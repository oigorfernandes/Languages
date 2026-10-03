# -*- coding: utf-8 -*-
"""
Argus Full — Azure Function.

Dois endpoints, chamados pelo agente do Copilot Studio como ações:

  POST /api/extract   recebe o arquivo, devolve TODO o texto da peça
                      (vivo + artes + quadros de vídeo), já localizado,
                      com timecode e link do quadro exportado

  POST /api/report    recebe os achados que o agente produziu e devolve
                      o .docx no padrão visual da ACD

O agente fica com o que sabe fazer bem: conversar e aplicar as regras de
revisão sobre texto. A Function fica com o que ele não consegue fazer:
abrir arquivo, fatiar vídeo e ler pixel.
"""
from __future__ import annotations

import base64
import json
import logging
import os

import azure.functions as func

import extractors
import report_builder

app = func.FunctionApp(http_auth_level=func.AuthLevel.FUNCTION)
log = logging.getLogger("argus")

MAX_ITEMS = int(os.environ.get("MAX_ITEMS_RETURNED", "1200"))


def _bad(message: str, status: int = 400) -> func.HttpResponse:
    return func.HttpResponse(
        json.dumps({"ok": False, "error": message}, ensure_ascii=False),
        status_code=status, mimetype="application/json",
    )


@app.route(route="extract", methods=["POST"])
def extract(req: func.HttpRequest) -> func.HttpResponse:
    """Body: {"file_url": "...", "file_name": "deck.pptx"}"""
    try:
        body = req.get_json()
    except ValueError:
        return _bad("Corpo inválido: esperado JSON.")

    file_url = body.get("file_url")
    file_name = body.get("file_name")
    if not file_url or not file_name:
        return _bad("Informe 'file_url' e 'file_name'.")

    try:
        result = extractors.run(file_url, file_name)
    except ValueError as err:                    # formato/arquivo inválido
        return _bad(str(err))
    except Exception as err:                     # falha real: diga, não mascare
        log.exception("falha na extração")
        return _bad(f"Falha ao processar o arquivo: {type(err).__name__}: {err}", 500)

    items = result["items"]
    if len(items) > MAX_ITEMS:
        result["items"] = items[:MAX_ITEMS]
        result["coverage_notes"].append(
            f"A peça gerou {len(items)} trechos de texto; foram devolvidos os "
            f"primeiros {MAX_ITEMS}. Revise o arquivo em partes para cobertura total."
        )

    result["ok"] = True
    return func.HttpResponse(
        json.dumps(result, ensure_ascii=False),
        status_code=200, mimetype="application/json",
    )


@app.route(route="report", methods=["POST"])
def report(req: func.HttpRequest) -> func.HttpResponse:
    """Body: {"language": "pt|en|es", "findings": {...}}

    Devolve o .docx em base64 para o Copilot Studio entregar ao usuário.
    """
    try:
        body = req.get_json()
    except ValueError:
        return _bad("Corpo inválido: esperado JSON.")

    findings = body.get("findings")
    if not isinstance(findings, dict):
        return _bad("Informe 'findings' como objeto.")

    language = (body.get("language") or "en").lower()[:2]

    # as contagens do relatório saem de código, nunca de estimativa
    for key in ("errors", "consistency", "clean", "coverage_notes"):
        findings.setdefault(key, [])

    try:
        data = report_builder.build(findings, language)
    except Exception as err:
        log.exception("falha ao montar o relatório")
        return _bad(f"Falha ao gerar o relatório: {type(err).__name__}: {err}", 500)

    name = findings.get("report_name") or "Argus_Report.docx"
    return func.HttpResponse(
        json.dumps({
            "ok": True,
            "file_name": name,
            "content_type": "application/vnd.openxmlformats-officedocument."
                            "wordprocessingml.document",
            "content_base64": base64.b64encode(data).decode("ascii"),
            "summary": {
                "errors": len(findings["errors"]),
                "consistency": len(findings["consistency"]),
                "clean": len(findings["clean"]),
                "coverage_notes": len(findings["coverage_notes"]),
            },
        }, ensure_ascii=False),
        status_code=200, mimetype="application/json",
    )


@app.route(route="health", methods=["GET"], auth_level=func.AuthLevel.ANONYMOUS)
def health(req: func.HttpRequest) -> func.HttpResponse:
    """Diz o que está realmente configurado — evita descobrir em produção."""
    import shutil
    return func.HttpResponse(
        json.dumps({
            "ok": True,
            "ffmpeg": bool(shutil.which(extractors.FFMPEG)),
            "vision_configured": bool(extractors.VISION_ENDPOINT and extractors.VISION_KEY),
            "storage_configured": bool(extractors.STORAGE_CONN),
            "frame_fps": extractors.FRAME_FPS,
            "max_video_seconds": extractors.MAX_VIDEO_SECONDS,
        }, ensure_ascii=False),
        status_code=200, mimetype="application/json",
    )
