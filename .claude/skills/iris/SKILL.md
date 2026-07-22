---
name: iris
description: IRIS — transforma um layout de e-mail marketing (JPEG/PNG) em HTML pronto para disparo — fatia a imagem, monta tabelas de 600px compatíveis com Gmail/Outlook/mobile e insere os links. Use sempre que o usuário enviar uma imagem de peça de e-mail marketing pedindo o HTML, em português ou inglês. / Turns an email-marketing layout image (JPEG/PNG) into send-ready HTML — slices the image, builds 600px email-safe tables and wires up the links. Trigger whenever the user sends an email-marketing layout image asking for HTML, in Portuguese or English.
---

# E-mail Marketing: imagem → HTML / image → HTML

Responda no idioma que o usuário usar (português ou inglês). Todo o conteúdo
do e-mail (alt texts, comentários) segue o idioma do layout enviado.
Reply in the user's language (PT or EN). All email content (alt texts,
comments) follows the language of the submitted layout.

## Entradas / Inputs

1. **Obrigatório (uma das duas):**
   - uma imagem JPEG/PNG do layout completo do e-mail (idealmente 600px de largura; se vier maior, redimensionar mantendo proporção); **ou**
   - um **link do Figma** para o frame do layout. Nesse caso, use as ferramentas do Figma MCP: `get_screenshot` para a visão geral, `get_design_context`/`get_metadata` para textos, cores e fontes exatos das camadas, e `download_assets` para exportar as fatias de imagem em 2x direto dos nós — preferindo sempre os dados do arquivo aos valores amostrados por pixel.
2. **Opcional:** lista de links (URL de cada botão/área clicável). Sem links, usar o placeholder `#LINK` em todos os CTAs.
3. **Opcional:** nome da campanha para batizar a pasta (senão, derivar do nome do arquivo).

Se faltar apenas os links, NÃO bloqueie: monte tudo com `#LINK` e avise no final que é só mandar os links que você substitui.

## Padrão de referência (obrigatório ler antes de montar)

As peças em `email-marketing/BR_*_16.01/` neste repositório são o padrão canônico. Antes de montar qualquer peça nova, leia um `index.html` de lá e siga:

- Estrutura: pasta `<NomeDaCampanha>/` com `index.html` + `images/`.
- Tabela externa de **600px** (`role="presentation"`, `cellpadding/cellspacing=0`), centrada, `max-width:100%`.
- `<head>` com os mesmos resets, media query mobile (480px, classe `.stack`) e dark mode (`prefers-color-scheme` + `[data-ogsc]`).
- Fontes: Arial/Helvetica apenas. CSS inline em cada elemento (e-mail não confia em `<style>` para o corpo).
- Tag `<custom name="opencounter" type="tracking"/>` logo após `<body>` (Salesforce Marketing Cloud).
- Placeholders de personalização entre colchetes: `[NOME]`, `[R$ x.xxx]` etc. — nunca inventar valores.

## Modo de renderização — decidir ANTES de fatiar

Clientes diferentes exigem builds diferentes:

- **Modo A — TEXTO VIVO** (ex.: Carrefour, Atacadão, Sam's Club): máximo de texto no código. Usa a tabela de fatiamento abaixo.
- **Modo B — IMAGEM** (ex.: LATAM): o cliente exige a fonte proprietária, então tudo vira imagem fatiada — EXCETO conteúdo dinâmico/personalizado (`%%PRINOME%%`, valores variáveis), que não pode ser imagem e fica em texto vivo com Arial. Nesse modo: fatiar em cada fronteira de seção E em cada área clicável distinta (cada link precisa da própria fatia); alt text rico e completo em toda fatia; avisar uma vez sobre o risco maior de spam e seguir.

Se o usuário nomeou o modo ou o cliente, aplique (marcas do Grupo Carrefour → Modo A; LATAM → Modo B). Senão, faça UMA pergunta curta antes de executar: "Build em texto vivo (estilo Carrefour) ou em imagem (estilo LATAM, fonte proprietária)?".

## Decisão de fatiamento — Modo A (o coração do trabalho)

No Modo B esta tabela é sobrescrita: toda linha vira "fatia de imagem", exceto conteúdo dinâmico/personalizado e blocos com placeholders, que ficam em texto vivo.

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

1. Renderizar com o Chromium headless disponível em `/opt/pw-browsers/`:
   ```
   /opt/pw-browsers/chromium_headless_shell-*/chrome-linux/headless_shell \
     --headless --disable-gpu --no-sandbox --hide-scrollbars \
     --window-size=600,3300 --screenshot=preview.png "file://<caminho>/index.html"
   ```
2. Comparar o screenshot com o layout original seção por seção: textos idênticos (números de telefone, placeholders, títulos), cores, ordem dos blocos.
3. Corrigir divergências e re-renderizar até bater.

## Entrega

1. Salvar a pasta da peça em `email-marketing/` no repositório, commitar e fazer push na branch de trabalho.
2. Zipar a pasta e enviar ao usuário com `SendUserFile` (zip como `attach`, preview como `render`).
3. Resumo final: o que virou imagem vs. texto, quais links foram aplicados, quais ficaram `#LINK`, e qualquer divergência ou suspeita encontrada no layout.
