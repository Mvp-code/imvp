package com.dataobjects;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Properties;

import com.beans.AdminConfiguration;
import com.beans.ErrorBean;
import com.beans.MainBean;
import com.beans.SearchBean;
import com.util.RecordStatus;
import com.util.SubmitType;

public class AdminConfigurationDAO extends MVPGDAO {

	AdminConfiguration bean = new AdminConfiguration();

	@Override
	public SearchBean searchRecords(SearchBean searchBean, String recordID,
			String loginUser, String loginUserRoles, String loginUserID,
			String entityID) throws Exception {

		List<String> labelsList = new ArrayList<String>();
		labelsList.add("Category");
		labelsList.add("Name");
		labelsList.add("Value");
		labelsList.add("Status");

		searchBean.setWidthColumns(new int[] { 15, 30, 45, 10 });

		searchBean.setDisplayName(bean.getDisplayName() + "s");

		searchBean.setController(bean.getController());
		searchBean.setSelectedType(SubmitType.UPDATE + "");

		String condQry = "";
		if (searchBean.getSrhStatus().length() == 0)
			searchBean.setSrhStatus(RecordStatus.ACTIVE + "");

		condQry += db.getIDInCondQuery(searchBean.getSrhStatus(), "STATUS");

		condQry += db.getDataInCondQuery(searchBean.getSrhValue(), "CATEGORY");

		String selQry = "SELECT PROPERTYID, CATEGORY, NAME, VALUE, "
				+ db.decodeStatus("STATUS",
						new int[] { RecordStatus.ACTIVE,
								RecordStatus.INACTIVE })
				+ " FROM PROPERTY WHERE STATUS!=" + RecordStatus.DELETE
				+ " AND ENTITYID=" + entityID + condQry + " ORDER BY 2, 3 ";
		List resultList = db.selectAsList(selQry, 5);

		if ((RecordStatus.ACTIVE + "")
				.equalsIgnoreCase(searchBean.getSrhStatus())) {

			List newResultList = new ArrayList();
			Map<String, String> _hMap = new HashMap<String, String>();
			List<String> pendingPrefList = new ArrayList<String>();
			String tempCateory = "";
			for (int i = 0; i < resultList.size(); i++) {
				List tempList = (ArrayList) resultList.get(i);
				String category = tempList.get(1) == null ? ""
						: tempList.get(1).toString().trim();
				String name = tempList.get(2) == null ? ""
						: tempList.get(2).toString().trim();

				if (_hMap.get(category) == null) {
					if (pendingPrefList.size() > 0) {
						for (int j = 0; j < pendingPrefList.size(); j++) {
							String tempProp = pendingPrefList.get(j);
							List tempList1 = new ArrayList();
							tempList1.add("");
							tempList1.add(tempCateory);
							tempList1.add(tempProp);
							tempList1.add("");
							tempList1.add("Active");
							newResultList.add(tempList1);
						}
					}
					tempCateory = category;
					pendingPrefList = getCategoryPrefList(category, entityID);
					_hMap.put(category, category);
				}
				newResultList.add(tempList);
				if (pendingPrefList.contains(name))
					pendingPrefList.remove(name);

			}

			for (int j = 0; j < pendingPrefList.size(); j++) {
				String tempProp = pendingPrefList.get(j);
				List tempList1 = new ArrayList();
				tempList1.add("");
				tempList1.add(tempCateory);
				tempList1.add(tempProp);
				tempList1.add("");
				tempList1.add("Active");
				newResultList.add(tempList1);
			}

			resultList = newResultList;
		}

		searchBean.setLabelsList(labelsList);
		searchBean.setDataList(resultList);
		searchBean.setSearchFiltersArray(new String[] { "Category", "Status" });

		return searchBean;
	}

	@Override
	public String getAjaxRequestTypeResp(String requestType,
			Map<String, String> requestMap, String loginUser,
			String loginUserRoles, String loginUserID, String entityID)
			throws Exception {

		String xmlMesg = "";
		if ("updateRecord".equalsIgnoreCase(requestType)) {
			List<String> upList = new ArrayList<String>();
			String propID = requestMap.get("propID") == null ? ""
					: requestMap.get("propID");
			String propCategory = requestMap.get("propCategory") == null ? ""
					: requestMap.get("propCategory");
			String propName = requestMap.get("propName") == null ? ""
					: requestMap.get("propName");
			String propValue = requestMap.get("propValue") == null ? ""
					: requestMap.get("propValue");
			String propStatus = requestMap.get("propStatus") == null ? ""
					: requestMap.get("propStatus");
			System.out.println("propID :: " + propID + " :: " + propCategory
					+ " :: " + propName + " :: " + propValue + " :: "
					+ propStatus);

			if (propID.length() > 0) {
				// Existing Property
				if ((RecordStatus.ACTIVE + "").equalsIgnoreCase(propStatus)) {
					String selQry = "SELECT STATUS FROM PROPERTY WHERE PROPERTYID="
							+ propID + " AND ENTITYID=" + entityID;
					String recordStatus = db.selectById(selQry);

					// Inactive to Active
					if ((RecordStatus.INACTIVE + "")
							.equalsIgnoreCase(recordStatus)) {
						selQry = "SELECT PROPERTYID FROM PROPERTY WHERE STATUS="
								+ RecordStatus.ACTIVE + " AND ENTITYID="
								+ entityID
								+ db.getDataInCondQuery(propName, "NAME")
								+ db.getDataInCondQuery(propCategory,
										"CATEGORY");
						String recordID = db.selectById(selQry);
						if (recordID.length() > 0) {
							// Updating existing records to Inactive
							String upQry = buildStatusQry("PROPERTY",
									"PROPERTYID", recordID,
									RecordStatus.INACTIVE, loginUser);
							upList.add(upQry);
						}

						// Chenge Inactive to Active
						String upQry = buildStatusQry("PROPERTY", "PROPERTYID",
								propID, RecordStatus.ACTIVE, loginUser);
						upList.add(upQry);

					} else {
						// Active to Inactive
						String upQry = buildStatusQry("PROPERTY", "PROPERTYID",
								propID, RecordStatus.INACTIVE, loginUser);
						upList.add(upQry);

						// New Record
						upList = buildInsQry(propCategory, propName, propValue,
								loginUser, entityID, upList);
					}

				} else if ((RecordStatus.INACTIVE + "")
						.equalsIgnoreCase(propStatus)) {
					String upQry = buildStatusQry("PROPERTY", "PROPERTYID",
							propID, RecordStatus.INACTIVE, loginUser);
					upList.add(upQry);
				}

			} else {
				// New Property
				String selQry = "SELECT PROPERTYID FROM PROPERTY WHERE STATUS="
						+ RecordStatus.ACTIVE + " AND ENTITYID=" + entityID
						+ db.getDataInCondQuery(propName, "NAME")
						+ db.getDataInCondQuery(propCategory, "CATEGORY");
				String recordID = db.selectById(selQry);

				if (recordID.length() > 0) {
					String upQry = buildStatusQry("PROPERTY", "PROPERTYID",
							recordID, RecordStatus.INACTIVE, loginUser);
					upList.add(upQry);
				}

				upList = buildInsQry(propCategory, propName, propValue,
						loginUser, entityID, upList);
			}

			boolean result = false;
			if (upList.size() > 0)
				result = db.batchInsert(upList);
			xmlMesg = "<status>" + result + "</status>";
		}

		return xmlMesg;
	}

	private List<String> buildInsQry(String cetegory, String name, String value,
			String loginUser, String entityID, List upList) throws Exception {

		// if NO DATA then don't insert record
		if (value.length() > 0) {
			String autoIncrementArray[] = db
					.getAutoIncrementArray("PROPERTYID");
			String insQry = "INSERT INTO PROPERTY (";
			if (autoIncrementArray != null)
				insQry += autoIncrementArray[0];
			insQry += "ENTITYID, CATEGORY, NAME, VALUE, "
					+ "CREATE_USER, CREATE_DATE, STATUS) VALUES (";
			if (autoIncrementArray != null)
				insQry += autoIncrementArray[1];
			insQry += entityID + ", " + db.getInsertDBValue(cetegory) + ", "
					+ db.getInsertDBValue(name) + ", "
					+ db.getInsertDBValue(value) + ", "
					+ db.getInsertDBValue(loginUser) + ", "
					+ db.getInsertSysdate() + ", " + RecordStatus.ACTIVE + ")";
			upList.add(insQry);
		}

		return upList;
	}

	@Override
	public Object[] createRecord(MainBean mainBean, String loginUser,
			String loginUserRoles, String loginUserID, String entityID)
			throws Exception {

		return new Object[] { "", new ErrorBean() };
	}

	@Override
	public Object[] updateRecord(MainBean mainBean, String loginUser,
			String loginUserRoles, String loginUserID, String entityID)
			throws Exception {

		return new Object[] { "", new ErrorBean() };
	}

	@Override
	public Object[] deleteRecord(MainBean mainBean, String loginUser,
			String loginUserRoles, String loginUserID, String entityID)
			throws Exception {

		return new Object[] { "", new ErrorBean() };
	}

	@Override
	public Object[] finalRecord(MainBean mainBean, String loginUser,
			String loginUserRoles, String loginUserID, String entityID)
			throws Exception {

		return new Object[] { "", new ErrorBean() };
	}

	@Override
	public AdminConfiguration fetchRecord(String recordID, String loginUser,
			String loginUserRoles, String loginUserID, String entityID,
			int submitType) throws Exception {

		bean = new AdminConfiguration();

		return bean;
	}

	private List<String> getCategoryPrefList(String category, String entityID)
			throws Exception {

		List<String> prefList = new ArrayList<String>();
		Class<? extends Enum<?>> enumClass;
		if ("SMS".equalsIgnoreCase(category)) {
			enumClass = AdminConfiguration.enumSMS.class;
		} else {
			enumClass = AdminConfiguration.enumGeneral.class;
		}

		Map<String, String> _hMap = new HashMap<String, String>();
		for (Enum<?> enumObj : enumClass.getEnumConstants()) {
			String propName = enumObj.name();
			if (propName.contains("__")) {
				String splitArray[] = propName.split("__");
				if (splitArray.length == 2) {
					String tempProp = splitArray[1];
					String tempCategory = tempProp.substring(0,
							tempProp.indexOf("_"));
					String tempPropName = tempProp
							.substring(tempProp.indexOf("_") + 1);
					if (tempCategory.length() > 0
							&& tempPropName.length() > 0) {
						String checkPref = tempCategory + "_" + tempPropName;
						String tempPropValue = "";
						if (_hMap.get(checkPref) == null) {
							tempPropValue = getPropertyValue(tempCategory,
									tempPropName, entityID);
							_hMap.put(checkPref, tempPropValue);
						} else {
							tempPropValue = _hMap.get(checkPref);
						}

						String propArray[] = tempPropValue.split("#");
						for (int j = 0; j < propArray.length; j++) {
							propArray[j] = propArray[j].trim();
							if (propArray[j].length() > 0) {
								propName = splitArray[0] + "_" + propArray[j];
								prefList.add(propName);
							}
						}
					}
				}

			} else {
				prefList.add(propName);
			}
		}

		return prefList;
	}

	private List buildPropList(String name, String value, String inputType,
			List dataList) {

		List tempList = new ArrayList();
		tempList.add(name);
		tempList.add(value);
		tempList.add(inputType);
		dataList.add(tempList);

		return dataList;
	}

	public boolean isProperties(String category, String entityID) {

		try {
			Properties prop = getProperties(category, null, entityID);
			if (prop.size() > 0)
				return true;
		} catch (Exception ex) {
			ex.printStackTrace();
		}

		return false;
	}

	public Properties getProperties(String category, String propArray[],
			String entityID) throws Exception {

		Properties prop = new Properties();
		String condQry = "";
		String selQry = "SELECT NAME, VALUE FROM PROPERTY WHERE CATEGORY LIKE '"
				+ category + "' AND STATUS=" + RecordStatus.ACTIVE
				+ " AND ENTITYID=" + entityID + " AND VALUE IS NOT NULL ";
		if (propArray != null) {
			for (int i = 0; i < propArray.length; i++) {
				propArray[i] = propArray[i].trim();
				if (propArray[i].length() > 0) {
					if (condQry.length() == 0) {
						condQry = "NAME IN ('" + propArray[i] + "'";
					} else {
						condQry += ", '" + propArray[i] + "'";
					}
				}
			}
			if (condQry.length() > 0)
				condQry += ")";
		}
		selQry += condQry;

		try {
			List resultList = db.selectAsList(selQry, 2);
			for (int i = 0; i < resultList.size(); i++) {
				List tempList = (ArrayList) resultList.get(i);
				String name = tempList.get(0) == null ? ""
						: tempList.get(0).toString().trim();
				String value = tempList.get(1) == null ? ""
						: tempList.get(1).toString().trim();
				prop.put(name, value);
			}
		} catch (Exception ex) {
			ex.printStackTrace();
		}

		return prop;
	}

	public String getPropertyValue(String propName, Properties prop) {

		String propValue = prop.getProperty(propName) == null ? ""
				: prop.getProperty(propName).trim();
		return propValue;

	}

	public String getPropertyValue(String category, String propName,
			String entityID) throws Exception {

		String propVal = "";
		String selQry = "SELECT NAME, VALUE FROM PROPERTY WHERE CATEGORY LIKE '"
				+ category + "' AND STATUS=" + RecordStatus.ACTIVE
				+ db.getDataInCondQuery(propName, "NAME") + " AND ENTITYID="
				+ entityID + " AND VALUE IS NOT NULL";
		try {
			List resultList = db.selectAsList(selQry, 2);
			if (resultList.size() > 0) {
				List tempList = (ArrayList) resultList.get(0);
				String name = tempList.get(0) == null ? ""
						: tempList.get(0).toString().trim();
				propVal = tempList.get(1) == null ? ""
						: tempList.get(1).toString().trim();

			}
		} catch (Exception ex) {
			ex.printStackTrace();
		}

		return propVal;
	}

}
