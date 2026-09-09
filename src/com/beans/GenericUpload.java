package com.beans;

import java.util.ArrayList;
import java.util.List;

public class GenericUpload extends MainBean {

	public static final String PRIMARY_KEY_ID = "recordID";
	private String selectedType = "";

	public GenericUpload() {
		setDisplayName("Upload");
		setController("GenericUpload");
	}

	@Override
	public List<String> getBeanAttributes() {

		List<String> beanAttributes = new ArrayList<String>();
		beanAttributes.add("recordID");
		beanAttributes.add("entityID");
		beanAttributes.add("uploadFileName");
		beanAttributes.add("uploadFileNameWithPath");
		beanAttributes.add("tableName");
		beanAttributes.add("dataSeperator");
		beanAttributes.add("selectedType");

		beanAttributes.add("createUser");
		beanAttributes.add("createDate");
		beanAttributes.add("updateUser");
		beanAttributes.add("updateDate");
		beanAttributes.add("status");
		return beanAttributes;
	}

	public String getSelectedType() {
		return selectedType;
	}

	public void setSelectedType(String selectedType) {
		this.selectedType = selectedType;
	}
}
