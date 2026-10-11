"""Build phones_end_sept_2026.sql from the carrier workbook.

Match on digits-only phone number.
  UPDATE rows already in phones (any STATUS) and reactivate them.
  INSERT numbers that are not in phones at all.
  Soft-delete (STATUS=1) live rows whose number is not in the workbook.
CURRENTSTATUS is left alone on update. New rows start as Not Used.
SERIALNUMBER stores Device In Use IMEI 1 (the Phones screen label is IMEI 1).
"""
from __future__ import annotations

from datetime import date, datetime
from pathlib import Path

from openpyxl import load_workbook

SRC = Path(r"c:\Users\mvplo\Downloads\MVP end Sept 2026 (2).xlsx")
OUT = Path(__file__).with_name("phones_end_sept_2026.sql")


def digits(v):
    if v is None:
        return ""
    if isinstance(v, float):
        v = str(int(v))
    return "".join(c for c in str(v) if c.isdigit())


def fmt_phone(v):
    d = digits(v)
    if len(d) == 11 and d.startswith("1"):
        d = d[1:]
    if len(d) == 10:
        return "%s-%s-%s" % (d[:3], d[3:6], d[6:])
    return d


def phone_key(v):
    d = digits(v)
    if len(d) == 11 and d.startswith("1"):
        d = d[1:]
    return d


def sql_str(v, limit=None):
    if v is None:
        return "NULL"
    if isinstance(v, float) and v == int(v):
        s = str(int(v))
    else:
        s = str(v).strip()
    if s == "" or s.lower() == "none":
        return "NULL"
    if limit:
        s = s[:limit]
    return "'" + s.replace("\\", "\\\\").replace("'", "''") + "'"


def sql_dt(v):
    if v is None:
        return "NULL"
    if isinstance(v, datetime):
        return "'" + v.strftime("%Y-%m-%d %H:%M:%S") + "'"
    if isinstance(v, date):
        return "'" + v.strftime("%Y-%m-%d") + " 00:00:00'"
    s = str(v).strip()
    if not s:
        return "NULL"
    for fmt in ("%Y-%m-%d %H:%M:%S", "%Y-%m-%d", "%m/%d/%Y"):
        try:
            return "'" + datetime.strptime(s[:19], fmt).strftime("%Y-%m-%d %H:%M:%S") + "'"
        except Exception:
            pass
    return "NULL"


def phone_status(code):
    st = str(code or "").strip().lower()
    if st in ("a", "active"):
        return "Active"
    if st in ("susp", "suspend", "suspended", "s"):
        return "Suspended"
    return "Active"


def load_sheet():
    wb = load_workbook(SRC, data_only=True)
    ws = wb.active
    rows = list(ws.iter_rows(values_only=True))
    hdr = [str(c).strip() if c else "" for c in rows[0]]
    data = []
    seen = set()
    for r in rows[1:]:
        if not any(c is not None and str(c).strip() for c in r):
            continue
        d = dict(zip(hdr, r))
        key = phone_key(d.get("Phone Number"))
        if not key or key in seen:
            continue
        seen.add(key)
        d["_key"] = key
        d["_fmt"] = fmt_phone(d.get("Phone Number"))
        data.append(d)
    return data


def main():
    data = load_sheet()
    sheet_keys = [d["_key"] for d in data]
    in_list = ",".join("'%s'" % k for k in sheet_keys)

    lines = [
        "-- Phones sync from MVP end Sept 2026 (2).xlsx",
        "-- Workbook rows: %d (Sts Cd A = Active, Susp = Suspended)." % len(data),
        "-- Match is digits-only phone number. Safe to re-run.",
        "-- UPDATE refreshes carrier fields and sets STATUS=0. CURRENTSTATUS is not changed.",
        "-- INSERT adds numbers that are not in phones. New CURRENTSTATUS is Not Used.",
        "-- DELETE is the app soft-delete (STATUS=1), not a physical DELETE.",
        "-- SERIALNUMBER is Device In Use IMEI 1. Device SN is stored in REMARKS only on insert.",
        "-- Local fleetdb preview (rolled back): update 81, insert 28, soft-delete 138.",
        "-- After commit, live phones should be 86 Active and 23 Suspended.",
    ]
    lines.extend([
        "-- Review the counts, then change ROLLBACK to COMMIT.",
        "",
        "USE fleetdb;",
        "",
        "SET SQL_SAFE_UPDATES = 0;",
        "START TRANSACTION;",
        "",
        "DROP TEMPORARY TABLE IF EXISTS tmp_phone_sept2026;",
        "CREATE TEMPORARY TABLE tmp_phone_sept2026 (",
        "  PHONEKEY varchar(20) NOT NULL PRIMARY KEY,",
        "  PHONENUMBER varchar(20) NOT NULL,",
        "  PHONESTATUS varchar(80) NOT NULL,",
        "  SERIALNUMBER varchar(32) DEFAULT NULL,",
        "  DEVICEMAKE varchar(50) DEFAULT NULL,",
        "  DEVICEMODEL varchar(80) DEFAULT NULL,",
        "  IMEI2 varchar(20) DEFAULT NULL,",
        "  IMSI varchar(20) DEFAULT NULL,",
        "  ICCID varchar(32) DEFAULT NULL,",
        "  EID varchar(40) DEFAULT NULL,",
        "  SN varchar(40) DEFAULT NULL,",
        "  CONTRACTENDDATE datetime DEFAULT NULL,",
        "  CONTRACTSTARTDATE datetime DEFAULT NULL,",
        "  DEVICEORDEREDDATE datetime DEFAULT NULL,",
        "  DEVICEORDEREDIMEI varchar(20) DEFAULT NULL,",
        "  DEVICEINUSEDATE datetime DEFAULT NULL",
        ") ENGINE=MEMORY;",
        "",
    ])

    # Chunk inserts so the file stays reviewable.
    chunk = []
    def flush():
        if not chunk:
            return
        lines.append(
            "INSERT INTO tmp_phone_sept2026 (PHONEKEY, PHONENUMBER, PHONESTATUS, SERIALNUMBER, "
            "DEVICEMAKE, DEVICEMODEL, IMEI2, IMSI, ICCID, EID, SN, "
            "CONTRACTENDDATE, CONTRACTSTARTDATE, DEVICEORDEREDDATE, DEVICEORDEREDIMEI, DEVICEINUSEDATE) VALUES"
        )
        lines.append(",\n".join(chunk) + ";")
        lines.append("")
        chunk.clear()

    for d in data:
        sn = sql_str(d.get("Device In Use SN"), 40)
        vals = "(%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)" % (
            sql_str(d["_key"]),
            sql_str(d["_fmt"]),
            sql_str(phone_status(d.get("Sts Cd"))),
            sql_str(d.get("Device In Use IMEI 1"), 32),
            sql_str(d.get("Device In Use Make"), 50),
            sql_str(d.get("Device In Use Model"), 80),
            sql_str(d.get("Device In Use IMEI 2"), 20),
            sql_str(d.get("Device In Use IMSI"), 20),
            sql_str(d.get("Device In Use ICCID"), 32),
            sql_str(d.get("Device In Use EID"), 40),
            sn,
            sql_dt(d.get("Contract End Date")),
            sql_dt(d.get("Contract Start Date")),
            sql_dt(d.get("Device Ordered Date")),
            sql_str(d.get("Device Ordered IMEI"), 20),
            sql_dt(d.get("Device In Use Date")),
        )
        chunk.append(vals)
        if len(chunk) >= 40:
            flush()
    flush()

    norm = "REPLACE(REPLACE(REPLACE(IFNULL(p.PHONENUMBER,''),'-',''),' ',''),'+','')"
    lines.extend([
        "-- Existing numbers: refresh carrier fields. Keep CURRENTSTATUS (In Use / Not Used / Damaged / Lost).",
        "UPDATE phones p",
        "JOIN tmp_phone_sept2026 t",
        "  ON %s = t.PHONEKEY" % norm.replace("p.", "p."),
        "SET p.PHONENUMBER = t.PHONENUMBER,",
        "    p.PHONESTATUS = t.PHONESTATUS,",
        "    p.SERIALNUMBER = t.SERIALNUMBER,",
        "    p.DEVICEMAKE = t.DEVICEMAKE,",
        "    p.DEVICEMODEL = t.DEVICEMODEL,",
        "    p.IMEI2 = t.IMEI2,",
        "    p.IMSI = t.IMSI,",
        "    p.ICCID = t.ICCID,",
        "    p.EID = t.EID,",
        "    p.CONTRACTENDDATE = t.CONTRACTENDDATE,",
        "    p.CONTRACTSTARTDATE = t.CONTRACTSTARTDATE,",
        "    p.DEVICEORDEREDDATE = t.DEVICEORDEREDDATE,",
        "    p.DEVICEORDEREDIMEI = t.DEVICEORDEREDIMEI,",
        "    p.DEVICEINUSEDATE = t.DEVICEINUSEDATE,",
        "    p.STATUS = 0,",
        "    p.UPDATE_USER = 'phone-sept-2026',",
        "    p.UPDATE_DATE = NOW();",
        "",
        "-- Numbers in the workbook that are not in phones yet.",
        "INSERT INTO phones (ENTITYID, PHONENUMBER, PHONESTATUS, CURRENTSTATUS, SERIALNUMBER,",
        "  DEVICEMAKE, DEVICEMODEL, IMEI2, IMSI, ICCID, EID, REMARKS,",
        "  CONTRACTENDDATE, CONTRACTSTARTDATE, DEVICEORDEREDDATE, DEVICEORDEREDIMEI,",
        "  DEVICEINUSEDATE, CREATE_USER, CREATE_DATE, STATUS)",
        "SELECT 1, t.PHONENUMBER, t.PHONESTATUS, 'Not Used', t.SERIALNUMBER,",
        "  t.DEVICEMAKE, t.DEVICEMODEL, t.IMEI2, t.IMSI, t.ICCID, t.EID,",
        "  CASE WHEN t.SN IS NULL OR t.SN = '' THEN NULL ELSE CONCAT('SN: ', t.SN) END,",
        "  t.CONTRACTENDDATE, t.CONTRACTSTARTDATE, t.DEVICEORDEREDDATE, t.DEVICEORDEREDIMEI,",
        "  t.DEVICEINUSEDATE, 'phone-sept-2026', NOW(), 0",
        "FROM tmp_phone_sept2026 t",
        "WHERE NOT EXISTS (",
        "  SELECT 1 FROM phones p",
        "  WHERE REPLACE(REPLACE(REPLACE(IFNULL(p.PHONENUMBER,''),'-',''),' ',''),'+','') = t.PHONEKEY",
        ");",
        "",
        "-- Live phones that are not in the end-of-September workbook.",
        "UPDATE phones p",
        "SET p.STATUS = 1,",
        "    p.UPDATE_USER = 'phone-sept-2026',",
        "    p.UPDATE_DATE = NOW()",
        "WHERE p.STATUS != 1",
        "  AND REPLACE(REPLACE(REPLACE(IFNULL(p.PHONENUMBER,''),'-',''),' ',''),'+','') NOT IN (%s);" % in_list,
        "",
        "SELECT 'updated_or_kept' AS what, COUNT(*) n FROM phones p",
        "JOIN tmp_phone_sept2026 t",
        "  ON REPLACE(REPLACE(REPLACE(IFNULL(p.PHONENUMBER,''),'-',''),' ',''),'+','') = t.PHONEKEY",
        "WHERE p.STATUS = 0;",
        "SELECT 'soft_deleted' AS what, COUNT(*) n FROM phones",
        "WHERE STATUS = 1 AND UPDATE_USER = 'phone-sept-2026' AND UPDATE_DATE >= NOW() - INTERVAL 1 HOUR;",
        "SELECT PHONESTATUS, COUNT(*) n FROM phones WHERE STATUS = 0 GROUP BY PHONESTATUS;",
        "",
        "SET SQL_SAFE_UPDATES = 1;",
        "ROLLBACK;",
        "-- COMMIT;",
        "",
    ])
    OUT.write_text("\n".join(lines), encoding="utf-8")
    print("wrote %s rows=%d bytes=%d" % (OUT, len(data), OUT.stat().st_size))


if __name__ == "__main__":
    main()
