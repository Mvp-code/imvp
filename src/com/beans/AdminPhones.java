package com.beans;

import java.util.ArrayList;
import java.util.List;

public class AdminPhones extends MainBean {

	private String phoneID = "";
	private String phoneNumber = "";
	private String phoneStatus = "";
	private String serialNumber = "";
	private String remarks = "";
	private String auditedBy = "";
	private String auditedDate = "";
	private String validity = "";

	public AdminPhones() {
		setDisplayName("Phone");
		setController("AdminPhones");
	}

	@Override
	public List<String> getBeanAttributes() {

		List<String> beanAttributes = new ArrayList<String>();
		beanAttributes.add("phoneID");
		beanAttributes.add("entityID");
		beanAttributes.add("phoneNumber");
		beanAttributes.add("phoneStatus");
		beanAttributes.add("serialNumber");
		beanAttributes.add("remarks");
		beanAttributes.add("auditedBy");
		beanAttributes.add("auditedDate");
		beanAttributes.add("validity");

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

	public String getSerialNumber() {
		return serialNumber;
	}

	public void setSerialNumber(String serialNumber) {
		this.serialNumber = serialNumber;
	}

	public String getRemarks() {
		return remarks;
	}

	public void setRemarks(String remarks) {
		this.remarks = remarks;
	}

	public String getAuditedBy() {
		return auditedBy;
	}

	public void setAuditedBy(String auditedBy) {
		this.auditedBy = auditedBy;
	}

	public String getAuditedDate() {
		return auditedDate;
	}

	public void setAuditedDate(String auditedDate) {
		this.auditedDate = auditedDate;
	}

	public String getValidity() {
		return validity;
	}

	public void setValidity(String validity) {
		this.validity = validity;
	}

}
