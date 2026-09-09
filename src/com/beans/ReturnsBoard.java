package com.beans;

import java.util.ArrayList;
import java.util.List;

public class ReturnsBoard extends MainBean {

	public ReturnsBoard() {
		setDisplayName("Returns Board");
		setController("ReturnsBoard");
	}

	@Override
	public List<String> getBeanAttributes() {
		return new ArrayList<String>();
	}
}
