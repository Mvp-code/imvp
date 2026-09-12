<!DOCTYPE html>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*, com.util.*"%>
<jsp:useBean id="_recordBean" class="com.beans.SearchBean" scope="request"/>
<jsp:useBean id="_errorBean"  class="com.beans.ErrorBean"  scope="request"/>
<jsp:useBean id="_mainUtil"   class="com.util.MainUtil"    scope="request"/>
<%
int submitType = request.getAttribute("submitType") == null
    ? SubmitType.SEARCH
    : Integer.parseInt(request.getAttribute("submitType").toString().trim());

String ctrl        = _recordBean.getController();
String pgDisplayName = _recordBean.getDisplayName();  /* renamed: 'displayName' collides with includeHeader.jsp's submenu var */
List   dataList    = _recordBean.getDataList();
List   labelsList  = _recordBean.getLabelsList();
String fromDate    = _recordBean.getSrhFromDate() == null ? "" : _recordBean.getSrhFromDate();
String toDate      = _recordBean.getSrhToDate()   == null ? "" : _recordBean.getSrhToDate();
String srhValue    = _recordBean.getSrhValue()     == null ? "" : _recordBean.getSrhValue();
boolean hasBrowse  = true;
boolean hasNew     = true;
%>
<script>
function validatePageData(st, isValid) { return isValid; }
function pageOnSubmitFunction() {
    submitPageDataForm('<%=SubmitType.SEARCH%>','<%=ctrl%>','','','&searchFilter=yes');
}
</script>
<%@ include file="includeHeader.jsp"%>

<style>
:root{
  --n-blue:var(--theme-accent,#2563EB);--n-blue-dark:var(--theme-accent-dark,#1D4ED8);--n-blue-50:var(--status-info-bg,#EFF4FF);--n-blue-100:#DBE6FF;
  --n-ink:#0B1220;--n-text:#1F2937;--n-muted:#475569;--n-faint:#64748B;
  --n-line:#E4E8F0;--n-line-soft:#EEF1F6;--n-canvas:#F5F7FA;
  --n-green:var(--status-ok-fg,#15803D);--n-green-50:var(--status-ok-bg,#E7F6EE);
  --n-red:var(--status-action-fg,#C62828);--n-red-50:var(--status-action-bg,#FCEBEB);
  --n-amber:var(--status-warn-fg,#B45309);--n-amber-50:var(--status-warn-bg,#FBF1E2);
  --n-shadow:0 1px 2px rgba(16,24,40,.05),0 1px 3px rgba(16,24,40,.06);
}
.n-wrap{padding:4px 0 60px}
.n-crumb{font-size:13px;color:var(--n-muted);margin-bottom:10px}
.n-crumb .tag{background:var(--n-blue-50);color:var(--n-blue-dark);font-weight:700;font-size:12px;padding:2px 8px;border-radius:6px}
.n-headrow{display:flex;justify-content:space-between;align-items:flex-start;gap:12px;margin-bottom:12px;flex-wrap:wrap}
.n-headrow h2{margin:0;font-size:20px;font-weight:800;color:var(--n-ink)}
.n-toolbar{display:flex;align-items:center;gap:8px;flex-wrap:wrap;background:#fff;border:1px solid var(--n-line);border-radius:11px;padding:9px 11px;box-shadow:var(--n-shadow);margin-bottom:6px}
.n-daterange{display:inline-flex;align-items:center;gap:5px;border:1px solid var(--n-line);border-radius:8px;padding:4px 9px;background:#fff}
.n-daterange input[type=date]{border:none;font-size:13px;padding:3px 2px;font-family:inherit;color:var(--n-text);background:transparent}
.n-daterange input[type=date]:focus{outline:none}
.n-daterange .dash{color:var(--n-faint);font-size:13px}
.n-quick{display:inline-flex;gap:4px}
.n-quick button{border:1px solid var(--n-line);background:#fff;color:var(--n-muted);border-radius:7px;padding:6px 10px;font-size:12px;font-weight:600;cursor:pointer;transition:background .15s}
.n-quick button.on{background:var(--n-blue-50);border-color:var(--n-blue-100);color:var(--n-blue-dark)}
.n-flt{border:1px solid var(--n-line);border-radius:8px;padding:7px 10px;font-size:13px;background:#fff;cursor:pointer;color:var(--n-text)}
.n-flt:focus{outline:none;border-color:var(--n-blue)}
.n-search{border:1px solid var(--n-line);border-radius:8px;padding:7px 10px;font-size:13px;background:#fff;color:var(--n-text);min-width:180px}
.n-search:focus{outline:none;border-color:var(--n-blue);box-shadow:0 0 0 3px var(--n-blue-50)}
.n-chips{display:flex;gap:7px;flex-wrap:wrap;margin:8px 0 0;min-height:0}
.n-chip{background:var(--n-blue-50);border:1px solid var(--n-blue-100);color:var(--n-blue-dark);border-radius:999px;padding:3px 8px 3px 10px;font-size:12px;font-weight:600;display:inline-flex;align-items:center;gap:6px}
.n-chip .x{cursor:pointer;border:none;background:transparent;color:var(--n-blue-dark);font-size:13px;line-height:1;padding:0 2px}
.n-tablewrap{background:#fff;border:1px solid var(--n-line);border-radius:11px;overflow:hidden;box-shadow:var(--n-shadow);margin-top:12px}
.n-tablewrap table{width:100%;border-collapse:collapse}
.n-tablewrap thead th{text-align:left;font-size:13px;color:#111827;font-weight:800;padding:11px 13px;background:#FAFCFF;border-bottom:1px solid var(--n-line);white-space:nowrap}
.n-tablewrap thead th a{color:#111827;text-decoration:none;cursor:pointer}
.n-tablewrap thead th a:hover{color:var(--n-blue)}
.n-tablewrap tbody td{padding:11px 13px;border-bottom:1px solid var(--n-line-soft);font-size:14.5px;vertical-align:middle}
.n-tablewrap tbody tr:last-child td{border-bottom:none}
.n-tablewrap tbody tr.browseable:hover{background:#FAFBFE;cursor:pointer}
.n-tablefoot{display:flex;justify-content:space-between;align-items:center;padding:9px 13px;border-top:1px solid var(--n-line-soft);font-size:13px;color:var(--n-muted);gap:8px;flex-wrap:wrap}
.n-btn{border:1px solid var(--n-line);background:#fff;color:var(--n-text);padding:7px 13px;border-radius:8px;font-size:13px;font-weight:600;cursor:pointer;display:inline-flex;align-items:center;gap:6px;white-space:nowrap;transition:background .15s}
.n-btn:hover{background:var(--n-line-soft)}
.n-btn.primary{background:var(--n-blue);border-color:var(--n-blue);color:#fff}.n-btn.primary:hover{background:var(--n-blue-dark)}
.n-btn.sm{padding:5px 9px;font-size:12px}
.n-empty{text-align:center;color:var(--n-faint);padding:32px;font-size:14px}
.n-row-html{font-size:13px}
.n-row-html a{color:var(--n-blue)}
</style>

<div class="n-wrap">
  <%-- heading row --%>
  <div class="n-headrow">
    <h2><%=pgDisplayName%></h2>
    <div style="display:flex;gap:8px;align-items:center">
      <%if(hasNew){%>
      <button class="n-btn primary" onclick="submitPageDataForm('<%=SubmitType.CREATE%>','<%=ctrl%>');">&#xFF0B; New</button>
      <%}%>
    </div>
  </div>

  <%-- error banner --%>
  <%if(_errorBean != null && _errorBean.getType().length() > 0){%>
  <div class="row text-center mt-2 mb-2">
    <section class="alert_section">
      <div class="alert-box <%=_errorBean.getType()%>Color"><%=_errorBean.getMesg()%></div>
    </section>
  </div>
  <%}%>

  <%-- filter toolbar --%>
  <div class="n-toolbar">
    <%-- date range — only shown when the search returned dates --%>
    <%if(fromDate.length() > 0 || toDate.length() > 0){%>
    <div class="n-daterange">
      <span style="color:var(--n-faint)">&#128197;</span>
      <input type="date" id="nFilterFrom" value="<%=fromDate%>" onchange="nQuickReload()">
      <span class="dash">&ndash;</span>
      <input type="date" id="nFilterTo" value="<%=toDate%>" onchange="nQuickReload()">
    </div>
    <div class="n-quick">
      <button id="nBtnToday" onclick="nQuickDate(this,'today')">Today</button>
      <button id="nBtnTmrw"  onclick="nQuickDate(this,'tomorrow')">Tomorrow</button>
    </div>
    <%}%>
    <input class="n-search" id="nSearch" type="text" placeholder="Search&#8230;" value="<%=srhValue%>" oninput="nApplyFilters()">
  </div>

  <%-- active filter chips --%>
  <div class="n-chips" id="nChips"></div>

  <%-- table --%>
  <div class="n-tablewrap">
    <table>
      <thead>
        <tr>
          <%for(int i=0; i<labelsList.size(); i++){
            String colLabel = (String)labelsList.get(i);%>
          <th>
            <a href="Javascript:sortSearchRecords('<%=SubmitType.SEARCH%>','<%=ctrl%>','<%=i%>','<%=_recordBean.getColumnSortOrder()%>');"><%=colLabel%></a>
          </th>
          <%}%>
        </tr>
      </thead>
      <tbody id="nRows">
        <%if(dataList == null || dataList.size() == 0){%>
        <tr><td colspan="<%=labelsList.size()%>" class="n-empty">No records found.</td></tr>
        <%} else {
          for(int i=0; i<dataList.size(); i++){
            List row = (List)dataList.get(i);
            String rowID = row.get(0) == null ? "" : row.get(0).toString().trim();
            /* build a combined search key from all visible cells */
            StringBuilder sk = new StringBuilder();
            for(int c=0; c<row.size(); c++){
              if(row.get(c)!=null) sk.append(row.get(c).toString().replaceAll("<[^>]+>","")).append(" ");
            }
            String searchKey = sk.toString().toLowerCase().replace("\"","&quot;");
        %>
        <tr class="<%=hasBrowse?"browseable":""%>"
            data-id="<%=rowID%>"
            data-key="<%=searchKey%>"
            <%if(hasBrowse && rowID.length()>0){%>
            onclick="submitPageDataForm('<%=SubmitType.BROWSE%>','<%=ctrl%>','<%=rowID%>')"
            <%}%>>
          <%for(int c=0; c<labelsList.size(); c++){
            String cell = (row.size()>c && row.get(c)!=null) ? row.get(c).toString() : "";%>
          <td class="n-row-html"><%=cell%></td>
          <%}%>
        </tr>
        <%}}%>
      </tbody>
    </table>
    <div class="n-tablefoot">
      <span id="nShowCount"><%=dataList!=null?dataList.size():0%> record(s)</span>
      <button class="n-btn sm" onclick="submitPageDataForm('<%=SubmitType.SEARCH%>','<%=ctrl%>','','','&searchFilter=yes')">&#8635; Refresh</button>
    </div>
  </div>
</div>

<script>
var _nCtrl = '<%=ctrl%>';
var _nSt   = <%=SubmitType.SEARCH%>;

/* ---- client-side filtering ---- */
function nApplyFilters() {
  var q = (document.getElementById('nSearch').value || '').toLowerCase().trim();
  var rows = document.querySelectorAll('#nRows tr[data-key]');
  var shown = 0;
  rows.forEach(function(r) {
    var vis = !q || r.dataset.key.indexOf(q) >= 0;
    r.style.display = vis ? '' : 'none';
    if (vis) shown++;
  });
  document.getElementById('nShowCount').textContent = shown + ' record(s)';
  nRenderChips(q);
}

function nRenderChips(q) {
  var c = document.getElementById('nChips');
  c.innerHTML = '';
  if (q) {
    c.innerHTML = '<span class="n-chip">Search: <b>' + q + '</b>'
      + '<button class="x" onclick="nClearSearch()">&times;</button></span>';
  }
}

function nClearSearch() {
  document.getElementById('nSearch').value = '';
  nApplyFilters();
}

/* ---- date quick buttons ---- */
function nQuickDate(el, which) {
  document.querySelectorAll('.n-quick button').forEach(function(b){ b.classList.remove('on'); });
  el.classList.add('on');
  var d = new Date();
  if (which === 'tomorrow') d.setDate(d.getDate() + 1);
  var iso = d.toISOString().substring(0, 10);
  var fd = document.getElementById('nFilterFrom');
  var td = document.getElementById('nFilterTo');
  if (fd) { fd.value = iso; td.value = iso; }
  nQuickReload();
}

function nQuickReload() {
  var fd = document.getElementById('nFilterFrom');
  var td = document.getElementById('nFilterTo');
  var q  = encodeURIComponent(document.getElementById('nSearch').value || '');
  var url = '../servlet/MVPGServlet?submitType=' + _nSt + '&controller=' + _nCtrl + '&searchFilter=yes&srhValue=' + q;
  if (fd) url += '&srhFromDate=' + fd.value + '&srhToDate=' + td.value;
  window.location.href = url;
}

/* init: mark today/tomorrow button if dates match */
(function(){
  var fd = document.getElementById('nFilterFrom');
  if (!fd) return;
  var today = new Date().toISOString().substring(0,10);
  var tmrw  = new Date(Date.now()+86400000).toISOString().substring(0,10);
  if (fd.value === today) document.getElementById('nBtnToday').classList.add('on');
  else if (fd.value === tmrw) document.getElementById('nBtnTmrw').classList.add('on');
})();
</script>
