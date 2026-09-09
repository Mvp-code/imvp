package com.dataobjects;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import com.beans.EmployeeTermination;
import com.beans.ErrorBean;
import com.beans.MainBean;
import com.beans.SearchBean;
import com.util.RecordStatus;
import com.util.SubmitType;

public class EmployeeTerminationDAO extends MVPGDAO {

	EmployeeTermination bean = new EmployeeTermination();

	@Override
	public SearchBean searchRecords(SearchBean searchBean, String recordID,
			String loginUser, String loginUserRoles, String loginUserID,
			String entityID) throws Exception {

		if (searchBean.getSelectedType().length() > 0) {
			int submitType = Integer.parseInt(searchBean.getSelectedType());
			if (submitType == SubmitType.FINAL) {
				boolean result = postRecords(searchBean.getSelectedValues(),
						loginUser, entityID);
				searchBean.setErrorBean(getErrorType(result, submitType,
						bean.getDisplayName()));
			}
		}

		List<String> labelsList = new ArrayList<String>();
		labelsList.add("Employee");
		labelsList.add("Date");
		labelsList.add("Type");
		labelsList.add("Reason");
		labelsList.add("Comments");
		labelsList.add("Status");

		searchBean.setWidthColumns(new int[] { 20, 10, 20, 20, 20, 10 });

		searchBean.setDisplayName(bean.getDisplayName() + "s");

		searchBean.setController(bean.getController());

		String condQry = db.getDateCondQuery(searchBean.getSrhFromDate(),
				searchBean.getSrhToDate(), "A.DATEOFTERMINATION");

		condQry += db.getIDInCondQuery(searchBean.getSrhEmployeeID(),
				"A.EMPLOYEEID");

		if (searchBean.getSrhStatus().length() > 0) {
			condQry += db.getIDInCondQuery(searchBean.getSrhStatus(),
					"A.STATUS");
		} else {
			searchBean.setSrhStatus(RecordStatus.ACTIVE + "");
			condQry += db.getIDInCondQuery(searchBean.getSrhStatus(),
					"A.STATUS");
		}

		searchBean.setColumnSortName(
				searchBean.getColumnSortName().replaceAll("3", "8"));

		String selQry = "SELECT A.EMPLOYEETERMINATIONID, B.FULLNAME, "
				+ db.getSelectDate("A.DATEOFTERMINATION")
				+ ", A.TERMINATIONTYPE, A.TERMINATIONREASON, "
				+ "A.COMMENTS, A.STATUS, "
				+ db.getSelectDateFormat("A.DATEOFTERMINATION",
						db.ORACLE_YYYYSMMSDD)
				+ " FROM EMPLOYEETERMINATION A, EMPLOYEE B WHERE "
				+ "A.EMPLOYEEID=B.EMPLOYEEID AND B.ENTITYID=" + entityID
				+ condQry + getOrderByQry(searchBean, "1");

		searchBean.setColumnSortName(
				searchBean.getColumnSortName().replaceAll("8", "3"));

		List resultList = db.selectAsList(selQry, 8);
		if (resultList.size() > 0) {
			searchBean.setDisplayPostBtn(true);
			for (int i = 0; i < resultList.size(); i++) {
				List tempList = (ArrayList) resultList.get(i);
				String status = tempList.get(6) == null ? ""
						: tempList.get(6).toString().trim();
				status = RecordStatus.RecordStatus[Integer.parseInt(status)];

				tempList.set(6, status);
				tempList.remove(tempList.size() - 1);

				resultList.set(i, tempList);
			}
		}

		searchBean.setLabelsList(labelsList);
		searchBean.setDataList(resultList);
		searchBean.setSearchFiltersArray(
				new String[] { "Date Range", "Employee", "Status" });
		return searchBean;
	}

	public boolean postRecords(String recordIDs, String loginUser,
			String entityID) throws Exception {

		boolean result = false;
		List<String> upList = new ArrayList<String>();
		String upQry = "";

		if (recordIDs.length() > 0) {
			upQry = buildStatusQry("EMPLOYEETERMINATION",
					"EMPLOYEETERMINATIONID", recordIDs, RecordStatus.POST,
					loginUser);
			upList.add(upQry);

			String selQry = "SELECT EMPLOYEEID FROM EMPLOYEETERMINATION WHERE STATUS!="
					+ RecordStatus.DELETE
					+ db.getIDInCondQuery(recordIDs, "EMPLOYEETERMINATIONID")
					+ db.getDataInCondQuery("Terminated", "TERMINATIONTYPE");
			String terminatedIDs = db.selectById(selQry);
			if (terminatedIDs.length() > 0) {
				upQry = "UPDATE EMPLOYEE SET REVIEW_STATUS="
						+ RecordStatus.TERMINATED + " WHERE STATUS!="
						+ RecordStatus.DELETE + " AND EMPLOYEEID IN ("
						+ terminatedIDs + ")";
				upList.add(upQry);
			}

			selQry = "SELECT EMPLOYEEID FROM EMPLOYEETERMINATION WHERE STATUS!="
					+ RecordStatus.DELETE
					+ db.getIDInCondQuery(recordIDs, "EMPLOYEETERMINATIONID")
					+ db.getDataInCondQuery("Quit", "TERMINATIONTYPE");
			String quitIDs = db.selectById(selQry);
			if (quitIDs.length() > 0) {
				upQry = "UPDATE EMPLOYEE SET REVIEW_STATUS=" + RecordStatus.QUIT
						+ " WHERE STATUS!=" + RecordStatus.DELETE
						+ " AND EMPLOYEEID IN (" + quitIDs + ")";
				upList.add(upQry);
			}
		}

		if (upList.size() > 0)
			result = db.batchInsert(upList);

		return result;
	}

	private String checkRecordID(String employeeID, String entityID)
			throws Exception {

		String recordID = "";
		String selQry = "SELECT EMPLOYEETERMINATIONID FROM "
				+ "EMPLOYEETERMINATION WHERE STATUS!=" + RecordStatus.DELETE
				+ " AND ENTITYID=" + entityID + " AND EMPLOYEEID=" + employeeID;
		List resultList = db.selectAsList(selQry, 1);
		if (resultList.size() > 0) {
			List tempList = (ArrayList) resultList.get(0);
			recordID = tempList.get(0) == null ? ""
					: tempList.get(0).toString().trim();
		}

		return recordID;
	}

	@Override
	public Object[] createRecord(MainBean mainBean, String loginUser,
			String loginUserRoles, String loginUserID, String entityID)
			throws Exception {

		bean = (EmployeeTermination) mainBean;
		ErrorBean errorType = new ErrorBean();
		boolean result = false;
		for (int i = 0; i < bean.getTransList().size(); i++) {
			List tempList = (ArrayList) bean.getTransList().get(i);
			String dateOfTermination = getListData(tempList, 0);
			String employeeID = getListData(tempList, 1);
			String terminationType = getListData(tempList, 2);
			String terminationReason = getListData(tempList, 3);
			String comments = getListData(tempList, 4);

			String recordID = checkRecordID(employeeID, entityID);
			if (recordID.length() == 0) {
				int status = bean.getStatus().length() == 0
						? RecordStatus.ACTIVE
						: Integer.parseInt(bean.getStatus());

				List<String> insList = new ArrayList<String>();
				recordID = db.getNextIDValue("EMPLOYEETERMINATIONID");
				insList = buildMainQry(recordID, dateOfTermination, employeeID,
						terminationType, terminationReason, comments, status,
						loginUser, entityID, insList);

				boolean result1 = db.batchInsert(insList);
				if (result1)
					result = true;
			}
		}

		errorType = getErrorType(result, SubmitType.CREATE,
				bean.getDisplayName());

		return new Object[] { "", errorType };
	}

	public List<String> buildMainQry(String recordID, String dateOfTermination,
			String employeeID, String terminationType, String terminationReason,
			String comments, int status, String loginUser, String entityID,
			List<String> insList) {

		String insQry = "INSERT INTO EMPLOYEETERMINATION (EMPLOYEETERMINATIONID, ENTITYID, "
				+ "DATEOFTERMINATION, EMPLOYEEID, TERMINATIONTYPE, TERMINATIONREASON, "
				+ "COMMENTS, CREATE_USER, CREATE_DATE, STATUS) VALUES ("
				+ recordID + ", " + entityID + ", "
				+ db.getInsertDate(dateOfTermination) + ", "
				+ db.getInsertDBValue(employeeID) + ", "
				+ db.getInsertDBValue(terminationType) + ", "
				+ db.getInsertDBValue(terminationReason) + ", "
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

		bean = (EmployeeTermination) mainBean;
		ErrorBean errorType = new ErrorBean();
		List<String> upList = new ArrayList<String>();

		int status = bean.getStatus().length() == 0 ? RecordStatus.ACTIVE
				: Integer.parseInt(bean.getStatus());

		String recordID = bean.getEmployeeTerminationID();
		String upQry = "UPDATE EMPLOYEETERMINATION SET DATEOFTERMINATION="
				+ db.getInsertDate(bean.getDateOfTermination())
				+ ", EMPLOYEEID=" + db.getInsertDBValue(bean.getEmployeeID())
				+ ", TERMINATIONTYPE="
				+ db.getInsertDBValue(bean.getTerminationType())
				+ ", TERMINATIONREASON="
				+ db.getInsertDBValue(bean.getTerminationReason())
				+ ", COMMENTS=" + db.getInsertDBValue(bean.getComments())
				+ ", UPDATE_USER=" + db.getInsertDBValue(loginUser)
				+ ", UPDATE_DATE=" + db.getInsertSysdate() + ", STATUS="
				+ db.getInsertDBValue(status) + " WHERE EMPLOYEETERMINATIONID="
				+ recordID;
		upList.add(upQry);

		if (status == RecordStatus.POST) {
			int empStatus = RecordStatus.TERMINATED;
			if ("Quit".equalsIgnoreCase(bean.getTerminationType()))
				empStatus = RecordStatus.QUIT;

			upQry = "UPDATE EMPLOYEE SET REVIEW_STATUS=" + empStatus
					+ " WHERE STATUS!=" + RecordStatus.DELETE
					+ " AND EMPLOYEEID IN (" + bean.getEmployeeID() + ")";
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

		bean = (EmployeeTermination) mainBean;
		ErrorBean errorType = new ErrorBean();
		List<String> upList = new ArrayList<String>();

		String recordID = bean.getEmployeeTerminationID();
		upList.add(
				buildStatusQry("EMPLOYEETERMINATION", "EMPLOYEETERMINATIONID",
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

		bean = (EmployeeTermination) mainBean;
		ErrorBean errorType = new ErrorBean();
		List<String> upList = new ArrayList<String>();

		String recordID = bean.getEmployeeTerminationID();
		upList.add(
				buildStatusQry("EMPLOYEETERMINATION", "EMPLOYEETERMINATIONID",
						recordID, RecordStatus.POST, loginUser));

		boolean result = db.batchInsert(upList);

		errorType = getErrorType(result, SubmitType.FINAL,
				bean.getDisplayName());

		return new Object[] { recordID, errorType };
	}

	@Override
	public EmployeeTermination fetchRecord(String recordID, String loginUser,
			String loginUserRoles, String loginUserID, String entityID,
			int submitType) throws Exception {

		String selQry = "SELECT EMPLOYEETERMINATIONID, ENTITYID, "
				+ db.getSelectDate("DATEOFTERMINATION")
				+ ", EMPLOYEEID, TERMINATIONTYPE, "
				+ "TERMINATIONREASON, COMMENTS, CREATE_USER, "
				+ db.getSelectDateTime("CREATE_DATE") + ", UPDATE_USER, "
				+ db.getSelectDateTime("UPDATE_DATE")
				+ ", STATUS, 0 FROM EMPLOYEETERMINATION WHERE EMPLOYEETERMINATIONID="
				+ recordID;

		List resultList = new ArrayList();
		if (recordID.length() > 0)
			resultList = db.selectAsList(selQry,
					bean.getBeanAttributes().size());

		bean = (EmployeeTermination) setListValuesToBean(bean,
				bean.getBeanAttributes(), resultList);

		if (bean.getEmployeeID().length() > 0) {
			Map<String, String> _employeeMap = getAdminDataMap(
					enumSuggestorTypes.employees.toString(),
					bean.getEmployeeID(), entityID);
			String employeeName = _employeeMap.get(bean.getEmployeeID()) == null
					? bean.getEmployeeID()
					: _employeeMap.get(bean.getEmployeeID());
			bean.setEmployeeName(employeeName);
		}

		if (submitType == SubmitType.CREATE
				|| submitType == SubmitType.UPDATE) {

			String currentDate = db.getCurrentDate();
			if (submitType == SubmitType.CREATE)
				bean.setDateOfTermination(currentDate);
		}

		return bean;
	}
}
