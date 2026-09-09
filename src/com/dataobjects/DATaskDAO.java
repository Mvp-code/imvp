package com.dataobjects;

import java.util.ArrayList;
import java.util.Calendar;
import java.util.GregorianCalendar;
import java.util.List;
import java.util.Map;

import com.beans.DATask;
import com.beans.ErrorBean;
import com.beans.MainBean;
import com.beans.SearchBean;
import com.util.RecordStatus;
import com.util.SubmitType;

/**
 * DA Tasks — dispatcher to-dos about DAs, with due dates.
 *
 * TASKSTATUS: 0 Open, 1 Pending, 2 Completed. "At Risk" (overdue) and
 * "Needs Attention" (due within 1 day) are computed from DUEDATE at read
 * time, never stored.
 *
 * Visibility: dispatchers (employee.ROLE=1) see only tasks assigned to
 * them; leads (ROLE=3 / TechAdmin — and blank roles for dev access) see
 * every task.
 */
public class DATaskDAO extends MVPGDAO {

	DATask bean = new DATask();

	private boolean isLead(String loginUserRoles) {
		if (loginUserRoles == null) return true;
		String r = loginUserRoles.trim();
		return r.length() == 0 || "3".equals(r) || "TechAdmin".equalsIgnoreCase(r);
	}

	/* da_tasks IDs come from seq.DA_TASKSID via NEXTVAL — if the row is
	   missing, NEXTVAL returns 0 and every insert fails with a duplicate/zero PK */
	private void ensureDaTaskSeq() throws Exception {
		List mx = db.selectAsList("SELECT IFNULL(MAX(DA_TASKSID),0) FROM da_tasks", 1);
		String max = "0";
		if (mx != null && !mx.isEmpty())
			max = getListData((List) mx.get(0), 0);
		if (max.length() == 0) max = "0";
		db.create("INSERT INTO seq (name, val) VALUES ('DA_TASKSID', " + max
				+ ") ON DUPLICATE KEY UPDATE val = GREATEST(val, " + max + ")");
	}

	@Override
	public SearchBean searchRecords(SearchBean searchBean, String recordID,
			String loginUser, String loginUserRoles, String loginUserID,
			String entityID) throws Exception {

		List<String> labelsList = new ArrayList<String>();
		labelsList.add("Due");
		labelsList.add("DA");
		labelsList.add("Task");
		labelsList.add("Topic");
		labelsList.add("Priority");
		labelsList.add("Assigned");
		labelsList.add("Status");

		searchBean.setWidthColumns(new int[] { 10, 15, 25, 10, 10, 15, 15 });
		searchBean.setDisplayName(bean.getDisplayName() + "s");
		searchBean.setController(bean.getController());

		String visCond = isLead(loginUserRoles) ? ""
				: " AND T.ASSIGNED_TO=" + db.getInsertDBValue(loginUser);

		String selQry = "SELECT T.DA_TASKSID, " + db.getSelectDate("T.DUEDATE")
				+ ", IFNULL(E.FULLNAME,''), T.TASKTITLE, IFNULL(T.TOPIC,''), "
				+ "IFNULL(T.PRIORITY,''), IFNULL(T.ASSIGNED_TO,''), T.TASKSTATUS, "
				+ "DATEDIFF(T.DUEDATE, CURDATE()) "
				+ "FROM da_tasks T LEFT JOIN employee E ON T.EMPLOYEEID=E.EMPLOYEEID "
				+ "WHERE T.STATUS!=" + RecordStatus.DELETE + " AND T.ENTITYID=" + entityID
				+ visCond + " ORDER BY T.TASKSTATUS, T.DUEDATE, T.DA_TASKSID DESC";

		List resultList = db.selectAsList(selQry, 9);
		for (int i = 0; i < resultList.size(); i++) {
			List t = (ArrayList) resultList.get(i);
			String st = t.get(7) == null ? "0" : t.get(7).toString().trim();
			String dd = t.get(8) == null ? "" : t.get(8).toString().trim();
			String stText = "Open", pill = "amber";
			if ("1".equals(st)) { stText = "Pending"; pill = "blue"; }
			else if ("2".equals(st)) { stText = "Completed"; pill = "green"; }
			String flag = "", flagLabel = "";
			if (!"2".equals(st) && dd.length() > 0) {
				int days = Integer.parseInt(dd);
				if (days < 0) { flag = "atrisk"; flagLabel = "At Risk"; }
				else if (days <= 1) { flag = "due"; flagLabel = "Needs Attention"; }
			}
			t.set(7, stText);
			t.add(pill);       /* 9 */
			t.add(flag);       /* 10 */
			t.add(flagLabel);  /* 11 */
			t.add(st);         /* 12 raw status for action buttons */
			resultList.set(i, t);
		}

		searchBean.setLabelsList(labelsList);
		searchBean.setDataList(resultList);

		Map transMap = searchBean.getTransMap();
		transMap.put("isLead", isLead(loginUserRoles) ? "yes" : "no");
		searchBean.setTransMap(transMap);
		return searchBean;
	}

	@Override
	public Object[] createRecord(MainBean mainBean, String loginUser,
			String loginUserRoles, String loginUserID, String entityID)
			throws Exception {

		DATask b = (DATask) mainBean;
		ensureDaTaskSeq();
		String recordID = db.getNextIDValue("DA_TASKSID");
		if (recordID.length() == 0 || "0".equals(recordID)) {
			ensureDaTaskSeq();
			recordID = db.getNextIDValue("DA_TASKSID");
		}
		if (recordID.length() == 0 || "0".equals(recordID))
			return new Object[] { "", getErrorType(false, SubmitType.CREATE,
					"Could not allocate task ID — check seq.DA_TASKSID") };

		String assignTo = b.getAssignedTo().length() > 0 ? b.getAssignedTo() : loginUser;

		List<String> insList = new ArrayList<String>();
		insList.add("INSERT INTO da_tasks (DA_TASKSID, ENTITYID, EMPLOYEEID, TASKTITLE, "
				+ "TASKDESC, TOPIC, PRIORITY, ASSIGNED_TO, DUEDATE, TASKSTATUS, "
				+ "CREATE_USER, CREATE_DATE, STATUS) VALUES ("
				+ recordID + ", " + entityID + ", "
				+ db.getInsertDBValue(b.getEmployeeID()) + ", "
				+ db.getInsertDBValue(b.getTaskTitle()) + ", "
				+ db.getInsertDBValue(b.getTaskDesc()) + ", "
				+ db.getInsertDBValue(cleanTopic(b.getTopic())) + ", "
				+ db.getInsertDBValue(b.getPriority()) + ", "
				+ db.getInsertDBValue(assignTo) + ", "
				+ db.getInsertDate(b.getDueDate()) + ", 0, "
				+ db.getInsertDBValue(loginUser) + ", " + db.getInsertSysdate() + ", "
				+ RecordStatus.ACTIVE + ")");

		boolean result = db.batchInsert(insList);
		ErrorBean errorType = getErrorType(result, SubmitType.CREATE, bean.getDisplayName());
		return new Object[] { result ? recordID : "", errorType };
	}

	@Override
	public Object[] updateRecord(MainBean mainBean, String loginUser,
			String loginUserRoles, String loginUserID, String entityID)
			throws Exception {

		DATask b = (DATask) mainBean;
		String recordID = b.getTaskID();
		String taskStatus = b.getTaskStatus().length() == 0 ? "0" : b.getTaskStatus();

		List<String> upList = new ArrayList<String>();
		upList.add("UPDATE da_tasks SET EMPLOYEEID=" + db.getInsertDBValue(b.getEmployeeID())
				+ ", TASKTITLE=" + db.getInsertDBValue(b.getTaskTitle())
				+ ", TASKDESC=" + db.getInsertDBValue(b.getTaskDesc())
				+ ", TOPIC=" + db.getInsertDBValue(cleanTopic(b.getTopic()))
				+ ", PRIORITY=" + db.getInsertDBValue(b.getPriority())
				+ ", ASSIGNED_TO=" + db.getInsertDBValue(b.getAssignedTo())
				+ ", DUEDATE=" + db.getInsertDate(b.getDueDate())
				+ ", TASKSTATUS=" + taskStatus
				+ ", COMPLETED_DATE=" + ("2".equals(taskStatus) ? db.getInsertSysdate() : "NULL")
				+ ", UPDATE_USER=" + db.getInsertDBValue(loginUser)
				+ ", UPDATE_DATE=" + db.getInsertSysdate()
				+ " WHERE DA_TASKSID=" + recordID);

		boolean result = db.batchInsert(upList);
		ErrorBean errorType = getErrorType(result, SubmitType.UPDATE, bean.getDisplayName());
		return new Object[] { recordID, errorType };
	}

	@Override
	public Object[] deleteRecord(MainBean mainBean, String loginUser,
			String loginUserRoles, String loginUserID, String entityID)
			throws Exception {

		DATask b = (DATask) mainBean;
		List<String> upList = new ArrayList<String>();
		upList.add(buildStatusQry("da_tasks", "DA_TASKSID", b.getTaskID(),
				RecordStatus.DELETE, loginUser));
		boolean result = db.batchInsert(upList);
		ErrorBean errorType = getErrorType(result, SubmitType.DELETE, bean.getDisplayName());
		return new Object[] { b.getTaskID(), errorType };
	}

	@Override
	public DATask fetchRecord(String recordID, String loginUser,
			String loginUserRoles, String loginUserID, String entityID,
			int submitType) throws Exception {

		String selQry = "SELECT DA_TASKSID, ENTITYID, EMPLOYEEID, TASKTITLE, TASKDESC, "
				+ "IFNULL(TOPIC,''), IFNULL(PRIORITY,''), IFNULL(ASSIGNED_TO,''), "
				+ db.getSelectDate("DUEDATE") + ", TASKSTATUS, CREATE_USER, "
				+ db.getSelectDateTime("CREATE_DATE") + ", UPDATE_USER, "
				+ db.getSelectDateTime("UPDATE_DATE")
				+ ", STATUS, 0 FROM da_tasks WHERE DA_TASKSID=" + recordID;

		List resultList = new ArrayList();
		if (recordID.length() > 0)
			resultList = db.selectAsList(selQry, bean.getBeanAttributes().size());

		bean = new DATask();
		bean = (DATask) setListValuesToBean(bean, bean.getBeanAttributes(), resultList);

		if (bean.getEmployeeID().length() > 0) {
			String nm = getTableColumnData("FULLNAME", "employee", "EMPLOYEEID",
					bean.getEmployeeID());
			bean.setEmployeeName(nm);
		}

		if (submitType == SubmitType.CREATE) {
			GregorianCalendar cal = new GregorianCalendar();
			cal.add(Calendar.DAY_OF_YEAR, 1);
			bean.setDueDate(sdfMMDDYYYY.format(cal.getTime()));
			bean.setAssignedTo(loginUser);
			bean.setPriority("Medium");
			bean.setTaskStatus("0");
		}
		return bean;
	}

	/* dispatchers & leads for the "Assign to" picker */
	@Override
	public String getSuggestorTypeData(String suggestorType,
			String suggestorValue, String entityID) throws Exception {

		if ("dispatchers".equalsIgnoreCase(suggestorType)) {
			List resultList = db.selectAsList("SELECT U.USERNAME, "
					+ "CONCAT(IFNULL(E.FULLNAME,U.USERNAME),' (',U.USERNAME,')') "
					+ "FROM entityusers U JOIN employee E ON U.EMPLOYEEID=E.EMPLOYEEID "
					+ "WHERE U.STATUS=0 AND E.ROLE IN (1,3) ORDER BY 2", 2);
			return getSuggextorData(resultList, suggestorValue);
		}
		return super.getSuggestorTypeData(suggestorType, suggestorValue, entityID);
	}

	/* one-click status moves from the list (Start / Done) + board JSON */
	@Override
	public String getAjaxRequestTypeResp(String requestType,
			Map<String, String> requestMap, String loginUser,
			String loginUserRoles, String loginUserID, String entityID)
			throws Exception {

		if ("dispBoardList".equalsIgnoreCase(requestType)) {
			/* Keep handed-off tasks on the board for the previous owner /
			   creator so the handoff does not "disappear". Leads see all. */
			String visCond = isLead(loginUserRoles) ? ""
					: " AND (UPPER(T.ASSIGNED_TO)=UPPER(" + db.getInsertDBValue(loginUser) + ")"
					+ " OR UPPER(T.CREATE_USER)=UPPER(" + db.getInsertDBValue(loginUser) + ")"
					+ " OR UPPER(T.TASKDESC) LIKE UPPER("
					+ db.getInsertDBValue("%HANDOFF " + loginUser + " →%") + ")"
					+ ")";
			List r = db.selectAsList("SELECT T.DA_TASKSID, "
					+ db.getSelectDate("T.DUEDATE") + ", IFNULL(E.FULLNAME,''), "
					+ "T.TASKTITLE, IFNULL(T.TOPIC,''), IFNULL(T.PRIORITY,''), "
					+ "IFNULL(T.ASSIGNED_TO,''), T.TASKSTATUS, "
					+ "IFNULL(T.TASKDESC,''), "
					+ "DATEDIFF(T.DUEDATE, CURDATE()), "
					+ "IFNULL(DATE_FORMAT(T.CREATE_DATE,'%m/%d/%Y %l:%i %p'),''), "
					+ "IFNULL(T.CREATE_USER,''), "
					+ "IFNULL(DATE_FORMAT(T.UPDATE_DATE,'%m/%d/%Y %l:%i %p'),''), "
					+ "IFNULL(T.UPDATE_USER,''), "
					+ "IFNULL(AE.FULLNAME, IFNULL(T.ASSIGNED_TO,'')) "
					+ "FROM da_tasks T LEFT JOIN employee E ON T.EMPLOYEEID=E.EMPLOYEEID "
					+ "LEFT JOIN entityusers AU ON AU.USERNAME=T.ASSIGNED_TO "
					+ "LEFT JOIN employee AE ON AE.EMPLOYEEID=AU.EMPLOYEEID "
					+ "WHERE T.STATUS!=" + RecordStatus.DELETE + " AND T.ENTITYID="
					+ entityID + visCond
					+ " AND T.TASKSTATUS IN (0,1) "
					+ "ORDER BY T.TASKSTATUS, T.DUEDATE, T.DA_TASKSID DESC LIMIT 300", 15);

			int open = 0, pend = 0, risk = 0, dueSoon = 0, handed = 0;
			java.util.Map<String, int[]> byDisp = new java.util.LinkedHashMap<String, int[]>();
			/* byDisp key = assignee username; value[0]=count, label stored separately */
			java.util.Map<String, String> byDispNm = new java.util.HashMap<String, String>();
			StringBuilder tasks = new StringBuilder("\"tasks\":[");
			for (int i = 0; i < r.size(); i++) {
				List t = (List) r.get(i);
				String st = getListData(t, 7);
				String dd = getListData(t, 9);
				String desc = getListData(t, 8);
				String owner = getListData(t, 6);
				String ownerNm = getListData(t, 14);
				if (owner.length() == 0) { owner = "(unassigned)"; ownerNm = "(unassigned)"; }
				if (ownerNm.length() == 0) ownerNm = owner;
				boolean handedOff = desc.toUpperCase().indexOf("HANDOFF ") >= 0;
				if (handedOff) handed++;
				if ("1".equals(st)) pend++; else open++;
				boolean overdue = false, needsAttn = false;
				if (dd.length() > 0) {
					try {
						int days = Integer.parseInt(dd);
						if (days < 0) { overdue = true; risk++; }
						else if (days <= 1) { needsAttn = true; dueSoon++; }
					} catch (Exception ignore) { }
				}
				int[] cnt = byDisp.get(owner);
				if (cnt == null) {
					cnt = new int[] { 0 };
					byDisp.put(owner, cnt);
					byDispNm.put(owner, ownerNm);
				}
				cnt[0]++;
				/* Prefer a Handed-off column when the task has been reassigned */
				String col = handedOff ? "handed"
						: ("1".equals(st) ? "pending" : (overdue ? "overdue" : "open"));
				String pri = getListData(t, 5);
				if (pri.length() == 0) pri = "Medium";
				if (i > 0) tasks.append(",");
				tasks.append("{")
						.append("\"id\":\"").append(jsEsc(getListData(t, 0))).append("\",")
						.append("\"due\":\"").append(jsEsc(getListData(t, 1))).append("\",")
						.append("\"da\":\"").append(jsEsc(getListData(t, 2))).append("\",")
						.append("\"title\":\"").append(jsEsc(getListData(t, 3))).append("\",")
						.append("\"topic\":\"").append(jsEsc(getListData(t, 4))).append("\",")
						.append("\"pri\":\"").append(jsEsc(pri)).append("\",")
						.append("\"owner\":\"").append(jsEsc(owner)).append("\",")
						.append("\"ownerNm\":\"").append(jsEsc(ownerNm)).append("\",")
						.append("\"st\":\"").append(jsEsc(st)).append("\",")
						.append("\"desc\":\"").append(jsEsc(desc)).append("\",")
						.append("\"overdue\":").append(overdue).append(",")
						.append("\"needsAttn\":").append(needsAttn).append(",")
						.append("\"handed\":").append(handedOff).append(",")
						.append("\"col\":\"").append(col).append("\",")
						.append("\"created\":\"").append(jsEsc(getListData(t, 10))).append("\",")
						.append("\"createUser\":\"").append(jsEsc(getListData(t, 11))).append("\",")
						.append("\"updated\":\"").append(jsEsc(getListData(t, 12))).append("\",")
						.append("\"updateUser\":\"").append(jsEsc(getListData(t, 13))).append("\"}");
			}
			tasks.append("]");
			StringBuilder owners = new StringBuilder("\"byDisp\":[");
			boolean firstO = true;
			for (java.util.Map.Entry<String, int[]> e : byDisp.entrySet()) {
				if (!firstO) owners.append(",");
				firstO = false;
				String label = byDispNm.get(e.getKey());
				if (label == null) label = e.getKey();
				owners.append("{\"id\":\"").append(jsEsc(e.getKey()))
						.append("\",\"nm\":\"").append(jsEsc(label))
						.append("\",\"n\":").append(e.getValue()[0]).append("}");
			}
			owners.append("]");
			return "{\"kpis\":{\"open\":" + open + ",\"pending\":" + pend
					+ ",\"risk\":" + risk + ",\"dueSoon\":" + dueSoon
					+ ",\"handed\":" + handed + "},"
					+ tasks.toString() + "," + owners.toString() + "}";
		}

		if ("taskNote".equalsIgnoreCase(requestType)) {
			String recordID = requestMap.get("recordID") == null ? ""
					: requestMap.get("recordID").trim();
			String note = requestMap.get("note") == null ? ""
					: requestMap.get("note").trim().replace("''", "'");
			if (!recordID.matches("\\d+") || note.length() == 0)
				return "<status>false</status><mesg>Note is required</mesg>";
			if (!isLead(loginUserRoles)) {
				String owner = getTableColumnData("ASSIGNED_TO", "da_tasks",
						"DA_TASKSID", recordID);
				if (!owner.equalsIgnoreCase(loginUser))
					return "<status>false</status><mesg>Only the assigned dispatcher "
							+ "or a lead can update this task</mesg>";
			}
			List<String> upList = new ArrayList<String>();
			upList.add("UPDATE da_tasks SET TASKDESC=CONCAT(IFNULL(TASKDESC,''), "
					+ db.getInsertDBValue("\n[" + loginUser + "] " + note) + "), "
					+ "UPDATE_USER=" + db.getInsertDBValue(loginUser)
					+ ", UPDATE_DATE=" + db.getInsertSysdate()
					+ " WHERE DA_TASKSID=" + recordID + " AND STATUS!="
					+ RecordStatus.DELETE);
			boolean result = db.batchInsert(upList);
			return "<status>" + result + "</status><mesg>"
					+ (result ? "Note saved" : "Save failed") + "</mesg>";
		}

		if ("dispBoardCreate".equalsIgnoreCase(requestType)) {
			String title = requestMap.get("title") == null ? ""
					: requestMap.get("title").trim().replace("''", "'");
			String employeeID = requestMap.get("employeeID") == null ? ""
					: requestMap.get("employeeID").trim();
			String dueDate = requestMap.get("dueDate") == null ? ""
					: requestMap.get("dueDate").trim().replace("''", "'");
			String assignedTo = requestMap.get("assignedTo") == null ? ""
					: requestMap.get("assignedTo").trim().replace("''", "'");
			if (title.length() == 0)
				return "<status>false</status><mesg>Task title is required</mesg>";
			if (!employeeID.matches("\\d+"))
				return "<status>false</status><mesg>Select a DA</mesg>";
			if (dueDate.length() == 0)
				return "<status>false</status><mesg>Due date is required</mesg>";
			if (assignedTo.length() == 0) assignedTo = loginUser;

			ensureDaTaskSeq();
			String recordID = db.getNextIDValue("DA_TASKSID");
			if (recordID.length() == 0 || "0".equals(recordID)) {
				ensureDaTaskSeq();
				recordID = db.getNextIDValue("DA_TASKSID");
			}
			if (recordID.length() == 0 || "0".equals(recordID))
				return "<status>false</status><mesg>Could not allocate task ID</mesg>";

			String topic = requestMap.get("topic") == null ? ""
					: requestMap.get("topic").trim().replace("''", "'");
			topic = cleanTopic(topic);
			String priority = requestMap.get("priority") == null ? "Medium"
					: requestMap.get("priority").trim().replace("''", "'");
			String desc = requestMap.get("desc") == null ? ""
					: requestMap.get("desc").trim().replace("''", "'");
			if (priority.length() == 0) priority = "Medium";

			List<String> insList = new ArrayList<String>();
			insList.add("INSERT INTO da_tasks (DA_TASKSID, ENTITYID, EMPLOYEEID, TASKTITLE, "
					+ "TASKDESC, TOPIC, PRIORITY, ASSIGNED_TO, DUEDATE, TASKSTATUS, "
					+ "CREATE_USER, CREATE_DATE, STATUS) VALUES ("
					+ recordID + ", " + entityID + ", "
					+ employeeID + ", "
					+ db.getInsertDBValue(title) + ", "
					+ db.getInsertDBValue(desc) + ", "
					+ db.getInsertDBValue(topic) + ", "
					+ db.getInsertDBValue(priority) + ", "
					+ db.getInsertDBValue(assignedTo) + ", "
					+ db.getInsertDate(dueDate) + ", 0, "
					+ db.getInsertDBValue(loginUser) + ", " + db.getInsertSysdate() + ", "
					+ RecordStatus.ACTIVE + ")");
			boolean result = db.batchInsert(insList);
			if (!result)
				return "<status>false</status><mesg>Save failed</mesg>";
			return "<status>true</status><mesg>Task created</mesg><id>" + recordID + "</id>";
		}

		if ("dispBoardDas".equalsIgnoreCase(requestType)) {
			/* Match classic DA Task employee picker: all active employees (DAs),
			   not a narrow ROLE=4 only set — stations often have 200+ DAs. */
			String q = requestMap.get("q") == null ? ""
					: requestMap.get("q").trim().replace("''", "'");
			String qCond = "";
			if (q.length() > 0) {
				String like = db.getInsertDBValue("%" + q + "%");
				qCond = " AND (FULLNAME LIKE " + like
						+ " OR CAST(EMPLOYEEID AS CHAR) LIKE " + like
						+ " OR IFNULL(TRANSPORTERID,'') LIKE " + like + ")";
			}
			List r = db.selectAsList("SELECT EMPLOYEEID, IFNULL(FULLNAME,'') "
					+ "FROM employee WHERE STATUS!=" + RecordStatus.DELETE
					+ " AND ENTITYID=" + entityID
					+ " AND REVIEW_STATUS=" + RecordStatus.ACTIVE
					+ qCond + " ORDER BY FULLNAME LIMIT 800", 2);
			if (r.isEmpty() && q.length() == 0)
				r = db.selectAsList("SELECT EMPLOYEEID, IFNULL(FULLNAME,'') "
						+ "FROM employee WHERE STATUS!=" + RecordStatus.DELETE
						+ " AND ENTITYID=" + entityID
						+ " ORDER BY FULLNAME LIMIT 800", 2);
			StringBuilder o = new StringBuilder("[");
			for (int i = 0; i < r.size(); i++) {
				List t = (List) r.get(i);
				o.append(i > 0 ? "," : "").append("{\"id\":\"")
						.append(jsEsc(getListData(t, 0))).append("\",\"nm\":\"")
						.append(jsEsc(getListData(t, 1))).append("\"}");
			}
			return o.append("]").toString();
		}

		if ("dispBoardTopics".equalsIgnoreCase(requestType)) {
			List r = db.selectAsList("SELECT DISTINCT TRIM(TOPIC) FROM da_tasks "
					+ "WHERE ENTITYID=" + entityID + " AND STATUS!="
					+ RecordStatus.DELETE
					+ " AND TOPIC IS NOT NULL AND TRIM(TOPIC)!='' "
					+ "ORDER BY 1 LIMIT 100", 1);
			java.util.LinkedHashSet<String> set = new java.util.LinkedHashSet<String>();
			String[] defaults = { "Safety", "Quality", "Attendance", "Coaching",
					"Customer Feedback", "Vehicle", "Other" };
			for (int i = 0; i < defaults.length; i++)
				set.add(defaults[i]);
			for (int i = 0; i < r.size(); i++) {
				String t = cleanTopic(getListData((List) r.get(i), 0));
				if (t.length() > 0) set.add(t);
			}
			StringBuilder o = new StringBuilder("[");
			int n = 0;
			for (String t : set) {
				o.append(n++ > 0 ? "," : "").append("\"").append(jsEsc(t))
						.append("\"");
			}
			return o.append("]").toString();
		}

		if ("dispBoardDispatchers".equalsIgnoreCase(requestType)) {
			List r = db.selectAsList("SELECT U.USERNAME, "
					+ "IFNULL(NULLIF(TRIM(E.FULLNAME),''), U.USERNAME) "
					+ "FROM entityusers U JOIN employee E ON U.EMPLOYEEID=E.EMPLOYEEID "
					+ "WHERE U.STATUS=" + RecordStatus.ACTIVE
					+ " AND E.STATUS!=" + RecordStatus.DELETE
					+ " AND E.ROLE IN (1,3) "
					+ "ORDER BY 2, 1", 2);
			java.util.LinkedHashMap<String, String> map =
					new java.util.LinkedHashMap<String, String>();
			for (int i = 0; i < r.size(); i++) {
				List t = (List) r.get(i);
				String user = getListData(t, 0);
				String nm = getListData(t, 1);
				if (user.length() == 0) continue;
				if (nm.length() == 0) nm = user;
				map.put(user, nm);
			}
			if (loginUser != null && loginUser.trim().length() > 0
					&& !map.containsKey(loginUser.trim())) {
				String dn = loginUser.trim();
				List me = db.selectAsList("SELECT IFNULL(NULLIF(TRIM(E.FULLNAME),''), U.USERNAME) "
						+ "FROM entityusers U JOIN employee E ON U.EMPLOYEEID=E.EMPLOYEEID "
						+ "WHERE U.USERNAME=" + db.getInsertDBValue(loginUser.trim())
						+ " LIMIT 1", 1);
				if (!me.isEmpty())
					dn = getListData((List) me.get(0), 0);
				map.put(loginUser.trim(), dn);
			}
			StringBuilder o = new StringBuilder("[");
			int n = 0;
			for (java.util.Map.Entry<String, String> e : map.entrySet()) {
				o.append(n++ > 0 ? "," : "").append("{\"id\":\"")
						.append(jsEsc(e.getKey())).append("\",\"nm\":\"")
						.append(jsEsc(e.getValue())).append("\"}");
			}
			return o.append("]").toString();
		}

		if ("dispBoardReassign".equalsIgnoreCase(requestType)) {
			String recordID = requestMap.get("recordID") == null ? ""
					: requestMap.get("recordID").trim();
			String toUser = requestMap.get("assignedTo") == null ? ""
					: requestMap.get("assignedTo").trim().replace("''", "'");
			String note = requestMap.get("note") == null ? ""
					: requestMap.get("note").trim().replace("''", "'");
			if (!recordID.matches("\\d+") || toUser.length() == 0)
				return "<status>false</status><mesg>Pick a dispatcher</mesg>";
			String fromUser = getTableColumnData("ASSIGNED_TO", "da_tasks",
					"DA_TASKSID", recordID);
			if (fromUser.length() == 0)
				return "<status>false</status><mesg>Task not found</mesg>";
			if (fromUser.equalsIgnoreCase(toUser))
				return "<status>false</status><mesg>Already assigned to that dispatcher</mesg>";
			if (!isLead(loginUserRoles) && !fromUser.equalsIgnoreCase(loginUser))
				return "<status>false</status><mesg>Only the current owner or a lead "
						+ "can hand off this task</mesg>";
			String handoff = "\n[" + loginUser + "] HANDOFF " + fromUser + " → " + toUser;
			if (note.length() > 0) handoff += " — " + note;
			List<String> upList = new ArrayList<String>();
			upList.add("UPDATE da_tasks SET ASSIGNED_TO=" + db.getInsertDBValue(toUser)
					+ ", TASKDESC=CONCAT(IFNULL(TASKDESC,''), "
					+ db.getInsertDBValue(handoff) + "), "
					+ "UPDATE_USER=" + db.getInsertDBValue(loginUser)
					+ ", UPDATE_DATE=" + db.getInsertSysdate()
					+ " WHERE DA_TASKSID=" + recordID + " AND STATUS!="
					+ RecordStatus.DELETE);
			boolean result = db.batchInsert(upList);
			if (!result)
				return "<status>false</status><mesg>Hand off failed</mesg>";
			return "<status>true</status><mesg>Handed off to " + toUser + "</mesg>";
		}

		if (!"taskState".equalsIgnoreCase(requestType)) return "";
		String recordID = requestMap.get("recordID") == null ? "" : requestMap.get("recordID").trim();
		String to = requestMap.get("to") == null ? "" : requestMap.get("to").trim();
		if (!recordID.matches("\\d+") || !to.matches("[012]"))
			return "<status>false</status><mesg>Bad request</mesg>";

		if (!isLead(loginUserRoles)) {
			String owner = getTableColumnData("ASSIGNED_TO", "da_tasks", "DA_TASKSID", recordID);
			if (!owner.equalsIgnoreCase(loginUser))
				return "<status>false</status><mesg>Only the assigned dispatcher "
						+ "or a lead can update this task</mesg>";
		}

		List<String> upList = new ArrayList<String>();
		upList.add("UPDATE da_tasks SET TASKSTATUS=" + to
				+ ", COMPLETED_DATE=" + ("2".equals(to) ? db.getInsertSysdate() : "NULL")
				+ ", UPDATE_USER=" + db.getInsertDBValue(loginUser)
				+ ", UPDATE_DATE=" + db.getInsertSysdate()
				+ " WHERE DA_TASKSID=" + recordID + " AND STATUS!=" + RecordStatus.DELETE);
		boolean result = db.batchInsert(upList);
		String verb = "2".equals(to) ? "completed" : ("1".equals(to) ? "moved to pending" : "reopened");
		return "<status>" + result + "</status><mesg>Task " + verb + "</mesg>";
	}

	private String cleanTopic(String s) {
		if (s == null) return "";
		StringBuilder b = new StringBuilder();
		for (int i = 0; i < s.length(); i++) {
			char c = s.charAt(i);
			if ((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z')
					|| (c >= '0' && c <= '9') || c == ' ' || c == '-' || c == '/')
				b.append(c);
		}
		return b.toString().trim().replaceAll(" +", " ");
	}

	private String jsEsc(String s) {
		if (s == null) return "";
		StringBuilder b = new StringBuilder();
		for (int i = 0; i < s.length(); i++) {
			char c = s.charAt(i);
			if (c == '"') b.append("\\\"");
			else if (c == '\\') b.append("\\\\");
			else if (c == '\n' || c == '\r') b.append(' ');
			else if (c == '<') b.append("\\u003C");
			else if (c >= 32) b.append(c);
		}
		return b.toString();
	}
}
