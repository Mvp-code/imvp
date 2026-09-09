package com.dataobjects;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import com.beans.DACheckout;
import com.beans.ErrorBean;
import com.beans.MainBean;
import com.beans.SearchBean;
import com.beans.VehicleInspection;
import com.util.RecordStatus;
import com.util.SubmitType;

public class VehicleInspectionDAO extends MVPGDAO {

	VehicleInspection bean = new VehicleInspection();

	public boolean updateRecordsOld(String entityID) throws Exception {

		boolean result = true;
		int successCNT = 0, errorCNT = 0;
		String selQry = "SELECT VEHICLEINSPECTIONID, "
				+ db.getSelectDate("INSPECTIONDATE")
				+ ", VEHICLEID FROM VEHICLEINSPECTION WHERE ENTITYID="
				+ entityID + " AND STATUS!=" + RecordStatus.DELETE
				+ " AND DACHECKINID IS NULL ORDER BY 1 DESC";
		List resultList = db.selectAsList(selQry, 3);
		if (resultList.size() > 0) {
			selQry = "SELECT "
					+ db.getConcat(new String[] { "VEHICLEID", "'_'",
							db.getSelectDate("CLOCKINTIME") })
					+ ", DACHECKINID FROM DACHECKIN WHERE ENTITYID=" + entityID
					+ " AND STATUS NOT IN (" + RecordStatus.DELETE + ","
					+ RecordStatus.UNPOST + ")";

			List daCheckinList = db.selectAsList(selQry, 2);
			Map<String, String> _hMap = getMap(daCheckinList);

			for (int i = 0; i < resultList.size(); i++) {
				List tempList = (ArrayList) resultList.get(i);
				String id = getListData(tempList, 0);
				String inspectionDate = getListData(tempList, 1);
				String vehicleID = getListData(tempList, 2);
				String key = vehicleID + "_" + inspectionDate;
				String daCheckinID = _hMap.get(key) == null ? ""
						: _hMap.get(key);
				if (daCheckinID.length() > 0) {
					String upQry = "UPDATE VEHICLEINSPECTION SET DACHECKINID="
							+ db.getInsertDBValue(daCheckinID)
							+ " WHERE VEHICLEINSPECTIONID=" + id;
					if (db.update(upQry))
						successCNT++;
					else
						errorCNT++;
				}
			}
		}
		System.out.println("updateRecordsOld :: " + resultList.size() + " :: "
				+ successCNT + " :: " + errorCNT);

		return result;
	}

	@Override
	public SearchBean searchRecords(SearchBean searchBean, String recordID,
			String loginUser, String loginUserRoles, String loginUserID,
			String entityID) throws Exception {

		int submitType = SubmitType.SEARCH;
		if (searchBean.getSelectedType().length() > 0) {
			submitType = Integer.parseInt(searchBean.getSelectedType());
			if (submitType == SubmitType.UPDATE_CONFIRM) {
				if ("updateOld".equalsIgnoreCase(searchBean.getSrhType())) {
					boolean result = updateRecordsOld(entityID);
					searchBean.setErrorBean(getErrorType(result,
							SubmitType.UPDATE, bean.getDisplayName()));
				} else {
					boolean result = updatRecords(searchBean.getTransList(),
							loginUser, entityID);
					searchBean.setErrorBean(getErrorType(result,
							SubmitType.UPDATE, bean.getDisplayName()));
				}
			} else if (submitType == SubmitType.FINAL) {
				boolean result = true;
				if ("DACheckout".equalsIgnoreCase(searchBean.getSrhType())) {
					result = new DACheckoutDAO().postRecords(
							searchBean.getSelectedValues(),
							searchBean.getSrhValue2(), loginUser, entityID);

					searchBean.setErrorBean(getErrorType(result, submitType,
							new DACheckout().getDisplayName()));

				} else {
					result = postRecords(searchBean.getSelectedValues(),
							loginUser, entityID);

					searchBean.setErrorBean(getErrorType(result, submitType,
							bean.getDisplayName()));
				}
			}
		}

		List<String> labelsList = new ArrayList<String>();
		labelsList.add("Date");
		labelsList.add("Vehicle");
		labelsList.add("Parking");
		labelsList.add("Employee");
		labelsList.add("DA Comments");
		labelsList.add("Dispatcher Comments");
		labelsList.add("Checkout");
		labelsList.add("Status");

		searchBean.setWidthColumns(new int[] { 7, 14, 8, 14, 17, 17, 10, 8 });

		searchBean.setDisplayName(bean.getDisplayName() + "s / DA Checkout");

		searchBean.setController(bean.getController());

		String currentDate = db.getCurrentDate();
		if (!"yes".equalsIgnoreCase(searchBean.getSearchFilter())) {
			searchBean.setSrhFromDate(currentDate);
			searchBean.setSrhToDate(currentDate);
		}

		String condQry = db.getDateCondQuery(searchBean.getSrhFromDate(),
				searchBean.getSrhToDate(), "A.INSPECTIONDATE");

		condQry += db.getIDInCondQuery(searchBean.getSrhVehicleID(),
				"A.VEHICLEID");

		if ("4".equalsIgnoreCase(loginUserRoles)) {
			String employeeID = getTableColumnData("EMPLOYEEID", "ENTITYUSERS",
					"ENTITYUSERSID", loginUserID);
			condQry += db.getIDInCondQuery(employeeID, "B.EMPLOYEEID");

		} else {
			// Default Active records to UPDATE screen in search screen
			if (submitType == SubmitType.SEARCH) {
				if (searchBean.getSrhStatus().length() == 0) {
					submitType = SubmitType.UPDATE;
					searchBean.setSelectedType(submitType + "");
					searchBean.setSrhStatus(RecordStatus.ACTIVE + "");

				} else if ((RecordStatus.ACTIVE + "")
						.equalsIgnoreCase(searchBean.getSrhStatus())) {
					submitType = SubmitType.UPDATE;
					searchBean.setSelectedType(submitType + "");
					searchBean.setSrhStatus(RecordStatus.ACTIVE + "");
				}
			}
		}

		if (submitType == SubmitType.UPDATE) {
			condQry += db.getIDInCondQuery(RecordStatus.ACTIVE + "",
					"A.STATUS");
		} else {
			if (searchBean.getSrhStatus().length() > 0) {
				condQry += db.getIDInCondQuery(searchBean.getSrhStatus(),
						"A.STATUS");
			} else {
				searchBean.setSrhStatus(RecordStatus.ACTIVE + "");
				condQry += db.getIDInCondQuery(searchBean.getSrhStatus(),
						"A.STATUS");
			}
		}

		searchBean.setColumnSortName(
				searchBean.getColumnSortName().replaceAll("2", "10"));

		String selQry = "SELECT A.VEHICLEINSPECTIONID, "
				+ db.getSelectDate("A.INSPECTIONDATE")
				+ ", A.VEHICLEID, C.PARKING, B.EMPLOYEEID, "
				+ "A.DACOMMENTS, A.DISPATCHERCOMMENTS, "
				+ db.getSelectDateTime("C.CLOCKOUTTIME") + ", A.STATUS, "
				+ db.getSelectDateFormat("A.INSPECTIONDATE",
						db.ORACLE_YYYYSMMSDD)
				+ ", C.DACHECKOUTID FROM VEHICLEINSPECTION A, DACHECKIN B, DACHECKOUT C "
				+ "WHERE A.DACHECKINID=B.DACHECKINID AND B.DACHECKINID=C.DACHECKINID AND "
				+ "A.ENTITYID=" + entityID + condQry
				+ getOrderByQry(searchBean, "1");

		searchBean.setColumnSortName(
				searchBean.getColumnSortName().replaceAll("10", "2"));

		List resultList = db.selectAsList(selQry, 11);
		if (resultList.size() > 0) {
			searchBean.setDisplayPostBtn(true);
			Map<String, String> _vehicleMap = getAdminDataMap(
					enumSuggestorTypes.vehicles.toString(), "", entityID, true);

			Map<String, String> _employeeMap = getAdminDataMap(
					enumSuggestorTypes.employees.toString(), "", entityID,
					true);

			String idsArray[] = db.getIndexedDataFromList(resultList,
					new int[] { 0 });
			String ids = idsArray[0];

			condQry = db.getDataInCondQuery("Inspection", "A.MODULE");

			condQry += db.getIDInCondQuery(ids, "A.MODULEID");

			condQry += db.getIDInCondQuery(entityID, "A.ENTITYID");

			selQry = "SELECT A.MODULEID, B.COMMONUPLOADSTRANSID "
					+ "FROM COMMONUPLOADS A, COMMONUPLOADSTRANS B WHERE "
					+ "A.COMMONUPLOADSID=B.COMMONUPLOADSID AND A.STATUS!="
					+ RecordStatus.DELETE + " AND B.STATUS!="
					+ RecordStatus.DELETE + condQry + " ORDER BY 1, 2";
			List uploadsList = db.selectAsList(selQry, 2);

			for (int i = 0; i < resultList.size(); i++) {
				List tempList = (ArrayList) resultList.get(i);
				String tempRecordID = getListData(tempList, 0);
				String vehicleID = tempList.get(2) == null ? ""
						: tempList.get(2).toString().trim();
				String parking = tempList.get(3) == null ? ""
						: tempList.get(3).toString().trim();
				String employeeID = tempList.get(4) == null ? ""
						: tempList.get(4).toString().trim();
				String checkoutTime = tempList.get(7) == null ? ""
						: tempList.get(7).toString().trim();
				String status = tempList.get(8) == null ? ""
						: tempList.get(8).toString().trim();
				String daCheckoutID = tempList.get(10) == null ? ""
						: tempList.get(10).toString().trim();

				String vehicleName = _vehicleMap.get(vehicleID) == null
						? vehicleID
						: _vehicleMap.get(vehicleID);
				String employeeName = _employeeMap.get(employeeID) == null ? ""
						: _employeeMap.get(employeeID);

				parking = mainUtil.getValue(mainUtil.getParking(), parking);

				status = RecordStatus.RecordStatus[Integer.parseInt(status)];
				String uploadIds = "";
				for (int j = 0; j < uploadsList.size(); j++) {
					List tempRow = (ArrayList) uploadsList.get(j);
					String uploadRecordID = getListData(tempRow, 0);
					if (uploadRecordID.equalsIgnoreCase(tempRecordID)) {
						String tempID = getListData(tempRow, 1);
						if (uploadIds.length() > 0)
							uploadIds += ",";
						uploadIds += tempID;
					} else {
						if (uploadIds.length() > 0) {
							break;
						}
					}
				}
				tempList.set(2, vehicleName);
				tempList.set(3, parking);
				tempList.set(4, employeeName);
				tempList.set(7, checkoutTime);
				tempList.set(8, status);
				tempList.set(9, daCheckoutID);
				tempList.set(10, uploadIds);
				resultList.set(i, tempList);
			}
		}

		String searchFiltersArray[] = new String[] { "Date Range", "Vehicle",
				"Status" };
		if ("4".equalsIgnoreCase(loginUserRoles)) {
			searchFiltersArray = new String[] { "Date Range", "Status" };
			searchBean.setDisplayPostBtn(false);
		}

		searchBean.setLabelsList(labelsList);
		searchBean.setDataList(resultList);
		searchBean.setSearchFiltersArray(searchFiltersArray);
		return searchBean;
	}

	public boolean updatRecords(List transList, String loginUser,
			String entityID) throws Exception {

		boolean result = false;
		if (transList.size() > 0) {
			List<String> upList = new ArrayList<String>();
			for (int i = 0; i < transList.size(); i++) {
				List tempList = (ArrayList) transList.get(i);
				System.out.println(i + " :: tempList :: " + tempList.size()
						+ " :: " + tempList);
				String recordID = tempList.get(0) == null ? ""
						: tempList.get(0).toString().trim();
				String daComments = tempList.get(1) == null ? ""
						: tempList.get(1).toString().trim();
				String dispatcherComments = tempList.get(2) == null ? ""
						: tempList.get(2).toString().trim();
				String parking = tempList.get(3) == null ? ""
						: tempList.get(3).toString().trim();
				String daCheckoutID = tempList.get(4) == null ? ""
						: tempList.get(4).toString().trim();
				String recordStatus = tempList.get(5) == null ? ""
						: tempList.get(5).toString().trim();
				recordStatus = recordStatus.length() == 0
						? (RecordStatus.ACTIVE + "")
						: recordStatus;

				String upQry = "UPDATE VEHICLEINSPECTION SET DACOMMENTS="
						+ db.getInsertDBValue(daComments)
						+ ", DISPATCHERCOMMENTS="
						+ db.getInsertDBValue(dispatcherComments) + ", STATUS="
						+ db.getInsertDBValue(recordStatus) + ", UPDATE_USER="
						+ db.getInsertDBValue(loginUser) + ", UPDATE_DATE="
						+ db.getInsertSysdate() + " WHERE VEHICLEINSPECTIONID="
						+ recordID;
				upList.add(upQry);

				// Getting Active Checkin records available for that vehicle
				String checkinIDs = "";
				String selQry = "SELECT DISTINCT B.DACHECKINID FROM VEHICLEINSPECTION A, "
						+ "DACHECKIN B WHERE A.VEHICLEID=B.VEHICLEID AND A.ENTITYID="
						+ entityID + " AND B.STATUS=" + RecordStatus.ACTIVE
						+ " AND A.VEHICLEINSPECTIONID=" + recordID;
				// checkinIDs = db.selectById(selQry);
				if (checkinIDs.length() > 0) {
					upQry = "UPDATE DACHECKIN SET PARKING="
							+ db.getInsertDBValue(parking) + ", UPDATE_USER="
							+ db.getInsertDBValue(loginUser) + ", UPDATE_DATE="
							+ db.getInsertSysdate() + " WHERE ENTITYID="
							+ entityID + " AND DACHECKINID IN (" + checkinIDs
							+ ")";
					upList.add(upQry);
				}

				if (daCheckoutID.length() > 0) {
					upQry = "UPDATE DACHECKOUT SET PARKING="
							+ db.getInsertDBValue(parking) + ", UPDATE_USER="
							+ db.getInsertDBValue(loginUser) + ", UPDATE_DATE="
							+ db.getInsertSysdate() + " WHERE DACHECKOUTID="
							+ daCheckoutID;
					upList.add(upQry);
				}
			}

			if (upList.size() > 0)
				result = db.batchInsert(upList);
		}

		return result;

	}

	public boolean postRecords(String recordIDs, String loginUser,
			String entityID) throws Exception {

		boolean result = false;

		List<String> upList = new ArrayList<String>();
		upList.add(buildStatusQry("VEHICLEINSPECTION", "VEHICLEINSPECTIONID",
				recordIDs, RecordStatus.POST, loginUser));

		if (upList.size() > 0)
			result = db.batchInsert(upList);

		return result;
	}

	@Override
	public Object[] createRecord(MainBean mainBean, String loginUser,
			String loginUserRoles, String loginUserID, String entityID)
			throws Exception {

		bean = (VehicleInspection) mainBean;
		ErrorBean errorType = new ErrorBean();
		List<String> insList = new ArrayList<String>();
		String recordID = "";

		String selQry = "SELECT VEHICLEINSPECTIONID FROM VEHICLEINSPECTION WHERE STATUS IN ("
				+ RecordStatus.ACTIVE + "," + RecordStatus.POST
				+ ") AND ENTITYID=" + entityID + " AND VEHICLEID="
				+ bean.getVehicleID()
				+ db.getDateCondTypeQuery(db.EQUALS_TO, "INSPECTIONDATE",
						bean.getInspectionDate(), db.ORACLE_MMSDDSYYYY);

		List resultList = db.selectAsList(selQry, 1);
		if (resultList.size() > 0) {
			List tempList = (ArrayList) resultList.get(0);
			recordID = tempList.get(0) == null ? ""
					: tempList.get(0).toString().trim();

		}

		if (recordID.length() == 0) {
			int status = bean.getStatus().length() == 0 ? RecordStatus.ACTIVE
					: Integer.parseInt(bean.getStatus());

			recordID = db.getNextIDValue("VEHICLEINSPECTIONID");
			insList = buildMainQry(recordID, bean.getInspectionDate(),
					bean.getDaCheckinID(), bean.getVehicleID(),
					bean.getDaComments(), bean.getDispatcherComments(),
					bean.getGroundByDispatcher(), status, loginUser, entityID,
					insList);

			for (int i = 0; i < bean.getTransList().size(); i++) {
				List tempList = (ArrayList) bean.getTransList().get(i);
				String name = tempList.get(0) == null ? ""
						: tempList.get(0).toString().trim();
				String value = tempList.get(1) == null ? ""
						: tempList.get(1).toString().trim();
				String comments = tempList.get(2) == null ? ""
						: tempList.get(2).toString().trim();

				insList = buildTransQry(recordID, name, value, comments, status,
						loginUser, entityID, insList);
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

	public List<String> buildMainQry(String recordID, String inspectionDate,
			String daCheckinID, String vehicleID, String daComments,
			String dispatcherComments, String groundedByDispatcher, int status,
			String loginUser, String entityID, List<String> insList) {

		String insQry = "INSERT INTO VEHICLEINSPECTION (VEHICLEINSPECTIONID, ENTITYID, "
				+ "INSPECTIONDATE, DACHECKINID, VEHICLEID, DACOMMENTS, DISPATCHERCOMMENTS, "
				+ "GROUNDBYDISPATCHER, CREATE_USER, CREATE_DATE, STATUS) VALUES ("
				+ recordID + ", " + entityID + ", "
				+ db.getInsertDate(inspectionDate) + ", "
				+ db.getInsertDBValue(daCheckinID) + ", "
				+ db.getInsertDBValue(vehicleID) + ", "
				+ db.getInsertDBValue(daComments) + ", "
				+ db.getInsertDBValue(dispatcherComments) + ", "
				+ db.getInsertDBValue(groundedByDispatcher) + ", "
				+ db.getInsertDBValue(loginUser) + ", " + db.getInsertSysdate()
				+ ", " + db.getInsertDBValue(status) + ")";
		insList.add(insQry);

		return insList;
	}

	public List<String> buildTransQry(String recordID, String name,
			String value, String comments, int status, String loginUser,
			String entityID, List<String> insList) throws Exception {

		String transID = db.getNextIDValue("VEHICLEINSPECTIONTRANSID");
		String insQry = "INSERT INTO VEHICLEINSPECTIONTRANS (VEHICLEINSPECTIONTRANSID, "
				+ "VEHICLEINSPECTIONID, PARTNAME, PARTINSPECTIONVALUE, "
				+ "PARTINSPECTIONCOMMENTS, CREATE_USER, CREATE_DATE, STATUS) VALUES ("
				+ transID + ", " + recordID + ", " + db.getInsertDBValue(name)
				+ ", " + db.getInsertDBValue(value) + ", "
				+ db.getInsertDBValue(comments) + ", "
				+ db.getInsertDBValue(loginUser) + ", " + db.getInsertSysdate()
				+ ", " + db.getInsertDBValue(status) + ")";
		insList.add(insQry);

		return insList;
	}

	@Override
	public Object[] updateRecord(MainBean mainBean, String loginUser,
			String loginUserRoles, String loginUserID, String entityID)
			throws Exception {

		bean = (VehicleInspection) mainBean;
		ErrorBean errorType = new ErrorBean();
		List<String> upList = new ArrayList<String>();

		int status = bean.getStatus().length() == 0 ? RecordStatus.ACTIVE
				: Integer.parseInt(bean.getStatus());

		String recordID = bean.getVehicleInspectionID();
		String upQry = "UPDATE VEHICLEINSPECTION SET INSPECTIONDATE="
				+ db.getInsertDate(bean.getInspectionDate()) + ", VEHICLEID="
				+ db.getInsertDBValue(bean.getVehicleID()) + ", DACOMMENTS="
				+ db.getInsertDBValue(bean.getDaComments())
				+ ", DISPATCHERCOMMENTS="
				+ db.getInsertDBValue(bean.getDispatcherComments())
				+ ", GROUNDBYDISPATCHER="
				+ db.getInsertDBValue(bean.getGroundByDispatcher())
				+ ", UPDATE_USER=" + db.getInsertDBValue(loginUser)
				+ ", UPDATE_DATE=" + db.getInsertSysdate() + ", STATUS="
				+ db.getInsertDBValue(status) + " WHERE VEHICLEINSPECTIONID="
				+ recordID;
		upList.add(upQry);

		String selQry = "SELECT VEHICLEINSPECTIONID FROM VEHICLEINSPECTIONTRANS "
				+ "WHERE STATUS!=" + RecordStatus.DELETE
				+ " AND VEHICLEINSPECTIONID=" + recordID;
		String transRecordID = db.selectById(selQry);
		if (transRecordID.length() > 0) {
			upQry = "UPDATE VEHICLEINSPECTIONTRANS SET UPDATE_USER="
					+ db.getInsertDBValue(loginUser) + ", UPDATE_DATE="
					+ db.getInsertSysdate() + ", STATUS="
					+ db.getInsertDBValue(RecordStatus.DELETE)
					+ " WHERE VEHICLEINSPECTIONID=" + recordID;
			upList.add(upQry);
		}

		for (int i = 0; i < bean.getTransList().size(); i++) {
			List tempList = (ArrayList) bean.getTransList().get(i);
			String name = tempList.get(0) == null ? ""
					: tempList.get(0).toString().trim();
			String value = tempList.get(1) == null ? ""
					: tempList.get(1).toString().trim();
			String comments = tempList.get(2) == null ? ""
					: tempList.get(2).toString().trim();

			String transID = db.getNextIDValue("VEHICLEINSPECTIONTRANSID");
			upQry = "INSERT INTO VEHICLEINSPECTIONTRANS (VEHICLEINSPECTIONTRANSID, "
					+ "VEHICLEINSPECTIONID, PARTNAME, PARTINSPECTIONVALUE, "
					+ "PARTINSPECTIONCOMMENTS, CREATE_USER, CREATE_DATE, STATUS) VALUES ("
					+ transID + ", " + recordID + ", "
					+ db.getInsertDBValue(name) + ", "
					+ db.getInsertDBValue(value) + ", "
					+ db.getInsertDBValue(comments) + ", "
					+ db.getInsertDBValue(loginUser) + ", "
					+ db.getInsertSysdate() + ", " + db.getInsertDBValue(status)
					+ ")";
			upList.add(upQry);
		}

		selQry = "SELECT C.DACHECKOUTID FROM VEHICLEINSPECTION A, "
				+ "DACHECKIN B, DACHECKOUT C WHERE "
				+ " A.DACHECKINID=B.DACHECKINID AND"
				+ " B.DACHECKINID=C.DACHECKINID AND A.VEHICLEINSPECTIONID="
				+ recordID + " AND A.ENTITYID=" + entityID;
		String daCheckoutID = db.selectById(selQry);
		if (daCheckoutID.length() > 0) {
			upQry = "UPDATE DACHECKOUT SET PARKING="
					+ db.getInsertDBValue(bean.getParking()) + ", UPDATE_USER="
					+ db.getInsertDBValue(loginUser) + ", UPDATE_DATE="
					+ db.getInsertSysdate() + " WHERE DACHECKOUTID="
					+ daCheckoutID;
			upList.add(upQry);
		}

		boolean result = db.batchInsert(upList);

		errorType = getErrorType(result, SubmitType.UPDATE,
				bean.getDisplayName());

		return new Object[] { recordID, errorType };
	}

	@Override
	public Object[] deleteRecord(MainBean mainBean, String loginUser,
			String loginUserRoles, String loginUserID, String entityID)
			throws Exception {

		bean = (VehicleInspection) mainBean;
		ErrorBean errorType = new ErrorBean();
		List<String> upList = new ArrayList<String>();

		String recordID = bean.getVehicleInspectionID();
		upList.add(buildStatusQry("VEHICLEINSPECTION", "VEHICLEINSPECTIONID",
				recordID, RecordStatus.DELETE, loginUser));

		boolean result = db.batchInsert(upList);

		errorType = getErrorType(result, SubmitType.DELETE,
				bean.getDisplayName());

		return new Object[] { recordID, errorType };
	}

	@Override
	public Object[] finalRecord(MainBean mainBean, String loginUser,
			String loginUserRoles, String loginUserID, String entityID)
			throws Exception {

		bean = (VehicleInspection) mainBean;
		ErrorBean errorType = new ErrorBean();
		List<String> upList = new ArrayList<String>();

		String recordID = bean.getVehicleInspectionID();
		upList.add(buildStatusQry("VEHICLEINSPECTION", "VEHICLEINSPECTIONID",
				recordID, RecordStatus.POST, loginUser));

		boolean result = db.batchInsert(upList);

		errorType = getErrorType(result, SubmitType.FINAL,
				bean.getDisplayName());

		return new Object[] { recordID, errorType };
	}

	@Override
	public VehicleInspection fetchRecord(String recordID, String loginUser,
			String loginUserRoles, String loginUserID, String entityID,
			int submitType) throws Exception {

		String selQry = "SELECT VEHICLEINSPECTIONID, ENTITYID, DACHECKINID, "
				+ db.getSelectDate("INSPECTIONDATE")
				+ ", VEHICLEID, DACOMMENTS, DISPATCHERCOMMENTS, "
				+ "GROUNDBYDISPATCHER, 1, CREATE_USER, "
				+ db.getSelectDateTime("CREATE_DATE") + ", UPDATE_USER, "
				+ db.getSelectDateTime("UPDATE_DATE")
				+ ", STATUS, 0 FROM VEHICLEINSPECTION WHERE VEHICLEINSPECTIONID="
				+ recordID;

		List resultList = new ArrayList();
		if (recordID.length() > 0)
			resultList = db.selectAsList(selQry,
					bean.getBeanAttributes().size());

		bean = (VehicleInspection) setListValuesToBean(bean,
				bean.getBeanAttributes(), resultList);

		if (resultList.size() > 0) {
			String employeeID = getTableColumnData("EMPLOYEEID", "DACHECKIN",
					"DACHECKINID", bean.getDaCheckinID());
			Map<String, String> _vehicleMap = getAdminDataMap(
					enumSuggestorTypes.vehicles.toString(), bean.getVehicleID(),
					entityID);
			Map<String, String> _employeeMap = getAdminDataMap(
					enumSuggestorTypes.employees.toString(), employeeID,
					entityID);

			String vehicleName = _vehicleMap.get(bean.getVehicleID()) == null
					? bean.getVehicleID()
					: _vehicleMap.get(bean.getVehicleID());

			String employeeName = _employeeMap.get(employeeID) == null ? ""
					: _employeeMap.get(employeeID);

			selQry = "SELECT VEHICLEINSPECTIONTRANSID, PARTNAME, "
					+ "PARTINSPECTIONVALUE, PARTINSPECTIONCOMMENTS "
					+ " FROM VEHICLEINSPECTIONTRANS WHERE STATUS!="
					+ RecordStatus.DELETE + " AND VEHICLEINSPECTIONID="
					+ recordID + " ORDER BY 1 ";
			List transList = db.selectAsList(selQry, 4);
			bean.setTransList(transList);
			bean.setVehicleName(vehicleName);
			bean.setEmployeeName(employeeName);

			selQry = "SELECT C.PARKING FROM VEHICLEINSPECTION A, "
					+ "DACHECKIN B, DACHECKOUT C WHERE "
					+ " A.DACHECKINID=B.DACHECKINID AND"
					+ " B.DACHECKINID=C.DACHECKINID AND A.VEHICLEINSPECTIONID="
					+ recordID + " AND A.ENTITYID=" + entityID;
			String parking = db.selectById(selQry);
			bean.setParking(parking);
		}

		if (submitType == SubmitType.CREATE
				|| submitType == SubmitType.UPDATE) {

			String currentDate = db.getCurrentDate();
			if (submitType == SubmitType.CREATE)
				bean.setInspectionDate(currentDate);

			bean.setDaCheckoutList(getDACheckinDetails(bean.getVehicleID(),
					entityID, currentDate, submitType));
		}

		return bean;
	}

	public List getDACheckinDetails(String vehicleID, String entityID,
			String srhDate, int submitType) throws Exception {

		String condQry = db.getDateCondQuery(srhDate, srhDate, "B.CLOCKINTIME");

		condQry += " AND B.STATUS=" + RecordStatus.POST;

		String subQry = "SELECT VEHICLEID FROM VEHICLEINSPECTION WHERE STATUS!="
				+ RecordStatus.DELETE + " AND ENTITYID=" + entityID
				+ db.getDateCondQuery(srhDate, srhDate, "INSPECTIONDATE");
		if (vehicleID.length() > 0)
			subQry += " AND VEHICLEID!=" + vehicleID;

		String selQry = "SELECT A.VEHICLEID, A.VEHICLENUMBER FROM "
				+ "VEHICLE A, DACHECKIN B WHERE "
				+ "A.VEHICLEID=B.VEHICLEID AND A.ENTITYID=" + entityID + condQry
				+ " AND A.VEHICLEID NOT IN (" + subQry + ") ORDER BY 2 ";

		List resultList = db.selectAsList(selQry, 2);

		return resultList;
	}

	@Override
	public String getAjaxRequestTypeResp(String requestType,
			Map<String, String> requestMap, String loginUser,
			String loginUserRoles, String loginUserID, String entityID)
			throws Exception {

		StringBuffer xmlMesg = new StringBuffer();
		String recordID = requestMap.get("recordID") == null ? ""
				: requestMap.get("recordID");

		if ("getTransList".equalsIgnoreCase(requestType)) {

			String selQry = "SELECT VEHICLEINSPECTIONTRANSID, PARTNAME, "
					+ "PARTINSPECTIONVALUE, PARTINSPECTIONCOMMENTS "
					+ " FROM VEHICLEINSPECTIONTRANS WHERE STATUS!="
					+ RecordStatus.DELETE + " AND VEHICLEINSPECTIONID="
					+ recordID + " ORDER BY 1 ";
			List transList = db.selectAsList(selQry, 4);

			xmlMesg.append(getXmlData(requestType, transList, new String[] {
					"transID", "partName", "partValue", "partComments" }));

		} else if ("updateTransList".equalsIgnoreCase(requestType)) {

			List<String> upList = new ArrayList<String>();
			String selQry = "SELECT VEHICLEINSPECTIONID FROM VEHICLEINSPECTIONTRANS "
					+ "WHERE STATUS!=" + RecordStatus.DELETE
					+ " AND VEHICLEINSPECTIONID=" + recordID;
			String transRecordID = db.selectById(selQry);
			if (transRecordID.length() > 0) {
				String upQry = "UPDATE VEHICLEINSPECTIONTRANS SET UPDATE_USER="
						+ db.getInsertDBValue(loginUser) + ", UPDATE_DATE="
						+ db.getInsertSysdate() + ", STATUS="
						+ db.getInsertDBValue(RecordStatus.DELETE)
						+ " WHERE VEHICLEINSPECTIONID=" + recordID;
				upList.add(upQry);
			}

			int numOfRows = Integer
					.parseInt(requestMap.get("numOfRows") == null ? "0"
							: requestMap.get("numOfRows"));
			int status = RecordStatus.ACTIVE;
			for (int i = 0; i < numOfRows; i++) {
				String partName = requestMap.get("partName" + i) == null ? ""
						: requestMap.get("partName" + i).toString().trim();
				String partValue = requestMap.get("partValue" + i) == null ? ""
						: requestMap.get("partValue" + i).toString().trim();
				String partComments = requestMap.get("partComments" + i) == null
						? ""
						: requestMap.get("partComments" + i).toString().trim();

				String transID = db.getNextIDValue("VEHICLEINSPECTIONTRANSID");
				String upQry = "INSERT INTO VEHICLEINSPECTIONTRANS (VEHICLEINSPECTIONTRANSID, "
						+ "VEHICLEINSPECTIONID, PARTNAME, PARTINSPECTIONVALUE, "
						+ "PARTINSPECTIONCOMMENTS, CREATE_USER, CREATE_DATE, STATUS) VALUES ("
						+ transID + ", " + recordID + ", "
						+ db.getInsertDBValue(partName) + ", "
						+ db.getInsertDBValue(partValue) + ", "
						+ db.getInsertDBValue(partComments) + ", "
						+ db.getInsertDBValue(loginUser) + ", "
						+ db.getInsertSysdate() + ", "
						+ db.getInsertDBValue(status) + ")";
				upList.add(upQry);
			}

			boolean result = db.batchInsert(upList);

			ErrorBean errorType = getErrorType(result, SubmitType.UPDATE,
					bean.getDisplayName());

			xmlMesg.append("<" + requestType + "Details>");
			xmlMesg = buildXML("mesgType", errorType.getType(), xmlMesg);
			xmlMesg = buildXML("mesg", errorType.getMesg(), xmlMesg);
			xmlMesg.append("</" + requestType + "Details>");
		}

		return xmlMesg.toString();
	}
}
