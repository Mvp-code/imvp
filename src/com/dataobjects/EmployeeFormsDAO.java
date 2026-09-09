package com.dataobjects;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import com.beans.EmployeeForms;
import com.beans.ErrorBean;
import com.beans.MainBean;
import com.beans.SearchBean;
import com.tools.Base64ForCanvas;
import com.tools.FileUpload;
import com.util.RecordStatus;
import com.util.SubmitType;

public class EmployeeFormsDAO extends MVPGDAO {

	EmployeeForms bean = new EmployeeForms();

	@Override
	public SearchBean searchRecords(SearchBean searchBean, String recordID,
			String loginUser, String loginUserRoles, String loginUserID,
			String entityID) throws Exception {

		List<String> labelsList = new ArrayList<String>();
		labelsList.add("Date");
		labelsList.add("Employee");
		labelsList.add("Template");
		labelsList.add("Status");

		searchBean.setWidthColumns(new int[] { 15, 27, 40, 15 });

		searchBean.setDisplayName(bean.getDisplayName() + "s");

		searchBean.setController(bean.getController());

		String currentDate = db.getCurrentDate();
		if (!"yes".equalsIgnoreCase(searchBean.getSearchFilter())) {
			searchBean.setSrhFromDate(currentDate);
			searchBean.setSrhToDate(currentDate);
		}

		String condQry = db.getDateCondQuery(searchBean.getSrhFromDate(),
				searchBean.getSrhToDate(), "B.CREATE_DATE");

		condQry += db.getIDInCondQuery(searchBean.getSrhTypeID(),
				"B.FORMSTEMPLATEID");

		condQry += db.getIDInCondQuery(searchBean.getSrhEmployeeID(),
				"B.EMPLOYEEID");

		if (searchBean.getSrhStatus().length() > 0) {
			condQry += db.getIDInCondQuery(searchBean.getSrhStatus(),
					"B.STATUS");
		} else {
			condQry += db.getIDInCondQuery(
					RecordStatus.ACTIVE + "," + RecordStatus.POST, "B.STATUS");
		}

		searchBean.setColumnSortName(
				searchBean.getColumnSortName().replaceAll("2", "6"));

		String selQry = "SELECT B.EMPLOYEEFORMSID, "
				+ db.getSelectDate("B.CREATE_DATE")
				+ ", C.FULLNAME, A.FORMTYPE, B.STATUS, "
				+ db.getSelectDateFormat("B.CREATE_DATE", db.ORACLE_YYYYSMMSDD)
				+ " FROM FORMSTEMPLATE A, EMPLOYEEFORMS B, EMPLOYEE C "
				+ "WHERE A.FORMSTEMPLATEID=B.FORMSTEMPLATEID AND "
				+ "B.EMPLOYEEID=C.EMPLOYEEID AND B.ENTITYID=" + entityID
				+ condQry + getOrderByQry(searchBean, "6 DESC, 3, 4 ");

		searchBean.setColumnSortName(
				searchBean.getColumnSortName().replaceAll("6", "2"));

		List resultList = db.selectAsList(selQry, 6);
		if (resultList.size() > 0) {
			for (int i = 0; i < resultList.size(); i++) {
				List tempList = (ArrayList) resultList.get(i);
				String status = tempList.get(4) == null ? ""
						: tempList.get(4).toString().trim();

				status = RecordStatus.RecordStatus[Integer.parseInt(status)];
				tempList.set(4, status);
				resultList.set(i, tempList);
			}
		}

		searchBean.setLabelsList(labelsList);
		searchBean.setDataList(resultList);
		searchBean.setSearchFiltersArray(new String[] { "Date Range",
				"Employee", "Template", "Status" });
		return searchBean;
	}

	@Override
	public String getAjaxRequestTypeResp(String requestType,
			Map<String, String> requestMap, String loginUser,
			String loginUserRoles, String loginUserID, String entityID)
			throws Exception {

		String xmlMesg = "";
		if ("getFormTemplate".equalsIgnoreCase(requestType)) {
			String formContents = "";
			String recordID = requestMap.get("adminFormsTemplateID") == null
					? ""
					: requestMap.get("adminFormsTemplateID");
			if (recordID.length() > 0) {
				String fileName = "Form_" + recordID + ".html";
				String blobQry = "SELECT FORMBLOB FROM FORMSTEMPLATE "
						+ "WHERE FORMSTEMPLATEID=" + recordID;
				String folderName = fileUtility.getFolderPath("ajax",
						bean.getClass().getSimpleName(), loginUser);

				String fileNameWithPath = db.fetchBlob(blobQry, folderName,
						fileName);
				if (fileNameWithPath != null)
					formContents = fileUtility
							.getStringFromFile(fileNameWithPath);

			}

			xmlMesg = formContents;
		}

		return xmlMesg;
	}

	@Override
	public Object[] createRecord(MainBean mainBean, String loginUser,
			String loginUserRoles, String loginUserID, String entityID)
			throws Exception {

		bean = (EmployeeForms) mainBean;
		ErrorBean errorType = new ErrorBean();

		String condQry = db.getIDInCondQuery(bean.getAdminFormsTemplateID(),
				"FORMSTEMPLATEID");

		condQry += db.getIDInCondQuery(bean.getEmployeeID(), "EMPLOYEEID");

		condQry += db.getDateCondTypeQuery(db.EQUALS_TO, "CREATE_DATE");

		condQry += db.getDataInCondQuery(bean.getStation(), "STATION");

		String recordID = checkDuplicate("EMPLOYEEFORMS", "EMPLOYEEFORMSID", "",
				entityID, condQry);

		if (recordID.length() == 0) {
			recordID = db.getNextIDValue("EMPLOYEEFORMSID");

			String fileNameWithPath = getTemplateFilePath(bean, "create",
					recordID, loginUser);

			int status = bean.getStatus().length() == 0 ? RecordStatus.ACTIVE
					: Integer.parseInt(bean.getStatus());

			String insQry = "INSERT INTO EMPLOYEEFORMS (EMPLOYEEFORMSID, ENTITYID, "
					+ "FORMSTEMPLATEID, FORMBLOB, STATION, EMPLOYEEID, COMMENTS, "
					+ "CREATE_USER, CREATE_DATE, STATUS) VALUES (" + recordID
					+ ", " + entityID + ", "
					+ db.getInsertDBValue(bean.getAdminFormsTemplateID())
					+ ", ?, " + db.getInsertDBValue(bean.getStation()) + ", "
					+ db.getInsertDBValue(bean.getEmployeeID()) + ", "
					+ db.getInsertDBValue(bean.getComments()) + ", "
					+ db.getInsertDBValue(loginUser) + ", "
					+ db.getInsertSysdate() + ", " + db.getInsertDBValue(status)
					+ ")";

			boolean result = db.insertBlob(insQry, fileNameWithPath);

			errorType = getErrorType(result, SubmitType.CREATE,
					bean.getDisplayName());
		} else {
			errorType = getErrorType(false, SubmitType.DUPLICATE,
					bean.getDisplayName());

		}

		return new Object[] { recordID, errorType };
	}

	private String getTemplateFilePath(EmployeeForms bean, String type,
			String recordID, String loginUser) throws Exception {

		String folderName = fileUtility.getFolderPath(type,
				bean.getClass().getSimpleName(), loginUser);

		String formContents = bean.getFormContents().replaceAll("''", "'");
		String formData = "<formData>";
		formData += "<formContents>" + formContents + "</formContents>";

		if (bean.getSignatureValue().length() > 0) {
			String base64 = bean.getSignatureValue();
			String imageName = "EmpSign_" + recordID + ".png";
			boolean imageUploaded = saveSignature(base64, imageName, folderName,
					true);
			if (imageUploaded)
				formData += "<formSign>" + base64 + "</formSign>";
		}
		formData += "</formData>";

		String fileName = "EmpForm_" + recordID + ".html";
		String fileNameWithPath = fileUtility.writeDataToFile(folderName,
				fileName, formData);
		return fileNameWithPath;
	}

	private boolean saveSignature(String base64, String imageName,
			String imagePath, boolean isFileUpload) throws Exception {

		boolean imageUploaded = false;
		String imageNameWithPath = imagePath + "/" + imageName;
		if (isFileUpload) {
			Object uploadArray[] = new FileUpload().uploadBase64File(base64,
					imageName, imagePath);
			imageUploaded = (Boolean) uploadArray[0];

		} else {
			imageUploaded = Base64ForCanvas.decodeToFile(base64,
					imageNameWithPath);
		}

		System.out.println("saveSignature :: " + imageUploaded + " :: "
				+ imageUploaded + " :: " + imageNameWithPath);
		return imageUploaded;
	}

	@Override
	public Object[] updateRecord(MainBean mainBean, String loginUser,
			String loginUserRoles, String loginUserID, String entityID)
			throws Exception {

		bean = (EmployeeForms) mainBean;
		ErrorBean errorType = new ErrorBean();

		int status = bean.getStatus().length() == 0 ? RecordStatus.ACTIVE
				: Integer.parseInt(bean.getStatus());
		String recordID = bean.getEmployeeFormsID();

		String condQry = db.getIDInCondQuery(bean.getAdminFormsTemplateID(),
				"FORMSTEMPLATEID");

		condQry += db.getIDInCondQuery(bean.getEmployeeID(), "EMPLOYEEID");

		condQry += db.getDateCondTypeQuery(db.EQUALS_TO, "CREATE_DATE");

		condQry += db.getDataInCondQuery(bean.getStation(), "STATION");

		String duplicateID = checkDuplicate("EMPLOYEEFORMS", "EMPLOYEEFORMSID",
				recordID, entityID, condQry);

		if (duplicateID.length() == 0) {

			String fileNameWithPath = getTemplateFilePath(bean, "update",
					recordID, loginUser);

			String upQry = "UPDATE EMPLOYEEFORMS SET STATION="
					+ db.getInsertDBValue(bean.getStation()) + ", COMMENTS="
					+ db.getInsertDBValue(bean.getComments())
					+ ", FORMBLOB=?, UPDATE_USER="
					+ db.getInsertDBValue(loginUser) + ", UPDATE_DATE="
					+ db.getInsertSysdate() + ", STATUS="
					+ db.getInsertDBValue(status) + " WHERE EMPLOYEEFORMSID="
					+ recordID;

			boolean result = db.insertBlob(upQry, fileNameWithPath);

			errorType = getErrorType(result, SubmitType.UPDATE,
					bean.getDisplayName());

		} else {
			duplicateID = recordID;
			errorType = getErrorType(false, SubmitType.DUPLICATE,
					bean.getDisplayName());

		}

		return new Object[] { recordID, errorType };
	}

	@Override
	public Object[] deleteRecord(MainBean mainBean, String loginUser,
			String loginUserRoles, String loginUserID, String entityID)
			throws Exception {

		bean = (EmployeeForms) mainBean;
		ErrorBean errorType = new ErrorBean();
		List<String> upList = new ArrayList<String>();

		String recordID = bean.getEmployeeFormsID();
		upList.add(buildStatusQry("EMPLOYEEFORMS", "EMPLOYEEFORMSID", recordID,
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

		bean = (EmployeeForms) mainBean;
		ErrorBean errorType = new ErrorBean();
		List<String> upList = new ArrayList<String>();

		String recordID = bean.getEmployeeFormsID();
		upList.add(buildStatusQry("EMPLOYEEFORMS", "EMPLOYEEFORMSID", recordID,
				RecordStatus.POST, loginUser));

		boolean result = db.batchInsert(upList);

		errorType = getErrorType(result, SubmitType.FINAL,
				bean.getDisplayName());

		return new Object[] { recordID, errorType };
	}

	@Override
	public EmployeeForms fetchRecord(String recordID, String loginUser,
			String loginUserRoles, String loginUserID, String entityID,
			int submitType) throws Exception {

		String selQry = "SELECT B.EMPLOYEEFORMSID, B.ENTITYID, "
				+ "B.FORMSTEMPLATEID, A.FORMTYPE, '', B.STATION, "
				+ "C.EMPLOYEEID, C.FULLNAME, B.COMMENTS, B.CREATE_USER, "
				+ db.getSelectDateTime("B.CREATE_DATE") + ", B.UPDATE_USER, "
				+ db.getSelectDateTime("B.UPDATE_DATE")
				+ ", B.STATUS FROM FORMSTEMPLATE A, EMPLOYEEFORMS B, EMPLOYEE C "
				+ "WHERE A.FORMSTEMPLATEID=B.FORMSTEMPLATEID AND "
				+ "B.EMPLOYEEID=C.EMPLOYEEID AND B.ENTITYID=" + entityID
				+ " AND B.EMPLOYEEFORMSID=" + recordID;

		List resultList = new ArrayList();
		if (recordID.length() > 0)
			resultList = db.selectAsList(selQry,
					bean.getBeanAttributes().size() - 1);

		bean = (EmployeeForms) setListValuesToBean(bean,
				bean.getBeanAttributes(), resultList);

		if (bean.getEmployeeFormsID().length() > 0) {
			bean.setRecordID(bean.getEmployeeFormsID());

			String fileName = "EmpForm_" + recordID + ".html";
			String blobQry = "SELECT FORMBLOB FROM EMPLOYEEFORMS "
					+ "WHERE EMPLOYEEFORMSID=" + recordID;
			String folderName = fileUtility.getFolderPath("download",
					bean.getClass().getSimpleName(), loginUser);

			String fileNameWithPath = db.fetchBlob(blobQry, folderName,
					fileName);
			if (fileNameWithPath != null) {
				String formData = fileUtility
						.getStringFromFile(fileNameWithPath);

				String formContents = "", signFileNameWithPath = "";
				if (formData.startsWith("<formData>")) {
					formContents = formData.substring(
							formData.indexOf("<formContents>") + 14,
							formData.indexOf("</formContents>"));

					if (formData.contains("<formSign>")) {
						String formSign = formData.substring(
								formData.indexOf("<formSign>") + 10,
								formData.indexOf("</formSign>"));

						String imageName = "EmpSign_"
								+ bean.getEmployeeFormsID() + ".png";
						signFileNameWithPath = folderName + "/" + imageName;
						boolean imageUploaded = saveSignature(formSign,
								imageName, folderName, true);
						if (!imageUploaded)
							signFileNameWithPath = "";

					}

				} else {
					formContents = formData;
				}

				bean.setFormContents(formContents);
				bean.setSignFileNameWithPath(signFileNameWithPath);
			}
		}

		return bean;
	}

}
