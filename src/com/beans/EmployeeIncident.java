package com.beans;

import java.util.ArrayList;
import java.util.List;

public class EmployeeIncident extends MainBean {

	private String employeeIncidentID = "";
	private String employeeID = "";
	private String employeeName = "";
	private String dateOfIncident = "";
	private String timeOfIncident = "";
	private String reportedTimeOfIncident = "";
	private String incidentType = "";
	private String incidentLocation = "";
	private String incidentDescription = "";
	private String emtNumber = "";

	public EmployeeIncident() {
		setDisplayName("OSHA Incident");
		setController("EmployeeIncident");
	}

	@Override
	public List<String> getBeanAttributes() {

		List<String> beanAttributes = new ArrayList<String>();
		beanAttributes.add("employeeIncidentID");
		beanAttributes.add("entityID");
		beanAttributes.add("dateOfIncident");
		beanAttributes.add("timeOfIncident");
		beanAttributes.add("reportedTimeOfIncident");
		beanAttributes.add("employeeID");
		beanAttributes.add("incidentType");
		beanAttributes.add("incidentLocation");
		beanAttributes.add("incidentDescription");
		beanAttributes.add("emtNumber");

		beanAttributes.add("createUser");
		beanAttributes.add("createDate");
		beanAttributes.add("updateUser");
		beanAttributes.add("updateDate");
		beanAttributes.add("status");
		beanAttributes.add("numOfRows");
		return beanAttributes;
	}

	public String getEmployeeIncidentID() {
		return employeeIncidentID;
	}

	public void setEmployeeIncidentID(String employeeIncidentID) {
		this.employeeIncidentID = employeeIncidentID;
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

	public String getDateOfIncident() {
		return dateOfIncident;
	}

	public void setDateOfIncident(String dateOfIncident) {
		this.dateOfIncident = dateOfIncident;
	}

	public String getTimeOfIncident() {
		return timeOfIncident;
	}

	public void setTimeOfIncident(String timeOfIncident) {
		this.timeOfIncident = timeOfIncident;
	}

	public String getReportedTimeOfIncident() {
		return reportedTimeOfIncident;
	}

	public void setReportedTimeOfIncident(String reportedTimeOfIncident) {
		this.reportedTimeOfIncident = reportedTimeOfIncident;
	}

	public String getIncidentType() {
		return incidentType;
	}

	public void setIncidentType(String incidentType) {
		this.incidentType = incidentType;
	}

	public String getIncidentLocation() {
		return incidentLocation;
	}

	public void setIncidentLocation(String incidentLocation) {
		this.incidentLocation = incidentLocation;
	}

	public String getIncidentDescription() {
		return incidentDescription;
	}

	public void setIncidentDescription(String incidentDescription) {
		this.incidentDescription = incidentDescription;
	}

	public String getEmtNumber() {
		return emtNumber;
	}

	public void setEmtNumber(String emtNumber) {
		this.emtNumber = emtNumber;
	}

}
