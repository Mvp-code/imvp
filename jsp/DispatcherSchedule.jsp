<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"
         import="java.util.*,com.util.*,com.beans.*" %>
<%
  String dsUser = request.getAttribute("loginUser") != null ? request.getAttribute("loginUser").toString() : (String) session.getAttribute("loginUser");
  String dsRoles = request.getAttribute("loginUserRoles") != null ? request.getAttribute("loginUserRoles").toString() : (String) session.getAttribute("loginUserRoles");
  String dsEntity = request.getAttribute("entityID") != null ? request.getAttribute("entityID").toString() : (session.getAttribute("entityID") != null ? session.getAttribute("entityID").toString() : "1");
  String dsName = request.getAttribute("loginUserDisplayName") != null ? request.getAttribute("loginUserDisplayName").toString() : (session.getAttribute("loginUserDisplayName") != null ? session.getAttribute("loginUserDisplayName").toString() : "");
  String dsUserID = request.getAttribute("loginUserID") != null ? request.getAttribute("loginUserID").toString() : (session.getAttribute("loginUserID") != null ? session.getAttribute("loginUserID").toString() : "");
  if (dsUser == null) dsUser = "";
  if (dsRoles == null) dsRoles = "";
  if (dsName == null || dsName.length() == 0) dsName = "Dispatcher";
  if (dsEntity == null || dsEntity.length() == 0) dsEntity = "1";
  request.setAttribute("loginUser", dsUser);
  request.setAttribute("loginUserRoles", dsRoles);
  request.setAttribute("entityID", dsEntity);
  request.setAttribute("loginUserDisplayName", dsName);
  request.setAttribute("loginUserID", dsUserID);
  request.setAttribute("shellNoForm", "yes");
  request.setAttribute("hideTopbarSearch", "yes");
%>
<jsp:useBean id="_recordBean" class="com.beans.SearchBean" scope="request" />
<%
  _recordBean.setController("DispatcherSchedule");
  _recordBean.setDisplayName("Dispatcher Schedule");
  int submitType = SubmitType.SEARCH;
%>
<!DOCTYPE html>
<html lang="en">
<%@ include file="includeHeader.jsp"%>
<script>function validatePageData(submitType, isValid) { return isValid; }</script>
<style>
.ds-page{max-width:1600px;margin:0 auto;color:#0f172a}
.ds-head{display:flex;gap:16px;align-items:flex-start;justify-content:space-between;flex-wrap:wrap;margin-bottom:12px}
.ds-head h1{margin:0;font-size:22px;font-weight:800;letter-spacing:-.025em}
.ds-sub{font-size:12px;color:#64748b;line-height:1.5;max-width:760px;margin-top:3px}
.ds-actions{display:flex;gap:7px;align-items:center;flex-wrap:wrap}
.ds-btn{min-height:38px;border:1px solid #cbd5e1;background:#fff;color:#0f172a;padding:7px 12px;border-radius:7px;font-size:12px;font-weight:750;cursor:pointer}
.ds-btn:hover{border-color:#0f172a}.ds-btn.primary{background:#0f172a;color:#fff;border-color:#0f172a}.ds-btn.danger{color:#b91c1c}
.ds-tabs{display:flex;gap:4px;border-bottom:1px solid #e2e8f0;margin-bottom:12px}
.ds-tab{border:0;background:transparent;color:#64748b;padding:9px 13px;border-bottom:3px solid transparent;font-size:12px;font-weight:800;cursor:pointer}
.ds-tab.on{color:#0f172a;border-bottom-color:#2563eb}
.ds-panel{display:none}.ds-panel.on{display:block}
.ds-card{background:#fff;border:1px solid #e2e8f0;border-radius:9px;padding:14px;margin-bottom:12px}
.ds-card h2{font-size:14px;margin:0 0 3px}.ds-help{font-size:11.5px;color:#64748b;line-height:1.45}
.ds-needs{display:grid;grid-template-columns:repeat(2,minmax(320px,1fr));gap:12px}
.ds-cycle{border-left:4px solid #2563eb}.ds-cycle.c1{border-left-color:#0f766e}
.ds-fields{display:grid;grid-template-columns:repeat(4,minmax(90px,1fr));gap:9px;margin-top:12px}
.ds-field label{display:block;font-size:10.5px;font-weight:800;color:#475569;text-transform:uppercase;letter-spacing:.035em;margin-bottom:4px}
.ds-field input,.ds-field select{width:100%;min-height:36px;border:1px solid #cbd5e1;border-radius:6px;padding:5px 7px;font-size:12px;background:#fff;box-sizing:border-box}
.ds-cov{display:grid;grid-template-columns:repeat(7,minmax(100px,1fr));gap:9px;margin-top:10px}
.ds-tablewrap{overflow:auto;border:1px solid #e2e8f0;border-radius:8px;background:#fff}
.ds-table{width:100%;border-collapse:separate;border-spacing:0;min-width:1080px}
.ds-table th{position:sticky;top:0;background:#f8fafc;color:#475569;font-size:10.5px;text-transform:uppercase;letter-spacing:.04em;text-align:left;padding:8px;border-bottom:1px solid #e2e8f0;z-index:2}
.ds-table td{padding:7px 8px;border-bottom:1px solid #eef2f7;border-right:1px solid #eef2f7;vertical-align:top;font-size:12px}
.ds-table tr:last-child td{border-bottom:0}.ds-person{font-weight:800;white-space:nowrap;border-left:5px solid var(--person-color,#64748b)}
.ds-person-dot{width:9px;height:9px;border-radius:50%;display:inline-block;background:var(--person-color,#64748b);margin-right:6px}
.ds-avcell{min-width:196px}.ds-avcell select{width:100%;border:0;background:transparent;font-size:10.5px;font-weight:750;color:#475569;margin-bottom:4px}
.ds-times{display:grid;grid-template-columns:minmax(82px,1fr) 10px minmax(82px,1fr);align-items:center;gap:4px}.ds-times input{width:100%;min-width:82px;box-sizing:border-box;border:1px solid #dbe3ee;border-radius:5px;padding:5px 4px;font-size:11px;color:#0f172a;background:#fff}
.ds-off{background:#f8fafc}.ds-backup{background:#fff7ed}
.ds-roster{display:flex;gap:7px;flex-wrap:wrap;margin-top:9px}.ds-name{display:flex;gap:6px;align-items:center;border:1px solid var(--person-color,#dbe3ee);border-left-width:5px;border-radius:999px;padding:5px 9px;background:#fff;font-size:11.5px;font-weight:750;color:var(--person-color,#0f172a)}
.ds-name button{border:0;background:transparent;color:#94a3b8;cursor:pointer;font-size:15px;line-height:1}
.ds-add{display:flex;gap:7px;margin-top:10px}.ds-add input{border:1px solid #cbd5e1;border-radius:6px;padding:7px 9px;min-width:220px}
.ds-summary{display:grid;grid-template-columns:repeat(4,minmax(120px,1fr));gap:9px;margin-bottom:12px}
.ds-kpi{background:#fff;border:1px solid #e2e8f0;border-radius:8px;padding:10px 12px}.ds-kpi b{font-size:22px;display:block}.ds-kpi span{font-size:10.5px;color:#64748b;text-transform:uppercase;font-weight:800}
.ds-kpi.bad b{color:#b91c1c}.ds-kpi.good b{color:#15803d}
.ds-sched td:first-child{position:sticky;left:0;background:#fff;z-index:1;font-weight:800;min-width:150px}
.ds-role{font-size:10px;color:#64748b;text-transform:uppercase;font-weight:800;margin-bottom:4px}
.ds-pill{display:inline-flex;background:color-mix(in srgb,var(--person-color,#2563eb) 10%,white);color:var(--person-color,#1d4ed8);border:1px solid color-mix(in srgb,var(--person-color,#2563eb) 35%,white);border-left-width:4px;border-radius:999px;padding:3px 7px;font-size:10.5px;font-weight:800;margin:2px 3px 2px 0}
.ds-pill.support{box-shadow:inset 0 -2px 0 rgba(15,23,42,.12)}.ds-pill.backup{border-style:dashed}
.ds-hours th:last-child,.ds-hours td:last-child{position:sticky;right:0;background:#f8fafc;font-weight:900;box-shadow:-2px 0 4px rgba(15,23,42,.06)}
.ds-shift{font-weight:800;white-space:nowrap}.ds-daily-hours{font-size:10.5px;color:#64748b;margin-top:3px}.ds-offtxt{color:#b91c1c;font-weight:900}.ds-total{font-size:17px;color:#0f172a}
.ds-gap{display:inline-flex;background:#fef2f2;color:#b91c1c;border:1px solid #fecaca;border-radius:5px;padding:3px 6px;font-size:10px;font-weight:800;margin-top:5px}
.ds-warn{margin-top:10px;background:#fff7ed;border:1px solid #fed7aa;border-radius:7px;padding:9px 11px;color:#9a3412;font-size:11.5px;line-height:1.5}
.ds-empty{text-align:center;color:#64748b;padding:36px 12px}
@media(max-width:900px){.ds-needs{grid-template-columns:1fr}.ds-fields{grid-template-columns:repeat(2,1fr)}.ds-cov{grid-template-columns:repeat(2,1fr)}.ds-summary{grid-template-columns:repeat(2,1fr)}}
@media print{.mvpx-sidebar,.mvpx-topbar,.ds-actions,.ds-tabs,#dsNeeds,#dsAvail{display:none!important}.mvpx-main{margin:0!important}.ds-panel{display:block!important}.ds-page{max-width:none}.ds-table{min-width:0}.ds-card{border:0;padding:0}.ds-pill{border:1px solid #999}}
</style>

<div class="ds-page">
  <div class="ds-head">
    <div>
      <h1>Dispatcher Schedule Optimizer</h1>
      <div class="ds-sub">Set Cycle 0 and Cycle 1 staffing needs, enter each dispatcher’s actual availability, then build a balanced weekly schedule. OFF is a hard block; Backup is used only when normal availability cannot cover the requirement.</div>
    </div>
    <div class="ds-actions">
      <label class="ds-field"><span style="display:block;font-size:10px;font-weight:800;color:#64748b">WEEK OF</span><input type="date" id="dsWeek" onchange="dsSave()"></label>
      <button type="button" class="ds-btn" onclick="dsRestoreExample()">Load example</button>
      <button type="button" class="ds-btn" onclick="window.print()">Print</button>
      <button type="button" class="ds-btn primary" onclick="dsBuild()">Build schedule</button>
    </div>
  </div>

  <div class="ds-tabs">
    <button type="button" class="ds-tab on" data-tab="needs" onclick="dsTab('needs')">1. Staffing needs</button>
    <button type="button" class="ds-tab" data-tab="avail" onclick="dsTab('avail')">2. Availability</button>
    <button type="button" class="ds-tab" data-tab="schedule" onclick="dsTab('schedule')">3. Optimized schedule</button>
  </div>

  <section class="ds-panel on" id="dsNeeds">
    <div class="ds-needs">
      <div class="ds-card ds-cycle">
        <h2>Cycle 0</h2><div class="ds-help">Default operating window: 7:00 AM–6:00 PM.</div>
        <div class="ds-fields">
          <div class="ds-field"><label>Start</label><input type="time" id="c0Start" value="07:00" onchange="dsSave()"></div>
          <div class="ds-field"><label>End</label><input type="time" id="c0End" value="18:00" onchange="dsSave()"></div>
          <div class="ds-field"><label>Openers needed</label><input type="number" id="c0Open" min="0" max="6" value="1" onchange="dsSave()"></div>
          <div class="ds-field"><label>Closers needed</label><input type="number" id="c0Close" min="0" max="6" value="2" onchange="dsSave()"></div>
          <div class="ds-field"><label>Closing backups</label><input type="number" id="c0CloseBackup" min="0" max="6" value="1" onchange="dsSave()"></div>
        </div>
      </div>
      <div class="ds-card ds-cycle c1">
        <h2>Cycle 1</h2><div class="ds-help">Default operating window: 11:00 AM–10:00 PM.</div>
        <div class="ds-fields">
          <div class="ds-field"><label>Start</label><input type="time" id="c1Start" value="11:00" onchange="dsSave()"></div>
          <div class="ds-field"><label>End</label><input type="time" id="c1End" value="22:00" onchange="dsSave()"></div>
          <div class="ds-field"><label>Openers needed</label><input type="number" id="c1Open" min="0" max="6" value="2" onchange="dsSave()"></div>
          <div class="ds-field"><label>Closers needed</label><input type="number" id="c1Close" min="0" max="6" value="2" onchange="dsSave()"></div>
        </div>
      </div>
    </div>
    <div class="ds-card">
      <h2>Shared coverage</h2>
      <div class="ds-help">The optimizer checks every 30 minutes. Extra evening hands are added above the minimum coverage when available.</div>
      <div class="ds-cov">
        <div class="ds-field"><label>Minimum from</label><input type="time" id="covStart" value="10:00" onchange="dsSave()"></div>
        <div class="ds-field"><label>Minimum until</label><input type="time" id="covEnd" value="22:00" onchange="dsSave()"></div>
        <div class="ds-field"><label>Minimum people</label><input type="number" id="covCount" min="1" max="10" value="2" onchange="dsSave()"></div>
        <div class="ds-field"><label>Extra from</label><input type="time" id="extraStart" value="18:00" onchange="dsSave()"></div>
        <div class="ds-field"><label>Extra until</label><input type="time" id="extraEnd" value="22:00" onchange="dsSave()"></div>
        <div class="ds-field"><label>Extra hands</label><select id="extraCount" onchange="dsSave()"><option value="1">1 extra</option><option value="2">2 extra</option></select></div>
        <div class="ds-field"><label>Max days/person</label><input type="number" id="maxDays" min="1" max="7" value="6" onchange="dsSave()"></div>
      </div>
    </div>
  </section>

  <section class="ds-panel" id="dsAvail">
    <div class="ds-card">
      <h2>Dispatcher roster</h2>
      <div class="ds-help">Add or remove dispatchers before entering availability.</div>
      <div class="ds-roster" id="dsRoster"></div>
      <div class="ds-add"><input id="dsNewName" placeholder="Dispatcher name" onkeydown="if(event.key==='Enter')dsAddPerson()"><button type="button" class="ds-btn primary" onclick="dsAddPerson()">Add dispatcher</button></div>
    </div>
    <div class="ds-tablewrap"><table class="ds-table"><thead id="dsAvailHead"></thead><tbody id="dsAvailBody"></tbody></table></div>
    <div class="ds-help" style="margin-top:8px">Blank/unknown cells from the manual sheet are treated as OFF until confirmed. “Backup” remains eligible but receives a scheduling penalty.</div>
  </section>

  <section class="ds-panel" id="dsSchedule">
    <div class="ds-summary" id="dsSummary"></div>
    <div class="ds-card">
      <h2>Weekly role assignment</h2>
      <div class="ds-help">Assignments are responsibilities at cycle open/close plus support coverage; they are not payroll punches.</div>
      <div class="ds-tablewrap" style="margin-top:10px"><table class="ds-table ds-sched"><thead id="dsSchedHead"></thead><tbody id="dsSchedBody"></tbody></table></div>
      <div id="dsWarnings"></div>
    </div>
    <div class="ds-card">
      <h2>Individual dispatcher shifts &amp; hours</h2>
      <div class="ds-help">Each dispatcher can see working days, shift times, daily paid hours, and the weekly total. OFF days count as zero.</div>
      <div class="ds-tablewrap" style="margin-top:10px"><table class="ds-table ds-hours"><thead id="dsHoursHead"></thead><tbody id="dsHoursBody"></tbody></table></div>
    </div>
  </section>
</div>

<script>
var DS_DAYS = ['Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday'];
var DS_KEY = 'mvpx_dispatcher_schedule_v1';
var DS_ALGO = 3;
var dsState = null;

function dsSlot(status,start,end){ return {status:status,start:start||'',end:end||''}; }
function dsColor(name){
  var palette=['#2563eb','#7c3aed','#db2777','#ea580c','#0891b2','#16a34a','#ca8a04','#dc2626','#4f46e5','#0f766e'];
  var index=dsState&&dsState.people?dsState.people.indexOf(name):-1;
  if(index<0){index=0;for(var i=0;i<String(name).length;i++)index+=String(name).charCodeAt(i)}
  return palette[index%palette.length];
}
function dsDefaultAvailability(){
  return {
    Jair:[dsSlot('off'),dsSlot('off'),dsSlot('available','07:00','15:00'),dsSlot('available','07:00','15:00'),dsSlot('available','07:00','15:00'),dsSlot('available','07:00','15:00'),dsSlot('available','07:00','15:00')],
    Steph:[dsSlot('available','14:00','22:00'),dsSlot('available','14:00','22:00'),dsSlot('available','14:00','22:00'),dsSlot('available','14:00','22:00'),dsSlot('available','10:00','19:00'),dsSlot('available','14:00','22:00'),dsSlot('off')],
    Saida:[dsSlot('available','07:00','19:00'),dsSlot('available','07:00','15:00'),dsSlot('available','15:00','22:00'),dsSlot('available','15:00','22:00'),dsSlot('available','15:00','22:00'),dsSlot('available','15:00','22:00'),dsSlot('available','15:00','22:00')],
    Eripson:[dsSlot('backup','14:00','22:00'),dsSlot('available','10:00','18:00'),dsSlot('available','10:00','14:00'),dsSlot('available','10:00','14:00'),dsSlot('off'),dsSlot('available','10:00','14:00'),dsSlot('available','10:00','14:00')],
    Cristobal:[dsSlot('off'),dsSlot('available','18:00','22:00'),dsSlot('available','18:00','22:00'),dsSlot('available','18:00','22:00'),dsSlot('available','18:00','22:00'),dsSlot('off'),dsSlot('off')],
    Singh:[dsSlot('available','10:00','22:00'),dsSlot('available','18:00','22:00'),dsSlot('available','18:00','22:00'),dsSlot('available','18:00','22:00'),dsSlot('off'),dsSlot('available','18:00','22:00'),dsSlot('available','18:00','22:00')],
    Juan:[dsSlot('off'),dsSlot('off'),dsSlot('off'),dsSlot('off'),dsSlot('off'),dsSlot('off'),dsSlot('available','18:00','22:00')]
  };
}
function dsDefaults(){
  return {people:['Jair','Steph','Saida','Eripson','Cristobal','Singh','Juan'],availability:dsDefaultAvailability(),assignments:null};
}
function dsMinutes(t){ if(!t)return null;var p=t.split(':');return (+p[0])*60+(+p[1]); }
function dsVal(id){var e=document.getElementById(id);return e?e.value:''}
function dsNum(id){return Math.max(0,parseInt(dsVal(id),10)||0)}
function dsEsc(s){return String(s||'').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;')}
function dsMonday(){
  var d=new Date(),day=d.getDay(),delta=(day===0?-6:1-day);d.setDate(d.getDate()+delta);
  return d.getFullYear()+'-'+String(d.getMonth()+1).padStart(2,'0')+'-'+String(d.getDate()).padStart(2,'0');
}
function dsLoad(){
  var raw=null;try{raw=JSON.parse(localStorage.getItem(DS_KEY)||'null')}catch(e){}
  dsState=raw&&raw.people&&raw.availability?raw:dsDefaults();
  if(dsState.algorithmVersion!==DS_ALGO){dsState.algorithmVersion=DS_ALGO;dsState.assignments=null}
  var req=dsState.requirements||{};
  ['c0Start','c0End','c0Open','c0Close','c0CloseBackup','c1Start','c1End','c1Open','c1Close','covStart','covEnd','covCount','extraStart','extraEnd','extraCount','maxDays'].forEach(function(id){
    if(req[id]!=null&&document.getElementById(id))document.getElementById(id).value=req[id];
  });
  document.getElementById('dsWeek').value=dsState.week||dsMonday();
  dsRenderAvailability();
  if(dsState.assignments)dsRenderSchedule(dsState.assignments);else dsEmptySchedule();
}
function dsSave(){
  dsState.week=dsVal('dsWeek');dsState.requirements={};
  ['c0Start','c0End','c0Open','c0Close','c0CloseBackup','c1Start','c1End','c1Open','c1Close','covStart','covEnd','covCount','extraStart','extraEnd','extraCount','maxDays'].forEach(function(id){dsState.requirements[id]=dsVal(id)});
  try{localStorage.setItem(DS_KEY,JSON.stringify(dsState))}catch(e){}
}
function dsRestoreExample(){if(!confirm('Replace current availability with the supplied example?'))return;dsState=dsDefaults();document.getElementById('dsWeek').value=dsMonday();dsRenderAvailability();dsSave();dsTab('avail')}
function dsTab(tab){
  document.querySelectorAll('.ds-tab').forEach(function(b){b.classList.toggle('on',b.dataset.tab===tab)});
  document.querySelectorAll('.ds-panel').forEach(function(p){p.classList.remove('on')});
  document.getElementById(tab==='needs'?'dsNeeds':tab==='avail'?'dsAvail':'dsSchedule').classList.add('on');
}
function dsRenderAvailability(){
  document.getElementById('dsRoster').innerHTML=dsState.people.map(function(n){return '<span class="ds-name" style="--person-color:'+dsColor(n)+'">'+dsEsc(n)+'<button type="button" title="Remove" onclick="dsRemovePerson(\''+dsEsc(n).replace(/'/g,"\\'")+'\')">&times;</button></span>'}).join('');
  document.getElementById('dsAvailHead').innerHTML='<tr><th>Dispatcher</th>'+DS_DAYS.map(function(d){return '<th>'+d+'</th>'}).join('')+'</tr>';
  var html='';
  dsState.people.forEach(function(name){
    if(!dsState.availability[name])dsState.availability[name]=DS_DAYS.map(function(){return dsSlot('off')});
    html+='<tr style="--person-color:'+dsColor(name)+'"><td class="ds-person"><span class="ds-person-dot"></span>'+dsEsc(name)+'</td>';
    dsState.availability[name].forEach(function(a,di){
      html+='<td class="ds-avcell '+(a.status==='off'?'ds-off':a.status==='backup'?'ds-backup':'')+'"><select onchange="dsAvailChange(\''+dsEsc(name).replace(/'/g,"\\'")+'\','+di+',\'status\',this.value)">'
        +'<option value="available"'+(a.status==='available'?' selected':'')+'>Available</option><option value="backup"'+(a.status==='backup'?' selected':'')+'>Backup</option><option value="off"'+(a.status==='off'?' selected':'')+'>OFF</option></select>'
        +'<div class="ds-times"><input type="time" value="'+dsEsc(a.start)+'" '+(a.status==='off'?'disabled':'')+' onchange="dsAvailChange(\''+dsEsc(name).replace(/'/g,"\\'")+'\','+di+',\'start\',this.value)"><span>–</span><input type="time" value="'+dsEsc(a.end)+'" '+(a.status==='off'?'disabled':'')+' onchange="dsAvailChange(\''+dsEsc(name).replace(/'/g,"\\'")+'\','+di+',\'end\',this.value)"></div></td>';
    });
    html+='</tr>';
  });
  document.getElementById('dsAvailBody').innerHTML=html;
}
function dsAvailChange(name,day,key,val){
  var a=dsState.availability[name][day];a[key]=val;
  if(key==='status'&&val==='off'){a.start='';a.end=''}
  if(key==='status'&&val!=='off'&&!a.start){a.start='09:00';a.end='17:00'}
  dsState.assignments=null;dsRenderAvailability();dsSave();
}
function dsAddPerson(){
  var i=document.getElementById('dsNewName'),n=i.value.trim();if(!n)return;
  if(dsState.people.some(function(x){return x.toLowerCase()===n.toLowerCase()})){alert('Dispatcher already exists');return}
  dsState.people.push(n);dsState.availability[n]=DS_DAYS.map(function(){return dsSlot('off')});i.value='';dsRenderAvailability();dsSave();
}
function dsRemovePerson(name){
  if(!confirm('Remove '+name+' from this planner?'))return;
  dsState.people=dsState.people.filter(function(x){return x!==name});delete dsState.availability[name];dsState.assignments=null;dsRenderAvailability();dsSave();
}
function dsAvailable(name,day,minute){
  var a=dsState.availability[name][day];if(!a||a.status==='off')return false;
  var s=dsMinutes(a.start),e=dsMinutes(a.end);return s!=null&&e!=null&&minute>=s&&minute<=e;
}
function dsCandidate(name,day,anchor,role,loads,chosen){
  var a=dsState.availability[name][day];if(!a||a.status==='off'||!dsAvailable(name,day,anchor))return null;
  if((role==='support'||role==='c0backup')&&chosen.indexOf(name)>=0)return null;
  var pref={c0open:['Jair','Saida'],c0close:['Saida','Steph','Eripson'],c0backup:['Eripson','Singh','Cristobal','Steph','Saida'],c1open:['Eripson','Jair','Saida','Steph','Cristobal'],c1close:['Steph','Saida','Singh','Cristobal','Eripson'],support:['Singh','Cristobal','Juan','Eripson','Saida']}[role]||[];
  var pi=pref.indexOf(name),score=(a.status==='backup'?100:0)+(loads[name]||0)*9+(chosen.indexOf(name)>=0?6:0)+(pi<0?25:pi*2);
  return {name:name,score:score,status:a.status};
}
function dsPick(day,anchor,count,role,loads,chosen){
  var candidates=dsState.people.map(function(n){return dsCandidate(n,day,anchor,role,loads,chosen)}).filter(Boolean).sort(function(a,b){return a.score-b.score||a.name.localeCompare(b.name)});
  var out=[];for(var i=0;i<candidates.length&&out.length<count;i++){if(out.indexOf(candidates[i].name)<0)out.push(candidates[i].name)}
  out.forEach(function(n){loads[n]=(loads[n]||0)+1;if(chosen.indexOf(n)<0)chosen.push(n)});return out;
}
function dsBuild(){
  dsSave();
  var maxDays=dsNum('maxDays'),loads={},daysUsed={},result={days:[],warnings:[],loads:{}};
  dsState.people.forEach(function(n){loads[n]=0;daysUsed[n]={}});
  for(var d=0;d<7;d++){
    var chosen=[],roles={};
    roles.c0open=dsPick(d,dsMinutes(dsVal('c0Start')),dsNum('c0Open'),'c0open',loads,chosen);
    roles.c0close=dsPick(d,dsMinutes(dsVal('c0End')),dsNum('c0Close'),'c0close',loads,chosen);
    roles.c0backup=dsPick(d,dsMinutes(dsVal('c0End')),dsNum('c0CloseBackup'),'c0backup',loads,chosen);
    roles.c1open=dsPick(d,dsMinutes(dsVal('c1Start')),dsNum('c1Open'),'c1open',loads,chosen);
    roles.c1close=dsPick(d,dsMinutes(dsVal('c1End')),dsNum('c1Close'),'c1close',loads,chosen);
    var support=[],gaps=[],covStart=dsMinutes(dsVal('covStart')),covEnd=dsMinutes(dsVal('covEnd')),extraStart=dsMinutes(dsVal('extraStart')),extraEnd=dsMinutes(dsVal('extraEnd'));
    for(var m=covStart;m<=covEnd;m+=30){
      var target=dsNum('covCount')+((m>=extraStart&&m<=extraEnd)?dsNum('extraCount'):0);
      var covered=chosen.filter(function(n){return dsAvailable(n,d,m)}).length;
      while(covered<target){
        var add=dsState.people.map(function(n){return dsCandidate(n,d,m,'support',loads,chosen)}).filter(Boolean).sort(function(a,b){return a.score-b.score||a.name.localeCompare(b.name)})[0];
        if(!add)break;support.push(add.name);chosen.push(add.name);loads[add.name]=(loads[add.name]||0)+1;
        covered=chosen.filter(function(n){return dsAvailable(n,d,m)}).length;
      }
      if(covered<target)gaps.push(dsFmt(m)+' needs '+target+', has '+covered);
    }
    roles.support=support.filter(function(n,i,a){return a.indexOf(n)===i});
    chosen.forEach(function(n){daysUsed[n][d]=true});
    [['Cycle 0 open','c0open',dsNum('c0Open')],['Cycle 0 close','c0close',dsNum('c0Close')],['Cycle 0 closing backup','c0backup',dsNum('c0CloseBackup')],['Cycle 1 open','c1open',dsNum('c1Open')],['Cycle 1 close','c1close',dsNum('c1Close')]].forEach(function(x){if(roles[x[1]].length<x[2])result.warnings.push(DS_DAYS[d]+': '+x[0]+' needs '+x[2]+', assigned '+roles[x[1]].length)});
    result.days.push({roles:roles,gaps:gaps,chosen:chosen});
  }
  Object.keys(daysUsed).forEach(function(n){if(Object.keys(daysUsed[n]).length>maxDays)result.warnings.push(n+' exceeds '+maxDays+' days')});
  result.loads=loads;dsState.assignments=result;dsSave();dsRenderSchedule(result);dsTab('schedule');
}
function dsFmt(min){var h=Math.floor(min/60),m=min%60,ap=h>=12?'PM':'AM',hh=h%12||12;return hh+':'+String(m).padStart(2,'0')+' '+ap}
function dsPills(arr,cls){return arr.length?arr.map(function(n){return '<span class="ds-pill '+(cls||'')+'" style="--person-color:'+dsColor(n)+'">'+dsEsc(n)+'</span>'}).join(''):'<span class="ds-gap">Unfilled</span>'}
function dsShiftHours(a){
  if(!a||a.status==='off')return 0;
  var start=dsMinutes(a.start),end=dsMinutes(a.end);
  if(start==null||end==null)return 0;
  if(end<start)end+=1440;
  return Math.max(0,(end-start)/60);
}
function dsHourLabel(hours){return (Math.round(hours*100)/100).toString().replace(/\.0+$/,'')+' hr'}
function dsRenderHours(){
  var head='<tr><th>Dispatcher</th>'+DS_DAYS.map(function(d){return '<th>'+d+'</th>'}).join('')+'<th>Total shift hr</th></tr>';
  var body=dsState.people.map(function(name){
    var total=0,cells=dsState.availability[name].map(function(a){
      var hours=dsShiftHours(a);total+=hours;
      if(a.status==='off'||!a.start||!a.end)return '<td><span class="ds-offtxt">OFF</span><div class="ds-daily-hours">0 hr</div></td>';
      return '<td><div class="ds-shift">'+dsFmt(dsMinutes(a.start))+'–'+dsFmt(dsMinutes(a.end))+'</div><div class="ds-daily-hours">'+dsHourLabel(hours)+(a.status==='backup'?' · Backup':'')+'</div></td>';
    }).join('');
    return '<tr style="--person-color:'+dsColor(name)+'"><td class="ds-person"><span class="ds-person-dot"></span>'+dsEsc(name)+'</td>'+cells+'<td><span class="ds-total">'+dsHourLabel(total)+'</span></td></tr>';
  }).join('');
  document.getElementById('dsHoursHead').innerHTML=head;
  document.getElementById('dsHoursBody').innerHTML=body;
}
function dsRenderSchedule(result){
  document.getElementById('dsSchedHead').innerHTML='<tr><th>Assignment</th>'+DS_DAYS.map(function(d){return '<th>'+d+'</th>'}).join('')+'</tr>';
  var rows=[['Cycle 0 Open','c0open'],['Cycle 0 Close','c0close'],['Cycle 0 Closing Backup','c0backup'],['Cycle 1 Open','c1open'],['Cycle 1 Close','c1close'],['Evening / Coverage','support']];
  document.getElementById('dsSchedBody').innerHTML=rows.map(function(r){return '<tr><td><div class="ds-role">'+r[0]+'</div></td>'+result.days.map(function(day){return '<td>'+dsPills(day.roles[r[1]],r[1]==='support'?'support':r[1]==='c0backup'?'backup':'')+'</td>'}).join('')+'</tr>'}).join('');
  var gapCount=result.days.reduce(function(n,d){return n+d.gaps.length},0),assigned=Object.keys(result.loads).filter(function(n){return result.loads[n]>0}).length,total=Object.keys(result.loads).reduce(function(n,k){return n+result.loads[k]},0);
  document.getElementById('dsSummary').innerHTML='<div class="ds-kpi '+(gapCount?'bad':'good')+'"><b>'+gapCount+'</b><span>Coverage gaps</span></div><div class="ds-kpi"><b>'+assigned+'</b><span>Dispatchers used</span></div><div class="ds-kpi"><b>'+total+'</b><span>Role assignments</span></div><div class="ds-kpi"><b>'+dsNum('extraCount')+'</b><span>Evening extra target</span></div>';
  var warnings=result.warnings.slice();result.days.forEach(function(day,i){if(day.gaps.length)warnings.push(DS_DAYS[i]+': '+day.gaps.slice(0,4).join('; ')+(day.gaps.length>4?'…':''))});
  document.getElementById('dsWarnings').innerHTML=warnings.length?'<div class="ds-warn"><b>Needs attention</b><br>'+warnings.map(dsEsc).join('<br>')+'</div>':'<div class="ds-warn" style="background:#ecfdf5;border-color:#bbf7d0;color:#166534"><b>Coverage validated.</b> All configured requirements are covered by confirmed availability.</div>';
  dsRenderHours();
}
function dsEmptySchedule(){
  document.getElementById('dsSummary').innerHTML='';
  document.getElementById('dsSchedHead').innerHTML='';
  document.getElementById('dsSchedBody').innerHTML='<tr><td class="ds-empty">Complete staffing needs and availability, then select Build schedule.</td></tr>';
  document.getElementById('dsWarnings').innerHTML='';
  dsRenderHours();
}
dsLoad();
</script>
<%@ include file="includeFooter.jsp"%>
