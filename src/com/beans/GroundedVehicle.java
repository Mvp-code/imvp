package com.beans;

import java.util.ArrayList;
import java.util.List;

public class GroundedVehicle extends MainBean {

	public GroundedVehicle() {
		setDisplayName("Grounded Vehicles");
		setController("GroundedVehicle");
	}

	@Override
	public List<String> getBeanAttributes() {
		return new ArrayList<String>();
	}
}
