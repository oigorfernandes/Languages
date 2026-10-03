# Argus — histórico, decisões e estado do projeto

> Documento de memória. Se a sessão reiniciar, **leia este arquivo primeiro**:
> ele carrega o raciocínio, não só os arquivos.
>
> Projeto de **Igor Fernandes**, Advisors Creative Desk (ACD).
> Última atualização: 2026-10-03.

---

## 1. O que é o Argus

Revisor ortográfico do time criativo da ACD. O diferencial não é corrigir texto —
é **alcançar texto que nenhum corretor alcança**: o que está achatado dentro de
artes e o que só existe **dentro de vídeo**.

Cobre PT, EN e ES (espanhol **localizado por país**) e os formatos PPTX, DOCX,
XLSX e PDF. Sempre entrega um relatório Word no padrão visual da ACD.

Foco é **correção ortográfica**. Tom de voz e manual de marca são de outra
ferramenta (a Lexi). Argus aponta e sugere, nunca reescreve a copy do redator.

---

## 2. As três versões (e quando usar cada uma)

| Versão | Onde roda | Lê | Estado |
|---|---|---|---|
| **Argus** (skill completa) | Cowork / Claude Code | texto vivo + artes + vídeo | em uso, testada |
| **Argus Text** (agente) | M365 Copilot (agent builder) | só texto vivo | instruções prontas |
| **Argus Full** (agente + serviço) | Copilot Studio + Azure | texto vivo + artes + **quadros de vídeo exportados** | blueprint, não implantado |

**Por que três:** o Copilot sozinho não consegue ler pixel de forma confiável.
Para texto puro, o agent builder basta e é mais simples que o Studio (tem
interpretador de código embutido). Para arte e vídeo, só com serviço externo —
daí o Argus Full.

**Armadilha registrada:** migrar o *Argus Text* para o Copilot Studio seria um
**downgrade**, porque no Studio se perde o interpretador de código e seria
preciso construir uma ação para fazer o que já funciona de graça. O Studio só
ganha quando é preciso chamar serviço externo (arte/vídeo).

---

## 3. Histórico de testes (a base de evidência do projeto)

Quatro rodadas reais. **São esses números que sustentam o pedido de ferramenta.**

### Rodada 1 — Mastercard Gasolineras (ES-MX, PPTX)
6 slides, 1 vídeo de 6s, 3 KVs achatados (1:1, 4:5, 9:16).
**0 erros · 2 a confirmar · 1 nota de cobertura.**
Achado: os 3 banners dizem *"noviembre **del** 2026"*, enquanto o brief e o quadro
de referência do vídeo dizem *"**de** 2026"*. Só aparece lendo os formatos juntos.
O vídeo **não pôde ser decodificado** — registrado como nota, nunca omitido.

### Rodada 2 — Sicoob Sirium World Legend (PT-BR, PDF)
28 páginas, jornada completa (carta, e-mails, pushes, banners, cards WhatsApp).
**3 erros · 5 a confirmar.**
- *"tragetória"* (por "trajetória") em tipo display, **nas duas variantes** do
  e-mail da Fase 2 — e correto nos banners do app.
- *"à soluções"* (crase indevida) no card de WhatsApp.
- *"LEGENG"* por *"LEGEND"* no carimbo do template, repetido em ~20 rodapés.

### Rodada 3 — Santander Banking Trends (EN, PDF)
16 páginas, deck de liderança com camadas gráficas achatadas.
**4 erros · 5 a confirmar.**
- **Todos os KPIs de destaque renderizados como ZERO** ("0 customers",
  "$0.0b profit (2024)") — as animações de contagem exportaram congeladas.
- *"2TB"* por *"T2B"*; dois quadrantes do 2×2 com o mesmo rótulo; *"affluency"*.

### Rodada 4 — C6 Bank Libertadores (PT-BR, PPTX) ← **caso de destaque**
14 slides, **9 vídeos de 15s**, 6 banners estáticos.
**3 erros · 2 a confirmar.**
- *"…e use **se** cartão de débito…"* aos **~00:06**, **só nos três vídeos 9:16**.
  Quadrado e 16:9 liam certo. Nenhuma revisão manual pegaria sem assistir aos
  nove vídeos inteiros, e nenhum corretor de mercado lê dentro de vídeo.
- *"DESODOBRAMENTO"* na capa; *"Concorra **à** uma viagem com **acompanhate**"*.

**Placar acumulado: 7 erros reais em 3 decks-piloto** (C6 3 + Santander 4 +
Gasolineras 0). O zero do Gasolineras é mantido de propósito nos materiais: prova
que a ferramenta não inventa achado.

---

## 4. Decisões de design (o raciocínio, não só a regra)

### 4.1 Nunca afirmar o que não leu
O guardrail central. Se o vídeo não decodificou, isso vira **nota de cobertura**
no relatório e um **chip cinza** no placar. Nunca "o vídeo está limpo".
Foi o que aconteceu de verdade no Gasolineras.

### 4.2 Incerto vira "a confirmar", não erro
Regionalismo válido, possível convenção de marca, frase que parece cortada na
camada de texto: tudo entra na tabela 🟡, nunca na 🔴. Nos testes isso evitou
dois falsos positivos no Sicoob que o zoom descartou ("conectar você a
experiências" e "família" estavam corretos).

### 4.3 Para ler pixel: OCR, não modelo generativo *(decisão do Argus Full)*
Um modelo generativo **corrige silenciosamente** ao transcrever: lê `tragetória`
e escreve `trajetória`. Para um revisor ortográfico isso é cegueira exatamente
naquilo que ele existe para achar. O OCR (Azure AI Vision Read) devolve texto
literal com confiança por linha. O texto citado num achado sai **sempre** do OCR.

### 4.4 No Argus Full, quem faz o OCR é o serviço, não o agente
A capacidade de um agente do Copilot Studio consumir imagens vindas de uma ação é
instável. Fazendo o OCR dentro da Function, o agente só lida com texto — remove a
maior fonte de risco do projeto.

### 4.5 Método em linguagem de negócio
O guardrail proíbe expor ferramentas e caminhos, mas a ficha do relatório pede
"método". Resolvido: *"leitura do texto vivo + leitura visual das artes"*,
nunca "extração XML" ou nome de arquivo de mídia.

---

## 5. Padrão visual do relatório (fixo, não negociar)

- **Arial em 100% do documento.** Nunca misturar fontes.
- **Cor só nos marcadores de status.** Nada de faixa ou bloco de cor sólida.
- Cabeçalho: eyebrow `ADVISORS CREATIVE DESK` em cinza + **um** filete fino na
  cor de marca. Hairlines são os únicos separadores.
- Rodapé fixo em todo relatório:
  **"Argus · Advisors Creative Desk · criado por Igor Fernandes"**
  (a parte "criado por" traduz com o idioma do relatório).

**Paleta (hex, fixa):**

| Uso | Hex |
|---|---|
| 🔴 Erros | `B3261E` |
| 🟡 A confirmar | `9A6300` |
| 🟢 Limpo | `1E7B34` |
| Cinza (cobertura / secundário) | `57606A` |
| Tinta (texto principal) | `1F2328` |
| Hairline (divisórias, bordas) | `D9DCE1` |
| Fundo de cabeçalho de tabela | `F6F7F8` |
| Filete de marca | `C6631F` |

Estrutura: ficha → chips do placar → tabela 🔴 → tabela 🟡 → lista ✅ →
Notas (cinza) → rodapé. Contagens calculadas por código, nunca de cabeça.

---

## 6. Limitações do ambiente e técnicas que funcionaram

Descobertas na prática, ao longo das rodadas. **Economizam horas numa sessão nova.**

| Ferramenta | Situação real | Contorno que funcionou |
|---|---|---|
| `soffice` / LibreOffice | **Quebrado**: falha até convertendo um `.txt` | nenhum render possível; ler mídias embutidas direto |
| `pdftoppm` / poppler-utils | ausente | parser de PDF em Python puro |
| `ffmpeg` | só o build do Playwright, **sem H.264** | não decodifica mp4 de deck |
| Chromium (`/opt/pw-browsers/chromium`) | funciona | **usado como lupa**: HTML com `<img>` ampliado → screenshot 4x |
| PIL, defusedxml, python-docx, numpy | ausentes | `zipfile` + `zlib` + `struct` da stdlib |

**Técnicas registradas:**
- **PDF em Python puro:** regex nos objetos, `zlib` nos streams, **expandir
  ObjStm** (sem isso parte das páginas fica invisível), blocos `BT…ET` com
  `Tj`/`TJ`, e varrer também os **Form XObjects**.
- **Contagem de páginas** sai da árvore `/Type /Pages` → `/Count` do próprio
  arquivo. O sistema errou duas vezes (disse 33 e era 28; disse 13 e era 16).
- **Chromium como lupa:** reserva **87px** de altura mesmo em headless — renderize
  com `altura + 87` e recorte o PNG por código.
- **Editar PPTX preservando formatação:** substituir só o conteúdo dentro de
  `<a:t>`, run a run, com contagem esperada de ocorrências. Nunca reserializar o
  XML inteiro. Validar depois comparando contagens de `<a:r>`, `<a:rPr>`, `<a:p>`.
- **Duplicar slide:** usar o `add_slide.py` da skill pptx (faz toda a contabilidade
  do pacote). Um slide duplicado **compartilha** o part de imagem do original —
  se os dois precisam de imagens diferentes, criar part novo e repontar o rel.
  Antes de criar `imageNN.png`, **conferir se o nome já existe** (errei uma vez e
  sobrescrevi uma imagem de outro slide).

---

## 7. Onde o projeto está (estado em 2026-10-03)

### Pronto
- **Skill Argus** — `argus/skill/SKILL.md`
- **Argus Text para Copilot** — `argus/copilot/argus-text-instructions.txt`
- **Argus Full (blueprint)** — `argus/azure/` + `argus/copilot/argus-full-agent-instructions.md`
- **Formulário ACD AI & Tooling Request preenchido** — versão v4, **entregue ao
  Igor por chat; não está no repositório** (ver seção 8).

### Pendente de decisão ou ação do Igor
1. **Teste de dez minutos** que define o tamanho do projeto Azure: no agent
   builder do Copilot, subir um PPTX com arte e verificar se o modelo **enxerga**
   as imagens que o interpretador de código extrai. Se enxergar, a camada de arte
   sai de graça e só o vídeo precisa do Azure.
2. **Formulário:** falta o link do SharePoint (slide 2) e o headcount de usuários
   (slide 3).
3. **Questão de fundo:** o formulário ACD foi desenhado para avaliar **fornecedor
   externo** (site, licença, procurement). O Argus é construção interna. Confirmar
   com o TF Lead se esse é mesmo o funil certo antes de submeter.
4. **Tabela de espanhol por país** segue marcada como rascunho: validar com
   falante nativo antes do rollout.
5. **Argus Full nunca foi executado.** É blueprint de engenharia — precisa de um
   dev para implantar e depurar.

---

## 8. O que se perdeu (e por quê)

O container desta sessão é efêmero e **já foi reciclado três vezes**, levando o
scratchpad e os uploads. Não estão aqui, e eu não consigo recriá-los:

- `ACD_AI_Tooling_Request_Form_Argus_v4.pptx` (o Igor tem; veio de template enviado)
- Os três relatórios `.docx` (C6, Santander, Gasolineras)
- Os arquivos-fonte revisados nos testes

**Tudo que era texto foi reconstruído e commitado aqui.** Os binários dependem de
upload. Se precisar mexer no formulário de novo, o Igor sobe o `.pptx` e o método
de edição está na seção 6.
