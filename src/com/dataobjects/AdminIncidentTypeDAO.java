package com.dataobjects;

import java.util.ArrayList;
import java.util.List;

import com.beans.AdminIncidentType;
import com.beans.ErrorBean;
import com.beans.MainBean;
import com.beans.SearchBean;
import com.util.RecordStatus;
import com.util.SubmitType;

public class AdminIncidentTypeDAO extends MVPGDAO {

	AdminIncidentType bean = new AdminIncidentType();

	@Override
	public SearchBean searchRecords(SearchBean searchBean, String recordID,
			String loginUser, String loginUserRoles, String loginUserID,
			String entityID) throws Exception {

		List<String> labelsList = new ArrayList<String>();
		labelsList.add("Type");

		searchBean.setWidthColumns(new int[] { 100 });

		searchBean.setDisplayName(bean.getDisplayName() + "s");

		searchBean.setController(bean.getController());

		String condQry = "";

		condQry += db.getDataLikeCondQuery(searchBean.getSrhValue(), "TYPE");

		String selQry = "SELECT INCIDENTTYPEID, TYPE FROM "
				+ "INCIDENTTYPE WHERE STATUS!=" + RecordStatus.DELETE
				+ " AND ENTITYID=" + entityID + condQry
				+ getOrderByQry(searchBean, "2");

		List resultList = db.selectAsList(selQry, 2);

		searchBean.setLabelsList(labelsList);
		searchBean.setDataList(resultList);
		searchBean.setSearchFiltersArray(new String[] { "Type" });
		return searchBean;
	}

	private String checkRecordID(String searchValue, String searchID,
			String entityID) throws Exception {

		String recordID = "";
		String selQry = "SELECT INCIDENTTYPEID FROM "
				+ "INCIDENTTYPE WHERE STATUS!=" + RecordStatus.DELETE
				+ " AND ENTITYID=" + entityID
				+ db.getDataInCondQuery(searchValue, "TYPE");
		if (searchID.length() > 0)
			selQry += " AND INCIDENTTYPEID!=" + searchID;
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

		bean = (AdminIncidentType) mainBean;
		ErrorBean errorType = new ErrorBean();
		boolean result = false;
		int numOfSaved = 0;
		int numOfDuplicates = 0;
		for (int i = 0; i < bean.getTransList().size(); i++) {
			List tempList = (ArrayList) bean.getTransList().get(i);
			String type = getListData(tempList, 0);

			String recordID = checkRecordID(type, "", entityID);
			if (recordID.length() == 0) {
				int status = bean.getStatus().length() == 0
						? RecordStatus.ACTIVE
						: Integer.parseInt(bean.getStatus());

				List<String> insList = new ArrayList<String>();
				recordID = db.getNextIDValue("INCIDENTTYPEID");
				insList = buildMainQry(recordID, type, status, loginUser,
						entityID, insList);

				boolean result1 = db.batchInsert(insList);
				if (result1) {
					result = true;
					numOfSaved++;
				}
			} else {
				numOfDuplicates++;
			}
		}

		if (!result) {
			if (numOfSaved > 0) {

			} else if (numOfDuplicates > 0) {
				errorType = getErrorType(false, SubmitType.DUPLICATE,
						bean.getDisplayName());
				return new Object[] { "", errorType };
			}
		}

		errorType = getErrorType(result, SubmitType.CREATE,
				bean.getDisplayName());

		return new Object[] { "", errorType };
	}

	public List<String> buildMainQry(String recordID, String type, int status,
			String loginUser, String entityID, List<String> insList) {

		String insQry = "INSERT INTO INCIDENTTYPE (INCIDENTTYPEID, ENTITYID, "
				+ "TYPE, CREATE_USER, CREATE_DATE, STATUS) VALUES (" + recordID
				+ ", " + entityID + ", " + db.getInsertDBValue(type) + ", "
				+ db.getInsertDBValue(loginUser) + ", " + db.getInsertSysdate()
				+ ", " + db.getInsertDBValue(status) + ")";
		insList.add(insQry);

		return insList;
	}

	@Override
	public Object[] updateRecord(MainBean mainBean, String loginUser,
			String loginUserRoles, String loginUserID, String entityID)
			throws Exception {

		bean = (AdminIncidentType) mainBean;
		ErrorBean errorType = new ErrorBean();
		List<String> upList = new ArrayList<String>();

		// Duplicte check for Phone Number
		String recordID = checkRecordID(bean.getTypeName(),
				bean.getIncidentTypeID(), entityID);
		if (recordID.length() > 0) {
			errorType = getErrorType(false, SubmitType.DUPLICATE,
					bean.getDisplayName());
			return new Object[] { recordID, errorType };
		}

		int status = bean.getStatus().length() == 0 ? RecordStatus.ACTIVE
				: Integer.parseInt(bean.getStatus());
		recordID = bean.getIncidentTypeID();
		String upQry = "UPDATE INCIDENTTYPE SET TYPE="
				+ db.getInsertDBValue(bean.getTypeName()) + ", UPDATE_USER="
				+ db.getInsertDBValue(loginUser) + ", UPDATE_DATE="
				+ db.getInsertSysdate() + ", STATUS="
				+ db.getInsertDBValue(status) + " WHERE INCIDENTTYPEID="
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

		bean = (AdminIncidentType) mainBean;
		ErrorBean errorType = new ErrorBean();
		List<String> upList = new ArrayList<String>();

		String recordID = bean.getIncidentTypeID();
		upList.add(buildStatusQry("INCIDENTTYPE", "INCIDENTTYPEID", recordID,
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

		bean = (AdminIncidentType) mainBean;
		ErrorBean errorType = new ErrorBean();
		List<String> upList = new ArrayList<String>();

		String recordID = bean.getIncidentTypeID();
		upList.add(buildStatusQry("INCIDENTTYPE", "INCIDENTTYPEID", recordID,
				RecordStatus.POST, loginUser));

		boolean result = db.batchInsert(upList);

		errorType = getErrorType(result, SubmitType.FINAL,
				bean.getDisplayName());

		return new Object[] { recordID, errorType };
	}

	@Override
	public AdminIncidentType fetchRecord(String recordID, String loginUser,
			String loginUserRoles, String loginUserID, String entityID,
			int submitType) throws Exception {

		String selQry = "SELECT INCIDENTTYPEID, ENTITYID, TYPE "
				+ ", CREATE_USER, " + db.getSelectDateTime("CREATE_DATE")
				+ ", UPDATE_USER, " + db.getSelectDateTime("UPDATE_DATE")
				+ ", STATUS, 0 FROM INCIDENTTYPE WHERE INCIDENTTYPEID="
				+ recordID;

		List resultList = new ArrayList();
		if (recordID.length() > 0)
			resultList = db.selectAsList(selQry,
					bean.getBeanAttributes().size());

		bean = (AdminIncidentType) setListValuesToBean(bean,
				bean.getBeanAttributes(), resultList);

		if (submitType == SubmitType.CREATE) {

		}

		return bean;
	}
}
