<!DOCTYPE html>
<%@ page import="java.util.*, com.util.*, com.beans.*"%>
<%!
private String escG(String s) {
  if (s == null) return "";
  return s.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;")
          .replace("\"","&quot;").replace("'","&#39;");
}
private String locClass(String loc) {
  if (loc == null) return "slate";
  String l = loc.toLowerCase();
  if (l.indexOf("dealer") >= 0) return "amber";
  if (l.indexOf("sammy") >= 0) return "blue";
  if (l.indexOf("dnk") >= 0) return "green";
  return "slate";
}
%>
<jsp:useBean id="_errorBean" class="com.beans.ErrorBean" scope="request" />
<%
int submitType = request.getAttribute("submitType") == null ? SubmitType.SEARCH : Integer.parseInt(request.getAttribute("submitType").toString().trim());
SearchBean _searchBean = new SearchBean();
Object _rawBeanObj = request.getAttribute("_recordBean");
if (_rawBeanObj instanceof SearchBean) {
  _searchBean = (SearchBean) _rawBeanObj;
  request.removeAttribute("_recordBean");
}
%>
<jsp:useBean id="_recordBean" class="com.beans.GroundedVehicle" scope="request" />
<%
if (submitType != SubmitType.SEARCH) submitType = SubmitType.SEARCH;

List dataList = _searchBean.getDataList() == null ? new ArrayList() : _searchBean.getDataList();
List histList = new ArrayList();
List opList = new ArrayList();
if (_searchBean.getTransMap() != null) {
  if (_searchBean.getTransMap().get("historyList") instanceof List)
    histList = (List) _searchBean.getTransMap().get("historyList");
  if (_searchBean.getTransMap().get("operationalList") instanceof List)
    opList = (List) _searchBean.getTransMap().get("operationalList");
}

int cntTotal = 0, cntDealer = 0, cntSammy = 0, cntDnk = 0, cntWeek = 0;
List<String[]> rows = new ArrayList<String[]>();
/* 0=id 1=num 2=vin 3=reason 4=gdate 5=days 6=loc 7=fdate 8=fnote 9=op 10=provider */
for (int i = 0; i < dataList.size(); i++) {
  List r = (List) dataList.get(i);
  String[] c = new String[11];
  for (int j = 0; j < 11; j++) {
    c[j] = (j < r.size() && r.get(j) != null) ? r.get(j).toString().trim() : "";
  }
  cntTotal++;
  String loc = c[6];
  if (loc.length() == 0) {
    if ("4".equals(c[9])) loc = "Dealer";
    else if ("5".equals(c[9])) loc = "Sammy";
    else loc = "DNK7";
    c[6] = loc;
  }
  String locLc = loc.toLowerCase();
  if (locLc.indexOf("dealer") >= 0) cntDealer++;
  else if (locLc.indexOf("sammy") >= 0) cntSammy++;
  else if (locLc.indexOf("dnk") >= 0) cntDnk++;
  int days = 0;
  try { days = Integer.parseInt(c[5]); } catch (Exception ignore) { }
  if (days >= 7) cntWeek++;
  rows.add(c);
}

String[] reasons = com.dataobjects.GroundedVehicleDAO.REASONS;
String[] locations = com.dataobjects.GroundedVehicleDAO.LOCATIONS;
%>
<%@ include file="includeHeader.jsp"%>
<link rel="stylesheet" href="../jsp/assets/css/mvpx-list.css?v=20261021g">
<style>
.gv-wrap{padding:0 0 8px}
.gv-head{display:flex;justify-content:space-between;align-items:flex-start;gap:10px;flex-wrap:wrap;margin-bottom:8px}
.gv-head h2{margin:0;font-size:20px;font-weight:700;color:#0F172A;letter-spacing:-.02em}
.gv-sub{font-size:12px;color:#64748B;margin-top:2px}
.gv-kpis{display:flex;gap:6px;flex-wrap:wrap}
.gv-kpi{border:1px solid #E4E8F0;background:#fff;border-radius:8px;padding:6px 12px;cursor:pointer;text-align:center;min-width:68px}
.gv-kpi:hover,.gv-kpi.on{border-color:#0f172a;background:#F8FAFC}
.gv-kpi b{display:block;font-size:18px;line-height:1.1;color:#0F172A}
.gv-kpi span{font-size:9.5px;font-weight:700;text-transform:uppercase;letter-spacing:.04em;color:#64748B}
.gv-kpi.red b{color:var(--status-action-fg,#C62828)}
.gv-kpi.amber b{color:var(--status-warn-fg,#B45309)}
.gv-kpi.blue b{color:var(--status-info-fg,#1D4ED8)}
.gv-kpi.green b{color:var(--status-ok-fg,#15803D)}
.gv-actions{display:flex;align-items:flex-start;gap:10px;flex-wrap:wrap}
.gv-tabs{display:inline-flex;border:1px solid #E4E8F0;border-radius:8px;padding:2px;background:#fff;margin-bottom:8px}
.gv-tabs button{border:none;background:transparent;padding:6px 12px;font-size:12px;font-weight:700;color:#64748B;cursor:pointer;border-radius:6px}
.gv-tabs button.on{background:#0f172a;color:#fff}
.gv-toolbar{display:flex;gap:6px;flex-wrap:wrap;align-items:center;padding:8px 10px;border-bottom:1px solid #EEF1F6;background:#FAFBFC}
.gv-flt{border:1px solid #E4E8F0;border-radius:7px;padding:5px 8px;font-size:12.5px;background:#fff}
.tablewrap{background:#fff;border:1px solid #E4E8F0;border-radius:10px;overflow:hidden}
.tablewrap table{width:100%;border-collapse:collapse}
.tablewrap th{text-align:left;font-size:11px;color:#64748B;font-weight:700;text-transform:uppercase;letter-spacing:.03em;padding:8px 10px;background:#fff;border-bottom:1px solid #E4E8F0}
.tablewrap td{padding:8px 10px;border-bottom:1px solid #EEF1F6;font-size:13px;vertical-align:middle}
.tablewrap tbody tr{cursor:pointer}
.tablewrap tbody tr:hover{background:#F8FAFC}
.gv-days{font-variant-numeric:tabular-nums;font-weight:800}
.gv-days.wk{color:var(--status-warn-fg,#B45309)}
.gv-days.long{color:var(--status-action-fg,#C62828)}
.pill{display:inline-flex;align-items:center;gap:5px;border-radius:999px;padding:2px 8px;font-size:11px;font-weight:700}
.pill .d{width:6px;height:6px;border-radius:50%}
.pill.green{background:var(--status-ok-bg,#E7F6EE);color:var(--status-ok-fg,#15803D)}.pill.green .d{background:var(--status-ok-fg,#15803D)}
.pill.amber{background:var(--status-warn-bg,#FBF1E2);color:var(--status-warn-fg,#B45309)}.pill.amber .d{background:var(--status-warn-fg,#B45309)}
.pill.blue{background:var(--status-info-bg,#EFF4FF);color:var(--status-info-fg,#1D4ED8)}.pill.blue .d{background:var(--status-info-fg,#1D4ED8)}
.pill.slate{background:#F1F5F9;color:#475569}.pill.slate .d{background:#64748B}
.btn2{border:1px solid #E4E8F0;background:#fff;color:#111827;padding:6px 11px;border-radius:7px;font-size:12.5px;font-weight:600;cursor:pointer}
.btn2.primary{background:#0f172a;border-color:#0f172a;color:#fff}
.btn2.danger{border-color:#FECACA;color:#C62828}
.tablefoot{display:flex;justify-content:space-between;align-items:center;padding:7px 10px;font-size:12.5px;color:#64748B;background:#FAFBFC}
.gv-scrim{display:none;position:fixed;inset:0;background:rgba(15,23,42,.35);z-index:390}
.gv-scrim.on{display:block}
.gv-drawer{position:fixed;top:0;right:0;width:min(440px,100vw);height:100%;background:#fff;z-index:400;transform:translateX(100%);transition:transform .2s ease;display:flex;flex-direction:column;box-shadow:-8px 0 24px rgba(15,23,42,.12)}
.gv-drawer.on{transform:translateX(0)}
.gv-drawer h3{margin:0;padding:14px 16px;border-bottom:1px solid #E4E8F0;font-size:16px;display:flex;align-items:center;gap:8px}
.gv-drawer h3 small{font-weight:500;color:#64748B;font-size:12px}
.gv-x{margin-left:auto;border:1px solid #E4E8F0;background:#fff;border-radius:6px;width:30px;height:30px;cursor:pointer}
.gv-body{flex:1;overflow:auto;padding:14px 16px}
.gv-fgrid{display:grid;grid-template-columns:1fr 1fr;gap:10px}
.gv-drawer label{display:flex;flex-direction:column;gap:4px;font-size:11px;font-weight:700;color:#64748B;text-transform:uppercase;letter-spacing:.03em;margin-bottom:10px}
.gv-drawer input,.gv-drawer select,.gv-drawer textarea{border:1px solid #E4E8F0;border-radius:7px;padding:7px 9px;font-size:13px;font-family:inherit;color:#0F172A}
.gv-drawer textarea{min-height:70px;resize:vertical}
.gv-foot{padding:12px 16px;border-top:1px solid #E4E8F0;display:flex;gap:8px;flex-wrap:wrap}
.gv-tl{list-style:none;padding:0;margin:0}
.gv-tl li{padding:8px 0;border-bottom:1px solid #F1F5F9;font-size:12.5px}
.gv-tl .w{color:#64748B;font-size:11px}
.da-empty{text-align:center;color:#94A3B8;padding:28px !important}
.nm{font-weight:700;color:#0F172A}
.meta{color:#64748B;font-size:12px}
</style>

<div class="gv-wrap">
  <div class="gv-head">
    <div>
      <h2>Grounded Vehicles</h2>
      <div class="gv-sub">Follow vans that are down &mdash; update location, then unground when they are ready.</div>
    </div>
    <div class="gv-actions">
      <button type="button" class="btn2 primary" onclick="gvGroundOpen()">Ground van</button>
      <div class="gv-kpis">
        <button type="button" class="gv-kpi on" data-kpi="" onclick="gvKpi(this,'')"><b><%=cntTotal%></b><span>Grounded</span></button>
        <button type="button" class="gv-kpi amber" data-kpi="dealer" onclick="gvKpi(this,'dealer')"><b><%=cntDealer%></b><span>Dealer</span></button>
        <button type="button" class="gv-kpi blue" data-kpi="sammy" onclick="gvKpi(this,'sammy')"><b><%=cntSammy%></b><span>Sammy</span></button>
        <button type="button" class="gv-kpi green" data-kpi="dnk" onclick="gvKpi(this,'dnk')"><b><%=cntDnk%></b><span>DNK7</span></button>
        <button type="button" class="gv-kpi red" data-kpi="week" onclick="gvKpi(this,'week')"><b><%=cntWeek%></b><span>7+ days</span></button>
      </div>
    </div>
  </div>

  <div class="gv-tabs">
    <button type="button" class="on" id="tabOpen" onclick="gvTab('open')">Currently grounded</button>
    <button type="button" id="tabHist" onclick="gvTab('hist')">Returned to service</button>
  </div>

  <div id="gvOpen">
    <div class="tablewrap">
      <div class="gv-toolbar">
        <input class="gv-flt" id="gvQ" placeholder="Search vehicle / VIN / reason" oninput="gvFilter()" style="min-width:220px">
        <select class="gv-flt" id="gvLoc" onchange="gvFilter()">
          <option value="">All locations</option>
          <%for (int i=0;i<locations.length;i++){%><option value="<%=escG(locations[i].toLowerCase())%>"><%=escG(locations[i])%></option><%}%>
        </select>
        <select class="gv-flt" id="gvReason" onchange="gvFilter()">
          <option value="">All reasons</option>
          <%for (int i=0;i<reasons.length;i++){%><option value="<%=escG(reasons[i].toLowerCase())%>"><%=escG(reasons[i])%></option><%}%>
        </select>
      </div>
      <table>
        <thead>
          <tr>
            <th>Vehicle</th>
            <th>Reason</th>
            <th>Grounded date</th>
            <th>Days grounded</th>
            <th>Location</th>
            <th>Follow-up</th>
            <th></th>
          </tr>
        </thead>
        <tbody id="gvRows">
          <%if (rows.isEmpty()) {%>
          <tr><td colspan="7" class="da-empty">No grounded vehicles. Use Ground van to take one out of service.</td></tr>
          <%}%>
          <%for (String[] r : rows) {
            int days = 0; try { days = Integer.parseInt(r[5]); } catch (Exception ignore) {}
            String dayCls = days >= 14 ? "long" : (days >= 7 ? "wk" : "");
            String follow = r[7];
            if (r[8].length() > 0) follow = (follow.length()>0 ? follow + " · " : "") + r[8];
            if (follow.length() == 0) follow = "—";
          %>
          <tr data-id="<%=escG(r[0])%>"
              data-num="<%=escG(r[1])%>"
              data-vin="<%=escG(r[2])%>"
              data-reason="<%=escG(r[3].toLowerCase())%>"
              data-gdate="<%=escG(r[4])%>"
              data-days="<%=days%>"
              data-loc="<%=escG(r[6].toLowerCase())%>"
              data-fdate="<%=escG(r[7])%>"
              data-fnote="<%=escG(r[8])%>"
              data-reason-raw="<%=escG(r[3])%>"
              data-loc-raw="<%=escG(r[6])%>"
              onclick="gvOpen(this)">
            <td>
              <div class="nm"><%=escG(r[1])%></div>
              <div class="meta"><%=r[2].length()>0 ? escG(r[2]) : "&mdash;"%></div>
            </td>
            <td><%=r[3].length()>0 ? escG(r[3]) : "&mdash;"%></td>
            <td><%=r[4].length()>0 ? escG(r[4]) : "&mdash;"%></td>
            <td class="gv-days <%=dayCls%>"><%=days%></td>
            <td><span class="pill <%=locClass(r[6])%>"><span class="d"></span><%=escG(r[6])%></span></td>
            <td class="meta"><%=escG(follow)%></td>
            <td style="text-align:right;white-space:nowrap" onclick="event.stopPropagation()">
              <button type="button" class="btn2" onclick="gvOpen(this.closest('tr'))">Follow up</button>
            </td>
          </tr>
          <%}%>
        </tbody>
      </table>
      <div class="tablefoot">
        <span id="gvShow">Showing <%=rows.size()%> of <%=rows.size()%></span>
        <button type="button" class="btn2" onclick="submitPageDataForm('<%=SubmitType.SEARCH%>','GroundedVehicle')">Refresh</button>
      </div>
    </div>
  </div>

  <div id="gvHist" style="display:none">
    <div class="tablewrap">
      <table>
        <thead>
          <tr>
            <th>Vehicle</th>
            <th>Reason</th>
            <th>Returned</th>
            <th>Days down</th>
            <th>Location</th>
            <th>What fixed it</th>
            <th>By</th>
          </tr>
        </thead>
        <tbody>
          <%if (histList == null || histList.isEmpty()) {%>
          <tr><td colspan="7" class="da-empty">No returned vans yet. Unground from the current list to build history.</td></tr>
          <%} else {
            for (int i = 0; i < histList.size(); i++) {
              List h = (List) histList.get(i);
              String[] c = new String[10];
              for (int j = 0; j < 10; j++)
                c[j] = (j < h.size() && h.get(j) != null) ? h.get(j).toString().trim() : "";
          %>
          <tr>
            <td>
              <div class="nm"><%=escG(c[1])%></div>
              <div class="meta"><%=c[2].length()>0 ? escG(c[2]) : "&mdash;"%></div>
            </td>
            <td><%=c[3].length()>0 ? escG(c[3]) : "&mdash;"%></td>
            <td><%=escG(c[4])%></td>
            <td class="gv-days"><%=escG(c[5])%></td>
            <td><span class="pill <%=locClass(c[6])%>"><span class="d"></span><%=c[6].length()>0 ? escG(c[6]) : "&mdash;"%></span></td>
            <td class="meta"><%=c[7].length()>0 ? escG(c[7]) : "&mdash;"%></td>
            <td class="meta"><%=escG(c[8])%></td>
          </tr>
          <%} }%>
        </tbody>
      </table>
    </div>
  </div>
</div>

<div class="gv-scrim" id="gvScrim" onclick="gvClose()"></div>
<aside class="gv-drawer" id="gvGroundDrawer" aria-label="Ground a van">
  <h3>Ground van <small>Take out of service</small><button type="button" class="gv-x" onclick="gvClose()">&#10005;</button></h3>
  <div class="gv-body">
    <label>Vehicle
      <input class="gv-flt" id="gvPickQ" placeholder="Filter by number or VIN" oninput="gvPickFilter()" style="margin-bottom:6px;width:100%">
      <select id="gvPickVan" size="8" style="width:100%;min-height:160px">
        <%if (opList == null || opList.isEmpty()) {%>
        <option value="">No operational vans</option>
        <%} else {
          for (int i = 0; i < opList.size(); i++) {
            List o = (List) opList.get(i);
            String oid = (o.size()>0 && o.get(0)!=null) ? o.get(0).toString().trim() : "";
            String onum = (o.size()>1 && o.get(1)!=null) ? o.get(1).toString().trim() : "";
            String ovin = (o.size()>2 && o.get(2)!=null) ? o.get(2).toString().trim() : "";
        %>
        <option value="<%=escG(oid)%>" data-num="<%=escG(onum.toLowerCase())%>" data-vin="<%=escG(ovin.toLowerCase())%>"><%=escG(onum)%><%=ovin.length()>0 ? " · " + escG(ovin) : ""%></option>
        <%} }%>
      </select>
    </label>
    <div class="gv-fgrid">
      <label>Location
        <select id="gvNewLoc">
          <%for (int i=0;i<locations.length;i++){%><option value="<%=escG(locations[i])%>"><%=escG(locations[i])%></option><%}%>
        </select>
      </label>
      <label>Reason
        <select id="gvNewReason">
          <option value="">Select…</option>
          <%for (int i=0;i<reasons.length;i++){%><option value="<%=escG(reasons[i])%>"><%=escG(reasons[i])%></option><%}%>
        </select>
      </label>
    </div>
    <label>Notes<textarea id="gvNewNote" placeholder="What happened, shop, who called…"></textarea></label>
  </div>
  <div class="gv-foot">
    <button type="button" class="btn2 primary" onclick="gvGroundSave()">Ground van</button>
  </div>
</aside>
<aside class="gv-drawer" id="gvDrawer" aria-label="Grounded vehicle follow-up">
  <h3>Follow up <small id="gvDrName"></small><button type="button" class="gv-x" onclick="gvClose()">&#10005;</button></h3>
  <div class="gv-body">
    <input type="hidden" id="gvId">
    <div class="gv-fgrid">
      <label>VIN<input id="gvVin" readonly></label>
      <label>Grounded date<input id="gvGDate" readonly></label>
      <label>Days grounded<input id="gvDays" readonly></label>
      <label>Location
        <select id="gvDrLoc">
          <%for (int i=0;i<locations.length;i++){%><option value="<%=escG(locations[i])%>"><%=escG(locations[i])%></option><%}%>
        </select>
      </label>
      <label>Reason
        <select id="gvDrReason">
          <option value=""></option>
          <%for (int i=0;i<reasons.length;i++){%><option value="<%=escG(reasons[i])%>"><%=escG(reasons[i])%></option><%}%>
        </select>
      </label>
      <label>Next follow-up<input type="date" id="gvDrFollow"></label>
    </div>
    <label>Notes<textarea id="gvDrNote" placeholder="Shop update, parts ETA, who you called…"></textarea></label>
    <div class="meta" style="margin:8px 0 6px;font-weight:800;text-transform:uppercase;letter-spacing:.04em">Timeline</div>
    <ul class="gv-tl" id="gvTl"><li class="meta">Loading…</li></ul>
  </div>
  <div class="gv-foot">
    <button type="button" class="btn2 primary" onclick="gvSave()">Save follow-up</button>
    <button type="button" class="btn2 danger" onclick="gvUnground()">Unground</button>
  </div>
</aside>

<script>
function gvTab(which) {
  document.getElementById('gvOpen').style.display = which === 'open' ? '' : 'none';
  document.getElementById('gvHist').style.display = which === 'hist' ? '' : 'none';
  document.getElementById('tabOpen').classList.toggle('on', which === 'open');
  document.getElementById('tabHist').classList.toggle('on', which === 'hist');
}
function gvKpi(btn, key) {
  document.querySelectorAll('.gv-kpi').forEach(function(b){ b.classList.remove('on'); });
  btn.classList.add('on');
  document.getElementById('gvLoc').value = (key === 'dealer' || key === 'sammy' || key === 'dnk') ? key : '';
  window._gvWeek = key === 'week';
  gvFilter();
}
function gvFilter() {
  var q = (document.getElementById('gvQ').value || '').toLowerCase();
  var loc = (document.getElementById('gvLoc').value || '').toLowerCase();
  var reason = (document.getElementById('gvReason').value || '').toLowerCase();
  var week = !!window._gvWeek;
  var rows = document.querySelectorAll('#gvRows tr[data-id]');
  var n = 0, tot = rows.length;
  rows.forEach(function(tr) {
    var hay = ((tr.dataset.num||'') + ' ' + (tr.dataset.vin||'') + ' ' + (tr.dataset.reason||'')).toLowerCase();
    var ok = (!q || hay.indexOf(q) >= 0)
      && (!loc || (tr.dataset.loc||'').indexOf(loc) >= 0)
      && (!reason || (tr.dataset.reason||'').indexOf(reason) >= 0)
      && (!week || parseInt(tr.dataset.days||'0',10) >= 7);
    tr.style.display = ok ? '' : 'none';
    if (ok) n++;
  });
  var el = document.getElementById('gvShow');
  if (el) el.textContent = 'Showing ' + n + ' of ' + tot;
}
function gvOpen(tr) {
  if (!tr || !tr.dataset) return;
  document.getElementById('gvId').value = tr.dataset.id;
  document.getElementById('gvDrName').textContent = tr.dataset.num || '';
  document.getElementById('gvVin').value = tr.dataset.vin || '';
  document.getElementById('gvGDate').value = tr.dataset.gdate || '';
  document.getElementById('gvDays').value = tr.dataset.days || '0';
  var loc = tr.dataset.locRaw || 'DNK7';
  var sel = document.getElementById('gvDrLoc');
  var found = false;
  for (var i = 0; i < sel.options.length; i++) {
    if (sel.options[i].value.toLowerCase() === loc.toLowerCase()) { sel.selectedIndex = i; found = true; break; }
  }
  if (!found) sel.value = 'Other';
  var rsn = tr.dataset.reasonRaw || '';
  var rs = document.getElementById('gvDrReason');
  found = false;
  for (var j = 0; j < rs.options.length; j++) {
    if (rs.options[j].value === rsn) { rs.selectedIndex = j; found = true; break; }
  }
  if (!found && rsn) {
    rs.value = 'Other';
    document.getElementById('gvDrNote').value = rsn + (tr.dataset.fnote ? '\n' + tr.dataset.fnote : '');
  } else {
    document.getElementById('gvDrNote').value = tr.dataset.fnote || '';
  }
  document.getElementById('gvDrFollow').value = toIsoDate(tr.dataset.fdate || '');
  document.getElementById('gvScrim').classList.add('on');
  document.getElementById('gvDrawer').classList.add('on');
  gvTimeline(tr.dataset.id);
}
function toIsoDate(s) {
  if (!s) return '';
  var m = /(\d{1,2})\/(\d{1,2})\/(\d{4})/.exec(s);
  if (m) return m[3] + '-' + ('0'+m[1]).slice(-2) + '-' + ('0'+m[2]).slice(-2);
  if (/^\d{4}-\d{2}-\d{2}/.test(s)) return s.substring(0,10);
  return '';
}
function gvClose() {
  document.getElementById('gvScrim').classList.remove('on');
  document.getElementById('gvDrawer').classList.remove('on');
  document.getElementById('gvGroundDrawer').classList.remove('on');
}
function gvGroundOpen() {
  gvClose();
  document.getElementById('gvScrim').classList.add('on');
  document.getElementById('gvGroundDrawer').classList.add('on');
  var q = document.getElementById('gvPickQ');
  if (q) { q.value = ''; gvPickFilter(); q.focus(); }
}
function gvPickFilter() {
  var q = (document.getElementById('gvPickQ').value || '').toLowerCase();
  var opts = document.querySelectorAll('#gvPickVan option[value]');
  opts.forEach(function(op) {
    if (!op.value) return;
    var hay = (op.dataset.num || '') + ' ' + (op.dataset.vin || '') + ' ' + (op.textContent || '').toLowerCase();
    op.hidden = !!(q && hay.indexOf(q) < 0);
  });
}
function gvGroundSave() {
  var sel = document.getElementById('gvPickVan');
  var id = sel && sel.value ? sel.value : '';
  var reason = (document.getElementById('gvNewReason').value || '').trim();
  if (!id) { alert('Pick a van.'); return; }
  if (!reason) { alert('Choose a reason.'); document.getElementById('gvNewReason').focus(); return; }
  var loc = document.getElementById('gvNewLoc').value || 'DNK7';
  var note = document.getElementById('gvNewNote').value || '';
  var label = sel.options[sel.selectedIndex] ? sel.options[sel.selectedIndex].text : id;
  if (!confirm('Ground ' + label + ' at ' + loc + '?')) return;
  document.getElementById('gvId').value = id;
  gvPost('ground', { location: loc, reason: reason, note: note }).then(function(resp){
    if (resp.indexOf('<status>true') >= 0) {
      if (typeof mvpxToast === 'function') mvpxToast('Van grounded', true);
      submitPageDataForm('<%=SubmitType.SEARCH%>','GroundedVehicle');
    } else {
      var m = /<mesg>([^<]*)<\/mesg>/.exec(resp);
      alert(m && m[1] ? m[1] : 'Ground failed');
    }
  }).catch(function(){ alert('Ground failed'); });
}
function gvBody() {
  var body = new URLSearchParams();
  body.append('submitType', '<%=SubmitType.DYNAMIC%>');
  body.append('controller', 'GroundedVehicle');
  body.append('recordID', document.getElementById('gvId').value);
  ['entityID','loginUser','loginUserID','loginUserRoles','loginUserDisplayName'].forEach(function(k){
    var el = document.getElementById(k); if (el) body.append(k, el.value);
  });
  return body;
}
function gvPost(type, extra) {
  var body = gvBody();
  body.append('requestType', type);
  Object.keys(extra || {}).forEach(function(k){ body.append(k, extra[k]); });
  return fetch('../servlet/MVPGServlet', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: body.toString()
  }).then(function(r){ return r.text(); });
}
function gvSave() {
  gvPost('saveFollowup', {
    location: document.getElementById('gvDrLoc').value,
    reason: document.getElementById('gvDrReason').value,
    note: document.getElementById('gvDrNote').value,
    followUpDate: document.getElementById('gvDrFollow').value
  }).then(function(resp){
    if (resp.indexOf('<status>true') >= 0) {
      if (typeof mvpxToast === 'function') mvpxToast('Follow-up saved', true);
      submitPageDataForm('<%=SubmitType.SEARCH%>','GroundedVehicle');
    } else {
      var m = /<mesg>([^<]*)<\/mesg>/.exec(resp);
      alert(m && m[1] ? m[1] : 'Save failed');
    }
  }).catch(function(){ alert('Save failed'); });
}
function gvUnground() {
  var note = (document.getElementById('gvDrNote').value || '').trim();
  if (!note) { alert('Enter what fixed it before ungrounding.'); document.getElementById('gvDrNote').focus(); return; }
  if (!confirm('Return this van to Operational?')) return;
  gvPost('unground', {
    location: document.getElementById('gvDrLoc').value || 'DNK7',
    note: note
  }).then(function(resp){
    if (resp.indexOf('<status>true') >= 0) {
      if (typeof mvpxToast === 'function') mvpxToast('Returned to service', true);
      submitPageDataForm('<%=SubmitType.SEARCH%>','GroundedVehicle');
    } else {
      var m = /<mesg>([^<]*)<\/mesg>/.exec(resp);
      alert(m && m[1] ? m[1] : 'Unground failed');
    }
  }).catch(function(){ alert('Unground failed'); });
}
function gvTimeline(id) {
  var ul = document.getElementById('gvTl');
  ul.innerHTML = '<li class="meta">Loading…</li>';
  gvPost('timeline', {}).then(function(resp){
    var m = /<json>([\s\S]*)<\/json>/.exec(resp);
    ul.innerHTML = '';
    var data = { events: [] };
    if (m) { try { data = JSON.parse(m[1]); } catch (e) {} }
    if (!data.events || !data.events.length) {
      ul.innerHTML = '<li class="meta">No follow-up history yet.</li>';
      return;
    }
    data.events.forEach(function(ev){
      var li = document.createElement('li');
      li.innerHTML = '<div><b>' + (ev.type || '') + '</b> · ' + (ev.loc || '') + (ev.reason ? ' · ' + ev.reason : '') + '</div>'
        + (ev.notes ? '<div>' + ev.notes + '</div>' : '')
        + '<div class="w">' + (ev.when || '') + (ev.by ? ' · ' + ev.by : '') + (ev.days ? ' · ' + ev.days + ' days' : '') + '</div>';
      ul.appendChild(li);
    });
  }).catch(function(){ ul.innerHTML = '<li class="meta">Could not load timeline.</li>'; });
}
</script>
<%@ include file="includeFooter.jsp"%>
