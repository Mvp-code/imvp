package com.beans;

import java.util.ArrayList;
import java.util.List;

public class Login extends MainBean {

	private String loginUserID = "";
	private String loginUser = "";
	private String loginRole = "";
	private String loginPwd = "";

	public Login() {
		setDisplayName("Login");
		setController("Login");
	}

	@Override
	public List<String> getBeanAttributes() {

		List<String> beanAttributes = new ArrayList<String>();
		beanAttributes.add("loginUserID");
		beanAttributes.add("loginUser");
		beanAttributes.add("loginPwd");
		beanAttributes.add("loginRole");

		beanAttributes.add("createUser");
		beanAttributes.add("createDate");
		beanAttributes.add("updateUser");
		beanAttributes.add("updateDate");
		beanAttributes.add("status");
		return beanAttributes;
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

	public String getLoginRole() {
		return loginRole;
	}

	public void setLoginRole(String loginRole) {
		this.loginRole = loginRole;
	}

	public String getLoginPwd() {
		return loginPwd;
	}

	public void setLoginPwd(String loginPwd) {
		this.loginPwd = loginPwd;
	}

}
