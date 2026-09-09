package com.dataobjects;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import com.beans.ErrorBean;
import com.beans.DACheckout;
import com.beans.MainBean;
import com.beans.SearchBean;
import com.util.RecordStatus;
import com.util.SubmitType;

public class DACheckoutDAO extends DACheckinDAO {

	DACheckout bean = new DACheckout();

	@Override
	public SearchBean searchRecords(SearchBean searchBean, String recordID,
			String loginUser, String loginUserRoles, String loginUserID,
			String entityID) throws Exception {

		if (searchBean.getSelectedType().length() > 0) {
			int submitType = Integer.parseInt(searchBean.getSelectedType());
			if (submitType == SubmitType.FINAL) {
				boolean result = postRecords(searchBean.getSelectedValues(),
						searchBean.getSrhValue2(), loginUser, entityID);
				searchBean.setErrorBean(getErrorType(result, submitType,
						bean.getDisplayName()));
			}
		}

		List<String> labelsList = new ArrayList<String>();
		labelsList.add("Clockin Time");
		labelsList.add("Clockout Time");
		labelsList.add("Employee");
		labelsList.add("Vehicle");
		labelsList.add("Parking");
		labelsList.add("Status");

		searchBean.setWidthColumns(new int[] { 20, 20, 20, 20, 10, 10 });

		searchBean.setDisplayName(bean.getDisplayName() + "s");

		searchBean.setController(bean.getController());

		String currentDate = db.getCurrentDate();
		/* default any empty date to today — never dump the whole history */
		if (searchBean.getSrhFromDate() == null || searchBean.getSrhFromDate().trim().length() == 0)
			searchBean.setSrhFromDate(currentDate);
		if (searchBean.getSrhToDate() == null || searchBean.getSrhToDate().trim().length() == 0)
			searchBean.setSrhToDate(currentDate);

		String condQry = db.getDateCondQuery(searchBean.getSrhFromDate(),
				searchBean.getSrhToDate(), "A.CLOCKOUTTIME");

		condQry += db.getIDInCondQuery(searchBean.getSrhEmployeeID(),
				"B.EMPLOYEEID");

		condQry += db.getIDInCondQuery(searchBean.getSrhVehicleID(),
				"B.VEHICLEID");

		searchBean.setColumnSortName(searchBean.getColumnSortName()
				.replaceAll("2", "9").replaceAll("3", "8"));

		String selQry = "SELECT A.DACHECKOUTID, "
				+ db.getSelectDateTime("B.CLOCKINTIME") + ", "
				+ db.getSelectDateTime("A.CLOCKOUTTIME")
				+ ", B.EMPLOYEEID, B.VEHICLEID, A.PARKING, A.STATUS, "
				+ db.getSelectDateFormat("A.CLOCKOUTTIME",
						db.ORACLE_YYYYMMDDHH24MISS)
				+ ", "
				+ db.getSelectDateFormat("B.CLOCKINTIME",
						db.ORACLE_YYYYMMDDHH24MISS)
				+ ", " + db.getSelectDate("A.CLOCKOUTTIME")
				+ " FROM DACHECKOUT A, DACHECKIN B WHERE "
				+ "A.DACHECKINID=B.DACHECKINID AND A.STATUS!="
				+ RecordStatus.DELETE + " AND B.ENTITYID=" + entityID + condQry
				+ getOrderByQry(searchBean, "8");

		searchBean.setColumnSortName(searchBean.getColumnSortName()
				.replaceAll("9", "2").replaceAll("8", "3"));

		List resultList = db.selectAsList(selQry, 10);
		if (resultList.size() > 0) {
			Map<String, String> _employeeMap = getAdminDataMap(
					enumSuggestorTypes.employees.toString(), "", entityID,
					true);

			Map<String, String> _vehicleMap = getAdminDataMap(
					enumSuggestorTypes.vehicles.toString(), "", entityID, true);

			boolean displayPostBtn = false;
			String clockInDate = getIndexedDataFromList(resultList, 9, ",");
			if (clockInDate.equalsIgnoreCase(currentDate))
				displayPostBtn = true;
			searchBean.setDisplayPostBtn(displayPostBtn);

			for (int i = 0; i < resultList.size(); i++) {
				List tempList = (ArrayList) resultList.get(i);
				String employeeID = tempList.get(3) == null ? ""
						: tempList.get(3).toString().trim();
				String vehicleID = tempList.get(4) == null ? ""
						: tempList.get(4).toString().trim();
				String parking = tempList.get(5) == null ? ""
						: tempList.get(5).toString().trim();
				String status = tempList.get(6) == null ? ""
						: tempList.get(6).toString().trim();

				status = RecordStatus.RecordStatus[Integer.parseInt(status)];

				parking = mainUtil.getValue(mainUtil.getParking(), parking);

				String employeeName = _employeeMap.get(employeeID) == null
						? employeeID
						: _employeeMap.get(employeeID);
				String vehicleName = _vehicleMap.get(vehicleID) == null
						? vehicleID
						: _vehicleMap.get(vehicleID);
				tempList.set(3, employeeName);
				tempList.set(4, vehicleName);
				tempList.set(5, parking);
				tempList.set(6, status);
				tempList.remove(tempList.size() - 1);
				tempList.remove(tempList.size() - 1);
				tempList.remove(tempList.size() - 1);
				resultList.set(i, tempList);
			}
		}

		searchBean.setLabelsList(labelsList);
		searchBean.setDataList(resultList);
		searchBean.setSearchFiltersArray(
				new String[] { "Date Range", "Employee", "Vehicle" });
		return searchBean;
	}

	@Override
	public Object[] createRecord(MainBean mainBean, String loginUser,
			String loginUserRoles, String loginUserID, String entityID)
			throws Exception {

		bean = (DACheckout) mainBean;
		ErrorBean errorType = new ErrorBean();
		List<String> insList = new ArrayList<String>();
		String selQry = "SELECT DACHECKOUTID FROM DACHECKOUT WHERE STATUS!="
				+ RecordStatus.DELETE + " AND DACHECKINID="
				+ bean.getDaCheckinID();
		String recordID = db.selectById(selQry);
		if (recordID.length() == 0) {
			int status = bean.getStatus().length() == 0 ? RecordStatus.ACTIVE
					: Integer.parseInt(bean.getStatus());
			recordID = db.getNextIDValue("DACHECKOUTID");

			insList = buildMainQry(recordID, bean.getDaCheckinID(),
					bean.getClockoutDate(), bean.getClockoutTime(),
					bean.getPostInspection(), bean.getParking(),
					bean.getVehicleClean(), bean.getDispatcherChecked(),
					bean.getPackagesLeft(), bean.getCalledFromLast(),
					bean.getPhoneReturned(), bean.getGasCard(),
					bean.getPhoneCable(), bean.getFlashLight(),
					bean.getPowerBank(), bean.getDaComments(),
					bean.getDispatchComments(), status, loginUser, entityID,
					insList);

			if (status == RecordStatus.POST) {
				if (bean.getDaCheckinID().length() > 0) {
					String upQry = "UPDATE DACHECKIN SET STATUS="
							+ db.getInsertDBValue(RecordStatus.COMPLETED)
							+ " WHERE DACHECKINID=" + bean.getDaCheckinID();
					insList.add(upQry);
				}
			}

			boolean result = db.batchInsert(insList);

			errorType = getErrorType(result, SubmitType.CREATE,
					bean.getDisplayName());
		} else {
			errorType = getErrorType(false, SubmitType.DUPLICATE,
					bean.getDisplayName());

		}

		return new Object[] { recordID, errorType };
	}

	public List<String> buildMainQry(String recordID, String daCheckinID,
			String clockoutDate, String clockoutTime, String postInspection,
			String parking, String vehicleClean, String dispatcherChecked,
			String packagesLeft, String calledFromLast, String phoneReturned,
			String gasCard, String phoneCable, String flashLight,
			String powerBank, String daComments, String dispatchComments,
			int status, String loginUser, String entityID, List insList) {

		String insQry = "INSERT INTO DACHECKOUT (DACHECKOUTID, ENTITYID, DACHECKINID, "
				+ "CLOCKOUTTIME, POSTINSPECTION, PARKING, VEHICLECLEAN, "
				+ "DISPATCHERCHECKED, PACKAGESLEFT, CALLEDFROMLAST, "
				+ "PHONERETURNED, GASCARDRETURNED, CABLES, FLASHLIGHT, "
				+ "POWERBANK, DAREMARKS, DISPATCHERREMARKS, CREATE_USER, "
				+ "CREATE_DATE, STATUS) VALUES (" + recordID + ", " + entityID
				+ ", " + daCheckinID + ", "
				+ db.getInsertDateFormat((clockoutDate + " " + clockoutTime),
						db.ORACLE_MMSDDSYYYYSHHSMISAM)
				+ ", " + db.getInsertDBValue(postInspection) + ", "
				+ db.getInsertDBValue(parking) + ", "
				+ db.getInsertDBValue(vehicleClean) + ", "
				+ db.getInsertDBValue(dispatcherChecked) + ", "
				+ db.getInsertDBValue(packagesLeft) + ", "
				+ db.getInsertDBValue(calledFromLast) + ", "
				+ db.getInsertDBValue(phoneReturned) + ", "
				+ db.getInsertDBValue(gasCard) + ", "
				+ db.getInsertDBValue(phoneCable) + ", "
				+ db.getInsertDBValue(flashLight) + ", "
				+ db.getInsertDBValue(powerBank) + ", "
				+ db.getInsertDBValue(daComments) + ", "
				+ db.getInsertDBValue(dispatchComments) + ", "
				+ db.getInsertDBValue(loginUser) + ", " + db.getInsertSysdate()
				+ ", " + db.getInsertDBValue(status) + ")";
		insList.add(insQry);
		return insList;
	}

	@Override
	public Object[] updateRecord(MainBean mainBean, String loginUser,
			String loginUserRoles, String loginUserID, String entityID)
			throws Exception {

		bean = (DACheckout) mainBean;
		ErrorBean errorType = new ErrorBean();
		List<String> upList = new ArrayList<String>();

		int status = bean.getStatus().length() == 0 ? RecordStatus.ACTIVE
				: Integer.parseInt(bean.getStatus());

		String recordID = bean.getDaCheckoutID();
		String upQry = "UPDATE DACHECKOUT SET CLOCKOUTTIME="
				+ db.getInsertDateFormat(
						(bean.getClockoutDate() + " " + bean.getClockoutTime()),
						db.ORACLE_MMSDDSYYYYSHHSMISAM)
				+ ", DACHECKINID=" + db.getInsertDBValue(bean.getDaCheckinID())
				+ ", POSTINSPECTION="
				+ db.getInsertDBValue(bean.getPostInspection()) + ", PARKING="
				+ db.getInsertDBValue(bean.getParking()) + ", VEHICLECLEAN="
				+ db.getInsertDBValue(bean.getVehicleClean())
				+ ", DISPATCHERCHECKED="
				+ db.getInsertDBValue(bean.getDispatcherChecked())
				+ ", PACKAGESLEFT="
				+ db.getInsertDBValue(bean.getPackagesLeft())
				+ ", CALLEDFROMLAST="
				+ db.getInsertDBValue(bean.getCalledFromLast())
				+ ", PHONERETURNED="
				+ db.getInsertDBValue(bean.getPhoneReturned())
				+ ", GASCARDRETURNED=" + db.getInsertDBValue(bean.getGasCard())
				+ ", CABLES=" + db.getInsertDBValue(bean.getPhoneCable())
				+ ", FLASHLIGHT=" + db.getInsertDBValue(bean.getFlashLight())
				+ ", POWERBANK=" + db.getInsertDBValue(bean.getPowerBank())
				+ ", DAREMARKS=" + db.getInsertDBValue(bean.getDaComments())
				+ ", DISPATCHERREMARKS="
				+ db.getInsertDBValue(bean.getDispatchComments())
				+ ", UPDATE_USER=" + db.getInsertDBValue(loginUser)
				+ ", UPDATE_DATE=" + db.getInsertSysdate() + ", STATUS="
				+ db.getInsertDBValue(status) + " WHERE DACHECKOUTID="
				+ recordID;
		upList.add(upQry);

		if (status == RecordStatus.POST) {
			if (bean.getDaCheckinID().length() > 0) {
				upQry = "UPDATE DACHECKIN SET STATUS="
						+ db.getInsertDBValue(RecordStatus.COMPLETED)
						+ " WHERE DACHECKINID=" + bean.getDaCheckinID();
				upList.add(upQry);
			}
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

		bean = (DACheckout) mainBean;
		ErrorBean errorType = new ErrorBean();
		List<String> upList = new ArrayList<String>();

		String recordID = bean.getDaCheckoutID();
		upList.add(buildStatusQry("DACHECKOUT", "DACHECKOUTID", recordID,
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

		bean = (DACheckout) mainBean;
		ErrorBean errorType = new ErrorBean();
		boolean result = postRecords(bean.getDaCheckoutID(), "", loginUser,
				entityID);

		errorType = getErrorType(result, SubmitType.FINAL,
				bean.getDisplayName());

		return new Object[] { bean.getDaCheckoutID(), errorType };
	}

	public boolean postRecords(String recordIDs, String checkoutTime,
			String loginUser, String entityID) throws Exception {

		boolean result = false;
		List<String> upList = new ArrayList<String>();
		String upQry = "";

		if (checkoutTime.length() > 0) {
			upQry = "UPDATE DACHECKOUT SET CLOCKOUTTIME="
					+ db.getInsertDateFormat(checkoutTime, db.ORACLE_HHSMISAM)
					+ ", UPDATE_USER=" + db.getInsertDBValue(loginUser)
					+ ", UPDATE_DATE=" + db.getInsertSysdate() + ", STATUS="
					+ db.getInsertDBValue(RecordStatus.POST)
					+ " WHERE DACHECKOUTID IN (" + recordIDs + ") ";
			upList.add(upQry);

		} else {
			upQry = buildStatusQry("DACHECKOUT", "DACHECKOUTID", recordIDs,
					RecordStatus.POST, loginUser);
			upList.add(upQry);
		}

		String selQry = "SELECT DACHECKINID FROM DACHECKOUT WHERE STATUS="
				+ RecordStatus.ACTIVE
				+ db.getIDInCondQuery(recordIDs, "DACHECKOUTID");
		String daCheckinIDs = db.selectById(selQry);
		if (daCheckinIDs.length() > 0) {
			upQry = "UPDATE DACHECKIN SET STATUS="
					+ db.getInsertDBValue(RecordStatus.COMPLETED)
					+ " WHERE DACHECKINID IN (" + daCheckinIDs + ")";
			upList.add(upQry);
		}

		if (upList.size() > 0)
			result = db.batchInsert(upList);

		return result;
	}

	@Override
	public DACheckout fetchRecord(String recordID, String loginUser,
			String loginUserRoles, String loginUserID, String entityID,
			int submitType) throws Exception {

		String selQry = "SELECT A.DACHECKOUTID, A.DACHECKINID, "
				+ db.getSelectDateTime("B.CLOCKINTIME") + ", 0, "
				+ db.getSelectDateTime("A.CLOCKOUTTIME") + ", 1"
				+ ", A.POSTINSPECTION, A.PARKING, A.VEHICLECLEAN, "
				+ "A.DISPATCHERCHECKED, A.PACKAGESLEFT, A.CALLEDFROMLAST, "
				+ "A.PHONERETURNED, A.GASCARDRETURNED, A.CABLES, "
				+ "A.FLASHLIGHT, A.POWERBANK, A.DAREMARKS, "
				+ "A.DISPATCHERREMARKS, A.CREATE_USER, "
				+ db.getSelectDateTime("A.CREATE_DATE") + ", A.UPDATE_USER, "
				+ db.getSelectDateTime("A.UPDATE_DATE")
				+ ", A.STATUS, B.EMPLOYEEID, B.VEHICLEID "
				+ "FROM DACHECKOUT A, DACHECKIN B WHERE "
				+ "A.DACHECKINID=B.DACHECKINID AND A.DACHECKOUTID=" + recordID;

		List resultList = new ArrayList();
		if (recordID.length() > 0)
			resultList = db.selectAsList(selQry,
					bean.getBeanAttributes().size());

		bean = (DACheckout) setListValuesToBean(bean, bean.getBeanAttributes(),
				resultList);
		if (resultList.size() > 0) {
			List tempList = (ArrayList) resultList.get(0);
			String clockinDateTime = tempList.get(2) == null ? ""
					: tempList.get(2).toString().trim();
			String clockoutDateTime = tempList.get(4) == null ? ""
					: tempList.get(4).toString().trim();
			String employeeID = tempList.get(24) == null ? ""
					: tempList.get(24).toString().trim();
			String vehicleID = tempList.get(25) == null ? ""
					: tempList.get(25).toString().trim();

			String clockinDate = clockinDateTime.substring(0, 10).trim();
			String clockinTime = clockinDateTime.substring(10).trim();

			String clockoutDate = clockoutDateTime.substring(0, 10).trim();
			String clockoutTime = clockoutDateTime.substring(10).trim();

			Map<String, String> _employeeMap = getAdminDataMap(
					enumSuggestorTypes.employees.toString(), employeeID,
					entityID);
			Map<String, String> _vehicleMap = getAdminDataMap(
					enumSuggestorTypes.vehicles.toString(), vehicleID,
					entityID);

			String employeeName = _employeeMap.get(employeeID) == null
					? employeeID
					: _employeeMap.get(employeeID);
			String vehicleName = _vehicleMap.get(vehicleID) == null ? vehicleID
					: _vehicleMap.get(vehicleID);

			bean.setClockinDate(clockinDate);
			bean.setClockinTime(clockinTime);

			bean.setClockoutDate(clockoutDate);
			bean.setClockoutTime(clockoutTime);

			bean.setEmployeeName(employeeName);
			bean.setVehicleName(vehicleName);
		}

		if (submitType == SubmitType.CREATE
				|| submitType == SubmitType.UPDATE) {
			bean.setCheckinList(getDACheckinDetails(entityID,
					db.getCurrentDate(), submitType));
		}

		return bean;
	}

	public List getDACheckinDetails(String entityID, String srhDate,
			int submitType) throws Exception {

		List returnList = new ArrayList();
		String condQry = db.getDateCondQuery(srhDate, srhDate, "CLOCKINTIME");
		if (submitType == SubmitType.CREATE)
			condQry += " AND STATUS=" + RecordStatus.POST;
		else
			condQry += " AND STATUS IN (" + RecordStatus.POST + ", "
					+ RecordStatus.COMPLETED + ")";

		String selQry = "SELECT DACHECKINID, "
				+ db.getSelectDateTime("CLOCKINTIME")
				+ ", EMPLOYEEID FROM DACHECKIN WHERE ENTITYID=" + entityID
				+ condQry + " ORDER BY 1 ";

		List resultList = db.selectAsList(selQry, 3);
		if (resultList.size() > 0) {
			Map<String, String> _employeeMap = getAdminDataMap(
					enumSuggestorTypes.employees.toString(), "", entityID,
					true);
			for (int i = 0; i < resultList.size(); i++) {
				List tempList = (ArrayList) resultList.get(i);
				String employeeID = tempList.get(2) == null ? ""
						: tempList.get(2).toString().trim();
				String employeeName = _employeeMap.get(employeeID) == null ? ""
						: _employeeMap.get(employeeID);

				List tempRow = new ArrayList();
				tempRow.add(tempList.get(0).toString());
				tempRow.add(employeeName);
				tempRow.add(tempList.get(1).toString());
				returnList.add(tempRow);
			}
		}

		return returnList;
	}
}
