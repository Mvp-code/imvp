package com.beans;

import java.util.ArrayList;
import java.util.List;

public class AdminEmployee extends MainBean {

	private String adminEmployeeID = "";
	private String firstName = "";
	private String lastName = "";
	private String fullName = "";
	private String transporterID = "";
	private String position = "";
	private String qualification = "";
	private String idExpiryDate = "";
	private String smsPref = "";
	private String employeeRole = "";
	private String employeeRoleName = "";
	private String preferredLanguage = "";

	private String addressID = "";
	private String contactID = "";
	private String reviewStatus = "";
	private String availability = "";

	Address addressBean = new Address();
	Contact contactBean = new Contact();

	public AdminEmployee() {
		setDisplayName("Employee");
		setController("AdminEmployee");
	}

	@Override
	public List<String> getBeanAttributes() {

		List<String> beanAttributes = new ArrayList<String>();
		beanAttributes.add("adminEmployeeID");
		beanAttributes.add("entityID");
		beanAttributes.add("firstName");
		beanAttributes.add("lastName");
		beanAttributes.add("fullName");
		beanAttributes.add("transporterID");
		beanAttributes.add("position");
		beanAttributes.add("qualification");
		beanAttributes.add("idExpiryDate");
		beanAttributes.add("smsPref");
		beanAttributes.add("addressID");
		beanAttributes.add("contactID");
		beanAttributes.add("reviewStatus");
		beanAttributes.add("availability");
		beanAttributes.add("employeeRole");
		beanAttributes.add("preferredLanguage");

		beanAttributes.add("createUser");
		beanAttributes.add("createDate");
		beanAttributes.add("updateUser");
		beanAttributes.add("updateDate");
		beanAttributes.add("status");

		beanAttributes.add("uploadFileName");
		beanAttributes.add("uploadFileNameWithPath");
		beanAttributes.add("tableName");
		beanAttributes.add("dataSeperator");
		return beanAttributes;
	}

	public String getAdminEmployeeID() {
		return adminEmployeeID;
	}

	public void setAdminEmployeeID(String adminEmployeeID) {
		this.adminEmployeeID = adminEmployeeID;
	}

	public String getFirstName() {
		return firstName;
	}

	public void setFirstName(String firstName) {
		this.firstName = firstName;
	}

	public String getLastName() {
		return lastName;
	}

	public void setLastName(String lastName) {
		this.lastName = lastName;
	}

	public String getFullName() {
		return fullName;
	}

	public void setFullName(String fullName) {
		this.fullName = fullName;
	}

	public String getTransporterID() {
		return transporterID;
	}

	public void setTransporterID(String transporterID) {
		this.transporterID = transporterID;
	}

	public String getPosition() {
		return position;
	}

	public void setPosition(String position) {
		this.position = position;
	}

	public String getQualification() {
		return qualification;
	}

	public void setQualification(String qualification) {
		this.qualification = qualification;
	}

	public String getIdExpiryDate() {
		return idExpiryDate;
	}

	public void setIdExpiryDate(String idExpiryDate) {
		this.idExpiryDate = idExpiryDate;
	}

	public String getSmsPref() {
		return smsPref;
	}

	public void setSmsPref(String smsPref) {
		this.smsPref = smsPref;
	}

	public String getAddressID() {
		return addressID;
	}

	public void setAddressID(String addressID) {
		this.addressID = addressID;
	}

	public String getContactID() {
		return contactID;
	}

	public void setContactID(String contactID) {
		this.contactID = contactID;
	}

	public String getReviewStatus() {
		return reviewStatus;
	}

	public void setReviewStatus(String reviewStatus) {
		this.reviewStatus = reviewStatus;
	}

	public String getAvailability() {
		return availability;
	}

	public void setAvailability(String availability) {
		this.availability = availability;
	}

	public String getEmployeeRole() {
		return employeeRole;
	}

	public void setEmployeeRole(String employeeRole) {
		this.employeeRole = employeeRole;
	}

	public String getPreferredLanguage() {
		return preferredLanguage;
	}

	public void setPreferredLanguage(String preferredLanguage) {
		this.preferredLanguage = preferredLanguage;
	}

	public String getEmployeeRoleName() {
		return employeeRoleName;
	}

	public void setEmployeeRoleName(String employeeRoleName) {
		this.employeeRoleName = employeeRoleName;
	}

	public Address getAddressBean() {
		return addressBean;
	}

	public void setAddressBean(Address addressBean) {
		this.addressBean = addressBean;
	}

	public Contact getContactBean() {
		return contactBean;
	}

	public void setContactBean(Contact contactBean) {
		this.contactBean = contactBean;
	}
}
