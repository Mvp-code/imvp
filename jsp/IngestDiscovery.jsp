<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"
         import="java.sql.*,javax.sql.*,javax.naming.*,java.util.*,com.util.*,com.beans.*" %>
<%
  /* ── MVPX-AMZL Bridge — Phase A discovery view ──
     Read-only. Lists what the bridge has captured into amzl_raw so far,
     grouped by endpoint / dataSetId, plus the recent ingest_log outcomes.
     No writes, no forms. Auto-refreshes so you can watch it fill while you
     browse the Amazon portal. When enough shapes are captured, these
     dataSetIds become the parser-v1 registry for Phase B. */
  String arLoginUser   = (request.getAttribute("loginUser") != null) ? request.getAttribute("loginUser").toString() : (String) session.getAttribute("loginUser");
  String arLoginRoles  = (request.getAttribute("loginUserRoles") != null) ? request.getAttribute("loginUserRoles").toString() : (String) session.getAttribute("loginUserRoles");
  String arEntityID    = (request.getAttribute("entityID") != null) ? request.getAttribute("entityID").toString() : (session.getAttribute("entityID") != null ? session.getAttribute("entityID").toString() : "1");
  String arDispName    = (request.getAttribute("loginUserDisplayName") != null) ? request.getAttribute("loginUserDisplayName").toString() : (session.getAttribute("loginUserDisplayName") != null ? session.getAttribute("loginUserDisplayName").toString() : "");
  String arLoginUserID = (request.getAttribute("loginUserID") != null) ? request.getAttribute("loginUserID").toString() : (session.getAttribute("loginUserID") != null ? session.getAttribute("loginUserID").toString() : "");
  if (arLoginUser == null)  arLoginUser  = "";
  if (arLoginRoles == null) arLoginRoles = "";
  if (arDispName == null || arDispName.length() == 0) arDispName = "User";
  if (arEntityID == null || arEntityID.length() == 0) arEntityID = "1";
  if (arLoginUser.trim().length() == 0) {
    response.sendRedirect(request.getContextPath() + "/jsp/login.jsp");
    return;
  }

  /* group key from a captured URL: getData dataSetId / pageConfig page / else path */
  class Lbl {
    String label(String url) {
      if (url == null) return "";
      int i = url.indexOf("dataSetId=");
      if (i >= 0) { String v = url.substring(i + 10); int a = v.indexOf('&'); if (a >= 0) v = v.substring(0, a); return "getData · " + v; }
      int p = url.indexOf("getPageConfig?page=");
      if (p >= 0) { String v = url.substring(p + 19); int a = v.indexOf('&'); if (a >= 0) v = v.substring(0, a); return "pageConfig · " + v; }
      String path = url;
      try { path = url.replaceFirst("^https?://[^/]+", ""); int q = path.indexOf('?'); if (q >= 0) path = path.substring(0, q); } catch (Exception e) {}
      return path;
    }
    String host(String url) {
      try { java.util.regex.Matcher m = java.util.regex.Pattern.compile("^https?://([^/]+)").matcher(url); if (m.find()) return m.group(1); } catch (Exception e) {}
      return "(relative)";
    }
  }
  Lbl L = new Lbl();

  /* aggregate holder */
  class Agg { String label, host; long count = 0, bytes = 0; String last = ""; String parseStatus = ""; }
  LinkedHashMap<String, Agg> groups = new LinkedHashMap<String, Agg>();
  java.util.HashSet<String> urlSeen = new java.util.HashSet<String>();
  long totalRows = 0, totalBytes = 0; int distinctUrls = 0; String lastCapture = "";
  List<String[]> logRows = new ArrayList<String[]>();
  List<String[]> loadRows = new ArrayList<String[]>();  /* {table, records, lastLoaded} */
  List<String[]> hiddenRows = new ArrayList<String[]>(); /* {table, hiddenCount} */
  long loadedTotal = 0, hiddenTotal = 0;
  String dbError = "";
  String ingestKey = "";
  LinkedHashMap<String,String> capturedDs = new LinkedHashMap<String,String>(); /* dataSetId -> cadence */
  LinkedHashMap<String,Integer> dsCount = new LinkedHashMap<String,Integer>(); /* dataSetId -> captured payloads */
  int itinCount = 0, vehCount = 0;
  boolean sawItin = false;
  boolean sawRoster = false;
  boolean sawVehicles = false;
  boolean sawEmployees = false;
  int empCount = 0;
  List<String[]> parseable = new ArrayList<String[]>(); /* {dataSetId, cadence, tableName} that has a table */
  java.util.Map<String,String> loadedByTable = new java.util.HashMap<String,String>(); /* table -> loaded count */
  java.util.Map<String,Boolean> dsEnabled = new java.util.HashMap<String,Boolean>(); /* datasetKey -> enabled (default true) */

  Connection conn = null;
  try {
    Context ictx = new InitialContext();
    DataSource ds = (DataSource) ictx.lookup("java:comp/env/jdbc/MVPGDB");
    conn = ds.getConnection();

    try {
      PreparedStatement pto = conn.prepareStatement("SET SESSION MAX_EXECUTION_TIME=8000");
      pto.execute(); pto.close();
    } catch (Exception ignoreTimeout) {}

    /* headline counters — avoid SUM(LENGTH(BODY)) on the full table (timeout) */
    PreparedStatement ps0 = conn.prepareStatement(
        "SELECT COUNT(*), COALESCE(MAX(CREATE_DATE),'') FROM amzl_raw");
    ps0.setQueryTimeout(8);
    ResultSet r0 = ps0.executeQuery();
    if (r0.next()) { totalRows = r0.getLong(1); lastCapture = r0.getString(2); }
    r0.close(); ps0.close();

    /* recent rows only, aggregated in Java by endpoint label */
    PreparedStatement ps1 = conn.prepareStatement(
        "SELECT URL, LENGTH(BODY), CREATE_DATE, PARSE_STATUS FROM amzl_raw "
        + "WHERE CREATE_DATE >= DATE_SUB(NOW(), INTERVAL 14 DAY) "
        + "ORDER BY CREATE_DATE DESC LIMIT 2000");
    ps1.setQueryTimeout(8);
    ResultSet r1 = ps1.executeQuery();
    while (r1.next()) {
      String url = r1.getString(1); long len = r1.getLong(2); String cd = r1.getString(3); String pstat = r1.getString(4);
      if (url != null) urlSeen.add(url);
      String key = L.label(url);
      Agg a = groups.get(key);
      if (a == null) { a = new Agg(); a.label = key; a.host = L.host(url == null ? "" : url); a.last = cd; a.parseStatus = pstat; groups.put(key, a); }
      a.count++; a.bytes += len; totalBytes += len;
      if (a.last == null || (cd != null && cd.compareTo(a.last) > 0)) a.last = cd;
      /* collect dataSetId + cadence for the parse-picker */
      if (url != null) {
        int di = url.indexOf("dataSetId=");
        if (di >= 0) {
          String v = url.substring(di + 10); int amp = v.indexOf('&'); if (amp >= 0) v = v.substring(0, amp);
          String ul = url.toLowerCase();
          String cad = ul.contains("timeframe=daily") ? "Daily"
                     : ul.contains("timeframe=weekly") ? "Weekly"
                     : ul.contains("timeframe=monthly") ? "Monthly" : "—";
          if (v.length() > 0) {
            if (!capturedDs.containsKey(v)) capturedDs.put(v, cad);
            Integer cc = dsCount.get(v); dsCount.put(v, cc == null ? 1 : cc + 1);
          }
        }
        if (url.contains("/operations/execution/api/summaries")) { sawItin = true; itinCount++; }
        if (url.contains("/api/v4/rosters")) sawRoster = true;
        if (url.contains("/fleet-management/api/vehicles")) { sawVehicles = true; vehCount++; }
        if (url.contains("fetchDSPAssociates")) { sawEmployees = true; empCount++; }
      }
    }
    r1.close(); ps1.close();
    distinctUrls = urlSeen.size();

    /* ingest key for the Parse-now button (LAN-only page, already behind MVPx auth) */
    PreparedStatement psk = conn.prepareStatement("SELECT VAL FROM emily_config WHERE NAME='INGEST_KEY'");
    ResultSet rk = psk.executeQuery();
    if (rk.next()) ingestKey = rk.getString(1);
    rk.close(); psk.close();

    /* recent ingest_log */
    PreparedStatement ps2 = conn.prepareStatement(
        "SELECT CREATE_DATE, SOURCE, OUTCOME, ROWS_IN, ROWS_UPSERTED, MS FROM ingest_log ORDER BY INGEST_LOGID DESC LIMIT 25");
    ps2.setQueryTimeout(8);
    ResultSet r2 = ps2.executeQuery();
    while (r2.next()) {
      logRows.add(new String[]{ r2.getString(1), r2.getString(2), r2.getString(3),
          String.valueOf(r2.getInt(4)), String.valueOf(r2.getInt(5)), String.valueOf(r2.getInt(6)) });
    }
    r2.close(); ps2.close();

    /* records loaded into MVPx by the bridge: every fleetdb table with a
       SOURCE column, counting active SOURCE='BRIDGE' rows, + daily_itineraries
       (upserted, tagged by UPDATE_USER='bridge'). */
    List<String> srcTables = new ArrayList<String>();
    PreparedStatement pst = conn.prepareStatement(
        "SELECT TABLE_NAME FROM information_schema.COLUMNS "
        + "WHERE TABLE_SCHEMA=DATABASE() AND COLUMN_NAME='SOURCE' "
        + "AND TABLE_NAME <> 'ingest_log' ORDER BY TABLE_NAME");
    ResultSet rt = pst.executeQuery();
    while (rt.next()) srcTables.add(rt.getString(1));
    rt.close(); pst.close();

    /* parseable datasets = captured dataSetIds that have a matching table (+ itineraries) */
    java.util.Set<String> srcLower = new java.util.HashSet<String>();
    for (String stn : srcTables) srcLower.add(stn.toLowerCase());
    if (sawItin) parseable.add(new String[]{ "itineraries", "Live", "daily_itineraries" });
    if (sawVehicles) parseable.add(new String[]{ "vehicles", "Fleet", "VEHICLE" });
    if (sawEmployees) parseable.add(new String[]{ "employees", "Roster", "EMPLOYEE" });
    for (Map.Entry<String,String> e : capturedDs.entrySet()) {
      if (srcLower.contains(e.getKey().toLowerCase()))
        parseable.add(new String[]{ e.getKey(), e.getValue(), e.getKey() });
    }
    /* file-based canonical datasets (loaded from supp-reports manifest files) */
    parseable.add(new String[]{ "DVIC", "File", "dvic" });
    parseable.add(new String[]{ "DA Break Utilization", "File", "da_break_utilization" });
    parseable.add(new String[]{ "Sentiment Survey", "File", "sentiment_survey" });
    parseable.add(new String[]{ "Compliance Supplementary", "File", "compliance_supplementary" });
    parseable.add(new String[]{ "Tenure Workforce DAS", "File", "tenure_workforce_das" });
    parseable.add(new String[]{ "Tenure Workforce Weekly", "File", "tenure_workforce_weekly" });
    java.util.Collections.sort(parseable, new java.util.Comparator<String[]>() {
      public int compare(String[] a, String[] b) {
        int c1 = a[1].compareTo(b[1]); return c1 != 0 ? c1 : a[0].compareTo(b[0]);
      }
    });

    for (String tbl : srcTables) {
      try {
        PreparedStatement pc = conn.prepareStatement(
            "SELECT COUNT(*), COALESCE(MAX(CREATE_DATE),'') FROM `" + tbl + "` "
            + "WHERE SOURCE='BRIDGE' AND (STATUS IS NULL OR STATUS!=1)");
        ResultSet rc = pc.executeQuery();
        if (rc.next() && rc.getLong(1) > 0) {
          loadRows.add(new String[]{ tbl, String.valueOf(rc.getLong(1)), rc.getString(2) });
          loadedTotal += rc.getLong(1);
        }
        rc.close(); pc.close();
      } catch (Exception exT) { /* skip a table that can't be counted */ }
    }
    /* daily_itineraries — bridge-upserted rows */
    try {
      PreparedStatement pi = conn.prepareStatement(
          "SELECT COUNT(*), COALESCE(MAX(UPDATE_DATE),'') FROM daily_itineraries "
          + "WHERE UPDATE_USER='bridge' AND (STATUS IS NULL OR STATUS!=1)");
      ResultSet ri = pi.executeQuery();
      if (ri.next() && ri.getLong(1) > 0) {
        loadRows.add(new String[]{ "daily_itineraries", String.valueOf(ri.getLong(1)), ri.getString(2) });
        loadedTotal += ri.getLong(1);
      }
      ri.close(); pi.close();
    } catch (Exception exI) {}
    /* VEHICLE + EMPLOYEE + safety_dashboard — bridge-reconciled (updated or inserted) */
    for (String at : new String[]{ "VEHICLE", "EMPLOYEE", "safety_dashboard" }) {
      try {
        PreparedStatement pv = conn.prepareStatement(
            "SELECT COUNT(*), COALESCE(MAX(UPDATE_DATE),'') FROM `" + at + "` "
            + "WHERE (UPDATE_USER='bridge' OR CREATE_USER='bridge') AND STATUS=0");
        ResultSet rv = pv.executeQuery();
        if (rv.next() && rv.getLong(1) > 0) {
          loadRows.add(new String[]{ at, String.valueOf(rv.getLong(1)), rv.getString(2) });
          loadedTotal += rv.getLong(1);
        }
        rv.close(); pv.close();
      } catch (Exception exV) {}
    }
    /* supplementary-report FILES loaded into canonical tables via /amzl-file */
    for (String ft : new String[]{ "dvic","sentiment_survey","tenure_workforce_das","tenure_workforce_weekly","compliance_supplementary","da_break_utilization" }) {
      try {
        PreparedStatement pf = conn.prepareStatement(
            "SELECT COUNT(*), COALESCE(MAX(CREATE_DATE),'') FROM `" + ft + "` "
            + "WHERE CREATE_USER='bridge' AND STATUS=0");
        ResultSet rf = pf.executeQuery();
        if (rf.next() && rf.getLong(1) > 0) {
          loadRows.add(new String[]{ ft, String.valueOf(rf.getLong(1)), rf.getString(2) });
          loadedTotal += rf.getLong(1);
        }
        rf.close(); pf.close();
      } catch (Exception exF) {}
    }
    /* employee_schedule — show exactly what the last schedule parse loaded
       (from ingest_log). The DAO dedupes vs manual uploads, so a table COUNT
       would mix days/sources; the logged run count is the honest number. */
    try {
      PreparedStatement pe = conn.prepareStatement(
          "SELECT ROWS_UPSERTED, SOURCE, CREATE_DATE FROM ingest_log "
          + "WHERE SOURCE LIKE 'schedule:%' ORDER BY INGEST_LOGID DESC LIMIT 1");
      ResultSet re = pe.executeQuery();
      if (re.next() && re.getLong(1) > 0) {
        loadRows.add(new String[]{ "employee_schedule (" + re.getString(2).replace("schedule:","") + ")",
            String.valueOf(re.getLong(1)), re.getString(3) });
        loadedTotal += re.getLong(1);
      }
      re.close(); pe.close();
    } catch (Exception exE) {}
    /* map table -> loaded count for the datasets picker */
    for (String[] lr2 : loadRows) loadedByTable.put(lr2[0], lr2[1]);
    /* per-dataset enabled state (default enabled) */
    try {
      PreparedStatement pen = conn.prepareStatement("SELECT DATASET, ENABLED FROM amzl_dataset");
      ResultSet ren = pen.executeQuery();
      while (ren.next()) dsEnabled.put(ren.getString(1), ren.getInt(2) != 0);
      ren.close(); pen.close();
    } catch (Exception exEn) {}

    /* hidden (superseded STATUS=1) rows in the weekly report tables — purgeable */
    String[] purgeTbls = { "dvic","da_break_utilization","sentiment_survey","compliance_supplementary",
      "tenure_workforce_das","tenure_workforce_weekly","quality_dcr_weekly","quality_overview",
      "cdf_feedback","dsb_details","dashboard_overview","safety_dashboard" };
    for (String pt : purgeTbls) {
      try {
        PreparedStatement ph = conn.prepareStatement("SELECT COUNT(*) FROM `" + pt + "` WHERE STATUS=1");
        ResultSet rh = ph.executeQuery();
        if (rh.next() && rh.getLong(1) > 0) { hiddenRows.add(new String[]{ pt, String.valueOf(rh.getLong(1)) }); hiddenTotal += rh.getLong(1); }
        rh.close(); ph.close();
      } catch (Exception exH) {}
    }
    /* sort by records desc */
    java.util.Collections.sort(loadRows, new java.util.Comparator<String[]>() {
      public int compare(String[] a, String[] b) {
        return Long.compare(Long.parseLong(b[1]), Long.parseLong(a[1]));
      }
    });

  } catch (Exception ex) {
    dbError = ex.getClass().getSimpleName() + ": " + ex.getMessage();
  } finally {
    if (conn != null) try { conn.close(); } catch (Exception e) {}
  }

  /* sort groups by count desc */
  List<Agg> aggList = new ArrayList<Agg>(groups.values());
  Collections.sort(aggList, new Comparator<Agg>() { public int compare(Agg a, Agg b) { return Long.compare(b.count, a.count); } });

  String fmtBytes;
  { double kb = totalBytes / 1024.0; fmtBytes = kb < 1024 ? String.format("%.0f KB", kb) : String.format("%.1f MB", kb / 1024.0); }

  request.setAttribute("loginUser", arLoginUser);
  request.setAttribute("loginUserRoles", arLoginRoles);
  request.setAttribute("entityID", arEntityID);
  request.setAttribute("loginUserDisplayName", arDispName);
  request.setAttribute("loginUserID", arLoginUserID);
  request.setAttribute("shellNoForm", "yes");
  request.setAttribute("hideTopbarSearch", "yes");
%>
<jsp:useBean id="_recordBean" class="com.beans.SearchBean" scope="request" />
<%
  _recordBean.setController("IngestDiscovery");
  _recordBean.setDisplayName("MVPX-AMZL Bridge");
  int submitType = SubmitType.SEARCH;
%>
<!DOCTYPE html>
<html lang="en">
<%@ include file="includeHeader.jsp"%>
<script>
function validatePageData(submitType, isValid) { return isValid; }
</script>
<style>
.ig-shell{display:flex;flex-direction:column;height:calc(100vh - 96px);overflow:hidden}
.ig-hdr{display:flex;align-items:center;gap:12px;margin-bottom:10px;flex-shrink:0;flex-wrap:wrap}
.ig-hdr h1{font-size:18px;font-weight:900;color:#0f172a;margin:0}
.ig-hdr .sub{font-size:12px;color:#64748B}
.ig-hdr .live{margin-left:auto;display:flex;align-items:center;gap:6px;font-size:12px;color:#334155}
.ig-hdr .dot{width:9px;height:9px;border-radius:50%;background:#22c55e}
.ig-hdr .dot.off{background:#9CA3AF}
.ig-cards{display:flex;gap:10px;margin-bottom:12px;flex-shrink:0;flex-wrap:wrap}
.ig-card{border:1px solid #E4E8F0;border-radius:9px;padding:10px 14px;min-width:120px;background:#fff}
.ig-card .n{font-size:22px;font-weight:900;color:#0f172a;line-height:1.1}
.ig-card .k{font-size:11px;text-transform:uppercase;letter-spacing:.04em;color:#94A3B8;margin-top:2px}
.ig-body{flex:1;display:flex;gap:12px;min-height:0}
.ig-col{flex:1;display:flex;flex-direction:column;min-height:0}
.ig-col h2{font-size:12px;text-transform:uppercase;letter-spacing:.05em;color:#64748B;margin:0 0 6px}
.ig-wrap{flex:1;overflow:auto;border:1px solid #E4E8F0;border-radius:8px;background:#fff}
.ig-wrap table{width:100%;border-collapse:collapse}
.ig-wrap th{position:sticky;top:0;background:#F8FAFC;font-size:10px;text-transform:uppercase;letter-spacing:.04em;color:#64748B;text-align:left;padding:6px 9px;border-bottom:1px solid #E4E8F0;white-space:nowrap;z-index:2}
.ig-wrap td{font-size:12px;color:#1F2937;padding:5px 9px;border-bottom:1px solid #EEF1F6;white-space:nowrap;max-width:360px;overflow:hidden;text-overflow:ellipsis}
.ig-wrap td.num{text-align:right;font-variant-numeric:tabular-nums}
.ig-wrap tr:hover td{background:#F8FAFC}
.ig-wrap .mono{font-family:Consolas,Menlo,monospace;font-size:11.5px}
.ig-tag{display:inline-block;font-size:10px;font-weight:700;padding:1px 7px;border-radius:9px;background:#EEF1F6;color:#334155}
.ig-tag.amz{background:#ECFDF5;color:#065F46}
.ig-empty{color:#94A3B8;font-size:12.5px;padding:18px;text-align:center}
.ig-err{color:var(--status-escalation-fg);font-size:12.5px;padding:10px 12px;border:1px solid var(--status-escalation-border);border-radius:8px;background:var(--status-escalation-bg);margin-bottom:10px}
.ig-note{font-size:11.5px;color:#94A3B8;margin-top:8px;flex-shrink:0}
.ig-parsebar{display:flex;align-items:center;gap:8px;flex-wrap:wrap;background:#F8FAFC;border:1px solid #E4E8F0;border-radius:8px;padding:8px 12px;margin-bottom:10px;flex-shrink:0}
.ig-parsebar .lbl{font-size:11px;text-transform:uppercase;letter-spacing:.04em;color:#64748B;font-weight:700}
.ig-parsebar .sep{width:1px;height:20px;background:#E4E8F0;margin:0 4px}
.ig-parsebar select{border:1px solid #CBD5E1;border-radius:6px;padding:5px 8px;font:inherit;font-size:12.5px;max-width:340px}
.ig-parsebar .pcount{margin-left:auto;font-size:11.5px;color:#94A3B8}
.pbtn{border:1px solid #CBD5E1;background:#fff;color:#0f172a;border-radius:6px;padding:5px 12px;font:inherit;font-size:12px;font-weight:700;cursor:pointer}
.pbtn:hover{background:#EEF1F6}
.pbtn.primary{background:#0f172a;color:#fff;border-color:#0f172a}
.pbtn:disabled{opacity:.5;cursor:default}
.ig-parsebar label.radio{display:inline-flex;align-items:center;gap:4px;font-size:12.5px;color:#0f172a;cursor:pointer}
.ig-parsebar label.radio small{color:#94A3B8}
.ig-tag.file{background:#EFF6FF;color:#1E40AF}
.tgl{position:relative;display:inline-block;width:34px;height:18px;cursor:pointer}
.tgl input{opacity:0;width:0;height:0;position:absolute}
.tgl .sl{position:absolute;inset:0;background:#CBD5E1;border-radius:18px;transition:.15s}
.tgl .sl:before{content:"";position:absolute;height:14px;width:14px;left:2px;top:2px;background:#fff;border-radius:50%;transition:.15s}
.tgl input:checked + .sl{background:#16a34a}
.tgl input:checked + .sl:before{transform:translateX(16px)}
</style>

<div class="ig-shell">
  <div class="ig-hdr">
    <h1><i class="fa fa-random"></i>&nbsp;MVPX-AMZL Bridge <span class="sub">· Phase A discovery</span></h1>
    <div class="live">
      <span class="dot<%= (totalRows > 0) ? "" : " off" %>"></span>
      <%= (lastCapture != null && lastCapture.length() > 0) ? ("last capture " + lastCapture) : "no captures yet" %>
      &nbsp;·&nbsp;auto-refresh 20s
    </div>
  </div>

  <div class="ig-parsebar">
    <span class="lbl">Auto-load is ON by default</span>
    <span class="pcount" style="margin-left:0">&mdash; enabled datasets load automatically as they're captured. Toggle a row off to stop it.</span>
    <span class="sep"></span>
    <span class="lbl">Load now:</span>
    <button class="pbtn primary" onclick="parseNow('all','All')">All enabled</button>
    <button class="pbtn" onclick="parseNow('weekly','Weekly')">Weekly</button>
    <button class="pbtn" onclick="parseNow('daily','Daily')">Daily</button>
  </div>

  <div class="ig-parsebar">
    <span class="lbl">Employee Schedule:</span>
    <label class="radio"><input type="radio" name="schedMode" value="nextday" checked> Next Day <small>(default)</small></label>
    <label class="radio"><input type="radio" name="schedMode" value="today"> Today</label>
    <label class="radio"><input type="radio" name="schedMode" value="todaynext"> Today + Next</label>
    <label class="radio"><input type="radio" name="schedMode" value="holiday"> Holiday <small>(3-day)</small></label>
    <button class="pbtn primary" onclick="parseSchedule()"<%= sawRoster ? "" : " disabled title='No roster captured yet — open the Scheduling page in the portal'" %>>Parse Schedule</button>
    <span class="pcount"><%= sawRoster ? "roster captured" : "no roster captured" %> &middot; runs vehicle allocation</span>
  </div>
  <div id="parseMsg" style="display:none;font-size:12px;color:#065F46;background:#ECFDF5;border:1px solid #A7F3D0;border-radius:7px;padding:8px 12px;margin-bottom:10px;white-space:pre-line;"></div>

  <% if (dbError.length() > 0) { %>
    <div class="ig-err"><b>DB error:</b> <%= dbError %></div>
  <% } %>

  <div class="ig-cards">
    <div class="ig-card"><div class="n"><%= totalRows %></div><div class="k">payloads</div></div>
    <div class="ig-card"><div class="n"><%= distinctUrls %></div><div class="k">distinct URLs</div></div>
    <div class="ig-card"><div class="n"><%= aggList.size() %></div><div class="k">endpoints</div></div>
    <div class="ig-card"><div class="n"><%= fmtBytes %></div><div class="k">raw stored</div></div>
    <div class="ig-card"><div class="n"><%= String.format("%,d", loadedTotal) %></div><div class="k">records loaded</div></div>
    <div class="ig-card" style="<%= hiddenTotal > 0 ? "border-color:#FCD34D;background:#FFFBEB" : "" %>">
      <div class="n" style="<%= hiddenTotal > 0 ? "color:var(--status-warn-fg)" : "" %>"><%= String.format("%,d", hiddenTotal) %></div>
      <div class="k">hidden / superseded</div>
      <% if (hiddenTotal > 0) { %>
        <button class="pbtn" style="margin-top:5px;padding:3px 10px;font-size:11px" onclick="purgeHidden()"
          title="<% for (String[] h : hiddenRows) { %><%= h[0] %>: <%= h[1] %>&#10;<% } %>">Purge hidden</button>
      <% } %>
    </div>
  </div>

  <div class="ig-body">
    <div class="ig-col">
      <h2>Datasets &mdash; auto-load <span style="color:#94A3B8;font-weight:400;text-transform:none;letter-spacing:0;">(on by default; toggle off to stop)</span></h2>
      <div class="ig-wrap">
        <table>
          <thead><tr>
            <th style="width:52px">Auto</th><th>Table / dataSetId</th><th>Cadence</th>
            <th style="text-align:right">Captured</th><th style="text-align:right">Loaded</th><th></th>
          </tr></thead>
          <tbody>
          <% if (parseable.isEmpty()) { %>
            <tr><td colspan="6" class="ig-empty">No datasets captured yet. Browse logistics.amazon.com with the extension on.</td></tr>
          <% } else { for (String[] pd : parseable) {
               String dsid = pd[0], cad = pd[1], tbl = pd[2];
               boolean isFile = "File".equals(cad);
               int capC = "itineraries".equals(dsid) ? itinCount
                        : "vehicles".equals(dsid) ? vehCount
                        : "employees".equals(dsid) ? empCount
                        : isFile ? -1
                        : (dsCount.get(dsid) == null ? 0 : dsCount.get(dsid));
               String loaded = loadedByTable.get(tbl);
               if (loaded == null && "itineraries".equals(dsid)) loaded = loadedByTable.get("daily_itineraries");
               boolean en = dsEnabled.containsKey(dsid) ? dsEnabled.get(dsid) : true; %>
            <tr>
              <td><label class="tgl"><input type="checkbox" onchange="toggleDs('<%= dsid %>',this.checked)"<%= en ? " checked" : "" %>><span class="sl"></span></label></td>
              <td class="mono" title="<%= dsid %>"><%= tbl %></td>
              <td><span class="ig-tag<%= "Live".equals(cad)||"Daily".equals(cad) ? " amz" : (isFile ? " file" : "") %>"><%= cad %></span></td>
              <td class="num"><%= capC < 0 ? "&mdash;" : String.valueOf(capC) %></td>
              <td class="num"><%= loaded == null ? "&mdash;" : String.format("%,d", Long.parseLong(loaded)) %></td>
              <td><% if (!isFile) { %><button class="pbtn" style="padding:3px 10px" onclick="parseNow('<%= dsid %>','<%= tbl %>')">Parse</button><% } else { %><span style="color:#94A3B8;font-size:11px">via file</span><% } %></td>
            </tr>
          <% } } %>
          </tbody>
        </table>
      </div>
    </div>

    <div class="ig-col">
      <h2>Loaded into MVPx &nbsp;<span style="color:#94A3B8;font-weight:400;text-transform:none;letter-spacing:0;">(<%= String.format("%,d", loadedTotal) %> records)</span></h2>
      <div class="ig-wrap">
        <table>
          <thead><tr><th>Table</th><th style="text-align:right">Records</th><th>Last loaded</th></tr></thead>
          <tbody>
          <% if (loadRows.isEmpty()) { %>
            <tr><td colspan="3" class="ig-empty">Nothing loaded yet. Click <b>Parse now</b> to load captured payloads into MVPx tables.</td></tr>
          <% } else { for (String[] lr : loadRows) { %>
            <tr>
              <td class="mono" title="<%= lr[0] %>"><%= lr[0] %></td>
              <td class="num"><%= String.format("%,d", Long.parseLong(lr[1])) %></td>
              <td class="mono"><%= lr[2] %></td>
            </tr>
          <% } } %>
          </tbody>
        </table>
      </div>
      <h2 style="margin-top:10px">Recent ingest log</h2>
      <div class="ig-wrap">
        <table>
          <thead><tr><th>When</th><th>Source</th><th>Outcome</th><th style="text-align:right">In</th><th style="text-align:right">Up</th><th style="text-align:right">ms</th></tr></thead>
          <tbody>
          <% if (logRows.isEmpty()) { %>
            <tr><td colspan="6" class="ig-empty">No ingest activity yet.</td></tr>
          <% } else { for (String[] lr : logRows) { %>
            <tr>
              <td class="mono"><%= lr[0] %></td>
              <td><%= lr[1] %></td>
              <td><%= lr[2] %></td>
              <td class="num"><%= lr[3] %></td>
              <td class="num"><%= lr[4] %></td>
              <td class="num"><%= lr[5] %></td>
            </tr>
          <% } } %>
          </tbody>
        </table>
      </div>
    </div>
  </div>

  <div class="ig-note">Read-only. Auth/credential/telemetry endpoints are denylisted and never captured. The <code>getData · &lt;dataSetId&gt;</code> rows become the parser-v1 registry for Phase B.</div>
</div>

<script>
  var _rt = setTimeout(function () { location.reload(); }, 20000);
  var INGEST_KEY = "<%= ingestKey %>";
  function parseNow(filter, label) {
    clearTimeout(_rt);
    var btns = document.querySelectorAll(".pbtn");
    btns.forEach(function (b) { b.disabled = true; });
    var msg = document.getElementById("parseMsg");
    msg.style.display = "block"; msg.style.color = "#334155"; msg.style.background = "#EEF1F6";
    msg.textContent = "Parsing " + (label || filter) + "…";
    fetch("../api/ingest/process?filter=" + encodeURIComponent(filter) + "&user=<%= arLoginUser %>", {
      method: "POST", headers: { "X-INGEST-KEY": INGEST_KEY }
    }).then(function (r) { return r.json(); })
      .then(function (d) {
        msg.style.color = "#065F46"; msg.style.background = "#ECFDF5";
        msg.textContent = d.ok ? ("Parsed " + (label || filter) + ":\n" + (d.summary || "")) : ("Error: " + JSON.stringify(d));
        btns.forEach(function (b) { b.disabled = false; });
        setTimeout(function () { location.reload(); }, 2500);
      }).catch(function (e) {
        msg.style.color = "var(--status-escalation-fg)"; msg.style.background = "var(--status-escalation-bg)";
        msg.textContent = "Failed: " + e;
        btns.forEach(function (b) { b.disabled = false; });
      });
  }
  function purgeHidden() {
    if (!confirm("Permanently delete all hidden (superseded) rows from the weekly report tables? Active data is untouched.")) return;
    clearTimeout(_rt);
    var msg = document.getElementById("parseMsg");
    msg.style.display = "block"; msg.style.color = "#334155"; msg.style.background = "#EEF1F6";
    msg.textContent = "Purging hidden rows…";
    fetch("../api/ingest/purge?user=<%= arLoginUser %>", { method: "POST", headers: { "X-INGEST-KEY": INGEST_KEY } })
      .then(function (r) { return r.json(); })
      .then(function (d) {
        msg.style.color = "#065F46"; msg.style.background = "#ECFDF5";
        msg.textContent = "Purged " + (d.deleted || 0) + " hidden rows. " + JSON.stringify(d.byTable || {});
        _rt = setTimeout(function () { location.reload(); }, 2500);
      }).catch(function (e) {
        msg.style.color = "var(--status-escalation-fg)"; msg.style.background = "var(--status-escalation-bg)"; msg.textContent = "Purge failed: " + e;
      });
  }
  function toggleDs(dataset, enabled) {
    clearTimeout(_rt);
    var msg = document.getElementById("parseMsg");
    fetch("../api/ingest/toggle?dataset=" + encodeURIComponent(dataset) + "&enabled=" + (enabled ? 1 : 0) + "&user=<%= arLoginUser %>", {
      method: "POST", headers: { "X-INGEST-KEY": INGEST_KEY }
    }).then(function (r) { return r.json(); })
      .then(function (d) {
        msg.style.display = "block"; msg.style.color = "#334155"; msg.style.background = "#EEF1F6";
        msg.textContent = dataset + " auto-load " + (enabled ? "ENABLED — loads automatically as captured." : "DISABLED — will not load until re-enabled.");
        _rt = setTimeout(function () { location.reload(); }, 8000);
      }).catch(function (e) {
        msg.style.display = "block"; msg.style.color = "var(--status-escalation-fg)"; msg.style.background = "var(--status-escalation-bg)";
        msg.textContent = "Toggle failed: " + e;
      });
  }
  function parseSchedule() {
    var r = document.querySelector('input[name="schedMode"]:checked');
    var mode = r ? r.value : "nextday";
    var label = r ? r.parentNode.textContent.replace(/\s+/g," ").trim() : "Next Day";
    clearTimeout(_rt);
    var btns = document.querySelectorAll(".pbtn");
    btns.forEach(function (b) { b.disabled = true; });
    var msg = document.getElementById("parseMsg");
    msg.style.display = "block"; msg.style.color = "#334155"; msg.style.background = "#EEF1F6";
    msg.textContent = "Loading Employee Schedule (" + label + ") — running vehicle allocation…";
    fetch("../api/ingest/process?filter=schedule&scheduleMode=" + encodeURIComponent(mode) + "&user=<%= arLoginUser %>&entityID=<%= arEntityID %>", {
      method: "POST", headers: { "X-INGEST-KEY": INGEST_KEY }
    }).then(function (r) { return r.json(); })
      .then(function (d) {
        msg.style.color = "#065F46"; msg.style.background = "#ECFDF5";
        msg.textContent = d.ok ? ("Schedule loaded (" + label + "):\n" + (d.summary || "")) : ("Error: " + JSON.stringify(d));
        btns.forEach(function (b) { b.disabled = false; });
        setTimeout(function () { location.reload(); }, 2500);
      }).catch(function (e) {
        msg.style.color = "var(--status-escalation-fg)"; msg.style.background = "var(--status-escalation-bg)";
        msg.textContent = "Failed: " + e;
        btns.forEach(function (b) { b.disabled = false; });
      });
  }
</script>

<%@ include file="includeFooter.jsp"%>
