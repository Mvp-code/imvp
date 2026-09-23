#!/usr/bin/env python3
"""MVPx page smoke + Smart Upload pack. See ../SKILL.md."""
from __future__ import print_function

import argparse
import os
import re
import ssl
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from http.cookiejar import CookieJar

DEFAULT_USER = "9082960064"
DEFAULT_FILES = {
    "employee": r"C:\Users\mvplo\Downloads\AssociateData (22).csv",
    "schedule": r"C:\Users\mvplo\Downloads\Week-39-Schedule.xlsx",
    "itineraries": r"C:\Users\mvplo\Downloads\Itineraries_DNK7_2026-09-22_00_42 (EDT).xlsx",
}

SERVLET_PAGES = [
    "DACheckin",
    "DAStatus",
    "DACheckout",
    "Incident",
    "ReturnsBoard",
    "WaveSheet",
    "AdminEmployee",
    "EmployeeForms",
    "AdminVehicle",
    "AdminPhones",
    "AdminGasCard",
    "SmartUpload",
    "UploadHistory",
    "StationDashboard",
    "AdminFormsTemplate",
    "EntityUsers",
    "AdminConfiguration",
    "AdminIncidentType",
    "AdminIncidentCategory",
    "DATask",
    "GenericSMS",
    "EmployeeIncident",
    "EmployeeCoachingFollowup",
    "EmployeeRequest",
    "EmployeeAvailability",
    "EmployeeSchedule",
    "EmployeeTermination",
    "VehicleInspection",
    "GenericUpload",
    "CommonUpload",
    "Reports",
]

JSP_PAGES = [
    "DispatcherTaskBoard.jsp",
    "DAOnboarding.jsp",
    "DAOnboardingDashboard.jsp",
    "FleetTaskBoard.jsp",
    "FleetInventoryDashboard.jsp",
    "IngestDiscovery.jsp",
    "PredictScorecard.jsp",
    "MVPxReports.jsp",
    "DAStandardWorkDocument.jsp",
    "DispatcherStandardWorkDocument.jsp",
    "EmilyConsole.jsp",
    "DailyStatus.jsp",
    "PortalResources.jsp",
    "BridgeHelp.jsp",
    "home.jsp",
]

FAIL_MARKERS = (
    "HTTP Status 500",
    "javax.servlet.ServletException",
    "org.apache.jasper",
    "java.lang.NullPointerException",
    "ClassCastException",
    "Upload failed:",
)


class Client(object):
    def __init__(self, base, timeout=120):
        self.base = base.rstrip("/")
        self.timeout = timeout
        self.cj = CookieJar()
        ctx = ssl.create_default_context()
        self.opener = urllib.request.build_opener(
            urllib.request.HTTPCookieProcessor(self.cj),
            urllib.request.HTTPSHandler(context=ctx),
        )

    def url(self, path):
        if path.startswith("http"):
            return path
        if not path.startswith("/"):
            path = "/" + path
        return self.base + path

    def open(self, path, data=None, headers=None, method=None):
        req = urllib.request.Request(
            self.url(path), data=data, method=method or ("POST" if data else "GET")
        )
        req.add_header("User-Agent", "MVPx-uat-test")
        for k, v in (headers or {}).items():
            req.add_header(k, v)
        try:
            res = self.opener.open(req, timeout=self.timeout)
            body = res.read()
            try:
                text = body.decode("utf-8", "replace")
            except Exception:
                text = ""
            return res.getcode(), text, res.geturl()
        except urllib.error.HTTPError as e:
            body = e.read() if e.fp else b""
            try:
                text = body.decode("utf-8", "replace")
            except Exception:
                text = ""
            return e.code, text, self.url(path)
        except Exception as e:
            return 0, str(e), self.url(path)


def looks_like_login(html, final_url):
    u = (final_url or "").lower()
    if "login.jsp" in u:
        return True
    h = html or ""
    return 'id="loginPwd"' in h and "controller=Login" in h and "DA Checkins" not in h


def page_ok(code, html, final_url, allow_login=False):
    if code != 200:
        return False, "http %s" % code
    if not allow_login and looks_like_login(html, final_url):
        return False, "redirected to login"
    low = html.lower()
    for m in FAIL_MARKERS:
        if m.lower() in low:
            return False, m
    if len(html) < 80:
        return False, "tiny body (%s)" % len(html)
    return True, "ok"


def multipart(fields, files):
    boundary = "----MvpxUat7e3b1c"
    chunks = []
    for name, value in fields:
        chunks.append("--" + boundary)
        chunks.append('Content-Disposition: form-data; name="%s"' % name)
        chunks.append("")
        chunks.append(value)
    for name, path in files:
        fn = os.path.basename(path)
        with open(path, "rb") as f:
            raw = f.read()
        chunks.append("--" + boundary)
        chunks.append(
            'Content-Disposition: form-data; name="%s"; filename="%s"'
            % (name, fn.replace('"', ""))
        )
        chunks.append("Content-Type: application/octet-stream")
        chunks.append("")
        chunks.append(raw)
    chunks.append("--" + boundary + "--")
    chunks.append("")
    body = b"\r\n".join(
        c if isinstance(c, bytes) else c.encode("utf-8") for c in chunks
    )
    return body, "multipart/form-data; boundary=" + boundary


def login(client, user, password):
    qs = urllib.parse.urlencode(
        {
            "submitType": "11",
            "controller": "Login",
            "loginUser": user,
            "loginPwd": password,
        }
    )
    code, html, url = client.open(
        "/servlet/MVPGServlet?" + qs, data=b"", method="POST"
    )
    ok, reason = page_ok(code, html, url)
    if not ok:
        return False, reason
    if "DACheckin" not in html and "DA Checkin" not in html:
        return False, "did not land on check-in"
    return True, "logged in"


def db_identity():
    try:
        import mysql.connector
    except Exception:
        return [("db", "SKIP", "mysql.connector missing")]
    out = []
    try:
        cn = mysql.connector.connect(
            host="localhost", user="root", password="admin", database="fleetdb"
        )
        cur = cn.cursor()
        cur.execute(
            "SELECT COUNT(*) FROM employee WHERE IFNULL(TRANSPORTERID,'')<>'' "
            "GROUP BY TRANSPORTERID HAVING COUNT(*)>1"
        )
        n = len(cur.fetchall())
        out.append(("dup transporters", "PASS" if n == 0 else "FAIL", str(n)))
        cur.execute(
            "SELECT COUNT(*) FROM ("
            " SELECT EMPLOYEEID, DATE(SCHEDULEDATE) d FROM daconfirmation"
            " WHERE STATUS=0 GROUP BY EMPLOYEEID, DATE(SCHEDULEDATE)"
            " HAVING COUNT(*)>1) x"
        )
        n = cur.fetchone()[0]
        out.append(("dup confirm person-day", "PASS" if n == 0 else "FAIL", str(n)))
        cur.execute(
            "SELECT STATUS, COUNT(*) FROM employee GROUP BY STATUS ORDER BY STATUS"
        )
        out.append(("employee counts", "INFO", str(cur.fetchall())))
        cur.execute(
            "SELECT COUNT(*) FROM entityusers WHERE USERNAME=%s AND STATUS=0",
            (os.environ.get("MVPX_USER", DEFAULT_USER),),
        )
        n = cur.fetchone()[0]
        out.append(("active admin login rows", "PASS" if n == 1 else "FAIL", str(n)))
        cn.close()
    except Exception as e:
        out.append(("db", "SKIP", str(e)[:160]))
    return out


def employee_count():
    try:
        import mysql.connector

        cn = mysql.connector.connect(
            host="localhost", user="root", password="admin", database="fleetdb"
        )
        cur = cn.cursor()
        cur.execute("SELECT COUNT(*) FROM employee")
        n = cur.fetchone()[0]
        cn.close()
        return n
    except Exception:
        return None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--base", default="http://localhost:8080/MVPx")
    ap.add_argument("--user", default=os.environ.get("MVPX_USER", DEFAULT_USER))
    ap.add_argument(
        "--password", default=os.environ.get("MVPX_PASSWORD", "")
    )
    ap.add_argument("--skip-upload", action="store_true")
    ap.add_argument("--skip-db", action="store_true")
    ap.add_argument("--timeout", type=int, default=180)
    args = ap.parse_args()
    password = args.password or args.user

    rows = []
    client = Client(args.base, timeout=args.timeout)

    code, html, url = client.open("/jsp/login.jsp")
    ok, reason = page_ok(code, html, url, allow_login=True)
    rows.append(("login.jsp", "PASS" if ok else "FAIL", reason))

    ok, reason = login(client, args.user, password)
    rows.append(("login POST", "PASS" if ok else "FAIL", reason))
    if not ok:
        print_report(args.base, rows)
        return 1

    for ctrl in SERVLET_PAGES:
        path = "/servlet/MVPGServlet?submitType=1&controller=" + urllib.parse.quote(
            ctrl
        )
        code, html, url = client.open(path)
        ok, reason = page_ok(code, html, url)
        extra = ""
        if ctrl == "AdminVehicle" and ok:
            if re.search(r"0\s+of\s+0", html) and "Operational" in html:
                ok, reason = False, "vehicles empty 0 of 0"
            extra = " rows~%s" % len(re.findall(r"<tr", html, re.I))
        rows.append((ctrl, "PASS" if ok else "FAIL", reason + extra))

    for jsp in JSP_PAGES:
        code, html, url = client.open("/jsp/" + jsp)
        allow = jsp in ("home.jsp", "login.jsp")
        ok, reason = page_ok(code, html, url, allow_login=allow)
        rows.append((jsp, "PASS" if ok else "FAIL", reason))

    before = None if args.skip_db else employee_count()

    uploads = [
        ("Employee", DEFAULT_FILES["employee"], ""),
        ("EmployeeSchedule", DEFAULT_FILES["schedule"], "Next Day Run"),
        ("Daily Itineraries", DEFAULT_FILES["itineraries"], ""),
    ]
    if not args.skip_upload:
        for table, path, selected in uploads:
            if not os.path.isfile(path):
                rows.append((table + " upload", "FAIL", "missing " + path))
                continue
            qs = {
                "submitType": "3",
                "controller": "SmartUpload",
                "tableName": table,
                "dataSeperator": ",",
            }
            if selected:
                qs["selectedType"] = selected
            body, ctype = multipart([], [("uploadFileName", path)])
            t0 = time.time()
            code, html, url = client.open(
                "/servlet/MVPGServlet?" + urllib.parse.urlencode(qs),
                data=body,
                headers={"Content-Type": ctype},
                method="POST",
            )
            elapsed = int(time.time() - t0)
            ok, reason = page_ok(code, html, url)
            if ok and ("error" in (html or "").lower() and "upload failed" in (html or "").lower()):
                ok, reason = False, "upload failed banner"
            rows.append(
                (
                    table + " upload",
                    "PASS" if ok else "FAIL",
                    "%s %ss %s" % (reason, elapsed, os.path.basename(path)),
                )
            )

        after = None if args.skip_db else employee_count()
        if before is not None and after is not None:
            rows.append(
                (
                    "employee row count after associate",
                    "INFO",
                    "%s -> %s" % (before, after),
                )
            )

        for ctrl in ("AdminEmployee", "EmployeeSchedule", "DAStatus", "DACheckin", "UploadHistory", "WaveSheet"):
            path = "/servlet/MVPGServlet?submitType=1&controller=" + ctrl
            code, html, url = client.open(path)
            ok, reason = page_ok(code, html, url)
            rows.append((ctrl + " after upload", "PASS" if ok else "FAIL", reason))

    if not args.skip_db and "localhost" in args.base:
        for name, st, detail in db_identity():
            rows.append((name, st, detail))

    return print_report(args.base, rows)


def print_report(base, rows):
    fails = [r for r in rows if r[1] == "FAIL"]
    print("BASE", base)
    print("%-42s %-6s %s" % ("PAGE", "RESULT", "DETAIL"))
    print("-" * 100)
    for name, st, detail in rows:
        print("%-42s %-6s %s" % (name[:42], st, detail)[:200])
    print("-" * 100)
    print(
        "PASS %s  FAIL %s  INFO/SKIP %s"
        % (
            sum(1 for r in rows if r[1] == "PASS"),
            len(fails),
            sum(1 for r in rows if r[1] not in ("PASS", "FAIL")),
        )
    )
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
