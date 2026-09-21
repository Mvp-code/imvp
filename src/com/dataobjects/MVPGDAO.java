package com.dataobjects;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import com.beans.CommonUpload;
import com.beans.MainBean;
import com.beans.SearchBean;
import com.util.RecordStatus;

public class MVPGDAO extends MainDAO {

	MVPGDB db = new MVPGDB();

	public enum enumSuggestorTypes {
		incidentCategories, incidentTypes, employees, transporterEmployees,
		dispatchers, allUsers, coachingOwner, followupDeliveryAssociate,
		vehicles, vehiclesDetails, gasCards, usStatesList, employeeNotAsUsers,
		formsTemplate, stations
	}

	public String getOrderByQry(SearchBean searchBean, String defaultOrderBy) {

		String orderByQry = "";
		if (searchBean.getColumnSortName().length() > 0) {
			if (searchBean.getColumnSortOrder().length() > 0) {
				orderByQry += " ORDER BY " + searchBean.getColumnSortName()
						+ " " + searchBean.getColumnSortOrder() + " ";
			} else {
				orderByQry += " ORDER BY " + searchBean.getColumnSortName();
			}
		} else {
			orderByQry += " ORDER BY " + defaultOrderBy;
		}

		return orderByQry;
	}

	public List getAdminDataList(String suggestorType, String inVal,
			String notInVal, String entityID) throws Exception {

		return getAdminDataList(suggestorType, inVal, notInVal, entityID,
				false);
	}

	public List getAdminDataList(String suggestorType, String inVal,
			String notInVal, String entityID, boolean isAll) throws Exception {

		List resultList = new ArrayList();
		int numOfCols = 2;
		String selQry = "", condQry = "";
		switch (enumSuggestorTypes.valueOf(suggestorType)) {
		case formsTemplate:
			condQry += db.getIDInCondQuery(inVal, "FORMSTEMPLATEID");
			if (!isAll)
				condQry += " AND STATUS=" + RecordStatus.ACTIVE;

			selQry = "SELECT FORMSTEMPLATEID, FORMTYPE FROM "
					+ "FORMSTEMPLATE WHERE ENTITYID=" + entityID + condQry
					+ " ORDER BY 2 ";
			break;

		case incidentCategories:
			condQry += db.getIDInCondQuery(inVal, "INCIDENTCATEGORYID");
			condQry += db.getIDNotInCondQuery(notInVal, "INCIDENTCATEGORYID");
			if (isAll) {
			} else if (inVal.length() == 0)
				condQry += " AND STATUS=" + RecordStatus.ACTIVE;

			selQry = "SELECT INCIDENTCATEGORYID, DESCRIPTION FROM "
					+ "INCIDENTCATEGORY WHERE ENTITYID=" + entityID + condQry
					+ " ORDER BY 2 ";
			break;

		case incidentTypes:
			condQry += db.getIDInCondQuery(inVal, "INCIDENTTYPEID");
			condQry += db.getIDNotInCondQuery(notInVal, "INCIDENTTYPEID");
			if (isAll) {
			} else if (inVal.length() == 0)
				condQry += " AND STATUS=" + RecordStatus.ACTIVE;

			selQry = "SELECT INCIDENTTYPEID, TYPE FROM INCIDENTTYPE "
					+ "WHERE ENTITYID=" + entityID + condQry + " ORDER BY 2 ";
			break;

		case transporterEmployees:
			condQry += db.getIDInCondQuery(inVal, "EMPLOYEEID");
			condQry += db.getIDNotInCondQuery(notInVal, "EMPLOYEEID");
			if (isAll) {
			} else if (inVal.length() == 0)
				condQry += " AND REVIEW_STATUS=" + RecordStatus.ACTIVE
						+ " AND STATUS=" + RecordStatus.ACTIVE;

			selQry = "SELECT DISTINCT TRANSPORTERID, FULLNAME FROM EMPLOYEE "
					+ "WHERE ENTITYID=" + entityID + condQry + " ORDER BY 2 ";
			break;

		case employees:
			condQry += db.getIDInCondQuery(inVal, "EMPLOYEEID");
			condQry += db.getIDNotInCondQuery(notInVal, "EMPLOYEEID");
			if (isAll) {
			} else if (inVal.length() == 0)
				condQry += " AND REVIEW_STATUS=" + RecordStatus.ACTIVE
						+ " AND STATUS=" + RecordStatus.ACTIVE;

			selQry = "SELECT EMPLOYEEID, FULLNAME FROM EMPLOYEE "
					+ "WHERE ENTITYID=" + entityID + condQry + " ORDER BY 2 ";
			break;

		case employeeNotAsUsers:
			condQry = " AND EMPLOYEEID NOT IN (SELECT DISTINCT EMPLOYEEID "
					+ "FROM ENTITYUSERS WHERE EMPLOYEEID IS NOT NULL AND "
					+ "STATUS=" + RecordStatus.ACTIVE + " AND ENTITYID="
					+ entityID + ")";
			if (isAll) {
			} else if (inVal.length() == 0)
				condQry += " AND REVIEW_STATUS=" + RecordStatus.ACTIVE
						+ " AND STATUS=" + RecordStatus.ACTIVE;

			selQry = "SELECT EMPLOYEEID, FULLNAME FROM EMPLOYEE "
					+ "WHERE ENTITYID=" + entityID + condQry + " ORDER BY 2 ";
			break;

		case followupDeliveryAssociate:
			selQry = "SELECT DISTINCT A.TRANSPORTERID, "
					+ "A.DELIVERYASSOCIATE FROM DASHBOARD_OVERVIEW A, "
					+ "COACHING_FOLLOWUP B WHERE "
					+ "A.DASHBOARD_OVERVIEWID=B.DASHBOARD_OVERVIEWID AND A.STATUS="
					+ RecordStatus.ACTIVE + " AND A.ENTITYID=" + entityID
					+ condQry + " ORDER BY 2 ";
			break;

		case coachingOwner:
			numOfCols = 1;
			condQry += db.getIDInCondQuery(inVal, "EMPLOYEEID");
			condQry += db.getIDNotInCondQuery(notInVal, "EMPLOYEEID");
			if (isAll) {
			} else if (inVal.length() == 0)
				condQry += " AND REVIEW_STATUS=" + RecordStatus.ACTIVE
						+ " AND STATUS=" + RecordStatus.ACTIVE;

			selQry = "SELECT FULLNAME FROM EMPLOYEE WHERE ROLE=1 AND ENTITYID="
					+ entityID + condQry + " ORDER BY 1 ";
			break;

		case dispatchers:
			condQry += db.getIDInCondQuery(inVal, "A.EMPLOYEEID");
			condQry += db.getIDNotInCondQuery(notInVal, "A.EMPLOYEEID");
			if (isAll) {
			} else if (inVal.length() == 0)
				condQry += " AND A.REVIEW_STATUS=" + RecordStatus.ACTIVE
						+ " AND A.STATUS=" + RecordStatus.ACTIVE;

			selQry = "SELECT B.USERNAME, A.FULLNAME FROM "
					+ "EMPLOYEE A, ENTITYUSERS B WHERE "
					+ "A.EMPLOYEEID=B.EMPLOYEEID AND A.ROLE=1 "
					+ "AND A.ENTITYID=" + entityID + condQry + " ORDER BY 2 ";
			break;

		case allUsers:
			selQry = "SELECT B.USERNAME, A.FULLNAME FROM "
					+ "EMPLOYEE A, ENTITYUSERS B WHERE "
					+ "A.EMPLOYEEID=B.EMPLOYEEID AND A.STATUS="
					+ RecordStatus.ACTIVE + " AND B.STATUS="
					+ RecordStatus.ACTIVE + " AND A.ENTITYID=" + entityID
					+ " ORDER BY 2 ";
			break;

		case vehicles:
			condQry += db.getIDInCondQuery(inVal, "VEHICLEID");
			condQry += db.getIDNotInCondQuery(notInVal, "VEHICLEID");
			if (isAll) {
			} else if (inVal.length() == 0)
				condQry += " AND OPERATIONALSTATUS=" + RecordStatus.ACTIVE
						+ " AND STATUS=" + RecordStatus.ACTIVE;

			selQry = "SELECT VEHICLEID, VEHICLENUMBER FROM VEHICLE "
					+ "WHERE ENTITYID=" + entityID + condQry + " ORDER BY 2 ";
			break;

		case vehiclesDetails:
			condQry += db.getIDInCondQuery(inVal, "VEHICLEID");
			condQry += db.getIDNotInCondQuery(notInVal, "VEHICLEID");
			condQry += db.getIDNotInCondQuery(notInVal, "VEHICLEID");
			if (isAll) {
			} else if (inVal.length() == 0)
				condQry += " AND OPERATIONALSTATUS=" + RecordStatus.ACTIVE
						+ " AND STATUS=" + RecordStatus.ACTIVE;

			selQry = "SELECT VEHICLEID, "
					+ db.getConcat(new String[] { "VEHICLENUMBER", "##",
							"SERVICETIER" })
					+ " FROM VEHICLE WHERE ENTITYID=" + entityID + condQry
					+ " ORDER BY 2 ";
			break;

		case gasCards:
			condQry += db.getIDInCondQuery(inVal, "GASCARDID");
			condQry += db.getIDNotInCondQuery(notInVal, "GASCARDID");
			if (isAll) {
			} else if (inVal.length() == 0)
				condQry += " AND STATUS!=" + RecordStatus.DELETE;

			selQry = "SELECT GASCARDID, CARDIDENTIFIER FROM "
					+ "GASCARDS WHERE ENTITYID=" + entityID + condQry
					+ " ORDER BY 2 ";
			break;
		}

		if (selQry.length() > 0)
			resultList = db.selectAsList(selQry, numOfCols);

		return resultList;
	}

	public String getSuggestorTypeData(String suggestorType,
			String suggestorValue, String entityID) throws Exception {

		List resultList = getAdminDataList(suggestorType, "", "", entityID,
				false);

		String xmlMesg = getSuggextorData(resultList, suggestorValue);

		if ("usStatesList".equalsIgnoreCase(suggestorType)) {
			xmlMesg = getSuggextorData(getUSStates(), suggestorValue);
		}

		return xmlMesg;
	}

	public String getAjaxRequestTypeResp(String requestType,
			Map<String, String> requestMap, String loginUser,
			String loginUserRoles, String loginUserID, String entityID)
			throws Exception {

		return "";
	}

	public Map<String, String> getAdminDataMap(String suggestorType,
			String suggestorValue, String entityID) throws Exception {
		return getAdminDataMap(suggestorType, suggestorValue, entityID, false);
	}

	public Map<String, String> getAdminDataMap(String suggestorType,
			String suggestorValue, String entityID, boolean isAll)
			throws Exception {

		List resultList = getAdminDataList(suggestorType, suggestorValue, "",
				entityID, isAll);

		Map<String, String> _hMap = getMap(resultList);

		return _hMap;
	}

	public String buildStatusQry(String tableName, String keyName,
			String keyValue, int status, String loginUser) {

		String upQry = "UPDATE " + tableName + " SET UPDATE_USER="
				+ db.getInsertDBValue(loginUser) + ", UPDATE_DATE="
				+ db.getInsertSysdate() + ", STATUS="
				+ db.getInsertDBValue(status) + " WHERE STATUS!="
				+ RecordStatus.DELETE + " AND " + keyName + " IN (" + keyValue
				+ ") ";

		return upQry;
	}

	public String getTableColumnData(String selColumnName, String tableName,
			String keyName, String keyValue) throws Exception {

		return getTableColumnData(selColumnName, tableName, keyName, keyValue,
				"");
	}

	public String getTableColumnData(String selColumnName, String tableName,
			String keyName, String keyValue, String condQry) throws Exception {

		if (keyValue.length() > 0) {
			String selQry = "SELECT " + selColumnName + " FROM " + tableName
					+ " WHERE " + keyName + "=" + keyValue + condQry;

			return db.selectById(selQry);
		} else {
			return "";
		}
	}

	public MainBean setListValuesToBean(MainBean mainBean,
			List<String> beanAttributesList, List result) {

		try {
			mainBean = (MainBean) setListValuesToMainBean(mainBean,
					beanAttributesList, result);

			if (mainBean.getCreateUser().length() > 0
					&& !"testUser".equalsIgnoreCase(mainBean.getCreateUser())) {
				String userName = getFirstNameAsUserName(
						mainBean.getCreateUser(), mainBean.getEntityID());
				mainBean.setCreateUser(userName);
			}
			if (mainBean.getUpdateUser().length() > 0
					&& !"testUser".equalsIgnoreCase(mainBean.getUpdateUser())) {
				String userName = getFirstNameAsUserName(
						mainBean.getUpdateUser(), mainBean.getEntityID());
				mainBean.setUpdateUser(userName);
			}

		} catch (Exception ex) {
			ex.printStackTrace();
		}
		return mainBean;
	}

	public String getFirstNameAsUserName(String userName, String entityID)
			throws Exception {

		if (userName.length() > 0) {
			String selQry = "SELECT A.FULLNAME FROM EMPLOYEE A, ENTITYUSERS B "
					+ "WHERE A.EMPLOYEEID=B.EMPLOYEEID "
					+ db.getDataInCondQuery(userName, "USERNAME");
			String returnVal = db.selectById(selQry);
			if (returnVal.length() == 0)
				returnVal = userName;
			return returnVal;
		} else
			return userName;
	}

	public String checkDuplicate(String tableName, String primaryKeyName,
			String primaryKeyVal, String entityID, String condQry)
			throws Exception {

		String recordID = "";
		String selQry = "SELECT " + primaryKeyName + " FROM " + tableName
				+ " WHERE STATUS!=" + RecordStatus.DELETE + " AND ENTITYID="
				+ entityID + condQry;
		if (primaryKeyVal.length() > 0)
			selQry += " AND " + primaryKeyName + "!=" + primaryKeyVal;

		List resultList = db.selectAsList(selQry, 1);
		if (resultList.size() > 0) {
			List tempList = (ArrayList) resultList.get(0);
			recordID = tempList.get(0) == null ? ""
					: tempList.get(0).toString().trim();
		}

		return recordID;
	}

	public boolean createAuditInfo(String resource, int event, String ipAddress,
			String additionalInfo, String loginUser, String entityID) {

		boolean result = true;
		try {
			String autoIncrementArray[] = db
					.getAutoIncrementArray("AUDITINFOID");
			additionalInfo = "";
			String insQry = "INSERT INTO AUDITINFO (";
			if (autoIncrementArray != null)
				insQry += autoIncrementArray[0];
			insQry += "ENTITYID, USERNAME, USERIPADDRESS, AUDITDATETIME, "
					+ "AUDITEVENT, RESOURCEPAGE, ADDITIONAL_INFO, STATUS) VALUES (";
			if (autoIncrementArray != null)
				insQry += autoIncrementArray[1];
			insQry += db.getInsertDBValue(entityID) + ", "
					+ db.getInsertDBValue(loginUser) + ", "
					+ db.getInsertDBValue(ipAddress) + ", "
					+ db.getInsertSysdate() + ", " + db.getInsertDBValue(event)
					+ ", " + db.getInsertDBValue(resource) + ", "
					+ db.getInsertDBValue(additionalInfo) + ", "
					+ RecordStatus.ACTIVE + ")";

			result = db.update(insQry);

		} catch (Exception ex) {
			ex.printStackTrace();
		}

		return result;
	}

	public SearchBean getSearchCounts(SearchBean searchBean, String entityID)
			throws Exception {

		List dataCountList = new ArrayList();
		if ("AdminVehicle".equalsIgnoreCase(searchBean.getController())) {

			String condQry = db.getIDInCondQuery(searchBean.getSrhStatus(),
					"OPERATIONALSTATUS");

			String selQry = "SELECT SERVICETIER, COUNT(SERVICETIER) FROM "
					+ "VEHICLE WHERE SERVICETIER IS NOT NULL AND ENTITYID="
					+ entityID + " AND STATUS!=" + RecordStatus.DELETE + condQry
					+ " GROUP BY SERVICETIER ORDER BY 1";
			List resultList = db.selectAsList(selQry, 2);
			for (int i = 0; i < resultList.size(); i++) {
				List tempList = (ArrayList) resultList.get(i);
				String label = getListData(tempList, 0);
				String value = getListData(tempList, 1);
				dataCountList = buildDataCNTList(label, value, dataCountList);
			}
			if (dataCountList.size() > 0) {
				dataCountList = buildDataCNTList("", "", dataCountList);
			}
			selQry = "SELECT PROVIDER, COUNT(PROVIDER) FROM "
					+ "VEHICLE WHERE PROVIDER IS NOT NULL AND ENTITYID="
					+ entityID + " AND STATUS!=" + RecordStatus.DELETE + condQry
					+ " GROUP BY PROVIDER ORDER BY 1";
			resultList = db.selectAsList(selQry, 2);
			for (int i = 0; i < resultList.size(); i++) {
				List tempList = (ArrayList) resultList.get(i);
				String label = getListData(tempList, 0);
				String value = getListData(tempList, 1);
				dataCountList = buildDataCNTList(label, value, dataCountList);
			}

		} else if ("AdminEmployee"
				.equalsIgnoreCase(searchBean.getController())) {

			String selQry = "SELECT REVIEW_STATUS, COUNT(REVIEW_STATUS) FROM "
					+ "EMPLOYEE WHERE REVIEW_STATUS IS NOT NULL AND ENTITYID="
					+ entityID + " AND STATUS!=" + RecordStatus.DELETE
					+ " GROUP BY REVIEW_STATUS ORDER BY 1";
			List resultList = db.selectAsList(selQry, 2);
			for (int i = 0; i < resultList.size(); i++) {
				List tempList = (ArrayList) resultList.get(i);
				String label = getListData(tempList, 0);
				String value = getListData(tempList, 1);

				label = RecordStatus.RecordStatus[Integer.parseInt(label)];
				dataCountList = buildDataCNTList(label, value, dataCountList);
			}

		} else if ("EmployeeTermination"
				.equalsIgnoreCase(searchBean.getController())) {

			String selQry = "SELECT TERMINATIONTYPE, COUNT(TERMINATIONTYPE) FROM "
					+ "EMPLOYEETERMINATION WHERE TERMINATIONTYPE IS NOT NULL AND ENTITYID="
					+ entityID + " AND STATUS!=" + RecordStatus.DELETE
					+ " GROUP BY TERMINATIONTYPE ORDER BY 1";
			List resultList = db.selectAsList(selQry, 2);
			for (int i = 0; i < resultList.size(); i++) {
				List tempList = (ArrayList) resultList.get(i);
				String label = getListData(tempList, 0);
				String value = getListData(tempList, 1);

				dataCountList = buildDataCNTList(label, value, dataCountList);
			}

		} else if ("EmployeeIncident"
				.equalsIgnoreCase(searchBean.getController())) {

			String condQry = db.getDateCondQuery(searchBean.getSrhFromDate(),
					searchBean.getSrhToDate(), "INCIDENTDATE");
			if (searchBean.getSrhStatus().length() > 0)
				condQry += db.getIDInCondQuery(searchBean.getSrhStatus(),
						"STATUS");
			else
				condQry += db.getIDInCondQuery(RecordStatus.ACTIVE + "",
						"STATUS");

			String selQry = "SELECT TYPEOFINCIDENT, COUNT(TYPEOFINCIDENT) FROM "
					+ "EMPLOYEEINCIDENT WHERE TYPEOFINCIDENT IS NOT NULL AND ENTITYID="
					+ entityID + condQry
					+ " GROUP BY TYPEOFINCIDENT ORDER BY 1";
			List resultList = db.selectAsList(selQry, 2);
			for (int i = 0; i < resultList.size(); i++) {
				List tempList = (ArrayList) resultList.get(i);
				String label = getListData(tempList, 0);
				String value = getListData(tempList, 1);

				dataCountList = buildDataCNTList(label, value, dataCountList);
			}
		} else if ("DAStatus".equalsIgnoreCase(searchBean.getController())) {

			String condQry = db.getDateCondQuery(searchBean.getSrhFromDate(),
					searchBean.getSrhToDate(), "SCHEDULEDATE");

			condQry += db.getIDInCondQuery(searchBean.getSrhEmployeeID(),
					"EMPLOYEEID");

			// condQry += db.getDataInCondQuery(searchBean.getSrhStatus(),
			// "CONFIRMATION", ",");

			String selQry = "SELECT CONFIRMATION, COUNT(CONFIRMATION) FROM "
					+ "DACONFIRMATION WHERE CONFIRMATION IS NOT NULL AND STATUS="
					+ RecordStatus.ACTIVE + " AND ENTITYID=" + entityID
					+ condQry + " GROUP BY CONFIRMATION ORDER BY 1";
			List resultList = db.selectAsList(selQry, 2);
			for (int i = 0; i < resultList.size(); i++) {
				List tempList = (ArrayList) resultList.get(i);
				String label = getListData(tempList, 0);
				String value = getListData(tempList, 1);

				dataCountList = buildDataCNTList(label, value, dataCountList);
			}

		} else if ("VehicleInspection"
				.equalsIgnoreCase(searchBean.getController())) {

			if (searchBean.getSrhFromDate()
					.equalsIgnoreCase(searchBean.getSrhToDate())) {
				String condQry = db.getDateCondQuery(
						searchBean.getSrhFromDate(), searchBean.getSrhToDate(),
						"INSPECTIONDATE");
				String selQry = "SELECT COUNT(VEHICLEINSPECTIONID) FROM "
						+ "VEHICLEINSPECTION WHERE ENTITYID=" + entityID
						+ " AND STATUS!=" + RecordStatus.DELETE + condQry;
				String total = db.selectById(selQry);
				total = total.length() == 0 ? "0" : total;
				dataCountList = buildDataCNTList("Total", total, dataCountList);

				selQry = "SELECT STATUS, COUNT(STATUS) FROM "
						+ "VEHICLEINSPECTION WHERE ENTITYID=" + entityID
						+ " AND STATUS!=" + RecordStatus.DELETE + condQry
						+ " GROUP BY STATUS ORDER BY 1";
				List resultList = db.selectAsList(selQry, 2);
				String label = "";
				for (int i = 0; i < resultList.size(); i++) {
					List tempList = (ArrayList) resultList.get(i);
					label = getListData(tempList, 0);
					String value = getListData(tempList, 1);

					label = RecordStatus.RecordStatus[Integer.parseInt(label)];
					if ("Posted".equalsIgnoreCase(label)) {
						label = "Completed";
					}
					dataCountList = buildDataCNTList(label, value,
							dataCountList);
				}
				if (resultList.size() == 0) {
					dataCountList = buildDataCNTList("Active", "0",
							dataCountList);
					dataCountList = buildDataCNTList("Completed", "0",
							dataCountList);

				} else if (resultList.size() == 1)
					dataCountList = buildDataCNTList("Completed", "0",
							dataCountList);

				dataCountList = buildDataCNTList("", "", dataCountList);

				// Parking
				condQry = db.getDateCondQuery(searchBean.getSrhFromDate(),
						searchBean.getSrhToDate(), "A.CLOCKOUTTIME");
				selQry = "SELECT A.PARKING, COUNT(A.PARKING) FROM "
						+ "DACHECKOUT A, DACHECKIN B WHERE "
						+ "A.DACHECKINID=B.DACHECKINID AND B.ENTITYID="
						+ entityID + " AND B.STATUS!=" + RecordStatus.DELETE
						+ condQry + " GROUP BY A.PARKING ORDER BY 1";
				resultList = db.selectAsList(selQry, 2);
				for (int i = 0; i < resultList.size(); i++) {
					List tempList = (ArrayList) resultList.get(i);
					label = getListData(tempList, 0);
					String value = getListData(tempList, 1);

					label = mainUtil.getValue(mainUtil.getParking(), label);
					dataCountList = buildDataCNTList("Parking " + label, value,
							dataCountList);
				}
				if (resultList.size() == 0) {
					dataCountList = buildDataCNTList("Parking Inside", "0",
							dataCountList);
					dataCountList = buildDataCNTList("Parking outside", "0",
							dataCountList);

				} else if (resultList.size() == 1) {
					if ("Outside".equalsIgnoreCase(label))
						label = "inside";
					else
						label = "Outside";

					dataCountList = buildDataCNTList("Parking " + label, "0",
							dataCountList);
				}
			}

		} else if ("Incident".equalsIgnoreCase(searchBean.getController())) {
			// Already present in search method
			dataCountList = searchBean.getDataCountList();

		} else if ("DACheckin".equalsIgnoreCase(searchBean.getController())) {

			String numOfRecords = getNumOfRecords("DACHECKIN",
					searchBean.getSrhFromDate(), searchBean.getSrhToDate(),
					entityID);
			dataCountList = buildDataCNTList("Total Checkins", numOfRecords,
					dataCountList);

		} else if ("DACheckout".equalsIgnoreCase(searchBean.getController())) {

			int totalCheckins = Integer.parseInt(
					getNumOfRecords("DACHECKIN", searchBean.getSrhFromDate(),
							searchBean.getSrhToDate(), entityID));
			int totalCheckouts = Integer.parseInt(
					getNumOfRecords("DACHECKOUT", searchBean.getSrhFromDate(),
							searchBean.getSrhToDate(), entityID));
			int totalPending = totalCheckins - totalCheckouts;

			dataCountList = buildDataCNTList("Total Checkins",
					totalCheckins + "", dataCountList);
			dataCountList = buildDataCNTList("Total Checkouts",
					totalCheckouts + "", dataCountList);
			dataCountList = buildDataCNTList("Pending", totalPending + "",
					dataCountList);

		}

		searchBean.setDataCountList(dataCountList);

		return searchBean;
	}

	public String getNumOfRecords(String tableName, String srhFromDate,
			String srhToDate, String entityID) throws Exception {

		String returnVal = "";
		String selQry = "";
		if (srhFromDate.equalsIgnoreCase(srhToDate)) {
			if ("DACHECKOUT".equalsIgnoreCase(tableName)) {
				String condQry = db.getDateCondQuery(srhFromDate, srhToDate,
						"A.CLOCKOUTTIME");

				selQry = "SELECT COUNT(A.DACHECKOUTID) FROM "
						+ "DACHECKOUT A, DACHECKIN B WHERE "
						+ "A.DACHECKINID=B.DACHECKINID AND A.STATUS!="
						+ RecordStatus.DELETE + " AND B.ENTITYID=" + entityID
						+ condQry;

			} else if ("DACHECKIN".equalsIgnoreCase(tableName)) {
				String condQry = db.getDateCondQuery(srhFromDate, srhToDate,
						"CLOCKINTIME");

				selQry = "SELECT COUNT(DACHECKINID) FROM DACHECKIN WHERE STATUS IN ("
						+ RecordStatus.ACTIVE + ", " + RecordStatus.POST + ", "
						+ RecordStatus.COMPLETED + ") AND ENTITYID=" + entityID
						+ condQry;
			}

			if (selQry.length() > 0)
				returnVal = db.selectById(selQry);
		}

		returnVal = returnVal.length() == 0 ? "0" : returnVal;

		return returnVal;
	}

	public List buildDataCNTList(String label, String value,
			List dataCountList) {

		List tempList = new ArrayList();
		tempList.add(label);
		tempList.add(value);
		dataCountList.add(tempList);
		return dataCountList;
	}

	public CommonUpload fetchUploadDetails(CommonUpload _bean,
			String loginUserID, String loginUserRoles, String loginUser,
			String entityID) throws Exception {

		if ("4".equalsIgnoreCase(loginUserRoles)) {
			String module = "Inspection";
			String employeeID = getTableColumnData("EMPLOYEEID", "ENTITYUSERS",
					"ENTITYUSERSID", loginUserID);
			String employeeName = "";
			if (employeeID.length() > 0) {
				employeeName = getTableColumnData("FULLNAME", "EMPLOYEE",
						"EMPLOYEEID", employeeID);
				String selQry = "SELECT A.VEHICLEINSPECTIONID, "
						+ "B.VEHICLENUMBER, A.VEHICLEID, "
						+ db.getSelectDateFormat("C.WAVE_TIME",
								db.ORACLE_HHSMISAM)
						+ ", C.DACHECKINID , A.DACOMMENTS FROM VEHICLEINSPECTION A, "
						+ "VEHICLE B, DACHECKIN C WHERE "
						+ "A.DACHECKINID=C.DACHECKINID AND "
						+ "A.VEHICLEID=B.VEHICLEID AND C.STATUS NOT IN ("
						+ RecordStatus.DELETE + ", " + RecordStatus.UNPOST
						+ ") "
						+ db.getDateCondTypeQuery(db.EQUALS_TO, "C.CLOCKINTIME")
						+ db.getIDInCondQuery(employeeID, "C.EMPLOYEEID");
				List resultList = db.selectAsList(selQry, 6);
				if (resultList.size() == 1) {
					List tempList = (ArrayList) resultList.get(0);
					String vehicleInspectionID = getListData(tempList, 0);
					String vehicleNum = getListData(tempList, 1);
					String vehicleID = getListData(tempList, 2);
					String waveTime = getListData(tempList, 3);
					String daCheckinID = getListData(tempList, 4);
					String daComments = getListData(tempList, 5);

					String parking = getTableColumnData("PARKING", "DACHECKOUT",
							"DACHECKINID", daCheckinID);
					String parkingDesc = mainUtil
							.getValue(mainUtil.getParking(), parking);

					String commonUploadsID = getTableColumnData(
							"COMMONUPLOADSID", "COMMONUPLOADS", "MODULEID",
							vehicleInspectionID,
							db.getDataInCondQuery(module, "MODULE"));

					_bean.setRecordID(commonUploadsID);
					_bean.setVehicleID(vehicleInspectionID);
					_bean.setParking(parking);
					_bean.setParkingDesc(parkingDesc);
					_bean.setVehicleNumber(vehicleNum);
					_bean.setWaveTime(waveTime);
					_bean.setDaCheckinID(daCheckinID);
					_bean.setDaComments(daComments);

					List uploadsList = getUploadsList(module,
							vehicleInspectionID, entityID);
					_bean.setUploadsList(uploadsList);
				}
			}
			_bean.setEmployeeName(employeeName);
			_bean.setEmployeeID(employeeID);
			_bean.setModule(module);

			if (employeeID.length() > 0) {
				List extraDaysList = getEmployeeExtraAvailDatesList(employeeID,
						entityID);
				List timeOffList = getEmployeeTimeOffList(employeeID, entityID);

				Map transMap = new HashMap();
				transMap.put("timeOffList", timeOffList);
				transMap.put("extraDaysList", extraDaysList);
				_bean.setTransMap(transMap);
			}

		} else if (_bean.getVehicleID().length() > 0) {

			String module = "Inspection";
			String selQry = "SELECT A.VEHICLEINSPECTIONID, "
					+ "B.VEHICLENUMBER, A.VEHICLEID, "
					+ db.getSelectDateFormat("C.WAVE_TIME", db.ORACLE_HHSMISAM)
					+ ", C.DACHECKINID , A.DACOMMENTS, C.EMPLOYEEID FROM VEHICLEINSPECTION A, "
					+ "VEHICLE B, DACHECKIN C WHERE "
					+ "A.DACHECKINID=C.DACHECKINID AND "
					+ "A.VEHICLEID=B.VEHICLEID AND A.VEHICLEINSPECTIONID="
					+ _bean.getVehicleID();
			List resultList = db.selectAsList(selQry, 7);
			if (resultList.size() == 1) {
				List tempList = (ArrayList) resultList.get(0);
				String vehicleInspectionID = getListData(tempList, 0);
				String vehicleNum = getListData(tempList, 1);
				String vehicleID = getListData(tempList, 2);
				String waveTime = getListData(tempList, 3);
				String daCheckinID = getListData(tempList, 4);
				String daComments = getListData(tempList, 5);
				String employeeID = getListData(tempList, 6);

				String parking = getTableColumnData("PARKING", "DACHECKOUT",
						"DACHECKINID", daCheckinID);
				String parkingDesc = mainUtil.getValue(mainUtil.getParking(),
						parking);

				String employeeName = getTableColumnData("FULLNAME", "EMPLOYEE",
						"EMPLOYEEID", employeeID);

				String commonUploadsID = getTableColumnData("COMMONUPLOADSID",
						"COMMONUPLOADS", "MODULEID", vehicleInspectionID,
						db.getDataInCondQuery(module, "MODULE"));

				_bean.setRecordID(commonUploadsID);
				_bean.setVehicleID(vehicleInspectionID);
				_bean.setParking(parking);
				_bean.setParkingDesc(parkingDesc);
				_bean.setVehicleNumber(vehicleNum);
				_bean.setWaveTime(waveTime);
				_bean.setDaCheckinID(daCheckinID);
				_bean.setDaComments(daComments);
				_bean.setEmployeeName(employeeName);
				_bean.setEmployeeID(employeeID);

				List uploadsList = getUploadsList(module, vehicleInspectionID,
						entityID);
				_bean.setUploadsList(uploadsList);
			}

		} else if (_bean.getEmployeeID().length() > 0) {
			_bean.setEmployeeName(getTableColumnData("FULLNAME", "EMPLOYEE",
					"EMPLOYEEID", _bean.getEmployeeID()));
		}

		return _bean;
	}

	public List getEmployeeExtraAvailDatesList(String employeeID,
			String entityID) throws Exception {

		String selQry = "SELECT EMPLOYEE_EXTRADAYSID, "
				+ db.getSelectDate("EXTRADAY") + ", STATUS, "
				+ db.getSelectDateFormat("EXTRADAY", db.ORACLE_YYYYSMMSDD)
				+ " FROM EMPLOYEE_EXTRADAYS WHERE STATUS=" + RecordStatus.ACTIVE
				+ db.getIDInCondQuery(employeeID, "EMPLOYEEID")
				+ db.getIDInCondQuery(entityID, "ENTITYID")
				+ db.getDateCondTypeQuery(db.GREATER_THAN_EQUALS, "EXTRADAY")
				+ " ORDER BY 4";

		List resultList = db.selectAsList(selQry, 4);

		return resultList;
	}

	public List getEmployeeTimeOffList(String employeeID, String entityID)
			throws Exception {

		String selQry = "SELECT EMPLOYEE_TIMEOFFID, "
				+ db.getSelectDate("START_DATE") + ", "
				+ db.getSelectDate("END_DATE") + ", REASON, "
				+ db.decodeStatus("STATUS",
						new int[] { RecordStatus.ACTIVE, RecordStatus.APPROVED,
								RecordStatus.REJECTED })
				+ ", REVIEWER, REVIEWERCOMMENTS, "
				+ db.getSelectDateTime("REVIEWEDON") + ", "
				+ db.getSelectDateFormat("START_DATE", db.ORACLE_YYYYSMMSDD)
				+ " FROM EMPLOYEE_TIMEOFF WHERE STATUS!=" + RecordStatus.DELETE
				+ db.getIDInCondQuery(employeeID, "EMPLOYEEID")
				+ db.getIDInCondQuery(entityID, "ENTITYID")
				+ db.getDateCondTypeQuery(db.GREATER_THAN_EQUALS, "START_DATE")
				+ " ORDER BY 9, 1";

		List resultList = db.selectAsList(selQry, 9);

		return resultList;
	}

	public List getUploadsList(String module, String moduleID, String entityID)
			throws Exception {

		List uploadsList = new ArrayList();
		module = module.replaceAll("VehicleInspection", "Inspection");
		module = module.replaceAll("AdminEmployee", "Employee");

		if (("Inspection".equalsIgnoreCase(module)
				|| "Employee".equalsIgnoreCase(module)
				|| "DACheckout".equalsIgnoreCase(module))
				&& moduleID.length() > 0) {

			String condQry = db.getDataInCondQuery(module, "A.MODULE");

			condQry += db.getIDInCondQuery(moduleID, "A.MODULEID");

			condQry += db.getIDInCondQuery(entityID, "A.ENTITYID");

			String selQry = "SELECT B.COMMONUPLOADSTRANSID, B.UPLOAD_NAME, "
					+ "B.UPLOADTYPE, B.COMMENTS, B.CREATE_USER, "
					+ db.getSelectDateTime("B.CREATE_DATE")
					+ ", B.STATUS FROM COMMONUPLOADS A, COMMONUPLOADSTRANS B WHERE "
					+ "A.COMMONUPLOADSID=B.COMMONUPLOADSID AND A.STATUS!="
					+ RecordStatus.DELETE + " AND B.STATUS!="
					+ RecordStatus.DELETE + condQry + " ORDER BY 1 DESC";

			uploadsList = db.selectAsList(selQry, 7);
			System.out.println("uploadsList :: " + uploadsList.size());
		}

		return uploadsList;
	}

	public boolean delteUploadRecord(String recordID, String loginUser)
			throws Exception {

		String upQry = buildStatusQry("COMMONUPLOADSTRANS",
				"COMMONUPLOADSTRANSID", recordID, RecordStatus.DELETE,
				loginUser);
		boolean result = db.update(upQry);
		return result;
	}

	public String getSMSID(String module, String moduleID, String toNumber,
			String messageStatus, String accountID, String entityID)
			throws Exception {

		String selQry = "SELECT SMSTRANSACTIONID FROM SMSTRANSACTION "
				+ "WHERE STATUS=" + RecordStatus.ACTIVE
				+ db.getDataInCondQuery(module, "MODULE")
				+ db.getIDInCondQuery(moduleID, "MODULEID")
				+ db.getDataInCondQuery(toNumber, "TONUMBER")
				+ db.getDataInCondQuery(messageStatus, "MESSAGESTATUS")
				+ db.getDataInCondQuery(accountID, "ACCOUNTID")
				+ db.getIDInCondQuery(entityID, "ENTITYID");

		return db.selectById(selQry);
	}

	public String[] getReplySMSID(String MessagingServiceSid, String fromNumber,
			String toNumber, String accountID) throws Exception {

		String selQry = "SELECT SMSTRANSACTIONID, ENTITYID, "
				+ "MODULE, MODULEID, EMPLOYEEID, "
				+ db.getSelectDate("TRANSACTIONDATE") + " FROM SMSTRANSACTION "
				+ "WHERE STATUS=" + RecordStatus.ACTIVE
				+ db.getDataInCondQuery(MessagingServiceSid,
						"MESSAGING_SERVICE_SID")
				+ db.getDataInCondQuery(fromNumber, "FROMNUMBER")
				+ db.getDataInCondQuery(toNumber, "TONUMBER")
				+ db.getDataInCondQuery(accountID, "ACCOUNTID")
				+ " ORDER BY 1 DESC";

		List resultList = db.selectAsList(selQry, 6);
		if (resultList.size() > 0) {
			List tempList = (ArrayList) resultList.get(0);
			String recordID = getListData(tempList, 0);
			String entityID = getListData(tempList, 1);
			String module = getListData(tempList, 2);
			String moduleID = getListData(tempList, 3);
			String employeeID = getListData(tempList, 4);
			String transcationDate = getListData(tempList, 5);

			return new String[] { recordID, entityID, module, moduleID,
					employeeID, transcationDate };
		}

		return null;
	}

	public List<String> buildSMSQry(String station, String module,
			String moduleID, String fromNumber, String toNumber,
			String employeeID, String accountID, String messageID,
			String transactionDate, String message, String messageStatus,
			String comments, String messageServiceSID, String loginUser,
			String entityID, List<String> insList) throws Exception {

		String autoIncrementArray[] = db
				.getAutoIncrementArray("SMSTRANSACTIONID");
		String insQry = "INSERT INTO SMSTRANSACTION (";
		if (autoIncrementArray != null)
			insQry += autoIncrementArray[0];
		insQry += "ENTITYID, STATION, MODULE, MODULEID, "
				+ "EMPLOYEEID, FROMNUMBER, TONUMBER, "
				+ "ACCOUNTID, MESSAGEID, TRANSACTIONDATE, "
				+ "MESSAGE, MESSAGESTATUS, COMMENTS, MESSAGING_SERVICE_SID, "
				+ "CREATE_USER, CREATE_DATE, STATUS) VALUES (";
		if (autoIncrementArray != null)
			insQry += autoIncrementArray[1];
		insQry += entityID + ", " + db.getInsertDBValue(station) + ", "
				+ db.getInsertDBValue(module) + ", "
				+ db.getInsertDBValue(moduleID) + ", "
				+ db.getInsertDBValue(employeeID) + ", "
				+ db.getInsertDBValue(fromNumber) + ", "
				+ db.getInsertDBValue(toNumber) + ", "
				+ db.getInsertDBValue(accountID) + ", "
				+ db.getInsertDBValue(messageID) + ", "
				+ db.getInsertDate(transactionDate) + ", "
				+ db.getInsertDBValue(message) + ", "
				+ db.getInsertDBValue(messageStatus) + ", "
				+ db.getInsertDBValue(comments) + ", "
				+ db.getInsertDBValue(messageServiceSID) + ", "
				+ db.getInsertDBValue(loginUser) + ", " + db.getInsertSysdate()
				+ ", " + RecordStatus.ACTIVE + ")";
		insList.add(insQry);

		return insList;
	}

	private String normalizeSmsReply(String body) {
		if (body == null)
			return "";
		String t = body.trim();
		t = t.replaceAll("^[\\s\\p{Punct}]+|[\\s\\p{Punct}]+$", "");
		t = java.text.Normalizer.normalize(t,
				java.text.Normalizer.Form.NFD);
		t = t.replaceAll("\\p{M}+", "");
		return t.toLowerCase(java.util.Locale.ROOT);
	}

	private boolean isConfirmedSmsReply(String normalized) {
		if (normalized.length() == 0)
			return false;
		String[] yes = { "confirmed", "ok", "okay", "okey", "yes", "thanks",
				"copy", "si", "confirmado" };
		for (int i = 0; i < yes.length; i++) {
			if (yes[i].equals(normalized))
				return true;
		}
		return false;
	}

	private String getReplyRecordStatus(String body) {

		String recordStatus = "Review"; // Default
		String emojiText = "";
		String normalized = normalizeSmsReply(body);
		if (isConfirmedSmsReply(normalized)) {
			recordStatus = "Confirmed";

		} else if ("no".equals(normalized)) {
			recordStatus = "Not Confirmed";

		} else if (body != null && (body.contains("👍") || body.contains("👍🏼"))) {
			emojiText = "thumbs up";
			recordStatus = "Confirmed";

		} else if (body != null && (body.contains("👌") || body.contains("👌🏼"))) {
			emojiText = "okay";
			recordStatus = "Confirmed";

		} else if (body != null && body.contains("✅")) {
			emojiText = "check mark button";
			recordStatus = "Confirmed";

		} else if (body != null && body.contains("☑️")) {
			emojiText = "ballot box with check";
			recordStatus = "Confirmed";
		}

		System.out.println("getReplyRecordStatus :: " + recordStatus + " :: "
				+ emojiText + " :: " + body);
		return recordStatus;
	}

	public boolean updateSMSReply(String messageID, String replyMesg,
			String comments, String dataArray[]) throws Exception {

		String smsID = dataArray[0];
		String entityID = dataArray[1];
		String module = dataArray[2];

		String loginUser = "superadmin";
		List insList = new ArrayList();
		boolean result = false;
		String transModule = "", transModuleID = "";
		System.out.println("updateSMSReply :: " + messageID + " :: " + replyMesg
				+ " :: " + comments);
		System.out.println(
				"dataArray :: " + smsID + " :: " + entityID + " :: " + module);
		String recordStatus = getReplyRecordStatus(replyMesg);

		if ("DACheckin".equalsIgnoreCase(module)) {
			String moduleID = dataArray[3];
			String employeeID = dataArray[4];
			String scheduleDate = dataArray[5];

			String selQry = "SELECT DACONFIRMATIONID, CONFIRMATION "
					+ "FROM DACONFIRMATION WHERE STATUS=" + RecordStatus.ACTIVE
					+ db.getIDInCondQuery(entityID, "ENTITYID")
					+ db.getIDInCondQuery(employeeID, "EMPLOYEEID")
					+ db.getDateCondTypeQuery(db.EQUALS_TO, "SCHEDULEDATE",
							scheduleDate);

			List resultList = db.selectAsList(selQry, 2);
			if (resultList.size() > 0) {
				List tempList = (ArrayList) resultList.get(0);
				String daStatusID = getListData(tempList, 0);

				String upQry = "UPDATE DACONFIRMATION SET CONFIRMATION="
						+ db.getInsertDBValue(recordStatus) + ", CONFIRMEDBY="
						+ db.getInsertDBValue("Employee") + ", COMMENTS="
						+ db.getInsertDBValue(replyMesg) + ", UPDATE_USER="
						+ db.getInsertDBValue(loginUser) + ", UPDATE_DATE="
						+ db.getInsertSysdate() + " WHERE STATUS="
						+ RecordStatus.ACTIVE + " AND ENTITYID=" + entityID
						+ db.getIDInCondQuery(daStatusID, "DACONFIRMATIONID");
				insList.add(upQry);

				transModule = "DAStatus";
				transModuleID = daStatusID;
			}

		} else if ("DAStatus".equalsIgnoreCase(module)) {
			String moduleID = dataArray[3];
			String employeeID = dataArray[4];
			String scheduleDate = dataArray[5];

			String upQry = "UPDATE DACONFIRMATION SET CONFIRMATION="
					+ db.getInsertDBValue(recordStatus) + ", CONFIRMEDBY="
					+ db.getInsertDBValue("Employee") + ", COMMENTS="
					+ db.getInsertDBValue(replyMesg) + ", UPDATE_USER="
					+ db.getInsertDBValue(loginUser) + ", UPDATE_DATE="
					+ db.getInsertSysdate() + " WHERE STATUS="
					+ RecordStatus.ACTIVE + " AND ENTITYID=" + entityID
					+ db.getIDInCondQuery(moduleID, "DACONFIRMATIONID");
			insList.add(upQry);

			transModule = module;
			transModuleID = moduleID;
		}

		String autoIncrementArray[] = db
				.getAutoIncrementArray("SMSTRANSACTIONTRANSID");
		String insQry = "INSERT INTO SMSTRANSACTIONTRANS (";
		if (autoIncrementArray != null)
			insQry += autoIncrementArray[0];
		insQry += "SMSTRANSACTIONID, MESSAGEID, REPLAYMSG, "
				+ "COMMENTS, MODULE, MODULEID, CREATE_USER, "
				+ "CREATE_DATE, STATUS) VALUES (";
		if (autoIncrementArray != null)
			insQry += autoIncrementArray[1];
		insQry += smsID + ", " + db.getInsertDBValue(messageID) + ", "
				+ db.getInsertDBValue(replyMesg) + ", "
				+ db.getInsertDBValue(comments) + ", "
				+ db.getInsertDBValue(transModule) + ", "
				+ db.getInsertDBValue(transModuleID) + ", "
				+ db.getInsertDBValue(loginUser) + ", " + db.getInsertSysdate()
				+ ", " + RecordStatus.ACTIVE + ")";
		insList.add(insQry);

		result = db.batchInsert(insList);

		return result;
	}

	public Map<String, List> getGroupByIDListMap(List dataList, int keyIndex)
			throws Exception {

		Map<String, List> _hMap = new HashMap<String, List>();
		List tempList = null;
		List transList = new ArrayList();
		String tempID = "";
		for (int i = 0; i < dataList.size(); i++) {
			tempList = (ArrayList) dataList.get(i);
			String id = tempList.get(keyIndex).toString().trim();
			if (!id.equalsIgnoreCase(tempID)) {
				if (i != 0 && transList.size() > 0) {
					_hMap.put(tempID, transList);
				}
				tempID = id;
				transList = new ArrayList();
			}
			transList.add(tempList);
		}

		if (transList.size() > 0) {
			_hMap.put(tempID, transList);
		}

		return _hMap;
	}

	public String getPropertyValue(String category, String propName,
			String entityID) throws Exception {

		return new AdminConfigurationDAO().getPropertyValue(category, propName,
				entityID);

	}

	public boolean isProperties(String category, String entityID) {

		return new AdminConfigurationDAO().isProperties(category, entityID);
	}
}
