<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
if (isDriver || "yes".equalsIgnoreCase(isPopup)) {
  /* no subnav for drivers or popups */
} else {
  java.util.List tabItems = new java.util.ArrayList();
  String tabGroupTitle = "";
  String tabGroupClass = "sec-ops";

  for (int ti = 0; ti < moduleArray.length; ti++) {
    String subMenuDetails = moduleArray[ti].length > 3 ? moduleArray[ti][3] : "";
    if (subMenuDetails.length() == 0) continue;

    java.util.List groupTabs = new java.util.ArrayList();
    boolean groupActive = false;
    String parentLabel = moduleArray[ti][0];
    String tabName = parentLabel.replaceAll(" ", "").replaceAll("Info", "");
    String subMenuDetailsArray[] = subMenuDetails.split("#@#");

    for (int j = 0; j < subMenuDetailsArray.length; j++) {
      String subMenuArray[] = subMenuDetailsArray[j].split("@@");
      for (int k = 0; k < subMenuArray.length; k++) {
        String subMenuDataArray[] = subMenuArray[k].split("~");
        String displayName = subMenuDataArray[0];
        int selMode = SubmitType.SEARCH;
        String explicitController = subMenuDataArray.length > 2 ? subMenuDataArray[2] : "";
        boolean isActive = false;
        String tabHref = "";
        String tabOnclick = "";
        boolean tabDisabled = false;

        if (explicitController.startsWith("jsp:")) {
          String jspFile = explicitController.substring(4);
          isActive = requestUri.contains("/" + jspFile + ".jsp")
                  || currentController.equalsIgnoreCase(jspFile);
          tabHref = ctx + "/jsp/" + jspFile + ".jsp";
        } else {
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

          if (subController.length() == 0) {
            tabDisabled = true;
          } else {
            isActive = _recordBean.getController().equalsIgnoreCase(subController);
            tabOnclick = "submitPageDataForm('" + selMode + "','" + subController + "');";
          }
        }

        if (isActive) groupActive = true;

        String tabRow[] = new String[] {
          displayName,
          tabHref,
          tabOnclick,
          tabDisabled ? "1" : "0",
          isActive ? "1" : "0"
        };
        groupTabs.add(tabRow);
      }
    }

    if (groupActive) {
      tabItems = groupTabs;
      tabGroupTitle = parentLabel;
      if (parentLabel.contains("Employee")) tabGroupClass = "sec-ppl";
      else if (parentLabel.contains("Incident") || parentLabel.contains("Vehicle")) tabGroupClass = "sec-saf";
      else if (parentLabel.contains("Training") || parentLabel.contains("Documents")) tabGroupClass = "sec-doc";
      else if (parentLabel.contains("Admin")) tabGroupClass = "sec-adm";
      break;
    }
  }

  if (tabItems.size() > 0) {
%>
<nav class="mvpx-subnav <%=tabGroupClass%>" aria-label="<%=tabGroupTitle%>">
  <div class="mvpx-subnav-label" data-i18n="<%=tabGroupTitle%>"><%=tabGroupTitle%></div>
  <div class="mvpx-subnav-tabs" role="tablist">
<%
    for (int t = 0; t < tabItems.size(); t++) {
      String[] tab = (String[]) tabItems.get(t);
      String tLabel = tab[0];
      String tHref = tab[1];
      String tOnclick = tab[2];
      boolean tDisabled = "1".equals(tab[3]);
      boolean tActive = "1".equals(tab[4]);
      if (tDisabled) {
%>
    <span class="mvpx-subnav-tab disabled" role="tab" aria-disabled="true"><span data-i18n="<%=tLabel%>"><%=tLabel%></span></span>
<%
      } else if (tHref.length() > 0) {
%>
    <a class="mvpx-subnav-tab<%=(tActive)?" active":""%>" role="tab"
       href="<%=tHref%>"<%=(tActive)?" aria-current=\"page\"":""%>>
      <span data-i18n="<%=tLabel%>"><%=tLabel%></span>
    </a>
<%
      } else {
%>
    <a class="mvpx-subnav-tab<%=(tActive)?" active":""%>" role="tab" href="javascript:void(0)"
       onclick="<%=tOnclick%>"<%=(tActive)?" aria-current=\"page\"":""%>>
      <span data-i18n="<%=tLabel%>"><%=tLabel%></span>
    </a>
<%
      }
    }
%>
  </div>
</nav>
<%
  }
}
%>
