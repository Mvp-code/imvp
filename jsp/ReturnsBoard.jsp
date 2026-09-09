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
String _boardJson = "{\"out\":[],\"done\":[]}";
String _boardDate = "";
if (_searchBean.getTransMap() != null) {
    if (_searchBean.getTransMap().get("boardJson") != null)
        _boardJson = _searchBean.getTransMap().get("boardJson").toString();
    if (_searchBean.getTransMap().get("boardDate") != null)
        _boardDate = _searchBean.getTransMap().get("boardDate").toString();
}
%>
<jsp:useBean id="_recordBean" class="com.beans.ReturnsBoard" scope="request" />
<%@ include file="includeHeader.jsp"%>
<style>
/* ═══ Returns Board \u2014 iPad-first one-tap checkout ═══ */
.rb-hd{display:flex;align-items:center;gap:12px;flex-wrap:wrap;margin-bottom:10px}
.rb-hd h2{font-family:var(--font-disp);font-weight:800;font-size:22px;letter-spacing:-.02em;color:var(--text)}
.rb-date{font-family:var(--font-mono);font-size:12px;border:1px solid var(--border);border-radius:10px;padding:7px 10px;background:#fff;color:var(--text)}
.rb-prog{flex:1;min-width:220px;display:flex;align-items:center;gap:10px}
.rb-prog .tr{flex:1;height:12px;background:#ECEAE1;border-radius:6px;overflow:hidden}
.rb-prog .fl{height:100%;background:var(--text);border-radius:6px;transition:width .4s cubic-bezier(.2,.7,.2,1)}
.rb-prog .tx{font-family:var(--font-mono);font-size:12px;color:var(--text);font-weight:600;white-space:nowrap}
.rb-scan{display:flex;align-items:center;gap:8px;border:1px solid var(--border);border-radius:12px;padding:9px 13px;background:#fff;min-width:250px}
.rb-scan input{border:none;outline:none;font-family:var(--font);font-size:16px;color:var(--text);width:100%;background:transparent}
.rb-btn{font-weight:700;font-size:14px;border-radius:12px;padding:11px 17px;cursor:pointer;border:1px solid var(--border);background:#fff;color:var(--text);white-space:nowrap;transition:all .13s}
.rb-btn:hover{background:#F8F7F2}
.rb-btn.ink{background:var(--text);border-color:var(--text);color:#F4F3EE}
.rb-btn:disabled{opacity:.5}
.rb-grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(190px,1fr));gap:10px;margin-top:8px}
.rb-tile{background:#fff;border:1px solid var(--border);border-radius:14px;padding:13px 14px;cursor:pointer;
  box-shadow:0 1px 2px rgba(20,21,25,.05);transition:transform .12s,box-shadow .12s;position:relative;min-height:142px}
.rb-tile:active{transform:scale(.97)}
.rb-tile.hl{outline:3px solid var(--text);outline-offset:2px}
.rb-tile .veh{font-family:var(--font-disp);font-weight:800;font-size:19px;letter-spacing:-.01em;color:var(--text);line-height:1.1}
.rb-tile .nm{font-size:12.5px;font-weight:600;color:var(--text-muted);margin-top:3px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.rb-tile .meta{font-family:var(--font-mono);font-size:10px;color:var(--text-light);margin-top:7px;line-height:1.7}
.rb-tile .flexout{display:inline-block;font-family:var(--font-mono);font-size:9.5px;background:#E7F4EC;color:#15803D;border-radius:999px;padding:1px 8px;margin-top:5px}
.rb-tile .confirm{position:absolute;inset:0;background:#fff;border-radius:13px;display:none;flex-direction:column;gap:5px;padding:9px;z-index:2}
.rb-tile.arm .confirm{display:flex}
.rb-cf{flex:1;border-radius:9px;border:none;font-weight:800;font-size:12.5px;cursor:pointer;font-family:var(--font);line-height:1.15}
.rb-cf.good{background:#15803D;color:#fff}
.rb-cf.good.outs{background:#fff;color:#15803D;border:1.5px solid #15803D}
.rb-cf.issue{background:#FBF1E2;color:#B45309;border:1.5px solid #B45309}
.rb-cf.cancel{flex:0 0 20px;background:transparent;color:var(--text-light);font-weight:600;font-size:10.5px;border:none}
.rb-park{display:inline-flex;background:#F8F7F2;border:1px solid var(--border);border-radius:11px;padding:3px;gap:2px}
.rb-park button{border:none;background:transparent;border-radius:8px;padding:9px 16px;font-size:13px;font-weight:700;color:var(--text-light);cursor:pointer;font-family:var(--font)}
.rb-park button.on{background:var(--text);color:#F4F3EE}
.rb-empty{grid-column:1/-1;text-align:center;color:#A6A9B1;padding:44px 10px;font-size:15px}
.rb-donebar{margin-top:16px;background:#fff;border:1px solid var(--border);border-radius:12px;padding:11px 15px}
.rb-donebar h4{font-family:var(--font-mono);font-size:10px;letter-spacing:.14em;color:var(--text-light);margin:0 0 8px;text-transform:uppercase}
.rb-done-row{display:flex;gap:10px;align-items:center;padding:5px 0;font-size:12.5px;border-bottom:1px solid #ECEAE1}
.rb-done-row:last-child{border-bottom:none}
.rb-done-row .v{font-family:var(--font-mono);font-size:11.5px;font-weight:600;color:var(--text);width:120px}
.rb-done-row .t{font-family:var(--font-mono);font-size:11px;color:var(--text-light);margin-left:auto}
.rb-done-row .fl{font-family:var(--font-mono);font-size:9.5px;background:#FBF1E2;color:#B45309;border-radius:999px;padding:1px 8px}
/* exception bottom sheet */
/* centered modal, above the app sidebar (sidebar z-index is 200) */
.rb-scrim{position:fixed;inset:0;background:rgba(20,21,25,.45);opacity:0;pointer-events:none;transition:opacity .2s;z-index:390}
.rb-scrim.open{opacity:1;pointer-events:auto}
.rb-sheet{position:fixed;left:50%;top:50%;transform:translate(-50%,-50%) scale(.96);width:min(880px,94vw);
  max-height:88dvh;overflow-y:auto;background:#fff;border-radius:18px;border:1px solid var(--border);
  box-shadow:0 30px 90px rgba(20,21,25,.35);opacity:0;pointer-events:none;
  transition:opacity .2s,transform .22s cubic-bezier(.2,.7,.2,1);z-index:400;
  padding:20px 20px calc(20px + env(safe-area-inset-bottom))}
.rb-sheet.open{opacity:1;pointer-events:auto;transform:translate(-50%,-50%) scale(1)}
.rb-sheet h3{font-family:var(--font-disp);font-weight:800;font-size:19px;color:var(--text);margin-bottom:2px}
.rb-sheet .sub{font-family:var(--font-mono);font-size:11px;color:var(--text-light);margin-bottom:14px}
.rb-togglegrid{display:grid;grid-template-columns:repeat(auto-fill,minmax(150px,1fr));gap:8px;margin-bottom:14px}
.rb-tg{border:1.5px solid var(--border);border-radius:11px;padding:11px 8px;text-align:center;font-size:12.5px;font-weight:700;
  color:#15803D;background:#E7F4EC;cursor:pointer;user-select:none;transition:all .12s}
.rb-tg.bad{color:#C62828;background:#FCEBEB;border-color:#C62828}
.rb-tg small{display:block;font-family:var(--font-mono);font-size:9px;font-weight:400;letter-spacing:.05em;margin-top:2px}
.rb-row{display:flex;gap:10px;align-items:center;margin-bottom:12px;flex-wrap:wrap}
.rb-num{display:flex;align-items:center;gap:0;border:1px solid var(--border);border-radius:11px;overflow:hidden}
.rb-num button{width:44px;height:44px;border:none;background:#F8F7F2;font-size:19px;cursor:pointer;color:var(--text)}
.rb-num input{width:64px;height:44px;border:none;text-align:center;font-family:var(--font-mono);font-size:16px;outline:none}
.rb-remarks{width:100%;border:1px solid var(--border);border-radius:11px;padding:11px;font-family:var(--font);font-size:16px;
  color:var(--text);min-height:64px;resize:vertical}
.rb-remarks:focus{outline:none;border-color:var(--text)}
.rb-photo{display:flex;gap:10px;align-items:center;margin:12px 0}
.rb-photo img{height:64px;border-radius:9px;border:1px solid var(--border);display:none}
.rb-hint{font-family:var(--font-mono);font-size:9.5px;color:#A6A9B1;letter-spacing:.05em}
/* QR scanner overlay */
.rb-qr{position:fixed;inset:0;background:#000;z-index:500;display:none;flex-direction:column}
.rb-qr.open{display:flex}
.rb-qr video{flex:1;object-fit:cover;width:100%}
.rb-qr .bar{display:flex;align-items:center;gap:12px;padding:14px 16px calc(14px + env(safe-area-inset-bottom));background:#141519}
.rb-qr .bar span{color:#F4F3EE;font-family:var(--font-mono);font-size:12px;flex:1}
.rb-toast{position:fixed;bottom:24px;right:24px;background:#141519;color:#fff;padding:11px 17px;border-radius:11px;
  font-size:13.5px;font-weight:600;z-index:9999;opacity:0;transform:translateY(8px);transition:all .25s;pointer-events:none}
.rb-toast.show{opacity:1;transform:none}
@media (max-width:760px){.rb-grid{grid-template-columns:repeat(auto-fill,minmax(155px,1fr))}}
</style>

<div class="rb-hd">
  <h2>Returns Board</h2>
  <input type="date" class="rb-date" id="rbDate" onchange="rbDateChange()">
  <div class="rb-prog">
    <span class="tx" id="rbProgTx">0 / 0</span>
    <div class="tr"><div class="fl" id="rbProgFl" style="width:0%"></div></div>
  </div>
  <div class="rb-scan">
    <span style="color:#A6A9B1">&#9906;</span>
    <input id="rbFilter" placeholder="Scan / type van, VIN or name" oninput="rbRender()" autocomplete="off">
  </div>
  <button class="rb-btn" id="rbQrBtn" onclick="rbQrOpen()" style="display:none">&#9635; Scan VIN</button>
  <button class="rb-btn ink" id="rbAllBtn" onclick="rbAllGood(this)">&#10003; Check out all remaining</button>
</div>

<%if(_errorBean != null && _errorBean.getType().length() > 0){%>
<div class="alert-box <%=_errorBean.getType()%>Color"><%=_errorBean.getMesg()%></div>
<%}%>

<div class="rb-grid" id="rbGrid"></div>

<div class="rb-donebar">
  <h4>Returned <span id="rbDoneCnt"></span></h4>
  <div id="rbDone"></div>
</div>

<!-- exception sheet -->
<div class="rb-scrim" id="rbScrim" onclick="rbSheetClose()"></div>
<div class="rb-sheet" id="rbSheet">
  <h3 id="rbShTitle">Issue at return</h3>
  <div class="sub" id="rbShSub"></div>
  <div class="rb-hint" style="margin-bottom:7px">TAP ANYTHING THAT IS A PROBLEM &mdash; GREEN MEANS OK</div>
  <div class="rb-togglegrid" id="rbToggles"></div>
  <div class="rb-row">
    <div>
      <div class="rb-hint" style="margin-bottom:5px">PARKED</div>
      <div class="rb-park" id="rbPark">
        <button type="button" class="on" data-v="1" onclick="rbParkSet(this)">Inside</button>
        <button type="button" data-v="2" onclick="rbParkSet(this)">Outside</button>
        <button type="button" data-v="3" onclick="rbParkSet(this)">Backside</button>
      </div>
    </div>
    <div>
      <div class="rb-hint" style="margin-bottom:5px">PACKAGES BROUGHT BACK</div>
      <div class="rb-num">
        <button type="button" onclick="rbPkg(-1)">&minus;</button>
        <input id="rbPkgs" value="0" inputmode="numeric">
        <button type="button" onclick="rbPkg(1)">&#43;</button>
      </div>
    </div>
    <div style="flex:1;min-width:230px">
      <div class="rb-hint" style="margin-bottom:5px">NOTES &mdash; USE THE KEYBOARD MIC TO DICTATE</div>
      <textarea class="rb-remarks" id="rbRemarks" placeholder="e.g. scratch on left slider door, phone screen cracked"></textarea>
    </div>
  </div>
  <div class="rb-photo">
    <button class="rb-btn" onclick="document.getElementById('rbFile').click()">&#128247; Add photo</button>
    <input type="file" id="rbFile" accept="image/*" capture="environment" style="display:none" onchange="rbPhotoPick(this)">
    <img id="rbPhotoPrev" alt="">
    <span class="rb-hint" id="rbPhotoHint">OPTIONAL WALK-AROUND SHOT</span>
  </div>
  <div class="rb-row" style="margin-bottom:0">
    <button class="rb-btn" onclick="rbSheetClose()">Cancel</button>
    <span style="flex:1"></span>
    <button class="rb-btn ink" id="rbShSave" onclick="rbSheetSave(this)">Save checkout</button>
  </div>
</div>

<!-- QR scanner -->
<div class="rb-qr" id="rbQr">
  <video id="rbQrVideo" playsinline muted></video>
  <div class="bar">
    <span>Point at the VIN QR code on the windshield</span>
    <button class="rb-btn" onclick="rbQrClose()">Close</button>
  </div>
</div>

<div class="rb-toast" id="rbToast"></div>

<script>
var RB = <%=_boardJson%>;
var RB_DATE = '<%=_boardDate%>';   /* MM/DD/YYYY */
var RB_CTRL = 'ReturnsBoard';
var rbArmTimer = null, rbSheetCk = null, rbPhotoData = '';

function rbEsc(s){ return String(s == null ? '' : s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;'); }
function rbToast(msg, ok){
  var t = document.getElementById('rbToast');
  t.textContent = msg;
  t.style.background = ok === false ? '#B91C1C' : '#141519';
  t.classList.add('show');
  setTimeout(function(){ t.classList.remove('show'); }, 2800);
}
function rbAjax(params, cb){
  var body = new URLSearchParams();
  body.append('submitType', '<%=SubmitType.DYNAMIC%>');
  body.append('controller', RB_CTRL);
  body.append('boardDate', RB_DATE);
  ['entityID','loginUser','loginUserID','loginUserRoles','loginUserDisplayName'].forEach(function(k){
    var el = document.getElementById(k); if (el) body.append(k, el.value);
  });
  for (var k in params) body.append(k, params[k]);
  fetch('MVPGServlet', { method:'POST', headers:{'Content-Type':'application/x-www-form-urlencoded'}, body: body.toString() })
    .then(function(r){ return r.text(); }).then(cb).catch(function(){ cb(''); });
}

/* MM/DD/YYYY <-> ISO for the date input */
(function(){
  var p = RB_DATE.split('/');
  if (p.length === 3) document.getElementById('rbDate').value = p[2] + '-' + ('0'+p[0]).slice(-2) + '-' + ('0'+p[1]).slice(-2);
})();
function rbDateChange(){
  var v = document.getElementById('rbDate').value.split('-');
  if (v.length !== 3) return;
  var mdy = v[1] + '/' + v[2] + '/' + v[0];
  submitPageDataForm('<%=SubmitType.SEARCH%>', RB_CTRL, '', '', '&srhFromDate=' + encodeURIComponent(mdy) + '&searchFilter=yes');
}

/* ── render ───────────────────────────────────────────────── */
function rbRender(){
  var q = (document.getElementById('rbFilter').value || '').toLowerCase().trim();
  var g = document.getElementById('rbGrid'), h = '';
  var shown = 0;
  RB.out.forEach(function(t, i){
    var hay = (t.veh + ' ' + t.vin + ' ' + t.nm).toLowerCase();
    if (q && hay.indexOf(q) < 0) return;
    shown++;
    h += '<div class="rb-tile" id="rbT' + t.ck + '" onclick="rbArm(' + t.ck + ')">'
      + '<div class="veh">' + rbEsc(t.veh || 'No van') + '</div>'
      + '<div class="nm">' + rbEsc(t.nm) + '</div>'
      + '<div class="meta">IN ' + rbEsc(t.in) + (t.wave ? ' &middot; W' + rbEsc(t.wave) : '')
      + (t.stops ? '<br>STOPS ' + rbEsc(t.stops) : '') + '</div>'
      + (t.flexOut ? '<span class="flexout">FLEX OUT ' + rbEsc(t.flexOut) + '</span>' : '')
      + '<div class="confirm">'
      + '<button class="rb-cf good" onclick="event.stopPropagation();rbGood(' + t.ck + ', this, 1)">&#10003; All good &middot; Parked inside</button>'
      + '<button class="rb-cf good outs" onclick="event.stopPropagation();rbGood(' + t.ck + ', this, 2)">&#10003; All good &middot; Parked outside</button>'
      + '<button class="rb-cf issue" onclick="event.stopPropagation();rbIssue(' + t.ck + ')">&#9888; Issue</button>'
      + '<button class="rb-cf cancel" onclick="event.stopPropagation();rbDisarm()">cancel</button>'
      + '</div></div>';
  });
  if (!RB.out.length) h = '<div class="rb-empty">Everyone is back &mdash; nothing waiting to check out &#127881;</div>';
  else if (!shown) h = '<div class="rb-empty">No match for &ldquo;' + rbEsc(q) + '&rdquo;</div>';
  g.innerHTML = h;

  var total = RB.out.length + RB.done.length;
  document.getElementById('rbProgTx').textContent = RB.done.length + ' / ' + total + ' returned';
  document.getElementById('rbProgFl').style.width = total ? (RB.done.length / total * 100) + '%' : '0%';
  document.getElementById('rbAllBtn').style.display = RB.out.length ? '' : 'none';

  var dh = '';
  RB.done.slice(0, 12).forEach(function(x){
    dh += '<div class="rb-done-row"><span class="v">' + rbEsc(x.veh || '&mdash;') + '</span>'
      + '<span>' + rbEsc(x.nm) + '</span>'
      + (x.flag ? '<span class="fl" title="' + rbEsc(x.rm) + '">ISSUE</span>' : '')
      + '<span class="t">' + rbEsc(x.outAt) + '</span></div>';
  });
  if (!RB.done.length) dh = '<div style="color:#A6A9B1;font-size:12px">None yet tonight</div>';
  document.getElementById('rbDone').innerHTML = dh;
  document.getElementById('rbDoneCnt').textContent = RB.done.length ? '(' + RB.done.length + ')' : '';
}

function rbRefresh(cb){
  rbAjax({ requestType:'board' }, function(t){
    try { RB = JSON.parse(t); } catch(e) { }
    rbRender();
    if (cb) cb();
  });
}

/* ── tap -> confirm -> checkout ───────────────────────────── */
function rbArm(ck){
  rbDisarm();
  var el = document.getElementById('rbT' + ck);
  if (el) { el.classList.add('arm'); rbArmTimer = setTimeout(rbDisarm, 6000); }
}
function rbDisarm(){
  clearTimeout(rbArmTimer);
  document.querySelectorAll('.rb-tile.arm').forEach(function(t){ t.classList.remove('arm'); });
}
function rbGood(ck, btn, parking){
  btn.disabled = true;
  rbAjax({ requestType:'boardCheckout', checkinID: ck, mode:'good', parking: parking || '' }, function(resp){
    var m = /<mesg>([^<]*)<\/mesg>/.exec(resp);
    if (resp.indexOf('<status>true') >= 0) { rbToast(m ? m[1] : 'Checked out', true); rbRefresh(); }
    else { rbToast(m ? m[1] : 'Failed', false); btn.disabled = false; }
  });
}

/* check out everything left, one confirm tap (no blocking dialogs) */
var rbAllArmed = false;
function rbAllGood(btn){
  if (!rbAllArmed) {
    rbAllArmed = true;
    btn.textContent = 'Tap again to confirm ' + RB.out.length + ' checkouts';
    setTimeout(function(){ rbAllArmed = false; btn.innerHTML = '&#10003; Check out all remaining'; }, 4000);
    return;
  }
  rbAllArmed = false;
  btn.disabled = true;
  btn.textContent = 'Working\u2026';
  var pend = RB.out.map(function(t){ return t.ck; });
  var i = 0;
  function next(){
    if (i >= pend.length) {
      btn.disabled = false; btn.innerHTML = '&#10003; Check out all remaining';
      rbToast('All remaining checked out', true);
      rbRefresh();
      return;
    }
    rbAjax({ requestType:'boardCheckout', checkinID: pend[i++], mode:'good' }, function(){ next(); });
  }
  next();
}

/* ── exception sheet ──────────────────────────────────────── */
var RB_ITEMS = [
  { k:'postInspection',    l:'Post inspection', s:'DONE' },
  { k:'vehicleClean',      l:'Vehicle clean',   s:'CLEAN' },
  { k:'dispatcherChecked', l:'Dispatcher check',s:'DONE' },
  { k:'calledFromLast',    l:'Called from last stop', s:'YES' },
  { k:'phoneReturned',     l:'Phone',           s:'RETURNED' },
  { k:'gasCardReturned',   l:'Gas card',        s:'RETURNED' },
  { k:'cables',            l:'Cables',          s:'RETURNED' },
  { k:'flashLight',        l:'Flashlight',      s:'RETURNED' },
  { k:'powerBank',         l:'Power bank',      s:'RETURNED' }
];
function rbIssue(ck){
  rbDisarm();
  rbSheetCk = ck;
  var t = null;
  RB.out.forEach(function(x){ if (x.ck === ck) t = x; });
  document.getElementById('rbShTitle').textContent = (t ? t.veh + ' \u00B7 ' + t.nm : 'Issue at return');
  document.getElementById('rbShSub').textContent = t && t.flexOut ? 'FLEX SIGN-OUT ' + t.flexOut : '';
  var h = '';
  RB_ITEMS.forEach(function(it, i){
    h += '<div class="rb-tg" id="rbTg' + i + '" onclick="this.classList.toggle(\'bad\')">' + it.l + '<small>' + it.s + ' &mdash; TAP IF NOT</small></div>';
  });
  document.getElementById('rbToggles').innerHTML = h;
  document.getElementById('rbPkgs').value = '0';
  document.getElementById('rbRemarks').value = '';
  rbPhotoData = '';
  document.getElementById('rbPhotoPrev').style.display = 'none';
  document.getElementById('rbPhotoHint').textContent = 'OPTIONAL WALK-AROUND SHOT';
  document.getElementById('rbSheet').classList.add('open');
  document.getElementById('rbScrim').classList.add('open');
}
function rbSheetClose(){
  document.getElementById('rbSheet').classList.remove('open');
  document.getElementById('rbScrim').classList.remove('open');
}
function rbPkg(d){
  var el = document.getElementById('rbPkgs');
  el.value = Math.max(0, (parseInt(el.value, 10) || 0) + d);
}
function rbParkSet(btn){
  document.querySelectorAll('#rbPark button').forEach(function(b){ b.classList.remove('on'); });
  btn.classList.add('on');
}
function rbParkVal(){
  var b = document.querySelector('#rbPark button.on');
  return b ? b.dataset.v : '1';
}
function rbPhotoPick(inp){
  var f = inp.files && inp.files[0];
  if (!f) return;
  var img = new Image();
  img.onload = function(){
    /* downscale so the POST stays small enough for Tomcat */
    var mx = 1280, sc = Math.min(1, mx / Math.max(img.width, img.height));
    var cv = document.createElement('canvas');
    cv.width = Math.round(img.width * sc);
    cv.height = Math.round(img.height * sc);
    cv.getContext('2d').drawImage(img, 0, 0, cv.width, cv.height);
    rbPhotoData = cv.toDataURL('image/jpeg', 0.72);
    var pv = document.getElementById('rbPhotoPrev');
    pv.src = rbPhotoData; pv.style.display = '';
    document.getElementById('rbPhotoHint').textContent = 'PHOTO ATTACHED (' + Math.round(rbPhotoData.length / 1365) + ' KB)';
    URL.revokeObjectURL(img.src);
  };
  img.src = URL.createObjectURL(f);
}
function rbSheetSave(btn){
  btn.disabled = true;
  var p = { requestType:'boardCheckout', checkinID: rbSheetCk, mode:'except',
            parking: rbParkVal(),
            packagesLeft: document.getElementById('rbPkgs').value || '0',
            remarks: document.getElementById('rbRemarks').value };
  RB_ITEMS.forEach(function(it, i){
    p[it.k] = document.getElementById('rbTg' + i).classList.contains('bad') ? '0' : '1';
  });
  if (rbPhotoData) p.photo = rbPhotoData;
  rbAjax(p, function(resp){
    btn.disabled = false;
    var m = /<mesg>([^<]*)<\/mesg>/.exec(resp);
    if (resp.indexOf('<status>true') >= 0) { rbToast(m ? m[1] : 'Checked out', true); rbSheetClose(); rbRefresh(); }
    else rbToast(m ? m[1] : 'Failed', false);
  });
}

/* ── VIN QR scan (BarcodeDetector where available) ────────── */
var rbQrStream = null, rbQrLoop = null;
if ('BarcodeDetector' in window) document.getElementById('rbQrBtn').style.display = '';
function rbQrOpen(){
  var v = document.getElementById('rbQrVideo');
  navigator.mediaDevices.getUserMedia({ video: { facingMode:'environment' } }).then(function(s){
    rbQrStream = s; v.srcObject = s; v.play();
    document.getElementById('rbQr').classList.add('open');
    var det = new BarcodeDetector({ formats: ['qr_code', 'code_128', 'code_39'] });
    rbQrLoop = setInterval(function(){
      det.detect(v).then(function(codes){
        if (!codes.length) return;
        var raw = (codes[0].rawValue || '').trim();
        if (!raw) return;
        rbQrClose();
        document.getElementById('rbFilter').value = raw;
        rbRender();
        /* exactly one tile matched -> arm it for the confirm tap */
        var vis = [];
        RB.out.forEach(function(t){
          if ((t.veh + ' ' + t.vin + ' ' + t.nm).toLowerCase().indexOf(raw.toLowerCase()) >= 0) vis.push(t.ck);
        });
        if (vis.length === 1) { rbArm(vis[0]); rbToast('Van found', true); }
        else if (!vis.length) rbToast('No open return matches that code', false);
      }).catch(function(){ });
    }, 400);
  }).catch(function(){ rbToast('Camera not available', false); });
}
function rbQrClose(){
  clearInterval(rbQrLoop);
  if (rbQrStream) rbQrStream.getTracks().forEach(function(t){ t.stop(); });
  document.getElementById('rbQr').classList.remove('open');
}

rbRender();
</script>
