# Argus — registro completo da sessão

Tudo o que foi construído, descoberto e decidido. Guardado aqui porque o ambiente de
trabalho é apagado entre sessões e o arquivo da skill já sumiu do disco duas vezes.

**Autor:** Igor Fernandes (Advisors Creative Desk)
**Arquivo da skill:** `argus-figma-skill.md` (nesta mesma pasta)

---

## 1. As duas versões do Argus

| Versão | Entrada | Saída |
|---|---|---|
| **Copilot / arquivos** (`arguscopilot.md`) | PPTX, DOCX, XLSX, PDF | Relatório em Word |
| **Figma / canvas** (`argusfigma.md`) | Frame ou página aberta no Figma | Sticky notes no canvas, ao lado de cada erro |

A versão de arquivos lê **texto dentro de imagens e vídeos embutidos** — é o
diferencial principal, porque é onde corretor nenhum chega.

**Importante, verificado:** a leitura de **imagem** foi confirmada funcionando (foi
assim que apareceram os achados do item 3 abaixo). A de **vídeo** nunca foi vista
rodando — no ambiente usado faltavam as ferramentas de vídeo, e aquela revisão cobriu
só o roteiro do slide, não os quadros. **Testar num deck com vídeo antes de divulgar
essa capacidade.**

---

## 2. Os cinco bugs da versão Figma — causa e correção

Esta é a parte mais reaproveitável do trabalho. Todos os cinco tinham sintoma visual
parecido e causa completamente diferente.

| # | Sintoma | Causa real | Correção |
|---|---|---|---|
| 1 | Notas aparecem **vazias** | Fonte não carregada antes de escrever o texto (`loadFontAsync` sem `await`, ou ausente) | Carregar a fonte com `await` antes de qualquer `characters` |
| 2 | Texto **cortado** na nota | Altura fixa (40px) que não acompanhava o conteúdo | Altura calculada na mão a partir do texto já escrito + `clipsContent = false` |
| 3 | Notas na **página errada** | O script começa toda execução na primeira página do arquivo (a "Cover"), não na que o usuário vê | Guardar o id da página de cada erro na leitura e criar a nota nessa página, com verificação que quebra se nascer em outra |
| 4 | Caixa **fina demais**, texto em coluna de uma letra | Texto em modo "preencher" (FILL) com auto-resize padrão colapsa para largura ~zero | `textAutoResize = "HEIGHT"` **antes** da largura, e largura fixa em px (nunca FILL) |
| 5 | Notas **sem hierarquia**, tudo num peso só | A receita carregava um peso único, e a checagem de fonte derrubava o script se pedisse outro | Carregar `Regular` + `Bold`, negrito só nos rótulos, com degradação para um peso se Bold faltar |

### A lição que vale além do Figma

Nas primeiras quatro rodadas a correção foi *explicar melhor em prosa* ("garanta que a
caixa caiba no texto"). **Nunca funcionou.** O que resolveu foi substituir a descrição
por **código literal na ordem exata + verificações que quebram a execução** quando o
resultado sai errado.

Armadilha específica que causou a reincidência do bug 2: no Figma, **redimensionar um
frame depois de ligar o modo "abraçar conteúdo" desliga esse modo em silêncio.** Por
isso a receita final abandona o auto-layout e calcula a altura manualmente.

---

## 3. Achados reais das revisões (prova de que funciona)

### PPT Mastercard — Campaña Gasolineras CM (espanhol, México)
- **🔴 "del 2026" vs "de 2026":** as artes 1:1, 4:5 e 9:16 diziam *"al 30 de noviembre
  **del** 2026"*, enquanto o texto do slide e a arte do vídeo diziam *"de 2026"*.
  **Esse erro estava dentro da imagem achatada** — nenhum corretor pegaria.
- 🟡 Falta de ponto final numa variação do roteiro do vídeo.
- 🟡 Espaço duplo em nota interna.
- 🟡 Separador de milhar nas resoluções (1.440 vs 1,440 — convenção do México a confirmar).

### PDF Sicoob — Sirium World Legend (português, 28 páginas)
- **🔴 "LEGENG" em vez de "LEGEND"** no cabeçalho recorrente de praticamente todas as
  páginas de conteúdo (4 a 27). O nome do produto estava certo no corpo do texto inteiro
  — só o cabeçalho-mestre estava errado.
- **🔴 "tragetória" em vez de "trajetória"** na headline do e-mail da Fase 2 (página 11).
  Erro isolado: em todas as outras peças a palavra aparece correta.

> **Nota de cuidado:** os dois decks trazem "©2026 Mastercard. Proprietary and
> Confidential" em todas as páginas. Não usar como demo pública nem anexar em canal
> amplo — usar um deck neutro com erros plantados.

**Lição de método:** num primeiro passe em baixa resolução eu *achei* ter visto dois
erros ("e trajetória" e "de Sicoob") que, ampliados, estavam corretos. Ampliar antes de
cravar não é zelo excessivo — é o que separa achado de invenção.

---

## 4. Idiomas

**15 idiomas, 19 variantes.** Português (BR/PT), inglês, espanhol (localizado por país,
incluindo Espanha), alemão, holandês, italiano, francês, bahasa indonésio, bahasa
malaio, vietnamita, chinês (simplificado; tradicional TW e HK), japonês, coreano,
hindi e árabe padrão.

### Decisões que valem lembrar

- **Indonésio e malaio são separados**, nunca um "malaio" só. Falsos amigos perigosos:
  *budak* = criança (MS) / escravo (ID); *pejabat* = escritório (MS) / autoridade (ID);
  *kereta* = carro (MS) / trem (ID).
- **Em CJK não existe "erro de ortografia"** no sentido latino — existe caractere errado
  por homófono do teclado. Por isso, nesses idiomas, mais achados saem 🟡 que 🔴.
- **Coreano:** partícula muda conforme a última letra da palavra anterior (을/를, 이/가).
  Quebra sempre depois de placeholder tipo `[이름]` — achado valioso em campanha personalizada.
- **Espanha** é a única variante com *vosotros*. Sem essa linha na tabela, o Argus
  "corrigiria" espanhol da Espanha com norma mexicana.

### Fonte

Padronizado em **Noto Sans** (+ cortes SC/TC/HK/JP/KR/Thai/Devanagari/Arabic).
Confirmado: o Figma carrega a biblioteca inteira do Google Fonts automaticamente em
qualquer arquivo, sem instalação — e toda a família Noto está lá.

Motivo de não ser uma fonte só: o formato de fonte comporta ~65 mil caracteres, e só o
CJK já passa disso. Nenhuma fonte cobre tudo; a Noto é a família feita para o problema.

### Pendente: tailandês

Deixado de fora de propósito. É o único idioma que **exige mexer no código de
renderização da nota** — as marcas de tom empilham em até 3 níveis e cortam com a
entrelinha atual de 140%, precisaria de ~160%. Como o uso é ocasional, não valia
arriscar o lote inteiro. Entra isolado depois que esta versão estiver validada.

---

## 5. Textos prontos

### Descrição para publicar no Figma (978 caracteres, limite 1024)

```
Argus reads the live text in your selection — or the page you point it to — and pins a sticky note next to every issue it finds. No exporting, no pasting copy into another tool.

It checks spelling, accents, agreement, typos and consistency. Red notes are errors; yellow ones are calls to confirm — regional wording, mixed conventions. Each note shows the text as it currently reads, the correction, and a one-line reason, pinned beside the layer it refers to.

Argus flags and suggests. It never rewrites your copy, and it doesn't review tone or brand voice.

15 languages: Portuguese, English, Spanish, German, Dutch, Italian, French, Bahasa Indonesia, Bahasa Malaysia, Vietnamese, Chinese, Japanese, Korean, Hindi and Modern Standard Arabic.

Regional variants where they matter: Portuguese (Brazil/Portugal), Spanish by country (vos, tú, vosotros), Chinese (Simplified; Traditional for Taiwan and Hong Kong).

Notes and summary are always written in the language you choose.
```

Tagline, se houver campo separado: *Spelling review, pinned right where the error is.*

### Post para a LAC AI Community (challenge #1)

```
My tip: when AI keeps getting something *almost* right, stop explaining and start writing the recipe.

Video above: Argus, a spelling reviewer I built. It reads a Figma file and pins a sticky note next to every error, on the canvas, in the language of the piece — 15 languages, with Spanish localized by country. A second version does the same for decks and PDFs, including text baked into images and video frames, where a normal spell checker can't reach.

Two catches that sold me: a product name misspelled in the running header of every page, and a date written one way in the copy and a different way inside the artwork. People had read both decks. Nobody caught either.

But the part worth sharing is how it got there. The early versions failed in ways that looked random — notes empty, then cut in half, then on the wrong page. Every time my instinct was to explain the problem better in the instructions: "make sure the box fits the text." Never stuck.

What worked was the opposite of explaining: exact steps in order, plus a self-check that stops the process when the result is wrong. Not "make sure it fits," but "measure the text, set the height, verify — if it doesn't match, redo it."

If AI gets you to 90% and stalls there, what's missing usually isn't a better description. It's a checklist, and a way for it to catch its own mistake.
```

Antes de postar: conferir se a ferramenta usada está na lista *AI approved tools*
antes de nomeá-la, e não anexar material de cliente marcado como confidencial.

### Update para o chefe

```
Atualização do Argus:

Entraram 7 idiomas nesta rodada — bahasa indonésio, bahasa malaio, vietnamita, chinês simplificado, chinês tradicional (com distinção entre Taiwan e Hong Kong), japonês e coreano. O Argus passa a cobrir 15 idiomas, além das variantes regionais de português, espanhol e chinês. Indonésio e malaio entraram separados de propósito: são próximos, mas têm falsos amigos que mudam o sentido da peça.

O tailandês ficou de fora por enquanto. É o único da lista que exige mexer na forma como as notas são desenhadas no canvas — a escrita tailandesa empilha marcas que a caixa atual corta — e, como o uso é pontual, preferi não arriscar a estabilidade dos outros idiomas nesta entrega. Estou estudando a solução pra incluir numa próxima rodada, isolado, depois que essa versão estiver validada em uso.
```

---

## 6. Próximos passos

- [ ] Testar a versão com negrito (bug 5) no Figma e confirmar a hierarquia das notas
- [ ] Rodar a versão de arquivos num deck **com vídeo embutido** para confirmar a leitura de quadros
- [ ] Coletar com o time global quais idiomas são mais pedidos
- [ ] Incluir tailandês, isolado, com entrelinha de ~160%
- [ ] Validar com nativos os rótulos de nota em hindi, árabe, tailandês e CJK
- [ ] Decidir se inglês ganha pergunta de variante US/UK (hoje a mistura sai como 🟡)
