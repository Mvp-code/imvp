package com.dataobjects;

import java.util.ArrayList;
import java.util.Calendar;
import java.util.GregorianCalendar;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

import com.beans.AdminPhones;
import com.beans.DACheckin;
import com.beans.ErrorBean;
import com.beans.MainBean;
import com.beans.SearchBean;
import com.beans.VehicleInspection;
import com.util.RecordStatus;
import com.util.SubmitType;

public class DACheckinDAO extends MVPGDAO {

	DAStatusDAO daStatusDAO = new DAStatusDAO();
	DACheckin bean = new DACheckin();

	@Override
	public SearchBean searchRecords(SearchBean searchBean, String recordID,
			String loginUser, String loginUserRoles, String loginUserID,
			String entityID) throws Exception {

		String currentDate = db.getCurrentDate();
		String condQry = "";
		int submitType = SubmitType.SEARCH;
		if (searchBean.getSelectedType().length() > 0) {
			submitType = Integer.parseInt(searchBean.getSelectedType());
			if (submitType == SubmitType.UPDATE) {

				String requestType = searchBean.getSelectedValues();
				if ("NewRun".equalsIgnoreCase(requestType)
						|| "NewNext Day Run".equalsIgnoreCase(requestType)) {

					requestType = requestType.substring(3,
							requestType.length());
					updateNewRunRecords(requestType, RecordStatus.ACTIVE,
							loginUser, entityID);
					searchBean.setSelectedValues("");
					searchBean.setSelectedType("");
					submitType = SubmitType.SEARCH;

				} else if ("Run".equalsIgnoreCase(requestType)
						|| "Next Day Run".equalsIgnoreCase(requestType)) {

					updateRunRecords(requestType, RecordStatus.ACTIVE,
							loginUser, entityID);
					searchBean.setSelectedValues("");
					searchBean.setSelectedType("");
					submitType = SubmitType.SEARCH;

				} else {
					condQry += db.getIDInCondQuery(
							searchBean.getSelectedValues(), "A.DACHECKINID");
				}

			} else if (submitType == SubmitType.PRINT) {
				condQry += db.getIDInCondQuery(searchBean.getSelectedValues(),
						"A.DACHECKINID");

			} else if (submitType == SubmitType.UPDATE_CONFIRM) {
				boolean result = updateSwapRecords(searchBean.getTransList(),
						RecordStatus.ACTIVE, loginUser);
				searchBean.setErrorBean(getErrorType(result, submitType,
						bean.getDisplayName()));

				// Once Swap is done, display swap screen only
				String ids = getIndexedDataFromList(searchBean.getTransList(),
						0, ",");
				submitType = SubmitType.UPDATE;
				searchBean.setSelectedType(submitType + "");
				condQry += db.getIDInCondQuery(ids, "A.DACHECKINID");

			} else if (submitType == SubmitType.DELETE
					|| submitType == SubmitType.FINAL) {

				boolean result = false;
				if (submitType == SubmitType.FINAL) {
					result = postCheckIn(searchBean.getSelectedValues(),
							loginUser, entityID);

				} else {
					String upQry = buildStatusQry("DACHECKIN", "DACHECKINID",
							searchBean.getSelectedValues(), RecordStatus.DELETE,
							loginUser);
					result = db.update(upQry);
				}

				searchBean.setErrorBean(getErrorType(result, submitType,
						bean.getDisplayName()));

			}
		}

		List<String> labelsList = new ArrayList<String>();
		if (submitType == SubmitType.UPDATE) {
			labelsList.add("Clockin Time");
			labelsList.add("Employee");
			labelsList.add("Vehicle");
			labelsList.add("Service Tier");

			searchBean.setWidthColumns(new int[] { 11, 12, 12, 14 });

		} else if (submitType == SubmitType.PRINT) {
			labelsList.add("Wave Time");
			labelsList.add("Employee");
			labelsList.add("Vehicle");
			labelsList.add("Service Tier");
			labelsList.add("Parking");
			labelsList.add("Route");
			labelsList.add("Staging");
			labelsList.add("Status");

			searchBean.setWidthColumns(new int[] { 13, 24, 14, 19, 9, 7, 8, 6 });

			condQry += db.getIDNotInCondQuery("1", "B.ROLE");

			condQry += db.getDataNotLikeCondQuery("Extra-DA",
					"C.VEHICLENUMBER");

			condQry += db.getDataNotLikeCondQuery("Trainer", "C.VEHICLENUMBER");

			/* placeholder vans (Dispatcher-AM-Shift-1 ...) are not routes */
			condQry += db.getDataNotLikeCondQuery("Dispatcher",
					"C.VEHICLENUMBER");

		} else {
			labelsList.add("Clockin Time");
			labelsList.add("Employee");
			labelsList.add("Route");
			labelsList.add("Staging");
			labelsList.add("Vehicle");
			labelsList.add("Actual vehicle");
			labelsList.add("Phone used");
			labelsList.add("Prev Vehicle");
			labelsList.add("Service Tier");
			labelsList.add("Sch Service Tier");
			labelsList.add("Parking");
			labelsList.add("Wave");
			labelsList.add("Status");

			searchBean.setWidthColumns(
					new int[] { 10, 12, 6, 6, 10, 10, 10, 8, 10, 10, 6, 6, 6 });
		}

		searchBean.setDisplayName(bean.getDisplayName() + "s");

		searchBean.setController(bean.getController());

		/* Always scope to a day: default any EMPTY date to today, so the page
		   never dumps the entire check-in history (which happened when a
		   navigation sent searchFilter=yes with blank dates). */
		if (searchBean.getSrhFromDate() == null || searchBean.getSrhFromDate().trim().length() == 0)
			searchBean.setSrhFromDate(currentDate);
		if (searchBean.getSrhToDate() == null || searchBean.getSrhToDate().trim().length() == 0)
			searchBean.setSrhToDate(currentDate);
		condQry += db.getDateCondQuery(searchBean.getSrhFromDate(),
				searchBean.getSrhToDate(), "A.CLOCKINTIME");

		condQry += db.getIDInCondQuery(searchBean.getSrhEmployeeID(),
				"A.EMPLOYEEID");

		if (searchBean.getSrhValue2().length() > 0) {
			String selQry = "SELECT DISTINCT VEHICLEID FROM VEHICLE WHERE STATUS!="
					+ RecordStatus.DELETE + " AND ENTITYID=" + entityID
					+ db.getDataInCondQuery(searchBean.getSrhValue2(),
							"SERVICETIER");
			String vehicleIDs = db.selectById(selQry);
			if (vehicleIDs.length() > 0) {
				condQry += db.getIDInCondQuery(vehicleIDs, "A.VEHICLEID");
			} else {
				condQry += " AND A.VEHICLEID IS NULL AND A.EMPLOYEEID IS NULL ";
			}

		} else {
			condQry += db.getIDInCondQuery(searchBean.getSrhVehicleID(),
					"A.VEHICLEID");
		}

		if (submitType == SubmitType.UPDATE) {
			condQry += db.getIDInCondQuery(RecordStatus.ACTIVE + "",
					"A.STATUS");
		} else {
			if (searchBean.getSrhStatus().length() > 0)
				condQry += db.getIDInCondQuery(searchBean.getSrhStatus(),
						"A.STATUS");
			else
				condQry += db.getIDInCondQuery(
						RecordStatus.ACTIVE + ", " + RecordStatus.POST,
						"A.STATUS");

		}

		String printType = searchBean.getTransMap().get("printType") == null
				? ""
				: searchBean.getTransMap().get("printType").toString().trim();

		searchBean.setColumnSortName(searchBean.getColumnSortName()
				.replaceAll("2", "9").replaceAll("3", "11")
				.replaceAll("4", "10").replaceAll("6", "14"));

		String selQry = "SELECT A.DACHECKINID, "
				+ db.getSelectDateTime("A.CLOCKINTIME")
				+ ", A.EMPLOYEEID, A.VEHICLEID, C.SERVICETIER, A.PARKING, "
				+ db.getSelectDateFormat("A.WAVE_TIME", db.ORACLE_HHSMISAM)
				+ ", A.STATUS, "
				+ db.getSelectDateFormat("A.CLOCKINTIME",
						db.ORACLE_YYYYMMDDHH24MISS)
				+ ", C.VEHICLENUMBER, B.FULLNAME, PREV_VEHICLEID, "
				+ db.getSelectDate("A.CLOCKINTIME")
				+ ", A.SERVICETIER, IFNULL(B.TRANSPORTERID,'') FROM DACHECKIN A JOIN EMPLOYEE B ON "
				+ "A.EMPLOYEEID=B.EMPLOYEEID LEFT JOIN VEHICLE C ON "
				+ "A.VEHICLEID=C.VEHICLEID WHERE A.ENTITYID=" + entityID
				+ condQry;
		if (submitType == SubmitType.UPDATE) {
			selQry += getOrderByQry(searchBean, "14, 11");

		} else if (submitType == SubmitType.PRINT) {
			if ("view".equalsIgnoreCase(printType)) {
				selQry += getOrderByQry(searchBean, "9, 11");
			} else {
				selQry += getOrderByQry(searchBean, "9, 5, 11");
			}

		} else {
			selQry += getOrderByQry(searchBean, "5, 9, 11");
		}

		searchBean.setColumnSortName(searchBean.getColumnSortName()
				.replaceAll("9", "2").replaceAll("11", "3")
				.replaceAll("10", "4").replaceAll("14", "6"));
		List resultList = db.selectAsList(selQry, 15);
		List tableDataList = new ArrayList();
		if (resultList.size() > 0) {
			searchBean.setDisplayPrintBtn(true);
			searchBean.setDisplayViewBtn(true);

			if (submitType == SubmitType.UPDATE) {
				String employeesTxt = getSuggextorData(
						getAdminDataList("employees", "", "", entityID), "");
				String vehiclesTxt = getSuggextorData(
						getAdminDataList("vehicles", "", "", entityID), "");
				String gasCardsTxt = "";
				// gasCardsTxt = getSuggextorData(getAdminDataList("gasCards",
				// "", "", entityID), "");

				StringBuffer xmlMesg = new StringBuffer();
				xmlMesg.append("<employeesTxt>").append(employeesTxt)
						.append("</employeesTxt>");
				xmlMesg.append("<vehiclesTxt>").append(vehiclesTxt)
						.append("</vehiclesTxt>");
				xmlMesg.append("<gasCardsTxt>").append(gasCardsTxt)
						.append("</gasCardsTxt>");
				searchBean.setXmlMesg(xmlMesg.toString());
			}

			if (submitType == SubmitType.UPDATE) {
				for (int i = 0; i < resultList.size(); i++) {
					List tempList = (ArrayList) resultList.get(i);
					String id = tempList.get(0) == null ? ""
							: tempList.get(0).toString().trim();
					String clockInTime = tempList.get(1) == null ? ""
							: tempList.get(1).toString().trim();
					String employeeID = tempList.get(2) == null ? ""
							: tempList.get(2).toString().trim();
					String vehicleID = tempList.get(3) == null ? ""
							: tempList.get(3).toString().trim();
					String serviceTier = tempList.get(13) == null ? ""
							: tempList.get(13).toString().trim();

					List<String> tempRow = new ArrayList<String>();
					tempRow.add(id);
					tempRow.add(clockInTime);
					tempRow.add(employeeID);
					tempRow.add(vehicleID);
					tempRow.add(serviceTier);
					tableDataList.add(tempRow);
				}

			} else {
				Map<String, String> _prevEmpVehicleMap = new HashMap();
				Map<String, String> _routeCodeMap = new HashMap();
				Map<String, String> _smsMap = new HashMap();
				/* wave-sheet assignments (route_assignment) for the searched
				   dates, keyed by employee */
				Map<String, String[]> _assignMap = getRouteAssignMap(
						searchBean.getSrhFromDate(), searchBean.getSrhToDate(),
						entityID);
				Map<String, String[]> _itinMap = getItineraryVinPhoneMap(
						searchBean.getSrhFromDate(),
						searchBean.getSrhToDate(), entityID);

				String clockInDate = getIndexedDataFromList(resultList, 12,
						",");

				String idArray[] = db.getIndexedDataFromList(resultList,
						new int[] { 2, 0 });
				String empIDs = idArray[0];
				String ids = idArray[1];

				SMSDAO smsDAO = new SMSDAO();
				_smsMap = smsDAO.getSMSSentMap(bean.getController(), ids,
						entityID);

				if (clockInDate.equalsIgnoreCase(currentDate)) {
					searchBean.setDisplayPostBtn(true);
					searchBean.setDisplayViewBtn(true);

					_prevEmpVehicleMap = getEmpPrevVehicle(empIDs,
							searchBean.getSrhFromDate(),
							searchBean.getSrhToDate(), entityID);

					_routeCodeMap = getEmpRouteCodesMap(empIDs,
							searchBean.getSrhFromDate(),
							searchBean.getSrhToDate(), entityID);
				}

				for (int i = 0; i < resultList.size(); i++) {
					List tempList = (ArrayList) resultList.get(i);
					String id = tempList.get(0) == null ? ""
							: tempList.get(0).toString().trim();
					String clockInTime = tempList.get(1) == null ? ""
							: tempList.get(1).toString().trim();
					String employeeID = tempList.get(2) == null ? ""
							: tempList.get(2).toString().trim();
					String vehicleID = tempList.get(3) == null ? ""
							: tempList.get(3).toString().trim();
					String serviceTier = tempList.get(4) == null ? ""
							: tempList.get(4).toString().trim();
					String parking = tempList.get(5) == null ? ""
							: tempList.get(5).toString().trim();
					String wave = tempList.get(6) == null ? ""
							: tempList.get(6).toString().trim();
					String status = tempList.get(7) == null ? ""
							: tempList.get(7).toString().trim();
					String vehicleName = tempList.get(9) == null ? ""
							: tempList.get(9).toString().trim();
					String employeeName = tempList.get(10) == null ? ""
							: tempList.get(10).toString().trim();
					String runIndicator = tempList.get(11) == null ? ""
							: tempList.get(11).toString().trim();
					String scheduleServiceTier = tempList.get(13) == null ? ""
							: tempList.get(13).toString().trim();
					String transporterID = tempList.get(14) == null ? ""
							: tempList.get(14).toString().trim();
					String clockDay = tempList.get(12) == null ? ""
							: tempList.get(12).toString().trim();

					status = RecordStatus.RecordStatus[Integer
							.parseInt(status)];

					parking = mainUtil.getValue(mainUtil.getParking(), parking);

					String[] assign = _assignMap.get(employeeID);
					String assignRoute = assign == null ? "" : assign[0];
					String assignStaging = assign == null ? "" : assign[1];

					if (submitType == SubmitType.PRINT) {
						String routeCode = assignRoute.length() > 0 ? assignRoute
								: (_routeCodeMap.get(employeeID) == null ? ""
										: _routeCodeMap.get(employeeID));

						List<String> tempRow = new ArrayList<String>();
						tempRow.add(id);
						tempRow.add(clockInTime);
						tempRow.add(employeeName);
						tempRow.add(vehicleName);
						tempRow.add(scheduleServiceTier);
						tempRow.add(parking);
						tempRow.add(routeCode);
						tempRow.add(assignStaging);
						tempRow.add(status);
						tableDataList.add(tempRow);

					} else {
						String smsStatus = _smsMap.get(id) == null ? ""
								: _smsMap.get(id).toString().trim();
						smsStatus = smsStatus.replaceAll("queued", "Sent");

						if (smsStatus.contains("SMS Sent"))
							employeeName = "<span class='text-success' title='SMS Status: "
									+ smsStatus + "'>" + employeeName
									+ "</span>";
						else if (smsStatus.length() > 0)
							employeeName = "<span class='text-danger' title='SMS Status: "
									+ smsStatus + "'>" + employeeName
									+ "</span>";

						String prevVehicleName = _prevEmpVehicleMap
								.get(employeeID) == null ? ""
										: _prevEmpVehicleMap.get(employeeID);
						if (runIndicator.length() > 0) {
							vehicleName = "<span class='text-success' title='Changed'>"
									+ vehicleName + "</span>";

						} else if (scheduleServiceTier.length() > 0) {
							boolean notify = false;
							switch (scheduleServiceTier) {
							case "Custom Delivery Van 12ft":
								if (!(serviceTier.contains("TWELVE_FT")
										|| serviceTier.contains("12")))
									notify = true;
								break;

							case "Custom Delivery Van 14ft":
								if (!(serviceTier.contains("FOURTEEN_FT")
										|| serviceTier.contains("14")))
									notify = true;
								break;

							case "Custom Delivery Van 16ft":
								if (!(serviceTier.contains("SIXTEEN_FT")
										|| serviceTier.contains("16")))
									notify = true;
								break;

							case "Extra Large Van - US":
								if (!serviceTier
										.contains("EXTRA_LARGE_CARGO_VAN"))
									notify = true;
								break;

							case "Large Van":
								break;
							}

							if (notify)
								serviceTier = "<span class='text-info' title='Mismatch Service Tier'>"
										+ serviceTier + "</span>";
						}

						List<String> tempRow = new ArrayList<String>();
						tempRow.add(id);
						tempRow.add(clockInTime);
						tempRow.add(employeeName);
						tempRow.add(assignRoute);
						tempRow.add(assignStaging);
						tempRow.add(vehicleName);
						String[] itin = _itinMap.get(
								transporterID.toUpperCase() + "|" + clockDay);
						String actualVeh = "Unknown";
						String phoneUsed = "Unknown";
						if (itin != null) {
							if (itin[0].length() > 0)
								actualVeh = itin[0];
							if (itin[1].length() > 0)
								phoneUsed = itin[1];
						}
						tempRow.add(actualVeh);
						tempRow.add(phoneUsed);
						tempRow.add(prevVehicleName);
						tempRow.add(serviceTier);
						tempRow.add(scheduleServiceTier);
						tempRow.add(parking);
						tempRow.add(wave);
						tempRow.add(status);
						tableDataList.add(tempRow);
					}
				}
				/*-
				searchBean.setDisplaySMSBtn(isProperties(
						AdminConfiguration.enumCategorys.SMS.toString(),
						entityID));
				*/
			}
		}

		searchBean.setLabelsList(labelsList);
		searchBean.setDataList(tableDataList);
		searchBean.setSearchFiltersArray(new String[] { "Date Range",
				"Employee", "Vehicle", "Service Tier", "Status" });
		Map transMap = searchBean.getTransMap() == null ? new HashMap()
				: searchBean.getTransMap();
		transMap.put("_phoneInvDigits", getPhoneInventoryDigits(entityID));
		searchBean.setTransMap(transMap);
		return searchBean;

	}

	/* Vehicle number from VEHICLE via itinerary VIN + itinerary phone */
	private Map<String, String[]> getItineraryVinPhoneMap(String srhFromDate,
			String srhToDate, String entityID) throws Exception {
		Map<String, String[]> map = new HashMap<String, String[]>();
		String selQry = "SELECT UPPER(IFNULL(I.TRANSPORTERID,'')), "
				+ db.getSelectDate("I.ITINARARYDATE")
				+ ", IFNULL(V.VEHICLENUMBER,''), IFNULL(I.PHONENUMBER,'') "
				+ "FROM DAILY_ITINERARIES I LEFT JOIN VEHICLE V ON V.STATUS!="
				+ RecordStatus.DELETE + " AND V.ENTITYID=I.ENTITYID "
				+ "AND (UPPER(IFNULL(V.VINNUMBER,''))=UPPER(IFNULL(I.VINNUMBER,'')) "
				+ "OR (CHAR_LENGTH(IFNULL(I.VINNUMBER,''))>=6 AND RIGHT(UPPER(IFNULL(V.VINNUMBER,'')),"
				+ "CHAR_LENGTH(IFNULL(I.VINNUMBER,'')))=UPPER(IFNULL(I.VINNUMBER,'')))) "
				+ "WHERE I.STATUS=" + RecordStatus.ACTIVE + " AND I.ENTITYID="
				+ entityID
				+ db.getDateCondQuery(srhFromDate, srhToDate, "I.ITINARARYDATE");
		List rows = db.selectAsList(selQry, 4);
		for (int i = 0; i < rows.size(); i++) {
			List t = (ArrayList) rows.get(i);
			String tid = t.get(0) == null ? "" : t.get(0).toString().trim();
			String dt = t.get(1) == null ? "" : t.get(1).toString().trim();
			if (tid.length() == 0 || dt.length() == 0)
				continue;
			String vehNum = t.get(2) == null ? "" : t.get(2).toString().trim();
			String ph = t.get(3) == null ? "" : t.get(3).toString().trim();
			map.put(tid + "|" + dt, new String[] { vehNum, ph });
		}
		return map;
	}

	private Set<String> getPhoneInventoryDigits(String entityID)
			throws Exception {
		Set<String> digits = new HashSet<String>();
		List rows = db.selectAsList(
				"SELECT IFNULL(PHONENUMBER,'') FROM PHONES WHERE STATUS!="
						+ RecordStatus.DELETE + " AND ENTITYID=" + entityID,
				1);
		for (int i = 0; i < rows.size(); i++) {
			List t = (ArrayList) rows.get(i);
			String d = AdminPhones.digits10(
					t.get(0) == null ? "" : t.get(0).toString());
			if (d.length() > 0)
				digits.add(d);
		}
		return digits;
	}

	/* wave-sheet route/staging per employee for the searched date(s) —
	   route_assignment joined to employee by TRANSPORTERID */
	private Map<String, String[]> getRouteAssignMap(String srhFromDate,
			String srhToDate, String entityID) throws Exception {

		Map<String, String[]> _hMap = new HashMap<String, String[]>();
		try {
			String selQry = "SELECT E.EMPLOYEEID, IFNULL(R.ROUTE,''), "
					+ "IFNULL(R.STAGING,'') FROM route_assignment R "
					+ "JOIN EMPLOYEE E ON UPPER(E.TRANSPORTERID)=UPPER(R.TRANSPORTERID) "
					+ "WHERE R.ENTITYID=" + entityID + " AND R.STATUS!="
					+ RecordStatus.DELETE
					+ db.getDateCondQuery(srhFromDate, srhToDate,
							"R.ASSIGN_DATE");
			List resultList = db.selectAsList(selQry, 3);
			for (int i = 0; i < resultList.size(); i++) {
				List t = (ArrayList) resultList.get(i);
				String empID = t.get(0) == null ? "" : t.get(0).toString().trim();
				String route = t.get(1) == null ? "" : t.get(1).toString().trim();
				String staging = t.get(2) == null ? ""
						: t.get(2).toString().trim();
				if (empID.length() > 0)
					_hMap.put(empID, new String[] { route, staging });
			}
		} catch (Exception ex) {
			// table may not exist yet on older environments
		}
		return _hMap;
	}

	private Map<String, String> getEmpRouteCodesMap(String empIDs,
			String srhFromDate, String srhToDate, String entityID)
			throws Exception {

		Map<String, String> _hMap = new HashMap<String, String>();
		if (srhFromDate.equalsIgnoreCase(srhToDate)) {
			String selQry = "SELECT DISTINCT A.EMPLOYEEID, C.ROUTECODE, "
					+ db.getSelectDate("C.ROUTEDATE")
					+ " FROM DACHECKIN A, EMPLOYEE B, DAILYROUTES C WHERE "
					+ "A.EMPLOYEEID=B.EMPLOYEEID AND UPPER(B.TRANSPORTERID)"
					+ "=UPPER(C.TRANSPORTERID) AND DATE(A.CLOCKINTIME)=DATE(C.ROUTEDATE) "
					+ db.getIDInCondQuery(entityID, "A.ENTITYID")
					+ db.getIDInCondQuery(entityID, "C.ENTITYID")
					+ db.getIDInCondQuery(empIDs, "A.EMPLOYEEID")
					+ db.getIDInCondQuery(RecordStatus.ACTIVE + ", "
							+ RecordStatus.POST + ", " + RecordStatus.COMPLETED,
							"A.STATUS")
					+ db.getIDInCondQuery((RecordStatus.ACTIVE + ""),
							"C.STATUS")
					+ db.getDateCondTypeQuery(db.EQUALS_TO, "C.ROUTEDATE",
							srhToDate);

			List resultList = db.selectAsList(selQry, 3);
			_hMap = getMap(resultList);
		}

		return _hMap;
	}

	public Map<String, String> getEmpPrevVehicle(String empIDs,
			String srhFromDate, String srhToDate, String entityID)
			throws Exception {

		Map<String, String> _hMap = new HashMap<String, String>();
		if (srhFromDate.equalsIgnoreCase(srhToDate)) {
			String selQry = "SELECT A.EMPLOYEEID, B.VEHICLENUMBER, "
					+ "A.CLOCKINTIME FROM DACHECKIN A JOIN VEHICLE B "
					+ "ON A.VEHICLEID=B.VEHICLEID JOIN ("
					+ "SELECT EMPLOYEEID, MAX(CLOCKINTIME) AS MAX_DATE "
					+ "FROM DACHECKIN WHERE ENTITYID=" + entityID
					+ db.getIDInCondQuery(RecordStatus.ACTIVE + ", "
							+ RecordStatus.POST + ", " + RecordStatus.COMPLETED,
							"STATUS")
					+ db.getDateCondTypeQuery(db.LESS_THAN, "CLOCKINTIME")
					+ " GROUP BY EMPLOYEEID) LATEST "
					+ "ON A.EMPLOYEEID=LATEST.EMPLOYEEID AND "
					+ "A.CLOCKINTIME=LATEST.MAX_DATE WHERE A.ENTITYID="
					+ entityID
					+ db.getIDInCondQuery(RecordStatus.ACTIVE + ", "
							+ RecordStatus.POST + ", " + RecordStatus.COMPLETED,
							"A.STATUS")
					+ " ORDER BY A.EMPLOYEEID, A.CLOCKINTIME DESC";

			List resultList = db.selectAsList(selQry, 3);
			for (int i = 0; i < resultList.size(); i++) {
				List tempList = (ArrayList) resultList.get(i);
				String empID = getListData(tempList, 0);
				String vehicleName = getListData(tempList, 1);
				if (_hMap.get(empID) == null) {
					_hMap.put(empID, vehicleName);
				}
			}
		}

		return _hMap;
	}

	@Override
	public Object[] createRecord(MainBean mainBean, String loginUser,
			String loginUserRoles, String loginUserID, String entityID)
			throws Exception {

		bean = (DACheckin) mainBean;
		ErrorBean errorType = new ErrorBean();
		List<String> insList = new ArrayList<String>();
		String recordID = "";
		String station = "", daStatus = "";

		String selQry = "SELECT DACHECKINID FROM DACHECKIN WHERE STATUS IN ("
				+ RecordStatus.ACTIVE + "," + RecordStatus.POST
				+ ") AND ENTITYID=" + entityID + " AND EMPLOYEEID="
				+ bean.getEmployeeID()
				+ db.getDateCondTypeQuery(db.EQUALS_TO, "CLOCKINTIME",
						bean.getClockinDate(), db.ORACLE_MMSDDSYYYY)
				+ db.getIDInCondQuery(bean.getWave(), "WAVE");
		List resultList = db.selectAsList(selQry, 1);
		if (resultList.size() > 0) {
			List tempList = (ArrayList) resultList.get(0);
			recordID = tempList.get(0) == null ? ""
					: tempList.get(0).toString().trim();

		}

		if (recordID.length() == 0) {
			int status = bean.getStatus().length() == 0 ? RecordStatus.ACTIVE
					: Integer.parseInt(bean.getStatus());
			recordID = db.getNextIDValue("DACHECKINID");

			insList = buildCheckinQry(recordID, bean.getClockinDate(),
					bean.getClockinTime(), bean.getEmployeeID(),
					bean.getVehicleID(), bean.getCdvCertified(),
					bean.getParking(), bean.getWave(), bean.getPhoneCable(),
					bean.getGasCard(), bean.getGasCardID(),
					bean.getDaComments(), bean.getDispatchComments(), status,
					"", "", "", station, daStatus, loginUser, entityID,
					insList);

			boolean result = db.batchInsert(insList);

			if (result && status == RecordStatus.POST)
				result = postCheckIn(recordID, loginUser, entityID);

			errorType = getErrorType(result, SubmitType.CREATE,
					bean.getDisplayName());
		} else {
			errorType = getErrorType(false, SubmitType.DUPLICATE,
					bean.getDisplayName());

		}

		return new Object[] { recordID, errorType };
	}

	public String getLastVehicleParking(String vehicleID, String scheduleDate,
			String entityID) throws Exception {

		String parking = "";
		if (vehicleID.length() > 0 && entityID.length() > 0) {
			String selQry = "SELECT A.DACHECKOUTID, A.PARKING, "
					+ db.getSelectDateFormat("A.CLOCKOUTTIME",
							db.ORACLE_YYYYSMMSDD)
					+ " FROM DACHECKOUT A, DACHECKIN B WHERE "
					+ "A.DACHECKINID=B.DACHECKINID AND A.STATUS!="
					+ RecordStatus.DELETE + " AND B.ENTITYID=" + entityID
					+ db.getIDInCondQuery(vehicleID, "B.VEHICLEID")
					+ db.getDateCondTypeQuery(db.LESS_THAN_EQUALS,
							"A.CLOCKOUTTIME", scheduleDate)
					+ " ORDER BY 3 DESC, 1 DESC";

			List resultList = db.selectAsList(selQry, 3);
			if (resultList.size() > 0) {
				List tempList = (ArrayList) resultList.get(0);
				parking = getListData(tempList, 1);
			}
		}

		System.out.println("getLastVehicleParking :: " + parking + " :: "
				+ vehicleID + " :: " + entityID);
		return parking;
	}

	public List<String> buildCheckinQry(String recordID, String clockInDate,
			String clockinTime, String employeeID, String vehicleID,
			String cdvCert, String parking, String wave, String phoneCable,
			String gasCard, String gasCardID, String daComments,
			String dispatchComments, int status, String scheduleID,
			String scheduleWaveTime, String scheduleServiceTier, String station,
			String daStatus, String loginUser, String entityID, List insList) {

		String clockInDateTime = clockInDate + " " + clockinTime;
		String insQry = "INSERT INTO DACHECKIN (DACHECKINID, ENTITYID, "
				+ "CLOCKINTIME, EMPLOYEEID, VEHICLEID, CDVCERTIFIED, "
				+ "PARKING, WAVE, PHONECABLE, GASCARD, GASCARDID, DAREMARKS, "
				+ "DISPATCHERREMARKS, CREATE_USER, CREATE_DATE, STATUS, "
				+ "EMPLOYEE_SCHEDULEID, WAVE_TIME, SERVICETIER) VALUES ("
				+ recordID + ", " + entityID + ", "
				+ db.getInsertDateTime(clockInDateTime) + ", "
				+ db.getInsertDBValue(employeeID) + ", "
				+ db.getInsertDBValue(vehicleID) + ", "
				+ db.getInsertDBValue(cdvCert) + ", "
				+ db.getInsertDBValue(parking) + ", "
				+ db.getInsertDBValue(wave) + ", "
				+ db.getInsertDBValue(phoneCable) + ", "
				+ db.getInsertDBValue(gasCard) + ", "
				+ db.getInsertDBValue(gasCardID) + ", "
				+ db.getInsertDBValue(daComments) + ", "
				+ db.getInsertDBValue(dispatchComments) + ", "
				+ db.getInsertDBValue(loginUser) + ", " + db.getInsertSysdate()
				+ ", " + db.getInsertDBValue(status) + ", "
				+ db.getInsertDBValue(scheduleID) + ", "
				+ db.getInsertDateFormat(scheduleWaveTime, db.ORACLE_HHSMISAM)
				+ ", " + db.getInsertDBValue(scheduleServiceTier) + ")";
		insList.add(insQry);

		Object returnObj[] = daStatusDAO.buildMainQry(clockInDate, clockinTime,
				employeeID, station, "", "", "", loginUser, entityID, insList);
		insList = (List) returnObj[0];

		return insList;
	}

	@Override
	public Object[] updateRecord(MainBean mainBean, String loginUser,
			String loginUserRoles, String loginUserID, String entityID)
			throws Exception {

		bean = (DACheckin) mainBean;
		ErrorBean errorType = new ErrorBean();
		List<String> upList = new ArrayList<String>();

		int status = bean.getStatus().length() == 0 ? RecordStatus.ACTIVE
				: Integer.parseInt(bean.getStatus());

		String recordID = bean.getDaCheckinID();
		String upQry = "UPDATE DACHECKIN SET CLOCKINTIME="
				+ db.getInsertDateFormat(
						(bean.getClockinDate() + " " + bean.getClockinTime()),
						db.ORACLE_MMSDDSYYYYSHHSMISAM)
				+ ", EMPLOYEEID=" + db.getInsertDBValue(bean.getEmployeeID())
				+ ", VEHICLEID=" + db.getInsertDBValue(bean.getVehicleID())
				+ ", PREV_VEHICLEID=" + db.getInsertDBValue("")
				+ ", CDVCERTIFIED="
				+ db.getInsertDBValue(bean.getCdvCertified()) + ", PARKING="
				+ db.getInsertDBValue(bean.getParking()) + ", WAVE="
				+ db.getInsertDBValue(bean.getWave()) + ", PHONECABLE="
				+ db.getInsertDBValue(bean.getPhoneCable()) + ", GASCARD="
				+ db.getInsertDBValue(bean.getGasCard()) + ", GASCARDID="
				+ db.getInsertDBValue(bean.getGasCardID()) + ", DAREMARKS="
				+ db.getInsertDBValue(bean.getDaComments())
				+ ", DISPATCHERREMARKS="
				+ db.getInsertDBValue(bean.getDispatchComments())
				+ ", UPDATE_USER=" + db.getInsertDBValue(loginUser)
				+ ", UPDATE_DATE=" + db.getInsertSysdate() + ", STATUS="
				+ db.getInsertDBValue(status) + " WHERE DACHECKINID="
				+ recordID;
		upList.add(upQry);

		boolean result = db.batchInsert(upList);

		if (result && status == RecordStatus.POST)
			result = postCheckIn(recordID, loginUser, entityID);

		errorType = getErrorType(result, SubmitType.UPDATE,
				bean.getDisplayName());

		return new Object[] { recordID, errorType };
	}

	@Override
	public Object[] deleteRecord(MainBean mainBean, String loginUser,
			String loginUserRoles, String loginUserID, String entityID)
			throws Exception {

		bean = (DACheckin) mainBean;
		ErrorBean errorType = new ErrorBean();
		List<String> upList = new ArrayList<String>();

		String recordID = bean.getDaCheckinID();
		upList.add(buildStatusQry("DACHECKIN", "DACHECKINID", recordID,
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

		bean = (DACheckin) mainBean;
		ErrorBean errorType = new ErrorBean();
		List<String> upList = new ArrayList<String>();

		String recordID = bean.getDaCheckinID();
		upList.add(buildStatusQry("DACHECKIN", "DACHECKINID", recordID,
				RecordStatus.POST, loginUser));

		boolean result = db.batchInsert(upList);

		errorType = getErrorType(result, SubmitType.FINAL,
				bean.getDisplayName());

		return new Object[] { recordID, errorType };
	}

	@Override
	public Object[] withHoldRecord(MainBean mainBean, String loginUser,
			String loginUserRoles, String loginUserID, String entityID)
			throws Exception {

		bean = (DACheckin) mainBean;
		ErrorBean errorType = new ErrorBean();
		List<String> upList = new ArrayList<String>();
		String station = "", daStatus = "";

		String recordID = bean.getDaCheckinID();
		upList.add(buildStatusQry("DACHECKIN", "DACHECKINID", recordID,
				RecordStatus.UNPOST, loginUser));

		String selQry = "SELECT A.DACHECKOUTID, "
				+ db.getSelectDate("A.CLOCKOUTTIME")
				+ ", B.EMPLOYEEID, B.VEHICLEID FROM "
				+ "DACHECKOUT A, DACHECKIN B WHERE "
				+ "A.DACHECKINID=B.DACHECKINID AND A.STATUS!="
				+ RecordStatus.DELETE + " AND A.DACHECKINID IN (" + recordID
				+ ")";
		List resultList = db.selectAsList(selQry, 4);
		if (resultList.size() > 0) {
			List tempList = (ArrayList) resultList.get(0);
			String daCheckoutID = getListData(tempList, 0);
			String clockoutDate = getListData(tempList, 1);
			String employeeID = getListData(tempList, 2);
			String vehicleID = getListData(tempList, 3);

			upList.add(buildStatusQry("DACHECKOUT", "DACHECKOUTID",
					daCheckoutID, RecordStatus.DELETE, loginUser));

			selQry = "SELECT VEHICLEINSPECTIONID FROM VEHICLEINSPECTION "
					+ "WHERE STATUS!=" + RecordStatus.DELETE + " AND ENTITYID="
					+ entityID + db.getIDInCondQuery(vehicleID, "VEHICLEID")
					+ db.getDateCondTypeQuery(db.EQUALS_TO, "INSPECTIONDATE",
							clockoutDate, "");
			String vehicleInspectionID = db.selectById(selQry);
			if (vehicleInspectionID.length() > 0)
				upList.add(buildStatusQry("VEHICLEINSPECTION",
						"VEHICLEINSPECTIONID", vehicleInspectionID,
						RecordStatus.DELETE, loginUser));
		}

		bean = fetchRecord(recordID, loginUser, loginUserRoles, loginUserID,
				entityID, SubmitType.BROWSE);

		recordID = db.getNextIDValue("DACHECKINID");
		upList = buildCheckinQry(recordID, bean.getClockinDate(),
				bean.getClockinTime(), bean.getEmployeeID(),
				bean.getVehicleID(), bean.getCdvCertified(), bean.getParking(),
				bean.getWave(), bean.getPhoneCable(), bean.getGasCard(),
				bean.getGasCardID(), bean.getDaComments().replaceAll("'", "''"),
				bean.getDispatchComments().replaceAll("'", "''"),
				RecordStatus.ACTIVE, bean.getScheduleID(),
				bean.getScheduleWaveTime(), bean.getScheduleServiceTier(),
				station, daStatus, loginUser, entityID, upList);

		boolean result = db.batchInsert(upList);

		errorType = getErrorType(result, SubmitType.WITH_HOLD,
				bean.getDisplayName());

		return new Object[] { recordID, errorType };
	}

	@Override
	public DACheckin fetchRecord(String recordID, String loginUser,
			String loginUserRoles, String loginUserID, String entityID,
			int submitType) throws Exception {

		String selQry = "SELECT DACHECKINID, ENTITYID, "
				+ db.getSelectDateTime("CLOCKINTIME") + ", 0"
				+ ", EMPLOYEEID, VEHICLEID, CDVCERTIFIED, "
				+ "PARKING, WAVE, PHONECABLE, GASCARD, GASCARDID, DAREMARKS, "
				+ "DISPATCHERREMARKS, CREATE_USER, "
				+ db.getSelectDateTime("CREATE_DATE") + ", UPDATE_USER, "
				+ db.getSelectDateTime("UPDATE_DATE")
				+ ", STATUS FROM DACHECKIN WHERE DACHECKINID=" + recordID;

		List resultList = new ArrayList();
		if (recordID.length() > 0)
			resultList = db.selectAsList(selQry,
					bean.getBeanAttributes().size());

		bean = (DACheckin) setListValuesToBean(bean, bean.getBeanAttributes(),
				resultList);
		if (resultList.size() > 0) {
			List tempList = (ArrayList) resultList.get(0);
			String clockinDateTime = tempList.get(2) == null ? ""
					: tempList.get(2).toString().trim();
			String employeeID = tempList.get(4) == null ? ""
					: tempList.get(4).toString().trim();
			String vehicleID = tempList.get(5) == null ? ""
					: tempList.get(5).toString().trim();

			Map<String, String> _employeeMap = getAdminDataMap(
					enumSuggestorTypes.employees.toString(), employeeID,
					entityID);
			Map<String, String> _vehicleMap = getAdminDataMap(
					enumSuggestorTypes.vehicles.toString(), vehicleID,
					entityID);

			String employeeName = _employeeMap.get(employeeID) == null
					? employeeID
					: _employeeMap.get(employeeID);
			String vehicleName = _vehicleMap.get(vehicleID) == null ? vehicleID
					: _vehicleMap.get(vehicleID);
			String clockinDate = clockinDateTime.substring(0, 10).trim();
			String clockinTime = clockinDateTime.substring(10).trim();

			bean.setClockinDate(clockinDate);
			bean.setClockinTime(clockinTime);
			bean.setEmployeeName(employeeName);
			bean.setVehicleName(vehicleName);

			bean.setGasCardIdentifier(getTableColumnData("CARDIDENTIFIER",
					"GASCARDS", "GASCARDID", bean.getGasCardID()));
		}

		if (submitType == SubmitType.CREATE
				|| submitType == SubmitType.UPDATE) {
			String currentDate = db.getCurrentDate();
			if (submitType == SubmitType.CREATE)
				bean.setClockinDate(currentDate);
			bean.setGasCardList(getGasCardDetails(bean.getGasCardID(), entityID,
					currentDate, submitType));
		}

		return bean;
	}

	@Override
	public String getAjaxRequestTypeResp(String requestType,
			Map<String, String> requestMap, String loginUser,
			String loginUserRoles, String loginUserID, String entityID)
			throws Exception {

		String xmlMesg = "";
		if ("employeeVehicleAvail".equalsIgnoreCase(requestType)) {
			String srhEmployeeID = requestMap.get("employeeID") == null ? ""
					: requestMap.get("employeeID");
			String srhVehicleID = requestMap.get("vehicleID") == null ? ""
					: requestMap.get("vehicleID");
			String srhDos = requestMap.get("dos") == null ? ""
					: requestMap.get("dos");
			String srhWave = requestMap.get("wave") == null ? ""
					: requestMap.get("wave");

			Map<String, String> _assignedVehicleMap = new HashMap<String, String>();
			Object returnObjArray[] = getEmployeeVehicleID(srhEmployeeID,
					srhVehicleID, _assignedVehicleMap, srhDos, srhWave, "",
					entityID);
			String vehicleSelected = returnObjArray[0].toString();
			List availVehiclesList = (List) returnObjArray[1];
			xmlMesg = getSuggextorData(availVehiclesList, vehicleSelected);

		} else if ("sendSMS".equalsIgnoreCase(requestType)) {
			xmlMesg = new SMSDAO().sendSMS(bean.getController(), requestMap,
					loginUser, entityID);

		} else if ("quickAdd".equalsIgnoreCase(requestType)) {
			// Quick-add row on the redesigned list page: create a check-in
			// via the standard createRecord flow, report status back as XML.
			DACheckin qBean = new DACheckin();
			qBean.setClockinDate(requestMap.get("clockinDate") == null ? ""
					: requestMap.get("clockinDate").trim());
			qBean.setClockinTime(requestMap.get("clockinTime") == null ? ""
					: requestMap.get("clockinTime").trim());
			qBean.setEmployeeID(requestMap.get("employeeID") == null ? ""
					: requestMap.get("employeeID").trim());
			qBean.setVehicleID(requestMap.get("vehicleID") == null ? ""
					: requestMap.get("vehicleID").trim());
			qBean.setParking(requestMap.get("parking") == null ? ""
					: requestMap.get("parking").trim());
			qBean.setWave(requestMap.get("wave") == null ? "1"
					: requestMap.get("wave").trim());
			qBean.setCdvCertified("1");
			qBean.setPhoneCable("1");
			qBean.setGasCard("0");

			Object returnObjArray[] = createRecord(qBean, loginUser,
					loginUserRoles, loginUserID, entityID);
			ErrorBean qErr = (ErrorBean) returnObjArray[1];
			boolean qOK = ErrorBean.enumTypes.success.toString()
					.equalsIgnoreCase(qErr.getType());
			xmlMesg = "<status>" + qOK + "</status><mesg>"
					+ qErr.getMesg().replaceAll("<", "&lt;") + "</mesg>";
		}

		return xmlMesg;
	}

	public List getAvailableVehiclesList(String assignedVehicleIDs,
			String entityID) throws Exception {

		String condQry = "";
		if (assignedVehicleIDs.length() > 0)
			condQry += " AND VEHICLEID NOT IN (" + assignedVehicleIDs + ")";

		String selQry = "SELECT VEHICLEID, VEHICLENUMBER, SERVICETIER, "
				+ "SERVICETYPE FROM VEHICLE WHERE "
				+ "STATUS=0 AND OPERATIONALSTATUS=0 AND ENTITYID=" + entityID
				+ condQry + " ORDER BY 2 ";
		List availVehiclesList = db.selectAsList(selQry, 4);
		System.out.println("availVehiclesList :: " + availVehiclesList.size());
		return availVehiclesList;
	}

	public Object[] getEmployeeVehicleID(String srhEmployeeID,
			String srhVehicleID, Map<String, String> _assignedVehicleMap,
			String srhDos, String srhWave, String srhServiceTierInDB,
			String entityID) throws Exception {

		String vehicleSelected = "";

		String tempVehicleIDs = _assignedVehicleMap.get(srhDos) == null ? ""
				: _assignedVehicleMap.get(srhDos);
		String requestType = _assignedVehicleMap.get("requestType") == null ? ""
				: _assignedVehicleMap.get("requestType");
		String empServiceTier = _assignedVehicleMap
				.get("PrevServiceTier_" + srhEmployeeID) == null ? ""
						: _assignedVehicleMap
								.get("PrevServiceTier_" + srhEmployeeID);

		System.out.println("getEmployeeVehicleID.start :: " + srhDos + " :: "
				+ srhEmployeeID + " :: " + srhVehicleID + " :: " + srhWave
				+ " :: " + srhServiceTierInDB + " :: " + _assignedVehicleMap);

		String fromDate = "", toDate = "";
		String assignedVehicleIDs = tempVehicleIDs;
		if ("Next Day Run".equalsIgnoreCase(requestType)
				|| "Run".equalsIgnoreCase(requestType)) {

			// Vehicles allocated to this Employee in last 7 days
			GregorianCalendar fromDateCal = new GregorianCalendar();
			fromDateCal.setTime(sdfMMDDYYYY.parse(srhDos));
			fromDateCal.add(Calendar.DAY_OF_YEAR, -1);
			toDate = sdfMMDDYYYY.format(fromDateCal.getTime());

			fromDateCal.add(Calendar.DAY_OF_YEAR, -6);
			fromDate = sdfMMDDYYYY.format(fromDateCal.getTime());

		} else {
			// Available vehicles for that Day
			String selQry = "SELECT DISTINCT VEHICLEID "
					+ "FROM DACHECKIN WHERE STATUS IN (" + RecordStatus.ACTIVE
					+ "," + RecordStatus.POST + ", " + RecordStatus.COMPLETED
					+ ") AND ENTITYID=" + entityID
					+ db.getDateCondTypeQuery(db.EQUALS_TO, "CLOCKINTIME",
							srhDos, db.ORACLE_MMSDDSYYYY)
					+ db.getIDInCondQuery(srhWave, "WAVE")
					+ " AND EMPLOYEEID NOT IN (" + srhEmployeeID
					+ ") AND VEHICLEID IS NOT NULL ";
			assignedVehicleIDs = db.selectById(selQry);

			// Vehicles allocated to this Employee in last 7 days
			GregorianCalendar fromDateCal = new GregorianCalendar();
			fromDateCal.setTime(sdfMMDDYYYY.parse(srhDos));
			toDate = sdfMMDDYYYY.format(fromDateCal.getTime());

			fromDateCal.add(Calendar.DAY_OF_YEAR, -7);
			fromDate = sdfMMDDYYYY.format(fromDateCal.getTime());
		}

		List availVehiclesList = getAvailableVehiclesList(assignedVehicleIDs,
				entityID);

		Object retArray[] = getEmpoyeePastWeekDetails(fromDate, toDate,
				srhEmployeeID, srhServiceTierInDB, empServiceTier,
				vehicleSelected, _assignedVehicleMap, availVehiclesList,
				entityID);
		vehicleSelected = retArray[0].toString();
		empServiceTier = retArray[1].toString();
		_assignedVehicleMap = (Map<String, String>) retArray[2];

		if (vehicleSelected.length() == 0 && srhServiceTierInDB.length() > 0) {
			// Checking Service Tier vehicle matches with upload file
			for (int j = 0; j < availVehiclesList.size(); j++) {
				List tempList = (ArrayList) availVehiclesList.get(j);
				String id = getListData(tempList, 0);
				// String tVehicleNum = getListData(tempList, 1);
				String serviceTier = getListData(tempList, 2);
				// Checking previously used vehicle type from the available
				// pool and allocating
				if (srhServiceTierInDB.equalsIgnoreCase(serviceTier)) {
					vehicleSelected = id;
					System.out
							.println("availVehiclesList.vehicleSelected.875 :: "
									+ vehicleSelected);
					break;
				}
			}
		}

		if (vehicleSelected.length() == 0) {
			if (empServiceTier.length() == 0) {
				// Getting Employee Previous Service Tier if NOT present
				String selQry = "SELECT A.VEHICLEID, "
						+ db.getSelectDateFormat("A.CLOCKINTIME",
								db.ORACLE_YYYYSMMSDD)
						+ ", B.SERVICETIER FROM DACHECKIN A, VEHICLE B WHERE "
						+ "A.VEHICLEID=B.VEHICLEID AND A.STATUS IN ("
						+ RecordStatus.ACTIVE + "," + RecordStatus.POST + ","
						+ RecordStatus.COMPLETED + ") AND A.ENTITYID="
						+ entityID + " AND A.EMPLOYEEID=" + srhEmployeeID
						+ db.getDateCondQuery("", fromDate, "A.CLOCKINTIME")
						+ " ORDER BY 2 DESC, 1 ";
				List temployeeVehicleList = db.selectAsList(selQry, 3);
				System.out.println(
						"temployeeVehicleList :: " + temployeeVehicleList);
				if (temployeeVehicleList.size() > 0) {
					List tempList = (ArrayList) temployeeVehicleList.get(0);
					empServiceTier = getListData(tempList, 2);
				}
			}

			// Allcating Vehicle from the available pool
			for (int j = 0; j < availVehiclesList.size(); j++) {
				List tempList = (ArrayList) availVehiclesList.get(j);
				String id = getListData(tempList, 0);
				// String tVehicleNum = getListData(tempList, 1);
				String serviceTier = getListData(tempList, 2);
				if (empServiceTier.length() > 0) {
					// Checking previously used vehicle type the selecting
					if (empServiceTier.equalsIgnoreCase(serviceTier)) {
						vehicleSelected = id;
						System.out.println(
								"availVehiclesList.vehicleSelected.917 :: "
										+ vehicleSelected);
						break;
					}
					if (j == (availVehiclesList.size() - 1)) {
						tempList = (ArrayList) availVehiclesList.get(0);
						id = getListData(tempList, 0);
						vehicleSelected = id;
						System.out.println(
								"availVehiclesList.vehicleSelected.929 :: "
										+ vehicleSelected);
					}
				} else {
					// First Time Employee
					vehicleSelected = id;
					System.out
							.println("availVehiclesList.vehicleSelected.936 :: "
									+ vehicleSelected);
					break;
				}
			}
		}

		if (vehicleSelected.length() > 0) {
			if (tempVehicleIDs.length() > 0)
				tempVehicleIDs += ",";
			tempVehicleIDs += vehicleSelected;
			_assignedVehicleMap.put(srhDos, tempVehicleIDs);

			System.out.println("getEmployeeVehicleID.end :: " + srhDos + " :: "
					+ srhEmployeeID + " :: " + srhVehicleID + " :: " + srhWave
					+ " :: " + vehicleSelected);
		}

		return new Object[] { vehicleSelected, availVehiclesList,
				_assignedVehicleMap };
	}

	public String findEmployeeVehicleInCheckin(String fromDate, String toDate,
			String serviceTier, String employeeID, List availVehiclesList,
			String entityID) throws Exception {

		String vehicleID = "";
		String selQry = "SELECT A.VEHICLEID, "
				+ db.getSelectDateFormat("A.CLOCKINTIME", db.ORACLE_YYYYSMMSDD)
				+ ", B.SERVICETIER, A.SERVICETIER FROM DACHECKIN A, VEHICLE B WHERE "
				+ "A.VEHICLEID=B.VEHICLEID AND A.STATUS IN ("
				+ RecordStatus.ACTIVE + "," + RecordStatus.POST + ","
				+ RecordStatus.COMPLETED + ") AND A.ENTITYID=" + entityID
				+ " AND A.EMPLOYEEID=" + employeeID
				+ db.getDateCondQuery(fromDate, toDate, "A.CLOCKINTIME")
				+ " ORDER BY 2 DESC, 1 ";
		List checkinDataList = db.selectAsList(selQry, 4);

		for (int i = 0; i < checkinDataList.size(); i++) {
			List tempList = (ArrayList) checkinDataList.get(i);
			String checkinVehicleID = getListData(tempList, 0);
			String checkinServiceTier = getListData(tempList, 3);

			List tempList1 = new ArrayList();
			for (int j = 0; j < availVehiclesList.size(); j++) {
				tempList1 = (ArrayList) availVehiclesList.get(j);
				String adminVehicleID = getListData(tempList1, 0);
				if (adminVehicleID.equalsIgnoreCase(checkinVehicleID)) {
					if (serviceTier.equalsIgnoreCase(checkinServiceTier)) {
						vehicleID = checkinVehicleID;
						break;

					}
				}
			}

			if (vehicleID.length() > 0) {
				System.out.println(i + " :: findEmployeeVehicleInCheckin :: "
						+ serviceTier + " :: " + vehicleID + " :: " + tempList
						+ " :: " + tempList1);
				return vehicleID;
			}
		}

		return vehicleID;
	}

	public Object[] getEmpoyeePastWeekDetails(String fromDate, String toDate,
			String srhEmployeeID, String srhServiceTierInDB,
			String empServiceTier, String vehicleSelected,
			Map<String, String> _assignedVehicleMap, List availVehiclesList,
			String entityID) throws Exception {

		String selQry = "SELECT A.VEHICLEID, "
				+ db.getSelectDateFormat("A.CLOCKINTIME", db.ORACLE_YYYYSMMSDD)
				+ ", B.SERVICETIER, A.SERVICETIER FROM DACHECKIN A, VEHICLE B WHERE "
				+ "A.VEHICLEID=B.VEHICLEID AND A.STATUS IN ("
				+ RecordStatus.ACTIVE + "," + RecordStatus.POST + ","
				+ RecordStatus.COMPLETED + ") AND A.ENTITYID=" + entityID
				+ " AND A.EMPLOYEEID=" + srhEmployeeID
				+ db.getDateCondQuery(fromDate, toDate, "A.CLOCKINTIME")
				+ " ORDER BY 2 DESC, 1 ";
		List empPastWeekVehicleList = db.selectAsList(selQry, 4);
		System.out
				.println("empPastWeekVehicleList :: " + empPastWeekVehicleList);

		for (int i = 0; i < empPastWeekVehicleList.size(); i++) {
			List tempList = (ArrayList) empPastWeekVehicleList.get(i);
			String vehicleID = getListData(tempList, 0);
			String serviceTierInVehicle = getListData(tempList, 2);
			String serviceTierInDA = getListData(tempList, 3);
			if (empServiceTier.length() == 0) {
				empServiceTier = serviceTierInVehicle;
				_assignedVehicleMap.put("PrevServiceTier_" + srhEmployeeID,
						empServiceTier);
			}

			List tempList1 = new ArrayList();
			for (int j = 0; j < availVehiclesList.size(); j++) {
				tempList1 = (ArrayList) availVehiclesList.get(j);
				String tVehicleID = getListData(tempList1, 0);
				// String tVehicleNum = getListData(tempList1, 1);
				String tServiceTier = getListData(tempList1, 2);
				if (tVehicleID.equalsIgnoreCase(vehicleID)) {
					if (srhServiceTierInDB.length() > 0) {
						// Checking Service Tier vehicle matches with upload
						// file
						if (srhServiceTierInDB.equalsIgnoreCase(tServiceTier)) {
							vehicleSelected = vehicleID;
							break;
						}
					} else {
						vehicleSelected = vehicleID;
						break;
					}
				}

			}

			if (vehicleSelected.length() > 0) {
				System.out.println(
						i + " :: empPastWeekVehicleList.vehicleSelected :: "
								+ vehicleSelected + " :: " + tempList + " :: "
								+ tempList1);
				break;
			}
		}

		return new Object[] { vehicleSelected, empServiceTier,
				_assignedVehicleMap };
	}

	public List getGasCardDetails(String gasCardID, String entityID,
			String srhDate, int submitType) throws Exception {

		String subQry = "SELECT GASCARDID FROM DACHECKIN WHERE STATUS IN ("
				+ RecordStatus.ACTIVE + "," + RecordStatus.POST
				+ ")  AND GASCARDID IS NOT NULL AND ENTITYID=" + entityID
				+ db.getDateCondQuery(srhDate, srhDate, "CLOCKINTIME");
		if (gasCardID.length() > 0)
			subQry += " AND GASCARDID!=" + gasCardID;

		String condQry = " AND STATUS=" + RecordStatus.ACTIVE
				+ " AND AVAILABLE=1 AND CARDSTATUS=" + RecordStatus.ACTIVE;

		condQry += db.getDateCondTypeQuery(db.GREATER_THAN_EQUALS, "CARDEXPIRY",
				srhDate, "");

		String selQry = "SELECT GASCARDID, CARDIDENTIFIER FROM "
				+ "GASCARDS WHERE ENTITYID=" + entityID + condQry
				+ " AND GASCARDID NOT IN (" + subQry + ") ORDER BY 2 ";

		List resultList = db.selectAsList(selQry, 2);

		return resultList;
	}

	public boolean postCheckIn(String recordIDs, String loginUser,
			String entityID) throws Exception {

		boolean result = false;
		DACheckoutDAO daCheckoutDAO = new DACheckoutDAO();
		VehicleInspectionDAO vehicleInspectionDAO = new VehicleInspectionDAO();
		VehicleInspection vehicleInspection = new VehicleInspection();

		String selQry = "SELECT A.DACHECKINID, A.EMPLOYEEID, A.VEHICLEID, "
				+ db.getSelectDate("A.CLOCKINTIME")
				+ ", A.STATUS FROM DACHECKIN A LEFT JOIN VEHICLE C ON "
				+ "A.VEHICLEID=C.VEHICLEID WHERE A.STATUS IN ("
				+ RecordStatus.ACTIVE + ", " + RecordStatus.POST
				+ ") AND A.ENTITYID=" + entityID
				+ db.getIDInCondQuery(recordIDs, "A.DACHECKINID")
				+ " ORDER BY 1";
		List resultList = db.selectAsList(selQry, 5);

		for (int i = 0; i < resultList.size(); i++) {
			List tempList = (ArrayList) resultList.get(i);
			String daCheckInID = tempList.get(0) == null ? ""
					: tempList.get(0).toString().trim();
			String employeeID = tempList.get(1) == null ? ""
					: tempList.get(1).toString().trim();
			String vehicleID = tempList.get(2) == null ? ""
					: tempList.get(2).toString().trim();
			String clockInDate = tempList.get(3) == null ? ""
					: tempList.get(3).toString().trim();
			String status = tempList.get(4) == null ? ""
					: tempList.get(4).toString().trim();

			List<String> upList = new ArrayList();
			if ((RecordStatus.ACTIVE + "").equalsIgnoreCase(status))
				upList.add(buildStatusQry("DACHECKIN", "DACHECKINID",
						daCheckInID, RecordStatus.POST, loginUser));

			selQry = "SELECT DACHECKOUTID FROM DACHECKOUT WHERE DACHECKINID="
					+ daCheckInID + " AND ENTITYID=" + entityID
					+ " AND STATUS!=" + RecordStatus.DELETE;
			String daCheckoutID = db.selectById(selQry);
			// Duplicate Check for browser refresh
			if (daCheckoutID.length() == 0) {
				// DACheckout
				daCheckoutID = db.getNextIDValue("DACHECKOUTID");
				upList = daCheckoutDAO.buildMainQry(daCheckoutID, daCheckInID,
						clockInDate, "", "1", "1", "1", "1", "", "1", "1", "1",
						"1", "1", "1", "", "", RecordStatus.ACTIVE, loginUser,
						entityID, upList);

				// Vehicle Inspection
				String vehicleInspectionID = db
						.getNextIDValue("VEHICLEINSPECTIONID");
				upList = vehicleInspectionDAO.buildMainQry(vehicleInspectionID,
						clockInDate, daCheckInID, vehicleID, "", "", "",
						RecordStatus.ACTIVE, loginUser, entityID, upList);
				for (int j = 0; j < vehicleInspection
						.getTransArray().length; j++) {
					String displayName = vehicleInspection
							.getTransArray()[j][0];
					upList = vehicleInspectionDAO.buildTransQry(
							vehicleInspectionID, displayName, "0", "",
							RecordStatus.ACTIVE, loginUser, entityID, upList);
				}
			}

			if (upList.size() > 0)
				result = db.batchInsert(upList);
		}

		return result;
	}

	public String getAssignedVehicleIDs(String scheduleDate, String entityID) {

		String assignedVehicleIDs = "";
		String selQry = "SELECT VEHICLEID FROM DACHECKIN WHERE STATUS IN ("
				+ RecordStatus.ACTIVE + "," + RecordStatus.POST + ","
				+ RecordStatus.COMPLETED + ") AND ENTITYID=" + entityID
				+ db.getDateCondTypeQuery(db.EQUALS_TO, "CLOCKINTIME",
						scheduleDate);
		try {
			assignedVehicleIDs = db.selectById(selQry);
		} catch (Exception ex) {
			ex.printStackTrace();
		}

		return assignedVehicleIDs;
	}

	public boolean updateNewRunRecords(String requestType, int status,
			String loginUser, String entityID) throws Exception {

		boolean result = true;
		String scheduleDate = db.getCurrentDate();
		Map<String, String> _assignedVehicleMap = new HashMap<String, String>();
		_assignedVehicleMap.put("requestType", requestType);

		GregorianCalendar scheduleDateCal = new GregorianCalendar();
		scheduleDateCal.setTime(sdfMMDDYYYY.parse(scheduleDate));
		if ("Next Day Run".equalsIgnoreCase(requestType)) {
			scheduleDateCal.add(Calendar.DAY_OF_YEAR, 1);
			scheduleDate = sdfMMDDYYYY.format(scheduleDateCal.getTime());
		}

		String selQry = "SELECT A.DACHECKINID, A.EMPLOYEEID, "
				+ "A.VEHICLEID, C.SERVICETIER, A.WAVE, "
				+ db.getSelectDateFormat("A.CLOCKINTIME",
						db.ORACLE_YYYYMMDDHH24MISS)
				+ ", A.SERVICETIER FROM DACHECKIN A LEFT JOIN VEHICLE C ON "
				+ "A.VEHICLEID=C.VEHICLEID WHERE A.STATUS IN ("
				+ RecordStatus.ACTIVE + ") AND A.ENTITYID=" + entityID
				+ db.getDateCondQuery(scheduleDate, scheduleDate,
						"A.CLOCKINTIME")
				+ " ORDER BY 7";

		List resultList = db.selectAsList(selQry, 7);
		if (resultList.size() > 0) {
			String fromDate = "", toDate = "";
			String dataArray[] = getScheduledLastWeekDateRange(scheduleDate);
			if (dataArray != null) {
				fromDate = dataArray[0];
				toDate = dataArray[1];
			}

			String assignedVehicleIDs = _assignedVehicleMap
					.get(scheduleDate) == null ? ""
							: _assignedVehicleMap.get(scheduleDate);
			if (assignedVehicleIDs.length() == 0) {
				assignedVehicleIDs = getAssignedVehicleIDs(scheduleDate,
						entityID);
				_assignedVehicleMap.put(scheduleDate, assignedVehicleIDs);
			}

			System.out.println("getScheduledLastWeekDateRange :: "
					+ scheduleDate + " :: " + fromDate + " :: " + toDate
					+ " :: " + assignedVehicleIDs);

			String loopArray[] = new String[] { "serviceTierInLastWeek",
					"serviceTierInOpenPool", "checkInOpenPool", "" };
			for (int i = 0; i < loopArray.length; i++) {
				String checkLoopCond = loopArray[i];
				_assignedVehicleMap.put("checkLoopCond", checkLoopCond);

				for (int ij = 0; ij < resultList.size(); ij++) {
					List tempList = (ArrayList) resultList.get(ij);
					String recordID = tempList.get(0) == null ? ""
							: tempList.get(0).toString().trim();
					String employeeID = tempList.get(1) == null ? ""
							: tempList.get(1).toString().trim();
					String actualVehicleID = tempList.get(2) == null ? ""
							: tempList.get(2).toString().trim();
					String serviceTierInVehicle = tempList.get(3) == null ? ""
							: tempList.get(3).toString().trim();
					String serviceTierInFile = tempList.get(6) == null ? ""
							: tempList.get(6).toString().trim();

					String newVehicleID = "";
					String assignedVehicle = _assignedVehicleMap
							.get("Assigned_" + employeeID) == null ? ""
									: _assignedVehicleMap
											.get("Assigned_" + employeeID);
					assignedVehicleIDs = _assignedVehicleMap
							.get(scheduleDate) == null ? ""
									: _assignedVehicleMap.get(scheduleDate);
					System.out.println(i + " :: " + ij
							+ " :: updateNewRunRecords :: " + requestType
							+ " :: " + checkLoopCond + " :: " + assignedVehicle
							+ " :: " + assignedVehicleIDs + " :: " + tempList);
					if (assignedVehicle.length() > 0)
						continue;

					List availVehiclesList = getAvailableVehiclesList(
							assignedVehicleIDs, entityID);

					if ("serviceTierInLastWeek"
							.equalsIgnoreCase(checkLoopCond)) {

						newVehicleID = findEmployeeVehicleInCheckin(fromDate,
								toDate, serviceTierInFile, employeeID,
								availVehiclesList, entityID);

					} else if ("serviceTierInOpenPool"
							.equalsIgnoreCase(checkLoopCond)) {

						for (int j = 0; j < availVehiclesList.size(); j++) {
							tempList = (ArrayList) availVehiclesList.get(j);
							String adminVehicleID = getListData(tempList, 0);
							String adminVehicleServiceTier = getListData(
									tempList, 2);
							String adminVehicleServiceType = getListData(
									tempList, 3);
							if (adminVehicleServiceTier
									.equalsIgnoreCase(serviceTierInVehicle)) {
								newVehicleID = adminVehicleID;
								System.out.println(j + " :: " + checkLoopCond
										+ " :: " + serviceTierInVehicle + " :: "
										+ newVehicleID + " :: " + tempList);
								break;

							} else if (adminVehicleServiceType.length() > 0) {
								// Service Type Ex: Standard Parcel - Extra
								// Large Van - US
								if (adminVehicleServiceType
										.contains(serviceTierInFile)) {
									newVehicleID = adminVehicleID;
									System.out.println(j + " :: "
											+ checkLoopCond + " :: "
											+ serviceTierInFile + " :: "
											+ newVehicleID + " :: " + tempList);
									break;
								}
							}
						}

					} else if ("checkInOpenPool"
							.equalsIgnoreCase(checkLoopCond)) {

						for (int j = 0; j < availVehiclesList.size(); j++) {
							tempList = (ArrayList) availVehiclesList.get(j);
							String adminVehicleID = getListData(tempList, 0);
							newVehicleID = adminVehicleID;
							System.out
									.println(j + " :: " + checkLoopCond + " :: "
											+ newVehicleID + " :: " + tempList);
							break;
						}

					} else if (checkLoopCond.length() == 0) {
						Object returnObjArray[] = getEmployeeVehicleID(
								employeeID, "", _assignedVehicleMap,
								scheduleDate, "1", serviceTierInVehicle,
								entityID);
						newVehicleID = returnObjArray[0].toString();
						_assignedVehicleMap = (Map<String, String>) returnObjArray[2];
					}

					System.out.println(i + " :: " + ij + " :: " + checkLoopCond
							+ ".newVehicleID :: " + newVehicleID.length()
							+ " :: " + newVehicleID);
					if (newVehicleID.length() > 0) {
						if (!actualVehicleID.equalsIgnoreCase(newVehicleID)) {
							String upQry = "UPDATE DACHECKIN SET VEHICLEID="
									+ db.getInsertDBValue(newVehicleID)
									+ ", UPDATE_USER="
									+ db.getInsertDBValue(loginUser)
									+ ", UPDATE_DATE=" + db.getInsertSysdate()
									+ ", STATUS=" + db.getInsertDBValue(status)
									+ ", PREV_VEHICLEID ="
									+ db.getInsertDBValue(actualVehicleID)
									+ " WHERE DACHECKINID=" + recordID;
							result = db.update(upQry);

							System.out.println("      updateRunRecords :: "
									+ recordID + " :: "
									+ actualVehicleID.equalsIgnoreCase(
											newVehicleID)
									+ " :: " + newVehicleID + " :: "
									+ actualVehicleID + " :: " + result + " :: "
									+ scheduleDate);
						}

						if (assignedVehicleIDs.length() > 0)
							assignedVehicleIDs += ",";
						assignedVehicleIDs += newVehicleID;

						_assignedVehicleMap.put("Assigned_" + employeeID,
								newVehicleID);
						_assignedVehicleMap.put(scheduleDate,
								assignedVehicleIDs);
					}
				}
			}
		}

		return result;
	}

	public String[] getScheduledLastWeekDateRange(String scheduleDate) {

		try {
			GregorianCalendar fromDateCal = new GregorianCalendar();
			fromDateCal.setTime(sdfMMDDYYYY.parse(scheduleDate));
			fromDateCal.add(Calendar.DAY_OF_YEAR, -1);
			String toDate = sdfMMDDYYYY.format(fromDateCal.getTime());

			fromDateCal.add(Calendar.DAY_OF_YEAR, -6);
			String fromDate = sdfMMDDYYYY.format(fromDateCal.getTime());
			return new String[] { fromDate, toDate };
		} catch (Exception ex) {
			ex.printStackTrace();
		}

		return null;
	}

	public boolean updateRunRecords(String requestType, int status,
			String loginUser, String entityID) throws Exception {

		boolean result = true;

		String runDateVal = db.getCurrentDate();
		String checkDate = "";
		String statusCheck = RecordStatus.POST + ", " + RecordStatus.COMPLETED;
		Map<String, String> _assignedVehicleMap = new HashMap<String, String>();
		_assignedVehicleMap.put("requestType", requestType);

		GregorianCalendar fromDateCal = new GregorianCalendar();
		fromDateCal.setTime(sdfMMDDYYYY.parse(runDateVal));
		if ("Next Day Run".equalsIgnoreCase(requestType)) {
			statusCheck = RecordStatus.ACTIVE + ", " + RecordStatus.POST + ", "
					+ RecordStatus.COMPLETED;
			checkDate = runDateVal;

			fromDateCal.add(Calendar.DAY_OF_YEAR, 1);
			runDateVal = sdfMMDDYYYY.format(fromDateCal.getTime());
		} else {
			fromDateCal.add(Calendar.DAY_OF_YEAR, -1);
			checkDate = sdfMMDDYYYY.format(fromDateCal.getTime());
		}

		String selQry = "SELECT A.DACHECKINID, A.EMPLOYEEID, "
				+ "A.VEHICLEID, C.SERVICETIER, A.WAVE, "
				+ db.getSelectDateFormat("A.CLOCKINTIME",
						db.ORACLE_YYYYMMDDHH24MISS)
				+ " FROM DACHECKIN A LEFT JOIN VEHICLE C ON "
				+ "A.VEHICLEID=C.VEHICLEID WHERE A.STATUS IN ("
				+ RecordStatus.ACTIVE + ") AND A.ENTITYID=" + entityID
				+ db.getDateCondQuery(runDateVal, runDateVal, "A.CLOCKINTIME")
				+ " ORDER BY 6";

		List resultList = db.selectAsList(selQry, 6);
		System.out.println("updateRunRecords :: " + resultList.size() + " :: "
				+ requestType);
		if (resultList.size() > 0) {
			String assignedVehicleIDs = _assignedVehicleMap
					.get(runDateVal) == null ? ""
							: _assignedVehicleMap.get(runDateVal);
			if (assignedVehicleIDs.length() == 0) {
				assignedVehicleIDs = getAssignedVehicleIDs(runDateVal,
						entityID);
				_assignedVehicleMap.put(runDateVal, assignedVehicleIDs);
			}

			String tempDateVal = runDateVal;
			String employeeIDs = getIndexedDataFromList(resultList, 1, ",");
			GregorianCalendar tempDateCal = new GregorianCalendar();
			int count = 0;

			while (employeeIDs.length() > 0) {
				tempDateCal.setTime(sdfMMDDYYYY.parse(tempDateVal));
				tempDateCal.add(Calendar.DAY_OF_YEAR, -1);
				tempDateVal = sdfMMDDYYYY.format(tempDateCal.getTime());

				selQry = "SELECT DISTINCT EMPLOYEEID FROM DACHECKIN WHERE STATUS IN ("
						+ statusCheck + ") AND ENTITYID=" + entityID
						+ " AND EMPLOYEEID IN (" + employeeIDs + ") "
						+ db.getDateCondQuery(tempDateVal, tempDateVal,
								"CLOCKINTIME");

				String tempIDs = db.selectById(selQry);
				if (tempIDs.length() > 0) {
					String splitArray[] = tempIDs.split(",");
					for (int i = 0; i < splitArray.length; i++) {
						String empID = splitArray[i].trim();
						for (int j = 0; j < resultList.size(); j++) {
							List tempList = (ArrayList) resultList.get(j);
							String recordID = tempList.get(0) == null ? ""
									: tempList.get(0).toString().trim();
							String employeeID = tempList.get(1) == null ? ""
									: tempList.get(1).toString().trim();
							if (employeeID.equalsIgnoreCase(empID)) {
								String vehicleID = tempList.get(2) == null ? ""
										: tempList.get(2).toString().trim();
								String serviceTier = tempList.get(3) == null
										? ""
										: tempList.get(3).toString().trim();
								String wave = tempList.get(4) == null ? ""
										: tempList.get(4).toString().trim();
								result = false;

								Object returnObjArray[] = getEmployeeVehicleID(
										employeeID, "", _assignedVehicleMap,
										runDateVal, wave, "", entityID);
								String resetVehicleID = returnObjArray[0]
										.toString();
								_assignedVehicleMap = (HashMap<String, String>) returnObjArray[2];
								System.out.println(i
										+ " :: last7DaysLoop.empID :: " + empID
										+ " :: " + tempList + " :: "
										+ resetVehicleID + " :: "
										+ (resetVehicleID
												.equalsIgnoreCase(vehicleID)));
								if (!resetVehicleID
										.equalsIgnoreCase(vehicleID)) {
									vehicleID = vehicleID.length() == 0 ? "0"
											: vehicleID;
									String upQry = "UPDATE DACHECKIN SET VEHICLEID="
											+ db.getInsertDBValue(
													resetVehicleID)
											+ ", UPDATE_USER="
											+ db.getInsertDBValue(loginUser)
											+ ", UPDATE_DATE="
											+ db.getInsertSysdate()
											+ ", STATUS="
											+ db.getInsertDBValue(status)
											+ ", PREV_VEHICLEID ="
											+ db.getInsertDBValue(vehicleID)
											+ " WHERE DACHECKINID=" + recordID;

									result = db.update(upQry);

									System.out.println(
											"      updateRunRecords :: "
													+ recordID + " :: "
													+ resetVehicleID
															.equalsIgnoreCase(
																	vehicleID)
													+ " :: " + resetVehicleID
													+ " :: " + vehicleID
													+ " :: " + result + " :: "
													+ runDateVal);
								}
								System.out.println("");
								resultList.remove(j);
								break;
							}
						}
					}
				}
				employeeIDs = getIndexedDataFromList(resultList, 1, ",");
				statusCheck = RecordStatus.POST + "";

				count++;
				if (count > 7)
					break;
			}

			System.out.println(
					"pendingRecords.resultList :: " + resultList.size());
			// Pending records
			for (int j = 0; j < resultList.size(); j++) {
				List tempList = (ArrayList) resultList.get(j);
				String recordID = tempList.get(0) == null ? ""
						: tempList.get(0).toString().trim();
				String employeeID = tempList.get(1) == null ? ""
						: tempList.get(1).toString().trim();
				String vehicleID = tempList.get(2) == null ? ""
						: tempList.get(2).toString().trim();
				String serviceTier = tempList.get(3) == null ? ""
						: tempList.get(3).toString().trim();
				String wave = tempList.get(4) == null ? ""
						: tempList.get(4).toString().trim();
				result = false;

				Object returnObjArray[] = getEmployeeVehicleID(employeeID, "",
						_assignedVehicleMap, runDateVal, wave, "", entityID);
				String resetVehicleID = returnObjArray[0].toString();
				_assignedVehicleMap = (HashMap<String, String>) returnObjArray[2];
				System.out.println(
						j + " :: pendingRecords.empID :: " + employeeID + " :: "
								+ tempList + " :: " + resetVehicleID + " :: "
								+ (resetVehicleID.equalsIgnoreCase(vehicleID)));
				if (!resetVehicleID.equalsIgnoreCase(vehicleID)) {
					vehicleID = vehicleID.length() == 0 ? "0" : vehicleID;
					String upQry = "UPDATE DACHECKIN SET VEHICLEID="
							+ db.getInsertDBValue(resetVehicleID)
							+ ", UPDATE_USER=" + db.getInsertDBValue(loginUser)
							+ ", UPDATE_DATE=" + db.getInsertSysdate()
							+ ", STATUS=" + db.getInsertDBValue(status)
							+ ", PREV_VEHICLEID ="
							+ db.getInsertDBValue(vehicleID)
							+ " WHERE DACHECKINID=" + recordID;

					result = db.update(upQry);

					System.out.println("      updateRunRecords :: " + recordID
							+ " :: "
							+ resetVehicleID.equalsIgnoreCase(vehicleID)
							+ " :: " + resetVehicleID + " :: " + vehicleID
							+ " :: " + result + " :: " + runDateVal);
				}
				System.out.println("");
			}
		}
		System.out.println("");

		return result;
	}

	public boolean updateSwapRecords(List transList, int status,
			String loginUser) throws Exception {

		boolean result = true;
		List<String> upList = new ArrayList<String>();
		for (int i = 0; i < transList.size(); i++) {
			List tempList = (ArrayList) transList.get(i);
			String recordID = tempList.get(0) == null ? ""
					: tempList.get(0).toString().trim();
			String employeeID = tempList.get(1) == null ? ""
					: tempList.get(1).toString().trim();
			String vehicleID = tempList.get(2) == null ? ""
					: tempList.get(2).toString().trim();
			String clockinTime = tempList.get(3) == null ? ""
					: tempList.get(3).toString().trim();
			if (clockinTime.length() > 0)
				clockinTime = clockinTime.substring(0,
						clockinTime.indexOf(" "));

			String upQry = "UPDATE DACHECKIN SET EMPLOYEEID="
					+ db.getInsertDBValue(employeeID) + ", VEHICLEID="
					+ db.getInsertDBValue(vehicleID) + ", PREV_VEHICLEID="
					+ db.getInsertDBValue("") + ", UPDATE_USER="
					+ db.getInsertDBValue(loginUser) + ", UPDATE_DATE="
					+ db.getInsertSysdate() + ", STATUS="
					+ db.getInsertDBValue(status) + " WHERE DACHECKINID="
					+ recordID;
			upList.add(upQry);

			// Reset vechicle to Future Schedule
			String selQry = "SELECT DISTINCT DACHECKINID FROM DACHECKIN WHERE EMPLOYEEID="
					+ employeeID + " AND STATUS=" + RecordStatus.ACTIVE
					+ db.getDateCondTypeQuery(db.GREATER_THAN, "CLOCKINTIME",
							clockinTime, db.ORACLE_MMSDDSYYYY)
					+ " AND DACHECKINID!=" + recordID;
			String empCheckinIDs = db.selectById(selQry);
			if (empCheckinIDs.length() > 0) {
				upQry = "UPDATE DACHECKIN SET VEHICLEID="
						+ db.getInsertDBValue(vehicleID) + ", PREV_VEHICLEID="
						+ db.getInsertDBValue("") + ", UPDATE_USER="
						+ db.getInsertDBValue(loginUser) + ", UPDATE_DATE="
						+ db.getInsertSysdate() + " WHERE DACHECKINID IN ("
						+ empCheckinIDs + ")";
				upList.add(upQry);
			}
		}

		if (upList.size() > 0)
			result = db.batchInsert(upList);

		return result;
	}
}
