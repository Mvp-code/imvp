package com.beans;

import java.util.ArrayList;
import java.util.List;

public class EmployeeForms extends MainBean {

	private String employeeFormsID = "";
	private String adminFormsTemplateID = "";
	private String station = "";
	private String employeeID = "";
	private String employeeName = "";
	private String formName = "";
	private String formContents = "";
	private String comments = "";
	private String signatureValue = "";
	private String signFileNameWithPath = "";

	public EmployeeForms() {
		setDisplayName("Form");
		setController("EmployeeForms");
	}

	@Override
	public List<String> getBeanAttributes() {

		List<String> beanAttributes = new ArrayList<String>();
		beanAttributes.add("employeeFormsID");
		beanAttributes.add("entityID");
		beanAttributes.add("adminFormsTemplateID");
		beanAttributes.add("formName");
		beanAttributes.add("formContents");
		beanAttributes.add("station");
		beanAttributes.add("employeeID");
		beanAttributes.add("employeeName");
		beanAttributes.add("comments");

		beanAttributes.add("createUser");
		beanAttributes.add("createDate");
		beanAttributes.add("updateUser");
		beanAttributes.add("updateDate");
		beanAttributes.add("status");
		beanAttributes.add("signatureValue");
		return beanAttributes;
	}

	public String getEmployeeFormsID() {
		return employeeFormsID;
	}

	public void setEmployeeFormsID(String employeeFormsID) {
		this.employeeFormsID = employeeFormsID;
	}

	public String getAdminFormsTemplateID() {
		return adminFormsTemplateID;
	}

	public void setAdminFormsTemplateID(String adminFormsTemplateID) {
		this.adminFormsTemplateID = adminFormsTemplateID;
	}

	public String getStation() {
		return station;
	}

	public void setStation(String station) {
		this.station = station;
	}

	public String getEmployeeID() {
		return employeeID;
	}

	public void setEmployeeID(String employeeID) {
		this.employeeID = employeeID;
	}

	public String getEmployeeName() {
		return employeeName;
	}

	public void setEmployeeName(String employeeName) {
		this.employeeName = employeeName;
	}

	public String getFormName() {
		return formName;
	}

	public void setFormName(String formName) {
		this.formName = formName;
	}

	public String getFormContents() {
		return formContents;
	}

	public void setFormContents(String formContents) {
		this.formContents = formContents;
	}

	public String getComments() {
		return comments;
	}

	public void setComments(String comments) {
		this.comments = comments;
	}

	public String getSignatureValue() {
		return signatureValue;
	}

	public void setSignatureValue(String signatureValue) {
		this.signatureValue = signatureValue;
	}

	public String getSignFileNameWithPath() {
		return signFileNameWithPath;
	}

	public void setSignFileNameWithPath(String signFileNameWithPath) {
		this.signFileNameWithPath = signFileNameWithPath;
	}

}
