# MVPx Navigation Tests

Automated checks for every sidebar / subnav link. Run after menu or routing changes.

## Quick start

```powershell
cd "C:\Program Files\Apache Software Foundation\Tomcat 9.0\webapps\MVPx"

# 1) Static only — verifies JSP + DAO files exist (no login)
.\tests\run-nav-tests.ps1 -StaticOnly

# 2) Full HTTP smoke test — needs Tomcat running + credentials
$env:MVPX_TEST_USER = "your@email.com"
$env:MVPX_TEST_PASSWORD = "yourpassword"
.\tests\run-nav-tests.ps1
```

Or with Python directly:

Or copy the example and fill in locally (git-ignored):

```powershell
copy tests\.env.example tests\.env
# edit tests\.env with your credentials
```

```bash
python tests/test_nav_links.py --static-only
python tests/test_nav_links.py --user you@email.com --password secret
```

## Environment variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `MVPX_BASE_URL` | `http://localhost:8080/MVPx` | Tomcat app context |
| `MVPX_TEST_USER` | (required for HTTP) | Login username or email |
| `MVPX_TEST_PASSWORD` | (required for HTTP) | Login password |

## What is tested

**Static (always):**
- Each menu route has a target JSP or `*DAO.java`
- No duplicate route keys
- Controllers referenced in `tests/mvpx_routes.py` align with `includeHeader.jsp`

**HTTP (when credentials provided):**
- Login via `MVPGServlet?submitType=11&controller=Login`
- Each **JSP** link: GET → HTTP 200, no Jasper/500 errors
- Each **servlet** link: POST (same as `submitPageDataForm`) → HTTP 200, shell loads
- Fails on: HTTP 5xx, login redirect, `JasperException`, compile errors

## Keeping routes in sync

Route list lives in `tests/mvpx_routes.py` and mirrors `jsp/includeHeader.jsp` `moduleArray` submenu rules.

When you add or rename a menu item in `includeHeader.jsp`, update `mvpx_routes.py` and re-run:

```powershell
.\tests\run-nav-tests.ps1 -StaticOnly
```

## TechAdmin menu

Admin **User** and **Configuration** items are included with `--tech-admin` / `-TechAdmin`:

```powershell
.\tests\run-nav-tests.ps1 -TechAdmin -User admin@example.com -Password secret
```

## CI / pre-deploy

```powershell
.\tests\run-nav-tests.ps1 -StaticOnly
if ($LASTEXITCODE -ne 0) { exit 1 }
# optional: full HTTP if secrets available in CI
```
