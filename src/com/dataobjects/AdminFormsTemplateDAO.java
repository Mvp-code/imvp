package com.dataobjects;

import java.util.ArrayList;
import java.util.List;

import com.beans.AdminFormsTemplate;
import com.beans.ErrorBean;
import com.beans.MainBean;
import com.beans.SearchBean;
import com.util.RecordStatus;
import com.util.SubmitType;

public class AdminFormsTemplateDAO extends MVPGDAO {

	AdminFormsTemplate bean = new AdminFormsTemplate();

	@Override
	public SearchBean searchRecords(SearchBean searchBean, String recordID,
			String loginUser, String loginUserRoles, String loginUserID,
			String entityID) throws Exception {

		List<String> labelsList = new ArrayList<String>();
		labelsList.add("Name");
		labelsList.add("Status");

		searchBean.setWidthColumns(new int[] { 80, 20 });

		searchBean.setDisplayName(bean.getDisplayName() + "s");

		searchBean.setController(bean.getController());

		String condQry = "";

		condQry += db.getDataLikeCondQuery(searchBean.getSrhValue(),
				"FORMTYPE");

		if (searchBean.getSrhStatus().length() > 0) {
			condQry += db.getIDInCondQuery(searchBean.getSrhStatus(), "STATUS");
		} else {
			condQry += db.getIDInCondQuery(RecordStatus.ACTIVE + "", "STATUS");
		}

		String selQry = "SELECT FORMSTEMPLATEID, FORMTYPE, STATUS "
				+ "FROM FORMSTEMPLATE WHERE STATUS!=" + RecordStatus.DELETE
				+ " AND ENTITYID=" + entityID + condQry
				+ getOrderByQry(searchBean, "2");

		List resultList = db.selectAsList(selQry, 3);
		if (resultList.size() > 0) {
			for (int i = 0; i < resultList.size(); i++) {
				List tempList = (ArrayList) resultList.get(i);
				String status = tempList.get(2) == null ? ""
						: tempList.get(2).toString().trim();

				status = RecordStatus.RecordStatus[Integer.parseInt(status)];
				tempList.set(2, status);
				resultList.set(i, tempList);
			}
		}

		searchBean.setLabelsList(labelsList);
		searchBean.setDataList(resultList);
		searchBean.setSearchFiltersArray(new String[] { "Name" });
		return searchBean;
	}

	@Override
	public Object[] createRecord(MainBean mainBean, String loginUser,
			String loginUserRoles, String loginUserID, String entityID)
			throws Exception {

		bean = (AdminFormsTemplate) mainBean;
		ErrorBean errorType = new ErrorBean();

		String condQry = db.getDataInCondQuery(bean.getFormName(), "FORMTYPE");

		String recordID = checkDuplicate("FORMSTEMPLATE", "FORMSTEMPLATEID", "",
				entityID, condQry);

		if (recordID.length() == 0) {
			recordID = db.getNextIDValue("FORMSTEMPLATEID");

			String fileName = "Form_" + recordID + ".html";
			String folderName = fileUtility.getFolderPath("create",
					bean.getClass().getSimpleName(), loginUser);
			String fileNameWithPath = fileUtility.writeDataToFile(folderName,
					fileName, bean.getFormContents().replaceAll("''", "'"));

			int status = bean.getStatus().length() == 0 ? RecordStatus.ACTIVE
					: Integer.parseInt(bean.getStatus());

			String insQry = "INSERT INTO FORMSTEMPLATE (FORMSTEMPLATEID, ENTITYID, "
					+ "FORMTYPE, FORMBLOB, CREATE_USER, CREATE_DATE, STATUS) VALUES ("
					+ recordID + ", " + entityID + ", "
					+ db.getInsertDBValue(bean.getFormName()) + ", ?, "
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

	@Override
	public Object[] updateRecord(MainBean mainBean, String loginUser,
			String loginUserRoles, String loginUserID, String entityID)
			throws Exception {

		bean = (AdminFormsTemplate) mainBean;
		ErrorBean errorType = new ErrorBean();

		int status = bean.getStatus().length() == 0 ? RecordStatus.ACTIVE
				: Integer.parseInt(bean.getStatus());
		String recordID = bean.getAdminFormsTemplateID();

		String condQry = db.getDataInCondQuery(bean.getFormName(), "FORMTYPE");

		String duplicateID = checkDuplicate("FORMSTEMPLATE", "FORMSTEMPLATEID",
				recordID, entityID, condQry);

		if (duplicateID.length() == 0) {

			String fileName = "Form_" + recordID + ".html";
			String folderName = fileUtility.getFolderPath("update",
					bean.getClass().getSimpleName(), loginUser);
			String fileNameWithPath = fileUtility.writeDataToFile(folderName,
					fileName, bean.getFormContents().replaceAll("''", "'"));

			String upQry = "UPDATE FORMSTEMPLATE SET FORMTYPE="
					+ db.getInsertDBValue(bean.getFormName())
					+ ", FORMBLOB=?, UPDATE_USER="
					+ db.getInsertDBValue(loginUser) + ", UPDATE_DATE="
					+ db.getInsertSysdate() + ", STATUS="
					+ db.getInsertDBValue(status) + " WHERE FORMSTEMPLATEID="
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

		bean = (AdminFormsTemplate) mainBean;
		ErrorBean errorType = new ErrorBean();
		List<String> upList = new ArrayList<String>();

		String recordID = bean.getAdminFormsTemplateID();
		upList.add(buildStatusQry("FORMSTEMPLATE", "FORMSTEMPLATEID", recordID,
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

		bean = (AdminFormsTemplate) mainBean;
		ErrorBean errorType = new ErrorBean();
		List<String> upList = new ArrayList<String>();

		String recordID = bean.getAdminFormsTemplateID();
		upList.add(buildStatusQry("FORMSTEMPLATE", "FORMSTEMPLATEID", recordID,
				RecordStatus.POST, loginUser));

		boolean result = db.batchInsert(upList);

		errorType = getErrorType(result, SubmitType.FINAL,
				bean.getDisplayName());

		return new Object[] { recordID, errorType };
	}

	@Override
	public AdminFormsTemplate fetchRecord(String recordID, String loginUser,
			String loginUserRoles, String loginUserID, String entityID,
			int submitType) throws Exception {

		String selQry = "SELECT FORMSTEMPLATEID, ENTITYID, FORMTYPE, "
				+ "'', CREATE_USER, " + db.getSelectDateTime("CREATE_DATE")
				+ ", UPDATE_USER, " + db.getSelectDateTime("UPDATE_DATE")
				+ ", STATUS FROM FORMSTEMPLATE WHERE FORMSTEMPLATEID="
				+ recordID;

		List resultList = new ArrayList();
		if (recordID.length() > 0)
			resultList = db.selectAsList(selQry,
					bean.getBeanAttributes().size());

		bean = (AdminFormsTemplate) setListValuesToBean(bean,
				bean.getBeanAttributes(), resultList);

		if (bean.getAdminFormsTemplateID().length() > 0) {
			bean.setRecordID(bean.getAdminFormsTemplateID());

			String fileName = "Form_" + recordID + ".html";

			String blobQry = "SELECT FORMBLOB FROM FORMSTEMPLATE "
					+ "WHERE FORMSTEMPLATEID=" + recordID;

			String folderName = fileUtility.getFolderPath("download",
					bean.getClass().getSimpleName(), loginUser);

			String fileNameWithPath = db.fetchBlob(blobQry, folderName,
					fileName);
			if (fileNameWithPath != null) {
				String formContents = fileUtility
						.getStringFromFile(fileNameWithPath);
				bean.setFormContents(formContents);
			}
		}

		return bean;
	}
}
