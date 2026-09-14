package com.dataobjects;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import com.beans.Address;
import com.beans.AdminConfiguration;
import com.beans.AdminEmployee;
import com.beans.Contact;
import com.beans.ErrorBean;
import com.beans.MainBean;
import com.beans.SearchBean;
import com.util.RecordStatus;
import com.util.SubmitType;

public class AdminEmployeeDAO extends MVPGDAO {

	AdminEmployee bean = new AdminEmployee();

	@Override
	public SearchBean searchRecords(SearchBean searchBean, String recordID,
			String loginUser, String loginUserRoles, String loginUserID,
			String entityID) throws Exception {

		List<String> labelsList = new ArrayList<String>();
		labelsList.add("Employee");
		labelsList.add("Mobile");
		labelsList.add("Language");
		labelsList.add("SMS");
		labelsList.add("Expiry");
		labelsList.add("Availability");
		labelsList.add("Role");
		labelsList.add("Status");

		searchBean.setWidthColumns(new int[] { 24, 12, 8, 10, 10, 16, 10, 10 });

		searchBean.setDisplayName(bean.getDisplayName() + "s");

		searchBean.setController(bean.getController());

		String condQry = "";
		int submitType = SubmitType.SEARCH;
		if (searchBean.getSelectedType().length() > 0) {
			submitType = Integer.parseInt(searchBean.getSelectedType());
			if (submitType == SubmitType.UPDATE) {
				condQry += db.getIDInCondQuery(searchBean.getSelectedValues(),
						"A.EMPLOYEEID");

			} else if (submitType == SubmitType.UPDATE_CONFIRM) {
				boolean result = updateRecords(searchBean.getTransList(),
						RecordStatus.ACTIVE, loginUser);
				searchBean.setErrorBean(getErrorType(result, SubmitType.UPDATE,
						bean.getDisplayName()));
			}
		}

		/*-
		if (searchBean.getSrhValue().length() > 0) {
			String splitArray[] = searchBean.getSrhValue().split(",");
			if (splitArray.length == 2) {
				condQry += " AND (A.LASTNAME LIKE '%" + splitArray[0]
						+ "%' AND A.FIRSTNAME LIKE '%" + splitArray[1] + "%') ";
		
			} else {
				splitArray = searchBean.getSrhValue().split(" ");
				if (splitArray.length == 2) {
					condQry += "  AND (A.FIRSTNAME LIKE '%" + splitArray[0]
							+ "%' AND A.LASTNAME LIKE '%" + splitArray[1]
							+ "%') ";
				} else {
					condQry += "  AND (A.FIRSTNAME LIKE '%"
							+ searchBean.getSrhValue()
							+ "%' OR A.LASTNAME LIKE '%"
							+ searchBean.getSrhValue() + "%') ";
				}
			}
		}
		*/

		condQry += db.getDataLikeCondQuery(searchBean.getSrhValue(),
				"A.FULLNAME");

		condQry += db.getDataLikeCondQuery(searchBean.getSrhValue2(),
				"B.MOBILE");

		condQry += db.getDataLikeCondQuery(searchBean.getSrhTransporterID(),
				"A.TRANSPORTERID");

		condQry += db.getIDInCondQuery(searchBean.getSrhRole(), "A.ROLE");

		/* no default active-only clamp: the list carries every employee and
		   the page's status filter (Active / Inactive / Terminated) narrows */
		if (searchBean.getSrhStatus().length() > 0) {
			condQry += db.getIDInCondQuery(searchBean.getSrhStatus(),
					"A.REVIEW_STATUS");
		}

		searchBean.setColumnSortName(
				searchBean.getColumnSortName().replaceAll("6", "9"));

		String selQry = "SELECT A.EMPLOYEEID, A.FULLNAME, "
				+ "B.MOBILE, A.PREFERRED_LANGUAGE, A.SMS_PREF, "
				+ db.getSelectDate("A.IDEXPIRY")
				+ ", '', A.ROLE, A.REVIEW_STATUS, "
				+ "(SELECT COUNT(*) FROM employeetermination TT WHERE "
				+ "TT.EMPLOYEEID=A.EMPLOYEEID AND TT.STATUS!=1), "
				+ db.getSelectDateFormat("A.IDEXPIRY",
						db.ORACLE_YYYYMMDDHH24MISS)
				+ " FROM EMPLOYEE A "
				+ "LEFT JOIN CONTACT B ON A.CONTACTID=B.CONTACTID WHERE A.STATUS!="
				+ RecordStatus.DELETE + " AND A.ENTITYID=" + entityID + condQry
				+ getOrderByQry(searchBean, "2, 6, 3");

		searchBean.setColumnSortName(
				searchBean.getColumnSortName().replaceAll("9", "6"));
		List resultList = db.selectAsList(selQry, 11);
		if (resultList.size() > 0) {
			selQry = "SELECT EMPLOYEEID, AVAILABILITY FROM "
					+ "EMPLOYEE_AVAILABILITY WHERE STATUS="
					+ RecordStatus.ACTIVE;
			Map<String, String> _availabilityMap = getMap(
					db.selectAsList(selQry, 2));

			for (int i = 0; i < resultList.size(); i++) {
				List tempList = (ArrayList) resultList.get(i);
				String empID = tempList.get(0) == null ? ""
						: tempList.get(0).toString().trim();
				String smsPref = tempList.get(4) == null ? ""
						: tempList.get(4).toString().trim();
				String role = tempList.get(7) == null ? ""
						: tempList.get(7).toString().trim();
				String reviewStatus = tempList.get(8) == null ? ""
						: tempList.get(8).toString().trim();
				String availability = _availabilityMap.get(empID) == null ? ""
						: _availabilityMap.get(empID);
				smsPref = "1".equalsIgnoreCase(smsPref) ? "Opt-in" : "Opt-out";
				reviewStatus = RecordStatus.RecordStatus[Integer
						.parseInt(reviewStatus)];
				role = getRoleName(role);

				tempList.set(4, smsPref);
				tempList.set(6, availability);
				tempList.set(7, role);
				tempList.set(8, reviewStatus);
				tempList.remove(tempList.size() - 1);
				resultList.set(i, tempList);
			}
		}

		searchBean.setLabelsList(labelsList);
		searchBean.setDataList(resultList);
		searchBean.setSearchFiltersArray(new String[] { "Name", "Mobile",
				"Status", "Transporter ID", "Role" });

		searchBean.setPreferredLanguageOptions(getPropertyValue(
				AdminConfiguration.enumCategorys.GENERAL.toString(),
				AdminConfiguration.enumGeneral.PREFERRED_LANGUAGE.toString(),
				entityID));

		return searchBean;
	}

	public boolean updateRecords(List transList, int status, String loginUser)
			throws Exception {

		boolean result = true;
		List<String> upList = new ArrayList<String>();
		for (int i = 0; i < transList.size(); i++) {
			List tempList = (ArrayList) transList.get(i);
			String recordID = tempList.get(0) == null ? ""
					: tempList.get(0).toString().trim();
			String employeeRole = tempList.get(1) == null ? ""
					: tempList.get(1).toString().trim();
			String preferredLanguage = tempList.get(2) == null ? ""
					: tempList.get(2).toString().trim();

			String upQry = "UPDATE EMPLOYEE SET ROLE="
					+ db.getInsertDBValue(employeeRole)
					+ ", PREFERRED_LANGUAGE="
					+ db.getInsertDBValue(preferredLanguage) + ", UPDATE_USER="
					+ db.getInsertDBValue(loginUser) + ", UPDATE_DATE="
					+ db.getInsertSysdate() + ", STATUS="
					+ db.getInsertDBValue(status) + " WHERE EMPLOYEEID="
					+ recordID;
			upList.add(upQry);
		}

		if (upList.size() > 0)
			result = db.batchInsert(upList);

		return result;
	}

	public String getRoleName(String role) {

		if ("1".equalsIgnoreCase(role))
			return "Dispatcher";
		else if ("2".equalsIgnoreCase(role))
			return "Manager";
		else if ("3".equalsIgnoreCase(role))
			return "Management";
		else if ("4".equalsIgnoreCase(role))
			return "DA Associate";
		return "";
	}

	@Override
	public Object[] createRecord(MainBean mainBean, String loginUser,
			String loginUserRoles, String loginUserID, String entityID)
			throws Exception {

		bean = (AdminEmployee) mainBean;
		ErrorBean errorType = new ErrorBean();
		Contact contactBean = bean.getContactBean();

		String dataArray[] = checkRecordExist(bean.getFullName(),
				contactBean.getMobile(), "", entityID);
		String recordID = dataArray[0];

		if (recordID.length() == 0) {
			dataArray = checkRecordExist(bean.getFullName(), "",
					contactBean.getEmail(), entityID);
			recordID = dataArray[0];
		}

		if (recordID.length() == 0) {
			int status = bean.getStatus().length() == 0 ? RecordStatus.ACTIVE
					: Integer.parseInt(bean.getStatus());

			recordID = db.getNextIDValue("EMPLOYEEID");
			boolean result = createEmployee(recordID, entityID,
					bean.getFirstName(), bean.getLastName(), bean.getFullName(),
					bean.getSmsPref(), bean.getTransporterID(),
					bean.getPosition(), bean.getQualification(),
					bean.getIdExpiryDate(), bean.getReviewStatus(),
					bean.getEmployeeRole(), bean.getPreferredLanguage(),
					bean.getAvailability(), bean.getAddressBean(),
					bean.getContactBean(), status, loginUser);

			errorType = getErrorType(result, SubmitType.CREATE,
					bean.getDisplayName());
		} else {
			errorType = getErrorType(false, SubmitType.DUPLICATE,
					bean.getDisplayName());

		}

		return new Object[] { recordID, errorType };
	}

	public String[] checkRecordExist(String employeeName, String mobile,
			String email, String entityID) {

		String recordID = "", contactID = "";

		String condQry = db.getDataInCondQuery(employeeName, "A.FULLNAME");

		condQry += db.getDataInCondQuery(mobile, "B.MOBILE");

		condQry += db.getDataInCondQuery(email, "B.EMAIL");

		String selQry = "SELECT A.EMPLOYEEID, B.CONTACTID FROM EMPLOYEE A LEFT JOIN CONTACT B "
				+ "ON A.CONTACTID=B.CONTACTID WHERE A.STATUS IN ("
				+ RecordStatus.ACTIVE + ") AND A.ENTITYID=" + entityID
				+ condQry;
		try {
			List resultList = db.selectAsList(selQry, 2);
			if (resultList.size() > 0) {
				List tempList = (ArrayList) resultList.get(0);
				recordID = tempList.get(0) == null ? ""
						: tempList.get(0).toString().trim();
				contactID = tempList.get(1) == null ? ""
						: tempList.get(1).toString().trim();

			}
		} catch (Exception ex) {
			ex.printStackTrace();
		}
		return new String[] { recordID, contactID };
	}

	public boolean createEmployee(String recordID, String entityID,
			String firstName, String lastName, String fullName, String smsPref,
			String transportorID, String position, String qualification,
			String idExpiryDate, String reviewStatus, String employeeRole,
			String preferredLanguage, String availability, Address addressBean,
			Contact contactBean, int status, String loginUser)
			throws Exception {

		List<String> insList = new ArrayList<String>();

		String addressID = db.getNextIDValue("ADDRESSID");
		insList = buildAddressQry(true, addressID, addressBean, loginUser,
				insList);

		String contactID = db.getNextIDValue("CONTACTID");
		insList = buildContactQry(true, contactID, contactBean, loginUser,
				insList);

		String insQry = "INSERT INTO EMPLOYEE (EMPLOYEEID, ENTITYID, "
				+ "FIRSTNAME, LASTNAME, FULLNAME, SMS_PREF, TRANSPORTERID, "
				+ "POSITION, QUALIFICATION, IDEXPIRY, ADDRESSID, CONTACTID, PREFERRED_LANGUAGE, "
				+ "REVIEW_STATUS, ROLE, CREATE_USER, CREATE_DATE, STATUS) VALUES ("
				+ recordID + ", " + entityID + ", "
				+ db.getInsertDBValue(firstName) + ", "
				+ db.getInsertDBValue(lastName) + ", "
				+ db.getInsertDBValue(fullName) + ", "
				+ db.getInsertDBValue(smsPref) + ", "
				+ db.getInsertDBValue(transportorID) + ", "
				+ db.getInsertDBValue(position) + ", "
				+ db.getInsertDBValue(qualification) + ", "
				+ db.getInsertDate(idExpiryDate) + ", "
				+ db.getInsertDBValue(addressID) + ", "
				+ db.getInsertDBValue(contactID) + ", "
				+ db.getInsertDBValue(preferredLanguage) + ", "
				+ db.getInsertDBValue(reviewStatus) + ", "
				+ db.getInsertDBValue(employeeRole) + ", "
				+ db.getInsertDBValue(loginUser) + ", " + db.getInsertSysdate()
				+ ", " + db.getInsertDBValue(status) + ")";
		insList.add(insQry);

		insList = buildAvailablityQry(availability, reviewStatus, recordID,
				loginUser, insList);

		insList = buildUsersQry(recordID, contactBean.getMobile(),
				contactBean.getMobile(), loginUser, entityID, insList);

		boolean result = db.batchInsert(insList);

		return result;
	}

	public List<String> buildUsersQry(String employeeID, String userName,
			String password, String loginUser, String entityID,
			List<String> insList) throws Exception {

		if (userName.length() > 0 && password.length() > 0) {
			String autoIncrementArray[] = db
					.getAutoIncrementArray("ENTITYUSERSID");
			String insQry = "INSERT INTO ENTITYUSERS (";
			if (autoIncrementArray != null)
				insQry += autoIncrementArray[0];
			insQry += "ENTITYID, EMPLOYEEID, USERNAME, PASSWORD, "
					+ "CREATE_USER, CREATE_DATE, STATUS) VALUES (";
			if (autoIncrementArray != null)
				insQry += autoIncrementArray[1];
			insQry += entityID + ", " + db.getInsertDBValue(employeeID) + ", "
					+ db.getInsertDBValue(userName) + ", "
					+ db.getInsertDBValue(password) + ", "
					+ db.getInsertDBValue(loginUser) + ", "
					+ db.getInsertSysdate() + ", " + RecordStatus.ACTIVE + ")";
			insList.add(insQry);
		}

		return insList;
	}

	public List<String> buildAvailablityQry(String availability,
			String reviewStatus, String employeeID, String loginUser,
			List<String> insList) throws Exception {

		String selQry = "SELECT EMPLOYEE_AVAILABILITYID FROM "
				+ "EMPLOYEE_AVAILABILITY WHERE EMPLOYEEID=" + employeeID
				+ " AND STATUS=" + RecordStatus.ACTIVE;
		String recordID = db.selectById(selQry);
		if (recordID.length() == 0) {
			String autoIncrementArray[] = db
					.getAutoIncrementArray("EMPLOYEE_AVAILABILITYID");

			String insQry = "INSERT INTO EMPLOYEE_AVAILABILITY (";
			if (autoIncrementArray != null)
				insQry += autoIncrementArray[0];
			insQry += "EMPLOYEEID, AVAILABILITY, REVIEW_STATUS, "
					+ "CREATE_USER, CREATE_DATE, STATUS) VALUES (";
			if (autoIncrementArray != null)
				insQry += autoIncrementArray[1];
			insQry += employeeID + ", " + db.getInsertDBValue(availability)
					+ ", " + RecordStatus.ACTIVE + ", "
					+ db.getInsertDBValue(loginUser) + ", "
					+ db.getInsertSysdate() + ", " + RecordStatus.ACTIVE + ")";
			insList.add(insQry);

		} else {
			String upQry = "UPDATE EMPLOYEE_AVAILABILITY SET AVAILABILITY="
					+ db.getInsertDBValue(availability) + ", UPDATE_USER="
					+ db.getInsertDBValue(loginUser) + ", UPDATE_DATE="
					+ db.getInsertSysdate() + ", REVIEW_STATUS="
					+ db.getInsertDBValue(RecordStatus.ACTIVE)
					+ " WHERE EMPLOYEE_AVAILABILITYID=" + recordID;
			insList.add(upQry);
		}

		return insList;
	}

	@Override
	public Object[] updateRecord(MainBean mainBean, String loginUser,
			String loginUserRoles, String loginUserID, String entityID)
			throws Exception {

		bean = (AdminEmployee) mainBean;
		ErrorBean errorType = new ErrorBean();
		List<String> upList = new ArrayList<String>();

		String recordID = "";
		String addressID = bean.getAddressID();
		String contactID = bean.getContactID();
		Contact contactBean = bean.getContactBean();

		String condQry = db.getDataInCondQuery(bean.getFirstName(),
				"A.FIRSTNAME");

		condQry += db.getDataInCondQuery(bean.getLastName(), "A.LASTNAME");

		condQry += db.getDataInCondQuery(contactBean.getMobile(), "B.MOBILE");

		String selQry = "SELECT A.EMPLOYEEID FROM EMPLOYEE A LEFT JOIN CONTACT B "
				+ "ON A.CONTACTID=B.CONTACTID WHERE A.STATUS IN ("
				+ RecordStatus.ACTIVE + ") AND A.ENTITYID=" + entityID
				+ " AND A.EMPLOYEEID!=" + bean.getAdminEmployeeID() + condQry;

		List resultList = db.selectAsList(selQry, 1);
		if (resultList.size() > 0) {
			List tempList = (ArrayList) resultList.get(0);
			recordID = tempList.get(0) == null ? ""
					: tempList.get(0).toString().trim();
		}

		if (recordID.length() == 0) {
			recordID = bean.getAdminEmployeeID();
			if (addressID.length() == 0) {
				addressID = db.getNextIDValue("ADDRESSID");
				upList = buildAddressQry(true, addressID, bean.getAddressBean(),
						loginUser, upList);
			} else {
				upList = buildAddressQry(false, addressID,
						bean.getAddressBean(), loginUser, upList);

			}

			if (contactID.length() == 0) {
				contactID = db.getNextIDValue("CONTACTID");
				upList = buildContactQry(true, contactID, contactBean,
						loginUser, upList);
			} else {
				upList = buildContactQry(false, contactID, contactBean,
						loginUser, upList);

			}

			int status = bean.getStatus().length() == 0 ? RecordStatus.ACTIVE
					: Integer.parseInt(bean.getStatus());

			String upQry = "UPDATE EMPLOYEE SET FIRSTNAME="
					+ db.getInsertDBValue(bean.getFirstName()) + ", LASTNAME="
					+ db.getInsertDBValue(bean.getLastName()) + ", FULLNAME="
					+ db.getInsertDBValue(bean.getFullName()) + ", SMS_PREF="
					+ db.getInsertDBValue(bean.getSmsPref())
					+ ", TRANSPORTERID="
					+ db.getInsertDBValue(bean.getTransporterID())
					+ ", POSITION=" + db.getInsertDBValue(bean.getPosition())
					+ ", QUALIFICATION="
					+ db.getInsertDBValue(bean.getQualification())
					+ ", IDEXPIRY=" + db.getInsertDate(bean.getIdExpiryDate())
					+ ", ADDRESSID=" + db.getInsertDBValue(addressID)
					+ ", CONTACTID=" + db.getInsertDBValue(contactID)
					+ ", PREFERRED_LANGUAGE="
					+ db.getInsertDBValue(bean.getPreferredLanguage())
					+ ", REVIEW_STATUS="
					+ db.getInsertDBValue(bean.getReviewStatus()) + ", ROLE="
					+ db.getInsertDBValue(bean.getEmployeeRole())
					+ ", UPDATE_USER=" + db.getInsertDBValue(loginUser)
					+ ", UPDATE_DATE=" + db.getInsertSysdate() + ", STATUS="
					+ db.getInsertDBValue(status) + " WHERE EMPLOYEEID="
					+ recordID;
			upList.add(upQry);

			upList = buildAvailablityQry(bean.getAvailability(),
					bean.getReviewStatus(), recordID, loginUser, upList);

			boolean result = db.batchInsert(upList);

			errorType = getErrorType(result, SubmitType.UPDATE,
					bean.getDisplayName());
		} else {
			errorType = getErrorType(false, SubmitType.DUPLICATE,
					bean.getDisplayName());
		}

		return new Object[] { recordID, errorType };
	}

	@Override
	public Object[] deleteRecord(MainBean mainBean, String loginUser,
			String loginUserRoles, String loginUserID, String entityID)
			throws Exception {

		bean = (AdminEmployee) mainBean;
		ErrorBean errorType = new ErrorBean();
		List<String> upList = new ArrayList<String>();

		String recordID = bean.getAdminEmployeeID();
		upList.add(buildStatusQry("EMPLOYEE", "EMPLOYEEID", recordID,
				RecordStatus.DELETE, loginUser));

		boolean result = db.batchInsert(upList);

		errorType = getErrorType(result, SubmitType.DELETE,
				bean.getDisplayName());

		return new Object[] { recordID, errorType };
	}

	@Override
	public Object[] finalRecord(MainBean mainBean, String loginUser,
			String loginUserRoles, String loginUserID, String entityID)
			throws Exception {

		bean = (AdminEmployee) mainBean;
		ErrorBean errorType = new ErrorBean();
		List<String> upList = new ArrayList<String>();

		String recordID = bean.getAdminEmployeeID();
		upList.add(buildStatusQry("EMPLOYEE", "EMPLOYEEID", recordID,
				RecordStatus.POST, loginUser));

		boolean result = db.batchInsert(upList);

		errorType = getErrorType(result, SubmitType.FINAL,
				bean.getDisplayName());

		return new Object[] { recordID, errorType };
	}

	@Override
	public AdminEmployee fetchRecord(String recordID, String loginUser,
			String loginUserRoles, String loginUserID, String entityID,
			int submitType) throws Exception {

		String selQry = "SELECT EMPLOYEEID, ENTITYID, FIRSTNAME, "
				+ "LASTNAME, FULLNAME, TRANSPORTERID, POSITION, QUALIFICATION, "
				+ db.getSelectDate("IDEXPIRY")
				+ ", SMS_PREF, ADDRESSID, CONTACTID, REVIEW_STATUS, "
				+ "'', ROLE, PREFERRED_LANGUAGE, CREATE_USER, "
				+ db.getSelectDateTime("CREATE_DATE") + ", UPDATE_USER, "
				+ db.getSelectDateTime("UPDATE_DATE")
				+ ", STATUS FROM EMPLOYEE WHERE EMPLOYEEID=" + recordID;

		List resultList = new ArrayList();
		if (recordID.length() > 0)
			resultList = db.selectAsList(selQry,
					bean.getBeanAttributes().size() - 4);

		bean = (AdminEmployee) setListValuesToBean(bean,
				bean.getBeanAttributes(), resultList);

		bean.setEmployeeRoleName(getRoleName(bean.getEmployeeRole()));

		bean.setAddressBean(fetchAddress(bean.getAddressID()));

		bean.setContactBean(fetchContact(bean.getContactID()));

		if (bean.getAdminEmployeeID().length() > 0) {
			selQry = "SELECT AVAILABILITY FROM "
					+ "EMPLOYEE_AVAILABILITY WHERE EMPLOYEEID=" + recordID
					+ " AND STATUS=" + RecordStatus.ACTIVE;

			bean.setAvailability(db.selectById(selQry));
		}

		bean.setPreferredLanguageOptions(getPropertyValue(
				AdminConfiguration.enumCategorys.GENERAL.toString(),
				AdminConfiguration.enumGeneral.PREFERRED_LANGUAGE.toString(),
				entityID));

		return bean;
	}

	public Address fetchAddress(String recordID) throws Exception {

		Address addressBean = new Address();
		if (recordID.length() > 0) {
			String selQry = "SELECT ADDRESSID, STREET1, STREET2, "
					+ "CITY, STATE, ZIP, COUNTRY, CREATE_USER, "
					+ db.getSelectDateTime("CREATE_DATE") + ", UPDATE_USER, "
					+ db.getSelectDateTime("UPDATE_DATE")
					+ ", STATUS FROM ADDRESS WHERE ADDRESSID=" + recordID;
			List resultList = db.selectAsList(selQry,
					addressBean.getBeanAttributes().size());

			addressBean = (Address) setListValuesToBean(addressBean,
					addressBean.getBeanAttributes(), resultList);

		}

		return addressBean;
	}

	public Contact fetchContact(String recordID) throws Exception {

		Contact contactBean = new Contact();
		if (recordID.length() > 0) {
			String selQry = "SELECT CONTACTID, PHONE, WORKPHONE, "
					+ "MOBILE, FAX, EMAIL, CREATE_USER, "
					+ db.getSelectDateTime("CREATE_DATE") + ", UPDATE_USER, "
					+ db.getSelectDateTime("UPDATE_DATE")
					+ ", STATUS FROM CONTACT WHERE CONTACTID=" + recordID;
			List resultList = db.selectAsList(selQry,
					contactBean.getBeanAttributes().size());

			contactBean = (Contact) setListValuesToBean(contactBean,
					contactBean.getBeanAttributes(), resultList);

		}

		return contactBean;
	}

	public List<String> buildAddressQry(boolean isNew, String recordID,
			Address bean, String loginUser, List<String> insList) {

		if (isNew) {
			String insQry = "INSERT INTO ADDRESS (ADDRESSID, STREET1, "
					+ "STREET2, CITY, STATE, ZIP, COUNTRY, "
					+ "CREATE_USER, CREATE_DATE, STATUS) VALUES (" + recordID
					+ ", " + db.getInsertDBValue(bean.getAddressLine1()) + ", "
					+ db.getInsertDBValue(bean.getAddressLine2()) + ", "
					+ db.getInsertDBValue(bean.getCity()) + ", "
					+ db.getInsertDBValue(bean.getState()) + ", "
					+ db.getInsertDBValue(bean.getZip()) + ", "
					+ db.getInsertDBValue(bean.getCountry()) + ", "
					+ db.getInsertDBValue(loginUser) + ", "
					+ db.getInsertSysdate() + ", "
					+ db.getInsertDBValue(RecordStatus.ACTIVE) + ")";
			insList.add(insQry);
		} else {
			String upQry = "UPDATE ADDRESS SET STREET1="
					+ db.getInsertDBValue(bean.getAddressLine1()) + ", STREET2="
					+ db.getInsertDBValue(bean.getAddressLine2()) + ", CITY="
					+ db.getInsertDBValue(bean.getCity()) + ", STATE="
					+ db.getInsertDBValue(bean.getState()) + ", ZIP="
					+ db.getInsertDBValue(bean.getZip()) + ", COUNTRY="
					+ db.getInsertDBValue(bean.getCountry()) + ", UPDATE_USER="
					+ db.getInsertDBValue(loginUser) + ", UPDATE_DATE="
					+ db.getInsertSysdate() + ", STATUS="
					+ db.getInsertDBValue(RecordStatus.ACTIVE)
					+ " WHERE ADDRESSID=" + recordID;
			insList.add(upQry);
		}

		return insList;
	}

	public List<String> buildContactQry(boolean isNew, String recordID,
			Contact bean, String loginUser, List<String> insList) {

		if (isNew) {
			String insQry = "INSERT INTO CONTACT (CONTACTID, PHONE, "
					+ "WORKPHONE, MOBILE, FAX, EMAIL, "
					+ "CREATE_USER, CREATE_DATE, STATUS) VALUES (" + recordID
					+ ", " + db.getInsertDBValue(bean.getPhone()) + ", "
					+ db.getInsertDBValue(bean.getWorkPhone()) + ", "
					+ db.getInsertDBValue(bean.getMobile()) + ", "
					+ db.getInsertDBValue(bean.getFax()) + ", "
					+ db.getInsertDBValue(bean.getEmail()) + ", "
					+ db.getInsertDBValue(loginUser) + ", "
					+ db.getInsertSysdate() + ", "
					+ db.getInsertDBValue(RecordStatus.ACTIVE) + ")";
			insList.add(insQry);
		} else {
			String upQry = "UPDATE CONTACT SET PHONE="
					+ db.getInsertDBValue(bean.getPhone()) + ", WORKPHONE="
					+ db.getInsertDBValue(bean.getWorkPhone()) + ", MOBILE="
					+ db.getInsertDBValue(bean.getMobile()) + ", FAX="
					+ db.getInsertDBValue(bean.getFax()) + ", EMAIL="
					+ db.getInsertDBValue(bean.getEmail()) + ", UPDATE_USER="
					+ db.getInsertDBValue(loginUser) + ", UPDATE_DATE="
					+ db.getInsertSysdate() + ", STATUS="
					+ db.getInsertDBValue(RecordStatus.ACTIVE)
					+ " WHERE CONTACTID=" + recordID;
			insList.add(upQry);
		}

		return insList;
	}

	@Override
	public double updateFromFile(List<String> columnsList, List dataList,
			String loginUser, String entityID, Map<String, String> _reqMap) {

		double numOfRows = 0;
		for (int i = 0; i < dataList.size(); i++) {
			List tempList = (ArrayList) dataList.get(i);
			String fullName = getListDBData(tempList, 0);
			String transportorID = getListDBData(tempList, 1);
			String position = getListDBData(tempList, 2);
			String qualification = getListDBData(tempList, 3);
			String idExpiryDate = getListDBData(tempList, 4);
			String mobile = getListDBData(tempList, 5);
			String workPhone = getListDBData(tempList, 6);
			String eMail = getListDBData(tempList, 7);
			String reviewStatus = getListDBData(tempList, 8);
			String smsPref = "1";
			String availability = "";
			String employeeRole = "4";

			if ("INACTIVE".equalsIgnoreCase(reviewStatus)) {
				reviewStatus = RecordStatus.INACTIVE + "";
			} else {
				reviewStatus = RecordStatus.ACTIVE + "";
			}

			mobile = mobile.startsWith("+1")
					? mobile.substring(2, mobile.length())
					: mobile;

			workPhone = workPhone.startsWith("+1")
					? workPhone.substring(2, workPhone.length())
					: workPhone;

			try {
				idExpiryDate = getFileDate(idExpiryDate);
				String dataArray[] = checkRecordExist("", mobile, "", entityID);
				String recordID = dataArray[0];
				String contactID = dataArray[1];
				if (recordID.length() == 0) {
					if (eMail.length() > 0) {
						dataArray = checkRecordExist("", "", eMail, entityID);
						recordID = dataArray[0];
						contactID = dataArray[1];
					}
				}

				if (recordID.length() == 0) {
					recordID = db.getNextIDValue("EMPLOYEEID");
					Address addressBean = new Address();

					Contact contactBean = new Contact();
					contactBean.setMobile(mobile);
					contactBean.setWorkPhone(workPhone);
					contactBean.setEmail(eMail);
					String preferredLanguage = "English";

					boolean result = createEmployee(recordID, entityID, "", "",
							fullName, smsPref, transportorID, position,
							qualification, idExpiryDate, reviewStatus,
							employeeRole, preferredLanguage, availability,
							addressBean, contactBean, RecordStatus.ACTIVE,
							loginUser);
					if (result)
						numOfRows++;

				} else {
					// Update existing Data
					List<String> upList = new ArrayList<String>();
					String upQry = "UPDATE EMPLOYEE SET FULLNAME="
							+ db.getInsertDBValue(fullName) + ", SMS_PREF="
							+ db.getInsertDBValue(smsPref) + ", TRANSPORTERID="
							+ db.getInsertDBValue(transportorID) + ", POSITION="
							+ db.getInsertDBValue(position) + ", QUALIFICATION="
							+ db.getInsertDBValue(qualification) + ", IDEXPIRY="
							+ db.getInsertDate(idExpiryDate)
							+ ", REVIEW_STATUS="
							+ db.getInsertDBValue(reviewStatus)
							+ ", UPDATE_USER=" + db.getInsertDBValue(loginUser)
							+ ", UPDATE_DATE=" + db.getInsertSysdate()
							+ ", STATUS="
							+ db.getInsertDBValue(RecordStatus.ACTIVE)
							+ " WHERE EMPLOYEEID=" + recordID;
					upList.add(upQry);

					if (contactID.length() > 0) {
						Contact contactBean = new Contact();
						contactBean.setMobile(mobile);
						contactBean.setWorkPhone(workPhone);
						contactBean.setEmail(eMail);

						upList = buildContactQry(false, contactID, contactBean,
								loginUser, upList);
					}

					boolean result = db.batchInsert(upList);
					if (result)
						numOfRows++;
				}

			} catch (Exception ex) {
				ex.printStackTrace();
			}
		}

		return numOfRows;
	}

	/* ── single-page employee actions (toggle / drawers) ───────── */

	private String jsE(String s) {
		if (s == null) return "\"\"";
		StringBuilder b = new StringBuilder("\"");
		for (int i = 0; i < s.length(); i++) {
			char c = s.charAt(i);
			if (c == '"') b.append("\\\"");
			else if (c == '\\') b.append("\\\\");
			else if (c == '\n' || c == '\r') b.append("\\n");
			else if (c == '\t') b.append(' ');
			else if (c == '<') b.append("\\u003C");
			else if (c >= 32) b.append(c);
		}
		return b.append('"').toString();
	}

	private String dd(List row, int i) {
		if (row == null || i >= row.size() || row.get(i) == null) return "";
		return row.get(i).toString().trim();
	}

	private String rqE(Map<String, String> m, String k) {
		String v = m.get(k) == null ? "" : m.get(k).trim();
		return v.replace("''", "'");
	}

	private void empLog(String empID, String note, String loginUser,
			String entityID, List<String> upList) {
		upList.add("INSERT INTO employee_log (ENTITYID, EMPLOYEEID, NOTE, "
				+ "CREATE_USER, CREATE_DATE, STATUS) VALUES (" + entityID + ", "
				+ empID + ", " + db.getInsertDBValue(note) + ", "
				+ db.getInsertDBValue(loginUser) + ", " + db.getInsertSysdate()
				+ ", 0)");
	}

	@Override
	public String getAjaxRequestTypeResp(String requestType,
			Map<String, String> requestMap, String loginUser,
			String loginUserRoles, String loginUserID, String entityID)
			throws Exception {

		String empID = requestMap.get("employeeID") == null ? ""
				: requestMap.get("employeeID").trim();
		boolean hasEmp = empID.matches("\\d+");
		List<String> upList = new ArrayList<String>();

		if ("empToggle".equalsIgnoreCase(requestType)) {
			String on = requestMap.get("on") == null ? "" : requestMap.get("on").trim();
			if (!hasEmp || !on.matches("[01]"))
				return "<status>false</status><mesg>Bad request</mesg>";
			int st = "1".equals(on) ? RecordStatus.ACTIVE : RecordStatus.INACTIVE;
			upList.add("UPDATE EMPLOYEE SET REVIEW_STATUS=" + st + ", UPDATE_USER="
					+ db.getInsertDBValue(loginUser) + ", UPDATE_DATE="
					+ db.getInsertSysdate() + " WHERE EMPLOYEEID=" + empID
					+ " AND ENTITYID=" + entityID);
			empLog(empID, "Marked " + ("1".equals(on) ? "ACTIVE" : "INACTIVE"),
					loginUser, entityID, upList);
			boolean ok = db.batchInsert(upList);
			return ok ? "<status>true</status><mesg>Employee marked "
					+ ("1".equals(on) ? "active" : "inactive") + "</mesg>"
					: "<status>false</status><mesg>Update failed</mesg>";
		}

		if ("empGet".equalsIgnoreCase(requestType)) {
			if (!hasEmp) return "<status>false</status><mesg>Bad request</mesg>";
			List r = db.selectAsList("SELECT IFNULL(A.FIRSTNAME,''), IFNULL(A.LASTNAME,''), IFNULL(B.MOBILE,''), "
					+ "IFNULL(A.PREFERRED_LANGUAGE,''), IFNULL(A.SMS_PREF,''), "
					+ "IFNULL(DATE_FORMAT(A.IDEXPIRY,'%m/%d/%Y'),''), IFNULL(A.ROLE,''), "
					+ "IFNULL(A.STATION,''), IFNULL(A.TRANSPORTERID,''), IFNULL(A.POSITION,''), "
					+ "IFNULL(A.FULLNAME,'') "
					+ "FROM EMPLOYEE A LEFT JOIN CONTACT B ON A.CONTACTID=B.CONTACTID "
					+ "WHERE A.EMPLOYEEID=" + empID, 11);
			if (r.isEmpty()) return "<status>false</status><mesg>Not found</mesg>";
			List t = (List) r.get(0);
			String avail = db.selectById("SELECT MAX(AVAILABILITY) FROM EMPLOYEE_AVAILABILITY "
					+ "WHERE EMPLOYEEID=" + empID + " AND STATUS=" + RecordStatus.ACTIVE);
			String[] k = { "fn", "ln", "mobile", "lang", "sms", "exp", "role",
					"station", "tid", "posn" };
			StringBuilder o = new StringBuilder("{");
			for (int i = 0; i < k.length; i++)
				o.append(i > 0 ? "," : "").append("\"").append(k[i]).append("\":")
						.append(jsE(dd(t, i)));
			o.append(",\"avail\":").append(jsE(avail == null ? "" : avail));
			o.append(",\"nm\":").append(jsE(dd(t, 10)));
			return o.append("}").toString();
		}

		if ("empSave".equalsIgnoreCase(requestType)) {
			if (!hasEmp) return "<status>false</status><mesg>Bad request</mesg>";
			String mobile = rqE(requestMap, "mobile").replaceAll("[^0-9]", "");
			if (mobile.length() != 10)
				return "<status>false</status><mesg>Mobile must be 10 digits</mesg>";
			String dup = db.selectById("SELECT MAX(A.EMPLOYEEID) FROM EMPLOYEE A "
					+ "JOIN CONTACT B ON A.CONTACTID=B.CONTACTID WHERE A.STATUS!=1 "
					+ "AND A.REVIEW_STATUS=" + RecordStatus.ACTIVE
					+ " AND A.EMPLOYEEID!=" + empID
					+ " AND REPLACE(REPLACE(REPLACE(IFNULL(B.MOBILE,''),'-',''),' ',''),'.','')='"
					+ mobile + "'");
			if (dup != null && dup.matches("\\d+"))
				return "<status>false</status><mesg>Another active employee already "
						+ "uses that mobile number</mesg>";
			String oldMobile = db.selectById("SELECT MAX(IFNULL(B.MOBILE,'')) FROM EMPLOYEE A "
					+ "JOIN CONTACT B ON A.CONTACTID=B.CONTACTID WHERE A.EMPLOYEEID=" + empID);
			if (oldMobile == null) oldMobile = "";

			String fn = rqE(requestMap, "fn"), ln = rqE(requestMap, "ln");
			/* many rows carry only FULLNAME: don't blank the name when the
			   first/last inputs come back empty */
			String nameSet = (fn + ln).trim().length() > 0
					? "FIRSTNAME=" + db.getInsertDBValue(fn)
							+ ", LASTNAME=" + db.getInsertDBValue(ln)
							+ ", FULLNAME=" + db.getInsertDBValue((fn + " " + ln).trim()) + ", "
					: "";
			upList.add("UPDATE EMPLOYEE SET " + nameSet
					+ "PREFERRED_LANGUAGE=" + db.getInsertDBValue(rqE(requestMap, "lang"))
					+ ", SMS_PREF=" + ("Opt-in".equalsIgnoreCase(rqE(requestMap, "sms")) ? "1" : "0")
					+ ", IDEXPIRY=" + db.getInsertDate(rqE(requestMap, "exp"))
					+ ", ROLE=" + db.getInsertDBValue(rqE(requestMap, "role"))
					+ ", STATION=" + db.getInsertDBValue(rqE(requestMap, "station"))
					+ ", UPDATE_USER=" + db.getInsertDBValue(loginUser)
					+ ", UPDATE_DATE=" + db.getInsertSysdate()
					+ " WHERE EMPLOYEEID=" + empID + " AND ENTITYID=" + entityID);
			upList.add("UPDATE CONTACT B JOIN EMPLOYEE A ON A.CONTACTID=B.CONTACTID "
					+ "SET B.MOBILE='" + mobile + "', B.UPDATE_USER="
					+ db.getInsertDBValue(loginUser) + ", B.UPDATE_DATE="
					+ db.getInsertSysdate() + " WHERE A.EMPLOYEEID=" + empID);
			String oldClean = oldMobile.replaceAll("[^0-9]", "");
			if (!oldClean.equals(mobile))
				empLog(empID, "Mobile changed " + oldMobile + " -> " + mobile,
						loginUser, entityID, upList);
			/* availability: replace the active row */
			String avail = rqE(requestMap, "avail");
			upList.add("UPDATE EMPLOYEE_AVAILABILITY SET STATUS=1 WHERE EMPLOYEEID="
					+ empID + " AND STATUS=" + RecordStatus.ACTIVE);
			if (avail.length() > 0)
				upList.add("INSERT INTO EMPLOYEE_AVAILABILITY (EMPLOYEEID, AVAILABILITY, "
						+ "CREATE_USER, CREATE_DATE, STATUS) VALUES (" + empID + ", "
						+ db.getInsertDBValue(avail) + ", "
						+ db.getInsertDBValue(loginUser) + ", " + db.getInsertSysdate()
						+ ", 0)");
			boolean ok = db.batchInsert(upList);
			return ok ? "<status>true</status><mesg>Employee saved</mesg>"
					: "<status>false</status><mesg>Save failed</mesg>";
		}

		if ("empIncidents".equalsIgnoreCase(requestType)) {
			if (!hasEmp) return "<status>false</status><mesg>Bad request</mesg>";
			StringBuilder o = new StringBuilder("{\"types\":[");
			List r = db.selectAsList("SELECT INCIDENTTYPEID, TYPE FROM incidenttype "
					+ "WHERE STATUS!=1 ORDER BY TYPE", 2);
			for (int i = 0; i < r.size(); i++) {
				List t = (List) r.get(i);
				o.append(i > 0 ? "," : "").append("{\"id\":").append(dd(t, 0))
						.append(",\"n\":").append(jsE(dd(t, 1))).append("}");
			}
			o.append("],\"rows\":[");
			r = db.selectAsList("SELECT DATE_FORMAT(I.INCIDENT_DATE,'%m/%d/%Y'), "
					+ "IFNULL(T.TYPE,''), IFNULL(I.DESCRIPTION,''), I.STATUS "
					+ "FROM incidents I LEFT JOIN incidenttype T ON I.INCIDENTTYPEID=T.INCIDENTTYPEID "
					+ "WHERE I.STATUS!=1 AND I.EMPLOYEEID=" + empID
					+ " ORDER BY I.INCIDENT_DATE DESC, I.INCIDENTSID DESC LIMIT 60", 4);
			for (int i = 0; i < r.size(); i++) {
				List t = (List) r.get(i);
				o.append(i > 0 ? "," : "").append("{\"d\":").append(jsE(dd(t, 0)))
						.append(",\"ty\":").append(jsE(dd(t, 1)))
						.append(",\"m\":").append(jsE(dd(t, 2)))
						.append(",\"posted\":").append("2".equals(dd(t, 3)) ? "1" : "0")
						.append("}");
			}
			return o.append("]}").toString();
		}

		if ("empIncidentAdd".equalsIgnoreCase(requestType)) {
			String typeID = requestMap.get("typeID") == null ? "" : requestMap.get("typeID").trim();
			String dt = rqE(requestMap, "idate");
			String desc = rqE(requestMap, "descr");
			if (!hasEmp || !typeID.matches("\\d+") || dt.length() == 0)
				return "<status>false</status><mesg>Type and date are required</mesg>";
			boolean ok = db.update("INSERT INTO incidents (ENTITYID, EMPLOYEEID, "
					+ "INCIDENTTYPEID, DESCRIPTION, INCIDENT_DATE, CREATE_USER, "
					+ "CREATE_DATE, STATUS) VALUES (" + entityID + ", " + empID + ", "
					+ typeID + ", " + db.getInsertDBValue(desc) + ", "
					+ db.getInsertDate(dt) + ", " + db.getInsertDBValue(loginUser)
					+ ", " + db.getInsertSysdate() + ", " + RecordStatus.ACTIVE + ")");
			return ok ? "<status>true</status><mesg>Incident saved</mesg>"
					: "<status>false</status><mesg>Save failed</mesg>";
		}

		if ("empOshaAdd".equalsIgnoreCase(requestType)) {
			String dt = rqE(requestMap, "idate");
			String ty = rqE(requestMap, "itype");
			if (!hasEmp || dt.length() == 0 || ty.length() == 0)
				return "<status>false</status><mesg>Date and type are required</mesg>";

			/* incident/reported datetimes: MM/DD/YYYY date + optional HH:MM */
			String itime = rqE(requestMap, "itime");
			String incDT = itime.matches("\\d{2}:\\d{2}")
					? "STR_TO_DATE('" + dt + " " + itime + "', '%m/%d/%Y %H:%i')"
					: "NULL";
			String repDate = rqE(requestMap, "irepdate");
			String repTime = rqE(requestMap, "ireptime");
			String repDT = "NULL";
			if (repDate.length() > 0)
				repDT = "STR_TO_DATE('" + repDate + " "
						+ (repTime.matches("\\d{2}:\\d{2}") ? repTime : "00:00")
						+ "', '%m/%d/%Y %H:%i')";

			boolean ok = db.update("INSERT INTO employeeincident (ENTITYID, EMPLOYEEID, "
					+ "INCIDENTDATE, INCIDENTTIME, REPORTEDTIME, TYPEOFINCIDENT, "
					+ "INCIDENTLOCATION, INCIDENTDESCRIPTION, EMTNUMBER, "
					+ "CREATE_USER, CREATE_DATE, STATUS) VALUES (" + entityID + ", "
					+ empID + ", " + db.getInsertDate(dt) + ", " + incDT + ", " + repDT
					+ ", " + db.getInsertDBValue(ty)
					+ ", " + db.getInsertDBValue(rqE(requestMap, "iloc")) + ", "
					+ db.getInsertDBValue(rqE(requestMap, "descr")) + ", "
					+ db.getInsertDBValue(rqE(requestMap, "iemt")) + ", "
					+ db.getInsertDBValue(loginUser) + ", " + db.getInsertSysdate()
					+ ", " + RecordStatus.ACTIVE + ")");
			return ok ? "<status>true</status><mesg>OSHA incident saved</mesg>"
					: "<status>false</status><mesg>Save failed</mesg>";
		}

		if ("empTerminate".equalsIgnoreCase(requestType)) {
			String dt = rqE(requestMap, "tdate");
			String ty = rqE(requestMap, "ttype");
			String rsn = rqE(requestMap, "treason");
			if (!hasEmp || dt.length() == 0 || ty.length() == 0 || rsn.length() == 0)
				return "<status>false</status><mesg>Date, type and reason are required</mesg>";
			upList.add("INSERT INTO employeetermination (ENTITYID, EMPLOYEEID, "
					+ "DATEOFTERMINATION, TERMINATIONTYPE, TERMINATIONREASON, COMMENTS, "
					+ "CREATE_USER, CREATE_DATE, STATUS) VALUES (" + entityID + ", "
					+ empID + ", " + db.getInsertDate(dt) + ", " + db.getInsertDBValue(ty)
					+ ", " + db.getInsertDBValue(rsn) + ", "
					+ db.getInsertDBValue(rqE(requestMap, "tcomments")) + ", "
					+ db.getInsertDBValue(loginUser) + ", " + db.getInsertSysdate()
					+ ", " + RecordStatus.ACTIVE + ")");
			upList.add("UPDATE EMPLOYEE SET REVIEW_STATUS=" + RecordStatus.INACTIVE
					+ ", UPDATE_USER=" + db.getInsertDBValue(loginUser)
					+ ", UPDATE_DATE=" + db.getInsertSysdate()
					+ " WHERE EMPLOYEEID=" + empID + " AND ENTITYID=" + entityID);
			empLog(empID, "TERMINATED " + dt + " - " + ty + " - " + rsn, loginUser,
					entityID, upList);
			boolean ok = db.batchInsert(upList);
			return ok ? "<status>true</status><mesg>Termination recorded</mesg>"
					: "<status>false</status><mesg>Save failed</mesg>";
		}

		if ("empHistory".equalsIgnoreCase(requestType)) {
			if (!hasEmp) return "<status>false</status><mesg>Bad request</mesg>";
			StringBuilder o = new StringBuilder("{\"term\":[");
			List r = db.selectAsList("SELECT DATE_FORMAT(DATEOFTERMINATION,'%m/%d/%Y'), "
					+ "IFNULL(TERMINATIONTYPE,''), IFNULL(TERMINATIONREASON,''), "
					+ "IFNULL(COMMENTS,''), IFNULL(CREATE_USER,'') FROM employeetermination "
					+ "WHERE STATUS!=1 AND EMPLOYEEID=" + empID
					+ " ORDER BY EMPLOYEETERMINATIONID DESC LIMIT 3", 5);
			for (int i = 0; i < r.size(); i++) {
				List t = (List) r.get(i);
				o.append(i > 0 ? "," : "").append("{\"d\":").append(jsE(dd(t, 0)))
						.append(",\"ty\":").append(jsE(dd(t, 1)))
						.append(",\"rsn\":").append(jsE(dd(t, 2)))
						.append(",\"cm\":").append(jsE(dd(t, 3)))
						.append(",\"u\":").append(jsE(dd(t, 4))).append("}");
			}
			o.append("],\"inc\":[");
			r = db.selectAsList("SELECT DATE_FORMAT(I.INCIDENT_DATE,'%m/%d/%Y'), "
					+ "IFNULL(T.TYPE,''), IFNULL(I.DESCRIPTION,''), I.STATUS "
					+ "FROM incidents I LEFT JOIN incidenttype T ON I.INCIDENTTYPEID=T.INCIDENTTYPEID "
					+ "WHERE I.STATUS!=1 AND I.EMPLOYEEID=" + empID
					+ " ORDER BY I.INCIDENT_DATE DESC LIMIT 25", 4);
			for (int i = 0; i < r.size(); i++) {
				List t = (List) r.get(i);
				o.append(i > 0 ? "," : "").append("{\"d\":").append(jsE(dd(t, 0)))
						.append(",\"ty\":").append(jsE(dd(t, 1)))
						.append(",\"m\":").append(jsE(dd(t, 2)))
						.append(",\"posted\":").append("2".equals(dd(t, 3)) ? "1" : "0")
						.append("}");
			}
			o.append("],\"osha\":[");
			r = db.selectAsList("SELECT DATE_FORMAT(INCIDENTDATE,'%m/%d/%Y'), "
					+ "IFNULL(TYPEOFINCIDENT,''), IFNULL(INCIDENTLOCATION,''), "
					+ "IFNULL(INCIDENTDESCRIPTION,''), "
					+ "IFNULL(TIME_FORMAT(INCIDENTTIME,'%l:%i %p'),''), "
					+ "IFNULL(DATE_FORMAT(REPORTEDTIME,'%m/%d %l:%i %p'),''), "
					+ "IFNULL(EMTNUMBER,'') FROM employeeincident "
					+ "WHERE STATUS!=1 AND EMPLOYEEID=" + empID
					+ " ORDER BY INCIDENTDATE DESC LIMIT 15", 7);
			for (int i = 0; i < r.size(); i++) {
				List t = (List) r.get(i);
				o.append(i > 0 ? "," : "").append("{\"d\":").append(jsE(dd(t, 0)))
						.append(",\"ty\":").append(jsE(dd(t, 1)))
						.append(",\"loc\":").append(jsE(dd(t, 2)))
						.append(",\"m\":").append(jsE(dd(t, 3)))
						.append(",\"tm\":").append(jsE(dd(t, 4)))
						.append(",\"rep\":").append(jsE(dd(t, 5)))
						.append(",\"emt\":").append(jsE(dd(t, 6))).append("}");
			}
			/* schedule: availability + recent weeks worked + last checkin */
			String avail = db.selectById("SELECT MAX(AVAILABILITY) FROM EMPLOYEE_AVAILABILITY "
					+ "WHERE EMPLOYEEID=" + empID + " AND STATUS=" + RecordStatus.ACTIVE);
			o.append("],\"sched\":{\"avail\":").append(jsE(avail == null ? "" : avail));
			o.append(",\"weeks\":[");
			r = db.selectAsList("SELECT YEAR(CLOCKINTIME), "
					+ "(WEEK(CLOCKINTIME,0) + (DAYOFWEEK(MAKEDATE(YEAR(CLOCKINTIME),1))!=1)), "
					+ "COUNT(DISTINCT DATE(CLOCKINTIME)) FROM dacheckin WHERE STATUS!=1 "
					+ "AND EMPLOYEEID=" + empID
					+ " GROUP BY 1,2 ORDER BY 1 DESC,2 DESC LIMIT 4", 3);
			for (int i = 0; i < r.size(); i++) {
				List t = (List) r.get(i);
				o.append(i > 0 ? "," : "").append("{\"w\":").append(jsE(dd(t, 1)))
						.append(",\"days\":").append(jsE(dd(t, 2))).append("}");
			}
			String lastCk = db.selectById("SELECT DATE_FORMAT(MAX(CLOCKINTIME),'%m/%d/%Y') "
					+ "FROM dacheckin WHERE STATUS!=1 AND EMPLOYEEID=" + empID);
			o.append("],\"lastCk\":").append(jsE(lastCk == null ? "" : lastCk)).append("}");
			o.append(",\"log\":[");
			r = db.selectAsList("SELECT DATE_FORMAT(CREATE_DATE,'%m/%d/%Y'), "
					+ "IFNULL(CREATE_USER,''), IFNULL(NOTE,'') FROM employee_log "
					+ "WHERE STATUS!=1 AND EMPLOYEEID=" + empID
					+ " ORDER BY EMPLOYEE_LOGID DESC LIMIT 25", 3);
			for (int i = 0; i < r.size(); i++) {
				List t = (List) r.get(i);
				o.append(i > 0 ? "," : "").append("{\"d\":").append(jsE(dd(t, 0)))
						.append(",\"u\":").append(jsE(dd(t, 1)))
						.append(",\"m\":").append(jsE(dd(t, 2))).append("}");
			}
			o.append("],\"writeups\":[");
			r = db.selectAsList("SELECT IFNULL(T.FORMTYPE,''), COUNT(*) FROM employeeforms F "
					+ "JOIN formstemplate T ON F.FORMSTEMPLATEID=T.FORMSTEMPLATEID "
					+ "WHERE F.STATUS!=1 AND F.EMPLOYEEID=" + empID
					+ " GROUP BY 1 ORDER BY 2 DESC LIMIT 8", 2);
			for (int i = 0; i < r.size(); i++) {
				List t = (List) r.get(i);
				o.append(i > 0 ? "," : "").append("{\"n\":").append(jsE(dd(t, 0)))
						.append(",\"c\":").append(jsE(dd(t, 1))).append("}");
			}
			o.append("],\"daDocs\":[");
			try {
				String empEmail = db.selectById(
						"SELECT LOWER(TRIM(IFNULL(B.EMAIL,''))) FROM EMPLOYEE A "
								+ "LEFT JOIN CONTACT B ON A.CONTACTID=B.CONTACTID "
								+ "WHERE A.EMPLOYEEID=" + empID);
				String empFn = db.selectById(
						"SELECT LOWER(TRIM(IFNULL(FIRSTNAME,''))) FROM EMPLOYEE WHERE EMPLOYEEID=" + empID);
				String empLn = db.selectById(
						"SELECT LOWER(TRIM(IFNULL(LASTNAME,''))) FROM EMPLOYEE WHERE EMPLOYEEID=" + empID);
				if (empEmail == null) empEmail = "";
				if (empFn == null) empFn = "";
				if (empLn == null) empLn = "";
				empEmail = empEmail.replace("'", "''");
				empFn = empFn.replace("'", "''");
				empLn = empLn.replace("'", "''");
				String daCond = "";
				if (empEmail.length() > 0) {
					daCond = "LOWER(TRIM(IFNULL(a.email,'')))='" + empEmail + "'";
				}
				if (empFn.length() > 0 && empLn.length() > 0) {
					String nameCond = "LOWER(TRIM(IFNULL(a.first_name,'')))='" + empFn
							+ "' AND LOWER(TRIM(IFNULL(a.last_name,'')))='" + empLn + "'";
					daCond = daCond.length() > 0 ? "(" + daCond + " OR (" + nameCond + "))" : nameCond;
				}
				if (daCond.length() > 0) {
					r = db.selectAsList(
							"SELECT a.application_id, DATE_FORMAT(a.applied_ts,'%m/%d/%Y'), "
									+ "IFNULL(a.dl_file_path,''), IFNULL(a.ssn_file_path,''), "
									+ "IFNULL(a.wp_front_file_path,''), IFNULL(a.wp_back_file_path,''), "
									+ "IFNULL(a.offer_letter_file_path,''), IFNULL(a.offer_letter_signed,0), "
									+ "IFNULL(a.dl_drive_url,''), IFNULL(a.ssn_drive_url,''), "
									+ "IFNULL(a.wp_front_drive_url,''), IFNULL(a.wp_back_drive_url,''), "
									+ "IFNULL(a.offer_letter_drive_url,''), "
									+ "IFNULL((SELECT o.drug_test_doc_path FROM da_onboarding o "
									+ "WHERE o.application_id=a.application_id "
									+ "ORDER BY o.onboarding_id DESC LIMIT 1),''), "
									+ "IFNULL((SELECT o.offer_letter_doc_path FROM da_onboarding o "
									+ "WHERE o.application_id=a.application_id "
									+ "ORDER BY o.onboarding_id DESC LIMIT 1),'') "
									+ "FROM da_applications a WHERE " + daCond
									+ " ORDER BY a.application_id DESC LIMIT 5",
							15);
					for (int i = 0; i < r.size(); i++) {
						List t = (List) r.get(i);
						String appId = dd(t, 0);
						String offerLocal = dd(t, 6);
						String offerOb = dd(t, 14);
						if (offerLocal.length() == 0 && offerOb.length() > 0) offerLocal = offerOb;
						o.append(i > 0 ? "," : "").append("{\"id\":").append(jsE(appId))
								.append(",\"d\":").append(jsE(dd(t, 1)))
								.append(",\"signed\":").append(jsE(dd(t, 7)))
								.append(",\"docs\":[");
						String[][] docs = {
								{ "dl", "Driver's License", dd(t, 2), dd(t, 8) },
								{ "ssn", "SSN Card", dd(t, 3), dd(t, 9) },
								{ "wp_front", "Work Permit Front", dd(t, 4), dd(t, 10) },
								{ "wp_back", "Work Permit Back", dd(t, 5), dd(t, 11) },
								{ "drug_test", "Drug Test Result", dd(t, 13), "" },
								{ "offer_letter", "Offer Letter", offerLocal, dd(t, 12) }
						};
						for (int di = 0; di < docs.length; di++) {
							boolean has = (docs[di][2] != null && docs[di][2].length() > 0)
									|| (docs[di][3] != null && docs[di][3].length() > 0);
							o.append(di > 0 ? "," : "").append("{\"k\":").append(jsE(docs[di][0]))
									.append(",\"n\":").append(jsE(docs[di][1]))
									.append(",\"has\":").append(has ? "1" : "0").append("}");
						}
						o.append("]}");
					}
				}
			} catch (Exception ignoreDa) {
				/* table/columns may not exist on older DBs */
			}
			return o.append("]}").toString();
		}

		return super.getAjaxRequestTypeResp(requestType, requestMap, loginUser,
				loginUserRoles, loginUserID, entityID);
	}
}
