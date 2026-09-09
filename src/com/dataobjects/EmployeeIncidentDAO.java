package com.dataobjects;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import com.beans.EmployeeIncident;
import com.beans.ErrorBean;
import com.beans.MainBean;
import com.beans.SearchBean;
import com.util.RecordStatus;
import com.util.SubmitType;

public class EmployeeIncidentDAO extends MVPGDAO {

	EmployeeIncident bean = new EmployeeIncident();

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
		labelsList.add("Time");
		labelsList.add("Reported");
		labelsList.add("Type");
		labelsList.add("Location");
		labelsList.add("EMT Number");
		labelsList.add("Status");

		searchBean
				.setWidthColumns(new int[] { 15, 10, 10, 10, 15, 20, 10, 10 });

		searchBean.setDisplayName(bean.getDisplayName() + "s");

		searchBean.setController(bean.getController());

		String currentDate = db.getCurrentDate();
		if (!"yes".equalsIgnoreCase(searchBean.getSearchFilter())) {
			searchBean.setSrhFromDate(currentDate);
			searchBean.setSrhToDate(currentDate);
		}

		String condQry = db.getDateCondQuery(searchBean.getSrhFromDate(),
				searchBean.getSrhToDate(), "A.INCIDENTDATE");

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
				searchBean.getColumnSortName().replaceAll("3", "10"));

		String selQry = "SELECT A.EMPLOYEEINCIDENTID, B.FULLNAME, "
				+ db.getSelectDate("A.INCIDENTDATE") + ", "
				+ db.getSelectDateFormat("A.INCIDENTTIME", db.ORACLE_HHSMISAM)
				+ ", "
				+ db.getSelectDateFormat("A.REPORTEDTIME", db.ORACLE_HHSMISAM)
				+ ", A.TYPEOFINCIDENT, A.INCIDENTLOCATION, "
				+ "A.EMTNUMBER, A.STATUS, "
				+ db.getSelectDateFormat("A.INCIDENTDATE", db.ORACLE_YYYYSMMSDD)
				+ " FROM EMPLOYEEINCIDENT A, EMPLOYEE B WHERE "
				+ "A.EMPLOYEEID=B.EMPLOYEEID AND B.ENTITYID=" + entityID
				+ condQry + getOrderByQry(searchBean, "1");

		searchBean.setColumnSortName(
				searchBean.getColumnSortName().replaceAll("10", "3"));

		List resultList = db.selectAsList(selQry, 10);
		if (resultList.size() > 0) {
			searchBean.setDisplayPostBtn(true);
			for (int i = 0; i < resultList.size(); i++) {
				List tempList = (ArrayList) resultList.get(i);
				String status = tempList.get(8) == null ? ""
						: tempList.get(8).toString().trim();
				status = RecordStatus.RecordStatus[Integer.parseInt(status)];

				tempList.set(8, status);
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
			upQry = buildStatusQry("EMPLOYEEINCIDENT", "EMPLOYEEINCIDENTID",
					recordIDs, RecordStatus.POST, loginUser);
			upList.add(upQry);
		}

		if (upList.size() > 0)
			result = db.batchInsert(upList);

		return result;
	}

	private String checkRecordID(String employeeID, String incidentDate,
			String incidentTime, String entityID) throws Exception {

		String recordID = "";
		String selQry = "SELECT EMPLOYEEINCIDENTID FROM "
				+ "EMPLOYEEINCIDENT WHERE STATUS IN (" + RecordStatus.ACTIVE
				+ "," + RecordStatus.POST + ") AND ENTITYID=" + entityID
				+ " AND EMPLOYEEID=" + employeeID
				+ db.getDateCondTypeQuery(db.EQUALS_TO, "INCIDENTDATE",
						incidentDate, db.ORACLE_MMSDDSYYYY)
				+ db.getDateCondTypeQuery(db.EQUALS_TO, "INCIDENTTIME",
						incidentTime, db.ORACLE_HHSMISAM);
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

		bean = (EmployeeIncident) mainBean;
		ErrorBean errorType = new ErrorBean();
		boolean result = false;
		for (int i = 0; i < bean.getTransList().size(); i++) {
			List tempList = (ArrayList) bean.getTransList().get(i);
			String dateOfIncident = getListData(tempList, 0);
			String timeOfIncident = getListData(tempList, 1);
			String reportedTimeOfIncident = getListData(tempList, 2);
			String employeeID = getListData(tempList, 3);
			String incidentType = getListData(tempList, 4);
			String incidentLocation = getListData(tempList, 5);
			String incidentDesc = getListData(tempList, 6);
			String emtNumber = getListData(tempList, 7);

			String recordID = checkRecordID(employeeID, dateOfIncident,
					timeOfIncident, entityID);
			if (recordID.length() == 0) {
				int status = bean.getStatus().length() == 0
						? RecordStatus.ACTIVE
						: Integer.parseInt(bean.getStatus());

				List<String> insList = new ArrayList<String>();
				recordID = db.getNextIDValue("EMPLOYEEINCIDENTID");
				insList = buildMainQry(recordID, dateOfIncident, timeOfIncident,
						reportedTimeOfIncident, employeeID, incidentType,
						incidentLocation, incidentDesc, emtNumber, status,
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

	public List<String> buildMainQry(String recordID, String dateOfIncident,
			String timeOfIncident, String reportedTimeIncident,
			String employeeID, String incidentType, String incidentLocation,
			String incidentDesc, String emtNumber, int status, String loginUser,
			String entityID, List<String> insList) {

		String insQry = "INSERT INTO EMPLOYEEINCIDENT (EMPLOYEEINCIDENTID, "
				+ "ENTITYID, INCIDENTDATE, INCIDENTTIME, REPORTEDTIME, "
				+ "EMPLOYEEID, TYPEOFINCIDENT, INCIDENTLOCATION, "
				+ "INCIDENTDESCRIPTION, EMTNUMBER, CREATE_USER, "
				+ "CREATE_DATE, STATUS) VALUES (" + recordID + ", " + entityID
				+ ", " + db.getInsertDate(dateOfIncident) + ", "
				+ db.getInsertDateFormat(timeOfIncident, db.ORACLE_HHSMISAM)
				+ ", "
				+ db.getInsertDateFormat(reportedTimeIncident,
						db.ORACLE_HHSMISAM)
				+ ", " + db.getInsertDBValue(employeeID) + ", "
				+ db.getInsertDBValue(incidentType) + ", "
				+ db.getInsertDBValue(incidentLocation) + ", "
				+ db.getInsertDBValue(incidentDesc) + ", "
				+ db.getInsertDBValue(emtNumber) + ", "
				+ db.getInsertDBValue(loginUser) + ", " + db.getInsertSysdate()
				+ ", " + db.getInsertDBValue(status) + ")";
		insList.add(insQry);

		return insList;
	}

	@Override
	public Object[] updateRecord(MainBean mainBean, String loginUser,
			String loginUserRoles, String loginUserID, String entityID)
			throws Exception {

		bean = (EmployeeIncident) mainBean;
		ErrorBean errorType = new ErrorBean();
		List<String> upList = new ArrayList<String>();

		int status = bean.getStatus().length() == 0 ? RecordStatus.ACTIVE
				: Integer.parseInt(bean.getStatus());

		String recordID = bean.getEmployeeIncidentID();
		String upQry = "UPDATE EMPLOYEEINCIDENT SET INCIDENTDATE="
				+ db.getInsertDate(bean.getDateOfIncident()) + ", INCIDENTTIME="
				+ db.getInsertDateFormat(
						bean.getTimeOfIncident(), db.ORACLE_HHSMISAM)
				+ ", REPORTEDTIME="
				+ db.getInsertDateFormat(bean.getReportedTimeOfIncident(),
						db.ORACLE_HHSMISAM)
				+ ", EMPLOYEEID=" + db.getInsertDBValue(bean.getEmployeeID())
				+ ", TYPEOFINCIDENT="
				+ db.getInsertDBValue(bean.getIncidentType())
				+ ", INCIDENTLOCATION="
				+ db.getInsertDBValue(bean.getIncidentLocation())
				+ ", INCIDENTDESCRIPTION="
				+ db.getInsertDBValue(bean.getIncidentDescription())
				+ ", EMTNUMBER=" + db.getInsertDBValue(bean.getEmtNumber())
				+ ", UPDATE_USER=" + db.getInsertDBValue(loginUser)
				+ ", UPDATE_DATE=" + db.getInsertSysdate() + ", STATUS="
				+ db.getInsertDBValue(status) + " WHERE EMPLOYEEINCIDENTID="
				+ recordID;
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

		bean = (EmployeeIncident) mainBean;
		ErrorBean errorType = new ErrorBean();
		List<String> upList = new ArrayList<String>();

		String recordID = bean.getEmployeeIncidentID();
		upList.add(buildStatusQry("EMPLOYEEINCIDENT", "EMPLOYEEINCIDENTID",
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

		bean = (EmployeeIncident) mainBean;
		ErrorBean errorType = new ErrorBean();
		List<String> upList = new ArrayList<String>();

		String recordID = bean.getEmployeeIncidentID();
		upList.add(buildStatusQry("EMPLOYEEINCIDENT", "EMPLOYEEINCIDENTID",
				recordID, RecordStatus.POST, loginUser));

		boolean result = db.batchInsert(upList);

		errorType = getErrorType(result, SubmitType.FINAL,
				bean.getDisplayName());

		return new Object[] { recordID, errorType };
	}

	@Override
	public EmployeeIncident fetchRecord(String recordID, String loginUser,
			String loginUserRoles, String loginUserID, String entityID,
			int submitType) throws Exception {

		String selQry = "SELECT EMPLOYEEINCIDENTID, ENTITYID, "
				+ db.getSelectDate("INCIDENTDATE") + ", "
				+ db.getSelectDateFormat("INCIDENTTIME", db.ORACLE_HHSMISAM)
				+ ", "
				+ db.getSelectDateFormat("REPORTEDTIME", db.ORACLE_HHSMISAM)
				+ ", EMPLOYEEID, TYPEOFINCIDENT, INCIDENTLOCATION, "
				+ "INCIDENTDESCRIPTION, EMTNUMBER, CREATE_USER, "
				+ db.getSelectDateTime("CREATE_DATE") + ", UPDATE_USER, "
				+ db.getSelectDateTime("UPDATE_DATE")
				+ ", STATUS, 0 FROM EMPLOYEEINCIDENT WHERE EMPLOYEEINCIDENTID="
				+ recordID;

		List resultList = new ArrayList();
		if (recordID.length() > 0)
			resultList = db.selectAsList(selQry,
					bean.getBeanAttributes().size());

		bean = (EmployeeIncident) setListValuesToBean(bean,
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
				bean.setDateOfIncident(currentDate);
		}

		return bean;
	}
}
