package com.controller;

import com.util.SubmitType;
import java.io.ByteArrayOutputStream;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

public class ControllerParameters {

	private String entityID = "";

	private String loginUserID = "";
	private String loginUser = "";
	private String loginUserDisplayName = "";
	private String loginUserRoles = "";

	private String controller = "";
	private String recordID = "";

	private String responseType = "";
	private String responseMessage = "";

	private String forwardTo = "";
	private int submitType = SubmitType.CREATE;
	private boolean isDispatcherRequired = true;

	private HttpServletRequest request;
	private HttpServletResponse response;

	private ByteArrayOutputStream baos = null;
	private String reportFileNameWithPath = "";

	public String getEntityID() {
		return entityID;
	}

	public void setEntityID(String entityID) {
		this.entityID = entityID;
	}

	public String getLoginUserID() {
		return loginUserID;
	}

	public void setLoginUserID(String loginUserID) {
		this.loginUserID = loginUserID;
	}

	public String getLoginUser() {
		return loginUser;
	}

	public void setLoginUser(String loginUser) {
		this.loginUser = loginUser;
	}

	public String getLoginUserDisplayName() {
		return loginUserDisplayName;
	}

	public void setLoginUserDisplayName(String loginUserDisplayName) {
		this.loginUserDisplayName = loginUserDisplayName;
	}

	public String getLoginUserRoles() {
		return loginUserRoles;
	}

	public void setLoginUserRoles(String loginUserRoles) {
		this.loginUserRoles = loginUserRoles;
	}

	public String getRecordID() {
		return recordID;
	}

	public void setRecordID(String recordID) {
		this.recordID = recordID;
	}

	public String getController() {
		return controller;
	}

	public void setController(String controller) {
		this.controller = controller;
	}

	public String getResponseType() {
		return responseType;
	}

	public void setResponseType(String responseType) {
		this.responseType = responseType;
	}

	public String getResponseMessage() {
		return responseMessage;
	}

	public void setResponseMessage(String responseMessage) {
		this.responseMessage = responseMessage;
	}

	public String getForwardTo() {
		return forwardTo;
	}

	public void setForwardTo(String forwardTo) {
		this.forwardTo = forwardTo;
	}

	public int getSubmitType() {
		return submitType;
	}

	public void setSubmitType(int submitType) {
		this.submitType = submitType;
	}

	public boolean isDispatcherRequired() {
		return isDispatcherRequired;
	}

	public void setDispatcherRequired(boolean isDispatcherRequired) {
		this.isDispatcherRequired = isDispatcherRequired;
	}

	public HttpServletRequest getRequest() {
		return request;
	}

	public void setRequest(HttpServletRequest request) {
		this.request = request;
	}

	public HttpServletResponse getResponse() {
		return response;
	}

	public void setResponse(HttpServletResponse response) {
		this.response = response;
	}

	public ByteArrayOutputStream getBaos() {
		return baos;
	}

	public void setBaos(ByteArrayOutputStream baos) {
		this.baos = baos;
	}

	public String getReportFileNameWithPath() {
		return reportFileNameWithPath;
	}

	public void setReportFileNameWithPath(String reportFileNameWithPath) {
		this.reportFileNameWithPath = reportFileNameWithPath;
	}

}
