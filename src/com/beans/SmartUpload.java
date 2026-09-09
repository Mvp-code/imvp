package com.beans;

import java.util.ArrayList;
import java.util.List;

public class SmartUpload extends GenericUpload {

	private String detectedType = "";
	private String uploadSummary = "";

	public SmartUpload() {
		setDisplayName("Smart Upload");
		setController("SmartUpload");
	}

	@Override
	public List<String> getBeanAttributes() {
		List<String> attrs = new ArrayList<String>();
		attrs.add("recordID");
		attrs.add("entityID");
		attrs.add("uploadFileName");
		attrs.add("uploadFileNameWithPath");
		attrs.add("tableName");
		attrs.add("dataSeperator");
		attrs.add("selectedType");
		attrs.add("detectedType");
		attrs.add("uploadSummary");
		attrs.add("createUser");
		attrs.add("createDate");
		attrs.add("updateUser");
		attrs.add("updateDate");
		attrs.add("status");
		return attrs;
	}

	public String getDetectedType() { return detectedType; }
	public void setDetectedType(String detectedType) { this.detectedType = detectedType; }

	public String getUploadSummary() { return uploadSummary; }
	public void setUploadSummary(String uploadSummary) { this.uploadSummary = uploadSummary; }
}
