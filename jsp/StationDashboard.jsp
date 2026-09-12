<!DOCTYPE html>
<%@ page import="java.util.*, com.util.*, com.beans.*"%>
<jsp:useBean id="_errorBean" class="com.beans.ErrorBean" scope="request" />
<%
int submitType = request.getAttribute("submitType") == null ? SubmitType.SEARCH : Integer.parseInt(request.getAttribute("submitType").toString().trim());

SearchBean _searchBean = new SearchBean();
Object _rawBeanObj = request.getAttribute("_recordBean");
if (_rawBeanObj instanceof SearchBean) {
    _searchBean = (SearchBean) _rawBeanObj;
    request.removeAttribute("_recordBean");
}
String _bootstrapJson = "{\"empty\":true}";
if (_searchBean.getTransMap() != null && _searchBean.getTransMap().get("bootstrapJson") != null)
    _bootstrapJson = _searchBean.getTransMap().get("bootstrapJson").toString();
%>
<jsp:useBean id="_recordBean" class="com.beans.StationDashboard" scope="request" />
<%@ include file="includeHeader.jsp"%>
<style>
/* ═══ Station Dashboard (REV C ledger) \u2014 scoped sd- ═══ */
.sd-hd{display:flex;align-items:center;gap:12px;flex-wrap:wrap;margin-bottom:12px}
.sd-hd h2{font-family:var(--font-disp);font-weight:800;font-size:21px;letter-spacing:-.02em;color:var(--text);line-height:1}
.sd-tabs{display:inline-flex;background:#F8F7F2;border:1px solid var(--border);border-radius:11px;padding:2px;margin-left:auto}
.sd-tabs button{border:none;background:transparent;border-radius:9px;padding:6.5px 14px;font-size:12.5px;font-weight:600;color:var(--text-light);cursor:pointer;transition:all .13s;font-family:var(--font)}
.sd-tabs button.on{background:var(--text);color:#F4F3EE}
.sd-view{display:none;animation:sdrise .35s cubic-bezier(.2,.7,.2,1)}
.sd-view.on{display:block}
@keyframes sdrise{from{opacity:0;transform:translateY(8px)}to{opacity:1;transform:none}}
.sd-grid{display:grid;gap:11px}
.sd-kpi6{grid-template-columns:repeat(6,1fr)}
#sdKpis{grid-template-columns:repeat(7,1fr)}
@media (max-width:1100px){#sdKpis{grid-template-columns:repeat(4,1fr)}}
@media (max-width:760px){#sdKpis{grid-template-columns:repeat(2,1fr)}}
.sd-2{grid-template-columns:1.25fr .75fr}
.sd-3{grid-template-columns:repeat(3,1fr)}
.sd-4{grid-template-columns:repeat(4,1fr)}
/* league coach toggle */
.sd-cotgl{width:34px;height:19px;border-radius:10px;border:1px solid var(--border,#D8D6CE);background:#E5E3DB;position:relative;cursor:pointer;padding:0;vertical-align:middle;transition:background .15s}
.sd-cotgl .kn{position:absolute;top:2px;left:2px;width:13px;height:13px;border-radius:50%;background:#fff;box-shadow:0 1px 2px rgba(0,0,0,.25);transition:left .15s}
.sd-cotgl.on{background:var(--status-ok-solid);border-color:var(--status-ok-solid)}
.sd-cotgl.on .kn{left:17px}
.sd-cotgl:disabled{opacity:.5}
/* coaching log entries */
.sd-clog{border:1px solid var(--border);border-radius:9px;padding:8px 10px;margin-bottom:7px;font-size:12.5px}
.sd-clcat{font-family:var(--font-mono);font-size:8.5px;letter-spacing:.08em;padding:2px 7px;border-radius:8px;background:#EEEDE8;color:#6B6E76}
.sd-clcat.cSafety{background:var(--status-action-bg);color:var(--status-action-fg)}
.sd-clcat.cQuality{background:var(--status-info-bg);color:var(--status-info-fg)}
.sd-sq{display:flex;align-items:center;justify-content:space-between;gap:8px;padding:5px 0;border-bottom:1px solid var(--border,#E8E6DF)}
.sd-sq:last-child{border-bottom:0}
.sd-sq .q{font-size:11px;line-height:1.3;color:var(--text-light,#6B6E76);overflow:hidden;display:-webkit-box;-webkit-line-clamp:2;-webkit-box-orient:vertical}
.sd-sq .p{font-family:var(--font-mono);font-size:13px;font-weight:600;white-space:nowrap}
.sd-sq .t{font-family:var(--font-mono);font-size:10px;color:#A6A9B1;white-space:nowrap}
.sd-half{grid-template-columns:1fr 1fr}
.sd-mt{margin-top:11px}
.sd-card{background:#fff;border:1px solid var(--border);border-radius:14px;box-shadow:0 1px 2px rgba(20,21,25,.05);padding:14px 16px;min-width:0}
.sd-card h3{font-family:var(--font-mono);font-size:9.5px;letter-spacing:.15em;text-transform:uppercase;color:var(--text-light);font-weight:500;margin-bottom:11px;display:flex;align-items:center;gap:8px}
.sd-card h3 .src{margin-left:auto;color:#A6A9B1;letter-spacing:.05em;font-size:8.5px;text-transform:none}
.sd-wksel{font-family:var(--font-mono);font-size:10px;color:var(--text);border:1px solid var(--border);border-radius:7px;padding:2.5px 6px;background:#fff;cursor:pointer}
.sd-kpi .lbl{font-family:var(--font-mono);font-size:9px;letter-spacing:.14em;text-transform:uppercase;color:var(--text-light)}
.sd-kpi .num{font-family:var(--font-disp);font-weight:800;font-size:27px;letter-spacing:-.02em;color:var(--text);line-height:1.1;margin:4px 0 2px}
.sd-kpi .sub{font-size:11px;color:var(--text-light)}
.sd-kpi .sub b{color:var(--text)}
.sd-pill{display:inline-flex;align-items:center;gap:5px;border-radius:999px;padding:2.5px 10px;font-size:11px;font-weight:700}
.sd-pill .d{width:6px;height:6px;border-radius:50%}
.sd-pill.plat{background:var(--status-info-bg);color:var(--status-info-fg)}.sd-pill.plat .d{background:var(--status-info-fg)}
.sd-pill.fan{background:var(--status-ok-bg);color:var(--status-ok-fg)}.sd-pill.fan .d{background:var(--status-ok-fg)}
.sd-pill.great{background:#F8F7F2;color:#7A7E88;border:1px solid var(--border)}.sd-pill.great .d{background:#A6A9B1}
.sd-pill.fair{background:var(--status-warn-bg);color:var(--status-warn-fg)}.sd-pill.fair .d{background:var(--status-warn-fg)}
.sd-pill.poor{background:var(--status-action-bg);color:var(--status-action-fg)}.sd-pill.poor .d{background:var(--status-action-fg)}
.sd-qgrid{display:grid;grid-template-columns:repeat(8,1fr);gap:8px}
.sd-qt{background:#F8F7F2;border:1px solid #ECEAE1;border-radius:10px;padding:8px 10px;min-width:0}
.sd-qt .l{font-family:var(--font-mono);font-size:8.5px;letter-spacing:.1em;color:var(--text-light);text-transform:uppercase;white-space:nowrap}
.sd-qt .v{font-family:var(--font-disp);font-weight:800;font-size:18px;color:var(--text);margin-top:2px}
.sd-qt .s{font-family:var(--font-mono);font-size:9px;color:#A6A9B1;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.sd-cat{font-family:var(--font-mono);font-size:9px;letter-spacing:.1em;padding:2.5px 8px;border-radius:999px;border:1px solid var(--border);background:#F8F7F2;color:var(--text-muted);flex-shrink:0;font-weight:600;white-space:nowrap}
.sd-cat.saf{border-color:var(--text);color:var(--text)}
.sd-vs{display:flex;align-items:baseline;gap:8px}
.sd-vs .v{font-family:var(--font-disp);font-weight:800;font-size:22px;color:var(--text)}
.sd-vs .f{font-family:var(--font-mono);font-size:9.5px;color:#A6A9B1}
.sd-ev{display:flex;gap:10px;align-items:center;padding:7px 0;border-bottom:1px solid #ECEAE1;font-size:12.5px}
.sd-ev:last-child{border-bottom:none}
.sd-ev .d8{font-family:var(--font-mono);font-size:11px;color:var(--text-light);width:44px;flex-shrink:0}
.sd-ev .ty{font-weight:600;color:var(--text);width:150px;flex-shrink:0;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.sd-ev .meta{color:var(--text-light);flex:1;min-width:0;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.sd-ev a{font-family:var(--font-mono);font-size:10px;color:var(--text)}
svg.sdchart text{font-family:var(--font-mono);font-size:9.5px;fill:var(--text-light)}
svg.sdchart .lbl-ink{fill:var(--text);font-weight:600}
svg.sdchart .grid-l{stroke:#ECEAE1;stroke-width:1}
.sd-legend{display:flex;gap:14px;font-size:11px;color:var(--text-light);margin-top:7px;flex-wrap:wrap}
.sd-legend .sw{display:inline-block;width:14px;height:0;border-top:2px solid var(--text);vertical-align:middle;margin-right:5px}
.sd-legend .sw.dash{border-top-style:dashed;border-color:#A6A9B1}
.sd-legend .sw.bar{height:9px;background:var(--text);border-radius:2px;border:none}
.sd-legend .sw.bar.gr{background:#7A7E88}
.sd-tip{position:fixed;background:var(--text);color:#F4F3EE;font-family:var(--font-mono);font-size:10.5px;border-radius:8px;padding:6px 10px;pointer-events:none;opacity:0;transition:opacity .1s;z-index:999;white-space:nowrap}
.sd-lg{width:100%;border-collapse:collapse}
.sd-lg th{font-family:var(--font-mono);font-size:9px;letter-spacing:.12em;text-transform:uppercase;color:var(--text-light);font-weight:500;text-align:left;padding:8px 10px;background:#F8F7F2;border-bottom:1px solid var(--border);white-space:nowrap}
.sd-lg td{padding:6.5px 10px;border-bottom:1px solid #ECEAE1;font-size:12.5px;white-space:nowrap}
.sd-lg tr:hover td{background:#F8F7F2;cursor:pointer}
.sd-lg .rk{font-family:var(--font-mono);font-size:11px;color:#A6A9B1}
.sd-lg .nm{font-weight:600;color:var(--text);max-width:230px;overflow:hidden;text-overflow:ellipsis}
.sd-lg .num{font-family:var(--font-mono);font-size:11.5px;color:var(--text)}
.sd-lg .dim{font-family:var(--font-mono);font-size:11.5px;color:var(--text-light)}
.sd-scorebar{display:inline-flex;align-items:center;gap:7px}
.sd-scorebar .tr{width:72px;height:8px;background:#ECEAE1;border-radius:4px;overflow:hidden}
.sd-scorebar .fl{height:100%;background:var(--text);border-radius:4px}
.sd-foot{display:flex;align-items:center;gap:10px;padding:8px 12px;border-top:1px solid var(--border);font-family:var(--font-mono);font-size:10px;color:var(--text-light)}
.sd-foot .pg{margin-left:auto;display:flex;align-items:center;gap:8px}
.sd-pgbtn{border:1px solid var(--border);background:#fff;border-radius:7px;width:26px;height:23px;cursor:pointer;color:var(--text);display:inline-flex;align-items:center;justify-content:center}
.sd-pgbtn:hover:not(:disabled){background:var(--text);color:#fff}
.sd-pgbtn:disabled{opacity:.3}
.sd-coach{display:flex;align-items:center;gap:12px;padding:9px 0;border-bottom:1px solid #ECEAE1}
.sd-coach:last-child{border-bottom:none}
.sd-coach .who{width:210px;flex-shrink:0}
.sd-coach .who .n{font-weight:600;color:var(--text);font-size:13px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.sd-coach .who .t{font-family:var(--font-mono);font-size:9.5px;color:#A6A9B1}
.sd-coach .why{flex:1;font-size:12px;color:var(--text-muted);min-width:0}
.sd-fstat{font-family:var(--font-mono);font-size:9.5px;letter-spacing:.06em;padding:3px 9px;border-radius:999px;white-space:nowrap}
.sd-fstat.open{background:var(--status-warn-bg);color:var(--status-warn-fg)}
.sd-fstat.done{background:var(--status-ok-bg);color:var(--status-ok-fg)}
.sd-dasel{border:1px solid var(--border);border-radius:11px;padding:8px 12px;font-size:14.5px;font-weight:600;font-family:var(--font);color:var(--text);background:#fff;min-width:280px}
.sd-dasel:focus{outline:none;border-color:var(--text)}
/* per-metric tier grid (Amazon "Performance" style) */
.sd-tg{display:grid;grid-template-columns:repeat(3,1fr);gap:8px}
.sd-tg .m{background:#F8F7F2;border:1px solid #ECEAE1;border-radius:10px;padding:9px 11px;min-width:0}
.sd-tg .m .n{font-family:var(--font-mono);font-size:8.5px;letter-spacing:.08em;color:var(--text-light);text-transform:uppercase;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.sd-tg .m .v{font-family:var(--font-disp);font-weight:800;font-size:19px;color:var(--text);margin:3px 0 4px}
.sd-daysrow td{padding:6px 10px;border-bottom:1px solid #ECEAE1;font-size:12.5px}
.sd-h6{font-family:var(--font-mono);font-size:8.5px;letter-spacing:.1em;color:var(--text-light);text-align:center;padding:2px 4px}
/* profile activity: full incident descriptions, wrapped under the type line */
#sdAct .sd-ev{flex-wrap:wrap}
#sdAct .sd-ev .ty{width:auto;max-width:280px}
#sdAct .sd-ev .desc{flex-basis:100%;font-size:12.5px;color:var(--text-muted);line-height:1.5;
  white-space:normal;margin:3px 0 1px;padding-left:2px}
@media (max-width:900px){.sd-tg{grid-template-columns:repeat(2,1fr)}}
/* DA Scorecard tab \u2014 the DA's phone view, rendered for dispatchers */
.sc-mode{border:none;background:transparent;border-radius:8px;padding:6px 13px;font-size:12px;font-weight:700;color:var(--text-light);cursor:pointer;font-family:var(--font)}
.sc-mode.on{background:var(--text);color:#F4F3EE}
.sc-hero{text-align:center;margin:4px 0 10px}
.sc-hero .lbl{font-family:var(--font-mono);font-size:9.5px;letter-spacing:.16em;color:var(--text-light)}
.sc-hero .n{font-family:var(--font-disp);font-weight:800;font-size:38px;color:var(--text);letter-spacing:-.02em;line-height:1.05}
.sc-tiles{display:grid;grid-template-columns:1fr 1fr;gap:9px;margin-bottom:11px}
.sc-tile{background:var(--text);color:#F4F3EE;border-radius:15px;padding:14px 10px;text-align:center}
.sc-tile .big{font-family:var(--font-disp);font-weight:800;font-size:20px}
.sc-tile .big small{font-size:12px;color:#B9BBC2;font-weight:700}
.sc-tile .lb{font-family:var(--font-mono);font-size:8.5px;letter-spacing:.14em;color:#8A8E97;margin-top:3px}
.sc-tile.tier{background:var(--status-info-solid)}
.sc-card{background:#fff;border:1px solid var(--border);border-radius:15px;margin-bottom:11px;overflow:hidden}
.sc-card h4{display:flex;align-items:center;gap:8px;font-family:var(--font-disp);font-weight:800;font-size:14px;color:var(--text);padding:10px 13px;border-bottom:1px solid #ECEAE1;letter-spacing:-.01em}
.sc-card h4 .tier{margin-left:auto}
.sc-rows{padding:4px 13px 10px}
.sc-row{display:flex;align-items:center;gap:9px;padding:7px 0;border-bottom:1px solid #ECEAE1;font-size:12.5px}
.sc-row:last-child{border-bottom:none}
.sc-row .l{color:var(--text-muted);flex:1}
.sc-row .l small{display:block;font-family:var(--font-mono);font-size:8.5px;color:#A6A9B1;letter-spacing:.04em}
.sc-row .v{font-family:var(--font-mono);font-size:11.5px;font-weight:600;color:var(--text);border-radius:7px;padding:2.5px 9px}
.sc-row .v.g{background:var(--status-ok-bg);color:var(--status-ok-fg)}
.sc-row .v.w{background:var(--status-warn-bg);color:var(--status-warn-fg)}
.sc-row .v.b{background:var(--status-action-bg);color:var(--status-action-fg)}
.sc-row .v.n{background:#F8F7F2;color:var(--text-light)}
.sc-note{font-family:var(--font-mono);font-size:8.5px;color:#A6A9B1;padding:0 13px 10px;letter-spacing:.04em}
.sc-focus{background:var(--text);color:#B9BBC2;border-radius:15px;padding:13px;margin-bottom:11px}
.sc-focus h5{font-family:var(--font-mono);font-size:8.5px;letter-spacing:.16em;color:var(--status-warn-fg);margin-bottom:6px}
.sc-focus .kfa{font-family:var(--font-disp);font-weight:800;font-size:15px;color:#fff}
@media (max-width:1100px){.sd-qgrid{grid-template-columns:repeat(4,1fr)}.sd-kpi6{grid-template-columns:repeat(3,1fr)}}
@media (max-width:760px){.sd-kpi6{grid-template-columns:repeat(2,1fr)}.sd-2,.sd-3,.sd-half{grid-template-columns:1fr}.sd-tabs{order:5;width:100%;overflow-x:auto}}
</style>

<div class="sd-hd">
  <h2>MVPx Dashboard</h2>
  <span id="sdWkBadge" class="sd-pill plat" style="display:none"></span>
  <div class="sd-tabs" id="sdTabs">
    <button class="on" onclick="sdShow(0,this)">Overview</button>
    <button onclick="sdShow(1,this)">Trends</button>
    <button onclick="sdShow(2,this)">DA Performance</button>
    <button onclick="sdShow(3,this)">Coaching</button>
    <button onclick="sdShow(4,this)">DA Profile</button>
    <button onclick="sdShow(5,this)">DA Scorecard</button>
  </div>
</div>

<%if(_errorBean != null && _errorBean.getType().length() > 0){%>
<div class="alert-box <%=_errorBean.getType()%>Color"><%=_errorBean.getMesg()%></div>
<%}%>

<!-- ═══ 0 OVERVIEW ═══ -->
<div class="sd-view on" id="sdv0">
  <div class="sd-grid sd-kpi6" id="sdKpis"></div>
  <div class="sd-grid sd-3 sd-mt">
    <div class="sd-card">
      <h3>Standings Mix <select class="sd-wksel" id="wkStand" onchange="sdCoreCard('stand')"></select><span class="src">dashboard_overview</span></h3>
      <div id="sdStandings"></div>
    </div>
    <div class="sd-card">
      <h3>Focus Areas <select class="sd-wksel" id="wkKfa" onchange="sdCoreCard('kfa')"></select><span class="src">POD &lt; 100% / DNR / DSB / CDF &gt; 0</span></h3>
      <div id="sdKfa"></div>
    </div>
    <div class="sd-card">
      <h3>Ops Pulse <span id="sdOpsDate" style="font-family:var(--font-mono);font-size:10px;color:var(--text)"></span><span class="src">dacheckin &middot; wave sheet &middot; confirmations</span></h3>
      <div id="sdOps"></div>
    </div>
  </div>
  <div class="sd-card sd-mt">
    <h3>Quality Overview &middot; Fleet <select class="sd-wksel" id="wkQual" onchange="sdCoreCard('qual')"></select><span class="src">quality_overview &middot; dashboard_overview &middot; quality_dcr_weekly</span></h3>
    <div class="sd-qgrid" id="sdQual"></div>
  </div>
  <div class="sd-grid sd-half sd-mt">
    <div class="sd-card">
      <h3>Safety Events by Week <span class="src">safety_dashboard</span></h3>
      <svg class="sdchart" width="100%" height="118" viewBox="0 0 560 118" id="sdSafetyWk"></svg>
    </div>
    <div class="sd-card">
      <h3>DA Survey <select class="sd-wksel" id="moSurv" onchange="sdDaSurveyRender()"></select><span class="src">sentiment_survey</span></h3>
      <div id="sdDaSurvey"></div>
    </div>
  </div>
</div>

<!-- ═══ 1 TRENDS ═══ -->
<div class="sd-view" id="sdv1">
  <div class="sd-grid sd-half" style="margin-bottom:11px">
  <div class="sd-card">
    <h3>Safety Incidents by Week
      <select class="sd-wksel" id="sdSafRange" onchange="sdSafetyTrendRender()">
        <option value="6wk">LAST 6 WEEKS</option>
        <option value="wk">CURRENT WEEK</option>
        <option value="12wk">LAST 12 WEEKS</option>
        <option value="24wk">LAST 24 WEEKS</option>
        <option value="cmonth">CURRENT MONTH</option>
        <option value="pmonth">PREVIOUS MONTH</option>
        <option value="cyear">CURRENT YEAR</option>
        <option value="pyear">PREVIOUS YEAR</option>
      </select>
      <span class="src">safety_dashboard &middot; camera events</span>
    </h3>
    <svg class="sdchart" width="100%" height="170" viewBox="0 0 560 170" id="sdSafetyTrend"></svg>
  </div>
    <div class="sd-card"><h3>Safety Event Mix
      <select class="sd-wksel" id="sdMixWk" onchange="sdMixLoad()"><option value="all">ALL TIME</option></select>
      <span class="src">safety_dashboard</span></h3>
      <svg class="sdchart" width="100%" height="170" viewBox="0 0 560 170" id="sdSafetyMix"></svg></div>
  </div>
  <div class="sd-card">
    <h3>Packages Delivered by Week <span class="src">dashboard_overview</span></h3>
    <svg class="sdchart" width="100%" height="165" viewBox="0 0 1140 165" id="sdPkgBars"></svg>
  </div>
  <div class="sd-grid sd-half sd-mt">
    <div class="sd-card"><h3>Rescues / Week <span class="src">incidents &middot; rescue types</span></h3>
      <svg class="sdchart" width="100%" height="115" viewBox="0 0 320 115" id="sdRescLine"></svg></div>
    <div class="sd-card"><h3>Call-outs &amp; Lates / Week <span class="src">incidents</span></h3>
      <svg class="sdchart" width="100%" height="115" viewBox="0 0 320 115" id="sdAttLine"></svg>
      <div class="sd-legend"><span><span class="sw"></span>Call-outs</span><span><span class="sw dash"></span>Lates</span></div></div>

  </div>
</div>

<!-- ═══ 2 LEAGUE ═══ -->
<div class="sd-view" id="sdv2">
  <div class="sd-card" style="padding:0">
    <div style="display:flex;align-items:center;gap:10px;padding:10px 14px;border-bottom:1px solid var(--border)">
      <span style="font-family:var(--font-mono);font-size:9.5px;letter-spacing:.15em;color:var(--text-light)">DA LEAGUE TABLE</span>
      <select class="sd-wksel" id="wkLeague" onchange="sdLeagueWeek()"></select>
      <select class="sd-wksel" id="lgStand" onchange="sdLeagueRender()">
        <option value="">All standings</option><option>Platinum</option><option>Fantastic</option>
        <option>Great</option><option>Fair</option><option>Poor</option>
      </select>
      <span style="margin-left:auto;font-family:var(--font-mono);font-size:8.5px;color:#A6A9B1">scorecard + quality + safety + coaching &middot; row click &rarr; profile</span>
    </div>
    <div style="overflow-x:auto;scrollbar-width:none">
    <table class="sd-lg">
      <thead><tr><th></th><th>Delivery Associate</th><th>Standing</th><th>Score</th>
        <th>DCR</th><th>POD</th><th>DNR</th><th>DSB</th><th>CDF</th><th>Pkgs</th><th>Safety EV</th><th>Coach</th></tr></thead>
      <tbody id="sdLgRows"></tbody>
    </table>
    </div>
    <div class="sd-foot"><span id="sdLgInfo"></span>
      <div class="pg"><button class="sd-pgbtn" id="sdLgPrev" onclick="sdLgPage(-1)">&#8249;</button>
      <span id="sdLgLabel">1/1</span>
      <button class="sd-pgbtn" id="sdLgNext" onclick="sdLgPage(1)">&#8250;</button></div>
    </div>
  </div>
</div>

<!-- ═══ 3 COACHING ═══ -->
<div class="sd-view" id="sdv3">
  <div class="sd-grid sd-2">
    <div>
      <div class="sd-card">
        <h3>Open Coaching
          <span style="display:inline-flex;gap:4px" id="sdClFilters">
            <button type="button" class="sc-mode on" data-c="" onclick="sdClFilter(this)">All</button>
            <button type="button" class="sc-mode" data-c="Safety" onclick="sdClFilter(this)">Safety</button>
            <button type="button" class="sc-mode" data-c="Quality" onclick="sdClFilter(this)">Quality</button>
            <button type="button" class="sc-mode" data-c="Other" onclick="sdClFilter(this)">Other</button>
          </span>
          <span class="src">coaching_log &middot; every DA conversation lives here</span></h3>
        <div id="sdCoachLog"></div>
      </div>
      <div class="sd-card sd-mt">
        <h3>Coaching Queue &middot; suggested <select class="sd-wksel" id="wkCoach" onchange="sdCoachWeek()"></select><span class="src">KFA + camera events + standing</span></h3>
        <div id="sdQueue"></div>
      </div>
    </div>
    <div>
      <div class="sd-card">
        <h3>Coaching Volume by Week <span class="src">incidents &middot; B_Coached</span></h3>
        <svg class="sdchart" width="100%" height="105" viewBox="0 0 320 105" id="sdCoachBars"></svg>
        <div class="sd-legend"><span><span class="sw bar"></span>Quality</span><span><span class="sw bar gr"></span>Safety</span></div>
      </div>
      <div class="sd-card sd-mt">
        <h3>Write-ups by Week <span class="src">employeeforms &middot; formstemplate</span></h3>
        <svg class="sdchart" width="100%" height="95" viewBox="0 0 320 95" id="sdWriteupBars"></svg>
        <div class="sd-legend"><span><span class="sw bar"></span>Safety warnings</span><span><span class="sw bar gr"></span>Other categories</span></div>
        <div style="margin-top:9px;display:flex;flex-wrap:wrap;gap:6px" id="sdWriteupCats"></div>
      </div>
      <div class="sd-card sd-mt">
        <h3>Escalations <span class="src">escalations &middot; latest</span></h3>
        <div id="sdEscal"></div>
      </div>
    </div>
  </div>
</div>

<!-- ═══ 4 PROFILE ═══ -->
<div class="sd-view" id="sdv4">
  <div class="sd-card">
    <div style="display:flex;align-items:center;gap:12px;flex-wrap:wrap">
      <select class="sd-dasel" id="sdDaSel" onchange="sdProfileLoad()"></select>
      <select class="sd-wksel" id="wkProf" onchange="sdProfileLoad()"></select>
      <span id="sdProfBadge"></span>
      <span id="sdProfKfa" style="font-family:var(--font-mono);font-size:10.5px;color:var(--text-light)"></span>
      <button class="btn2 sm" style="margin-left:auto" onclick="submitPageDataForm('<%=SubmitType.SEARCH%>','Incident')">Open incidents</button>
      <button class="btn2 sm" onclick="submitPageDataForm('<%=SubmitType.SEARCH%>','EmployeeForms')">Employee forms</button>
    </div>
  </div>
  <div class="sd-grid sd-kpi6 sd-mt" id="sdProfKpis"></div>

  <div class="sd-grid sd-half sd-mt">
    <div class="sd-card">
      <h3>Safety Metrics &middot; selected week <span class="src">dashboard_overview tiers</span></h3>
      <div class="sd-tg" id="sdTierSaf"></div>
    </div>
    <div class="sd-card">
      <h3>Quality Metrics &middot; selected week <span class="src">dashboard_overview tiers</span></h3>
      <div class="sd-tg" id="sdTierQual"></div>
    </div>
  </div>

  <div class="sd-grid sd-2 sd-mt">
    <div class="sd-card">
      <h3>Standing &amp; Score Trend &middot; 14 weeks <span class="src">dashboard_overview</span></h3>
      <svg class="sdchart" width="100%" height="128" viewBox="0 0 560 128" id="sdStandLine"></svg>
      <svg class="sdchart" width="100%" height="140" viewBox="0 0 560 140" id="sdDaLine"></svg>
      <div class="sd-legend"><span><span class="sw"></span><span id="sdDaLegend">DA</span></span><span><span class="sw dash"></span>Fleet average</span></div>
    </div>
    <div class="sd-card">
      <h3>Weekly Activity <span class="src">incidents &middot; OSHA &middot; terminations</span></h3>
      <div id="sdAct"></div>
    </div>
  </div>

  <div class="sd-grid sd-half sd-mt">
    <div class="sd-card">
      <h3>Activity
        <select class="sd-wksel" id="actRange" onchange="sdProfileLoad()">
          <option value="6">LAST 6 WEEKS</option>
          <option value="12">LAST 12 WEEKS</option>
        </select>
        <span class="src">incidents &middot; OSHA &middot; terminations</span></h3>
      <div id="sdAct6" style="overflow-y:auto;max-height:260px;scrollbar-width:none"></div>
    </div>
    <div class="sd-card">
      <h3>Vehicles Driven
        <select class="sd-wksel" id="vehRange" onchange="sdProfileLoad()">
          <option value="1">THIS WEEK</option>
          <option value="6">LAST 6 WEEKS</option>
          <option value="12">LAST 12 WEEKS</option>
        </select>
        <span class="src">dacheckin &middot; vehicle</span></h3>
      <div id="sdVeh"></div>
    </div>
  </div>

  <div class="sd-card sd-mt">
    <h3>Trips &amp; Flex App
      <select class="sd-wksel" id="wkTrips" onchange="sdTripsLoad()"></select>
      <span id="sdWkHrs" style="font-family:var(--font-mono);font-size:10px;color:var(--text)"></span>
      <span class="src">daily_itineraries &middot; sign-in/out &middot; break &middot; pace</span></h3>
    <div id="sdDays" style="overflow-x:auto;scrollbar-width:none"></div>
  </div>
</div>

<!-- ═══ 5 DA SCORECARD (exactly what the DA will see) ═══ -->
<div class="sd-view" id="sdv5">
  <div class="sd-card" style="max-width:560px;margin:0 auto 12px">
    <div style="display:flex;align-items:center;gap:10px;flex-wrap:wrap">
      <select class="sd-dasel" id="sdScDa" style="flex:1;min-width:190px" onchange="sdScLoad()"></select>
      <select class="sd-wksel" id="wkSc" onchange="sdScLoad()"></select>
      <span style="display:inline-flex;background:#F8F7F2;border:1px solid var(--border);border-radius:10px;padding:2px">
        <button type="button" class="sc-mode on" data-m="cur" onclick="sdScMode(this)">Current</button>
        <button type="button" class="sc-mode" data-m="trail" onclick="sdScMode(this)">6-Wk Trailing</button>
      </span>
    </div>
  </div>
  <div id="sdSc" style="max-width:440px;margin:0 auto"></div>
</div>

<div class="sd-tip" id="sdTip"></div>

<script>
var BOOT = <%=_bootstrapJson%>;
var SD_CTRL = 'StationDashboard';

function sdEsc(s){ return String(s == null ? '' : s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;'); }
function sdShow(i, btn){
  document.querySelectorAll('.sd-view').forEach(function(v, j){ v.classList.toggle('on', j === i); });
  document.querySelectorAll('#sdTabs button').forEach(function(b){ b.classList.remove('on'); });
  btn.classList.add('on');
  if (i === 2) sdLgFitRender();
  if (i === 5 && !document.getElementById('sdSc').innerHTML) {
    /* follow the profile's DA if one is selected */
    var pd = document.getElementById('sdDaSel');
    if (pd && pd.value) document.getElementById('sdScDa').value = pd.value;
    sdScLoad();
  }
}
function sdAjax(params, cb){
  var body = new URLSearchParams();
  body.append('submitType', '<%=SubmitType.DYNAMIC%>');
  body.append('controller', SD_CTRL);
  body.append('requestType', 'dash');
  ['entityID','loginUser','loginUserID','loginUserRoles','loginUserDisplayName'].forEach(function(k){
    var el = document.getElementById(k); if (el) body.append(k, el.value);
  });
  for (var k in params) body.append(k, params[k]);
  fetch('MVPGServlet', { method:'POST', headers:{'Content-Type':'application/x-www-form-urlencoded'}, body: body.toString() })
    .then(function(r){ return r.text(); })
    .then(function(t){ try { cb(JSON.parse(t)); } catch(e) { cb(null); } })
    .catch(function(){ cb(null); });
}

/* tooltip + chart helpers (ink monochrome) */
var sdTipEl = document.getElementById('sdTip');
function sdTipShow(e, html){ sdTipEl.innerHTML = html; sdTipEl.style.opacity = 1;
  sdTipEl.style.left = (e.clientX + 14) + 'px'; sdTipEl.style.top = (e.clientY - 10) + 'px'; }
function sdTipHide(){ sdTipEl.style.opacity = 0; }

function sdLine(id, series, labels, fmt){
  var svg = document.getElementById(id); if (!svg) return;
  var vb = svg.viewBox.baseVal, W = vb.width, H = vb.height;
  var padL = 34, padR = 12, padT = 12, padB = 20;
  var all = [];
  series.forEach(function(s){ s.pts.forEach(function(v){ if (v !== null && v !== '') all.push(+v); }); });
  if (!all.length) { svg.innerHTML = '<text x="10" y="30">no data</text>'; return; }
  var mn = Math.min.apply(null, all), mx = Math.max.apply(null, all);
  var span = (mx - mn) || 1; var mn0 = mn; mn -= span * .15; mx += span * .1;
  if (mn0 >= 0 && mn < 0) mn = 0; /* counts never chart below zero */
  var n = series[0].pts.length;
  function X(i){ return n < 2 ? W / 2 : padL + i * (W - padL - padR) / (n - 1); }
  function Y(v){ return padT + (1 - (v - mn) / (mx - mn)) * (H - padT - padB); }
  var g = '';
  for (var gi = 0; gi < 3; gi++){
    var gy = padT + gi * (H - padT - padB) / 2, gv = mx - gi * (mx - mn) / 2;
    g += '<line class="grid-l" x1="' + padL + '" y1="' + gy + '" x2="' + (W - padR) + '" y2="' + gy + '"/>'
       + '<text x="2" y="' + (gy + 3) + '">' + (fmt ? fmt(gv) : Math.round(gv)) + '</text>';
  }
  series.forEach(function(s){
    var dtr = '';
    s.pts.forEach(function(v, i){ if (v === null || v === '') return; dtr += (dtr ? ' ' : '') + X(i) + ',' + Y(+v); });
    g += '<polyline fill="none" stroke="' + (s.dash ? '#A6A9B1' : '#141519') + '" stroke-width="2"'
       + (s.dash ? ' stroke-dasharray="5 4"' : '') + ' points="' + dtr + '"/>';
  });
  series[0].pts.forEach(function(v, i){
    if (v === null || v === '') return;
    g += '<circle cx="' + X(i) + '" cy="' + Y(+v) + '" r="3" fill="#141519"/>'
       + '<rect x="' + (X(i) - 11) + '" y="' + padT + '" width="22" height="' + (H - padT - padB) + '" fill="transparent" data-i="' + i + '"/>';
  });
  labels.forEach(function(l, i){
    if (i % Math.ceil(n / 7) !== 0 && i !== n - 1) return;
    g += '<text x="' + X(i) + '" y="' + (H - 5) + '" text-anchor="middle">' + sdEsc(l) + '</text>';
  });
  svg.innerHTML = g;
  svg.querySelectorAll('rect[data-i]').forEach(function(rc){
    rc.addEventListener('mousemove', function(e){
      var i = parseInt(rc.dataset.i, 10), t = '<b>' + sdEsc(labels[i]) + '</b>';
      series.forEach(function(s){ if (s.pts[i] !== null && s.pts[i] !== '') t += '<br>' + sdEsc(s.name) + ': <b>' + s.pts[i] + '</b>'; });
      sdTipShow(e, t);
    });
    rc.addEventListener('mouseleave', sdTipHide);
  });
}

function sdBars(id, vals, labels){
  var svg = document.getElementById(id); if (!svg) return;
  var vb = svg.viewBox.baseVal, W = vb.width, H = vb.height;
  var padL = 28, padR = 6, padT = 8, padB = 18;
  var mx = 0;
  vals.forEach(function(v){ if (v) mx = Math.max(mx, (v.q !== undefined ? (+v.q) + (+v.s) : +v)); });
  if (!mx) { svg.innerHTML = '<text x="10" y="30">no data</text>'; return; }
  var n = vals.length, bw = (W - padL - padR) / n;
  var g = '<line class="grid-l" x1="' + padL + '" y1="' + (H - padB) + '" x2="' + (W - padR) + '" y2="' + (H - padB) + '"/>';
  vals.forEach(function(v, i){
    if (v === null) return;
    var x = padL + i * bw + bw * .18, w = bw * .64;
    if (v.q !== undefined){
      var hq = (+v.q) / mx * (H - padT - padB), hs = (+v.s) / mx * (H - padT - padB);
      g += '<rect x="' + x + '" y="' + (H - padB - hq) + '" width="' + w + '" height="' + hq + '" rx="3" fill="#141519" data-i="' + i + '"/>'
         + '<rect x="' + x + '" y="' + (H - padB - hq - 2 - hs) + '" width="' + w + '" height="' + Math.max(0, hs) + '" rx="3" fill="#7A7E88" data-i="' + i + '"/>';
    } else {
      var h = (+v) / mx * (H - padT - padB);
      g += '<rect x="' + x + '" y="' + (H - padB - h) + '" width="' + w + '" height="' + h + '" rx="3" fill="#141519" data-i="' + i + '"/>';
      if (n <= 16 && +v > 0)
        g += '<text x="' + (x + w / 2) + '" y="' + (H - padB - h - 3) + '" text-anchor="middle" style="font-weight:600">' + v + '</text>';
    }
    if (n <= 14 || i % 2 === 0)
      g += '<text x="' + (x + w / 2) + '" y="' + (H - 4) + '" text-anchor="middle">' + sdEsc(labels[i]) + '</text>';
  });
  svg.innerHTML = g;
  svg.querySelectorAll('rect[data-i]').forEach(function(rc){
    rc.addEventListener('mousemove', function(e){
      var i = parseInt(rc.dataset.i, 10), v = vals[i];
      sdTipShow(e, '<b>' + sdEsc(labels[i]) + '</b><br>' + (v.q !== undefined ? 'q: <b>' + v.q + '</b> \u00B7 s: <b>' + v.s + '</b>' : '<b>' + v + '</b>'));
    });
    rc.addEventListener('mouseleave', sdTipHide);
  });
}

function sdHBars(id, items){
  var svg = document.getElementById(id); if (!svg) return;
  var vb = svg.viewBox.baseVal, W = vb.width;
  var mx = 0; items.forEach(function(it){ mx = Math.max(mx, +it.c); });
  if (!mx) { svg.innerHTML = '<text x="10" y="30">no data</text>'; return; }
  /* rows auto-fit the card height so every category stays visible */
  var H = vb.height;
  var rowH = Math.max(14, Math.min(26, Math.floor((H - 12) / Math.max(1, items.length))));
  var g = '', labW = 118, valW = 34;
  items.forEach(function(it, i){
    var y = 8 + i * rowH;
    var w = Math.max(4, (+it.c) / mx * (W - labW - valW - 14));
    var nm = it.n.length > 20 ? it.n.substring(0, 19) + '\u2026' : it.n;
    g += '<text x="0" y="' + (y + 9) + '">' + sdEsc(nm.toUpperCase()) + '</text>'
       + '<rect x="' + labW + '" y="' + y + '" width="' + w + '" height="11" rx="4" fill="#141519"><title>' + sdEsc(it.n) + '</title></rect>'
       + '<text x="' + (labW + w + 6) + '" y="' + (y + 9) + '" class="lbl-ink">' + it.c + '</text>';
  });
  svg.innerHTML = g;
}

/* ── week selects ──────────────────────────────────────────── */
/* Scorecard week range: Sunday-started, week 1 contains Jan 1 (Amazon convention) */
function sdWkRange(y, w){
  var jan1 = new Date(+y, 0, 1);
  var start = new Date(+y, 0, 1 - jan1.getDay() + (w - 1) * 7);
  var end = new Date(start); end.setDate(start.getDate() + 6);
  return (start.getMonth() + 1) + '/' + start.getDate() + '-' + (end.getMonth() + 1) + '/' + end.getDate();
}
function sdWkOptions(sel, y, w){
  var el = document.getElementById(sel);
  el.innerHTML = '';
  BOOT.weeks.forEach(function(k){
    var o = document.createElement('option');
    o.value = k.y + '|' + k.w;
    o.textContent = 'WK ' + k.w + ' (' + sdWkRange(k.y, k.w) + ') ' + k.y;
    if (k.y == y && k.w == w) o.selected = true;
    el.appendChild(o);
  });
}
function sdWkOf(sel){ var v = document.getElementById(sel).value.split('|'); return { y: v[0], w: v[1] }; }

/* ── OVERVIEW renders ─────────────────────────────────────── */
var STAND_CLS = { 'Platinum':'plat', 'Fantastic':'fan', 'Gold':'fair', 'Great':'great', 'Fair':'fair', 'Poor':'poor', 'Silver':'great', 'Bronze':'poor' };
function mvpxCssVar(name, fallback){
  try { var v = getComputedStyle(document.documentElement).getPropertyValue(name).trim(); return v || fallback; }
  catch(e){ return fallback; }
}
var STAND_COL = {
  'Platinum': mvpxCssVar('--status-info-fg','#1D4ED8'),
  'Fantastic': mvpxCssVar('--status-ok-fg','#15803D'),
  'Gold': mvpxCssVar('--status-warn-fg','#B45309'),
  'Great': mvpxCssVar('--status-neutral-fg','#7A7E88'),
  'Fair': mvpxCssVar('--status-warn-fg','#B45309'),
  'Poor': mvpxCssVar('--status-action-fg','#C62828'),
  'Silver': mvpxCssVar('--status-neutral-fg','#7A7E88'),
  'Bronze': mvpxCssVar('--status-action-fg','#C62828')
};

/* metric tiers reuse standing colors; Silver/Bronze fold to gray/red */
function sdTierCls(t){
  t = String(t || '');
  if (STAND_CLS[t]) return STAND_CLS[t];
  if (t.indexOf('Silver') >= 0) return 'great';
  if (t.indexOf('Bronze') >= 0) return 'poor';
  return 'great';
}

/* standing-by-week band chart (Amazon "Performance trends" style) */
/* new scorecard standing names; legacy names fold in (Fantastic = Platinum) */
var SD_BANDS = ['Platinum', 'Gold', 'Silver', 'Bronze'];
function sdStandNorm(st){
  if (!st) return st;
  var s = String(st).toUpperCase();
  if (s.indexOf('FANTASTIC') === 0 || s === 'PLATINUM') return 'Platinum';
  if (s === 'GREAT' || s === 'GOLD') return 'Gold';
  if (s === 'FAIR' || s === 'SILVER') return 'Silver';
  if (s === 'POOR' || s === 'BRONZE' || s.indexOf('RISK') >= 0) return 'Bronze';
  return st;
}
function sdStandChart(id, rawTrend){
  var trend = rawTrend.map(function(t){
    return { w: t.w, st: t.st ? sdStandNorm(t.st) : t.st };
  });
  var svg = document.getElementById(id); if (!svg) return;
  var vb = svg.viewBox.baseVal, W = vb.width, H = vb.height;
  var padL = 74, padR = 12, padT = 10, padB = 18;
  /* only draw bands that appear, but always keep at least the top three */
  var present = {};
  trend.forEach(function(t){ if (t.st) present[t.st] = 1; });
  var bands = SD_BANDS.filter(function(b, i){ return present[b] || i < 3; });
  var rowH = (H - padT - padB) / Math.max(1, bands.length - 1);
  function BY(st){ var i = bands.indexOf(st); return i < 0 ? null : padT + i * rowH; }
  var g = '';
  bands.forEach(function(b, i){
    var y = padT + i * rowH;
    g += '<line class="grid-l" x1="' + padL + '" y1="' + y + '" x2="' + (W - padR) + '" y2="' + y + '"/>'
       + '<text x="' + (padL - 6) + '" y="' + (y + 3) + '" text-anchor="end">' + b.toUpperCase() + '</text>';
  });
  var n = trend.length;
  function X(i){ return n < 2 ? W / 2 : padL + i * (W - padL - padR) / (n - 1); }
  var line = '';
  trend.forEach(function(t, i){
    var y = BY(t.st);
    if (y === null) return;
    line += (line ? ' ' : '') + X(i) + ',' + y;
  });
  if (line) g += '<polyline fill="none" stroke="#141519" stroke-width="2" points="' + line + '"/>';
  trend.forEach(function(t, i){
    var y = BY(t.st);
    if (y === null) return;
    var col = STAND_COL[t.st] || '#141519';
    g += '<circle cx="' + X(i) + '" cy="' + y + '" r="4.5" fill="' + col + '" stroke="#fff" stroke-width="1.5">'
       + '<title>WK' + t.w + ' ' + sdEsc(t.st) + '</title></circle>';
    if (i % Math.ceil(n / 7) === 0 || i === n - 1)
      g += '<text x="' + X(i) + '" y="' + (H - 4) + '" text-anchor="middle">W' + t.w + '</text>';
  });
  if (!line) g += '<text x="' + padL + '" y="' + (H / 2) + '">no standing history</text>';
  svg.innerHTML = g;
}

function sdKpisRender(c){
  var h = '', p = c.prev || {};
  function kpi(l, v, s){ h += '<div class="sd-card sd-kpi"><div class="lbl">' + l + '</div><div class="num">' + v + '</div><div class="sub">' + s + '</div></div>'; }
  function fmtN(v){ return (v === '' || v == null) ? 'No Data' : Number(v).toLocaleString(); }
  function nz(v){ return (v === '' || v == null) ? '0' : v; }
  function lastWk(prev, fmt){ return c.pw ? 'last wk ' + c.pw + ': <b>' + (fmt || nz)(prev) + '</b>' : 'no prior week'; }

  var dispSub = (c.dispatched !== '' && +c.dispatched > 0)
      ? 'of <b>' + fmtN(c.dispatched) + '</b> dispatched \u00B7 ' + lastWk(p.pkgs, fmtN)
      : lastWk(p.pkgs, fmtN);
  kpi('Packages Delivered', fmtN(c.pkgs), dispSub);
  kpi('DAs Worked', nz(c.das), lastWk(p.das));
  var trips = +nz(c.trips);
  var safSub = trips > 0
      ? '<b>' + trips + '</b> trips \u00B7 ' + (Math.round((+nz(c.safety)) / trips * 100) / 100) + '/trip \u00B7 ' + lastWk(p.safety)
      : lastWk(p.safety);
  kpi('Safety Events', nz(c.safety), safSub);
  kpi('Rescues', nz(c.rescues), 'rescue legs logged \u00B7 ' + lastWk(p.rescues));
  kpi('Routes Rescued', nz(c.rescRoutes), lastWk(p.rescRoutes));
  kpi('DAs Rescued', nz(c.rescDas), lastWk(p.rescDas));
  kpi('Extra DAs', nz(c.extraDas), 'on Extra-DA vans \u00B7 ' + lastWk(p.extraDas));
  kpi('Routes', nz(c.routes), 'itineraries \u00B7 ' + lastWk(p.routes));
  kpi('Flex App Hours', c.flexHrs === '' ? 'No Data' : fmtN(c.flexHrs), 'sign-in to sign-out \u00B7 ' + lastWk(p.flexHrs, fmtN));
  kpi('DAs Over 40 Hr', nz(c.over40), 'flex app clock \u00B7 ' + lastWk(p.over40));
  document.getElementById('sdKpis').innerHTML = h;
  var b = document.getElementById('sdWkBadge');
  b.style.display = ''; b.className = 'sd-pill plat';
  b.innerHTML = '<span class="d"></span>WK ' + c.w + ' \u00B7 ' + c.y;
}

function sdStandBar(list){
  var tot = 0; list.forEach(function(s){ tot += +s.c; });
  var h = '<svg class="sdchart" width="100%" height="30" viewBox="0 0 600 30" preserveAspectRatio="none">';
  var x = 0;
  list.forEach(function(s){
    var w = tot ? Math.max(8, (+s.c) / tot * 596) : 0;
    if (x + w > 596) w = 596 - x;
    var col = STAND_COL[s.n] || '#A6A9B1';
    h += '<rect x="' + x + '" y="4" width="' + Math.max(2, w - 2) + '" height="22" rx="4" fill="' + col + '">'
       + '<title>' + sdEsc(s.n) + ': ' + s.c + '</title></rect>';
    if (w > 34)
      h += '<text x="' + (x + w / 2) + '" y="19" text-anchor="middle" style="fill:#fff;font-weight:600">' + s.c + '</text>';
    x += w;
  });
  return h + '</svg>';
}
function sdStandRender(c){
  var h = '<div class="sd-legend" style="margin:0 0 3px">THIS WK ' + c.w + '</div>' + sdStandBar(c.standings);
  if (c.prevStandings && c.prevStandings.length)
    h += '<div class="sd-legend" style="margin:8px 0 3px">LAST WK ' + c.pw + '</div>' + sdStandBar(c.prevStandings);
  h += '<div class="sd-legend" style="margin-top:9px">';
  c.standings.forEach(function(s){
    h += '<span class="sd-pill ' + (STAND_CLS[s.n] || 'great') + '"><span class="d"></span>' + sdEsc(s.n) + ': ' + s.c + '</span>';
  });
  h += '</div>';
  document.getElementById('sdStandings').innerHTML = h;
}

function sdQualRender(c){
  var q = c.quality, h = '';
  function qt(l, v, s){ h += '<div class="sd-qt"><div class="l">' + l + '</div><div class="v">' + (v === '' || v == null ? '\u2014' : v) + '</div><div class="s">' + s + '</div></div>'; }
  qt('DCR', q.dcr ? q.dcr + '%' : '', 'fleet avg');
  qt('POD', q.podPct ? q.podPct + '%' : '', q.podS !== '' && q.podO !== '' ? (q.podS || 0) + ' / ' + (q.podO || 0) + ' opps' : 'fleet avg');
  qt('DNR', q.dnr, q.dnrDpmo ? q.dnrDpmo + ' DPMO avg' : 'packages');
  qt('DSB', q.dsb, 'DPMO avg');
  /* CDF: defect count when a CDF detail upload covers the week,
     otherwise the scorecard's CDF DPMO so the tile always has a value */
  if (q.cdfDefects !== '' && q.cdfDefects != null) qt('CDF', q.cdfDefects, 'defects \u00B7 WK');
  else qt('CDF', q.cdfDpmo, 'DPMO avg');
  qt('CED', q.cedDefects !== '' ? q.cedDefects : q.ced, 'escalation defects');
  document.getElementById('sdQual').innerHTML = h;
}

/* Focus Areas: compact strip (was a tall bar chart) */
function sdKfaRender(c){
  var h = '';
  (c.focus || []).forEach(function(f){
    h += '<div class="sd-vs" style="margin-bottom:4px;padding:4px 8px"><span class="v" style="font-size:17px">'
       + (f.c === '' || f.c == null ? '\u2014' : f.c) + '</span><span class="f">' + sdEsc(f.n).toUpperCase() + '</span></div>';
  });
  document.getElementById('sdKfa').innerHTML = h;
}

/* DA sentiment survey: month dropdown + per-question favorable rates */
var SD_MONTHS = ['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
function sdDaSurveyInit(rows){
  window.SD_SURVEY = rows || [];
  var sel = document.getElementById('moSurv');
  var seen = {}, h = '';
  window.SD_SURVEY.forEach(function(r){
    var k = r.yr + '|' + r.mo;
    if (!seen[k]) { seen[k] = 1; h += '<option value="' + k + '">' + (SD_MONTHS[+r.mo] || r.mo).toUpperCase() + ' ' + r.yr + '</option>'; }
  });
  sel.innerHTML = h;
  sdDaSurveyRender();
}
function sdDaSurveyRender(){
  var sel = document.getElementById('moSurv');
  var box = document.getElementById('sdDaSurvey');
  if (!sel.value) { box.innerHTML = '<div class="sd-legend">NO SURVEY UPLOAD ON FILE</div>'; return; }
  var p = sel.value.split('|');
  var rows = window.SD_SURVEY.filter(function(r){ return r.yr == p[0] && r.mo == p[1]; });
  var h = '', respSum = 0, respN = 0;
  rows.forEach(function(r){
    if (r.resp !== '') { respSum += +r.resp; respN++; }
    var dir = '';
    if (r.fav !== '' && r.t6m !== '')
      dir = +r.fav >= +r.t6m ? ' style="color:var(--status-ok-fg)"' : ' style="color:var(--status-warn-fg)"';
    h += '<div class="sd-sq"><span class="q" title="' + sdEsc(r.q) + '">' + sdEsc(r.q) + '</span>'
       + '<span><span class="p"' + dir + '>' + (r.fav === '' ? '\u2014' : r.fav + '%') + '</span>'
       + ' <span class="t">6M ' + (r.t6m === '' ? '\u2014' : r.t6m + '%') + '</span></span></div>';
  });
  if (respN) h += '<div class="sd-legend" style="margin-top:7px">AVG RESPONSE RATE ' + Math.round(respSum / respN * 10) / 10 + '% \u00B7 FAVORABLE = 3-5 RATINGS</div>';
  box.innerHTML = h || '<div class="sd-legend">NO ROWS FOR THIS MONTH</div>';
}

function sdOpsRender(){
  var o = BOOT.ops;
  var day = o.opsToday ? 'TODAY' : (o.opsDate || '').substring(5).replace('-', '/');
  document.getElementById('sdOpsDate').textContent = o.opsToday ? 'TODAY' : 'LATEST: ' + day;
  document.getElementById('sdOps').innerHTML =
      '<div class="sd-vs"><span class="v">' + o.checkedin + ' / ' + o.scheduled + '</span><span class="f">CHECKED IN vs SCHEDULED</span></div>'
    + '<div class="sd-vs sd-mt"><span class="v">' + o.confTomorrow + '</span><span class="f">CONFIRMED FOR NEXT DAY</span></div>'
    + '<div class="sd-vs sd-mt"><span class="v">' + o.callouts + '</span><span class="f">CALL-OUTS ' + day + '</span></div>';
}

/* Trends: safety-by-week with range filter (client-side slice of 120 wks) */
function sdWkStartDate(y, w){
  var jan1 = new Date(+y, 0, 1);
  return new Date(+y, 0, 1 - jan1.getDay() + (w - 1) * 7);
}
function sdSafetyTrendRender(){
  var mode = document.getElementById('sdSafRange').value;
  var s = BOOT.trends.safety, now = new Date(), out;
  if (mode === 'wk') out = s.filter(function(e){ return e.y == BOOT.latest.y && e.w == BOOT.latest.w; });
  else if (mode === '6wk') out = s.slice(-6);
  else if (mode === '12wk') out = s.slice(-12);
  else if (mode === '24wk') out = s.slice(-24);
  else if (mode === 'cmonth' || mode === 'pmonth') {
    var m = now.getMonth(), yy = now.getFullYear();
    if (mode === 'pmonth') { m--; if (m < 0) { m = 11; yy--; } }
    out = s.filter(function(e){ var d = sdWkStartDate(e.y, e.w); return d.getFullYear() === yy && d.getMonth() === m; });
  }
  else if (mode === 'cyear') out = s.filter(function(e){ return +e.y === now.getFullYear(); });
  else out = s.filter(function(e){ return +e.y === now.getFullYear() - 1; });
  var yearMode = mode === 'cyear' || mode === 'pyear';
  sdBars('sdSafetyTrend',
    out.map(function(x){ return x.v === '' ? 0 : x.v; }),
    out.map(function(x){ return 'W' + x.w + (yearMode ? '' : ''); }));
  if (!out.length) document.getElementById('sdSafetyTrend').innerHTML = '<text x="20" y="40">No camera events in this range</text>';
}

/* card-level week change: refetch core, update just that card */
function sdCoreCard(which){
  var wk = sdWkOf(which === 'stand' ? 'wkStand' : which === 'kfa' ? 'wkKfa' : 'wkQual');
  sdAjax({ panel:'core', y: wk.y, w: wk.w }, function(c){
    if (!c) return;
    if (which === 'stand') sdStandRender(c);
    else if (which === 'kfa') sdKfaRender(c);
    else sdQualRender(c);
  });
}

/* Safety Event Mix: ALL TIME from bootstrap, single week via ajax */
function sdMixLoad(){
  var v = document.getElementById('sdMixWk').value;
  if (v === 'all') { sdHBars('sdSafetyMix', BOOT.trends.safetyMix); return; }
  var p = v.split('|');
  sdAjax({ panel:'safmix', y: p[0], w: p[1] }, function(mix){
    if (mix) sdHBars('sdSafetyMix', mix);
  });
}

/* ── LEAGUE ───────────────────────────────────────────────── */
var LG = { rows: [], page: 0, per: 12 };
function sdLeagueWeek(){
  var wk = sdWkOf('wkLeague');
  sdAjax({ panel:'league', y: wk.y, w: wk.w }, function(rows){
    if (rows) { LG.rows = rows; LG.page = 0; sdLeagueRender(); }
  });
}
function sdLeagueRender(){
  var flt = document.getElementById('lgStand').value;
  LG.view = LG.rows.filter(function(r){ return !flt || r.st === flt; });
  LG.page = 0;
  sdLgFitRender();
}
function sdLgFitRender(){
  var stageTop = document.querySelector('#sdv2 .sd-card').getBoundingClientRect().top;
  var avail = window.innerHeight - stageTop - 132; /* header bar + thead + foot */
  LG.per = Math.max(6, Math.floor(avail / 33));
  var v = LG.view || [];
  var maxP = Math.max(0, Math.ceil(v.length / LG.per) - 1);
  if (LG.page > maxP) LG.page = maxP;
  var start = LG.page * LG.per, slice = v.slice(start, start + LG.per);
  var h = '';
  slice.forEach(function(r, i){
    var cls = STAND_CLS[r.st] || 'great';
    h += '<tr onclick="sdOpenProfile(' + JSON.stringify(String(r.da)).replace(/"/g, '&quot;') + ')">'
      + '<td class="rk">' + (start + i + 1) + '</td>'
      + '<td class="nm" title="' + sdEsc(r.da) + '">' + sdEsc(r.da) + '</td>'
      + '<td><span class="sd-pill ' + cls + '"><span class="d"></span>' + sdEsc(r.st || '\u2014') + '</span></td>'
      + '<td><span class="sd-scorebar"><span class="tr"><span class="fl" style="width:' + Math.max(0, Math.min(100, +r.sc || 0)) + '%"></span></span><span class="num">' + (r.sc === '' ? '\u2014' : r.sc) + '</span></span></td>'
      + '<td class="num">' + (r.dcr === '' ? '\u2014' : r.dcr) + '</td>'
      + '<td class="num">' + (r.pod === '' ? '\u2014' : r.pod) + '</td>'
      + '<td class="dim">' + (r.dnr === '' ? '\u2014' : r.dnr) + '</td>'
      + '<td class="dim">' + (r.dsb === '' ? '\u2014' : r.dsb) + '</td>'
      + '<td class="dim">' + (r.cdf === '' ? '\u2014' : r.cdf) + '</td>'
      + '<td class="num">' + (r.pkgs === '' ? '\u2014' : r.pkgs) + '</td>'
      + '<td class="num"' + ((+r.sev) >= 3 ? ' style="color:var(--status-action-fg);font-weight:700"' : '') + '>' + r.sev + '</td>'
      + '<td onclick="event.stopPropagation()"><button type="button" class="sd-cotgl' + (r.coach == 1 ? ' on' : '')
      + '" title="' + (r.coach == 1 ? 'Coaching open - click to complete' : 'Start coaching') + '" '
      + 'onclick="sdCoachTgl(' + JSON.stringify(String(r.tid)).replace(/"/g, '&quot;') + ', ' + (r.coach == 1 ? 0 : 1) + ', this)"><span class="kn"></span></button></td></tr>';
  });
  if (!slice.length) h = '<tr><td colspan="12" style="text-align:center;color:#A6A9B1;padding:30px">No rows for this week / filter</td></tr>';
  document.getElementById('sdLgRows').innerHTML = h;
  document.getElementById('sdLgLabel').textContent = (v.length ? LG.page + 1 : 0) + ' / ' + (maxP + 1);
  document.getElementById('sdLgInfo').textContent = 'ROWS ' + (v.length ? start + 1 : 0) + '\u2013' + Math.min(v.length, start + LG.per) + ' OF ' + v.length;
  document.getElementById('sdLgPrev').disabled = LG.page === 0;
  document.getElementById('sdLgNext').disabled = LG.page >= maxP;
}
function sdLgPage(d){
  var v = LG.view || [], maxP = Math.max(0, Math.ceil(v.length / LG.per) - 1);
  LG.page = Math.min(maxP, Math.max(0, LG.page + d));
  sdLgFitRender();
}

/* Coach toggle: open/complete a coaching_log entry for the DA */
function sdCoachTgl(tid, on, btn){
  btn.disabled = true;
  sdRawAjax({ requestType:'coachToggle', tid: tid, on: on }, function(resp){
    btn.disabled = false;
    if (resp.indexOf('<status>true') >= 0) {
      btn.classList.toggle('on', on === 1);
      btn.setAttribute('onclick', 'sdCoachTgl(' + JSON.stringify(String(tid)).replace(/"/g, '&quot;') + ', ' + (on === 1 ? 0 : 1) + ', this)');
      LG.rows.forEach(function(r){ if (r.tid === tid) r.coach = on === 1 ? 1 : 0; });
      window.SD_COACH_STALE = true; /* coaching tab refetches on next open */
    }
  });
}
function sdRawAjax(params, cb){
  var body = new URLSearchParams();
  body.append('submitType', 10);
  body.append('controller', SD_CTRL);
  Object.keys(params).forEach(function(k){ body.append(k, params[k]); });
  ['entityID','loginUser','loginUserID','loginUserRoles','loginUserDisplayName'].forEach(function(k){
    var el = document.getElementById(k); if (el) body.append(k, el.value);
  });
  fetch('MVPGServlet', { method:'POST', headers:{'Content-Type':'application/x-www-form-urlencoded'}, body: body.toString() })
    .then(function(r){ return r.text(); }).then(cb).catch(function(){ cb(''); });
}

/* league row -> profile tab with that DA selected */
function sdOpenProfile(daName){
  var sel = document.getElementById('sdDaSel');
  var key = daName.toUpperCase().replace(/\s+/g, ' ').trim();
  for (var i = 0; i < sel.options.length; i++){
    if (sel.options[i].text.toUpperCase().replace(/\s+/g, ' ').trim() === key) { sel.selectedIndex = i; break; }
  }
  sdShow(4, document.querySelectorAll('#sdTabs button')[4]);
  sdProfileLoad();
}

/* ── COACHING ─────────────────────────────────────────────── */
var SD_CLOG = [];
function sdClFilter(btn){
  document.querySelectorAll('#sdClFilters .sc-mode').forEach(function(b){ b.classList.remove('on'); });
  btn.classList.add('on');
  sdClRender();
}
function sdClRender(){
  var flt = document.querySelector('#sdClFilters .sc-mode.on');
  var cat = flt ? flt.dataset.c : '';
  var h = '';
  SD_CLOG.forEach(function(e){
    if (cat && e.cat !== cat) return;
    var notes = '';
    (e.notes || []).forEach(function(nt){
      notes += '<div style="font-size:11.5px;padding:3px 0;border-top:1px dashed var(--border)">'
        + '<span style="font-family:var(--font-mono);font-size:9.5px;color:#A6A9B1">' + sdEsc(nt.d) + ' | ' + sdEsc(nt.u) + '</span><br>' + sdEsc(nt.m) + '</div>';
    });
    h += '<div class="sd-clog">'
      + '<div style="display:flex;align-items:center;gap:8px">'
      + '<span class="sd-clcat c' + e.cat + '">' + sdEsc(e.cat).toUpperCase() + '</span>'
      + '<b style="flex:1;min-width:0;overflow:hidden;text-overflow:ellipsis;white-space:nowrap">' + sdEsc(e.nm) + '</b>'
      + '<select class="sd-wksel" onchange="sdClCat(' + e.id + ', this.value)">'
      + ['Safety','Quality','Other'].map(function(cx){ return '<option' + (cx === e.cat ? ' selected' : '') + '>' + cx + '</option>'; }).join('')
      + '</select>'
      + '<span style="font-family:var(--font-mono);font-size:9.5px;color:#A6A9B1">' + sdEsc(e.dt) + '</span>'
      + '<button class="btn2 sm" onclick="sdClClose(' + e.id + ')">Complete</button>'
      + '</div>'
      + (e.rsn ? '<div style="font-size:11px;color:var(--text-light);margin-top:2px">' + sdEsc(e.rsn) + '</div>' : '')
      + notes
      + '<div style="display:flex;gap:6px;margin-top:6px">'
      + '<input id="clNote' + e.id + '" placeholder="Log the conversation with the DA" style="flex:1;border:1px solid var(--border);border-radius:6px;padding:5px 8px;font:inherit;font-size:12px;background:#FAF9F5">'
      + '<button class="btn2 sm" onclick="sdClNote(' + e.id + ')">Add note</button>'
      + '</div></div>';
  });
  if (!h) h = '<div style="color:#A6A9B1;padding:18px;text-align:center">No open coaching' + (cat ? ' in ' + cat : '') + ' - flip the Coach toggle in DA Performance or start one from the queue below.</div>';
  document.getElementById('sdCoachLog').innerHTML = h;
}
function sdClCat(id, cat){
  sdRawAjax({ requestType:'coachCat', logID: id, cat: cat }, function(){});
  SD_CLOG.forEach(function(e){ if (e.id === id) e.cat = cat; });
  sdClRender();
}
function sdClNote(id){
  var inp = document.getElementById('clNote' + id);
  if (!inp.value.trim()) return;
  sdRawAjax({ requestType:'coachNote', logID: id, note: inp.value.trim() }, function(resp){
    if (resp.indexOf('<status>true') >= 0) sdCoachWeek();
  });
}
function sdClClose(id){
  sdRawAjax({ requestType:'coachClose', logID: id }, function(resp){
    if (resp.indexOf('<status>true') >= 0) { sdCoachWeek(); if (LG.rows.length) sdLeagueWeek(); }
  });
}
function sdClStart(tid, cat, reason){
  sdRawAjax({ requestType:'coachStart', tid: tid, cat: cat, reason: reason }, function(resp){
    if (resp.indexOf('<status>true') >= 0) { sdCoachWeek(); if (LG.rows.length) sdLeagueWeek(); }
  });
}
function sdCoachRender(c){
  SD_CLOG = c.log || [];
  sdClRender();
  var h = '';
  var qSeq = 0;
  c.queue.forEach(function(qr){ var qi = qSeq++;
    var why = [];
    if (+qr.ev >= 3) why.push(qr.ev + ' camera events this week');
    if (qr.kfa) why.push('KFA: ' + qr.kfa);
    if (qr.st === 'Fair' || qr.st === 'Poor') why.push('standing ' + qr.st);
    h += '<div class="sd-coach"><div class="who"><div class="n" title="' + sdEsc(qr.da) + '">' + sdEsc(qr.da) + '</div>'
      + '<div class="t">' + sdEsc((qr.tid || '').substring(0, 14)) + ' \u00B7 ' + sdEsc((qr.st || '\u2014').toUpperCase()) + '</div></div>'
      + '<div class="why">' + sdEsc(why.join(' \u00B7 ')) + '</div>'
      + '<select class="sd-wksel" id="qCat' + qi + '">'
      + ['Safety','Quality','Other'].map(function(cx){ return '<option' + (cx === ((+qr.ev >= 3) ? 'Safety' : (qr.kfa ? 'Quality' : 'Other')) ? ' selected' : '') + '>' + cx + '</option>'; }).join('')
      + '</select> '
      + '<button class="btn2 sm" onclick="sdClStart(' + JSON.stringify(String(qr.tid)).replace(/"/g, '&quot;') + ', document.getElementById(\'qCat' + qi + '\').value, \'Queue suggestion\')">Start</button> '
      + '<button class="btn2 sm" onclick="sdCoachProfile(' + JSON.stringify(String(qr.da)).replace(/"/g, '&quot;') + ')">Open DA</button></div>';
  });
  if (!c.queue.length) h = '<div style="color:#A6A9B1;padding:20px;text-align:center">Queue is clear for this week</div>';
  document.getElementById('sdQueue').innerHTML = h;

  sdBars('sdCoachBars', c.coachWk.map(function(x){ return { q: x.q, s: x.s }; }), c.coachWk.map(function(x){ return 'W' + x.w; }));
  sdBars('sdWriteupBars', c.writeupWk.map(function(x){ return { q: x.s, s: x.o }; }), c.writeupWk.map(function(x){ return 'W' + x.w; }));

  var wc = '';
  c.writeupCats.forEach(function(x){
    wc += '<span class="sd-cat' + (x.n === 'SAFETY' ? ' saf' : '') + '">' + sdEsc(x.n) + ' \u00B7 ' + x.c + '</span>';
  });
  document.getElementById('sdWriteupCats').innerHTML = wc;

  var es = '';
  c.escal.forEach(function(x){
    es += '<div class="sd-ev"><span class="d8">WK' + (x.wk === '' ? '?' : x.wk) + '</span>'
      + '<span class="ty">' + sdEsc(x.cat) + '</span><span class="meta">' + sdEsc(x.da) + ' \u00B7 bucket ' + sdEsc(x.bkt) + '</span>'
      + '<span class="sd-fstat ' + (String(x.ap).toUpperCase().indexOf('Y') === 0 ? 'done' : 'open') + '">'
      + (String(x.ap).toUpperCase().indexOf('Y') === 0 ? 'APPEALED' : 'NO APPEAL') + '</span></div>';
  });
  if (!c.escal.length) es = '<div style="color:#A6A9B1;padding:14px;text-align:center">None on record</div>';
  document.getElementById('sdEscal').innerHTML = es;
}
function sdCoachWeek(){
  var wk = sdWkOf('wkCoach');
  sdAjax({ panel:'coach', y: wk.y, w: wk.w }, function(c){ if (c) sdCoachRender(c); });
}
function sdCoachProfile(daName){ sdOpenProfile(daName); }

/* ── PROFILE ──────────────────────────────────────────────── */
function sdDaysRender(p){
    /* trips + Flex app table */
    var dh = '';
    function mono(v, right){ return '<td style="font-family:var(--font-mono);font-size:11.5px;white-space:nowrap' + (right ? ';text-align:right' : '') + '">' + v + '</td>'; }
    if (p.days.length) {
      dh = '<table style="width:100%;border-collapse:collapse">'
        + '<tr><td class="sd-h6" style="text-align:left">DAY</td><td class="sd-h6" style="text-align:left">ROUTE</td>'
        + '<td class="sd-h6">STOPS</td><td class="sd-h6">PKGS</td><td class="sd-h6">CLOCK IN</td><td class="sd-h6">CLOCK OUT</td>'
        + '<td class="sd-h6">BREAK</td><td class="sd-h6">PACE</td><td class="sd-h6" style="text-align:right">HOURS</td></tr>';
      p.days.forEach(function(x){
        dh += '<tr class="sd-daysrow">'
          + mono(sdEsc(x.d)) + mono(sdEsc(x.rt))
          + '<td style="text-align:center">' + sdEsc(x.stops) + '</td>'
          + '<td style="text-align:center;font-family:var(--font-mono);font-size:11.5px">' + (x.pkgs === '' ? '\u2014' : x.pkgs) + '</td>'
          + '<td style="text-align:center;font-family:var(--font-mono);font-size:11.5px">' + (x.ci || '\u2014') + '</td>'
          + '<td style="text-align:center;font-family:var(--font-mono);font-size:11.5px">' + (x.co || '\u2014') + '</td>'
          + '<td style="text-align:center;font-family:var(--font-mono);font-size:11.5px">' + (x.brk === '' ? '\u2014' : x.brk + 'm') + '</td>'
          + '<td style="text-align:center;font-family:var(--font-mono);font-size:11.5px">' + (x.pace === '' ? '\u2014' : x.pace + '/hr') + '</td>'
          + mono(x.hrs === '' ? '\u2014' : '<b>' + x.hrs + '</b>', true)
          + '</tr>';
      });
      dh += '</table>';
      document.getElementById('sdWkHrs').textContent = (p.wkHours !== '' && +p.wkHours > 0)
        ? 'TOTAL ' + p.wkHours + ' HR THIS WEEK' : '';
    } else {
      dh = '<div style="color:#A6A9B1;padding:12px;text-align:center">No routes on file for this week</div>';
      document.getElementById('sdWkHrs').textContent = '';
    }
    document.getElementById('sdDays').innerHTML = dh;
}

/* trips card week dropdown: refetch, repaint only the trips table */
function sdTripsLoad(){
  var empID = document.getElementById('sdDaSel').value;
  if (!empID) return;
  var wk = sdWkOf('wkTrips');
  sdAjax({ panel:'profile', employeeID: empID, y: wk.y, w: wk.w }, function(p){
    if (p) sdDaysRender(p);
  });
}

function sdProfileLoad(){
  var empID = document.getElementById('sdDaSel').value;
  if (!empID) return;
  var wk = sdWkOf('wkProf');
  /* trips card follows the profile week until its own dropdown changes */
  var wt = document.getElementById('wkTrips');
  if (wt) wt.value = document.getElementById('wkProf').value;
  var aw = document.getElementById('actRange') ? document.getElementById('actRange').value : '6';
  var vw = document.getElementById('vehRange') ? document.getElementById('vehRange').value : '1';
  document.getElementById('sdAct').innerHTML = '<div style="color:#A6A9B1;padding:14px">Loading\u2026</div>';
  sdAjax({ panel:'profile', employeeID: empID, y: wk.y, w: wk.w, aw: aw, vw: vw }, function(p){
    if (!p) return;
    var badge = document.getElementById('sdProfBadge');
    badge.innerHTML = p.st ? '<span class="sd-pill ' + (STAND_CLS[p.st] || 'great') + '"><span class="d"></span>' + sdEsc(p.st) + ' \u00B7 WK' + p.w + '</span>'
                           : '<span class="sd-pill great"><span class="d"></span>Not on WK' + p.w + ' scorecard</span>';
    var meta = [];
    if (p.tid) meta.push(p.tid);
    if (p.posn) meta.push(p.posn.toUpperCase());
    if (p.statn) meta.push(p.statn);
    if (p.kfa) meta.push('KFA: ' + p.kfa.toUpperCase());
    document.getElementById('sdProfKfa').textContent = meta.join('  |  ');

    /* per-metric tier grids */
    function tierGrid(target, group){
      var g = '';
      p.metrics.forEach(function(m){
        if (m.g !== group) return;
        g += '<div class="m"><div class="n" title="' + sdEsc(m.n) + '">' + sdEsc(m.n) + '</div>'
          + '<div class="v">' + (m.v === '' || m.v == null ? 'No Data' : m.v) + '</div>'
          + (m.t ? '<span class="sd-pill ' + sdTierCls(m.t) + '"><span class="d"></span>' + sdEsc(m.t) + '</span>' : '<span class="sd-pill great"><span class="d"></span>No Tier</span>')
          + '</div>';
      });
      document.getElementById(target).innerHTML = g;
    }
    tierGrid('sdTierSaf', 'SAFETY');
    tierGrid('sdTierQual', 'QUALITY');

    /* standing band trend */
    sdStandChart('sdStandLine', p.trend);

    sdDaysRender(p);
    var h = '';
    function kpi(l, v, s){ h += '<div class="sd-card sd-kpi"><div class="lbl">' + l + '</div><div class="num">' + (v === '' || v == null ? 'No Data' : v) + '</div><div class="sub">' + s + '</div></div>'; }
    var cur6 = p.act6.length ? p.act6[p.act6.length - 1] : { inc:0, co:0, resc:0, osha:0, term:0 };
    kpi('Rank', p.rank !== '' && p.rank != null ? '#' + p.rank + ' <span style="font-size:15px;color:var(--text-light)">of ' + p.rankOf + '</span>' : '',
        'score <b>' + (p.sc === '' ? 'No Data' : p.sc) + '</b> \u00B7 fleet <b>' + (p.flSc === '' ? 'No Data' : p.flSc) + '</b>');
    kpi('Packages', p.pkgs || p.qual.pkgs,
        'of <b>' + (p.stationPkgs === '' ? 'No Data' : Number(p.stationPkgs).toLocaleString()) + '</b> station total');
    kpi('Incidents', cur6.inc, 'this week, all types');
    kpi('Call-outs', cur6.co, 'this week');
    kpi('Rescues', cur6.resc, 'this week');
    kpi('Vehicles', p.vehicles.length, vw === '1' ? 'driven this week' : 'driven, last ' + vw + ' wks');
    document.getElementById('sdProfKpis').innerHTML = h;

    /* 6-week activity trend table */
    var t6 = '<table style="width:100%;border-collapse:collapse">'
      + '<tr><td></td><td class="sd-h6">INC</td><td class="sd-h6">C/O</td><td class="sd-h6">RESC</td><td class="sd-h6">OSHA</td><td class="sd-h6">TERM</td></tr>';
    p.act6.forEach(function(x){
      function cell(v){ return '<td style="text-align:center;font-family:var(--font-mono);font-size:11.5px;' + (v > 0 ? 'color:var(--text);font-weight:600' : 'color:#A6A9B1') + '">' + v + '</td>'; }
      t6 += '<tr class="sd-daysrow"><td style="font-family:var(--font-mono);font-size:11px">WK ' + x.w + '</td>'
         + cell(x.inc) + cell(x.co) + cell(x.resc) + cell(x.osha) + cell(x.term) + '</tr>';
    });
    t6 += '</table>';
    document.getElementById('sdAct6').innerHTML = t6;

    /* vehicles driven */
    var vh = '';
    if (p.vehicles.length) {
      vh = '<table style="width:100%;border-collapse:collapse"><tbody>';
      p.vehicles.forEach(function(x){
        vh += '<tr class="sd-daysrow"><td style="font-family:var(--font-mono);font-size:11.5px;font-weight:600;color:var(--text)">' + sdEsc(x.v) + '</td>'
           + '<td style="text-align:center">' + x.days + ' day' + (x.days == 1 ? '' : 's') + '</td>'
           + '<td style="text-align:right;font-family:var(--font-mono);font-size:11px;color:var(--text-light)">last ' + sdEsc(x.last) + '</td></tr>';
      });
      vh += '</tbody></table>';
    } else {
      vh = '<div style="color:#A6A9B1;padding:12px;text-align:center">No check-ins in this range</div>';
    }
    document.getElementById('sdVeh').innerHTML = vh;

    sdLine('sdDaLine',
      [{ pts: p.trend.map(function(t){ return t.me === '' ? null : t.me; }), name: p.nm },
       { pts: p.trend.map(function(t){ return t.fl === '' ? null : t.fl; }), name: 'fleet', dash: true }],
      p.trend.map(function(t){ return 'W' + t.w; }),
      function(v){ return v.toFixed(0); });
    document.getElementById('sdDaLegend').textContent = p.nm;

    var a = '';
    p.act.forEach(function(x){
      a += '<div class="sd-ev"><span class="sd-cat' + (x.cat === 'TERMINATION' || x.cat === 'OSHA' ? ' saf' : '') + '">' + sdEsc(x.cat) + '</span>'
        + '<span class="d8">' + sdEsc(x.d) + '</span><span class="ty" title="' + sdEsc(x.ty) + '">' + sdEsc(x.ty) + '</span>'
        + (x.m ? '<div class="desc">' + sdEsc(x.m) + '</div>' : '')
        + '</div>';
    });
    if (!p.act.length)
      a = '<div style="color:#A6A9B1;padding:16px;text-align:center">No incidents, OSHA entries or terminations for WK' + p.w + '</div>';
    document.getElementById('sdAct').innerHTML = a;
  });
}

/* ── DA SCORECARD tab ─────────────────────────────────────── */
function sdScMode(btn){
  document.querySelectorAll('.sc-mode').forEach(function(b){ b.classList.remove('on'); });
  btn.classList.add('on');
  sdScLoad();
}
function scHeat(v, zeroGood){
  if (v === '' || v == null) return 'n';
  return (+v === 0) === !!zeroGood ? 'g' : 'w';
}
function sdScLoad(){
  var empID = document.getElementById('sdScDa').value;
  if (!empID) return;
  var wk = sdWkOf('wkSc');
  var mode = document.querySelector('.sc-mode.on').dataset.m;
  document.getElementById('sdSc').innerHTML = '<div style="color:#A6A9B1;text-align:center;padding:22px">Loading\u2026</div>';
  sdAjax({ panel:'scorecard', employeeID: empID, y: wk.y, w: wk.w, mode: mode }, function(d){
    if (!d || !d.nm) { document.getElementById('sdSc').innerHTML = '<div style="color:#A6A9B1;text-align:center;padding:22px">No data</div>'; return; }
    var trail = d.mode === 'trail';
    var rangeLbl = trail ? ('WK ' + d.w0 + ' \u2013 WK ' + d.w + ' \u00B7 ' + d.y)
                         : ('WK ' + d.w + ' (' + sdWkRange(d.y, d.w) + ') ' + d.y);
    function row(l, sub, v, cls){
      return '<div class="sc-row"><span class="l">' + l + (sub ? '<small>' + sub + '</small>' : '') + '</span>'
        + '<span class="v ' + cls + '">' + (v === '' || v == null ? 'No Data' : v) + '</span></div>';
    }
    function tierPill(t){
      return t ? '<span class="tier sd-pill ' + sdTierCls(t) + '"><span class="d"></span>' + sdEsc(t) + '</span>' : '';
    }
    var h = '<div class="sc-hero"><span class="lbl">' + sdEsc(d.nm).toUpperCase() + ' \u00B7 ' + rangeLbl + '</span>'
      + '<div class="n">' + (d.del === '' ? 'No Data' : Number(d.del).toLocaleString()) + '</div>'
      + '<span class="lbl">DELIVERIES' + (trail ? ' \u00B7 ' + d.wks + ' WKS ON SCORECARD' : '') + '</span></div>';
    h += '<div class="sc-tiles">'
      + '<div class="sc-tile tier"><div class="big">' + sdEsc(d.tier || 'No Data') + '</div><div class="lb">OVERALL TIER</div></div>'
      + '<div class="sc-tile"><div class="big">' + (d.rank !== '' ? '#' + d.rank + ' <small>of ' + d.rankOf + '</small>' : (trail ? 'Trailing' : 'No Data')) + '</div><div class="lb">' + (trail ? 'RANK IS PER-WEEK' : 'RANK THIS WEEK') + '</div></div>'
      + '</div>';

    h += '<div class="sc-card"><h4>Driving Safety ' + tierPill(d.tier) + '</h4><div class="sc-rows">';
    d.safety.forEach(function(m){
      h += row(m.n, m.t ? 'TIER: ' + m.t.toUpperCase() : 'EVENTS PER TRIP', m.v, scHeat(m.v, true));
    });
    h += row('Safety incidents', 'LOGGED BY DISPATCH' + (trail ? ' \u00B7 6 WKS' : ''), d.safInc, scHeat(d.safInc, true));
    h += '</div></div>';

    h += '<div class="sc-card"><h4>Delivery Quality ' + tierPill(d.qualTier) + '</h4><div class="sc-rows">'
      + row('Delivery Completion', 'DCR', d.qual.dcr === '' ? '' : d.qual.dcr + '%', d.qual.dcr === '' ? 'n' : (+d.qual.dcr >= 99 ? 'g' : 'w'))
      + row('Delivered, Not Received', 'DNR', d.qual.dnr === '' ? '' : d.qual.dnr + (d.qual.qdel !== '' ? ' / ' + d.qual.qdel : ''), scHeat(d.qual.dnr, true))
      + row('Photo-On-Delivery', 'POD', d.qual.pod === '' ? '' : d.qual.pod + '%', d.qual.pod === '' ? 'n' : (+d.qual.pod >= 97 ? 'g' : 'w'))
      + row('Delivery Success Behaviors', 'DSB', d.qual.dsb, scHeat(d.qual.dsb, true))
      + row('Returned to station', 'PACKAGES', d.qual.rts, scHeat(d.qual.rts, true));
    var rx = d.rtsMix || {ret:'', resc:'', rs:[]};
    for (var ri = 0; ri < rx.rs.length; ri++)
      h += row(rx.rs[ri].n, 'RTS REASON', rx.rs[ri].c, 'w');
    h += '</div>'
      + (d.qual.dcr === '' ? '<div class="sc-note">QUALITY UPLOAD NOT ON FILE FOR THIS RANGE</div>' : '')
      + '</div>';

    h += '<div class="sc-card"><h4>Customer Feedback ' + tierPill(d.cdfTier) + '</h4><div class="sc-rows">'
      + row('CDF defects', 'CUSTOMER DELIVERY FEEDBACK', d.cdf, scHeat(d.cdf, true))
      + row('Escalation defects', 'CED', d.ced, scHeat(d.ced, true));
    var cd = d.cdfDet || {tot:'', cats:[], cmts:[]};
    if (+cd.tot > 0) {
      for (var ci = 0; ci < cd.cats.length; ci++)
        if (+cd.cats[ci].c > 0)
          h += row(cd.cats[ci].n, 'NEGATIVE FEEDBACK', cd.cats[ci].c, 'w');
      h += '</div>';
      for (var mi = 0; mi < cd.cmts.length; mi++)
        h += '<div class="sc-note">' + cd.cmts[mi].d + ' &middot; &ldquo;' + cd.cmts[mi].m + '&rdquo;</div>';
      h += '</div>';
    } else {
      h += '</div><div class="sc-note">' + (+cd.up === 1
        ? 'NO NEGATIVE CUSTOMER FEEDBACK ' + (trail ? 'IN THIS RANGE' : 'THIS WEEK')
        : 'CDF DETAIL UPLOAD NOT ON FILE FOR THIS RANGE') + '</div></div>';
    }

    h += '<div class="sc-card"><h4>Incidents'
      + '<span class="tier sd-pill ' + (+d.inc.tot > 0 ? 'fair' : 'fan') + '"><span class="d"></span>' + d.inc.tot + (trail ? ' in 6 wks' : ' this week') + '</span></h4><div class="sc-rows">'
      + row('Total incidents', 'LOGGED BY DISPATCH', d.inc.tot, scHeat(d.inc.tot, true))
      + row('Call-outs', '', d.inc.co, scHeat(d.inc.co, true))
      + row('Rescues needed', 'SOMEONE TOOK STOPS FROM THE ROUTE', d.inc.resc, scHeat(d.inc.resc, true))
      + row('Write-ups', 'SIGNED FORMS', d.inc.wu, scHeat(d.inc.wu, true))
      + row('Late arrivals', '', d.inc.late, scHeat(d.inc.late, true))
      + '</div></div>';

    h += '<div class="sc-card"><h4>Vehicle Inspections'
      + '<span class="tier sd-pill ' + (d.dvicRushed > 0 ? 'fair' : 'fan') + '"><span class="d"></span>' + d.dvicRushed + ' rushed</span></h4><div class="sc-rows">';
    if (d.dvic.length) {
      d.dvic.forEach(function(x){
        var mm = Math.floor(x.dur / 60), ss = ('0' + (x.dur % 60)).slice(-2);
        h += row(x.d + ' \u00B7 ' + sdEsc(x.ty), x.st, x.dur ? mm + ':' + ss : '', x.rush ? 'b' : 'g');
      });
    } else {
      h += '<div class="sc-row"><span class="l" style="color:#A6A9B1">No inspections on file for this range</span></div>';
    }
    h += '</div><div class="sc-note">UNDER 90 SECONDS COUNTS AS RUSHED</div></div>';

    h += '<div class="sc-card"><h4>My Week \u00B7 Flex App</h4><div class="sc-rows">'
      + row('Hours on road', '', d.flex.hrs, 'n')
      + row('Routes', '', d.flex.routes, 'n')
      + row('Average pace', 'STOPS PER HOUR', d.flex.pace, 'n')
      + row('Breaks', 'TOTAL MINUTES', d.flex.brk !== '' && d.flex.brk != null && +d.flex.brk > 0
            ? (Math.floor(d.flex.brk / 60) > 0 ? Math.floor(d.flex.brk / 60) + 'h ' + (d.flex.brk % 60) + 'm' : d.flex.brk + 'm')
            : (d.flex.hrs !== '' ? '0m' : ''), 'n')
      + row('Stops completed', '', d.flex.cs !== '' ? d.flex.cs + ' / ' + d.flex.st : '', 'n')
      + '</div></div>';

    if (d.kfa)
      h += '<div class="sc-focus"><h5>FOCUS AREA</h5><div class="kfa">' + sdEsc(d.kfa) + '</div></div>';

    document.getElementById('sdSc').innerHTML = h;
  });
}

/* ── boot ─────────────────────────────────────────────────── */
(function(){
  if (BOOT.empty) {
    document.getElementById('sdv0').innerHTML = '<div class="sd-card" style="text-align:center;color:#A6A9B1;padding:40px">No scorecard data uploaded yet.</div>';
    return;
  }
  var y = BOOT.latest.y, w = BOOT.latest.w;
  ['wkStand','wkKfa','wkQual','wkLeague','wkCoach','wkProf','wkTrips'].forEach(function(s){ sdWkOptions(s, y, w); });

  sdKpisRender(BOOT.core);
  sdStandRender(BOOT.core);
  sdKfaRender(BOOT.core);
  sdQualRender(BOOT.core);
  sdDaSurveyInit(BOOT.core.survey);
  sdOpsRender();
  var saf6 = BOOT.trends.safety.slice(-6);
  sdBars('sdSafetyWk', saf6.map(function(x){ return x.v; }), saf6.map(function(x){ return 'W' + x.w; }));
  sdSafetyTrendRender();

  /* Safety Event Mix week options: recent 14 weeks from the safety series */
  var mixSel = document.getElementById('sdMixWk');
  BOOT.trends.safety.slice(-14).reverse().forEach(function(x){
    var o = document.createElement('option');
    o.value = x.y + '|' + x.w; o.textContent = 'WK ' + x.w + ' ' + x.y;
    mixSel.appendChild(o);
  });

  sdBars('sdPkgBars', BOOT.trends.score.map(function(x){ return x.p === '' ? 0 : x.p; }), BOOT.trends.score.map(function(x){ return 'W' + x.w; }));
  sdLine('sdRescLine', [{ pts: BOOT.trends.inc.map(function(x){ return x.r; }), name: 'rescues' }],
    BOOT.trends.inc.map(function(x){ return 'W' + x.w; }));
  sdLine('sdAttLine',
    [{ pts: BOOT.trends.inc.map(function(x){ return x.c; }), name: 'call-outs' },
     { pts: BOOT.trends.inc.map(function(x){ return x.l; }), name: 'lates', dash: true }],
    BOOT.trends.inc.map(function(x){ return 'W' + x.w; }));
  sdHBars('sdSafetyMix', BOOT.trends.safetyMix);

  LG.rows = BOOT.league; LG.view = BOOT.league;
  sdCoachRender(BOOT.coach);

  var sel = document.getElementById('sdDaSel');
  var scSel = document.getElementById('sdScDa');
  BOOT.employees.forEach(function(e){
    var o = document.createElement('option');
    o.value = e.id; o.textContent = e.nm;
    sel.appendChild(o);
    var o2 = document.createElement('option');
    o2.value = e.id; o2.textContent = e.nm;
    scSel.appendChild(o2);
  });
  sdWkOptions('wkSc', y, w);

  window.addEventListener('resize', function(){ if (document.getElementById('sdv2').classList.contains('on')) sdLgFitRender(); });
})();
</script>

<%@ include file="includeFooter.jsp"%>
