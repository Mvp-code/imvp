package com.dataobjects;

import java.io.File;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import com.beans.ApplicationConfig;
import com.beans.CommonUpload;
import com.beans.ErrorBean;
import com.beans.MainBean;
import com.beans.SearchBean;
import com.tools.FileUpload;
import com.util.RecordStatus;
import com.util.SubmitType;

public class CommonUploadDAO extends MVPGDAO {

	CommonUpload bean = new CommonUpload();

	@Override
	public SearchBean searchRecords(SearchBean searchBean, String recordID,
			String loginUser, String loginUserRoles, String loginUserID,
			String entityID) throws Exception {

		if (searchBean.getSelectedType().length() > 0) {
			int submitType = Integer.parseInt(searchBean.getSelectedType());
			if (submitType == SubmitType.DELETE) {
				String upQry = buildStatusQry("COMMONUPLOADSTRANS",
						"COMMONUPLOADSTRANSID", searchBean.getSelectedValues(),
						RecordStatus.DELETE, loginUser);

				boolean result = db.update(upQry);

				searchBean.setErrorBean(getErrorType(result, submitType,
						bean.getDisplayName()));
			}
		}

		List<String> labelsList = new ArrayList<String>();
		labelsList.add("Date");
		labelsList.add("Type");
		labelsList.add("File");
		labelsList.add("Status");
		labelsList.add("View");

		searchBean.setWidthColumns(new int[] { 10, 40, 30, 10, 10 });

		searchBean.setDisplayName(bean.getDisplayName() + "s");

		searchBean.setController(bean.getController());

		String currentDate = db.getCurrentDate();
		if (!"yes".equalsIgnoreCase(searchBean.getSearchFilter())) {
			searchBean.setSrhFromDate(currentDate);
			searchBean.setSrhToDate(currentDate);
		}

		String condQry = db.getDateCondQuery(searchBean.getSrhFromDate(),
				searchBean.getSrhToDate(), "A.CREATE_DATE");

		searchBean.setColumnSortName(
				searchBean.getColumnSortName().replaceAll("2", "6"));

		String selQry = "SELECT A.COMMONUPLOADSID, "
				+ db.getSelectDate("A.CREATE_DATE")
				+ ", A.MODULE, B.UPLOAD_NAME, A.STATUS, B.COMMONUPLOADSTRANSID, "
				+ db.getSelectDateFormat("A.CREATE_DATE", db.ORACLE_YYYYSMMSDD)
				+ ", A.MODULEID FROM COMMONUPLOADS A, COMMONUPLOADSTRANS B WHERE "
				+ "A.COMMONUPLOADSID=B.COMMONUPLOADSID AND A.STATUS!="
				+ RecordStatus.DELETE + " AND B.STATUS!=" + RecordStatus.DELETE
				+ " AND A.ENTITYID=" + entityID + condQry
				+ getOrderByQry(searchBean, "6 DESC, 1 DESC");

		searchBean.setColumnSortName(
				searchBean.getColumnSortName().replaceAll("6", "2"));

		List resultList = db.selectAsList(selQry, 8);
		if (resultList.size() > 0) {
			String[] idsArray = db.getIndexedDataFromList(resultList,
					new int[] { 7 });
			String ids = idsArray[0];

			Map<String, String> _vehicleMap = new HashMap<String, String>();
			Map<String, String> _empMap = new HashMap<String, String>();
			if (ids.length() > 0) {
				selQry = "SELECT A.VEHICLEINSPECTIONID, B.VEHICLENUMBER "
						+ "FROM VEHICLEINSPECTION A, VEHICLE B WHERE "
						+ "A.VEHICLEID=B.VEHICLEID AND A.ENTITYID=" + entityID
						+ db.getIDInCondQuery(ids, "A.VEHICLEINSPECTIONID");
				List dataList = db.selectAsList(selQry, 2);
				_vehicleMap = getMap(dataList);

				selQry = "SELECT EMPLOYEEID, FULLNAME "
						+ "FROM EMPLOYEE WHERE ENTITYID=" + entityID
						+ db.getIDInCondQuery(ids, "EMPLOYEEID");
				dataList = db.selectAsList(selQry, 2);
				_empMap = getMap(dataList);

			}
			for (int i = 0; i < resultList.size(); i++) {
				List tempList = (ArrayList) resultList.get(i);

				String module = tempList.get(2) == null ? ""
						: tempList.get(2).toString().trim();
				String status = tempList.get(4) == null ? ""
						: tempList.get(4).toString().trim();
				String moduleID = tempList.get(7) == null ? ""
						: tempList.get(7).toString().trim();
				status = RecordStatus.RecordStatus[Integer.parseInt(status)];
				if ("Inspection".equalsIgnoreCase(module)) {
					String vehicleNum = _vehicleMap.get(moduleID) == null ? ""
							: _vehicleMap.get(moduleID);
					module = module + " - " + vehicleNum;

				} else if ("Employee".equalsIgnoreCase(module)) {
					String empName = _empMap.get(moduleID) == null ? ""
							: _empMap.get(moduleID);
					module = module + " - " + empName;
				}

				tempList.set(2, module);
				tempList.set(4, status);
				tempList.remove(tempList.size() - 1);
				tempList.remove(tempList.size() - 1);
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

		bean = (CommonUpload) mainBean;
		ErrorBean errorType = new ErrorBean();
		boolean result = true;
		String moduleID = "";
		if ("Inspection".equalsIgnoreCase(bean.getModule())) {
			moduleID = bean.getVehicleID();

		} else if ("Employee".equalsIgnoreCase(bean.getModule())) {
			moduleID = bean.getEmployeeID();
		}

		String recordID = bean.getRecordID();
		if (moduleID.length() > 0) {
			String insQry = "";
			if (recordID.length() == 0) {
				recordID = db.getNextIDValue("COMMONUPLOADSID");
				insQry = "INSERT INTO COMMONUPLOADS ("
						+ "COMMONUPLOADSID, ENTITYID, STATION, "
						+ "MODULE, MODULEID, CREATE_USER, "
						+ "CREATE_DATE, STATUS) VALUES (" + recordID + ", "
						+ entityID + ", "
						+ db.getInsertDBValue(bean.getStation()) + ", "
						+ db.getInsertDBValue(bean.getModule()) + ", "
						+ db.getInsertDBValue(moduleID + "") + ", "
						+ db.getInsertDBValue(loginUser) + ", "
						+ db.getInsertSysdate() + ", " + RecordStatus.ACTIVE
						+ ")";
			} else {
				// Update
				insQry = "UPDATE COMMONUPLOADS SET UPDATE_USER="
						+ db.getInsertDBValue(loginUser) + ", UPDATE_DATE="
						+ db.getInsertSysdate() + " WHERE COMMONUPLOADSID="
						+ recordID;
			}

			String destinationFolder = "";
			if (ApplicationConfig.getExternalDocsPath().length() > 0) {
				destinationFolder = fileUtility
						.getFileSourcePath(
								ApplicationConfig.getExternalDocsPath()
										+ File.separator + "Vehicles",
								bean.getVehicleNumber());
			}

			for (int i = 0; i < bean.getTransList().size(); i++) {
				List tempList = (ArrayList) bean.getTransList().get(i);
				String uploadFileName = tempList.get(0) == null ? ""
						: tempList.get(0).toString().trim();
				String docType = tempList.get(1) == null ? ""
						: tempList.get(1).toString().trim();
				String comments = "";
				if (tempList.size() > 2)
					comments = tempList.get(2) == null ? ""
							: tempList.get(2).toString().trim();
				String uploadFilePath = bean.getUploadFileNameWithPath().trim()
						+ "/" + uploadFileName;

				boolean isCopiedToExternal = false;
				if (destinationFolder.length() > 0
						&& "Inspection".equalsIgnoreCase(bean.getModule())) {
					String destinationFile = destinationFolder + File.separator
							+ uploadFileName;
					isCopiedToExternal = fileUtility.copyFile(uploadFilePath,
							destinationFile);
				}
				System.out.println(
						i + " :: isCopiedToExternal :: " + isCopiedToExternal
								+ " :: " + destinationFolder.length() + " :: "
								+ bean.getModule());

				String blobQry = buildTransQry(recordID, docType,
						uploadFileName, uploadFilePath, comments, loginUser);
				if (insQry.length() > 0) {
					result = db.insertBlob(insQry, blobQry, uploadFilePath);
					if (result)
						insQry = "";
				} else {
					result = db.insertBlob(blobQry, uploadFilePath);
				}
			}

			if (result && "Inspection".equalsIgnoreCase(bean.getModule())) {
				List<String> upList = new ArrayList<String>();

				upList = updateDADetails(bean.getVehicleID(),
						bean.getDaCheckinID(), bean.getParking(),
						bean.getDaComments(), loginUserID, entityID, upList);

				if ("4".equalsIgnoreCase(loginUserRoles)
						&& bean.getEmployeeID().length() > 0) {

					upList = buildEmployeeTimeOff(bean.getEmployeeID(),
							bean.getStation(), bean.getTimeOffStartDate(),
							bean.getTimeOffEndDate(), bean.getTimeOffReason(),
							bean.getTransMap(), loginUser, entityID, upList);

					upList = buildEmployeeAvailableDays(bean.getEmployeeID(),
							bean.getStation(), bean.getTransMap(), loginUser,
							entityID, upList);
				}

				db.batchInsert(upList);
			}
		}

		errorType = getErrorType(result, SubmitType.CREATE,
				bean.getDisplayName());

		return new Object[] { "", errorType };
	}

	public List<String> updateDADetails(String vehicleInspectionID,
			String daCheckinID, String parking, String daComments,
			String loginUser, String entityID, List<String> upList)
			throws Exception {

		String upQry = "UPDATE VEHICLEINSPECTION SET DACOMMENTS="
				+ db.getInsertDBValue(daComments) + ", UPDATE_USER="
				+ db.getInsertDBValue(loginUser) + ", UPDATE_DATE="
				+ db.getInsertSysdate() + " WHERE VEHICLEINSPECTIONID="
				+ vehicleInspectionID;
		upList.add(upQry);

		// Getting Active Checkin records available for that vehicle
		String selQry = "SELECT DISTINCT B.DACHECKINID FROM VEHICLEINSPECTION A, "
				+ "DACHECKIN B WHERE A.VEHICLEID=B.VEHICLEID AND A.ENTITYID="
				+ entityID + " AND B.STATUS=" + RecordStatus.ACTIVE
				+ " AND A.VEHICLEINSPECTIONID=" + vehicleInspectionID;
		String activeCheckinIDs = db.selectById(selQry);
		if (activeCheckinIDs.length() > 0) {
			upQry = "UPDATE DACHECKIN SET PARKING="
					+ db.getInsertDBValue(parking) + ", UPDATE_USER="
					+ db.getInsertDBValue(loginUser) + ", UPDATE_DATE="
					+ db.getInsertSysdate() + " WHERE ENTITYID=" + entityID
					+ " AND DACHECKINID IN (" + activeCheckinIDs + ")";
			upList.add(upQry);
		}

		String daCheckoutID = getTableColumnData("DACHECKOUTID", "DACHECKOUT",
				"DACHECKINID", daCheckinID);
		if (daCheckoutID.length() > 0) {
			upQry = "UPDATE DACHECKOUT SET PARKING="
					+ db.getInsertDBValue(parking) + ", UPDATE_USER="
					+ db.getInsertDBValue(loginUser) + ", UPDATE_DATE="
					+ db.getInsertSysdate() + " WHERE DACHECKOUTID="
					+ daCheckoutID;
			upList.add(upQry);
		}

		return upList;
	}

	@Override
	public CommonUpload fetchRecord(String recordID, String loginUser,
			String loginUserRoles, String loginUserID, String entityID,
			int submitType) throws Exception {

		bean = new CommonUpload();
		if (submitType == SubmitType.UPLOAD) {
			String selQry = "SELECT A.VEHICLEINSPECTIONID, B.VEHICLENUMBER "
					+ "FROM VEHICLEINSPECTION A, VEHICLE B WHERE "
					+ "A.VEHICLEID=B.VEHICLEID AND A.STATUS!="
					+ RecordStatus.DELETE
					+ db.getIDInCondQuery(entityID, "A.ENTITYID")
					+ db.getDateCondTypeQuery(db.EQUALS_TO, "A.INSPECTIONDATE")
					+ " ORDER BY 2 ";
			List vehiclesList = db.selectAsList(selQry, 2);
			bean.setVehiclesList(vehiclesList);
		}

		return bean;
	}

	@Override
	public String fetchBlobRecord(String recordID, String loginUser,
			String entityID) throws Exception {

		String blobQry = "SELECT UPLOADBLOB, " + db.getConcat(
				new String[] { "COMMONUPLOADSTRANSID", "'_'", "UPLOAD_NAME" })
				+ " FROM COMMONUPLOADSTRANS WHERE COMMONUPLOADSTRANSID="
				+ recordID;

		String folderName = fileUtility.getFolderPath("download",
				bean.getClass().getSimpleName(), loginUser);

		String filePath = db.fetchBlob(blobQry, folderName, "");

		return filePath;
	}

	public String buildTransQry(String recordID, String docType,
			String uploadFileName, String uploadFilePath, String comments,
			String loginUser) throws Exception {

		String autoIncrementArray[] = db
				.getAutoIncrementArray("COMMONUPLOADSTRANSID");
		String blobQry = "INSERT INTO COMMONUPLOADSTRANS (";
		if (autoIncrementArray != null)
			blobQry += autoIncrementArray[0];
		blobQry += "COMMONUPLOADSID, UPLOADTYPE, UPLOADBLOB, "
				+ "UPLOAD_NAME , UPLOADPATH, COMMENTS, CREATE_USER, "
				+ "CREATE_DATE, STATUS) VALUES (";
		if (autoIncrementArray != null)
			blobQry += autoIncrementArray[1];
		blobQry += recordID + ", " + db.getInsertDBValue(docType) + ", ?, "
				+ db.getInsertDBValue(uploadFileName) + ", "
				+ db.getInsertDBValue(uploadFilePath) + ", "
				+ db.getInsertDBValue(comments) + ", "
				+ db.getInsertDBValue(loginUser) + ", " + db.getInsertSysdate()
				+ ", " + RecordStatus.ACTIVE + ") ";

		return blobQry;
	}

	public List<String> buildEmployeeAvailableDays(String employeeID,
			String station, Map _transMap, String loginUser, String entityID,
			List<String> upList) throws Exception {

		int extraDayCNT = Integer
				.parseInt(_transMap.get("extraDayCNT") == null ? "0"
						: _transMap.get("extraDayCNT").toString().trim());
		for (int i = 0; i < extraDayCNT; i++) {
			String extraDayID = _transMap.get("extraDayID" + i) == null ? ""
					: _transMap.get("extraDayID" + i).toString().trim();
			String extraDayVal = _transMap.get("extraDayVal" + i) == null ? ""
					: _transMap.get("extraDayVal" + i).toString().trim();
			if (extraDayID.length() > 0) {
				if (extraDayVal.length() > 0) {
					String upQry = "UPDATE EMPLOYEE_EXTRADAYS SET EXTRADAY="
							+ db.getInsertDate(extraDayVal) + ", UPDATE_USER="
							+ db.getInsertDBValue(loginUser) + ", UPDATE_DATE="
							+ db.getInsertSysdate()
							+ " WHERE EMPLOYEE_EXTRADAYSID=" + extraDayID;
					upList.add(upQry);
				} else {
					upList.add(buildStatusQry("EMPLOYEE_EXTRADAYS",
							"EMPLOYEE_EXTRADAYSID", extraDayID,
							RecordStatus.DELETE, loginUser));
				}

			} else if (extraDayVal.length() > 0) {
				String recordID = db.getNextIDValue("EMPLOYEE_EXTRADAYSID");
				String insQry = "INSERT INTO EMPLOYEE_EXTRADAYS ("
						+ "EMPLOYEE_EXTRADAYSID, ENTITYID, STATION, "
						+ "EMPLOYEEID, EXTRADAY, CREATE_USER, "
						+ "CREATE_DATE, STATUS) VALUES (" + recordID + ", "
						+ entityID + ", " + db.getInsertDBValue(station) + ", "
						+ db.getInsertDBValue(employeeID) + ", "
						+ db.getInsertDate(extraDayVal) + ", "
						+ db.getInsertDBValue(loginUser) + ", "
						+ db.getInsertSysdate() + ", " + RecordStatus.ACTIVE
						+ ")";
				upList.add(insQry);
			}
		}

		return upList;

	}

	public List<String> buildEmployeeTimeOff(String employeeID, String station,
			String startDate, String endDate, String reason, Map _transMap,
			String loginUser, String entityID, List<String> upList)
			throws Exception {

		String delTimeOffIDs = _transMap.get("delTimeOffIDs") == null ? ""
				: _transMap.get("delTimeOffIDs").toString().trim();
		if (delTimeOffIDs.length() > 0)
			upList.add(buildStatusQry("EMPLOYEE_TIMEOFF", "EMPLOYEE_TIMEOFFID",
					delTimeOffIDs, RecordStatus.DELETE, loginUser));

		if (startDate.length() > 0) {
			String recordID = db.getNextIDValue("EMPLOYEE_TIMEOFFID");
			String insQry = "INSERT INTO EMPLOYEE_TIMEOFF ("
					+ "EMPLOYEE_TIMEOFFID, ENTITYID, STATION, EMPLOYEEID, "
					+ "START_DATE, END_DATE, REASON, CREATE_USER, "
					+ "CREATE_DATE, STATUS) VALUES (" + recordID + ", "
					+ entityID + ", " + db.getInsertDBValue(station) + ", "
					+ db.getInsertDBValue(employeeID) + ", "
					+ db.getInsertDate(startDate) + ", "
					+ db.getInsertDate(endDate) + ", "
					+ db.getInsertDBValue(reason) + ", "
					+ db.getInsertDBValue(loginUser) + ", "
					+ db.getInsertSysdate() + ", " + RecordStatus.ACTIVE + ")";
			upList.add(insQry);
		}

		return upList;
	}

	public String updateEmployeeTimeOffStatus(String recordID, String status,
			String comments, String loginUser, String entityID) {

		String upQry = "UPDATE EMPLOYEE_TIMEOFF SET STATUS="
				+ db.getInsertDBValue(status) + ", REVIEWER="
				+ db.getInsertDBValue(loginUser) + ", REVIEWEDON ="
				+ db.getInsertSysdate() + ", REVIEWERCOMMENTS="
				+ db.getInsertDBValue(comments) + ", UPDATE_USER="
				+ db.getInsertDBValue(loginUser) + ", UPDATE_DATE="
				+ db.getInsertSysdate() + " WHERE EMPLOYEE_TIMEOFFID="
				+ recordID;

		return upQry;
	}

	@Override
	public String getAjaxRequestTypeResp(String requestType,
			Map<String, String> requestMap, String loginUser,
			String loginUserRoles, String loginUserID, String entityID)
			throws Exception {

		String xmlMesg = "";
		if ("autoSaveImage".equalsIgnoreCase(requestType)) {
			boolean result = false;
			String folderName = fileUtility.getFolderPath(requestType,
					bean.getClass().getSimpleName(), loginUser);

			String recordID = requestMap.get("recordID") == null ? ""
					: requestMap.get("recordID").trim();
			String base64 = requestMap.get("base64") == null ? ""
					: requestMap.get("base64").trim();
			String docType = requestMap.get("docType") == null ? ""
					: requestMap.get("docType").trim();
			String uploadFileName = requestMap.get("fileName") == null ? ""
					: requestMap.get("fileName").trim();

			Object uploadArray[] = new FileUpload().uploadBase64File(base64,
					uploadFileName, folderName);
			boolean isUploaded = (Boolean) uploadArray[0];
			if (isUploaded) {
				String fileNameWithPath = uploadArray[1].toString();

				String moduleID = "";
				String module = requestMap.get("module") == null ? ""
						: requestMap.get("module").trim();
				if ("Inspection".equalsIgnoreCase(module)) {
					moduleID = requestMap.get("vehicleID") == null ? ""
							: requestMap.get("vehicleID").trim();

				} else if ("Employee".equalsIgnoreCase(module)) {
					moduleID = requestMap.get("employeeID") == null ? ""
							: requestMap.get("employeeID").trim();
				}

				if (moduleID.length() > 0) {
					String insQry = "";
					String station = requestMap.get("station") == null ? ""
							: requestMap.get("station").trim();
					String vehicleNumber = requestMap
							.get("vehicleNumber") == null ? ""
									: requestMap.get("vehicleNumber").trim();
					if (recordID.length() == 0) {
						recordID = db.getNextIDValue("COMMONUPLOADSID");
						insQry = "INSERT INTO COMMONUPLOADS ("
								+ "COMMONUPLOADSID, ENTITYID, STATION, "
								+ "MODULE, MODULEID, CREATE_USER, "
								+ "CREATE_DATE, STATUS) VALUES (" + recordID
								+ ", " + entityID + ", "
								+ db.getInsertDBValue(station) + ", "
								+ db.getInsertDBValue(module) + ", "
								+ db.getInsertDBValue(moduleID + "") + ", "
								+ db.getInsertDBValue(loginUser) + ", "
								+ db.getInsertSysdate() + ", "
								+ RecordStatus.ACTIVE + ")";
					} else {
						// Update
						insQry = "UPDATE COMMONUPLOADS SET UPDATE_USER="
								+ db.getInsertDBValue(loginUser)
								+ ", UPDATE_DATE=" + db.getInsertSysdate()
								+ " WHERE COMMONUPLOADSID=" + recordID;
					}

					String destinationFolder = "";
					if (ApplicationConfig.getExternalDocsPath().length() > 0) {
						destinationFolder = fileUtility.getFileSourcePath(
								ApplicationConfig.getExternalDocsPath()
										+ File.separator + "Vehicles",
								vehicleNumber);
					}

					String uploadFilePath = fileNameWithPath + "/"
							+ uploadFileName;

					boolean isCopiedToExternal = false;
					if (destinationFolder.length() > 0
							&& "Inspection".equalsIgnoreCase(module)) {
						String destinationFile = destinationFolder
								+ File.separator + uploadFileName;
						isCopiedToExternal = fileUtility
								.copyFile(uploadFilePath, destinationFile);
					}
					System.out.println("isCopiedToExternal :: "
							+ isCopiedToExternal + " :: "
							+ destinationFolder.length() + " :: " + module);

					String blobQry = buildTransQry(recordID, docType,
							uploadFileName, uploadFilePath, "", loginUser);
					if (insQry.length() > 0) {
						result = db.insertBlob(insQry, blobQry, uploadFilePath);
						if (result)
							insQry = "";
					} else {
						result = db.insertBlob(blobQry, uploadFilePath);
					}

				}
			}

			xmlMesg = "<statusDetails><status>" + result + "</status>"
					+ "<recordID>" + recordID + "</recordID></statusDetails>";
		}

		return xmlMesg;
	}
}
