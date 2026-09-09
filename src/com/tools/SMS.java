package com.tools;

import java.net.URI;
import java.util.Properties;

import com.beans.AdminConfiguration;
import com.dataobjects.AdminConfigurationDAO;
import com.twilio.Twilio;
import com.twilio.rest.api.v2010.account.Message;
import com.twilio.rest.api.v2010.account.Message.Status;
import com.twilio.type.PhoneNumber;

public class SMS {

	public String getMobileNum(String input) {

		if (input.length() > 0) {
			input = input.replace("(", "");
			input = input.replace(")", "");
			input = input.replace("-", "");
			input = input.replace(" ", "");
		}

		return input;
	}

	public String buildTemplate(String firstName, String dayOfWeek,
			String mmSdd, String waveTime, String mesgTemp) {

		mesgTemp = mesgTemp.replace("##firstName##", firstName);
		mesgTemp = mesgTemp.replace("##dayOfWeek##", dayOfWeek);
		mesgTemp = mesgTemp.replace("##mmSdd##", mmSdd);
		mesgTemp = mesgTemp.replace("##waveTime##", waveTime);
		return mesgTemp;
	}

	public String buildDynTemplate(String fromVal, String toVal,
			String mesgTemp) {

		mesgTemp = mesgTemp.replace(fromVal, toVal);
		return mesgTemp;
	}

	public String[] getSMSGatewayDetailsArray(Properties prop) {

		AdminConfigurationDAO configDAO = new AdminConfigurationDAO();
		String SMS_GATEWAY = configDAO.getPropertyValue(
				AdminConfiguration.enumSMS.SMS_GATEWAY.toString(), prop);
		String fromPhoneNum = "";
		String SMS_ACCOUNT_SID = "";
		String SMS_ACCOUNT_AUTH_TOKEN = "";

		if ("Twilio".equalsIgnoreCase(SMS_GATEWAY)) {
			fromPhoneNum = configDAO.getPropertyValue(
					AdminConfiguration.enumSMS.TwilioPrimaryNum.toString(),
					prop);
			SMS_ACCOUNT_SID = configDAO.getPropertyValue(
					AdminConfiguration.enumSMS.TwilioAccountSID.toString(),
					prop);
			SMS_ACCOUNT_AUTH_TOKEN = configDAO.getPropertyValue(
					AdminConfiguration.enumSMS.TwilioAuthToken.toString(),
					prop);
		}

		return new String[] { SMS_GATEWAY, SMS_ACCOUNT_SID,
				SMS_ACCOUNT_AUTH_TOKEN, fromPhoneNum };
	}

	public Object[] sendSMS(int messageType, String communicationType,
			String toPhoneNum, String mesgBody, String mediaURL,
			Properties prop, String entityID) {

		System.out.println(this.getClass().getSimpleName() + ".sendSMS :: "
				+ entityID + " :: " + messageType + " :: " + communicationType
				+ " :: " + toPhoneNum + " :: " + mesgBody + " :: " + mediaURL);

		try {
			if (toPhoneNum.length() == 0 || mesgBody.length() == 0) {
				return new Object[] { false };
			}

			String array[] = getSMSGatewayDetailsArray(prop);
			String SMS_GATEWAY = array[0];
			if ("Twilio".equalsIgnoreCase(SMS_GATEWAY)) {
				// Twilio
				String SMS_ACCOUNT_SID = array[1];
				String SMS_ACCOUNT_AUTH_TOKEN = array[2];
				String fromPhoneNum = array[3];
				if ("WhatsApp".equalsIgnoreCase(communicationType)) {
					communicationType = "whatsapp:";
				} else {
					communicationType = "";
				}

				if (SMS_ACCOUNT_SID.length() > 0
						&& SMS_ACCOUNT_AUTH_TOKEN.length() > 0
						&& fromPhoneNum.length() > 0) {

					return twilioGateway(SMS_ACCOUNT_SID,
							SMS_ACCOUNT_AUTH_TOKEN, communicationType,
							fromPhoneNum, toPhoneNum, mesgBody, mediaURL);
				} else {
					System.out.println("Twilio SMS not configured");
				}
			}

		} catch (Exception ex) {
			ex.printStackTrace();
		}

		return new Object[] { false };

	}

	private Object[] twilioGateway(String SMS_ACCOUNT_SID,
			String SMS_ACCOUNT_AUTH_TOKEN, String communicationType,
			String fromPhoneNum, String toPhoneNum, String mesgBody,
			String mediaURL) throws Exception {

		Twilio.init(SMS_ACCOUNT_SID, SMS_ACCOUNT_AUTH_TOKEN);

		System.out.println("Twilio.initialized :: " + communicationType + " :: "
				+ fromPhoneNum + " :: " + toPhoneNum + " :: " + mesgBody);

		Message message = null;
		if (mediaURL.length() > 0) {
			message = Message
					.creator(new PhoneNumber(communicationType + toPhoneNum),
							new PhoneNumber(communicationType + fromPhoneNum),
							mesgBody)
					.setMediaUrl(new URI(mediaURL)).create();
		} else {
			message = Message
					.creator(new PhoneNumber(communicationType + toPhoneNum),
							new PhoneNumber(communicationType + fromPhoneNum),
							mesgBody)
					.create();
		}

		Object[] returnObjArray = getMessageStatus(fromPhoneNum, message);

		return returnObjArray;
	}

	public Object[] getMessageStatus(String fromPhoneNum, Message message)
			throws Exception {

		boolean isSent = false;
		String messageAccountID = "";
		String messageServiceID = "";
		String messageSID = "";
		String messageStatus = "";
		String messageErrorCodeStr = "", messageErrorDesc = "";
		if (message != null) {
			Status messageTransactionStatus = message.getStatus();
			messageStatus = messageTransactionStatus.toString();

			messageAccountID = message.getAccountSid() == null ? ""
					: message.getAccountSid();
			// apiVersion = message.getApiVersion();
			// messageBody = message.getBody();
			messageSID = message.getSid() == null ? "" : message.getSid();
			messageServiceID = message.getMessagingServiceSid() == null ? ""
					: message.getMessagingServiceSid();

			int messageErrorCode = 0;
			if (message.getErrorCode() != null)
				messageErrorCode = message.getErrorCode();

			if (messageErrorCode > 0)
				messageErrorCodeStr = Integer.toString(messageErrorCode);

			if (message.getErrorMessage() != null)
				messageErrorDesc = message.getErrorMessage();

			if (messageSID.length() > 0)
				isSent = true;
		}

		System.out.println("getMessageStatus :: " + isSent + " :: "
				+ fromPhoneNum + " :: " + messageSID + " :: " + messageAccountID
				+ " :: " + messageStatus + " :: " + messageErrorCodeStr + " :: "
				+ messageErrorDesc + " :: " + messageServiceID);

		return new Object[] { isSent, fromPhoneNum, messageSID,
				messageAccountID, messageStatus, messageErrorCodeStr,
				messageErrorDesc, messageServiceID };
	}
}
