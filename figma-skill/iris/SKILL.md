---
name: iris
description: IRIS — transforma um layout de e-mail marketing (frame do Figma ou imagem JPEG/PNG) em HTML pronto para disparo — decide o que vira texto vivo e o que vira imagem, monta tabelas de 600px compatíveis com Gmail/Outlook/mobile e insere os links. Use sempre que o usuário apontar um frame de e-mail marketing pedindo o HTML, em português ou inglês. / IRIS — turns an email-marketing layout (Figma frame or JPEG/PNG image) into send-ready HTML: decides what becomes live text vs. image, builds 600px email-safe tables and wires up the links. Trigger whenever the user points at an email-marketing frame asking for HTML, in Portuguese or English.
---

# IRIS · E-mail Marketing: layout → HTML

Versão para o agente do Figma. Responda no idioma que o usuário usar
(português ou inglês). Todo o conteúdo do e-mail (alt texts, comentários)
segue o idioma do layout.
Figma-agent version. Reply in the user's language (PT or EN). All email
content follows the language of the layout.

## Entradas / Inputs

1. **Obrigatório:** o frame do layout do e-mail — o frame selecionado/apontado pelo usuário no arquivo atual, ou um link para o frame. (Fallback: uma imagem JPEG/PNG anexada, se não houver frame.)
2. **Opcional:** lista de links (URL de cada botão/área clicável). Sem links, usar o placeholder `#LINK` em todos os CTAs.
3. **Opcional:** nome da campanha para batizar os arquivos (senão, derivar do nome do frame).

Se faltar apenas os links, NÃO bloqueie: monte tudo com `#LINK` e avise no final que é só mandar os links que você substitui.

## Fonte da verdade: as camadas, não os pixels

Trabalhando dentro do Figma, extraia tudo do próprio arquivo:

- **Textos**: copiar o conteúdo exato das camadas de texto (incluindo tokens de personalização como `[NOME]` ou `%%PRINOME%%` — nunca inventar valores).
- **Cores**: usar os fills/hex exatos das camadas (fundos, textos, botões).
- **Tipografia**: anotar peso e tamanho de cada texto, mas no HTML usar apenas Arial/Helvetica (e-mail não carrega webfonts) — mapeie o peso (bold/regular) e o tamanho aproximado.
- **Medidas**: larguras, paddings e raios de borda direto das propriedades dos frames.

## Padrão de código (obrigatório ler `REFERENCE.html` desta skill antes de montar)

O arquivo `REFERENCE.html` incluído nesta skill é uma peça real e canônica. Siga a estrutura dele:

- Tabela externa de **600px** (`role="presentation"`, `cellpadding/cellspacing=0`), centrada, `max-width:100%`.
- `<head>` com os mesmos resets, media query mobile (480px, classe `.stack`) e dark mode (`prefers-color-scheme` + `[data-ogsc]`).
- Fontes: Arial/Helvetica apenas. CSS inline em cada elemento (e-mail não confia em `<style>` para o corpo).
- Tag `<custom name="opencounter" type="tracking"/>` logo após `<body>` (Salesforce Marketing Cloud).
- Rodapé institucional: seguir o bloco de rodapé do `REFERENCE.html` (contatos, sociais, aviso legal), adaptando textos ao layout novo.

## Decisão de fatiamento (o coração do trabalho)

Classifique cada seção vertical do frame:

| Seção | Tratamento |
|---|---|
| Faixa do logo no topo | **Fatia separada** do restante do header, com link próprio (padrão Carrefour: mesmo quando o logo está sobre a arte, cortar a faixa horizontal do logo como imagem à parte — as fatias empilham sem emenda com `display:block`) |
| Header/banner com foto e arte | **Imagem exportada** (600px de largura, exportar em 2x), com link |
| Saudação, parágrafos, títulos coloridos | **Texto vivo em HTML** (cor/tamanho das camadas) |
| Blocos de fundo colorido com texto | `<td bgcolor>` + texto vivo dentro |
| Ícones pequenos, cartão, mockup de celular | Imagens pequenas exportadas dos nós, dentro de tabelas |
| Botões/CTAs retangulares simples | **Botão em HTML** (`<a>` com bgcolor, border-radius, padding) |
| Badges App Store/Google Play | Imagens pequenas com links separados quando os links vierem separados |
| Rodapé institucional | **Texto vivo** seguindo o `REFERENCE.html` |

Regra de ouro: maximizar texto vivo (entregabilidade e acessibilidade) e usar imagem só onde há arte real. E-mail 100% imagem cai em spam — se o usuário insistir em imagem única, atenda, mas avise do risco.

## Assets — frames de exportação (fluxo padrão)

Não tente exportar recortes arbitrários dos nós. Em vez disso, **crie frames de exportação diretamente no arquivo do Figma**:

1. Crie uma página (ou seção) separada chamada **`IRIS EXPORT`** — nunca misturar com o layout.
2. Para cada fatia do e-mail, crie ali um frame com:
   - **nome exatamente igual ao arquivo esperado** (sem extensão): `LOGO-TOPO`, `HEADER`, `BANNER01`, `SQUARES`, `ICON1`...
   - **tamanho 1x exato da fatia** (ex.: 600×90 para a faixa do logo, 600 de largura para seções full-width);
   - **clip content ativado** (senão o export sai com sobras);
   - o conteúdo correspondente do layout posicionado dentro (instância/cópia da arte);
   - **export setting PNG em 2x** já configurado no frame.
3. Exporte os frames você mesmo se o ambiente permitir; senão, avise o usuário que é só selecionar a página `IRIS EXPORT` e fazer batch-export — os arquivos já saem com nome e escala certos.
4. No HTML, referencie como `images/NOME.png`, com `width` = tamanho em 1x.

Nomes sempre em ASCII, MAIÚSCULOS, sem acento. Se o layout mudar depois, os frames de export continuam válidos — basta re-exportar.

## Links

- Cada área clicável indicada pelo usuário vira `<a href="..." target="_blank">` envolvendo a fatia ou o botão.
- Sem link informado → `href="#LINK"`.
- Telefones no rodapé: `href="tel:..."` sem espaços.
- Nunca inventar URLs. Se uma URL parecer errada (domínio de outra marca etc.), usar mesmo assim e apontar a suspeita no resumo final.

## Verificação (obrigatória antes de entregar)

Sem navegador disponível, a conferência é contra as camadas: percorra o frame de cima a baixo e confirme, seção por seção, que o HTML gerado tem (1) os mesmos textos, palavra por palavra — telefones, placeholders, títulos; (2) as mesmas cores hex; (3) a mesma ordem de blocos; (4) todos os pontos clicáveis com link ou `#LINK`. Corrija qualquer divergência antes de entregar.

## Entrega

1. Entregar o `index.html` completo (arquivo para download se o ambiente permitir; senão, em bloco de código).
2. Junto, a lista de assets: nome do arquivo → nó do Figma → escala de export.
3. Resumo final: o que virou imagem vs. texto, quais links foram aplicados, quais ficaram `#LINK`, e qualquer divergência ou suspeita encontrada no layout.
