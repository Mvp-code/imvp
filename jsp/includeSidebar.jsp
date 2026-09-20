<%-- ═══════════════════════════════════════════════════════════
     includeSidebar.jsp  —  shared sidebar for all pages
     Keep in sync with includeHeader.jsp moduleArray.
     Expects callers to set:
       String _sbUser      — display name
       String _sbRole      — role string
       String _sbPage      — current page key  e.g. "DAOnboarding"
       String _sbCtxPath   — request.getContextPath()
       boolean _sbAdmin    — true if TechAdmin
     Navigation uses direct servlet href (works on any page).
     ════════════════════════════════════════════════════════════ --%>
<%
  String _sbServlet = _sbCtxPath + "/servlet/MVPGServlet?submitType=1&controller=";
  boolean _sbInAdmin  = "EntityUsers".equals(_sbPage)    || "AdminFormsTemplate".equals(_sbPage) || "AdminIncidentType".equals(_sbPage)
                     || "AdminConfiguration".equals(_sbPage);
  boolean _sbInTrain  = "DAStandardWorkDocument".equals(_sbPage) || "DispatcherStandardWorkDocument".equals(_sbPage);
%>
<nav class="mvpx-sidebar" id="mvpxSidebar">

  <!-- Logo -->
  <div class="sb-logo" onclick="mvpxToggleSidebar()">
    <div class="sb-logo-mark">MVP<span>x</span></div>
    <div class="sb-logo-text"><strong>DSP Platform</strong>DNK7</div>
    <button class="sb-toggle" id="mvpxSbToggle" title="Collapse sidebar"><i class="fas fa-bars"></i></button>
  </div>

  <!-- OPERATION -->
  <div class="sb-section-label sb-section-ops"><i class="fas fa-bolt" style="font-size:9px;"></i>&nbsp;Operation</div>

  <a class="sb-item<%="Incident".equals(_sbPage)?" active":""%>" href="<%=_sbServlet%>Incident">
    <span class="sb-icon"><i class="fas fa-exclamation-triangle"></i></span><span class="sb-label">Incident</span>
  </a>
  <a class="sb-item<%="DACheckin".equals(_sbPage)?" active":""%>" href="<%=_sbServlet%>DACheckin">
    <span class="sb-icon"><i class="fas fa-sign-in-alt"></i></span><span class="sb-label">DA Checkins</span>
  </a>
  <a class="sb-item<%="DAStatus".equals(_sbPage)?" active":""%>" href="<%=_sbServlet%>DAStatus">
    <span class="sb-icon"><i class="fas fa-check-circle"></i></span><span class="sb-label">DA Confirmations</span>
    <span class="sb-dot green"></span>
  </a>
  <a class="sb-item<%="DACheckout".equals(_sbPage)?" active":""%>" href="<%=_sbServlet%>DACheckout">
    <span class="sb-icon"><i class="fas fa-sign-out-alt"></i></span><span class="sb-label">DA Checkouts</span>
  </a>
  <a class="sb-item<%="DispatcherTaskBoard".equals(_sbPage)?" active":""%>" href="<%=_sbCtxPath%>/jsp/DispatcherTaskBoard.jsp">
    <span class="sb-icon"><i class="fas fa-tasks"></i></span><span class="sb-label">Dispatcher Tasks</span>
  </a>
  <a class="sb-item<%="ReturnsBoard".equals(_sbPage)?" active":""%>" href="<%=_sbServlet%>ReturnsBoard">
    <span class="sb-icon"><i class="fas fa-th-large"></i></span><span class="sb-label">Returns Board</span>
  </a>
  <a class="sb-item<%="WaveSheet".equals(_sbPage)?" active":""%>" href="<%=_sbServlet%>WaveSheet">
    <span class="sb-icon"><i class="fas fa-table"></i></span><span class="sb-label">Wave Sheet</span>
  </a>

  <div class="sb-divider"></div>

  <!-- HR -->
  <div class="sb-section-label sb-section-ppl"><i class="fas fa-users" style="font-size:9px;"></i>&nbsp;HR</div>

  <a class="sb-item<%="DAOnboarding".equals(_sbPage)?" active":""%>" href="<%=_sbCtxPath%>/jsp/DAOnboarding.jsp">
    <span class="sb-icon"><i class="fas fa-user-plus"></i></span><span class="sb-label">DA Onboarding</span>
  </a>
  <a class="sb-item<%="AdminEmployee".equals(_sbPage)?" active":""%>" href="<%=_sbServlet%>AdminEmployee">
    <span class="sb-icon"><i class="fas fa-id-badge"></i></span><span class="sb-label">Employees</span>
  </a>
  <a class="sb-item<%="EmployeeForms".equals(_sbPage)?" active":""%>" href="<%=_sbServlet%>EmployeeForms">
    <span class="sb-icon"><i class="fas fa-sticky-note"></i></span><span class="sb-label">Forms</span>
  </a>
  <a class="sb-item<%="DAOnboardingDashboard".equals(_sbPage)?" active":""%>" href="<%=_sbCtxPath%>/jsp/DAOnboardingDashboard.jsp">
    <span class="sb-icon"><i class="fas fa-chart-line"></i></span><span class="sb-label">Onboarding Dashboard</span>
  </a>

  <div class="sb-divider"></div>

  <!-- FLEET -->
  <div class="sb-section-label sb-section-flt"><i class="fas fa-truck" style="font-size:9px;"></i>&nbsp;Fleet Management</div>

  <a class="sb-item<%="AdminVehicle".equals(_sbPage)?" active":""%>" href="<%=_sbServlet%>AdminVehicle">
    <span class="sb-icon"><i class="fas fa-truck"></i></span><span class="sb-label">Vehicles</span>
  </a>
  <a class="sb-item<%="AdminPhones".equals(_sbPage)?" active":""%>" href="javascript:void(0)" onclick="submitPageDataForm('<%=SubmitType.SEARCH%>','AdminPhones');return false;">
    <span class="sb-icon"><i class="fas fa-mobile-alt"></i></span><span class="sb-label">Phones</span>
  </a>
  <a class="sb-item<%="AdminGasCard".equals(_sbPage)?" active":""%>" href="javascript:void(0)" onclick="submitPageDataForm('<%=SubmitType.SEARCH%>','AdminGasCard');return false;">
    <span class="sb-icon"><i class="fas fa-id-card"></i></span><span class="sb-label">Gas Cards</span>
  </a>
  <a class="sb-item<%="FleetTaskBoard".equals(_sbPage)?" active":""%>" href="<%=_sbCtxPath%>/jsp/FleetTaskBoard.jsp">
    <span class="sb-icon"><i class="fas fa-tasks"></i></span><span class="sb-label">Fleet Tasks</span>
  </a>
  <a class="sb-item<%="FleetInventoryDashboard".equals(_sbPage)?" active":""%>" href="<%=_sbCtxPath%>/jsp/FleetInventoryDashboard.jsp">
    <span class="sb-icon"><i class="fas fa-tachometer-alt"></i></span><span class="sb-label">Fleet Inventory</span>
  </a>

  <div class="sb-divider"></div>

  <!-- UPLOADS -->
  <div class="sb-section-label sb-section-doc"><i class="fas fa-folder" style="font-size:9px;"></i>&nbsp;Uploads</div>

  <a class="sb-item<%="SmartUpload".equals(_sbPage)?" active":""%>" href="<%=_sbServlet%>SmartUpload">
    <span class="sb-icon"><i class="fas fa-magic"></i></span><span class="sb-label">Smart Upload</span>
  </a>
  <a class="sb-item<%="UploadHistory".equals(_sbPage)?" active":""%>" href="<%=_sbServlet%>UploadHistory">
    <span class="sb-icon"><i class="fas fa-history"></i></span><span class="sb-label">Upload History</span>
  </a>
  <a class="sb-item<%="IngestDiscovery".equals(_sbPage)?" active":""%>" href="<%=_sbCtxPath%>/jsp/IngestDiscovery.jsp">
    <span class="sb-icon"><i class="fas fa-random"></i></span><span class="sb-label">AMZL Bridge</span>
  </a>

  <div class="sb-divider"></div>

  <!-- ANALYTICS -->
  <div class="sb-section-label sb-section-ana"><i class="fas fa-chart-bar" style="font-size:9px;"></i>&nbsp;Analytics</div>

  <a class="sb-item<%="StationDashboard".equals(_sbPage) || "Dashboard".equals(_sbPage)?" active":""%>" href="<%=_sbServlet%>StationDashboard">
    <span class="sb-icon"><i class="fas fa-tachometer-alt"></i></span><span class="sb-label">MVPx Dashboard</span>
  </a>
  <a class="sb-item<%="PredictScorecard".equals(_sbPage)?" active":""%>" href="<%=_sbCtxPath%>/jsp/PredictScorecard.jsp">
    <span class="sb-icon"><i class="fas fa-chart-line"></i></span><span class="sb-label">Predict Scorecard</span>
  </a>
  <a class="sb-item<%="MVPxReports".equals(_sbPage)?" active":""%>" href="<%=_sbCtxPath%>/jsp/MVPxReports.jsp">
    <span class="sb-icon"><i class="fas fa-table"></i></span><span class="sb-label">MVPx-Reports</span>
  </a>

  <div class="sb-divider"></div>

  <!-- DOCUMENTS -->
  <div class="sb-section-label sb-section-doc"><i class="fas fa-folder" style="font-size:9px;"></i>&nbsp;Documents</div>

  <a class="sb-item sb-has-sub<%=_sbInTrain?" open":""%>" onclick="sbToggle(this)">
    <span class="sb-icon"><i class="fas fa-graduation-cap"></i></span>
    <span class="sb-label">Training</span>
    <i class="fas fa-chevron-right sb-chevron"></i>
  </a>
  <div class="sb-submenu<%=_sbInTrain?" open":""%>">
    <a class="sb-sub-item<%="DAStandardWorkDocument".equals(_sbPage)?" active":""%>" href="<%=_sbCtxPath%>/jsp/DAStandardWorkDocument.jsp">
      <span class="sb-sub-dot"></span>DA Standard Work
    </a>
    <a class="sb-sub-item<%="DispatcherStandardWorkDocument".equals(_sbPage)?" active":""%>" href="<%=_sbCtxPath%>/jsp/DispatcherStandardWorkDocument.jsp">
      <span class="sb-sub-dot"></span>Dispatcher Standard Work
    </a>
  </div>

  <div class="sb-divider"></div>

  <!-- EMILY -->
  <div class="sb-section-label sb-section-ops"><i class="fas fa-phone" style="font-size:9px;"></i>&nbsp;Emily Dispatcher</div>

  <a class="sb-item<%="EmilyConsole".equals(_sbPage)?" active":""%>" href="<%=_sbCtxPath%>/jsp/EmilyConsole.jsp">
    <span class="sb-icon"><i class="fas fa-phone"></i></span><span class="sb-label">Emily Console</span>
  </a>

  <%if(_sbAdmin){%>
  <div class="sb-divider"></div>

  <!-- ADMIN -->
  <div class="sb-section-label sb-section-adm"><i class="fas fa-cog" style="font-size:9px;"></i>&nbsp;Admin</div>

  <a class="sb-item sb-has-sub<%=_sbInAdmin?" open":""%>" onclick="sbToggle(this)">
    <span class="sb-icon"><i class="fas fa-cogs"></i></span>
    <span class="sb-label">Admin</span>
    <i class="fas fa-chevron-right sb-chevron"></i>
  </a>
  <div class="sb-submenu<%=_sbInAdmin?" open":""%>">
    <a class="sb-sub-item<%="AdminFormsTemplate".equals(_sbPage)?" active":""%>" href="<%=_sbServlet%>AdminFormsTemplate">
      <span class="sb-sub-dot"></span>Form Templates
    </a>
    <a class="sb-sub-item<%="EntityUsers".equals(_sbPage)?" active":""%>" href="<%=_sbServlet%>EntityUsers">
      <span class="sb-sub-dot"></span>Users
    </a>
    <a class="sb-sub-item<%="AdminConfiguration".equals(_sbPage)?" active":""%>" href="<%=_sbServlet%>AdminConfiguration">
      <span class="sb-sub-dot"></span>Configuration
    </a>
    <a class="sb-sub-item" href="<%=_sbCtxPath%>/servlet/MVPGServlet?submitType=17&controller=EntityUsers">
      <span class="sb-sub-dot"></span>Change Password
    </a>
  </div>
  <a class="sb-item<%="AdminIncidentType".equals(_sbPage)?" active":""%>" href="<%=_sbServlet%>AdminIncidentType">
    <span class="sb-icon"><i class="fas fa-tags"></i></span><span class="sb-label">Types</span>
  </a>
  <a class="sb-item<%="AdminIncidentCategory".equals(_sbPage)?" active":""%>" href="<%=_sbServlet%>AdminIncidentCategory">
    <span class="sb-icon"><i class="fas fa-list"></i></span><span class="sb-label">Category</span>
  </a>
  <%}%>

  <div class="sb-divider"></div>

  <!-- OTHER (matches includeHeader Other) -->
  <div class="sb-section-label sb-section-ops"><i class="fas fa-ellipsis-h" style="font-size:9px;"></i>&nbsp;Other</div>
  <a class="sb-item<%="DailyStatus".equals(_sbPage)?" active":""%>" href="<%=_sbCtxPath%>/jsp/DailyStatus.jsp">
    <span class="sb-icon"><i class="fas fa-clipboard"></i></span><span class="sb-label">Daily Status</span>
  </a>
  <a class="sb-item<%="DATask".equals(_sbPage)?" active":""%>" href="<%=_sbServlet%>DATask">
    <span class="sb-icon"><i class="fas fa-check-square"></i></span><span class="sb-label">DA Tasks</span>
  </a>
  <a class="sb-item<%="GenericSMS".equals(_sbPage)?" active":""%>" href="<%=_sbServlet%>GenericSMS">
    <span class="sb-icon"><i class="fas fa-comments"></i></span><span class="sb-label">SMS</span>
  </a>
  <a class="sb-item<%="EmployeeIncident".equals(_sbPage)?" active":""%>" href="<%=_sbServlet%>EmployeeIncident">
    <span class="sb-icon"><i class="fas fa-medkit"></i></span><span class="sb-label">OSHA Incidents</span>
  </a>
  <a class="sb-item<%="home".equals(_sbPage)?" active":""%>" href="<%=_sbCtxPath%>/jsp/home.jsp">
    <span class="sb-icon"><i class="fas fa-home"></i></span><span class="sb-label">Home</span>
  </a>

  <!-- Logout + User -->
  <div class="sb-divider"></div>
  <a class="sb-item sb-logout" href="<%=_sbCtxPath%>/servlet/MVPGServlet?submitType=12&controller=Login">
    <span class="sb-icon"><i class="fas fa-sign-out-alt"></i></span><span class="sb-label">Logout</span>
  </a>

  <div class="sb-user">
    <div class="sb-avatar"><%=_sbUser.length()>1?_sbUser.substring(0,2).toUpperCase():"?"%></div>
    <div>
      <div class="sb-user-name"><%=_sbUser%></div>
      <div class="sb-user-role"><%=_sbRole%></div>
    </div>
  </div>

</nav>
<script>
function sbToggle(el) {
  var sub = el.nextElementSibling;
  if (!sub || !sub.classList.contains('sb-submenu')) return;
  var open = sub.classList.contains('open');
  el.classList.toggle('open', !open);
  sub.classList.toggle('open', !open);
}
function mvpxToggleSidebar() {
  var sb = document.getElementById('mvpxSidebar');
  if (sb) sb.classList.toggle('collapsed');
}
</script>
