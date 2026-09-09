package com.dataobjects;

import java.util.ArrayList;
import java.util.Calendar;
import java.util.GregorianCalendar;
import java.util.List;
import java.util.Map;

import com.beans.EmployeeDashboard;
import com.beans.ErrorBean;
import com.beans.MainBean;
import com.beans.SearchBean;
import com.util.RecordStatus;
import com.util.SubmitType;

public class EmployeeDashboardDAO extends MVPGDAO {

	EmployeeDashboard bean = new EmployeeDashboard();

	@Override
	public SearchBean searchRecords(SearchBean searchBean, String recordID,
			String loginUser, String loginUserRoles, String loginUserID,
			String entityID) throws Exception {

		searchBean.setDisplayName(bean.getDisplayName() + "s");
		searchBean.setController(bean.getController());

		return searchBean;
	}

	public Object[] getEmployeeData(String srhYear, String srhWeek,
			String shrTransporterID, String srhDashboardOverviewID,
			String entityID) throws Exception {

		String recordID = "", targetDate = "";
		List section1List = new ArrayList();
		List qualityList = new ArrayList();
		List safetyList = new ArrayList();
		List incidentList = new ArrayList();
		List accidentsList = new ArrayList();
		List dvicList = new ArrayList();

		String condQry = db.getIDInCondQuery(srhYear, "DASHBOARD_YEAR");

		condQry += db.getIDInCondQuery(srhWeek, "DASHBOARD_WEEK");

		if (srhDashboardOverviewID.length() > 0)
			condQry = "";

		String selQry = "SELECT TRANSPORTERID, DELIVERYASSOCIATE, OVERALLSTANDING, "
				// Quality
				+ "CDFDPMO, DCR, DSB, SWCPOD, DNRS, "
				+ "CUSTESCALATIONDEFECT, CUSTDELIVERYFEEDBACK, "
				// Safety
				+ "DISTRACTION, SEATBELTOFFRATE, SPEEDING, SPEEDINGEVENTRATE, "
				+ "DISTRACTIONRATE, LOOKINGATPHONE, TALKINGONPHONE, "
				+ "LOOKINGDOWN, FOLLOWINGDISTANCERATE, SIGNORSIGNALVIOLATIONRATE, "
				+ "STOPSIGNVIOLATIONS, STOPLIGHTVIOLATIONS, ILLEGALUTURNS, "

				+ "ONROADSAFETYSCORE, OVERALLQUALITYSCORE, DASHBOARD_OVERVIEWID, DASHBOARD_YEAR, DASHBOARD_WEEK "

				+ "FROM DASHBOARD_OVERVIEW WHERE STATUS=" + RecordStatus.ACTIVE
				+ " AND ENTITYID=" + entityID + condQry
				+ db.getDataInCondQuery(shrTransporterID, "TRANSPORTERID")
				+ db.getIDInCondQuery(srhDashboardOverviewID,
						"DASHBOARD_OVERVIEWID")
				+ " ORDER BY 2";

		List resultList = db.selectAsList(selQry, 28);
		if (resultList.size() > 0) {
			List tempList = (ArrayList) resultList.get(0);
			String transporter_id = getListData(tempList, 0);
			String delivery_associate = getListData(tempList, 1);
			String overall_standing = getListData(tempList, 2);
			String cdf_dpmo = getListData(tempList, 3);
			String dcr = getListData(tempList, 4);
			String dsb = getListData(tempList, 5);
			String swc_pod = getListData(tempList, 6);
			String dnrs = getListData(tempList, 7);
			String cust_escalation_defect = getListData(tempList, 8);
			String cust_delivery_feedback = getListData(tempList, 9);
			String distraction = getListData(tempList, 10);
			String seatbelt_off_rate = getListData(tempList, 11);
			String speeding = getListData(tempList, 12);
			String speeding_event_rate = getListData(tempList, 13);
			String distraction_rate = getListData(tempList, 14);
			String looking_at_phone = getListData(tempList, 15);
			String talking_on_phone = getListData(tempList, 16);
			String looking_down = getListData(tempList, 17);
			String following_distance_rate = getListData(tempList, 18);
			String sign_or_signal_violation_rate = getListData(tempList, 19);
			String stop_sign_violations = getListData(tempList, 20);
			String stop_light_violations = getListData(tempList, 21);
			String illegal_u_turns = getListData(tempList, 22);
			String onroad_safety_score = getListData(tempList, 23);
			String overall_quality_score = getListData(tempList, 24);
			recordID = getListData(tempList, 25);
			if (srhDashboardOverviewID.length() > 0) {
				srhYear = getListData(tempList, 26);
				srhWeek = getListData(tempList, 27);
			}
			String rank = "";
			String packages = "";

			String dataArray[] = getDateRangeByWeekOfYear(srhYear, srhWeek);
			String srhFromDate = dataArray[0];
			String srhToDate = dataArray[1];
			targetDate = dataArray[2];
			String weekDates = dataArray[3];

			selQry = "SELECT A.EMAIL FROM CONTACT A, EMPLOYEE B WHERE "
					+ "A.CONTACTID=B.CONTACTID AND B.STATUS!="
					+ RecordStatus.DELETE + " AND A.STATUS!="
					+ RecordStatus.DELETE + " AND B.ENTITYID=" + entityID
					+ db.getDataInCondQuery(transporter_id, "B.TRANSPORTERID");
			String email = db.selectById(selQry);

			/*-
			selQry = "SELECT DISPATCHED_PACKAGES, DILIVERED_PACKAGES "
					+ "FROM DELIVERY_OVERVIEW WHERE STATUS="
					+ RecordStatus.ACTIVE + " AND ENTITYID=" + entityID
					+ db.getIDInCondQuery(srhYear, "DELIVERY_YEAR")
					+ db.getIDInCondQuery(srhWeek, "DELIVERY_WEEK")
					+ " ORDER BY 1";
			resultList = db.selectAsList(selQry, 2);
			for (int i = 0; i < resultList.size(); i++) {
				tempList = (ArrayList) resultList.get(i);
				String dispatched_packages = getListData(tempList, 0);
				String delivered_packages = getListData(tempList, 1);
				packages = dispatched_packages + " / " + delivered_packages;
			}
			 */

			selQry = "SELECT DASHBOARD_OVERVIEWID, TRANSPORTERID "
					+ "FROM DASHBOARD_OVERVIEW WHERE STATUS="
					+ RecordStatus.ACTIVE + " AND ENTITYID=" + entityID
					+ db.getIDInCondQuery(srhYear, "DASHBOARD_YEAR")
					+ db.getIDInCondQuery(srhWeek, "DASHBOARD_WEEK")
					+ " ORDER BY 1";
			resultList = db.selectAsList(selQry, 2);
			for (int i = 0; i < resultList.size(); i++) {
				tempList = (ArrayList) resultList.get(i);
				String transporter_id1 = getListData(tempList, 1);
				if (transporter_id.equalsIgnoreCase(transporter_id1)) {
					rank = (i + 1) + " / " + resultList.size();
					break;
				}
			}

			// Section 1
			section1List = buildDataList("Year", srhYear, section1List);
			section1List = buildDataList("Week", srhWeek, section1List);
			section1List = buildDataList("Name", delivery_associate,
					section1List);
			section1List = buildDataList("OnRoad Safety Score",
					onroad_safety_score, section1List);
			section1List = buildDataList("Overall Quality Score",
					overall_quality_score, section1List);
			section1List = buildDataList("Overall Tier", overall_standing,
					section1List);
			section1List = buildDataList("Packages", packages, section1List);
			section1List = buildDataList("Rank", rank, section1List);
			section1List = buildDataList("Email", email, section1List);

			float minVal = 0.0f;
			// Section 2
			qualityList = buildDataList(
					"Customer Delivery Feedback Defect Per Million Opportunites",
					cdf_dpmo, qualityList, minVal);
			qualityList = buildDataList("Delivery Completion Rate", dcr,
					qualityList, minVal);
			qualityList = buildDataList("Delivery Success Behaviours", dsb,
					qualityList, minVal);
			qualityList = buildDataList("SWC POD", swc_pod, qualityList,
					minVal);
			qualityList = buildDataList("DNRs", dnrs, qualityList, minVal);
			qualityList = buildDataList("Customer Escalation Defect",
					cust_escalation_defect, qualityList, minVal);
			qualityList = buildDataList("Customer Delivery Feedback",
					cust_delivery_feedback, qualityList, minVal);

			safetyList = buildDataList("Distraction", distraction, safetyList,
					minVal);
			safetyList = buildDataList("Seatbelt Off Rate", seatbelt_off_rate,
					safetyList, minVal);
			safetyList = buildDataList("Speeding", speeding, safetyList,
					minVal);
			safetyList = buildDataList("Speeding Event Rate",
					speeding_event_rate, safetyList, minVal);
			safetyList = buildDataList("Distraction Rate", distraction_rate,
					safetyList, minVal);
			safetyList = buildDataList("Looking At Phone", looking_at_phone,
					safetyList, minVal);
			safetyList = buildDataList("Talking On Phone", talking_on_phone,
					safetyList, minVal);
			safetyList = buildDataList("Looking Down", looking_down, safetyList,
					minVal);
			safetyList = buildDataList("Following Distance Rate",
					following_distance_rate, safetyList, minVal);
			safetyList = buildDataList("SignOrSignal Violations Rate",
					sign_or_signal_violation_rate, safetyList, minVal);
			safetyList = buildDataList("Stop Sign Violations",
					stop_sign_violations, safetyList, minVal);
			safetyList = buildDataList("Stop Light Violations",
					stop_light_violations, safetyList, minVal);
			safetyList = buildDataList("Illegal U-Turns", illegal_u_turns,
					safetyList, minVal);

			selQry = "SELECT A.EMPLOYEEINCIDENTID, "
					+ db.getSelectDate("A.INCIDENTDATE")
					+ ", A.TYPEOFINCIDENT, A.INCIDENTDESCRIPTION FROM "
					+ "EMPLOYEEINCIDENT A, EMPLOYEE B WHERE "
					+ "A.EMPLOYEEID=B.EMPLOYEEID AND A.STATUS!="
					+ RecordStatus.DELETE + " AND A.ENTITYID=" + entityID
					+ db.getDataInCondQuery(transporter_id, "B.TRANSPORTERID")
					+ db.getDateCondQuery(srhFromDate, srhToDate,
							"A.INCIDENTDATE");
			accidentsList = db.selectAsList(selQry, 4);

			selQry = "SELECT A.INCIDENTSID, "
					+ db.getSelectDate("A.INCIDENT_DATE")
					+ ", A.INCIDENTTYPEID, A.DESCRIPTION "
					+ "FROM INCIDENTS A, EMPLOYEE B WHERE "
					+ "A.EMPLOYEEID=B.EMPLOYEEID AND A.STATUS!="
					+ RecordStatus.DELETE + " AND A.ENTITYID=" + entityID
					+ db.getDataInCondQuery(transporter_id, "B.TRANSPORTERID")
					+ db.getDateCondQuery(srhFromDate, srhToDate,
							"A.INCIDENT_DATE");
			incidentList = db.selectAsList(selQry, 4);
			if (incidentList.size() > 0) {
				Map<String, String> _typeMap = getAdminDataMap(
						enumSuggestorTypes.incidentTypes.toString(), "",
						entityID, true);
				for (int i = 0; i < incidentList.size(); i++) {
					tempList = (ArrayList) incidentList.get(i);
					String typeID = tempList.get(2) == null ? ""
							: tempList.get(2).toString().trim();
					String typeName = _typeMap.get(typeID) == null ? typeID
							: _typeMap.get(typeID);
					tempList.set(2, typeName);
					incidentList.set(i, tempList);
				}
			}

			// srhWeek = "13";
			selQry = "SELECT " + db.getSelectDate("B.EOC_DATE")
					+ ", B.DAILY_AVERAGE "
					+ " FROM EOCOVERVIEW A, EOCOVERVIEWTRANS B WHERE "
					+ "A.EOCOVERVIEWID=B.EOCOVERVIEWID AND A.STATUS!="
					+ RecordStatus.DELETE + " AND B.STATUS!="
					+ RecordStatus.DELETE + " AND A.ENTITYID=" + entityID
					+ db.getIDInCondQuery(srhYear, "A.EOC_YEAR")
					+ db.getIDInCondQuery(srhWeek, "A.EOC_WEEK")
					+ db.getDataInCondQuery(transporter_id, "A.TRANSPORTERID");
			List tempResultsList = db.selectAsList(selQry, 2);
			Map<String, String> _eocMap = getMap(tempResultsList);

			selQry = "SELECT " + db.getSelectDate("STARTTIME") + ", DURATION "
					+ " FROM DVIC WHERE STATUS!=" + RecordStatus.DELETE
					+ " AND ENTITYID=" + entityID
					+ db.getIDInCondQuery(srhYear, "DVIC_YEAR")
					+ db.getIDInCondQuery(srhWeek, "DVIC_WEEK")
					+ db.getDataInCondQuery(transporter_id, "TRANSPORTERID");
			tempResultsList = db.selectAsList(selQry, 2);
			Map<String, String> _dvicMap = getMap(tempResultsList);

			if (_eocMap.size() > 0 || _dvicMap.size() > 0) {
				boolean isData1Present = false, isData2Present = false;
				List<String> dateList = new ArrayList<String>();
				dateList.add("");

				List<String> data1List = new ArrayList<String>();
				data1List.add("DVIC");

				List<String> data2List = new ArrayList<String>();
				data2List.add("EOC");

				// weekDates = "03/23/2025 @@ 03/24/2025 @@ 03/25/2025 @@
				// 03/26/2025 @@ 03/27/2025 @@ 03/28/2025 @@ 03/29/2025";
				String splitArray[] = weekDates.split("@@");
				for (int i = 0; i < splitArray.length; i++) {
					String dateKey = splitArray[i].trim();
					if (dateKey.length() > 0) {
						dateList.add(dateKey);
						if (_dvicMap.size() > 0) {
							String value = _dvicMap.get(dateKey) == null ? ""
									: _dvicMap.get(dateKey);
							if ("0.0".equalsIgnoreCase(value))
								value = "";
							data1List.add(value);
							if (value.length() > 0)
								isData1Present = true;
						}

						if (_eocMap.size() > 0) {
							String value = _eocMap.get(dateKey) == null ? ""
									: _eocMap.get(dateKey);
							if ("0.0".equalsIgnoreCase(value))
								value = "";
							data2List.add(value);
							if (value.length() > 0)
								isData2Present = true;
						}
					}
				}

				dvicList.add(dateList);
				if (isData1Present)
					dvicList.add(data1List);
				if (isData2Present)
					dvicList.add(data2List);

			}
		}

		return new Object[] { recordID, targetDate, section1List, safetyList,
				qualityList, accidentsList, incidentList, dvicList };
	}

	public String[] getDateRangeByWeekOfYear(String srhYear, String srhWeek)
			throws Exception {

		GregorianCalendar weekCal = new GregorianCalendar();
		weekCal.setTime(sdfMMDDYYYY.parse("01/01/" + srhYear));

		weekCal.set(Calendar.WEEK_OF_YEAR, Integer.parseInt(srhWeek));
		weekCal.set(Calendar.DAY_OF_WEEK, Calendar.SUNDAY);
		String srhFromDate = sdfMMDDYYYY.format(weekCal.getTime());
		String srhToDate = "";
		String weekDates = srhFromDate;
		for (int i = 0; i < 6; i++) {
			weekCal.add(Calendar.DAY_OF_YEAR, 1);
			srhToDate = sdfMMDDYYYY.format(weekCal.getTime());
			weekDates += " @@ " + srhToDate;
		}
		weekCal = new GregorianCalendar();
		weekCal.add(Calendar.DAY_OF_YEAR, 13);
		String targetDate = sdfMMDDYYYY.format(weekCal.getTime());

		return new String[] { srhFromDate, srhToDate, targetDate, weekDates };
	}

	public String getPast6WeeksCondQry(String srhYear, String srhWeek)
			throws Exception {

		String returnYearWeeks = "";
		GregorianCalendar weekCal = new GregorianCalendar();
		weekCal.setTime(sdfMMDDYYYY.parse("01/01/" + srhYear));

		weekCal.set(Calendar.WEEK_OF_YEAR, Integer.parseInt(srhWeek));
		weekCal.set(Calendar.DAY_OF_WEEK, Calendar.SUNDAY);
		for (int i = 0; i < 6; i++) {
			weekCal.add(Calendar.DAY_OF_YEAR, -7);
			int weekNum = weekCal.get(Calendar.WEEK_OF_YEAR);
			int yearNum = weekCal.get(Calendar.YEAR);

			if (returnYearWeeks.length() > 0)
				returnYearWeeks += " OR ";
			returnYearWeeks += "(DASHBOARD_YEAR IN (" + yearNum
					+ ")  AND DASHBOARD_WEEK IN (" + weekNum + "))";
		}

		System.out.println("getPast6Weeks :: " + srhYear + " :: " + srhWeek
				+ " :: " + returnYearWeeks);
		return returnYearWeeks;
	}

	public List buildDataList(String label, String value, List returnList) {

		List<String> tempRow = new ArrayList<String>();
		tempRow.add(label);
		tempRow.add(value);
		returnList.add(tempRow);
		return returnList;

	}

	public List buildDataList(String label, String value, List returnList,
			float minVal) {

		if (value.length() > 0) {
			float floatVal = Float.parseFloat(value);
			if (floatVal > minVal) {
				List<String> tempRow = new ArrayList<String>();
				tempRow.add(label);
				tempRow.add(value);
				returnList.add(tempRow);
			}
		}

		return returnList;
	}

	@Override
	public String getAjaxRequestTypeResp(String requestType,
			Map<String, String> requestMap, String loginUser,
			String loginUserRoles, String loginUserID, String entityID)
			throws Exception {

		String xmlMesg = "";
		String srhYear = requestMap.get("srhYear") == null ? ""
				: requestMap.get("srhYear");
		String srhWeek = requestMap.get("srhWeek") == null ? ""
				: requestMap.get("srhWeek");
		String shrTransporterID = requestMap.get("srhTransporterID") == null
				? ""
				: requestMap.get("srhTransporterID");
		if (srhYear.length() == 0 || srhWeek.length() == 0) {
			return xmlMesg;
		}

		if ("employeeList".equalsIgnoreCase(requestType)) {
			String selQry = "SELECT DASHBOARD_OVERVIEWID, TRANSPORTERID, "
					+ "DELIVERYASSOCIATE, OVERALLSTANDING, ONROADSAFETYSCORE, "
					+ "OVERALLQUALITYSCORE, DASHBOARD_YEAR, DASHBOARD_WEEK, 0 FROM "
					+ "DASHBOARD_OVERVIEW WHERE STATUS=" + RecordStatus.ACTIVE
					+ " AND ENTITYID=" + entityID
					+ db.getIDInCondQuery(srhYear, "DASHBOARD_YEAR")
					+ db.getIDInCondQuery(srhWeek, "DASHBOARD_WEEK")
					+ " ORDER BY 1";

			List resultList = db.selectAsList(selQry, 9);
			if (resultList.size() > 0) {
				String yearWeekCondQry = getPast6WeeksCondQry(srhYear, srhWeek);

				selQry = "SELECT DISTINCT B.TRANSPORTERID, A.EMAIL FROM "
						+ "CONTACT A, EMPLOYEE B, DASHBOARD_OVERVIEW C "
						+ "WHERE A.CONTACTID=B.CONTACTID AND "
						+ "LOWER(B.TRANSPORTERID)=LOWER(C.TRANSPORTERID) AND "
						+ "B.STATUS!=" + RecordStatus.DELETE + " AND A.STATUS!="
						+ RecordStatus.DELETE + " AND B.ENTITYID=" + entityID
						+ db.getIDInCondQuery(srhYear, "C.DASHBOARD_YEAR")
						+ db.getIDInCondQuery(srhWeek, "C.DASHBOARD_WEEK");
				List employeeEmailList = db.selectAsList(selQry, 2);
				Map<String, String> _emailMap = getMap(employeeEmailList);
				for (int i = 0; i < resultList.size(); i++) {
					List tempList = (ArrayList) resultList.get(i);
					String transporter_id = getListData(tempList, 1);
					String email = _emailMap.get(transporter_id) == null ? ""
							: _emailMap.get(transporter_id);

					int fantasticCNT = 0, greatCNT = 0, fairCNT = 0,
							poorCNT = 0;
					selQry = "SELECT DASHBOARD_OVERVIEWID, OVERALLSTANDING FROM "
							+ "DASHBOARD_OVERVIEW WHERE STATUS="
							+ RecordStatus.ACTIVE + " AND ENTITYID=" + entityID
							+ db.getDataInCondQuery(transporter_id,
									"TRANSPORTERID")
							+ " AND (" + yearWeekCondQry + ") ORDER BY 1";
					List overallTierList = db.selectAsList(selQry, 2);
					for (int j = 0; j < overallTierList.size(); j++) {
						List tempList1 = (ArrayList) overallTierList.get(j);
						String data = getListData(tempList1, 1).toLowerCase();
						if (data.contains("fant"))
							fantasticCNT++;
						else if (data.contains("great"))
							greatCNT++;
						else if (data.contains("fair"))
							fairCNT++;
						else if (data.contains("poor"))
							poorCNT++;
					}
					tempList.set(8, email);
					tempList.add(fantasticCNT + "");
					tempList.add(greatCNT + "");
					tempList.add(fairCNT + "");
					tempList.add(poorCNT + "");
				}
			}

			xmlMesg = getXmlData(requestType, resultList,
					new String[] { "dashboard_overviewid", "transporter_id",
							"delivery_associate", "overall_standing",
							"onroad_safety_score", "overall_quality_score",
							"dashboard_year", "dashboard_week", "email",
							"fantasticCNT", "greatCNT", "fairCNT", "poorCNT" });

		} else if ("employeeData".equalsIgnoreCase(requestType)) {
			String srhDashboardOverviewID = requestMap
					.get("srhDashboardOverviewID") == null ? ""
							: requestMap.get("srhDashboardOverviewID");
			Object returnObArray[] = getEmployeeData(srhYear, srhWeek,
					shrTransporterID, srhDashboardOverviewID, entityID);

			xmlMesg = buildEmployeeDataXML(returnObArray, shrTransporterID,
					srhDashboardOverviewID).toString();
		}

		return xmlMesg;
	}

	private String buildEmployeeDataXML(Object[] dataObjArray,
			String shrTransporterID, String srhDashboardOverviewID) {

		String dashboardOverviewID = dataObjArray[0].toString();
		String followupTargetDate = dataObjArray[1].toString();
		List section1List = (ArrayList) dataObjArray[2];
		List safetyList = (ArrayList) dataObjArray[3];
		List qualityList = (ArrayList) dataObjArray[4];
		List accidentList = (ArrayList) dataObjArray[5];
		List incidentList = (ArrayList) dataObjArray[6];
		List dvicList = (ArrayList) dataObjArray[7];
		String coachingFollowupID = "";

		try {
			String selQry = "SELECT COACHING_FOLLOWUPID FROM COACHING_FOLLOWUP "
					+ "WHERE STATUS IN (" + RecordStatus.ACTIVE + ","
					+ RecordStatus.POST + ") AND DASHBOARD_OVERVIEWID="
					+ dashboardOverviewID;
			if (dashboardOverviewID.length() > 0)
				coachingFollowupID = db.selectById(selQry);
		} catch (Exception ex) {
			ex.printStackTrace();
		}

		StringBuffer buff = new StringBuffer();
		buff.append("<employeeDataList>");
		buff = buildXML("dashboardOverviewID", dashboardOverviewID, buff);
		buff = buildXML("coachingFollowupID", coachingFollowupID, buff);
		buff = buildXML("followupTargetDate", followupTargetDate, buff);
		buff = buildXML("shrTransporterID", shrTransporterID, buff);

		buff.append("<section1List>");
		for (int i = 0; i < section1List.size(); i++) {
			List tempList = (ArrayList) section1List.get(i);
			String label = getListData(tempList, 0);
			String value = getListData(tempList, 1);

			buff.append("<section1ListTrans>");
			buff = buildXML("label", label, buff);
			buff = buildXML("value", value, buff);
			buff.append("</section1ListTrans>");
		}
		buff.append("</section1List>");

		buff.append("<qualityList>");
		for (int i = 0; i < qualityList.size(); i++) {
			List tempList = (ArrayList) qualityList.get(i);
			String label = getListData(tempList, 0);
			String value = getListData(tempList, 1);

			buff.append("<qualityListTrans>");
			buff = buildXML("label", label, buff);
			buff = buildXML("value", value, buff);
			buff.append("</qualityListTrans>");
		}
		buff.append("</qualityList>");

		buff.append("<safetyList>");
		for (int i = 0; i < safetyList.size(); i++) {
			List tempList = (ArrayList) safetyList.get(i);
			String label = getListData(tempList, 0);
			String value = getListData(tempList, 1);

			buff.append("<safetyListTrans>");
			buff = buildXML("label", label, buff);
			buff = buildXML("value", value, buff);
			buff.append("</safetyListTrans>");
		}
		buff.append("</safetyList>");

		buff.append("<incidentList>");
		for (int i = 0; i < incidentList.size(); i++) {
			List tempList = (ArrayList) incidentList.get(i);
			String incidentID = getListData(tempList, 0);
			String incidentDate = getListData(tempList, 1);
			String incidentType = getListData(tempList, 2);
			String incidentDesc = getListData(tempList, 3);

			buff.append("<incidentListTrans>");
			buff = buildXML("incidentID", incidentID, buff);
			buff = buildXML("incidentDate", incidentDate, buff);
			buff = buildXML("incidentType", incidentType, buff);
			buff = buildXML("incidentDesc", incidentDesc, buff);
			buff.append("</incidentListTrans>");
		}
		buff.append("</incidentList>");

		buff.append("<accidentList>");
		for (int i = 0; i < accidentList.size(); i++) {
			List tempList = (ArrayList) accidentList.get(i);
			String incidentID = getListData(tempList, 0);
			String incidentDate = getListData(tempList, 1);
			String incidentType = getListData(tempList, 2);
			String incidentDesc = getListData(tempList, 3);

			buff.append("<accidentListTrans>");
			buff = buildXML("incidentID", incidentID, buff);
			buff = buildXML("incidentDate", incidentDate, buff);
			buff = buildXML("incidentType", incidentType, buff);
			buff = buildXML("incidentDesc", incidentDesc, buff);
			buff.append("</accidentListTrans>");
		}
		buff.append("</accidentList>");

		buff.append("<dvicList>");
		for (int i = 0; i < dvicList.size(); i++) {
			List tempList = (ArrayList) dvicList.get(i);
			String dvicLabel = getListData(tempList, 0);
			String dvicValue1 = getListData(tempList, 1);
			String dvicValue2 = getListData(tempList, 2);
			String dvicValue3 = getListData(tempList, 3);
			String dvicValue4 = getListData(tempList, 4);
			String dvicValue5 = getListData(tempList, 5);
			String dvicValue6 = getListData(tempList, 6);
			String dvicValue7 = getListData(tempList, 7);

			buff.append("<dvicListTrans>");
			buff = buildXML("dvicLabel", dvicLabel, buff);
			buff = buildXML("dvicValue1", dvicValue1, buff);
			buff = buildXML("dvicValue2", dvicValue2, buff);
			buff = buildXML("dvicValue3", dvicValue3, buff);
			buff = buildXML("dvicValue4", dvicValue4, buff);
			buff = buildXML("dvicValue5", dvicValue5, buff);
			buff = buildXML("dvicValue6", dvicValue6, buff);
			buff = buildXML("dvicValue7", dvicValue7, buff);
			buff.append("</dvicListTrans>");
		}
		buff.append("</dvicList>");
		buff.append("</employeeDataList>");

		return buff.toString();
	}

	@Override
	public Object[] createRecord(MainBean mainBean, String loginUser,
			String loginUserRoles, String loginUserID, String entityID)
			throws Exception {

		bean = (EmployeeDashboard) mainBean;
		ErrorBean errorType = new ErrorBean();
		List<String> insList = new ArrayList<String>();
		String selQry = "SELECT COACHING_FOLLOWUPID FROM COACHING_FOLLOWUP "
				+ "WHERE STATUS IN (" + RecordStatus.ACTIVE + ","
				+ RecordStatus.POST + ") "
				+ db.getIDInCondQuery(entityID, "ENTITYID")
				+ db.getIDInCondQuery(bean.getDashboardOverviewID(),
						"DASHBOARD_OVERVIEWID");
		String recordID = db.selectById(selQry);

		if (recordID.length() == 0) {
			recordID = db.getNextIDValue("COACHING_FOLLOWUPID");

			String insQry = "INSERT INTO COACHING_FOLLOWUP (COACHING_FOLLOWUPID, "
					+ "ENTITYID, DASHBOARD_OVERVIEWID, CREATE_USER, CREATE_DATE, "
					+ "STATUS) VALUES (" + recordID + ", " + entityID + ", "
					+ bean.getDashboardOverviewID() + ", "
					+ db.getInsertDBValue(loginUser) + ", "
					+ db.getInsertSysdate() + ", " + RecordStatus.ACTIVE + ")";
			insList.add(insQry);

		} else {
			/*-
			insList.add(
					buildStatusQry("COACHING_FOLLOWUP", "COACHING_FOLLOWUPID",
							recordID, RecordStatus.ACTIVE, loginUser));
			
			insList.add(buildStatusQry("COACHING_FOLLOWUPTRANS",
					"COACHING_FOLLOWUPID", recordID, RecordStatus.DELETE,
					loginUser));
			*/
			errorType = getErrorType(false, SubmitType.CREATE,
					"Coaching Followup");

			return new Object[] { recordID, errorType };
		}

		for (int i = 0; i < bean.getTransList().size(); i++) {
			List tempList = (ArrayList) bean.getTransList().get(i);
			String category = getListData(tempList, 0);
			String metric = getListData(tempList, 1);
			String coachingOwner = getListData(tempList, 2);
			String targetDate = getListData(tempList, 3);
			String coachingStatus = getListData(tempList, 4);
			String comments = getListData(tempList, 5);

			if (coachingOwner.length() > 0) {
				String transID = db.getNextIDValue("COACHING_FOLLOWUPTRANSID");
				String insQry = "INSERT INTO COACHING_FOLLOWUPTRANS ("
						+ "COACHING_FOLLOWUPTRANSID, COACHING_FOLLOWUPID, "
						+ "CATEGORY, METRIC, COACHINGOWNER, TARGET_DATE, "
						+ "COACHING_STATUS, COMMENTS, CREATE_USER, CREATE_DATE, "
						+ "STATUS) VALUES (" + transID + ", " + recordID + ", "
						+ db.getInsertDBValue(category) + ", "
						+ db.getInsertDBValue(metric) + ", "
						+ db.getInsertDBValue(coachingOwner) + ", "
						+ db.getInsertDate(targetDate) + ", "
						+ db.getInsertDBValue(coachingStatus) + ", "
						+ db.getInsertDBValue(comments) + ", "
						+ db.getInsertDBValue(loginUser) + ", "
						+ db.getInsertSysdate() + ", " + RecordStatus.ACTIVE
						+ ")";
				insList.add(insQry);

				String autoIncrementArray[] = db
						.getAutoIncrementArray("COACHING_FOLLOWUPSTATUSID");
				insQry = "INSERT INTO COACHING_FOLLOWUPSTATUS (";
				if (autoIncrementArray != null)
					insQry += autoIncrementArray[0];
				insQry += "COACHING_FOLLOWUPTRANSID, COACHING_STATUS, "
						+ "COMMENTS, CREATE_USER, CREATE_DATE, "
						+ "STATUS) VALUES (";
				if (autoIncrementArray != null)
					insQry += autoIncrementArray[1];
				insQry += transID + ", " + db.getInsertDBValue(coachingStatus)
						+ ", " + db.getInsertDBValue(comments) + ", "
						+ db.getInsertDBValue(loginUser) + ", "
						+ db.getInsertSysdate() + ", " + RecordStatus.ACTIVE
						+ ")";
				insList.add(insQry);
			}
		}

		boolean result = db.batchInsert(insList);

		errorType = getErrorType(result, SubmitType.CREATE,
				"Coaching Followup");

		return new Object[] { recordID, errorType };
	}

	@Override
	public EmployeeDashboard fetchRecord(String recordID, String loginUser,
			String loginUserRoles, String loginUserID, String entityID,
			int submitType) throws Exception {

		return new EmployeeDashboard();
	}
}
