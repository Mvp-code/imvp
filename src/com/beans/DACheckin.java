package com.beans;

import java.util.ArrayList;
import java.util.List;

public class DACheckin extends MainBean {

	private String daCheckinID = "";
	private String clockinDate = "";
	private String clockinTime = "";
	private String employeeID = "";
	private String employeeName = "";
	private String vehicleID = "";
	private String vehicleName = "";
	private String cdvCertified = "";
	private String parking = "";
	private String wave = "";
	private String phoneCable = "";
	private String gasCard = "";
	private String gasCardID = "";
	private String gasCardIdentifier = "";
	private String daComments = "";
	private String dispatchComments = "";

	private String scheduleID = "";
	private String scheduleWaveTime = "";
	private String scheduleServiceTier = "";

	private List gasCardList = new ArrayList();

	public DACheckin() {
		setDisplayName("DA Checkin");
		setController("DACheckin");
	}

	@Override
	public List<String> getBeanAttributes() {

		List<String> beanAttributes = new ArrayList<String>();
		beanAttributes.add("daCheckinID");
		beanAttributes.add("entityID");
		beanAttributes.add("clockinDate");
		beanAttributes.add("clockinTime");
		beanAttributes.add("employeeID");
		beanAttributes.add("vehicleID");
		beanAttributes.add("cdvCertified");
		beanAttributes.add("parking");
		beanAttributes.add("wave");
		beanAttributes.add("phoneCable");
		beanAttributes.add("gasCard");
		beanAttributes.add("gasCardID");
		beanAttributes.add("daComments");
		beanAttributes.add("dispatchComments");

		beanAttributes.add("createUser");
		beanAttributes.add("createDate");
		beanAttributes.add("updateUser");
		beanAttributes.add("updateDate");
		beanAttributes.add("status");
		return beanAttributes;
	}

	public String getDaCheckinID() {
		return daCheckinID;
	}

	public void setDaCheckinID(String daCheckinID) {
		this.daCheckinID = daCheckinID;
	}

	public String getClockinDate() {
		return clockinDate;
	}

	public void setClockinDate(String clockinDate) {
		this.clockinDate = clockinDate;
	}

	public String getClockinTime() {
		return clockinTime;
	}

	public void setClockinTime(String clockinTime) {
		this.clockinTime = clockinTime;
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

	public String getCdvCertified() {
		return cdvCertified;
	}

	public void setCdvCertified(String cdvCertified) {
		this.cdvCertified = cdvCertified;
	}

	public String getParking() {
		return parking;
	}

	public void setParking(String parking) {
		this.parking = parking;
	}

	public String getWave() {
		return wave;
	}

	public void setWave(String wave) {
		this.wave = wave;
	}

	public String getPhoneCable() {
		return phoneCable;
	}

	public void setPhoneCable(String phoneCable) {
		this.phoneCable = phoneCable;
	}

	public String getGasCard() {
		return gasCard;
	}

	public void setGasCard(String gasCard) {
		this.gasCard = gasCard;
	}

	public String getGasCardID() {
		return gasCardID;
	}

	public void setGasCardID(String gasCardID) {
		this.gasCardID = gasCardID;
	}

	public String getGasCardIdentifier() {
		return gasCardIdentifier;
	}

	public void setGasCardIdentifier(String gasCardIdentifier) {
		this.gasCardIdentifier = gasCardIdentifier;
	}

	public String getDaComments() {
		return daComments;
	}

	public void setDaComments(String daComments) {
		this.daComments = daComments;
	}

	public String getDispatchComments() {
		return dispatchComments;
	}

	public void setDispatchComments(String dispatchComments) {
		this.dispatchComments = dispatchComments;
	}

	public String getScheduleID() {
		return scheduleID;
	}

	public void setScheduleID(String scheduleID) {
		this.scheduleID = scheduleID;
	}

	public String getScheduleWaveTime() {
		return scheduleWaveTime;
	}

	public void setScheduleWaveTime(String scheduleWaveTime) {
		this.scheduleWaveTime = scheduleWaveTime;
	}

	public String getScheduleServiceTier() {
		return scheduleServiceTier;
	}

	public void setScheduleServiceTier(String scheduleServiceTier) {
		this.scheduleServiceTier = scheduleServiceTier;
	}

	public List getGasCardList() {
		return gasCardList;
	}

	public void setGasCardList(List gasCardList) {
		this.gasCardList = gasCardList;
	}

}
