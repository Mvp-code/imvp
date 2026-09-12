<!DOCTYPE html>
<%@ page import="java.util.*, com.util.*, com.beans.*"%>
<jsp:useBean id="_errorBean" class="com.beans.ErrorBean" scope="request" />
<%
int submitType = request.getAttribute("submitType") == null ? SubmitType.SEARCH : Integer.parseInt(request.getAttribute("submitType").toString().trim());

SearchBean _searchBean = new SearchBean();
Object _rawBeanObj = request.getAttribute("_recordBean");
if (_rawBeanObj instanceof SearchBean) {
    _searchBean = (SearchBean) _rawBeanObj;
    request.removeAttribute("_recordBean");
}
String _boot = _searchBean.getTransMap() == null || _searchBean.getTransMap().get("bootstrapJson") == null
    ? "{}" : _searchBean.getTransMap().get("bootstrapJson").toString();
%>
<jsp:useBean id="_recordBean" class="com.beans.WaveSheet" scope="request" />
<%@ include file="includeHeader.jsp"%>
<style>
:root{--ws-green:var(--status-ok-fg,#15803D);--ws-green-50:var(--status-ok-bg,#E7F6EE);--ws-amber:var(--status-warn-fg,#B45309);--ws-amber-50:var(--status-warn-bg,#FBF1E2);
--ws-red:var(--status-action-fg,#C62828);--ws-red-50:var(--status-action-bg,#FCEBEB);--ws-faint:#8B8E96;--ws-border:#D8D6CE;--ws-line:#ECEAE3}
.ws-wrap{padding:4px 0 60px}
.ws-crumb{font-size:13px;color:var(--ws-faint);margin-bottom:10px}
.ws-crumb .tag{background:var(--status-info-bg);color:var(--status-info-fg);font-weight:700;font-size:12px;padding:2px 8px;border-radius:6px}
.ws-head{display:flex;align-items:center;gap:10px;flex-wrap:wrap;margin-bottom:10px}
.ws-head h2{margin:0;font-size:28px;font-weight:700;color:#111827}
.ws-head input[type=date]{border:1px solid var(--ws-border);border-radius:8px;padding:6px 9px;font:inherit;background:#fff}
.ws-btn{border:1px solid var(--ws-border);background:#fff;padding:7px 13px;border-radius:8px;font-size:13.5px;font-weight:600;color:#111827;cursor:pointer;white-space:nowrap}
.ws-btn:hover{background:#F0EEE7}
.ws-btn.primary{background:#141519;border-color:#141519;color:#fff}
.ws-btn.primary:disabled{opacity:.5;cursor:wait}
.ws-drop{border:2px dashed var(--ws-border);border-radius:12px;padding:22px;text-align:center;background:#fff;cursor:pointer;transition:border-color .15s;margin-bottom:10px}
.ws-drop.on{border-color:#141519;background:#FAF9F5}
.ws-drop b{font-size:15px}
.ws-drop .f{color:var(--ws-faint);font-size:12px;margin-top:3px}
.ws-slack{background:#fff;border:1px solid var(--ws-border);border-radius:12px;padding:12px 14px;margin-bottom:10px}
.ws-slack-hd{display:flex;align-items:center;gap:10px;margin-bottom:9px;flex-wrap:wrap}
.ws-slack-badge{font-size:12.5px;font-weight:800;color:#4A154B;background:#F4E7F5;border-radius:7px;padding:3px 9px}
.ws-mode{display:inline-flex;border:1px solid var(--ws-border);border-radius:8px;overflow:hidden}
.ws-mode button{border:none;background:#fff;padding:5px 11px;font-size:12px;font-weight:700;cursor:pointer;color:var(--ws-faint)}
.ws-mode button.on{background:#141519;color:#fff}
.ws-slack-list{display:flex;gap:9px;flex-wrap:wrap}
.ws-recent-bar{margin-top:9px}
.ws-recent-bar a{font-size:12px;color:var(--ws-faint);text-decoration:none}
.ws-recent-bar a:hover{color:#141519;text-decoration:underline}
.ws-swave{display:flex;align-items:center;gap:9px;border:1px solid var(--ws-border);border-radius:10px;padding:7px 10px;background:#FAF9F5}
.ws-swave .wl{font-weight:800;font-size:13px;font-family:monospace;color:#141519}
.ws-swave .wm{font-size:11.5px;color:var(--ws-faint);max-width:220px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.ws-swave .wt{font-size:11px;color:var(--ws-faint)}
.ws-swave button{border:1px solid var(--ws-border);background:#fff;border-radius:7px;padding:4px 10px;font-size:12px;font-weight:700;cursor:pointer}
.ws-swave button.load{background:#141519;border-color:#141519;color:#fff}
.ws-swave button:disabled{opacity:.5;cursor:wait}
.ws-prog{display:none;background:#fff;border:1px solid var(--ws-border);border-radius:10px;padding:10px 14px;margin-bottom:10px;font-size:13px}
.ws-prog .bar{height:8px;background:var(--ws-line);border-radius:4px;overflow:hidden;margin-top:7px}
.ws-prog .fl{height:100%;width:0;background:#141519;border-radius:4px;transition:width .3s}
.ws-chips{display:flex;gap:7px;flex-wrap:wrap;align-items:center;margin-bottom:8px}
.ws-pill{display:inline-flex;align-items:center;gap:5px;font-size:11.5px;font-weight:700;padding:3px 10px;border-radius:999px;font-family:monospace}
.ws-pill .d{width:7px;height:7px;border-radius:50%}
.ws-pill.ok{background:var(--ws-green-50);color:var(--ws-green)}.ws-pill.ok .d{background:var(--ws-green)}
.ws-pill.warn{background:var(--ws-amber-50);color:var(--ws-amber)}.ws-pill.warn .d{background:var(--ws-amber)}
.ws-pill.err{background:var(--ws-red-50);color:var(--ws-red)}.ws-pill.err .d{background:var(--ws-red)}
.ws-pill.skip{background:#EEEDE8;color:var(--ws-faint);cursor:pointer}.ws-pill.skip .d{background:var(--ws-faint)}
.ws-chips .ws-pill{cursor:pointer;user-select:none}
.ws-pill.filt-on{outline:2px solid currentColor;outline-offset:1px}
.ws-pill.clearf{background:#141519;color:#fff}.ws-pill.clearf .d{display:none}
.ws-tablewrap{background:#fff;border:1px solid var(--ws-border);border-radius:11px;overflow:auto}
.ws-tablewrap table{width:100%;border-collapse:collapse;min-width:820px}
.ws-tablewrap thead th{text-align:left;font-size:13px;color:#111827;font-weight:700;padding:10px 10px;background:#FAFCFF;border-bottom:1px solid var(--ws-border);white-space:nowrap}
.ws-tablewrap tbody td{padding:8px 10px;border-bottom:1px solid var(--ws-line);font-size:14.5px;color:#111827;vertical-align:middle}
.ws-tablewrap input,.ws-tablewrap select{border:1px solid var(--ws-border);border-radius:6px;padding:6px 8px;font:inherit;font-size:13.5px;background:#FAF9F5;max-width:100%}
tr.st-warn td{background:var(--ws-amber-50)}
tr.st-err td{background:var(--ws-red-50)}
tr.st-skip td{background:#F4F3EE;color:var(--ws-faint)}
.ws-x{border:none;background:transparent;color:var(--ws-faint);cursor:pointer;font-size:13px}
.ws-foot{display:flex;gap:10px;align-items:center;padding:10px 2px;flex-wrap:wrap}
.ws-note{font-size:12px;color:var(--ws-faint)}
.da-toast{position:fixed;bottom:24px;right:24px;background:#0B1220;color:#fff;padding:10px 16px;border-radius:10px;font-size:13px;font-weight:600;z-index:9999;opacity:0;transform:translateY(8px);transition:opacity .25s,transform .25s;pointer-events:none}
.da-toast.show{opacity:1;transform:translateY(0)}
/* print: staging-grouped board */
#wsPrint{display:none}
@media print{
  body *{visibility:hidden}
  #wsPrint,#wsPrint *{visibility:visible}
  #wsPrint{display:block;position:absolute;left:0;top:0;width:100%}
  .ws-ph{font-size:20px;font-weight:800;text-align:center;margin:6px 0 12px}
  .ws-pg{font-size:14px;font-weight:800;background:#141519;color:#fff;padding:5px 10px;margin-top:10px;-webkit-print-color-adjust:exact}
  .ws-pr{display:flex;justify-content:space-between;padding:6px 10px;border:1px solid #999;border-top:0;font-size:15px}
  .ws-pr b{font-size:17px;font-family:monospace}
}
</style>

<div class="ws-wrap">

  <div class="ws-head">
    <h2>Wave Sheet</h2>
    <input type="date" id="wsDate" onchange="wsDateChange()">
    <span class="ws-note">upload today = today's routes</span>
    <span style="flex:1"></span>
    <button class="ws-btn" onclick="wsAddRow()">&#xFF0B; Add Route</button>
    <button class="ws-btn" onclick="wsPrint()">Print Wave Sheet</button>
    <button class="ws-btn primary" id="wsSaveBtn" onclick="wsSave()">Save Day</button>
  </div>

  <div class="ws-slack" id="wsSlack" style="display:none">
    <div class="ws-slack-hd">
      <span class="ws-slack-badge">&#9889; From Slack</span>
      <span class="ws-note" id="wsSlackNote">wave sheets delivered by the AMZL Bridge &mdash; click Load to read one</span>
      <span style="flex:1"></span>
      <span class="ws-mode" id="wsMode" title="Review = you check each sheet before saving. Auto-load = OCR &amp; save automatically while this page is open.">
        <button id="wsModeReview" class="on" onclick="slackSetMode('review')">Review</button><button id="wsModeAuto" onclick="slackSetMode('auto')">Auto-load</button>
      </span>
      <button class="ws-btn" onclick="slackPoll()" title="Check for new">&#8635; Refresh</button>
    </div>
    <div class="ws-slack-list" id="wsSlackList"></div>
    <div class="ws-recent-bar">
      <a href="#" id="wsRecentToggle" onclick="slackRecentToggle();return false">&#8635; Reload a past sheet</a>
    </div>
    <div class="ws-slack-list" id="wsRecentList" style="display:none;margin-top:8px"></div>
  </div>

  <div class="ws-drop" id="wsDrop" onclick="document.getElementById('wsFile').click()">
    <b>&#8853; Drop wave-sheet image(s) here</b>
    <div class="f">or click to choose &middot; or paste a screenshot / Excel rows with Ctrl+V &middot; rows append to the grid below</div>
    <input type="file" id="wsFile" accept="image/*" multiple style="display:none" onchange="wsFiles(this.files)">
  </div>

  <div class="ws-prog" id="wsProg">
    <span id="wsProgTxt">Reading image&hellip;</span>
    <div class="bar"><div class="fl" id="wsProgFl"></div></div>
  </div>

  <%if(_errorBean != null && _errorBean.getType().length() > 0){%>
  <div class="row text-center mt-2"><section class="alert_section">
    <div class="alert-box <%=_errorBean.getType()%>Color"><%=_errorBean.getMesg()%></div>
  </section></div>
  <%}%>

  <div class="ws-chips" id="wsChips"></div>

  <div class="ws-tablewrap">
    <table>
      <thead><tr>
        <th style="width:26px"></th>
        <th>Route</th><th>Driver (as read)</th><th>DA Match &rarr; Transporter ID</th>
        <th>Staging</th><th>Service Type</th><th>DSP</th><th></th>
      </tr></thead>
      <tbody id="wsRows"></tbody>
    </table>
  </div>
  <div class="ws-foot">
    <span class="ws-note" id="wsCount"></span>
  </div>
</div>

<div class="da-toast" id="daToast"></div>
<div id="wsPrint"></div>

<script src="../jsp/assets/js/tesseract/tesseract.min.js"></script>
<script>
var BOOT = <%=_boot%>;
var WS = { rows: [], das: BOOT.das || [], worker: null, ocrBusy: false };
var MY_DSP = 'MVPG';

function toast(msg, ok){
  var t = document.getElementById('daToast');
  t.textContent = msg;
  t.style.background = ok === false ? (typeof mvpxCssVar==='function'?mvpxCssVar('--status-danger-solid-hover','#B91C1C'):'#B91C1C') : '#0B1220';
  t.classList.add('show');
  setTimeout(function(){ t.classList.remove('show'); }, 3400);
}
function esc(s){
  return (s == null ? '' : String(s)).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/"/g,'&quot;');
}
function mdyToIso(v){ var p=(v||'').split('/'); return p.length===3 ? p[2]+'-'+p[0]+'-'+p[1] : ''; }
function isoToMdy(v){ var p=(v||'').split('-'); return p.length===3 ? p[1]+'/'+p[2]+'/'+p[0] : ''; }

/* ---------- DA name matching ---------- */
function nkey(s){ return (s||'').toUpperCase().replace(/[^A-Z ]/g,' ').replace(/\s+/g,' ').trim(); }
var DA_BY_KEY = {};
WS.das.forEach(function(d){ DA_BY_KEY[nkey(d.n)] = d; });
function daMatch(name){
  var k = nkey(name);
  if (!k) return { st:'unassigned', da:null, sugg:[] };
  if (DA_BY_KEY[k]) return { st:'ok', da: DA_BY_KEY[k], sugg:[] };
  /* fuzzy: token overlap score */
  var toks = k.split(' ');
  var scored = [];
  WS.das.forEach(function(d){
    var dk = nkey(d.n), hit = 0;
    toks.forEach(function(t){ if (t.length > 1 && dk.indexOf(t) >= 0) hit++; });
    if (hit > 0) scored.push({ s: hit / Math.max(toks.length, dk.split(' ').length), d: d });
  });
  scored.sort(function(a,b){ return b.s - a.s; });
  var best = scored.slice(0, 6).map(function(x){ return x.d; });
  if (scored.length && scored[0].s >= 0.99) return { st:'ok', da: scored[0].d, sugg: best };
  return { st:'fuzzy', da: (best[0] || null), sugg: best };
}

/* ---------- row model + render ---------- */
function wsAddParsed(o){
  var m = daMatch(o.driver);
  var row = {
    route: o.route, driver: o.driver || '', staging: o.staging || '',
    service: o.service || '', dsp: o.dsp || '', wave: o.wave || '',
    tid: o.tid && o.tid.length ? o.tid : (m.st === 'ok' && m.da ? m.da.t : ''),
    st: o.tid && o.tid.length ? 'ok' : m.st, sugg: m.sugg,
    skip: (o.dsp || '').toUpperCase() !== MY_DSP && (o.dsp || '').length > 0
  };
  /* one row per route: re-reading the same image (or a corrected retake)
     replaces the existing row instead of duplicating it */
  var key = (o.route || '').toUpperCase();
  var ix = -1;
  if (key) WS.rows.forEach(function(r, i){
    if (ix < 0 && (r.route || '').toUpperCase() === key) ix = i;
  });
  if (ix >= 0) WS.rows[ix] = row;
  else WS.rows.push(row);
}
function wsFilter(cat){ window.WS_FILTER = (window.WS_FILTER === cat) ? '' : cat; wsRender(); }
function wsRender(){
  var tb = document.getElementById('wsRows');
  var showSkip = window.WS_SHOWSKIP === true;
  var filt = window.WS_FILTER || '';
  var h = '', ok = 0, warn = 0, err = 0, skip = 0, shown = 0;
  WS.rows.forEach(function(r, i){
    /* one category per row, used for counts, the row pill, and filtering */
    var cat = r.skip ? 'skip' : (r.st === 'ok' && r.tid ? 'ok' : (!r.driver ? 'err' : 'warn'));
    if (cat === 'skip') skip++; else if (cat === 'ok') ok++; else if (cat === 'err') err++; else warn++;
    /* when a filter chip is active show ONLY that category; otherwise hide
       skipped rows unless the user expanded them */
    var visible = filt ? (cat === filt) : !(cat === 'skip' && !showSkip);
    if (!visible) return;
    shown++;
    var cls = cat === 'skip' ? 'st-skip' : (cat === 'ok' ? '' : (cat === 'err' ? 'st-err' : 'st-warn'));
    var pill = cat === 'skip' ? '<span class="ws-pill skip"><span class="d"></span>SKIP</span>'
      : (cat === 'ok' ? '<span class="ws-pill ok"><span class="d"></span>&#10003;</span>'
      : (cat === 'err' ? '<span class="ws-pill err"><span class="d"></span>!</span>'
      : '<span class="ws-pill warn"><span class="d"></span>?</span>'));
    var sel = '<select onchange="wsPickDa(' + i + ', this.value)" style="max-width:230px">';
    sel += '<option value="">' + (r.driver ? 'Pick DA&hellip;' : 'Leave unassigned') + '</option>';
    var listed = {};
    (r.sugg || []).forEach(function(d){
      listed[d.t] = 1;
      sel += '<option value="' + esc(d.t) + '"' + (d.t === r.tid ? ' selected' : '') + '>' + esc(d.n) + ' (' + esc(d.t.substring(0,8)) + '&hellip;)</option>';
    });
    if (r.tid && !listed[r.tid]) {
      var cur = null;
      WS.das.forEach(function(d){ if (d.t === r.tid) cur = d; });
      sel += '<option value="' + esc(r.tid) + '" selected>' + esc(cur ? cur.n : r.tid) + '</option>';
    }
    sel += '<option value="__all">Search all DAs&hellip;</option></select>';
    var matched = '';
    if (r.st === 'ok' && r.tid) {
      var cur2 = null;
      WS.das.forEach(function(d){ if (d.t === r.tid) cur2 = d; });
      matched = '<span class="ws-pill ok"><span class="d"></span>' + esc(cur2 ? cur2.n : '') + ' &middot; ' + esc(r.tid.substring(0, 10)) + '&hellip;</span> '
        + '<button class="ws-x" title="Change" onclick="wsUnmatch(' + i + ')">&#9998;</button>';
    } else {
      matched = sel;
    }
    h += '<tr class="' + cls + '">'
      + '<td>' + pill + '</td>'
      + '<td><input value="' + esc(r.route) + '" style="width:64px;font-weight:700" onchange="wsUpd(' + i + ',\'route\',this.value)"></td>'
      + '<td><input value="' + esc(r.driver) + '" style="width:180px" onchange="wsDriverEdit(' + i + ',this.value)"></td>'
      + '<td>' + matched + '</td>'
      + '<td><input value="' + esc(r.staging) + '" style="width:76px" onchange="wsUpd(' + i + ',\'staging\',this.value)"></td>'
      + '<td><input value="' + esc(r.service) + '" style="width:250px" onchange="wsUpd(' + i + ',\'service\',this.value)"></td>'
      + '<td><input value="' + esc(r.dsp) + '" style="width:52px" onchange="wsDspEdit(' + i + ',this.value)"></td>'
      + '<td><button class="ws-x" onclick="wsDel(' + i + ')">&#10005;</button></td>'
      + '</tr>';
  });
  if (!h) h = '<tr><td colspan="8" style="text-align:center;color:var(--ws-faint);padding:26px">'
    + (filt ? 'No ' + filt.toUpperCase() + ' rows &mdash; <a href="#" onclick="wsFilter(\'' + filt + '\');return false" style="color:#141519">show all</a>'
            : 'No rows yet &mdash; drop an image above.') + '</td></tr>';
  tb.innerHTML = h;
  function chip(cat, cls, label, n){
    return '<span class="ws-pill ' + cls + (filt === cat ? ' filt-on' : '')
      + '" onclick="wsFilter(\'' + cat + '\')" title="Click to show only these">'
      + '<span class="d"></span>' + n + ' ' + label + '</span>';
  }
  var chips = chip('ok', 'ok', 'MATCHED', ok)
    + chip('warn', 'warn', 'CHECK NAME', warn)
    + chip('err', 'err', 'UNASSIGNED', err);
  if (skip > 0) chips += chip('skip', 'skip', 'OTHER DSP &middot; SKIPPED', skip);
  if (filt) chips += '<span class="ws-pill clearf" onclick="wsFilter(\'' + filt + '\')" title="Show all rows"><span class="d"></span>&#10005; clear filter</span>';
  document.getElementById('wsChips').innerHTML = chips;
  var saveable = 0;
  WS.rows.forEach(function(r){ if (!r.skip && r.route) saveable++; });
  document.getElementById('wsCount').textContent = saveable + ' routes will be saved for ' + isoToMdy(document.getElementById('wsDate').value);
}
function wsUpd(i, k, v){ WS.rows[i][k] = v.trim(); if (k === 'route') wsRender(); }
function wsDspEdit(i, v){ WS.rows[i].dsp = v.trim(); WS.rows[i].skip = v.trim().toUpperCase() !== MY_DSP && v.trim().length > 0; wsRender(); }
function wsDriverEdit(i, v){
  WS.rows[i].driver = v.trim();
  var m = daMatch(v);
  WS.rows[i].st = m.st; WS.rows[i].sugg = m.sugg;
  WS.rows[i].tid = m.st === 'ok' && m.da ? m.da.t : '';
  wsRender();
}
function wsPickDa(i, tid){
  if (tid === '__all') {
    WS.rows[i].sugg = WS.das.slice(0, 400);
    wsRender();
    return;
  }
  WS.rows[i].tid = tid;
  WS.rows[i].st = tid ? 'ok' : (WS.rows[i].driver ? 'fuzzy' : 'unassigned');
  wsRender();
}
function wsUnmatch(i){ WS.rows[i].st = 'fuzzy'; wsRender(); }
function wsDel(i){ WS.rows.splice(i, 1); wsRender(); }
function wsAddRow(){
  WS.rows.unshift({ route:'', driver:'', staging:'', service:'', dsp:MY_DSP, wave:'', tid:'', st:'unassigned', sugg:[], skip:false });
  wsRender();
}

/* ---------- OCR ---------- */
function wsProg(show, txt, pct){
  document.getElementById('wsProg').style.display = show ? 'block' : 'none';
  if (txt) document.getElementById('wsProgTxt').textContent = txt;
  document.getElementById('wsProgFl').style.width = (pct || 0) + '%';
}
var WS_TESS = location.origin + '<%=request.getContextPath()%>/jsp/assets/js/tesseract/';
function wsGetWorker(cb){
  if (WS.worker) { cb(WS.worker); return; }
  /* worker paths must be ABSOLUTE - relative URLs break inside the Worker */
  Tesseract.createWorker('eng', 1, {
    workerPath: WS_TESS + 'worker.min.js',
    corePath:   WS_TESS + 'tesseract-core-simd.wasm.js',
    langPath:   WS_TESS,
    logger: function(m){
      if (m.status === 'recognizing text') wsProg(true, 'Reading image' + (WS.ocrTag || '') + '\u2026', Math.round(m.progress * 100));
    }
  }).then(function(w){ WS.worker = w; cb(w); })
    .catch(function(e){ wsProg(false); toast('OCR engine failed to load: ' + e, false); });
}
/* Wave-sheet screenshots defeat whole-page OCR (the bordered middle columns
   come back empty), so we detect the horizontal table borders, slice the
   image into row bands, and read each band as a single line - the vertical
   borders survive as '|' separators, which makes parsing exact. */
function wsBands(canvas){
  var cx = canvas.getContext('2d');
  var d = cx.getImageData(0, 0, canvas.width, canvas.height).data;
  var hs = [];
  for (var y = 0; y < canvas.height; y++) {
    var dark = 0;
    for (var x = 0; x < canvas.width; x += 2) {
      var i = (y * canvas.width + x) * 4;
      var g = 0.3*d[i] + 0.59*d[i+1] + 0.11*d[i+2];
      if (g < 120) dark++;
    }
    if (dark > (canvas.width / 2) * 0.7) hs.push(y);
  }
  var bands = [];
  for (var k = 0; k < hs.length; k++) {
    if (bands.length && hs[k] - bands[bands.length-1].e <= 2) bands[bands.length-1].e = hs[k];
    else bands.push({ s: hs[k], e: hs[k] });
  }
  return bands;
}
function wsOcrImage(w, bmp, tag, done){
  var cv = document.createElement('canvas');
  cv.width = bmp.width; cv.height = bmp.height;
  cv.getContext('2d').drawImage(bmp, 0, 0);
  var bands = wsBands(cv);
  var rowsAdded = 0;

  function finish(){ done(rowsAdded); }

  if (bands.length >= 3) {
    /* bordered table: one OCR per row band, single-line mode */
    var idx = 0;
    w.setParameters({ tessedit_pageseg_mode: '7', preserve_interword_spaces: '1' }).then(function(){
      function nextBand(){
        if (idx >= bands.length - 1) { finish(); return; }
        var top = bands[idx].e + 1, bot = bands[idx + 1].s - 1;
        idx++;
        var h = bot - top;
        if (h < 8) { nextBand(); return; }
        wsProg(true, 'Reading image' + tag + ' - row ' + idx + ' of ' + (bands.length - 1) + '\u2026',
               Math.round(idx / (bands.length - 1) * 100));
        var rc = document.createElement('canvas');
        rc.width = cv.width * 3; rc.height = h * 3;
        rc.getContext('2d').drawImage(cv, 0, top, cv.width, h, 0, 0, rc.width, rc.height);
        w.recognize(rc).then(function(res){
          if (wsParseLine(res.data.text || '')) rowsAdded++;
          wsRender();
          nextBand();
        }).catch(function(){ nextBand(); });
      }
      nextBand();
    });
  } else {
    /* no table borders: whole-image OCR + line parsing */
    w.setParameters({ tessedit_pageseg_mode: '6', preserve_interword_spaces: '1' }).then(function(){
      w.recognize(cv).then(function(res){
        (res.data.text || '').split(/\r?\n/).forEach(function(ln){ if (wsParseLine(ln)) rowsAdded++; });
        wsRender();
        finish();
      }).catch(function(){ finish(); });
    });
  }
}
function wsFiles(files, onDone){
  var list = Array.prototype.slice.call(files || []);
  if (!list.length) { if (onDone) onDone(0); return; }
  var i = 0, total = 0;
  function next(){
    if (i >= list.length) {
      wsProg(false); wsRender();
      if (onDone) { onDone(total); return; }
      toast('Read ' + list.length + ' image(s), ' + total + ' routes found - review the grid', total > 0);
      return;
    }
    var tag = ' ' + (i + 1) + ' of ' + list.length;
    wsProg(true, 'Reading image' + tag + '\u2026', 2);
    var f = list[i];
    i++;
    wsGetWorker(function(w){
      createImageBitmap(f).then(function(bmp){
        wsOcrImage(w, bmp, tag, function(n){ total += n; next(); });
      }).catch(function(){ toast('Could not open ' + f.name, false); next(); });
    });
  }
  next();
  document.getElementById('wsFile').value = '';
}

/* parse one OCR'd row (or pasted line) into a grid row; returns true if added */
function wsCleanRoute(v){
  v = (v || '').replace(/[^A-Z0-9]/gi, '').toUpperCase();
  v = v.replace(/^0X/, 'CX').replace(/^C8/, 'CX').replace(/^GX/, 'CX').replace(/^CK/, 'CX');
  var m = v.match(/^([A-Z]{1,2}X)[A-Z]*(\d{1,4})/); /* CXe67 -> CX67 */
  return m ? m[1] + m[2] : v;
}
function wsCleanStaging(v){
  var m = (v || '').match(/(STG|S1G|5TG|SIG)[\s._-]*([A-Z])[\s._-]*(\d{1,2})/i);
  return m ? ('STG.' + m[2].toUpperCase() + '.' + m[3]) : (v || '').trim();
}
function wsParseLine(line){
  line = (line || '').replace(/\t/g, '|').replace(/\s+/g, ' ').trim();
  if (!line) return false;
  if (/route/i.test(line) && /driver/i.test(line)) return false; /* header */
  if (/^dsp\b/i.test(line)) return false;

  var route = '', driver = '', staging = '', service = '', dsp = '';
  if (line.indexOf('|') >= 0) {
    /* bordered-cell read: DSP | Route | Driver | Staging | Service.
       OCR sometimes eats a pipe (route+driver merge, pipe becomes an 'l'),
       so anchor on the staging part and the route token instead of
       trusting the part count. */
    var parts = line.split('|').map(function(p){ return p.trim(); });
    while (parts.length && !parts[0]) parts.shift();
    while (parts.length && !parts[parts.length - 1]) parts.pop();
    var stgIdx = -1, routeIdx = -1, routeM = null;
    parts.forEach(function(p, ix){
      if (stgIdx < 0 && /(STG|S1G|5TG|SIG)[\s._-]*[A-Z][\s._-]*\d/i.test(p)) stgIdx = ix;
    });
    var scanEnd = stgIdx < 0 ? parts.length : stgIdx;
    for (var ix = 0; ix < scanEnd; ix++) {
      var m = parts[ix].match(/([A-Z]{1,2}X)\s*[a-z]?\s*(\d{1,4})/i);
      if (m) { routeIdx = ix; routeM = m; break; }
    }
    if (routeM) {
      route = wsCleanRoute(routeM[1] + routeM[2]);
      var midTxt = [];
      var afterRt = parts[routeIdx].substring(
          parts[routeIdx].indexOf(routeM[0]) + routeM[0].length).trim();
      if (afterRt) midTxt.push(afterRt);
      for (var j = routeIdx + 1; j < scanEnd; j++)
        if (parts[j]) midTxt.push(parts[j]);
      driver = midTxt.join(' ')
        .replace(/^[lI\[\]!1]+(?=[A-Z])/, '') /* pipe read as a letter */
        .replace(/[^A-Za-z' -]/g, ' ').replace(/\s+/g, ' ').trim();
      staging = stgIdx >= 0 ? wsCleanStaging(parts[stgIdx]) : '';
      service = stgIdx >= 0
          ? parts.slice(stgIdx + 1).join(' ').replace(/\s+/g, ' ').trim() : '';
      dsp = routeIdx > 0
          ? (parts[0] || '').replace(/[^A-Z]/gi, '').toUpperCase() : '';
    }
  }
  if (!route) {
    /* free-text fallback */
    var rm = line.match(/\b([A-Z]{1,2}X ?\d{1,4})\b/i);
    if (!rm) return false;
    route = wsCleanRoute(rm[1]);
    var sm = line.match(/\b(STG|S1G|5TG|SIG)[\s._-]*([A-Z])[\s._-]*(\d{1,2})\b/i);
    staging = sm ? ('STG.' + sm[2].toUpperCase() + '.' + sm[3]) : '';
    var upper = line.toUpperCase();
    var preRoute = line.substring(0, upper.indexOf(rm[1].toUpperCase())).trim();
    var dspM = preRoute.match(/^([A-Z]{3,6})\b/i);
    if (dspM) dsp = dspM[1].toUpperCase();
    var afterRoute = line.substring(upper.indexOf(rm[1].toUpperCase()) + rm[1].length);
    if (sm) {
      var sIdx = afterRoute.indexOf(sm[0]);
      driver = afterRoute.substring(0, sIdx >= 0 ? sIdx : afterRoute.length);
      service = sIdx >= 0 ? afterRoute.substring(sIdx + sm[0].length) : '';
    } else driver = afterRoute;
    driver = driver.replace(/[^A-Za-z' -]/g, ' ').replace(/\s+/g, ' ').trim();
    service = service.replace(/^[\s.,;:-]+/, '').replace(/\s+/g, ' ').trim();
  }
  if (!/^[A-Z]{1,2}X?\d{1,4}$/.test(route)) return false;
  wsAddParsed({ route: route, driver: driver, staging: staging, service: service, dsp: dsp });
  return true;
}

/* ---------- drag/drop + paste ---------- */
(function(){
  var drop = document.getElementById('wsDrop');
  ['dragover','dragenter'].forEach(function(ev){
    drop.addEventListener(ev, function(e){ e.preventDefault(); drop.classList.add('on'); });
  });
  ['dragleave','drop'].forEach(function(ev){
    drop.addEventListener(ev, function(e){ e.preventDefault(); drop.classList.remove('on'); });
  });
  drop.addEventListener('drop', function(e){
    if (e.dataTransfer && e.dataTransfer.files && e.dataTransfer.files.length) wsFiles(e.dataTransfer.files);
  });
  document.addEventListener('paste', function(e){
    var items = (e.clipboardData || {}).items || [];
    var imgs = [];
    for (var i = 0; i < items.length; i++)
      if (items[i].type && items[i].type.indexOf('image') === 0) imgs.push(items[i].getAsFile());
    if (imgs.length) { wsFiles(imgs); return; }
    var txt = (e.clipboardData || {}).getData ? e.clipboardData.getData('text') : '';
    if (txt && txt.indexOf('\t') >= 0) { /* pasted Excel rows */
      txt.split(/\r?\n/).forEach(function(ln){
        var c = ln.split('\t');
        if (c.length >= 2 && c[1] && /x ?\d/i.test(c[1]))
          wsAddParsed({ dsp: (c[0]||'').trim().toUpperCase(), route: (c[1]||'').replace(/\s+/g,'').toUpperCase(),
                        driver: (c[2]||'').trim(), staging: (c[3]||'').trim().toUpperCase(), service: (c[4]||'').trim() });
      });
      wsRender();
      toast('Pasted rows added - review the grid', true);
    }
  });
})();

/* ---------- date / load / save ---------- */
function wsAjax(params, cb){
  var body = new URLSearchParams();
  body.append('submitType', '<%=SubmitType.DYNAMIC%>');
  body.append('controller', 'WaveSheet');
  Object.keys(params).forEach(function(k){ body.append(k, params[k]); });
  ['entityID','loginUser','loginUserID','loginUserRoles','loginUserDisplayName'].forEach(function(k){
    var el = document.getElementById(k); if (el) body.append(k, el.value);
  });
  fetch('MVPGServlet', { method:'POST', headers:{'Content-Type':'application/x-www-form-urlencoded'}, body: body.toString() })
    .then(function(r){ return r.text(); }).then(cb)
    .catch(function(){ toast('Request failed', false); });
}
function wsLoadDay(rows){
  WS.rows = [];
  (rows || []).forEach(function(r){
    wsAddParsed({ route: r.route, driver: r.driver, staging: r.staging, service: r.service, dsp: r.dsp, wave: r.wave, tid: r.tid });
  });
  wsRender();
}
function wsDateChange(){
  var mdy = isoToMdy(document.getElementById('wsDate').value);
  if (!mdy) return;
  wsAjax({ requestType:'dayRows', assignDate: mdy }, function(resp){
    try { wsLoadDay(JSON.parse(resp)); }
    catch(e){ toast('Could not load that day', false); }
  });
  slackPoll(); /* inbox follows the selected day */
  var rl = document.getElementById('wsRecentList'); if (rl) rl.style.display = 'none';
}
function wsSave(){
  var mdy = isoToMdy(document.getElementById('wsDate').value);
  if (!mdy) { toast('Pick a date first', false); return; }
  var out = [];
  WS.rows.forEach(function(r){
    if (r.skip || !r.route) return;
    out.push({ route: r.route, driver: r.driver, tid: r.tid || '', staging: r.staging,
               service: r.service, dsp: r.dsp || MY_DSP, wave: r.wave || '' });
  });
  if (!out.length) { toast('Nothing to save', false); return; }
  var btn = document.getElementById('wsSaveBtn');
  btn.disabled = true;
  wsAjax({ requestType:'saveDay', assignDate: mdy, rowsJson: JSON.stringify(out) }, function(resp){
    btn.disabled = false;
    var m = /<mesg>([^<]*)<\/mesg>/.exec(resp);
    if (resp.indexOf('<status>true') >= 0) toast(m && m[1] ? m[1] : 'Saved', true);
    else toast(m && m[1] ? m[1] : 'Save failed', false);
  });
}

/* ---------- print: staging-grouped board ---------- */
function wsPrint(){
  var groups = {};
  WS.rows.forEach(function(r){
    if (r.skip || !r.route) return;
    var g = (r.staging.match(/STG\.([A-Z])/i) || [,'?'])[1].toUpperCase();
    (groups[g] = groups[g] || []).push(r);
  });
  var keys = Object.keys(groups).sort();
  if (!keys.length) { toast('Nothing to print', false); return; }
  var h = '<div class="ws-ph">' + MY_DSP + ' \u00B7 WAVE SHEET \u00B7 ' + isoToMdy(document.getElementById('wsDate').value) + '</div>';
  keys.forEach(function(k){
    h += '<div class="ws-pg">STAGING ' + k + '</div>';
    groups[k].sort(function(a,b){
      var an = parseInt((a.staging.match(/(\d+)$/) || [,'0'])[1], 10);
      var bn = parseInt((b.staging.match(/(\d+)$/) || [,'0'])[1], 10);
      return an - bn;
    });
    groups[k].forEach(function(r){
      h += '<div class="ws-pr"><b>' + esc(r.route) + '</b><span>' + esc(r.driver || '(unassigned)') + '</span><span>' + esc(r.staging) + '</span></div>';
    });
  });
  document.getElementById('wsPrint').innerHTML = h;
  window.print();
}

/* ---------- Slack inbox (bridge-delivered wave images) ---------- */
function dataUriToFile(uri, name){
  var m = /^data:([^;]+);base64,(.*)$/.exec(uri || '');
  if (!m) return null;
  var bin = atob(m[2]), len = bin.length, arr = new Uint8Array(len);
  for (var i = 0; i < len; i++) arr[i] = bin.charCodeAt(i);
  return new File([arr], name || 'wave.png', { type: m[1] });
}
WS.slackMode = 'review';
WS.slackBusy = false;
function slackApplyMode(mode){
  WS.slackMode = (mode === 'auto') ? 'auto' : 'review';
  var rv = document.getElementById('wsModeReview'), au = document.getElementById('wsModeAuto');
  if (rv) rv.className = WS.slackMode === 'review' ? 'on' : '';
  if (au) au.className = WS.slackMode === 'auto' ? 'on' : '';
}
function slackSetMode(mode){
  slackApplyMode(mode);
  wsAjax({ requestType:'slackSetMode', mode: WS.slackMode }, function(){
    toast(WS.slackMode === 'auto'
      ? 'Auto-load on — sheets will OCR & save while this page is open' : 'Review mode — you confirm each sheet', true);
    slackPoll();
  });
}
function slackRender(list){
  var box = document.getElementById('wsSlack');
  var wrap = document.getElementById('wsSlackList');
  if (!list || !list.length) {
    /* keep the strip visible in auto mode so the toggle stays reachable */
    if (WS.slackMode === 'auto') { box.style.display = 'block'; wrap.innerHTML = ''; document.getElementById('wsSlackNote').textContent = 'Auto-load on — waiting for wave sheets from Slack'; }
    else { box.style.display = 'none'; wrap.innerHTML = ''; }
    return;
  }
  box.style.display = 'block';
  document.getElementById('wsSlackNote').textContent =
    list.length + ' wave sheet' + (list.length > 1 ? 's' : '') + ' from Slack'
    + (WS.slackMode === 'auto' ? ' — auto-loading…' : ' — click Load to read one');
  var h = '';
  list.forEach(function(s){
    h += '<div class="ws-swave" id="sw' + s.wsid + '">'
      + '<span class="wl">' + esc(s.wave || 'WAVE') + '</span>'
      + (s.caption && s.caption !== s.wave ? '<span class="wm" title="' + esc(s.caption) + '">' + esc(s.caption) + '</span>' : '')
      + '<span class="wt">' + esc(s.when || '') + '</span>'
      + (WS.slackMode === 'auto' ? ''
        : '<button class="load" onclick="slackLoad(' + s.wsid + ',this)">Load</button>'
          + '<button onclick="slackDismiss(' + s.wsid + ',this)" title="Ignore this one">Dismiss</button>')
      + '</div>';
  });
  wrap.innerHTML = h;
}
function wsCurMdy(){ return isoToMdy(document.getElementById('wsDate').value) || ''; }
function slackPoll(){
  wsAjax({ requestType:'slackInbox', assignDate: wsCurMdy() }, function(resp){
    var list; try { list = JSON.parse(resp); } catch(e){ return; }
    if (WS.slackMode === 'auto' && list && list.length && !WS.slackBusy) {
      slackRender(list);
      slackAuto(list);
    } else {
      slackRender(list);
    }
  });
}
/* auto-load: OCR every pending sheet into the grid (accumulating), then save
   the day once. Runs only while this page is open. */
function slackAuto(list){
  if (WS.slackBusy) return;
  WS.slackBusy = true;
  var i = 0, loaded = 0;
  function step(){
    if (i >= list.length) {
      WS.slackBusy = false;
      if (loaded > 0) { wsRender(); wsSave(); toast('Auto-loaded ' + loaded + ' Slack wave sheet(s)', true); }
      return;
    }
    var s = list[i++];
    wsAjax({ requestType:'slackImage', wsid: s.wsid }, function(resp){
      var f = dataUriToFile(resp, 'slack-wave-' + s.wsid + '.png');
      if (!f) { wsAjax({ requestType:'slackConsume', wsid: s.wsid }, step); return; }
      wsFiles([f], function(){
        loaded++;
        wsAjax({ requestType:'slackConsume', wsid: s.wsid }, step);
      });
    });
  }
  step();
}
function slackLoad(wsid, btn){
  if (btn){ btn.disabled = true; btn.textContent = 'Reading…'; }
  wsAjax({ requestType:'slackImage', wsid: wsid }, function(resp){
    var f = dataUriToFile(resp, 'slack-wave-' + wsid + '.png');
    if (!f) { toast('Could not read that image', false); if (btn){ btn.disabled=false; btn.textContent='Load'; } return; }
    /* identical path to a manual drop: OCR -> grid rows -> human review -> Save */
    wsFiles([f]);
    /* mark consumed so it drops out of the inbox; rows now await your Save */
    wsAjax({ requestType:'slackConsume', wsid: wsid }, function(){
      var el = document.getElementById('sw' + wsid);
      if (el) el.parentNode.removeChild(el);
      slackPoll();
    });
  });
}
function slackDismiss(wsid, btn){
  if (btn) btn.disabled = true;
  wsAjax({ requestType:'slackDismiss', wsid: wsid }, function(){
    var el = document.getElementById('sw' + wsid);
    if (el) el.parentNode.removeChild(el);
    slackPoll();
  });
}
/* ---- reload a previously-loaded Slack sheet (images are kept, not deleted) ---- */
function slackRecentToggle(){
  var box = document.getElementById('wsRecentList');
  if (box.style.display !== 'none') { box.style.display = 'none'; return; }
  box.style.display = 'flex';
  box.innerHTML = '<span class="ws-note">loading…</span>';
  wsAjax({ requestType:'slackRecent', assignDate: wsCurMdy() }, function(resp){
    var list; try { list = JSON.parse(resp); } catch(e){ list = []; }
    if (!list.length) { box.innerHTML = '<span class="ws-note">no previously-loaded sheets</span>'; return; }
    var h = '';
    list.forEach(function(s){
      h += '<div class="ws-swave">'
        + '<span class="wl">' + esc(s.wave || 'WAVE') + '</span>'
        + (s.caption && s.caption !== s.wave ? '<span class="wm" title="' + esc(s.caption) + '">' + esc(s.caption) + '</span>' : '')
        + '<span class="wt">loaded ' + esc(s.when || '') + '</span>'
        + '<button class="load" onclick="slackReload(' + s.wsid + ',this)">Reload</button>'
        + '</div>';
    });
    box.innerHTML = h;
  });
}
function slackReload(wsid, btn){
  if (btn){ btn.disabled = true; btn.textContent = 'Reading…'; }
  wsAjax({ requestType:'slackImage', wsid: wsid }, function(resp){
    var f = dataUriToFile(resp, 'slack-wave-' + wsid + '.png');
    if (!f) { toast('Could not read that image', false); if (btn){ btn.disabled=false; btn.textContent='Reload'; } return; }
    wsFiles([f], function(n){
      if (btn){ btn.disabled=false; btn.textContent='Reload'; }
      toast('Re-loaded ' + n + ' route(s) — review & Save Day', n > 0);
    });
  });
}

/* ---------- boot ---------- */
(function(){
  document.getElementById('wsDate').value = mdyToIso(BOOT.date || '');
  wsLoadDay(BOOT.rows || []);
  wsAjax({ requestType:'slackMode' }, function(resp){
    slackApplyMode((resp || '').indexOf('auto') >= 0 ? 'auto' : 'review');
    slackPoll();
  });
  setInterval(slackPoll, 25000); /* pick up newly-posted waves while the page is open */
})();
</script>
<%@ include file="includeFooter.jsp"%>