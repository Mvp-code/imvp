<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
String _loginUser = request.getAttribute("loginUser") == null ? "" : request.getAttribute("loginUser").toString().trim();
String _loginUserDisplayName = request.getAttribute("loginUserDisplayName") == null ? "" : request.getAttribute("loginUserDisplayName").toString().trim();
String _loginUserID = request.getAttribute("loginUserID") == null ? "" : request.getAttribute("loginUserID").toString().trim();
String _loginUserRoles = request.getAttribute("loginUserRoles") == null ? "" : request.getAttribute("loginUserRoles").toString().trim();
String _entityID = request.getAttribute("entityID") == null ? "" : request.getAttribute("entityID").toString().trim();
if (session != null) {
	if (_loginUser.length() == 0 && session.getAttribute("loginUser") != null)
		_loginUser = session.getAttribute("loginUser").toString().trim();
	if (_loginUserDisplayName.length() == 0 && session.getAttribute("loginUserDisplayName") != null)
		_loginUserDisplayName = session.getAttribute("loginUserDisplayName").toString().trim();
	if (_loginUserID.length() == 0 && session.getAttribute("loginUserID") != null)
		_loginUserID = session.getAttribute("loginUserID").toString().trim();
	if (_loginUserRoles.length() == 0 && session.getAttribute("loginUserRoles") != null)
		_loginUserRoles = session.getAttribute("loginUserRoles").toString().trim();
	if (_entityID.length() == 0 && session.getAttribute("entityID") != null)
		_entityID = session.getAttribute("entityID").toString().trim();
}
if (_loginUser.length() == 0) {
  if (!response.isCommitted())
    response.sendRedirect(request.getContextPath() + "/jsp/login.jsp");
  return;
}
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8" />
<meta name="viewport" content="width=device-width, initial-scale=1.0" />
<title>Predict Scorecard</title>
<link rel="stylesheet" type="text/css" href="../jsp/bootstrap/bootstrap.min.css">
<link rel="stylesheet" type="text/css" href="../jsp/bootstrap/all.min.css"/>
<!-- ═══ MVPG Foundation ═══ -->
<link rel="stylesheet" type="text/css" href="../jsp/bootstrap/mvpg-tokens.css">
<link rel="stylesheet" type="text/css" href="../jsp/bootstrap/mvpg-design-system.css">
<script src="../jsp/mvpg-toast.js"></script>
<script src="../jsp/mvpg-fetch.js"></script>
<style>
@import url("https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=DM+Sans:wght@400;500;600;700&family=Open+Sans:wght@400;600;700&family=Work+Sans:wght@400;500;600;700&display=swap");
body { margin:0; font-family:"Segoe UI", Tahoma, Geneva, Verdana, sans-serif; background:#f5f8ff; color:#0f172a; }
.wrap { max-width: 1900px; margin: 1rem auto 2rem; padding: 0 1rem; }
.toolbar { display:flex; gap:.5rem; flex-wrap:wrap; margin-top:.7rem; }
/* Weekly summary: row 1 = Week; row 2 = Quality block + Safety block (one row, side by side) */
.sc-summary-panel {
	margin-top: .75rem;
	padding: .55rem .65rem .65rem;
	background: #fff;
	border: 1px solid #dbe3ef;
	border-radius: 12px;
	box-shadow: 0 5px 14px rgba(15,23,42,.06);
}
.sc-kpi-inner {
	font-size: .78rem;
	background: #fafbff;
	border: 1px solid #d8dee9;
	border-radius: 10px;
	box-sizing: border-box;
	padding: .42rem .55rem .48rem;
}
.sc-kpi-week-row {
	display: flex;
	flex-direction: row;
	flex-wrap: nowrap;
	align-items: center;
	gap: .45rem .55rem;
	width: 100%;
	min-width: 0;
	padding-bottom: .42rem;
	margin-bottom: .38rem;
	border-bottom: 1px solid #e2e8f0;
}
.sc-kpi-week-row .week-select.kpi-week-select {
	flex: 1 1 auto;
	min-width: 12rem;
	max-width: none;
	font-size: .78rem;
	font-weight: 700;
	padding: .3rem .45rem;
	line-height: 1.35;
	border-radius: 8px;
	border: 1px solid #cdd8ea;
	background: #fff;
	color: #0f172a;
	box-sizing: border-box;
}
.sc-kpi-metrics-row {
	display: flex;
	flex-direction: row;
	flex-wrap: nowrap;
	align-items: stretch;
	gap: .55rem .65rem;
	width: 100%;
	min-width: 0;
	overflow-x: auto;
	overflow-y: hidden;
	-webkit-overflow-scrolling: touch;
}
.sc-kpi-metrics-row::-webkit-scrollbar { height: 5px; }
.sc-kpi-metrics-row::-webkit-scrollbar-thumb { background: #cbd5e1; border-radius: 4px; }
.sc-kpi-block {
	display: flex;
	flex-direction: row;
	flex-wrap: nowrap;
	align-items: center;
	gap: .35rem .45rem;
	flex: 1 1 0;
	min-width: 0;
	padding: .38rem .45rem;
	border-radius: 10px;
	border: 1px solid #e2e8f0;
	box-sizing: border-box;
}
.sc-kpi-block--quality {
	background: #f0fdf4;
	border-color: #bbf7d0;
}
.sc-kpi-block--safety {
	background: #eff6ff;
	border-color: #bfdbfe;
}
.sc-kpi-sect {
	flex: 0 0 auto;
	font-size: .74rem;
	font-weight: 800;
	color: #1e3a8a;
	white-space: nowrap;
	line-height: 1.25;
}
.sc-kpi-sect--week label {
	margin: 0;
	cursor: pointer;
	font: inherit;
	font-weight: inherit;
	color: inherit;
}
.sc-mg-cell {
	flex: 0 0 auto;
	display: inline-flex;
	flex-direction: row;
	flex-wrap: nowrap;
	align-items: baseline;
	gap: .22rem .3rem;
	background: #fff;
	min-width: 0;
	padding: .28rem .38rem;
	border: 1px solid #e8ecf4;
	border-radius: 8px;
	box-sizing: border-box;
	white-space: nowrap;
}
.sc-mg-cell .sc-mg-lbl {
	display: inline;
	font-size: .58rem;
	font-weight: 700;
	color: #64748b;
	line-height: 1.2;
	margin-bottom: 0;
	text-transform: none;
}
.sc-mg-cell .sc-mg-lbl::after {
	content: ":";
	margin-left: .06rem;
	color: #94a3b8;
	font-weight: 600;
}
.sc-mg-cell .sc-mg-val {
	font-size: .84rem;
	font-weight: 800;
	color: #0f172a;
	line-height: 1.2;
	flex-shrink: 0;
}
.sc-summary-panel--prev .sc-kpi-week-row .prev-week-token-readout {
	flex: 1 1 auto;
	min-width: 12rem;
	display: block;
	box-sizing: border-box;
	font-size: .78rem;
	font-weight: 700;
	color: #0f172a;
	padding: .3rem .45rem;
	border: 1px solid #cdd8ea;
	border-radius: 8px;
	background: #fff;
	white-space: nowrap;
}
.sc-summary-panel--prev { margin-top: .35rem; }
.sc-summary-panel--prev .sc-kpi-inner { background: #f1f5f9; }
.sc-summary-panel--prev .sc-kpi-block--quality { background: #ecfdf5; }
.sc-summary-panel--prev .sc-kpi-block--safety { background: #f0f9ff; }
.sc-summary-panel--prev .sc-mg-cell { background: rgba(255,255,255,.85); }
.page-hero__actions .btn-scorecard-back {
	color: #0f172a;
	background: #e2e8f0;
	border: 1px solid #94a3b8;
	font-weight: 600;
}
.page-hero__actions .btn-scorecard-back:hover {
	background: #cbd5e1;
	border-color: #64748b;
	color: #0f172a;
}
.panel { margin-top:.85rem; background:#fff; border:1px solid #dbe3ef; border-radius:14px; padding:.75rem; box-shadow:0 8px 20px rgba(15,23,42,.08); }
.panel h5 { margin: 0 0 .5rem; font-size: .95rem; }
.table-responsive { max-height: 70vh; overflow-x: visible; overflow-y: auto; border: 1px solid #dbe3ef; border-radius: 10px; }
.table-fit { width:100%; table-layout:fixed; margin-bottom:0; }
.table-fit thead { position:sticky; top:0; z-index:5; background:#4472C4; }
.table-fit thead th { position:static; background:#4472C4; color:#fff; font-size:.52rem; font-weight:700; text-transform:none; border:1px solid #3465a4; vertical-align:middle; white-space:normal; line-height:1.1; padding:.18rem .1rem; }
.table-fit tbody td { border:1px solid #d0d7e2; vertical-align:middle; font-size:.58rem; padding:.12rem .08rem; }
.table-fit tbody tr:nth-child(even) td { background:#f7f9fc; }
.table-fit tbody tr:nth-child(even) td.edit-col,
.table-fit tbody tr:nth-child(even) td.sc-entry-readonly { background:#fff2cc !important; }
.edit-col { background:#fff2cc !important; }
.sc-entry-readonly { background:#fff2cc !important; font-weight:600; color:#1a1a1a; }
.calc-col { background:#E2EFDA !important; }
.focus-col { background:#DDEBF7 !important; font-weight:700; }
.txt-input { width:100%; border:1px solid #bf9000; border-radius:4px; padding:.12rem .08rem; font-size:.58rem; text-align:right; background:#fff2cc !important; color:#1a1a1a; box-sizing:border-box; }
.txt-input:focus { outline:none; border-color:#806000; box-shadow:0 0 0 1px rgba(191,144,0,.35); }
.readonly-cell { font-size:.58rem; font-weight:600; color:#1e3a8a; }
.table-fit .readonly-cell { font-size:.58rem; }
.small-note { font-size:.74rem; color:#64748b; margin-top:.45rem; }
.previous-title { display:flex; justify-content:space-between; align-items:center; gap:.5rem; margin-bottom:.5rem; }
.delta-up { color:#16a34a; font-weight:700; }
.delta-down { color:#dc2626; font-weight:700; }
.tier-good { color:#166534; background:#dcfce7 !important; font-weight:800; text-align:center; }
.tier-bad { color:var(--status-escalation-fg); background:var(--status-escalation-bg) !important; font-weight:800; text-align:center; }
.table-fit tbody td.tier-good { background:#dcfce7 !important; }
.table-fit tbody td.tier-bad { background:var(--status-escalation-bg) !important; }
.threshold-panel { margin-top:.8rem; background:#fff; border:1px solid #dbe3ef; border-radius:12px; padding:.75rem; box-shadow:0 6px 16px rgba(15,23,42,.06); }
.threshold-panel h6 { margin:0 0 .45rem; font-weight:800; color:#1e3a8a; }
.threshold-grid { display:grid; grid-template-columns: repeat(2, minmax(260px, 1fr)); gap:.45rem .8rem; font-size:.8rem; }
@media (max-width: 900px){ .threshold-grid { grid-template-columns: 1fr; } }
.threshold-grid b { color:#0f172a; }
.threshold-note { margin-top:.45rem; font-size:.76rem; color:#475569; }
.week-select { border:1px solid #cdd8ea; border-radius:8px; font-size:.85rem; font-weight:700; padding:.2rem .35rem; color:#0f172a; }
.tierbar-panel { margin-top:.8rem; background:#fff; border:1px solid #dbe3ef; border-radius:12px; padding:.65rem .75rem; box-shadow:0 6px 16px rgba(15,23,42,.06); }
.tierbar-title-row { display:flex; flex-direction:column; align-items:stretch; gap:.5rem; margin-bottom:.45rem; }
.tierbar-title-inline { font-size:.88rem; font-weight:800; color:#1e3a8a; line-height:1.3; width:100%; }
.tierbar-title-row .tierbar-wrap { width:100%; min-width:0; }
.tierbar-wrap { width:100%; border-radius:10px; overflow:hidden; border:1px solid #cbd5e1; background:#f1f5f9; }
.tierbar-stack { display:flex; width:100%; min-height:48px; align-items:stretch; }
.tierbar-seg { height:auto; min-height:48px; flex-shrink:0; min-width:0; transition:width .2s ease; box-sizing:border-box; border-right:1px solid rgba(255,255,255,.35); display:flex; align-items:center; justify-content:center; padding:2px; }
.tierbar-seg:last-child { border-right:none; }
.tierbar-seg-inner { display:flex; flex-direction:column; align-items:center; justify-content:center; text-align:center; line-height:1.1; max-width:100%; }
.tierbar-cat { font-size:.58rem; font-weight:700; color:#fff; text-shadow:0 1px 2px rgba(0,0,0,.45); opacity:.95; }
.tierbar-num { font-size:.78rem; font-weight:800; color:#fff; text-shadow:0 1px 2px rgba(0,0,0,.45); }
.tierbar-seg--remainder .tierbar-cat, .tierbar-seg--remainder .tierbar-num { color:#475569; text-shadow:none; }
.tierbar-seg-inner--narrow .tierbar-cat { display:none; }
.tierbar-seg-inner--narrow .tierbar-num { font-size:.65rem; }
/* Keep numbers visible when segment is narrow; only hide category label */
.tierbar-seg-inner--tiny { display:flex !important; flex-direction:column; align-items:center; justify-content:center; }
.tierbar-seg-inner--tiny .tierbar-cat { display:none !important; }
.tierbar-seg-inner--tiny .tierbar-num { font-size:.58rem; line-height:1.05; }
.tierbar-legend { font-size:.68rem; color:#64748b; margin-top:.35rem; line-height:1.3; }
.sc-trend-panel { background:#fff; border:1px solid #dbe3ef; border-radius:14px; padding:.75rem .85rem; box-shadow:0 8px 20px rgba(15,23,42,.08); }
.sc-chart-grid { display:grid; grid-template-columns:repeat(auto-fill,minmax(260px,1fr)); gap:.65rem; }
.sc-chart-card { border:1px solid #e2e8f0; border-radius:10px; padding:.45rem .5rem .55rem; background:#fafbff; }
.sc-chart-card .sc-chart-title { font-size:.72rem; font-weight:800; color:#1e3a8a; margin-bottom:.35rem; }
.sc-chart-bars { display:flex; align-items:flex-end; gap:3px; height:72px; padding:.35rem .25rem; background:#fff; border-radius:8px; border:1px solid #e8ecf4; }
.sc-chart-bars .bar { flex:1; min-width:5px; border-radius:3px 3px 1px 1px; background:linear-gradient(180deg,#93c5fd,#2563eb); position:relative; }
.sc-chart-bars .bar--hi { background:linear-gradient(180deg,#fca5a5,#dc2626); }
.sc-chart-meta { font-size:.62rem; color:#64748b; margin-top:.25rem; display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:.25rem; }
.sc-tr-improve { color:#059669; font-weight:700; }
.sc-tr-worse { color:#dc2626; font-weight:700; }
.sc-tr-same { color:#64748b; font-weight:600; }

/* Performance module redesign */
body { background: var(--mvpg-bg-canvas, #f4f6f8); }
.wrap { max-width: 1800px; }
.perf-toolbar {
	position: sticky; top: 8px; z-index: 20;
	display:flex; gap:8px; flex-wrap:wrap; align-items:center;
	background: rgba(255,255,255,.92);
	border:1px solid #dbe3ef; border-radius:12px; padding:8px 10px; margin-bottom:10px;
	backdrop-filter: blur(6px);
}
.perf-tabs { display:flex; gap:6px; flex-wrap:wrap; }
.perf-tab {
	border:1px solid #cbd5e1; background:#fff; border-radius:999px; padding:5px 11px;
	font-size:12px; font-weight:700; color:#334155; cursor:pointer;
}
.perf-tab.active { background:#ccfbf1; border-color:#5eead4; color:#0f766e; }
.perf-kpi-grid { display:grid; grid-template-columns:repeat(6,minmax(0,1fr)); gap:10px; margin-top:10px; }
@media(max-width:1200px){ .perf-kpi-grid { grid-template-columns:repeat(3,minmax(0,1fr)); } }
@media(max-width:760px){ .perf-kpi-grid { grid-template-columns:repeat(2,minmax(0,1fr)); } }
.perf-kpi-card {
	background:#fff; border:1px solid #e2e8f0; border-radius:10px; padding:10px 12px; box-shadow:0 1px 4px rgba(15,23,42,.05);
}
.perf-kpi-card .lbl { font-size:11px; font-weight:700; color:#64748b; text-transform:uppercase; letter-spacing:.04em; }
.perf-kpi-card .val { font-size:24px; line-height:1.1; font-weight:800; color:#0f172a; margin-top:4px; }
.perf-kpi-card .sub { font-size:11px; color:#64748b; margin-top:3px; }
.perf-kpi-card.score .val { color:#0f766e; }
.perf-section { margin-top:.85rem; }
.perf-section.hidden { display:none; }
.panel .panel-badge {
	display:inline-flex; align-items:center; gap:5px; margin-left:8px;
	border:1px solid #cbd5e1; background:#f8fafc; color:#475569; border-radius:999px; padding:2px 8px; font-size:11px; font-weight:700;
}
.section-note {
	font-size:12px; color:#64748b; margin-top:6px;
}

/* Match DA Confirmation type + true-neutral ink. Do not change flex/min-width. */
body, .wrap, .page-hero__title, .page-hero__sub, .perf-tab, .perf-kpi-card,
.table-fit, .txt-input, .week-select, button, input, select {
	font-family: 'Inter', 'DM Sans', 'Open Sans', 'Work Sans', 'Segoe UI', sans-serif;
	-webkit-font-smoothing: auto;
	-moz-osx-font-smoothing: auto;
	text-rendering: geometricPrecision;
}
body { color: #181818; }
h1.page-hero__title {
	font-size: 24px;
	font-weight: 700;
	letter-spacing: -.015em;
	color: #181818;
	line-height: 1.2;
}
.page-hero__sub { font-size: 13px; font-weight: 400; color: #444444; }
.perf-kpi-card .lbl {
	font-size: 13px;
	font-weight: 600;
	letter-spacing: 0;
	text-transform: none;
	color: #444444;
}
.perf-kpi-card .val,
.perf-kpi-card.score .val {
	font-size: 24px;
	font-weight: 700;
	letter-spacing: -.015em;
	color: #181818;
}
.perf-kpi-card .sub { font-size: 13px; color: #444444; }
.perf-tab { font-size: 13px; font-weight: 600; color: #444444; }
.perf-tab.active { color: #181818; }
.sc-kpi-inner { font-size: 13px; }
.sc-kpi-sect { font-size: 13px; font-weight: 600; color: #444444; }
.sc-kpi-week-row .week-select.kpi-week-select,
select.week-select {
	font-size: 13px;
	font-weight: 400;
	color: #181818;
}
.sc-mg-cell .sc-mg-lbl { font-size: 13px; font-weight: 600; color: #444444; }
.sc-mg-cell .sc-mg-val { font-size: 14px; font-weight: 700; color: #181818; }
.panel h5, .tierbar-title-inline, .threshold-panel h6, .sc-chart-card .sc-chart-title {
	font-size: 14px;
	font-weight: 700;
	color: #181818;
}
.table-fit thead th {
	font-size: 12px;
	font-weight: 700;
	letter-spacing: 0;
	color: #fff;
	padding: 8px 6px;
}
.table-fit tbody td,
.table-fit .readonly-cell,
.readonly-cell {
	font-size: 13px;
	color: #181818;
	padding: 6px 5px;
}
.txt-input {
	font-size: 13px;
	font-weight: 400;
	color: #181818;
	padding: 6px 5px;
}
.small-note, .tierbar-legend, .section-note, .sc-chart-meta, .threshold-note {
	font-size: 13px;
	color: #444444;
}
.tierbar-cat { font-size: 12px; font-weight: 600; }
.tierbar-num,
.tierbar-seg-inner--narrow .tierbar-num,
.tierbar-seg-inner--tiny .tierbar-num {
	font-size: 13px;
	font-weight: 700;
}
.panel-badge { font-size: 12px; color: #444444; }
</style>
</head>
<body>
<div class="wrap">
	<div class="page-hero">
		<div class="page-hero__text">
			<h1 class="page-hero__title">Predict Scorecard</h1>
			<p class="page-hero__sub">Weekly Entry, Trends, Comparison, and Coaching Triggers</p>
		</div>
		<div class="page-hero__actions">
			<button class="btn btn-sm btn-success" type="button" onclick="saveScorecard()"><i class="fa fa-save"></i> Save</button>
			<button class="btn btn-sm btn-warning" type="button" onclick="resetScorecard()"><i class="fa fa-refresh"></i> Reset</button>
			<button class="btn btn-sm btn-info" type="button" onclick="copyFromPreviousWeek()" title="Copy trip and scorecard inputs from the prior Sunday-Saturday week into this week"><i class="fa fa-copy"></i> Copy last week</button>
			<button class="btn btn-sm btn-primary" type="button" onclick="downloadCSV()"><i class="fa fa-download"></i> Export CSV</button>
		</div>
	</div>

	<div class="perf-toolbar">
		<div class="perf-tabs">
			<button type="button" class="perf-tab active" data-section="weekly" onclick="scShowSection('weekly', this)">Weekly Entry</button>
			<button type="button" class="perf-tab" data-section="trends" onclick="scShowSection('trends', this)">Trends</button>
			<button type="button" class="perf-tab" data-section="comparison" onclick="scShowSection('comparison', this)">Comparison</button>
			<button type="button" class="perf-tab" data-section="coaching" onclick="scShowSection('coaching', this)">Coaching Triggers</button>
		</div>
		<div class="section-note">Yellow cells are editable input; green/blue cells are calculated and read-only.</div>
	</div>

	<div class="perf-kpi-grid">
		<div class="perf-kpi-card score">
			<div class="lbl">Weighted Weekly Score</div>
			<div class="val" id="perfWeightedScore">0.00</div>
			<div class="sub">Tier <span id="perfTierTxt">Poor</span></div>
		</div>
		<div class="perf-kpi-card">
			<div class="lbl">Safety incidents</div>
			<div class="val" id="perfKpiSafetyIncidents">0</div>
			<div class="sub">Weekly total</div>
		</div>
		<div class="perf-kpi-card">
			<div class="lbl">Negative feedback</div>
			<div class="val" id="perfKpiNegFeedback">0</div>
			<div class="sub">Customer defects</div>
		</div>
		<div class="perf-kpi-card">
			<div class="lbl">DSB defects</div>
			<div class="val" id="perfKpiDsbDefects">0</div>
			<div class="sub">Delivery service breaches</div>
		</div>
		<div class="perf-kpi-card">
			<div class="lbl">Seatbelt</div>
			<div class="val" id="perfKpiSeatbeltSubtotal">0</div>
			<div class="sub">Event subtotal</div>
		</div>
		<div class="perf-kpi-card">
			<div class="lbl">Speeding</div>
			<div class="val" id="perfKpiSpeedingSubtotal">0</div>
			<div class="sub">Event subtotal</div>
		</div>
	</div>

	<div class="sc-summary-panel" id="kpiStripCurrent" title="Current week summary">
		<div class="sc-kpi-inner" role="group" aria-label="Weekly Quality and Safety summary">
			<div class="sc-kpi-week-row">
				<span class="sc-kpi-sect sc-kpi-sect--week"><label for="kpiWeekSelect">Week</label></span>
				<select id="kpiWeekSelect" class="week-select kpi-week-select" title="Scorecard week (Sun-Sat)" aria-label="Scorecard week"></select>
			</div>
			<div class="sc-kpi-metrics-row">
				<div class="sc-kpi-block sc-kpi-block--quality" aria-labelledby="kpiQualityHeading">
					<span class="sc-kpi-sect" id="kpiQualityHeading">Quality</span>
					<div class="sc-mg-cell">
						<span class="sc-mg-lbl">Total Negative Feedback</span>
						<strong class="sc-mg-val" id="kpiNegFeedback">0</strong>
					</div>
					<div class="sc-mg-cell">
						<span class="sc-mg-lbl">Total DSB Defects</span>
						<strong class="sc-mg-val" id="kpiDsbDefects">0</strong>
					</div>
				</div>
				<div class="sc-kpi-block sc-kpi-block--safety" aria-labelledby="kpiSafetyHeading">
					<span class="sc-kpi-sect" id="kpiSafetyHeading">Safety</span>
					<div class="sc-mg-cell">
						<span class="sc-mg-lbl">Total Safety Incidents</span>
						<strong class="sc-mg-val" id="kpiSafetyIncidents">0</strong>
					</div>
					<div class="sc-mg-cell">
						<span class="sc-mg-lbl">Seatbelt</span>
						<strong class="sc-mg-val" id="kpiSeatbeltSubtotal">0</strong>
					</div>
					<div class="sc-mg-cell">
						<span class="sc-mg-lbl">Speeding</span>
						<strong class="sc-mg-val" id="kpiSpeedingSubtotal">0</strong>
					</div>
					<div class="sc-mg-cell">
						<span class="sc-mg-lbl">Sign/Signal</span>
						<strong class="sc-mg-val" id="kpiSignSubtotal">0</strong>
					</div>
					<div class="sc-mg-cell">
						<span class="sc-mg-lbl">Distraction</span>
						<strong class="sc-mg-val" id="kpiDistractionSubtotal">0</strong>
					</div>
					<div class="sc-mg-cell">
						<span class="sc-mg-lbl">Following Dist.</span>
						<strong class="sc-mg-val" id="kpiFollowingSubtotal">0</strong>
					</div>
				</div>
			</div>
		</div>
	</div>

	<div class="tierbar-panel perf-section" id="weightedPanel">
		<div class="tierbar-title-row">
			<div id="tierBarTitle" class="tierbar-title-inline">Weighted Score Card - Poor (0.00/100)</div>
			<div class="tierbar-wrap">
			<div class="tierbar-stack" id="tierBarStack" title="Stacked by category (width = points out of 100)">
				<div id="segSafety" class="tierbar-seg" style="width:0%; background:#2563eb;" title="Safety">
					<span id="innerSafety" class="tierbar-seg-inner"><span class="tierbar-cat">Safety</span><span class="tierbar-num" id="numSafetyBar">0.00/47.50</span></span>
				</div>
				<div id="segQuality" class="tierbar-seg" style="width:0%; background:#16a34a;" title="Quality">
					<span id="innerQuality" class="tierbar-seg-inner"><span class="tierbar-cat">Quality</span><span class="tierbar-num" id="numQualityBar">0.00/42.50</span></span>
				</div>
				<div id="segPickup" class="tierbar-seg" style="width:0%; background:#f59e0b;" title="Pickup">
					<span id="innerPickup" class="tierbar-seg-inner"><span class="tierbar-cat">Pickup</span><span class="tierbar-num" id="numPickupBar">0.00/5.00</span></span>
				</div>
				<div id="segFleet" class="tierbar-seg" style="width:0%; background:#7c3aed;" title="Fleet">
					<span id="innerFleet" class="tierbar-seg-inner"><span class="tierbar-cat">Fleet</span><span class="tierbar-num" id="numFleetBar">0.00/5.00</span></span>
				</div>
				<div id="segRemainder" class="tierbar-seg tierbar-seg--remainder" style="width:100%; background:#e2e8f0;" title="Opportunity missed">
					<span id="innerRemainder" class="tierbar-seg-inner"><span class="tierbar-cat">Opportunity missed</span><span class="tierbar-num" id="numMissedBar">100.00</span></span>
				</div>
			</div>
			</div>
			<p class="tierbar-legend">Segment numbers are weighted points earned vs bucket max (47.5 / 42.5 / 5 / 5), not the raw 0-100 scores from the grid.</p>
		</div>
	</div>

	<div class="perf-section" id="section-weekly">
	<div class="panel" id="panel-current">
		<h5>Weekly Entry <span class="panel-badge">Editable Grid</span></h5>
		<div class="table-responsive">
			<table class="table table-sm table-fit" id="scoreTable">
				<thead id="mainHead"></thead>
				<tbody id="scoreTbody"></tbody>
			</table>
		</div>
		<div class="small-note">Yellow columns = editable business inputs. Green and blue columns = computed read-only outputs.</div>
	</div>
	</div>

	<div class="perf-section hidden" id="section-trends">
		<div class="panel sc-trend-panel" id="scoreTrendPanel" style="margin-top:.85rem;">
			<h5 style="margin:0 0 .35rem;">Visual Trends <span class="panel-badge">Read-only analytics</span></h5>
			<p class="small-note" style="margin:0 0 .65rem;">Up to <strong>11 weeks</strong>: selected week plus up to 10 older weeks with data. Bars left→right = oldest→newest; <strong>lower is better</strong> for every metric below.</p>
			<div id="scoreTrendCharts" class="sc-chart-grid"></div>
		</div>
	</div>

	<div class="perf-section hidden" id="section-comparison">
	<div class="panel" id="panel-prev">
		<div class="previous-title">
			<h5>Previous Week <span class="panel-badge">Read-only baseline</span></h5>
			<span class="small-note" id="prevWeekLabel">No previous week data</span>
		</div>
		<div class="sc-summary-panel sc-summary-panel--prev" id="kpiStripPrev" title="Previous week summary">
			<div class="sc-kpi-inner" role="group" aria-label="Previous week Quality and Safety summary">
				<div class="sc-kpi-week-row">
					<span class="sc-kpi-sect sc-kpi-sect--week">Week</span>
					<span id="prevKpiWeekToken" class="prev-week-token-readout" aria-label="Previous week">-</span>
				</div>
				<div class="sc-kpi-metrics-row">
					<div class="sc-kpi-block sc-kpi-block--quality" aria-labelledby="prevKpiQualityHeading">
						<span class="sc-kpi-sect" id="prevKpiQualityHeading">Quality</span>
						<div class="sc-mg-cell">
							<span class="sc-mg-lbl">Total Negative Feedback</span>
							<strong class="sc-mg-val" id="prevKpiNegFeedback">-</strong>
						</div>
						<div class="sc-mg-cell">
							<span class="sc-mg-lbl">Total DSB Defects</span>
							<strong class="sc-mg-val" id="prevKpiDsbDefects">-</strong>
						</div>
					</div>
					<div class="sc-kpi-block sc-kpi-block--safety" aria-labelledby="prevKpiSafetyHeading">
						<span class="sc-kpi-sect" id="prevKpiSafetyHeading">Safety</span>
						<div class="sc-mg-cell">
							<span class="sc-mg-lbl">Total Safety Incidents</span>
							<strong class="sc-mg-val" id="prevKpiSafetyIncidents">-</strong>
						</div>
						<div class="sc-mg-cell">
							<span class="sc-mg-lbl">Seatbelt</span>
							<strong class="sc-mg-val" id="prevKpiSeatbeltSubtotal">-</strong>
						</div>
						<div class="sc-mg-cell">
							<span class="sc-mg-lbl">Speeding</span>
							<strong class="sc-mg-val" id="prevKpiSpeedingSubtotal">-</strong>
						</div>
						<div class="sc-mg-cell">
							<span class="sc-mg-lbl">Sign/Signal</span>
							<strong class="sc-mg-val" id="prevKpiSignSubtotal">-</strong>
						</div>
						<div class="sc-mg-cell">
							<span class="sc-mg-lbl">Distraction</span>
							<strong class="sc-mg-val" id="prevKpiDistractionSubtotal">-</strong>
						</div>
						<div class="sc-mg-cell">
							<span class="sc-mg-lbl">Following Dist.</span>
							<strong class="sc-mg-val" id="prevKpiFollowingSubtotal">-</strong>
						</div>
					</div>
				</div>
			</div>
		</div>
		<div class="table-responsive" style="max-height: 42vh;">
			<table class="table table-sm table-fit">
				<thead id="prevHead"></thead>
				<tbody id="prevTbody"></tbody>
			</table>
		</div>
	</div>
	</div>

	<div class="perf-section hidden" id="section-coaching">
		<div class="panel" id="coachingTriggersPanel">
			<h5>Coaching Triggers <span class="panel-badge">Priority actions</span></h5>
			<div id="coachingTriggers" class="small-note">No triggers yet.</div>
		</div>
		<div class="threshold-panel" id="threshold-panel">
			<h6>Safety Metric Thresholds (Q1 2026)</h6>
			<div class="threshold-grid">
				<div><b>Seatbelt-Off Rate</b> (23.3% OSS): Fantastic &lt;4, Great &gt;4, Fair &gt;10, Poor &gt;15 per 100 trips.</div>
				<div><b>Distracted Driving Rate</b> (15.0% OSS): Fantastic &lt;3, Great &gt;3, Fair &gt;6, Poor &gt;10 per 100 trips.</div>
				<div><b>Following Distance Rate</b>: Fantastic &lt;3, Great &gt;3, Fair &gt;6, Poor &gt;10 per 100 trips.</div>
				<div><b>Speeding Rate</b>: Fantastic &lt;8, Great &gt;8, Fair &gt;12, Poor &gt;16 per 100 trips.</div>
				<div><b>Sign/Signal Violations Rate</b>: Fantastic &lt;8, Great &gt;8, Fair &gt;12, Poor &gt;16 per 100 trips.</div>
			</div>
			<div class="threshold-note">Trip definition: one trip = any day with package delivery and system coverage for that behavior. Minimum requirement: 20 trips per week for safety metrics to impact OSS.</div>
		</div>
	</div>
	</div>
</div>

<script>
const STORAGE_KEY = "mvpg_projected_scorecard_v3";
const TARGET_WEEKLY_SCORE = 88;
const DAYS = ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"];
const HEADERS = [
	"Day","Next Day Target","Wk Projection (Sun-Sat)","Trips","Pickup Qty","Fleet","Pkg Dispatched","Pkg Returned","Delivered","Neg. Feedback","DSB Def.","Seatbelt","Speeding","Sign/Sig","Distract.","Follow Dist.","Proj. Tier","CDF Left (F+)","DSB Left (F+)","Safety","Seat /100","Spd /100","Sign /100","Dist /100","Follow /100","Safety Score","CDF DPMO","DSB DPMO","Qual. Score","Proj. Wk Score"
];
const INPUT_FIELDS = [
	"trips","pickup_quality_score","team_score","packages_dispatched","packages_returned","negative_feedback","dsb_defects","seatbelt_events","speeding_events","sign_signal_events","distraction_events","following_distance_events"
];
const SAFETY_WEIGHTS = {
	seatbelt: 23.3,
	distracted: 15.0,
	following: (100 - 23.3 - 15.0) / 3,
	speeding: (100 - 23.3 - 15.0) / 3,
	signSignal: (100 - 23.3 - 15.0) / 3
};
const MIN_WEEK_TRIPS_FOR_OSS = 20;
const AUTH_KEYS = ["loginUser","loginUserDisplayName","loginUserID","loginUserRoles","entityID"];
const SESSION_AUTH = {
	loginUser: "<%= _loginUser.replace("\\", "\\\\").replace("\"", "\\\"") %>",
	loginUserDisplayName: "<%= _loginUserDisplayName.replace("\\", "\\\\").replace("\"", "\\\"") %>",
	loginUserID: "<%= _loginUserID.replace("\\", "\\\\").replace("\"", "\\\"") %>",
	loginUserRoles: "<%= _loginUserRoles.replace("\\", "\\\\").replace("\"", "\\\"") %>",
	entityID: "<%= _entityID.replace("\\", "\\\\").replace("\"", "\\\"") %>"
};
let currentWeekOffset = 0;
let currentWeekToken = getWeekToken(0);
let weekTokenOffsetMap = {};

function scShowSection(section, btn){
	document.querySelectorAll(".perf-section").forEach((el) => el.classList.add("hidden"));
	const target = document.getElementById("section-" + section);
	if (target) target.classList.remove("hidden");
	document.querySelectorAll(".perf-tab").forEach((t) => t.classList.remove("active"));
	if (btn) btn.classList.add("active");
}

/**
 * ISO 8601 week number and ISO week-year for a calendar date.
 * Week 1 is the week with the year's first Thursday; Monday-based weeks.
 * (Matches Excel WEEKNUM(...,21) / typical "2026-W16" labels.)
 */
function isoWeekYearAndNumber(date) {
	const d = new Date(date.getFullYear(), date.getMonth(), date.getDate());
	d.setHours(0, 0, 0, 0);
	d.setDate(d.getDate() + 3 - (d.getDay() + 6) % 7);
	const week1 = new Date(d.getFullYear(), 0, 4);
	return {
		isoYear: d.getFullYear(),
		week: 1 + Math.round(((d.getTime() - week1.getTime()) / 86400000 - 3 + (week1.getDay() + 6) % 7) / 7)
	};
}

/** Week token for the Sun-Sat block: use ISO week of that week's Thursday. */
function getWeekToken(offsetWeeks) {
	offsetWeeks = offsetWeeks || 0;
	const sun = getWeekStartSunday(offsetWeeks);
	const thu = new Date(sun.getFullYear(), sun.getMonth(), sun.getDate() + 4);
	const { isoYear, week } = isoWeekYearAndNumber(thu);
	return isoYear + "-W" + String(week).padStart(2, "0");
}

function formatWeekDropdownLabel(offsetWeeks) {
	const sun = getWeekStartSunday(offsetWeeks);
	const sat = new Date(sun.getFullYear(), sun.getMonth(), sun.getDate() + 6);
	const opts = { month: "short", day: "numeric" };
	const token = getWeekToken(offsetWeeks);
	const a = sun.toLocaleDateString("en-US", opts).replace(/\u2013|\u2014/g, "-");
	const b = sat.toLocaleDateString("en-US", opts).replace(/\u2013|\u2014/g, "-");
	return token + "  " + a + " - " + b;
}
function getWeekStartSunday(offsetWeeks) {
	offsetWeeks = offsetWeeks || 0;
	const now = new Date();
	now.setDate(now.getDate() + (offsetWeeks * 7));
	const day = now.getDay();
	now.setDate(now.getDate() - day);
	now.setHours(0,0,0,0);
	return now;
}
function formatDayWithDate(dayIndex, offsetWeeks) {
	const d = getWeekStartSunday(offsetWeeks);
	d.setDate(d.getDate() + dayIndex);
	const dayName = DAYS[dayIndex];
	const monthName = d.toLocaleString("en-US", { month: "long" });
	return dayName + " - " + d.getDate() + " " + monthName;
}
function weekStorageKey(weekToken) { return STORAGE_KEY + "_" + weekToken; }
function toNum(v) { const n = Number((v+"").replace(/,/g,"")); return Number.isFinite(n) ? n : 0; }
function fmt(v) { return toNum(v).toFixed(2); }
function fmtInt(v) { return String(Math.round(toNum(v))); }
function txt(v) { return v == null ? "" : String(v); }
function esc(v){ return encodeURIComponent(v == null ? "" : String(v)); }

function defaultRow(day, weekToken) {
	return {
		week: weekToken || currentWeekToken, day: day,
		next_day_target_score_needed: 0,
		weekly_projection: 0,
		trips: "", pickup_quality_score: "100", team_score: "100", packages_dispatched: "", packages_returned: "",
		total_delivered_auto: 0, negative_feedback: "", dsb_defects: "",
		seatbelt_events: "", speeding_events: "", sign_signal_events: "", distraction_events: "", following_distance_events: "",
		seatbelt_rate: 0, speeding_rate: 0, sign_signal_rate: 0, distraction_rate: 0, following_distance_rate: 0,
		safety_score_daily: 0, cdf_dpmo_running: 0, dsb_dpmo_running: 0, quality_score_running: 0,
		projected_weekly_score: 0, projected_tier: "-", remaining_cdf_allowed: 0, remaining_dsb_allowed: 0, safety_warning: "-"
	};
}

function loadData(weekToken) {
	const raw = localStorage.getItem(weekStorageKey(weekToken));
	let rows = DAYS.map(d => defaultRow(d, weekToken));
	if(raw){
		try{
			const parsed = JSON.parse(raw);
			if(parsed.week === weekToken && Array.isArray(parsed.rows) && parsed.rows.length === 7) {
			rows = parsed.rows;
			rows.forEach((r) => {
				if (r.pickup_quality_score === "" || r.pickup_quality_score == null) r.pickup_quality_score = "100";
				if (r.team_score === "" || r.team_score == null) r.team_score = "100";
			});
		}
		}catch(e){}
	}
	return rows;
}
function persistData(weekToken, rows) {
	localStorage.setItem(weekStorageKey(weekToken), JSON.stringify({ week: weekToken, rows: rows, savedAt: new Date().toISOString() }));
}
function buildAuthParams(){
	const qs = new URLSearchParams(window.location.search);
	const arr = [];
	AUTH_KEYS.forEach((k) => {
		let v = qs.get(k);
		if((!v || v.length === 0) && SESSION_AUTH[k]) v = SESSION_AUTH[k];
		if(v && v.length > 0) arr.push(`${k}=${esc(v)}`);
	});
	return arr.join("&");
}
/** Same-origin servlet URL; avoids broken relative ../servlet when path or reverse-proxy layout differs. */
function resolveScorecardServletUrl(){
	if (typeof window.MVPG_SERVLET_URL === "string" && window.MVPG_SERVLET_URL.length > 0)
		return window.MVPG_SERVLET_URL;
	const p = window.location.pathname || "";
	const jspIdx = p.indexOf("/jsp/");
	if (jspIdx >= 0)
		return p.substring(0, jspIdx) + "/servlet/MVPGServlet";
	return "../servlet/MVPGServlet";
}
function apiPost(extra){
	const auth = buildAuthParams();
	const body = `submitType=10&controller=Scorecard${auth ? "&"+auth : ""}&${extra}`;
	return fetch(resolveScorecardServletUrl(), {
		method: "POST",
		credentials: "same-origin",
		headers: { "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8" },
		body
	});
}
function mergeDbRows(week, dbRows){
	const rows = DAYS.map((d) => defaultRow(d, week));
	for(let i=0;i<rows.length;i++){
		rows[i].week = week;
		rows[i].day = DAYS[i];
	}
	/* Map by weekday name - DB ORDER BY id may not match Sun-Sat order if some rows failed to insert. */
	const byDay = {};
	(dbRows || []).forEach((dbRow) => {
		const raw = (dbRow && dbRow.day) != null ? String(dbRow.day) : "";
		const m = raw.match(/^(Sunday|Monday|Tuesday|Wednesday|Thursday|Friday|Saturday)\b/);
		const name = m ? m[1] : raw.split(/\s*[\u2013\u2014-]\s*/)[0].trim();
		if (DAYS.indexOf(name) >= 0) byDay[name] = dbRow;
	});
	DAYS.forEach((d, i) => {
		const src = byDay[d];
		if (!src) return;
		const r = rows[i];
		Object.keys(src).forEach((k) => { r[k] = src[k]; });
		if (r.pickup_quality_score === "" || r.pickup_quality_score == null) r.pickup_quality_score = "100";
		if (r.team_score === "" || r.team_score == null) r.team_score = "100";
	});
	return rows;
}
async function fetchWeekFromDb(weekToken){
	try{
		const resp = await apiPost(`requestType=loadScorecardWeek&scorecardWeek=${esc(weekToken)}`);
		const txtResp = await resp.text();
		const json = JSON.parse(txtResp || "{}");
		if(json && json.ok && Array.isArray(json.rows)) {
			const rows = calculate(mergeDbRows(weekToken, json.rows));
			persistData(weekToken, rows);
			return rows;
		}
	}catch(e){}
	return loadData(weekToken);
}
async function saveWeekToDb(weekToken, rows){
	const pairs = [`requestType=saveScorecardWeek`,`scorecardWeek=${esc(weekToken)}`];
	rows.forEach((r, i) => {
		pairs.push(`r${i}_day=${esc(formatDayWithDate(i, currentWeekOffset))}`);
		pairs.push(`r${i}_next_day_target_score_needed=${esc(typeof r.next_day_target_score_needed === "string" ? r.next_day_target_score_needed : fmt(r.next_day_target_score_needed))}`);
		pairs.push(`r${i}_weekly_projection=${esc(fmt(r.weekly_projection))}`);
		pairs.push(`r${i}_trips=${esc(toNum(r.trips))}`);
		pairs.push(`r${i}_pickup_quality_score=${esc(toNum(r.pickup_quality_score))}`);
		pairs.push(`r${i}_team_score=${esc(toNum(r.team_score))}`);
		pairs.push(`r${i}_packages_dispatched=${esc(toNum(r.packages_dispatched))}`);
		pairs.push(`r${i}_packages_returned=${esc(toNum(r.packages_returned))}`);
		pairs.push(`r${i}_total_delivered_auto=${esc(fmt(r.total_delivered_auto))}`);
		pairs.push(`r${i}_negative_feedback=${esc(toNum(r.negative_feedback))}`);
		pairs.push(`r${i}_dsb_defects=${esc(toNum(r.dsb_defects))}`);
		pairs.push(`r${i}_seatbelt_events=${esc(toNum(r.seatbelt_events))}`);
		pairs.push(`r${i}_speeding_events=${esc(toNum(r.speeding_events))}`);
		pairs.push(`r${i}_sign_signal_events=${esc(toNum(r.sign_signal_events))}`);
		pairs.push(`r${i}_distraction_events=${esc(toNum(r.distraction_events))}`);
		pairs.push(`r${i}_following_distance_events=${esc(toNum(r.following_distance_events))}`);
		pairs.push(`r${i}_seatbelt_rate=${esc(fmt(r.seatbelt_rate))}`);
		pairs.push(`r${i}_speeding_rate=${esc(fmt(r.speeding_rate))}`);
		pairs.push(`r${i}_sign_signal_rate=${esc(fmt(r.sign_signal_rate))}`);
		pairs.push(`r${i}_distraction_rate=${esc(fmt(r.distraction_rate))}`);
		pairs.push(`r${i}_following_distance_rate=${esc(fmt(r.following_distance_rate))}`);
		pairs.push(`r${i}_safety_score_daily=${esc(fmt(r.safety_score_daily))}`);
		pairs.push(`r${i}_cdf_dpmo_running=${esc(fmt(r.cdf_dpmo_running))}`);
		pairs.push(`r${i}_dsb_dpmo_running=${esc(fmt(r.dsb_dpmo_running))}`);
		pairs.push(`r${i}_quality_score_running=${esc(fmt(r.quality_score_running))}`);
		pairs.push(`r${i}_projected_weekly_score=${esc(fmt(r.projected_weekly_score))}`);
		pairs.push(`r${i}_projected_tier=${esc(r.projected_tier)}`);
		pairs.push(`r${i}_remaining_cdf_allowed=${esc(fmt(r.remaining_cdf_allowed))}`);
		pairs.push(`r${i}_remaining_dsb_allowed=${esc(fmt(r.remaining_dsb_allowed))}`);
		pairs.push(`r${i}_safety_warning=${esc(r.safety_warning)}`);
	});
	const resp = await apiPost(pairs.join("&"));
	const txtResp = await resp.text();
	if (!resp.ok) {
		console.error("saveScorecardWeek HTTP", resp.status, txtResp.slice(0, 500));
		return false;
	}
	try{
		const json = JSON.parse(txtResp || "{}");
		if (!json || !json.ok) {
			const msg = (json && json.message) ? json.message : (txtResp && txtResp.length < 400 ? txtResp : "Unknown error");
			console.error("saveScorecardWeek failed:", msg, json && json.rowsInserted);
		} else if (json.rowsInserted != null && json.rowsInserted < 7) {
			console.warn("saveScorecardWeek: only " + json.rowsInserted + " rows inserted (expected 7). Check DB constraints / score_day.");
		}
		return json && json.ok;
	}catch(e){
		console.error("saveScorecardWeek not JSON:", txtResp.slice(0, 500), e);
		return false;
	}
}

function tierForScore(score){
	if(score >= 88) return "Fantastic+";
	if(score >= 73) return "Fantastic";
	if(score >= 60) return "Great";
	return "At Risk";
}

function metricScoreFromRate(rate, fantasticMax, greatMax, fairMax, poorMax){
	const r = Math.max(0, toNum(rate));
	if(r < fantasticMax) return 100;
	if(r <= greatMax) return 100 - ((r - fantasticMax) / Math.max(0.0001, greatMax - fantasticMax)) * 20;
	if(r <= fairMax) return 80 - ((r - greatMax) / Math.max(0.0001, fairMax - greatMax)) * 20;
	if(r <= poorMax) return 60 - ((r - fairMax) / Math.max(0.0001, poorMax - fairMax)) * 30;
	return Math.max(0, 30 - ((r - poorMax) * 2));
}

function calculate(rows){
	let cumulativeDelivered = 0, cumulativeNeg = 0, cumulativeDsb = 0, cumulativeProjected = 0;
	for(let i=0;i<rows.length;i++){
		const r = rows[i];
		const trips = Math.max(0, toNum(r.trips));
		const pqs = Math.max(0, Math.min(100, toNum(r.pickup_quality_score)));
		const team = Math.max(0, Math.min(100, toNum(r.team_score)));
		const dispatched = Math.max(0, toNum(r.packages_dispatched));
		const returned = Math.max(0, toNum(r.packages_returned));
		const neg = Math.max(0, toNum(r.negative_feedback));
		const dsb = Math.max(0, toNum(r.dsb_defects));
		const seat = Math.max(0, toNum(r.seatbelt_events));
		const spd = Math.max(0, toNum(r.speeding_events));
		const ssg = Math.max(0, toNum(r.sign_signal_events));
		const dis = Math.max(0, toNum(r.distraction_events));
		const fol = Math.max(0, toNum(r.following_distance_events));

		r.total_delivered_auto = Math.max(0, dispatched - returned);
		const divisor = Math.max(1, trips);
		r.seatbelt_rate = (seat / divisor) * 100;
		r.speeding_rate = (spd / divisor) * 100;
		r.sign_signal_rate = (ssg / divisor) * 100;
		r.distraction_rate = (dis / divisor) * 100;
		r.following_distance_rate = (fol / divisor) * 100;
		// W column exact formula model from workbook
		const seatbeltMetric = r.seatbelt_rate <= 4 ? 100 : (4 / Math.max(r.seatbelt_rate, 0.0001)) * 100;
		const speedingMetric = r.speeding_rate <= 1.6 ? 100 : (1.6 / Math.max(r.speeding_rate, 0.0001)) * 100;
		const signMetric = r.sign_signal_rate <= 0.5 ? 100 : (0.5 / Math.max(r.sign_signal_rate, 0.0001)) * 100;
		const distractionMetric = r.distraction_rate <= 2.9 ? 100 : (2.9 / Math.max(r.distraction_rate, 0.0001)) * 100;
		const followingMetric = r.following_distance_rate <= 0.8 ? 100 : (0.8 / Math.max(r.following_distance_rate, 0.0001)) * 100;
		r.safety_score_daily = (seatbeltMetric + speedingMetric + signMetric + distractionMetric + followingMetric) / 5;

		cumulativeDelivered += r.total_delivered_auto;
		cumulativeNeg += neg;
		cumulativeDsb += dsb;

		// X / Y running DPMO
		r.cdf_dpmo_running = cumulativeDelivered > 0 ? (cumulativeNeg / cumulativeDelivered) * 1000000 : 0;
		r.dsb_dpmo_running = cumulativeDelivered > 0 ? (cumulativeDsb / cumulativeDelivered) * 1000000 : 0;
		// Z running quality
		const cdfMetric = r.cdf_dpmo_running <= 980 ? 100 : (980 / Math.max(r.cdf_dpmo_running, 0.0001)) * 100;
		const dsbMetric = r.dsb_dpmo_running <= 233 ? 100 : (233 / Math.max(r.dsb_dpmo_running, 0.0001)) * 100;
		r.quality_score_running = (cdfMetric + dsbMetric) / 2;
		// AA projected weekly score
		r.projected_weekly_score = (r.safety_score_daily * 0.475) + (r.quality_score_running * 0.425) + (pqs * 0.05) + (team * 0.05);
		cumulativeProjected += r.projected_weekly_score;
		// D weekly projection
		r.weekly_projection = cumulativeProjected / (i + 1);
		// C next day target
		const rowCount = i + 1;
		if(rowCount >= 7) r.next_day_target_score_needed = "Complete";
		else r.next_day_target_score_needed = ((TARGET_WEEKLY_SCORE * 7) - cumulativeProjected) / (7 - rowCount);

		r.projected_tier = tierForScore(r.projected_weekly_score);
		r.remaining_cdf_allowed = Math.max(0, ((980 * cumulativeDelivered) / 1000000) - cumulativeNeg);
		r.remaining_dsb_allowed = Math.max(0, ((233 * cumulativeDelivered) / 1000000) - cumulativeDsb);
		r.safety_warning = (r.seatbelt_rate > 4 || r.speeding_rate > 1.6 || r.sign_signal_rate > 0.5 || r.distraction_rate > 2.9 || r.following_distance_rate > 0.8) ? "? Safety Risk" : "Safe";
	}
	return rows;
}

function headerHtml(){
	const spec = [
		[2,"Day"],
		[1,"Next","Target"],
		[1,"Wk Proj.","(Sun-Sat)"],
		[2,"Trips"],
		[1,"Pickup","Qty"],
		[2,"Fleet"],
		[1,"Pkg","Disp."],
		[1,"Pkg","Rtn."],
		[1,"Delivered",""],
		[1,"Neg.","Feedback"],
		[1,"DSB","Def."],
		[2,"Seatbelt"],
		[2,"Speeding"],
		[2,"Sign/Sig"],
		[2,"Distract."],
		[2,"Follow Dist."],
		[2,"Proj. Tier"],
		[1,"CDF","L(F+)"],
		[1,"DSB","L(F+)"],
		[2,"Safety"],
		[1,"Seat","/100"],
		[1,"Spd","/100"],
		[1,"Sign","/100"],
		[1,"Dist","/100"],
		[1,"Follow","/100"],
		[1,"Safety","Score"],
		[1,"CDF","DPMO"],
		[1,"DSB","DPMO"],
		[1,"Qual.","Score"],
		[1,"Proj.","Wk"]
	];
	let r1 = "<tr>";
	let r2 = "<tr>";
	spec.forEach((s) => {
		if(s[0] === 2){
			r1 += "<th rowspan=\"2\">" + s[1] + "</th>";
		} else {
			r1 += "<th>" + s[1] + "</th>";
			const sub = (s.length > 2 && s[2] !== "") ? s[2] : "&nbsp;";
			r2 += "<th>" + sub + "</th>";
		}
	});
	r1 += "</tr>";
	r2 += "</tr>";
	return r1 + r2;
}
function tierCellClass(tier){
	return tier === "Fantastic+" ? "tier-good" : "tier-bad";
}
function buildWeekDropdown(){
	const sel = document.getElementById("kpiWeekSelect");
	if(!sel) return;
	weekTokenOffsetMap = {};
	sel.innerHTML = "";
	const seen = {};
	for(let i=0;i<16;i++){
		const off = -i;
		const token = getWeekToken(off);
		if (seen[token]) {
			console.warn("Scorecard: duplicate week token", token, "offsets", seen[token], off);
		}
		seen[token] = off;
		weekTokenOffsetMap[token] = off;
		const opt = document.createElement("option");
		opt.value = token;
		opt.textContent = formatWeekDropdownLabel(off);
		if(off === currentWeekOffset) opt.selected = true;
		sel.appendChild(opt);
	}
	sel.onchange = onWeekChanged;
}
function totalSafetyIncidents(rows){
	return rows.reduce((acc, r) => acc
		+ toNum(r.seatbelt_events)
		+ toNum(r.speeding_events)
		+ toNum(r.sign_signal_events)
		+ toNum(r.distraction_events)
		+ toNum(r.following_distance_events), 0);
}

function escapeHtmlSc(s){
	if(s == null) return "";
	return String(s).replace(/&/g,"&amp;").replace(/</g,"&lt;").replace(/>/g,"&gt;").replace(/"/g,"&quot;");
}

const SC_TREND_METRICS = [
	{ key:"negFeedback", label:"Total Negative Feedback" },
	{ key:"dsbDefects", label:"Total DSB Defects" },
	{ key:"safetyIncidents", label:"Total Safety Incidents" },
	{ key:"seatbelt", label:"Seatbelt events" },
	{ key:"speeding", label:"Speeding events" },
	{ key:"signSignal", label:"Sign / Signal events" },
	{ key:"distraction", label:"Distraction events" },
	{ key:"following", label:"Following distance events" }
];

function trendVsPrev(lowerBetter, prev, cur){
	if(!Number.isFinite(prev) || !Number.isFinite(cur)) return { cls:"sc-tr-same", text:"—" };
	const d = cur - prev;
	if(Math.abs(d) < 1e-6) return { cls:"sc-tr-same", text:"● No change" };
	if(lowerBetter){
		if(cur < prev) return { cls:"sc-tr-improve", text:"▲ Improving" };
		if(cur > prev) return { cls:"sc-tr-worse", text:"▼ Worse" };
	}
	return { cls:"sc-tr-same", text:"●" };
}

function renderScoreTrendCharts(points){
	const box = document.getElementById("scoreTrendCharts");
	if(!box) return;
	if(!points || points.length === 0){
		box.innerHTML = "<p class='small-note'>No weekly rows in <code>projected_scorecard</code> yet. Save this scorecard to build trend history.</p>";
		return;
	}
	const lastIdx = points.length - 1;
	const prevIdx = lastIdx - 1;
	box.innerHTML = SC_TREND_METRICS.map((def) => {
		const vals = points.map(p => Number(p[def.key]));
		const mx = Math.max(1, ...vals.map(v => Number.isFinite(v) ? v : 0));
		const cur = vals[lastIdx];
		const prev = prevIdx >= 0 ? vals[prevIdx] : null;
		const tv = trendVsPrev(true, prev, cur);
		const bars = points.map((p, i) => {
			const v = Number(p[def.key]);
			const h = Number.isFinite(v) ? Math.max(5, Math.round((v / mx) * 100)) : 5;
			const hi = i === lastIdx && prevIdx >= 0 && Number.isFinite(prev) && Number.isFinite(v) && v > prev;
			const cls = hi ? "bar bar--hi" : "bar";
			const tip = (p.week||"") + ": " + (Number.isFinite(v)?String(Math.round(v)):"—");
			return `<div class="${cls}" style="height:${h}%" title="${escapeHtmlSc(tip)}"></div>`;
		}).join("");
		const lastWin = points[lastIdx].week || "";
		return `<div class="sc-chart-card">
			<div class="sc-chart-title">${escapeHtmlSc(def.label)}</div>
			<div class="sc-chart-bars">${bars}</div>
			<div class="sc-chart-meta"><span>Last: <strong>${escapeHtmlSc(lastWin)}</strong> → <strong>${Number.isFinite(cur)?Math.round(cur):"—"}</strong></span><span class="${tv.cls}">${tv.text}</span></div>
		</div>`;
	}).join("");
}

async function loadScorecardWeeklyTrend(){
	const box = document.getElementById("scoreTrendCharts");
	if(!box) return;
	try{
		const resp = await apiPost("requestType=scorecardWeeklyTrend&scorecardWeek=" + esc(currentWeekToken));
		const data = JSON.parse((await resp.text()).trim() || "{}");
		if(!data.ok){
			box.innerHTML = "<p class='text-danger small'>" + escapeHtmlSc(data.message || "Trend request failed") + "</p>";
			return;
		}
		renderScoreTrendCharts(data.points || []);
	}catch(e){
		box.innerHTML = "<p class='text-danger small'>" + escapeHtmlSc(e.message) + "</p>";
	}
}
function getTierByTotal(total){
	if(total >= 88) return "Fantastic+";
	if(total >= 73) return "Fantastic";
	if(total >= 60) return "Great";
	if(total >= 50) return "Fair";
	return "Poor";
}
function getTierColor(tier){
	if(tier === "Fantastic+") return "#16a34a";
	if(tier === "Fantastic") return "#22c55e";
	if(tier === "Great") return "#3b82f6";
	if(tier === "Fair") return "#f59e0b";
	return "#ef4444";
}
function renderRunningTierBar(rows){
	const days = Math.max(1, rows.length);
	const safetyAvg = rows.reduce((a, r) => a + toNum(r.safety_score_daily), 0) / days;
	const qualityAvg = rows.reduce((a, r) => a + toNum(r.quality_score_running), 0) / days;
	const pickupAvg = rows.reduce((a, r) => a + toNum(r.pickup_quality_score), 0) / days;
	const fleetAvg = rows.reduce((a, r) => a + toNum(r.team_score), 0) / days;
	const safetyPts = (Math.max(0, Math.min(100, safetyAvg)) * 0.475);
	const qualityPts = (Math.max(0, Math.min(100, qualityAvg)) * 0.425);
	const pickupPts = (Math.max(0, Math.min(100, pickupAvg)) * 0.05);
	const fleetPts = (Math.max(0, Math.min(100, fleetAvg)) * 0.05);
	const total = safetyPts + qualityPts + pickupPts + fleetPts;
	const tier = getTierByTotal(total);
	const color = getTierColor(tier);

	const wS = Math.max(0, Math.min(100, safetyPts));
	const wQ = Math.max(0, Math.min(100, qualityPts));
	const wP = Math.max(0, Math.min(100, pickupPts));
	const wF = Math.max(0, Math.min(100, fleetPts));
	const wRem = Math.max(0, 100 - total);
	const TIER_MAX_SAFETY = 47.5;
	const TIER_MAX_QUALITY = 42.5;
	const TIER_MAX_PICKUP = 5;
	const TIER_MAX_FLEET = 5;

	document.getElementById("segSafety").style.width = wS.toFixed(2) + "%";
	document.getElementById("segQuality").style.width = wQ.toFixed(2) + "%";
	document.getElementById("segPickup").style.width = wP.toFixed(2) + "%";
	document.getElementById("segFleet").style.width = wF.toFixed(2) + "%";
	document.getElementById("segRemainder").style.width = wRem.toFixed(2) + "%";

	function setTierSegBar(segId, innerId, numId, wPct, pts, catTitle, maxPts){
		const seg = document.getElementById(segId);
		const inner = document.getElementById(innerId);
		const numEl = document.getElementById(numId);
		const earned = Math.max(0, Math.min(maxPts, pts));
		if(numEl) numEl.textContent = fmt(earned) + "/" + fmt(maxPts);
		if(seg) seg.title = `${catTitle} weighted: ${fmt(earned)}/${fmt(maxPts)} (toward weekly 100)`;
		if(inner){
			inner.classList.toggle("tierbar-seg-inner--narrow", wPct >= 1.5 && wPct < 9);
			inner.classList.toggle("tierbar-seg-inner--tiny", wPct < 1.5);
		}
	}
	setTierSegBar("segSafety", "innerSafety", "numSafetyBar", wS, safetyPts, "Safety", TIER_MAX_SAFETY);
	setTierSegBar("segQuality", "innerQuality", "numQualityBar", wQ, qualityPts, "Quality", TIER_MAX_QUALITY);
	setTierSegBar("segPickup", "innerPickup", "numPickupBar", wP, pickupPts, "Pickup", TIER_MAX_PICKUP);
	setTierSegBar("segFleet", "innerFleet", "numFleetBar", wF, fleetPts, "Fleet", TIER_MAX_FLEET);
	const innerRem = document.getElementById("innerRemainder");
	const numMissed = document.getElementById("numMissedBar");
	if(numMissed) numMissed.textContent = fmt(wRem);
	document.getElementById("segRemainder").title = `Opportunity missed ${fmt(wRem)} (points left to 100)`;
	if(innerRem){
		innerRem.classList.toggle("tierbar-seg-inner--narrow", wRem >= 1.5 && wRem < 9);
		innerRem.classList.toggle("tierbar-seg-inner--tiny", wRem < 1.5);
	}

	const titleEl = document.getElementById("tierBarTitle");
	if(titleEl){
		titleEl.innerHTML = '<span style="color:#1e3a8a">Scorecard Bar - </span><span style="color:' + color + '">' + tier + " (" + fmt(total) + "/100)</span>";
	}
}
function getPrevWeekTokenFromCurrent(){
	return getWeekToken(currentWeekOffset - 1);
}
async function onWeekChanged(){
	const sel = document.getElementById("kpiWeekSelect");
	currentWeekToken = sel.value;
	currentWeekOffset = weekTokenOffsetMap[currentWeekToken] == null ? 0 : weekTokenOffsetMap[currentWeekToken];
	const currentRows = await fetchWeekFromDb(currentWeekToken);
	const prevRows = await fetchWeekFromDb(getPrevWeekTokenFromCurrent());
	renderMain(currentRows);
	renderPrev(prevRows);
}

function renderMain(preloadedRows){
	const week = currentWeekToken;
	let rows = calculate(preloadedRows || loadData(week));
	persistData(week, rows);
	document.getElementById("mainHead").innerHTML = headerHtml();
	const tb = document.getElementById("scoreTbody");
	tb.innerHTML = "";
	rows.forEach((r, idx) => {
		const input = (field, col) => `<input class="txt-input" type="text" data-idx="${idx}" data-row="${idx}" data-col="${col}" data-field="${field}" value="${txt(r[field])}">`;
		const td = [];
		td.push(`<td class="calc-col">${formatDayWithDate(idx, currentWeekOffset)}</td>`);
		td.push(`<td class="focus-col readonly-cell">${typeof r.next_day_target_score_needed === "string" ? r.next_day_target_score_needed : fmt(r.next_day_target_score_needed)}</td>`);
		td.push(`<td class="focus-col readonly-cell">${fmt(r.weekly_projection)}</td>`);
		td.push(`<td class="edit-col">${input("trips", 0)}</td>`);
		td.push(`<td class="edit-col">${input("pickup_quality_score", 1)}</td>`);
		td.push(`<td class="edit-col">${input("team_score", 2)}</td>`);
		td.push(`<td class="edit-col">${input("packages_dispatched", 3)}</td>`);
		td.push(`<td class="edit-col">${input("packages_returned", 4)}</td>`);
		td.push(`<td class="calc-col readonly-cell">${fmtInt(r.total_delivered_auto)}</td>`);
		td.push(`<td class="edit-col">${input("negative_feedback", 5)}</td>`);
		td.push(`<td class="edit-col">${input("dsb_defects", 6)}</td>`);
		td.push(`<td class="edit-col">${input("seatbelt_events", 7)}</td>`);
		td.push(`<td class="edit-col">${input("speeding_events", 8)}</td>`);
		td.push(`<td class="edit-col">${input("sign_signal_events", 9)}</td>`);
		td.push(`<td class="edit-col">${input("distraction_events", 10)}</td>`);
		td.push(`<td class="edit-col">${input("following_distance_events", 11)}</td>`);
		td.push(`<td class="${tierCellClass(r.projected_tier)}">${r.projected_tier}</td>`);
		td.push(`<td class="calc-col readonly-cell">${fmt(r.remaining_cdf_allowed)}</td>`);
		td.push(`<td class="calc-col readonly-cell">${fmt(r.remaining_dsb_allowed)}</td>`);
		td.push(`<td class="calc-col readonly-cell">${r.safety_warning}</td>`);
		td.push(`<td class="calc-col readonly-cell">${fmt(r.seatbelt_rate)}</td>`);
		td.push(`<td class="calc-col readonly-cell">${fmt(r.speeding_rate)}</td>`);
		td.push(`<td class="calc-col readonly-cell">${fmt(r.sign_signal_rate)}</td>`);
		td.push(`<td class="calc-col readonly-cell">${fmt(r.distraction_rate)}</td>`);
		td.push(`<td class="calc-col readonly-cell">${fmt(r.following_distance_rate)}</td>`);
		td.push(`<td class="calc-col readonly-cell">${fmt(r.safety_score_daily)}</td>`);
		td.push(`<td class="calc-col readonly-cell">${fmt(r.cdf_dpmo_running)}</td>`);
		td.push(`<td class="calc-col readonly-cell">${fmt(r.dsb_dpmo_running)}</td>`);
		td.push(`<td class="calc-col readonly-cell">${fmt(r.quality_score_running)}</td>`);
		td.push(`<td class="calc-col readonly-cell">${fmt(r.projected_weekly_score)}</td>`);
		const tr = document.createElement("tr");
		tr.innerHTML = td.join("");
		tb.appendChild(tr);
	});
	bindInputs();
	updateKpis(rows);
	loadScorecardWeeklyTrend();
}

function bindInputs(){
	const inputs = Array.from(document.querySelectorAll("#scoreTbody .txt-input"));
	inputs.forEach((el, idx) => {
		el.addEventListener("input", () => quickSave(false));
		el.addEventListener("blur", () => quickSave(false));
		el.addEventListener("keydown", (e) => {
			if(e.key === "Enter") {
				e.preventDefault();
				const next = inputs[idx + 1];
				if(next) {
					next.focus();
					next.select();
				} else {
					el.blur();
				}
			} else if(e.key === "Tab") {
				e.preventDefault();
				const target = e.shiftKey ? inputs[idx - 1] : inputs[idx + 1];
				if(target) {
					target.focus();
					target.select();
				} else {
					el.blur();
				}
			} else if(e.key === "ArrowDown" || e.key === "ArrowUp") {
				e.preventDefault();
				const row = Number(el.getAttribute("data-row"));
				const col = Number(el.getAttribute("data-col"));
				const targetRow = e.key === "ArrowDown" ? row + 1 : row - 1;
				const target = document.querySelector(`#scoreTbody .txt-input[data-row='${targetRow}'][data-col='${col}']`);
				if(target) {
					target.focus();
					target.select();
				}
			}
		});
	});
}

function collectCurrentRows(){
	const rows = DAYS.map(d => defaultRow(d, currentWeekToken));
	document.querySelectorAll("#scoreTbody .txt-input").forEach(el => {
		const idx = Number(el.getAttribute("data-idx"));
		const field = el.getAttribute("data-field");
		rows[idx][field] = el.value;
	});
	return rows;
}

function quickSave(hardRender){
	const week = currentWeekToken;
	const rows = calculate(collectCurrentRows());
	persistData(week, rows);
	updateKpis(rows);
	if(hardRender) renderMain();
	else updateCurrentCalcCells(rows);
	renderPrev();
}

function updateCurrentCalcCells(rows){
	const trs = document.querySelectorAll("#scoreTbody tr");
	rows.forEach((r,i) => {
		const t = trs[i];
		if(!t) return;
		t.children[1].innerText = (typeof r.next_day_target_score_needed === "string") ? r.next_day_target_score_needed : fmt(r.next_day_target_score_needed);
		t.children[2].innerText = fmt(r.weekly_projection);
		t.children[8].innerText = fmtInt(r.total_delivered_auto);
		t.children[16].innerText = r.projected_tier;
		t.children[16].className = tierCellClass(r.projected_tier);
		t.children[17].innerText = fmt(r.remaining_cdf_allowed);
		t.children[18].innerText = fmt(r.remaining_dsb_allowed);
		t.children[19].innerText = r.safety_warning;
		t.children[20].innerText = fmt(r.seatbelt_rate);
		t.children[21].innerText = fmt(r.speeding_rate);
		t.children[22].innerText = fmt(r.sign_signal_rate);
		t.children[23].innerText = fmt(r.distraction_rate);
		t.children[24].innerText = fmt(r.following_distance_rate);
		t.children[25].innerText = fmt(r.safety_score_daily);
		t.children[26].innerText = fmt(r.cdf_dpmo_running);
		t.children[27].innerText = fmt(r.dsb_dpmo_running);
		t.children[28].innerText = fmt(r.quality_score_running);
		t.children[29].innerText = fmt(r.projected_weekly_score);
	});
}

function updateKpis(rows){
	const safetyInc = String(totalSafetyIncidents(rows));
	const negFb = String(rows.reduce((a, r) => a + toNum(r.negative_feedback), 0));
	const dsb = String(rows.reduce((a, r) => a + toNum(r.dsb_defects), 0));
	const seat = String(rows.reduce((a, r) => a + toNum(r.seatbelt_events), 0));
	const speed = String(rows.reduce((a, r) => a + toNum(r.speeding_events), 0));
	const sign = String(rows.reduce((a, r) => a + toNum(r.sign_signal_events), 0));
	const dis = String(rows.reduce((a, r) => a + toNum(r.distraction_events), 0));
	const foll = String(rows.reduce((a, r) => a + toNum(r.following_distance_events), 0));
	document.getElementById("kpiSafetyIncidents").innerText = safetyInc;
	document.getElementById("kpiNegFeedback").innerText = negFb;
	document.getElementById("kpiDsbDefects").innerText = dsb;
	document.getElementById("kpiSeatbeltSubtotal").innerText = seat;
	document.getElementById("kpiSpeedingSubtotal").innerText = speed;
	document.getElementById("kpiSignSubtotal").innerText = sign;
	document.getElementById("kpiDistractionSubtotal").innerText = dis;
	document.getElementById("kpiFollowingSubtotal").innerText = foll;
	document.getElementById("perfKpiSafetyIncidents").innerText = safetyInc;
	document.getElementById("perfKpiNegFeedback").innerText = negFb;
	document.getElementById("perfKpiDsbDefects").innerText = dsb;
	document.getElementById("perfKpiSeatbeltSubtotal").innerText = seat;
	document.getElementById("perfKpiSpeedingSubtotal").innerText = speed;
	const weighted = rows.length ? toNum(rows[rows.length - 1].projected_weekly_score) : 0;
	document.getElementById("perfWeightedScore").innerText = fmt(weighted);
	document.getElementById("perfTierTxt").innerText = tierForScore(weighted);
	renderRunningTierBar(rows);
	renderCoachingTriggers(rows);
}

function renderCoachingTriggers(rows){
	const host = document.getElementById("coachingTriggers");
	if(!host) return;
	const latest = rows && rows.length ? rows[rows.length - 1] : null;
	if(!latest){
		host.innerHTML = "<div class='small-note'>No weekly data available.</div>";
		return;
	}
	const cards = [];
	function pushTrigger(cond, title, detail){
		if(cond) cards.push(`<div class="mvpg-state mvpg-state--error" style="text-align:left;padding:10px 12px;margin-bottom:8px;"><strong>${title}</strong>${detail}</div>`);
	}
	pushTrigger(toNum(latest.seatbelt_rate) > 4, "Seatbelt coaching required", `Rate ${fmt(latest.seatbelt_rate)} exceeds Fantastic threshold (<4).`);
	pushTrigger(toNum(latest.distraction_rate) > 2.9, "Distraction behavior elevated", `Rate ${fmt(latest.distraction_rate)} exceeds threshold (<2.9).`);
	pushTrigger(toNum(latest.speeding_rate) > 1.6, "Speeding events elevated", `Rate ${fmt(latest.speeding_rate)} exceeds threshold (<1.6).`);
	pushTrigger(toNum(latest.sign_signal_rate) > 0.5, "Sign/Signal misses elevated", `Rate ${fmt(latest.sign_signal_rate)} exceeds threshold (<0.5).`);
	pushTrigger(toNum(latest.following_distance_rate) > 0.8, "Following distance risk", `Rate ${fmt(latest.following_distance_rate)} exceeds threshold (<0.8).`);
	pushTrigger(toNum(latest.projected_weekly_score) < 73, "Weekly score below Fantastic", `Projected score is ${fmt(latest.projected_weekly_score)}. Focus coaching on safety + quality drivers.`);
	if(cards.length === 0){
		host.innerHTML = "<div class='mvpg-state'><strong>No active triggers</strong>Current metrics are within target coaching thresholds.</div>";
		return;
	}
	host.innerHTML = cards.join("");
}
function updatePrevKpis(rows, weekToken){
	document.getElementById("prevKpiWeekToken").innerText = weekToken || "-";
	document.getElementById("prevKpiSafetyIncidents").innerText = rows.length ? String(totalSafetyIncidents(rows)) : "-";
	document.getElementById("prevKpiNegFeedback").innerText = rows.length ? String(rows.reduce((a, r) => a + toNum(r.negative_feedback), 0)) : "-";
	document.getElementById("prevKpiDsbDefects").innerText = rows.length ? String(rows.reduce((a, r) => a + toNum(r.dsb_defects), 0)) : "-";
	document.getElementById("prevKpiSeatbeltSubtotal").innerText = rows.length ? String(rows.reduce((a, r) => a + toNum(r.seatbelt_events), 0)) : "-";
	document.getElementById("prevKpiSpeedingSubtotal").innerText = rows.length ? String(rows.reduce((a, r) => a + toNum(r.speeding_events), 0)) : "-";
	document.getElementById("prevKpiSignSubtotal").innerText = rows.length ? String(rows.reduce((a, r) => a + toNum(r.sign_signal_events), 0)) : "-";
	document.getElementById("prevKpiDistractionSubtotal").innerText = rows.length ? String(rows.reduce((a, r) => a + toNum(r.distraction_events), 0)) : "-";
	document.getElementById("prevKpiFollowingSubtotal").innerText = rows.length ? String(rows.reduce((a, r) => a + toNum(r.following_distance_events), 0)) : "-";
}

function renderPrev(preloadedRows){
	document.getElementById("prevHead").innerHTML = headerHtml();
	const prevWeek = getPrevWeekTokenFromCurrent();
	const rows = calculate(preloadedRows || loadData(prevWeek));
	const hasData = rows.some(r => INPUT_FIELDS.some(f => toNum(r[f]) > 0));
	document.getElementById("prevWeekLabel").innerText = hasData ? ("Week " + prevWeek) : ("No saved data for week " + prevWeek);
	const tb = document.getElementById("prevTbody");
	tb.innerHTML = "";
	rows.forEach((r, idx) => {
		const td = [];
		td.push(`<td class="calc-col">${formatDayWithDate(idx, currentWeekOffset - 1)}</td>`);
		td.push(`<td class="focus-col readonly-cell">${typeof r.next_day_target_score_needed === "string" ? r.next_day_target_score_needed : fmt(r.next_day_target_score_needed)}</td>`);
		td.push(`<td class="focus-col readonly-cell">${fmt(r.weekly_projection)}</td>`);
		td.push(`<td class="sc-entry-readonly readonly-cell">${toNum(r.trips)}</td>`);
		td.push(`<td class="sc-entry-readonly readonly-cell">${toNum(r.pickup_quality_score)}</td>`);
		td.push(`<td class="sc-entry-readonly readonly-cell">${toNum(r.team_score)}</td>`);
		td.push(`<td class="sc-entry-readonly readonly-cell">${toNum(r.packages_dispatched)}</td>`);
		td.push(`<td class="sc-entry-readonly readonly-cell">${toNum(r.packages_returned)}</td>`);
		td.push(`<td class="calc-col readonly-cell">${fmtInt(r.total_delivered_auto)}</td>`);
		td.push(`<td class="sc-entry-readonly readonly-cell">${toNum(r.negative_feedback)}</td>`);
		td.push(`<td class="sc-entry-readonly readonly-cell">${toNum(r.dsb_defects)}</td>`);
		td.push(`<td class="sc-entry-readonly readonly-cell">${toNum(r.seatbelt_events)}</td>`);
		td.push(`<td class="sc-entry-readonly readonly-cell">${toNum(r.speeding_events)}</td>`);
		td.push(`<td class="sc-entry-readonly readonly-cell">${toNum(r.sign_signal_events)}</td>`);
		td.push(`<td class="sc-entry-readonly readonly-cell">${toNum(r.distraction_events)}</td>`);
		td.push(`<td class="sc-entry-readonly readonly-cell">${toNum(r.following_distance_events)}</td>`);
		td.push(`<td class="${tierCellClass(r.projected_tier)}">${r.projected_tier}</td>`);
		td.push(`<td class="calc-col readonly-cell">${fmt(r.remaining_cdf_allowed)}</td>`);
		td.push(`<td class="calc-col readonly-cell">${fmt(r.remaining_dsb_allowed)}</td>`);
		td.push(`<td class="calc-col readonly-cell">${r.safety_warning}</td>`);
		td.push(`<td class="calc-col readonly-cell">${fmt(r.seatbelt_rate)}</td>`);
		td.push(`<td class="calc-col readonly-cell">${fmt(r.speeding_rate)}</td>`);
		td.push(`<td class="calc-col readonly-cell">${fmt(r.sign_signal_rate)}</td>`);
		td.push(`<td class="calc-col readonly-cell">${fmt(r.distraction_rate)}</td>`);
		td.push(`<td class="calc-col readonly-cell">${fmt(r.following_distance_rate)}</td>`);
		td.push(`<td class="calc-col readonly-cell">${fmt(r.safety_score_daily)}</td>`);
		td.push(`<td class="calc-col readonly-cell">${fmt(r.cdf_dpmo_running)}</td>`);
		td.push(`<td class="calc-col readonly-cell">${fmt(r.dsb_dpmo_running)}</td>`);
		td.push(`<td class="calc-col readonly-cell">${fmt(r.quality_score_running)}</td>`);
		td.push(`<td class="calc-col readonly-cell">${fmt(r.projected_weekly_score)}</td>`);
		const tr = document.createElement("tr");
		tr.innerHTML = td.join("");
		tb.appendChild(tr);
	});
	updatePrevKpis(rows, prevWeek);
}

async function saveScorecard(){
	const week = currentWeekToken;
	const rows = calculate(collectCurrentRows());
	persistData(week, rows);
	updateKpis(rows);
	const ok = await saveWeekToDb(week, rows);
	const toast = typeof mvpgToast !== "undefined" ? mvpgToast : null;
	if (ok) {
		if (toast) toast.success("Scorecard saved to DB for " + week);
		updateCurrentCalcCells(rows);
		renderPrev();
		loadScorecardWeeklyTrend();
	} else {
		if (toast) toast.error("DB save failed for " + week + ". Saved locally only. Check browser console (F12) for details.");
	}
}
function resetScorecard(){ if(!confirm("Reset this week's scorecard?")) return; localStorage.removeItem(weekStorageKey(currentWeekToken)); renderMain(); renderPrev(); }

async function copyFromPreviousWeek(){
	const prevTok = getPrevWeekTokenFromCurrent();
	if (!prevTok || prevTok === currentWeekToken) {
		if (typeof mvpgToast !== "undefined") mvpgToast.warning("No previous week to copy.");
		return;
	}
	if (!confirm("Fill this week (" + currentWeekToken + ") using entry values from the previous week (" + prevTok + ")? Same weekday rows are copied (Sun to Sun, etc.)."))
		return;
	let prevRows;
	try {
		prevRows = await fetchWeekFromDb(prevTok);
	} catch (e) {
		prevRows = loadData(prevTok);
	}
	if (!prevRows || prevRows.length < 7) {
		if (typeof mvpgToast !== "undefined") mvpgToast.error("Could not load previous week data.");
		return;
	}
	const base = DAYS.map((d) => defaultRow(d, currentWeekToken));
	for (let i = 0; i < 7; i++) {
		const src = prevRows[i];
		if (!src) continue;
		INPUT_FIELDS.forEach((f) => {
			const v = src[f];
			if (v != null && String(v).length > 0) base[i][f] = v;
		});
	}
	const merged = calculate(base);
	persistData(currentWeekToken, merged);
	renderMain(merged);
	try {
		const prevCompare = await fetchWeekFromDb(getPrevWeekTokenFromCurrent());
		renderPrev(prevCompare);
	} catch (e) {
		renderPrev();
	}
	if (typeof mvpgToast !== "undefined") mvpgToast.success("Copied inputs from previous week. Save when ready.");
}
function downloadCSV(){
	const rows = calculate(collectCurrentRows());
	const lines = [HEADERS];
	rows.forEach((r, idx) => {
		lines.push([
			formatDayWithDate(idx, currentWeekOffset),(typeof r.next_day_target_score_needed === "string" ? r.next_day_target_score_needed : fmt(r.next_day_target_score_needed)),fmt(r.weekly_projection),toNum(r.trips),toNum(r.pickup_quality_score),toNum(r.team_score),toNum(r.packages_dispatched),toNum(r.packages_returned),fmtInt(r.total_delivered_auto),toNum(r.negative_feedback),toNum(r.dsb_defects),toNum(r.seatbelt_events),toNum(r.speeding_events),toNum(r.sign_signal_events),toNum(r.distraction_events),toNum(r.following_distance_events),r.projected_tier,fmt(r.remaining_cdf_allowed),fmt(r.remaining_dsb_allowed),r.safety_warning,fmt(r.seatbelt_rate),fmt(r.speeding_rate),fmt(r.sign_signal_rate),fmt(r.distraction_rate),fmt(r.following_distance_rate),fmt(r.safety_score_daily),fmt(r.cdf_dpmo_running),fmt(r.dsb_dpmo_running),fmt(r.quality_score_running),fmt(r.projected_weekly_score)
		]);
	});
	const csv = lines.map(arr => arr.map(v => `"${String(v).replace(/\"/g,'""')}"`).join(",")).join("\n");
	const blob = new Blob([csv], { type:"text/csv;charset=utf-8;" });
	const a = document.createElement("a");
	a.href = URL.createObjectURL(blob);
	a.download = "projected-scorecard-" + currentWeekToken + ".csv";
	document.body.appendChild(a); a.click(); document.body.removeChild(a);
}

(async function init(){
	currentWeekOffset = 0;
	currentWeekToken = getWeekToken(0);
	buildWeekDropdown();
	const week = currentWeekToken;
	const prevWeek = getPrevWeekTokenFromCurrent();
	const currentRows = await fetchWeekFromDb(week);
	const prevRows = await fetchWeekFromDb(prevWeek);
	renderMain(currentRows);
	renderPrev(prevRows);

	/* Show the read-only previous-week block directly on the Weekly Entry
	   screen (below the editable grid). It was in the Comparison tab, which
	   is now redundant, so hide that tab. */
	var _pp = document.getElementById("panel-prev");
	var _sw = document.getElementById("section-weekly");
	if (_pp && _sw) _sw.appendChild(_pp);
	var _cmpTab = document.querySelector('.perf-tab[data-section="comparison"]');
	if (_cmpTab) _cmpTab.style.display = "none";
})();
</script>
</body>
</html>
