<!DOCTYPE html>
<%@ page import="java.util.*, com.util.*, com.beans.*"%>
<jsp:useBean id="_errorBean" class="com.beans.ErrorBean" scope="request" />
<jsp:useBean id="_mainUtil" class="com.util.MainUtil" scope="request" />
<%
int submitType = request.getAttribute("submitType") == null ? SubmitType.CREATE : Integer.parseInt(request.getAttribute("submitType").toString().trim());

SearchBean _searchBean = new SearchBean();
Object _rawBeanObj = request.getAttribute("_recordBean");
if (_rawBeanObj instanceof SearchBean) {
    _searchBean = (SearchBean) _rawBeanObj;
    request.removeAttribute("_recordBean");
}
%>
<jsp:useBean id="_recordBean" class="com.beans.AdminEmployee" scope="request" />
<%
/* ═══════════════ LIST VIEW (redesigned — MVPx list standard) ═══════════════ */
if (submitType == SubmitType.SEARCH) {
    List dataList = _searchBean.getDataList() == null ? new ArrayList() : _searchBean.getDataList();
    int cntTotal = dataList.size(), cntActive = 0, cntInactive = 0, cntOptIn = 0, cntTerm = 0;
    List<String> roleNames = new ArrayList<String>();
    List<String> availNames = new ArrayList<String>();
    List<String> stNames = new ArrayList<String>();
    /* [0]=id 1=name 2=mobile 3=lang 4=sms 5=expiry 6=avail 7=role 8=status 9=pill 10=terminated */
    List<String[]> rows = new ArrayList<String[]>();
    for (int i = 0; i < dataList.size(); i++) {
        List r = (List) dataList.get(i);
        String[] c = new String[11];
        for (int j = 0; j < 9 && j < r.size(); j++)
            c[j] = r.get(j) == null ? "" : r.get(j).toString().trim();
        if (r.size() > 9) c[10] = r.get(9) == null || "0".equals(r.get(9).toString().trim()) ? "" : "1";
        for (int j = 0; j < 11; j++) if (c[j] == null) c[j] = "";
        String status = c[8];
        String pill = "slate";
        if ("Active".equalsIgnoreCase(status)) pill = "green";
        else if (status.toLowerCase().contains("inactive")) pill = "red";
        c[9] = pill;
        if ("Opt-in".equalsIgnoreCase(c[4])) cntOptIn++;
        if ("1".equals(c[10]) || status.toLowerCase().contains("termin")) { cntTerm++; c[10] = "1"; } else if ("Active".equalsIgnoreCase(status)) cntActive++; else cntInactive++;
        if (c[7].length() > 0 && !roleNames.contains(c[7])) roleNames.add(c[7]);
        if (c[6].length() > 0 && !availNames.contains(c[6])) availNames.add(c[6]);
        if (status.length() > 0 && !stNames.contains(status)) stNames.add(status);
        rows.add(c);
    }
    Collections.sort(roleNames); Collections.sort(availNames); Collections.sort(stNames);
%>
<%@ include file="includeHeader.jsp"%>
<link rel="stylesheet" href="../jsp/assets/css/mvpx-list.css?v=20260911a">
<script src="../jsp/assets/js/mvpx-list.js?v=20260722d"></script>

<div class="da-wrap">

  <div class="da-headrow">
    <div>
      <h2>Employees</h2>
      <div class="statchips">
        <span class="statchip em-chip" onclick="emChipReset()" title="Clear filters"><span class="dot" style="background:var(--da-blue)"></span><b><%=cntTotal%></b> employees</span>
        <span class="statchip em-chip" onclick="emChipF('filterStatus','active')"><span class="dot" style="background:var(--da-green)"></span><b id="emcAct"><%=cntActive%></b> active</span>
        <span class="statchip em-chip" onclick="emChipF('filterStatus','inactive')"><span class="dot" style="background:#64748B"></span><b id="emcInact"><%=cntInactive%></b> inactive</span>
        <span class="statchip em-chip" onclick="emChipF('filterSms','opt-in')"><span class="dot" style="background:var(--da-amber)"></span><b><%=cntOptIn%></b> SMS opt-in</span>
        <span class="statchip em-chip" onclick="emChipF('filterStatus','terminated')"><span class="dot" style="background:var(--status-action-fg)"></span><b id="emcTerm"><%=cntTerm%></b> terminated</span>
      </div>
    </div>
    <div style="display:flex;gap:7px;align-items:center;flex-wrap:wrap">
      <button class="btn2" onclick="mvpxEditSelected(<%=SubmitType.UPDATE%>)" title="Bulk edit the selected employees"><i class="fas fa-pen"></i> Edit Selected</button>
      <button class="btn2" onclick="mvpxPrint('xls')" title="Export to Excel"><i class="fas fa-file-excel"></i> Excel</button>
      <button class="btn2" onclick="mvpxPrint('')" title="Download PDF"><i class="fas fa-file-pdf"></i> PDF</button>
      <button class="btn2 primary" onclick="submitPageDataForm('<%=SubmitType.CREATE%>','<%=_searchBean.getController()%>');">&#xFF0B; New</button>
    </div>
  </div>

  <div class="da-toolbar">
    <input class="da-flt" id="filterName" oninput="mvpxApplyFilters()" placeholder="Name&hellip;" style="min-width:170px">
    <input class="da-flt" id="filterMobile" oninput="mvpxApplyFilters()" placeholder="Mobile&hellip;" style="max-width:130px">
    <select class="da-flt" id="filterRole" onchange="mvpxApplyFilters()">
      <option value="">All roles</option>
      <%for(String v : roleNames){%><option value="<%=v.toLowerCase()%>"><%=v%></option><%}%>
    </select>
    <select class="da-flt" id="filterAvail" onchange="mvpxApplyFilters()">
      <option value="">All availability</option>
      <%for(String v : availNames){%><option value="<%=v.toLowerCase()%>"><%=v%></option><%}%>
    </select>
    <select id="filterSms" style="display:none" onchange="mvpxApplyFilters()"><option value=""></option><option value="opt-in">Opt-in</option><option value="opt-out">Opt-out</option></select>
    <select class="da-flt" id="filterStatus" onchange="mvpxApplyFilters()">
      <option value="">All statuses</option>
      <option value="active">Active</option><option value="inactive">Inactive</option><option value="terminated">Terminated</option>
    </select>
  </div>

  <div class="da-chips" id="activeChips"></div>
  <div class="da-typesum" id="roleSum"></div>
  <div class="da-typesum" id="availSum"></div>

  <%if(_errorBean != null && _errorBean.getType().length() > 0){%>
  <div class="row text-center mt-2">
    <section class="alert_section">
      <div class="alert-box <%=_errorBean.getType()%>Color"><%=_errorBean.getMesg()%></div>
    </section>
  </div>
  <%}%>

  <div class="tablewrap">
    <table>
      <thead>
        <tr>
          <th style="width:32px"><input type="checkbox" id="selectAll" onchange="mvpxToggleSelectAll(this)"></th>
          <th>Employee</th>
          <th>Mobile</th>
          <th>Language</th>
          <th>SMS</th>
          <th>Expiry</th>
          <th>Availability</th>
          <th>Role</th>
          <th>Active</th>
          <th>Actions</th>
        </tr>
      </thead>
      <tbody id="ciRows">
        <%if(rows.isEmpty()){%>
        <tr><td colspan="10" class="da-empty">No employees found.</td></tr>
        <%}%>
        <%for(String[] r : rows){%>
        <tr data-id="<%=r[0]%>"
            data-emp="<%=r[1].toLowerCase()%>"
            data-mob="<%=r[2].toLowerCase()%>"
            data-role="<%=r[7].toLowerCase()%>"
            data-avail="<%=r[6].toLowerCase()%>"
            data-st="<%="1".equals(r[10]) ? "terminated" : ("Active".equalsIgnoreCase(r[8]) ? "active" : "inactive")%>"
            data-sms="<%=r[4].toLowerCase()%>">
          <td><input type="checkbox" class="rowCheck" value="<%=r[0]%>"></td>
          <td class="nm"><a href="javascript:void(0)" style="color:inherit" onclick="submitPageDataForm('<%=SubmitType.BROWSE%>','<%=_searchBean.getController()%>','<%=r[0]%>')"><%=r[1]%></a></td>
          <td><%=r[2].length()>0?r[2]:"&mdash;"%></td>
          <td class="meta"><%=r[3].length()>0?r[3]:"&mdash;"%></td>
          <td class="meta"><%=r[4].length()>0?r[4]:"&mdash;"%></td>
          <td class="meta"><%=r[5].length()>0?r[5]:"&mdash;"%></td>
          <td class="meta"><%=r[6].length()>0?r[6]:"&mdash;"%></td>
          <td><%=r[7].length()>0?r[7]:"&mdash;"%></td>
          <td><button type="button" class="em-tgl<%="Active".equalsIgnoreCase(r[8])?" on":""%>" onclick="emToggle('<%=r[0]%>', this)" title="Active / Inactive"><span class="kn"></span></button></td>
          <td><div class="em-act">
            <button type="button" class="btn2 sm dark" onclick="emScore('<%=r[0]%>','<%=r[1].replaceAll("'","\\\\'")%>')">Scorecard</button>
            <button type="button" class="btn2 sm tblue" onclick="emEdit('<%=r[0]%>')">Edit</button>
            <button type="button" class="btn2 sm tamber" onclick="emInc('<%=r[0]%>','<%=r[1].replaceAll("'","\\\\'")%>')">Incidents</button>
            <button type="button" class="btn2 sm tslate" onclick="emHist('<%=r[0]%>','<%=r[1].replaceAll("'","\\\\'")%>')">History</button>
            <button type="button" class="btn2 sm tgreen" onclick="emOsha('<%=r[0]%>','<%=r[1].replaceAll("'","\\\\'")%>')">OSHA</button>
            <%if("1".equals(r[10])){%><span class="pill red"><span class="d"></span>TERMINATED</span>
            <%}else{%><button type="button" class="btn2 sm tred" onclick="emTerm('<%=r[0]%>','<%=r[1].replaceAll("'","\\\\'")%>')">Terminate</button><%}%>
          </div></td>
        </tr>
        <%}%>
      </tbody>
    </table>
    <div class="tablefoot">
      <span id="showCount">Showing <%=rows.size()%> of <%=cntTotal%></span>
      <button class="btn2 sm" onclick="submitPageDataForm('<%=SubmitType.SEARCH%>','<%=_searchBean.getController()%>')">&#8635; Refresh</button>
    </div>
  </div>
</div>

<div class="da-toast" id="daToast"></div>
<style>
.em-tgl{width:34px;height:19px;border-radius:10px;border:1px solid var(--da-line,#E4E8F0);background:#D8D6CE;position:relative;cursor:pointer;padding:0;vertical-align:middle;transition:background .15s}
.em-tgl .kn{position:absolute;top:2px;left:2px;width:13px;height:13px;border-radius:50%;background:#fff;box-shadow:0 1px 2px rgba(0,0,0,.25);transition:left .15s}
.em-tgl.on{background:var(--status-ok-solid);border-color:var(--status-ok-solid)}
.em-tgl.on .kn{left:17px}
.em-tgl:disabled{opacity:.5}
.em-chip{cursor:pointer;user-select:none}
.em-chip:hover{border-color:#0B1220}
.em-act{display:flex;gap:4px;align-items:center;white-space:nowrap;flex-wrap:wrap}
.em-act .btn2{padding:2px 8px;font-size:10.5px}
.btn2.dark{background:#0B1220;border-color:#0B1220;color:#fff}
.btn2.tblue{background:var(--status-info-bg);border-color:var(--status-info-border);color:var(--status-info-fg)}
.btn2.tamber{background:var(--status-warn-bg);border-color:var(--status-warn-border);color:var(--status-warn-fg)}
.btn2.tslate{background:var(--status-neutral-bg);border-color:var(--status-neutral-border);color:var(--status-neutral-fg)}
.btn2.tgreen{background:var(--status-ok-bg);border-color:var(--status-ok-border);color:var(--status-ok-fg)}
.btn2.tred{background:var(--status-action-bg);border-color:var(--status-action-border);color:var(--status-action-fg)}
.pill.red{background:var(--status-action-bg);color:var(--status-action-fg)}.pill.red .d{background:var(--status-action-fg)}
.pill.escalation{background:var(--status-escalation-bg);color:var(--status-escalation-fg)}.pill.escalation .d{background:var(--status-escalation-fg)}
.em-scrim{display:none;position:fixed;inset:0;background:rgba(20,21,25,.35);z-index:390}
.em-scrim.on{display:block}
.em-drawer{position:fixed;top:0;right:0;width:min(460px,100vw);height:100vh;box-sizing:border-box;background:#fff;border-left:1px solid var(--da-line,#E4E8F0);box-shadow:-8px 0 30px rgba(0,0,0,.14);z-index:400;padding:14px 18px;overflow:hidden;transform:translateX(calc(100% + 40px));visibility:hidden;transition:transform .22s ease,visibility .22s;display:flex;flex-direction:column}
.em-drawer.on{transform:translateX(0);visibility:visible}
.em-drawer.wide{width:min(540px,100vw)}
.em-drawer h3{margin:0 0 10px;font-size:16px;display:flex;align-items:center;gap:8px;font-weight:800}
.em-drawer h3 .sub{color:#64748B;font-weight:500;font-size:12.5px}
.em-x{margin-left:auto;border:0;background:transparent;font-size:15px;cursor:pointer;color:#64748B}
.em-scroll{flex:1;min-height:0;overflow-y:auto;scrollbar-width:none}
.em-scroll::-webkit-scrollbar{display:none}
.em-grid{display:grid;grid-template-columns:1fr 1fr;gap:8px 12px}
.em-drawer label{display:flex;flex-direction:column;gap:3px;font-size:10px;letter-spacing:.06em;text-transform:uppercase;color:#64748B;margin-top:4px;min-width:0}
.em-drawer input,.em-drawer select,.em-drawer textarea{border:1px solid var(--da-line,#E4E8F0);border-radius:7px;padding:7px 9px;font-size:13px;font-family:inherit;background:#FAFBFE;width:100%;min-width:0;box-sizing:border-box}
.em-req{display:none}
.em-drawer label:has(.em-req){color:var(--status-action-fg);font-weight:700}
.em-btns{display:flex;gap:8px;align-items:center;margin-top:14px}
.em-day{display:inline-flex;align-items:center;gap:4px;font-size:11px;font-weight:700;padding:3px 10px;border-radius:999px;cursor:pointer;background:#F1F5F9;color:#64748B;border:1px solid var(--da-line,#E4E8F0);user-select:none}
.em-day.on{background:var(--status-ok-bg);color:var(--status-ok-fg);border-color:var(--status-ok-border)}
.em-hx{border:1px solid var(--da-line,#E4E8F0);border-radius:9px;padding:8px 10px;margin-bottom:7px;font-size:12.5px}
.em-hx .hd{display:flex;gap:8px;align-items:center;font-weight:700;flex-wrap:wrap}
.em-hx .meta{font-size:11.5px;color:#64748B;margin-top:2px;line-height:1.5;white-space:pre-wrap;word-break:break-word}
.em-sec{font-size:10px;font-weight:700;letter-spacing:.1em;text-transform:uppercase;color:#64748B;margin:12px 0 6px;border-bottom:1px solid var(--da-line,#E4E8F0);padding-bottom:3px}
.em-sc{border:1px solid var(--da-line,#E4E8F0);border-radius:10px;padding:10px 12px;margin-bottom:8px}
.em-sc .big{font-size:30px;font-weight:800}
.em-row{display:flex;justify-content:space-between;font-size:12.5px;padding:3px 0;border-bottom:1px dashed #EEF1F6}
.em-row b{font-family:monospace}
</style>
<div class="em-scrim" id="emScrim" onclick="emClose()"></div>

<div class="em-drawer" id="emEditDr">
  <h3>Edit Employee <span class="sub" id="emEditNm"></span><button class="em-x" onclick="emClose()">&#10005;</button></h3>
  <input type="hidden" id="emId">
  <div class="em-scroll">
    <div class="em-grid">
      <label>First name<span class="em-req">*</span><input id="emFn"></label>
      <label>Last name<span class="em-req">*</span><input id="emLn"></label>
      <label>Mobile<span class="em-req">*</span><input id="emMobile" inputmode="numeric" style="font-family:monospace"></label>
      <label>Preferred language<select id="emLang"><option></option><option>English</option><option>Spanish</option><option>Creole</option><option>Portuguese</option><option>French</option></select></label>
      <label>SMS preference<select id="emSms"><option>Opt-in</option><option>Opt-out</option></select></label>
      <label>ID expiry<input type="date" id="emExp"></label>
      <label>Role<select id="emRole"><option value="4">DA Associate</option><option value="1">Dispatcher</option><option value="3">Lead Dispatcher</option><option value="2">Manager</option></select></label>
      <label>Station<input id="emStation"></label>
      <label>Transporter ID<input id="emTid" readonly style="opacity:.65;font-family:monospace;font-size:11px"></label>
      <label>Position<input id="emPosn" readonly style="opacity:.65"></label>
    </div>
    <label style="margin-top:10px">Availability - tap days on/off</label>
    <div id="emDays" style="display:flex;gap:5px;margin-top:4px;flex-wrap:wrap"></div>
  </div>
  <div class="em-btns">
    <button class="btn2" onclick="emClose()">Cancel</button>
    <button class="btn2 primary" id="emSaveBtn" onclick="emSave()">Save</button>
    <a href="javascript:void(0)" style="margin-left:auto;font-size:12px;color:#64748B" onclick="submitPageDataForm('4','AdminEmployee', document.getElementById('emId').value)">Full page &#8599;</a>
  </div>
</div>

<div class="em-drawer wide" id="emIncDr">
  <h3>Incidents <span class="sub" id="emIncNm"></span><button class="em-x" onclick="emClose()">&#10005;</button></h3>
  <div class="em-scroll">
    <div class="em-hx" style="border-color:#BFDCC8;background:#F7FBF7">
      <div class="hd">&#xFF0B; New Incident</div>
      <div class="em-grid" style="margin-top:6px">
        <label>Type<span class="em-req">*</span><select id="emIncType"></select></label>
        <label>Date<span class="em-req">*</span><input type="date" id="emIncDate"></label>
      </div>
      <label style="margin-top:6px">Description - full size</label>
      <textarea id="emIncDesc" rows="5" style="resize:vertical" placeholder="What happened - as much detail as needed"></textarea>
      <div style="text-align:right;margin-top:6px"><button class="btn2 primary sm" id="emIncAddBtn" onclick="emIncAdd()">Save Incident</button></div>
    </div>
    <div id="emIncList"></div>
  </div>
</div>

<div class="em-drawer wide" id="emHistDr">
  <h3>History <span class="sub" id="emHistNm"></span><button class="em-x" onclick="emClose()">&#10005;</button></h3>
  <div class="em-scroll" id="emHistBody"></div>
</div>

<div class="em-drawer" id="emOshaDr">
  <h3>Add OSHA Incident <span class="sub" id="emOshaNm"></span><button class="em-x" onclick="emClose()">&#10005;</button></h3>
  <div class="em-scroll">
    <div class="em-grid">
      <label>Incident date<span class="em-req">*</span><input type="date" id="emOshaDate"></label>
      <label>Incident time<input type="time" id="emOshaTime"></label>
      <label>Reported date<input type="date" id="emOshaRepDate"></label>
      <label>Reported time<input type="time" id="emOshaRepTime"></label>
      <label>Type<span class="em-req">*</span><select id="emOshaType"><option></option><option>Slip / trip / fall</option><option>Dog encounter</option><option>Vehicle-related injury</option><option>Lifting / strain</option><option>Heat-related</option><option>Other</option></select></label>
      <label>EMT number<input id="emOshaEmt" placeholder="EMT #"></label>
    </div>
    <label style="margin-top:6px">Location</label>
    <input id="emOshaLoc" placeholder="Station area / route / address">
    <label style="margin-top:6px">Description - full size</label>
    <textarea id="emOshaDesc" rows="9" style="resize:vertical" placeholder="What happened, injuries, treatment, witnesses - as much detail as needed"></textarea>
  </div>
  <div class="em-btns">
    <button class="btn2" onclick="emClose()">Cancel</button>
    <button class="btn2 primary" id="emOshaBtn" onclick="emOshaSave()">Save OSHA Incident</button>
  </div>
</div>

<div class="em-drawer" id="emTermDr">
  <h3 style="color:#C62828">Terminate <span class="sub" id="emTermNm"></span><button class="em-x" onclick="emClose()">&#10005;</button></h3>
  <div class="em-scroll">
    <div class="em-grid">
      <label>Termination date<span class="em-req">*</span><input type="date" id="emTermDate"></label>
      <label>Type<span class="em-req">*</span><select id="emTermType"><option></option><option>Voluntary resignation</option><option>Involuntary</option><option>No call / no show</option><option>End of contract</option><option>Other</option></select></label>
    </div>
    <label style="margin-top:6px">Reason<span class="em-req">*</span></label>
    <input id="emTermReason" placeholder="Primary reason">
    <label style="margin-top:6px">Comments - full size</label>
    <textarea id="emTermCm" rows="5" style="resize:vertical" placeholder="Notice given, equipment returned, final day details..."></textarea>
    <div style="font-size:11.5px;color:#64748B;margin-top:8px">Saving records the termination, marks the DA Inactive, and logs it to History.</div>
  </div>
  <div class="em-btns">
    <button class="btn2" onclick="emClose()">Cancel</button>
    <button class="btn2 danger" id="emTermBtn" onclick="emTermSave()">Terminate</button>
  </div>
</div>

<div class="em-drawer" id="emScoreDr">
  <h3>DA Scorecard <span class="sub" id="emScNm"></span>
    <select id="emScWk" onchange="emScoreLoad()" style="margin-left:auto;border:1px solid var(--da-line);border-radius:6px;font-size:10.5px;padding:2px 5px;font-family:monospace"></select>
    <button class="em-x" onclick="emClose()">&#10005;</button></h3>
  <div class="em-scroll" id="emScBody"></div>
</div>

<script>
var EM = { id:'', nm:'', days:[] };
function emChipF(selId, val){
  var s = document.getElementById(selId);
  if (!s) return;
  s.value = (s.value === val ? '' : val);
  mvpxApplyFilters();
}
function emChipReset(){
  ['filterName','filterMobile','filterRole','filterAvail','filterStatus','filterSms'].forEach(function(id){
    var el = document.getElementById(id); if (el) el.value = '';
  });
  mvpxApplyFilters();
}
function emChips(){
  var a = 0, i = 0, tm = 0;
  document.querySelectorAll('#ciRows tr[data-id]').forEach(function(r){
    if (r.dataset.st === 'terminated') tm++;
    else if (r.dataset.st === 'active') a++;
    else i++;
  });
  var e1 = document.getElementById('emcAct'), e2 = document.getElementById('emcInact'), e3 = document.getElementById('emcTerm');
  if (e1) e1.textContent = a;
  if (e2) e2.textContent = i;
  if (e3) e3.textContent = tm;
}
var EM_DAYNAMES = ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'];
function emEsc(s){ return String(s == null ? '' : s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/"/g,'&quot;'); }
function emMdyIso(v){ var p=(v||'').split('/'); return p.length===3 ? p[2]+'-'+p[0]+'-'+p[1] : ''; }
function emIsoMdy(v){ var p=(v||'').split('-'); return p.length===3 ? p[1]+'/'+p[2]+'/'+p[0] : ''; }
function emAjax(ctrl, params, cb){
  var body = new URLSearchParams();
  body.append('submitType', 10);
  body.append('controller', ctrl);
  Object.keys(params).forEach(function(k){ body.append(k, params[k]); });
  ['entityID','loginUser','loginUserID','loginUserRoles','loginUserDisplayName'].forEach(function(k){
    var el = document.getElementById(k); if (el) body.append(k, el.value);
  });
  fetch('MVPGServlet', { method:'POST', headers:{'Content-Type':'application/x-www-form-urlencoded'}, body: body.toString() })
    .then(function(r){ return r.text(); }).then(cb)
    .catch(function(){ mvpxToast('Request failed', false); });
}
function emOpen(id){
  ['emEditDr','emIncDr','emHistDr','emOshaDr','emTermDr','emScoreDr'].forEach(function(d){
    document.getElementById(d).classList.toggle('on', d === id);
  });
  document.getElementById('emScrim').classList.add('on');
}
function emClose(){
  ['emEditDr','emIncDr','emHistDr','emOshaDr','emTermDr','emScoreDr'].forEach(function(d){
    document.getElementById(d).classList.remove('on');
  });
  document.getElementById('emScrim').classList.remove('on');
}
document.addEventListener('keydown', function(e){ if (e.key === 'Escape') emClose(); });

function emToggle(id, btn){
  var on = btn.classList.contains('on') ? 0 : 1;
  btn.disabled = true;
  emAjax('AdminEmployee', { requestType:'empToggle', employeeID:id, on:on }, function(resp){
    btn.disabled = false;
    var m = /<mesg>([^<]*)<\/mesg>/.exec(resp);
    if (resp.indexOf('<status>true') >= 0) {
      btn.classList.toggle('on', on === 1);
      var tr = btn.closest('tr');
      if (tr && tr.dataset.st !== 'terminated') tr.dataset.st = on === 1 ? 'active' : 'inactive';
      emChips();
      mvpxToast(m && m[1] ? m[1] : 'Updated', true);
    }
    else mvpxToast(m && m[1] ? m[1] : 'Update failed', false);
  });
}

function emDaysRender(){
  var h = '';
  EM_DAYNAMES.forEach(function(d){
    h += '<span class="em-day' + (EM.days.indexOf(d) >= 0 ? ' on' : '') + '" onclick="emDayTgl(\'' + d + '\')">' + d.toUpperCase() + '</span>';
  });
  document.getElementById('emDays').innerHTML = h;
}
function emDayTgl(d){
  var i = EM.days.indexOf(d);
  if (i >= 0) EM.days.splice(i, 1); else EM.days.push(d);
  emDaysRender();
}
function emEdit(id){
  emAjax('AdminEmployee', { requestType:'empGet', employeeID:id }, function(resp){
    var d; try { d = JSON.parse(resp); } catch(e){ mvpxToast('Could not load employee', false); return; }
    EM.id = id;
    document.getElementById('emId').value = id;
    document.getElementById('emEditNm').textContent = d.nm || (d.fn + ' ' + d.ln).trim();
    document.getElementById('emFn').value = d.fn; document.getElementById('emLn').value = d.ln;
    document.getElementById('emMobile').value = d.mobile;
    document.getElementById('emLang').value = d.lang;
    document.getElementById('emSms').value = d.sms === '1' ? 'Opt-in' : 'Opt-out';
    document.getElementById('emExp').value = emMdyIso(d.exp);
    document.getElementById('emRole').value = d.role || '4';
    document.getElementById('emStation').value = d.station;
    document.getElementById('emTid').value = d.tid;
    document.getElementById('emPosn').value = d.posn;
    EM.days = (d.avail || '').split(',').map(function(s){ return s.trim(); }).filter(Boolean);
    emDaysRender();
    emOpen('emEditDr');
  });
}
function emSave(){
  var btn = document.getElementById('emSaveBtn');
  btn.disabled = true;
  emAjax('AdminEmployee', {
    requestType:'empSave', employeeID: EM.id,
    fn: document.getElementById('emFn').value.trim(),
    ln: document.getElementById('emLn').value.trim(),
    mobile: document.getElementById('emMobile').value.trim(),
    lang: document.getElementById('emLang').value,
    sms: document.getElementById('emSms').value,
    exp: emIsoMdy(document.getElementById('emExp').value),
    role: document.getElementById('emRole').value,
    station: document.getElementById('emStation').value.trim(),
    avail: EM.days.join(',')
  }, function(resp){
    btn.disabled = false;
    var m = /<mesg>([^<]*)<\/mesg>/.exec(resp);
    if (resp.indexOf('<status>true') >= 0) {
      emClose(); mvpxToast(m && m[1] ? m[1] : 'Saved', true);
      setTimeout(function(){ submitPageDataForm('1','AdminEmployee'); }, 700);
    } else mvpxToast(m && m[1] ? m[1] : 'Save failed', false);
  });
}

function emInc(id, nm){
  EM.id = id; EM.nm = nm;
  document.getElementById('emIncNm').textContent = nm;
  document.getElementById('emIncDate').value = new Date().toISOString().substring(0,10);
  document.getElementById('emIncDesc').value = '';
  emAjax('AdminEmployee', { requestType:'empIncidents', employeeID:id }, function(resp){
    var d; try { d = JSON.parse(resp); } catch(e){ mvpxToast('Could not load incidents', false); return; }
    var ts = '<option value=""></option>';
    (d.types || []).forEach(function(t){ ts += '<option value="' + t.id + '">' + emEsc(t.n) + '</option>'; });
    document.getElementById('emIncType').innerHTML = ts;
    var h = '';
    (d.rows || []).forEach(function(r){
      h += '<div class="em-hx"><div class="hd">' + emEsc(r.d) + ' - ' + emEsc(r.ty)
        + '<span class="pill ' + (r.posted == 1 ? 'green' : 'slate') + '" style="margin-left:auto"><span class="d"></span>' + (r.posted == 1 ? 'POSTED' : 'OPEN') + '</span></div>'
        + (r.m ? '<div class="meta">' + emEsc(r.m) + '</div>' : '') + '</div>';
    });
    document.getElementById('emIncList').innerHTML = h || '<div style="color:#94A3B8;padding:14px;text-align:center">No incidents on record</div>';
    emOpen('emIncDr');
  });
}
function emIncAdd(){
  var btn = document.getElementById('emIncAddBtn');
  if (!document.getElementById('emIncType').value) { mvpxToast('Pick an incident type', false); return; }
  btn.disabled = true;
  emAjax('AdminEmployee', {
    requestType:'empIncidentAdd', employeeID: EM.id,
    typeID: document.getElementById('emIncType').value,
    idate: emIsoMdy(document.getElementById('emIncDate').value),
    descr: document.getElementById('emIncDesc').value.trim()
  }, function(resp){
    btn.disabled = false;
    var m = /<mesg>([^<]*)<\/mesg>/.exec(resp);
    if (resp.indexOf('<status>true') >= 0) { mvpxToast(m && m[1] ? m[1] : 'Saved', true); emInc(EM.id, EM.nm); }
    else mvpxToast(m && m[1] ? m[1] : 'Save failed', false);
  });
}

function emHist(id, nm){
  document.getElementById('emHistNm').textContent = nm;
  emAjax('AdminEmployee', { requestType:'empHistory', employeeID:id }, function(resp){
    var d; try { d = JSON.parse(resp); } catch(e){ mvpxToast('Could not load history', false); return; }
    var h = '';
    if ((d.term || []).length) {
      h += '<div class="em-sec">Termination</div>';
      d.term.forEach(function(x){
        h += '<div class="em-hx" style="border-color:#F3C1C1;background:#FDF7F7"><div class="hd"><span class="pill red"><span class="d"></span>TERMINATED</span> ' + emEsc(x.d) + '</div>'
          + '<div class="meta">Type: ' + emEsc(x.ty) + '\nReason: ' + emEsc(x.rsn) + (x.cm ? '\n' + emEsc(x.cm) : '') + '\nentered by ' + emEsc(x.u) + '</div></div>';
      });
    }
    h += '<div class="em-sec">Schedule</div><div class="em-hx"><div class="hd">Availability: ';
    var av = ((d.sched || {}).avail || '').split(',').filter(Boolean);
    if (av.length) av.forEach(function(x){ h += '<span class="pill green"><span class="d"></span>' + emEsc(x.trim().toUpperCase()) + '</span> '; });
    else h += '<span style="color:#94A3B8;font-weight:400">not set</span>';
    h += '</div><div class="meta">Recent weeks worked: ';
    ((d.sched || {}).weeks || []).forEach(function(x){ h += 'WK' + x.w + ' - ' + x.days + ' days   '; });
    h += ((d.sched || {}).lastCk ? '\nLast check-in: ' + emEsc(d.sched.lastCk) : '') + '</div></div>';
    h += '<div class="em-sec">OSHA Incidents (' + (d.osha || []).length + ')</div>';
    (d.osha || []).forEach(function(x){
      h += '<div class="em-hx"><div class="hd">' + emEsc(x.d) + (x.tm ? ' ' + emEsc(x.tm) : '') + ' - ' + emEsc(x.ty) + '</div>'
        + '<div class="meta">' + (x.rep ? 'Reported: ' + emEsc(x.rep) + '\n' : '') + (x.emt ? 'EMT #: ' + emEsc(x.emt) + '\n' : '')
        + (x.loc ? 'Location: ' + emEsc(x.loc) + '\n' : '') + emEsc(x.m) + '</div></div>';
    });
    if (!(d.osha || []).length) h += '<div style="color:#94A3B8;font-size:12px;padding:4px 0 8px">None on record</div>';
    h += '<div class="em-sec">Record Changes</div>';
    (d.log || []).forEach(function(x){
      h += '<div class="em-hx"><div class="meta"><b>' + emEsc(x.d) + ' - ' + emEsc(x.u) + '</b>  ' + emEsc(x.m) + '</div></div>';
    });
    if (!(d.log || []).length) h += '<div style="color:#94A3B8;font-size:12px;padding:4px 0 8px">None yet</div>';
    h += '<div class="em-sec">Incidents (' + (d.inc || []).length + ')</div>';
    (d.inc || []).forEach(function(x){
      h += '<div class="em-hx"><div class="hd">' + emEsc(x.d) + ' - ' + emEsc(x.ty)
        + '<span class="pill ' + (x.posted == 1 ? 'green' : 'slate') + '" style="margin-left:auto"><span class="d"></span>' + (x.posted == 1 ? 'POSTED' : 'OPEN') + '</span></div>'
        + (x.m ? '<div class="meta">' + emEsc(x.m) + '</div>' : '') + '</div>';
    });
    if (!(d.inc || []).length) h += '<div style="color:#94A3B8;font-size:12px;padding:4px 0 8px">None on record</div>';
    if ((d.writeups || []).length) {
      h += '<div class="em-sec">Write-ups</div><div class="em-hx"><div class="meta">';
      d.writeups.forEach(function(x){ h += emEsc(x.n) + ': ' + x.c + '   '; });
      h += '</div></div>';
    }
    document.getElementById('emHistBody').innerHTML = h;
    emOpen('emHistDr');
  });
}

function emOsha(id, nm){
  EM.id = id;
  document.getElementById('emOshaNm').textContent = nm;
  var now = new Date();
  var iso = now.getFullYear() + '-' + ('0'+(now.getMonth()+1)).slice(-2) + '-' + ('0'+now.getDate()).slice(-2);
  var hm = ('0'+now.getHours()).slice(-2) + ':' + ('0'+now.getMinutes()).slice(-2);
  document.getElementById('emOshaDate').value = iso;
  document.getElementById('emOshaTime').value = '';
  document.getElementById('emOshaRepDate').value = iso;
  document.getElementById('emOshaRepTime').value = hm;
  document.getElementById('emOshaType').value = '';
  document.getElementById('emOshaEmt').value = '';
  document.getElementById('emOshaLoc').value = '';
  document.getElementById('emOshaDesc').value = '';
  emOpen('emOshaDr');
}
function emOshaSave(){
  if (!document.getElementById('emOshaType').value) { mvpxToast('Pick a type', false); return; }
  var btn = document.getElementById('emOshaBtn');
  btn.disabled = true;
  emAjax('AdminEmployee', {
    requestType:'empOshaAdd', employeeID: EM.id,
    idate: emIsoMdy(document.getElementById('emOshaDate').value),
    itime: document.getElementById('emOshaTime').value,
    irepdate: emIsoMdy(document.getElementById('emOshaRepDate').value),
    ireptime: document.getElementById('emOshaRepTime').value,
    itype: document.getElementById('emOshaType').value,
    iemt: document.getElementById('emOshaEmt').value.trim(),
    iloc: document.getElementById('emOshaLoc').value.trim(),
    descr: document.getElementById('emOshaDesc').value.trim()
  }, function(resp){
    btn.disabled = false;
    var m = /<mesg>([^<]*)<\/mesg>/.exec(resp);
    if (resp.indexOf('<status>true') >= 0) { emClose(); mvpxToast(m && m[1] ? m[1] : 'Saved', true); }
    else mvpxToast(m && m[1] ? m[1] : 'Save failed', false);
  });
}

function emTerm(id, nm){
  EM.id = id;
  document.getElementById('emTermNm').textContent = nm;
  document.getElementById('emTermDate').value = new Date().toISOString().substring(0,10);
  document.getElementById('emTermType').value = '';
  document.getElementById('emTermReason').value = '';
  document.getElementById('emTermCm').value = '';
  emOpen('emTermDr');
}
function emTermSave(){
  if (!document.getElementById('emTermType').value || !document.getElementById('emTermReason').value.trim()) {
    mvpxToast('Type and reason are required', false); return;
  }
  var btn = document.getElementById('emTermBtn');
  btn.disabled = true;
  emAjax('AdminEmployee', {
    requestType:'empTerminate', employeeID: EM.id,
    tdate: emIsoMdy(document.getElementById('emTermDate').value),
    ttype: document.getElementById('emTermType').value,
    treason: document.getElementById('emTermReason').value.trim(),
    tcomments: document.getElementById('emTermCm').value.trim()
  }, function(resp){
    btn.disabled = false;
    var m = /<mesg>([^<]*)<\/mesg>/.exec(resp);
    if (resp.indexOf('<status>true') >= 0) {
      emClose(); mvpxToast(m && m[1] ? m[1] : 'Termination recorded', true);
      setTimeout(function(){ submitPageDataForm('1','AdminEmployee'); }, 800);
    } else mvpxToast(m && m[1] ? m[1] : 'Save failed', false);
  });
}

/* scorecard drawer: same data service as Dashboard > DA Scorecard */
function emAwk(dt){
  var y = dt.getFullYear(); var jan1 = new Date(y, 0, 1);
  var start = new Date(y, 0, 1 - jan1.getDay());
  return { y: y, w: Math.floor((dt - start) / 604800000) + 1 };
}
function emScore(id, nm){
  EM.id = id;
  document.getElementById('emScNm').textContent = nm;
  var sel = document.getElementById('emScWk');
  if (!sel.options.length) {
    var now = new Date();
    for (var i = 0; i < 10; i++) {
      var d = new Date(now.getTime() - i * 604800000);
      var aw = emAwk(d);
      var o = document.createElement('option');
      o.value = aw.y + '|' + aw.w; o.textContent = 'WK ' + aw.w + ' ' + aw.y;
      sel.appendChild(o);
    }
    sel.selectedIndex = 1; /* last completed week */
  }
  emOpen('emScoreDr');
  emScoreLoad();
}
function emScoreLoad(){
  var p = document.getElementById('emScWk').value.split('|');
  document.getElementById('emScBody').innerHTML = '<div style="color:#94A3B8;padding:16px">Loading...</div>';
  emAjax('StationDashboard', { requestType:'dash', panel:'scorecard', employeeID: EM.id, y: p[0], w: p[1], mode:'cur' }, function(resp){
    var d; try { d = JSON.parse(resp); } catch(e){ document.getElementById('emScBody').innerHTML = '<div style="color:#94A3B8;padding:16px">No scorecard for this week</div>'; return; }
    var q = d.qual || {}, fx = d.flex || {};
    function rw(l, v){ return '<div class="em-row"><span>' + l + '</span><b>' + (v === '' || v == null ? 'No Data' : v) + '</b></div>'; }
    var h = '<div class="em-sc" style="text-align:center"><div class="big">' + (d.score === '' || d.score == null ? '-' : d.score) + '</div>'
      + '<span class="pill ' + (String(d.tier).toUpperCase().indexOf('PLAT') === 0 || String(d.tier).toUpperCase().indexOf('FANT') === 0 ? 'green' : 'slate') + '"><span class="d"></span>'
      + emEsc(d.tier || 'No standing') + (d.rank !== '' && d.rank != null ? ' - RANK #' + d.rank + ' OF ' + d.rankOf : '') + '</span></div>';
    h += '<div class="em-sc"><div class="em-sec" style="margin-top:0">Delivery Quality</div>'
      + rw('DCR', q.dcr !== '' && q.dcr != null ? q.dcr + '%' : '') + rw('Packages delivered', q.qdel)
      + rw('Returned to station', q.rts) + rw('DSB', q.dsb) + rw('POD', q.pod !== '' && q.pod != null ? q.pod + '%' : '') + '</div>';
    h += '<div class="em-sc"><div class="em-sec" style="margin-top:0">Safety</div>';
    (d.safety || []).forEach(function(s){ h += rw(s.n, (s.v === '' || s.v == null ? '' : s.v) + (s.t ? ' (' + s.t + ')' : '')); });
    h += rw('Safety incidents (dispatch)', d.safInc) + '</div>';
    h += '<div class="em-sc"><div class="em-sec" style="margin-top:0">Customer + Incidents</div>'
      + rw('CDF defects', d.cdf) + rw('CED', d.ced) + '</div>';
    h += '<div class="em-sc"><div class="em-sec" style="margin-top:0">My Week - Flex App</div>'
      + rw('Hours on road', fx.hrs) + rw('Routes', fx.routes) + rw('Average pace', fx.pace !== '' && fx.pace != null ? fx.pace + '/hr' : '')
      + rw('Breaks', fx.brk !== '' && fx.brk != null && +fx.brk > 0 ? fx.brk + 'm' : (fx.hrs !== '' && fx.hrs != null ? '0m' : ''))
      + rw('Stops completed', fx.cs !== '' && fx.cs != null ? fx.cs + ' / ' + fx.st : '') + '</div>';
    h += '<div style="text-align:center;margin-top:4px"><a href="javascript:void(0)" style="font-size:12px" onclick="submitPageDataForm(\'1\',\'StationDashboard\')">Open in Dashboard &#8599;</a></div>';
    document.getElementById('emScBody').innerHTML = h;
  });
}
</script>

<script>
mvpxListInit({
  ctrl: '<%=_searchBean.getController()%>',
  from: '<%=_searchBean.getSrhFromDate()%>',
  to:   '<%=_searchBean.getSrhToDate()%>',
  summaries: [
    { key:'role',  label:'By role',         filterId:'filterRole',  into:'roleSum'  },
    { key:'avail', label:'By availability', filterId:'filterAvail', into:'availSum' }
  ],
  filters: [
    { id:'filterName',   key:'emp',   label:'Name',        mode:'includes' },
    { id:'filterMobile', key:'mob',   label:'Mobile',      mode:'includes' },
    { id:'filterRole',   key:'role',  label:'Role',        mode:'exact' },
    { id:'filterAvail',  key:'avail', label:'Availability', mode:'exact' },
    { id:'filterStatus', key:'st',    label:'Status',      mode:'exact' },
    { id:'filterSms',    key:'sms',   label:'SMS',         mode:'exact' }
  ]
});
</script>

<%
/* ═══════════════ RECORD FORM VIEWS (unchanged legacy) ═══════════════ */
} else {
%>

<script>
function validatePageData(submitType, isValid) {

	if(submitType == <%=SubmitType.CREATE_CONFIRM%> || submitType == <%=SubmitType.UPDATE_CONFIRM%>) {
		if(isValid) {
			var availability = getCheckboxValue(document.formmain["availabilityChk"], ",");
			document.formmain["availability"].value = availability;

			var mandatoryFieldsArray = new Array();
			mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["fullName"], "Employee Name");
			mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["transporterID"], "Transporter ID");
			mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["idExpiryDate"], "ID Expiry");
			mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["availability"], "Availability");
			mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["mobile"], "Mobile");
			mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["reviewStatus"], "Status");
			isValid = validateMandatoryFieldsInForm(mandatoryFieldsArray, isValid);
		}

	} else if(submitType == <%=SubmitType.DELETE%>) {
		isValid = deleteRecord();
	}

	return isValid;
}
</script>

<%@ include file="includeHeader.jsp"%>
<div class='row my-2'>
	<div class='col-12 mb-2'>
		<div class='card'>
			<div class='card-header table-title-header m-0 py-2'>
				<div class="row">
					<div class="col-2"></div>
					<div class="col-8"><%=_recordBean.getDisplayName()%></div>
					<div class="col-2 text-right my-auto"><%if(submitType == SubmitType.BROWSE) {%><button class="btn btn-primary btn-sm" onClick="Javascript:submitPageDataForm('<%=SubmitType.CREATE%>','<%=_recordBean.getController()%>');" title="Create New">New</button><%}%></div>
				</div>
			</div>

			<%if(_errorBean != null && _errorBean.getType().length() > 0) {%>
				<div class="row text-center"><section class='alert_section'><div class='alert-box <%=_errorBean.getType()%>Color'><%=_errorBean.getMesg()%></div></section></div>
			<%}%>

			<div class='card-body m-1 p-1'>
			<input type="hidden" id="adminEmployeeID" name="adminEmployeeID" value="<%=_recordBean.getAdminEmployeeID()%>">
			<input type="hidden" id="addressID" name="addressID" value="<%=_recordBean.getAddressID()%>">
			<input type="hidden" id="contactID" name="contactID" value="<%=_recordBean.getContactID()%>">
			<input type="hidden" id="availability" name="availability" value="">
			<%if(submitType == SubmitType.CREATE || submitType == SubmitType.UPDATE) {%>
				<div class="row">
					<div class="col-5">
						<div class="row form-row form-group form-group-sm">
							<label class="col-3 col-form-label required text-left">Employee Name</label>
							<div class="col-9 text-left"><input type="text" id="fullName" name="fullName" class="form-control form-control-sm" value="<%=_recordBean.getFullName()%>"></div>
						</div>
						<div class="row form-row form-group form-group-sm">
							<label class="col-3 col-form-label text-left"></label>
							<div class="col-4 text-left"><input type="text" id="firstName" name="firstName" class="form-control form-control-sm" value="<%=_recordBean.getFirstName()%>" placeholder="First Name"></div>
							<div class="col-1 text-left"></div>
							<div class="col-4 text-left"><input type="text" id="lastName" name="lastName" class="form-control form-control-sm" value="<%=_recordBean.getLastName()%>" placeholder="Last Name"></div>
						</div>
						<div class="row form-row form-group form-group-sm">
							<label class="col-3 col-form-label required text-left">Transporter ID</label>
							<div class="col-9 text-left"><input type="text" id="transporterID" name="transporterID" class="form-control form-control-sm" value="<%=_recordBean.getTransporterID()%>"></div>
						</div>
						<div class="row form-row form-group form-group-sm">
							<label class="col-3 col-form-label required text-left">ID Expiry</label>
							<div class="col-9 text-left"><input type="text" id="idExpiryDate" name="idExpiryDate" class="form-control form-control-sm datepicker" value="<%=_recordBean.getIdExpiryDate()%>"></div>
						</div>
						<div class="row form-row form-group form-group-sm">
							<label class="col-3 col-form-label text-left">Position</label>
							<div class="col-9 text-left"><input type="text" id="position" name="position" class="form-control form-control-sm" value="<%=_recordBean.getPosition()%>"></div>
						</div>
						<div class="row form-row form-group form-group-sm">
							<label class="col-3 col-form-label text-left">Qualifications</label>
							<div class="col-9 text-left"><input type="text" id="qualification" name="qualification" class="form-control form-control-sm" value="<%=_recordBean.getQualification()%>"></div>
						</div>
						<div class="row form-row form-group form-group-sm">
							<label class="col-3 col-form-label required text-left">Availability</label>
							<div class="col-9 text-left input-group">
							<%String availabilityArray[]= "Mon,Tue,Wed,Thu,Fri,Sat,Sun".split(",");
							for(int i=0; i<availabilityArray.length; i++) {%>
								<div class="form-check-inline">
									<label class="form-check-label"><input type="checkbox" class="form-check-input" id="availabilityChk" name="availabilityChk" value="<%=availabilityArray[i]%>"><%=availabilityArray[i]%></label>
								</div>
							<%}%>
							</div>
						</div>
					</div>

					<div class="col-2"></div>

					<div class="col-5">
						<div class="row form-row form-group form-group-sm">
							<label class="col-3 col-form-label required text-left">Role</label>
							<div class="col-9 text-left"><select id="employeeRole" name="employeeRole" class="form-control form-control-sm">
								<option value="1">Dispatcher</option>
								<option value="2">Manager</option>
								<option value="3">Management</option>
								<option value="4" selected>DA Associate</option>
							</select></div>
						</div>
						<div class="row form-row form-group form-group-sm">
							<label class="col-3 col-form-label text-left">SMS</label>
							<div class="col-9 text-left">
								<div class="form-check-inline">
									<label class="form-check-label"><input type="radio" class="form-check-input" name="smsPref" value="1" checked>Opt-in</label>
								</div>
								<div class="form-check-inline">
									<label class="form-check-label"><input type="radio" class="form-check-input" name="smsPref" value="0">Opt-out</label>
								</div>
							</div>
						</div>
						<div class="row form-row form-group form-group-sm">
							<label class="col-3 col-form-label required text-left">Preferred Language</label>
							<div class="col-9 text-left"><select id="preferredLanguage" name="preferredLanguage" class="form-control form-control-sm">
								<%String preferredLanguageOptions = _recordBean.getPreferredLanguageOptions();
								if(preferredLanguageOptions.length() == 0)
									preferredLanguageOptions = "English";
								String _array1[] = preferredLanguageOptions.split("#");
								for(int k=0; k<_array1.length; k++) {%><option value="<%=_array1[k]%>"><%=_array1[k]%></option><%}%>
							</select></div>
						</div>
						<div class="row form-row form-group form-group-sm">
							<label class="col-3 col-form-label required text-left">Mobile</label>
							<div class="col-9 text-left"><input type="text" id="mobile" name="mobile" class="form-control form-control-sm" onBlur="validateNumericValues(this);" value="<%=_recordBean.getContactBean().getMobile()%>"></div>
						</div>
						<div class="row form-row form-group form-group-sm">
							<label class="col-3 col-form-label text-left">Work Phone</label>
							<div class="col-9 text-left"><input type="text" id="workPhone" name="workPhone" class="form-control form-control-sm" onBlur="validateNumericValues(this);" value="<%=_recordBean.getContactBean().getWorkPhone()%>"></div>
						</div>
						<div class="row form-row form-group form-group-sm">
							<label class="col-3 col-form-label text-left">Email</label>
							<div class="col-9 text-left"><input type="text" id="email" name="email" class="form-control form-control-sm" onBlur="validateEmailAdd(this);" value="<%=_recordBean.getContactBean().getEmail()%>"></div>
						</div>
						<div class="row form-row form-group form-group-sm">
							<label class="col-3 col-form-label required text-left">Status</label>
							<div class="col-9 text-left"><select id="reviewStatus" name="reviewStatus" class="form-control form-control-sm"><option value=""></option><option value="0">Active</option><option value="4">Inactive</option><option value="8">Terminated</option><option value="9">Quit</option></select></div>
						</div>
					</div>
				</div>
				<script>
					setSelectBoxValue(document.formmain["reviewStatus"], "<%=_recordBean.getReviewStatus()%>");
					setCheckboxValue(document.formmain["availabilityChk"], "<%=_recordBean.getAvailability()%>", ",");
					setRadioButtonValue(document.formmain["smsPref"], "<%=_recordBean.getSmsPref()%>");
					setSelectBoxValue(document.formmain["employeeRole"], "<%=_recordBean.getEmployeeRole()%>");
					setSelectBoxValue(document.formmain["preferredLanguage"], "<%=_recordBean.getPreferredLanguage()%>");
				</script>

			<%} else if(submitType == SubmitType.BROWSE) {%>
				<div class="row">
					<div class="col-5">
						<div class="row">
							<label class="col-3 col-form-label text-left">Employee Name</label>
							<div class="col-9 form-control-plaintext text-left"><%=_recordBean.getFullName()%></div>
						</div>
						<%if(_recordBean.getFirstName().length() > 0) {%>
							<div class="row">
								<label class="col-3 col-form-label text-left">First Name</label>
								<div class="col-9 form-control-plaintext text-left"><%=_recordBean.getFirstName()%></div>
							</div>
						<%} if(_recordBean.getLastName().length() > 0) {%>
							<div class="row">
								<label class="col-3 col-form-label text-left">Last Name</label>
								<div class="col-9 form-control-plaintext text-left"><%=_recordBean.getLastName()%></div>
							</div>
						<%}%>
						<div class="row">
							<label class="col-3 col-form-label text-left">Transporter ID</label>
							<div class="col-9 form-control-plaintext text-left"><%=_recordBean.getTransporterID()%></div>
						</div>
						<div class="row">
							<label class="col-3 col-form-label text-left">ID Expiry</label>
							<div class="col-9 form-control-plaintext text-left"><%=_recordBean.getIdExpiryDate()%></div>
						</div>
						<div class="row">
							<label class="col-3 col-form-label text-left">Position</label>
							<div class="col-9 form-control-plaintext text-left"><%=_recordBean.getPosition()%></div>
						</div>
						<div class="row">
							<label class="col-3 col-form-label text-left">Qualifications</label>
							<div class="col-9 form-control-plaintext text-left"><%=_recordBean.getQualification()%></div>
						</div>
						<div class="row">
							<label class="col-3 col-form-label text-left">Availability</label>
							<div class="col-9 form-control-plaintext text-left"><%=_recordBean.getAvailability()%></div>
						</div>
					</div>

					<div class="col-2"></div>

					<div class="col-5">
						<div class="row">
							<label class="col-3 col-form-label text-left">Role</label>
							<div class="col-9 form-control-plaintext text-left"><%=_recordBean.getEmployeeRoleName()%></div>
						</div>
						<div class="row">
							<label class="col-3 col-form-label text-left">SMS</label>
							<div class="col-9 form-control-plaintext text-left"><%="1".equalsIgnoreCase(_recordBean.getSmsPref()) ? "Opt-in" : "Opt-out"%></div>
						</div>
						<div class="row">
							<label class="col-3 col-form-label text-left">Preferred Language</label>
							<div class="col-9 form-control-plaintext text-left"><%=_recordBean.getPreferredLanguage()%></div>
						</div>
						<div class="row">
							<label class="col-3 col-form-label text-left">Mobile</label>
							<div class="col-9 form-control-plaintext text-left"><%=_recordBean.getContactBean().getMobile()%></div>
						</div>
						<div class="row">
							<label class="col-3 col-form-label text-left">Work Phone</label>
							<div class="col-9 form-control-plaintext text-left"><%=_recordBean.getContactBean().getWorkPhone()%></div>
						</div>
						<div class="row">
							<label class="col-3 col-form-label text-left">Email</label>
							<div class="col-9 form-control-plaintext text-left"><%=_recordBean.getContactBean().getEmail()%></div>
						</div>
						<div class="row">
							<label class="col-3 col-form-label text-left">Review Status</label>
							<div class="col-9 form-control-plaintext text-left"><%=RecordStatus.RecordStatus[Integer.parseInt(_recordBean.getReviewStatus())]%></div>
						</div>
					</div>
				</div>
			<%}%>
			</div>
		</div>

		<%if(submitType == SubmitType.CREATE || submitType == SubmitType.UPDATE) {%>
			<div class="row mt-4">
				<div class="col-4 text-left">
					<button class="btn btn-secondary text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.SEARCH%>','<%=_recordBean.getController()%>','');">Back to search</button>
				</div>
				<div class="col-4 text-center">
					<%if(submitType == SubmitType.CREATE) {%>
						<button class="btn btn-success text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.CREATE_CONFIRM%>','<%=_recordBean.getController()%>','<%=_recordBean.getAdminEmployeeID()%>');">Save</button>
						<!--button class="btn btn-success text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.CREATE_CONFIRM%>','<%=_recordBean.getController()%>','<%=_recordBean.getAdminEmployeeID()%>','2');">Save & Post</button --></div>
					<%} else {%>
						<button class="btn btn-success text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.UPDATE_CONFIRM%>','<%=_recordBean.getController()%>','<%=_recordBean.getAdminEmployeeID()%>');">Save</button>
						<!--button class="btn btn-success text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.UPDATE_CONFIRM%>','<%=_recordBean.getController()%>','<%=_recordBean.getAdminEmployeeID()%>','2');">Save & Post</button --></div>
					<%}%>
				<div class="col-4 text-right"></div>
			</div>

		<%} else if(submitType == SubmitType.BROWSE) {%>
			<div class="row mt-4">
				<div class="col-4 text-left">
					<button class="btn btn-secondary text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.SEARCH%>','<%=_recordBean.getController()%>','');">Back to search</button>
				</div>
				<div class="col-4 text-center">
				<%if("0".equalsIgnoreCase(_recordBean.getStatus())) {%>
					<button class="btn btn-primary text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.UPDATE%>','<%=_recordBean.getController()%>','<%=_recordBean.getAdminEmployeeID()%>');">Edit</button>
				<%}%>
				</div>
				<div class="col-4 text-right">
				<%if("0".equalsIgnoreCase(_recordBean.getStatus())) {%>
					<button class="btn btn-danger text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.DELETE%>','<%=_recordBean.getController()%>','<%=_recordBean.getAdminEmployeeID()%>');">Delete</button>
				<%}%>
				</div>
			</div>
		<%}%>
	</div>
</div>
<%@ include file="includeFooter.jsp"%>
<%}%>