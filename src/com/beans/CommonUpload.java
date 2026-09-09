package com.beans;

import java.util.ArrayList;
import java.util.List;

public class CommonUpload extends MainBean {

	public static final String PRIMARY_KEY_ID = "recordID";
	private String station = "";
	private String module = "";
	private String employeeID = "";
	private String employeeName = "";

	private String vehicleID = "";
	private String vehicleNumber = "";

	private String waveTime = "";
	private String parking = "";
	private String parkingDesc = "";
	private String daComments = "";
	private String daCheckinID = "";

	private String timeOffStartDate = "";
	private String timeOffEndDate = "";
	private String timeOffReason = "";

	private List vehiclesList = new ArrayList();

	public CommonUpload() {
		setDisplayName("Employee Upload");
		setController("CommonUpload");
	}

	@Override
	public List<String> getBeanAttributes() {

		List<String> beanAttributes = new ArrayList<String>();
		beanAttributes.add("recordID");
		beanAttributes.add("entityID");
		beanAttributes.add("station");
		beanAttributes.add("module");
		beanAttributes.add("employeeID");
		beanAttributes.add("employeeName");
		beanAttributes.add("vehicleID");
		beanAttributes.add("vehicleNumber");
		beanAttributes.add("uploadFileName");
		beanAttributes.add("uploadFileNameWithPath");
		beanAttributes.add("parking");
		beanAttributes.add("daComments");
		beanAttributes.add("daCheckinID");

		// Time Off
		beanAttributes.add("timeOffStartDate");
		beanAttributes.add("timeOffEndDate");
		beanAttributes.add("timeOffReason");

		beanAttributes.add("createUser");
		beanAttributes.add("createDate");
		beanAttributes.add("updateUser");
		beanAttributes.add("updateDate");
		beanAttributes.add("status");
		beanAttributes.add("numOfRows");
		return beanAttributes;
	}

	public String getStation() {
		return station;
	}

	public void setStation(String station) {
		this.station = station;
	}

	public String getModule() {
		return module;
	}

	public void setModule(String module) {
		this.module = module;
	}

	public String getEmployeeID() {
		return employeeID;
	}

	public void setEmployeeID(String employeeID) {
		this.employeeID = employeeID;
	}

	public String getVehicleID() {
		return vehicleID;
	}

	public void setVehicleID(String vehicleID) {
		this.vehicleID = vehicleID;
	}

	public String getEmployeeName() {
		return employeeName;
	}

	public void setEmployeeName(String employeeName) {
		this.employeeName = employeeName;
	}

	public String getVehicleNumber() {
		return vehicleNumber;
	}

	public void setVehicleNumber(String vehicleNumber) {
		this.vehicleNumber = vehicleNumber;
	}

	public String getWaveTime() {
		return waveTime;
	}

	public void setWaveTime(String waveTime) {
		this.waveTime = waveTime;
	}

	public String getParking() {
		return parking;
	}

	public void setParking(String parking) {
		this.parking = parking;
	}

	public String getParkingDesc() {
		return parkingDesc;
	}

	public void setParkingDesc(String parkingDesc) {
		this.parkingDesc = parkingDesc;
	}

	public String getDaComments() {
		return daComments;
	}

	public void setDaComments(String daComments) {
		this.daComments = daComments;
	}

	public String getDaCheckinID() {
		return daCheckinID;
	}

	public void setDaCheckinID(String daCheckinID) {
		this.daCheckinID = daCheckinID;
	}

	public String getTimeOffStartDate() {
		return timeOffStartDate;
	}

	public void setTimeOffStartDate(String timeOffStartDate) {
		this.timeOffStartDate = timeOffStartDate;
	}

	public String getTimeOffEndDate() {
		return timeOffEndDate;
	}

	public void setTimeOffEndDate(String timeOffEndDate) {
		this.timeOffEndDate = timeOffEndDate;
	}

	public String getTimeOffReason() {
		return timeOffReason;
	}

	public void setTimeOffReason(String timeOffReason) {
		this.timeOffReason = timeOffReason;
	}

	public List getVehiclesList() {
		return vehiclesList;
	}

	public void setVehiclesList(List vehiclesList) {
		this.vehiclesList = vehiclesList;
	}

}
