package com.dataobjects;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import com.beans.AdminConfiguration;
import com.beans.ErrorBean;
import com.beans.GenericSMS;
import com.beans.MainBean;
import com.beans.SearchBean;
import com.util.RecordStatus;
import com.util.SubmitType;

public class GenericSMSDAO extends MVPGDAO {

	GenericSMS bean = new GenericSMS();

	@Override
	public SearchBean searchRecords(SearchBean searchBean, String recordID,
			String loginUser, String loginUserRoles, String loginUserID,
			String entityID) throws Exception {

		List<String> labelsList = new ArrayList<String>();
		labelsList.add("Date");
		labelsList.add("Station");
		labelsList.add("Message");
		labelsList.add("Num #");
		labelsList.add("Sent #");

		searchBean.setWidthColumns(new int[] { 16, 8, 60, 8, 8 });

		searchBean.setDisplayName(bean.getDisplayName());

		searchBean.setController(bean.getController());

		String currentDate = db.getCurrentDate();
		if (!"yes".equalsIgnoreCase(searchBean.getSearchFilter())) {
			searchBean.setSrhFromDate(currentDate);
			searchBean.setSrhToDate(currentDate);
		}

		// updateScheduleStatus(currentDate, loginUserID, entityID);

		String condQry = db.getDateCondQuery(searchBean.getSrhFromDate(),
				searchBean.getSrhToDate(), "CREATE_DATE");

		searchBean.setColumnSortName(
				searchBean.getColumnSortName().replaceAll("2", "7"));

		String selQry = "SELECT GENERICSMSID, "
				+ db.getSelectDateTime("CREATE_DATE")
				+ ", STATION, MESSAGE, 0, 1, "
				+ db.getSelectDateFormat("CREATE_DATE",
						db.ORACLE_YYYYMMDDHH24MISS)
				+ " FROM GENERICSMS WHERE STATUS=" + RecordStatus.ACTIVE
				+ " AND ENTITYID=" + entityID + condQry;
		selQry += getOrderByQry(searchBean, "7");

		searchBean.setColumnSortName(
				searchBean.getColumnSortName().replaceAll("7", "2"));

		List resultList = db.selectAsList(selQry, 6);
		if (resultList.size() > 0) {
			String ids = getIndexedDataFromList(resultList, 0, ",");
			selQry = "SELECT GENERICSMSID, COUNT(GENERICSMSTRANSID) "
					+ "FROM GENERICSMSTRANS WHERE STATUS=" + RecordStatus.ACTIVE
					+ " AND GENERICSMSID IN (" + ids
					+ ") GROUP BY GENERICSMSID";
			Map<String, String> _hMap = getMap(db.selectAsList(selQry, 2));

			selQry = "SELECT GENERICSMSID, COUNT(GENERICSMSTRANSID) "
					+ "FROM GENERICSMSTRANS WHERE STATUS=" + RecordStatus.ACTIVE
					+ " AND GENERICSMSID IN (" + ids + ") "
					+ db.getDataInCondQuery("Sent@@queued", "MESSAGESTATUS",
							"@@")
					+ " GROUP BY GENERICSMSID";
			Map<String, String> _sentMap = getMap(db.selectAsList(selQry, 2));
			for (int i = 0; i < resultList.size(); i++) {
				List tempList = (ArrayList) resultList.get(i);
				String id = tempList.get(0) == null ? ""
						: tempList.get(0).toString().trim();
				String dateTime = tempList.get(1) == null ? ""
						: tempList.get(1).toString().trim();
				String station = tempList.get(2) == null ? ""
						: tempList.get(2).toString().trim();
				String message = tempList.get(3) == null ? ""
						: tempList.get(3).toString().trim();
				String empCNT = tempList.get(4) == null ? ""
						: tempList.get(4).toString().trim();
				String sentCNT = tempList.get(4) == null ? ""
						: tempList.get(4).toString().trim();

				empCNT = _hMap.get(id) == null ? "0" : _hMap.get(id);
				sentCNT = _sentMap.get(id) == null ? "0" : _sentMap.get(id);
				tempList.set(4, empCNT);
				tempList.set(5, sentCNT);
				resultList.set(i, tempList);
			}
		}

		searchBean.setLabelsList(labelsList);
		searchBean.setDataList(resultList);
		searchBean.setSearchFiltersArray(new String[] { "Date Range" });

		return searchBean;
	}

	@Override
	public Object[] createRecord(MainBean mainBean, String loginUser,
			String loginUserRoles, String loginUserID, String entityID)
			throws Exception {

		bean = (GenericSMS) mainBean;
		ErrorBean errorType = new ErrorBean();
		boolean result = false, sendSMS = false;
		String recordID = "";
		int status = bean.getStatus().length() == 0 ? RecordStatus.ACTIVE
				: Integer.parseInt(bean.getStatus());

		List<String> insList = new ArrayList<String>();
		if (bean.getTransList().size() > 0) {
			recordID = db.getNextIDValue("GENERICSMSID");
			String insQry = "INSERT INTO GENERICSMS ("
					+ "GENERICSMSID, ENTITYID, STATION, MESSAGE, "
					+ "CREATE_USER, CREATE_DATE, STATUS) VALUES (" + recordID
					+ ", " + entityID + ", "
					+ db.getInsertDBValue(bean.getStation()) + ", "
					+ db.getInsertDBValue(bean.getMessage()) + ", "
					+ db.getInsertDBValue(loginUser) + ", "
					+ db.getInsertSysdate() + ", " + RecordStatus.ACTIVE + ")";
			insList.add(insQry);

			int messageType = 0;
			String messageStatus = "";
			for (int i = 0; i < bean.getTransList().size(); i++) {
				List tempList = (ArrayList) bean.getTransList().get(i);
				String employeeID = getListData(tempList, 0);

				String autoIncrementArray[] = db
						.getAutoIncrementArray("GENERICSMSTRANSID");
				insQry = "INSERT INTO GENERICSMSTRANS (";
				if (autoIncrementArray != null)
					insQry += autoIncrementArray[0];
				insQry += "GENERICSMSID, EMPLOYEEID, MESSAGETYPE, MESSAGESTATUS, "
						+ "CREATE_USER, CREATE_DATE, STATUS) VALUES (";
				if (autoIncrementArray != null)
					insQry += autoIncrementArray[1];
				insQry += recordID + ", " + employeeID + ", " + messageType
						+ ", " + db.getInsertDBValue(messageStatus) + ", "
						+ db.getInsertDBValue(loginUser) + ", "
						+ db.getInsertSysdate() + ", " + RecordStatus.ACTIVE
						+ ")";
				insList.add(insQry);
			}

			result = db.batchInsert(insList);
		}

		if (result && status == RecordStatus.POST) {
			sendSMS = true;
		}

		errorType = getErrorType(result, SubmitType.CREATE,
				bean.getDisplayName());

		if (sendSMS) {
			String selQry = "SELECT A.GENERICSMSTRANSID, C.MOBILE, B.FULLNAME "
					+ " FROM GENERICSMSTRANS A, EMPLOYEE B, CONTACT C "
					+ "WHERE A.EMPLOYEEID=B.EMPLOYEEID AND "
					+ "B.CONTACTID=C.CONTACTID AND C.STATUS="
					+ RecordStatus.ACTIVE + " AND A.STATUS="
					+ RecordStatus.ACTIVE + " AND B.ENTITYID=" + entityID
					+ " AND A.GENERICSMSID=" + recordID + " ORDER BY 1";
			List transList = db.selectAsList(selQry, 3);

			new SMSDAO().sendSMS("GENERICSMSTRANS", bean.getMessage(),
					transList, loginUser, entityID);
		}

		return new Object[] { "", errorType };
	}

	@Override
	public GenericSMS fetchRecord(String recordID, String loginUser,
			String loginUserRoles, String loginUserID, String entityID,
			int submitType) throws Exception {

		String selQry = "SELECT GENERICSMSID, ENTITYID, STATION, MESSAGE, CREATE_USER, "
				+ db.getSelectDateTime("CREATE_DATE") + ", UPDATE_USER, "
				+ db.getSelectDateTime("UPDATE_DATE")
				+ ", STATUS, 0 FROM GENERICSMS WHERE GENERICSMSID=" + recordID;

		List resultList = new ArrayList();
		if (recordID.length() > 0)
			resultList = db.selectAsList(selQry,
					bean.getBeanAttributes().size());

		bean = (GenericSMS) setListValuesToBean(bean, bean.getBeanAttributes(),
				resultList);

		if (bean.getRecordID().length() > 0) {
			selQry = "SELECT A.GENERICSMSTRANSID, A.EMPLOYEEID, "
					+ db.getConcat(
							new String[] { "B.FULLNAME", "' - '", "C.MOBILE" })
					+ ", A.MESSAGETYPE, A.MESSAGESTATUS FROM "
					+ "GENERICSMSTRANS A, EMPLOYEE B, CONTACT C "
					+ "WHERE A.EMPLOYEEID=B.EMPLOYEEID AND "
					+ "B.CONTACTID=C.CONTACTID AND C.STATUS="
					+ RecordStatus.ACTIVE + " AND A.STATUS="
					+ RecordStatus.ACTIVE + " AND B.ENTITYID=" + entityID
					+ " AND A.GENERICSMSID=" + recordID + " ORDER BY 1";
			List transList = db.selectAsList(selQry, 5);
			bean.setTransList(transList);
		}

		if (submitType == SubmitType.CREATE) {
			bean.setDisplaySMSBtn(isProperties(
					AdminConfiguration.enumCategorys.SMS.toString(), entityID));
		}

		return bean;
	}
}
