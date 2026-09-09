<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"
         import="java.util.*,com.util.*,com.beans.*" %>
<%
  /* ── MVPX-AMZL Bridge — data loading reference (help page) ──
     Read-only. How each dataset loads into MVPx and what happens on re-load. */
  String arLoginUser   = (request.getAttribute("loginUser") != null) ? request.getAttribute("loginUser").toString() : (String) session.getAttribute("loginUser");
  String arLoginRoles  = (request.getAttribute("loginUserRoles") != null) ? request.getAttribute("loginUserRoles").toString() : (String) session.getAttribute("loginUserRoles");
  String arEntityID    = (request.getAttribute("entityID") != null) ? request.getAttribute("entityID").toString() : (session.getAttribute("entityID") != null ? session.getAttribute("entityID").toString() : "1");
  String arDispName    = (request.getAttribute("loginUserDisplayName") != null) ? request.getAttribute("loginUserDisplayName").toString() : (session.getAttribute("loginUserDisplayName") != null ? session.getAttribute("loginUserDisplayName").toString() : "");
  String arLoginUserID = (request.getAttribute("loginUserID") != null) ? request.getAttribute("loginUserID").toString() : (session.getAttribute("loginUserID") != null ? session.getAttribute("loginUserID").toString() : "");
  if (arLoginUser == null)  arLoginUser  = "";
  if (arLoginRoles == null) arLoginRoles = "";
  if (arDispName == null || arDispName.length() == 0) arDispName = "User";
  if (arEntityID == null || arEntityID.length() == 0) arEntityID = "1";

  /* dataset, table, capture, how it loads, re-load same file */
  final String[][] ROWS = {
    {"Itineraries", "daily_itineraries", "Live", "upsert by driver + date", "updates in place"},
    {"Schedule", "employee_schedule", "Live", "delete-and-reload per day", "replaces that day"},
    {"Vehicles", "VEHICLE", "Live", "dedup by VIN", "updates in place"},
    {"Employees", "EMPLOYEE", "Live", "dedup by transporter ID", "updates in place"},
    {"Safety", "safety_dashboard", "Live / Download", "upsert by Event ID", "updates in place"},
    {"DVIC", "dvic", "Reports file", "delete-and-reload per week", "replaces that week"},
    {"Break Utilization", "da_break_utilization", "Reports file", "delete-and-reload per day", "replaces that day"},
    {"Sentiment", "sentiment_survey", "Reports file", "delete-and-reload per scope", "replaces that scope"},
    {"Compliance", "compliance_supplementary", "Reports file", "delete-and-reload per week", "replaces that week"},
    {"Tenure DAS / Weekly", "tenure_workforce_das / _weekly", "Reports file", "delete-and-reload per week", "replaces that week"},
    {"Quality DCR", "quality_dcr_weekly", "Download", "delete-and-reload per week", "replaces that week"},
    {"CDF", "cdf_feedback", "Download", "delete-and-reload per week", "replaces that week"},
    {"DSB", "dsb_details", "Download", "delete-and-reload per week", "replaces that week"},
    {"Overview", "dashboard_overview", "Download", "delete-and-reload per scope", "replaces that scope"},
    {"Weekly summaries", "bonus dataSetId tables", "Live", "full refresh", "replaces all"}
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
  _recordBean.setController("BridgeHelp");
  _recordBean.setDisplayName("Bridge Loading Guide");
  int submitType = SubmitType.SEARCH;
%>
<!DOCTYPE html>
<html lang="en">
<%@ include file="includeHeader.jsp"%>
<script>
function validatePageData(submitType, isValid) { return isValid; }
</script>
<style>
.bh-shell{display:flex;flex-direction:column;height:calc(100vh - 96px);overflow:auto;padding-right:6px}
.bh-hdr h1{font-size:18px;font-weight:900;color:#0f172a;margin:0 0 2px}
.bh-hdr .sub{font-size:12px;color:#64748B;margin-bottom:14px}
.bh-sec{font-size:12px;text-transform:uppercase;letter-spacing:.05em;color:#64748B;font-weight:800;margin:18px 0 8px}
.bh-wrap{border:1px solid #E4E8F0;border-radius:8px;background:#fff;overflow:auto}
.bh-wrap table{width:100%;border-collapse:collapse}
.bh-wrap th{background:#F8FAFC;font-size:10px;text-transform:uppercase;letter-spacing:.04em;color:#64748B;text-align:left;padding:8px 11px;border-bottom:1px solid #E4E8F0;white-space:nowrap}
.bh-wrap td{font-size:12.5px;color:#1F2937;padding:8px 11px;border-bottom:1px solid #EEF1F6;vertical-align:top}
.bh-wrap tr:hover td{background:#F8FAFC}
.bh-wrap .mono{font-family:Consolas,Menlo,monospace;font-size:11.5px;color:#0f172a}
.bh-tag{display:inline-block;font-size:10px;font-weight:700;padding:1px 7px;border-radius:9px}
.bh-tag.live{background:#ECFDF5;color:#065F46}
.bh-tag.file{background:#EFF6FF;color:#1E40AF}
.bh-tag.dl{background:#FEF3C7;color:#92400E}
.bh-note{border:1px solid #E4E8F0;border-radius:8px;background:#F8FAFC;padding:12px 14px;font-size:12.5px;color:#334155;line-height:1.55}
.bh-note b{color:#0f172a}
.bh-note code{font-family:Consolas,Menlo,monospace;font-size:11.5px;background:#EEF1F6;padding:1px 5px;border-radius:4px}
.bh-grid{display:grid;grid-template-columns:1fr 1fr;gap:12px}
@media (max-width:760px){.bh-grid{grid-template-columns:1fr}}
</style>

<div class="bh-shell">
  <div class="bh-hdr">
    <h1><i class="fa fa-book"></i>&nbsp;Bridge Loading Guide</h1>
    <div class="sub">How each Amazon data set loads into MVPx, and what happens when the same data is loaded again.</div>
  </div>

  <div class="bh-sec">Where each data set lands &amp; how it loads</div>
  <div class="bh-wrap">
    <table>
      <thead><tr><th>Data set</th><th>MVPx table</th><th>Source</th><th>How it loads</th><th>Re-load the same file?</th></tr></thead>
      <tbody>
      <% for (String[] r : ROWS) {
           String cad = r[2]; String cls = cad.indexOf("Download") >= 0 ? "dl" : (cad.indexOf("file") >= 0 ? "file" : "live"); %>
        <tr>
          <td><b><%= r[0] %></b></td>
          <td class="mono"><%= r[1] %></td>
          <td><span class="bh-tag <%= cls %>"><%= cad %></span></td>
          <td><%= r[3] %></td>
          <td><%= r[4] %></td>
        </tr>
      <% } %>
      </tbody>
    </table>
  </div>

  <div class="bh-sec">What the terms mean</div>
  <div class="bh-grid">
    <div class="bh-note">
      <b>Upsert / dedup</b> &mdash; the loader matches each row on a key (driver+date, VIN, transporter&nbsp;ID, Event&nbsp;ID) and <b>updates the existing row</b> instead of adding a new one. Loading the same data again just refreshes it.
    </div>
    <div class="bh-note">
      <b>Delete-and-reload per week / day / scope</b> &mdash; before loading, the loader clears that report's <b>same week (or day)</b>, then inserts the fresh rows. Re-loading Week&nbsp;28 replaces Week&nbsp;28; loading Week&nbsp;29 <b>adds</b> alongside it. Always exactly one current copy per week.
    </div>
    <div class="bh-note">
      <b>Full refresh</b> &mdash; the weekly summary (bonus) tables wipe and reload the whole snapshot each time.
    </div>
    <div class="bh-note">
      <b>Source</b> &mdash; <span class="bh-tag live">Live</span> captured automatically as you browse &middot; <span class="bh-tag file">Reports file</span> auto-fetched from the Supplementary Reports page &middot; <span class="bh-tag dl">Download</span> captured when you click the grid's download arrow.
    </div>
  </div>

  <div class="bh-sec">Re-loading is always safe</div>
  <div class="bh-note">
    You can load the same report as many times as you want &mdash; it <b>never creates duplicates</b>. Every path protects itself: upsert updates in place, delete-and-reload replaces the same week, full-refresh replaces the snapshot. <b>Same week in = same week replaced. New week in = added.</b>
  </div>

  <div class="bh-sec">Hidden (superseded) rows</div>
  <div class="bh-note">
    Delete-and-reload doesn't hard-delete the old rows &mdash; it marks them <b>hidden</b> (<code>STATUS=1</code>) and the new ones <b>active</b> (<code>STATUS=0</code>). Your pages only ever show the active set, so data is always correct, but hidden rows accumulate over time. On the <b>AMZL Bridge</b> page, the amber <b>&ldquo;hidden / superseded&rdquo;</b> card shows the count and a <b>Purge hidden</b> button clears them (report tables only &mdash; Vehicles, Employees, Itineraries and Schedule are left alone, since a hidden row there can be a real deletion).
  </div>

  <div style="height:14px"></div>
</div>

<%@ include file="includeFooter.jsp"%>
