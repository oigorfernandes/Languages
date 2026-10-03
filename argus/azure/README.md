# Argus Full — Copilot Studio + Azure

Versão completa do Argus: lê **texto vivo**, **texto achatado dentro de artes** e
**texto dentro de vídeos, quadro a quadro**, e **exporta os quadros** para revisão humana.

Este pacote é o que o time de TI precisa para implantar. O Copilot Studio hospeda a
conversa e as regras de revisão; o trabalho pesado acontece numa Azure Function.

> **Status: blueprint. Este código nunca foi executado** — foi escrito para o
> ambiente-alvo, mas não havia Azure, ffmpeg funcional nem serviço de OCR onde foi
> redigido. Um dev precisa implantar, rodar e depurar.

---

## 1. Arquitetura

```
  Usuário (Teams / web)
        │  anexa PPTX · PDF · DOCX · XLSX
        ▼
  ┌─────────────────────────────┐
  │  Agente no Copilot Studio   │   pergunta idioma da revisão / idioma do
  │  (conversa + regras)        │   relatório / país (se ES); aplica as regras
  └──────────┬──────────────────┘   de revisão sobre o texto que recebe de volta
             │ ação: POST /extract
             ▼
  ┌─────────────────────────────────────────────────────────────┐
  │  Azure Function  "argus-extract"   (container com ffmpeg)   │
  │                                                             │
  │  1. abre o arquivo (zip/OOXML, PDF)                         │
  │  2. extrai TEXTO VIVO com localização (slide/página/célula) │
  │  3. extrai as MÍDIAS embutidas (imagens e vídeos)           │
  │  4. ffmpeg: 1 quadro/segundo + cartela de contato           │
  │  5. sobe quadros e artes no Blob Storage (URL com SAS)      │
  │  6. OCR literal em cada arte e cada quadro                  │
  │  7. devolve JSON: texto + localização + timecode + URL      │
  └──────────┬──────────────────────────────────────────────────┘
             │  JSON com TODO o texto da peça, já localizado
             ▼
  ┌─────────────────────────────┐
  │  Agente revisa e monta      │   ação: POST /report  →  .docx no padrão ACD
  │  os achados                 │   (com link para o quadro de cada achado)
  └─────────────────────────────┘
```

---

## 2. As três decisões de arquitetura que importam

### 2.1 A Function faz o OCR, não o agente

O caminho óbvio seria a Function devolver as imagens e o agente "olhar" para elas.
**Não faça isso.** A capacidade de um agente do Copilot Studio consumir imagens
arbitrárias vindas de uma ação é instável e depende de canal, modelo e tenant.

Fazendo o OCR dentro da Function, o agente só lida com **texto** — que é o que ele faz
bem e de forma previsível. Isso remove a maior fonte de risco do projeto.

### 2.2 Para ler pixels, use OCR — não modelo generativo

Esta é a decisão menos óbvia e a mais importante.

Um modelo generativo, ao transcrever uma imagem, tende a **corrigir silenciosamente**
os erros que encontra: lê `tragetória` e escreve `trajetória`, lê `use se cartão` e
escreve `use seu cartão`. Para qualquer outra aplicação isso é um recurso. Para um
revisor ortográfico é **cegueira exatamente naquilo que ele existe para achar**.

O OCR (Azure AI Vision *Read* / Document Intelligence) devolve o texto **literal**,
com caixa delimitadora e grau de confiança. É isso que o Argus precisa.

> Use o modelo generativo, se quiser, apenas como **segunda passada de contexto**
> (descrever layout, apontar região suspeita). O texto citado no achado sai **sempre**
> do OCR.

### 2.3 ffmpeg exige container

O plano Consumption do Azure Functions não traz `ffmpeg` e não permite instalar.
Duas saídas:

- **Recomendada:** container próprio (Dockerfile incluído) rodando em
  **Azure Container Apps** ou **Functions Premium com container**.
- **Alternativa barata:** empacotar um binário estático do ffmpeg junto com a função
  e dar `chmod +x`. Funciona no Consumption, mas é mais frágil de manter.

---

## 3. Arquivos deste pacote

| Arquivo | O que é |
|---|---|
| `function_app.py` | Os endpoints `/extract`, `/report` e `/health` |
| `extractors.py` | Leitura por formato, ffmpeg e OCR |
| `report_builder.py` | Gera o `.docx` no padrão visual da ACD |
| `requirements.txt` | Dependências Python |
| `Dockerfile` | Imagem com ffmpeg |
| `host.json` | Configuração do host (timeout de 15 min) |
| `openapi.yaml` | Conector customizado para o Copilot Studio |
| `../copilot/argus-full-agent-instructions.md` | Instruções do agente |

---

## 4. Implantação (roteiro para TI)

1. **Recursos Azure**
   - Resource Group
   - Storage Account (container `argus-assets`, acesso privado)
   - Azure AI Vision (ou Document Intelligence) — chave e endpoint
   - Azure Container Registry
   - Azure Container Apps **ou** Function App Premium (Linux, container)

2. **Variáveis de ambiente da Function**
   ```
   AZURE_STORAGE_CONNECTION_STRING=...
   ASSET_CONTAINER=argus-assets
   VISION_ENDPOINT=https://<seu-recurso>.cognitiveservices.azure.com/
   VISION_KEY=...
   SAS_TTL_HOURS=72          # validade dos links de quadro
   FRAME_FPS=1               # quadros por segundo
   MAX_VIDEO_SECONDS=180     # trava de custo
   OCR_MIN_CONFIDENCE=0.80   # abaixo disso o achado vira "a confirmar"
   ```

3. **Build e deploy**
   ```bash
   az acr build -r <registry> -t argus:1 .
   az containerapp create -n argus -g <rg> --image <registry>.azurecr.io/argus:1 \
      --ingress external --target-port 80 --env-vars ...
   ```

4. **Conector customizado**
   Copilot Studio → Ferramentas → Novo conector customizado → importar `openapi.yaml`
   → apontar host para a URL do Container App → autenticação por API key.

5. **Agente**
   Copilot Studio → novo agente → colar as instruções → adicionar as duas ações do
   conector → publicar no Teams.

6. **Confira o `/health` antes de testar.** Ele diz se ffmpeg, OCR e storage estão
   realmente configurados — é para o time descobrir que falta uma chave no deploy,
   não no meio da primeira revisão de verdade.

---

## 5. Custo aproximado (ordem de grandeza, valide com a Azure)

| Item | Direcionador |
|---|---|
| Container Apps | tempo de execução; um deck de 6 vídeos roda em poucos minutos |
| Azure AI Vision Read | por imagem analisada — é o item que escala com nº de quadros |
| Blob Storage | quadros exportados; use ciclo de vida para expirar em 30 dias |

O parâmetro que governa o custo é `FRAME_FPS`. A 1 quadro/segundo, um vídeo de 15s
gera 15 imagens para OCR. Em 9 vídeos (caso C6), 135 imagens. Se o custo apertar,
caia para `0.5` — a maioria das legendas fica em tela mais de 2 segundos.

---

## 6. Ressalvas honestas

- **`MAX_VIDEO_SECONDS` existe por um motivo.** Sem trava, um vídeo longo vira uma
  conta grande de OCR. Comece conservador.
- **O OCR erra.** Ele devolve confiança por linha; o código já marca como
  *a confirmar* (não como erro) tudo que vier abaixo de `OCR_MIN_CONFIDENCE`.
  Isso preserva o guardrail do Argus de nunca afirmar o que não leu com clareza.
- **Capacidades do Copilot Studio mudam rápido.** Confirme o suporte atual a conector
  customizado e upload de arquivo no canal que vocês vão usar antes de fechar escopo.
