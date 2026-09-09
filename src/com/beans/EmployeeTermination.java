package com.beans;

import java.util.ArrayList;
import java.util.List;

public class EmployeeTermination extends MainBean {

	private String employeeTerminationID = "";
	private String employeeID = "";
	private String employeeName = "";
	private String dateOfTermination = "";
	private String terminationType = "";
	private String terminationReason = "";
	private String comments = "";

	public EmployeeTermination() {
		setDisplayName("Employee Termination");
		setController("EmployeeTermination");
	}

	@Override
	public List<String> getBeanAttributes() {

		List<String> beanAttributes = new ArrayList<String>();
		beanAttributes.add("employeeTerminationID");
		beanAttributes.add("entityID");
		beanAttributes.add("dateOfTermination");
		beanAttributes.add("employeeID");
		beanAttributes.add("terminationType");
		beanAttributes.add("terminationReason");
		beanAttributes.add("comments");

		beanAttributes.add("createUser");
		beanAttributes.add("createDate");
		beanAttributes.add("updateUser");
		beanAttributes.add("updateDate");
		beanAttributes.add("status");
		beanAttributes.add("numOfRows");
		return beanAttributes;
	}

	public String getEmployeeTerminationID() {
		return employeeTerminationID;
	}

	public void setEmployeeTerminationID(String employeeTerminationID) {
		this.employeeTerminationID = employeeTerminationID;
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

	public String getDateOfTermination() {
		return dateOfTermination;
	}

	public void setDateOfTermination(String dateOfTermination) {
		this.dateOfTermination = dateOfTermination;
	}

	public String getTerminationType() {
		return terminationType;
	}

	public void setTerminationType(String terminationType) {
		this.terminationType = terminationType;
	}

	public String getTerminationReason() {
		return terminationReason;
	}

	public void setTerminationReason(String terminationReason) {
		this.terminationReason = terminationReason;
	}

	public String getComments() {
		return comments;
	}

	public void setComments(String comments) {
		this.comments = comments;
	}

}
