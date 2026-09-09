<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"
         import="java.sql.*,javax.sql.*,javax.naming.*,java.util.*,java.text.SimpleDateFormat,com.util.*,com.beans.*" %>
<%!
  private String gp(javax.servlet.http.HttpServletRequest req, String name) {
    String v = req.getParameter(name);
    return v == null ? "" : v.trim();
  }
  private String esc(String s) {
    return s == null ? "" : s.replace("&","&amp;").replace("<","&lt;").replace("\"","&quot;");
  }
%>
<%
  /* ── Daily Status — Loadout / 2PM / 5PM / Close-Out ──
     Auto metrics come live from fleetdb (itineraries, routes, vehicles,
     rescues); everything else is a manual field saved per date+slot.
     The Copy button composes the Slack-style report from both. */
  String dsLoginUser   = (request.getAttribute("loginUser") != null) ? request.getAttribute("loginUser").toString() : (String) session.getAttribute("loginUser");
  String dsLoginRoles  = (request.getAttribute("loginUserRoles") != null) ? request.getAttribute("loginUserRoles").toString() : (String) session.getAttribute("loginUserRoles");
  String dsEntityID    = (request.getAttribute("entityID") != null) ? request.getAttribute("entityID").toString() : (session.getAttribute("entityID") != null ? session.getAttribute("entityID").toString() : "1");
  String dsDispName    = (request.getAttribute("loginUserDisplayName") != null) ? request.getAttribute("loginUserDisplayName").toString() : (session.getAttribute("loginUserDisplayName") != null ? session.getAttribute("loginUserDisplayName").toString() : "");
  String dsLoginUserID = (request.getAttribute("loginUserID") != null) ? request.getAttribute("loginUserID").toString() : (session.getAttribute("loginUserID") != null ? session.getAttribute("loginUserID").toString() : "");
  if (dsLoginUser == null)  dsLoginUser  = "";
  if (dsLoginRoles == null) dsLoginRoles = "";
  if (dsDispName == null || dsDispName.length() == 0) dsDispName = "Dispatcher";

  String selDate = gp(request, "d");
  if (!selDate.matches("\\d{4}-\\d{2}-\\d{2}"))
    selDate = new SimpleDateFormat("yyyy-MM-dd").format(new java.util.Date());

  /* manual field layout per slot (label -> field key) */
  final String[][] SLOTS = {
    {"loadout",  "&#128241; Morning Loadout"},
    {"2pm",      "&#128337; 2PM Update"},
    {"5pm",      "&#128340; 5PM Report"},
    {"closeout", "&#127937; Close-Out / Nightly"}
  };
  final String[][][] FIELDS = {
    { {"safety","Safety"}, {"delays","Delays"}, {"routechanges","Route changes"},
      {"helpers","Helpers"}, {"pickup","Pickup"}, {"issues","Issues"}, {"vibe","Vibe"},
      {"others","Others"} },
    { {"red","Red (manual adj.)"}, {"yellow","Yellow (manual adj.)"}, {"reassign","Reassignments"},
      {"violations","Violations"}, {"pickuprts","Pickups / RTS"}, {"notes","Notes"},
      {"others","Others"} },
    { {"red","Red (manual adj.)"}, {"yellow","Yellow (manual adj.)"}, {"helping","Who helping whom"},
      {"shop","Shop / returns"}, {"chokepoint","Chokepoint"}, {"others","Others"} },
    { {"rts","RTS"}, {"undeliverable","Undeliverables"}, {"violations","Violations"},
      {"pickups","Pickups"}, {"vehicleshop","Vehicle / Shop"}, {"nextday","Next day schedule"},
      {"others","Others"} }
  };

  Connection conn = null;
  String dbError = "", savedMsg = "";
  Map<String, String> manual = new HashMap<String, String>();   // slot|field -> val

  /* auto metrics */
  long routes = 0, stops = 0, pkgs = 0, done = 0;
  String firstWave = "", lastWave = "", lastBack = "", lastBackName = "";
  int onTime = 0, behind = 0;
  List<String[]> reds = new ArrayList<String[]>();     // name, done/all
  List<String[]> yellows = new ArrayList<String[]>();
  List<String> grounded = new ArrayList<String>();
  List<String> repairTonight = new ArrayList<String>();
  List<String[]> shopOpen = new ArrayList<String[]>(); // vehicle, type
  List<String[]> rescues = new ArrayList<String[]>();  // helper, target
  long routesTomorrow = 0;

  try {
    Context ictx = new InitialContext();
    DataSource ds = (DataSource) ictx.lookup("java:comp/env/jdbc/MVPGDB");
    conn = ds.getConnection();

    /* save posted manual fields (POST-to-self, then re-render) */
    if ("save".equals(gp(request, "action"))) {
      String slot = gp(request, "slot");
      for (String[][] grp : FIELDS)
        for (String[] f : grp) {
          String pv = request.getParameter("f_" + slot + "_" + f[0]);
          if (pv == null) continue;
          PreparedStatement pu = conn.prepareStatement(
            "INSERT INTO daily_status_entry (ENTITYID, REPORT_DATE, SLOT, FIELD, VAL, UPDATE_USER, UPDATE_DATE) "
            + "VALUES (1, ?, ?, ?, ?, ?, NOW()) "
            + "ON DUPLICATE KEY UPDATE VAL=VALUES(VAL), UPDATE_USER=VALUES(UPDATE_USER), UPDATE_DATE=NOW()");
          pu.setString(1, selDate);
          pu.setString(2, slot);
          pu.setString(3, f[0]);
          pu.setString(4, pv.trim());
          pu.setString(5, dsDispName);
          pu.executeUpdate();
          pu.close();
        }
      savedMsg = "Saved " + slot + " at " + new SimpleDateFormat("h:mm a").format(new java.util.Date());
    }

    /* load manual values for the date */
    PreparedStatement pm = conn.prepareStatement(
      "SELECT SLOT, FIELD, VAL FROM daily_status_entry WHERE ENTITYID=1 AND REPORT_DATE=?");
    pm.setString(1, selDate);
    ResultSet rm = pm.executeQuery();
    while (rm.next()) manual.put(rm.getString(1) + "|" + rm.getString(2), rm.getString(3) == null ? "" : rm.getString(3));
    rm.close(); pm.close();

    /* ── auto metrics for the selected date ── */
    PreparedStatement ps = conn.prepareStatement(
      "SELECT COUNT(*), IFNULL(SUM(ALLSTOPS),0), IFNULL(SUM(TOALPACKAGES),0), "
      + "SUM(ALLSTOPS>0 AND COMPLETEDSTOPS>=ALLSTOPS) FROM daily_itineraries "
      + "WHERE STATUS!=1 AND DATE(ITINARARYDATE)=?");
    ps.setString(1, selDate);
    ResultSet rs = ps.executeQuery();
    if (rs.next()) { routes = rs.getLong(1); stops = rs.getLong(2); pkgs = rs.getLong(3); done = rs.getLong(4); }
    rs.close(); ps.close();

    ps = conn.prepareStatement(
      "SELECT IFNULL(DATE_FORMAT(MIN(WAVE_TIME),'%h:%i %p'),''), IFNULL(DATE_FORMAT(MAX(WAVE_TIME),'%h:%i %p'),'') "
      + "FROM route_assignment WHERE STATUS!=1 AND DATE(ASSIGN_DATE)=?");
    ps.setString(1, selDate);
    rs = ps.executeQuery();
    if (rs.next()) { firstWave = rs.getString(1); lastWave = rs.getString(2); }
    rs.close(); ps.close();

    ps = conn.prepareStatement(
      "SELECT IFNULL(DATE_FORMAT(MAX(LAST_STOP_TIME),'%h:%i %p'),''), "
      + "(SELECT TRANSPORTERNAME FROM daily_itineraries WHERE STATUS!=1 AND DATE(ITINARARYDATE)=? "
      + " AND LAST_STOP_TIME IS NOT NULL ORDER BY LAST_STOP_TIME DESC LIMIT 1) "
      + "FROM daily_itineraries WHERE STATUS!=1 AND DATE(ITINARARYDATE)=?");
    ps.setString(1, selDate);
    ps.setString(2, selDate);
    rs = ps.executeQuery();
    if (rs.next()) { lastBack = rs.getString(1); lastBackName = rs.getString(2) == null ? "" : rs.getString(2); }
    rs.close(); ps.close();

    /* red (<50% done) / yellow (50-75%) — heuristic on completion */
    ps = conn.prepareStatement(
      "SELECT TRANSPORTERNAME, COMPLETEDSTOPS, ALLSTOPS FROM daily_itineraries "
      + "WHERE STATUS!=1 AND DATE(ITINARARYDATE)=? AND ALLSTOPS>0 "
      + "ORDER BY COMPLETEDSTOPS/ALLSTOPS ASC LIMIT 60");
    ps.setString(1, selDate);
    rs = ps.executeQuery();
    while (rs.next()) {
      int d2 = rs.getInt(2), a = rs.getInt(3);
      double pct = a > 0 ? (double) d2 / a : 1;
      if (pct >= 1) { onTime++; continue; }
      if (pct < 0.5) reds.add(new String[]{ rs.getString(1), d2 + "/" + a });
      else if (pct < 0.75) yellows.add(new String[]{ rs.getString(1), d2 + "/" + a });
      else onTime++;
      if (pct < 0.75) behind++;
    }
    rs.close(); ps.close();
    onTime = (int) routes - behind;

    /* vehicles: grounded + open shop jobs */
    ps = conn.prepareStatement(
      "SELECT VEHICLENUMBER FROM VEHICLE WHERE STATUS!=1 AND OPERATIONALSTATUS=1 ORDER BY 1 LIMIT 60");
    rs = ps.executeQuery();
    while (rs.next()) grounded.add(rs.getString(1));
    rs.close(); ps.close();
    /* flagged out-for-repair on the Vehicles page = tonight's shop list */
    ps = conn.prepareStatement(
      "SELECT VEHICLENUMBER FROM VEHICLE WHERE STATUS!=1 AND IFNULL(OUT_FOR_REPAIR,0)=1 ORDER BY 1 LIMIT 60");
    rs = ps.executeQuery();
    while (rs.next()) repairTonight.add(rs.getString(1));
    rs.close(); ps.close();
    try {
      ps = conn.prepareStatement(
        "SELECT V.VEHICLENUMBER, IFNULL(L.MAINT_CODE,'') FROM vehicle_maintenance_log L "
        + "JOIN VEHICLE V ON V.VEHICLEID=L.VEHICLEID "
        + "WHERE (L.STATUS IS NULL OR L.STATUS!=1) AND L.IS_OPEN=1 ORDER BY L.MAINT_LOGID DESC LIMIT 20");
      rs = ps.executeQuery();
      while (rs.next()) shopOpen.add(new String[]{ rs.getString(1), rs.getString(2) });
      rs.close(); ps.close();
    } catch (Exception exShop) { /* table shape differs - skip quietly */ }

    /* rescues for the date (Emily/dispatch) */
    ps = conn.prepareStatement(
      "SELECT IFNULL(H.FULLNAME,''), IFNULL(T.FULLNAME,'') FROM rescue_assignment R "
      + "LEFT JOIN employee H ON H.EMPLOYEEID=R.HELPER_EMPLOYEEID "
      + "LEFT JOIN employee T ON T.EMPLOYEEID=R.TARGET_EMPLOYEEID "
      + "WHERE R.STATUS!=1 AND R.RESCUE_STATUS IN ('approved','completed') AND DATE(R.CREATE_DATE)=?");
    ps.setString(1, selDate);
    rs = ps.executeQuery();
    while (rs.next()) rescues.add(new String[]{ rs.getString(1), rs.getString(2) });
    rs.close(); ps.close();

    ps = conn.prepareStatement(
      "SELECT COUNT(*) FROM route_assignment WHERE STATUS!=1 AND DATE(ASSIGN_DATE)=DATE_ADD(?, INTERVAL 1 DAY)");
    ps.setString(1, selDate);
    rs = ps.executeQuery();
    if (rs.next()) routesTomorrow = rs.getLong(1);
    rs.close(); ps.close();

  } catch (Exception ex) {
    dbError = String.valueOf(ex.getMessage());
  } finally {
    if (conn != null) try { conn.close(); } catch (Exception e) {}
  }

  SimpleDateFormat inFmt = new SimpleDateFormat("yyyy-MM-dd");
  java.util.Date dObj = inFmt.parse(selDate);
  String niceDate = new SimpleDateFormat("EEEE M/d").format(dObj);
  Calendar cal = Calendar.getInstance(); cal.setTime(dObj);
  cal.add(Calendar.DATE, -1); String prevD = inFmt.format(cal.getTime());
  cal.add(Calendar.DATE, 2);  String nextD = inFmt.format(cal.getTime());
%>
<jsp:useBean id="_recordBean" class="com.beans.SearchBean" scope="request" />
<jsp:useBean id="_errorBean" class="com.beans.ErrorBean" scope="request" />
<%
int submitType = SubmitType.SEARCH;
_recordBean.setController("DailyStatus");
_recordBean.setDisplayName("Daily Status");
request.setAttribute("loginUser", dsLoginUser);
request.setAttribute("loginUserRoles", dsLoginRoles);
request.setAttribute("entityID", dsEntityID);
request.setAttribute("loginUserDisplayName", dsDispName);
request.setAttribute("loginUserID", dsLoginUserID);
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
.dst-shell{display:flex;flex-direction:column;height:calc(100vh - 96px);overflow:hidden}
.dst-hdr{display:flex;align-items:center;gap:10px;margin-bottom:8px;flex-shrink:0;flex-wrap:wrap}
.dst-hdr h1{font-size:18px;font-weight:900;color:#0f172a;margin:0}
.dst-nav{display:flex;align-items:center;gap:6px}
.dst-nav a,.dst-nav b{font-size:13px;font-weight:800;color:#0f172a;text-decoration:none;padding:4px 9px;border:1px solid #E4E8F0;border-radius:7px;background:#fff}
.dst-nav b{border-color:#0f172a}
.dst-kpis{display:flex;gap:8px;margin-left:auto;flex-wrap:wrap}
.dst-kpi{background:#fff;border:1px solid #E4E8F0;border-radius:8px;padding:3px 11px;text-align:center}
.dst-kpi b{display:block;font-size:15px;color:#0f172a;line-height:1.15}
.dst-kpi span{font-size:9.5px;color:#64748B;font-weight:700;text-transform:uppercase;letter-spacing:.04em}
.dst-grid{flex:1;display:grid;grid-template-columns:repeat(4, 1fr);gap:10px;min-height:0}
.dst-card{background:#fff;border:1px solid #E4E8F0;border-radius:10px;display:flex;flex-direction:column;min-height:0;overflow:hidden}
.dst-card h3{margin:0;padding:9px 12px;font-size:12.5px;font-weight:900;color:#0f172a;border-bottom:1px solid #EEF1F6;display:flex;align-items:center;gap:6px;flex-shrink:0}
.dst-card h3 .cp{margin-left:auto;border:1px solid #CBD5E1;background:#fff;border-radius:6px;font-size:10.5px;font-weight:700;padding:3px 8px;cursor:pointer}
.dst-card h3 .cp:hover{background:#F1F5F9}
.dst-scroll{flex:1;overflow:auto;padding:10px 12px;min-height:0}
.dst-auto{background:#F8FAFC;border:1px solid #EEF1F6;border-radius:8px;padding:7px 10px;font-size:12px;color:#334155;margin-bottom:9px}
.dst-auto b{color:#0f172a}
.dst-auto .tag{font-size:9px;font-weight:800;color:#1D4ED8;background:#EFF4FF;padding:1px 6px;border-radius:5px;letter-spacing:.05em}
.dst-auto div{margin:2px 0}
.dst-fld{margin-bottom:7px}
.dst-fld label{display:block;font-size:10.5px;font-weight:800;color:#475569;margin-bottom:2px;text-transform:uppercase;letter-spacing:.03em}
.dst-fld textarea{width:100%;box-sizing:border-box;border:1px solid #CBD5E1;border-radius:7px;padding:8px 10px;font-size:13.5px;color:#0f172a;resize:vertical;min-height:58px;font-family:inherit;line-height:1.45}
.dst-fld textarea:focus{border-color:#0f172a;outline:none}
.dst-save{border:none;background:#0f172a;color:#fff;font-size:12px;font-weight:800;padding:7px 0;border-radius:7px;cursor:pointer;width:100%;margin-top:2px}
.dst-saved{font-size:11.5px;color:#15803D;font-weight:700}
.pill-r{color:#C62828;font-weight:700}.pill-y{color:#B45309;font-weight:700}
@media(max-width:1100px){.dst-grid{grid-template-columns:repeat(2,1fr);overflow:auto}}
</style>

<div class="dst-shell">
  <div class="dst-hdr">
    <h1>&#128203;&nbsp;Daily Status</h1>
    <div class="dst-nav">
      <a href="?d=<%=prevD%>">&#8249;</a><b><%=niceDate%></b><a href="?d=<%=nextD%>">&#8250;</a>
      <input type="date" value="<%=selDate%>" onchange="location='?d='+this.value"
             style="border:1px solid #CBD5E1;border-radius:7px;padding:4px 8px;font-size:12px">
    </div>
    <%if (savedMsg.length() > 0) {%><span class="dst-saved">&#10003; <%=savedMsg%></span><%}%>
    <div class="dst-kpis">
      <div class="dst-kpi"><b><%=routes%></b><span>routes</span></div>
      <div class="dst-kpi"><b><%=stops%></b><span>stops</span></div>
      <div class="dst-kpi"><b><%=pkgs%></b><span>pkgs</span></div>
      <div class="dst-kpi"><b><%=done%></b><span>done</span></div>
      <div class="dst-kpi"><b class="<%=behind>0?"pill-r":""%>"><%=behind%></b><span>behind</span></div>
      <div class="dst-kpi"><b><%=grounded.size()%></b><span>grounded</span></div>
    </div>
  </div>
  <%if (dbError.length() > 0 && !"null".equals(dbError)) {%><div style="color:#C62828;font-size:12px"><%=dbError%></div><%}%>

  <div class="dst-grid">
  <%for (int s = 0; s < SLOTS.length; s++) {
      String slot = SLOTS[s][0];%>
    <div class="dst-card" id="card_<%=slot%>">
      <h3><%=SLOTS[s][1]%><button class="cp" onclick="dstCopy('<%=slot%>')">&#128203; Copy report</button></h3>
      <div class="dst-scroll">
        <div class="dst-auto" id="auto_<%=slot%>">
          <div style="margin-bottom:3px"><span class="tag">AUTO from MVPx</span></div>
          <%if ("loadout".equals(slot)) {%>
          <div><b><%=routes%></b> routes / <b><%=stops%></b> stops / <b><%=pkgs%></b> pkgs</div>
          <div>First wave: <b><%=firstWave.length()>0?firstWave:"&mdash;"%></b> &middot; Last: <b><%=lastWave.length()>0?lastWave:"&mdash;"%></b></div>
          <%} else if ("2pm".equals(slot) || "5pm".equals(slot)) {%>
          <div>Snapshot: <b><%=onTime<0?0:onTime%></b> on pace / <b class="pill-r"><%=behind%></b> behind</div>
          <%if (!reds.isEmpty()) {%><div class="pill-r">&#128308; <%for (String[] r : reds) {%><%=esc(r[0])%> (<%=r[1]%>) <%}%></div><%}%>
          <%if (!yellows.isEmpty()) {%><div class="pill-y">&#128993; <%for (String[] r : yellows) {%><%=esc(r[0])%> (<%=r[1]%>) <%}%></div><%}%>
          <%if (!rescues.isEmpty()) {%><div>&#127384; <%for (String[] r : rescues) {%><%=esc(r[0])%> &rarr; <%=esc(r[1])%>; <%}%></div><%}%>
          <%} else {%>
          <div>Last driver: <b><%=esc(lastBackName)%></b> <b><%=lastBack.length()>0?lastBack:"&mdash;"%></b></div>
          <div>Routes done: <b><%=done%></b> of <b><%=routes%></b></div>
          <div>&#128295; For repair tonight: <b><%=repairTonight.isEmpty()?"none flagged":String.join(", ", repairTonight)%></b></div>
          <div>Grounded: <b><%=grounded.isEmpty()?"none":String.join(", ", grounded)%></b></div>
          <%if (!shopOpen.isEmpty()) {%><div>Shop: <%for (String[] v : shopOpen) {%><%=esc(v[0])%> (<%=esc(v[1])%>) <%}%></div><%}%>
          <div>Tomorrow: <b><%=routesTomorrow%></b> routes scheduled</div>
          <%}%>
        </div>
        <form method="post" action="?d=<%=selDate%>">
          <input type="hidden" name="action" value="save">
          <input type="hidden" name="slot" value="<%=slot%>">
          <%for (String[] f : FIELDS[s]) {
              String key = slot + "|" + f[0];
              String val = manual.get(key) == null ? "" : manual.get(key);%>
          <div class="dst-fld">
            <label><%=f[1]%></label>
            <textarea name="f_<%=slot%>_<%=f[0]%>" rows="2" data-fld="<%=f[1]%>"><%=esc(val)%></textarea>
          </div>
          <%}%>
          <button class="dst-save" type="submit">Save <%=SLOTS[s][1].replaceAll("&#\\d+;","").trim()%></button>
        </form>
      </div>
    </div>
  <%}%>
  </div>
</div>

<script>
/* compose the Slack-style report for a slot: auto lines + manual fields */
function dstCopy(slot){
  var card = document.getElementById('card_' + slot);
  var title = card.querySelector('h3').childNodes[0].textContent.trim();
  var out = title + ' – <%=niceDate%>\n';
  card.querySelectorAll('#auto_' + slot + ' div').forEach(function(d, i){
    if (i === 0) return; // skip the AUTO tag line
    out += d.textContent.trim() + '\n';
  });
  card.querySelectorAll('textarea').forEach(function(ta){
    if (ta.value.trim()) out += ta.dataset.fld + ': ' + ta.value.trim() + '\n';
  });
  navigator.clipboard.writeText(out).then(function(){
    var btn = card.querySelector('.cp');
    var old = btn.innerHTML;
    btn.innerHTML = '✓ copied';
    setTimeout(function(){ btn.innerHTML = old; }, 1500);
  });
}
/* textareas grow with content */
document.querySelectorAll('.dst-fld textarea').forEach(function(ta){
  var fit = function(){ ta.style.height = 'auto'; ta.style.height = Math.max(58, ta.scrollHeight) + 'px'; };
  ta.addEventListener('input', fit); fit();
});
/* auto metrics refresh: reload every 5 min unless someone is typing */
setInterval(function(){
  if (![].some.call(document.querySelectorAll('textarea'), function(t){ return t === document.activeElement; }))
    location.reload();
}, 300000);
</script>
<%@ include file="includeFooter.jsp"%>
</html>
