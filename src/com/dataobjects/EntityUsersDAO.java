package com.dataobjects;

import java.util.ArrayList;
import java.util.List;

import com.beans.EntityUsers;
import com.beans.ErrorBean;
import com.beans.MainBean;
import com.beans.SearchBean;
import com.util.RecordStatus;
import com.util.SubmitType;

public class EntityUsersDAO extends MVPGDAO {

	EntityUsers bean = new EntityUsers();

	@Override
	public SearchBean searchRecords(SearchBean searchBean, String recordID,
			String loginUser, String loginUserRoles, String loginUserID,
			String entityID) throws Exception {

		List<String> labelsList = new ArrayList<String>();
		labelsList.add("Employee");
		labelsList.add("User Name");
		labelsList.add("Status");

		searchBean.setWidthColumns(new int[] { 60, 30, 10 });

		searchBean.setDisplayName(bean.getDisplayName() + "s");

		searchBean.setController(bean.getController());

		String condQry = db.getDataLikeCondQuery(searchBean.getSrhValue(),
				"B.USERNAME");

		String selQry = "SELECT B.ENTITYUSERSID, A.FULLNAME, "
				+ "B.USERNAME, B.STATUS FROM EMPLOYEE A, ENTITYUSERS B "
				+ "WHERE A.EMPLOYEEID=B.EMPLOYEEID AND B.STATUS!="
				+ RecordStatus.DELETE + " AND B.ENTITYID=" + entityID + condQry
				+ getOrderByQry(searchBean, "2");

		List resultList = db.selectAsList(selQry, 4);
		for (int i = 0; i < resultList.size(); i++) {
			List tempList = (ArrayList) resultList.get(i);
			String status = getListData(tempList, 3);
			status = RecordStatus.RecordStatus[Integer.parseInt(status)];
			tempList.set(3, status);
			resultList.set(i, tempList);
		}

		searchBean.setLabelsList(labelsList);
		searchBean.setDataList(resultList);
		searchBean.setSearchFiltersArray(new String[] { "User Name" });
		return searchBean;
	}

	@Override
	public EntityUsers fetchRecord(String recordID, String loginUser,
			String loginUserRoles, String loginUserID, String entityID,
			int submitType) throws Exception {

		String selQry = "";
		if (recordID.length() > 0) {
			selQry = "SELECT B.ENTITYUSERSID, B.ENTITYID, "
					+ "B.USERNAME, B.PASSWORD, B.EMPLOYEEID, A.FULLNAME, B.CREATE_USER, "
					+ db.getSelectDateTime("B.CREATE_DATE")
					+ ", B.UPDATE_USER, "
					+ db.getSelectDateTime("B.UPDATE_DATE")
					+ ", B.STATUS FROM EMPLOYEE A, ENTITYUSERS B "
					+ "WHERE A.EMPLOYEEID=B.EMPLOYEEID AND B.STATUS!="
					+ RecordStatus.DELETE + " AND B.ENTITYID=" + entityID
					+ " AND B.ENTITYUSERSID=" + recordID;
		} else {
			selQry = "SELECT ENTITYUSERSID, ENTITYID, "
					+ "USERNAME, PASSWORD, EMPLOYEEID, 0, CREATE_USER, "
					+ db.getSelectDateTime("CREATE_DATE") + ", UPDATE_USER, "
					+ db.getSelectDateTime("UPDATE_DATE")
					+ ", STATUS FROM ENTITYUSERS B WHERE STATUS!="
					+ RecordStatus.DELETE + " AND ENTITYID=" + entityID
					+ db.getDataInCondQuery(loginUser, "USERNAME");
		}

		List resultList = db.selectAsList(selQry,
				bean.getBeanAttributes().size());

		bean = (EntityUsers) setListValuesToBean(bean, bean.getBeanAttributes(),
				resultList);

		if (recordID.length() == 0) {
			// Change Password
			if (bean.getEmployeeID().length() > 0) {
				String employeeName = getTableColumnData("FULLNAME", "EMPLOYEE",
						"EMPLOYEEID", bean.getEmployeeID());
				bean.setEmployeeName(employeeName);

			} else if ("superadmin".equalsIgnoreCase(bean.getUserName())) {
				bean.setEmployeeName("Super Admin");
			}
		}

		return bean;
	}

	public String checkDuplicate(String userName, String employeeID,
			String entityUsersID, String entityID) throws Exception {

		String recordID = "";

		String condQry = db.getDataInCondQuery(userName, "USERNAME");

		condQry += db.getIDInCondQuery(employeeID, "EMPLOYEEID");

		condQry += db.getIDNotInCondQuery(entityUsersID, "ENTITYUSERSID");

		String selQry = "SELECT ENTITYUSERSID FROM ENTITYUSERS WHERE STATUS IN ("
				+ RecordStatus.ACTIVE + ", " + RecordStatus.INACTIVE + ") "
				+ condQry;
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

		bean = (EntityUsers) mainBean;
		ErrorBean errorType = new ErrorBean();
		List<String> insList = new ArrayList<String>();

		String recordID = checkDuplicate(bean.getUserName(), "", "", entityID);
		if (recordID.length() > 0) {
			errorType = getErrorType(false, SubmitType.DUPLICATE,
					bean.getDisplayName());
			return new Object[] { "", errorType };
		}

		recordID = checkDuplicate("", bean.getEmployeeID(), "", entityID);
		if (recordID.length() > 0) {
			errorType = getErrorType(false, SubmitType.DUPLICATE,
					bean.getDisplayName());
			return new Object[] { "", errorType };
		}

		int status = bean.getStatus().length() == 0 ? RecordStatus.ACTIVE
				: Integer.parseInt(bean.getStatus());
		recordID = db.getNextIDValue("ENTITYUSERSID");

		String insQry = "INSERT INTO ENTITYUSERS (ENTITYUSERSID, ENTITYID, "
				+ "EMPLOYEEID, USERNAME, PASSWORD, CREATE_USER, "
				+ "CREATE_DATE, STATUS) VALUES (" + recordID + ", " + entityID
				+ ", " + db.getInsertDBValue(bean.getEmployeeID()) + ", "
				+ db.getInsertDBValue(bean.getUserName()) + ", "
				+ db.getInsertDBValue(bean.getPassword()) + ", "
				+ db.getInsertDBValue(loginUser) + ", " + db.getInsertSysdate()
				+ ", " + db.getInsertDBValue(status) + ")";
		insList.add(insQry);

		boolean result = db.batchInsert(insList);

		errorType = getErrorType(result, SubmitType.CREATE,
				bean.getDisplayName());

		return new Object[] { recordID, errorType };
	}

	@Override
	public Object[] updateRecord(MainBean mainBean, String loginUser,
			String loginUserRoles, String loginUserID, String entityID)
			throws Exception {

		bean = (EntityUsers) mainBean;
		ErrorBean errorType = new ErrorBean();
		List<String> upList = new ArrayList<String>();

		String recordID = checkDuplicate(bean.getUserName(), "",
				bean.getRecordID(), entityID);
		if (recordID.length() > 0) {
			errorType = getErrorType(false, SubmitType.DUPLICATE,
					bean.getDisplayName());
			return new Object[] { "", errorType };
		}

		recordID = checkDuplicate("", bean.getEmployeeID(), bean.getRecordID(),
				entityID);
		if (recordID.length() > 0) {
			errorType = getErrorType(false, SubmitType.DUPLICATE,
					bean.getDisplayName());
			return new Object[] { "", errorType };
		}

		int status = bean.getStatus().length() == 0 ? RecordStatus.ACTIVE
				: Integer.parseInt(bean.getStatus());

		recordID = bean.getRecordID();
		String upQry = "UPDATE ENTITYUSERS SET USERNAME="
				+ db.getInsertDBValue(bean.getUserName()) + ", PASSWORD="
				+ db.getInsertDBValue(bean.getPassword()) + ", UPDATE_USER="
				+ db.getInsertDBValue(loginUser) + ", UPDATE_DATE="
				+ db.getInsertSysdate() + ", STATUS="
				+ db.getInsertDBValue(status) + " WHERE ENTITYUSERSID="
				+ recordID;
		upList.add(upQry);

		boolean result = db.batchInsert(upList);

		errorType = getErrorType(result, SubmitType.UPDATE,
				bean.getDisplayName());

		return new Object[] { recordID, errorType };
	}

	@Override
	public Object[] changeRecord(MainBean mainBean, String loginUser,
			String loginUserRoles, String loginUserID, String entityID)
			throws Exception {

		bean = (EntityUsers) mainBean;
		ErrorBean errorType = new ErrorBean();
		List<String> upList = new ArrayList<String>();

		int status = bean.getStatus().length() == 0 ? RecordStatus.ACTIVE
				: Integer.parseInt(bean.getStatus());

		String recordID = bean.getRecordID();
		String upQry = "UPDATE ENTITYUSERS SET PASSWORD="
				+ db.getInsertDBValue(bean.getPassword()) + ", UPDATE_USER="
				+ db.getInsertDBValue(loginUser) + ", UPDATE_DATE="
				+ db.getInsertSysdate() + ", STATUS="
				+ db.getInsertDBValue(status) + " WHERE ENTITYUSERSID="
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

		bean = (EntityUsers) mainBean;
		ErrorBean errorType = new ErrorBean();
		List<String> upList = new ArrayList<String>();

		String recordID = bean.getRecordID();
		upList.add(buildStatusQry("ENTITYUSERS", "ENTITYUSERSID", recordID,
				RecordStatus.DELETE, loginUser));

		boolean result = db.batchInsert(upList);

		errorType = getErrorType(result, SubmitType.DELETE,
				bean.getDisplayName());

		return new Object[] { recordID, errorType };
	}
}
