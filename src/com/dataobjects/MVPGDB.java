package com.dataobjects;

import java.sql.Connection;
import java.sql.DriverManager;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import javax.naming.Context;
import javax.naming.InitialContext;
import javax.sql.DataSource;

import com.util.RecordStatus;

public class MVPGDB extends Database {

	private static DataSource dataSource = null;
	public static int DB_TYPE = DB_MYSQL;

	public static void main(String args[]) {
		MVPGDB tempDB = new MVPGDB();

		tempDB.testConnect();
	}

	public void testConnect() {
		final String DB_URL = "jdbc:mysql://system1a:3306/fleetdb?useSSL=false&allowPublicKeyRetrieval=true";
		final String USER = "mysqlUSR";
		final String PASS = "mysqlUSR";
		List<String> upList = new ArrayList<String>();
		String upQry = "UPDATE EMPLOYEE_SCHEDULE SET STATUS="
				+ RecordStatus.DELETE + " WHERE STATUS=0";
		upList.add(upQry);
		// Open a connection
		try {
			Connection conn = DriverManager.getConnection(DB_URL, USER, PASS);
			batchInsert(conn, upList);
		} catch (Exception e) {
			e.printStackTrace();
			System.out.println("" + e.getMessage());
		}

	}

	private static void loadDataSource() {

		try {
			Context initContext = new InitialContext();
			Context envContext = (Context) initContext.lookup("java:/comp/env");
			dataSource = (DataSource) envContext.lookup("jdbc/MVPGDB");
		} catch (Exception ex) {
			ex.printStackTrace();
		}
	}

	private Connection getDBConn() throws Exception {

		Connection conn = null;
		try {
			if (dataSource == null)
				loadDataSource();
			conn = dataSource.getConnection();
		} catch (Exception ex) {
			ex.printStackTrace();
		}

		return conn;
	}

	public String getDataType(String dataType) throws Exception {

		switch (DB_TYPE) {
		case DB_MYSQL:
			if ("DATE".equalsIgnoreCase(dataType)) {
				return " DATETIME";
			} else if ("INT".equalsIgnoreCase(dataType)) {
				return " INT(8)";
			} else {
				return " VARCHAR(200)";
			}

		default:
			if ("DATE".equalsIgnoreCase(dataType)) {
				return " DATE";
			} else if ("INT".equalsIgnoreCase(dataType)) {
				return " NUMBER";
			} else {
				return " VARCHAR2(200)";
			}
		}
	}

	public String[] getAutoIncrementArray(String IdName) throws Exception {

		switch (DB_TYPE) {
		case DB_MYSQL:
			return null;

		default:
			return new String[] { (IdName + ", "), (IdName + ".NEXTVAL, ") };
		}
	}

	public String checkTableExistQry(String tableName) throws Exception {

		String selQry = "";
		switch (DB_TYPE) {
		case DB_MYSQL:
			selQry = "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME LIKE '"
					+ tableName + "' AND TABLE_SCHEMA LIKE DATABASE()";
			break;

		default:
			selQry = "SELECT TABLE_NAME FROM USER_TABLES WHERE TABLE_NAME LIKE '"
					+ tableName + "'";
			break;
		}

		return selectById(selQry);
	}

	public String getNextIDValue(String IdName) throws Exception {
		return getSequenceID(getDBConn(), getNextIDQry(IdName, DB_TYPE));
	}

	public String selectById(String selQry) throws Exception {
		return selectById(getDBConn(), selQry);
	}

	public boolean insertBlob(String blobQry, String fileNameWithPath)
			throws Exception {
		return insertBlob(getDBConn(), "", blobQry, fileNameWithPath);
	}

	public boolean insertBlob(String insQry, String blobQry,
			String fileNameWithPath) throws Exception {
		return insertBlob(getDBConn(), insQry, blobQry, fileNameWithPath);
	}

	public String fetchBlob(String blobQry, String downloadPath,
			String fileName) throws Exception {
		return fetchBlob(getDBConn(), blobQry, downloadPath, fileName);
	}

	public List selectAsList(String selQry, int numOfColumns) throws Exception {
		return selectAsList(getDBConn(), selQry, numOfColumns);
	}

	public boolean create(String upQry) throws Exception {
		return create(getDBConn(), upQry);
	}

	public boolean update(String upQry) throws Exception {
		return update(getDBConn(), upQry);
	}

	public boolean batchInsert(List<String> insRecord) throws Exception {
		return batchInsert(getDBConn(), insRecord);
	}

	public String getInsertSysdate() {
		return getInsertSysdate(DB_TYPE);
	}

	public String getInsertDate(String insDate) {
		return getInsertDate(insDate, DB_TYPE);
	}

	public String getInsertDateTime(String insDate) {
		return getInsertDateTime(insDate, DB_TYPE);
	}

	public String getInsertDateFormat(String insDate, String format) {
		return getInsertDateFormat(insDate, format, DB_TYPE);
	}

	public String getInsertDBValue(Object input) {
		return getInsertDBValue(input, DB_TYPE);
	}

	public String getInsertAppendDBValue(String columnName, Object input) {
		return getInsertAppendDBValue(columnName, input, DB_TYPE);
	}

	public String getConcat(String columnsArray[]) {
		return getConcat(columnsArray, DB_TYPE);
	}

	public String getName(String firstName, String lastName) {
		return getConcat(new String[] { firstName, " ", lastName }, DB_TYPE);
	}

	public String getSelectDate(String colName) {
		return getSelectDate(colName, DB_TYPE);
	}

	public String getSelectTime(String colName) {
		return getSelectTime(colName, DB_TYPE);
	}

	public String getSelectTimeWithTypeInterval(String type, int numOfMins,
			String colName) {
		return getSelectTimeWithTypeInterval(type, numOfMins, colName, DB_TYPE);
	}

	public String getSelectDaysBetween(String dateVal, String additionalDays,
			String startDateCol, String endDateCol) {
		return getSelectDaysBetween(dateVal, additionalDays, startDateCol,
				endDateCol, DB_TYPE);
	}

	public String getSelectDateTime(String colName) {
		return getSelectDateTime(colName, DB_TYPE);
	}

	public String getDateCondQuery(String fromDate, String toDate,
			String colName) {
		return getDateCondQuery(fromDate, toDate, colName, DB_TYPE);
	}

	public String getSelectDateFormat(String colName, String format) {
		return getSelectDateFormat(colName, format, DB_TYPE);
	}

	public String getDateCondTypeQuery(String relationalOperator,
			String colName, String dateVal, String format) {
		return getDateCondTypeQuery(relationalOperator, colName, dateVal,
				format, DB_TYPE);
	}

	public String getDateCondTypeQuery(String relationalOperator,
			String colName, String dateVal) {
		return getDateCondTypeQuery(relationalOperator, colName, dateVal, "",
				DB_TYPE);
	}

	public String getDateCondTypeQuery(String relationalOperator,
			String colName) {
		return getDateCondTypeQuery(relationalOperator, colName, "", "",
				DB_TYPE);
	}

	public String decodeStatus(String colName, int colValues[]) {
		return decodeStatus(colName, colValues, DB_TYPE);
	}

	public String decodeStatus(String colName, Map<String, String> _hMap) {
		return decodeStatus(colName, _hMap, DB_TYPE);
	}
}
