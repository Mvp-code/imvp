package com.beans;

import java.util.ArrayList;
import java.util.List;

public class EmployeeRequest extends MainBean {

	public static final String PRIMARY_KEY_ID = "recordID";
	private String comments = "";

	public EmployeeRequest() {
		setDisplayName("Employee Request");
		setController("EmployeeRequest");
	}

	@Override
	public List<String> getBeanAttributes() {

		List<String> beanAttributes = new ArrayList<String>();
		beanAttributes.add("recordID");
		beanAttributes.add("entityID");
		beanAttributes.add("comments");
		beanAttributes.add("createUser");
		beanAttributes.add("createDate");
		beanAttributes.add("updateUser");
		beanAttributes.add("updateDate");
		beanAttributes.add("status");
		return beanAttributes;
	}

	public String getComments() {
		return comments;
	}

	public void setComments(String comments) {
		this.comments = comments;
	}

}
