package com.beans;

import java.util.ArrayList;
import java.util.List;

public class OnBoarding extends MainBean {

	private String onBoardingID = "";

	public OnBoarding() {
		setDisplayName("On Boarding");
		setController("OnBoarding");
	}

	@Override
	public List<String> getBeanAttributes() {

		List<String> beanAttributes = new ArrayList<String>();
		beanAttributes.add("onBoardingID");
		beanAttributes.add("entityID");
		beanAttributes.add("uploadFileName");
		beanAttributes.add("uploadFileNameWithPath");

		beanAttributes.add("createUser");
		beanAttributes.add("createDate");
		beanAttributes.add("updateUser");
		beanAttributes.add("updateDate");
		beanAttributes.add("status");
		return beanAttributes;
	}

	public String getOnBoardingID() {
		return onBoardingID;
	}

	public void setOnBoardingID(String onBoardingID) {
		this.onBoardingID = onBoardingID;
	}
}
