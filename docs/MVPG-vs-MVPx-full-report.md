# MVPG vs MVPx — full comparison, documentation, and vehicle assignment

Date: 2026-09-24  
Data: local `fleetdb` (jdbc/MVPGDB). Check-ins from 2026-06-26 through 2026-09-25.  
STATUS: 0 = ACTIVE, 1 = DELETE. Check-in analysis uses STATUS IN (0, 2 POST, 3 COMPLETED).

---

## 1. What each system is

### MVPG (legacy)

Tomcat JSP/Servlet DSP fleet app. Same domain model: ENTITY, EMPLOYEE, VEHICLE, EMPLOYEE_AVAILABILITY, EMPLOYEE_SCHEDULE, DACHECKIN, DACHECKOUT, DACONFIRMATION, GASCARDS, ENTITYUSERS.

Typical submitType values: SEARCH=1, CREATE_CONFIRM=3, UPDATE=5, PRINT=9, DYNAMIC=10, LOGIN=11.

Employee matching on Excel upload: **Active record by mobile, then email**. New transporter IDs insert a second EMPLOYEE row (twins). Swap / employee lists require `REVIEW_STATUS=0` (NULL rows drop off).

Vehicle assignment on schedule upload and DA check-in re-run is the three-pass loop in `EmployeeScheduleDAO` / `DACheckinDAO` (see section 3).

### MVPx (this repo)

Same JSP/Servlet stack, same database, evolved UI and operations boards. Core DA day (schedule → confirmation → check-in → checkout) is intentionally aligned with MVPG after the 2026-09-24 confirmation revert.

**Keep these MVPx changes (not in classic MVPG):**

| Area | MVPx behavior |
|---|---|
| Employee identity | Match **TRANSPORTERID**, then mobile, then email. If STATUS=1, **revive** instead of insert. |
| Users / login | Prefer live employee user rows so an inactive twin cannot steal the login. |
| Swap / Wave employees | `IFNULL(REVIEW_STATUS,0)=0` so NULL review still appears. |
| Schedule re-upload | Do not soft-delete a schedule row unless a replacement row is inserted (avoids orphan check-in). |
| Vehicles grid | Fixed empty grid (`String[22]`). |
| Smart Upload | `tableName` on the query string, not the Excel file name. |
| Extra pages | Wave Sheet, scorecards, task boards, Smart Upload, Tire Tread, MVPx reports. |

**Restored to MVPG (do not keep the later “close confirmation on check-in delete” work):**

- DACONFIRMATION uniqueness is **EMPLOYEEID + date** only.
- Delete check-in does **not** close confirmation.
- Confirmation list is insert-or-skip; no extra STATUS/transporter subquery.

---

## 2. Page-by-page logic (MVPx vs MVPG)

| MVPx page | JSP | Vs MVPG | Logic |
|---|---|---|---|
| Login | `login.jsp` | **DIFF** | MVPx prefers live employee user rows. |
| Home | `home.jsp` | UI DIFF | Same landing; MVPx chrome/nav. |
| Admin Employees | `AdminEmployee.jsp` | **DIFF** | TRANSPORTERID → mobile → email; revive STATUS=1. |
| Entity users | `EntityUsers.jsp` | SAME tables | Linked to employee identity; login restore copies password onto the live row. |
| Employee Schedule | `EmployeeSchedule.jsp` | **DIFF** | Same Amazon file parse; idempotent re-upload; Active employee preferred on transporter lookup. |
| **Vehicle assign** | (DAO, not a page) | **SAME core** | Three passes identical (section 3). |
| DA Status / Confirmation | `DAStatus.jsp` | Data **SAME**, UI extra | Unique person+day. Auto-SMS controls exist in MVPx only. |
| DA Check-in | `DACheckin.jsp` | Delete **SAME**; display extras | Delete check-in only. Itinerary/VIN display may differ. |
| DA Checkout | `DACheckout.jsp` | **SAME data** | Date default aligned. |
| Vehicles | `AdminVehicle.jsp` | MVPx **bugfix** | Empty grid was index/login, not assigner. |
| Vehicle inspection | `VehicleInspection.jsp` | MOSTLY SAME | Same post-check-in path. |
| Gas cards | `AdminGasCard.jsp` | MOSTLY SAME | Open-pool cards exclude in-use IDs. |
| Incidents | `Incident.jsp` / `EmployeeIncident.jsp` | **SAME** | Same tables. |
| Employee forms | `EmployeeForms.jsp` | MOSTLY SAME | File store under `docs/`. |
| Onboarding | `OnBoarding.jsp`, `DAOnboarding.jsp` | MVPx extras | Dashboard/onboarding boards. |
| Smart Upload | `SmartUpload.jsp` | **NEW** | Query-string table name. |
| Wave Sheet | `WaveSheet.jsp` | **NEW** | Uses IFNULL review filter. |
| Scorecards | `PredictScorecard*.jsp` | **NEW** | |
| Task boards | `DispatcherTaskBoard.jsp`, `FleetTaskBoard.jsp` | **NEW** | |
| Station / fleet dashboards | `StationDashboard.jsp`, `FleetInventoryDashboard.jsp` | **NEW** | |
| Reports | `Reports.jsp`, `MVPxReports.jsp` | DIFF surface | Extra MVPx reports. |
| Config | `MVPGConfig.jsp` | SAME idea | Do not commit `META-INF/context.xml`. |
| Generic SMS | `GenericSMS.jsp` | MVPx extras | Twilio from Admin Config/env only. |

---

## 3. How vehicles are assigned (MVPG = MVPx)

Triggered from **Associate Data / schedule Excel upload** (`EmployeeScheduleDAO`) and from **Run / Next Day Run** on check-in (`DACheckinDAO.updateRunRecords` / `updateNewRunRecords`).

### 3.1 Inputs

- Amazon day cell parsed by `getDayValueArray`: wave time, hours, **service tier string from the file**, mapped vehicle tier (default **`EXTRA_LARGE_CARGO_VAN`** if unmapped).
- Open pool: `VEHICLE.STATUS=0` AND `OPERATIONALSTATUS=0` AND not already on a check-in that day (`getAssignedVehicleIDs`).
- Last-week window: schedule date minus 1 through minus 7 calendar days.

### 3.2 Three passes (same loop in both apps)

`loopArray = serviceTierInLastWeek, serviceTierInOpenPool, checkInOpenPool`

1. **serviceTierInLastWeek** — `findEmployeeVehicleInCheckin`: walk this DA’s check-ins in the last week (newest first). If that **same VEHICLEID** is still in the open pool **and** the check-in service tier matches the **file** service tier, take it.
2. **serviceTierInOpenPool** — first van in the open pool whose **vehicle** service tier matches the mapped file tier.
3. **checkInOpenPool** — first remaining operational van (order = vehicle number).

A fourth empty-pass path (`getEmployeeVehicleID`) is used on check-in re-run: last-week same van if tier matches, else same-tier spare, else any van, else first-time DA gets the first pool van.

### 3.3 Why DAs rotate

- First-available, not “home van.”
- Last van is skipped if someone else already has it today.
- File tier must match or pass 1 fails even if the same van is free.
- Unmapped file cells force Extra Large, so Large vans are skipped.
- Shared vans (75 vans used by 3+ DAs in 90 days) guarantee contention.
- No AM/PM pair lock except by accident.

### 3.4 Recommended algorithm (home van + group)

Keep the service-tier and operational filters. Replace greedy first-available.

1. **Home van (required for “same driver, same van”).** Store `HOME_VEHICLEID` on EMPLOYEE (or a small `DA_VEHICLE_PREF` table with DA, vehicle, share_group, wave). If that van is operational and unassigned today, assign it. Do not give it to anyone else while this DA is scheduled.
2. **Share group.** Two DAs (or a small set) may share one van across waves. Assign the group van if the partner is off or on the other wave.
3. **Last 7 days (current pass 1)** as fallback when no home van is set.
4. **Same-tier spare** from vans that are **not** someone else’s home van.
5. **Dispatcher override** only to steal a home van (logged).

This is stable, auditable, and matches how high-stick DAs already behave (e.g. Alejandro on MVPG-11 at 97.7%).

---

## 4. Did the current logic work? (local data)

Definition of a **pair**: two consecutive work days for the same EMPLOYEEID with a vehicle on both days.

| Metric | Worked | Did not | Rate |
|---|---:|---:|---:|
| Same van as previous work day | 1,612 | 1,983 | **44.8%** |
| Same van when previous van was free and operational | 1,354 | 275 | **83.1%** |
| Same van as mode of prior 7 calendar days | 1,281 | 2,189 | **36.9%** |
| Last 14 days, same as previous work day | 45 | 101 | **30.8%** |

Population: **147** drivers, **3,742** employee-days, **3,595** pairs.

Drivers by stick rate: **10** at 80%+, **35** at 50–79%, **62** at 20–49%, **26** under 20%, **14** with only one day (no pair).

**Read this as:** pass 1 works when the van is still there (83%). It does **not** reserve the van, so most days the van is already taken and the DA is given the next Extra Large (45% overall; worse in the last two weeks).

Highest-volume examples:

- **Works:** Alejandro Carmona — 42/43 pairs on MVPG-11 (97.7%); Myles Sylman — 36/40 on MER-41-XL-CAM (90%); Jhabril Townes — 36/43 on CDV-MVPG-22 (83.7%).
- **Does not:** Tomasz Grochocki 9/43 (20.9%); Terrence Butler 9/42 (21.4%); Luis Canizares 12/43 (27.9%) — last van usually already assigned.

Full top-25 table is on the canvas `MVPG-vs-MVPx-report`.

---

## 5. Files / UAT (context, not this report’s zip)

Identity + confirmation revert classes already discussed: `AdminEmployeeDAO`, `DAStatusDAO`, `DACheckinDAO`, `DACheckoutDAO`, `EmployeeScheduleDAO`, `MVPGDAO`. SQL remap is local-only until reviewed. Do not commit `META-INF/context.xml` or Twilio secrets.
