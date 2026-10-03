# -*- coding: utf-8 -*-
"""
Argus Full — extração de texto e mídia.

Cobre PPTX, PDF, DOCX e XLSX. Para cada peça devolve:
  · TEXTO VIVO, com localização (slide/página/célula)
  · ARTES achatadas, com o texto lido por OCR literal
  · VÍDEOS fatiados em quadros (1/s por padrão), cada quadro com timecode,
    URL do quadro exportado e o texto lido por OCR

Princípio inegociável: o texto citado num achado sai de OCR literal, nunca de
modelo generativo — um modelo tende a corrigir o erro ao transcrever, que é
exatamente o que não pode acontecer num revisor ortográfico.
"""
from __future__ import annotations

import os
import re
import shutil
import subprocess
import tempfile
import uuid
import zipfile
from dataclasses import dataclass, field, asdict
from datetime import datetime, timedelta, timezone

import requests

# ----------------------------------------------------------------------------
# Configuração
# ----------------------------------------------------------------------------
STORAGE_CONN = os.environ.get("AZURE_STORAGE_CONNECTION_STRING", "")
ASSET_CONTAINER = os.environ.get("ASSET_CONTAINER", "argus-assets")
VISION_ENDPOINT = os.environ.get("VISION_ENDPOINT", "").rstrip("/")
VISION_KEY = os.environ.get("VISION_KEY", "")
SAS_TTL_HOURS = int(os.environ.get("SAS_TTL_HOURS", "72"))
FRAME_FPS = float(os.environ.get("FRAME_FPS", "1"))
MAX_VIDEO_SECONDS = int(os.environ.get("MAX_VIDEO_SECONDS", "180"))
OCR_MIN_CONFIDENCE = float(os.environ.get("OCR_MIN_CONFIDENCE", "0.80"))
FFMPEG = os.environ.get("FFMPEG_BIN", "ffmpeg")
FFPROBE = os.environ.get("FFPROBE_BIN", "ffprobe")

VIDEO_EXT = (".mp4", ".mov", ".m4v", ".avi", ".mkv", ".webm")
IMAGE_EXT = (".png", ".jpg", ".jpeg", ".gif", ".bmp", ".tif", ".tiff", ".webp")

A_T = re.compile(r"<a:t(?:\s[^>]*)?>(.*?)</a:t>", re.DOTALL)
W_T = re.compile(r"<w:t(?:\s[^>]*)?>(.*?)</w:t>", re.DOTALL)
XML_ESCAPES = {"&amp;": "&", "&lt;": "<", "&gt;": ">", "&quot;": '"', "&apos;": "'"}


def _unescape(s: str) -> str:
    for k, v in XML_ESCAPES.items():
        s = s.replace(k, v)
    return s


# ----------------------------------------------------------------------------
# Modelo de saída
# ----------------------------------------------------------------------------
@dataclass
class TextItem:
    """Um trecho de texto lido, sempre com origem e localização."""
    text: str
    location: str                 # "Slide 5", "Página 12", "Aba Resumo · B14"
    source: str                   # "live" | "artwork" | "video"
    timecode: str | None = None   # "~00:06" apenas para vídeo
    asset_url: str | None = None  # quadro/arte exportado, para revisão humana
    confidence: float | None = None  # confiança do OCR (None quando texto vivo)


@dataclass
class Extraction:
    file_name: str
    format: str
    inventory: dict = field(default_factory=dict)
    items: list[TextItem] = field(default_factory=list)
    coverage_notes: list[str] = field(default_factory=list)

    def to_dict(self) -> dict:
        return {
            "file_name": self.file_name,
            "format": self.format,
            "inventory": self.inventory,
            "coverage_notes": self.coverage_notes,
            "items": [asdict(i) for i in self.items],
        }


# ----------------------------------------------------------------------------
# Blob Storage
# ----------------------------------------------------------------------------
def upload_asset(path: str, prefix: str) -> str | None:
    """Sobe um quadro/arte e devolve URL com SAS de leitura. None se não configurado."""
    if not STORAGE_CONN:
        return None
    from azure.storage.blob import (
        BlobServiceClient, generate_blob_sas, BlobSasPermissions,
    )
    svc = BlobServiceClient.from_connection_string(STORAGE_CONN)
    try:
        svc.create_container(ASSET_CONTAINER)
    except Exception:
        pass  # já existe
    blob_name = f"{prefix}/{uuid.uuid4().hex}_{os.path.basename(path)}"
    client = svc.get_blob_client(ASSET_CONTAINER, blob_name)
    with open(path, "rb") as fh:
        client.upload_blob(fh, overwrite=True)
    sas = generate_blob_sas(
        account_name=svc.account_name,
        container_name=ASSET_CONTAINER,
        blob_name=blob_name,
        account_key=svc.credential.account_key,
        permission=BlobSasPermissions(read=True),
        expiry=datetime.now(timezone.utc) + timedelta(hours=SAS_TTL_HOURS),
    )
    return f"{client.url}?{sas}"


# ----------------------------------------------------------------------------
# OCR literal (Azure AI Vision — Read)
# ----------------------------------------------------------------------------
def ocr_lines(image_path: str) -> list[tuple[str, float]]:
    """Devolve [(linha, confiança)] exatamente como está na imagem.

    Não normaliza, não corrige, não interpreta. Se o serviço não estiver
    configurado, devolve lista vazia e quem chamou registra nota de cobertura.
    """
    if not (VISION_ENDPOINT and VISION_KEY):
        return []
    url = f"{VISION_ENDPOINT}/computervision/imageanalysis:analyze"
    params = {"api-version": "2024-02-01", "features": "read"}
    headers = {
        "Ocp-Apim-Subscription-Key": VISION_KEY,
        "Content-Type": "application/octet-stream",
    }
    with open(image_path, "rb") as fh:
        resp = requests.post(url, params=params, headers=headers, data=fh.read(), timeout=60)
    resp.raise_for_status()
    body = resp.json()
    out: list[tuple[str, float]] = []
    for block in body.get("readResult", {}).get("blocks", []):
        for line in block.get("lines", []):
            words = line.get("words", [])
            conf = min((w.get("confidence", 1.0) for w in words), default=1.0)
            text = line.get("text", "").strip()
            if text:
                out.append((text, conf))
    return out


def ocr_into(items: list[TextItem], image_path: str, location: str,
             source: str, timecode: str | None, asset_url: str | None) -> None:
    """Roda OCR e acrescenta cada linha lida como um TextItem."""
    for text, conf in ocr_lines(image_path):
        items.append(TextItem(
            text=text, location=location, source=source,
            timecode=timecode, asset_url=asset_url, confidence=round(conf, 3),
        ))


# ----------------------------------------------------------------------------
# Vídeo: quadros + cartela de contato
# ----------------------------------------------------------------------------
def video_duration(path: str) -> float:
    try:
        out = subprocess.run(
            [FFPROBE, "-v", "error", "-show_entries", "format=duration",
             "-of", "default=noprint_wrappers=1:nokey=1", path],
            capture_output=True, text=True, timeout=60,
        )
        return float(out.stdout.strip())
    except Exception:
        return 0.0


def extract_frames(video_path: str, workdir: str, fps: float = FRAME_FPS) -> list[tuple[str, str]]:
    """Fatia o vídeo em quadros. Devolve [(timecode, caminho_do_quadro)].

    É esta função que dá ao Argus a capacidade que nenhum corretor tem:
    ler o texto que só existe dentro do vídeo. Os quadros ficam exportados
    para que uma pessoa possa conferir o achado com os próprios olhos.
    """
    dur = video_duration(video_path)
    if dur > MAX_VIDEO_SECONDS:
        dur = MAX_VIDEO_SECONDS  # trava de custo
    out_dir = os.path.join(workdir, "frames_" + uuid.uuid4().hex[:8])
    os.makedirs(out_dir, exist_ok=True)
    subprocess.run(
        [FFMPEG, "-hide_banner", "-loglevel", "error", "-t", str(dur),
         "-i", video_path, "-vf", f"fps={fps}", "-q:v", "2",
         os.path.join(out_dir, "f_%04d.jpg")],
        check=True, timeout=900,
    )
    frames: list[tuple[str, str]] = []
    for i, name in enumerate(sorted(os.listdir(out_dir))):
        seconds = i / fps
        timecode = f"~{int(seconds // 60):02d}:{int(seconds % 60):02d}"
        frames.append((timecode, os.path.join(out_dir, name)))
    return frames


def contact_sheet(video_path: str, workdir: str) -> str | None:
    """Cartela de contato 4x4: o vídeo inteiro numa imagem, para leitura rápida."""
    out = os.path.join(workdir, f"sheet_{uuid.uuid4().hex[:8]}.jpg")
    try:
        subprocess.run(
            [FFMPEG, "-hide_banner", "-loglevel", "error", "-i", video_path,
             "-vf", "fps=1,scale=380:-1,tile=4x4", "-frames:v", "1", out],
            check=True, timeout=300,
        )
        return out if os.path.exists(out) else None
    except Exception:
        return None


# ----------------------------------------------------------------------------
# PPTX
# ----------------------------------------------------------------------------
def extract_pptx(path: str, workdir: str) -> Extraction:
    ex = Extraction(file_name=os.path.basename(path), format="PPTX")
    z = zipfile.ZipFile(path)
    names = z.namelist()

    slides = sorted(
        [n for n in names if re.match(r"ppt/slides/slide\d+\.xml$", n)],
        key=lambda s: int(re.search(r"(\d+)", s.split("/")[-1]).group(1)),
    )

    # 1. texto vivo, slide a slide
    for n in slides:
        idx = int(re.search(r"(\d+)", n.split("/")[-1]).group(1))
        xml = z.read(n).decode("utf-8", errors="ignore")
        text = " ".join(_unescape(t) for t in A_T.findall(xml)).strip()
        if text:
            ex.items.append(TextItem(text=text, location=f"Slide {idx}", source="live"))

    # 2. mapa mídia -> slide, pelos rels
    media_slide: dict[str, int] = {}
    for n in slides:
        idx = int(re.search(r"(\d+)", n.split("/")[-1]).group(1))
        rel = n.replace("slides/", "slides/_rels/") + ".rels"
        if rel not in names:
            continue
        for target in re.findall(r'Target="([^"]*media/[^"]+)"',
                                 z.read(rel).decode("utf-8", "ignore")):
            media_slide.setdefault(os.path.basename(target), idx)

    n_video = n_image = 0
    for n in [x for x in names if x.startswith("ppt/media/")]:
        base = os.path.basename(n)
        ext = os.path.splitext(base)[1].lower()
        slide = media_slide.get(base)
        loc = f"Slide {slide}" if slide else "Mídia do arquivo"
        local = os.path.join(workdir, base)
        with open(local, "wb") as fh:
            fh.write(z.read(n))

        if ext in VIDEO_EXT:
            n_video += 1
            _process_video(ex, local, loc, workdir)
        elif ext in IMAGE_EXT:
            n_image += 1
            url = upload_asset(local, "artwork")
            ocr_into(ex.items, local, loc, "artwork", None, url)

    ex.inventory = {"slides": len(slides), "videos": n_video, "images": n_image}
    return ex


def _process_video(ex: Extraction, local: str, loc: str, workdir: str) -> None:
    """Fatia, exporta e lê um vídeo. Falha vira nota de cobertura, nunca silêncio."""
    try:
        frames = extract_frames(local, workdir)
    except Exception as err:
        ex.coverage_notes.append(
            f"{loc}: o vídeo não pôde ser decodificado ({type(err).__name__}). "
            f"Os quadros NÃO foram verificados. Recomendamos conferência manual "
            f"do export final antes de publicar."
        )
        return

    sheet = contact_sheet(local, workdir)
    if sheet:
        upload_asset(sheet, "contact-sheets")

    for timecode, frame_path in frames:
        url = upload_asset(frame_path, "frames")
        ocr_into(ex.items, frame_path, loc, "video", timecode, url)

    if not frames:
        ex.coverage_notes.append(f"{loc}: nenhum quadro extraído do vídeo.")


# ----------------------------------------------------------------------------
# PDF
# ----------------------------------------------------------------------------
def extract_pdf(path: str, workdir: str) -> Extraction:
    import fitz  # PyMuPDF

    ex = Extraction(file_name=os.path.basename(path), format="PDF")
    doc = fitz.open(path)
    n_images = 0
    pages_without_text = 0

    for pno in range(doc.page_count):
        page = doc.load_page(pno)
        loc = f"Página {pno + 1}"

        live = page.get_text("text").strip()
        if live:
            ex.items.append(TextItem(text=live, location=loc, source="live"))
        else:
            pages_without_text += 1

        # artes embutidas, na resolução nativa
        for img in page.get_images(full=True):
            xref = img[0]
            try:
                pix = fitz.Pixmap(doc, xref)
                if pix.n - pix.alpha >= 4:            # CMYK -> RGB
                    pix = fitz.Pixmap(fitz.csRGB, pix)
                if pix.width * pix.height < 40000:    # ignora ícones
                    continue
                out = os.path.join(workdir, f"p{pno+1}_x{xref}.png")
                pix.save(out)
                n_images += 1
                url = upload_asset(out, "artwork")
                ocr_into(ex.items, out, loc, "artwork", None, url)
            except Exception:
                continue

        # página inteira rasterizada: pega o que é desenho vetorial achatado
        if not live:
            out = os.path.join(workdir, f"page_{pno+1}.png")
            page.get_pixmap(dpi=200).save(out)
            url = upload_asset(out, "pages")
            ocr_into(ex.items, out, loc, "artwork", None, url)

    ex.inventory = {"pages": doc.page_count, "images": n_images}
    if pages_without_text:
        ex.coverage_notes.append(
            f"{pages_without_text} página(s) sem camada de texto foram lidas por OCR."
        )
    return ex


# ----------------------------------------------------------------------------
# DOCX
# ----------------------------------------------------------------------------
def extract_docx(path: str, workdir: str) -> Extraction:
    ex = Extraction(file_name=os.path.basename(path), format="DOCX")
    z = zipfile.ZipFile(path)
    names = z.namelist()

    parts = [("Corpo", "word/document.xml")]
    parts += [(f"Cabeçalho/rodapé ({os.path.basename(n)})", n)
              for n in names if re.match(r"word/(header|footer)\d*\.xml$", n)]
    parts += [(f"Notas ({os.path.basename(n)})", n)
              for n in names if re.match(r"word/(foot|end)notes\.xml$", n)]

    for loc, part in parts:
        if part not in names:
            continue
        xml = z.read(part).decode("utf-8", errors="ignore")
        text = " ".join(_unescape(t) for t in W_T.findall(xml)).strip()
        if text:
            ex.items.append(TextItem(text=text, location=loc, source="live"))

    n_images = 0
    for n in [x for x in names if x.startswith("word/media/")]:
        ext = os.path.splitext(n)[1].lower()
        local = os.path.join(workdir, os.path.basename(n))
        with open(local, "wb") as fh:
            fh.write(z.read(n))
        if ext in VIDEO_EXT:
            _process_video(ex, local, "Vídeo embutido", workdir)
        elif ext in IMAGE_EXT:
            n_images += 1
            url = upload_asset(local, "artwork")
            ocr_into(ex.items, local, "Imagem no documento", "artwork", None, url)

    ex.inventory = {"parts": len(parts), "images": n_images}
    return ex


# ----------------------------------------------------------------------------
# XLSX
# ----------------------------------------------------------------------------
def extract_xlsx(path: str, workdir: str) -> Extraction:
    ex = Extraction(file_name=os.path.basename(path), format="XLSX")
    z = zipfile.ZipFile(path)
    names = z.namelist()

    shared: list[str] = []
    if "xl/sharedStrings.xml" in names:
        xml = z.read("xl/sharedStrings.xml").decode("utf-8", errors="ignore")
        shared = [_unescape(t) for t in re.findall(r"<t(?:\s[^>]*)?>(.*?)</t>", xml, re.DOTALL)]

    sheet_names: list[str] = []
    if "xl/workbook.xml" in names:
        wb = z.read("xl/workbook.xml").decode("utf-8", errors="ignore")
        sheet_names = [_unescape(m) for m in re.findall(r'<sheet[^>]*name="([^"]+)"', wb)]

    for i, n in enumerate(sorted(x for x in names
                                 if re.match(r"xl/worksheets/sheet\d+\.xml$", x))):
        tab = sheet_names[i] if i < len(sheet_names) else f"Aba {i+1}"
        xml = z.read(n).decode("utf-8", errors="ignore")
        for cell in re.finditer(r'<c r="([A-Z]+\d+)"([^>]*)>(.*?)</c>', xml, re.DOTALL):
            ref, attrs, body = cell.groups()
            vals = re.findall(r"<v>(.*?)</v>", body, re.DOTALL)
            if not vals:
                continue
            if 't="s"' in attrs:                       # string compartilhada
                try:
                    text = shared[int(vals[0])]
                except (ValueError, IndexError):
                    continue
            elif 't="str"' in attrs or 't="inlineStr"' in attrs:
                text = _unescape(vals[0])
            else:
                continue                               # número: não é objeto de revisão
            if text.strip():
                ex.items.append(TextItem(text=text, location=f"{tab} · {ref}", source="live"))

    # títulos de gráfico e caixas de texto
    for n in [x for x in names if re.match(r"xl/(charts|drawings)/.*\.xml$", x)]:
        xml = z.read(n).decode("utf-8", errors="ignore")
        text = " ".join(_unescape(t) for t in A_T.findall(xml)).strip()
        if text:
            ex.items.append(TextItem(
                text=text, location=f"Gráfico/caixa ({os.path.basename(n)})", source="live"))

    n_images = 0
    for n in [x for x in names if x.startswith("xl/media/")]:
        local = os.path.join(workdir, os.path.basename(n))
        with open(local, "wb") as fh:
            fh.write(z.read(n))
        if os.path.splitext(n)[1].lower() in IMAGE_EXT:
            n_images += 1
            url = upload_asset(local, "artwork")
            ocr_into(ex.items, local, "Imagem na planilha", "artwork", None, url)

    ex.inventory = {"sheets": len(sheet_names), "images": n_images}
    return ex


# ----------------------------------------------------------------------------
# Entrada
# ----------------------------------------------------------------------------
DISPATCH = {
    ".pptx": extract_pptx, ".ppt": extract_pptx,
    ".pdf": extract_pdf,
    ".docx": extract_docx,
    ".xlsx": extract_xlsx, ".xlsm": extract_xlsx,
}


def fetch(file_url: str, file_name: str, workdir: str) -> str:
    local = os.path.join(workdir, file_name)
    resp = requests.get(file_url, timeout=300, stream=True)
    resp.raise_for_status()
    with open(local, "wb") as fh:
        shutil.copyfileobj(resp.raw, fh)
    if os.path.getsize(local) == 0:
        raise ValueError("O arquivo baixado tem 0 bytes. Confirme o link antes de revisar.")
    return local


def run(file_url: str, file_name: str) -> dict:
    ext = os.path.splitext(file_name)[1].lower()
    handler = DISPATCH.get(ext)
    if not handler:
        raise ValueError(f"Formato não suportado: {ext}. Aceito PPTX, PDF, DOCX e XLSX.")
    workdir = tempfile.mkdtemp(prefix="argus_")
    try:
        local = fetch(file_url, file_name, workdir)
        ex = handler(local, workdir)
        if not (VISION_ENDPOINT and VISION_KEY):
            ex.coverage_notes.append(
                "O serviço de leitura de imagem não está configurado: artes e quadros "
                "de vídeo NÃO foram lidos. Só o texto vivo foi revisado."
            )
        # achados de baixa confiança entram como 'a confirmar', nunca como erro
        for item in ex.items:
            if item.confidence is not None and item.confidence < OCR_MIN_CONFIDENCE:
                item.location += "  [leitura incerta — confirmar]"
        return ex.to_dict()
    finally:
        shutil.rmtree(workdir, ignore_errors=True)
