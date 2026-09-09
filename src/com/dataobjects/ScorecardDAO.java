package com.dataobjects;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

public class ScorecardDAO extends MVPGDAO {

	@Override
	public String getAjaxRequestTypeResp(String requestType,
			Map<String, String> requestMap, String loginUser,
			String loginUserRoles, String loginUserID, String entityID)
			throws Exception {

		ensureScorecardTable();

		if ("saveScorecardWeek".equalsIgnoreCase(requestType)) {
			return saveScorecardWeek(requestMap, loginUser);
		} else if ("loadScorecardWeek".equalsIgnoreCase(requestType)) {
			return loadScorecardWeek(requestMap);
		}

		return "{\"ok\":false,\"message\":\"Unsupported requestType\"}";
	}

	/* Self-heal: create the projected_scorecard table on first use if it is
	   missing (mirrors the CREATE-IF-NOT-EXISTS self-heal used elsewhere). */
	private void ensureScorecardTable() {
		try {
			db.create("CREATE TABLE IF NOT EXISTS projected_scorecard ("
				+ "id BIGINT PRIMARY KEY AUTO_INCREMENT,"
				+ "scorecard_week VARCHAR(20) NOT NULL,"
				+ "score_day VARCHAR(40) NOT NULL,"
				+ "next_day_target_score_needed VARCHAR(40) NOT NULL DEFAULT '0',"
				+ "weekly_projection_sun_sat DECIMAL(10,4) NOT NULL DEFAULT 0.0000,"
				+ "trips INT NOT NULL DEFAULT 0,"
				+ "pickup_quality_score DECIMAL(10,4) NOT NULL DEFAULT 0.0000,"
				+ "team_score DECIMAL(10,4) NOT NULL DEFAULT 0.0000,"
				+ "packages_dispatched INT NOT NULL DEFAULT 0,"
				+ "packages_returned INT NOT NULL DEFAULT 0,"
				+ "total_delivered_auto INT NOT NULL DEFAULT 0,"
				+ "negative_feedback INT NOT NULL DEFAULT 0,"
				+ "dsb_defects INT NOT NULL DEFAULT 0,"
				+ "seatbelt_events INT NOT NULL DEFAULT 0,"
				+ "speeding_events INT NOT NULL DEFAULT 0,"
				+ "sign_signal_events INT NOT NULL DEFAULT 0,"
				+ "distraction_events INT NOT NULL DEFAULT 0,"
				+ "following_distance_events INT NOT NULL DEFAULT 0,"
				+ "seatbelt_rate DECIMAL(10,4) NOT NULL DEFAULT 0.0000,"
				+ "speeding_rate DECIMAL(10,4) NOT NULL DEFAULT 0.0000,"
				+ "sign_signal_rate DECIMAL(10,4) NOT NULL DEFAULT 0.0000,"
				+ "distraction_rate DECIMAL(10,4) NOT NULL DEFAULT 0.0000,"
				+ "following_distance_rate DECIMAL(10,4) NOT NULL DEFAULT 0.0000,"
				+ "safety_score_daily DECIMAL(10,4) NOT NULL DEFAULT 0.0000,"
				+ "cdf_dpmo_running DECIMAL(14,4) NOT NULL DEFAULT 0.0000,"
				+ "dsb_dpmo_running DECIMAL(14,4) NOT NULL DEFAULT 0.0000,"
				+ "quality_score_running DECIMAL(10,4) NOT NULL DEFAULT 0.0000,"
				+ "projected_weekly_score DECIMAL(10,4) NOT NULL DEFAULT 0.0000,"
				+ "projected_tier VARCHAR(30) NOT NULL DEFAULT '-',"
				+ "remaining_cdf_allowed DECIMAL(14,4) NOT NULL DEFAULT 0.0000,"
				+ "remaining_dsb_allowed DECIMAL(14,4) NOT NULL DEFAULT 0.0000,"
				+ "safety_warning VARCHAR(50) NOT NULL DEFAULT '-',"
				+ "user_created VARCHAR(100) NOT NULL DEFAULT 'system',"
				+ "user_created_timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,"
				+ "user_modified VARCHAR(100) NOT NULL DEFAULT 'system',"
				+ "modified_timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,"
				+ "UNIQUE KEY uq_projected_scorecard_week_day (scorecard_week, score_day),"
				+ "KEY ix_projected_scorecard_week (scorecard_week))");
		} catch (Exception ex) {
			/* table probably already exists — safe to ignore */
		}
	}

	private String saveScorecardWeek(Map<String, String> requestMap,
			String loginUser) throws Exception {
		String scorecardWeek = getReq(requestMap, "scorecardWeek", "");
		if (scorecardWeek.length() == 0) {
			return "{\"ok\":false,\"message\":\"scorecardWeek is required\"}";
		}

		db.update("DELETE FROM projected_scorecard WHERE scorecard_week="
				+ db.getInsertDBValue(scorecardWeek));
		boolean ok = true;
		int rowsInserted = 0;

		for (int i = 0; i < 7; i++) {
			String idx = String.valueOf(i);
			String scoreDay = getReq(requestMap, "r" + idx + "_day", "");
			if (scoreDay.length() == 0)
				continue;

			String nextDayTarget = getReq(requestMap,
					"r" + idx + "_next_day_target_score_needed", "0");
			String projectedTier = getReq(requestMap, "r" + idx + "_projected_tier",
					"-");
			String safetyWarning = getReq(requestMap, "r" + idx + "_safety_warning",
					"-");

			String insQry = "INSERT INTO projected_scorecard ("
					+ "scorecard_week, score_day, next_day_target_score_needed, "
					+ "weekly_projection_sun_sat, trips, pickup_quality_score, team_score, "
					+ "packages_dispatched, packages_returned, total_delivered_auto, negative_feedback, dsb_defects, "
					+ "seatbelt_events, speeding_events, sign_signal_events, distraction_events, following_distance_events, "
					+ "seatbelt_rate, speeding_rate, sign_signal_rate, distraction_rate, following_distance_rate, "
					+ "safety_score_daily, cdf_dpmo_running, dsb_dpmo_running, quality_score_running, "
					+ "projected_weekly_score, projected_tier, remaining_cdf_allowed, remaining_dsb_allowed, safety_warning, "
					+ "user_created, user_modified) VALUES ("
					+ db.getInsertDBValue(scorecardWeek) + ", "
					+ db.getInsertDBValue(scoreDay) + ", "
					+ db.getInsertDBValue(nextDayTarget) + ", "
					+ toDecimal(getReq(requestMap, "r" + idx + "_weekly_projection", "0"))
					+ ", " + toInt(getReq(requestMap, "r" + idx + "_trips", "0"))
					+ ", "
					+ toDecimal(getReq(requestMap, "r" + idx + "_pickup_quality_score",
							"0"))
					+ ", "
					+ toDecimal(getReq(requestMap, "r" + idx + "_team_score", "0"))
					+ ", "
					+ toInt(getReq(requestMap, "r" + idx + "_packages_dispatched", "0"))
					+ ", "
					+ toInt(getReq(requestMap, "r" + idx + "_packages_returned", "0"))
					+ ", "
					+ toInt(getReq(requestMap, "r" + idx + "_total_delivered_auto", "0"))
					+ ", "
					+ toInt(getReq(requestMap, "r" + idx + "_negative_feedback", "0"))
					+ ", " + toInt(getReq(requestMap, "r" + idx + "_dsb_defects", "0"))
					+ ", "
					+ toInt(getReq(requestMap, "r" + idx + "_seatbelt_events", "0"))
					+ ", "
					+ toInt(getReq(requestMap, "r" + idx + "_speeding_events", "0"))
					+ ", "
					+ toInt(getReq(requestMap, "r" + idx + "_sign_signal_events", "0"))
					+ ", "
					+ toInt(getReq(requestMap, "r" + idx + "_distraction_events", "0"))
					+ ", "
					+ toInt(getReq(requestMap, "r" + idx + "_following_distance_events",
							"0"))
					+ ", " + toDecimal(getReq(requestMap, "r" + idx + "_seatbelt_rate",
							"0"))
					+ ", " + toDecimal(getReq(requestMap, "r" + idx + "_speeding_rate",
							"0"))
					+ ", "
					+ toDecimal(getReq(requestMap, "r" + idx + "_sign_signal_rate", "0"))
					+ ", "
					+ toDecimal(getReq(requestMap, "r" + idx + "_distraction_rate", "0"))
					+ ", "
					+ toDecimal(
							getReq(requestMap, "r" + idx + "_following_distance_rate", "0"))
					+ ", "
					+ toDecimal(getReq(requestMap, "r" + idx + "_safety_score_daily",
							"0"))
					+ ", "
					+ toDecimal(getReq(requestMap, "r" + idx + "_cdf_dpmo_running", "0"))
					+ ", "
					+ toDecimal(getReq(requestMap, "r" + idx + "_dsb_dpmo_running", "0"))
					+ ", "
					+ toDecimal(getReq(requestMap, "r" + idx + "_quality_score_running",
							"0"))
					+ ", "
					+ toDecimal(getReq(requestMap, "r" + idx + "_projected_weekly_score",
							"0"))
					+ ", " + db.getInsertDBValue(projectedTier) + ", "
					+ toDecimal(
							getReq(requestMap, "r" + idx + "_remaining_cdf_allowed", "0"))
					+ ", "
					+ toDecimal(
							getReq(requestMap, "r" + idx + "_remaining_dsb_allowed", "0"))
					+ ", " + db.getInsertDBValue(safetyWarning) + ", "
					+ db.getInsertDBValue(loginUser) + ", "
					+ db.getInsertDBValue(loginUser) + ")";

			boolean insOk = db.update(insQry);
			if (insOk)
				rowsInserted++;
			ok = ok && insOk;
		}

		return "{\"ok\":" + ok + ",\"rowsInserted\":" + rowsInserted
				+ ",\"message\":\""
				+ (ok ? "Saved scorecard" : "Failed to save scorecard") + "\"}";
	}

	private String loadScorecardWeek(Map<String, String> requestMap)
			throws Exception {
		String scorecardWeek = getReq(requestMap, "scorecardWeek", "");
		if (scorecardWeek.length() == 0) {
			return "{\"ok\":false,\"message\":\"scorecardWeek is required\",\"rows\":[]}";
		}

		String selQry = "SELECT score_day, next_day_target_score_needed, weekly_projection_sun_sat, "
				+ "trips, pickup_quality_score, team_score, packages_dispatched, packages_returned, total_delivered_auto, "
				+ "negative_feedback, dsb_defects, seatbelt_events, speeding_events, sign_signal_events, "
				+ "distraction_events, following_distance_events, seatbelt_rate, speeding_rate, sign_signal_rate, "
				+ "distraction_rate, following_distance_rate, safety_score_daily, cdf_dpmo_running, dsb_dpmo_running, "
				+ "quality_score_running, projected_weekly_score, projected_tier, remaining_cdf_allowed, "
				+ "remaining_dsb_allowed, safety_warning "
				+ "FROM projected_scorecard WHERE scorecard_week="
				+ db.getInsertDBValue(scorecardWeek) + " ORDER BY id";

		List resultList = db.selectAsList(selQry, 30);
		StringBuffer buff = new StringBuffer();
		buff.append("{\"ok\":true,\"week\":\"").append(jsonEscape(scorecardWeek))
				.append("\",\"rows\":[");
		for (int i = 0; i < resultList.size(); i++) {
			List temp = (List) resultList.get(i);
			if (i > 0)
				buff.append(",");
			buff.append("{");
			buff.append("\"day\":\"").append(jsonEscape(getListData(temp, 0)))
					.append("\",");
			buff.append("\"next_day_target_score_needed\":\"")
					.append(jsonEscape(getListData(temp, 1))).append("\",");
			buff.append("\"weekly_projection\":")
					.append(numJson(getListData(temp, 2))).append(",");
			buff.append("\"trips\":").append(numJson(getListData(temp, 3)))
					.append(",");
			buff.append("\"pickup_quality_score\":")
					.append(numJson(getListData(temp, 4))).append(",");
			buff.append("\"team_score\":").append(numJson(getListData(temp, 5)))
					.append(",");
			buff.append("\"packages_dispatched\":")
					.append(numJson(getListData(temp, 6))).append(",");
			buff.append("\"packages_returned\":")
					.append(numJson(getListData(temp, 7))).append(",");
			buff.append("\"total_delivered_auto\":")
					.append(numJson(getListData(temp, 8))).append(",");
			buff.append("\"negative_feedback\":")
					.append(numJson(getListData(temp, 9))).append(",");
			buff.append("\"dsb_defects\":").append(numJson(getListData(temp, 10)))
					.append(",");
			buff.append("\"seatbelt_events\":")
					.append(numJson(getListData(temp, 11))).append(",");
			buff.append("\"speeding_events\":")
					.append(numJson(getListData(temp, 12))).append(",");
			buff.append("\"sign_signal_events\":")
					.append(numJson(getListData(temp, 13))).append(",");
			buff.append("\"distraction_events\":")
					.append(numJson(getListData(temp, 14))).append(",");
			buff.append("\"following_distance_events\":")
					.append(numJson(getListData(temp, 15))).append(",");
			buff.append("\"seatbelt_rate\":")
					.append(numJson(getListData(temp, 16))).append(",");
			buff.append("\"speeding_rate\":")
					.append(numJson(getListData(temp, 17))).append(",");
			buff.append("\"sign_signal_rate\":")
					.append(numJson(getListData(temp, 18))).append(",");
			buff.append("\"distraction_rate\":")
					.append(numJson(getListData(temp, 19))).append(",");
			buff.append("\"following_distance_rate\":")
					.append(numJson(getListData(temp, 20))).append(",");
			buff.append("\"safety_score_daily\":")
					.append(numJson(getListData(temp, 21))).append(",");
			buff.append("\"cdf_dpmo_running\":")
					.append(numJson(getListData(temp, 22))).append(",");
			buff.append("\"dsb_dpmo_running\":")
					.append(numJson(getListData(temp, 23))).append(",");
			buff.append("\"quality_score_running\":")
					.append(numJson(getListData(temp, 24))).append(",");
			buff.append("\"projected_weekly_score\":")
					.append(numJson(getListData(temp, 25))).append(",");
			buff.append("\"projected_tier\":\"")
					.append(jsonEscape(getListData(temp, 26))).append("\",");
			buff.append("\"remaining_cdf_allowed\":")
					.append(numJson(getListData(temp, 27))).append(",");
			buff.append("\"remaining_dsb_allowed\":")
					.append(numJson(getListData(temp, 28))).append(",");
			buff.append("\"safety_warning\":\"")
					.append(jsonEscape(getListData(temp, 29))).append("\"");
			buff.append("}");
		}
		buff.append("]}");
		return buff.toString();
	}

	private String getReq(Map<String, String> requestMap, String key,
			String defaultValue) {
		String val = requestMap.get(key) == null ? "" : requestMap.get(key);
		return val.length() == 0 ? defaultValue : val.trim();
	}

	private String toInt(String val) {
		try {
			String temp = val == null ? "" : val.replaceAll(",", "").trim();
			if (temp.length() == 0)
				return "0";
			return String.valueOf(Integer.parseInt(temp));
		} catch (Exception ex) {
			return "0";
		}
	}

	private String toDecimal(String val) {
		try {
			String temp = val == null ? "" : val.replaceAll(",", "").trim();
			if (temp.length() == 0)
				return "0";
			return String.valueOf(Double.parseDouble(temp));
		} catch (Exception ex) {
			return "0";
		}
	}

	private String numJson(String val) {
		return toDecimal(val);
	}

	private String jsonEscape(String val) {
		if (val == null)
			return "";
		String out = val;
		out = out.replace("\\", "\\\\");
		out = out.replace("\"", "\\\"");
		out = out.replace("\r", "");
		out = out.replace("\n", " ");
		return out;
	}
}
