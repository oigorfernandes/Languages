---
description: IRIS — transforma um layout de e-mail marketing (JPEG/PNG) em HTML pronto para disparo — fatia a imagem, monta tabelas de 600px compatíveis com Gmail/Outlook/mobile e insere os links. / Turns an email-marketing layout image into send-ready sliced HTML with links. PT/EN.
---

# E-mail Marketing: imagem → HTML / image → HTML

Responda no idioma que o usuário usar (português ou inglês). Todo o conteúdo
do e-mail (alt texts, comentários) segue o idioma do layout enviado.
Reply in the user's language (PT or EN). All email content (alt texts,
comments) follows the language of the submitted layout.

## Entradas / Inputs

1. **Obrigatório:** uma imagem JPEG/PNG do layout completo do e-mail (idealmente 600px de largura; se vier maior, redimensionar mantendo proporção).
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

## Decisão de fatiamento (o coração do trabalho)

Analise a imagem e classifique cada seção vertical:

| Seção | Tratamento |
|---|---|
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

1. Renderizar o `index.html` em um navegador headless disponível no ambiente (Chromium/Chrome com `--headless --screenshot`, Playwright ou equivalente), com viewport de 600px de largura e altura suficiente para a peça inteira.
2. Comparar o screenshot com o layout original seção por seção: textos idênticos (números de telefone, placeholders, títulos), cores, ordem dos blocos.
3. Corrigir divergências e re-renderizar até bater.

## Entrega

1. Salvar a pasta da peça em `email-marketing/` no repositório e commitar na branch de trabalho.
2. Resumo final: o que virou imagem vs. texto, quais links foram aplicados, quais ficaram `#LINK`, e qualquer divergência ou suspeita encontrada no layout.
