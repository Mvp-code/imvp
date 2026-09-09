package com.beans;

import java.util.ArrayList;
import java.util.List;

public class AdminGasCard extends MainBean {

	private String gasCardID = "";
	private String cardIdentifier = "";
	private String cardStatus = "";
	private String cardStatusDate = "";
	private String cardStatusReason = "";
	private String cardExpiry = "";
	private String lockStatus = "";
	private String location = "";
	private String available = "";

	public AdminGasCard() {
		setDisplayName("Gas Card");
		setController("AdminGasCard");
	}

	@Override
	public List<String> getBeanAttributes() {

		List<String> beanAttributes = new ArrayList<String>();
		beanAttributes.add("gasCardID");
		beanAttributes.add("entityID");
		beanAttributes.add("cardIdentifier");
		beanAttributes.add("cardStatus");
		beanAttributes.add("cardStatusDate");
		beanAttributes.add("cardStatusReason");
		beanAttributes.add("cardExpiry");
		beanAttributes.add("lockStatus");
		beanAttributes.add("location");
		beanAttributes.add("available");

		beanAttributes.add("createUser");
		beanAttributes.add("createDate");
		beanAttributes.add("updateUser");
		beanAttributes.add("updateDate");
		beanAttributes.add("status");
		return beanAttributes;
	}

	public String getGasCardID() {
		return gasCardID;
	}

	public void setGasCardID(String gasCardID) {
		this.gasCardID = gasCardID;
	}

	public String getCardIdentifier() {
		return cardIdentifier;
	}

	public void setCardIdentifier(String cardIdentifier) {
		this.cardIdentifier = cardIdentifier;
	}

	public String getCardStatus() {
		return cardStatus;
	}

	public void setCardStatus(String cardStatus) {
		this.cardStatus = cardStatus;
	}

	public String getCardStatusDate() {
		return cardStatusDate;
	}

	public void setCardStatusDate(String cardStatusDate) {
		this.cardStatusDate = cardStatusDate;
	}

	public String getCardStatusReason() {
		return cardStatusReason;
	}

	public void setCardStatusReason(String cardStatusReason) {
		this.cardStatusReason = cardStatusReason;
	}

	public String getCardExpiry() {
		return cardExpiry;
	}

	public void setCardExpiry(String cardExpiry) {
		this.cardExpiry = cardExpiry;
	}

	public String getLockStatus() {
		return lockStatus;
	}

	public void setLockStatus(String lockStatus) {
		this.lockStatus = lockStatus;
	}

	public String getLocation() {
		return location;
	}

	public void setLocation(String location) {
		this.location = location;
	}

	public String getAvailable() {
		return available;
	}

	public void setAvailable(String available) {
		this.available = available;
	}
}
