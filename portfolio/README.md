# Portfólio

Site de portfólio estático, no mesmo espírito do Chimba: **sem build, sem npm, sem framework**.
Você edita um arquivo de texto, salva, e o site muda.

```
portfolio/
├── content.js   ← 👈 é aqui que você mexe (todo o conteúdo e as cores)
├── index.html      estrutura da página
├── style.css       estilos
├── app.js          o motor que monta a página a partir do content.js
└── img/            suas imagens (capas, foto, etc.)
```

## Como editar

Abra `content.js`. Está tudo lá dentro, em português e comentado: nome, textos,
projetos, cores, links de redes sociais. Salve o arquivo, atualize o navegador.

Três regras que evitam 99% dos problemas:

1. Texto sempre entre aspas — `titulo: "Meu projeto"`
2. Vírgula no fim de cada linha e entre itens de lista — `["Motion", "3D"]`
3. Não apague as chaves `{ }` nem os colchetes `[ ]`

Se a página aparecer em branco, aperte `F12` no navegador e olhe a aba Console:
ela diz exatamente qual linha do `content.js` está com problema (quase sempre é
uma vírgula ou aspa faltando).

## Ver o site na sua máquina

Basta abrir o `index.html` com dois cliques. Se quiser servir de verdade
(recomendado, porque alguns navegadores bloqueiam vídeos em `file://`):

```bash
cd portfolio
python3 -m http.server 8000
# depois abra http://localhost:8000
```

## Adicionar um projeto

Em `content.js`, dentro de `trabalhos.itens`, copie um bloco `{ ... }` inteiro,
cole logo abaixo e troque o conteúdo:

```js
{
  titulo:     "Nome do projeto",
  cliente:    "Nome da marca",
  ano:        "2026",
  categorias: ["Motion", "3D"],      // viram os filtros do topo, sozinhas
  capa:       "img/meu-projeto.jpg", // deixe "" para gerar um card automático
  video:      "https://vimeo.com/123456789",
  descricao:  "O que era o projeto e qual foi o seu papel nele.",
  creditos:   ["Direção: Fulano", "Trilha: Ciclano"],
  link:       "",                    // opcional, vira o botão "Ver online"
  destaque:   false,                 // true faz o card ocupar a largura dobrada
},
```

**Vídeos**: cole o link normal do YouTube ou do Vimeo — o site converte sozinho.
Também aceita arquivo local: `"img/reel.mp4"`.

**Imagens**: jogue os arquivos dentro de `portfolio/img/` e aponte para eles
(`"img/nome-do-arquivo.jpg"`). Capas ficam melhores em 1600×1200 (4:3) ou
1920×1080 (16:9) para os projetos em destaque. Se você deixar `capa: ""`, o site
desenha automaticamente um cartão colorido com as iniciais do projeto — dá para
publicar antes de ter as imagens prontas.

## Trocar as cores

Tudo no bloco `tema` do `content.js`. A cor `destaque` é a que manda: botões,
links, números, detalhes. Existem duas paletas — `escuro` e `claro` — e o
visitante alterna entre elas pelo botão no topo. `temaInicial` define qual abre
por padrão (`"escuro"`, `"claro"` ou `"sistema"`).

## Esconder seções

- **Reel**: `reel.ativo: false`
- **Clientes**: `clientes.ativo: false`
- **Selo de disponibilidade**: `site.disponivel: false`
- **Números / experiência / habilidades**: apague a lista inteira (deixe `[]`)
- **Item do menu**: apague a linha correspondente em `navegacao`

## Publicar

O site é estático, então qualquer hospedagem serve.

**GitHub Pages** — em *Settings → Pages*, escolha a branch e a pasta `/root`.
O portfólio fica em `https://SEU-USUARIO.github.io/languages/portfolio/`.
Para servir na raiz do domínio, mova os quatro arquivos e a pasta `img/` para a
raiz de um repositório próprio.

**Netlify / Vercel / Cloudflare Pages** — arraste a pasta `portfolio/` na
interface deles. Não há passo de build para configurar.

**Domínio próprio** — aponte o DNS para a hospedagem escolhida e ajuste
`site.urlDoSite` no `content.js` (isso só afeta os metadados de compartilhamento).

## Detalhes técnicos

- Zero dependências de JavaScript. A única requisição externa é a fonte Inter do
  Google Fonts; se ela falhar, o site cai na fonte do sistema sem quebrar.
- Os textos do `content.js` são escapados antes de virar HTML.
- Acessibilidade: navegação por teclado, `Esc` fecha a janela de projeto e o
  menu, foco visível, e as animações desligam sozinhas para quem tem
  `prefers-reduced-motion` ativado.
- O favicon é gerado na hora a partir das iniciais e da cor de destaque — não há
  arquivo de ícone para manter.
