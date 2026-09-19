package com.tools;

import java.awt.Color;
import java.io.BufferedReader;
import java.io.DataInputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.InputStreamReader;
import java.text.DateFormat;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Date;
import java.util.List;

import org.apache.poi.hssf.usermodel.HSSFWorkbook;
import org.apache.poi.openxml4j.util.ZipSecureFile;
import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.CellStyle;
import org.apache.poi.ss.usermodel.DateUtil;
import org.apache.poi.ss.usermodel.FillPatternType;
import org.apache.poi.ss.usermodel.Font;
import org.apache.poi.ss.usermodel.HorizontalAlignment;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.ss.usermodel.WorkbookFactory;
import org.apache.poi.xssf.usermodel.XSSFColor;

import com.dataobjects.MVPGDB;
import com.util.RecordStatus;
import com.beans.SearchBean;

public class ExcelFile {

	MVPGDB db = new MVPGDB();
	DateFormat poiCell = new SimpleDateFormat("E MMM dd HH:mm:ss Z yyyy");
	DateFormat dateFormat = new SimpleDateFormat("MM/dd/yyyy");

	private Object[] createTable(String tableName, Row headerRow, Row dataRow) {

		boolean result = false;
		List<String> columnsList = new ArrayList<String>();

		try {
			String checkTableName = db.checkTableExistQry(tableName);
			if (checkTableName.length() > 0)
				db.create("DROP TABLE " + tableName);

			String insQry = "CREATE TABLE " + tableName + " (" + tableName
					+ "ID INT(8) NOT NULL AUTO_INCREMENT, ENTITYID INT(8) NOT NULL, ";
			for (int j = 0; j < headerRow.getPhysicalNumberOfCells(); j++) {
				String colLabel = getCellValue(headerRow, j, "");
				colLabel = getTableColumnName(colLabel);

				String colDataType = getCellDataType(dataRow, j);

				columnsList.add(colLabel + " @@ " + colDataType);

				insQry += colLabel + colDataType + ", ";
			}

			insQry += " CREATE_USER VARCHAR(50), CREATE_DATE DATETIME, "
					+ "STATUS INT(3) DEFAULT '0', CONSTRAINT " + tableName
					+ "_PK PRIMARY KEY (" + tableName
					+ "ID)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4";

			result = db.create(insQry);
		} catch (Exception ex) {
			ex.printStackTrace();
		}

		return new Object[] { result, columnsList };
	}

	public Object[] createTableFromCsv(String tableName, String loginUser,
			String entityID, String fileNameWithPath, String DATA_SEPERATOR)
			throws Exception {

		DATA_SEPERATOR = DATA_SEPERATOR.length() == 0 ? "\"," : DATA_SEPERATOR;
		tableName = getTableName(tableName);

		System.out.println("createTableFromCsv :: " + tableName + " :: "
				+ DATA_SEPERATOR + " :: " + loginUser + " :: " + entityID
				+ " :: " + fileNameWithPath);

		double numOfRows = 0;
		double numOfRowsInserted = 0;
		boolean isHeader = true;
		boolean result = false;

		FileInputStream fstream = null;
		DataInputStream in = null;
		BufferedReader br = null;
		List<String> columnsList = new ArrayList<String>();

		try {
			fstream = new FileInputStream(fileNameWithPath);
			in = new DataInputStream(fstream);
			br = new BufferedReader(new InputStreamReader(in));
			String strLine;
			while ((strLine = br.readLine()) != null) {
				if (strLine.length() > 0) {
					String splitDataArray[] = strLine.split(DATA_SEPERATOR);
					if (isHeader) {
						String checkTableName = db
								.checkTableExistQry(tableName);
						if (checkTableName.length() > 0)
							db.create("DROP TABLE " + tableName);

						try {
							String insQry = "CREATE TABLE " + tableName + " ("
									+ tableName
									+ "ID INT(8) NOT NULL AUTO_INCREMENT, "
									+ "ENTITYID INT(8) NOT NULL, ";
							for (int j = 0; j < splitDataArray.length; j++) {
								String colLabel = splitDataArray[j].trim();

								colLabel = getTableColumnName(colLabel);

								String colDataType = db.getDataType("");

								columnsList
										.add(colLabel + " @@ " + colDataType);

								insQry += colLabel + colDataType + ", ";
							}

							insQry += " CREATE_USER VARCHAR(50), CREATE_DATE DATETIME, "
									+ "STATUS INT(3) DEFAULT '0', CONSTRAINT "
									+ tableName + "_PK PRIMARY KEY ("
									+ tableName
									+ "ID)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4";
							result = db.create(insQry);
						} catch (Exception ex) {
							ex.printStackTrace();
							result = false;
						}

						if (result)
							isHeader = false;
						else
							break;

					} else {
						numOfRows++;
						try {
							String autoIncrementArray[] = db
									.getAutoIncrementArray(tableName + "ID");
							String insQry = "INSERT INTO " + tableName + "(";
							if (autoIncrementArray != null)
								insQry += autoIncrementArray[0];
							insQry += "ENTITYID, ";
							for (int j = 0; j < columnsList.size(); j++) {
								String tempData = columnsList.get(j);

								String splitArray[] = tempData.split("@@");
								insQry += splitArray[0].trim() + ", ";
							}
							insQry += "CREATE_USER, CREATE_DATE, STATUS) VALUES (";
							if (autoIncrementArray != null)
								insQry += autoIncrementArray[1];
							insQry += entityID + ", ";
							for (int j = 0; j < splitDataArray.length; j++) {
								String colData = splitDataArray[j].trim();
								if (colData.startsWith("\""))
									colData = colData.substring(1);
								if (colData.endsWith("\""))
									colData = colData.substring(0,
											colData.length() - 1);

								String tempData = columnsList.get(j);
								String splitArray[] = tempData.split("@@");
								if (splitArray[1].contains("DATETIME")
										|| splitArray[1].contains("DATE")) {
									insQry += db.getInsertDate(colData) + ", ";
								} else {
									insQry += db.getInsertDBValue(
											colData.replaceAll("'", "''"))
											+ ", ";
								}
							}

							insQry += db.getInsertDBValue(loginUser) + ", "
									+ db.getInsertSysdate() + ", "
									+ db.getInsertDBValue(RecordStatus.ACTIVE)
									+ ")";

							result = db.update(insQry);
						} catch (Exception ex) {
							ex.printStackTrace();
							result = false;
						}

						if (result)
							numOfRowsInserted++;
					}
				}
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

		return new Object[] { numOfRows, numOfRowsInserted };
	}

	public Object[] createTableFromExcel(String tableName, String loginUser,
			String entityID, String fileNameWithPath) {

		tableName = getTableName(tableName);

		double numOfRows = 0;
		double numOfRowsInserted = 0;
		int labelStartIndex = 0;
		int dataTypeStartIndex = 1;
		List<String> columnsList = new ArrayList<String>();
		if ("WEEK_51_SCHEDULE".equalsIgnoreCase(tableName)) {
			labelStartIndex = 3;
			dataTypeStartIndex = labelStartIndex + 2;
		}

		Workbook workbook = null;
		Sheet sheet = null;
		System.out.println("createTableFromExcel :: " + tableName + " :: "
				+ loginUser + " :: " + entityID + " :: " + fileNameWithPath);
		try {
			if (fileNameWithPath.endsWith(".xls")) {
				workbook = new HSSFWorkbook(
						new FileInputStream(new File(fileNameWithPath)));
			} else {
				workbook = WorkbookFactory.create(new File(fileNameWithPath));
			}

			sheet = workbook.getSheetAt(0);
			for (int i = labelStartIndex; i <= sheet.getLastRowNum(); i++) {
				Row posRow = sheet.getRow(i);
				boolean result = false;
				if (i == labelStartIndex) {
					Object returnArray[] = createTable(tableName, posRow,
							sheet.getRow(dataTypeStartIndex));
					result = (Boolean) returnArray[0];
					if (result) {
						columnsList = (ArrayList<String>) returnArray[1];
					} else {
						break;
					}

				} else {
					numOfRows++;
					result = createTableRow(tableName, columnsList, loginUser,
							entityID, posRow);
					if (result)
						numOfRowsInserted++;
				}
			}

		} catch (Exception ex) {
			ex.printStackTrace();
		}

		workbook = null;
		sheet = null;

		return new Object[] { numOfRows, numOfRowsInserted };
	}

	private boolean createTableRow(String tableName, List<String> columnsList,
			String loginUser, String entityID, Row dataRow) {

		boolean result = false;
		try {
			String autoIncrementArray[] = db
					.getAutoIncrementArray(tableName + "ID");

			String insQry = "INSERT INTO " + tableName + "(";
			if (autoIncrementArray != null)
				insQry += autoIncrementArray[0];
			insQry += "ENTITYID, ";
			for (int j = 0; j < columnsList.size(); j++) {
				String tempData = columnsList.get(j);
				String splitArray[] = tempData.split("@@");
				insQry += splitArray[0].trim() + ", ";
			}
			insQry += "CREATE_USER, CREATE_DATE, STATUS) VALUES (";

			if (autoIncrementArray != null)
				insQry += autoIncrementArray[1];
			insQry += entityID + ", ";
			for (int j = 0; j < columnsList.size(); j++) {
				String colData = getCellValue(dataRow, j, "");
				String tempData = columnsList.get(j);
				String splitArray[] = tempData.split("@@");
				if (splitArray[1].contains("DATETIME")
						|| splitArray[1].contains("DATE")) {
					insQry += db.getInsertDate(colData) + ", ";
				} else {
					insQry += db.getInsertDBValue(colData.replaceAll("'", "''"))
							+ ", ";
				}
			}

			insQry += db.getInsertDBValue(loginUser) + ", "
					+ db.getInsertSysdate() + ", "
					+ db.getInsertDBValue(RecordStatus.ACTIVE) + ")";

			result = db.update(insQry);
		} catch (Exception ex) {
			ex.printStackTrace();
		}

		return result;
	}

	private String getCellDataType(Row posRow, int index) throws Exception {

		try {
			Cell posCell = posRow.getCell((short) index);
			if (posCell != null) {
				switch (posCell.getCellType()) {
				case STRING:
					return db.getDataType("");

				case NUMERIC:
					return db.getDataType("INT");

				case BOOLEAN:
					return db.getDataType("");

				case FORMULA:
					return db.getDataType("");

				default:
					if (DateUtil.isCellDateFormatted(posCell)) {
						return db.getDataType("DATE");
					} else {
						return db.getDataType("");
					}
				}
			}
		} catch (Exception ex) {
			ex.printStackTrace();
		}

		return db.getDataType("");
	}

	private String getCellValue(Row posRow, int index, String type)
			throws Exception {

		String cellVal = "";
		try {
			Cell posCell = posRow.getCell((short) index,
					Row.MissingCellPolicy.RETURN_BLANK_AS_NULL);
			if (posCell != null) {
				switch (posCell.getCellType()) {
				case STRING:
					cellVal = "" + posCell.getStringCellValue();
					break;

				case NUMERIC:
					int cellValueInt = (int) (posCell.getNumericCellValue());
					cellVal = cellValueInt + "";
					if ("EOC".equalsIgnoreCase(type))
						cellVal = posCell.toString();
					break;

				case BOOLEAN:
					cellVal = posCell.getBooleanCellValue() + "";
					break;

				case FORMULA:
					cellVal = posCell.getCellFormula() + "";
					break;

				default:
					if (DateUtil.isCellDateFormatted(posCell)) {
						cellVal = posCell.getDateCellValue() + "";
						cellVal = getDateInMMDDYYYY(cellVal);
					} else {
						cellVal = "" + posCell.getStringCellValue();
					}
					break;
				}
			}
		} catch (Exception ex) {
			ex.printStackTrace();
		}

		return cellVal;
	}

	public String getDateInMMDDYYYY(String dateStr) throws Exception {
		String returnVal = "";
		try {
			if (dateStr.length() > 0) {
				Date dateVal = (Date) poiCell.parse(dateStr);
				Calendar cal = Calendar.getInstance();
				cal.setTime(dateVal);

				String formatedDate = (cal.get(Calendar.MONTH) + 1) + "/"
						+ cal.get(Calendar.DATE) + "/" + cal.get(Calendar.YEAR);
				dateVal = dateFormat.parse(formatedDate);
				returnVal = dateFormat.format(dateVal);
			}
		} catch (ParseException e) {
			e.printStackTrace();
		}

		return returnVal;
	}

	public String getTableColumnName(String colLabel) {

		colLabel = colLabel.replaceAll(" ", "_");
		colLabel = colLabel.replaceAll(",", "");
		colLabel = colLabel.replace("(", "");
		colLabel = colLabel.replace(")", "");
		colLabel = colLabel.replace("/", "_");
		colLabel = colLabel.toUpperCase().trim();

		if (colLabel.startsWith("\""))
			colLabel = colLabel.substring(1);
		if (colLabel.endsWith("\""))
			colLabel = colLabel.substring(0, colLabel.length() - 1);

		if ("DATE".equalsIgnoreCase(colLabel))
			colLabel = "SERVICE_DATE";

		return colLabel;
	}

	public String getTableName(String tableName) {

		tableName = tableName.replaceAll(" ", "_");
		tableName = tableName.replaceAll("-", "_");
		tableName = tableName.replaceAll(",", "_");
		tableName = tableName.replace("(", "");
		tableName = tableName.replace(")", "");
		tableName = tableName.replace("/", "_");
		tableName = tableName.toUpperCase();

		return tableName;
	}

	public Object[] readDataFromFile(String fileNameWithPath,
			String DATA_SEPERATOR, int columnStartIndex, int dataStartIndex,
			String type) throws Exception {

		// Extension match must be case-insensitive: browsers keep whatever the
		// portal sends (e.g. "Week-27-Schedule.Xlsx"), which used to fall
		// through both branches and return null (blank page, nothing loaded).
		String fileNameLower = fileNameWithPath == null ? ""
				: fileNameWithPath.toLowerCase();
		if (fileNameLower.length() == 0) {
			throw new Exception("No file was uploaded");
		}
		if (fileNameLower.endsWith(".csv")) {
			return readDataFromCsv(fileNameWithPath, DATA_SEPERATOR);

		} else if (fileNameLower.endsWith(".xls")
				|| fileNameLower.endsWith(".xlsx")) {
			return readDataFromXls(fileNameWithPath, columnStartIndex,
					dataStartIndex, type);
		}

		return null;
	}

	public Object[] readDataFromXls(String fileNameWithPath, int rowStartIndex,
			int dataStartIndex, int dataEndIndex) throws Exception {

		System.out.println(
				"readDataFromXls :: " + rowStartIndex + " :: " + dataStartIndex
						+ " :: " + dataEndIndex + " :: " + fileNameWithPath);
		List<String> columnsList = new ArrayList<String>();
		List dataList = new ArrayList();
		Workbook workbook = null;
		Sheet sheet = null;

		try {
			// Lower the ratio threshold before reading the file
			ZipSecureFile.setMinInflateRatio(0.0001);
			if (fileNameWithPath.endsWith(".xls")) {
				workbook = new HSSFWorkbook(
						new FileInputStream(new File(fileNameWithPath)));
			} else {
				workbook = WorkbookFactory.create(new File(fileNameWithPath));
			}

			sheet = workbook.getSheetAt(0);
			for (int i = rowStartIndex; i <= dataEndIndex; i++) {
				Row posRow = sheet.getRow(i);
				if (posRow != null) {
					if (i == rowStartIndex) {
						for (int j = 0; j < posRow
								.getPhysicalNumberOfCells(); j++)
							columnsList.add(getCellValue(posRow, j, ""));

					} else if (i >= dataStartIndex) {
						List<String> rowList = new ArrayList<String>();
						for (int j = 0; j < columnsList.size(); j++) {
							String dataVal = getCellValue(posRow, j, "");
							rowList.add(dataVal);
						}

						boolean isDataPresent = false;
						for (int j = 0; j < rowList.size(); j++) {
							if (rowList.get(j).toString().trim().length() > 0) {
								isDataPresent = true;
								break;
							}
						}

						if (isDataPresent && rowList.size() > 0)
							dataList.add(rowList);
					}
				}
			}

		} catch (Exception ex) {
			ex.printStackTrace();
		}

		workbook = null;
		sheet = null;
		System.out.println("readDataFromXls.columnsList :: "
				+ columnsList.size() + " :: " + columnsList);
		System.out.println("readDataFromXls.dataList :: " + dataList.size()
				+ " :: " + dataList);
		return new Object[] { dataList, columnsList };
	}

	private Object[] readDataFromXls(String fileNameWithPath, int rowStartIndex,
			int dataStartIndex, String type) throws Exception {

		System.out.println("readDataFromXls :: " + rowStartIndex + " :: "
				+ dataStartIndex + " :: " + fileNameWithPath);
		List<String> columnsList = new ArrayList<String>();
		List dataList = new ArrayList();
		Workbook workbook = null;
		Sheet sheet = null;

		try {
			// Lower the ratio threshold before reading the file
			ZipSecureFile.setMinInflateRatio(0.0001);
			if (fileNameWithPath.endsWith(".xls")) {
				workbook = new HSSFWorkbook(
						new FileInputStream(new File(fileNameWithPath)));
			} else {
				workbook = WorkbookFactory.create(new File(fileNameWithPath));
			}

			sheet = workbook.getSheetAt(0);
			for (int i = rowStartIndex; i <= sheet.getLastRowNum(); i++) {
				Row posRow = sheet.getRow(i);
				if (posRow != null) {
					if (i == rowStartIndex) {
						for (int j = 0; j < posRow
								.getPhysicalNumberOfCells(); j++)
							columnsList.add(getCellValue(posRow, j, type));

					} else if (i >= dataStartIndex) {
						List<String> rowList = new ArrayList<String>();
						for (int j = 0; j < columnsList.size(); j++) {
							String dataVal = getCellValue(posRow, j, type);
							rowList.add(dataVal);
						}

						boolean isDataPresent = false;
						for (int j = 0; j < rowList.size(); j++) {
							if (rowList.get(j).toString().trim().length() > 0) {
								isDataPresent = true;
								break;
							}
						}

						if (isDataPresent && rowList.size() > 0)
							dataList.add(rowList);
					}
				}
			}

		} catch (Exception ex) {
			ex.printStackTrace();
		}

		workbook = null;
		sheet = null;

		System.out.println("readDataFromXls.columnsList :: "
				+ columnsList.size() + " :: " + columnsList);
		System.out.println("readDataFromXls.dataList :: " + dataList.size());
		return new Object[] { dataList, columnsList };
	}

	private Object[] readDataFromCsv(String fileNameWithPath,
			String DATA_SEPERATOR) {

		DATA_SEPERATOR = DATA_SEPERATOR.length() == 0 ? "\"," : DATA_SEPERATOR;
		System.out.println("readDataFromCsv :: " + DATA_SEPERATOR + " :: "
				+ " :: " + fileNameWithPath);

		List<String> columnsList = new ArrayList<String>();
		List dataList = new ArrayList();
		boolean isHeader = true;

		FileInputStream fstream = null;
		DataInputStream in = null;
		BufferedReader br = null;

		try {
			fstream = new FileInputStream(fileNameWithPath);
			in = new DataInputStream(fstream);
			br = new BufferedReader(new InputStreamReader(in));
			String strLine;
			while ((strLine = br.readLine()) != null) {
				if (strLine.length() > 0) {
					String splitDataArray[] = strLine.split(DATA_SEPERATOR);
					if (isHeader) {
						for (int j = 0; j < splitDataArray.length; j++) {
							String colData = splitDataArray[j].trim();
							if (colData.startsWith("\""))
								colData = colData.substring(1);
							if (colData.endsWith("\""))
								colData = colData.substring(0,
										colData.length() - 1);

							columnsList.add(colData);
						}
						isHeader = false;

					} else {
						List tempList = new ArrayList();
						boolean isAppendData = false;
						String tempData = "";
						for (int j = 0; j < splitDataArray.length; j++) {
							String colData = splitDataArray[j].trim();
							if (colData.startsWith("\"")
									&& colData.endsWith("\"")) {
								if (colData.startsWith("\""))
									colData = colData.substring(1);
								if (colData.endsWith("\""))
									colData = colData.substring(0,
											colData.length() - 1);
								tempList.add(colData);

							} else if (colData.startsWith("\"")
									&& DATA_SEPERATOR.equalsIgnoreCase(",")
									|| isAppendData) {

								if (colData.endsWith("\"")) {
									isAppendData = false;
									tempData += splitDataArray[j];
									tempData = tempData.trim();
									if (tempData.startsWith("\""))
										tempData = tempData.substring(1);
									if (tempData.endsWith("\""))
										tempData = tempData.substring(0,
												tempData.length() - 1);
									tempList.add(tempData);
								} else {
									tempData += splitDataArray[j] + ",";
									isAppendData = true;
								}

							} else {
								if (colData.startsWith("\""))
									colData = colData.substring(1);
								if (colData.endsWith("\""))
									colData = colData.substring(0,
											colData.length() - 1);
								tempList.add(colData);
							}
						}
						if (tempList.size() > 0)
							dataList.add(tempList);
					}
				}
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

		return new Object[] { dataList, columnsList };
	}

	public CellStyle getCellStyle(Workbook workbook, boolean isBold,
			String bgColor) {
		CellStyle style = workbook.createCellStyle();
		Font font = workbook.createFont();
		font.setFontName("Arial");
		font.setBold(isBold);
		style.setFont(font);
		style.setAlignment(HorizontalAlignment.LEFT);

		if ("bg-warning".equalsIgnoreCase(bgColor)) {
			style.setFillPattern(FillPatternType.SOLID_FOREGROUND);
			// Set background color (example: yellow)
			XSSFColor color = new XSSFColor(new Color(255, 193, 7), null); // #ffc107
			style.setFillForegroundColor(color);
		}

		return style;
	}

	public static String stripHtml(String val) {
		if (val == null || val.indexOf('<') < 0 && val.indexOf('&') < 0)
			return val == null ? "" : val;
		return val.replaceAll("(?i)<br\\s*/?>", " ")
				.replaceAll("<[^>]+>", "")
				.replaceAll("&nbsp;", " ")
				.replaceAll("&amp;", "&")
				.replaceAll("\\s+", " ").trim();
	}

	public String writeDataToXls(SearchBean searchBean,
			String fileNameWithPath) {

		String reportName = searchBean.getDisplayName();
		List<String> labelsList = searchBean.getLabelsList();
		List dataList = searchBean.getDataList();
		List footerList = searchBean.getFooterList();

		try {
			Workbook workbook = WorkbookFactory.create(true);
			Sheet sheet = workbook.createSheet(reportName);
			int rownum = 0;
			CellStyle labelStyle = getCellStyle(workbook, true, "");
			CellStyle dataStyle = getCellStyle(workbook, false, "");
			CellStyle warningStyle = getCellStyle(workbook, false,
					"bg-warning");

			Row row = sheet.createRow(rownum++);
			for (int i = 0; i < labelsList.size(); i++) {
				Cell cell = row.createCell(i);
				cell.setCellValue((String) labelsList.get(i));
				cell.setCellStyle(labelStyle);
			}

			for (int i = 0; i < dataList.size(); i++) {
				List tempList = (ArrayList) dataList.get(i);
				row = sheet.createRow(rownum++);
				String rowColor = searchBean.getRequestMap()
						.get("highlightRowColor_" + i) == null
								? ""
								: searchBean.getRequestMap()
										.get("highlightRowColor_" + i)
										.toString().trim();
				for (int j = 0; j < labelsList.size(); j++) {
					Cell cell = row.createCell(j);
					// data rows carry the record ID at index 0 (labels don't) —
					// start at index 1 like the PDF report does
					Object colVal = (j + 1) < tempList.size()
							? tempList.get(j + 1)
							: null;
					cell.setCellValue(
							colVal == null ? "" : stripHtml(colVal.toString()));
					if (searchBean.getBoldColumns() != null) {
						CellStyle dataStyle1 = dataStyle;
						for (int k = 0; k < searchBean
								.getBoldColumns().length; k++) {
							if (searchBean.getBoldColumns()[k] == j) {
								dataStyle1 = labelStyle;
								break;
							}
						}
						cell.setCellStyle(dataStyle1);
					} else {
						if (rowColor.length() > 0) {
							cell.setCellStyle(warningStyle);
						} else {
							cell.setCellStyle(dataStyle);
						}
					}
				}
			}

			for (int i = 0; i < footerList.size(); i++) {
				List tempList = (ArrayList) footerList.get(i);
				row = sheet.createRow(rownum++);
				for (int j = 0; j < tempList.size(); j++) {
					Cell cell = row.createCell(j);
					cell.setCellValue((String) tempList.get(j));
					cell.setCellStyle(labelStyle);
				}
			}

			FileOutputStream out = new FileOutputStream(
					new File(fileNameWithPath));
			workbook.write(out);
			out.close();
		} catch (Exception ex) {
			ex.printStackTrace();
			fileNameWithPath = "";
		}

		return fileNameWithPath;
	}
}
