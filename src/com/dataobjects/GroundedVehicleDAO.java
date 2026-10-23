package com.dataobjects;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import com.beans.GroundedVehicle;
import com.beans.SearchBean;
import com.util.RecordStatus;

/**
 * Grounded Vehicles work queue — follow vans that are down until they
 * return to service. Location is independent of operational status
 * (Dealer / Sammy / DNK7 / Other).
 */
public class GroundedVehicleDAO extends MVPGDAO {

	GroundedVehicle bean = new GroundedVehicle();

	public static final String[] LOCATIONS = { "DNK7", "Dealer", "Sammy", "Other" };
	public static final String[] REASONS = {
			"Accident", "DVIC fail", "Brakes", "Engine/mechanical",
			"Tires", "Body/glass", "Recall", "Electrical", "Other"
	};

	void ensureSchema() {
		String[][] cols = {
			{ "GROUND_LOCATION", "VARCHAR(40) NULL" },
			{ "GROUNDED_DATE", "DATE NULL" },
			{ "GROUND_REASON", "VARCHAR(120) NULL" },
			{ "GROUND_FOLLOWUP_DATE", "DATE NULL" },
			{ "GROUND_FOLLOWUP_NOTE", "VARCHAR(500) NULL" }
		};
		for (String[] col : cols) {
			try {
				List c = db.selectAsList(
						"SELECT 1 FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() "
								+ "AND TABLE_NAME='vehicle' AND COLUMN_NAME='"
								+ col[0] + "'", 1);
				if (c == null || c.isEmpty())
					db.create("ALTER TABLE vehicle ADD COLUMN " + col[0] + " " + col[1]);
			} catch (Exception ignore) { }
		}
		try {
			List t = db.selectAsList(
					"SELECT 1 FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() "
							+ "AND TABLE_NAME='vehicle_ground_event'", 1);
			if (t == null || t.isEmpty())
				db.create("CREATE TABLE vehicle_ground_event ("
						+ "VEHICLEGROUNDEVENTID INT NOT NULL PRIMARY KEY, "
						+ "VEHICLEID INT NOT NULL, ENTITYID INT NOT NULL, "
						+ "EVENT_TYPE VARCHAR(20) NOT NULL, "
						+ "LOCATION VARCHAR(40) NULL, REASON VARCHAR(120) NULL, "
						+ "NOTES VARCHAR(500) NULL, DAYS_DOWN INT NULL, "
						+ "CREATE_USER VARCHAR(80) NULL, CREATE_DATE DATETIME NULL, "
						+ "STATUS INT DEFAULT 0)");
		} catch (Exception ignore) { }
		try {
			List mx = db.selectAsList(
					"SELECT IFNULL(MAX(VEHICLEGROUNDEVENTID),0) FROM vehicle_ground_event", 1);
			String max = "0";
			if (mx != null && !mx.isEmpty())
				max = getListData((List) mx.get(0), 0);
			if (max == null || max.length() == 0)
				max = "0";
			db.create("INSERT INTO seq (name, val) VALUES ('VEHICLEGROUNDEVENTID', "
					+ max + ") ON DUPLICATE KEY UPDATE val = GREATEST(val, " + max + ")");
		} catch (Exception ignore) { }
		try {
			db.create("UPDATE vehicle SET GROUNDED_DATE=DATE(IFNULL(UPDATE_DATE,CREATE_DATE)) "
					+ "WHERE OPERATIONALSTATUS=1 AND GROUNDED_DATE IS NULL "
					+ "AND STATUS!=" + RecordStatus.DELETE);
			db.create("UPDATE vehicle SET GROUND_LOCATION='DNK7' "
					+ "WHERE OPERATIONALSTATUS=1 AND IFNULL(GROUND_LOCATION,'')='' "
					+ "AND STATUS!=" + RecordStatus.DELETE);
			db.create("UPDATE vehicle SET GROUND_LOCATION='Dealer' "
					+ "WHERE OPERATIONALSTATUS=4 AND IFNULL(GROUND_LOCATION,'')='' "
					+ "AND STATUS!=" + RecordStatus.DELETE);
			db.create("UPDATE vehicle SET GROUND_LOCATION='Sammy' "
					+ "WHERE OPERATIONALSTATUS=5 AND IFNULL(GROUND_LOCATION,'')='' "
					+ "AND STATUS!=" + RecordStatus.DELETE);
			db.create("UPDATE vehicle SET GROUNDED_DATE=DATE(IFNULL(UPDATE_DATE,CREATE_DATE)) "
					+ "WHERE OPERATIONALSTATUS IN (4,5) AND GROUNDED_DATE IS NULL "
					+ "AND STATUS!=" + RecordStatus.DELETE);
		} catch (Exception ignore) { }
	}

	@Override
	public SearchBean searchRecords(SearchBean searchBean, String recordID,
			String loginUser, String loginUserRoles, String loginUserID,
			String entityID) throws Exception {

		ensureSchema();

		searchBean.setDisplayName("Grounded Vehicles");
		searchBean.setController(bean.getController());
		List<String> labels = new ArrayList<String>();
		labels.add("Vehicle");
		labels.add("Reason");
		labels.add("Grounded date");
		labels.add("Days grounded");
		labels.add("Location");
		labels.add("Follow-up");
		searchBean.setLabelsList(labels);
		searchBean.setWidthColumns(new int[] { 12, 18, 12, 10, 12, 18 });

		String downCond = " AND (OPERATIONALSTATUS=1 OR OPERATIONALSTATUS=4 OR OPERATIONALSTATUS=5)";
		String selQry = "SELECT VEHICLEID, VEHICLENUMBER, IFNULL(VINNUMBER,''), "
				+ "IFNULL(GROUND_REASON,''), " + db.getSelectDate("GROUNDED_DATE")
				+ ", IFNULL(DATEDIFF(CURDATE(), GROUNDED_DATE),0), "
				+ "IFNULL(GROUND_LOCATION,''), "
				+ db.getSelectDate("GROUND_FOLLOWUP_DATE") + ", "
				+ "IFNULL(GROUND_FOLLOWUP_NOTE,''), "
				+ "IFNULL(OPERATIONALSTATUS,1), IFNULL(PROVIDER,'') "
				+ "FROM VEHICLE WHERE STATUS!=" + RecordStatus.DELETE
				+ " AND ENTITYID=" + entityID + downCond
				+ " ORDER BY IFNULL(DATEDIFF(CURDATE(), GROUNDED_DATE),0) DESC, VEHICLENUMBER";

		List resultList = db.selectAsList(selQry, 11);
		searchBean.setDataList(resultList == null ? new ArrayList() : resultList);

		List hist = db.selectAsList(
				"SELECT E.VEHICLEGROUNDEVENTID, IFNULL(V.VEHICLENUMBER,''), IFNULL(V.VINNUMBER,''), "
						+ "IFNULL(E.REASON,''), " + db.getSelectDate("E.CREATE_DATE")
						+ ", IFNULL(E.DAYS_DOWN,0), IFNULL(E.LOCATION,''), "
						+ "IFNULL(E.NOTES,''), IFNULL(E.CREATE_USER,''), E.VEHICLEID "
						+ "FROM vehicle_ground_event E "
						+ "JOIN VEHICLE V ON V.VEHICLEID=E.VEHICLEID "
						+ "WHERE E.EVENT_TYPE='UNGROUND' AND E.STATUS!=" + RecordStatus.DELETE
						+ " AND E.ENTITYID=" + entityID
						+ " ORDER BY E.VEHICLEGROUNDEVENTID DESC LIMIT 200", 10);

		Map transMap = searchBean.getTransMap() == null ? new HashMap()
				: searchBean.getTransMap();
		transMap.put("historyList", hist == null ? new ArrayList() : hist);
		List ops = db.selectAsList(
				"SELECT VEHICLEID, IFNULL(VEHICLENUMBER,''), IFNULL(VINNUMBER,'') "
						+ "FROM VEHICLE WHERE STATUS!=" + RecordStatus.DELETE
						+ " AND ENTITYID=" + entityID
						+ " AND IFNULL(OPERATIONALSTATUS,0) NOT IN (1,4,5) "
						+ "ORDER BY VEHICLENUMBER", 3);
		transMap.put("operationalList", ops == null ? new ArrayList() : ops);
		searchBean.setTransMap(transMap);
		return searchBean;
	}

	/** Called when Vehicles / maintenance marks a van Grounded. */
	public void onGrounded(String vehicleId, String entityID, String reason,
			String loginUser) {
		if (vehicleId == null || !vehicleId.matches("\\d+"))
			return;
		ensureSchema();
		try {
			String loc = getTableColumnData("GROUND_LOCATION", "VEHICLE", "VEHICLEID", vehicleId);
			if (loc == null || loc.trim().length() == 0)
				loc = "DNK7";
			String rsn = reason == null ? "" : reason.trim();
			if (rsn.length() > 120)
				rsn = rsn.substring(0, 120);
			List<String> up = new ArrayList<String>();
			up.add("UPDATE VEHICLE SET "
					+ "GROUNDED_DATE=IFNULL(GROUNDED_DATE, CURDATE()), "
					+ "GROUND_LOCATION=CASE WHEN IFNULL(GROUND_LOCATION,'')='' THEN "
					+ db.getInsertDBValue(loc) + " ELSE GROUND_LOCATION END"
					+ (rsn.length() > 0
							? ", GROUND_REASON=" + db.getInsertDBValue(rsn) : "")
					+ ", UPDATE_USER=" + db.getInsertDBValue(loginUser)
					+ ", UPDATE_DATE=" + db.getInsertSysdate()
					+ " WHERE VEHICLEID=" + vehicleId + " AND ENTITYID=" + entityID
					+ " AND STATUS!=" + RecordStatus.DELETE);
			addEvent(up, vehicleId, entityID, "GROUND", loc, rsn, "", null, loginUser);
			db.batchInsert(up);
		} catch (Exception ignore) { }
	}

	/** Called when Vehicles / maintenance marks a van Operational. */
	public void onUngrounded(String vehicleId, String entityID, String notes,
			String loginUser) {
		if (vehicleId == null || !vehicleId.matches("\\d+"))
			return;
		ensureSchema();
		try {
			ungroundInternal(vehicleId, entityID, "DNK7", notes, loginUser);
		} catch (Exception ignore) { }
	}

	@Override
	public String getAjaxRequestTypeResp(String requestType,
			Map<String, String> requestMap, String loginUser,
			String loginUserRoles, String loginUserID, String entityID)
			throws Exception {

		ensureSchema();
		String recordID = rq(requestMap, "recordID");

		if ("searchVans".equalsIgnoreCase(requestType))
			return searchVans(entityID, rq(requestMap, "q"));

		if (!recordID.matches("\\d+"))
			return xml(false, "Bad request");

		if ("saveFollowup".equalsIgnoreCase(requestType))
			return saveFollowup(recordID, entityID, requestMap, loginUser);
		if ("unground".equalsIgnoreCase(requestType))
			return doUnground(recordID, entityID, requestMap, loginUser);
		if ("timeline".equalsIgnoreCase(requestType))
			return timeline(recordID, entityID);
		if ("ground".equalsIgnoreCase(requestType))
			return doGround(recordID, entityID, requestMap, loginUser);
		return "";
	}

	private String searchVans(String entityID, String q) throws Exception {
		String like = q == null ? "" : q.replace("'", "").replace("%", "").trim();
		String extra = "";
		if (like.length() > 0)
			extra = " AND (VEHICLENUMBER LIKE " + db.getInsertDBValue("%" + like + "%")
					+ " OR VINNUMBER LIKE " + db.getInsertDBValue("%" + like + "%") + ")";
		List r = db.selectAsList(
				"SELECT VEHICLEID, IFNULL(VEHICLENUMBER,''), IFNULL(VINNUMBER,'') "
						+ "FROM VEHICLE WHERE STATUS!=" + RecordStatus.DELETE
						+ " AND ENTITYID=" + entityID
						+ " AND IFNULL(OPERATIONALSTATUS,0) NOT IN (1,4,5) "
						+ extra + " ORDER BY VEHICLENUMBER LIMIT 40", 3);
		if (r == null)
			r = new ArrayList();
		StringBuilder b = new StringBuilder("{\"vans\":[");
		for (int i = 0; i < r.size(); i++) {
			List row = (List) r.get(i);
			if (i > 0)
				b.append(',');
			b.append("{\"id\":").append(js(getListData(row, 0)))
					.append(",\"num\":").append(js(getListData(row, 1)))
					.append(",\"vin\":").append(js(getListData(row, 2)))
					.append("}");
		}
		b.append("]}");
		return "<status>true</status><json>" + b.toString().replace("<", "\\u003C") + "</json>";
	}

	private String doGround(String vehicleId, String entityID,
			Map<String, String> requestMap, String loginUser) throws Exception {
		String loc = normLocation(rq(requestMap, "location"));
		String reason = rq(requestMap, "reason");
		if (reason.length() == 0)
			return xml(false, "Choose a reason");
		if (reason.length() > 120)
			reason = reason.substring(0, 120);
		String note = rq(requestMap, "note");
		if (note.length() > 500)
			note = note.substring(0, 500);

		List chk = db.selectAsList(
				"SELECT IFNULL(OPERATIONALSTATUS,0), IFNULL(VEHICLENUMBER,'') "
						+ "FROM VEHICLE WHERE VEHICLEID=" + vehicleId
						+ " AND ENTITYID=" + entityID
						+ " AND STATUS!=" + RecordStatus.DELETE, 2);
		if (chk == null || chk.isEmpty())
			return xml(false, "Vehicle not found");
		List row = (List) chk.get(0);
		String op = getListData(row, 0);
		if ("1".equals(op) || "4".equals(op) || "5".equals(op))
			return xml(false, "That van is already grounded");

		List<String> up = new ArrayList<String>();
		up.add("UPDATE VEHICLE SET OPERATIONALSTATUS=1, GROUNDED_DATE=CURDATE(), "
				+ "GROUND_LOCATION=" + db.getInsertDBValue(loc)
				+ ", GROUND_REASON=" + db.getInsertDBValue(reason)
				+ ", GROUND_FOLLOWUP_NOTE=" + db.getInsertDBValue(note)
				+ ", GROUND_FOLLOWUP_DATE=NULL"
				+ ", UPDATE_USER=" + db.getInsertDBValue(loginUser)
				+ ", UPDATE_DATE=" + db.getInsertSysdate()
				+ " WHERE VEHICLEID=" + vehicleId + " AND ENTITYID=" + entityID
				+ " AND STATUS!=" + RecordStatus.DELETE);
		addEvent(up, vehicleId, entityID, "GROUND", loc, reason, note, null, loginUser);
		String transID = db.getNextIDValue("VEHICLETRANSID");
		String comments = "GROUNDED - " + reason + " @ " + loc
				+ (note.length() > 0 ? " - " + note : "");
		up.add("INSERT INTO VEHICLETRANS (VEHICLETRANSID, VEHICLEID, "
				+ "COMMENTS, CREATE_USER, CREATE_DATE, STATUS) VALUES ("
				+ transID + ", " + vehicleId + ", "
				+ db.getInsertDBValue(comments) + ", "
				+ db.getInsertDBValue(loginUser) + ", " + db.getInsertSysdate()
				+ ", " + RecordStatus.ACTIVE + ")");
		boolean ok = db.batchInsert(up);
		return xml(ok, ok ? "Van grounded" : "Ground failed");
	}

	private String saveFollowup(String vehicleId, String entityID,
			Map<String, String> requestMap, String loginUser) throws Exception {
		String loc = normLocation(rq(requestMap, "location"));
		String reason = rq(requestMap, "reason");
		if (reason.length() > 120)
			reason = reason.substring(0, 120);
		String note = rq(requestMap, "note");
		if (note.length() > 500)
			note = note.substring(0, 500);
		String follow = rq(requestMap, "followUpDate");
		if (follow.matches("\\d{4}-\\d{2}-\\d{2}"))
			follow = follow.substring(5, 7) + "/" + follow.substring(8, 10)
					+ "/" + follow.substring(0, 4);

		List<String> up = new ArrayList<String>();
		up.add("UPDATE VEHICLE SET GROUND_LOCATION=" + db.getInsertDBValue(loc)
				+ ", GROUND_REASON=" + db.getInsertDBValue(reason)
				+ ", GROUND_FOLLOWUP_NOTE=" + db.getInsertDBValue(note)
				+ ", GROUND_FOLLOWUP_DATE=" + db.getInsertDate(follow)
				+ ", GROUNDED_DATE=IFNULL(GROUNDED_DATE, CURDATE())"
				+ ", UPDATE_USER=" + db.getInsertDBValue(loginUser)
				+ ", UPDATE_DATE=" + db.getInsertSysdate()
				+ " WHERE VEHICLEID=" + vehicleId + " AND ENTITYID=" + entityID
				+ " AND STATUS!=" + RecordStatus.DELETE);
		addEvent(up, vehicleId, entityID, "FOLLOWUP", loc, reason, note, null, loginUser);
		boolean ok = db.batchInsert(up);
		return xml(ok, ok ? "Follow-up saved" : "Save failed");
	}

	private String doUnground(String vehicleId, String entityID,
			Map<String, String> requestMap, String loginUser) throws Exception {
		String notes = rq(requestMap, "note");
		if (notes.trim().length() == 0)
			return xml(false, "Enter what fixed it before ungrounding");
		String loc = normLocation(rq(requestMap, "location"));
		if (loc.length() == 0)
			loc = "DNK7";
		boolean ok = ungroundInternal(vehicleId, entityID, loc, notes, loginUser);
		return xml(ok, ok ? "Vehicle returned to service" : "Unground failed");
	}

	private boolean ungroundInternal(String vehicleId, String entityID,
			String loc, String notes, String loginUser) throws Exception {
		String days = "0";
		try {
			List d = db.selectAsList(
					"SELECT IFNULL(DATEDIFF(CURDATE(), GROUNDED_DATE),0), "
							+ "IFNULL(GROUND_REASON,''), IFNULL(GROUND_LOCATION,'') "
							+ "FROM VEHICLE WHERE VEHICLEID=" + vehicleId, 3);
			if (d != null && !d.isEmpty()) {
				List row = (List) d.get(0);
				days = getListData(row, 0);
				if (loc == null || loc.length() == 0)
					loc = getListData(row, 2);
			}
		} catch (Exception ignore) { }
		if (loc == null || loc.length() == 0)
			loc = "DNK7";
		String reason = "";
		try {
			reason = getTableColumnData("GROUND_REASON", "VEHICLE", "VEHICLEID", vehicleId);
		} catch (Exception ignore) { }
		Integer daysDown = null;
		try {
			daysDown = Integer.valueOf(days);
		} catch (Exception ignore) { }

		List<String> up = new ArrayList<String>();
		up.add("UPDATE VEHICLE SET OPERATIONALSTATUS=0, "
				+ "GROUND_LOCATION=" + db.getInsertDBValue(loc)
				+ ", GROUNDED_DATE=NULL, GROUND_FOLLOWUP_DATE=NULL, "
				+ "GROUND_FOLLOWUP_NOTE=" + db.getInsertDBValue("")
				+ ", UPDATE_USER=" + db.getInsertDBValue(loginUser)
				+ ", UPDATE_DATE=" + db.getInsertSysdate()
				+ " WHERE VEHICLEID=" + vehicleId + " AND ENTITYID=" + entityID
				+ " AND STATUS!=" + RecordStatus.DELETE);
		addEvent(up, vehicleId, entityID, "UNGROUND", loc, reason, notes, daysDown, loginUser);
		String transID = db.getNextIDValue("VEHICLETRANSID");
		up.add("INSERT INTO VEHICLETRANS (VEHICLETRANSID, VEHICLEID, "
				+ "COMMENTS, CREATE_USER, CREATE_DATE, STATUS) VALUES ("
				+ transID + ", " + vehicleId + ", "
				+ db.getInsertDBValue("UNGROUNDED - " + notes) + ", "
				+ db.getInsertDBValue(loginUser) + ", " + db.getInsertSysdate()
				+ ", " + RecordStatus.ACTIVE + ")");
		return db.batchInsert(up);
	}

	private String timeline(String vehicleId, String entityID) throws Exception {
		List r = db.selectAsList(
				"SELECT EVENT_TYPE, IFNULL(LOCATION,''), IFNULL(REASON,''), "
						+ "IFNULL(NOTES,''), IFNULL(DAYS_DOWN,''), IFNULL(CREATE_USER,''), "
						+ "IFNULL(DATE_FORMAT(CREATE_DATE,'%m/%d/%Y %l:%i %p'),'') "
						+ "FROM vehicle_ground_event WHERE VEHICLEID=" + vehicleId
						+ " AND ENTITYID=" + entityID + " AND STATUS!=" + RecordStatus.DELETE
						+ " ORDER BY VEHICLEGROUNDEVENTID DESC LIMIT 40", 7);
		if (r == null)
			r = new ArrayList();
		StringBuilder b = new StringBuilder("{\"events\":[");
		for (int i = 0; i < r.size(); i++) {
			List row = (List) r.get(i);
			if (i > 0)
				b.append(',');
			b.append("{\"type\":").append(js(getListData(row, 0)))
					.append(",\"loc\":").append(js(getListData(row, 1)))
					.append(",\"reason\":").append(js(getListData(row, 2)))
					.append(",\"notes\":").append(js(getListData(row, 3)))
					.append(",\"days\":").append(js(getListData(row, 4)))
					.append(",\"by\":").append(js(getListData(row, 5)))
					.append(",\"when\":").append(js(getListData(row, 6)))
					.append("}");
		}
		b.append("]}");
		return "<status>true</status><json>" + b.toString().replace("<", "\\u003C") + "</json>";
	}

	private void addEvent(List<String> up, String vehicleId, String entityID,
			String type, String loc, String reason, String notes,
			Integer daysDown, String loginUser) throws Exception {
		String id = db.getNextIDValue("VEHICLEGROUNDEVENTID");
		up.add("INSERT INTO vehicle_ground_event (VEHICLEGROUNDEVENTID, VEHICLEID, "
				+ "ENTITYID, EVENT_TYPE, LOCATION, REASON, NOTES, DAYS_DOWN, "
				+ "CREATE_USER, CREATE_DATE, STATUS) VALUES (" + id + ", "
				+ vehicleId + ", " + entityID + ", " + db.getInsertDBValue(type)
				+ ", " + db.getInsertDBValue(loc) + ", " + db.getInsertDBValue(reason)
				+ ", " + db.getInsertDBValue(notes) + ", "
				+ (daysDown == null ? "NULL" : daysDown.toString()) + ", "
				+ db.getInsertDBValue(loginUser) + ", " + db.getInsertSysdate()
				+ ", " + RecordStatus.ACTIVE + ")");
	}

	private String normLocation(String loc) {
		if (loc == null)
			return "DNK7";
		loc = loc.trim();
		for (int i = 0; i < LOCATIONS.length; i++) {
			if (LOCATIONS[i].equalsIgnoreCase(loc))
				return LOCATIONS[i];
		}
		return loc.length() == 0 ? "DNK7" : loc;
	}

	private String rq(Map<String, String> map, String key) {
		String v = map.get(key);
		return v == null ? "" : v.trim();
	}

	private String xml(boolean ok, String mesg) {
		return "<status>" + ok + "</status><mesg>" + escXml(mesg) + "</mesg>";
	}

	private String escXml(String s) {
		if (s == null)
			return "";
		return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;");
	}

	private String js(String s) {
		if (s == null)
			return "\"\"";
		StringBuilder b = new StringBuilder("\"");
		for (int i = 0; i < s.length(); i++) {
			char c = s.charAt(i);
			if (c == '"')
				b.append("\\\"");
			else if (c == '\\')
				b.append("\\\\");
			else if (c == '<')
				b.append("\\u003C");
			else if (c >= 32)
				b.append(c);
		}
		return b.append('"').toString();
	}
}
