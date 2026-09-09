package com.dataobjects;

import java.text.DecimalFormat;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Date;
import java.util.GregorianCalendar;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import com.beans.ErrorBean;
import com.beans.GenericUpload;
import com.beans.MainBean;
import com.beans.SearchBean;
import com.tools.ExcelFile;
import com.util.RecordStatus;
import com.util.SubmitType;

public class GenericUploadDAO extends MVPGDAO {

	GenericUpload bean = new GenericUpload();

	DecimalFormat df = new DecimalFormat("0.00");

	public Map<String, String> getTableColumnIndexMap(List columnsList) {

		Map<String, String> _hMap = new HashMap<String, String>();
		for (int i = 0; i < columnsList.size(); i++) {
			String colLabel = getListDBData(columnsList, i).replaceAll(" ", "_")
					.replaceAll("-", "_").replaceAll("%", "").replace("(", "")
					.replace(")", "").replaceAll("/", "").toLowerCase();
			if (colLabel.length() > 0) {
				switch (colLabel) {
				default:
					_hMap.put(colLabel, i + "");
					break;
				}
			}
		}

		return _hMap;
	}

	@Override
	public GenericUpload fetchRecord(String recordID, String loginUser,
			String loginUserRoles, String loginUserID, String entityID,
			int submitType) throws Exception {

		bean = new GenericUpload();

		return bean;
	}

	@Override
	public SearchBean searchRecords(SearchBean searchBean, String recordID,
			String loginUser, String loginUserRoles, String loginUserID,
			String entityID) throws Exception {

		List<String> labelsList = new ArrayList<String>();
		labelsList.add("Upload Date");
		labelsList.add("File Name");
		labelsList.add("Total Rows");
		labelsList.add("Actual Rows");

		searchBean.setWidthColumns(new int[] { 20, 60, 10, 10 });

		searchBean.setDisplayName(bean.getDisplayName() + "s");

		searchBean.setController(bean.getController());

		String currentDate = db.getCurrentDate();
		if (!"yes".equalsIgnoreCase(searchBean.getSearchFilter())) {
			searchBean.setSrhFromDate(currentDate);
			searchBean.setSrhToDate(currentDate);
		}

		String condQry = db.getDateCondQuery(searchBean.getSrhFromDate(),
				searchBean.getSrhToDate(), "CREATE_DATE");

		searchBean.setColumnSortName(
				searchBean.getColumnSortName().replaceAll("2", "6"));

		String selQry = "SELECT GENERIC_UPLOADID, "
				+ db.getSelectDate("CREATE_DATE") + ", FILE_NAME, "
				+ "TOTAL_ROWS, ACTUAL_ROWS, "
				+ db.getSelectDateFormat("CREATE_DATE", db.ORACLE_YYYYSMMSDD)
				+ " FROM GENERIC_UPLOAD WHERE STATUS!=" + RecordStatus.DELETE
				+ " AND ENTITYID=" + entityID + condQry
				+ getOrderByQry(searchBean, "6 DESC, 1 DESC");

		searchBean.setColumnSortName(
				searchBean.getColumnSortName().replaceAll("6", "2"));

		List resultList = db.selectAsList(selQry, 6);
		if (resultList.size() > 0) {
			for (int i = 0; i < resultList.size(); i++) {
				List tempList = (ArrayList) resultList.get(i);
				tempList.remove(tempList.size() - 1);
				resultList.set(i, tempList);
			}
		}

		searchBean.setLabelsList(labelsList);
		searchBean.setDataList(resultList);
		searchBean.setSearchFiltersArray(new String[] { "Date Range" });
		return searchBean;
	}

	@Override
	public Object[] createRecord(MainBean mainBean, String loginUser,
			String loginUserRoles, String loginUserID, String entityID)
			throws Exception {

		bean = (GenericUpload) mainBean;
		ErrorBean errorType = new ErrorBean();
		ExcelFile excelFile = new ExcelFile();
		double totalRows = 0;
		double totalRowsInserted = 0;
		boolean createNewTable = true;
		boolean scheduleDayMismatch = false;
		String displayName = bean.getTableName();

		if (bean.getTableName().length() > 0) {
			List dataList = new ArrayList();
			Map<String, String> _reqMap = new HashMap<String, String>();
			_reqMap.put("selectedType", bean.getSelectedType());

			List<String> columnsList = new ArrayList<String>();

			switch (bean.getTableName()) {
			case "Vehicles":
			case "Employee":
			case "DVIC":
			case "SafetyDashboard":
			case "DashboardOverview":
			case "DeliveryOverview":
			case "QualityOverview":
			case "Escalations":
			case "Daily Routes":
			case "Station Level":
			case "WST Delivered Packages":
			case "WST Service Details":
			case "WST Weekly Report":
			case "Associates Concessions":
			case "Daily Itineraries":
			case "CDF Feedback":
			case "DSB Details":
			case "QualityOverview-DCR":
			case "QualityOverview-RTS":
			case "Sentiment Survey":
			case "DABreakUtilization":
			case "Tenure Workforce Weekly":
			case "Tenure Workforce DAS":
			case "Compliance Supplementary":
				createNewTable = false;
				Object returnObjArray[] = excelFile.readDataFromFile(
						bean.getUploadFileNameWithPath(),
						bean.getDataSeperator(), 0, 1, "");
				dataList = (ArrayList) returnObjArray[0];
				columnsList = (ArrayList<String>) returnObjArray[1];
				break;

			case "EmployeeSchedule":
				createNewTable = false;
				returnObjArray = excelFile.readDataFromFile(
						bean.getUploadFileNameWithPath(),
						bean.getDataSeperator(), 3, 4, "");
				dataList = (ArrayList) returnObjArray[0];
				columnsList = (ArrayList<String>) returnObjArray[1];
				/*-
				returnObjArray = excelFile.readDataFromXls(
						bean.getUploadFileNameWithPath(), 0, 1, 1);
				if (returnObjArray != null) {
					List dataList1 = (ArrayList) returnObjArray[0];
					List columnsList1 = (ArrayList<String>) returnObjArray[1];
				}
				*/
				break;

			case "Engine Off Compliance (EOC) Overview":
				createNewTable = false;
				returnObjArray = excelFile.readDataFromFile(
						bean.getUploadFileNameWithPath(),
						bean.getDataSeperator(), 17, 18, "EOC");
				dataList = (ArrayList) returnObjArray[0];
				columnsList = (ArrayList<String>) returnObjArray[1];
				break;
			}

			System.out.println("createNewTable :: " + createNewTable + " :: "
					+ bean.getTableName() + " :: " + dataList.size() + " :: "
					+ columnsList);
			String weekNum = "";
			totalRows = dataList.size();
			if (dataList.size() > 0) {
				switch (bean.getTableName()) {
				case "Employee":
					totalRowsInserted = new AdminEmployeeDAO().updateFromFile(
							columnsList, dataList, loginUser, entityID,
							_reqMap);
					break;

				case "Vehicles":
					totalRowsInserted = new AdminVehicleDAO().updateFromFile(
							columnsList, dataList, loginUser, entityID,
							_reqMap);
					break;

				case "EmployeeSchedule":
					displayName = "Schedule";
					totalRowsInserted = new EmployeeScheduleDAO()
							.updateFromFile(columnsList, dataList, loginUser,
									entityID, _reqMap);
					// FIX: -1 = selected run day not inside the file's week.
					if (totalRowsInserted == -1) {
						scheduleDayMismatch = true;
						totalRowsInserted = 0;
					}
					break;

				case "Engine Off Compliance (EOC) Overview":
					totalRows = dataList.size() - 1;
					totalRowsInserted = insEngineOffCompliance(
							bean.getUploadFileName(), columnsList, dataList,
							loginUser, entityID);
					break;

				case "SafetyDashboard":
					displayName = "Safety Dashboard";
					String splitArray[] = bean.getUploadFileName().split("-");
					if (splitArray.length > 0) {
						weekNum = splitArray[splitArray.length - 1].trim();
						if (weekNum.length() > 3)
							weekNum = weekNum.substring(1, 3);
					}
					totalRowsInserted = insSafetyDashboard("SAFETY_DASHBOARD",
							weekNum, dataList, loginUser, entityID);
					break;

				case "DashboardOverview":
					displayName = "Dashboard Overview";
					totalRowsInserted = insDashboardOverview(
							"DASHBOARD_OVERVIEW", weekNum, columnsList,
							dataList, loginUser, entityID);
					break;

				case "DeliveryOverview":
					displayName = "Delivery Overview";
					totalRowsInserted = insDeliveryOverview("DELIVERY_OVERVIEW",
							columnsList, dataList, loginUser, entityID);
					totalRows = columnsList.size() - 1;
					break;

				case "QualityOverview":
					displayName = "Quality Overview";
					totalRowsInserted = insQualityOverview("QUALITY_OVERVIEW",
							weekNum, columnsList, dataList, loginUser,
							entityID);
					break;

				case "Escalations":
					totalRowsInserted = insEscalations("ESCALATIONS", weekNum,
							columnsList, dataList, loginUser, entityID);
					break;

				case "DVIC":
					totalRowsInserted = insDvic("DVIC", weekNum, columnsList,
							dataList, loginUser, entityID);
					break;

				case "Daily Routes":
					totalRowsInserted = insDailyRoutes(bean.getUploadFileName(),
							columnsList, dataList, loginUser, entityID);
					break;

				case "Station Level":
					totalRowsInserted = insStationLevel(
							bean.getUploadFileName(), columnsList, dataList,
							loginUser, entityID);
					break;

				case "WST Delivered Packages":
					totalRowsInserted = insDeliveredPackages(
							bean.getUploadFileName(), columnsList, dataList,
							loginUser, entityID);
					break;

				case "WST Service Details":
					totalRowsInserted = insServiceDetails(
							bean.getUploadFileName(), columnsList, dataList,
							loginUser, entityID);
					break;

				case "WST Weekly Report":
					totalRowsInserted = insWeeklyReport(
							bean.getUploadFileName(), columnsList, dataList,
							loginUser, entityID);
					break;

				case "Associates Concessions":
					totalRowsInserted = insAssociatesConcessions(
							bean.getUploadFileName(), columnsList, dataList,
							loginUser, entityID);
					break;

				case "Daily Itineraries":
					totalRowsInserted = insDailyItineraries(
							bean.getUploadFileName(), columnsList, dataList,
							loginUser, entityID);
					break;

				case "CDF Feedback":
					displayName = "Customer Delivery Feedback";
					totalRowsInserted = insCdfFeedback(bean.getUploadFileName(),
							columnsList, dataList, loginUser, entityID);
					break;

				case "DSB Details":
					displayName = "Delivery Concessions (DSB)";
					totalRowsInserted = insDsbDetails(bean.getUploadFileName(),
							columnsList, dataList, loginUser, entityID);
					break;

				case "QualityOverview-DCR":
					displayName = "Quality DCR Weekly";
					totalRowsInserted = insQualityDcrWeekly(
							bean.getUploadFileName(), columnsList, dataList,
							loginUser, entityID);
					break;

				case "QualityOverview-RTS":
					displayName = "Quality RTS Details";
					totalRowsInserted = insRtsDetails(bean.getUploadFileName(),
							columnsList, dataList, loginUser, entityID);
					break;

				case "Sentiment Survey":
					displayName = "DA Sentiment Survey";
					totalRowsInserted = insSentimentSurvey(
							bean.getUploadFileName(), columnsList, dataList,
							loginUser, entityID);
					break;

				case "DABreakUtilization":
					displayName = "DA Break Utilization";
					totalRowsInserted = insDaBreakUtilization(dataList,
							loginUser, entityID);
					break;

				case "Tenure Workforce Weekly":
					displayName = "Tenure Workforce (weekly)";
					totalRowsInserted = insTenureWeekly(columnsList, dataList,
							loginUser, entityID);
					break;

				case "Tenure Workforce DAS":
					displayName = "Tenure Workforce (per DA)";
					totalRowsInserted = insTenureDas(columnsList, dataList,
							loginUser, entityID);
					break;

				case "Compliance Supplementary":
					displayName = "Compliance Supplementary";
					totalRowsInserted = insComplianceSupplementary(
							bean.getUploadFileName(),
							bean.getUploadFileNameWithPath(), loginUser,
							entityID);
					break;
				}
			}
		}

		if (createNewTable) {
			// Case-insensitive: portal downloads can arrive as ".Xlsx" / ".CSV"
			String uploadNameLower = bean.getUploadFileName().toLowerCase();
			if (uploadNameLower.endsWith(".xls")
					|| uploadNameLower.endsWith(".xlsx")) {

				String tableName = bean.getUploadFileName().substring(0,
						bean.getUploadFileName().indexOf("."));

				Object returnObjArray[] = excelFile.createTableFromExcel(
						tableName, loginUser, entityID,
						bean.getUploadFileNameWithPath());
				totalRows = (double) returnObjArray[0];
				totalRowsInserted = (double) returnObjArray[1];

			} else if (uploadNameLower.endsWith(".csv")) {

				String tableName = bean.getUploadFileName().substring(0,
						bean.getUploadFileName().indexOf("."));

				Object returnObjArray[] = excelFile.createTableFromCsv(
						tableName, loginUser, entityID,
						bean.getUploadFileNameWithPath(),
						bean.getDataSeperator());
				totalRows = (double) returnObjArray[0];
				totalRowsInserted = (double) returnObjArray[1];
			}
		}

		String autoIncrementArray[] = db
				.getAutoIncrementArray("GENERIC_UPLOADID");

		String insQry = "INSERT INTO GENERIC_UPLOAD (";
		if (autoIncrementArray != null)
			insQry += autoIncrementArray[0];
		insQry += "ENTITYID, FILE_NAME, BLOB_VALUE, "
				+ "TOTAL_ROWS, ACTUAL_ROWS, CREATE_USER, "
				+ "CREATE_DATE, STATUS) VALUES (";
		if (autoIncrementArray != null)
			insQry += autoIncrementArray[1];
		insQry += entityID + ", "
				+ db.getInsertDBValue(bean.getUploadFileName()) + ", ?, "
				+ db.getInsertDBValue(totalRows + "") + ", "
				+ db.getInsertDBValue(totalRowsInserted + "") + ", "
				+ db.getInsertDBValue(loginUser) + ", " + db.getInsertSysdate()
				+ ", " + RecordStatus.ACTIVE + ")";

		boolean result = db.insertBlob(insQry,
				bean.getUploadFileNameWithPath());

		errorType = getErrorType(result, SubmitType.CREATE,
				displayName + " " + bean.getDisplayName());

		// FIX: clear, user-facing message instead of a silent 0-row "success".
		if (scheduleDayMismatch) {
			errorType.setType(ErrorBean.enumTypes.warning.toString());
			errorType.setMesg("Schedule NOT loaded: the selected run day is not "
					+ "in this file's week. Check the file's week dates and "
					+ "choose Today / Next Day / Holiday Run accordingly.");
		}

		return new Object[] { "", errorType };
	}

	public double insSafetyDashboard(String tableName, String week,
			List dataList, String loginUser, String entityID) throws Exception {

		double numOfRows = 0;
		for (int i = 0; i < dataList.size(); i++) {
			List tempList = (ArrayList) dataList.get(i);
			String safetyDate = getListDBData(tempList, 0);
			String deliveryAssociate = getListDBData(tempList, 1);
			String transporterID = getListDBData(tempList, 2);
			String eventID = getListDBData(tempList, 3);
			String eventDateTime = getListDBData(tempList, 4);
			String vin = getListDBData(tempList, 5);
			String OSSImpact = getListDBData(tempList, 6);
			String metricType = getListDBData(tempList, 7);
			String metricSubType = getListDBData(tempList, 8);
			String source = getListDBData(tempList, 9);
			String videoLink = getListDBData(tempList, 10);
			String reviewDetails = getListDBData(tempList, 11);

			safetyDate = getFileDate(safetyDate);

			String selQry = "SELECT " + tableName + "ID FROM " + tableName
					+ " WHERE STATUS=" + RecordStatus.ACTIVE
					+ db.getDataInCondQuery(transporterID, "TRANSPORTERID")
					+ db.getDataInCondQuery(eventID, "EVENTID")
					+ db.getIDInCondQuery(entityID, "ENTITYID")
					+ db.getDateCondTypeQuery(db.EQUALS_TO, "EVENT_DATETIME",
							eventDateTime, db.ORACLE_YYYYDMMDDD24HRDMIDSS);
			String recordID = db.selectById(selQry);
			if (recordID.length() == 0) {
				String autoIncrementArray[] = db
						.getAutoIncrementArray(tableName + "ID");

				String insQry = "INSERT INTO " + tableName + " (";
				if (autoIncrementArray != null)
					insQry += autoIncrementArray[0];
				insQry += "ENTITYID, SAFTY_WEEK, SAFTY_DATE, "
						+ "DELIVERYASSOCIATE, TRANSPORTERID, EVENTID, "
						+ "EVENT_DATETIME, VIN, OSSIMPACT, METRICTYPE, "
						+ "METRICSUBTYPE, SOURCE, VIDEOLINK, REVIEWDETAILS, "
						+ "CREATE_USER, CREATE_DATE, STATUS) VALUES (";
				if (autoIncrementArray != null)
					insQry += autoIncrementArray[1];
				insQry += entityID + ", " + db.getInsertDBValue(week) + ", "
						+ db.getInsertDate(safetyDate) + ", "
						+ db.getInsertDBValue(deliveryAssociate) + ", "
						+ db.getInsertDBValue(transporterID) + ", "
						+ db.getInsertDBValue(eventID) + ", "
						+ db.getInsertDateFormat(eventDateTime,
								db.ORACLE_YYYYDMMDDD24HRDMIDSS)
						+ ", " + db.getInsertDBValue(vin) + ", "
						+ db.getInsertDBValue(OSSImpact) + ", "
						+ db.getInsertDBValue(metricType) + ", "
						+ db.getInsertDBValue(metricSubType) + ", "
						+ db.getInsertDBValue(source) + ", "
						+ db.getInsertDBValue(videoLink) + ", "
						+ db.getInsertDBValue(reviewDetails) + ", "
						+ db.getInsertDBValue(loginUser) + ", "
						+ db.getInsertSysdate() + ", " + RecordStatus.ACTIVE
						+ ")";
				boolean result = db.update(insQry);

				if (result)
					numOfRows++;
			}
		}

		return numOfRows;
	}

	public double insDeliveryOverview(String tableName, List columnsList,
			List dataList, String loginUser, String entityID) throws Exception {

		double numOfRows = 0;
		int arrayLen = 4;
		String deliveryYearArray[] = new String[arrayLen];
		String deliveryWeekArray[] = new String[arrayLen];
		String completedRoutesArray[] = new String[arrayLen];
		String dispatchedPackagesArray[] = new String[arrayLen];
		String deliveredPackagesArray[] = new String[arrayLen];
		String deliverySuccessPercArray[] = new String[arrayLen];
		String deliverySuccessPercDSPArray[] = new String[arrayLen];
		String firstDayDeliverySuccessPercArray[] = new String[arrayLen];
		String deliveryAttemptsArray[] = new String[arrayLen];
		String dnrDMPOArray[] = new String[arrayLen];
		String packagesDeliveredNotRecArray[] = new String[arrayLen];
		String shipmentsPerZoneHrArray[] = new String[arrayLen];
		String returnToStationDPMOArray[] = new String[arrayLen];
		String packagesReturnedToStationArray[] = new String[arrayLen];
		String packagesReturnedToStationPercArray[] = new String[arrayLen];
		String rescuedPackagesArray[] = new String[arrayLen];
		String rtsPackagesUnableToAccessArray[] = new String[arrayLen];
		String rtsPackagesUnableToAccessPercArray[] = new String[arrayLen];
		String rtsPackagesCustomerUnavailableArray[] = new String[arrayLen];
		String rtsPackagesCustomerUnavailablePercArray[] = new String[arrayLen];
		String rtsPackagesUnableToLocateArray[] = new String[arrayLen];
		String rtsPackagesUnableToLocatePercArray[] = new String[arrayLen];
		String rtsPackagesNoSecureLocationArray[] = new String[arrayLen];
		String rtsPackagesNoSecureLocationPercArray[] = new String[arrayLen];
		String rtsPackagesUnsafeDueToDogArray[] = new String[arrayLen];
		String rtsPackagesUnsafeDueToDogPercArray[] = new String[arrayLen];
		String rtsPackagesOutofDriveTimeArray[] = new String[arrayLen];
		String rtsPackagesOutofDriveTimePrecArray[] = new String[arrayLen];
		String rtsPackagesBusinessClosedArray[] = new String[arrayLen];
		String rtsPackagesBusinessClosedPrecArray[] = new String[arrayLen];
		String packagesReturnedToStationOthersArray[] = new String[arrayLen];
		String packagesReturnedToStationOthersPrecArray[] = new String[arrayLen];
		String packagesNotOnVanArray[] = new String[arrayLen];
		String podOpportunitesArray[] = new String[arrayLen];
		String podSuccessArray[] = new String[arrayLen];
		String podSuccessPrecArray[] = new String[arrayLen];

		for (int i = 0; i < dataList.size(); i++) {
			if (i == 0) {
				String week1 = getListData(columnsList, 1)
						.replaceAll("Week", "").trim();
				String week2 = getListData(columnsList, 2)
						.replaceAll("Week", "").trim();
				String week3 = getListData(columnsList, 3)
						.replaceAll("Week", "").trim();
				String week4 = getListData(columnsList, 4)
						.replaceAll("Week", "").trim();
				deliveryWeekArray = new String[] { week1, week2, week3, week4 };

				GregorianCalendar currentDateCal = new GregorianCalendar();
				int currentYear = currentDateCal.get(GregorianCalendar.YEAR);
				int week1Year = currentYear;
				int week2Year = currentYear;
				int week3Year = currentYear;
				int week4Year = currentYear;

				int currentWeekOfMonth = currentDateCal
						.get(GregorianCalendar.WEEK_OF_YEAR);
				if (Integer.parseInt(week1) > currentWeekOfMonth)
					week1Year--;
				if (Integer.parseInt(week2) > currentWeekOfMonth)
					week2Year--;
				if (Integer.parseInt(week3) > currentWeekOfMonth)
					week3Year--;
				if (Integer.parseInt(week4) > currentWeekOfMonth)
					week4Year--;

				deliveryYearArray = new String[] { week1Year + "",
						week2Year + "", week3Year + "", week4Year + "" };
			}

			List tempList = (ArrayList) dataList.get(i);
			String type = getListData(tempList, 0).replaceAll("'", "''");
			String week1 = getListData(tempList, 1).replaceAll("%", "")
					.replaceAll(",", "").replaceAll("'", "''").trim();
			String week2 = getListData(tempList, 2).replaceAll("%", "")
					.replaceAll(",", "").replaceAll("'", "''").trim();
			String week3 = getListData(tempList, 3).replaceAll("%", "")
					.replaceAll(",", "").replaceAll("'", "''").trim();
			String week4 = getListData(tempList, 4).replaceAll("%", "")
					.replaceAll(",", "").replaceAll("'", "''").trim();

			switch (type) {
			case "Completed Routes":
				completedRoutesArray = new String[] { week1, week2, week3,
						week4 };
				break;

			case "Dispatched Packages":
				dispatchedPackagesArray = new String[] { week1, week2, week3,
						week4 };
				break;

			case "Delivered Packages":
				deliveredPackagesArray = new String[] { week1, week2, week3,
						week4 };
				break;

			case "Delivery Success (%)":
				deliverySuccessPercArray = new String[] { week1, week2, week3,
						week4 };
				break;

			case "Delivery Success (%) - DSP":
				deliverySuccessPercDSPArray = new String[] { week1, week2,
						week3, week4 };
				break;

			case "First Day Delivery Success %":
				firstDayDeliverySuccessPercArray = new String[] { week1, week2,
						week3, week4 };
				break;

			case "Delivery Attempt":
				deliveryAttemptsArray = new String[] { week1, week2, week3,
						week4 };
				break;

			case "DNR DPMO":
				dnrDMPOArray = new String[] { week1, week2, week3, week4 };
				break;

			case "Packages Delivered Not Received (DNR)":
				packagesDeliveredNotRecArray = new String[] { week1, week2,
						week3, week4 };
				break;

			case "Shipments Per On Zone Hour":
				shipmentsPerZoneHrArray = new String[] { week1, week2, week3,
						week4 };
				break;

			case "Return To Station DPMO":
				returnToStationDPMOArray = new String[] { week1, week2, week3,
						week4 };
				break;

			case "Packages Returned to Station (RTS)":
				packagesReturnedToStationArray = new String[] { week1, week2,
						week3, week4 };
				break;

			case "Packages Returned to Station (RTS) %":
				packagesReturnedToStationPercArray = new String[] { week1,
						week2, week3, week4 };
				break;

			case "Rescued Packages":
				rescuedPackagesArray = new String[] { week1, week2, week3,
						week4 };
				break;

			case "RTS Packages Unable to Access":
				rtsPackagesUnableToAccessArray = new String[] { week1, week2,
						week3, week4 };
				break;

			case "RTS Packages Unable to Access %":
				rtsPackagesUnableToAccessPercArray = new String[] { week1,
						week2, week3, week4 };
				break;

			case "RTS Packages Customer Unavailable":
				rtsPackagesCustomerUnavailableArray = new String[] { week1,
						week2, week3, week4 };
				break;

			case "RTS Packages Customer Unavailable %":
				rtsPackagesCustomerUnavailablePercArray = new String[] { week1,
						week2, week3, week4 };
				break;

			case "RTS Packages Unable to Locate":
				rtsPackagesUnableToLocateArray = new String[] { week1, week2,
						week3, week4 };
				break;

			case "RTS Packages Unable to Locate %":
				rtsPackagesUnableToLocatePercArray = new String[] { week1,
						week2, week3, week4 };
				break;

			case "RTS Packages No Secure Location":
				rtsPackagesNoSecureLocationArray = new String[] { week1, week2,
						week3, week4 };
				break;

			case "RTS Packages No Secure Location %":
				rtsPackagesNoSecureLocationPercArray = new String[] { week1,
						week2, week3, week4 };
				break;

			case "RTS Packages Unsafe Due to Dog":
				rtsPackagesUnsafeDueToDogArray = new String[] { week1, week2,
						week3, week4 };
				break;

			case "RTS Packages Unsafe Due to Dog %":
				rtsPackagesUnsafeDueToDogPercArray = new String[] { week1,
						week2, week3, week4 };
				break;

			case "RTS Packages Out of Drive Time":
				rtsPackagesOutofDriveTimeArray = new String[] { week1, week2,
						week3, week4 };
				break;

			case "RTS Packages Out of Drive Time %":
				rtsPackagesOutofDriveTimePrecArray = new String[] { week1,
						week2, week3, week4 };
				break;

			case "RTS Packages Business Closed":
				rtsPackagesBusinessClosedArray = new String[] { week1, week2,
						week3, week4 };
				break;

			case "RTS Packages Business Closed %":
				rtsPackagesBusinessClosedPrecArray = new String[] { week1,
						week2, week3, week4 };
				break;

			case "Packages Returned to Station, Other":
				packagesReturnedToStationOthersArray = new String[] { week1,
						week2, week3, week4 };
				break;

			case "Packages Returned to Station, Other %":
				packagesReturnedToStationOthersPrecArray = new String[] { week1,
						week2, week3, week4 };
				break;

			case "Packages Not On Van":
				packagesNotOnVanArray = new String[] { week1, week2, week3,
						week4 };
				break;

			case "POD Opportunities":
				podOpportunitesArray = new String[] { week1, week2, week3,
						week4 };
				break;

			case "POD Success":
				podSuccessArray = new String[] { week1, week2, week3, week4 };
				break;

			case "POD Success Rate":
				podSuccessPrecArray = new String[] { week1, week2, week3,
						week4 };
				break;
			}
		}

		for (int i = 0; i < deliveryWeekArray.length; i++) {
			List<String> insList = new ArrayList<String>();
			String selQry = "SELECT " + tableName + "ID FROM " + tableName
					+ " WHERE ENTITYID=" + entityID + " AND STATUS="
					+ RecordStatus.ACTIVE + " AND DELIVERY_YEAR="
					+ deliveryYearArray[i] + " AND DELIVERY_WEEK="
					+ deliveryWeekArray[i];
			String recordID = db.selectById(selQry);
			if (recordID.length() > 0) {
				insList.add(buildStatusQry(tableName, tableName + "ID",
						recordID, RecordStatus.DELETE, loginUser));
			}

			String autoIncrementArray[] = db
					.getAutoIncrementArray(tableName + "ID");

			String insQry = "INSERT INTO " + tableName + " (";
			if (autoIncrementArray != null)
				insQry += autoIncrementArray[0];
			insQry += "ENTITYID, DELIVERY_YEAR, DELIVERY_WEEK, COMPLETED_ROUTES, "
					+ "DISPATCHED_PACKAGES, DILIVERED_PACKAGES, "
					+ "DILIVERY_SUCCESS_PERCENT, DILIVERY_SUCCESS_PERCENT_DSP, "
					+ "FIRSTDAY_DELIVERY_SUCCESS_PERCENT, DELIVERY_ATTEMPTS, "
					+ "DNR_DPMO, PACKAGES_DELIVERED_NOT_RECEIVED, SHIPMENTS_PER_ZONE_HOUR, "
					+ "RETURN_TO_STATION_DPMO, PACKAGES_RETURNED_TO_STATION, "
					+ "PACKAGES_RETURNED_TO_STATION_PERCENT, RESCUED_PACKAGES, "
					+ "RTSPACKAGES_UNABLE_TO_ACCESS, RTSPACKAGES_UNABLE_TO_ACCESS_PERCENT, "
					+ "RTSPACKAGES_CUSTOMER_UNAVAILABLE, RTSPACKAGES_CUSTOMER_UNAVAILABLE_PERCENT, "
					+ "RTSPACKAGES_UNABLE_TO_LOCATE, RTSPACKAGES_UNABLE_TO_LOCATE_PERCENT, "
					+ "RTSPACKAGES_NO_SECURE_LOCATION, RTSPACKAGES_NO_SECURE_LOCATION_PERCENT, "
					+ "RTSPACKAGES_UNSAFE_DUETO_DOG, RTSPACKAGES_UNSAFE_DUETO_DOG_PERCENT, "
					+ "RTSPACKAGES_OUTOF_DRIVETIME, RTSPACKAGES_OUTOF_DRIVETIME_PERCENT, "
					+ "RTSPACKAGES_BUSINESS_CLOSED, RTSPACKAGES_BUSINESS_CLOSED_PERCENT, "
					+ "PACKAGES_RETURNED_TO_STATION_OTH, PACKAGES_RETURNED_TO_STATION_OTH_PERCENT, "
					+ "PACKAGES_NOT_ON_VAN, POD_OPPORTUNITIES, "
					+ "POD_SUCCESS, POD_SUCCESS_PERCENT, CREATE_USER, "
					+ "CREATE_DATE, STATUS) VALUES (";
			if (autoIncrementArray != null)
				insQry += autoIncrementArray[1];
			insQry += entityID + ", "
					+ db.getInsertDBValue(deliveryYearArray[i]) + ", "
					+ db.getInsertDBValue(deliveryWeekArray[i]) + ", "
					+ db.getInsertDBValue(completedRoutesArray[i]) + ", "
					+ db.getInsertDBValue(dispatchedPackagesArray[i]) + ", "
					+ db.getInsertDBValue(deliveredPackagesArray[i]) + ", "
					+ db.getInsertDBValue(deliverySuccessPercArray[i]) + ", "
					+ db.getInsertDBValue(deliverySuccessPercDSPArray[i]) + ", "
					+ db.getInsertDBValue(firstDayDeliverySuccessPercArray[i])
					+ ", " + db.getInsertDBValue(deliveryAttemptsArray[i])
					+ ", " + db.getInsertDBValue(dnrDMPOArray[i]) + ", "
					+ db.getInsertDBValue(packagesDeliveredNotRecArray[i])
					+ ", " + db.getInsertDBValue(shipmentsPerZoneHrArray[i])
					+ ", " + db.getInsertDBValue(returnToStationDPMOArray[i])
					+ ", "
					+ db.getInsertDBValue(packagesReturnedToStationArray[i])
					+ ", "
					+ db.getInsertDBValue(packagesReturnedToStationPercArray[i])
					+ ", " + db.getInsertDBValue(rescuedPackagesArray[i]) + ", "
					+ db.getInsertDBValue(rtsPackagesUnableToAccessArray[i])
					+ ", "
					+ db.getInsertDBValue(rtsPackagesUnableToAccessPercArray[i])
					+ ", "
					+ db.getInsertDBValue(
							rtsPackagesCustomerUnavailableArray[i])
					+ ", "
					+ db.getInsertDBValue(
							rtsPackagesCustomerUnavailablePercArray[i])
					+ ", "
					+ db.getInsertDBValue(rtsPackagesUnableToLocateArray[i])
					+ ", "
					+ db.getInsertDBValue(rtsPackagesUnableToLocatePercArray[i])
					+ ", "
					+ db.getInsertDBValue(rtsPackagesNoSecureLocationArray[i])
					+ ", "
					+ db.getInsertDBValue(
							rtsPackagesNoSecureLocationPercArray[i])
					+ ", "
					+ db.getInsertDBValue(rtsPackagesUnsafeDueToDogArray[i])
					+ ", "
					+ db.getInsertDBValue(rtsPackagesUnsafeDueToDogPercArray[i])
					+ ", "
					+ db.getInsertDBValue(rtsPackagesOutofDriveTimeArray[i])
					+ ", "
					+ db.getInsertDBValue(rtsPackagesOutofDriveTimePrecArray[i])
					+ ", "
					+ db.getInsertDBValue(rtsPackagesBusinessClosedArray[i])
					+ ", "
					+ db.getInsertDBValue(rtsPackagesBusinessClosedPrecArray[i])
					+ ", "
					+ db.getInsertDBValue(
							packagesReturnedToStationOthersArray[i])
					+ ", "
					+ db.getInsertDBValue(
							packagesReturnedToStationOthersPrecArray[i])
					+ ", " + db.getInsertDBValue(packagesNotOnVanArray[i])
					+ ", " + db.getInsertDBValue(podOpportunitesArray[i]) + ", "
					+ db.getInsertDBValue(podSuccessArray[i]) + ", "
					+ db.getInsertDBValue(podSuccessPrecArray[i]) + ", "
					+ db.getInsertDBValue(loginUser) + ", "
					+ db.getInsertSysdate() + ", " + RecordStatus.ACTIVE + ")";
			insList.add(insQry);

			boolean result = db.batchInsert(insList);
			if (result)
				numOfRows++;
		}

		return numOfRows;
	}

	public double insQualityOverview(String tableName, String week1,
			List columnsList, List dataList, String loginUser, String entityID)
			throws Exception {

		double numOfRows = 0;
		for (int i = 0; i < dataList.size(); i++) {
			List tempList = (ArrayList) dataList.get(i);
			String week = getListDBData(tempList, 0);
			String deliveryAssociate = getListDBData(tempList, 1);
			String transporterID = getListDBData(tempList, 2);
			String overallQualityScore = getListDBData(tempList, 3);

			String dcr = getListDBData(tempList, 4);
			String dsb = getListDBData(tempList, 5);
			String pod = getListDBData(tempList, 6);
			String swcCC = getListDBData(tempList, 7);
			String swcAD = getListDBData(tempList, 8);
			String packagesDelivered = getListDBData(tempList, 9);

			String dnr = getListDBData(tempList, 10);
			String dnrDPMO = getListDBData(tempList, 11);
			String packagesDispatched = getListDBData(tempList, 12);
			String packagesReturnedToStation = getListDBData(tempList, 13);
			String rtsBusinessClosed = getListDBData(tempList, 14);
			String rtsCustomerUnavailable = getListDBData(tempList, 15);

			String rtsNoSecureLocation = getListDBData(tempList, 16);
			String rtsOther = getListDBData(tempList, 17);
			String rtsOutOfDriveTime = getListDBData(tempList, 18);
			String rtsUnableToAccess = getListDBData(tempList, 19);
			String rtsUnableToLocate = getListDBData(tempList, 20);
			String podSuccess = getListDBData(tempList, 21);
			String podOpportunites = getListDBData(tempList, 22);
			String cdfDPMO = getListDBData(tempList, 23);
			String ced = getListDBData(tempList, 24);

			String year = "";
			String splitArray[] = week.split("-");
			if (splitArray.length > 0)
				year = splitArray[0];
			if (splitArray.length > 1)
				week = splitArray[1];

			if (transporterID.length() > 0) {
				if (week.startsWith("0") && week.length() > 1)
					week = week.substring(1);

				List<String> insList = new ArrayList<String>();
				String selQry = "SELECT " + tableName + "ID FROM " + tableName
						+ " WHERE STATUS=" + RecordStatus.ACTIVE
						+ db.getDataInCondQuery(transporterID, "TRANSPORTERID")
						+ db.getIDInCondQuery(week, "QUALITY_WEEK")
						+ db.getIDInCondQuery(year, "QUALITY_YEAR")
						+ db.getIDInCondQuery(entityID, "ENTITYID");
				String recordID = db.selectById(selQry);
				if (recordID.length() > 0) {
					insList.add(buildStatusQry(tableName, tableName + "ID",
							recordID, RecordStatus.DELETE, loginUser));
				}

				String autoIncrementArray[] = db
						.getAutoIncrementArray(tableName + "ID");

				String insQry = "INSERT INTO " + tableName + " (";
				if (autoIncrementArray != null)
					insQry += autoIncrementArray[0];
				insQry += "ENTITYID, QUALITY_YEAR, QUALITY_WEEK, "
						+ "DELIVERYASSOCIATE, TRANSPORTERID, OVERALLQUALITYSCORE, "
						+ "DCR, DSB, POD, SWC_CC, SWC_AD, PACKAGESDELIVERED, DNR, "
						+ "DNR_DPMO, PACKAGES_DISPATCHED, PACKAGES_RETURNED, RTS_BUSINIESS_CLOSED, "
						+ "RTS_CUSTOMER_UNAVAILABLE, RTS_NO_SECURE_LOCATION, "
						+ "RTS_OTHER, RTS_OUT_OF_DRIVETIME, RTS_UNABLE_TO_ACCESS, "
						+ "RTS_UNABLE_TO_LOCATE, POD_SUCCESS, POD_OPPORTUNITIES, CDF_DPMO, CED, "
						+ "CREATE_USER, CREATE_DATE, STATUS) VALUES (";
				if (autoIncrementArray != null)
					insQry += autoIncrementArray[1];
				insQry += entityID + ", " + db.getInsertDBValue(year) + ", "
						+ db.getInsertDBValue(week) + ", "
						+ db.getInsertDBValue(deliveryAssociate) + ", "
						+ db.getInsertDBValue(transporterID) + ", "
						+ db.getInsertDBValue(overallQualityScore) + ", "
						+ db.getInsertDBValue(dcr) + ", "
						+ db.getInsertDBValue(dsb) + ", "
						+ db.getInsertDBValue(pod) + ", "
						+ db.getInsertDBValue(swcCC) + ", "
						+ db.getInsertDBValue(swcAD) + ", "
						+ db.getInsertDBValue(packagesDelivered) + ", "
						+ db.getInsertDBValue(dnr) + ", "
						+ db.getInsertDBValue(dnrDPMO) + ", "
						+ db.getInsertDBValue(packagesDispatched) + ", "
						+ db.getInsertDBValue(packagesReturnedToStation) + ", "
						+ db.getInsertDBValue(rtsBusinessClosed) + ", "
						+ db.getInsertDBValue(rtsCustomerUnavailable) + ", "
						+ db.getInsertDBValue(rtsNoSecureLocation) + ", "
						+ db.getInsertDBValue(rtsOther) + ", "
						+ db.getInsertDBValue(rtsOutOfDriveTime) + ", "
						+ db.getInsertDBValue(rtsUnableToAccess) + ", "
						+ db.getInsertDBValue(rtsUnableToLocate) + ", "
						+ db.getInsertDBValue(podSuccess) + ", "
						+ db.getInsertDBValue(podOpportunites) + ", "
						+ db.getInsertDBValue(cdfDPMO) + ", "
						+ db.getInsertDBValue(ced) + ", "
						+ db.getInsertDBValue(loginUser) + ", "
						+ db.getInsertSysdate() + ", " + RecordStatus.ACTIVE
						+ ")";
				insList.add(insQry);

				boolean result = db.batchInsert(insList);
				if (result)
					numOfRows++;
			}
		}

		return numOfRows;
	}

	public double insEscalations(String tableName, String week1,
			List columnsList, List dataList, String loginUser, String entityID)
			throws Exception {

		double numOfRows = 0;
		Map<String, String> _colNameMap = getTableColumnIndexMap(columnsList);
		for (int i = 0; i < dataList.size(); i++) {
			List tempList = (ArrayList) dataList.get(i);
			String country = getListDBData(tempList, "country", _colNameMap);
			String station = getListDBData(tempList, "station", _colNameMap);
			String dsp = getListDBData(tempList, "dsp", _colNameMap);
			String driver_transporter_id = getListDBData(tempList,
					"driver_transporter_id", _colNameMap);
			String da_name = getListDBData(tempList, "da_name", _colNameMap);
			String flagged_for_mdr_in_the_last_120_days = getListDBData(
					tempList, "flagged_for_mdr_in_the_last_120_days",
					_colNameMap);
			String total_defects_in_the_last_120_days = getListDBData(tempList,
					"total_defects_in_the_last_120_days", _colNameMap);
			String bucket = getListDBData(tempList, "bucket", _colNameMap);
			String category = getListDBData(tempList, "category", _colNameMap);
			String behavior = getListDBData(tempList, "behavior", _colNameMap);
			String scorecard_week = getListDBData(tempList, "scorecard_week",
					_colNameMap);
			String incident_date = getListDBData(tempList, "incident_date",
					_colNameMap);
			String dsp_notification_date = getListDBData(tempList,
					"dsp_notification_date", _colNameMap);
			String dsp_appealed_or_da_coaching_retraining_ack = getListDBData(
					tempList, "dsp_appealed_or_da_coaching_retraining_ack",
					_colNameMap);
			String week = getListDBData(tempList, "week", _colNameMap);
			String year = getListDBData(tempList, "year", _colNameMap);

			if ("N/A".equalsIgnoreCase(scorecard_week))
				scorecard_week = "0";

			if (driver_transporter_id.length() > 0) {
				incident_date = getFileDate(incident_date);
				dsp_notification_date = getFileDate(dsp_notification_date);

				if (week.startsWith("0") && week.length() > 1)
					week = week.substring(1);

				List<String> insList = new ArrayList<String>();
				String selQry = "SELECT ESCALATIONSID FROM ESCALATIONS WHERE STATUS="
						+ RecordStatus.ACTIVE
						+ db.getDataInCondQuery(driver_transporter_id,
								"TRANSPORTERID")
						+ db.getIDInCondQuery(week, "ESCALATION_WEEK")
						+ db.getIDInCondQuery(year, "ESCALATION_YEAR")
						+ db.getIDInCondQuery(entityID, "ENTITYID");
				String recordID = db.selectById(selQry);
				if (recordID.length() > 0) {
					insList.add(buildStatusQry(tableName, tableName + "ID",
							recordID, RecordStatus.DELETE, loginUser));
				}

				String autoIncrementArray[] = db
						.getAutoIncrementArray("ESCALATIONSID");

				String insQry = "INSERT INTO ESCALATIONS (";
				if (autoIncrementArray != null)
					insQry += autoIncrementArray[0];
				insQry += "ENTITYID, ESCALATION_YEAR, ESCALATION_WEEK, "
						+ "DELIVERYASSOCIATE, TRANSPORTERID, TOTALDEFECTSINPAST, "
						+ "BUCKET, CATEGORY, BEHAVIOR, SCORECARD_WEEK, INCIDENT_DATE, "
						+ "DSP_NOTIFICATION_DATE, DSP_APPEALED, "
						+ "CREATE_USER, CREATE_DATE, STATUS) VALUES (";
				if (autoIncrementArray != null)
					insQry += autoIncrementArray[1];
				insQry += entityID + ", " + db.getInsertDBValue(year) + ", "
						+ db.getInsertDBValue(week) + ", "
						+ db.getInsertDBValue(da_name) + ", "
						+ db.getInsertDBValue(driver_transporter_id) + ", "
						+ db.getInsertDBValue(
								total_defects_in_the_last_120_days)
						+ ", " + db.getInsertDBValue(bucket) + ", "
						+ db.getInsertDBValue(category) + ", "
						+ db.getInsertDBValue(behavior) + ", "
						+ db.getInsertDBValue(scorecard_week) + ", "
						+ db.getInsertDate(incident_date) + ", "
						+ db.getInsertDate(dsp_notification_date) + ", "
						+ db.getInsertDBValue(
								dsp_appealed_or_da_coaching_retraining_ack)
						+ ", " + db.getInsertDBValue(loginUser) + ", "
						+ db.getInsertSysdate() + ", " + RecordStatus.ACTIVE
						+ ")";
				insList.add(insQry);

				boolean result = db.batchInsert(insList);
				if (result)
					numOfRows++;
			}
		}

		return numOfRows;
	}

	public double insDvic(String tableName, String week1, List columnsList,
			List dataList, String loginUser, String entityID) throws Exception {

		double numOfRows = 0;
		Map<String, String> _colNameMap = getTableColumnIndexMap(columnsList);
		String week = "", year = "";
		for (int i = 0; i < dataList.size(); i++) {
			List tempList = (ArrayList) dataList.get(i);
			String start_date = getListDBData(tempList, "start_date",
					_colNameMap);
			String dsp = getListDBData(tempList, "dsp", _colNameMap);
			String station = getListDBData(tempList, "station", _colNameMap);
			String transporter_id = getListDBData(tempList, "transporter_id",
					_colNameMap);
			String transporter_name = getListDBData(tempList,
					"transporter_name", _colNameMap);
			String vin = getListDBData(tempList, "vin", _colNameMap);
			String fleet_type = getListDBData(tempList, "fleet_type",
					_colNameMap);
			String inspection_type = getListDBData(tempList, "inspection_type",
					_colNameMap);
			String inspection_status = getListDBData(tempList,
					"inspection_status", _colNameMap);
			String start_time = getListDBData(tempList, "start_time",
					_colNameMap);
			String end_time = getListDBData(tempList, "end_time", _colNameMap);
			String duration = getListDBData(tempList, "duration", _colNameMap);

			if (transporter_id.length() > 0) {
				GregorianCalendar dateCal = new GregorianCalendar();
				dateCal.setTime(sdfYYYY_D_MM_D_DD.parse(start_date));
				start_date = sdfMMDDYYYY.format(dateCal.getTime());
				if (week.length() == 0) {
					week = dateCal.get(Calendar.WEEK_OF_YEAR) + "";
					year = dateCal.get(Calendar.YEAR) + "";
				}

				List<String> insList = new ArrayList<String>();
				String selQry = "SELECT DVICID FROM DVIC WHERE STATUS="
						+ RecordStatus.ACTIVE
						+ db.getDataInCondQuery(transporter_id, "TRANSPORTERID")
						+ db.getIDInCondQuery(week, "DVIC_WEEK")
						+ db.getIDInCondQuery(year, "DVIC_YEAR")
						+ db.getIDInCondQuery(entityID, "ENTITYID")
						+ db.getDateCondTypeQuery(db.EQUALS_TO, "STARTDATE",
								start_date);

				String recordID = db.selectById(selQry);
				if (recordID.length() > 0) {
					insList.add(buildStatusQry(tableName, tableName + "ID",
							recordID, RecordStatus.DELETE, loginUser));
				}

				String autoIncrementArray[] = db
						.getAutoIncrementArray("DVICID");

				String insQry = "INSERT INTO DVIC (";
				if (autoIncrementArray != null)
					insQry += autoIncrementArray[0];
				insQry += "ENTITYID, DVIC_YEAR, DVIC_WEEK, "
						+ "STARTDATE, DSP, STATION, TRANSPORTERID, "
						+ "TRANSPORTERNAME, VINNUMBER, VEHICLETYPE, "
						+ "INSPECTIONTYPE, INSPECTIONSTATUS, "
						+ "STARTTIME, ENDTIME, DURATION, "
						+ "CREATE_USER, CREATE_DATE, STATUS) VALUES (";
				if (autoIncrementArray != null)
					insQry += autoIncrementArray[1];
				insQry += entityID + ", " + db.getInsertDBValue(year) + ", "
						+ db.getInsertDBValue(week) + ", "
						+ db.getInsertDate(start_date) + ", "
						+ db.getInsertDBValue(dsp) + ", "
						+ db.getInsertDBValue(station) + ", "
						+ db.getInsertDBValue(transporter_id) + ", "
						+ db.getInsertDBValue(transporter_name) + ", "
						+ db.getInsertDBValue(vin) + ", "
						+ db.getInsertDBValue(fleet_type) + ", "
						+ db.getInsertDBValue(inspection_type) + ", "
						+ db.getInsertDBValue(inspection_status) + ", "
						+ db.getInsertDateFormat(
								start_time, db.ORACLE_YYYYDMMDDD24HRDMIDSS)
						+ ", "
						+ db.getInsertDateFormat(end_time,
								db.ORACLE_YYYYDMMDDD24HRDMIDSS)
						+ ", " + db.getInsertDBValue(duration) + ", "
						+ db.getInsertDBValue(loginUser) + ", "
						+ db.getInsertSysdate() + ", " + RecordStatus.ACTIVE
						+ ")";
				insList.add(insQry);

				boolean result = db.batchInsert(insList);
				if (result)
					numOfRows++;
			}
		}

		return numOfRows;
	}

	public double insDashboardOverview(String tableName, String week1,
			List columnsList, List dataList, String loginUser, String entityID)
			throws Exception {

		double numOfRows = 0;
		Map<String, String> _colNameMap = getTableColumnIndexMap(columnsList);
		for (int i = 0; i < dataList.size(); i++) {
			List tempList = (ArrayList) dataList.get(i);
			String week = getListDBData(tempList, 0);
			String delivery_associate = getListDBData(tempList,
					"delivery_associate", _colNameMap);
			String transporter_id = getListDBData(tempList, "transporter_id",
					_colNameMap);
			String overall_standing = getListDBData(tempList,
					"overall_standing", _colNameMap);
			String overall_score = getListDBData(tempList, "overall_score",
					_colNameMap, true);

			String fico_metric = getListDBData(tempList, "fico_metric",
					_colNameMap, true);
			String fico_tier = getListDBData(tempList, "fico_tier",
					_colNameMap);
			String fico_score = getListDBData(tempList, "fico_score",
					_colNameMap, true);

			String speeding_event_rate_per_trip = getListDBData(tempList,
					"speeding_event_rate_per_trip", _colNameMap, true);
			String speeding_event_rate_tier = getListDBData(tempList,
					"speeding_event_rate_tier", _colNameMap);
			String speeding_event_rate_score = getListDBData(tempList,
					"speeding_event_rate_score", _colNameMap, true);

			String seatbelt_off_rate_per_trip = getListDBData(tempList,
					"seatbelt_off_rate_per_trip", _colNameMap, true);
			String seatbelt_off_rate_tier = getListDBData(tempList,
					"seatbelt_off_rate_tier", _colNameMap);
			String seatbelt_off_rate_score = getListDBData(tempList,
					"seatbelt_off_rate_score", _colNameMap, true);

			String distractions_rate_per_trip = getListDBData(tempList,
					"distractions_rate_per_trip", _colNameMap, true);
			String distractions_rate_tier = getListDBData(tempList,
					"distractions_rate_tier", _colNameMap);
			String distractions_rate_score = getListDBData(tempList,
					"distractions_rate_score", _colNameMap, true);

			String sign_signal_violations_rate_per_trip = getListDBData(
					tempList, "sign_signal_violations_rate_per_trip",
					_colNameMap, true);
			String sign_signal_violations_rate_tier = getListDBData(tempList,
					"sign_signal_violations_rate_tier", _colNameMap);
			String sign_signal_violations_rate_score = getListDBData(tempList,
					"sign_signal_violations_rate_score", _colNameMap, true);

			String following_distance_rate_per_trip = getListDBData(tempList,
					"following_distance_rate_per_trip", _colNameMap, true);
			String following_distance_rate_tier = getListDBData(tempList,
					"following_distance_rate_tier", _colNameMap);
			String following_distance_rate_score = getListDBData(tempList,
					"following_distance_rate_score", _colNameMap, true);

			String cdf_dpmo = getListDBData(tempList, "cdf_dpmo", _colNameMap,
					true);
			String cdf_dpmo_tier = getListDBData(tempList, "cdf_dpmo_tier",
					_colNameMap);
			String cdf_dpmo_score = getListDBData(tempList, "cdf_dpmo_score",
					_colNameMap, true);

			String ced = getListDBData(tempList, "ced", _colNameMap, true);
			String ced_tier = getListDBData(tempList, "ced_tier", _colNameMap);
			String ced_score = getListDBData(tempList, "ced_score", _colNameMap,
					true);

			String dcr = getListDBData(tempList, "dcr", _colNameMap, true);
			String dcr_tier = getListDBData(tempList, "dcr_tier", _colNameMap);
			String dcr_score = getListDBData(tempList, "dcr_score", _colNameMap,
					true);
			/* newer scorecard bundles label these "Delivery Completion DPMO" */
			if (dcr.length() == 0)
				dcr = getListDBData(tempList, "delivery_completion_dpmo",
						_colNameMap, true);
			if (dcr_tier.length() == 0)
				dcr_tier = getListDBData(tempList,
						"delivery_completion_dpmo_tier", _colNameMap);
			if (dcr_score.length() == 0)
				dcr_score = getListDBData(tempList,
						"delivery_completion_dpmo_score", _colNameMap, true);

			String dsb = getListDBData(tempList, "dsb", _colNameMap, true);
			String dsb_dpmo_tier = getListDBData(tempList, "dsb_dpmo_tier",
					_colNameMap);
			String dsb_dpmo_score = getListDBData(tempList, "dsb_dpmo_score",
					_colNameMap, true);

			String pod = getListDBData(tempList, "pod", _colNameMap, true);
			String pod_tier = getListDBData(tempList, "pod_tier", _colNameMap);
			String pod_score = getListDBData(tempList, "pod_score", _colNameMap,
					true);

			String psb = getListDBData(tempList, "psb", _colNameMap, true);
			String psb_tier = getListDBData(tempList, "psb_tier", _colNameMap);
			String psb_score = getListDBData(tempList, "psb_score", _colNameMap,
					true);

			String packages_delivered = getListDBData(tempList,
					"packages_delivered", _colNameMap, true);

			/*-
			String delivered_packages = getListDBData(tempList,
					"delivered_packages", _colNameMap);
			String key_focus_area = getListDBData(tempList, "key_focus_area",
					_colNameMap);
			String on_road_safety_score = getListDBData(tempList,
					"on_road_safety_score", _colNameMap);
			String overall_quality_score = getListDBData(tempList,
					"overall_quality_score", _colNameMap);
			String fico = getListDBData(tempList, "fico", _colNameMap);
			String acceleration = getListDBData(tempList, "acceleration",
					_colNameMap);
			String braking = getListDBData(tempList, "braking", _colNameMap);
			String cornering = getListDBData(tempList, "cornering",
					_colNameMap);
			String distraction = getListDBData(tempList, "distraction",
					_colNameMap);
			String seatbelt_off_rate = getListDBData(tempList,
					"seatbelt_off_rate", _colNameMap);
			String speeding = getListDBData(tempList, "speeding", _colNameMap);
			String speeding_event_rate = getListDBData(tempList,
					"speeding_event_rate", _colNameMap);
			String distractions_rate = getListDBData(tempList,
					"distractions_rate", _colNameMap);
			String looking_at_phone = getListDBData(tempList,
					"looking_at_phone", _colNameMap);
			String talking_on_phone = getListDBData(tempList,
					"talking_on_phone", _colNameMap);
			String looking_down = getListDBData(tempList, "looking_down",
					_colNameMap);
			String following_distance_rate = getListDBData(tempList,
					"following_distance_rate", _colNameMap);
			String sign_signal_violations_rate = getListDBData(tempList,
					"sign_signal_violations_rate", _colNameMap);
			String stop_sign_violations = getListDBData(tempList,
					"stop_sign_violations", _colNameMap);
			String stop_light_violations = getListDBData(tempList,
					"stop_light_violations", _colNameMap);
			String illegal_u_turns = getListDBData(tempList, "illegal_u_turns",
					_colNameMap);
			String cdf_dpmo = getListDBData(tempList, "cdf_dpmo", _colNameMap);
			String dcr = getListDBData(tempList, "dcr", _colNameMap);
			String dsb = getListDBData(tempList, "dsb", _colNameMap);
			String swc_pod = getListDBData(tempList, "swc_pod", _colNameMap);
			String swc_cc = getListDBData(tempList, "swc_cc", _colNameMap);
			String swc_ad = getListDBData(tempList, "swc_ad", _colNameMap);
			String dnrs = getListDBData(tempList, "dnrs", _colNameMap);
			String shipments_per_on_zone_hour = getListDBData(tempList,
					"shipments_per_on_zone_hour", _colNameMap);
			String pod_opps = getListDBData(tempList, "pod_opps", _colNameMap);
			String cc_opps = getListDBData(tempList, "cc_opps", _colNameMap);
			String customer_escalation_defect = getListDBData(tempList,
					"customer_escalation_defect", _colNameMap);
			String customer_delivery_feedback = getListDBData(tempList,
					"customer_delivery_feedback", _colNameMap);
			*/

			String year = "";
			String splitArray[] = week.split("-");
			if (splitArray.length > 0)
				year = splitArray[0].trim();
			if (splitArray.length > 1)
				week = splitArray[1].trim();
			week = week.replaceAll("W", "");
			if (transporter_id.length() > 0) {
				if (week.startsWith("0") && week.length() > 1)
					week = week.substring(1);

				List<String> insList = new ArrayList<String>();
				String selQry = "SELECT DASHBOARD_OVERVIEWID FROM DASHBOARD_OVERVIEW "
						+ "WHERE STATUS=" + RecordStatus.ACTIVE
						+ db.getDataInCondQuery(transporter_id, "TRANSPORTERID")
						+ db.getIDInCondQuery(week, "DASHBOARD_WEEK")
						+ db.getIDInCondQuery(year, "DASHBOARD_YEAR")
						+ db.getIDInCondQuery(entityID, "ENTITYID");

				String recordID = db.selectById(selQry);
				if (recordID.length() > 0) {
					insList.add(buildStatusQry(tableName, tableName + "ID",
							recordID, RecordStatus.DELETE, loginUser));
				}
				String key_focus_area = "";
				String on_road_safety_score = "";
				String overall_quality_score = "";
				// String fico = "";
				String acceleration = "";
				String braking = "";
				String cornering = "";
				String distraction = "";
				// String seatbelt_off_rate = "";
				String speeding = "";
				// String speeding_event_rate = "";
				// String distractions_rate = "";
				String looking_at_phone = "";
				String talking_on_phone = "";
				String looking_down = "";
				// String following_distance_rate = "";
				// String sign_signal_violations_rate = "";
				String stop_sign_violations = "";
				String stop_light_violations = "";
				String illegal_u_turns = "";
				String swc_pod = "";
				String swc_cc = "";
				String swc_ad = "";
				String dnrs = "";
				String shipments_per_on_zone_hour = "";
				// String pod_opps = "";
				String cc_opps = "";
				// String customer_escalation_defect = "";
				String customer_delivery_feedback = "";

				String autoIncrementArray[] = db
						.getAutoIncrementArray("DASHBOARD_OVERVIEWID");
				String insQry = "INSERT INTO DASHBOARD_OVERVIEW (";
				if (autoIncrementArray != null)
					insQry += autoIncrementArray[0];
				insQry += "ENTITYID, DASHBOARD_YEAR, DASHBOARD_WEEK, DELIVERYASSOCIATE, "
						+ "TRANSPORTERID, OVERALLSTANDING, DELIVEREDPACKAGES, "
						+ "KEYFOCUSAREA, ONROADSAFETYSCORE, OVERALLQUALITYSCORE, "
						+ "FICO, ACCELERATION, BRAKING, CORNERING, DISTRACTION, "
						+ "SEATBELTOFFRATE, SPEEDING, SPEEDINGEVENTRATE, "
						+ "DISTRACTIONRATE, LOOKINGATPHONE, TALKINGONPHONE, LOOKINGDOWN, "
						+ "FOLLOWINGDISTANCERATE, SIGNORSIGNALVIOLATIONRATE, STOPSIGNVIOLATIONS, "
						+ "STOPLIGHTVIOLATIONS, ILLEGALUTURNS, CDFDPMO, DCR, DSB, SWCPOD, SWCCC, "
						+ "SWCAD, DNRS, SHIPMENTSPERZONEHOUR, PODOPPS, CCOPPS, CUSTESCALATIONDEFECT, "
						+ "CUSTDELIVERYFEEDBACK, "

						// New Columns
						+ "OVERALLSCORE, FICOTIER, FICOSCORE, "
						+ "SPEEDINGEVENTRATETIER, SPEEDINGEVENTRATESCORE, "
						+ "SEATBELTOFFRATETIER, SEATBELTOFFRATESCORE, "
						+ "DISTRACTIONRATETIER, DISTRACTIONRATESCORE, "
						+ "SIGNORSIGNALVIOLATIONRATETIER, SIGNORSIGNALVIOLATIONRATESCORE, "
						+ "FOLLOWINGDISTANCERATETIER, FOLLOWINGDISTANCERATESCORE, "
						+ "CDFDPMOTIER, CDFDPMOSCORE, CEDTIER, CEDSCORE, "
						+ "DCRTIER, DCRSCORE, DSBDPMOTIER, DSBDPMOSCORE, "
						+ "PODTIER, PODSCORE, PSB, PSBTIER, PSBSCORE, "
						+ "CREATE_USER, CREATE_DATE, STATUS) VALUES (";
				if (autoIncrementArray != null)
					insQry += autoIncrementArray[1];
				insQry += entityID + ", " + db.getInsertDBValue(year) + ", "
						+ db.getInsertDBValue(week) + ", "
						+ db.getInsertDBValue(delivery_associate) + ", "
						+ db.getInsertDBValue(transporter_id) + ", "
						+ db.getInsertDBValue(overall_standing) + ", "
						+ db.getInsertDBValue(packages_delivered) + ", "
						+ db.getInsertDBValue(key_focus_area) + ", "
						+ db.getInsertDBValue(on_road_safety_score) + ", "
						+ db.getInsertDBValue(overall_quality_score) + ", "
						+ db.getInsertDBValue(fico_metric) + ", "
						+ db.getInsertDBValue(acceleration) + ", "
						+ db.getInsertDBValue(braking) + ", "
						+ db.getInsertDBValue(cornering) + ", "
						+ db.getInsertDBValue(distraction) + ", "
						+ db.getInsertDBValue(seatbelt_off_rate_per_trip) + ", "
						+ db.getInsertDBValue(speeding) + ", "
						+ db.getInsertDBValue(speeding_event_rate_per_trip)
						+ ", " + db.getInsertDBValue(distractions_rate_per_trip)
						+ ", " + db.getInsertDBValue(looking_at_phone) + ", "
						+ db.getInsertDBValue(talking_on_phone) + ", "
						+ db.getInsertDBValue(looking_down) + ", "
						+ db.getInsertDBValue(following_distance_rate_per_trip)
						+ ", "
						+ db.getInsertDBValue(
								sign_signal_violations_rate_per_trip)
						+ ", " + db.getInsertDBValue(stop_sign_violations)
						+ ", " + db.getInsertDBValue(stop_light_violations)
						+ ", " + db.getInsertDBValue(illegal_u_turns) + ", "
						+ db.getInsertDBValue(cdf_dpmo) + ", "
						+ db.getInsertDBValue(dcr) + ", "
						+ db.getInsertDBValue(dsb) + ", "
						+ db.getInsertDBValue(swc_pod) + ", "
						+ db.getInsertDBValue(swc_cc) + ", "
						+ db.getInsertDBValue(swc_ad) + ", "
						+ db.getInsertDBValue(dnrs) + ", "
						+ db.getInsertDBValue(shipments_per_on_zone_hour) + ", "
						+ db.getInsertDBValue(pod) + ", "
						+ db.getInsertDBValue(cc_opps) + ", "
						+ db.getInsertDBValue(ced) + ", "
						+ db.getInsertDBValue(customer_delivery_feedback) + ", "

						// New Columns
						+ db.getInsertDBValue(overall_score) + ", "
						+ db.getInsertDBValue(fico_tier) + ", "
						+ db.getInsertDBValue(fico_score) + ", "

						+ db.getInsertDBValue(speeding_event_rate_tier) + ", "
						+ db.getInsertDBValue(speeding_event_rate_score) + ", "

						+ db.getInsertDBValue(seatbelt_off_rate_tier) + ", "
						+ db.getInsertDBValue(seatbelt_off_rate_score) + ", "

						+ db.getInsertDBValue(distractions_rate_tier) + ", "
						+ db.getInsertDBValue(distractions_rate_score) + ", "

						+ db.getInsertDBValue(sign_signal_violations_rate_tier)
						+ ", "
						+ db.getInsertDBValue(sign_signal_violations_rate_score)
						+ ", "

						+ db.getInsertDBValue(following_distance_rate_tier)
						+ ", "
						+ db.getInsertDBValue(following_distance_rate_score)
						+ ", "

						+ db.getInsertDBValue(cdf_dpmo_tier) + ", "
						+ db.getInsertDBValue(cdf_dpmo_score) + ", "

						+ db.getInsertDBValue(ced_tier) + ", "
						+ db.getInsertDBValue(ced_score) + ", "

						+ db.getInsertDBValue(dcr_tier) + ", "
						+ db.getInsertDBValue(dcr_score) + ", "

						+ db.getInsertDBValue(dsb_dpmo_tier) + ", "
						+ db.getInsertDBValue(dsb_dpmo_score) + ", "

						+ db.getInsertDBValue(pod_tier) + ", "
						+ db.getInsertDBValue(pod_score) + ", "

						+ db.getInsertDBValue(psb) + ", "
						+ db.getInsertDBValue(psb_tier) + ", "
						+ db.getInsertDBValue(psb_score) + ", "

						+ db.getInsertDBValue(loginUser) + ", "
						+ db.getInsertSysdate() + ", " + RecordStatus.ACTIVE
						+ ")";
				insList.add(insQry);
				boolean result = db.batchInsert(insList);
				if (result)
					numOfRows++;
			}
		}

		return numOfRows;
	}

	public double insEngineOffCompliance(String fileName,
			List<String> columnsList, List dataList, String loginUser,
			String entityID) throws Exception {

		double numOfRows = 0;

		String eocYear = "";
		String eocWeek = "";
		String station = "";

		if (fileName.length() > 0) {
			// US-MVPG-DNK7-Week13-2025_20250330_EOC_Last_7_Days
			String splitArray[] = fileName.split("-");
			if (splitArray.length > 2)
				station = splitArray[2].trim();

			if (splitArray.length > 3)
				eocWeek = splitArray[3].replaceAll("Week", "").trim();

			if (splitArray.length > 4) {
				eocYear = splitArray[4].trim();
				if (eocYear.indexOf("_") != -1) {
					splitArray = eocYear.split("_");
					if (splitArray.length > 0)
						eocYear = splitArray[0].trim();
				}
			}
		}

		String date1Val = "";
		String date2Val = "";
		String date3Val = "";
		String date4Val = "";
		String date5Val = "";
		String date6Val = "";
		String date7Val = "";

		if (columnsList.size() > 0) {
			String day1 = getListDBData(columnsList, 2);
			String day2 = getListDBData(columnsList, 3);
			String day3 = getListDBData(columnsList, 4);
			String day4 = getListDBData(columnsList, 5);
			String day5 = getListDBData(columnsList, 6);
			String day6 = getListDBData(columnsList, 7);
			String day7 = getListDBData(columnsList, 8);

			date1Val = getFileDate(day1);
			date2Val = getFileDate(day2);
			date3Val = getFileDate(day3);
			date4Val = getFileDate(day4);
			date5Val = getFileDate(day5);
			date6Val = getFileDate(day6);
			date7Val = getFileDate(day7);

			// db.update("DELETE FROM EOCOVERVIEW");
			// db.update("DELETE FROM EOCOVERVIEWTRANS");
		}

		for (int i = 0; i < dataList.size(); i++) {
			List tempList = (ArrayList) dataList.get(i);
			String transporter_id = getListDBData(tempList, 0);
			String da_name = getListDBData(tempList, 1);
			String day1 = getListDBData(tempList, 2);
			String day2 = getListDBData(tempList, 3);
			String day3 = getListDBData(tempList, 4);
			String day4 = getListDBData(tempList, 5);
			String day5 = getListDBData(tempList, 6);
			String day6 = getListDBData(tempList, 7);
			String day7 = getListDBData(tempList, 8);
			String currentAverage = getListDBData(tempList, 9);

			if (transporter_id.length() > 0) {
				if ("transporter_id".equalsIgnoreCase(transporter_id)) {

				} else {
					List<String> insList = new ArrayList<String>();
					String selQry = "SELECT EOCOVERVIEWID FROM EOCOVERVIEW "
							+ "WHERE STATUS=" + RecordStatus.ACTIVE
							+ db.getIDInCondQuery(eocYear, "EOC_YEAR")
							+ db.getIDInCondQuery(eocWeek, "EOC_WEEK")
							+ db.getDataInCondQuery(transporter_id,
									"TRANSPORTERID")
							+ db.getIDInCondQuery(entityID, "ENTITYID");
					String recordID = db.selectById(selQry);
					if (recordID.length() > 0)
						insList.add(buildStatusQry("EOCOVERVIEW",
								"EOCOVERVIEWID", recordID, RecordStatus.DELETE,
								loginUser));

					recordID = db.getNextIDValue("EOCOVERVIEWID");
					insList = buildEOCMainsQry(recordID, eocYear, eocWeek,
							station, transporter_id, currentAverage, loginUser,
							entityID, insList);

					insList = buildEOCTransQry(recordID, date1Val, day1,
							loginUser, insList);
					insList = buildEOCTransQry(recordID, date2Val, day2,
							loginUser, insList);
					insList = buildEOCTransQry(recordID, date3Val, day3,
							loginUser, insList);
					insList = buildEOCTransQry(recordID, date4Val, day4,
							loginUser, insList);
					insList = buildEOCTransQry(recordID, date5Val, day5,
							loginUser, insList);
					insList = buildEOCTransQry(recordID, date6Val, day6,
							loginUser, insList);
					insList = buildEOCTransQry(recordID, date7Val, day7,
							loginUser, insList);
					boolean result = db.batchInsert(insList);
					if (result)
						numOfRows++;
				}

			} else if (da_name.length() > 0) {
				if ("dsp_shortcode".equalsIgnoreCase(da_name)) {

				} else {
					transporter_id = da_name;
					List<String> insList = new ArrayList<String>();
					String selQry = "SELECT EOCOVERVIEWID FROM EOCOVERVIEW "
							+ "WHERE STATUS=" + RecordStatus.ACTIVE
							+ db.getIDInCondQuery(eocYear, "EOC_YEAR")
							+ db.getIDInCondQuery(eocWeek, "EOC_WEEK")
							+ db.getDataInCondQuery(transporter_id,
									"TRANSPORTERID")
							+ db.getIDInCondQuery(entityID, "ENTITYID");
					String recordID = db.selectById(selQry);
					if (recordID.length() > 0)
						insList.add(buildStatusQry("EOCOVERVIEW",
								"EOCOVERVIEWID", recordID, RecordStatus.DELETE,
								loginUser));

					recordID = db.getNextIDValue("EOCOVERVIEWID");
					insList = buildEOCMainsQry(recordID, eocYear, eocWeek,
							station, transporter_id, currentAverage, loginUser,
							entityID, insList);

					insList = buildEOCTransQry(recordID, date1Val, day1,
							loginUser, insList);
					insList = buildEOCTransQry(recordID, date2Val, day2,
							loginUser, insList);
					insList = buildEOCTransQry(recordID, date3Val, day3,
							loginUser, insList);
					insList = buildEOCTransQry(recordID, date4Val, day4,
							loginUser, insList);
					insList = buildEOCTransQry(recordID, date5Val, day5,
							loginUser, insList);
					insList = buildEOCTransQry(recordID, date6Val, day6,
							loginUser, insList);
					insList = buildEOCTransQry(recordID, date7Val, day7,
							loginUser, insList);
					boolean result = db.batchInsert(insList);
					if (result)
						numOfRows++;
				}
			}
		}

		return numOfRows;
	}

	public List<String> buildEOCMainsQry(String recordID, String eocYear,
			String eocWeek, String station, String transporter_id,
			String currentAverage, String loginUser, String entityID,
			List<String> insList) throws Exception {

		if (currentAverage.length() > 0) {
			float floatVal = Float.parseFloat(currentAverage) * 100;
			currentAverage = df.format(floatVal);
		}

		String insQry = "INSERT INTO EOCOVERVIEW (EOCOVERVIEWID, "
				+ "ENTITYID, EOC_YEAR, EOC_WEEK, STATION, TRANSPORTERID, "
				+ "CURRENT_AVERAGE, CREATE_USER, CREATE_DATE, STATUS) VALUES ("
				+ recordID + ", " + entityID + ", "
				+ db.getInsertDBValue(eocYear) + ", "
				+ db.getInsertDBValue(eocWeek) + ", "
				+ db.getInsertDBValue(station) + ", "
				+ db.getInsertDBValue(transporter_id) + ", "
				+ db.getInsertDBValue(currentAverage) + ", "
				+ db.getInsertDBValue(loginUser) + ", " + db.getInsertSysdate()
				+ ", " + RecordStatus.ACTIVE + ")";
		insList.add(insQry);

		return insList;
	}

	public List<String> buildEOCTransQry(String recordID, String eocDate,
			String average, String loginUser, List<String> insList)
			throws Exception {

		if (average.length() > 0) {
			float floatVal = Float.parseFloat(average) * 100;
			average = df.format(floatVal);
		}

		String autoIncrementArray[] = db
				.getAutoIncrementArray("EOCOVERVIEWTRANSID");
		String insQry = "INSERT INTO EOCOVERVIEWTRANS (";
		if (autoIncrementArray != null)
			insQry += autoIncrementArray[0];
		insQry += "EOCOVERVIEWID, EOC_DATE, DAILY_AVERAGE, "
				+ "CREATE_USER, CREATE_DATE, STATUS) VALUES (";
		if (autoIncrementArray != null)
			insQry += autoIncrementArray[1];
		insQry += recordID + ", " + db.getInsertDate(eocDate) + ", "
				+ db.getInsertDBValue(average) + ", "
				+ db.getInsertDBValue(loginUser) + ", " + db.getInsertSysdate()
				+ ", " + RecordStatus.ACTIVE + ")";
		insList.add(insQry);

		return insList;
	}

	public double insDailyRoutes(String fileName, List<String> columnsList,
			List dataList, String loginUser, String entityID) throws Exception {

		double numOfRows = 0;
		String station = "";
		String route_date = "";
		String year = "", week = "";
		Map<String, String> _colNameMap = getTableColumnIndexMap(columnsList);

		if (fileName.length() > 0) {
			// Routes_DNK7_2025-05-03_14_20 (EDT)
			String splitArray[] = fileName.split("_");
			if (splitArray.length > 1)
				station = splitArray[1].trim();
			if (splitArray.length > 2)
				route_date = splitArray[2].trim();

			if (route_date.length() > 0) {
				GregorianCalendar dateCal = new GregorianCalendar();
				dateCal.setTime(sdfYYYY_D_MM_D_DD.parse(route_date));
				route_date = sdfMMDDYYYY.format(dateCal.getTime());
				if (week.length() == 0) {
					week = dateCal.get(Calendar.WEEK_OF_YEAR) + "";
					year = dateCal.get(Calendar.YEAR) + "";
				}
			}
		}

		for (int i = 0; i < dataList.size(); i++) {
			List tempList = (ArrayList) dataList.get(i);
			String route_code = getListDBData(tempList, "route_code",
					_colNameMap);
			String dsp = getListDBData(tempList, "dsp", _colNameMap);
			String transporter_id = getListDBData(tempList, "transporter_id",
					_colNameMap);
			String driver_name = getListDBData(tempList, "driver_name",
					_colNameMap);
			String route_progress = getListDBData(tempList, "route_progress",
					_colNameMap);
			String delivery_service_type = getListDBData(tempList,
					"delivery_service_type", _colNameMap);
			String route_duration = getListDBData(tempList, "route_duration",
					_colNameMap);
			String all_stops = getListDBData(tempList, "all_stops",
					_colNameMap);
			String stops_complete = getListDBData(tempList, "stops_complete",
					_colNameMap);
			String not_started_stops = getListDBData(tempList,
					"not_started_stops", _colNameMap);

			String transporter_id_Array[] = transporter_id.split("\\|");
			String driver_name_Array[] = driver_name.split("\\|");
			for (int j = 0; j < transporter_id_Array.length; j++) {
				transporter_id = transporter_id_Array[j].trim();
				driver_name = driver_name_Array[j].trim();

				List<String> insList = new ArrayList<String>();

				String selQry = "SELECT DAILYROUTESID FROM DAILYROUTES WHERE ENTITYID="
						+ entityID + " AND STATUS=" + RecordStatus.ACTIVE
						+ db.getDateCondTypeQuery(db.EQUALS_TO, "ROUTEDATE",
								route_date)
						+ db.getDataInCondQuery(transporter_id, "TRANSPORTERID")
						+ db.getDataInCondQuery(route_code, "ROUTECODE");

				String recordID = db.selectById(selQry);
				if (recordID.length() > 0)
					insList.add(buildStatusQry("DAILYROUTES", "DAILYROUTESID",
							recordID, RecordStatus.ACTIVE, loginUser));

				String autoIncrementArray[] = db
						.getAutoIncrementArray("DAILYROUTESID");

				String insQry = "INSERT INTO DAILYROUTES (";
				if (autoIncrementArray != null)
					insQry += autoIncrementArray[0];
				insQry += "ENTITYID, ROUTECODE, ROUTEDATE, ROUTE_WEEK, "
						+ "ROUTE_YEAR, STATION, TRANSPORTERID, TRANSPORTERNAME, "
						+ "ROUTEPROGRESS, SERVICETYPE, ROUTEDURATION, ALLSTOPS, "
						+ "COMPLETEDSTOPS, NOTSTARTEDSTOPS, "
						+ "CREATE_USER, CREATE_DATE, STATUS) VALUES (";
				if (autoIncrementArray != null)
					insQry += autoIncrementArray[1];
				insQry += entityID + ", " + db.getInsertDBValue(route_code)
						+ ", " + db.getInsertDate(route_date) + ", "
						+ db.getInsertDBValue(week) + ", "
						+ db.getInsertDBValue(year) + ", "
						+ db.getInsertDBValue(station) + ", "
						+ db.getInsertDBValue(transporter_id) + ", "
						+ db.getInsertDBValue(driver_name) + ", "
						+ db.getInsertDBValue(route_progress) + ", "
						+ db.getInsertDBValue(delivery_service_type) + ", "
						+ db.getInsertDBValue(route_duration) + ", "
						+ db.getInsertDBValue(all_stops) + ", "
						+ db.getInsertDBValue(stops_complete) + ", "
						+ db.getInsertDBValue(not_started_stops) + ", "
						+ db.getInsertDBValue(loginUser) + ", "
						+ db.getInsertSysdate() + ", " + RecordStatus.ACTIVE
						+ ")";
				insList.add(insQry);

				boolean result = db.batchInsert(insList);
				if (result)
					numOfRows++;
			}
		}

		return numOfRows;
	}

	public boolean createDailyRouteRecord(String route_code, String route_date,
			String week, String year, String station, String transporter_id,
			String driver_name, String route_progress,
			String delivery_service_type, String route_duration,
			String all_stops, String stops_complete, String not_started_stops,
			String loginUser, String entityID) throws Exception {

		List<String> insList = new ArrayList<String>();

		String selQry = "SELECT DAILYROUTESID FROM DAILYROUTES WHERE ENTITYID="
				+ entityID + " AND STATUS=" + RecordStatus.ACTIVE
				+ db.getDateCondTypeQuery(db.EQUALS_TO, "ROUTEDATE", route_date)
				+ db.getDataInCondQuery(transporter_id, "TRANSPORTERID")
				+ db.getDataInCondQuery(route_code, "ROUTECODE");

		String recordID = db.selectById(selQry);
		if (recordID.length() > 0)
			insList.add(buildStatusQry("DAILYROUTES", "DAILYROUTESID", recordID,
					RecordStatus.ACTIVE, loginUser));

		String autoIncrementArray[] = db.getAutoIncrementArray("DAILYROUTESID");

		String insQry = "INSERT INTO DAILYROUTES (";
		if (autoIncrementArray != null)
			insQry += autoIncrementArray[0];
		insQry += "ENTITYID, ROUTECODE, ROUTEDATE, ROUTE_WEEK, "
				+ "ROUTE_YEAR, STATION, TRANSPORTERID, TRANSPORTERNAME, "
				+ "ROUTEPROGRESS, SERVICETYPE, ROUTEDURATION, ALLSTOPS, "
				+ "COMPLETEDSTOPS, NOTSTARTEDSTOPS, "
				+ "CREATE_USER, CREATE_DATE, STATUS) VALUES (";
		if (autoIncrementArray != null)
			insQry += autoIncrementArray[1];
		insQry += entityID + ", " + db.getInsertDBValue(route_code) + ", "
				+ db.getInsertDate(route_date) + ", "
				+ db.getInsertDBValue(week) + ", " + db.getInsertDBValue(year)
				+ ", " + db.getInsertDBValue(station) + ", "
				+ db.getInsertDBValue(transporter_id) + ", "
				+ db.getInsertDBValue(driver_name) + ", "
				+ db.getInsertDBValue(route_progress) + ", "
				+ db.getInsertDBValue(delivery_service_type) + ", "
				+ db.getInsertDBValue(route_duration) + ", "
				+ db.getInsertDBValue(all_stops) + ", "
				+ db.getInsertDBValue(stops_complete) + ", "
				+ db.getInsertDBValue(not_started_stops) + ", "
				+ db.getInsertDBValue(loginUser) + ", " + db.getInsertSysdate()
				+ ", " + RecordStatus.ACTIVE + ")";
		insList.add(insQry);

		boolean result = db.batchInsert(insList);

		return result;
	}

	public double insStationLevel(String fileName, List<String> columnsList,
			List dataList, String loginUser, String entityID) throws Exception {

		double numOfRows = 0;
		String station = "";
		if (fileName.length() > 0) {
			// Station_Level_Metrics_DNK7_2025-W18
			String splitArray[] = fileName.split("_");
			if (splitArray.length > 3)
				station = splitArray[3].trim();
		}

		for (int i = 0; i < dataList.size(); i++) {
			List tempList = (ArrayList) dataList.get(i);
			String week = getListDBData(tempList, 0);
			String dsp = getListDBData(tempList, 1);
			String dispatched_packages = getListDBData(tempList, 2);
			String delivered_packages = getListDBData(tempList, 3);
			String delivered_not_received_dnr = getListDBData(tempList, 4);
			String dnr_dpmo = getListDBData(tempList, 5);
			String returned_to_station_rts = getListDBData(tempList, 6);
			String rts_ = getListDBData(tempList, 7).replaceAll("%", "");
			String rts_dpmo = getListDBData(tempList, 8);

			String year = "";
			String splitArray[] = week.split("-");
			if (splitArray.length > 0)
				year = splitArray[0].trim();
			if (splitArray.length > 1)
				week = splitArray[1].trim();

			List<String> insList = new ArrayList<String>();

			String selQry = "SELECT STATIONMETRICSID FROM STATIONMETRICS WHERE ENTITYID="
					+ entityID + " AND STATUS=" + RecordStatus.ACTIVE
					+ db.getIDInCondQuery(week, "METRIC_WEEK")
					+ db.getIDInCondQuery(year, "METRIC_YEAR")
					+ db.getDataInCondQuery(station, "STATION");

			String recordID = db.selectById(selQry);
			if (recordID.length() > 0)
				insList.add(buildStatusQry("STATIONMETRICS", "STATIONMETRICSID",
						recordID, RecordStatus.ACTIVE, loginUser));

			String autoIncrementArray[] = db
					.getAutoIncrementArray("STATIONMETRICSID");

			String insQry = "INSERT INTO STATIONMETRICS (";
			if (autoIncrementArray != null)
				insQry += autoIncrementArray[0];
			insQry += "ENTITYID, METRIC_WEEK, METRIC_YEAR, STATION, "
					+ "DISPATCHED_PACKAGES, DELIVERED_PACKAGES, "
					+ "DELIVERED_NOTRECEIVED, DNRDPMO, RETURNEDTOSTATION, "
					+ "RETURNEDTOSTATIONPERCENT, RETURNEDTOSTATIONDPMO, "
					+ "CREATE_USER, CREATE_DATE, STATUS) VALUES (";
			if (autoIncrementArray != null)
				insQry += autoIncrementArray[1];
			insQry += entityID + ", " + db.getInsertDBValue(week) + ", "
					+ db.getInsertDBValue(year) + ", "
					+ db.getInsertDBValue(station) + ", "
					+ db.getInsertDBValue(dispatched_packages) + ", "
					+ db.getInsertDBValue(delivered_packages) + ", "
					+ db.getInsertDBValue(delivered_not_received_dnr) + ", "
					+ db.getInsertDBValue(dnr_dpmo) + ", "
					+ db.getInsertDBValue(returned_to_station_rts) + ", "
					+ db.getInsertDBValue(rts_) + ", "
					+ db.getInsertDBValue(rts_dpmo) + ", "
					+ db.getInsertDBValue(loginUser) + ", "
					+ db.getInsertSysdate() + ", " + RecordStatus.ACTIVE + ")";
			insList.add(insQry);

			boolean result = db.batchInsert(insList);
			if (result)
				numOfRows++;
		}

		return numOfRows;
	}

	public double insDeliveredPackages(String fileName,
			List<String> columnsList, List dataList, String loginUser,
			String entityID) throws Exception {

		double numOfRows = 0;
		String week = "", year = "";
		for (int i = 0; i < dataList.size(); i++) {
			List tempList = (ArrayList) dataList.get(i);
			String date = getListDBData(tempList, 0);
			String station = getListDBData(tempList, 1);
			String dsp_short_code = getListDBData(tempList, 2);
			String package_count = getListDBData(tempList, 3);
			String package_details = getListDBData(tempList, 4);
			String package_type = getListDBData(tempList, 5);

			if (station.contains("(") && station.contains(")"))
				station = station.substring(station.indexOf("(") + 1,
						station.indexOf(")"));

			date = getFileDate(date);
			if (i == 0 && date.length() > 0) {
				GregorianCalendar dateCal = new GregorianCalendar();
				dateCal.setTime(sdfMMDDYYYY.parse(date));
				if (week.length() == 0) {
					week = dateCal.get(Calendar.WEEK_OF_YEAR) + "";
					year = dateCal.get(Calendar.YEAR) + "";
				}
			}

			List<String> insList = new ArrayList<String>();
			String selQry = "SELECT WST_DELIVEREDPACKAGESID FROM "
					+ "WST_DELIVEREDPACKAGES WHERE ENTITYID=" + entityID
					+ " AND STATUS=" + RecordStatus.ACTIVE
					+ db.getDataInCondQuery(station, "STATION")
					+ db.getDataInCondQuery(package_details, "PACKAGEDETAILS")
					+ db.getDataInCondQuery(package_type, "PACKAGETYPE")
					+ db.getDateCondTypeQuery(db.EQUALS_TO, "WST_PACKAGEDATE",
							date);

			String recordID = db.selectById(selQry);
			if (recordID.length() > 0)
				insList.add(buildStatusQry("WST_DELIVEREDPACKAGES",
						"WST_DELIVEREDPACKAGESID", recordID,
						RecordStatus.ACTIVE, loginUser));

			String autoIncrementArray[] = db
					.getAutoIncrementArray("WST_DELIVEREDPACKAGESID");

			String insQry = "INSERT INTO WST_DELIVEREDPACKAGES (";
			if (autoIncrementArray != null)
				insQry += autoIncrementArray[0];
			insQry += "ENTITYID, WST_PACKAGEWEEK, WST_PACKAGEYEAR, WST_PACKAGEDATE, "
					+ "STATION, PACKAGECOUNT, PACKAGEDETAILS, PACKAGETYPE, "
					+ "CREATE_USER, CREATE_DATE, STATUS) VALUES (";
			if (autoIncrementArray != null)
				insQry += autoIncrementArray[1];
			insQry += entityID + ", " + db.getInsertDBValue(week) + ", "
					+ db.getInsertDBValue(year) + ", " + db.getInsertDate(date)
					+ ", " + db.getInsertDBValue(station) + ", "
					+ db.getInsertDBValue(package_count) + ", "
					+ db.getInsertDBValue(package_details) + ", "
					+ db.getInsertDBValue(package_type) + ", "
					+ db.getInsertDBValue(loginUser) + ", "
					+ db.getInsertSysdate() + ", " + RecordStatus.ACTIVE + ")";
			insList.add(insQry);

			boolean result = db.batchInsert(insList);
			if (result)
				numOfRows++;
		}

		return numOfRows;
	}

	public double insServiceDetails(String fileName, List<String> columnsList,
			List dataList, String loginUser, String entityID) throws Exception {

		double numOfRows = 0;
		String week = "", year = "";
		for (int i = 0; i < dataList.size(); i++) {
			List tempList = (ArrayList) dataList.get(i);
			String date = getListDBData(tempList, 0);
			String station = getListDBData(tempList, 1);
			String dsp_short_code = getListDBData(tempList, 2);
			String delivery_associate = getListDBData(tempList, 3);
			String route = getListDBData(tempList, 4);
			String service_type = getListDBData(tempList, 5);
			String planned_duration = getListDBData(tempList, 6);
			String log_in = getListDBData(tempList, 7);
			String log_out = getListDBData(tempList, 8);
			String total_distance_planned = getListDBData(tempList, 9);
			String total_distance_allowance = getListDBData(tempList, 10);
			String distance_unit = getListDBData(tempList, 11);
			String shipments_delivered = getListDBData(tempList, 12);
			String shipments_returned = getListDBData(tempList, 13);
			String pickup_packages = getListDBData(tempList, 14);
			String excluded = getListDBData(tempList, 15);

			if (station.contains("(") && station.contains(")"))
				station = station.substring(station.indexOf("(") + 1,
						station.indexOf(")"));

			date = getFileDate(date);
			if (i == 0 && date.length() > 0) {
				GregorianCalendar dateCal = new GregorianCalendar();
				dateCal.setTime(sdfMMDDYYYY.parse(date));
				if (week.length() == 0) {
					week = dateCal.get(Calendar.WEEK_OF_YEAR) + "";
					year = dateCal.get(Calendar.YEAR) + "";
				}
			}

			if (log_in.length() > 0) {
				log_in = log_in.substring(0, 19);
				log_in = log_in.replace("T", " ");
			}

			if (log_out.length() > 0) {
				log_out = log_out.substring(0, 19);
				log_out = log_out.replace("T", " ");
			}

			List<String> insList = new ArrayList<String>();
			String selQry = "SELECT WST_SERVICEDETAILSID FROM "
					+ "WST_SERVICEDETAILS WHERE ENTITYID=" + entityID
					+ " AND STATUS=" + RecordStatus.ACTIVE
					+ db.getDataInCondQuery(station, "STATION")
					+ db.getDataInCondQuery(service_type, "SERVICETYPE")
					+ db.getDataInCondQuery(route, "ROUTE")
					+ db.getDataInCondQuery(delivery_associate,
							"DELIVERYASSOCIATE")
					+ db.getDateCondTypeQuery(db.EQUALS_TO, "WST_SERVICEDATE",
							date);

			String recordID = db.selectById(selQry);
			if (recordID.length() > 0)
				insList.add(buildStatusQry("WST_SERVICEDETAILS",
						"WST_SERVICEDETAILSID", recordID, RecordStatus.ACTIVE,
						loginUser));

			String autoIncrementArray[] = db
					.getAutoIncrementArray("WST_SERVICEDETAILSID");

			String insQry = "INSERT INTO WST_SERVICEDETAILS (";
			if (autoIncrementArray != null)
				insQry += autoIncrementArray[0];
			insQry += "ENTITYID, WST_SERVICEWEEK, WST_SERVICEYEAR, "
					+ "WST_SERVICEDATE, STATION, DELIVERYASSOCIATE, "
					+ "ROUTE, SERVICETYPE, PLANNEDDURATION, LOGINTIME, "
					+ "LOGOUTTIME, TOTALDISTANCEPLANNED, TOTALDISTANCEALLOWANCE, "
					+ "DISTANCEUNIT, SHIPMENTSDELIVERED, SHIPMENTSRETURNED, "
					+ "PICKUPPACKAGES, EXCLUDED, CREATE_USER, CREATE_DATE, "
					+ "STATUS) VALUES (";
			if (autoIncrementArray != null)
				insQry += autoIncrementArray[1];
			insQry += entityID + ", " + db.getInsertDBValue(week) + ", "
					+ db.getInsertDBValue(year) + ", " + db.getInsertDate(date)
					+ ", " + db.getInsertDBValue(station) + ", "
					+ db.getInsertDBValue(delivery_associate) + ", "
					+ db.getInsertDBValue(route) + ", "
					+ db.getInsertDBValue(service_type) + ", "
					+ db.getInsertDBValue(planned_duration) + ", "
					+ db.getInsertDateFormat(log_in,
							db.ORACLE_YYYYDMMDDD24HRDMIDSS)
					+ ", "
					+ db.getInsertDateFormat(log_out,
							db.ORACLE_YYYYDMMDDD24HRDMIDSS)
					+ ", " + db.getInsertDBValue(total_distance_planned) + ", "
					+ db.getInsertDBValue(total_distance_allowance) + ", "
					+ db.getInsertDBValue(distance_unit) + ", "
					+ db.getInsertDBValue(shipments_delivered) + ", "
					+ db.getInsertDBValue(shipments_returned) + ", "
					+ db.getInsertDBValue(pickup_packages) + ", "
					+ db.getInsertDBValue(excluded) + ", "
					+ db.getInsertDBValue(loginUser) + ", "
					+ db.getInsertSysdate() + ", " + RecordStatus.ACTIVE + ")";
			insList.add(insQry);

			boolean result = db.batchInsert(insList);
			if (result)
				numOfRows++;
		}

		return numOfRows;
	}

	public double insWeeklyReport(String fileName, List<String> columnsList,
			List dataList, String loginUser, String entityID) throws Exception {

		double numOfRows = 0;
		String week = "", year = "";

		for (int i = 0; i < dataList.size(); i++) {
			List tempList = (ArrayList) dataList.get(i);
			String date = getListDBData(tempList, 0);
			String station = getListDBData(tempList, 1);
			String dsp_short_code = getListDBData(tempList, 2);
			String service_type = getListDBData(tempList, 3);
			String planned_duration = getListDBData(tempList, 4);
			String total_distance_planned = getListDBData(tempList, 5);
			String total_distance_allowance = getListDBData(tempList, 6);
			String planned_distance_unit = getListDBData(tempList, 7);
			String amzl_late_cancel = getListDBData(tempList, 8);
			String dsp_late_cancel = getListDBData(tempList, 9);
			String quick_coverage = getListDBData(tempList, 10);
			String accepted = getListDBData(tempList, 11);
			String completed_routes = getListDBData(tempList, 12);

			if ("N/A".equalsIgnoreCase(amzl_late_cancel))
				amzl_late_cancel = "";
			if ("N/A".equalsIgnoreCase(dsp_late_cancel))
				dsp_late_cancel = "";
			if ("N/A".equalsIgnoreCase(quick_coverage))
				quick_coverage = "";
			if ("N/A".equalsIgnoreCase(accepted))
				accepted = "";
			if ("N/A".equalsIgnoreCase(completed_routes))
				completed_routes = "";

			if (station.contains("(") && station.contains(")"))
				station = station.substring(station.indexOf("(") + 1,
						station.indexOf(")"));

			date = getFileDate(date);
			if (i == 0 && date.length() > 0) {
				GregorianCalendar dateCal = new GregorianCalendar();
				dateCal.setTime(sdfMMDDYYYY.parse(date));
				if (week.length() == 0) {
					week = dateCal.get(Calendar.WEEK_OF_YEAR) + "";
					year = dateCal.get(Calendar.YEAR) + "";
				}
			}

			List<String> insList = new ArrayList<String>();
			String selQry = "SELECT WST_WEEKLYREPORTID FROM "
					+ "WST_WEEKLYREPORT WHERE ENTITYID=" + entityID
					+ " AND STATUS=" + RecordStatus.ACTIVE
					+ db.getDataInCondQuery(station, "STATION")
					+ db.getDataInCondQuery(service_type, "SERVICETYPE")
					+ db.getDateCondTypeQuery(db.EQUALS_TO, "WST_DATE", date);

			String recordID = db.selectById(selQry);
			if (recordID.length() > 0)
				insList.add(
						buildStatusQry("WST_WEEKLYREPORT", "WST_WEEKLYREPORTID",
								recordID, RecordStatus.ACTIVE, loginUser));

			String autoIncrementArray[] = db
					.getAutoIncrementArray("WST_WEEKLYREPORTID");

			String insQry = "INSERT INTO WST_WEEKLYREPORT (";
			if (autoIncrementArray != null)
				insQry += autoIncrementArray[0];
			insQry += "ENTITYID, WST_WEEK, WST_YEAR, WST_DATE, "
					+ "STATION, SERVICETYPE, PLANNEDDURATION, "
					+ "TOTALDISTANCEPLANNED, TOTALDISTANCEALLOWANCE, "
					+ "PLANNEDDISTANCEUNIT, AMZLLATECANCEL, DSPLATECANCEL, "
					+ "QUICKCOVERAGE, ACCEPTED, COMPLETEDROUTES, "
					+ "CREATE_USER, CREATE_DATE, STATUS) VALUES (";
			if (autoIncrementArray != null)
				insQry += autoIncrementArray[1];
			insQry += entityID + ", " + db.getInsertDBValue(week) + ", "
					+ db.getInsertDBValue(year) + ", " + db.getInsertDate(date)
					+ ", " + db.getInsertDBValue(station) + ", "
					+ db.getInsertDBValue(service_type) + ", "
					+ db.getInsertDBValue(planned_duration) + ", "
					+ db.getInsertDBValue(total_distance_planned) + ", "
					+ db.getInsertDBValue(total_distance_allowance) + ", "
					+ db.getInsertDBValue(planned_distance_unit) + ", "
					+ db.getInsertDBValue(amzl_late_cancel) + ", "
					+ db.getInsertDBValue(dsp_late_cancel) + ", "
					+ db.getInsertDBValue(quick_coverage) + ", "
					+ db.getInsertDBValue(accepted) + ", "
					+ db.getInsertDBValue(completed_routes) + ", "
					+ db.getInsertDBValue(loginUser) + ", "
					+ db.getInsertSysdate() + ", " + RecordStatus.ACTIVE + ")";
			insList.add(insQry);

			boolean result = db.batchInsert(insList);
			if (result)
				numOfRows++;
		}

		return numOfRows;
	}

	public double insAssociatesConcessions(String fileName,
			List<String> columnsList, List dataList, String loginUser,
			String entityID) throws Exception {

		double numOfRows = 0;
		String week = "", year = "", station = "";
		if (fileName.length() > 0) {
			// DSP_Associates_Concessions_DNK7_2025-W18
			String splitArray[] = fileName.split("_");
			if (splitArray.length > 3)
				station = splitArray[3].trim();
			if (splitArray.length > 4) {
				splitArray = splitArray[4].split("-");
				if (splitArray.length > 0)
					year = splitArray[0].trim();
				if (splitArray.length > 1)
					week = splitArray[1].replaceAll("W", "").trim();
			}
		}

		for (int i = 0; i < dataList.size(); i++) {
			List tempList = (ArrayList) dataList.get(i);
			String week1 = getListDBData(tempList, 0);
			String delivery_associate_name = getListDBData(tempList, 1);
			String delivery_associate_id = getListDBData(tempList, 2);
			String delivered_packages = getListDBData(tempList, 3)
					.replaceAll(",", "");
			String packages_delivered_not_received_dnr = getListDBData(tempList,
					4).replaceAll(",", "");
			String dsb_count = getListDBData(tempList, 5).replaceAll(",", "");
			String dsb_dpmo = getListDBData(tempList, 6).replaceAll(",", "");
			String dispatched_packages = getListDBData(tempList, 7)
					.replaceAll(",", "");
			String packages_returned_to_station__rts = getListDBData(tempList,
					8).replaceAll(",", "");
			String packages_returned_to_station__rts_perc = getListDBData(
					tempList, 9).replaceAll("%", "");
			String return_to_station_dpmo = getListDBData(tempList, 10)
					.replaceAll(",", "");

			if (i == 0 && week1.length() > 0) {
				if (week1.startsWith("-"))
					week1 = week1.substring(1, week1.length());

				String splitArray[] = week1.split("-");
				if (splitArray.length > 0)
					year = splitArray[0].trim();
				if (splitArray.length > 1)
					week = splitArray[1].replaceAll("W", "").trim();
			}

			List<String> insList = new ArrayList<String>();
			String selQry = "SELECT ASSOCIATE_CONCESSIONSID FROM "
					+ "ASSOCIATE_CONCESSIONS WHERE ENTITYID=" + entityID
					+ " AND STATUS=" + RecordStatus.ACTIVE
					+ db.getDataInCondQuery(station, "STATION")
					+ db.getIDInCondQuery(week, "CONCESSION_WEEK")
					+ db.getIDInCondQuery(year, "CONCESSION_YEAR")
					+ db.getDataInCondQuery(delivery_associate_id,
							"TRANSPORTERID");

			String recordID = db.selectById(selQry);
			if (recordID.length() > 0)
				insList.add(buildStatusQry("ASSOCIATE_CONCESSIONS",
						"ASSOCIATE_CONCESSIONSID", recordID,
						RecordStatus.ACTIVE, loginUser));

			String autoIncrementArray[] = db
					.getAutoIncrementArray("ASSOCIATE_CONCESSIONSID");

			String insQry = "INSERT INTO ASSOCIATE_CONCESSIONS (";
			if (autoIncrementArray != null)
				insQry += autoIncrementArray[0];
			insQry += "ENTITYID, CONCESSION_WEEK, CONCESSION_YEAR, "
					+ "STATION, DELIVERYASSOCIATE, TRANSPORTERID, "
					+ "DELIVEREDPACKAGES, PACKAGESDELIVEREDNOTRETURNED, "
					+ "DSBCOUNT, DSBDPMO, DISPATCHEDPACKAGES, "
					+ "PACKAGESRETURNEDTOSTATION, RETURNEDTOSTATIONPERCENT, "
					+ "RETURNTOSTATIONDPMO, CREATE_USER, CREATE_DATE, STATUS) VALUES (";
			if (autoIncrementArray != null)
				insQry += autoIncrementArray[1];
			insQry += entityID + ", " + db.getInsertDBValue(week) + ", "
					+ db.getInsertDBValue(year) + ", "
					+ db.getInsertDBValue(station) + ", "
					+ db.getInsertDBValue(delivery_associate_name) + ", "
					+ db.getInsertDBValue(delivery_associate_id) + ", "
					+ db.getInsertDBValue(delivered_packages) + ", "
					+ db.getInsertDBValue(packages_delivered_not_received_dnr)
					+ ", " + db.getInsertDBValue(dsb_count) + ", "
					+ db.getInsertDBValue(dsb_dpmo) + ", "
					+ db.getInsertDBValue(dispatched_packages) + ", "
					+ db.getInsertDBValue(packages_returned_to_station__rts)
					+ ", "
					+ db.getInsertDBValue(
							packages_returned_to_station__rts_perc)
					+ ", " + db.getInsertDBValue(return_to_station_dpmo) + ", "
					+ db.getInsertDBValue(loginUser) + ", "
					+ db.getInsertSysdate() + ", " + RecordStatus.ACTIVE + ")";
			insList.add(insQry);

			boolean result = db.batchInsert(insList);
			if (result)
				numOfRows++;
		}

		return numOfRows;
	}

	public double insDailyItineraries(String fileName, List<String> columnsList,
			List dataList, String loginUser, String entityID) throws Exception {

		double numOfRows = 0;
		String week = "", year = "", station = "";
		String itinarary_date = "";
		if (fileName.length() > 0) {
			// Itineraries_DNK7_2025-08-26_14_42 (EDT)
			String splitArray[] = fileName.split("_");
			if (splitArray.length > 1)
				station = splitArray[1].trim();
			if (splitArray.length > 2) {
				itinarary_date = splitArray[2];
				splitArray = itinarary_date.split("-");
				if (splitArray.length > 0)
					year = splitArray[0].trim();

				itinarary_date = getFileDate(itinarary_date);
				GregorianCalendar dateCal = new GregorianCalendar();
				dateCal.setTime(sdfMMDDYYYY.parse(itinarary_date));
				week = dateCal.get(Calendar.WEEK_OF_YEAR) + "";
			}
		}

		for (int i = 0; i < dataList.size(); i++) {
			List tempList = (ArrayList) dataList.get(i);
			String transporter_id = getListDBData(tempList, 0);
			String driver_name = getListDBData(tempList, 1);
			String dsp = getListDBData(tempList, 2);
			String da_activity = getListDBData(tempList, 3);
			String route_code = getListDBData(tempList, 4);
			String progress_status = getListDBData(tempList, 5);
			String projected_return_to_station = getListDBData(tempList, 6);
			String projected_overtime_duration_minutes = getListDBData(tempList,
					7);
			String delivery_service_type = getListDBData(tempList, 8);
			String cortex_vin_number = getListDBData(tempList, 9);
			String all_stops = getListDBData(tempList, 10);
			String stops_complete = getListDBData(tempList, 11);
			String not_started_stops = getListDBData(tempList, 12);
			String total_packages = getListDBData(tempList, 13);
			String cortex_avg_pace_stops_per_hour = getListDBData(tempList, 14);
			String cortex_remaining_state_of_charge = getListDBData(tempList,
					15);
			String app_sign_in = getListDBData(tempList, 16);
			String app_sign_out = getListDBData(tempList, 17);
			String cortex_last_stop_execution_time = getListDBData(tempList,
					18);
			String cortex_total_break_time_used = getListDBData(tempList, 19);

			if (route_code.contains("|")) {
				String splitArray[] = route_code.split("\\|");
				route_code = "";
				for (int j = 0; j < splitArray.length; j++) {
					splitArray[j] = splitArray[j].trim();
					if (splitArray[j].length() > 0) {
						if (route_code.length() > 0)
							route_code += ", ";
						route_code += splitArray[j];
					}
				}
			}

			if (!isInteger(cortex_total_break_time_used))
				cortex_total_break_time_used = "0";

			app_sign_in = getDateTime(itinarary_date, app_sign_in);
			app_sign_out = getDateTime(itinarary_date, app_sign_out);
			cortex_last_stop_execution_time = getDateTime(itinarary_date,
					cortex_last_stop_execution_time);

			List<String> insList = new ArrayList<String>();
			String selQry = "SELECT DAILY_ITINERARIESID FROM "
					+ "DAILY_ITINERARIES WHERE ENTITYID=" + entityID
					+ " AND STATUS=" + RecordStatus.ACTIVE
					+ db.getDataInCondQuery(station, "STATION")
					+ db.getIDInCondQuery(week, "ITINARARY_WEEK")
					+ db.getIDInCondQuery(year, "ITINARARY_YEAR")
					+ db.getDateCondTypeQuery(db.EQUALS_TO, "ITINARARYDATE",
							itinarary_date)
					+ db.getDataInCondQuery(transporter_id, "TRANSPORTERID");

			String recordID = db.selectById(selQry);
			if (recordID.length() > 0)
				insList.add(buildStatusQry("DAILY_ITINERARIES",
						"DAILY_ITINERARIESID", recordID, RecordStatus.ACTIVE,
						loginUser));

			String autoIncrementArray[] = db
					.getAutoIncrementArray("DAILY_ITINERARIESID");

			String insQry = "INSERT INTO DAILY_ITINERARIES (";
			if (autoIncrementArray != null)
				insQry += autoIncrementArray[0];
			insQry += "ENTITYID, ITINARARY_WEEK, ITINARARY_YEAR, "
					+ "ITINARARYDATE, ROUTECODE, STATION, "
					+ "TRANSPORTERID, TRANSPORTERNAME, ROUTEPROGRESS, "
					+ "PROJECTEDRETURN, PROJECTEDOVERTIME, SERVICETYPE, "
					+ "VINNUMBER, ALLSTOPS, COMPLETEDSTOPS, NOTSTARTEDSTOPS, "
					+ "TOALPACKAGES, AVG_PACE_STOP_PER_HOUR, REMAININGCHARGE, "
					+ "APP_SIGNIN, APP_SIGNOUT, LAST_STOP_TIME, TOTAL_BREAKTIME, "
					+ "CREATE_USER, CREATE_DATE, STATUS) VALUES (";
			if (autoIncrementArray != null)
				insQry += autoIncrementArray[1];
			insQry += entityID + ", " + db.getInsertDBValue(week) + ", "
					+ db.getInsertDBValue(year) + ", "
					+ db.getInsertDate(itinarary_date) + ", "
					+ db.getInsertDBValue(route_code) + ", "
					+ db.getInsertDBValue(station) + ", "
					+ db.getInsertDBValue(transporter_id) + ", "
					+ db.getInsertDBValue(driver_name) + ", "
					+ db.getInsertDBValue(progress_status) + ", "
					+ db.getInsertDBValue(projected_return_to_station) + ", "
					+ db.getInsertDBValue(projected_overtime_duration_minutes)
					+ ", " + db.getInsertDBValue(delivery_service_type) + ", "
					+ db.getInsertDBValue(cortex_vin_number) + ", "
					+ db.getInsertDBValue(all_stops) + ", "
					+ db.getInsertDBValue(stops_complete) + ", "
					+ db.getInsertDBValue(not_started_stops) + ", "
					+ db.getInsertDBValue(total_packages) + ", "
					+ db.getInsertDBValue(cortex_avg_pace_stops_per_hour) + ", "
					+ db.getInsertDBValue(cortex_remaining_state_of_charge)
					+ ", " + db.getInsertDateTime(app_sign_in) + ", "
					+ db.getInsertDateTime(app_sign_out) + ", "
					+ db.getInsertDateTime(cortex_last_stop_execution_time)
					+ ", " + db.getInsertDBValue(cortex_total_break_time_used)
					+ ", " + db.getInsertDBValue(loginUser) + ", "
					+ db.getInsertSysdate() + ", " + RecordStatus.ACTIVE + ")";
			insList.add(insQry);

			boolean result = db.batchInsert(insList);
			if (result)
				numOfRows++;
		}

		return numOfRows;
	}

	public String getDateTime(String itinarary_date, String actualTime)
			throws Exception {

		String time = actualTime;
		String splitArray[] = time.split(" ");
		if (splitArray.length == 3)
			time = splitArray[2].trim();

		else if (splitArray.length > 2)
			time = (splitArray[splitArray.length - 2] + " "
					+ splitArray[splitArray.length - 1]).trim();

		if (time.length() == 6)
			time = "0" + time;

		splitArray = time.split(" ");
		if (splitArray.length == 1) {
			time = time.toUpperCase();

			if (time.endsWith("AM"))
				time = time.substring(0, time.length() - 2) + " AM";
			if (time.endsWith("PM"))
				time = time.substring(0, time.length() - 2) + " PM";
		}

		String dateTime = itinarary_date + " " + time;

		Date date = sdfMMDDYYYY_HHCMM_AM.parse(dateTime);
		GregorianCalendar dateCal = new GregorianCalendar();
		dateCal.setTime(date);
		if (splitArray.length > 2)
			dateCal.add(Calendar.DAY_OF_YEAR, 1);

		return sdfMMDDYYYY_HHCMM_AM.format(dateCal.getTime());
	}

	public boolean isInteger(String str) {
		if (str == null || str.isEmpty()) {
			return false;
		}
		try {
			Integer.parseInt(str); // try converting to int
			return true;
		} catch (NumberFormatException e) {
			return false;
		}
	}

	// Station + year + week from filenames like
	// DSP_Customer_Delivery_Feedback_negative_DNK7_2026-W20.csv /
	// Quality_DCR_MVPG_DNK7_2026-W27.csv : last _token = year-Wweek,
	// token before it = station.
	private String[] getStationYearWeek(String fileName) {
		String station = "", year = "", week = "";
		if (fileName.indexOf(".") > 0)
			fileName = fileName.substring(0, fileName.lastIndexOf("."));
		String splitArray[] = fileName.split("_");
		if (splitArray.length > 1) {
			station = splitArray[splitArray.length - 2].trim();
			String yw[] = splitArray[splitArray.length - 1].split("-");
			if (yw.length > 0)
				year = yw[0].trim();
			if (yw.length > 1)
				week = yw[1].replaceAll("W", "").trim();
		}
		return new String[] { station, year, week };
	}

	// getListDBData doubles apostrophes but the deployed getInsertDBValue
	// backslash-escapes them again, so text would land double-escaped;
	// undo the doubling and let getInsertDBValue escape once.
	private String getListRawData(List tempList, int index) {
		return getListDBData(tempList, index).replace("''", "'");
	}

	// ISO datetime/date from the quality CSVs ('2026-05-10 12:14:39.932',
	// '2026-06-29'); millis stripped, blank -> NULL.
	private String getIsoDBDateTime(String value) {
		if (value == null)
			return "NULL";
		value = value.trim();
		if (value.length() == 0)
			return "NULL";
		if (value.length() > 19)
			value = value.substring(0, 19);
		return "'" + value.replaceAll("'", "''") + "'";
	}

	// "Delete and reload": re-uploading a file soft-deletes every row in the
	// file's scope (station/week) before the fresh rows go in, so rows removed
	// from a corrected file don't survive the re-upload.
	private void clearUploadScope(String tableName, String condQry,
			String loginUser) throws Exception {
		try {
			db.update("UPDATE " + tableName + " SET UPDATE_USER="
					+ db.getInsertDBValue(loginUser) + ", UPDATE_DATE="
					+ db.getInsertSysdate() + ", STATUS=" + RecordStatus.DELETE
					+ " WHERE STATUS!=" + RecordStatus.DELETE + condQry);
		} catch (Exception ex) {
			// nothing to clear on a first-time upload
		}
	}

	/* Column positions in Amazon's CSVs move between report versions (W28
	   inserted 'Tracking ID' early and added 'Dispute status'), so resolve
	   every column BY HEADER NAME. Exact normalized match wins over
	   contains-match so 'Delivery Associate' can't grab '... Name'. */
	private static String normHdr(String s) {
		return s == null ? "" : s.toLowerCase().replaceAll("[^a-z0-9]", "");
	}

	private int colIdx(List<String> columnsList, String... names) {
		for (String n : names) {
			String key = normHdr(n);
			for (int i = 0; i < columnsList.size(); i++)
				if (normHdr(columnsList.get(i)).equals(key))
					return i;
		}
		for (String n : names) {
			String key = normHdr(n);
			for (int i = 0; i < columnsList.size(); i++)
				if (normHdr(columnsList.get(i)).contains(key))
					return i;
		}
		return -1;
	}

	private String byHdr(List tempList, List<String> columnsList,
			String... names) {
		int i = colIdx(columnsList, names);
		return i < 0 ? "" : getListRawData(tempList, i);
	}

	public double insCdfFeedback(String fileName, List<String> columnsList,
			List dataList, String loginUser, String entityID) throws Exception {

		double numOfRows = 0;
		String stationYW[] = getStationYearWeek(fileName);
		String station = stationYW[0], year = stationYW[1], week = stationYW[2];

		if (week.length() > 0)
			clearUploadScope("CDF_FEEDBACK", " AND ENTITYID=" + entityID
					+ " AND CDF_YEAR=" + year + " AND CDF_WEEK=" + week
					+ db.getDataInCondQuery(station, "STATION"), loginUser);

		for (int i = 0; i < dataList.size(); i++) {
			List tempList = (ArrayList) dataList.get(i);
			String transporterID = byHdr(tempList, columnsList, "Delivery Associate");
			String daName = byHdr(tempList, columnsList, "Delivery Associate Name");
			String impactsScorecard = byHdr(tempList, columnsList, "Impacts Scorecard");
			String mishandled = byHdr(tempList, columnsList, "DA Mishandled Package");
			String unprofessional = byHdr(tempList, columnsList, "DA was Unprofessional");
			String notFollowInstructions = byHdr(tempList, columnsList, "did not follow my delivery instructions");
			String wrongAddress = byHdr(tempList, columnsList, "Delivered to Wrong Address");
			String neverReceived = byHdr(tempList, columnsList, "Never Received Delivery");
			String wrongItem = byHdr(tempList, columnsList, "Received Wrong Item");
			String feedbackDetails = byHdr(tempList, columnsList, "Feedback Details");
			String trackingID = byHdr(tempList, columnsList, "Tracking ID");
			String deliveryDate = byHdr(tempList, columnsList, "Delivery Date");
			String disputeStatus = byHdr(tempList, columnsList, "Dispute status");
			if (transporterID.length() == 0 && trackingID.length() == 0)
				continue;

			String autoIncrementArray[] = db
					.getAutoIncrementArray("CDF_FEEDBACKID");

			String insQry = "INSERT INTO CDF_FEEDBACK (";
			if (autoIncrementArray != null)
				insQry += autoIncrementArray[0];
			insQry += "ENTITYID, STATION, CDF_WEEK, CDF_YEAR, TRANSPORTERID, "
					+ "DELIVERYASSOCIATE, IMPACTS_SCORECARD, MISHANDLED, "
					+ "UNPROFESSIONAL, NOT_FOLLOW_INSTRUCTIONS, WRONG_ADDRESS, "
					+ "NEVER_RECEIVED, WRONG_ITEM, FEEDBACK_DETAILS, "
					+ "TRACKINGID, DELIVERY_DATE, DISPUTE_STATUS, "
					+ "CREATE_USER, CREATE_DATE, STATUS) VALUES (";
			if (autoIncrementArray != null)
				insQry += autoIncrementArray[1];
			insQry += entityID + ", " + db.getInsertDBValue(station) + ", "
					+ db.getInsertDBValue(week) + ", "
					+ db.getInsertDBValue(year) + ", "
					+ db.getInsertDBValue(transporterID) + ", "
					+ db.getInsertDBValue(daName) + ", "
					+ db.getInsertDBValue(impactsScorecard) + ", "
					+ db.getInsertDBValue(mishandled) + ", "
					+ db.getInsertDBValue(unprofessional) + ", "
					+ db.getInsertDBValue(notFollowInstructions) + ", "
					+ db.getInsertDBValue(wrongAddress) + ", "
					+ db.getInsertDBValue(neverReceived) + ", "
					+ db.getInsertDBValue(wrongItem) + ", "
					+ db.getInsertDBValue(feedbackDetails) + ", "
					+ db.getInsertDBValue(trackingID) + ", "
					+ getIsoDBDateTime(deliveryDate) + ", "
					+ db.getInsertDBValue(disputeStatus) + ", "
					+ db.getInsertDBValue(loginUser) + ", "
					+ db.getInsertSysdate() + ", " + RecordStatus.ACTIVE + ")";

			boolean result = db.update(insQry);
			if (result)
				numOfRows++;
		}

		return numOfRows;
	}

	public double insDsbDetails(String fileName, List<String> columnsList,
			List dataList, String loginUser, String entityID) throws Exception {

		double numOfRows = 0;
		String stationYW[] = getStationYearWeek(fileName);
		String year = stationYW[1], week = stationYW[2];

		if (week.length() > 0)
			clearUploadScope("DSB_DETAILS", " AND ENTITYID=" + entityID
					+ " AND DSB_YEAR=" + year + " AND DSB_WEEK=" + week,
					loginUser);

		for (int i = 0; i < dataList.size(); i++) {
			List tempList = (ArrayList) dataList.get(i);
			/* by-header: the W28 'DSP_Delivery_Concessions' rename moved
			   Tracking ID, dropped Pickup/Attempt dates, added Dispute status */
			String daName = byHdr(tempList, columnsList, "Delivery Associate Name");
			String transporterID = byHdr(tempList, columnsList, "Delivery Associate");
			String impactsScorecard = byHdr(tempList, columnsList, "Impacts Scorecard");
			String deliveryType = byHdr(tempList, columnsList, "Delivery Type");
			String simultaneous = byHdr(tempList, columnsList, "Simultaneous Deliveries", "Simultaneous");
			String deliveredOver50m = byHdr(tempList, columnsList, "Delivered > 50 m", "Delivered over 50");
			String scanAttended = byHdr(tempList, columnsList, "Incorrect Scan Usage - Attended Delivery");
			String scanUnattended = byHdr(tempList, columnsList, "Incorrect Scan Usage - Unattended Delivery");
			String noPod = byHdr(tempList, columnsList, "No POD on Delivery", "No POD");
			String scannedNotDelivered = byHdr(tempList, columnsList, "Scanned - Not Delivered - Not Returned");
			String trackingID = byHdr(tempList, columnsList, "Tracking ID");
			String pickupDate = byHdr(tempList, columnsList, "Pickup Date");
			String attemptDate = byHdr(tempList, columnsList, "Attempt Date");
			String deliveryDate = byHdr(tempList, columnsList, "Delivery Date");
			String concessionDate = byHdr(tempList, columnsList, "Concession Date");
			String station = byHdr(tempList, columnsList, "Service Area", "Station");
			String dsp = byHdr(tempList, columnsList, "DSP");
			String disputeStatus = byHdr(tempList, columnsList, "Dispute status");
			if (transporterID.length() == 0 && trackingID.length() == 0)
				continue;

			String autoIncrementArray[] = db
					.getAutoIncrementArray("DSB_DETAILSID");

			String insQry = "INSERT INTO DSB_DETAILS (";
			if (autoIncrementArray != null)
				insQry += autoIncrementArray[0];
			insQry += "ENTITYID, STATION, DSP, DSB_WEEK, DSB_YEAR, "
					+ "TRANSPORTERID, DELIVERYASSOCIATE, IMPACTS_SCORECARD, "
					+ "DELIVERY_TYPE, SIMULTANEOUS, DELIVERED_OVER_50M, "
					+ "INCORRECT_SCAN_ATTENDED, INCORRECT_SCAN_UNATTENDED, "
					+ "NO_POD, SCANNED_NOT_DELIVERED, TRACKINGID, PICKUP_DATE, "
					+ "ATTEMPT_DATE, DELIVERY_DATE, CONCESSION_DATE, DISPUTE_STATUS, "
					+ "CREATE_USER, CREATE_DATE, STATUS) VALUES (";
			if (autoIncrementArray != null)
				insQry += autoIncrementArray[1];
			insQry += entityID + ", " + db.getInsertDBValue(station) + ", "
					+ db.getInsertDBValue(dsp) + ", "
					+ db.getInsertDBValue(week) + ", "
					+ db.getInsertDBValue(year) + ", "
					+ db.getInsertDBValue(transporterID) + ", "
					+ db.getInsertDBValue(daName) + ", "
					+ db.getInsertDBValue(impactsScorecard) + ", "
					+ db.getInsertDBValue(deliveryType) + ", "
					+ db.getInsertDBValue(simultaneous) + ", "
					+ db.getInsertDBValue(deliveredOver50m) + ", "
					+ db.getInsertDBValue(scanAttended) + ", "
					+ db.getInsertDBValue(scanUnattended) + ", "
					+ db.getInsertDBValue(noPod) + ", "
					+ db.getInsertDBValue(scannedNotDelivered) + ", "
					+ db.getInsertDBValue(trackingID) + ", "
					+ getIsoDBDateTime(pickupDate) + ", "
					+ getIsoDBDateTime(attemptDate) + ", "
					+ getIsoDBDateTime(deliveryDate) + ", "
					+ getIsoDBDateTime(concessionDate) + ", "
					+ db.getInsertDBValue(disputeStatus) + ", "
					+ db.getInsertDBValue(loginUser) + ", "
					+ db.getInsertSysdate() + ", " + RecordStatus.ACTIVE + ")";

			boolean result = db.update(insQry);
			if (result)
				numOfRows++;
		}

		return numOfRows;
	}

	public double insQualityDcrWeekly(String fileName,
			List<String> columnsList, List dataList, String loginUser,
			String entityID) throws Exception {

		double numOfRows = 0;
		String stationYW[] = getStationYearWeek(fileName);
		String station = stationYW[0];

		String rtsColumns = "RTS_ALL_EXEMPTED, RTS_BUSINESS_CLOSED, "
				+ "RTS_OUT_OF_DRIVE_TIME, RTS_OTHER, RTS_OBJECT_MISSING, "
				+ "RTS_UNABLE_TO_ACCESS, RTS_DAMAGED, RTS_BAD_WEATHER, "
				+ "RTS_CUSTOMER_UNAVAILABLE, RTS_UNSAFE_DOG, "
				+ "RTS_NO_SECURE_LOCATION, RTS_UNABLE_TO_LOCATE, "
				+ "RTS_LOCKER_ISSUE, RTS_RESCHEDULED, RTS_OTP_NOT_AVAILABLE, "
				+ "RTS_NO_LOCKER, RTS_MISSING_ACCESS_CODE, RTS_LOCKER_SPACE, "
				+ "RTS_LOCKER_INELIGIBLE, RTS_MERCHANT_UNAVAILABLE, "
				+ "RTS_AGE_VERIFICATION";

		/* weeks come per-row; clear each (year, week) scope once */
		String clearedScopes = "";

		for (int i = 0; i < dataList.size(); i++) {
			List tempList = (ArrayList) dataList.get(i);
			String week = getListRawData(tempList, 0);
			String daName = getListRawData(tempList, 1);
			String transporterID = getListRawData(tempList, 2);
			String dcrDpmo = getListRawData(tempList, 3).replaceAll(",", "");
			String delivered = getListRawData(tempList, 4).replaceAll(",", "");
			String dispatched = getListRawData(tempList, 5).replaceAll(",", "");
			String returned = getListRawData(tempList, 6).replaceAll(",", "");
			String returnedDaCtrl = getListRawData(tempList, 7).replaceAll(",",
					"");
			String rescued = getListRawData(tempList, 8).replaceAll(",", "");

			// Week column: '2026-27'
			String year = "";
			String yw[] = week.split("-");
			if (yw.length > 0)
				year = yw[0].trim();
			if (yw.length > 1)
				week = yw[1].replaceAll("W", "").trim();

			String scopeKey = "|" + year + "-" + week + "|";
			if (week.length() > 0 && clearedScopes.indexOf(scopeKey) < 0) {
				clearUploadScope("QUALITY_DCR_WEEKLY", " AND ENTITYID="
						+ entityID + " AND DCR_YEAR=" + year
						+ " AND DCR_WEEK=" + week, loginUser);
				clearedScopes += scopeKey;
			}

			String autoIncrementArray[] = db
					.getAutoIncrementArray("QUALITY_DCRID");

			String insQry = "INSERT INTO QUALITY_DCR_WEEKLY (";
			if (autoIncrementArray != null)
				insQry += autoIncrementArray[0];
			insQry += "ENTITYID, STATION, DCR_WEEK, DCR_YEAR, "
					+ "DELIVERYASSOCIATE, TRANSPORTERID, DCR_DPMO, DELIVERED, "
					+ "DISPATCHED, RETURNED, RETURNED_DA_CTRL, RESCUED, "
					+ rtsColumns + ", CREATE_USER, CREATE_DATE, STATUS) VALUES (";
			if (autoIncrementArray != null)
				insQry += autoIncrementArray[1];
			insQry += entityID + ", " + db.getInsertDBValue(station) + ", "
					+ db.getInsertDBValue(week) + ", "
					+ db.getInsertDBValue(year) + ", "
					+ db.getInsertDBValue(daName) + ", "
					+ db.getInsertDBValue(transporterID) + ", "
					+ db.getInsertDBValue(dcrDpmo) + ", "
					+ db.getInsertDBValue(delivered) + ", "
					+ db.getInsertDBValue(dispatched) + ", "
					+ db.getInsertDBValue(returned) + ", "
					+ db.getInsertDBValue(returnedDaCtrl) + ", "
					+ db.getInsertDBValue(rescued);
			// 21 RTS reason counts, columns 9..29 in file order
			for (int j = 9; j <= 29; j++)
				insQry += ", " + db.getInsertDBValue(
						getListRawData(tempList, j).replaceAll(",", ""));
			insQry += ", " + db.getInsertDBValue(loginUser) + ", "
					+ db.getInsertSysdate() + ", " + RecordStatus.ACTIVE + ")";

			boolean result = db.update(insQry);
			if (result)
				numOfRows++;
		}

		return numOfRows;
	}

	public double insRtsDetails(String fileName, List<String> columnsList,
			List dataList, String loginUser, String entityID) throws Exception {

		double numOfRows = 0;
		String stationYW[] = getStationYearWeek(fileName);
		String year = stationYW[1], week = stationYW[2];

		if (week.length() > 0)
			clearUploadScope("RTS_DETAILS", " AND ENTITYID=" + entityID
					+ " AND RTS_YEAR=" + year + " AND RTS_WEEK=" + week,
					loginUser);

		for (int i = 0; i < dataList.size(); i++) {
			List tempList = (ArrayList) dataList.get(i);
			String daName = getListRawData(tempList, 0);
			String trackingID = getListRawData(tempList, 1);
			String transporterID = getListRawData(tempList, 2);
			String impactsScorecard = getListRawData(tempList, 3);
			String rtsCode = getListRawData(tempList, 4);
			String additionalInfo = getListRawData(tempList, 5);
			String exemptionReason = getListRawData(tempList, 6);
			String plannedDate = getListRawData(tempList, 7);
			String station = getListRawData(tempList, 8);

			String autoIncrementArray[] = db
					.getAutoIncrementArray("RTS_DETAILSID");

			String insQry = "INSERT INTO RTS_DETAILS (";
			if (autoIncrementArray != null)
				insQry += autoIncrementArray[0];
			insQry += "ENTITYID, STATION, RTS_WEEK, RTS_YEAR, "
					+ "DELIVERYASSOCIATE, TRANSPORTERID, TRACKINGID, "
					+ "IMPACTS_SCORECARD, RTS_CODE, ADDITIONAL_INFO, "
					+ "EXEMPTION_REASON, PLANNED_DATE, "
					+ "CREATE_USER, CREATE_DATE, STATUS) VALUES (";
			if (autoIncrementArray != null)
				insQry += autoIncrementArray[1];
			insQry += entityID + ", " + db.getInsertDBValue(station) + ", "
					+ db.getInsertDBValue(week) + ", "
					+ db.getInsertDBValue(year) + ", "
					+ db.getInsertDBValue(daName) + ", "
					+ db.getInsertDBValue(transporterID) + ", "
					+ db.getInsertDBValue(trackingID) + ", "
					+ db.getInsertDBValue(impactsScorecard) + ", "
					+ db.getInsertDBValue(rtsCode) + ", "
					+ db.getInsertDBValue(additionalInfo) + ", "
					+ db.getInsertDBValue(exemptionReason) + ", "
					+ getIsoDBDateTime(plannedDate) + ", "
					+ db.getInsertDBValue(loginUser) + ", "
					+ db.getInsertSysdate() + ", " + RecordStatus.ACTIVE + ")";

			boolean result = db.update(insQry);
			if (result)
				numOfRows++;
		}

		return numOfRows;
	}

	/* tenure_workforce_calculation csv: one row per station-week (a year of
	   history per file). Keyed columns; delete-and-reload per station+year+week. */
	public double insTenureWeekly(List<String> columnsList, List dataList,
			String loginUser, String entityID) throws Exception {

		double numOfRows = 0;
		String clearedScopes = "";
		for (int i = 0; i < dataList.size(); i++) {
			List row = (ArrayList) dataList.get(i);
			String station = byHdr(row, columnsList, "station");
			String year = byHdr(row, columnsList, "year").replaceAll("[^0-9]", "");
			String week = byHdr(row, columnsList, "week").replaceAll("[^0-9]", "");
			if (station.length() == 0 || week.length() == 0)
				continue;
			String scopeKey = "|" + station + "-" + year + "-" + week + "|";
			if (clearedScopes.indexOf(scopeKey) < 0) {
				clearUploadScope("TENURE_WORKFORCE_WEEKLY", " AND ENTITYID="
						+ entityID + " AND REPORT_YEAR=" + year
						+ " AND REPORT_WEEK=" + week
						+ db.getDataInCondQuery(station, "STATION"), loginUser);
				clearedScopes += scopeKey;
			}
			String insQry = "INSERT INTO TENURE_WORKFORCE_WEEKLY (ENTITYID, STATION, "
					+ "REPORT_YEAR, REPORT_WEEK, TENURED_DAS, TOTAL_DAS, RAW_PCT, "
					+ "EXEMPTIONS, FINAL_PCT, DSP_TENURE, DSP_TENURE_STATUS, TIER, "
					+ "CREATE_USER, CREATE_DATE, STATUS) VALUES ("
					+ entityID + ", " + db.getInsertDBValue(station) + ", "
					+ year + ", " + week + ", "
					+ numOrNull(byHdr(row, columnsList, "delivering das-tenured")) + ", "
					+ numOrNull(byHdr(row, columnsList, "delivering das-total")) + ", "
					+ numOrNull(byHdr(row, columnsList, "tenured workforce raw")) + ", "
					+ db.getInsertDBValue(cut(byHdr(row, columnsList, "exemptions"), 1200)) + ", "
					+ numOrNull(byHdr(row, columnsList, "tenured workforce final")) + ", "
					+ db.getInsertDBValue(byHdr(row, columnsList, "dsp tenure")) + ", "
					+ db.getInsertDBValue(byHdr(row, columnsList, "dsp tenure status")) + ", "
					+ db.getInsertDBValue(byHdr(row, columnsList, "tenured workforce tier")) + ", "
					+ db.getInsertDBValue(loginUser) + ", " + db.getInsertSysdate()
					+ ", " + RecordStatus.ACTIVE + ")";
			if (db.update(insQry))
				numOfRows++;
		}
		return numOfRows;
	}

	/* tenure_workforce_das csv: one row per DA per week */
	public double insTenureDas(List<String> columnsList, List dataList,
			String loginUser, String entityID) throws Exception {

		double numOfRows = 0;
		String clearedScopes = "";
		for (int i = 0; i < dataList.size(); i++) {
			List row = (ArrayList) dataList.get(i);
			String station = byHdr(row, columnsList, "station");
			String year = byHdr(row, columnsList, "year").replaceAll("[^0-9]", "");
			String week = byHdr(row, columnsList, "week").replaceAll("[^0-9]", "");
			String tid = byHdr(row, columnsList, "transporter id");
			if (station.length() == 0 || week.length() == 0 || tid.length() == 0)
				continue;
			String scopeKey = "|" + station + "-" + year + "-" + week + "|";
			if (clearedScopes.indexOf(scopeKey) < 0) {
				clearUploadScope("TENURE_WORKFORCE_DAS", " AND ENTITYID="
						+ entityID + " AND REPORT_YEAR=" + year
						+ " AND REPORT_WEEK=" + week
						+ db.getDataInCondQuery(station, "STATION"), loginUser);
				clearedScopes += scopeKey;
			}
			String insQry = "INSERT INTO TENURE_WORKFORCE_DAS (ENTITYID, STATION, "
					+ "REPORT_YEAR, REPORT_WEEK, AMZ_EMPLOYEE_ID, TRANSPORTERID, "
					+ "DA_NAME, DAYS_SINCE_LAST_DELIVERED, DELIVERY_STATUS, "
					+ "DRIVER_STATUS, DRIVER_STATUS_REASON, LIFETIME_ROUTES, "
					+ "ROUTES_IN_WEEK, TENURE_STATUS, CREATE_USER, CREATE_DATE, STATUS) VALUES ("
					+ entityID + ", " + db.getInsertDBValue(station) + ", "
					+ year + ", " + week + ", "
					+ db.getInsertDBValue(byHdr(row, columnsList, "employee id")) + ", "
					+ db.getInsertDBValue(tid) + ", "
					+ db.getInsertDBValue(byHdr(row, columnsList, "name")) + ", "
					+ numOrNull(byHdr(row, columnsList, "days since last delivered")) + ", "
					+ db.getInsertDBValue(byHdr(row, columnsList, "delivery status")) + ", "
					+ db.getInsertDBValue(byHdr(row, columnsList, "driver status")) + ", "
					+ db.getInsertDBValue(byHdr(row, columnsList, "driver status reason code")) + ", "
					+ numOrNull(byHdr(row, columnsList, "lifetime routes")) + ", "
					+ numOrNull(byHdr(row, columnsList, "routes in week")) + ", "
					+ db.getInsertDBValue(byHdr(row, columnsList, "tenure status")) + ", "
					+ db.getInsertDBValue(loginUser) + ", " + db.getInsertSysdate()
					+ ", " + RecordStatus.ACTIVE + ")";
			if (db.update(insQry))
				numOfRows++;
		}
		return numOfRows;
	}

	/* Compliance Supplementary xlsx is a FORM, not a table (labels and values
	   scattered across the grid), so the generic reader - which sizes rows by
	   row 0's cell count - misses most of it. Read the workbook directly and
	   store adjacent label/value pairs as METRIC/VAL. Week comes from the
	   '2026_28' cell, station from the 'Station' pair. */
	public double insComplianceSupplementary(String fileName,
			String fileNameWithPath, String loginUser, String entityID)
			throws Exception {

		String station = "", year = "", week = "";
		List<String[]> pairs = new ArrayList<String[]>();

		org.apache.poi.ss.usermodel.Workbook workbook =
				org.apache.poi.ss.usermodel.WorkbookFactory
						.create(new java.io.File(fileNameWithPath));
		org.apache.poi.ss.usermodel.Sheet sheet = workbook.getSheetAt(0);
		org.apache.poi.ss.usermodel.DataFormatter fmt =
				new org.apache.poi.ss.usermodel.DataFormatter();
		for (int r = 0; r <= sheet.getLastRowNum(); r++) {
			org.apache.poi.ss.usermodel.Row row = sheet.getRow(r);
			if (row == null)
				continue;
			int last = row.getLastCellNum();
			for (int j = 0; j < last; j++) {
				String cell = row.getCell(j) == null ? ""
						: fmt.formatCellValue(row.getCell(j)).trim();
				if (cell.length() == 0)
					continue;
				if (cell.matches("\\d{4}_\\d{1,2}")) {
					year = cell.substring(0, 4);
					week = cell.substring(5);
					continue;
				}
				String next = j + 1 < last && row.getCell(j + 1) != null
						? fmt.formatCellValue(row.getCell(j + 1)).trim() : "";
				if (next.length() > 0 && cell.matches(".*[A-Za-z].*")) {
					if (normHdr(cell).equals("station"))
						station = next;
					else if (!normHdr(cell).equals("dsp")
							&& !normHdr(cell).startsWith("note")
							&& cell.length() < 200)
						pairs.add(new String[] { cell, next });
					j++;
				}
			}
		}
		workbook.close();
		if (week.length() == 0) {
			java.util.regex.Matcher m = java.util.regex.Pattern
					.compile("Week(\\d{1,2})-(\\d{4})").matcher(fileName);
			if (m.find()) {
				week = m.group(1);
				year = m.group(2);
			}
		}
		if (station.length() == 0)
			station = "DNK7";
		if (week.length() == 0)
			return 0;

		clearUploadScope("COMPLIANCE_SUPPLEMENTARY", " AND ENTITYID=" + entityID
				+ " AND REPORT_YEAR=" + year + " AND REPORT_WEEK=" + week
				+ db.getDataInCondQuery(station, "STATION"), loginUser);

		double numOfRows = 0;
		for (String[] p : pairs) {
			String insQry = "INSERT INTO COMPLIANCE_SUPPLEMENTARY (ENTITYID, STATION, "
					+ "REPORT_YEAR, REPORT_WEEK, METRIC, VAL, CREATE_USER, CREATE_DATE, STATUS) VALUES ("
					+ entityID + ", " + db.getInsertDBValue(station) + ", "
					+ year + ", " + week + ", "
					+ db.getInsertDBValue(cut(p[0], 200)) + ", "
					+ db.getInsertDBValue(cut(p[1], 200)) + ", "
					+ db.getInsertDBValue(loginUser) + ", " + db.getInsertSysdate()
					+ ", " + RecordStatus.ACTIVE + ")";
			if (db.update(insQry))
				numOfRows++;
		}
		return numOfRows;
	}

	private static String numOrNull(String s) {
		s = s == null ? "" : s.trim();
		if (s.length() == 0)
			return "NULL";
		try {
			return new java.math.BigDecimal(s).toPlainString();
		} catch (Exception e) {
			return "NULL";
		}
	}

	private static String cut(String s, int max) {
		return s != null && s.length() > max ? s.substring(0, max) : s;
	}

	/* DA Break Utilization csv: preamble notes, then a metadata block
	   (DSP/Station/Date/Heat tier/Planned minutes/% under), then the real
	   header row starting 'DA Transporter ID:'. One file = one station-day;
	   delete-and-reload on (ENTITYID, STATION, REPORT_DATE). */
	public double insDaBreakUtilization(List dataList, String loginUser,
			String entityID) throws Exception {

		String station = "", reportDate = "", heatTier = "", pctUnder = "";
		String plannedMin = "";
		boolean inData = false;
		double numOfRows = 0;

		for (int i = 0; i < dataList.size(); i++) {
			List row = (ArrayList) dataList.get(i);
			String c0 = getListRawData(row, 0);
			String c1 = getListRawData(row, 1);

			if (!inData) {
				if ("Station:".equalsIgnoreCase(c0))
					station = c1;
				else if ("Date:".equalsIgnoreCase(c0))
					reportDate = c1;
				else if (c0.startsWith("Heat tier"))
					heatTier = c1;
				else if (c0.startsWith("Planned Break Time"))
					plannedMin = c1.replaceAll("[^0-9]", "");
				else if (c0.startsWith("% Drivers"))
					pctUnder = c1;
				else if (c0.startsWith("DA Transporter ID")) {
					inData = true;
					if (reportDate.length() > 0) {
						clearUploadScope("DA_BREAK_UTILIZATION",
								" AND ENTITYID=" + entityID
										+ db.getDataInCondQuery(station, "STATION")
										+ db.getDataInCondQuery(reportDate, "REPORT_DATE"),
								loginUser);
					}
				}
				continue;
			}

			if (c0.length() == 0)
				continue;

			String breakMin = getListRawData(row, 4).replaceAll("[^0-9]", "");
			String insQry = "INSERT INTO DA_BREAK_UTILIZATION (ENTITYID, STATION, "
					+ "REPORT_DATE, HEAT_TIER, PLANNED_BREAK_MIN, PCT_UNDER_PLANNED, "
					+ "TRANSPORTERID, DA_NAME, BREAK_START, BREAK_END, BREAK_MIN, "
					+ "REPORT_SOURCE, BREAK_TYPE, CREATE_USER, CREATE_DATE, STATUS) VALUES ("
					+ entityID + ", " + db.getInsertDBValue(station) + ", "
					/* file date is already yyyy-MM-dd - native MySQL DATE literal */
					+ db.getInsertDBValue(reportDate) + ", "
					+ db.getInsertDBValue(heatTier) + ", "
					+ (plannedMin.length() == 0 ? "NULL" : plannedMin) + ", "
					+ db.getInsertDBValue(pctUnder) + ", "
					+ db.getInsertDBValue(c0) + ", "
					+ db.getInsertDBValue(c1) + ", "
					+ db.getInsertDBValue(getListRawData(row, 2)) + ", "
					+ db.getInsertDBValue(getListRawData(row, 3)) + ", "
					+ (breakMin.length() == 0 ? "NULL" : breakMin) + ", "
					+ db.getInsertDBValue(getListRawData(row, 5)) + ", "
					+ db.getInsertDBValue(getListRawData(row, 6)) + ", "
					+ db.getInsertDBValue(loginUser) + ", " + db.getInsertSysdate()
					+ ", " + RecordStatus.ACTIVE + ")";

			if (db.update(insQry))
				numOfRows++;
		}

		return numOfRows;
	}

	public double insSentimentSurvey(String fileName,
			List<String> columnsList, List dataList, String loginUser,
			String entityID) throws Exception {

		double numOfRows = 0;
		/* report weeks come per-row (col 0 = '202624'); clear each scope once */
		String clearedScopes = "";

		for (int i = 0; i < dataList.size(); i++) {
			List tempList = (ArrayList) dataList.get(i);
			String reportWk = getListRawData(tempList, 0);
			String surveyMo = getListRawData(tempList, 1);
			String country = getListRawData(tempList, 2);
			String station = getListRawData(tempList, 3);
			String dsp = getListRawData(tempList, 4);
			String question = getListRawData(tempList, 5);
			String responseRate = getListRawData(tempList, 6).replaceAll("%", "");
			String favorableRate = getListRawData(tempList, 7).replaceAll("%", "");
			String t6mFavorable = getListRawData(tempList, 8).replaceAll("%", "");

			// week '202624' -> year 2026 wk 24; month '202606' -> 2026 / 6;
			// the file ends with a "Key:" legend footer - skip non-data rows
			String repYear = "", repWeek = "", surYear = "", surMonth = "";
			try {
				if (reportWk.length() >= 5) {
					repYear = String.valueOf(
							Integer.parseInt(reportWk.substring(0, 4)));
					repWeek = String.valueOf(
							Integer.parseInt(reportWk.substring(4).trim()));
				}
				if (surveyMo.length() >= 5) {
					surYear = String.valueOf(
							Integer.parseInt(surveyMo.substring(0, 4)));
					surMonth = String.valueOf(
							Integer.parseInt(surveyMo.substring(4).trim()));
				}
			} catch (NumberFormatException ex) {
				continue;
			}
			if (repWeek.length() == 0)
				continue;

			/* Scope by SURVEY month, not report week: consecutive weekly files
			   carry the same trailing months, so week-scoped clearing left one
			   copy per file and months showed duplicated. Latest upload wins. */
			String scopeKey = "|" + surYear + "-" + surMonth + "-" + station + "|";
			if (clearedScopes.indexOf(scopeKey) < 0) {
				if (surMonth.length() > 0) {
					clearUploadScope("SENTIMENT_SURVEY", " AND ENTITYID="
							+ entityID + " AND SURVEY_YEAR=" + surYear
							+ " AND SURVEY_MONTH=" + surMonth
							+ db.getDataInCondQuery(station, "STATION"),
							loginUser);
				} else {
					clearUploadScope("SENTIMENT_SURVEY", " AND ENTITYID="
							+ entityID + " AND REPORT_YEAR=" + repYear
							+ " AND REPORT_WEEK=" + repWeek
							+ db.getDataInCondQuery(station, "STATION"),
							loginUser);
				}
				clearedScopes += scopeKey;
			}

			String autoIncrementArray[] = db
					.getAutoIncrementArray("SENTIMENT_SURVEYID");

			String insQry = "INSERT INTO SENTIMENT_SURVEY (";
			if (autoIncrementArray != null)
				insQry += autoIncrementArray[0];
			insQry += "ENTITYID, COUNTRY, STATION, DSP, REPORT_WEEK, "
					+ "REPORT_YEAR, SURVEY_MONTH, SURVEY_YEAR, QUESTION, "
					+ "RESPONSE_RATE, FAVORABLE_RATE, T6M_FAVORABLE_RATE, "
					+ "CREATE_USER, CREATE_DATE, STATUS) VALUES (";
			if (autoIncrementArray != null)
				insQry += autoIncrementArray[1];
			insQry += entityID + ", " + db.getInsertDBValue(country) + ", "
					+ db.getInsertDBValue(station) + ", "
					+ db.getInsertDBValue(dsp) + ", "
					+ db.getInsertDBValue(repWeek) + ", "
					+ db.getInsertDBValue(repYear) + ", "
					+ db.getInsertDBValue(surMonth) + ", "
					+ db.getInsertDBValue(surYear) + ", "
					+ db.getInsertDBValue(question) + ", "
					+ db.getInsertDBValue(responseRate) + ", "
					+ db.getInsertDBValue(favorableRate) + ", "
					+ db.getInsertDBValue(t6mFavorable) + ", "
					+ db.getInsertDBValue(loginUser) + ", "
					+ db.getInsertSysdate() + ", " + RecordStatus.ACTIVE + ")";

			boolean result = db.update(insQry);
			if (result)
				numOfRows++;
		}

		return numOfRows;
	}
}
// build 2026-07-03 fix: schedule day-mismatch warning
// build 2026-07-13: CDF / DSB / Quality DCR / RTS detail uploads
// build 2026-07-13b: sentiment survey upload + delete-and-reload scopes
