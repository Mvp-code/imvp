package com.beans;

import java.util.ArrayList;
import java.util.List;

public class EmployeeDashboard extends MainBean {

	private String dashboardOverviewID = "";

	public EmployeeDashboard() {
		setDisplayName("Dashboard");
		setController("EmployeeDashboard");
	}

	@Override
	public List<String> getBeanAttributes() {

		List<String> beanAttributes = new ArrayList<String>();
		beanAttributes.add("dashboardOverviewID");

		beanAttributes.add("numOfRows");
		return beanAttributes;
	}

	public String getDashboardOverviewID() {
		return dashboardOverviewID;
	}

	public void setDashboardOverviewID(String dashboardOverviewID) {
		this.dashboardOverviewID = dashboardOverviewID;
	}

}
