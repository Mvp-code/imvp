package com.dataobjects;

import java.io.File;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import com.beans.AdminVehicle;
import com.beans.ApplicationConfig;
import com.beans.ErrorBean;
import com.beans.MainBean;
import com.beans.SearchBean;
import com.tools.FileUpload;
import com.tools.ServerUploadPaths;
import com.util.RecordStatus;
import com.util.SubmitType;

public class AdminVehicleDAO extends MVPGDAO {

	AdminVehicle bean = new AdminVehicle();

	/* ensure the MVPx-only OUT_FOR_REPAIR flag column exists on VEHICLE — it is
	   stripped whenever a vehiclesdata upload recreates the table (ExcelFile
	   DROP+CREATE from the Amazon file's columns). Best-effort; never blocks. */
	private void ensureOutForRepairColumn() {
		try {
			java.util.List _c = db.selectAsList(
					"SELECT 1 FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() "
					+ "AND TABLE_NAME='vehicle' AND COLUMN_NAME='OUT_FOR_REPAIR'", 1);
			if (_c == null || _c.isEmpty())
				db.create("ALTER TABLE vehicle ADD COLUMN OUT_FOR_REPAIR INT DEFAULT 0");
		} catch (Exception _e) { /* best effort */ }
	}

	private void ensureVehicleMetricColumns() {
		String[][] cols = {
			{"ODOMETER", "INT NULL"},
			{"LAST_ODOMETER_REPORTED_DATE", "DATE NULL"},
			{"LAST_OIL_CHANGE_MILEAGE", "INT NULL"},
			{"LAST_OIL_CHANGE_DATE", "DATE NULL"},
			{"REGISTRATION_PDF", "VARCHAR(500) NULL"},
			{"RO_PDF", "VARCHAR(500) NULL"},
			{"RO_NUMBER", "VARCHAR(100) NULL"},
			{"RO_DATE", "DATE NULL"}
		};
		for (String[] col : cols) {
			try {
				java.util.List _c = db.selectAsList(
						"SELECT 1 FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() "
						+ "AND TABLE_NAME='vehicle' AND COLUMN_NAME='" + col[0] + "'", 1);
				if (_c == null || _c.isEmpty())
					db.create("ALTER TABLE vehicle ADD COLUMN " + col[0] + " " + col[1]);
			} catch (Exception _e) { /* best effort */ }
		}
		/* RO / oil / attachment paths on maintenance log rows (best effort) */
		String[][] logCols = {
			{"RO_DATE", "DATE NULL"},
			{"RO_PDF", "VARCHAR(500) NULL"},
			{"OIL_PDF", "VARCHAR(500) NULL"},
			{"DOC_PDF", "VARCHAR(500) NULL"}
		};
		for (String[] col : logCols) {
			try {
				java.util.List _c = db.selectAsList(
						"SELECT 1 FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() "
						+ "AND TABLE_NAME='vehicle_maintenance_log' AND COLUMN_NAME='" + col[0] + "'", 1);
				if (_c == null || _c.isEmpty())
					db.create("ALTER TABLE vehicle_maintenance_log ADD COLUMN "
							+ col[0] + " " + col[1]);
			} catch (Exception _e) { /* best effort */ }
		}
	}

	@Override
	public SearchBean searchRecords(SearchBean searchBean, String recordID,
			String loginUser, String loginUserRoles, String loginUserID,
			String entityID) throws Exception {

		/* Self-heal: a "vehiclesdata" Smart Upload recreates the VEHICLE table
		   from the Amazon file (ExcelFile DROP+CREATE), which strips the
		   MVPx-only OUT_FOR_REPAIR flag column and blanks this page (the list
		   query references it). Re-add it if a reload removed it. */
		ensureOutForRepairColumn();
		ensureVehicleMetricColumns();

		List<String> labelsList = new ArrayList<String>();
		labelsList.add("Vehicle Number");
		labelsList.add("VIN Number");
		labelsList.add("Registration Expiry");
		labelsList.add("Odometer");
		labelsList.add("Last Odometer Reported Date");
		labelsList.add("Last Oil Change Mileage");
		labelsList.add("Last Oil Change Date");
		labelsList.add("Service Tier");
		labelsList.add("Rental Start");
		labelsList.add("Rental End");
		labelsList.add("Number of days Rented");
		labelsList.add("Provider");
		labelsList.add("Op Status");
		labelsList.add("Out for Repair");

		searchBean.setWidthColumns(
				new int[] { 8, 10, 8, 6, 9, 8, 8, 9, 7, 7, 6, 8, 7, 5 });

		searchBean.setDisplayName(bean.getDisplayName() + "s");

		searchBean.setController(bean.getController());

		String condQry = "";

		condQry += db.getDataInCondQuery(searchBean.getSrhValue(),
				"VEHICLENUMBER");

		/* no default op-status clamp: the list shows every vehicle and the
		   page's client-side filters (op status, status, repair) narrow it */
		if (searchBean.getSrhStatus().length() > 0) {
			condQry += db.getIDInCondQuery(searchBean.getSrhStatus(),
					"OPERATIONALSTATUS");
		}

		String dateVal = searchBean.getSrhToDate();
		if (dateVal.length() == 0)
			dateVal = db.getCurrentDate();

		condQry += db.getDateCondQuery(searchBean.getSrhFromDate(),
				searchBean.getSrhToDate(), "RENTAL_START");

		searchBean.setColumnSortName(searchBean.getColumnSortName()
				.replaceAll("9", "15").replaceAll("8", "14"));

		String selQry = "SELECT VEHICLEID, VEHICLENUMBER, VINNUMBER, "
				+ db.getSelectDate("REGISTRATIONEXPIRY") + ", "
				+ "IFNULL(ODOMETER,''), "
				+ db.getSelectDate("LAST_ODOMETER_REPORTED_DATE") + ", "
				+ "IFNULL(LAST_OIL_CHANGE_MILEAGE,''), "
				+ db.getSelectDate("LAST_OIL_CHANGE_DATE") + ", "
				+ "SERVICETIER, "
				+ db.getSelectDate("RENTAL_START") + ", "
				+ db.getSelectDate("RENTAL_END") + ", "
				+ db.getSelectDaysBetween(
						dateVal, "1", "RENTAL_START", "RENTAL_END")
				+ ", PROVIDER, "
				+ db.decodeStatus(
						"OPERATIONALSTATUS", mainUtil.getOpertionalStatus())
				+ ", "
				+ db.getSelectDateFormat("RENTAL_START",
						db.ORACLE_YYYYMMDDHH24MISS)
				+ ", "
				+ db.getSelectDateFormat("RENTAL_END",
						db.ORACLE_YYYYMMDDHH24MISS)
				+ ", " + db.decodeStatus("STATUS", getVehicleStatusMap())
				+ ", IFNULL(OUT_FOR_REPAIR, 0)"
				+ ", IFNULL(REGISTRATION_PDF,'')"
				+ ", IFNULL(RO_PDF,'')"
				+ " FROM VEHICLE WHERE STATUS!=" + RecordStatus.DELETE
				+ " AND ENTITYID=" + entityID + condQry
				+ getOrderByQry(searchBean, "2");

		searchBean.setColumnSortName(searchBean.getColumnSortName()
				.replaceAll("15", "9").replaceAll("14", "8"));

		List resultList = db.selectAsList(selQry, 20);

		searchBean.setLabelsList(labelsList);
		searchBean.setDataList(resultList);
		searchBean.setSearchFiltersArray(new String[] { "Date Range",
				"Vehicle Number", "Opertional Status" });

		/* maintenance type cards for the drawer */
		ensureMaintTypes();
		Map transMap = searchBean.getTransMap() == null
				? new java.util.HashMap() : searchBean.getTransMap();
		transMap.put("maintTypes", db.selectAsList(
				"SELECT VEHICLE_MAINTENANCE_TYPEID, MAINTENANCETYPE, MAINT_CODE, "
						+ "IFNULL(MAINT_CATEGORY,''), IFNULL(ICON,'') "
						+ "FROM vehicle_maintenance_type WHERE STATUS!="
						+ RecordStatus.DELETE + " ORDER BY SORT_ORDER", 5));
		searchBean.setTransMap(transMap);
		return searchBean;
	}

	/* Self-heal: make sure the standard maintenance types exist (idempotent —
	   inserts only the ones missing, matched by MAINT_CODE). */
	private void ensureMaintTypes() {
		/* ICON kept empty on purpose — the JSP derives the FontAwesome icon from
		   the name/category, and the ICON column is a short VARCHAR. */
		String[][] defs = {
			{"Oil Change",          "OIL_CHANGE",          "Routine", "", "50"},
			{"Major Onsite Repair", "MAJOR_ONSITE_REPAIR", "Repair",  "", "100"},
			{"Major Dealer Repair", "MAJOR_DEALER_REPAIR", "Repair",  "", "110"},
			{"Tire Service",        "TIRE_SERVICE",        "Routine", "", "120"},
			{"Brake Service",       "BRAKE_SERVICE",       "Repair",  "", "130"},
			{"Inspection",          "INSPECTION",          "Routine", "", "140"},
			/* Repair extras */
			{"Battery Replacement", "BATTERY_REPLACE",     "Repair",  "", "150"},
			{"Windshield / Glass",  "WINDSHIELD_GLASS",    "Repair",  "", "160"},
			{"Diagnostic / Check Engine", "DIAGNOSTIC",    "Repair",  "", "170"},
			{"A/C Service",         "AC_SERVICE",          "Repair",  "", "180"},
			{"Electrical",          "ELECTRICAL_REPAIR",   "Repair",  "", "190"},
			{"Recall Service",      "RECALL_SERVICE",      "Repair",  "", "200"},
			{"Warranty Repair",     "WARRANTY_REPAIR",     "Repair",  "", "210"},
			/* Routine extras */
			{"Fluid Service",       "FLUID_SERVICE",       "Routine", "", "220"},
			{"Wipers & Bulbs",      "WIPERS_BULBS",        "Routine", "", "230"},
			{"Alignment",           "ALIGNMENT",           "Routine", "", "240"},
			{"Detailing / Cleaning","DETAILING",           "Routine", "", "250"},
			{"PM / Scheduled Service", "PM_SCHEDULED",     "Routine", "", "260"},
			/* Roadside (breakdown / field events) */
			{"Tow",                 "TOW",                 "Roadside", "", "270"},
			{"Jump Start / Battery Boost", "JUMP_START",   "Roadside", "", "280"},
			{"Lockout",             "LOCKOUT",             "Roadside", "", "290"},
			{"Roadside Assistance", "ROADSIDE_ASSIST",     "Roadside", "", "300"},
			{"Flat Tire",           "FLAT_TIRE",           "Roadside", "", "310"},
			{"RO",                  "RO",                  "Repair",   "", "320"}
		};
		for (int i = 0; i < defs.length; i++) {
			String[] d = defs[i];
			try {
				db.update("INSERT INTO vehicle_maintenance_type "
					+ "(MAINTENANCETYPE, MAINT_CODE, MAINT_CATEGORY, ICON, STATUS, SORT_ORDER) "
					+ "SELECT " + db.getInsertDBValue(d[0]) + ", " + db.getInsertDBValue(d[1]) + ", "
					+ db.getInsertDBValue(d[2]) + ", " + db.getInsertDBValue(d[3]) + ", "
					+ RecordStatus.ACTIVE + ", " + d[4] + " FROM DUAL "
					+ "WHERE NOT EXISTS (SELECT 1 FROM vehicle_maintenance_type WHERE MAINT_CODE="
					+ db.getInsertDBValue(d[1]) + ")");
			} catch (Exception ex) { /* type likely already present */ }
		}
	}

	private Map<String, String> getVehicleStatusMap() {
		Map<String, String> _hMap = new HashMap<String, String>();
		_hMap.put(RecordStatus.ACTIVE + "", "Active");
		_hMap.put(RecordStatus.INACTIVE + "", "Inactive");
		return _hMap;
	}

	/* requestMap values arrive with apostrophes doubled; the deployed
	   getInsertDBValue escapes again, so undo the doubling first */
	private String rq(Map<String, String> requestMap, String key) {
		String v = requestMap.get(key) == null ? "" : requestMap.get(key).trim();
		return v.replace("''", "'");
	}

	private String jsEsc(String s) {
		if (s == null) return "";
		StringBuilder b = new StringBuilder();
		for (int i = 0; i < s.length(); i++) {
			char c = s.charAt(i);
			if (c == '"') b.append("\\\"");
			else if (c == '\\') b.append("\\\\");
			else if (c == '\n' || c == '\r') b.append(' ');
			else if (c == '<') b.append("\\u003C");
			else if (c >= 32) b.append(c);
		}
		return b.toString();
	}

	private int parseIntSafe(String s) {
		try {
			return Integer.parseInt(s == null || s.length() == 0 ? "0" : s.trim());
		} catch (Exception e) {
			return 0;
		}
	}

	/** Save maint doc under docs/RegistrationForms/... (View links).
	 *  On UAT also copy to F:\JavProject\serverUpload\RegistrationForms\... */
	private String saveVehicleMaintDoc(String vehicleId, String entityID,
			String loginUser, String subFolder, String saveNameBase,
			String base64, String fileName) {
		if (vehicleId == null || !vehicleId.matches("\\d+")) return null;
		if (saveNameBase == null || saveNameBase.trim().length() == 0) return null;
		if (base64 == null || base64.length() == 0) return null;
		String folder = (subFolder == null || subFolder.trim().length() == 0)
				? "Docs" : subFolder.trim().replaceAll("[^A-Za-z0-9_-]", "");
		String fn = fileName == null || fileName.length() == 0
				? "Document.pdf" : fileName;
		String lower = fn.toLowerCase();
		if (!(lower.endsWith(".pdf") || lower.endsWith(".png")
				|| lower.endsWith(".jpg") || lower.endsWith(".jpeg")))
			return null;
		int comma = base64.indexOf(',');
		if (base64.startsWith("data:") && comma > 0)
			base64 = base64.substring(comma + 1);
		try {
			String ext = lower.substring(lower.lastIndexOf('.'));
			String saveName = saveNameBase.replaceAll("[^A-Za-z0-9_-]", "_") + ext;

			String docsRoot = ApplicationConfig.getDocsPath();
			if (docsRoot == null || docsRoot.length() == 0)
				docsRoot = ApplicationConfig.getApplicationPath()
						+ File.separator + "docs";
			String stableFolder = docsRoot + File.separator + "RegistrationForms"
					+ File.separator + vehicleId + File.separator + folder;
			Object[] stable = new FileUpload().uploadBase64File(base64,
					saveName, stableFolder);
			if (!((Boolean) stable[0]).booleanValue()) return null;

			/* UAT: also store under F:\JavProject\serverUpload */
			if (ServerUploadPaths.isUatServerUpload()) {
				try {
					String uatFolder = ServerUploadPaths.getRegistrationForms()
							+ File.separator + vehicleId + File.separator + folder;
					new FileUpload().uploadBase64File(base64, saveName, uatFolder);
				} catch (Exception ignore) { }
			}

			try {
				String archiveFolder = fileUtility.getFolderPath("create",
						"RegistrationForms", loginUser) + File.separator + folder;
				new File(archiveFolder).mkdirs();
				new FileUpload().uploadBase64File(base64, saveName, archiveFolder);
			} catch (Exception ignore) { }

			return "docs/RegistrationForms/" + vehicleId + "/" + folder + "/"
					+ saveName;
		} catch (Exception ex) {
			return null;
		}
	}

	/** Save RO PDF under docs/RegistrationForms/{vehicleId}/RO/{Vehicle#}_{ROnumber}.pdf */
	private String saveVehicleRoPdf(String vehicleId, String entityID,
			String loginUser, String roNum, String base64, String fileName) {
		if (vehicleId == null || !vehicleId.matches("\\d+")) return null;
		if (roNum == null || roNum.trim().length() == 0) return null;
		try {
			List v = db.selectAsList(
					"SELECT IFNULL(VEHICLENUMBER,'') FROM VEHICLE WHERE VEHICLEID="
					+ vehicleId + " AND ENTITYID=" + entityID
					+ " AND STATUS!=" + RecordStatus.DELETE, 1);
			if (v.isEmpty()) return null;
			List vt = (List) v.get(0);
			String vehNum = vt.get(0) == null ? "" : vt.get(0).toString().trim();
			String safeNum = vehNum.replaceAll("[^A-Za-z0-9_-]", "_");
			if (safeNum.length() == 0) safeNum = "Vehicle" + vehicleId;
			String safeRo = roNum.trim().replaceAll("[^A-Za-z0-9_-]", "_");
			if (safeRo.length() == 0) safeRo = "RO";
			return saveVehicleMaintDoc(vehicleId, entityID, loginUser, "RO",
					safeNum + "_" + safeRo, base64, fileName);
		} catch (Exception ex) {
			return null;
		}
	}

	private String saveVehicleOilPdf(String vehicleId, String entityID,
			String loginUser, String svcDate, String base64, String fileName) {
		if (vehicleId == null || !vehicleId.matches("\\d+")) return null;
		try {
			List v = db.selectAsList(
					"SELECT IFNULL(VEHICLENUMBER,'') FROM VEHICLE WHERE VEHICLEID="
					+ vehicleId + " AND ENTITYID=" + entityID
					+ " AND STATUS!=" + RecordStatus.DELETE, 1);
			if (v.isEmpty()) return null;
			List vt = (List) v.get(0);
			String vehNum = vt.get(0) == null ? "" : vt.get(0).toString().trim();
			String safeNum = vehNum.replaceAll("[^A-Za-z0-9_-]", "_");
			if (safeNum.length() == 0) safeNum = "Vehicle" + vehicleId;
			String day = (svcDate == null ? "" : svcDate.trim())
					.replaceAll("[^0-9]", "");
			if (day.length() == 0)
				day = String.valueOf(System.currentTimeMillis());
			return saveVehicleMaintDoc(vehicleId, entityID, loginUser, "OilChange",
					safeNum + "_OilChange_" + day, base64, fileName);
		} catch (Exception ex) {
			return null;
		}
	}

	private String latestMaintLogId(String vehicleId) {
		try {
			List r = db.selectAsList(
					"SELECT MAX(MAINT_LOGID) FROM VEHICLE_MAINTENANCE_LOG WHERE VEHICLEID="
					+ vehicleId, 1);
			if (r.isEmpty()) return "";
			return getListData((List) r.get(0), 0);
		} catch (Exception e) {
			return "";
		}
	}

	private void patchMaintLogDocs(String logId, String vehicleId,
			String loginUser, String roDate, String roPath, String oilPath) {
		if (logId == null || !logId.matches("\\d+")) return;
		try {
			StringBuilder sql = new StringBuilder(
					"UPDATE VEHICLE_MAINTENANCE_LOG SET ");
			boolean any = false;
			if (roDate != null && roDate.trim().length() > 0) {
				sql.append("RO_DATE=").append(db.getInsertDate(roDate.trim()));
				any = true;
			}
			if (roPath != null && roPath.length() > 0) {
				if (any) sql.append(", ");
				sql.append("RO_PDF=").append(db.getInsertDBValue(roPath));
				any = true;
			}
			if (oilPath != null && oilPath.length() > 0) {
				if (any) sql.append(", ");
				sql.append("OIL_PDF=").append(db.getInsertDBValue(oilPath));
				any = true;
			}
			/* DOC_PDF = primary attachment for history (prefer RO, else oil) */
			String doc = (roPath != null && roPath.length() > 0) ? roPath
					: ((oilPath != null && oilPath.length() > 0) ? oilPath : "");
			if (doc.length() > 0) {
				if (any) sql.append(", ");
				sql.append("DOC_PDF=").append(db.getInsertDBValue(doc));
				any = true;
			}
			if (!any) return;
			sql.append(", UPDATE_USER=").append(db.getInsertDBValue(loginUser))
					.append(", UPDATE_DATE=").append(db.getInsertSysdate())
					.append(" WHERE MAINT_LOGID=").append(logId)
					.append(" AND VEHICLEID=").append(vehicleId);
			db.update(sql.toString());
		} catch (Exception ignore) { }
	}

	private void updateVehicleLatestRo(String vehicleId, String entityID,
			String loginUser, String roNum, String roDate, String relPath) {
		if (vehicleId == null || !vehicleId.matches("\\d+")) return;
		try {
			StringBuilder sql = new StringBuilder("UPDATE VEHICLE SET ");
			boolean any = false;
			if (roNum != null && roNum.trim().length() > 0) {
				sql.append("RO_NUMBER=").append(db.getInsertDBValue(roNum.trim()));
				any = true;
			}
			if (roDate != null && roDate.trim().length() > 0) {
				if (any) sql.append(", ");
				sql.append("RO_DATE=").append(db.getInsertDate(roDate.trim()));
				any = true;
			}
			if (relPath != null && relPath.length() > 0) {
				if (any) sql.append(", ");
				sql.append("RO_PDF=").append(db.getInsertDBValue(relPath));
				any = true;
			}
			if (!any) return;
			sql.append(", UPDATE_USER=").append(db.getInsertDBValue(loginUser))
					.append(", UPDATE_DATE=").append(db.getInsertSysdate())
					.append(" WHERE VEHICLEID=").append(vehicleId)
					.append(" AND ENTITYID=").append(entityID)
					.append(" AND STATUS!=").append(RecordStatus.DELETE);
			db.update(sql.toString());
		} catch (Exception ignore) { }
	}

	private void addVehicleTransNote(String recordID, String note,
			String loginUser, List<String> upList) throws Exception {
		String transID = db.getNextIDValue("VEHICLETRANSID");
		upList.add("INSERT INTO VEHICLETRANS (VEHICLETRANSID, VEHICLEID, "
				+ "COMMENTS, CREATE_USER, CREATE_DATE, STATUS) VALUES ("
				+ transID + ", " + recordID + ", " + db.getInsertDBValue(note)
				+ ", " + db.getInsertDBValue(loginUser) + ", "
				+ db.getInsertSysdate() + ", " + RecordStatus.ACTIVE + ")");
	}

	@Override
	public String getAjaxRequestTypeResp(String requestType,
			Map<String, String> requestMap, String loginUser,
			String loginUserRoles, String loginUserID, String entityID)
			throws Exception {

		String recordID = requestMap.get("recordID") == null ? ""
				: requestMap.get("recordID").trim();

		if ("repairToggle".equalsIgnoreCase(requestType)) {
			String to = requestMap.get("to") == null ? ""
					: requestMap.get("to").trim();
			if (!recordID.matches("\\d+") || !to.matches("[01]"))
				return "<status>false</status><mesg>Bad request</mesg>";

			List<String> upList = new ArrayList<String>();
			upList.add("UPDATE VEHICLE SET OUT_FOR_REPAIR=" + to
					+ ", UPDATE_USER=" + db.getInsertDBValue(loginUser)
					+ ", UPDATE_DATE=" + db.getInsertSysdate()
					+ " WHERE VEHICLEID=" + recordID + " AND ENTITYID=" + entityID
					+ " AND STATUS!=" + RecordStatus.DELETE);
			addVehicleTransNote(recordID, "1".equals(to)
					? "Marked out for repair" : "Back from repair", loginUser,
					upList);
			boolean result = db.batchInsert(upList);

			if (!result)
				return "<status>false</status><mesg>Update failed</mesg>";
			return "<status>true</status><mesg>Vehicle marked "
					+ ("1".equals(to) ? "out for repair" : "back from repair")
					+ "</mesg>";
		}

		if ("vehGet".equalsIgnoreCase(requestType)) {
			if (!recordID.matches("\\d+"))
				return "<status>false</status><mesg>Bad request</mesg>";
			List r = db.selectAsList("SELECT VEHICLENUMBER, VINNUMBER, "
					+ "IFNULL(VEHICLETYPE,''), IFNULL(LICENSEPLATE,''), "
					+ "IFNULL(DATE_FORMAT(REGISTRATIONEXPIRY,'%m/%d/%Y'),''), "
					+ "IFNULL(REGISTEREDSTATE,''), IFNULL(SERVICETIER,''), "
					+ "IFNULL(OPERATIONALSTATUS,0), "
					+ "IFNULL(DATE_FORMAT(RENTAL_START,'%m/%d/%Y'),''), "
					+ "IFNULL(DATE_FORMAT(RENTAL_END,'%m/%d/%Y'),''), "
					+ "IFNULL(OUT_FOR_REPAIR,0), IFNULL(PROVIDER,''), "
					+ "IFNULL(ODOMETER,''), "
					+ "IFNULL(DATE_FORMAT(LAST_ODOMETER_REPORTED_DATE,'%m/%d/%Y'),''), "
					+ "IFNULL(LAST_OIL_CHANGE_MILEAGE,''), "
					+ "IFNULL(DATE_FORMAT(LAST_OIL_CHANGE_DATE,'%m/%d/%Y'),'') "
					+ "FROM VEHICLE WHERE VEHICLEID=" + recordID
					+ " AND ENTITYID=" + entityID + " AND STATUS!="
					+ RecordStatus.DELETE, 16);
			if (r.isEmpty())
				return "<status>false</status><mesg>Vehicle not found</mesg>";
			List t = (List) r.get(0);
			String[] keys = { "num", "vin", "type", "plate", "regExp", "state",
					"tier", "op", "rentS", "rentE", "rep", "prov",
					"odometer", "odoDate", "oilMileage", "oilDate" };
			StringBuilder o = new StringBuilder("{");
			for (int i = 0; i < keys.length; i++)
				o.append(i > 0 ? "," : "").append("\"").append(keys[i])
						.append("\":\"").append(jsEsc(getListData(t, i)))
						.append("\"");
			return o.append("}").toString();
		}

		if ("vehHistory".equalsIgnoreCase(requestType)) {
			if (!recordID.matches("\\d+"))
				return "<status>false</status><mesg>Bad request</mesg>";
			ensureVehicleMetricColumns();
			/* maintenance records (editable while open) + the notes trail */
			List r;
			String[] rk;
			try {
				r = db.selectAsList("SELECT L.MAINT_LOGID, "
						+ "IFNULL(DATE_FORMAT(L.SERVICE_DATE,'%m/%d/%Y'),''), "
						+ "IFNULL(T.MAINTENANCETYPE, IFNULL(L.MAINT_CODE,'')), "
						+ "IFNULL(T.ICON,''), IFNULL(L.MAINT_CATEGORY,''), "
						+ "IFNULL(L.SHOP_VENDOR,''), IFNULL(L.INVOICE_NUMBER,''), "
						+ "IFNULL(L.PARTS_REPLACED,''), IFNULL(L.DESCRIPTION,''), "
						+ "IFNULL(L.IS_OPEN,0), "
						+ "IFNULL(DATE_FORMAT(L.COMPLETED_DATE,'%m/%d/%Y'),''), "
						+ "IFNULL(DATE_FORMAT(L.NEXT_SERVICE_DATE,'%m/%d/%Y'),''), "
						+ "IFNULL(DATE_FORMAT(L.FOLLOWUP_DATE,'%m/%d/%Y'),''), "
						+ "IFNULL(L.FOLLOWUP_ASSIGNED_TO,''), IFNULL(L.REMINDER_DAYS,''), "
						+ "IFNULL(L.MAINT_TYPEID,''), IFNULL(L.MAINT_CODE,''), "
						+ "IFNULL(L.RO_PDF,''), IFNULL(L.OIL_PDF,''), "
						+ "IFNULL(L.DOC_PDF,''), "
						+ "IFNULL(DATE_FORMAT(L.RO_DATE,'%m/%d/%Y'),'') "
						+ "FROM vehicle_maintenance_log L "
						+ "LEFT JOIN vehicle_maintenance_type T "
						+ "ON T.VEHICLE_MAINTENANCE_TYPEID=L.MAINT_TYPEID "
						+ "WHERE L.VEHICLEID=" + recordID + " AND L.STATUS!="
						+ RecordStatus.DELETE
						+ " ORDER BY L.IS_OPEN DESC, L.MAINT_LOGID DESC LIMIT 60", 21);
				rk = new String[] { "id", "d", "ty", "ic", "cat", "shop", "ro", "parts",
						"m", "open", "done", "nextSvc", "followUp", "asg", "days",
						"tid", "code", "roPdf", "oilPdf", "docPdf", "roDate" };
			} catch (Exception hxEx) {
				r = db.selectAsList("SELECT L.MAINT_LOGID, "
						+ "IFNULL(DATE_FORMAT(L.SERVICE_DATE,'%m/%d/%Y'),''), "
						+ "IFNULL(T.MAINTENANCETYPE, IFNULL(L.MAINT_CODE,'')), "
						+ "IFNULL(T.ICON,''), IFNULL(L.MAINT_CATEGORY,''), "
						+ "IFNULL(L.SHOP_VENDOR,''), IFNULL(L.INVOICE_NUMBER,''), "
						+ "IFNULL(L.PARTS_REPLACED,''), IFNULL(L.DESCRIPTION,''), "
						+ "IFNULL(L.IS_OPEN,0), "
						+ "IFNULL(DATE_FORMAT(L.COMPLETED_DATE,'%m/%d/%Y'),''), "
						+ "IFNULL(DATE_FORMAT(L.NEXT_SERVICE_DATE,'%m/%d/%Y'),''), "
						+ "IFNULL(DATE_FORMAT(L.FOLLOWUP_DATE,'%m/%d/%Y'),''), "
						+ "IFNULL(L.FOLLOWUP_ASSIGNED_TO,''), IFNULL(L.REMINDER_DAYS,''), "
						+ "IFNULL(L.MAINT_TYPEID,''), IFNULL(L.MAINT_CODE,'') "
						+ "FROM vehicle_maintenance_log L "
						+ "LEFT JOIN vehicle_maintenance_type T "
						+ "ON T.VEHICLE_MAINTENANCE_TYPEID=L.MAINT_TYPEID "
						+ "WHERE L.VEHICLEID=" + recordID + " AND L.STATUS!="
						+ RecordStatus.DELETE
						+ " ORDER BY L.IS_OPEN DESC, L.MAINT_LOGID DESC LIMIT 60", 17);
				rk = new String[] { "id", "d", "ty", "ic", "cat", "shop", "ro", "parts",
						"m", "open", "done", "nextSvc", "followUp", "asg", "days",
						"tid", "code" };
			}
			StringBuilder o = new StringBuilder("{\"recs\":[");
			for (int i = 0; i < r.size(); i++) {
				List t = (List) r.get(i);
				o.append(i > 0 ? "," : "").append("{");
				for (int j = 0; j < rk.length; j++)
					o.append(j > 0 ? "," : "").append("\"").append(rk[j])
							.append("\":\"").append(jsEsc(getListData(t, j)))
							.append("\"");
				o.append("}");
			}
			o.append("],\"notes\":[");
			r = db.selectAsList("SELECT DATE_FORMAT(CREATE_DATE,'%m/%d/%Y %l:%i %p'), "
					+ "IFNULL(CREATE_USER,''), IFNULL(COMMENTS,'') "
					+ "FROM VEHICLETRANS WHERE VEHICLEID=" + recordID
					+ " AND STATUS!=" + RecordStatus.DELETE
					+ " ORDER BY VEHICLETRANSID DESC LIMIT 50", 3);
			for (int i = 0; i < r.size(); i++) {
				List t = (List) r.get(i);
				o.append(i > 0 ? "," : "").append("{\"d\":\"")
						.append(jsEsc(getListData(t, 0))).append("\",\"u\":\"")
						.append(jsEsc(getListData(t, 1))).append("\",\"m\":\"")
						.append(jsEsc(getListData(t, 2))).append("\"}");
			}
			String regPdf = "";
			String vehRoPdf = "";
			try {
				List vp = db.selectAsList(
						"SELECT IFNULL(REGISTRATION_PDF,''), IFNULL(RO_PDF,'') "
						+ "FROM VEHICLE WHERE VEHICLEID=" + recordID
						+ " AND ENTITYID=" + entityID + " AND STATUS!="
						+ RecordStatus.DELETE + " LIMIT 1", 2);
				if (!vp.isEmpty()) {
					List vt = (List) vp.get(0);
					regPdf = getListData(vt, 0);
					vehRoPdf = getListData(vt, 1);
				}
			} catch (Exception ignore) { }
			return o.append("],\"regPdf\":\"").append(jsEsc(regPdf))
					.append("\",\"roPdf\":\"").append(jsEsc(vehRoPdf))
					.append("\"}").toString();
		}

		if ("vehDispatchers".equalsIgnoreCase(requestType)) {
			/* full dispatcher/lead roster for Assigned-to typeahead */
			List r = db.selectAsList("SELECT U.USERNAME, "
					+ "IFNULL(NULLIF(TRIM(E.FULLNAME),''), U.USERNAME) "
					+ "FROM entityusers U JOIN employee E ON U.EMPLOYEEID=E.EMPLOYEEID "
					+ "WHERE U.STATUS=" + RecordStatus.ACTIVE
					+ " AND E.STATUS!=" + RecordStatus.DELETE
					+ " AND E.ROLE IN (1,3) "
					+ "ORDER BY 2, 1", 2);
			java.util.LinkedHashMap<String, String> map =
					new java.util.LinkedHashMap<String, String>();
			for (int i = 0; i < r.size(); i++) {
				List t = (List) r.get(i);
				String user = getListData(t, 0);
				String nm = getListData(t, 1);
				if (user.length() == 0) continue;
				if (nm.length() == 0) nm = user;
				map.put(user, nm);
			}
			/* always include the logged-in user even if role filter missed them */
			if (loginUser != null && loginUser.trim().length() > 0
					&& !map.containsKey(loginUser.trim())) {
				String dn = loginUser.trim();
				List me = db.selectAsList("SELECT IFNULL(NULLIF(TRIM(E.FULLNAME),''), U.USERNAME) "
						+ "FROM entityusers U JOIN employee E ON U.EMPLOYEEID=E.EMPLOYEEID "
						+ "WHERE U.USERNAME=" + db.getInsertDBValue(loginUser.trim())
						+ " LIMIT 1", 1);
				if (!me.isEmpty())
					dn = getListData((List) me.get(0), 0);
				map.put(loginUser.trim(), dn);
			}
			StringBuilder o = new StringBuilder("[");
			int n = 0;
			for (java.util.Map.Entry<String, String> e : map.entrySet()) {
				o.append(n++ > 0 ? "," : "").append("{\"id\":\"")
						.append(jsEsc(e.getKey())).append("\",\"nm\":\"")
						.append(jsEsc(e.getValue())).append("\"}");
			}
			return o.append("]").toString();
		}

		if ("vehMaint".equalsIgnoreCase(requestType)) {
			if (!recordID.matches("\\d+"))
				return "<status>false</status><mesg>Bad request</mesg>";
			ensureVehicleMetricColumns();
			String mType = rq(requestMap, "mType");
			String mCat = rq(requestMap, "mCat");
			String svcDate = rq(requestMap, "svcDate");
			if (mType.length() == 0)
				return "<status>false</status><mesg>Pick a maintenance type</mesg>";
			if (svcDate.length() == 0)
				return "<status>false</status><mesg>Service date is required</mesg>";
			String vehSt = rq(requestMap, "vehSt");
			String oilDays = rq(requestMap, "oilDays");
			if (!oilDays.matches("\\d+")) oilDays = "";

			String mTypeId = rq(requestMap, "mTypeId");
			if (!mTypeId.matches("\\d+")) mTypeId = "";
			String mCode = rq(requestMap, "mCode");
			String jobSt = rq(requestMap, "jobSt");
			boolean open = !"Completed".equalsIgnoreCase(jobSt);
			String stBefore = getTableColumnData("OPERATIONALSTATUS", "VEHICLE",
					"VEHICLEID", recordID);
			String stAfter = "Grounded".equalsIgnoreCase(vehSt) ? "1"
					: ("Operational".equalsIgnoreCase(vehSt) ? "0" : stBefore);

			List<String> upList = new ArrayList<String>();
			String insQry = "INSERT INTO VEHICLE_MAINTENANCE_LOG (VEHICLEID, ENTITYID, "
					+ "MAINT_TYPEID, MAINT_CODE, MAINT_CATEGORY, SERVICE_DATE, "
					+ (open ? "" : "COMPLETED_DATE, ")
					+ "SHOP_VENDOR, INVOICE_NUMBER, PARTS_REPLACED, DESCRIPTION, "
					+ "STATUS_BEFORE, STATUS_AFTER, IS_OPEN, NEXT_SERVICE_DATE, "
					+ "FOLLOWUP_DATE, FOLLOWUP_ASSIGNED_TO, REMINDER_DAYS, "
					+ "CREATE_USER, CREATE_DATE, STATUS) VALUES ("
					+ recordID + ", " + entityID + ", "
					+ (mTypeId.length() > 0 ? mTypeId : "NULL") + ", "
					+ db.getInsertDBValue(mCode) + ", "
					+ db.getInsertDBValue(mCat) + ", "
					+ db.getInsertDate(svcDate) + ", "
					+ (open ? "" : db.getInsertSysdate() + ", ")
					+ db.getInsertDBValue(rq(requestMap, "shop")) + ", "
					+ db.getInsertDBValue(rq(requestMap, "roNum")) + ", "
					+ db.getInsertDBValue(rq(requestMap, "parts")) + ", "
					+ db.getInsertDBValue(rq(requestMap, "notes")) + ", "
					+ (stBefore.length() > 0 ? stBefore : "NULL") + ", "
					+ (stAfter.length() > 0 ? stAfter : "NULL") + ", "
					+ (open ? "1" : "0") + ", "
					+ db.getInsertDate(rq(requestMap, "nextSvc")) + ", "
					+ db.getInsertDate(rq(requestMap, "followUp")) + ", "
					+ db.getInsertDBValue(rq(requestMap, "assigned")) + ", "
					+ (oilDays.length() > 0 ? oilDays : "30") + ", "
					+ db.getInsertDBValue(loginUser) + ", " + db.getInsertSysdate()
					+ ", " + RecordStatus.ACTIVE + ")";
			upList.add(insQry);

			/* the form's Vehicle status choice also moves the van itself */
			if ("Grounded".equalsIgnoreCase(vehSt))
				upList.add("UPDATE VEHICLE SET OPERATIONALSTATUS=1, UPDATE_USER="
						+ db.getInsertDBValue(loginUser) + ", UPDATE_DATE="
						+ db.getInsertSysdate() + " WHERE VEHICLEID=" + recordID
						+ " AND ENTITYID=" + entityID);
			else if ("Operational".equalsIgnoreCase(vehSt))
				upList.add("UPDATE VEHICLE SET OPERATIONALSTATUS=0, UPDATE_USER="
						+ db.getInsertDBValue(loginUser) + ", UPDATE_DATE="
						+ db.getInsertSysdate() + " WHERE VEHICLEID=" + recordID
						+ " AND ENTITYID=" + entityID);

			/* summary note keeps the Hx drawer a single trail */
			StringBuilder note = new StringBuilder("MAINTENANCE - " + mType
					+ " - " + svcDate);
			String shop = rq(requestMap, "shop");
			String ro = rq(requestMap, "roNum");
			if (shop.length() > 0) note.append(" - ").append(shop);
			if (ro.length() > 0) note.append(" - RO# ").append(ro);
			String nts = rq(requestMap, "notes");
			if (nts.length() > 0) note.append(" - ").append(nts);
			addVehicleTransNote(recordID, note.toString(), loginUser, upList);

			boolean result = db.batchInsert(upList);
			if (!result)
				return "<status>false</status><mesg>Save failed</mesg>";

			String logId = latestMaintLogId(recordID);
			String roNum = rq(requestMap, "roNum");
			String roDate = rq(requestMap, "roDate");
			String roPath = "";
			String oilPath = "";
			String warn = "";
			String roB64 = rq(requestMap, "roBase64");
			String oilB64 = rq(requestMap, "oilBase64");
			if (roB64.length() > 0) {
				if (roNum.length() == 0) {
					warn = "RO document skipped (enter RO number)";
				} else {
					roPath = saveVehicleRoPdf(recordID, entityID, loginUser, roNum,
							roB64, rq(requestMap, "roFileName"));
					if (roPath == null || roPath.length() == 0)
						warn = (warn.length() > 0 ? warn + "; " : "")
								+ "RO upload failed";
				}
			}
			if (oilB64.length() > 0) {
				oilPath = saveVehicleOilPdf(recordID, entityID, loginUser, svcDate,
						oilB64, rq(requestMap, "oilFileName"));
				if (oilPath == null || oilPath.length() == 0)
					warn = (warn.length() > 0 ? warn + "; " : "")
							+ "Oil document upload failed";
			}
			if (roNum.length() > 0 || roDate.length() > 0 || roPath.length() > 0)
				updateVehicleLatestRo(recordID, entityID, loginUser, roNum, roDate, roPath);
			patchMaintLogDocs(logId, recordID, loginUser, roDate, roPath, oilPath);

			String mesg = "Maintenance logged";
			if (roPath.length() > 0) mesg += " (RO saved)";
			if (oilPath.length() > 0) mesg += " (Oil doc saved)";
			if (warn.length() > 0) mesg += " — " + warn;
			return "<status>true</status><mesg>" + mesg + "</mesg>"
					+ (roPath.length() > 0 ? ("<ropath>" + roPath.replace("<","") + "</ropath>") : "")
					+ (oilPath.length() > 0 ? ("<oilpath>" + oilPath.replace("<","") + "</oilpath>") : "");
		}

		if ("vehMaintUpd".equalsIgnoreCase(requestType)) {
			String logID = requestMap.get("logID") == null ? ""
					: requestMap.get("logID").trim();
			if (!recordID.matches("\\d+") || !logID.matches("\\d+"))
				return "<status>false</status><mesg>Bad request</mesg>";
			String isOpen = getTableColumnData("IS_OPEN",
					"VEHICLE_MAINTENANCE_LOG", "MAINT_LOGID", logID);
			if (!"1".equals(isOpen))
				return "<status>false</status><mesg>Completed jobs cannot be "
						+ "changed</mesg>";

			String mType = rq(requestMap, "mType");
			String svcDate = rq(requestMap, "svcDate");
			if (mType.length() == 0)
				return "<status>false</status><mesg>Pick a maintenance type</mesg>";
			if (svcDate.length() == 0)
				return "<status>false</status><mesg>Service date is required</mesg>";
			String mTypeId = rq(requestMap, "mTypeId");
			if (!mTypeId.matches("\\d+")) mTypeId = "";
			String oilDays = rq(requestMap, "oilDays");
			if (!oilDays.matches("\\d+")) oilDays = "";
			String jobSt = rq(requestMap, "jobSt");
			boolean open = !"Completed".equalsIgnoreCase(jobSt);
			String vehSt = rq(requestMap, "vehSt");

			List<String> upList = new ArrayList<String>();
			upList.add("UPDATE VEHICLE_MAINTENANCE_LOG SET MAINT_TYPEID="
					+ (mTypeId.length() > 0 ? mTypeId : "NULL")
					+ ", MAINT_CODE=" + db.getInsertDBValue(rq(requestMap, "mCode"))
					+ ", MAINT_CATEGORY=" + db.getInsertDBValue(rq(requestMap, "mCat"))
					+ ", SERVICE_DATE=" + db.getInsertDate(svcDate)
					+ ", SHOP_VENDOR=" + db.getInsertDBValue(rq(requestMap, "shop"))
					+ ", INVOICE_NUMBER=" + db.getInsertDBValue(rq(requestMap, "roNum"))
					+ ", PARTS_REPLACED=" + db.getInsertDBValue(rq(requestMap, "parts"))
					+ ", DESCRIPTION=" + db.getInsertDBValue(rq(requestMap, "notes"))
					+ ", NEXT_SERVICE_DATE=" + db.getInsertDate(rq(requestMap, "nextSvc"))
					+ ", FOLLOWUP_DATE=" + db.getInsertDate(rq(requestMap, "followUp"))
					+ ", FOLLOWUP_ASSIGNED_TO=" + db.getInsertDBValue(rq(requestMap, "assigned"))
					+ ", REMINDER_DAYS=" + (oilDays.length() > 0 ? oilDays : "30")
					+ ", IS_OPEN=" + (open ? "1" : "0")
					+ ", COMPLETED_DATE=" + (open ? "NULL" : db.getInsertSysdate())
					+ ", UPDATE_USER=" + db.getInsertDBValue(loginUser)
					+ ", UPDATE_DATE=" + db.getInsertSysdate()
					+ " WHERE MAINT_LOGID=" + logID + " AND VEHICLEID=" + recordID
					+ " AND IS_OPEN=1 AND STATUS!=" + RecordStatus.DELETE);

			if ("Grounded".equalsIgnoreCase(vehSt))
				upList.add("UPDATE VEHICLE SET OPERATIONALSTATUS=1, UPDATE_USER="
						+ db.getInsertDBValue(loginUser) + ", UPDATE_DATE="
						+ db.getInsertSysdate() + " WHERE VEHICLEID=" + recordID
						+ " AND ENTITYID=" + entityID);
			else if ("Operational".equalsIgnoreCase(vehSt))
				upList.add("UPDATE VEHICLE SET OPERATIONALSTATUS=0, UPDATE_USER="
						+ db.getInsertDBValue(loginUser) + ", UPDATE_DATE="
						+ db.getInsertSysdate() + " WHERE VEHICLEID=" + recordID
						+ " AND ENTITYID=" + entityID);

			if (!open)
				addVehicleTransNote(recordID, "MAINTENANCE COMPLETED - " + mType
						+ (rq(requestMap, "shop").length() > 0
								? " - " + rq(requestMap, "shop") : ""),
						loginUser, upList);

			boolean result = db.batchInsert(upList);
			if (!result)
				return "<status>false</status><mesg>Update failed</mesg>";
			ensureVehicleMetricColumns();
			String roNum = rq(requestMap, "roNum");
			String roDate = rq(requestMap, "roDate");
			String roPath = "";
			String oilPath = "";
			String warn = "";
			String roB64 = rq(requestMap, "roBase64");
			String oilB64 = rq(requestMap, "oilBase64");
			if (roB64.length() > 0) {
				if (roNum.length() == 0) {
					warn = "RO document skipped (enter RO number)";
				} else {
					roPath = saveVehicleRoPdf(recordID, entityID, loginUser, roNum,
							roB64, rq(requestMap, "roFileName"));
					if (roPath == null || roPath.length() == 0)
						warn = (warn.length() > 0 ? warn + "; " : "")
								+ "RO upload failed";
				}
			}
			if (oilB64.length() > 0) {
				oilPath = saveVehicleOilPdf(recordID, entityID, loginUser, svcDate,
						oilB64, rq(requestMap, "oilFileName"));
				if (oilPath == null || oilPath.length() == 0)
					warn = (warn.length() > 0 ? warn + "; " : "")
							+ "Oil document upload failed";
			}
			if (roNum.length() > 0 || roDate.length() > 0 || roPath.length() > 0)
				updateVehicleLatestRo(recordID, entityID, loginUser, roNum, roDate, roPath);
			patchMaintLogDocs(logID, recordID, loginUser, roDate, roPath, oilPath);
			String mesg = "Maintenance " + (open ? "updated" : "completed");
			if (roPath.length() > 0) mesg += " (RO saved)";
			if (oilPath.length() > 0) mesg += " (Oil doc saved)";
			if (warn.length() > 0) mesg += " — " + warn;
			return "<status>true</status><mesg>" + mesg + "</mesg>"
					+ (roPath.length() > 0 ? ("<ropath>" + roPath.replace("<","") + "</ropath>") : "")
					+ (oilPath.length() > 0 ? ("<oilpath>" + oilPath.replace("<","") + "</oilpath>") : "");
		}

		if ("vehShops".equalsIgnoreCase(requestType)) {
			/* previously used shops feed the Shop dropdown */
			List r = db.selectAsList("SELECT DISTINCT SHOP_VENDOR FROM VEHICLE_MAINTENANCE_LOG "
					+ "WHERE ENTITYID=" + entityID + " AND STATUS!=" + RecordStatus.DELETE
					+ " AND SHOP_VENDOR IS NOT NULL AND SHOP_VENDOR!='' ORDER BY SHOP_VENDOR LIMIT 40", 1);
			StringBuilder o = new StringBuilder("[");
			for (int i = 0; i < r.size(); i++)
				o.append(i > 0 ? "," : "").append("\"")
						.append(jsEsc(getListData((List) r.get(i), 0))).append("\"");
			return o.append("]").toString();
		}

		/* ── Fleet Task Board (Phase 1): open maint logs + OFR/grounded KPIs ── */
		if ("fleetBoardList".equalsIgnoreCase(requestType)) {
			ensureOutForRepairColumn();
			int kpiOpen = 0, kpiOfr = 0, kpiGr = 0, kpiOver = 0, kpiHanded = 0;
			List k = db.selectAsList("SELECT "
					+ "(SELECT COUNT(*) FROM vehicle_maintenance_log L "
					+ " WHERE L.ENTITYID=" + entityID + " AND L.IS_OPEN=1 "
					+ " AND L.STATUS!=" + RecordStatus.DELETE + "), "
					+ "(SELECT COUNT(*) FROM VEHICLE V WHERE V.ENTITYID=" + entityID
					+ " AND V.STATUS!=" + RecordStatus.DELETE
					+ " AND IFNULL(V.OUT_FOR_REPAIR,0)=1), "
					+ "(SELECT COUNT(*) FROM VEHICLE V WHERE V.ENTITYID=" + entityID
					+ " AND V.STATUS!=" + RecordStatus.DELETE
					+ " AND IFNULL(V.OPERATIONALSTATUS,0)=1)", 3);
			if (!k.isEmpty()) {
				List kt = (List) k.get(0);
				kpiOpen = parseIntSafe(getListData(kt, 0));
				kpiOfr = parseIntSafe(getListData(kt, 1));
				kpiGr = parseIntSafe(getListData(kt, 2));
			}

			List r = db.selectAsList("SELECT L.MAINT_LOGID, L.VEHICLEID, "
					+ "IFNULL(V.VEHICLENUMBER,''), IFNULL(V.VINNUMBER,''), "
					+ "IFNULL(T.MAINTENANCETYPE, IFNULL(L.MAINT_CODE,'Maintenance')), "
					+ "IFNULL(L.MAINT_CATEGORY,''), IFNULL(L.SHOP_VENDOR,''), "
					+ "IFNULL(L.FOLLOWUP_ASSIGNED_TO,''), "
					+ "IFNULL(DATE_FORMAT(L.FOLLOWUP_DATE,'%m/%d/%Y'),''), "
					+ "IFNULL(DATE_FORMAT(L.SERVICE_DATE,'%m/%d/%Y'),''), "
					+ "IFNULL(L.DESCRIPTION,''), IFNULL(L.INVOICE_NUMBER,''), "
					+ "IFNULL(V.OUT_FOR_REPAIR,0), IFNULL(V.OPERATIONALSTATUS,0), "
					+ "DATEDIFF(CURDATE(), IFNULL(L.SERVICE_DATE, CURDATE())), "
					+ "CASE WHEN L.FOLLOWUP_DATE IS NOT NULL AND L.FOLLOWUP_DATE < CURDATE() "
					+ "THEN 1 ELSE 0 END "
					+ "FROM vehicle_maintenance_log L "
					+ "JOIN VEHICLE V ON V.VEHICLEID=L.VEHICLEID "
					+ "LEFT JOIN vehicle_maintenance_type T "
					+ "ON T.VEHICLE_MAINTENANCE_TYPEID=L.MAINT_TYPEID "
					+ "WHERE L.ENTITYID=" + entityID + " AND L.IS_OPEN=1 "
					+ "AND L.STATUS!=" + RecordStatus.DELETE
					+ " AND V.STATUS!=" + RecordStatus.DELETE
					+ " ORDER BY L.FOLLOWUP_DATE IS NULL, L.FOLLOWUP_DATE, L.MAINT_LOGID DESC "
					+ "LIMIT 300", 16);

			StringBuilder o = new StringBuilder("{\"kpis\":{");
			o.append("\"open\":").append(kpiOpen)
					.append(",\"ofr\":").append(kpiOfr)
					.append(",\"grounded\":").append(kpiGr);
			/* overdue counted while building cards */
			java.util.Map<String, Integer> byDisp = new java.util.LinkedHashMap<String, Integer>();
			StringBuilder tasks = new StringBuilder("\"tasks\":[");
			for (int i = 0; i < r.size(); i++) {
				List t = (List) r.get(i);
				boolean overdue = "1".equals(getListData(t, 15));
				if (overdue) kpiOver++;
				boolean ofr = "1".equals(getListData(t, 12));
				boolean grounded = "1".equals(getListData(t, 13));
				String notes = getListData(t, 10);
				boolean handed = notes.toUpperCase().indexOf("HANDOFF ") >= 0;
				if (handed) kpiHanded++;
				String owner = getListData(t, 7);
				if (owner.length() == 0) owner = "(unassigned)";
				Integer oc = byDisp.get(owner);
				byDisp.put(owner, Integer.valueOf(oc == null ? 1 : oc.intValue() + 1));
				String col = handed ? "handed" : (ofr ? "ofr" : (grounded ? "grounded"
						: (overdue ? "overdue" : "open")));
				int ageDays = parseIntSafe(getListData(t, 14));
				if (i > 0) tasks.append(",");
				tasks.append("{")
						.append("\"id\":\"").append(jsEsc(getListData(t, 0))).append("\",")
						.append("\"vehId\":\"").append(jsEsc(getListData(t, 1))).append("\",")
						.append("\"veh\":\"").append(jsEsc(getListData(t, 2))).append("\",")
						.append("\"vin\":\"").append(jsEsc(getListData(t, 3))).append("\",")
						.append("\"type\":\"").append(jsEsc(getListData(t, 4))).append("\",")
						.append("\"cat\":\"").append(jsEsc(getListData(t, 5))).append("\",")
						.append("\"shop\":\"").append(jsEsc(getListData(t, 6))).append("\",")
						.append("\"owner\":\"").append(jsEsc(getListData(t, 7))).append("\",")
						.append("\"due\":\"").append(jsEsc(getListData(t, 8))).append("\",")
						.append("\"svc\":\"").append(jsEsc(getListData(t, 9))).append("\",")
						.append("\"notes\":\"").append(jsEsc(notes)).append("\",")
						.append("\"ro\":\"").append(jsEsc(getListData(t, 11))).append("\",")
						.append("\"ofr\":\"").append(jsEsc(getListData(t, 12))).append("\",")
						.append("\"grounded\":\"").append(jsEsc(getListData(t, 13))).append("\",")
						.append("\"overdue\":").append(overdue).append(",")
						.append("\"handed\":").append(handed).append(",")
						.append("\"age\":\"").append(ageDays).append("d\",")
						.append("\"col\":\"").append(col).append("\"}");
			}
			tasks.append("]");
			StringBuilder owners = new StringBuilder("\"byDisp\":[");
			boolean firstO = true;
			for (java.util.Map.Entry<String, Integer> e : byDisp.entrySet()) {
				if (!firstO) owners.append(",");
				firstO = false;
				owners.append("{\"nm\":\"").append(jsEsc(e.getKey()))
						.append("\",\"n\":").append(e.getValue().intValue()).append("}");
			}
			owners.append("]");
			o.append(",\"overdue\":").append(kpiOver)
					.append(",\"handed\":").append(kpiHanded).append("},")
					.append(tasks).append(",").append(owners).append("}");
			return o.toString();
		}

		if ("fleetBoardGet".equalsIgnoreCase(requestType)) {
			String logID = requestMap.get("logID") == null ? ""
					: requestMap.get("logID").trim();
			if (!logID.matches("\\d+"))
				return "<status>false</status><mesg>Bad request</mesg>";
			List r = db.selectAsList("SELECT L.MAINT_LOGID, L.VEHICLEID, "
					+ "IFNULL(V.VEHICLENUMBER,''), IFNULL(V.VINNUMBER,''), "
					+ "IFNULL(T.MAINTENANCETYPE, IFNULL(L.MAINT_CODE,'')), "
					+ "IFNULL(L.SHOP_VENDOR,''), IFNULL(L.FOLLOWUP_ASSIGNED_TO,''), "
					+ "IFNULL(DATE_FORMAT(L.FOLLOWUP_DATE,'%m/%d/%Y'),''), "
					+ "IFNULL(DATE_FORMAT(L.SERVICE_DATE,'%m/%d/%Y'),''), "
					+ "IFNULL(L.DESCRIPTION,''), IFNULL(L.INVOICE_NUMBER,''), "
					+ "IFNULL(L.PARTS_REPLACED,''), IFNULL(V.OUT_FOR_REPAIR,0), "
					+ "IFNULL(V.OPERATIONALSTATUS,0) "
					+ "FROM vehicle_maintenance_log L "
					+ "JOIN VEHICLE V ON V.VEHICLEID=L.VEHICLEID "
					+ "LEFT JOIN vehicle_maintenance_type T "
					+ "ON T.VEHICLE_MAINTENANCE_TYPEID=L.MAINT_TYPEID "
					+ "WHERE L.MAINT_LOGID=" + logID + " AND L.ENTITYID=" + entityID
					+ " AND L.STATUS!=" + RecordStatus.DELETE, 14);
			if (r.isEmpty())
				return "<status>false</status><mesg>Job not found</mesg>";
			List t = (List) r.get(0);
			String vehId = getListData(t, 1);
			StringBuilder o = new StringBuilder("{");
			String[] keys = { "id", "vehId", "veh", "vin", "type", "shop", "owner",
					"due", "svc", "notes", "ro", "parts", "ofr", "grounded" };
			for (int i = 0; i < keys.length; i++)
				o.append(i > 0 ? "," : "").append("\"").append(keys[i])
						.append("\":\"").append(jsEsc(getListData(t, i))).append("\"");
			o.append(",\"trail\":[");
			List n = db.selectAsList("SELECT DATE_FORMAT(CREATE_DATE,'%m/%d/%Y %l:%i %p'), "
					+ "IFNULL(CREATE_USER,''), IFNULL(COMMENTS,'') "
					+ "FROM VEHICLETRANS WHERE VEHICLEID=" + vehId
					+ " AND STATUS!=" + RecordStatus.DELETE
					+ " ORDER BY VEHICLETRANSID DESC LIMIT 40", 3);
			for (int i = 0; i < n.size(); i++) {
				List nt = (List) n.get(i);
				o.append(i > 0 ? "," : "").append("{\"t\":\"")
						.append(jsEsc(getListData(nt, 0))).append("\",\"u\":\"")
						.append(jsEsc(getListData(nt, 1))).append("\",\"m\":\"")
						.append(jsEsc(getListData(nt, 2))).append("\"}");
			}
			return o.append("]}").toString();
		}

		if ("fleetBoardClose".equalsIgnoreCase(requestType)) {
			String logID = requestMap.get("logID") == null ? ""
					: requestMap.get("logID").trim();
			if (!logID.matches("\\d+"))
				return "<status>false</status><mesg>Bad request</mesg>";
			String vehId = getTableColumnData("VEHICLEID", "vehicle_maintenance_log",
					"MAINT_LOGID", logID);
			if (vehId.length() == 0)
				return "<status>false</status><mesg>Job not found</mesg>";
			String mType = getTableColumnData("MAINT_CODE", "vehicle_maintenance_log",
					"MAINT_LOGID", logID);
			List<String> upList = new ArrayList<String>();
			upList.add("UPDATE vehicle_maintenance_log SET IS_OPEN=0, COMPLETED_DATE="
					+ db.getInsertSysdate() + ", UPDATE_USER="
					+ db.getInsertDBValue(loginUser) + ", UPDATE_DATE="
					+ db.getInsertSysdate() + " WHERE MAINT_LOGID=" + logID
					+ " AND ENTITYID=" + entityID + " AND IS_OPEN=1 AND STATUS!="
					+ RecordStatus.DELETE);
			String note = rq(requestMap, "note");
			addVehicleTransNote(vehId, "MAINTENANCE COMPLETED - "
					+ (mType.length() > 0 ? mType : "job")
					+ (note.length() > 0 ? " - " + note : ""), loginUser, upList);
			boolean result = db.batchInsert(upList);
			if (!result)
				return "<status>false</status><mesg>Close failed</mesg>";
			return "<status>true</status><mesg>Job closed</mesg>";
		}

		if ("fleetBoardNote".equalsIgnoreCase(requestType)) {
			String logID = requestMap.get("logID") == null ? ""
					: requestMap.get("logID").trim();
			String note = rq(requestMap, "note");
			if (!logID.matches("\\d+") || note.length() == 0)
				return "<status>false</status><mesg>Note is required</mesg>";
			String vehId = getTableColumnData("VEHICLEID", "vehicle_maintenance_log",
					"MAINT_LOGID", logID);
			if (vehId.length() == 0)
				return "<status>false</status><mesg>Job not found</mesg>";
			List<String> upList = new ArrayList<String>();
			addVehicleTransNote(vehId, "BOARD NOTE - " + note, loginUser, upList);
			/* also append onto the open job description for visibility on the card */
			upList.add("UPDATE vehicle_maintenance_log SET DESCRIPTION=CONCAT("
					+ "IFNULL(DESCRIPTION,''), "
					+ db.getInsertDBValue("\n[" + loginUser + "] " + note) + "), "
					+ "UPDATE_USER=" + db.getInsertDBValue(loginUser)
					+ ", UPDATE_DATE=" + db.getInsertSysdate()
					+ " WHERE MAINT_LOGID=" + logID + " AND IS_OPEN=1 AND STATUS!="
					+ RecordStatus.DELETE);
			boolean result = db.batchInsert(upList);
			if (!result)
				return "<status>false</status><mesg>Save failed</mesg>";
			return "<status>true</status><mesg>Note saved</mesg>";
		}

		if ("fleetBoardReassign".equalsIgnoreCase(requestType)) {
			String logID = requestMap.get("logID") == null ? ""
					: requestMap.get("logID").trim();
			String toUser = rq(requestMap, "assigned");
			String note = rq(requestMap, "note");
			if (!logID.matches("\\d+") || toUser.length() == 0)
				return "<status>false</status><mesg>Pick a dispatcher</mesg>";
			String fromUser = getTableColumnData("FOLLOWUP_ASSIGNED_TO",
					"vehicle_maintenance_log", "MAINT_LOGID", logID);
			String vehId = getTableColumnData("VEHICLEID", "vehicle_maintenance_log",
					"MAINT_LOGID", logID);
			String isOpen = getTableColumnData("IS_OPEN", "vehicle_maintenance_log",
					"MAINT_LOGID", logID);
			if (vehId.length() == 0 || !"1".equals(isOpen))
				return "<status>false</status><mesg>Open job not found</mesg>";
			if (fromUser.equalsIgnoreCase(toUser))
				return "<status>false</status><mesg>Already assigned to that dispatcher</mesg>";
			if (fromUser.length() == 0) fromUser = "(unassigned)";
			String handoff = "\n[" + loginUser + "] HANDOFF " + fromUser + " → " + toUser;
			if (note.length() > 0) handoff += " — " + note;
			List<String> upList = new ArrayList<String>();
			upList.add("UPDATE vehicle_maintenance_log SET FOLLOWUP_ASSIGNED_TO="
					+ db.getInsertDBValue(toUser) + ", DESCRIPTION=CONCAT("
					+ "IFNULL(DESCRIPTION,''), " + db.getInsertDBValue(handoff) + "), "
					+ "UPDATE_USER=" + db.getInsertDBValue(loginUser)
					+ ", UPDATE_DATE=" + db.getInsertSysdate()
					+ " WHERE MAINT_LOGID=" + logID + " AND IS_OPEN=1 AND STATUS!="
					+ RecordStatus.DELETE);
			addVehicleTransNote(vehId, "HANDOFF " + fromUser + " → " + toUser
					+ (note.length() > 0 ? " - " + note : ""), loginUser, upList);
			boolean result = db.batchInsert(upList);
			if (!result)
				return "<status>false</status><mesg>Hand off failed</mesg>";
			return "<status>true</status><mesg>Handed off to " + toUser + "</mesg>";
		}

		if ("fleetBoardVehicles".equalsIgnoreCase(requestType)) {
			List r = db.selectAsList("SELECT VEHICLEID, IFNULL(VEHICLENUMBER,''), "
					+ "IFNULL(VINNUMBER,'') FROM VEHICLE WHERE ENTITYID=" + entityID
					+ " AND STATUS!=" + RecordStatus.DELETE
					+ " ORDER BY VEHICLENUMBER LIMIT 500", 3);
			StringBuilder o = new StringBuilder("[");
			for (int i = 0; i < r.size(); i++) {
				List t = (List) r.get(i);
				o.append(i > 0 ? "," : "").append("{\"id\":\"")
						.append(jsEsc(getListData(t, 0))).append("\",\"nm\":\"")
						.append(jsEsc(getListData(t, 1))).append("\",\"vin\":\"")
						.append(jsEsc(getListData(t, 2))).append("\"}");
			}
			return o.append("]").toString();
		}

		if ("fleetBoardTypes".equalsIgnoreCase(requestType)) {
			ensureMaintTypes();
			List r = db.selectAsList("SELECT VEHICLE_MAINTENANCE_TYPEID, MAINTENANCETYPE, "
					+ "IFNULL(MAINT_CODE,''), IFNULL(MAINT_CATEGORY,'') "
					+ "FROM vehicle_maintenance_type WHERE STATUS!="
					+ RecordStatus.DELETE + " ORDER BY SORT_ORDER, MAINTENANCETYPE", 4);
			StringBuilder o = new StringBuilder("[");
			for (int i = 0; i < r.size(); i++) {
				List t = (List) r.get(i);
				o.append(i > 0 ? "," : "").append("{\"id\":\"")
						.append(jsEsc(getListData(t, 0))).append("\",\"nm\":\"")
						.append(jsEsc(getListData(t, 1))).append("\",\"code\":\"")
						.append(jsEsc(getListData(t, 2))).append("\",\"cat\":\"")
						.append(jsEsc(getListData(t, 3))).append("\"}");
			}
			return o.append("]").toString();
		}

		if ("fleetBoardCreate".equalsIgnoreCase(requestType)) {
			String vehId = requestMap.get("vehId") == null ? ""
					: requestMap.get("vehId").trim();
			String mTypeId = rq(requestMap, "mTypeId");
			String mType = rq(requestMap, "mType");
			String mCode = rq(requestMap, "mCode");
			String mCat = rq(requestMap, "mCat");
			String svcDate = rq(requestMap, "svcDate");
			if (!vehId.matches("\\d+"))
				return "<status>false</status><mesg>Select a vehicle</mesg>";
			if (mType.length() == 0 && !mTypeId.matches("\\d+"))
				return "<status>false</status><mesg>Pick a maintenance type</mesg>";
			if (svcDate.length() == 0)
				return "<status>false</status><mesg>Service date is required</mesg>";
			if (!mTypeId.matches("\\d+")) mTypeId = "";
			if (mType.length() == 0 && mTypeId.length() > 0)
				mType = getTableColumnData("MAINTENANCETYPE", "vehicle_maintenance_type",
						"VEHICLE_MAINTENANCE_TYPEID", mTypeId);
			if (mCode.length() == 0 && mTypeId.length() > 0)
				mCode = getTableColumnData("MAINT_CODE", "vehicle_maintenance_type",
						"VEHICLE_MAINTENANCE_TYPEID", mTypeId);
			if (mCat.length() == 0 && mTypeId.length() > 0)
				mCat = getTableColumnData("MAINT_CATEGORY", "vehicle_maintenance_type",
						"VEHICLE_MAINTENANCE_TYPEID", mTypeId);

			String stBefore = getTableColumnData("OPERATIONALSTATUS", "VEHICLE",
					"VEHICLEID", vehId);
			List<String> upList = new ArrayList<String>();
			upList.add("INSERT INTO vehicle_maintenance_log (VEHICLEID, ENTITYID, "
					+ "MAINT_TYPEID, MAINT_CODE, MAINT_CATEGORY, SERVICE_DATE, "
					+ "SHOP_VENDOR, INVOICE_NUMBER, PARTS_REPLACED, DESCRIPTION, "
					+ "STATUS_BEFORE, STATUS_AFTER, IS_OPEN, NEXT_SERVICE_DATE, "
					+ "FOLLOWUP_DATE, FOLLOWUP_ASSIGNED_TO, REMINDER_DAYS, "
					+ "CREATE_USER, CREATE_DATE, STATUS) VALUES ("
					+ vehId + ", " + entityID + ", "
					+ (mTypeId.length() > 0 ? mTypeId : "NULL") + ", "
					+ db.getInsertDBValue(mCode) + ", "
					+ db.getInsertDBValue(mCat) + ", "
					+ db.getInsertDate(svcDate) + ", "
					+ db.getInsertDBValue(rq(requestMap, "shop")) + ", "
					+ db.getInsertDBValue(rq(requestMap, "roNum")) + ", "
					+ db.getInsertDBValue(rq(requestMap, "parts")) + ", "
					+ db.getInsertDBValue(rq(requestMap, "notes")) + ", "
					+ (stBefore.length() > 0 ? stBefore : "NULL") + ", "
					+ (stBefore.length() > 0 ? stBefore : "NULL") + ", 1, "
					+ db.getInsertDate(rq(requestMap, "nextSvc")) + ", "
					+ db.getInsertDate(rq(requestMap, "followUp")) + ", "
					+ db.getInsertDBValue(rq(requestMap, "assigned")) + ", 30, "
					+ db.getInsertDBValue(loginUser) + ", " + db.getInsertSysdate()
					+ ", " + RecordStatus.ACTIVE + ")");
			StringBuilder note = new StringBuilder("MAINTENANCE - " + mType
					+ " - " + svcDate);
			String shop = rq(requestMap, "shop");
			if (shop.length() > 0) note.append(" - ").append(shop);
			String nts = rq(requestMap, "notes");
			if (nts.length() > 0) note.append(" - ").append(nts);
			addVehicleTransNote(vehId, note.toString(), loginUser, upList);
			boolean result = db.batchInsert(upList);
			if (!result)
				return "<status>false</status><mesg>Save failed</mesg>";
			return "<status>true</status><mesg>Fleet task created</mesg>";
		}

		if ("vehSave".equalsIgnoreCase(requestType)) {
			if (!recordID.matches("\\d+"))
				return "<status>false</status><mesg>Bad request</mesg>";

			String num = rq(requestMap, "num");
			if (num.length() == 0)
				return "<status>false</status><mesg>Vehicle Number is required</mesg>";
			String dup = checkDuplicate("", num, recordID, entityID);
			if (dup.length() > 0)
				return "<status>false</status><mesg>Another vehicle already "
						+ "uses that number</mesg>";
			String opSt = rq(requestMap, "op");
			if (!opSt.matches("\\d"))
				opSt = "0";
			String reason = rq(requestMap, "comments");
			if ("1".equals(opSt) && reason.length() == 0)
				return "<status>false</status><mesg>A reason is required when "
						+ "grounding a vehicle</mesg>";

			List<String> upList = new ArrayList<String>();
			upList.add("UPDATE VEHICLE SET VEHICLENUMBER="
					+ db.getInsertDBValue(num)
					+ ", VEHICLETYPE=" + db.getInsertDBValue(rq(requestMap, "type"))
					+ ", LICENSEPLATE=" + db.getInsertDBValue(rq(requestMap, "plate"))
					+ ", REGISTRATIONEXPIRY=" + db.getInsertDate(rq(requestMap, "regExp"))
					+ ", REGISTEREDSTATE=" + db.getInsertDBValue(rq(requestMap, "state"))
					+ ", SERVICETIER=" + db.getInsertDBValue(rq(requestMap, "tier"))
					+ ", OPERATIONALSTATUS=" + opSt
					+ ", RENTAL_START=" + db.getInsertDate(rq(requestMap, "rentS"))
					+ ", RENTAL_END=" + db.getInsertDate(rq(requestMap, "rentE"))
					+ ", PROVIDER=" + db.getInsertDBValue(rq(requestMap, "prov"))
					+ ", ODOMETER=" + db.getInsertDBValue(rq(requestMap, "odometer"))
					+ ", LAST_ODOMETER_REPORTED_DATE="
					+ db.getInsertDate(rq(requestMap, "odoDate"))
					+ ", LAST_OIL_CHANGE_MILEAGE="
					+ db.getInsertDBValue(rq(requestMap, "oilMileage"))
					+ ", LAST_OIL_CHANGE_DATE="
					+ db.getInsertDate(rq(requestMap, "oilDate"))
					+ ", UPDATE_USER=" + db.getInsertDBValue(loginUser)
					+ ", UPDATE_DATE=" + db.getInsertSysdate()
					+ " WHERE VEHICLEID=" + recordID + " AND ENTITYID=" + entityID
					+ " AND STATUS!=" + RecordStatus.DELETE);
			if (reason.length() > 0)
				addVehicleTransNote(recordID, reason, loginUser, upList);

			boolean result = db.batchInsert(upList);
			if (!result)
				return "<status>false</status><mesg>Save failed</mesg>";
			return "<status>true</status><mesg>Vehicle saved</mesg>";
		}

		/* spreadsheet-style bulk edit for odometer / oil / rental fields */
		if ("vehBulkSave".equalsIgnoreCase(requestType)) {
			String rowsJson = rq(requestMap, "rowsJson");
			List<Map<String, String>> bulkRows = parseBulkRows(rowsJson);
			if (bulkRows.isEmpty())
				return "<status>false</status><mesg>No changes to save</mesg>";

			List<String> upList = new ArrayList<String>();
			int n = 0;
			for (Map<String, String> row : bulkRows) {
				String id = row.get("id") == null ? "" : row.get("id").trim();
				if (!id.matches("\\d+"))
					continue;
				String odo = row.get("odometer") == null ? ""
						: row.get("odometer").trim();
				String oilMi = row.get("oilMileage") == null ? ""
						: row.get("oilMileage").trim();
				if (odo.length() > 0 && !odo.matches("\\d+"))
					return "<status>false</status><mesg>Invalid odometer for vehicle "
							+ id + "</mesg>";
				if (oilMi.length() > 0 && !oilMi.matches("\\d+"))
					return "<status>false</status><mesg>Invalid oil mileage for vehicle "
							+ id + "</mesg>";
				String odoDate = row.get("odoDate") == null ? ""
						: row.get("odoDate").trim();
				String oilDate = row.get("oilDate") == null ? ""
						: row.get("oilDate").trim();
				String rentS = row.get("rentS") == null ? ""
						: row.get("rentS").trim();
				String rentE = row.get("rentE") == null ? ""
						: row.get("rentE").trim();
				String prov = row.get("prov") == null ? ""
						: row.get("prov").trim();
				String opSt = row.get("op") == null ? ""
						: row.get("op").trim();
				if (!opSt.matches("\\d"))
					opSt = "0";
				String reason = row.get("reason") == null ? ""
						: row.get("reason").trim();
				upList.add("UPDATE VEHICLE SET ODOMETER="
						+ db.getInsertDBValue(odo)
						+ ", LAST_ODOMETER_REPORTED_DATE="
						+ db.getInsertDate(odoDate)
						+ ", LAST_OIL_CHANGE_MILEAGE="
						+ db.getInsertDBValue(oilMi)
						+ ", LAST_OIL_CHANGE_DATE="
						+ db.getInsertDate(oilDate)
						+ ", RENTAL_START=" + db.getInsertDate(rentS)
						+ ", RENTAL_END=" + db.getInsertDate(rentE)
						+ ", PROVIDER=" + db.getInsertDBValue(prov)
						+ ", OPERATIONALSTATUS=" + opSt
						+ ", UPDATE_USER=" + db.getInsertDBValue(loginUser)
						+ ", UPDATE_DATE=" + db.getInsertSysdate()
						+ " WHERE VEHICLEID=" + id + " AND ENTITYID=" + entityID
						+ " AND STATUS!=" + RecordStatus.DELETE);
				if (reason.length() > 0)
					addVehicleTransNote(id, reason, loginUser, upList);
				n++;
			}
			if (n == 0)
				return "<status>false</status><mesg>No valid rows to save</mesg>";
			boolean result = db.batchInsert(upList);
			if (!result)
				return "<status>false</status><mesg>Bulk save failed</mesg>";
			return "<status>true</status><mesg>" + n + " vehicle"
					+ (n == 1 ? "" : "s") + " updated</mesg>";
		}

		/* Registration PDF → docs/.../RegistrationForms (same docs tree as forms) */
		if ("regPdfUpload".equalsIgnoreCase(requestType)) {
			if (!recordID.matches("\\d+"))
				return "<status>false</status><mesg>Bad request</mesg>";
			String base64 = rq(requestMap, "base64");
			String fileName = rq(requestMap, "fileName");
			if (base64.length() == 0)
				return "<status>false</status><mesg>No file data</mesg>";
			if (fileName.length() == 0)
				fileName = "Registration.pdf";
			String lower = fileName.toLowerCase();
			if (!(lower.endsWith(".pdf") || lower.endsWith(".png")
					|| lower.endsWith(".jpg") || lower.endsWith(".jpeg")))
				return "<status>false</status><mesg>Upload a PDF or image</mesg>";
			/* strip data-url prefix if present */
			int comma = base64.indexOf(',');
			if (base64.startsWith("data:") && comma > 0)
				base64 = base64.substring(comma + 1);

			List v = db.selectAsList(
					"SELECT IFNULL(VEHICLENUMBER,''), IFNULL(VINNUMBER,'') "
					+ "FROM VEHICLE WHERE VEHICLEID=" + recordID
					+ " AND ENTITYID=" + entityID + " AND STATUS!="
					+ RecordStatus.DELETE, 2);
			if (v.isEmpty())
				return "<status>false</status><mesg>Vehicle not found</mesg>";
			List vt = (List) v.get(0);
			String vehNum = vt.get(0) == null ? "" : vt.get(0).toString().trim();
			String vin = vt.get(1) == null ? "" : vt.get(1).toString().trim();
			String safeNum = vehNum.replaceAll("[^A-Za-z0-9_-]", "_");
			String safeVin = vin.replaceAll("[^A-Za-z0-9_-]", "_");
			if (safeNum.length() == 0)
				safeNum = "Vehicle" + recordID;
			if (safeVin.length() == 0)
				safeVin = "NOVIN";
			String ext = lower.substring(lower.lastIndexOf('.'));
			/* named Vehicle# + VIN — e.g. Budget-2021_1HGCM82633A123456.pdf */
			String saveName = safeNum + "_" + safeVin + ext;

			/* Primary: docs/ for View Registration (laptop + all envs) */
			String docsRoot = ApplicationConfig.getDocsPath();
			if (docsRoot == null || docsRoot.length() == 0)
				docsRoot = ApplicationConfig.getApplicationPath()
						+ File.separator + "docs";
			String stableFolder = docsRoot + File.separator + "RegistrationForms"
					+ File.separator + recordID;
			Object[] stable = new FileUpload().uploadBase64File(base64,
					saveName, stableFolder);
			if (!((Boolean) stable[0]).booleanValue())
				return "<status>false</status><mesg>Could not save RegistrationForms file</mesg>";

			/* UAT: also store under F:\JavProject\serverUpload */
			if (ServerUploadPaths.isUatServerUpload()) {
				try {
					String uatFolder = ServerUploadPaths.getRegistrationForms()
							+ File.separator + recordID;
					new FileUpload().uploadBase64File(base64, saveName, uatFolder);
				} catch (Exception ignore) { }
			}

			try {
				String archiveFolder = fileUtility.getFolderPath("create",
						"RegistrationForms", loginUser);
				new FileUpload().uploadBase64File(base64, saveName, archiveFolder);
			} catch (Exception ignore) { }

			String relPath = "docs/RegistrationForms/" + recordID + "/"
					+ saveName;
			boolean ok = db.update("UPDATE VEHICLE SET REGISTRATION_PDF="
					+ db.getInsertDBValue(relPath)
					+ ", UPDATE_USER=" + db.getInsertDBValue(loginUser)
					+ ", UPDATE_DATE=" + db.getInsertSysdate()
					+ " WHERE VEHICLEID=" + recordID + " AND ENTITYID="
					+ entityID + " AND STATUS!=" + RecordStatus.DELETE);
			if (!ok)
				return "<status>false</status><mesg>Saved file but DB update failed</mesg>";
			return "<status>true</status><mesg>Registration uploaded</mesg><path>"
					+ relPath.replace("<", "") + "</path>";
		}

		/* Standalone RO PDF upload → docs/RegistrationForms/{id}/RO/{Vehicle#}_{ROnumber}.ext */
		if ("roPdfUpload".equalsIgnoreCase(requestType)) {
			if (!recordID.matches("\\d+"))
				return "<status>false</status><mesg>Bad request</mesg>";
			String roNum = rq(requestMap, "roNum");
			String roDate = rq(requestMap, "roDate");
			String base64 = rq(requestMap, "base64");
			if (roNum.length() == 0)
				return "<status>false</status><mesg>RO number is required</mesg>";
			if (base64.length() == 0)
				return "<status>false</status><mesg>No file data</mesg>";
			String relPath = saveVehicleRoPdf(recordID, entityID, loginUser, roNum,
					base64, rq(requestMap, "fileName"));
			if (relPath == null || relPath.length() == 0)
				return "<status>false</status><mesg>RO upload failed</mesg>";
			updateVehicleLatestRo(recordID, entityID, loginUser, roNum, roDate, relPath);
			return "<status>true</status><mesg>RO document uploaded</mesg><path>"
					+ relPath.replace("<", "") + "</path>";
		}

		return super.getAjaxRequestTypeResp(requestType, requestMap, loginUser,
				loginUserRoles, loginUserID, entityID);
	}

	/* minimal JSON-array-of-flat-objects parser (string values only) */
	private List<Map<String, String>> parseBulkRows(String json) {
		List<Map<String, String>> out = new ArrayList<Map<String, String>>();
		if (json == null)
			return out;
		int i = 0, n = json.length();
		while (i < n) {
			while (i < n && json.charAt(i) != '{')
				i++;
			if (i >= n)
				break;
			i++;
			Map<String, String> obj = new HashMap<String, String>();
			while (i < n && json.charAt(i) != '}') {
				while (i < n && json.charAt(i) != '"' && json.charAt(i) != '}')
					i++;
				if (i >= n || json.charAt(i) == '}')
					break;
				StringBuilder key = new StringBuilder();
				i++;
				while (i < n && json.charAt(i) != '"') {
					if (json.charAt(i) == '\\' && i + 1 < n)
						i++;
					key.append(json.charAt(i));
					i++;
				}
				i++;
				while (i < n && (json.charAt(i) == ':' || json.charAt(i) == ' '))
					i++;
				StringBuilder val = new StringBuilder();
				if (i < n && json.charAt(i) == '"') {
					i++;
					while (i < n && json.charAt(i) != '"') {
						if (json.charAt(i) == '\\' && i + 1 < n) {
							i++;
							char c = json.charAt(i);
							if (c == 'n' || c == 'r') {
								val.append(' ');
								i++;
								continue;
							}
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
				while (i < n && (json.charAt(i) == ',' || json.charAt(i) == ' '))
					i++;
			}
			if (!obj.isEmpty())
				out.add(obj);
			i++;
		}
		return out;
	}

	@Override
	public Object[] createRecord(MainBean mainBean, String loginUser,
			String loginUserRoles, String loginUserID, String entityID)
			throws Exception {

		bean = (AdminVehicle) mainBean;
		ErrorBean errorType = new ErrorBean();
		List<String> insList = new ArrayList<String>();

		String recordID = checkDuplicate(bean.getVinNumber(), "", "", entityID);
		if (recordID.length() == 0)
			recordID = checkDuplicate("", bean.getVehicleNumber(), "",
					entityID);

		if (recordID.length() == 0) {
			int status = bean.getStatus().length() == 0 ? RecordStatus.ACTIVE
					: Integer.parseInt(bean.getStatus());
			recordID = db.getNextIDValue("VEHICLEID");

			insList = buildMainQry(recordID, entityID, bean.getVehicleNumber(),
					bean.getVinNumber(), bean.getVehicleType(),
					bean.getLicensePlate(), bean.getRegistrationExpiryDate(),
					bean.getRegisteredState(), bean.getServiceTier(),
					bean.getOpertionalStatus(), bean.getMake(), bean.getModel(),
					bean.getSubModel(), bean.getStatusPriority(),
					bean.getStatusReasonCode(), bean.getStatusReasonMesg(),
					bean.getStatusSearchVal(), bean.getSubContractorName(),
					bean.getProvider(), bean.getRegistrationType(),
					bean.getVehicleYear(), bean.getOwnershipType(),
					bean.getOwnershipStart(), bean.getOwnershipEnd(),
					bean.getStation(), bean.getServiceType(),
					bean.getRentalStart(), bean.getRentalEnd(), status,
					loginUser, insList);

			if (bean.getComments().length() > 0) {
				String transID = db.getNextIDValue("VEHICLETRANSID");
				String insQry = "INSERT INTO VEHICLETRANS (VEHICLETRANSID, "
						+ "VEHICLEID, COMMENTS, CREATE_USER, CREATE_DATE, "
						+ "STATUS) VALUES (" + transID + ", " + recordID + ", "
						+ db.getInsertDBValue(bean.getComments()) + ", "
						+ db.getInsertDBValue(loginUser) + ", "
						+ db.getInsertSysdate() + ", " + RecordStatus.ACTIVE
						+ ")";
				insList.add(insQry);
			}

			boolean result = db.batchInsert(insList);

			errorType = getErrorType(result, SubmitType.CREATE,
					bean.getDisplayName());
		} else {
			errorType = getErrorType(false, SubmitType.DUPLICATE,
					bean.getDisplayName());

		}

		return new Object[] { recordID, errorType };
	}

	public List<String> buildMainQry(String recordID, String entityID,
			String vehicleNumber, String vinNumber, String vehicleType,
			String licensePlate, String registrationExpiryDate,
			String registeredState, String serviceTier, String opertionalStatus,
			String make, String model, String subModel, String statusPriority,
			String statusReasonCode, String statusReasonMesg,
			String statusSearchVal, String subContractorName, String provider,
			String registrationType, String vehicleYear, String ownershipType,
			String ownershipStart, String ownershipEnd, String station,
			String serviceType, String rentalStart, String rentalEnd,
			int status, String loginUser, List<String> insList) {

		String insQry = "INSERT INTO VEHICLE (VEHICLEID, ENTITYID, "
				+ "VEHICLENUMBER, VINNUMBER, VEHICLETYPE, LICENSEPLATE, "
				+ "REGISTRATIONEXPIRY, REGISTEREDSTATE, SERVICETIER, "
				+ "OPERATIONALSTATUS, MAKE, MODEL, SUBMODEL, STATUSPRIORITY, "
				+ "STATUSREASONCODE, STATUSREASONMSG, STATUSSEARCHVAL, "
				+ "SUBCONTRACTORNAME, PROVIDER, REGISTRATIONTYPE, VEHICLEYEAR, "
				+ "OWNERSHIPTYPE, OWNERSHIPSTART, OWNERSHIPEND, STATION, "
				+ "SERVICETYPE, RENTAL_START, RENTAL_END, "
				+ "CREATE_USER, CREATE_DATE, STATUS) VALUES (" + recordID + ", "
				+ entityID + ", " + db.getInsertDBValue(vehicleNumber) + ", "
				+ db.getInsertDBValue(vinNumber) + ", "
				+ db.getInsertDBValue(vehicleType) + ", "
				+ db.getInsertDBValue(licensePlate) + ", "
				+ db.getInsertDate(registrationExpiryDate) + ", "
				+ db.getInsertDBValue(registeredState) + ", "
				+ db.getInsertDBValue(serviceTier) + ", "
				+ db.getInsertDBValue(opertionalStatus) + ", "
				+ db.getInsertDBValue(make) + ", " + db.getInsertDBValue(model)
				+ ", " + db.getInsertDBValue(subModel) + ", "
				+ db.getInsertDBValue(statusPriority) + ", "
				+ db.getInsertDBValue(statusReasonCode) + ", "
				+ db.getInsertDBValue(statusReasonMesg) + ", "
				+ db.getInsertDBValue(statusSearchVal) + ", "
				+ db.getInsertDBValue(subContractorName) + ", "
				+ db.getInsertDBValue(provider) + ", "
				+ db.getInsertDBValue(registrationType) + ", "
				+ db.getInsertDBValue(vehicleYear) + ", "
				+ db.getInsertDBValue(ownershipType) + ", "
				+ db.getInsertDate(ownershipStart) + ", "
				+ db.getInsertDate(ownershipEnd) + ", "
				+ db.getInsertDBValue(station) + ", "
				+ db.getInsertDBValue(serviceType) + ", "
				+ db.getInsertDate(rentalStart) + ", "
				+ db.getInsertDate(rentalEnd) + ", "
				+ db.getInsertDBValue(loginUser) + ", " + db.getInsertSysdate()
				+ ", " + db.getInsertDBValue(status) + ")";
		insList.add(insQry);
		return insList;
	}

	@Override
	public Object[] updateRecord(MainBean mainBean, String loginUser,
			String loginUserRoles, String loginUserID, String entityID)
			throws Exception {

		bean = (AdminVehicle) mainBean;
		ErrorBean errorType = new ErrorBean();
		List<String> upList = new ArrayList<String>();

		String recordID = checkDuplicate(bean.getVinNumber(), "",
				bean.getAdminVehicleID(), entityID);
		if (recordID.length() == 0)
			recordID = checkDuplicate("", bean.getVehicleNumber(),
					bean.getAdminVehicleID(), entityID);

		if (recordID.length() == 0) {
			recordID = bean.getAdminVehicleID();
			int status = bean.getStatus().length() == 0 ? RecordStatus.ACTIVE
					: Integer.parseInt(bean.getStatus());

			String upQry = "UPDATE VEHICLE SET VEHICLENUMBER="
					+ db.getInsertDBValue(bean.getVehicleNumber())
					+ ", VINNUMBER=" + db.getInsertDBValue(bean.getVinNumber())
					+ ", VEHICLETYPE="
					+ db.getInsertDBValue(bean.getVehicleType())
					+ ", LICENSEPLATE="
					+ db.getInsertDBValue(bean.getLicensePlate())
					+ ", REGISTRATIONEXPIRY="
					+ db.getInsertDate(bean.getRegistrationExpiryDate())
					+ ", RENTAL_START="
					+ db.getInsertDate(bean.getRentalStart()) + ", RENTAL_END="
					+ db.getInsertDate(bean.getRentalEnd())
					+ ", REGISTEREDSTATE="
					+ db.getInsertDBValue(bean.getRegisteredState())
					+ ", SERVICETIER="
					+ db.getInsertDBValue(bean.getServiceTier())
					+ ", OPERATIONALSTATUS="
					+ db.getInsertDBValue(bean.getOpertionalStatus());
			/*-
			+ ", MAKE=" + db.getInsertDBValue(bean.getMake())
			+ ", MODEL=" + db.getInsertDBValue(bean.getModel())
			+ ", SUBMODEL=" + db.getInsertDBValue(bean.getSubModel())
			+ ", STATUSPRIORITY="
			+ db.getInsertDBValue(bean.getStatusPriority())
			+ ", STATUSREASONCODE="
			+ db.getInsertDBValue(bean.getStatusReasonCode())
			+ ", STATUSREASONMSG="
			+ db.getInsertDBValue(bean.getStatusReasonMesg())
			+ ", STATUSSEARCHVAL="
			+ db.getInsertDBValue(bean.getStatusSearchVal())
			+ ", SUBCONTRACTORNAME="
			+ db.getInsertDBValue(bean.getSubContractorName())
			+ ", PROVIDER=" + db.getInsertDBValue(bean.getProvider())
			+ ", REGISTRATIONTYPE="
			+ db.getInsertDBValue(bean.getRegistrationType())
			+ ", VEHICLEYEAR=" + db.getInsertDBValue(bean.getVehicleYear())
			+ ", OWNERSHIPTYPE="
			+ db.getInsertDBValue(bean.getOwnershipType()) + ", STATION="
			+ db.getInsertDBValue(bean.getStation()) + ", SERVICETYPE="
			+ db.getInsertDBValue(bean.getServiceType());
			*/
			upQry += ", UPDATE_USER=" + db.getInsertDBValue(loginUser)
					+ ", UPDATE_DATE=" + db.getInsertSysdate() + ", STATUS="
					+ db.getInsertDBValue(status) + " WHERE VEHICLEID="
					+ recordID;
			upList.add(upQry);

			if (bean.getComments().length() > 0) {
				String transID = db.getNextIDValue("VEHICLETRANSID");
				String insQry = "INSERT INTO VEHICLETRANS (VEHICLETRANSID, "
						+ "VEHICLEID, COMMENTS, CREATE_USER, CREATE_DATE, "
						+ "STATUS) VALUES (" + transID + ", " + recordID + ", "
						+ db.getInsertDBValue(bean.getComments()) + ", "
						+ db.getInsertDBValue(loginUser) + ", "
						+ db.getInsertSysdate() + ", " + RecordStatus.ACTIVE
						+ ")";
				upList.add(insQry);

			} else {
				String selQry = "SELECT MAX(VEHICLETRANSID) FROM VEHICLETRANS WHERE VEHICLEID="
						+ recordID + " AND STATUS=" + RecordStatus.ACTIVE;
				String maxTransID = db.selectById(selQry);
				if (maxTransID.length() > 0) {
					upQry = "UPDATE VEHICLETRANS SET UPDATE_USER="
							+ db.getInsertDBValue(loginUser) + ", UPDATE_DATE="
							+ db.getInsertSysdate() + " WHERE VEHICLETRANSID="
							+ maxTransID;
					upList.add(upQry);
				}
			}

			boolean result = db.batchInsert(upList);

			errorType = getErrorType(result, SubmitType.UPDATE,
					bean.getDisplayName());
		} else {
			errorType = getErrorType(false, SubmitType.DUPLICATE,
					bean.getDisplayName());
		}

		return new Object[] { recordID, errorType };
	}

	@Override
	public Object[] deleteRecord(MainBean mainBean, String loginUser,
			String loginUserRoles, String loginUserID, String entityID)
			throws Exception {

		bean = (AdminVehicle) mainBean;
		ErrorBean errorType = new ErrorBean();
		List<String> upList = new ArrayList<String>();

		String recordID = bean.getAdminVehicleID();
		upList.add(buildStatusQry("VEHICLE", "VEHICLEID", recordID,
				RecordStatus.DELETE, loginUser));

		boolean result = db.batchInsert(upList);

		errorType = getErrorType(result, SubmitType.DELETE,
				bean.getDisplayName());

		return new Object[] { recordID, errorType };
	}

	@Override
	public Object[] finalRecord(MainBean mainBean, String loginUser,
			String loginUserRoles, String loginUserID, String entityID)
			throws Exception {

		bean = (AdminVehicle) mainBean;
		ErrorBean errorType = new ErrorBean();
		List<String> upList = new ArrayList<String>();

		String recordID = bean.getAdminVehicleID();
		upList.add(buildStatusQry("VEHICLE", "VEHICLEID", recordID,
				RecordStatus.POST, loginUser));

		boolean result = db.batchInsert(upList);

		errorType = getErrorType(result, SubmitType.FINAL,
				bean.getDisplayName());

		return new Object[] { recordID, errorType };
	}

	@Override
	public AdminVehicle fetchRecord(String recordID, String loginUser,
			String loginUserRoles, String loginUserID, String entityID,
			int submitType) throws Exception {

		String selQry = "SELECT VEHICLEID, ENTITYID, VEHICLENUMBER, "
				+ "VINNUMBER, VEHICLETYPE, LICENSEPLATE, "
				+ db.getSelectDate("REGISTRATIONEXPIRY") + ", REGISTEREDSTATE, "
				+ "SERVICETIER, OPERATIONALSTATUS, '', MAKE, MODEL, SUBMODEL, STATUSPRIORITY, "
				+ "STATUSREASONCODE, STATUSREASONMSG, STATUSSEARCHVAL, SUBCONTRACTORNAME, "
				+ "PROVIDER, REGISTRATIONTYPE, VEHICLEYEAR, OWNERSHIPTYPE, "
				+ db.getSelectDate("OWNERSHIPSTART") + ", "
				+ db.getSelectDate("OWNERSHIPEND") + ", STATION, SERVICETYPE, "
				+ db.getSelectDate("RENTAL_START") + ", "
				+ db.getSelectDate("RENTAL_END") + ", CREATE_USER, "
				+ db.getSelectDateTime("CREATE_DATE") + ", UPDATE_USER, "
				+ db.getSelectDateTime("UPDATE_DATE")
				+ ", STATUS FROM VEHICLE WHERE VEHICLEID=" + recordID;

		List resultList = new ArrayList();
		if (recordID.length() > 0) {
			resultList = db.selectAsList(selQry,
					bean.getBeanAttributes().size());

			selQry = "SELECT VEHICLETRANSID, COMMENTS,  CREATE_USER, "
					+ db.getSelectDateTime("CREATE_DATE")
					+ " FROM VEHICLETRANS WHERE STATUS=" + RecordStatus.ACTIVE
					+ " AND  VEHICLEID=" + recordID + " ORDER BY 1 DESC";
			List transList = db.selectAsList(selQry, 4);
			bean.setOpertionalStatusReasonList(transList);
		}

		bean = (AdminVehicle) setListValuesToBean(bean,
				bean.getBeanAttributes(), resultList);

		return bean;
	}

	public String checkDuplicate(String vinNumber, String vehicleNumber,
			String vehicleID, String entityID) throws Exception {

		String recordID = "";

		String condQry = db.getDataInCondQuery(vinNumber, "VINNUMBER");

		condQry += db.getDataInCondQuery(vehicleNumber, "VEHICLENUMBER");

		if (vehicleID.length() > 0)
			condQry += " AND VEHICLEID!=" + vehicleID;

		String selQry = "SELECT VEHICLEID FROM VEHICLE WHERE STATUS IN ("
				+ RecordStatus.ACTIVE + ") AND ENTITYID=" + entityID + condQry;

		List resultList = db.selectAsList(selQry, 1);
		if (resultList.size() > 0) {
			List tempList = (ArrayList) resultList.get(0);
			recordID = tempList.get(0) == null ? ""
					: tempList.get(0).toString().trim();
		}

		return recordID;
	}

	@Override
	public double updateFromFile(List<String> columnsList, List dataList,
			String loginUser, String entityID, Map<String, String> _reqMap) {

		double numOfRows = 0;
		for (int i = 0; i < dataList.size(); i++) {
			List tempList = (ArrayList) dataList.get(i);
			String vinNumber = getListDBData(tempList, 0);
			String serviceType = getListDBData(tempList, 1);
			String vehicleNumber = getListDBData(tempList, 2);
			String licensePlate = getListDBData(tempList, 3);
			String make = getListDBData(tempList, 4);
			String model = getListDBData(tempList, 5);
			String subModel = getListDBData(tempList, 6);
			String status1 = getListDBData(tempList, 7);
			String statusPriority = getListDBData(tempList, 8);
			String statusReasonCode = getListDBData(tempList, 9);
			String statusReasonMesg = getListDBData(tempList, 10);
			String opertionalStatus = getListDBData(tempList, 11);
			String statusSearchVal = getListDBData(tempList, 12);
			String subContractorName = getListDBData(tempList, 13);
			String provider = getListDBData(tempList, 14);
			String registrationType = getListDBData(tempList, 15);
			String vehicleYear = getListDBData(tempList, 16);
			String vehicleType = getListDBData(tempList, 17);
			String ownershipType = getListDBData(tempList, 18);
			String ownershipStart = getListDBData(tempList, 19);
			String ownershipEnd = getListDBData(tempList, 20);
			String pmStatus = getListDBData(tempList, 21);
			String registrationExpiryDate = getListDBData(tempList, 22);
			String registeredState = getListDBData(tempList, 23);
			String serviceTier = getListDBData(tempList, 24);
			String station = getListDBData(tempList, 25);
			String payLoad = getListDBData(tempList, 26);
			String cubicCapacity = getListDBData(tempList, 27);

			try {
				List<String> insList = new ArrayList<String>();
				registrationExpiryDate = getFileDate(registrationExpiryDate);
				ownershipStart = getFileDate(ownershipStart);
				ownershipEnd = getFileDate(ownershipEnd);

				if ("Amazon-Owned".equalsIgnoreCase(vehicleType))
					vehicleType = "Amazon-Owned";

				if ("OPERATIONAL".equalsIgnoreCase(opertionalStatus))
					opertionalStatus = "0";
				else if ("GROUNDED".equalsIgnoreCase(opertionalStatus))
					opertionalStatus = "1";

				if (registeredState.contains(" - "))
					registeredState = registeredState
							.substring(registeredState.indexOf(" - ") + 3)
							.trim();

				serviceTier = mainUtil.getServiceTier(serviceTier);

				String recordID = checkDuplicate(vinNumber, "", "", entityID);
				if (recordID.length() == 0)
					recordID = checkDuplicate("", vehicleNumber, "", entityID);

				if (recordID.length() == 0) {
					int status = bean.getStatus().length() == 0
							? RecordStatus.ACTIVE
							: Integer.parseInt(bean.getStatus());

					recordID = db.getNextIDValue("VEHICLEID");

					insList = buildMainQry(recordID, entityID, vehicleNumber,
							vinNumber, vehicleType, licensePlate,
							registrationExpiryDate, registeredState,
							serviceTier, opertionalStatus, make, model,
							subModel, statusPriority, statusReasonCode,
							statusReasonMesg, statusSearchVal,
							subContractorName, provider, registrationType,
							vehicleYear, ownershipType, ownershipStart,
							ownershipEnd, station, serviceType, ownershipStart,
							ownershipEnd, status, loginUser, insList);

				} else {
					int status = bean.getStatus().length() == 0
							? RecordStatus.ACTIVE
							: Integer.parseInt(bean.getStatus());

					String upQry = "UPDATE VEHICLE SET MAKE="
							+ db.getInsertDBValue(make) + ", MODEL="
							+ db.getInsertDBValue(model) + ", SUBMODEL="
							+ db.getInsertDBValue(subModel) + ", VEHICLENUMBER="
							+ db.getInsertDBValue(vehicleNumber)
							+ ", VEHICLETYPE="
							+ db.getInsertDBValue(vehicleType)
							+ ", LICENSEPLATE="
							+ db.getInsertDBValue(licensePlate)
							+ ", REGISTRATIONEXPIRY="
							+ db.getInsertDate(registrationExpiryDate)
							+ ", REGISTEREDSTATE="
							+ db.getInsertDBValue(registeredState)
							+ ", SERVICETIER="
							+ db.getInsertDBValue(serviceTier)
							+ ", STATUSPRIORITY="
							+ db.getInsertDBValue(statusPriority)
							+ ", STATUSREASONCODE="
							+ db.getInsertDBValue(statusReasonCode)
							+ ", STATUSREASONMSG="
							+ db.getInsertDBValue(statusReasonMesg)
							+ ", STATUSSEARCHVAL="
							+ db.getInsertDBValue(statusSearchVal)
							+ ", SUBCONTRACTORNAME="
							+ db.getInsertDBValue(subContractorName)
							+ ", PROVIDER=" + db.getInsertDBValue(provider)
							+ ", REGISTRATIONTYPE="
							+ db.getInsertDBValue(registrationType)
							+ ", VEHICLEYEAR="
							+ db.getInsertDBValue(vehicleYear)
							+ ", OPERATIONALSTATUS="
							+ db.getInsertDBValue(opertionalStatus)
							+ ", OWNERSHIPTYPE="
							+ db.getInsertDBValue(ownershipType)
							+ ", OWNERSHIPSTART="
							+ db.getInsertDate(ownershipStart)
							+ ", OWNERSHIPEND=" + db.getInsertDate(ownershipEnd)
							+ ", RENTAL_START="
							+ db.getInsertDate(ownershipStart) + ", RENTAL_END="
							+ db.getInsertDate(ownershipEnd) + ", STATION="
							+ db.getInsertDBValue(station) + ", SERVICETYPE="
							+ db.getInsertDBValue(serviceType)
							+ ", UPDATE_USER=" + db.getInsertDBValue(loginUser)
							+ ", UPDATE_DATE=" + db.getInsertSysdate()
							+ ", STATUS=" + db.getInsertDBValue(status)
							+ " WHERE VEHICLEID=" + recordID;
					insList.add(upQry);
				}

				if (insList.size() > 0) {
					boolean result = db.batchInsert(insList);
					if (result)
						numOfRows++;
				}
			} catch (Exception ex) {
				ex.printStackTrace();
			}

		}

		return numOfRows;
	}
}
