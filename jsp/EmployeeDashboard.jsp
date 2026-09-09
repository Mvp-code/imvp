<!DOCTYPE html>
<%@ page import="java.util.*, com.util.*"%>
<jsp:useBean id="_errorBean" class="com.beans.ErrorBean" scope="request" />
<jsp:useBean id="_recordBean" class="com.beans.SearchBean" scope="request" />
<%
int submitType = request.getAttribute("submitType") == null ? SubmitType.CREATE : Integer.parseInt(request.getAttribute("submitType").toString().trim());
%>

<script>
function validatePageData(submitType, isValid) {

	if(submitType == <%=SubmitType.CREATE_CONFIRM%>) {
		if(isValid) {
			var mandatoryFieldsArray = new Array();
			var numOfRows = parseInt(document.getElementById("numOfRows").value);
			if(numOfRows == 0) {
				isValid = false;
				alert("Atleast one record is required");
				if(document.formmain.pageSubmitLock != null)
					document.formmain.pageSubmitLock.value = "unlocked";
			} else {
				var selCNT = 0;
				for(var i=0; i<numOfRows; i++) {
					if(!document.getElementById("followupExclude_"+i).checked) {
						mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.getElementById("followupOwner"+i), "Coaching Owner "+(i+1));
						mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.getElementById("followupTargetDate"+i), "Target Completion "+(i+1));
						mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.getElementById("followupStatus"+i), "Status "+(i+1));
						selCNT++;
					}

					document.getElementById("followupOwner"+i).value = document.getElementById("followupOwner_"+i).value;
					document.getElementById("followupTargetDate"+i).value = document.getElementById("followupTargetDate_"+i).value;
					document.getElementById("followupStatus"+i).value = document.getElementById("followupStatus_"+i).value;
					document.getElementById("followupComments"+i).value = document.getElementById("followupComments_"+i).value;
				}

				isValid = validateMandatoryFieldsInForm(mandatoryFieldsArray, isValid);

				if(isValid) {
					if(selCNT == 0) {
						isValid = false;
						alert("Atleast one record is required");
						if(document.formmain.pageSubmitLock != null)
							document.formmain.pageSubmitLock.value = "unlocked";
					}
				}
			}
		}
	}

	return isValid;
}
</script>

<%@ include file="includeHeader.jsp"%>
<div class='row my-2'>
	<div class='col-12 mb-2'>
		<div class='card'>
			<div class='card-header table-title-header m-0 py-2'>
				<div class="row">
					<div class="col-2"></div>
					<div class="col-8" id="pageHeadDivID"><%=_recordBean.getDisplayName()%></div>
					<div class="col-2 text-right my-auto"></div>
				</div>
			</div>

			<%if(_errorBean != null && _errorBean.getType().length() > 0) {%>
				<div class="row text-center"><section class='alert_section'><div class='alert-box <%=_errorBean.getType()%>Color'><%=_errorBean.getMesg()%></div></section></div>
			<%}%>

			<div class='card-body m-1 p-1'>
			<%if(submitType == SubmitType.SEARCH) {
				GregorianCalendar calObj = new GregorianCalendar();
				int currentYear = calObj.get(Calendar.YEAR);
				int currentWeekOfYear = calObj.get(Calendar.WEEK_OF_YEAR);
				%>
				<script>
				function getEmployeeList() {
					deleteRows("employeeTBodyID");
					var srhYear = getSelectBoxValue(document.formmain["srhYear"]);
					var srhWeek = getSelectBoxValue(document.formmain["srhWeek"]);
					if(srhYear.length > 0 && srhWeek.length > 0) {
						var appQry = "&srhYear="+srhYear+"&srhWeek="+srhWeek;
						var xmlHttpRequest = setSynXMLHttpOb("../servlet/MVPGServlet");
						var str = "submitType=10&controller=EmployeeDashboard&requestType=employeeList"+appQry+getEntityParams();
						xmlHttpRequest.send(str);
						var xmlMessage = xmlHttpRequest.responseXML;
						if(xmlMessage.getElementsByTagName("employeeListDetails")[0] != null) {
							var employeeList = xmlMessage.getElementsByTagName("employeeListDetails")[0];
							var len = employeeList.childNodes.length;
							for(var i=0; i<len; i++) {
								var transXML = employeeList.getElementsByTagName("employeeListTrans")[i];
								var dashboard_overviewid = getXMLValue(transXML.getElementsByTagName("dashboard_overviewid")[0]);
								var transporter_id = getXMLValue(transXML.getElementsByTagName("transporter_id")[0]);
								var delivery_associate = getXMLValue(transXML.getElementsByTagName("delivery_associate")[0]);
								var overall_standing = getXMLValue(transXML.getElementsByTagName("overall_standing")[0]);
								var onroad_safety_score = getXMLValue(transXML.getElementsByTagName("onroad_safety_score")[0]);
								var overall_quality_score = getXMLValue(transXML.getElementsByTagName("overall_quality_score")[0]);
								var dashboard_year = getXMLValue(transXML.getElementsByTagName("dashboard_year")[0]);
								var dashboard_week = getXMLValue(transXML.getElementsByTagName("dashboard_week")[0]);
								var packages = getXMLValue(transXML.getElementsByTagName("packages")[0]);
								var rank = (i+1)+" / "+len;
								var email = getXMLValue(transXML.getElementsByTagName("email")[0]);
								var fantasticCNT = getXMLValue(transXML.getElementsByTagName("fantasticCNT")[0]);
								var greatCNT = getXMLValue(transXML.getElementsByTagName("greatCNT")[0]);
								var fairCNT = getXMLValue(transXML.getElementsByTagName("fairCNT")[0]);
								var poorCNT = getXMLValue(transXML.getElementsByTagName("poorCNT")[0]);

								buildEmployeeRow(dashboard_overviewid, transporter_id, dashboard_year, dashboard_week, delivery_associate, onroad_safety_score, overall_quality_score, overall_standing, packages, rank, email, fantasticCNT, greatCNT, fairCNT, poorCNT);
							}
						}
					}
				}

				function buildEmployeeRow(dashboard_overviewid, transporter_id, dashboard_year, dashboard_week, delivery_associate, onroad_safety_score, overall_quality_score, overall_standing, packages, rank, email, fantasticCNT, greatCNT, fairCNT, poorCNT) {

					var tBodyDivID = document.getElementById("employeeTBodyID");
					var rowIndex = tBodyDivID.rows.length;
					var newRow = tBodyDivID.insertRow(rowIndex);
					newRow.className = "tr-block";
					var newCell = newRow.insertCell(0);
					newCell.className = "td-block table-value text-left text-md-center";
					newCell.setAttribute("colSpan", "2");
					newCell.setAttribute("data-th", "Select");
					newCell.innerHTML = '<button class="my-view-btn" onClick=Javascript:getEmployeeData("'+dashboard_overviewid+'","'+transporter_id+'");>View</button>';
					var newCell = newRow.insertCell(1);
					newCell.className = "td-block table-value";
					newCell.setAttribute("data-th", "Employee");
					newCell.innerHTML = delivery_associate;
					var newCell = newRow.insertCell(2);
					newCell.className = "td-block table-value";
					newCell.setAttribute("data-th", "OnRoad Safety Score");
					newCell.innerHTML = onroad_safety_score;
					var newCell = newRow.insertCell(3);
					newCell.className = "td-block table-value";
					newCell.setAttribute("data-th", "Overall Quality Score");
					newCell.innerHTML = overall_quality_score;
					var newCell = newRow.insertCell(4);
					newCell.className = "td-block table-value";
					newCell.setAttribute("data-th", "Overall Tier");
					newCell.innerHTML = overall_standing;
					var newCell = newRow.insertCell(5);
					newCell.className = "td-block table-value";
					newCell.setAttribute("data-th", "Packages");
					newCell.innerHTML = packages;
					var newCell = newRow.insertCell(6);
					newCell.className = "td-block table-value";
					newCell.setAttribute("data-th", "Rank");
					newCell.innerHTML = rank;
					var newCell = newRow.insertCell(7);
					newCell.className = "td-block table-value";
					newCell.setAttribute("data-th", "Email");
					newCell.innerHTML = email;
					var newCell = newRow.insertCell(8);
					newCell.className = "td-block table-value text-left text-md-center";
					newCell.setAttribute("data-th", "Fantastic");
					newCell.innerHTML = fantasticCNT;
					var newCell = newRow.insertCell(9);
					newCell.className = "td-block table-value text-left text-md-center";
					newCell.setAttribute("data-th", "Great");
					newCell.innerHTML = greatCNT;
					var newCell = newRow.insertCell(10);
					newCell.className = "td-block table-value text-left text-md-center";
					newCell.setAttribute("data-th", "Fair");
					newCell.innerHTML = fairCNT;
					var newCell = newRow.insertCell(11);
					newCell.className = "td-block table-value text-left text-md-center";
					newCell.setAttribute("data-th", "Poor");
					newCell.innerHTML = poorCNT;
				}

				var followupTargetDate = "";
				var coachingFollowupDataArray = new Array();
				function popupEmployeeDashboard(xmlMessage) {

					coachingFollowupDataArray = new Array();
					var dashboardOverviewID = getXMLValue(xmlMessage.getElementsByTagName("dashboardOverviewID")[0]);
					var coachingFollowupID = getXMLValue(xmlMessage.getElementsByTagName("coachingFollowupID")[0]);
					followupTargetDate = getXMLValue(xmlMessage.getElementsByTagName("followupTargetDate")[0]);
					var shrTransporterID = getXMLValue(xmlMessage.getElementsByTagName("shrTransporterID")[0]);
					updateIDValue("dashboardOverviewID", dashboardOverviewID);

					var innerHTML = "";
					if(xmlMessage.getElementsByTagName("dvicList")[0] != null && xmlMessage.getElementsByTagName("dvicList")[0].childNodes.length > 0) {
						var dvicList = xmlMessage.getElementsByTagName("dvicList")[0];
						var len = dvicList.childNodes.length;
						innerHTML = '<table width="100%" border="0" cellpadding="0" cellspacing="0" class="table table-bordered table-striped table-hover table-sm table-block table-vertical sortable mb-0">';
						for(var i=0; i<len; i++) {
							var transXML = dvicList.getElementsByTagName("dvicListTrans")[i];
							var dvicLabel = getXMLValue(transXML.getElementsByTagName("dvicLabel")[0]);
							var dvicValue1 = getXMLValue(transXML.getElementsByTagName("dvicValue1")[0]);
							var dvicValue2 = getXMLValue(transXML.getElementsByTagName("dvicValue2")[0]);
							var dvicValue3 = getXMLValue(transXML.getElementsByTagName("dvicValue3")[0]);
							var dvicValue4 = getXMLValue(transXML.getElementsByTagName("dvicValue4")[0]);
							var dvicValue5 = getXMLValue(transXML.getElementsByTagName("dvicValue5")[0]);
							var dvicValue6 = getXMLValue(transXML.getElementsByTagName("dvicValue6")[0]);
							var dvicValue7 = getXMLValue(transXML.getElementsByTagName("dvicValue7")[0]);

							if(i == 0) {
								innerHTML += '<thead class="thead-block">';
									innerHTML += '<tr class="tr-block">';
										innerHTML += '<th class="th-block table-header-label text-center" width="16%">'+dvicLabel+'</th>';
										innerHTML += '<th class="th-block table-header-label text-center" width="12%">'+dvicValue1+'</th>';
										innerHTML += '<th class="th-block table-header-label text-center" width="12%">'+dvicValue2+'</th>';
										innerHTML += '<th class="th-block table-header-label text-center" width="12%">'+dvicValue3+'</th>';
										innerHTML += '<th class="th-block table-header-label text-center" width="12%">'+dvicValue4+'</th>';
										innerHTML += '<th class="th-block table-header-label text-center" width="12%">'+dvicValue5+'</th>';
										innerHTML += '<th class="th-block table-header-label text-center" width="12%">'+dvicValue6+'</th>';
										innerHTML += '<th class="th-block table-header-label text-center" width="12%">'+dvicValue7+'</th>';
									innerHTML += '</tr>';
								innerHTML += '</thead>';

								innerHTML += '<tbody class="tbody-block">';
							} else {
								innerHTML += '<tr class="tr-block">';
									innerHTML += '<th class="th-block table-header-label text-left" data-th="">'+dvicLabel+'</th>';
									innerHTML += '<td class="td-block table-value" data-th="">'+dvicValue1+'</td>';
									innerHTML += '<td class="td-block table-value" data-th="">'+dvicValue2+'</td>';
									innerHTML += '<td class="td-block table-value" data-th="">'+dvicValue3+'</td>';
									innerHTML += '<td class="td-block table-value" data-th="">'+dvicValue4+'</td>';
									innerHTML += '<td class="td-block table-value" data-th="">'+dvicValue5+'</td>';
									innerHTML += '<td class="td-block table-value" data-th="">'+dvicValue6+'</td>';
									innerHTML += '<td class="td-block table-value" data-th="">'+dvicValue7+'</td>';
								innerHTML += '<tr>';

								if(dvicValue1.length > 0)
									coachingFollowupDataArray[coachingFollowupDataArray.length] = new Array(dvicLabel, dvicValue1);
								if(dvicValue2.length > 0)
									coachingFollowupDataArray[coachingFollowupDataArray.length] = new Array(dvicLabel, dvicValue2);
								if(dvicValue3.length > 0)
									coachingFollowupDataArray[coachingFollowupDataArray.length] = new Array(dvicLabel, dvicValue3);
								if(dvicValue4.length > 0)
									coachingFollowupDataArray[coachingFollowupDataArray.length] = new Array(dvicLabel, dvicValue4);
								if(dvicValue5.length > 0)
									coachingFollowupDataArray[coachingFollowupDataArray.length] = new Array(dvicLabel, dvicValue5);
								if(dvicValue6.length > 0)
									coachingFollowupDataArray[coachingFollowupDataArray.length] = new Array(dvicLabel, dvicValue6);
								if(dvicValue7.length > 0)
									coachingFollowupDataArray[coachingFollowupDataArray.length] = new Array(dvicLabel, dvicValue7);
							}
						}
						innerHTML += '</tbody></table>';
					}
					innerHTML = buildSection("DVIC / EOC", innerHTML);

					var htmlContent = '<div class="col-12 m-0 p-0 pb-3">';
						htmlContent += '<div class="row form-row">';
							htmlContent += "<div class='col-12'><div class='card'>";
								htmlContent += "<div class='card-header table-title-header m-0 py-2' id='empDashboardTitle'></div>";
								htmlContent += "<div class='card-body m-1 p-1'>";
									htmlContent += '<table width="100%" border="0" cellpadding="0" cellspacing="0" class="table table-bordered table-striped table-hover table-sm table-block table-vertical sortable mb-0">';
										htmlContent += '<thead class="thead-block">';
											htmlContent += '<tr class="tr-block">';
												htmlContent += '<th class="th-block table-header-label text-center" width="6%">Year</th>';
												htmlContent += '<th class="th-block table-header-label text-center" width="6%">Week</th>';
												htmlContent += '<th class="th-block table-header-label text-center" width="20%">Name</th>';
												htmlContent += '<th class="th-block table-header-label text-center" width="10%">OnRoad Safety Score</th>';
												htmlContent += '<th class="th-block table-header-label text-center" width="10%">Overall Quality Score</th>';
												htmlContent += '<th class="th-block table-header-label text-center" width="10%">Overall Tier</th>';
												htmlContent += '<th class="th-block table-header-label text-center" width="8%">Packages</th>';
												htmlContent += '<th class="th-block table-header-label text-center" width="8%">Rank</th>';
												htmlContent += '<th class="th-block table-header-label text-center" width="20%">Email</th>';
											htmlContent += '</tr>';
										htmlContent += '</thead>';
										htmlContent += '<tbody class="tbody-block">';
											htmlContent += '<tr class="tr-block">';
												htmlContent += '<td class="td-block table-value" data-th="Year"><select id="srhYear1" name="srhYear1" class="form-control form-control-sm" onChange=getEmployeeData("","'+shrTransporterID+'",this);><%for(int i=currentYear; i > 1999; i--) {%><option value="<%=i%>"><%=i%></option><%}%></select></td>';
												htmlContent += '<td class="td-block table-value" data-th="Week"><select id="srhWeek1" name="srhWeek1" class="form-control form-control-sm" onChange=getEmployeeData("","'+shrTransporterID+'",this);><option value=""></option><%for(int i=1; i<53; i++) {%><option value="<%=i%>" <%if((currentWeekOfYear-1) == i) {%>selected<%}%>><%=i%></option><%}%></td>';
												htmlContent += '<td class="td-block table-value" data-th="Name" id="empNameTDID"></td>';
												htmlContent += '<td class="td-block table-value" data-th="OnRoad Safety Score" id="empOnroadSafetyScoreTDID"></td>';
												htmlContent += '<td class="td-block table-value" data-th="Overall Quality Score" id="empOverAllQualityScoreTDID"></td>';
												htmlContent += '<td class="td-block table-value" data-th="Overall Tier" id="empOverall_standingTDID"></td>';
												htmlContent += '<td class="td-block table-value" data-th="Packages" id="empPackagesTDID"></td>';
												htmlContent += '<td class="td-block table-value" data-th="Rank" id="empRankTDID"></td>';
												htmlContent += '<td class="td-block table-value" data-th="Email" id="empEmailTDID"></td>';
											htmlContent += '</tr>';
										htmlContent += '</tbody>';
									htmlContent += '</table>';

									htmlContent += '<div class="col-12 m-0 p-0 my-3">';
										htmlContent += '<div class="row">';
											htmlContent += '<div class="col-12 col-md-4" id="safetySectionDivID">'+getSectionData1(xmlMessage, "Safety Metrics", "Safety", "safetyList")+'</div>';
											htmlContent += '<div class="col-12 col-md-4" id="qualitySectionDivID">'+getSectionData1(xmlMessage, "Quality Metrics", "Quality", "qualityList")+'</div>';
											htmlContent += '<div class="col-12 col-md-4" id="incidentSectionDivID">'+getSectionData2(xmlMessage, "Incidents", "Incident", "incidentList")+'</div>';
										htmlContent += '</div>';
										htmlContent += '<div class="row my-3">';
											htmlContent += '<div class="col-12 col-md-4" id="accidentsSectionDivID">'+getSectionData2(xmlMessage, "Accidents", "Accident", "accidentList")+'</div>';
											htmlContent += '<div class="col-12 col-md-8" id="dvicSectionDivID">'+innerHTML+'</div>';
										htmlContent += '</div>';
									htmlContent += '</div>';

									htmlContent += '<div class="col-12 m-0 p-0 my-3">';
										htmlContent += '<div class="row form-row form-group form-group-sm">';
											htmlContent += '<label class="col-12 col-md-2 col-form-label text-left">Coaching Notes</label>';
											htmlContent += '<div class="col-12 col-md-10 text-left"><textarea id="coachingNotes" name="coachingNotes" class="form-control form-control-sm"></textarea></div>';
										htmlContent += '</div>';
										htmlContent += '<div class="row form-row form-group form-group-sm">';
											htmlContent += '<label class="col-12 col-md-2 col-form-label text-left">Coaching Results</label>';
											htmlContent += '<div class="col-12 col-md-10 text-left"><textarea id="coachingResults" name="coachingResults" class="form-control form-control-sm"></textarea></div>';
										htmlContent += '</div>';
									htmlContent += '</div>';

								htmlContent += "</div>";
							htmlContent += "</div></div>";
						htmlContent += '</div>';

						if(dashboardOverviewID.length > 0) {
							htmlContent += '<div class="row form-row my-3">';
								htmlContent += '<div class="row col-12 my-4 text-center text-md-left">';
									htmlContent += '<div class="col-12 col-md-4 mb-2 mb-md-0 text-md-left">';
										if(coachingFollowupID.length > 0) {
											htmlContent += '<button class="my-disabled-btn disabled" Title="Followup already exist" href="#">Followup</button>';
										} else {
											htmlContent += '<button class="my-common-btn" onClick=Javascript:popupCoachingFollowup();>Followup</button>';
										}
									htmlContent += '</div>';

									htmlContent += '<div class="col-12 col-md-4 mb-2 mb-md-0 text-md-center">';
										htmlContent += '<button class="my-print-btn" onClick=Javascript:searchPageDataForm("<%=SubmitType.PRINT%>","<%=_recordBean.getController()%>");>Print</button>';
										htmlContent += '&nbsp;&nbsp;&nbsp;&nbsp;<button class="my-mail-btn" onClick=#;>Mail</button>';
									htmlContent += '</div>';

									htmlContent += '<div class="col-12 col-md-4 mb-2 mb-md-0 text-md-right"><button class="my-close-btn" onClick=Javascript:TINY.box.hide();>Close</button></div>';
								htmlContent += '</div>';
							htmlContent += '</div>';
						}

						htmlContent += '<div class="row form-row my-3"><div class="col-12">&nbsp;</div></div>';
					htmlContent += '</div>';

					TINY.box.show({
						html:htmlContent,
						fixed:false,
						maskid:'frameless',
						width:1600,
						maskopacity:40,
						openjs:function() {
							if(xmlMessage.getElementsByTagName("section1List")[0] != null) {
								var section1List = xmlMessage.getElementsByTagName("section1List")[0];
								var len = section1List.childNodes.length;
								for(var i=0; i<len; i++) {
									var transXML = section1List.getElementsByTagName("section1ListTrans")[i];
									var label = getXMLValue(transXML.getElementsByTagName("label")[0]);
									var value = getXMLValue(transXML.getElementsByTagName("value")[0]);
									if(label == "Year") {
										updateIDInnerHTML("empYearTDID", value);
										updateIDValue("srhYear1", value);
									} else if(label == "Week") {
										updateIDInnerHTML("empWeekTDID", value);
										updateIDValue("srhWeek1", value);
									} else if(label == "Name") {
										updateIDInnerHTML("empDashboardTitle", value+" - Dashboard");
										updateIDInnerHTML("empNameTDID", value);
										updateIDValue("srhEmpName", value);
									} else if(label == "OnRoad Safety Score") {
										updateIDInnerHTML("empOnroadSafetyScoreTDID", value);
									} else if(label == "Overall Quality Score") {
										updateIDInnerHTML("empOverAllQualityScoreTDID", value);
									} else if(label == "Overall Tier") {
										updateIDInnerHTML("empOverall_standingTDID", value);
									} else if(label == "Packages") {
										updateIDInnerHTML("empPackagesTDID", value);
									} else if(label == "Rank") {
										updateIDInnerHTML("empRankTDID", value);
									} else if(label == "Email") {
										updateIDInnerHTML("empEmailTDID", value);
									}
								}
							}
							if(dashboardOverviewID.length == 0) {
								updateIDInnerHTML("empDashboardTitle", "<span class='text-danger'><B>Data not found for this criteria</B></span>");
							}
						}
					});
				}

				function getSectionData1(xmlMessage, sectionTitle, sectionType, selctionListName) {

					var innerHTML = "";
					if(xmlMessage.getElementsByTagName(selctionListName)[0] != null && xmlMessage.getElementsByTagName(selctionListName)[0].childNodes.length > 0) {
						var selctionList = xmlMessage.getElementsByTagName(selctionListName)[0];
						var len = selctionList.childNodes.length;
						for(var i=0; i<len; i++) {
							var transXML = selctionList.getElementsByTagName(selctionListName+"Trans")[i];
							var label = getXMLValue(transXML.getElementsByTagName("label")[0]);
							var value = getXMLValue(transXML.getElementsByTagName("value")[0]);
							innerHTML += builSectionRow(sectionType, label, value);
						}
					}
					return buildSection(sectionTitle, innerHTML);
				}

				function getSectionData2(xmlMessage, sectionTitle, sectionType, selctionListName) {

					var innerHTML = "";
					if(xmlMessage.getElementsByTagName(selctionListName)[0] != null && xmlMessage.getElementsByTagName(selctionListName)[0].childNodes.length > 0) {
						var selctionList = xmlMessage.getElementsByTagName(selctionListName)[0];
						var len = selctionList.childNodes.length;
						for(var i=0; i<len; i++) {
							var transXML = selctionList.getElementsByTagName(selctionListName+"Trans")[i];
							var incidentID = getXMLValue(transXML.getElementsByTagName("incidentID")[0]);
							var incidentDate = getXMLValue(transXML.getElementsByTagName("incidentDate")[0]);
							var incidentType = getXMLValue(transXML.getElementsByTagName("incidentType")[0]);
							var incidentDesc = getXMLValue(transXML.getElementsByTagName("incidentDesc")[0]);
							if(i > 0)
								innerHTML += '<div class="row"><div class="col-12 m-0 p-0"><HR></div></div>';
							innerHTML += buildIncidentRow("Date", incidentDate);
							innerHTML += buildIncidentRow("Type", incidentType);
							innerHTML += buildIncidentRow("Desc", incidentDesc);
							coachingFollowupDataArray[coachingFollowupDataArray.length] = new Array(sectionType, incidentType);
						}
					}
					return buildSection(sectionTitle, innerHTML);
				}

				function getEmployeeData(dashboard_overviewid, transporter_id, thisObj) {

					var srhYear = getSelectBoxValue(document.formmain["srhYear"]);
					var srhWeek = getSelectBoxValue(document.formmain["srhWeek"]);
					if(thisObj != null) {
						if(thisObj.name == "srhYear1" || thisObj.name == "srhWeek1") {
							srhYear = getSelectBoxValue(document.getElementById("srhYear1"));
							srhWeek = getSelectBoxValue(document.getElementById("srhWeek1"));
						}
					}
					console.log("getEmployeeData :: "+srhYear+" :: "+srhWeek+" :: "+dashboard_overviewid+" :: "+transporter_id);
					if(srhYear.length > 0 && srhWeek.length > 0 && (dashboard_overviewid.length > 0 || transporter_id.length > 0)) {
						var appQry = "&srhYear="+srhYear+"&srhWeek="+srhWeek+"&srhTransporterID="+transporter_id+"&srhDashboardOverviewID="+dashboard_overviewid;
						var xmlHttpRequest = setSynXMLHttpOb("../servlet/MVPGServlet");
						var str = "submitType=10&controller=EmployeeDashboard&requestType=employeeData"+appQry+getEntityParams();
						xmlHttpRequest.send(str);
						var xmlMessage = xmlHttpRequest.responseXML;

						popupEmployeeDashboard(xmlMessage);
					}
				}

				function popupCoachingFollowup() {
					var followupSectionDivID = "";
					var htmlContent = '<div class="col-12 m-0 p-0 pb-3">';
						htmlContent += '<div class="row form-row">';
							htmlContent += "<div class='col-12'><div class='card'>";
								htmlContent += "<div class='card-header table-title-header m-0 py-2'>Coaching Followup</div>";
								htmlContent += "<div class='card-body m-1 p-1'>";
									htmlContent += '<table width="100%" border="0" cellpadding="0" cellspacing="0" class="table table-bordered table-striped table-hover table-sm table-block table-vertical sortable mb-0">';
										htmlContent += '<thead class="thead-block">';
											htmlContent += '<tr class="tr-block">';
												htmlContent += '<th class="th-block table-header-label text-center" width="10%">Year</th>';
												htmlContent += '<th class="th-block table-header-label text-center" width="10%">Week</th>';
												htmlContent += '<th class="th-block table-header-label text-center" width="80%">Name</th>';
											htmlContent += '</tr>';
										htmlContent += '</thead>';
										htmlContent += '<tbody class="tbody-block">';
											htmlContent += '<tr class="tr-block">';
												htmlContent += '<td class="td-block table-value" data-th="Year" id="followupYearTDID">'+document.getElementById("srhYear").value+'</td>';
												htmlContent += '<td class="td-block table-value" data-th="Week" id="followupWeekTDID">'+document.getElementById("srhWeek").value+'</td>';
												htmlContent += '<td class="td-block table-value" data-th="Name" id="followupNameTDID">'+document.getElementById("srhEmpName").value+'</td>';
											htmlContent += '</tr>';
										htmlContent += '</tbody>';
									htmlContent += '</table>';

									htmlContent += '<table width="100%" border="0" cellpadding="0" cellspacing="0" class="table table-bordered table-striped table-hover table-sm table-block table-vertical sortable mb-0 mt-3">';
										htmlContent += '<thead class="thead-block">';
											htmlContent += '<tr class="tr-block">';
												htmlContent += '<th class="th-block table-header-label required text-center" width="5%" title="Exclude">Ex</th>';
												htmlContent += '<th class="th-block table-header-label text-center" width="10%">Category</th>';
												htmlContent += '<th class="th-block table-header-label text-center" width="20%">Metric</th>';
												htmlContent += '<th class="th-block table-header-label required text-center" width="15%">Coaching Owner</th>';
												htmlContent += '<th class="th-block table-header-label required text-center" width="10%">Target Date</th>';
												htmlContent += '<th class="th-block table-header-label required text-center" width="15%">Coaching Status</th>';
												htmlContent += '<th class="th-block table-header-label text-center" width="25%">Description</th>';
											htmlContent += '</tr>';
										htmlContent += '</thead>';
										htmlContent += '<tbody class="tbody-block">';
										for(var i=0; i<coachingFollowupDataArray.length; i++) {
											htmlContent += '<tr class="tr-block">';
												htmlContent += '<td class="td-block table-value text-center" data-th="Exclude"><input type="checkbox" id="followupExclude_'+i+'" name="followupExclude_'+i+'" value="'+i+'"></td>';

												htmlContent += '<td class="td-block table-value" data-th="Category">'+coachingFollowupDataArray[i][0]+'</td>';

												htmlContent += '<td class="td-block table-value" data-th="Metric">'+coachingFollowupDataArray[i][1]+'</td>';

												htmlContent += '<td class="td-block table-value" data-th="Coaching Owner"><select id="followupOwner_'+i+'" name="followupOwner_'+i+'" class="form-control form-control-sm"><option value=""></option></select></td>';

												htmlContent += '<td class="td-block table-value" data-th="Target Date"><input type="text" id="followupTargetDate_'+i+'" name="followupTargetDate_'+i+'" class="form-control form-control-sm datepicker" value="'+followupTargetDate+'"></td>';

												htmlContent += '<td class="td-block table-value" data-th="Coaching Status"><select id="followupStatus_'+i+'" name="followupStatus_'+i+'" class="form-control form-control-sm"><option value="Not started" selected>Not started</option><option value="Inprogress">Inprogress</option><option value="Monitoring">Monitoring</option><option value="No improvement">No improvement</option><option value="Can Improve">Can Improve</option><option value="Improving">Improving</option><option value="Closed">Closed</option></select></td>';

												htmlContent += '<td class="td-block table-value" data-th="Description"><textarea id="followupComments_'+i+'" name="followupComments_'+i+'" class="form-control form-control-sm" rows="1" maxLength="2000"></textarea></td>';
											htmlContent += '</tr>';

											followupSectionDivID += '<input type="hidden" id="followupCategory'+i+'" name="followupCategory'+i+'" class="form-control form-control-sm" value="'+coachingFollowupDataArray[i][0]+'">';
											followupSectionDivID += '<input type="hidden" id="followupMetric'+i+'" name="followupMetric'+i+'" class="form-control form-control-sm" value="'+coachingFollowupDataArray[i][1]+'">';
											followupSectionDivID += '<input type="hidden" id="followupOwner'+i+'" name="followupOwner'+i+'" class="form-control form-control-sm" value="">';
											followupSectionDivID += '<input type="hidden" id="followupTargetDate'+i+'" name="followupTargetDate'+i+'" class="form-control form-control-sm" value="">';
											followupSectionDivID += '<input type="hidden" id="followupStatus'+i+'" name="followupStatus'+i+'" class="form-control form-control-sm" value="">';
											followupSectionDivID += '<input type="hidden" id="followupComments'+i+'" name="followupComments'+i+'" class="form-control form-control-sm" value="">';
										}
										htmlContent += '</tbody>';
									htmlContent += '</table>';

								htmlContent += "</div>";
							htmlContent += "</div></div>";
						htmlContent += '</div>';

						htmlContent += '<div class="row form-row my-3">';
							htmlContent += '<div class="row col-12">';
								htmlContent += '<div class="col-4 text-right"></div>';

								htmlContent += '<div class="col-4 text-center"><button class="my-save-btn" onClick=Javascript:submitPageDataForm("<%=SubmitType.CREATE_CONFIRM%>","<%=_recordBean.getController()%>");>Save</button></div>';

								htmlContent += '<div class="col-4 text-right"><button class="my-close-btn" onClick=Javascript:TINY.box.hide();>Close</button></div>';
							htmlContent += '</div>';
						htmlContent += '</div>';
					htmlContent += '</div>';

					TINY.box.show({
						html:htmlContent,
						fixed:false,
						maskid:'frameless',
						width:1600,
						maskopacity:40,
						openjs:function() {
							reloadDatePicker();
							updateIDInnerHTML("followupSectionDivID", followupSectionDivID);
							document.formmain["numOfRows"].value = coachingFollowupDataArray.length;
							for(var i=0; i<coachingFollowupDataArray.length; i++) {
								initSelect2SuggestorConvert("followupStatus_"+i, "", false, 50);
								initSelect2Suggestor("coachingOwner", "followupOwner_"+i, "", false, "");
							}
						}
					});
				}

				function searchPageDataForm(submitType, controller, tempType) {
					var appQry= "&printType="+tempType;
					window.open("../servlet/MVPGServlet?submitType="+submitType+"&controller="+controller+"&searchFilter=yes&requestType=search&selectedType="+submitType+appQry+getPageSubmitFormValues());
				}

				function buildSection(heading, dataHTML) {
					var innerHTML = '<div class="card">';
						innerHTML += '<div class="card-header table-title-header m-0 py-2">'+heading+'</div>';
						innerHTML += '<div class="card-body m-1 p-1">';
							if(dataHTML.length > 0)
								innerHTML += '<div class="col-12 m-0 p-0">'+dataHTML+'</div>';
							else if(document.getElementById("dashboardOverviewID") && document.getElementById("dashboardOverviewID").value.length > 0)
								innerHTML += '<div class="col-12 m-0 p-0 text-center"><B>Fantastic</B></div>';
						innerHTML += '</div>';
					innerHTML += '</div>';
					return innerHTML;
				}

				function builSectionRow(section, label, value) {
					var innerHTML = '<div class="row">';
						innerHTML += '<label class="col-8 col-form-label text-left">'+label+'</label>';
						innerHTML += '<div class="col-4 form-control-plaintext text-left">'+value+'</div>';
					innerHTML += '</div>';

					value = value.length == 0 ? "0" : value;
					var sectionVal = parseFloat(value);
					if(sectionVal > 0.0) {
						coachingFollowupDataArray[coachingFollowupDataArray.length] = new Array(section, label);
					}
					return innerHTML;
				}

				function buildIncidentRow(label, value) {
					var innerHTML = '<div class="row">';
						innerHTML += '<label class="col-3 col-form-label text-left">'+label+'</label>';
						innerHTML += '<div class="col-9 form-control-plaintext text-left">'+value+'</div>';
					innerHTML += '</div>';
					return innerHTML;
				}
				</script>

				<input type="hidden" id="dashboardOverviewID" name="dashboardOverviewID" value="0">
				<input type="hidden" id="srhEmpName" name="srhEmpName" value="">
				<input type="hidden" id="numOfRows" name="numOfRows" value="0">
				<input type="hidden" id="dynamicParams" name="dynamicParams" value="followupCategory,followupMetric,followupOwner,followupTargetDate,followupStatus,followupComments">

				<div class="row">
					<div class="col-12 py-3">
						<div class="card">
							<div class="card-body m-1 p-1">
								<table width="100%" border="0" cellpadding="0" cellspacing="0" class="table table-bordered table-striped table-hover table-sm table-block table-vertical sortable mb-0">
									<thead class="thead-block">
										<tr class="tr-block">
											<th class="th-block table-header-label required text-center" width="6%">Year</th>
											<th class="th-block table-header-label required text-center" width="5%">Week</th>
											<th class="td-block table-value" width="73%" colSpan="7"></th>
											<th class="th-block table-header-label text-center" width="16%" colSpan="4">Past 6 Weeks</th>
										</tr>
									</thead>
									<tbody class="tbody-block">
										<tr class="tr-block">
											<td class="td-block table-value pt-3" data-th="Year" width="6%"><select id="srhYear" name="srhYear" onChange="getEmployeeList();"><%for(int i=currentYear; i > 1999; i--) {%><option value="<%=i%>"><%=i%></option><%}%></select></td>

											<td class="td-block table-value pt-3" data-th="Week" width="5%"><select id="srhWeek" name="srhWeek" onChange="getEmployeeList();"><option value=""></option><%for(int i=1; i<53; i++) {%><option value="<%=i%>" <%if((currentWeekOfYear-1) == i) {%>selected<%}%>><%=i%></option><%}%></select></td>

											<th class="th-block table-header-label text-center" width="16%">Name</th>
											<th class="th-block table-header-label text-center" width="8%">OnRoad Safety Score</th>
											<th class="th-block table-header-label text-center" width="8%">Overall Quality Score</th>
											<th class="th-block table-header-label text-center" width="8%">Overall Tier</th>
											<th class="th-block table-header-label text-center" width="8%">Packages</th>
											<th class="th-block table-header-label text-center" width="5%">Rank</th>
											<th class="th-block table-header-label text-center" width="20%">Email</th>

											<th class="th-block table-header-label text-center" width="4%">Fant</th>
											<th class="th-block table-header-label text-center" width="4%">Great</th>
											<th class="th-block table-header-label text-center" width="4%">Fair</th>
											<th class="th-block table-header-label text-center" width="4%">Poor</th>
										</tr>
									</tbody>

									<tbody class="tbody-block" id="employeeTBodyID">
									</tbody>
								</table>
							</div>
						</div>
					</div>
				</div>

				<div id="followupSectionDivID"></div>
				<script>
					initSelect2SuggestorConvert("srhYear", "", false);
					initSelect2SuggestorConvert("srhWeek", "", false);
				</script>
			<%}%>
			</div>
		</div>

		<%if(submitType == SubmitType.SEARCH) {%>
			<div class="row mt-4">
				<div class="col-4 text-right" id="leftButtonsDivID"></div>
				<div class="col-4 text-center" id="centerButtonsDivID"></div>
				<div class="col-4 text-right" id="rightButtonsDivID"></div>
			</div>
			<script>getEmployeeList();</script>
		<%}%>
	</div>
</div>

<%@ include file="includeFooter.jsp"%>