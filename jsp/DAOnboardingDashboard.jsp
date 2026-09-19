<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"
         import="java.sql.*,javax.sql.*,javax.naming.*,java.util.*,com.util.*,com.beans.*" %>
<%!
  private Connection getConn() throws Exception {
    Context ctx = new InitialContext();
    DataSource ds = (DataSource) ctx.lookup("java:comp/env/jdbc/MVPGDB");
    return ds.getConnection();
  }
  private String esc(String s) {
    if (s == null) return "";
    return s.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("'","&#39;");
  }
%>
<%
  String obLoginUser   = request.getAttribute("loginUser") != null ? request.getAttribute("loginUser").toString() : (String) session.getAttribute("loginUser");
  String obLoginRoles  = request.getAttribute("loginUserRoles") != null ? request.getAttribute("loginUserRoles").toString() : (String) session.getAttribute("loginUserRoles");
  String obEntityID    = request.getAttribute("entityID") != null ? request.getAttribute("entityID").toString() : (session.getAttribute("entityID") != null ? session.getAttribute("entityID").toString() : "1");
  String obDispName    = request.getAttribute("loginUserDisplayName") != null ? request.getAttribute("loginUserDisplayName").toString() : (session.getAttribute("loginUserDisplayName") != null ? session.getAttribute("loginUserDisplayName").toString() : "");
  String obLoginUserID = request.getAttribute("loginUserID") != null ? request.getAttribute("loginUserID").toString() : (session.getAttribute("loginUserID") != null ? session.getAttribute("loginUserID").toString() : "");
  if (obLoginUser == null) obLoginUser = "";
  if (obLoginRoles == null) obLoginRoles = "";
  if (obDispName == null || obDispName.length() == 0) obDispName = "User";
  if (obEntityID == null || obEntityID.length() == 0) obEntityID = "1";
  if (obLoginUser.isEmpty()) {
    response.sendRedirect(request.getContextPath() + "/servlet/MVPGServlet?submitType=11&controller=Login");
    return;
  }

  List<Map<String,String>> hiredRows = new ArrayList<Map<String,String>>();
  List<String[]> byWeek  = new ArrayList<String[]>();
  List<String[]> byMonth = new ArrayList<String[]>();
  List<String[]> byMonthPipeline = new ArrayList<String[]>();
  String dbError = null;
  int total = 0, onTrack = 0, behind = 0, complete = 0, totalHired = 0;
  int hired30 = 0;

  Connection conn = null;
  try {
    conn = getConn();
    int eid = 1;
    try { eid = Integer.parseInt(obEntityID); } catch (Exception ex) { eid = 1; }

    try {
      Statement stFail = conn.createStatement();
      stFail.executeUpdate(
        "UPDATE da_onboarding SET ob_status='FAILED' " +
        "WHERE IFNULL(ob_status,'') NOT IN ('FAILED','COMPLETE') " +
        "AND UPPER(IFNULL(checkr_status,'')) IN ('FAIL','FAILED','ADVERSE','ADVERSE_ACTION')");
      stFail.close();
    } catch (Exception ignore) {}

    PreparedStatement psPipe = conn.prepareStatement(
      "SELECT COUNT(*) FROM da_applications a " +
      "LEFT JOIN da_onboarding o ON o.application_id = a.application_id " +
      "WHERE a.entity_id = ? AND (o.ob_status IS NULL OR o.ob_status NOT IN ('COMPLETE','FAILED'))");
    psPipe.setInt(1, eid);
    ResultSet rsPipe = psPipe.executeQuery();
    if (rsPipe.next()) total = rsPipe.getInt(1);
    rsPipe.close(); psPipe.close();

    PreparedStatement psSt = conn.prepareStatement(
      "SELECT " +
      " SUM(CASE WHEN o.ob_status='ON_TRACK' THEN 1 ELSE 0 END), " +
      " SUM(CASE WHEN o.ob_status='BEHIND' THEN 1 ELSE 0 END), " +
      " SUM(CASE WHEN o.ob_status='COMPLETE' THEN 1 ELSE 0 END) " +
      "FROM da_onboarding o WHERE o.entity_id=?");
    psSt.setInt(1, eid);
    ResultSet rsSt = psSt.executeQuery();
    if (rsSt.next()) {
      onTrack = rsSt.getInt(1);
      behind = rsSt.getInt(2);
      complete = rsSt.getInt(3);
    }
    rsSt.close(); psSt.close();

    PreparedStatement psH = conn.prepareStatement(
      "SELECT a.application_id, a.first_name, a.last_name, a.email, a.phone, a.avail_type, " +
      "       o.onboarding_id, o.completed_date, o.s9_day1_date, o.notes " +
      "FROM da_applications a " +
      "JOIN da_onboarding o ON o.application_id = a.application_id " +
      "WHERE a.entity_id = ? AND o.ob_status = 'COMPLETE' " +
      "ORDER BY o.completed_date DESC");
    psH.setInt(1, eid);
    ResultSet rsH = psH.executeQuery();
    ResultSetMetaData metaH = rsH.getMetaData();
    while (rsH.next()) {
      Map<String,String> row = new LinkedHashMap<String,String>();
      for (int i = 1; i <= metaH.getColumnCount(); i++) {
        String v = rsH.getString(i);
        row.put(metaH.getColumnName(i).toLowerCase(), v == null ? "" : v);
      }
      hiredRows.add(row);
      totalHired++;
    }
    rsH.close(); psH.close();

    PreparedStatement ps30 = conn.prepareStatement(
      "SELECT COUNT(*) FROM da_onboarding WHERE entity_id=? AND ob_status='COMPLETE' " +
      "AND IFNULL(completed_date,CURDATE()) >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)");
    ps30.setInt(1, eid);
    ResultSet rs30 = ps30.executeQuery();
    if (rs30.next()) hired30 = rs30.getInt(1);
    rs30.close(); ps30.close();

    PreparedStatement psW = conn.prepareStatement(
      "SELECT DATE_FORMAT(IFNULL(completed_date,CURDATE()),'%Y-%u') as yw, COUNT(*) as cnt " +
      "FROM da_onboarding WHERE ob_status='COMPLETE' AND entity_id=? " +
      "GROUP BY DATE_FORMAT(IFNULL(completed_date,CURDATE()),'%Y-%u') ORDER BY yw DESC LIMIT 16");
    psW.setInt(1, eid);
    ResultSet rsW = psW.executeQuery();
    while (rsW.next()) {
      String yw = rsW.getString("yw");
      String lbl = "Week " + yw.substring(5) + ", " + yw.substring(0,4);
      byWeek.add(new String[] { yw, lbl, rsW.getString("cnt") });
    }
    rsW.close(); psW.close();

    String[] MON = {"","Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"};
    PreparedStatement psM = conn.prepareStatement(
      "SELECT DATE_FORMAT(IFNULL(completed_date,CURDATE()),'%Y-%m') as ym, COUNT(*) as cnt " +
      "FROM da_onboarding WHERE ob_status='COMPLETE' AND entity_id=? " +
      "GROUP BY DATE_FORMAT(IFNULL(completed_date,CURDATE()),'%Y-%m') ORDER BY ym DESC LIMIT 12");
    psM.setInt(1, eid);
    ResultSet rsM = psM.executeQuery();
    while (rsM.next()) {
      String ym = rsM.getString("ym");
      int mo = Integer.parseInt(ym.substring(5));
      byMonth.add(new String[] { ym, MON[mo] + " " + ym.substring(0,4), rsM.getString("cnt") });
    }
    rsM.close(); psM.close();

    PreparedStatement psPL = conn.prepareStatement(
      "SELECT DATE_FORMAT(a.applied_ts,'%Y-%m') as ym, COUNT(*) as cnt " +
      "FROM da_applications a " +
      "LEFT JOIN da_onboarding o ON o.application_id = a.application_id " +
      "WHERE a.entity_id = ? AND (o.ob_status IS NULL OR o.ob_status NOT IN ('COMPLETE','FAILED')) " +
      "GROUP BY DATE_FORMAT(a.applied_ts,'%Y-%m') ORDER BY ym DESC LIMIT 12");
    psPL.setInt(1, eid);
    ResultSet rsPL = psPL.executeQuery();
    while (rsPL.next()) {
      byMonthPipeline.add(new String[] { rsPL.getString("ym"), rsPL.getString("cnt") });
    }
    rsPL.close(); psPL.close();
  } catch (Exception ex) {
    dbError = ex.getMessage();
  } finally {
    if (conn != null) try { conn.close(); } catch (Exception e) {}
  }

  Map<String,Integer> hiredByMonthMap = new LinkedHashMap<String,Integer>();
  for (String[] r : byMonth) hiredByMonthMap.put(r[0], Integer.parseInt(r[2]));
  Map<String,Integer> pipelineByMonthMap = new LinkedHashMap<String,Integer>();
  for (String[] pl : byMonthPipeline) pipelineByMonthMap.put(pl[0], Integer.parseInt(pl[1]));
  Set<String> allMKeys = new LinkedHashSet<String>();
  for (String[] r : byMonth) allMKeys.add(r[0]);
  for (String[] pl : byMonthPipeline) allMKeys.add(pl[0]);
  List<String> sortedMKeys = new ArrayList<String>(allMKeys);
  Collections.sort(sortedMKeys, Collections.reverseOrder());
  if (sortedMKeys.size() > 12) sortedMKeys = sortedMKeys.subList(0, 12);
  String[] SMON2 = {"","Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"};
%>
<jsp:useBean id="_recordBean" class="com.beans.SearchBean" scope="request" />
<jsp:useBean id="_errorBean" class="com.beans.ErrorBean" scope="request" />
<%
int submitType = SubmitType.SEARCH;
_recordBean.setController("DAOnboardingDashboard");
_recordBean.setDisplayName("DA Onboarding Dashboard");
request.setAttribute("loginUser", obLoginUser);
request.setAttribute("loginUserRoles", obLoginRoles);
request.setAttribute("entityID", obEntityID);
request.setAttribute("loginUserDisplayName", obDispName);
request.setAttribute("loginUserID", obLoginUserID);
request.setAttribute("shellNoForm", "yes");
request.setAttribute("hideTopbarSearch", "yes");
%>
<!DOCTYPE html>
<html lang="en">
<%@ include file="includeHeader.jsp"%>
<script>function validatePageData(submitType, isValid) { return isValid; }</script>
<style>
.odb-shell{display:flex;flex-direction:column;gap:14px;padding-bottom:28px}
.odb-hdr{display:flex;align-items:flex-start;justify-content:space-between;gap:12px;flex-wrap:wrap}
.odb-hdr h1{font-size:22px;font-weight:900;color:#0f172a;margin:0}
.odb-hdr p{font-size:13px;color:#64748b;margin:4px 0 0}
.odb-actions{display:flex;gap:8px;flex-wrap:wrap}
.odb-actions a{display:inline-flex;align-items:center;gap:6px;padding:8px 14px;border-radius:8px;font-size:13px;font-weight:700;text-decoration:none}
.odb-actions .primary{background:#2563eb;color:#fff}
.odb-actions .ghost{background:#fff;color:#0f172a;border:1px solid #e2e8f0}
.odb-kpis{display:grid;grid-template-columns:repeat(5,minmax(120px,1fr));gap:10px}
.odb-kpi{background:#fff;border:1px solid #e2e8f0;border-radius:10px;padding:14px 16px}
.odb-kpi b{display:block;font-size:28px;font-weight:900;color:#0f172a;line-height:1.1}
.odb-kpi span{font-size:12px;color:#64748b;font-weight:700;text-transform:uppercase;letter-spacing:.04em}
.odb-kpi.green b{color:#16a34a}.odb-kpi.red b{color:#dc2626}.odb-kpi.blue b{color:#2563eb}.odb-kpi.purple b{color:#7c3aed}
.odb-grid{display:grid;grid-template-columns:1.1fr 1fr 1.2fr;gap:14px;align-items:start}
.odb-card{background:#fff;border:1px solid #e2e8f0;border-radius:12px;overflow:hidden;display:flex;flex-direction:column;max-height:70vh}
.odb-card-hdr{padding:14px 16px 12px;border-bottom:1px solid #f1f5f9;flex-shrink:0}
.odb-card-title{font-size:14px;font-weight:800;color:#0f172a;text-transform:uppercase;letter-spacing:.03em}
.odb-card-sub{font-size:12px;color:#94a3b8;margin-top:3px}
.odb-card-body{overflow:auto;scrollbar-width:thin;scrollbar-color:#94A3B8 #E2E8F0}
.odb-card-body::-webkit-scrollbar{width:10px;height:10px}
.odb-card-body::-webkit-scrollbar-thumb{background:#94A3B8;border-radius:6px}
.odb-row{display:flex;padding:10px 16px;border-bottom:1px solid #f8fafc;align-items:center;gap:8px;font-size:14px}
.odb-row:last-child{border-bottom:none}
.odb-row .m{flex:1;font-weight:600;color:#374151}
.odb-row .n{min-width:42px;text-align:center;font-weight:800;border-radius:7px;padding:3px 8px;font-size:13px}
.odb-n-blue{color:#2563eb;background:#eff6ff}
.odb-n-purple{color:#7c3aed;background:#ede9fe}
.odb-hired{display:flex;padding:11px 16px;border-bottom:1px solid #f8fafc;align-items:center;gap:10px}
.odb-av{width:34px;height:34px;border-radius:50%;background:#7c3aed;color:#fff;font-size:12px;font-weight:800;display:flex;align-items:center;justify-content:center;flex-shrink:0}
.odb-hn{font-size:14px;font-weight:700;color:#0f172a}
.odb-hm{font-size:12px;color:#94a3b8;margin-top:2px}
.odb-err{background:var(--status-escalation-bg);border:1px solid var(--status-escalation-border);border-radius:8px;padding:12px 16px;color:var(--status-escalation-fg);font-size:13px}
@media (max-width:1100px){.odb-grid{grid-template-columns:1fr}.odb-kpis{grid-template-columns:repeat(2,1fr)}.odb-card{max-height:none}}
</style>

<div class="odb-shell">
  <div class="odb-hdr">
    <div>
      <h1>DA Onboarding Dashboard</h1>
      <p>Monthly &amp; weekly hiring reports &middot; completed DAs</p>
    </div>
    <div class="odb-actions">
      <a class="ghost" href="DAOnboarding.jsp">Open Pipeline</a>
      <a class="primary" href="DAApplicationForm.jsp" target="_blank" rel="noopener">+ New Application</a>
    </div>
  </div>

  <% if (dbError != null) { %>
  <div class="odb-err"><strong>DB error:</strong> <%=esc(dbError)%></div>
  <% } %>

  <div class="odb-kpis">
    <div class="odb-kpi"><b><%=total%></b><span>In Pipeline</span></div>
    <div class="odb-kpi green"><b><%=onTrack%></b><span>On Track</span></div>
    <div class="odb-kpi red"><b><%=behind%></b><span>Behind</span></div>
    <div class="odb-kpi purple"><b><%=hired30%></b><span>Hired (30 days)</span></div>
    <div class="odb-kpi blue"><b><%=totalHired%></b><span>Hired (All Time)</span></div>
  </div>

  <div class="odb-grid">
    <div class="odb-card">
      <div class="odb-card-hdr">
        <div class="odb-card-title">Monthly Report</div>
        <div class="odb-card-sub">Pipeline vs hired by month</div>
      </div>
      <div class="odb-card-body">
        <div class="odb-row" style="background:#f8fafc;border-bottom:1px solid #e2e8f0;">
          <span class="m" style="color:#94a3b8;font-size:11px;text-transform:uppercase;">Month</span>
          <span class="n" style="color:#2563eb;background:transparent;font-size:11px;">Pipe</span>
          <span class="n" style="color:#7c3aed;background:transparent;font-size:11px;">Hired</span>
        </div>
        <% if (sortedMKeys.isEmpty()) { %>
        <div class="odb-row" style="color:#94a3b8;">No data yet.</div>
        <% } %>
        <% int mTotalP=0, mTotalH=0;
           for (String mk : sortedMKeys) {
             int mh = hiredByMonthMap.containsKey(mk) ? hiredByMonthMap.get(mk) : 0;
             int mp = pipelineByMonthMap.containsKey(mk) ? pipelineByMonthMap.get(mk) : 0;
             mTotalP += mp; mTotalH += mh;
             int moI = Integer.parseInt(mk.substring(5));
             String mlbl = SMON2[moI] + " '" + mk.substring(2,4);
        %>
        <div class="odb-row">
          <span class="m"><%=mlbl%></span>
          <span class="n odb-n-blue"><%=mp%></span>
          <span class="n odb-n-purple"><%=mh%></span>
        </div>
        <% } %>
        <div class="odb-row" style="background:#f8fafc;border-top:1px solid #e2e8f0;">
          <span class="m" style="font-weight:800;color:#0f172a;">Total</span>
          <span class="n odb-n-blue"><%=mTotalP%></span>
          <span class="n odb-n-purple"><%=mTotalH%></span>
        </div>
      </div>
    </div>

    <div class="odb-card">
      <div class="odb-card-hdr">
        <div class="odb-card-title">Weekly Hires</div>
        <div class="odb-card-sub">Last 8 weeks hired</div>
      </div>
      <div class="odb-card-body">
        <% if (byWeek.isEmpty()) { %>
        <div class="odb-row" style="color:#94a3b8;">No hires yet.</div>
        <% } %>
        <% int wTotal=0, wIdx=0;
           for (String[] w : byWeek) {
             if (wIdx++ >= 8) break;
             int wc = Integer.parseInt(w[2]); wTotal += wc;
        %>
        <div class="odb-row">
          <span class="m"><%=esc(w[1])%></span>
          <span class="n odb-n-purple"><%=wc%></span>
        </div>
        <% } %>
        <% if (!byWeek.isEmpty()) { %>
        <div class="odb-row" style="background:#f8fafc;border-top:1px solid #e2e8f0;">
          <span class="m" style="font-weight:800;color:#0f172a;">Total</span>
          <span class="n odb-n-purple"><%=wTotal%></span>
        </div>
        <% } %>
      </div>
    </div>

    <div class="odb-card">
      <div class="odb-card-hdr">
        <div class="odb-card-title">Hired DAs &nbsp;<span style="color:#7c3aed;"><%=totalHired%></span></div>
        <div class="odb-card-sub">All time &mdash; completed onboarding</div>
      </div>
      <div class="odb-card-body">
        <% if (hiredRows.isEmpty()) { %>
        <div class="odb-hired" style="color:#94a3b8;font-size:13px;">No completed hires yet.</div>
        <% } %>
        <% for (Map<String,String> h : hiredRows) {
             String fn = h.get("first_name"); String ln = h.get("last_name");
             if (fn == null) fn = ""; if (ln == null) ln = "";
             String initials = (fn.length()>0?fn.substring(0,1):"") + (ln.length()>0?ln.substring(0,1):"");
             String avail = h.get("avail_type"); if (avail == null) avail = "";
        %>
        <div class="odb-hired">
          <div class="odb-av"><%=esc(initials.toUpperCase())%></div>
          <div style="min-width:0;flex:1;">
            <div class="odb-hn"><%=esc(fn)%> <%=esc(ln)%></div>
            <div class="odb-hm">Day 1: <%=h.get("s9_day1_date")==null||h.get("s9_day1_date").isEmpty()?"-":esc(h.get("s9_day1_date"))%></div>
          </div>
          <div style="font-size:12px;color:#94a3b8;text-align:right;flex-shrink:0;"><%=esc(avail.replace("_"," "))%></div>
        </div>
        <% } %>
      </div>
    </div>
  </div>
</div>

<%@ include file="includeFooter.jsp"%>
</html>
