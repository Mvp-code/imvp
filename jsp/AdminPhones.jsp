<!DOCTYPE html>
<%@ page import="java.util.*, com.util.*, com.beans.*"%>
<jsp:useBean id="_errorBean" class="com.beans.ErrorBean" scope="request" />
<%
int submitType = request.getAttribute("submitType") == null ? SubmitType.CREATE : Integer.parseInt(request.getAttribute("submitType").toString().trim());

SearchBean _searchBean = new SearchBean();
Object _rawBeanObj = request.getAttribute("_recordBean");
if (_rawBeanObj instanceof SearchBean) {
    _searchBean = (SearchBean) _rawBeanObj;
    request.removeAttribute("_recordBean");
}
%>
<jsp:useBean id="_recordBean" class="com.beans.AdminPhones" scope="request" />
<%
String _cs = _recordBean.getCurrentStatus() == null || _recordBean.getCurrentStatus().trim().length() == 0 ? "0" : _recordBean.getCurrentStatus().trim();
String _ps = _recordBean.getPhoneStatus() == null || _recordBean.getPhoneStatus().trim().length() == 0 ? "0" : _recordBean.getPhoneStatus().trim();

/* ═══════════════ LIST VIEW (Vehicle desk pattern — Vehicles page untouched) ═══════════════ */
if (submitType == SubmitType.SEARCH) {
    List dataList = _searchBean.getDataList() == null ? new ArrayList() : _searchBean.getDataList();
    int cntTotal = dataList.size(), cntActive = 0, cntInactive = 0;
    int cntInUse = 0, cntNotUsed = 0, cntDamaged = 0, cntLost = 0;
    Map<String, Integer> curAct = new LinkedHashMap<String, Integer>();
    Map<String, Integer> curInact = new LinkedHashMap<String, Integer>();
    /* [0]=id [1]=number [2]=phone status [3]=current status [4]=in-use date [5]=audit date [6]=notes */
    List<String[]> rows = new ArrayList<String[]>();
    for (int i = 0; i < dataList.size(); i++) {
        List r = (List) dataList.get(i);
        String[] c = new String[7];
        for (int j = 0; j < 7 && j < r.size(); j++)
            c[j] = r.get(j) == null ? "" : r.get(j).toString().trim();
        for (int j = 0; j < 7; j++) if (c[j] == null) c[j] = "";
        boolean isActive = "Active".equalsIgnoreCase(c[2]);
        if (isActive) cntActive++; else cntInactive++;
        String cur = c[3].length() > 0 ? c[3] : "In Use";
        c[3] = cur;
        String curLc = cur.toLowerCase();
        if (curLc.equals("in use")) cntInUse++;
        else if (curLc.equals("not used")) cntNotUsed++;
        else if (curLc.equals("damaged")) cntDamaged++;
        else if (curLc.equals("lost")) cntLost++;
        Map<String, Integer> bucket = isActive ? curAct : curInact;
        bucket.put(cur, bucket.get(cur) == null ? 1 : bucket.get(cur) + 1);
        rows.add(c);
    }
    int cntIssues = cntDamaged + cntLost;
%>
<%@ include file="includeHeader.jsp"%>
<link rel="stylesheet" href="../jsp/assets/css/mvpx-list.css?v=20260916e">
<script src="../jsp/assets/js/mvpx-list.js?v=20260916a"></script>
<style>
.da-wrap{padding:2px 0 48px}
.da-wrap .da-headrow{margin-bottom:10px;align-items:center}
.da-wrap .da-headrow h2{
  margin:0;font-size:22px;font-weight:800;letter-spacing:-.02em;
  color:var(--text,#16202e);font-family:var(--font-disp,'Inter','DM Sans','Open Sans','Work Sans','Segoe UI',sans-serif);
}
.da-wrap .statchip{
  border-radius:6px;font-size:12px;padding:4px 10px;
  background:var(--status-action-bg);border-color:var(--status-action-border);
  color:var(--status-action-fg);
}
.da-wrap .statchip .dot{background:var(--status-action-fg)!important}
.da-wrap .statchip b{color:var(--status-action-fg)}
.ph-chip{cursor:pointer;user-select:none}
.ph-chip:hover{border-color:var(--text,#16202e)}
.vh-cards{display:grid;grid-template-columns:1fr 1fr 1fr;gap:10px;margin:0 0 12px}
.vh-card{
  background:var(--surface,#fff);border:1px solid var(--border,#e2e8f0);
  border-radius:8px;padding:12px 14px 10px;min-width:0;
  border-left:3px solid var(--border-strong,#cbd5e1);
  box-shadow:none;
}
.vh-cards .vh-card:nth-child(1){border-left-color:var(--status-ok-fg)}
.vh-cards .vh-card:nth-child(2){border-left-color:var(--status-neutral-fg,#475569)}
.vh-cards .vh-card:nth-child(3){border-left-color:var(--status-warn-fg)}
.vh-cards .vh-card:nth-child(1) h4 .dot{background:var(--status-ok-fg)!important}
.vh-cards .vh-card:nth-child(2) h4 .dot{background:var(--status-neutral-fg,#475569)!important}
.vh-cards .vh-card:nth-child(3) h4 .dot{background:var(--status-warn-fg)!important}
.vh-card h4{
  margin:0 0 8px;font-size:12px;font-weight:800;letter-spacing:.04em;
  text-transform:uppercase;color:var(--text-muted,#475569);
  display:flex;align-items:center;gap:6px;
  font-family:var(--font,'Inter','DM Sans','Open Sans','Work Sans','Segoe UI',sans-serif);
}
.vh-card h4 .n{
  margin-left:auto;font-family:var(--font-mono,ui-monospace,monospace);
  font-size:20px;font-weight:800;color:var(--text,#16202e);letter-spacing:-.02em;
}
.vh-card .dot{width:8px;height:8px;border-radius:50%;display:inline-block;margin-right:2px;vertical-align:baseline}
.vh-sub{
  font-size:10px;font-weight:700;letter-spacing:.08em;text-transform:uppercase;
  color:var(--text-light,#64748b);margin:0 0 4px;
}
.vh-line{
  display:inline-flex;align-items:center;gap:4px;font-size:12.5px;line-height:1.5;
  cursor:pointer;border-radius:4px;padding:2px 5px;margin:0 0 1px;max-width:100%;
  color:var(--text,#16202e);
}
.vh-line:hover{background:var(--bg,#f1f5f9)}
.vh-line b{font-family:var(--font-mono,ui-monospace,monospace);font-weight:700;white-space:nowrap;color:var(--text-muted,#475569)}
@media (max-width:900px){.vh-cards{grid-template-columns:1fr}}
.da-wrap .da-toolbar{
  border-radius:8px;padding:8px 10px;margin-bottom:8px;
  border-color:var(--border,#e2e8f0);box-shadow:none;
  background:var(--surface,#fff);
}
.da-wrap .da-flt{
  font-size:13px;padding:7px 10px;border-radius:6px;
  border-color:var(--border-strong,#cbd5e1);max-width:200px;
}
.da-wrap .btn2{border-radius:6px}
.da-wrap .btn2.primary{
  background:var(--theme-accent,#2563eb);border-color:var(--theme-accent,#2563eb);
}
.da-wrap .da-chips{margin-top:6px}
.da-wrap .tablewrap{
  overflow:hidden !important;border-radius:8px;margin-top:8px;
  border-color:var(--border,#e2e8f0);box-shadow:none;
}
.da-wrap .vh-tbl-x{
  overflow-x:auto !important;overflow-y:visible !important;
  scrollbar-width:thin !important;scrollbar-color:var(--border-strong,#cbd5e1) var(--bg,#f1f5f9);
}
.da-wrap .vh-tbl-x::-webkit-scrollbar{display:block !important;width:10px;height:10px}
.da-wrap .vh-tbl-x::-webkit-scrollbar-track{background:var(--bg,#f1f5f9)}
.da-wrap .vh-tbl-x::-webkit-scrollbar-thumb{background:var(--border-strong,#cbd5e1);border-radius:5px}
.da-wrap .vh-tbl-x > table{width:max-content;min-width:100%;border-collapse:collapse}
.da-wrap .tablewrap thead th{
  font-size:11px !important;font-weight:700;letter-spacing:.03em;text-transform:uppercase;
  padding:8px 10px !important;white-space:normal !important;line-height:1.25;
  max-width:7.5em;vertical-align:bottom;
  color:var(--text-muted,#475569)!important;background:var(--bg,#f1f5f9)!important;
  border-bottom:1px solid var(--border,#e2e8f0)!important;
  font-family:var(--font,'Inter','DM Sans','Open Sans','Work Sans','Segoe UI',sans-serif);
}
.da-wrap .tablewrap thead th.srt{cursor:pointer;user-select:none}
.da-wrap .tablewrap thead th.srt:hover{background:#EEF3FB!important;color:var(--theme-accent-dark,#1d4ed8)!important}
.da-wrap .tablewrap thead th .ar{color:var(--theme-accent,#2563eb);font-size:10px;margin-left:2px}
.da-wrap .tablewrap tbody td{
  font-size:13.5px !important;padding:9px 12px !important;white-space:nowrap;
  color:var(--text,#16202e);border-bottom-color:var(--da-line-soft,#EEF1F6);
  font-family:var(--font,'Inter','DM Sans','Open Sans','Work Sans','Segoe UI',sans-serif);
}
.da-wrap .tablewrap tbody tr:hover{filter:brightness(.98);cursor:pointer}
.da-wrap .tablewrap .meta{font-size:12.5px !important;color:var(--text-muted,#475569)!important}
.da-wrap .tablewrap .nm{font-size:13.5px !important;font-weight:700}
.da-wrap .tablewrap .ph-notes{white-space:normal !important;max-width:28em;line-height:1.35;color:var(--text-muted,#475569)}
.da-empty{text-align:center;color:var(--text-light,#64748b);padding:28px 12px !important}
.ph-scrim{display:none;position:fixed;inset:0;background:rgba(15,23,42,.4);z-index:390}
.ph-scrim.on{display:block}
.ph-drawer{
  position:fixed;top:0;right:0;width:min(720px,100vw);height:100vh;box-sizing:border-box;
  background:var(--surface,#fff);border-left:1px solid var(--border,#e2e8f0);
  box-shadow:-8px 0 28px rgba(15,23,42,.12);z-index:400;padding:16px 18px;overflow:hidden;
  transform:translateX(calc(100% + 40px));visibility:hidden;
  transition:transform .22s ease,visibility .22s;display:flex;flex-direction:column;
}
.ph-drawer.on{transform:translateX(0);visibility:visible}
.ph-drawer .ph-scrollarea{flex:1;min-height:0;overflow-y:auto;scrollbar-width:thin}
.ph-drawer h3{margin:0 0 14px;font-size:16px;font-weight:800;display:flex;align-items:center;gap:8px;color:var(--text,#16202e);font-family:var(--font,'Inter','DM Sans','Open Sans','Work Sans','Segoe UI',sans-serif)}
.ph-drawer h3 span{color:var(--text-light,#64748b);font-weight:500;font-size:13px}
.ph-x{margin-left:auto;border:0;background:transparent;font-size:15px;cursor:pointer;color:var(--text-light,#64748b)}
.ph-fgrid{display:grid;grid-template-columns:1fr 1fr;gap:9px 12px}
.ph-drawer label{
  display:flex;flex-direction:column;gap:3px;font-size:10.5px;letter-spacing:.06em;
  text-transform:uppercase;color:var(--text-light,#64748b);margin-top:4px;
  font-family:var(--font,'Inter','DM Sans','Open Sans','Work Sans','Segoe UI',sans-serif);
}
.ph-step{
  font-size:10.5px;letter-spacing:.09em;text-transform:uppercase;font-weight:700;
  color:var(--text-light,#64748b);margin:10px 0 6px;
  border-bottom:1px solid var(--border,#e2e8f0);padding-bottom:4px;
}
.ph-drawer input,.ph-drawer select,.ph-drawer textarea{
  border:1px solid var(--border-strong,#cbd5e1);border-radius:6px;padding:7px 9px;
  font-size:13.5px;font-family:inherit;background:#fff;color:inherit;width:100%;min-width:0;box-sizing:border-box;
  text-transform:none;letter-spacing:0;
}
.ph-fgrid label{min-width:0}
.ph-req{display:inline;margin-left:1px;color:var(--status-action-fg)}
.ph-drawer label:has(.ph-req){color:var(--status-action-fg);font-weight:700}
.ph-drawer input:focus,.ph-drawer select:focus,.ph-drawer textarea:focus{
  outline:2px solid var(--theme-accent,#2563eb);outline-offset:-1px;
}
.ph-drbtns{display:flex;gap:8px;align-items:center;margin-top:16px}
.ph-notes-full{grid-column:1 / -1}
</style>

<div class="da-wrap">

  <div class="da-headrow">
    <div>
      <h2>Phones</h2>
    </div>
    <div style="display:flex;gap:7px;align-items:center;flex-wrap:wrap">
      <span class="statchip ph-chip" onclick="phChip('filterCur','damaged')"><span class="dot"></span><b><%=cntIssues%></b> damaged / lost</span>
      <button type="button" class="btn2 sm" id="vhSumBtn" onclick="phSummary()">Hide summary</button>
      <button type="button" class="btn2" onclick="mvpxPrint('xls')" title="Download filtered phones to Excel"><i class="fas fa-file-excel"></i> Excel</button>
      <button type="button" class="btn2" onclick="mvpxPrint('')" title="Download PDF"><i class="fas fa-file-pdf"></i> PDF</button>
      <button type="button" class="btn2 primary" onclick="submitPageDataForm('<%=SubmitType.CREATE%>','<%=_searchBean.getController()%>');">&#xFF0B; New</button>
    </div>
  </div>

  <div class="vh-cards">
    <div class="vh-card">
      <h4 onclick="phChip('filterSt','active')" style="cursor:pointer"><span class="dot"></span> Active <span class="n"><%=cntActive%></span></h4>
      <div class="vh-sub">By current status</div>
      <%for(Map.Entry<String,Integer> e : curAct.entrySet()){%>
      <div class="vh-line" onclick="phChip2('active','filterCur','<%=e.getKey().toLowerCase()%>')"><span><%=e.getKey()%></span><b>(<%=e.getValue()%>)</b></div>
      <%}%>
      <%if(curAct.isEmpty()){%><div class="vh-sub">No active lines</div><%}%>
    </div>
    <div class="vh-card">
      <h4 onclick="phChip('filterSt','inactive')" style="cursor:pointer"><span class="dot"></span> Inactive <span class="n"><%=cntInactive%></span></h4>
      <div class="vh-sub">By current status</div>
      <%for(Map.Entry<String,Integer> e : curInact.entrySet()){%>
      <div class="vh-line" onclick="phChip2('inactive','filterCur','<%=e.getKey().toLowerCase()%>')"><span><%=e.getKey()%></span><b>(<%=e.getValue()%>)</b></div>
      <%}%>
      <%if(curInact.isEmpty()){%><div class="vh-sub">No inactive lines</div><%}%>
    </div>
    <div class="vh-card">
      <h4 onclick="phChip('filterCur','damaged')" style="cursor:pointer"><span class="dot"></span> Damaged / Lost <span class="n"><%=cntIssues%></span></h4>
      <div class="vh-line" onclick="phChip('filterCur','damaged')"><span>Damaged</span><b>(<%=cntDamaged%>)</b></div>
      <div class="vh-line" onclick="phChip('filterCur','lost')"><span>Lost</span><b>(<%=cntLost%>)</b></div>
      <div class="vh-line" onclick="phChip('filterCur','in use')"><span>In Use</span><b>(<%=cntInUse%>)</b></div>
      <div class="vh-line" onclick="phChip('filterCur','not used')"><span>Not Used</span><b>(<%=cntNotUsed%>)</b></div>
    </div>
  </div>

  <div class="da-toolbar">
    <select class="da-flt" id="filterNum" onchange="mvpxApplyFilters()" style="max-width:180px">
      <option value="">All phone numbers</option>
      <%
        List<String> phNums = new ArrayList<String>();
        for (String[] pr : rows) {
          if (pr[1] != null && pr[1].length() > 0 && !phNums.contains(pr[1])) phNums.add(pr[1]);
        }
        Collections.sort(phNums);
        for (String pn : phNums) {
      %>
      <option value="<%=pn.toLowerCase().replace("&","&amp;").replace("\"","&quot;")%>"><%=pn.replace("&","&amp;").replace("<","&lt;")%></option>
      <%}%>
    </select>
    <select class="da-flt" id="filterSt" onchange="mvpxApplyFilters()">
      <option value="">All phone status</option>
      <option value="active">Active</option>
      <option value="inactive">Inactive</option>
    </select>
    <select class="da-flt" id="filterCur" onchange="mvpxApplyFilters()">
      <option value="">All current status</option>
      <option value="in use">In Use</option>
      <option value="not used">Not Used</option>
      <option value="damaged">Damaged</option>
      <option value="lost">Lost</option>
    </select>
  </div>

  <div class="da-chips" id="activeChips"></div>

  <%if(_errorBean != null && _errorBean.getType().length() > 0){%>
  <div class="row text-center mt-2">
    <section class="alert_section">
      <div class="alert-box <%=_errorBean.getType()%>Color"><%=_errorBean.getMesg()%></div>
    </section>
  </div>
  <%}%>

  <div class="tablewrap">
    <div class="vh-tbl-x">
    <table>
      <thead>
        <tr>
          <th class="srt" onclick="mvpxSort(this)">Phone Number<span class="ar"></span></th>
          <th class="srt" onclick="mvpxSort(this)">Phone Status<span class="ar"></span></th>
          <th class="srt" onclick="mvpxSort(this)">Current status<span class="ar"></span></th>
          <th class="srt" onclick="mvpxSort(this)">Device In Use Date<span class="ar"></span></th>
          <th class="srt" onclick="mvpxSort(this)">Last Audit Date<span class="ar"></span></th>
          <th class="srt" onclick="mvpxSort(this)">Notes<span class="ar"></span></th>
        </tr>
      </thead>
      <tbody id="ciRows">
        <%if(rows.isEmpty()){%>
        <tr><td colspan="6" class="da-empty">No phones found.</td></tr>
        <%}%>
        <%for(String[] r : rows){
            String stLc = r[2].toLowerCase();
            String curLc = r[3].toLowerCase();
            String stPill = "slate";
            if (stLc.startsWith("active")) stPill = "green";
            else if (stLc.contains("inactive")) stPill = "slate";
            String curPill = "slate";
            if (curLc.equals("in use")) curPill = "green";
            else if (curLc.equals("not used")) curPill = "slate";
            else if (curLc.equals("damaged")) curPill = "amber";
            else if (curLc.equals("lost")) curPill = "red";
            String numAttr = r[1].replace("&","&amp;").replace("\"","&quot;").replace("<","&lt;");
            String notesHtml = r[6].replace("&","&amp;").replace("<","&lt;");
        %>
        <tr data-id="<%=r[0]%>"
            data-num="<%=r[1].toLowerCase().replace("&","&amp;").replace("\"","&quot;")%>"
            data-st="<%=stLc.startsWith("active") ? "active" : "inactive"%>"
            data-cur="<%=curLc.replace("&","&amp;").replace("\"","&quot;")%>"
            onclick="if(event.target.closest('a,button,select,input'))return;phEdit('<%=r[0]%>')">
          <td class="nm"><a href="javascript:void(0)" style="color:inherit" onclick="phEdit('<%=r[0]%>');return false;"><%=numAttr%></a></td>
          <td><span class="pill <%=stPill%>"><span class="d"></span><%=r[2].length()>0?r[2]:"&mdash;"%></span></td>
          <td><span class="pill <%=curPill%>"><span class="d"></span><%=r[3].length()>0?r[3]:"&mdash;"%></span></td>
          <td class="meta"><%=r[4].length()>0?r[4]:"&mdash;"%></td>
          <td class="meta"><%=r[5].length()>0?r[5]:"&mdash;"%></td>
          <td class="ph-notes"><%=notesHtml.length()>0?notesHtml:"&mdash;"%></td>
        </tr>
        <%}%>
      </tbody>
    </table>
    </div>
    <div class="tablefoot">
      <span id="showCount">Showing <%=rows.size()%> of <%=cntTotal%></span>
      <button type="button" class="btn2 sm" onclick="submitPageDataForm('<%=SubmitType.SEARCH%>','<%=_searchBean.getController()%>')">&#8635; Refresh</button>
    </div>
  </div>
</div>

<div class="da-toast" id="daToast"></div>
<div class="ph-scrim" id="phScrim" onclick="phClose()"></div>
<div class="ph-drawer" id="phDrawer">
  <h3>Edit Phone <span id="phDrName"></span><button type="button" class="ph-x" onclick="phClose()">&#10005;</button></h3>
  <input type="hidden" id="phId">
  <div class="ph-scrollarea">
    <div class="ph-step">Line details</div>
    <div class="ph-fgrid">
      <label>Phone Number<span class="ph-req">*</span><input id="phNum"></label>
      <label>Phone Status
        <select id="phPs">
          <option value="0">Active</option>
          <option value="4">Inactive</option>
        </select>
      </label>
      <label>Current status
        <select id="phCs">
          <option value="0">In Use</option>
          <option value="1">Not Used</option>
          <option value="2">Damaged</option>
          <option value="3">Lost</option>
        </select>
      </label>
      <label>IMEI 1<span class="ph-req">*</span><input id="phImei1"></label>
      <label>IMEI 2<input id="phImei2"></label>
      <label>Make<input id="phMake"></label>
      <label>Model<input id="phModel"></label>
      <label>IMSI<input id="phImsi"></label>
      <label>ICCID<input id="phIccid"></label>
      <label>EID<input id="phEid"></label>
    </div>
    <div class="ph-step">Contract &amp; audit</div>
    <div class="ph-fgrid">
      <label>Contract End Date<span class="ph-req">*</span><input type="date" id="phEndDt"></label>
      <label>Contract Start Date<input type="date" id="phStartDt"></label>
      <label>Last Audit Date<input type="date" id="phAudit"></label>
      <label>Device Ordered Date<input type="date" id="phOrdDt"></label>
      <label>Ordered IMEI<input id="phOrdImei"></label>
      <label>Device In Use Date<input type="date" id="phInUse"></label>
      <label class="ph-notes-full">Notes<textarea id="phNotes" rows="3"></textarea></label>
    </div>
  </div>
  <div class="ph-drbtns">
    <button type="button" class="btn2" onclick="phClose()">Cancel</button>
    <button type="button" class="btn2 primary" id="phSaveBtn" onclick="phSave()">Save</button>
  </div>
</div>
<script>
mvpxListInit({
  ctrl: '<%=_searchBean.getController()%>',
  from: '<%=_searchBean.getSrhFromDate()%>',
  to:   '<%=_searchBean.getSrhToDate()%>',
  filters: [
    { id:'filterNum', key:'num', label:'Phone #',         mode:'exact' },
    { id:'filterSt',  key:'st',  label:'Phone Status',    mode:'exact' },
    { id:'filterCur', key:'cur', label:'Current status',  mode:'exact' }
  ]
});
function phChip(selId, val) {
  var s = document.getElementById(selId);
  if (!s) return;
  s.value = (s.value === val ? '' : val);
  mvpxApplyFilters();
}
function phChip2(stVal, selId, val) {
  var st = document.getElementById('filterSt'), s = document.getElementById(selId);
  if (!st || !s) return;
  if (st.value === stVal && s.value === val) { st.value = ''; s.value = ''; }
  else { st.value = stVal; s.value = val; }
  mvpxApplyFilters();
}
function phSummary() {
  var cards = document.querySelector('.vh-cards'), btn = document.getElementById('vhSumBtn');
  var hidden = cards.style.display === 'none';
  cards.style.display = hidden ? '' : 'none';
  btn.textContent = hidden ? 'Hide summary' : 'Show summary';
  if (typeof mvpxFitStart === 'function') mvpxFitStart();
}
function phAjax(params, cb) {
  var body = new URLSearchParams();
  body.append('submitType', '<%=SubmitType.DYNAMIC%>');
  body.append('controller', '<%=_searchBean.getController()%>');
  Object.keys(params).forEach(function(k){ body.append(k, params[k]); });
  ['entityID','loginUser','loginUserID','loginUserRoles','loginUserDisplayName'].forEach(function(k){
    var el = document.getElementById(k); if (el) body.append(k, el.value);
  });
  fetch('MVPGServlet', { method:'POST', headers:{'Content-Type':'application/x-www-form-urlencoded'}, body: body.toString() })
    .then(function(r){ return r.text(); })
    .then(cb)
    .catch(function(){ mvpxToast('Request failed', false); });
}
function phMdyToIso(v) {
  var p = (v || '').split('/');
  return p.length === 3 ? p[2] + '-' + p[0] + '-' + p[1] : '';
}
function phIsoToMdy(v) {
  var p = (v || '').split('-');
  return p.length === 3 ? p[1] + '/' + p[2] + '/' + p[0] : '';
}
function phClose() {
  document.getElementById('phDrawer').classList.remove('on');
  document.getElementById('phScrim').classList.remove('on');
}
function phEdit(id) {
  if (event) event.stopPropagation();
  phAjax({ requestType:'phoneGet', recordID:id }, function(resp){
    var d; try { d = JSON.parse(resp); } catch(e) { mvpxToast('Could not load phone', false); return; }
    document.getElementById('phId').value = id;
    document.getElementById('phDrName').textContent = d.num || '';
    document.getElementById('phNum').value = d.num || '';
    document.getElementById('phPs').value = d.ps || '0';
    document.getElementById('phCs').value = d.cs || '0';
    document.getElementById('phImei1').value = d.imei1 || '';
    document.getElementById('phImei2').value = d.imei2 || '';
    document.getElementById('phMake').value = d.make || '';
    document.getElementById('phModel').value = d.model || '';
    document.getElementById('phImsi').value = d.imsi || '';
    document.getElementById('phIccid').value = d.iccid || '';
    document.getElementById('phEid').value = d.eid || '';
    document.getElementById('phEndDt').value = phMdyToIso(d.endDt);
    document.getElementById('phStartDt').value = phMdyToIso(d.startDt);
    document.getElementById('phAudit').value = phMdyToIso(d.audit);
    document.getElementById('phOrdDt').value = phMdyToIso(d.ordDt);
    document.getElementById('phOrdImei').value = d.ordImei || '';
    document.getElementById('phInUse').value = phMdyToIso(d.inUse);
    document.getElementById('phNotes').value = d.notes || '';
    document.getElementById('phScrim').classList.add('on');
    document.getElementById('phDrawer').classList.add('on');
  });
}
function phSave() {
  var id = document.getElementById('phId').value;
  var btn = document.getElementById('phSaveBtn');
  var num = document.getElementById('phNum').value.trim();
  var imei1 = document.getElementById('phImei1').value.trim();
  var endDt = document.getElementById('phEndDt').value;
  var ps = document.getElementById('phPs').value;
  var cs = document.getElementById('phCs').value;
  var notes = document.getElementById('phNotes').value.trim();
  if (!num) { mvpxToast('Phone Number is required', false); return; }
  if (!imei1) { mvpxToast('IMEI 1 is required', false); return; }
  if (!endDt) { mvpxToast('Contract End Date is required', false); return; }
  if ((ps === '4' || cs === '2' || cs === '3') && !notes) {
    mvpxToast('Notes are required for Inactive, Damaged, or Lost', false); return;
  }
  btn.disabled = true;
  phAjax({
    requestType:'phoneSave', recordID:id,
    num: num, ps: ps, cs: cs, imei1: imei1,
    imei2: document.getElementById('phImei2').value.trim(),
    make: document.getElementById('phMake').value.trim(),
    model: document.getElementById('phModel').value.trim(),
    imsi: document.getElementById('phImsi').value.trim(),
    iccid: document.getElementById('phIccid').value.trim(),
    eid: document.getElementById('phEid').value.trim(),
    notes: notes,
    audit: phIsoToMdy(document.getElementById('phAudit').value),
    endDt: phIsoToMdy(endDt),
    startDt: phIsoToMdy(document.getElementById('phStartDt').value),
    ordDt: phIsoToMdy(document.getElementById('phOrdDt').value),
    ordImei: document.getElementById('phOrdImei').value.trim(),
    inUse: phIsoToMdy(document.getElementById('phInUse').value)
  }, function(resp){
    btn.disabled = false;
    var m = /<mesg>([^<]*)<\/mesg>/.exec(resp);
    if (resp.indexOf('<status>true') >= 0) {
      phRowRefresh(id);
      phClose();
      mvpxToast(m && m[1] ? m[1] : 'Saved', true);
    } else {
      mvpxToast(m && m[1] ? m[1] : 'Save failed', false);
    }
  });
}
function phRowRefresh(id) {
  var tr = document.querySelector('#ciRows tr[data-id="' + id + '"]');
  if (!tr) return;
  var num = document.getElementById('phNum').value.trim();
  var psSel = document.getElementById('phPs');
  var csSel = document.getElementById('phCs');
  var psTxt = psSel.options[psSel.selectedIndex].text;
  var csTxt = csSel.options[csSel.selectedIndex].text;
  var inUse = phIsoToMdy(document.getElementById('phInUse').value);
  var audit = phIsoToMdy(document.getElementById('phAudit').value);
  var notes = document.getElementById('phNotes').value.trim();
  var stLc = psTxt.toLowerCase();
  var curLc = csTxt.toLowerCase();
  tr.dataset.num = num.toLowerCase();
  tr.dataset.st = stLc.indexOf('active') === 0 ? 'active' : 'inactive';
  tr.dataset.cur = curLc;
  var tds = tr.querySelectorAll('td');
  if (tds[0]) tds[0].innerHTML = '<a href="javascript:void(0)" style="color:inherit" onclick="phEdit(\'' + id + '\');return false;">' + num.replace(/</g,'') + '</a>';
  var stPill = stLc.indexOf('active') === 0 ? 'green' : 'slate';
  var curPill = 'slate';
  if (curLc === 'in use') curPill = 'green';
  else if (curLc === 'damaged') curPill = 'amber';
  else if (curLc === 'lost') curPill = 'red';
  if (tds[1]) tds[1].innerHTML = '<span class="pill ' + stPill + '"><span class="d"></span>' + psTxt + '</span>';
  if (tds[2]) tds[2].innerHTML = '<span class="pill ' + curPill + '"><span class="d"></span>' + csTxt + '</span>';
  if (tds[3]) tds[3].innerHTML = inUse || '&mdash;';
  if (tds[4]) tds[4].innerHTML = audit || '&mdash;';
  if (tds[5]) tds[5].textContent = notes || '—';
  if (typeof mvpxApplyFilters === 'function') mvpxApplyFilters();
}
</script>
<%
} else {
%>

<script>
function validatePageData(submitType, isValid) {

	if(submitType == <%=SubmitType.CREATE_CONFIRM%> || submitType == <%=SubmitType.UPDATE_CONFIRM%>) {
		if(isValid) {
			var mandatoryFieldsArray = new Array();
			mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["phoneNumber"], "Phone Number");
			if(document.formmain["phoneStatus"] && document.formmain["phoneStatus"].value == "4") {
				mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["remarks"], "Notes");
			}
			var cs = document.formmain["currentStatus"] ? document.formmain["currentStatus"].value : "0";
			if(cs == "2" || cs == "3") {
				mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["remarks"], "Notes");
			}
			mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["serialNumber"], "IMEI 1");
			mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["contractEndDate"], "Contract End Date");
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
			<%if(submitType == SubmitType.CREATE || submitType == SubmitType.UPDATE) {%>
				<input type="hidden" id="phoneID" name="phoneID" value="<%=_recordBean.getPhoneID()%>">
				<div class="row">
					<div class="col-5">
						<div class="row form-row form-group form-group-sm">
							<label class="col-3 col-form-label required text-left">Phone Number</label>
							<div class="col-9 text-left"><input type="text" id="phoneNumber" name="phoneNumber" class="form-control form-control-sm" value="<%=_recordBean.getPhoneNumber()%>"></div>
						</div>
						<div class="row">
							<label class="col-3 col-form-label text-left">Phone Status</label>
							<div class="col-9 text-left">
								<div class="form-check-inline">
									<label class="form-check-label"><input type="radio" class="form-check-input" name="phoneStatus" value="0" checked>Active</label>
								</div>
								<div class="form-check-inline">
									<label class="form-check-label"><input type="radio" class="form-check-input" name="phoneStatus" value="4">Inactive</label>
								</div>
							</div>
						</div>
						<div class="row">
							<label class="col-3 col-form-label text-left">Current Status</label>
							<div class="col-9 text-left">
								<div class="form-check-inline">
									<label class="form-check-label"><input type="radio" class="form-check-input" name="currentStatus" value="0" checked>In Use</label>
								</div>
								<div class="form-check-inline">
									<label class="form-check-label"><input type="radio" class="form-check-input" name="currentStatus" value="1">Not Used</label>
								</div>
								<div class="form-check-inline">
									<label class="form-check-label"><input type="radio" class="form-check-input" name="currentStatus" value="2">Damaged</label>
								</div>
								<div class="form-check-inline">
									<label class="form-check-label"><input type="radio" class="form-check-input" name="currentStatus" value="3">Lost</label>
								</div>
							</div>
						</div>
						<div class="row form-row form-group form-group-sm">
							<label class="col-3 col-form-label required text-left">IMEI 1</label>
							<div class="col-9 text-left"><input type="text" id="serialNumber" name="serialNumber" class="form-control form-control-sm" value="<%=_recordBean.getSerialNumber()%>"></div>
						</div>
						<div class="row form-row form-group form-group-sm">
							<label class="col-3 col-form-label text-left">IMEI 2</label>
							<div class="col-9 text-left"><input type="text" id="imei2" name="imei2" class="form-control form-control-sm" value="<%=_recordBean.getImei2()%>"></div>
						</div>
						<div class="row form-row form-group form-group-sm">
							<label class="col-3 col-form-label text-left">Make</label>
							<div class="col-9 text-left"><input type="text" id="deviceMake" name="deviceMake" class="form-control form-control-sm" value="<%=_recordBean.getDeviceMake()%>"></div>
						</div>
						<div class="row form-row form-group form-group-sm">
							<label class="col-3 col-form-label text-left">Model</label>
							<div class="col-9 text-left"><input type="text" id="deviceModel" name="deviceModel" class="form-control form-control-sm" value="<%=_recordBean.getDeviceModel()%>"></div>
						</div>
						<div class="row form-row form-group form-group-sm">
							<label class="col-3 col-form-label text-left">IMSI</label>
							<div class="col-9 text-left"><input type="text" id="imsi" name="imsi" class="form-control form-control-sm" value="<%=_recordBean.getImsi()%>"></div>
						</div>
						<div class="row form-row form-group form-group-sm">
							<label class="col-3 col-form-label text-left">ICCID</label>
							<div class="col-9 text-left"><input type="text" id="iccid" name="iccid" class="form-control form-control-sm" value="<%=_recordBean.getIccid()%>"></div>
						</div>
						<div class="row form-row form-group form-group-sm">
							<label class="col-3 col-form-label text-left">EID</label>
							<div class="col-9 text-left"><input type="text" id="eid" name="eid" class="form-control form-control-sm" value="<%=_recordBean.getEid()%>"></div>
						</div>
					</div>

					<div class="col-2"></div>

					<div class="col-5">
						<div class="row form-row form-group form-group-sm">
							<label class="col-3 col-form-label required text-left">Contract End Date</label>
							<div class="col-9 text-left"><input type="text" id="contractEndDate" name="contractEndDate" class="form-control form-control-sm datepicker" value="<%=_recordBean.getContractEndDate()%>"></div>
						</div>
						<div class="row form-row form-group form-group-sm">
							<label class="col-3 col-form-label text-left">Contract Start Date</label>
							<div class="col-9 text-left"><input type="text" id="contractStartDate" name="contractStartDate" class="form-control form-control-sm datepicker" value="<%=_recordBean.getContractStartDate()%>"></div>
						</div>
						<div class="row form-row form-group form-group-sm">
							<label class="col-3 col-form-label text-left">Last Audit Date</label>
							<div class="col-9 text-left"><input type="text" id="auditedDate" name="auditedDate" class="form-control form-control-sm datepicker" value="<%=_recordBean.getAuditedDate()%>"></div>
						</div>
						<div class="row form-row form-group form-group-sm">
							<label class="col-3 col-form-label text-left">Device Ordered Date</label>
							<div class="col-9 text-left"><input type="text" id="deviceOrderedDate" name="deviceOrderedDate" class="form-control form-control-sm datepicker" value="<%=_recordBean.getDeviceOrderedDate()%>"></div>
						</div>
						<div class="row form-row form-group form-group-sm">
							<label class="col-3 col-form-label text-left">Ordered IMEI</label>
							<div class="col-9 text-left"><input type="text" id="deviceOrderedImei" name="deviceOrderedImei" class="form-control form-control-sm" value="<%=_recordBean.getDeviceOrderedImei()%>"></div>
						</div>
						<div class="row form-row form-group form-group-sm">
							<label class="col-3 col-form-label text-left">In Use Date</label>
							<div class="col-9 text-left"><input type="text" id="deviceInUseDate" name="deviceInUseDate" class="form-control form-control-sm datepicker" value="<%=_recordBean.getDeviceInUseDate()%>"></div>
						</div>
						<div class="row form-row form-group form-group-sm">
							<label class="col-3 col-form-label text-left">Notes</label>
							<div class="col-9 text-left"><textarea id="remarks" name="remarks" class="form-control form-control-sm"><%=_recordBean.getRemarks()%></textarea></div>
						</div>
					</div>
				</div>
				<script>
					setRadioButtonValue(document.formmain["phoneStatus"], "<%=_ps%>");
					setRadioButtonValue(document.formmain["currentStatus"], "<%=_cs%>");
				</script>

			<%} else if(submitType == SubmitType.BROWSE) {%>
				<input type="hidden" id="phoneID" name="phoneID" value="<%=_recordBean.getPhoneID()%>">
				<div class="row">
					<div class="col-5">
						<div class="row">
							<label class="col-3 col-form-label text-left">Phone Number</label>
							<div class="col-9 form-control-plaintext text-left"><%=_recordBean.getPhoneNumber()%></div>
						</div>
						<div class="row">
							<label class="col-3 col-form-label text-left">Phone Status</label>
							<div class="col-9 form-control-plaintext text-left"><%=RecordStatus.RecordStatus[Integer.parseInt(_ps)]%></div>
						</div>
						<div class="row">
							<label class="col-3 col-form-label text-left">Current Status</label>
							<div class="col-9 form-control-plaintext text-left"><%=AdminPhones.currentStatusLabel(_cs)%></div>
						</div>
						<div class="row">
							<label class="col-3 col-form-label text-left">IMEI 1</label>
							<div class="col-9 form-control-plaintext text-left"><%=_recordBean.getSerialNumber()%></div>
						</div>
						<div class="row">
							<label class="col-3 col-form-label text-left">IMEI 2</label>
							<div class="col-9 form-control-plaintext text-left"><%=_recordBean.getImei2()%></div>
						</div>
						<div class="row">
							<label class="col-3 col-form-label text-left">Make / Model</label>
							<div class="col-9 form-control-plaintext text-left"><%=((_recordBean.getDeviceMake()+" "+_recordBean.getDeviceModel()).trim())%></div>
						</div>
						<div class="row">
							<label class="col-3 col-form-label text-left">IMSI</label>
							<div class="col-9 form-control-plaintext text-left"><%=_recordBean.getImsi()%></div>
						</div>
						<div class="row">
							<label class="col-3 col-form-label text-left">ICCID</label>
							<div class="col-9 form-control-plaintext text-left"><%=_recordBean.getIccid()%></div>
						</div>
						<div class="row">
							<label class="col-3 col-form-label text-left">EID</label>
							<div class="col-9 form-control-plaintext text-left"><%=_recordBean.getEid()%></div>
						</div>
					</div>

					<div class="col-2"></div>

					<div class="col-5">
						<div class="row">
							<label class="col-3 col-form-label text-left">Contract End Date</label>
							<div class="col-9 form-control-plaintext text-left"><%=_recordBean.getContractEndDate()%></div>
						</div>
						<div class="row">
							<label class="col-3 col-form-label text-left">Contract Start Date</label>
							<div class="col-9 form-control-plaintext text-left"><%=_recordBean.getContractStartDate()%></div>
						</div>
						<div class="row">
							<label class="col-3 col-form-label text-left">Last Audit Date</label>
							<div class="col-9 form-control-plaintext text-left"><%=_recordBean.getAuditedDate()%></div>
						</div>
						<div class="row">
							<label class="col-3 col-form-label text-left">Device Ordered Date</label>
							<div class="col-9 form-control-plaintext text-left"><%=_recordBean.getDeviceOrderedDate()%></div>
						</div>
						<div class="row">
							<label class="col-3 col-form-label text-left">Ordered IMEI</label>
							<div class="col-9 form-control-plaintext text-left"><%=_recordBean.getDeviceOrderedImei()%></div>
						</div>
						<div class="row">
							<label class="col-3 col-form-label text-left">In Use Date</label>
							<div class="col-9 form-control-plaintext text-left"><%=_recordBean.getDeviceInUseDate()%></div>
						</div>
						<%if(_recordBean.getRemarks().length() > 0) {%>
						<div class="row">
							<label class="col-3 col-form-label text-left">Notes</label>
							<div class="col-9 form-control-plaintext text-left"><%=_recordBean.getRemarks()%></div>
						</div>
						<%}%>
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
						<button class="btn btn-success text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.CREATE_CONFIRM%>','<%=_recordBean.getController()%>','<%=_recordBean.getPhoneID()%>');">Save</button>
						</div>
					<%} else {%>
						<button class="btn btn-success text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.UPDATE_CONFIRM%>','<%=_recordBean.getController()%>','<%=_recordBean.getPhoneID()%>');">Save</button>
						</div>
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
					<button class="btn btn-primary text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.UPDATE%>','<%=_recordBean.getController()%>','<%=_recordBean.getPhoneID()%>');">Edit</button>
				<%}%>
				</div>
				<div class="col-4 text-right">
				<%if("0".equalsIgnoreCase(_recordBean.getStatus())) {%>
					<button class="btn btn-danger text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.DELETE%>','<%=_recordBean.getController()%>','<%=_recordBean.getPhoneID()%>');">Delete</button>
				<%}%>
				</div>
			</div>
		<%}%>
	</div>
</div>
<%@ include file="includeFooter.jsp"%>
<%}%>
