package com.beans;

import java.util.ArrayList;
import java.util.List;

public class VehicleInspection extends MainBean {

	private String vehicleInspectionID = "";
	private String inspectionDate = "";
	private String daCheckinID = "";
	private String vehicleID = "";
	private String vehicleName = "";
	private String employeeName = "";
	private String daComments = "";
	private String dispatcherComments = "";
	private String groundByDispatcher = "";
	private String parking = "";

	private List daCheckoutList = new ArrayList();

	private String transArray[][] = new String[][] {
			{ "Front Side", "Good#Damaged" }, { "Back Side", "Good#Damaged" },
			{ "Driver Side", "Good#Damaged" },
			{ "Passenger Side", "Good#Damaged" }, { "Mirrors", "Good#Damaged" },
			{ "Hadelights", "Good#Damaged" }, { "Blinkers", "Good#Damaged" },
			{ "Cleanliness", "Good#Bad" }, { "Gas Filled", "Yes#No" },
			{ "AVI Inspection", "Yes#No" }, { "DVIC", "Yes#No" } };

	public VehicleInspection() {
		setDisplayName("Vehicle Inspection");
		setController("VehicleInspection");
	}

	@Override
	public List<String> getBeanAttributes() {

		List<String> beanAttributes = new ArrayList<String>();
		beanAttributes.add("vehicleInspectionID");
		beanAttributes.add("entityID");
		beanAttributes.add("daCheckinID");
		beanAttributes.add("inspectionDate");
		beanAttributes.add("vehicleID");
		beanAttributes.add("daComments");
		beanAttributes.add("dispatcherComments");
		beanAttributes.add("groundByDispatcher");
		beanAttributes.add("parking");

		beanAttributes.add("createUser");
		beanAttributes.add("createDate");
		beanAttributes.add("updateUser");
		beanAttributes.add("updateDate");
		beanAttributes.add("status");
		beanAttributes.add("numOfRows");
		return beanAttributes;
	}

	public String getVehicleInspectionID() {
		return vehicleInspectionID;
	}

	public void setVehicleInspectionID(String vehicleInspectionID) {
		this.vehicleInspectionID = vehicleInspectionID;
	}

	public String getInspectionDate() {
		return inspectionDate;
	}

	public void setInspectionDate(String inspectionDate) {
		this.inspectionDate = inspectionDate;
	}

	public String getDaCheckinID() {
		return daCheckinID;
	}

	public void setDaCheckinID(String daCheckinID) {
		this.daCheckinID = daCheckinID;
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

	public String getEmployeeName() {
		return employeeName;
	}

	public void setEmployeeName(String employeeName) {
		this.employeeName = employeeName;
	}

	public String getDaComments() {
		return daComments;
	}

	public void setDaComments(String daComments) {
		this.daComments = daComments;
	}

	public String getDispatcherComments() {
		return dispatcherComments;
	}

	public void setDispatcherComments(String dispatcherComments) {
		this.dispatcherComments = dispatcherComments;
	}

	public String getGroundByDispatcher() {
		return groundByDispatcher;
	}

	public void setGroundByDispatcher(String groundByDispatcher) {
		this.groundByDispatcher = groundByDispatcher;
	}

	public String[][] getTransArray() {
		return transArray;
	}

	public List getDaCheckoutList() {
		return daCheckoutList;
	}

	public void setDaCheckoutList(List daCheckoutList) {
		this.daCheckoutList = daCheckoutList;
	}

	public String getParking() {
		return parking;
	}

	public void setParking(String parking) {
		this.parking = parking;
	}

}
