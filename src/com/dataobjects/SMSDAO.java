package com.dataobjects;

import java.util.ArrayList;
import java.util.Calendar;
import java.util.GregorianCalendar;
import java.util.List;
import java.util.Map;
import java.util.Properties;

import com.beans.AdminConfiguration;
import com.tools.SMS;
import com.util.RecordStatus;

public class SMSDAO extends MVPGDAO {

	static final String englishDayOfWeekArray[] = new String[] { "", "Sunday",
			"Monday", "Tuesday", "Wednesday", "Thrusday", "Friday",
			"Saturday" };

	static final String spanishDayOfWeekArray[] = new String[] { "", "Domingo",
			"Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado" };

	static final String frenchDayOfWeekArray[] = new String[] { "", "Dimanche",
			"Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi" };

	public Map<String, String> getSMSSentMap(String module, String ids,
			String entityID) throws Exception {

		String selQry = "SELECT MODULEID, "
				+ db.getConcat(
						new String[] { db.getSelectDateTime("CREATE_DATE"),
								"' - '", "MESSAGESTATUS" })
				+ " FROM " + "SMSTRANSACTION WHERE STATUS="
				+ RecordStatus.ACTIVE + db.getDataInCondQuery(module, "MODULE")
				+ db.getIDInCondQuery(entityID, "ENTITYID")
				+ db.getIDInCondQuery(ids, "MODULEID");
		List smsList = db.selectAsList(selQry, 2);
		return getMap(smsList);
	}

	public List getSMSReplyMap(String module, String ids, String entityID)
			throws Exception {

		String selQry = "SELECT MODULEID, "
				+ db.getSelectDateTime("CREATE_DATE")
				+ ", REPLAYMSG, SMSTRANSACTIONTRANSID FROM "
				+ "SMSTRANSACTIONTRANS WHERE STATUS=" + RecordStatus.ACTIVE
				+ db.getDataInCondQuery(module, "MODULE")
				+ db.getIDInCondQuery(ids, "MODULEID") + " ORDER BY 1, 4";
		List smsList = db.selectAsList(selQry, 4);
		return smsList;
	}

	public boolean sendSMS(String tableName, String mesgBody, List resultList,
			String loginUser, String entityID) throws Exception {

		SMS sms = new SMS();
		AdminConfigurationDAO configDAO = new AdminConfigurationDAO();
		Properties prop = configDAO.getProperties(
				AdminConfiguration.enumCategorys.SMS.toString(), null,
				entityID);
		String smsArray[] = sms.getSMSGatewayDetailsArray(prop);
		// String SMS_GATEWAY = smsArray[0];
		String SMS_ACCOUNT_SID = smsArray[1];
		// String SMS_ACCOUNT_AUTH_TOKEN = smsArray[2];
		String fromPhoneNum = smsArray[3];

		for (int i = 0; i < resultList.size(); i++) {
			List tempList = (ArrayList) resultList.get(i);
			String id = tempList.get(0) == null ? ""
					: tempList.get(0).toString().trim();
			String mobile = tempList.get(1) == null ? ""
					: tempList.get(1).toString().trim();
			String messageStatus = "failed";

			if (mobile.length() > 0) {
				mobile = "+1" + mobile;
				boolean isSent = false;
				String messageID = "";
				String comments = "";
				String messageServiceSID = "";

				Object returnObjArray[] = new Object[] { false };
				returnObjArray = sms.sendSMS(0, "", mobile, mesgBody, "", prop,
						entityID);
				if ((Boolean) returnObjArray[0])
					isSent = (Boolean) returnObjArray[0];

				if (returnObjArray.length > 1) {
					messageID = returnObjArray[2].toString();
					messageStatus = returnObjArray[4].toString();
					comments = returnObjArray[5].toString();
					messageServiceSID = returnObjArray[7].toString();
				}

				if (isSent) {
					messageStatus = "Sent";
				}

			} else {
				// Mobile Missing
				messageStatus = "Mobile";
			}

			String upQry = "UPDATE " + tableName + " SET MESSAGESTATUS="
					+ db.getInsertDBValue(messageStatus) + ", UPDATE_USER="
					+ db.getInsertDBValue(loginUser) + ", UPDATE_DATE="
					+ db.getInsertSysdate() + " WHERE " + tableName + "ID="
					+ id;
			try {
				db.update(upQry);
			} catch (Exception ex) {
				ex.printStackTrace();
			}
		}

		return true;
	}

	public String sendSMS(String module, Map<String, String> requestMap,
			String loginUser, String entityID) throws Exception {

		String xmlMesg = "";
		String recordIDs = requestMap.get("selRecordIDs") == null ? ""
				: requestMap.get("selRecordIDs");
		if (recordIDs.length() > 0) {
			List insList = new ArrayList();
			String failedEmp = "";
			String mobileNumMissing = "";
			String alreadySent = "";
			boolean isSent = false;
			GregorianCalendar dateCal = new GregorianCalendar();

			SMS sms = new SMS();
			AdminConfigurationDAO configDAO = new AdminConfigurationDAO();

			Properties prop = configDAO.getProperties(
					AdminConfiguration.enumCategorys.SMS.toString(), null,
					entityID);

			String mesgTemplate = configDAO
					.getPropertyValue(module + "_OutTemplate", prop);
			String timeInMins = configDAO
					.getPropertyValue(module + "_BeforeTimeInMins", prop);
			if (timeInMins.length() == 0)
				timeInMins = "25";
			int beforeTimeInMins = Integer.parseInt(timeInMins);

			if (mesgTemplate.length() == 0)
				mesgTemplate = "Hello ##firstName##, Friendly REMINDER you are "
						+ "working ##dayOfWeek## (##mmSdd##). It's Mandatory to "
						+ "be on time by ##waveTime##. Also, "
						+ "please make sure you use the TABLET to clock in "
						+ "correctly at the beginning of shift and use the "
						+ "TABLET to clock out immediately after you end work "
						+ "on Flex Also please confirm, Thanks, MVPG logistics LlC, Call @ 7328001594";

			String spanishMesgTemplate = "Hola ##firstName##, Amistoso RECORDATORIO que tu "
					+ "trabajas el ##dayOfWeek## (##mmSdd##). Es obligatorio "
					+ "llegar a tiempo a las ##waveTime##. Tambien, "
					+ "por favor asegurate de usar la TABLET para hacer clock in "
					+ "apropiadamente al incio del turno y usar la "
					+ "TABLET para hacer clock out inmediatamente al finalizar el turno y"
					+ " en Flex. Tambien, por favor Confirma, Gracias, MVPG logistics LlC, Call @ 7328001594";

			List resultList = new ArrayList();
			if ("DAStatus".equalsIgnoreCase(module)) {
				String selQry = "SELECT A.DACONFIRMATIONID, "
						+ db.getSelectDate("A.SCHEDULEDATE") + ", "
						+ db.getSelectTime("A.SCHEDULEDATE")
						+ ", B.FULLNAME, '', C.MOBILE, "
						+ db.getSelectTimeWithTypeInterval("-",
								beforeTimeInMins, "A.SCHEDULEDATE")
						+ ", A.EMPLOYEEID, B.PREFERRED_LANGUAGE FROM "
						+ "DACONFIRMATION A JOIN EMPLOYEE B ON "
						+ "A.EMPLOYEEID=B.EMPLOYEEID LEFT JOIN "
						+ "CONTACT C ON B.CONTACTID=C.CONTACTID WHERE A.ENTITYID="
						+ entityID
						+ db.getIDInCondQuery(recordIDs, "A.DACONFIRMATIONID");
				resultList = db.selectAsList(selQry, 9);

			} else if ("DACheckin".equalsIgnoreCase(module)) {
				String selQry = "SELECT A.DACHECKINID, "
						+ db.getSelectDate("A.CLOCKINTIME") + ", "
						+ db.getSelectTime("A.CLOCKINTIME")
						+ ", B.FULLNAME, A.WAVE, C.MOBILE, "
						+ db.getSelectTimeWithTypeInterval("-",
								beforeTimeInMins, "A.CLOCKINTIME")
						+ ", A.EMPLOYEEID, B.PREFERRED_LANGUAGE FROM "
						+ "DACHECKIN A JOIN EMPLOYEE B ON "
						+ "A.EMPLOYEEID=B.EMPLOYEEID LEFT JOIN "
						+ "CONTACT C ON B.CONTACTID=C.CONTACTID WHERE A.ENTITYID="
						+ entityID
						+ db.getIDInCondQuery(recordIDs, "A.DACHECKINID");
				resultList = db.selectAsList(selQry, 9);
			}

			if (resultList.size() > 0) {
				String smsArray[] = sms.getSMSGatewayDetailsArray(prop);
				// String SMS_GATEWAY = smsArray[0];
				String SMS_ACCOUNT_SID = smsArray[1];
				// String SMS_ACCOUNT_AUTH_TOKEN = smsArray[2];
				String fromPhoneNum = smsArray[3];

				for (int i = 0; i < resultList.size(); i++) {
					List tempList = (ArrayList) resultList.get(i);
					String id = tempList.get(0) == null ? ""
							: tempList.get(0).toString().trim();
					String clockInDate = tempList.get(1) == null ? ""
							: tempList.get(1).toString().trim();
					String waveTime1 = tempList.get(2) == null ? ""
							: tempList.get(2).toString().trim();
					String empName = tempList.get(3) == null ? ""
							: tempList.get(3).toString().trim();
					String wave1 = tempList.get(4) == null ? ""
							: tempList.get(4).toString().trim();
					String mobile = tempList.get(5) == null ? ""
							: tempList.get(5).toString().trim();
					String beforeWaveTime = tempList.get(6) == null ? ""
							: tempList.get(6).toString().trim();
					String employeeID = tempList.get(7) == null ? ""
							: tempList.get(7).toString().trim();
					String preferredLanguage = tempList.get(8) == null ? ""
							: tempList.get(8).toString().trim();
					String station = "";

					if (mobile.length() > 0) {
						mobile = "+1" + mobile;
						String txID = getSMSID(module, id, mobile, "queued",
								SMS_ACCOUNT_SID, entityID);

						if (txID.length() == 0) {
							String messageStatus = "failed";

							dateCal.setTime(sdfMMDDYYYY.parse(clockInDate));

							String propName = module + "_OutTemplate_"
									+ preferredLanguage;
							String languageTemplate = configDAO
									.getPropertyValue(propName, prop);

							String dayOfWeekArray[] = englishDayOfWeekArray;
							if (languageTemplate.length() == 0) {
								if ("Spanish"
										.equalsIgnoreCase(preferredLanguage)) {
									languageTemplate = spanishMesgTemplate;
									dayOfWeekArray = spanishDayOfWeekArray;

								} else {
									// Default Template
									languageTemplate = mesgTemplate;
								}

							} else {
								// Other Language Templates
								if ("Spanish"
										.equalsIgnoreCase(preferredLanguage))
									dayOfWeekArray = spanishDayOfWeekArray;

								else if ("French"
										.equalsIgnoreCase(preferredLanguage))
									dayOfWeekArray = frenchDayOfWeekArray;

							}

							String dayWeek = dayOfWeekArray[dateCal
									.get(Calendar.DAY_OF_WEEK)];
							String mmSdd = clockInDate.substring(0, 5);

							String mesgBody = sms.buildTemplate(empName,
									dayWeek, mmSdd, beforeWaveTime,
									languageTemplate);

							String messageID = "";
							String comments = "";
							String messageServiceSID = "";
							Object returnObjArray[] = new Object[] { false };
							returnObjArray = sms.sendSMS(0, "", mobile,
									mesgBody, "", prop, entityID);
							if ((Boolean) returnObjArray[0])
								isSent = (Boolean) returnObjArray[0];

							if (returnObjArray.length > 1) {
								messageID = returnObjArray[2].toString();
								messageStatus = returnObjArray[4].toString();
								comments = returnObjArray[5].toString();
								messageServiceSID = returnObjArray[7]
										.toString();
							}

							if (isSent) {
								if ("DAStatus".equalsIgnoreCase(module)) {
									String upQry = "UPDATE DACONFIRMATION SET CONFIRMATION="
											+ db.getInsertDBValue("Sent")
											+ ", UPDATE_USER="
											+ db.getInsertDBValue(loginUser)
											+ ", UPDATE_DATE="
											+ db.getInsertSysdate()
											+ " WHERE DACONFIRMATIONID=" + id;
									insList.add(upQry);
								}

							} else {
								if (failedEmp.length() > 0)
									failedEmp += ", ";
								failedEmp += empName;
							}

							insList = buildSMSQry(station, module, id,
									fromPhoneNum, mobile, employeeID,
									SMS_ACCOUNT_SID, messageID, clockInDate,
									mesgBody.replaceAll("'", "''"),
									messageStatus, comments, messageServiceSID,
									loginUser, entityID, insList);

						} else {
							if (alreadySent.length() > 0)
								alreadySent += ", ";
							alreadySent += empName;
						}

					} else {
						if (mobileNumMissing.length() > 0)
							mobileNumMissing += ", ";
						mobileNumMissing += empName;
					}
				}
			}

			if (insList.size() > 0)
				db.batchInsert(insList);

			if (isSent)
				xmlMesg = "<status>success</status>";
			else
				xmlMesg = "<status>failed</status>";

			if (mobileNumMissing.length() > 0)
				xmlMesg += "<mobileNumMissing>" + mobileNumMissing
						+ "</mobileNumMissing>";

			if (failedEmp.length() > 0)
				xmlMesg += "<failedEmp>" + failedEmp + "</failedEmp>";

			if (alreadySent.length() > 0)
				xmlMesg += "<alreadySent>" + alreadySent + "</alreadySent>";

		} else {
			xmlMesg = "<status>failed</status>";
		}

		xmlMesg = "<statusResp>" + xmlMesg + "</statusResp>";
		return xmlMesg;
	}
}
