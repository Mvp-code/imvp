package com.tools;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.naming.InitialContext;
import javax.sql.DataSource;

/**
 * Emily Phase 0 - deterministic policy engine + data access.
 * The LLM (Phase 1 voice vendor) speaks; THIS class decides. Every decision
 * returns an explicit rule id (RTS-01, EMR-01, ...) and is written to
 * emily_events so any automated action is explainable after the fact.
 * All SQL uses PreparedStatement (same JNDI pattern as DAOnboarding.jsp).
 */
public class EmilyService {

	/* config cache: emily_config is tiny; re-read at most once a minute */
	private static Map<String, String> cfgCache = null;
	private static long cfgLoadedAt = 0;

	private Connection getConn() throws Exception {
		InitialContext ctx = new InitialContext();
		DataSource ds = (DataSource) ctx.lookup("java:comp/env/jdbc/MVPGDB");
		return ds.getConnection();
	}

	public synchronized String cfg(String name) {
		try {
			if (cfgCache == null || System.currentTimeMillis() - cfgLoadedAt > 60000) {
				Map<String, String> m = new HashMap<String, String>();
				Connection c = getConn();
				try {
					PreparedStatement ps = c.prepareStatement(
							"SELECT NAME, VAL FROM emily_config");
					ResultSet rs = ps.executeQuery();
					while (rs.next())
						m.put(rs.getString(1), rs.getString(2));
					rs.close();
					ps.close();
				} finally {
					c.close();
				}
				cfgCache = m;
				cfgLoadedAt = System.currentTimeMillis();
			}
		} catch (Exception ex) {
			ex.printStackTrace();
			if (cfgCache == null)
				cfgCache = new HashMap<String, String>();
		}
		String v = cfgCache.get(name);
		return v == null ? "" : v;
	}

	private int cfgInt(String name, int def) {
		try {
			return Integer.parseInt(cfg(name).trim());
		} catch (Exception e) {
			return def;
		}
	}

	/* ── JSON helpers (strings out only; inputs arrive as request params) ── */
	public static String js(String s) {
		if (s == null)
			return "\"\"";
		StringBuilder b = new StringBuilder("\"");
		for (int i = 0; i < s.length(); i++) {
			char ch = s.charAt(i);
			if (ch == '"' || ch == '\\')
				b.append('\\').append(ch);
			else if (ch == '\n')
				b.append("\\n");
			else if (ch == '\r')
				b.append("\\r");
			else if (ch == '\t')
				b.append("\\t");
			else if (ch < 0x20)
				b.append(String.format("\\u%04x", (int) ch));
			else
				b.append(ch);
		}
		return b.append('"').toString();
	}

	private static String digits(String phone) {
		if (phone == null)
			return "";
		String d = phone.replaceAll("[^0-9]", "");
		return d.length() > 10 ? d.substring(d.length() - 10) : d;
	}

	/* ── event log: the audit trail behind every decision ── */
	public void logEvent(int callId, String tool, String ruleId,
			String decision, String reqJson, String resJson) {
		try {
			Connection c = getConn();
			try {
				PreparedStatement ps = c.prepareStatement(
						"INSERT INTO emily_events (ENTITYID, CALLID, TOOL, RULE_ID, "
						+ "DECISION, REQUEST_JSON, RESULT_JSON, CREATE_DATE) "
						+ "VALUES (1, ?, ?, ?, ?, ?, ?, NOW())");
				ps.setInt(1, callId);
				ps.setString(2, tool);
				ps.setString(3, ruleId);
				ps.setString(4, decision);
				ps.setString(5, reqJson);
				ps.setString(6, resJson);
				ps.executeUpdate();
				ps.close();
			} finally {
				c.close();
			}
		} catch (Exception ex) {
			ex.printStackTrace();
		}
	}

	/* ── the reference date for route/itinerary lookups.
	   Production: today. Phase 0 with SIM_DATA_DATE=LATEST: newest date on
	   file, so the simulator exercises real rows even when today is empty. ── */
	private String dataDate(Connection c) throws Exception {
		if (!"LATEST".equalsIgnoreCase(cfg("SIM_DATA_DATE")))
			return "CURDATE()";
		PreparedStatement ps = c.prepareStatement(
				"SELECT DATE_FORMAT(MAX(ASSIGN_DATE),'%Y-%m-%d') FROM route_assignment WHERE STATUS!=1");
		ResultSet rs = ps.executeQuery();
		String d = rs.next() ? rs.getString(1) : null;
		rs.close();
		ps.close();
		return d == null ? "CURDATE()" : "'" + d + "'"; // yyyy-MM-dd from DB, not user input
	}

	/* ── /context : caller-id -> who is this, what are they doing today ── */
	public Map<String, String> contextMap(String phone) throws Exception {
		Map<String, String> m = new HashMap<String, String>();
		m.put("match", "false");
		String d = digits(phone);
		if (d.length() < 7)
			return m;
		Connection c = getConn();
		try {
			PreparedStatement ps = c.prepareStatement(
					"SELECT E.EMPLOYEEID, E.FULLNAME, IFNULL(E.TRANSPORTERID,''), "
					+ "IFNULL(E.PREFERRED_LANGUAGE,''), IFNULL(E.STATION,'') "
					+ "FROM employee E JOIN contact C ON E.CONTACTID=C.CONTACTID "
					+ "WHERE E.STATUS=0 AND REPLACE(REPLACE(REPLACE(REPLACE(IFNULL(C.MOBILE,''),'-',''),' ',''),'(',''),')','') LIKE ? "
					+ "ORDER BY E.EMPLOYEEID LIMIT 1");
			ps.setString(1, "%" + d);
			ResultSet rs = ps.executeQuery();
			if (rs.next()) {
				m.put("match", "true");
				m.put("employeeId", rs.getString(1));
				m.put("name", rs.getString(2));
				m.put("transporterId", rs.getString(3));
				m.put("language", rs.getString(4));
				m.put("station", rs.getString(5));
			}
			rs.close();
			ps.close();
			if (!"true".equals(m.get("match")))
				return m;

			String dd = dataDate(c);
			ps = c.prepareStatement(
					"SELECT IFNULL(ROUTE,''), IFNULL(STAGING,''), IFNULL(DATE_FORMAT(WAVE_TIME,'%h:%i %p'),'') "
					+ "FROM route_assignment WHERE STATUS!=1 AND DATE(ASSIGN_DATE)=" + dd
					+ " AND (EMPLOYEEID=? OR (TRANSPORTERID<>'' AND TRANSPORTERID=?)) LIMIT 1");
			ps.setInt(1, Integer.parseInt(m.get("employeeId")));
			ps.setString(2, m.get("transporterId"));
			rs = ps.executeQuery();
			if (rs.next()) {
				m.put("route", rs.getString(1));
				m.put("staging", rs.getString(2));
				m.put("waveTime", rs.getString(3));
			}
			rs.close();
			ps.close();

			ps = c.prepareStatement(
					"SELECT IFNULL(ALLSTOPS,0), IFNULL(COMPLETEDSTOPS,0), "
					+ "TIMESTAMPDIFF(MINUTE, COALESCE(UPDATE_DATE, CREATE_DATE), NOW()) "
					+ "FROM daily_itineraries WHERE STATUS!=1 AND DATE(ITINARARYDATE)=" + dd
					+ " AND TRANSPORTERID=? ORDER BY DAILY_ITINERARIESID DESC LIMIT 1");
			ps.setString(1, m.get("transporterId"));
			rs = ps.executeQuery();
			if (rs.next()) {
				m.put("stopsAll", rs.getString(1));
				m.put("stopsDone", rs.getString(2));
				m.put("ageMin", rs.getString(3));
			}
			rs.close();
			ps.close();

			ps = c.prepareStatement(
					"SELECT DATE_FORMAT(CLOCKINTIME,'%h:%i %p') FROM dacheckin "
					+ "WHERE STATUS!=1 AND EMPLOYEEID=? AND DATE(CLOCKINTIME)=" + dd + " LIMIT 1");
			ps.setInt(1, Integer.parseInt(m.get("employeeId")));
			rs = ps.executeQuery();
			if (rs.next())
				m.put("checkin", rs.getString(1));
			rs.close();
			ps.close();
		} finally {
			c.close();
		}
		return m;
	}

	public String context(String phone) throws Exception {
		Map<String, String> m = contextMap(phone);
		String res;
		if (!"true".equals(m.get("match"))) {
			/* UNK-01: never discuss route data with an unverified caller */
			res = "{\"match\":false,\"rule\":\"UNK-01\",\"say\":\"I don't recognize this number. "
					+ "I can connect you to a dispatcher - say dispatcher or press 0.\"}";
		} else {
			res = "{\"match\":true,\"employeeId\":" + m.get("employeeId")
					+ ",\"name\":" + js(m.get("name"))
					+ ",\"route\":" + js(m.get("route"))
					+ ",\"staging\":" + js(m.get("staging"))
					+ ",\"waveTime\":" + js(m.get("waveTime"))
					+ ",\"checkin\":" + js(m.get("checkin"))
					+ ",\"language\":" + js(m.get("language"))
					+ ",\"stops\":" + js(m.get("stopsDone") == null ? ""
							: m.get("stopsDone") + "/" + m.get("stopsAll"))
					+ ",\"paceAgeMin\":" + (m.get("ageMin") == null ? "null" : m.get("ageMin"))
					+ "}";
		}
		return res;
	}

	/* ── /rts-check : RTS-01 / RTS-02-STALE / RTS-03-SHORT ── */
	public String rtsCheck(int employeeId, Integer ovAgeMin, Integer ovStopsDone)
			throws Exception {
		Map<String, String> m = ctxByEmployee(employeeId);
		int all = parse(m.get("stopsAll"), 0);
		int done = ovStopsDone != null ? ovStopsDone.intValue() : parse(m.get("stopsDone"), -1);
		int age = ovAgeMin != null ? ovAgeMin.intValue() : parse(m.get("ageMin"), 99999);
		int maxAge = cfgInt("MAX_DATA_AGE_MIN", 15);
		int minPct = cfgInt("RTS_MIN_PCT", 100);

		String rule, decision, say;
		if (all <= 0 || done < 0) {
			rule = "RTS-02-STALE";
			decision = "DENY";
			say = "I don't have route data for you right now, so let me have dispatch confirm before you head back.";
		} else if (age > maxAge) {
			rule = "RTS-02-STALE";
			decision = "DENY";
			say = "My route data is " + age + " minutes old, so let me have dispatch confirm before you head back.";
		} else if (done * 100 < all * minPct) {
			rule = "RTS-03-SHORT";
			decision = "CLARIFY";
			say = "I show " + done + " of " + all + " stops complete. Are the remaining stops attempted or being returned?";
		} else if (hasOpenRescueAsHelper(employeeId)) {
			rule = "RTS-04-HELPER";
			decision = "DENY";
			say = "You're assigned as a rescue helper right now, so please check with dispatch before returning.";
		} else {
			rule = "RTS-01";
			decision = "ALLOW";
			say = "You show " + done + " of " + all + " stops complete and your data is "
					+ age + " minutes old. You're cleared to return to station - logged it.";
		}
		return "{\"decision\":" + js(decision) + ",\"rule\":" + js(rule)
				+ ",\"say\":" + js(say) + ",\"stops\":" + js(done + "/" + all)
				+ ",\"ageMin\":" + age + ",\"autoRts\":" + js(cfg("AUTO_RTS")) + "}";
	}

	private boolean hasOpenRescueAsHelper(int employeeId) throws Exception {
		Connection c = getConn();
		try {
			PreparedStatement ps = c.prepareStatement(
					"SELECT COUNT(*) FROM rescue_assignment WHERE STATUS!=1 "
					+ "AND HELPER_EMPLOYEEID=? AND RESCUE_STATUS IN ('proposed','approved')");
			ps.setInt(1, employeeId);
			ResultSet rs = ps.executeQuery();
			boolean open = rs.next() && rs.getInt(1) > 0;
			rs.close();
			ps.close();
			return open;
		} finally {
			c.close();
		}
	}

	private Map<String, String> ctxByEmployee(int employeeId) throws Exception {
		Map<String, String> m = new HashMap<String, String>();
		Connection c = getConn();
		try {
			PreparedStatement ps = c.prepareStatement(
					"SELECT IFNULL(TRANSPORTERID,''), FULLNAME FROM employee WHERE EMPLOYEEID=?");
			ps.setInt(1, employeeId);
			ResultSet rs = ps.executeQuery();
			if (rs.next()) {
				m.put("transporterId", rs.getString(1));
				m.put("name", rs.getString(2));
			}
			rs.close();
			ps.close();
			String dd = dataDate(c);
			ps = c.prepareStatement(
					"SELECT IFNULL(ALLSTOPS,0), IFNULL(COMPLETEDSTOPS,0), "
					+ "TIMESTAMPDIFF(MINUTE, COALESCE(UPDATE_DATE, CREATE_DATE), NOW()) "
					+ "FROM daily_itineraries WHERE STATUS!=1 AND DATE(ITINARARYDATE)=" + dd
					+ " AND TRANSPORTERID=? ORDER BY DAILY_ITINERARIESID DESC LIMIT 1");
			ps.setString(1, m.get("transporterId") == null ? "" : m.get("transporterId"));
			rs = ps.executeQuery();
			if (rs.next()) {
				m.put("stopsAll", rs.getString(1));
				m.put("stopsDone", rs.getString(2));
				m.put("ageMin", rs.getString(3));
			}
			rs.close();
			ps.close();
		} finally {
			c.close();
		}
		return m;
	}

	/* ── /log-exception : PKG-01 — writes a real incidents row, SOURCE=EMILY ── */
	public String logException(int employeeId, String category, int count,
			String inVan, String attempts, String note, int callId, String user)
			throws Exception {
		int max = cfgInt("PKG_MAX_COUNT", 10);
		if (count < 1 || count > max)
			return "{\"decision\":\"CLARIFY\",\"rule\":\"PKG-02-COUNT\",\"say\":"
					+ js("That's " + count + " packages - for more than " + max
							+ " let me get a dispatcher to help you.") + "}";
		Connection c = getConn();
		int incidentId = 0;
		try {
			PreparedStatement ps = c.prepareStatement(
					"INSERT INTO incidents (ENTITYID, EMPLOYEEID, DESCRIPTION, "
					+ "INCIDENT_DATE, SOURCE, CREATE_USER, CREATE_DATE, STATUS) "
					+ "VALUES (1, ?, ?, NOW(), 'EMILY', ?, NOW(), 0)",
					PreparedStatement.RETURN_GENERATED_KEYS);
			ps.setInt(1, employeeId);
			ps.setString(2, "[EMILY call " + callId + "] package exception: category="
					+ category + " count=" + count + " inVan=" + inVan
					+ " attempts=" + attempts + (note == null || note.length() == 0 ? "" : " note=" + note));
			ps.setString(3, user == null || user.length() == 0 ? "emily" : user);
			ps.executeUpdate();
			ResultSet rs = ps.getGeneratedKeys();
			if (rs.next())
				incidentId = rs.getInt(1);
			rs.close();
			ps.close();
		} finally {
			c.close();
		}
		return "{\"decision\":\"ALLOW\",\"rule\":\"PKG-01\",\"ok\":true,\"incidentId\":" + incidentId
				+ ",\"say\":" + js("Logged " + count + " " + category
						+ (count == 1 ? " package" : " packages")
						+ (("Y".equalsIgnoreCase(inVan)) ? ", still in your van" : "")
						+ ". Dispatch can see it now. Anything else?") + "}";
	}

	/* ── /rescue-candidates : RSC-01..03 — deterministic scoring ── */
	public String rescueCandidates(int targetEmployeeId) throws Exception {
		Map<String, String> t = ctxByEmployee(targetEmployeeId);
		int all = parse(t.get("stopsAll"), 0);
		int done = parse(t.get("stopsDone"), 0);
		int age = parse(t.get("ageMin"), 99999);
		int gap = all - done;
		int minGap = cfgInt("RESCUE_MIN_GAP", 10);
		int maxAge = cfgInt("MAX_DATA_AGE_MIN", 15);

		if (all <= 0 || age > maxAge)
			return "{\"decision\":\"DENY\",\"rule\":\"RSC-01-STALE\",\"say\":"
					+ js("My route data isn't fresh enough to arrange a rescue safely - let me have dispatch look at it.")
					+ ",\"candidates\":[]}";
		if (gap < minGap)
			return "{\"decision\":\"DENY\",\"rule\":\"RSC-02-NOGAP\",\"say\":"
					+ js("You show only " + gap + " stops remaining, which is under the rescue threshold of "
							+ minGap + ". You've got this - call back if it changes.")
					+ ",\"candidates\":[]}";
		if (hasOpenRescueAsTarget(targetEmployeeId))
			return "{\"decision\":\"DENY\",\"rule\":\"RSC-04-DUP\",\"say\":"
					+ js("A rescue is already in motion for your route.") + ",\"candidates\":[]}";

		/* candidates: drivers on file for the same data date who are nearly done.
		   score = 0.4*gapSeverity + 0.3*stagingMatch + 0.3*spareCapacity (docs §5) */
		StringBuilder cand = new StringBuilder("[");
		int n = 0;
		Connection c = getConn();
		try {
			String dd = dataDate(c);
			String targetStaging = stagingFor(c, dd, targetEmployeeId);
			PreparedStatement ps = c.prepareStatement(
					"SELECT RA.EMPLOYEEID, RA.DRIVER_NAME, RA.ROUTE, IFNULL(RA.STAGING,''), "
					+ "DI.ALLSTOPS, DI.COMPLETEDSTOPS "
					+ "FROM route_assignment RA JOIN daily_itineraries DI "
					+ "  ON DI.TRANSPORTERID=RA.TRANSPORTERID AND DATE(DI.ITINARARYDATE)=DATE(RA.ASSIGN_DATE) "
					+ "WHERE RA.STATUS!=1 AND DI.STATUS!=1 AND DATE(RA.ASSIGN_DATE)=" + dd
					+ " AND RA.EMPLOYEEID<>? AND DI.ALLSTOPS>0 "
					+ " AND DI.COMPLETEDSTOPS*100 >= DI.ALLSTOPS*80 "
					+ " AND RA.EMPLOYEEID NOT IN (SELECT HELPER_EMPLOYEEID FROM rescue_assignment "
					+ "     WHERE STATUS!=1 AND RESCUE_STATUS IN ('proposed','approved')) "
					+ "ORDER BY DI.COMPLETEDSTOPS/DI.ALLSTOPS DESC LIMIT 5");
			ps.setInt(1, targetEmployeeId);
			ResultSet rs = ps.executeQuery();
			while (rs.next()) {
				int hAll = rs.getInt(5), hDone = rs.getInt(6);
				double spare = hAll > 0 ? (double) hDone / hAll : 0;
				double gapSev = Math.min(gap / 30.0, 1.0);
				String hStaging = rs.getString(4);
				double stgMatch = (targetStaging.length() > 4 && hStaging.length() > 4
						&& targetStaging.substring(0, 5).equals(hStaging.substring(0, 5))) ? 1.0 : 0.3;
				double score = Math.round((0.4 * gapSev + 0.3 * stgMatch + 0.3 * spare) * 100) / 100.0;
				if (n++ > 0)
					cand.append(',');
				cand.append("{\"helperId\":").append(rs.getInt(1))
						.append(",\"helper\":").append(js(rs.getString(2)))
						.append(",\"route\":").append(js(rs.getString(3)))
						.append(",\"staging\":").append(js(hStaging))
						.append(",\"helperStops\":").append(js(hDone + "/" + hAll))
						.append(",\"score\":").append(score).append("}");
			}
			rs.close();
			ps.close();
		} finally {
			c.close();
		}
		cand.append(']');
		if (n == 0)
			return "{\"decision\":\"ESCALATE\",\"rule\":\"RSC-05-NONE\",\"say\":"
					+ js("Nobody is far enough along to rescue right now - I'm flagging dispatch to work it out.")
					+ ",\"candidates\":[]}";
		return "{\"decision\":\"RECOMMEND\",\"rule\":\"RSC-03\",\"paceGap\":" + gap
				+ ",\"say\":" + js("I found " + n + " possible helper" + (n == 1 ? "" : "s")
						+ " - sending it to dispatch to confirm. You'll get a text when it's assigned.")
				+ ",\"autoRescue\":" + js(cfg("AUTO_RESCUE")) + ",\"candidates\":" + cand + "}";
	}

	private boolean hasOpenRescueAsTarget(int employeeId) throws Exception {
		Connection c = getConn();
		try {
			PreparedStatement ps = c.prepareStatement(
					"SELECT COUNT(*) FROM rescue_assignment WHERE STATUS!=1 "
					+ "AND TARGET_EMPLOYEEID=? AND RESCUE_STATUS IN ('proposed','approved')");
			ps.setInt(1, employeeId);
			ResultSet rs = ps.executeQuery();
			boolean open = rs.next() && rs.getInt(1) > 0;
			rs.close();
			ps.close();
			return open;
		} finally {
			c.close();
		}
	}

	private String stagingFor(Connection c, String dd, int employeeId) throws Exception {
		PreparedStatement ps = c.prepareStatement(
				"SELECT IFNULL(STAGING,'') FROM route_assignment WHERE STATUS!=1 "
				+ "AND DATE(ASSIGN_DATE)=" + dd + " AND EMPLOYEEID=? LIMIT 1");
		ps.setInt(1, employeeId);
		ResultSet rs = ps.executeQuery();
		String s = rs.next() ? rs.getString(1) : "";
		rs.close();
		ps.close();
		return s;
	}

	public int proposeRescue(int callId, int helperId, int targetId,
			String helperRoute, String targetRoute, double score, int paceGap,
			String user) throws Exception {
		Connection c = getConn();
		try {
			PreparedStatement ps = c.prepareStatement(
					"INSERT INTO rescue_assignment (ENTITYID, CALLID, HELPER_EMPLOYEEID, "
					+ "TARGET_EMPLOYEEID, HELPER_ROUTE, TARGET_ROUTE, SCORE, PACE_GAP, "
					+ "SOURCE, RESCUE_STATUS, CREATE_USER, CREATE_DATE, STATUS) "
					+ "VALUES (1, ?, ?, ?, ?, ?, ?, ?, 'EMILY', 'proposed', ?, NOW(), 0)",
					PreparedStatement.RETURN_GENERATED_KEYS);
			ps.setInt(1, callId);
			ps.setInt(2, helperId);
			ps.setInt(3, targetId);
			ps.setString(4, helperRoute);
			ps.setString(5, targetRoute);
			ps.setDouble(6, score);
			ps.setInt(7, paceGap);
			ps.setString(8, user == null || user.length() == 0 ? "emily" : user);
			ps.executeUpdate();
			ResultSet rs = ps.getGeneratedKeys();
			int id = rs.next() ? rs.getInt(1) : 0;
			rs.close();
			ps.close();
			return id;
		} finally {
			c.close();
		}
	}

	/* ── /escalate : EMR-01 (P1) and P2 callback queue ── */
	public String escalate(int callId, String priority, String reason)
			throws Exception {
		if (!"P1".equalsIgnoreCase(priority))
			priority = "P2";
		Connection c = getConn();
		try {
			PreparedStatement ps = c.prepareStatement(
					"INSERT INTO emily_escalations (ENTITYID, CALLID, PRIORITY, REASON, "
					+ "TRANSFERRED_TO, CREATE_DATE, STATUS) VALUES (1, ?, ?, ?, ?, NOW(), 0)");
			ps.setInt(1, callId);
			ps.setString(2, priority.toUpperCase());
			ps.setString(3, reason == null ? "" : reason);
			ps.setString(4, cfg("TRANSFER_TARGET"));
			ps.executeUpdate();
			ps.close();
		} finally {
			c.close();
		}
		String say = "P1".equalsIgnoreCase(priority)
				? "I'm connecting you to a dispatcher right now - stay on the line."
				: "I've queued this for a dispatcher callback - you'll hear back shortly.";
		return "{\"ok\":true,\"rule\":" + js("P1".equalsIgnoreCase(priority) ? "EMR-01" : "ESC-02")
				+ ",\"priority\":" + js(priority.toUpperCase())
				+ ",\"transferTo\":" + js(cfg("TRANSFER_TARGET")) + ",\"say\":" + js(say) + "}";
	}

	/* ── call lifecycle ── */
	public int openCall(String vapiCallId, Integer employeeId, String phone,
			int simulated, String user) throws Exception {
		Connection c = getConn();
		try {
			PreparedStatement ps = c.prepareStatement(
					"INSERT INTO emily_calls (ENTITYID, VAPI_CALL_ID, EMPLOYEEID, PHONE, "
					+ "START_TIME, SIMULATED, CREATE_USER, CREATE_DATE, STATUS) "
					+ "VALUES (1, ?, ?, ?, NOW(), ?, ?, NOW(), 0)",
					PreparedStatement.RETURN_GENERATED_KEYS);
			ps.setString(1, vapiCallId == null ? "" : vapiCallId);
			if (employeeId == null)
				ps.setNull(2, java.sql.Types.INTEGER);
			else
				ps.setInt(2, employeeId.intValue());
			ps.setString(3, phone == null ? "" : phone);
			ps.setInt(4, simulated);
			ps.setString(5, user == null || user.length() == 0 ? "emily" : user);
			ps.executeUpdate();
			ResultSet rs = ps.getGeneratedKeys();
			int id = rs.next() ? rs.getInt(1) : 0;
			rs.close();
			ps.close();
			return id;
		} finally {
			c.close();
		}
	}

	public String completeCall(int callId, String intent, String outcome,
			String confidence, int durationSec, String transcript,
			String recordingUrl) throws Exception {
		Connection c = getConn();
		try {
			PreparedStatement ps = c.prepareStatement(
					"UPDATE emily_calls SET END_TIME=NOW(), INTENT=?, OUTCOME=?, "
					+ "CONFIDENCE=?, DURATION_SEC=?, TRANSCRIPT=?, RECORDING_URL=? WHERE CALLID=?");
			ps.setString(1, intent);
			ps.setString(2, outcome);
			ps.setBigDecimal(3, new java.math.BigDecimal(
					confidence == null || confidence.length() == 0 ? "0" : confidence));
			ps.setInt(4, durationSec);
			ps.setString(5, transcript == null ? "" : transcript);
			ps.setString(6, recordingUrl == null ? "" : recordingUrl);
			ps.setInt(7, callId);
			ps.executeUpdate();
			ps.close();
		} finally {
			c.close();
		}
		return "{\"ok\":true,\"callId\":" + callId + "}";
	}

	private static int parse(String s, int def) {
		try {
			return Integer.parseInt(s.trim());
		} catch (Exception e) {
			return def;
		}
	}
}
