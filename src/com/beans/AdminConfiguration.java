package com.beans;

import java.util.ArrayList;
import java.util.List;

public class AdminConfiguration extends MainBean {

	private String recordID = "";
	private String category = "";
	private String name = "";
	private String value = "";

	public enum enumCategorys {
		GENERAL, SMS, VEHICLE
	}

	public enum enumGeneral {
		PREFERRED_LANGUAGE
	}

	public enum enumSMS {
		SMS_GATEWAY, TwilioPrimaryNum, TwilioAccountSID, TwilioAuthToken,
		/*-
		DACheckin_OutTemplate,
		DACheckin_OutTemplate__GENERAL_PREFERRED_LANGUAGE,
		DACheckin_BeforeTimeInMins,
		*/

		DAStatus_OutTemplate, DAStatus_OutTemplate__GENERAL_PREFERRED_LANGUAGE,
		DAStatus_BeforeTimeInMins
	}

	public enum enumVehicle {
		REGISTRATION_EXPIRY_WARN_DAYS
	}

	public AdminConfiguration() {
		setDisplayName("Configuration");
		setController("AdminConfiguration");
	}

	@Override
	public List<String> getBeanAttributes() {

		List<String> beanAttributes = new ArrayList<String>();
		beanAttributes.add("recordID");
		beanAttributes.add("entityID");
		beanAttributes.add("category");
		beanAttributes.add("name");
		beanAttributes.add("value");

		beanAttributes.add("createUser");
		beanAttributes.add("createDate");
		beanAttributes.add("updateUser");
		beanAttributes.add("updateDate");
		beanAttributes.add("status");
		beanAttributes.add("numOfRows");

		return beanAttributes;
	}

	public String getRecordID() {
		return recordID;
	}

	public void setRecordID(String recordID) {
		this.recordID = recordID;
	}

	public String getCategory() {
		return category;
	}

	public void setCategory(String category) {
		this.category = category;
	}

	public String getName() {
		return name;
	}

	public void setName(String name) {
		this.name = name;
	}

	public String getValue() {
		return value;
	}

	public void setValue(String value) {
		this.value = value;
	}

}
