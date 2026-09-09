# Fleet Inventory Import — Plan, Approach, Gaps

## Goal
1. Load `MVP_Fleet_Inventory_Report_3.xlsx` into MVPx (`fleetdb`)
2. Keep imports reversible (delete / restore scripts)
3. Later: new **Fleet Inventory Dashboard** (KPIs below)
4. Stay ready for more incoming files

## Best approach (recommended)
Do **not** hand-edit live rows or one-off SQL each time.

Use a **tagged batch import**:

```
Excel → import_fleet_inventory.py → backup tables + upsert VEHICLE by VIN
                                 → insert VEHICLE_MAINTENANCE_LOG (history)
                                 → fleet_import_batch / fleet_import_touch
```

Why this is best when more files are coming:
- **VIN is the match key** (stable across roster renames like `CDV-17` vs `CDV-MVPG-17`)
- Every run gets a `BATCH_TAG` so you can roll back one bad load without wiping the fleet
- Backups (`bkup_vehicle_<batch>`, `bkup_maint_log_<batch>`) let UPDATE rows be restored
- Same script can re-run next week’s workbook (history rows de-dupe inside a batch)

Later (phase 2): wire the same mapper into Smart Upload so ops can drop the file in the UI.

## What maps where

| Excel sheet | Target | Match |
|-------------|--------|--------|
| Current Issues (Full Inventory) | `vehicle` upsert | `VINNUMBER` |
| Vehicle History | `vehicle_maintenance_log` insert | Van → VIN via inventory sheet |

### Inventory → vehicle
| Excel | DB |
|-------|-----|
| Van | `VEHICLENUMBER` (keeps existing `CDV-MVPG-*` when Excel only has short name) |
| VIN | `VINNUMBER` |
| Plate | `LICENSEPLATE` |
| Type | `SERVICETIER` |
| Ownership | `OWNERSHIPTYPE` + `VEHICLETYPE` (Rental / Amazon-Owned) |
| Provider | `PROVIDER` |
| Year | `VEHICLEYEAR` |
| Status OPERATIONAL/GROUNDED/INACTIVE | `OPERATIONALSTATUS` 0/1 + `STATUS` 0/4 |
| Registration Expiry | `REGISTRATIONEXPIRY` |
| Grounding Category | `STATUSREASONCODE` |
| Issue / Reason | `STATUSREASONMSG` |
| Currently at Dealer | `OUT_FOR_REPAIR` |
| Last Oil Change + Next PM Due | oil `vehicle_maintenance_log` row |

### History → maintenance log
Activity text mapped to `MAINT_CODE` (`OIL_CHANGE`, `DEALER_REPAIR`, `TIRE_SERVICE`, `BRAKE_SERVICE`, `RECALL_SERVICE`, `TOW`, …). Source / outcome stored in `DESCRIPTION` + `SHOP_VENDOR`.

## How to run

```powershell
cd "C:\Program Files\Apache Software Foundation\Tomcat 9.0\webapps\MVPx\scripts\fleet_inventory"

# Preview only
python import_fleet_inventory.py --dry-run

# Real import
python import_fleet_inventory.py
# note the printed BATCH_TAG
```

Rollback if it looks wrong:

```powershell
mysql -uroot -padmin fleetdb -e "SET @batch:='PASTE_BATCH_TAG_HERE'; SOURCE C:/Program Files/Apache Software Foundation/Tomcat 9.0/webapps/MVPx/scripts/fleet_inventory/rollback_fleet_inventory.sql"
```

## Dashboard phase (after data looks good)

New page: **Fleet Inventory Dashboard** (not StationDashboard).

Suggested KPIs:
1. Total / Operational / Grounded / Inactive / Out-for-repair
2. Rental vs Amazon-owned counts + by provider
3. **Rentals not used but still on rent** — rentals with `OWNERSHIPTYPE=RENTAL` and no `dacheckin` in last N days (need date window)
4. Repairs open vs closed (from maintenance log `IS_OPEN`)
5. Repair volume by type / shop / month
6. PM overdue (`NEXT_SERVICE_DATE` < today)
7. Registration expiry next 30/60/90 days
8. Grounding reason breakdown
9. Cost rollup (when cost data arrives — currently mostly empty)
10. Top vans by repair events

## Gaps (known)

| Gap | Impact |
|-----|--------|
| No rental $ rate in Excel | Can’t compute “$ wasted on idle rentals” yet — only count of idle vans |
| Van names differ (`CDV-17` vs `CDV-MVPG-17`) | History relies on inventory Van→VIN map; orphans skipped |
| `(not in roster)` / unnamed vans | Inserted by VIN with weak vehicle numbers |
| `payload` / cubic capacity | Not in this report; still unused in DB |
| Tire data sparse | Excel itself notes only 2 real tire rotations |
| Existing Smart Upload expects Amazon `vehiclesdata` layout | This report needs this script (or a new upload adapter) |
| Manual Admin Vehicle form doesn’t save make/model/ownership block | UI edit path incomplete; import path updates those fields |
| Azure vs local DB | Import runs against **local** `fleetdb`; repeat on Azure MySQL for production |
| Idle-rental KPI needs checkin history | Join `dacheckin` × `vehicle`; define “unused” window (7/14/30 days) |

## Suggested sequence
1. Dry-run import → review counts  
2. Real import → spot-check Vehicles + a few maintenance drawers  
3. If bad → run rollback with `BATCH_TAG`  
4. If good → build Fleet Inventory Dashboard on this data  
5. When next Excel arrives → re-run importer (new batch tag)
