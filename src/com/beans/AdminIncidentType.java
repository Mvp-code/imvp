package com.beans;

import java.util.ArrayList;
import java.util.List;

public class AdminIncidentType extends MainBean {

	private String incidentTypeID = "";
	private String typeName = "";

	public AdminIncidentType() {
		setDisplayName("Incident Type");
		setController("AdminIncidentType");
	}

	@Override
	public List<String> getBeanAttributes() {

		List<String> beanAttributes = new ArrayList<String>();
		beanAttributes.add("incidentTypeID");
		beanAttributes.add("entityID");
		beanAttributes.add("typeName");

		beanAttributes.add("createUser");
		beanAttributes.add("createDate");
		beanAttributes.add("updateUser");
		beanAttributes.add("updateDate");
		beanAttributes.add("status");
		beanAttributes.add("numOfRows");
		return beanAttributes;
	}

	public String getIncidentTypeID() {
		return incidentTypeID;
	}

	public void setIncidentTypeID(String incidentTypeID) {
		this.incidentTypeID = incidentTypeID;
	}

	public String getTypeName() {
		return typeName;
	}

	public void setTypeName(String typeName) {
		this.typeName = typeName;
	}

}
