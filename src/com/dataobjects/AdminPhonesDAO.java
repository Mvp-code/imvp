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

	private String blank(String v) {
		return v == null ? "" : v.trim();
	}

	@Override
	public SearchBean searchRecords(SearchBean searchBean, String recordID,
			String loginUser, String loginUserRoles, String loginUserID,
			String entityID) throws Exception {

		List<String> labelsList = new ArrayList<String>();
		labelsList.add("Phone Number");
		labelsList.add("Device");
		labelsList.add("Current Status");
		labelsList.add("Contract End Date");
		labelsList.add("Last Audit Date");
		labelsList.add("Phone Status");
		labelsList.add("Notes");

		searchBean.setWidthColumns(new int[] { 12, 16, 10, 12, 12, 10, 18 });
		searchBean.setDisplayName(bean.getDisplayName() + "s");
		searchBean.setController(bean.getController());

		String condQry = "";
		condQry += db.getDataInCondQuery(searchBean.getSrhValue(),
				"PHONENUMBER");

		if (searchBean.getSrhValue2().length() > 0) {
			condQry += db.getIDInCondQuery(searchBean.getSrhValue2(),
					"CURRENTSTATUS");
		}

		if (searchBean.getSrhStatus().length() > 0) {
			condQry += db.getIDInCondQuery(searchBean.getSrhStatus(),
					"PHONESTATUS");
		} else {
			searchBean.setSrhStatus("0,4");
			condQry += db.getIDInCondQuery(searchBean.getSrhStatus(),
					"PHONESTATUS");
		}

		String selQry = "SELECT PHONEID, PHONENUMBER, "
				+ "TRIM(CONCAT(IFNULL(DEVICEMAKE,''), ' ', IFNULL(DEVICEMODEL,''))), "
				+ "CURRENTSTATUS, " + db.getSelectDate("CONTRACTENDDATE")
				+ ", " + db.getSelectDate("AUDITEDDATE") + ", PHONESTATUS, "
				+ "REMARKS FROM PHONES WHERE STATUS!=" + RecordStatus.DELETE
				+ " AND ENTITYID=" + entityID + condQry
				+ getOrderByQry(searchBean, "2");

		List resultList = db.selectAsList(selQry, 8);
		if (resultList.size() > 0) {
			for (int i = 0; i < resultList.size(); i++) {
				List tempList = (ArrayList) resultList.get(i);
				String device = tempList.get(2) == null ? ""
						: tempList.get(2).toString().trim();
				String currentStatus = tempList.get(3) == null ? "0"
						: tempList.get(3).toString().trim();
				String phoneStatus = tempList.get(6) == null ? "0"
						: tempList.get(6).toString().trim();
				if (device.length() == 0) {
					device = "—";
				}
				if (currentStatus.length() == 0) {
					currentStatus = "0";
				}
				tempList.set(2, device);
				tempList.set(3, AdminPhones.currentStatusLabel(currentStatus));
				try {
					tempList.set(6, RecordStatus.RecordStatus[Integer
							.parseInt(phoneStatus)]);
				} catch (Exception ex) {
					tempList.set(6, phoneStatus);
				}
				resultList.set(i, tempList);
			}
		}

		searchBean.setLabelsList(labelsList);
		searchBean.setDataList(resultList);
		searchBean.setSearchFiltersArray(new String[] { "Phone Number",
				"Phone Status", "Current Status" });
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

		if (recordID.length() == 0 && blank(bean.getSerialNumber()).length() > 0) {
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
				duplicateType = " - IMEI 1";
			}
		}

		if (recordID.length() == 0) {
			int status = bean.getStatus().length() == 0 ? RecordStatus.ACTIVE
					: Integer.parseInt(bean.getStatus());
			String currentStatus = blank(bean.getCurrentStatus()).length() == 0
					? "0" : bean.getCurrentStatus();
			recordID = db.getNextIDValue("PHONEID");

			String insQry = "INSERT INTO PHONES (PHONEID, ENTITYID, "
					+ "PHONENUMBER, PHONESTATUS, CURRENTSTATUS, SERIALNUMBER, "
					+ "DEVICEMAKE, DEVICEMODEL, IMEI2, IMSI, ICCID, EID, "
					+ "REMARKS, AUDITEDDATE, CONTRACTENDDATE, CONTRACTSTARTDATE, "
					+ "DEVICEORDEREDDATE, DEVICEORDEREDIMEI, DEVICEINUSEDATE, "
					+ "CREATE_USER, CREATE_DATE, STATUS) VALUES (" + recordID
					+ ", " + entityID + ", "
					+ db.getInsertDBValue(bean.getPhoneNumber()) + ", "
					+ db.getInsertDBValue(bean.getPhoneStatus()) + ", "
					+ db.getInsertDBValue(currentStatus) + ", "
					+ db.getInsertDBValue(bean.getSerialNumber()) + ", "
					+ db.getInsertDBValue(bean.getDeviceMake()) + ", "
					+ db.getInsertDBValue(bean.getDeviceModel()) + ", "
					+ db.getInsertDBValue(bean.getImei2()) + ", "
					+ db.getInsertDBValue(bean.getImsi()) + ", "
					+ db.getInsertDBValue(bean.getIccid()) + ", "
					+ db.getInsertDBValue(bean.getEid()) + ", "
					+ db.getInsertDBValue(bean.getRemarks()) + ", "
					+ db.getInsertDate(bean.getAuditedDate()) + ", "
					+ db.getInsertDate(bean.getContractEndDate()) + ", "
					+ db.getInsertDate(bean.getContractStartDate()) + ", "
					+ db.getInsertDate(bean.getDeviceOrderedDate()) + ", "
					+ db.getInsertDBValue(bean.getDeviceOrderedImei()) + ", "
					+ db.getInsertDate(bean.getDeviceInUseDate()) + ", "
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
		String currentStatus = blank(bean.getCurrentStatus()).length() == 0
				? "0" : bean.getCurrentStatus();

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

		if (blank(bean.getSerialNumber()).length() > 0) {
			condQry = db.getDataInCondQuery(bean.getSerialNumber(),
					"SERIALNUMBER");
			selQry = "SELECT PHONEID FROM PHONES WHERE STATUS IN ("
					+ RecordStatus.ACTIVE + ", " + RecordStatus.INACTIVE
					+ ") AND ENTITYID=" + entityID + " AND PHONEID!="
					+ recordID + condQry;
			resultList = db.selectAsList(selQry, 1);
			if (resultList.size() > 0) {
				List tempList = (ArrayList) resultList.get(0);
				recordID = tempList.get(0) == null ? ""
						: tempList.get(0).toString().trim();

				errorType = getErrorType(false, SubmitType.DUPLICATE,
						bean.getDisplayName() + " - IMEI 1");
				return new Object[] { recordID, errorType };
			}
		}

		String upQry = "UPDATE PHONES SET PHONENUMBER="
				+ db.getInsertDBValue(bean.getPhoneNumber()) + ", PHONESTATUS="
				+ db.getInsertDBValue(bean.getPhoneStatus())
				+ ", CURRENTSTATUS=" + db.getInsertDBValue(currentStatus)
				+ ", SERIALNUMBER="
				+ db.getInsertDBValue(bean.getSerialNumber()) + ", DEVICEMAKE="
				+ db.getInsertDBValue(bean.getDeviceMake()) + ", DEVICEMODEL="
				+ db.getInsertDBValue(bean.getDeviceModel()) + ", IMEI2="
				+ db.getInsertDBValue(bean.getImei2()) + ", IMSI="
				+ db.getInsertDBValue(bean.getImsi()) + ", ICCID="
				+ db.getInsertDBValue(bean.getIccid()) + ", EID="
				+ db.getInsertDBValue(bean.getEid()) + ", REMARKS="
				+ db.getInsertDBValue(bean.getRemarks()) + ", AUDITEDDATE="
				+ db.getInsertDate(bean.getAuditedDate()) + ", CONTRACTENDDATE="
				+ db.getInsertDate(bean.getContractEndDate())
				+ ", CONTRACTSTARTDATE="
				+ db.getInsertDate(bean.getContractStartDate())
				+ ", DEVICEORDEREDDATE="
				+ db.getInsertDate(bean.getDeviceOrderedDate())
				+ ", DEVICEORDEREDIMEI="
				+ db.getInsertDBValue(bean.getDeviceOrderedImei())
				+ ", DEVICEINUSEDATE="
				+ db.getInsertDate(bean.getDeviceInUseDate())
				+ ", UPDATE_USER=" + db.getInsertDBValue(loginUser)
				+ ", UPDATE_DATE=" + db.getInsertSysdate() + ", STATUS="
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
				+ "PHONESTATUS, CURRENTSTATUS, SERIALNUMBER, DEVICEMAKE, "
				+ "DEVICEMODEL, IMEI2, IMSI, ICCID, EID, REMARKS, "
				+ db.getSelectDate("AUDITEDDATE") + ", "
				+ db.getSelectDate("CONTRACTENDDATE") + ", "
				+ db.getSelectDate("CONTRACTSTARTDATE") + ", "
				+ db.getSelectDate("DEVICEORDEREDDATE")
				+ ", DEVICEORDEREDIMEI, "
				+ db.getSelectDate("DEVICEINUSEDATE") + ", CREATE_USER, "
				+ db.getSelectDateTime("CREATE_DATE") + ", UPDATE_USER, "
				+ db.getSelectDateTime("UPDATE_DATE")
				+ ", STATUS FROM PHONES WHERE PHONEID=" + recordID;

		List resultList = new ArrayList();
		if (recordID.length() > 0)
			resultList = db.selectAsList(selQry,
					bean.getBeanAttributes().size());

		bean = (AdminPhones) setListValuesToBean(bean, bean.getBeanAttributes(),
				resultList);

		if (blank(bean.getCurrentStatus()).length() == 0) {
			bean.setCurrentStatus("0");
		}

		return bean;
	}
}
