package com.dataobjects;

import java.util.ArrayList;
import java.util.List;

import com.beans.MainBean;
import com.beans.SearchBean;
import com.beans.SmartUpload;

public class SmartUploadDAO extends GenericUploadDAO {

	@Override
	public SearchBean searchRecords(SearchBean searchBean, String recordID,
			String loginUser, String loginUserRoles, String loginUserID,
			String entityID) throws Exception {
		SearchBean result = super.searchRecords(searchBean, recordID, loginUser,
				loginUserRoles, loginUserID, entityID);
		result.setController("SmartUpload");
		result.setDisplayName("Smart Upload");
		return result;
	}

	@Override
	public Object[] createRecord(MainBean mainBean, String loginUser,
			String loginUserRoles, String loginUserID, String entityID)
			throws Exception {

		SmartUpload bean = (SmartUpload) mainBean;

		// Wave-sheet screenshots are images: they load through the Wave Sheet
		// page (Operations > Wave Sheet), which OCRs them in the browser.
		if (bean.getUploadFileName().toLowerCase()
				.matches(".*\\.(png|jpe?g|webp|gif|bmp)$")) {
			com.beans.ErrorBean errorType = new com.beans.ErrorBean();
			errorType.setType(com.beans.ErrorBean.enumTypes.warning.toString());
			errorType.setMesg("That looks like a wave-sheet image. Open "
					+ "Operations &rsaquo; Wave Sheet and drop it there - the "
					+ "page reads it and loads the day's route assignments.");
			return new Object[] { "", errorType };
		}

		// Auto-detect table name if not already set
		if (bean.getTableName() == null || bean.getTableName().trim().length() == 0) {
			String detected = detectTableName(bean.getUploadFileName().toLowerCase());
			bean.setTableName(detected);
			bean.setDetectedType(detected);
		} else {
			bean.setDetectedType(bean.getTableName());
		}

		// Auto-set CSV separator
		String fn = bean.getUploadFileName().toLowerCase();
		if ((fn.endsWith(".csv") || fn.endsWith(".txt"))
				&& (bean.getDataSeperator() == null || bean.getDataSeperator().trim().length() == 0)) {
			bean.setDataSeperator(",");
		}

		// Delegate to existing GenericUploadDAO logic
		Object[] result = super.createRecord(bean, loginUser, loginUserRoles, loginUserID, entityID);

		// Fetch row counts from the just-inserted GENERIC_UPLOAD record
		try {
			String selQry = "SELECT TOTAL_ROWS, ACTUAL_ROWS FROM GENERIC_UPLOAD"
					+ " WHERE STATUS != 9"
					+ db.getDataInCondQuery(bean.getUploadFileName(), "FILE_NAME")
					+ db.getIDInCondQuery(entityID, "ENTITYID")
					+ " ORDER BY CREATE_DATE DESC LIMIT 1";
			List countResult = db.selectAsList(selQry, 2);
			if (countResult.size() > 0) {
				List row = (ArrayList) countResult.get(0);
				String total = getListDBData(row, 0);
				String inserted = getListDBData(row, 1);
				bean.setUploadSummary(total + "|" + inserted);
			}
		} catch (Exception ex) {
			// non-critical — summary just won't show counts
		}

		return result;
	}

	public static String detectTableName(String fileName) {
		if (fileName.matches("dsp_overview_dashboard.*\\.(csv|xlsx?)")) return "DashboardOverview";
		if (fileName.matches("safety_dashboard_.*\\.csv"))               return "SafetyDashboard";
		if (fileName.matches("orcas_.*\\.csv"))                          return "Escalations";
		if (fileName.matches(".*sentiment_report.*\\.csv"))              return "Sentiment Survey";
		if (fileName.matches(".*tenure_workforce_das_report.*\\.csv"))   return "Tenure Workforce DAS";
		if (fileName.matches(".*tenure_workforce_calculation.*\\.csv"))  return "Tenure Workforce Weekly";
		if (fileName.matches("itineraries_.*\\.(xlsx?)"))                return "Daily Itineraries";
		if (fileName.matches("routes_.*\\.(xlsx?)"))                     return "Daily Routes";
		if (fileName.matches("da.daily.summary.report.*\\.(xlsx?)"))     return "Daily Routes";
		if (fileName.matches("week.*schedule.*\\.(xlsx?)"))              return "EmployeeSchedule";
		if (fileName.matches(".*schedule.*week.*\\.(xlsx?)"))            return "EmployeeSchedule";
		if (fileName.matches(".*dvic.pre.?trip.*\\.(xlsx?)"))            return "DVIC";
		if (fileName.matches(".*capacity.reliability.*\\.(xlsx?)"))      return "DashboardOverview";
		if (fileName.matches(".*compliance.supplementary.*\\.(xlsx?)"))  return "Compliance Supplementary";
		if (fileName.matches("associatedata.*\\.csv"))                   return "Employee";
		if (fileName.matches("vehiclesdata.*\\.(xlsx?)"))                return "Vehicles";
		if (fileName.matches(".*escalation.*\\.csv"))                    return "Escalations";
		if (fileName.matches(".*delivered.packages.*\\.(csv|xlsx?)"))    return "WST Delivered Packages";
		if (fileName.matches(".*service.details.*\\.(csv|xlsx?)"))       return "WST Service Details";
		if (fileName.matches(".*weekly.report.*\\.(csv|xlsx?)"))         return "WST Weekly Report";
		if (fileName.matches("station.level.metrics.*\\.csv"))           return "Station Level";
		if (fileName.matches("mvpg.package.report.*\\.csv"))             return "WST Delivered Packages";
		if (fileName.matches("dsp_customer_delivery_feedback.*\\.csv"))  return "CDF Feedback";
		if (fileName.matches("dsp_delivery_concessions.*\\.csv"))        return "DSB Details";
		if (fileName.matches("quality_dcr_.*\\.csv"))                    return "QualityOverview-DCR";
		if (fileName.matches("quality_rts_.*\\.csv"))                    return "QualityOverview-RTS";
		if (fileName.matches(".*dabreakutilization.*\\.csv"))            return "DABreakUtilization";
		return "";
	}
}
