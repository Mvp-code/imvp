package com.beans;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class MainBean {

	private String recordID = "";
	private String entityID = "";
	private String createUser = "";
	private String createDate = "";
	private String updateUser = "";
	private String updateDate = "";
	private String status = "";

	private String uploadFileName = "";
	private String uploadFileNameWithPath = "";
	private String tableName = "";
	private String dataSeperator = "";

	private String numOfRows = "";
	private List transList = new ArrayList();
	private Map transMap = new HashMap();
	private List uploadsList = new ArrayList();
	private List<String> reportsList = new ArrayList<String>();

	private boolean displayNewBtn = false;
	private boolean displayBrowseBtn = false;

	private boolean displayUpdateBtn = false;
	private boolean displayPostBtn = false;
	private boolean displayPrintBtn = false;
	private boolean displayViewBtn = false;
	private boolean displayDeleteBtn = false;
	private boolean displaySMSBtn = false;

	private String preferredLanguageOptions = "";

	private String displayName = "";
	private String controller = "";

	public List<String> getBeanAttributes() {
		return new ArrayList<String>();
	}

	public String getRecordID() {
		return recordID;
	}

	public void setRecordID(String recordID) {
		this.recordID = recordID;
	}

	public String getEntityID() {
		return entityID;
	}

	public void setEntityID(String entityID) {
		this.entityID = entityID;
	}

	public String getCreateUser() {
		return createUser;
	}

	public void setCreateUser(String createUser) {
		this.createUser = createUser;
	}

	public String getCreateDate() {
		return createDate;
	}

	public void setCreateDate(String createDate) {
		this.createDate = createDate;
	}

	public String getUpdateUser() {
		return updateUser;
	}

	public void setUpdateUser(String updateUser) {
		this.updateUser = updateUser;
	}

	public String getUpdateDate() {
		return updateDate;
	}

	public void setUpdateDate(String updateDate) {
		this.updateDate = updateDate;
	}

	public String getStatus() {
		return status;
	}

	public void setStatus(String status) {
		this.status = status;
	}

	public String getDisplayName() {
		return displayName;
	}

	public void setDisplayName(String displayName) {
		this.displayName = displayName;
	}

	public String getController() {
		return controller;
	}

	public void setController(String controller) {
		this.controller = controller;
	}

	public String getNumOfRows() {
		return numOfRows;
	}

	public void setNumOfRows(String numOfRows) {
		this.numOfRows = numOfRows;
	}

	public List getTransList() {
		return transList;
	}

	public void setTransList(List transList) {
		this.transList = transList;
	}

	public Map getTransMap() {
		return transMap;
	}

	public void setTransMap(Map transMap) {
		this.transMap = transMap;
	}

	public List getUploadsList() {
		return uploadsList;
	}

	public void setUploadsList(List uploadsList) {
		this.uploadsList = uploadsList;
	}

	public List<String> getReportsList() {
		return reportsList;
	}

	public void setReportsList(List<String> reportsList) {
		this.reportsList = reportsList;
	}

	public String getUploadFileName() {
		return uploadFileName;
	}

	public void setUploadFileName(String uploadFileName) {
		this.uploadFileName = uploadFileName;
	}

	public String getUploadFileNameWithPath() {
		return uploadFileNameWithPath;
	}

	public void setUploadFileNameWithPath(String uploadFileNameWithPath) {
		this.uploadFileNameWithPath = uploadFileNameWithPath;
	}

	public String getTableName() {
		return tableName;
	}

	public void setTableName(String tableName) {
		this.tableName = tableName;
	}

	public String getDataSeperator() {
		return dataSeperator;
	}

	public void setDataSeperator(String dataSeperator) {
		this.dataSeperator = dataSeperator;
	}

	public String getPreferredLanguageOptions() {
		return preferredLanguageOptions;
	}

	public void setPreferredLanguageOptions(String preferredLanguageOptions) {
		this.preferredLanguageOptions = preferredLanguageOptions;
	}

	public boolean isDisplayNewBtn() {
		return displayNewBtn;
	}

	public void setDisplayNewBtn(boolean displayNewBtn) {
		this.displayNewBtn = displayNewBtn;
	}

	public boolean isDisplayBrowseBtn() {
		return displayBrowseBtn;
	}

	public void setDisplayBrowseBtn(boolean displayBrowseBtn) {
		this.displayBrowseBtn = displayBrowseBtn;
	}

	public boolean isDisplayUpdateBtn() {
		return displayUpdateBtn;
	}

	public void setDisplayUpdateBtn(boolean displayUpdateBtn) {
		this.displayUpdateBtn = displayUpdateBtn;
	}

	public boolean isDisplayPostBtn() {
		return displayPostBtn;
	}

	public void setDisplayPostBtn(boolean displayPostBtn) {
		this.displayPostBtn = displayPostBtn;
	}

	public boolean isDisplayPrintBtn() {
		return displayPrintBtn;
	}

	public void setDisplayPrintBtn(boolean displayPrintBtn) {
		this.displayPrintBtn = displayPrintBtn;
	}

	public boolean isDisplayViewBtn() {
		return displayViewBtn;
	}

	public void setDisplayViewBtn(boolean displayViewBtn) {
		this.displayViewBtn = displayViewBtn;
	}

	public boolean isDisplayDeleteBtn() {
		return displayDeleteBtn;
	}

	public void setDisplayDeleteBtn(boolean displayDeleteBtn) {
		this.displayDeleteBtn = displayDeleteBtn;
	}

	public boolean isDisplaySMSBtn() {
		return displaySMSBtn;
	}

	public void setDisplaySMSBtn(boolean displaySMSBtn) {
		this.displaySMSBtn = displaySMSBtn;
	}
}
