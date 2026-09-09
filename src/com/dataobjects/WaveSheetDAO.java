package com.dataobjects;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import com.beans.SearchBean;
import com.beans.WaveSheet;
import com.util.RecordStatus;

/*
 * Wave Sheet - daily route assignments (route_assignment).
 * The page OCRs wave-sheet images in the browser; this DAO bootstraps the
 * DA list + the selected day's saved rows, and persists a whole day at a
 * time (delete-and-reload per ASSIGN_DATE).
 */
public class WaveSheetDAO extends MVPGDAO {

	WaveSheet bean = new WaveSheet();

	private String js(String s) {
		if (s == null) return "\"\"";
		StringBuilder b = new StringBuilder("\"");
		for (int i = 0; i < s.length(); i++) {
			char c = s.charAt(i);
			if (c == '"') b.append("\\\"");
			else if (c == '\\') b.append("\\\\");
			else if (c == '\n' || c == '\r') b.append(' ');
			else if (c == '<') b.append("\\u003C");
			else if (c >= 32) b.append(c);
		}
		return b.append('"').toString();
	}

	private String d(List row, int i) {
		if (row == null || i >= row.size() || row.get(i) == null) return "";
		return row.get(i).toString().trim();
	}

	/* requestMap values arrive with apostrophes doubled */
	private String rq(Map<String, String> requestMap, String key) {
		String v = requestMap.get(key) == null ? "" : requestMap.get(key).trim();
		return v.replace("''", "'");
	}

	@Override
	public SearchBean searchRecords(SearchBean searchBean, String recordID,
			String loginUser, String loginUserRoles, String loginUserID,
			String entityID) throws Exception {

		searchBean.setDisplayName(bean.getDisplayName());
		searchBean.setController(bean.getController());
		searchBean.setLabelsList(new ArrayList<String>());
		searchBean.setDataList(new ArrayList());

		String today = db.getCurrentDate();

		StringBuilder o = new StringBuilder("{\"date\":" + js(today));

		/* every active DA for name matching (role 4 = driver, but include
		   all non-deleted so helpers/trainers match too) */
		o.append(",\"das\":[");
		/* DA match list = ACTIVE associates only. STATUS filters deleted records;
		   REVIEW_STATUS is the employment status (0 Active / 4 Inactive /
		   8 Terminated / 9 Quit) — only 0 should be assignable on a wave sheet.
		   NULL review status = manually-added, treated as active. */
		List r = db.selectAsList("SELECT EMPLOYEEID, IFNULL(TRANSPORTERID,''), "
				+ "IFNULL(FULLNAME,'') FROM EMPLOYEE WHERE STATUS!="
				+ RecordStatus.DELETE + " AND ENTITYID=" + entityID
				+ " AND IFNULL(REVIEW_STATUS," + RecordStatus.ACTIVE + ")="
				+ RecordStatus.ACTIVE
				+ " AND IFNULL(FULLNAME,'')!='' ORDER BY FULLNAME", 3);
		for (int i = 0; i < r.size(); i++) {
			List t = (List) r.get(i);
			o.append(i > 0 ? "," : "").append("{\"e\":").append(jnum(d(t, 0)))
					.append(",\"t\":").append(js(d(t, 1)))
					.append(",\"n\":").append(js(d(t, 2))).append("}");
		}
		o.append("],\"rows\":").append(dayRowsJson(today, entityID)).append("}");

		Map transMap = searchBean.getTransMap() == null ? new HashMap()
				: searchBean.getTransMap();
		transMap.put("bootstrapJson", o.toString());
		searchBean.setTransMap(transMap);
		return searchBean;
	}

	private String jnum(String v) {
		return v.matches("\\d+") ? v : "0";
	}

	/* Scope Slack sheets to a single day = the page's selected date (date
	   picker) if it sent one, else today. Change the date picker to see a
	   different day's sheets. */
	private String slackDayCond(Map<String, String> requestMap) {
		String date = rq(requestMap, "assignDate");
		if (date.matches("\\d{2}/\\d{2}/\\d{4}"))
			return " AND DATE(CREATE_DATE)=" + db.getInsertDate(date);
		return " AND DATE(CREATE_DATE)=CURDATE()";
	}

	/* Slack wave-sheet load mode: "review" (default) or "auto" */
	private String getSlackMode(String entityID) throws Exception {
		List r = db.selectAsList(
				"SELECT VAL FROM emily_config WHERE NAME='SLACK_WAVE_MODE'", 1);
		String v = r.isEmpty() ? "" : d((List) r.get(0), 0);
		return "auto".equalsIgnoreCase(v) ? "auto" : "review";
	}

	private String dayRowsJson(String mdyDate, String entityID)
			throws Exception {
		List r = db.selectAsList("SELECT ROUTE, IFNULL(DRIVER_NAME,''), "
				+ "IFNULL(TRANSPORTERID,''), IFNULL(STAGING,''), "
				+ "IFNULL(SERVICETYPE,''), IFNULL(DSP,''), IFNULL(WAVE_TIME,'') "
				+ "FROM route_assignment WHERE ENTITYID=" + entityID
				+ " AND STATUS!=" + RecordStatus.DELETE
				+ db.getDateCondQuery(mdyDate, mdyDate, "ASSIGN_DATE")
				+ " ORDER BY STAGING, ROUTE", 7);
		StringBuilder o = new StringBuilder("[");
		for (int i = 0; i < r.size(); i++) {
			List t = (List) r.get(i);
			o.append(i > 0 ? "," : "").append("{\"route\":").append(js(d(t, 0)))
					.append(",\"driver\":").append(js(d(t, 1)))
					.append(",\"tid\":").append(js(d(t, 2)))
					.append(",\"staging\":").append(js(d(t, 3)))
					.append(",\"service\":").append(js(d(t, 4)))
					.append(",\"dsp\":").append(js(d(t, 5)))
					.append(",\"wave\":").append(js(d(t, 6))).append("}");
		}
		return o.append("]").toString();
	}

	@Override
	public String getAjaxRequestTypeResp(String requestType,
			Map<String, String> requestMap, String loginUser,
			String loginUserRoles, String loginUserID, String entityID)
			throws Exception {

		if ("dayRows".equalsIgnoreCase(requestType)) {
			String date = rq(requestMap, "assignDate");
			if (!date.matches("\\d{2}/\\d{2}/\\d{4}"))
				return "<status>false</status><mesg>Bad date</mesg>";
			return dayRowsJson(date, entityID);
		}

		if ("saveDay".equalsIgnoreCase(requestType)) {
			String date = rq(requestMap, "assignDate");
			if (!date.matches("\\d{2}/\\d{2}/\\d{4}"))
				return "<status>false</status><mesg>Bad date</mesg>";
			String rowsJson = rq(requestMap, "rowsJson");
			List<Map<String, String>> rows = parseRows(rowsJson);
			if (rows.isEmpty())
				return "<status>false</status><mesg>No rows to save</mesg>";

			/* TID -> EMPLOYEEID for the lookup column */
			Map<String, String> tidEmp = new HashMap<String, String>();
			List r = db.selectAsList("SELECT UPPER(IFNULL(TRANSPORTERID,'')), "
					+ "EMPLOYEEID FROM EMPLOYEE WHERE STATUS!="
					+ RecordStatus.DELETE + " AND ENTITYID=" + entityID, 2);
			for (int i = 0; i < r.size(); i++) {
				List t = (List) r.get(i);
				if (d(t, 0).length() > 0)
					tidEmp.put(d(t, 0), d(t, 1));
			}

			/* delete-and-reload the day. Runs OUTSIDE the batch: batchInsert
			   rolls the whole batch back when any statement touches 0 rows,
			   which is exactly what this UPDATE does on a first save. */
			try {
				db.update("UPDATE route_assignment SET STATUS=" + RecordStatus.DELETE
						+ ", UPDATE_USER=" + db.getInsertDBValue(loginUser)
						+ ", UPDATE_DATE=" + db.getInsertSysdate()
						+ " WHERE ENTITYID=" + entityID + " AND STATUS!="
						+ RecordStatus.DELETE
						+ db.getDateCondQuery(date, date, "ASSIGN_DATE"));
			} catch (Exception ex) {
				// nothing to clear on a first save
			}

			List<String> upList = new ArrayList<String>();
			int saved = 0;
			for (Map<String, String> row : rows) {
				String route = row.get("route") == null ? ""
						: row.get("route").trim();
				if (route.length() == 0) continue;
				String tid = row.get("tid") == null ? "" : row.get("tid").trim();
				String empID = tidEmp.get(tid.toUpperCase());

				upList.add("INSERT INTO route_assignment (ENTITYID, ASSIGN_DATE, "
						+ "DSP, ROUTE, DRIVER_NAME, TRANSPORTERID, EMPLOYEEID, "
						+ "STAGING, SERVICETYPE, WAVE_TIME, "
						+ "CREATE_USER, CREATE_DATE, STATUS) VALUES ("
						+ entityID + ", " + db.getInsertDate(date) + ", "
						+ db.getInsertDBValue(row.get("dsp")) + ", "
						+ db.getInsertDBValue(route) + ", "
						+ db.getInsertDBValue(row.get("driver")) + ", "
						+ db.getInsertDBValue(tid) + ", "
						+ (empID != null && empID.matches("\\d+") ? empID : "NULL")
						+ ", " + db.getInsertDBValue(row.get("staging")) + ", "
						+ db.getInsertDBValue(row.get("service")) + ", "
						+ db.getInsertDBValue(row.get("wave")) + ", "
						+ db.getInsertDBValue(loginUser) + ", "
						+ db.getInsertSysdate() + ", " + RecordStatus.ACTIVE
						+ ")");
				saved++;
			}

			boolean result = db.batchInsert(upList);
			if (!result)
				return "<status>false</status><mesg>Save failed</mesg>";
			return "<status>true</status><mesg>" + saved
					+ " routes saved for " + date + "</mesg>";
		}

		/* ---- Slack wave-sheet inbox (delivered by the AMZL Bridge) ----
		   scoped to the selected day (defaults to today) — wave sheets are for
		   the day being dispatched, so old sheets never show or auto-load. */
		if ("slackInbox".equalsIgnoreCase(requestType)) {
			List r = db.selectAsList("SELECT WSID, IFNULL(WAVE_LABEL,''), "
					+ "IFNULL(CAPTION,''), IFNULL(IMG_W,0), IFNULL(IMG_H,0), "
					+ "DATE_FORMAT(CREATE_DATE,'%m/%d %H:%i'), IFNULL(CHANNEL,'') "
					+ "FROM slack_wavesheet WHERE ENTITYID=" + entityID
					+ " AND STATUS=0" + slackDayCond(requestMap)
					+ " ORDER BY WSID DESC LIMIT 40", 7);
			StringBuilder o = new StringBuilder("[");
			for (int i = 0; i < r.size(); i++) {
				List t = (List) r.get(i);
				o.append(i > 0 ? "," : "").append("{\"wsid\":").append(jnum(d(t, 0)))
						.append(",\"wave\":").append(js(d(t, 1)))
						.append(",\"caption\":").append(js(d(t, 2)))
						.append(",\"w\":").append(jnum(d(t, 3)))
						.append(",\"h\":").append(jnum(d(t, 4)))
						.append(",\"when\":").append(js(d(t, 5)))
						.append(",\"channel\":").append(js(d(t, 6))).append("}");
			}
			return o.append("]").toString();
		}

		if ("slackRecent".equalsIgnoreCase(requestType)) {
			/* already-loaded sheets (STATUS=1) kept for re-loading; images are
			   retained, not deleted, so a sheet can be pulled back any time */
			List r = db.selectAsList("SELECT WSID, IFNULL(WAVE_LABEL,''), "
					+ "IFNULL(CAPTION,''), DATE_FORMAT(IFNULL(CONSUMED_DATE,CREATE_DATE),'%m/%d %H:%i') "
					+ "FROM slack_wavesheet WHERE ENTITYID=" + entityID
					+ " AND STATUS=1" + slackDayCond(requestMap)
					+ " ORDER BY WSID DESC LIMIT 25", 4);
			StringBuilder o = new StringBuilder("[");
			for (int i = 0; i < r.size(); i++) {
				List t = (List) r.get(i);
				o.append(i > 0 ? "," : "").append("{\"wsid\":").append(jnum(d(t, 0)))
						.append(",\"wave\":").append(js(d(t, 1)))
						.append(",\"caption\":").append(js(d(t, 2)))
						.append(",\"when\":").append(js(d(t, 3))).append("}");
			}
			return o.append("]").toString();
		}

		if ("slackImage".equalsIgnoreCase(requestType)) {
			String wsid = rq(requestMap, "wsid");
			if (!wsid.matches("\\d+"))
				return "";
			List r = db.selectAsList("SELECT IFNULL(IMG_MIME,'image/png'), "
					+ "TO_BASE64(IMG_DATA) FROM slack_wavesheet WHERE WSID="
					+ wsid + " AND ENTITYID=" + entityID, 2);
			if (r.isEmpty())
				return "";
			List t = (List) r.get(0);
			/* plain data-URI text; the page turns it into a File for OCR */
			return "data:" + d(t, 0) + ";base64," + d(t, 1).replaceAll("\\s", "");
		}

		if ("slackMode".equalsIgnoreCase(requestType)) {
			return getSlackMode(entityID); /* "review" | "auto" */
		}

		if ("slackSetMode".equalsIgnoreCase(requestType)) {
			String mode = rq(requestMap, "mode");
			mode = "auto".equalsIgnoreCase(mode) ? "auto" : "review";
			db.update("INSERT INTO emily_config (NAME, VAL, DESCRIPTION, "
					+ "UPDATE_USER, UPDATE_DATE) VALUES ('SLACK_WAVE_MODE', "
					+ db.getInsertDBValue(mode) + ", 'Slack wave-sheet load mode', "
					+ db.getInsertDBValue(loginUser) + ", " + db.getInsertSysdate()
					+ ") ON DUPLICATE KEY UPDATE VAL=VALUES(VAL), UPDATE_USER="
					+ "VALUES(UPDATE_USER), UPDATE_DATE=VALUES(UPDATE_DATE)");
			return "<status>true</status><mesg>" + mode + "</mesg>";
		}

		if ("slackConsume".equalsIgnoreCase(requestType)
				|| "slackDismiss".equalsIgnoreCase(requestType)) {
			String wsid = rq(requestMap, "wsid");
			if (!wsid.matches("\\d+"))
				return "<status>false</status><mesg>Bad id</mesg>";
			int st = "slackDismiss".equalsIgnoreCase(requestType) ? 2 : 1;
			db.update("UPDATE slack_wavesheet SET STATUS=" + st + ", CONSUMED_USER="
					+ db.getInsertDBValue(loginUser) + ", CONSUMED_DATE="
					+ db.getInsertSysdate() + " WHERE WSID=" + wsid
					+ " AND ENTITYID=" + entityID);
			return "<status>true</status><mesg>ok</mesg>";
		}

		return super.getAjaxRequestTypeResp(requestType, requestMap, loginUser,
				loginUserRoles, loginUserID, entityID);
	}

	/* minimal JSON-array-of-flat-objects parser (string values only) —
	   avoids adding a JSON lib to the stack */
	private List<Map<String, String>> parseRows(String json) {
		List<Map<String, String>> out = new ArrayList<Map<String, String>>();
		if (json == null) return out;
		int i = 0, n = json.length();
		while (i < n) {
			while (i < n && json.charAt(i) != '{') i++;
			if (i >= n) break;
			i++;
			Map<String, String> obj = new HashMap<String, String>();
			while (i < n && json.charAt(i) != '}') {
				while (i < n && json.charAt(i) != '"' && json.charAt(i) != '}') i++;
				if (i >= n || json.charAt(i) == '}') break;
				StringBuilder key = new StringBuilder();
				i++;
				while (i < n && json.charAt(i) != '"') {
					if (json.charAt(i) == '\\' && i + 1 < n) i++;
					key.append(json.charAt(i));
					i++;
				}
				i++;
				while (i < n && (json.charAt(i) == ':' || json.charAt(i) == ' ')) i++;
				StringBuilder val = new StringBuilder();
				if (i < n && json.charAt(i) == '"') {
					i++;
					while (i < n && json.charAt(i) != '"') {
						if (json.charAt(i) == '\\' && i + 1 < n) {
							i++;
							char c = json.charAt(i);
							if (c == 'n' || c == 'r') { val.append(' '); i++; continue; }
						}
						val.append(json.charAt(i));
						i++;
					}
					i++;
				} else {
					while (i < n && json.charAt(i) != ',' && json.charAt(i) != '}') {
						val.append(json.charAt(i));
						i++;
					}
				}
				obj.put(key.toString(), val.toString().trim());
				while (i < n && (json.charAt(i) == ',' || json.charAt(i) == ' ')) i++;
			}
			if (!obj.isEmpty()) out.add(obj);
			i++;
		}
		return out;
	}
}