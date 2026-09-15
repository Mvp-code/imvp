# MVPx review checklist

Read from `SKILL.md` when scoring findings. Confirm in code; do not paste this list into the user report.

## Navigation and entry

- [ ] `jsp/includeSidebar.jsp` vs `jsp/includeHeader.jsp` `moduleArray` — pages in one but not the other
- [ ] Mix of `/servlet/MVPGServlet?controller=` and raw `/jsp/Foo.jsp` hrefs
- [ ] Sample/backup still linked or browseable: `login_Backup1.jsp`, `*Sample.jsp`
- [ ] `_sbPage` keys match actual controller/JSP names (active state wrong = user is lost)
- [ ] TechAdmin-only blocks vs pages that still render for other roles

## Auth and session

- [ ] `MVPGServlet` reads `loginUser`, `loginUserID`, `loginUserRoles` from request parameters
- [ ] No `<filter>` in `WEB-INF/web.xml` — JSPs may be hittable without the servlet
- [ ] Login/session invalidation on `submitType=11`
- [ ] Driver role `"4"` vs `TechAdmin` string vs other numeric roles — inconsistent gates
- [ ] `entityID` scoping on fetches/updates (cross-entity data leak)

## Data and SQL

- [ ] DAO SQL concatenated with `db.getInsertDBValue` / string + rather than bound parameters
- [ ] `MainCtrl.getRequestVal` escapes `'` by doubling — not parameterization
- [ ] Search filters from `searchFilter` / request maps into WHERE clauses
- [ ] Deletes/status changes without optimistic checks
- [ ] File paths and vehicle numbers interpolated into filesystem or SQL

## Uploads and documents

- [ ] `serverUploadPath` empty in `web.xml`; UAT vs laptop roots in comments
- [ ] `docs/` under the webapp (RegistrationForms, EmployeeForms, signatures)
- [ ] `ServerUploadPaths` / `FileUpload` path traversal, overwrite, content-type
- [ ] Generated PDFs and PNG signatures appearing as git untracked files

## UI / CSS

- [ ] Changes belong in `jsp/assets/css/mvpx.css` or `mvpx-list.css`, not parked `mvpg-*`
- [ ] Fragile tabular create/edit: `:has()`, `display: contents`, flex, `min-width`, sticky footer
- [ ] Preserve `.mvpx-sidebar.collapsed`, `.sb-item[data-tip]`, `.sb-has-sub.open`, `.sb-backdrop.visible`, `.mvpx-prefs-panel.open`, `data-th`
- [ ] Per-page one-off colors vs CSS variables
- [ ] Forms: labels, errors, disabled submit, 44px targets

## Pages worth extra attention

Live operational loops — review these before cosmetic pages:

- DA Status / Checkin / Checkout
- DA Onboarding + Onboarding Dashboard + application form
- Employees, schedule, terminations
- Fleet inventory, vehicles, gas cards
- Incidents / inspections
- Generic SMS / Emily console
- Smart upload / generic upload / employee forms
- Login and EntityUsers

## Ops

- [ ] Hardcoded `C:/Program Files/Apache Software Foundation/Tomcat 9.0/webapps/MVPx` in `web.xml`
- [ ] `web-app` 2.3 DTD — no servlet filters, limited security-constraint usage
- [ ] `System.out.println` in controllers (noise, no operator-facing error)
- [ ] Twilio / Drive / ingest credentials only from Admin Configuration or env
