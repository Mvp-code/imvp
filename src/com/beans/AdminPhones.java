package com.beans;

import java.util.ArrayList;
import java.util.List;

public class AdminPhones extends MainBean {

	public static final String[] CURRENT_STATUS = new String[] { "In Use",
			"Not Used", "Damaged", "Lost" };

	public static final String[] PHONE_STATUS = new String[] { "Active",
			"Suspended" };

	private String phoneID = "";
	private String phoneNumber = "";
	private String phoneStatus = "Active";
	private String currentStatus = "In Use";
	private String serialNumber = "";
	private String deviceMake = "";
	private String deviceModel = "";
	private String imei2 = "";
	private String imsi = "";
	private String iccid = "";
	private String eid = "";
	private String remarks = "";
	private String auditedDate = "";
	private String contractEndDate = "";
	private String contractStartDate = "";
	private String deviceOrderedDate = "";
	private String deviceOrderedImei = "";
	private String deviceInUseDate = "";

	public AdminPhones() {
		setDisplayName("Phone");
		setController("AdminPhones");
	}

	public static String phoneStatusLabel(String code) {
		if (code == null || code.trim().length() == 0) {
			return "Active";
		}
		String v = code.trim();
		if ("0".equals(v) || "Active".equalsIgnoreCase(v)) {
			return "Active";
		}
		if ("4".equals(v) || "Inactive".equalsIgnoreCase(v)
				|| "Suspended".equalsIgnoreCase(v)) {
			return "Suspended";
		}
		return v;
	}

	public static String currentStatusLabel(String code) {
		if (code == null || code.trim().length() == 0) {
			return CURRENT_STATUS[0];
		}
		String v = code.trim();
		if ("0".equals(v)) {
			return CURRENT_STATUS[0];
		}
		if ("1".equals(v)) {
			return CURRENT_STATUS[1];
		}
		if ("2".equals(v)) {
			return CURRENT_STATUS[2];
		}
		if ("3".equals(v)) {
			return CURRENT_STATUS[3];
		}
		for (int i = 0; i < CURRENT_STATUS.length; i++) {
			if (CURRENT_STATUS[i].equalsIgnoreCase(v)) {
				return CURRENT_STATUS[i];
			}
		}
		return v;
	}

	public static boolean notesRequired(String phoneStatus, String currentStatus) {
		String p = phoneStatusLabel(phoneStatus).toLowerCase();
		String c = currentStatusLabel(currentStatus).toLowerCase();
		return p.indexOf("suspend") >= 0 || "inactive".equals(p)
				|| "damaged".equals(c) || "lost".equals(c);
	}

	@Override
	public List<String> getBeanAttributes() {

		List<String> beanAttributes = new ArrayList<String>();
		beanAttributes.add("phoneID");
		beanAttributes.add("entityID");
		beanAttributes.add("phoneNumber");
		beanAttributes.add("phoneStatus");
		beanAttributes.add("currentStatus");
		beanAttributes.add("serialNumber");
		beanAttributes.add("deviceMake");
		beanAttributes.add("deviceModel");
		beanAttributes.add("imei2");
		beanAttributes.add("imsi");
		beanAttributes.add("iccid");
		beanAttributes.add("eid");
		beanAttributes.add("remarks");
		beanAttributes.add("auditedDate");
		beanAttributes.add("contractEndDate");
		beanAttributes.add("contractStartDate");
		beanAttributes.add("deviceOrderedDate");
		beanAttributes.add("deviceOrderedImei");
		beanAttributes.add("deviceInUseDate");
		beanAttributes.add("createUser");
		beanAttributes.add("createDate");
		beanAttributes.add("updateUser");
		beanAttributes.add("updateDate");
		beanAttributes.add("status");
		return beanAttributes;
	}

	public String getPhoneID() {
		return phoneID;
	}

	public void setPhoneID(String phoneID) {
		this.phoneID = phoneID;
	}

	public String getPhoneNumber() {
		return phoneNumber;
	}

	public void setPhoneNumber(String phoneNumber) {
		this.phoneNumber = phoneNumber;
	}

	public String getPhoneStatus() {
		return phoneStatus;
	}

	public void setPhoneStatus(String phoneStatus) {
		this.phoneStatus = phoneStatus;
	}

	public String getCurrentStatus() {
		return currentStatus;
	}

	public void setCurrentStatus(String currentStatus) {
		this.currentStatus = currentStatus;
	}

	public String getSerialNumber() {
		return serialNumber;
	}

	public void setSerialNumber(String serialNumber) {
		this.serialNumber = serialNumber;
	}

	public String getDeviceMake() {
		return deviceMake;
	}

	public void setDeviceMake(String deviceMake) {
		this.deviceMake = deviceMake;
	}

	public String getDeviceModel() {
		return deviceModel;
	}

	public void setDeviceModel(String deviceModel) {
		this.deviceModel = deviceModel;
	}

	public String getImei2() {
		return imei2;
	}

	public void setImei2(String imei2) {
		this.imei2 = imei2;
	}

	public String getImsi() {
		return imsi;
	}

	public void setImsi(String imsi) {
		this.imsi = imsi;
	}

	public String getIccid() {
		return iccid;
	}

	public void setIccid(String iccid) {
		this.iccid = iccid;
	}

	public String getEid() {
		return eid;
	}

	public void setEid(String eid) {
		this.eid = eid;
	}

	public String getRemarks() {
		return remarks;
	}

	public void setRemarks(String remarks) {
		this.remarks = remarks;
	}

	public String getAuditedDate() {
		return auditedDate;
	}

	public void setAuditedDate(String auditedDate) {
		this.auditedDate = auditedDate;
	}

	public String getContractEndDate() {
		return contractEndDate;
	}

	public void setContractEndDate(String contractEndDate) {
		this.contractEndDate = contractEndDate;
	}

	public String getContractStartDate() {
		return contractStartDate;
	}

	public void setContractStartDate(String contractStartDate) {
		this.contractStartDate = contractStartDate;
	}

	public String getDeviceOrderedDate() {
		return deviceOrderedDate;
	}

	public void setDeviceOrderedDate(String deviceOrderedDate) {
		this.deviceOrderedDate = deviceOrderedDate;
	}

	public String getDeviceOrderedImei() {
		return deviceOrderedImei;
	}

	public void setDeviceOrderedImei(String deviceOrderedImei) {
		this.deviceOrderedImei = deviceOrderedImei;
	}

	public String getDeviceInUseDate() {
		return deviceInUseDate;
	}

	public void setDeviceInUseDate(String deviceInUseDate) {
		this.deviceInUseDate = deviceInUseDate;
	}

}
