#!/usr/bin/env python3
"""
MVPx navigation link smoke tests.

Static checks (no server): JSP files + DAO classes exist for every route.
HTTP checks (needs Tomcat + login): each menu URL returns 200 without server errors.

Usage:
  set MVPX_BASE_URL=http://localhost:8080/MVPx
  set MVPX_TEST_USER=your@email.com
  set MVPX_TEST_PASSWORD=yourpassword
  python tests/test_nav_links.py

  python tests/test_nav_links.py --static-only
  python tests/test_nav_links.py --tech-admin
"""

from __future__ import annotations

import argparse
import os
import re
import sys
import urllib.error
import urllib.parse
import urllib.request
from http.cookiejar import CookieJar
from pathlib import Path

# Allow running as script from repo root or tests/
ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(Path(__file__).resolve().parent))

from mvpx_routes import FAIL_MARKERS, NavRoute, build_nav_routes

JSP_DIR = ROOT / "jsp"
DAO_DIR = ROOT / "src" / "com" / "dataobjects"

HIDDEN_INPUT = re.compile(
    r'<input[^>]*type=["\']hidden["\'][^>]*name=["\']([^"\']+)["\'][^>]*value=["\']([^"\']*)["\']',
    re.I,
)
HIDDEN_INPUT_ALT = re.compile(
    r'<input[^>]*name=["\']([^"\']+)["\'][^>]*type=["\']hidden["\'][^>]*value=["\']([^"\']*)["\']',
    re.I,
)


def scrape_hidden_fields(html: str) -> dict[str, str]:
    fields: dict[str, str] = {}
    for pattern in (HIDDEN_INPUT, HIDDEN_INPUT_ALT):
        for m in pattern.finditer(html):
            fields[m.group(1)] = m.group(2)
    return fields


class HttpSession:
    def __init__(self, base_url: str, timeout: int = 30):
        self.base = base_url.rstrip("/")
        self.timeout = timeout
        self.jar = CookieJar()
        self.opener = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(self.jar))

    def request(self, url: str, method: str = "GET", data: dict | None = None) -> tuple[int, str, str]:
        body = None
        headers = {"User-Agent": "MVPx-NavTest/1.0"}
        if data is not None:
            body = urllib.parse.urlencode(data).encode("utf-8")
            headers["Content-Type"] = "application/x-www-form-urlencoded"
        req = urllib.request.Request(url, data=body, headers=headers, method=method)
        try:
            with self.opener.open(req, timeout=self.timeout) as resp:
                raw = resp.read()
                charset = resp.headers.get_content_charset() or "utf-8"
                return resp.status, raw.decode(charset, errors="replace"), resp.geturl()
        except urllib.error.HTTPError as e:
            raw = e.read()
            charset = e.headers.get_content_charset() if e.headers else None
            charset = charset or "utf-8"
            return e.code, raw.decode(charset, errors="replace"), url

    def login(self, user: str, password: str) -> tuple[bool, str]:
        url = f"{self.base}/servlet/MVPGServlet?submitType=11&controller=Login"
        status, body, final_url = self.request(
            url, "POST", {"loginUser": user, "loginPwd": password}
        )
        if status >= 500:
            return False, f"Login HTTP {status}"
        if "MVPG Login" in body and "loginPwd" in body:
            return False, "Login failed — still on login page (check credentials)"
        self.form_fields = scrape_hidden_fields(body)
        # Load a shell page to capture hidden nav form fields
        boot_url = f"{self.base}/servlet/MVPGServlet?submitType=1&controller=StationDashboard"
        boot_fields = dict(self.form_fields)
        boot_fields.setdefault("entityID", "1")
        boot_fields.setdefault("pageSubmitLock", "")
        st2, html2, _ = self.request(boot_url, "POST", boot_fields)
        if st2 == 200:
            scraped = scrape_hidden_fields(html2)
            if scraped.get("loginUser"):
                self.form_fields = scraped
                return True, "Logged in (bootstrapped from StationDashboard)"
        if self.form_fields.get("loginUser"):
            return True, "Logged in"
        return False, "Login may have succeeded but session form fields were not found"

    def fetch_route(self, route: NavRoute) -> tuple[int, str]:
        if route.kind == "jsp":
            status, body, _ = self.request(route.full_path(self.base))
            return status, body
        fields = dict(getattr(self, "form_fields", {}))
        fields.setdefault("pageSubmitLock", "")
        url = route.servlet_url(self.base)
        status, body, _ = self.request(url, "POST", fields)
        return status, body


def expected_jsp_for_controller(controller: str) -> list[Path]:
    """Servlet SEARCH forwards to Controller.jsp or searchList.jsp."""
    for name in (controller + ".jsp",):
        specific = JSP_DIR / name
        if specific.exists():
            return [specific]
    return [JSP_DIR / "searchList.jsp"]


def run_static_tests(routes: list[NavRoute]) -> list[str]:
    errors: list[str] = []
    seen: set[str] = set()

    for route in routes:
        key = f"{route.kind}:{route.controller or route.path}:{route.label}"
        if key in seen:
            errors.append(f"DUPLICATE route key: {key} ({route.label})")
        seen.add(key)

        if route.kind == "jsp":
            jsp_path = ROOT / route.path.lstrip("/").replace("/", os.sep)
            if not jsp_path.is_file():
                errors.append(f"MISSING JSP: {route.label} -> {jsp_path}")
        else:
            dao = DAO_DIR / f"{route.controller}DAO.java"
            jsp_direct = JSP_DIR / f"{route.controller}.jsp"
            if not dao.is_file() and not jsp_direct.is_file():
                errors.append(f"MISSING DAO/JSP: {route.label} -> {route.controller}")
            for jsp in expected_jsp_for_controller(route.controller):
                if not jsp.is_file():
                    errors.append(f"MISSING forward JSP for {route.controller}: {jsp}")

    header = ROOT / "jsp" / "includeHeader.jsp"
    if header.is_file():
        text = header.read_text(encoding="utf-8", errors="replace")
        skip_controller_warn = {
            "EmployeeAvailability", "AdminConfiguration", "AdminIncidentType",
            "AdminIncidentCategory", "EmployeeForms", "EmployeeSchedule",
            "EmployeeTermination", "AdminEmployee", "VehicleInspection",
            "AdminGasCard", "AdminPhones", "AdminFormsTemplate", "EntityUsers",
            "Incident", "AdminVehicle", "DAOnboarding", "SmartUpload", "UploadHistory",
            "StationDashboard", "ReturnsBoard", "WaveSheet", "GenericSMS",
            "EmployeeCoachingFollowup", "EmployeeRequest", "CommonUpload",
            "EmployeeIncident", "GenericUpload", "Reports", "DATask",
        }
        for route in routes:
            if route.kind == "servlet" and route.controller:
                if route.controller not in text and route.controller not in skip_controller_warn:
                    errors.append(
                        f"WARN: controller {route.controller} ({route.label}) not found in includeHeader.jsp"
                    )

    return errors


def run_http_tests(session: HttpSession, routes: list[NavRoute]) -> list[str]:
    errors: list[str] = []
    ok = 0
    for route in routes:
        try:
            status, body = session.fetch_route(route)
        except Exception as ex:
            errors.append(f"FAIL {route.group} > {route.label}: {ex}")
            continue

        if status >= 500:
            errors.append(f"FAIL {route.group} > {route.label}: HTTP {status} — {route.full_path(session.base)}")
            continue
        if status == 302 or (status == 200 and "MVPG Login" in body):
            errors.append(f"FAIL {route.group} > {route.label}: redirected to login (session lost?)")
            continue
        for marker in FAIL_MARKERS:
            if marker in body:
                errors.append(f"FAIL {route.group} > {route.label}: page contains '{marker}'")
                break
        else:
            if route.expect_fragment and route.expect_fragment not in body:
                errors.append(
                    f"WARN {route.group} > {route.label}: expected '{route.expect_fragment}' not in response "
                    f"(HTTP {status}) — page may use different layout"
                )
            ok += 1

    print(f"HTTP OK: {ok}/{len(routes)} routes")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description="MVPx navigation link tests")
    parser.add_argument("--static-only", action="store_true", help="Only verify files exist")
    parser.add_argument("--tech-admin", action="store_true", help="Include TechAdmin-only menu items")
    parser.add_argument("--base-url", default=os.environ.get("MVPX_BASE_URL", "http://localhost:8080/MVPx"))
    parser.add_argument("--user", default=os.environ.get("MVPX_TEST_USER", ""))
    parser.add_argument("--password", default=os.environ.get("MVPX_TEST_PASSWORD", ""))
    args = parser.parse_args()

    routes = build_nav_routes(tech_admin=args.tech_admin)
    print(f"MVPx nav test — {len(routes)} routes")
    print(f"Project root: {ROOT}")

    static_errors = run_static_tests(routes)
    if static_errors:
        print("\n--- Static check issues ---")
        for e in static_errors:
            print(f"  {e}")
    else:
        print("\nStatic checks: ALL PASSED")

    if args.static_only:
        return 1 if static_errors else 0

    if not args.user or not args.password:
        print("\nSkipping HTTP tests — set MVPX_TEST_USER and MVPX_TEST_PASSWORD (or --user / --password)")
        return 1 if static_errors else 0

    print(f"\nHTTP tests against {args.base_url} as {args.user}")
    session = HttpSession(args.base_url)
    ok, msg = session.login(args.user, args.password)
    print(f"Login: {msg}")
    if not ok:
        print("HTTP tests aborted.")
        return 1

    http_errors = run_http_tests(session, routes)
    if http_errors:
        print("\n--- HTTP failures ---")
        for e in http_errors:
            print(f"  {e}")

    total_errors = static_errors + http_errors
    if total_errors:
        print(f"\nFAILED — {len(total_errors)} issue(s)")
        return 1
    print("\nPASSED — all navigation links OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
