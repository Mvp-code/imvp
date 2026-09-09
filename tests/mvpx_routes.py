"""
MVPx navigation routes — mirrors jsp/includeHeader.jsp moduleArray + submenu resolution.
Update this file when the sidebar menu changes.
"""

from __future__ import annotations

import re
from dataclasses import dataclass
from typing import List, Optional

SUBMIT_SEARCH = 1
SUBMIT_CHANGE = 17

ADMIN_TABS_STANDARD = (
    "Gas Card@@Phone@@Form@@Change Password"
)
ADMIN_TABS_TECH = (
    "Gas Card@@Phone@@Form@@User@@Configuration@@Change Password"
)


@dataclass
class NavRoute:
    label: str
    group: str
    kind: str  # "jsp" | "servlet"
    path: str = ""
    controller: str = ""
    submit_type: int = SUBMIT_SEARCH
    tech_admin_only: bool = False
    expect_fragment: str = ""

    def servlet_url(self, base: str) -> str:
        return f"{base}/servlet/MVPGServlet?submitType={self.submit_type}&controller={self.controller}"

    def full_path(self, base: str) -> str:
        if self.kind == "jsp":
            return f"{base}{self.path}"
        return self.servlet_url(base)


def _suffix_plural(display: str) -> str:
    if display.endswith("Category") or display.endswith("Availability") or display.endswith("Password"):
        return display
    return display + "s"


def _resolve_sub_controller(parent_label: str, display_name: str, explicit: str = "") -> tuple[str, int, bool]:
    """Returns (controller, submit_type, disabled)."""
    if explicit.startswith("jsp:"):
        return explicit[4:], SUBMIT_SEARCH, False

    tab_name = parent_label.replace(" ", "").replace("Info", "")
    sub = (tab_name + display_name).replace(" ", "").replace("Info", "")
    submit_type = SUBMIT_SEARCH

    if sub.lower() == "adminphone":
        sub = "AdminPhones"
    elif sub.lower() == "adminform":
        sub = "AdminFormsTemplate"
    elif sub.lower() == "adminuser":
        sub = "EntityUsers"
    elif sub.lower() == "adminchangepassword":
        sub = "EntityUsers"
        submit_type = SUBMIT_CHANGE
    elif tab_name.lower() == "incident":
        if sub.lower() == "incidentincident":
            sub = "Incident"
        else:
            sub = "Admin" + sub
    elif tab_name.lower() == "employee":
        if sub.lower() == "employeeemployee":
            sub = "AdminEmployee"
        elif sub.lower() == "employeeform":
            sub = "EmployeeForms"
        elif sub.lower() == "employeeonboarding":
            return "", submit_type, True
        else:
            sub = sub  # EmployeeAvailability etc.
    elif tab_name.lower() == "vehicle":
        if sub.lower() == "vehiclevehicle":
            sub = "AdminVehicle"

    return sub, submit_type, False


def _parse_submenu(parent_label: str, sub_menu: str) -> List[NavRoute]:
    routes: List[NavRoute] = []
    for chunk in sub_menu.split("@@"):
        parts = chunk.split("~")
        display = parts[0].strip()
        if not display:
            continue
        explicit = parts[2] if len(parts) > 2 else ""
        if explicit.startswith("jsp:"):
            jsp_name = explicit[4:]
            routes.append(NavRoute(
                label=display,
                group=parent_label,
                kind="jsp",
                path=f"/jsp/{jsp_name}.jsp",
                controller=jsp_name,
                expect_fragment="mvpx-shell",
            ))
            continue
        controller, submit_type, disabled = _resolve_sub_controller(parent_label, display, explicit)
        if disabled or not controller:
            continue
        routes.append(NavRoute(
            label=_suffix_plural(display),
            group=parent_label,
            kind="servlet",
            controller=controller,
            submit_type=submit_type,
            expect_fragment="mvpx-shell",
        ))
    return routes


def build_nav_routes(tech_admin: bool = False) -> List[NavRoute]:
    """All sidebar + subnav routes (logged-in dispatcher, not driver)."""
    admin_sub = ADMIN_TABS_TECH if tech_admin else ADMIN_TABS_STANDARD
    routes: List[NavRoute] = [
        NavRoute("Home", "Operations", "jsp", "/jsp/home.jsp", "home", expect_fragment="MVP"),
        NavRoute("Dashboard", "Operations", "servlet", controller="EmployeeDashboard",
                 expect_fragment="mvpx-shell"),
        NavRoute("DA Confirmations", "Operations", "servlet", controller="DAStatus",
                 expect_fragment="mvpx-shell"),
        NavRoute("DA Checkins", "Operations", "servlet", controller="DACheckin",
                 expect_fragment="mvpx-shell"),
        NavRoute("DA Checkouts", "Operations", "servlet", controller="DACheckout",
                 expect_fragment="mvpx-shell"),
        NavRoute("SMS", "Operations", "servlet", controller="GenericSMS",
                 expect_fragment="mvpx-shell"),
    ]

    routes.extend(_parse_submenu("Employee Info", "DA Onboarding~~jsp:DAOnboarding@@Employee@@Availability@@Form@@Schedule@@Termination"))
    routes.extend([
        NavRoute("Coaching Followup", "People", "servlet", controller="EmployeeCoachingFollowup",
                 expect_fragment="mvpx-shell"),
        NavRoute("Employee Requests", "People", "servlet", controller="EmployeeRequest",
                 expect_fragment="mvpx-shell"),
        NavRoute("Employee Uploads", "People", "servlet", controller="CommonUpload",
                 expect_fragment="mvpx-shell"),
        NavRoute("OSHA Incidents", "People", "servlet", controller="EmployeeIncident",
                 expect_fragment="mvpx-shell"),
    ])
    routes.extend(_parse_submenu("Incident", "Type@@Category@@Incident"))
    routes.extend(_parse_submenu("Vehicle Info", "Vehicle@@Inspection"))
    routes.extend([
        NavRoute("Uploads", "Documents", "servlet", controller="GenericUpload",
                 expect_fragment="mvpx-shell"),
        NavRoute("Smart Upload", "Documents", "servlet", controller="SmartUpload",
                 expect_fragment="mvpx-shell"),
        NavRoute("Upload History", "Documents", "servlet", controller="UploadHistory",
                 expect_fragment="mvpx-shell"),
        NavRoute("Reports", "Reports", "servlet", controller="Reports",
                 expect_fragment="mvpx-shell"),
    ])
    routes.extend(_parse_submenu("Admin", admin_sub))
    if tech_admin:
        for r in routes:
            if r.controller in ("EntityUsers",) and r.submit_type == SUBMIT_CHANGE:
                pass
            if r.label in ("Configuration",):
                r.tech_admin_only = True
    return routes


# Servlet controllers should have a DAO class
EXPECTED_DAO = re.compile(r"class\s+(\w+DAO)")

FAIL_MARKERS = (
    "JasperException",
    "HTTP Status 500",
    "Unable to compile class for JSP",
    "Error report",
    "java.lang.NullPointerException",
)
