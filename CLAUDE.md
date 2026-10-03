# CLAUDE.md

Memória do projeto. Carregado automaticamente em toda sessão nova neste repositório.

---

## Este repositório tem dois projetos

### 1. Chimba — tradutor PT → ES colombiano (PWA)
A aplicação na raiz (`index.html`, `sw.js`, `manifest.json`, `icon.svg`).

### 2. Argus — revisor ortográfico da ACD  →  pasta `argus/`
Projeto de **Igor Fernandes** para a Advisors Creative Desk (Mastercard).
Não tem relação com o Chimba; mora aqui por conveniência de versionamento.

> **Ao mexer em qualquer coisa do Argus, leia `argus/HISTORY.md` primeiro.**
> Ele carrega o raciocínio do projeto, não só a lista de arquivos: histórico dos
> testes, decisões de design e por quê, padrão visual, limitações de ambiente já
> descobertas e as técnicas que funcionaram.

---

## Argus — o essencial para retomar

**O que é:** revisor ortográfico que lê **todo** o texto de uma entrega criativa —
texto vivo, texto achatado dentro de artes e texto **dentro de vídeos**, quadro a
quadro. PT, EN e ES (espanhol localizado por país). PPTX, DOCX, XLSX, PDF.
Entrega sempre um relatório Word no padrão da ACD.

**Três versões:**
| Versão | Onde roda | Lê | Estado |
|---|---|---|---|
| Argus (skill) | Cowork / Claude Code | texto + artes + vídeo | em uso, testada |
| Argus Text | M365 Copilot (agent builder) | só texto vivo | instruções prontas |
| Argus Full | Copilot Studio + Azure | texto + artes + quadros exportados | blueprint, não implantado |

**Guardrails que não se negociam:**
- **Nunca afirmar o que não leu.** Vídeo que não decodificou vira *nota de
  cobertura* no relatório e chip cinza no placar — nunca "o vídeo está limpo".
- **Incerto vira "a confirmar", não erro.** Regionalismo válido, possível
  convenção de marca, frase que parece cortada: tabela 🟡, nunca 🔴.
- **Nunca reescrever a copy do redator.** Aponta e sugere. Tom de voz é da Lexi.
- **Linguagem de negócio na saída.** Nunca expor caminhos, ferramentas ou XML.

**Relatório — padrão fixo:** Arial em 100%; cor **só** nos marcadores de status;
sem faixas de cor sólida; hairlines como únicos separadores; rodapé fixo
*"Argus · Advisors Creative Desk · criado por Igor Fernandes"*.
Paleta: 🔴 `B3261E` · 🟡 `9A6300` · 🟢 `1E7B34` · cinza `57606A` ·
tinta `1F2328` · hairline `D9DCE1` · fundo de cabeçalho `F6F7F8` · marca `C6631F`.

**Evidência acumulada (4 testes reais):** 7 erros em 3 decks-piloto.
O caso de destaque é o **C6 Bank**: `"…use se cartão de débito…"` aos **~00:06**,
**só nos três vídeos 9:16** — quadrado e 16:9 corretos. Nenhuma revisão manual
pegaria sem assistir aos nove vídeos inteiros.

---

## Ambiente desta sessão — avisos que economizam horas

- **O container é efêmero e já foi reciclado três vezes**, apagando scratchpad e
  uploads. Nada fora do git sobrevive. Se precisar de um binário (`.pptx`,
  `.docx`), peça ao Igor para subir de novo.
- **LibreOffice/`soffice` está quebrado** — falha até convertendo um `.txt`.
  **Não há QA visual.** Toda edição de documento é verificada por código.
- **Não há** `pdftoppm`, `ffmpeg` com H.264, PIL, defusedxml, python-docx nem numpy.
  Use `zipfile` + `zlib` + `struct` da stdlib.
- **Chromium funciona** (`/opt/pw-browsers/chromium`) e serve de **lupa**: HTML com
  a imagem ampliada → screenshot. Ele reserva **87px** de altura mesmo em headless;
  renderize com `altura + 87` e recorte o PNG por código.
- **Editar PPTX preservando formatação:** substituir só o conteúdo dentro de
  `<a:t>`, run a run, conferindo a contagem esperada de ocorrências. Nunca
  reserializar o XML. Validar comparando contagens de `<a:r>`, `<a:rPr>`, `<a:p>`.
  Ao criar um part de mídia novo, **conferir se o nome já existe** antes de gravar.

---

## Pendências do Argus (estado em 2026-10-03)

1. **Teste de dez minutos** que define o tamanho do projeto Azure: no agent builder
   do Copilot, subir um PPTX com arte e ver se o modelo **enxerga** as imagens que o
   interpretador de código extrai. Se enxergar, só o vídeo precisa do Azure.
2. Formulário ACD AI & Tooling Request (v4, fora do git): falta link do SharePoint
   e headcount de usuários.
3. Confirmar com o TF Lead se o formulário — desenhado para **fornecedor externo** —
   é mesmo o funil certo para uma ferramenta interna.
4. Tabela de espanhol por país segue como rascunho: validar com falante nativo.
5. O código Azure nunca foi executado. É blueprint; precisa de um dev.

---

## Convenções de trabalho

- Responder ao Igor em **português**; os materiais da ACD saem no idioma que ele pedir.
- Branch desta linha de trabalho: `claude/skill-testing-68brx9`.
- Ao entregar documento ou deck, **dizer o que foi verificado e o que não foi**.
  Sem QA visual neste ambiente, overflow de texto é sempre risco em aberto.
