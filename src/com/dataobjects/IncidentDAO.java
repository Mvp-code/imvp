package com.dataobjects;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import com.beans.ErrorBean;
import com.beans.Incident;
import com.beans.MainBean;
import com.beans.SearchBean;
import com.util.RecordStatus;
import com.util.SubmitType;

public class IncidentDAO extends MVPGDAO {

	Incident bean = new Incident();

	@Override
	public SearchBean searchRecords(SearchBean searchBean, String recordID,
			String loginUser, String loginUserRoles, String loginUserID,
			String entityID) throws Exception {

		List<String> labelsList = new ArrayList<String>();
		labelsList.add("Date");
		labelsList.add("Category");
		labelsList.add("Type");
		labelsList.add("Employee");
		labelsList.add("Vehicle");
		labelsList.add("Desc");
		labelsList.add("Status");

		searchBean.setWidthColumns(new int[] { 10, 10, 15, 15, 10, 30, 10 });

		searchBean.setDisplayName(bean.getDisplayName() + "s");

		searchBean.setController(bean.getController());

		if (!"yes".equalsIgnoreCase(searchBean.getSearchFilter())) {
			String currentDate = db.getCurrentDate();
			searchBean.setSrhFromDate(currentDate);
			searchBean.setSrhToDate(currentDate);
		}

		String condQry = db.getDateCondQuery(searchBean.getSrhFromDate(),
				searchBean.getSrhToDate(), "INCIDENT_DATE");

		condQry += db.getIDInCondQuery(searchBean.getSrhCategoryID(),
				"INCIDENTCATEGORYID");

		condQry += db.getIDInCondQuery(searchBean.getSrhTypeID(),
				"INCIDENTTYPEID");

		condQry += db.getIDInCondQuery(searchBean.getSrhEmployeeID(),
				"EMPLOYEEID");

		condQry += db.getIDInCondQuery(searchBean.getSrhVehicleID(),
				"VEHICLEID");

		searchBean.setColumnSortName(
				searchBean.getColumnSortName().replaceAll("2", "9"));

		String selQry = "SELECT INCIDENTSID, "
				+ db.getSelectDate("INCIDENT_DATE")
				+ ", INCIDENTCATEGORYID, INCIDENTTYPEID, "
				+ "EMPLOYEEID, VEHICLEID, DESCRIPTION, STATUS, "
				+ db.getSelectDateFormat("INCIDENT_DATE",
						db.ORACLE_YYYYMMDDHH24MISS)
				+ " FROM INCIDENTS WHERE STATUS!=" + RecordStatus.DELETE
				+ " AND ENTITYID=" + entityID + condQry
				+ getOrderByQry(searchBean, "2");

		searchBean.setColumnSortName(
				searchBean.getColumnSortName().replaceAll("9", "2"));

		List resultList = db.selectAsList(selQry, 9);
		if (resultList.size() > 0) {

			Map<String, String> _categoryMap = getAdminDataMap(

					enumSuggestorTypes.incidentCategories.toString(), "",
					entityID, true);
			Map<String, String> _typeMap = getAdminDataMap(
					enumSuggestorTypes.incidentTypes.toString(), "", entityID,
					true);
			Map<String, String> _employeeMap = getAdminDataMap(
					enumSuggestorTypes.employees.toString(), "", entityID,
					true);
			Map<String, String> _vehicleMap = getAdminDataMap(
					enumSuggestorTypes.vehicles.toString(), "", entityID, true);

			List dataCountList = new ArrayList();
			selQry = "SELECT DISTINCT INCIDENTTYPEID, COUNT(INCIDENTTYPEID) "
					+ " FROM INCIDENTS WHERE STATUS!=" + RecordStatus.DELETE
					+ " AND ENTITYID=" + entityID + condQry
					+ " GROUP BY INCIDENTTYPEID ORDER BY 1 ";
			List countList = db.selectAsList(selQry, 2);
			for (int i = 0; i < countList.size(); i++) {
				List tempList = (ArrayList) countList.get(i);
				String typeID = tempList.get(0) == null ? ""
						: tempList.get(0).toString().trim();
				int typeCNT = Integer.parseInt(tempList.get(1) == null ? "0"
						: tempList.get(1).toString().trim());
				if (typeCNT > 0) {
					String typeName = _typeMap.get(typeID) == null ? typeID
							: _typeMap.get(typeID);

					dataCountList = buildDataCNTList(typeName, typeCNT + "",
							dataCountList);
				}
			}
			searchBean.setDataCountList(dataCountList);

			for (int i = 0; i < resultList.size(); i++) {
				List tempList = (ArrayList) resultList.get(i);
				String categoryID = tempList.get(2) == null ? ""
						: tempList.get(2).toString().trim();
				String typeID = tempList.get(3) == null ? ""
						: tempList.get(3).toString().trim();
				String employeeID = tempList.get(4) == null ? ""
						: tempList.get(4).toString().trim();
				String vehicleID = tempList.get(5) == null ? ""
						: tempList.get(5).toString().trim();
				String status = tempList.get(7) == null ? ""
						: tempList.get(7).toString().trim();
				status = "2".equalsIgnoreCase(status) ? "Posted" : "Active";

				String categoryName = _categoryMap.get(categoryID) == null
						? categoryID
						: _categoryMap.get(categoryID);
				String typeName = _typeMap.get(typeID) == null ? typeID
						: _typeMap.get(typeID);
				String employeeName = _employeeMap.get(employeeID) == null
						? employeeID
						: _employeeMap.get(employeeID);
				String vehicleName = _vehicleMap.get(vehicleID) == null
						? vehicleID
						: _vehicleMap.get(vehicleID);

				tempList.set(2, categoryName);
				tempList.set(3, typeName);
				tempList.set(4, employeeName);
				tempList.set(5, vehicleName);
				tempList.set(7, status);
				resultList.set(i, tempList);
			}
		}

		searchBean.setLabelsList(labelsList);
		searchBean.setDataList(resultList);
		searchBean.setSearchFiltersArray(new String[] { "Date Range",
				"Category", "Type", "Employee", "Vehicle" });
		return searchBean;
	}

	@Override
	public Object[] createRecord(MainBean mainBean, String loginUser,
			String loginUserRoles, String loginUserID, String entityID)
			throws Exception {

		Incident bean = (Incident) mainBean;
		ErrorBean errorType = new ErrorBean();
		List<String> insList = new ArrayList<String>();

		int status = bean.getStatus().length() == 0 ? RecordStatus.ACTIVE
				: Integer.parseInt(bean.getStatus());
		String recordID = "";
		for (int i = 0; i < bean.getTransList().size(); i++) {
			List tempList = (ArrayList) bean.getTransList().get(i);
			String type = tempList.get(0) == null ? ""
					: tempList.get(0).toString().trim();
			String typeDesc = tempList.get(1) == null ? ""
					: tempList.get(1).toString().trim();
			String employeeID = tempList.get(2) == null ? ""
					: tempList.get(2).toString().trim();
			String vehicleID = tempList.get(3) == null ? ""
					: tempList.get(3).toString().trim();

			recordID = db.getNextIDValue("INCIDENTSID");
			String insQry = "INSERT INTO INCIDENTS (INCIDENTSID, ENTITYID, INCIDENT_DATE, "
					+ "INCIDENTCATEGORYID, INCIDENTTYPEID, DESCRIPTION, EMPLOYEEID, "
					+ "VEHICLEID, CREATE_USER, CREATE_DATE, STATUS) VALUES ("
					+ recordID + ", " + entityID + ", "
					+ db.getInsertDate(bean.getIncidentDate()) + ", "
					+ db.getInsertDBValue(bean.getIncidentCategoryID()) + ", "
					+ db.getInsertDBValue(type) + ", "
					+ db.getInsertDBValue(typeDesc) + ", "
					+ db.getInsertDBValue(employeeID) + ", "
					+ db.getInsertDBValue(vehicleID) + ", "
					+ db.getInsertDBValue(loginUser) + ", "
					+ db.getInsertSysdate() + ", " + db.getInsertDBValue(status)
					+ ")";
			insList.add(insQry);
		}

		boolean result = db.batchInsert(insList);

		errorType = getErrorType(result, SubmitType.CREATE,
				bean.getDisplayName());

		return new Object[] { "", errorType };
	}

	@Override
	public Object[] updateRecord(MainBean mainBean, String loginUser,
			String loginUserRoles, String loginUserID, String entityID)
			throws Exception {

		Incident bean = (Incident) mainBean;
		ErrorBean errorType = new ErrorBean();
		List<String> upList = new ArrayList<String>();

		int status = bean.getStatus().length() == 0 ? RecordStatus.ACTIVE
				: Integer.parseInt(bean.getStatus());

		String recordID = bean.getIncidentID();
		String upQry = "UPDATE INCIDENTS SET INCIDENT_DATE="
				+ db.getInsertDate(bean.getIncidentDate())
				+ ", INCIDENTCATEGORYID="
				+ db.getInsertDBValue(bean.getIncidentCategoryID())
				+ ", INCIDENTTYPEID="
				+ db.getInsertDBValue(bean.getIncidentTypeID())
				+ ", DESCRIPTION=" + db.getInsertDBValue(bean.getIncidentDesc())
				+ ", EMPLOYEEID=" + db.getInsertDBValue(bean.getEmployeeID())
				+ ", VEHICLEID=" + db.getInsertDBValue(bean.getVehicleID())
				+ ", UPDATE_USER=" + db.getInsertDBValue(loginUser)
				+ ", UPDATE_DATE=" + db.getInsertSysdate() + ", STATUS="
				+ db.getInsertDBValue(status) + " WHERE INCIDENTSID="
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

		Incident bean = (Incident) mainBean;
		ErrorBean errorType = new ErrorBean();
		List<String> upList = new ArrayList<String>();

		String recordID = bean.getIncidentID();
		upList.add(buildStatusQry("INCIDENTS", "INCIDENTSID", recordID,
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

		Incident bean = (Incident) mainBean;
		ErrorBean errorType = new ErrorBean();
		List<String> upList = new ArrayList<String>();

		String recordID = bean.getIncidentID();
		upList.add(buildStatusQry("INCIDENTS", "INCIDENTSID", recordID,
				RecordStatus.POST, loginUser));

		boolean result = db.batchInsert(upList);

		errorType = getErrorType(result, SubmitType.FINAL,
				bean.getDisplayName());

		return new Object[] { recordID, errorType };
	}

	@Override
	public Incident fetchRecord(String recordID, String loginUser,
			String loginUserRoles, String loginUserID, String entityID,
			int submitType) throws Exception {

		String selQry = "SELECT INCIDENTSID, ENTITYID, "
				+ db.getSelectDate("INCIDENT_DATE")
				+ ", INCIDENTCATEGORYID, INCIDENTTYPEID, "
				+ "DESCRIPTION, EMPLOYEEID, VEHICLEID, CREATE_USER, "
				+ db.getSelectDateTime("CREATE_DATE") + ", UPDATE_USER, "
				+ db.getSelectDateTime("UPDATE_DATE")
				+ ", STATUS, 0 FROM INCIDENTS WHERE INCIDENTSID=" + recordID;

		List resultList = new ArrayList();
		if (recordID.length() > 0)
			resultList = db.selectAsList(selQry,
					bean.getBeanAttributes().size());

		bean = (Incident) setListValuesToBean(bean, bean.getBeanAttributes(),
				resultList);
		if (resultList.size() > 0) {
			List tempList = (ArrayList) resultList.get(0);
			String categoryID = tempList.get(3) == null ? ""
					: tempList.get(3).toString().trim();
			String typeID = tempList.get(4) == null ? ""
					: tempList.get(4).toString().trim();
			String employeeID = tempList.get(6) == null ? ""
					: tempList.get(6).toString().trim();
			String vehicleID = tempList.get(7) == null ? ""
					: tempList.get(7).toString().trim();

			Map<String, String> _categoryMap = getAdminDataMap(
					enumSuggestorTypes.incidentCategories.toString(),
					categoryID, entityID);
			Map<String, String> _typeMap = getAdminDataMap(
					enumSuggestorTypes.incidentTypes.toString(), typeID,
					entityID);
			Map<String, String> _employeeMap = getAdminDataMap(
					enumSuggestorTypes.employees.toString(), employeeID,
					entityID);
			Map<String, String> _vehicleMap = getAdminDataMap(
					enumSuggestorTypes.vehicles.toString(), vehicleID,
					entityID);

			String categoryName = _categoryMap.get(categoryID) == null
					? categoryID
					: _categoryMap.get(categoryID);
			String typeName = _typeMap.get(typeID) == null ? typeID
					: _typeMap.get(typeID);
			String employeeName = _employeeMap.get(employeeID) == null
					? employeeID
					: _employeeMap.get(employeeID);
			String vehicleName = _vehicleMap.get(vehicleID) == null ? vehicleID
					: _vehicleMap.get(vehicleID);
			bean.setIncidentCategoryName(categoryName);
			bean.setIncidentTypeName(typeName);
			bean.setEmployeeName(employeeName);
			bean.setVehicleName(vehicleName);
		}

		if (submitType == SubmitType.CREATE) {
			String incidentCategoryID = "";
			String employeeID = "";
			String vehicleID = "";
			String incidentDate = db.getCurrentDate();

			selQry = "SELECT ENTITYUSERSID, EMPLOYEEID, ENTITYID "
					+ "FROM ENTITYUSERS WHERE STATUS=" + RecordStatus.ACTIVE
					+ db.getDataInCondQuery(loginUser, "USERNAME");
			resultList = db.selectAsList(selQry, 3);
			if (resultList.size() == 1) {
				List tempList = (ArrayList) resultList.get(0);
				employeeID = getListDBData(tempList, 1);
				if (employeeID.length() > 0) {
					selQry = "SELECT A.DACHECKINID, A.VEHICLEID FROM DACHECKIN A JOIN EMPLOYEE B ON "
							+ "A.EMPLOYEEID=B.EMPLOYEEID LEFT JOIN VEHICLE C ON "
							+ "A.VEHICLEID=C.VEHICLEID WHERE A.ENTITYID="
							+ entityID
							+ db.getIDInCondQuery(employeeID, "A.EMPLOYEEID")
							+ db.getIDInCondQuery(
									RecordStatus.ACTIVE + ","
											+ RecordStatus.POST + ","
											+ RecordStatus.COMPLETED,
									"A.STATUS")
							+ db.getDateCondTypeQuery(db.EQUALS_TO,
									"A.CLOCKINTIME", incidentDate)
							+ " ORDER BY 1 DESC";
					resultList = db.selectAsList(selQry, 2);
					if (resultList.size() > 0) {
						tempList = (ArrayList) resultList.get(0);
						vehicleID = getListDBData(tempList, 1);
					}
				}
			}

			selQry = "SELECT INCIDENTCATEGORYID, DESCRIPTION FROM "
					+ "INCIDENTCATEGORY WHERE STATUS=" + RecordStatus.ACTIVE
					+ " AND ENTITYID=" + entityID
					+ db.getDataInCondQuery("Employee", "DESCRIPTION")
					+ " ORDER BY 2 ";

			resultList = db.selectAsList(selQry, 2);
			if (resultList.size() > 0) {
				List tempList = (ArrayList) resultList.get(0);
				incidentCategoryID = getListDBData(tempList, 0);
			}

			bean.setIncidentCategoryID(incidentCategoryID);
			bean.setIncidentDate(incidentDate);
			bean.setEmployeeID(employeeID);
			bean.setVehicleID(vehicleID);
		}

		return bean;
	}
}
