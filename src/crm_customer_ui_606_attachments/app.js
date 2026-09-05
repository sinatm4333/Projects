/* CRM Customer 360 (bot 606) — app.js
   SPA رابط کاربری ماژول مشتری. داده از خود بات (POST action=...) و عملیات بدون API از مسیرهای هم‌مبدأ ماژول بومی.
   قواعد: ریشهٔ اختصاصی (بدون getElementById سراسری)، رویدادهای delegate شده، بدون وابستگی خارجی. */
(function () {
  'use strict';

  var roots = document.querySelectorAll('[data-crm606-root]');
  var root = roots[roots.length - 1];
  if (!root || root.__crm606) { return; }
  root.__crm606 = true;

  var CFG = {
    runUrl: root.getAttribute('data-run-url'),
    baseUrl: root.getAttribute('data-base-url'),
    userId: root.getAttribute('data-user-id') || '0',
    version: root.getAttribute('data-version') || '',
    pageSize: parseInt(root.getAttribute('data-page-size') || '30', 10),
    logo: root.getAttribute('data-logo') || '',
    siteBot: root.getAttribute('data-site-bot') || '/bot/run/443/crm_saite_show',
    siteMarker: root.getAttribute('data-site-marker') || 'شناسه سایت',
    siteLogin: root.getAttribute('data-site-login') || '/bot/run/2/show_site'
  };
  // بات ۴۸۶ «نمایش مشتری در سایت»: فقط برای مشتریانی معنا دارد که در توضیحاتشان «شناسه سایت:NNN» ثبت شده
  function hasSiteId(comment) { return String(comment || '').indexOf(CFG.siteMarker) >= 0; }
  function siteBotUrl(id) { return CFG.baseUrl + CFG.siteBot + '?client_id=' + encodeURIComponent(id); }

  // لاگین سایت (بات ۳۹۸): باید در همین مرورگر بارگذاری شود تا کوکی سایت ست شود. یک‌بار در پس‌زمینه هنگام باز شدن
  // ماژول و پیش از «نمایش در سایت» اگر منقضی شده باشد. نشست سایت mobile140 دو روز معتبر است (گفتهٔ کاربر ۱۴۰۵/۰۶/۱۳)،
  // پس زمان آخرین لاگین در localStorage (نه sessionStorage) نگه داشته می‌شود تا با بستن تب هم دوباره اجرا نشود.
  var SITE_LOGIN_TTL_MS = 2 * 24 * 60 * 60 * 1000;
  var siteLoginPromise = null;
  function siteLoginFresh() { try { var t = parseInt(localStorage.getItem('crm606:site_login_at') || '0', 10); return t && (Date.now() - t) < SITE_LOGIN_TTL_MS; } catch (e) { return false; } }
  function ensureSiteLogin(force) {
    if (!force && siteLoginFresh()) { return Promise.resolve(true); }
    if (siteLoginPromise && !force) { return siteLoginPromise; }
    siteLoginPromise = new Promise(function (resolve) {
      var old = q('#crm606-site-login');
      if (old) { old.remove(); }
      var fr = el('iframe', { id: 'crm606-site-login', title: 'site-login', 'aria-hidden': 'true', style: 'position:absolute;width:0;height:0;border:0;opacity:0;pointer-events:none;' });
      var done = false;
      function finish() {
        if (done) { return; }
        done = true;
        try { localStorage.setItem('crm606:site_login_at', String(Date.now())); } catch (e) { }
        siteLoginPromise = null;
        resolve(true);
      }
      // بات ۳۹۸ خودش یک iframe به سایت دارد؛ بعد از load قاب بیرونی، به قاب داخلی (cross-origin) چند ثانیه فرصت می‌دهیم
      fr.addEventListener('load', function () { setTimeout(finish, 3500); });
      fr.addEventListener('error', function () { setTimeout(finish, 500); });
      setTimeout(finish, 12000);
      root.appendChild(fr);
      fr.src = CFG.baseUrl + CFG.siteLogin;
    });
    return siteLoginPromise;
  }
  function openSiteModal(id, name) {
    var url = siteBotUrl(id);
    var body = openModal('نمایش در سایت — ' + (name || ('مشتری ' + id)), '<div class="site-frame-wrap"><div class="loading" data-role="site-status">ورود به سایت (بات ۳۹۸)…</div><iframe class="site-frame" title="سایت" allowfullscreen></iframe></div>', [
      { label: 'باز کردن در تب جدید ↗', cls: 'secondary', onClick: function () { window.open(url, '_blank', 'noopener'); } },
      { label: 'ورود مجدد به سایت', cls: 'secondary', onClick: function (btn) { btn.disabled = true; var st = q('[data-role="site-status"]', body) || el('div', { 'class': 'loading', 'data-role': 'site-status' }); if (!st.parentNode) { q('.site-frame-wrap', body).insertBefore(st, q('.site-frame', body)); } st.textContent = 'ورود مجدد به سایت…'; ensureSiteLogin(true).then(function () { st.textContent = 'بارگذاری صفحهٔ سایت…'; fr.src = url + '&r=' + Date.now(); btn.disabled = false; }); } },
      { label: 'بستن', cls: 'secondary' }
    ], { wide: true });
    var fr = q('.site-frame', body);
    fr.addEventListener('load', function () { var l = q('[data-role="site-status"]', body); if (l && fr.src) { l.remove(); } });
    ensureSiteLogin(false).then(function () {
      var st = q('[data-role="site-status"]', body);
      if (st) { st.textContent = 'بارگذاری صفحهٔ سایت…'; }
      fr.src = url;
    });
  }

  /* ============================== helpers ============================== */
  function esc(v) {
    if (v === null || v === undefined) { return ''; }
    return String(v).replace(/[&<>"']/g, function (c) {
      return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c];
    });
  }
  function asArray(v) { return Array.isArray(v) ? v : []; }
  // json.encode لوآ آرایهٔ خالی را {} می‌فرستد — همهٔ فیلدهای فهرستی پروفایل نرمال می‌شوند
  var CLIENT_LIST_FIELDS = ['mobiles', 'emails', 'phones', 'national_codes', 'profile_addresses', 'crm_addresses', 'categories', 'notify_users', 'favorite_users', 'contacts', 'custom_fields', 'custom_forms', 'cards', 'bank_accounts', 'accounting', 'family', 'assigned', 'responsible'];
  function normalizeClient(c) { CLIENT_LIST_FIELDS.forEach(function (k) { c[k] = asArray(c[k]); }); return c; }
  function fmtNum(v) {
    var n = Number(v);
    if (isNaN(n)) { return '0'; }
    return Math.round(n).toLocaleString('en-US');
  }
  function q(sel, ctx) { return (ctx || root).querySelector(sel); }
  function qa(sel, ctx) { return Array.prototype.slice.call((ctx || root).querySelectorAll(sel)); }
  function el(tag, attrs, html) {
    var e = document.createElement(tag);
    if (attrs) { Object.keys(attrs).forEach(function (k) { if (attrs[k] !== null && attrs[k] !== undefined) { e.setAttribute(k, attrs[k]); } }); }
    if (html !== undefined) { e.innerHTML = html; }
    return e;
  }
  function store(key, val) {
    try {
      if (val === undefined) { var raw = localStorage.getItem('crm606:' + key); return raw ? JSON.parse(raw) : null; }
      localStorage.setItem('crm606:' + key, JSON.stringify(val));
    } catch (e) { return null; }
    return val;
  }
  function dash(v) { return (v === null || v === undefined || v === '') ? '—' : v; }
  function initials(name) {
    var parts = String(name || '').trim().split(/\s+/).filter(Boolean);
    if (!parts.length) { return '؟'; }
    return parts.slice(0, 2).map(function (p) { return p.charAt(0); }).join('');
  }
  function debounce(fn, ms) { var t; return function () { var a = arguments, s = this; clearTimeout(t); t = setTimeout(function () { fn.apply(s, a); }, ms); }; }

  /* ============================== نمای جدول (جدولی/کارتی/خودکار) + حالت روز/شب ============================== */
  var VIEW_MODES = { auto: 'خودکار', table: 'جدولی', cards: 'کارتی' };
  function viewMode() { var v = store('view_mode'); return VIEW_MODES[v] ? v : 'auto'; }
  function cardsActive() { var m = viewMode(); return m === 'cards' || (m === 'auto' && window.innerWidth < 700); }
  function applyViewMode() {
    var on = cardsActive();
    qa('.table-wrap.cardable').forEach(function (w) { w.classList.toggle('cards-on', on); });
    qa('[data-role="view-mode-label"]').forEach(function (s) { s.textContent = VIEW_MODES[viewMode()]; });
    qa('[data-role="tf-view"]').forEach(function (b) { b.textContent = on ? '☷ جدولی' : '▦ کارتی'; b.title = on ? 'نمایش به‌صورت جدول' : 'نمایش به‌صورت کارت'; });
  }
  function setViewMode(mode) { store('view_mode', mode); applyViewMode(); toast('نمای جدول‌ها: ' + VIEW_MODES[mode]); }
  function cycleViewMode() { var order = ['auto', 'table', 'cards']; setViewMode(order[(order.indexOf(viewMode()) + 1) % order.length]); }
  window.addEventListener('resize', debounce(applyViewMode, 150));

  function themeName() {
    var t = store('theme');
    if (t === 'dark' || t === 'light') { return t; }
    try { return (window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches) ? 'dark' : 'light'; } catch (e) { return 'light'; }
  }
  function applyTheme() {
    var dark = themeName() === 'dark';
    root.classList.toggle('theme-dark', dark);
    try { document.body.style.background = dark ? '#111' : ''; } catch (e) { }
    qa('[data-act="theme"]').forEach(function (b) { b.textContent = dark ? '☀ حالت روز' : '🌙 حالت شب'; });
  }
  function toggleTheme() { store('theme', themeName() === 'dark' ? 'light' : 'dark'); applyTheme(); }

  /* ============================== toasts ============================== */
  var toastBox = el('div', { 'class': 'toasts' });
  document.body.appendChild(toastBox);
  function toast(msg, isErr) {
    var t = el('div', { 'class': 'toast' + (isErr ? ' err' : '') }, esc(msg));
    toastBox.appendChild(t);
    setTimeout(function () { t.style.opacity = '0'; t.style.transition = 'opacity .4s'; }, isErr ? 6000 : 3200);
    setTimeout(function () { if (t.parentNode) { t.parentNode.removeChild(t); } }, isErr ? 6500 : 3700);
  }

  /* ============================== API ============================== */
  function api(action, fields) {
    var fd = new FormData();
    fd.append('action', action);
    Object.keys(fields || {}).forEach(function (k) {
      var v = fields[k];
      if (v === undefined || v === null) { return; }
      fd.append(k, typeof v === 'object' ? JSON.stringify(v) : String(v));
    });
    return fetch(CFG.runUrl + '?cu_action=' + encodeURIComponent(action), { method: 'POST', body: fd, credentials: 'same-origin' })
      .then(function (res) {
        return res.text().then(function (txt) {
          var data;
          try { data = JSON.parse(txt); } catch (e) {
            throw new Error('پاسخ سرور JSON نبود (HTTP ' + res.status + ')' + (res.status === 400 ? ' — فیلد نامعتبر' : res.status === 403 ? ' — دسترسی/نشست' : ''));
          }
          if (!res.ok && !data) { throw new Error('HTTP ' + res.status); }
          if (!data.ok) { throw new Error(data.error || 'خطای ناشناخته'); }
          return data;
        });
      });
  }

  // مسیرهای هم‌مبدأ ماژول بومی (همان چیزی که دکمه‌های ماژول اصلی صدا می‌زنند) — سطح دسترسی همان کاربر جاری
  function nativeCall(path, params, method) {
    var url = CFG.baseUrl + path;
    var opts = { method: method || 'GET', credentials: 'same-origin', headers: { 'X-Requested-With': 'XMLHttpRequest' } };
    var qs = Object.keys(params || {}).map(function (k) { return encodeURIComponent(k) + '=' + encodeURIComponent(params[k]); }).join('&');
    if (opts.method === 'GET') { url += (url.indexOf('?') >= 0 ? '&' : '?') + qs; }
    else { opts.body = qs; opts.headers['Content-Type'] = 'application/x-www-form-urlencoded; charset=UTF-8'; }
    return fetch(url, opts).then(function (res) {
      return res.text().then(function (txt) {
        var t = (txt || '').trim();
        if (!res.ok) { throw new Error('HTTP ' + res.status + ' از ماژول بومی'); }
        if (/ACCESS_DENIED|JS_ERR_ACCESS_DENIED/.test(t)) { throw new Error('برای این عملیات دسترسی ندارید'); }
        if (/ERROR_EXIST_ACCOUNT/.test(t)) { throw new Error('برای مشتری در حسابداری حساب وجود دارد'); }
        if (/ERROR_EXIST_DOCUMENT/.test(t)) { throw new Error('مشتری در ماژول اسناد دارای سند است'); }
        if (/<html|<!DOCTYPE/i.test(t) && t.length > 2000) { throw new Error('ماژول بومی صفحهٔ HTML برگرداند (احتمالاً نشست منقضی شده)'); }
        if (/^ERROR/i.test(t)) { throw new Error(t.slice(0, 120)); }
        return t;
      });
    });
  }

  /* ============================== modal ============================== */
  var overlay = el('div', { 'class': 'modal-overlay' });
  overlay.innerHTML = '<div class="modal"><div class="modal-head"><span class="m-title"></span><button type="button" data-close="1">✕</button></div><div class="modal-body"></div><div class="modal-foot"></div></div>';
  root.appendChild(overlay);
  overlay.addEventListener('click', function (e) { if (e.target === overlay || e.target.getAttribute('data-close')) { closeModal(); } });
  document.addEventListener('keydown', function (e) { if (e.key === 'Escape' && overlay.classList.contains('open')) { closeModal(); } });
  var modalOnClose = null;
  function openModal(title, bodyHtml, buttons, opts) {
    opts = opts || {};
    q('.modal', overlay).classList.toggle('wide', !!opts.wide);
    q('.m-title', overlay).textContent = title;
    q('.modal-body', overlay).innerHTML = bodyHtml;
    var foot = q('.modal-foot', overlay);
    foot.innerHTML = '';
    (buttons || []).forEach(function (b) {
      var btn = el('button', { type: 'button', 'class': 'btn' + (b.cls ? ' ' + b.cls : '') }, esc(b.label));
      btn.addEventListener('click', function () { if (b.onClick) { b.onClick(btn); } else { closeModal(); } });
      foot.appendChild(btn);
    });
    if (!buttons || !buttons.length) { foot.appendChild(el('button', { type: 'button', 'class': 'btn secondary', 'data-close': '1' }, 'بستن')); }
    modalOnClose = opts.onClose || null;
    overlay.classList.add('open');
    return q('.modal-body', overlay);
  }
  function closeModal() { overlay.classList.remove('open'); if (modalOnClose) { var f = modalOnClose; modalOnClose = null; f(); } }
  function confirmModal(title, message, okLabel, onOk, danger) {
    openModal(title, '<p>' + message + '</p>', [
      { label: okLabel || 'تأیید', cls: danger ? 'gray' : '', onClick: function (btn) { btn.disabled = true; btn.textContent = 'در حال انجام…'; Promise.resolve(onOk()).then(closeModal).catch(function (e) { btn.disabled = false; btn.textContent = okLabel || 'تأیید'; toast(e.message, true); }); } },
      { label: 'لغو', cls: 'secondary' }
    ]);
  }

  /* ============================== router ============================== */
  var state = {
    view: 'list',
    list: { scope: 'all', section_id: '', category_id: '', q: '', page: 1, per_page: store('per_page') || CFG.pageSize, sort: 'id', dir: 'desc', adv: [] },
    client: { id: null, tab: 'overview', data: null, counts: null, tabs: {} },
    tree: null,
    selected: {},
    listRows: [],
    total: 0
  };

  function parseHash(h) {
    h = (h || location.hash || '#/list').replace(/^#/, '');
    var path = h.split('?')[0];
    var qs = h.split('?')[1] || '';
    var params = {};
    qs.split('&').forEach(function (p) { if (!p) { return; } var kv = p.split('='); params[decodeURIComponent(kv[0])] = decodeURIComponent((kv[1] || '').replace(/\+/g, ' ')); });
    var seg = path.split('/').filter(Boolean);
    return { seg: seg, params: params };
  }
  function listHash(over) {
    var s = Object.assign({}, state.list, over || {});
    var parts = [];
    ['scope', 'section_id', 'category_id', 'q', 'page', 'sort', 'dir'].forEach(function (k) { if (s[k] !== '' && s[k] !== null && s[k] !== undefined && !(k === 'page' && s[k] === 1) && !(k === 'scope' && s[k] === 'all') && !(k === 'sort' && s[k] === 'id') && !(k === 'dir' && s[k] === 'desc')) { parts.push(k + '=' + encodeURIComponent(s[k])); } });
    if (s.adv && s.adv.length) { parts.push('adv=' + encodeURIComponent(JSON.stringify(s.adv))); }
    return '#/list' + (parts.length ? '?' + parts.join('&') : '');
  }
  // ناوبری مستقل از hash: داخل شل پرتال، تغییر hash یا کلیک روی لینک ممکن است توسط پرتال بلعیده شود؛
  // پس مسیر همیشه مستقیم رندر می‌شود و hash فقط «در صورت امکان» همگام نگه داشته می‌شود.
  var lastRouted = null;
  function go(hash) {
    try { if (location.hash !== hash) { lastRouted = hash; location.hash = hash; } } catch (e) { }
    route(hash);
  }
  window.addEventListener('hashchange', function () { if (location.hash !== lastRouted) { route(location.hash); } });
  root.addEventListener('click', function (e) {
    var a = e.target.closest('a[href^="#/"]');
    if (a && root.contains(a)) { e.preventDefault(); e.stopPropagation(); go(a.getAttribute('href')); return; }
    // کلیک روی هر جای ردیف مشتری (به‌جز کنترل‌ها) = باز کردن پروفایل
    var tr = e.target.closest('tr[data-id]');
    if (tr && root.contains(tr) && !e.target.closest('a, button, input, select, label')) { go('#/client/' + tr.getAttribute('data-id')); }
  }, true);

  function route(hash) {
    var r = parseHash(hash);
    lastRouted = hash || location.hash;
    var first = r.seg[0] || 'list';
    if (first === 'client' && r.seg[1]) {
      state.view = 'client';
      var id = r.seg[1];
      var tab = r.seg[2] || 'overview';
      if (state.client.id !== id) { state.client = { id: id, tab: tab, data: null, counts: null, tabs: {} }; }
      state.client.tab = tab;
      renderClient();
      return;
    }
    if (first === 'new') { state.view = 'form'; renderClientForm(null); return; }
    if (first === 'edit' && r.seg[1]) { state.view = 'form'; renderClientForm(r.seg[1]); return; }
    state.view = 'list';
    var p = r.params;
    state.list.scope = p.scope || 'all';
    state.list.section_id = p.section_id || '';
    state.list.category_id = p.category_id || '';
    state.list.q = p.q || '';
    state.list.page = parseInt(p.page || '1', 10) || 1;
    state.list.sort = p.sort || 'id';
    state.list.dir = p.dir || 'desc';
    try { state.list.adv = p.adv ? JSON.parse(p.adv) : []; } catch (e) { state.list.adv = []; }
    renderList();
  }

  /* ============================== shell ============================== */
  var mainEl, sideEl, crumbEl, layoutEl;
  function renderShell() {
    root.innerHTML = '';
    var header = el('div', { 'class': 'crm606-header' });
    header.innerHTML =
      '<div class="brand">' + (CFG.logo ? '<img src="' + esc(CFG.logo) + '" alt="140">' : '') +
      '<div><h1>ماژول مشتریان (CRM)</h1><div class="crumb"></div></div></div>' +
      '<div class="crm606-toolbar">' +
      '<button type="button" class="btn ghost" data-act="toggle-side" title="نمایش/پنهان کردن پنل رده‌ها">☰ رده‌ها</button>' +
      '<button type="button" class="btn ghost" data-act="new-client">＋ مشتری جدید</button>' +
      '<button type="button" class="btn ghost" data-act="export">خروجی Excel</button>' +
      '<button type="button" class="btn ghost" data-act="view-mode" title="نمای جدول‌ها: خودکار / جدولی / کارتی">نما: <span data-role="view-mode-label"></span></button>' +
      '<button type="button" class="btn ghost" data-act="theme"></button>' +
      '<button type="button" class="btn ghost" data-act="fullscreen">تمام صفحه</button>' +
      '<button type="button" class="btn ghost" data-act="help">راهنما</button>' +
      '</div>';
    root.appendChild(header);
    crumbEl = q('.crumb', header);
    layoutEl = el('div', { 'class': 'crm606-layout' + (store('side') === 'closed' ? ' side-collapsed' : '') });
    sideEl = el('div', { 'class': 'crm606-side' });
    mainEl = el('div', { 'class': 'crm606-main' });
    layoutEl.appendChild(sideEl);
    layoutEl.appendChild(mainEl);
    root.appendChild(layoutEl);
    root.appendChild(el('div', { 'class': 'footer' }, 'CRM مشتریان — نسخهٔ ' + esc(CFG.version) + ' — همهٔ عملیات با سطح دسترسی کاربر جاری در تیم‌یار انجام می‌شود.'));
    root.appendChild(overlay);
    header.addEventListener('click', function (e) {
      var b = e.target.closest('[data-act]');
      if (!b) { return; }
      var act = b.getAttribute('data-act');
      if (act === 'toggle-side') { layoutEl.classList.toggle('side-collapsed'); store('side', layoutEl.classList.contains('side-collapsed') ? 'closed' : 'open'); }
      if (act === 'new-client') { go('#/new'); }
      if (act === 'export') { exportExcel(); }
      if (act === 'fullscreen') { root.classList.toggle('is-fullscreen'); b.textContent = root.classList.contains('is-fullscreen') ? 'خروج از تمام صفحه' : 'تمام صفحه'; }
      if (act === 'help') { showHelp(); }
      if (act === 'view-mode') { cycleViewMode(); }
      if (act === 'theme') { toggleTheme(); }
    });
    applyTheme();
    applyViewMode();
    sideEl.addEventListener('click', onSideClick);
    // هر جدولی که در main رندر شود خودکار سورت/فیلتر/برچسب موبایل می‌گیرد (بدون وابستگی به محل رندر)
    if (window.MutationObserver) {
      new MutationObserver(function () { enhanceTables(mainEl); qa('table.grid', mainEl).forEach(function (t) { if (t.__relabel) { t.__relabel(); } if (t.__applyHidden) { t.__applyHidden(); } }); }).observe(mainEl, { childList: true, subtree: true });
    }
    // موبایل: پنل رده‌ها پیش‌فرض بسته (دراپ‌داون رده در نوار جستجو جایگزین آن است)
    if (window.innerWidth < 900 && store('side') === null) { layoutEl.classList.add('side-collapsed'); }
    mainEl.addEventListener('click', onMainClick);
    mainEl.addEventListener('change', onMainChange);
    mainEl.addEventListener('input', onMainInput);
    mainEl.addEventListener('submit', function (e) { e.preventDefault(); });
  }

  /* ============================== side tree ============================== */
  function loadTree(force) {
    if (state.tree && !force) { return Promise.resolve(state.tree); }
    return api('tree').then(function (d) { state.tree = d; renderSide(); updateQuickCounts(); return d; }).catch(function (e) { sideEl.innerHTML = '<div class="error-box">' + esc(e.message) + '</div>'; });
  }
  function updateQuickCounts() {
    if (!state.tree) { return; }
    qa('[data-qc]').forEach(function (s) { var k = s.getAttribute('data-qc'); if (state.tree.totals[k] !== undefined) { s.textContent = fmtNum(state.tree.totals[k]); } });
  }
  function renderSide() {
    var t = state.tree;
    if (!t) { sideEl.innerHTML = '<div class="loading">بارگذاری رده‌ها…</div>'; return; }
    var L = state.list;
    var isList = state.view === 'list';
    function item(label, count, attrs, active) {
      var a = Object.keys(attrs).map(function (k) { return k + '="' + esc(attrs[k]) + '"'; }).join(' ');
      return '<div class="tree-item' + (active ? ' active' : '') + '" ' + a + '><span>' + label + '</span><span class="count">' + fmtNum(count) + '</span></div>';
    }
    var html = '<div class="side-title">بخش‌ها و رده‌ها <button type="button" class="icon-btn" data-side="refresh" title="بازخوانی شمارش‌ها">⟳</button></div>';
    html += item('همهٔ مشتریان', t.totals.all, { 'data-side': 'all' }, isList && !L.section_id && !L.category_id && L.scope !== 'trash' && L.scope !== 'nocat');
    var collapsed = store('collapsed') || {};
    asArray(t.sections).forEach(function (s) {
      var secActive = isList && String(L.section_id) === String(s.id) && !L.category_id;
      // پیش‌فرض: جمع‌شده؛ فقط بخشی که ردهٔ فعال در آن است یا کاربر بازش کرده، باز می‌ماند
      var hasActiveCat = asArray(s.categories).some(function (c) { return String(c.id) === String(L.category_id); });
      var isCollapsed = collapsed[s.id] === undefined ? !hasActiveCat : !!collapsed[s.id];
      html += '<div class="tree-section' + (isCollapsed ? ' collapsed' : '') + '" data-sec="' + esc(s.id) + '">';
      html += '<div class="tree-item' + (secActive ? ' active' : '') + '" data-side="section" data-id="' + esc(s.id) + '"><span><span class="caret" data-side="caret" data-id="' + esc(s.id) + '">▾</span> ' + esc(s.name) + '</span><span class="count">' + fmtNum(s.members) + '</span></div>';
      html += '<div class="tree-children">';
      asArray(s.categories).forEach(function (c) {
        html += item(esc(c.name), c.members, { 'data-side': 'category', 'data-id': c.id, 'data-sec-id': s.id }, isList && String(L.category_id) === String(c.id));
      });
      html += '</div></div>';
    });
    html += '<div class="side-divider"></div>';
    html += item('بدون رده', t.totals.nocat, { 'data-side': 'scope', 'data-id': 'nocat' }, isList && L.scope === 'nocat');
    html += item('تأیید نشده', t.totals.unconfirmed, { 'data-side': 'scope', 'data-id': 'unconfirmed' }, isList && L.scope === 'unconfirmed');
    html += item('حذف‌شده‌ها', t.totals.trash, { 'data-side': 'scope', 'data-id': 'trash' }, isList && L.scope === 'trash');
    html += '<div class="side-divider"></div><div class="note">برگزیده و مطلع بر اساس کاربر جاری (شناسهٔ ' + esc(t.current_user_id) + ') محاسبه می‌شوند.</div>';
    sideEl.innerHTML = html;
  }
  function onSideClick(e) {
    var caret = e.target.closest('[data-side="caret"]');
    if (caret) {
      e.stopPropagation();
      var sec = caret.closest('.tree-section');
      sec.classList.toggle('collapsed');
      var c = store('collapsed') || {}; c[caret.getAttribute('data-id')] = sec.classList.contains('collapsed'); store('collapsed', c);
      return;
    }
    var it = e.target.closest('[data-side]');
    if (!it) { return; }
    var kind = it.getAttribute('data-side');
    if (kind === 'refresh') { loadTree(true); return; }
    var over = { page: 1, section_id: '', category_id: '', scope: (state.list.scope === 'trash' || state.list.scope === 'nocat' || state.list.scope === 'unconfirmed') ? 'all' : state.list.scope };
    if (kind === 'section') { over.section_id = it.getAttribute('data-id'); }
    if (kind === 'category') { over.category_id = it.getAttribute('data-id'); over.section_id = it.getAttribute('data-sec-id'); }
    if (kind === 'scope') { over.scope = it.getAttribute('data-id'); }
    state.selected = {};
    go(listHash(over));
  }

  /* ============================== list view ============================== */
  // ستون‌های لیست = همهٔ فیلدهای جزئیات مشتری؛ کاربر با «انتخاب ستون‌ها» هر ترکیبی را نمایش/پنهان می‌کند (ذخیره در مرورگر).
  function plain(key) { return function (r) { return esc(dash(r[key])); }; }
  function tel(key) { return function (r) { return r[key] ? '<a href="tel:' + esc(r[key]) + '">' + esc(r[key]) + '</a>' : '—'; }; }
  var COLUMNS = [
    { key: 'id', group: 'اصلی', label: 'شناسه', sort: 'id', def: true, render: function (r) { return '<a href="#/client/' + esc(r.id) + '">' + esc(r.id) + '</a>'; } },
    { key: 'name', group: 'اصلی', label: 'نام کامل', sort: 'name', def: true, cls: 'name', render: function (r) { return '<a href="#/client/' + esc(r.id) + '">' + esc(r.name) + '</a>' + (r.is_fav ? ' <span title="برگزیده">★</span>' : ''); } },
    { key: 'type', group: 'اصلی', label: 'نوع', sort: 'type', def: true, render: function (r) { return '<span class="badge' + (r.type === 4 ? ' dark' : '') + '">' + esc(r.type_label) + '</span>'; } },
    { key: 'gender', group: 'اصلی', label: 'جنسیت', sort: 'gender', def: false, render: plain('gender') },
    { key: 'classify', group: 'اصلی', label: 'رده', def: true, cls: 'right', render: plain('classify') },
    { key: 'confirm', group: 'اصلی', label: 'تأیید', sort: 'confirm', def: false, render: function (r) { return r.confirm ? '<span class="badge accent">تأیید شده</span>' : '<span class="badge">تأیید نشده</span>'; } },
    { key: 'comment', group: 'اصلی', label: 'توضیحات', def: false, cls: 'wrap right', render: plain('comment') },
    { key: 'lable', group: 'اصلی', label: 'برچسب', sort: 'lable', def: false, render: plain('lable') },
    { key: 'mobile', group: 'تماس', label: 'تلفن همراه', def: true, render: tel('mobile') },
    { key: 'mobiles_all', group: 'تماس', label: 'همهٔ شماره‌های همراه', def: false, render: plain('mobiles_all') },
    { key: 'email', group: 'تماس', label: 'ایمیل', def: false, render: function (r) { return r.email ? '<a href="mailto:' + esc(r.email) + '">' + esc(r.email) + '</a>' : '—'; } },
    { key: 'emails_all', group: 'تماس', label: 'همهٔ ایمیل‌ها', def: false, render: plain('emails_all') },
    { key: 'work_phone', group: 'تماس', label: 'تلفن محل کار', def: false, render: tel('work_phone') },
    { key: 'home_phone', group: 'تماس', label: 'تلفن منزل', def: false, render: tel('home_phone') },
    { key: 'fax', group: 'تماس', label: 'فکس', def: false, render: plain('fax') },
    { key: 'website', group: 'تماس', label: 'وب‌سایت', sort: 'website', def: false, render: plain('website') },
    { key: 'national_code', group: 'هویتی', label: 'کد ملی / شناسهٔ ملی', def: true, render: plain('national_code') },
    { key: 'birthday', group: 'هویتی', label: 'تاریخ تولد', sort: 'birthday', def: false, render: plain('birthday') },
    { key: 'patronymic', group: 'هویتی', label: 'نام پدر', def: false, render: plain('patronymic') },
    { key: 'birthplace', group: 'هویتی', label: 'محل تولد', def: false, render: plain('birthplace') },
    { key: 'identity_no', group: 'هویتی', label: 'شماره شناسنامه', def: false, render: plain('identity_no') },
    { key: 'nationality', group: 'هویتی', label: 'ملیت', def: false, render: plain('nationality') },
    { key: 'passport_no', group: 'هویتی', label: 'شماره پاسپورت', def: false, render: plain('passport_no') },
    { key: 'state', group: 'آدرس', label: 'استان', def: false, render: plain('state') },
    { key: 'city', group: 'آدرس', label: 'شهر', def: true, render: plain('city') },
    { key: 'address', group: 'آدرس', label: 'آدرس', def: false, cls: 'wrap right', render: plain('address') },
    { key: 'zip_code', group: 'آدرس', label: 'کد پستی', def: false, render: plain('zip_code') },
    { key: 'company', group: 'کسب‌وکار', label: 'شرکت / نام کسب‌وکار', sort: 'company', def: false, render: plain('company') },
    { key: 'job', group: 'کسب‌وکار', label: 'شغل', sort: 'job', def: false, render: plain('job') },
    { key: 'tin', group: 'کسب‌وکار', label: 'کد اقتصادی', sort: 'tin', def: false, render: plain('tin') },
    { key: 'kpp', group: 'کسب‌وکار', label: 'کد ملی مدیرعامل', sort: 'kpp', def: false, render: plain('kpp') },
    { key: 'reg_number', group: 'کسب‌وکار', label: 'شماره ثبت', sort: 'reg_number', def: false, render: plain('reg_number') },
    { key: 'industry', group: 'کسب‌وکار', label: 'پیشه', sort: 'industry', def: false, render: plain('industry') },
    { key: 'personality_type', group: 'کسب‌وکار', label: 'نوع شخصیت حقوقی', def: false, render: plain('personality_type') },
    { key: 'number_personnel', group: 'کسب‌وکار', label: 'تعداد پرسنل', sort: 'number_personnel', def: false, render: plain('number_personnel') },
    { key: 'issue_activity', group: 'کسب‌وکار', label: 'موضوع/حوزه فعالیت', def: false, render: plain('issue_activity') },
    { key: 'property_code', group: 'کسب‌وکار', label: 'شماره پروانه کسب', def: false, render: plain('property_code') },
    { key: 'balance', group: 'حسابداری و فروش', label: 'مانده حساب', def: false, render: function (r) { return esc(r.balance_fmt || '0'); } },
    { key: 'account_code', group: 'حسابداری و فروش', label: 'کد حساب', def: false, render: plain('account_code') },
    { key: 'sales_count', group: 'حسابداری و فروش', label: 'تعداد فاکتور فروش', def: false, render: function (r) { return fmtNum(r.sales_count); } },
    { key: 'last_invoice', group: 'حسابداری و فروش', label: 'آخرین فاکتور', def: false, render: plain('last_invoice') },
    { key: 'todo_count', group: 'فعالیت', label: 'تعداد اقدام', def: false, render: function (r) { return fmtNum(r.todo_count); } },
    { key: 'events_count', group: 'فعالیت', label: 'تعداد رویداد', def: false, render: function (r) { return fmtNum(r.events_count); } },
    { key: 'contacts_count', group: 'فعالیت', label: 'تعداد رابط', def: false, render: function (r) { return fmtNum(r.contacts_count); } },
    { key: 'last_comment', group: 'فعالیت', label: 'آخرین توضیح', def: false, cls: 'wrap right', render: plain('last_comment') },
    { key: 'has_folder', group: 'فعالیت', label: 'پوشهٔ اسناد', def: false, render: function (r) { return r.has_folder ? '<span class="badge accent">دارد</span>' : '<span class="badge">ندارد</span>'; } },
    { key: 'assigned', group: 'کاربران', label: 'مطلع', def: true, render: function (r) { return r.assigned === undefined ? '<span class="note" title="فقط در تب «مطلع» یا پروفایل مشتری">—</span>' : esc(asArray(r.assigned).join('، ') || '—'); } },
    { key: 'notify', group: 'کاربران', label: 'اعلان‌گیران', def: false, render: function (r) { return '<span class="badge' + (r.is_notified ? ' outline' : '') + '" title="' + (r.is_notified ? 'شما اعلان‌های این مشتری را می‌گیرید' : 'تعداد همکارانی که اعلان این مشتری را می‌گیرند') + '">' + fmtNum(r.notify_count) + (r.is_notified ? ' ✓' : '') + '</span>'; } },
    { key: 'author', group: 'سیستم', label: 'ایجادکننده', def: true, render: plain('author') },
    { key: 'created', group: 'سیستم', label: 'تاریخ ایجاد', sort: 'created', def: true, render: plain('created') },
    { key: 'modified', group: 'سیستم', label: 'تاریخ تغییر', sort: 'modified', def: false, render: plain('modified') },
    { key: 'modifier', group: 'سیستم', label: 'تغییردهنده', def: false, render: plain('modifier') }
  ];
  var QUICK_TABS = [
    { key: 'all', label: 'همه', count: 'all' }, { key: 'person', label: 'حقیقی', count: 'person' }, { key: 'business', label: 'حقوقی', count: 'business' },
    { key: 'favorite', label: 'برگزیده', count: 'favorite' }, { key: 'assign', label: 'مطلع' }, { key: 'events', label: 'رویدادها' }
  ];
  var ADV_FIELD_DEFS = [
    { key: 'name', label: 'نام کامل', type: 'text' }, { key: 'mobile', label: 'تلفن همراه', type: 'text' }, { key: 'email', label: 'ایمیل', type: 'text' },
    { key: 'national_code', label: 'کد ملی', type: 'text' }, { key: 'phone', label: 'تلفن', type: 'text' }, { key: 'company', label: 'شرکت / کسب‌وکار', type: 'text' },
    { key: 'job', label: 'شغل', type: 'text' }, { key: 'tin', label: 'کد اقتصادی', type: 'text' }, { key: 'kpp', label: 'کد ملی مدیرعامل', type: 'text' },
    { key: 'reg_number', label: 'شماره ثبت', type: 'text' }, { key: 'industry', label: 'پیشه', type: 'text' }, { key: 'website', label: 'وب‌سایت', type: 'text' },
    { key: 'lable', label: 'برچسب', type: 'text' }, { key: 'comment', label: 'توضیحات', type: 'text' },
    { key: 'city', label: 'شهر', type: 'text' }, { key: 'state', label: 'استان', type: 'text' }, { key: 'address', label: 'آدرس', type: 'text' }, { key: 'zip_code', label: 'کد پستی', type: 'text' },
    { key: 'author', label: 'ایجادکننده', type: 'text' },
    { key: 'create_date', label: 'تاریخ ایجاد', type: 'date' }, { key: 'modified_date', label: 'تاریخ تغییر', type: 'date' }, { key: 'birth_date', label: 'تاریخ تولد', type: 'date' },
    { key: 'type', label: 'نوع مشتری', type: 'select', options: [[3, 'حقیقی'], [4, 'حقوقی']] },
    { key: 'gender', label: 'جنسیت', type: 'select', options: [[1, 'مرد'], [2, 'زن']] },
    { key: 'confirm', label: 'وضعیت تأیید', type: 'select', options: [[1, 'تأیید شده'], [0, 'تأیید نشده']] },
    { key: 'category', label: 'رده', type: 'category' },
    { key: 'has_sales', label: 'دارای فاکتور فروش', type: 'flag' }, { key: 'has_events', label: 'دارای رویداد', type: 'flag' }, { key: 'has_todo', label: 'دارای اقدام', type: 'flag' },
    { key: 'is_favorite', label: 'برگزیدهٔ من', type: 'flag' }, { key: 'is_notified', label: 'اعلان‌های آن را می‌گیرم', type: 'flag' }
  ];
  var OPS = {
    text: [['contains', 'شامل'], ['not_contains', 'شامل نباشد'], ['eq', 'برابر'], ['neq', 'متفاوت'], ['starts', 'شروع شود با'], ['empty', 'خالی'], ['not_empty', 'پر شده']],
    date: [['eq', 'برابر روز'], ['gte', 'از تاریخ'], ['lte', 'تا تاریخ'], ['last_days', 'در طی روز اخیر'], ['before_days', 'قبل از روز اخیر'], ['empty', 'خالی'], ['not_empty', 'پر شده']],
    select: [['eq', 'برابر'], ['neq', 'متفاوت']],
    category: [['eq', 'عضو رده'], ['neq', 'عضو رده نباشد']],
    flag: [['eq', 'دارد'], ['neq', 'ندارد']]
  };
  function visibleColumns() {
    var saved = store('cols');
    return COLUMNS.filter(function (c) { return saved ? saved.indexOf(c.key) >= 0 : c.def; });
  }

  function renderList() {
    crumbEl.innerHTML = 'لیست مشتریان';
    loadTree().then(renderSide);
    var L = state.list;
    var html = '<div class="panel">';
    html += '<div class="quick-tabs">' + QUICK_TABS.map(function (t) {
      var cnt = t.count ? '<span class="count" data-qc="' + t.count + '">' + (state.tree ? fmtNum(state.tree.totals[t.count]) : '…') + '</span>' : '';
      var active = L.scope === t.key || (t.key === 'all' && ['person', 'business', 'favorite', 'assign', 'events'].indexOf(L.scope) < 0);
      return '<button type="button" class="quick-tab' + (active ? ' active' : '') + '" data-act="scope" data-scope="' + t.key + '">' + t.label + cnt + '</button>';
    }).join('') + '</div>';
    html += '<div class="search-row"><div class="search-box"><span class="search-icon">🔍</span><input type="search" data-role="search" value="' + esc(L.q) + '" placeholder="جستجو: شناسه، نام، تلفن همراه، کد ملی، ایمیل، نام کسب‌وکار… (Enter)"></div>' +
      '<button type="button" class="btn" data-act="search">جستجو</button>' +
      '<select data-role="cat-select" title="رده" class="cat-select"><option value="">همهٔ رده‌ها</option>' + asArray(state.tree && state.tree.sections).map(function (s) {
        return '<optgroup label="' + esc(s.name) + '"><option value="s:' + s.id + '"' + (String(L.section_id) === String(s.id) && !L.category_id ? ' selected' : '') + '>همهٔ ' + esc(s.name) + ' (' + fmtNum(s.members) + ')</option>' +
          asArray(s.categories).map(function (c) { return '<option value="c:' + c.id + ':' + s.id + '"' + (String(L.category_id) === String(c.id) ? ' selected' : '') + '>' + esc(c.name) + ' (' + fmtNum(c.members) + ')</option>'; }).join('') + '</optgroup>';
      }).join('') + '</select>' +
      '<button type="button" class="btn secondary" data-act="adv-toggle">فیلتر پیشرفته' + (L.adv.length ? ' (' + L.adv.length + ')' : '') + '</button>' +
      '<button type="button" class="btn secondary" data-act="columns">انتخاب ستون‌ها</button>' +
      '<button type="button" class="btn secondary" data-act="refresh" title="بازخوانی">⟳</button></div>';
    html += '<div data-role="adv-panel" class="' + (L.adv.length ? '' : 'hidden') + '"></div>';
    html += '<div class="chips" data-role="chips"></div>';
    html += '<div class="bulk-bar" data-role="bulk"><b><span data-role="sel-count">0</span> مشتری انتخاب شده</b>' +
      '<button type="button" class="btn small" data-act="bulk-sms">✉ پیامک گروهی</button>' +
      '<button type="button" class="btn small" data-act="bulk-email">@ ایمیل گروهی</button>' +
      '<button type="button" class="btn small" data-act="bulk-fav">★ برگزیده</button>' +
      '<button type="button" class="btn small" data-act="bulk-unfav">☆ حذف از برگزیده</button>' +
      '<button type="button" class="btn small" data-act="bulk-category">تغییر رده</button>' +
      '<button type="button" class="btn small" data-act="bulk-confirm">تأیید</button>' +
      (L.scope === 'trash' ? '<button type="button" class="btn small" data-act="bulk-restore">بازگرداندن</button><button type="button" class="btn small" data-act="bulk-delete">حذف نهایی</button>' : '<button type="button" class="btn small" data-act="bulk-trash">انتقال به حذف‌شده‌ها</button>') +
      '<button type="button" class="btn small" data-act="bulk-export">خروجی Excel انتخاب‌شده‌ها</button>' +
      '<button type="button" class="btn small" data-act="bulk-clear">لغو انتخاب</button></div>';
    html += '<div data-role="table"><div class="loading">بارگذاری مشتریان…</div></div>';
    html += '<div class="pager" data-role="pager"></div></div>';
    mainEl.innerHTML = html;
    renderAdvPanel();
    renderChips();
    fetchList();
  }

  // ستون‌های پایه همیشه از سرور می‌آیند؛ فیلدهای جزئیات فقط وقتی انتخاب شده‌اند (cols) تا لیست کند نشود
  var BASE_KEYS = ['id', 'name', 'type', 'gender', 'classify', 'confirm', 'comment', 'mobile', 'email', 'national_code', 'state', 'city', 'address', 'zip_code', 'company', 'job', 'tin', 'created', 'modified', 'author', 'notify', 'assigned'];
  function extraCols() { return visibleColumns().map(function (c) { return c.key; }).filter(function (k) { return BASE_KEYS.indexOf(k) < 0; }).join(','); }
  function listParams(extra) {
    var L = state.list;
    return Object.assign({ scope: L.scope, section_id: L.section_id, category_id: L.category_id, q: L.q, page: L.page, per_page: L.per_page, sort: L.sort, dir: L.dir, adv: L.adv.length ? L.adv : undefined, cols: extraCols() || undefined }, extra || {});
  }
  var listSeq = 0;
  function fetchList() {
    var seq = ++listSeq;
    var box = q('[data-role="table"]');
    if (!box) { return; }
    box.innerHTML = '<div class="loading">بارگذاری مشتریان…</div>';
    var source = state.list.scope === 'assign' ? fetchNativeAssignList() : api('list', listParams());
    source.then(function (d) {
      if (seq !== listSeq) { return; }
      state.listRows = asArray(d.rows);
      state.total = d.total || 0;
      if (asArray(d.warnings).length) { toast('برخی شرط‌های فیلتر نادیده گرفته شد: ' + d.warnings.join('، '), true); }
      renderTable();
      renderPager();
    }).catch(function (e) { if (seq === listSeq) { box.innerHTML = '<div class="error-box">خطا در دریافت لیست: ' + esc(e.message) + '</div>'; } });
  }

  // تب «مطلع» لیست: رابطهٔ مطلع جدول قابل‌کوئری ندارد، پس همان JSON ماژول بومی (/crm/index/assign/?json=1) با نشست
  // کاربر جاری خوانده و به شکل ردیف‌های این لیست نگاشت می‌شود (همان داده و همان دسترسی ماژول اصلی).
  function fetchNativeAssignList() {
    var L = state.list;
    var params = { from: (L.page - 1) * L.per_page, count: L.per_page, json: 1, filter_id: 0, is_fast: L.q ? 1 : 0, search: L.q || '' };
    if (L.category_id) { params.left_id = 'category_' + L.category_id + '_' + (L.section_id || ''); params.category = L.category_id; params.section = L.section_id || ''; }
    else if (L.section_id) { params.left_id = 'section_' + L.section_id; params.section = L.section_id; }
    else { params.left_id = 'all'; }
    var url = CFG.baseUrl + '/crm/index/assign/?' + Object.keys(params).map(function (k) { return encodeURIComponent(k) + '=' + encodeURIComponent(params[k]); }).join('&');
    return fetch(url, { credentials: 'same-origin', headers: { 'X-Requested-With': 'XMLHttpRequest' } }).then(function (res) { return res.json(); }).then(function (j) {
      var rows = asArray(j.table).map(function (t, i) {
        var pa = asArray(j.profile_address)[i] || {};
        var nc = String((asArray(j.national_code)[i] || '')).replace(/^\d+_/, '');
        return { id: String(t.id), name: t.title || ((asArray(j.first_name)[i] || '') + ' ' + (asArray(j.last_name)[i] || '')).trim(), type: t.type === 4 ? 4 : 3, type_label: t.type === 4 ? 'حقوقی' : 'حقیقی',
          gender: '', created: fmtFiletime(asArray(j.create_date)[i]), modified: fmtFiletime(asArray(j.modified_date)[i]), author: asArray(j.author)[i] || '', confirm: true, comment: t.comment || '',
          company: '', job: '', tin: asArray(j.tin)[i] || '', mobile: asArray(j.mobile_phone)[i] || '', email: asArray(j.email)[i] || '', national_code: nc, state: pa.state || '', city: pa.city || '', address: pa.address || '', zip_code: pa.zip_code || '',
          classify: asArray(asArray(j.classify_persons)[i]).join('، '), is_fav: !!t.favorite, is_notified: false, notify_count: 0, deleted: false, assigned: asArray(asArray(j.assigned)[i]) };
      });
      return { ok: true, rows: rows, total: parseInt(j.total || rows.length, 10) || 0, warnings: [] };
    }).catch(function (e) { throw new Error('دریافت تب مطلع از ماژول بومی ناموفق بود: ' + e.message); });
  }
  // FILETIME (تیک ۱۰۰ns از ۱۶۰۱) -> تاریخ شمسی کوتاه، فقط برای ردیف‌های تب مطلع
  function fmtFiletime(ft) {
    var n = Number(ft); if (!n || n <= 0) { return ''; }
    var ms = n / 10000 - 11644473600000;
    try { return new Intl.DateTimeFormat('fa-IR-u-nu-latn', { year: 'numeric', month: '2-digit', day: '2-digit', hour: '2-digit', minute: '2-digit' }).format(new Date(ms)).replace(/،/g, ''); } catch (e) { return ''; }
  }

  function renderTable() {
    var cols = visibleColumns();
    var L = state.list;
    var html = '<div class="table-wrap"><table class="grid"><thead><tr><th class="nosort"><input type="checkbox" data-role="sel-all" title="انتخاب همه"></th>';
    cols.forEach(function (c) {
      var cls = c.sort ? (L.sort === c.sort ? (L.dir === 'asc' ? 'sort-asc' : 'sort-desc') : '') : 'nosort';
      html += '<th class="' + cls + '"' + (c.sort ? ' data-sort="' + c.sort + '"' : '') + '>' + esc(c.label) + '</th>';
    });
    html += '<th class="nosort">عملیات</th></tr></thead><tbody>';
    if (!state.listRows.length) {
      html += '<tr><td class="empty-row" colspan="' + (cols.length + 2) + '">مشتری‌ای با این شرایط یافت نشد.</td></tr>';
    }
    state.listRows.forEach(function (r) {
      html += '<tr data-id="' + esc(r.id) + '"' + (state.selected[r.id] ? ' class="selected"' : '') + '><td><input type="checkbox" data-role="sel" data-id="' + esc(r.id) + '"' + (state.selected[r.id] ? ' checked' : '') + '></td>';
      cols.forEach(function (c) { html += '<td class="' + (c.cls || '') + '">' + c.render(r) + '</td>'; });
      html += '<td><div class="row-actions">' +
        '<a class="icon-btn" href="#/client/' + esc(r.id) + '" title="بررسی">👁</a>' +
        '<a class="icon-btn" href="#/edit/' + esc(r.id) + '" title="ویرایش">✎</a>' +
        '<button type="button" class="icon-btn' + (r.is_fav ? ' on' : '') + '" data-act="fav" data-id="' + esc(r.id) + '" data-on="' + (r.is_fav ? 1 : 0) + '" title="برگزیده">★</button>' +
        '<button type="button" class="icon-btn" data-act="comment" data-id="' + esc(r.id) + '" data-name="' + esc(r.name) + '" title="توضیحات جدید">✎+</button>' +
        (r.mobile ? '<button type="button" class="icon-btn" data-act="sms" data-id="' + esc(r.id) + '" data-name="' + esc(r.name) + '" data-mobile="' + esc(r.mobile) + '" title="ارسال پیامک">✉</button>' : '') +
        (r.email ? '<button type="button" class="icon-btn" data-act="email" data-id="' + esc(r.id) + '" data-name="' + esc(r.name) + '" data-address="' + esc(r.email) + '" title="ارسال ایمیل">@</button>' : '') +
        (hasSiteId(r.comment) ? '<button type="button" class="icon-btn" data-act="site" data-id="' + esc(r.id) + '" data-name="' + esc(r.name) + '" title="نمایش در سایت (بات ۴۸۶)">🌐</button>' : '') +
        '<button type="button" class="icon-btn" data-act="row-menu" data-id="' + esc(r.id) + '" title="بیشتر">⋯</button>' +
        '</div></td></tr>';
    });
    html += '</tbody></table></div>';
    q('[data-role="table"]').innerHTML = html;
    updateBulkBar();
  }

  function renderPager() {
    var L = state.list, pages = Math.max(1, Math.ceil(state.total / L.per_page));
    var html = '';
    html += '<button type="button" class="btn small secondary" data-act="page" data-page="1"' + (L.page <= 1 ? ' disabled' : '') + '>« اول</button>';
    html += '<button type="button" class="btn small secondary" data-act="page" data-page="' + (L.page - 1) + '"' + (L.page <= 1 ? ' disabled' : '') + '>قبلی</button>';
    html += '<span>صفحهٔ <input type="number" data-role="page-input" value="' + L.page + '" min="1" max="' + pages + '" style="width:64px;padding:3px 6px"> از ' + fmtNum(pages) + ' — مجموع <b>' + fmtNum(state.total) + '</b> مشتری</span>';
    html += '<button type="button" class="btn small secondary" data-act="page" data-page="' + (L.page + 1) + '"' + (L.page >= pages ? ' disabled' : '') + '>بعدی</button>';
    html += '<button type="button" class="btn small secondary" data-act="page" data-page="' + pages + '"' + (L.page >= pages ? ' disabled' : '') + '>آخر »</button>';
    html += '<span>در صفحه: <select data-role="per-page">' + [15, 30, 50, 100, 200].map(function (n) { return '<option value="' + n + '"' + (n === L.per_page ? ' selected' : '') + '>' + n + '</option>'; }).join('') + '</select></span>';
    q('[data-role="pager"]').innerHTML = html;
  }

  function renderChips() {
    var box = q('[data-role="chips"]');
    if (!box) { return; }
    var L = state.list, chips = [];
    if (L.q) { chips.push({ label: 'جستجو: ' + L.q, clear: { q: '' } }); }
    if (state.tree) {
      asArray(state.tree.sections).forEach(function (s) {
        if (String(s.id) === String(L.section_id) && !L.category_id) { chips.push({ label: 'بخش: ' + s.name, clear: { section_id: '' } }); }
        asArray(s.categories).forEach(function (c) { if (String(c.id) === String(L.category_id)) { chips.push({ label: 'رده: ' + s.name + '/' + c.name, clear: { category_id: '', section_id: '' } }); } });
      });
    }
    var scopeLabels = { trash: 'حذف‌شده‌ها', nocat: 'بدون رده', unconfirmed: 'تأیید نشده', favorite: 'برگزیده', assign: 'مطلع', events: 'دارای رویداد', person: 'حقیقی', business: 'حقوقی' };
    if (scopeLabels[L.scope]) { chips.push({ label: scopeLabels[L.scope], clear: { scope: 'all' } }); }
    L.adv.forEach(function (a, i) {
      var f = ADV_FIELD_DEFS.filter(function (d) { return d.key === a.field; })[0];
      var opLabel = ((OPS[f ? f.type : 'text'] || []).filter(function (o) { return o[0] === a.op; })[0] || [])[1] || a.op;
      chips.push({ label: (f ? f.label : a.field) + ' ' + opLabel + (a.value ? ' «' + a.value + '»' : ''), advIndex: i });
    });
    box.innerHTML = chips.map(function (c, i) {
      return '<span class="chip accent" data-chip="' + i + '">' + esc(c.label) + ' <span class="x" data-act="chip-x" data-chip="' + i + '">✕</span></span>';
    }).join('') + (chips.length > 1 ? '<span class="chip" data-act="chips-clear" style="cursor:pointer">پاک کردن همه</span>' : '');
    box.__chips = chips;
  }

  function renderAdvPanel() {
    var panel = q('[data-role="adv-panel"]');
    if (!panel) { return; }
    var rows = state.list.adv.length ? state.list.adv : [{ field: 'name', op: 'contains', value: '' }];
    var saved = store('saved_filters') || [];
    var html = '<div class="panel" style="background:#fafafa"><div class="panel-title">شرایط فیلتر <span class="note">همهٔ شرط‌ها با «و» ترکیب می‌شوند</span></div><div class="adv-rows">';
    rows.forEach(function (r, i) { html += advRowHtml(r, i); });
    html += '</div><div class="adv-actions">' +
      '<button type="button" class="btn" data-act="adv-apply">اجرا کردن</button>' +
      '<button type="button" class="btn secondary" data-act="adv-add">＋ شرط</button>' +
      '<button type="button" class="btn secondary" data-act="adv-save">ذخیرهٔ فیلتر</button>' +
      '<button type="button" class="btn secondary" data-act="adv-clear">پاک کردن</button>' +
      '<button type="button" class="btn secondary" data-act="adv-share">اشتراک (کپی لینک)</button></div>';
    if (saved.length) {
      html += '<div class="saved-filters"><span class="note">فیلترهای ذخیره‌شده:</span>' + saved.map(function (s, i) {
        return '<span class="chip" style="cursor:pointer" data-act="adv-load" data-idx="' + i + '">' + esc(s.name) + ' <span class="x" data-act="adv-del-saved" data-idx="' + i + '">✕</span></span>';
      }).join('') + '</div>';
    }
    html += '</div>';
    panel.innerHTML = html;
  }
  function advRowHtml(r, i) {
    var f = ADV_FIELD_DEFS.filter(function (d) { return d.key === r.field; })[0] || ADV_FIELD_DEFS[0];
    var ops = OPS[f.type] || OPS.text;
    var html = '<div class="adv-row" data-adv-row="' + i + '">';
    html += '<select data-adv="field">' + ADV_FIELD_DEFS.map(function (d) { return '<option value="' + d.key + '"' + (d.key === f.key ? ' selected' : '') + '>' + esc(d.label) + '</option>'; }).join('') + '</select>';
    html += '<select data-adv="op">' + ops.map(function (o) { return '<option value="' + o[0] + '"' + (o[0] === r.op ? ' selected' : '') + '>' + o[1] + '</option>'; }).join('') + '</select>';
    var noValue = r.op === 'empty' || r.op === 'not_empty' || f.type === 'flag';
    if (f.type === 'select') {
      html += '<select data-adv="value"' + (noValue ? ' disabled' : '') + '>' + f.options.map(function (o) { return '<option value="' + o[0] + '"' + (String(o[0]) === String(r.value) ? ' selected' : '') + '>' + o[1] + '</option>'; }).join('') + '</select>';
    } else if (f.type === 'category') {
      var opts = '';
      asArray(state.tree && state.tree.sections).forEach(function (s) { asArray(s.categories).forEach(function (c) { opts += '<option value="' + c.id + '"' + (String(c.id) === String(r.value) ? ' selected' : '') + '>' + esc(s.name + ' / ' + c.name) + '</option>'; }); });
      html += '<select data-adv="value">' + opts + '</select>';
    } else if (f.type === 'flag') {
      html += '<input type="text" data-adv="value" value="" disabled placeholder="—">';
    } else {
      var ph = f.type === 'date' ? ((r.op === 'last_days' || r.op === 'before_days') ? 'تعداد روز' : 'مثال: 1405/06/12') : 'مقدار';
      html += '<input type="text" data-adv="value" value="' + esc(r.value || '') + '" placeholder="' + ph + '"' + (noValue ? ' disabled' : '') + '>';
    }
    html += '<button type="button" class="icon-btn" data-act="adv-remove" data-idx="' + i + '" title="حذف شرط">✕</button></div>';
    return html;
  }
  function readAdvRows() {
    return qa('[data-adv-row]').map(function (row) {
      var v = q('[data-adv="value"]', row);
      return { field: q('[data-adv="field"]', row).value, op: q('[data-adv="op"]', row).value, value: v && !v.disabled ? v.value.trim() : '' };
    }).filter(function (r) { return r.field && (r.value !== '' || r.op === 'empty' || r.op === 'not_empty' || (ADV_FIELD_DEFS.filter(function (d) { return d.key === r.field; })[0] || {}).type === 'flag'); });
  }

  function updateBulkBar() {
    var ids = Object.keys(state.selected).filter(function (k) { return state.selected[k]; });
    var bar = q('[data-role="bulk"]');
    if (!bar) { return; }
    bar.classList.toggle('show', ids.length > 0);
    var c = q('[data-role="sel-count"]'); if (c) { c.textContent = fmtNum(ids.length); }
  }
  function selectedIds() { return Object.keys(state.selected).filter(function (k) { return state.selected[k]; }); }

  /* ============================== list events ============================== */
  function onMainClick(e) {
    var a = e.target.closest('[data-act]');
    var th = e.target.closest('th[data-sort]');
    if (th && !a) {
      var s = th.getAttribute('data-sort');
      go(listHash({ sort: s, dir: (state.list.sort === s && state.list.dir === 'desc') ? 'asc' : 'desc', page: 1 }));
      return;
    }
    if (!a) { return; }
    var act = a.getAttribute('data-act');
    var id = a.getAttribute('data-id');
    switch (act) {
      case 'scope': state.selected = {}; go(listHash({ scope: a.getAttribute('data-scope'), page: 1 })); break;
      case 'search': doSearch(); break;
      case 'refresh': fetchList(); loadTree(true); break;
      case 'page': go(listHash({ page: parseInt(a.getAttribute('data-page'), 10) })); break;
      case 'columns': showColumnChooser(); break;
      case 'adv-toggle': q('[data-role="adv-panel"]').classList.toggle('hidden'); break;
      case 'adv-add': { var rows = readAdvRows(); rows.push({ field: 'name', op: 'contains', value: '' }); state.list.adv = rows; renderAdvPanel(); break; }
      case 'adv-remove': { var rr = qa('[data-adv-row]').map(function (row) { var v = q('[data-adv="value"]', row); return { field: q('[data-adv="field"]', row).value, op: q('[data-adv="op"]', row).value, value: v && !v.disabled ? v.value : '' }; }); rr.splice(parseInt(a.getAttribute('data-idx'), 10), 1); state.list.adv = rr; renderAdvPanel(); if (!rr.length) { go(listHash({ adv: [], page: 1 })); } break; }
      case 'adv-apply': go(listHash({ adv: readAdvRows(), page: 1 })); break;
      case 'adv-clear': state.list.adv = []; renderAdvPanel(); go(listHash({ adv: [], page: 1 })); break;
      case 'adv-save': saveFilter(); break;
      case 'adv-load': { var sf = (store('saved_filters') || [])[parseInt(a.getAttribute('data-idx'), 10)]; if (sf) { go(listHash(Object.assign({ page: 1 }, sf.state))); } break; }
      case 'adv-del-saved': { e.stopPropagation(); var list = store('saved_filters') || []; list.splice(parseInt(a.getAttribute('data-idx'), 10), 1); store('saved_filters', list); renderAdvPanel(); break; }
      case 'adv-share': { var url = location.href.split('#')[0] + listHash({ adv: readAdvRows() }); copyText(url); break; }
      case 'chip-x': { var chips = q('[data-role="chips"]').__chips || []; var ch = chips[parseInt(a.getAttribute('data-chip'), 10)]; if (!ch) { break; } if (ch.advIndex !== undefined) { var adv = state.list.adv.slice(); adv.splice(ch.advIndex, 1); go(listHash({ adv: adv, page: 1 })); } else { go(listHash(Object.assign({ page: 1 }, ch.clear))); } break; }
      case 'chips-clear': go('#/list'); break;
      case 'fav': toggleFavorite(id, a.getAttribute('data-on') === '1', a); break;
      case 'comment': openCommentModal(id, a.getAttribute('data-name')); break;
      case 'site': openSiteModal(id, a.getAttribute('data-name')); break;
      case 'sms': {
        var c0 = (state.client.data && state.client.data.id === id) ? state.client.data : null;
        var nums = c0 ? c0.mobiles.map(function (m) { return m.value; }) : [a.getAttribute('data-mobile')];
        var row0 = state.listRows.filter(function (x) { return x.id === id; })[0];
        if (!c0 && row0 && row0.mobiles_all) { nums = row0.mobiles_all.split('، ').filter(Boolean); }
        openSmsModal(id, a.getAttribute('data-name'), nums, a.getAttribute('data-mobile'));
        break;
      }
      case 'bulk-sms': openBulkSmsModal(selectedIds()); break;
      case 'email': {
        var c1 = (state.client.data && state.client.data.id === id) ? state.client.data : null;
        var addrs = c1 ? c1.emails.map(function (m) { return m.value; }) : [a.getAttribute('data-address')];
        var row1 = state.listRows.filter(function (x) { return x.id === id; })[0];
        if (!c1 && row1 && row1.emails_all) { addrs = row1.emails_all.split('، ').filter(Boolean); }
        openEmailModal(id, a.getAttribute('data-name'), addrs, a.getAttribute('data-address'));
        break;
      }
      case 'bulk-email': openBulkEmailModal(selectedIds()); break;
      case 'row-menu': showRowMenu(id); break;
      case 'bulk-clear': state.selected = {}; renderTable(); break;
      case 'bulk-fav': bulkNative(selectedIds(), function (cid) { return nativeCall('/crm/index/set_favorite/', { id: cid, favorite: 1 }); }, 'افزودن به برگزیده'); break;
      case 'bulk-unfav': bulkNative(selectedIds(), function (cid) { return nativeCall('/crm/index/set_favorite/', { id: cid, favorite: 0 }); }, 'حذف از برگزیده'); break;
      case 'bulk-confirm': bulkNative(selectedIds(), function (cid) { return nativeCall('/crm/index/confirm/', { id: cid, type: 'confirm' }); }, 'تأیید مشتریان'); break;
      case 'bulk-trash': confirmModal('انتقال به حذف‌شده‌ها', fmtNum(selectedIds().length) + ' مشتری به حذف‌شده‌ها منتقل می‌شوند (قابل بازگرداندن). ادامه می‌دهید؟', 'انتقال', function () { return bulkNative(selectedIds(), function (cid) { return nativeCall('/crm/index/change/', { id: cid }); }, 'انتقال به حذف‌شده‌ها'); }, true); break;
      case 'bulk-restore': bulkNative(selectedIds(), function (cid) { return nativeCall('/crm/index/restore/', { id: cid, type: 'restor' }); }, 'بازگرداندن'); break;
      case 'bulk-delete': confirmModal('حذف نهایی', '<b>حذف نهایی برگشت‌پذیر نیست</b> و فقط با دسترسی مدیر انجام می‌شود. ' + fmtNum(selectedIds().length) + ' مشتری حذف شوند؟', 'حذف نهایی', function () { return bulkNative(selectedIds(), function (cid) { return nativeCall('/crm/index/delete/', { id: cid }); }, 'حذف نهایی'); }, true); break;
      case 'bulk-category': openCategoryModal(selectedIds()); break;
      case 'bulk-export': exportRows(state.listRows.filter(function (r) { return state.selected[r.id]; }), 'crm_selected'); break;
      default: onClientClick(act, a, e);
    }
  }
  function onMainChange(e) {
    var t = e.target;
    if (t.matches('[data-role="sel-all"]')) { state.listRows.forEach(function (r) { state.selected[r.id] = t.checked; }); renderTable(); return; }
    if (t.matches('[data-role="sel"]')) { state.selected[t.getAttribute('data-id')] = t.checked; t.closest('tr').classList.toggle('selected', t.checked); updateBulkBar(); return; }
    if (t.matches('[data-role="per-page"]')) { state.list.per_page = parseInt(t.value, 10); store('per_page', state.list.per_page); go(listHash({ page: 1 })); return; }
    if (t.matches('[data-role="cat-select"]')) {
      var v = t.value.split(':');
      state.selected = {};
      var over = { page: 1, section_id: '', category_id: '', scope: (['trash', 'nocat', 'unconfirmed'].indexOf(state.list.scope) >= 0) ? 'all' : state.list.scope };
      if (v[0] === 's') { over.section_id = v[1]; }
      if (v[0] === 'c') { over.category_id = v[1]; over.section_id = v[2]; }
      go(listHash(over)); return;
    }
    if (t.matches('[data-adv="field"]') || t.matches('[data-adv="op"]')) {
      var rows = qa('[data-adv-row]').map(function (row) { var v = q('[data-adv="value"]', row); return { field: q('[data-adv="field"]', row).value, op: q('[data-adv="op"]', row).value, value: v && !v.disabled ? v.value : '' }; });
      if (t.matches('[data-adv="field"]')) { var idx = parseInt(t.closest('[data-adv-row]').getAttribute('data-adv-row'), 10); var f = ADV_FIELD_DEFS.filter(function (d) { return d.key === rows[idx].field; })[0]; rows[idx].op = (OPS[f.type] || OPS.text)[0][0]; rows[idx].value = ''; }
      state.list.adv = rows; renderAdvPanel(); return;
    }
    if (t.matches('[data-role="page-input"]')) { var p = parseInt(t.value, 10); if (p > 0) { go(listHash({ page: p })); } return; }
    onClientChange(t);
  }
  function onMainInput(e) {
    // پاک‌کردن جستجو با دکمهٔ ✕ فیلد search (رویداد input بدون inputType)
    if (e.target.matches('[data-role="search"]') && e.inputType === undefined && e.target.value === '' && state.list.q) { doSearch(); }
  }
  root.addEventListener('keydown', function (e) {
    if (e.key === 'Enter' && e.target.matches && e.target.matches('[data-role="search"]')) { doSearch(); }
    if (e.key === 'Enter' && e.target.matches && e.target.matches('[data-adv="value"]')) { go(listHash({ adv: readAdvRows(), page: 1 })); }
  });
  function doSearch() { var inp = q('[data-role="search"]'); state.selected = {}; go(listHash({ q: inp ? inp.value.trim() : '', page: 1 })); }

  function copyText(txt) {
    var done = function () { toast('لینک کپی شد'); };
    if (navigator.clipboard && navigator.clipboard.writeText) { navigator.clipboard.writeText(txt).then(done, function () { openModal('لینک اشتراک', '<input type="text" style="width:100%" value="' + esc(txt) + '" readonly onclick="this.select()">'); }); }
    else { openModal('لینک اشتراک', '<input type="text" style="width:100%" value="' + esc(txt) + '" readonly onclick="this.select()">'); }
  }
  function saveFilter() {
    var rows = readAdvRows();
    var body = openModal('ذخیرهٔ فیلتر', '<div class="form-grid"><div class="fld full"><label>نام فیلتر</label><input type="text" data-f="name" placeholder="مثلاً: مشتریان تهران بدون فاکتور"></div></div><p class="note">فیلتر شامل شرط‌های پیشرفته، جستجو، بخش/رده و تب فعال است و فقط در همین مرورگر ذخیره می‌شود.</p>', [
      { label: 'ذخیره', onClick: function () { var name = q('[data-f="name"]', body).value.trim(); if (!name) { toast('نام فیلتر را وارد کنید', true); return; } var list = store('saved_filters') || []; list.push({ name: name, state: { adv: rows, q: state.list.q, scope: state.list.scope, section_id: state.list.section_id, category_id: state.list.category_id } }); store('saved_filters', list); closeModal(); renderAdvPanel(); toast('فیلتر ذخیره شد'); } },
      { label: 'لغو', cls: 'secondary' }
    ]);
  }
  // انتخابگر ستون: همهٔ فیلدهای جزئیات مشتری، گروه‌بندی‌شده، با جستجو و انتخاب گروهی؛ ترتیب = ترتیب گروه‌ها
  function showColumnChooser() {
    var saved = store('cols');
    var groups = [];
    COLUMNS.forEach(function (c) { var g = groups.filter(function (x) { return x.name === c.group; })[0]; if (!g) { g = { name: c.group, cols: [] }; groups.push(g); } g.cols.push(c); });
    var html = '<div class="chooser-top"><input type="search" data-f="q" placeholder="جستجوی نام ستون…"><span class="note" data-f="cnt"></span>' +
      '<button type="button" class="btn small secondary" data-cc="all">همه</button><button type="button" class="btn small secondary" data-cc="none">هیچ‌کدام</button><button type="button" class="btn small secondary" data-cc="def">پیش‌فرض</button></div>';
    groups.forEach(function (g) {
      html += '<div class="chooser-group" data-group="' + esc(g.name) + '"><div class="chooser-group-title"><label><input type="checkbox" data-gc="' + esc(g.name) + '"> ' + esc(g.name) + '</label></div><div class="chooser-items">' +
        g.cols.map(function (c) { var on = saved ? saved.indexOf(c.key) >= 0 : c.def; return '<label class="chip chooser-item" data-label="' + esc(c.label) + '"><input type="checkbox" data-col="' + c.key + '"' + (on ? ' checked' : '') + '> ' + esc(c.label) + '</label>'; }).join('') + '</div></div>';
    });
    html += '<p class="note">ستون‌های انتخاب‌شده در همین مرورگر ذخیره می‌شوند و خروجی Excel هم همین ستون‌ها را دارد. برای پنهان‌کردن موقت یک ستون از دکمهٔ «ستون‌ها» بالای هر جدول هم می‌توانید استفاده کنید.</p>';
    var body = openModal('انتخاب ستون‌های لیست', html, [
      { label: 'اعمال', onClick: function () { var keys = qa('[data-col]', body).filter(function (c) { return c.checked; }).map(function (c) { return c.getAttribute('data-col'); }); if (!keys.length) { toast('دست‌کم یک ستون انتخاب کنید', true); return; } store('cols', keys); closeModal(); fetchList(); } },
      { label: 'لغو', cls: 'secondary' }
    ], { wide: true });
    function syncGroups() { qa('[data-gc]', body).forEach(function (g) { var items = qa('.chooser-group[data-group="' + g.getAttribute('data-gc') + '"] [data-col]', body); var on = items.filter(function (i) { return i.checked; }).length; g.checked = on === items.length; g.indeterminate = on > 0 && on < items.length; }); var total = qa('[data-col]', body).filter(function (i) { return i.checked; }).length; q('[data-f="cnt"]', body).textContent = fmtNum(total) + ' ستون انتخاب شده'; }
    body.addEventListener('change', function (e) {
      if (e.target.matches('[data-gc]')) { qa('.chooser-group[data-group="' + e.target.getAttribute('data-gc') + '"] [data-col]', body).forEach(function (i) { i.checked = e.target.checked; }); }
      syncGroups();
    });
    body.addEventListener('click', function (e) {
      var b = e.target.closest('[data-cc]'); if (!b) { return; }
      var mode = b.getAttribute('data-cc');
      qa('[data-col]', body).forEach(function (i) { var def = COLUMNS.filter(function (c) { return c.key === i.getAttribute('data-col'); })[0]; i.checked = mode === 'all' ? true : mode === 'none' ? false : !!(def && def.def); });
      syncGroups();
    });
    q('[data-f="q"]', body).addEventListener('input', function () {
      var t = this.value.trim();
      qa('.chooser-item', body).forEach(function (it) { it.style.display = (!t || it.getAttribute('data-label').indexOf(t) >= 0) ? '' : 'none'; });
      qa('.chooser-group', body).forEach(function (g) { g.style.display = qa('.chooser-item', g).some(function (it) { return it.style.display !== 'none'; }) ? '' : 'none'; });
    });
    syncGroups();
  }
  function showRowMenu(id) {
    var r = state.listRows.filter(function (x) { return x.id === id; })[0] || { id: id, name: '' };
    var trash = state.list.scope === 'trash';
    openModal(r.name || ('مشتری ' + id), '<div class="cards">' +
      '<a class="card" href="#/client/' + esc(id) + '"><div class="t">بررسی</div><div class="s">پروفایل ۳۶۰ درجه</div></a>' +
      '<a class="card" href="#/edit/' + esc(id) + '"><div class="t">ویرایش</div><div class="s">اطلاعات عمومی، تماس، آدرس</div></a>' +
      '<a class="card" href="' + esc(CFG.baseUrl + '/?page=/crm/client/edit/' + id + '&tab=1') + '" target="_blank" rel="noopener"><div class="t">باز کردن در تیم‌یار ↗</div><div class="s">فرم اصلی ماژول</div></a>' +
      '<div class="card" data-act="menu-comment" data-id="' + esc(id) + '" data-name="' + esc(r.name) + '" style="cursor:pointer"><div class="t">توضیحات جدید</div><div class="s">ثبت از طریق API</div></div>' +
      (hasSiteId(r.comment) ? '<div class="card" data-act="menu-site" data-id="' + esc(id) + '" data-name="' + esc(r.name) + '" style="cursor:pointer"><div class="t">🌐 نمایش در سایت</div><div class="s">اجرای بات ۴۸۶ روی شناسهٔ سایت این مشتری</div></div>' : '') +
      '<div class="card" data-act="menu-notify" data-id="' + esc(id) + '" style="cursor:pointer"><div class="t">مطلع شدن / حذف از مطلعین</div><div class="s">وضعیت فعلی شما از API خوانده و برعکس می‌شود</div></div>' +
      '<div class="card" data-act="menu-category" data-id="' + esc(id) + '" style="cursor:pointer"><div class="t">تغییر رده</div><div class="s">' + esc(r.classify || 'بدون رده') + '</div></div>' +
      '<div class="card" data-act="menu-share" data-id="' + esc(id) + '" style="cursor:pointer"><div class="t">اشتراک</div><div class="s">کپی لینک پروفایل برای همکاران</div></div>' +
      '<a class="card" href="' + esc(CFG.baseUrl + '/crm/client/print/' + id) + '" target="_blank" rel="noopener"><div class="t">چاپ ↗</div><div class="s">چاپ اطلاعات مشتری</div></a>' +
      '<a class="card" href="' + esc(CFG.baseUrl + '/crm/client/envelope_print/' + id) + '" target="_blank" rel="noopener"><div class="t">پرینت پاکتی ↗</div><div class="s">برچسب پستی</div></a>' +
      (!r.confirm && !trash ? '<div class="card" data-act="menu-confirm" data-id="' + esc(id) + '" style="cursor:pointer"><div class="t">تأیید مشتری</div><div class="s">فعال‌سازی رکورد</div></div>' : '') +
      (trash ? '<div class="card" data-act="menu-restore" data-id="' + esc(id) + '" style="cursor:pointer"><div class="t">بازگرداندن</div><div class="s">خروج از حذف‌شده‌ها</div></div><div class="card" data-act="menu-delete" data-id="' + esc(id) + '" style="cursor:pointer"><div class="t">حذف نهایی</div><div class="s">فقط مدیر — برگشت‌پذیر نیست</div></div>'
        : '<div class="card" data-act="menu-trash" data-id="' + esc(id) + '" style="cursor:pointer"><div class="t">انتقال به حذف‌شده‌ها</div><div class="s">قابل بازگرداندن</div></div>') +
      '</div>');
  }
  overlay.addEventListener('click', function (e) {
    var a = e.target.closest('[data-act]');
    if (!a) { return; }
    var act = a.getAttribute('data-act'), id = a.getAttribute('data-id');
    if (act === 'menu-comment') { closeModal(); openCommentModal(id, a.getAttribute('data-name')); }
    if (act === 'menu-site') { closeModal(); openSiteModal(id, a.getAttribute('data-name')); }
    if (act === 'menu-notify') { closeModal(); toggleNotify(id); }
    if (act === 'menu-category') { closeModal(); openCategoryModal([id]); }
    if (act === 'menu-share') { closeModal(); copyText(location.href.split('#')[0] + '#/client/' + id); }
    if (act === 'menu-confirm') { closeModal(); bulkNative([id], function (cid) { return nativeCall('/crm/index/confirm/', { id: cid, type: 'confirm' }); }, 'تأیید مشتری'); }
    if (act === 'menu-restore') { closeModal(); bulkNative([id], function (cid) { return nativeCall('/crm/index/restore/', { id: cid, type: 'restor' }); }, 'بازگرداندن'); }
    if (act === 'menu-trash') { closeModal(); confirmModal('انتقال به حذف‌شده‌ها', 'این مشتری به حذف‌شده‌ها منتقل می‌شود (قابل بازگرداندن). ادامه می‌دهید؟', 'انتقال', function () { return bulkNative([id], function (cid) { return nativeCall('/crm/index/change/', { id: cid }); }, 'انتقال به حذف‌شده‌ها'); }, true); }
    if (act === 'menu-delete') { closeModal(); confirmModal('حذف نهایی', '<b>برگشت‌پذیر نیست.</b> مشتری برای همیشه حذف شود؟', 'حذف نهایی', function () { return bulkNative([id], function (cid) { return nativeCall('/crm/index/delete/', { id: cid }); }, 'حذف نهایی'); }, true); }
  });

  /* ============================== list actions ============================== */
  function toggleFavorite(id, isOn, btn) {
    if (btn) { btn.disabled = true; }
    return nativeCall('/crm/index/set_favorite/', { id: id, favorite: isOn ? 0 : 1 }).then(function () {
      toast(isOn ? 'از برگزیده‌ها حذف شد' : 'به برگزیده‌ها اضافه شد');
      state.listRows.forEach(function (r) { if (r.id === id) { r.is_fav = !isOn; } });
      if (state.client.data && state.client.data.id === id) { state.client.data.is_fav = !isOn; }
      if (state.view === 'list') { renderTable(); } else { renderClient(); }
      loadTree(true);
    }).catch(function (e) { toast(e.message, true); if (btn) { btn.disabled = false; } });
  }
  // «مطلع» (type=0) و «مسئول» (type=2): خواندن از API (assign/get, responsible/get)؛ نوشتن با همان POST هم‌مبدأ ماژول
  // بومی /crm/client/assign/ که فهرست کامل را جایگزین می‌کند (تأیید زنده ۱۴۰۵/۰۶/۱۲؛ API del/responsible بی‌اثر بود).
  var RELATION_TYPE = { assign: 0, responsible: 2 };
  function setRelation(clientId, relation, users) {
    return nativeCall('/crm/client/assign/', { client_id: clientId, type: RELATION_TYPE[relation], category: '', section: '', users: JSON.stringify(users.map(function (u) { return { id: parseInt(u.id, 10) }; })) }, 'POST');
  }
  function changeRelation(clientId, relation, userId, add) {
    return api(relation + '_get', { id: clientId }).then(function (d) {
      var users = asArray(d.users).filter(function (u) { return String(u.id) !== String(userId); });
      if (add) { users.push({ id: userId }); }
      return setRelation(clientId, relation, users);
    });
  }
  function afterRelationChange() {
    if (state.view === 'list') { if (state.list.scope === 'assign') { fetchList(); } } else { state.client.data = null; state.client.counts = null; renderClient(); }
  }
  function toggleNotify(id) {
    var known = (state.client.data && state.client.data.id === id) ? state.client.data.is_assigned : null;
    var check = known === null ? api('assign_get', { id: id }).then(function (d) { return asArray(d.users).some(function (u) { return String(u.id) === String(CFG.userId); }); }) : Promise.resolve(known);
    return check.then(function (isOn) {
      return changeRelation(id, 'assign', CFG.userId, !isOn).then(function () {
        toast(isOn ? 'از مطلعین این مشتری حذف شدید' : 'به مطلعین این مشتری اضافه شدید');
        afterRelationChange();
      });
    }).catch(function (e) { toast('مطلع: ' + e.message, true); });
  }
  function bulkNative(ids, fn, title) {
    if (!ids.length) { toast('هیچ مشتری‌ای انتخاب نشده است', true); return Promise.resolve(); }
    var okCount = 0, failCount = 0, errors = [];
    var body = openModal(title, '<div class="loading" data-role="bulk-progress">۰ از ' + fmtNum(ids.length) + '</div><div data-role="bulk-errors"></div>', [{ label: 'در حال انجام…', cls: 'secondary', onClick: function () { } }]);
    var stop = false;
    q('.modal-foot .btn', overlay).addEventListener('click', function () { stop = true; });
    q('.modal-foot .btn', overlay).textContent = 'توقف';
    var i = 0;
    function next() {
      if (i >= ids.length || stop) {
        q('[data-role="bulk-progress"]', body).className = '';
        q('[data-role="bulk-progress"]', body).innerHTML = '<b>پایان:</b> موفق ' + fmtNum(okCount) + ' — ناموفق ' + fmtNum(failCount) + (stop ? ' — متوقف شد' : '');
        q('.modal-foot .btn', overlay).textContent = 'بستن';
        q('.modal-foot .btn', overlay).onclick = closeModal;
        state.selected = {};
        fetchList(); loadTree(true);
        return Promise.resolve();
      }
      var cid = ids[i++];
      return fn(cid).then(function () { okCount++; }).catch(function (e) { failCount++; errors.push(cid + ': ' + e.message); q('[data-role="bulk-errors"]', body).innerHTML = '<div class="error-box">' + errors.map(esc).join('<br>') + '</div>'; })
        .then(function () { q('[data-role="bulk-progress"]', body).textContent = fmtNum(i) + ' از ' + fmtNum(ids.length); return next(); });
    }
    return next();
  }
  function openCategoryModal(ids) {
    if (!ids.length) { toast('مشتری انتخاب نشده است', true); return; }
    loadTree().then(function (t) {
      var opts = '';
      asArray(t.sections).forEach(function (s) { asArray(s.categories).forEach(function (c) { opts += '<option value="' + c.id + '">' + esc(s.name + ' / ' + c.name) + '</option>'; }); });
      var body = openModal('تغییر رده (' + fmtNum(ids.length) + ' مشتری)', '<div class="form-grid"><div class="fld full"><label>رده</label><select data-f="cat">' + opts + '</select></div><div class="fld full"><label>عملیات</label><select data-f="mode"><option value="add">افزودن به رده (اگر در همان بخش رده‌ای داشت، جایگزین می‌شود)</option><option value="del">حذف از رده</option></select></div></div><p class="note">قانون ماژول: هر مشتری در هر بخش فقط می‌تواند عضو یک رده باشد.</p>', [
        { label: 'اجرا', onClick: function () { var cat = q('[data-f="cat"]', body).value, mode = q('[data-f="mode"]', body).value; closeModal(); bulkNative(ids, function (cid) { return api(mode === 'add' ? 'category_add' : 'category_del', { id: cid, category_id: cat }); }, mode === 'add' ? 'افزودن به رده' : 'حذف از رده').then(function () { if (state.view === 'client') { state.client.data = null; renderClient(); } }); } },
        { label: 'لغو', cls: 'secondary' }
      ]);
    });
  }
  function openCommentModal(id, name) {
    var client = state.client.data && state.client.data.id === id ? state.client.data : null;
    // API بخش معتبر می‌خواهد؛ پیش‌فرض = بخش ردهٔ مشتری، در غیر این صورت فهرست همهٔ بخش‌ها
    var clientSections = client ? asArray(client.categories).map(function (c) { return c.section_id; }) : [];
    var sectionOpts = '';
    asArray(state.tree && state.tree.sections).forEach(function (s) { sectionOpts += '<option value="' + s.id + '"' + (clientSections.indexOf(s.id) >= 0 ? ' selected' : '') + '>' + esc(s.name) + '</option>'; });
    if (!sectionOpts) { sectionOpts = '<option value="">پیش‌فرض (بخش ردهٔ مشتری)</option>'; }
    var body = openModal('توضیحات جدید — ' + (name || ('مشتری ' + id)), '<div class="form-grid"><div class="fld full"><label class="req">متن توضیح</label><textarea data-f="comment" rows="5" placeholder="متن توضیح…"></textarea></div><div class="fld"><label>بخش</label><select data-f="section">' + sectionOpts + '</select></div></div><p class="note">توضیح از طریق API رسمی ماژول مشتری ثبت می‌شود و در تب «توضیحات» و صفحهٔ اصلی تیم‌یار دیده می‌شود.</p>', [
      { label: 'ثبت توضیح', onClick: function (btn) {
        var txt = q('[data-f="comment"]', body).value.trim();
        if (!txt) { toast('متن توضیح خالی است', true); return; }
        btn.disabled = true;
        api('comment_add', { id: id, comment: txt, section_id: q('[data-f="section"]', body).value }).then(function () { toast('توضیح ثبت شد'); closeModal(); if (state.view === 'client') { state.client.tabs.comments = null; state.client.counts = null; renderClient(); } }).catch(function (e) { btn.disabled = false; toast(e.message, true); });
      } },
      { label: 'لغو', cls: 'secondary' }
    ]);
    q('[data-f="comment"]', body).focus();
  }

  /* ============================== sms (API /api/sms/send) ============================== */
  var smsBoxesCache = null;
  function loadSmsBoxes() {
    if (smsBoxesCache) { return Promise.resolve(smsBoxesCache); }
    return api('sms_boxes').then(function (d) { smsBoxesCache = asArray(d.boxes); return smsBoxesCache; });
  }
  function smsCounterText(txt) {
    // پیامک فارسی: ۷۰ نویسه در یک بخش، بعد از آن هر بخش ۶۷ نویسه
    var n = txt.length, parts = n === 0 ? 0 : (n <= 70 ? 1 : Math.ceil(n / 67));
    return fmtNum(n) + ' نویسه — ' + fmtNum(parts) + ' بخش';
  }
  function boxOptions(boxes, selected) {
    return boxes.map(function (b) { return '<option value="' + b.id + '"' + ((selected ? String(selected) === String(b.id) : b.is_default) ? ' selected' : '') + '>' + esc(b.name) + (b.is_default ? ' (پیش‌فرض)' : '') + '</option>'; }).join('');
  }
  // نگارش و ارسال پیامک برای یک مشتری: انتخاب شماره (از شماره‌های ثبت‌شده) + صندوق + متن؛ ارسال از سرور بات با API
  function openSmsModal(id, name, mobiles, preselect) {
    var nums = asArray(mobiles).filter(Boolean);
    if (!nums.length) { toast('برای این مشتری شمارهٔ همراهی ثبت نشده است', true); return; }
    loadSmsBoxes().then(function (boxes) {
      var body = openModal('ارسال پیامک — ' + (name || ('مشتری ' + id)),
        '<div class="form-grid">' +
        '<div class="fld"><label class="req">شماره گیرنده</label><select data-f="mobile">' + nums.map(function (m) { return '<option value="' + esc(m) + '"' + (m === preselect ? ' selected' : '') + '>' + esc(m) + '</option>'; }).join('') + '</select></div>' +
        '<div class="fld"><label>صندوق پیامک</label><select data-f="box">' + boxOptions(boxes, store('sms_box')) + '</select></div>' +
        '<div class="fld full"><label class="req">متن پیامک</label><textarea data-f="content" rows="5" maxlength="1000" placeholder="متن پیامک…"></textarea><div class="note" data-f="counter">۰ نویسه</div></div>' +
        '</div><p class="note">ارسال از طریق API رسمی پیامک تیم‌یار (/api/sms/send) انجام می‌شود و در تب «پیامک» مشتری و صندوق انتخابی ثبت می‌شود.</p>',
        [{ label: 'ارسال پیامک', onClick: function (btn) {
          var content = q('[data-f="content"]', body).value.trim();
          if (!content) { toast('متن پیامک خالی است', true); return; }
          var mobile = q('[data-f="mobile"]', body).value, box = q('[data-f="box"]', body).value;
          store('sms_box', box);
          btn.disabled = true; btn.textContent = 'در حال ارسال…';
          api('sms_send', { id: id, mobile: mobile, box_id: box, content: content }).then(function (d) {
            toast('پیامک به ' + d.mobile + ' ارسال شد' + (asArray(d.message_ids).length ? ' (شناسهٔ ' + d.message_ids.join('، ') + ')' : ''));
            closeModal();
            if (state.view === 'client' && state.client.id === id) { state.client.tabs.sms = null; state.client.counts = null; if (state.client.tab === 'sms') { renderPane(); } }
          }).catch(function (e) { btn.disabled = false; btn.textContent = 'ارسال پیامک'; toast(e.message, true); });
        } }, { label: 'لغو', cls: 'secondary' }]);
      var ta = q('[data-f="content"]', body), counter = q('[data-f="counter"]', body);
      ta.addEventListener('input', function () { counter.textContent = smsCounterText(ta.value); });
      ta.focus();
    }).catch(function (e) { toast('صندوق‌های پیامک: ' + e.message, true); });
  }
  // پیامک گروهی به مشتریان انتخاب‌شدهٔ لیست: یک متن، برای هر مشتری جدا ارسال و شمارش موفق/ناموفق (اولین شمارهٔ هر مشتری)
  function openBulkSmsModal(ids) {
    if (!ids.length) { toast('مشتری‌ای انتخاب نشده است', true); return; }
    loadSmsBoxes().then(function (boxes) {
      var body = openModal('پیامک گروهی به ' + fmtNum(ids.length) + ' مشتری',
        '<div class="form-grid"><div class="fld"><label>صندوق پیامک</label><select data-f="box">' + boxOptions(boxes, store('sms_box')) + '</select></div>' +
        '<div class="fld full"><label class="req">متن پیامک</label><textarea data-f="content" rows="5" maxlength="1000"></textarea><div class="note" data-f="counter">۰ نویسه</div></div></div>' +
        '<p class="note">برای هر مشتری به اولین شمارهٔ همراه ثبت‌شده ارسال می‌شود؛ مشتریان بدون شماره «ناموفق» شمرده می‌شوند. هر ارسال جدا اعتبارسنجی و شمارش می‌شود و دکمهٔ توقف دارد.</p>',
        [{ label: 'ارسال به همه', onClick: function () {
          var content = q('[data-f="content"]', body).value.trim(), box = q('[data-f="box"]', body).value;
          if (!content) { toast('متن پیامک خالی است', true); return; }
          store('sms_box', box);
          closeModal();
          bulkNative(ids, function (cid) { return api('sms_send', { id: cid, box_id: box, content: content }); }, 'ارسال پیامک گروهی');
        } }, { label: 'لغو', cls: 'secondary' }]);
      var ta = q('[data-f="content"]', body), counter = q('[data-f="counter"]', body);
      ta.addEventListener('input', function () { counter.textContent = smsCounterText(ta.value); });
      ta.focus();
    }).catch(function (e) { toast('صندوق‌های پیامک: ' + e.message, true); });
  }

  /* ============================== email (API /api/email/emailmsgadd) ============================== */
  var emailBoxesCache = null;
  function loadEmailBoxes() {
    if (emailBoxesCache) { return Promise.resolve(emailBoxesCache); }
    return api('email_boxes').then(function (d) { emailBoxesCache = asArray(d.boxes); return emailBoxesCache; });
  }
  function emailBoxOptions(boxes, selected) {
    var opts = '<option value="">صندوق پیش‌فرض تیم‌یار</option>';
    return opts + boxes.map(function (b) { return '<option value="' + b.id + '"' + ((selected ? String(selected) === String(b.id) : b.is_default) ? ' selected' : '') + '>' + esc(b.name || b.email) + ' — ' + esc(b.email) + (b.is_default ? ' (پیش‌فرض)' : '') + '</option>'; }).join('');
  }
  function emailFormHtml(boxes, addressesHtml) {
    return '<div class="form-grid">' + (addressesHtml || '') +
      '<div class="fld"><label>صندوق فرستنده</label><select data-f="box">' + emailBoxOptions(boxes, store('email_box')) + '</select></div>' +
      '<div class="fld full"><label class="req">موضوع</label><input type="text" data-f="subject" maxlength="200"></div>' +
      '<div class="fld full"><label class="req">متن ایمیل</label><textarea data-f="content" rows="8" placeholder="متن ایمیل… (متن ساده؛ خطوط جدید حفظ می‌شوند)"></textarea></div></div>';
  }
  // نگارش و ارسال ایمیل برای یک مشتری: گیرنده از ایمیل‌های ثبت‌شده، صندوق شخصی فرستنده، موضوع، متن؛ ارسال از سرور بات با API
  function openEmailModal(id, name, emails, preselect) {
    var addrs = asArray(emails).filter(Boolean);
    if (!addrs.length) { toast('برای این مشتری ایمیلی ثبت نشده است', true); return; }
    loadEmailBoxes().then(function (boxes) {
      if (!boxes.length) { toast('برای شما صندوق ایمیلی در ماژول پست تعریف نشده؛ ارسال با صندوق پیش‌فرض تیم‌یار انجام می‌شود', false); }
      var body = openModal('ارسال ایمیل — ' + (name || ('مشتری ' + id)), emailFormHtml(boxes,
        '<div class="fld"><label class="req">گیرنده</label><select data-f="address">' + addrs.map(function (a) { return '<option value="' + esc(a) + '"' + (a === preselect ? ' selected' : '') + '>' + esc(a) + '</option>'; }).join('') + '</select></div>') +
        '<p class="note">ارسال از طریق API رسمی پست تیم‌یار (/api/email/emailmsgadd) انجام می‌شود و ایمیل در صندوق فرستنده ثبت می‌شود.</p>',
        [{ label: 'ارسال ایمیل', onClick: function (btn) {
          var subject = q('[data-f="subject"]', body).value.trim(), content = q('[data-f="content"]', body).value.trim();
          if (!subject) { toast('موضوع ایمیل خالی است', true); return; }
          if (!content) { toast('متن ایمیل خالی است', true); return; }
          var box = q('[data-f="box"]', body).value; store('email_box', box);
          btn.disabled = true; btn.textContent = 'در حال ارسال…';
          api('email_send', { id: id, address: q('[data-f="address"]', body).value, box_id: box || undefined, subject: subject, content: content }).then(function (d) {
            toast('ایمیل به ' + d.address + ' ارسال شد' + (d.message_id ? ' (شناسهٔ ' + d.message_id + ')' : ''));
            closeModal();
            if (state.view === 'client' && state.client.id === id) { state.client.tabs.emails = null; state.client.counts = null; if (state.client.tab === 'emails') { renderPane(); } }
          }).catch(function (e) { btn.disabled = false; btn.textContent = 'ارسال ایمیل'; toast(e.message, true); });
        } }, { label: 'لغو', cls: 'secondary' }], { wide: true });
      q('[data-f="subject"]', body).focus();
    }).catch(function (e) { toast('صندوق‌های ایمیل: ' + e.message, true); });
  }
  // ایمیل گروهی به مشتریان انتخاب‌شدهٔ لیست (اولین ایمیل هر مشتری)؛ ارسال جدا و شمارش موفق/ناموفق
  function openBulkEmailModal(ids) {
    if (!ids.length) { toast('مشتری‌ای انتخاب نشده است', true); return; }
    loadEmailBoxes().then(function (boxes) {
      var body = openModal('ایمیل گروهی به ' + fmtNum(ids.length) + ' مشتری', emailFormHtml(boxes, '') +
        '<p class="note">برای هر مشتری به اولین ایمیل ثبت‌شده ارسال می‌شود؛ مشتریان بدون ایمیل «ناموفق» شمرده می‌شوند. دکمهٔ توقف دارد.</p>',
        [{ label: 'ارسال به همه', onClick: function () {
          var subject = q('[data-f="subject"]', body).value.trim(), content = q('[data-f="content"]', body).value.trim(), box = q('[data-f="box"]', body).value;
          if (!subject || !content) { toast('موضوع و متن الزامی است', true); return; }
          store('email_box', box); closeModal();
          bulkNative(ids, function (cid) { return api('email_send', { id: cid, box_id: box || undefined, subject: subject, content: content }); }, 'ارسال ایمیل گروهی');
        } }, { label: 'لغو', cls: 'secondary' }], { wide: true });
      q('[data-f="subject"]', body).focus();
    }).catch(function (e) { toast('صندوق‌های ایمیل: ' + e.message, true); });
  }

  /* ============================== excel export ============================== */
  function exportRows(rows, name) {
    if (!rows.length) { toast('ردیفی برای خروجی وجود ندارد', true); return; }
    var cols = visibleColumns();
    var html = '<html xmlns:o="urn:schemas-microsoft-com:office:office" xmlns:x="urn:schemas-microsoft-com:office:excel"><head><meta charset="UTF-8"></head><body><table border="1" dir="rtl"><tr>' + cols.map(function (c) { return '<th>' + esc(c.label) + '</th>'; }).join('') + '</tr>';
    rows.forEach(function (r) {
      html += '<tr>' + cols.map(function (c) {
        var v = r[c.key]; if (c.key === 'type') { v = r.type_label; } if (c.key === 'confirm') { v = r.confirm ? 'تأیید شده' : 'تأیید نشده'; } if (c.key === 'notify') { v = r.notify_count; }
        if (c.key === 'has_folder') { v = r.has_folder ? 'دارد' : 'ندارد'; } if (c.key === 'balance') { v = r.balance_fmt; } if (c.key === 'assigned') { v = asArray(r.assigned).join('، '); }
        return '<td style="mso-number-format:\\@">' + esc(dash(v)) + '</td>';
      }).join('') + '</tr>';
    });
    html += '</table></body></html>';
    var blob = new Blob(['\uFEFF', html], { type: 'application/vnd.ms-excel;charset=utf-8' });
    var a = document.createElement('a');
    a.href = URL.createObjectURL(blob);
    a.download = (name || 'crm_customers') + '_' + new Date().toISOString().slice(0, 10) + '.xls';
    document.body.appendChild(a); a.click(); document.body.removeChild(a);
    setTimeout(function () { URL.revokeObjectURL(a.href); }, 2000);
  }
  function exportExcel() {
    if (state.view === 'client' && state.client.data) { exportClientTab(); return; }
    toast('در حال آماده‌سازی خروجی…');
    api('export', listParams()).then(function (d) {
      exportRows(asArray(d.rows), 'crm_customers');
      if (d.truncated) { toast('خروجی به ' + fmtNum(d.max_rows) + ' ردیف اول محدود شد — فیلتر را دقیق‌تر کنید', true); }
    }).catch(function (e) { toast(e.message, true); });
  }
  function exportClientTab() {
    var tab = state.client.tab, rows = state.client.tabs[tab];
    if (!rows || !rows.length) { toast('این تب داده‌ای برای خروجی ندارد', true); return; }
    var keys = Object.keys(rows[0]).filter(function (k) { return typeof rows[0][k] !== 'object' && k !== 'url'; });
    var html = '<html><head><meta charset="UTF-8"></head><body><table border="1" dir="rtl"><tr>' + keys.map(function (k) { return '<th>' + esc(k) + '</th>'; }).join('') + '</tr>' +
      rows.map(function (r) { return '<tr>' + keys.map(function (k) { return '<td style="mso-number-format:\\@">' + esc(dash(r[k])) + '</td>'; }).join('') + '</tr>'; }).join('') + '</table></body></html>';
    var blob = new Blob(['\uFEFF', html], { type: 'application/vnd.ms-excel;charset=utf-8' });
    var a = document.createElement('a'); a.href = URL.createObjectURL(blob); a.download = 'crm_' + state.client.id + '_' + tab + '.xls'; document.body.appendChild(a); a.click(); document.body.removeChild(a);
  }

  /* ============================== client view ============================== */
  var CLIENT_TABS = [
    { key: 'overview', label: 'بررسی' }, { key: 'contacts', label: 'رابط‌ها', count: 'contacts' }, { key: 'categories', label: 'رده / بخش' },
    { key: 'notify', label: 'مطلع', count: 'notify' }, { key: 'sales', label: 'فروش', count: 'sales' }, { key: 'purchase', label: 'خرید', count: 'purchase' },
    { key: 'todo', label: 'اقدام', count: 'todo' }, { key: 'comments', label: 'توضیحات', count: 'comments' }, { key: 'documents', label: 'اسناد', count: 'documents' },
    { key: 'emails', label: 'ایمیل', count: 'emails' }, { key: 'sms', label: 'پیامک', count: 'sms' }, { key: 'chats', label: 'گفتگو', count: 'chats' },
    { key: 'events', label: 'رویدادها', count: 'events' }, { key: 'polls', label: 'نظرسنجی', count: 'polls' }, { key: 'projects', label: 'پروژه', count: 'projects' },
    { key: 'calls', label: 'فایل‌های صوتی', count: 'calls' }, { key: 'history', label: 'تاریخچه', count: 'history' }, { key: 'tools', label: 'ابزارها' }
  ];
  var DATA_TABS = ['sales', 'purchase', 'todo', 'comments', 'documents', 'emails', 'sms', 'chats', 'events', 'polls', 'projects', 'calls', 'history'];

  function renderClient() {
    var C = state.client;
    loadTree().then(renderSide);
    if (!C.data) {
      mainEl.innerHTML = '<div class="panel"><div class="loading">بارگذاری پروفایل مشتری…</div></div>';
      crumbEl.innerHTML = '<a href="#/list">لیست مشتریان</a> › مشتری ' + esc(C.id);
      api('client', { id: C.id }).then(function (d) {
        if (state.client.id !== C.id) { return; }
        state.client.data = normalizeClient(d.client);
        renderClient();
        api('counts', { id: C.id }).then(function (cd) { if (state.client.id === C.id) { state.client.counts = cd; renderClientCounts(); } }).catch(function (e) { toast('شمارش تب‌ها: ' + e.message, true); });
      }).catch(function (e) { mainEl.innerHTML = '<div class="error-box">' + esc(e.message) + ' — <a href="#/list">بازگشت به لیست</a></div>'; });
      return;
    }
    var c = C.data;
    crumbEl.innerHTML = '<a href="#/list">لیست مشتریان</a> › ' + esc(c.full_name);
    var mobile = (c.mobiles[0] || {}).value || '';
    var email = (c.emails[0] || {}).value || '';
    var html = '<div class="hero"><div class="avatar">' + esc(initials(c.full_name)) + '</div><div>' +
      '<h2>' + esc(c.full_name) + ' <span class="badge' + (c.type === 4 ? ' dark' : '') + '">' + esc(c.type_label) + '</span>' +
      (c.confirm ? '' : ' <span class="badge">تأیید نشده</span>') + (c.deleted ? ' <span class="badge dark">حذف‌شده</span>' : '') +
      asArray(c.categories).map(function (k) { return ' <span class="badge outline">' + esc(k.section_name + ' / ' + k.name) + '</span>'; }).join('') + '</h2>' +
      '<div class="meta">' +
      '<span>شناسه: <b>' + esc(c.id) + '</b></span>' +
      '<span>تلفن همراه: <b>' + (mobile ? '<a href="tel:' + esc(mobile) + '">' + esc(mobile) + '</a>' : '—') + '</b>' + (c.mobiles.length > 1 ? ' <span class="note">(+' + (c.mobiles.length - 1) + ')</span>' : '') + '</span>' +
      '<span>ایمیل: <b>' + (email ? '<a href="mailto:' + esc(email) + '">' + esc(email) + '</a>' : '—') + '</b></span>' +
      '<span>' + (c.type === 4 ? 'شناسهٔ ملی' : 'کد ملی') + ': <b>' + esc(dash((c.national_codes[0] || {}).value)) + '</b></span>' +
      (c.company ? '<span>کسب‌وکار: <b>' + esc(c.company) + '</b></span>' : '') +
      '<span>ایجاد: <b>' + esc(dash(c.created)) + '</b> توسط <b>' + esc(dash(c.author)) + '</b></span>' +
      '<span>آخرین تغییر: <b>' + esc(dash(c.modified)) + '</b></span>' +
      (c.comment ? '<span>توضیحات: <b>' + esc(c.comment) + '</b></span>' : '') +
      '</div></div>' +
      '<div class="hero-actions"><div class="row">' +
      '<button type="button" class="btn small' + (c.is_fav ? '' : ' secondary') + '" data-act="fav" data-id="' + esc(c.id) + '" data-on="' + (c.is_fav ? 1 : 0) + '">★ ' + (c.is_fav ? 'برگزیده' : 'برگزیده کردن') + '</button>' +
      '<button type="button" class="btn small' + (c.is_assigned ? '' : ' secondary') + '" data-act="notify" data-id="' + esc(c.id) + '">🔔 ' + (c.is_assigned ? 'مطلع هستم' : 'مطلع شدن') + '</button>' +
      '<a class="btn small secondary" href="#/edit/' + esc(c.id) + '">✎ ویرایش</a>' +
      '<button type="button" class="btn small secondary" data-act="comment" data-id="' + esc(c.id) + '" data-name="' + esc(c.full_name) + '">✎+ توضیحات جدید</button>' +
      (hasSiteId(c.comment) ? '<button type="button" class="btn small" data-act="site" data-id="' + esc(c.id) + '" data-name="' + esc(c.full_name) + '" title="اجرای بات نمایش مشتری در سایت">🌐 نمایش در سایت</button>' : '<button type="button" class="btn small secondary" disabled title="در توضیحات این مشتری «شناسه سایت» ثبت نشده است">🌐 نمایش در سایت</button>') +
      '</div><div class="row">' +
      (mobile ? '<a class="btn small secondary" href="tel:' + esc(mobile) + '">☎ تماس</a><button type="button" class="btn small secondary" data-act="sms" data-id="' + esc(c.id) + '" data-name="' + esc(c.full_name) + '">✉ پیامک</button>' : '') +
      (email ? '<button type="button" class="btn small secondary" data-act="email" data-id="' + esc(c.id) + '" data-name="' + esc(c.full_name) + '">@ ایمیل</button>' : '') +
      '<a class="btn small secondary" href="' + esc(c.links.events) + '" target="_blank" rel="noopener">📅 رویداد جدید ↗</a>' +
      '<a class="btn small secondary" href="' + esc(c.links.todo) + '" target="_blank" rel="noopener">☑ اقدام جدید ↗</a>' +
      '</div><div class="row">' +
      '<a class="btn small secondary" href="' + esc(c.links.native_edit) + '" target="_blank" rel="noopener">تیم‌یار ↗</a>' +
      '<a class="btn small secondary" href="' + esc(c.links.print) + '" target="_blank" rel="noopener">چاپ</a>' +
      '<a class="btn small secondary" href="' + esc(c.links.envelope) + '" target="_blank" rel="noopener">پرینت پاکتی</a>' +
      '<button type="button" class="btn small secondary" data-act="share" data-id="' + esc(c.id) + '">اشتراک</button>' +
      '<button type="button" class="btn small gray" data-act="more" data-id="' + esc(c.id) + '">⋯</button>' +
      '</div></div></div>';
    html += '<div class="kpis" data-role="kpis"></div>';
    html += '<div class="tabs" data-role="tabs">' + CLIENT_TABS.map(function (t) {
      return '<button type="button" class="tab' + (t.key === C.tab ? ' active' : '') + '" data-act="ctab" data-tab="' + t.key + '">' + t.label + (t.count ? ' <span class="count" data-count="' + t.count + '">…</span>' : '') + '</button>';
    }).join('') + '</div>';
    html += '<div class="panel" data-role="pane"></div>';
    mainEl.innerHTML = html;
    renderClientCounts();
    renderPane();
  }
  function renderClientCounts() {
    var cd = state.client.counts;
    var kp = q('[data-role="kpis"]');
    if (!kp) { return; }
    if (!cd) { kp.innerHTML = '<div class="kpi"><div class="lbl">شاخص‌ها</div><div class="val loading" style="padding:0"></div></div>'; return; }
    var k = cd.kpi, n = cd.counts;
    // «مطلعین» = فهرست assign از API (نه crm_notify که اعلان‌گیران رده است)
    n.notify = state.client.data ? asArray(state.client.data.assigned).length : n.notify;
    kp.innerHTML =
      '<div class="kpi accent"><div class="lbl">فروش خالص</div><div class="val">' + esc(k.net_sales_fmt) + '</div></div>' +
      '<div class="kpi"><div class="lbl">فاکتورهای فروش</div><div class="val">' + fmtNum(n.sales) + '</div></div>' +
      '<div class="kpi"><div class="lbl">برگشت از فروش</div><div class="val">' + esc(k.returns_total_fmt) + '</div></div>' +
      '<div class="kpi"><div class="lbl">آخرین فاکتور</div><div class="val">' + esc(k.last_invoice) + '</div></div>' +
      '<div class="kpi"><div class="lbl">اقدام‌های باز</div><div class="val">' + fmtNum(k.open_todos) + ' <span class="note">از ' + fmtNum(n.todo) + '</span></div></div>' +
      '<div class="kpi"><div class="lbl">رویدادها</div><div class="val">' + fmtNum(n.events) + '</div></div>' +
      '<div class="kpi"><div class="lbl">توضیحات</div><div class="val">' + fmtNum(n.comments) + '</div></div>' +
      '<div class="kpi"><div class="lbl">مطلعین</div><div class="val">' + fmtNum(n.notify) + '</div></div>';
    qa('[data-count]').forEach(function (s) { var key = s.getAttribute('data-count'); s.textContent = fmtNum(n[key] || 0); });
  }
  function onClientClick(act, a, e) {
    var C = state.client, id = a.getAttribute('data-id') || C.id;
    switch (act) {
      case 'ctab': go('#/client/' + C.id + '/' + a.getAttribute('data-tab')); break;
      case 'notify': toggleNotify(id); break;
      case 'share': copyText(location.href.split('#')[0] + '#/client/' + id); break;
      case 'more': showRowMenu(id); break;
      case 'reload-tab': C.tabs[C.tab] = null; renderPane(); break;
      case 'sub-tab': C.subTab = a.getAttribute('data-sub'); renderPane(); break;
      case 'contact-add': openContactModal(); break;
      case 'contact-del': confirmModal('حذف رابط', 'رابط «' + esc(a.getAttribute('data-name')) + '» از این مشتری حذف شود؟', 'حذف', function () { return api('contact_del', { id: C.id, contact_id: a.getAttribute('data-cid'), type: a.getAttribute('data-type') }).then(function () { toast('رابط حذف شد'); C.data = null; renderClient(); }); }, true); break;
      case 'cat-add': openCategoryModal([C.id]); break;
      case 'cat-del': confirmModal('حذف از رده', 'مشتری از رده «' + esc(a.getAttribute('data-name')) + '» حذف شود؟', 'حذف', function () { return api('category_del', { id: C.id, category_id: a.getAttribute('data-cat') }).then(function () { toast('از رده حذف شد'); C.data = null; renderClient(); loadTree(true); }); }, true); break;
      case 'notify-add': openUserPicker('افزودن مطلع', function (u) { return changeRelation(C.id, 'assign', u.id, true).then(function () { toast(u.name + ' مطلع شد'); afterRelationChange(); }); }); break;
      case 'notify-del': confirmModal('حذف مطلع', '«' + esc(a.getAttribute('data-name')) + '» از مطلعین حذف شود؟', 'حذف', function () { return changeRelation(C.id, 'assign', a.getAttribute('data-uid'), false).then(function () { toast('حذف شد'); afterRelationChange(); }); }, true); break;
      case 'resp-add': openUserPicker('افزودن مسئول', function (u) { return changeRelation(C.id, 'responsible', u.id, true).then(function () { toast(u.name + ' مسئول شد'); afterRelationChange(); }); }); break;
      case 'resp-del': confirmModal('حذف مسئول', '«' + esc(a.getAttribute('data-name')) + '» از مسئولین حذف شود؟', 'حذف', function () { return changeRelation(C.id, 'responsible', a.getAttribute('data-uid'), false).then(function () { toast('حذف شد'); afterRelationChange(); }); }, true); break;
      case 'api-raw': api('api_get', { id: C.id }).then(function (d) { openModal('پاسخ /api/client/get', '<pre style="direction:ltr;text-align:left;white-space:pre-wrap;font-size:14px">' + esc(JSON.stringify(d.api, null, 2)) + '</pre>', null, { wide: true }); }).catch(function (e2) { toast(e2.message, true); }); break;
      default: break;
    }
  }
  function onClientChange(t) { /* رزرو برای فرم‌های داخل تب‌ها */ }

  function renderPane() {
    var C = state.client, c = C.data, pane = q('[data-role="pane"]');
    if (!pane || !c) { return; }
    qa('[data-act="ctab"]').forEach(function (b) { b.classList.toggle('active', b.getAttribute('data-tab') === C.tab); });
    if (C.tab === 'overview') { pane.innerHTML = overviewHtml(c); return; }
    if (C.tab === 'contacts') { pane.innerHTML = contactsHtml(c); return; }
    if (C.tab === 'categories') { pane.innerHTML = categoriesHtml(c); return; }
    if (C.tab === 'notify') { pane.innerHTML = notifyHtml(c); return; }
    if (C.tab === 'tools') { pane.innerHTML = toolsHtml(c); return; }
    if (DATA_TABS.indexOf(C.tab) >= 0) {
      if (C.tabs[C.tab]) { pane.innerHTML = dataTabHtml(C.tab, C.tabs[C.tab], c); return; }
      pane.innerHTML = '<div class="loading">بارگذاری…</div>';
      var tab = C.tab;
      api('tab', { id: C.id, tab: tab }).then(function (d) { if (state.client.id === C.id) { C.tabs[tab] = asArray(d.rows); if (C.tab === tab) { renderPane(); } } })
        .catch(function (e) { if (C.tab === tab) { pane.innerHTML = '<div class="error-box">' + esc(e.message) + '</div>'; } });
      return;
    }
    pane.innerHTML = '<div class="empty">تب ناشناخته</div>';
  }
  function dl(pairs) {
    return '<div class="dl">' + pairs.filter(function (p) { return p; }).map(function (p) { return '<div class="f"><span class="k">' + esc(p[0]) + '</span><span class="v">' + (p[2] ? p[1] : esc(dash(p[1]))) + '</span></div>'; }).join('') + '</div>';
  }
  function overviewHtml(c) {
    var html = '<div class="section-title">اطلاعات عمومی</div>';
    var pairs = [['نام', c.name], ['نام خانوادگی', c.surname], ['نوع', c.type_label], ['جنسیت', c.gender_label], ['نام پدر', c.patronymic], ['تاریخ تولد', c.birthday], ['محل تولد', c.birthplace],
      ['شماره شناسنامه', c.identity_no], ['سریال شناسنامه', c.identity_serial], ['صدور شناسنامه', c.place_of_issue], ['تاریخ صدور', c.date_of_issue], ['ملیت', c.nationality], ['شماره پاسپورت', c.passport_no], ['زبان', c.language], ['برچسب', c.lable]];
    if (c.type === 4) { pairs = pairs.concat([['نام کسب‌وکار', c.company], ['شناسه ملی / کد اقتصادی', c.tin], ['کد ملی مدیرعامل', c.kpp], ['مدیرعامل', c.account_manager], ['شماره ثبت', c.reg_number], ['نوع شخصیت حقوقی', c.personality_type], ['پیشه', c.industry], ['تعداد پرسنل', c.number_personnel], ['موضوع/حوزه فعالیت', c.issue_activity], ['شماره پروانه کسب', c.property_code], ['تاریخ پروانه', c.property_date]]); }
    else { pairs = pairs.concat([['شرکت', c.company], ['شغل', c.job], ['کد اقتصادی', c.tin]]); }
    pairs.push(['وب‌سایت', c.website ? '<a href="' + esc(/^https?:/.test(c.website) ? c.website : 'http://' + c.website) + '" target="_blank" rel="noopener">' + esc(c.website) + '</a>' : '', true]);
    pairs.push(['توضیحات', c.comment]); pairs.push(['شناسهٔ درون‌ریزی', c.import_id]); pairs.push(['دامنه', c.domain]);
    html += dl(pairs);
    html += '<div class="section-title">اطلاعات تماس</div><div class="cards">';
    html += '<div class="card"><div class="t">تلفن همراه</div>' + (c.mobiles.length ? c.mobiles.map(function (m) { return '<div><a href="tel:' + esc(m.value) + '">' + esc(m.value) + '</a> <button type="button" class="icon-btn" data-act="sms" data-id="' + esc(c.id) + '" data-name="' + esc(c.full_name) + '" data-mobile="' + esc(m.value) + '">پیامک</button></div>'; }).join('') : '<div class="s">—</div>') + '</div>';
    html += '<div class="card"><div class="t">ایمیل</div>' + (c.emails.length ? c.emails.map(function (m) { return '<div><a href="mailto:' + esc(m.value) + '">' + esc(m.value) + '</a> <button type="button" class="icon-btn" data-act="email" data-id="' + esc(c.id) + '" data-name="' + esc(c.full_name) + '" data-address="' + esc(m.value) + '">ارسال</button>' + (m.verified ? ' <span class="badge accent">تأیید شده</span>' : '') + '</div>'; }).join('') : '<div class="s">—</div>') + '</div>';
    html += '<div class="card"><div class="t">تلفن‌ها</div>' + (c.phones.length ? c.phones.map(function (m) { return '<div>' + esc(m.type_label) + ': <a href="tel:' + esc(m.value) + '">' + esc(m.value) + '</a></div>'; }).join('') : '<div class="s">—</div>') + '</div>';
    html += '<div class="card"><div class="t">' + (c.type === 4 ? 'شناسهٔ ملی' : 'کد ملی') + '</div>' + (c.national_codes.length ? c.national_codes.map(function (m) { return '<div>' + esc(m.value) + '</div>'; }).join('') : '<div class="s">—</div>') + '</div>';
    html += '</div>';
    html += '<div class="section-title">آدرس‌ها</div><div class="cards">';
    asArray(c.profile_addresses).forEach(function (a) { if (!a.address && !a.city && !a.state) { return; } html += '<div class="card"><div class="t">' + esc(a.type_label) + '</div><div>' + esc([a.state, a.city].filter(Boolean).join(' / ')) + '</div><div>' + esc(a.address) + '</div><div class="s">کد پستی: ' + esc(dash(a.zip_code)) + (a.loc_x ? ' — <a target="_blank" rel="noopener" href="https://www.google.com/maps?q=' + esc(a.loc_y + ',' + a.loc_x) + '">نقشه</a>' : '') + '</div></div>'; });
    asArray(c.crm_addresses).forEach(function (a) { html += '<div class="card"><div class="t">' + esc(a.title || 'آدرس') + (a.confirm ? ' <span class="badge accent">تأیید</span>' : '') + '</div><div>' + esc([a.province || a.state, a.city].filter(Boolean).join(' / ')) + '</div><div>' + esc(a.address) + '</div><div class="s">' + [a.zip_code && ('کد پستی: ' + a.zip_code), a.home_phone && ('تلفن: ' + a.home_phone), a.work_phone && ('محل کار: ' + a.work_phone), a.mobile && ('همراه: ' + a.mobile), a.fax && ('فکس: ' + a.fax)].filter(Boolean).map(esc).join(' — ') + '</div>' + (a.comment ? '<div class="s">' + esc(a.comment) + '</div>' : '') + '</div>'; });
    if (!asArray(c.profile_addresses).filter(function (a) { return a.address || a.city; }).length && !c.crm_addresses.length) { html += '<div class="empty">آدرسی ثبت نشده است.</div>'; }
    html += '</div>';
    html += '<div class="section-title">حسابداری (طرف حساب)</div>';
    html += c.accounting.length ? '<div class="table-wrap"><table class="grid"><thead><tr><th class="nosort">سازمان</th><th class="nosort">کد مشتری</th><th class="nosort">کد حساب</th><th class="nosort">مانده حساب</th></tr></thead><tbody>' + c.accounting.map(function (a) { return '<tr><td>' + esc(a.org_name) + '</td><td>' + esc(dash(a.code)) + '</td><td>' + esc(dash(a.account_code)) + '</td><td>' + esc(a.balance_fmt) + '</td></tr>'; }).join('') + '</tbody></table></div>' : '<div class="empty">برای این مشتری طرف حساب حسابداری ایجاد نشده است.</div>';
    if (c.bank_accounts.length || c.cards.length) {
      html += '<div class="section-title">اطلاعات حساب و کارت بانکی</div><div class="cards">';
      c.bank_accounts.forEach(function (b) { html += '<div class="card"><div class="t">' + esc(b.bank || 'حساب بانکی') + '</div><div>شماره حساب: ' + esc(dash(b.account_number)) + '</div><div>شبا: ' + esc(dash(b.shaba || b.iban)) + '</div><div class="s">' + esc([b.branch, b.city, b.swift].filter(Boolean).join(' — ')) + '</div></div>'; });
      c.cards.forEach(function (b) { html += '<div class="card"><div class="t">کارت ' + esc(b.bank || '') + '</div><div>' + esc(dash(b.card_number)) + '</div><div class="s">' + esc([b.holder, b.expiry && ('انقضا ' + b.expiry), b.card_type].filter(Boolean).join(' — ')) + '</div></div>'; });
      html += '</div>';
    }
    if (c.custom_fields.length) { html += '<div class="section-title">فیلدهای شخصی</div>' + dl(c.custom_fields.map(function (f) { return [f.name, f.value]; })); }
    if (c.family.length) { html += '<div class="section-title">خانواده</div><div class="table-wrap"><table class="grid"><thead><tr><th class="nosort">نام</th><th class="nosort">نسبت</th><th class="nosort">کد ملی</th><th class="nosort">تاریخ تولد</th><th class="nosort">تلفن</th><th class="nosort">شغل</th></tr></thead><tbody>' + c.family.map(function (f) { return '<tr><td>' + esc(f.name) + '</td><td>' + esc(dash(f.relation)) + '</td><td>' + esc(dash(f.national_code)) + '</td><td>' + esc(dash(f.birth_date)) + '</td><td>' + esc(dash(f.phone)) + '</td><td>' + esc(dash(f.job)) + '</td></tr>'; }).join('') + '</tbody></table></div>'; }
    html += '<div class="section-title">سیستم</div>' + dl([['ایجادکننده', c.author], ['تاریخ ایجاد', c.created], ['آخرین تغییر', c.modified], ['تغییردهنده', c.modifier], ['وضعیت تأیید', c.confirm ? 'تأیید شده' : 'تأیید نشده'], ['پوشهٔ اسناد', c.folder_id > 0 ? ('#' + c.folder_id) : 'ایجاد نشده']]);
    return html;
  }
  function contactsHtml(c) {
    var html = '<div class="pane-head"><div class="note">رابط = شخص مرتبط با این مشتری (مشتری تیم‌یار، غیر تیم‌یاری یا معرف). ثبت دوطرفه برای رابط تیم‌یاری.</div><div class="links"><button type="button" class="btn small" data-act="contact-add">＋ افزودن رابط</button></div></div>';
    if (!c.contacts.length) { return html + '<div class="empty">رابطی ثبت نشده است.</div>'; }
    html += '<div class="table-wrap"><table class="grid"><thead><tr><th class="nosort">نام</th><th class="nosort">نوع</th><th class="nosort">سمت</th><th class="nosort">تلفن</th><th class="nosort">توضیح</th><th class="nosort">عملیات</th></tr></thead><tbody>';
    c.contacts.forEach(function (k) {
      html += '<tr><td class="name">' + (k.type === 2 ? esc(k.name) : '<a href="#/client/' + esc(k.contact_id) + '">' + esc(k.name) + '</a>') + '</td><td><span class="badge">' + esc(k.type_label) + '</span></td><td>' + esc(dash(k.post)) + '</td><td>' + (k.phone ? '<a href="tel:' + esc(k.phone) + '">' + esc(k.phone) + '</a>' : '—') + '</td><td class="right">' + esc(dash(k.description)) + '</td><td><button type="button" class="icon-btn" data-act="contact-del" data-cid="' + esc(k.contact_id) + '" data-type="' + k.type + '" data-name="' + esc(k.name) + '">حذف</button></td></tr>';
    });
    return html + '</tbody></table></div>';
  }
  function categoriesHtml(c) {
    var html = '<div class="pane-head"><div class="note">هر مشتری در هر بخش فقط عضو یک رده است؛ افزودن رده در همان بخش، ردهٔ قبلی را جایگزین می‌کند.</div><div class="links"><button type="button" class="btn small" data-act="cat-add">＋ افزودن / تغییر رده</button></div></div>';
    if (!c.categories.length) { return html + '<div class="empty">این مشتری در هیچ رده‌ای عضو نیست («بدون رده»).</div>'; }
    html += '<div class="cards">' + c.categories.map(function (k) { return '<div class="card"><div class="t">' + esc(k.name) + ' <button type="button" class="icon-btn" data-act="cat-del" data-cat="' + esc(k.id) + '" data-name="' + esc(k.name) + '">حذف</button></div><div class="s">بخش: ' + esc(k.section_name) + '</div><div class="s"><a href="' + listHash({ scope: 'all', category_id: k.id, section_id: k.section_id, q: '', adv: [], page: 1 }) + '">مشاهدهٔ هم‌رده‌ها</a></div></div>'; }).join('') + '</div>';
    return html;
  }
  function userCards(list, delAct, emptyText) {
    if (!list.length) { return '<div class="empty">' + emptyText + '</div>'; }
    return '<div class="cards">' + list.map(function (u) { return '<div class="card"><div class="t">' + esc(u.name) + (String(u.id) === String(CFG.userId) ? ' <span class="badge accent">شما</span>' : '') + (delAct ? ' <button type="button" class="icon-btn" data-act="' + delAct + '" data-uid="' + esc(u.id) + '" data-name="' + esc(u.name) + '">حذف</button>' : '') + '</div><div class="s">کاربر #' + esc(u.id) + '</div></div>'; }).join('') + '</div>';
  }
  function notifyHtml(c) {
    var html = '<div class="pane-head"><div class="note">مطلع = همکاری که این مشتری در تب «مطلع» لیست او دیده می‌شود و اعلان‌هایش را می‌گیرد (همان ستون «مطلع» ماژول اصلی). مسئول = مسئول پیگیری مشتری.</div><div class="links"><button type="button" class="btn small" data-act="notify-add">＋ افزودن مطلع</button><button type="button" class="btn small secondary" data-act="notify" data-id="' + esc(c.id) + '">' + (c.is_assigned ? 'حذف خودم از مطلعین' : 'مطلع شدن خودم') + '</button><button type="button" class="btn small secondary" data-act="resp-add">＋ افزودن مسئول</button></div></div>';
    html += '<div class="section-title">مطلعین (' + fmtNum(c.assigned.length) + ')</div>' + userCards(c.assigned, 'notify-del', 'هیچ همکاری مطلع این مشتری نیست.');
    html += '<div class="section-title">مسئولین (' + fmtNum(c.responsible.length) + ')</div>' + userCards(c.responsible, 'resp-del', 'مسئولی تعیین نشده است.');
    html += '<div class="section-title">اعلان‌گیران رده (' + fmtNum(c.notify_users.length) + ')</div><p class="note">همکارانی که به‌صورت خودکار برای ردهٔ این مشتری اعلان می‌گیرند (تنظیم در «تنظیمات رده» ماژول؛ از این‌جا قابل تغییر نیست).</p>' + userCards(c.notify_users, null, '—');
    html += '<div class="section-title">برگزیده برای (' + fmtNum(c.favorite_users.length) + ')</div>';
    html += c.favorite_users.length ? '<div class="chips">' + c.favorite_users.map(function (u) { return '<span class="chip">★ ' + esc(u.name) + '</span>'; }).join('') + '</div>' : '<div class="empty">این مشتری برای هیچ کاربری برگزیده نشده است.</div>';
    return html;
  }
  function toolsHtml(c) {
    return '<div class="cards">' +
      (hasSiteId(c.comment) ? '<div class="card" data-act="site" data-id="' + esc(c.id) + '" data-name="' + esc(c.full_name) + '" style="cursor:pointer"><div class="t">🌐 نمایش در سایت</div><div class="s">بات ۴۸۶ — صفحهٔ این مشتری در پنل سایت (' + esc(c.comment) + ')</div></div>' : '<div class="card"><div class="t">🌐 نمایش در سایت</div><div class="s">غیرفعال: در توضیحات این مشتری «' + esc(CFG.siteMarker) + '» ثبت نشده است</div></div>') +
      '<a class="card" href="' + esc(c.links.native_edit) + '" target="_blank" rel="noopener"><div class="t">فرم کامل تیم‌یار ↗</div><div class="s">تب‌های پورتال، ارز، فیلد شخصی، تأیید خودکار، بازاریابی/فروش/پشتیبانی</div></a>' +
      '<a class="card" href="' + esc(CFG.baseUrl + '/?page=/crm/client/edit/' + c.id + '&tab=1&portal=1') + '" target="_blank" rel="noopener"><div class="t">کاربر پورتال ↗</div><div class="s">ایجاد کاربر پورتال / تغییر رمز — از فرم اصلی (رمز عبور هرگز از این‌جا ارسال نمی‌شود)</div></a>' +
      '<a class="card" href="' + esc(c.links.print) + '" target="_blank" rel="noopener"><div class="t">چاپ ↗</div><div class="s">چاپ اطلاعات مشتری</div></a>' +
      '<a class="card" href="' + esc(c.links.envelope) + '" target="_blank" rel="noopener"><div class="t">پرینت پاکتی ↗</div><div class="s">برچسب پستی گیرنده</div></a>' +
      '<a class="card" href="' + esc(c.links.documents) + '" target="_blank" rel="noopener"><div class="t">پوشهٔ اسناد ↗</div><div class="s">' + (c.folder_id > 0 ? 'پوشه #' + c.folder_id : 'ایجاد پوشهٔ مشتری در ماژول اسناد') + '</div></a>' +
      '<a class="card" href="' + esc(c.links.audio) + '" target="_blank" rel="noopener"><div class="t">VOIP / فایل‌های صوتی ↗</div><div class="s">لاگ تماس‌ها، مغایرت‌گیری، ایجاد کاربر voip</div></a>' +
      '<div class="card" data-act="api-raw" style="cursor:pointer"><div class="t">دادهٔ خام API</div><div class="s">/api/client/get — برای عیب‌یابی</div></div>' +
      '<div class="card" data-act="share" data-id="' + esc(c.id) + '" style="cursor:pointer"><div class="t">اشتراک</div><div class="s">کپی لینک این پروفایل</div></div>' +
      '</div>';
  }

  /* قانون پروژه (۱۴۰۵/۰۶/۱۲): هر جدول باید سورت + فیلتر داشته باشد و موبایل‌محور باشد.
     enhanceTable روی هر table.grid یک‌بار اجرا می‌شود: فیلتر متنی بالای جدول (سمت کلاینت، همهٔ ستون‌ها)،
     سورت روی همهٔ سرستون‌ها (ستون‌های سروری لیست همان data-sort را نگه می‌دارند)، و data-label برای نمای کارتی موبایل. */
  function enhanceTable(tbl) {
    if (!tbl || tbl.__enhanced) { return; }
    tbl.__enhanced = true;
    var ths = qa('thead th', tbl);
    var labels = ths.map(function (th) { return th.textContent.replace(/[▲▼]/g, '').trim(); });
    function labelRows() {
      qa('tbody tr', tbl).forEach(function (tr) {
        if (tr.__labeled) { return; }
        tr.__labeled = true;
        Array.prototype.forEach.call(tr.cells, function (td, i) { if (!td.hasAttribute('data-label') && labels[i] && !td.querySelector('input[type="checkbox"]')) { td.setAttribute('data-label', labels[i]); } });
      });
    }
    labelRows();
    ths.forEach(function (th) {
      if (th.hasAttribute('data-sort') || th.hasAttribute('data-lsort')) { return; }
      if (th.querySelector('input') || !th.textContent.trim()) { return; }
      th.setAttribute('data-lsort', '1'); th.classList.remove('nosort');
    });
    var wrap = tbl.closest('.table-wrap');
    if (!wrap || wrap.previousElementSibling && wrap.previousElementSibling.classList && wrap.previousElementSibling.classList.contains('table-filter')) { return; }
    var bar = el('div', { 'class': 'table-filter' });
    // کنترل «مرتب‌سازی» (ستون + جهت) — برای موبایل که سرستون دیده نمی‌شود و به‌عنوان راه دوم روی دسکتاپ
    var sortOpts = '<option value="">مرتب‌سازی…</option>' + ths.map(function (th, i) { return (labels[i] && (th.hasAttribute('data-sort') || th.hasAttribute('data-lsort'))) ? '<option value="' + i + '">' + esc(labels[i]) + '</option>' : ''; }).join('');
    bar.innerHTML = '<input type="search" placeholder="فیلتر در این جدول…" aria-label="فیلتر جدول"><span class="note" data-role="tf-count"></span>' +
      '<span class="tf-sort"><select data-role="tf-sort" aria-label="مرتب‌سازی">' + sortOpts + '</select><button type="button" class="icon-btn" data-role="tf-dir" data-dir="asc" title="جهت مرتب‌سازی">↑ صعودی</button></span>' +
      '<button type="button" class="btn small secondary" data-role="tf-cols" title="پنهان/نمایش ستون‌های این جدول">ستون‌ها</button>' +
      '<button type="button" class="btn small secondary" data-role="tf-view"></button>';
    wrap.parentNode.insertBefore(bar, wrap);
    wrap.classList.add('cardable');
    // سوییچ جدولی/کارتی (تنظیم سراسری کاربر؛ «خودکار» = کارتی فقط روی صفحهٔ باریک)
    q('[data-role="tf-view"]', bar).addEventListener('click', function () { setViewMode(cardsActive() ? 'table' : 'cards'); });
    applyViewMode();
    var sortSel = q('[data-role="tf-sort"]', bar), dirBtn = q('[data-role="tf-dir"]', bar);
    function applySortControl() { var i = parseInt(sortSel.value, 10); if (isNaN(i)) { return; } sortByHeader(tbl, ths[i], dirBtn.getAttribute('data-dir')); }
    sortSel.addEventListener('change', applySortControl);
    dirBtn.addEventListener('click', function () { var d = dirBtn.getAttribute('data-dir') === 'asc' ? 'desc' : 'asc'; dirBtn.setAttribute('data-dir', d); dirBtn.textContent = d === 'asc' ? '↑ صعودی' : '↓ نزولی'; applySortControl(); });
    // هم‌گام‌سازی کنترل با وضعیت فعلی سرستون‌ها (سورت سروری لیست)
    ths.forEach(function (th, i) { if (th.classList.contains('sort-asc') || th.classList.contains('sort-desc')) { sortSel.value = String(i); var d = th.classList.contains('sort-asc') ? 'asc' : 'desc'; dirBtn.setAttribute('data-dir', d); dirBtn.textContent = d === 'asc' ? '↑ صعودی' : '↓ نزولی'; } });
    // پنهان‌کردن ستون‌های ناخواستهٔ همین جدول (به‌جز ستون تیک و عملیات)؛ ذخیره بر اساس امضای سرستون‌ها
    var sig = 'tcols:' + labels.filter(Boolean).join('|').slice(0, 200);
    function applyHidden() {
      var hidden = store(sig) || [];
      ths.forEach(function (th, i) { var off = hidden.indexOf(i) >= 0; th.classList.toggle('col-hidden', off); qa('tbody tr', tbl).forEach(function (tr) { if (tr.cells[i]) { tr.cells[i].classList.toggle('col-hidden', off); } }); });
    }
    applyHidden();
    tbl.__applyHidden = applyHidden;
    q('[data-role="tf-cols"]', bar).addEventListener('click', function () {
      var hidden = store(sig) || [];
      var items = ths.map(function (th, i) { return labels[i] ? '<label class="chip chooser-item"><input type="checkbox" data-ci="' + i + '"' + (hidden.indexOf(i) < 0 ? ' checked' : '') + '> ' + esc(labels[i]) + '</label>' : ''; }).join('');
      var body = openModal('ستون‌های این جدول', '<div class="chooser-items">' + items + '</div><p class="note">ستون‌های بدون تیک پنهان می‌شوند (فقط همین مرورگر).</p>', [
        { label: 'اعمال', onClick: function () { var off = qa('[data-ci]', body).filter(function (c) { return !c.checked; }).map(function (c) { return parseInt(c.getAttribute('data-ci'), 10); }); store(sig, off); applyHidden(); closeModal(); } },
        { label: 'نمایش همه', cls: 'secondary', onClick: function () { store(sig, []); applyHidden(); closeModal(); } },
        { label: 'لغو', cls: 'secondary' }
      ]);
    });
    var inp = q('input', bar), cnt = q('[data-role="tf-count"]', bar);
    inp.addEventListener('input', debounce(function () {
      var terms = inp.value.trim().toLowerCase().split(/\s+/).filter(Boolean);
      var shown = 0, total = 0;
      qa('tbody tr', tbl).forEach(function (tr) {
        if (tr.querySelector('.empty-row')) { return; }
        total++;
        var txt = tr.innerText.toLowerCase();
        var ok = terms.every(function (t) { return txt.indexOf(t) >= 0; });
        tr.style.display = ok ? '' : 'none';
        if (ok) { shown++; }
      });
      cnt.textContent = terms.length ? (fmtNum(shown) + ' از ' + fmtNum(total)) : '';
    }, 150));
    tbl.__relabel = labelRows;
  }
  function enhanceTables(container) { qa('table.grid', container || root).forEach(enhanceTable); }

  function table(headers, rows, rowFn, empty) {
    if (!rows.length) { return '<div class="empty">' + esc(empty || 'رکوردی وجود ندارد.') + '</div>'; }
    return '<div class="table-wrap"><table class="grid" data-role="sortable"><thead><tr>' + headers.map(function (h) { return '<th data-lsort="1">' + esc(h) + '</th>'; }).join('') + '</tr></thead><tbody>' + rows.map(rowFn).join('') + '</tbody></table></div>';
  }
  function link(url, label) { return '<a href="' + esc(url) + '" target="_blank" rel="noopener">' + esc(label) + '</a>'; }
  function dataTabHtml(tab, rows, c) {
    var head = '<div class="pane-head"><div class="note">' + fmtNum(rows.length) + ' رکورد' + (rows.length >= 300 ? ' (۳۰۰ ردیف آخر)' : '') + '</div><div class="links">';
    var nativeLink = { sales: c.links.sales, purchase: c.links.purchase, todo: c.links.todo, comments: c.links.comments, documents: c.links.documents, emails: c.links.emails, sms: c.links.sms, chats: c.links.chats, events: c.links.events, polls: c.links.poll, projects: c.links.project, calls: c.links.audio, history: c.links.native_view }[tab];
    if (tab === 'comments') { head += '<button type="button" class="btn small" data-act="comment" data-id="' + esc(c.id) + '" data-name="' + esc(c.full_name) + '">✎+ توضیحات جدید</button>'; }
    if (tab === 'todo') { head += link(c.links.todo, '☑ اقدام جدید ↗').replace('<a ', '<a class="btn small" '); }
    if (tab === 'events') { head += link(c.links.events, '📅 رویداد جدید ↗').replace('<a ', '<a class="btn small" '); }
    if (tab === 'sms' && c.mobiles[0]) { head += '<button type="button" class="btn small" data-act="sms" data-id="' + esc(c.id) + '" data-name="' + esc(c.full_name) + '">✉ پیامک جدید</button>'; }
    if (tab === 'emails' && c.emails[0]) { head += '<button type="button" class="btn small" data-act="email" data-id="' + esc(c.id) + '" data-name="' + esc(c.full_name) + '">@ ایمیل جدید</button>'; }
    head += '<button type="button" class="btn small secondary" data-act="reload-tab">⟳</button>' + (nativeLink ? link(nativeLink, 'در تیم‌یار ↗').replace('<a ', '<a class="btn small secondary" ') : '') + '</div></div>';

    if (tab === 'sales') {
      var sub = state.client.subTab || 'all';
      var types = { all: 'همه', 1: 'فاکتور فروش', 3: 'برگشت از فروش', canceled: 'ابطال‌شده' };
      var filtered = rows.filter(function (r) { if (sub === 'all') { return true; } if (sub === 'canceled') { return r.canceled; } return String(r.type) === sub && !r.canceled; });
      var sum = 0; filtered.forEach(function (r) { if (!r.canceled) { sum += (r.type === 3 ? -1 : 1) * (r.amount || 0); } });
      head = head.replace('<div class="links">', '<div class="sub-tabs">' + Object.keys(types).map(function (k) { return '<button type="button" class="btn secondary' + (sub === k ? ' active' : '') + '" data-act="sub-tab" data-sub="' + k + '">' + types[k] + '</button>'; }).join('') + '</div><div class="links"><span class="badge accent">جمع: ' + fmtNum(sum) + '</span>');
      return head + table(['شماره', 'کد فاکتور', 'عنوان', 'نوع', 'تاریخ', 'مبلغ', 'مانده', 'مرکز فروش', 'ثبت‌کننده', 'وضعیت'], filtered, function (r) {
        return '<tr><td>' + link(r.url, r.id) + '</td><td>' + esc(dash(r.code)) + '</td><td class="right">' + esc(dash(r.title)) + '</td><td><span class="badge' + (r.type === 3 ? ' dark' : '') + '">' + esc(r.type_label) + '</span></td><td>' + esc(r.date) + '</td><td>' + esc(r.amount_fmt) + '</td><td>' + esc(r.remained) + '</td><td>' + esc(dash(r.center)) + '</td><td>' + esc(dash(r.creator)) + '</td><td>' + (r.canceled ? '<span class="badge dark">ابطال</span>' : r.reject ? '<span class="badge">رد شده</span>' : '<span class="badge">وضعیت ' + esc(r.status) + '</span>') + '</td></tr>';
      }, 'فاکتوری برای این مشتری ثبت نشده است.') + '<p class="note">پیش‌فاکتور، سفارش فروش، حواله و قرارداد در پایگاه‌داده به‌صورت جداگانه ذخیره نمی‌شوند؛ برای آن‌ها از «در تیم‌یار» استفاده کنید. مبلغ = جمع اقلام فاکتور (کسر تخفیف، افزودن ارزش افزوده/مالیات/عوارض).</p>';
    }
    if (tab === 'purchase') { return head + table(['شماره', 'شماره فاکتور', 'عنوان', 'تاریخ', 'پیش‌پرداخت', 'ثبت‌کننده', 'وضعیت'], rows, function (r) { return '<tr><td>' + esc(r.id) + '</td><td>' + esc(dash(r.number)) + '</td><td class="right">' + esc(dash(r.title)) + '</td><td>' + esc(r.date) + '</td><td>' + esc(r.pre_payment) + '</td><td>' + esc(dash(r.creator)) + '</td><td>' + (r.canceled ? '<span class="badge dark">ابطال</span>' : '<span class="badge">وضعیت ' + esc(r.status) + '</span>') + '</td></tr>'; }, 'رکورد خریدی برای این مشتری ثبت نشده است.'); }
    if (tab === 'todo') { return head + table(['شماره', 'عنوان اقدام', 'وضعیت', 'پیشرفت', 'شروع', 'مهلت', 'پایان واقعی', 'ایجادکننده', 'مسئول'], rows, function (r) { return '<tr><td>' + link(r.url, r.id) + '</td><td class="right">' + link(r.url, r.title) + '</td><td><span class="badge' + (r.status === 2 ? ' dark' : r.status === 0 ? ' accent' : '') + '">' + esc(r.status_label) + '</span></td><td>' + esc(r.progress) + '%</td><td>' + esc(dash(r.start)) + '</td><td>' + esc(dash(r.deadline)) + '</td><td>' + esc(dash(r.finished)) + '</td><td>' + esc(dash(r.author)) + '</td><td>' + esc(dash(r.owner)) + '</td></tr>'; }, 'اقدامی به این مشتری لینک نشده است.'); }
    if (tab === 'comments') {
      var notes = rows.filter(function (r) { return r.kind !== 'file'; }), files = rows.filter(function (r) { return r.kind === 'file'; });
      if (!rows.length) { return head + '<div class="empty">توضیحی ثبت نشده است. با «توضیحات جدید» اولین توضیح را بنویسید.</div>'; }
      var out = head;
      if (notes.length) { out += '<div class="timeline">' + notes.map(function (r) { return '<div class="tl-item"><div class="d">' + esc(r.created) + ' — <b>' + esc(dash(r.author)) + '</b>' + (r.section_name ? ' <span class="badge">' + esc(r.section_name) + '</span>' : '') + '</div><div style="white-space:pre-wrap">' + esc(r.text) + '</div></div>'; }).join('') + '</div>'; }
      if (files.length) { out += '<div class="section-title">فایل‌های توضیح (پیوست / قدیمی)</div>' + table(['عنوان', 'نویسنده', 'تاریخ', 'اندازه'], files, function (r) { return '<tr><td class="right">' + link(r.url, r.subject || r.name) + '</td><td>' + esc(dash(r.author)) + '</td><td>' + esc(r.created) + '</td><td>' + esc(r.size_fmt) + '</td></tr>'; }); }
      return out + '<p class="note">ویرایش/حذف توضیح و پیوست فایل از صفحهٔ «در تیم‌یار» انجام می‌شود.</p>';
    }
    if (tab === 'documents') { return head + table(['نام فایل', 'نوع', 'اندازه', 'تاریخ', 'ایجادکننده', 'منبع'], rows, function (r) { return '<tr><td class="right">' + (r.is_folder ? '📁 ' + esc(r.name) : link(r.url, r.name)) + '</td><td>' + esc(dash(r.mime)) + '</td><td>' + esc(r.size_fmt) + '</td><td>' + esc(r.created) + '</td><td>' + esc(dash(r.author)) + '</td><td><span class="badge">' + (r.source === 'folder' ? 'پوشهٔ مشتری' : 'لینک‌شده') + '</span></td></tr>'; }, c.folder_id > 0 ? 'سندی در پوشهٔ این مشتری نیست.' : 'پوشهٔ اسناد این مشتری هنوز ایجاد نشده است (از «در تیم‌یار» ایجاد کنید).'); }
    if (tab === 'emails') { return head + table(['موضوع', 'تاریخ', 'ارسال', 'فرستنده/نویسنده', 'وضعیت'], rows, function (r) { return '<tr><td class="right">' + link(r.url, r.subject) + '</td><td>' + esc(r.created) + '</td><td>' + esc(dash(r.sent)) + '</td><td>' + esc(dash(r.author)) + '</td><td>' + (r.sent_flag ? '<span class="badge accent">ارسال شده</span>' : '<span class="badge">' + (r.archived ? 'آرشیو' : 'دریافتی/پیش‌نویس') + '</span>') + '</td></tr>'; }, 'ایمیلی به این مشتری لینک نشده است.'); }
    if (tab === 'sms') { return head + table(['تاریخ', 'جهت', 'شماره', 'متن', 'وضعیت', 'ارسال‌کننده'], rows, function (r) { return '<tr><td>' + esc(r.date) + '</td><td><span class="badge' + (r.direction === 1 ? ' outline' : '') + '">' + esc(r.direction_label || '—') + '</span></td><td>' + esc(r.number) + '</td><td class="wrap right">' + esc(r.content) + '</td><td>' + esc(dash(r.result) || ('وضعیت ' + r.status)) + '</td><td>' + esc(dash(r.author)) + '</td></tr>'; }, 'پیامکی با شماره‌های این مشتری ثبت نشده است.'); }
    if (tab === 'chats') { return head + table(['عنوان گفتگو', 'شروع', 'پایان', 'پیام‌ها', 'وضعیت', 'موبایل'], rows, function (r) { return '<tr><td class="right">' + link(r.url, r.topic) + '</td><td>' + esc(r.created) + '</td><td>' + esc(dash(r.ended)) + '</td><td>' + fmtNum(r.messages) + '</td><td><span class="badge">' + esc(r.status) + '</span></td><td>' + esc(dash(r.mobile)) + '</td></tr>'; }, 'گفتگویی از این مشتری ثبت نشده است.'); }
    if (tab === 'events') { return head + table(['رویداد', 'شروع', 'پایان', 'موقعیت', 'ایجادکننده', 'وضعیت دعوت'], rows, function (r) { return '<tr><td class="right">' + esc(r.name) + (r.online ? ' <span class="badge">آنلاین</span>' : '') + '</td><td>' + esc(r.start) + '</td><td>' + esc(dash(r.finish)) + '</td><td>' + esc(dash(r.place)) + '</td><td>' + esc(dash(r.creator)) + '</td><td><span class="badge">' + esc(r.invite_status) + '</span></td></tr>'; }, 'رویدادی در تقویم برای این مشتری یافت نشد.'); }
    if (tab === 'polls') { return head + table(['نظرسنجی', 'شروع', 'پایان', 'ایجاد', 'ایجادکننده', 'وضعیت'], rows, function (r) { return '<tr><td class="right">' + link(r.url, r.name) + '</td><td>' + esc(dash(r.start)) + '</td><td>' + esc(dash(r.finish)) + '</td><td>' + esc(r.created) + '</td><td>' + esc(dash(r.author)) + '</td><td><span class="badge">' + esc(r.status) + '</span></td></tr>'; }, 'نظرسنجی‌ای به این مشتری اختصاص نیافته است.'); }
    if (tab === 'projects') { return head + table(['پروژه', 'پیشرفت', 'شروع', 'مهلت', 'ایجاد', 'وضعیت'], rows, function (r) { return '<tr><td class="right">' + link(r.url, r.title) + '</td><td>' + esc(r.progress) + '%</td><td>' + esc(dash(r.start)) + '</td><td>' + esc(dash(r.deadline)) + '</td><td>' + esc(r.created) + '</td><td><span class="badge">' + esc(r.status) + '</span></td></tr>'; }, 'پروژه‌ای به این مشتری لینک نشده است.'); }
    if (tab === 'calls') { return head + table(['شناسه تماس', 'تاریخ', 'مدت (ثانیه)', 'هزینه', 'شماره', 'فایل'], rows, function (r) { return '<tr><td>' + esc(r.id) + '</td><td>' + esc(r.date) + '</td><td>' + fmtNum(r.duration) + '</td><td>' + esc(r.cost) + '</td><td>' + esc(dash(r.cid)) + '</td><td>' + (r.has_file ? link(c.links.audio, 'پخش در تیم‌یار') : '—') + '</td></tr>'; }, 'تماس ضبط‌شده‌ای برای این مشتری وجود ندارد (سرویس VOIP روی این سامانه داده‌ای ندارد).'); }
    if (tab === 'history') {
      if (!rows.length) { return head + '<div class="empty">لاگی ثبت نشده است.</div>'; }
      return head + '<div class="timeline">' + rows.map(function (r) { return '<div class="tl-item"><div class="d">' + esc(r.date) + ' — ' + esc(dash(r.author)) + ' <span class="badge">نوع ' + esc(r.type) + '</span></div><div>' + esc(r.text || '(بدون متن)') + '</div></div>'; }).join('') + '</div><p class="note">لاگ سیستمی ماژول مشتری (مشاهده، ویرایش، تنظیمات)؛ ۱۵۰ رکورد آخر.</p>';
    }
    return head + '<div class="empty">—</div>';
  }
  // مرتب‌سازی سمت کلاینت (صفحهٔ جاری) — هم از کلیک سرستون، هم از کنترل «مرتب‌سازی» بالای جدول (موبایل)
  function clientSortTable(tbl, idx, dir) {
    var ths = qa('thead th', tbl), th = ths[idx];
    ths.forEach(function (h) { h.classList.remove('sort-asc', 'sort-desc'); });
    if (th) { th.classList.add(dir === 'asc' ? 'sort-asc' : 'sort-desc'); }
    var tb = tbl.tBodies[0], rows = Array.prototype.slice.call(tb.rows);
    rows.sort(function (a, b) {
      var av = a.cells[idx] ? a.cells[idx].innerText.trim() : '', bv = b.cells[idx] ? b.cells[idx].innerText.trim() : '';
      var an = parseFloat(av.replace(/,/g, '')), bn = parseFloat(bv.replace(/,/g, ''));
      var cmp = (!isNaN(an) && !isNaN(bn)) ? an - bn : av.localeCompare(bv, 'fa');
      return dir === 'asc' ? cmp : -cmp;
    });
    rows.forEach(function (r) { tb.appendChild(r); });
  }
  // سورت یک ستون از روی سرستون آن: ستون‌های سروری لیست (data-sort) => درخواست سرور؛ بقیه => کلاینت
  function sortByHeader(tbl, th, dir) {
    if (th.hasAttribute('data-sort')) { go(listHash({ sort: th.getAttribute('data-sort'), dir: dir, page: 1 })); return; }
    clientSortTable(tbl, Array.prototype.indexOf.call(th.parentNode.children, th), dir);
  }
  root.addEventListener('click', function (e) {
    var th = e.target.closest('th[data-lsort]');
    if (!th) { return; }
    clientSortTable(th.closest('table'), Array.prototype.indexOf.call(th.parentNode.children, th), th.classList.contains('sort-asc') ? 'desc' : 'asc');
  });

  /* ============================== pickers ============================== */
  function openUserPicker(title, onPick) {
    var body = openModal(title, '<div class="picker"><input type="text" data-f="q" placeholder="نام کاربر (پرسنل) را بنویسید…"><div class="results open" data-f="res"><div class="note" style="padding:8px">در حال بارگذاری…</div></div></div>');
    var inp = q('[data-f="q"]', body), res = q('[data-f="res"]', body);
    function search() {
      api('lookup', { kind: 'users', q: inp.value.trim() }).then(function (d) {
        var rows = asArray(d.rows);
        res.innerHTML = rows.length ? rows.map(function (u) { return '<div data-uid="' + esc(u.id) + '" data-uname="' + esc(u.name) + '">' + esc(u.name) + ' <span class="note">#' + esc(u.id) + '</span></div>'; }).join('') : '<div class="note" style="padding:8px">کاربری یافت نشد</div>';
      }).catch(function (e) { res.innerHTML = '<div class="error-box">' + esc(e.message) + '</div>'; });
    }
    inp.addEventListener('input', debounce(search, 300));
    res.addEventListener('click', function (e) { var d = e.target.closest('[data-uid]'); if (!d) { return; } closeModal(); Promise.resolve(onPick({ id: d.getAttribute('data-uid'), name: d.getAttribute('data-uname') })).catch(function (err) { toast(err.message, true); }); });
    search(); inp.focus();
  }
  function openContactModal() {
    var C = state.client;
    var body = openModal('افزودن رابط', '<div class="form-grid">' +
      '<div class="fld"><label>نوع رابط</label><select data-f="type"><option value="1">مشتری تیم‌یار (دوطرفه)</option><option value="3">معرف (یک‌طرفه)</option><option value="2">غیر تیم‌یاری (متن آزاد)</option></select></div>' +
      '<div class="fld" data-f="pick-wrap"><label>مشتری</label><div class="picker"><input type="text" data-f="pick" placeholder="نام یا شناسهٔ مشتری…"><div class="results" data-f="pick-res"></div></div><input type="hidden" data-f="contact_id"></div>' +
      '<div class="fld hidden" data-f="text-wrap"><label>عنوان رابط</label><input type="text" data-f="contact_text"></div>' +
      '<div class="fld"><label>سمت</label><input type="text" data-f="position"></div>' +
      '<div class="fld"><label>تلفن</label><input type="text" data-f="phone"></div>' +
      '<div class="fld full"><label>توضیح</label><input type="text" data-f="comment"></div></div>', [
      { label: 'افزودن', onClick: function (btn) {
        var type = parseInt(q('[data-f="type"]', body).value, 10);
        var payload = { type: type, contact_id: parseInt(q('[data-f="contact_id"]', body).value || '0', 10), contact_text: q('[data-f="contact_text"]', body).value.trim(), contact_position: q('[data-f="position"]', body).value.trim(), contact_phone: q('[data-f="phone"]', body).value.trim(), contact_comment: q('[data-f="comment"]', body).value.trim() };
        if (type !== 2 && !payload.contact_id) { toast('مشتری را از فهرست انتخاب کنید', true); return; }
        if (type === 2 && !payload.contact_text) { toast('عنوان رابط الزامی است', true); return; }
        btn.disabled = true;
        api('contact_add', { id: C.id, contact: payload }).then(function () { toast('رابط اضافه شد'); closeModal(); C.data = null; C.counts = null; renderClient(); }).catch(function (e) { btn.disabled = false; toast(e.message, true); });
      } }, { label: 'لغو', cls: 'secondary' }]);
    var typeSel = q('[data-f="type"]', body);
    typeSel.addEventListener('change', function () { var free = typeSel.value === '2'; q('[data-f="pick-wrap"]', body).classList.toggle('hidden', free); q('[data-f="text-wrap"]', body).classList.toggle('hidden', !free); });
    var pick = q('[data-f="pick"]', body), pres = q('[data-f="pick-res"]', body);
    pick.addEventListener('input', debounce(function () {
      api('lookup', { kind: 'clients', q: pick.value.trim() }).then(function (d) { var rows = asArray(d.rows).filter(function (r) { return r.id !== C.id; }); pres.innerHTML = rows.map(function (r) { return '<div data-cid="' + esc(r.id) + '" data-cname="' + esc(r.name) + '">' + esc(r.name) + ' <span class="note">#' + esc(r.id) + ' ' + esc(r.mobile) + '</span></div>'; }).join('') || '<div class="note" style="padding:8px">یافت نشد</div>'; pres.classList.add('open'); });
    }, 300));
    pres.addEventListener('click', function (e) { var d = e.target.closest('[data-cid]'); if (!d) { return; } q('[data-f="contact_id"]', body).value = d.getAttribute('data-cid'); pick.value = d.getAttribute('data-cname') + ' (#' + d.getAttribute('data-cid') + ')'; pres.classList.remove('open'); });
  }

  /* ============================== client form (new / edit) ============================== */
  function renderClientForm(editId) {
    loadTree().then(renderSide);
    crumbEl.innerHTML = '<a href="#/list">لیست مشتریان</a> › ' + (editId ? 'ویرایش مشتری ' + esc(editId) : 'مشتری جدید');
    mainEl.innerHTML = '<div class="panel"><div class="loading">آماده‌سازی فرم…</div></div>';
    var ready = editId ? api('client', { id: editId }).then(function (d) { return normalizeClient(d.client); }) : Promise.resolve(null);
    Promise.all([ready, loadTree()]).then(function (res) { buildForm(res[0], editId); }).catch(function (e) { mainEl.innerHTML = '<div class="error-box">' + esc(e.message) + '</div>'; });
  }
  function multiHtml(name, items, placeholder, extra) {
    return '<div class="multi-list" data-multi="' + name + '">' + (items.length ? items : [{ id: '', value: '' }]).map(function (it) { return multiItem(name, it, placeholder, extra); }).join('') + '</div><button type="button" class="btn small secondary" data-act="multi-add" data-multi="' + name + '" data-ph="' + esc(placeholder) + '">＋ افزودن</button>';
  }
  function multiItem(name, it, placeholder, extra) {
    var typeSel = '';
    if (name === 'phone') { typeSel = '<select data-mf="type">' + [[3, 'محل کار'], [2, 'منزل'], [4, 'فکس']].map(function (o) { return '<option value="' + o[0] + '"' + (String(o[0]) === String(it.type || 3) ? ' selected' : '') + '>' + o[1] + '</option>'; }).join('') + '</select>'; }
    return '<div class="item" data-mid="' + esc(it.id || '') + '">' + typeSel + '<input type="text" data-mf="value" value="' + esc(it.value || '') + '" placeholder="' + esc(placeholder) + '"><button type="button" class="icon-btn" data-act="multi-del">✕</button></div>';
  }
  function buildForm(c, editId) {
    var isLegal = c ? c.type === 4 : false;
    var home = (c && asArray(c.profile_addresses).filter(function (a) { return a.type === 1; })[0]) || {};
    var work = (c && asArray(c.profile_addresses).filter(function (a) { return a.type === 2; })[0]) || {};
    var catOpts = '<option value="">— بدون رده —</option>';
    asArray(state.tree && state.tree.sections).forEach(function (s) { asArray(s.categories).forEach(function (k) { catOpts += '<option value="' + k.id + '"' + (String(k.id) === String(state.list.category_id) ? ' selected' : '') + '>' + esc(s.name + ' / ' + k.name) + '</option>'; }); });
    function f(label, name, val, opts) { opts = opts || {}; return '<div class="fld' + (opts.full ? ' full' : '') + (opts.legal ? ' only-legal' : '') + (opts.natural ? ' only-natural' : '') + '"><label class="' + (opts.req ? 'req' : '') + '">' + label + '</label>' + (opts.type === 'textarea' ? '<textarea data-f="' + name + '" rows="3">' + esc(val || '') + '</textarea>' : '<input type="text" data-f="' + name + '" value="' + esc(val || '') + '"' + (opts.ph ? ' placeholder="' + esc(opts.ph) + '"' : '') + '>') + '</div>'; }
    var html = '<div class="panel"><div class="panel-title">' + (editId ? 'ویرایش مشتری — ' + esc(c.full_name) : 'مشتری جدید') + '<span class="note">ثبت از طریق API رسمی ماژول مشتری (/api/client/' + (editId ? 'update' : 'create') + ')</span></div>';
    html += '<div class="form-tabs">' + [['general', 'اطلاعات عمومی'], ['contact', 'اطلاعات تماس'], ['details', 'جزئیات'], ['address', 'آدرس'], ['other', 'سایر']].map(function (t, i) { return '<button type="button" class="btn secondary' + (i === 0 ? ' active' : '') + '" data-act="ftab" data-ftab="' + t[0] + '">' + t[1] + '</button>'; }).join('') + '</div>';
    html += '<form data-role="client-form">';
    html += '<div class="form-pane active" data-fpane="general"><div class="form-grid">' +
      '<div class="fld"><label class="req">نوع مشتری</label><select data-f="user_type"><option value="3"' + (!isLegal ? ' selected' : '') + '>حقیقی</option><option value="4"' + (isLegal ? ' selected' : '') + '>حقوقی</option></select></div>' +
      f('نام', 'name', c ? c.name : '', { req: true }) + f('نام خانوادگی', 'last_name', c ? c.surname : '', { natural: true, req: true }) +
      '<div class="fld only-natural"><label>جنسیت</label><select data-f="gender"><option value="0">—</option><option value="1"' + (c && c.gender === 1 ? ' selected' : '') + '>مرد</option><option value="2"' + (c && c.gender === 2 ? ' selected' : '') + '>زن</option></select></div>' +
      f('نام کسب‌وکار / شرکت', 'company', c ? c.company : '', { legal: true }) + f('شناسهٔ ملی / کد اقتصادی', 'tin', c ? c.tin : '', { legal: true }) + f('کد ملی مدیرعامل', 'kpp', c ? c.kpp : '', { legal: true }) +
      f('شماره ثبت', 'reg_number', c ? c.reg_number : '', { legal: true }) + f('پیشه', 'industry', c ? c.industry : '', { legal: true }) + f('تعداد پرسنل', 'number_personnel', c ? c.number_personnel : '', { legal: true }) +
      f('شغل', 'job', c ? c.job : '', { natural: true }) + f('وب‌سایت', 'website', c ? c.website : '') +
      (editId ? '' : '<div class="fld"><label>رده</label><select data-f="category_id">' + catOpts + '</select></div>') +
      '</div></div>';
    html += '<div class="form-pane" data-fpane="contact"><div class="form-grid">' +
      '<div class="fld"><label>تلفن همراه</label>' + multiHtml('mobile', c ? c.mobiles : [], '09xxxxxxxxx') + '</div>' +
      '<div class="fld"><label>ایمیل</label>' + multiHtml('email', c ? c.emails : [], 'name@example.com') + '</div>' +
      '<div class="fld"><label><span class="only-natural">کد ملی</span><span class="only-legal">شناسهٔ ملی</span></label>' + multiHtml('national_code', c ? c.national_codes : [], 'ارقام') + '</div>' +
      '<div class="fld"><label>تلفن‌ها (منزل / محل کار / فکس)</label>' + multiHtml('phone', c ? c.phones : [], '021xxxxxxxx') + '</div>' +
      '</div><p class="note">با «API check» قبل از ایجاد، تکراری‌بودن موبایل/ایمیل/کد ملی بررسی می‌شود.</p></div>';
    html += '<div class="form-pane" data-fpane="details"><div class="form-grid">' +
      f('نام پدر', 'patronymic', c ? c.patronymic : '', { natural: true }) + f('تاریخ تولد', 'birth_date', c ? c.birthday : '', { natural: true, ph: '1370/01/01' }) + f('محل تولد', 'birth_place', c ? c.birthplace : '', { natural: true }) +
      f('شماره شناسنامه', 'identity_no', c ? c.identity_no : '', { natural: true }) + f('سریال شناسنامه', 'identity_serial_no', c ? c.identity_serial : '', { natural: true }) + f('محل صدور', 'place_of_issue', c ? c.place_of_issue : '', { natural: true }) + f('تاریخ صدور', 'date_of_issue', c ? c.date_of_issue : '', { natural: true, ph: '1370/01/01' }) +
      f('ملیت', 'nationality', c ? c.nationality : '') + f('شماره پاسپورت', 'passport_no', c ? c.passport_no : '') +
      f('برچسب', 'lable', c ? c.lable : '') + f('موضوع/حوزه فعالیت', 'issue_activity', c ? c.issue_activity : '', { legal: true }) + f('شماره پروانه کسب', 'property_code', c ? c.property_code : '', { legal: true }) +
      '</div></div>';
    html += '<div class="form-pane" data-fpane="address"><div class="section-title">آدرس اصلی</div><div class="form-grid">' + f('استان', 'home_state', home.state) + f('شهر', 'home_city', home.city) + f('کد پستی', 'home_zip', home.zip_code) + f('آدرس', 'home_address', home.address, { full: true }) + '</div>' +
      '<div class="section-title">آدرس محل کار</div><div class="form-grid">' + f('استان', 'work_state', work.state) + f('شهر', 'work_city', work.city) + f('کد پستی', 'work_zip', work.zip_code) + f('آدرس', 'work_address', work.address, { full: true }) + '</div></div>';
    html += '<div class="form-pane" data-fpane="other"><div class="form-grid">' + f('توضیحات', 'comment', c ? c.comment : '', { full: true, type: 'textarea' }) + '</div></div>';
    html += '</form><div class="adv-actions" style="margin-top:12px">' +
      '<button type="button" class="btn" data-act="form-save">' + (editId ? 'ذخیرهٔ تغییرات' : 'ایجاد مشتری') + '</button>' +
      (editId ? '' : '<button type="button" class="btn secondary" data-act="form-check">بررسی تکراری (API check)</button>') +
      '<a class="btn secondary" href="' + (editId ? '#/client/' + esc(editId) : '#/list') + '">لغو</a>' +
      (editId ? '<a class="btn secondary" href="' + esc(c.links.native_edit) + '" target="_blank" rel="noopener">فرم کامل تیم‌یار ↗</a>' : '') +
      '</div><div data-role="form-result"></div></div>';
    mainEl.innerHTML = html;
    mainEl.__formClient = c;
    applyTypeVisibility();
  }
  function applyTypeVisibility() {
    var sel = q('[data-f="user_type"]'); if (!sel) { return; }
    var legal = sel.value === '4';
    qa('.only-legal').forEach(function (e) { e.classList.toggle('hidden', !legal); });
    qa('.only-natural').forEach(function (e) { e.classList.toggle('hidden', legal); });
  }
  root.addEventListener('change', function (e) { if (e.target.matches && e.target.matches('[data-f="user_type"]')) { applyTypeVisibility(); } });
  root.addEventListener('click', function (e) {
    var a = e.target.closest('[data-act]');
    if (!a || !mainEl.contains(a)) { return; }
    var act = a.getAttribute('data-act');
    if (act === 'ftab') { qa('[data-act="ftab"]').forEach(function (b) { b.classList.toggle('active', b === a); }); qa('[data-fpane]').forEach(function (p) { p.classList.toggle('active', p.getAttribute('data-fpane') === a.getAttribute('data-ftab')); }); }
    if (act === 'multi-add') { var list = q('[data-multi="' + a.getAttribute('data-multi') + '"]'); list.insertAdjacentHTML('beforeend', multiItem(a.getAttribute('data-multi'), { id: '', value: '' }, a.getAttribute('data-ph'))); }
    if (act === 'multi-del') { var item = a.closest('.item'); var lst = item.parentNode; if (item.getAttribute('data-mid')) { lst.__deleted = (lst.__deleted || []).concat([item.getAttribute('data-mid')]); } item.remove(); }
    if (act === 'form-save') { submitClientForm(a); }
    if (act === 'form-check') { checkDuplicates(a); }
  });
  function readMulti(name) {
    var list = q('[data-multi="' + name + '"]');
    var items = qa('.item', list).map(function (it) { var v = q('[data-mf="value"]', it).value.trim(); var o = { value: v }; var id = it.getAttribute('data-mid'); if (id) { o.id = parseInt(id, 10); } var t = q('[data-mf="type"]', it); if (t) { o.type = parseInt(t.value, 10); } if (name !== 'email') { o.country = 364; } return o; }).filter(function (o) { return o.value; });
    return { items: items, deleted: (list.__deleted || []).map(function (x) { return parseInt(x, 10); }) };
  }
  function readForm() {
    function v(n) { var e = q('[data-f="' + n + '"]'); return e ? e.value.trim() : ''; }
    var userType = parseInt(v('user_type'), 10);
    var mob = readMulti('mobile'), em = readMulti('email'), nc = readMulti('national_code'), ph = readMulti('phone');
    var payload = {
      profile: { name: v('name'), last_name: v('last_name'), user_type: userType, gender: parseInt(v('gender') || '0', 10), mobile: mob.items, email: em.items, national_code: nc.items, phone: ph.items,
        patronymic: v('patronymic'), birth_place: v('birth_place'), identity_no: v('identity_no'), identity_serial_no: v('identity_serial_no'), place_of_issue: v('place_of_issue'), nationality: v('nationality'), passport_no: v('passport_no'),
        address: { home: { state: v('home_state'), city: v('home_city'), zip_code: v('home_zip'), address: v('home_address'), country_code: 364 }, work: { state: v('work_state'), city: v('work_city'), zip_code: v('work_zip'), address: v('work_address'), country_code: 364 } } },
      comment: v('comment'), company: v('company'), job: v('job'), website: v('website'), tin: v('tin'), kpp: v('kpp'), industry: v('industry'), number_personnel: v('number_personnel'), reg_number: v('reg_number'), lable: v('lable'), issue_activity: v('issue_activity'), property_code: v('property_code')
    };
    if (v('birth_date')) { payload.profile.birth_date_jalali = v('birth_date'); }
    if (v('date_of_issue')) { payload.profile.date_of_issue_jalali = v('date_of_issue'); }
    if (mob.deleted.length) { payload.deleted_mobile = mob.deleted; }
    if (em.deleted.length) { payload.deleted_email = em.deleted; }
    if (nc.deleted.length) { payload.deleted_national_code = nc.deleted; }
    if (ph.deleted.length) { payload.deleted_phone = ph.deleted; }
    var cat = q('[data-f="category_id"]'); if (cat && cat.value) { payload.category_id = parseInt(cat.value, 10); }
    return payload;
  }
  function checkDuplicates(btn) {
    var p = readForm();
    btn.disabled = true;
    api('client_check', { payload: { email: p.profile.email.map(function (e) { return { value: e.value }; }), mobile: p.profile.mobile.map(function (m) { return { value: m.value, country: 364 }; }), national_code: p.profile.national_code.map(function (n) { return { value: n.value, country: 364 }; }) } })
      .then(function (d) { q('[data-role="form-result"]').innerHTML = '<div class="panel" style="margin-top:8px"><b>پاسخ بررسی تکراری:</b><pre style="direction:ltr;text-align:left;white-space:pre-wrap">' + esc(JSON.stringify(d.api, null, 2)) + '</pre></div>'; })
      .catch(function (e) { toast(e.message, true); }).then(function () { btn.disabled = false; });
  }
  function submitClientForm(btn) {
    var c = mainEl.__formClient;
    var p = readForm();
    if (!p.profile.name) { toast('نام الزامی است', true); return; }
    if (p.profile.user_type === 3 && !p.profile.last_name) { toast('نام خانوادگی الزامی است', true); return; }
    var summary = '<ul><li>نوع: ' + (p.profile.user_type === 4 ? 'حقوقی' : 'حقیقی') + '</li><li>نام: ' + esc(p.profile.name + ' ' + p.profile.last_name) + '</li><li>موبایل: ' + esc(p.profile.mobile.map(function (m) { return m.value; }).join('، ') || '—') + '</li><li>ایمیل: ' + esc(p.profile.email.map(function (m) { return m.value; }).join('، ') || '—') + '</li></ul>';
    confirmModal(c ? 'ذخیرهٔ تغییرات مشتری ' + c.id : 'ایجاد مشتری جدید', summary + '<p class="note">' + (c ? 'تغییرات از طریق /api/client/update ثبت می‌شود.' : 'مشتری از طریق /api/client/create ایجاد می‌شود.') + '</p>', c ? 'ذخیره' : 'ایجاد', function () {
      return api(c ? 'client_update' : 'client_create', c ? { id: c.id, payload: p } : { payload: p }).then(function (d) {
        toast(c ? 'تغییرات ذخیره شد' : 'مشتری ایجاد شد' + (d.new_id ? ' (شناسهٔ ' + d.new_id + ')' : ''));
        state.tree = null;
        if (c) { state.client = { id: c.id, tab: 'overview', data: null, counts: null, tabs: {} }; go('#/client/' + c.id); }
        else if (d.new_id) { go('#/client/' + d.new_id); }
        else { q('[data-role="form-result"]').innerHTML = '<div class="panel"><pre style="direction:ltr;text-align:left;white-space:pre-wrap">' + esc(JSON.stringify(d.api, null, 2)) + '</pre></div>'; }
      });
    });
  }

  /* ============================== help ============================== */
  function showHelp() {
    openModal('راهنمای ماژول مشتریان', '<p><b>این صفحه چیست؟</b> نمای بازطراحی‌شدهٔ ماژول مشتری (CRM) تیم‌یار با همان داده و همان سطح دسترسی، در یک رابط سریع‌تر.</p>' +
      '<ul>' +
      '<li><b>پنل راست (بخش‌ها و رده‌ها):</b> کلیک روی بخش یا رده، لیست را فیلتر می‌کند؛ عدد کنار هر مورد تعداد مشتریان فعال است. «بدون رده»، «تأیید نشده» و «حذف‌شده‌ها» نماهای ویژه‌اند.</li>' +
      '<li><b>تب‌های بالای لیست:</b> همه / حقیقی / حقوقی / برگزیده (برگزیده‌های شما) / مطلع (مشتریانی که شما مطلع آن‌ها هستید) / رویدادها (مشتریان دارای رویداد تقویم).</li>' +
      '<li><b>جستجو:</b> شناسه، نام، تلفن همراه (۱۰ رقم آخر)، کد ملی، ایمیل و نام کسب‌وکار. Enter یا دکمهٔ جستجو.</li>' +
      '<li><b>فیلتر پیشرفته:</b> چند شرط با «و»؛ فیلدهای متنی، تاریخ شمسی (مثلاً 1405/06/01 یا «در طی N روز اخیر»)، نوع، جنسیت، تأیید، رده و پرچم‌ها (دارای فاکتور/رویداد/اقدام). فیلترها را می‌توانید ذخیره و لینکشان را با همکاران به اشتراک بگذارید.</li>' +
      '<li><b>ستون‌ها و مرتب‌سازی:</b> با «انتخاب ستون‌ها» هر فیلد جزئیات مشتری را به لیست اضافه کنید؛ کلیک روی هر سرستون (نشانهٔ ⇅) مرتب می‌کند — ستون‌های اصلی سمت سرور روی همهٔ مشتریان، ستون‌های محاسبه‌ای روی صفحهٔ جاری. روی موبایل که سرستون دیده نمی‌شود، از کنترل «مرتب‌سازی…» و دکمهٔ جهت (↑/↓) بالای هر جدول استفاده کنید؛ دکمهٔ «ستون‌ها» هم ستون‌های همان جدول را پنهان می‌کند.</li>' +
      '<li><b>انتخاب گروهی:</b> با تیک ردیف‌ها نوار عملیات ظاهر می‌شود: برگزیده، تغییر رده، تأیید، انتقال به حذف‌شده‌ها/بازگرداندن/حذف نهایی و خروجی Excel انتخاب‌شده‌ها. هر رکورد جدا اجرا و نتیجه‌اش (موفق/ناموفق) شمرده می‌شود؛ دکمهٔ توقف دارد.</li>' +
      '<li><b>عملیات هر ردیف:</b> 👁 بررسی، ✎ ویرایش، ★ برگزیده، ✎+ توضیحات جدید، ✉ پیامک، 🌐 نمایش در سایت، ⋯ منوی بیشتر (مطلع، رده، اشتراک، چاپ، پرینت پاکتی، تأیید، حذف).</li>' +
      '<li><b>✉ پیامک:</b> در هدر پروفایل، کارت شماره‌های همراه، تب پیامک و عملیات ردیف، پنجرهٔ نگارش باز می‌شود: انتخاب شمارهٔ گیرنده از شماره‌های ثبت‌شدهٔ مشتری، صندوق پیامک (پیش‌فرض قابل تغییر و به‌خاطرسپاری) و متن با شمارندهٔ نویسه/بخش. ارسال با API رسمی پیامک تیم‌یار انجام و در تب «پیامک» مشتری ثبت می‌شود. با انتخاب چند ردیف، «پیامک گروهی» یک متن را به همه (اولین شمارهٔ هر مشتری) با شمارندهٔ موفق/ناموفق و دکمهٔ توقف می‌فرستد.</li>' +
      '<li><b>@ ایمیل:</b> در هدر پروفایل، کارت ایمیل‌ها، تب ایمیل و عملیات ردیف، پنجرهٔ نگارش: گیرنده از ایمیل‌های ثبت‌شدهٔ مشتری، صندوق فرستنده (صندوق‌های شخصی شما در ماژول پست یا پیش‌فرض تیم‌یار)، موضوع و متن ساده. ارسال با API رسمی پست انجام می‌شود. «ایمیل گروهی» در نوار انتخاب، یک ایمیل را به اولین ایمیل هر مشتری انتخاب‌شده می‌فرستد.</li>' +
      '<li><b>🌐 نمایش در سایت:</b> اجرای بات ۴۸۶ برای مشتریانی که در توضیحاتشان «شناسه سایت:…» ثبت شده؛ صفحهٔ مشتری در پنل سایت داخل پنجره باز می‌شود و با «باز کردن در تب جدید» جدا هم می‌شود. در هدر پروفایل، عملیات ردیف، منوی ⋯ و تب ابزارها در دسترس است. ورود به سایت (بات ۳۹۸) هنگام باز شدن ماژول در پس‌زمینه انجام می‌شود و پیش از هر نمایش هم بررسی می‌شود؛ اگر باز هم فرم ورود سایت را دیدید، «ورود مجدد به سایت» را بزنید.</li>' +
      '<li><b>پروفایل مشتری:</b> هدر با اطلاعات کلیدی و دکمه‌های سریع، شاخص‌ها (فروش خالص، فاکتورها، برگشت، آخرین فاکتور، اقدام‌های باز، رویدادها، توضیحات، مطلعین) و تب‌ها: بررسی، رابط‌ها، رده/بخش، مطلع، فروش (با زیرتب نوع و جمع مبلغ)، خرید، اقدام، توضیحات، اسناد، ایمیل، پیامک، گفتگو، رویدادها، نظرسنجی، پروژه، فایل‌های صوتی، تاریخچه و ابزارها. سرستون جدول‌های تب‌ها مرتب‌سازی سمت کلاینت دارند.</li>' +
      '<li><b>ویرایش / مشتری جدید:</b> فرم چندتبی (عمومی، تماس، جزئیات، آدرس، سایر). قبل از ثبت خلاصه تأیید می‌شود و ثبت از طریق API رسمی ماژول مشتری انجام می‌شود؛ هر خطای اعتبارسنجی کل ثبت را متوقف می‌کند (ثبت ناقص انجام نمی‌شود).</li>' +
      '<li><b>خروجی Excel:</b> در لیست، همهٔ ردیف‌های فیلتر فعال (تا ۳۰۰۰ ردیف) با ستون‌های نمایش‌داده‌شده؛ در پروفایل، تب فعال.</li>' +
      '<li><b>نما (جدولی / کارتی / خودکار):</b> دکمهٔ «نما» در نوار بالا بین سه حالت می‌چرخد و برای همهٔ جدول‌ها ذخیره می‌شود؛ «خودکار» روی صفحهٔ باریک کارتی و روی دسکتاپ جدولی است. کنار فیلتر هر جدول هم دکمهٔ «▦ کارتی / ☷ جدولی» همان تنظیم را تغییر می‌دهد. در نمای کارتی، سورت از کنترل «مرتب‌سازی…» انجام می‌شود.</li>' +
      '<li><b>حالت روز/شب:</b> دکمهٔ «🌙 حالت شب / ☀ حالت روز» در نوار بالا؛ پیش‌فرض از تنظیم سیستم شما گرفته می‌شود و انتخابتان در مرورگر ذخیره می‌شود.</li>' +
      '<li><b>تمام صفحه:</b> نمای بدون حاشیه؛ Escape پنجره‌ها را می‌بندد.</li>' +
      '<li><b>«↗»</b> یعنی صفحهٔ اصلی تیم‌یار در تب جدید باز می‌شود (برای مواردی که فرم اختصاصی پرتال لازم است: کاربر پورتال، پیش‌فاکتور/سفارش، VOIP…).</li>' +
      '</ul><p class="note">نسخهٔ ' + esc(CFG.version) + ' — تحلیل و ایجاد: سینا مقدم ۰۹۱۲۱۰۱۱۷۷۸</p>', null, { wide: true });
  }

  /* ============================== boot ============================== */
  renderShell();
  route();
  // پیشنهاد کاربر: لاگین سایت (بات ۳۹۸) در پس‌زمینه، تا «نمایش در سایت» بار اول هم بدون فرم ورود باز شود
  setTimeout(function () { ensureSiteLogin(false); }, 2500);
  window.CRM606 = { version: CFG.version, reload: route, state: state, siteLogin: ensureSiteLogin };
})();
