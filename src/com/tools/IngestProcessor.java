package com.tools;

import java.text.SimpleDateFormat;
import java.sql.Connection;
import java.sql.DatabaseMetaData;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

import javax.naming.InitialContext;
import javax.sql.DataSource;

import com.google.gson.JsonArray;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;
import com.google.gson.JsonPrimitive;

/**
 * AMZL Bridge Phase B - parse raw captures into MVPx tables.
 *
 * Reads amzl_raw rows with PARSE_STATUS='RAW' and routes by URL:
 *   - /operations/execution/api/summaries  -> upsert daily_itineraries
 *     (keyed on TRANSPORTERID + DATE(ITINARARYDATE); UPDATE_DATE=NOW is the
 *      freshness signal Emily's MAX_DATA_AGE_MIN gate reads)
 *   - ...?dataSetId=<X>  and a fleetdb table named <X> exists  -> full-refresh
 *     that table from tableData.<X>.rows (each row = one flat JSON record)
 *   - anything else -> NO_HANDLER (left in place, re-parseable later)
 *
 * getData payload shape:
 *   { "tableData": { "<dataSetId>": { "rows": [ "<json-string per record>" ] } } }
 * Each row string parses to a flat object; keys map 1:1 to table columns
 * (columns were created from these same payloads in Phase A).
 */
public class IngestProcessor {

	private Connection getConn() throws Exception {
		InitialContext ctx = new InitialContext();
		DataSource ds = (DataSource) ctx.lookup("java:comp/env/jdbc/MVPGDB");
		return ds.getConnection();
	}

	/**
	 * Parse captured payloads into MVPx tables.
	 * filter selects which captures to (re)parse:
	 *   "" / "all"  -> everything captured
	 *   "weekly"    -> getData payloads with timeFrame=Weekly
	 *   "daily"     -> getData payloads with timeFrame=Daily + itineraries (summaries)
	 *   "raw"       -> only not-yet-parsed (PARSE_STATUS='RAW')
	 *   "<dataSetId>" -> only that dataset (alnum/underscore); "itineraries" = summaries
	 * Re-parsing is idempotent (getData tables full-refresh; itineraries upsert).
	 * Returns a summary string.
	 */
	public String process(String filter, String loginUser) throws Exception {
		return process(filter, "nextday", loginUser, "1");
	}

	public String process(String filter, String scheduleMode, String loginUser,
			String entityID) throws Exception {
		int itinRows = 0, dataRows = 0, handled = 0, noHandler = 0, errors = 0;
		boolean scheduleReq = "schedule".equalsIgnoreCase(filter == null ? "" : filter.trim());
		StringBuilder detail = new StringBuilder();
		Connection c = getConn();
		try {
			Set<String> tables = listTables(c);
			List<Object[]> batch = new ArrayList<Object[]>();

			String sel = "SELECT AMZL_RAWID, URL, BODY FROM amzl_raw"
					+ buildWhere(filter) + " ORDER BY AMZL_RAWID";
			PreparedStatement ps = c.prepareStatement(sel);
			ResultSet rs = ps.executeQuery();
			while (rs.next()) {
				batch.add(new Object[] { rs.getLong(1), rs.getString(2), rs.getString(3) });
			}
			rs.close();
			ps.close();

			for (Object[] row : batch) {
				long id = (Long) row[0];
				String url = (String) row[1];
				String body = (String) row[2];
				String status = "NO_HANDLER";
				try {
					if (url != null && url.contains("/operations/execution/api/summaries")) {
						int n = upsertItineraries(c, body, loginUser, url);
						itinRows += n;
						handled++;
						status = "PARSED";
						detail.append("itineraries: ").append(n).append(" rows\n");
					} else if (url != null && url.contains("/api/v4/rosters")) {
						// schedule/vehicle-allocation only runs when explicitly requested
						if (scheduleReq) {
							int n = upsertSchedule(body, loginUser, entityID, scheduleMode);
							dataRows += n;
							handled++;
							status = "PARSED";
							detail.append("schedule (").append(scheduleMode).append("): ")
									.append(n).append(" rows\n");
							logSchedule(c, scheduleMode, n);
						} else {
							noHandler++;
						}
					} else if (url != null && url.contains("/fleet-management/api/vehicles")) {
						int n = upsertVehicles(body, loginUser, entityID);
						dataRows += n;
						handled++;
						status = "PARSED";
						detail.append("vehicles: ").append(n).append(" rows\n");
					} else if (url != null && url.contains("fetchDSPAssociates")) {
						int n = upsertEmployees(body, loginUser, entityID);
						dataRows += n;
						handled++;
						status = "PARSED";
						detail.append("employees: ").append(n).append(" rows\n");
					} else if (url != null && url.contains("dataSetId=")) {
						String dsid = param(url, "dataSetId");
						if (dsid.contains("safety_oss_events")) {
							int nn = upsertSafetyEvents(c, body, loginUser, entityID);
							dataRows += nn;
							handled++;
							status = "PARSED";
							detail.append("safety_dashboard: ").append(nn).append(" rows\n");
						} else if (dsid.length() > 0 && tables.contains(dsid.toLowerCase())) {
							int n = loadGetData(c, dsid, body, loginUser);
							dataRows += n;
							handled++;
							status = "PARSED";
							detail.append(dsid).append(": ").append(n).append(" rows\n");
						} else {
							noHandler++;
						}
					} else {
						noHandler++;
					}
				} catch (Exception exRow) {
					errors++;
					status = "ERROR";
					detail.append("id ").append(id).append(" ERROR: ")
							.append(exRow.getClass().getSimpleName()).append(": ")
							.append(exRow.getMessage()).append("\n");
				}
				setParseStatus(c, id, status);
			}
		} finally {
			c.close();
		}
		return "handled=" + handled + " noHandler=" + noHandler + " errors=" + errors
				+ " | itineraryRows=" + itinRows + " datasetRows=" + dataRows
				+ "\n" + detail.toString();
	}

	/* ── generic getData -> full refresh of a dataSetId-named table ── */
	private int loadGetData(Connection c, String dsid, String body, String loginUser)
			throws Exception {
		JsonObject root = JsonParser.parseString(body).getAsJsonObject();
		JsonObject td = root.has("tableData") && root.get("tableData").isJsonObject()
				? root.getAsJsonObject("tableData") : null;
		if (td == null)
			return 0;
		JsonArray rows = null;
		// prefer the exact dsid key; else the first member that has "rows"
		if (td.has(dsid) && td.get(dsid).isJsonObject()
				&& td.getAsJsonObject(dsid).has("rows")) {
			rows = td.getAsJsonObject(dsid).getAsJsonArray("rows");
		} else {
			for (Map.Entry<String, JsonElement> e : td.entrySet()) {
				if (e.getValue().isJsonObject()
						&& e.getValue().getAsJsonObject().has("rows")) {
					rows = e.getValue().getAsJsonObject().getAsJsonArray("rows");
					break;
				}
			}
		}
		if (rows == null)
			return 0;

		Set<String> cols = columnsOf(c, dsid); // lower-cased actual columns
		// full refresh: clear this entity's rows, then insert the snapshot
		Statement del = c.createStatement();
		del.executeUpdate("DELETE FROM `" + dsid + "` WHERE ENTITYID=1");
		del.close();

		int inserted = 0;
		for (JsonElement re : rows) {
			JsonObject rec;
			if (re.isJsonPrimitive()) {
				rec = JsonParser.parseString(re.getAsString()).getAsJsonObject();
			} else if (re.isJsonObject()) {
				rec = re.getAsJsonObject();
			} else {
				continue;
			}
			LinkedHashMap<String, String> vals = new LinkedHashMap<String, String>();
			for (Map.Entry<String, JsonElement> f : rec.entrySet()) {
				if (cols.contains(f.getKey().toLowerCase()))
					vals.put(f.getKey(), scalar(f.getValue()));
			}
			if (vals.isEmpty())
				continue;
			StringBuilder cSql = new StringBuilder("INSERT INTO `" + dsid + "` (ENTITYID,SOURCE,STATUS,CREATE_USER,CREATE_DATE");
			StringBuilder vSql = new StringBuilder(") VALUES (1,'BRIDGE',0,?,NOW()");
			for (String k : vals.keySet()) {
				cSql.append(",`").append(k).append("`");
				vSql.append(",?");
			}
			cSql.append(vSql).append(")");
			PreparedStatement ins = c.prepareStatement(cSql.toString());
			int i = 1;
			ins.setString(i++, loginUser);
			for (String v : vals.values()) {
				if (v == null)
					ins.setNull(i++, java.sql.Types.VARCHAR);
				else
					ins.setString(i++, v);
			}
			ins.executeUpdate();
			ins.close();
			inserted++;
		}
		return inserted;
	}

	/* ── itinerarySummaries -> upsert daily_itineraries ── */
	private int upsertItineraries(Connection c, String body, String loginUser, String url)
			throws Exception {
		JsonObject root = JsonParser.parseString(body).getAsJsonObject();
		JsonArray items = root.has("itinerarySummaries") && root.get("itinerarySummaries").isJsonArray()
				? root.getAsJsonArray("itinerarySummaries") : null;
		if (items == null)
			return 0;

		// station is derived from the capture's serviceAreaId (works for any
		// station/DSP), looked up in amzl_station_map; falls back to the raw id.
		String serviceAreaId = param(url == null ? "" : url, "serviceAreaId");
		String stationCode = lookupStation(c, serviceAreaId);
		if (stationCode.length() == 0)
			stationCode = serviceAreaId;

		// driver display names live in the top-level transporters LIST,
		// each item = {transporterId, firstName, lastName, ...}
		Map<String, String> names = new java.util.HashMap<String, String>();
		if (root.has("transporters") && root.get("transporters").isJsonArray()) {
			for (JsonElement te : root.getAsJsonArray("transporters")) {
				try {
					JsonObject t = te.getAsJsonObject();
					String id = str(t, "transporterId");
					if (id.length() == 0)
						continue;
					String nm = str(t, "name");
					if (nm.length() == 0)
						nm = (str(t, "firstName") + " " + str(t, "lastName")).trim();
					if (nm.length() > 0)
						names.put(id, nm);
				} catch (Exception ig) {
				}
			}
		}

		int n = 0;
		for (JsonElement ie : items) {
			if (!ie.isJsonObject())
				continue;
			JsonObject it = ie.getAsJsonObject();
			String tid = str(it, "transporterId");
			if (tid.length() == 0)
				continue;
			String routeCode = str(it, "routeCode");
			Timestamp itinDate = epochMsToTs(startOfDayFromPlanned(it));
			if (itinDate == null)
				itinDate = new Timestamp(System.currentTimeMillis());
			int[] wk = weekYear(itinDate);
			// multi-station: derive from the capture's serviceAreaId (any station/DSP)
			String station = stationCode;
			String name = names.containsKey(tid) ? names.get(tid) : "";
			String progress = firstNonEmpty(str(it, "progressStatus"), str(it, "executionStatus"));
			String projReturn = num(it, "projectedCompletionTime");
			String serviceType = str(it, "serviceTypeName");
			String vin = str(it, "vinNumber");
			int all = 0, done = 0, notStarted = 0;
			if (it.has("stopProgress") && it.get("stopProgress").isJsonObject()) {
				JsonObject sp = it.getAsJsonObject("stopProgress");
				all = intOf(sp, "total");
				done = intOf(sp, "completed");
				notStarted = intOf(sp, "notStarted");
			}
			int totalPkg = intOf(it, "totalPackages");
			int pace = (int) Math.round(dbl(it, "stopCompletionRate"));
			if (pace == 0)
				pace = intOf(it, "completedStopsInLastHour");
			String charge = num(it, "stateOfChargeRemainingPercent");

			// upsert on (TRANSPORTERID, DATE(ITINARARYDATE))
			String find = "SELECT DAILY_ITINERARIESID FROM daily_itineraries "
					+ "WHERE ENTITYID=1 AND TRANSPORTERID=? AND DATE(ITINARARYDATE)=DATE(?) LIMIT 1";
			PreparedStatement pf = c.prepareStatement(find);
			pf.setString(1, tid);
			pf.setTimestamp(2, itinDate);
			ResultSet rf = pf.executeQuery();
			Long existing = rf.next() ? rf.getLong(1) : null;
			rf.close();
			pf.close();

			if (existing == null) {
				String ins = "INSERT INTO daily_itineraries (ENTITYID,routecode,ITINARARYDATE,"
						+ "ITINARARY_WEEK,ITINARARY_YEAR,STATION,TRANSPORTERID,TRANSPORTERNAME,"
						+ "ROUTEPROGRESS,PROJECTEDRETURN,SERVICETYPE,VINNUMBER,ALLSTOPS,COMPLETEDSTOPS,"
						+ "NOTSTARTEDSTOPS,TOALPACKAGES,AVG_PACE_STOP_PER_HOUR,REMAININGCHARGE,"
						+ "CREATE_USER,CREATE_DATE,UPDATE_USER,UPDATE_DATE,STATUS) "
						+ "VALUES (1,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,NOW(),?,NOW(),0)";
				PreparedStatement pi = c.prepareStatement(ins);
				int i = 1;
				pi.setString(i++, routeCode);
				pi.setTimestamp(i++, itinDate);
				pi.setInt(i++, wk[0]);
				pi.setInt(i++, wk[1]);
				pi.setString(i++, station);
				pi.setString(i++, tid);
				pi.setString(i++, name);
				pi.setString(i++, progress);
				pi.setString(i++, projReturn);
				pi.setString(i++, serviceType);
				pi.setString(i++, vin);
				pi.setInt(i++, all);
				pi.setInt(i++, done);
				pi.setInt(i++, notStarted);
				pi.setInt(i++, totalPkg);
				pi.setInt(i++, pace);
				pi.setString(i++, charge);
				pi.setString(i++, loginUser);
				pi.setString(i++, loginUser);
				pi.executeUpdate();
				pi.close();
			} else {
				String upd = "UPDATE daily_itineraries SET routecode=?,TRANSPORTERNAME=?,"
						+ "ROUTEPROGRESS=?,PROJECTEDRETURN=?,SERVICETYPE=?,VINNUMBER=?,ALLSTOPS=?,"
						+ "COMPLETEDSTOPS=?,NOTSTARTEDSTOPS=?,TOALPACKAGES=?,AVG_PACE_STOP_PER_HOUR=?,"
						+ "REMAININGCHARGE=?,STATION=?,STATUS=0,UPDATE_USER=?,UPDATE_DATE=NOW() "
						+ "WHERE DAILY_ITINERARIESID=?";
				PreparedStatement pu = c.prepareStatement(upd);
				int i = 1;
				pu.setString(i++, routeCode);
				pu.setString(i++, name);
				pu.setString(i++, progress);
				pu.setString(i++, projReturn);
				pu.setString(i++, serviceType);
				pu.setString(i++, vin);
				pu.setInt(i++, all);
				pu.setInt(i++, done);
				pu.setInt(i++, notStarted);
				pu.setInt(i++, totalPkg);
				pu.setInt(i++, pace);
				pu.setString(i++, charge);
				pu.setString(i++, station);
				pu.setString(i++, loginUser);
				pu.setLong(i++, existing);
				pu.executeUpdate();
				pu.close();
			}
			n++;
		}
		return n;
	}

	/* ── fleet vehicles JSON -> canonical VEHICLE table via AdminVehicleDAO ──
	   Reconstructs the exact 28-column order the fleet export (vehicledata.xlsx)
	   produces, which AdminVehicleDAO.updateFromFile reads positionally, then
	   reuses that DAO (dedupes by VIN/vehicleNumber -> update-or-insert). */
	private int upsertVehicles(String body, String loginUser, String entityID)
			throws Exception {
		JsonObject root = JsonParser.parseString(body).getAsJsonObject();
		JsonArray vs = null;
		if (root.has("data") && root.get("data").isJsonObject()
				&& root.getAsJsonObject("data").has("vehicles"))
			vs = root.getAsJsonObject("data").getAsJsonArray("vehicles");
		else if (root.has("vehicles") && root.get("vehicles").isJsonArray())
			vs = root.getAsJsonArray("vehicles");
		if (vs == null)
			return 0;

		List dataList = new ArrayList();
		String learnSA = "", learnStn = "", learnCo = "";
		for (JsonElement ve : vs) {
			if (!ve.isJsonObject())
				continue;
			JsonObject v = ve.getAsJsonObject();
			String station = "";
			if (v.has("serviceStation") && v.get("serviceStation").isJsonObject()) {
				JsonObject ss = v.getAsJsonObject("serviceStation");
				station = str(ss, "stationCode");
				// learn serviceAreaId -> stationCode for multi-station itineraries
				if (learnSA.length() == 0) {
					learnSA = str(ss, "serviceAreaId");
					learnStn = station;
					learnCo = str(v, "companyId");
				}
			}
			String own = str(v, "vehicleOwnershipType");
			List<String> r = new ArrayList<String>();
			r.add(str(v, "vin"));                       // 0  vin
			r.add(str(v, "serviceType"));               // 1  serviceType
			r.add(str(v, "dspVehicleId"));              // 2  vehicleName
			r.add(str(v, "registrationNo"));            // 3  licensePlateNumber
			r.add(str(v, "make"));                      // 4  make
			r.add(str(v, "model"));                     // 5  model
			r.add(str(v, "submodel"));                  // 6  subModel
			r.add(str(v, "status"));                    // 7  status
			r.add("");                                  // 8  statusPriority (not in API)
			r.add(str(v, "statusReasonCode"));          // 9  statusReasonCode
			r.add(str(v, "statusReasonMessage"));       // 10 statusReasonMessage
			r.add(str(v, "operationalStatus"));         // 11 operationalStatus
			r.add("");                                  // 12 statusSearchValue
			r.add(str(v, "subcontractorName"));         // 13 subcontractorName
			r.add(str(v, "vehicleProvider"));           // 14 vehicleProvider
			r.add(str(v, "vehicleRegistrationType"));   // 15 vehicleRegistrationType
			r.add(num(v, "year"));                      // 16 year
			r.add(own);                                 // 17 type
			r.add(own);                                 // 18 ownershipType
			r.add(str(v, "ownershipStartDate"));        // 19 ownershipStartDate
			r.add(str(v, "ownershipEndDate"));          // 20 ownershipEndDate
			r.add("");                                  // 21 pmStats
			r.add(str(v, "registrationExpiryDate"));    // 22 registrationExpiryDate
			r.add(str(v, "registeredState"));           // 23 registeredState
			r.add(str(v, "serviceTier"));               // 24 serviceTier
			r.add(station);                             // 25 stationCode
			r.add(num(v, "payload"));                   // 26 payload
			r.add(num(v, "cubicCapacity"));             // 27 cubicCapacity
			dataList.add(r);
		}
		if (dataList.isEmpty())
			return 0;
		if (learnSA.length() > 0) {
			Connection lc = getConn();
			try { learnStation(lc, learnSA, learnStn, learnCo); } finally { lc.close(); }
		}
		Map<String, String> reqMap = new java.util.HashMap<String, String>();
		double n = new com.dataobjects.AdminVehicleDAO()
				.updateFromFile(new ArrayList<String>(), dataList, loginUser, entityID, reqMap);
		return (int) n;
	}

	/* ── safety OSS events getData -> canonical safety_dashboard (upsert by EVENTID) ──
	   the "Metric event-level details" grid: per-event rows map 1:1 to the table
	   the Safety CSV normally fills. */
	private int upsertSafetyEvents(Connection c, String body, String loginUser,
			String entityID) throws Exception {
		JsonObject root = JsonParser.parseString(body).getAsJsonObject();
		JsonObject td = root.has("tableData") && root.get("tableData").isJsonObject()
				? root.getAsJsonObject("tableData") : null;
		if (td == null)
			return 0;
		JsonArray rows = null;
		for (Map.Entry<String, JsonElement> e : td.entrySet()) {
			if (e.getKey().contains("safety_oss_events") && e.getValue().isJsonObject()
					&& e.getValue().getAsJsonObject().has("rows")) {
				rows = e.getValue().getAsJsonObject().getAsJsonArray("rows");
				break;
			}
		}
		if (rows == null)
			return 0;
		SimpleDateFormat iso = new SimpleDateFormat("yyyy-MM-dd");
		int n = 0;
		for (JsonElement re : rows) {
			JsonObject r = re.isJsonPrimitive()
					? JsonParser.parseString(re.getAsString()).getAsJsonObject()
					: (re.isJsonObject() ? re.getAsJsonObject() : null);
			if (r == null)
				continue;
			String eventId = str(r, "event_id");
			if (eventId.length() == 0)
				continue;
			String dataDate = str(r, "data_date");
			int wk = 0;
			try {
				int[] w = weekYear(new Timestamp(iso.parse(dataDate).getTime()));
				wk = w[0];
			} catch (Exception ig) {
			}
			String da = str(r, "da_name"), tid = str(r, "transporter_id"),
					vin = str(r, "vehicle_id"), evtDt = str(r, "event_start_time_local"),
					oss = firstNonEmpty(str(r, "oss_impact"), str(r, "program_impact")),
					mtype = str(r, "dashboard_metric_type"),
					msub = str(r, "dashboard_metric_subtype"),
					src = str(r, "source"), vid = str(r, "video_url"),
					rev = str(r, "dashboard_review_details");

			PreparedStatement pf = c.prepareStatement(
					"SELECT SAFETY_DASHBOARDID FROM safety_dashboard WHERE ENTITYID=1 AND EVENTID=? LIMIT 1");
			pf.setString(1, eventId);
			ResultSet rf = pf.executeQuery();
			Long id = rf.next() ? rf.getLong(1) : null;
			rf.close();
			pf.close();
			if (id == null) {
				PreparedStatement pi = c.prepareStatement(
						"INSERT INTO safety_dashboard (ENTITYID,SAFTY_WEEK,SAFTY_DATE,DELIVERYASSOCIATE,"
						+ "TRANSPORTERID,EVENTID,EVENT_DATETIME,VIN,OSSIMPACT,METRICTYPE,METRICSUBTYPE,"
						+ "SOURCE,VIDEOLINK,REVIEWDETAILS,CREATE_USER,CREATE_DATE,UPDATE_USER,UPDATE_DATE,STATUS) "
						+ "VALUES (1,?,?,?,?,?,?,?,?,?,?,?,?,?,?,NOW(),?,NOW(),0)");
				int i = 1;
				pi.setInt(i++, wk);
				pi.setString(i++, dataDate);
				pi.setString(i++, da);
				pi.setString(i++, tid);
				pi.setString(i++, eventId);
				pi.setString(i++, evtDt);
				pi.setString(i++, vin);
				pi.setString(i++, oss);
				pi.setString(i++, mtype);
				pi.setString(i++, msub);
				pi.setString(i++, src);
				pi.setString(i++, vid);
				pi.setString(i++, rev);
				pi.setString(i++, loginUser);
				pi.setString(i++, loginUser);
				pi.executeUpdate();
				pi.close();
			} else {
				PreparedStatement pu = c.prepareStatement(
						"UPDATE safety_dashboard SET SAFTY_WEEK=?,SAFTY_DATE=?,DELIVERYASSOCIATE=?,"
						+ "TRANSPORTERID=?,EVENT_DATETIME=?,VIN=?,OSSIMPACT=?,METRICTYPE=?,METRICSUBTYPE=?,"
						+ "SOURCE=?,VIDEOLINK=?,REVIEWDETAILS=?,STATUS=0,UPDATE_USER=?,UPDATE_DATE=NOW() "
						+ "WHERE SAFETY_DASHBOARDID=?");
				int i = 1;
				pu.setInt(i++, wk);
				pu.setString(i++, dataDate);
				pu.setString(i++, da);
				pu.setString(i++, tid);
				pu.setString(i++, evtDt);
				pu.setString(i++, vin);
				pu.setString(i++, oss);
				pu.setString(i++, mtype);
				pu.setString(i++, msub);
				pu.setString(i++, src);
				pu.setString(i++, vid);
				pu.setString(i++, rev);
				pu.setString(i++, loginUser);
				pu.setLong(i++, id);
				pu.executeUpdate();
				pu.close();
			}
			n++;
		}
		return n;
	}

	/* ── fetchDSPAssociates JSON -> canonical EMPLOYEE via AdminEmployeeDAO ──
	   tableData."dsp-associates-table-data".rows -> the 9-col positional order
	   AdminEmployeeDAO.updateFromFile reads (dedupes by transporterId). */
	private int upsertEmployees(String body, String loginUser, String entityID)
			throws Exception {
		JsonObject root = JsonParser.parseString(body).getAsJsonObject();
		JsonArray rows = null;
		if (root.has("tableData") && root.get("tableData").isJsonObject()) {
			JsonObject td = root.getAsJsonObject("tableData");
			if (td.has("dsp-associates-table-data")
					&& td.get("dsp-associates-table-data").isJsonObject())
				rows = td.getAsJsonObject("dsp-associates-table-data").getAsJsonArray("rows");
		}
		if (rows == null)
			return 0;
		List dataList = new ArrayList();
		for (JsonElement re : rows) {
			JsonObject r;
			if (re.isJsonPrimitive())
				r = JsonParser.parseString(re.getAsString()).getAsJsonObject();
			else if (re.isJsonObject())
				r = re.getAsJsonObject();
			else
				continue;
			List<String> row = new ArrayList<String>();
			row.add(str(r, "full_name"));                        // 0 fullName
			row.add(str(r, "transporter_id"));                   // 1 transporterID
			row.add(str(r, "roles"));                            // 2 position
			row.add(str(r, "qualifications"));                   // 3 qualification
			row.add(str(r, "driver_license_expiration_date"));   // 4 idExpiryDate
			row.add(str(r, "personal_phone_number"));            // 5 mobile
			row.add(str(r, "work_phone_number"));                // 6 workPhone
			row.add(str(r, "email_address"));                    // 7 email
			row.add(str(r, "operational_status"));               // 8 reviewStatus
			dataList.add(row);
		}
		if (dataList.isEmpty())
			return 0;
		Map<String, String> reqMap = new java.util.HashMap<String, String>();
		double n = new com.dataobjects.AdminEmployeeDAO()
				.updateFromFile(new ArrayList<String>(), dataList, loginUser, entityID, reqMap);
		return (int) n;
	}

	/* ── rosters -> reconstruct schedule shape -> reuse EmployeeScheduleDAO ── */
	private int upsertSchedule(String body, String loginUser, String entityID,
			String mode) throws Exception {
		JsonObject root = JsonParser.parseString(body).getAsJsonObject();
		JsonArray data = root.has("data") && root.get("data").isJsonArray()
				? root.getAsJsonArray("data") : null;
		if (data == null)
			return 0;

		// distinct roster dates (yyyy-MM-dd sorts chronologically) across all drivers
		java.util.TreeSet<String> dateSet = new java.util.TreeSet<String>();
		for (JsonElement de : data) {
			if (!de.isJsonObject())
				continue;
			JsonObject d = de.getAsJsonObject();
			if (d.has("reservationsMap") && d.get("reservationsMap").isJsonObject())
				for (Map.Entry<String, JsonElement> e : d.getAsJsonObject("reservationsMap").entrySet())
					dateSet.add(e.getKey());
		}
		if (dateSet.isEmpty())
			return 0;
		List<String> dates = new ArrayList<String>(dateSet);

		// columnsList = [Associate, Transporter ID, "E, dd/MMM" per date]
		// (the DAO parses only column[2] then assumes consecutive days)
		SimpleDateFormat iso = new SimpleDateFormat("yyyy-MM-dd");
		SimpleDateFormat colFmt = new SimpleDateFormat("E, dd/MMM");
		List<String> columnsList = new ArrayList<String>();
		columnsList.add("Associate");
		columnsList.add("Transporter ID");
		for (String d : dates)
			columnsList.add(colFmt.format(iso.parse(d)));

		// dataList = [headerRow(skipped by DAO), driverRow...]
		List dataList = new ArrayList();
		dataList.add(new ArrayList<String>(columnsList));
		for (JsonElement de : data) {
			if (!de.isJsonObject())
				continue;
			JsonObject d = de.getAsJsonObject();
			String name = str(d, "driverName");
			if (name.length() == 0)
				name = (str(d, "driverFirstName") + " " + str(d, "driverLastName")).trim();
			String tid = str(d, "driverPersonId");
			if (tid.length() == 0)
				continue;
			JsonObject resMap = d.has("reservationsMap") && d.get("reservationsMap").isJsonObject()
					? d.getAsJsonObject("reservationsMap") : new JsonObject();
			List<String> rowL = new ArrayList<String>();
			rowL.add(name);
			rowL.add(tid);
			for (String dk : dates) {
				String cell = "";
				if (resMap.has(dk) && resMap.get(dk).isJsonArray()) {
					JsonObject res = pickReservation(resMap.getAsJsonArray(dk));
					if (res != null)
						cell = buildScheduleCell(res);
				}
				rowL.add(cell);
			}
			dataList.add(rowL);
		}

		// run the existing loader (vehicle allocation + delete-and-reload) per mode
		List<String> types = new ArrayList<String>();
		String m = mode == null ? "" : mode.trim().toLowerCase();
		if (m.equals("today"))
			types.add("Run");
		else if (m.equals("todaynext")) {
			types.add("Run");
			types.add("Next Day Run");
		} else if (m.equals("holiday"))
			types.add("Holiday Run");
		else
			types.add("Next Day Run"); // default
		com.dataobjects.EmployeeScheduleDAO dao = new com.dataobjects.EmployeeScheduleDAO();
		int total = 0;
		for (String st : types) {
			Map<String, String> reqMap = new java.util.HashMap<String, String>();
			reqMap.put("selectedType", st);
			double n = dao.updateFromFile(columnsList, dataList, loginUser, entityID, reqMap);
			if (n > 0)
				total += (int) n;
		}
		return total;
	}

	/* prefer an ASSIGNED reservation, else the first */
	private static JsonObject pickReservation(JsonArray arr) {
		JsonObject first = null;
		for (JsonElement e : arr) {
			if (!e.isJsonObject())
				continue;
			JsonObject o = e.getAsJsonObject();
			if (first == null)
				first = o;
			if (str(o, "status").toUpperCase().contains("ASSIGN"))
				return o;
		}
		return first;
	}

	/* cell = "serviceTypeName\nH:MM AM • Nh" — the shape getDayValueArray parses */
	private static String buildScheduleCell(JsonObject res) {
		String svc = str(res, "serviceTypeName");
		String time = "";
		if (res.has("startTimeInMinutes") && !res.get("startTimeInMinutes").isJsonNull()) {
			try {
				time = fmtClock(res.get("startTimeInMinutes").getAsInt());
			} catch (Exception e) {
			}
		}
		String hrs = "";
		if (res.has("durationInMinutes") && !res.get("durationInMinutes").isJsonNull()) {
			try {
				double h = res.get("durationInMinutes").getAsInt() / 60.0;
				hrs = (h == Math.floor(h)) ? ((int) h + "h") : (h + "h");
			} catch (Exception e) {
			}
		}
		return svc + "\n" + time + " • " + hrs;
	}

	private static String fmtClock(int minsFromMidnight) {
		int h = minsFromMidnight / 60, mm = minsFromMidnight % 60;
		String ap = h < 12 ? "AM" : "PM";
		int h12 = h % 12;
		if (h12 == 0)
			h12 = 12;
		return h12 + ":" + (mm < 10 ? "0" : "") + mm + " " + ap;
	}

	/* ── helpers ── */

	/* serviceAreaId -> stationCode (multi-station); learned from vehicle data */
	private String lookupStation(Connection c, String serviceAreaId) {
		if (serviceAreaId == null || serviceAreaId.length() == 0)
			return "";
		try {
			PreparedStatement ps = c.prepareStatement(
					"SELECT STATION_CODE FROM amzl_station_map WHERE SERVICE_AREA_ID=?");
			ps.setString(1, serviceAreaId);
			ResultSet rs = ps.executeQuery();
			String s = rs.next() ? rs.getString(1) : "";
			rs.close();
			ps.close();
			return s == null ? "" : s;
		} catch (Exception e) {
			return "";
		}
	}

	private void learnStation(Connection c, String serviceAreaId, String stationCode, String companyId) {
		if (serviceAreaId == null || serviceAreaId.length() == 0
				|| stationCode == null || stationCode.length() == 0)
			return;
		try {
			PreparedStatement ps = c.prepareStatement(
					"INSERT INTO amzl_station_map (SERVICE_AREA_ID, STATION_CODE, COMPANY_ID, UPDATE_DATE) "
					+ "VALUES (?,?,?,NOW()) ON DUPLICATE KEY UPDATE STATION_CODE=VALUES(STATION_CODE), "
					+ "COMPANY_ID=COALESCE(NULLIF(VALUES(COMPANY_ID),''), COMPANY_ID), UPDATE_DATE=NOW()");
			ps.setString(1, serviceAreaId);
			ps.setString(2, stationCode);
			ps.setString(3, companyId);
			ps.executeUpdate();
			ps.close();
		} catch (Exception e) {
		}
	}

	/* SQL WHERE for the capture selection, per filter (values are sanitized) */
	private static String buildWhere(String filter) {
		String f = filter == null ? "" : filter.trim().toLowerCase();
		if (f.length() == 0 || f.equals("all"))
			return "";
		// multiselect: comma-separated dataSetIds (and/or "itineraries")
		if (filter.indexOf(',') >= 0) {
			String[] toks = filter.split(",");
			StringBuilder sb = new StringBuilder(" WHERE (");
			boolean any = false;
			for (String t : toks) {
				String tk = t.trim().toLowerCase();
				String clause = null;
				if (tk.equals("itineraries") || tk.equals("daily_itineraries"))
					clause = "URL LIKE '%/operations/execution/api/summaries%'";
				else {
					String safe = t.replaceAll("[^A-Za-z0-9_]", "");
					if (safe.length() > 0)
						clause = "URL LIKE '%dataSetId=" + safe + "%'";
				}
				if (clause != null) {
					if (any)
						sb.append(" OR ");
					sb.append(clause);
					any = true;
				}
			}
			sb.append(")");
			return any ? sb.toString() : " WHERE 1=0";
		}
		if (f.equals("raw"))
			return " WHERE PARSE_STATUS='RAW'";
		if (f.equals("weekly"))
			return " WHERE URL LIKE '%timeframe=weekly%'";
		if (f.equals("daily"))
			return " WHERE (URL LIKE '%timeframe=daily%' OR URL LIKE '%/operations/execution/api/summaries%')";
		if (f.equals("itineraries") || f.equals("daily_itineraries"))
			return " WHERE URL LIKE '%/operations/execution/api/summaries%'";
		if (f.equals("schedule"))
			// only the NEWEST roster snapshot — rosters are full snapshots, and
			// processing older ones just wastes a delete-and-reload + allocation
			return " WHERE AMZL_RAWID = (SELECT MAX(a2.AMZL_RAWID) FROM amzl_raw a2 "
					+ "WHERE a2.URL LIKE '%/api/v4/rosters%')";
		if (f.equals("vehicles"))
			// newest fleet snapshot only (full list; dedupes by VIN)
			return " WHERE AMZL_RAWID = (SELECT MAX(a2.AMZL_RAWID) FROM amzl_raw a2 "
					+ "WHERE a2.URL LIKE '%/fleet-management/api/vehicles%')";
		if (f.equals("employees"))
			// newest associate snapshot with the full roster (biggest body)
			return " WHERE AMZL_RAWID = (SELECT a3.AMZL_RAWID FROM amzl_raw a3 "
					+ "WHERE a3.URL LIKE '%fetchDSPAssociates%' "
					+ "ORDER BY LENGTH(a3.BODY) DESC LIMIT 1)";
		// specific dataSetId — allow only safe chars, then match dataSetId=<id>
		String safe = filter.replaceAll("[^A-Za-z0-9_]", "");
		if (safe.length() == 0)
			return " WHERE 1=0";
		return " WHERE URL LIKE '%dataSetId=" + safe + "%'";
	}

	/* record a schedule load so the bridge dashboard can show exactly what it did */
	private void logSchedule(Connection c, String mode, int rows) {
		try {
			PreparedStatement ps = c.prepareStatement(
					"INSERT INTO ingest_log (ENTITYID, SOURCE, ROWS_IN, ROWS_UPSERTED, "
					+ "PARSER_VERSION, OUTCOME, MS, CREATE_DATE) VALUES "
					+ "(1, ?, ?, ?, 'sched-v1', 'OK', 0, NOW())");
			ps.setString(1, "schedule:" + (mode == null ? "nextday" : mode));
			ps.setInt(2, rows);
			ps.setInt(3, rows);
			ps.executeUpdate();
			ps.close();
		} catch (Exception e) {
			/* logging is best-effort */
		}
	}

	private void setParseStatus(Connection c, long id, String status) throws Exception {
		PreparedStatement ps = c.prepareStatement(
				"UPDATE amzl_raw SET PARSE_STATUS=? WHERE AMZL_RAWID=?");
		ps.setString(1, status);
		ps.setLong(2, id);
		ps.executeUpdate();
		ps.close();
	}

	private Set<String> listTables(Connection c) throws Exception {
		Set<String> t = new LinkedHashSet<String>();
		DatabaseMetaData md = c.getMetaData();
		ResultSet rs = md.getTables(c.getCatalog(), null, "%", new String[] { "TABLE" });
		while (rs.next())
			t.add(rs.getString("TABLE_NAME").toLowerCase());
		rs.close();
		return t;
	}

	private Set<String> columnsOf(Connection c, String table) throws Exception {
		Set<String> cols = new LinkedHashSet<String>();
		DatabaseMetaData md = c.getMetaData();
		ResultSet rs = md.getColumns(c.getCatalog(), null, table, "%");
		while (rs.next())
			cols.add(rs.getString("COLUMN_NAME").toLowerCase());
		rs.close();
		return cols;
	}

	private static String param(String url, String key) {
		String k = key + "=";
		int i = url.indexOf(k);
		if (i < 0)
			return "";
		String v = url.substring(i + k.length());
		int amp = v.indexOf('&');
		return amp >= 0 ? v.substring(0, amp) : v;
	}

	private static String scalar(JsonElement e) {
		if (e == null || e.isJsonNull())
			return null;
		if (e.isJsonPrimitive()) {
			JsonPrimitive p = e.getAsJsonPrimitive();
			if (p.isBoolean())
				return p.getAsBoolean() ? "1" : "0";
			return p.getAsString();
		}
		return e.toString(); // nested object/array -> store JSON text
	}

	private static String str(JsonObject o, String k) {
		return o.has(k) && !o.get(k).isJsonNull() && o.get(k).isJsonPrimitive()
				? o.get(k).getAsString() : "";
	}

	private static String num(JsonObject o, String k) {
		return o.has(k) && !o.get(k).isJsonNull() && o.get(k).isJsonPrimitive()
				? o.get(k).getAsString() : "";
	}

	private static int intOf(JsonObject o, String k) {
		try {
			return o.has(k) && !o.get(k).isJsonNull() ? o.get(k).getAsInt() : 0;
		} catch (Exception e) {
			return 0;
		}
	}

	private static double dbl(JsonObject o, String k) {
		try {
			return o.has(k) && !o.get(k).isJsonNull() ? o.get(k).getAsDouble() : 0;
		} catch (Exception e) {
			return 0;
		}
	}

	private static String firstNonEmpty(String a, String b) {
		return a != null && a.length() > 0 ? a : (b == null ? "" : b);
	}

	/* planned departure epoch (ms) -> that calendar day; fallback to now */
	private static long startOfDayFromPlanned(JsonObject it) {
		long ms = 0;
		try {
			if (it.has("plannedDepartureTime") && !it.get("plannedDepartureTime").isJsonNull())
				ms = it.get("plannedDepartureTime").getAsLong();
		} catch (Exception e) {
		}
		if (ms == 0) {
			try {
				if (it.has("itineraryStartTime") && !it.get("itineraryStartTime").isJsonNull())
					ms = it.get("itineraryStartTime").getAsLong();
			} catch (Exception e) {
			}
		}
		return ms;
	}

	private static Timestamp epochMsToTs(long ms) {
		return ms > 0 ? new Timestamp(ms) : null;
	}

	private static int[] weekYear(Timestamp ts) {
		java.util.GregorianCalendar cal = new java.util.GregorianCalendar();
		cal.setTime(ts);
		cal.setMinimalDaysInFirstWeek(4);
		cal.setFirstDayOfWeek(java.util.Calendar.MONDAY);
		int wk = cal.get(java.util.Calendar.WEEK_OF_YEAR);
		int yr = cal.get(java.util.Calendar.YEAR);
		return new int[] { wk, yr };
	}
}
