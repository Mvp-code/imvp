<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %><!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1.0"/>
<title>MVPx &mdash; DSP Operations Platform</title>
<style>
:root {
  --blue:       #2563eb;
  --blue-dark:  #1d4ed8;
  --blue-light: #eff6ff;
  --navy:       #0f172a;
  --navy-mid:   #1e293b;
  --slate:      #64748b;
  --border:     #e2e8f0;
  --bg:         #f8fafc;
  --green:      #15803D;
  --font:       'Segoe UI', Arial, sans-serif;
  --status-ok-fg: #15803D; --status-ok-bg: #E7F6EE;
  --status-warn-fg: #B45309; --status-warn-bg: #FBF1E2;
  --status-action-fg: #C62828; --status-action-bg: #FCEBEB;
  --status-escalation-fg: #991B1B; --status-escalation-bg: #FEE2E2; --status-escalation-border: #FCA5A5;
  --status-info-fg: #1D4ED8; --status-info-bg: #EFF4FF;
}
*, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
html { scroll-behavior: smooth; }
body { font-family: var(--font); color: var(--navy-mid); background: #fff; font-size: 14px; line-height: 1.6; }
a { text-decoration: none; color: inherit; }

/* ── NAV ──────────────────────────────────────────────── */
.nav {
  position: sticky; top: 0; z-index: 100;
  background: rgba(255,255,255,.96);
  backdrop-filter: blur(8px);
  border-bottom: 1px solid var(--border);
  padding: 0 5%;
  height: 60px;
  display: flex; align-items: center; justify-content: space-between;
  gap: 24px;
}
.nav-logo {
  display: flex; align-items: center; gap: 10px; flex-shrink: 0; text-decoration: none;
}
.nav-logo img { height: 40px; width: auto; display: block; }
.nav-logo-tag { font-size: 10px; font-weight: 700; color: var(--slate); letter-spacing: .8px; text-transform: uppercase; }
.nav-links { display: flex; gap: 28px; list-style: none; }
.nav-links a { font-size: 13px; font-weight: 500; color: var(--slate); transition: color .15s; }
.nav-links a:hover { color: var(--blue); }
.nav-right { display: flex; align-items: center; gap: 10px; flex-shrink: 0; }
.btn-nav-login {
  padding: 7px 18px; border: 1.5px solid var(--border);
  background: #fff; color: var(--navy-mid);
  border-radius: 7px; font-size: 13px; font-weight: 600; cursor: pointer;
  transition: all .15s;
}
.btn-nav-login:hover { border-color: var(--blue); color: var(--blue); }
.btn-nav-onboard {
  padding: 7px 16px; border: 1.5px solid var(--blue); color: var(--blue);
  border-radius: 7px; font-size: 13px; font-weight: 700; cursor: pointer;
  text-decoration: none; display: inline-flex; align-items: center; gap: 5px;
  transition: all .15s;
}
.btn-nav-onboard:hover { background: var(--blue); color: #fff; }
.btn-nav-signup {
  padding: 7px 18px; background: var(--blue); color: #fff;
  border: none; border-radius: 7px; font-size: 13px; font-weight: 700; cursor: pointer;
  transition: background .15s;
}
.btn-nav-signup:hover { background: var(--blue-dark); }

/* ── HERO ─────────────────────────────────────────────── */
.hero {
  background: linear-gradient(135deg, var(--navy) 0%, #1e3a5f 55%, #0f2d5e 100%);
  padding: 80px 5% 70px;
  text-align: center;
}
.hero-badge {
  display: inline-flex; align-items: center; gap: 6px;
  background: rgba(37,99,235,.2); color: #93c5fd;
  border: 1px solid rgba(37,99,235,.35); border-radius: 20px;
  padding: 4px 14px; font-size: 11px; font-weight: 700; letter-spacing: .3px;
  margin-bottom: 20px;
}
.hero h1 {
  font-size: 42px; font-weight: 900; color: #fff; line-height: 1.15;
  letter-spacing: -.5px; margin-bottom: 18px;
}
.hero h1 em { font-style: normal; color: #60a5fa; }
.hero-sub { font-size: 16px; color: #94a3b8; line-height: 1.7; margin-bottom: 32px; max-width: 560px; margin-left: auto; margin-right: auto; }
.hero-cta { display: flex; gap: 12px; flex-wrap: wrap; justify-content: center; }
.btn-hero-primary {
  padding: 13px 28px; background: var(--blue); color: #fff;
  border: none; border-radius: 8px; font-size: 14px; font-weight: 700; cursor: pointer;
  transition: background .15s;
}
.btn-hero-primary:hover { background: var(--blue-dark); }
.btn-hero-secondary {
  padding: 13px 28px; background: rgba(255,255,255,.08); color: #fff;
  border: 1px solid rgba(255,255,255,.2); border-radius: 8px;
  font-size: 14px; font-weight: 600; cursor: pointer; transition: background .15s;
}
.btn-hero-secondary:hover { background: rgba(255,255,255,.14); }

/* ── LOGO STRIP ───────────────────────────────────────── */
.logo-strip {
  background: var(--bg); border-top: 1px solid var(--border); border-bottom: 1px solid var(--border);
  padding: 18px 5%; display: flex; align-items: center;
}
.logo-strip-label { font-size: 11px; font-weight: 700; color: var(--slate); text-transform: uppercase; letter-spacing: .8px; white-space: nowrap; margin-right: 32px; flex-shrink: 0; }
.logo-strip-items { display: flex; gap: 16px; align-items: center; flex-wrap: wrap; }
.logo-pill {
  font-size: 12px; font-weight: 700; color: #94a3b8; letter-spacing: -.3px;
  background: #fff; border: 1px solid var(--border); border-radius: 6px;
  padding: 5px 14px;
}

/* ── FEATURES ─────────────────────────────────────────── */
.features { padding: 80px 5%; background: #fff; }
.section-header { text-align: center; margin-bottom: 52px; }
.section-eyebrow { font-size: 12px; font-weight: 700; color: var(--blue); text-transform: uppercase; letter-spacing: 1px; margin-bottom: 10px; }
.section-title { font-size: 30px; font-weight: 900; color: var(--navy); letter-spacing: -.3px; margin-bottom: 12px; }
.section-sub { font-size: 15px; color: var(--slate); max-width: 500px; margin: 0 auto; line-height: 1.7; }

.feature-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 24px; }
.feature-card {
  background: var(--bg); border: 1px solid var(--border); border-radius: 14px;
  padding: 28px; transition: box-shadow .2s, transform .2s;
}
.feature-card:hover { box-shadow: 0 8px 24px rgba(0,0,0,.08); transform: translateY(-2px); }
.feature-icon {
  width: 44px; height: 44px; border-radius: 11px; background: var(--blue-light);
  display: flex; align-items: center; justify-content: center;
  font-size: 15px; font-weight: 800; color: var(--blue);
  margin-bottom: 16px; letter-spacing: -.5px;
}
.feature-card h3 { font-size: 15px; font-weight: 700; color: var(--navy); margin-bottom: 8px; }
.feature-card p { font-size: 13px; color: var(--slate); line-height: 1.65; }
.feature-tag {
  display: inline-block; margin-top: 14px;
  font-size: 10px; font-weight: 700; color: var(--blue);
  background: var(--blue-light); border-radius: 20px; padding: 2px 10px;
}
.feature-tag.soon { color: #92400e; background: #fef3c7; }

/* ── HOW IT WORKS ─────────────────────────────────────── */
.how { padding: 80px 5%; background: var(--bg); }
.steps { display: grid; grid-template-columns: repeat(4, 1fr); gap: 0; position: relative; margin-top: 52px; }
.steps::before {
  content: ''; position: absolute; top: 28px; left: 12.5%; right: 12.5%;
  height: 2px; background: var(--border); z-index: 0;
}
.step { text-align: center; padding: 0 16px; position: relative; z-index: 1; }
.step-num {
  width: 56px; height: 56px; border-radius: 50%;
  background: var(--blue); color: #fff;
  font-size: 18px; font-weight: 900;
  display: flex; align-items: center; justify-content: center;
  margin: 0 auto 16px; box-shadow: 0 0 0 6px #fff, 0 0 0 8px var(--border);
}
.step h3 { font-size: 14px; font-weight: 700; color: var(--navy); margin-bottom: 8px; }
.step p { font-size: 12px; color: var(--slate); line-height: 1.6; }

/* ── METRICS BAND ─────────────────────────────────────── */
.metrics-band {
  background: var(--navy); padding: 52px 5%;
  display: flex; justify-content: space-around; gap: 24px; flex-wrap: wrap;
}
.metric-item { text-align: center; }
.metric-val { font-size: 38px; font-weight: 900; color: #fff; line-height: 1; }
.metric-val span { color: #60a5fa; }
.metric-lbl { font-size: 12px; color: #94a3b8; margin-top: 6px; }

/* ── ONBOARDING SECTION ───────────────────────────────── */
.onboard { padding: 80px 5%; background: #fff; }
.onboard-inner {
  max-width: 900px; margin: 0 auto;
  display: grid; grid-template-columns: 1fr 1fr; gap: 60px; align-items: center;
}
.onboard-text h2 { font-size: 28px; font-weight: 900; color: var(--navy); margin-bottom: 14px; letter-spacing: -.3px; }
.onboard-text p { font-size: 14px; color: var(--slate); line-height: 1.7; margin-bottom: 24px; }
.onboard-bullets { list-style: none; display: flex; flex-direction: column; gap: 10px; margin-bottom: 28px; }
.onboard-bullets li { display: flex; align-items: flex-start; gap: 10px; font-size: 13px; color: var(--slate); }
.onboard-bullets li::before { content: '\2713'; font-weight: 900; color: var(--green); flex-shrink: 0; margin-top: 1px; font-size: 13px; }
.btn-gform {
  display: inline-flex; align-items: center; gap: 10px;
  padding: 14px 28px; background: var(--blue); color: #fff;
  border: none; border-radius: 9px; font-size: 15px; font-weight: 700;
  cursor: pointer; transition: background .15s; text-decoration: none;
}
.btn-gform:hover { background: var(--blue-dark); color: #fff; }
.btn-gform-note { font-size: 11px; color: var(--slate); margin-top: 10px; }

.onboard-visual {
  background: var(--bg); border: 1px solid var(--border);
  border-radius: 16px; padding: 32px; display: flex; flex-direction: column; gap: 16px;
}
.onboard-visual-title { font-size: 13px; font-weight: 700; color: var(--slate); text-transform: uppercase; letter-spacing: .5px; margin-bottom: 4px; }
.onboard-step-row {
  display: flex; align-items: flex-start; gap: 14px;
}
.onboard-step-circle {
  width: 32px; height: 32px; border-radius: 50%; background: var(--blue);
  color: #fff; font-size: 13px; font-weight: 800;
  display: flex; align-items: center; justify-content: center; flex-shrink: 0;
}
.onboard-step-body h4 { font-size: 13px; font-weight: 700; color: var(--navy); }
.onboard-step-body p { font-size: 12px; color: var(--slate); margin-top: 2px; }

/* ── FOOTER ───────────────────────────────────────────── */
.footer {
  background: var(--navy); padding: 40px 5%;
  display: flex; align-items: center; justify-content: space-between;
  gap: 20px; flex-wrap: wrap;
}
.footer-logo { font-size: 18px; font-weight: 900; color: #fff; }
.footer-logo span { color: #60a5fa; }
.footer-links { display: flex; gap: 24px; }
.footer-links a { font-size: 12px; color: #64748b; transition: color .15s; }
.footer-links a:hover { color: #94a3b8; }
.footer-copy { font-size: 11px; color: #475569; }

/* ── LOGIN MODAL ──────────────────────────────────────── */
.modal-overlay {
  display: none; position: fixed; inset: 0;
  background: rgba(0,0,0,.5); z-index: 500;
  align-items: center; justify-content: center;
  backdrop-filter: blur(4px);
}
.modal-overlay.open { display: flex; }
.modal-box {
  background: #fff; border-radius: 16px;
  width: min(420px, 94vw); padding: 36px;
  box-shadow: 0 24px 60px rgba(0,0,0,.2);
  position: relative;
}
.modal-box h2 { font-size: 20px; font-weight: 900; color: var(--navy); margin-bottom: 6px; }
.modal-box .modal-sub { font-size: 13px; color: var(--slate); margin-bottom: 28px; }
.modal-close {
  position: absolute; top: 16px; right: 16px;
  background: var(--bg); border: none; border-radius: 50%;
  width: 30px; height: 30px; font-size: 16px; cursor: pointer;
  display: flex; align-items: center; justify-content: center; color: var(--slate);
}
.modal-close:hover { background: var(--border); }
.modal-form { display: flex; flex-direction: column; gap: 16px; }
.f-group { display: flex; flex-direction: column; gap: 4px; }
.f-group label { font-size: 11px; font-weight: 700; color: #374151; }
.f-group input {
  padding: 11px 12px; border: 1px solid #d1d5db; border-radius: 8px;
  font-size: 14px; font-family: var(--font); color: var(--navy-mid); background: #fff;
  transition: border-color .15s;
}
.f-group input:focus { outline: none; border-color: var(--blue); box-shadow: 0 0 0 3px rgba(37,99,235,.1); }
.btn-modal-login {
  padding: 12px; background: var(--blue); color: #fff;
  border: none; border-radius: 8px; font-size: 14px; font-weight: 700;
  cursor: pointer; font-family: var(--font); transition: background .15s;
}
.btn-modal-login:hover { background: var(--blue-dark); }
.modal-error {
  font-size: 12px; color: var(--status-escalation-fg); background: var(--status-escalation-bg);
  border: 1px solid var(--status-escalation-border); border-radius: 6px; padding: 8px 12px; display: none;
}
.modal-error.show { display: block; }
.modal-divider { border: none; border-top: 1px solid var(--border); }
.modal-footer-link { text-align: center; font-size: 12px; color: var(--slate); }
.modal-footer-link a { color: var(--blue); font-weight: 600; }

/* ── RESPONSIVE ───────────────────────────────────────── */
@media (max-width: 900px) {
  .hero h1 { font-size: 30px; }
  .feature-grid { grid-template-columns: repeat(2, 1fr); }
  .steps { grid-template-columns: repeat(2, 1fr); gap: 32px; }
  .steps::before { display: none; }
  .onboard-inner { grid-template-columns: 1fr; gap: 36px; }
  .nav-links { display: none; }
}
@media (max-width: 600px) {
  .hero h1 { font-size: 26px; }
  .feature-grid { grid-template-columns: 1fr; }
  .metrics-band { padding: 40px 5%; }
  .metric-val { font-size: 28px; }
  .footer { flex-direction: column; text-align: center; }
}
</style>
</head>
<body>

<!-- NAV -->
<nav class="nav">
  <a href="#" class="nav-logo">
    <img src="../images/logo/logo_1.jpeg" alt="MVP Logistics">
    <span class="nav-logo-tag">DSP PLATFORM</span>
  </a>
  <ul class="nav-links">
    <li><a href="#features">Features</a></li>
    <li><a href="#how">How It Works</a></li>
    <li><a href="#onboard">Get Started</a></li>
  </ul>
  <div class="nav-right">
    <a href="DAApplicationForm.jsp" class="btn-nav-onboard">Apply Now</a>
    <button class="btn-nav-login" onclick="openLogin()">Log In</button>
    <button class="btn-nav-signup" onclick="scrollTo('onboard')">Request Access</button>
  </div>
</nav>

<!-- HERO -->
<section class="hero">
  <div class="hero-badge">Built for Amazon DSP Operators</div>
  <h1>Run Your DSP<br><em>Smarter, Faster,</em><br>With Less Clicks.</h1>
  <p class="hero-sub">MVPx is the all-in-one operations platform for Amazon DSP owners &mdash; scheduling, driver management, fleet, scorecard analytics, and two-way SMS in one place.</p>
  <div class="hero-cta">
    <button class="btn-hero-primary" onclick="openLogin()">Go to Dashboard</button>
    <button class="btn-hero-secondary" onclick="scrollTo('onboard')">Request Access</button>
  </div>
</section>

<!-- LOGO STRIP -->
<div class="logo-strip">
  <div class="logo-strip-label">Integrated with</div>
  <div class="logo-strip-items">
    <div class="logo-pill">Amazon Logistics</div>
    <div class="logo-pill">Twilio SMS</div>
    <div class="logo-pill">Netradyne</div>
    <div class="logo-pill">ORCAS</div>
    <div class="logo-pill">DVIC</div>
    <div class="logo-pill">ADP Payroll</div>
  </div>
</div>

<!-- FEATURES -->
<section class="features" id="features">
  <div class="section-header">
    <div class="section-eyebrow">Platform Features</div>
    <div class="section-title">Everything your station needs in one place</div>
    <div class="section-sub">Stop juggling spreadsheets, texts, and Amazon portal tabs. MVPx brings it all together.</div>
  </div>
  <div class="feature-grid">
    <div class="feature-card">
      <div class="feature-icon">DSH</div>
      <h3>Live Operations Dashboard</h3>
      <p>See today's route status, DA checkin/checkout counts, open incidents, and FICO score &mdash; all on one screen the moment you log in.</p>
      <span class="feature-tag">Available now</span>
    </div>
    <div class="feature-card">
      <div class="feature-icon">SCH</div>
      <h3>Smart Scheduling</h3>
      <p>Build weekly schedules with DA availability built in. Get alerts before you post when a day is understaffed or a driver hits overtime.</p>
      <span class="feature-tag">Available now</span>
    </div>
    <div class="feature-card">
      <div class="feature-icon">SMS</div>
      <h3>Two-Way SMS Chat</h3>
      <p>Send confirmations and receive replies in a per-driver inbox. No more missed callouts buried in your personal texts. Powered by Twilio.</p>
      <span class="feature-tag soon">Coming soon</span>
    </div>
    <div class="feature-card">
      <div class="feature-icon">SCR</div>
      <h3>Scorecard and Safety Analytics</h3>
      <p>Upload your weekly Amazon scorecard CSV and instantly see FICO trends, ORCAS events, POD rates, and safety metrics per driver over time.</p>
      <span class="feature-tag">Available now</span>
    </div>
    <div class="feature-card">
      <div class="feature-icon">PWA</div>
      <h3>Driver Mobile App</h3>
      <p>Drivers open a link on their phone &mdash; no app store needed. They see their schedule, scorecard, and can submit callouts directly.</p>
      <span class="feature-tag soon">Coming soon</span>
    </div>
    <div class="feature-card">
      <div class="feature-icon">FLT</div>
      <h3>Fleet Management</h3>
      <p>Track every van &mdash; VIN, registration expiry, ownership type, operational status, and DVIC pre-trip inspection results synced from Amazon.</p>
      <span class="feature-tag">Available now</span>
    </div>
    <div class="feature-card">
      <div class="feature-icon">UPL</div>
      <h3>Smart File Upload</h3>
      <p>Drop any Amazon report file &mdash; schedules, itineraries, ORCAS, tenure reports &mdash; and MVPx auto-detects the type and loads it to the right table.</p>
      <span class="feature-tag soon">Coming soon</span>
    </div>
    <div class="feature-card">
      <div class="feature-icon">INC</div>
      <h3>Incident and OSHA Tracking</h3>
      <p>Log vehicle incidents and OSHA events with photos and signatures. Full audit trail for coaching conversations and compliance reviews.</p>
      <span class="feature-tag">Available now</span>
    </div>
    <div class="feature-card">
      <div class="feature-icon">CON</div>
      <h3>Contacts and Resources</h3>
      <p>One page for every contact your team needs &mdash; fleet, tow, insurance, health, incident response, and Amazon ops &mdash; organized and searchable.</p>
      <span class="feature-tag soon">Coming soon</span>
    </div>
  </div>
</section>

<!-- HOW IT WORKS -->
<section class="how" id="how">
  <div class="section-header">
    <div class="section-eyebrow">How It Works</div>
    <div class="section-title">Up and running in under 30 minutes</div>
    <div class="section-sub">No IT team required. If you can log into the Amazon portal, you can run MVPx.</div>
  </div>
  <div class="steps">
    <div class="step">
      <div class="step-num">1</div>
      <h3>Request Access</h3>
      <p>Fill out the form below. We set up your station, your admin account, and seed your employee roster.</p>
    </div>
    <div class="step">
      <div class="step-num">2</div>
      <h3>Upload Your Files</h3>
      <p>Drop your Amazon report files &mdash; schedules, scorecards, fleet data. MVPx auto-loads everything to the right place.</p>
    </div>
    <div class="step">
      <div class="step-num">3</div>
      <h3>Invite Your Team</h3>
      <p>Add dispatchers and managers. Drivers get mobile access automatically through their phone number on file.</p>
    </div>
    <div class="step">
      <div class="step-num">4</div>
      <h3>Run Your Station</h3>
      <p>One login. One dashboard. Less clicking, less texting, less guessing. Your whole operation in one place.</p>
    </div>
  </div>
</section>

<!-- METRICS BAND -->
<div class="metrics-band">
  <div class="metric-item">
    <div class="metric-val">16<span>+</span></div>
    <div class="metric-lbl">Amazon report types auto-parsed</div>
  </div>
  <div class="metric-item">
    <div class="metric-val">0<span>x</span></div>
    <div class="metric-lbl">Spreadsheets needed</div>
  </div>
  <div class="metric-item">
    <div class="metric-val">&lt;30<span>min</span></div>
    <div class="metric-lbl">Average onboarding time</div>
  </div>
  <div class="metric-item">
    <div class="metric-val">1<span>x</span></div>
    <div class="metric-lbl">Login for everything</div>
  </div>
</div>

<!-- ONBOARDING -->
<section class="onboard" id="onboard">
  <div class="onboard-inner">
    <div class="onboard-text">
      <div class="section-eyebrow" style="text-align:left;">Get Started</div>
      <h2>Get your station set up today</h2>
      <p>Tell us about your DSP and we will get your MVPx account configured. Currently in private access &mdash; Amazon DSP operators only.</p>
      <ul class="onboard-bullets">
        <li>30-day free trial, no credit card required</li>
        <li>Same-day setup for stations under 150 DAs</li>
        <li>Your data stays yours &mdash; no sharing with Amazon</li>
        <li>Built by a DSP operator, for DSP operators</li>
        <li>Cancel any time &mdash; no long-term contracts</li>
      </ul>
      <a class="btn-gform"
         href="https://docs.google.com/forms/d/1Y6FKvb1D4bRPWMbhnnnXTqkh6qt3JtXFvW2f1Y6iTXs/edit"
         target="_blank" rel="noopener">
        Request Early Access
      </a>
      <p class="btn-gform-note">We will reach out within 1 business day.</p>
    </div>
    <div class="onboard-visual">
      <div class="onboard-visual-title">What happens next</div>
      <div class="onboard-step-row">
        <div class="onboard-step-circle">1</div>
        <div class="onboard-step-body">
          <h4>Submit the form</h4>
          <p>Tell us your station code, team size, and what you are currently using.</p>
        </div>
      </div>
      <div class="onboard-step-row">
        <div class="onboard-step-circle">2</div>
        <div class="onboard-step-body">
          <h4>We configure your account</h4>
          <p>Your station is set up within 1 business day. We send you login credentials.</p>
        </div>
      </div>
      <div class="onboard-step-row">
        <div class="onboard-step-circle">3</div>
        <div class="onboard-step-body">
          <h4>Upload your first file</h4>
          <p>Drop a DA roster or scorecard export. MVPx auto-detects and loads it.</p>
        </div>
      </div>
      <div class="onboard-step-row">
        <div class="onboard-step-circle">4</div>
        <div class="onboard-step-body">
          <h4>Your team goes live</h4>
          <p>Dispatchers log in from desktop. Drivers access schedules from their phone.</p>
        </div>
      </div>
    </div>
  </div>
</section>

<!-- FOOTER -->
<footer class="footer" id="contact">
  <div class="footer-logo"><img src="../images/logo/logo_1.jpeg" alt="MVP Logistics" style="height:32px;width:auto;filter:brightness(0) invert(1);"></div>
  <div class="footer-links">
    <a href="#features">Features</a>
    <a href="#how">How It Works</a>
    <a href="#onboard">Get Started</a>
  </div>
  <div class="footer-copy">&copy; 2026 MVPx &mdash; Built for Amazon DSP Operators</div>
</footer>

<!-- LOGIN MODAL -->
<div class="modal-overlay" id="loginModal" onclick="handleOverlayClick(event)">
  <div class="modal-box">
    <button class="modal-close" onclick="closeLogin()">X</button>
    <h2>Welcome back</h2>
    <p class="modal-sub">Log in to your MVPx station dashboard</p>
    <form class="modal-form" onsubmit="doLogin(event)">
      <div id="loginError" class="modal-error">Invalid username or password. Please try again.</div>
      <div class="f-group">
        <label>Username or Phone Number</label>
        <input type="text" id="loginUser" name="loginUser" placeholder="Enter your username" autocomplete="username">
      </div>
      <div class="f-group">
        <label>Password</label>
        <input type="password" id="loginPwd" name="loginPwd" placeholder="Enter your password" autocomplete="current-password">
      </div>
      <button type="submit" class="btn-modal-login">Log In</button>
      <hr class="modal-divider">
      <div class="modal-footer-link">No access yet? <a href="#onboard" onclick="closeLogin(); setTimeout(function(){ document.getElementById('onboard').scrollIntoView({behavior:'smooth'}); }, 150);">Request it here</a></div>
    </form>
  </div>
</div>

<script>
function openLogin() {
  document.getElementById('loginModal').classList.add('open');
  setTimeout(function(){ document.getElementById('loginUser').focus(); }, 100);
}
function closeLogin() {
  document.getElementById('loginModal').classList.remove('open');
}
function handleOverlayClick(e) {
  if (e.target === document.getElementById('loginModal')) closeLogin();
}
document.addEventListener('keydown', function(e) {
  if (e.key === 'Escape') closeLogin();
});
function scrollTo(id) {
  var el = document.getElementById(id);
  if (el) el.scrollIntoView({ behavior: 'smooth' });
}

function doLogin(e) {
  e.preventDefault();
  var user = document.getElementById('loginUser').value.trim();
  var pwd  = document.getElementById('loginPwd').value.trim();
  if (!user || !pwd) {
    document.getElementById('loginError').classList.add('show');
    return;
  }
  document.getElementById('loginError').classList.remove('show');
  var form = document.createElement('form');
  form.method = 'POST';
  form.action = '../servlet/MVPGServlet';
  var fields = { submitType: '11', controller: 'Login', loginUser: user, loginPwd: pwd };
  Object.keys(fields).forEach(function(k) {
    var inp = document.createElement('input');
    inp.type = 'hidden'; inp.name = k; inp.value = fields[k];
    form.appendChild(inp);
  });
  document.body.appendChild(form);
  form.submit();
}

document.querySelectorAll('a[href^="#"]').forEach(function(a) {
  a.addEventListener('click', function(e) {
    var href = this.getAttribute('href');
    if (href === '#') return;
    var target = document.querySelector(href);
    if (target) { e.preventDefault(); target.scrollIntoView({ behavior: 'smooth' }); }
  });
});
</script>
</body>
</html>
