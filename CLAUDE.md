# Instruções do projeto

## Comando: SALVA NO CEREBRO

Quando o usuário disser **"SALVA NO CEREBRO"** (ou variações como "salva no cérebro"),
execute os três passos abaixo, nesta ordem. Não pergunte confirmação — só execute.

### IDs fixos (não procurar, já conferidos)

| O quê | ID |
|---|---|
| Pasta **Cérebro** | `1zqEY64sckggQ3i3KPD5N8HYU48V1eOyM` |
| Subpasta **Registros** | `1JEaAAnslYZScNUQUXdsNqsxsn7RLPv-9` |
| Doc **00 Índice do Cérebro** | `1ETc4MiOSATW6OXxPgHTuK0xRbae93YTlSz8_3UKC5Oo` |

**Nunca salvar na pasta "Argus — ACD"** — ela foi descontinuada.

### Passo 1 — Nota-resumo (Google Doc, na pasta Cérebro)

- Título no formato **`AAAA-MM-DD Assunto`**.
- **Links para os registros no topo** do documento (os docs criados no passo 2).
- Corpo: o resumo do que foi pedido, feito e decidido.
- **Palavras-chave no final.**

### Passo 2 — Registros (Google Docs, na subpasta Registros)

- O **registro completo**: tudo o que foi pedido e feito, decisões, o que mudou entre
  versões, achados, ressalvas.
- **O conteúdo integral de cada arquivo criado ou alterado — um Google Doc por arquivo**,
  com o **caminho do arquivo no título**.

### Passo 3 — Linha no índice

No doc **00 Índice do Cérebro**, insira **uma linha no topo da seção "Notas"**
(a mais recente fica sempre em primeiro), seguindo exatamente o formato das existentes:

```
- [**AAAA-MM-DD Assunto**](link da nota). Resumo em uma ou duas frases. Palavras-chave: a, b, c.
```

O título vai **em negrito e linkado** para a nota-resumo do passo 1.

### Estrutura do índice (para referência)

Seções na ordem: `Como usar` · `Documentos fixos` (01 Quem sou eu, 02 Projetos,
03 Ideias) · `Notas`. Só a seção Notas recebe linhas novas.

### Armadilhas já conhecidas ao escrever no Drive

- **Converter HTML para Google Doc quebra emoji.** 🔴 e 🟡 viram caracteres corrompidos
  (`ð´`, `ð¡`), e o negrito dentro de tabelas pode se perder. Se o conteúdo depender de
  emoji, confira o resultado depois de criar e corrija, ou suba também uma versão em
  markdown puro.
- **Para Google Doc formatado:** `create_file` com `contentMimeType: "text/html"`.
- **Para arquivo fiel byte a byte:** `create_file` com o mime real e
  `disableConversionToGoogleType: true`.
- **Sempre conferir o resultado** com `read_file_content` antes de reportar como pronto.
