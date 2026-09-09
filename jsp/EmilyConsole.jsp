<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"
         import="java.sql.*,javax.sql.*,javax.naming.*,java.util.*,com.util.*,com.beans.*" %>
<%
  /* ── Emily Console (Phase 0) — dispatcher UI + call simulator ──
     Same standalone-JSP shell pattern as DAOnboarding.jsp. All data comes
     from ../api/emily/console-data; the simulator posts ../api/emily/simulate. */
  String emLoginUser   = (request.getAttribute("loginUser") != null) ? request.getAttribute("loginUser").toString() : (String) session.getAttribute("loginUser");
  String emLoginRoles  = (request.getAttribute("loginUserRoles") != null) ? request.getAttribute("loginUserRoles").toString() : (String) session.getAttribute("loginUserRoles");
  String emEntityID    = (request.getAttribute("entityID") != null) ? request.getAttribute("entityID").toString() : (session.getAttribute("entityID") != null ? session.getAttribute("entityID").toString() : "1");
  String emDispName    = (request.getAttribute("loginUserDisplayName") != null) ? request.getAttribute("loginUserDisplayName").toString() : (session.getAttribute("loginUserDisplayName") != null ? session.getAttribute("loginUserDisplayName").toString() : "");
  String emLoginUserID = (request.getAttribute("loginUserID") != null) ? request.getAttribute("loginUserID").toString() : (session.getAttribute("loginUserID") != null ? session.getAttribute("loginUserID").toString() : "");
  if (emLoginUser == null)  emLoginUser  = "";
  if (emLoginRoles == null) emLoginRoles = "";
  if (emDispName == null || emDispName.length() == 0) emDispName = "Dispatcher";

  /* caller dropdown: drivers on the newest route date who have a mobile —
     these are the phones the simulator can "call in" from */
  List<String[]> simCallers = new ArrayList<String[]>();
  String dbError = "";
  Connection conn = null;
  try {
    Context ictx = new InitialContext();
    DataSource ds = (DataSource) ictx.lookup("java:comp/env/jdbc/MVPGDB");
    conn = ds.getConnection();
    PreparedStatement ps = conn.prepareStatement(
      "SELECT E.FULLNAME, C.MOBILE, RA.ROUTE " +
      "FROM route_assignment RA JOIN employee E ON E.EMPLOYEEID=RA.EMPLOYEEID " +
      "JOIN contact C ON C.CONTACTID=E.CONTACTID " +
      /* only drivers with an itinerary the same day - callers who are truly
         on-road, so RTS/rescue rules see real stop data */
      "JOIN daily_itineraries DI ON DI.TRANSPORTERID=RA.TRANSPORTERID " +
      "  AND DATE(DI.ITINARARYDATE)=DATE(RA.ASSIGN_DATE) AND DI.STATUS!=1 " +
      "WHERE RA.STATUS!=1 AND IFNULL(C.MOBILE,'')<>'' " +
      "AND DATE(RA.ASSIGN_DATE)=(SELECT MAX(DATE(ASSIGN_DATE)) FROM route_assignment WHERE STATUS!=1) " +
      "ORDER BY E.FULLNAME LIMIT 10");
    ResultSet rs = ps.executeQuery();
    while (rs.next())
      simCallers.add(new String[]{ rs.getString(1), rs.getString(2), rs.getString(3) });
    rs.close(); ps.close();
  } catch (Exception ex) {
    dbError = String.valueOf(ex.getMessage());
  } finally {
    if (conn != null) try { conn.close(); } catch (Exception e) {}
  }
%>
<jsp:useBean id="_recordBean" class="com.beans.SearchBean" scope="request" />
<jsp:useBean id="_errorBean" class="com.beans.ErrorBean" scope="request" />
<%
int submitType = SubmitType.SEARCH;
_recordBean.setController("EmilyConsole");
_recordBean.setDisplayName("Emily Console");
request.setAttribute("loginUser", emLoginUser);
request.setAttribute("loginUserRoles", emLoginRoles);
request.setAttribute("entityID", emEntityID);
request.setAttribute("loginUserDisplayName", emDispName);
request.setAttribute("loginUserID", emLoginUserID);
request.setAttribute("shellNoForm", "yes");
request.setAttribute("hideTopbarSearch", "yes");
%>
<!DOCTYPE html>
<html lang="en">
<%@ include file="includeHeader.jsp"%>
<script>
function validatePageData(submitType, isValid) { return isValid; }
</script>
<style>
.em-shell{display:flex;flex-direction:column;height:calc(100vh - 96px);overflow:hidden}
.em-hdr{display:flex;align-items:center;gap:12px;margin-bottom:8px;flex-wrap:wrap;flex-shrink:0}
.em-hdr h1{font-size:18px;font-weight:900;color:#0f172a;margin:0}
.em-badge{background:#0f172a;color:#fff;font-size:10px;font-weight:800;letter-spacing:.08em;padding:3px 9px;border-radius:6px}
.em-badge.sim{background:#B45309}
.em-kpis{display:flex;gap:8px;margin-left:auto;flex-wrap:wrap}
.em-kpi{background:#fff;border:1px solid #E4E8F0;border-radius:8px;padding:4px 12px;text-align:center}
.em-kpi b{display:block;font-size:16px;color:#0f172a;line-height:1.1}
.em-kpi span{font-size:10px;color:#64748B;font-weight:700;text-transform:uppercase;letter-spacing:.04em}
.em-tabs{display:flex;gap:4px;border-bottom:2px solid #E4E8F0;margin-bottom:8px;flex-shrink:0}
.em-tab{border:none;background:none;padding:7px 14px;font-size:13px;font-weight:700;color:#64748B;cursor:pointer;border-bottom:2px solid transparent;margin-bottom:-2px}
.em-tab.active{color:#0f172a;border-bottom-color:#0f172a}
.em-tab .cnt{background:#EEF1F6;border-radius:9px;font-size:10px;padding:1px 7px;margin-left:4px;color:#334155}
.em-tab .cnt.hot{background:#C62828;color:#fff}
.em-body{flex:1;overflow:auto;min-height:0}
.em-pane{display:none}.em-pane.active{display:block}
.em-tbl{width:100%;border-collapse:collapse;background:#fff;border:1px solid #E4E8F0;border-radius:8px;overflow:hidden}
.em-tbl th{font-size:10px;text-transform:uppercase;letter-spacing:.05em;color:#64748B;text-align:left;padding:7px 10px;background:#F8FAFC;border-bottom:1px solid #E4E8F0}
.em-tbl td{font-size:12.5px;color:#1F2937;padding:7px 10px;border-bottom:1px solid #EEF1F6;vertical-align:top}
.em-tbl tr:hover td{background:#F8FAFC}
.em-pill{display:inline-block;font-size:10.5px;font-weight:800;padding:2px 9px;border-radius:10px;background:#EEF1F6;color:#334155}
.em-pill.green{background:#E7F6EE;color:#15803D}.em-pill.red{background:#FCEBEB;color:#C62828}
.em-pill.amber{background:#FBF1E2;color:#B45309}.em-pill.blue{background:#EFF4FF;color:#1D4ED8}
.em-btn{border:1px solid #CBD5E1;background:#fff;color:#0f172a;font-size:12px;font-weight:700;padding:4px 12px;border-radius:7px;cursor:pointer}
.em-btn:hover{background:#F1F5F9}
.em-btn.pri{background:#0f172a;border-color:#0f172a;color:#fff}
.em-btn.ok{border-color:#15803D;color:#15803D}.em-btn.no{border-color:#C62828;color:#C62828}
.em-grid{display:grid;grid-template-columns:340px 1fr;gap:10px;height:100%;min-height:0}
.em-card{background:#fff;border:1px solid #E4E8F0;border-radius:8px;padding:12px}
.em-card h3{margin:0 0 8px;font-size:12px;font-weight:900;color:#0f172a;text-transform:uppercase;letter-spacing:.05em}
.em-fld{display:block;font-size:11px;font-weight:700;color:#475569;margin:8px 0 3px}
.em-in,.em-sel,.em-ta{width:100%;border:1px solid #CBD5E1;border-radius:7px;padding:6px 9px;font-size:13px;color:#0f172a;background:#fff;box-sizing:border-box}
.em-ta{resize:vertical}
.em-steps{font-family:Consolas,monospace;font-size:11.5px;background:#0f172a;color:#E2E8F0;border-radius:8px;padding:10px;white-space:pre-wrap;max-height:340px;overflow:auto}
.em-step-rule{color:#7DD3FC;font-weight:700}
.em-runrow{display:flex;gap:8px;margin-top:10px}
.em-passfail{margin-top:8px}
.em-passfail div{font-size:12px;padding:3px 8px;border-radius:6px;margin-bottom:3px}
.em-passfail .p{background:#E7F6EE;color:#15803D}.em-passfail .f{background:#FCEBEB;color:#C62828}
.em-cfgin{width:130px;border:1px solid #CBD5E1;border-radius:6px;padding:4px 8px;font-size:12.5px}
.em-drawer{position:fixed;top:0;right:-560px;width:540px;height:100vh;background:#fff;border-left:1px solid #E4E8F0;box-shadow:-8px 0 24px rgba(15,23,42,.12);z-index:60;transition:right .18s;padding:16px;overflow:auto}
.em-drawer.open{right:0}
.em-empty{color:#94A3B8;font-size:12.5px;padding:14px;text-align:center}
</style>

<div class="em-shell">
  <div class="em-hdr">
    <h1><i class="fas fa-headset"></i>&nbsp;Emily Console</h1>
    <span class="em-badge">PHASE 0</span>
    <span class="em-badge sim" id="emSimBadge" style="display:none">SIMULATOR MODE &mdash; no live calls yet</span>
    <div class="em-kpis" id="emKpis"></div>
  </div>

  <div class="em-tabs">
    <button class="em-tab active" data-pane="sim" onclick="emTab(this)">Simulator</button>
    <button class="em-tab" data-pane="live" onclick="emTab(this)">Live <span class="cnt" id="cntLive">0</span></button>
    <button class="em-tab" data-pane="rescue" onclick="emTab(this)">Rescues <span class="cnt" id="cntRescue">0</span></button>
    <button class="em-tab" data-pane="calls" onclick="emTab(this)">Call Log <span class="cnt" id="cntCalls">0</span></button>
    <button class="em-tab" data-pane="qa" onclick="emTab(this)">QA <span class="cnt" id="cntQa">0</span></button>
    <button class="em-tab" data-pane="config" onclick="emTab(this)">Config</button>
  </div>

  <div class="em-body">

    <div class="em-pane active" id="pane-sim">
      <div class="em-grid">
        <div class="em-card">
          <h3><i class="fas fa-phone"></i>&nbsp;Place a test call</h3>
          <label class="em-fld">Caller</label>
          <select class="em-sel" id="simCaller">
            <%for (String[] sc : simCallers) {%>
            <option value="<%=sc[1]%>"><%=sc[0]%> &mdash; <%=sc[2]%></option>
            <%}%>
            <option value="0000000000">Unknown caller (not in system)</option>
          </select>
          <label class="em-fld">Preset scenario</label>
          <select class="em-sel" id="simPreset" onchange="emPresetPick()"><option value="">&mdash; custom &mdash;</option></select>
          <label class="em-fld">What the driver says</label>
          <textarea class="em-ta" id="simUtterance" rows="2" placeholder="I'm done with my route, heading back"></textarea>
          <div style="display:flex;gap:8px">
            <div style="flex:1"><label class="em-fld">Override data age (min)</label>
            <input class="em-in" id="simAge" placeholder="auto"></div>
            <div style="flex:1"><label class="em-fld">Override stops done</label>
            <input class="em-in" id="simStops" placeholder="auto"></div>
          </div>
          <div class="em-runrow">
            <button class="em-btn pri" onclick="emRunSim()"><i class="fas fa-play"></i> Run call</button>
            <button class="em-btn" onclick="emRunAll(this)"><i class="fas fa-list-check"></i> Run all presets</button>
          </div>
          <div class="em-passfail" id="simPassFail"></div>
          <%if (dbError.length() > 0 && !"null".equals(dbError)) {%><div class="em-empty">DB: <%=dbError%></div><%}%>
        </div>
        <div class="em-card">
          <h3><i class="fas fa-diagram-project"></i>&nbsp;Decision trace</h3>
          <div class="em-steps" id="simSteps">Pick a caller and a scenario, then Run call.
Every step below is exactly what the live voice vendor will trigger in Phase 1 &mdash; same endpoints, same rules, same audit rows.</div>
        </div>
      </div>
    </div>

    <div class="em-pane" id="pane-live">
      <table class="em-tbl"><thead><tr><th style="width:70px">Priority</th><th>Who</th><th>Reason</th><th style="width:130px">When</th><th style="width:110px"></th></tr></thead>
      <tbody id="tbLive"></tbody></table>
    </div>

    <div class="em-pane" id="pane-rescue">
      <table class="em-tbl"><thead><tr><th>Target (behind)</th><th>Helper (proposed)</th><th style="width:90px">Score</th><th style="width:90px">Stop gap</th><th style="width:80px">Status</th><th style="width:130px">When</th><th style="width:160px"></th></tr></thead>
      <tbody id="tbRescue"></tbody></table>
    </div>

    <div class="em-pane" id="pane-calls">
      <table class="em-tbl"><thead><tr><th style="width:120px">When</th><th>Caller</th><th style="width:100px">Intent</th><th style="width:100px">Outcome</th><th style="width:60px">Sec</th><th style="width:60px">Sim</th><th style="width:70px">QA</th><th style="width:80px"></th></tr></thead>
      <tbody id="tbCalls"></tbody></table>
    </div>

    <div class="em-pane" id="pane-qa">
      <div class="em-empty" style="text-align:left;padding:8px 2px">Every call can be graded once. Fails feed the prompt/rule backlog &mdash; the QA error rate on the KPI strip is the gate for expanding Emily's autonomy.</div>
      <table class="em-tbl"><thead><tr><th style="width:120px">When</th><th>Caller</th><th style="width:100px">Intent</th><th style="width:100px">Outcome</th><th>Transcript</th><th style="width:280px">Grade</th></tr></thead>
      <tbody id="tbQa"></tbody></table>
    </div>

    <div class="em-pane" id="pane-config">
      <table class="em-tbl"><thead><tr><th style="width:190px">Setting</th><th style="width:160px">Value</th><th>What it does</th><th style="width:190px">Last change</th></tr></thead>
      <tbody id="tbCfg"></tbody></table>
    </div>

  </div>
</div>

<div class="em-drawer" id="emDrawer">
  <div style="display:flex;justify-content:space-between;align-items:center">
    <h3 style="margin:0;font-size:14px;font-weight:900">Call #<span id="drCallId"></span> &mdash; decision trail</h3>
    <button class="em-btn" onclick="document.getElementById('emDrawer').classList.remove('open')">&#10005;</button>
  </div>
  <div id="drBody" style="margin-top:10px"></div>
</div>

<script>
var EM = {data:null, user:'<%=emDispName.replace("'","")%>'};

/* ── preset regression scenarios: expected outcomes are asserted ── */
var EM_PRESETS = [
 {n:'RTS &mdash; clean return',            u:"I'm done with my route, heading back",          age:'5',  stops:'999', expect:['resolved']},
 {n:'RTS &mdash; stale route data',        u:"I'm finished, can I return to station?",        age:'60', stops:'',    expect:['escalated']},
 {n:'RTS &mdash; stops incomplete',        u:"I'm done, coming back now",                     age:'5',  stops:'1',   expect:['callback']},
 {n:'Package &mdash; 2 damaged in van',    u:"I have 2 damaged packages in my van",           age:'',   stops:'',    expect:['resolved']},
 {n:'Package &mdash; 25 over cap',         u:"I have 25 damaged packages",                    age:'',   stops:'',    expect:['callback']},
 {n:'Package &mdash; missort',             u:"Got a missort package for another route",       age:'',   stops:'',    expect:['resolved']},
 {n:'Emergency &mdash; accident',          u:"I just got in an accident",                     age:'',   stops:'',    expect:['escalated']},
 {n:'Emergency &mdash; dog bite',          u:"A dog bit me at the last stop",                 age:'',   stops:'',    expect:['escalated']},
 {n:'Rescue &mdash; way behind',           u:"I'm way behind, I need a rescue",               age:'',   stops:'',    expect:['resolved','escalated']},
 {n:'Device &mdash; app frozen',           u:"My flex app is frozen",                         age:'',   stops:'',    expect:['resolved']},
 {n:'Device &mdash; dead, blocked',        u:"My phone is dead and I can't deliver",          age:'',   stops:'',    expect:['escalated']},
 {n:'Callout &mdash; sick',                u:"I'm sick, calling out for tomorrow",            age:'',   stops:'',    expect:['resolved']},
 {n:'Unknown caller',                      u:"Where is my route today?",  phone:'0000000000', age:'',   stops:'',    expect:['escalated']},
 {n:'Unknown intent &mdash; paycheck',     u:"I want to talk about my paycheck",              age:'',   stops:'',    expect:['callback']},
 {n:'Rescue &mdash; asks but not behind',  u:"Can someone take stops off me? I need help",    age:'',   stops:'',    expect:['resolved','escalated']}
];
(function(){
  var sel = document.getElementById('simPreset');
  EM_PRESETS.forEach(function(p, i){
    var o = document.createElement('option'); o.value = i; o.innerHTML = p.n; sel.appendChild(o);
  });
})();
function emPresetPick(){
  var i = document.getElementById('simPreset').value;
  if (i === '') return;
  var p = EM_PRESETS[+i];
  document.getElementById('simUtterance').value = p.u;
  document.getElementById('simAge').value = p.age;
  document.getElementById('simStops').value = p.stops;
  if (p.phone) document.getElementById('simCaller').value = p.phone;
}

function emTab(btn){
  document.querySelectorAll('.em-tab').forEach(function(t){ t.classList.remove('active'); });
  document.querySelectorAll('.em-pane').forEach(function(p){ p.classList.remove('active'); });
  btn.classList.add('active');
  document.getElementById('pane-' + btn.dataset.pane).classList.add('active');
}

function esc(s){ var d = document.createElement('div'); d.textContent = s == null ? '' : s; return d.innerHTML; }
function pill(t, cls){ return '<span class="em-pill ' + cls + '">' + esc(t) + '</span>'; }
function outPill(o){
  return o === 'resolved' ? pill(o,'green') : o === 'escalated' ? pill(o,'red')
       : o === 'callback' ? pill(o,'amber') : pill(o,'');
}

/* ── data refresh ── */
function emLoad(){
  fetch('../api/emily/console-data').then(function(r){ return r.json(); }).then(function(d){
    EM.data = d;
    document.getElementById('emSimBadge').style.display = d.simMode ? '' : 'none';
    var k = d.kpis;
    document.getElementById('emKpis').innerHTML =
      '<div class="em-kpi"><b>' + k.calls + '</b><span>calls</span></div>' +
      '<div class="em-kpi"><b>' + k.containment + '%</b><span>contained</span></div>' +
      '<div class="em-kpi"><b>' + k.escalated + '</b><span>escalated</span></div>' +
      '<div class="em-kpi"><b>' + Math.round(k.avgSec) + 's</b><span>avg call</span></div>' +
      '<div class="em-kpi"><b>' + k.qaErrPct + '%</b><span>qa errors</span></div>';

    var live = d.escalations;
    document.getElementById('cntLive').textContent = live.length;
    document.getElementById('cntLive').className = 'cnt' + (live.length ? ' hot' : '');
    document.getElementById('tbLive').innerHTML = live.length ? live.map(function(e){
      return '<tr><td>' + pill(e.priority, e.priority === 'P1' ? 'red' : 'amber') + '</td>' +
        '<td>' + esc(e.who) + '</td><td>' + esc(e.reason) + '</td><td>' + esc(e.when) + '</td>' +
        '<td><button class="em-btn ok" onclick="emAct(\'esc-handled\',' + e.id + ')">Handled</button></td></tr>';
    }).join('') : '<tr><td colspan="5" class="em-empty">No open escalations.</td></tr>';

    var rsc = d.rescues;
    document.getElementById('cntRescue').textContent = rsc.length;
    document.getElementById('tbRescue').innerHTML = rsc.length ? rsc.map(function(r){
      return '<tr><td>' + esc(r.target) + ' ' + pill(r.targetRoute,'blue') + '</td>' +
        '<td>' + esc(r.helper) + ' ' + pill(r.helperRoute,'blue') + '</td>' +
        '<td>' + r.score + '</td><td>' + r.gap + ' stops</td>' +
        '<td>' + pill(r.status, r.status === 'approved' ? 'green' : 'amber') + '</td>' +
        '<td>' + esc(r.when) + '</td>' +
        '<td>' + (r.status === 'proposed'
          ? '<button class="em-btn ok" onclick="emAct(\'approve-rescue\',' + r.id + ')">Approve</button> ' +
            '<button class="em-btn no" onclick="emAct(\'deny-rescue\',' + r.id + ')">Deny</button>'
          : '') + '</td></tr>';
    }).join('') : '<tr><td colspan="7" class="em-empty">No pending rescues. The simulator "Rescue" preset creates one when a helper qualifies.</td></tr>';

    var calls = d.calls;
    document.getElementById('cntCalls').textContent = calls.length;
    document.getElementById('tbCalls').innerHTML = calls.length ? calls.map(function(c){
      return '<tr><td>' + esc(c.when) + '</td><td>' + esc(c.who) + '</td>' +
        '<td>' + pill(c.intent || '?', 'blue') + '</td><td>' + outPill(c.outcome) + '</td>' +
        '<td>' + c.sec + '</td><td>' + (c.sim ? pill('SIM','') : '') + '</td>' +
        '<td>' + (c.qa ? pill(c.qa, c.qa === 'pass' ? 'green' : 'red') : '') + '</td>' +
        '<td><button class="em-btn" onclick="emTrail(' + c.id + ')">Trail</button></td></tr>';
    }).join('') : '<tr><td colspan="8" class="em-empty">No calls yet &mdash; run the simulator.</td></tr>';

    var qa = calls.filter(function(c){ return c.outcome !== 'open' && !c.qa; });
    document.getElementById('cntQa').textContent = qa.length;
    document.getElementById('tbQa').innerHTML = qa.length ? qa.map(function(c){
      return '<tr><td>' + esc(c.when) + '</td><td>' + esc(c.who) + '</td>' +
        '<td>' + pill(c.intent || '?','blue') + '</td><td>' + outPill(c.outcome) + '</td>' +
        '<td style="font-size:11.5px;color:#475569">' + esc(c.transcript) + '</td>' +
        '<td><select class="em-sel" style="width:150px;display:inline-block" id="qacat' + c.id + '">' +
        '<option value="">category&hellip;</option><option>wrong-decision</option><option>should-have-escalated</option>' +
        '<option>bad-understanding</option><option>policy-gap</option><option>other</option></select> ' +
        '<button class="em-btn ok" onclick="emQa(' + c.id + ',\'pass\')">Pass</button> ' +
        '<button class="em-btn no" onclick="emQa(' + c.id + ',\'fail\')">Fail</button></td></tr>';
    }).join('') : '<tr><td colspan="6" class="em-empty">QA queue is empty.</td></tr>';

    document.getElementById('tbCfg').innerHTML = d.config.map(function(c){
      var ro = c.name === 'SHARED_KEY';
      return '<tr><td><b>' + esc(c.name) + '</b></td>' +
        '<td>' + (ro ? '********'
          : '<input class="em-cfgin" id="cfg_' + c.name + '" value="' + esc(c.val) + '"> ' +
            '<button class="em-btn" onclick="emCfg(\'' + c.name + '\')">Save</button>') + '</td>' +
        '<td style="color:#64748B">' + esc(c.desc) + '</td>' +
        '<td style="color:#94A3B8;font-size:11.5px">' + esc(c.by ? c.by + ' &middot; ' + c.at : '') + '</td></tr>';
    }).join('');
  }).catch(function(e){ console.error('emLoad', e); });
}

function emAct(action, id){
  var fd = new URLSearchParams(); fd.append('action', action); fd.append('id', id); fd.append('user', EM.user);
  fetch('../api/emily/console-action', {method:'POST', body:fd}).then(function(){ emLoad(); });
}
function emQa(id, verdict){
  var fd = new URLSearchParams();
  fd.append('action','qa-mark'); fd.append('id', id); fd.append('qa', verdict);
  fd.append('category', (document.getElementById('qacat' + id) || {value:''}).value);
  fd.append('user', EM.user);
  fetch('../api/emily/console-action', {method:'POST', body:fd}).then(function(){ emLoad(); });
}
function emCfg(name){
  var fd = new URLSearchParams();
  fd.append('action','config-set'); fd.append('name', name);
  fd.append('val', document.getElementById('cfg_' + name).value); fd.append('user', EM.user);
  fetch('../api/emily/console-action', {method:'POST', body:fd}).then(function(){ emLoad(); });
}
function emTrail(callId){
  var ev = (EM.data.events || []).filter(function(e){ return e.callId === callId; });
  document.getElementById('drCallId').textContent = callId;
  document.getElementById('drBody').innerHTML = ev.length ? ev.reverse().map(function(e){
    return '<div style="border:1px solid #E4E8F0;border-radius:8px;padding:8px 10px;margin-bottom:6px">' +
      '<div style="display:flex;gap:8px;align-items:center"><b style="font-size:12px">' + esc(e.tool) + '</b>' +
      pill(e.rule, 'blue') + pill(e.decision, e.decision === 'ALLOW' ? 'green' : e.decision === 'DENY' ? 'red' : 'amber') +
      '<span style="margin-left:auto;color:#94A3B8;font-size:11px">' + esc(e.when) + '</span></div>' +
      '<div style="font-family:Consolas,monospace;font-size:10.5px;color:#475569;margin-top:5px;word-break:break-all">' + esc(e.result) + '</div></div>';
  }).join('') : '<div class="em-empty">No events for this call.</div>';
  document.getElementById('emDrawer').classList.add('open');
}

/* ── simulator ── */
function emSimCall(phone, utterance, age, stops){
  var fd = new URLSearchParams();
  fd.append('phone', phone); fd.append('utterance', utterance);
  fd.append('ovAgeMin', age || ''); fd.append('ovStopsDone', stops || '');
  fd.append('user', EM.user);
  return fetch('../api/emily/simulate', {method:'POST', body:fd}).then(function(r){ return r.json(); });
}
function emRenderSteps(res){
  var out = 'CALL #' + res.callId + '   intent=' + res.intent + '   outcome=' + res.outcome + '\n' +
            '─────────────────────────────────────────\n';
  res.steps.forEach(function(s){
    var r = s.result || {};
    out += '► ' + s.step + (r.rule ? '   [' + r.rule + ']' : '') + (r.decision ? '  ' + r.decision : '') + '\n';
    if (r.say) out += '  Emily: "' + r.say + '"\n';
    if (r.candidates && r.candidates.length) out += '  candidates: ' + r.candidates.map(function(c){ return c.helper + ' (' + c.score + ')'; }).join(', ') + '\n';
    if (r.stops) out += '  stops=' + r.stops + ' ageMin=' + r.ageMin + '\n';
    if (r.incidentId) out += '  incidents row #' + r.incidentId + ' (SOURCE=EMILY)\n';
    if (r.rescueId) out += '  rescue #' + r.rescueId + ' proposed → Rescues tab\n';
    if (r.transferTo !== undefined && r.priority) out += '  priority=' + r.priority + (r.transferTo ? ' → ' + r.transferTo : ' (TRANSFER_TARGET not set — D3)') + '\n';
    out += '\n';
  });
  document.getElementById('simSteps').textContent = out;
}
function emRunSim(){
  var phone = document.getElementById('simCaller').value;
  var utt = document.getElementById('simUtterance').value || 'hello';
  document.getElementById('simSteps').textContent = 'Running…';
  document.getElementById('simPassFail').innerHTML = '';
  emSimCall(phone, utt, document.getElementById('simAge').value, document.getElementById('simStops').value)
    .then(function(res){ emRenderSteps(res); emLoad(); })
    .catch(function(e){ document.getElementById('simSteps').textContent = 'Error: ' + e; });
}
function emRunAll(btn){
  btn.disabled = true;
  var phone0 = document.getElementById('simCaller').value;
  var pf = document.getElementById('simPassFail');
  pf.innerHTML = '';
  var i = 0, pass = 0;
  function next(){
    if (i >= EM_PRESETS.length){
      pf.innerHTML += '<div class="' + (pass === EM_PRESETS.length ? 'p' : 'f') + '"><b>' + pass + '/' + EM_PRESETS.length + ' scenarios passed</b></div>';
      btn.disabled = false; emLoad(); return;
    }
    var p = EM_PRESETS[i];
    emSimCall(p.phone || phone0, p.u, p.age, p.stops).then(function(res){
      var ok = p.expect.indexOf(res.outcome) >= 0;
      if (ok) pass++;
      pf.innerHTML += '<div class="' + (ok ? 'p' : 'f') + '">' + (ok ? '&#10003;' : '&#10007;') + ' ' + p.n +
        ' &rarr; ' + res.outcome + (ok ? '' : ' (expected ' + p.expect.join('/') + ')') + '</div>';
      i++; next();
    }).catch(function(e){
      pf.innerHTML += '<div class="f">&#10007; ' + p.n + ' &rarr; error ' + e + '</div>';
      i++; next();
    });
  }
  next();
}

emLoad();
setInterval(emLoad, 10000);
</script>
<%@ include file="includeFooter.jsp"%>
</html>
