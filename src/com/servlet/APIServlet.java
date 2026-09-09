package com.servlet;

import java.io.BufferedReader;
import java.io.File;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.RandomAccessFile;
import java.net.URLDecoder;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Enumeration;
import java.util.HashMap;
import java.util.Map;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import com.beans.ApplicationConfig;
import com.beans.UserPreference;
import com.dataobjects.MVPGDAO;
import com.dataobjects.UserPreferenceDAO;

public class APIServlet extends HttpServlet {

	private static final long serialVersionUID = -4128287776599965906L;
	String folderPath = ApplicationConfig.getLogsPath() + File.separator
			+ "API";
	String fileNamePrefix = "API_";

	@Override
	public void init(ServletConfig config) throws ServletException {
		super.init(config);
		ApplicationConfig.update(config);
	}

	@Override
	public void doGet(HttpServletRequest req, HttpServletResponse res)
			throws ServletException, IOException {
		doPost(req, res);
	}

	@Override
	public void doPost(HttpServletRequest req, HttpServletResponse res)
			throws ServletException, IOException {
		processRequest(req, res);
	}

	private void processRequest(HttpServletRequest request,
			HttpServletResponse response) throws ServletException, IOException {

		request.setCharacterEncoding("UTF-8");
		HttpSession session = request.getSession(true);
		String requestURI = request.getRequestURI();
		String qryString = request.getQueryString();
		String contentType = request.getContentType();
		String characterEncoding = request.getCharacterEncoding();
		int contentLength = request.getContentLength();

		writeInLogFile(folderPath, fileNamePrefix, "");
		writeInLogFile(folderPath, fileNamePrefix,
				"getRequestURI :: " + requestURI);
		writeInLogFile(folderPath, fileNamePrefix,
				"getQueryString :: " + qryString);
		writeInLogFile(folderPath, fileNamePrefix,
				"getContentType :: " + contentType + " :: " + contentLength
						+ " :: " + characterEncoding);

		StringBuffer readerBuff = new StringBuffer();
		String line = null;
		try {
			BufferedReader reader = request.getReader();
			while ((line = reader.readLine()) != null)
				readerBuff.append(line);
			reader.close();
		} catch (Exception ex) {
			ex.printStackTrace();
		}
		writeInLogFile(folderPath, fileNamePrefix,
				"request.getReader :: " + readerBuff);

		if (readerBuff.length() == 0) {
			try {
				BufferedReader reader = new BufferedReader(
						new InputStreamReader(request.getInputStream()));
				while ((line = reader.readLine()) != null)
					readerBuff.append(line);
				reader.close();
			} catch (Exception ex) {
				ex.printStackTrace();
			}
			writeInLogFile(folderPath, fileNamePrefix,
					"request.getInputStream :: " + readerBuff);
		}

		Map<String, String> reqHeaderMap = getRequestHeaderValuesMap(request);

		Map<String, String> reqParamMap = getRequestParameterValuesMap(request);

		String controller = request.getParameter("controller") == null ? ""
				: request.getParameter("controller").trim();
		String responseMessage = "Message Received";

		try {
			writeInLogFile(folderPath, fileNamePrefix,
					"controller :: " + controller + " :: "
							+ "Twilio".equalsIgnoreCase(controller));
			if ("Twilio".equalsIgnoreCase(controller)) {

				reqParamMap = getRawBodytoMap(readerBuff.toString(),
						reqParamMap);

				String SmsMessageSid = reqParamMap.get("SmsMessageSid") == null
						? ""
						: reqParamMap.get("SmsMessageSid").toString().trim();
				String SmsSid = reqParamMap.get("SmsSid") == null ? ""
						: reqParamMap.get("SmsSid").toString().trim();
				String SmsStatus = reqParamMap.get("SmsStatus") == null ? ""
						: reqParamMap.get("SmsStatus").toString().trim();
				String To = reqParamMap.get("To") == null ? ""
						: reqParamMap.get("To").toString().trim();
				String Body = reqParamMap.get("Body") == null ? ""
						: reqParamMap.get("Body").toString().trim();
				String MessageSid = reqParamMap.get("MessageSid") == null ? ""
						: reqParamMap.get("MessageSid").toString().trim();
				String AccountSid = reqParamMap.get("AccountSid") == null ? ""
						: reqParamMap.get("AccountSid").toString().trim();
				String From = reqParamMap.get("From") == null ? ""
						: reqParamMap.get("From").toString().trim();
				String MessagingServiceSid = reqParamMap
						.get("MessagingServiceSid") == null ? ""
								: reqParamMap.get("MessagingServiceSid")
										.toString().trim();

				writeInLogFile(folderPath, fileNamePrefix, "To :: " + To
						+ " :: " + From + " :: " + MessageSid + " :: " + Body);
				if (To.length() > 0 && From.length() > 0) {
					if (To.length() > 0 && !To.startsWith("+"))
						To = "+" + To;

					if (From.length() > 0 && !From.startsWith("+"))
						From = "+" + From;

					writeInLogFile(folderPath, fileNamePrefix,
							"getSMSID :: " + MessagingServiceSid + " :: " + To
									+ " :: " + From + " :: " + AccountSid);

					MVPGDAO _DAO = new MVPGDAO();
					String dataArray[] = _DAO.getReplySMSID(MessagingServiceSid,
							To, From, AccountSid);
					writeInLogFile(folderPath, fileNamePrefix,
							"dataArray-1 :: " + getDataArrayValue(dataArray));

					if (dataArray == null) {
						dataArray = _DAO.getReplySMSID("", To, From,
								AccountSid);
						writeInLogFile(folderPath, fileNamePrefix,
								"dataArray-2 :: "
										+ getDataArrayValue(dataArray));
					}

					if (dataArray == null) {
						dataArray = _DAO.getReplySMSID("", "", From,
								AccountSid);
						writeInLogFile(folderPath, fileNamePrefix,
								"dataArray-3 :: "
										+ getDataArrayValue(dataArray));
					}

					if (dataArray != null) {
						writeInLogFile(folderPath, fileNamePrefix,
								"dataArray.updateSMSReply :: "
										+ getDataArrayValue(dataArray));
						_DAO.updateSMSReply(MessageSid,
								Body.replaceAll("'", "''"), "", dataArray);
					}
				}
			} else if ("UserPref".equalsIgnoreCase(controller)) {

				// Persist per-user UI preferences (theme, language, accessibility).
				// Params are read from the query string so they survive the body
				// reads above. Values are whitelisted/normalized inside the DAO.
				String prefUserID = request.getParameter("userID") == null ? ""
						: request.getParameter("userID").trim();

				if (prefUserID.length() > 0) {
					UserPreference pref = new UserPreference();
					pref.setUserID(prefUserID);
					pref.setEntityID(request.getParameter("entityID") == null ? ""
							: request.getParameter("entityID").trim());
					pref.setStation(request.getParameter("station") == null ? ""
							: request.getParameter("station").trim());
					pref.setTheme(request.getParameter("theme") == null ? ""
							: request.getParameter("theme").trim());
					pref.setLang(request.getParameter("lang") == null ? ""
							: request.getParameter("lang").trim());
					pref.setFontScale(request.getParameter("fontScale") == null ? ""
							: request.getParameter("fontScale").trim());
					pref.setA11yLarge(request.getParameter("a11yLarge") == null ? ""
							: request.getParameter("a11yLarge").trim());
					pref.setA11yContrast(request.getParameter("a11yContrast") == null ? ""
							: request.getParameter("a11yContrast").trim());
					pref.setA11yMotion(request.getParameter("a11yMotion") == null ? ""
							: request.getParameter("a11yMotion").trim());

					boolean saved = new UserPreferenceDAO().save(pref, prefUserID);
					responseMessage = saved ? "PREF_SAVED" : "PREF_SAVE_FAILED";
				} else {
					responseMessage = "PREF_NO_USER";
				}
			}

			response.getWriter()
					.print("<Message>" + responseMessage + "</Message>");
		} catch (Exception ex) {
			ex.printStackTrace();
		}
	}

	private String getDataArrayValue(String dataArray[]) {

		String dataArrayVal = "";
		if (dataArray != null) {
			for (int i = 0; i < dataArray.length; i++)
				dataArrayVal += dataArray[i] + " :: ";
		}

		return dataArrayVal;
	}

	private Map<String, String> getRawBodytoMap(String body,
			Map<String, String> _hMap) throws Exception {

		System.out
				.println("getRawBodytoMap :: " + body.length() + " :: " + body);
		if (body.length() > 0) {
			String[] pairs = body.split("&");
			System.out.println("getRawBodytoMap.pairs :: " + pairs.length);
			for (String pair : pairs) {
				String[] keyValue = pair.split("=", 2);
				String key = URLDecoder.decode(keyValue[0], "UTF-8");
				String value = keyValue.length > 1
						? URLDecoder.decode(keyValue[1], "UTF-8")
						: "";
				_hMap.put(key, value);
				System.out.println(
						"getRawBodytoMap.key :: " + key + " :: " + value);
			}
		}

		return _hMap;
	}

	private Map<String, String> getRequestHeaderValuesMap(
			HttpServletRequest request) {

		Map<String, String> _hMap = new HashMap<String, String>();
		if (request.getHeaderNames() != null) {
			Enumeration enumeration = request.getHeaderNames();
			while (enumeration.hasMoreElements()) {
				String fieldName = (String) enumeration.nextElement();
				String fieldVal = request.getHeader(fieldName) == null ? ""
						: request.getHeader(fieldName);
				writeInLogFile(folderPath, fileNamePrefix,
						("getHeaderNames :: " + fieldName + " :: " + fieldVal));
				_hMap.put(fieldName, fieldVal);
			}
		}

		return _hMap;
	}

	private Map<String, String> getRequestParameterValuesMap(
			HttpServletRequest request) {

		Map<String, String> _hMap = new HashMap<String, String>();
		if (request.getParameterNames() != null) {
			Enumeration enumeration = request.getParameterNames();
			while (enumeration.hasMoreElements()) {
				String fieldName = (String) enumeration.nextElement();
				String data = "";
				if (request.getParameterValues(fieldName) != null) {
					String[] paraValArr = request.getParameterValues(fieldName);
					if (paraValArr != null) {
						for (int k = 0; k < paraValArr.length; k++) {
							if (paraValArr[k].trim().length() > 0) {
								if (data.length() == 0) {
									data = paraValArr[k].trim();
								} else {
									data += " @@ " + paraValArr[k].trim();
								}
							}
						}
					}
				}

				writeInLogFile(folderPath, fileNamePrefix,
						("getParameterNames :: " + fieldName + " :: " + data));
				_hMap.put(fieldName, data);
			}
		}

		return _hMap;
	}

	public synchronized void writeInLogFile(String folderName,
			String fileNamePrefix, String contents) {

		try {
			RandomAccessFile ralogfile = null;
			String logFileDate = new SimpleDateFormat("yyyy-MM-dd")
					.format(new Date());
			String contentDate = new SimpleDateFormat("MM/dd/yyyy hh:mm:ss a")
					.format(new Date());

			String logFileName = fileNamePrefix + logFileDate + ".log";
			StringBuffer logFilePath = new StringBuffer(folderName);
			File logFileFolder = new File(logFilePath.toString());
			if (!logFileFolder.isDirectory())
				logFileFolder.mkdirs();
			logFilePath.append(File.separator);
			logFilePath.append(logFileName);

			File logFile = new File(logFilePath.toString());
			if (!logFile.exists())
				logFile.createNewFile();
			ralogfile = new RandomAccessFile(logFile, "rwd");
			ralogfile.seek(ralogfile.length());
			if (contents.length() > 0)
				ralogfile.writeBytes(contentDate + " : " + contents);
			else
				ralogfile.writeBytes("");
			ralogfile.writeBytes(System.getProperty("line.separator"));
			ralogfile.close();
		} catch (Exception ex) {
			ex.printStackTrace();
		}
	}

}
