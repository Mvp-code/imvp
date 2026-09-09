package com.dataobjects;

import java.util.ArrayList;
import java.util.List;

import com.beans.AdminGasCard;
import com.beans.ErrorBean;
import com.beans.MainBean;
import com.beans.SearchBean;
import com.util.RecordStatus;
import com.util.SubmitType;

public class AdminGasCardDAO extends MVPGDAO {

	AdminGasCard bean = new AdminGasCard();

	@Override
	public SearchBean searchRecords(SearchBean searchBean, String recordID,
			String loginUser, String loginUserRoles, String loginUserID,
			String entityID) throws Exception {

		List<String> labelsList = new ArrayList<String>();
		labelsList.add("Card ID");
		labelsList.add("Card Status");
		labelsList.add("Card Status Date");
		labelsList.add("Card Expiry");
		labelsList.add("Lock Status");
		labelsList.add("Location");
		labelsList.add("Available");

		searchBean.setWidthColumns(new int[] { 10, 15, 20, 10, 15, 20, 10 });

		searchBean.setDisplayName(bean.getDisplayName() + "s");

		searchBean.setController(bean.getController());

		String condQry = "";

		condQry += db.getIDInCondQuery(searchBean.getSrhValue(),
				"CARDIDENTIFIER");

		if (searchBean.getSrhStatus().length() > 0) {
			condQry += db.getIDInCondQuery(searchBean.getSrhStatus(),
					"CARDSTATUS");
		} else {
			searchBean.setSrhStatus(RecordStatus.ACTIVE + "");
			condQry += db.getIDInCondQuery(searchBean.getSrhStatus(),
					"CARDSTATUS");
		}

		if (searchBean.getSrhStatusDate().length() > 0)
			condQry += db.getDateCondTypeQuery(db.EQUALS_TO, "CARDSTATUSDATE",
					searchBean.getSrhStatusDate(), db.ORACLE_MMSDDSYYYY);

		if (searchBean.getSrhExpiryDate().length() > 0)
			condQry += db.getDateCondTypeQuery(db.EQUALS_TO, "CARDEXPIRY",
					searchBean.getSrhExpiryDate(), db.ORACLE_MMSDDSYYYY);

		searchBean.setColumnSortName(searchBean.getColumnSortName()
				.replaceAll("4", "9").replaceAll("5", "10"));

		String selQry = "SELECT GASCARDID, CARDIDENTIFIER, CARDSTATUS, "
				+ db.getSelectDate("CARDSTATUSDATE") + ", "
				+ db.getSelectDate("CARDEXPIRY")
				+ ", LOCKSTATUS, LOCATION, AVAILABLE, "
				+ db.getSelectDateFormat("CARDSTATUSDATE",
						db.ORACLE_YYYYMMDDHH24MISS)
				+ ", "
				+ db.getSelectDateFormat("CARDEXPIRY",
						db.ORACLE_YYYYMMDDHH24MISS)
				+ " FROM GASCARDS WHERE STATUS!=" + RecordStatus.DELETE
				+ " AND ENTITYID=" + entityID + condQry
				+ getOrderByQry(searchBean, "2");

		searchBean.setColumnSortName(searchBean.getColumnSortName()
				.replaceAll("9", "4").replaceAll("10", "5"));

		List resultList = db.selectAsList(selQry, 10);
		if (resultList.size() > 0) {
			for (int i = 0; i < resultList.size(); i++) {
				List tempList = (ArrayList) resultList.get(i);
				String cardStatus = tempList.get(2) == null ? ""
						: tempList.get(2).toString().trim();
				String lockStatus = tempList.get(5) == null ? ""
						: tempList.get(5).toString().trim();
				String available = tempList.get(7) == null ? ""
						: tempList.get(7).toString().trim();

				cardStatus = RecordStatus.RecordStatus[Integer
						.parseInt(cardStatus)];
				lockStatus = RecordStatus.RecordStatus[Integer
						.parseInt(lockStatus)];
				available = "1".equalsIgnoreCase(available) ? "Yes" : "No";

				tempList.set(2, cardStatus);
				tempList.set(5, lockStatus);
				tempList.set(7, available);
				resultList.set(i, tempList);
			}
		}

		searchBean.setLabelsList(labelsList);
		searchBean.setDataList(resultList);
		searchBean.setSearchFiltersArray(new String[] { "Card ID",
				"Card Status", "Card Status Date", "Expiry Date" });
		return searchBean;
	}

	@Override
	public Object[] createRecord(MainBean mainBean, String loginUser,
			String loginUserRoles, String loginUserID, String entityID)
			throws Exception {

		bean = (AdminGasCard) mainBean;
		ErrorBean errorType = new ErrorBean();
		List<String> insList = new ArrayList<String>();
		String recordID = "";

		String condQry = db.getIDInCondQuery(bean.getCardIdentifier(),
				"CARDIDENTIFIER");

		String selQry = "SELECT GASCARDID FROM GASCARDS WHERE STATUS IN ("
				+ RecordStatus.ACTIVE + ") AND ENTITYID=" + entityID + condQry;

		List resultList = db.selectAsList(selQry, 1);
		if (resultList.size() > 0) {
			List tempList = (ArrayList) resultList.get(0);
			recordID = tempList.get(0) == null ? ""
					: tempList.get(0).toString().trim();

		}

		if (recordID.length() == 0) {
			int status = bean.getStatus().length() == 0 ? RecordStatus.ACTIVE
					: Integer.parseInt(bean.getStatus());
			recordID = db.getNextIDValue("GASCARDID");

			String insQry = "INSERT INTO GASCARDS (GASCARDID, ENTITYID, "
					+ "CARDIDENTIFIER, CARDSTATUS, CARDSTATUSDATE, CARDSTATUSREASON, "
					+ "CARDEXPIRY, LOCKSTATUS, LOCATION, AVAILABLE, CREATE_USER, "
					+ "CREATE_DATE, STATUS) VALUES (" + recordID + ", "
					+ entityID + ", "
					+ db.getInsertDBValue(bean.getCardIdentifier()) + ", "
					+ db.getInsertDBValue(bean.getCardStatus()) + ", "
					+ db.getInsertDate(bean.getCardStatusDate()) + ", "
					+ db.getInsertDBValue(bean.getCardStatusReason()) + ", "
					+ db.getInsertDate(bean.getCardExpiry()) + ", "
					+ db.getInsertDBValue(bean.getLockStatus()) + ", "
					+ db.getInsertDBValue(bean.getLocation()) + ", "
					+ db.getInsertDBValue(bean.getAvailable()) + ", "
					+ db.getInsertDBValue(loginUser) + ", "
					+ db.getInsertSysdate() + ", " + db.getInsertDBValue(status)
					+ ")";
			insList.add(insQry);

			boolean result = db.batchInsert(insList);

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

		bean = (AdminGasCard) mainBean;
		ErrorBean errorType = new ErrorBean();
		List<String> upList = new ArrayList<String>();

		int status = bean.getStatus().length() == 0 ? RecordStatus.ACTIVE
				: Integer.parseInt(bean.getStatus());

		String recordID = bean.getGasCardID();
		String upQry = "UPDATE GASCARDS SET CARDIDENTIFIER="
				+ db.getInsertDBValue(bean.getCardIdentifier())
				+ ", CARDSTATUS=" + db.getInsertDBValue(bean.getCardStatus())
				+ ", CARDSTATUSDATE="
				+ db.getInsertDate(bean.getCardStatusDate())
				+ ", CARDSTATUSREASON="
				+ db.getInsertDBValue(bean.getCardStatusReason())
				+ ", CARDEXPIRY=" + db.getInsertDate(bean.getCardExpiry())
				+ ", LOCKSTATUS=" + db.getInsertDBValue(bean.getLockStatus())
				+ ", LOCATION=" + db.getInsertDBValue(bean.getLocation())
				+ ", AVAILABLE=" + db.getInsertDBValue(bean.getAvailable())
				+ ", UPDATE_USER=" + db.getInsertDBValue(loginUser)
				+ ", UPDATE_DATE=" + db.getInsertSysdate() + ", STATUS="
				+ db.getInsertDBValue(status) + " WHERE GASCARDID=" + recordID;
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

		bean = (AdminGasCard) mainBean;
		ErrorBean errorType = new ErrorBean();
		List<String> upList = new ArrayList<String>();

		String recordID = bean.getGasCardID();
		upList.add(buildStatusQry("GASCARDS", "GASCARDID", recordID,
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

		bean = (AdminGasCard) mainBean;
		ErrorBean errorType = new ErrorBean();
		List<String> upList = new ArrayList<String>();

		String recordID = bean.getGasCardID();
		upList.add(buildStatusQry("GASCARDS", "GASCARDID", recordID,
				RecordStatus.POST, loginUser));

		boolean result = db.batchInsert(upList);

		errorType = getErrorType(result, SubmitType.FINAL,
				bean.getDisplayName());

		return new Object[] { recordID, errorType };
	}

	@Override
	public AdminGasCard fetchRecord(String recordID, String loginUser,
			String loginUserRoles, String loginUserID, String entityID,
			int submitType) throws Exception {

		String selQry = "SELECT GASCARDID, ENTITYID, CARDIDENTIFIER, CARDSTATUS, "
				+ db.getSelectDate("CARDSTATUSDATE") + ", CARDSTATUSREASON, "
				+ db.getSelectDate("CARDEXPIRY") + ", LOCKSTATUS, "
				+ "LOCATION, AVAILABLE, CREATE_USER, "
				+ db.getSelectDateTime("CREATE_DATE") + ", UPDATE_USER, "
				+ db.getSelectDateTime("UPDATE_DATE")
				+ ", STATUS FROM GASCARDS WHERE GASCARDID=" + recordID;

		List resultList = new ArrayList();
		if (recordID.length() > 0)
			resultList = db.selectAsList(selQry,
					bean.getBeanAttributes().size());

		bean = (AdminGasCard) setListValuesToBean(bean,
				bean.getBeanAttributes(), resultList);

		if (submitType == SubmitType.CREATE) {
			bean.setCardStatusDate(db.getCurrentDate());
		}

		return bean;
	}
}
