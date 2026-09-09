package com.beans;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class SearchBean extends MainBean {

	// Post or Delete
	private String updateType = "";
	private String updateValues = "";

	private String selectedType = "";
	private String selectedValues = "";
	private ErrorBean errorBean = new ErrorBean();

	private String srhFromDate = "";
	private String srhToDate = "";
	private String srhCategoryID = "";
	private String srhTypeID = "";
	private String srhEmployeeID = "";
	private String srhVehicleID = "";

	private String srhYear = "";
	private String srhWeek = "";

	private String srhType = "";
	private String srhRole = "";
	private String srhValue = "";
	private String srhValue2 = "";
	private String srhStatus = "";
	private String srhStatusDefault = "";
	private String srhStatusDate = "";
	private String srhExpiryDate = "";
	private String srhTransporterID = "";
	private String srhReportType = "";

	private String searchFilter = "";
	private String pageNum = "";
	private String pagingParams = "";

	private String columnSortName = "";
	private String columnSortOrder = "";

	private String numOfCheckinRecords = "";
	private String numOfCheckoutRecords = "";

	private boolean displayRunBtn = false;
	private boolean displayNextRunBtn = false;

	private boolean displayResultsSorting = true;

	private List<String> labelsList = new ArrayList<String>();
	private List dataList = new ArrayList();
	private List dataCountList = new ArrayList();
	private List footerList = new ArrayList();

	private Map<String, String> requestMap = new HashMap<String, String>();
	private String xmlMesg = "";

	private int widthColumns[] = null;
	private int rightAlignColumns[] = null;
	private int boldColumns[] = null;
	private int localeColumns[] = null;
	private String searchFiltersArray[] = new String[] {};
	private String reportsFilterArray[] = null;

	@Override
	public List<String> getBeanAttributes() {
		List<String> attributesList = new ArrayList<String>();
		attributesList.add("searchFilter");
		attributesList.add("updateType");
		attributesList.add("updateValues");
		attributesList.add("selectedType");
		attributesList.add("selectedValues");
		attributesList.add("srhType");

		attributesList.add("srhFromDate");
		attributesList.add("srhToDate");
		attributesList.add("srhCategoryID");
		attributesList.add("srhTypeID");
		attributesList.add("srhEmployeeID");
		attributesList.add("srhVehicleID");
		attributesList.add("srhTransporterID");
		attributesList.add("srhReportType");

		attributesList.add("srhYear");
		attributesList.add("srhWeek");

		attributesList.add("srhRole");
		attributesList.add("srhValue");
		attributesList.add("srhValue2");
		attributesList.add("srhStatus");
		attributesList.add("srhStatusDate");
		attributesList.add("srhExpiryDate");

		attributesList.add("pageNum");
		attributesList.add("pagingParams");

		attributesList.add("columnSortOrder");
		attributesList.add("columnSortName");

		attributesList.add("numOfRows");
		return attributesList;
	}

	public List<String> getLabelsList() {
		return labelsList;
	}

	public void setLabelsList(List<String> labelsList) {
		this.labelsList = labelsList;
	}

	public List getDataList() {
		return dataList;
	}

	public void setDataList(List dataList) {
		this.dataList = dataList;
	}

	public List getDataCountList() {
		return dataCountList;
	}

	public void setDataCountList(List dataCountList) {
		this.dataCountList = dataCountList;
	}

	public List getFooterList() {
		return footerList;
	}

	public void setFooterList(List footerList) {
		this.footerList = footerList;
	}

	public Map<String, String> getRequestMap() {
		return requestMap;
	}

	public void setRequestMap(Map<String, String> requestMap) {
		this.requestMap = requestMap;
	}

	public String getSearchFilter() {
		return searchFilter;
	}

	public void setSearchFilter(String searchFilter) {
		this.searchFilter = searchFilter;
	}

	public String getUpdateType() {
		return updateType;
	}

	public void setUpdateType(String updateType) {
		this.updateType = updateType;
	}

	public String getUpdateValues() {
		return updateValues;
	}

	public void setUpdateValues(String updateValues) {
		this.updateValues = updateValues;
	}

	public String getSelectedType() {
		return selectedType;
	}

	public void setSelectedType(String selectedType) {
		this.selectedType = selectedType;
	}

	public String getSelectedValues() {
		return selectedValues;
	}

	public void setSelectedValues(String selectedValues) {
		this.selectedValues = selectedValues;
	}

	public String getSrhType() {
		return srhType;
	}

	public void setSrhType(String srhType) {
		this.srhType = srhType;
	}

	public ErrorBean getErrorBean() {
		return errorBean;
	}

	public void setErrorBean(ErrorBean errorBean) {
		this.errorBean = errorBean;
	}

	public String getSrhFromDate() {
		return srhFromDate;
	}

	public void setSrhFromDate(String srhFromDate) {
		this.srhFromDate = srhFromDate;
	}

	public String getSrhToDate() {
		return srhToDate;
	}

	public void setSrhToDate(String srhToDate) {
		this.srhToDate = srhToDate;
	}

	public String getSrhYear() {
		return srhYear;
	}

	public void setSrhYear(String srhYear) {
		this.srhYear = srhYear;
	}

	public String getSrhWeek() {
		return srhWeek;
	}

	public void setSrhWeek(String srhWeek) {
		this.srhWeek = srhWeek;
	}

	public String getSrhCategoryID() {
		return srhCategoryID;
	}

	public void setSrhCategoryID(String srhCategoryID) {
		this.srhCategoryID = srhCategoryID;
	}

	public String getSrhTypeID() {
		return srhTypeID;
	}

	public void setSrhTypeID(String srhTypeID) {
		this.srhTypeID = srhTypeID;
	}

	public String getSrhEmployeeID() {
		return srhEmployeeID;
	}

	public void setSrhEmployeeID(String srhEmployeeID) {
		this.srhEmployeeID = srhEmployeeID;
	}

	public String getSrhVehicleID() {
		return srhVehicleID;
	}

	public void setSrhVehicleID(String srhVehicleID) {
		this.srhVehicleID = srhVehicleID;
	}

	public String getPageNum() {
		return pageNum;
	}

	public void setPageNum(String pageNum) {
		this.pageNum = pageNum;
	}

	public String getPagingParams() {
		return pagingParams;
	}

	public void setPagingParams(String pagingParams) {
		this.pagingParams = pagingParams;
	}

	public String getColumnSortName() {
		return columnSortName;
	}

	public void setColumnSortName(String columnSortName) {
		this.columnSortName = columnSortName;
	}

	public String getColumnSortOrder() {
		return columnSortOrder;
	}

	public void setColumnSortOrder(String columnSortOrder) {
		this.columnSortOrder = columnSortOrder;
	}

	public int[] getWidthColumns() {
		return widthColumns;
	}

	public void setWidthColumns(int[] widthColumns) {
		this.widthColumns = widthColumns;
	}

	public int[] getRightAlignColumns() {
		return rightAlignColumns;
	}

	public void setRightAlignColumns(int[] rightAlignColumns) {
		this.rightAlignColumns = rightAlignColumns;
	}

	public int[] getBoldColumns() {
		return boldColumns;
	}

	public void setBoldColumns(int[] boldColumns) {
		this.boldColumns = boldColumns;
	}

	public int[] getLocaleColumns() {
		return localeColumns;
	}

	public void setLocaleColumns(int[] localeColumns) {
		this.localeColumns = localeColumns;
	}

	public String[] getSearchFiltersArray() {
		return searchFiltersArray;
	}

	public void setSearchFiltersArray(String[] searchFiltersArray) {
		this.searchFiltersArray = searchFiltersArray;
	}

	public String getNumOfCheckinRecords() {
		return numOfCheckinRecords;
	}

	public void setNumOfCheckinRecords(String numOfCheckinRecords) {
		this.numOfCheckinRecords = numOfCheckinRecords;
	}

	public String getNumOfCheckoutRecords() {
		return numOfCheckoutRecords;
	}

	public void setNumOfCheckoutRecords(String numOfCheckoutRecords) {
		this.numOfCheckoutRecords = numOfCheckoutRecords;
	}

	public String getSrhRole() {
		return srhRole;
	}

	public void setSrhRole(String srhRole) {
		this.srhRole = srhRole;
	}

	public String getSrhValue() {
		return srhValue;
	}

	public void setSrhValue(String srhValue) {
		this.srhValue = srhValue;
	}

	public String getSrhValue2() {
		return srhValue2;
	}

	public void setSrhValue2(String srhValue2) {
		this.srhValue2 = srhValue2;
	}

	public String getSrhExpiryDate() {
		return srhExpiryDate;
	}

	public void setSrhExpiryDate(String srhExpiryDate) {
		this.srhExpiryDate = srhExpiryDate;
	}

	public String getSrhTransporterID() {
		return srhTransporterID;
	}

	public void setSrhTransporterID(String srhTransporterID) {
		this.srhTransporterID = srhTransporterID;
	}

	public String getSrhStatus() {
		return srhStatus;
	}

	public void setSrhStatus(String srhStatus) {
		this.srhStatus = srhStatus;
	}

	public String getSrhStatusDefault() {
		return srhStatusDefault;
	}

	public void setSrhStatusDefault(String srhStatusDefault) {
		this.srhStatusDefault = srhStatusDefault;
	}

	public String getSrhStatusDate() {
		return srhStatusDate;
	}

	public void setSrhStatusDate(String srhStatusDate) {
		this.srhStatusDate = srhStatusDate;
	}

	public String getXmlMesg() {
		return xmlMesg;
	}

	public void setXmlMesg(String xmlMesg) {
		this.xmlMesg = xmlMesg;
	}

	public boolean isDisplayRunBtn() {
		return displayRunBtn;
	}

	public void setDisplayRunBtn(boolean displayRunBtn) {
		this.displayRunBtn = displayRunBtn;
	}

	public boolean isDisplayNextRunBtn() {
		return displayNextRunBtn;
	}

	public void setDisplayNextRunBtn(boolean displayNextRunBtn) {
		this.displayNextRunBtn = displayNextRunBtn;
	}

	public String getSrhReportType() {
		return srhReportType;
	}

	public void setSrhReportType(String srhReportType) {
		this.srhReportType = srhReportType;
	}

	public boolean isDisplayResultsSorting() {
		return displayResultsSorting;
	}

	public void setDisplayResultsSorting(boolean displayResultsSorting) {
		this.displayResultsSorting = displayResultsSorting;
	}

	public String[] getReportsFilterArray() {
		return reportsFilterArray;
	}

	public void setReportsFilterArray(String[] reportsFilterArray) {
		this.reportsFilterArray = reportsFilterArray;
	}
}
