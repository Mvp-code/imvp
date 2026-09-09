package com.dataobjects;

import java.util.ArrayList;
import java.util.Calendar;
import java.util.GregorianCalendar;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import com.beans.EmployeeCoachingFollowup;
import com.beans.ErrorBean;
import com.beans.MainBean;
import com.beans.SearchBean;
import com.util.RecordStatus;
import com.util.SubmitType;

public class EmployeeCoachingFollowupDAO extends MVPGDAO {

	EmployeeCoachingFollowup bean = new EmployeeCoachingFollowup();

	@Override
	public SearchBean searchRecords(SearchBean searchBean, String recordID,
			String loginUser, String loginUserRoles, String loginUserID,
			String entityID) throws Exception {

		List<String> labelsList = new ArrayList<String>();
		labelsList.add("Employee");
		labelsList.add("Year");
		labelsList.add("Week");
		labelsList.add("Create Date");
		labelsList.add("Status");

		searchBean.setWidthColumns(new int[] { 50, 10, 10, 20, 10 });

		searchBean.setDisplayName(bean.getDisplayName() + "s");

		searchBean.setController(bean.getController());

		if (!"yes".equalsIgnoreCase(searchBean.getSearchFilter())) {
			GregorianCalendar calObj = new GregorianCalendar();
			int currentYear = calObj.get(Calendar.YEAR);
			int currentWeekOfYear = calObj.get(Calendar.WEEK_OF_YEAR) - 1;
			searchBean.setSrhYear(currentYear + "");
			searchBean.setSrhWeek(currentWeekOfYear + "");
		}

		String condQry = "";

		condQry += db.getIDInCondQuery(searchBean.getSrhYear(),
				"A.DASHBOARD_YEAR");

		condQry += db.getIDInCondQuery(searchBean.getSrhWeek(),
				"A.DASHBOARD_WEEK");

		condQry += db.getDataInCondQuery(searchBean.getSrhEmployeeID(),
				"C.COACHINGOWNER");

		if (searchBean.getSrhStatus().length() > 0) {
			condQry += db.getIDInCondQuery(searchBean.getSrhStatus(),
					"B.STATUS");
		} else {
			searchBean.setSrhStatus(RecordStatus.ACTIVE + "");
			condQry += db.getIDInCondQuery(searchBean.getSrhStatus(),
					"B.STATUS");
		}

		searchBean.setColumnSortName(
				searchBean.getColumnSortName().replaceAll("5", "7"));

		String selQry = "SELECT DISTINCT B.COACHING_FOLLOWUPID, A.DELIVERYASSOCIATE, "
				+ "A.DASHBOARD_YEAR, A.DASHBOARD_WEEK, "
				+ db.getSelectDate("B.CREATE_DATE") + ", B.STATUS, "
				+ db.getSelectDateFormat("B.CREATE_DATE",
						db.ORACLE_YYYYMMDDHH24MISS)
				+ " FROM DASHBOARD_OVERVIEW A, COACHING_FOLLOWUP B, "
				+ "COACHING_FOLLOWUPTRANS C WHERE "
				+ "A.DASHBOARD_OVERVIEWID=B.DASHBOARD_OVERVIEWID AND "
				+ "B.COACHING_FOLLOWUPID=C.COACHING_FOLLOWUPID AND B.ENTITYID="
				+ entityID + condQry + getOrderByQry(searchBean, "1 DESC");

		searchBean.setColumnSortName(
				searchBean.getColumnSortName().replaceAll("7", "5"));

		List resultList = db.selectAsList(selQry, 7);
		if (resultList.size() > 0) {
			searchBean.setDisplayPostBtn(true);
			for (int i = 0; i < resultList.size(); i++) {
				List tempList = (ArrayList) resultList.get(i);
				String status = tempList.get(5) == null ? ""
						: tempList.get(5).toString().trim();
				status = RecordStatus.RecordStatus[Integer.parseInt(status)];

				tempList.set(5, status);
				resultList.set(i, tempList);
			}
		}

		searchBean.setLabelsList(labelsList);
		searchBean.setDataList(resultList);
		searchBean.setSearchFiltersArray(
				new String[] { "Year", "Week", "Coaching Owner", "Status" });
		return searchBean;
	}

	@Override
	public Object[] updateRecord(MainBean mainBean, String loginUser,
			String loginUserRoles, String loginUserID, String entityID)
			throws Exception {

		bean = (EmployeeCoachingFollowup) mainBean;
		ErrorBean errorType = new ErrorBean();
		List<String> upList = new ArrayList<String>();
		String recordID = bean.getEmployeeCoachingFollowupID();

		for (int i = 0; i < bean.getTransList().size(); i++) {
			List tempList = (ArrayList) bean.getTransList().get(i);
			String transID = getListData(tempList, 0);
			String coachingStatus = getListData(tempList, 1);
			String comments = getListData(tempList, 2);

			String upQry = "UPDATE COACHING_FOLLOWUPTRANS SET COACHING_STATUS="
					+ db.getInsertDBValue(coachingStatus) + ", COMMENTS="
					+ db.getInsertDBValue(comments) + ", UPDATE_USER="
					+ db.getInsertDBValue(loginUser) + ", UPDATE_DATE="
					+ db.getInsertSysdate() + " WHERE COACHING_FOLLOWUPTRANSID="
					+ transID;
			upList.add(upQry);

			String autoIncrementArray[] = db
					.getAutoIncrementArray("COACHING_FOLLOWUPSTATUSID");
			String insQry = "INSERT INTO COACHING_FOLLOWUPSTATUS (";
			if (autoIncrementArray != null)
				insQry += autoIncrementArray[0];
			insQry += "COACHING_FOLLOWUPTRANSID, COACHING_STATUS, "
					+ "COMMENTS, CREATE_USER, CREATE_DATE, "
					+ "STATUS) VALUES (";
			if (autoIncrementArray != null)
				insQry += autoIncrementArray[1];
			insQry += transID + ", " + db.getInsertDBValue(coachingStatus)
					+ ", " + db.getInsertDBValue(comments) + ", "
					+ db.getInsertDBValue(loginUser) + ", "
					+ db.getInsertSysdate() + ", " + RecordStatus.ACTIVE + ")";
			upList.add(insQry);
		}

		boolean result = db.batchInsert(upList);

		errorType = getErrorType(result, SubmitType.UPDATE,
				bean.getDisplayName());

		return new Object[] { recordID, errorType };
	}

	@Override
	public Object[] finalRecord(MainBean mainBean, String loginUser,
			String loginUserRoles, String loginUserID, String entityID)
			throws Exception {

		bean = (EmployeeCoachingFollowup) mainBean;
		ErrorBean errorType = new ErrorBean();
		List<String> upList = new ArrayList<String>();
		String recordID = bean.getEmployeeCoachingFollowupID();

		upList.add(buildStatusQry("COACHING_FOLLOWUP", "COACHING_FOLLOWUPID",
				recordID, RecordStatus.POST, loginUser));

		boolean result = db.batchInsert(upList);

		errorType = getErrorType(result, SubmitType.FINAL,
				bean.getDisplayName());

		return new Object[] { recordID, errorType };
	}

	@Override
	public Object[] deleteRecord(MainBean mainBean, String loginUser,
			String loginUserRoles, String loginUserID, String entityID)
			throws Exception {

		bean = (EmployeeCoachingFollowup) mainBean;
		ErrorBean errorType = new ErrorBean();
		List<String> upList = new ArrayList<String>();

		String recordID = bean.getEmployeeCoachingFollowupID();
		upList.add(buildStatusQry("COACHING_FOLLOWUP", "COACHING_FOLLOWUPID",
				recordID, RecordStatus.DELETE, loginUser));

		boolean result = db.batchInsert(upList);

		errorType = getErrorType(result, SubmitType.DELETE,
				bean.getDisplayName());

		return new Object[] { recordID, errorType };
	}

	@Override
	public EmployeeCoachingFollowup fetchRecord(String recordID,
			String loginUser, String loginUserRoles, String loginUserID,
			String entityID, int submitType) throws Exception {

		String selQry = "SELECT B.COACHING_FOLLOWUPID, B.DASHBOARD_OVERVIEWID, "
				+ "A.DASHBOARD_YEAR, A.DASHBOARD_WEEK, A.DELIVERYASSOCIATE, B.CREATE_USER, "
				+ db.getSelectDateTime("B.CREATE_DATE") + ", B.UPDATE_USER, "
				+ db.getSelectDateTime("B.UPDATE_DATE") + ", B.STATUS, 0 FROM "
				+ "DASHBOARD_OVERVIEW A, COACHING_FOLLOWUP B WHERE "
				+ "A.DASHBOARD_OVERVIEWID=B.DASHBOARD_OVERVIEWID AND "
				+ "B.COACHING_FOLLOWUPID=" + recordID;

		List resultList = new ArrayList();
		if (recordID.length() > 0)
			resultList = db.selectAsList(selQry,
					bean.getBeanAttributes().size());

		bean = (EmployeeCoachingFollowup) setListValuesToBean(bean,
				bean.getBeanAttributes(), resultList);

		if (bean.getEmployeeCoachingFollowupID().length() > 0) {
			selQry = "SELECT COACHING_FOLLOWUPTRANSID, "
					+ "CATEGORY, METRIC, COACHINGOWNER, "
					+ db.getSelectDate("TARGET_DATE")
					+ ", COACHING_STATUS, COMMENTS, CREATE_USER, "
					+ db.getSelectDateTime("CREATE_DATE")
					+ ", STATUS FROM COACHING_FOLLOWUPTRANS WHERE STATUS!="
					+ RecordStatus.DELETE + " AND COACHING_FOLLOWUPID="
					+ recordID + " ORDER BY 1 ";

			List transList = db.selectAsList(selQry, 10);
			for (int i = 0; i < transList.size(); i++) {
				List tempList = (ArrayList) transList.get(i);
				String transID = getListData(tempList, 0);

				tempList.add(getStatusHx(transID, entityID, true).size() + "");
				transList.set(i, tempList);
			}

			bean.setTransList(transList);
		}

		return bean;
	}

	private List getStatusHx(String transID, String entityID, boolean onlyCount)
			throws Exception {

		String selQry = "SELECT COACHING_FOLLOWUPSTATUSID, "
				+ "COACHING_STATUS, COMMENTS, CREATE_USER, "
				+ db.getSelectDateTime("CREATE_DATE") + ", STATUS FROM "
				+ "COACHING_FOLLOWUPSTATUS WHERE STATUS!=" + RecordStatus.DELETE
				+ " AND COACHING_FOLLOWUPTRANSID=" + transID
				+ " ORDER BY 1 DESC ";

		List statusList = db.selectAsList(selQry, 6);
		if (!onlyCount) {
			Map<String, String> _dupMap = new HashMap<String, String>();
			for (int i = 0; i < statusList.size(); i++) {
				List tempList = (ArrayList) statusList.get(i);
				String createUser = getListData(tempList, 3);
				String firstName = "";
				if (!_dupMap.containsKey(createUser)) {
					firstName = getFirstNameAsUserName(createUser, entityID);
					_dupMap.put(createUser, firstName);
				} else {
					firstName = _dupMap.get(createUser);
				}
				tempList.set(3, firstName);
				statusList.set(i, tempList);
			}
		}

		return statusList;
	}

	@Override
	public String getAjaxRequestTypeResp(String requestType,
			Map<String, String> requestMap, String loginUser,
			String loginUserRoles, String loginUserID, String entityID)
			throws Exception {

		String xmlMesg = "";
		if ("showTransHx".equalsIgnoreCase(requestType)) {
			String transID = requestMap.get("transID") == null ? ""
					: requestMap.get("transID");
			List statusList = getStatusHx(transID, entityID, false);
			xmlMesg = getXmlData(requestType, statusList,
					new String[] { "transID", "coachingStatus", "comments",
							"createUser", "createDate", "status" });
		}
		return xmlMesg;
	}
}
