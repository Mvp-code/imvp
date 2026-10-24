<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"
         import="java.util.*,com.util.*,com.beans.*" %>
<%
  String rsLoginUser   = request.getAttribute("loginUser") != null ? request.getAttribute("loginUser").toString() : (String) session.getAttribute("loginUser");
  String rsLoginRoles  = request.getAttribute("loginUserRoles") != null ? request.getAttribute("loginUserRoles").toString() : (String) session.getAttribute("loginUserRoles");
  String rsEntityID    = request.getAttribute("entityID") != null ? request.getAttribute("entityID").toString() : (session.getAttribute("entityID") != null ? session.getAttribute("entityID").toString() : "1");
  String rsDispName    = request.getAttribute("loginUserDisplayName") != null ? request.getAttribute("loginUserDisplayName").toString() : (session.getAttribute("loginUserDisplayName") != null ? session.getAttribute("loginUserDisplayName").toString() : "");
  String rsLoginUserID = request.getAttribute("loginUserID") != null ? request.getAttribute("loginUserID").toString() : (session.getAttribute("loginUserID") != null ? session.getAttribute("loginUserID").toString() : "");
  if (rsLoginUser == null) rsLoginUser = "";
  if (rsLoginRoles == null) rsLoginRoles = "";
  if (rsDispName == null || rsDispName.length() == 0) rsDispName = "User";
  if (rsEntityID == null || rsEntityID.length() == 0) rsEntityID = "1";
  request.setAttribute("loginUser", rsLoginUser);
  request.setAttribute("loginUserRoles", rsLoginRoles);
  request.setAttribute("entityID", rsEntityID);
  request.setAttribute("loginUserDisplayName", rsDispName);
  request.setAttribute("loginUserID", rsLoginUserID);
  request.setAttribute("shellNoForm", "yes");
  request.setAttribute("hideTopbarSearch", "yes");
%>
<jsp:useBean id="_recordBean" class="com.beans.SearchBean" scope="request" />
<%
  _recordBean.setController("RoadsideAssistance");
  _recordBean.setDisplayName("Roadside & Fuel");
  int submitType = SubmitType.SEARCH;
%>
<!DOCTYPE html>
<html lang="en">
<%@ include file="includeHeader.jsp"%>
<script>function validatePageData(submitType, isValid) { return isValid; }</script>
<link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" integrity="sha256-p4NxAoJBhIIN+hmNHrzRCf9tD/miZyoHS5obTRR9BMY=" crossorigin="">
<script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js" integrity="sha256-20nQCchB9co0qIjJZRGuk2/Z9VM+kNiyxNV1lvTlZBo=" crossorigin=""></script>
<style>
.rs-wrap{display:flex;flex-direction:column;height:calc(100vh - 108px);min-height:520px;gap:8px}
.rs-head{display:flex;justify-content:space-between;align-items:flex-start;gap:10px;flex-wrap:wrap;flex-shrink:0}
.rs-head h1{margin:0;font-size:20px;font-weight:700;letter-spacing:-.02em;color:#0F172A}
.rs-sub{font-size:12px;color:#64748B;margin-top:2px;max-width:720px;line-height:1.45}
.rs-tabs{display:inline-flex;border:1px solid #E4E8F0;border-radius:8px;padding:2px;background:#fff}
.rs-tabs button{border:none;background:transparent;padding:6px 12px;font-size:12px;font-weight:700;color:#64748B;cursor:pointer;border-radius:6px}
.rs-tabs button.on{background:#0f172a;color:#fff}
.rs-stage{flex:1;min-height:0;display:grid;grid-template-columns:minmax(0,1.4fr) minmax(320px,420px);gap:8px}
.rs-map{background:#fff;border:1px solid #E4E8F0;border-radius:10px;overflow:hidden;min-height:280px;height:100%;position:relative}
.rs-map .leaflet-container{height:100%;width:100%;min-height:280px;background:#F1F5F9}
.rs-map .leaflet-tile{image-rendering:auto;-ms-interpolation-mode:bicubic}
.rs-base{position:absolute;z-index:500;left:10px;bottom:28px;display:flex;gap:4px;background:#fff;border:1px solid #E4E8F0;border-radius:8px;padding:3px;box-shadow:0 1px 6px rgba(15,23,42,.12)}
.rs-base button{border:none;background:transparent;padding:5px 10px;font-size:11px;font-weight:700;color:#64748B;cursor:pointer;border-radius:6px}
.rs-base button.on{background:#0f172a;color:#fff}
.rs-pin{background:transparent !important;border:none !important}
.rs-mk{display:flex;align-items:center;justify-content:center;border:2px solid #fff;box-shadow:0 1px 4px rgba(15,23,42,.35);font-size:11px;font-weight:800;color:#fff;line-height:1;flex-shrink:0}
.rs-mk-road{width:14px;height:14px;border-radius:50%}
.rs-mk-fuel{width:22px;height:22px;border-radius:6px;font-size:12px}
.rs-lbl{display:flex;align-items:flex-start;gap:5px}
.rs-lbl-card{background:#fff;border:1px solid #E4E8F0;border-radius:8px;padding:5px 8px;box-shadow:0 2px 10px rgba(15,23,42,.16);min-width:148px;max-width:210px}
.rs-lbl-card b{display:block;font-size:12px;font-weight:800;color:#0F172A;line-height:1.25}
.rs-lbl-card .p{font-size:12px;font-weight:700;color:#0F172A;margin-top:2px}
.rs-lbl-card .d{font-size:10.5px;color:#64748B;margin-top:2px;line-height:1.3}
.rs-lbl-fuel{display:flex;align-items:center;gap:4px}
.rs-lbl-fuel .nm{background:#fff;border:1px solid #E4E8F0;border-radius:6px;padding:2px 6px;font-size:11px;font-weight:800;color:#0F172A;box-shadow:0 1px 4px rgba(15,23,42,.12);white-space:nowrap}
.rs-side{background:#fff;border:1px solid #E4E8F0;border-radius:10px;display:flex;flex-direction:column;min-height:0}
.rs-tools{display:flex;gap:6px;flex-wrap:wrap;padding:8px 10px;border-bottom:1px solid #EEF1F6}
.rs-flt{border:1px solid #E4E8F0;border-radius:7px;padding:6px 8px;font-size:12.5px;background:#fff;flex:1;min-width:140px}
.rs-chip{border:1px solid #E4E8F0;background:#fff;border-radius:999px;padding:4px 10px;font-size:11px;font-weight:700;cursor:pointer;color:#475569}
.rs-chip.on{background:#0f172a;border-color:#0f172a;color:#fff}
.rs-list{flex:1;overflow:auto;padding:6px}
.rs-card{border:1px solid #EEF1F6;border-radius:9px;padding:10px 11px;margin:0 4px 7px;cursor:pointer}
.rs-card:hover,.rs-card.on{border-color:#0f172a;background:#F8FAFC}
.rs-card .nm{font-weight:700;color:#0F172A;font-size:13.5px}
.rs-card .meta{color:#64748B;font-size:12px;margin-top:2px;line-height:1.4}
.rs-card .acts{display:flex;gap:6px;flex-wrap:wrap;margin-top:8px}
.rs-pill{display:inline-flex;align-items:center;border-radius:999px;padding:2px 8px;font-size:10.5px;font-weight:700;background:#F1F5F9;color:#475569;margin:2px 4px 0 0}
.rs-pill.pri{background:var(--status-warn-bg,#FBF1E2);color:var(--status-warn-fg,#B45309)}
.rs-pill.ok{background:var(--status-ok-bg,#E7F6EE);color:var(--status-ok-fg,#15803D)}
.rs-pill.info{background:var(--status-info-bg,#EFF4FF);color:var(--status-info-fg,#1D4ED8)}
.rs-pill.mob{background:#F1F5F9;color:#475569}
.btn2{border:1px solid #E4E8F0;background:#fff;color:#111827;padding:5px 10px;border-radius:7px;font-size:12px;font-weight:600;cursor:pointer;text-decoration:none;display:inline-flex;align-items:center}
.btn2.primary{background:#0f172a;border-color:#0f172a;color:#fff}
.rs-panel{display:none;background:#fff;border:1px solid #E4E8F0;border-radius:10px;overflow:auto;padding:14px 16px;flex:1;min-height:0}
.rs-panel.on{display:block}
.rs-panel h3{margin:0 0 8px;font-size:15px}
.rs-panel p,.rs-panel li{font-size:13px;color:#334155;line-height:1.5}
.rs-tbl{width:100%;border-collapse:collapse;margin:8px 0 16px}
.rs-tbl th{text-align:left;font-size:11px;color:#64748B;text-transform:uppercase;letter-spacing:.03em;padding:8px 10px;border-bottom:1px solid #E4E8F0}
.rs-tbl td{padding:8px 10px;border-bottom:1px solid #EEF1F6;font-size:13px;vertical-align:top}
.rs-msg{white-space:pre-wrap;background:#F8FAFC;border:1px solid #E4E8F0;border-radius:8px;padding:12px;font-size:13px;line-height:1.5;color:#0F172A}
.rs-note{font-size:12px;color:#64748B;margin:8px 0 0}
.rs-legend{display:flex;gap:10px;flex-wrap:wrap;font-size:11px;color:#64748B;padding:0 2px}
.rs-dot{width:8px;height:8px;border-radius:50%;display:inline-block;margin-right:4px}
@media (max-width:980px){
  .rs-stage{grid-template-columns:1fr;grid-template-rows:minmax(240px,42vh) minmax(220px,1fr)}
  .rs-wrap{height:auto}
}
</style>

<div class="rs-wrap">
  <div class="rs-head">
    <div>
      <h1>Roadside &amp; Fuel</h1>
      <div class="rs-sub">MVPG Logistics DNK7 roadside network &mdash; Oct 24, 2026. Coverage now runs northwest to Hackettstown / Allamuchy, west through Long Valley / Califon, and south to Hillsborough / Franklin. Fuel pins are WEX approved locations for DNK7, plus approved stations in the gained north (DNJ7 list).</div>
    </div>
    <div class="rs-tabs">
      <button type="button" class="on" id="tabMap" onclick="rsTab('map')">Map</button>
      <button type="button" id="tabCover" onclick="rsTab('cover')">Coverage</button>
      <button type="button" id="tabRates" onclick="rsTab('rates')">Fleet rates</button>
      <button type="button" id="tabMsg" onclick="rsTab('msg')">Outreach</button>
    </div>
  </div>

  <div id="rsMapStage" class="rs-stage">
    <div class="rs-map" role="application" aria-label="Roadside and fuel map">
      <div id="rsMap" style="height:100%;width:100%"></div>
      <div class="rs-base">
        <button type="button" class="on" id="rsBaseStreet" onclick="rsBase('street')">Streets</button>
        <button type="button" id="rsBaseSat" onclick="rsBase('sat')">Satellite</button>
      </div>
    </div>
    <div class="rs-side">
      <div class="rs-tools">
        <input class="rs-flt" id="rsQ" placeholder="Search vendor, town, or station" oninput="rsFilter()">
        <button type="button" class="rs-chip on" data-layer="all" onclick="rsLayer(this,'all')">All</button>
        <button type="button" class="rs-chip" data-layer="road" onclick="rsLayer(this,'road')">Roadside</button>
        <button type="button" class="rs-chip" data-layer="fuel" onclick="rsLayer(this,'fuel')">Fuel</button>
      </div>
      <div class="rs-legend" style="padding:6px 12px 0">
        <span><span class="rs-dot" style="background:#B45309"></span>Call first (6)</span>
        <span><span class="rs-dot" style="background:#1D4ED8"></span>Backup shop</span>
        <span><span class="rs-dot" style="background:#15803D"></span>DNK7 WEX fuel</span>
        <span><span class="rs-dot" style="background:#0F766E"></span>Gained north fuel</span>
      </div>
      <div class="rs-list" id="rsList"></div>
    </div>
  </div>

  <div class="rs-panel" id="rsCover">
    <h3>Territory (Oct 24, 2026)</h3>
    <p><b style="color:#1D4ED8">Blue — no change:</b> Long Valley, Califon, High Bridge, Oldwick, Peapack-Gladstone, Far Hills.
    <b style="color:#15803D">Green — gained:</b> Hackettstown, Allamuchy, Budd Lake, Stanhope, northern routes.
    <b style="color:#B45309">Yellow — temporary:</b> Chester, Mendham.
    <b style="color:#C62828">Red — lost:</b> portions of Bernardsville / Somerville — lower priority unless a live route is still there.</p>
    <p>Fuel: all DNK7 pins come from the WEX <a href="https://lsphelp.iconnectdata.com/approved-locations/" target="_blank" rel="noopener">approved locations</a> list. Teal pins are the same WEX list for DNJ7 (Hackettstown / Budd Lake / Allamuchy / Flanders) so drivers in the gained north have an approved pump.</p>
    <h3>First call by zone</h3>
    <p>Planning ETAs assume an available truck and normal traffic — not a vendor contract. Rural / muddy / late-night recoveries can run 45–90+ minutes.</p>
    <table class="rs-tbl">
      <thead><tr><th>Delivery zone</th><th>First call</th><th>Backup</th><th>Planning ETA</th></tr></thead>
      <tbody>
        <tr><td>Hackettstown, Allamuchy, Great Meadows</td><td>Riccardos</td><td>Knight's</td><td>20–45 min</td></tr>
        <tr><td>Budd Lake, Stanhope, Mount Olive</td><td>Riccardos</td><td>Ron &amp; Sons</td><td>20–45 min</td></tr>
        <tr><td>Long Valley, Middle Valley</td><td>Action Towing</td><td>Ron &amp; Sons</td><td>20–40 min</td></tr>
        <tr><td>Chester, Mendham</td><td>Action Towing</td><td>OnCall</td><td>15–35 min</td></tr>
        <tr><td>Califon, High Bridge, Lebanon</td><td>Superior</td><td>Kovi</td><td>20–40 min</td></tr>
        <tr><td>Oldwick, Far Hills, Peapack</td><td>Superior</td><td>Mike's</td><td>25–45 min</td></tr>
        <tr><td>Bedminster, Pluckemin</td><td>Mike's</td><td>Chain Gang</td><td>20–40 min</td></tr>
        <tr><td>Bridgewater, Branchburg</td><td>Mike's</td><td>Chain Gang</td><td>15–35 min</td></tr>
        <tr><td>Hillsborough, Readington</td><td>Kovi</td><td>Chain Gang</td><td>20–45 min</td></tr>
        <tr><td>Franklin, Somerset, Manville</td><td>A&amp;G Towing</td><td>Derricks</td><td>20–40 min</td></tr>
      </tbody>
    </table>
    <h3>Dispatch SLA to negotiate</h3>
    <table class="rs-tbl">
      <thead><tr><th>KPI</th><th>Requested target</th></tr></thead>
      <tbody>
        <tr><td>Answer dispatch call</td><td>Within 3 minutes</td></tr>
        <tr><td>Confirm acceptance and ETA</td><td>Within 5 minutes</td></tr>
        <tr><td>Arrive in core coverage</td><td>Within 30–45 minutes</td></tr>
        <tr><td>Arrive in rural coverage</td><td>Within 45–60 minutes</td></tr>
        <tr><td>Update if delayed</td><td>Every 15 minutes</td></tr>
        <tr><td>Invoice and photos</td><td>Same day</td></tr>
      </tbody>
    </table>
    <p class="rs-note">A 30-minute arrival is not a 30-minute return-to-service. Spare swap often adds 15–30 minutes on site; a hard winch-out can add 30–90 minutes. Collect wheel/ground photos before authorizing recovery.</p>
  </div>

  <div class="rs-panel" id="rsRates">
    <h3>Target fleet prices</h3>
    <p>MVPG negotiation ranges for Transit / ProMaster / Sprinter — not vendor-confirmed. Confirm the truck can handle loaded high-roof cargo vans.</p>
    <table class="rs-tbl">
      <thead><tr><th>Service</th><th>Target fleet price</th><th>On-site work</th></tr></thead>
      <tbody>
        <tr><td>Flat tire &rarr; install existing spare</td><td>$60–$85</td><td>15–30 min</td></tr>
        <tr><td>Tire repair, where safe</td><td>$65–$100</td><td>20–45 min</td></tr>
        <tr><td>New tire + labor</td><td>Tire + $40–$90 labor</td><td>30–75 min</td></tr>
        <tr><td>Simple driveway pull-out</td><td>$100–$150</td><td>15–30 min</td></tr>
        <tr><td>Grass / mud winch-out</td><td>$125–$225</td><td>20–60 min</td></tr>
        <tr><td>Ditch / steep-slope recovery</td><td>Quoted individually</td><td>45–120+ min</td></tr>
        <tr><td>Local tow, first 5 miles</td><td>$100–$175</td><td>20–45 min to load</td></tr>
        <tr><td>Jump-start</td><td>$50–$75</td><td>10–20 min</td></tr>
      </tbody>
    </table>
    <p class="rs-note">Towing can rise with distance, weight, after-hours, or extra equipment. No work over the quoted amount without dispatcher approval.</p>
  </div>

  <div class="rs-panel" id="rsMsg">
    <h3>Commercial pricing request</h3>
    <p>Send to the six shortlisted vendors: Action, Superior, Riccardos, Mike's, Kovi, and Chain Gang. Verify Action Towing NJ license and insurance before assigning work.</p>
    <p><button type="button" class="btn2 primary" onclick="rsCopyMsg()">Copy message</button></p>
    <div class="rs-msg" id="rsMsgText">Hello,

We operate MVP Logistics LLC (station DNK7), an Amazon Delivery Service Partner with cargo vans across Morris, Hunterdon, Somerset, and Warren counties in New Jersey, including Hackettstown / Allamuchy, Long Valley / Califon, Chester / Mendham, Bridgewater / Bedminster, and Hillsborough / Franklin.

We are looking to establish a long-term relationship with a reliable roadside assistance provider for recurring service calls.

Our primary needs are:
1. Flat tire changes using the spare tire already available in the van.
2. Winch-out assistance for vans stuck in residential driveways, grass, mud, or snow.
3. Occasional jump-starts, lockouts, and towing.

We are interested in negotiated fleet rates rather than standard one-time emergency pricing.

Could you please provide your pricing for these services, coverage areas, average response times, operating hours, and whether you offer monthly billing?

We would be happy to discuss a preferred-vendor arrangement for ongoing business.

Thank you,
MVP Logistics LLC</div>
  </div>
</div>

<script>
var RS_VENDORS = [
  {id:'action', kind:'road', primary:true, name:'Action Towing LLC', phone:'908-879-6960',
    address:'90 Highway 206 South, Chester, NJ 07930', lat:40.78750, lng:-74.69650,
    cover:'Chester, Long Valley, Mendham', hours:'Confirm 24/7',
    services:['Tire','Driveway recovery','Tow'],
    note:'First-call evaluation for Chester–Long Valley. Verify NJ license and insurance before assigning work (USDOT listing may be inactive).'},
  {id:'superior', kind:'road', primary:true, name:'Superior Towing & Transport', phone:'908-534-0110',
    address:'1239 US Highway 22, Lebanon, NJ 08833', lat:40.64368, lng:-74.82967,
    cover:'Lebanon, Califon, High Bridge, Oldwick', hours:'24/7',
    services:['Tow','Winch','Tire'],
    note:'Call first for Califon / High Bridge / Lebanon.'},
  {id:'riccardos', kind:'road', primary:true, name:'Riccardos Towing & Recovery', phone:'201-396-3115',
    address:'1551 NJ-57, Hackettstown, NJ 07840', lat:40.83483, lng:-74.82336,
    cover:'Hackettstown, Stanhope, Hopatcong, Allamuchy', hours:'24/7',
    services:['Tow','Tire','Recovery'],
    note:'Call first for gained north territory. Also lists 450 Riverstyx Rd, Hopatcong.'},
  {id:'mikes', kind:'road', primary:true, name:"Mike's Towing & Recovery", phone:'908-722-2122',
    address:'643 East Main Street, Bridgewater, NJ 08807', lat:40.56290, lng:-74.57538,
    cover:'Bridgewater, Branchburg, Bedminster', hours:'24-hour dispatch',
    services:['Tow','Recovery','Tire'],
    note:'Call first for Bridgewater / Bedminster. Also 58 Chambers Brook Rd, Branchburg.'},
  {id:'kovi', kind:'road', primary:true, name:'Kovi Towing LLC', phone:'908-782-8333',
    address:'600 US 206, Hillsborough, NJ 08844', lat:40.50193, lng:-74.64506,
    cover:'Readington, Hillsborough, Hunterdon', hours:'24/7',
    services:['Tow','Winch','Tire'],
    note:'Call first for Hillsborough / Readington. Yards also in Flemington (685 Route 12) and Hopewell.'},
  {id:'chaingang', kind:'road', primary:true, name:'Chain Gang Towing & Recovery', phone:'908-642-3699',
    address:'203 Valley Road, Hillsborough, NJ 08844', lat:40.52512, lng:-74.64374,
    cover:'Hillsborough, Raritan, Somerville', hours:'24/7 dispatch',
    services:['Tow','Winch','Tire'],
    note:'Call first backup for Bedminster / Bridgewater / Hillsborough.'},
  {id:'knights', kind:'road', name:"Knight's Service Center & Towing", phone:'908-892-5337',
    address:'3 US-46, Hackettstown, NJ 07840', lat:40.85864, lng:-74.83928,
    cover:'Hackettstown, Beattystown', hours:'Confirm hours',
    services:['Tow','Spare swap'],
    note:'Backup for Hackettstown / Allamuchy.'},
  {id:'ronsons', kind:'road', name:'Ron & Sons Towing', phone:'973-927-9194',
    address:'745 US-46, Kenvil, NJ 07847', lat:40.87948, lng:-74.63147,
    cover:'Roxbury, Flanders, Chester', hours:'24/7',
    services:['Tow','Winch','Tire'],
    note:'Backup for Long Valley and Mount Olive.'},
  {id:'oncall', kind:'road', mobile:true, name:'OnCall Road Service', phone:'973-651-1140',
    address:'Mobile — Randolph / Chester / Mendham', lat:null, lng:null,
    cover:'Randolph, Chester, Mendham', hours:'Confirm hours',
    services:['Tire','Roadside','Tow'],
    note:'Mobile only — not plotted. Backup for Chester / Mendham.'},
  {id:'steven', kind:'road', name:'Steven Truck Repair', phone:'973-610-7310',
    address:'524 US-46, Kenvil, NJ 07847', lat:40.87968, lng:-74.61964,
    cover:'Roxbury, Mount Olive', hours:'24/7',
    services:['Commercial tow','Repair'],
    note:'Commercial repair backup on US-46.'},
  {id:'ag', kind:'road', name:'A&G Towing & Recovery', phone:'908-500-0802',
    address:'22 Arlington Avenue, Somerset, NJ 08873', lat:40.50634, lng:-74.47284,
    cover:'Franklin, Somerset, Hillsborough', hours:'24/7',
    services:['Tow','Winch','Tire'],
    note:'First call for Franklin / Somerset / Manville.'},
  {id:'derricks', kind:'road', name:'Derricks Towing & Recovery', phone:'908-239-4663',
    address:'550 Bound Brook Rd, Middlesex, NJ 08846', lat:40.58275, lng:-74.48738,
    cover:'Middlesex, Bridgewater, Franklin', hours:'24/7',
    services:['Tow','Winch','Roadside'],
    note:'Backup for Franklin / Somerset.'},
  {id:'rossano', kind:'road', name:'Rossano & Sons Towing', phone:'973-919-5060',
    address:'56 Paterson Ave, Newton, NJ 07860', lat:41.04146, lng:-74.75393,
    cover:'Northern routes, backup', hours:'24/7',
    services:['Tow','Winch','Tire'],
    note:'Far-north backup only.'}
];

var RS_FUEL = [
  {id:'usfuel', kind:'fuel', allowed:true, name:'US Fuel', address:'345 US-22, Dunellen, NJ 08812', lat:40.58920, lng:-74.46850, area:'DNK7 WEX · North · 2.9 mi'},
  {id:'valero', kind:'fuel', allowed:true, name:'Valero Green Brook', address:'280-282 Rt 22 West, Green Brook, NJ 08812', lat:40.58217, lng:-74.51719, area:'DNK7 WEX · North · 4.4 mi'},
  {id:'josan', kind:'fuel', allowed:true, name:'Josan Fuel Inc.', address:'421 Somerset St, North Plainfield, NJ 07060', lat:40.62369, lng:-74.43275, area:'DNK7 WEX · Northeast · 7.9 mi'},
  {id:'fuel4met', kind:'fuel', allowed:true, name:'Fuel 4 Metuchen', address:'621 Middlesex Avenue, Metuchen, NJ 08840', lat:40.54141, lng:-74.36596, area:'DNK7 WEX · East · 9.4 mi'},
  {id:'fuelwaymet', kind:'fuel', allowed:true, name:'Fuelway Metuchen', address:'209 Central Ave, Metuchen, NJ 08840', lat:40.54486, lng:-74.37003, area:'DNK7 WEX · East · 9.7 mi'},
  {id:'fuelwayed', kind:'fuel', allowed:true, name:'Fuelway Edison', address:'1808 Woodbridge Avenue, Edison, NJ 08817', lat:40.50086, lng:-74.41112, area:'DNK7 WEX · Southeast · 9.2 mi'},
  {id:'exxoned', kind:'fuel', allowed:true, name:'Edison Exxon', address:'470 US Hwy 1 N, Edison, NJ 08817', lat:40.50054, lng:-74.39839, area:'DNK7 WEX · Southeast · 9.5 mi'},
  {id:'vp', kind:'fuel', allowed:true, name:'VP Racing Fuels', address:'1300 NJ-27, North Brunswick, NJ 08902', lat:40.47024, lng:-74.49371, area:'DNK7 WEX · South · 9.6 mi'},
  {id:'711franklin', kind:'fuel', allowed:true, name:'Franklin 7-Eleven', address:'2 Veronica Ave, Somerset, NJ 08873', lat:40.48746, lng:-74.50228, area:'DNK7 WEX · South · 7.6 mi'},
  {id:'delta', kind:'fuel', allowed:true, name:'Delta Hillsborough', address:'1008 Amwell Rd, Hillsborough, NJ 08844', lat:40.47750, lng:-74.62700, area:'DNK7 WEX · Southwest · 7.4 mi'},
  {id:'qc35', kind:'fuel', allowed:true, name:'QuickChek #35', address:'273 US Highway 206, Hillsborough, NJ 08844', lat:40.47700, lng:-74.64780, area:'DNK7 WEX · Southwest · 8.5 mi'},
  {id:'exxon22', kind:'fuel', allowed:true, name:'North Bridge Exxon', address:'960 US Rt 22 East, Somerville, NJ 08876', lat:40.57280, lng:-74.58600, area:'DNK7 WEX · West · 6.3 mi'},
  {id:'fuel4bw', kind:'fuel', allowed:true, name:'Fuel 4 Bridgewater', address:'555 Union Ave, Bridgewater, NJ 08807', lat:40.56851, lng:-74.56608, area:'DNK7 WEX · West · 3.4 mi'},
  {id:'speedway', kind:'fuel', allowed:true, name:'Speedway Bound Brook', address:'1620 US Highway 22, Bound Brook, NJ 08805', lat:40.57780, lng:-74.53534, area:'DNK7 WEX · Northwest · 3.2 mi'},
  {id:'shell', kind:'fuel', allowed:true, name:'Shell Martinsville', address:'1972 Washington Valley Rd, Martinsville, NJ 08836', lat:40.60067, lng:-74.56012, area:'DNK7 WEX · Northwest · 5.1 mi'},
  {id:'stanhope', kind:'fuel', allowed:true, north:true, name:'Stanhope Delta', address:'24 NJ-183, Stanhope, NJ 07874', lat:40.90280, lng:-74.70950, area:'Gained north · WEX DNJ7 · 1.6 mi from DNJ7'},
  {id:'fuel1ledge', kind:'fuel', allowed:true, north:true, name:'Fuel 1 Ledgewood', address:'1174 US-46, Ledgewood, NJ 07852', lat:40.87720, lng:-74.65180, area:'Gained north · WEX DNJ7'},
  {id:'fuel4kenvil', kind:'fuel', allowed:true, north:true, name:'Fuel 4 Kenvil', address:'666 US-46, Kenvil, NJ 07852', lat:40.88120, lng:-74.62300, area:'Gained north · WEX DNJ7'},
  {id:'fuel4succ', kind:'fuel', allowed:true, north:true, name:'Fuel 4 Succasunna', address:'11 NJ-10, Roxbury Township, NJ 07876', lat:40.86950, lng:-74.64100, area:'Gained north · WEX DNJ7'},
  {id:'wawafland', kind:'fuel', allowed:true, north:true, name:'Wawa #8446 Flanders', address:'Rt 206 & Flanders-Netcong Rd, Flanders, NJ 07836', lat:40.84700, lng:-74.70000, area:'Gained north · WEX DNJ7'},
  {id:'sunocofland', kind:'fuel', allowed:true, north:true, name:'Sunoco Flanders', address:'236 US Highway 206, Flanders, NJ 07836', lat:40.84500, lng:-74.69800, area:'Gained north · WEX DNJ7'},
  {id:'nj0004', kind:'fuel', allowed:true, north:true, name:'Hackettstown Rt 57', address:'104 Route 57, Hackettstown, NJ 07840', lat:40.85200, lng:-74.83000, area:'Gained north · WEX DNJ7'},
  {id:'deltabudd', kind:'fuel', allowed:true, north:true, name:'Delta Budd Lake', address:'132 US-46, Mount Olive, NJ 07828', lat:40.88079, lng:-74.73167, area:'Gained north · WEX DNJ7'},
  {id:'usgashack', kind:'fuel', allowed:true, north:true, name:'US Gas Hackettstown', address:'104 Main St, Hackettstown, NJ 07840', lat:40.85454, lng:-74.83117, area:'Gained north · WEX DNJ7'},
  {id:'qcmeadows', kind:'fuel', allowed:true, north:true, name:'QuickChek #108', address:'918-920 County 517, Great Meadows, NJ 07838', lat:40.87600, lng:-74.89600, area:'Gained north · WEX DNJ7'},
  {id:'shellbudd', kind:'fuel', allowed:true, north:true, name:'Shell Budd Lake', address:'35 US Highway 46, Budd Lake, NJ 07828', lat:40.87100, lng:-74.75350, area:'Gained north · WEX DNJ7'},
  {id:'shellalla', kind:'fuel', allowed:true, north:true, name:'Shell Allamuchy', address:'1707 Route 517, Allamuchy, NJ 07820', lat:40.92150, lng:-74.81200, area:'Gained north · WEX DNJ7'}
];

var rsLayerMode = 'all';
var rsMap, rsMarkers = {}, rsSel = null;

function rsAll() { return RS_VENDORS.concat(RS_FUEL); }

function rsMapsUrl(item) {
  return 'https://www.google.com/maps/search/?api=1&query=' + encodeURIComponent(item.address || item.name);
}
function rsWazeUrl(item) {
  if (item.lat && item.lng)
    return 'https://waze.com/ul?ll=' + item.lat + '%2C' + item.lng + '&navigate=yes';
  return 'https://waze.com/ul?q=' + encodeURIComponent(item.address || item.name) + '&navigate=yes';
}
function rsTel(p) { return 'tel:+1' + String(p || '').replace(/\D/g, ''); }
function rsEsc(s) {
  return String(s || '').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}

function rsIcon(item) {
  var fuel = item.kind === 'fuel';
  var color = fuel ? (item.north ? '#0F766E' : '#15803D') : (item.primary ? '#B45309' : '#1D4ED8');
  var html;
  if (fuel) {
    html = '<div class="rs-lbl-fuel"><div class="rs-mk rs-mk-fuel" style="background:' + color + '">⛽</div>'
      + '<span class="nm">' + rsEsc(item.name) + '</span></div>';
    return L.divIcon({ className: 'rs-pin', html: html, iconSize: [170, 26], iconAnchor: [11, 13], popupAnchor: [0, -12] });
  }
  var svc = (item.services || []).join(' · ');
  html = '<div class="rs-lbl"><div class="rs-mk rs-mk-road" style="background:' + color + '"></div>'
    + '<div class="rs-lbl-card">'
    + '<b>' + rsEsc(item.name) + '</b>'
    + (item.phone ? '<div class="p">' + rsEsc(item.phone) + '</div>' : '')
    + (item.cover ? '<div class="d">' + rsEsc(item.cover) + '</div>' : '')
    + (svc ? '<div class="d">' + rsEsc(svc) + '</div>' : '')
    + (item.hours ? '<div class="d">' + rsEsc(item.hours) + '</div>' : '')
    + '</div></div>';
  return L.divIcon({ className: 'rs-pin', html: html, iconSize: [230, 86], iconAnchor: [8, 10], popupAnchor: [80, -8] });
}

function rsVisible(item) {
  if (rsLayerMode === 'road' && item.kind !== 'road') return false;
  if (rsLayerMode === 'fuel' && item.kind !== 'fuel') return false;
  var q = (document.getElementById('rsQ').value || '').toLowerCase();
  if (!q) return true;
  var hay = [item.name, item.address, item.cover, item.area, item.phone, (item.services || []).join(' ')].join(' ').toLowerCase();
  return hay.indexOf(q) >= 0;
}

function rsPopup(item) {
  var bits = '<div style="min-width:180px"><b>' + rsEsc(item.name) + '</b><div style="margin-top:4px;color:#64748B">'
    + rsEsc(item.address) + '</div>';
  if (item.phone) bits += '<div style="margin-top:6px"><a href="' + rsTel(item.phone) + '">' + rsEsc(item.phone) + '</a></div>';
  if (item.services) bits += '<div style="margin-top:6px">' + item.services.map(function(s){ return rsEsc(s); }).join(' · ') + '</div>';
  bits += '<div style="margin-top:8px;display:flex;gap:6px;flex-wrap:wrap">';
  if (item.phone) bits += '<a class="btn2 primary" href="' + rsTel(item.phone) + '">Call</a>';
  bits += '<a class="btn2" target="_blank" rel="noopener" href="' + rsMapsUrl(item) + '">Maps</a>';
  bits += '<a class="btn2" target="_blank" rel="noopener" href="' + rsWazeUrl(item) + '">Waze</a></div></div>';
  return bits;
}

function rsCard(item) {
  var pills = '';
  if (item.primary) pills += '<span class="rs-pill pri">Call first</span>';
  if (item.mobile) pills += '<span class="rs-pill mob">Mobile</span>';
  if (item.allowed && item.north) pills += '<span class="rs-pill info">WEX gained north</span>';
  else if (item.allowed) pills += '<span class="rs-pill ok">WEX DNK7</span>';
  if (item.hours) pills += '<span class="rs-pill info">' + rsEsc(item.hours) + '</span>';
  (item.services || []).forEach(function(s){ pills += '<span class="rs-pill">' + rsEsc(s) + '</span>'; });
  var acts = '';
  if (item.phone) acts += '<a class="btn2 primary" href="' + rsTel(item.phone) + '" onclick="event.stopPropagation()">Call</a>';
  acts += '<a class="btn2" target="_blank" rel="noopener" href="' + rsMapsUrl(item) + '" onclick="event.stopPropagation()">Maps</a>';
  acts += '<a class="btn2" target="_blank" rel="noopener" href="' + rsWazeUrl(item) + '" onclick="event.stopPropagation()">Waze</a>';
  return '<div class="rs-card' + (rsSel === item.id ? ' on' : '') + '" data-id="' + item.id + '" onclick="rsFocus(\'' + item.id + '\')">'
    + '<div class="nm">' + rsEsc(item.name) + '</div>'
    + '<div class="meta">' + rsEsc(item.address) + (item.phone ? '<br>' + rsEsc(item.phone) : '')
    + (item.cover ? '<br>' + rsEsc(item.cover) : '')
    + (item.area ? '<br>' + rsEsc(item.area) : '')
    + (item.note ? '<br>' + rsEsc(item.note) : '') + '</div>'
    + '<div>' + pills + '</div><div class="acts">' + acts + '</div></div>';
}

function rsRenderList() {
  var road = '', fuel = '';
  rsAll().forEach(function(item) {
    if (!rsVisible(item)) return;
    if (item.kind === 'fuel') fuel += rsCard(item);
    else road += rsCard(item);
  });
  var html = '';
  if (road) html += '<div class="rs-note" style="padding:4px 8px 6px;font-weight:800;text-transform:uppercase;letter-spacing:.04em">Roadside</div>' + road;
  if (fuel) html += '<div class="rs-note" style="padding:8px 8px 6px;font-weight:800;text-transform:uppercase;letter-spacing:.04em">Gas stations</div>' + fuel;
  document.getElementById('rsList').innerHTML = html || '<div class="rs-note" style="padding:16px">No matches.</div>';
}

function rsSyncMarkers() {
  Object.keys(rsMarkers).forEach(function(id) {
    var item = rsAll().filter(function(x){ return x.id === id; })[0];
    var m = rsMarkers[id];
    if (!item || !m) return;
    if (rsVisible(item) && item.lat && item.lng) {
      if (!rsMap.hasLayer(m)) m.addTo(rsMap);
    } else if (rsMap.hasLayer(m)) {
      rsMap.removeLayer(m);
    }
  });
}

function rsFit() {
  var pts = [];
  rsAll().forEach(function(item) {
    if (rsVisible(item) && item.lat && item.lng) pts.push([item.lat, item.lng]);
  });
  if (!rsMap || !pts.length) return;
  rsMap.fitBounds(pts, { padding: [48, 48], maxZoom: 11 });
}

function rsFilter() { rsRenderList(); rsSyncMarkers(); }

function rsLayer(btn, mode) {
  rsLayerMode = mode;
  document.querySelectorAll('.rs-chip[data-layer]').forEach(function(b){ b.classList.toggle('on', b === btn); });
  rsFilter();
  rsFit();
}

function rsFocus(id) {
  rsSel = id;
  rsRenderList();
  var item = rsAll().filter(function(x){ return x.id === id; })[0];
  if (!item) return;
  var el = document.querySelector('.rs-card[data-id="' + id + '"]');
  if (el) el.scrollIntoView({ block: 'nearest' });
  if (item.lat && item.lng && rsMarkers[id]) {
    rsMap.setView([item.lat, item.lng], 13);
    rsMarkers[id].openPopup();
  }
}

function rsTab(which) {
  document.getElementById('rsMapStage').style.display = which === 'map' ? '' : 'none';
  document.getElementById('rsCover').classList.toggle('on', which === 'cover');
  document.getElementById('rsRates').classList.toggle('on', which === 'rates');
  document.getElementById('rsMsg').classList.toggle('on', which === 'msg');
  document.getElementById('tabMap').classList.toggle('on', which === 'map');
  document.getElementById('tabCover').classList.toggle('on', which === 'cover');
  document.getElementById('tabRates').classList.toggle('on', which === 'rates');
  document.getElementById('tabMsg').classList.toggle('on', which === 'msg');
  if (which === 'map' && rsMap) setTimeout(function(){ rsMap.invalidateSize(); }, 60);
}

function rsCopyMsg() {
  var t = document.getElementById('rsMsgText').innerText;
  if (navigator.clipboard && navigator.clipboard.writeText) {
    navigator.clipboard.writeText(t).then(function(){
      if (typeof mvpxToast === 'function') mvpxToast('Message copied', true);
      else alert('Copied');
    });
  } else {
    var ta = document.createElement('textarea'); ta.value = t; document.body.appendChild(ta); ta.select();
    document.execCommand('copy'); document.body.removeChild(ta);
    alert('Copied');
  }
}

var rsStreetLayer, rsSatLayer, rsBaseMode = 'street';
function rsBase(mode) {
  rsBaseMode = mode;
  var streetBtn = document.getElementById('rsBaseStreet');
  var satBtn = document.getElementById('rsBaseSat');
  if (streetBtn) streetBtn.classList.toggle('on', mode === 'street');
  if (satBtn) satBtn.classList.toggle('on', mode === 'sat');
  if (!rsMap) return;
  if (mode === 'sat') {
    if (rsMap.hasLayer(rsStreetLayer)) rsMap.removeLayer(rsStreetLayer);
    if (!rsMap.hasLayer(rsSatLayer)) rsSatLayer.addTo(rsMap);
  } else {
    if (rsMap.hasLayer(rsSatLayer)) rsMap.removeLayer(rsSatLayer);
    if (!rsMap.hasLayer(rsStreetLayer)) rsStreetLayer.addTo(rsMap);
  }
}

(function initMap() {
  rsMap = L.map('rsMap', { scrollWheelZoom: true, zoomSnap: 0.5 }).setView([40.58, -74.52], 10);
  rsStreetLayer = L.tileLayer('https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png', {
    attribution: '&copy; OpenStreetMap &copy; CARTO',
    subdomains: 'abcd',
    maxZoom: 20
  });
  rsSatLayer = L.tileLayer('https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}', {
    attribution: 'Esri',
    maxZoom: 19
  });
  rsStreetLayer.addTo(rsMap);
  rsAll().forEach(function(item) {
    if (!item.lat || !item.lng) return;
    var m = L.marker([item.lat, item.lng], { icon: rsIcon(item), title: item.name, zIndexOffset: item.kind === 'road' ? 400 : 120 });
    m.bindPopup(rsPopup(item));
    m.on('click', function(){ rsFocus(item.id); });
    m.addTo(rsMap);
    rsMarkers[item.id] = m;
  });
  rsRenderList();
  setTimeout(function(){
    rsMap.invalidateSize();
    rsFit();
  }, 80);
})();
</script>
<%@ include file="includeFooter.jsp"%>
