package com.tools;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.HashMap;
import java.util.Map;

import javax.naming.InitialContext;
import javax.sql.DataSource;

/**
 * Emily Phase 0 - console feed, dispatcher actions, and the call simulator.
 * The simulator drives the SAME EmilyService methods a live voice call will
 * use in Phase 1, so every scenario run here is a true regression test.
 */
public class EmilyConsoleService {

	private final EmilyService svc = new EmilyService();

	private Connection getConn() throws Exception {
		InitialContext ctx = new InitialContext();
		DataSource ds = (DataSource) ctx.lookup("java:comp/env/jdbc/MVPGDB");
		return ds.getConnection();
	}

	private static String js(String s) {
		return EmilyService.js(s);
	}

	/* ── one JSON for the whole console page ── */
	public String consoleData() throws Exception {
		StringBuilder o = new StringBuilder("{");
		Connection c = getConn();
		try {
			/* KPIs exclude simulated calls once real ones exist; in Phase 0
			   (simulator only) they fall back to simulated so the page is alive */
			PreparedStatement ps = c.prepareStatement(
					"SELECT COUNT(*) FROM emily_calls WHERE STATUS!=1 AND SIMULATED=0");
			ResultSet rs = ps.executeQuery();
			boolean hasReal = rs.next() && rs.getInt(1) > 0;
			rs.close();
			ps.close();
			String simCond = hasReal ? " AND SIMULATED=0 " : " ";

			ps = c.prepareStatement(
					"SELECT COUNT(*), SUM(OUTCOME='resolved'), SUM(OUTCOME='escalated'), "
					+ "SUM(OUTCOME='callback'), IFNULL(AVG(DURATION_SEC),0) "
					+ "FROM emily_calls WHERE STATUS!=1 AND OUTCOME IS NOT NULL" + simCond);
			rs = ps.executeQuery();
			int total = 0, resolved = 0, escalated = 0, callback = 0, avgSec = 0;
			if (rs.next()) {
				total = rs.getInt(1);
				resolved = rs.getInt(2);
				escalated = rs.getInt(3);
				callback = rs.getInt(4);
				avgSec = rs.getInt(5);
			}
			rs.close();
			ps.close();

			ps = c.prepareStatement("SELECT COUNT(*), SUM(QA_STATUS='fail') FROM emily_calls "
					+ "WHERE STATUS!=1 AND QA_STATUS IS NOT NULL");
			rs = ps.executeQuery();
			int qaN = 0, qaFail = 0;
			if (rs.next()) {
				qaN = rs.getInt(1);
				qaFail = rs.getInt(2);
			}
			rs.close();
			ps.close();

			o.append("\"simMode\":").append(hasReal ? "false" : "true");
			o.append(",\"kpis\":{\"calls\":").append(total)
					.append(",\"containment\":").append(total > 0 ? Math.round(100.0 * resolved / total) : 0)
					.append(",\"escalated\":").append(escalated)
					.append(",\"callback\":").append(callback)
					.append(",\"avgSec\":").append(avgSec)
					.append(",\"qaChecked\":").append(qaN)
					.append(",\"qaErrPct\":").append(qaN > 0 ? Math.round(100.0 * qaFail / qaN) : 0)
					.append("}");

			/* live board: open escalations + proposed rescues */
			o.append(",\"escalations\":[");
			ps = c.prepareStatement(
					"SELECT E.ESCID, E.CALLID, E.PRIORITY, E.REASON, E.RESOLUTION_STATUS, "
					+ "DATE_FORMAT(E.CREATE_DATE,'%m/%d %h:%i %p'), IFNULL(EM.FULLNAME, CONCAT('caller ', IFNULL(C.PHONE,'?'))) "
					+ "FROM emily_escalations E LEFT JOIN emily_calls C ON C.CALLID=E.CALLID "
					+ "LEFT JOIN employee EM ON EM.EMPLOYEEID=C.EMPLOYEEID "
					+ "WHERE E.STATUS!=1 AND E.RESOLUTION_STATUS='open' ORDER BY E.ESCID DESC LIMIT 30");
			rs = ps.executeQuery();
			int n = 0;
			while (rs.next()) {
				if (n++ > 0)
					o.append(',');
				o.append("{\"id\":").append(rs.getInt(1))
						.append(",\"callId\":").append(rs.getInt(2))
						.append(",\"priority\":").append(js(rs.getString(3)))
						.append(",\"reason\":").append(js(rs.getString(4)))
						.append(",\"when\":").append(js(rs.getString(6)))
						.append(",\"who\":").append(js(rs.getString(7))).append("}");
			}
			rs.close();
			ps.close();
			o.append(']');

			o.append(",\"rescues\":[");
			ps = c.prepareStatement(
					"SELECT R.RESCUEID, R.RESCUE_STATUS, R.SCORE, R.PACE_GAP, "
					+ "IFNULL(H.FULLNAME,''), IFNULL(T.FULLNAME,''), R.HELPER_ROUTE, R.TARGET_ROUTE, "
					+ "DATE_FORMAT(R.CREATE_DATE,'%m/%d %h:%i %p') "
					+ "FROM rescue_assignment R LEFT JOIN employee H ON H.EMPLOYEEID=R.HELPER_EMPLOYEEID "
					+ "LEFT JOIN employee T ON T.EMPLOYEEID=R.TARGET_EMPLOYEEID "
					+ "WHERE R.STATUS!=1 AND R.RESCUE_STATUS IN ('proposed','approved') "
					+ "ORDER BY R.RESCUEID DESC LIMIT 30");
			rs = ps.executeQuery();
			n = 0;
			while (rs.next()) {
				if (n++ > 0)
					o.append(',');
				o.append("{\"id\":").append(rs.getInt(1))
						.append(",\"status\":").append(js(rs.getString(2)))
						.append(",\"score\":").append(rs.getDouble(3))
						.append(",\"gap\":").append(rs.getInt(4))
						.append(",\"helper\":").append(js(rs.getString(5)))
						.append(",\"target\":").append(js(rs.getString(6)))
						.append(",\"helperRoute\":").append(js(rs.getString(7)))
						.append(",\"targetRoute\":").append(js(rs.getString(8)))
						.append(",\"when\":").append(js(rs.getString(9))).append("}");
			}
			rs.close();
			ps.close();
			o.append(']');

			/* call log (latest 100) + QA queue flag */
			o.append(",\"calls\":[");
			ps = c.prepareStatement(
					"SELECT C.CALLID, DATE_FORMAT(C.START_TIME,'%m/%d %h:%i %p'), "
					+ "IFNULL(E.FULLNAME, C.PHONE), IFNULL(C.INTENT,''), IFNULL(C.OUTCOME,'open'), "
					+ "IFNULL(C.DURATION_SEC,0), C.SIMULATED, IFNULL(C.QA_STATUS,''), "
					+ "IFNULL(C.TRANSCRIPT,''), IFNULL(C.CONFIDENCE,0) "
					+ "FROM emily_calls C LEFT JOIN employee E ON E.EMPLOYEEID=C.EMPLOYEEID "
					+ "WHERE C.STATUS!=1 ORDER BY C.CALLID DESC LIMIT 100");
			rs = ps.executeQuery();
			n = 0;
			while (rs.next()) {
				if (n++ > 0)
					o.append(',');
				String tr = rs.getString(9);
				if (tr != null && tr.length() > 400)
					tr = tr.substring(0, 400) + "…";
				o.append("{\"id\":").append(rs.getInt(1))
						.append(",\"when\":").append(js(rs.getString(2)))
						.append(",\"who\":").append(js(rs.getString(3)))
						.append(",\"intent\":").append(js(rs.getString(4)))
						.append(",\"outcome\":").append(js(rs.getString(5)))
						.append(",\"sec\":").append(rs.getInt(6))
						.append(",\"sim\":").append(rs.getInt(7))
						.append(",\"qa\":").append(js(rs.getString(8)))
						.append(",\"transcript\":").append(js(tr))
						.append(",\"conf\":").append(rs.getBigDecimal(10)).append("}");
			}
			rs.close();
			ps.close();
			o.append(']');

			/* recent decision trail for the drill-down drawer */
			o.append(",\"events\":[");
			ps = c.prepareStatement(
					"SELECT EVENTID, CALLID, TOOL, IFNULL(RULE_ID,''), IFNULL(DECISION,''), "
					+ "DATE_FORMAT(CREATE_DATE,'%h:%i:%s %p'), IFNULL(RESULT_JSON,'') "
					+ "FROM emily_events WHERE STATUS!=1 ORDER BY EVENTID DESC LIMIT 200");
			rs = ps.executeQuery();
			n = 0;
			while (rs.next()) {
				if (n++ > 0)
					o.append(',');
				String rj = rs.getString(7);
				if (rj != null && rj.length() > 300)
					rj = rj.substring(0, 300) + "…";
				o.append("{\"id\":").append(rs.getInt(1))
						.append(",\"callId\":").append(rs.getInt(2))
						.append(",\"tool\":").append(js(rs.getString(3)))
						.append(",\"rule\":").append(js(rs.getString(4)))
						.append(",\"decision\":").append(js(rs.getString(5)))
						.append(",\"when\":").append(js(rs.getString(6)))
						.append(",\"result\":").append(js(rj)).append("}");
			}
			rs.close();
			ps.close();
			o.append(']');

			/* config (shared key masked - visible only via DB) */
			o.append(",\"config\":[");
			ps = c.prepareStatement(
					"SELECT NAME, IF(NAME='SHARED_KEY','********',VAL), IFNULL(DESCRIPTION,''), "
					+ "IFNULL(UPDATE_USER,''), IFNULL(DATE_FORMAT(UPDATE_DATE,'%m/%d %h:%i %p'),'') "
					+ "FROM emily_config ORDER BY NAME");
			rs = ps.executeQuery();
			n = 0;
			while (rs.next()) {
				if (n++ > 0)
					o.append(',');
				o.append("{\"name\":").append(js(rs.getString(1)))
						.append(",\"val\":").append(js(rs.getString(2)))
						.append(",\"desc\":").append(js(rs.getString(3)))
						.append(",\"by\":").append(js(rs.getString(4)))
						.append(",\"at\":").append(js(rs.getString(5))).append("}");
			}
			rs.close();
			ps.close();
			o.append(']');
		} finally {
			c.close();
		}
		return o.append('}').toString();
	}

	/* ── dispatcher actions from the console ── */
	public String consoleAction(String action, Map<String, String> p, String user)
			throws Exception {
		Connection c = getConn();
		try {
			if ("approve-rescue".equals(action) || "deny-rescue".equals(action)) {
				boolean ok = "approve-rescue".equals(action);
				PreparedStatement ps = c.prepareStatement(
						"UPDATE rescue_assignment SET RESCUE_STATUS=?, ACCEPTED=?, "
						+ (ok ? "ASSIGNED_AT=NOW(), " : "")
						+ "CREATE_USER=CREATE_USER WHERE RESCUEID=? AND RESCUE_STATUS='proposed'");
				ps.setString(1, ok ? "approved" : "denied");
				ps.setInt(2, ok ? 1 : 0);
				ps.setInt(3, Integer.parseInt(p.get("id")));
				int upd = ps.executeUpdate();
				ps.close();
				svc.logEvent(0, "console", ok ? "RSC-APPROVE" : "RSC-DENY",
						ok ? "ALLOW" : "DENY", "{\"rescueId\":" + p.get("id") + "}",
						"{\"by\":" + js(user) + "}");
				return "{\"ok\":" + (upd > 0) + "}";

			} else if ("esc-handled".equals(action)) {
				PreparedStatement ps = c.prepareStatement(
						"UPDATE emily_escalations SET RESOLUTION_STATUS='handled' WHERE ESCID=?");
				ps.setInt(1, Integer.parseInt(p.get("id")));
				int upd = ps.executeUpdate();
				ps.close();
				svc.logEvent(0, "console", "ESC-HANDLED", "ALLOW",
						"{\"escId\":" + p.get("id") + "}", "{\"by\":" + js(user) + "}");
				return "{\"ok\":" + (upd > 0) + "}";

			} else if ("qa-mark".equals(action)) {
				PreparedStatement ps = c.prepareStatement(
						"UPDATE emily_calls SET QA_STATUS=?, QA_CATEGORY=?, QA_NOTE=?, "
						+ "QA_USER=?, QA_DATE=NOW() WHERE CALLID=?");
				ps.setString(1, p.get("qa"));
				ps.setString(2, p.get("category") == null ? "" : p.get("category"));
				ps.setString(3, p.get("note") == null ? "" : p.get("note"));
				ps.setString(4, user);
				ps.setInt(5, Integer.parseInt(p.get("id")));
				int upd = ps.executeUpdate();
				ps.close();
				return "{\"ok\":" + (upd > 0) + "}";

			} else if ("config-set".equals(action)) {
				String name = p.get("name");
				if (name == null || "SHARED_KEY".equals(name))
					return "{\"ok\":false,\"err\":\"not editable here\"}";
				PreparedStatement ps = c.prepareStatement(
						"UPDATE emily_config SET VAL=?, UPDATE_USER=?, UPDATE_DATE=NOW() WHERE NAME=?");
				ps.setString(1, p.get("val"));
				ps.setString(2, user);
				ps.setString(3, name);
				int upd = ps.executeUpdate();
				ps.close();
				/* audited: config changes land in the same immutable event log */
				svc.logEvent(0, "config", "CFG-SET", "ALLOW",
						"{\"name\":" + js(name) + "}",
						"{\"val\":" + js(p.get("val")) + ",\"by\":" + js(user) + "}");
				return "{\"ok\":" + (upd > 0) + "}";
			}
			return "{\"ok\":false,\"err\":\"unknown action\"}";
		} finally {
			c.close();
		}
	}

	/* ── the simulator: same pipeline a live call will take ── */
	public String simulate(String phone, String utterance, String ovAge,
			String ovStops, String user) throws Exception {

		StringBuilder steps = new StringBuilder("[");
		Map<String, String> ctx = svc.contextMap(phone);
		boolean match = "true".equals(ctx.get("match"));
		Integer empId = match ? Integer.valueOf(ctx.get("employeeId")) : null;

		int callId = svc.openCall("sim-" + System.currentTimeMillis(), empId,
				phone, 1, user);

		String ctxJson = svc.context(phone);
		steps.append("{\"step\":\"context\",\"result\":").append(ctxJson).append("}");
		svc.logEvent(callId, "context", match ? "CTX-01" : "UNK-01",
				match ? "ALLOW" : "DENY", "{\"phone\":" + js(phone) + "}", ctxJson);

		String intent = detectIntent(utterance);
		steps.append(",{\"step\":\"intent\",\"result\":{\"intent\":")
				.append(js(intent)).append("}}");

		String outcome;
		String toolJson = "";
		if (!match) {
			toolJson = svc.escalate(callId, "P2", "unverified caller");
			svc.logEvent(callId, "escalate", "UNK-01", "ESCALATE",
					"{\"reason\":\"unverified\"}", toolJson);
			steps.append(",{\"step\":\"escalate\",\"result\":").append(toolJson).append("}");
			outcome = "escalated";

		} else if ("emergency".equals(intent)) {
			/* EMR-01: never automated, always a warm P1 transfer */
			toolJson = svc.escalate(callId, "P1", "emergency keywords in utterance");
			svc.logEvent(callId, "escalate", "EMR-01", "ESCALATE",
					"{\"utterance\":" + js(utterance) + "}", toolJson);
			steps.append(",{\"step\":\"escalate\",\"result\":").append(toolJson).append("}");
			outcome = "escalated";

		} else if ("rts".equals(intent)) {
			Integer age = ovAge != null && ovAge.length() > 0 ? Integer.valueOf(ovAge) : null;
			Integer done = ovStops != null && ovStops.length() > 0 ? Integer.valueOf(ovStops) : null;
			toolJson = svc.rtsCheck(empId.intValue(), age, done);
			String rule = pick(toolJson, "rule");
			String decision = pick(toolJson, "decision");
			svc.logEvent(callId, "rts-check", rule, decision,
					"{\"employeeId\":" + empId + ",\"ovAge\":" + age + ",\"ovStops\":" + done + "}",
					toolJson);
			steps.append(",{\"step\":\"rts-check\",\"result\":").append(toolJson).append("}");
			outcome = "ALLOW".equals(decision) ? "resolved" : "escalated";
			if ("CLARIFY".equals(decision))
				outcome = "callback";

		} else if ("package".equals(intent)) {
			int count = countIn(utterance);
			toolJson = svc.logException(empId.intValue(), categoryIn(utterance),
					count, utterance.toLowerCase().indexOf("van") >= 0 ? "Y" : "N",
					"attempted", utterance, callId, user);
			String rule = pick(toolJson, "rule");
			svc.logEvent(callId, "log-exception", rule, pick(toolJson, "decision"),
					"{\"utterance\":" + js(utterance) + "}", toolJson);
			steps.append(",{\"step\":\"log-exception\",\"result\":").append(toolJson).append("}");
			outcome = "PKG-01".equals(rule) ? "resolved" : "callback";

		} else if ("rescue".equals(intent)) {
			toolJson = svc.rescueCandidates(empId.intValue());
			String rule = pick(toolJson, "rule");
			String decision = pick(toolJson, "decision");
			svc.logEvent(callId, "rescue-candidates", rule, decision,
					"{\"employeeId\":" + empId + "}", toolJson);
			steps.append(",{\"step\":\"rescue-candidates\",\"result\":").append(toolJson).append("}");
			if ("RECOMMEND".equals(decision)) {
				/* propose the top candidate; dispatcher approves in the console */
				int hId = parse(pick(toolJson, "helperId"), 0);
				String hRoute = pick(toolJson, "route");
				int gap = parse(pick(toolJson, "paceGap"), 0);
				double score = 0;
				try {
					score = Double.parseDouble(pick(toolJson, "score"));
				} catch (Exception e) {
				}
				int rescueId = svc.proposeRescue(callId, hId, empId.intValue(),
						hRoute, ctx.get("route") == null ? "" : ctx.get("route"),
						score, gap, user);
				steps.append(",{\"step\":\"propose-rescue\",\"result\":{\"rescueId\":")
						.append(rescueId).append(",\"status\":\"proposed\"}}");
				svc.logEvent(callId, "propose-rescue", "RSC-03", "PROPOSE",
						"{\"helperId\":" + hId + "}", "{\"rescueId\":" + rescueId + "}");
				outcome = "resolved";
			} else {
				outcome = "RSC-02-NOGAP".equals(rule) ? "resolved" : "escalated";
			}

		} else if ("device".equals(intent)) {
			boolean blocked = utterance.toLowerCase().indexOf("can't deliver") >= 0
					|| utterance.toLowerCase().indexOf("cannot deliver") >= 0
					|| utterance.toLowerCase().indexOf("dead") >= 0;
			if (blocked) {
				toolJson = svc.escalate(callId, "P2", "device failure blocking deliveries");
				svc.logEvent(callId, "escalate", "DEV-02", "ESCALATE",
						"{\"utterance\":" + js(utterance) + "}", toolJson);
				steps.append(",{\"step\":\"escalate\",\"result\":").append(toolJson).append("}");
				outcome = "escalated";
			} else {
				toolJson = "{\"rule\":\"DEV-01\",\"say\":\"Try these in order: restart the Flex app, "
						+ "toggle airplane mode for ten seconds, then restart the phone. "
						+ "Call back if it's still stuck and I'll get dispatch.\"}";
				svc.logEvent(callId, "device-steps", "DEV-01", "ALLOW",
						"{\"utterance\":" + js(utterance) + "}", toolJson);
				steps.append(",{\"step\":\"device-steps\",\"result\":").append(toolJson).append("}");
				outcome = "resolved";
			}

		} else if ("callout".equals(intent)) {
			toolJson = svc.logException(empId.intValue(), "callout-or-late", 1, "N",
					"", utterance, callId, user);
			svc.logEvent(callId, "log-exception", "ATT-01", "ALLOW",
					"{\"utterance\":" + js(utterance) + "}", toolJson);
			steps.append(",{\"step\":\"log-exception\",\"result\":").append(toolJson).append("}");
			outcome = "resolved";

		} else {
			toolJson = svc.escalate(callId, "P2", "intent not recognized");
			svc.logEvent(callId, "escalate", "UNK-02", "ESCALATE",
					"{\"utterance\":" + js(utterance) + "}", toolJson);
			steps.append(",{\"step\":\"escalate\",\"result\":").append(toolJson).append("}");
			outcome = "callback";
		}

		svc.completeCall(callId, intent, outcome, "0.95",
				30 + utterance.length() / 4, "[SIM] " + utterance, "");
		steps.append(']');
		return "{\"callId\":" + callId + ",\"intent\":" + js(intent)
				+ ",\"outcome\":" + js(outcome) + ",\"steps\":" + steps + "}";
	}

	/* keyword intent detection - the Phase 0 stand-in for the vendor NLU.
	   Order matters: emergency wins over everything. */
	public static String detectIntent(String u) {
		String s = u == null ? "" : u.toLowerCase();
		if (has(s, "accident", "emergency", "hurt", "injured", "injury", "fire",
				"robbed", "robbery", "crash", "911", "dog bit", "bleeding"))
			return "emergency";
		if (has(s, "rescue", "behind", "too many stops", "need help", "help me with stops",
				"someone take stops"))
			return "rescue";
		if (has(s, "done", "finished", "complete", "rts", "head back",
				"return to station", "come back", "coming back"))
			return "rts";
		if (has(s, "damaged", "damage", "missort", "broken", "leaking",
				"wrong package", "extra package", "missing package"))
			return "package";
		if (has(s, "phone", "cable", "flex", "app ", "device", "charger", "dead", "frozen"))
			return "device";
		if (has(s, "call out", "calling out", "sick", "running late", "late tomorrow",
				"can't come", "cannot come"))
			return "callout";
		return "unknown";
	}

	private static boolean has(String s, String... keys) {
		for (int i = 0; i < keys.length; i++)
			if (s.indexOf(keys[i]) >= 0)
				return true;
		return false;
	}

	private static int countIn(String u) {
		java.util.regex.Matcher m = java.util.regex.Pattern.compile("(\\d{1,3})")
				.matcher(u == null ? "" : u);
		return m.find() ? Integer.parseInt(m.group(1)) : 1;
	}

	private static String categoryIn(String u) {
		String s = u == null ? "" : u.toLowerCase();
		if (s.indexOf("missort") >= 0)
			return "missort";
		if (s.indexOf("leak") >= 0)
			return "leaking";
		if (s.indexOf("missing") >= 0)
			return "missing";
		return "damaged";
	}

	/* first occurrence of "key":"value" or "key":number in a JSON string we
	   built ourselves - not a general parser, just enough for chaining */
	private static String pick(String json, String key) {
		java.util.regex.Matcher m = java.util.regex.Pattern
				.compile("\"" + key + "\"\\s*:\\s*\"?([^\",}\\]]*)").matcher(json);
		return m.find() ? m.group(1) : "";
	}

	private static int parse(String s, int def) {
		try {
			return Integer.parseInt(s.trim());
		} catch (Exception e) {
			return def;
		}
	}
}
