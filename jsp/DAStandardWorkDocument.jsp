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
  if (swDispName == null || swDispName.length() == 0) swDispName = "User";
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
  _recordBean.setController("DAStandardWorkDocument");
  _recordBean.setDisplayName("DA Standard Work");
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
.sw-doc .warn{background:#FEF2F2;border-left:4px solid #DC2626;padding:10px 12px;border-radius:0 8px 8px 0;margin:10px 0;font-size:12.5px;color:#7F1D1D}
.sw-ack{margin-top:24px;padding-top:16px;border-top:2px solid #E4E8F0}
.sw-sig{display:grid;grid-template-columns:1fr 1fr;gap:12px;margin-top:12px}
.sw-sig label{display:block;font-size:10px;text-transform:uppercase;letter-spacing:.05em;color:#64748B;margin-bottom:3px}
.sw-sig .ln{border-bottom:1px solid #CBD5E1;height:28px}
@media(max-width:800px){.sw-body{flex-direction:column}.sw-nav{width:100%;max-height:140px}}
</style>

<div class="sw-shell">
  <div class="sw-hdr">
    <h1><i class="fa fa-file-text-o"></i> Delivery Associate Mandatory Standard Work &amp; Performance</h1>
    <div class="sw-sub">MVP Logistics LLC · Effective August 2026 · Applies to all Delivery Associates (DAs)</div>
    <div class="sw-meta">
      <span class="sw-chip">Company <b>MVP Logistics LLC</b></span>
      <span class="sw-chip">Effective <b>August 2026</b></span>
      <span class="sw-chip">Audience <b>All DAs</b></span>
    </div>
  </div>

  <div class="sw-intro">
    MVP Logistics LLC is committed to providing safe, reliable, and high-quality delivery service while maintaining a professional and respectful workplace.
    The following Mandatory Standard Work establishes the minimum expectations for Delivery Associates regarding safety, delivery quality, attendance, timekeeping, vehicle care, communication, and route performance.
    All Delivery Associates are expected to understand and follow these standards during every scheduled shift.
  </div>

  <div class="sw-body">
    <nav class="sw-nav" id="swNav">
      <button type="button" class="sw-nav-btn active" data-sec="s1" onclick="swSec('s1',this)"><span class="n">1</span> Safety Standards</button>
      <button type="button" class="sw-nav-btn" data-sec="s2" onclick="swSec('s2',this)"><span class="n">2</span> Accidents &amp; Damage</button>
      <button type="button" class="sw-nav-btn" data-sec="s3" onclick="swSec('s3',this)"><span class="n">3</span> Vehicle Inspection</button>
      <button type="button" class="sw-nav-btn" data-sec="s4" onclick="swSec('s4',this)"><span class="n">4</span> Delivery Quality</button>
      <button type="button" class="sw-nav-btn" data-sec="s5" onclick="swSec('s5',this)"><span class="n">5</span> Contact Compliance</button>
      <button type="button" class="sw-nav-btn" data-sec="s6" onclick="swSec('s6',this)"><span class="n">6</span> Photo on Delivery</button>
      <button type="button" class="sw-nav-btn" data-sec="s7" onclick="swSec('s7',this)"><span class="n">7</span> Route Performance</button>
      <button type="button" class="sw-nav-btn" data-sec="s8" onclick="swSec('s8',this)"><span class="n">8</span> Breaks</button>
      <button type="button" class="sw-nav-btn" data-sec="s9" onclick="swSec('s9',this)"><span class="n">9</span> Return-to-Station</button>
      <button type="button" class="sw-nav-btn" data-sec="s10" onclick="swSec('s10',this)"><span class="n">10</span> Fueling</button>
      <button type="button" class="sw-nav-btn" data-sec="s11" onclick="swSec('s11',this)"><span class="n">11</span> Attendance</button>
      <button type="button" class="sw-nav-btn" data-sec="s12" onclick="swSec('s12',this)"><span class="n">12</span> Callouts &amp; NCNS</button>
      <button type="button" class="sw-nav-btn" data-sec="s13" onclick="swSec('s13',this)"><span class="n">13</span> Time-Off Requests</button>
      <button type="button" class="sw-nav-btn" data-sec="s14" onclick="swSec('s14',this)"><span class="n">14</span> Timekeeping</button>
      <button type="button" class="sw-nav-btn" data-sec="s15" onclick="swSec('s15',this)"><span class="n">15</span> Towing / Stuck</button>
      <button type="button" class="sw-nav-btn" data-sec="s16" onclick="swSec('s16',this)"><span class="n">16</span> Complaints</button>
      <button type="button" class="sw-nav-btn" data-sec="s17" onclick="swSec('s17',this)"><span class="n">17</span> Dispatch Communication</button>
      <button type="button" class="sw-nav-btn" data-sec="s18" onclick="swSec('s18',this)"><span class="n">18</span> Corrective Action</button>
      <button type="button" class="sw-nav-btn" data-sec="s19" onclick="swSec('s19',this)"><span class="n">19</span> Amazon vs MVP</button>
      <button type="button" class="sw-nav-btn" data-sec="s20" onclick="swSec('s20',this)"><span class="n">20</span> Acknowledgment</button>
    </nav>
    <article class="sw-doc" id="swDoc"></article>
  </div>
</div>

<script>
var SW = {
  s1: { t:'1. Safety Standards', h:'<p><b>Safety is our highest priority.</b> No delivery, package, or route completion goal takes priority over safe driving.</p><h3>Safe Driving Expectations</h3><p>Delivery Associates must:</p><ul><li>Wear a seatbelt whenever the vehicle is moving.</li><li>Come to a complete stop at all stop signs and red lights.</li><li>Obey posted speed limits and adjust speed for road, traffic, and weather conditions.</li><li>Maintain a safe following distance.</li><li>Never use or handle a phone while driving.</li><li>Avoid distracted driving, including eating or performing other activities that interfere with safe vehicle operation.</li><li>Follow all applicable traffic laws and Amazon/MVP safety requirements.</li><li>Operate vehicles carefully around driveways, mailboxes, lawns, structures, pedestrians, and other vehicles.</li></ul><p>Safety violations may result in coaching, removal from a route, suspension from scheduled work, or termination depending on seriousness, frequency, circumstances, and applicable company policy.</p><div class="warn">Serious safety incidents—including conduct that creates substantial risk to employees, customers, pedestrians, or the public—may result in immediate removal from duty pending review.</div>' },
  s2: { t:'2. Accidents, Vehicle Damage & Property Damage', h:'<p>All accidents, collisions, vehicle damage, and property damage must be reported <b>immediately</b>. Never leave the scene without following required procedures.</p><h3>Accident Involving Another Vehicle</h3><ul><li>Stop in a safe location and assess the situation.</li><li>If anyone may be injured or emergency assistance is needed, call 911.</li><li>Follow the required incident/emergency process in the Amazon Flex app when applicable.</li><li>Immediately contact MVP Dispatch.</li><li>Do not admit fault or make promises regarding payment or liability.</li><li>Take clear photographs of the scene and all sides of the vehicles involved, when safe.</li><li>Obtain or provide required information as directed by Dispatch.</li><li>Submit a complete written statement describing what occurred.</li></ul><h3>Property Damage</h3><p>Includes damage to mailboxes, driveways, lawns, landscaping, fences, buildings, garage doors, sidewalks, lawn decorations, customer vehicles, and other property.</p><ul><li>Immediately notify Dispatch if you believe you may have damaged property, even if minor.</li><li>Take photographs when safe and submit a written incident statement.</li><li>Do not wait for the customer to report the damage.</li></ul><div class="warn">Failure to report an accident or known damage may be treated more seriously than the underlying incident itself.</div>' },
  s3: { t:'3. Vehicle Inspection & Damage Reporting', h:'<p>Every Delivery Associate is responsible for inspecting their assigned vehicle.</p><h3>Before the Route</h3><ul><li>Complete the required pre-trip inspection.</li><li>Perform the required DVIC accurately.</li><li>Inspect the vehicle for visible damage or safety concerns.</li><li>Follow MVP\'s required vehicle-photo procedure.</li><li>Immediately notify Dispatch of new or undocumented damage.</li><li>Do not independently mark vehicle defects in Flex without following MVP\'s reporting procedure and communicating with Dispatch.</li></ul><h3>After the Route</h3><ul><li>Complete the required post-trip inspection and DVIC.</li><li>Report any new damage, warning lights, mechanical issues, or safety concerns.</li><li>Complete the required end-of-shift vehicle photographs/inspection.</li><li>Never conceal or fail to report vehicle damage.</li></ul><div class="warn">Knowingly failing to report an accident, vehicle damage, or significant safety issue may result in disciplinary action up to and including termination.</div>' },
  s4: { t:'4. Delivery Quality', h:'<p>Every package should be delivered safely, accurately, and according to Amazon and customer delivery requirements.</p><h3>Customer Instructions</h3><ul><li>Review delivery instructions before completing the delivery.</li><li>Follow reasonable and safe customer instructions.</li><li>Deliver to the correct address and location.</li><li>Never place a package somewhere unsafe merely to avoid returning it.</li><li>Contact the customer when clarification is necessary.</li><li>Contact Dispatch or Driver Support when assistance is required.</li></ul><p>If an instruction is unsafe, impossible, conflicts with policy, or cannot reasonably be completed, contact Dispatch for guidance.</p><h3>Delivered Not Received (DNR)</h3><ul><li>Verify the address before delivery.</li><li>Confirm apartment/unit numbers.</li><li>Follow customer delivery instructions.</li><li>Select an appropriate secure delivery location.</li><li>Take a compliant Photo on Delivery when required.</li><li>Avoid leaving packages in highly visible or unsafe locations when a better approved location is available.</li></ul><p>Repeated preventable quality defects may result in coaching or corrective action.</p>' },
  s5: { t:'5. Contact Compliance', h:'<p>Delivery Associates must follow Amazon\'s current contact requirements when a delivery cannot be successfully completed.</p><p>For applicable situations—including Unable to Access (UTA), Unable to Locate (UTL), No Secure Location (NSL), Customer Unavailable, or other unsuccessful-delivery situations—follow the contact procedure required by Amazon and MVP.</p><h3>When customer contact is required</h3><ul><li>Place the required call and/or send the required text through the approved delivery workflow.</li><li>Allow calls sufficient time to connect.</li><li>Follow Driver Support procedures when required.</li><li>Do not falsely indicate that customer contact was attempted.</li></ul><p><b>The goal is 100% Contact Compliance whenever contact is required.</b></p>' },
  s6: { t:'6. Photo on Delivery', h:'<p>When a Photo on Delivery (POD) is required:</p><ul><li>Make sure the package is clearly visible.</li><li>Take a clear, usable photograph.</li><li>Show enough surroundings to help the customer identify the delivery location.</li><li>Do not intentionally include people in the photograph.</li><li>Do not submit blurry, obstructed, dark, or meaningless photographs.</li><li>Follow Amazon requirements regarding attended deliveries and locations where POD is not appropriate or required.</li></ul><p>Delivery Associates are expected to maintain MVP and Amazon quality standards for Photo on Delivery.</p>' },
  s7: { t:'7. Route Performance & Time Management', h:'<p>Delivery Associates are expected to work consistently and efficiently throughout their routes while maintaining safe driving and delivery practices.</p><ul><li>Begin their route promptly after loadout.</li><li>Maintain reasonable delivery progress throughout the day.</li><li>Take only authorized breaks.</li><li>Avoid unnecessary extended stops or excessive idle time.</li><li>Monitor remaining packages and route progress.</li><li>Communicate with Dispatch before a route becomes significantly behind schedule.</li><li>Follow Dispatch instructions regarding rescues and route adjustments.</li></ul><div class="warn">Do not sacrifice safety or delivery quality to increase speed.</div><p>If you believe you will not complete your route within the expected operating window, contact Dispatch as early as possible rather than waiting until the end of the route.</p><p>MVP\'s objective is to complete routes within scheduled operating hours while complying with applicable work-hour limitations.</p>' },
  s8: { t:'8. Breaks', h:'<p>Delivery Associates may take breaks in accordance with applicable law and company policy.</p><ul><li>Plan breaks responsibly when possible, especially when carrying packages for businesses with limited operating hours.</li><li>Do not intentionally delay time-sensitive business deliveries in order to take an avoidable break immediately before the business closes.</li><li>Do not skip legally required or authorized breaks solely to meet delivery targets.</li></ul>' },
  s9: { t:'9. Return-to-Station Procedures', h:'<p>At the end of your route:</p><ul><li>Contact Dispatch as required when completing your final stop.</li><li>Report packages being returned and the reason for each return.</li><li>Follow the proper Amazon return code/process.</li><li>Return all undelivered packages as instructed.</li><li>Return company equipment, keys, fuel cards, and other assigned property.</li><li>Complete the required vehicle inspection.</li><li>Complete required Flex and ADP procedures before leaving.</li></ul><div class="warn">Never leave the station without completing required end-of-shift procedures.</div>' },
  s10: { t:'10. Fueling', h:'<ul><li>Use the correct fuel type.</li><li>Fuel the vehicle when instructed.</li><li>Return the fuel card as required.</li><li>Immediately report lost fuel cards, declined transactions, incorrect fueling, or other fueling problems to Dispatch.</li></ul>' },
  s11: { t:'11. Attendance & Punctuality', h:'<p>Employees are expected to arrive on time and ready to work for their scheduled shift.</p><p>Repeated tardiness creates operational problems for loadout, route assignments, and other Delivery Associates.</p><p>Depending on operational needs, an employee arriving late may lose some or all scheduled work for that day if the assigned route can no longer be held.</p><p>Repeated or excessive tardiness may result in corrective action.</p>' },
  s12: { t:'12. Callouts & No Call/No Show', h:'<p>If you cannot report for a scheduled shift, notify MVP as soon as possible using the required callout procedure.</p><p>Employees should not wait until immediately before their shift when they already know they will be unable to work.</p><div class="warn">A No Call/No Show is a serious attendance violation and may result in corrective action up to and including termination, subject to applicable law and company policy.</div><p>Repeated attendance problems may also result in corrective action.</p><p><em>Nothing in this policy is intended to interfere with legally protected leave, sick time, disability accommodation, or other rights provided by applicable federal, state, or local law.</em></p>' },
  s13: { t:'13. Time-Off Requests', h:'<ul><li>Planned time-off requests—including vacations, appointments, travel, and other foreseeable obligations—should be submitted at least <b>three weeks in advance</b> whenever possible.</li><li>Earlier notice improves the likelihood that scheduling needs can be accommodated.</li><li>Approval depends on staffing, operational requirements, previously approved requests, and applicable company policies.</li><li>Emergency situations and legally protected absences will be handled in accordance with applicable law and company policy.</li></ul>' },
  s14: { t:'14. Timekeeping', h:'<p>All employees are responsible for accurately recording all time worked.</p><ul><li>Clock in and out accurately using the designated MVP timekeeping system.</li><li>Never clock in or out for another employee.</li><li>Never ask another employee to alter or falsify time records.</li><li>Immediately report a missed or incorrect punch.</li><li>Record all working time as required.</li></ul><div class="warn">Working "off the clock" is prohibited. Intentional falsification or manipulation of time records may result in disciplinary action up to and including termination.</div>' },
  s15: { t:'15. Towing / Vehicle Stuck', h:'<p>Use good judgment before entering narrow driveways, unpaved roads, soft shoulders, mud, snow, grass, areas with insufficient clearance, or locations where turning around may be difficult.</p><p>If uncertain whether the vehicle can safely enter an area, stop and contact Dispatch when necessary.</p><h3>If the vehicle becomes stuck</h3><ul><li>Do not repeatedly accelerate or take actions that could damage the vehicle or property.</li><li>Contact Dispatch immediately.</li><li>Follow Dispatch instructions.</li><li>Document the circumstances when requested.</li></ul><p>Repeated preventable towing incidents may result in coaching or corrective action.</p>' },
  s16: { t:'16. Customer Complaints & Escalations', h:'<p>All customer complaints and Amazon escalations will be reviewed based on the available facts.</p><h3>Examples of serious concerns</h3><ul><li>Unsafe driving</li><li>Threatening or inappropriate behavior</li><li>Intentional property damage</li><li>Falsifying delivery information</li><li>Repeated failure to follow delivery instructions</li><li>Mishandling packages</li><li>Leaving packages at knowingly incorrect locations</li><li>Failure to report an accident or damage</li><li>Other serious violations of Amazon or MVP requirements</li></ul><p>Amazon may independently restrict or remove a driver\'s eligibility to perform Amazon delivery services.</p><p>MVP will address employment-related corrective action based on the circumstances, available evidence, applicable company policies, and applicable law.</p>' },
  s17: { t:'17. Communication with Dispatch', h:'<p>Communication is a core job responsibility. Contact Dispatch promptly when:</p><ul><li>You are significantly behind on your route.</li><li>You have an accident.</li><li>You damage a vehicle or property.</li><li>You become stuck.</li><li>Your vehicle develops a mechanical or safety issue.</li><li>You cannot access or locate a delivery location after following required procedures.</li><li>You experience an emergency.</li><li>You have a package or delivery issue you cannot resolve.</li><li>You believe you may exceed permitted working hours.</li><li>You are instructed to contact Dispatch under another MVP procedure.</li></ul><div class="warn">Do not wait until returning to the station to report a problem that should have been reported on the road.</div>' },
  s18: { t:'18. Corrective Action', h:'<p>MVP Logistics may use coaching and corrective action when performance, attendance, quality, safety, conduct, or policy expectations are not met.</p><h3>Depending on circumstances, corrective action may include</h3><ul><li>Coaching or retraining</li><li>Verbal counseling</li><li>Written warning</li><li>Removal from a route</li><li>Suspension or reduction/removal of scheduled work where permitted</li><li>Final warning</li><li>Termination of employment</li></ul><p>The appropriate response depends on severity, previous incidents, employee conduct, available evidence, Amazon eligibility requirements, and applicable law.</p><p>Serious misconduct or safety violations may warrant immediate action without requiring every progressive disciplinary step.</p>' },
  s19: { t:'19. Amazon Standards vs. MVP Policies', h:'<p>Amazon delivery standards, metrics, technology, and program requirements may change periodically.</p><p>MVP Logistics may update operating procedures as Amazon requirements or business needs change. Employees are responsible for following the most current training and instructions communicated by MVP.</p><p>Amazon performance metrics should not be interpreted as replacing MVP employment policies, and MVP disciplinary guidelines should not be represented as Amazon policies unless they are specifically required by Amazon.</p>' },
  s20: { t:'20. Employee Acknowledgment', h:'<div class="sw-ack"><p>I acknowledge that I have received and reviewed the MVP Logistics LLC Delivery Associate Mandatory Standard Work &amp; Performance document.</p><ul><li>I understand that I am responsible for following applicable MVP policies, safety requirements, delivery procedures, and current Amazon delivery requirements communicated to me.</li><li>I understand that failure to meet these expectations may result in coaching or corrective action, up to and including termination of employment, depending on the circumstances and applicable law.</li><li>I understand that policies and operating procedures may be modified as business, safety, legal, or Amazon requirements change.</li></ul><div class="sw-sig"><div><label>Employee Name</label><div class="ln"></div></div><div><label>Date</label><div class="ln"></div></div><div><label>Employee Signature</label><div class="ln"></div></div><div><label>MVP Representative</label><div class="ln"></div></div><div><label>Representative Date</label><div class="ln"></div></div></div></div>' }
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
