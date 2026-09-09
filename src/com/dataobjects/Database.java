package com.dataobjects;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.sql.Blob;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;

public class Database extends DatabaseQuery {

	protected String getNextIDQry(String IdName, int dbType) throws Exception {

		StringBuffer qry = new StringBuffer();
		switch (dbType) {
		case DB_MYSQL:
			qry = qry.append("SELECT NEXTVAL('");
			qry.append(IdName);
			qry.append("')");
			break;

		case DB_ORACLE:
			qry = qry.append("SELECT ");
			qry.append(IdName);
			qry.append(".NEXTVAL FROM DUAL");
			break;
		}

		return qry.toString();
	}

	public synchronized boolean insertBlob(Connection conn, String insQry,
			String blobQry, String fileNameWithPath) {

		boolean isInsert = false;
		Statement stmt = null;
		PreparedStatement pstmt = null;
		FileInputStream inputStream = null;
		int stmtStatus = 1;

		try {
			conn.setAutoCommit(false);
			System.out.println("insertBlob :: " + insQry);
			if (insQry.length() > 0) {
				stmt = conn.createStatement();
				stmtStatus = stmt.executeUpdate(insQry);
				System.out.println(
						"insertBlob :: " + stmtStatus + " :: " + insQry);
			}
			if (stmtStatus != 0) {
				pstmt = conn.prepareStatement(blobQry);
				inputStream = new FileInputStream(new File(fileNameWithPath));
				pstmt.setBinaryStream(1, inputStream);
				pstmt.executeUpdate();
				conn.commit();
				isInsert = true;
			}
		} catch (SQLException ex) {
			System.err.println("insertBlob :: " + stmtStatus + " :: " + blobQry
					+ " :: " + ex.getMessage());
			ex.printStackTrace();

		} catch (FileNotFoundException ex) {
			System.err.println(
					"insertBlob " + blobQry + " :: " + ex.getMessage());
			ex.printStackTrace();

		} catch (Exception ex) {
			System.err.println(
					"insertBlob :: " + blobQry + " :: " + ex.getMessage());
			ex.printStackTrace();

		} finally {
			try {
				if (inputStream != null)
					inputStream.close();
				closeDBObjects(null, null, pstmt, conn);
			} catch (Exception ex) {
				ex.printStackTrace();
			}
		}

		System.out.println("insertBlob :: " + isInsert + " :: " + insQry
				+ " :: " + blobQry + " :: " + fileNameWithPath);
		return isInsert;
	}

	public String fetchBlob(Connection conn, String blobQry,
			String downloadPath, String fileName) throws Exception {

		ResultSet resultset = null;
		Statement stmt = conn.createStatement();
		File fileObj = null;
		String fileNameWithPath = null;
		System.out.println("fetchBlob :: " + downloadPath + " :: " + fileName
				+ " :: " + blobQry);

		try {
			stmt = conn.createStatement();
			resultset = stmt.executeQuery(blobQry);
			if (resultset.next()) {
				Blob mapBlob = resultset.getBlob(1);
				if (fileName.length() == 0)
					fileName = resultset.getString(2);

				fileNameWithPath = downloadPath + File.separator + fileName;

				fileObj = blobToFile(mapBlob, fileNameWithPath);
				if (fileObj == null)
					fileNameWithPath = null;
			}

		} catch (Exception ex) {
			ex.printStackTrace();
			System.err.println(
					"fetchBlob :: " + blobQry + " :: " + ex.getMessage());
			closeDBObjects(resultset, stmt, null, conn);

		} finally {
			try {
				conn.close();
				stmt.close();
				closeDBObjects(null, stmt, null, conn);
			} catch (SQLException ex) {

			}
		}

		System.out.println("fetchBlob :: " + fileNameWithPath);

		return fileNameWithPath;
	}

	private File blobToFile(Blob blob, String fileNameWithPath) {

		FileOutputStream fileOutStream = null;
		InputStream blobStream = null;
		File fileObj = null;
		System.out.println("blobToFile :: " + fileNameWithPath);

		try {
			blobStream = blob.getBinaryStream();
			fileObj = new File(fileNameWithPath);
			fileOutStream = new FileOutputStream(fileObj);
			byte[] buffer = new byte[10];
			int nbytes = 0;
			while ((nbytes = blobStream.read(buffer)) != -1) {
				fileOutStream.write(buffer, 0, nbytes);
			}
			fileOutStream.flush();
			fileOutStream.close();
			blobStream.close();

		} catch (Exception ex) {
			ex.printStackTrace();
			System.err.println("blobToFile :: " + fileNameWithPath + " :: "
					+ ex.getMessage());

		} finally {
			try {
				if (blobStream != null)
					blobStream.close();
				if (fileOutStream != null)
					fileOutStream.close();
			} catch (Exception e) {
				e.printStackTrace();
			}
		}

		return fileObj;
	}

	protected String selectById(Connection conn, String selQry)
			throws Exception {

		StringBuffer buff = new StringBuffer();
		ResultSet resultset = null;
		Statement stmt = conn.createStatement();
		try {
			resultset = stmt.executeQuery(selQry);
			for (int i = 0; resultset.next(); i++) {
				if (resultset.getString(1) != null) {
					if (i > 0)
						buff.append(",");

					buff.append(resultset.getString(1));
				}
			}
			closeDBObjects(resultset, stmt, null, conn);

		} catch (Exception ex) {
			System.err.println(
					"selectById :: " + selQry + " :: " + ex.getMessage());
			ex.printStackTrace();
			closeDBObjects(resultset, stmt, null, conn);
		}

		System.out.println("selectById :: " + buff + " :: " + selQry);
		return buff.toString();
	}

	protected String getSequenceID(Connection conn, String selQry)
			throws Exception {

		StringBuffer buff = new StringBuffer();
		ResultSet resultset = null;
		Statement stmt = conn.createStatement();
		try {
			resultset = stmt.executeQuery(selQry);
			for (int i = 0; resultset.next(); i++) {
				if (resultset.getString(1) != null) {
					if (i > 0)
						buff.append(",");

					buff.append(resultset.getString(1));
				}
			}
			closeDBObjects(resultset, stmt, null, conn);

		} catch (Exception ex) {
			System.err.println(
					"getSequenceID :: " + selQry + " :: " + ex.getMessage());
			ex.printStackTrace();
			closeDBObjects(resultset, stmt, null, conn);
		}

		// System.out.println("getSequenceID :: " + buff + " :: " + selQry);
		return buff.toString();
	}

	protected List selectAsList(Connection conn, String selQry,
			int numOfColumns) throws Exception {

		List resultList = new ArrayList();
		ResultSet resultset = null;
		Statement stmt = conn.createStatement();
		try {
			resultset = stmt.executeQuery(selQry);
			while (resultset.next()) {
				List columnArrayList = new ArrayList();
				for (int i = 0; i < numOfColumns; i++)
					columnArrayList.add(resultset.getString(i + 1));

				resultList.add(columnArrayList);
				columnArrayList = null;
			}
			closeDBObjects(resultset, stmt, null, conn);

		} catch (Exception ex) {
			System.err.println(
					"selectAsList :: " + selQry + " :: " + ex.getMessage());
			ex.printStackTrace();
			closeDBObjects(resultset, stmt, null, conn);
		}

		System.out.println(
				"selectAsList :: " + resultList.size() + " :: " + selQry);
		return resultList;
	}

	protected boolean update(Connection conn, String upQry) throws Exception {

		Statement stmt = conn.createStatement();
		conn.setAutoCommit(false);
		boolean result = false;

		try {
			int insertStatus = stmt.executeUpdate(upQry);
			if (insertStatus == 0) {
				conn.rollback();
				closeDBObjects(null, stmt, null, conn);
				result = false;

			} else {
				conn.commit();
				result = true;
			}

		} catch (SQLException ex) {
			conn.rollback();
			System.err.println("update :: " + upQry + " :: " + ex.getMessage());
			ex.printStackTrace();

		} catch (Exception ex) {
			conn.rollback();
			System.err.println("update :: " + upQry + " :: " + ex.getMessage());
			ex.printStackTrace();

		} finally {
			closeDBObjects(null, stmt, null, conn);

		}

		System.out.println("update :: " + result + " :: " + upQry);
		return result;
	}

	protected boolean create(Connection conn, String upQry) throws Exception {

		Statement stmt = conn.createStatement();
		conn.setAutoCommit(false);
		boolean result = false;
		try {
			int insertStatus = stmt.executeUpdate(upQry);
			if (insertStatus != 0) {
				conn.rollback();
				closeDBObjects(null, stmt, null, conn);
				result = false;

			} else {
				conn.commit();
				result = true;
			}

		} catch (SQLException ex) {
			conn.rollback();
			System.err.println("create :: " + upQry + " :: " + ex.getMessage());
			ex.printStackTrace();

		} catch (Exception ex) {
			conn.rollback();
			System.err.println("create :: " + upQry + " :: " + ex.getMessage());
			ex.printStackTrace();

		} finally {
			closeDBObjects(null, stmt, null, conn);

		}

		System.out.println("create :: " + result + " :: " + upQry);
		return result;
	}

	protected boolean batchInsert(Connection conn, List<String> insRecord)
			throws Exception {

		boolean result = false;
		Statement stmt = conn.createStatement();
		conn.setAutoCommit(false);
		String qry = "";

		try {
			System.out.println(
					"batchInsert.insRecord.size :: " + insRecord.size());
			if (insRecord.size() > 0) {
				for (int i = 0; i < insRecord.size(); i++) {
					qry = insRecord.get(i);
					int insertStatus = stmt.executeUpdate(qry);
					System.out.println(i + " :: batchInsert :: " + insertStatus
							+ " :: " + qry);
					if (insertStatus == 0) {
						conn.rollback();
						result = false;
						break;
					}
				}
				conn.commit();
				result = true;
			} else
				result = false;

		} catch (SQLException ex) {
			conn.rollback();
			System.err.println(
					"batchInsert :: " + qry + " :: " + ex.getMessage());
			ex.printStackTrace();

		} catch (Exception ex) {
			conn.rollback();
			System.err.println(
					"batchInsert :: " + qry + " :: " + ex.getMessage());
			ex.printStackTrace();

		} finally {
			closeDBObjects(null, stmt, null, conn);
		}

		return result;
	}

	protected void closeDBObjects(ResultSet resultset, Statement stmt,
			PreparedStatement pstmt, Connection conn) {

		if (resultset != null) {
			try {
				resultset.close();
			} catch (Exception e) {
				e.printStackTrace();
			}
			resultset = null;
		}

		if (stmt != null) {
			try {
				stmt.close();
			} catch (Exception e) {
				e.printStackTrace();
			}
			stmt = null;
		}

		if (pstmt != null) {
			try {
				pstmt.close();
			} catch (Exception e) {
				e.printStackTrace();
			}
			pstmt = null;
		}

		if (conn != null) {
			try {
				if (!conn.isClosed()) {
					conn.close();
					conn = null;
				}
			} catch (Exception e) {
				e.printStackTrace();
			}
		}
	}

	protected java.io.File blobToFilePath(Blob blob, String directoryPath,
			String fileName) {

		FileOutputStream fileOutStream = null;
		java.io.File newFile = null;
		try {
			if (blob != null) {
				// Open a stream to read the Blob data
				InputStream blobStream = blob.getBinaryStream();
				String newFileName = fileName;
				if (directoryPath.length() > 0) {
					File fileObj = new File(directoryPath);
					if (!fileObj.isDirectory())
						fileObj.mkdirs();

					newFileName = directoryPath + java.io.File.separator
							+ fileName;
				}

				newFile = new java.io.File(newFileName);
				// Open a file stream to save the Blob data
				fileOutStream = new FileOutputStream(newFile);

				// Read from the Blob data input stream, and write to the file
				// output stream
				byte[] buffer = new byte[10]; // buffer holding bytes to be
				// transferred
				int nbytes = 0; // Number of bytes read
				// Read from Blob stream
				while ((nbytes = blobStream.read(buffer)) != -1) {
					// Write to file stream
					fileOutStream.write(buffer, 0, nbytes);
				}

				// Flush and close the streams
				fileOutStream.flush();
				fileOutStream.close();
				blobStream.close();
			}
		} catch (Exception ex) {
			ex.printStackTrace();
		}

		return newFile;
	}
}
