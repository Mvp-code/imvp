<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
String entityID             = request.getAttribute("entityID")             == null ? "" : request.getAttribute("entityID").toString().trim();
String loginUser            = request.getAttribute("loginUser")            == null ? "" : request.getAttribute("loginUser").toString().trim();
String loginUserDisplayName = request.getAttribute("loginUserDisplayName") == null ? "" : request.getAttribute("loginUserDisplayName").toString().trim();
String loginUserID          = request.getAttribute("loginUserID")          == null ? "" : request.getAttribute("loginUserID").toString().trim();
String loginUserRoles       = request.getAttribute("loginUserRoles")       == null ? "" : request.getAttribute("loginUserRoles").toString().trim();
String isPopup              = request.getAttribute("isPopup")              == null ? "" : request.getAttribute("isPopup").toString().trim();
String shellNoForm          = request.getAttribute("shellNoForm")          == null ? "" : request.getAttribute("shellNoForm").toString().trim();
String hideTopbarSearch     = request.getAttribute("hideTopbarSearch")     == null ? "" : request.getAttribute("hideTopbarSearch").toString().trim();
String currentController    = (_recordBean != null) ? _recordBean.getController() : "";
String requestUri           = request.getRequestURI() == null ? "" : request.getRequestURI();
if (loginUserDisplayName.isEmpty()) loginUserDisplayName = loginUser;

boolean isDriver    = "4".equalsIgnoreCase(loginUserRoles);
boolean isTechAdmin = "TechAdmin".equalsIgnoreCase(loginUserRoles);
String ctx          = request.getContextPath();

// Per-user UI preferences (theme, language, accessibility) — DB-backed.
String _mvpxPrefUserKey = loginUserID.isEmpty() ? loginUser : loginUserID;
com.beans.UserPreference _mvpxPrefs = null;
try {
  _mvpxPrefs = new com.dataobjects.UserPreferenceDAO().load(_mvpxPrefUserKey, entityID);
} catch (Exception _mvpxPrefEx) { /* fall back to defaults */ }
if (_mvpxPrefs == null) _mvpxPrefs = new com.beans.UserPreference();
String pageTitle    = (_recordBean != null && _recordBean.getDisplayName() != null && _recordBean.getDisplayName().length() > 0)
                      ? _recordBean.getDisplayName() : (currentController.isEmpty() ? "Dashboard" : currentController);
String userInitials = loginUserDisplayName.length() > 1 ? loginUserDisplayName.substring(0, 2).toUpperCase() : "?";

String adminTabsInfo = "Gas Card~<i class='fa fa-id-card' aria-hidden='true'></i>@@";
adminTabsInfo += "Phone~<i class='fa fa-mobile fa-2x' aria-hidden='true'></i>@@";
adminTabsInfo += "Form~<i class='fa fa-sticky-note-o' aria-hidden='true'></i>@@";
if (isTechAdmin)
  adminTabsInfo += "User~<i class='fa fa-user' aria-hidden='true'></i>@@Configuration@@";
adminTabsInfo += "Change Password~<i class='fa fa-user' aria-hidden='true'></i>";

String trainingTabsInfo = "DA Standard Work~<i class='fa fa-id-badge' aria-hidden='true'></i>~jsp:DAStandardWorkDocument@@"
  + "Dispatcher Standard Work~<i class='fa fa-headphones' aria-hidden='true'></i>~jsp:DispatcherStandardWorkDocument";

String moduleArray[][] = new String[][] {
  {"section:Operation", "", ""},
  {"Incident",        "Incident",          "<i class='fa fa-exclamation-triangle' aria-hidden='true'></i>"},
  {"DA Checkins",     "DACheckin",         "<i class='fa fa-sign-in' aria-hidden='true'></i>"},
  {"DA Confirmations","DAStatus",          "<i class='fa fa-check-circle' aria-hidden='true'></i>"},
  {"DA Checkouts",    "DACheckout",        "<i class='fa fa-sign-out' aria-hidden='true'></i>"},
  {"Dispatcher Tasks","jsp:DispatcherTaskBoard", "<i class='fa fa-tasks' aria-hidden='true'></i>"},
  {"Returns Board",   "ReturnsBoard",      "<i class='fa fa-th-large' aria-hidden='true'></i>"},
  {"Wave Sheet",      "WaveSheet",         "<i class='fa fa-table' aria-hidden='true'></i>"},

  {"section:HR", "", ""},
  {"Onboarding Dashboard", "jsp:DAOnboardingDashboard", "<i class='fa fa-dashboard' aria-hidden='true'></i>"},
  {"DA Onboarding",   "jsp:DAOnboarding",  "<i class='fa fa-id-badge' aria-hidden='true'></i>"},
  {"Employees",       "AdminEmployee",     "<i class='fa fa-users' aria-hidden='true'></i>"},
  {"Forms",           "EmployeeForms",     "<i class='fa fa-sticky-note-o' aria-hidden='true'></i>"},

  {"section:Fleet Management", "", ""},
  {"Fleet Inventory", "jsp:FleetInventoryDashboard", "<i class='fa fa-dashboard' aria-hidden='true'></i>"},
  {"Fleet Tasks",     "jsp:FleetTaskBoard", "<i class='fa fa-tasks' aria-hidden='true'></i>"},
  {"Vehicles",        "AdminVehicle",      "<i class='fa fa-truck' aria-hidden='true'></i>"},

  {"section:Uploads", "", ""},
  {"Smart Upload",    "SmartUpload",       "<i class='fa fa-magic' aria-hidden='true'></i>"},
  {"Upload History",  "UploadHistory",     "<i class='fa fa-history' aria-hidden='true'></i>"},
  {"AMZL Bridge",     "jsp:IngestDiscovery","<i class='fa fa-random' aria-hidden='true'></i>"},

  {"section:Analytics", "", ""},
  {"MVPx Dashboard",  "StationDashboard",  "<i class='fa fa-tachometer' aria-hidden='true'></i>"},
  {"Predict Scorecard", "jsp:PredictScorecard", "<i class='fa fa-line-chart' aria-hidden='true'></i>"},
  {"MVPx-Reports",    "jsp:MVPxReports",   "<i class='fa fa-table' aria-hidden='true'></i>"},

  {"section:Documents", "", ""},
  {"Training", "", "<i class='fa fa-graduation-cap' aria-hidden='true'></i>", trainingTabsInfo},

  {"section:Emily Dispatcher", "", ""},
  {"Emily Console",   "jsp:EmilyConsole",  "<i class='fa fa-phone' aria-hidden='true'></i>"},

  {"section:Admin", "", ""},
  {"Admin",           "", "<i class='fa fa-cog' aria-hidden='true'></i>", adminTabsInfo},
  {"Settings",        "AdminConfiguration","<i class='fa fa-sliders' aria-hidden='true'></i>"},
  {"Types",           "AdminIncidentType",    "<i class='fa fa-tags' aria-hidden='true'></i>"},
  {"Category",        "AdminIncidentCategory","<i class='fa fa-list' aria-hidden='true'></i>"},

  {"section:Other", "", ""},
  {"Home",            "jsp:home",          "<i class='fa fa-home' aria-hidden='true'></i>"},
  {"Daily Status",    "jsp:DailyStatus",   "<i class='fa fa-clipboard' aria-hidden='true'></i>"},
  {"DA Tasks",        "DATask",            "<i class='fa fa-check-square-o' aria-hidden='true'></i>"},
  {"Amazon Portal Links", "jsp:PortalResources", "<i class='fa fa-external-link' aria-hidden='true'></i>"},
  {"Bridge Loading Guide", "jsp:BridgeHelp",     "<i class='fa fa-book' aria-hidden='true'></i>"},
  {"SMS",             "GenericSMS",        "<i class='fa fa-comments' aria-hidden='true'></i>"},
  {"Coaching Followup","EmployeeCoachingFollowup","<i class='fa fa-comments' aria-hidden='true'></i>"},
  {"Employee Requests","EmployeeRequest",  "<i class='fa fa-calendar' aria-hidden='true'></i>"},
  {"Employee Uploads","CommonUpload",      "<i class='fa fa-cloud-upload' aria-hidden='true'></i>"},
  {"OSHA Incidents",  "EmployeeIncident",  "<i class='fa fa-medkit' aria-hidden='true'></i>"},
  {"Availability",    "EmployeeAvailability","<i class='fa fa-clock-o' aria-hidden='true'></i>"},
  {"Schedule",        "EmployeeSchedule",  "<i class='fa fa-calendar-o' aria-hidden='true'></i>"},
  {"Termination",     "EmployeeTermination","<i class='fa fa-user-times' aria-hidden='true'></i>"},
  {"Vehicle Inspection","VehicleInspection","<i class='fa fa-wrench' aria-hidden='true'></i>"},
  {"Uploads",         "GenericUpload",     "<i class='fa fa-cloud-upload' aria-hidden='true'></i>"},
  {"Reports",         "Reports",           "<i class='fa fa-bar-chart' aria-hidden='true'></i>"}
};
%>
<head>
<meta charset="UTF-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover"/>
<title>MVPx — <%=pageTitle%></title>

<%-- REV C type system: Bricolage Grotesque / Geist / Geist Mono --%>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:opsz,wght@12..96,600;12..96,700;12..96,800&family=Geist:wght@400;500;600;700&family=Geist+Mono:wght@400;500;600&family=Inter:wght@400;500;600;700&family=IBM+Plex+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">

<script src="../jsp/bootstrap/jquery-3.3.1.js"></script>
<script src="../jsp/bootstrap/popper.js"></script>
<script src="../jsp/bootstrap/bootstrap.min.js"></script>
<script src="../jsp/assets/js/JSFunctions.js?v=20260715b"></script>
<script src="../jsp/assets/js/mvpx.js?v=20260722d"></script>
<script src="../jsp/assets/js/mvpx-prefs.js?v=20260703"></script>

<link rel="stylesheet" href="../jsp/bootstrap/bootstrap.min.css">
<link rel="stylesheet" href="../jsp/bootstrap/all.min.css">
<link rel="stylesheet" href="../jsp/bootstrap/font-awesome.css">
<link rel="stylesheet" href="../jsp/bootstrap/datepicker/datepicker.min.css">
<link rel="stylesheet" href="../jsp/bootstrap/select2/select2.css">
<link rel="stylesheet" href="../jsp/bootstrap/MVPG.css">
<link rel="stylesheet" href="../jsp/bootstrap/buttons.css">
<link rel="stylesheet" href="../jsp/divPopup/style.css">
<link rel="stylesheet" href="../jsp/assets/css/mvpx.css?v=20260911a">
<link rel="stylesheet" href="../jsp/assets/css/mvpx-revc.css?v=20260722d">
<script src="../jsp/assets/js/mvpx-cmdk.js?v=20260915a" defer></script>

<script src="../jsp/bootstrap/datepicker/bootstrap-datepicker.min.js"></script>
<script src="../jsp/bootstrap/select2/select2.js"></script>
<script src="../jsp/divPopup/tinybox.js"></script>

<script>
function deleteUploadRecord(delID) {
  if (deleteRecord()) {
    document.formmain.action = "../servlet/MVPGServlet?submitType=<%=SubmitType.BROWSE%>&controller=<%=currentController%>&recordID=<%=_recordBean.getRecordID()%>&deleteUploadID=" + delID;
    document.formmain.submit();
  }
}
function viewUploadRecord(recordID) {
  window.open("../servlet/MVPGServlet?submitType=<%=SubmitType.PRINT%>&controller=CommonUpload&recordID=" + recordID + getPageSubmitFormValues(true));
}
function redirectToLogin() {
  submitPageDataForm('<%=SubmitType.LOGOUT%>', 'Login', '', '', '&sessionExpired=true');
}
<%if(isDriver){%>
setTimeout(function() { redirectToLogin(); }, 1800000);
<%} else if(loginUserRoles.length() > 0) {
  int sessionTimeoutMins = 60;
%>
var noClickTime = (1000 * 60 * <%=sessionTimeoutMins%>);
var noClickTimeoutObj = setTimeout("redirectToLogin();", noClickTime);
<%}%>
</script>
</head>
<body>

<a href="#mvpxMainContent" class="mvpx-skip-link" data-i18n="Skip to content">Skip to content</a>
<input type="hidden" id="mvpxUserKey" value="<%=loginUserID.isEmpty() ? loginUser : loginUserID%>">
<script>
/* DB-backed preferences handed to mvpx-prefs.js (source of truth on load). */
window.MVPX_CTX = '<%=ctx%>';
window.MVPX_SERVER_PREFS = {
  userKey:      '<%=_mvpxPrefUserKey%>',
  entityID:     '<%=entityID%>',
  theme:        '<%=_mvpxPrefs.getTheme()%>',
  lang:         '<%=_mvpxPrefs.getLang()%>',
  fontScale:    '<%=_mvpxPrefs.getFontScale()%>',
  a11yLarge:    <%="1".equals(_mvpxPrefs.getA11yLarge())%>,
  a11yContrast: <%="1".equals(_mvpxPrefs.getA11yContrast())%>,
  a11yMotion:   <%="1".equals(_mvpxPrefs.getA11yMotion())%>
};
</script>

<%if(!"yes".equalsIgnoreCase(isPopup)){%>
<div class="mvpx-shell">

<div class="sb-backdrop" id="sbBackdrop" onclick="mvpxCloseMobileSidebar()"></div>

<nav class="mvpx-sidebar collapsed" id="mvpxSidebar" aria-label="Main navigation">

  <div class="sb-header">
    <a class="sb-brand" href="<%=ctx%>/jsp/home.jsp">
      <img class="sb-brand-img" src="<%=ctx%>/images/logo/logo_1.jpeg" alt="MVP"
           onerror="this.style.display='none';this.nextElementSibling.style.display='flex';">
      <div class="sb-brand-fallback" style="display:none;">Mx</div>
      <div class="sb-brand-text">
        <div class="sb-brand-name">MVP<span>x</span></div>
        <div class="sb-brand-meta">
          <span class="sb-station-badge">DNK7</span>
          <span class="sb-brand-sub">DSP Platform</span>
        </div>
      </div>
    </a>
    <button type="button" class="sb-collapse-btn" id="mvpxSbToggle" onclick="mvpxToggleSidebar()"
            aria-label="Toggle menu" aria-expanded="false" title="Expand menu">
      <i class="fas fa-bars" aria-hidden="true"></i>
    </button>
  </div>

  <%if(!isDriver){%>

  <div class="sb-nav-search">
    <div class="sb-nav-search-wrap">
      <i class="fas fa-search"></i>
      <input type="text" placeholder="Filter menu…" autocomplete="off" oninput="mvpxFilterNav(this.value)"
             data-i18n="Filter menu…" aria-label="Filter menu">
    </div>
  </div>

  <div class="sb-nav-scroll" id="sbNavScroll">
  <%
  for (int i = 0; i < moduleArray.length; i++) {
    String controllerName = moduleArray[i][1];

    if (moduleArray[i][0].startsWith("section:")) {
      String secName = moduleArray[i][0].substring(8);
      String secClass = "sb-sec";
      if (secName.contains("Operations")) secClass += " sec-ops";
      else if (secName.contains("People")) secClass += " sec-ppl";
      else if (secName.contains("Safety")) secClass += " sec-saf";
      else if (secName.contains("Documents")) secClass += " sec-doc";
      else if (secName.contains("Reports")) secClass += " sec-ana";
      else if (secName.contains("Admin")) secClass += " sec-adm";
  %>
    <div class="<%=secClass%>" data-section data-i18n="<%=secName%>"><%=secName%></div>
  <%
      continue;
    }

    String icon = moduleArray[i].length > 2 ? moduleArray[i][2] : "";
    String subMenuDetails = moduleArray[i].length > 3 ? moduleArray[i][3] : "";

    if (subMenuDetails.length() > 0) {
      boolean isMenuSelected = false;
      String subMenuDetailsArray[] = subMenuDetails.split("#@#");
  %>
    <div class="sb-submenu-wrap" data-nav-group>
      <div class="sb-item sb-has-sub<%=isMenuSelected?" open":""%>" id="menu_<%=moduleArray[i][0].replaceAll(" ","")%>_LiID"
           data-tip="<%=moduleArray[i][0]%>"
           onclick="mvpxToggleSubmenu(this)" role="button" tabindex="0"
           onkeydown="if(event.key==='Enter'||event.key===' '){event.preventDefault();mvpxToggleSubmenu(this);}">
        <span class="sb-icon"><%=icon%></span>
        <span class="sb-label" data-i18n="<%=moduleArray[i][0]%>"><%=moduleArray[i][0]%></span>
        <i class="fas fa-chevron-right sb-chevron"></i>
      </div>
      <div class="sb-submenu<%=isMenuSelected?" open":""%>">
  <%
      for (int j = 0; j < subMenuDetailsArray.length; j++) {
        String subMenuArray[] = subMenuDetailsArray[j].split("@@");
        for (int k = 0; k < subMenuArray.length; k++) {
          String subMenuDataArray[] = subMenuArray[k].split("~");
          String displayName = subMenuDataArray[0];
          String subIcon = subMenuDataArray.length > 1 ? subMenuDataArray[1] : "";
          int selMode = SubmitType.SEARCH;
          String explicitController = subMenuDataArray.length > 2 ? subMenuDataArray[2] : "";

          if (explicitController.startsWith("jsp:")) {
            String jspFile = explicitController.substring(4);
            boolean jspActive = requestUri.contains("/" + jspFile + ".jsp");
            if (jspActive) isMenuSelected = true;
  %>
        <a class="sb-sub-item<%=(jspActive)?" active":""%>" href="<%=ctx%>/jsp/<%=jspFile%>.jsp"
           data-tip="<%=displayName%>">
          <span class="sb-sub-dot"></span><span data-i18n="<%=displayName%>"><%=displayName%></span>
        </a>
  <%
            continue;
          }

          String tabName = (moduleArray[i][0]).replaceAll(" ", "").replaceAll("Info", "");
          String subController = (tabName + displayName).replaceAll(" ", "").replaceAll("Info", "");

          if ("AdminPhone".equalsIgnoreCase(subController)) {
            subController = "AdminPhones";
          } else if ("AdminForm".equalsIgnoreCase(subController)) {
            subController = "AdminFormsTemplate";
          } else if ("AdminUser".equalsIgnoreCase(subController)) {
            subController = "EntityUsers";
          } else if ("AdminChangePassword".equalsIgnoreCase(subController)) {
            subController = "EntityUsers";
            selMode = SubmitType.CHANGE;
          } else if ("Incident".equalsIgnoreCase(tabName)) {
            if ("IncidentIncident".equalsIgnoreCase(subController))
              subController = "Incident";
            else
              subController = "Admin" + subController;
          } else if ("Employee".equalsIgnoreCase(tabName)) {
            if ("EmployeeEmployee".equalsIgnoreCase(subController))
              subController = "Admin" + tabName;
            else if ("EmployeeForm".equalsIgnoreCase(subController))
              subController = "EmployeeForms";
            else if ("EmployeeOnBoarding".equalsIgnoreCase(subController))
              subController = "";
          } else if ("Vehicle".equalsIgnoreCase(tabName)) {
            if ("VehicleVehicle".equalsIgnoreCase(subController))
              subController = "Admin" + tabName;
          }

          if (!displayName.endsWith("Category") && !displayName.endsWith("Availability") && !displayName.endsWith("Password"))
            displayName = displayName + "s";

          boolean isActive = _recordBean != null && _recordBean.getController().equalsIgnoreCase(subController);
          if (isActive) isMenuSelected = true;

          if (subController.length() == 0) {
  %>
        <span class="sb-sub-item sb-sub-disabled"><span class="sb-sub-dot"></span><span><%=subIcon%>&nbsp;<%=displayName%></span></span>
  <%
          } else {
  %>
        <a class="sb-sub-item<%=(isActive && (selMode == submitType || selMode == SubmitType.SEARCH))?" active":""%>"
           href="javascript:void(0)"
           data-tip="<%=displayName%>"
           onclick="submitPageDataForm('<%=selMode%>','<%=subController%>');">
          <span class="sb-sub-dot"></span><span data-i18n="<%=displayName%>"><%=displayName%></span>
        </a>
  <%
          }
        }
      }
  %>
      </div>
    </div>
  <%
      if (isMenuSelected) {
  %>
    <script>
    (function() {
      var el = document.getElementById("menu_<%=moduleArray[i][0].replaceAll(" ","")%>_LiID");
      if (el) { el.classList.add("open"); var sub = el.nextElementSibling; if (sub) sub.classList.add("open"); }
    })();
    </script>
  <%
      }

    } else if (controllerName.startsWith("jsp:")) {
      String jspPage = controllerName.substring(4);
  %>
    <a class="sb-item" href="<%=ctx%>/jsp/<%=jspPage%>.jsp" data-tip="<%=moduleArray[i][0]%>"
       <%if(requestUri.contains("/" + jspPage + ".jsp")){%> aria-current="page"<%}%>>
      <span class="sb-icon"><%=icon%></span><span class="sb-label" data-i18n="<%=moduleArray[i][0]%>"><%=moduleArray[i][0]%></span>
    </a>
  <%
    } else if (controllerName.length() > 0) {
      boolean isActive = _recordBean != null && _recordBean.getController().equalsIgnoreCase(moduleArray[i][1]);
  %>
    <a class="sb-item<%=(isActive)?" active":""%>"
       href="javascript:void(0)"
       data-tip="<%=moduleArray[i][0]%>"
       onclick="submitPageDataForm('<%=SubmitType.SEARCH%>','<%=moduleArray[i][1]%>');">
      <span class="sb-icon"><%=icon%></span><span class="sb-label" data-i18n="<%=moduleArray[i][0]%>"><%=moduleArray[i][0]%></span>
    </a>
  <%
    } else {
  %>
    <span class="sb-item sb-item-disabled">
      <span class="sb-icon"><%=icon%></span><span class="sb-label"><%=moduleArray[i][0]%></span>
    </span>
  <%
    }
  }
  %>
  </div><!-- /sb-nav-scroll -->

  <%}%><%/* !isDriver */%>

  <div class="sb-footer">
    <button type="button" class="sb-prefs-btn" onclick="mvpxTogglePrefs()"
            data-tip="Settings" aria-label="Settings" title="Settings">
      <i class="fas fa-cog" aria-hidden="true"></i>
      <span class="sb-prefs-label" data-i18n="Settings" style="margin-left:8px;">Settings</span>
    </button>
    <a class="sb-item sb-logout" href="javascript:void(0)" data-tip="Sign Out"
       onclick="submitPageDataForm('<%=SubmitType.LOGOUT%>','Login');">
      <span class="sb-icon"><i class="fas fa-sign-out-alt" aria-hidden="true"></i></span>
      <span class="sb-label" data-i18n="Sign Out">Sign Out</span>
    </a>
    <div class="sb-user" data-tip="<%=loginUserDisplayName%>">
      <div class="sb-avatar"><%=userInitials%></div>
      <div class="sb-user-info">
        <div class="sb-user-name"><%=loginUserDisplayName%></div>
        <div class="sb-user-role"><%=loginUserRoles.isEmpty() ? "User" : loginUserRoles%></div>
      </div>
    </div>
  </div>

</nav>

<div class="mvpx-main" id="mvpxMain">
  <%-- ═══ Horizontal group tabs (clickable, each jumps to its default page) + subtabs — mirrors the sidebar moduleArray ═══ --%>
  <%
    java.util.List<String> _tgN = new java.util.ArrayList<String>();
    java.util.List<java.util.List<String[]>> _tgS = new java.util.ArrayList<java.util.List<String[]>>();
    int _actG = 0; java.util.List<String[]> _cw = null;
    for (int _gi = 0; _gi < moduleArray.length; _gi++) {
      if (moduleArray[_gi][0].startsWith("section:")) {
        _tgN.add(moduleArray[_gi][0].substring(8));
        _cw = new java.util.ArrayList<String[]>(); _tgS.add(_cw); continue;
      }
      if (_cw == null) continue;
      String _nm = moduleArray[_gi][0], _ct = moduleArray[_gi][1];
      String _sd = moduleArray[_gi].length > 3 ? moduleArray[_gi][3] : "";
      if (_sd.length() > 0) {                    /* submenu item (e.g. Admin) — flatten its items */
        String _tab = _nm.replaceAll(" ", "").replaceAll("Info", "");
        for (String _blk : _sd.split("#@#")) for (String _it : _blk.split("@@")) {
          String[] _p = _it.split("~"); String _dn = _p[0];
          String _exp = _p.length > 2 ? _p[2] : "";
          if (_exp.startsWith("jsp:")) { String _j = _exp.substring(4); boolean _a = requestUri.contains("/" + _j + ".jsp"); _cw.add(new String[]{_dn, "jsp", _j, _a ? "1" : "0"}); if (_a) _actG = _tgN.size() - 1; continue; }
          String _sc = (_tab + _dn).replaceAll(" ", "").replaceAll("Info", "");
          if ("AdminPhone".equalsIgnoreCase(_sc)) _sc = "AdminPhones";
          else if ("AdminForm".equalsIgnoreCase(_sc)) _sc = "AdminFormsTemplate";
          else if ("AdminUser".equalsIgnoreCase(_sc)) _sc = "EntityUsers";
          else if ("AdminChangePassword".equalsIgnoreCase(_sc)) _sc = "EntityUsers";
          boolean _a = currentController.equalsIgnoreCase(_sc);
          _cw.add(new String[]{_dn, "ctrl", _sc, _a ? "1" : "0"}); if (_a) _actG = _tgN.size() - 1;
        }
      } else if (_ct.startsWith("jsp:")) {
        String _j = _ct.substring(4); boolean _a = requestUri.contains("/" + _j + ".jsp");
        _cw.add(new String[]{_nm, "jsp", _j, _a ? "1" : "0"}); if (_a) _actG = _tgN.size() - 1;
      } else if (_ct.length() > 0) {
        boolean _a = currentController.equalsIgnoreCase(_ct);
        _cw.add(new String[]{_nm, "ctrl", _ct, _a ? "1" : "0"}); if (_a) _actG = _tgN.size() - 1;
      }
    }
    /* default landing page per group: first subtab, except HR->Employees, Admin->Settings */
    java.util.List<String[]> _tgDef = new java.util.ArrayList<String[]>();
    for (int _gi = 0; _gi < _tgN.size(); _gi++) {
      java.util.List<String[]> _subs = _tgS.get(_gi);
      String[] _def = _subs.isEmpty() ? null : _subs.get(0);
      String _want = "HR".equals(_tgN.get(_gi)) ? "AdminEmployee" : ("Admin".equals(_tgN.get(_gi)) ? "AdminConfiguration" : null);
      if (_want != null) for (String[] _s : _subs) if (_want.equalsIgnoreCase(_s[2])) { _def = _s; break; }
      _tgDef.add(_def);
    }
  %>
  <style>
  .mvpx-tabs{background:#fff;border-bottom:1px solid #E4E8F0;flex-shrink:0;position:sticky;top:0;z-index:50}
  .mvpx-tabs-groups{display:flex;align-items:center;gap:2px;padding:0 10px;border-bottom:1px solid #EEF1F6}
  .mvpx-tabs-menu,.mvpx-tabs-prefs{border:none;background:transparent;color:#64748B;cursor:pointer;width:34px;height:34px;border-radius:7px;flex-shrink:0;font-size:15px;display:inline-flex;align-items:center;justify-content:center}
  .mvpx-tabs-menu:hover,.mvpx-tabs-prefs:hover{background:#F1F5F9;color:#111827}
  .mvpx-tabs-grouplist{display:flex;gap:2px;overflow-x:auto;flex:1;min-width:0}
  .mvpx-tg{border:none;background:transparent;padding:9px 13px;font-size:13px;font-weight:700;color:#64748B;cursor:pointer;border-bottom:2px solid transparent;white-space:nowrap;font-family:inherit;text-decoration:none;display:inline-block}
  .mvpx-tg:hover{color:#111827}
  .mvpx-tg.active{color:#2563EB;border-bottom-color:#2563EB}
  .mvpx-tabs-subs{display:none;gap:4px;padding:7px 12px;flex-wrap:wrap;align-items:center}
  .mvpx-tabs-subs.active{display:flex}
  .mvpx-ts{font-size:12.5px;font-weight:600;color:#475569;text-decoration:none;padding:5px 11px;border-radius:7px;white-space:nowrap}
  .mvpx-ts:hover{background:#F1F5F9;color:#111827}
  .mvpx-ts.active{background:var(--status-info-bg);color:var(--status-info-fg);font-weight:700}
  .mvpx-tabs .mvpx-search{margin:0 2px;flex-shrink:0}
  </style>
  <nav class="mvpx-tabs" aria-label="Section tabs">
    <div class="mvpx-tabs-groups">
      <button type="button" class="mvpx-tabs-menu" onclick="mvpxToggleSidebar()" aria-label="Toggle menu" title="Menu"><i class="fas fa-bars" aria-hidden="true"></i></button>
      <div class="mvpx-tabs-grouplist">
      <% for (int _gi = 0; _gi < _tgN.size(); _gi++) { if (_tgS.get(_gi).isEmpty()) continue;
           String[] _d = _tgDef.get(_gi);
           String _dh = (_d != null && "jsp".equals(_d[1])) ? (ctx + "/jsp/" + _d[2] + ".jsp") : "javascript:void(0)"; %>
      <a class="mvpx-tg<%= _gi == _actG ? " active" : "" %>" href="<%=_dh%>"<%if(_d != null && "ctrl".equals(_d[1])){%> onclick="submitPageDataForm('<%=SubmitType.SEARCH%>','<%=_d[2]%>')"<%}%>><%=_tgN.get(_gi)%></a>
      <% } %>
      </div>
      <%if(!"yes".equalsIgnoreCase(hideTopbarSearch)){%>
      <div class="mvpx-search">
        <span class="mvpx-search-icon"><i class="fas fa-search" aria-hidden="true"></i></span>
        <input type="text" placeholder="Search records…" data-search="true" data-i18n="Search records…"
               data-controller="<%=currentController%>" data-submit-type="<%=SubmitType.SEARCH%>" aria-label="Search records">
        <span class="mvpx-search-hint" data-i18n="Enter">Enter</span>
      </div>
      <%}%>
      <button type="button" class="mvpx-tabs-prefs" onclick="mvpxTogglePrefs()" aria-label="Preferences" title="Preferences"><i class="fas fa-sliders-h" aria-hidden="true"></i></button>
    </div>
    <% java.util.List<String[]> _actSubs = (_actG >= 0 && _actG < _tgS.size()) ? _tgS.get(_actG) : null;
       if (_actSubs != null && !_actSubs.isEmpty()) { %>
    <div class="mvpx-tabs-subs active">
      <% for (String[] _s : _actSubs) {
           String _hr = "jsp".equals(_s[1]) ? (ctx + "/jsp/" + _s[2] + ".jsp") : "javascript:void(0)"; %>
      <a class="mvpx-ts<%= "1".equals(_s[3]) ? " active" : "" %>" href="<%=_hr%>"<%if("ctrl".equals(_s[1])){%> onclick="submitPageDataForm('<%=SubmitType.SEARCH%>','<%=_s[2]%>')"<%}%>><%=_s[0]%></a>
      <% } %>
    </div>
    <% } %>
  </nav>
  <div class="mvpx-body" id="mvpxMainContent">

<%} else {%>
<div class="mvpx-popup-wrap">
<%}%>

<%if("yes".equalsIgnoreCase(shellNoForm)){%>
<form id="formmain" name="formmain" method="post" action="Javascript:#" class="mvpx-nav-form">
<input type="hidden" id="entityID"            name="entityID"            value="<%=entityID%>">
<input type="hidden" id="loginUser"            name="loginUser"           value="<%=loginUser%>">
<input type="hidden" id="loginUserDisplayName" name="loginUserDisplayName" value="<%=loginUserDisplayName%>">
<input type="hidden" id="loginUserID"          name="loginUserID"         value="<%=loginUserID%>">
<input type="hidden" id="loginUserRoles"       name="loginUserRoles"      value="<%=loginUserRoles%>">
<input type="hidden" id="pageSubmitLock"       name="pageSubmitLock"      value="">
</form>
<%} else {%>
<form id="formmain" name="formmain" method="post" action="Javascript:#"
      <%if(submitType == SubmitType.UPLOAD){%>ENCTYPE="multipart/form-data"<%}%>>
<input type="hidden" id="entityID"            name="entityID"            value="<%=entityID%>">
<input type="hidden" id="loginUser"            name="loginUser"           value="<%=loginUser%>">
<input type="hidden" id="loginUserDisplayName" name="loginUserDisplayName" value="<%=loginUserDisplayName%>">
<input type="hidden" id="loginUserID"          name="loginUserID"         value="<%=loginUserID%>">
<input type="hidden" id="loginUserRoles"       name="loginUserRoles"      value="<%=loginUserRoles%>">
<input type="hidden" id="pageSubmitLock"       name="pageSubmitLock"      value="">
<%if("yes".equalsIgnoreCase(isPopup)){%>
<input type="hidden" id="isPopup" name="isPopup" value="<%=isPopup%>">
<%}%>
<%}%>

<%@ include file="includeSubnavTabs.jsp" %>

<%if(!"yes".equalsIgnoreCase(isPopup)){%>
<div class="mvpx-prefs-backdrop" id="mvpxPrefsBackdrop" onclick="mvpxClosePrefs()"></div>
<aside class="mvpx-prefs-panel" id="mvpxPrefsPanel" aria-hidden="true" aria-label="Preferences">
  <div class="mvpx-prefs-hdr">
    <h2 data-i18n="Preferences">Preferences</h2>
    <button type="button" class="mvpx-prefs-close" onclick="mvpxClosePrefs()" aria-label="Close">&times;</button>
  </div>
  <div class="mvpx-prefs-body">
    <div class="mvpx-prefs-section">
      <h3 data-i18n="Theme color">Theme color</h3>
      <div class="mvpx-theme-swatches" role="group" aria-label="Theme color">
        <button type="button" class="mvpx-theme-swatch active" data-theme="blue" style="background:#2563eb"
                onclick="mvpxSetTheme('blue')" aria-label="Blue theme" aria-pressed="true"></button>
        <button type="button" class="mvpx-theme-swatch" data-theme="green" style="background:#059669"
                onclick="mvpxSetTheme('green')" aria-label="Green theme" aria-pressed="false"></button>
        <button type="button" class="mvpx-theme-swatch" data-theme="purple" style="background:#7c3aed"
                onclick="mvpxSetTheme('purple')" aria-label="Purple theme" aria-pressed="false"></button>
        <button type="button" class="mvpx-theme-swatch" data-theme="slate" style="background:#475569"
                onclick="mvpxSetTheme('slate')" aria-label="Slate theme" aria-pressed="false"></button>
        <button type="button" class="mvpx-theme-swatch" data-theme="orange" style="background:#ea580c"
                onclick="mvpxSetTheme('orange')" aria-label="Orange theme" aria-pressed="false"></button>
      </div>
    </div>
    <div class="mvpx-prefs-section">
      <h3 data-i18n="Language">Language</h3>
      <div class="mvpx-lang-toggle" role="group" aria-label="Language">
        <button type="button" class="mvpx-lang-btn active" id="mvpxLangEn"
                onclick="mvpxSetLang('en')" data-i18n="English">English</button>
        <button type="button" class="mvpx-lang-btn" id="mvpxLangEs"
                onclick="mvpxSetLang('es')" data-i18n="Español">Español</button>
      </div>
    </div>
    <div class="mvpx-prefs-section">
      <h3 data-i18n="Accessibility">Accessibility</h3>
      <label class="mvpx-a11y-option">
        <input type="checkbox" id="mvpxA11yLarge" onchange="mvpxToggleA11y('large', this.checked)">
        <span data-i18n="Larger text">Larger text</span>
      </label>
      <label class="mvpx-a11y-option">
        <input type="checkbox" id="mvpxA11yContrast" onchange="mvpxToggleA11y('contrast', this.checked)">
        <span data-i18n="High contrast">High contrast</span>
      </label>
      <label class="mvpx-a11y-option">
        <input type="checkbox" id="mvpxA11yMotion" onchange="mvpxToggleA11y('motion', this.checked)">
        <span data-i18n="Reduce motion">Reduce motion</span>
      </label>
    </div>
  </div>
</aside>
<%}%>
