package com.tools;

import java.io.BufferedInputStream;
import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.DataInputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.io.RandomAccessFile;
import java.io.Writer;
import java.net.URLDecoder;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;

import org.apache.commons.codec.binary.Base64;

import com.beans.ApplicationConfig;

public class FileUtility {
	public static void main(String args[]) {
		/* sample Twilio webhook payload — use placeholders only (no real SIDs) */
		String data = "ToCountry=US&ToState=PA&SmsMessageSid=SMxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
				+ "&NumMedia=0&ToCity=&FromZip=00000&SmsSid=SMxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
				+ "&FromState=NJ&SmsStatus=received&FromCity=EXAMPLE&Body=Confirm&FromCountry=US"
				+ "&To=%2B10000000000&MessagingServiceSid=MGxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
				+ "&ToZip=&NumSegments=1&MessageSid=SMxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
				+ "&AccountSid=ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx&From=%2B10000000000"
				+ "&ApiVersion=2010-04-01";
		getRawBodytoMap(data);
	}

	public static Map<String, String> getRawBodytoMap(String body) {

		Map<String, String> _hMap = new HashMap<String, String>();
		String[] pairs = body.split("&");
		for (String pair : pairs) {
			String[] keyValue = pair.split("=", 2);
			String key = URLDecoder.decode(keyValue[0]);
			String value = keyValue.length > 1 ? URLDecoder.decode(keyValue[1])
					: "";
			_hMap.put(key, value);
			System.out.println("getRawBodytoMap :: " + key + " :: " + value);
		}

		return _hMap;
	}

	public String getFolderPath(String type, String docType, String loginUser) {

		SimpleDateFormat sdfYYYY_D_MM_D_DD = new SimpleDateFormat("yyyy-MM-dd");
		String dateVal = sdfYYYY_D_MM_D_DD.format(new Date());
		String dateArray[] = dateVal.split("-");
		String folderName = ApplicationConfig.getApplicationPath()
				+ File.separator + "docs" + File.separator + type
				+ File.separator + dateArray[0] + File.separator + dateArray[1]
				+ File.separator + dateArray[2] + File.separator + loginUser
				+ File.separator + docType;

		File folderObj = new File(folderName);
		if (!folderObj.isDirectory() || !folderObj.exists())
			folderObj.mkdirs();

		return folderName;
	}

	public String getFileSourcePath(String source, String type) {

		SimpleDateFormat sdfYYYY_D_MM_D_DD = new SimpleDateFormat("yyyy-MM-dd");
		String dateVal = sdfYYYY_D_MM_D_DD.format(new Date());
		String folderName = source + File.separator + type + File.separator
				+ dateVal;

		File folderObj = new File(folderName);
		if (!folderObj.isDirectory() || !folderObj.exists())
			folderObj.mkdirs();

		return folderName;
	}

	public synchronized String writeDataToFile(String folderName,
			String fileName, String contents) {

		if (contents.length() == 0)
			return "";

		File folderObj = new File(folderName);
		if (!folderObj.isDirectory() || !folderObj.exists())
			folderObj.mkdirs();

		String fileNameWithPath = folderName + File.separator + fileName;
		try {
			Writer output = null;
			output = new BufferedWriter(new FileWriter(fileNameWithPath));
			output.write(contents);
			output.close();

		} catch (IOException ex) {
			ex.printStackTrace();
		}

		return fileNameWithPath;
	}

	public synchronized String writeDataToLog(String folderName,
			String fileName, String contents) {

		try {
			File folderObj = new File(folderName);
			if (!folderObj.isDirectory() || !folderObj.exists())
				folderObj.mkdirs();

			RandomAccessFile ralogfile = null;
			String fileNameWithPath = folderName + File.separator + fileName;
			File logFile = new File(fileNameWithPath);
			if (!logFile.exists())
				logFile.createNewFile();

			ralogfile = new RandomAccessFile(logFile, "rwd");
			ralogfile.seek(ralogfile.length());
			ralogfile.writeBytes(contents);
			ralogfile.writeBytes(System.getProperty("line.separator"));
			ralogfile.close();
			return fileNameWithPath;
		} catch (Exception ex) {
			ex.printStackTrace();
		}

		return null;
	}

	public String convertFileToBase64Contents(String fileNameWithPath) {

		BufferedInputStream reader = null;
		try {
			File file = new File(fileNameWithPath);
			int length = (int) file.length();
			reader = new BufferedInputStream(new FileInputStream(file));
			byte[] bytes = new byte[length];
			reader.read(bytes, 0, length);
			reader.close();
			return new String(Base64.encodeBase64(bytes));
		} catch (Exception ex) {
			ex.printStackTrace();
			fileNameWithPath = "";
		} finally {
			try {
				if (reader != null)
					reader.close();
			} catch (Exception ex) {
				ex.printStackTrace();
			}
		}

		return "";
	}

	public String convertBase64ContentsToFile(String fileContents,
			String fileNameWithPath) {

		byte pdfBytes[] = Base64.decodeBase64(fileContents);
		OutputStream os = null;
		try {
			os = new FileOutputStream(fileNameWithPath);
			os.write(pdfBytes);
		} catch (Exception ex) {
			ex.printStackTrace();
			fileNameWithPath = "";
		} finally {
			try {
				if (os != null)
					os.close();
			} catch (Exception ex) {
				ex.printStackTrace();
				fileNameWithPath = "";
			}
		}

		return fileNameWithPath;
	}

	public String getStringFromFile(String fileNameWithPath) {

		StringBuffer buff = new StringBuffer();
		FileInputStream fstream = null;
		DataInputStream in = null;
		BufferedReader br = null;

		try {
			fstream = new FileInputStream(fileNameWithPath);
			in = new DataInputStream(fstream);
			br = new BufferedReader(new InputStreamReader(in));
			String strLine;
			while ((strLine = br.readLine()) != null) {
				buff.append(strLine);
				buff.append("\n");
			}
			br.close();
			in.close();
			fstream.close();

		} catch (Exception ex) {
			ex.printStackTrace();

		} finally {
			try {
				if (br != null)
					br.close();
				if (in != null)
					in.close();
				if (fstream != null)
					fstream.close();
			} catch (Exception ex) {
				ex.printStackTrace();
			}
		}

		return buff.toString();
	}

	public synchronized boolean copyFile(String sourceFile,
			String destinationFile) {

		System.out.println(
				"copyFile :: " + sourceFile + " :: " + destinationFile);
		InputStream in = null;
		OutputStream out = null;
		boolean isSuccess = false;
		try {
			File sourecObj = new File(sourceFile);
			File destinationObj = new File(destinationFile);

			File parentDir = destinationObj.getParentFile();
			System.out.println("destinationObj.getParentFile().exists() :: "
					+ parentDir.exists());

			if (!parentDir.exists())
				parentDir.mkdirs();

			System.out.println("Can write to destinationObj ? "
					+ destinationObj.canWrite());
			if (!destinationObj.exists())
				destinationObj.createNewFile();

			in = new FileInputStream(sourecObj);

			// For Append the file.
			// OutputStream out = new FileOutputStream(f2,true);

			// For Overwrite the file.
			out = new FileOutputStream(destinationObj);

			byte[] buf = new byte[1024];
			int len;
			while ((len = in.read(buf)) > 0)
				out.write(buf, 0, len);

			isSuccess = true;

		} catch (FileNotFoundException fnfEx) {
			isSuccess = false;
			System.err.println("Problem in copyFile " + fnfEx.getMessage());

		} catch (IOException ioEx) {
			isSuccess = false;
			System.err.println("Problem in copyFile " + ioEx.getMessage());

		} catch (Exception ex) {
			isSuccess = false;
			System.err.println("Problem in copyFile " + ex.getMessage());

		} finally {
			try {
				if (in != null)
					in.close();
				if (out != null)
					out.close();
			} catch (Exception ex) {
				ex.printStackTrace();
			}
		}

		System.out.println("copyFile :: " + isSuccess);
		return isSuccess;
	}

}
