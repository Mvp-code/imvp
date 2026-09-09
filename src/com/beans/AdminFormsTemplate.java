package com.beans;

import java.util.ArrayList;
import java.util.List;

public class AdminFormsTemplate extends MainBean {

	private String adminFormsTemplateID = "";
	private String formName = "";
	private String formContents = "";

	public AdminFormsTemplate() {
		setDisplayName("Form");
		setController("AdminFormsTemplate");
	}

	@Override
	public List<String> getBeanAttributes() {

		List<String> beanAttributes = new ArrayList<String>();
		beanAttributes.add("adminFormsTemplateID");
		beanAttributes.add("entityID");
		beanAttributes.add("formName");
		beanAttributes.add("formContents");

		beanAttributes.add("createUser");
		beanAttributes.add("createDate");
		beanAttributes.add("updateUser");
		beanAttributes.add("updateDate");
		beanAttributes.add("status");
		return beanAttributes;
	}

	public String getAdminFormsTemplateID() {
		return adminFormsTemplateID;
	}

	public void setAdminFormsTemplateID(String adminFormsTemplateID) {
		this.adminFormsTemplateID = adminFormsTemplateID;
	}

	public String getFormName() {
		return formName;
	}

	public void setFormName(String formName) {
		this.formName = formName;
	}

	public String getFormContents() {
		return formContents;
	}

	public void setFormContents(String formContents) {
		this.formContents = formContents;
	}

}
