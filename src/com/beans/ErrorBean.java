package com.beans;

public class ErrorBean {
	
	public enum enumTypes {
		success, error, notice, warning
	}

	private String type = "";
	private String mesg = "";

	public String getType() {
		return type;
	}

	public void setType(String type) {
		this.type = type;
	}

	public String getMesg() {
		return mesg;
	}

	public void setMesg(String mesg) {
		this.mesg = mesg;
	}

}
