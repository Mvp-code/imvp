package com.beans;

import java.util.ArrayList;
import java.util.List;

public class DAStatus extends MainBean {

	private String scheduleDate = "";
	private String scheduleTime = "";
	private String employeeID = "";
	private String employeeName = "";
	private String station = "";
	private String comments = "";
	private String confirmedBy = "";
	private String recordStatus = "";

	public DAStatus() {
		setDisplayName("DA Confirmation");
		setController("DAStatus");
	}

	@Override
	public List<String> getBeanAttributes() {

		List<String> beanAttributes = new ArrayList<String>();
		beanAttributes.add("recordID");
		beanAttributes.add("entityID");
		beanAttributes.add("scheduleDate");
		beanAttributes.add("scheduleTime");
		beanAttributes.add("employeeID");
		beanAttributes.add("station");
		beanAttributes.add("comments");
		beanAttributes.add("confirmedBy");
		beanAttributes.add("recordStatus");

		beanAttributes.add("createUser");
		beanAttributes.add("createDate");
		beanAttributes.add("updateUser");
		beanAttributes.add("updateDate");
		beanAttributes.add("status");
		beanAttributes.add("numOfRows");
		return beanAttributes;
	}

	public String getScheduleDate() {
		return scheduleDate;
	}

	public void setScheduleDate(String scheduleDate) {
		this.scheduleDate = scheduleDate;
	}

	public String getScheduleTime() {
		return scheduleTime;
	}

	public void setScheduleTime(String scheduleTime) {
		this.scheduleTime = scheduleTime;
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

	public String getStation() {
		return station;
	}

	public void setStation(String station) {
		this.station = station;
	}

	public String getRecordStatus() {
		return recordStatus;
	}

	public void setRecordStatus(String recordStatus) {
		this.recordStatus = recordStatus;
	}

	public String getComments() {
		return comments;
	}

	public void setComments(String comments) {
		this.comments = comments;
	}

	public String getConfirmedBy() {
		return confirmedBy;
	}

	public void setConfirmedBy(String confirmedBy) {
		this.confirmedBy = confirmedBy;
	}

}
