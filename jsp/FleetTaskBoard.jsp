<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"
         import="java.util.*,com.util.*,com.beans.*" %>
<%
  String ftLoginUser   = request.getAttribute("loginUser") != null ? request.getAttribute("loginUser").toString() : (String) session.getAttribute("loginUser");
  String ftLoginRoles  = request.getAttribute("loginUserRoles") != null ? request.getAttribute("loginUserRoles").toString() : (String) session.getAttribute("loginUserRoles");
  String ftEntityID    = request.getAttribute("entityID") != null ? request.getAttribute("entityID").toString() : (session.getAttribute("entityID") != null ? session.getAttribute("entityID").toString() : "1");
  String ftDispName    = request.getAttribute("loginUserDisplayName") != null ? request.getAttribute("loginUserDisplayName").toString() : (session.getAttribute("loginUserDisplayName") != null ? session.getAttribute("loginUserDisplayName").toString() : "");
  String ftLoginUserID = request.getAttribute("loginUserID") != null ? request.getAttribute("loginUserID").toString() : (session.getAttribute("loginUserID") != null ? session.getAttribute("loginUserID").toString() : "");
  if (ftLoginUser == null) ftLoginUser = "";
  if (ftLoginRoles == null) ftLoginRoles = "";
  if (ftDispName == null || ftDispName.length() == 0) ftDispName = "User";
  if (ftEntityID == null || ftEntityID.length() == 0) ftEntityID = "1";
  request.setAttribute("loginUser", ftLoginUser);
  request.setAttribute("loginUserRoles", ftLoginRoles);
  request.setAttribute("entityID", ftEntityID);
  request.setAttribute("loginUserDisplayName", ftDispName);
  request.setAttribute("loginUserID", ftLoginUserID);
  request.setAttribute("shellNoForm", "yes");
  request.setAttribute("hideTopbarSearch", "yes");
%>
<jsp:useBean id="_recordBean" class="com.beans.SearchBean" scope="request" />
<%
  _recordBean.setController("FleetTaskBoard");
  _recordBean.setDisplayName("Fleet Tasks");
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
.ft-kpi.red b{color:var(--status-action-fg)}.ft-kpi.amber b{color:var(--status-warn-fg)}
.ft-toolbar{display:flex;gap:7px;flex-wrap:wrap;margin-bottom:8px;flex-shrink:0;align-items:center}
.ft-toolbar input,.ft-toolbar select{border:1px solid #CBD5E1;border-radius:7px;padding:6px 9px;font-size:12.5px;background:#fff}
.ft-toolbar .btn{border:1px solid #CBD5E1;background:#fff;border-radius:7px;padding:6px 12px;font-size:12px;font-weight:700;cursor:pointer}
.ft-view{display:inline-flex;border:1px solid #CBD5E1;border-radius:8px;padding:2px;background:#fff}
.ft-view button{border:none;background:transparent;padding:5px 11px;font-size:12px;font-weight:700;color:#64748B;cursor:pointer;border-radius:6px}
.ft-view button.on{background:#0f172a;color:#fff}
.ft-body{flex:1;min-height:0;overflow:auto}
.ft-board{display:grid;grid-template-columns:repeat(5,minmax(150px,1fr));gap:10px;min-height:100%}
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
.ft-pill.red{background:var(--status-action-bg);color:var(--status-action-fg)}.ft-pill.amber{background:var(--status-warn-bg);color:var(--status-warn-fg)}
.ft-pill.blue{background:var(--status-info-bg);color:var(--status-info-fg)}
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
.ft-timeline{border-top:1px solid #EEF1F6;margin-top:14px;padding-top:10px}
.ft-timeline h4{font-size:11px;text-transform:uppercase;letter-spacing:.05em;color:#64748B;margin:0 0 8px}
.ft-tl{font-size:12px;padding:6px 0;border-bottom:1px solid #F1F5F9}
.ft-tl .t{font-family:Consolas,monospace;font-size:10px;color:#94A3B8}
.ft-empty{font-size:11px;color:#94A3B8;padding:8px;text-align:center}
.ft-err{color:var(--status-action-fg);font-size:13px;padding:20px}
.ft-drawer input,.ft-drawer select,.ft-drawer textarea{border:1px solid #CBD5E1;border-radius:7px;padding:7px 9px;font-size:13px;width:100%;box-sizing:border-box;background:#fff}
.ft-drawer .ft-fgrid label span{text-transform:uppercase;letter-spacing:.05em;font-size:10px;color:#64748B}
.ft-toolbar .btn.pri{background:#0f172a;border-color:#0f172a;color:#fff;text-decoration:none}
.ft-owners{display:flex;flex-wrap:wrap;gap:6px;margin:0 0 8px;flex-shrink:0;align-items:center}
.ft-owners .lbl{font-size:10px;font-weight:800;text-transform:uppercase;letter-spacing:.05em;color:#64748B;margin-right:2px}
.ft-own{border:1px solid #E4E8F0;background:#fff;border-radius:8px;padding:5px 10px;font-size:12px;cursor:pointer;display:inline-flex;align-items:center;gap:7px}
.ft-own:hover,.ft-own.on{border-color:#0f172a;background:#F8FAFC}
.ft-own b{font-size:13px;color:#0f172a;min-width:1.2em;text-align:center}
.ft-own span{color:#475569;font-weight:600}
.ft-combo{position:relative}
.ft-combo input[type=text]{width:100%;box-sizing:border-box;border:1px solid #CBD5E1;border-radius:7px;padding:7px 9px;font-size:13px;background:#fff}
.ft-combo-list{display:none;position:absolute;left:0;right:0;top:100%;z-index:30;max-height:220px;overflow:auto;background:#fff;border:1px solid #CBD5E1;border-radius:7px;box-shadow:0 8px 20px rgba(0,0,0,.12);margin-top:2px}
.ft-combo-list.on{display:block}
.ft-combo-list div{padding:8px 10px;font-size:13px;cursor:pointer;color:#0f172a}
.ft-combo-list div:hover,.ft-combo-list div.on{background:#F1F5F9}
.ft-combo-list .empty{color:#94A3B8;cursor:default}
.ft-combo-sel{font-size:11px;color:#64748B;margin-top:3px;min-height:14px}
@media(max-width:1100px){.ft-board{grid-template-columns:repeat(2,1fr)}}
</style>

<div class="ft-shell">
  <div class="ft-hd">
    <div>
      <h1><i class="fa fa-tasks"></i> Fleet Tasks</h1>
      <div class="sub">Open maintenance jobs · OFR &amp; grounded KPIs · from vehicle_maintenance_log</div>
    </div>
    <div class="ft-kpis">
      <div class="ft-kpi on" data-f="" onclick="ftKpi(this,'')"><b id="kOpen">—</b><span>Open jobs</span></div>
      <div class="ft-kpi red" data-f="overdue" onclick="ftKpi(this,'overdue')"><b id="kOver">—</b><span>Overdue</span></div>
      <div class="ft-kpi amber" data-f="ofr" onclick="ftKpi(this,'ofr')"><b id="kOfr">—</b><span>Out for repair</span></div>
      <div class="ft-kpi" data-f="grounded" onclick="ftKpi(this,'grounded')"><b id="kGr">—</b><span>Grounded</span></div>
      <div class="ft-kpi" data-f="handed" onclick="ftKpi(this,'handed')" style="border-color:#BFDBFE"><b id="kHand" style="color:#1D4ED8">—</b><span>Handed off</span></div>
    </div>
  </div>
  <div class="ft-toolbar">
    <input id="ftQ" placeholder="Vehicle #, type, shop…" oninput="ftRender()" style="min-width:160px">
    <div class="ft-view">
      <button type="button" class="on" id="ftVBoard" onclick="ftView('board')">Board</button>
      <button type="button" id="ftVList" onclick="ftView('list')">List</button>
    </div>
    <button type="button" class="btn" style="margin-left:auto" onclick="ftLoad()">↻ Refresh</button>
    <button type="button" class="btn pri" onclick="ftNew()">+ New task</button>
    <a class="btn" href="javascript:void(0)" onclick="submitPageDataForm('<%=SubmitType.SEARCH%>','AdminVehicle')">Vehicles</a>
  </div>
  <div class="ft-owners" id="ftOwners"><span class="lbl">Dispatchers</span><span class="ft-empty" style="padding:0">Loading…</span></div>
  <div class="ft-body">
    <div id="ftBoard" class="ft-board"></div>
    <div id="ftList" style="display:none"></div>
  </div>
</div>

<div class="ft-scrim" id="ftScrim" onclick="ftClose()"></div>
<div class="ft-drawer" id="ftDrawer">
  <h3><span id="ftDrTitle">Job</span><button type="button" class="x" onclick="ftClose()">&#10005;</button></h3>
  <div class="sub" id="ftDrSub"></div>
  <div id="ftViewPane">
    <div class="ft-fgrid">
      <label>Type<div class="v" id="ftDrType">—</div></label>
      <label>Shop<div class="v" id="ftDrShop">—</div></label>
      <label>Owner<div class="v" id="ftDrOwn">—</div></label>
      <label>Due / follow-up<div class="v" id="ftDrDue">—</div></label>
      <label>Service date<div class="v" id="ftDrSvc">—</div></label>
      <label>RO #<div class="v" id="ftDrRo">—</div></label>
    </div>
    <div id="ftHandoffBox" style="display:none;margin:8px 0 10px;padding:10px;border:1px solid #DBEAFE;background:#EFF6FF;border-radius:8px">
      <div style="font-size:10px;font-weight:800;text-transform:uppercase;letter-spacing:.05em;color:#1D4ED8;margin-bottom:6px">Prior dispatcher work / handoffs</div>
      <div id="ftHandoffs"></div>
    </div>
    <label style="display:block;font-size:10px;text-transform:uppercase;letter-spacing:.05em;color:#64748B">Notes
      <div id="ftDrNotes" style="font-size:13px;color:#334155;text-transform:none;letter-spacing:0;margin-top:4px;white-space:pre-wrap"></div>
    </label>
    <label style="display:block;margin-top:10px;font-size:10px;text-transform:uppercase;letter-spacing:.05em;color:#64748B">Add note
      <textarea id="ftDrNote" rows="2"></textarea>
    </label>
    <div class="ft-actions">
      <button type="button" class="btn pri" onclick="ftSaveNote()">Save note</button>
      <button type="button" class="btn ok" onclick="ftCloseJob()">Mark closed</button>
      <a class="btn" id="ftVehLink" href="javascript:void(0)">Open vehicle</a>
    </div>
    <div class="ft-timeline" style="margin-top:14px">
      <h4>Hand off to another dispatcher</h4>
      <div class="ft-fgrid" style="margin-bottom:8px">
        <label style="grid-column:1/-1"><span>New owner</span>
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
        <button type="button" class="btn" style="border-color:#1D4ED8;color:#1D4ED8" onclick="ftReassign()">Hand off</button>
      </div>
      <div class="ft-empty" style="text-align:left;padding:6px 0 0">Keeps prior notes and adds a handoff link for the next dispatcher. Optional note above is included.</div>
    </div>
    <div class="ft-timeline"><h4>Activity trail (VEHICLETRANS)</h4><div id="ftTrail"></div></div>
  </div>
  <div id="ftCreatePane" style="display:none">
    <div class="ft-fgrid">
      <label style="grid-column:1/-1"><span>Vehicle</span>
        <div class="ft-combo" data-combo="veh">
          <input type="text" id="veh_q" placeholder="Type to search vehicle #" autocomplete="off"
                 oninput="ftComboType('veh')" onfocus="ftComboType('veh')" onkeydown="ftComboKey(event,'veh')">
          <input type="hidden" id="veh" value="">
          <div id="veh_list" class="ft-combo-list"></div>
        </div>
        <div class="ft-combo-sel" id="veh_sel">No vehicle selected</div>
      </label>
      <label style="grid-column:1/-1"><span>Maintenance type</span>
        <div class="ft-combo" data-combo="mtype">
          <input type="text" id="mtype_q" placeholder="Type to search type" autocomplete="off"
                 oninput="ftComboType('mtype')" onfocus="ftComboType('mtype')" onkeydown="ftComboKey(event,'mtype')">
          <input type="hidden" id="mtype" value="">
          <div id="mtype_list" class="ft-combo-list"></div>
        </div>
        <div class="ft-combo-sel" id="mtype_sel">No type selected</div>
      </label>
      <label><span>Service date</span><input type="date" id="ftCSvc"></label>
      <label><span>Follow-up due</span><input type="date" id="ftCDue"></label>
      <label><span>Shop / vendor</span>
        <div class="ft-combo" data-combo="shop">
          <input type="text" id="shop_q" placeholder="Type to search shop" autocomplete="off"
                 oninput="ftComboType('shop')" onfocus="ftComboType('shop')" onkeydown="ftComboKey(event,'shop')">
          <input type="hidden" id="shop" value="">
          <div id="shop_list" class="ft-combo-list"></div>
        </div>
        <div class="ft-combo-sel" id="shop_sel">No shop selected</div>
      </label>
      <label><span>Assigned to</span>
        <div class="ft-combo" data-combo="asn">
          <input type="text" id="asn_q" placeholder="Type to search dispatcher" autocomplete="off"
                 oninput="ftComboType('asn')" onfocus="ftComboType('asn')" onkeydown="ftComboKey(event,'asn')">
          <input type="hidden" id="asn" value="">
          <div id="asn_list" class="ft-combo-list"></div>
        </div>
        <div class="ft-combo-sel" id="asn_sel">No dispatcher selected</div>
      </label>
      <label id="ftCShopNewWrap" style="display:none;grid-column:1/-1"><span>New shop name</span>
        <input type="text" id="ftCShopNew" placeholder="Shop / vendor name">
      </label>
      <label><span>RO #</span><input type="text" id="ftCRo"></label>
      <label><span>Parts</span><input type="text" id="ftCParts"></label>
    </div>
    <label style="display:block;margin-top:4px;font-size:10px;text-transform:uppercase;letter-spacing:.05em;color:#64748B">Notes
      <textarea id="ftCNotes" rows="3" style="margin-top:3px"></textarea>
    </label>
    <div class="ft-actions">
      <button type="button" class="btn pri" onclick="ftCreateSave()">Create task</button>
      <button type="button" class="btn" onclick="ftClose()">Cancel</button>
    </div>
  </div>
</div>

<script>
var FT_CTRL = 'AdminVehicle';
var FT_DATA = { kpis:{}, tasks:[] };
var FT_VIEW = 'board', FT_KPI = '', FT_OWNER = '', FT_CUR = null;
var FT_VEHS = null, FT_TYPES = null, FT_TYPE_MAP = {};
var FT_SHOPS = null, FT_DISPS = null;
var FT_LOGIN = '<%=ftLoginUser.replace("\\", "\\\\").replace("'", "\\'")%>';
var FT_DEFAULT_ASN = '<%=ftDispName != null && ftDispName.length() > 0 && !"User".equals(ftDispName) ? ftDispName.replace("\\", "\\\\").replace("'", "\\'") : ftLoginUser.replace("\\", "\\\\").replace("'", "\\'")%>';
function ftDispRows(){
  return (FT_DISPS||[]).map(function(r){
    if (typeof r === "string") return { id:r, nm:r };
    var nm = r.nm || r.id || "";
    var user = r.id || nm;
    return { id:nm, nm: nm + (user && user !== nm ? " ("+user+")" : "") };
  });
}
function ftDefaultAssigned(){
  var asnNm = FT_DEFAULT_ASN || FT_LOGIN, asnLabel = asnNm;
  (FT_DISPS||[]).forEach(function(r){
    if (typeof r === "string") {
      if (r === FT_DEFAULT_ASN || r === FT_LOGIN) { asnNm = r; asnLabel = r; }
    } else if (r && (r.id === FT_LOGIN || r.nm === FT_DEFAULT_ASN || r.nm === FT_LOGIN)) {
      asnNm = r.nm || r.id;
      asnLabel = asnNm + (r.id && r.id !== asnNm ? " ("+r.id+")" : "");
    }
  });
  if (asnNm) ftComboSet("asn", asnNm, asnLabel);
}

function ftAjax(params, cb) {
  var body = new URLSearchParams();
  body.append('submitType', '<%=SubmitType.DYNAMIC%>');
  body.append('controller', FT_CTRL);
  Object.keys(params).forEach(function(k){ body.append(k, params[k]); });
  ['entityID','loginUser','loginUserID','loginUserRoles','loginUserDisplayName'].forEach(function(k){
    var el = document.getElementById(k); if (el) body.append(k, el.value);
  });
  fetch('../servlet/MVPGServlet', { method:'POST', headers:{'Content-Type':'application/x-www-form-urlencoded'}, body: body.toString() })
    .then(function(r){ return r.text(); })
    .then(cb)
    .catch(function(){ document.getElementById('ftBoard').innerHTML = '<div class="ft-err">Request failed</div>'; });
}
function ftLoad() {
  ftAjax({ requestType:'fleetBoardList' }, function(resp){
    try { FT_DATA = JSON.parse(resp); } catch(e) {
      document.getElementById('ftBoard').innerHTML = '<div class="ft-err">Could not load board. Recompile AdminVehicleDAO if needed.</div>';
      return;
    }
    document.getElementById('kOpen').textContent = (FT_DATA.kpis && FT_DATA.kpis.open) || 0;
    document.getElementById('kOver').textContent = (FT_DATA.kpis && FT_DATA.kpis.overdue) || 0;
    document.getElementById('kOfr').textContent = (FT_DATA.kpis && FT_DATA.kpis.ofr) || 0;
    document.getElementById('kGr').textContent = (FT_DATA.kpis && FT_DATA.kpis.grounded) || 0;
    document.getElementById('kHand').textContent = (FT_DATA.kpis && FT_DATA.kpis.handed) || 0;
    ftRenderOwners();
    ftRender();
  });
}
function ftRenderOwners(){
  var box = document.getElementById('ftOwners');
  var list = (FT_DATA.byDisp || []).slice().sort(function(a,b){ return (b.n||0)-(a.n||0); });
  var h = '<span class="lbl">Dispatchers</span>';
  h += '<button type="button" class="ft-own'+(FT_OWNER===''?' on':'')+'" onclick="ftOwnerFilter(\'\')"><b>'+((FT_DATA.tasks||[]).length)+'</b><span>All</span></button>';
  if (!list.length) {
    box.innerHTML = h + '<span class="ft-empty" style="padding:0">No open assignees</span>';
    return;
  }
  list.forEach(function(d){
    var id = d.nm || '(unassigned)';
    h += '<button type="button" class="ft-own'+(FT_OWNER===id?' on':'')+'" data-own="'+esc(id)+'" onclick="ftOwnerFilter(this.getAttribute(\'data-own\'))">'
      + '<b>'+esc(String(d.n||0))+'</b><span>'+esc(id)+'</span></button>';
  });
  box.innerHTML = h;
}
function ftOwnerFilter(id){
  FT_OWNER = id || '';
  ftRenderOwners();
  ftRender();
}
function ftFiltered() {
  var q = (document.getElementById('ftQ').value || '').toLowerCase();
  return (FT_DATA.tasks || []).filter(function(t){
    if (FT_KPI === 'overdue' && !t.overdue) return false;
    if (FT_KPI === 'ofr' && t.ofr !== '1') return false;
    if (FT_KPI === 'grounded' && t.grounded !== '1') return false;
    if (FT_KPI === 'handed' && !t.handed) return false;
    var own = t.owner || '(unassigned)';
    if (FT_OWNER && own !== FT_OWNER) return false;
    if (q && (t.veh+' '+t.vin+' '+t.type+' '+t.shop+' '+t.owner).toLowerCase().indexOf(q) < 0) return false;
    return true;
  });
}
function ftRender() {
  var rows = ftFiltered();
  var cols = [
    { id:'open', label:'Open' },
    { id:'handed', label:'Handed off' },
    { id:'overdue', label:'Overdue follow-up' },
    { id:'ofr', label:'Out for repair' },
    { id:'grounded', label:'Grounded' }
  ];
  if (FT_VIEW === 'list') {
    document.getElementById('ftBoard').style.display = 'none';
    document.getElementById('ftList').style.display = '';
    var h = '<table class="ft-tbl"><thead><tr><th>Vehicle</th><th>Type</th><th>Shop</th><th>Owner</th><th>Due</th><th>Age</th><th>Flags</th></tr></thead><tbody>';
    rows.forEach(function(t){
      var ho = /HANDOFF/i.test(t.notes||'');
      h += '<tr onclick="ftOpen(\''+t.id+'\')"><td><b>'+esc(t.veh)+'</b></td><td>'+esc(t.type)+'</td><td>'+esc(t.shop||'—')+'</td>'
        + '<td>'+esc(t.owner||'—')+'</td><td>'+esc(t.due||'—')+'</td><td>'+esc(t.age)+'</td><td>'
        + (t.overdue?'<span class="ft-pill red">overdue</span> ':'')
        + (t.ofr==='1'?'<span class="ft-pill amber">OFR</span> ':'')
        + (t.grounded==='1'?'<span class="ft-pill">grounded</span> ':'')
        + (ho?'<span class="ft-pill blue">handed off</span>':'')+'</td></tr>';
    });
    if (!rows.length) h += '<tr><td colspan="7" class="ft-empty">No open jobs match.</td></tr>';
    document.getElementById('ftList').innerHTML = h + '</tbody></table>';
    return;
  }
  document.getElementById('ftBoard').style.display = '';
  document.getElementById('ftList').style.display = 'none';
  var html = '';
  cols.forEach(function(c){
    var cards = rows.filter(function(t){ return t.col === c.id; });
    html += '<div class="ft-col"><div class="ft-col-h">'+c.label+'<span class="n">'+cards.length+'</span></div><div class="ft-col-b">';
    cards.forEach(function(t){
      var ho = /HANDOFF/i.test(t.notes||'');
      html += '<div class="ft-card" onclick="ftOpen(\''+t.id+'\')"><div class="veh">'+esc(t.veh)+'</div>'
        + '<div class="ty">'+esc(t.type)+(t.shop?' · '+esc(t.shop):'')+'</div>'
        + '<div class="meta">'+(t.overdue?'<span class="ft-pill red">overdue</span>':'')
        + (t.ofr==='1'?' <span class="ft-pill amber">OFR</span>':'')
        + (ho?' <span class="ft-pill blue">handed off</span>':'')+'</div>'
        + '<div class="age">'+esc(t.age)+' · due '+(t.due||'—')+(t.owner?' · '+esc(t.owner):'')+'</div></div>';
    });
    if (!cards.length) html += '<div class="ft-empty">Empty</div>';
    html += '</div></div>';
  });
  document.getElementById('ftBoard').innerHTML = html;
}
function esc(s){ return (s||'').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;'); }
function isoToMdy(v){ var p=(v||'').split('-'); return p.length===3 ? p[1]+'/'+p[2]+'/'+p[0] : (v||''); }
function ftView(v){ FT_VIEW=v; document.getElementById('ftVBoard').classList.toggle('on',v==='board'); document.getElementById('ftVList').classList.toggle('on',v==='list'); ftRender(); }
function ftKpi(el,f){ document.querySelectorAll('.ft-kpi').forEach(function(k){k.classList.remove('on');}); el.classList.add('on'); FT_KPI=f; ftRender(); }
function ftShowDrawer(mode){
  document.getElementById('ftViewPane').style.display = mode === 'view' ? '' : 'none';
  document.getElementById('ftCreatePane').style.display = mode === 'create' ? '' : 'none';
  document.getElementById('ftScrim').classList.add('on');
  document.getElementById('ftDrawer').classList.add('on');
}
function ftParseTrail(desc){
  var handoffs = [], notes = [], other = [];
  (desc||"").split(/\r?\n/).forEach(function(line){
    var s = line.trim();
    if (!s) return;
    if (/HANDOFF\s+/i.test(s)) handoffs.push(s);
    else if (/^\[[^\]]+\]/.test(s)) notes.push(s);
    else other.push(s);
  });
  return { handoffs:handoffs, notes:notes, other:other };
}
var FT_COMBO = {
  veh:   { hi:-1, allowNew:false, rows:function(){ return (FT_VEHS||[]).map(function(r){ return { id:r.id, nm:r.nm+(r.vin?" · "+r.vin:"") }; }); } },
  mtype: { hi:-1, allowNew:false, rows:function(){ return (FT_TYPES||[]).map(function(r){ return { id:r.id, nm:r.nm+(r.cat?" ("+r.cat+")":"") }; }); } },
  shop:  { hi:-1, allowNew:true, newLabel:"+ Add new shop", rows:function(){ return (FT_SHOPS||[]).map(function(s){ return { id:s, nm:s }; }); } },
  asn:   { hi:-1, allowNew:false, rows:function(){ return ftDispRows(); } },
  reAsn: { hi:-1, allowNew:false, skip:function(){ return FT_CUR && FT_CUR.owner ? FT_CUR.owner : ""; }, rows:function(){ return ftDispRows(); } }
};
function ftComboClear(key){
  var el = document.getElementById(key);
  var q = document.getElementById(key+"_q");
  var sel = document.getElementById(key+"_sel");
  var list = document.getElementById(key+"_list");
  if (el) el.value = "";
  if (q) q.value = "";
  if (sel) sel.textContent = "Nothing selected";
  if (list) list.classList.remove("on");
  if (FT_COMBO[key]) FT_COMBO[key].hi = -1;
  if (key === "shop") {
    var w = document.getElementById("ftCShopNewWrap");
    if (w) w.style.display = "none";
  }
}
function ftComboSet(key, id, nm){
  document.getElementById(key).value = id;
  document.getElementById(key+"_q").value = nm;
  document.getElementById(key+"_sel").textContent = id === "__new" ? "Add new shop" : ("Selected: " + nm);
  document.getElementById(key+"_list").classList.remove("on");
  FT_COMBO[key].hi = -1;
  if (key === "shop") {
    document.getElementById("ftCShopNewWrap").style.display = id === "__new" ? "" : "none";
    if (id === "__new") document.getElementById("ftCShopNew").focus();
  }
}
function ftComboVal(key){ return (document.getElementById(key).value || "").trim(); }
function ftComboRender(key, rows){
  var box = document.getElementById(key+"_list");
  var cfg = FT_COMBO[key];
  var skip = cfg.skip ? cfg.skip() : "";
  rows = (rows||[]).filter(function(r){ return !skip || r.id !== skip; });
  if (cfg.allowNew) rows = rows.concat([{ id:"__new", nm: cfg.newLabel || "+ Add new" }]);
  if (!rows.length) {
    box.innerHTML = "<div class=\"empty\">No matches</div>";
    box.classList.add("on");
    cfg.hi = -1;
    return;
  }
  var h = "", max = Math.min(rows.length, 80);
  for (var i = 0; i < max; i++) {
    h += "<div data-id=\""+esc(rows[i].id)+"\" data-nm=\""+esc(rows[i].nm)+"\" "
      + "onmousedown=\"event.preventDefault();ftComboSet('"+key+"', this.getAttribute('data-id'), this.getAttribute('data-nm'))\">"
      + esc(rows[i].nm)+"</div>";
  }
  if (rows.length > max) h += "<div class=\"empty\">Showing "+max+" of "+rows.length+" - type more to narrow</div>";
  box.innerHTML = h;
  box.classList.add("on");
  cfg.hi = -1;
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
      if (key === "shop") document.getElementById("ftCShopNewWrap").style.display = "none";
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
  for (var i = 0; i < items.length; i++) items[i].classList.toggle("on", i === cfg.hi);
  if (cfg.hi >= 0 && items[cfg.hi]) items[cfg.hi].scrollIntoView({ block:"nearest" });
}
function ftEnsureDispatchers(cb){
  if (FT_DISPS) { if (cb) cb(); return; }
  ftAjax({ requestType:"vehDispatchers" }, function(resp){
    try { FT_DISPS = JSON.parse(resp); } catch(e){ FT_DISPS = []; }
    if (cb) cb();
  });
}
function ftOpen(id){
  ftAjax({ requestType:"fleetBoardGet", logID:id }, function(resp){
    var d; try { d = JSON.parse(resp); } catch(e){ alert("Could not load job"); return; }
    if (d.status === false || resp.indexOf("<status>false")>=0) { alert("Job not found"); return; }
    FT_CUR = d;
    document.getElementById("ftDrTitle").textContent = d.veh + " · " + d.type;
    document.getElementById("ftDrSub").textContent = (d.vin||"") + (d.ofr==="1"?" · Out for repair":"") + (d.grounded==="1"?" · Grounded":"");
    document.getElementById("ftDrType").textContent = d.type || "-";
    document.getElementById("ftDrShop").textContent = d.shop || "-";
    document.getElementById("ftDrOwn").textContent = d.owner || "-";
    document.getElementById("ftDrDue").textContent = d.due || "-";
    document.getElementById("ftDrSvc").textContent = d.svc || "-";
    document.getElementById("ftDrRo").textContent = d.ro || "-";
    document.getElementById("ftDrNote").value = "";
    document.getElementById("ftVehLink").onclick = function(){ submitPageDataForm("<%=SubmitType.BROWSE%>","AdminVehicle", d.vehId); };
    var parsed = ftParseTrail(d.notes);
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
    document.getElementById("ftDrNotes").textContent = parsed.other.length
      ? parsed.other.join("\n")
      : (d.notes && !parsed.handoffs.length && !parsed.notes.length ? d.notes : "-");
    var trail = "";
    (d.trail||[]).forEach(function(x){
      trail += "<div class=\"ft-tl\"><div class=\"t\">"+esc(x.t)+" · "+esc(x.u)+"</div><div class=\"m\">"+esc(x.m)+"</div></div>";
    });
    document.getElementById("ftTrail").innerHTML = trail || "<div class=\"ft-empty\">No notes yet.</div>";
    ftComboClear("reAsn");
    ftShowDrawer("view");
    ftEnsureDispatchers(function(){});
  });
}
function ftClose(){ document.getElementById("ftScrim").classList.remove("on"); document.getElementById("ftDrawer").classList.remove("on"); FT_CUR=null; }
function ftToday(){
  var d = new Date();
  return d.getFullYear()+"-"+("0"+(d.getMonth()+1)).slice(-2)+"-"+("0"+d.getDate()).slice(-2);
}
function ftShopVal(){
  var v = ftComboVal("shop");
  return v === "__new" ? (document.getElementById("ftCShopNew").value || "").trim() : v;
}
function ftReassign(){
  if (!FT_CUR) return;
  var to = ftComboVal("reAsn");
  if (!to) { alert("Select a dispatcher"); return; }
  if (to === (FT_CUR.owner || "")) { alert("Already assigned to that dispatcher"); return; }
  var note = document.getElementById("ftDrNote").value.trim();
  if (!confirm("Hand off this fleet task to "+to+"? Prior notes stay on the job.")) return;
  ftAjax({ requestType:"fleetBoardReassign", logID:FT_CUR.id, assigned:to, note:note }, function(resp){
    if (resp.indexOf("<status>true")>=0) { ftClose(); ftLoad(); }
    else alert(/<mesg>([^<]*)<\/mesg>/.exec(resp) ? RegExp.$1 : "Hand off failed");
  });
}
function ftNew(){
  FT_CUR = null;
  document.getElementById("ftDrTitle").textContent = "New fleet task";
  document.getElementById("ftDrSub").textContent = "Creates an open maintenance job";
  document.getElementById("ftCSvc").value = ftToday();
  document.getElementById("ftCDue").value = "";
  document.getElementById("ftCRo").value = "";
  document.getElementById("ftCParts").value = "";
  document.getElementById("ftCNotes").value = "";
  document.getElementById("ftCShopNew").value = "";
  ftComboClear("veh"); ftComboClear("mtype"); ftComboClear("shop"); ftComboClear("asn");
  ftShowDrawer("create");
  if (!FT_VEHS) {
    ftAjax({ requestType:"fleetBoardVehicles" }, function(resp){
      try { FT_VEHS = JSON.parse(resp); } catch(e){ FT_VEHS = []; }
    });
  }
  if (!FT_TYPES) {
    ftAjax({ requestType:"fleetBoardTypes" }, function(resp){
      try { FT_TYPES = JSON.parse(resp); } catch(e){ FT_TYPES = []; }
      FT_TYPE_MAP = {};
      FT_TYPES.forEach(function(t){ FT_TYPE_MAP[t.id]=t; });
    });
  } else {
    FT_TYPE_MAP = {};
    FT_TYPES.forEach(function(t){ FT_TYPE_MAP[t.id]=t; });
  }
  if (!FT_SHOPS) {
    ftAjax({ requestType:"vehShops" }, function(resp){
      try { FT_SHOPS = JSON.parse(resp); } catch(e){ FT_SHOPS = []; }
    });
  }
  ftEnsureDispatchers(function(){ ftDefaultAssigned(); });
}
function ftCreateSave(){
  var vehId = ftComboVal("veh");
  var mTypeId = ftComboVal("mtype");
  var svcDate = document.getElementById("ftCSvc").value;
  if (!vehId) { alert("Select a vehicle"); return; }
  if (!mTypeId) { alert("Pick a maintenance type"); return; }
  if (!svcDate) { alert("Service date is required"); return; }
  var shop = ftShopVal();
  if (ftComboVal("shop") === "__new" && !shop) {
    alert("Enter the new shop name"); return;
  }
  var t = FT_TYPE_MAP[mTypeId] || {};
  ftAjax({
    requestType:"fleetBoardCreate",
    vehId: vehId,
    mTypeId: mTypeId,
    mType: t.nm || "",
    mCode: t.code || "",
    mCat: t.cat || "",
    svcDate: isoToMdy(svcDate),
    followUp: isoToMdy(document.getElementById("ftCDue").value),
    shop: shop,
    assigned: ftComboVal("asn"),
    roNum: document.getElementById("ftCRo").value,
    parts: document.getElementById("ftCParts").value,
    notes: document.getElementById("ftCNotes").value
  }, function(resp){
    if (resp.indexOf("<status>true")>=0) {
      FT_SHOPS = null;
      ftClose(); ftLoad();
    }
    else alert(/<mesg>([^<]*)<\/mesg>/.exec(resp) ? RegExp.$1 : "Save failed");
  });
}

function ftSaveNote(){
  if (!FT_CUR) return;
  var note = document.getElementById('ftDrNote').value.trim();
  if (!note) { alert('Enter a note'); return; }
  ftAjax({ requestType:'fleetBoardNote', logID:FT_CUR.id, note:note }, function(resp){
    if (resp.indexOf('<status>true')>=0) { ftOpen(FT_CUR.id); ftLoad(); }
    else alert(/<mesg>([^<]*)<\/mesg>/.exec(resp) ? RegExp.$1 : 'Save failed');
  });
}
function ftCloseJob(){
  if (!FT_CUR || !confirm('Close this maintenance job?')) return;
  var note = document.getElementById('ftDrNote').value.trim();
  ftAjax({ requestType:'fleetBoardClose', logID:FT_CUR.id, note:note }, function(resp){
    if (resp.indexOf('<status>true')>=0) { ftClose(); ftLoad(); }
    else alert(/<mesg>([^<]*)<\/mesg>/.exec(resp) ? RegExp.$1 : 'Close failed');
  });
}
ftLoad();
document.addEventListener('click', function(e){
  document.querySelectorAll('.ft-combo').forEach(function(c){
    if (!c.contains(e.target)) {
      var list = c.querySelector('.ft-combo-list');
      if (list) list.classList.remove('on');
    }
  });
});
</script>
<%@ include file="includeFooter.jsp"%>