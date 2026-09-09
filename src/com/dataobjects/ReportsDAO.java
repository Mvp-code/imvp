package com.dataobjects;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import com.beans.Reports;
import com.beans.SearchBean;
import com.util.RecordStatus;

public class ReportsDAO extends MVPGDAO {

	Reports bean = new Reports();

	@Override
	public SearchBean searchRecords(SearchBean searchBean, String recordID,
			String loginUser, String loginUserRoles, String loginUserID,
			String entityID) throws Exception {

		List<String> labelsList = new ArrayList<String>();
		List resultList = new ArrayList();
		List footerList = new ArrayList();

		searchBean.setController(bean.getController());
		searchBean.setDisplayName("Reports");
		if (searchBean.getSrhReportType().length() > 0) {
			String selCols = "";
			String condQry = "";
			String tableName = searchBean.getSrhReportType()
					.replaceAll(" ", "_").toUpperCase();

			searchBean
					.setDisplayName(searchBean.getSrhReportType() + " Report");

			// Search Criteria
			String dataArray[][] = getTableColsArray(
					searchBean.getSrhReportType().replaceAll(" ", ""));
//			String tableColArray[] = dataArray[0];
			String tableFiltersArray[] = dataArray[1];
			searchBean.setReportsFilterArray(tableFiltersArray);

			if (tableFiltersArray != null) {
				for (int i = 0; i < tableFiltersArray.length; i++) {
					String filterName = tableFiltersArray[i];
					switch (filterName) {
					case "SAFTY_DATE":
					case "EVENT_DATETIME":
						String fromVal = searchBean.getRequestMap()
								.get("srh" + filterName + "From") == null
										? ""
										: searchBean.getRequestMap()
												.get("srh" + filterName
														+ "From")
												.toString().trim();
						String toVal = searchBean.getRequestMap()
								.get("srh" + filterName + "To") == null
										? ""
										: searchBean.getRequestMap()
												.get("srh" + filterName + "To")
												.toString().trim();
						condQry += db.getDateCondQuery(fromVal, toVal,
								filterName);
						break;

					default:
						String scVal = searchBean.getRequestMap()
								.get("srh" + filterName) == null
										? ""
										: searchBean.getRequestMap()
												.get("srh" + filterName)
												.toString().trim();

						if (scVal.startsWith(">")) {
							scVal = scVal.substring(1);
							if (scVal.length() > 0)
								condQry += " AND " + filterName + " > " + scVal;

						} else if (scVal.startsWith(">=")) {
							scVal = scVal.substring(2);
							if (scVal.length() > 0)
								condQry += " AND " + filterName + " >= "
										+ scVal;

						} else if (scVal.startsWith("<")) {
							scVal = scVal.substring(1);
							if (scVal.length() > 0)
								condQry += " AND " + filterName + " < " + scVal;

						} else if (scVal.startsWith("<=")) {
							scVal = scVal.substring(2);
							if (scVal.length() > 0)
								condQry += " AND " + filterName + " <= "
										+ scVal;

						} else if (scVal.startsWith("=")) {
							scVal = scVal.substring(1);
							if (scVal.length() > 0)
								condQry += " AND " + filterName + " = " + scVal;

						} else {
							condQry += db.getDataInCondQuery(scVal, filterName);
						}
						break;
					}
				}
			}

			// Report Columns
			String selectedCols = searchBean.getRequestMap()
					.get("reportCol") == null ? ""
							: searchBean.getRequestMap().get("reportCol")
									.toString().trim();
			String printType = searchBean.getRequestMap()
					.get("printType") == null ? ""
							: searchBean.getRequestMap().get("printType")
									.toString().trim();
			int numOfCols = 0;
			if (selectedCols.length() > 0) {
				String selectedColsArray[] = selectedCols.split("@@");
				if (printType.length() > 0)
					numOfCols = selectedColsArray.length;
				else {
					numOfCols = selectedColsArray.length + 1;
					selCols += tableName + "ID";
				}

				for (int i = 0; i < selectedColsArray.length; i++) {
					selectedColsArray[i] = selectedColsArray[i].trim();
					String displayName = selectedColsArray[i]
							.replaceAll("_", " ").trim();
					if (displayName.length() > 0) {
						labelsList.add(displayName);
						if (selCols.length() > 0)
							selCols += ", ";

						switch (selectedColsArray[i]) {
						case "SAFTY_DATE":
						case "ITINARARYDATE":
							selCols += db.getSelectDate(selectedColsArray[i]);
							break;

						case "EVENT_DATETIME":
							selCols += db
									.getSelectDateTime(selectedColsArray[i]);
							break;

						default:
							selCols += selectedColsArray[i];
							break;
						}
					}
				}

				String selQry = "SELECT " + selCols + " FROM " + tableName
						+ " WHERE STATUS=" + RecordStatus.ACTIVE
						+ " AND ENTITYID=" + entityID + condQry + " ORDER BY 1";
				resultList = db.selectAsList(selQry, numOfCols);

			} else if ("SMS Tx Summary"
					.equalsIgnoreCase(searchBean.getSrhReportType())) {
				labelsList.add("Employee");
				labelsList.add("Sent #");
				labelsList.add("Received #");
				searchBean.setWidthColumns(new int[] { 70, 15, 15 });

				String srhEmployee = searchBean.getRequestMap()
						.get("srhEMPLOYEE") == null ? ""
								: searchBean.getRequestMap().get("srhEMPLOYEE")
										.toString().trim();

				searchBean.setColumnSortName(
						searchBean.getColumnSortName().replaceAll("7", "15"));

				String selQry = "SELECT EMPLOYEEID, COUNT(SMSTRANSACTIONID) "
						+ "FROM SMSTRANSACTION WHERE STATUS="
						+ RecordStatus.ACTIVE + " AND ENTITYID=" + entityID
						+ db.getDateCondQuery(searchBean.getSrhFromDate(),
								searchBean.getSrhToDate(), "CREATE_DATE")
						+ db.getDataInCondQuery(srhEmployee, "EMPLOYEEID")
						+ db.getDataInCondQuery("queued", "MESSAGESTATUS")
						+ " GROUP BY EMPLOYEEID";
				List sentList = db.selectAsList(selQry, 2);

				selQry = "SELECT A.EMPLOYEEID, COUNT(B.SMSTRANSACTIONTRANSID) "
						+ "FROM SMSTRANSACTION A, SMSTRANSACTIONTRANS B WHERE A.STATUS="
						+ RecordStatus.ACTIVE + " AND B.STATUS="
						+ RecordStatus.ACTIVE + " AND A.ENTITYID=" + entityID
						+ db.getDateCondQuery(searchBean.getSrhFromDate(),
								searchBean.getSrhToDate(), "B.CREATE_DATE")
						+ db.getDataInCondQuery(srhEmployee, "A.EMPLOYEEID")
						+ " GROUP BY A.EMPLOYEEID";
				List receivedList = db.selectAsList(selQry, 2);

				/*-
				selQry = "SELECT A.EMPLOYEEID, A.SMSTRANSACTIONID, B.SMSTRANSACTIONTRANSID, B.MESSAGEID, B.REPLAYMSG, B.CREATE_USER, B.CREATE_DATE, B.STATUS "
						+ "FROM SMSTRANSACTION A, SMSTRANSACTIONTRANS B WHERE A.STATUS="
						+ RecordStatus.ACTIVE + " AND B.STATUS="
						+ RecordStatus.ACTIVE + " AND A.ENTITYID=" + entityID
						+ db.getDateCondQuery(searchBean.getSrhFromDate(),
								searchBean.getSrhToDate(), "B.CREATE_DATE")
						+ db.getDataInCondQuery(srhEmployee, "A.EMPLOYEEID")
						+ " ORDER BY 1, 2, 3 ";
				List receivedList1 = db.selectAsList(selQry, 8);
				for (int i = 0; i < receivedList1.size(); i++) {
					List tempList = (ArrayList) receivedList1.get(i);
					System.out.println(i + " :: receivedList1 :: "
							+ tempList.size() + " :: " + tempList);
				}
				*/
				List<String> empIDList = new ArrayList<String>();
				empIDList = getUniqueDataFromList(sentList, 0, empIDList);
				empIDList = getUniqueDataFromList(receivedList, 0, empIDList);
				String empIDs = String.join(",", empIDList);

				if (empIDs.length() > 0) {
					Map<String, String> _sentMap = getMap(sentList);
					Map<String, String> _receivedMap = getMap(receivedList);

					selQry = "SELECT EMPLOYEEID, FULLNAME "
							+ "FROM EMPLOYEE WHERE STATUS="
							+ RecordStatus.ACTIVE + " AND ENTITYID=" + entityID
							+ db.getIDInCondQuery(empIDs, "EMPLOYEEID")
							+ getOrderByQry(searchBean, "2");

					List dataList = db.selectAsList(selQry, 2);
					for (int i = 0; i < dataList.size(); i++) {
						List tempList = (ArrayList) dataList.get(i);
						String empID = tempList.get(0) == null ? ""
								: tempList.get(0).toString().trim();
						String empName = tempList.get(1) == null ? ""
								: tempList.get(1).toString().trim();
						String sentCNT = _sentMap.get(empID) == null ? "0"
								: _sentMap.get(empID);
						String receivedCNT = _receivedMap.get(empID) == null
								? "0"
								: _receivedMap.get(empID);

						List tempRow = new ArrayList();
						if (!"xls".equalsIgnoreCase(printType))
							tempRow.add(empID);
						tempRow.add(empName);
						tempRow.add(sentCNT);
						tempRow.add(receivedCNT);
						resultList.add(tempRow);
					}
				}

			} else if ("DA Daily Summary"
					.equalsIgnoreCase(searchBean.getSrhReportType())) {

				// searchBean.setDisplayResultsSorting(false);

				labelsList.add("Route Code");
				labelsList.add("All Stops");
				labelsList.add("Total Packages");
				labelsList.add("Avg Pace Stops /hr");
				labelsList.add("Total Break Time");
				labelsList.add("Itinerary Date");
				labelsList.add("Driver Name");
				labelsList.add("Transporter");
				labelsList.add("Signin Time");
				labelsList.add("Signout Time");
				labelsList.add("Last Stop Time");
				labelsList.add("Time On Road");
				labelsList.add("Last Stop Station");

				searchBean.setWidthColumns(
						new int[] { 6, 6, 6, 6, 6, 10, 18, 12, 6, 6, 6, 6, 6 });
				String srhTRANSPORTERID = searchBean.getRequestMap()
						.get("srhTRANSPORTERID") == null
								? ""
								: searchBean.getRequestMap()
										.get("srhTRANSPORTERID").toString()
										.trim();
				String srhDriverName = searchBean.getRequestMap()
						.get("srhDRIVER_NAME") == null
								? ""
								: searchBean.getRequestMap()
										.get("srhDRIVER_NAME").toString()
										.trim();
				String srhEmployee = searchBean.getRequestMap()
						.get("srhEMPLOYEE") == null ? ""
								: searchBean.getRequestMap().get("srhEMPLOYEE")
										.toString().trim();

				condQry = db.getDateCondQuery(searchBean.getSrhFromDate(),
						searchBean.getSrhToDate(), "ITINARARYDATE");
				if (srhEmployee.length() > 0) {
					// Suggestor
					condQry += db.getDataInCondQuery(srhEmployee,
							"TRANSPORTERID");

				} else {
					condQry += db.getDataInCondQuery(srhTRANSPORTERID,
							"TRANSPORTERID");

					condQry += db.getDataLikeCondQuery(srhDriverName,
							"TRANSPORTERNAME");
				}

				numOfCols = 15;
				String addCols = "DAILY_ITINERARIESID, ";
				if ("xls".equalsIgnoreCase(printType)) {
					numOfCols = 14;
					addCols = "";
				}

				searchBean.setColumnSortName(
						searchBean.getColumnSortName().replaceAll("7", "15"));

				String selQry = "SELECT " + addCols + " ROUTECODE, "
						+ "ALLSTOPS, TOALPACKAGES, AVG_PACE_STOP_PER_HOUR, "
						+ "TOTAL_BREAKTIME, "
						+ db.getSelectDate("ITINARARYDATE")
						+ ", TRANSPORTERNAME, TRANSPORTERID, "
						+ db.getSelectDateFormat("APP_SIGNIN",
								db.ORACLE_HHSMISAM)
						+ ", "
						+ db.getSelectDateFormat("APP_SIGNOUT",
								db.ORACLE_HHSMISAM)
						+ ", "
						+ db.getSelectDateFormat("LAST_STOP_TIME",
								db.ORACLE_HHSMISAM)
						+ ", "
						+ db.getSelectDateFormat(
								"TIMEDIFF(MAX(APP_SIGNOUT), MIN(APP_SIGNIN))",
								db.ORACLE_HH24SMI)
						+ ", "
						+ db.getSelectDateFormat(
								"TIMEDIFF(MAX(APP_SIGNOUT), MIN(LAST_STOP_TIME))",
								db.ORACLE_HH24SMI)
						+ ", "
						+ db.getSelectDateFormat("ITINARARYDATE",
								db.ORACLE_YYYYSMMSDD)
						+ " FROM DAILY_ITINERARIES WHERE STATUS="
						+ RecordStatus.ACTIVE + " AND ENTITYID=" + entityID
						+ condQry + " GROUP BY " + addCols
						+ " ROUTECODE, ALLSTOPS, "
						+ "TOALPACKAGES, AVG_PACE_STOP_PER_HOUR, TOTAL_BREAKTIME, "
						+ "ITINARARYDATE, TRANSPORTERNAME, TRANSPORTERID, APP_SIGNIN, "
						+ "APP_SIGNOUT, LAST_STOP_TIME "
						+ getOrderByQry(searchBean, numOfCols + "");

				searchBean.setColumnSortName(
						searchBean.getColumnSortName().replaceAll("15", "7"));

				resultList = db.selectAsList(selQry, numOfCols);

				if (resultList.size() > 0) {
					int routeCodeIndex = 1;
					int breakTimeIndex = 5;
					int timeOnRoadIndex = 12;

					long totalRouteCodeCNT = 0;
					long totalBreakTime = 0;
					long totalMinutes = 0;

					Map<String, String> _reqMap = searchBean.getRequestMap();

					if (addCols.length() == 0) {
						routeCodeIndex = 0;
						breakTimeIndex = 4;
						timeOnRoadIndex = 11;
					}

					for (int i = 0; i < resultList.size(); i++) {
						List tempList = (ArrayList) resultList.get(i);
						String routeCode = tempList.get(routeCodeIndex) == null
								? ""
								: tempList.get(routeCodeIndex).toString()
										.trim();
						String breakTime = tempList.get(breakTimeIndex) == null
								? ""
								: tempList.get(breakTimeIndex).toString()
										.trim();
						String timeOnRoad = tempList
								.get(timeOnRoadIndex) == null ? ""
										: tempList.get(timeOnRoadIndex)
												.toString().trim();
						if (routeCode.length() > 0) {
							String[] parts = routeCode.split(",");
							totalRouteCodeCNT += parts.length;
						}

						if (breakTime.length() > 0)
							totalBreakTime += Long.parseLong(breakTime);

						if (timeOnRoad.length() > 0) {
							String[] parts = timeOnRoad.split(":");
							if (parts.length == 2) {
								int hours = Integer.parseInt(parts[0]);
								int minutes = Integer.parseInt(parts[1]);

								totalMinutes += hours * 60 + minutes;
								if (hours > 9) {
									_reqMap.put("highlightRowColor_" + i,
											"bg-warning");
								}
							}
						}
					}

					long resultHours = totalMinutes / 60;
					long resultMinutes = totalMinutes % 60;

					List totalList = new ArrayList();
					for (int i = 0; i < numOfCols; i++) {
						totalList.add("");
					}

					totalList.set(routeCodeIndex, totalRouteCodeCNT + "");
					totalList.set(breakTimeIndex, totalBreakTime + "");
					totalList.set(timeOnRoadIndex,
							resultHours + ":" + resultMinutes);
					footerList.add(totalList);
					searchBean.setRequestMap(_reqMap);
				}
			} else if ("Safety Dashboard Metrics"
					.equalsIgnoreCase(searchBean.getSrhReportType())) {

				searchBean.setDisplayResultsSorting(false);

				labelsList = new ArrayList<String>();
				Map<String, String> _empMap = new HashMap<String, String>();
				Map<String, String> _columnCNTMap = new HashMap<String, String>();

				condQry = db.getDateCondQuery(searchBean.getSrhFromDate(),
						searchBean.getSrhToDate(), "SAFTY_DATE");

				condQry += db.getDataInCondQuery(searchBean.getSrhValue(),
						"DELIVERYASSOCIATE");

				String selQry = "SELECT DELIVERYASSOCIATE, METRICSUBTYPE "
						+ "FROM SAFETY_DASHBOARD WHERE STATUS="
						+ RecordStatus.ACTIVE + " AND ENTITYID=" + entityID
						+ condQry + " ORDER BY 1";
				List dataList = db.selectAsList(selQry, 2);
				if (dataList.size() > 0) {
					selQry = "SELECT DISTINCT METRICSUBTYPE "
							+ "FROM SAFETY_DASHBOARD WHERE STATUS="
							+ RecordStatus.ACTIVE + " AND ENTITYID=" + entityID
							+ condQry + " ORDER BY 1";
					List subTypesList = db.selectAsList(selQry, 1);

					int colWidsths[] = new int[subTypesList.size() + 2];
					labelsList.add("Employee");
					colWidsths[0] = 20;
					for (int i = 0; i < subTypesList.size(); i++) {
						List tempList = (ArrayList) subTypesList.get(i);
						String subType = getListData(tempList, 0);
						labelsList.add(subType);
						colWidsths[i + 1] = 10;
					}
					labelsList.add("Grand Total");
					colWidsths[colWidsths.length - 1] = 10;
					searchBean.setWidthColumns(colWidsths);
					if (printType.length() == 0)
						searchBean.setBoldColumns(
								new int[] { colWidsths.length });
					else
						searchBean.setBoldColumns(
								new int[] { colWidsths.length - 1 });

					String tempEmp = "";
					for (int i = 0; i < dataList.size(); i++) {
						List tempList = (ArrayList) dataList.get(i);
						String employee = getListData(tempList, 0);
						String subType = getListData(tempList, 1);

						if (!employee.equalsIgnoreCase(tempEmp)) {
							if (tempEmp.length() > 0) {
								int totalRowCNT = 0;
								List tempRow = new ArrayList();
								if (printType.length() == 0)
									tempRow.add("1");

								tempRow.add(tempEmp);
								for (int j = 0; j < subTypesList.size(); j++) {
									tempList = (ArrayList) subTypesList.get(j);
									String tempSubType = getListData(tempList,
											0);
									int count = _empMap.get(tempSubType) == null
											? 0
											: Integer.parseInt(
													_empMap.get(tempSubType));
									tempRow.add(count + "");

									int colCNT = _columnCNTMap
											.get(tempSubType) == null
													? 0
													: Integer.parseInt(
															_columnCNTMap.get(
																	tempSubType));
									colCNT += count;
									_columnCNTMap.put(tempSubType, colCNT + "");

									totalRowCNT += count;
								}
								tempRow.add(totalRowCNT + "");
								resultList.add(tempRow);
							}

							tempEmp = employee;
							_empMap = new HashMap<String, String>();
						}

						int count = _empMap.get(subType) == null ? 0
								: Integer.parseInt(_empMap.get(subType));
						count++;
						_empMap.put(subType, count + "");
					}

					if (tempEmp.length() > 0) {
						int totalRowCNT = 0;
						List tempRow = new ArrayList();
						if (printType.length() == 0)
							tempRow.add("1");
						tempRow.add(tempEmp);
						for (int j = 0; j < subTypesList.size(); j++) {
							List tempList = (ArrayList) subTypesList.get(j);
							String tempSubType = getListData(tempList, 0);
							int count = _empMap.get(tempSubType) == null ? 0
									: Integer
											.parseInt(_empMap.get(tempSubType));
							tempRow.add(count + "");

							int colCNT = _columnCNTMap.get(tempSubType) == null
									? 0
									: Integer.parseInt(
											_columnCNTMap.get(tempSubType));
							colCNT += count;
							_columnCNTMap.put(tempSubType, colCNT + "");

							totalRowCNT += count;
						}
						tempRow.add(totalRowCNT + "");
						resultList.add(tempRow);
					}

					int totalGT = 0;
					List tempRow = new ArrayList();
					if (printType.length() == 0)
						tempRow.add("1");
					tempRow.add("Grand Total");
					for (int i = 0; i < subTypesList.size(); i++) {
						List tempList = (ArrayList) subTypesList.get(i);
						String subType = getListData(tempList, 0);
						int colCNT = _columnCNTMap.get(subType) == null ? 0
								: Integer.parseInt(_columnCNTMap.get(subType));
						tempRow.add(colCNT + "");
						totalGT += colCNT;
					}
					tempRow.add(totalGT + "");
					footerList.add(tempRow);
				}
			}

		} else {
			List<String> reportsList = new ArrayList<String>();
			reportsList.add("Safety Dashboard");
			reportsList.add("Safety Dashboard Metrics");
			reportsList.add("Quality Overview");
			reportsList.add("DA Daily Summary");
			reportsList.add("SMS Tx Summary");
			searchBean.setReportsList(reportsList);
		}

		searchBean.setLabelsList(labelsList);
		searchBean.setDataList(resultList);
		searchBean.setFooterList(footerList);
		return searchBean;
	}

	@Override
	public String getAjaxRequestTypeResp(String requestType,
			Map<String, String> requestMap, String loginUser,
			String loginUserRoles, String loginUserID, String entityID)
			throws Exception {

		StringBuffer xmlMesg = new StringBuffer();

		String dataArray[][] = getTableColsArray(requestType);
		String tableColsArray[] = dataArray[0];
		String tableFiltersArray[] = dataArray[1];
		xmlMesg.append("<reportDetails>");
		xmlMesg.append("<tableCols>");
		if (tableColsArray != null) {
			for (int i = 0; i < tableColsArray.length; i++) {
				xmlMesg = buildXML("colName", tableColsArray[i], xmlMesg);
			}
		}
		xmlMesg.append("</tableCols>");

		xmlMesg.append("<tableFilters>");
		if (tableFiltersArray != null) {
			for (int i = 0; i < tableFiltersArray.length; i++) {
				xmlMesg = buildXML("colName", tableFiltersArray[i], xmlMesg);
			}
		}
		xmlMesg.append("</tableFilters>");
		xmlMesg.append("</reportDetails>");

		return xmlMesg.toString();
	}

	private String[][] getTableColsArray(String reqportName) {

		String tableColsArray[] = null;
		String tableFiltersArray[] = null;
		if ("SafetyDashboard".equalsIgnoreCase(reqportName)) {
			tableColsArray = new String[] { "SAFTY_WEEK", "SAFTY_DATE",
					"DELIVERYASSOCIATE", "TRANSPORTERID", "EVENTID",
					"EVENT_DATETIME", "VIN", "OSSIMPACT", "METRICTYPE",
					"METRICSUBTYPE", "SOURCE", "VIDEOLINK", "REVIEWDETAILS" };

		} else if ("SafetyDashboardMetrics".equalsIgnoreCase(reqportName)
				|| "SMSTxSummary".equalsIgnoreCase(reqportName)) {
			tableFiltersArray = new String[] { "DATE_RANGE", "EMPLOYEE" };

		} else if ("DADailySummary".equalsIgnoreCase(reqportName)) {
			tableFiltersArray = new String[] { "DATE_RANGE", "TRANSPORTERID",
					"DRIVER_NAME", "EMPLOYEE" };

		} else if ("QualityOverview".equalsIgnoreCase(reqportName)) {
			tableColsArray = new String[] { "QUALITY_YEAR", "QUALITY_WEEK",
					"DELIVERYASSOCIATE", "TRANSPORTERID", "OVERALLQUALITYSCORE",
					"DCR", "DSB", "POD", "SWC_CC", "SWC_AD",
					"PACKAGESDELIVERED", "DNR", "DNR_DPMO",
					"PACKAGES_DISPATCHED", "PACKAGES_RETURNED",
					"RTS_BUSINIESS_CLOSED", "RTS_CUSTOMER_UNAVAILABLE",
					"RTS_NO_SECURE_LOCATION", "" + "RTS_OTHER",
					"RTS_OUT_OF_DRIVETIME", "RTS_UNABLE_TO_ACCESS",
					"RTS_UNABLE_TO_LOCATE", "POD_SUCCESS", "POD_OPPORTUNITIES",
					"CDF_DPMO", "CED" };
		}

		if (tableFiltersArray == null)
			tableFiltersArray = tableColsArray;

		return new String[][] { tableColsArray, tableFiltersArray };
	}
}
