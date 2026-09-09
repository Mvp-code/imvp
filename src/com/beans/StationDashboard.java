package com.beans;

import java.util.ArrayList;
import java.util.List;

public class StationDashboard extends MainBean {

	public StationDashboard() {
		setDisplayName("MVPx Dashboard");
		setController("StationDashboard");
	}

	@Override
	public List<String> getBeanAttributes() {
		return new ArrayList<String>();
	}
}
