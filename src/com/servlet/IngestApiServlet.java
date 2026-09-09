package com.servlet;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.PrintWriter;
import java.security.MessageDigest;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

import javax.naming.InitialContext;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.sql.DataSource;

import com.beans.ErrorBean;
import com.beans.GenericUpload;
import com.dataobjects.GenericUploadDAO;
import com.dataobjects.SmartUploadDAO;
import com.tools.EmilyService;

/**
 * AMZL Bridge ingest API - /api/ingest/*  (Phase A: discovery)
 *
 * Every endpoint REQUIRES the X-INGEST-KEY header to match
 * emily_config.INGEST_KEY (same shared-key pattern as the Emily API).
 * LAN-only; never exposed through any tunnel.
 *
 *   POST /api/ingest/amzl-raw   query: url, capturedAt(ISO)   body: raw JSON
 *       -> amzl_raw (SHA-256 hash dedupe; duplicate = 200 {"dup":true})
 *   POST /api/ingest/heartbeat  params: tabOpen, loggedIn, queueDepth, version
 *       -> in-memory (drives LIVE/OFFLINE chip; not persisted)
 *   GET  /api/ingest/status     -> last heartbeat + today's capture counts
 *
 * Phase A stores payloads verbatim - no JSON parsing server-side. Parser v1
 * (/amzl-itineraries upsert) arrives with Phase B once amzl_raw shows us the
 * real endpoint shapes.
 */
public class IngestApiServlet extends HttpServlet {

	private static final long serialVersionUID = 20260717L;

	private final EmilyService svc = new EmilyService();

	/* last heartbeat, in-memory: [receivedAtMs, tabOpen, loggedIn, queueDepth, version] */
	private static volatile long hbAt = 0;
	private static volatile String hbTabOpen = "", hbLoggedIn = "",
			hbQueueDepth = "", hbVersion = "";

	private Connection getConn() throws Exception {
		InitialContext ctx = new InitialContext();
		DataSource ds = (DataSource) ctx.lookup("java:comp/env/jdbc/MVPGDB");
		return ds.getConnection();
	}

	@Override
	public void doGet(HttpServletRequest req, HttpServletResponse res)
			throws ServletException, IOException {
		doPost(req, res);
	}

	@Override
	public void doPost(HttpServletRequest req, HttpServletResponse res)
			throws ServletException, IOException {
		req.setCharacterEncoding("UTF-8");
		res.setContentType("application/json;charset=UTF-8");
		PrintWriter out = res.getWriter();

		String path = req.getPathInfo() == null ? "" : req.getPathInfo();
		long t0 = System.currentTimeMillis();

		try {
			String key = req.getHeader("X-INGEST-KEY");
			String expected = svc.cfg("INGEST_KEY");
			if (expected.length() == 0 || !expected.equals(key)) {
				res.setStatus(401);
				out.print("{\"error\":\"unauthorized\"}");
				return;
			}

			if (path.equals("/amzl-raw")) {
				String url = p(req, "url");
				String capturedAt = p(req, "capturedAt");
				String body = readBody(req);
				if (body.length() == 0) {
					res.setStatus(400);
					out.print("{\"error\":\"empty body\"}");
					return;
				}

				// Server-side guard (defense in depth): never persist auth /
				// credential / telemetry payloads even if an out-of-date
				// extension still sends them. Mirrors tap.js DENY.
				if (isDeniedUrl(url)) {
					logIngest("amzl-raw", 1, 0, "SKIPPED-denied",
							(int) (System.currentTimeMillis() - t0));
					out.print("{\"ok\":true,\"skipped\":\"denied\"}");
					return;
				}

				String hash = sha256(url + "|" + body);
				boolean inserted = insertRaw(url, hash, capturedAt, body);
				logIngest("amzl-raw", 1, inserted ? 1 : 0,
						inserted ? "OK" : "DUP",
						(int) (System.currentTimeMillis() - t0));
				// auto-load: parse this capture straight into its table unless the
				// dataset is toggled off. Fire-and-forget so the capture POST stays fast.
				final String dsKey = datasetKeyOf(url);
				if (inserted && dsKey != null && isEnabled(dsKey)) {
					final String fBody = body;
					new Thread(new Runnable() {
						public void run() {
							try {
								new com.tools.IngestProcessor().process(dsKey, "nextday", "bridge", "1");
							} catch (Exception ex) {
								ex.printStackTrace();
							}
						}
					}).start();
				}
				out.print("{\"ok\":true,\"dup\":" + (!inserted) + ",\"hash\":"
						+ EmilyService.js(hash) + "}");

			} else if (path.equals("/heartbeat")) {
				hbAt = System.currentTimeMillis();
				hbTabOpen = p(req, "tabOpen");
				hbLoggedIn = p(req, "loggedIn");
				hbQueueDepth = p(req, "queueDepth");
				hbVersion = p(req, "version");
				out.print("{\"ok\":true}");

			} else if (path.equals("/amzl-file")) {
				// A supplementary-report FILE (csv/xlsx) the bridge fetched from
				// the supp_reports manifest's presigned URL. Run it through the
				// SAME Smart Upload pipeline as a manual upload -> canonical table.
				String fileName = p(req, "fileName");
				if (fileName.length() == 0) {
					res.setStatus(400);
					out.print("{\"error\":\"fileName required\"}");
					return;
				}
				String user = p(req, "user");
				if (user.length() == 0)
					user = "bridge";
				String entityID = p(req, "entityID");
				if (entityID.length() == 0)
					entityID = "1";

				// save the posted bytes to a temp file
				File dir = new File(System.getProperty("java.io.tmpdir"), "amzl-bridge");
				dir.mkdirs();
				File tmp = new File(dir, new File(fileName).getName());
				InputStream in = req.getInputStream();
				FileOutputStream fos = new FileOutputStream(tmp);
				byte[] buf = new byte[16384];
				int r, bytes = 0;
				while ((r = in.read(buf)) > 0) {
					fos.write(buf, 0, r);
					bytes += r;
				}
				fos.close();
				if (bytes == 0) {
					res.setStatus(400);
					out.print("{\"error\":\"empty file body\"}");
					return;
				}

				// normalize duplicate-download suffix: "…W28 (1).csv" -> "…W28.csv"
				// (the " (1)" otherwise corrupts week/date parsing in the handlers)
				fileName = fileName.replaceAll("\\s*\\((\\d+)\\)(\\.[A-Za-z0-9]+)$", "$2");
				String detected = SmartUploadDAO.detectTableName(fileName.toLowerCase());
				if (detected.length() == 0) {
					logIngest("amzl-file", 0, 0, "UNKNOWN-TYPE",
							(int) (System.currentTimeMillis() - t0));
					out.print("{\"ok\":true,\"detected\":\"\",\"skipped\":\"unknown type\",\"file\":"
							+ EmilyService.js(fileName) + "}");
					return;
				}
				if (!isEnabled(detected)) {
					out.print("{\"ok\":true,\"detected\":" + EmilyService.js(detected)
							+ ",\"skipped\":\"disabled\",\"file\":" + EmilyService.js(fileName) + "}");
					return;
				}

				GenericUpload bean = new GenericUpload();
				bean.setUploadFileName(fileName);
				bean.setUploadFileNameWithPath(tmp.getAbsolutePath());
				bean.setTableName(detected);
				// CSV separator defaulting — same as SmartUploadDAO does before load
				String fnl = fileName.toLowerCase();
				if (fnl.endsWith(".csv") || fnl.endsWith(".txt"))
					bean.setDataSeperator(",");
				if ("EmployeeSchedule".equals(detected))
					bean.setSelectedType("Next Day Run");
				Object[] rr = new GenericUploadDAO().createRecord(bean, user,
						"TechAdmin", "1", entityID);
				ErrorBean eb = rr != null && rr.length > 1 ? (ErrorBean) rr[1] : null;
				String etype = eb != null ? eb.getType() : "";
				int[] counts = uploadCounts(fileName, entityID);
				logIngest("amzl-file:" + detected, counts[0], counts[1], "OK",
						(int) (System.currentTimeMillis() - t0));
				out.print("{\"ok\":true,\"detected\":" + EmilyService.js(detected)
						+ ",\"rowsTotal\":" + counts[0] + ",\"rowsLoaded\":" + counts[1]
						+ ",\"outcome\":" + EmilyService.js(etype)
						+ ",\"file\":" + EmilyService.js(fileName) + "}");

			} else if (path.equals("/slack-wavesheet")) {
				// A wave-sheet IMAGE the bridge pulled from the Slack channel.
				// Stored pending; the Wave Sheet page lists it and runs the SAME
				// browser OCR a manual drop would. Never parsed server-side.
				String channel = p(req, "channel");
				String ts = p(req, "ts");
				if (ts.length() == 0) {
					res.setStatus(400);
					out.print("{\"error\":\"ts required\"}");
					return;
				}
				String caption = p(req, "caption");
				String mime = p(req, "mime");
				if (mime.length() == 0)
					mime = "image/png";
				String imgName = p(req, "name");
				int w = 0, h = 0;
				try { w = Integer.parseInt(p(req, "w")); } catch (Exception e) {}
				try { h = Integer.parseInt(p(req, "h")); } catch (Exception e) {}

				// read the posted image bytes
				InputStream sin = req.getInputStream();
				java.io.ByteArrayOutputStream bos = new java.io.ByteArrayOutputStream();
				byte[] sbuf = new byte[16384];
				int sr;
				while ((sr = sin.read(sbuf)) > 0)
					bos.write(sbuf, 0, sr);
				byte[] img = bos.toByteArray();
				if (img.length == 0) {
					res.setStatus(400);
					out.print("{\"error\":\"empty image body\"}");
					return;
				}
				boolean inserted = insertSlackWave(channel, ts, caption,
						waveLabel(caption), mime, imgName, w, h, img);
				logIngest("slack-wavesheet", 1, inserted ? 1 : 0,
						inserted ? "OK" : "DUP",
						(int) (System.currentTimeMillis() - t0));
				out.print("{\"ok\":true,\"dup\":" + (!inserted)
						+ ",\"bytes\":" + img.length + "}");

			} else if (path.equals("/purge")) {
				// hard-delete superseded (STATUS=1) rows from the weekly report
				// tables only (pure load-and-replace — hidden there = stale copy).
				// Shared operational tables are excluded on purpose.
				String only = p(req, "table");
				int total = 0;
				StringBuilder by = new StringBuilder("{");
				for (String t : PURGE_TABLES) {
					if (only.length() > 0 && !only.equalsIgnoreCase(t))
						continue;
					int n = purgeHidden(t);
					if (by.length() > 1)
						by.append(",");
					by.append(EmilyService.js(t)).append(":").append(n);
					total += n;
				}
				by.append("}");
				logIngest("purge", 0, total, "OK",
						(int) (System.currentTimeMillis() - t0));
				out.print("{\"ok\":true,\"deleted\":" + total + ",\"byTable\":" + by + "}");

			} else if (path.equals("/toggle")) {
				// enable/disable auto-load for a dataset key
				String ds = p(req, "dataset");
				String en = p(req, "enabled");
				if (ds.length() == 0) {
					res.setStatus(400);
					out.print("{\"error\":\"dataset required\"}");
					return;
				}
				setEnabled(ds, !"0".equals(en) && !"false".equalsIgnoreCase(en),
						p(req, "user"));
				out.print("{\"ok\":true,\"dataset\":" + EmilyService.js(ds)
						+ ",\"enabled\":" + (!"0".equals(en) && !"false".equalsIgnoreCase(en)) + "}");

			} else if (path.equals("/process")) {
				// Phase B: parse captures into MVPx tables.
				// filter = all | weekly | daily | raw | <dataSetId> (default all)
				String filter = p(req, "filter");
				if (filter.length() == 0)
					filter = ("1".equals(p(req, "all")) || "true".equals(p(req, "all"))) ? "all" : "all";
				String user = p(req, "user");
				if (user.length() == 0)
					user = "bridge";
				String schedMode = p(req, "scheduleMode");
				if (schedMode.length() == 0)
					schedMode = "nextday";
				String entityID = p(req, "entityID");
				if (entityID.length() == 0)
					entityID = "1";
				String summary = new com.tools.IngestProcessor().process(filter, schedMode, user, entityID);
				logIngest("process", 0, 0, "OK",
						(int) (System.currentTimeMillis() - t0));
				out.print("{\"ok\":true,\"summary\":" + EmilyService.js(summary) + "}");

			} else if (path.equals("/status")) {
				long ageSec = hbAt == 0 ? -1
						: (System.currentTimeMillis() - hbAt) / 1000;
				int[] counts = rawCountsToday();
				out.print("{\"heartbeatAgeSec\":" + ageSec + ",\"tabOpen\":"
						+ EmilyService.js(hbTabOpen) + ",\"loggedIn\":"
						+ EmilyService.js(hbLoggedIn) + ",\"queueDepth\":"
						+ EmilyService.js(hbQueueDepth) + ",\"version\":"
						+ EmilyService.js(hbVersion) + ",\"rawToday\":"
						+ counts[0] + ",\"rawDistinctUrlsToday\":" + counts[1]
						+ "}");

			} else {
				res.setStatus(404);
				out.print("{\"error\":\"unknown endpoint\"}");
			}
		} catch (Exception ex) {
			ex.printStackTrace();
			try {
				logIngest(path, 0, 0, "ERR " + ex.getClass().getSimpleName(),
						(int) (System.currentTimeMillis() - t0));
			} catch (Exception ignore) {
			}
			res.setStatus(500);
			out.print("{\"error\":" + EmilyService.js(
					ex.getClass().getSimpleName() + ": " + ex.getMessage())
					+ "}");
		}
	}

	/* returns false when the unique hash already exists (duplicate capture) */
	private boolean insertRaw(String url, String hash, String capturedAt,
			String body) throws Exception {
		Connection c = getConn();
		try {
			PreparedStatement ps = c.prepareStatement(
					"INSERT IGNORE INTO amzl_raw (ENTITYID, URL, HASH, "
					+ "CAPTURED_AT, PARSE_STATUS, BODY, CREATE_DATE) "
					+ "VALUES (1, ?, ?, ?, 'RAW', ?, NOW())");
			ps.setString(1, url.length() > 1000 ? url.substring(0, 1000) : url);
			ps.setString(2, hash);
			// capturedAt arrives ISO-8601 from the extension; store null if unparseable
			java.sql.Timestamp ts = null;
			try {
				ts = new java.sql.Timestamp(
						javax.xml.bind.DatatypeConverter.parseDateTime(capturedAt)
								.getTimeInMillis());
			} catch (Exception e) {
			}
			ps.setTimestamp(3, ts);
			ps.setString(4, body);
			int n = ps.executeUpdate();
			ps.close();
			return n > 0;
		} finally {
			c.close();
		}
	}

	/* store a Slack wave-sheet image; false when (channel,ts) already present */
	private boolean insertSlackWave(String channel, String ts, String caption,
			String waveLabel, String mime, String imgName, int w, int h,
			byte[] img) throws Exception {
		Connection c = getConn();
		try {
			PreparedStatement ps = c.prepareStatement(
					"INSERT IGNORE INTO slack_wavesheet (ENTITYID, CHANNEL, "
					+ "SLACK_TS, CAPTION, WAVE_LABEL, IMG_MIME, IMG_NAME, "
					+ "IMG_W, IMG_H, IMG_DATA, STATUS, CREATE_DATE) "
					+ "VALUES (1, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0, NOW())");
			ps.setString(1, channel);
			ps.setString(2, ts);
			ps.setString(3, caption);
			ps.setString(4, waveLabel);
			ps.setString(5, mime);
			ps.setString(6, imgName);
			ps.setInt(7, w);
			ps.setInt(8, h);
			ps.setBytes(9, img);
			int n = ps.executeUpdate();
			ps.close();
			return n > 0;
		} finally {
			c.close();
		}
	}

	/* pull a short "WAVE 6.5 - 11:35" label out of the Slack caption text */
	private static String waveLabel(String caption) {
		if (caption == null)
			return "";
		java.util.regex.Matcher m = java.util.regex.Pattern
				.compile("(?i)wave\\s*[0-9]+(?:\\.[0-9]+)?\\s*(?:[-–]\\s*[0-9]{1,2}:[0-9]{2})?")
				.matcher(caption);
		if (m.find())
			return m.group().replaceAll("\\s+", " ").trim();
		return caption.length() > 60 ? caption.substring(0, 60) : caption;
	}

	private void logIngest(String source, int rowsIn, int rowsUpserted,
			String outcome, int ms) throws Exception {
		Connection c = getConn();
		try {
			PreparedStatement ps = c.prepareStatement(
					"INSERT INTO ingest_log (ENTITYID, SOURCE, ROWS_IN, "
					+ "ROWS_UPSERTED, PARSER_VERSION, OUTCOME, MS, CREATE_DATE) "
					+ "VALUES (1, ?, ?, ?, '', ?, ?, NOW())");
			ps.setString(1, source);
			ps.setInt(2, rowsIn);
			ps.setInt(3, rowsUpserted);
			ps.setString(4, outcome);
			ps.setInt(5, ms);
			ps.executeUpdate();
			ps.close();
		} finally {
			c.close();
		}
	}

	/* weekly report tables that are pure load-and-replace: STATUS=1 there is
	   always a superseded reload copy, safe to hard-delete. NOT the shared
	   operational tables (VEHICLE/EMPLOYEE/daily_itineraries/employee_schedule). */
	private static final String[] PURGE_TABLES = {
			"dvic", "da_break_utilization", "sentiment_survey",
			"compliance_supplementary", "tenure_workforce_das",
			"tenure_workforce_weekly", "quality_dcr_weekly", "quality_overview",
			"cdf_feedback", "dsb_details", "dashboard_overview", "safety_dashboard" };

	private int purgeHidden(String table) {
		Connection c = null;
		try {
			c = getConn();
			java.sql.Statement st = c.createStatement();
			int n = st.executeUpdate("DELETE FROM `" + table + "` WHERE STATUS=1");
			st.close();
			return n;
		} catch (Exception e) {
			return 0;
		} finally {
			if (c != null)
				try {
					c.close();
				} catch (Exception e) {
				}
		}
	}

	/* count of hidden (superseded) rows across the purgeable report tables */
	private int hiddenCount() {
		Connection c = null;
		int total = 0;
		try {
			c = getConn();
			for (String t : PURGE_TABLES) {
				try {
					java.sql.Statement st = c.createStatement();
					ResultSet rs = st.executeQuery("SELECT COUNT(*) FROM `" + t + "` WHERE STATUS=1");
					if (rs.next())
						total += rs.getInt(1);
					rs.close();
					st.close();
				} catch (Exception e) {
				}
			}
		} catch (Exception e) {
		} finally {
			if (c != null)
				try {
					c.close();
				} catch (Exception e) {
				}
		}
		return total;
	}

	/* a dataset auto-loads unless explicitly disabled (default ON) */
	private boolean isEnabled(String dataset) {
		Connection c = null;
		try {
			c = getConn();
			PreparedStatement ps = c.prepareStatement(
					"SELECT ENABLED FROM amzl_dataset WHERE DATASET=?");
			ps.setString(1, dataset);
			ResultSet rs = ps.executeQuery();
			boolean en = true; // default enabled
			if (rs.next())
				en = rs.getInt(1) != 0;
			rs.close();
			ps.close();
			return en;
		} catch (Exception e) {
			return true;
		} finally {
			if (c != null)
				try {
					c.close();
				} catch (Exception e) {
				}
		}
	}

	private void setEnabled(String dataset, boolean enabled, String user) {
		Connection c = null;
		try {
			c = getConn();
			PreparedStatement ps = c.prepareStatement(
					"INSERT INTO amzl_dataset (DATASET, ENABLED, UPDATE_USER, UPDATE_DATE) "
					+ "VALUES (?,?,?,NOW()) ON DUPLICATE KEY UPDATE ENABLED=VALUES(ENABLED), "
					+ "UPDATE_USER=VALUES(UPDATE_USER), UPDATE_DATE=NOW()");
			ps.setString(1, dataset);
			ps.setInt(2, enabled ? 1 : 0);
			ps.setString(3, user.length() == 0 ? "bridge" : user);
			ps.executeUpdate();
			ps.close();
		} catch (Exception e) {
			/* best effort */
		} finally {
			if (c != null)
				try {
					c.close();
				} catch (Exception e) {
				}
		}
	}

	/* the dataset key a captured URL belongs to (null = not auto-loadable) */
	private static String datasetKeyOf(String url) {
		if (url == null)
			return null;
		if (url.contains("/operations/execution/api/summaries"))
			return "itineraries";
		if (url.contains("/fleet-management/api/vehicles"))
			return "vehicles";
		if (url.contains("fetchDSPAssociates"))
			return "employees";
		int i = url.indexOf("dataSetId=");
		if (i >= 0) {
			String v = url.substring(i + 10);
			int amp = v.indexOf('&');
			return amp >= 0 ? v.substring(0, amp) : v;
		}
		return null; // rosters(schedule), supp_reports manifest, misc -> not auto-parsed here
	}

	/* latest GENERIC_UPLOAD row for a filename -> [total, loaded] */
	private int[] uploadCounts(String fileName, String entityID) {
		Connection c = null;
		try {
			c = getConn();
			PreparedStatement ps = c.prepareStatement(
					"SELECT TOTAL_ROWS, ACTUAL_ROWS FROM GENERIC_UPLOAD "
					+ "WHERE FILE_NAME=? AND ENTITYID=? AND STATUS!=9 "
					+ "ORDER BY CREATE_DATE DESC, GENERIC_UPLOADID DESC LIMIT 1");
			ps.setString(1, fileName);
			ps.setInt(2, Integer.parseInt(entityID));
			ResultSet rs = ps.executeQuery();
			int[] out = new int[] { 0, 0 };
			if (rs.next()) {
				out[0] = (int) Math.round(rs.getDouble(1));
				out[1] = (int) Math.round(rs.getDouble(2));
			}
			rs.close();
			ps.close();
			return out;
		} catch (Exception e) {
			return new int[] { 0, 0 };
		} finally {
			if (c != null)
				try {
					c.close();
				} catch (Exception e) {
				}
		}
	}

	private int[] rawCountsToday() throws Exception {
		Connection c = getConn();
		try {
			PreparedStatement ps = c.prepareStatement(
					"SELECT COUNT(*), COUNT(DISTINCT URL) FROM amzl_raw "
					+ "WHERE CREATE_DATE >= CURDATE()");
			ResultSet rs = ps.executeQuery();
			int[] r = new int[] { 0, 0 };
			if (rs.next()) {
				r[0] = rs.getInt(1);
				r[1] = rs.getInt(2);
			}
			rs.close();
			ps.close();
			return r;
		} finally {
			c.close();
		}
	}

	/* URL patterns whose payloads must never be stored (session tokens etc.) */
	private static boolean isDeniedUrl(String url) {
		if (url == null)
			return false;
		String u = url.toLowerCase();
		return u.contains("cognito-identity")
				|| u.contains("/companion/credentials")
				|| u.contains("/credentials")
				|| u.contains("/oauth") || u.contains("/token")
				|| u.contains("/signin") || u.contains("/login")
				|| u.matches(".*\\brum\\.[^/]*amazonaws\\.com.*")
				|| u.matches(".*\\bsts\\.[^/]*amazonaws\\.com.*");
	}

	private static String sha256(String s) throws Exception {
		MessageDigest md = MessageDigest.getInstance("SHA-256");
		byte[] d = md.digest(s.getBytes("UTF-8"));
		StringBuilder b = new StringBuilder();
		for (byte x : d)
			b.append(String.format("%02x", x));
		return b.toString();
	}

	private static String readBody(HttpServletRequest req) throws IOException {
		StringBuilder b = new StringBuilder();
		BufferedReader r = req.getReader();
		char[] buf = new char[8192];
		int n;
		while ((n = r.read(buf)) > 0)
			b.append(buf, 0, n);
		return b.toString();
	}

	private static String p(HttpServletRequest req, String name) {
		String v = req.getParameter(name);
		return v == null ? "" : v.trim();
	}
}
