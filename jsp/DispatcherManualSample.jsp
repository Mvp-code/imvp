<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"
         import="java.util.*,com.util.*,com.beans.*" %>
<%
  /* ── SAMPLE ONLY — Dispatcher Scorecard Manual (review before final build) ──
     Open: /MVPx/jsp/DispatcherManualSample.jsp
     Not in nav yet. Tell us what to add/remove before we ship DispatcherManual.jsp */
  String dmLoginUser   = request.getAttribute("loginUser") != null ? request.getAttribute("loginUser").toString() : (String) session.getAttribute("loginUser");
  String dmLoginRoles  = request.getAttribute("loginUserRoles") != null ? request.getAttribute("loginUserRoles").toString() : (String) session.getAttribute("loginUserRoles");
  String dmEntityID    = request.getAttribute("entityID") != null ? request.getAttribute("entityID").toString() : (session.getAttribute("entityID") != null ? session.getAttribute("entityID").toString() : "1");
  String dmDispName    = request.getAttribute("loginUserDisplayName") != null ? request.getAttribute("loginUserDisplayName").toString() : (session.getAttribute("loginUserDisplayName") != null ? session.getAttribute("loginUserDisplayName").toString() : "");
  String dmLoginUserID = request.getAttribute("loginUserID") != null ? request.getAttribute("loginUserID").toString() : (session.getAttribute("loginUserID") != null ? session.getAttribute("loginUserID").toString() : "");
  if (dmLoginUser == null) dmLoginUser = "";
  if (dmLoginRoles == null) dmLoginRoles = "";
  if (dmDispName == null || dmDispName.length() == 0) dmDispName = "Dispatcher";
  if (dmEntityID == null || dmEntityID.length() == 0) dmEntityID = "1";

  final String ST = "DNK7", DSP = "MVPG";
  final String CO = "b67abdb1-a16c-46db-b466-81c3a78e65aa";
  final String P  = "https://logistics.amazon.com/performance?station=" + ST + "&companyId=" + CO + "&navMenuVariant=external&timeFrame=Weekly&pageId=";

  request.setAttribute("loginUser", dmLoginUser);
  request.setAttribute("loginUserRoles", dmLoginRoles);
  request.setAttribute("entityID", dmEntityID);
  request.setAttribute("loginUserDisplayName", dmDispName);
  request.setAttribute("loginUserID", dmLoginUserID);
  request.setAttribute("shellNoForm", "yes");
  request.setAttribute("hideTopbarSearch", "yes");
%>
<jsp:useBean id="_recordBean" class="com.beans.SearchBean" scope="request" />
<%
  _recordBean.setController("DispatcherManualSample");
  _recordBean.setDisplayName("Dispatcher Manual (Sample)");
  int submitType = SubmitType.SEARCH;
%>
<!DOCTYPE html>
<html lang="en">
<%@ include file="includeHeader.jsp"%>
<script>function validatePageData(submitType, isValid) { return isValid; }</script>
<style>
.dm-sample-banner{background:#FEF3C7;border:1px solid #F59E0B;border-radius:8px;padding:8px 12px;font-size:12px;color:#92400E;margin-bottom:10px}
.dm-shell{display:flex;flex-direction:column;height:calc(100vh - 96px);overflow:hidden}
.dm-hdr{display:flex;align-items:flex-start;gap:14px;flex-wrap:wrap;margin-bottom:8px;flex-shrink:0}
.dm-hdr h1{font-size:18px;font-weight:900;color:#0f172a;margin:0}
.dm-meta{display:flex;gap:8px;flex-wrap:wrap}
.dm-chip{background:#fff;border:1px solid #E4E8F0;border-radius:7px;padding:4px 10px;font-size:11px;color:#475569}
.dm-chip b{color:#0f172a}
.dm-week{margin-left:auto;display:flex;align-items:center;gap:6px;font-size:12px;color:#64748B}
.dm-week select{border:1px solid #CBD5E1;border-radius:7px;padding:5px 8px;font-size:12px}
.dm-tabs{display:flex;gap:2px;border-bottom:2px solid #E4E8F0;margin-bottom:8px;flex-shrink:0;flex-wrap:wrap}
.dm-tab{border:none;background:none;padding:7px 14px;font-size:13px;font-weight:700;color:#64748B;cursor:pointer;border-bottom:2px solid transparent;margin-bottom:-2px}
.dm-tab.active{color:#0f172a;border-bottom-color:#0f172a}
.dm-body{flex:1;min-height:0;overflow:hidden;display:flex;gap:10px}
.dm-pane{display:none;flex:1;min-height:0;overflow:auto}.dm-pane.active{display:flex;flex-direction:column}
/* overview */
.dm-ov-grid{display:grid;grid-template-columns:1.2fr 1fr;gap:12px}
@media(max-width:900px){.dm-ov-grid{grid-template-columns:1fr}}
.dm-card{background:#fff;border:1px solid #E4E8F0;border-radius:10px;padding:12px 14px}
.dm-card h2{margin:0 0 8px;font-size:13px;font-weight:900;color:#0f172a;text-transform:uppercase;letter-spacing:.04em}
.dm-score{font-size:42px;font-weight:900;color:#0f172a;line-height:1}
.dm-tier{display:inline-block;background:#ECFDF5;color:#065F46;font-size:11px;font-weight:800;padding:3px 10px;border-radius:9px;margin-top:4px}
.dm-weights{display:grid;grid-template-columns:repeat(4,1fr);gap:8px;margin-top:10px}
.dm-wt{text-align:center;border:1px solid #EEF1F6;border-radius:8px;padding:8px 6px}
.dm-wt b{display:block;font-size:18px;color:#0f172a}
.dm-wt span{font-size:9.5px;text-transform:uppercase;letter-spacing:.06em;color:#64748B}
.dm-wt.safety{border-color:#FECACA;background:#FEF2F2}
.dm-wt.quality{border-color:#BFDBFE;background:#EFF6FF}
.dm-bar{height:8px;border-radius:4px;background:#EEF1F6;overflow:hidden;margin:8px 0 4px}
.dm-bar i{display:block;height:100%;border-radius:4px}
.dm-kpi-row{display:grid;grid-template-columns:repeat(auto-fill,minmax(140px,1fr));gap:8px;margin-top:8px}
.dm-kpi{border:1px solid #EEF1F6;border-radius:8px;padding:7px 9px}
.dm-kpi .l{font-size:9.5px;text-transform:uppercase;color:#64748B;letter-spacing:.05em}
.dm-kpi .v{font-size:15px;font-weight:800;color:#0f172a;font-family:Consolas,monospace}
.dm-kpi .t{font-size:10px;color:var(--status-ok-fg);font-weight:700}
.dm-callout{border-left:4px solid var(--status-warn-fg);background:var(--status-warn-bg);padding:10px 12px;border-radius:0 8px 8px 0;font-size:12.5px;color:var(--status-warn-fg);line-height:1.5;margin-top:10px}
/* modules */
.dm-mod-nav{width:220px;flex-shrink:0;overflow:auto;border:1px solid #E4E8F0;border-radius:8px;background:#F8FAFC;padding:6px}
.dm-mod-btn{display:block;width:100%;text-align:left;border:none;background:transparent;padding:7px 9px;border-radius:6px;font-size:12px;color:#334155;cursor:pointer;margin-bottom:2px}
.dm-mod-btn:hover{background:#EEF1F6}
.dm-mod-btn.active{background:#0f172a;color:#fff;font-weight:700}
.dm-mod-btn small{display:block;font-size:10px;opacity:.75;margin-top:1px}
.dm-mod-body{flex:1;overflow:auto;border:1px solid #E4E8F0;border-radius:8px;background:#fff;padding:14px 16px}
.dm-mod-body h3{margin:0 0 4px;font-size:17px;color:#0f172a}
.dm-mod-body .goal{font-size:12px;color:#64748B;font-style:italic;margin-bottom:12px;padding-bottom:10px;border-bottom:1px solid #EEF1F6}
.dm-mod-body h4{margin:14px 0 6px;font-size:12px;text-transform:uppercase;letter-spacing:.05em;color:#475569}
.dm-mod-body p,.dm-mod-body li{font-size:13px;line-height:1.55;color:#1F2937}
.dm-mod-body table{width:100%;border-collapse:collapse;margin:8px 0;font-size:12px}
.dm-mod-body th,.dm-mod-body td{border:1px solid #E4E8F0;padding:6px 8px;text-align:left;vertical-align:top}
.dm-mod-body th{background:#F8FAFC;font-size:10px;text-transform:uppercase;color:#64748B}
.dm-mod-body code,.dm-mod-body pre{font-family:Consolas,Menlo,monospace;font-size:11.5px;background:#F1F5F9;padding:2px 5px;border-radius:4px}
.dm-mod-body pre{padding:10px;border-radius:8px;line-height:1.45;overflow:auto}
.dm-stub{color:#94A3B8;font-size:12px;border:1px dashed #CBD5E1;border-radius:8px;padding:12px;margin-top:10px}
/* resources */
.dm-res-wrap{flex:1;overflow:auto}
.dm-res-grp{font-size:11px;font-weight:800;text-transform:uppercase;letter-spacing:.05em;color:#64748B;margin:14px 0 6px}
.dm-res-grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(280px,1fr));gap:8px}
.dm-link{display:block;text-decoration:none;border:1px solid #E4E8F0;border-radius:8px;padding:10px 12px;background:#fff;color:inherit}
.dm-link:hover{border-color:#0f172a;background:#F8FAFC}
.dm-link b{display:block;font-size:13px;color:#0f172a;margin-bottom:3px}
.dm-link span{font-size:11.5px;color:#64748B;line-height:1.4}
.dm-link .tag{display:inline-block;font-size:9px;font-weight:800;padding:1px 6px;border-radius:6px;background:#EFF6FF;color:#1E40AF;margin-top:4px}
/* self-check */
.dm-q{border:1px solid #E4E8F0;border-radius:8px;padding:10px 12px;margin-bottom:8px;background:#fff}
.dm-q b{font-size:13px;color:#0f172a}
.dm-q .ans{display:none;margin-top:8px;padding-top:8px;border-top:1px solid #EEF1F6;font-size:12.5px;color:#334155}
.dm-q.open .ans{display:block}
</style>

<div class="dm-shell">
  <div class="dm-sample-banner">
    <b>SAMPLE / REVIEW ONLY</b> — Layout preview for the Dispatcher Scorecard Manual. Not linked in nav yet.
    Tell us what to add, cut, or reorder before we build the final page.
  </div>

  <div class="dm-hdr">
    <div>
      <h1><i class="fa fa-graduation-cap"></i> Dispatcher Scorecard Manual</h1>
      <div class="dm-meta">
        <span class="dm-chip">DSP <b><%=DSP%></b></span>
        <span class="dm-chip">Station <b><%=ST%></b></span>
        <span class="dm-chip">Role <b>Dispatcher</b></span>
        <span class="dm-chip">Examples <b>2026 W32 – W34</b></span>
      </div>
    </div>
    <div class="dm-week">
      <label>Scorecard week</label>
      <select id="dmWeek" onchange="dmWeekChg()">
        <option value="W34" selected>W34 · Aug 16–22 2026</option>
        <option value="W33">W33</option>
        <option value="W32">W32</option>
      </select>
    </div>
  </div>

  <div class="dm-tabs">
    <button type="button" class="dm-tab active" onclick="dmTab('overview',this)">Overview &amp; Weights</button>
    <button type="button" class="dm-tab" onclick="dmTab('modules',this)">Training Modules</button>
    <button type="button" class="dm-tab" onclick="dmTab('resources',this)">Resources &amp; Links</button>
    <button type="button" class="dm-tab" onclick="dmTab('selfcheck',this)">Self-Check</button>
    <button type="button" class="dm-tab" onclick="dmTab('workbook',this)">Workbook</button>
  </div>

  <div class="dm-body">

    <!-- ═══ OVERVIEW ═══ -->
    <div id="pane-overview" class="dm-pane active">
      <div class="dm-ov-grid" style="width:100%">
        <div class="dm-card">
          <h2>Latest scorecard · <span id="dmWkLbl">W34</span></h2>
          <div class="dm-score" id="dmOvScore">89.1</div>
          <span class="dm-tier" id="dmOvTier">Fantastic Plus</span>
          <div class="dm-bar" title="Category weights">
            <i id="dmBarSafety" style="width:47.5%;background:#DC2626;float:left"></i>
            <i id="dmBarQuality" style="width:42.5%;background:#2563EB;float:left"></i>
            <i style="width:5%;background:#059669;float:left"></i>
            <i style="width:5%;background:#7C3AED;float:left"></i>
          </div>
          <div style="font-size:10px;color:#64748B">Red = Safety 47.5% · Blue = Delivery Quality 42.5% · Green = Pickup 5% · Purple = Team &amp; Fleet 5%</div>
          <div class="dm-callout">
            <b>Safety veto:</b> If Safety &amp; Compliance lands at <b>Great</b>, overall is capped at Great — no matter how strong Delivery Quality is.
          </div>
        </div>
        <div class="dm-card">
          <h2>Category weights (fixed)</h2>
          <div class="dm-weights">
            <div class="dm-wt safety"><b>47.5%</b><span>Safety &amp; Compliance</span></div>
            <div class="dm-wt quality"><b>42.5%</b><span>Delivery Quality</span></div>
            <div class="dm-wt"><b>5%</b><span>Pickup Quality</span></div>
            <div class="dm-wt"><b>5%</b><span>Team &amp; Fleet</span></div>
          </div>
          <h4 style="margin-top:12px">The clock (Module 0)</h4>
          <table>
            <tr><th>Item</th><th>When</th></tr>
            <tr><td>Performance week</td><td>Sunday → Saturday (7 days)</td></tr>
            <tr><td>Scorecard published</td><td>Wednesday (+4 days)</td></tr>
            <tr><td>Portal DSB / DNR detail</td><td>2 days behind scorecard</td></tr>
            <tr><td colspan="2"><b>Mon mistake → scorecard ~9 days later</b></td></tr>
          </table>
        </div>
      </div>
      <div class="dm-card" style="margin-top:12px;width:100%">
        <h2>DNK7 metrics snapshot · <span class="dmWkLbl">W34</span> (real data)</h2>
        <div class="dm-kpi-row" id="dmKpis"></div>
      </div>
    </div>

    <!-- ═══ MODULES ═══ -->
    <div id="pane-modules" class="dm-pane">
      <nav class="dm-mod-nav" id="dmModNav">
        <button type="button" class="dm-mod-btn active" data-mod="m0" onclick="dmMod('m0',this)">Module 0<small>The clock</small></button>
        <button type="button" class="dm-mod-btn" data-mod="m1" onclick="dmMod('m1',this)">Module 1<small>How scorecard is built</small></button>
        <button type="button" class="dm-mod-btn" data-mod="m2" onclick="dmMod('m2',this)">Module 2<small>Reading DPMO</small></button>
        <button type="button" class="dm-mod-btn" data-mod="m3" onclick="dmMod('m3',this)">Module 3<small>Safety 47.5%</small></button>
        <button type="button" class="dm-mod-btn" data-mod="m4" onclick="dmMod('m4',this)">Module 4<small>Delivery Quality 42.5%</small></button>
        <button type="button" class="dm-mod-btn" data-mod="m5" onclick="dmMod('m5',this)">Module 5<small>Pickup &amp; Fleet 10%</small></button>
        <button type="button" class="dm-mod-btn" data-mod="m6" onclick="dmMod('m6',this)">Module 6<small>Where numbers live</small></button>
        <button type="button" class="dm-mod-btn" data-mod="m7" onclick="dmMod('m7',this)">Module 7<small>Weekly cadence</small></button>
        <button type="button" class="dm-mod-btn" data-mod="m8" onclick="dmMod('m8',this)">Module 8<small>Disputes</small></button>
        <button type="button" class="dm-mod-btn" data-mod="m9" onclick="dmMod('m9',this)">Module 9<small>Eight traps</small></button>
        <button type="button" class="dm-mod-btn" data-mod="m10" onclick="dmMod('m10',this)">Module 10<small>Self-check</small></button>
        <button type="button" class="dm-mod-btn" data-mod="m11" onclick="dmMod('m11',this)">Module 11<small>One-hour workbook</small></button>
      </nav>
      <div class="dm-mod-body" id="dmModBody"></div>
    </div>

    <!-- ═══ RESOURCES ═══ -->
    <div id="pane-resources" class="dm-pane dm-res-wrap">
      <p style="font-size:13px;color:#475569;margin:0 0 8px">Every link opens in a new tab. Station <%=ST%> · DSP <%=DSP%>.</p>

      <div class="dm-res-grp">Amazon Portal — Performance</div>
      <div class="dm-res-grid">
        <a class="dm-link" target="_blank" rel="noopener" href="<%=P%>dsp_dashboard_overview"><b>Dashboard Overview (Scorecard)</b><span>Per-DA weekly scorecard, 6-week performance, thresholds.</span><span class="tag">Overview CSV source</span></a>
        <a class="dm-link" target="_blank" rel="noopener" href="<%=P%>dsp_safety"><b>Safety Dashboard</b><span>Camera events, OSS, intraday safety. Event-level dispute source.</span><span class="tag">Safety CSV source</span></a>
        <a class="dm-link" target="_blank" rel="noopener" href="<%=P%>dsp_quality"><b>Quality Dashboard</b><span>DCR overview, RTS detail, CDF feedback, supplemental quality.</span><span class="tag">Quality DCR CSV · CDF comments</span></a>
        <a class="dm-link" target="_blank" rel="noopener" href="<%=P%>dsp_delivery_concessions"><b>Delivery Concessions (DSB / DNR)</b><span>DSB behaviour detail — 2 days behind scorecard.</span><span class="tag">DSB Preview Data</span></a>
        <a class="dm-link" target="_blank" rel="noopener" href="<%=P%>dsp_mechanisms"><b>Mechanisms (ORCAS)</b><span>Per-DA daily ORCAS events — severe/moderate violations.</span></a>
        <a class="dm-link" target="_blank" rel="noopener" href="<%=P%>dsp_supp_reports"><b>Supplementary Reports</b><span>Weekly exports: DVIC, tenure, compliance, sentiment, scorecard PDF.</span><span class="tag">DSP Scorecard PDF</span></a>
      </div>

      <div class="dm-res-grp">Amazon Portal — Operations &amp; Workforce</div>
      <div class="dm-res-grid">
        <a class="dm-link" target="_blank" rel="noopener" href="https://logistics.amazon.com/operations/execution/itineraries"><b>Route Itineraries</b><span>Live stop progress, pace, rescue decisions.</span></a>
        <a class="dm-link" target="_blank" rel="noopener" href="https://logistics.amazon.com/workforce?pageId=da_console_associates&companyId=<%=CO%>&station=<%=ST%>"><b>DA Console — Associates</b><span>Roster, transporter IDs, qualifications.</span></a>
        <a class="dm-link" target="_blank" rel="noopener" href="https://logistics.amazon.com/fleet-management/#vehicles"><b>Fleet — My Vehicles</b><span>VIN, provider, status — van assignment for safety disputes.</span></a>
      </div>

      <div class="dm-res-grp">Weekly files — what each export actually holds</div>
      <div class="dm-res-grid">
        <a class="dm-link" href="javascript:void(0)" onclick="dmTab('modules',document.querySelector('.dm-tab:nth-child(2)'));dmMod('m6',document.querySelector('[data-mod=m6]'))"><b>DSP Overview Dashboard .csv</b><span>One row per DA: scores, safety rates, CDF, DSB, POD, PSB, weights. <em>No Delivery Completion.</em></span></a>
        <a class="dm-link" href="javascript:void(0)" onclick="dmTab('modules',document.querySelector('.dm-tab:nth-child(2)'));dmMod('m6',document.querySelector('[data-mod=m6]'))"><b>Quality DCR .csv</b><span>Real Delivery Completion detail — controllable vs exempt returns, 21 RTS reason columns.</span></a>
        <a class="dm-link" href="javascript:void(0)" onclick="dmTab('modules',document.querySelector('.dm-tab:nth-child(2)'));dmMod('m6',document.querySelector('[data-mod=m6]'))"><b>Safety Dashboard .csv</b><span>Individual camera events — not rates. Dispute IDs and video links.</span></a>
        <a class="dm-link" href="javascript:void(0)" onclick="dmTab('modules',document.querySelector('.dm-tab:nth-child(2)'));dmMod('m6',document.querySelector('[data-mod=m6]'))"><b>DSP Scorecard .pdf</b><span>Official station-level result — tiers, weights, compliance gates.</span></a>
      </div>

      <div class="dm-res-grp">Published metric guides (confirm thresholds before quoting)</div>
      <div class="dm-res-grid">
        <div class="dm-link" style="cursor:default"><b>DSB Toolkit</b><span>Rev. Jul 29 2026 — six DSB behaviours, exemptions, dispute cases.</span><span class="tag">Amazon internal</span></div>
        <div class="dm-link" style="cursor:default"><b>CDF Metric Guide (AMZL/RSR)</b><span>Eff. Apr 30 2025 — Fantastic ≤980 DSP · ≤1,160 DA DPMO.</span><span class="tag">Amazon internal</span></div>
        <div class="dm-link" style="cursor:default"><b>Pickup Success Behaviors Guide</b><span>Rev. Jul 29 2026 — PSB defects, rescue trap, contact compliance.</span><span class="tag">Amazon internal</span></div>
      </div>

      <div class="dm-res-grp">MVPx internal</div>
      <div class="dm-res-grid">
        <a class="dm-link" href="PortalResources.jsp"><b>Amazon Portal Links</b><span>Full operator reference — same portal URLs with MVPx landing notes.</span></a>
        <a class="dm-link" href="BridgeHelp.jsp"><b>Bridge Loading Guide</b><span>How weekly CSVs load into MVPx tables.</span></a>
        <a class="dm-link" href="PredictScorecard.jsp"><b>Predict Scorecard</b><span>Live scorecard tooling inside MVPx.</span></a>
      </div>
    </div>

    <!-- ═══ SELF-CHECK (sample 3 of 12) ═══ -->
    <div id="pane-selfcheck" class="dm-pane">
      <p style="font-size:13px;color:#475569">Sample: 3 of 12 questions. Full set in Module 10 on final build.</p>
      <div class="dm-q" onclick="this.classList.toggle('open')">
        <b>1. Safety category = Great, Delivery Quality perfect. Best possible overall standing?</b>
        <div class="ans"><b>Great</b> — safety veto caps overall at the Safety tier maximum.</div>
      </div>
      <div class="dm-q" onclick="this.classList.toggle('open')">
        <b>2. CDF DPMO 3,164 at ~93,500 packages/week — roughly how many complaints?</b>
        <div class="ans"><b>~296</b> — 3,164 × 93,500 ÷ 1,000,000. At low volume, use raw defect count instead.</div>
      </div>
      <div class="dm-q" onclick="this.classList.toggle('open')">
        <b>3. Overview CSV shows DC DPMO 0 for all 94 DAs. Good week?</b>
        <div class="ans"><b>No conclusion</b> — Delivery Completion is station-level; real detail is in Quality DCR (W34 station DC = 2,020 DPMO).</div>
      </div>
      <div class="dm-stub">+ 9 more questions in final build (Modules 10)</div>
    </div>

    <!-- ═══ WORKBOOK (sample 2 of 9) ═══ -->
    <div id="pane-workbook" class="dm-pane">
      <p style="font-size:13px;color:#475569">Sample exercises with verified DNK7 answers. Full workbook in Module 11.</p>
      <div class="dm-card" style="margin-bottom:10px">
        <h2>Exercise 3 — Sign &amp; Signal</h2>
        <p>1 red light, 3 severe stop signs, 1 illegal U-turn, over 200 trips. Calculate the rate.</p>
        <pre>(Red×10 + Severe×5 + U-turn) ÷ Trips × 100
= (10 + 15 + 1) ÷ 200 × 100 = <b>13.0</b></pre>
      </div>
      <div class="dm-card">
        <h2>Exercise 7 — Volume sensitivity</h2>
        <p>Two drivers, one CDF defect each: 284 vs 1,495 packages.</p>
        <pre>284 pkg  → 3,520 DPMO (Bronze)
1,495 pkg → 672 DPMO (Platinum)
Coach on <b>second consecutive</b> flagged week, not DPMO alone.</pre>
      </div>
      <div class="dm-stub">+ 7 more exercises in final build (Module 11)</div>
    </div>

  </div>
</div>

<script>
var DM_WEEKS = {
  W34: { score:'89.1', tier:'Fantastic Plus',
    kpis:[
      ['Safety composite','Great','tier'],['Speeding','2.0','/100 trips'],['Sign/Signal','2.0','/100 trips'],
      ['Distraction','0.4','/100 trips'],['CED','0','zero — protect'],['DSB','182 DPMO','≤233 Fantastic'],
      ['Delivery Completion','2,020 DPMO','station-level'],['CDF','771 DPMO','≤980 Fantastic'],
      ['POD','99.54%','rising trend'],['PSB','0.00','17 DAs scored'],['Packages/wk','~93,527','DPMO denominator']
    ]},
  W33: { score:'—', tier:'(load from upload)', kpis:[['DSB','—',''],['CDF','—',''],['Packages','—','']]},
  W32: { score:'—', tier:'(load from upload)', kpis:[['DC controllable','875 DPMO','76 returns'],['Exempt returns','70%','180 of 256']] }
};

var DM_MODULES = {
  m0: { title:'Module 0 — The clock you are actually working against',
    goal:'You know when the week starts, when the scorecard lands, and why waiting for it is already too late.',
    html:'<p>The scorecard is a <b>receipt, not a control</b>. A Monday mistake appears on the scorecard ~9 days later — by then the driver has run eight more routes.</p>'
      +'<h4>Scorecard week</h4><table><tr><th>Item</th><th>When</th><th>Verified</th></tr>'
      +'<tr><td>Performance week</td><td>Sunday → Saturday</td><td>W34 = Aug 16–22 2026</td></tr>'
      +'<tr><td>Scorecard published</td><td>Wednesday (+4 days)</td><td>Previous Sun–Sat</td></tr>'
      +'<tr><td>Portal DSB/DNR</td><td>2 days behind scorecard</td><td>Amazon DSB Toolkit</td></tr></table>'
      +'<p>Three risky driving events in 10 hours <b>pause the route automatically</b> — that counter runs inside a single shift; weekly review cannot see it.</p>' },
  m1: { title:'Module 1 — How the scorecard is built',
    goal:'Explain overall score composition, the safety veto, and why DA weights differ from station weights.',
    html:'<h4>Four weighted categories</h4><p>Safety 47.5% · Delivery Quality 42.5% · Pickup 5% · Team &amp; Fleet 5%</p>'
      +'<h4>Two tier ladders</h4><table><tr><th>Level</th><th>Ladder</th><th>Where</th></tr>'
      +'<tr><td>Station/DSP</td><td>Fantastic Plus → … → Poor</td><td>Scorecard PDF — DNK7 W34 = 89.1 F+</td></tr>'
      +'<tr><td>DA</td><td>Platinum → Gold → Silver → Bronze</td><td>Overview CSV — 93/94 Platinum W34</td></tr></table>'
      +'<div class="dm-callout"><b>Safety veto:</b> Safety at Great → overall capped at Great.</div>'
      +'<h4>DA weight profiles — W34</h4><table><tr><th>Profile</th><th>DAs</th><th>Speeding</th><th>CED/DC/DSB</th><th>POD</th><th>PSB</th></tr>'
      +'<tr><td>Standard</td><td>73</td><td>13.2%</td><td>12.6% each</td><td>3.1%</td><td>0%</td></tr>'
      +'<tr><td>Has pickups</td><td>17</td><td>12.5%</td><td>11.9% each</td><td>2.9%</td><td>5.5%</td></tr>'
      +'<tr><td>No safety data</td><td>4</td><td>0%</td><td>26.7% each</td><td>6.5%</td><td>0%</td></tr></table>' },
  m2: { title:'Module 2 — Reading DPMO', goal:'Convert DPMO to package counts; explain low-volume noise.',
    html:'<pre>DPMO = (defects ÷ opportunities) × 1,000,000\ndefects = DPMO × packages ÷ 1,000,000</pre>'
      +'<p>At ~93,500 pkg/wk: <b>100 DPMO ≈ 9 packages</b>. Under 500 pkg/week, use raw defect count.</p>'
      +'<h4>One defect, two DPMOs (W34 CDF)</h4><table><tr><th>DA</th><th>Packages</th><th>CDF DPMO</th><th>Tier</th></tr>'
      +'<tr><td>Prince Brandon Onukogu</td><td>284</td><td>3,520</td><td>Bronze</td></tr>'
      +'<tr><td>Alejandro Carmona calderon</td><td>1,495</td><td>672</td><td>Platinum</td></tr></table>' },
  m3: { title:'Module 3 — Safety & Compliance (47.5%)', goal:'Five scored metrics, per-100-trips rates, dispatch levers.',
    html:'<table><tr><th>Metric</th><th>Weight</th><th>W34</th><th>Triggers</th></tr>'
      +'<tr><td>Seatbelt-Off</td><td>11.7%</td><td>1.2</td><td>Unbelted while moving</td></tr>'
      +'<tr><td>Speeding</td><td>11.7%</td><td>2.0</td><td>10+ mph over 5s or &gt;85 mph</td></tr>'
      +'<tr><td>Sign/Signal</td><td>11.7%</td><td>2.0</td><td>Red 10×, severe stop 5×, rolling 1×</td></tr>'
      +'<tr><td>Distractions</td><td>7.5%</td><td>0.4</td><td>Phone in hand</td></tr>'
      +'<tr><td>Following Distance</td><td>5.0%</td><td>0.4</td><td>Tailgating</td></tr></table>'
      +'<p><b>Corrections vs MVPG manual:</b> seatbelt = 1× (not 4×); severe stop = 5× (not 4×).</p>'
      +'<div class="dm-stub">Full Module 3 text: 11 W34 events, passenger seatbelt trap, rescue trigger at 18:00, dispute pattern — in final build.</div>' },
  m4: { title:'Module 4 — Delivery Quality (42.5%)', goal:'Five metrics, who controls each, DC is yours.',
    html:'<table><tr><th>Metric</th><th>Weight</th><th>W34</th><th>Controller</th></tr>'
      +'<tr><td>CED</td><td>11.3%</td><td>0</td><td>Driver — never break</td></tr>'
      +'<tr><td>DSB</td><td>11.3%</td><td>182</td><td>Driver (≤233 Fantastic)</td></tr>'
      +'<tr><td>Delivery Completion</td><td>11.3%</td><td>2,020</td><td><b>Station / you</b></td></tr>'
      +'<tr><td>CDF</td><td>5.7%</td><td>771</td><td>Driver (≤980 DSP)</td></tr>'
      +'<tr><td>POD</td><td>2.8%</td><td>99.54%</td><td>Driver — early warning for DSB</td></tr></table>'
      +'<div class="dm-stub">Full Module 4: W32 DC decomposition, DCR% vs DC DPMO, call-before-improvising — in final build.</div>' },
  m5: { title:'Module 5 — Pickup, Team & Fleet (10%)', goal:'PSB breaks, rescue trap, fleet execution.',
    html:'<p><b>PSB</b> — rate per 100 pickup stops; Fantastic &lt;10. DNK7 W34 = 0.00. Only 17/94 DAs scored.</p>'
      +'<p><b>Rescue trap:</b> pickup stops must be reassigned in Station Command Center — verbal handoff does not move them.</p>'
      +'<div class="dm-stub">Full PSB six behaviours table + Team &amp; Fleet — in final build.</div>' },
  m6: { title:'Module 6 — Where the numbers live', goal:'Find any metric without asking; know which file lacks what.',
    html:'<table><tr><th>File</th><th>Contains</th><th>Does NOT contain</th></tr>'
      +'<tr><td>Overview CSV</td><td>Per-DA scores, safety, CDF, DSB, weights</td><td>Delivery Completion (always 0 per DA)</td></tr>'
      +'<tr><td>Quality DCR CSV</td><td>DC detail, controllable returns, 21 RTS columns</td><td>Safety, CDF, DSB</td></tr>'
      +'<tr><td>Safety CSV</td><td>Event list, dispute, video link</td><td>Rates</td></tr>'
      +'<tr><td>Scorecard PDF</td><td>Station tiers, weights, gates</td><td>Per-driver detail</td></tr></table>'
      +'<p>Portal only: DSB behaviour per defect · CDF customer comments · both 2 days behind scorecard.</p>' },
  m7: { title:'Module 7 — The weekly cadence', goal:'What to do when the scorecard lands; daily control plan.',
    html:'<h4>When scorecard lands</h4><ol><li>Compliance gates (BOC, CAS)</li><li>Safety tier</li><li>DSB, DC, CDF</li><li>Cross-check rates vs raw counts</li><li>Decompose DC in Quality DCR</li><li>Portal behaviour detail</li><li>Disputes before window closes</li></ol>'
      +'<h4>Daily control</h4><table><tr><th>When</th><th>Do</th></tr>'
      +'<tr><td>Morning</td><td>Overnight safety, yesterday RTS, label supply</td></tr>'
      +'<tr><td>Midday</td><td>Pace, safety counter, intervene below 99.2%</td></tr>'
      +'<tr><td>17:00–18:00</td><td>Rescue decisions — not on request</td></tr>'
      +'<tr><td>End of day</td><td>Debrief, written station message, plan tomorrow</td></tr></table>' },
  m8: { title:'Module 8 — Disputes', goal:'Winnable grounds and documentation needed.',
    html:'<p>W34: 5 disputes filed, <b>5 approved</b>. Map-error pattern: same driver, van, day on speeding.</p>'
      +'<div class="dm-stub">Full dispute table by metric (Safety, DSB, CDF, PSB) — in final build.</div>' },
  m9: { title:'Module 9 — Eight traps', goal:'Avoid losing credibility in month one.',
    html:'<ol><li>Coaching off a single week</li><li>Reading DPMO without volume</li><li>Believing export over count (258 vs 18 events)</li>'
      +'<li>Coaching a number not a behaviour</li><li>Confusing exempt vs controllable returns</li>'
      +'<li>Coaching automatic exemptions</li><li>Treating a place as a person</li><li>Assuming scorecard is whole picture</li></ol>' },
  m10: { title:'Module 10 — Self-check', goal:'12 questions — answer before opening.',
    html:'<p>Use the <b>Self-Check</b> top tab (sample shows 3 of 12). Full question bank in final build.</p>' },
  m11: { title:'Module 11 — One-hour workbook', goal:'Exercises with verified DNK7 answer key.',
    html:'<p>Use the <b>Workbook</b> top tab (sample shows 2 of 9). All answers derived from W32–W34 real data.</p>'
      +'<p><b>Corrections documented:</b> stop sign 5×, seatbelt 1×, CDF 980/1160, DCR% ≠ DC DPMO, safety 47.5% vs CDF 5.7%.</p>' }
};

function dmTab(id, btn) {
  document.querySelectorAll('.dm-pane').forEach(function(p){ p.classList.remove('active'); });
  document.querySelectorAll('.dm-tab').forEach(function(t){ t.classList.remove('active'); });
  document.getElementById('pane-' + id).classList.add('active');
  if (btn) btn.classList.add('active');
}
function dmMod(id, btn) {
  document.querySelectorAll('.dm-mod-btn').forEach(function(b){ b.classList.remove('active'); });
  if (btn) btn.classList.add('active');
  var m = DM_MODULES[id];
  document.getElementById('dmModBody').innerHTML =
    '<h3>' + m.title + '</h3><div class="goal">By the end: ' + m.goal + '</div>' + m.html;
}
function dmWeekChg() {
  var w = document.getElementById('dmWeek').value;
  var d = DM_WEEKS[w] || DM_WEEKS.W34;
  document.getElementById('dmOvScore').textContent = d.score;
  document.getElementById('dmOvTier').textContent = d.tier;
  document.querySelectorAll('.dmWkLbl').forEach(function(el){ el.textContent = w; });
  document.getElementById('dmWkLbl').textContent = w;
  var h = '';
  (d.kpis || []).forEach(function(k){
    h += '<div class="dm-kpi"><div class="l">' + k[0] + '</div><div class="v">' + k[1] + '</div>'
       + (k[2] ? '<div class="t">' + k[2] + '</div>' : '') + '</div>';
  });
  document.getElementById('dmKpis').innerHTML = h;
}
dmMod('m0', document.querySelector('[data-mod=m0]'));
dmWeekChg();
</script>

<%@ include file="includeFooter.jsp"%>
