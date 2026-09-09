package com.dataobjects;

import java.io.File;
import java.io.FileOutputStream;
import java.util.ArrayList;
import java.util.Base64;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import com.beans.SearchBean;
import com.util.RecordStatus;

/**
 * Returns Board — one-tap end-of-shift checkouts for dispatchers on iPad.
 *
 * Tiles = today's check-ins with no checkout yet. "All good" writes a full
 * dacheckout row with every checklist item defaulted to OK, clock-out taken
 * from the Flex app sign-out (daily_itineraries.APP_SIGNOUT) when present.
 * The exception path accepts flipped checklist flags, packages-left count,
 * remarks and a camera photo (base64, stored as a COMMONUPLOADS blob under
 * MODULE='DACheckout' so it shows on the checkout record's uploads).
 */
public class ReturnsBoardDAO extends MVPGDAO {

	private String js(String s) {
		if (s == null) return "\"\"";
		StringBuilder b = new StringBuilder("\"");
		for (int i = 0; i < s.length(); i++) {
			char c = s.charAt(i);
			if (c == '"') b.append("\\\"");
			else if (c == '\\') b.append("\\\\");
			else if (c == '<') b.append("\\u003C");
			else if (c >= 32) b.append(c);
		}
		return b.append('"').toString();
	}

	private String d(List row, int i) {
		if (row == null || i >= row.size() || row.get(i) == null) return "";
		return row.get(i).toString().trim();
	}

	@Override
	public SearchBean searchRecords(SearchBean searchBean, String recordID,
			String loginUser, String loginUserRoles, String loginUserID,
			String entityID) throws Exception {

		searchBean.setDisplayName("Returns Board");
		searchBean.setController("ReturnsBoard");
		searchBean.setLabelsList(new ArrayList<String>());
		searchBean.setDataList(new ArrayList());

		String boardDate = searchBean.getSrhFromDate();
		if (boardDate == null || boardDate.trim().length() == 0)
			boardDate = db.getCurrentDate();

		Map transMap = searchBean.getTransMap() == null ? new HashMap()
				: searchBean.getTransMap();
		transMap.put("boardJson", buildBoard(boardDate, entityID));
		transMap.put("boardDate", boardDate);
		searchBean.setTransMap(transMap);
		return searchBean;
	}

	private String buildBoard(String boardDate, String entityID) throws Exception {
		String dCond = db.getDateCondTypeQuery(db.EQUALS_TO, "C.CLOCKINTIME", boardDate);

		/* still out: check-ins without a checkout */
		/* itineraries pre-aggregated per DA/day: only_full_group_by is on,
		   and a raw LEFT JOIN would duplicate tiles per itinerary row */
		List r = db.selectAsList("SELECT C.DACHECKINID, C.EMPLOYEEID, IFNULL(E.FULLNAME,''), "
				+ "IFNULL(V.VEHICLENUMBER,''), IFNULL(V.VINNUMBER,''), "
				+ "TIME_FORMAT(C.CLOCKINTIME,'%l:%i %p'), IFNULL(C.WAVE,''), IFNULL(C.PARKING,''), "
				+ "IFNULL(TIME_FORMAT(I.SO,'%l:%i %p'),''), IFNULL(I.CS,''), IFNULL(I.ST,'') "
				+ "FROM dacheckin C "
				+ "JOIN employee E ON C.EMPLOYEEID=E.EMPLOYEEID "
				+ "LEFT JOIN vehicle V ON C.VEHICLEID=V.VEHICLEID "
				+ "LEFT JOIN (SELECT TRANSPORTERID, DATE(ITINARARYDATE) DT, MAX(APP_SIGNOUT) SO, "
				+ "SUM(COMPLETEDSTOPS) CS, SUM(ALLSTOPS) ST FROM daily_itineraries WHERE STATUS!=1 "
				+ "GROUP BY TRANSPORTERID, DATE(ITINARARYDATE)) I "
				+ "ON I.TRANSPORTERID=E.TRANSPORTERID AND I.DT=DATE(C.CLOCKINTIME) "
				+ "WHERE C.ENTITYID=" + entityID + " AND C.STATUS!=" + RecordStatus.DELETE
				+ dCond
				+ " AND NOT EXISTS (SELECT 1 FROM dacheckout O WHERE O.DACHECKINID=C.DACHECKINID "
				+ "AND O.STATUS!=" + RecordStatus.DELETE + ") "
				+ "ORDER BY V.VEHICLENUMBER, E.FULLNAME", 11);

		StringBuilder o = new StringBuilder("{\"out\":[");
		for (int i = 0; i < r.size(); i++) {
			List t = (List) r.get(i);
			o.append(i > 0 ? "," : "").append("{\"ck\":").append(d(t, 0))
					.append(",\"emp\":").append(d(t, 1))
					.append(",\"nm\":").append(js(d(t, 2)))
					.append(",\"veh\":").append(js(d(t, 3)))
					.append(",\"vin\":").append(js(d(t, 4)))
					.append(",\"in\":").append(js(d(t, 5)))
					.append(",\"wave\":").append(js(d(t, 6)))
					.append(",\"flexOut\":").append(js(d(t, 8)))
					.append(",\"stops\":").append(js(d(t, 9).length() > 0 ? d(t, 9) + "/" + d(t, 10) : ""))
					.append("}");
		}
		o.append("],\"done\":[");

		/* already returned that day */
		r = db.selectAsList("SELECT IFNULL(E.FULLNAME,''), IFNULL(V.VEHICLENUMBER,''), "
				+ "TIME_FORMAT(O.CLOCKOUTTIME,'%l:%i %p'), "
				+ "(O.VEHICLECLEAN=0 OR O.POSTINSPECTION=0 OR O.PHONERETURNED=0 OR O.GASCARDRETURNED=0 "
				+ "OR O.CABLES=0 OR O.FLASHLIGHT=0 OR O.POWERBANK=0 OR IFNULL(O.PACKAGESLEFT,0)>0), "
				+ "IFNULL(O.DISPATCHERREMARKS,'') "
				+ "FROM dacheckout O JOIN dacheckin C ON O.DACHECKINID=C.DACHECKINID "
				+ "JOIN employee E ON C.EMPLOYEEID=E.EMPLOYEEID "
				+ "LEFT JOIN vehicle V ON C.VEHICLEID=V.VEHICLEID "
				+ "WHERE O.ENTITYID=" + entityID + " AND O.STATUS!=" + RecordStatus.DELETE
				+ " AND C.STATUS!=" + RecordStatus.DELETE + dCond
				+ " ORDER BY O.CLOCKOUTTIME DESC", 5);
		for (int i = 0; i < r.size(); i++) {
			List t = (List) r.get(i);
			o.append(i > 0 ? "," : "").append("{\"nm\":").append(js(d(t, 0)))
					.append(",\"veh\":").append(js(d(t, 1)))
					.append(",\"outAt\":").append(js(d(t, 2)))
					.append(",\"flag\":").append("1".equals(d(t, 3)) ? "true" : "false")
					.append(",\"rm\":").append(js(d(t, 4)))
					.append("}");
		}
		o.append("]}");
		return o.toString();
	}

	/* ── AJAX: board refresh + checkouts ────────────────────── */
	@Override
	public String getAjaxRequestTypeResp(String requestType,
			Map<String, String> requestMap, String loginUser,
			String loginUserRoles, String loginUserID, String entityID)
			throws Exception {

		String boardDate = requestMap.get("boardDate") == null ? db.getCurrentDate()
				: requestMap.get("boardDate").trim();

		if ("board".equalsIgnoreCase(requestType))
			return buildBoard(boardDate, entityID);

		if (!"boardCheckout".equalsIgnoreCase(requestType)) return "";

		String checkinID = requestMap.get("checkinID") == null ? "" : requestMap.get("checkinID").trim();
		if (!checkinID.matches("\\d+"))
			return "<status>false</status><mesg>Missing check-in</mesg>";

		/* duplicate guard — same rule the legacy form uses */
		String existing = db.selectById("SELECT DACHECKOUTID FROM dacheckout WHERE STATUS!="
				+ RecordStatus.DELETE + " AND DACHECKINID=" + checkinID);
		if (existing.length() > 0)
			return "<status>false</status><mesg>Already checked out</mesg>";

		/* check-in context: parking + DA + date */
		List r = db.selectAsList("SELECT C.PARKING, C.EMPLOYEEID, DATE(C.CLOCKINTIME), "
				+ "IFNULL(E.TRANSPORTERID,'') FROM dacheckin C "
				+ "JOIN employee E ON C.EMPLOYEEID=E.EMPLOYEEID WHERE C.DACHECKINID=" + checkinID, 4);
		if (r.isEmpty())
			return "<status>false</status><mesg>Check-in not found</mesg>";
		String parking = d((List) r.get(0), 0);
		/* board buttons pick where the van was parked: 1 Inside, 2 Outside, 3 Backside */
		String pkIn = requestMap.get("parking") == null ? "" : requestMap.get("parking").trim();
		if (pkIn.matches("[123]")) parking = pkIn;
		String ciDate = d((List) r.get(0), 2);
		String tid = d((List) r.get(0), 3).replaceAll("'", "''");

		/* clock-out: Flex app sign-out if we have it, else now */
		String clockout = "NOW()";
		if (tid.length() > 0) {
			String so = db.selectById("SELECT MAX(APP_SIGNOUT) FROM daily_itineraries "
					+ "WHERE TRANSPORTERID='" + tid + "' AND DATE(ITINARARYDATE)='" + ciDate
					+ "' AND STATUS!=1 AND APP_SIGNOUT IS NOT NULL");
			if (so.length() > 0) clockout = "'" + so + "'";
		}

		/* checklist: default all-OK; the exception sheet overrides */
		String[] items = { "postInspection", "vehicleClean", "dispatcherChecked",
				"calledFromLast", "phoneReturned", "gasCardReturned", "cables",
				"flashLight", "powerBank" };
		Map<String, String> vals = new HashMap<String, String>();
		for (int i = 0; i < items.length; i++) {
			String v = requestMap.get(items[i]);
			vals.put(items[i], v != null && v.trim().equals("0") ? "0" : "1");
		}
		String pkgsLeft = requestMap.get("packagesLeft") == null ? "0" : requestMap.get("packagesLeft").trim();
		if (!pkgsLeft.matches("\\d{1,4}")) pkgsLeft = "0";
		String remarks = requestMap.get("remarks") == null ? "" : requestMap.get("remarks").trim();
		boolean allGood = "good".equalsIgnoreCase(
				requestMap.get("mode") == null ? "good" : requestMap.get("mode").trim());
		if (remarks.length() == 0 && allGood)
			remarks = "Returns Board: all good";
		if (remarks.length() > 1400) remarks = remarks.substring(0, 1400);

		String recordID = db.getNextIDValue("DACHECKOUTID");
		List<String> insList = new ArrayList<String>();
		insList.add("INSERT INTO dacheckout (DACHECKOUTID, ENTITYID, DACHECKINID, CLOCKOUTTIME, "
				+ "POSTINSPECTION, PARKING, VEHICLECLEAN, DISPATCHERCHECKED, PACKAGESLEFT, "
				+ "CALLEDFROMLAST, PHONERETURNED, GASCARDRETURNED, CABLES, FLASHLIGHT, POWERBANK, "
				+ "DAREMARKS, DISPATCHERREMARKS, CREATE_USER, CREATE_DATE, STATUS) VALUES ("
				+ recordID + ", " + entityID + ", " + checkinID + ", " + clockout + ", "
				+ vals.get("postInspection") + ", " + db.getInsertDBValue(parking) + ", "
				+ vals.get("vehicleClean") + ", " + vals.get("dispatcherChecked") + ", "
				+ pkgsLeft + ", " + vals.get("calledFromLast") + ", " + vals.get("phoneReturned") + ", "
				+ vals.get("gasCardReturned") + ", " + vals.get("cables") + ", "
				+ vals.get("flashLight") + ", " + vals.get("powerBank") + ", '', "
				+ db.getInsertDBValue(remarks) + ", " + db.getInsertDBValue(loginUser) + ", "
				+ db.getInsertSysdate() + ", " + RecordStatus.ACTIVE + ")");
		boolean result = db.batchInsert(insList);
		if (!result)
			return "<status>false</status><mesg>Save failed</mesg>";

		/* optional walk-around photo -> COMMONUPLOADS blob on the checkout */
		String photo = requestMap.get("photo") == null ? "" : requestMap.get("photo").trim();
		String photoMsg = "";
		if (photo.startsWith("data:image")) {
			try {
				String b64 = photo.substring(photo.indexOf(",") + 1)
						.replaceAll(" ", "+").replaceAll("@@", "");
				byte[] bytes = Base64.getDecoder().decode(b64);
				File tmp = File.createTempFile("returns_" + recordID + "_", ".jpg");
				FileOutputStream fos = new FileOutputStream(tmp);
				fos.write(bytes);
				fos.close();

				String upID = db.getNextIDValue("COMMONUPLOADSID");
				String insQry = "INSERT INTO COMMONUPLOADS (COMMONUPLOADSID, ENTITYID, MODULE, "
						+ "MODULEID, CREATE_USER, CREATE_DATE, STATUS) VALUES (" + upID + ", "
						+ entityID + ", 'DACheckout', " + recordID + ", "
						+ db.getInsertDBValue(loginUser) + ", " + db.getInsertSysdate() + ", "
						+ RecordStatus.ACTIVE + ")";
				String fileName = "checkout_" + recordID + ".jpg";
				String autoInc[] = db.getAutoIncrementArray("COMMONUPLOADSTRANSID");
				String blobQry = "INSERT INTO COMMONUPLOADSTRANS ("
						+ (autoInc != null ? autoInc[0] : "")
						+ "COMMONUPLOADSID, UPLOADTYPE, UPLOADBLOB, UPLOAD_NAME, UPLOADPATH, "
						+ "COMMENTS, CREATE_USER, CREATE_DATE, STATUS) VALUES ("
						+ (autoInc != null ? autoInc[1] : "")
						+ upID + ", 'Returns Photo', ?, " + db.getInsertDBValue(fileName)
						+ ", '', 'Returns Board walk-around', "
						+ db.getInsertDBValue(loginUser) + ", " + db.getInsertSysdate() + ", "
						+ RecordStatus.ACTIVE + ")";
				boolean pOK = db.insertBlob(insQry, blobQry, tmp.getAbsolutePath());
				tmp.delete();
				photoMsg = pOK ? " with photo" : " (photo failed)";
			} catch (Exception ex) {
				ex.printStackTrace();
				photoMsg = " (photo failed)";
			}
		}

		return "<status>true</status><mesg>" + (allGood ? "Checked out" : "Checked out with issues")
				+ photoMsg + "</mesg>";
	}
}
