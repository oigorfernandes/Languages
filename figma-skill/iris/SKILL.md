---
name: iris
description: IRIS — transforma um layout de e-mail marketing (frame do Figma ou imagem JPEG/PNG) em HTML pronto para disparo — decide o que vira texto vivo e o que vira imagem, monta tabelas de 600px compatíveis com Gmail/Outlook/mobile e insere os links. Use sempre que o usuário apontar um frame de e-mail marketing pedindo o HTML, em português ou inglês. / IRIS — turns an email-marketing layout (Figma frame or JPEG/PNG image) into send-ready HTML. Trigger whenever the user points at an email-marketing frame asking for HTML, in Portuguese or English.
---

# IRIS · E-mail Marketing: layout → HTML

Responda no idioma do usuário (PT ou EN). Todo o conteúdo do e-mail (alt texts, comentários) segue o idioma do layout. / Reply in the user's language; email content follows the layout's language.

## Entradas

1. **Obrigatório:** o frame do layout do e-mail — selecionado/apontado pelo usuário no arquivo atual (fallback: imagem JPEG/PNG anexada).
2. **Opcional:** lista de links. Sem links, usar `#LINK` em todos os CTAs — não bloqueie por falta de links; avise no final que é só mandar as URLs.
3. **Opcional:** nome da campanha (senão, derivar do nome do frame).

## Fonte da verdade: as camadas, não os pixels

- **Textos:** copiar exatamente das camadas de texto, incluindo tokens de personalização (`[NOME]`, `%%PRINOME%%`) — nunca inventar valores; manter `[R$ x.xxx]`, `XX de XX` etc. como estão.
- **Cores:** hex exatos dos fills.
- **Tipografia:** anotar peso/tamanho, mas no HTML usar só Arial/Helvetica.
- **Medidas:** larguras, paddings e raios direto das propriedades dos frames.

## Decisão de fatiamento

| Seção | Tratamento |
|---|---|
| Faixa do logo no topo | **Fatia separada** do restante do header, com link próprio — mesmo quando o logo está sobre a arte (padrão Carrefour); fatias empilham sem emenda com `display:block` |
| Header/banner com foto e arte | **Imagem** (600px de largura), com link |
| Saudação, parágrafos, títulos | **Texto vivo** (cor/tamanho das camadas) |
| Blocos de fundo colorido com texto | `<td bgcolor>` + texto vivo dentro |
| Ícones, cartão, mockup de celular | Imagens pequenas dentro de tabelas |
| Botões/CTAs retangulares | **Botão em HTML** (`<a>` com bgcolor, border-radius, padding) |
| Rodapé institucional | **Texto vivo** |

Regra de ouro: maximizar texto vivo (entregabilidade, acessibilidade); imagem só onde há arte real. E-mail 100% imagem cai em spam — se o usuário insistir, atenda e avise do risco.

## Assets — frames de exportação (fluxo padrão)

Não exporte recortes arbitrários dos nós. Crie **frames de exportação no arquivo**:

1. Página (ou seção) separada chamada **`IRIS EXPORT`**.
2. Um frame por fatia: **nome igual ao arquivo esperado** sem extensão (`LOGO-TOPO`, `HEADER`, `BANNER01`, `SQUARES`, `ICON1`...), **tamanho 1x exato** (ex.: 600×90 para a faixa do logo), **clip content ativado**, conteúdo do layout posicionado dentro, **export setting PNG 2x**.
3. Exporte você mesmo se possível; senão, instrua o usuário a fazer batch-export da página `IRIS EXPORT`.
4. No HTML: `images/NOME.png` com `width` = tamanho 1x. Nomes ASCII, MAIÚSCULOS, sem acento.

## Padrão de código (esqueleto obrigatório)

```html
<!DOCTYPE html>
<html lang="pt-br" xmlns="http://www.w3.org/1999/xhtml" xmlns:o="urn:schemas-microsoft-com:office:office">
<head>
  <meta charset="UTF-8">
  <meta content="width=device-width, initial-scale=1" name="viewport">
  <meta name="x-apple-disable-message-reformatting">
  <meta http-equiv="X-UA-Compatible" content="IE=edge">
  <meta content="telephone=no" name="format-detection">
  <title>Email Personalizado Salesforce</title>
  <meta name="color-scheme" content="light dark">
  <meta name="supported-color-schemes" content="light dark">
  <style type="text/css">
    html, body { margin:0 !important; padding:0 !important; height:100% !important; width:100% !important; }
    * { -ms-text-size-adjust:100%; -webkit-text-size-adjust:100%; }
    table, td { mso-table-lspace:0pt; mso-table-rspace:0pt; border-collapse:collapse !important; }
    img { -ms-interpolation-mode:bicubic; border:0; outline:none; text-decoration:none; display:block; }
    a { text-decoration:none; }
    body { background-color:#ffffff; font-family: Arial, 'Helvetica Neue', Helvetica, sans-serif; }
    .container { width:100% !important; max-width:600px !important; margin:0 auto !important; }
    @media only screen and (max-width: 480px) {
      .container { width:100% !important; max-width:100% !important; }
      .stack { display:block !important; width:100% !important; max-width:100% !important; }
      .stack td { display:block !important; width:100% !important; max-width:100% !important; }
    }
    @media (prefers-color-scheme: dark) {
      .dm-bg { background-color:#111111 !important; } .dm-bg2 { background-color:#1b1b1b !important; }
      .dm-txt { color:#ffffff !important; }
    }
    [data-ogsc] .dm-bg { background-color:#111111 !important; }
    [data-ogsc] .dm-bg2 { background-color:#1b1b1b !important; }
    [data-ogsc] .dm-txt { color:#ffffff !important; }
  </style>
</head>
<body style="width:100%; padding:0; margin:0; max-width:100%;">
<custom name="opencounter" type="tracking"/>
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" align="center">
  <tr><td align="center">
    <table role="presentation" width="600" cellpadding="0" cellspacing="0" border="0" align="center" style="width:600px; max-width:100%; margin:0 auto;">

      <!-- fatia de imagem (ex.: logo, header, banner) -->
      <tr><td align="center" style="padding:0;">
        <a href="#LINK" target="_blank">
          <img src="images/HEADER.png" width="600" alt="descrever a arte" border="0"
               style="display:block; width:600px; max-width:100%; height:auto;" />
        </a>
      </td></tr>

      <!-- bloco de texto vivo sobre fundo colorido -->
      <tr><td align="center" bgcolor="#HEXFUNDO" style="background-color:#HEXFUNDO; padding:36px 20px 40px 20px;">
        <table role="presentation" width="550" cellpadding="0" cellspacing="0" border="0" align="center" style="width:550px; max-width:100%;">
          <tr><td align="center" style="font-family:Arial,sans-serif; font-size:27px; font-weight:700; line-height:130%; color:#FFFFFF;">Título do layout</td></tr>
          <tr><td height="28" style="font-size:0; line-height:0;">&nbsp;</td></tr>
          <tr><td align="center">
            <a href="#LINK" target="_blank" style="background-color:#FFFFFF; color:#HEXFUNDO; text-decoration:none; font-family:Arial,sans-serif; font-size:16px; font-weight:700; letter-spacing:.5px; text-transform:uppercase; display:inline-block; border-radius:10px; padding:15px 70px;">Texto do botão</a>
          </td></tr>
        </table>
      </td></tr>

      <!-- rodapé institucional: td bgcolor da marca contendo tabelas de contatos
           (tel: sem espaços), ícones sociais, bloco "RACISMO É CRIME." e texto legal
           em 12px branco. Seguir o rodapé das peças já aprovadas da marca. -->

    </table>
  </td></tr>
</table>
</body>
</html>
```

Placeholders de personalização sempre intocados. Telefones como `href="tel:08001234567"`. Nunca inventar URLs — se uma URL do layout parecer errada (marca trocada etc.), reproduza e sinalize no resumo.

## Verificação (obrigatória antes de entregar)

Percorra o frame de cima a baixo e confirme no HTML gerado, seção por seção: (1) textos idênticos palavra por palavra — telefones, placeholders, títulos; (2) mesmos hex; (3) mesma ordem de blocos; (4) todo ponto clicável com link ou `#LINK`. Corrija divergências antes de entregar.

## Entrega

1. `index.html` completo (arquivo para download se possível; senão, bloco de código).
2. Lista de assets: nome do arquivo → frame de export → escala.
3. Resumo: o que virou imagem vs. texto, links aplicados vs. `#LINK`, e qualquer divergência ou suspeita encontrada no layout.
