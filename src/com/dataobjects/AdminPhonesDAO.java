package com.dataobjects;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

import com.beans.AdminPhones;
import com.beans.ErrorBean;
import com.beans.MainBean;
import com.beans.SearchBean;
import com.util.RecordStatus;
import com.util.SubmitType;

public class AdminPhonesDAO extends MVPGDAO {

	AdminPhones bean = new AdminPhones();

	private String blank(String v) {
		return v == null ? "" : v.trim();
	}

	@Override
	public SearchBean searchRecords(SearchBean searchBean, String recordID,
			String loginUser, String loginUserRoles, String loginUserID,
			String entityID) throws Exception {

		List<String> labelsList = new ArrayList<String>();
		labelsList.add("Phone Number");
		labelsList.add("Phone Status");
		labelsList.add("Current status");
		labelsList.add("Device In Use Date");
		labelsList.add("Last Audit Date");
		labelsList.add("Remaining Days");
		labelsList.add("Notes");

		searchBean.setWidthColumns(new int[] { 14, 12, 12, 14, 14, 12, 22 });
		searchBean.setDisplayName(bean.getDisplayName() + "s");
		searchBean.setController(bean.getController());
		ensurePhoneStatusOptions(entityID);

		String condQry = "";
		condQry += db.getDataInCondQuery(searchBean.getSrhValue(),
				"PHONENUMBER");

		if (searchBean.getSrhValue2().length() > 0) {
			condQry += db.getDataInCondQuery(searchBean.getSrhValue2(),
					"CURRENTSTATUS");
		}

		if (searchBean.getSrhStatus().length() > 0) {
			condQry += db.getDataInCondQuery(searchBean.getSrhStatus(),
					"PHONESTATUS");
		}

		String selQry = "SELECT PHONEID, PHONENUMBER, PHONESTATUS, CURRENTSTATUS, "
				+ db.getSelectDate("DEVICEINUSEDATE") + ", "
				+ db.getSelectDate("AUDITEDDATE") + ", IFNULL(REMARKS,''), "
				+ db.getSelectDate("CONTRACTENDDATE") + ", "
				+ db.getSelectDate("CONTRACTSTARTDATE")
				+ " FROM PHONES WHERE STATUS!=" + RecordStatus.DELETE
				+ " AND ENTITYID=" + entityID + condQry
				+ getOrderByQry(searchBean, "2");

		List resultList = db.selectAsList(selQry, 9);
		if (resultList.size() > 0) {
			for (int i = 0; i < resultList.size(); i++) {
				List tempList = (ArrayList) resultList.get(i);
				String phoneStatus = tempList.get(2) == null ? ""
						: tempList.get(2).toString().trim();
				String currentStatus = tempList.get(3) == null ? ""
						: tempList.get(3).toString().trim();
				tempList.set(2, AdminPhones.phoneStatusLabel(phoneStatus));
				tempList.set(3, AdminPhones.currentStatusLabel(currentStatus));
				String remain = remainingDaysValue(cell(tempList, 7),
						cell(tempList, 8));
				tempList.add(6, remain);
				resultList.set(i, tempList);
			}
		}

		Map transMap = searchBean.getTransMap() == null ? new HashMap()
				: searchBean.getTransMap();
		transMap.put("phoneStatuses", statusOptionNames(entityID, "phone"));
		transMap.put("currentStatuses", statusOptionNames(entityID, "current"));
		searchBean.setTransMap(transMap);

		searchBean.setLabelsList(labelsList);
		searchBean.setDataList(resultList);
		searchBean.setSearchFiltersArray(new String[] { "Phone Number",
				"Phone Status", "Current Status" });
		return searchBean;
	}

	@Override
	public Object[] createRecord(MainBean mainBean, String loginUser,
			String loginUserRoles, String loginUserID, String entityID)
			throws Exception {

		bean = (AdminPhones) mainBean;
		ErrorBean errorType = new ErrorBean();
		List<String> insList = new ArrayList<String>();
		String recordID = "";
		String duplicateType = "";

		String condQry = db.getDataInCondQuery(bean.getPhoneNumber(),
				"PHONENUMBER");
		String selQry = "SELECT PHONEID FROM PHONES WHERE STATUS IN ("
				+ RecordStatus.ACTIVE + ", " + RecordStatus.INACTIVE
				+ ") AND ENTITYID=" + entityID + condQry;
		List resultList = db.selectAsList(selQry, 1);
		if (resultList.size() > 0) {
			List tempList = (ArrayList) resultList.get(0);
			recordID = tempList.get(0) == null ? ""
					: tempList.get(0).toString().trim();
		}

		if (recordID.length() == 0 && blank(bean.getSerialNumber()).length() > 0) {
			condQry = db.getDataInCondQuery(bean.getSerialNumber(),
					"SERIALNUMBER");
			selQry = "SELECT PHONEID FROM PHONES WHERE STATUS IN ("
					+ RecordStatus.ACTIVE + ", " + RecordStatus.INACTIVE
					+ ") AND ENTITYID=" + entityID + condQry;
			resultList = db.selectAsList(selQry, 1);
			if (resultList.size() > 0) {
				List tempList = (ArrayList) resultList.get(0);
				recordID = tempList.get(0) == null ? ""
						: tempList.get(0).toString().trim();
				duplicateType = " - IMEI 1";
			}
		}

		if (recordID.length() == 0) {
			int status = bean.getStatus().length() == 0 ? RecordStatus.ACTIVE
					: Integer.parseInt(bean.getStatus());
			String currentStatus = AdminPhones.currentStatusLabel(
					blank(bean.getCurrentStatus()));
			String phoneStatus = AdminPhones.phoneStatusLabel(
					blank(bean.getPhoneStatus()));
			addStatusOption("phone", phoneStatus, entityID, loginUser);
			addStatusOption("current", currentStatus, entityID, loginUser);
			recordID = db.getNextIDValue("PHONEID");

			String insQry = "INSERT INTO PHONES (PHONEID, ENTITYID, "
					+ "PHONENUMBER, PHONESTATUS, CURRENTSTATUS, SERIALNUMBER, "
					+ "DEVICEMAKE, DEVICEMODEL, IMEI2, IMSI, ICCID, EID, "
					+ "REMARKS, AUDITEDDATE, CONTRACTENDDATE, CONTRACTSTARTDATE, "
					+ "DEVICEORDEREDDATE, DEVICEORDEREDIMEI, DEVICEINUSEDATE, "
					+ "CREATE_USER, CREATE_DATE, STATUS) VALUES (" + recordID
					+ ", " + entityID + ", "
					+ db.getInsertDBValue(bean.getPhoneNumber()) + ", "
					+ db.getInsertDBValue(phoneStatus) + ", "
					+ db.getInsertDBValue(currentStatus) + ", "
					+ db.getInsertDBValue(bean.getSerialNumber()) + ", "
					+ db.getInsertDBValue(bean.getDeviceMake()) + ", "
					+ db.getInsertDBValue(bean.getDeviceModel()) + ", "
					+ db.getInsertDBValue(bean.getImei2()) + ", "
					+ db.getInsertDBValue(bean.getImsi()) + ", "
					+ db.getInsertDBValue(bean.getIccid()) + ", "
					+ db.getInsertDBValue(bean.getEid()) + ", "
					+ db.getInsertDBValue(bean.getRemarks()) + ", "
					+ db.getInsertDate(bean.getAuditedDate()) + ", "
					+ db.getInsertDate(bean.getContractEndDate()) + ", "
					+ db.getInsertDate(bean.getContractStartDate()) + ", "
					+ db.getInsertDate(bean.getDeviceOrderedDate()) + ", "
					+ db.getInsertDBValue(bean.getDeviceOrderedImei()) + ", "
					+ db.getInsertDate(bean.getDeviceInUseDate()) + ", "
					+ db.getInsertDBValue(loginUser) + ", "
					+ db.getInsertSysdate() + ", " + db.getInsertDBValue(status)
					+ ")";
			insList.add(insQry);

			boolean result = db.batchInsert(insList);

			errorType = getErrorType(result, SubmitType.CREATE,
					bean.getDisplayName());
		} else {
			errorType = getErrorType(false, SubmitType.DUPLICATE,
					bean.getDisplayName() + duplicateType);

		}

		return new Object[] { recordID, errorType };
	}

	@Override
	public Object[] updateRecord(MainBean mainBean, String loginUser,
			String loginUserRoles, String loginUserID, String entityID)
			throws Exception {

		bean = (AdminPhones) mainBean;
		ErrorBean errorType = new ErrorBean();
		List<String> upList = new ArrayList<String>();

		int status = bean.getStatus().length() == 0 ? RecordStatus.ACTIVE
				: Integer.parseInt(bean.getStatus());
		String recordID = bean.getPhoneID();
		String currentStatus = AdminPhones.currentStatusLabel(
				blank(bean.getCurrentStatus()));
		String phoneStatus = AdminPhones.phoneStatusLabel(
				blank(bean.getPhoneStatus()));
		addStatusOption("phone", phoneStatus, entityID, loginUser);
		addStatusOption("current", currentStatus, entityID, loginUser);

		String condQry = db.getDataInCondQuery(bean.getPhoneNumber(),
				"PHONENUMBER");
		String selQry = "SELECT PHONEID FROM PHONES WHERE STATUS IN ("
				+ RecordStatus.ACTIVE + ", " + RecordStatus.INACTIVE
				+ ") AND ENTITYID=" + entityID + " AND PHONEID!=" + recordID
				+ condQry;
		List resultList = db.selectAsList(selQry, 1);
		if (resultList.size() > 0) {
			List tempList = (ArrayList) resultList.get(0);
			recordID = tempList.get(0) == null ? ""
					: tempList.get(0).toString().trim();

			errorType = getErrorType(false, SubmitType.DUPLICATE,
					bean.getDisplayName());
			return new Object[] { recordID, errorType };
		}

		if (blank(bean.getSerialNumber()).length() > 0) {
			condQry = db.getDataInCondQuery(bean.getSerialNumber(),
					"SERIALNUMBER");
			selQry = "SELECT PHONEID FROM PHONES WHERE STATUS IN ("
					+ RecordStatus.ACTIVE + ", " + RecordStatus.INACTIVE
					+ ") AND ENTITYID=" + entityID + " AND PHONEID!="
					+ recordID + condQry;
			resultList = db.selectAsList(selQry, 1);
			if (resultList.size() > 0) {
				List tempList = (ArrayList) resultList.get(0);
				recordID = tempList.get(0) == null ? ""
						: tempList.get(0).toString().trim();

				errorType = getErrorType(false, SubmitType.DUPLICATE,
						bean.getDisplayName() + " - IMEI 1");
				return new Object[] { recordID, errorType };
			}
		}

		String upQry = "UPDATE PHONES SET PHONENUMBER="
				+ db.getInsertDBValue(bean.getPhoneNumber()) + ", PHONESTATUS="
				+ db.getInsertDBValue(phoneStatus)
				+ ", CURRENTSTATUS=" + db.getInsertDBValue(currentStatus)
				+ ", SERIALNUMBER="
				+ db.getInsertDBValue(bean.getSerialNumber()) + ", DEVICEMAKE="
				+ db.getInsertDBValue(bean.getDeviceMake()) + ", DEVICEMODEL="
				+ db.getInsertDBValue(bean.getDeviceModel()) + ", IMEI2="
				+ db.getInsertDBValue(bean.getImei2()) + ", IMSI="
				+ db.getInsertDBValue(bean.getImsi()) + ", ICCID="
				+ db.getInsertDBValue(bean.getIccid()) + ", EID="
				+ db.getInsertDBValue(bean.getEid()) + ", REMARKS="
				+ db.getInsertDBValue(bean.getRemarks()) + ", AUDITEDDATE="
				+ db.getInsertDate(bean.getAuditedDate()) + ", CONTRACTENDDATE="
				+ db.getInsertDate(bean.getContractEndDate())
				+ ", CONTRACTSTARTDATE="
				+ db.getInsertDate(bean.getContractStartDate())
				+ ", DEVICEORDEREDDATE="
				+ db.getInsertDate(bean.getDeviceOrderedDate())
				+ ", DEVICEORDEREDIMEI="
				+ db.getInsertDBValue(bean.getDeviceOrderedImei())
				+ ", DEVICEINUSEDATE="
				+ db.getInsertDate(bean.getDeviceInUseDate())
				+ ", UPDATE_USER=" + db.getInsertDBValue(loginUser)
				+ ", UPDATE_DATE=" + db.getInsertSysdate() + ", STATUS="
				+ db.getInsertDBValue(status) + " WHERE PHONEID=" + recordID;
		upList.add(upQry);

		boolean result = db.batchInsert(upList);

		errorType = getErrorType(result, SubmitType.UPDATE,
				bean.getDisplayName());

		return new Object[] { recordID, errorType };
	}

	@Override
	public Object[] deleteRecord(MainBean mainBean, String loginUser,
			String loginUserRoles, String loginUserID, String entityID)
			throws Exception {

		bean = (AdminPhones) mainBean;
		ErrorBean errorType = new ErrorBean();
		List<String> upList = new ArrayList<String>();

		String recordID = bean.getPhoneID();
		upList.add(buildStatusQry("PHONES", "PHONEID", recordID,
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

		bean = (AdminPhones) mainBean;
		ErrorBean errorType = new ErrorBean();
		List<String> upList = new ArrayList<String>();

		String recordID = bean.getPhoneID();
		upList.add(buildStatusQry("PHONES", "PHONEID", recordID,
				RecordStatus.POST, loginUser));

		boolean result = db.batchInsert(upList);

		errorType = getErrorType(result, SubmitType.FINAL,
				bean.getDisplayName());

		return new Object[] { recordID, errorType };
	}

	@Override
	public AdminPhones fetchRecord(String recordID, String loginUser,
			String loginUserRoles, String loginUserID, String entityID,
			int submitType) throws Exception {

		String selQry = "SELECT PHONEID, ENTITYID, PHONENUMBER, "
				+ "PHONESTATUS, CURRENTSTATUS, SERIALNUMBER, DEVICEMAKE, "
				+ "DEVICEMODEL, IMEI2, IMSI, ICCID, EID, REMARKS, "
				+ db.getSelectDate("AUDITEDDATE") + ", "
				+ db.getSelectDate("CONTRACTENDDATE") + ", "
				+ db.getSelectDate("CONTRACTSTARTDATE") + ", "
				+ db.getSelectDate("DEVICEORDEREDDATE")
				+ ", DEVICEORDEREDIMEI, "
				+ db.getSelectDate("DEVICEINUSEDATE") + ", CREATE_USER, "
				+ db.getSelectDateTime("CREATE_DATE") + ", UPDATE_USER, "
				+ db.getSelectDateTime("UPDATE_DATE")
				+ ", STATUS FROM PHONES WHERE PHONEID=" + recordID;

		List resultList = new ArrayList();
		if (recordID.length() > 0)
			resultList = db.selectAsList(selQry,
					bean.getBeanAttributes().size());

		bean = (AdminPhones) setListValuesToBean(bean, bean.getBeanAttributes(),
				resultList);

		bean.setPhoneStatus(AdminPhones.phoneStatusLabel(bean.getPhoneStatus()));
		bean.setCurrentStatus(
				AdminPhones.currentStatusLabel(bean.getCurrentStatus()));

		return bean;
	}

	@Override
	public String getAjaxRequestTypeResp(String requestType,
			Map<String, String> requestMap, String loginUser,
			String loginUserRoles, String loginUserID, String entityID)
			throws Exception {

		String recordID = requestMap.get("recordID") == null ? ""
				: requestMap.get("recordID").trim();

		if ("phoneGet".equalsIgnoreCase(requestType)) {
			if (!recordID.matches("\\d+"))
				return "<status>false</status><mesg>Bad request</mesg>";
			List r = db.selectAsList("SELECT PHONENUMBER, PHONESTATUS, "
					+ "CURRENTSTATUS, IFNULL(SERIALNUMBER,''), "
					+ "IFNULL(DEVICEMAKE,''), IFNULL(DEVICEMODEL,''), "
					+ "IFNULL(IMEI2,''), IFNULL(IMSI,''), IFNULL(ICCID,''), "
					+ "IFNULL(EID,''), IFNULL(REMARKS,''), "
					+ db.getSelectDate("AUDITEDDATE") + ", "
					+ db.getSelectDate("CONTRACTENDDATE") + ", "
					+ db.getSelectDate("CONTRACTSTARTDATE") + ", "
					+ db.getSelectDate("DEVICEORDEREDDATE") + ", "
					+ "IFNULL(DEVICEORDEREDIMEI,''), "
					+ db.getSelectDate("DEVICEINUSEDATE")
					+ " FROM PHONES WHERE PHONEID=" + recordID
					+ " AND ENTITYID=" + entityID + " AND STATUS!="
					+ RecordStatus.DELETE, 17);
			if (r.isEmpty())
				return "<status>false</status><mesg>Phone not found</mesg>";
			List t = (List) r.get(0);
			String[] keys = { "num", "ps", "cs", "imei1", "make", "model",
					"imei2", "imsi", "iccid", "eid", "notes", "audit",
					"endDt", "startDt", "ordDt", "ordImei", "inUse" };
			StringBuilder o = new StringBuilder("{");
			for (int i = 0; i < keys.length; i++) {
				String val = cell(t, i);
				if (i == 1)
					val = AdminPhones.phoneStatusLabel(val);
				if (i == 2)
					val = AdminPhones.currentStatusLabel(val);
				o.append(i > 0 ? "," : "").append("\"").append(keys[i])
						.append("\":\"").append(jsEsc(val)).append("\"");
			}
			return o.append("}").toString();
		}

		if ("phoneAuditReport".equalsIgnoreCase(requestType)
				|| "phoneAuditApply".equalsIgnoreCase(requestType)) {
			try {
				String dateVal = rq(requestMap, "date");
				if ("phoneAuditApply".equalsIgnoreCase(requestType))
					return applyItineraryPhoneAudit(entityID, dateVal, loginUser);
				return itineraryPhoneAuditJson(entityID, dateVal, false,
						loginUser);
			} catch (Exception ex) {
				ex.printStackTrace();
				return "{\"ok\":false,\"mesg\":\"Phone audit is not ready. Apply WEB-INF/db/alter_daily_itineraries_phone.sql and re-upload Daily Itineraries.\",\"used\":0,\"notUsed\":0,\"unmatched\":0,\"usedList\":[],\"notUsedList\":[],\"unmatchedList\":[]}";
			}
		}

		if ("phoneStatusAdd".equalsIgnoreCase(requestType)) {
			String kind = rq(requestMap, "kind");
			String name = rq(requestMap, "name");
			if (!"phone".equals(kind) && !"current".equals(kind))
				return "<status>false</status><mesg>Invalid status type</mesg>";
			if (name.length() == 0 || name.length() > 80
					|| "__new".equalsIgnoreCase(name))
				return "<status>false</status><mesg>Enter a status name</mesg>";
			addStatusOption(kind, name, entityID, loginUser);
			return "{\"ok\":true,\"name\":\"" + jsEsc(name) + "\"}";
		}

		if ("phoneSave".equalsIgnoreCase(requestType)) {
			if (!recordID.matches("\\d+"))
				return "<status>false</status><mesg>Bad request</mesg>";
			String num = rq(requestMap, "num");
			if (num.length() == 0)
				return "<status>false</status><mesg>Phone Number is required</mesg>";
			String imei1 = rq(requestMap, "imei1");
			if (imei1.length() == 0)
				return "<status>false</status><mesg>IMEI 1 is required</mesg>";
			String endDt = rq(requestMap, "endDt");
			if (endDt.length() == 0)
				return "<status>false</status><mesg>Contract End Date is required</mesg>";
			String ps = AdminPhones.phoneStatusLabel(rq(requestMap, "ps"));
			String cs = AdminPhones.currentStatusLabel(rq(requestMap, "cs"));
			addStatusOption("phone", ps, entityID, loginUser);
			addStatusOption("current", cs, entityID, loginUser);
			String notes = rq(requestMap, "notes");
			if (AdminPhones.notesRequired(ps, cs) && notes.length() == 0)
				return "<status>false</status><mesg>Notes are required for Suspended, Damaged, or Lost</mesg>";

			String dupQry = "SELECT PHONEID FROM PHONES WHERE STATUS IN ("
					+ RecordStatus.ACTIVE + ", " + RecordStatus.INACTIVE
					+ ") AND ENTITYID=" + entityID + " AND PHONEID!="
					+ recordID
					+ db.getDataInCondQuery(num, "PHONENUMBER");
			List dup = db.selectAsList(dupQry, 1);
			if (dup.size() > 0)
				return "<status>false</status><mesg>Another phone already uses that number</mesg>";
			if (imei1.length() > 0) {
				dupQry = "SELECT PHONEID FROM PHONES WHERE STATUS IN ("
						+ RecordStatus.ACTIVE + ", " + RecordStatus.INACTIVE
						+ ") AND ENTITYID=" + entityID + " AND PHONEID!="
						+ recordID
						+ db.getDataInCondQuery(imei1, "SERIALNUMBER");
				dup = db.selectAsList(dupQry, 1);
				if (dup.size() > 0)
					return "<status>false</status><mesg>Another phone already uses that IMEI 1</mesg>";
			}

			List<String> upList = new ArrayList<String>();
			upList.add("UPDATE PHONES SET PHONENUMBER="
					+ db.getInsertDBValue(num) + ", PHONESTATUS="
					+ db.getInsertDBValue(ps) + ", CURRENTSTATUS="
					+ db.getInsertDBValue(cs) + ", SERIALNUMBER="
					+ db.getInsertDBValue(imei1) + ", DEVICEMAKE="
					+ db.getInsertDBValue(rq(requestMap, "make"))
					+ ", DEVICEMODEL="
					+ db.getInsertDBValue(rq(requestMap, "model"))
					+ ", IMEI2=" + db.getInsertDBValue(rq(requestMap, "imei2"))
					+ ", IMSI=" + db.getInsertDBValue(rq(requestMap, "imsi"))
					+ ", ICCID=" + db.getInsertDBValue(rq(requestMap, "iccid"))
					+ ", EID=" + db.getInsertDBValue(rq(requestMap, "eid"))
					+ ", REMARKS=" + db.getInsertDBValue(notes)
					+ ", AUDITEDDATE=" + db.getInsertDate(rq(requestMap, "audit"))
					+ ", CONTRACTENDDATE=" + db.getInsertDate(endDt)
					+ ", CONTRACTSTARTDATE="
					+ db.getInsertDate(rq(requestMap, "startDt"))
					+ ", DEVICEORDEREDDATE="
					+ db.getInsertDate(rq(requestMap, "ordDt"))
					+ ", DEVICEORDEREDIMEI="
					+ db.getInsertDBValue(rq(requestMap, "ordImei"))
					+ ", DEVICEINUSEDATE="
					+ db.getInsertDate(rq(requestMap, "inUse"))
					+ ", UPDATE_USER=" + db.getInsertDBValue(loginUser)
					+ ", UPDATE_DATE=" + db.getInsertSysdate()
					+ " WHERE PHONEID=" + recordID + " AND ENTITYID="
					+ entityID + " AND STATUS!=" + RecordStatus.DELETE);
			boolean result = db.batchInsert(upList);
			if (!result)
				return "<status>false</status><mesg>Save failed</mesg>";
			return "<status>true</status><mesg>Phone saved</mesg>";
		}

		return super.getAjaxRequestTypeResp(requestType, requestMap, loginUser,
				loginUserRoles, loginUserID, entityID);
	}

	public String applyItineraryPhoneAudit(String entityID, String dateVal,
			String loginUser) throws Exception {
		return itineraryPhoneAuditJson(entityID, dateVal, true, loginUser);
	}

	private String itineraryPhoneAuditJson(String entityID, String dateVal,
			boolean apply, String loginUser) throws Exception {
		String dateMdy = toMdyDate(dateVal);
		if (dateMdy.length() == 0)
			dateMdy = latestItineraryPhoneDate(entityID);
		if (dateMdy.length() == 0)
			return "{\"ok\":false,\"mesg\":\"Pick a date\",\"used\":0,\"notUsed\":0,\"unmatched\":0,\"usedList\":[],\"notUsedList\":[],\"unmatchedList\":[]}";

		int itinRows = countQry("SELECT COUNT(*) FROM DAILY_ITINERARIES WHERE STATUS="
				+ RecordStatus.ACTIVE + " AND ENTITYID=" + entityID
				+ db.getDateCondTypeQuery(db.EQUALS_TO, "ITINARARYDATE",
						dateMdy));

		Set<String> usedDigits = itineraryPhoneDigits(entityID, dateMdy);
		Map<String, String[]> invByDigits = inventoryPhonesByDigits(entityID);

		List<String[]> usedList = new ArrayList<String[]>();
		List<String[]> notUsedList = new ArrayList<String[]>();
		List<String[]> unmatchedList = new ArrayList<String[]>();
		Set<String> matchedDigits = new HashSet<String>();

		for (String d : usedDigits) {
			String[] inv = invByDigits.get(d);
			if (inv == null) {
				unmatchedList.add(new String[] { "", d });
			} else {
				usedList.add(new String[] { inv[0], inv[1] });
				matchedDigits.add(d);
			}
		}

		for (Map.Entry<String, String[]> e : invByDigits.entrySet()) {
			if (matchedDigits.contains(e.getKey()))
				continue;
			String[] inv = e.getValue();
			String cs = AdminPhones.currentStatusLabel(inv[3]).toLowerCase();
			if ("damaged".equals(cs) || "lost".equals(cs))
				continue;
			notUsedList.add(new String[] { inv[0], inv[1] });
		}

		String mesg;
		boolean ok = true;
		if (itinRows == 0) {
			ok = false;
			mesg = "No itineraries loaded for that date";
		} else if (usedDigits.isEmpty()) {
			ok = false;
			mesg = "Itineraries for that date have no phone numbers. Re-upload the Daily Itineraries Excel.";
		} else {
			mesg = usedList.size() + " on road, " + notUsedList.size()
					+ " not used, " + unmatchedList.size() + " unmatched";
		}

		if (apply && usedDigits.size() > 0) {
			List<String> batch = new ArrayList<String>();
			batch.add("UPDATE phone_audit SET STATUS=" + RecordStatus.DELETE
					+ ", UPDATE_USER=" + db.getInsertDBValue(loginUser)
					+ ", UPDATE_DATE=" + db.getInsertSysdate()
					+ " WHERE STATUS!=" + RecordStatus.DELETE + " AND ENTITYID="
					+ entityID + " AND SOURCE=" + db.getInsertDBValue("itinerary")
					+ db.getDateCondTypeQuery(db.EQUALS_TO, "AUDIT_DATE",
							dateMdy));
			addAuditRows(batch, entityID, dateMdy, loginUser, "Used", usedList);
			addAuditRows(batch, entityID, dateMdy, loginUser, "Not Used",
					notUsedList);
			addAuditRows(batch, entityID, dateMdy, loginUser, "Unmatched",
					unmatchedList);

			for (String[] row : usedList) {
				String[] inv = invByDigits.get(AdminPhones.digits10(row[1]));
				if (inv == null)
					inv = findInv(invByDigits, row[0]);
				if (inv == null)
					continue;
				String setCs = "";
				if (AdminPhones.canAuditFlipCurrent(inv[3]))
					setCs = ", CURRENTSTATUS=" + db.getInsertDBValue("In Use");
				batch.add("UPDATE PHONES SET AUDITEDDATE="
						+ db.getInsertDate(dateMdy) + setCs + ", UPDATE_USER="
						+ db.getInsertDBValue(loginUser) + ", UPDATE_DATE="
						+ db.getInsertSysdate() + " WHERE PHONEID=" + inv[0]
						+ " AND ENTITYID=" + entityID + " AND STATUS!="
						+ RecordStatus.DELETE);
			}
			for (String[] row : notUsedList) {
				String[] inv = findInv(invByDigits, row[0]);
				if (inv == null)
					continue;
				String setCs = "";
				if (AdminPhones.canAuditFlipCurrent(inv[3]))
					setCs = ", CURRENTSTATUS="
							+ db.getInsertDBValue("Not Used");
				batch.add("UPDATE PHONES SET AUDITEDDATE="
						+ db.getInsertDate(dateMdy) + setCs + ", UPDATE_USER="
						+ db.getInsertDBValue(loginUser) + ", UPDATE_DATE="
						+ db.getInsertSysdate() + " WHERE PHONEID=" + inv[0]
						+ " AND ENTITYID=" + entityID + " AND STATUS!="
						+ RecordStatus.DELETE);
			}
			db.batchInsert(batch);
		}

		StringBuilder o = new StringBuilder();
		o.append("{\"ok\":").append(ok ? "true" : "false");
		o.append(",\"applied\":").append(apply && usedDigits.size() > 0 ? "true" : "false");
		o.append(",\"date\":\"").append(jsEsc(dateMdy)).append("\"");
		o.append(",\"dateIso\":\"").append(jsEsc(mdyToIso(dateMdy))).append("\"");
		o.append(",\"itinRows\":").append(itinRows);
		o.append(",\"used\":").append(usedList.size());
		o.append(",\"notUsed\":").append(notUsedList.size());
		o.append(",\"unmatched\":").append(unmatchedList.size());
		o.append(",\"mesg\":\"").append(jsEsc(mesg)).append("\",");
		jsonPhoneArr(o, "usedList", usedList);
		o.append(",");
		jsonPhoneArr(o, "notUsedList", notUsedList);
		o.append(",");
		jsonPhoneArr(o, "unmatchedList", unmatchedList);
		o.append("}");
		return o.toString();
	}

	private String[] findInv(Map<String, String[]> invByDigits, String phoneId) {
		if (phoneId == null || phoneId.length() == 0)
			return null;
		for (String[] inv : invByDigits.values()) {
			if (phoneId.equals(inv[0]))
				return inv;
		}
		return null;
	}

	private void addAuditRows(List<String> batch, String entityID,
			String dateMdy, String loginUser, String result,
			List<String[]> rows) {
		for (int i = 0; i < rows.size(); i++) {
			String id = rows.get(i)[0];
			String num = rows.get(i)[1];
			String phoneIdSql = id != null && id.matches("\\d+") ? id : "NULL";
			batch.add("INSERT INTO phone_audit (ENTITYID, PHONEID, PHONENUMBER, "
					+ "AUDIT_DATE, AUDIT_RESULT, SOURCE, CREATE_USER, CREATE_DATE, STATUS) VALUES ("
					+ entityID + ", " + phoneIdSql + ", "
					+ db.getInsertDBValue(num) + ", "
					+ db.getInsertDate(dateMdy) + ", "
					+ db.getInsertDBValue(result) + ", "
					+ db.getInsertDBValue("itinerary") + ", "
					+ db.getInsertDBValue(loginUser) + ", "
					+ db.getInsertSysdate() + ", " + RecordStatus.ACTIVE + ")");
		}
	}

	private Set<String> itineraryPhoneDigits(String entityID, String dateMdy)
			throws Exception {
		Set<String> digits = new LinkedHashSet<String>();
		List rows = db.selectAsList(
				"SELECT PHONENUMBER FROM DAILY_ITINERARIES WHERE STATUS="
						+ RecordStatus.ACTIVE + " AND ENTITYID=" + entityID
						+ db.getDateCondTypeQuery(db.EQUALS_TO, "ITINARARYDATE",
								dateMdy),
				1);
		for (int i = 0; i < rows.size(); i++) {
			List t = (List) rows.get(i);
			String d = AdminPhones.digits10(cell(t, 0));
			if (d.length() > 0)
				digits.add(d);
		}
		return digits;
	}

	private Map<String, String[]> inventoryPhonesByDigits(String entityID)
			throws Exception {
		Map<String, String[]> map = new LinkedHashMap<String, String[]>();
		List rows = db.selectAsList(
				"SELECT PHONEID, PHONENUMBER, PHONESTATUS, CURRENTSTATUS FROM PHONES WHERE STATUS!="
						+ RecordStatus.DELETE + " AND ENTITYID=" + entityID,
				4);
		for (int i = 0; i < rows.size(); i++) {
			List t = (List) rows.get(i);
			String d = AdminPhones.digits10(cell(t, 1));
			if (d.length() == 0 || map.containsKey(d))
				continue;
			map.put(d, new String[] { cell(t, 0), cell(t, 1), cell(t, 2),
					cell(t, 3) });
		}
		return map;
	}

	private String latestItineraryPhoneDate(String entityID) throws Exception {
		List rows = db.selectAsList(
				"SELECT " + db.getSelectDate("MAX(ITINARARYDATE)")
						+ " FROM DAILY_ITINERARIES WHERE STATUS="
						+ RecordStatus.ACTIVE + " AND ENTITYID=" + entityID
						+ " AND IFNULL(PHONENUMBER,'')<>''",
				1);
		if (rows.isEmpty())
			return "";
		return cell((List) rows.get(0), 0);
	}

	private int countQry(String sql) throws Exception {
		List rows = db.selectAsList(sql, 1);
		if (rows.isEmpty())
			return 0;
		try {
			return Integer.parseInt(cell((List) rows.get(0), 0));
		} catch (Exception ex) {
			return 0;
		}
	}

	private String toMdyDate(String v) {
		if (v == null)
			return "";
		v = v.trim();
		if (v.matches("\\d{4}-\\d{2}-\\d{2}"))
			return v.substring(5, 7) + "/" + v.substring(8, 10) + "/"
					+ v.substring(0, 4);
		if (v.matches("\\d{1,2}/\\d{1,2}/\\d{4}"))
			return v;
		return "";
	}

	private String mdyToIso(String mdy) {
		if (mdy == null || mdy.length() < 8)
			return "";
		String[] p = mdy.split("/");
		if (p.length != 3)
			return "";
		String mm = p[0].length() == 1 ? "0" + p[0] : p[0];
		String dd = p[1].length() == 1 ? "0" + p[1] : p[1];
		return p[2] + "-" + mm + "-" + dd;
	}

	private void jsonPhoneArr(StringBuilder o, String key, List<String[]> rows) {
		o.append("\"").append(key).append("\":[");
		for (int i = 0; i < rows.size(); i++) {
			if (i > 0)
				o.append(",");
			o.append("{\"id\":\"").append(jsEsc(rows.get(i)[0]))
					.append("\",\"num\":\"").append(jsEsc(rows.get(i)[1]))
					.append("\"}");
		}
		o.append("]");
	}

	private void ensurePhoneStatusOptions(String entityID) throws Exception {
		if (entityID == null || !entityID.matches("\\d+"))
			return;
		String[][] seeds = { { "phone", "Active" }, { "phone", "Suspended" },
				{ "current", "In Use" }, { "current", "Not Used" },
				{ "current", "Damaged" }, { "current", "Lost" } };
		for (int i = 0; i < seeds.length; i++)
			addStatusOption(seeds[i][0], seeds[i][1], entityID, "seed");
	}

	private List statusOptionNames(String entityID, String kind)
			throws Exception {
		List names = new ArrayList();
		if (entityID == null || !entityID.matches("\\d+"))
			return names;
		List rows = db.selectAsList(
				"SELECT STATUS_NAME FROM phone_status_option WHERE STATUS=0 AND KIND="
						+ db.getInsertDBValue(kind) + " AND ENTITYID="
						+ entityID + " ORDER BY PHONE_STATUS_OPTIONID",
				1);
		for (int i = 0; i < rows.size(); i++) {
			List t = (List) rows.get(i);
			String n = t.get(0) == null ? "" : t.get(0).toString().trim();
			if (n.length() > 0 && !names.contains(n))
				names.add(n);
		}
		return names;
	}

	private void addStatusOption(String kind, String name, String entityID,
			String loginUser) throws Exception {
		if (name == null)
			return;
		String n = name.trim();
		if (n.length() == 0 || n.length() > 80 || "__new".equalsIgnoreCase(n))
			return;
		if (!"phone".equals(kind) && !"current".equals(kind))
			return;
		if (entityID == null || !entityID.matches("\\d+"))
			return;
		List<String> ins = new ArrayList<String>();
		ins.add("INSERT IGNORE INTO phone_status_option (ENTITYID, KIND, "
				+ "STATUS_NAME, CREATE_USER, CREATE_DATE, STATUS) VALUES ("
				+ entityID + ", " + db.getInsertDBValue(kind) + ", "
				+ db.getInsertDBValue(n) + ", "
				+ db.getInsertDBValue(loginUser == null ? "" : loginUser)
				+ ", " + db.getInsertSysdate() + ", 0)");
		db.batchInsert(ins);
	}

	private String remainingDaysValue(String endMdy, String startMdy) {
		java.util.Date end = parseMdy(endMdy);
		if (end == null)
			return "";
		java.util.Calendar cal = java.util.Calendar.getInstance();
		cal.set(java.util.Calendar.HOUR_OF_DAY, 0);
		cal.set(java.util.Calendar.MINUTE, 0);
		cal.set(java.util.Calendar.SECOND, 0);
		cal.set(java.util.Calendar.MILLISECOND, 0);
		long days = Math.round(
				(end.getTime() - cal.getTimeInMillis()) / 86400000.0);
		return String.valueOf(days);
	}

	private java.util.Date parseMdy(String v) {
		if (v == null || v.trim().length() == 0)
			return null;
		try {
			java.text.SimpleDateFormat f = new java.text.SimpleDateFormat(
					"MM/dd/yyyy");
			f.setLenient(false);
			return f.parse(v.trim());
		} catch (Exception ex) {
			return null;
		}
	}

	private String rq(Map<String, String> requestMap, String key) {
		String v = requestMap.get(key) == null ? "" : requestMap.get(key).trim();
		return v.replace("''", "'");
	}

	private String cell(List t, int i) {
		if (t == null || i >= t.size() || t.get(i) == null)
			return "";
		return t.get(i).toString().trim();
	}

	private String jsEsc(String s) {
		if (s == null)
			return "";
		StringBuilder b = new StringBuilder();
		for (int i = 0; i < s.length(); i++) {
			char c = s.charAt(i);
			if (c == '"')
				b.append("\\\"");
			else if (c == '\\')
				b.append("\\\\");
			else if (c == '\n' || c == '\r')
				b.append(' ');
			else if (c == '<')
				b.append("\\u003C");
			else if (c >= 32)
				b.append(c);
		}
		return b.toString();
	}
}
