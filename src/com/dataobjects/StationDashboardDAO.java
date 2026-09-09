package com.dataobjects;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import com.beans.SearchBean;

/**
 * Station Dashboard (REV C) — assembles fleetdb analytics as JSON.
 *
 * Bootstrap JSON rides in searchBean.transMap("bootstrapJson") and powers
 * the initial render of every tab. Per-card week dropdowns and the DA
 * profile re-query through getAjaxRequestTypeResp(requestType="dash").
 *
 * Scorecard weeks are deduped: uploads can bundle several weeks or repeat
 * a week (2026 W25 has 456 rows), so every weekly read takes the latest
 * row per TRANSPORTERID via MAX(DASHBOARD_OVERVIEWID) / MAX(id) subjoins.
 * DA identity across tables: TRANSPORTERID when present, else
 * TRIM(UPPER(name)) against employee.FULLNAME.
 */
public class StationDashboardDAO extends MVPGDAO {

	/* ── JSON helpers (no JSON lib in this app) ─────────────── */
	private String js(String s) {
		if (s == null) return "\"\"";
		StringBuilder b = new StringBuilder("\"");
		for (int i = 0; i < s.length(); i++) {
			char c = s.charAt(i);
			if (c == '"') b.append("\\\"");
			else if (c == '\\') b.append("\\\\");
			else if (c == '\n' || c == '\r') b.append(' ');
			else if (c == '<') b.append("\\u003C");
			else if (c >= 32) b.append(c);
		}
		return b.append('"').toString();
	}

	private String jn(String v) { /* number-or-empty-string */
		if (v == null || v.trim().length() == 0) return "\"\"";
		try { Double.parseDouble(v.trim()); return v.trim(); }
		catch (Exception e) { return js(v.trim()); }
	}

	private String d(List row, int i) {
		if (row == null || i >= row.size() || row.get(i) == null) return "";
		return row.get(i).toString().trim();
	}

	/* Scorecard ("Amazon") week: Sunday-started, week 1 contains Jan 1 even
	   when partial. Equals MySQL WEEK(d,0), +1 unless Jan 1 is a Sunday. */
	private String awk(String col) {
		return "(WEEK(" + col + ",0) + (DAYOFWEEK(MAKEDATE(YEAR(" + col + "),1))!=1))";
	}

	/* latest row per transporter for one scorecard week */
	private String dedupJoin(String y, String w, String entityID) {
		return " JOIN (SELECT MAX(DASHBOARD_OVERVIEWID) MID FROM dashboard_overview "
				+ "WHERE DASHBOARD_YEAR=" + y + " AND DASHBOARD_WEEK=" + w
				+ " AND ENTITYID=" + entityID + " AND STATUS!=1 GROUP BY TRANSPORTERID) DD "
				+ "ON DD.MID=O.DASHBOARD_OVERVIEWID ";
	}

	private String qualDedupJoin(String y, String w, String entityID) {
		return " JOIN (SELECT MAX(QUALITY_OVERVIEWID) MID FROM quality_overview "
				+ "WHERE QUALITY_YEAR=" + y + " AND QUALITY_WEEK=" + w
				+ " AND ENTITYID=" + entityID + " AND STATUS!=1 GROUP BY TRANSPORTERID) DD "
				+ "ON DD.MID=Q.QUALITY_OVERVIEWID ";
	}

	/* ── page entry ─────────────────────────────────────────── */
	@Override
	public SearchBean searchRecords(SearchBean searchBean, String recordID,
			String loginUser, String loginUserRoles, String loginUserID,
			String entityID) throws Exception {

		searchBean.setDisplayName("MVPx Dashboard");
		searchBean.setController("StationDashboard");
		searchBean.setLabelsList(new ArrayList<String>());
		searchBean.setDataList(new ArrayList());

		Map transMap = searchBean.getTransMap() == null ? new HashMap()
				: searchBean.getTransMap();
		transMap.put("bootstrapJson", buildBootstrap(entityID));
		searchBean.setTransMap(transMap);
		return searchBean;
	}

	private String buildBootstrap(String entityID) throws Exception {
		/* weeks present on the scorecard, newest first */
		List wkList = db.selectAsList("SELECT DISTINCT DASHBOARD_YEAR, DASHBOARD_WEEK "
				+ "FROM dashboard_overview WHERE ENTITYID=" + entityID
				+ " AND STATUS!=1 ORDER BY 1 DESC, 2 DESC LIMIT 20", 2);
		if (wkList.isEmpty()) return "{\"empty\":true}";
		String y = d((List) wkList.get(0), 0), w = d((List) wkList.get(0), 1);

		StringBuilder o = new StringBuilder("{");
		o.append("\"latest\":{\"y\":").append(y).append(",\"w\":").append(w).append("},");
		o.append("\"weeks\":[");
		for (int i = 0; i < wkList.size(); i++) {
			List r = (List) wkList.get(i);
			o.append(i > 0 ? "," : "").append("{\"y\":").append(d(r, 0))
					.append(",\"w\":").append(d(r, 1)).append("}");
		}
		o.append("],");

		o.append("\"core\":").append(buildCore(y, w, entityID)).append(",");
		o.append("\"league\":").append(buildLeague(y, w, entityID)).append(",");
		o.append("\"ops\":").append(buildOps(entityID)).append(",");
		o.append("\"trends\":").append(buildTrends(entityID)).append(",");
		o.append("\"coach\":").append(buildCoach(y, w, entityID)).append(",");
		o.append("\"employees\":").append(buildEmployees(entityID));
		o.append("}");
		return o.toString();
	}

	/* previous scorecard week on file before (y,w) — respects upload gaps */
	private String[] prevWeek(String y, String w, String entityID) throws Exception {
		List r = db.selectAsList("SELECT DASHBOARD_YEAR, DASHBOARD_WEEK FROM dashboard_overview "
				+ "WHERE ENTITYID=" + entityID + " AND STATUS!=1 AND (DASHBOARD_YEAR<" + y
				+ " OR (DASHBOARD_YEAR=" + y + " AND DASHBOARD_WEEK<" + w + ")) "
				+ "ORDER BY 1 DESC, 2 DESC LIMIT 1", 2);
		if (r.isEmpty()) return null;
		return new String[] { d((List) r.get(0), 0), d((List) r.get(0), 1) };
	}

	private String weekCounts(String y, String w, String entityID) throws Exception {
		/* one week's operational counts as a JSON fragment */
		List r = db.selectAsList("SELECT ROUND(AVG(O.OVERALLSCORE),1), SUM(O.DELIVEREDPACKAGES), "
				+ "COUNT(*) FROM dashboard_overview O " + dedupJoin(y, w, entityID), 3);
		List k = r.isEmpty() ? null : (List) r.get(0);

		r = db.selectAsList("SELECT COUNT(*) FROM safety_dashboard WHERE ENTITYID=" + entityID
				+ " AND STATUS!=1 AND SAFTY_WEEK=" + w + " AND YEAR(SAFTY_DATE)=" + y, 1);
		String saf = d((List) r.get(0), 0);

		/* rescue incidents: the row's employee is the DA whose route was
		   rescued — legs = rows, routes = one per DA per day, DAs = distinct */
		r = db.selectAsList("SELECT COUNT(*), COUNT(DISTINCT I.EMPLOYEEID), "
				+ "COUNT(DISTINCT CONCAT(I.EMPLOYEEID,'-',DATE(I.INCIDENT_DATE))) "
				+ "FROM incidents I JOIN incidenttype T ON I.INCIDENTTYPEID=T.INCIDENTTYPEID "
				+ "WHERE I.ENTITYID=" + entityID + " AND I.STATUS!=1 AND T.TYPE LIKE '%Rescue%' "
				+ "AND " + awk("I.INCIDENT_DATE") + "=" + w + " AND YEAR(I.INCIDENT_DATE)=" + y, 3);
		List rc = r.isEmpty() ? null : (List) r.get(0);

		r = db.selectAsList("SELECT COUNT(*) FROM dailyroutes WHERE ENTITYID=" + entityID
				+ " AND STATUS!=1 AND ROUTE_WEEK=" + w + " AND ROUTE_YEAR=" + y, 1);
		String trips = d((List) r.get(0), 0);

		/* dispatched: the Quality DCR weekly upload is authoritative; the
		   itinerary sum only covers days that have itineraries on file */
		r = db.selectAsList("SELECT SUM(DISPATCHED) FROM quality_dcr_weekly WHERE ENTITYID=" + entityID
				+ " AND STATUS!=1 AND DCR_WEEK=" + w + " AND DCR_YEAR=" + y, 1);
		String disp = d((List) r.get(0), 0);
		if (disp.length() == 0 || "0".equals(disp)) {
			r = db.selectAsList("SELECT SUM(TOALPACKAGES) FROM daily_itineraries WHERE ENTITYID=" + entityID
					+ " AND STATUS!=1 AND ITINARARY_WEEK=" + w + " AND ITINARARY_YEAR=" + y, 1);
			disp = d((List) r.get(0), 0);
		}

		r = db.selectAsList("SELECT COUNT(DISTINCT C.EMPLOYEEID) FROM dacheckin C "
				+ "JOIN vehicle V ON C.VEHICLEID=V.VEHICLEID WHERE C.ENTITYID=" + entityID
				+ " AND C.STATUS!=1 AND V.VEHICLENUMBER LIKE 'Extra%' AND YEAR(C.CLOCKINTIME)=" + y
				+ " AND " + awk("C.CLOCKINTIME") + "=" + w, 1);
		String extra = d((List) r.get(0), 0);

		/* Flex app (daily_itineraries): route count, on-clock hours, >40hr DAs */
		r = db.selectAsList("SELECT COUNT(*), "
				+ "ROUND(SUM(TIMESTAMPDIFF(MINUTE, APP_SIGNIN, APP_SIGNOUT))/60,0) "
				+ "FROM daily_itineraries WHERE ENTITYID=" + entityID + " AND STATUS!=1 "
				+ "AND ITINARARY_WEEK=" + w + " AND ITINARARY_YEAR=" + y, 2);
		List it = r.isEmpty() ? null : (List) r.get(0);
		String routes = d(it, 0);
		if ("0".equals(routes) || routes.length() == 0) routes = trips;

		r = db.selectAsList("SELECT COUNT(*) FROM (SELECT TRANSPORTERID, "
				+ "SUM(TIMESTAMPDIFF(MINUTE, APP_SIGNIN, APP_SIGNOUT))/60 H "
				+ "FROM daily_itineraries WHERE ENTITYID=" + entityID + " AND STATUS!=1 "
				+ "AND ITINARARY_WEEK=" + w + " AND ITINARARY_YEAR=" + y
				+ " GROUP BY TRANSPORTERID HAVING H>40) X", 1);
		String over40 = d((List) r.get(0), 0);

		return "\"score\":" + jn(d(k, 0)) + ",\"pkgs\":" + jn(d(k, 1)) + ",\"das\":" + jn(d(k, 2))
				+ ",\"safety\":" + jn(saf) + ",\"rescues\":" + jn(d(rc, 0))
				+ ",\"rescDas\":" + jn(d(rc, 1)) + ",\"rescRoutes\":" + jn(d(rc, 2))
				+ ",\"trips\":" + jn(trips) + ",\"dispatched\":" + jn(disp)
				+ ",\"extraDas\":" + jn(extra) + ",\"routes\":" + jn(routes)
				+ ",\"flexHrs\":" + jn(d(it, 1)) + ",\"over40\":" + jn(over40);
	}

	private String standingsJson(String y, String w, String entityID) throws Exception {
		List r = db.selectAsList("SELECT IFNULL(O.OVERALLSTANDING,'(none)'), COUNT(*) "
				+ "FROM dashboard_overview O " + dedupJoin(y, w, entityID)
				+ "GROUP BY 1 ORDER BY 2 DESC", 2);
		StringBuilder o = new StringBuilder("[");
		for (int i = 0; i < r.size(); i++) {
			List t = (List) r.get(i);
			o.append(i > 0 ? "," : "").append("{\"n\":").append(js(d(t, 0)))
					.append(",\"c\":").append(jn(d(t, 1))).append("}");
		}
		return o.append("]").toString();
	}

	/* KPIs + standings + focus areas + quality + survey for one week,
	   each paired with the previous scorecard week for comparison */
	private String buildCore(String y, String w, String entityID) throws Exception {
		StringBuilder o = new StringBuilder("{\"y\":" + y + ",\"w\":" + w + ",");

		o.append(weekCounts(y, w, entityID)).append(",");

		String[] pv = prevWeek(y, w, entityID);
		if (pv != null) {
			o.append("\"py\":").append(pv[0]).append(",\"pw\":").append(pv[1]).append(",\"prev\":{")
					.append(weekCounts(pv[0], pv[1], entityID)).append("},");
			o.append("\"prevStandings\":").append(standingsJson(pv[0], pv[1], entityID)).append(",");
		} else {
			o.append("\"prev\":null,\"prevStandings\":[],");
		}

		List r = db.selectAsList("SELECT COUNT(*) FROM coaching_followup WHERE STATUS=0", 1);
		o.append("\"coachOpen\":").append(jn(d((List) r.get(0), 0))).append(",");

		o.append("\"standings\":").append(standingsJson(y, w, entityID)).append(",");

		/* quality strip from quality_overview — uploads lag the scorecard, so
		   fall back to the latest quality week at or before the requested one */
		String qy = y, qw = w;
		r = db.selectAsList("SELECT QUALITY_YEAR, QUALITY_WEEK FROM quality_overview "
				+ "WHERE ENTITYID=" + entityID + " AND STATUS!=1 AND QUALITY_WEEK<=53 "
				+ "AND (QUALITY_YEAR<" + y + " OR (QUALITY_YEAR=" + y + " AND QUALITY_WEEK<=" + w + ")) "
				+ "ORDER BY QUALITY_YEAR DESC, QUALITY_WEEK DESC LIMIT 1", 2);
		if (!r.isEmpty()) {
			qy = d((List) r.get(0), 0);
			qw = d((List) r.get(0), 1);
		}
		o.append("\"qy\":").append(qy).append(",\"qw\":").append(qw).append(",");
		/* DCR/POD are stored as 0–1 fractions; DSB & CDF_DPMO are per-DA rates
		   (average, never sum); DNR DPMO is derived from counts */
		r = db.selectAsList("SELECT ROUND(AVG(Q.DCR)*100,1), SUM(Q.POD_SUCCESS), SUM(Q.POD_OPPORTUNITIES), "
				+ "SUM(Q.DNR), ROUND(SUM(Q.DNR)/NULLIF(SUM(Q.PACKAGESDELIVERED),0)*1000000,0), "
				+ "ROUND(AVG(Q.DSB),0), ROUND(AVG(Q.CDF_DPMO),0), SUM(Q.CED), "
				+ "SUM(Q.PACKAGESDELIVERED), SUM(Q.PACKAGES_RETURNED) "
				+ "FROM quality_overview Q " + qualDedupJoin(qy, qw, entityID), 10);
		List q = r.isEmpty() ? null : (List) r.get(0);
		String podS = d(q, 1), podO = d(q, 2), podPct = "";
		try {
			double s = Double.parseDouble(podS), op = Double.parseDouble(podO);
			if (op > 0) podPct = String.valueOf(Math.round(s / op * 1000) / 10.0);
		} catch (Exception e) { }

		/* exact-week DCR/delivered/returned from the Quality DCR upload beats
		   the quality_overview fallback when that upload lags */
		String dcrV = d(q, 0), delV = d(q, 8), retV = d(q, 9);
		r = db.selectAsList("SELECT ROUND(SUM(DELIVERED)/NULLIF(SUM(DISPATCHED),0)*100,1), "
				+ "SUM(DELIVERED), SUM(RETURNED) FROM quality_dcr_weekly "
				+ "WHERE ENTITYID=" + entityID + " AND STATUS!=1 AND DCR_YEAR=" + y
				+ " AND DCR_WEEK=" + w, 3);
		List xq = r.isEmpty() ? null : (List) r.get(0);
		if (xq != null && d(xq, 1).length() > 0 && !"0".equals(d(xq, 1))) {
			dcrV = d(xq, 0);
			delV = d(xq, 1);
			retV = d(xq, 2);
		}

		/* exact-week POD / CDF DPMO / DSB DPMO come from the weekly scorecard
		   bundle (dashboard_overview); the file's POD column lands in PODOPPS */
		String dsbV = d(q, 5), cdfDpmoV = d(q, 6);
		r = db.selectAsList("SELECT ROUND(AVG(O.PODOPPS),1), ROUND(AVG(O.CDFDPMO),0), "
				+ "ROUND(AVG(O.DSB),0), ROUND(AVG(O.DCR),0) "
				+ "FROM dashboard_overview O " + dedupJoin(y, w, entityID), 4);
		List sq = r.isEmpty() ? null : (List) r.get(0);
		if (d(sq, 0).length() > 0) { podPct = d(sq, 0); podS = ""; podO = ""; }
		if (d(sq, 1).length() > 0) cdfDpmoV = d(sq, 1);
		if (d(sq, 2).length() > 0) dsbV = d(sq, 2);
		if (dcrV.length() == 0 && d(sq, 3).length() > 0) {
			/* scorecard DCR is a DPMO: % = 100 - DPMO/10000 */
			try {
				dcrV = String.valueOf(Math.round(
						(100 - Double.parseDouble(d(sq, 3)) / 10000) * 10) / 10.0);
			} catch (Exception e) { }
		}

		o.append("\"quality\":{\"dcr\":").append(jn(dcrV))
				.append(",\"podPct\":").append(jn(podPct))
				.append(",\"podS\":").append(jn(podS)).append(",\"podO\":").append(jn(podO))
				.append(",\"dnr\":").append(jn(d(q, 3))).append(",\"dnrDpmo\":").append(jn(d(q, 4)))
				.append(",\"dsb\":").append(jn(dsbV)).append(",\"cdfDpmo\":").append(jn(cdfDpmoV))
				.append(",\"ced\":").append(jn(d(q, 7))).append(",\"delivered\":").append(jn(delV))
				.append(",\"returned\":").append(jn(retV)).append(",");

		r = db.selectAsList("SELECT ROUND(AVG(O.SWCCC),1), ROUND(AVG(O.SWCAD),1), "
				+ "SUM(O.CUSTDELIVERYFEEDBACK), SUM(O.CUSTESCALATIONDEFECT) "
				+ "FROM dashboard_overview O " + dedupJoin(y, w, entityID), 4);
		List s2 = r.isEmpty() ? null : (List) r.get(0);
		/* CDF defect count: scorecard column when present, else the CDF
		   detail upload for the same week */
		String cdfDef = d(s2, 2);
		if (cdfDef.length() == 0) {
			r = db.selectAsList("SELECT COUNT(*) FROM cdf_feedback WHERE ENTITYID=" + entityID
					+ " AND STATUS!=1 AND CDF_YEAR=" + y + " AND CDF_WEEK=" + w, 1);
			String c2 = d((List) r.get(0), 0);
			if (!"0".equals(c2)) cdfDef = c2;
		}
		o.append("\"swccc\":").append(jn(d(s2, 0))).append(",\"swcad\":").append(jn(d(s2, 1)))
				.append(",\"cdfDefects\":").append(jn(cdfDef))
				.append(",\"cedDefects\":").append(jn(d(s2, 3))).append("},");

		/* focus areas = DAs whose POD is not 100% or DNR/DSB/CDF is not 0 */
		r = db.selectAsList("SELECT SUM(Q.POD<1), SUM(Q.DNR>0), SUM(Q.DSB>0), SUM(Q.CDF_DPMO>0) "
				+ "FROM quality_overview Q " + qualDedupJoin(qy, qw, entityID), 4);
		List f = r.isEmpty() ? null : (List) r.get(0);
		o.append("\"focus\":[")
				.append("{\"n\":\"POD below 100%\",\"c\":").append(jn(d(f, 0)))
				.append("},{\"n\":\"DNR above 0\",\"c\":").append(jn(d(f, 1)))
				.append("},{\"n\":\"DSB above 0\",\"c\":").append(jn(d(f, 2)))
				.append("},{\"n\":\"CDF defects\",\"c\":").append(jn(d(f, 3)))
				.append("}],");

		/* DA sentiment survey: every month on file (client picks the month) */
		r = db.selectAsList("SELECT SURVEY_YEAR, SURVEY_MONTH, QUESTION, "
				+ "IFNULL(RESPONSE_RATE,''), IFNULL(FAVORABLE_RATE,''), "
				+ "IFNULL(T6M_FAVORABLE_RATE,'') FROM sentiment_survey "
				+ "WHERE ENTITYID=" + entityID + " AND STATUS!=1 "
				+ "ORDER BY SURVEY_YEAR DESC, SURVEY_MONTH DESC, QUESTION LIMIT 200", 6);
		o.append("\"survey\":[");
		for (int i = 0; i < r.size(); i++) {
			List t = (List) r.get(i);
			o.append(i > 0 ? "," : "").append("{\"yr\":").append(jn(d(t, 0)))
					.append(",\"mo\":").append(jn(d(t, 1)))
					.append(",\"q\":").append(js(d(t, 2)))
					.append(",\"resp\":").append(jn(d(t, 3)))
					.append(",\"fav\":").append(jn(d(t, 4)))
					.append(",\"t6m\":").append(jn(d(t, 5))).append("}");
		}
		o.append("]");

		o.append("}");
		return o.toString();
	}

	/* league table rows for one week */
	private String buildLeague(String y, String w, String entityID) throws Exception {
		/* quality per transporter */
		Map<String, String[]> qMap = new HashMap<String, String[]>();
		List r = db.selectAsList("SELECT Q.TRANSPORTERID, ROUND(Q.DCR*100,1), ROUND(Q.POD*100,1), "
				+ "ROUND(Q.DNR/NULLIF(Q.PACKAGESDELIVERED,0)*1000000,0), Q.DSB, "
				+ "Q.CDF_DPMO FROM quality_overview Q " + qualDedupJoin(y, w, entityID), 6);
		for (int i = 0; i < r.size(); i++) {
			List t = (List) r.get(i);
			qMap.put(d(t, 0), new String[] { d(t, 1), d(t, 2), d(t, 3), d(t, 4), d(t, 5) });
		}
		/* no quality_overview for this week: per-DA DCR from the DCR upload */
		if (qMap.isEmpty()) {
			r = db.selectAsList("SELECT TRANSPORTERID, "
					+ "ROUND(SUM(DELIVERED)/NULLIF(SUM(DISPATCHED),0)*100,1) "
					+ "FROM quality_dcr_weekly WHERE ENTITYID=" + entityID
					+ " AND STATUS!=1 AND DCR_YEAR=" + y + " AND DCR_WEEK=" + w
					+ " GROUP BY TRANSPORTERID", 2);
			for (int i = 0; i < r.size(); i++) {
				List t = (List) r.get(i);
				qMap.put(d(t, 0), new String[] { d(t, 1), "", "", "", "" });
			}
		}
		/* safety events per DA name for the week */
		Map<String, String> sMap = new HashMap<String, String>();
		r = db.selectAsList("SELECT TRIM(UPPER(DELIVERYASSOCIATE)), COUNT(*) FROM safety_dashboard "
				+ "WHERE ENTITYID=" + entityID + " AND STATUS!=1 AND SAFTY_WEEK=" + w
				+ " AND YEAR(SAFTY_DATE)=" + y + " GROUP BY 1", 2);
		for (int i = 0; i < r.size(); i++) {
			List t = (List) r.get(i);
			sMap.put(d(t, 0), d(t, 1));
		}
		/* open coaching entries (the league Coach toggle) */
		Map<String, String> cMap = new HashMap<String, String>();
		try {
			r = db.selectAsList("SELECT UPPER(IFNULL(TRANSPORTERID,'')), COUNT(*) FROM coaching_log "
					+ "WHERE ENTITYID=" + entityID + " AND STATUS=0 GROUP BY 1", 2);
			for (int i = 0; i < r.size(); i++) {
				List t = (List) r.get(i);
				cMap.put(d(t, 0), "1");
			}
		} catch (Exception ex) { }

		/* scorecard row also carries per-DA quality when the quality upload
		   lags: POD lands in PODOPPS, DSB & CDF are DPMOs, DCR when present */
		r = db.selectAsList("SELECT O.DELIVERYASSOCIATE, O.TRANSPORTERID, O.OVERALLSTANDING, "
				+ "O.OVERALLSCORE, O.FICO, O.DELIVEREDPACKAGES, "
				+ "ROUND(IFNULL(O.SWCPOD, O.PODOPPS),1), ROUND(O.DSB,0), "
				+ "ROUND(O.CDFDPMO,0), ROUND(O.DCR,0) FROM dashboard_overview O "
				+ dedupJoin(y, w, entityID) + "ORDER BY O.OVERALLSCORE DESC, O.DELIVERYASSOCIATE", 10);
		StringBuilder o = new StringBuilder("[");
		for (int i = 0; i < r.size(); i++) {
			List t = (List) r.get(i);
			String tid = d(t, 1);
			String[] q = qMap.get(tid);
			String sev = sMap.get(d(t, 0).toUpperCase());
			String dcr = q != null && q[0].length() > 0 ? q[0] : d(t, 9);
			String pod = q != null && q[1].length() > 0 ? q[1] : d(t, 6);
			String dsb = q != null && q[3].length() > 0 ? q[3] : d(t, 7);
			String cdf = q != null && q[4].length() > 0 ? q[4] : d(t, 8);
			o.append(i > 0 ? "," : "").append("{\"da\":").append(js(d(t, 0)))
					.append(",\"tid\":").append(js(tid))
					.append(",\"st\":").append(js(d(t, 2)))
					.append(",\"sc\":").append(jn(d(t, 3)))
					.append(",\"fico\":").append(jn(d(t, 4)))
					.append(",\"pkgs\":").append(jn(d(t, 5)))
					.append(",\"dcr\":").append(jn(dcr))
					.append(",\"pod\":").append(jn(pod))
					.append(",\"dnr\":").append(jn(q == null ? "" : q[2]))
					.append(",\"dsb\":").append(jn(dsb))
					.append(",\"cdf\":").append(jn(cdf))
					.append(",\"sev\":").append(jn(sev == null ? "0" : sev))
					.append(",\"coach\":").append(cMap.get(tid.toUpperCase()) != null ? "1" : "0")
					.append("}");
		}
		return o.append("]").toString();
	}

	/* ops pulse: anchors to today when today has activity, else the most
	   recent day that does — a fresh morning no longer reads 0 / 0 */
	private String buildOps(String entityID) throws Exception {
		List r = db.selectAsList("SELECT MAX(DATE(CLOCKINTIME)) FROM dacheckin "
				+ "WHERE ENTITYID=" + entityID + " AND STATUS!=1", 1);
		String anchor = d((List) r.get(0), 0);
		r = db.selectAsList("SELECT CURDATE()", 1);
		String today = d((List) r.get(0), 0);
		if (anchor.length() == 0 || anchor.compareTo(today) > 0) anchor = today;

		StringBuilder o = new StringBuilder("{");
		o.append("\"opsDate\":").append(js(anchor)).append(",");
		o.append("\"opsToday\":").append(anchor.equals(today) ? "true" : "false").append(",");
		r = db.selectAsList("SELECT COUNT(*) FROM dacheckin WHERE ENTITYID=" + entityID
				+ " AND STATUS!=1 AND DATE(CLOCKINTIME)='" + anchor + "'", 1);
		o.append("\"checkedin\":").append(jn(d((List) r.get(0), 0))).append(",");
		/* scheduled: schedule upload first, wave sheet as the fallback */
		r = db.selectAsList("SELECT COUNT(*) FROM employee_schedule WHERE STATUS!=1 "
				+ "AND DATE(SCHEDULEDATE)='" + anchor + "'", 1);
		String sched = d((List) r.get(0), 0);
		if ("0".equals(sched) || sched.length() == 0) {
			try {
				r = db.selectAsList("SELECT COUNT(*) FROM route_assignment WHERE ENTITYID="
						+ entityID + " AND STATUS!=1 AND ASSIGN_DATE='" + anchor + "'", 1);
				String ra = d((List) r.get(0), 0);
				if (!"0".equals(ra) && ra.length() > 0) sched = ra;
			} catch (Exception ex) { }
		}
		o.append("\"scheduled\":").append(jn(sched)).append(",");
		r = db.selectAsList("SELECT COUNT(*) FROM daconfirmation WHERE ENTITYID=" + entityID
				+ " AND STATUS!=1 AND DATE(SCHEDULEDATE)=DATE_ADD('" + anchor + "', INTERVAL 1 DAY) "
				+ "AND CONFIRMATION LIKE '%onfirm%'", 1);
		o.append("\"confTomorrow\":").append(jn(d((List) r.get(0), 0))).append(",");
		r = db.selectAsList("SELECT COUNT(*) FROM incidents I JOIN incidenttype T ON "
				+ "I.INCIDENTTYPEID=T.INCIDENTTYPEID WHERE I.ENTITYID=" + entityID
				+ " AND I.STATUS!=1 AND T.TYPE LIKE '%Call Out%' AND DATE(I.INCIDENT_DATE)='"
				+ anchor + "'", 1);
		o.append("\"callouts\":").append(jn(d((List) r.get(0), 0))).append("}");
		return o.toString();
	}

	/* weekly series for the Trends tab + safety mix + write-ups */
	private String buildTrends(String entityID) throws Exception {
		StringBuilder o = new StringBuilder("{");

		List r = db.selectAsList("SELECT O.DASHBOARD_YEAR, O.DASHBOARD_WEEK, "
				+ "ROUND(AVG(O.OVERALLSCORE),1), SUM(O.DELIVEREDPACKAGES) FROM dashboard_overview O "
				+ "JOIN (SELECT MAX(DASHBOARD_OVERVIEWID) MID FROM dashboard_overview WHERE ENTITYID=" + entityID
				+ " AND STATUS!=1 GROUP BY DASHBOARD_YEAR, DASHBOARD_WEEK, TRANSPORTERID) DD "
				+ "ON DD.MID=O.DASHBOARD_OVERVIEWID GROUP BY 1,2 ORDER BY 1 DESC,2 DESC LIMIT 14", 4);
		o.append("\"score\":[");
		for (int i = r.size() - 1, n = 0; i >= 0; i--, n++) {
			List t = (List) r.get(i);
			o.append(n > 0 ? "," : "").append("{\"y\":").append(d(t, 0)).append(",\"w\":").append(d(t, 1))
					.append(",\"v\":").append(jn(d(t, 2))).append(",\"p\":").append(jn(d(t, 3))).append("}");
		}
		o.append("],");

		r = db.selectAsList("SELECT YEAR(SAFTY_DATE), SAFTY_WEEK, COUNT(*) FROM safety_dashboard "
				+ "WHERE ENTITYID=" + entityID + " AND STATUS!=1 GROUP BY 1,2 ORDER BY 1 DESC,2 DESC LIMIT 120", 3);
		o.append("\"safety\":[");
		for (int i = r.size() - 1, n = 0; i >= 0; i--, n++) {
			List t = (List) r.get(i);
			o.append(n > 0 ? "," : "").append("{\"y\":").append(d(t, 0)).append(",\"w\":").append(d(t, 1))
					.append(",\"v\":").append(jn(d(t, 2))).append("}");
		}
		o.append("],");

		/* rescues / call-outs / lates per week (last 13 with any) */
		o.append("\"inc\":[");
		r = db.selectAsList("SELECT YEAR(I.INCIDENT_DATE), " + awk("I.INCIDENT_DATE") + ", "
				+ "SUM(T.TYPE LIKE '%Rescue%'), SUM(T.TYPE LIKE '%Call Out%'), SUM(T.TYPE LIKE '%Late%') "
				+ "FROM incidents I JOIN incidenttype T ON I.INCIDENTTYPEID=T.INCIDENTTYPEID "
				+ "WHERE I.ENTITYID=" + entityID + " AND I.STATUS!=1 "
				+ "GROUP BY 1,2 ORDER BY 1 DESC,2 DESC LIMIT 13", 5);
		for (int i = r.size() - 1, n = 0; i >= 0; i--, n++) {
			List t = (List) r.get(i);
			o.append(n > 0 ? "," : "").append("{\"y\":").append(d(t, 0)).append(",\"w\":").append(d(t, 1))
					.append(",\"r\":").append(jn(d(t, 2))).append(",\"c\":").append(jn(d(t, 3)))
					.append(",\"l\":").append(jn(d(t, 4))).append("}");
		}
		o.append("],");

		r = db.selectAsList("SELECT METRICTYPE, COUNT(*) FROM safety_dashboard WHERE ENTITYID="
				+ entityID + " AND STATUS!=1 GROUP BY 1 ORDER BY 2 DESC LIMIT 6", 2);
		o.append("\"safetyMix\":[");
		for (int i = 0; i < r.size(); i++) {
			List t = (List) r.get(i);
			o.append(i > 0 ? "," : "").append("{\"n\":").append(js(d(t, 0)))
					.append(",\"c\":").append(jn(d(t, 1))).append("}");
		}
		o.append("]}");
		return o.toString();
	}

	/* coaching queue + open coaching log + write-ups + escalations */
	private String buildCoach(String y, String w, String entityID) throws Exception {
		StringBuilder o = new StringBuilder("{");

		/* open coaching entries with their conversation notes */
		o.append("\"log\":[");
		try {
			List lr = db.selectAsList("SELECT L.COACHING_LOGID, IFNULL(E.FULLNAME, L.TRANSPORTERID), "
					+ "IFNULL(L.TRANSPORTERID,''), IFNULL(L.CATEGORY,'Other'), IFNULL(L.SOURCE,''), "
					+ "IFNULL(L.REASON,''), IFNULL(DATE_FORMAT(L.OPENED_DATE,'%m/%d'),'') "
					+ "FROM coaching_log L LEFT JOIN employee E ON E.EMPLOYEEID=L.EMPLOYEEID "
					+ "WHERE L.ENTITYID=" + entityID + " AND L.STATUS=0 "
					+ "ORDER BY L.CATEGORY, L.OPENED_DATE DESC LIMIT 60", 7);
			for (int i = 0; i < lr.size(); i++) {
				List t = (List) lr.get(i);
				String logID = d(t, 0);
				o.append(i > 0 ? "," : "").append("{\"id\":").append(jn(logID))
						.append(",\"nm\":").append(js(d(t, 1)))
						.append(",\"tid\":").append(js(d(t, 2)))
						.append(",\"cat\":").append(js(d(t, 3)))
						.append(",\"src\":").append(js(d(t, 4)))
						.append(",\"rsn\":").append(js(d(t, 5)))
						.append(",\"dt\":").append(js(d(t, 6)))
						.append(",\"notes\":[");
				List nr = db.selectAsList("SELECT IFNULL(DATE_FORMAT(CREATE_DATE,'%m/%d %l:%i %p'),''), "
						+ "IFNULL(CREATE_USER,''), IFNULL(NOTE,'') FROM coaching_notes "
						+ "WHERE COACHING_LOGID=" + logID + " AND STATUS!=1 "
						+ "ORDER BY COACHING_NOTEID DESC LIMIT 10", 3);
				for (int j = 0; j < nr.size(); j++) {
					List nt = (List) nr.get(j);
					o.append(j > 0 ? "," : "").append("{\"d\":").append(js(d(nt, 0)))
							.append(",\"u\":").append(js(d(nt, 1)))
							.append(",\"m\":").append(js(d(nt, 2))).append("}");
				}
				o.append("]}");
			}
		} catch (Exception ex) { }
		o.append("],");

		/* queue: KFA set, or Fair/Poor standing, or >=3 camera events this week */
		List r = db.selectAsList("SELECT O.DELIVERYASSOCIATE, O.TRANSPORTERID, O.OVERALLSTANDING, "
				+ "O.KEYFOCUSAREA, IFNULL(S.EV,0) FROM dashboard_overview O "
				+ dedupJoin(y, w, entityID)
				+ "LEFT JOIN (SELECT TRIM(UPPER(DELIVERYASSOCIATE)) NM, COUNT(*) EV FROM safety_dashboard "
				+ "WHERE ENTITYID=" + entityID + " AND STATUS!=1 AND SAFTY_WEEK=" + w
				+ " AND YEAR(SAFTY_DATE)=" + y + " GROUP BY 1) S ON S.NM=TRIM(UPPER(O.DELIVERYASSOCIATE)) "
				+ "WHERE (O.KEYFOCUSAREA IS NOT NULL AND O.KEYFOCUSAREA!='') "
				+ "OR O.OVERALLSTANDING IN ('Fair','Poor') OR IFNULL(S.EV,0)>=3 "
				+ "ORDER BY IFNULL(S.EV,0) DESC, O.OVERALLSCORE ASC LIMIT 12", 5);
		o.append("\"queue\":[");
		for (int i = 0; i < r.size(); i++) {
			List t = (List) r.get(i);
			o.append(i > 0 ? "," : "").append("{\"da\":").append(js(d(t, 0)))
					.append(",\"tid\":").append(js(d(t, 1))).append(",\"st\":").append(js(d(t, 2)))
					.append(",\"kfa\":").append(js(d(t, 3))).append(",\"ev\":").append(jn(d(t, 4))).append("}");
		}
		o.append("],");

		/* coached incidents by week (quality vs safety), last 13 wks */
		r = db.selectAsList("SELECT YEAR(I.INCIDENT_DATE), " + awk("I.INCIDENT_DATE") + ", "
				+ "SUM(T.TYPE LIKE '%Coached%Quality%'), SUM(T.TYPE LIKE '%Coached%Safety%') "
				+ "FROM incidents I JOIN incidenttype T ON I.INCIDENTTYPEID=T.INCIDENTTYPEID "
				+ "WHERE I.ENTITYID=" + entityID + " AND I.STATUS!=1 AND T.TYPE LIKE '%Coached%' "
				+ "GROUP BY 1,2 ORDER BY 1 DESC,2 DESC LIMIT 13", 4);
		o.append("\"coachWk\":[");
		for (int i = r.size() - 1, n = 0; i >= 0; i--, n++) {
			List t = (List) r.get(i);
			o.append(n > 0 ? "," : "").append("{\"y\":").append(d(t, 0)).append(",\"w\":").append(d(t, 1))
					.append(",\"q\":").append(jn(d(t, 2))).append(",\"s\":").append(jn(d(t, 3))).append("}");
		}
		o.append("],");

		/* write-ups by week: safety category vs other */
		r = db.selectAsList("SELECT YEAR(F.CREATE_DATE), " + awk("F.CREATE_DATE") + ", "
				+ "SUM(T.FORMTYPE LIKE '%Safety%'), SUM(T.FORMTYPE NOT LIKE '%Safety%') "
				+ "FROM employeeforms F JOIN formstemplate T ON F.FORMSTEMPLATEID=T.FORMSTEMPLATEID "
				+ "WHERE F.STATUS!=1 GROUP BY 1,2 ORDER BY 1 DESC,2 DESC LIMIT 13", 4);
		o.append("\"writeupWk\":[");
		for (int i = r.size() - 1, n = 0; i >= 0; i--, n++) {
			List t = (List) r.get(i);
			o.append(n > 0 ? "," : "").append("{\"y\":").append(d(t, 0)).append(",\"w\":").append(d(t, 1))
					.append(",\"s\":").append(jn(d(t, 2))).append(",\"o\":").append(jn(d(t, 3))).append("}");
		}
		o.append("],");

		/* write-up categories, all time */
		r = db.selectAsList("SELECT CASE WHEN T.FORMTYPE LIKE '%Termination%' THEN 'TERMINATION' "
				+ "WHEN T.FORMTYPE LIKE '%Safety%' THEN 'SAFETY' "
				+ "WHEN T.FORMTYPE LIKE '%Vehicle%' THEN 'VEHICLE DAMAGE' "
				+ "WHEN T.FORMTYPE LIKE '%Quality%' THEN 'QUALITY' "
				+ "WHEN T.FORMTYPE LIKE '%rescue%' THEN 'RESCUE/ROUTE' ELSE 'CONDUCT' END, COUNT(*) "
				+ "FROM employeeforms F JOIN formstemplate T ON F.FORMSTEMPLATEID=T.FORMSTEMPLATEID "
				+ "WHERE F.STATUS!=1 GROUP BY 1 ORDER BY 2 DESC", 2);
		o.append("\"writeupCats\":[");
		for (int i = 0; i < r.size(); i++) {
			List t = (List) r.get(i);
			o.append(i > 0 ? "," : "").append("{\"n\":").append(js(d(t, 0)))
					.append(",\"c\":").append(jn(d(t, 1))).append("}");
		}
		o.append("],");

		/* recent escalations — ESCALATION_WEEK (SCORECARD_WEEK is mostly 0),
		   newest incident first, duplicate upload rows collapsed */
		r = db.selectAsList("SELECT E.ESCALATION_WEEK, E.CATEGORY, E.DELIVERYASSOCIATE, E.BUCKET, "
				+ "E.DSP_APPEALED, MAX(E.INCIDENT_DATE) DT FROM escalations E WHERE E.ENTITYID=" + entityID
				+ " AND E.STATUS!=1 GROUP BY 1,2,3,4,5 ORDER BY DT DESC LIMIT 8", 6);
		o.append("\"escal\":[");
		for (int i = 0; i < r.size(); i++) {
			List t = (List) r.get(i);
			o.append(i > 0 ? "," : "").append("{\"wk\":").append(jn(d(t, 0)))
					.append(",\"cat\":").append(js(d(t, 1))).append(",\"da\":").append(js(d(t, 2)))
					.append(",\"bkt\":").append(js(d(t, 3))).append(",\"ap\":").append(js(d(t, 4))).append("}");
		}
		o.append("]}");
		return o.toString();
	}

	private String buildEmployees(String entityID) throws Exception {
		List r = db.selectAsList("SELECT EMPLOYEEID, FULLNAME FROM employee WHERE ENTITYID="
				+ entityID + " AND STATUS=0 ORDER BY FULLNAME", 2);
		StringBuilder o = new StringBuilder("[");
		for (int i = 0; i < r.size(); i++) {
			List t = (List) r.get(i);
			o.append(i > 0 ? "," : "").append("{\"id\":").append(jn(d(t, 0)))
					.append(",\"nm\":").append(js(d(t, 1))).append("}");
		}
		return o.append("]").toString();
	}

	/* ── AJAX: per-card week changes + DA profile ───────────── */
	@Override
	public String getAjaxRequestTypeResp(String requestType,
			Map<String, String> requestMap, String loginUser,
			String loginUserRoles, String loginUserID, String entityID)
			throws Exception {

		/* coaching log actions (league toggle + coaching tab) */
		if ("coachToggle".equalsIgnoreCase(requestType)) {
			String tid = requestMap.get("tid") == null ? "" : requestMap.get("tid").trim().replace("''", "'");
			String on = requestMap.get("on") == null ? "" : requestMap.get("on").trim();
			if (tid.length() == 0 || !on.matches("[01]"))
				return "<status>false</status><mesg>Bad request</mesg>";
			String tidEsc = tid.replaceAll("'", "''");
			String empID = db.selectById("SELECT MAX(EMPLOYEEID) FROM employee WHERE STATUS!=1 "
					+ "AND UPPER(TRANSPORTERID)=UPPER('" + tidEsc + "') AND ENTITYID=" + entityID);
			boolean ok;
			if ("1".equals(on)) {
				ok = db.update("INSERT INTO coaching_log (ENTITYID, EMPLOYEEID, TRANSPORTERID, "
						+ "CATEGORY, SOURCE, REASON, OPENED_DATE, CREATE_USER, CREATE_DATE, STATUS) VALUES ("
						+ entityID + ", " + (empID.length() > 0 ? empID : "NULL") + ", '" + tidEsc
						+ "', 'Other', 'League toggle', '', " + db.getInsertSysdate() + ", "
						+ db.getInsertDBValue(loginUser) + ", " + db.getInsertSysdate() + ", 0)");
			} else {
				ok = db.update("UPDATE coaching_log SET STATUS=3, COMPLETED_DATE=" + db.getInsertSysdate()
						+ ", UPDATE_USER=" + db.getInsertDBValue(loginUser) + ", UPDATE_DATE="
						+ db.getInsertSysdate() + " WHERE ENTITYID=" + entityID
						+ " AND STATUS=0 AND UPPER(TRANSPORTERID)=UPPER('" + tidEsc + "')");
			}
			return ok ? "<status>true</status><mesg>Coaching " + ("1".equals(on) ? "opened" : "completed")
					+ "</mesg>" : "<status>false</status><mesg>Update failed</mesg>";
		}
		if ("coachCat".equalsIgnoreCase(requestType)) {
			String id = requestMap.get("logID") == null ? "" : requestMap.get("logID").trim();
			String cat = requestMap.get("cat") == null ? "" : requestMap.get("cat").trim();
			if (!id.matches("\\d+") || !cat.matches("Safety|Quality|Other"))
				return "<status>false</status><mesg>Bad request</mesg>";
			boolean ok = db.update("UPDATE coaching_log SET CATEGORY='" + cat + "', UPDATE_USER="
					+ db.getInsertDBValue(loginUser) + ", UPDATE_DATE=" + db.getInsertSysdate()
					+ " WHERE COACHING_LOGID=" + id);
			return ok ? "<status>true</status><mesg>Category updated</mesg>"
					: "<status>false</status><mesg>Update failed</mesg>";
		}
		if ("coachNote".equalsIgnoreCase(requestType)) {
			String id = requestMap.get("logID") == null ? "" : requestMap.get("logID").trim();
			String note = requestMap.get("note") == null ? "" : requestMap.get("note").trim().replace("''", "'");
			if (!id.matches("\\d+") || note.length() == 0)
				return "<status>false</status><mesg>Type a note first</mesg>";
			boolean ok = db.update("INSERT INTO coaching_notes (COACHING_LOGID, NOTE, CREATE_USER, "
					+ "CREATE_DATE, STATUS) VALUES (" + id + ", " + db.getInsertDBValue(note) + ", "
					+ db.getInsertDBValue(loginUser) + ", " + db.getInsertSysdate() + ", 0)");
			return ok ? "<status>true</status><mesg>Note added</mesg>"
					: "<status>false</status><mesg>Save failed</mesg>";
		}
		if ("coachClose".equalsIgnoreCase(requestType)) {
			String id = requestMap.get("logID") == null ? "" : requestMap.get("logID").trim();
			if (!id.matches("\\d+"))
				return "<status>false</status><mesg>Bad request</mesg>";
			boolean ok = db.update("UPDATE coaching_log SET STATUS=3, COMPLETED_DATE="
					+ db.getInsertSysdate() + ", UPDATE_USER=" + db.getInsertDBValue(loginUser)
					+ ", UPDATE_DATE=" + db.getInsertSysdate() + " WHERE COACHING_LOGID=" + id);
			return ok ? "<status>true</status><mesg>Coaching completed</mesg>"
					: "<status>false</status><mesg>Update failed</mesg>";
		}
		if ("coachStart".equalsIgnoreCase(requestType)) {
			String tid = requestMap.get("tid") == null ? "" : requestMap.get("tid").trim().replace("''", "'");
			String cat = requestMap.get("cat") == null ? "Other" : requestMap.get("cat").trim();
			String reason = requestMap.get("reason") == null ? "" : requestMap.get("reason").trim().replace("''", "'");
			if (tid.length() == 0 || !cat.matches("Safety|Quality|Other"))
				return "<status>false</status><mesg>Bad request</mesg>";
			String tidEsc = tid.replaceAll("'", "''");
			String empID = db.selectById("SELECT MAX(EMPLOYEEID) FROM employee WHERE STATUS!=1 "
					+ "AND UPPER(TRANSPORTERID)=UPPER('" + tidEsc + "') AND ENTITYID=" + entityID);
			boolean ok = db.update("INSERT INTO coaching_log (ENTITYID, EMPLOYEEID, TRANSPORTERID, "
					+ "CATEGORY, SOURCE, REASON, OPENED_DATE, CREATE_USER, CREATE_DATE, STATUS) VALUES ("
					+ entityID + ", " + (empID.length() > 0 ? empID : "NULL") + ", '" + tidEsc + "', '"
					+ cat + "', 'Queue', " + db.getInsertDBValue(reason) + ", " + db.getInsertSysdate()
					+ ", " + db.getInsertDBValue(loginUser) + ", " + db.getInsertSysdate() + ", 0)");
			return ok ? "<status>true</status><mesg>Coaching opened</mesg>"
					: "<status>false</status><mesg>Save failed</mesg>";
		}

		if (!"dash".equalsIgnoreCase(requestType)) return "";
		String panel = requestMap.get("panel") == null ? "" : requestMap.get("panel").trim();
		String y = requestMap.get("y") == null ? "" : requestMap.get("y").trim();
		String w = requestMap.get("w") == null ? "" : requestMap.get("w").trim();
		if (!y.matches("\\d{4}") || !w.matches("\\d{1,2}")) return "{}";

		if ("core".equalsIgnoreCase(panel)) return buildCore(y, w, entityID);
		if ("league".equalsIgnoreCase(panel)) return buildLeague(y, w, entityID);
		if ("coach".equalsIgnoreCase(panel)) return buildCoach(y, w, entityID);
		if ("safmix".equalsIgnoreCase(panel)) {
			/* safety event mix for one week (the Trends dropdown) */
			List r2 = db.selectAsList("SELECT UPPER(IFNULL(METRICTYPE,'OTHER')), COUNT(*) "
					+ "FROM safety_dashboard WHERE ENTITYID=" + entityID
					+ " AND STATUS!=1 AND SAFTY_WEEK=" + w + " AND YEAR(SAFTY_DATE)=" + y
					+ " GROUP BY 1 ORDER BY 2 DESC LIMIT 10", 2);
			StringBuilder o2 = new StringBuilder("[");
			for (int i = 0; i < r2.size(); i++) {
				List t2 = (List) r2.get(i);
				o2.append(i > 0 ? "," : "").append("{\"n\":").append(js(d(t2, 0)))
						.append(",\"c\":").append(jn(d(t2, 1))).append("}");
			}
			return o2.append("]").toString();
		}
		if ("profile".equalsIgnoreCase(panel)) {
			String empID = requestMap.get("employeeID") == null ? "" : requestMap.get("employeeID").trim();
			if (!empID.matches("\\d+")) return "{}";
			String aw = requestMap.get("aw") == null ? "6" : requestMap.get("aw").trim();
			String vw = requestMap.get("vw") == null ? "1" : requestMap.get("vw").trim();
			int vehWeeks = "12".equals(vw) ? 12 : ("6".equals(vw) ? 6 : 1);
			return buildProfile(empID, y, w, "12".equals(aw) ? 12 : 6, vehWeeks, entityID);
		}
		if ("scorecard".equalsIgnoreCase(panel)) {
			String empID = requestMap.get("employeeID") == null ? "" : requestMap.get("employeeID").trim();
			if (!empID.matches("\\d+")) return "{}";
			boolean trail = "trail".equalsIgnoreCase(
					requestMap.get("mode") == null ? "" : requestMap.get("mode").trim());
			return buildScorecard(empID, y, w, trail, entityID);
		}
		return "{}";
	}

	/* ── DA Scorecard: the DA-facing week view, dispatcher-visible ──
	   trail=true aggregates the trailing six scorecard weeks (same year) */
	private String buildScorecard(String empID, String y, String w, boolean trail,
			String entityID) throws Exception {

		List r = db.selectAsList("SELECT FULLNAME, IFNULL(TRANSPORTERID,''), IFNULL(STATION,'') "
				+ "FROM employee WHERE EMPLOYEEID=" + empID, 3);
		if (r.isEmpty()) return "{}";
		String name = d((List) r.get(0), 0);
		String tid = d((List) r.get(0), 1).replaceAll("'", "''");
		String statn = d((List) r.get(0), 2);
		int wi = Integer.parseInt(w);
		int w0 = trail ? Math.max(1, wi - 5) : wi;
		String scWin = " O.DASHBOARD_YEAR=" + y + " AND O.DASHBOARD_WEEK BETWEEN " + w0 + " AND " + wi
				+ " AND O.TRANSPORTERID='" + tid + "' ";

		StringBuilder o = new StringBuilder("{\"nm\":" + js(name) + ",\"tid\":" + js(tid)
				+ ",\"statn\":" + js(statn) + ",\"mode\":\"" + (trail ? "trail" : "cur")
				+ "\",\"y\":" + y + ",\"w\":" + w + ",\"w0\":" + w0 + ",");

		/* scorecard row(s): tier from the latest week, rates averaged when trailing */
		r = db.selectAsList("SELECT SUM(O.DELIVEREDPACKAGES), ROUND(AVG(O.OVERALLSCORE),1), "
				+ "ROUND(AVG(O.SEATBELTOFFRATE),1), ROUND(AVG(O.SPEEDINGEVENTRATE),1), "
				+ "ROUND(AVG(O.DISTRACTIONRATE),1), ROUND(AVG(O.FOLLOWINGDISTANCERATE),1), "
				+ "ROUND(AVG(O.SIGNORSIGNALVIOLATIONRATE),1), "
				+ "IFNULL(SUM(O.CUSTDELIVERYFEEDBACK),0), IFNULL(SUM(O.CUSTESCALATIONDEFECT),0), COUNT(*) "
				+ "FROM dashboard_overview O "
				+ "JOIN (SELECT MAX(DASHBOARD_OVERVIEWID) MID FROM dashboard_overview WHERE ENTITYID=" + entityID
				+ " AND STATUS!=1 GROUP BY DASHBOARD_YEAR, DASHBOARD_WEEK, TRANSPORTERID) DD "
				+ "ON DD.MID=O.DASHBOARD_OVERVIEWID WHERE" + scWin, 10);
		List sc = r.isEmpty() ? null : (List) r.get(0);
		o.append("\"del\":").append(jn(d(sc, 0))).append(",\"score\":").append(jn(d(sc, 1)))
				.append(",\"cdf\":").append(jn(d(sc, 7))).append(",\"ced\":").append(jn(d(sc, 8)))
				.append(",\"wks\":").append(jn(d(sc, 9))).append(",");
		String[] rateN = { "Seatbelt-Off Rate", "Speeding Event Rate", "Distractions Rate",
				"Following Distance", "Sign/Signal Violations" };
		String[] tierC = { "SEATBELTOFFRATETIER", "SPEEDINGEVENTRATETIER", "DISTRACTIONRATETIER",
				"FOLLOWINGDISTANCERATETIER", "SIGNORSIGNALVIOLATIONRATETIER" };

		/* tiers + standing + KFA from the anchor week's row */
		r = db.selectAsList("SELECT O.OVERALLSTANDING, O.KEYFOCUSAREA, O.SEATBELTOFFRATETIER, "
				+ "O.SPEEDINGEVENTRATETIER, O.DISTRACTIONRATETIER, O.FOLLOWINGDISTANCERATETIER, "
				+ "O.SIGNORSIGNALVIOLATIONRATETIER, O.OVERALLQUALITYSCORE, O.CDFDPMOTIER, O.OVERALLSCORE "
				+ "FROM dashboard_overview O " + dedupJoin(y, w, entityID)
				+ "WHERE O.TRANSPORTERID='" + tid + "' LIMIT 1", 10);
		List tw = r.isEmpty() ? null : (List) r.get(0);
		o.append("\"tier\":").append(js(d(tw, 0))).append(",\"kfa\":").append(js(d(tw, 1)))
				.append(",\"qualTier\":").append(js(d(tw, 7))).append(",\"cdfTier\":").append(js(d(tw, 8))).append(",");

		o.append("\"safety\":[");
		for (int i = 0; i < 5; i++) {
			o.append(i > 0 ? "," : "").append("{\"n\":").append(js(rateN[i]))
					.append(",\"v\":").append(jn(d(sc, 2 + i)))
					.append(",\"t\":").append(js(d(tw, 2 + i))).append("}");
		}
		o.append("],");

		/* rank: anchor week only (meaningless when trailing) */
		String myScore = d(tw, 9);
		if (!trail && myScore.length() > 0) {
			r = db.selectAsList("SELECT COUNT(*)+1, (SELECT COUNT(*) FROM dashboard_overview O "
					+ dedupJoin(y, w, entityID) + ") FROM dashboard_overview O "
					+ dedupJoin(y, w, entityID) + "WHERE O.OVERALLSCORE > " + myScore, 2);
			o.append("\"rank\":").append(jn(d((List) r.get(0), 0)))
					.append(",\"rankOf\":").append(jn(d((List) r.get(0), 1))).append(",");
		} else {
			o.append("\"rank\":\"\",\"rankOf\":\"\",");
		}

		/* safety incidents from the dispatch incident log (not camera events) */
		r = db.selectAsList("SELECT COUNT(*) FROM incidents I "
				+ "JOIN incidenttype T ON I.INCIDENTTYPEID=T.INCIDENTTYPEID "
				+ "WHERE I.ENTITYID=" + entityID + " AND I.STATUS!=1 AND I.EMPLOYEEID=" + empID
				+ " AND T.TYPE LIKE '%Safety%' AND T.TYPE NOT LIKE '%Coached%' "
				+ "AND YEAR(I.INCIDENT_DATE)=" + y + " AND " + awk("I.INCIDENT_DATE")
				+ " BETWEEN " + w0 + " AND " + wi, 1);
		o.append("\"safInc\":").append(jn(d((List) r.get(0), 0))).append(",");

		/* quality (exact weeks; blank when the upload lags) */
		r = db.selectAsList("SELECT ROUND(AVG(Q.DCR)*100,1), SUM(Q.DNR), SUM(Q.PACKAGESDELIVERED), "
				+ "ROUND(AVG(Q.POD)*100,1), SUM(Q.DSB), SUM(Q.PACKAGES_RETURNED) FROM quality_overview Q "
				+ "WHERE Q.ENTITYID=" + entityID + " AND Q.STATUS!=1 AND Q.TRANSPORTERID='" + tid
				+ "' AND Q.QUALITY_YEAR=" + y + " AND Q.QUALITY_WEEK BETWEEN " + w0 + " AND " + wi, 6);
		List q = r.isEmpty() ? null : (List) r.get(0);
		String scDcr = d(q, 0), scQdel = d(q, 2), scRts = d(q, 5);
		if (scDcr.length() == 0) {
			/* quality_overview lags: per-DA DCR/RTS from the DCR weekly upload */
			r = db.selectAsList("SELECT ROUND(SUM(DELIVERED)/NULLIF(SUM(DISPATCHED),0)*100,1), "
					+ "SUM(DELIVERED), SUM(RETURNED) FROM quality_dcr_weekly "
					+ "WHERE ENTITYID=" + entityID + " AND STATUS!=1 AND TRANSPORTERID='" + tid
					+ "' AND DCR_YEAR=" + y + " AND DCR_WEEK BETWEEN " + w0 + " AND " + wi, 3);
			List xq2 = r.isEmpty() ? null : (List) r.get(0);
			if (xq2 != null && d(xq2, 1).length() > 0) {
				scDcr = d(xq2, 0);
				scQdel = d(xq2, 1);
				scRts = d(xq2, 2);
			}
		}
		String scPod = d(q, 3);
		if (scPod.length() == 0) {
			/* POD fallback: the scorecard bundle's POD column (lands in PODOPPS) */
			r = db.selectAsList("SELECT ROUND(AVG(O.PODOPPS),1) FROM dashboard_overview O "
					+ "JOIN (SELECT MAX(DASHBOARD_OVERVIEWID) MID FROM dashboard_overview WHERE ENTITYID=" + entityID
					+ " AND STATUS!=1 GROUP BY DASHBOARD_YEAR, DASHBOARD_WEEK, TRANSPORTERID) DD "
					+ "ON DD.MID=O.DASHBOARD_OVERVIEWID WHERE" + scWin, 1);
			scPod = d((List) r.get(0), 0);
		}
		String scDsb = d(q, 4);
		if (scDsb.length() == 0) {
			/* DSB fallback: per-package concession rows from the DSB upload */
			r = db.selectAsList("SELECT COUNT(*) FROM dsb_details WHERE ENTITYID=" + entityID
					+ " AND STATUS!=1 AND TRANSPORTERID='" + tid + "' AND DSB_YEAR=" + y
					+ " AND DSB_WEEK BETWEEN " + w0 + " AND " + wi, 1);
			String dsbC = d((List) r.get(0), 0);
			/* only claim 0 when the upload actually covers the range */
			if (!"0".equals(dsbC)) {
				scDsb = dsbC;
			} else {
				r = db.selectAsList("SELECT COUNT(*) FROM dsb_details WHERE ENTITYID=" + entityID
						+ " AND STATUS!=1 AND DSB_YEAR=" + y
						+ " AND DSB_WEEK BETWEEN " + w0 + " AND " + wi, 1);
				if (!"0".equals(d((List) r.get(0), 0))) scDsb = "0";
			}
		}
		o.append("\"qual\":{\"dcr\":").append(jn(scDcr)).append(",\"dnr\":").append(jn(d(q, 1)))
				.append(",\"qdel\":").append(jn(scQdel)).append(",\"pod\":").append(jn(scPod))
				.append(",\"dsb\":").append(jn(scDsb)).append(",\"rts\":").append(jn(scRts)).append("},");

		/* RTS reason mix from the Quality DCR weekly upload */
		String[][] rtsDef = { { "RTS_ALL_EXEMPTED", "All exempted" }, { "RTS_BUSINESS_CLOSED", "Business closed" },
				{ "RTS_OUT_OF_DRIVE_TIME", "Out of drive time" }, { "RTS_OTHER", "Other" },
				{ "RTS_OBJECT_MISSING", "Object missing" }, { "RTS_UNABLE_TO_ACCESS", "Unable to access" },
				{ "RTS_DAMAGED", "Damaged" }, { "RTS_BAD_WEATHER", "Bad weather" },
				{ "RTS_CUSTOMER_UNAVAILABLE", "Customer unavailable" }, { "RTS_UNSAFE_DOG", "Unsafe due to dog" },
				{ "RTS_NO_SECURE_LOCATION", "No secure location" }, { "RTS_UNABLE_TO_LOCATE", "Unable to locate" },
				{ "RTS_LOCKER_ISSUE", "Locker issue" }, { "RTS_RESCHEDULED", "Rescheduled by customer" },
				{ "RTS_OTP_NOT_AVAILABLE", "OTP not available" }, { "RTS_NO_LOCKER", "No locker available" },
				{ "RTS_MISSING_ACCESS_CODE", "Missing access code" }, { "RTS_LOCKER_SPACE", "Locker space insufficient" },
				{ "RTS_LOCKER_INELIGIBLE", "Locker ineligible" }, { "RTS_MERCHANT_UNAVAILABLE", "Merchant unavailable" },
				{ "RTS_AGE_VERIFICATION", "Age verification failed" } };
		StringBuilder rtsSel = new StringBuilder("SELECT IFNULL(SUM(RETURNED),0), IFNULL(SUM(RESCUED),0)");
		for (int i = 0; i < rtsDef.length; i++)
			rtsSel.append(", IFNULL(SUM(").append(rtsDef[i][0]).append("),0)");
		rtsSel.append(" FROM quality_dcr_weekly WHERE ENTITYID=").append(entityID)
				.append(" AND STATUS!=1 AND TRANSPORTERID='").append(tid)
				.append("' AND DCR_YEAR=").append(y).append(" AND DCR_WEEK BETWEEN ").append(w0)
				.append(" AND ").append(wi);
		r = db.selectAsList(rtsSel.toString(), rtsDef.length + 2);
		List rm = r.isEmpty() ? null : (List) r.get(0);
		o.append("\"rtsMix\":{\"ret\":").append(jn(d(rm, 0))).append(",\"resc\":").append(jn(d(rm, 1)))
				.append(",\"rs\":[");
		int rn = 0;
		for (int i = 0; i < rtsDef.length; i++) {
			String cnt = d(rm, i + 2);
			if (cnt.length() > 0 && !cnt.equals("0"))
				o.append(rn++ > 0 ? "," : "").append("{\"n\":").append(js(rtsDef[i][1]))
						.append(",\"c\":").append(cnt).append("}");
		}
		o.append("]},");

		/* CDF detail upload: negative-feedback categories + customer comments */
		String cdfWin = " ENTITYID=" + entityID + " AND STATUS!=1 AND TRANSPORTERID='" + tid
				+ "' AND CDF_YEAR=" + y + " AND CDF_WEEK BETWEEN " + w0 + " AND " + wi;
		r = db.selectAsList("SELECT COUNT(*), IFNULL(SUM(MISHANDLED),0), IFNULL(SUM(UNPROFESSIONAL),0), "
				+ "IFNULL(SUM(NOT_FOLLOW_INSTRUCTIONS),0), IFNULL(SUM(WRONG_ADDRESS),0), "
				+ "IFNULL(SUM(NEVER_RECEIVED),0), IFNULL(SUM(WRONG_ITEM),0) FROM cdf_feedback WHERE" + cdfWin, 7);
		List cf = r.isEmpty() ? null : (List) r.get(0);
		String[] cfn = { "Mishandled package", "Unprofessional", "Ignored instructions",
				"Wrong address", "Never received", "Wrong item" };
		r = db.selectAsList("SELECT COUNT(*) FROM cdf_feedback WHERE ENTITYID=" + entityID
				+ " AND STATUS!=1 AND CDF_YEAR=" + y + " AND CDF_WEEK BETWEEN " + w0 + " AND " + wi, 1);
		String cdfUp = d((List) r.get(0), 0).equals("0") ? "0" : "1";
		o.append("\"cdfDet\":{\"up\":").append(cdfUp)
				.append(",\"tot\":").append(jn(d(cf, 0))).append(",\"cats\":[");
		for (int i = 0; i < cfn.length; i++)
			o.append(i > 0 ? "," : "").append("{\"n\":").append(js(cfn[i]))
					.append(",\"c\":").append(jn(d(cf, i + 1))).append("}");
		o.append("],\"cmts\":[");
		r = db.selectAsList("SELECT DATE_FORMAT(DELIVERY_DATE,'%m/%d'), FEEDBACK_DETAILS FROM cdf_feedback "
				+ "WHERE" + cdfWin + " AND FEEDBACK_DETAILS IS NOT NULL AND FEEDBACK_DETAILS!='' "
				+ "ORDER BY DELIVERY_DATE DESC LIMIT 4", 2);
		for (int i = 0; i < r.size(); i++) {
			List t = (List) r.get(i);
			o.append(i > 0 ? "," : "").append("{\"d\":").append(js(d(t, 0)))
					.append(",\"m\":").append(js(d(t, 1))).append("}");
		}
		o.append("]},");

		/* incidents: total / call-outs / rescues / lates + write-ups
		   (IFNULL: zero rows must read as 0, not "No Data") */
		r = db.selectAsList("SELECT COUNT(*), IFNULL(SUM(T.TYPE LIKE '%Call Out%'),0), "
				+ "IFNULL(SUM(T.TYPE LIKE '%Rescue%'),0), "
				+ "IFNULL(SUM(T.TYPE LIKE '%Late%'),0) FROM incidents I "
				+ "JOIN incidenttype T ON I.INCIDENTTYPEID=T.INCIDENTTYPEID "
				+ "WHERE I.ENTITYID=" + entityID + " AND I.STATUS!=1 AND I.EMPLOYEEID=" + empID
				+ " AND YEAR(I.INCIDENT_DATE)=" + y + " AND " + awk("I.INCIDENT_DATE")
				+ " BETWEEN " + w0 + " AND " + wi, 4);
		List inc = r.isEmpty() ? null : (List) r.get(0);
		r = db.selectAsList("SELECT COUNT(*) FROM employeeforms F WHERE F.STATUS!=1 AND F.EMPLOYEEID=" + empID
				+ " AND YEAR(F.CREATE_DATE)=" + y + " AND " + awk("F.CREATE_DATE")
				+ " BETWEEN " + w0 + " AND " + wi, 1);
		o.append("\"inc\":{\"tot\":").append(jn(d(inc, 0))).append(",\"co\":").append(jn(d(inc, 1)))
				.append(",\"resc\":").append(jn(d(inc, 2))).append(",\"late\":").append(jn(d(inc, 3)))
				.append(",\"wu\":").append(jn(d((List) r.get(0), 0))).append("},");

		/* DVIC inspections: list + rushed count (<90s) */
		r = db.selectAsList("SELECT DATE_FORMAT(STARTDATE,'%a %m/%d'), IFNULL(INSPECTIONTYPE,''), "
				+ "IFNULL(INSPECTIONSTATUS,''), IFNULL(DURATION,'') FROM dvic "
				+ "WHERE ENTITYID=" + entityID + " AND STATUS!=1 AND TRANSPORTERID='" + tid
				+ "' AND DVIC_YEAR=" + y + " AND DVIC_WEEK BETWEEN " + w0 + " AND " + wi
				+ " ORDER BY STARTDATE DESC LIMIT 10", 4);
		int rushed = 0;
		StringBuilder dv = new StringBuilder("[");
		for (int i = 0; i < r.size(); i++) {
			List t = (List) r.get(i);
			int dur = 0;
			try { dur = (int) Double.parseDouble(d(t, 3)); } catch (Exception e) { }
			boolean rush = dur > 0 && dur < 90;
			if (rush) rushed++;
			dv.append(i > 0 ? "," : "").append("{\"d\":").append(js(d(t, 0)))
					.append(",\"ty\":").append(js(d(t, 1).replace("_DVIC", "").replace("_", " ")))
					.append(",\"st\":").append(js(d(t, 2))).append(",\"dur\":").append(dur)
					.append(",\"rush\":").append(rush).append("}");
		}
		dv.append("]");
		o.append("\"dvic\":").append(dv).append(",\"dvicRushed\":").append(rushed)
				.append(",\"dvicTotal\":").append(r.size()).append(",");

		/* Flex app week */
		r = db.selectAsList("SELECT ROUND(SUM(TIMESTAMPDIFF(MINUTE, APP_SIGNIN, APP_SIGNOUT))/60,1), "
				+ "COUNT(*), ROUND(AVG(AVG_PACE_STOP_PER_HOUR),0), SUM(COMPLETEDSTOPS), SUM(ALLSTOPS), "
				+ "SUM(CASE WHEN TOTAL_BREAKTIME REGEXP '^[0-9]+$' THEN TOTAL_BREAKTIME ELSE 0 END) "
				+ "FROM daily_itineraries WHERE ENTITYID=" + entityID + " AND STATUS!=1 "
				+ "AND TRANSPORTERID='" + tid + "' AND ITINARARY_YEAR=" + y
				+ " AND ITINARARY_WEEK BETWEEN " + w0 + " AND " + wi, 6);
		List fx = r.isEmpty() ? null : (List) r.get(0);
		o.append("\"flex\":{\"hrs\":").append(jn(d(fx, 0))).append(",\"routes\":").append(jn(d(fx, 1)))
				.append(",\"pace\":").append(jn(d(fx, 2))).append(",\"cs\":").append(jn(d(fx, 3)))
				.append(",\"st\":").append(jn(d(fx, 4)))
				.append(",\"brk\":").append(jn(d(fx, 5))).append("}}");
		return o.toString();
	}

	/* per-DA profile: KPIs vs fleet, 14-wk trend, categorized weekly activity */
	private String buildProfile(String empID, String y, String w, int actWeeks,
			int vehWeeks, String entityID) throws Exception {

		List r = db.selectAsList("SELECT FULLNAME, IFNULL(TRANSPORTERID,''), IFNULL(POSITION,''), "
				+ "IFNULL(STATION,'') FROM employee WHERE EMPLOYEEID=" + empID, 4);
		String name = r.isEmpty() ? "" : d((List) r.get(0), 0);
		String tid = r.isEmpty() ? "" : d((List) r.get(0), 1).replaceAll("'", "''");
		String posn = r.isEmpty() ? "" : d((List) r.get(0), 2);
		String statn = r.isEmpty() ? "" : d((List) r.get(0), 3);
		String nameKey = name.toUpperCase().replaceAll("\\s+", " ").trim().replaceAll("'", "''");
		/* TRANSPORTERID is populated on all employees and metric tables — the
		   reliable join; free-text name match remains the fallback */
		String nameCond = tid.length() > 0
				? " TRANSPORTERID='" + tid + "' "
				: " TRIM(UPPER(REPLACE(REPLACE(DELIVERYASSOCIATE,'  ',' '),'  ',' ')))='" + nameKey + "' ";

		StringBuilder o = new StringBuilder("{\"nm\":" + js(name) + ",\"y\":" + y + ",\"w\":" + w
				+ ",\"tid\":" + js(tid) + ",\"posn\":" + js(posn) + ",\"statn\":" + js(statn) + ",");

		/* this week's scorecard row + fleet averages */
		r = db.selectAsList("SELECT O.OVERALLSTANDING, O.OVERALLSCORE, O.FICO, O.KEYFOCUSAREA, "
				+ "O.DELIVEREDPACKAGES FROM dashboard_overview O " + dedupJoin(y, w, entityID)
				+ "WHERE" + nameCond.replace("DELIVERYASSOCIATE", "O.DELIVERYASSOCIATE") + "LIMIT 1", 5);
		List me = r.isEmpty() ? null : (List) r.get(0);
		o.append("\"st\":").append(js(d(me, 0))).append(",\"sc\":").append(jn(d(me, 1)))
				.append(",\"fico\":").append(jn(d(me, 2))).append(",\"kfa\":").append(js(d(me, 3)))
				.append(",\"pkgs\":").append(jn(d(me, 4))).append(",");

		r = db.selectAsList("SELECT ROUND(AVG(O.OVERALLSCORE),1), ROUND(AVG(O.FICO),0), "
				+ "ROUND(AVG(O.DELIVEREDPACKAGES),0), SUM(O.DELIVEREDPACKAGES), COUNT(*) "
				+ "FROM dashboard_overview O " + dedupJoin(y, w, entityID), 5);
		List fl = r.isEmpty() ? null : (List) r.get(0);
		o.append("\"flSc\":").append(jn(d(fl, 0))).append(",\"flFico\":").append(jn(d(fl, 1)))
				.append(",\"flPkgs\":").append(jn(d(fl, 2)))
				.append(",\"stationPkgs\":").append(jn(d(fl, 3)))
				.append(",\"rankOf\":").append(jn(d(fl, 4))).append(",");

		/* rank among that week's scorecard DAs (1 = best score) */
		String myScore = d(me, 1);
		if (myScore.length() > 0) {
			r = db.selectAsList("SELECT COUNT(*)+1 FROM dashboard_overview O " + dedupJoin(y, w, entityID)
					+ "WHERE O.OVERALLSCORE > " + myScore, 1);
			o.append("\"rank\":").append(jn(d((List) r.get(0), 0))).append(",");
		} else {
			o.append("\"rank\":\"\",");
		}

		/* quality row for the week */
		r = db.selectAsList("SELECT ROUND(Q.DCR*100,1), ROUND(Q.POD*100,1), "
				+ "ROUND(Q.DNR/NULLIF(Q.PACKAGESDELIVERED,0)*1000000,0), Q.DNR, Q.DSB, Q.CDF_DPMO, Q.CED, "
				+ "Q.PACKAGESDELIVERED FROM quality_overview Q " + qualDedupJoin(y, w, entityID)
				+ "WHERE" + nameCond.replace("DELIVERYASSOCIATE", "Q.DELIVERYASSOCIATE") + "LIMIT 1", 8);
		List q = r.isEmpty() ? null : (List) r.get(0);
		o.append("\"qual\":{\"dcr\":").append(jn(d(q, 0))).append(",\"pod\":").append(jn(d(q, 1)))
				.append(",\"dnrDpmo\":").append(jn(d(q, 2))).append(",\"dnr\":").append(jn(d(q, 3)))
				.append(",\"dsb\":").append(jn(d(q, 4))).append(",\"cdf\":").append(jn(d(q, 5)))
				.append(",\"ced\":").append(jn(d(q, 6))).append(",\"pkgs\":").append(jn(d(q, 7))).append("},");

		/* per-metric tiers for the selected week — the "Performance" grid */
		r = db.selectAsList("SELECT O.FICO, O.FICOTIER, O.SEATBELTOFFRATE, O.SEATBELTOFFRATETIER, "
				+ "O.SPEEDINGEVENTRATE, O.SPEEDINGEVENTRATETIER, O.DISTRACTIONRATE, O.DISTRACTIONRATETIER, "
				+ "O.FOLLOWINGDISTANCERATE, O.FOLLOWINGDISTANCERATETIER, "
				+ "O.SIGNORSIGNALVIOLATIONRATE, O.SIGNORSIGNALVIOLATIONRATETIER, "
				+ "O.DCR, O.DCRTIER, O.DSB, O.DSBDPMOTIER, O.CDFDPMO, O.CDFDPMOTIER, "
				+ "O.CUSTESCALATIONDEFECT, O.CEDTIER, IFNULL(O.SWCPOD, O.PODOPPS), O.PODTIER, O.PSB, O.PSBTIER "
				+ "FROM dashboard_overview O " + dedupJoin(y, w, entityID)
				+ "WHERE" + nameCond.replace("DELIVERYASSOCIATE", "O.DELIVERYASSOCIATE") + "LIMIT 1", 24);
		List mrow = r.isEmpty() ? null : (List) r.get(0);
		String[][] mdef = {
				{ "SAFETY", "Seatbelt-Off Rate", "2" },
				{ "SAFETY", "Speeding Event Rate", "4" }, { "SAFETY", "Distractions Rate", "6" },
				{ "SAFETY", "Following Distance", "8" }, { "SAFETY", "Sign/Signal Violations", "10" },
				{ "QUALITY", "Delivery Completion", "12" }, { "QUALITY", "Delivery Success (DSB)", "14" },
				{ "QUALITY", "Cust. Delivery Feedback", "16" }, { "QUALITY", "Cust. Escalations", "18" },
				{ "QUALITY", "Photo-On-Delivery", "20" }, { "QUALITY", "Pickup Success (PSB)", "22" } };
		/* scorecard DCR column blank: per-DA DCR% from the DCR weekly upload */
		String profDcr = "";
		if (d(mrow, 12).length() == 0 && tid.length() > 0) {
			r = db.selectAsList("SELECT ROUND(SUM(DELIVERED)/NULLIF(SUM(DISPATCHED),0)*100,1) "
					+ "FROM quality_dcr_weekly WHERE ENTITYID=" + entityID
					+ " AND STATUS!=1 AND TRANSPORTERID='" + tid + "' AND DCR_YEAR=" + y
					+ " AND DCR_WEEK=" + w, 1);
			profDcr = d((List) r.get(0), 0);
		}
		o.append("\"metrics\":[");
		for (int i = 0; i < mdef.length; i++) {
			int ix = Integer.parseInt(mdef[i][2]);
			String mv = d(mrow, ix);
			if (mv.length() == 0 && "Delivery Completion".equals(mdef[i][1]))
				mv = profDcr;
			o.append(i > 0 ? "," : "").append("{\"g\":\"").append(mdef[i][0]).append("\",\"n\":")
					.append(js(mdef[i][1])).append(",\"v\":").append(jn(mv))
					.append(",\"t\":").append(js(d(mrow, ix + 1))).append("}");
		}
		o.append("],");

		/* daily trips + Flex app times (itineraries first, routes as fallback) */
		r = db.selectAsList("SELECT DATE_FORMAT(ITINARARYDATE,'%a %m/%d'), routecode, "
				+ "CONCAT(IFNULL(COMPLETEDSTOPS,0),' / ',IFNULL(ALLSTOPS,0)), IFNULL(TOALPACKAGES,''), "
				+ "IFNULL(TIME_FORMAT(APP_SIGNIN,'%l:%i %p'),''), IFNULL(TIME_FORMAT(APP_SIGNOUT,'%l:%i %p'),''), "
				+ "IFNULL(TOTAL_BREAKTIME,''), IFNULL(AVG_PACE_STOP_PER_HOUR,''), "
				+ "IFNULL(ROUND(TIMESTAMPDIFF(MINUTE, APP_SIGNIN, APP_SIGNOUT)/60,1),'') "
				+ "FROM daily_itineraries WHERE TRANSPORTERID='" + tid + "' AND ITINARARY_WEEK=" + w
				+ " AND ITINARARY_YEAR=" + y + " AND STATUS!=1 ORDER BY ITINARARYDATE LIMIT 10", 9);
		if (r.isEmpty())
			r = db.selectAsList("SELECT DATE_FORMAT(ROUTEDATE,'%a %m/%d'), ROUTECODE, "
					+ "CONCAT(IFNULL(COMPLETEDSTOPS,0),' / ',IFNULL(ALLSTOPS,0)), '', '', '', '', '', '' "
					+ "FROM dailyroutes WHERE TRANSPORTERID='" + tid + "' AND ROUTE_WEEK=" + w
					+ " AND ROUTE_YEAR=" + y + " AND STATUS!=1 ORDER BY ROUTEDATE LIMIT 10", 9);
		double wkHours = 0;
		o.append("\"days\":[");
		for (int i = 0; i < r.size(); i++) {
			List t = (List) r.get(i);
			try { wkHours += Double.parseDouble(d(t, 8)); } catch (Exception e) { }
			o.append(i > 0 ? "," : "").append("{\"d\":").append(js(d(t, 0))).append(",\"rt\":").append(js(d(t, 1)))
					.append(",\"stops\":").append(js(d(t, 2))).append(",\"pkgs\":").append(jn(d(t, 3)))
					.append(",\"ci\":").append(js(d(t, 4))).append(",\"co\":").append(js(d(t, 5)))
					.append(",\"brk\":").append(jn(d(t, 6))).append(",\"pace\":").append(jn(d(t, 7)))
					.append(",\"hrs\":").append(jn(d(t, 8))).append("}");
		}
		o.append("],\"wkHours\":").append(jn(String.valueOf(Math.round(wkHours * 10) / 10.0))).append(",");

		/* 14-week trend: my score + standing + fleet score on the same weeks */
		r = db.selectAsList("SELECT O.DASHBOARD_YEAR, O.DASHBOARD_WEEK, "
				+ "ROUND(AVG(CASE WHEN" + nameCond.replace("DELIVERYASSOCIATE", "O.DELIVERYASSOCIATE")
				+ "THEN O.OVERALLSCORE END),1), ROUND(AVG(O.OVERALLSCORE),1), "
				+ "MAX(CASE WHEN" + nameCond.replace("DELIVERYASSOCIATE", "O.DELIVERYASSOCIATE")
				+ "THEN O.OVERALLSTANDING END) "
				+ "FROM dashboard_overview O JOIN (SELECT MAX(DASHBOARD_OVERVIEWID) MID FROM dashboard_overview "
				+ "WHERE ENTITYID=" + entityID + " AND STATUS!=1 GROUP BY DASHBOARD_YEAR, DASHBOARD_WEEK, TRANSPORTERID) DD "
				+ "ON DD.MID=O.DASHBOARD_OVERVIEWID GROUP BY 1,2 ORDER BY 1 DESC,2 DESC LIMIT 14", 5);
		o.append("\"trend\":[");
		for (int i = r.size() - 1, n = 0; i >= 0; i--, n++) {
			List t = (List) r.get(i);
			o.append(n > 0 ? "," : "").append("{\"y\":").append(d(t, 0)).append(",\"w\":").append(d(t, 1))
					.append(",\"me\":").append(jn(d(t, 2))).append(",\"fl\":").append(jn(d(t, 3)))
					.append(",\"st\":").append(js(d(t, 4))).append("}");
		}
		o.append("],");

		/* weekly activity: dispatch incidents + OSHA + terminations only */
		o.append("\"act\":[");
		int n = 0;

		r = db.selectAsList("SELECT DATE_FORMAT(I.INCIDENT_DATE,'%m/%d'), T.TYPE, "
				+ "IFNULL(C.DESCRIPTION,''), IFNULL(I.DESCRIPTION,'') FROM incidents I "
				+ "JOIN incidenttype T ON I.INCIDENTTYPEID=T.INCIDENTTYPEID "
				+ "LEFT JOIN incidentcategory C ON I.INCIDENTCATEGORYID=C.INCIDENTCATEGORYID "
				+ "WHERE I.ENTITYID=" + entityID + " AND I.STATUS!=1 AND I.EMPLOYEEID=" + empID
				+ " AND " + awk("I.INCIDENT_DATE") + "=" + w + " AND YEAR(I.INCIDENT_DATE)=" + y
				+ " ORDER BY I.INCIDENT_DATE DESC LIMIT 15", 4);
		for (int i = 0; i < r.size(); i++) {
			List t = (List) r.get(i);
			String ty = d(t, 1);
			String cat = "INCIDENT";
			if (ty.indexOf("Call Out") >= 0) cat = "CALL-OUT";
			else if (ty.indexOf("Rescue") >= 0) cat = "RESCUE";
			o.append(n++ > 0 ? "," : "").append("{\"cat\":\"").append(cat).append("\",\"d\":").append(js(d(t, 0)))
					.append(",\"ty\":").append(js(ty)).append(",\"m\":")
					.append(js((d(t, 2).length() > 0 ? d(t, 2) + " - " : "") + d(t, 3))).append("}");
		}

		r = db.selectAsList("SELECT DATE_FORMAT(INCIDENTDATE,'%m/%d'), IFNULL(TYPEOFINCIDENT,''), "
				+ "IFNULL(INCIDENTLOCATION,''), IFNULL(INCIDENTDESCRIPTION,'') FROM employeeincident "
				+ "WHERE STATUS!=1 AND EMPLOYEEID=" + empID + " AND " + awk("INCIDENTDATE") + "=" + w
				+ " AND YEAR(INCIDENTDATE)=" + y + " LIMIT 5", 4);
		for (int i = 0; i < r.size(); i++) {
			List t = (List) r.get(i);
			String desc = d(t, 3);
			if (desc.length() > 400) desc = desc.substring(0, 400) + "...";
			o.append(n++ > 0 ? "," : "").append("{\"cat\":\"OSHA\",\"d\":").append(js(d(t, 0)))
					.append(",\"ty\":").append(js(d(t, 1))).append(",\"m\":")
					.append(js(d(t, 2) + " - " + desc)).append("}");
		}

		r = db.selectAsList("SELECT DATE_FORMAT(DATEOFTERMINATION,'%m/%d'), IFNULL(TERMINATIONTYPE,''), "
				+ "IFNULL(TERMINATIONREASON,''), IFNULL(COMMENTS,'') FROM employeetermination "
				+ "WHERE STATUS!=1 AND EMPLOYEEID=" + empID + " AND " + awk("DATEOFTERMINATION") + "=" + w
				+ " AND YEAR(DATEOFTERMINATION)=" + y + " LIMIT 3", 4);
		for (int i = 0; i < r.size(); i++) {
			List t = (List) r.get(i);
			String cm = d(t, 3);
			if (cm.length() > 400) cm = cm.substring(0, 400) + "...";
			o.append(n++ > 0 ? "," : "").append("{\"cat\":\"TERMINATION\",\"d\":").append(js(d(t, 0)))
					.append(",\"ty\":").append(js(d(t, 1))).append(",\"m\":")
					.append(js(d(t, 2) + (cm.length() > 0 ? " - " + cm : ""))).append("}");
		}
		o.append("],");

		/* activity trend for this DA (incidents split + OSHA + terms) —
		   window size comes from the card's dropdown (6 or 12 weeks) */
		int wi = Integer.parseInt(w);
		int w0 = Math.max(1, wi - (actWeeks - 1));
		Map<String, int[]> wkMap = new HashMap<String, int[]>();
		r = db.selectAsList("SELECT " + awk("I.INCIDENT_DATE") + ", COUNT(*), "
				+ "SUM(T.TYPE LIKE '%Call Out%'), SUM(T.TYPE LIKE '%Rescue%') "
				+ "FROM incidents I JOIN incidenttype T ON I.INCIDENTTYPEID=T.INCIDENTTYPEID "
				+ "WHERE I.ENTITYID=" + entityID + " AND I.STATUS!=1 AND I.EMPLOYEEID=" + empID
				+ " AND YEAR(I.INCIDENT_DATE)=" + y + " AND " + awk("I.INCIDENT_DATE")
				+ " BETWEEN " + w0 + " AND " + wi + " GROUP BY 1", 4);
		for (int i = 0; i < r.size(); i++) {
			List t = (List) r.get(i);
			int[] a = new int[5];
			a[0] = Integer.parseInt("0" + d(t, 1));
			a[1] = Integer.parseInt("0" + d(t, 2));
			a[2] = Integer.parseInt("0" + d(t, 3));
			wkMap.put(d(t, 0), a);
		}
		r = db.selectAsList("SELECT " + awk("INCIDENTDATE") + ", COUNT(*) FROM employeeincident "
				+ "WHERE STATUS!=1 AND EMPLOYEEID=" + empID + " AND YEAR(INCIDENTDATE)=" + y
				+ " AND " + awk("INCIDENTDATE") + " BETWEEN " + w0 + " AND " + wi + " GROUP BY 1", 2);
		for (int i = 0; i < r.size(); i++) {
			List t = (List) r.get(i);
			int[] a = wkMap.get(d(t, 0));
			if (a == null) { a = new int[5]; wkMap.put(d(t, 0), a); }
			a[3] = Integer.parseInt("0" + d(t, 1));
		}
		r = db.selectAsList("SELECT " + awk("DATEOFTERMINATION") + ", COUNT(*) FROM employeetermination "
				+ "WHERE STATUS!=1 AND EMPLOYEEID=" + empID + " AND YEAR(DATEOFTERMINATION)=" + y
				+ " AND " + awk("DATEOFTERMINATION") + " BETWEEN " + w0 + " AND " + wi + " GROUP BY 1", 2);
		for (int i = 0; i < r.size(); i++) {
			List t = (List) r.get(i);
			int[] a = wkMap.get(d(t, 0));
			if (a == null) { a = new int[5]; wkMap.put(d(t, 0), a); }
			a[4] = Integer.parseInt("0" + d(t, 1));
		}
		o.append("\"act6\":[");
		for (int k2 = w0; k2 <= wi; k2++) {
			int[] a = wkMap.get(String.valueOf(k2));
			if (a == null) a = new int[5];
			o.append(k2 > w0 ? "," : "").append("{\"w\":").append(k2)
					.append(",\"inc\":").append(a[0]).append(",\"co\":").append(a[1])
					.append(",\"resc\":").append(a[2]).append(",\"osha\":").append(a[3])
					.append(",\"term\":").append(a[4]).append("}");
		}
		o.append("],");

		/* vehicles driven — window from the card's dropdown (this wk / 6 / 12) */
		int vw0 = Math.max(1, wi - (vehWeeks - 1));
		r = db.selectAsList("SELECT V.VEHICLENUMBER, COUNT(DISTINCT DATE(C.CLOCKINTIME)), "
				+ "DATE_FORMAT(MAX(C.CLOCKINTIME),'%m/%d') FROM dacheckin C "
				+ "JOIN vehicle V ON C.VEHICLEID=V.VEHICLEID "
				+ "WHERE C.STATUS!=1 AND C.EMPLOYEEID=" + empID + " AND YEAR(C.CLOCKINTIME)=" + y
				+ " AND " + awk("C.CLOCKINTIME") + " BETWEEN " + vw0 + " AND " + wi
				+ " GROUP BY 1 ORDER BY 2 DESC LIMIT 12", 3);
		o.append("\"vehicles\":[");
		for (int i = 0; i < r.size(); i++) {
			List t = (List) r.get(i);
			o.append(i > 0 ? "," : "").append("{\"v\":").append(js(d(t, 0)))
					.append(",\"days\":").append(jn(d(t, 1))).append(",\"last\":").append(js(d(t, 2))).append("}");
		}
		o.append("]}");
		return o.toString();
	}
}
