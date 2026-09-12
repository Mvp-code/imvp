<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"
         import="java.util.*,com.util.*,com.beans.*" %>
<%
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
  _recordBean.setController("DispatcherTaskBoard");
  _recordBean.setDisplayName("Dispatcher Tasks");
  int submitType = SubmitType.SEARCH;
%>
<!DOCTYPE html>
<html lang="en">
<%@ include file="includeHeader.jsp"%>
<script>function validatePageData(submitType, isValid) { return isValid; }</script>
<style>
.ft-shell{display:flex;flex-direction:column;height:calc(100vh - 96px);overflow:hidden}
.ft-hd{display:flex;align-items:flex-start;gap:12px;flex-wrap:wrap;margin-bottom:8px;flex-shrink:0}
.ft-hd h1{font-size:18px;font-weight:900;color:#0f172a;margin:0}
.ft-hd .sub{font-size:12px;color:#64748B}
.ft-kpis{display:flex;gap:8px;margin-left:auto;flex-wrap:wrap}
.ft-kpi{background:#fff;border:1px solid #E4E8F0;border-radius:8px;padding:5px 12px;text-align:center;min-width:72px;cursor:pointer}
.ft-kpi:hover,.ft-kpi.on{border-color:#0f172a}
.ft-kpi b{display:block;font-size:18px;color:#0f172a;line-height:1.1}
.ft-kpi span{font-size:9.5px;color:#64748B;font-weight:700;text-transform:uppercase;letter-spacing:.04em}
.ft-kpi.red b{color:var(--status-action-fg)}.ft-kpi.amber b{color:var(--status-warn-fg)}.ft-kpi.blue b{color:var(--status-info-fg)}
.ft-toolbar{display:flex;gap:7px;flex-wrap:wrap;margin-bottom:8px;flex-shrink:0;align-items:center}
.ft-toolbar input{border:1px solid #CBD5E1;border-radius:7px;padding:6px 9px;font-size:12.5px;background:#fff}
.ft-toolbar .btn{border:1px solid #CBD5E1;background:#fff;border-radius:7px;padding:6px 12px;font-size:12px;font-weight:700;cursor:pointer;text-decoration:none;color:inherit}
.ft-view{display:inline-flex;border:1px solid #CBD5E1;border-radius:8px;padding:2px;background:#fff}
.ft-view button{border:none;background:transparent;padding:5px 11px;font-size:12px;font-weight:700;color:#64748B;cursor:pointer;border-radius:6px}
.ft-view button.on{background:#0f172a;color:#fff}
.ft-body{flex:1;min-height:0;overflow:auto}
.ft-board{display:grid;grid-template-columns:repeat(4,minmax(180px,1fr));gap:10px;min-height:100%}
.ft-col{background:#F8FAFC;border:1px solid #E4E8F0;border-radius:10px;display:flex;flex-direction:column;min-height:280px}
.ft-col-h{padding:9px 11px;font-size:11px;font-weight:800;text-transform:uppercase;letter-spacing:.05em;color:#475569;border-bottom:1px solid #E4E8F0;display:flex;align-items:center}
.ft-col-h .n{margin-left:auto;background:#EEF1F6;border-radius:9px;padding:1px 7px;font-size:10px;color:#0f172a}
.ft-col-b{padding:8px;display:flex;flex-direction:column;gap:7px;flex:1;overflow:auto}
.ft-card{background:#fff;border:1px solid #E4E8F0;border-radius:9px;padding:10px;cursor:pointer}
.ft-card:hover{border-color:#0f172a}
.ft-card .veh{font-weight:800;font-size:13.5px;color:#0f172a}
.ft-card .ty{font-size:11px;color:#64748B;margin-top:2px}
.ft-card .meta{display:flex;gap:6px;flex-wrap:wrap;margin-top:7px}
.ft-pill{display:inline-block;font-size:9.5px;font-weight:800;padding:2px 7px;border-radius:9px;background:#EEF1F6;color:#334155}
.ft-pill.red{background:var(--status-action-bg);color:var(--status-action-fg)}.ft-pill.amber{background:var(--status-warn-bg);color:var(--status-warn-fg)}.ft-pill.blue{background:var(--status-info-bg);color:var(--status-info-fg)}
.ft-pill.escalation{background:var(--status-escalation-bg);color:var(--status-escalation-fg)}
.ft-card .age{font-family:Consolas,monospace;font-size:10px;color:#94A3B8;margin-top:6px}
.ft-tbl{width:100%;border-collapse:collapse;background:#fff;border:1px solid #E4E8F0}
.ft-tbl th{font-size:10px;text-transform:uppercase;letter-spacing:.04em;color:#64748B;text-align:left;padding:8px 10px;background:#F8FAFC;border-bottom:1px solid #E4E8F0}
.ft-tbl td{font-size:12.5px;padding:8px 10px;border-bottom:1px solid #EEF1F6}
.ft-tbl tr{cursor:pointer}.ft-tbl tr:hover td{background:#F8FAFC}
.ft-scrim{display:none;position:fixed;inset:0;background:rgba(20,21,25,.35);z-index:390}
.ft-scrim.on{display:block}
.ft-drawer{position:fixed;top:0;right:0;width:min(460px,100vw);height:100vh;background:#fff;border-left:1px solid #E4E8F0;box-shadow:-8px 0 30px rgba(0,0,0,.14);z-index:400;padding:14px 18px;overflow:auto;transform:translateX(calc(100% + 40px));visibility:hidden;transition:transform .22s,visibility .22s}
.ft-drawer.on{transform:translateX(0);visibility:visible}
.ft-drawer h3{margin:0 0 4px;font-size:16px;display:flex;align-items:center;gap:8px}
.ft-drawer .x{margin-left:auto;border:0;background:transparent;font-size:16px;cursor:pointer;color:#94A3B8}
.ft-drawer .sub{font-size:12px;color:#64748B;margin-bottom:12px}
.ft-fgrid{display:grid;grid-template-columns:1fr 1fr;gap:9px;margin-bottom:10px}
.ft-fgrid label{display:flex;flex-direction:column;gap:3px;font-size:10px;text-transform:uppercase;letter-spacing:.05em;color:#64748B}
.ft-fgrid .v{font-size:13px;color:#0f172a;text-transform:none;letter-spacing:0;font-weight:600}
.ft-actions{display:flex;gap:8px;margin-top:10px;flex-wrap:wrap}
.ft-actions .btn{border:1px solid #CBD5E1;background:#fff;border-radius:7px;padding:7px 14px;font-size:12.5px;font-weight:700;cursor:pointer}
.ft-actions .btn.pri{background:#0f172a;border-color:#0f172a;color:#fff}
.ft-actions .btn.ok{border-color:var(--status-ok-fg);color:var(--status-ok-fg)}
.ft-actions .btn.blue{border-color:var(--status-info-fg);color:var(--status-info-fg)}
.ft-timeline{border-top:1px solid #EEF1F6;margin-top:14px;padding-top:10px}
.ft-timeline h4{font-size:11px;text-transform:uppercase;letter-spacing:.05em;color:#64748B;margin:0 0 8px}
.ft-tl{font-size:12px;padding:6px 0;border-bottom:1px solid #F1F5F9;white-space:pre-wrap}
.ft-empty{font-size:11px;color:#94A3B8;padding:8px;text-align:center}
.ft-err{color:var(--status-action-fg);font-size:13px;padding:20px}
.ft-drawer input,.ft-drawer select,.ft-drawer textarea{border:1px solid #CBD5E1;border-radius:7px;padding:7px 9px;font-size:13px;width:100%;box-sizing:border-box;background:#fff}
.ft-toolbar .btn.pri{background:#0f172a;border-color:#0f172a;color:#fff;text-decoration:none}
.ft-combo{position:relative}
.ft-combo input[type=text]{width:100%;box-sizing:border-box}
.ft-combo-list{display:none;position:absolute;left:0;right:0;top:100%;z-index:20;max-height:220px;overflow:auto;background:#fff;border:1px solid #CBD5E1;border-radius:7px;box-shadow:0 8px 20px rgba(0,0,0,.12);margin-top:2px}
.ft-combo-list.on{display:block}
.ft-combo-list div{padding:8px 10px;font-size:13px;cursor:pointer;color:#0f172a}
.ft-combo-list div:hover,.ft-combo-list div.on{background:#F1F5F9}
.ft-combo-list .empty{color:#94A3B8;cursor:default}
.ft-combo-sel{font-size:11px;color:#64748B;margin-top:3px;min-height:14px}
.ft-owners{display:flex;flex-wrap:wrap;gap:6px;margin:0 0 8px;flex-shrink:0;align-items:center}
.ft-owners .lbl{font-size:10px;font-weight:800;text-transform:uppercase;letter-spacing:.05em;color:#64748B;margin-right:2px}
.ft-own{border:1px solid #E4E8F0;background:#fff;border-radius:8px;padding:5px 10px;font-size:12px;cursor:pointer;display:inline-flex;align-items:center;gap:7px}
.ft-own:hover,.ft-own.on{border-color:#0f172a;background:#F8FAFC}
.ft-own b{font-size:13px;color:#0f172a;min-width:1.2em;text-align:center}
.ft-own span{color:#475569;font-weight:600}
@media(max-width:900px){.ft-board{grid-template-columns:1fr}}
</style>

<div class="ft-shell">
  <div class="ft-hd">
    <div>
      <h1><i class="fa fa-headphones"></i> Dispatcher Tasks</h1>
      <div class="sub">Open / pending da_tasks | Start | Done | notes in TASKDESC</div>
    </div>
    <div class="ft-kpis">
      <div class="ft-kpi on" data-f="" onclick="ftKpi(this,'')"><b id="kOpen">-</b><span>Open</span></div>
      <div class="ft-kpi blue" data-f="pending" onclick="ftKpi(this,'pending')"><b id="kPend">-</b><span>Pending</span></div>
      <div class="ft-kpi red" data-f="overdue" onclick="ftKpi(this,'overdue')"><b id="kRisk">-</b><span>At risk</span></div>
      <div class="ft-kpi amber" data-f="dueSoon" onclick="ftKpi(this,'dueSoon')"><b id="kDue">—</b><span>Due soon</span></div>
      <div class="ft-kpi" data-f="handed" onclick="ftKpi(this,'handed')" style="border-color:var(--status-info-border)"><b id="kHand" style="color:var(--status-info-fg)">—</b><span>Handed off</span></div>
    </div>
  </div>
  <div class="ft-toolbar">
    <input id="ftQ" placeholder="DA, title, owner" oninput="ftRender()" style="min-width:200px">
    <div class="ft-view">
      <button type="button" class="on" id="ftVBoard" onclick="ftView('board')">Board</button>
      <button type="button" id="ftVList" onclick="ftView('list')">List</button>
    </div>
    <button type="button" class="btn" style="margin-left:auto" onclick="ftLoad()">Refresh</button>
    <a class="btn" href="javascript:void(0)" onclick="submitPageDataForm('<%=SubmitType.SEARCH%>','DATask')">Classic DA Tasks</a>
    <button type="button" class="btn pri" onclick="ftNew()">+ New task</button>
  </div>
  <div class="ft-owners" id="ftOwners"><span class="lbl">Dispatchers</span><span class="ft-empty" style="padding:0">Loading...</span></div>
  <div class="ft-body">
    <div id="ftBoard" class="ft-board"></div>
    <div id="ftList" style="display:none"></div>
  </div>
</div>

<div class="ft-scrim" id="ftScrim" onclick="ftClose()"></div>
<div class="ft-drawer" id="ftDrawer">
  <h3><span id="ftDrTitle">Task</span><button type="button" class="x" onclick="ftClose()">&#10005;</button></h3>
  <div class="sub" id="ftDrSub"></div>
  <div id="ftViewPane">
    <div class="ft-fgrid">
      <label>DA<div class="v" id="ftDrDa">-</div></label>
      <label>Topic<div class="v" id="ftDrTopic">-</div></label>
      <label>Priority<div class="v" id="ftDrPri">-</div></label>
      <label>Owner<div class="v" id="ftDrOwn">-</div></label>
      <label>Due<div class="v" id="ftDrDue">-</div></label>
      <label>Status<div class="v" id="ftDrSt">-</div></label>
    </div>
    <div id="ftHandoffBox" style="display:none;margin:8px 0 10px;padding:10px;border:1px solid #DBEAFE;background:#EFF6FF;border-radius:8px">
      <div style="font-size:10px;font-weight:800;text-transform:uppercase;letter-spacing:.05em;color:var(--status-info-fg);margin-bottom:6px">Prior dispatcher work / handoffs</div>
      <div id="ftHandoffs"></div>
    </div>
    <label style="display:block;font-size:10px;text-transform:uppercase;letter-spacing:.05em;color:#64748B">Description / notes
      <div id="ftDrDesc" class="ft-tl" style="border:0;margin-top:4px"></div>
    </label>
    <label style="display:block;margin-top:10px;font-size:10px;text-transform:uppercase;letter-spacing:.05em;color:#64748B">Add note
      <textarea id="ftDrNote" rows="2"></textarea>
    </label>
    <div class="ft-actions">
      <button type="button" class="btn pri" onclick="ftSaveNote()">Save note</button>
      <button type="button" class="btn blue" id="ftBtnStart" onclick="ftState('1')">Start (Pending)</button>
      <button type="button" class="btn ok" onclick="ftState('2')">Mark done</button>
      <button type="button" class="btn" id="ftBtnReopen" onclick="ftState('0')">Reopen</button>
    </div>
    <div class="ft-timeline" style="margin-top:14px">
      <h4>Hand off to another dispatcher</h4>
      <div class="ft-fgrid" style="margin-bottom:8px">
        <label style="grid-column:1/-1">New owner
          <div class="ft-combo" data-combo="reAsn">
            <input type="text" id="reAsn_q" placeholder="Type to search dispatcher" autocomplete="off"
                   oninput="ftComboType('reAsn')" onfocus="ftComboType('reAsn')" onkeydown="ftComboKey(event,'reAsn')">
            <input type="hidden" id="reAsn" value="">
            <div id="reAsn_list" class="ft-combo-list"></div>
          </div>
          <div class="ft-combo-sel" id="reAsn_sel">No dispatcher selected</div>
        </label>
      </div>
      <div class="ft-actions" style="margin-top:0">
        <button type="button" class="btn blue" onclick="ftReassign()">Hand off</button>
      </div>
      <div class="ft-empty" style="text-align:left;padding:6px 0 0">Adds a handoff link in the trail so the next dispatcher sees what was already done. Optional note above is included.</div>
    </div>
    <div class="ft-timeline">
      <h4>Audit</h4>
      <div id="ftTrail"></div>
    </div>
  </div>
  <div id="ftCreatePane" style="display:none">
    <div class="ft-fgrid">
      <label style="grid-column:1/-1">DA
        <div class="ft-combo">
          <input type="text" id="ftCDaQ" placeholder="Type to search DA name" autocomplete="off"
                 oninput="ftDaType()" onfocus="ftDaType()" onkeydown="ftDaKey(event)">
          <input type="hidden" id="ftCDa" value="">
          <div id="ftCDaList" class="ft-combo-list"></div>
        </div>
        <div class="ft-combo-sel" id="ftCDaSel">No DA selected</div>
      </label>
      <label style="grid-column:1/-1">Task title
        <input type="text" id="ftCTitle" placeholder="What needs to happen">
      </label>
      <label>Topic
        <div class="ft-combo" data-combo="topic">
          <input type="text" id="topic_q" placeholder="Type to search topic" autocomplete="off"
                 oninput="ftComboType('topic')" onfocus="ftComboType('topic')" onkeydown="ftComboKey(event,'topic')">
          <input type="hidden" id="topic" value="">
          <div id="topic_list" class="ft-combo-list"></div>
        </div>
        <div class="ft-combo-sel" id="topic_sel">No topic selected</div>
      </label>
      <label>Priority
        <div class="ft-combo" data-combo="pri">
          <input type="text" id="pri_q" placeholder="Type priority" autocomplete="off"
                 oninput="ftComboType('pri')" onfocus="ftComboType('pri')" onkeydown="ftComboKey(event,'pri')">
          <input type="hidden" id="pri" value="Medium">
          <div id="pri_list" class="ft-combo-list"></div>
        </div>
        <div class="ft-combo-sel" id="pri_sel">Selected: Medium</div>
      </label>
      <label id="ftCTopicNewWrap" style="display:none;grid-column:1/-1">New topic
        <input type="text" id="ftCTopicNew" placeholder="Letters, numbers, spaces only" maxlength="60">
      </label>
      <label>Due date<input type="date" id="ftCDue"></label>
      <label>Assigned to
        <div class="ft-combo" data-combo="asn">
          <input type="text" id="asn_q" placeholder="Type to search dispatcher" autocomplete="off"
                 oninput="ftComboType('asn')" onfocus="ftComboType('asn')" onkeydown="ftComboKey(event,'asn')">
          <input type="hidden" id="asn" value="">
          <div id="asn_list" class="ft-combo-list"></div>
        </div>
        <div class="ft-combo-sel" id="asn_sel">No dispatcher selected</div>
      </label>
    </div>
    <label style="display:block;margin-top:4px;font-size:10px;text-transform:uppercase;letter-spacing:.05em;color:#64748B">Description
      <textarea id="ftCDesc" rows="3" style="margin-top:3px"></textarea>
    </label>
    <div class="ft-actions">
      <button type="button" class="btn pri" onclick="ftCreateSave()">Create task</button>
      <button type="button" class="btn" onclick="ftClose()">Cancel</button>
    </div>
  </div>
</div>

<script>
<% String dtLoginEsc = dtLoginUser.replace("\\", "\\\\").replace("\"", "\\\""); %>
var FT_DATA = { kpis:{}, tasks:[] };
var FT_VIEW = "board", FT_KPI = "", FT_OWNER = "", FT_CUR = null;
var FT_DAS = null, FT_DISPS = null, FT_TOPICS = null;
var FT_DA_TIMER = null, FT_DA_HI = -1;
var FT_LOGIN = "<%=dtLoginEsc%>";
var FT_COMBO = {
  topic: { hi:-1, allowNew:true, newLabel:"+ Add new topic", rows:function(){ return (FT_TOPICS||[]).map(function(s){ var c=ftCleanTopic(s); return c?{id:c,nm:c}:null; }).filter(Boolean); } },
  pri:   { hi:-1, allowNew:false, rows:function(){ return ["Low","Medium","High","Critical"].map(function(s){ return {id:s,nm:s}; }); } },
  asn:   { hi:-1, allowNew:false, rows:function(){ return (FT_DISPS||[]).map(function(r){ return { id:r.id, nm:r.nm+" ("+r.id+")" }; }); } },
  reAsn: { hi:-1, allowNew:false, skip:function(){ return FT_CUR && FT_CUR.owner ? FT_CUR.owner : ""; }, rows:function(){ return (FT_DISPS||[]).map(function(r){ return { id:r.id, nm:r.nm+" ("+r.id+")" }; }); } }
};
function ftComboClear(key){
  var el = document.getElementById(key), q = document.getElementById(key+"_q"), sel = document.getElementById(key+"_sel"), list = document.getElementById(key+"_list");
  if (el) el.value = (key==="pri" ? "Medium" : "");
  if (q) q.value = (key==="pri" ? "Medium" : "");
  if (sel) sel.textContent = key==="pri" ? "Selected: Medium" : "Nothing selected";
  if (list) list.classList.remove("on");
  if (FT_COMBO[key]) FT_COMBO[key].hi = -1;
  if (key === "topic") { var w=document.getElementById("ftCTopicNewWrap"); if (w) w.style.display="none"; }
}
function ftComboSet(key, id, nm){
  document.getElementById(key).value = id;
  document.getElementById(key+"_q").value = nm;
  document.getElementById(key+"_sel").textContent = id === "__new" ? "Add new topic" : ("Selected: " + nm);
  document.getElementById(key+"_list").classList.remove("on");
  FT_COMBO[key].hi = -1;
  if (key === "topic") {
    document.getElementById("ftCTopicNewWrap").style.display = id === "__new" ? "" : "none";
    if (id === "__new") document.getElementById("ftCTopicNew").focus();
  }
}
function ftComboVal(key){ return (document.getElementById(key).value || "").trim(); }
function ftComboRender(key, rows){
  var box = document.getElementById(key+"_list");
  var cfg = FT_COMBO[key];
  var skip = cfg.skip ? cfg.skip() : "";
  rows = (rows||[]).filter(function(r){ return !skip || r.id !== skip; });
  if (cfg.allowNew) rows = rows.concat([{ id:"__new", nm: cfg.newLabel || "+ Add new" }]);
  if (!rows.length) { box.innerHTML = "<div class=\"empty\">No matches</div>"; box.classList.add("on"); cfg.hi=-1; return; }
  var h = "", max = Math.min(rows.length, 80);
  for (var i=0;i<max;i++) {
    h += "<div data-id=\""+esc(rows[i].id)+"\" data-nm=\""+esc(rows[i].nm)+"\" onmousedown=\"event.preventDefault();ftComboSet('"+key+"', this.getAttribute('data-id'), this.getAttribute('data-nm'))\">"+esc(rows[i].nm)+"</div>";
  }
  if (rows.length > max) h += "<div class=\"empty\">Showing "+max+" of "+rows.length+" - type more to narrow</div>";
  box.innerHTML = h; box.classList.add("on"); cfg.hi = -1;
}
function ftComboType(key){
  var q = (document.getElementById(key+"_q").value || "").trim().toLowerCase();
  var cur = ftComboVal(key);
  if (cur && cur !== "__new") {
    var hit = null;
    FT_COMBO[key].rows().forEach(function(r){ if (r.id === cur) hit = r; });
    if (!hit || (hit.nm||"").toLowerCase() !== q) {
      document.getElementById(key).value = "";
      document.getElementById(key+"_sel").textContent = "Nothing selected";
      if (key === "topic") document.getElementById("ftCTopicNewWrap").style.display = "none";
    }
  }
  var rows = FT_COMBO[key].rows();
  if (q) rows = rows.filter(function(r){ return (r.nm||"").toLowerCase().indexOf(q) >= 0 || String(r.id).toLowerCase().indexOf(q) >= 0; });
  ftComboRender(key, rows);
}
function ftComboKey(ev, key){
  var box = document.getElementById(key+"_list");
  var items = box.querySelectorAll("div[data-id]");
  if (!items.length) return;
  var cfg = FT_COMBO[key];
  if (ev.key === "ArrowDown") { ev.preventDefault(); cfg.hi = Math.min(cfg.hi + 1, items.length - 1); }
  else if (ev.key === "ArrowUp") { ev.preventDefault(); cfg.hi = Math.max(cfg.hi - 1, 0); }
  else if (ev.key === "Enter") {
    ev.preventDefault();
    if (cfg.hi >= 0 && items[cfg.hi]) ftComboSet(key, items[cfg.hi].getAttribute("data-id"), items[cfg.hi].getAttribute("data-nm"));
    return;
  } else if (ev.key === "Escape") { box.classList.remove("on"); return; }
  else return;
  for (var i=0;i<items.length;i++) items[i].classList.toggle("on", i === cfg.hi);
  if (cfg.hi >= 0 && items[cfg.hi]) items[cfg.hi].scrollIntoView({ block:"nearest" });
}


function ftAjax(params, cb) {
  var body = new URLSearchParams();
  body.append("submitType", "<%=SubmitType.DYNAMIC%>");
  body.append("controller", "DATask");
  Object.keys(params).forEach(function(k){ body.append(k, params[k]); });
  ["entityID","loginUser","loginUserID","loginUserRoles","loginUserDisplayName"].forEach(function(k){
    var el = document.getElementById(k); if (el) body.append(k, el.value);
  });
  fetch("../servlet/MVPGServlet", { method:"POST", headers:{"Content-Type":"application/x-www-form-urlencoded"}, body: body.toString() })
    .then(function(r){ return r.text(); })
    .then(cb)
    .catch(function(){ document.getElementById("ftBoard").innerHTML = "<div class=\"ft-err\">Request failed</div>"; });
}
function ftLoad() {
  ftAjax({ requestType:"dispBoardList" }, function(resp){
    try { FT_DATA = JSON.parse(resp); } catch(e) {
      document.getElementById("ftBoard").innerHTML = "<div class=\"ft-err\">Could not load board. Recompile DATaskDAO if needed.</div>";
      return;
    }
    document.getElementById("kOpen").textContent = (FT_DATA.kpis && FT_DATA.kpis.open) || 0;
    document.getElementById("kPend").textContent = (FT_DATA.kpis && FT_DATA.kpis.pending) || 0;
    document.getElementById("kRisk").textContent = (FT_DATA.kpis && FT_DATA.kpis.risk) || 0;
    document.getElementById("kDue").textContent = (FT_DATA.kpis && FT_DATA.kpis.dueSoon) || 0;
    var kh = document.getElementById("kHand"); if (kh) kh.textContent = (FT_DATA.kpis && FT_DATA.kpis.handed) || 0;
    ftRenderOwners();
    ftRender();
  });
}
function ftRenderOwners(){
  var box = document.getElementById("ftOwners");
  if (!box) return;
  var list = (FT_DATA.byDisp || []).slice().sort(function(a,b){ return (b.n||0)-(a.n||0); });
  var h = "<span class=\"lbl\">Dispatchers</span>";
  h += "<button type=\"button\" class=\"ft-own"+(FT_OWNER===""?" on":"")+"\" onclick=\"ftOwnerFilter('')\"><b>"+((FT_DATA.tasks||[]).length)+"</b><span>All</span></button>";
  if (!list.length) {
    box.innerHTML = h + "<span class=\"ft-empty\" style=\"padding:0\">No open assignees</span>";
    return;
  }
  list.forEach(function(d){
    var id = d.id || d.nm || "(unassigned)";
    var label = d.nm || id;
    h += "<button type=\"button\" class=\"ft-own"+(FT_OWNER===id?" on":"")+"\" data-own=\""+esc(id)+"\" onclick=\"ftOwnerFilter(this.getAttribute('data-own'))\">"
      + "<b>"+esc(String(d.n||0))+"</b><span>"+esc(label)+"</span></button>";
  });
  box.innerHTML = h;
}
function ftOwnerFilter(id){
  FT_OWNER = id || "";
  ftRenderOwners();
  ftRender();
}
function ftFiltered() {
  var q = (document.getElementById("ftQ").value || "").toLowerCase()
    .replace(/[^a-z0-9\s\-_/]/gi, " ").replace(/\s+/g, " ").trim();
  return (FT_DATA.tasks || []).filter(function(t){
    if (FT_KPI === "pending" && t.st !== "1") return false;
    if (FT_KPI === "overdue" && !t.overdue) return false;
    if (FT_KPI === "dueSoon" && !t.needsAttn) return false;
    if (FT_KPI === "handed" && !t.handed) return false;
    var own = t.owner || "(unassigned)";
    if (FT_OWNER && own !== FT_OWNER) return false;
    if (q) {
      var hay = (t.da+" "+t.title+" "+(t.ownerNm||t.owner||"")).toLowerCase()
        .replace(/[^a-z0-9\s\-_/]/gi, " ").replace(/\s+/g, " ");
      if (hay.indexOf(q) < 0) return false;
    }
    return true;
  });
}
function esc(s){ return (s||"").replace(/&/g,"&amp;").replace(/</g,"&lt;").replace(/>/g,"&gt;"); }
function isoToMdy(v){ var p=(v||"").split("-"); return p.length===3 ? p[1]+"/"+p[2]+"/"+p[0] : (v||""); }
function ftPriPill(p){
  var cls = (p||"").toLowerCase().indexOf("high")>=0||(p||"").toLowerCase().indexOf("crit")>=0 ? "red"
    : ((p||"").toLowerCase().indexOf("med")>=0 ? "amber" : "");
  return "<span class=\"ft-pill "+cls+"\">"+esc(p||"—")+"</span>";
}
function ftDispLabel(id){
  if (!id) return "";
  if (!FT_DISPS) return id;
  for (var i=0;i<FT_DISPS.length;i++) if (FT_DISPS[i].id === id) return FT_DISPS[i].nm + " (" + id + ")";
  return id;
}
function ftFillDispSelect(){ /* replaced by typeahead combos */ }
function ftLoadDispatchers(cb){
  if (FT_DISPS) { if (cb) cb(); return; }
  ftAjax({ requestType:"dispBoardDispatchers" }, function(resp){
    try { FT_DISPS = JSON.parse(resp); } catch(e){ FT_DISPS = []; }
    if (cb) cb();
  });
}
function ftParseTrail(desc){
  var handoffs = [], notes = [], other = [];
  var lines = (desc||"").split(/\r?\n/);
  lines.forEach(function(line){
    var s = line.trim();
    if (!s) return;
    if (/HANDOFF\s+/i.test(s)) handoffs.push(s);
    else if (/^\[[^\]]+\]/.test(s)) notes.push(s);
    else other.push(s);
  });
  return { handoffs:handoffs, notes:notes, other:other };
}
function ftRender() {
  var rows = ftFiltered();
  var cols = [
    { id:"open", label:"Open" },
    { id:"handed", label:"Handed off" },
    { id:"overdue", label:"At risk (overdue)" },
    { id:"pending", label:"Pending / in progress" }
  ];
  if (FT_VIEW === "list") {
    document.getElementById("ftBoard").style.display = "none";
    document.getElementById("ftList").style.display = "";
    var h = "<table class=\"ft-tbl\"><thead><tr><th>DA</th><th>Task</th><th>Topic</th><th>Priority</th><th>Owner</th><th>Due</th><th>Status</th></tr></thead><tbody>";
    rows.forEach(function(t){
      var ho = ftParseTrail(t.desc).handoffs.length;
      h += "<tr onclick=\"ftOpen('"+t.id+"')\"><td><b>"+esc(t.da||"—")+"</b></td><td>"+esc(t.title)
        + (ho?" <span class=\"ft-pill blue\">"+ho+" handoff"+(ho>1?"s":"")+"</span>":"")
        + "</td><td>"+esc(t.topic||"—")+"</td>"
        + "<td>"+ftPriPill(t.pri)+"</td><td>"+esc(t.ownerNm||t.owner)+"</td><td>"+esc(t.due||"—")
        + (t.overdue?" <span class=\"ft-pill red\">at risk</span>":"")+"</td>"
        + "<td>"+(t.st==="1"?"Pending":"Open")+"</td></tr>";
    });
    if (!rows.length) h += "<tr><td colspan=\"7\" class=\"ft-empty\">No open tasks match.</td></tr>";
    document.getElementById("ftList").innerHTML = h + "</tbody></table>";
    return;
  }
  document.getElementById("ftBoard").style.display = "";
  document.getElementById("ftList").style.display = "none";
  var html = "";
  cols.forEach(function(c){
    var cards = rows.filter(function(t){ return t.col === c.id; });
    html += "<div class=\"ft-col\"><div class=\"ft-col-h\">"+c.label+"<span class=\"n\">"+cards.length+"</span></div><div class=\"ft-col-b\">";
    cards.forEach(function(t){
      var ho = ftParseTrail(t.desc).handoffs.length;
      html += "<div class=\"ft-card\" onclick=\"ftOpen('"+t.id+"')\"><div class=\"veh\">"+esc(t.title)+"</div>"
        + "<div class=\"ty\">"+(t.da||"No DA")+(t.topic?" · "+esc(t.topic):"")+"</div>"
        + "<div class=\"meta\">"+ftPriPill(t.pri)+(t.overdue?" <span class=\"ft-pill red\">at risk</span>":"")
        + (t.needsAttn?" <span class=\"ft-pill amber\">due soon</span>":"")
        + (ho?" <span class=\"ft-pill blue\">handed off</span>":"")+"</div>"
        + "<div class=\"age\">due "+(t.due||"—")+" · "+esc(t.ownerNm||t.owner)+"</div></div>";
    });
    if (!cards.length) html += "<div class=\"ft-empty\">Empty</div>";
    html += "</div></div>";
  });
  document.getElementById("ftBoard").innerHTML = html;
}
function ftView(v){ FT_VIEW=v; document.getElementById("ftVBoard").classList.toggle("on",v==="board"); document.getElementById("ftVList").classList.toggle("on",v==="list"); ftRender(); }
function ftKpi(el,f){ document.querySelectorAll(".ft-kpi").forEach(function(k){k.classList.remove("on");}); el.classList.add("on"); FT_KPI=f; ftRender(); }
function ftShowDrawer(mode){
  document.getElementById("ftViewPane").style.display = mode === "view" ? "" : "none";
  document.getElementById("ftCreatePane").style.display = mode === "create" ? "" : "none";
  document.getElementById("ftScrim").classList.add("on");
  document.getElementById("ftDrawer").classList.add("on");
}
function ftOpen(id){
  var t = null;
  (FT_DATA.tasks||[]).forEach(function(x){ if (x.id === id) t = x; });
  if (!t) return;
  FT_CUR = t;
  document.getElementById("ftDrTitle").textContent = t.title;
  document.getElementById("ftDrSub").textContent = (t.da||"") + (t.overdue?" · At risk":"");
  document.getElementById("ftDrDa").textContent = t.da || "—";
  document.getElementById("ftDrTopic").textContent = t.topic || "—";
  document.getElementById("ftDrPri").textContent = t.pri || "—";
  document.getElementById("ftDrOwn").textContent = t.ownerNm || t.owner || "—";
  document.getElementById("ftDrDue").textContent = t.due || "—";
  document.getElementById("ftDrSt").textContent = t.st === "1" ? "Pending" : "Open";
  document.getElementById("ftDrNote").value = "";
  document.getElementById("ftBtnStart").style.display = t.st === "0" ? "" : "none";

  var parsed = ftParseTrail(t.desc);
  var hoHtml = "";
  parsed.handoffs.forEach(function(line, idx){
    hoHtml += "<div class=\"ft-tl\" style=\"border-color:#BFDBFE\"><div class=\"t\">Handoff "+(idx+1)+"</div><div class=\"m\">"+esc(line)+"</div></div>";
  });
  parsed.notes.forEach(function(line){
    if (/HANDOFF/i.test(line)) return;
    hoHtml += "<div class=\"ft-tl\"><div class=\"t\">Note</div><div class=\"m\">"+esc(line)+"</div></div>";
  });
  document.getElementById("ftHandoffs").innerHTML = hoHtml || "<div class=\"ft-empty\">No prior handoffs or notes yet.</div>";
  document.getElementById("ftHandoffBox").style.display = (parsed.handoffs.length || parsed.notes.length) ? "" : "none";
  document.getElementById("ftDrDesc").textContent = parsed.other.length ? parsed.other.join("\n") : (t.desc && !parsed.handoffs.length && !parsed.notes.length ? t.desc : "—");

  var trail = "";
  if (t.created) trail += "<div class=\"ft-tl\"><div class=\"t\">"+esc(t.created)+" · "+esc(t.createUser)+"</div><div class=\"m\">Created</div></div>";
  if (t.updated) trail += "<div class=\"ft-tl\"><div class=\"t\">"+esc(t.updated)+" · "+esc(t.updateUser)+"</div><div class=\"m\">Last update</div></div>";
  document.getElementById("ftTrail").innerHTML = trail || "<div class=\"ft-empty\">No audit yet.</div>";
  ftShowDrawer("view");
  ftComboClear("reAsn"); ftLoadDispatchers(function(){});
}
function ftClose(){ document.getElementById("ftScrim").classList.remove("on"); document.getElementById("ftDrawer").classList.remove("on"); FT_CUR=null; }
function ftToday(){
  var d = new Date();
  return d.getFullYear()+"-"+("0"+(d.getMonth()+1)).slice(-2)+"-"+("0"+d.getDate()).slice(-2);
}
function ftLoadDas(cb){
  if (FT_DAS && FT_DAS.length) { if (cb) cb(); return; }
  ftAjax({ requestType:"dispBoardDas" }, function(resp){
    try { FT_DAS = JSON.parse(resp); } catch(e){ FT_DAS = []; }
    if (cb) cb();
  });
}
function ftDaClear(){
  document.getElementById("ftCDa").value = "";
  document.getElementById("ftCDaQ").value = "";
  document.getElementById("ftCDaSel").textContent = "No DA selected";
  document.getElementById("ftCDaList").classList.remove("on");
  FT_DA_HI = -1;
}
function ftDaPick(id, nm){
  document.getElementById("ftCDa").value = id;
  document.getElementById("ftCDaQ").value = nm;
  document.getElementById("ftCDaSel").textContent = "Selected: " + nm;
  document.getElementById("ftCDaList").classList.remove("on");
  FT_DA_HI = -1;
}
function ftDaRenderList(rows){
  var box = document.getElementById("ftCDaList");
  if (!rows || !rows.length) {
    box.innerHTML = "<div class=\"empty\">No matches</div>";
    box.classList.add("on");
    FT_DA_HI = -1;
    return;
  }
  var h = "", max = Math.min(rows.length, 80);
  for (var i = 0; i < max; i++) {
    h += "<div data-id=\""+esc(rows[i].id)+"\" data-nm=\""+esc(rows[i].nm)+"\" "
      + "onmousedown=\"event.preventDefault();ftDaPick(this.getAttribute('data-id'), this.getAttribute('data-nm'))\">"
      + esc(rows[i].nm)+"</div>";
  }
  if (rows.length > max) h += "<div class=\"empty\">Showing "+max+" of "+rows.length+" - type more to narrow</div>";
  box.innerHTML = h;
  box.classList.add("on");
  FT_DA_HI = -1;
}
function ftDaType(){
  var q = (document.getElementById("ftCDaQ").value || "").trim().toLowerCase();
  /* if user edits text after pick, clear id until they pick again */
  var curId = document.getElementById("ftCDa").value;
  if (curId) {
    var match = null;
    (FT_DAS||[]).forEach(function(r){ if (r.id === curId) match = r; });
    if (!match || (match.nm || "").toLowerCase() !== q) {
      document.getElementById("ftCDa").value = "";
      document.getElementById("ftCDaSel").textContent = "No DA selected";
    }
  }
  clearTimeout(FT_DA_TIMER);
  FT_DA_TIMER = setTimeout(function(){
    var run = function(list){
      var rows = list || [];
      if (q) {
        rows = rows.filter(function(r){
          return (r.nm||"").toLowerCase().indexOf(q) >= 0 || String(r.id).indexOf(q) >= 0;
        });
      }
      ftDaRenderList(rows);
    };
    if (FT_DAS && FT_DAS.length) { run(FT_DAS); return; }
    ftAjax({ requestType:"dispBoardDas", q: q }, function(resp){
      try { FT_DAS = JSON.parse(resp); } catch(e){ FT_DAS = []; }
      /* if server filtered, show that; also keep for client filter next time */
      if (q && FT_DAS.length < 50) {
        ftDaRenderList(FT_DAS);
        /* still load full list in background for snappy filtering */
        ftAjax({ requestType:"dispBoardDas" }, function(full){
          try { FT_DAS = JSON.parse(full); } catch(e){}
        });
      } else run(FT_DAS);
    });
  }, 120);
}
function ftDaKey(ev){
  var box = document.getElementById("ftCDaList");
  var items = box.querySelectorAll("div[data-id]");
  if (!items.length) return;
  if (ev.key === "ArrowDown") {
    ev.preventDefault();
    FT_DA_HI = Math.min(FT_DA_HI + 1, items.length - 1);
  } else if (ev.key === "ArrowUp") {
    ev.preventDefault();
    FT_DA_HI = Math.max(FT_DA_HI - 1, 0);
  } else if (ev.key === "Enter") {
    ev.preventDefault();
    if (FT_DA_HI >= 0 && items[FT_DA_HI]) {
      ftDaPick(items[FT_DA_HI].getAttribute("data-id"), items[FT_DA_HI].getAttribute("data-nm"));
    }
    return;
  } else if (ev.key === "Escape") {
    box.classList.remove("on");
    return;
  } else return;
  for (var i = 0; i < items.length; i++) items[i].classList.toggle("on", i === FT_DA_HI);
  if (FT_DA_HI >= 0 && items[FT_DA_HI]) items[FT_DA_HI].scrollIntoView({ block:"nearest" });
}
function ftCleanTopic(s){
  return (s||"").replace(/[^A-Za-z0-9 \-\/]/g, " ").replace(/\s+/g, " ").trim();
}
function ftTopicChg(){ /* combo */ }
function ftTopicVal(){
  var v = ftComboVal("topic");
  if (v === "__new") return ftCleanTopic(document.getElementById("ftCTopicNew").value);
  return ftCleanTopic(v);
}
function ftLoadTopics(cb){
  if (FT_TOPICS) { if (cb) cb(); return; }
  ftAjax({ requestType:"dispBoardTopics" }, function(resp){
    try { FT_TOPICS = JSON.parse(resp); } catch(e){
      FT_TOPICS = ["Safety","Quality","Attendance","Coaching","Customer Feedback","Vehicle","Other"];
    }
    if (cb) cb();
  });
}
function ftNew(){
  FT_CUR = null;
  document.getElementById("ftDrTitle").textContent = "New DA task";
  document.getElementById("ftDrSub").textContent = "Creates an open da_tasks row";
  document.getElementById("ftCTitle").value = "";
  document.getElementById("ftCDue").value = ftToday();
  document.getElementById("ftCDesc").value = "";
  document.getElementById("ftCTopicNew").value = "";
  ftDaClear();
  ftComboClear("topic");
  ftComboClear("pri");
  ftComboSet("pri", "Medium", "Medium");
  ftComboClear("asn");
  ftShowDrawer("create");
  ftLoadDas(function(){});
  ftLoadTopics(function(){});
  ftLoadDispatchers(function(){
    var id = FT_LOGIN, label = FT_LOGIN;
    (FT_DISPS||[]).forEach(function(r){
      if (r && r.id && r.id.toLowerCase() === (FT_LOGIN||"").toLowerCase()) {
        id = r.id;
        label = (r.nm || r.id) + " (" + r.id + ")";
      }
    });
    if (id) ftComboSet("asn", id, label);
  });
}
function ftCreateSave(){
  var employeeID = document.getElementById("ftCDa").value;
  var title = document.getElementById("ftCTitle").value.trim();
  var dueDate = document.getElementById("ftCDue").value;
  var assignedTo = ftComboVal("asn");
  var topic = ftTopicVal();
  var priority = ftComboVal("pri") || "Medium";
  if (!employeeID) { alert("Select a DA from the list"); return; }
  if (!title) { alert("Task title is required"); return; }
  if (!dueDate) { alert("Due date is required"); return; }
  if (!assignedTo) { alert("Select a dispatcher"); return; }
  if (ftComboVal("topic") === "__new" && !topic) { alert("Enter the new topic"); return; }
  ftAjax({
    requestType:"dispBoardCreate",
    employeeID: employeeID,
    title: title,
    topic: topic,
    priority: priority,
    dueDate: isoToMdy(dueDate),
    assignedTo: assignedTo,
    desc: document.getElementById("ftCDesc").value
  }, function(resp){
    if (resp.indexOf("<status>true")>=0) { FT_TOPICS = null; ftClose(); ftLoad(); }
    else alert(/<mesg>([^<]*)<\/mesg>/.exec(resp) ? RegExp.$1 : "Save failed");
  });
}
function ftSaveNote(){
  if (!FT_CUR) return;
  var note = document.getElementById("ftDrNote").value.trim();
  if (!note) { alert("Enter a note"); return; }
  ftAjax({ requestType:"taskNote", recordID:FT_CUR.id, note:note }, function(resp){
    if (resp.indexOf("<status>true")>=0) { ftClose(); ftLoad(); }
    else alert(/<mesg>([^<]*)<\/mesg>/.exec(resp) ? RegExp.$1 : "Save failed");
  });
}
function ftReassign(){
  if (!FT_CUR) return;
  var to = ftComboVal("reAsn");
  if (!to) { alert("Select a dispatcher"); return; }
  if (to === FT_CUR.owner) { alert("Already assigned to that dispatcher"); return; }
  var note = document.getElementById("ftDrNote").value.trim();
  if (!confirm("Hand off this task to "+ftDispLabel(to)+"? Prior notes stay on the task for them.")) return;
  ftAjax({ requestType:"dispBoardReassign", recordID:FT_CUR.id, assignedTo:to, note:note }, function(resp){
    if (resp.indexOf("<status>true")>=0) { ftClose(); ftLoad(); }
    else alert(/<mesg>([^<]*)<\/mesg>/.exec(resp) ? RegExp.$1 : "Hand off failed");
  });
}
function ftState(to){
  if (!FT_CUR) return;
  ftAjax({ requestType:"taskState", recordID:FT_CUR.id, to:to }, function(resp){
    if (resp.indexOf("<status>true")>=0) { ftClose(); ftLoad(); }
    else alert(/<mesg>([^<]*)<\/mesg>/.exec(resp) ? RegExp.$1 : "Update failed");
  });
}
ftLoad();
document.addEventListener("click", function(e){
  var combo = document.querySelector(".ft-combo");
  if (combo && !combo.contains(e.target)) {
    var list = document.getElementById("ftCDaList");
    if (list) list.classList.remove("on");
  }
});
</script>
<%@ include file="includeFooter.jsp"%>