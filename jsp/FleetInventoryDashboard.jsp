<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"
         import="java.sql.*,javax.sql.*,javax.naming.*,java.util.*,java.text.*,com.util.*,com.beans.*" %>
<%!
  String gp(HttpServletRequest req, String n) {
    String v = req.getParameter(n); return v == null ? "" : v.trim();
  }
  String esc(String s) {
    if (s == null) return "";
    return s.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;");
  }
  String jesc(String s) {
    if (s == null) return "";
    StringBuilder o = new StringBuilder();
    for (int i = 0; i < s.length(); i++) {
      char c = s.charAt(i);
      if (c == '"' || c == '\\') o.append('\\').append(c);
      else if (c == '\n') o.append("\\n");
      else if (c == '\r') o.append("\\r");
      else if (c == '\t') o.append("\\t");
      else if (c < 32) { /* skip */ }
      else o.append(c);
    }
    return o.toString();
  }
  String nz(String s) { return s == null ? "" : s.trim(); }
  String ownLabel(String o) {
    if (o == null || o.isEmpty()) return "Unknown";
    String u = o.toUpperCase();
    if (u.contains("RENTAL")) return "Rental";
    if (u.contains("AMAZON")) return "Branded";
    return o;
  }
%>
<%
  String fidLoginUser   = request.getAttribute("loginUser") != null ? request.getAttribute("loginUser").toString() : (String) session.getAttribute("loginUser");
  String fidLoginRoles  = request.getAttribute("loginUserRoles") != null ? request.getAttribute("loginUserRoles").toString() : (String) session.getAttribute("loginUserRoles");
  String fidEntityID    = request.getAttribute("entityID") != null ? request.getAttribute("entityID").toString() : (session.getAttribute("entityID") != null ? session.getAttribute("entityID").toString() : "1");
  String fidDispName    = request.getAttribute("loginUserDisplayName") != null ? request.getAttribute("loginUserDisplayName").toString() : (session.getAttribute("loginUserDisplayName") != null ? session.getAttribute("loginUserDisplayName").toString() : "");
  String fidLoginUserID = request.getAttribute("loginUserID") != null ? request.getAttribute("loginUserID").toString() : (session.getAttribute("loginUserID") != null ? session.getAttribute("loginUserID").toString() : "");
  if (fidLoginUser == null) fidLoginUser = "";
  if (fidLoginRoles == null) fidLoginRoles = "";
  if (fidDispName == null || fidDispName.isEmpty()) fidDispName = fidLoginUser;
  if (fidEntityID == null || fidEntityID.isEmpty()) fidEntityID = "1";

  int idleDays = 14;
  try { idleDays = Integer.parseInt(gp(request, "idleDays")); } catch (Exception ignore) {}
  if (idleDays != 7 && idleDays != 14 && idleDays != 30) idleDays = 14;

  Connection conn = null;
  String dbError = "";
  StringBuilder json = new StringBuilder();

  int total = 0, operational = 0, grounded = 0, inactive = 0, outRepair = 0;
  int rental = 0, branded = 0, unknownOwn = 0;
  int idleRentals = 0, usedRentals = 0;
  int openRepairs = 0, closedRepairs = 0;
  int pmOverdue = 0, pmDue14 = 0, pmDue30 = 0;
  int reg30 = 0, reg60 = 0, reg90 = 0;
  int damageInc = 0, vehicleWriteups = 0;
  int paveDone = 0, paveNever = 0;
  double repairCostSum = 0;
  int repairCostRows = 0;
  int avgDaysUp = 0, daysUpN = 0;

  try {
    Context ictx = new InitialContext();
    DataSource ds = (DataSource) ictx.lookup("java:comp/env/jdbc/MVPGDB");
    conn = ds.getConnection();

    /* self-heal PAVE table for future imports */
    try {
      conn.createStatement().execute(
        "CREATE TABLE IF NOT EXISTS vehicle_pave ("
        + "PAVEID INT NOT NULL AUTO_INCREMENT PRIMARY KEY,"
        + "VEHICLEID INT NOT NULL,"
        + "ENTITYID INT NULL,"
        + "PAVE_DATE DATETIME NULL,"
        + "SCORE VARCHAR(40) NULL,"
        + "CONDITION_BAND VARCHAR(40) NULL,"
        + "NOTES VARCHAR(500) NULL,"
        + "CREATE_USER VARCHAR(50) NULL,"
        + "CREATE_DATE DATETIME NULL,"
        + "STATUS INT DEFAULT 0,"
        + "KEY idx_veh (VEHICLEID), KEY idx_date (PAVE_DATE)"
        + ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");
    } catch (Exception ignore) {}

    /* ── vehicle universe ── */
    String vehSql =
      "SELECT V.VEHICLEID, IFNULL(V.VEHICLENUMBER,''), IFNULL(V.VINNUMBER,''), IFNULL(V.LICENSEPLATE,''),"
      + " IFNULL(V.OWNERSHIPTYPE,''), IFNULL(V.PROVIDER,''), IFNULL(V.SERVICETIER,''),"
      + " IFNULL(V.OPERATIONALSTATUS,0), IFNULL(V.STATUS,0), IFNULL(V.OUT_FOR_REPAIR,0),"
      + " IFNULL(V.STATUSREASONCODE,''), IFNULL(V.STATUSREASONMSG,''),"
      + " DATE_FORMAT(V.REGISTRATIONEXPIRY,'%Y-%m-%d'),"
      + " (SELECT DATE_FORMAT(MAX(COALESCE(L.COMPLETED_DATE,L.SERVICE_DATE)),'%Y-%m-%d')"
      + "    FROM vehicle_maintenance_log L"
      + "   WHERE L.VEHICLEID=V.VEHICLEID AND L.STATUS=0"
      + "     AND (L.STATUS_BEFORE=1 OR IFNULL(L.GROUNDED_REASON,'')!=''"
      + "          OR L.MAINT_CODE IN ('DEALER_REPAIR','MAJOR_DEALER_REPAIR','TOW','MAJOR_AUTOBODY'))) AS LAST_DOWN,"
      + " (SELECT DATE_FORMAT(MAX(P.PAVE_DATE),'%Y-%m-%d') FROM vehicle_pave P"
      + "   WHERE P.VEHICLEID=V.VEHICLEID AND P.STATUS=0) AS LAST_PAVE,"
      + " (SELECT P.CONDITION_BAND FROM vehicle_pave P"
      + "   WHERE P.VEHICLEID=V.VEHICLEID AND P.STATUS=0 ORDER BY P.PAVE_DATE DESC LIMIT 1) AS FLEET_COND"
      + " FROM vehicle V WHERE V.ENTITYID=? AND V.STATUS IN (0,4)";

    PreparedStatement ps = conn.prepareStatement(vehSql);
    ps.setInt(1, Integer.parseInt(fidEntityID));
    ResultSet rs = ps.executeQuery();

    StringBuilder vehArr = new StringBuilder("[");
    int vn = 0;
    java.util.Date today = new java.util.Date();
    SimpleDateFormat ymd = new SimpleDateFormat("yyyy-MM-dd");

    Set<Integer> rentalIds = new HashSet<Integer>();
    Map<Integer, String[]> vehMeta = new HashMap<Integer, String[]>();

    while (rs.next()) {
      int id = rs.getInt(1);
      String num = nz(rs.getString(2));
      String vin = nz(rs.getString(3));
      String plate = nz(rs.getString(4));
      String own = nz(rs.getString(5));
      String prov = nz(rs.getString(6));
      String tier = nz(rs.getString(7));
      int op = rs.getInt(8);
      int st = rs.getInt(9);
      int ofr = rs.getInt(10);
      String rcode = nz(rs.getString(11));
      String rmsg = nz(rs.getString(12));
      String regExp = nz(rs.getString(13));
      String lastDown = nz(rs.getString(14));
      String lastPave = nz(rs.getString(15));
      String cond = nz(rs.getString(16));
      String ownL = ownLabel(own);

      total++;
      if (st == 4) inactive++;
      else if (op == 1) grounded++;
      else operational++;
      if (ofr == 1) outRepair++;
      if ("Rental".equals(ownL)) { rental++; rentalIds.add(id); }
      else if ("Branded".equals(ownL)) branded++;
      else unknownOwn++;

      Integer daysUp = null;
      if (op == 0 && st == 0 && lastDown.length() >= 10) {
        try {
          long d = (today.getTime() - ymd.parse(lastDown).getTime()) / 86400000L;
          daysUp = (int) d;
          avgDaysUp += daysUp; daysUpN++;
        } catch (Exception ignore) {}
      }

      if (regExp.length() >= 10) {
        try {
          long d = (ymd.parse(regExp).getTime() - today.getTime()) / 86400000L;
          if (d >= 0 && d <= 30) reg30++;
          if (d >= 0 && d <= 60) reg60++;
          if (d >= 0 && d <= 90) reg90++;
        } catch (Exception ignore) {}
      }

      if (lastPave.length() >= 10) paveDone++; else paveNever++;

      vehMeta.put(id, new String[]{ num, vin, ownL, prov });

      if (vn++ > 0) vehArr.append(',');
      vehArr.append("{")
        .append("\"id\":").append(id)
        .append(",\"num\":\"").append(jesc(num)).append("\"")
        .append(",\"vin\":\"").append(jesc(vin)).append("\"")
        .append(",\"plate\":\"").append(jesc(plate)).append("\"")
        .append(",\"own\":\"").append(jesc(ownL)).append("\"")
        .append(",\"prov\":\"").append(jesc(prov)).append("\"")
        .append(",\"tier\":\"").append(jesc(tier)).append("\"")
        .append(",\"op\":").append(op)
        .append(",\"st\":").append(st)
        .append(",\"ofr\":").append(ofr)
        .append(",\"rcode\":\"").append(jesc(rcode)).append("\"")
        .append(",\"rmsg\":\"").append(jesc(rmsg)).append("\"")
        .append(",\"reg\":\"").append(jesc(regExp)).append("\"")
        .append(",\"lastDown\":\"").append(jesc(lastDown)).append("\"")
        .append(",\"daysUp\":").append(daysUp == null ? "null" : daysUp.toString())
        .append(",\"pave\":\"").append(jesc(lastPave)).append("\"")
        .append(",\"cond\":\"").append(jesc(cond)).append("\"")
        .append("}");
    }
    rs.close(); ps.close();
    vehArr.append("]");
    if (daysUpN > 0) avgDaysUp = Math.round(avgDaysUp * 1f / daysUpN);

    /* idle rentals */
    Set<Integer> used = new HashSet<Integer>();
    ps = conn.prepareStatement(
      "SELECT DISTINCT VEHICLEID FROM dacheckin WHERE STATUS=0 AND VEHICLEID IS NOT NULL"
      + " AND CLOCKINTIME >= DATE_SUB(CURDATE(), INTERVAL ? DAY)");
    ps.setInt(1, idleDays);
    rs = ps.executeQuery();
    while (rs.next()) used.add(rs.getInt(1));
    rs.close(); ps.close();
    StringBuilder idleArr = new StringBuilder("[");
    int idleN = 0;
    for (Integer rid : rentalIds) {
      if (used.contains(rid)) usedRentals++;
      else {
        idleRentals++;
        if (idleN++ > 0) idleArr.append(',');
        idleArr.append(rid);
      }
    }
    idleArr.append("]");

    /* maintenance */
    StringBuilder maintArr = new StringBuilder("[");
    int mn = 0;
    Map<String, int[]> issueOwn = new LinkedHashMap<String, int[]>(); // issue -> [total, rental, branded]
    Map<String, Integer> byCode = new LinkedHashMap<String, Integer>();
    ps = conn.prepareStatement(
      "SELECT L.MAINT_LOGID, L.VEHICLEID, IFNULL(L.MAINT_CODE,''), IFNULL(L.DESCRIPTION,''),"
      + " DATE_FORMAT(L.SERVICE_DATE,'%Y-%m-%d'), IFNULL(L.IS_OPEN,0), IFNULL(L.SHOP_VENDOR,''),"
      + " IFNULL(L.COST,0), IFNULL(L.NEXT_SERVICE_DATE IS NOT NULL AND L.NEXT_SERVICE_DATE < CURDATE(),0),"
      + " DATE_FORMAT(L.NEXT_SERVICE_DATE,'%Y-%m-%d'), IFNULL(L.GROUNDED_REASON,''),"
      + " IFNULL(V.VEHICLENUMBER,''), IFNULL(V.OWNERSHIPTYPE,''), IFNULL(V.STATUSREASONMSG,'')"
      + " FROM vehicle_maintenance_log L"
      + " JOIN vehicle V ON V.VEHICLEID=L.VEHICLEID"
      + " WHERE L.STATUS=0 AND V.ENTITYID=? AND V.STATUS IN (0,4)"
      + " ORDER BY L.SERVICE_DATE DESC LIMIT 2000");
    ps.setInt(1, Integer.parseInt(fidEntityID));
    rs = ps.executeQuery();
    while (rs.next()) {
      int open = rs.getInt(6);
      if (open == 1) openRepairs++; else closedRepairs++;
      String code = nz(rs.getString(3));
      byCode.put(code, byCode.getOrDefault(code, 0) + 1);
      double cost = rs.getDouble(8);
      if (cost > 0) { repairCostSum += cost; repairCostRows++; }
      if (rs.getInt(9) == 1) pmOverdue++;
      String nextSvc = nz(rs.getString(10));
      if (nextSvc.length() >= 10) {
        try {
          long d = (ymd.parse(nextSvc).getTime() - today.getTime()) / 86400000L;
          if (d >= 0 && d <= 14) pmDue14++;
          if (d >= 0 && d <= 30) pmDue30++;
        } catch (Exception ignore) {}
      }
      String issue = nz(rs.getString(14));
      if (issue.isEmpty()) issue = nz(rs.getString(11));
      if (issue.isEmpty() && code.length() > 0) issue = code;
      if (!issue.isEmpty()) {
        String key = issue.length() > 80 ? issue.substring(0, 80) : issue;
        int[] a = issueOwn.get(key);
        if (a == null) { a = new int[]{0,0,0}; issueOwn.put(key, a); }
        a[0]++;
        String ol = ownLabel(rs.getString(13));
        if ("Rental".equals(ol)) a[1]++; else if ("Branded".equals(ol)) a[2]++;
      }
      if (mn++ > 0) maintArr.append(',');
      maintArr.append("{")
        .append("\"id\":").append(rs.getInt(1))
        .append(",\"vid\":").append(rs.getInt(2))
        .append(",\"code\":\"").append(jesc(code)).append("\"")
        .append(",\"desc\":\"").append(jesc(nz(rs.getString(4)))).append("\"")
        .append(",\"dt\":\"").append(jesc(nz(rs.getString(5)))).append("\"")
        .append(",\"open\":").append(open)
        .append(",\"shop\":\"").append(jesc(nz(rs.getString(7)))).append("\"")
        .append(",\"cost\":").append(cost)
        .append(",\"next\":\"").append(jesc(nextSvc)).append("\"")
        .append(",\"num\":\"").append(jesc(nz(rs.getString(12)))).append("\"")
        .append(",\"own\":\"").append(jesc(ownLabel(rs.getString(13)))).append("\"")
        .append("}");
    }
    rs.close(); ps.close();
    maintArr.append("]");

    /* common issues JSON */
    List<Map.Entry<String,int[]>> issueList = new ArrayList<Map.Entry<String,int[]>>(issueOwn.entrySet());
    Collections.sort(issueList, new Comparator<Map.Entry<String,int[]>>() {
      public int compare(Map.Entry<String,int[]> a, Map.Entry<String,int[]> b) {
        return Integer.compare(b.getValue()[0], a.getValue()[0]);
      }
    });
    StringBuilder issuesArr = new StringBuilder("[");
    for (int i = 0; i < issueList.size() && i < 40; i++) {
      Map.Entry<String,int[]> e = issueList.get(i);
      if (i > 0) issuesArr.append(',');
      issuesArr.append("{\"issue\":\"").append(jesc(e.getKey())).append("\"")
        .append(",\"n\":").append(e.getValue()[0])
        .append(",\"r\":").append(e.getValue()[1])
        .append(",\"b\":").append(e.getValue()[2]).append("}");
    }
    issuesArr.append("]");

    StringBuilder codeArr = new StringBuilder("[");
    int ci = 0;
    for (Map.Entry<String,Integer> e : byCode.entrySet()) {
      if (ci++ > 0) codeArr.append(',');
      codeArr.append("{\"code\":\"").append(jesc(e.getKey())).append("\",\"n\":").append(e.getValue()).append("}");
    }
    codeArr.append("]");

    /* damage incidents */
    StringBuilder dmgArr = new StringBuilder("[");
    int dn = 0;
    ps = conn.prepareStatement(
      "SELECT I.INCIDENTSID, DATE_FORMAT(I.INCIDENT_DATE,'%Y-%m-%d'), IFNULL(T.TYPE,''),"
      + " IFNULL(E.FULLNAME,''), IFNULL(V.VEHICLENUMBER,''), IFNULL(V.OWNERSHIPTYPE,''),"
      + " IFNULL(I.DESCRIPTION,''), I.VEHICLEID"
      + " FROM incidents I"
      + " LEFT JOIN incidenttype T ON T.INCIDENTTYPEID=I.INCIDENTTYPEID"
      + " LEFT JOIN employee E ON E.EMPLOYEEID=I.EMPLOYEEID"
      + " LEFT JOIN vehicle V ON V.VEHICLEID=I.VEHICLEID"
      + " WHERE I.STATUS!=1 AND I.VEHICLEID IS NOT NULL AND I.VEHICLEID!=0"
      + " AND (T.TYPE LIKE '%Vehicle Damage%' OR T.TYPE LIKE '%Accident%'"
      + "   OR T.TYPE LIKE '%Property Damage%' OR T.TYPE LIKE '%Vehicle Issues%'"
      + "   OR T.TYPE LIKE '%Property Damages%')"
      + " AND I.INCIDENT_DATE >= DATE_SUB(CURDATE(), INTERVAL 180 DAY)"
      + " ORDER BY I.INCIDENT_DATE DESC LIMIT 800");
    rs = ps.executeQuery();
    while (rs.next()) {
      damageInc++;
      if (dn++ > 0) dmgArr.append(',');
      dmgArr.append("{")
        .append("\"id\":").append(rs.getInt(1))
        .append(",\"dt\":\"").append(jesc(nz(rs.getString(2)))).append("\"")
        .append(",\"type\":\"").append(jesc(nz(rs.getString(3)))).append("\"")
        .append(",\"da\":\"").append(jesc(nz(rs.getString(4)))).append("\"")
        .append(",\"num\":\"").append(jesc(nz(rs.getString(5)))).append("\"")
        .append(",\"own\":\"").append(jesc(ownLabel(rs.getString(6)))).append("\"")
        .append(",\"desc\":\"").append(jesc(nz(rs.getString(7)))).append("\"")
        .append("}");
    }
    rs.close(); ps.close();
    dmgArr.append("]");

    /* vehicle write-ups (employee forms) */
    StringBuilder wuArr = new StringBuilder("[");
    int wn = 0;
    ps = conn.prepareStatement(
      "SELECT F.EMPLOYEEFORMSID, DATE_FORMAT(F.CREATE_DATE,'%Y-%m-%d'), IFNULL(T.FORMTYPE,''),"
      + " IFNULL(E.FULLNAME,''), IFNULL(F.COMMENTS,'')"
      + " FROM employeeforms F"
      + " JOIN formstemplate T ON F.FORMSTEMPLATEID=T.FORMSTEMPLATEID"
      + " LEFT JOIN employee E ON E.EMPLOYEEID=F.EMPLOYEEID"
      + " WHERE F.STATUS!=1 AND T.FORMTYPE LIKE '%Vehicle%'"
      + " AND F.CREATE_DATE >= DATE_SUB(CURDATE(), INTERVAL 180 DAY)"
      + " ORDER BY F.CREATE_DATE DESC LIMIT 400");
    rs = ps.executeQuery();
    while (rs.next()) {
      vehicleWriteups++;
      if (wn++ > 0) wuArr.append(',');
      wuArr.append("{")
        .append("\"id\":").append(rs.getInt(1))
        .append(",\"dt\":\"").append(jesc(nz(rs.getString(2)))).append("\"")
        .append(",\"type\":\"").append(jesc(nz(rs.getString(3)))).append("\"")
        .append(",\"da\":\"").append(jesc(nz(rs.getString(4)))).append("\"")
        .append(",\"desc\":\"").append(jesc(nz(rs.getString(5)))).append("\"")
        .append("}");
    }
    rs.close(); ps.close();
    wuArr.append("]");

    json.append("{")
      .append("\"idleDays\":").append(idleDays).append(",")
      .append("\"kpis\":{")
      .append("\"total\":").append(total)
      .append(",\"operational\":").append(operational)
      .append(",\"grounded\":").append(grounded)
      .append(",\"inactive\":").append(inactive)
      .append(",\"outRepair\":").append(outRepair)
      .append(",\"rental\":").append(rental)
      .append(",\"branded\":").append(branded)
      .append(",\"unknownOwn\":").append(unknownOwn)
      .append(",\"idleRentals\":").append(idleRentals)
      .append(",\"usedRentals\":").append(usedRentals)
      .append(",\"utilPct\":").append(rental == 0 ? 0 : Math.round(usedRentals * 100.0 / rental))
      .append(",\"openRepairs\":").append(openRepairs)
      .append(",\"closedRepairs\":").append(closedRepairs)
      .append(",\"pmOverdue\":").append(pmOverdue)
      .append(",\"pmDue14\":").append(pmDue14)
      .append(",\"pmDue30\":").append(pmDue30)
      .append(",\"reg30\":").append(reg30)
      .append(",\"reg60\":").append(reg60)
      .append(",\"reg90\":").append(reg90)
      .append(",\"damageInc\":").append(damageInc)
      .append(",\"writeups\":").append(vehicleWriteups)
      .append(",\"avgDaysUp\":").append(avgDaysUp)
      .append(",\"paveDone\":").append(paveDone)
      .append(",\"paveNever\":").append(paveNever)
      .append(",\"repairCostSum\":").append(String.format(Locale.US, "%.2f", repairCostSum))
      .append(",\"repairCostRows\":").append(repairCostRows)
      .append("},")
      .append("\"idleIds\":").append(idleArr).append(",")
      .append("\"vehicles\":").append(vehArr).append(",")
      .append("\"maint\":").append(maintArr).append(",")
      .append("\"issues\":").append(issuesArr).append(",")
      .append("\"byCode\":").append(codeArr).append(",")
      .append("\"damage\":").append(dmgArr).append(",")
      .append("\"writeups\":").append(wuArr)
      .append("}");

  } catch (Exception ex) {
    dbError = ex.getMessage() == null ? ex.toString() : ex.getMessage();
    json = new StringBuilder("{\"kpis\":{},\"idleIds\":[],\"vehicles\":[],\"maint\":[],\"issues\":[],\"byCode\":[],\"damage\":[],\"writeups\":[]}");
  } finally {
    try { if (conn != null) conn.close(); } catch (Exception ignore) {}
  }

  if (fidLoginUser.isEmpty()) {
    response.sendRedirect(request.getContextPath() + "/servlet/MVPGServlet?submitType=11&controller=Login");
    return;
  }
%>
<jsp:useBean id="_recordBean" class="com.beans.SearchBean" scope="request" />
<jsp:useBean id="_errorBean" class="com.beans.ErrorBean" scope="request" />
<%
int submitType = SubmitType.SEARCH;
_recordBean.setController("FleetInventoryDashboard");
_recordBean.setDisplayName("Fleet Inventory");
request.setAttribute("loginUser", fidLoginUser);
request.setAttribute("loginUserRoles", fidLoginRoles);
request.setAttribute("entityID", fidEntityID);
request.setAttribute("loginUserDisplayName", fidDispName);
request.setAttribute("loginUserID", fidLoginUserID);
request.setAttribute("shellNoForm", "yes");
request.setAttribute("hideTopbarSearch", "yes");
%>
<!DOCTYPE html>
<html lang="en">
<%@ include file="includeHeader.jsp"%>
<script>function validatePageData(s,v){return v;}</script>
<style>
.fid-shell{display:flex;flex-direction:column;gap:10px;padding-bottom:20px}
.fid-hd{display:flex;align-items:center;gap:10px;flex-wrap:wrap}
.fid-hd h1{margin:0;font-size:20px;font-weight:800;letter-spacing:-.02em;color:#0F172A}
.fid-hd .sub{font-size:12px;color:#64748B}
.fid-hd .sp{margin-left:auto;display:flex;gap:6px;align-items:center;flex-wrap:wrap}
.fid-hd select{border:1px solid #E2E8F0;border-radius:7px;padding:5px 8px;font-size:12.5px;background:#fff}
.fid-kpis{display:grid;grid-template-columns:repeat(6,1fr);gap:8px}
@media(max-width:1200px){.fid-kpis{grid-template-columns:repeat(3,1fr)}}
@media(max-width:700px){.fid-kpis{grid-template-columns:repeat(2,1fr)}}
.fid-kpi{background:#fff;border:1px solid #E2E8F0;border-radius:10px;padding:10px 12px;cursor:pointer;transition:border-color .12s,box-shadow .12s}
.fid-kpi:hover,.fid-kpi.on{border-color:#2563EB;box-shadow:0 0 0 3px #DBEAFE}
.fid-kpi .l{font-size:10px;font-weight:700;letter-spacing:.08em;text-transform:uppercase;color:#64748B}
.fid-kpi .n{font-size:24px;font-weight:800;color:#0F172A;line-height:1.15;margin-top:2px}
.fid-kpi .s{font-size:11px;color:#94A3B8;margin-top:2px}
.fid-kpi.warn .n{color:var(--status-warn-fg)}
.fid-kpi.bad .n{color:var(--status-action-fg)}
.fid-kpi.ok .n{color:var(--status-ok-fg)}
.fid-kpi.soon{opacity:.72;border-style:dashed}
.fid-grid{display:grid;grid-template-columns:1.2fr .8fr;gap:10px}
@media(max-width:1000px){.fid-grid{grid-template-columns:1fr}}
.fid-card{background:#fff;border:1px solid #E2E8F0;border-radius:10px;padding:12px 14px;min-width:0}
.fid-card h3{margin:0 0 10px;font-size:11px;font-weight:700;letter-spacing:.1em;text-transform:uppercase;color:#64748B;display:flex;align-items:center;gap:8px}
.fid-card h3 button{margin-left:auto;border:1px solid #E2E8F0;background:#fff;border-radius:6px;padding:3px 8px;font-size:11px;font-weight:600;cursor:pointer}
.fid-bar{display:flex;align-items:center;gap:8px;margin:6px 0;font-size:12.5px;cursor:pointer}
.fid-bar:hover .nm{color:#2563EB}
.fid-bar .nm{flex:1;min-width:0;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;font-weight:600;color:#0F172A}
.fid-bar .tr{width:110px;height:8px;background:#F1F5F9;border-radius:4px;overflow:hidden;flex-shrink:0}
.fid-bar .fl{height:100%;background:#2563EB;border-radius:4px}
.fid-bar .cnt{width:34px;text-align:right;font-variant-numeric:tabular-nums;color:#475569;font-weight:700;flex-shrink:0}
.fid-pill{display:inline-flex;gap:4px;font-size:11px;color:#64748B}
.fid-pill b{color:#0F172A}
.fid-drill{background:#fff;border:1px solid #E2E8F0;border-radius:10px;overflow:hidden;display:none}
.fid-drill.on{display:block}
.fid-drill-hd{display:flex;align-items:center;gap:10px;padding:10px 12px;border-bottom:1px solid #E2E8F0;background:#FAFBFC}
.fid-drill-hd h2{margin:0;font-size:15px;font-weight:700;color:#0F172A}
.fid-drill-hd .meta{font-size:12px;color:#64748B}
.fid-drill-hd button{margin-left:auto;border:1px solid #E2E8F0;background:#fff;border-radius:7px;padding:4px 10px;font-size:12px;cursor:pointer}
.fid-tbl-wrap{max-height:420px;overflow:auto}
.fid-tbl{width:100%;border-collapse:collapse}
.fid-tbl th{position:sticky;top:0;background:#F8FAFC;font-size:10px;letter-spacing:.06em;text-transform:uppercase;color:#64748B;text-align:left;padding:8px 10px;border-bottom:1px solid #E2E8F0;white-space:nowrap}
.fid-tbl td{padding:7px 10px;border-bottom:1px solid #F1F5F9;font-size:13px;color:#0F172A;vertical-align:top}
.fid-tbl tr:hover td{background:#F8FAFC}
.fid-empty{padding:28px;text-align:center;color:#94A3B8;font-size:13px}
.fid-err{color:var(--status-action-fg);font-size:12px}
.fid-tag{display:inline-block;padding:1px 7px;border-radius:999px;font-size:11px;font-weight:700}
.fid-tag.op{background:var(--status-ok-bg);color:var(--status-ok-fg)}
.fid-tag.gr{background:var(--status-action-bg);color:var(--status-action-fg)}
.fid-tag.in{background:#F1F5F9;color:#475569}
.fid-tag.soon{background:var(--status-info-bg);color:var(--status-info-fg)}
</style>

<div class="fid-shell">
  <div class="fid-hd">
    <div>
      <h1>Fleet Inventory</h1>
      <div class="sub">DNK7 · live from vehicles, maintenance, check-ins &amp; incidents</div>
    </div>
    <div class="sp">
      <label style="font-size:12px;color:#64748B">Idle window</label>
      <select id="idleDays" onchange="location='?idleDays='+this.value">
        <option value="7" <%=idleDays==7?"selected":""%>>7 days</option>
        <option value="14" <%=idleDays==14?"selected":""%>>14 days</option>
        <option value="30" <%=idleDays==30?"selected":""%>>30 days</option>
      </select>
    </div>
  </div>
  <%if (dbError.length() > 0) {%><div class="fid-err">DB: <%=esc(dbError)%></div><%}%>

  <div class="fid-kpis" id="fidKpis"></div>

  <div class="fid-grid">
    <div class="fid-card">
      <h3>Common issues <span class="fid-pill">by van count · rental vs branded</span>
        <button type="button" onclick="fidDrill('issues')">Open table</button></h3>
      <div id="fidIssues"></div>
    </div>
    <div class="fid-card">
      <h3>Repairs by type
        <button type="button" onclick="fidDrill('byCode')">Open table</button></h3>
      <div id="fidCodes"></div>
    </div>
  </div>

  <div class="fid-drill" id="fidDrill">
    <div class="fid-drill-hd">
      <h2 id="fidDrillTitle">Drill-down</h2>
      <span class="meta" id="fidDrillMeta"></span>
      <button type="button" onclick="fidCloseDrill()">Close</button>
    </div>
    <div class="fid-tbl-wrap">
      <table class="fid-tbl" id="fidDrillTable">
        <thead id="fidDrillHead"></thead>
        <tbody id="fidDrillBody"></tbody>
      </table>
      <div class="fid-empty" id="fidDrillEmpty" style="display:none">No rows for this filter.</div>
    </div>
  </div>
</div>

<script>
var FID = <%=json.toString()%>;

function fidStatus(v){
  if (v.st === 4) return '<span class="fid-tag in">Inactive</span>';
  if (v.op === 1) return '<span class="fid-tag gr">Grounded</span>';
  return '<span class="fid-tag op">Operational</span>';
}
function fidMax(arr, key){
  var m = 1;
  arr.forEach(function(x){ if ((x[key]||0) > m) m = x[key]; });
  return m;
}
function fidBars(el, rows, labelKey, countKey, onClick){
  var max = fidMax(rows, countKey);
  var h = '';
  rows.slice(0, 12).forEach(function(r, i){
    var pct = Math.round(100 * (r[countKey]||0) / max);
    h += '<div class="fid-bar" data-i="'+i+'"><span class="nm">'+escHtml(r[labelKey]||'—')+'</span>'
      + '<span class="tr"><span class="fl" style="width:'+pct+'%"></span></span>'
      + '<span class="cnt">'+(r[countKey]||0)+'</span></div>';
  });
  if (!rows.length) h = '<div class="fid-empty">No data yet</div>';
  el.innerHTML = h;
  [].forEach.call(el.querySelectorAll('.fid-bar'), function(b){
    b.onclick = function(){ onClick(rows[+b.getAttribute('data-i')]); };
  });
}
function escHtml(s){
  return String(s||'').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');
}

function fidRenderKpis(){
  var k = FID.kpis || {};
  var cards = [
    {key:'total', label:'Total fleet', n:k.total, s:'all active + inactive', cls:''},
    {key:'operational', label:'Operational', n:k.operational, s:k.total?(Math.round(100*k.operational/k.total)+'% of fleet'):'', cls:'ok'},
    {key:'grounded', label:'Grounded', n:k.grounded, s:'click for vans', cls:k.grounded?'bad':''},
    {key:'outRepair', label:'Out for repair', n:k.outRepair, s:'at dealer / shop', cls:k.outRepair?'warn':''},
    {key:'idleRentals', label:'Idle rentals', n:k.idleRentals, s:'no check-in · '+FID.idleDays+'d', cls:k.idleRentals?'warn':''},
    {key:'utilPct', label:'Rental utilization', n:(k.utilPct||0)+'%', s:(k.usedRentals||0)+' of '+(k.rental||0)+' used', cls:''},
    {key:'openRepairs', label:'Open repairs', n:k.openRepairs, s:(k.closedRepairs||0)+' closed on file', cls:k.openRepairs?'warn':''},
    {key:'pmOverdue', label:'PM overdue', n:k.pmOverdue, s:(k.pmDue14||0)+' due in 14d', cls:k.pmOverdue?'bad':''},
    {key:'reg30', label:'Reg. expiring 30d', n:k.reg30, s:(k.reg90||0)+' within 90d', cls:k.reg30?'warn':''},
    {key:'avgDaysUp', label:'Avg days up', n:k.avgDaysUp, s:'since last grounded', cls:'ok'},
    {key:'damageInc', label:'DA damage / incidents', n:k.damageInc, s:(k.writeups||0)+' vehicle write-ups · 180d', cls:k.damageInc?'warn':''},
    {key:'pave', label:'Last PAVE', n:k.paveDone||0, s:(k.paveNever||0)+' never · awaiting import', cls:'soon', soon:true},
    {key:'cost', label:'Repair cost', n: k.repairCostRows ? ('$'+Number(k.repairCostSum).toLocaleString()) : '—', s: k.repairCostRows ? (k.repairCostRows+' jobs with $') : 'awaiting cost data', cls:'soon', soon:true}
  ];
  var h = '';
  cards.forEach(function(c){
    h += '<div class="fid-kpi '+(c.cls||'')+(c.soon?' soon':'')+'" data-key="'+c.key+'">'
      + '<div class="l">'+c.label+(c.soon?' <span class="fid-tag soon">soon</span>':'')+'</div>'
      + '<div class="n">'+c.n+'</div><div class="s">'+escHtml(c.s)+'</div></div>';
  });
  var box = document.getElementById('fidKpis');
  box.innerHTML = h;
  [].forEach.call(box.querySelectorAll('.fid-kpi'), function(el){
    el.onclick = function(){
      [].forEach.call(box.querySelectorAll('.fid-kpi'), function(x){ x.classList.remove('on'); });
      el.classList.add('on');
      fidDrill(el.getAttribute('data-key'));
    };
  });
}

function fidVehFilter(pred){
  return (FID.vehicles||[]).filter(pred);
}
function fidMaintFilter(pred){
  return (FID.maint||[]).filter(pred);
}

function fidDrill(key, extra){
  var title = 'Drill-down', cols = [], rows = [];
  var k = FID.kpis || {};

  if (key === 'total') {
    title = 'All vehicles'; cols = ['Van','VIN','Ownership','Provider','Tier','Status','Reg expiry'];
    rows = fidVehFilter(function(){ return true; }).map(function(v){
      return [v.num, v.vin, v.own, v.prov, v.tier, fidStatus(v), v.reg||'—'];
    });
  } else if (key === 'operational') {
    title = 'Operational vans'; cols = ['Van','VIN','Ownership','Provider','Days up','Last grounded'];
    rows = fidVehFilter(function(v){ return v.st!==4 && v.op===0; }).map(function(v){
      return [v.num, v.vin, v.own, v.prov, v.daysUp==null?'—':v.daysUp, v.lastDown||'—'];
    });
  } else if (key === 'grounded') {
    title = 'Grounded vans'; cols = ['Van','VIN','Ownership','Provider','Reason code','Issue'];
    rows = fidVehFilter(function(v){ return v.st!==4 && v.op===1; }).map(function(v){
      return [v.num, v.vin, v.own, v.prov, v.rcode||'—', v.rmsg||'—'];
    });
  } else if (key === 'outRepair') {
    title = 'Out for repair'; cols = ['Van','VIN','Ownership','Provider','Issue'];
    rows = fidVehFilter(function(v){ return v.ofr===1; }).map(function(v){
      return [v.num, v.vin, v.own, v.prov, v.rmsg||'—'];
    });
  } else if (key === 'idleRentals' || key === 'utilPct') {
    title = (key==='idleRentals'?'Idle rentals':'Rental vans') + ' · '+FID.idleDays+'d window';
    cols = ['Van','VIN','Provider','Status','Tier'];
    var idleSet = {};
    (FID.idleIds||[]).forEach(function(id){ idleSet[id] = true; });
    var rentals = fidVehFilter(function(v){ return v.own==='Rental'; });
    if (key === 'idleRentals') {
      rows = rentals.filter(function(v){ return idleSet[v.id]; })
        .map(function(v){ return [v.num, v.vin, v.prov, fidStatus(v), v.tier]; });
    } else {
      rows = rentals.map(function(v){
        return [v.num, v.vin, v.prov, fidStatus(v) + (idleSet[v.id]?' · idle':''), v.tier];
      });
    }
  } else if (key === 'openRepairs') {
    title = 'Open repair jobs'; cols = ['Date','Van','Type','Shop','Own','Description'];
    rows = fidMaintFilter(function(m){ return m.open===1; }).map(function(m){
      return [m.dt||'—', m.num, m.code, m.shop||'—', m.own, m.desc||'—'];
    });
  } else if (key === 'pmOverdue') {
    title = 'PM overdue'; cols = ['Next PM','Van','Type','Own','Last service'];
    rows = fidMaintFilter(function(m){
      if (!m.next) return false;
      return m.next < new Date().toISOString().slice(0,10);
    }).map(function(m){ return [m.next, m.num, m.code, m.own, m.dt||'—']; });
  } else if (key === 'reg30' || key === 'reg60' || key === 'reg90') {
    var days = key==='reg30'?30:(key==='reg60'?60:90);
    title = 'Registration expiring in '+days+' days';
    cols = ['Reg expiry','Van','VIN','Ownership','Status'];
    var today = new Date(); today.setHours(0,0,0,0);
    rows = fidVehFilter(function(v){
      if (!v.reg) return false;
      var d = (new Date(v.reg+'T00:00:00') - today) / 86400000;
      return d >= 0 && d <= days;
    }).map(function(v){ return [v.reg, v.num, v.vin, v.own, fidStatus(v)]; });
  } else if (key === 'avgDaysUp') {
    title = 'Days up since last grounded';
    cols = ['Days up','Van','VIN','Ownership','Last grounded','Status'];
    rows = fidVehFilter(function(v){ return v.daysUp != null; })
      .sort(function(a,b){ return (b.daysUp||0)-(a.daysUp||0); })
      .map(function(v){ return [v.daysUp, v.num, v.vin, v.own, v.lastDown||'—', fidStatus(v)]; });
  } else if (key === 'damageInc') {
    title = 'DA-reported vehicle damage / incidents (180d)';
    cols = ['Date','Type','DA','Van','Own','Description'];
    rows = (FID.damage||[]).map(function(d){
      return [d.dt, d.type, d.da||'—', d.num||'—', d.own||'—', d.desc||'—'];
    });
    /* append write-ups */
    (FID.writeups||[]).forEach(function(w){
      rows.push([w.dt, 'Write-up: '+w.type, w.da||'—', '—', '—', w.desc||'—']);
    });
  } else if (key === 'issues') {
    title = 'Common issues';
    cols = ['Issue','Vehicles','Rental','Branded'];
    var issue = extra && extra.issue;
    if (issue) {
      title = 'Vehicles with issue: ' + issue;
      cols = ['Van','VIN','Ownership','Provider','Status','Issue'];
      rows = fidVehFilter(function(v){
        return (v.rmsg||'').indexOf(issue) >= 0 || (v.rcode||'') === issue;
      }).map(function(v){ return [v.num, v.vin, v.own, v.prov, fidStatus(v), v.rmsg||v.rcode||'—']; });
      if (!rows.length) {
        rows = (FID.issues||[]).filter(function(i){ return i.issue===issue; })
          .map(function(i){ return [i.issue, i.n, i.r, i.b]; });
        cols = ['Issue','Vehicles','Rental','Branded'];
      }
    } else {
      rows = (FID.issues||[]).map(function(i){ return [i.issue, i.n, i.r, i.b]; });
    }
  } else if (key === 'byCode') {
    title = 'Repairs by type';
    cols = ['Type','Count'];
    if (extra && extra.code) {
      title = 'Jobs: ' + extra.code;
      cols = ['Date','Van','Shop','Own','Open','Cost','Description'];
      rows = fidMaintFilter(function(m){ return m.code === extra.code; }).map(function(m){
        return [m.dt||'—', m.num, m.shop||'—', m.own, m.open?'Open':'Closed', m.cost||'—', m.desc||'—'];
      });
    } else {
      rows = (FID.byCode||[]).sort(function(a,b){ return b.n-a.n; })
        .map(function(c){ return [c.code||'(blank)', c.n]; });
    }
  } else if (key === 'pave') {
    title = 'PAVE status (awaiting PAVE import)';
    cols = ['Van','VIN','Ownership','Last PAVE','Condition'];
    rows = fidVehFilter(function(){ return true; }).map(function(v){
      return [v.num, v.vin, v.own, v.pave||'Never', v.cond||'—'];
    });
  } else if (key === 'cost') {
    title = 'Repair cost (awaiting cost data on jobs)';
    cols = ['Date','Van','Type','Shop','Cost','Description'];
    rows = fidMaintFilter(function(m){ return true; }).map(function(m){
      return [m.dt||'—', m.num, m.code, m.shop||'—', m.cost||'—', m.desc||'—'];
    });
  } else {
    title = key; cols = ['Info']; rows = [['No drill mapping yet']];
  }

  document.getElementById('fidDrillTitle').textContent = title;
  document.getElementById('fidDrillMeta').textContent = rows.length + ' row' + (rows.length===1?'':'s');
  var head = '<tr>' + cols.map(function(c){ return '<th>'+escHtml(c)+'</th>'; }).join('') + '</tr>';
  document.getElementById('fidDrillHead').innerHTML = head;
  var body = rows.map(function(r){
    return '<tr>' + r.map(function(c){ return '<td>'+ (String(c).indexOf('fid-tag')>=0 ? c : escHtml(c)) +'</td>'; }).join('') + '</tr>';
  }).join('');
  document.getElementById('fidDrillBody').innerHTML = body;
  document.getElementById('fidDrillEmpty').style.display = rows.length ? 'none' : 'block';
  document.getElementById('fidDrill').classList.add('on');
  document.getElementById('fidDrill').scrollIntoView({behavior:'smooth', block:'start'});
}
function fidCloseDrill(){ document.getElementById('fidDrill').classList.remove('on'); }

fidRenderKpis();
fidBars(document.getElementById('fidIssues'), FID.issues||[], 'issue', 'n', function(row){
  fidDrill('issues', row);
});
fidBars(document.getElementById('fidCodes'), (FID.byCode||[]).slice().sort(function(a,b){return b.n-a.n;}), 'code', 'n', function(row){
  fidDrill('byCode', row);
});
</script>
<%@ include file="includeFooter.jsp"%>
</html>
