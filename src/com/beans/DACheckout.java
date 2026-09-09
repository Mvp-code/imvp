package com.beans;

import java.util.ArrayList;
import java.util.List;

public class DACheckout extends DACheckin {

	private String daCheckoutID = "";
	private String clockoutDate = "";
	private String clockoutTime = "";
	private String postInspection = "";
	private String vehicleClean = "";
	private String dispatcherChecked = "";
	private String packagesLeft = "";
	private String calledFromLast = "";
	private String phoneReturned = "";
	private String flashLight = "";
	private String powerBank = "";
	private List checkinList = new ArrayList();

	public DACheckout() {
		setDisplayName("DA Checkout");
		setController("DACheckout");
	}

	@Override
	public List<String> getBeanAttributes() {

		List<String> beanAttributes = new ArrayList<String>();
		beanAttributes.add("daCheckoutID");
		beanAttributes.add("daCheckinID");
		beanAttributes.add("clockinDate");
		beanAttributes.add("clockinTime");
		beanAttributes.add("clockoutDate");
		beanAttributes.add("clockoutTime");
		beanAttributes.add("postInspection");
		beanAttributes.add("parking");
		beanAttributes.add("vehicleClean");
		beanAttributes.add("dispatcherChecked");
		beanAttributes.add("packagesLeft");
		beanAttributes.add("calledFromLast");
		beanAttributes.add("phoneReturned");
		beanAttributes.add("gasCard");
		beanAttributes.add("phoneCable");
		beanAttributes.add("flashLight");
		beanAttributes.add("powerBank");
		beanAttributes.add("daComments");
		beanAttributes.add("dispatchComments");

		beanAttributes.add("createUser");
		beanAttributes.add("createDate");
		beanAttributes.add("updateUser");
		beanAttributes.add("updateDate");
		beanAttributes.add("status");

		beanAttributes.add("employeeID");
		beanAttributes.add("vehicleID");
		return beanAttributes;
	}

	public String getDaCheckoutID() {
		return daCheckoutID;
	}

	public void setDaCheckoutID(String daCheckoutID) {
		this.daCheckoutID = daCheckoutID;
	}

	public String getClockoutDate() {
		return clockoutDate;
	}

	public void setClockoutDate(String clockoutDate) {
		this.clockoutDate = clockoutDate;
	}

	public String getClockoutTime() {
		return clockoutTime;
	}

	public void setClockoutTime(String clockoutTime) {
		this.clockoutTime = clockoutTime;
	}

	public String getPostInspection() {
		return postInspection;
	}

	public void setPostInspection(String postInspection) {
		this.postInspection = postInspection;
	}

	public String getVehicleClean() {
		return vehicleClean;
	}

	public void setVehicleClean(String vehicleClean) {
		this.vehicleClean = vehicleClean;
	}

	public String getDispatcherChecked() {
		return dispatcherChecked;
	}

	public void setDispatcherChecked(String dispatcherChecked) {
		this.dispatcherChecked = dispatcherChecked;
	}

	public String getPackagesLeft() {
		return packagesLeft;
	}

	public void setPackagesLeft(String packagesLeft) {
		this.packagesLeft = packagesLeft;
	}

	public String getCalledFromLast() {
		return calledFromLast;
	}

	public void setCalledFromLast(String calledFromLast) {
		this.calledFromLast = calledFromLast;
	}

	public String getPhoneReturned() {
		return phoneReturned;
	}

	public void setPhoneReturned(String phoneReturned) {
		this.phoneReturned = phoneReturned;
	}

	public String getFlashLight() {
		return flashLight;
	}

	public void setFlashLight(String flashLight) {
		this.flashLight = flashLight;
	}

	public String getPowerBank() {
		return powerBank;
	}

	public void setPowerBank(String powerBank) {
		this.powerBank = powerBank;
	}

	public List getCheckinList() {
		return checkinList;
	}

	public void setCheckinList(List checkinList) {
		this.checkinList = checkinList;
	}

}
