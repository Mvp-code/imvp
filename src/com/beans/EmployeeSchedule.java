package com.beans;

import java.util.ArrayList;
import java.util.List;

public class EmployeeSchedule extends MainBean {

	public EmployeeSchedule() {
		setDisplayName("Employee Schedule");
		setController("EmployeeSchedule");
	}

	private String employeeScheduleID = "";
	private String employeeAvailabilityID = "";
	private String employeeID = "";
	private String scheduleDate = "";
	private String scheduleDays = "";
	private String wave0 = "";
	private String wave1 = "";
	private String wave2 = "";
	private String wave3 = "";
	private String wave4 = "";
	private String wave5 = "";
	private String wave6 = "";

	@Override
	public List<String> getBeanAttributes() {

		List<String> beanAttributes = new ArrayList<String>();
		beanAttributes.add("employeeScheduleID");
		beanAttributes.add("employeeID");
		beanAttributes.add("employeeAvailabilityID");
		beanAttributes.add("scheduleDate");
		beanAttributes.add("scheduleDays");
		beanAttributes.add("wave0");
		beanAttributes.add("wave1");
		beanAttributes.add("wave2");
		beanAttributes.add("wave3");
		beanAttributes.add("wave4");
		beanAttributes.add("wave5");
		beanAttributes.add("wave6");

		beanAttributes.add("createUser");
		beanAttributes.add("createDate");
		beanAttributes.add("updateUser");
		beanAttributes.add("updateDate");
		beanAttributes.add("status");
		return beanAttributes;
	}

	public String getEmployeeScheduleID() {
		return employeeScheduleID;
	}

	public void setEmployeeScheduleID(String employeeScheduleID) {
		this.employeeScheduleID = employeeScheduleID;
	}

	public String getEmployeeID() {
		return employeeID;
	}

	public void setEmployeeID(String employeeID) {
		this.employeeID = employeeID;
	}

	public String getEmployeeAvailabilityID() {
		return employeeAvailabilityID;
	}

	public void setEmployeeAvailabilityID(String employeeAvailabilityID) {
		this.employeeAvailabilityID = employeeAvailabilityID;
	}

	public String getScheduleDate() {
		return scheduleDate;
	}

	public void setScheduleDate(String scheduleDate) {
		this.scheduleDate = scheduleDate;
	}

	public String getScheduleDays() {
		return scheduleDays;
	}

	public void setScheduleDays(String scheduleDays) {
		this.scheduleDays = scheduleDays;
	}

	public String getWave0() {
		return wave0;
	}

	public void setWave0(String wave0) {
		this.wave0 = wave0;
	}

	public String getWave1() {
		return wave1;
	}

	public void setWave1(String wave1) {
		this.wave1 = wave1;
	}

	public String getWave2() {
		return wave2;
	}

	public void setWave2(String wave2) {
		this.wave2 = wave2;
	}

	public String getWave3() {
		return wave3;
	}

	public void setWave3(String wave3) {
		this.wave3 = wave3;
	}

	public String getWave4() {
		return wave4;
	}

	public void setWave4(String wave4) {
		this.wave4 = wave4;
	}

	public String getWave5() {
		return wave5;
	}

	public void setWave5(String wave5) {
		this.wave5 = wave5;
	}

	public String getWave6() {
		return wave6;
	}

	public void setWave6(String wave6) {
		this.wave6 = wave6;
	}

}
