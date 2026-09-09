package com.beans;

import java.util.ArrayList;
import java.util.List;

public class EmployeeCoachingFollowup extends MainBean {

	private String employeeCoachingFollowupID = "";
	private String deliveryOverviewID = "";
	private String deliveryYear = "";
	private String deliveryWeek = "";
	private String deliveryAssociate = "";

	public EmployeeCoachingFollowup() {
		setDisplayName("Coaching Followup");
		setController("EmployeeCoachingFollowup");
	}

	@Override
	public List<String> getBeanAttributes() {

		List<String> beanAttributes = new ArrayList<String>();
		beanAttributes.add("employeeCoachingFollowupID");
		beanAttributes.add("deliveryOverviewID");
		beanAttributes.add("deliveryYear");
		beanAttributes.add("deliveryWeek");
		beanAttributes.add("deliveryAssociate");

		beanAttributes.add("createUser");
		beanAttributes.add("createDate");
		beanAttributes.add("updateUser");
		beanAttributes.add("updateDate");
		beanAttributes.add("status");
		beanAttributes.add("numOfRows");
		return beanAttributes;
	}

	public String getEmployeeCoachingFollowupID() {
		return employeeCoachingFollowupID;
	}

	public void setEmployeeCoachingFollowupID(
			String employeeCoachingFollowupID) {
		this.employeeCoachingFollowupID = employeeCoachingFollowupID;
	}

	public String getDeliveryOverviewID() {
		return deliveryOverviewID;
	}

	public void setDeliveryOverviewID(String deliveryOverviewID) {
		this.deliveryOverviewID = deliveryOverviewID;
	}

	public String getDeliveryYear() {
		return deliveryYear;
	}

	public void setDeliveryYear(String deliveryYear) {
		this.deliveryYear = deliveryYear;
	}

	public String getDeliveryWeek() {
		return deliveryWeek;
	}

	public void setDeliveryWeek(String deliveryWeek) {
		this.deliveryWeek = deliveryWeek;
	}

	public String getDeliveryAssociate() {
		return deliveryAssociate;
	}

	public void setDeliveryAssociate(String deliveryAssociate) {
		this.deliveryAssociate = deliveryAssociate;
	}

}
