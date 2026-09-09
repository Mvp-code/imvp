package com.beans;

import java.util.ArrayList;
import java.util.List;

public class Incident extends MainBean {

	private String incidentID = "";
	private String incidentDate = "";
	private String incidentCategoryID = "";
	private String incidentCategoryName = "";
	private String incidentTypeID = "";
	private String incidentTypeName = "";
	private String incidentDesc = "";
	private String employeeID = "";
	private String employeeName = "";
	private String vehicleID = "";
	private String vehicleName = "";
	private String dspCode = "";

	public Incident() {
		setDisplayName("Incident");
		setController("Incident");
	}

	@Override
	public List<String> getBeanAttributes() {

		List<String> beanAttributes = new ArrayList<String>();
		beanAttributes.add("incidentID");
		beanAttributes.add("entityID");
		beanAttributes.add("incidentDate");
		beanAttributes.add("incidentCategoryID");
		beanAttributes.add("incidentTypeID");
		beanAttributes.add("incidentDesc");
		beanAttributes.add("employeeID");
		beanAttributes.add("vehicleID");

		beanAttributes.add("createUser");
		beanAttributes.add("createDate");
		beanAttributes.add("updateUser");
		beanAttributes.add("updateDate");
		beanAttributes.add("status");
		beanAttributes.add("numOfRows");
		return beanAttributes;
	}

	public String getIncidentID() {
		return incidentID;
	}

	public void setIncidentID(String incidentID) {
		this.incidentID = incidentID;
	}

	public String getIncidentDate() {
		return incidentDate;
	}

	public void setIncidentDate(String incidentDate) {
		this.incidentDate = incidentDate;
	}

	public String getIncidentCategoryID() {
		return incidentCategoryID;
	}

	public void setIncidentCategoryID(String incidentCategoryID) {
		this.incidentCategoryID = incidentCategoryID;
	}

	public String getIncidentCategoryName() {
		return incidentCategoryName;
	}

	public void setIncidentCategoryName(String incidentCategoryName) {
		this.incidentCategoryName = incidentCategoryName;
	}

	public String getIncidentTypeID() {
		return incidentTypeID;
	}

	public void setIncidentTypeID(String incidentTypeID) {
		this.incidentTypeID = incidentTypeID;
	}

	public String getIncidentTypeName() {
		return incidentTypeName;
	}

	public void setIncidentTypeName(String incidentTypeName) {
		this.incidentTypeName = incidentTypeName;
	}

	public String getIncidentDesc() {
		return incidentDesc;
	}

	public void setIncidentDesc(String incidentDesc) {
		this.incidentDesc = incidentDesc;
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

	public String getVehicleID() {
		return vehicleID;
	}

	public void setVehicleID(String vehicleID) {
		this.vehicleID = vehicleID;
	}

	public String getVehicleName() {
		return vehicleName;
	}

	public void setVehicleName(String vehicleName) {
		this.vehicleName = vehicleName;
	}

	public String getDspCode() {
		return dspCode;
	}

	public void setDspCode(String dspCode) {
		this.dspCode = dspCode;
	}

}
