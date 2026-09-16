package com.dataobjects;

import java.util.ArrayList;
import java.util.List;

import com.beans.Login;
import com.beans.MainBean;
import com.util.RecordStatus;
import com.util.SubmitType;

public class LoginDAO extends MVPGDAO {

	Login bean = new Login();

	@Override
	public Object[] login(MainBean mainBean, String ipAddress, String sessionID,
			String loginUser, String loginUserRoles, String loginUserID,
			String entityID) {

		bean = (Login) mainBean;
		AdminEmployeeDAO employeeDAO = new AdminEmployeeDAO();
		try {
			String selQry = "SELECT ENTITYUSERSID, EMPLOYEEID, ENTITYID, "
					+ "PASSWORD, USERNAME FROM ENTITYUSERS WHERE STATUS="
					+ RecordStatus.ACTIVE
					+ db.getDataInCondQuery(bean.getLoginUser(), "USERNAME");

			List resultList = db.selectAsList(selQry, 5);
			if (resultList.size() == 0) {
				if (bean.getLoginUser().equalsIgnoreCase(bean.getLoginPwd())) {
					// Login using Employee Email or Mobile with username and
					// pwd as same
					selQry = "SELECT EMPLOYEEID, ENTITYID FROM EMPLOYEE A, CONTACT B "
							+ "WHERE A.CONTACTID=B.CONTACTID AND A.STATUS="
							+ RecordStatus.ACTIVE + " AND A.REVIEW_STATUS="
							+ RecordStatus.ACTIVE + " AND B.STATUS="
							+ RecordStatus.ACTIVE + db.getDataInCondQuery(
									bean.getLoginUser(), "B.EMAIL");

					List empList = db.selectAsList(selQry, 2);
					if (empList.size() == 0) {
						selQry = "SELECT EMPLOYEEID, ENTITYID FROM EMPLOYEE A, CONTACT B "
								+ "WHERE A.CONTACTID=B.CONTACTID AND A.STATUS="
								+ RecordStatus.ACTIVE + " AND A.REVIEW_STATUS="
								+ RecordStatus.ACTIVE + " AND B.STATUS="
								+ RecordStatus.ACTIVE + db.getDataInCondQuery(
										bean.getLoginUser(), "B.MOBILE");

						empList = db.selectAsList(selQry, 2);
					}

					if (empList.size() == 1) {
						List tempList = (ArrayList) empList.get(0);
						String employeeID = getListDBData(tempList, 0);
						String entityID1 = getListDBData(tempList, 1);

						selQry = "SELECT ENTITYUSERSID, EMPLOYEEID, ENTITYID, "
								+ "PASSWORD, USERNAME FROM ENTITYUSERS WHERE STATUS="
								+ RecordStatus.ACTIVE + db.getDataInCondQuery(
										employeeID, "EMPLOYEEID");
						resultList = db.selectAsList(selQry, 5);

						if (resultList.size() == 1) {
							tempList = (ArrayList) resultList.get(0);
							String loginPwd = getListDBData(tempList, 3);
							bean.setLoginPwd(loginPwd);
						}
					}
				}
			}

			resultList = preferLiveEmployeeUserRows(resultList);

			if (resultList.size() >= 1) {
				List tempList = (ArrayList) resultList.get(0);
				String entityUsersID = getListDBData(tempList, 0);
				String employeeID = getListDBData(tempList, 1);
				String entityID1 = getListDBData(tempList, 2);
				String dbPwd = getListDBData(tempList, 3);
				loginUser = getListDBData(tempList, 4);

				if (dbPwd.equals(bean.getLoginPwd())) {
					String employeeName = "";
					String userRole = "";
					if (employeeID.length() > 0) {
						selQry = "SELECT FULLNAME, ROLE FROM EMPLOYEE WHERE EMPLOYEEID="
								+ employeeID + " AND STATUS="
								+ RecordStatus.ACTIVE + " AND REVIEW_STATUS="
								+ RecordStatus.ACTIVE;
						resultList = db.selectAsList(selQry, 2);
						if (resultList.size() == 1) {
							tempList = (ArrayList) resultList.get(0);
							employeeName = getListDBData(tempList, 0);
							userRole = getListDBData(tempList, 1);
						} else {
							// Deleted or Inactive or Quit or Terminated Users
							// Not Allowed
							return new Object[] {};
						}

					} else if ("superadmin".equalsIgnoreCase(loginUser)) {
						userRole = "TechAdmin";
					}

					createUserAudit(SubmitType.LOGIN, ipAddress, sessionID,
							loginUser, entityID1);

					return new Object[] { entityID1, entityUsersID, loginUser,
							employeeID, userRole, employeeName };
				}

			} else if (resultList.size() == 0) {
				// First Time login
				if ("superadmin".equalsIgnoreCase(bean.getLoginUser())
						&& "Admin@2024".equals(bean.getLoginPwd())) {

					List<String> insList = new ArrayList<String>();
					String entityUsersID = "";
					insList = employeeDAO.buildUsersQry("", bean.getLoginUser(),
							bean.getLoginPwd(), loginUser, entityID, insList);

					selQry = "SELECT A.EMPLOYEEID, B.MOBILE, A.ENTITYID FROM "
							+ "EMPLOYEE A, CONTACT B WHERE A.CONTACTID=B.CONTACTID AND A.STATUS="
							+ RecordStatus.ACTIVE + " AND A.REVIEW_STATUS="
							+ RecordStatus.ACTIVE + " AND A.EMPLOYEEID NOT IN ("
							+ "SELECT DISTINCT EMPLOYEEID FROM ENTITYUSERS"
							+ ") AND B.MOBILE IS NOT NULL ORDER BY 1";
					resultList = db.selectAsList(selQry, 3);
					for (int i = 0; i < resultList.size(); i++) {
						List tempList = (ArrayList) resultList.get(i);
						String employeeID = getListDBData(tempList, 0);
						String mobileNum = getListDBData(tempList, 1);
						String entityID1 = getListDBData(tempList, 2);

						if (mobileNum.length() > 0)
							insList = employeeDAO.buildUsersQry(employeeID,
									mobileNum, mobileNum, loginUser, entityID1,
									insList);
					}

					boolean result = db.batchInsert(insList);
					if (result) {
						selQry = "SELECT ENTITYUSERSID FROM ENTITYUSERS WHERE STATUS="
								+ RecordStatus.ACTIVE + db.getDataInCondQuery(
										bean.getLoginUser(), "USERNAME");
						entityUsersID = db.selectById(selQry);

						return new Object[] { entityID, entityUsersID,
								bean.getLoginUser(), "", "TechAdmin" };
					}
				}
			}

		} catch (Exception ex) {
			ex.printStackTrace();
		}

		return new Object[] {};
	}

	/**
	 * Duplicate USERNAME rows (same mobile reused) make size!=1 and login
	 * fails. Keep only accounts whose employee is still active.
	 */
	private List preferLiveEmployeeUserRows(List resultList) {
		if (resultList == null || resultList.size() <= 1)
			return resultList;
		List keep = new ArrayList();
		for (int i = 0; i < resultList.size(); i++) {
			List row = (ArrayList) resultList.get(i);
			String employeeID = getListDBData(row, 1);
			if (employeeID == null || employeeID.trim().length() == 0) {
				keep.add(row);
				continue;
			}
			try {
				List emp = db.selectAsList(
						"SELECT EMPLOYEEID FROM EMPLOYEE WHERE EMPLOYEEID="
								+ employeeID + " AND STATUS="
								+ RecordStatus.ACTIVE + " AND REVIEW_STATUS="
								+ RecordStatus.ACTIVE,
						1);
				if (emp.size() == 1)
					keep.add(row);
			} catch (Exception ignore) {
			}
		}
		return keep.size() > 0 ? keep : resultList;
	}

	@Override
	public Object[] logout(MainBean mainBean, String ipAddress,
			String sessionID, String loginUser, String loginUserRoles,
			String loginUserID, String entityID) {

		try {
			bean = (Login) mainBean;
			createUserAudit(SubmitType.LOGOUT, ipAddress, sessionID,
					bean.getLoginUser(), entityID);
		} catch (Exception ex) {
			ex.printStackTrace();
		}

		return new Object[] {};
	}

	public boolean createUserAudit(int submitType, String ipAddress,
			String sessionID, String loginUser, String entityID)
			throws Exception {

		boolean result = true;
		String insQry = "";

		if (submitType == SubmitType.LOGIN) {
			String autoIncrementArray[] = db
					.getAutoIncrementArray("USERAUDITID");

			insQry = "INSERT INTO USERAUDIT (";
			if (autoIncrementArray != null)
				insQry += autoIncrementArray[0];
			insQry += "ENTITYID, USERNAME, USERIPADDRESS, SESSIONID, "
					+ "LOGINTETIME, STATUS) VALUES (";
			if (autoIncrementArray != null)
				insQry += autoIncrementArray[1];
			insQry += db.getInsertDBValue(entityID) + ", "
					+ db.getInsertDBValue(loginUser) + ", "
					+ db.getInsertDBValue(ipAddress) + ", "
					+ db.getInsertDBValue(sessionID) + ", "
					+ db.getInsertSysdate() + ", " + RecordStatus.ACTIVE + ")";

		} else if (submitType == SubmitType.LOGOUT) {
			String selQry = "SELECT USERAUDITID FROM USERAUDIT WHERE STATUS="
					+ RecordStatus.ACTIVE
					+ db.getDataInCondQuery(loginUser, "USERNAME")
					+ db.getDataInCondQuery(sessionID, "SESSIONID")
					+ db.getIDInCondQuery(entityID, "ENTITYID");
			List resultList = db.selectAsList(selQry, 1);
			if (resultList.size() == 1) {
				List tempList = (ArrayList) resultList.get(0);
				String userAuditID = getListData(tempList, 0);
				if (userAuditID.length() > 0) {
					insQry = "UPDATE USERAUDIT SET LOGOUTTIME="
							+ db.getInsertSysdate() + ", STATUS="
							+ RecordStatus.COMPLETED + "  WHERE USERAUDITID="
							+ userAuditID;
				}
			}
		}

		if (insQry.length() > 0)
			result = db.update(insQry);

		return result;
	}

}
