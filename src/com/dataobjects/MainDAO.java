package com.dataobjects;

import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.apache.commons.beanutils.ConvertUtils;
import org.apache.commons.beanutils.PropertyUtils;

import com.beans.ErrorBean;
import com.beans.MainBean;
import com.beans.SearchBean;
import com.tools.FileUtility;
import com.util.MainUtil;
import com.util.SubmitType;

public class MainDAO {

	MainUtil mainUtil = new MainUtil();
	SimpleDateFormat sdfMMDDYYYY = new SimpleDateFormat("MM/dd/yyyy");
	SimpleDateFormat sdfYYYY_D_MM_D_DD = new SimpleDateFormat("yyyy-MM-dd");
	SimpleDateFormat sdfMMDDYYYY_HHCMM_AM = new SimpleDateFormat(
			"MM/dd/yyyy hh:mm a");

	FileUtility fileUtility = new FileUtility();

	public ErrorBean getErrorType(boolean result, int submitType,
			String displayName) {

		String errMesg = displayName;
		String errType = "";
		if (result) {
			errType = ErrorBean.enumTypes.success.toString();
			switch (submitType) {
			case SubmitType.CREATE:
				errMesg += " created";
				break;

			case SubmitType.UPDATE:
				errMesg += " updated";
				break;

			case SubmitType.FINAL:
				errMesg += " posted";
				break;

			case SubmitType.WITH_HOLD:
				errMesg += " unposted";
				break;

			case SubmitType.DELETE:
				errMesg += " deleted";
				break;

			case SubmitType.LOGOUT:
				errMesg += " Logout successful";
				break;
			}

		} else {
			errType = ErrorBean.enumTypes.notice.toString();
			switch (submitType) {
			case SubmitType.DUPLICATE:
				errMesg += " already exists. Please check it";
				break;

			case SubmitType.CONCURRENCY:
				errMesg += " was modified by another user. Please check it";
				break;

			case SubmitType.LOGIN:
				errType = ErrorBean.enumTypes.error.toString();
				if (errMesg.length() == 0)
					errMesg += " Invalid credentials";
				break;

			default:
				errType = ErrorBean.enumTypes.error.toString();
				errMesg = "Error!! Data not updated. Please check entries and retry...";
			}
		}

		ErrorBean errorType = new ErrorBean();
		errorType.setType(errType);
		errorType.setMesg(errMesg);

		return errorType;
	}

	public MainBean setValuesToBean(Map<String, String> requestMap,
			MainBean bean) throws Exception {

		List<String> beanAttributes = bean.getBeanAttributes();
		for (int i = 0; i < beanAttributes.size(); i++) {
			String beanElementName = beanAttributes.get(i);
			Object beanElementValue = requestMap.get(beanElementName) == null
					? ""
					: requestMap.get(beanElementName);
			Class<?> classType = PropertyUtils.getPropertyType(bean,
					beanElementName);
			beanElementValue = ConvertUtils.convert(beanElementValue,
					classType);
			if (beanElementValue.toString().length() > 0)
				System.out.println("setValuesToBean :: " + beanElementName
						+ " :: " + beanElementValue);
			PropertyUtils.setProperty(bean, beanElementName, beanElementValue);
		}

		return bean;
	}

	public MainBean setListValuesToMainBean(MainBean mainBean,
			List<String> beanAttributesList, List result) {

		try {
			System.out.println("setListValuesToMainBean :: " + result + " :: "
					+ result.size());
			if (result.size() > 0) {
				result = (ArrayList) result.get(0);
				String beanElementName = "";
				Object beanElementValue = "";
				for (int i = 0; i < result.size(); i++) {
					beanElementName = beanAttributesList.get(i);
					beanElementValue = result.get(i) == null ? ""
							: result.get(i).toString().trim();
					Class<?> classType = PropertyUtils.getPropertyType(mainBean,
							beanElementName);
					beanElementValue = ConvertUtils.convert(beanElementValue,
							classType);
					PropertyUtils.setProperty(mainBean, beanElementName,
							beanElementValue);
					if (i == 0)
						mainBean.setRecordID(beanElementValue.toString());

				}
			}
		} catch (Exception ex) {
			ex.printStackTrace();
		}

		return mainBean;
	}

	public Object[] login(MainBean bean, String ipAddress, String sessionID,
			String loginUser, String loginUserRoles, String loginUserID,
			String entityID) throws Exception {

		return new Object[] {};
	}

	public Object[] logout(MainBean bean, String ipAddress, String sessionID,
			String loginUser, String loginUserRoles, String loginUserID,
			String entityID) throws Exception {

		return new Object[] {};
	}

	public SearchBean searchRecords(SearchBean searchBean, String recordID,
			String loginUser, String loginUserRoles, String loginUserID,
			String entityID) throws Exception {

		return searchBean;
	}

	public String fetchBlobRecord(String recordID, String loginUser,
			String entityID) throws Exception {

		return "";
	}

	public Object[] createRecord(MainBean bean, String loginUser,
			String loginUserRoles, String loginUserID, String entityID)
			throws Exception {

		return new Object[] {};
	}

	public double updateFromFile(List<String> columnsList, List dataList,
			String loginUser, String entityID, Map<String, String> _reqMap) {

		return 0;
	}

	public Object[] updateRecord(MainBean bean, String loginUser,
			String loginUserRoles, String loginUserID, String entityID)
			throws Exception {

		return new Object[] {};
	}

	public Object fetchRecord(String recordID, String loginUser,
			String loginUserRoles, String loginUserID, String entityID,
			int submitType) throws Exception {

		return new Object();
	}

	public Object[] finalRecord(MainBean bean, String loginUser,
			String loginUserRoles, String loginUserID, String entityID)
			throws Exception {

		return new Object[] {};
	}

	public Object[] withHoldRecord(MainBean bean, String loginUser,
			String loginUserRoles, String loginUserID, String entityID)
			throws Exception {

		return new Object[] {};
	}

	public Object[] changeRecord(MainBean bean, String loginUser,
			String loginUserRoles, String loginUserID, String entityID)
			throws Exception {

		return new Object[] {};
	}

	public Object[] deleteRecord(MainBean bean, String loginUser,
			String loginUserRoles, String loginUserID, String entityID)
			throws Exception {

		return new Object[] {};
	}

	public String getIndexedDataFromList(List resultsList, int indexVal,
			String dataSeperator) {

		StringBuffer returnBuff = new StringBuffer();
		List<String> duplicateList = new ArrayList<String>();
		List tempList = null;
		;
		for (int i = 0; i < resultsList.size(); i++) {
			tempList = (List) resultsList.get(i);
			if (tempList.size() > indexVal) {
				String data = tempList.get(indexVal) == null ? ""
						: tempList.get(indexVal).toString().trim();
				if (data.length() > 0 && !duplicateList.contains(data)) {
					duplicateList.add(data);
					if (returnBuff.length() > 0)
						returnBuff.append(dataSeperator);
					returnBuff.append(data);
				}
			}
		}

		return returnBuff.toString();
	}

	public List<String> getUniqueDataFromList(List resultsList, int indexVal,
			List<String> returnList) {

		List tempList = null;
		for (int i = 0; i < resultsList.size(); i++) {
			tempList = (List) resultsList.get(i);
			if (tempList.size() > indexVal) {
				String data = tempList.get(indexVal) == null ? ""
						: tempList.get(indexVal).toString().trim();
				if (data.length() > 0 && !returnList.contains(data)) {
					returnList.add(data);
				}
			}
		}

		return returnList;
	}

	public Map<String, List> getGroupByIDListMap(int mainIDIndex,
			List resultList) {

		System.out.println("getGroupByIDListMap :: " + resultList.size());
		Map<String, List> _hMap = new HashMap<String, List>();
		List tempList = null;
		List transList = new ArrayList();
		String tempID = "";
		for (int i = 0; i < resultList.size(); i++) {
			tempList = (ArrayList) resultList.get(i);
			String id = tempList.get(mainIDIndex).toString().trim();
			if (!id.equalsIgnoreCase(tempID)) {
				if (i != 0 && transList.size() > 0) {
					_hMap.put(tempID, transList);
					System.out.println("getGroupByIDListMap :: " + tempID
							+ " :: " + transList.size());
				}
				tempID = id;
				transList = new ArrayList();
			}
			transList.add(tempList);
		}

		if (transList.size() > 0) {
			_hMap.put(tempID, transList);
			System.out.println("getGroupByIDListMap :: " + tempID + " :: "
					+ transList.size());
		}

		return _hMap;
	}

	public Map<String, String> getMap(List resultList) throws Exception {

		Map<String, String> _hMap = new HashMap<String, String>();
		for (int i = 0; i < resultList.size(); i++) {
			List tempList = (ArrayList) resultList.get(i);
			String key = tempList.get(0) == null ? ""
					: tempList.get(0).toString().trim();
			String value = tempList.get(1) == null ? ""
					: tempList.get(1).toString().trim();
			_hMap.put(key, value);
		}

		return _hMap;
	}

	public String getXmlData(String requestType, List resultList,
			String[] labelArray) {

		StringBuffer xmlMesg = new StringBuffer();
		xmlMesg.append("<" + requestType + "Details>");
		for (int i = 0; i < resultList.size(); i++) {
			List tempList = (ArrayList) resultList.get(i);
			xmlMesg.append("<" + requestType + "Trans>");
			for (int j = 0; j < labelArray.length; j++) {
				xmlMesg = buildXML(labelArray[j], getListData(tempList, j),
						xmlMesg);
			}
			xmlMesg.append("</" + requestType + "Trans>");
		}
		xmlMesg.append("</" + requestType + "Details>");

		return xmlMesg.toString();
	}

	public String getSuggextorData(List resultList, String selectedVal) {

		String xmlMesg = "";
		xmlMesg += "<option value=\"\"></option>";
		for (int i = 0; i < resultList.size(); i++) {
			String value = "", text = "";
			if (resultList.get(i) instanceof String) {
				value = resultList.get(i) == null ? ""
						: resultList.get(i).toString().trim();
				text = value;

			} else {
				List tempList = (ArrayList) resultList.get(i);
				if (tempList.size() == 1) {
					value = tempList.get(0) == null ? ""
							: tempList.get(0).toString().trim();
					text = value;
				} else {
					value = tempList.get(0) == null ? ""
							: tempList.get(0).toString().trim();
					text = tempList.get(1) == null ? ""
							: tempList.get(1).toString().trim();
				}
			}

			boolean isSelected = false;
			if (selectedVal.length() > 0) {
				String splitArray[] = selectedVal.split(",");
				for (int j = 0; j < splitArray.length; j++) {
					splitArray[j] = splitArray[j].trim();
					if (splitArray[j].length() > 0
							&& splitArray[j].equalsIgnoreCase(value)) {
						isSelected = true;
						break;
					}
				}
			}

			if (isSelected) {
				xmlMesg += "<option value=\"" + value + "\" title=\"" + text
						+ "\" selected>" + text + "</option>";
			} else {
				xmlMesg += "<option value=\"" + value + "\" title=\"" + text
						+ "\">" + text + "</option>";
			}
		}

		return xmlMesg;
	}

	public StringBuffer buildXML(String tagName, String value,
			StringBuffer xmlMesg) {

		if (value.length() > 0) {
			xmlMesg.append("<").append(tagName).append(">");
			xmlMesg.append(value.replaceAll("¿", "&iquest;")
					.replaceAll("&", "&amp;").replaceAll("<", "&lt;")
					.replaceAll(">", "&gt;").replaceAll("\"", "&quot;")
					.replaceAll("\'", "&#39;").replaceAll("°", "&#xb0;")
					.replaceAll("é", "&#xe9;").replaceAll("è", "&#xe8;")
					.replaceAll("&nbsp;", "&#160;").trim());
			xmlMesg.append("</").append(tagName).append(">");
		}

		return xmlMesg;

	}

	public List<String> getUSStates() {
		List<String> statesSet = new ArrayList<String>();
		statesSet.add("Alabama");
		statesSet.add("Alaska");
		statesSet.add("Arizona");
		statesSet.add("Arkansas");
		statesSet.add("California");
		statesSet.add("Colorado");
		statesSet.add("Connecticut");
		statesSet.add("Delaware");
		statesSet.add("District of Columbia");
		statesSet.add("Florida");
		statesSet.add("Georgia");
		statesSet.add("Hawaii");
		statesSet.add("Idaho");
		statesSet.add("Illinois");
		statesSet.add("Indiana");
		statesSet.add("Iowa");
		statesSet.add("Kansas");
		statesSet.add("Kentucky");
		statesSet.add("Louisiana");
		statesSet.add("Maine");
		statesSet.add("Maryland");
		statesSet.add("Massachusetts");
		statesSet.add("Michigan");
		statesSet.add("Minnesota");
		statesSet.add("Mississippi");
		statesSet.add("Missouri");
		statesSet.add("Montana");
		statesSet.add("Nebraska");
		statesSet.add("Nevada");
		statesSet.add("New Hampshire");
		statesSet.add("New Jersey");
		statesSet.add("New Mexico");
		statesSet.add("New York");
		statesSet.add("North Carolina");
		statesSet.add("North Dakota");
		statesSet.add("Ohio");
		statesSet.add("Oklahoma");
		statesSet.add("Oregon");
		statesSet.add("Pennsylvania");
		statesSet.add("Rhode Island");
		statesSet.add("South Carolina");
		statesSet.add("South Dakota");
		statesSet.add("Tennessee");
		statesSet.add("Texas");
		statesSet.add("Utah");
		statesSet.add("Vermont");
		statesSet.add("Virginia");
		statesSet.add("Washington");
		statesSet.add("West Virginia");
		statesSet.add("Wisconsin");
		statesSet.add("Wyoming");
		return statesSet;
	}

	@SuppressWarnings({ "rawtypes", "unchecked" })
	public List sortListData(List dataList, int index) throws Exception {
		return sortListData(dataList, index, true);
	}

	@SuppressWarnings({ "rawtypes", "unchecked" })
	public List sortListData(List dataList, int index, boolean isAscending)
			throws Exception {

		final int sortIndex = index;
		List sortedList = dataList;

		try {
			Collections.sort(sortedList, new Comparator() {
				public int compare(Object o, Object o2) {
					try {
						String tem = ((ArrayList) o2).get(sortIndex) == null
								? ""
								: (String) ((ArrayList) o2).get(sortIndex);
						String temp = ((ArrayList) o).get(sortIndex) == null
								? ""
								: (String) ((ArrayList) o).get(sortIndex);
						if (isAscending)
							return String.CASE_INSENSITIVE_ORDER.compare(temp,
									tem);
						else
							return String.CASE_INSENSITIVE_ORDER.compare(tem,
									temp);

					} catch (Exception e) {
						e.printStackTrace();
					}
					return 0;
				}
			});
		} catch (Exception ex) {
			throw ex;
		}

		return sortedList;
	}

	public String getListData(List tempList, int index) {

		String colData = tempList.get(index) == null ? ""
				: tempList.get(index).toString().trim();
		return colData;
	}

	public String getListDBData(List tempList, int index) {

		String colData = "";
		if (index < tempList.size()) {
			colData = tempList.get(index) == null ? ""
					: tempList.get(index).toString().trim();
			colData = colData.replaceAll("'", "''");
		}

		return colData;
	}

	public String getListDBData(List tempList, String colName,
			Map<String, String> colNameMap) {
		return getListDBData(tempList, colName, colNameMap, false);
	}

	public String getListDBData(List tempList, String colName,
			Map<String, String> colNameMap, boolean isNumeric) {

		String colData = "";
		String colIndex = colNameMap.get(colName) == null ? ""
				: colNameMap.get(colName).toString().trim();
		if (colIndex.length() > 0) {
			int index = Integer.parseInt(colIndex);
			if (index < tempList.size()) {
				colData = tempList.get(index) == null ? ""
						: tempList.get(index).toString().trim();
				colData = colData.replaceAll("'", "''");
				if (isNumeric)
					colData = colData.replaceAll("%", "").replaceAll(",", "");
			}
		}

		return colData;
	}

	public String getFileDate(String dateVal) throws Exception {

		if (dateVal.length() > 0) {
			Date dateObj = (Date) sdfYYYY_D_MM_D_DD.parse(dateVal);
			dateVal = sdfMMDDYYYY.format(dateObj);
		}

		return dateVal;
	}
}
