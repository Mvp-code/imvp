<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"
         import="java.util.*,com.util.*,com.beans.*" %>
<%
  /* SAMPLE ONLY — Dispatcher open-task board (mock data, no DB writes).
     Open: /MVPx/jsp/DispatcherTaskBoardSample.jsp
     Same board pattern as FleetTaskBoardSample — dispatcher team scope. */
  String dtLoginUser   = request.getAttribute("loginUser") != null ? request.getAttribute("loginUser").toString() : (String) session.getAttribute("loginUser");
  String dtLoginRoles  = request.getAttribute("loginUserRoles") != null ? request.getAttribute("loginUserRoles").toString() : (String) session.getAttribute("loginUserRoles");
  String dtEntityID    = request.getAttribute("entityID") != null ? request.getAttribute("entityID").toString() : (session.getAttribute("entityID") != null ? session.getAttribute("entityID").toString() : "1");
  String dtDispName    = request.getAttribute("loginUserDisplayName") != null ? request.getAttribute("loginUserDisplayName").toString() : (session.getAttribute("loginUserDisplayName") != null ? session.getAttribute("loginUserDisplayName").toString() : "");
  String dtLoginUserID = request.getAttribute("loginUserID") != null ? request.getAttribute("loginUserID").toString() : (session.getAttribute("loginUserID") != null ? session.getAttribute("loginUserID").toString() : "");
  if (dtLoginUser == null) dtLoginUser = "";
  if (dtLoginRoles == null) dtLoginRoles = "";
  if (dtDispName == null || dtDispName.length() == 0) dtDispName = "Dispatcher";
  if (dtEntityID == null || dtEntityID.length() == 0) dtEntityID = "1";

  request.setAttribute("loginUser", dtLoginUser);
  request.setAttribute("loginUserRoles", dtLoginRoles);
  request.setAttribute("entityID", dtEntityID);
  request.setAttribute("loginUserDisplayName", dtDispName);
  request.setAttribute("loginUserID", dtLoginUserID);
  request.setAttribute("shellNoForm", "yes");
  request.setAttribute("hideTopbarSearch", "yes");
%>
<jsp:useBean id="_recordBean" class="com.beans.SearchBean" scope="request" />
<%
  _recordBean.setController("DispatcherTaskBoardSample");
  _recordBean.setDisplayName("Dispatcher Task Board (Sample)");
  int submitType = SubmitType.SEARCH;
%>
<!DOCTYPE html>
<html lang="en">
<%@ include file="includeHeader.jsp"%>
<script>function validatePageData(submitType, isValid) { return isValid; }</script>
<style>
.ft-banner{background:#FEF3C7;border:1px solid #F59E0B;border-radius:8px;padding:8px 12px;font-size:12px;color:#92400E;margin-bottom:10px}
.ft-banner a{color:#92400E;font-weight:800}
.ft-shell{display:flex;flex-direction:column;height:calc(100vh - 96px);overflow:hidden}
.ft-hd{display:flex;align-items:flex-start;gap:12px;flex-wrap:wrap;margin-bottom:8px;flex-shrink:0}
.ft-hd h1{font-size:18px;font-weight:900;color:#0f172a;margin:0}
.ft-hd .sub{font-size:12px;color:#64748B}
.ft-kpis{display:flex;gap:8px;margin-left:auto;flex-wrap:wrap}
.ft-kpi{background:#fff;border:1px solid #E4E8F0;border-radius:8px;padding:5px 12px;text-align:center;min-width:72px;cursor:pointer}
.ft-kpi:hover{border-color:#0f172a}
.ft-kpi.on{border-color:#0f172a;background:#F8FAFC}
.ft-kpi b{display:block;font-size:18px;color:#0f172a;line-height:1.1}
.ft-kpi span{font-size:9.5px;color:#64748B;font-weight:700;text-transform:uppercase;letter-spacing:.04em}
.ft-kpi.red b{color:var(--status-action-fg)}.ft-kpi.amber b{color:var(--status-warn-fg)}.ft-kpi.green b{color:var(--status-ok-fg)}.ft-kpi.blue b{color:var(--status-info-fg)}
.ft-toolbar{display:flex;gap:7px;flex-wrap:wrap;margin-bottom:8px;flex-shrink:0;align-items:center}
.ft-toolbar input,.ft-toolbar select{border:1px solid #CBD5E1;border-radius:7px;padding:6px 9px;font-size:12.5px;background:#fff}
.ft-toolbar .btn{border:1px solid #CBD5E1;background:#fff;border-radius:7px;padding:6px 12px;font-size:12px;font-weight:700;cursor:pointer}
.ft-toolbar .btn.pri{background:#0f172a;border-color:#0f172a;color:#fff}
.ft-view{display:inline-flex;border:1px solid #CBD5E1;border-radius:8px;padding:2px;background:#fff}
.ft-view button{border:none;background:transparent;padding:5px 11px;font-size:12px;font-weight:700;color:#64748B;cursor:pointer;border-radius:6px}
.ft-view button.on{background:#0f172a;color:#fff}
.ft-body{flex:1;min-height:0;overflow:auto}
.ft-board{display:grid;grid-template-columns:repeat(5,minmax(200px,1fr));gap:10px;min-height:100%}
.ft-col{background:#F8FAFC;border:1px solid #E4E8F0;border-radius:10px;display:flex;flex-direction:column;min-height:320px}
.ft-col-h{padding:9px 11px;font-size:11px;font-weight:800;text-transform:uppercase;letter-spacing:.05em;color:#475569;border-bottom:1px solid #E4E8F0;display:flex;align-items:center;gap:6px}
.ft-col-h .n{margin-left:auto;background:#EEF1F6;border-radius:9px;padding:1px 7px;font-size:10px;color:#0f172a}
.ft-col-b{padding:8px;display:flex;flex-direction:column;gap:7px;flex:1;overflow:auto}
.ft-card{background:#fff;border:1px solid #E4E8F0;border-radius:9px;padding:10px;cursor:pointer;transition:border-color .12s}
.ft-card:hover{border-color:#0f172a}
.ft-card .veh{font-weight:800;font-size:13.5px;color:#0f172a}
.ft-card .ty{font-size:11px;color:#64748B;margin-top:2px}
.ft-card .meta{display:flex;gap:6px;flex-wrap:wrap;margin-top:7px}
.ft-pill{display:inline-block;font-size:9.5px;font-weight:800;padding:2px 7px;border-radius:9px;background:#EEF1F6;color:#334155}
.ft-pill.red{background:var(--status-action-bg);color:var(--status-action-fg)}
.ft-pill.amber{background:var(--status-warn-bg);color:var(--status-warn-fg)}
.ft-pill.green{background:var(--status-ok-bg);color:var(--status-ok-fg)}
.ft-pill.blue{background:var(--status-info-bg);color:var(--status-info-fg)}
.ft-pill.escalation{background:var(--status-escalation-bg);color:var(--status-escalation-fg)}
.ft-card .age{font-family:Consolas,monospace;font-size:10px;color:#94A3B8;margin-top:6px}
.ft-tbl{width:100%;border-collapse:collapse;background:#fff;border:1px solid #E4E8F0;border-radius:8px;overflow:hidden}
.ft-tbl th{font-size:10px;text-transform:uppercase;letter-spacing:.04em;color:#64748B;text-align:left;padding:8px 10px;background:#F8FAFC;border-bottom:1px solid #E4E8F0}
.ft-tbl td{font-size:12.5px;padding:8px 10px;border-bottom:1px solid #EEF1F6;vertical-align:middle}
.ft-tbl tr{cursor:pointer}.ft-tbl tr:hover td{background:#F8FAFC}
.ft-scrim{display:none;position:fixed;inset:0;background:rgba(20,21,25,.35);z-index:390}
.ft-scrim.on{display:block}
.ft-drawer{position:fixed;top:0;right:0;width:min(480px,100vw);height:100vh;background:#fff;border-left:1px solid #E4E8F0;box-shadow:-8px 0 30px rgba(0,0,0,.14);z-index:400;padding:14px 18px;overflow:auto;transform:translateX(calc(100% + 40px));visibility:hidden;transition:transform .22s ease,visibility .22s}
.ft-drawer.on{transform:translateX(0);visibility:visible}
.ft-drawer h3{margin:0 0 4px;font-size:16px;display:flex;align-items:center;gap:8px}
.ft-drawer .x{margin-left:auto;border:0;background:transparent;font-size:16px;cursor:pointer;color:#94A3B8}
.ft-drawer .sub{font-size:12px;color:#64748B;margin-bottom:12px}
.ft-steps{display:flex;flex-direction:column;gap:0;margin:12px 0 16px}
.ft-step{display:grid;grid-template-columns:28px 1fr;gap:8px;padding:8px 0}
.ft-step .dot{width:18px;height:18px;border-radius:50%;border:2px solid #CBD5E1;background:#fff;margin-top:2px}
.ft-step.done .dot{background:var(--status-ok-fg);border-color:var(--status-ok-fg)}
.ft-step.done .dot:after{content:'';color:#fff;font-size:10px;font-weight:900;display:flex;align-items:center;justify-content:center;height:100%}
.ft-step.cur .dot{border-color:#0f172a;background:#0f172a;box-shadow:0 0 0 3px rgba(15,23,42,.15)}
.ft-step .lbl{font-size:12.5px;font-weight:700;color:#0f172a}
.ft-step .when{font-size:11px;color:#94A3B8;font-family:Consolas,monospace}
.ft-fgrid{display:grid;grid-template-columns:1fr 1fr;gap:9px}
.ft-fgrid label{display:flex;flex-direction:column;gap:3px;font-size:10px;text-transform:uppercase;letter-spacing:.05em;color:#64748B}
.ft-fgrid input,.ft-fgrid select,.ft-drawer textarea{border:1px solid #CBD5E1;border-radius:7px;padding:7px 9px;font-size:13px;font-family:inherit;background:#FAF9F5}
.ft-actions{display:flex;gap:8px;margin-top:14px;flex-wrap:wrap}
.ft-actions .btn{border:1px solid #CBD5E1;background:#fff;border-radius:7px;padding:7px 14px;font-size:12.5px;font-weight:700;cursor:pointer}
.ft-actions .btn.pri{background:#0f172a;border-color:#0f172a;color:#fff}
.ft-actions .btn.ok{border-color:var(--status-ok-fg);color:var(--status-ok-fg)}
.ft-timeline{border-top:1px solid #EEF1F6;margin-top:14px;padding-top:10px}
.ft-timeline h4{font-size:11px;text-transform:uppercase;letter-spacing:.05em;color:#64748B;margin:0 0 8px}
.ft-tl{font-size:12px;padding:6px 0;border-bottom:1px solid #F1F5F9}
.ft-tl .t{font-family:Consolas,monospace;font-size:10px;color:#94A3B8}
.ft-tl .m{color:#1F2937;margin-top:1px}
@media(max-width:1100px){.ft-board{grid-template-columns:repeat(2,1fr)}}
@media(max-width:700px){.ft-board{grid-template-columns:1fr}}
</style>

<div class="ft-shell">
  <div class="ft-banner">
    <b>SAMPLE / REVIEW ONLY</b> — Dispatcher team open tasks (mock data).
    Same board pattern as <a href="FleetTaskBoardSample.jsp">Fleet Task Board</a>.
  </div>

  <div class="ft-hd">
    <div>
      <h1><i class="fa fa-headphones"></i> Dispatcher Task Board</h1>
      <div class="sub">Open dispatch work · track every sub-status until closed · sample data</div>
    </div>
    <div class="ft-kpis">
      <div class="ft-kpi on" data-f="" onclick="ftKpi(this,'')"><b id="kAll">9</b><span>Open</span></div>
      <div class="ft-kpi red" data-f="overdue" onclick="ftKpi(this,'overdue')"><b id="kOver">2</b><span>Overdue</span></div>
      <div class="ft-kpi amber" data-f="waiting" onclick="ftKpi(this,'waiting')"><b id="kWait">2</b><span>Waiting</span></div>
      <div class="ft-kpi blue" data-f="progress" onclick="ftKpi(this,'progress')"><b id="kProg">3</b><span>In progress</span></div>
      <div class="ft-kpi green" data-f="ready" onclick="ftKpi(this,'ready')"><b id="kReady">1</b><span>Ready to close</span></div>
    </div>
  </div>

  <div class="ft-toolbar">
    <input id="ftQ" placeholder="DA, route, vehicle…" oninput="ftRender()" style="min-width:160px">
    <select id="ftType" onchange="ftRender()">
      <option value="">All types</option>
      <option>Rescue</option>
      <option>Coaching</option>
      <option>Safety follow-up</option>
      <option>Dispute</option>
      <option>RTS follow-up</option>
      <option>Contact compliance</option>
      <option>Route note</option>
      <option>Escalation</option>
    </select>
    <select id="ftPri" onchange="ftRender()">
      <option value="">All priorities</option>
      <option>Critical</option>
      <option>High</option>
      <option>Normal</option>
    </select>
    <select id="ftOwn" onchange="ftRender()">
      <option value="">All owners</option>
      <option>Alex — Dispatch</option>
      <option>Jordan — Dispatch</option>
      <option>Sam — Lead</option>
    </select>
    <div class="ft-view">
      <button type="button" class="on" id="ftVBoard" onclick="ftView('board')">Board</button>
      <button type="button" id="ftVList" onclick="ftView('list')">List</button>
    </div>
    <button type="button" class="btn pri" style="margin-left:auto" onclick="ftNew()">+ New task</button>
  </div>

  <div class="ft-body">
    <div id="ftBoard" class="ft-board"></div>
    <div id="ftList" style="display:none"></div>
  </div>
</div>

<div class="ft-scrim" id="ftScrim" onclick="ftClose()"></div>
<div class="ft-drawer" id="ftDrawer">
  <h3><span id="ftDrTitle">Task</span><button type="button" class="x" onclick="ftClose()">&#10005;</button></h3>
  <div class="sub" id="ftDrSub"></div>
  <div class="ft-steps" id="ftSteps"></div>
  <div class="ft-fgrid">
    <label>Sub-status<select id="ftSubSt"></select></label>
    <label>Priority<select id="ftDrPri"><option>Critical</option><option>High</option><option>Normal</option></select></label>
    <label>Owner (dispatcher)<input id="ftDrOwn"></label>
    <label>Route / vehicle<input id="ftDrRoute"></label>
    <label>Due date<input type="date" id="ftDrDue"></label>
    <label>Follow-up by<input type="date" id="ftDrEta"></label>
  </div>
  <label style="display:block;margin-top:8px;font-size:10px;text-transform:uppercase;letter-spacing:.05em;color:#64748B">Update note
    <textarea id="ftDrNote" rows="2" style="width:100%;margin-top:3px;border:1px solid #CBD5E1;border-radius:7px;padding:7px 9px;font-size:13px;box-sizing:border-box"></textarea>
  </label>
  <div class="ft-actions">
    <button type="button" class="btn" onclick="ftAdvance()">Advance status</button>
    <button type="button" class="btn pri" onclick="ftSave()">Save update</button>
    <button type="button" class="btn ok" onclick="ftCloseTask()">Mark closed</button>
  </div>
  <div class="ft-timeline">
    <h4>Activity trail</h4>
    <div id="ftTrail"></div>
  </div>
</div>

<script>
var FT_PIPELINE = [
  { id:'opened',   label:'Opened' },
  { id:'assigned', label:'Assigned' },
  { id:'progress', label:'In progress' },
  { id:'waiting',  label:'Waiting (DA / station)' },
  { id:'ready',    label:'Ready to close' },
  { id:'closed',   label:'Closed' }
];

/* title = DA name; route = route/vehicle context */
var FT_TASKS = [
  { id:1, title:'Prince Brandon Onukogu', route:'R12 · CDV-17', type:'Coaching', pri:'High', owner:'Alex — Dispatch',
    sub:'progress', due:'2026-09-06', eta:'2026-09-06', age:'2d', overdue:false,
    trail:[
      { t:'09/04 09:00', u:'alex', m:'Opened — 2nd consecutive week DSB flag (no photo ×2)' },
      { t:'09/04 09:15', u:'alex', m:'Assigned to self' },
      { t:'09/05 07:30', u:'alex', m:'In progress — pre-wave coaching scheduled' }
    ]},
  { id:2, title:'Alejandro Carmona', route:'R08 · AeroBLUE', type:'Rescue', pri:'Critical', owner:'Jordan — Dispatch',
    sub:'progress', due:'2026-09-05', eta:'', age:'0d', overdue:false,
    trail:[
      { t:'09/05 17:45', u:'jordan', m:'Opened — 42 stops open at 17:45, heavy apartments' },
      { t:'09/05 17:50', u:'jordan', m:'In progress — rescue van rolling, SCC pickup check' }
    ]},
  { id:3, title:'Randy Angel Cruz', route:'R21', type:'Safety follow-up', pri:'Critical', owner:'Sam — Lead',
    sub:'waiting', due:'2026-09-04', eta:'2026-09-05', age:'3d', overdue:true,
    trail:[
      { t:'09/03 08:10', u:'sam', m:'Opened — 2 speeding events same shift (14:57, 18:37)' },
      { t:'09/03 08:20', u:'sam', m:'Assigned' },
      { t:'09/04 16:00', u:'sam', m:'Waiting — DA off tomorrow; coaching booked next shift' }
    ]},
  { id:4, title:'Station — Merchants van', route:'CDV-12', type:'Dispute', pri:'High', owner:'Alex — Dispatch',
    sub:'waiting', due:'2026-09-03', eta:'', age:'5d', overdue:true,
    trail:[
      { t:'08/31 11:00', u:'alex', m:'Opened — 3 speeding same driver/van/day (map-error pattern)' },
      { t:'09/01 14:00', u:'alex', m:'Waiting — dispute filed, awaiting Amazon decision' }
    ]},
  { id:5, title:'Abdiel Aosta', route:'R03', type:'RTS follow-up', pri:'High', owner:'Jordan — Dispatch',
    sub:'assigned', due:'2026-09-06', eta:'', age:'1d', overdue:false,
    trail:[
      { t:'09/04 20:10', u:'jordan', m:'Opened — 3 Unable To Access at same complex' },
      { t:'09/05 07:00', u:'jordan', m:'Assigned — need gate code in route notes' }
    ]},
  { id:6, title:'Wave focus — POD', route:'All routes', type:'Contact compliance', pri:'Normal', owner:'Sam — Lead',
    sub:'progress', due:'2026-09-07', eta:'', age:'4d', overdue:false,
    trail:[
      { t:'09/01 06:30', u:'sam', m:'Opened — week focus: call before improvising (UTA/NSL)' },
      { t:'09/02 06:30', u:'sam', m:'In progress — morning script live' }
    ]},
  { id:7, title:'Complex — Harbor Apts', route:'R08 / R12', type:'Route note', pri:'Normal', owner:'Alex — Dispatch',
    sub:'ready', due:'2026-09-05', eta:'2026-09-05', age:'2d', overdue:false,
    trail:[
      { t:'09/03 19:00', u:'alex', m:'Opened — 8 UTA returns last week, missing gate code' },
      { t:'09/05 10:00', u:'alex', m:'Ready to close — note written; confirm on next itinerary' }
    ]},
  { id:8, title:'Customer escalation smell', route:'R15', type:'Escalation', pri:'Critical', owner:'Sam — Lead',
    sub:'opened', due:'2026-09-05', eta:'', age:'0d', overdue:false,
    trail:[
      { t:'09/05 14:20', u:'jordan', m:'Opened — customer complaint language; escalate to management (protect CED)' }
    ]},
  { id:9, title:'Paul Frank Jamorski', route:'R19', type:'Coaching', pri:'High', owner:'Alex — Dispatch',
    sub:'assigned', due:'2026-09-08', eta:'', age:'1d', overdue:false,
    trail:[
      { t:'09/04 12:00', u:'alex', m:'Opened — no camera data → CED/DC/DSB weight 26.7% each' },
      { t:'09/05 08:00', u:'alex', m:'Assigned — chase telematics + protect quality weight' }
    ]}
];

var FT_VIEW = 'board';
var FT_KPI = '';
var FT_CUR = null;

function ftPriPill(p) {
  return '<span class="ft-pill ' + (p==='Critical'?'red':p==='High'?'amber':'') + '">' + p + '</span>';
}
function ftSubLabel(id) {
  for (var i=0;i<FT_PIPELINE.length;i++) if (FT_PIPELINE[i].id===id) return FT_PIPELINE[i].label;
  return id;
}
function ftFiltered() {
  var q = (document.getElementById('ftQ').value||'').toLowerCase();
  var ty = document.getElementById('ftType').value;
  var pr = document.getElementById('ftPri').value;
  var ow = document.getElementById('ftOwn').value;
  return FT_TASKS.filter(function(t){
    if (t.sub === 'closed') return false;
    if (FT_KPI === 'overdue' && !t.overdue) return false;
    if (FT_KPI === 'waiting' && t.sub !== 'waiting') return false;
    if (FT_KPI === 'progress' && t.sub !== 'progress') return false;
    if (FT_KPI === 'ready' && t.sub !== 'ready') return false;
    if (ty && t.type !== ty) return false;
    if (pr && t.pri !== pr) return false;
    if (ow && t.owner !== ow) return false;
    if (q && (t.title+' '+t.route+' '+t.type+' '+t.owner).toLowerCase().indexOf(q) < 0) return false;
    return true;
  });
}
function ftRender() {
  var rows = ftFiltered();
  document.getElementById('kAll').textContent = FT_TASKS.filter(function(t){return t.sub!=='closed'}).length;
  document.getElementById('kOver').textContent = FT_TASKS.filter(function(t){return t.overdue && t.sub!=='closed'}).length;
  document.getElementById('kWait').textContent = FT_TASKS.filter(function(t){return t.sub==='waiting'}).length;
  document.getElementById('kProg').textContent = FT_TASKS.filter(function(t){return t.sub==='progress'}).length;
  document.getElementById('kReady').textContent = FT_TASKS.filter(function(t){return t.sub==='ready'}).length;

  if (FT_VIEW === 'list') {
    document.getElementById('ftBoard').style.display = 'none';
    document.getElementById('ftList').style.display = '';
    var h = '<table class="ft-tbl"><thead><tr><th>DA / subject</th><th>Type</th><th>Sub-status</th><th>Priority</th><th>Owner</th><th>Route</th><th>Due</th><th>Age</th></tr></thead><tbody>';
    rows.forEach(function(t){
      h += '<tr onclick="ftOpen('+t.id+')"><td><b>'+t.title+'</b></td><td>'+t.type+'</td>'
        + '<td><span class="ft-pill blue">'+ftSubLabel(t.sub)+'</span></td><td>'+ftPriPill(t.pri)+'</td>'
        + '<td>'+t.owner+'</td><td>'+t.route+'</td>'
        + '<td>'+(t.due||'—')+(t.overdue?' <span class="ft-pill red">overdue</span>':'')+'</td><td>'+t.age+'</td></tr>';
    });
    if (!rows.length) h += '<tr><td colspan="8" style="text-align:center;color:#94A3B8;padding:24px">No open tasks match.</td></tr>';
    h += '</tbody></table>';
    document.getElementById('ftList').innerHTML = h;
    return;
  }
  document.getElementById('ftBoard').style.display = '';
  document.getElementById('ftList').style.display = 'none';
  var cols = FT_PIPELINE.filter(function(p){ return p.id !== 'closed'; });
  var html = '';
  cols.forEach(function(c){
    var cards = rows.filter(function(t){ return t.sub === c.id; });
    html += '<div class="ft-col"><div class="ft-col-h">'+c.label+'<span class="n">'+cards.length+'</span></div><div class="ft-col-b">';
    cards.forEach(function(t){
      html += '<div class="ft-card" onclick="ftOpen('+t.id+')"><div class="veh">'+t.title+'</div>'
        + '<div class="ty">'+t.type+' · '+t.route+'</div>'
        + '<div class="meta">'+ftPriPill(t.pri)+(t.overdue?' <span class="ft-pill red">overdue</span>':'')
        + ' <span class="ft-pill">'+t.owner.split('—')[0].trim()+'</span></div>'
        + '<div class="age">'+t.age+' open · due '+(t.due||'—')+'</div></div>';
    });
    if (!cards.length) html += '<div style="font-size:11px;color:#94A3B8;padding:8px;text-align:center">Empty</div>';
    html += '</div></div>';
  });
  document.getElementById('ftBoard').innerHTML = html;
}
function ftView(v) {
  FT_VIEW = v;
  document.getElementById('ftVBoard').classList.toggle('on', v==='board');
  document.getElementById('ftVList').classList.toggle('on', v==='list');
  ftRender();
}
function ftKpi(el, f) {
  document.querySelectorAll('.ft-kpi').forEach(function(k){ k.classList.remove('on'); });
  el.classList.add('on');
  FT_KPI = f;
  ftRender();
}
function ftOpen(id) {
  var t = null;
  for (var i=0;i<FT_TASKS.length;i++) if (FT_TASKS[i].id===id) t = FT_TASKS[i];
  if (!t) return;
  FT_CUR = t;
  document.getElementById('ftDrTitle').textContent = t.type + ' · ' + t.title;
  document.getElementById('ftDrSub').textContent = t.route + ' · Owner: ' + t.owner;
  document.getElementById('ftDrPri').value = t.pri;
  document.getElementById('ftDrOwn').value = t.owner;
  document.getElementById('ftDrRoute').value = t.route;
  document.getElementById('ftDrDue').value = t.due || '';
  document.getElementById('ftDrEta').value = t.eta || '';
  document.getElementById('ftDrNote').value = '';
  var sel = document.getElementById('ftSubSt');
  sel.innerHTML = '';
  FT_PIPELINE.forEach(function(p){
    var o = document.createElement('option'); o.value = p.id; o.text = p.label;
    if (p.id === t.sub) o.selected = true;
    sel.add(o);
  });
  var idx = FT_PIPELINE.findIndex(function(p){ return p.id === t.sub; });
  var steps = '';
  FT_PIPELINE.forEach(function(p, i){
    var cls = i < idx ? 'done' : (i === idx ? 'cur' : '');
    steps += '<div class="ft-step '+cls+'"><div class="dot"></div><div><div class="lbl">'+p.label+'</div>'
      + (i===idx?'<div class="when">current</div>':'')+'</div></div>';
  });
  document.getElementById('ftSteps').innerHTML = steps;
  var trail = '';
  (t.trail||[]).slice().reverse().forEach(function(x){
    trail += '<div class="ft-tl"><div class="t">'+x.t+' · '+x.u+'</div><div class="m">'+x.m+'</div></div>';
  });
  document.getElementById('ftTrail').innerHTML = trail || '<div class="ft-tl"><div class="m">No activity yet.</div></div>';
  document.getElementById('ftScrim').classList.add('on');
  document.getElementById('ftDrawer').classList.add('on');
}
function ftClose() {
  document.getElementById('ftScrim').classList.remove('on');
  document.getElementById('ftDrawer').classList.remove('on');
  FT_CUR = null;
}
function ftSave() {
  if (!FT_CUR) return;
  FT_CUR.sub = document.getElementById('ftSubSt').value;
  FT_CUR.pri = document.getElementById('ftDrPri').value;
  FT_CUR.owner = document.getElementById('ftDrOwn').value;
  FT_CUR.route = document.getElementById('ftDrRoute').value;
  FT_CUR.due = document.getElementById('ftDrDue').value;
  FT_CUR.eta = document.getElementById('ftDrEta').value;
  var note = document.getElementById('ftDrNote').value.trim();
  FT_CUR.trail.push({ t:'now', u:'you', m:(note||'Updated')+' → '+ftSubLabel(FT_CUR.sub) });
  alert('Sample only — status updated in this page session, not saved to DB.');
  ftClose(); ftRender();
}
function ftAdvance() {
  if (!FT_CUR) return;
  var idx = FT_PIPELINE.findIndex(function(p){ return p.id === FT_CUR.sub; });
  if (idx < FT_PIPELINE.length - 1) document.getElementById('ftSubSt').value = FT_PIPELINE[idx+1].id;
}
function ftCloseTask() {
  if (!FT_CUR) return;
  document.getElementById('ftSubSt').value = 'closed';
  ftSave();
}
function ftNew() {
  alert('Sample only — New Task form will be wired after we lock dispatcher task types.');
}
ftRender();
</script>

<%@ include file="includeFooter.jsp"%>
