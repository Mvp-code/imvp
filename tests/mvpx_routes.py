"""
MVPx navigation routes — mirrors jsp/includeHeader.jsp moduleArray + submenu resolution.
Update this file when the sidebar menu changes.
"""

from __future__ import annotations

import re
from dataclasses import dataclass
from typing import List

SUBMIT_SEARCH = 1
SUBMIT_CHANGE = 17

ADMIN_TABS_STANDARD = (
    "Gas Card@@Phone@@Form@@Change Password"
)
ADMIN_TABS_TECH = (
    "Gas Card@@Phone@@Form@@User@@Configuration@@Change Password"
)

TRAINING_TABS = (
    "DA Standard Work~<i></i>~jsp:DAStandardWorkDocument@@"
    "Dispatcher Standard Work~<i></i>~jsp:DispatcherStandardWorkDocument"
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
            sub = sub
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


def _servlet(label: str, group: str, controller: str) -> NavRoute:
    return NavRoute(label, group, "servlet", controller=controller, expect_fragment="mvpx-shell")


def _jsp(label: str, group: str, jsp_name: str, fragment: str = "mvpx-shell") -> NavRoute:
    return NavRoute(label, group, "jsp", path=f"/jsp/{jsp_name}.jsp", controller=jsp_name,
                    expect_fragment=fragment)


def build_nav_routes(tech_admin: bool = False) -> List[NavRoute]:
    """All sidebar + subnav routes (logged-in dispatcher, not driver).

    Mirrors jsp/includeHeader.jsp moduleArray (live menu).
    """
    admin_sub = ADMIN_TABS_TECH if tech_admin else ADMIN_TABS_STANDARD
    routes: List[NavRoute] = [
        _servlet("Incident", "Operation", "Incident"),
        _servlet("DA Checkins", "Operation", "DACheckin"),
        _servlet("DA Confirmations", "Operation", "DAStatus"),
        _servlet("DA Checkouts", "Operation", "DACheckout"),
        _jsp("Dispatcher Tasks", "Operation", "DispatcherTaskBoard"),
        _servlet("Returns Board", "Operation", "ReturnsBoard"),
        _servlet("Wave Sheet", "Operation", "WaveSheet"),

        _jsp("DA Onboarding", "HR", "DAOnboarding"),
        _servlet("Employees", "HR", "AdminEmployee"),
        _servlet("Forms", "HR", "EmployeeForms"),
        _jsp("Onboarding Dashboard", "HR", "DAOnboardingDashboard"),

        _servlet("Vehicles", "Fleet Management", "AdminVehicle"),
        _jsp("Fleet Tasks", "Fleet Management", "FleetTaskBoard"),
        _jsp("Fleet Inventory", "Fleet Management", "FleetInventoryDashboard"),

        _servlet("Smart Upload", "Uploads", "SmartUpload"),
        _servlet("Upload History", "Uploads", "UploadHistory"),
        _jsp("AMZL Bridge", "Uploads", "IngestDiscovery"),

        _servlet("MVPx Dashboard", "Analytics", "StationDashboard"),
        _jsp("Predict Scorecard", "Analytics", "PredictScorecard"),
        _jsp("MVPx-Reports", "Analytics", "MVPxReports"),
    ]

    routes.extend(_parse_submenu("Training", TRAINING_TABS))
    routes.append(_jsp("Emily Console", "Emily Dispatcher", "EmilyConsole"))
    routes.extend(_parse_submenu("Admin", admin_sub))
    routes.extend([
        _servlet("Settings", "Admin", "AdminConfiguration"),
        _servlet("Types", "Admin", "AdminIncidentType"),
        _servlet("Category", "Admin", "AdminIncidentCategory"),
        _jsp("Daily Status", "Other", "DailyStatus"),
        _servlet("DA Tasks", "Other", "DATask"),
        _jsp("Amazon Portal Links", "Other", "PortalResources"),
        _jsp("Bridge Loading Guide", "Other", "BridgeHelp"),
        _servlet("SMS", "Other", "GenericSMS"),
        _servlet("Coaching Followup", "Other", "EmployeeCoachingFollowup"),
        _servlet("Employee Requests", "Other", "EmployeeRequest"),
        _servlet("Employee Uploads", "Other", "CommonUpload"),
        _servlet("OSHA Incidents", "Other", "EmployeeIncident"),
        _servlet("Availability", "Other", "EmployeeAvailability"),
        _servlet("Schedule", "Other", "EmployeeSchedule"),
        _servlet("Termination", "Other", "EmployeeTermination"),
        _servlet("Vehicle Inspection", "Other", "VehicleInspection"),
        _servlet("Uploads", "Other", "GenericUpload"),
        _servlet("Reports", "Other", "Reports"),
        _jsp("Home", "Other", "home", fragment="MVP"),
    ])

    if tech_admin:
        for r in routes:
            if r.label in ("Configuration", "Settings"):
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
