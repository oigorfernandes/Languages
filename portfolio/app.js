/* ═══════════════════════════════════════════════════════════════════════════
   Motor do portfólio. Lê o content.js e monta a página.
   Você normalmente NÃO precisa mexer aqui.
   ═══════════════════════════════════════════════════════════════════════════ */

(function () {
  'use strict';

  const P = typeof PORTFOLIO !== 'undefined' ? PORTFOLIO : null;
  if (!P) {
    document.body.innerHTML = '<p style="padding:40px;font:16px sans-serif">' +
      'Não consegui ler o <b>content.js</b>. Verifique se o arquivo existe e se não ' +
      'ficou nenhuma vírgula ou chave sobrando (abra o console com F12 para ver a linha).</p>';
    return;
  }

  const $  = (id) => document.getElementById(id);
  const el = (tag, cls, html) => {
    const n = document.createElement(tag);
    if (cls)  n.className = cls;
    if (html != null) n.innerHTML = html;
    return n;
  };

  /* Escapa texto vindo do content.js antes de virar HTML */
  const esc = (s) => String(s == null ? '' : s)
    .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');

  /* *destaque* → <em>destaque</em> */
  const enfase = (s) => esc(s).replace(/\*([^*]+)\*/g, '<em>$1</em>');

  const iniciaisDe = (txt, n = 2) => String(txt || '?')
    .split(/\s+/).filter(Boolean).slice(0, n)
    .map(p => p[0]).join('').toUpperCase();

  /* ═══ Tema ═════════════════════════════════════════════════════════════ */
  const T = P.tema || {};
  const CHAVE_TEMA = 'portfolio-tema';

  function aplicarTema(modo) {
    const p = (modo === 'claro' ? T.claro : T.escuro) || {};
    const r = document.documentElement.style;
    r.setProperty('--fundo',      p.fundo      || '#0B0B0D');
    r.setProperty('--fundo2',     p.fundo2     || '#131317');
    r.setProperty('--superficie', p.superficie || 'rgba(255,255,255,.045)');
    r.setProperty('--borda',      p.borda      || 'rgba(255,255,255,.10)');
    r.setProperty('--texto',      p.texto      || '#F4F4F5');
    r.setProperty('--apagado',    p.apagado    || '#8A8A96');
    r.setProperty('--destaque',       T.destaque       || '#FF4D2E');
    r.setProperty('--destaque-texto', T.destaqueTexto  || '#0B0B0D');
    if (T.fonte) r.setProperty('--fonte', T.fonte);

    document.documentElement.dataset.tema = modo;
    document.documentElement.style.colorScheme = modo === 'claro' ? 'light' : 'dark';
    meta('name', 'theme-color', p.fundo);

    const btn = $('btn-tema');
    if (btn) {
      btn.textContent = modo === 'claro' ? '☾' : '☀';
      btn.setAttribute('aria-label', modo === 'claro' ? 'Mudar para tema escuro' : 'Mudar para tema claro');
    }
    localStorage.setItem(CHAVE_TEMA, modo);
  }

  function temaInicial() {
    const salvo = localStorage.getItem(CHAVE_TEMA);
    if (salvo === 'claro' || salvo === 'escuro') return salvo;
    if (T.temaInicial === 'sistema') {
      return matchMedia('(prefers-color-scheme: light)').matches ? 'claro' : 'escuro';
    }
    return T.temaInicial === 'claro' ? 'claro' : 'escuro';
  }

  aplicarTema(temaInicial());
  $('btn-tema').addEventListener('click', () => {
    aplicarTema(document.documentElement.dataset.tema === 'claro' ? 'escuro' : 'claro');
  });

  /* ═══ Cabeça do documento ══════════════════════════════════════════════ */
  const S = P.site || {};
  document.title = S.tituloAba || `${S.nome || 'Portfólio'} — ${S.papel || ''}`.trim();

  function meta(attr, chave, valor) {
    if (!valor) return;
    let m = document.head.querySelector(`meta[${attr}="${chave}"]`);
    if (!m) { m = document.createElement('meta'); m.setAttribute(attr, chave); document.head.appendChild(m); }
    m.setAttribute('content', valor);
  }
  meta('name', 'description', S.descricao);
  meta('property', 'og:title', document.title);
  meta('property', 'og:description', S.descricao);
  meta('property', 'og:type', 'website');
  meta('property', 'og:url', S.urlDoSite);
  meta('name', 'twitter:card', S.imagemShare ? 'summary_large_image' : 'summary');
  if (S.imagemShare) {
    meta('property', 'og:image', S.imagemShare);
    meta('name', 'twitter:image', S.imagemShare);
  }

  /* Favicon desenhado a partir das iniciais + cor de destaque */
  (function favicon() {
    const ini = esc(S.iniciais || iniciaisDe(S.nome));
    const svg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64">
      <rect width="64" height="64" rx="15" fill="${esc(T.destaque || '#FF4D2E')}"/>
      <text x="32" y="43" text-anchor="middle" font-family="Inter,Arial,sans-serif"
            font-size="30" font-weight="900" fill="${esc(T.destaqueTexto || '#0B0B0D')}">${ini}</text>
    </svg>`;
    const link = document.createElement('link');
    link.rel = 'icon';
    link.type = 'image/svg+xml';
    link.href = 'data:image/svg+xml,' + encodeURIComponent(svg);
    document.head.appendChild(link);
  })();

  /* ═══ Topo ═════════════════════════════════════════════════════════════ */
  $('logo-mark').textContent = S.iniciais || iniciaisDe(S.nome);
  $('logo-nome').textContent = S.nome || '';

  const itensNav = P.navegacao || [];
  $('nav').innerHTML = itensNav
    .map(i => `<a href="#${esc(i.alvo)}" data-alvo="${esc(i.alvo)}">${esc(i.rotulo)}</a>`).join('');

  const menuMobile = $('menu-mobile');
  menuMobile.innerHTML = itensNav
    .map((i, k) => `<a href="#${esc(i.alvo)}" style="animation-delay:${k * 60 + 60}ms">${esc(i.rotulo)}</a>`).join('');

  const btnMenu = $('btn-menu');
  function fecharMenu() {
    menuMobile.hidden = true;
    btnMenu.setAttribute('aria-expanded', 'false');
    document.body.classList.remove('travado');
  }
  btnMenu.addEventListener('click', () => {
    const aberto = btnMenu.getAttribute('aria-expanded') === 'true';
    if (aberto) return fecharMenu();
    menuMobile.hidden = false;
    btnMenu.setAttribute('aria-expanded', 'true');
    document.body.classList.add('travado');
  });
  menuMobile.addEventListener('click', e => { if (e.target.tagName === 'A') fecharMenu(); });

  const topo = $('topo');
  addEventListener('scroll', () => topo.classList.toggle('colado', scrollY > 20), { passive: true });

  /* ═══ Abertura ═════════════════════════════════════════════════════════ */
  const H = P.hero || {};
  $('hero-titulo').innerHTML = (H.titulo || [S.nome])
    .map((linha, k) => `<span class="linha"><span style="animation-delay:${k * 110 + 120}ms">${enfase(linha)}</span></span>`)
    .join('');
  $('hero-sub').textContent = H.subtitulo || '';

  $('hero-botoes').innerHTML = (H.botoes || [])
    .map(b => `<a class="btn ${b.destaque ? 'btn-destaque' : 'btn-vazado'}" href="${esc(b.link || '#')}">${esc(b.rotulo)}</a>`)
    .join('');

  $('hero-papel').textContent = S.papel || '';
  $('hero-local').textContent = S.local || '';

  if (S.disponivel) {
    $('selo-texto').textContent = S.textoDisponivel || 'Disponível para projetos';
    $('selo-disponivel').hidden = false;
  }

  /* ═══ Mídia (YouTube / Vimeo / arquivo) ════════════════════════════════ */
  function midiaHTML(url, autoplay) {
    if (!url) return '';
    const auto = autoplay ? 1 : 0;

    const yt = url.match(/(?:youtube\.com\/(?:watch\?v=|embed\/|shorts\/|live\/)|youtu\.be\/)([\w-]{11})/);
    if (yt) return `<iframe src="https://www.youtube.com/embed/${yt[1]}?rel=0&playsinline=1&autoplay=${auto}"
      title="Vídeo" allow="accelerometer; autoplay; clipboard-write; encrypted-media; picture-in-picture"
      allowfullscreen loading="lazy"></iframe>`;

    const vm = url.match(/vimeo\.com\/(?:video\/)?(\d+)/);
    if (vm) return `<iframe src="https://player.vimeo.com/video/${vm[1]}?autoplay=${auto}&playsinline=1"
      title="Vídeo" allow="autoplay; fullscreen; picture-in-picture" allowfullscreen loading="lazy"></iframe>`;

    if (/\.(mp4|webm|ogv|mov)(\?.*)?$/i.test(url))
      return `<video src="${esc(url)}" controls playsinline preload="metadata" ${autoplay ? 'autoplay muted' : ''}></video>`;

    return `<iframe src="${esc(url)}" title="Vídeo" allowfullscreen loading="lazy"></iframe>`;
  }

  /* Capa: imagem se houver, senão um cartão com as iniciais */
  function capaHTML(imagem, titulo, classe) {
    if (imagem) return `<div class="${classe}" style="background-image:url('${esc(imagem)}')"></div>`;
    return `<div class="${classe} auto"><span>${esc(iniciaisDe(titulo))}</span></div>`;
  }

  /* ═══ Reel ═════════════════════════════════════════════════════════════ */
  const R = P.reel || {};
  if (R.ativo && R.video) {
    $('reel-etiqueta').textContent = R.etiqueta || '';
    $('reel-titulo').textContent   = R.titulo || '';
    const moldura = $('reel-moldura');

    if (R.capa) {
      const capa = el('button', 'play-capa', '<span class="play-btn" aria-hidden="true">▶</span>');
      capa.style.backgroundImage = `url('${R.capa}')`;
      capa.setAttribute('aria-label', 'Reproduzir o reel');
      capa.addEventListener('click', () => { moldura.innerHTML = midiaHTML(R.video, true); });
      moldura.appendChild(capa);
    } else {
      moldura.innerHTML = midiaHTML(R.video, false);
    }
    $('reel').hidden = false;
  }

  /* ═══ Trabalhos ════════════════════════════════════════════════════════ */
  const W = P.trabalhos || {};
  const projetos = W.itens || [];

  $('trab-etiqueta').textContent = W.etiqueta || '';
  $('trab-titulo').textContent   = W.titulo || 'Trabalhos';
  $('trab-sub').textContent      = W.subtitulo || '';

  const grade = $('grade');

  function desenharGrade(categoria) {
    const lista = categoria
      ? projetos.filter(p => (p.categorias || []).includes(categoria))
      : projetos;

    if (!lista.length) {
      grade.innerHTML = '<p class="vazio">Nenhum projeto nesta categoria ainda.</p>';
      return;
    }

    grade.innerHTML = lista.map(p => {
      const i = projetos.indexOf(p);
      const tags = (p.categorias || [])
        .map(c => `<span class="tag">${esc(c)}</span>`).join('');
      return `
        <button class="card rev ${p.destaque ? 'largo' : ''}" data-i="${i}" aria-label="Abrir ${esc(p.titulo)}">
          <div class="card-capa-wrap">
            ${capaHTML(p.capa, p.titulo, 'card-capa')}
            <span class="lupa"><span aria-hidden="true">${p.video ? '▶' : '↗'}</span></span>
          </div>
          <div class="card-info">
            <div class="card-topo">
              <span class="card-titulo">${esc(p.titulo)}</span>
              <span class="card-ano">${esc(p.ano || '')}</span>
            </div>
            ${p.cliente ? `<div class="card-cliente">${esc(p.cliente)}</div>` : ''}
            ${tags ? `<div class="card-tags">${tags}</div>` : ''}
          </div>
        </button>`;
    }).join('');

    grade.querySelectorAll('.rev').forEach(n => observador.observe(n));
  }

  /* Filtros, derivados das categorias dos projetos */
  const categorias = [...new Set(projetos.flatMap(p => p.categorias || []))];
  if (categorias.length > 1) {
    const filtros = $('filtros');
    const todos = [{ rotulo: W.textoFiltroTudo || 'Tudo', valor: '' }]
      .concat(categorias.map(c => ({ rotulo: c, valor: c })));

    filtros.innerHTML = todos
      .map((f, k) => `<button class="filtro ${k === 0 ? 'ativo' : ''}" data-cat="${esc(f.valor)}">${esc(f.rotulo)}</button>`)
      .join('');

    filtros.addEventListener('click', e => {
      const b = e.target.closest('.filtro');
      if (!b) return;
      filtros.querySelectorAll('.filtro').forEach(x => x.classList.toggle('ativo', x === b));
      desenharGrade(b.dataset.cat);
    });
  }

  /* ═══ Clientes ═════════════════════════════════════════════════════════ */
  const C = P.clientes || {};
  if (C.ativo && (C.lista || []).length) {
    $('clientes-titulo').textContent = C.titulo || '';
    const trilha = C.lista.map(n => `<span class="marquee-item">${esc(n)}</span>`).join('');
    // duas trilhas idênticas = laço contínuo
    $('marquee').innerHTML =
      `<div class="marquee-trilha" aria-hidden="false">${trilha}</div>` +
      `<div class="marquee-trilha" aria-hidden="true">${trilha}</div>`;
    $('clientes').hidden = false;
  }

  /* ═══ Sobre ════════════════════════════════════════════════════════════ */
  const A = P.sobre || {};
  $('sobre-etiqueta').textContent = A.etiqueta || '';
  $('sobre-titulo').textContent   = A.titulo || '';

  const foto = $('sobre-foto');
  if (A.foto) {
    foto.style.backgroundImage = `url('${A.foto}')`;
  } else {
    foto.classList.add('auto');
    foto.innerHTML = `<span>${esc(S.iniciais || iniciaisDe(S.nome))}</span>`;
  }

  $('sobre-paragrafos').innerHTML = (A.paragrafos || [])
    .map(p => `<p>${esc(p)}</p>`).join('');

  $('sobre-numeros').innerHTML = (A.numeros || [])
    .map(n => `<div><div class="numero-valor">${esc(n.valor)}</div><div class="numero-rotulo">${esc(n.rotulo)}</div></div>`)
    .join('');

  $('habilidades').innerHTML = (A.habilidades || []).map(h => `
    <div class="hab-bloco rev">
      <div class="hab-grupo">${esc(h.grupo)}</div>
      <ul class="hab-lista">${(h.itens || []).map(i => `<li>${esc(i)}</li>`).join('')}</ul>
    </div>`).join('');

  $('linha-tempo').innerHTML = (A.experiencia || []).map(e => `
    <li class="rev">
      <div class="tempo-periodo">${esc(e.periodo)}</div>
      <div>
        <div class="tempo-cargo">${esc(e.cargo)}</div>
        ${e.onde ? `<div class="tempo-onde">${esc(e.onde)}</div>` : ''}
        ${e.texto ? `<p class="tempo-texto">${esc(e.texto)}</p>` : ''}
      </div>
    </li>`).join('');

  /* ═══ Contato ══════════════════════════════════════════════════════════ */
  const K = P.contato || {};
  $('contato-etiqueta').textContent = K.etiqueta || '';
  $('contato-titulo').textContent   = K.titulo || '';
  $('contato-texto').textContent    = K.texto || '';

  const email = K.email || S.email || '';
  const btnContato = $('contato-botao');
  btnContato.href = email ? `mailto:${email}` : '#';
  btnContato.textContent = K.textoBotao || email || 'Falar comigo';

  const ICONES = {
    instagram: '<path d="M12 2.2c3.2 0 3.6 0 4.9.07 1.2.05 1.8.25 2.2.42.6.2 1 .47 1.4.9.4.4.7.8.9 1.4.2.4.4 1 .4 2.2.1 1.3.1 1.7.1 4.9s0 3.6-.1 4.9c0 1.2-.2 1.8-.4 2.2-.2.6-.5 1-.9 1.4-.4.4-.8.7-1.4.9-.4.2-1 .4-2.2.4-1.3.1-1.7.1-4.9.1s-3.6 0-4.9-.1c-1.2 0-1.8-.2-2.2-.4-.6-.2-1-.5-1.4-.9-.4-.4-.7-.8-.9-1.4-.2-.4-.4-1-.4-2.2C2.2 15.6 2.2 15.2 2.2 12s0-3.6.1-4.9c0-1.2.2-1.8.4-2.2.2-.6.5-1 .9-1.4.4-.4.8-.7 1.4-.9.4-.2 1-.4 2.2-.4C8.4 2.2 8.8 2.2 12 2.2zm0 3.1A6.7 6.7 0 1 0 18.7 12 6.7 6.7 0 0 0 12 5.3zm0 11a4.3 4.3 0 1 1 4.3-4.3 4.3 4.3 0 0 1-4.3 4.3zm6.9-11.2a1.6 1.6 0 1 1-1.6-1.6 1.6 1.6 0 0 1 1.6 1.6z"/>',
    behance:   '<path d="M9.1 6.5c.8 0 1.5.1 2.1.3.6.2 1.1.4 1.5.8.4.3.7.7.9 1.2.2.5.3 1 .3 1.7 0 .7-.2 1.3-.5 1.8-.3.5-.8.9-1.5 1.2.9.3 1.6.7 2 1.4.4.6.7 1.4.7 2.3 0 .8-.1 1.4-.4 2-.3.5-.7 1-1.2 1.3-.5.3-1.1.6-1.7.7-.6.2-1.3.2-2 .2H2V6.5h7.1zM8.7 12c.6 0 1.1-.2 1.5-.5.4-.3.6-.7.6-1.4 0-.4 0-.7-.2-.9-.1-.2-.3-.4-.5-.6-.2-.1-.5-.2-.8-.3-.3 0-.6-.1-.9-.1H5V12h3.7zm.2 5.9c.3 0 .7 0 1-.1.3-.1.6-.2.8-.3.2-.2.4-.4.5-.6.1-.3.2-.6.2-1 0-.8-.2-1.3-.6-1.7-.5-.3-1.1-.5-1.8-.5H5v4.2h3.9zM17.9 17.7c.4.4 1 .6 1.8.6.5 0 1-.2 1.4-.4.4-.3.7-.6.8-.9h2.1c-.4 1-.9 1.8-1.6 2.3-.7.5-1.6.7-2.6.7-.7 0-1.4-.1-2-.4-.6-.2-1.1-.6-1.5-1-.4-.4-.7-1-.9-1.6-.2-.6-.3-1.3-.3-2s.1-1.4.4-2c.2-.6.5-1.1 1-1.6.4-.4.9-.8 1.5-1 .6-.3 1.2-.4 1.9-.4.8 0 1.5.2 2.1.5.6.3 1.1.7 1.4 1.2.4.5.7 1.1.8 1.8.2.7.2 1.4.2 2.1h-6.9c0 .8.3 1.6.7 2.1zm3.1-5.6c-.3-.4-.9-.6-1.6-.6-.5 0-.8.1-1.1.2-.3.2-.5.4-.7.6-.2.2-.3.5-.4.7 0 .3-.1.5-.1.7h4.3c-.1-.7-.2-1.2-.4-1.6zM15.5 7.6h5.4v1.3h-5.4z"/>',
    vimeo:     '<path d="M22 7.4c-.1 2.1-1.6 5-4.4 8.7-2.9 3.9-5.4 5.8-7.4 5.8-1.3 0-2.3-1.2-3.2-3.5l-1.7-6.4c-.6-2.3-1.3-3.5-2-3.5-.2 0-.7.3-1.6.9L.7 8.2c1-.9 2-1.8 3-2.7C5.1 4.3 6.1 3.7 6.8 3.6c1.7-.2 2.8 1 3.2 3.6.4 2.8.7 4.5.9 5.2.5 2.2 1 3.3 1.6 3.3.5 0 1.2-.7 2.1-2.2.9-1.5 1.4-2.6 1.5-3.4.1-.8-.2-1.2-.9-1.2-.4 0-.7.1-1.1.2.8-2.5 2.2-3.7 4.4-3.6 1.6.05 2.4 1.1 2.3 3.1z"/>',
    linkedin:  '<path d="M4.98 3.5a2.5 2.5 0 1 1 0 5 2.5 2.5 0 0 1 0-5zM3 9h4v12H3zM9.5 9h3.8v1.7h.05c.53-1 1.8-2.05 3.7-2.05 4 0 4.7 2.6 4.7 6V21h-4v-5.5c0-1.3 0-3-1.9-3s-2.2 1.4-2.2 2.9V21h-4z"/>',
    youtube:   '<path d="M23 12s0-3.6-.5-5.3a2.8 2.8 0 0 0-2-2C18.8 4.2 12 4.2 12 4.2s-6.8 0-8.5.5a2.8 2.8 0 0 0-2 2C1 8.4 1 12 1 12s0 3.6.5 5.3a2.8 2.8 0 0 0 2 2c1.7.5 8.5.5 8.5.5s6.8 0 8.5-.5a2.8 2.8 0 0 0 2-2c.5-1.7.5-5.3.5-5.3zM9.8 15.5v-7l5.9 3.5z"/>',
    dribbble:  '<path d="M12 2a10 10 0 1 0 0 20 10 10 0 0 0 0-20zm6.6 4.6a8.3 8.3 0 0 1 1.9 5.2c-.3-.06-3.1-.6-5.9-.3-.06-.14-.13-.3-.2-.45-.2-.4-.4-.8-.6-1.2 3.1-1.3 4.5-3.1 4.8-3.25zM12 3.5c1.9 0 3.6.7 4.9 1.9-.2.3-1.5 2-4.4 3.1a44 44 0 0 0-3.2-4.8c.9-.2 1.8-.2 2.7-.2zM7.6 4.4a52 52 0 0 1 3.2 4.8c-4 1-7.5 1-7.9 1a8.6 8.6 0 0 1 4.7-5.8zM2.7 12v-.3c.4 0 4.5.06 8.8-1.2.25.5.5 1 .7 1.4l-.35.1c-4.4 1.4-6.8 5.3-7 5.6A8.3 8.3 0 0 1 2.7 12zm9.3 8.5c-1.9 0-3.7-.65-5.1-1.75.16-.3 1.9-3.7 6.7-5.4 2 5.2 2.85 9.6 3.1 10.85-1.4.6-2.9.3-4.7.3zm6.2-1.1c-.15-1-.9-5.2-2.8-10.3 2.65-.4 5 .3 5.3.4a8.4 8.4 0 0 1-2.5 9.9z"/>',
    site:      '<path d="M12 2a10 10 0 1 0 0 20 10 10 0 0 0 0-20zm6.9 6h-2.9a15.6 15.6 0 0 0-1.4-3.7A8 8 0 0 1 18.9 8zM12 4c.8 1.2 1.4 2.5 1.8 4h-3.6c.4-1.5 1-2.8 1.8-4zM4.3 14a8 8 0 0 1 0-4h3.3a17 17 0 0 0 0 4zm.8 2h2.9c.3 1.3.8 2.6 1.4 3.7A8 8 0 0 1 5.1 16zm2.9-8H5.1a8 8 0 0 1 4.3-3.7A15.6 15.6 0 0 0 8 8zM12 20c-.8-1.2-1.4-2.5-1.8-4h3.6c-.4 1.5-1 2.8-1.8 4zm2.2-6H9.8a15 15 0 0 1 0-4h4.4a15 15 0 0 1 0 4zm.4 5.7c.6-1.1 1.1-2.4 1.4-3.7h2.9a8 8 0 0 1-4.3 3.7zM16.4 14a17 17 0 0 0 0-4h3.3a8 8 0 0 1 0 4z"/>',
  };

  $('redes').innerHTML = (K.redes || []).map(r => {
    const svg = ICONES[r.icone] || ICONES.site;
    return `<a class="rede" href="${esc(r.url)}" target="_blank" rel="noopener">
      <svg viewBox="0 0 24 24" aria-hidden="true">${svg}</svg>${esc(r.rotulo)}</a>`;
  }).join('');

  /* ═══ Rodapé ═══════════════════════════════════════════════════════════ */
  $('rodape-esq').textContent = `© ${new Date().getFullYear()} ${S.nome || ''}`.trim();
  $('rodape-dir').textContent = (P.rodape && P.rodape.texto) || '';

  /* ═══ Janela de projeto ════════════════════════════════════════════════ */
  const modal = $('modal');
  let ultimoFoco = null;

  function abrirProjeto(i) {
    const p = projetos[i];
    if (!p) return;
    ultimoFoco = document.activeElement;

    $('modal-midia').innerHTML = p.video
      ? midiaHTML(p.video, true)
      : capaHTML(p.capa, p.titulo, 'card-capa');

    $('modal-meta').textContent  = [p.cliente, p.ano].filter(Boolean).join(' · ');
    $('modal-titulo').textContent = p.titulo || '';
    $('modal-desc').textContent   = p.descricao || '';
    $('modal-creditos').innerHTML = (p.creditos || []).map(c => `<li>${esc(c)}</li>`).join('');

    const link = $('modal-link');
    link.hidden = !p.link;
    if (p.link) link.href = p.link;

    modal.hidden = false;
    document.body.classList.add('travado');
    $('modal-x').focus();
  }

  function fecharProjeto() {
    modal.hidden = true;
    $('modal-midia').innerHTML = '';   // para o vídeo
    document.body.classList.remove('travado');
    if (ultimoFoco) ultimoFoco.focus();
  }

  grade.addEventListener('click', e => {
    const card = e.target.closest('.card');
    if (card) abrirProjeto(Number(card.dataset.i));
  });
  $('modal-x').addEventListener('click', fecharProjeto);
  $('modal-fundo').addEventListener('click', fecharProjeto);
  addEventListener('keydown', e => {
    if (e.key !== 'Escape') return;
    if (!modal.hidden) fecharProjeto();
    else if (!menuMobile.hidden) fecharMenu();
  });

  /* ═══ Revelação ao rolar ═══════════════════════════════════════════════ */
  const observador = new IntersectionObserver((entradas) => {
    entradas.forEach(en => {
      if (!en.isIntersecting) return;
      en.target.style.transitionDelay = (en.target.dataset.atraso || '0') + 'ms';
      en.target.classList.add('dentro');
      observador.unobserve(en.target);
    });
  }, { rootMargin: '0px 0px -8% 0px', threshold: .08 });

  desenharGrade('');   // primeira pintura da grade (usa o observador acima)

  document.querySelectorAll('.secao-cabeca, .reel-moldura, .sobre-grade, .numeros, .contato-titulo')
    .forEach(n => { n.classList.add('rev'); observador.observe(n); });
  document.querySelectorAll('.rev').forEach((n, k) => {
    if (!n.dataset.atraso) n.dataset.atraso = String((k % 4) * 70);
    observador.observe(n);
  });

  /* ═══ Menu: marcar a seção atual ═══════════════════════════════════════ */
  const links = [...document.querySelectorAll('.nav a')];
  const alvos = links.map(a => $(a.dataset.alvo)).filter(Boolean);
  if (alvos.length) {
    const espia = new IntersectionObserver(entradas => {
      entradas.forEach(en => {
        if (!en.isIntersecting) return;
        links.forEach(a => a.classList.toggle('ativo', a.dataset.alvo === en.target.id));
      });
    }, { rootMargin: '-45% 0px -50% 0px' });
    alvos.forEach(s => espia.observe(s));
  }
})();
