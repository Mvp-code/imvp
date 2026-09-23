package com.dataobjects;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import com.beans.AdminConfiguration;
import com.beans.DAStatus;
import com.beans.ErrorBean;
import com.beans.MainBean;
import com.beans.SearchBean;
import com.util.RecordStatus;
import com.util.SubmitType;

public class DAStatusDAO extends MVPGDAO {

	DAStatus bean = new DAStatus();

	public boolean updateScheduleStatus(String scheduleDate, String loginUser,
			String entityID) {

		if (scheduleDate.length() > 0) {
			String subQry = "SELECT DISTINCT EMPLOYEEID FROM DACHECKIN WHERE STATUS!="
					+ RecordStatus.DELETE + " AND ENTITYID=" + entityID
					+ db.getDateCondTypeQuery(db.EQUALS_TO, "CLOCKINTIME",
							scheduleDate);

			String selQry = "SELECT DISTINCT DACONFIRMATIONID FROM DACONFIRMATION WHERE STATUS="
					+ RecordStatus.ACTIVE + " AND ENTITYID=" + entityID
					+ " AND EMPLOYEEID NOT IN (" + subQry + ") "
					+ db.getDateCondTypeQuery(db.EQUALS_TO, "SCHEDULEDATE",
							scheduleDate)
					+ db.getDataNotLikeCondQuery("No block", "CONFIRMATION");

			boolean result = false;
			try {
				String daStatusIDs = db.selectById(selQry);
				if (daStatusIDs.length() > 0) {
					String upQry = "UPDATE DACONFIRMATION SET CONFIRMATION="
							+ db.getInsertAppendDBValue("CONFIRMATION",
									"- No block")
							+ " WHERE DACONFIRMATIONID IN (" + daStatusIDs
							+ ")";
					result = db.update(upQry);
				}

				// FIX (reversible flag): a DA who now HAS a check-in for this
				// date must not stay marked "- No block". The append above was
				// one-way, which hid checked-in DAs (e.g. flagged by an earlier
				// re-run) from the default DA Confirmation view.
				selQry = "SELECT DISTINCT DACONFIRMATIONID FROM DACONFIRMATION WHERE STATUS="
						+ RecordStatus.ACTIVE + " AND ENTITYID=" + entityID
						+ " AND EMPLOYEEID IN (" + subQry + ") "
						+ db.getDateCondTypeQuery(db.EQUALS_TO, "SCHEDULEDATE",
								scheduleDate)
						+ " AND CONFIRMATION LIKE '%No block%'";
				daStatusIDs = db.selectById(selQry);
				if (daStatusIDs.length() > 0) {
					String upQry = "UPDATE DACONFIRMATION SET CONFIRMATION="
							+ "TRIM(REPLACE(CONFIRMATION, ' - No block', ''))"
							+ " WHERE DACONFIRMATIONID IN (" + daStatusIDs
							+ ")";
					result = db.update(upQry);
				}
				return result;
			} catch (Exception ex) {
				ex.printStackTrace();
			}
		}

		return false;
	}

	public boolean updateRecords(List transList, String loginUser,
			String entityID) throws Exception {

		List<String> upList = new ArrayList<String>();
		for (int i = 0; i < transList.size(); i++) {
			List tempList = (ArrayList) transList.get(i);
			String recordID = tempList.get(0) == null ? ""
					: tempList.get(0).toString().trim();
			String recordStatus = tempList.get(1) == null ? ""
					: tempList.get(1).toString().trim();
			String confirmedBy = tempList.get(2) == null ? ""
					: tempList.get(2).toString().trim();
			String comments = tempList.get(3) == null ? ""
					: tempList.get(3).toString().trim();

			String upQry = "UPDATE DACONFIRMATION SET CONFIRMATION="
					+ db.getInsertDBValue(recordStatus) + ", CONFIRMEDBY="
					+ db.getInsertDBValue(confirmedBy) + ", COMMENTS="
					+ db.getInsertDBValue(comments) + ", UPDATE_USER="
					+ db.getInsertDBValue(loginUser) + ", UPDATE_DATE="
					+ db.getInsertSysdate() + " WHERE STATUS="
					+ RecordStatus.ACTIVE + " AND ENTITYID=" + entityID
					+ db.getIDInCondQuery(recordID, "DACONFIRMATIONID");
			upList.add(upQry);
		}

		if (upList.size() > 0)
			return db.batchInsert(upList);

		return false;
	}

	@Override
	public SearchBean searchRecords(SearchBean searchBean, String recordID,
			String loginUser, String loginUserRoles, String loginUserID,
			String entityID) throws Exception {

		if (searchBean.getSelectedType().length() > 0) {
			int submitType = Integer.parseInt(searchBean.getSelectedType());
			if (submitType == SubmitType.UPDATE_CONFIRM) {
				boolean result = updateRecords(searchBean.getTransList(),
						loginUser, entityID);
				searchBean.setErrorBean(getErrorType(result, submitType,
						bean.getDisplayName()));

			} else if (submitType == SubmitType.DELETE) {

				List<String> upList = new ArrayList<String>();
				upList.add(buildStatusQry("DACONFIRMATION", "DACONFIRMATIONID",
						searchBean.getSelectedValues(), RecordStatus.DELETE,
						loginUser));

				if (upList.size() > 0) {
					boolean result = db.batchInsert(upList);
					searchBean.setErrorBean(getErrorType(result, submitType,
							bean.getDisplayName()));
				}
			}
		}

		List<String> labelsList = new ArrayList<String>();
		labelsList.add("Schedule Date");
		labelsList.add("Employee");
		labelsList.add("SMS");
		labelsList.add("Respone");
		labelsList.add("Comments");
		labelsList.add("Confirmed By");
		labelsList.add("Status");

		searchBean.setWidthColumns(new int[] { 8, 14, 12, 20, 18, 14, 14 });

		searchBean.setDisplayName(bean.getDisplayName() + "s");

		searchBean.setController(bean.getController());

		String currentDate = db.getCurrentDate();
		/* default any empty date to today — never dump the whole history */
		if (searchBean.getSrhFromDate() == null || searchBean.getSrhFromDate().trim().length() == 0)
			searchBean.setSrhFromDate(currentDate);
		if (searchBean.getSrhToDate() == null || searchBean.getSrhToDate().trim().length() == 0)
			searchBean.setSrhToDate(currentDate);

		// updateScheduleStatus(currentDate, loginUserID, entityID);

		String condQry = db.getDateCondQuery(searchBean.getSrhFromDate(),
				searchBean.getSrhToDate(), "A.SCHEDULEDATE");

		condQry += db.getIDInCondQuery(searchBean.getSrhEmployeeID(),
				"A.EMPLOYEEID");

		if (searchBean.getSrhStatus().length() == 0) {
			searchBean.setSrhStatus("Not Confirmed,Available");
		}

		if ("All".equalsIgnoreCase(searchBean.getSrhStatus()))
			searchBean.setSrhStatus("");

		condQry += db.getDataInCondQuery(searchBean.getSrhStatus(),
				"A.CONFIRMATION", ",");

		searchBean.setColumnSortName(
				searchBean.getColumnSortName().replaceAll("2", "9"));

		String selQry = "SELECT DACONFIRMATIONID, "
				+ db.getSelectDateTime("A.SCHEDULEDATE") + ", "
				+ db.getConcat(
						new String[] { "B.FULLNAME", "' - '", "C.MOBILE" })
				+ ", 1, 2, A.COMMENTS, " + "A.CONFIRMEDBY, A.CONFIRMATION, "
				+ db.getSelectDateFormat("A.SCHEDULEDATE",
						db.ORACLE_YYYYMMDDHH24MISS)
				+ " FROM DACONFIRMATION A, EMPLOYEE B, CONTACT C "
				+ "WHERE A.EMPLOYEEID=B.EMPLOYEEID AND "
				+ "B.CONTACTID=C.CONTACTID AND C.STATUS=" + RecordStatus.ACTIVE
				+ " AND B.STATUS=" + RecordStatus.ACTIVE
				+ " AND A.STATUS=" + RecordStatus.ACTIVE + " AND A.ENTITYID="
				+ entityID + condQry
				+ " AND A.DACONFIRMATIONID=(SELECT MIN(D.DACONFIRMATIONID)"
				+ " FROM DACONFIRMATION D JOIN EMPLOYEE E"
				+ " ON E.EMPLOYEEID=D.EMPLOYEEID WHERE D.STATUS="
				+ RecordStatus.ACTIVE + " AND D.ENTITYID=A.ENTITYID"
				+ " AND DATE(D.SCHEDULEDATE)=DATE(A.SCHEDULEDATE)"
				+ " AND (D.EMPLOYEEID=A.EMPLOYEEID"
				+ " OR (IFNULL(B.TRANSPORTERID,'')<>'' AND"
				+ " UPPER(TRIM(IFNULL(E.TRANSPORTERID,'')))="
				+ "UPPER(TRIM(B.TRANSPORTERID)))))";
		selQry += getOrderByQry(searchBean, "3");

		searchBean.setColumnSortName(
				searchBean.getColumnSortName().replaceAll("9", "2"));

		List resultList = db.selectAsList(selQry, 9);
		if (resultList.size() > 0) {

			SMSDAO smsDAO = new SMSDAO();
			String ids = getIndexedDataFromList(resultList, 0, ",");
			List allUsersList = getAdminDataList(
					enumSuggestorTypes.allUsers.toString(), "", "", entityID,
					true);
			Map _usersMap = getMap(allUsersList);

			Map<String, String> _smsMap = smsDAO
					.getSMSSentMap(bean.getController(), ids, entityID);
			List replySMSList = smsDAO.getSMSReplyMap(bean.getController(), ids,
					entityID);
			Map<String, List> _replyMap = getGroupByIDListMap(replySMSList, 0);

			for (int i = 0; i < resultList.size(); i++) {
				List tempList = (ArrayList) resultList.get(i);
				String id = tempList.get(0) == null ? ""
						: tempList.get(0).toString().trim();
				String scheduleDate = tempList.get(1) == null ? ""
						: tempList.get(1).toString().trim();
				String employeeName = tempList.get(2) == null ? ""
						: tempList.get(2).toString().trim();
				String smsStatus = tempList.get(3) == null ? ""
						: tempList.get(3).toString().trim();
				String replyMesg = tempList.get(4) == null ? ""
						: tempList.get(4).toString().trim();
				String comments = tempList.get(5) == null ? ""
						: tempList.get(5).toString().trim();
				String confirmedBy = tempList.get(6) == null ? ""
						: tempList.get(6).toString().trim();
				String recordStatus = tempList.get(7) == null ? ""
						: tempList.get(7).toString().trim();

				smsStatus = _smsMap.get(id) == null ? ""
						: _smsMap.get(id).toString().trim();
				smsStatus = smsStatus.replaceAll("queued", "Sent");

				if (smsStatus.contains("Sent"))
					employeeName = "<span class='text-success'>" + employeeName
							+ "</span>";
				else if (smsStatus.length() > 0)
					employeeName = "<span class='text-danger'>" + employeeName
							+ "</span>";

				replyMesg = "";
				if (_replyMap.get(id) != null) {
					List replyList = _replyMap.get(id);
					for (int j = 0; j < replyList.size(); j++) {
						List tempRow = (ArrayList) replyList.get(j);
						String dateTime = getListData(tempRow, 1);
						String mesg = getListData(tempRow, 2);
						String dataMesg = dateTime + "  " + mesg;
						if (replyMesg.length() > 0)
							replyMesg += "<BR>";
						replyMesg += dataMesg;
					}
				}

				if (confirmedBy.length() > 0)
					confirmedBy = _usersMap.get(confirmedBy) == null
							? confirmedBy
							: _usersMap.get(confirmedBy).toString().trim();

				tempList.set(2, employeeName);
				tempList.set(3, smsStatus);
				tempList.set(4, replyMesg);
				tempList.set(6, confirmedBy);
				resultList.set(i, tempList);
			}

			List dispatchersList = getAdminDataList(
					enumSuggestorTypes.dispatchers.toString(), "", "",
					entityID);
			Map _dispatcherMap = getMap(dispatchersList);

			Map transMap = new HashMap();
			transMap.put("_dispatcherMap", _dispatcherMap);
			transMap.put("autoSMS", getAutoSMSSetting(entityID));
			searchBean.setTransMap(transMap);

			searchBean.setDisplaySMSBtn(isProperties(
					AdminConfiguration.enumCategorys.SMS.toString(), entityID));

		}

		/*-
		Map requestMap = new HashMap();
		List emojiList = getEmojiDataList();
		requestMap.put("emojiList", emojiList);
		searchBean.setTransMap(requestMap);
		*/

		searchBean.setLabelsList(labelsList);
		searchBean.setDataList(resultList);
		searchBean.setSearchFiltersArray(
				new String[] { "Date Range", "Employee", "Status" });

		return searchBean;
	}

	public List getEmojiDataList() throws Exception {
		List resultList = new ArrayList();
		String selQry = "SELECT TXT, EMOJITEXT FROM EMOJI_TEST";
		resultList = db.selectAsList(selQry, 2);
		System.out.println("getEmojiDataList :: " + resultList);
		return resultList;

	}

	@Override
	public Object[] createRecord(MainBean mainBean, String loginUser,
			String loginUserRoles, String loginUserID, String entityID)
			throws Exception {

		bean = (DAStatus) mainBean;
		ErrorBean errorType = new ErrorBean();
		boolean result = false;

		int status = bean.getStatus().length() == 0 ? RecordStatus.ACTIVE
				: Integer.parseInt(bean.getStatus());
		String newIDs = "", existIDs = "";
		List<String> insList = new ArrayList<String>();
		for (int i = 0; i < bean.getTransList().size(); i++) {
			List tempList = (ArrayList) bean.getTransList().get(i);
			String employeeID = getListData(tempList, 0);
			String comments = getListData(tempList, 1);

			String tempID = "";
			Object[] returnObj = buildMainQry(bean.getScheduleDate(),
					bean.getScheduleTime(), employeeID, bean.getStation(),
					comments, "", bean.getRecordStatus(), loginUser, entityID,
					insList);
			insList = (List<String>) returnObj[0];
			tempID = (String) returnObj[1];
			if (tempID.length() > 0) {
				if (existIDs.length() > 0)
					existIDs += ",";
				existIDs += tempID;
			}

			tempID = (String) returnObj[2];
			if (tempID.length() > 0) {
				if (newIDs.length() > 0)
					newIDs += ",";
				newIDs += tempID;
			}
		}

		boolean result1 = db.batchInsert(insList);
		if (result1)
			result = true;

		if (result && status == RecordStatus.POST) {
			if (newIDs.length() > 0) {

				Map<String, String> requestMap = new HashMap<String, String>();
				requestMap.put("selRecordIDs", newIDs);

				new SMSDAO().sendSMS(bean.getController(), requestMap,
						loginUser, entityID);

			}
		}

		errorType = getErrorType(result, SubmitType.CREATE,
				bean.getDisplayName());

		if (existIDs.length() > 0) {
			String selQry = "SELECT "
					+ db.getConcat(
							new String[] { "B.FULLNAME", "' - '", "C.MOBILE" })
					+ " FROM DACONFIRMATION A, EMPLOYEE B, CONTACT C "
					+ "WHERE A.EMPLOYEEID=B.EMPLOYEEID AND "
					+ "B.CONTACTID=C.CONTACTID AND C.STATUS="
					+ RecordStatus.ACTIVE + " AND A.STATUS="
					+ RecordStatus.ACTIVE + " AND A.ENTITYID=" + entityID
					+ " AND A.DACONFIRMATIONID IN (" + existIDs + ")";
			String existName = db.selectById(selQry);
			System.out.println("existName :: " + existName + " :: " + selQry);

			errorType.setType(ErrorBean.enumTypes.notice.toString());
			if (errorType.getMesg().length() > 0)
				errorType.setMesg(
						errorType.getMesg() + "<BR>Already exist " + existName);
			else
				errorType.setMesg("Already exist " + existName);
		}

		return new Object[] { "", errorType };
	}

	public Object[] buildMainQry(String scheduleDate, String scheduleTime,
			String employeeID, String station, String comments,
			String confirmedBy, String recordStatus, String loginUser,
			String entityID, List<String> insList) {

		String recordID = "";
		String existID = "";
		if (scheduleDate.length() > 10) {
			if (scheduleTime.length() == 0)
				scheduleTime = scheduleDate.substring(10);
			scheduleDate = scheduleDate.substring(0, 10).trim();
		}

		String scheduleDateTime = scheduleDate + " " + scheduleTime;

		String condQry = db.getDateCondQuery(scheduleDate, scheduleDate,
				"SCHEDULEDATE");

		condQry += db.getIDInCondQuery(employeeID, "EMPLOYEEID");

		String selQry = "SELECT DACONFIRMATIONID FROM DACONFIRMATION "
				+ "WHERE STATUS=" + RecordStatus.ACTIVE + " AND ENTITYID="
				+ entityID + condQry + " ORDER BY 1";

		try {
			String transporterID = "";
			if (employeeID != null && employeeID.trim().length() > 0)
				transporterID = db.selectById(
						"SELECT IFNULL(TRANSPORTERID,'') FROM EMPLOYEE WHERE EMPLOYEEID="
								+ employeeID);
			if (transporterID == null)
				transporterID = "";
			if (transporterID.trim().length() > 0) {
				selQry = "SELECT C.DACONFIRMATIONID FROM DACONFIRMATION C "
						+ "JOIN EMPLOYEE E ON E.EMPLOYEEID=C.EMPLOYEEID "
						+ "WHERE C.STATUS=" + RecordStatus.ACTIVE
						+ " AND C.ENTITYID=" + entityID
						+ db.getDateCondQuery(scheduleDate, scheduleDate,
								"C.SCHEDULEDATE")
						+ " AND (C.EMPLOYEEID=" + employeeID
						+ " OR UPPER(TRIM(IFNULL(E.TRANSPORTERID,'')))=UPPER(TRIM("
						+ db.getInsertDBValue(transporterID.trim()) + ")))"
						+ " ORDER BY (C.EMPLOYEEID=" + employeeID
						+ ") DESC, C.DACONFIRMATIONID";
			}
			recordID = db.selectById(selQry);
			if (recordID.length() == 0) {
				// Confirmed,Not Confirmed,Available
				if (recordStatus.length() == 0)
					recordStatus = "Not Confirmed";

				recordID = db.getNextIDValue("DACONFIRMATIONID");
				String insQry = "INSERT INTO DACONFIRMATION ("
						+ "DACONFIRMATIONID, ENTITYID, SCHEDULEDATE,"
						+ " EMPLOYEEID, STATION, COMMENTS, CONFIRMEDBY, "
						+ "CONFIRMATION, CREATE_USER, CREATE_DATE, STATUS) VALUES ("
						+ recordID + ", " + entityID + ", "
						+ db.getInsertDateTime(scheduleDateTime) + ", "
						+ employeeID + ", " + db.getInsertDBValue(station)
						+ ", " + db.getInsertDBValue(comments) + ", "
						+ db.getInsertDBValue(confirmedBy) + ", "
						+ db.getInsertDBValue(recordStatus) + ", "
						+ db.getInsertDBValue(loginUser) + ", "
						+ db.getInsertSysdate() + ", " + RecordStatus.ACTIVE
						+ ")";
				insList.add(insQry);
			} else {
				existID = recordID;
				insList.add("UPDATE DACONFIRMATION SET EMPLOYEEID="
						+ employeeID + ", UPDATE_USER="
						+ db.getInsertDBValue(loginUser) + ", UPDATE_DATE="
						+ db.getInsertSysdate() + " WHERE DACONFIRMATIONID="
						+ existID);
				recordID = "";
			}
			String keepId = existID.length() > 0 ? existID : recordID;
			closePersonDayConfirmations(keepId, employeeID, scheduleDate,
					loginUser, entityID, insList);

		} catch (Exception ex) {
			ex.printStackTrace();
		}

		return new Object[] { insList, existID, recordID };
	}

	public void closeConfirmationsForCheckin(String daCheckinID,
			String loginUser, String entityID, List<String> upList) {
		if (daCheckinID == null || !daCheckinID.matches("\\d+"))
			return;
		try {
			String employeeID = db.selectById(
					"SELECT EMPLOYEEID FROM DACHECKIN WHERE DACHECKINID="
							+ daCheckinID);
			String scheduleDate = db.selectById("SELECT "
					+ db.getSelectDate("CLOCKINTIME")
					+ " FROM DACHECKIN WHERE DACHECKINID=" + daCheckinID);
			closePersonDayConfirmations("", employeeID, scheduleDate,
					loginUser, entityID, upList);
		} catch (Exception ex) {
			ex.printStackTrace();
		}
	}

	public void closePersonDayConfirmations(String keepConfirmationID,
			String employeeID, String scheduleDate, String loginUser,
			String entityID, List<String> upList) {
		if (employeeID == null || !employeeID.matches("\\d+")
				|| scheduleDate == null || scheduleDate.trim().length() == 0)
			return;
		if (upList == null)
			return;
		try {
			String keepClause = "";
			if (keepConfirmationID != null
					&& keepConfirmationID.matches("\\d+"))
				keepClause = " AND C.DACONFIRMATIONID<>" + keepConfirmationID;
			String transporterID = db.selectById(
					"SELECT IFNULL(TRANSPORTERID,'') FROM EMPLOYEE WHERE EMPLOYEEID="
							+ employeeID);
			if (transporterID == null)
				transporterID = "";
			String personClause = "C.EMPLOYEEID=" + employeeID;
			if (transporterID.trim().length() > 0)
				personClause = "(" + personClause
						+ " OR UPPER(TRIM(IFNULL(E.TRANSPORTERID,'')))=UPPER(TRIM("
						+ db.getInsertDBValue(transporterID.trim()) + ")))";
			upList.add("UPDATE DACONFIRMATION C JOIN EMPLOYEE E "
					+ "ON E.EMPLOYEEID=C.EMPLOYEEID SET C.STATUS="
					+ RecordStatus.DELETE + ", C.UPDATE_USER="
					+ db.getInsertDBValue(loginUser) + ", C.UPDATE_DATE="
					+ db.getInsertSysdate()
					+ " WHERE C.STATUS=" + RecordStatus.ACTIVE
					+ " AND C.ENTITYID=" + entityID
					+ db.getDateCondQuery(scheduleDate, scheduleDate,
							"C.SCHEDULEDATE")
					+ keepClause + " AND " + personClause);
		} catch (Exception ex) {
			ex.printStackTrace();
		}
	}

	@Override
	public DAStatus fetchRecord(String recordID, String loginUser,
			String loginUserRoles, String loginUserID, String entityID,
			int submitType) throws Exception {

		String selQry = "SELECT DACONFIRMATIONID, ENTITYID, "
				+ db.getSelectDate("SCHEDULEDATE") + ", "
				+ db.getSelectTime("SCHEDULEDATE")
				+ ", EMPLOYEEID, STATION, COMMENTS, CONFIRMEDBY, "
				+ "CONFIRMATION, CREATE_USER, "
				+ db.getSelectDateTime("CREATE_DATE") + ", UPDATE_USER, "
				+ db.getSelectDateTime("UPDATE_DATE")
				+ ", STATUS, 0 FROM DACONFIRMATION WHERE DACONFIRMATIONID="
				+ recordID;

		List resultList = new ArrayList();
		if (recordID.length() > 0)
			resultList = db.selectAsList(selQry,
					bean.getBeanAttributes().size());

		bean = (DAStatus) setListValuesToBean(bean, bean.getBeanAttributes(),
				resultList);

		if (bean.getEmployeeID().length() > 0)
			bean.setEmployeeName(getTableColumnData("FULLNAME", "EMPLOYEE",
					"EMPLOYEEID", bean.getEmployeeID()));

		if (submitType == SubmitType.CREATE) {
			bean.setScheduleDate(db.getCurrentDate());
			bean.setRecordStatus("Available");
			bean.setDisplaySMSBtn(isProperties(
					AdminConfiguration.enumCategorys.SMS.toString(), entityID));
		}

		return bean;
	}

	@Override
	public String getAjaxRequestTypeResp(String requestType,
			Map<String, String> requestMap, String loginUser,
			String loginUserRoles, String loginUserID, String entityID)
			throws Exception {

		String xmlMesg = "";
		if ("updateStatus".equalsIgnoreCase(requestType)
				|| "saveRows".equalsIgnoreCase(requestType)) {
			boolean result = true;
			if ("saveRows".equalsIgnoreCase(requestType)) {
				String ids = requestMap.get("selRecordIDs") == null ? ""
						: requestMap.get("selRecordIDs").toString().trim();
				String[] idArr = ids.split("[,;]");
				for (int i = 0; i < idArr.length; i++) {
					String id = idArr[i].trim();
					if (!id.matches("\\d+"))
						continue;
					if (!patchConfirmationRow(requestMap, id, loginUser, true))
						result = false;
				}
			} else {
				String recordID = requestMap.get("recordID") == null ? ""
						: requestMap.get("recordID").toString().trim();
				result = patchConfirmationRow(requestMap, recordID, loginUser,
						false);
			}
			xmlMesg = buildXML("status", result + "", new StringBuffer()) + "";

		} else if ("sendSMS".equalsIgnoreCase(requestType)) {
			xmlMesg = new SMSDAO().sendSMS(bean.getController(), requestMap,
					loginUser, entityID);

		} else if ("toggleAutoSMS".equalsIgnoreCase(requestType)) {
			// Flip DAStatus_AutoSMS between Y and N in PROPERTY table.
			// Pattern: set existing row INACTIVE, insert new row with toggled value.
			String category = AdminConfiguration.enumCategorys.SMS.toString();
			String propName = "DAStatus_AutoSMS";
			String selQry = "SELECT PROPERTYID, VALUE FROM PROPERTY WHERE STATUS="
					+ RecordStatus.ACTIVE + " AND ENTITYID=" + entityID
					+ " AND CATEGORY='" + category + "' AND NAME='" + propName + "'";
			List existList = db.selectAsList(selQry, 2);
			String currentVal = "N";
			String existingID = "";
			if (existList != null && existList.size() > 0) {
				List row = (ArrayList) existList.get(0);
				existingID = row.get(0) == null ? "" : row.get(0).toString().trim();
				currentVal  = row.get(1) == null ? "N" : row.get(1).toString().trim();
			}
			String newVal = "Y".equalsIgnoreCase(currentVal) ? "N" : "Y";
			List<String> upList = new ArrayList<String>();
			if (existingID.length() > 0) {
				upList.add(buildStatusQry("PROPERTY", "PROPERTYID", existingID,
						RecordStatus.INACTIVE, loginUser));
			}
			// Insert new row with toggled value
			String[] ai = db.getAutoIncrementArray("PROPERTYID");
			String ins = "INSERT INTO PROPERTY (";
			if (ai != null) ins += ai[0];
			ins += "ENTITYID, CATEGORY, NAME, VALUE, CREATE_USER, CREATE_DATE, STATUS) VALUES (";
			if (ai != null) ins += ai[1];
			ins += entityID + ", " + db.getInsertDBValue(category) + ", "
					+ db.getInsertDBValue(propName) + ", "
					+ db.getInsertDBValue(newVal) + ", "
					+ db.getInsertDBValue(loginUser) + ", "
					+ db.getInsertSysdate() + ", " + RecordStatus.ACTIVE + ")";
			upList.add(ins);
			boolean ok = db.batchInsert(upList);
			xmlMesg = "<status>" + ok + "</status><autoSMS>" + (ok ? newVal : currentVal) + "</autoSMS>";
		}

		return xmlMesg;
	}

	private String blankToken(String v) {
		if (v == null)
			return "";
		if ("__BLANK__".equals(v))
			return "";
		return v;
	}

	private boolean patchConfirmationRow(Map<String, String> requestMap,
			String recordID, String loginUser, boolean fromSaveRows)
			throws Exception {
		if (recordID == null || !recordID.matches("\\d+"))
			return false;
		String statusKey = fromSaveRows ? "st_" + recordID : "recordStatus";
		String byKey = fromSaveRows ? "by_" + recordID : "confirmedBy";
		String cmtKey = fromSaveRows ? "c_" + recordID : "comments";
		boolean hasStatus = requestMap.containsKey(statusKey);
		boolean hasBy = requestMap.containsKey(byKey);
		boolean hasCmt = requestMap.containsKey(cmtKey);
		if (!hasStatus && !hasBy && !hasCmt)
			return false;
		StringBuilder set = new StringBuilder();
		if (hasStatus)
			set.append("CONFIRMATION=")
					.append(db.getInsertDBValue(blankToken(
							requestMap.get(statusKey))));
		if (hasBy) {
			if (set.length() > 0)
				set.append(", ");
			set.append("CONFIRMEDBY=").append(db.getInsertDBValue(
					blankToken(requestMap.get(byKey))));
		}
		if (hasCmt) {
			if (set.length() > 0)
				set.append(", ");
			set.append("COMMENTS=").append(db.getInsertDBValue(
					blankToken(requestMap.get(cmtKey))));
		}
		set.append(", UPDATE_USER=").append(db.getInsertDBValue(loginUser));
		set.append(", UPDATE_DATE=").append(db.getInsertSysdate());
		String upQry = "UPDATE DACONFIRMATION SET " + set
				+ " WHERE STATUS=" + RecordStatus.ACTIVE
				+ db.getIDInCondQuery(recordID, "DACONFIRMATIONID");
		return db.executeDml(upQry) == null;
	}

	/** Read DAStatus_AutoSMS setting for the entity. Returns "Y" or "N". */
	public String getAutoSMSSetting(String entityID) {
		try {
			String selQry = "SELECT VALUE FROM PROPERTY WHERE STATUS="
					+ RecordStatus.ACTIVE + " AND ENTITYID=" + entityID
					+ " AND CATEGORY='" + AdminConfiguration.enumCategorys.SMS.toString()
					+ "' AND NAME='DAStatus_AutoSMS'";
			String val = db.selectById(selQry);
			return "Y".equalsIgnoreCase(val) ? "Y" : "N";
		} catch (Exception e) {
			return "N";
		}
	}

}
// build 2026-07-03 fix: reversible No-block flag
