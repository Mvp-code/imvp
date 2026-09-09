<%-- ═══════════════════════════════════════════════════════════
     includeSidebar.jsp  —  shared sidebar for all pages
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
  boolean _sbInFleet  = "AdminVehicle".equals(_sbPage)   || "AdminGasCard".equals(_sbPage)
                     || "FleetInventoryDashboard".equals(_sbPage);
  boolean _sbInDocs   = "CommonUpload".equals(_sbPage)   || "EmployeeForms".equals(_sbPage)  || "Contacts".equals(_sbPage) || "GenericUpload".equals(_sbPage);
  boolean _sbInSafety = "Incident".equals(_sbPage)       || "EmployeeIncident".equals(_sbPage)|| "VehicleInspection".equals(_sbPage);
  boolean _sbInAdmin  = "EntityUsers".equals(_sbPage)    || "AdminPhones".equals(_sbPage)     || "AdminFormsTemplate".equals(_sbPage) || "AdminIncidentType".equals(_sbPage);
%>
<nav class="mvpx-sidebar" id="mvpxSidebar">

  <!-- Logo -->
  <div class="sb-logo" onclick="mvpxToggleSidebar()">
    <div class="sb-logo-mark">MVP<span>x</span></div>
    <div class="sb-logo-text"><strong>DSP Platform</strong>DNK7</div>
    <button class="sb-toggle" id="mvpxSbToggle" title="Collapse sidebar"><i class="fas fa-bars"></i></button>
  </div>

  <!-- OPERATIONS -->
  <div class="sb-section-label sb-section-ops"><i class="fas fa-bolt" style="font-size:9px;"></i>&nbsp;Operations</div>

  <a class="sb-item<%="Dashboard".equals(_sbPage)?" active":""%>" href="<%=_sbServlet%>Dashboard">
    <span class="sb-icon"><i class="fas fa-th-large"></i></span><span class="sb-label">Dashboard</span>
  </a>
  <a class="sb-item<%="DAStatus".equals(_sbPage)?" active":""%>" href="<%=_sbServlet%>DAStatus">
    <span class="sb-icon"><i class="fas fa-check-circle"></i></span><span class="sb-label">DA Status</span>
    <span class="sb-dot green"></span>
  </a>
  <a class="sb-item<%="DACheckin".equals(_sbPage)?" active":""%>" href="<%=_sbServlet%>DACheckin">
    <span class="sb-icon"><i class="fas fa-sign-in-alt"></i></span><span class="sb-label">DA Checkin</span>
  </a>
  <a class="sb-item<%="DACheckout".equals(_sbPage)?" active":""%>" href="<%=_sbServlet%>DACheckout">
    <span class="sb-icon"><i class="fas fa-sign-out-alt"></i></span><span class="sb-label">DA Checkout</span>
  </a>
  <a class="sb-item<%="GenericSMS".equals(_sbPage)?" active":""%>" href="<%=_sbServlet%>GenericSMS">
    <span class="sb-icon"><i class="fas fa-comments"></i></span><span class="sb-label">SMS Chat</span>
  </a>

  <div class="sb-divider"></div>

  <!-- PEOPLE -->
  <div class="sb-section-label sb-section-ppl"><i class="fas fa-users" style="font-size:9px;"></i>&nbsp;People</div>

  <a class="sb-item<%="DAOnboardingDashboard".equals(_sbPage)?" active":""%>" href="<%=_sbCtxPath%>/jsp/DAOnboardingDashboard.jsp">
    <span class="sb-icon"><i class="fas fa-chart-line"></i></span><span class="sb-label">Onboarding Dashboard</span>
  </a>
  <a class="sb-item<%="DAOnboarding".equals(_sbPage)?" active":""%>" href="<%=_sbCtxPath%>/jsp/DAOnboarding.jsp">
    <span class="sb-icon"><i class="fas fa-user-plus"></i></span><span class="sb-label">DA Onboarding</span>
  </a>
  <a class="sb-item<%="AdminEmployee".equals(_sbPage)?" active":""%>" href="<%=_sbServlet%>AdminEmployee">
    <span class="sb-icon"><i class="fas fa-id-badge"></i></span><span class="sb-label">Employees</span>
  </a>
  <a class="sb-item<%="EmployeeSchedule".equals(_sbPage)?" active":""%>" href="<%=_sbServlet%>EmployeeSchedule">
    <span class="sb-icon"><i class="fas fa-calendar-alt"></i></span><span class="sb-label">Schedule</span>
  </a>
  <a class="sb-item<%="EmployeeTermination".equals(_sbPage)?" active":""%>" href="<%=_sbServlet%>EmployeeTermination">
    <span class="sb-icon"><i class="fas fa-user-times"></i></span><span class="sb-label">Terminations</span>
  </a>

  <div class="sb-divider"></div>

  <!-- SAFETY -->
  <div class="sb-section-label sb-section-saf"><i class="fas fa-shield-alt" style="font-size:9px;"></i>&nbsp;Safety</div>

  <a class="sb-item sb-has-sub<%=_sbInSafety?" open":""%>" onclick="sbToggle(this)">
    <span class="sb-icon"><i class="fas fa-hard-hat"></i></span>
    <span class="sb-label">Safety &amp; Compliance</span>
    <i class="fas fa-chevron-right sb-chevron"></i>
  </a>
  <div class="sb-submenu<%=_sbInSafety?" open":""%>">
    <a class="sb-sub-item<%="Incident".equals(_sbPage)?" active":""%>" href="<%=_sbServlet%>Incident">
      <span class="sb-sub-dot"></span>Incidents
    </a>
    <a class="sb-sub-item<%="EmployeeIncident".equals(_sbPage)?" active":""%>" href="<%=_sbServlet%>EmployeeIncident">
      <span class="sb-sub-dot"></span>OSHA Events
    </a>
    <a class="sb-sub-item<%="VehicleInspection".equals(_sbPage)?" active":""%>" href="<%=_sbServlet%>VehicleInspection">
      <span class="sb-sub-dot"></span>Inspections
    </a>
  </div>

  <div class="sb-divider"></div>

  <!-- FLEET -->
  <div class="sb-section-label sb-section-flt"><i class="fas fa-truck" style="font-size:9px;"></i>&nbsp;Fleet</div>

  <a class="sb-item sb-has-sub<%=_sbInFleet?" open":""%>" onclick="sbToggle(this)">
    <span class="sb-icon"><i class="fas fa-truck-moving"></i></span>
    <span class="sb-label">Fleet Management</span>
    <i class="fas fa-chevron-right sb-chevron"></i>
  </a>
  <div class="sb-submenu<%=_sbInFleet?" open":""%>">
    <a class="sb-sub-item<%="FleetInventoryDashboard".equals(_sbPage)?" active":""%>" href="<%=_sbCtxPath%>/jsp/FleetInventoryDashboard.jsp">
      <span class="sb-sub-dot"></span>Fleet Inventory
    </a>
    <a class="sb-sub-item<%="AdminVehicle".equals(_sbPage)?" active":""%>" href="<%=_sbServlet%>AdminVehicle">
      <span class="sb-sub-dot"></span>Vehicles
    </a>
    <a class="sb-sub-item<%="AdminGasCard".equals(_sbPage)?" active":""%>" href="<%=_sbServlet%>AdminGasCard">
      <span class="sb-sub-dot"></span>Gas Cards
    </a>
  </div>

  <div class="sb-divider"></div>

  <!-- DOCUMENTS -->
  <div class="sb-section-label sb-section-doc"><i class="fas fa-folder" style="font-size:9px;"></i>&nbsp;Documents</div>

  <a class="sb-item sb-has-sub<%=_sbInDocs?" open":""%>" onclick="sbToggle(this)">
    <span class="sb-icon"><i class="fas fa-folder-open"></i></span>
    <span class="sb-label">All Documents</span>
    <i class="fas fa-chevron-right sb-chevron"></i>
  </a>
  <div class="sb-submenu<%=_sbInDocs?" open":""%>">
    <a class="sb-sub-item<%="CommonUpload".equals(_sbPage)?" active":""%>" href="<%=_sbServlet%>CommonUpload">
      <span class="sb-sub-dot"></span>DA Documents
    </a>
    <a class="sb-sub-item<%="GenericUpload".equals(_sbPage)?" active":""%>" href="<%=_sbServlet%>GenericUpload">
      <span class="sb-sub-dot"></span>Uploads
    </a>
    <a class="sb-sub-item<%="EmployeeForms".equals(_sbPage)?" active":""%>" href="<%=_sbServlet%>EmployeeForms">
      <span class="sb-sub-dot"></span>Employee Forms
    </a>
    <a class="sb-sub-item<%="Contacts".equals(_sbPage)?" active":""%>" href="<%=_sbServlet%>Contacts">
      <span class="sb-sub-dot"></span>Contacts
    </a>
  </div>

  <div class="sb-divider"></div>

  <!-- ANALYTICS -->
  <div class="sb-section-label sb-section-ana"><i class="fas fa-chart-bar" style="font-size:9px;"></i>&nbsp;Analytics</div>

  <a class="sb-item<%="Reports".equals(_sbPage)?" active":""%>" href="<%=_sbServlet%>Reports">
    <span class="sb-icon"><i class="fas fa-chart-bar"></i></span><span class="sb-label">Scorecard</span>
  </a>

  <%if(_sbAdmin){%>
  <div class="sb-divider"></div>

  <!-- ADMIN -->
  <div class="sb-section-label sb-section-adm"><i class="fas fa-cog" style="font-size:9px;"></i>&nbsp;Admin</div>

  <a class="sb-item sb-has-sub<%=_sbInAdmin?" open":""%>" onclick="sbToggle(this)">
    <span class="sb-icon"><i class="fas fa-cogs"></i></span>
    <span class="sb-label">System Admin</span>
    <i class="fas fa-chevron-right sb-chevron"></i>
  </a>
  <div class="sb-submenu<%=_sbInAdmin?" open":""%>">
    <a class="sb-sub-item<%="EntityUsers".equals(_sbPage)?" active":""%>" href="<%=_sbServlet%>EntityUsers">
      <span class="sb-sub-dot"></span>Users
    </a>
    <a class="sb-sub-item<%="AdminPhones".equals(_sbPage)?" active":""%>" href="<%=_sbServlet%>AdminPhones">
      <span class="sb-sub-dot"></span>Phones
    </a>
    <a class="sb-sub-item<%="AdminFormsTemplate".equals(_sbPage)?" active":""%>" href="<%=_sbServlet%>AdminFormsTemplate">
      <span class="sb-sub-dot"></span>Form Templates
    </a>
    <a class="sb-sub-item<%="AdminIncidentType".equals(_sbPage)?" active":""%>" href="<%=_sbServlet%>AdminIncidentType">
      <span class="sb-sub-dot"></span>Incident Types
    </a>
    <a class="sb-sub-item" href="<%=_sbCtxPath%>/jsp/MVPGConfig.jsp">
      <span class="sb-sub-dot"></span>Configuration
    </a>
  </div>
  <%}%>

  <!-- Logout + User -->
  <div class="sb-divider"></div>
  <a class="sb-item sb-logout" href="<%=_sbCtxPath%>/servlet/MVPGServlet?submitType=11&controller=Login">
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
