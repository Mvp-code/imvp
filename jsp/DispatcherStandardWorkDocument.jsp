<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"
         import="java.util.*,com.util.*,com.beans.*" %>
<%
  String swLoginUser   = request.getAttribute("loginUser") != null ? request.getAttribute("loginUser").toString() : (String) session.getAttribute("loginUser");
  String swLoginRoles  = request.getAttribute("loginUserRoles") != null ? request.getAttribute("loginUserRoles").toString() : (String) session.getAttribute("loginUserRoles");
  String swEntityID    = request.getAttribute("entityID") != null ? request.getAttribute("entityID").toString() : (session.getAttribute("entityID") != null ? session.getAttribute("entityID").toString() : "1");
  String swDispName    = request.getAttribute("loginUserDisplayName") != null ? request.getAttribute("loginUserDisplayName").toString() : (session.getAttribute("loginUserDisplayName") != null ? session.getAttribute("loginUserDisplayName").toString() : "");
  String swLoginUserID = request.getAttribute("loginUserID") != null ? request.getAttribute("loginUserID").toString() : (session.getAttribute("loginUserID") != null ? session.getAttribute("loginUserID").toString() : "");
  if (swLoginUser == null) swLoginUser = "";
  if (swLoginRoles == null) swLoginRoles = "";
  if (swDispName == null || swDispName.length() == 0) swDispName = "Dispatcher";
  if (swEntityID == null || swEntityID.length() == 0) swEntityID = "1";

  request.setAttribute("loginUser", swLoginUser);
  request.setAttribute("loginUserRoles", swLoginRoles);
  request.setAttribute("entityID", swEntityID);
  request.setAttribute("loginUserDisplayName", swDispName);
  request.setAttribute("loginUserID", swLoginUserID);
  request.setAttribute("shellNoForm", "yes");
  request.setAttribute("hideTopbarSearch", "yes");
%>
<jsp:useBean id="_recordBean" class="com.beans.SearchBean" scope="request" />
<%
  _recordBean.setController("DispatcherStandardWorkDocument");
  _recordBean.setDisplayName("Dispatcher Standard Work");
  int submitType = SubmitType.SEARCH;
%>
<!DOCTYPE html>
<html lang="en">
<%@ include file="includeHeader.jsp"%>
<script>function validatePageData(submitType, isValid) { return isValid; }</script>
<style>
.sw-shell{display:flex;flex-direction:column;height:calc(100vh - 96px);overflow:hidden}
.sw-hdr{margin-bottom:8px;flex-shrink:0}
.sw-hdr h1{font-size:18px;font-weight:900;color:#0f172a;margin:0 0 4px}
.sw-sub{font-size:12px;color:#64748B;line-height:1.45}
.sw-meta{display:flex;gap:8px;flex-wrap:wrap;margin-top:8px}
.sw-chip{background:#fff;border:1px solid #E4E8F0;border-radius:7px;padding:4px 10px;font-size:11px;color:#475569}
.sw-chip b{color:#0f172a}
.sw-intro{background:#F8FAFC;border:1px solid #E4E8F0;border-radius:8px;padding:12px 14px;font-size:13px;color:#334155;line-height:1.55;margin-bottom:10px}
.sw-body{flex:1;min-height:0;display:flex;gap:10px;overflow:hidden}
.sw-nav{width:240px;flex-shrink:0;overflow:auto;border:1px solid #E4E8F0;border-radius:8px;background:#F8FAFC;padding:6px}
.sw-nav-btn{display:block;width:100%;text-align:left;border:none;background:transparent;padding:6px 9px;border-radius:6px;font-size:11.5px;color:#334155;cursor:pointer;margin-bottom:1px;line-height:1.3}
.sw-nav-btn:hover{background:#EEF1F6}
.sw-nav-btn.active{background:#0f172a;color:#fff;font-weight:700}
.sw-nav-btn .n{font-weight:800;margin-right:4px}
.sw-doc{flex:1;overflow:auto;border:1px solid #E4E8F0;border-radius:8px;background:#fff;padding:18px 22px}
.sw-doc h2{margin:0 0 10px;font-size:16px;color:#0f172a;border-bottom:2px solid #E4E8F0;padding-bottom:6px}
.sw-doc h3{margin:14px 0 6px;font-size:13px;color:#0f172a}
.sw-doc p,.sw-doc li{font-size:13px;line-height:1.6;color:#1F2937}
.sw-doc ul{margin:6px 0 10px;padding-left:20px}
.sw-doc table{width:100%;border-collapse:collapse;margin:8px 0;font-size:12px}
.sw-doc th,.sw-doc td{border:1px solid #E4E8F0;padding:6px 8px;text-align:left;vertical-align:top}
.sw-doc th{background:#F8FAFC;font-size:10px;text-transform:uppercase;color:#64748B}
.sw-doc .warn{background:#FEF2F2;border-left:4px solid #DC2626;padding:10px 12px;border-radius:0 8px 8px 0;margin:10px 0;font-size:12.5px;color:#7F1D1D}
.sw-doc .note{background:#FFFBEB;border-left:4px solid #F59E0B;padding:10px 12px;border-radius:0 8px 8px 0;margin:10px 0;font-size:12.5px;color:#78350F}
.sw-ack{margin-top:24px;padding-top:16px;border-top:2px solid #E4E8F0}
.sw-sig{display:grid;grid-template-columns:1fr 1fr;gap:12px;margin-top:12px}
.sw-sig label{display:block;font-size:10px;text-transform:uppercase;letter-spacing:.05em;color:#64748B;margin-bottom:3px}
.sw-sig .ln{border-bottom:1px solid #CBD5E1;height:28px}
@media(max-width:800px){.sw-body{flex-direction:column}.sw-nav{width:100%;max-height:140px}}
</style>

<div class="sw-shell">
  <div class="sw-hdr">
    <h1><i class="fa fa-file-text-o"></i> Dispatcher Mandatory Standard Work &amp; Performance</h1>
    <div class="sw-sub">MVP Logistics LLC · Effective August 2026 · Applies to all Dispatchers</div>
    <div class="sw-meta">
      <span class="sw-chip">DSP <b>MVPG</b></span>
      <span class="sw-chip">Station <b>DNK7</b></span>
      <span class="sw-chip">Role <b>Dispatcher</b></span>
    </div>
  </div>

  <div class="sw-intro">
    Dispatchers control the conditions that produce safety events, quality defects, and route completion outcomes.
    The scorecard is a receipt — not a control. Everything you can change happens live: morning board setup, midday pace checks, the 18:00 rescue decision, and the debrief while the driver is still in front of you.
    <div class="note" style="margin-top:10px;margin-bottom:0">Full policy text can be added section-by-section. See also the <a href="DispatcherManualSample.jsp">Dispatcher Scorecard Manual</a> for metrics training.</div>
  </div>

  <div class="sw-body">
    <nav class="sw-nav" id="swNav">
      <button type="button" class="sw-nav-btn active" data-sec="s1" onclick="swSec('s1',this)"><span class="n">1</span> The Clock</button>
      <button type="button" class="sw-nav-btn" data-sec="s2" onclick="swSec('s2',this)"><span class="n">2</span> Daily Control Plan</button>
      <button type="button" class="sw-nav-btn" data-sec="s3" onclick="swSec('s3',this)"><span class="n">3</span> Rescue &amp; Pace</button>
      <button type="button" class="sw-nav-btn" data-sec="s4" onclick="swSec('s4',this)"><span class="n">4</span> Coaching Standards</button>
      <button type="button" class="sw-nav-btn" data-sec="s5" onclick="swSec('s5',this)"><span class="n">5</span> Disputes &amp; Documentation</button>
      <button type="button" class="sw-nav-btn" data-sec="s6" onclick="swSec('s6',this)"><span class="n">6</span> Weekly Scorecard Review</button>
      <button type="button" class="sw-nav-btn" data-sec="s7" onclick="swSec('s7',this)"><span class="n">7</span> Communication</button>
      <button type="button" class="sw-nav-btn" data-sec="s8" onclick="swSec('s8',this)"><span class="n">8</span> Acknowledgment</button>
    </nav>
    <article class="sw-doc" id="swDoc"></article>
  </div>
</div>

<script>
var SW = {
  s1: { t:'1. The Clock You Are Working Against', h:'<p>Performance week: <b>Sunday → Saturday</b>. Scorecard published <b>Wednesday</b> (+4 days). Portal DSB/DNR detail runs <b>2 days behind</b> the scorecard.</p><div class="warn">A mistake made Monday does not appear on a scorecard until ~9 days later. By then the driver has run eight more routes.</div><p>Three risky driving events in a 10-hour window pause a route automatically — that counter runs inside a single shift. Weekly review cannot see it.</p>' },
  s2: { t:'2. Daily Dispatch Control Plan', h:'<table><tr><th>When</th><th>Do</th><th>Watching for</th></tr>'
    +'<tr><td>Morning</td><td>Review overnight safety events; yesterday RTS/complaints; flag repeat offenders; confirm return-label supply</td><td>Chronic list on unfamiliar heavy routes</td></tr>'
    +'<tr><td>Midday</td><td>Check pace/completion; safety event counter per driver; coach live</td><td>2 safety events — intervene before 3rd pauses route; completion below 99.2%</td></tr>'
    +'<tr><td>17:00–18:00</td><td>Rescue decisions made for drivers, not on request</td><td>Heavy stop counts still open</td></tr>'
    +'<tr><td>End of day</td><td>Debrief RTS codes; itinerary clear; van empty; written station message on package risk; plan tomorrow board</td><td>Anything still in transit</td></tr></table>' },
  s3: { t:'3. Rescue & Pace Management', h:'<p>Five of eleven W34 camera events landed in the 20:00 hour. A driver behind at 17:00 with no rescue has one lever: drive faster.</p><div class="warn">Hard rule: heavy stop count still open at 18:00 means a rescue decision gets made for them — not when they ask.</div><ul><li>Rescue checklist must include Station Command Center pickup reassignment when applicable.</li><li>Never sacrifice safety coaching for speed — but never leave a behind driver with no options either.</li></ul>' },
  s4: { t:'4. Coaching Standards', h:'<ul><li>Coach on the <b>second consecutive</b> flagged week, not a single freak week.</li><li>Coach a <b>behaviour</b>, not a DPMO number — get Portal detail first.</li><li>Check package count before reacting to DPMO on low-volume drivers.</li><li>Ask: is this a <b>person or a place</b>? Fix route notes for repeat reason codes.</li><li>One focus behaviour per wave — same message every morning.</li></ul>' },
  s5: { t:'5. Disputes & Documentation', h:'<p>Disputes are free if you file them; pure loss if you do not. W34: 5 filed, 5 approved.</p><ul><li>File every dispute you have grounds for before the window closes.</li><li>Message the station in writing about RTS/package-status risk the same evening — required for lost-at-station disputes.</li><li>Map-error pattern: same driver, same van, same day on speeding — suspect calibration, not behaviour.</li></ul>' },
  s6: { t:'6. Weekly Scorecard Review', h:'<p>When the scorecard lands, read in this order:</p><ol><li>Compliance gates (BOC, CAS)</li><li>Safety category tier</li><li>DSB, Delivery Completion, CDF</li><li>Cross-check rates against raw event counts</li><li>Decompose DC in Quality DCR file</li><li>Pull behaviour-level detail from Portal</li><li>Build coaching list on repeat offenders</li></ol><p>Safety holds a veto: Safety at Great caps overall at Great regardless of Delivery Quality.</p>' },
  s7: { t:'7. Communication with Drivers & Station', h:'<p>Dispatchers must respond promptly to driver calls about accidents, access issues, package problems, mechanical issues, and route pace.</p><ul><li>Document coaching conversations when they affect safety or quality.</li><li>Escalate customer escalations (CED smell) to management immediately — DNK7 CED has been zero for three weeks.</li><li>Do not represent MVP disciplinary policy as Amazon policy unless specifically required.</li></ul>' },
  s8: { t:'8. Employee Acknowledgment', h:'<div class="sw-ack"><p>I acknowledge that I have received and reviewed the MVP Logistics LLC Dispatcher Mandatory Standard Work &amp; Performance document.</p><ul><li>I understand I am responsible for following applicable MVP policies, dispatch procedures, and current Amazon requirements communicated to me.</li><li>I understand failure to meet these expectations may result in coaching or corrective action, up to and including termination, depending on circumstances and applicable law.</li></ul><div class="sw-sig"><div><label>Employee Name</label><div class="ln"></div></div><div><label>Date</label><div class="ln"></div></div><div><label>Employee Signature</label><div class="ln"></div></div><div><label>MVP Representative</label><div class="ln"></div></div><div><label>Representative Date</label><div class="ln"></div></div></div></div>' }
};
function swSec(id, btn) {
  document.querySelectorAll('.sw-nav-btn').forEach(function(b){ b.classList.remove('active'); });
  if (btn) btn.classList.add('active');
  var s = SW[id];
  document.getElementById('swDoc').innerHTML = '<h2>' + s.t + '</h2>' + s.h;
}
swSec('s1', document.querySelector('[data-sec=s1]'));
</script>

<%@ include file="includeFooter.jsp"%>
