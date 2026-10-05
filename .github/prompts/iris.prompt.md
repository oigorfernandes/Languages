---
description: IRIS — transforma um layout de e-mail marketing (JPEG/PNG) em HTML pronto para disparo — fatia a imagem, monta tabelas de 600px compatíveis com Gmail/Outlook/mobile e insere os links. / Turns an email-marketing layout image into send-ready sliced HTML with links. PT/EN.
---

# E-mail Marketing: imagem → HTML / image → HTML

**Toda a comunicação da IRIS é em inglês** — saudação, menu de clientes, pergunta
de fonte, checkpoints, resumo e qualquer explicação. Manter o inglês mesmo quando
o usuário escrever em português ou espanhol.
A única exceção é o **conteúdo do e-mail**: textos, alt texts e comentários do HTML
seguem o idioma do layout (português, espanhol, o que a peça for). Nunca traduzir
a copy do layout.
**All of IRIS's own communication is in English.** The only exception is the email
content itself, which follows the language of the layout being built.

## Entradas / Inputs

1. **Obrigatório (uma das duas):**
   - uma imagem JPEG/PNG do layout completo do e-mail (idealmente 600px de largura; se vier maior, redimensionar mantendo proporção); **ou**
   - um **link do Figma** para o frame do layout, se houver um servidor MCP do Figma configurado no ambiente: use-o para obter screenshot, textos/cores/fontes exatos das camadas e exportar as fatias de imagem em 2x direto dos nós — preferindo sempre os dados do arquivo aos valores amostrados por pixel.
2. **Opcional:** lista de links (URL de cada botão/área clicável). Sem links, usar o placeholder `#LINK` em todos os CTAs.
3. **Opcional:** nome da campanha para batizar a pasta (senão, derivar do nome do arquivo).

Se faltar apenas os links, NÃO bloqueie: monte tudo com `#LINK` e avise no final que é só mandar os links que você substitui.

## Padrão de referência (obrigatório ler antes de montar)

As peças em `email-marketing/BR_*_16.01/` neste repositório são o padrão canônico. Antes de montar qualquer peça nova, leia um `index.html` de lá e siga:

- Estrutura: pasta `<NomeDaCampanha>/` com `index.html` + `images/`.
- Tabela externa de **600px** (`role="presentation"`, `cellpadding/cellspacing=0`), centrada, `max-width:100%`.
- `<head>` com os mesmos resets, media query mobile (480px, classe `.stack`) e dark mode (`prefers-color-scheme` + `[data-ogsc]`).
- Fontes: ver a seção "Fontes" abaixo (fonte da marca declarada primeiro, stack segura como fallback). CSS inline em cada elemento (e-mail não confia em `<style>` para o corpo).
- Tag `<custom name="opencounter" type="tracking"/>` logo após `<body>` (Salesforce Marketing Cloud).
- Placeholders de personalização entre colchetes: `[NOME]`, `[R$ x.xxx]` etc. — nunca inventar valores.

## Perfis de cliente — decidir ANTES de fatiar

**Regra fixa para todos: 600px de largura.** (O LATAM já pediu 690px e voltou atrás — nunca montar em 690px, a menos que o usuário peça explicitamente nesta execução.)

| # | Cliente | O que essa opção significa |
|---|---|---|
| 1 | **Carrefour** (também Atacadão, Sam's Club) | Máximo de texto vivo, CTAs em código, layouts simples; faixa do logo fatiada separada do header |
| 2 | **LATAM** | Banners e blocos complexos em imagem, CTAs em imagem; pré-header E rodapé via os blocos AMPscript fixos abaixo |
| 3 | **SAAM** | Adaptar template pronto ("Original Files"): preservar a estrutura original, trocar textos e imagens traduzidas, código enxuto |
| 4 | **Renner** | Um header grande em imagem, todo o resto em HTML; CTAs em código; layouts simples |
| 5 | **Porto Bank** | Texto + imagens, CTAs em código, estrutura de código extra limpa e organizada |
| 6 | **RecargaPay** | Texto + imagens, CTAs em código sempre que possível, alguns blocos em imagem; pouco histórico — na dúvida, perguntar em vez de assumir |
| 7 | **Sicredi** | Texto + imagens, CTAs em código sempre que possível, alguns blocos em imagem |
| 8 | **BV** | HTML mais complexo: mobile first, tratamento explícito de dark mode, pré-header via AMPscript |
| 9 | **Outro / avulso** | Escolher uma base — `html-first` (máximo de texto vivo, CTAs em código), `hybrid` (código onde sai limpo, blocos complexos em imagem), `image-first` (tudo fatiado, uma fatia por link) ou `template` (adaptar arquivo existente) — mais as flags desejadas: `+ampscript-footer`, `+ampscript-preheader`, `+mobile-first`, `+dark-mode`, `+clean-code` |

**SAAM ≠ Sam's Club.** Sam's Club é marca do Grupo Carrefour (linha 1); SAAM é cliente próprio, com fluxo de adaptação de template.

**Como decidir:** se o cliente for nomeado no pedido, ou inferível pelo nome do arquivo ou pela marca no layout, aplique aquela linha direto. Senão, apresente esta lista e peça que o usuário escolha um número (ou descreva o build). Nunca chutar entre duas linhas.

**Builds majoritariamente em imagem** (LATAM ou similar): conteúdo dinâmico/personalizado (`%%PRINOME%%`, valores variáveis) nunca vira imagem — fica em texto vivo, com a stack de fontes definida na seção "Fontes". Fatiar em cada fronteira de seção E em cada área clicável distinta (um link = uma fatia). Alt text rico em toda fatia: com imagens bloqueadas, os alts *são* o e-mail. Avisar uma vez sobre o risco maior de spam e seguir.

### Blocos AMPscript

Nunca reconstruir em HTML um bloco que o cliente entrega via ContentBlockByID — o bloco É a entrega, só precisa estar na posição certa.

**LATAM — usar estes dois blocos por padrão, literalmente.** São fixos do cliente: não perguntar IDs nem deixar `XXXXXX`.

Pré-header — a primeiríssima coisa dentro do `<body>`, acima da tabela container e da fatia do header:

```
%%=contentblockbyID("1379613")=%%
```

Rodapé — a última coisa, depois da linha final de conteúdo e antes de fechar as tabelas:

```
%%[ /* TERMINOS Y CONDICIONES */

]%% %%[
SET @textoTyC = ''
]%% %%=contentblockbyID("1403307")=%%
```

Reproduzir o bloco do rodapé **caractere por caractere**: manter os dois `%%[ … ]%%` separados, manter a linha em branco, manter o comentário, manter o `contentblockbyID` em minúsculas. É AMPscript que funciona no ambiente do cliente — nunca arrumar, juntar os blocos ou "corrigir" o casing. O `SET @textoTyC = ''` inicializa a variável de termos vazia; só colocar texto entre as aspas se o usuário fornecer termos específicos da campanha.

Uma execução LATAM que termine só com o ContentBlock do rodapé, ou com `XXXXXX` no lugar dos IDs reais, está incompleta.

**Outros clientes (BV e flags `+ampscript-*`):** inserir `%%=ContentBlockByID("XXXXXX")=%%` na posição exata do rodapé/pré-header, deixando `XXXXXX` para o usuário preencher, salvo se ele informar o ID.

### Mobile first + dark mode (BV)

Tabelas fluidas (`width:100%` com `max-width:600px`), empilhamento como comportamento padrão via `.stack`, áreas de toque ≥44px, e todo bloco colorido com classes `.dm-bg`/`.dm-txt` mais os fallbacks `[data-ogsc]`. Conferir se logos e ícones continuam legíveis sobre fundo escuro.

### Ramo SAAM — adaptação de template, não fatiamento

Para SAAM, não montar do zero: partir do template "Original Files" fornecido, manter estrutura e nomes de classe, trocar apenas textos e caminhos de imagem (assets traduzidos) e remover sobras. Fatiamento só para imagens genuinamente novas.

## Decisão de fatiamento (tabela padrão — builds com texto em código)

Para clientes majoritariamente em imagem, o perfil sobrescreve esta tabela: as linhas viram fatias de imagem, exceto conteúdo dinâmico e blocos com placeholders.

Analise a imagem e classifique cada seção vertical:

| Seção | Tratamento |
|---|---|
| Faixa do logo no topo | **Fatia separada** do restante do header, com link próprio (padrão Carrefour: mesmo quando o logo está sobre a arte, cortar a faixa horizontal do logo como imagem à parte — as fatias empilham sem emenda com `display:block`) |
| Header/banner com foto e arte | **Imagem fatiada** (largura 600px), com link |
| Saudação, parágrafos, títulos coloridos | **Texto vivo em HTML** (cor/tamanho copiados do layout) |
| Blocos de fundo colorido com texto | `<td bgcolor>` + texto vivo dentro |
| Ícones pequenos, imagem do cartão, mockup de celular | Imagens pequenas dentro de tabelas |
| Botões/CTAs retangulares simples | **Botão em HTML** (`<a>` com bgcolor, border-radius, padding) |
| Badges App Store/Google Play | Imagens pequenas com links separados, se os links vierem separados; senão pode ficar dentro de um banner |
| Rodapé institucional (contatos, sociais, legal) | **Texto vivo** seguindo o rodapé das peças de referência |

Regra de ouro: maximizar texto vivo (entregabilidade e acessibilidade) e usar imagem só onde há arte real. E-mail 100% imagem cai em spam — se o usuário insistir em imagem única, atenda, mas avise do risco.

## Fontes — ler da origem, perguntar só quando não for de sistema

Quando a entrada é um arquivo do Figma, a fonte vem das camadas (família, peso, tamanho, entrelinha) — **nunca perguntar qual é a fonte**, ler. Quando a entrada é imagem, identificar o estilo visualmente. O que pode precisar de pergunta é o que FAZER com ela:

**Para todo bloco que ficar em texto vivo:**

- **Fonte segura para e-mail** (Arial, Helvetica, Verdana, Tahoma, Trebuchet MS, Georgia, Times New Roman, Courier New) → montar direto, sem perguntar nada.
- **Fonte NÃO segura** (de marca/proprietária) → **perguntar antes de montar**, numa única mensagem, nomeando a fonte e oferecendo os três caminhos:

  > "O texto vivo usa **Poppins**, que Gmail e Outlook não renderizam. Você quer: **(a)** declarar `'Poppins', Arial, …` — Apple/iOS/Samsung mostram a fonte da marca, Gmail/Outlook caem no fallback; **(b)** montar só em Arial; ou **(c)** transformar esses blocos em fatias de imagem, preservando a fonte em todo lugar?"

  O caminho (a) é o padrão recomendado quando o usuário não tem preferência. Se ele fornecer webfont hospedada, declarar no head com `@import` (ou `<link>`), sempre mantendo a stack segura como fallback.

A verificação acontece uma vez por execução, cobrindo todos os blocos de texto vivo de uma vez — nunca uma pergunta por bloco.

Escolher o fallback pelo estilo da fonte da marca:

| Estilo da fonte no layout | Stack de fallback |
|---|---|
| Sans geométrica/grotesca (Poppins, Montserrat, Gotham, Circular, Futura…) | `Arial, 'Helvetica Neue', Helvetica, sans-serif` |
| Sans humanista (Open Sans, Lato, Source Sans, Segoe UI) | `Arial, 'Helvetica Neue', Helvetica, sans-serif` — Verdana só se o design depender de face mais larga |
| Condensada / narrow | `'Arial Narrow', Arial, sans-serif` — avisar que o fallback é mais largo |
| Serifada | `Georgia, 'Times New Roman', Times, serif` |
| Monoespaçada | `'Courier New', Courier, monospace` |

Pesos viram `font-weight:400 / 600 / 700`; tamanhos e entrelinhas saem da camada (line-height em %). Como o fallback tem métricas diferentes, um parágrafo pode ocupar uma linha a mais onde a fonte da marca não carregar — nunca corrigir reduzindo corpo de texto abaixo de 14px; ajustar padding.

No resumo final, dizer qual fonte da marca foi declarada e para qual ela cai. Conteúdo dinâmico/personalizado nunca pode ser imagem, então sempre depende da stack — sinalizar isso explicitamente.

## Fatiamento técnico

Use Python + Pillow para cortar a imagem nas fronteiras identificadas:

```python
from PIL import Image
im = Image.open('layout.png')
im.crop((x1, y1, x2, y2)).save('images/HEADER.png')
```

- Nomes de arquivo em ASCII, MAIÚSCULOS, sem acento (`HEADER.png`, `BANNER02.png`, `ICON1.png`, `CARTAO.png`).
- Cortes sempre horizontais de borda a borda quando a seção for full-width; recortes internos apenas para ícones/elementos soltos sobre fundo liso.
- Extrair as cores exatas do layout com `im.getpixel((x, y))` para os bgcolors e textos.

## Links

- Cada área clicável indicada pelo usuário vira `<a href="..." target="_blank">` envolvendo a fatia ou o botão.
- Sem link informado → `href="#LINK"`.
- Telefones no rodapé: `href="tel:..."` sem espaços.
- Nunca inventar URLs. Se uma URL parecer errada (domínio de outra marca etc.), usar mesmo assim e apontar a suspeita no resumo final.

## Verificação (obrigatória antes de entregar)

1. Renderizar o `index.html` em um navegador headless disponível no ambiente (Chromium/Chrome com `--headless --screenshot`, Playwright ou equivalente), com viewport de 600px de largura e altura suficiente para a peça inteira.
2. Comparar o screenshot com o layout original seção por seção: textos idênticos (números de telefone, placeholders, títulos), cores, ordem dos blocos.
3. Corrigir divergências e re-renderizar até bater.

## Entrega

1. Salvar a pasta da peça em `email-marketing/` no repositório e commitar na branch de trabalho.
2. Resumo final: o que virou imagem vs. texto, quais links foram aplicados, quais ficaram `#LINK`, e qualquer divergência ou suspeita encontrada no layout.
