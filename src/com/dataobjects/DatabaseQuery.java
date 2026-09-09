package com.dataobjects;

import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.Map;

import com.util.MainUtil;
import com.util.RecordStatus;

public class DatabaseQuery {

	public static final int DB_ORACLE = 0;
	public static final int DB_MYSQL = 1;

	public static String RANGE = "Range";
	public static String GREATER_THAN = "Greater Than";
	public static String GREATER_THAN_EQUALS = "Greater Than Equals";
	public static String LESS_THAN = "Less Than";
	public static String LESS_THAN_EQUALS = "Less Than Equals";
	public static String EQUALS_TO = "Equals To";
	public static String NOT_EQUALS_TO = "Not Equals To";

	public static String LESS_THAN_OPERATOR = "<";
	public static String LESS_THAN_EQUALS_OPERATOR = "<=";
	public static String GREATER_THAN_OPERATOR = ">";
	public static String GREATER_THAN_EQUALS_OPERATOR = ">=";
	public static String EQUALS_TO_OPERATOR = "=";

	public static String OPERATOR_AND = "AND";
	public static String OPERATOR_OR = "OR";

	public static String FUN_MAX = "MAX";
	public static String FUN_MIN = "MIN";

	public static String JOIN = " JOIN ";
	public static String LEFT_JOIN = " LEFT JOIN ";
	public static String RIGHT_JOIN = " RIGHT JOIN ";

	/*- Adds the integer expression interval to the date or datetime expression
	 datetime_expr. The unit for interval is given by the unit argument, which
	 should be one of the following values: MICROSECOND (microseconds),
	 SECOND, MINUTE, HOUR, DAY, WEEK, MONTH, QUARTER, or YEAR.
	*/
	public static final String MYSQL_MICROSECOND = "MICROSECOND";
	public static final String MYSQL_SECOND = "SECOND";
	public static final String MYSQL_MINUTE = "MINUTE";
	public static final String MYSQL_HOUR = "HOUR";
	public static final String MYSQL_DAY = "DAY";
	public static final String MYSQL_WEEK = "WEEK";
	public static final String MYSQL_MONTH = "MONTH";
	public static final String MYSQL_QUARTER = "QUARTER";
	public static final String MYSQL_YEAR = "YEAR";

	public static final String ORACLE_MONTH = "MONTH";
	public static final String ORACLE_DAY = "DAY";

	public static final String ORACLE_MMSDDSYYYYSHHSMISAM = "MM/DD/YYYY HH:MI AM";
	public static final String ORACLE_MMSDDSYYYYSHH24SMI = "MM/DD/YYYY HH24:MI";
	public static final String ORACLE_MMSDDSYYYYSHH24CMICSS = "MM/DD/YYYY HH24:MI:SS";
	public static final String ORACLE_YYYYDMMDDD24HRDMIDSS = "YYYY-MM-DD HH24:MI:SS";
	public static final String ORACLE_YYYYMMDDHH24MISS = "YYYYMMDDHH24MISS";

	public static final String ORACLE_MMSDDSYYYY = "MM/DD/YYYY";
	public static final String ORACLE_YYYYSMMSDD = "YYYY/MM/DD";

	public static final String ORACLE_HHSMISAM = "HH:MI AM";
	public static final String ORACLE_HH24SMI = "HH24:MI";

	private static final String MYSQL_MMSDDSYYYYSHHSMISAM = "%m/%d/%Y %h:%i %p";
	private static final String MYSQL_MMSDDSYYYYSHH24SMI = "%m/%d/%Y %H:%i";
	private static final String MYSQL_MMSDDSYYYYSHH24CMICSS = "%m/%d/%Y %H:%i:%S";
	private static final String MYSQL_YYYYDMMDDD24HRDMIDSS = "%Y-%m-%d %H:%i:%S";
	private static final String MYSQL_YYYYMMDDHH24MISS = "%Y%m%d%H%i%S";

	private static final String MYSQL_MMSDDSYYYY = "%m/%d/%Y";
	private static final String MYSQL_YYYYSMMSDD = "%Y/%m/%d";

	private static final String MYSQL_HHSMISAM = "%h:%i %p";
	private static final String MYSQL_HH24SMI = "%H:%i";

	public String getDBDateFormat(String format, int dbType) {

		switch (dbType) {
		case DB_MYSQL:
			switch (format) {
			case ORACLE_YYYYMMDDHH24MISS:
				format = MYSQL_YYYYMMDDHH24MISS;
				break;

			case ORACLE_YYYYDMMDDD24HRDMIDSS:
				format = MYSQL_YYYYDMMDDD24HRDMIDSS;
				break;

			case ORACLE_MONTH:
				format = MYSQL_MONTH;
				break;

			case ORACLE_MMSDDSYYYYSHH24SMI:
				format = MYSQL_MMSDDSYYYYSHH24SMI;
				break;

			case ORACLE_MMSDDSYYYYSHHSMISAM:
				format = MYSQL_MMSDDSYYYYSHHSMISAM;
				break;

			case ORACLE_MMSDDSYYYY:
				format = MYSQL_MMSDDSYYYY;
				break;

			case ORACLE_YYYYSMMSDD:
				format = MYSQL_YYYYSMMSDD;
				break;

			case ORACLE_HH24SMI:
				format = MYSQL_HH24SMI;
				break;

			case ORACLE_HHSMISAM:
				format = MYSQL_HHSMISAM;
				break;

			case ORACLE_MMSDDSYYYYSHH24CMICSS:
				format = MYSQL_MMSDDSYYYYSHH24CMICSS;
				break;

			}
		}

		return format;
	}

	public String getInsertSysdate(int dbType) {

		switch (dbType) {
		case DB_MYSQL:
			return "SYSDATE()";

		default:
			return "SYSDATE";
		}
	}

	public String getInsertDate(String insDate, int dbType) {

		insDate = insDate == null ? "" : insDate.trim();
		String format = getDBDateFormat(ORACLE_MMSDDSYYYY, dbType);
		switch (dbType) {
		case DB_MYSQL:
			if (insDate.length() == 0)
				return "STR_TO_DATE(null, '" + format + "')";
			else
				return "STR_TO_DATE('" + insDate + "', '" + format + "')";

		default:
			return "TO_DATE('" + insDate + "', '" + format + "')";
		}
	}

	public String getInsertDateTime(String insDate, int dbType) {

		insDate = insDate == null ? "" : insDate.trim();
		String format = getDBDateFormat(ORACLE_MMSDDSYYYYSHHSMISAM, dbType);
		switch (dbType) {
		case DB_MYSQL:
			if (insDate.length() == 0)
				return "STR_TO_DATE(null, '" + format + "')";
			else
				return "STR_TO_DATE('" + insDate + "', '" + format + "')";

		default:
			return "TO_DATE('" + insDate + "', '" + format + "')";
		}
	}

	public String getInsertDateFormat(String insDate, String format,
			int dbType) {

		insDate = insDate == null ? "" : insDate.trim();
		format = getDBDateFormat(format, dbType);
		switch (dbType) {
		case DB_MYSQL:
			if (insDate.length() == 0)
				return "STR_TO_DATE(null, '" + format + "')";
			else
				return "STR_TO_DATE('" + insDate + "', '" + format + "')";

		default:
			return "TO_DATE('" + insDate + "', '" + format + "')";
		}
	}

	public String getInsertDBValue(Object input, int dbType) {

		String value = input == null ? "" : input.toString().trim();
		switch (dbType) {
		case DB_MYSQL:
			value = value.length() == 0 ? null : value;
			if (value == null)
				return null;
			else
				return "'" + value + "'";

		default:
			return "'" + value + "'";
		}
	}

	public String getInsertAppendDBValue(String columnName, Object input,
			int dbType) {

		String value = input == null ? "" : input.toString().trim();
		switch (dbType) {
		case DB_MYSQL:
			value = "CONCAT(" + columnName + ", ' " + input + "')";
			return value;

		default:
			return columnName + " || ' " + input + "'";
		}
	}

	private String getNullValue(int dbType) {

		switch (dbType) {
		case DB_MYSQL:
			return "IFNULL";

		default:
			return "NVL";
		}
	}

	public String getConcat(String[] columnsArray, int dbType) {

		StringBuffer returnBuff = new StringBuffer();
		switch (dbType) {
		case DB_MYSQL:
			returnBuff.append("CONCAT(");
			for (int i = 0; i < columnsArray.length; i++) {
				if (isSpecialCharInConcat(columnsArray[i])) {
					returnBuff.append("'").append(columnsArray[i]).append("'");
				} else {
					returnBuff.append(getNullValue(dbType)).append("(");
					returnBuff.append(columnsArray[i]).append(", '')");
				}
				if (i != (columnsArray.length - 1))
					returnBuff.append(",");
			}
			returnBuff.append(")");
			return returnBuff.toString();

		default:
			returnBuff.append("(");
			for (int i = 0; i < columnsArray.length; i++) {
				if (isSpecialCharInConcat(columnsArray[i])) {
					returnBuff.append("'").append(columnsArray[i]).append("'");
				} else {
					returnBuff.append(columnsArray[i]);
				}
				if (i != (columnsArray.length - 1))
					returnBuff.append("||");
			}
			returnBuff.append(")");
			return returnBuff.toString();
		}
	}

	private boolean isSpecialCharInConcat(String value) {

		switch (value) {
		case " ":
			return true;

		case "##":
			return true;
		}
		return false;
	}

	public String getSelectDateTime(String colName, int dbType) {

		String format = getDBDateFormat(ORACLE_MMSDDSYYYYSHHSMISAM, dbType);
		switch (dbType) {
		case DB_MYSQL:
			return "DATE_FORMAT(" + colName + ", '" + format + "') ";

		default:
			return "TO_CHAR(" + colName + ", '" + format + "') ";
		}
	}

	public String getSelectDate(String colName, int dbType) {

		String format = getDBDateFormat(ORACLE_MMSDDSYYYY, dbType);
		switch (dbType) {
		case DB_MYSQL:
			return "DATE_FORMAT(" + colName + ", '" + format + "') ";

		default:
			return "TO_CHAR(" + colName + ", '" + format + "') ";
		}
	}

	public String getSelectTime(String colName, int dbType) {

		String format = getDBDateFormat(ORACLE_HHSMISAM, dbType);
		switch (dbType) {
		case DB_MYSQL:
			return "DATE_FORMAT(" + colName + ", '" + format + "') ";

		default:
			return "TO_CHAR(" + colName + ", '" + format + "') ";
		}
	}

	public String getSelectTimeWithTypeInterval(String type, int numOfMins,
			String colName, int dbType) {

		String format = getDBDateFormat(ORACLE_HHSMISAM, dbType);
		switch (dbType) {
		case DB_MYSQL:
			if ("-".equalsIgnoreCase(type)) {
				return "DATE_FORMAT(DATE_SUB(" + colName + ", INTERVAL "
						+ numOfMins + " MINUTE), '" + format + "')  ";
			} else {
				return "DATE_FORMAT(DATE_ADD(" + colName + ", INTERVAL "
						+ numOfMins + " MINUTE), '" + format + "')  ";
			}

		default:
			if ("-".equalsIgnoreCase(type)) {
				return "TO_CHAR(" + colName + "-(" + numOfMins + "/1440), '"
						+ format + "') ";
			} else {
				return "TO_CHAR(" + colName + "+(" + numOfMins + "/1440), '"
						+ format + "') ";
			}
		}
	}

	public String getSelectDaysBetween(String dateVal, String additionDays,
			String startDateCol, String endDateCol, int dbType) {

		additionDays = additionDays.length() == 0 ? "0" : additionDays;
		String format = getDBDateFormat(ORACLE_MMSDDSYYYY, dbType);
		switch (dbType) {
		case DB_MYSQL:
			return " CASE WHEN STR_TO_DATE('" + dateVal + "', '" + format
					+ "') <= " + endDateCol + " THEN (DATEDIFF(STR_TO_DATE('"
					+ dateVal + "', '" + format + "'), " + startDateCol + ") + "
					+ additionDays + ") ELSE (DATEDIFF(" + endDateCol + ", "
					+ startDateCol + ") + " + additionDays + ") END ";

		default:
			return " CASE WHEN TO_DATE('" + dateVal + "', '" + format + "') <= "
					+ startDateCol + " THEN ((TO_DATE('" + dateVal + "', '"
					+ format + "') - " + startDateCol + ") + " + additionDays
					+ ") ELSE ((" + endDateCol + " - " + startDateCol + ") + "
					+ additionDays + ") END";
		}
	}

	public String getSelectDateFormat(String colName, String format,
			int dbType) {

		format = getDBDateFormat(format, dbType);
		switch (dbType) {
		case DB_MYSQL:
			return "DATE_FORMAT(" + colName + ", '" + format + "') ";

		default:
			return "TO_CHAR(" + colName + ", '" + format + "') ";
		}
	}

	public String getIDInCondQuery(String searchValue, String colName) {

		String condQry = "";
		if (searchValue.length() > 0)
			condQry += " AND " + colName + " IN (" + searchValue.trim() + ") ";

		return condQry;
	}

	public String getIDNotInCondQuery(String searchValue, String colName) {

		String condQry = "";
		if (searchValue.length() > 0)
			condQry += " AND " + colName + " NOT IN (" + searchValue.trim()
					+ ") ";

		return condQry;
	}

	public String getDataInCondQuery(String searchValue, String colName) {

		String condQry = "";
		if (searchValue.length() > 0)
			condQry += " AND LOWER(" + colName + ") IN ('"
					+ searchValue.toLowerCase().trim() + "') ";

		return condQry;
	}

	public String getDataInCondQuery(String searchValue, String colName,
			String seperator) {

		String condQry = "";
		if (searchValue.length() > 0)
			condQry += " AND LOWER(" + colName + ") IN ('" + searchValue
					.toLowerCase().trim().replaceAll(seperator, "', '") + "') ";

		return condQry;
	}

	public String getDataLikeCondQuery(String searchValue, String colName) {

		String condQry = "";
		if (searchValue.length() > 0)
			condQry += " AND " + colName + " LIKE ('%" + searchValue.trim()
					+ "%') ";

		return condQry;
	}

	public String getDataNotLikeCondQuery(String searchValue, String colName) {

		String condQry = "";
		if (searchValue.length() > 0)
			condQry += " AND LOWER(" + colName + ") NOT LIKE ('%"
					+ searchValue.toLowerCase().trim() + "%') ";

		return condQry;
	}

	public String getDateCondQuery(String fromDate, String toDate,
			String colName, int dbType) {

		switch (dbType) {
		case DB_MYSQL:
			return mysqlDateCondQuery(fromDate, toDate, colName);

		default:
			return oracleDateCondQuery(fromDate, toDate, colName);
		}
	}

	public String getDateCondTypeQuery(String relationalOperator,
			String colName, String dateVal, String format, int dbType) {

		if (relationalOperator.length() > 0) {
			String condOperator = " AND ";

			if (GREATER_THAN.equalsIgnoreCase(relationalOperator)) {
				relationalOperator = ">";

			} else if (GREATER_THAN_EQUALS
					.equalsIgnoreCase(relationalOperator)) {
				relationalOperator = ">=";

			} else if (EQUALS_TO.equalsIgnoreCase(relationalOperator)) {
				relationalOperator = "=";

			} else if (NOT_EQUALS_TO.equalsIgnoreCase(relationalOperator)) {
				relationalOperator = "!=";

			} else if (LESS_THAN.equalsIgnoreCase(relationalOperator)) {
				relationalOperator = "<";

			} else if (LESS_THAN_EQUALS.equalsIgnoreCase(relationalOperator)) {
				relationalOperator = "<=";
			}

			if (format.length() == 0)
				format = ORACLE_MMSDDSYYYY;

			String dateFormat = getDBDateFormat(format, dbType);
			switch (dbType) {
			case DB_MYSQL:
				if (dateVal.length() > 0) {
					if (MYSQL_MMSDDSYYYY.equalsIgnoreCase(dateFormat)) {
						dateVal = stringDateFormat(dateVal, "MM/dd/yyyy",
								"yyyy-MM-dd");
						return condOperator + " DATE(" + colName + ")"
								+ relationalOperator + " DATE_FORMAT('"
								+ dateVal + "', '%Y-%m-%d')";
					} else {
						dateVal = dateVal.replaceAll("12:00:00", "00:00:00");
						return condOperator + " DATE_FORMAT(" + colName + ", '"
								+ dateFormat + "') " + relationalOperator + " '"
								+ dateVal + "'";
					}
				} else {
					return condOperator + " DATE(" + colName + ")"
							+ relationalOperator + " DATE(SYSDATE()) ";
				}

			default:
				if (dateVal.length() > 0) {
					if (dateFormat.length() != 10) {
						return condOperator + "TO_DATE(TO_CHAR(" + colName
								+ ", '" + dateFormat + "'), '" + dateFormat
								+ "') " + relationalOperator + " TO_DATE('"
								+ dateVal + "', '" + dateFormat + "')";

					} else {
						return condOperator + " TRUNC(" + colName + ")"
								+ relationalOperator + "TO_DATE('" + dateVal
								+ "', '" + dateFormat + "') ";
					}

				} else {
					return condOperator + " TRUNC(" + colName + ")"
							+ relationalOperator + "TRUNC(SYSDATE) ";
				}
			}
		}

		return "";
	}

	public String getCurrentDate() {
		Date date = new Date(new java.util.Date().getTime());
		SimpleDateFormat sdf = new SimpleDateFormat("MM/dd/yyyy");
		return sdf.format(date);
	}

	public String stringDateFormat(String myDate, String existFormat,
			String returnFormat) {

		if (myDate != null && !myDate.equals("")) {
			try {
				if (myDate.length() > 23) {
					SimpleDateFormat sdf = new SimpleDateFormat(existFormat);
					java.util.Date detDate = sdf.parse(myDate);

					sdf = new SimpleDateFormat(returnFormat);
					myDate = sdf.format(detDate);

				} else if (myDate.trim().length() == 10) {
					SimpleDateFormat sdf = new SimpleDateFormat(existFormat);
					java.util.Date detDate = sdf.parse(myDate);

					sdf = new SimpleDateFormat(returnFormat);
					myDate = sdf.format(detDate);
				}

			} catch (ParseException ex) {
				ex.printStackTrace();
			}
		}

		return myDate;
	}

	private String mysqlDateCondQuery(String fromDate, String toDate,
			String colName) {

		fromDate = stringDateFormat(fromDate, "MM/dd/yyyy", "yyyy-MM-dd");
		toDate = stringDateFormat(toDate, "MM/dd/yyyy", "yyyy-MM-dd");

		StringBuffer condQry = new StringBuffer();
		if (fromDate.length() > 0 && toDate.length() > 0) {
			condQry.append(" AND ").append(colName);
			condQry.append(" BETWEEN '");
			condQry.append(fromDate + " 00:00:00").append("' AND '");
			condQry.append(toDate + " 23:59:59").append("' ");

		} else if (fromDate.length() > 0) {
			condQry.append(" AND DATE(").append(colName);
			condQry.append(") >= DATE_FORMAT('");
			condQry.append(fromDate);
			condQry.append("', '").append(MYSQL_YYYYSMMSDD);
			condQry.append("') ");

		} else if (toDate.length() > 0) {
			condQry.append(" AND DATE(").append(colName);
			condQry.append(") <= DATE_FORMAT('");
			condQry.append(toDate);
			condQry.append("', '").append(MYSQL_YYYYSMMSDD);
			condQry.append("') ");
		}

		return condQry.toString();
	}

	private String oracleDateCondQuery(String fromDate, String toDate,
			String colName) {

		StringBuffer condQry = new StringBuffer();
		if (fromDate.length() > 0 && toDate.length() > 0) {
			condQry.append(" AND TRUNC(").append(colName);
			condQry.append(") BETWEEN TO_DATE('");
			condQry.append(fromDate).append("', '").append(ORACLE_MMSDDSYYYY);
			condQry.append("') AND TO_DATE('");
			condQry.append(toDate).append("', '").append(ORACLE_MMSDDSYYYY);
			condQry.append("') ");

		} else if (fromDate.length() > 0) {
			condQry.append(" AND TRUNC(").append(colName);
			condQry.append(") >= TO_DATE('");
			condQry.append(fromDate).append("', '").append(ORACLE_MMSDDSYYYY);
			condQry.append("') ");

		} else if (toDate.length() > 0) {
			condQry.append(" AND TRUNC(").append(colName);
			condQry.append(") <= TO_DATE('");
			condQry.append(toDate).append("', '").append(ORACLE_MMSDDSYYYY);
			condQry.append("') ");
		}

		return condQry.toString();
	}

	public String[] getIndexedDataFromList(List resultsList, int[] indexArray) {

		StringBuffer returnBuff1 = new StringBuffer();
		StringBuffer returnBuff2 = new StringBuffer();
		StringBuffer returnBuff3 = new StringBuffer();
		StringBuffer returnBuff4 = new StringBuffer();

		List<String> duplicateList1 = new ArrayList<String>();
		List<String> duplicateList2 = new ArrayList<String>();
		List<String> duplicateList3 = new ArrayList<String>();
		List<String> duplicateList4 = new ArrayList<String>();

		List tempList = null;
		for (int i = 0; i < resultsList.size(); i++) {
			tempList = (List) resultsList.get(i);
			for (int j = 0; j < indexArray.length; j++) {
				int indexVal = indexArray[j];
				switch (j) {
				case 0:
					returnBuff1 = getIndexedDataFromList(tempList, indexVal,
							duplicateList1, returnBuff1);
					break;

				case 1:
					returnBuff2 = getIndexedDataFromList(tempList, indexVal,
							duplicateList2, returnBuff2);
					break;

				case 2:
					returnBuff3 = getIndexedDataFromList(tempList, indexVal,
							duplicateList3, returnBuff3);
					break;

				case 3:
					returnBuff4 = getIndexedDataFromList(tempList, indexVal,
							duplicateList4, returnBuff4);
					break;
				}
			}
		}

		return new String[] { returnBuff1.toString(), returnBuff2.toString(),
				returnBuff3.toString(), returnBuff4.toString() };
	}

	private StringBuffer getIndexedDataFromList(List tempList, int indexVal,
			List<String> duplicateList, StringBuffer returnBuff) {

		if (tempList.size() > indexVal) {
			String data = tempList.get(indexVal) == null ? ""
					: tempList.get(indexVal).toString().trim();
			if (data.length() > 0 && !duplicateList.contains(data)) {
				duplicateList.add(data);
				if (returnBuff.length() > 0)
					returnBuff.append(",");
				returnBuff.append(data);
			}
		}

		return returnBuff;
	}

	public String decodeStatus(String colName, int colValues[], int dbType) {
		StringBuffer decode = new StringBuffer();
		switch (dbType) {
		case DB_MYSQL:
			decode.append(" CASE ").append(colName);
			for (int i = 0; i < colValues.length; i++) {
				decode.append(" WHEN ");
				decode.append(colValues[i]);
				decode.append(" THEN ");
				decode.append(
						"'" + RecordStatus.RecordStatus[colValues[i]].toString()
								+ "'");
			}
			decode.append(" END ");
			return decode.toString();

		default:
			decode.append(" DECODE (").append(colName);
			for (int i = 0; i < colValues.length; i++) {
				decode.append(",");
				decode.append(colValues[i]);
				decode.append(",");
				decode.append(
						"'" + RecordStatus.RecordStatus[colValues[i]].toString()
								+ "'");
			}
			decode.append(")");
		}

		return decode.toString();
	}

	public String decodeStatus(String colName, Map<String, String> _hMap,
			int dbType) {

		MainUtil mainUtil = new MainUtil();
		String ids = mainUtil.getAll(_hMap);
		String splitArray[] = ids.split(",");
		StringBuffer decode = new StringBuffer();
		switch (dbType) {
		case DB_MYSQL:
			decode.append(" CASE ").append(colName);
			for (int i = 0; i < splitArray.length; i++) {
				decode.append(" WHEN ");
				decode.append(splitArray[i]);
				decode.append(" THEN '");
				decode.append(_hMap.get(splitArray[i]) == null ? splitArray[i]
						: _hMap.get(splitArray[i])).append("'");
			}
			decode.append(" END ");
			return decode.toString();

		default:
			decode.append(" DECODE (").append(colName);
			for (int i = 0; i < splitArray.length; i++) {
				decode.append(", ");
				decode.append(splitArray[i]);
				decode.append(", '");
				decode.append(_hMap.get(splitArray[i]) == null ? splitArray[i]
						: _hMap.get(splitArray[i])).append("'");
			}
			decode.append(")");
		}

		return decode.toString();
	}

}
