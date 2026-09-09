package com.beans;

import java.util.ArrayList;
import java.util.List;

public class GenericSMS extends MainBean {

	private String station = "";
	private String message = "";

	public GenericSMS() {
		setDisplayName("SMS");
		setController("GenericSMS");
	}

	@Override
	public List<String> getBeanAttributes() {

		List<String> beanAttributes = new ArrayList<String>();
		beanAttributes.add("recordID");
		beanAttributes.add("entityID");
		beanAttributes.add("station");
		beanAttributes.add("message");

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

	public String getMessage() {
		return message;
	}

	public void setMessage(String message) {
		this.message = message;
	}

}
