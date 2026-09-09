package com.beans;

import java.util.ArrayList;
import java.util.List;

public class AdminVehicle extends MainBean {

	private String adminVehicleID = "";
	private String vehicleNumber = "";
	private String vinNumber = "";
	private String vehicleType = "";
	private String licensePlate = "";
	private String registrationExpiryDate = "";
	private String registeredState = "";
	private String serviceTier = "";

	private String opertionalStatus = "";
	private String comments = "";

	private String make = "";
	private String model = "";
	private String subModel = "";
	private String statusPriority = "";
	private String statusReasonCode = "";
	private String statusReasonMesg = "";
	private String statusSearchVal = "";
	private String subContractorName = "";
	private String provider = "";
	private String registrationType = "";
	private String vehicleYear = "";
	private String ownershipType = "";
	private String ownershipStart = "";
	private String ownershipEnd = "";
	private String station = "";
	private String serviceType = "";
	private String rentalStart = "";
	private String rentalEnd = "";

	private List opertionalStatusReasonList = new ArrayList();

	public AdminVehicle() {
		setDisplayName("Vehicle");
		setController("AdminVehicle");
	}

	@Override
	public List<String> getBeanAttributes() {

		List<String> beanAttributes = new ArrayList<String>();
		beanAttributes.add("adminVehicleID");
		beanAttributes.add("entityID");
		beanAttributes.add("vehicleNumber");
		beanAttributes.add("vinNumber");
		beanAttributes.add("vehicleType");
		beanAttributes.add("licensePlate");
		beanAttributes.add("registrationExpiryDate");
		beanAttributes.add("registeredState");
		beanAttributes.add("serviceTier");
		beanAttributes.add("opertionalStatus");
		beanAttributes.add("comments");

		beanAttributes.add("make");
		beanAttributes.add("model");
		beanAttributes.add("subModel");
		beanAttributes.add("statusPriority");
		beanAttributes.add("statusReasonCode");
		beanAttributes.add("statusReasonMesg");
		beanAttributes.add("statusSearchVal");
		beanAttributes.add("subContractorName");
		beanAttributes.add("provider");
		beanAttributes.add("registrationType");
		beanAttributes.add("vehicleYear");
		beanAttributes.add("ownershipType");
		beanAttributes.add("ownershipStart");
		beanAttributes.add("ownershipEnd");
		beanAttributes.add("station");
		beanAttributes.add("serviceType");
		beanAttributes.add("rentalStart");
		beanAttributes.add("rentalEnd");

		beanAttributes.add("createUser");
		beanAttributes.add("createDate");
		beanAttributes.add("updateUser");
		beanAttributes.add("updateDate");
		beanAttributes.add("status");
		return beanAttributes;
	}

	public String getAdminVehicleID() {
		return adminVehicleID;
	}

	public void setAdminVehicleID(String adminVehicleID) {
		this.adminVehicleID = adminVehicleID;
	}

	public String getVehicleNumber() {
		return vehicleNumber;
	}

	public void setVehicleNumber(String vehicleNumber) {
		this.vehicleNumber = vehicleNumber;
	}

	public String getVinNumber() {
		return vinNumber;
	}

	public void setVinNumber(String vinNumber) {
		this.vinNumber = vinNumber;
	}

	public String getVehicleType() {
		return vehicleType;
	}

	public void setVehicleType(String vehicleType) {
		this.vehicleType = vehicleType;
	}

	public String getLicensePlate() {
		return licensePlate;
	}

	public void setLicensePlate(String licensePlate) {
		this.licensePlate = licensePlate;
	}

	public String getRegistrationExpiryDate() {
		return registrationExpiryDate;
	}

	public void setRegistrationExpiryDate(String registrationExpiryDate) {
		this.registrationExpiryDate = registrationExpiryDate;
	}

	public String getRegisteredState() {
		return registeredState;
	}

	public void setRegisteredState(String registeredState) {
		this.registeredState = registeredState;
	}

	public String getServiceTier() {
		return serviceTier;
	}

	public void setServiceTier(String serviceTier) {
		this.serviceTier = serviceTier;
	}

	public String getOpertionalStatus() {
		return opertionalStatus;
	}

	public void setOpertionalStatus(String opertionalStatus) {
		this.opertionalStatus = opertionalStatus;
	}

	public String getComments() {
		return comments;
	}

	public void setComments(String comments) {
		this.comments = comments;
	}

	public String getMake() {
		return make;
	}

	public void setMake(String make) {
		this.make = make;
	}

	public String getModel() {
		return model;
	}

	public void setModel(String model) {
		this.model = model;
	}

	public String getSubModel() {
		return subModel;
	}

	public void setSubModel(String subModel) {
		this.subModel = subModel;
	}

	public String getStatusPriority() {
		return statusPriority;
	}

	public void setStatusPriority(String statusPriority) {
		this.statusPriority = statusPriority;
	}

	public String getStatusReasonCode() {
		return statusReasonCode;
	}

	public void setStatusReasonCode(String statusReasonCode) {
		this.statusReasonCode = statusReasonCode;
	}

	public String getStatusReasonMesg() {
		return statusReasonMesg;
	}

	public void setStatusReasonMesg(String statusReasonMesg) {
		this.statusReasonMesg = statusReasonMesg;
	}

	public String getStatusSearchVal() {
		return statusSearchVal;
	}

	public void setStatusSearchVal(String statusSearchVal) {
		this.statusSearchVal = statusSearchVal;
	}

	public String getSubContractorName() {
		return subContractorName;
	}

	public void setSubContractorName(String subContractorName) {
		this.subContractorName = subContractorName;
	}

	public String getProvider() {
		return provider;
	}

	public void setProvider(String provider) {
		this.provider = provider;
	}

	public String getRegistrationType() {
		return registrationType;
	}

	public void setRegistrationType(String registrationType) {
		this.registrationType = registrationType;
	}

	public String getVehicleYear() {
		return vehicleYear;
	}

	public void setVehicleYear(String vehicleYear) {
		this.vehicleYear = vehicleYear;
	}

	public String getOwnershipType() {
		return ownershipType;
	}

	public void setOwnershipType(String ownershipType) {
		this.ownershipType = ownershipType;
	}

	public String getOwnershipStart() {
		return ownershipStart;
	}

	public void setOwnershipStart(String ownershipStart) {
		this.ownershipStart = ownershipStart;
	}

	public String getOwnershipEnd() {
		return ownershipEnd;
	}

	public void setOwnershipEnd(String ownershipEnd) {
		this.ownershipEnd = ownershipEnd;
	}

	public String getStation() {
		return station;
	}

	public void setStation(String station) {
		this.station = station;
	}

	public String getServiceType() {
		return serviceType;
	}

	public void setServiceType(String serviceType) {
		this.serviceType = serviceType;
	}

	public List getOpertionalStatusReasonList() {
		return opertionalStatusReasonList;
	}

	public void setOpertionalStatusReasonList(List opertionalStatusReasonList) {
		this.opertionalStatusReasonList = opertionalStatusReasonList;
	}

	public String getRentalStart() {
		return rentalStart;
	}

	public void setRentalStart(String rentalStart) {
		this.rentalStart = rentalStart;
	}

	public String getRentalEnd() {
		return rentalEnd;
	}

	public void setRentalEnd(String rentalEnd) {
		this.rentalEnd = rentalEnd;
	}

}
