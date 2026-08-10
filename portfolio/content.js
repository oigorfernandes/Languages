/* ═══════════════════════════════════════════════════════════════════════════
   CONTEÚDO DO PORTFÓLIO — edite SÓ este arquivo.

   Tudo que aparece no site está aqui embaixo: textos, projetos, cores, links.
   Os outros arquivos (index.html, style.css, app.js) são o "motor" e você não
   precisa mexer neles.

   REGRAS DE OURO
   1. Texto sempre entre aspas:            titulo: "Meu projeto"
   2. Itens de lista separados por vírgula: ["Motion", "3D", "IA"]
   3. Não apague as vírgulas do fim das linhas nem as chaves { }
   4. Se algo quebrar, abra o console do navegador (F12) — ele diz a linha.

   Depois de editar: salve, dê refresh no navegador. Não precisa compilar nada.
   ═══════════════════════════════════════════════════════════════════════════ */

const PORTFOLIO = {

  /* ═══ 1. IDENTIDADE ══════════════════════════════════════════════════════
     Aparece no topo, na aba do navegador e nos metadados de compartilhamento. */
  site: {
    nome:        "Priscila Andrade",
    iniciais:    "PA",                       // usado no favicon e no logo do topo
    papel:       "Motion Designer",
    local:       "São Paulo, Brasil",
    email:       "ola@seudominio.com",
    tituloAba:   "Priscila Andrade — Motion Designer",
    descricao:   "Motion designer com 8 anos de experiência em vídeo, animação e IA.",
    urlDoSite:   "https://priandradeca.com",  // usado nos metadados de compartilhamento
    imagemShare: "",                          // opcional: "img/share.jpg" (1200x630)

    // Selo de disponibilidade no topo. Deixe `disponivel: false` para esconder.
    disponivel:  true,
    textoDisponivel: "Disponível para freelas",
  },

  /* ═══ 2. TEMA ════════════════════════════════════════════════════════════
     Troque as cores aqui e o site inteiro acompanha.
     `destaque` é a cor principal (botões, links, detalhes). */
  tema: {
    destaque:      "#FF4D2E",   // laranja-coral
    destaqueTexto: "#0B0B0D",   // cor do texto EM CIMA da cor de destaque

    escuro: {
      fundo:    "#0B0B0D",
      fundo2:   "#131317",
      superficie:"rgba(255,255,255,.045)",
      borda:    "rgba(255,255,255,.10)",
      texto:    "#F4F4F5",
      apagado:  "#8A8A96",
    },

    claro: {
      fundo:    "#FBFAF8",
      fundo2:   "#F1EFEA",
      superficie:"rgba(11,11,13,.035)",
      borda:    "rgba(11,11,13,.10)",
      texto:    "#141418",
      apagado:  "#6B6B78",
    },

    temaInicial: "escuro",   // "escuro", "claro" ou "sistema"
    fonte: "'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif",
  },

  /* ═══ 3. MENU ════════════════════════════════════════════════════════════
     `alvo` é o id da seção. Apague uma linha para tirar o item do menu. */
  navegacao: [
    { rotulo: "Trabalhos", alvo: "trabalhos" },
    { rotulo: "Sobre",     alvo: "sobre"     },
    { rotulo: "Contato",   alvo: "contato"   },
  ],

  /* ═══ 4. ABERTURA (HERO) ═════════════════════════════════════════════════ */
  hero: {
    // Cada item da lista vira uma linha do título gigante.
    // Envolva um trecho em *asteriscos* para pintar com a cor de destaque.
    titulo: [
      "Movimento",
      "que conta",
      "*histórias*",
    ],
    subtitulo: "Motion designer há 8 anos. Formada em Design Gráfico pela Belas Artes. Trabalho com animação, vídeo e IA para marcas que precisam ser lembradas.",
    botoes: [
      { rotulo: "Ver trabalhos", link: "#trabalhos",              destaque: true  },
      { rotulo: "Falar comigo",  link: "mailto:ola@seudominio.com", destaque: false },
    ],
  },

  /* ═══ 5. REEL ════════════════════════════════════════════════════════════
     O vídeo grande logo abaixo da abertura.
     `video` aceita link do YouTube, do Vimeo ou um arquivo .mp4 na pasta.
     Deixe `ativo: false` para esconder a seção inteira. */
  reel: {
    ativo:     true,
    etiqueta:  "Showreel 2026",
    titulo:    "Um minuto do que eu faço",
    video:     "https://vimeo.com/76979871",
    capa:      "",   // opcional: "img/reel.jpg" — imagem antes de dar play
  },

  /* ═══ 6. TRABALHOS ═══════════════════════════════════════════════════════
     A grade de projetos. Duplique um bloco { ... } para adicionar um projeto.

     Campos de cada projeto:
       titulo      → nome do projeto                         (obrigatório)
       cliente     → marca / estúdio
       ano         → "2025"
       categorias  → viram os filtros do topo da seção       ["Motion", "3D"]
       capa        → "img/projeto.jpg". Se deixar vazio, o site desenha
                     automaticamente um cartão colorido com as iniciais.
       video       → YouTube, Vimeo ou .mp4 — abre ao clicar
       descricao   → texto que aparece ao abrir o projeto
       creditos    → lista de linhas ["Direção: Fulano", "Trilha: Ciclano"]
       link        → botão "Ver online" dentro do projeto
       destaque    → true faz o card ocupar o dobro de largura
  */
  trabalhos: {
    etiqueta:  "Portfólio",
    titulo:    "Trabalhos selecionados",
    subtitulo: "Uma amostra de campanhas, aberturas e peças de conteúdo dos últimos anos.",
    textoFiltroTudo: "Tudo",

    itens: [
      {
        titulo:     "Campanha Seguro Vida",
        cliente:    "Bradesco Seguros",
        ano:        "2025",
        categorias: ["Motion", "Publicidade"],
        capa:       "",
        video:      "https://vimeo.com/76979871",
        descricao:  "Filme de 30 segundos para TV e digital. Direção de arte, animação de personagens e finalização. A ideia era transformar burocracia de seguro em algo leve e humano — o oposto do que o setor costuma comunicar.",
        creditos:   ["Agência: Estúdio X", "Direção: Fulano de Tal", "Animação: Priscila Andrade"],
        link:       "",
        destaque:   true,
      },
      {
        titulo:     "Lançamento OLED",
        cliente:    "LG",
        ano:        "2025",
        categorias: ["3D", "Publicidade"],
        capa:       "",
        video:      "",
        descricao:  "Peças em 3D para o lançamento da linha de TVs. Modelagem, iluminação e composição — cinco formatos, do stories ao painel de loja.",
        creditos:   ["3D e composição: Priscila Andrade"],
        link:       "",
        destaque:   false,
      },
      {
        titulo:     "Snacks em movimento",
        cliente:    "Mondelēz",
        ano:        "2024",
        categorias: ["Motion", "Social"],
        capa:       "",
        video:      "",
        descricao:  "Série de doze animações curtas para redes sociais. Sistema de templates que o time interno da marca conseguiu reutilizar depois sem depender de mim.",
        creditos:   ["Animação e design: Priscila Andrade"],
        link:       "",
        destaque:   false,
      },
      {
        titulo:     "Abertura de série",
        cliente:    "Warner",
        ano:        "2024",
        categorias: ["Motion", "Branding"],
        capa:       "",
        video:      "",
        descricao:  "Vinheta de abertura e pacote gráfico completo: cartelas, créditos e transições. Referência visual em cinema analógico, com textura de filme aplicada em cima da animação digital.",
        creditos:   ["Direção de arte: Priscila Andrade"],
        link:       "",
        destaque:   false,
      },
      {
        titulo:     "Experimentos com IA",
        cliente:    "Projeto pessoal",
        ano:        "2026",
        categorias: ["IA", "Experimental"],
        capa:       "",
        video:      "",
        descricao:  "Estudos de vídeo generativo integrados a um pipeline tradicional de motion. Aqui a IA gera a textura e o material bruto; o timing, o ritmo e a edição continuam sendo trabalho humano.",
        creditos:   ["Tudo: Priscila Andrade"],
        link:       "",
        destaque:   true,
      },
      {
        titulo:     "Identidade em movimento",
        cliente:    "Estúdio independente",
        ano:        "2023",
        categorias: ["Branding", "Motion"],
        capa:       "",
        video:      "",
        descricao:  "Desdobramento de uma identidade estática em sistema animado: como o logo respira, entra, sai e reage. Entregue como manual em vídeo, não em PDF.",
        creditos:   ["Design e animação: Priscila Andrade"],
        link:       "",
        destaque:   false,
      },
    ],
  },

  /* ═══ 7. CLIENTES ════════════════════════════════════════════════════════
     Faixa deslizante com nomes de marcas. Deixe `ativo: false` para esconder. */
  clientes: {
    ativo:  true,
    titulo: "Marcas com quem já trabalhei",
    lista: [
      "Bradesco Seguros",
      "LG",
      "Mondelēz",
      "Warner",
      "Belas Artes",
      "Globo",
    ],
  },

  /* ═══ 8. SOBRE ═══════════════════════════════════════════════════════════ */
  sobre: {
    etiqueta: "Sobre",
    titulo:   "Oi, eu sou a Pri",
    foto:     "",   // "img/foto.jpg" — se vazio, mostra um cartão com as iniciais

    // Cada item da lista vira um parágrafo.
    paragrafos: [
      "Sou motion designer em São Paulo, formada em Design Gráfico pela Belas Artes. Nos últimos oito anos passei por estúdios, agências e projetos diretos com marcas — o que me deu jogo de cintura para entrar tanto num pipeline montado quanto num projeto que ainda não existe.",
      "Meu trabalho vive entre design gráfico e vídeo: animação 2D, 3D, direção de arte e, mais recentemente, ferramentas de IA integradas ao processo. Gosto de projeto com problema real, prazo real e time de verdade do outro lado.",
    ],

    // Números que aparecem em destaque. Apague a lista inteira se não quiser.
    numeros: [
      { valor: "8+",  rotulo: "anos de experiência" },
      { valor: "60+", rotulo: "projetos entregues"  },
      { valor: "20+", rotulo: "marcas atendidas"    },
    ],

    // Ferramentas / habilidades, agrupadas.
    habilidades: [
      { grupo: "Animação", itens: ["After Effects", "Cinema 4D", "Blender"] },
      { grupo: "Design",   itens: ["Illustrator", "Photoshop", "Figma"]     },
      { grupo: "Vídeo",    itens: ["Premiere", "DaVinci Resolve"]           },
      { grupo: "IA",       itens: ["Runway", "Midjourney", "ComfyUI"]       },
    ],

    // Linha do tempo. Apague a lista inteira se não quiser essa parte.
    experiencia: [
      { periodo: "2022 — hoje",  cargo: "Motion Designer freelancer", onde: "São Paulo",       texto: "Projetos diretos com marcas e agências, do roteiro à entrega final." },
      { periodo: "2019 — 2022",  cargo: "Motion Designer sênior",     onde: "Estúdio",         texto: "Campanhas de TV e digital para grandes contas de varejo e serviços." },
      { periodo: "2017 — 2019",  cargo: "Designer gráfico",           onde: "Agência",         texto: "Peças de campanha, identidade visual e primeiras animações." },
    ],
  },

  /* ═══ 9. CONTATO ═════════════════════════════════════════════════════════ */
  contato: {
    etiqueta: "Contato",
    titulo:   "Vamos fazer algo juntos?",
    texto:    "Me conta o que você tem em mente. Respondo em até um dia útil.",
    email:    "ola@seudominio.com",
    textoBotao: "Mandar um e-mail",

    // Apague as linhas das redes que você não usa.
    redes: [
      { rotulo: "Instagram", url: "https://instagram.com/",  icone: "instagram" },
      { rotulo: "Behance",   url: "https://behance.net/",    icone: "behance"   },
      { rotulo: "Vimeo",     url: "https://vimeo.com/",      icone: "vimeo"     },
      { rotulo: "LinkedIn",  url: "https://linkedin.com/in/",icone: "linkedin"  },
    ],
  },

  /* ═══ 10. RODAPÉ ═════════════════════════════════════════════════════════ */
  rodape: {
    texto: "Feito à mão em São Paulo",
  },
};
