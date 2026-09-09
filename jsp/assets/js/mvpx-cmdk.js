/* ═══════════════════════════════════════════════════════════════
   MVPx REV C — global command palette (Ctrl+K) + mobile tab bar
   Included by includeHeader.jsp on every non-popup page.
   Injects its own DOM; needs no per-page markup.
   Sources: page rows (#ciRows), actions, navigation.
   ═══════════════════════════════════════════════════════════════ */
(function () {
  'use strict';
  if (window.__mvpxCmdk) return;
  window.__mvpxCmdk = true;

  var NAV = [
    { l: 'MVPx Dashboard',     c: 'StationDashboard' },
    { l: 'DA Tasks',           c: 'DATask' },
    { l: 'Daily Incidents',    c: 'Incident' },
    { l: 'Daily Inspections',  c: 'VehicleInspection' },
    { l: 'OSHA Incidents',     c: 'EmployeeIncident' },
    { l: 'DA Confirmations',   c: 'DAStatus' },
    { l: 'DA Checkins',        c: 'DACheckin' },
    { l: 'DA Checkouts',       c: 'DACheckout' },
    { l: 'Returns Board',      c: 'ReturnsBoard' },
    { l: 'Wave Sheet',         c: 'WaveSheet' },
    { l: 'Uploads',            c: 'GenericUpload' },
    { l: 'Employee Forms',     c: 'EmployeeForms' },
    { l: 'Terminations',       c: 'EmployeeTermination' },
    { l: 'Daily Uploads',      c: 'CommonUpload' },
    { l: 'Employees',          c: 'AdminEmployee' },
    { l: 'Vehicles',           c: 'AdminVehicle' },
    { l: 'Reports',            c: 'Reports' }
  ];

  function ctrl() {
    var el = document.querySelector('[data-search]');
    return (el && el.dataset.controller) ? el.dataset.controller : '';
  }
  function esc(s) {
    return String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
  }
  function hi(text, q) {
    if (!q) return esc(text);
    var i = text.toLowerCase().indexOf(q);
    if (i < 0) return esc(text);
    return esc(text.substring(0, i)) + '<mark>' + esc(text.substr(i, q.length)) + '</mark>' + esc(text.substring(i + q.length));
  }
  function go(mode, c) {
    if (typeof submitPageDataForm === 'function' && c) submitPageDataForm(String(mode), c);
  }

  /* ── inject palette DOM ─────────────────────────────────── */
  var scrim = document.createElement('div');
  scrim.className = 'mvpx-cmdk-scrim';
  scrim.onclick = close;
  var pal = document.createElement('div');
  pal.className = 'mvpx-cmdk';
  pal.innerHTML =
    '<div class="mvpx-cmdk-in">' +
      '<span style="color:#7A7E88">&#9906;</span>' +
      '<input id="mvpxCmdkQ" placeholder="Search this page, run an action, or jump to…" autocomplete="off">' +
      '<kbd>ESC</kbd>' +
    '</div>' +
    '<div class="mvpx-cmdk-list" id="mvpxCmdkList"></div>' +
    '<div class="mvpx-cmdk-foot">' +
      '<span><kbd>&#8593;</kbd><kbd>&#8595;</kbd> NAVIGATE</span>' +
      '<span><kbd>&#8629;</kbd> OPEN</span>' +
      '<span class="r">PAGE ROWS &middot; ACTIONS &middot; NAVIGATION</span>' +
    '</div>';
  document.body.appendChild(scrim);
  document.body.appendChild(pal);

  var isOpen = false, idx = 0, items = [];

  function actionsFor(q) {
    var c = ctrl(), a = [];
    if (c) {
      a.push({ ic: '+', t1: 'New record', t2: 'Create on this page', run: function () { close(); go(2, c); } });
      a.push({ ic: '↻', t1: 'Refresh list', t2: 'Reload this page’s records', run: function () { close(); go(1, c); } });
    }
    if (!q) return a;
    return a.filter(function (x) { return (x.t1 + ' ' + x.t2).toLowerCase().indexOf(q) >= 0; });
  }

  function rowsFor(q) {
    if (!q) return [];
    var out = [];
    var rows = document.querySelectorAll('#ciRows tr[data-id], #daRows tr[data-id]');
    for (var i = 0; i < rows.length && out.length < 7; i++) {
      var tr = rows[i];
      var txt = (tr.textContent || '').replace(/\s+/g, ' ').trim();
      if (txt.toLowerCase().indexOf(q) < 0) continue;
      out.push({ tr: tr, txt: txt });
    }
    return out;
  }

  function render() {
    var q = document.getElementById('mvpxCmdkQ').value.trim().toLowerCase();
    var list = document.getElementById('mvpxCmdkList');
    items = [];
    var html = '';

    var acts = actionsFor(q);
    if (acts.length) {
      html += '<div class="mvpx-cmdk-group">Actions</div>';
      acts.forEach(function (a) {
        var i = items.length;
        items.push({ run: a.run });
        html += '<div class="mvpx-cmdk-item" data-i="' + i + '">' +
          '<span class="ic">' + a.ic + '</span>' +
          '<span class="tx"><span class="t1">' + a.t1 + '</span><span class="t2">' + a.t2 + '</span></span>' +
          '<span class="go">RUN &#8629;</span></div>';
      });
    }

    var rows = rowsFor(q);
    if (rows.length) {
      html += '<div class="mvpx-cmdk-group">On this page</div>';
      rows.forEach(function (r) {
        var i = items.length;
        items.push({ run: function () {
          close();
          var a = r.tr.querySelector('a');
          if (a) a.click(); else r.tr.click();
        } });
        var t = r.txt.length > 90 ? r.txt.substring(0, 90) + '…' : r.txt;
        html += '<div class="mvpx-cmdk-item" data-i="' + i + '">' +
          '<span class="ic">&#8599;</span>' +
          '<span class="tx"><span class="t1">' + hi(t, q) + '</span></span>' +
          '<span class="go">OPEN &#8629;</span></div>';
      });
    }

    var navs = NAV.filter(function (n) { return !q || n.l.toLowerCase().indexOf(q) >= 0; });
    if (navs.length) {
      html += '<div class="mvpx-cmdk-group">Go to</div>';
      navs.slice(0, q ? 6 : 6).forEach(function (n) {
        var i = items.length;
        items.push({ run: function () { close(); go(1, n.c); } });
        html += '<div class="mvpx-cmdk-item" data-i="' + i + '">' +
          '<span class="ic">&#8594;</span>' +
          '<span class="tx"><span class="t1">' + hi(n.l, q) + '</span><span class="t2">Jump to page</span></span>' +
          '<span class="go">GO &#8629;</span></div>';
      });
    }

    if (!items.length) html = '<div class="mvpx-cmdk-empty">Nothing matches</div>';
    list.innerHTML = html;
    list.querySelectorAll('.mvpx-cmdk-item').forEach(function (el) {
      el.addEventListener('click', function () { run(parseInt(el.dataset.i, 10)); });
      el.addEventListener('mousemove', function () { idx = parseInt(el.dataset.i, 10); paint(); });
    });
    idx = 0;
    paint();
  }

  function paint() {
    document.querySelectorAll('.mvpx-cmdk-item').forEach(function (el) {
      el.classList.toggle('hot', parseInt(el.dataset.i, 10) === idx);
    });
    var hot = document.querySelector('.mvpx-cmdk-item.hot');
    if (hot) hot.scrollIntoView({ block: 'nearest' });
  }
  function run(i) { if (items[i]) items[i].run(); }

  function open() {
    isOpen = true;
    pal.classList.add('open');
    scrim.classList.add('open');
    var q = document.getElementById('mvpxCmdkQ');
    q.value = '';
    render();
    setTimeout(function () { q.focus(); }, 60);
  }
  function close() {
    isOpen = false;
    pal.classList.remove('open');
    scrim.classList.remove('open');
    document.getElementById('mvpxCmdkQ').blur();
  }
  window.mvpxCmdkOpen = open;

  document.getElementById('mvpxCmdkQ').addEventListener('input', render);

  document.addEventListener('keydown', function (e) {
    if ((e.ctrlKey || e.metaKey) && e.key && e.key.toLowerCase() === 'k') {
      e.preventDefault();
      isOpen ? close() : open();
      return;
    }
    if (!isOpen) return;
    if (e.key === 'Escape') { close(); }
    else if (e.key === 'ArrowDown') { e.preventDefault(); idx = Math.min(items.length - 1, idx + 1); paint(); }
    else if (e.key === 'ArrowUp')   { e.preventDefault(); idx = Math.max(0, idx - 1); paint(); }
    else if (e.key === 'Enter')     { e.preventDefault(); run(idx); }
  }, true);

  /* topbar search hint becomes the palette trigger */
  var hint = document.querySelector('.mvpx-search-hint');
  if (hint) {
    hint.textContent = 'Ctrl K';
    hint.style.cursor = 'pointer';
    hint.addEventListener('click', open);
  }

  /* ── mobile bottom tab bar ──────────────────────────────── */
  var shell = document.querySelector('.mvpx-shell');
  if (shell) {
    var cur = ctrl();
    var tabs = [
      { l: 'Incidents', ic: 'IN', c: 'Incident' },
      { l: 'Checkins',  ic: 'CI', c: 'DACheckin' },
      { l: 'Checkouts', ic: 'CO', c: 'DACheckout' },
      { l: 'Confirm',   ic: 'DC', c: 'DAStatus' },
      { l: 'More',      ic: '⋮', c: '' }
    ];
    var bar = document.createElement('nav');
    bar.className = 'mvpx-tabbar';
    tabs.forEach(function (t) {
      var b = document.createElement('button');
      b.type = 'button';
      b.className = 'tab' + (t.c && t.c === cur ? ' on' : '');
      b.innerHTML = '<span class="ic">' + t.ic + '</span>' + t.l;
      b.onclick = t.c
        ? function () { go(1, t.c); }
        : function () { if (typeof mvpxToggleSidebar === 'function') mvpxToggleSidebar(); };
      bar.appendChild(b);
    });
    shell.appendChild(bar);
  }
})();
