<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"
         import="java.sql.*,javax.sql.*,javax.naming.*,java.util.*,com.util.*,com.beans.*" %>
<%
  /* ── MVPx-Reports — one tab per uploaded Amazon data set ──
     Generic viewer: columns from ResultSetMetaData (schema-change-proof).
     Week/date filters run SERVER-SIDE against the whole table; sorting is
     client-side on the loaded rows. */
  String arLoginUser   = (request.getAttribute("loginUser") != null) ? request.getAttribute("loginUser").toString() : (String) session.getAttribute("loginUser");
  String arLoginRoles  = (request.getAttribute("loginUserRoles") != null) ? request.getAttribute("loginUserRoles").toString() : (String) session.getAttribute("loginUserRoles");
  String arEntityID    = (request.getAttribute("entityID") != null) ? request.getAttribute("entityID").toString() : (session.getAttribute("entityID") != null ? session.getAttribute("entityID").toString() : "1");
  String arDispName    = (request.getAttribute("loginUserDisplayName") != null) ? request.getAttribute("loginUserDisplayName").toString() : (session.getAttribute("loginUserDisplayName") != null ? session.getAttribute("loginUserDisplayName").toString() : "");
  String arLoginUserID = (request.getAttribute("loginUserID") != null) ? request.getAttribute("loginUserID").toString() : (session.getAttribute("loginUserID") != null ? session.getAttribute("loginUserID").toString() : "");
  if (arLoginUser == null)  arLoginUser  = "";
  if (arLoginRoles == null) arLoginRoles = "";
  if (arDispName == null || arDispName.length() == 0) arDispName = "User";

  final String[][] TABS = {
    {"Overview",       "dashboard_overview",       "per-DA weekly scorecard"},
    {"Safety",         "safety_dashboard",         "safety events"},
    {"Quality DCR",    "quality_dcr_weekly",       "weekly DCR"},
    {"CDF Feedback",   "cdf_feedback",             "negative customer feedback"},
    {"Concessions",    "dsb_details",              "DSB / concessions"},
    {"Sentiment",      "sentiment_survey",         "DA sentiment survey"},
    {"Break Util",     "da_break_utilization",     "DA break utilization"},
    {"Tenure Weekly",  "tenure_workforce_weekly",  "station tenure by week"},
    {"Tenure per DA",  "tenure_workforce_das",     "per-DA tenure"},
    {"Compliance",     "compliance_supplementary", "supplementary metrics"},
    {"DVIC",           "dvic",                     "pre-trip inspections"},
    {"Itineraries",    "daily_itineraries",        "route progress"},
    // Bridge-only bonus datasets (AMZL getData; populated in Phase B)
    {"6-Week Perf (DA)","da_dsp_weekly_sixweekly_performance", "per-DA 6-week performance"},
    {"Suppl Quality (DA)","da_dsp_station_daily_supplemental_quality", "per-DA daily supplemental quality (RTS/POD/DNR)"},
    {"Team",           "dsp_station_weekly_team",            "station team scorecard"},
    {"SPR",            "dsp_station_weekly_spr",             "stops-per-route averages"},
    {"Attrition",      "dsp_station_weekly_attrition",       "weekly attrition rate"},
    {"Device Health",  "dsp_station_weekly_working_device",  "camera/device health"},
    {"Conversion",     "dsp_station_weekly_conversion_rate", "onboarding conversion rate"},
    {"Onboard Time",   "dsp_station_weekly_average_completion_time", "avg onboarding-to-delivery time"},
    {"URR (Monthly)",  "dsp_station_monthly_urr",            "unfavorable response rate"},
    {"Thresholds DSP", "dsp_weekly_thresholds",              "DSP metric thresholds/tiers"},
    {"Thresholds DA",  "da_weekly_thresholds",               "DA metric thresholds/tiers"},
    {"Escalations (ORCAS)","da_dsp_daily_orcas_event_aggs",  "per-DA daily ORCAS events / violations"}
  };
  final java.util.Set<String> SKIP_COLS = new java.util.HashSet<String>(java.util.Arrays.asList(
    "ENTITYID","STATUS","CREATE_USER","CREATE_DATE","UPDATE_USER","UPDATE_DATE","BLOB_VALUE","SOURCE"));

  /* active-tab filter from URL (sanitized: week digits, date yyyy-MM-dd) */
  int selTab = 0;
  try { selTab = Integer.parseInt(String.valueOf(request.getParameter("tab"))); } catch (Exception e) {}
  if (selTab < 0 || selTab >= TABS.length) selTab = 0;
  String selWk = String.valueOf(request.getParameter("wk"));
  selWk = selWk.matches("\\d{1,2}") ? selWk : "";
  String selYr = String.valueOf(request.getParameter("yr"));
  selYr = selYr.matches("\\d{4}") ? selYr : "";
  String selDt = String.valueOf(request.getParameter("dt"));
  selDt = selDt.matches("\\d{4}-\\d{2}-\\d{2}") ? selDt : "";
  String selNm = String.valueOf(request.getParameter("nm"));
  if ("null".equals(selNm)) selNm = "";
  selNm = selNm.replaceAll("[\"'\\\\;%_]", "").trim();
  if (selNm.length() > 60) selNm = selNm.substring(0, 60);

  /* per tab: {label, hint, total, cols[], rows[][], weekCol, dateCol, weeks[], yearCol, nameCol} */
  List<Object[]> tabData = new ArrayList<Object[]>();
  String dbError = "";
  Connection conn = null;
  try {
    Context ictx = new InitialContext();
    DataSource ds = (DataSource) ictx.lookup("java:comp/env/jdbc/MVPGDB");
    conn = ds.getConnection();
    for (int t = 0; t < TABS.length; t++) {
      String[] tb = TABS[t];
      long total = 0;
      List<String> cols = new ArrayList<String>();
      List<String[]> rows = new ArrayList<String[]>();
      List<String> weeks = new ArrayList<String>();
      String weekCol = "", dateCol = "", yearCol = "", nameCol = "";
      try {
        /* discover columns + filter columns from metadata */
        PreparedStatement pm = conn.prepareStatement("SELECT * FROM " + tb[1] + " LIMIT 1");
        ResultSet rm = pm.executeQuery();
        ResultSetMetaData md = rm.getMetaData();
        List<Integer> keep = new ArrayList<Integer>();
        for (int c = 2; c <= md.getColumnCount(); c++) {
          String nm = md.getColumnLabel(c).toUpperCase();
          if (SKIP_COLS.contains(nm)) continue;
          keep.add(c); cols.add(nm);
          int ty = md.getColumnType(c);
          if (weekCol.length() == 0 && nm.contains("WEEK") && !nm.contains("WEEKLY"))
            weekCol = nm;
          if (yearCol.length() == 0 && nm.contains("YEAR"))
            yearCol = nm;
          if (dateCol.length() == 0 && (ty == java.sql.Types.DATE || ty == java.sql.Types.TIMESTAMP))
            dateCol = nm;
          /* employee/driver name: prefer explicit associate/name columns */
          if (nameCol.length() == 0 && (nm.contains("ASSOCIATE") || nm.equals("DA_NAME")
              || nm.equals("TRANSPORTERNAME") || nm.equals("DRIVER_NAME") || nm.equals("DA_NAME:"))
              && !nm.contains("ID"))
            nameCol = nm;
        }
        /* fallback: any column containing NAME */
        if (nameCol.length() == 0)
          for (String c2 : cols)
            if (c2.contains("NAME") && !c2.contains("FILE")) { nameCol = c2; break; }
        rm.close(); pm.close();

        /* distinct weeks for the dropdown - paired with year when the table
           has one (safety etc. span multiple years) */
        if (weekCol.length() > 0) {
          String wq = yearCol.length() > 0
              ? "SELECT DISTINCT CONCAT(" + yearCol + ",'|'," + weekCol + ") FROM " + tb[1]
                  + " WHERE (STATUS IS NULL OR STATUS!=1) AND " + weekCol + " IS NOT NULL"
                  + " ORDER BY 1 DESC LIMIT 60"
              : "SELECT DISTINCT " + weekCol + " FROM " + tb[1]
                  + " WHERE (STATUS IS NULL OR STATUS!=1) AND " + weekCol
                  + " IS NOT NULL ORDER BY 1 DESC LIMIT 60";
          PreparedStatement pw = conn.prepareStatement(wq);
          ResultSet rw = pw.executeQuery();
          while (rw.next()) weeks.add(rw.getString(1));
          rw.close(); pw.close();
        }

        /* server-side filters apply only to the ACTIVE tab */
        String cond = " WHERE (STATUS IS NULL OR STATUS!=1) ";
        if (t == selTab && selWk.length() > 0 && weekCol.length() > 0)
          cond += " AND " + weekCol + "='" + selWk + "' ";
        if (t == selTab && selYr.length() > 0 && yearCol.length() > 0)
          cond += " AND " + yearCol + "='" + selYr + "' ";
        if (t == selTab && selDt.length() > 0 && dateCol.length() > 0)
          cond += " AND DATE(" + dateCol + ")='" + selDt + "' ";
        if (t == selTab && selNm.length() > 0 && nameCol.length() > 0)
          cond += " AND " + nameCol + " LIKE '%" + selNm + "%' ";

        PreparedStatement pc = conn.prepareStatement("SELECT COUNT(*) FROM " + tb[1] + cond);
        ResultSet rc = pc.executeQuery();
        if (rc.next()) total = rc.getLong(1);
        rc.close(); pc.close();

        PreparedStatement ps = conn.prepareStatement(
            "SELECT * FROM " + tb[1] + cond + " ORDER BY 1 DESC LIMIT 300");
        ResultSet rs = ps.executeQuery();
        while (rs.next()) {
          String[] r = new String[keep.size()];
          for (int k = 0; k < keep.size(); k++) {
            Object v = rs.getObject(keep.get(k));
            String s = v == null ? "" : v.toString();
            if (s.length() > 160) s = s.substring(0, 160) + "…";
            r[k] = s;
          }
          rows.add(r);
        }
        rs.close(); ps.close();
      } catch (Exception exTab) {
        cols = java.util.Arrays.asList("error");
        rows = new ArrayList<String[]>();
        rows.add(new String[]{ String.valueOf(exTab.getMessage()) });
      }
      tabData.add(new Object[]{ tb[0], tb[2], total, cols, rows, weekCol, dateCol, weeks, yearCol, nameCol });
    }
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
_recordBean.setController("MVPxReports");
_recordBean.setDisplayName("MVPx-Reports");
request.setAttribute("loginUser", arLoginUser);
request.setAttribute("loginUserRoles", arLoginRoles);
request.setAttribute("entityID", arEntityID);
request.setAttribute("loginUserDisplayName", arDispName);
request.setAttribute("loginUserID", arLoginUserID);
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
.ar-shell{display:flex;flex-direction:column;height:calc(100vh - 96px);overflow:hidden}
.ar-hdr{display:flex;align-items:center;gap:12px;margin-bottom:8px;flex-shrink:0;flex-wrap:wrap}
.ar-hdr h1{font-size:18px;font-weight:900;color:#0f172a;margin:0}
.ar-hdr .sub{font-size:12px;color:#64748B}
.ar-flt{border:1px solid #CBD5E1;border-radius:7px;padding:6px 10px;font-size:13px;min-width:200px;margin-left:auto}
.ar-tabs{display:flex;gap:2px;border-bottom:2px solid #E4E8F0;margin-bottom:8px;flex-shrink:0;flex-wrap:wrap}
.ar-tab{border:none;background:none;padding:6px 10px;font-size:12.5px;font-weight:700;color:#64748B;cursor:pointer;border-bottom:2px solid transparent;margin-bottom:-2px;white-space:nowrap}
.ar-tab.active{color:#0f172a;border-bottom-color:#0f172a}
.ar-tab .cnt{background:#EEF1F6;border-radius:9px;font-size:10px;padding:1px 6px;margin-left:3px;color:#334155}
.ar-body{flex:1;overflow:hidden;min-height:0;display:flex;flex-direction:column}
.ar-pane{display:none;flex:1;min-height:0;flex-direction:column}
.ar-pane.active{display:flex}
.ar-meta{display:flex;align-items:center;gap:10px;font-size:11.5px;color:#94A3B8;margin-bottom:6px;flex-shrink:0;flex-wrap:wrap}
.ar-meta select,.ar-meta input[type=date]{border:1px solid #CBD5E1;border-radius:6px;padding:4px 8px;font-size:12px;color:#0f172a}
.ar-meta .clr{font-size:11.5px;font-weight:700;color:#C62828;cursor:pointer;text-decoration:none}
.ar-wrap{flex:1;overflow:auto;border:1px solid #E4E8F0;border-radius:8px;background:#fff}
.ar-wrap table{width:100%;border-collapse:collapse}
.ar-wrap th{position:sticky;top:0;background:#F8FAFC;font-size:10px;text-transform:uppercase;letter-spacing:.04em;color:#64748B;text-align:left;padding:6px 9px;border-bottom:1px solid #E4E8F0;white-space:nowrap;z-index:2;cursor:pointer;user-select:none}
.ar-wrap th:hover{background:#EEF1F6}
.ar-wrap th .dir{color:#0f172a;font-size:9px;margin-left:3px}
.ar-wrap td{font-size:12px;color:#1F2937;padding:5px 9px;border-bottom:1px solid #EEF1F6;white-space:nowrap;max-width:340px;overflow:hidden;text-overflow:ellipsis}
.ar-wrap tr:hover td{background:#F8FAFC}
.ar-empty{color:#94A3B8;font-size:12.5px;padding:16px;text-align:center}
</style>

<div class="ar-shell">
  <div class="ar-hdr">
    <h1><i class="fa fa-table"></i>&nbsp;MVPx-Reports</h1>
    <span class="sub">Every Amazon data set in one place &middot; filters search the whole table &middot; click a header to sort</span>
    <input class="ar-flt" id="arFilter" placeholder="Quick filter rows on this tab&hellip;" oninput="arFilter()">
  </div>
  <%if (dbError.length() > 0 && !"null".equals(dbError)) {%><div class="ar-empty">DB: <%=dbError%></div><%}%>

  <div class="ar-tabs">
    <%for (int t = 0; t < tabData.size(); t++) { Object[] td = tabData.get(t);%>
    <button class="ar-tab<%=t==selTab?" active":""%>" data-pane="<%=t%>" onclick="arTab(this)">
      <%=td[0]%> <span class="cnt"><%=td[2]%></span></button>
    <%}%>
  </div>

  <div class="ar-body">
    <%for (int t = 0; t < tabData.size(); t++) {
        Object[] td = tabData.get(t);
        List<String> cols = (List<String>) td[3];
        List<String[]> rows = (List<String[]>) td[4];
        String weekCol = (String) td[5], dateCol = (String) td[6];
        List<String> weeks = (List<String>) td[7];
        String yearCol = (String) td[8], nameCol = (String) td[9];
        boolean filtered = t == selTab && (selWk.length() > 0 || selDt.length() > 0
                || selNm.length() > 0 || selYr.length() > 0);%>
    <div class="ar-pane<%=t==selTab?" active":""%>" id="arPane<%=t%>">
      <div class="ar-meta">
        <span><%=td[1]%> &middot; <b><%=td[2]%></b> row<%=((Long)td[2])==1?"":"s"%><%=filtered ? " matching filter" : " total"%><%=((Long)td[2]) > 300 ? " (showing newest 300)" : ""%></span>
        <%if (weekCol.length() > 0) {%>
        <label>Week:
          <select class="ar-fwk" onchange="arGo(<%=t%>)">
            <option value="">all</option>
            <%for (String w : weeks) {
                String val = w, lbl = "Wk " + w;
                if (w.indexOf('|') > 0) {
                  String yy = w.substring(0, w.indexOf('|'));
                  String ww = w.substring(w.indexOf('|') + 1);
                  lbl = yy + " &middot; Wk " + ww;
                }
                boolean sel = t == selTab && (w.indexOf('|') > 0
                    ? w.equals(selYr + "|" + selWk) : w.equals(selWk));%>
            <option value="<%=val%>"<%=sel?" selected":""%>><%=lbl%></option>
            <%}%>
          </select></label>
        <%}%>
        <%if (dateCol.length() > 0) {%>
        <label>Day:
          <input type="date" class="ar-fdt" value="<%=(t==selTab)?selDt:""%>" onchange="arGo(<%=t%>)"></label>
        <%}%>
        <%if (nameCol.length() > 0) {%>
        <label>Employee:
          <input type="text" class="ar-fnm" placeholder="name&hellip;" style="width:140px;border:1px solid #CBD5E1;border-radius:6px;padding:4px 8px;font-size:12px"
                 value="<%=(t==selTab)?selNm:""%>" onkeydown="if(event.key==='Enter')arGo(<%=t%>)">
          <button class="ar-fgo" style="border:1px solid #CBD5E1;background:#fff;border-radius:6px;font-size:11px;padding:4px 8px;cursor:pointer" onclick="arGo(<%=t%>)">Apply</button></label>
        <%}%>
        <%if (filtered) {%><a class="clr" href="?tab=<%=t%>">&#10005; clear filter</a><%}%>
      </div>
      <div class="ar-wrap">
        <table>
          <thead><tr><%for (int c = 0; c < cols.size(); c++) {%><th onclick="arSort(this, <%=c%>)"><%=cols.get(c)%><span class="dir"></span></th><%}%></tr></thead>
          <tbody>
          <%if (rows.isEmpty()) {%><tr class="ar-norows"><td colspan="<%=cols.size()%>" class="ar-empty"><%=filtered ? "No rows match this filter." : "No rows yet — upload this report via Smart Upload."%></td></tr><%}%>
          <%for (String[] r : rows) {%><tr><%for (String v : r) {%><td title="<%=v.replace("\"","&quot;")%>"><%=v.replace("<","&lt;")%></td><%}%></tr><%}%>
          </tbody>
        </table>
      </div>
    </div>
    <%}%>
  </div>
</div>

<script>
function arTab(btn){
  document.querySelectorAll('.ar-tab').forEach(function(t){ t.classList.remove('active'); });
  document.querySelectorAll('.ar-pane').forEach(function(p){ p.classList.remove('active'); });
  btn.classList.add('active');
  document.getElementById('arPane' + btn.dataset.pane).classList.add('active');
  document.getElementById('arFilter').value = '';
  arFilter();
}
/* filters reload server-side so they search the WHOLE table; all of the
   active pane's controls are combined into one query string */
function arGo(tab){
  var pane = document.getElementById('arPane' + tab);
  var q = '?tab=' + tab;
  var wkSel = pane.querySelector('.ar-fwk');
  if (wkSel && wkSel.value) {
    var v = wkSel.value;
    if (v.indexOf('|') > 0) {
      q += '&yr=' + encodeURIComponent(v.split('|')[0]) + '&wk=' + encodeURIComponent(v.split('|')[1]);
    } else {
      q += '&wk=' + encodeURIComponent(v);
    }
  }
  var dt = pane.querySelector('.ar-fdt');
  if (dt && dt.value) q += '&dt=' + encodeURIComponent(dt.value);
  var nm = pane.querySelector('.ar-fnm');
  if (nm && nm.value.trim()) q += '&nm=' + encodeURIComponent(nm.value.trim());
  location.href = q;
}
function arFilter(){
  var q = document.getElementById('arFilter').value.toLowerCase();
  var pane = document.querySelector('.ar-pane.active');
  if (!pane) return;
  pane.querySelectorAll('tbody tr').forEach(function(tr){
    if (tr.classList.contains('ar-norows')) return;
    tr.style.display = !q || tr.textContent.toLowerCase().indexOf(q) >= 0 ? '' : 'none';
  });
}
/* header sort: numeric-aware, toggles asc/desc, one column at a time */
function arSort(th, idx){
  var tbody = th.closest('table').querySelector('tbody');
  var rows = [].slice.call(tbody.querySelectorAll('tr')).filter(function(r){ return !r.classList.contains('ar-norows'); });
  var asc = th.dataset.dir !== 'asc';
  th.closest('tr').querySelectorAll('th').forEach(function(h){ h.dataset.dir = ''; h.querySelector('.dir').textContent = ''; });
  th.dataset.dir = asc ? 'asc' : 'desc';
  th.querySelector('.dir').textContent = asc ? '▲' : '▼';
  rows.sort(function(a, b){
    var av = (a.cells[idx] ? a.cells[idx].textContent : '').trim();
    var bv = (b.cells[idx] ? b.cells[idx].textContent : '').trim();
    var an = parseFloat(av.replace(/[%,$]/g, '')), bn = parseFloat(bv.replace(/[%,$]/g, ''));
    var cmp;
    if (!isNaN(an) && !isNaN(bn) && av !== '' && bv !== '') cmp = an - bn;
    else cmp = av.localeCompare(bv);
    return asc ? cmp : -cmp;
  });
  rows.forEach(function(r){ tbody.appendChild(r); });
}
</script>
<%@ include file="includeFooter.jsp"%>
</html>
