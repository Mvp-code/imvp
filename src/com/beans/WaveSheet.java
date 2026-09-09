package com.beans;

import java.util.ArrayList;
import java.util.List;

public class WaveSheet extends MainBean {

	public WaveSheet() {
		setDisplayName("Wave Sheet");
		setController("WaveSheet");
	}

	@Override
	public List<String> getBeanAttributes() {
		return new ArrayList<String>();
	}
}