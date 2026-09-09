package com.beans;

import java.util.ArrayList;
import java.util.List;

public class AdminIncidentCategory extends MainBean {

	private String incidentCategoryID = "";
	private String categoryName = "";

	public AdminIncidentCategory() {
		setDisplayName("Incident Category");
		setController("AdminIncidentCategory");
	}

	@Override
	public List<String> getBeanAttributes() {

		List<String> beanAttributes = new ArrayList<String>();
		beanAttributes.add("incidentCategoryID");
		beanAttributes.add("entityID");
		beanAttributes.add("categoryName");

		beanAttributes.add("createUser");
		beanAttributes.add("createDate");
		beanAttributes.add("updateUser");
		beanAttributes.add("updateDate");
		beanAttributes.add("status");
		beanAttributes.add("numOfRows");
		return beanAttributes;
	}

	public String getIncidentCategoryID() {
		return incidentCategoryID;
	}

	public void setIncidentCategoryID(String incidentCategoryID) {
		this.incidentCategoryID = incidentCategoryID;
	}

	public String getCategoryName() {
		return categoryName;
	}

	public void setCategoryName(String categoryName) {
		this.categoryName = categoryName;
	}

}
