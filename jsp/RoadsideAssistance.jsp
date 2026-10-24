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
.rs-pin{background:transparent !important;border:none !important}
.rs-mk{display:flex;align-items:center;justify-content:center;border:2px solid #fff;box-shadow:0 1px 4px rgba(15,23,42,.35);font-size:11px;font-weight:800;color:#fff;line-height:1}
.rs-mk-road{width:14px;height:14px;border-radius:50%}
.rs-mk-fuel{width:26px;height:26px;border-radius:6px;font-size:13px}
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
      <div class="rs-sub">Preferred roadside vendors and allowed fuel stops for MVP Logistics (DNK7) across Morris, Hunterdon, Somerset, and Warren counties. Confirm dispatch coverage and fleet rates before the first paid call.</div>
    </div>
    <div class="rs-tabs">
      <button type="button" class="on" id="tabMap" onclick="rsTab('map')">Map</button>
      <button type="button" id="tabCover" onclick="rsTab('cover')">Coverage</button>
      <button type="button" id="tabRates" onclick="rsTab('rates')">Fleet rates</button>
      <button type="button" id="tabMsg" onclick="rsTab('msg')">Outreach</button>
    </div>
  </div>

  <div id="rsMapStage" class="rs-stage">
    <div class="rs-map" id="rsMap" role="application" aria-label="Roadside and fuel map"></div>
    <div class="rs-side">
      <div class="rs-tools">
        <input class="rs-flt" id="rsQ" placeholder="Search vendor, town, or station" oninput="rsFilter()">
        <button type="button" class="rs-chip on" data-layer="all" onclick="rsLayer(this,'all')">All</button>
        <button type="button" class="rs-chip" data-layer="road" onclick="rsLayer(this,'road')">Roadside</button>
        <button type="button" class="rs-chip" data-layer="fuel" onclick="rsLayer(this,'fuel')">Fuel</button>
      </div>
      <div class="rs-legend" style="padding:6px 12px 0">
        <span><span class="rs-dot" style="background:#B45309"></span>Call first</span>
        <span><span class="rs-dot" style="background:#1D4ED8"></span>Backup / shop</span>
        <span><span class="rs-dot" style="background:#15803D"></span>Allowed fuel</span>
        <span><span class="rs-dot" style="background:#64748B"></span>Nearby fuel</span>
      </div>
      <div class="rs-list" id="rsList"></div>
    </div>
  </div>

  <div class="rs-panel" id="rsCover">
    <h3>Coverage assignments</h3>
    <p>Proposed primary and backup by delivery area. These are starting assignments from shop locations — not confirmed territories or response times.</p>
    <table class="rs-tbl">
      <thead><tr><th>Delivery area</th><th>Primary</th><th>Backup</th></tr></thead>
      <tbody>
        <tr><td>Hackettstown, Washington</td><td>Knight's Service Center</td><td>Riccardos Towing</td></tr>
        <tr><td>Long Valley, Chester</td><td>OnCall Road Service</td><td>Ron &amp; Sons</td></tr>
        <tr><td>Califon, Lebanon, Clinton</td><td>Superior Towing</td><td>Knight's</td></tr>
        <tr><td>Bedminster, Basking Ridge</td><td>Derricks Towing</td><td>Liberty Mobile Tire</td></tr>
        <tr><td>Roxbury, Flanders, Mount Olive</td><td>Ron &amp; Sons</td><td>Steven Truck Repair</td></tr>
      </tbody>
    </table>
    <h3>What to ask for</h3>
    <ul>
      <li>Fixed price to install the van's existing spare — no tire sale required.</li>
      <li>Fixed price for a simple driveway / grass winch-out, plus an hourly rate for hard recoveries.</li>
      <li>No extra mileage inside an agreed radius; 30–45 minute target arrival when a truck is available.</li>
      <li>Dispatch through 10 PM, ideally 24/7. Monthly invoice with vehicle number, location, service type, photos.</li>
      <li>No work over the quoted amount without dispatcher approval. Collect wheel/ground photos before authorizing a stuck-van recovery.</li>
    </ul>
  </div>

  <div class="rs-panel" id="rsRates">
    <h3>Target fleet prices</h3>
    <p>Negotiation targets for cargo vans (Transit, ProMaster, Sprinter) — not confirmed quotes. Rates must apply to the van's actual weight.</p>
    <table class="rs-tbl">
      <thead><tr><th>Service</th><th>Target fleet price</th><th>Priority</th></tr></thead>
      <tbody>
        <tr><td>Replace flat with van's spare</td><td>$60–$85</td><td>High</td></tr>
        <tr><td>Simple winch-out from driveway/grass</td><td>$100–$150</td><td>High</td></tr>
        <tr><td>Mud/ditch recovery, extra equipment</td><td>$150–$250+</td><td>High</td></tr>
        <tr><td>Jump-start</td><td>$50–$75</td><td>Medium</td></tr>
        <tr><td>Vehicle lockout</td><td>$60–$85</td><td>Medium</td></tr>
        <tr><td>Local tow, up to 5 miles</td><td>$100–$150</td><td>Medium</td></tr>
      </tbody>
    </table>
    <p class="rs-note">Published starting points elsewhere: Majestic Towing $75 tire / $100 per half-hour winch; Road Heroes tire from $85 and recovery from $95. Use those only as a ceiling when you call.</p>
  </div>

  <div class="rs-panel" id="rsMsg">
    <h3>Commercial pricing request</h3>
    <p>Copy and send when you call the four first vendors: Superior, OnCall, Ron &amp; Sons, and Knight's.</p>
    <p><button type="button" class="btn2 primary" onclick="rsCopyMsg()">Copy message</button></p>
    <div class="rs-msg" id="rsMsgText">Hello,

We operate MVP Logistics LLC, an Amazon Delivery Service Partner with a fleet of delivery cargo vans operating across Morris, Hunterdon, Somerset, and Warren counties in New Jersey.

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
  {id:'superior', kind:'road', primary:true, name:'Superior Towing & Transport', phone:'908-534-0110',
    address:'1239 US Highway 22, Lebanon, NJ 08833', lat:40.64368, lng:-74.82967,
    cover:'Lebanon, Clinton, Califon', hours:'24/7',
    services:['Tire change','Winch-out','Tow','Jump','Lockout'],
    note:'Call first for western routes. Shop on US-22.'},
  {id:'oncall', kind:'road', primary:true, mobile:true, name:'OnCall Road Service', phone:'973-651-1140',
    address:'Mobile — Randolph / Chester / Long Valley', lat:null, lng:null,
    cover:'Randolph, Chester, Long Valley', hours:'Confirm hours',
    services:['Spare swap','Roadside'],
    note:'Mobile only — not plotted. Call first for Long Valley / Chester.'},
  {id:'knights', kind:'road', primary:true, name:"Knight's Service Center & Towing", phone:'908-892-5337',
    address:'3 US-46, Hackettstown, NJ 07840', lat:40.85864, lng:-74.83928,
    cover:'Hackettstown and western routes', hours:'Confirm hours',
    services:['Tow','Tire','Roadside'],
    note:'Call first for Hackettstown / Washington.'},
  {id:'ronsons', kind:'road', primary:true, name:'Ron & Sons Towing', phone:'973-927-9194',
    address:'745 US-46, Kenvil, NJ 07847', lat:40.87948, lng:-74.63147,
    cover:'Kenvil, Roxbury, Chester', hours:'24/7',
    services:['Off-road recovery','Winch','Tow'],
    note:'Call first for Roxbury / Flanders / Mount Olive. Also 15 Pine St, Kenvil.'},
  {id:'rossano', kind:'road', name:'Rossano & Sons Towing', phone:'973-919-5060',
    address:'56 Paterson Ave, Newton, NJ 07860', lat:41.04146, lng:-74.75393,
    cover:'Northwestern NJ', hours:'24/7',
    services:['Tire change','Driveway winch','Tow','Jump','Lockout'],
    note:'Backup for northern / northwestern routes.'},
  {id:'derricks', kind:'road', name:'Derricks Towing & Recovery', phone:'908-239-4663',
    address:'550 Bound Brook Rd, Middlesex, NJ 08846', lat:40.58275, lng:-74.48738,
    cover:'Central Somerset / Raritan Valley', hours:'24/7',
    services:['Tow','Recovery','Lockout'],
    note:'Primary for Bedminster / Basking Ridge.'},
  {id:'liberty', kind:'road', mobile:true, name:'Liberty Mobile Tire Service', phone:'908-365-7779',
    address:'Mobile tire — Central NJ', lat:null, lng:null,
    cover:'Mobile tire / potential fleet support', hours:'Confirm hours',
    services:['Mobile tire'],
    note:'Mobile only — not plotted. Backup for Bedminster / Basking Ridge.'},
  {id:'rapid', kind:'road', mobile:true, name:'Rapid Mobile Tire Repair', phone:'848-468-1726',
    address:'Mobile tire — Central NJ', lat:null, lng:null,
    cover:'Mobile tire changes across Central NJ', hours:'Confirm hours',
    services:['Mobile tire'],
    note:'Mobile only — not plotted.'},
  {id:'steven', kind:'road', name:'Steven Truck Repair', phone:'973-610-7310',
    address:'524 US-46, Kenvil, NJ 07847', lat:40.87968, lng:-74.61964,
    cover:'Kenvil, Roxbury — commercial tow and repair', hours:'24/7',
    services:['Commercial tow','Truck repair'],
    note:'Backup for Roxbury / Flanders / Mount Olive.'},
  {id:'riccardos', kind:'road', name:"Riccardos Towing & Recovery", phone:'201-396-3115',
    address:'1551 NJ-57, Hackettstown, NJ 07840', lat:40.83483, lng:-74.82336,
    cover:'Hackettstown 24/7 light/medium duty', hours:'24/7',
    services:['Tire','Tow','Jump','Lockout'],
    note:'Second Hackettstown option. riccardostowing.com'}
];

var RS_FUEL = [
  {id:'usfuel', kind:'fuel', allowed:true, name:'US Fuel', phone:'',
    address:'345 US-22, Dunellen, NJ 08812', lat:40.58920, lng:-74.46850, area:'DNK7 / Route 22'},
  {id:'speedway', kind:'fuel', allowed:true, name:'Speedway', phone:'',
    address:'1620 US Highway 22, Bound Brook, NJ 08805', lat:40.57780, lng:-74.53534, area:'DNK7 / Route 22'},
  {id:'fuel4bw', kind:'fuel', allowed:true, name:'Fuel 4', phone:'',
    address:'555 Union Ave, Bridgewater, NJ 08807', lat:40.56851, lng:-74.56608, area:'DNK7 / Route 22'},
  {id:'valero', kind:'fuel', allowed:true, name:'Valero Green Brook', phone:'',
    address:'280-282 Rt 22 West, Green Brook, NJ 08812', lat:40.58217, lng:-74.51719, area:'DNK7 / Route 22'},
  {id:'shell', kind:'fuel', allowed:true, name:'Shell Oil', phone:'',
    address:'1972 Washington Valley Rd, Martinsville, NJ 08836', lat:40.60067, lng:-74.56012, area:'DNK7 / Route 22'},
  {id:'exxon22', kind:'fuel', allowed:true, name:'North Bridge Exxon', phone:'',
    address:'960 US Rt 22 East, Somerville, NJ 08876', lat:40.57280, lng:-74.58600, area:'DNK7 / Route 22'},
  {id:'josan', kind:'fuel', allowed:true, name:'Josan Fuel Inc.', phone:'',
    address:'421 Somerset St, North Plainfield, NJ 07060', lat:40.62369, lng:-74.43275, area:'DNK7 / Route 22'},
  {id:'delta', kind:'fuel', nearby:true, name:'Delta', phone:'',
    address:'1008 Amwell Rd, Hillsborough, NJ 08844', lat:40.47750, lng:-74.62700, area:'Nearby south'},
  {id:'711franklin', kind:'fuel', nearby:true, name:'Franklin 7-Eleven', phone:'',
    address:'2 Veronica Ave, Somerset, NJ 08873', lat:40.48746, lng:-74.50228, area:'Nearby south'},
  {id:'qc35', kind:'fuel', nearby:true, name:'QuickChek #35', phone:'',
    address:'273 US Highway 206, Hillsborough, NJ 08844', lat:40.47700, lng:-74.64780, area:'Nearby south'},
  {id:'fuelwayed', kind:'fuel', nearby:true, name:'Fuelway Edison', phone:'',
    address:'1808 Woodbridge Avenue, Edison, NJ 08817', lat:40.50086, lng:-74.41112, area:'Nearby east'},
  {id:'fuel4met', kind:'fuel', nearby:true, name:'Fuel 4 Metuchen', phone:'',
    address:'621 Middlesex Avenue, Metuchen, NJ 08840', lat:40.54141, lng:-74.36596, area:'Nearby east'},
  {id:'exxoned', kind:'fuel', nearby:true, name:'Edison Exxon', phone:'',
    address:'470 US Hwy 1 N, Edison, NJ 08817', lat:40.50054, lng:-74.39839, area:'Nearby east'},
  {id:'vp', kind:'fuel', nearby:true, name:'VP Racing Fuels', phone:'',
    address:'1300 NJ-27, North Brunswick, NJ 08902', lat:40.47024, lng:-74.49371, area:'Nearby south'},
  {id:'fuelwaymet', kind:'fuel', nearby:true, name:'Fuelway Metuchen', phone:'',
    address:'209 Central Ave, Metuchen, NJ 08840', lat:40.54486, lng:-74.37003, area:'Nearby east'}
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
  var color = fuel ? (item.allowed ? '#15803D' : '#475569') : (item.primary ? '#B45309' : '#1D4ED8');
  var html = fuel
    ? '<div class="rs-mk rs-mk-fuel" style="background:' + color + '" title="' + rsEsc(item.name) + '">⛽</div>'
    : '<div class="rs-mk rs-mk-road" style="background:' + color + '"></div>';
  return L.divIcon({
    className: 'rs-pin',
    html: html,
    iconSize: fuel ? [26, 26] : [14, 14],
    iconAnchor: fuel ? [13, 13] : [7, 7],
    popupAnchor: [0, -10]
  });
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
  if (item.allowed) pills += '<span class="rs-pill ok">Allowed fuel</span>';
  if (item.nearby) pills += '<span class="rs-pill">Nearby fuel</span>';
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
  rsMap.fitBounds(pts, { padding: [28, 28], maxZoom: 12 });
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

(function initMap() {
  rsMap = L.map('rsMap', { scrollWheelZoom: true }).setView([40.58, -74.52], 10);
  L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    maxZoom: 19,
    attribution: '&copy; OpenStreetMap'
  }).addTo(rsMap);
  rsAll().forEach(function(item) {
    if (!item.lat || !item.lng) return;
    var m = L.marker([item.lat, item.lng], { icon: rsIcon(item), title: item.name, zIndexOffset: item.kind === 'fuel' ? 200 : 0 });
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
