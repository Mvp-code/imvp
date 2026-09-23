# MVPx pages — what we test

`S` = servlet `submitType=1` search. `J` = `/jsp/*.jsp` with session cookie.
`U` = Smart Upload. `M` = mutate (insert/update) — runner smokes the page; mutating
clicks are listed so a human or `--mutate` pass can finish them.

## Uploads (run first)

| # | What | File | Pass |
|---|---|---|---|
| U1 | Employee / AssociateData | `AssociateData (22).csv` | Result page, not “error uploading”; employee count for known transporters does not jump |
| U2 | DA Schedule | `Week-39-Schedule.xlsx` | Next Day Run; check-ins/schedule/confirmations for that day |
| U3 | Daily Itineraries | `Itineraries_DNK7_2026-09-22_00_42 (EDT).xlsx` | Loads; Wave Sheet / itinerary phone date usable |

Re-upload U1 once more: **update/revive**, not a second `EMPLOYEEID`.

## Operation

| Page | Route | Test |
|---|---|---|
| Incident | S `Incident` | List loads. M: New incident save, reopen, edit comments, logical delete |
| DA Checkins | S `DACheckin` | Rows after schedule. Names present. M: open one, Actual vehicle / phone, save. Delete check-in → confirmation closed |
| DA Confirmations | S `DAStatus` | One name per DA per day. M: set Confirmed / comments, Save checked |
| DA Checkouts | S `DACheckout` | List loads. M: checkout a posted check-in if one is ready |
| Dispatcher Tasks | J `DispatcherTaskBoard.jsp` | Board HTML, not login |
| Returns Board | S `ReturnsBoard` | Grid loads |
| Wave Sheet | S `WaveSheet` | Loads after itineraries; assignments visible if data exists |

## HR

| Page | Route | Test |
|---|---|---|
| DA Onboarding | J `DAOnboarding.jsp` | Page shell |
| Employees | S `AdminEmployee` | Grid after associate upload. M: open drawer, save phone (no twin), New revive if STATUS=1 |
| Forms | S `EmployeeForms` | List. M: open one form if present |
| Onboarding Dashboard | J `DAOnboardingDashboard.jsp` | Dashboard HTML |

## Fleet

| Page | Route | Test |
|---|---|---|
| Vehicles | S `AdminVehicle` | Operational vans listed (not blank 0 of 0). M: edit Tire Tread / odometer, save |
| Phones | S `AdminPhones` | List. M: in-use date = itinerary date if phones loaded |
| Gas Cards | S `AdminGasCard` | List. M: edit one card |
| Fleet Tasks | J `FleetTaskBoard.jsp` | Board HTML |
| Fleet Inventory | J `FleetInventoryDashboard.jsp` | Dashboard HTML |
| Vehicle Inspection | S `VehicleInspection` | List loads |

## Uploads / docs

| Page | Route | Test |
|---|---|---|
| Smart Upload | S `SmartUpload` | Drop zone. U1–U3 |
| Upload History | S `UploadHistory` | Recent U1–U3 filenames |
| AMZL Bridge | J `IngestDiscovery.jsp` | Page shell |
| Generic Upload | S `GenericUpload` | Page loads (Smart Upload is preferred) |
| Employee Uploads | S `CommonUpload` | Page loads |
| DA Standard Work | J `DAStandardWorkDocument.jsp` | Document page |
| Dispatcher Standard Work | J `DispatcherStandardWorkDocument.jsp` | Document page |

## Analytics / Emily / Admin / Other

| Page | Route | Test |
|---|---|---|
| MVPx Dashboard | S `StationDashboard` | Dashboard HTML |
| Predict Scorecard | J `PredictScorecard.jsp` | Page shell |
| MVPx-Reports | J `MVPxReports.jsp` | Page shell |
| Reports | S `Reports` | Page loads |
| Emily Console | J `EmilyConsole.jsp` | Console HTML (no live call) |
| Form Templates | S `AdminFormsTemplate` | Admin list |
| Users | S `EntityUsers` | `9082960064` present, one Active row |
| Configuration | S `AdminConfiguration` | Settings load |
| Types | S `AdminIncidentType` | List. M: do not delete production types |
| Category | S `AdminIncidentCategory` | List |
| Daily Status | J `DailyStatus.jsp` | Page shell |
| DA Tasks | S `DATask` | List |
| SMS | S `GenericSMS` | List only — **do not send** in the pack |
| OSHA Incidents | S `EmployeeIncident` | List. M: new OSHA row optional |
| Coaching Followup | S `EmployeeCoachingFollowup` | List |
| Employee Requests | S `EmployeeRequest` | List |
| Availability | S `EmployeeAvailability` | List after associate |
| Schedule | S `EmployeeSchedule` | Week-39 day populated |
| Termination | S `EmployeeTermination` | List. History still points at keep employee id |
| Portal Links | J `PortalResources.jsp` | Links page |
| Bridge Help | J `BridgeHelp.jsp` | Help page |
| Home | J `home.jsp` | Marketing/home (public) |
| Login | J `login.jsp` | Public; failed login stays here |

## Identity regressions (every environment after U1/U2)

1. No second Active employee for the same Amazon transporter id.
2. Confirmation list: one Active row per person per day.
3. Swap / employee dropdown: `IFNULL(REVIEW_STATUS,0)=0` so names appear.
4. Login `9082960064` still works after remap/uploads.
