---
name: mvpx-uat-test
description: >-
  Runs the MVPx page-and-upload test pack against local Tomcat or UAT. Use when
  the user asks to test all pages, test UAT, smoke-test MVPx, upload AssociateData /
  schedule / itineraries, or verify insert/update after employee identity work.
---

# MVPx UAT / local test pack

Automated HTTP tests plus a page matrix. Browser tools are optional; the runner
does not need them.

## When

- User says test all pages, test UAT, smoke test, or re-run uploads.
- After employee identity, vehicles, check-in, or Smart Upload changes.

## Environments

| Target | Base URL |
|---|---|
| Local | `http://localhost:8080/MVPx` |
| UAT | `http://20.84.71.185/MVPx` |

Login: `MVPX_USER` (default `9082960064`) and `MVPX_PASSWORD` (default same as user).
Do not print the password. Do not commit credentials.

## Default upload files

Use these unless the user names others:

- Associate / Employee: `C:/Users/mvplo/Downloads/AssociateData (22).csv`
- DA Schedule: `C:/Users/mvplo/Downloads/Week-39-Schedule.xlsx`
- Daily Itineraries: `C:/Users/mvplo/Downloads/Itineraries_DNK7_2026-09-22_00_42 (EDT).xlsx`

Smart Upload `CREATE_CONFIRM` (`submitType=3`), `controller=SmartUpload`.
Put `tableName` and `selectedType` on the query string. **Do not** put the Excel
name on the query string (spaces / `(EDT)` break UAT/IIS). File part name:
`uploadFileName`.

| File | `tableName` | Extra |
|---|---|---|
| AssociateData | `Employee` | none |
| Week-*Schedule | `EmployeeSchedule` | `selectedType=Next Day Run` |
| Itineraries_* | `Daily Itineraries` | none |

## Agent workflow

```
Test pack:
- [ ] 1. Read pages.md
- [ ] 2. Run scripts/run_tests.py
- [ ] 3. Report pass/fail per page and per upload
- [ ] 4. On local only, run identity SQL checks
```

```powershell
cd "C:\Program Files\Apache Software Foundation\Tomcat 9.0\webapps\MVPx"
python .cursor/skills/mvpx-uat-test/scripts/run_tests.py --base http://localhost:8080/MVPx
python .cursor/skills/mvpx-uat-test/scripts/run_tests.py --base http://20.84.71.185/MVPx --skip-db
```

`--skip-upload` = page smoke only. `--skip-db` = no MySQL (use on UAT).

## What “good” means

- Login lands on DA Checkins (not `login.jsp`, not empty body).
- Every sidebar / Other page returns HTTP 200, is not the login screen, and has no JSP exception stack.
- Vehicles list is not a blank Operational `0 of 0` after login.
- Associate re-upload does **not** grow `employee` rows for transporters already in the file.
- After schedule upload: one Active confirmation per DA per day; Swap/employee pickers have names.
- Check-in delete (manual) closes that day’s confirmation.

## Identity SQL (local `fleetdb` only)

```sql
SELECT STATUS, COUNT(*) FROM employee GROUP BY STATUS;
SELECT COUNT(*) FROM (
  SELECT TRANSPORTERID FROM employee
  WHERE IFNULL(TRANSPORTERID,'')<>''
  GROUP BY TRANSPORTERID HAVING COUNT(*)>1) x;
SELECT COUNT(*) FROM (
  SELECT EMPLOYEEID, DATE(SCHEDULEDATE) d FROM daconfirmation
  WHERE STATUS=0 GROUP BY EMPLOYEEID, DATE(SCHEDULEDATE) HAVING COUNT(*)>1) x;
```

Dup transporter ids and dup Active confirmations must be **0**.

## Do not

- Remap UAT until local pack is green and the user asks.
- Commit `META-INF/context.xml`, `.env`, Twilio secrets, or the Download xlsx/csv files.
- Send SMS in the automated pack.

Page-by-page insert/update expectations: [pages.md](pages.md).
