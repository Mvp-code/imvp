<!DOCTYPE html>
<%@ page import="java.util.*, com.util.*, com.beans.*"%>
<jsp:useBean id="_errorBean" class="com.beans.ErrorBean" scope="request" />
<jsp:useBean id="_mainUtil" class="com.util.MainUtil" scope="request" />
<%
int submitType = request.getAttribute("submitType") == null ? SubmitType.CREATE : Integer.parseInt(request.getAttribute("submitType").toString().trim());

/* SEARCH forwards a SearchBean; form views forward a DACheckin bean.
   Capture + remove before useBean so the cast never explodes (SmartUpload pattern). */
SearchBean _searchBean = new SearchBean();
Object _rawBeanObj = request.getAttribute("_recordBean");
if (_rawBeanObj instanceof SearchBean) {
    _searchBean = (SearchBean) _rawBeanObj;
    request.removeAttribute("_recordBean");
}
%>
<jsp:useBean id="_recordBean" class="com.beans.DACheckin" scope="request" />
<%
String _array[][] = null;

/* ═════════════════════════ LIST VIEW (redesigned) ═════════════════════════ */
if (submitType == SubmitType.SEARCH) {

    List dataList = _searchBean.getDataList() == null ? new ArrayList() : _searchBean.getDataList();

    int cntTotal = dataList.size();
    int cntVehicle = 0, cntActive = 0, cntPosted = 0;

    List<String> empNames = new ArrayList<String>();
    List<String> vehNames = new ArrayList<String>();
    List<String> tierNames = new ArrayList<String>();
    List<String> waveTimes = new ArrayList<String>();

    /* row: [0]=id [1]=clockDate [2]=clockTime [3]=empHtml [4]=empClean
             [5]=route [6]=staging [7]=vehHtml [8]=vehClean [9]=prevVeh
             [10]=tierHtml [11]=tierClean [12]=schedTier [13]=parking
             [14]=wave [15]=statusLabel [16]=pillClass */
    List<String[]> rows = new ArrayList<String[]>();

    for (int i = 0; i < dataList.size(); i++) {
        List r = (List) dataList.get(i);
        String id        = r.get(0) == null ? "" : r.get(0).toString().trim();
        String clockDT   = r.get(1) == null ? "" : r.get(1).toString().trim();
        String empHtml   = r.get(2) == null ? "" : r.get(2).toString().trim();
        String route     = r.get(3) == null ? "" : r.get(3).toString().trim();
        String staging   = r.get(4) == null ? "" : r.get(4).toString().trim();
        String vehHtml   = r.get(5) == null ? "" : r.get(5).toString().trim();
        String prevVeh   = r.get(6) == null ? "" : r.get(6).toString().trim();
        String tierHtml  = r.get(7) == null ? "" : r.get(7).toString().trim();
        String schedTier = r.get(8) == null ? "" : r.get(8).toString().trim();
        String parking   = r.get(9) == null ? "" : r.get(9).toString().trim();
        String wave      = r.get(10) == null ? "" : r.get(10).toString().trim();
        String status    = r.get(11) == null ? "" : r.get(11).toString().trim();

        String clockDate = clockDT, clockTime = "";
        if (clockDT.length() > 10) {
            clockDate = clockDT.substring(0, 10);
            clockTime = clockDT.substring(10).trim();
        }

        String empClean  = empHtml.replaceAll("<[^>]+>", "").trim();
        String vehClean  = vehHtml.replaceAll("<[^>]+>", "").trim();
        String tierClean = tierHtml.replaceAll("<[^>]+>", "").trim();
        String typeKey   = schedTier.length() > 0 ? schedTier : tierClean;

        if (empClean.length() > 0 && !empNames.contains(empClean))  empNames.add(empClean);
        if (vehClean.length() > 0 && !vehNames.contains(vehClean))  vehNames.add(vehClean);
        if (typeKey.length() > 0 && !tierNames.contains(typeKey))   tierNames.add(typeKey);
        if (wave.length() > 0 && !waveTimes.contains(wave))         waveTimes.add(wave);

        if (vehClean.length() > 0) cntVehicle++;

        String pillClass = "slate";
        if ("Active".equalsIgnoreCase(status))       { pillClass = "green"; cntActive++; }
        else if (status.toLowerCase().startsWith("post")) { pillClass = "blue"; cntPosted++; }

        rows.add(new String[]{ id, clockDate, clockTime, empHtml, empClean,
            route, staging,
            vehHtml, vehClean, prevVeh, tierHtml, tierClean,
            schedTier, parking, wave, status, pillClass });
    }
    Collections.sort(empNames);
    Collections.sort(vehNames);
    Collections.sort(tierNames);
    Collections.sort(waveTimes);
%>
<%@ include file="includeHeader.jsp"%>
<script src="../jsp/assets/js/mvpx-list.js?v=20260722d"></script>
<style>
:root{--da-blue:#2563EB;--da-blue-dark:#1D4ED8;--da-blue-50:#EFF4FF;--da-blue-100:#DBE6FF;
--da-ink:#0B1220;--da-text:#1F2937;--da-muted:#475569;--da-faint:#64748B;
--da-line:#E4E8F0;--da-line-soft:#EEF1F6;
--da-green:#15803D;--da-green-50:#E7F6EE;--da-red:#C62828;
--da-shadow:0 1px 2px rgba(16,24,40,.04);}
.da-wrap{padding:0 0 8px}
.da-headrow{display:flex;justify-content:space-between;align-items:center;gap:10px;margin-bottom:8px;flex-wrap:wrap}
.da-title{display:flex;align-items:center;gap:12px;flex-wrap:wrap;min-width:0}
.da-headrow h2{margin:0;font-size:20px;font-weight:700;color:#0F172A;letter-spacing:-.02em}
.statchips{display:flex;gap:4px;flex-wrap:wrap}
.statchip{font-size:12px;font-weight:600;color:#475569;background:transparent;border:none;padding:0 8px 0 0;display:inline-flex;gap:5px;align-items:center}
.statchip + .statchip{border-left:1px solid var(--da-line);padding-left:8px}
.statchip b{color:#0F172A;font-weight:700;font-variant-numeric:tabular-nums}
.statchip .dot{width:6px;height:6px;border-radius:50%;flex-shrink:0}
.da-actions{display:flex;gap:6px;align-items:center;flex-wrap:wrap}
.da-sep{width:1px;height:22px;background:var(--da-line);margin:0 2px;display:inline-block;flex-shrink:0}
.tablewrap{background:#fff;border:1px solid var(--da-line);border-radius:10px;overflow:hidden;box-shadow:var(--da-shadow)}
.da-toolbar{display:flex;align-items:center;gap:6px;flex-wrap:wrap;padding:8px 10px;border-bottom:1px solid var(--da-line-soft);background:#FAFBFC}
.daterange-fld{display:inline-flex;align-items:center;gap:4px;border:1px solid var(--da-line);border-radius:7px;padding:3px 8px;background:#fff}
.daterange-fld input[type=date]{border:none;font-size:12.5px;padding:2px 1px;font-family:inherit;color:var(--da-text);background:transparent;max-width:118px}
.daterange-fld input[type=date]:focus{outline:none}
.daterange-fld .dash{color:var(--da-faint);font-size:12px}
.da-quick{display:inline-flex;gap:3px}
.da-quick button{border:1px solid var(--da-line);background:#fff;color:var(--da-muted);border-radius:6px;padding:5px 9px;font-size:12px;font-weight:600;cursor:pointer}
.da-quick button.on{background:var(--da-blue-50);border-color:var(--da-blue-100);color:var(--da-blue-dark)}
.da-flt{border:1px solid var(--da-line);border-radius:7px;padding:5px 8px;font-size:12.5px;background:#fff;cursor:pointer;max-width:160px}
.da-flt:focus{outline:none;border-color:var(--da-blue);box-shadow:0 0 0 3px var(--da-blue-50)}
.da-chips{display:flex;gap:6px;flex-wrap:wrap;padding:0 10px;min-height:0}
.da-chips:not(:empty){padding-top:6px}
.da-chip{background:var(--da-blue-50);border:1px solid var(--da-blue-100);color:var(--da-blue-dark);border-radius:999px;padding:3px 7px 3px 9px;font-size:12px;font-weight:700;display:inline-flex;align-items:center;gap:5px}
.da-chip .x{cursor:pointer;border:none;background:transparent;color:var(--da-blue-dark);font-size:12px;line-height:1;padding:0 2px}
.tablewrap table{width:100%;border-collapse:collapse}
.tablewrap thead th{text-align:left;font-size:11.5px;color:#64748B;font-weight:700;text-transform:uppercase;letter-spacing:.03em;padding:8px 10px;background:#fff;border-bottom:1px solid var(--da-line);white-space:nowrap}
.tablewrap thead th.srt{cursor:pointer;user-select:none}
.tablewrap thead th.srt:hover{color:#0F172A;background:#F8FAFC}
.tablewrap thead th .ar{color:var(--da-blue);font-size:10px;font-weight:800;margin-left:3px}
.tablewrap tbody td{padding:7px 10px;border-bottom:1px solid var(--da-line-soft);font-size:13.5px;font-weight:400;color:#111827;vertical-align:middle}
.tablewrap tbody tr:last-child td{border-bottom:none}
.tablewrap tbody tr:hover{background:#F8FAFC}
.nm{font-weight:650;color:#0F172A}.meta{font-size:12px;color:#64748B}
.pill{display:inline-flex;align-items:center;gap:5px;padding:2px 8px;border-radius:999px;font-size:11.5px;font-weight:700}
.pill .d{width:5px;height:5px;border-radius:50%;flex-shrink:0}
.pill.green{background:var(--da-green-50);color:#15803D}.pill.green .d{background:var(--da-green)}
.pill.blue{background:var(--da-blue-50);color:var(--da-blue-dark)}.pill.blue .d{background:var(--da-blue)}
.pill.slate{background:#F1F5F9;color:#475569}.pill.slate .d{background:#64748B}
.tablefoot{display:flex;justify-content:space-between;align-items:center;padding:7px 10px;border-top:1px solid var(--da-line-soft);font-size:12.5px;color:var(--da-muted);gap:8px;flex-wrap:wrap;background:#FAFBFC}
.btn2{border:1px solid var(--da-line);background:#fff;color:#111827;padding:6px 11px;border-radius:7px;font-size:12.5px;font-weight:600;cursor:pointer;display:inline-flex;align-items:center;gap:5px;white-space:nowrap}
.btn2:hover{background:#F1F5F9}
.btn2.primary{background:var(--da-blue);border-color:var(--da-blue);color:#fff}.btn2.primary:hover{background:var(--da-blue-dark)}
.btn2.success{background:var(--da-green);border-color:var(--da-green);color:#fff}.btn2.success:hover{background:#166534}
.btn2.danger{background:#fff;border-color:#FECACA;color:#B91C1C}.btn2.danger:hover{background:#FEF2F2}
.btn2.sm{padding:4px 8px;font-size:12px}
.da-toast{position:fixed;bottom:24px;right:24px;background:#0B1220;color:#fff;padding:10px 16px;border-radius:10px;font-size:13px;font-weight:600;z-index:9999;opacity:0;transform:translateY(8px);transition:opacity .25s,transform .25s;pointer-events:none}
.da-toast.show{opacity:1;transform:translateY(0)}
.da-empty{text-align:center;color:var(--da-faint);padding:32px;font-size:14px}
.qa-toggle{margin-left:auto}
tr.qa-row td{background:#F8FDF9 !important;border-bottom:1px solid #D1FAE5;padding:5px 8px}
tr.qa-row select,tr.qa-row input{border:1px solid #A7F3D0;border-radius:6px;padding:5px 7px;font-size:12px;font-family:inherit;background:#fff;width:100%;min-width:90px}
tr.qa-row select:focus,tr.qa-row input:focus{outline:none;border-color:#16a34a;box-shadow:0 0 0 3px #DCFCE7}
.qa-save{background:#16a34a;color:#fff;border:none;border-radius:6px;padding:5px 10px;font-size:12px;font-weight:700;cursor:pointer;white-space:nowrap}
.qa-save:disabled{opacity:.6}
.qa-x{background:none;border:none;color:#94A3B8;cursor:pointer;font-size:14px;padding:2px 6px}
#qaRows:empty{display:none}
</style>

<div class="da-wrap">
  <div class="da-headrow">
    <div class="da-title">
      <h2>DA Checkins</h2>
      <div class="statchips">
        <span class="statchip"><span class="dot" style="background:var(--da-blue)"></span><b id="cnt-total"><%=cntTotal%></b> in</span>
        <span class="statchip"><span class="dot" style="background:var(--da-green)"></span><b id="cnt-vehicle"><%=cntVehicle%></b> vehicles</span>
        <span class="statchip"><span class="dot" style="background:#64748B"></span><b id="cnt-posted"><%=cntPosted%></b> posted</span>
      </div>
    </div>
    <div class="da-actions">
      <button type="button" class="btn2" onclick="doSwap()" title="Swap vehicles between selected"><i class="fas fa-random"></i> Swap</button>
      <button type="button" class="btn2" onclick="doRun('NewRun','assign vehicles for TODAY')" title="Assign vehicles for today"><i class="fas fa-truck"></i> Assign &middot; Today</button>
      <button type="button" class="btn2" onclick="doRun('NewNext Day Run','assign vehicles for TOMORROW')" title="Assign vehicles for tomorrow"><i class="fas fa-angle-double-right"></i> Assign &middot; Tomorrow</button>
      <span class="da-sep"></span>
      <button type="button" class="btn2" onclick="doPrint('xls')" title="Export to Excel"><i class="fas fa-file-excel"></i> Excel</button>
      <%if(_searchBean.isDisplayPrintBtn()){%>
      <button type="button" class="btn2" onclick="doPrint('')" title="Download PDF"><i class="fas fa-file-pdf"></i> PDF</button>
      <%}%>
      <%if(_searchBean.isDisplayViewBtn()){%>
      <button type="button" class="btn2" onclick="doPrint('view')" title="View report"><i class="fas fa-eye"></i> View</button>
      <%}%>
      <span class="da-sep"></span>
      <%if(_searchBean.isDisplayPostBtn()){%>
      <button class="btn2 success" onclick="doBulk(<%=SubmitType.FINAL%>,'post')" title="Post selected"><i class="fas fa-check"></i> Post</button>
      <%}%>
      <button class="btn2 danger" onclick="doBulk(<%=SubmitType.DELETE%>,'delete')" title="Delete selected"><i class="fas fa-trash"></i> Delete</button>
      <button class="btn2 primary" onclick="submitPageDataForm('<%=SubmitType.CREATE%>','<%=_searchBean.getController()%>');">&#xFF0B; New</button>
    </div>
  </div>

  <%if(_errorBean != null && _errorBean.getType().length() > 0){%>
  <div class="row text-center mt-2">
    <section class="alert_section">
      <div class="alert-box <%=_errorBean.getType()%>Color"><%=_errorBean.getMesg()%></div>
    </section>
  </div>
  <%}%>

  <div class="tablewrap">
    <div class="da-toolbar">
      <div class="da-quick">
        <button id="btnToday" onclick="quickDate('today')">Today</button>
        <button id="btnTomorrow" onclick="quickDate('tomorrow')">Tomorrow</button>
      </div>
      <div class="daterange-fld">
        <input type="date" id="filterFrom" data-mdy="<%=_searchBean.getSrhFromDate()%>" onchange="dateSearch()">
        <span class="dash">&ndash;</span>
        <input type="date" id="filterTo" data-mdy="<%=_searchBean.getSrhToDate()%>" onchange="dateSearch()">
      </div>
      <select class="da-flt" id="filterEmp" onchange="applyFilters()" style="min-width:140px">
        <option value="">All employees</option>
        <%for(String v : empNames){%><option value="<%=v.toLowerCase()%>"><%=v%></option><%}%>
      </select>
      <select class="da-flt" id="filterVeh" onchange="applyFilters()">
        <option value="">All vehicles</option>
        <%for(String v : vehNames){%><option value="<%=v.toLowerCase()%>"><%=v%></option><%}%>
      </select>
      <select class="da-flt" id="filterTier" onchange="applyFilters()">
        <option value="">All service types</option>
        <%for(String v : tierNames){%><option value="<%=v.toLowerCase()%>"><%=v%></option><%}%>
      </select>
      <select class="da-flt" id="filterWave" onchange="applyFilters()">
        <option value="">All waves</option>
        <%for(String v : waveTimes){%><option value="<%=v.toLowerCase()%>"><%=v%></option><%}%>
      </select>
      <select class="da-flt" id="filterStatus" onchange="applyFilters()">
        <option value="">Active &amp; Posted</option>
        <option value="active">Active</option>
        <option value="post">Posted</option>
      </select>
      <button type="button" class="btn2 sm qa-toggle" onclick="addQuickRow()" title="Quick-add a check-in row"><i class="fas fa-bolt"></i> Quick add</button>
    </div>
    <div class="da-chips" id="activeChips"></div>
    <table>
      <thead>
        <tr>
          <th style="width:32px"><input type="checkbox" id="selectAll" onchange="toggleSelectAll(this)"></th>
          <th class="srt" onclick="mvpxSort(this)">Clockin Time<span class="ar"></span></th>
          <th class="srt" onclick="mvpxSort(this)">Employee<span class="ar"></span></th>
          <th class="srt" onclick="mvpxSort(this)">Route<span class="ar"></span></th>
          <th class="srt" onclick="mvpxSort(this)">Staging<span class="ar"></span></th>
          <th class="srt" onclick="mvpxSort(this)">Vehicle<span class="ar"></span></th>
          <th class="srt" onclick="mvpxSort(this)">Prev Vehicle<span class="ar"></span></th>
          <th class="srt" onclick="mvpxSort(this)">Service Tier<span class="ar"></span></th>
          <th class="srt" onclick="mvpxSort(this)">Sch Service Tier<span class="ar"></span></th>
          <th class="srt" onclick="mvpxSort(this)">Parking<span class="ar"></span></th>
          <th class="srt" onclick="mvpxSort(this)">Wave Time<span class="ar"></span></th>
          <th class="srt" onclick="mvpxSort(this)">Status<span class="ar"></span></th>
        </tr>
      </thead>
      <tbody id="qaRows"></tbody>
      <tbody id="ciRows">
        <%if(rows.isEmpty()){%>
        <tr><td colspan="12" class="da-empty">No check-ins for this date range.</td></tr>
        <%}%>
        <%for(String[] r : rows){%>
        <tr data-id="<%=r[0]%>"
            data-emp="<%=r[4].toLowerCase()%>"
            data-veh="<%=r[8].toLowerCase()%>"
            data-tier="<%=(r[12].length()>0?r[12]:r[11]).toLowerCase()%>"
            data-wave="<%=r[14].toLowerCase()%>"
            data-st="<%=r[15].toLowerCase()%>">
          <td><input type="checkbox" class="rowCheck" value="<%=r[0]%>" data-status="<%=r[15]%>"></td>
          <td><%=r[1]%><div class="meta"><%=r[2]%></div></td>
          <td class="nm"><a href="javascript:void(0)" style="color:inherit" onclick="submitPageDataForm('<%=SubmitType.BROWSE%>','<%=_searchBean.getController()%>','<%=r[0]%>')"><%=r[3]%></a></td>
          <td class="nm"><%=r[5].length()>0?r[5]:"&mdash;"%></td>
          <td class="meta"><%=r[6].length()>0?r[6]:"&mdash;"%></td>
          <td><%=r[7].length()>0?r[7]:"&mdash;"%></td>
          <td class="meta"><%=r[9].length()>0?r[9]:"&mdash;"%></td>
          <td class="meta"><%=r[10].length()>0?r[10]:"&mdash;"%></td>
          <td class="meta"><%=r[12].length()>0?r[12]:"&mdash;"%></td>
          <td class="meta"><%=r[13].length()>0?r[13]:"&mdash;"%></td>
          <td><%=r[14].length()>0?r[14]:"&mdash;"%></td>
          <td><span class="pill <%=r[16]%>"><span class="d"></span><%=r[15]%></span></td>
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

<script>
var _ctrl  = '<%=_searchBean.getController()%>';
var _stDyn = <%=SubmitType.DYNAMIC%>;
var _srhFrom = '<%=_searchBean.getSrhFromDate()%>';
var _srhTo   = '<%=_searchBean.getSrhToDate()%>';

function toast(msg, ok) {
  var t = document.getElementById('daToast');
  t.textContent = msg;
  t.style.background = ok === false ? '#B91C1C' : '#0B1220';
  t.classList.add('show');
  setTimeout(function(){ t.classList.remove('show'); }, 3200);
}

function ajaxPost(params, cb) {
  var body = new URLSearchParams();
  body.append('submitType', _stDyn);
  body.append('controller', _ctrl);
  ['entityID','loginUser','loginUserID','loginUserRoles','loginUserDisplayName'].forEach(function(k){
    var el = document.getElementById(k); if (el) body.append(k, el.value);
  });
  for (var k in params) body.append(k, params[k]);
  fetch('MVPGServlet', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: body.toString()
  }).then(function(r){ return r.text(); })
    .then(function(txt){ cb(txt); })
    .catch(function(){ cb(''); });
}

/* ---- client-side filters (auto, no Search button) ---- */
var _st = { emp:'', veh:'', tier:'', wave:'', status:'' };
function applyFilters() {
  _st.emp    = (document.getElementById('filterEmp').value || '').toLowerCase();
  _st.veh    = (document.getElementById('filterVeh').value || '').toLowerCase();
  _st.tier   = (document.getElementById('filterTier').value || '').toLowerCase();
  _st.wave   = (document.getElementById('filterWave').value || '').toLowerCase();
  _st.status = (document.getElementById('filterStatus').value || '').toLowerCase();
  var rows = document.querySelectorAll('#ciRows tr[data-id]');
  var shown = 0, veh = 0, posted = 0;
  rows.forEach(function(r) {
    var vis = (!_st.emp    || (r.dataset.emp||'').indexOf(_st.emp) >= 0)
           && (!_st.veh    || (r.dataset.veh||'') === _st.veh)
           && (!_st.tier   || (r.dataset.tier||'') === _st.tier)
           && (!_st.wave   || (r.dataset.wave||'') === _st.wave)
           && (!_st.status || (r.dataset.st||'').indexOf(_st.status) >= 0);
    r.classList.toggle('mvpx-flt-out', !vis);
    if (vis) {
      shown++;
      if ((r.dataset.veh||'').length > 0) veh++;
      if ((r.dataset.st||'').indexOf('post') >= 0) posted++;
    }
  });
  if (window.mvpxPagerReset) mvpxPagerReset(); /* pager owns #showCount = "Rows X–Y of Z" */
  document.getElementById('cnt-total').textContent = shown;
  document.getElementById('cnt-vehicle').textContent = veh;
  document.getElementById('cnt-posted').textContent = posted;
  renderChips();
}
function renderChips() {
  var c = document.getElementById('activeChips'); c.innerHTML = '';
  var defs = [['emp','Employee','filterEmp'],['veh','Vehicle','filterVeh'],['tier','Type','filterTier'],['wave','Wave','filterWave'],['status','Status','filterStatus']];
  defs.forEach(function(d){
    if (_st[d[0]]) {
      var sel = document.getElementById(d[2]);
      var lbl = sel.options[sel.selectedIndex] ? sel.options[sel.selectedIndex].text : _st[d[0]];
      c.innerHTML += '<span class="da-chip">' + d[1] + ': <b>' + lbl + '</b>'
                   + '<button class="x" onclick="clearFilter(\'' + d[2] + '\')">&times;</button></span>';
    }
  });
}
function clearFilter(id){ document.getElementById(id).value=''; applyFilters(); }

/* ---- click-to-sort headers ---- */
function _cellText(tr, idx){
  var td = tr.children[idx];
  return td ? (td.textContent || '').replace(/\s+/g,' ').trim() : '';
}
function mvpxSort(th){
  var head = th.parentNode;
  var idx  = Array.prototype.indexOf.call(head.children, th);
  var asc  = th.getAttribute('data-dir') !== 'asc';
  /* reset the other headers' arrows */
  head.querySelectorAll('th').forEach(function(o){
    if (o !== th){ o.removeAttribute('data-dir'); var a=o.querySelector('.ar'); if(a) a.textContent=''; }
  });
  th.setAttribute('data-dir', asc ? 'asc' : 'desc');
  var ar = th.querySelector('.ar'); if (ar) ar.textContent = asc ? '▲' : '▼';

  var tb   = document.getElementById('ciRows');
  var rows = Array.prototype.slice.call(tb.querySelectorAll('tr[data-id]'));
  rows.sort(function(a, b){
    var x = _cellText(a, idx), y = _cellText(b, idx);
    var nx = parseFloat(x.replace(/[^0-9.\-]/g,'')), ny = parseFloat(y.replace(/[^0-9.\-]/g,''));
    var num = /\d/.test(x) && /\d/.test(y) && !isNaN(nx) && !isNaN(ny)
              && x.replace(/[0-9.\-\s:\/]/g,'') === '' && y.replace(/[0-9.\-\s:\/]/g,'') === '';
    var cmp = num ? (nx - ny) : x.toLowerCase().localeCompare(y.toLowerCase());
    if (cmp === 0) return 0;
    return asc ? cmp : -cmp;
  });
  rows.forEach(function(r){ tb.appendChild(r); }); /* re-order in place; filters/pager unaffected */
  if (window.mvpxPagerReset) mvpxPagerReset();
  else if (window.mvpxPagerRender) mvpxPagerRender(true);
}

/* ---- dates (server round trip) ---- */
function _pad(n){ return (n < 10 ? '0' : '') + n; }
function toMDY(iso){ if(!iso) return ''; var p = iso.split('-'); return p.length===3 ? (p[1]+'/'+p[2]+'/'+p[0]) : ''; }
function mdyToISO(mdy){ if(!mdy) return ''; var p = mdy.split('/'); return p.length===3 ? (p[2]+'-'+_pad(parseInt(p[0],10))+'-'+_pad(parseInt(p[1],10))) : ''; }
function goSearch(fromMDY, toMDY_){
  var extra = '&srhFromDate=' + encodeURIComponent(fromMDY)
            + '&srhToDate='   + encodeURIComponent(toMDY_)
            + '&searchFilter=yes';
  submitPageDataForm('<%=SubmitType.SEARCH%>', _ctrl, '', '', extra);
}
function dateSearch(){
  goSearch(toMDY(document.getElementById('filterFrom').value),
           toMDY(document.getElementById('filterTo').value));
}
function quickDate(which){
  var d = new Date();
  if (which === 'tomorrow') d.setDate(d.getDate() + 1);
  var mdy = _pad(d.getMonth()+1) + '/' + _pad(d.getDate()) + '/' + d.getFullYear();
  goSearch(mdy, mdy);
}
(function(){
  var f = document.getElementById('filterFrom'), t = document.getElementById('filterTo');
  if (f) f.value = mdyToISO((f.dataset.mdy||'').trim());
  if (t) t.value = mdyToISO((t.dataset.mdy||'').trim());
  /* light up Today/Tomorrow chip if range matches */
  var d = new Date(), mdyT = _pad(d.getMonth()+1)+'/'+_pad(d.getDate())+'/'+d.getFullYear();
  d.setDate(d.getDate()+1);
  var mdyN = _pad(d.getMonth()+1)+'/'+_pad(d.getDate())+'/'+d.getFullYear();
  if (_srhFrom === mdyT && _srhTo === mdyT) document.getElementById('btnToday').classList.add('on');
  if (_srhFrom === mdyN && _srhTo === mdyN) document.getElementById('btnTomorrow').classList.add('on');
})();

function toggleSelectAll(cb) {
  /* covers every filter-matching row; the pager only manages the viewport */
  document.querySelectorAll('#ciRows .rowCheck').forEach(function(c){
    if (!c.closest('tr').classList.contains('mvpx-flt-out')) c.checked = cb.checked;
  });
}
function selectedIDs(){
  return Array.from(document.querySelectorAll('#ciRows .rowCheck:checked')).map(function(c){ return c.value; });
}

/* ---- bulk actions (legacy submit flows, preserved) ---- */
function doBulk(st, verb){
  var ids = selectedIDs();
  if (ids.length === 0) { toast('Select at least one row to ' + verb, false); return; }
  if (!window.confirm('Are you sure you want to ' + verb + ' ' + ids.length + ' check-in(s)?')) return;
  document.formmain.action = '../servlet/MVPGServlet?submitType=<%=SubmitType.SEARCH%>&controller=' + _ctrl
    + '&searchFilter=yes&srhFromDate=' + encodeURIComponent(_srhFrom) + '&srhToDate=' + encodeURIComponent(_srhTo)
    + '&selectedType=' + st + '&selectedValues=' + ids.join(',');
  document.formmain.submit();
}
function doSwap(){
  var ids = selectedIDs();
  if (ids.length < 2) { toast('Select 2 or more employees to swap vehicles', false); return; }
  document.formmain.action = '../servlet/MVPGServlet?submitType=<%=SubmitType.SEARCH%>&controller=' + _ctrl
    + '&searchFilter=yes&srhFromDate=' + encodeURIComponent(_srhFrom) + '&srhToDate=' + encodeURIComponent(_srhTo)
    + '&selectedType=<%=SubmitType.UPDATE%>&selectedValues=' + ids.join(',');
  document.formmain.submit();
}
function doRun(type, verb){
  if (!window.confirm('Load the schedule and ' + verb + '?')) return;
  /* land on the day being assigned: Today for NewRun, Tomorrow for NewNext Day Run */
  var d = new Date();
  if (type.indexOf('Next') >= 0) d.setDate(d.getDate() + 1);
  var mdy = _pad(d.getMonth()+1) + '/' + _pad(d.getDate()) + '/' + d.getFullYear();
  document.formmain.action = '../servlet/MVPGServlet?submitType=<%=SubmitType.SEARCH%>&controller=' + _ctrl
    + '&searchFilter=yes&srhFromDate=' + encodeURIComponent(mdy) + '&srhToDate=' + encodeURIComponent(mdy)
    + '&selectedType=<%=SubmitType.UPDATE%>&selectedValues=' + encodeURIComponent(type);
  document.formmain.submit();
}
function doPrint(pt){
  /* requestType must be non-empty or MVPGCtrl.printRecord skips the report;
     selectedType=PRINT picks the DAO's print columns (else it renders the
     list rows, HTML markup and all) */
  window.open('../servlet/MVPGServlet?submitType=<%=SubmitType.PRINT%>&controller=' + _ctrl
    + '&printType=' + pt + '&requestType=print&selectedType=<%=SubmitType.PRINT%>'
    + '&searchFilter=yes&srhFromDate=' + encodeURIComponent(_srhFrom)
    + '&srhToDate=' + encodeURIComponent(_srhTo) + getPageSubmitFormValues(true));
}

/* ---- quick add rows ---- */
var _qaSeq = 0;
var _empOptions = null;

function addQuickRow(){
  var seq = ++_qaSeq;
  var tb = document.getElementById('qaRows');
  var tr = document.createElement('tr');
  tr.className = 'qa-row';
  tr.id = 'qa' + seq;
  tr.innerHTML =
    '<td><i class="fas fa-plus-circle" style="color:#16a34a"></i></td>' +
    '<td><input type="time" id="qaTime' + seq + '" value="10:55" style="min-width:105px"></td>' +
    '<td><select id="qaEmp' + seq + '" onchange="qaLoadVehicles(' + seq + ')"><option value="">Loading&hellip;</option></select></td>' +
    '<td class="meta">&mdash;</td>' +
    '<td class="meta">&mdash;</td>' +
    '<td><select id="qaVeh' + seq + '"><option value="">Pick employee first</option></select></td>' +
    '<td class="meta">&mdash;</td>' +
    '<td class="meta">&mdash;</td>' +
    '<td class="meta">&mdash;</td>' +
    '<td><select id="qaPark' + seq + '">' +
      '<option value=""></option>' +
      <%_array = _mainUtil.getDataArray(_mainUtil.getParking());
        StringBuffer _parkOpts = new StringBuffer();
        for(int k=0; k<_array.length; k++)
            _parkOpts.append("<option value=\\'"+_array[k][0]+"\\'>"+_array[k][1]+"</option>");%>
      '<%=_parkOpts.toString()%>' +
    '</select></td>' +
    '<td><select id="qaWave' + seq + '" style="min-width:60px"><option value="1">1</option><option value="2">2</option></select></td>' +
    '<td style="white-space:nowrap"><button class="qa-save" id="qaSave' + seq + '" onclick="qaSave(' + seq + ')">Save</button> ' +
    '<button class="qa-x" onclick="document.getElementById(\'qa' + seq + '\').remove()" title="Remove row">&#10005;</button></td>';
  tb.appendChild(tr);
  qaFillEmployees(seq);
}

function qaFillEmployees(seq){
  var sel = document.getElementById('qaEmp' + seq);
  if (_empOptions !== null) { sel.innerHTML = '<option value="">Select employee&hellip;</option>' + _empOptions; return; }
  var xhr = new XMLHttpRequest();
  xhr.open('POST', '../servlet/MVPGServlet', true);
  xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
  xhr.onload = function(){
    _empOptions = xhr.responseText || '';
    sel.innerHTML = '<option value="">Select employee&hellip;</option>' + _empOptions;
  };
  xhr.send('submitType=10&controller=Incident&requestType=suggestor&suggestorType=employees&suggestorValue=' + getEntityParams());
}

function qaLoadVehicles(seq){
  var emp = document.getElementById('qaEmp' + seq).value;
  var vSel = document.getElementById('qaVeh' + seq);
  if (!emp) { vSel.innerHTML = '<option value="">Pick employee first</option>'; return; }
  vSel.innerHTML = '<option value="">Loading&hellip;</option>';
  var dos = toMDY(document.getElementById('filterFrom').value) || _srhFrom;
  var wave = document.getElementById('qaWave' + seq).value || '1';
  var xhr = new XMLHttpRequest();
  xhr.open('POST', '../servlet/MVPGServlet', true);
  xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
  xhr.onload = function(){
    var opts = xhr.responseText || '';
    vSel.innerHTML = opts.length > 0 ? opts : '<option value="">No vehicles available</option>';
  };
  xhr.send('submitType=10&controller=DACheckin&requestType=employeeVehicleAvail&employeeID=' + encodeURIComponent(emp)
    + '&dos=' + encodeURIComponent(dos) + '&wave=' + wave + '&vehicleID=' + getEntityParams());
}

function qaSave(seq){
  var emp  = document.getElementById('qaEmp' + seq).value;
  var veh  = document.getElementById('qaVeh' + seq).value;
  var park = document.getElementById('qaPark' + seq).value;
  var time = document.getElementById('qaTime' + seq).value;
  var wave = document.getElementById('qaWave' + seq).value;
  if (!emp)  { toast('Pick an employee', false); return; }
  if (!veh)  { toast('Pick a vehicle', false); return; }
  if (!park) { toast('Pick parking', false); return; }
  if (!time) { toast('Set the clock-in time', false); return; }
  /* 24h -> "hh:mm AM/PM" */
  var hm = time.split(':'), h = parseInt(hm[0],10), ap = h >= 12 ? 'PM' : 'AM';
  h = h % 12; if (h === 0) h = 12;
  var time12 = _pad(h) + ':' + hm[1] + ' ' + ap;
  var dos = toMDY(document.getElementById('filterFrom').value) || _srhFrom;
  var btn = document.getElementById('qaSave' + seq);
  btn.disabled = true; btn.textContent = 'Saving…';
  ajaxPost({ requestType:'quickAdd', clockinDate: dos, clockinTime: time12,
             employeeID: emp, vehicleID: veh, parking: park, wave: wave }, function(resp){
    if (resp.indexOf('<status>true') >= 0) {
      toast('Check-in added ✓', true);
      setTimeout(function(){ goSearch(_srhFrom, _srhTo); }, 700);
    } else {
      var m = /<mesg>([^<]*)<\/mesg>/.exec(resp);
      toast(m && m[1] ? m[1] : 'Save failed', false);
      btn.disabled = false; btn.textContent = 'Save';
    }
  });
}

/* Quick-add stays collapsed until "Quick add" is clicked — more rows visible. */

/* REV C: viewport lock + auto-fit pager (shared engine).
   Quick-add rows change the available height, so re-measure after add/remove. */
mvpxFitStart();
(function(){
  var qa = document.getElementById('qaRows');
  if (qa && window.MutationObserver)
    new MutationObserver(function(){ if (window.mvpxPagerRender) mvpxPagerRender(true); })
      .observe(qa, { childList: true, subtree: true });
})();
</script>

<%
/* ═════════════════════ RECORD FORM VIEWS (unchanged) ═════════════════════ */
} else {
%>
<script>
function validatePageData(submitType, isValid) {

	if(submitType == <%=SubmitType.CREATE_CONFIRM%> || submitType == <%=SubmitType.UPDATE_CONFIRM%>) {
		if(isValid) {
			var mandatoryFieldsArray = new Array();
			mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["clockinDate"], "Clockin Date");
			mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["clockinTimeTxt"], "Clockin Time");
			mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["employeeID"], "Employee");
			mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["vehicleID"], "Vehicle");
			mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["parking"], "Parking");
			if(document.formmain["gasCard"] && document.formmain["gasCard"].value == "1") {
				mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["gasCardID"], "Card ID");
			}
			isValid = validateMandatoryFieldsInForm(mandatoryFieldsArray, isValid);
		}

	} else if(submitType == <%=SubmitType.DELETE%>) {
		isValid = deleteRecord();

	} else if(submitType == <%=SubmitType.WITH_HOLD%>) {
		isValid = unpostRecord();
	}

	return isValid;
}

var vehicleID = "<%=_recordBean.getVehicleID()%>";
function loadVehicles(thisObj) {
	if(thisObj.value.length > 0) {
		var appQry = "&employeeID="+document.formmain["employeeID"].value+"&dos="+document.formmain["clockinDate"].value+"&wave="+document.formmain["wave"].value+"&vehicleID="+vehicleID;
		var xmlHttpRequest = setSynXMLHttpOb("../servlet/MVPGServlet");
		var str = "submitType=10&controller=DACheckin&requestType=employeeVehicleAvail"+appQry+getEntityParams();
		xmlHttpRequest.send(str);
		var suggestorTxt = xmlHttpRequest.responseText;
		if(suggestorTxt.length == 0)
			suggestorTxt = "<option value='' selected>N/A</option>";
		initSelect2SuggestorSetData("vehicleID", suggestorTxt);
		vehicleID = "";
	} else {
		initSelect2SuggestorSetData("vehicleID", null);
	}
}
</script>

<%@ include file="includeHeader.jsp"%>
<link rel="stylesheet" href="../jsp/assets/css/mvpx-list.css?v=20260722d">
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
			<%if(submitType == SubmitType.CREATE || submitType == SubmitType.UPDATE) {
				String clockinTime = _recordBean.getClockinTime();
				String clockinTimeSel = "";
				if(clockinTime.length() > 0) {
					String splitArray[] = clockinTime.split(" ");
					clockinTime = "";
					if(splitArray.length == 2) {
						clockinTime = splitArray[0].trim();
						clockinTimeSel = splitArray[1].trim();
					}
				}
				%>
				<script>
				function checkStatus(thisObj, divID) {
					enableOrDisableID(divID, "");
					if(thisObj.value == "0") {
						enableOrDisableID(divID, "none");
						document.formmain["gasCardID"].value = "";
					}
				}
				</script>

				<input type="hidden" id="daCheckinID" name="daCheckinID" value="<%=_recordBean.getDaCheckinID()%>">
				<input type="hidden" id="clockinTime" name="clockinTime" value="<%=_recordBean.getClockinTime()%>">

				<%-- Single-row entry table — identical look to the list quick-add --%>
				<div class="tablewrap" style="border:none;box-shadow:none;margin-top:0">
					<table>
						<thead>
							<tr>
								<th style="min-width:215px">Clockin Time<span style="color:#DC2626"> *</span></th>
								<th style="min-width:180px">Employee<span style="color:#DC2626"> *</span></th>
								<th style="min-width:160px">Vehicle<span style="color:#DC2626"> *</span></th>
								<th>CDV<br>Verified<span style="color:#DC2626"> *</span></th>
								<th>Wave</th>
								<th style="min-width:110px">Parking<span style="color:#DC2626"> *</span></th>
								<th>ISPhone &amp;<br>Cables<span style="color:#DC2626"> *</span></th>
								<th style="min-width:140px">Gas Card<span style="color:#DC2626"> *</span></th>
								<th style="min-width:150px">DA Remarks</th>
								<th style="min-width:150px">Dispatch Remarks</th>
							</tr>
						</thead>
						<tbody>
							<tr class="qa-row">
								<td>
									<div style="display:flex;gap:5px;flex-wrap:nowrap">
										<input type="text" id="clockinDate" name="clockinDate" class="datepicker" value="<%=_recordBean.getClockinDate()%>" placeholder="Date" style="width:95px;flex:none">
										<input type="text" id="clockinTimeTxt" name="clockinTimeTxt" value="<%=clockinTime%>" placeholder="hh:mm" style="width:60px;flex:none" onChange="fixTime('clockinTime');">
										<select id="clockinTimeSel" name="clockinTimeSel" style="width:58px;flex:none;min-width:0" onChange="fixTime('clockinTime');"><option value="AM" <%if("AM".equalsIgnoreCase(clockinTimeSel)) {%>selected<%}%>>AM</option><option value="PM" <%if("PM".equalsIgnoreCase(clockinTimeSel)) {%>selected<%}%>>PM</option></select>
									</div>
								</td>
								<td><select id="employeeID" name="employeeID" onChange="loadVehicles(this);"></select></td>
								<td><select id="vehicleID" name="vehicleID"></select></td>
								<td><select id="cdvCertified" name="cdvCertified" style="min-width:64px"><option value="1">Yes</option><option value="0">No</option></select></td>
								<td><select id="wave" name="wave" style="min-width:52px"><option value="1">1</option><option value="2">2</option></select></td>
								<td><select id="parking" name="parking"><option value=""></option><%_array = _mainUtil.getDataArray(_mainUtil.getParking());for(int k=0; k<_array.length; k++) {%><option value="<%=_array[k][0]%>"><%=_array[k][1]%></option><%}%></select></td>
								<td><select id="phoneCable" name="phoneCable" style="min-width:64px"><option value="1">Yes</option><option value="0">No</option></select></td>
								<td>
									<select id="gasCard" name="gasCard" style="min-width:64px" onChange="Javascript:checkStatus(this,'gasCardDivID');"><option value="1">Yes</option><option value="0">No</option></select>
									<div id="gasCardDivID" style="margin-top:6px;<%if("0".equalsIgnoreCase(_recordBean.getGasCard())) {%>display:none;<%}%>">
										<select id="gasCardID" name="gasCardID">
											<option value=""></option>
											<%for(int i=0; i<_recordBean.getGasCardList().size(); i++) {
											List tempList = (ArrayList) _recordBean.getGasCardList().get(i);
											%><option value="<%=tempList.get(0).toString()%>" <%if(_recordBean.getGasCardID().equalsIgnoreCase(tempList.get(0).toString())) {%>selected<%}%>><%=tempList.get(1).toString()%></option><%}%>
										</select>
									</div>
								</td>
								<td><textarea id="daComments" name="daComments" rows="2" placeholder="Optional&hellip;"><%=_recordBean.getDaComments()%></textarea></td>
								<td><textarea id="dispatchComments" name="dispatchComments" rows="2" placeholder="Optional&hellip;"><%=_recordBean.getDispatchComments()%></textarea></td>
							</tr>
						</tbody>
					</table>
				</div>

				<script>
					initSelect2Suggestor("employees", "employeeID", "<%=_recordBean.getEmployeeID()%>", false, "");
					initSelect2SuggestorConvert("vehicleID");
					initSelect2SuggestorConvert("gasCardID", "Card ID");
					(function(){
						function setSel(n, v){ if (v && document.formmain[n]) setSelectBoxValue(document.formmain[n], v); }
						setSel("cdvCertified", "<%=_recordBean.getCdvCertified()%>");
						setSel("wave",         "<%=_recordBean.getWave()%>");
						setSel("parking",      "<%=_recordBean.getParking()%>");
						setSel("phoneCable",   "<%=_recordBean.getPhoneCable()%>");
						setSel("gasCard",      "<%=_recordBean.getGasCard()%>");
					})();
				</script>

			<%} else if(submitType == SubmitType.BROWSE) {%>
				<input type="hidden" id="daCheckinID" name="daCheckinID" value="<%=_recordBean.getDaCheckinID()%>">
				<div class="row">
					<div class="col-12 col-md-5">
						<div class="row">
							<label class="col-5 col-md-3 col-form-label text-left">Clockin Time</label>
							<div class="col-7 col-md-9 form-control-plaintext text-left"><%=_recordBean.getClockinDate()+" "+_recordBean.getClockinTime()%></div>
						</div>
						<div class="row">
							<label class="col-5 col-md-3 col-form-label text-left">Employee</label>
							<div class="col-7 col-md-9 form-control-plaintext text-left"><%=_recordBean.getEmployeeName()%></div>
						</div>
						<div class="row">
							<label class="col-5 col-md-3 col-form-label text-left">Vehicle</label>
							<div class="col-7 col-md-9 form-control-plaintext text-left"><%=_recordBean.getVehicleName()%></div>
						</div>
						<div class="row">
							<label class="col-5 col-md-3 col-form-label text-left">CDV Verified</label>
							<div class="col-7 col-md-9 form-control-plaintext text-left"><%="1".equalsIgnoreCase(_recordBean.getCdvCertified()) ? "Yes" : "No"%></div>
						</div>
						<div class="row">
							<label class="col-5 col-md-3 col-form-label text-left">DA Remarks</label>
							<div class="col-7 col-md-9 form-control-plaintext text-left"><%=_recordBean.getDaComments()%></div>
						</div>
					</div>

					<div class="col-12 col-md-2"></div>

					<div class="col-12 col-md-5">
						<div class="row">
							<label class="col-5 col-md-3 col-form-label text-left">Wave</label>
							<div class="col-7 col-md-9 form-control-plaintext text-left"><%=_recordBean.getWave()%></div>
						</div>
						<div class="row">
							<label class="col-5 col-md-3 col-form-label text-left">Parking</label>
							<div class="col-7 col-md-9 form-control-plaintext text-left"><%=_mainUtil.getParking().get(_recordBean.getParking())  == null ? "" : _mainUtil.getParking().get(_recordBean.getParking())%></div>
						</div>
						<div class="row">
							<label class="col-5 col-md-3 col-form-label text-left">ISPhone & cables</label>
							<div class="col-7 col-md-9 form-control-plaintext text-left"><%="1".equalsIgnoreCase(_recordBean.getPhoneCable()) ? "Yes" : "No"%></div>
						</div>
						<div class="row">
							<label class="col-5 col-md-3 col-form-label text-left">Gas Card</label>
							<div class="col-7 col-md-9 form-control-plaintext text-left"><%="1".equalsIgnoreCase(_recordBean.getGasCard()) ? "Yes" : "No"%><%if(_recordBean.getGasCardIdentifier().length() > 0) {%> - <%=_recordBean.getGasCardIdentifier()%><%}%></div>
						</div>
						<div class="row">
							<label class="col-5 col-md-3 col-form-label text-left">Dispatch Remarks</label>
							<div class="col-7 col-md-9 form-control-plaintext text-left"><%=_recordBean.getDispatchComments()%></div>
						</div>
					</div>
				</div>

			<%}%>
			</div>
		</div>

		<%if(submitType == SubmitType.CREATE || submitType == SubmitType.UPDATE) {
			int _confirmType = (submitType == SubmitType.CREATE) ? SubmitType.CREATE_CONFIRM : SubmitType.UPDATE_CONFIRM;
		%>
			<div style="display:flex;gap:8px;justify-content:flex-end;align-items:center;margin-top:14px">
				<button class="btn2" onClick="Javascript:submitPageDataForm('<%=SubmitType.SEARCH%>','<%=_recordBean.getController()%>','');">&larr; Back to list</button>
				<button class="btn2 success" onClick="Javascript:submitPageDataForm('<%=_confirmType%>','<%=_recordBean.getController()%>','<%=_recordBean.getDaCheckinID()%>');"><i class="fas fa-check"></i> Save</button>
				<button class="btn2 success" onClick="Javascript:submitPageDataForm('<%=_confirmType%>','<%=_recordBean.getController()%>','<%=_recordBean.getDaCheckinID()%>','2');"><i class="fas fa-check-double"></i> Save &amp; Post</button>
			</div>

		<%} else if(submitType == SubmitType.BROWSE) {%>
			<div class="row mt-4">
				<div class="col-4 text-left">
					<button class="btn btn-secondary text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.SEARCH%>','<%=_recordBean.getController()%>','');">Back to search</button>
				</div>
				<div class="col-4 text-center">
				<%if("0".equalsIgnoreCase(_recordBean.getStatus())) {%>
					<button class="btn btn-primary text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.UPDATE%>','<%=_recordBean.getController()%>','<%=_recordBean.getDaCheckinID()%>');">Edit</button>
				<%} else {%>
					<button class="btn btn-primary text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.WITH_HOLD%>','<%=_recordBean.getController()%>','<%=_recordBean.getDaCheckinID()%>');">Unpost</button>
				<%}%>
				</div>
				<div class="col-4 text-right">
				<%if("0".equalsIgnoreCase(_recordBean.getStatus())) {%>
					<button class="btn btn-danger text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.DELETE%>','<%=_recordBean.getController()%>','<%=_recordBean.getDaCheckinID()%>');">Delete</button>
				<%}%>
				</div>
			</div>
		<%}%>
	</div>
</div>
<%@ include file="includeFooter.jsp"%>
<%}%>
