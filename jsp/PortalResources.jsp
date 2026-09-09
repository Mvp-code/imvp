<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"
         import="java.util.*,java.sql.*,javax.sql.*,javax.naming.*,com.util.*,com.beans.*" %>
<%
  /* ── Amazon Portal Links — operator reference ──
     Where to go on logistics.amazon.com to get each data set, and where it
     lands in MVPx. Read-only. URLs discovered by the AMZL Bridge (Phase A).
     Station/company constants are DNK7 / MVPG. */
  String arLoginUser   = (request.getAttribute("loginUser") != null) ? request.getAttribute("loginUser").toString() : (String) session.getAttribute("loginUser");
  String arLoginRoles  = (request.getAttribute("loginUserRoles") != null) ? request.getAttribute("loginUserRoles").toString() : (String) session.getAttribute("loginUserRoles");
  String arEntityID    = (request.getAttribute("entityID") != null) ? request.getAttribute("entityID").toString() : (session.getAttribute("entityID") != null ? session.getAttribute("entityID").toString() : "1");
  String arDispName    = (request.getAttribute("loginUserDisplayName") != null) ? request.getAttribute("loginUserDisplayName").toString() : (session.getAttribute("loginUserDisplayName") != null ? session.getAttribute("loginUserDisplayName").toString() : "");
  String arLoginUserID = (request.getAttribute("loginUserID") != null) ? request.getAttribute("loginUserID").toString() : (session.getAttribute("loginUserID") != null ? session.getAttribute("loginUserID").toString() : "");
  if (arLoginUser == null)  arLoginUser  = "";
  if (arLoginRoles == null) arLoginRoles = "";
  if (arDispName == null || arDispName.length() == 0) arDispName = "User";
  if (arEntityID == null || arEntityID.length() == 0) arEntityID = "1";

  /* multi-station: use the most recently captured station/company/serviceAreaId
     (from amzl_station_map, learned automatically) — falls back to DNK7/MVPG. */
  String ST = "DNK7", CO = "b67abdb1-a16c-46db-b466-81c3a78e65aa", SA = "691a8008-aab2-4b9a-9201-7a56651b9fdb";
  try {
    Context prctx = new InitialContext();
    DataSource prds = (DataSource) prctx.lookup("java:comp/env/jdbc/MVPGDB");
    Connection prc = prds.getConnection();
    try {
      PreparedStatement prp = prc.prepareStatement(
          "SELECT SERVICE_AREA_ID, STATION_CODE, COMPANY_ID FROM amzl_station_map "
          + "WHERE STATION_CODE IS NOT NULL AND STATION_CODE<>'' ORDER BY UPDATE_DATE DESC LIMIT 1");
      ResultSet prr = prp.executeQuery();
      if (prr.next()) {
        if (prr.getString(2) != null && prr.getString(2).length() > 0) ST = prr.getString(2);
        if (prr.getString(1) != null && prr.getString(1).length() > 0) SA = prr.getString(1);
        if (prr.getString(3) != null && prr.getString(3).length() > 0) CO = prr.getString(3);
      }
      prr.close(); prp.close();
    } finally { prc.close(); }
  } catch (Exception prEx) { /* keep defaults */ }
  final String P  = "https://logistics.amazon.com/performance?station=" + ST + "&companyId=" + CO + "&navMenuVariant=external&timeFrame=Weekly&pageId=";

  /* group, portal location, url, what you get, MVPx destination */
  final String[][] LINKS = {
    {"Operations", "Route Itineraries (live stop progress)", "https://logistics.amazon.com/operations/execution/itineraries",
       "Live per-driver routes: stops done/total, pace, projected return, breaks, vehicle.", "Itineraries → daily_itineraries (live)"},

    {"Performance", "Dashboard Overview (Scorecard)", P + "dsp_dashboard_overview",
       "Per-DA weekly scorecard, 6-week performance, thresholds.", "Overview / 6-Week Perf / Thresholds"},
    {"Performance", "Safety", P + "dsp_safety",
       "Safety dashboard (OSS), intraday safety events.", "Safety"},
    {"Performance", "Quality", P + "dsp_quality",
       "Quality DCR/overview, RTS details + deep dive, CDF feedback, supplemental quality.", "Quality DCR / RTS / CDF / Suppl Quality"},
    {"Performance", "Delivery Concessions", P + "dsp_delivery_concessions",
       "DSB / concessions (DNR), scorecard disputes.", "Concessions"},
    {"Performance", "Mechanisms (Escalations / ORCAS)", P + "dsp_mechanisms",
       "Per-DA daily ORCAS events: severe/moderate violations, latest case #.", "Escalations (ORCAS)"},
    {"Performance", "Supplementary Reports", P + "dsp_supp_reports",
       "Weekly file exports: DVIC, DA Break Utilization, Tenure (calc + DAS), Compliance, Sentiment, daily PDFs.", "DVIC / Break Util / Tenure / Compliance / Sentiment"},

    {"Workforce", "DA Console — Associates", "https://logistics.amazon.com/workforce?pageId=da_console_associates&companyId=" + CO + "&station=" + ST,
       "Associate roster: name, email, phone, employeeId, positions, qualifications, status.", "Employees (AssociateData)"},
    {"Workforce", "DA Console — Attrition / Team / Tenure / Conversion", "https://logistics.amazon.com/workforce?pageId=da_console&companyId=" + CO + "&station=" + ST,
       "Attrition, team scorecard, tenure, conversion rate, avg onboarding time, URR.", "Attrition / Team / Conversion / URR"},

    {"Scheduling", "Weekly Schedule (Roster)", "https://logistics.amazon.com/scheduling/calendar-view/week?serviceAreaId=" + SA,
       "Full roster with per-day shift reservations (start, duration, service type).", "Schedule → employee schedule"},

    {"Administration", "Fleet — My Vehicles", "https://logistics.amazon.com/fleet-management/#vehicles",
       "Vehicle list: VIN, dspVehicleId, plate, make/model, status, provider, ownership, health.", "Vehicles → VEHICLE"}
  };

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
  _recordBean.setController("PortalResources");
  _recordBean.setDisplayName("Amazon Portal Links");
  int submitType = SubmitType.SEARCH;
%>
<!DOCTYPE html>
<html lang="en">
<%@ include file="includeHeader.jsp"%>
<script>
function validatePageData(submitType, isValid) { return isValid; }
</script>
<style>
.pr-shell{display:flex;flex-direction:column;height:calc(100vh - 96px);overflow:hidden}
.pr-hdr{display:flex;align-items:baseline;gap:12px;margin-bottom:8px;flex-shrink:0;flex-wrap:wrap}
.pr-hdr h1{font-size:18px;font-weight:900;color:#0f172a;margin:0}
.pr-hdr .sub{font-size:12px;color:#64748B}
.pr-flt{margin-left:auto}
.pr-flt input{border:1px solid #CBD5E1;border-radius:7px;padding:6px 10px;font-size:13px;min-width:220px}
.pr-wrap{flex:1;overflow:auto;border:1px solid #E4E8F0;border-radius:8px;background:#fff}
.pr-wrap table{width:100%;border-collapse:collapse}
.pr-wrap th{position:sticky;top:0;background:#F8FAFC;font-size:10px;text-transform:uppercase;letter-spacing:.04em;color:#64748B;text-align:left;padding:7px 10px;border-bottom:1px solid #E4E8F0;white-space:nowrap;z-index:2}
.pr-wrap td{font-size:12.5px;color:#1F2937;padding:8px 10px;border-bottom:1px solid #EEF1F6;vertical-align:top}
.pr-wrap tr:hover td{background:#F8FAFC}
.pr-grp{background:#F1F5F9 !important;font-weight:800;color:#0f172a;font-size:11px;text-transform:uppercase;letter-spacing:.05em}
.pr-loc{font-weight:700;color:#0f172a;white-space:nowrap}
.pr-get{color:#475569;max-width:420px}
.pr-dest{color:#065F46;font-size:11.5px;white-space:nowrap}
.pr-open{display:inline-block;text-decoration:none;border:1px solid #CBD5E1;border-radius:6px;padding:4px 10px;font-size:11.5px;font-weight:700;color:#0f172a;white-space:nowrap}
.pr-open:hover{background:#0f172a;color:#fff;border-color:#0f172a}
.pr-note{font-size:11.5px;color:#94A3B8;margin-top:8px;flex-shrink:0}
</style>

<div class="pr-shell">
  <div class="pr-hdr">
    <h1><i class="fa fa-external-link"></i>&nbsp;Amazon Portal Links</h1>
    <span class="sub">Where to get each data set on logistics.amazon.com · station <%=ST%> · opens in a new tab</span>
    <span class="pr-flt"><input id="prSearch" type="text" placeholder="Filter…" onkeyup="prFilter()"></span>
  </div>

  <div class="pr-wrap">
    <table id="prTable">
      <thead><tr><th>Portal location</th><th>What you get</th><th>Lands in MVPx</th><th></th></tr></thead>
      <tbody>
      <%
        String lastGrp = "";
        for (String[] r : LINKS) {
          if (!r[0].equals(lastGrp)) {
            lastGrp = r[0];
      %>
        <tr class="pr-grprow"><td class="pr-grp" colspan="4"><%=r[0]%></td></tr>
      <%    } %>
        <tr class="pr-row">
          <td class="pr-loc"><%=r[1]%></td>
          <td class="pr-get"><%=r[3]%></td>
          <td class="pr-dest"><%=r[4]%></td>
          <td><a class="pr-open" href="<%=r[2]%>" target="_blank" rel="noopener noreferrer">Open <i class="fa fa-external-link"></i></a></td>
        </tr>
      <% } %>
      </tbody>
    </table>
  </div>

  <div class="pr-note">Discovered by the MVPX-AMZL Bridge (Phase A). Once the bridge is live, most of these downloads stop — data flows straight into the MVPx tables shown at right.</div>
</div>

<script>
function prFilter(){
  var q=(document.getElementById("prSearch").value||"").toLowerCase();
  var rows=document.querySelectorAll("#prTable tbody tr.pr-row");
  rows.forEach(function(tr){
    tr.style.display = tr.innerText.toLowerCase().indexOf(q)>=0 ? "" : "none";
  });
}
</script>

<%@ include file="includeFooter.jsp"%>
