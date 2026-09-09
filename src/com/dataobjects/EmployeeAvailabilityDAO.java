package com.dataobjects;

import java.util.ArrayList;
import java.util.List;

import com.beans.EmployeeAvailability;
import com.beans.SearchBean;
import com.util.RecordStatus;

public class EmployeeAvailabilityDAO extends MVPGDAO {

	EmployeeAvailability bean = new EmployeeAvailability();

	@Override
	public SearchBean searchRecords(SearchBean searchBean, String recordID,
			String loginUser, String loginUserRoles, String loginUserID,
			String entityID) throws Exception {

		List<String> labelsList = new ArrayList<String>();

		labelsList.add("Employee");
		labelsList.add("Sun");
		labelsList.add("Mon");
		labelsList.add("Tue");
		labelsList.add("Wed");
		labelsList.add("Thru");
		labelsList.add("Fri");
		labelsList.add("Sat");
		labelsList.add("Review Status");

		searchBean.setWidthColumns(new int[] { 30, 8, 8, 8, 8, 8, 8, 8, 14 });

		searchBean.setDisplayName(bean.getDisplayName());

		searchBean.setController(bean.getController());

		String condQry = "";

		String selQry = "SELECT A.EMPLOYEE_AVAILABILITYID, B.FULLNAME, "
				+ "A.AVAILABILITY, A.REVIEW_STATUS "
				+ " FROM EMPLOYEE_AVAILABILITY A, EMPLOYEE B "
				+ "WHERE A.EMPLOYEEID=B.EMPLOYEEID AND B.REVIEW_STATUS="
				+ RecordStatus.ACTIVE + " AND A.STATUS!=" + RecordStatus.DELETE
				+ " AND B.ENTITYID=" + entityID + condQry
				+ getOrderByQry(searchBean, "2");

		List resultList = db.selectAsList(selQry, 4);
		if (resultList.size() > 0) {
			for (int i = 0; i < resultList.size(); i++) {
				List tempList = (ArrayList) resultList.get(i);
				String employeeAvailablityID = tempList.get(0) == null ? ""
						: tempList.get(0).toString().trim();
				String employeeName = tempList.get(1) == null ? ""
						: tempList.get(1).toString().trim();
				String availability = tempList.get(2) == null ? ""
						: tempList.get(2).toString().trim();
				String reviewStatus = tempList.get(3) == null ? ""
						: tempList.get(3).toString().trim();
				reviewStatus = RecordStatus.RecordStatus[Integer
						.parseInt(reviewStatus)];
				String sun = "", mon = "", tue = "", wed = "", thru = "",
						fri = "", sat = "";
				String splitArray[] = availability.split(",");
				for (int j = 0; j < splitArray.length; j++) {
					splitArray[j] = splitArray[j].trim();
					if (splitArray[j].length() > 0) {
						String data = "<b style=\"color:green\">Available</b>";
						switch (splitArray[j].toLowerCase()) {
						case "sun":
							sun = data;
							break;

						case "mon":
							mon = data;
							break;

						case "tue":
							tue = data;
							break;

						case "wed":
							wed = data;
							break;

						case "thu":
							thru = data;
							break;

						case "fri":
							fri = data;
							break;

						case "sat":
							sat = data;
							break;
						}
					}
				}

				List tempRow = new ArrayList();
				tempRow.add(employeeAvailablityID);
				tempRow.add(employeeName);
				tempRow.add(sun);
				tempRow.add(mon);
				tempRow.add(tue);
				tempRow.add(wed);
				tempRow.add(thru);
				tempRow.add(fri);
				tempRow.add(sat);
				tempRow.add(reviewStatus);
				resultList.set(i, tempRow);
			}
		}

		searchBean.setLabelsList(labelsList);
		searchBean.setDataList(resultList);
		return searchBean;
	}

}
