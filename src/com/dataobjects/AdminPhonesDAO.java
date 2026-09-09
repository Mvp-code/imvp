package com.dataobjects;

import java.util.ArrayList;
import java.util.List;

import com.beans.AdminPhones;
import com.beans.ErrorBean;
import com.beans.MainBean;
import com.beans.SearchBean;
import com.util.RecordStatus;
import com.util.SubmitType;

public class AdminPhonesDAO extends MVPGDAO {

	AdminPhones bean = new AdminPhones();

	@Override
	public SearchBean searchRecords(SearchBean searchBean, String recordID,
			String loginUser, String loginUserRoles, String loginUserID,
			String entityID) throws Exception {

		List<String> labelsList = new ArrayList<String>();
		labelsList.add("Phone Number");
		labelsList.add("Serial Number");
		labelsList.add("Remarks");
		labelsList.add("Audited");
		labelsList.add("Validity");
		labelsList.add("Phone Status");

		searchBean.setWidthColumns(new int[] { 15, 15, 25, 25, 10, 10 });

		searchBean.setDisplayName(bean.getDisplayName() + "s");

		searchBean.setController(bean.getController());

		String condQry = "";

		condQry += db.getDataInCondQuery(searchBean.getSrhValue(),
				"PHONENUMBER");

		condQry += db.getDataInCondQuery(searchBean.getSrhValue2(),
				"SERIALNUMBER");

		if (searchBean.getSrhStatus().length() > 0) {
			condQry += db.getIDInCondQuery(searchBean.getSrhStatus(),
					"PHONESTATUS");
		} else {
			searchBean.setSrhStatus(RecordStatus.ACTIVE + "");
			condQry += db.getIDInCondQuery(searchBean.getSrhStatus(),
					"PHONESTATUS");
		}

		searchBean.setColumnSortName(searchBean.getColumnSortName()
				.replaceAll("6", "10").replaceAll("5", "9"));

		String selQry = "SELECT PHONEID, PHONENUMBER, "
				+ "SERIALNUMBER, REMARKS, AUDITEDBY, "
				+ db.getSelectDate("AUDITEDDATE") + ", "
				+ db.getSelectDate("VALIDITY") + ", PHONESTATUS, "
				+ db.getSelectDateFormat("AUDITEDDATE",
						db.ORACLE_YYYYMMDDHH24MISS)
				+ ", "
				+ db.getSelectDateFormat("VALIDITY", db.ORACLE_YYYYMMDDHH24MISS)
				+ " FROM PHONES WHERE STATUS!=" + RecordStatus.DELETE
				+ " AND ENTITYID=" + entityID + condQry
				+ getOrderByQry(searchBean, "2");

		searchBean.setColumnSortName(searchBean.getColumnSortName()
				.replaceAll("9", "5").replaceAll("10", "6"));

		List resultList = db.selectAsList(selQry, 10);
		if (resultList.size() > 0) {
			for (int i = 0; i < resultList.size(); i++) {
				List tempList = (ArrayList) resultList.get(i);
				String auditedBy = tempList.get(4) == null ? ""
						: tempList.get(4).toString().trim();
				String auditedDate = tempList.get(5) == null ? ""
						: tempList.get(5).toString().trim();
				String phoneStatus = tempList.get(7) == null ? ""
						: tempList.get(7).toString().trim();
				String auditedInfo = "";
				if (auditedBy.length() > 0 && auditedDate.length() > 0)
					auditedInfo = auditedBy + " on " + auditedDate;

				phoneStatus = RecordStatus.RecordStatus[Integer
						.parseInt(phoneStatus)];
				tempList.set(4, auditedInfo);
				tempList.set(7, phoneStatus);
				tempList.remove(5);
				resultList.set(i, tempList);
			}
		}

		searchBean.setLabelsList(labelsList);
		searchBean.setDataList(resultList);
		searchBean.setSearchFiltersArray(new String[] { "Phone Number",
				"Serial Number", "Phone Status" });
		return searchBean;
	}

	@Override
	public Object[] createRecord(MainBean mainBean, String loginUser,
			String loginUserRoles, String loginUserID, String entityID)
			throws Exception {

		bean = (AdminPhones) mainBean;
		ErrorBean errorType = new ErrorBean();
		List<String> insList = new ArrayList<String>();
		String recordID = "";
		String duplicateType = "";

		// Duplicate Check for Phone Number
		String condQry = db.getDataInCondQuery(bean.getPhoneNumber(),
				"PHONENUMBER");
		String selQry = "SELECT PHONEID FROM PHONES WHERE STATUS IN ("
				+ RecordStatus.ACTIVE + ", " + RecordStatus.INACTIVE
				+ ") AND ENTITYID=" + entityID + condQry;
		List resultList = db.selectAsList(selQry, 1);
		if (resultList.size() > 0) {
			List tempList = (ArrayList) resultList.get(0);
			recordID = tempList.get(0) == null ? ""
					: tempList.get(0).toString().trim();
		}

		if (recordID.length() == 0) {
			// Duplicate Check for Serial Number
			condQry = db.getDataInCondQuery(bean.getSerialNumber(),
					"SERIALNUMBER");
			selQry = "SELECT PHONEID FROM PHONES WHERE STATUS IN ("
					+ RecordStatus.ACTIVE + ", " + RecordStatus.INACTIVE
					+ ") AND ENTITYID=" + entityID + condQry;
			resultList = db.selectAsList(selQry, 1);
			if (resultList.size() > 0) {
				List tempList = (ArrayList) resultList.get(0);
				recordID = tempList.get(0) == null ? ""
						: tempList.get(0).toString().trim();
				duplicateType = " - Serial Number";
			}
		}

		if (recordID.length() == 0) {
			int status = bean.getStatus().length() == 0 ? RecordStatus.ACTIVE
					: Integer.parseInt(bean.getStatus());
			recordID = db.getNextIDValue("PHONEID");

			String insQry = "INSERT INTO PHONES (PHONEID, ENTITYID, "
					+ "PHONENUMBER, PHONESTATUS, SERIALNUMBER, REMARKS, "
					+ "AUDITEDBY, AUDITEDDATE, VALIDITY, CREATE_USER, "
					+ "CREATE_DATE, STATUS) VALUES (" + recordID + ", "
					+ entityID + ", "
					+ db.getInsertDBValue(bean.getPhoneNumber()) + ", "
					+ db.getInsertDBValue(bean.getPhoneStatus()) + ", "
					+ db.getInsertDBValue(bean.getSerialNumber()) + ", "
					+ db.getInsertDBValue(bean.getRemarks()) + ", "
					+ db.getInsertDBValue(bean.getAuditedBy()) + ", "
					+ db.getInsertDate(bean.getAuditedDate()) + ", "
					+ db.getInsertDate(bean.getValidity()) + ", "
					+ db.getInsertDBValue(loginUser) + ", "
					+ db.getInsertSysdate() + ", " + db.getInsertDBValue(status)
					+ ")";
			insList.add(insQry);

			boolean result = db.batchInsert(insList);

			errorType = getErrorType(result, SubmitType.CREATE,
					bean.getDisplayName());
		} else {
			errorType = getErrorType(false, SubmitType.DUPLICATE,
					bean.getDisplayName() + duplicateType);

		}

		return new Object[] { recordID, errorType };
	}

	@Override
	public Object[] updateRecord(MainBean mainBean, String loginUser,
			String loginUserRoles, String loginUserID, String entityID)
			throws Exception {

		bean = (AdminPhones) mainBean;
		ErrorBean errorType = new ErrorBean();
		List<String> upList = new ArrayList<String>();

		int status = bean.getStatus().length() == 0 ? RecordStatus.ACTIVE
				: Integer.parseInt(bean.getStatus());
		String recordID = bean.getPhoneID();

		// Duplicte check for Phone Number
		String condQry = db.getDataInCondQuery(bean.getPhoneNumber(),
				"PHONENUMBER");
		String selQry = "SELECT PHONEID FROM PHONES WHERE STATUS IN ("
				+ RecordStatus.ACTIVE + ", " + RecordStatus.INACTIVE
				+ ") AND ENTITYID=" + entityID + " AND PHONEID!=" + recordID
				+ condQry;
		List resultList = db.selectAsList(selQry, 1);
		if (resultList.size() > 0) {
			List tempList = (ArrayList) resultList.get(0);
			recordID = tempList.get(0) == null ? ""
					: tempList.get(0).toString().trim();

			errorType = getErrorType(false, SubmitType.DUPLICATE,
					bean.getDisplayName());
			return new Object[] { recordID, errorType };
		}

		// Duplicte check for Serial Number
		condQry = db.getDataInCondQuery(bean.getSerialNumber(), "SERIALNUMBER");
		selQry = "SELECT PHONEID FROM PHONES WHERE STATUS IN ("
				+ RecordStatus.ACTIVE + ", " + RecordStatus.INACTIVE
				+ ") AND ENTITYID=" + entityID + " AND PHONEID!=" + recordID
				+ condQry;
		resultList = db.selectAsList(selQry, 1);
		if (resultList.size() > 0) {
			List tempList = (ArrayList) resultList.get(0);
			recordID = tempList.get(0) == null ? ""
					: tempList.get(0).toString().trim();

			errorType = getErrorType(false, SubmitType.DUPLICATE,
					bean.getDisplayName() + " - Serial Number");
			return new Object[] { recordID, errorType };
		}

		String upQry = "UPDATE PHONES SET PHONENUMBER="
				+ db.getInsertDBValue(bean.getPhoneNumber()) + ", PHONESTATUS="
				+ db.getInsertDBValue(bean.getPhoneStatus()) + ", SERIALNUMBER="
				+ db.getInsertDBValue(bean.getSerialNumber()) + ", REMARKS="
				+ db.getInsertDBValue(bean.getRemarks()) + ", AUDITEDBY="
				+ db.getInsertDBValue(bean.getAuditedBy()) + ", AUDITEDDATE="
				+ db.getInsertDate(bean.getAuditedDate()) + ", VALIDITY="
				+ db.getInsertDate(bean.getValidity()) + ", UPDATE_USER="
				+ db.getInsertDBValue(loginUser) + ", UPDATE_DATE="
				+ db.getInsertSysdate() + ", STATUS="
				+ db.getInsertDBValue(status) + " WHERE PHONEID=" + recordID;
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

		bean = (AdminPhones) mainBean;
		ErrorBean errorType = new ErrorBean();
		List<String> upList = new ArrayList<String>();

		String recordID = bean.getPhoneID();
		upList.add(buildStatusQry("PHONES", "PHONEID", recordID,
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

		bean = (AdminPhones) mainBean;
		ErrorBean errorType = new ErrorBean();
		List<String> upList = new ArrayList<String>();

		String recordID = bean.getPhoneID();
		upList.add(buildStatusQry("PHONES", "PHONEID", recordID,
				RecordStatus.POST, loginUser));

		boolean result = db.batchInsert(upList);

		errorType = getErrorType(result, SubmitType.FINAL,
				bean.getDisplayName());

		return new Object[] { recordID, errorType };
	}

	@Override
	public AdminPhones fetchRecord(String recordID, String loginUser,
			String loginUserRoles, String loginUserID, String entityID,
			int submitType) throws Exception {

		String selQry = "SELECT PHONEID, ENTITYID, PHONENUMBER, "
				+ "PHONESTATUS, SERIALNUMBER, REMARKS, AUDITEDBY,  "
				+ db.getSelectDate("AUDITEDDATE") + ", "
				+ db.getSelectDate("VALIDITY") + ", CREATE_USER, "
				+ db.getSelectDateTime("CREATE_DATE") + ", UPDATE_USER, "
				+ db.getSelectDateTime("UPDATE_DATE")
				+ ", STATUS FROM PHONES WHERE PHONEID=" + recordID;

		List resultList = new ArrayList();
		if (recordID.length() > 0)
			resultList = db.selectAsList(selQry,
					bean.getBeanAttributes().size());

		bean = (AdminPhones) setListValuesToBean(bean, bean.getBeanAttributes(),
				resultList);

		if (submitType == SubmitType.CREATE) {

		}

		return bean;
	}
}
