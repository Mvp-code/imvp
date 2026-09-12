/* ═══════════════════════════════════════════════════════════════
   MVPx List-Page engine (DA Confirmation pattern) — REV C
   Shared by redesigned list views. Auto-search: date changes hit
   the server, everything else filters client-side instantly.
   REV C adds: viewport lock (no scrollbars) with an auto-fit
   pager — the table shows exactly as many rows as fit the screen
   and pages the rest — plus a mobile card view with swipe paging.
   Page config via mvpxListInit({ctrl, from, to, filters:[...]}).
   filter def: { id: selectOrInputId, key: rowDatasetKey,
                 label: chipLabel, mode: 'exact'|'includes' }
   ═══════════════════════════════════════════════════════════════ */
var MVPXL = { ctrl:'', from:'', to:'', filters:[], onCount:null };

/** Resolve a :root CSS custom property for JS color use (charts/toasts). */
function mvpxCssVar(name, fallback) {
  try {
    var v = getComputedStyle(document.documentElement).getPropertyValue(name).trim();
    return v || fallback;
  } catch (e) { return fallback; }
}

function mvpxToast(msg, ok) {
  var t = document.getElementById('daToast');
  if (!t) return;
  t.textContent = msg;
  t.style.background = ok === false ? mvpxCssVar('--status-danger-solid-hover', '#B91C1C') : '#141519';
  t.classList.add('show');
  setTimeout(function(){ t.classList.remove('show'); }, 3200);
}

function mvpxPad(n){ return (n < 10 ? '0' : '') + n; }
function mvpxToMDY(iso){ if(!iso) return ''; var p = iso.split('-'); return p.length===3 ? (p[1]+'/'+p[2]+'/'+p[0]) : ''; }
function mvpxMdyToISO(mdy){ if(!mdy) return ''; var p = mdy.split('/'); return p.length===3 ? (p[2]+'-'+mvpxPad(parseInt(p[0],10))+'-'+mvpxPad(parseInt(p[1],10))) : ''; }

function mvpxListInit(cfg) {
  MVPXL = cfg;
  var f = document.getElementById('filterFrom'), t = document.getElementById('filterTo');
  if (f) f.value = mvpxMdyToISO((cfg.from||'').trim());
  if (t) t.value = mvpxMdyToISO((cfg.to||'').trim());
  /* light quick chips when the range matches */
  var d = new Date(), mdyT = mvpxPad(d.getMonth()+1)+'/'+mvpxPad(d.getDate())+'/'+d.getFullYear();
  d.setDate(d.getDate()+1);
  var mdyN = mvpxPad(d.getMonth()+1)+'/'+mvpxPad(d.getDate())+'/'+d.getFullYear();
  var bT = document.getElementById('btnToday'), bN = document.getElementById('btnTomorrow');
  if (bT && cfg.from === mdyT && cfg.to === mdyT) bT.classList.add('on');
  if (bN && cfg.from === mdyN && cfg.to === mdyN) bN.classList.add('on');
  mvpxFitStart();
  mvpxGroupSummary();
}

/* server round trip — dates only */
function mvpxGoSearch(fromMDY, toMDY) {
  var extra = '&srhFromDate=' + encodeURIComponent(fromMDY)
            + '&srhToDate='   + encodeURIComponent(toMDY)
            + '&searchFilter=yes' + (MVPXL.extraQry || '');
  submitPageDataForm('1', MVPXL.ctrl, '', '', extra); /* 1 = SEARCH */
}
function mvpxDateSearch(){
  mvpxGoSearch(mvpxToMDY(document.getElementById('filterFrom').value),
               mvpxToMDY(document.getElementById('filterTo').value));
}
function mvpxQuickDate(which){
  var d = new Date();
  if (which === 'tomorrow') d.setDate(d.getDate() + 1);
  var from = new Date(d), to = new Date(d);
  if (which === 'week')  { from.setDate(d.getDate() - d.getDay()); to.setDate(from.getDate() + 6); }
  if (which === 'month') { from.setDate(1); to = new Date(d.getFullYear(), d.getMonth()+1, 0); }
  var f = mvpxPad(from.getMonth()+1)+'/'+mvpxPad(from.getDate())+'/'+from.getFullYear();
  var t = mvpxPad(to.getMonth()+1)+'/'+mvpxPad(to.getDate())+'/'+to.getFullYear();
  mvpxGoSearch(f, t);
}

/* client-side instant filters (REV C: class-based, feeds the pager) */
function mvpxApplyFilters() {
  var rows = document.querySelectorAll('#ciRows tr[data-id]');
  var shown = 0;
  rows.forEach(function(r) {
    var vis = true;
    MVPXL.filters.forEach(function(fd){
      var el = document.getElementById(fd.id);
      if (!el) return;
      var v = (el.value || '').toLowerCase();
      if (!v) return;
      var rv = (r.dataset[fd.key] || '').toLowerCase();
      if (fd.mode === 'exact' ? rv !== v : rv.indexOf(v) < 0) vis = false;
    });
    r.classList.toggle('mvpx-flt-out', !vis);
    if (vis) shown++;
  });
  var sc = document.getElementById('showCount');
  if (sc) sc.textContent = 'Showing ' + shown + ' of ' + rows.length;
  mvpxRenderChips();
  if (typeof MVPXL.onCount === 'function') MVPXL.onCount();
  mvpxGroupSummary();
  mvpxPagerReset();
}
function mvpxRenderChips() {
  var c = document.getElementById('activeChips');
  if (!c) return;
  c.innerHTML = '';
  MVPXL.filters.forEach(function(fd){
    var el = document.getElementById(fd.id);
    if (!el || !el.value) return;
    var lbl = el.tagName === 'SELECT' && el.options[el.selectedIndex]
            ? el.options[el.selectedIndex].text : el.value;
    c.innerHTML += '<span class="da-chip">' + fd.label + ': <b>' + lbl + '</b>'
                 + '<button class="x" onclick="mvpxClearFilter(\'' + fd.id + '\')">&times;</button></span>';
  });
}
function mvpxClearFilter(id){ var el = document.getElementById(id); if (el) el.value=''; mvpxApplyFilters(); }

/* selection + bulk submits (legacy servlet flows) */
function mvpxToggleSelectAll(cb) {
  /* covers every row matching the filters — paging is only viewport
     management, so rows on other pager pages are included */
  document.querySelectorAll('#ciRows .rowCheck').forEach(function(c){
    var tr = c.closest('tr');
    var hidden = tr.classList.contains('mvpx-flt-out') || tr.style.display === 'none';
    if (!hidden) c.checked = cb.checked;
  });
}
function mvpxSelectedIDs(){
  return Array.from(document.querySelectorAll('#ciRows .rowCheck:checked')).map(function(c){ return c.value; });
}
function mvpxBulk(selectedType, verb, needsSelection) {
  var ids = mvpxSelectedIDs();
  if (needsSelection !== false && ids.length === 0) { mvpxToast('Select at least one row to ' + verb, false); return; }
  if (!window.confirm('Are you sure you want to ' + verb + ' ' + (ids.length || 'the selected') + ' record(s)?')) return;
  document.formmain.action = '../servlet/MVPGServlet?submitType=1&controller=' + MVPXL.ctrl
    + '&searchFilter=yes&srhFromDate=' + encodeURIComponent(MVPXL.from) + '&srhToDate=' + encodeURIComponent(MVPXL.to)
    + '&selectedType=' + selectedType + '&selectedValues=' + ids.join(',');
  document.formmain.submit();
}
function mvpxEditSelected(selectedType) {
  var ids = mvpxSelectedIDs();
  if (ids.length === 0) { mvpxToast('Select at least one row to edit', false); return; }
  document.formmain.action = '../servlet/MVPGServlet?submitType=1&controller=' + MVPXL.ctrl
    + '&searchFilter=yes&selectedType=' + selectedType + '&selectedValues=' + ids.join(',');
  document.formmain.submit();
}
function mvpxPrint(printType) {
  /* requestType=search is required — MVPGCtrl.printRecord() skips the whole
     export block without it and the servlet answers "No data found" */
  window.open('../servlet/MVPGServlet?submitType=9&controller=' + MVPXL.ctrl
    + '&printType=' + printType + '&searchFilter=yes&requestType=search&srhFromDate=' + encodeURIComponent(MVPXL.from)
    + '&srhToDate=' + encodeURIComponent(MVPXL.to) + getPageSubmitFormValues(true));
}

/* ═══════════════════════════════════════════════════════════════
   REV C — VIEWPORT LOCK + AUTO-FIT PAGER + MOBILE CARDS
   The page never scrolls: we measure how many 38px rows (or 88px
   cards on phones) fit the table area and page the rest.
   ═══════════════════════════════════════════════════════════════ */
var MVPXPG = { page:0, per:10, on:false, cards:false };

/* row containers: #ciRows (standard) or #daRows (DA Confirmations) */
var MVPX_ROWSEL = '#ciRows tr[data-id], #daRows tr[data-id]';
function mvpxIsMobile(){ return window.matchMedia('(max-width:760px)').matches; }
function mvpxAllRows(){ return Array.prototype.slice.call(document.querySelectorAll(MVPX_ROWSEL)); }
function mvpxVisRows(){ return mvpxAllRows().filter(function(r){ return !r.classList.contains('mvpx-flt-out'); }); }

function mvpxFitStart() {
  var wrap = document.querySelector('.tablewrap');
  if (!wrap || !(document.getElementById('ciRows') || document.getElementById('daRows'))) return;
  MVPXPG.on = true;
  /* card view only when the page has no row checkboxes (bulk flows keep the table) */
  MVPXPG.cardsOK = !document.querySelector('#ciRows .rowCheck, #daRows .rowCheck');
  /* viewport-lock removed — the page now scrolls naturally, so we no longer pin
     the shell to one screen (was: document.body.classList.add('mvpx-lock')). */

  /* pager UI into the table footer */
  var foot = wrap.querySelector('.tablefoot');
  if (foot && !foot.querySelector('.mvpx-pager')) {
    var pg = document.createElement('span');
    pg.className = 'mvpx-pager';
    pg.innerHTML = '<button type="button" class="mvpx-pgbtn" id="mvpxPgPrev" onclick="mvpxPage(-1)">&#8249;</button>'
      + '<span id="mvpxPgLabel">1 / 1</span>'
      + '<button type="button" class="mvpx-pgbtn" id="mvpxPgNext" onclick="mvpxPage(1)">&#8250;</button>';
    foot.appendChild(pg);
  }

  /* card list container (mobile) */
  if (MVPXPG.cardsOK && !wrap.querySelector('.mvpx-cardlist')) {
    var cl = document.createElement('div');
    cl.className = 'mvpx-cardlist';
    wrap.insertBefore(cl, foot || null);
  }

  /* swipe paging */
  var tx = 0, ty = 0;
  wrap.addEventListener('touchstart', function(e){ tx = e.touches[0].clientX; ty = e.touches[0].clientY; }, { passive:true });
  wrap.addEventListener('touchend', function(e){
    var dx = e.changedTouches[0].clientX - tx, dy = e.changedTouches[0].clientY - ty;
    if (Math.abs(dx) > 60 && Math.abs(dx) > Math.abs(dy) * 1.5) mvpxPage(dx < 0 ? 1 : -1);
  }, { passive:true });

  window.addEventListener('resize', mvpxPagerRender);
  if (document.fonts && document.fonts.ready) document.fonts.ready.then(mvpxPagerRender);
  setTimeout(mvpxPagerRender, 180);
  mvpxPagerRender();
}

function mvpxFitCount() {
  /* viewport-lock removed: show all loaded rows on one page and let the page
     scroll (rows are already all in the DOM, so this adds no render cost). */
  return 100000;
  var wrap = document.querySelector('.tablewrap');
  var thead = wrap.querySelector('thead');
  /* subtract everything in the wrap that is not the row area:
     footer, quick-add bars, extra tbodies (e.g. DACheckin's #qaRows) */
  var extra = 0;
  Array.prototype.forEach.call(wrap.children, function(ch){
    if (ch.tagName !== 'TABLE' && !ch.classList.contains('mvpx-cardlist')) extra += ch.offsetHeight;
  });
  wrap.querySelectorAll('table > tbody').forEach(function(tb){
    if (tb.id !== 'ciRows' && tb.id !== 'daRows') extra += tb.offsetHeight;
  });
  var avail = wrap.clientHeight - extra;
  if (MVPXPG.cards) {
    return Math.max(2, Math.floor((avail - 20 + 8) / 86));   /* 78px card + 8px gap, 10px padding */
  }
  /* measure the ACTUAL row height (rows can be taller than 38px — e.g. the
     two-line date/time cells on check-ins) so we never fit one row too many
     and push the footer off-screen. Fall back to 38 if none is measurable. */
  var rowH = 0, rr = wrap.querySelectorAll('#ciRows tr[data-id], #daRows tr[data-id]');
  for (var _i = 0; _i < rr.length; _i++) { if (rr[_i].offsetHeight > 0) { rowH = rr[_i].offsetHeight; break; } }
  if (rowH < 20) rowH = 38;
  return Math.max(3, Math.floor((avail - (thead ? thead.offsetHeight : 34)) / rowH));
}

function mvpxPage(d) {
  var vis = mvpxVisRows();
  var maxP = Math.max(0, Math.ceil(vis.length / MVPXPG.per) - 1);
  MVPXPG.page = Math.min(maxP, Math.max(0, MVPXPG.page + d));
  mvpxPagerRender(true);
}
function mvpxPagerReset() { MVPXPG.page = 0; mvpxPagerRender(true); }

function mvpxPagerRender(keepPage) {
  if (!MVPXPG.on) return;
  MVPXPG.cards = MVPXPG.cardsOK && mvpxIsMobile();
  document.body.classList.toggle('mvpx-cards-on', MVPXPG.cards);
  MVPXPG.per = mvpxFitCount();

  var vis = mvpxVisRows();
  var maxP = Math.max(0, Math.ceil(vis.length / MVPXPG.per) - 1);
  if (MVPXPG.page > maxP) MVPXPG.page = maxP;
  var start = MVPXPG.page * MVPXPG.per, end = start + MVPXPG.per;

  vis.forEach(function(r, i){ r.classList.toggle('mvpx-pg-hide', i < start || i >= end); });

  /* mobile cards mirror the current page of rows */
  var cl = document.querySelector('.mvpx-cardlist');
  if (cl) {
    if (MVPXPG.cards) {
      var html = '';
      vis.slice(start, end).forEach(function(r){
        var tds = r.querySelectorAll('td');
        if (!tds.length) return;
        var top = tds[0].textContent.trim();
        var st = tds.length > 1 ? tds[tds.length - 1].innerHTML : '';
        var title = [], sub = [];
        for (var i = 1; i < tds.length - 1; i++) {
          var v = tds[i].textContent.replace(/\s+/g, ' ').trim();
          if (!v || v === '—') continue;
          (title.length < 2 ? title : sub).push(v);
        }
        html += '<div class="mvpx-card" data-for="' + r.dataset.id + '">'
          + '<div class="r1"><span class="mono">' + top + '</span><span class="st">' + st + '</span></div>'
          + '<div class="r2">' + title.join(' · ') + '</div>'
          + '<div class="r3">' + sub.join(' — ') + '</div>'
          + '</div>';
      });
      if (!vis.length) html = '<div style="text-align:center;color:#A6A9B1;font-size:12px;padding:30px 10px">No records match</div>';
      cl.innerHTML = html;
      cl.querySelectorAll('.mvpx-card').forEach(function(card){
        card.addEventListener('click', function(){
          var tr = document.querySelector('#ciRows tr[data-id="' + card.dataset.for + '"], #daRows tr[data-id="' + card.dataset.for + '"]');
          if (!tr) return;
          var a = tr.querySelector('a');
          if (a) a.click(); else tr.click();
        });
      });
    } else {
      cl.innerHTML = '';
    }
  }

  var lbl = document.getElementById('mvpxPgLabel');
  if (lbl) lbl.textContent = (vis.length ? MVPXPG.page + 1 : 0) + ' / ' + (maxP + 1);
  var pv = document.getElementById('mvpxPgPrev'), nx = document.getElementById('mvpxPgNext');
  if (pv) pv.disabled = MVPXPG.page === 0;
  if (nx) nx.disabled = MVPXPG.page >= maxP;
  var sc = document.getElementById('showCount');
  if (sc) sc.textContent = 'Rows ' + (vis.length ? start + 1 : 0) + '–' + Math.min(vis.length, end) + ' of ' + vis.length;
}

/* keyboard paging */
document.addEventListener('keydown', function(e){
  if (!MVPXPG.on) return;
  if (e.target.tagName === 'INPUT' || e.target.tagName === 'SELECT' || e.target.tagName === 'TEXTAREA') return;
  if (e.key === 'ArrowRight') mvpxPage(1);
  else if (e.key === 'ArrowLeft') mvpxPage(-1);
});

/* ---- generic click-to-sort for list headers (mvpx list standard) ----
   Add class="srt" onclick="mvpxSort(this)" + <span class="ar"></span> to any
   sortable <th>. Sorts the table's data rows (tr[data-id]), numeric-aware,
   respects active filters + the auto-fit pager. */
function _mvpxCellText(tr, idx){
  var td = tr.children[idx];
  return td ? (td.textContent || '').replace(/\s+/g, ' ').trim() : '';
}
function mvpxSort(th){
  var table = th.closest('table'); if (!table) return;
  var head  = th.parentNode;
  var idx   = Array.prototype.indexOf.call(head.children, th);
  var asc   = th.getAttribute('data-dir') !== 'asc';
  head.querySelectorAll('th').forEach(function(o){
    if (o !== th){ o.removeAttribute('data-dir'); var a = o.querySelector('.ar'); if (a) a.textContent = ''; }
  });
  th.setAttribute('data-dir', asc ? 'asc' : 'desc');
  var ar = th.querySelector('.ar'); if (ar) ar.textContent = asc ? '▲' : '▼';
  /* the data tbody is the one holding tr[data-id] (skip any quick-add tbody) */
  var tb = null, tbs = table.querySelectorAll('tbody');
  for (var k = 0; k < tbs.length; k++){ if (tbs[k].querySelector('tr[data-id]')){ tb = tbs[k]; break; } }
  if (!tb) return;
  var rows = Array.prototype.slice.call(tb.querySelectorAll('tr[data-id]'));
  rows.sort(function(a, b){
    var x = _mvpxCellText(a, idx), y = _mvpxCellText(b, idx);
    var nx = parseFloat(x.replace(/[^0-9.\-]/g, '')), ny = parseFloat(y.replace(/[^0-9.\-]/g, ''));
    var num = /\d/.test(x) && /\d/.test(y) && !isNaN(nx) && !isNaN(ny)
              && x.replace(/[0-9.\-\s:\/]/g, '') === '' && y.replace(/[0-9.\-\s:\/]/g, '') === '';
    var cmp = num ? (nx - ny) : x.toLowerCase().localeCompare(y.toLowerCase());
    if (cmp === 0) return 0;
    return asc ? cmp : -cmp;
  });
  rows.forEach(function(r){ tb.appendChild(r); });
  if (window.mvpxPagerReset) mvpxPagerReset();
  else if (window.mvpxPagerRender) mvpxPagerRender(true);
}

/* ---- grouped count summary (clickable to filter) ----
   Config: MVPXL.summary = { key:'<data-key>', label:'By …', filterId:'<selectId>', into:'typeSum' }
   Counts the rows the current filters leave visible, grouped by data-<key>;
   shows nice labels from the filter select's options; clicking a chip toggles
   that filter. Works for both mvpxListInit pages and pages with their own
   applyFilters (falls back to window.applyFilters). */
/* render one or many summaries: MVPXL.summary (single) or MVPXL.summaries (array) */
function mvpxGroupSummary(){
  var cfg = (typeof MVPXL !== 'undefined' && MVPXL) ? MVPXL : window.MVPXL;
  if (!cfg) return;
  var list = cfg.summaries || (cfg.summary ? [cfg.summary] : []);
  list.forEach(mvpxRenderSummary);
}
function mvpxRenderSummary(s){
  if (!s || !s.key) return;
  var box = document.getElementById(s.into || 'typeSum'); if (!box) return;
  var rows = document.querySelectorAll('tr[data-id]');
  var map = {}, order = [];
  rows.forEach(function(r){
    if (r.classList.contains('mvpx-flt-out')) return;
    if (r.style.display === 'none') return;
    var v = (r.dataset[s.key] || '').trim().toLowerCase();
    if (!(v in map)) { map[v] = 0; order.push(v); }
    map[v]++;
  });
  var sel = s.filterId ? document.getElementById(s.filterId) : null;
  var labelOf = {};
  if (sel) Array.prototype.forEach.call(sel.options, function(o){ labelOf[(o.value||'').toLowerCase()] = o.text; });
  var cur = sel ? (sel.value || '').toLowerCase() : '';
  order.sort(function(a, b){ return map[b] - map[a] || a.localeCompare(b); });
  function esc(x){ return String(x).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;'); }
  var h = order.length ? '<span class="tsum-lbl">' + esc(s.label || 'By type') + '</span>' : '';
  order.forEach(function(v){
    var disp = labelOf[v] || v || '(none)';
    var on = cur && cur === v;
    var click = sel ? ' onclick="mvpxSummaryPick(\'' + s.filterId + '\',\'' + encodeURIComponent(v).replace(/'/g,'%27') + '\')"' : '';
    h += '<span class="tsum-chip' + (on ? ' on' : '') + '"' + click + '>' + esc(disp) + '<b>' + map[v] + '</b></span>';
  });
  box.innerHTML = h;
}
function mvpxSummaryPick(filterId, enc){
  var el = document.getElementById(filterId); if (!el) return;
  var want = decodeURIComponent(enc);
  el.value = ((el.value || '').toLowerCase() === want) ? '' : want;   /* toggle */
  var fn = window.mvpxApplyFilters || window.applyFilters;
  if (typeof fn === 'function') fn();
}
