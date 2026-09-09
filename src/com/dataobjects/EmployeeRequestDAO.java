package com.dataobjects;

import java.util.ArrayList;
import java.util.List;

import com.beans.EmployeeRequest;
import com.beans.SearchBean;
import com.util.RecordStatus;
import com.util.SubmitType;

public class EmployeeRequestDAO extends MVPGDAO {

	EmployeeRequest bean = new EmployeeRequest();

	public List<String> updateQry(String recordID, String status,
			String comments, String loginUser, String entityID,
			List<String> upList) {

		String upQry = "UPDATE EMPLOYEE_TIMEOFF SET STATUS="
				+ db.getInsertDBValue(status) + ", REVIEWER="
				+ db.getInsertDBValue(loginUser) + ", REVIEWEDON ="
				+ db.getInsertSysdate() + ", REVIEWERCOMMENTS="
				+ db.getInsertDBValue(comments) + ", UPDATE_USER="
				+ db.getInsertDBValue(loginUser) + ", UPDATE_DATE="
				+ db.getInsertSysdate() + " WHERE EMPLOYEE_TIMEOFFID="
				+ recordID;
		upList.add(upQry);

		return upList;
	}

	public boolean updateRecords(List transList, String loginUser,
			String entityID) throws Exception {

		boolean result = true;
		List<String> upList = new ArrayList<String>();
		for (int i = 0; i < transList.size(); i++) {
			List tempList = (ArrayList) transList.get(i);
			String recordID = tempList.get(0) == null ? ""
					: tempList.get(0).toString().trim();
			String status = tempList.get(1) == null ? ""
					: tempList.get(1).toString().trim();
			String type = tempList.get(3) == null ? ""
					: tempList.get(3).toString().trim();
			if (status.length() > 0 && "Time Off".equalsIgnoreCase(type)) {
				String reason = tempList.get(2) == null ? ""
						: tempList.get(2).toString().trim();
				upList = updateQry(recordID, status, reason, loginUser,
						entityID, upList);
			}
		}

		if (upList.size() > 0)
			result = db.batchInsert(upList);

		return result;
	}

	@Override
	public SearchBean searchRecords(SearchBean searchBean, String recordID,
			String loginUser, String loginUserRoles, String loginUserID,
			String entityID) throws Exception {

		int submitType = 0;
		if (searchBean.getSelectedType().length() > 0) {
			submitType = Integer.parseInt(searchBean.getSelectedType());
			if (submitType == SubmitType.UPDATE_CONFIRM) {
				boolean result = updateRecords(searchBean.getTransList(),
						loginUser, entityID);
				searchBean.setErrorBean(getErrorType(result, submitType,
						bean.getDisplayName()));
				searchBean.setSelectedType("");
			}
		}

		List resultList = new ArrayList();
		List<String> labelsList = new ArrayList<String>();
		labelsList.add("Type");
		labelsList.add("Request Date");
		labelsList.add("Employee");
		labelsList.add("Date Range");
		labelsList.add("Reason");
		labelsList.add("Status");

		searchBean.setWidthColumns(new int[] { 10, 10, 20, 20, 15, 10 });

		searchBean.setDisplayName(bean.getDisplayName() + "s");

		searchBean.setController(bean.getController());
		if (searchBean.getSrhType().length() == 0)
			searchBean.setSrhType("Time Off");

		String currentDate = db.getCurrentDate();
		if (!"yes".equalsIgnoreCase(searchBean.getSearchFilter())) {
			searchBean.setSrhFromDate(currentDate);
		}

		if (searchBean.getSrhStatus().length() == 0)
			searchBean.setSrhStatus(RecordStatus.ACTIVE + "");

		if ("Time Off".equalsIgnoreCase(searchBean.getSrhType()))
			resultList = getTimeOffRequest(searchBean, submitType, recordID,
					loginUser, loginUserRoles, loginUserID, entityID);
		else
			resultList = getExtraDaysRequest(searchBean, submitType, recordID,
					loginUser, loginUserRoles, loginUserID, entityID);

		searchBean.setLabelsList(labelsList);
		searchBean.setDataList(resultList);
		searchBean.setSearchFiltersArray(
				new String[] { "Date Range", "Type", "Employee", "Status" });

		return searchBean;
	}

	public List getTimeOffRequest(SearchBean searchBean, int submitType,
			String recordID, String loginUser, String loginUserRoles,
			String loginUserID, String entityID) throws Exception {

		String condQry = db.getDateCondQuery(searchBean.getSrhFromDate(),
				searchBean.getSrhToDate(), "A.START_DATE");

		condQry += db.getIDInCondQuery(searchBean.getSrhEmployeeID(),
				"A.EMPLOYEEID");

		if (submitType == SubmitType.UPDATE) {
			condQry += db.getIDInCondQuery(RecordStatus.ACTIVE + "",
					"A.STATUS");

		} else if (searchBean.getSrhStatus().length() > 0) {
			condQry += db.getIDInCondQuery(searchBean.getSrhStatus(),
					"A.STATUS");
		} else {
			condQry += db.getIDInCondQuery(searchBean.getSrhStatus(),
					"A.STATUS");
		}

		searchBean.setColumnSortName(searchBean.getColumnSortName()
				.replaceAll("3", "8").replaceAll("5", "9"));

		String selQry = "SELECT A.EMPLOYEE_TIMEOFFID, 'Time Off', "
				+ db.getSelectDate("A.CREATE_DATE") + ", B.FULLNAME, "
				+ db.getConcat(new String[] { db.getSelectDate("A.START_DATE"),
						"' - '", db.getSelectDate("A.END_DATE") })
				+ ", CASE A.STATUS WHEN " + RecordStatus.ACTIVE
				+ " THEN A.REASON ELSE A.REVIEWERCOMMENTS END, "
				+ db.decodeStatus("A.STATUS",
						new int[] { RecordStatus.ACTIVE, RecordStatus.APPROVED,
								RecordStatus.REJECTED })
				+ ", "
				+ db.getSelectDateFormat("A.CREATE_DATE", db.ORACLE_YYYYSMMSDD)
				+ ", "
				+ db.getSelectDateFormat("A.START_DATE", db.ORACLE_YYYYSMMSDD)
				+ " FROM EMPLOYEE_TIMEOFF A, EMPLOYEE B WHERE "
				+ "A.EMPLOYEEID=B.EMPLOYEEID AND B.STATUS!="
				+ RecordStatus.DELETE + " AND A.ENTITYID=" + entityID + condQry
				+ getOrderByQry(searchBean, "8, 1");

		searchBean.setColumnSortName(searchBean.getColumnSortName()
				.replaceAll("8", "3").replaceAll("9", "5"));

		List resultList = db.selectAsList(selQry, 8);

		return resultList;
	}

	public List getExtraDaysRequest(SearchBean searchBean, int submitType,
			String recordID, String loginUser, String loginUserRoles,
			String loginUserID, String entityID) throws Exception {

		String condQry = db.getDateCondQuery(searchBean.getSrhFromDate(),
				searchBean.getSrhToDate(), "A.EXTRADAY");

		condQry += db.getIDInCondQuery(searchBean.getSrhEmployeeID(),
				"A.EMPLOYEEID");

		if (submitType == SubmitType.UPDATE) {
			condQry += db.getIDInCondQuery(RecordStatus.ACTIVE + "",
					"A.STATUS");

		} else if (searchBean.getSrhStatus().length() > 0) {
			condQry += db.getIDInCondQuery(searchBean.getSrhStatus(),
					"A.STATUS");
		} else {
			condQry += db.getIDInCondQuery(searchBean.getSrhStatus(),
					"A.STATUS");
		}

		searchBean.setColumnSortName(searchBean.getColumnSortName()
				.replaceAll("3", "8").replaceAll("5", "9"));

		String selQry = "SELECT A.EMPLOYEE_EXTRADAYSID, 'Extra Day', "
				+ db.getSelectDate("A.CREATE_DATE") + ", B.FULLNAME, "
				+ db.getSelectDate("A.EXTRADAY") + ", '', "
				+ db.decodeStatus("A.STATUS",
						new int[] { RecordStatus.ACTIVE, RecordStatus.APPROVED,
								RecordStatus.REJECTED })
				+ ", "
				+ db.getSelectDateFormat("A.CREATE_DATE", db.ORACLE_YYYYSMMSDD)
				+ ", "
				+ db.getSelectDateFormat("A.EXTRADAY", db.ORACLE_YYYYSMMSDD)
				+ " FROM EMPLOYEE_EXTRADAYS A, EMPLOYEE B WHERE "
				+ "A.EMPLOYEEID=B.EMPLOYEEID AND B.STATUS!="
				+ RecordStatus.DELETE + " AND A.ENTITYID=" + entityID + condQry
				+ getOrderByQry(searchBean, "8 DESC, 1 DESC");

		searchBean.setColumnSortName(searchBean.getColumnSortName()
				.replaceAll("8", "3").replaceAll("9", "5"));

		List resultList = db.selectAsList(selQry, 8);

		return resultList;
	}
}
