package com.dataobjects;

import java.util.List;

import com.beans.UserPreference;
import com.util.RecordStatus;

/**
 * UserPreferenceDAO - load/save per-user UI preferences against USER_PREFERENCES.
 * Keeps the existing DAO style: uses the shared {@code db} (MVPGDB) helper and
 * plain query strings. Values are whitelisted/normalized before they touch SQL.
 *
 * USERID = ENTITYUSERSID (the login user). EMPLOYEEID / TRANSPORTERID / STATION
 * are resolved from ENTITYUSERS -> EMPLOYEE so prefs can be reported by employee
 * / transporter / station.
 */
public class UserPreferenceDAO extends MVPGDAO {

	private static final String TABLE = "USER_PREFERENCES";

	/** Load preferences for a user. Always returns a non-null bean (defaults if no row). */
	public UserPreference load(String userID, String entityID) throws Exception {

		UserPreference pref = new UserPreference();
		pref.setUserID(userID == null ? "" : userID.trim());
		pref.setEntityID(normEntity(entityID));

		if (pref.getUserID().length() == 0)
			return pref;

		String selQry = "SELECT THEME, LANG, FONT_SCALE, A11Y_LARGE, A11Y_CONTRAST, A11Y_MOTION, "
				+ "STATION, EMPLOYEEID, TRANSPORTERID "
				+ "FROM " + TABLE + " WHERE USERID='" + esc(pref.getUserID())
				+ "' AND ENTITYID=" + pref.getEntityID()
				+ " AND STATUS=" + RecordStatus.ACTIVE;

		List resultList = db.selectAsList(selQry, 9);
		if (resultList != null && resultList.size() > 0) {
			List row = (List) resultList.get(0);
			pref.setTheme(def((String) row.get(0), "blue"));
			pref.setLang(def((String) row.get(1), "en"));
			pref.setFontScale(def((String) row.get(2), "1"));
			pref.setA11yLarge(bit((String) row.get(3)));
			pref.setA11yContrast(bit((String) row.get(4)));
			pref.setA11yMotion(bit((String) row.get(5)));
			pref.setStation(def((String) row.get(6), ""));
			pref.setEmployeeID(def((String) row.get(7), ""));
			pref.setTransporterID(def((String) row.get(8), ""));
		} else {
			// No saved prefs yet: seed sensible defaults from the employee record
			// (e.g. honor EMPLOYEE.PREFERRED_LANGUAGE for first-time language).
			String[] emp = resolveEmployee(pref.getUserID());
			pref.setEmployeeID(emp[0]);
			pref.setTransporterID(emp[1]);
			pref.setStation(emp[2]);
			pref.setLang(langFromEmployee(emp[3]));
		}
		return pref;
	}

	/** Insert or update a user's preferences. Returns true on success. */
	public boolean save(UserPreference pref, String loginUser) throws Exception {

		if (pref == null || pref.getUserID() == null || pref.getUserID().trim().length() == 0)
			return false;

		String userID   = esc(pref.getUserID().trim());
		int    entityID = entityId(pref.getEntityID());
		String theme    = esc(theme(pref.getTheme()));
		String lang     = esc(lang(pref.getLang()));
		String fScale   = esc(def(pref.getFontScale(), "1"));
		String aLarge   = bit(pref.getA11yLarge());
		String aContr   = bit(pref.getA11yContrast());
		String aMotion  = bit(pref.getA11yMotion());
		String byUser   = esc(loginUser == null ? pref.getUserID() : loginUser);

		// Resolve employee / transporter / station from the login user (ENTITYUSERSID).
		// An explicitly passed station wins; otherwise fall back to the employee's station.
		String[] emp         = resolveEmployee(pref.getUserID().trim());
		String employeeID    = emp[0];                          // numeric or ""
		String transporterID = emp[1];                          // raw, may be ""
		String station       = def(pref.getStation(), emp[2]);  // param, else employee station

		// Does a row already exist?
		String existsQry = "SELECT USERPREFERENCEID FROM " + TABLE
				+ " WHERE USERID='" + userID + "' AND ENTITYID=" + entityID;
		List existing = db.selectAsList(existsQry, 1);

		String qry;
		if (existing != null && existing.size() > 0) {
			// COALESCE keeps any existing value when a fresh one isn't available.
			qry = "UPDATE " + TABLE + " SET "
					+ "THEME='" + theme + "', "
					+ "LANG='" + lang + "', "
					+ "FONT_SCALE='" + fScale + "', "
					+ "A11Y_LARGE=" + aLarge + ", "
					+ "A11Y_CONTRAST=" + aContr + ", "
					+ "A11Y_MOTION=" + aMotion + ", "
					+ "STATION=COALESCE(" + sqlStr(station) + ", STATION), "
					+ "EMPLOYEEID=COALESCE(" + sqlInt(employeeID) + ", EMPLOYEEID), "
					+ "TRANSPORTERID=COALESCE(" + sqlStr(transporterID) + ", TRANSPORTERID), "
					+ "STATUS=" + RecordStatus.ACTIVE + ", "
					+ "UPDATE_USER='" + byUser + "', "
					+ "UPDATE_DATE=NOW() "
					+ "WHERE USERID='" + userID + "' AND ENTITYID=" + entityID;
			return db.update(qry);
		} else {
			// PK from the shared sequence (seq table) like every other table.
			String newID = db.getNextIDValue("USERPREFERENCEID");
			qry = "INSERT INTO " + TABLE
					+ " (USERPREFERENCEID, USERID, ENTITYID, STATION, EMPLOYEEID, TRANSPORTERID, "
					+ "THEME, LANG, FONT_SCALE, A11Y_LARGE, "
					+ "A11Y_CONTRAST, A11Y_MOTION, CREATE_USER, CREATE_DATE, STATUS) VALUES ("
					+ newID + ", '" + userID + "', " + entityID + ", "
					+ sqlStr(station) + ", " + sqlInt(employeeID) + ", " + sqlStr(transporterID) + ", '"
					+ theme + "', '" + lang + "', '"
					+ fScale + "', " + aLarge + ", " + aContr + ", " + aMotion + ", '"
					+ byUser + "', NOW(), " + RecordStatus.ACTIVE + ")";
			// NOTE: db.create() has inverted commit logic (rolls back successful
			// inserts), so use db.update() which commits correctly for executeUpdate.
			return db.update(qry);
		}
	}

	// ---- helpers ---------------------------------------------------------

	/**
	 * Resolve { EMPLOYEEID, TRANSPORTERID, STATION, PREFERRED_LANGUAGE } for a
	 * login user (ENTITYUSERSID). Best-effort; returns blanks on any failure.
	 */
	private String[] resolveEmployee(String userID) {
		String[] out = new String[] { "", "", "", "" };
		try {
			if (userID == null) return out;
			userID = userID.trim();
			if (userID.length() == 0 || !userID.matches("\\d+")) return out;
			String q = "SELECT A.EMPLOYEEID, A.TRANSPORTERID, A.STATION, A.PREFERRED_LANGUAGE "
					+ "FROM ENTITYUSERS B LEFT JOIN EMPLOYEE A ON A.EMPLOYEEID=B.EMPLOYEEID "
					+ "WHERE B.ENTITYUSERSID=" + userID;
			List rs = db.selectAsList(q, 4);
			if (rs != null && rs.size() > 0) {
				List row = (List) rs.get(0);
				out[0] = blank(row.get(0));
				out[1] = blank(row.get(1));
				out[2] = blank(row.get(2));
				out[3] = blank(row.get(3));
			}
		} catch (Exception e) { /* best-effort; leave blanks */ }
		return out;
	}

	/** Map EMPLOYEE.PREFERRED_LANGUAGE to a supported UI language (en/es). */
	private String langFromEmployee(String pl) {
		if (pl == null) return "en";
		pl = pl.trim().toLowerCase();
		if (pl.startsWith("es") || pl.contains("span") || pl.contains("espa")) return "es";
		return "en";
	}

	/** SQL literal for an int column: the number, or NULL if blank/non-numeric. */
	private String sqlInt(String v) {
		v = (v == null) ? "" : v.trim();
		return v.matches("\\d+") ? v : "NULL";
	}

	/** SQL literal for a string column: quoted+escaped, or NULL if blank. */
	private String sqlStr(String v) {
		return (v == null || v.trim().length() == 0) ? "NULL" : "'" + esc(v.trim()) + "'";
	}

	private String blank(Object o) {
		return o == null ? "" : o.toString().trim();
	}

	private String esc(String v) {
		return v == null ? "" : v.replaceAll("'", "''");
	}

	private String def(String v, String fallback) {
		return (v == null || v.trim().length() == 0) ? fallback : v.trim();
	}

	/** Normalize any truthy value to "1" / "0". */
	private String bit(String v) {
		if (v == null) return "0";
		v = v.trim();
		return ("1".equals(v) || "true".equalsIgnoreCase(v) || "on".equalsIgnoreCase(v)) ? "1" : "0";
	}

	private String normEntity(String entityID) {
		return String.valueOf(entityId(entityID));
	}

	/** Entity id, defaulting to 1 when blank/invalid. */
	private int entityId(String v) {
		int e = parseInt(v);
		return e <= 0 ? 1 : e;
	}

	private int parseInt(String v) {
		try { return Integer.parseInt(v == null ? "0" : v.trim()); }
		catch (Exception e) { return 0; }
	}

	/** Whitelist theme ids; unknown values fall back to blue. */
	private String theme(String t) {
		t = def(t, "blue");
		if ("blue".equals(t) || "green".equals(t) || "purple".equals(t)
				|| "slate".equals(t) || "orange".equals(t)) return t;
		return "blue";
	}

	/** Whitelist language; only en/es supported today. */
	private String lang(String l) {
		l = def(l, "en");
		return "es".equals(l) ? "es" : "en";
	}
}
