<!DOCTYPE html>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*, com.util.*"%>
<jsp:useBean id="_recordBean" class="com.beans.SearchBean" scope="request" />
<jsp:useBean id="_errorBean" class="com.beans.ErrorBean" scope="request" />
<jsp:useBean id="_mainUtil" class="com.util.MainUtil" scope="request" />
<jsp:useBean id="_vehicleInspection" class="com.beans.VehicleInspection" scope="request" />
<%
// --- JSP-level routing guard: SmartUpload / UploadHistory render their own pages.
// Works without recompiling MVPGCtrl. (MVPGCtrl also has this routing; this is a
// no-recompile fallback. Harmless to keep once the servlet is rebuilt.)
{
  String _fwdCtrl = (_recordBean != null && _recordBean.getController() != null)
                    ? _recordBean.getController() : "";
  if ("SmartUpload".equalsIgnoreCase(_fwdCtrl)) {
    request.getRequestDispatcher("/jsp/SmartUpload.jsp").forward(request, response);
    return;
  }
  if ("UploadHistory".equalsIgnoreCase(_fwdCtrl)) {
    request.getRequestDispatcher("/jsp/UploadHistory.jsp").forward(request, response);
    return;
  }
}
int submitType = request.getAttribute("submitType") == null ? SubmitType.CREATE : Integer.parseInt(request.getAttribute("submitType").toString().trim());
boolean isNewReq = true, isSearchFilter = true, isBrowseReq = true;
boolean isActiveRecords = false, isFileUploadReq = false;
int numOfValues = 0;
String employeesTxt = "employeesTxt", vehiclesTxt = "vehiclesTxt", gasCardsTxt = "gasCardsTxt";
String _array[][] = null ;
Map _dispatcherMap = new HashMap();
if(_recordBean.getTransMap().get("_dispatcherMap") != null) 
	_dispatcherMap = (Map) _recordBean.getTransMap().get("_dispatcherMap");

List emojiList = new ArrayList();
if(_recordBean.getTransMap().get("emojiList") != null)  {
	emojiList = (List) _recordBean.getTransMap().get("emojiList");
	System.out.println("emojiList :: "+emojiList);
}
if("EmployeeAvailability".equalsIgnoreCase(_recordBean.getController()) || 
"OnBoarding".equalsIgnoreCase(_recordBean.getController()) || 
"GenericUpload".equalsIgnoreCase(_recordBean.getController())  || 
"CommonUpload".equalsIgnoreCase(_recordBean.getController()) || 
"Reports".equalsIgnoreCase(_recordBean.getController()) || 
"EmployeeRequest".equalsIgnoreCase(_recordBean.getController()) || 
"AdminConfiguration".equalsIgnoreCase(_recordBean.getController()) || 
"EmployeeCoachingFollowup".equalsIgnoreCase(_recordBean.getController())) { isNewReq = false; }

if("EmployeeAvailability".equalsIgnoreCase(_recordBean.getController()) || 
"EmployeeSchedule".equalsIgnoreCase(_recordBean.getController()) || 
"OnBoarding".equalsIgnoreCase(_recordBean.getController()) || 
"GenericUpload".equalsIgnoreCase(_recordBean.getController())  || 
"DAStatus".equalsIgnoreCase(_recordBean.getController())  || 
"CommonUpload".equalsIgnoreCase(_recordBean.getController()) || 
"EmployeeRequest".equalsIgnoreCase(_recordBean.getController()) || 
"Reports".equalsIgnoreCase(_recordBean.getController())) { isBrowseReq = false; }

if("EmployeeAvailability".equalsIgnoreCase(_recordBean.getController()) || 
"OnBoarding".equalsIgnoreCase(_recordBean.getController()) || 
"Reports".equalsIgnoreCase(_recordBean.getController())) { isSearchFilter = false; }

if("OnBoarding".equalsIgnoreCase(_recordBean.getController()) || 
"GenericUpload".equalsIgnoreCase(_recordBean.getController()) || 
"CommonUpload".equalsIgnoreCase(_recordBean.getController())) { isFileUploadReq = true; }
%>

<script>
function validatePageData(submitType, isValid) {
	return isValid;
}

function viewFile(recordID) {
	window.open("../servlet/MVPGServlet?submitType=<%=SubmitType.PRINT%>&controller=CommonUpload&recordID="+recordID+getPageSubmitFormValues(true));
}

function deleteSearchRecord(recordID) {
	if(deleteRecord()) {
		document.formmain.action = "../servlet/MVPGServlet?submitType=<%=SubmitType.SEARCH%>&controller=<%=_recordBean.getController()%>&searchFilter=yes&selectedType=<%=SubmitType.DELETE%>&selectedValues="+recordID;
		document.formmain.submit();
	}
}

function updateConfiguration(rowIndex, recordID, controller) {

	var category = document.getElementById("Category"+rowIndex).value;
	var name = document.getElementById("Name"+rowIndex).value;
	var value = document.getElementById("Value"+rowIndex).value;
	var status = document.getElementById("Status"+rowIndex).value;
	var appQry = "&propCategory="+category+"&propName="+name+"&propValue="+value+"&propStatus="+status;

	var xmlHttpRequest = setSynXMLHttpOb("../servlet/MVPGServlet");
	var str = "submitType=10&controller=<%=_recordBean.getController()%>&requestType=updateRecord&propID="+recordID+appQry+getEntityParams();
	xmlHttpRequest.send(str);
	var xmlMessage = xmlHttpRequest.responseXML;
	var status = getXMLValue(xmlMessage.getElementsByTagName("status")[0]);
	if(status != "true")
		alert("Problem in updating status");
	else
		submitPageDataForm('<%=SubmitType.SEARCH%>','<%=_recordBean.getController()%>','','','&searchFilter=yes');
}

function updateRecordStatus(thisObj,recordID) {
	var xmlHttpRequest = setSynXMLHttpOb("../servlet/MVPGServlet");
	var index = thisObj.name.replace("recordStatus", "");
	var appQry = "&recordStatus="+thisObj.value;
	if(document.formmain["confirmedBy"+index]) {
		if(document.formmain["confirmedBy"+index].value.length > 0) {
			appQry += "&confirmedBy="+document.formmain["confirmedBy"+index].value;
		} else {
			appQry += "&confirmedBy="+document.formmain["loginUser"].value;
		}
	}
	if(document.formmain["comments"+index])
		appQry += "&comments="+document.formmain["comments"+index].value;

	var str = "submitType=10&controller=<%=_recordBean.getController()%>&requestType=updateStatus&recordID="+recordID+appQry+getEntityParams();
	xmlHttpRequest.send(str);
	var xmlMessage = xmlHttpRequest.responseXML;
	var status = getXMLValue(xmlMessage.getElementsByTagName("status")[0]);
	if(status != "true") {
		alert("Problem in updating status");
	}
}

function checkDuplicateEntry(thisObj, dupIDArray, dupNameArray) {

	var tempID = thisObj.value;
	if(tempID.length > 0) {
		if(!dupIDArray.includes(tempID)) {
			dupIDArray.push(tempID);
		} else {
			var tempName = getSelectBoxText(thisObj);
			if(!dupNameArray.includes(tempName)) {
				dupNameArray.push(tempName);
			}
		}
	}

	return new Array(dupIDArray, dupNameArray);
}

function showDayFilter(day) {

	var dateObj = new Date();
	if(day == "left") {
		if(document.formmain["srhFromDate"].value.length > 0) {
			dateObj = new Date(document.formmain["srhFromDate"].value);
			dateObj.setDate(dateObj.getDate() - 1);
			var dayVal = dateObj.getDate();
			var monthVal = dateObj.getMonth()+1;
			var yearVal = dateObj.getFullYear();
			if(dayVal < 10)
				dayVal = "0"+dayVal;
			if(monthVal < 10)
				monthVal = "0"+monthVal;
			var dateVal = monthVal+"/"+dayVal+"/"+yearVal;

			document.formmain["srhFromDate"].value = dateVal;
			document.formmain["srhToDate"].value = dateVal;
			submitPageDataForm('<%=SubmitType.SEARCH%>','<%=_recordBean.getController()%>','','','&searchFilter=yes');
		}

	} else if(day == "right") {
		if(document.formmain["srhToDate"].value.length > 0) {
			dateObj = new Date(document.formmain["srhToDate"].value);
			dateObj.setDate(dateObj.getDate() + 1);
			var dayVal = dateObj.getDate();
			var monthVal = dateObj.getMonth()+1;
			var yearVal = dateObj.getFullYear();
			if(dayVal < 10)
				dayVal = "0"+dayVal;
			if(monthVal < 10)
				monthVal = "0"+monthVal;
			var dateVal = monthVal+"/"+dayVal+"/"+yearVal;

			document.formmain["srhFromDate"].value = dateVal;
			document.formmain["srhToDate"].value = dateVal;
			submitPageDataForm('<%=SubmitType.SEARCH%>','<%=_recordBean.getController()%>','','','&searchFilter=yes');
		}
	}
}

function searchPageDataForm1(submitType, controller) {
	var isValid = true;
	var mandatoryFieldsArray = new Array();
	<%if("DACheckin".equalsIgnoreCase(_recordBean.getController())) {%>
		var empIDArray = new Array(), empNameArray = new Array();
		var vehIDArray = new Array(), vehNameArray = new Array();
		var numOfRows = parseInt(document.formmain["numOfRows"].value);
		for(var i=0; i<numOfRows; i++) {
			mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["employeeID"+i], "Employee"+(i+1));
			mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["vehicleID"+i], "Vehicle"+(i+1));
			//mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["cdvCertified"+i], "CDV Certified"+(i+1));
			//mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["parking"+i], "Parking"+(i+1));
			//mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["wave"+i], "Wave"+(i+1));
			//mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["gasCard"+i], "Gas Card"+(i+1));
			//mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["phoneCable"+i], "Vehicle"+(i+1));
			var returnArray = checkDuplicateEntry(document.formmain["employeeID"+i], empIDArray, empNameArray);
			empIDArray = returnArray[0];
			empNameArray = returnArray[1];

			returnArray = checkDuplicateEntry(document.formmain["vehicleID"+i], vehIDArray, vehNameArray);
			vehIDArray = returnArray[0];
			vehNameArray = returnArray[1];
		}

		isValid = validateMandatoryFieldsInForm(mandatoryFieldsArray, isValid);
		if(isValid && empNameArray.length > 0) {
			alert("Employee selected for multiple records "+empNameArray);
			isValid = false;

		} else if(isValid && vehNameArray.length > 0) {
			alert("Vehicle selected for multiple records "+vehNameArray);
			isValid = false;
		}

	<%} else if("DAStatus".equalsIgnoreCase(_recordBean.getController())) {%>
		var numOfRows = parseInt(document.formmain["numOfRows"].value);
		for(var i=0; i<numOfRows; i++) {
			mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["confirmedBy"+i], "Confirmed By"+(i+1));
			mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["recordStatus"+i], "Status"+(i+1));
		}

		isValid = validateMandatoryFieldsInForm(mandatoryFieldsArray, isValid);
	<%}%>

	if(isValid) {
		document.formmain.action = "../servlet/MVPGServlet?submitType=<%=SubmitType.SEARCH%>&controller="+controller+"&searchFilter=yes&selectedType="+submitType;
		document.formmain.submit();
	}
}

function searchPageDataForm(submitType, controller, tempType, buttonObj) {

	if(buttonObj) {
		// Prevent double-click
		if (buttonObj.disabled) {
			return false;
		}
		// Lock button immediately
		buttonObj.disabled = true;
	}

	tempType = tempType == undefined ? "" : tempType;
	var isValid = true;
	var appQry = "";
	var tempStatus = "", tempVal = "";
	var selRecordIDs = "", seperator = ",";
	var activeCNT = 0, postCNT = 0;
	var checkoutIDs = "";
	if(document.formmain["selRecordIDs"] != undefined) {
		var thisObj = document.formmain["selRecordIDs"];
		var len = thisObj.length;
		if(len == undefined) {
			if(thisObj.checked) {
				tempVal = thisObj.value;
				selRecordIDs = tempVal;

				if(document.formmain["daCheckoutID"+tempVal]) {
					checkoutIDs = document.formmain["daCheckoutID"+tempVal].value;
				}

				if(document.formmain["sel"+tempVal+"Status"]) {
					tempStatus = document.formmain["sel"+tempVal+"Status"].value;
					if(tempStatus == "Active") {
						activeCNT++;
					} else if(tempStatus == "Posted" || tempStatus == "Completed") {
						postCNT++;
					}
				}
			}

		} else {
			for(var i=0; i<len; i++) {
				if(thisObj[i].checked) {
					if(tempVal == "") {
						tempVal = thisObj[i].value;
						selRecordIDs = tempVal;

						if(document.formmain["daCheckoutID"+tempVal]) {
							if(checkoutIDs.length > 0)
								checkoutIDs += ", ";
							checkoutIDs += document.formmain["daCheckoutID"+tempVal].value;
						}

						if(document.formmain["sel"+tempVal+"Status"]) {
							tempStatus = document.formmain["sel"+tempVal+"Status"].value;
							if(tempStatus == "Active") {
								activeCNT++;
							} else if(tempStatus == "Posted" || tempStatus == "Completed") {
								postCNT++;
							}
						}
					} else {
						tempVal = thisObj[i].value;
						selRecordIDs += seperator + tempVal;

						if(document.formmain["daCheckoutID"+tempVal]) {
							if(checkoutIDs.length > 0)
								checkoutIDs += ", ";
							checkoutIDs += document.formmain["daCheckoutID"+tempVal].value;
						}

						if(document.formmain["sel"+tempVal+"Status"]) {
							tempStatus = document.formmain["sel"+tempVal+"Status"].value;
							if(tempStatus == "Active") {
								activeCNT++;
							} else if(tempStatus == "Posted" || tempStatus == "Completed") {
								postCNT++;
							}
						}
					}
				}
			}
		}
	}

	if(submitType == "<%=SubmitType.PRINT%>") {
		appQry+= "&printType="+tempType;
		tempType = "";

	} else if(submitType == "<%=SubmitType.FINAL%>") {
		srhType = tempType;
		tempType = "";
	}

	if(tempType.length > 0) {
		if(tempType == "Update") {
			document.formmain.action = "../servlet/MVPGServlet?submitType=<%=SubmitType.SEARCH%>&controller="+controller+"&searchFilter=yes&selectedType="+submitType+"&selectedValues="+tempType;
			document.formmain.submit();
		} else {
			// Run and Next Day Run functionality - DA Chcckin
			var dispTempType = tempType;
			if(tempType == "NewRun")
				dispTempType = "New Run";
			else if(tempType == "NewNext Day Run")
				dispTempType = "New Next Day Run";

			if(window.confirm("Are you sure, you want to "+dispTempType+" ?")) {
				document.formmain.action = "../servlet/MVPGServlet?submitType=<%=SubmitType.SEARCH%>&controller="+controller+"&searchFilter=yes&selectedType="+submitType+"&selectedValues="+tempType;
				document.formmain.submit();
			} else {
				isValid = false;
				pageUnlock();
				if(buttonObj)
					buttonObj.disabled = false;
			}
		}

	} else if(submitType == "<%=SubmitType.DYNAMIC%>") {
		if(selRecordIDs.length > 0) {
			var xmlHttpRequest = setSynXMLHttpOb("../servlet/MVPGServlet");
			var str = "submitType="+submitType+"&controller="+controller+"&requestType=sendSMS&selRecordIDs="+selRecordIDs+getEntityParams();
			xmlHttpRequest.send(str);
			var xmlMesg = xmlHttpRequest.responseXML;
			var status = getXMLValue(xmlMesg.getElementsByTagName("status")[0]);
			var mobileNumMissing = getXMLValue(xmlMesg.getElementsByTagName("mobileNumMissing")[0]);
			var failedEmp = getXMLValue(xmlMesg.getElementsByTagName("failedEmp")[0]);
			var alreadySent = getXMLValue(xmlMesg.getElementsByTagName("alreadySent")[0]);
			if(mobileNumMissing.length > 0)
				mobileNumMissing = "\nMobile missing for employees "+mobileNumMissing;
			if(failedEmp.length > 0)
				failedEmp = "\nSMS failed for employees "+failedEmp;
			if(alreadySent.length > 0)
				alreadySent = "\nSMS already sent for employees "+alreadySent;
			if(status == "success") {
				alert("SMS sent successfully"+alreadySent+mobileNumMissing+failedEmp);
			} else {
				alert("Problem in sending SMS"+alreadySent+mobileNumMissing+failedEmp);
			}
		} else {
			alert("Select atleast one record");
		}
		if(buttonObj)
			buttonObj.disabled = false;

	} else if(submitType == "<%=SubmitType.PRINT%>") {
		appQry += "&columnSortName=<%=_recordBean.getColumnSortName()%>&columnSortOrder=<%=_recordBean.getColumnSortOrder()%>";
		if(document.formmain["srhReportType"])
			appQry += "&srhReportType="+document.formmain["srhReportType"].value;
		window.open("../servlet/MVPGServlet?submitType="+submitType+"&controller="+controller+"&searchFilter=yes&requestType=search&selectedType="+submitType+appQry+getPageSubmitFormValues(true)+"&selectedValues="+selRecordIDs);

	} else if(selRecordIDs.length > 0) {
		if(submitType == "<%=SubmitType.DELETE%>") {
			if(postCNT > 0) {
				alert("Please select only Active records to DELETE");
				isValid = false;
				if(buttonObj)
					buttonObj.disabled = false;
			}
			if(isValid)
				isValid = deleteRecord();

		} else if(submitType == "<%=SubmitType.FINAL%>") {
			<%if("DACheckout".equalsIgnoreCase(_recordBean.getController())) {%>
				appQry = "&srhValue2="+geLocaletAuditTime();

			<%} else if("VehicleInspection".equalsIgnoreCase(_recordBean.getController())) {%>
				if(srhType == "DACheckout") {
					appQry = "&srhType="+srhType+"&srhValue2="+geLocaletAuditTime();
					selRecordIDs = checkoutIDs;
				}
			<%}%>

			if(postCNT > 0) {
				alert("Please select only Active records to POST");
				isValid = false;
				if(buttonObj)
					buttonObj.disabled = false;
			}

		} else if(submitType == "<%=SubmitType.UPDATE%>") {
			if(postCNT > 0) {
				alert("Please select only Active records to Swap");
				isValid = false;
				if(buttonObj)
					buttonObj.disabled = false;
			}
		}

		if(isValid) {
			document.formmain.action = "../servlet/MVPGServlet?submitType=<%=SubmitType.SEARCH%>&controller="+controller+"&searchFilter=yes&selectedType="+submitType+"&selectedValues="+selRecordIDs+appQry;
			document.formmain.submit();
		}

	} else {
		if(document.formmain["srhReportType"] != undefined) {
			document.formmain.action = "../servlet/MVPGServlet?submitType=<%=SubmitType.SEARCH%>&controller="+controller+"&searchFilter=yes&selectedType="+submitType+"&selectedValues="+selRecordIDs+appQry;
			document.formmain.submit();
		} else {
			alert("Select atleast one record");
			if(buttonObj)
				buttonObj.disabled = false;
		}
	}
}

function pageOnSubmitFunction() {
	submitPageDataForm('<%=SubmitType.SEARCH%>','<%=_recordBean.getController()%>','','','&searchFilter=yes');
}

function geLocaletAuditTime() {
	var dateObj = new Date();
	var dateDay = dateObj.getDate();
	var dateMonth = dateObj.getMonth()+1;
	var dateYear = dateObj.getFullYear();

	var dateHours = dateObj.getHours();
	var dateMins = dateObj.getMinutes();
	var dateAMPM = dateHours > 12 ? "PM" : "AM";
	if(dateHours > 12)
		dateHours = dateHours-12;
	if(dateHours < 10)
		dateHours = "0"+dateHours;
	if(dateMins < 10)
		dateMins = "0"+dateMins;
	if(dateDay < 10)
		dateDay = "0"+dateDay;
	if(dateMonth < 10)
		dateMonth = "0"+dateMonth;

	var selDate = dateMonth+"/"+dateDay+"/"+dateYear;
	var selTime = dateHours+":"+dateMins+" "+dateAMPM;
	return selTime;
}

function loadReportFilters(reportName) {
	document.getElementById("reportFiltersDivID").innerHTML = "";
	var xmlHttpRequest = setSynXMLHttpOb("../servlet/MVPGServlet");
	var actualReportName = reportName.replace(/ /g, "");
	var str = "submitType=10&controller=Reports&requestType="+actualReportName+getEntityParams();
	xmlHttpRequest.send(str);
	var xmlMessage = xmlHttpRequest.responseXML;
	var tableColsXml = xmlMessage.getElementsByTagName("tableCols")[0]
	var tableColsLen = tableColsXml.childNodes.length;

	var tableFiltersXml = xmlMessage.getElementsByTagName("tableFilters")[0];
	var tableFiltersLen = tableFiltersXml.childNodes.length;

	var displayScreenPrint = false;
	if(reportName == "Safety Dashboard Metrics" || reportName == "DA Daily Summary") {
		displayScreenPrint = true;
	}

	var innerHTML = '';
	innerHTML = '<div class="card">';
		if(tableColsLen > 0) {
			innerHTML += '<div class="card-header table-title-header m-0 py-2"><div class="row"><div class="col-2 font-weight-bold text-left"><input type="checkbox" id="reportColAll" name="reportColAll" value="" onClick="checkOrUncheckValues(this,document.formmain.reportCol);" checked></div><div class="col-8 font-weight-bold">'+reportName+'</div><div class="col-2 font-weight-bold"></div></div></div>';
		} else {
			innerHTML += '<div class="card-header table-title-header m-0 py-2"><div class="row"><div class="col-12 font-weight-bold">'+reportName+'</div></div></div>';
		}
		innerHTML += '<div class="card-body m-1 p-1">';
			innerHTML += '<div class="row col-12">';
			for(var i=0; i<tableColsLen; i++) {
				var colName = getXMLValue(tableColsXml.getElementsByTagName("colName")[i]);
				innerHTML += '<div class="col-12 col-md-4 col-lg-2 mb-2 mb-md-0 text-md-left"><div class="form-check-inline"><label class="form-check-label"><input type="checkbox" id="reportCol" name="reportCol" value="'+colName+'" checked>&nbsp;'+colName.replace(/_/g, " ")+'</label></div></div>';
			}
			innerHTML += '</div>';

			innerHTML += '<div class="col-12 text-center font-weight-bold py-2"><u>Search Criteria</u></div>';
			innerHTML += '<div class="row col-12">';
			for(var i=0; i<tableFiltersLen; i++) {
				var colName = getXMLValue(tableFiltersXml.getElementsByTagName("colName")[i]);
				var displayName = colName.replace(/_/g, " ");
				switch(colName) {
					case "SAFTY_DATE":
					case "EVENT_DATETIME":
						innerHTML += '<div class="col-12 col-md-6 mb-2 mb-md-0 text-md-left">';
							innerHTML += '<div class="row form-row form-group form-group-sm">';
								innerHTML += '<label class="col-4 col-form-label text-left">'+displayName+'</label>';
								innerHTML += '<div class="col-4 text-left"><input type="text" id="srh'+colName+'From" name="srh'+colName+'From" class="form-control form-control-sm datepicker" value=""></div>';
								innerHTML += '<div class="col-4 text-left"><input type="text" id="srh'+colName+'To" name="srh'+colName+'To" class="form-control form-control-sm datepicker" value=""></div>';
							innerHTML += '</div>';
						innerHTML += '</div>';
						break;

					case "DATE_RANGE":
						var dateObj = new Date();
						if(reportName == "DA Daily Summary") {
							dateObj.setDate(dateObj.getDate() - 1);
						}
						var dayVal = dateObj.getDate();
						var monthVal = dateObj.getMonth()+1;
						var yearVal = dateObj.getFullYear();
						if(dayVal < 10)
							dayVal = "0"+dayVal;
						if(monthVal < 10)
							monthVal = "0"+monthVal;
						var dateVal = monthVal+"/"+dayVal+"/"+yearVal;

						innerHTML += '<div class="col-12 col-md-6 mb-2 mb-md-0 text-md-left">';
							innerHTML += '<div class="row form-row form-group form-group-sm">';
								innerHTML += '<label class="col-4 col-form-label text-left">'+displayName+'</label>';
								innerHTML += '<div class="col-4 text-left"><input type="text" id="srhFromDate" name="srhFromDate" class="form-control form-control-sm datepicker" value="'+dateVal+'"></div>';
								innerHTML += '<div class="col-4 text-left"><input type="text" id="srhToDate" name="srhToDate" class="form-control form-control-sm datepicker" value="'+dateVal+'"></div>';
							innerHTML += '</div>';
						innerHTML += '</div>';
						break;

					case "EMPLOYEE":
						innerHTML += '<div class="col-12 col-md-6 mb-2 mb-md-0 text-md-left">';
							innerHTML += '<div class="row form-row form-group form-group-sm">';
								innerHTML += '<label class="col-4 col-form-label text-left">'+displayName+'</label>';
								if(reportName == "DA Daily Summary" || reportName == "SMS Tx Summary") {
									innerHTML += '<div class="col-8 text-left"><select id="srh'+colName+'" name="srh'+colName+'" class="form-control form-control-sm" ><option value=""></option></select></div>';
								} else {
									innerHTML += '<div class="col-8 text-left"><input type="text" id="srhValue" name="srhValue" class="form-control form-control-sm"  value="<%=_recordBean.getSrhValue()%>"></div>';
								}
							innerHTML += '</div>';
						innerHTML += '</div>';
						break;

					default:
						innerHTML += '<div class="col-12 col-md-6 mb-2 mb-md-0 text-md-left">';
							innerHTML += '<div class="row form-row form-group form-group-sm">';
								innerHTML += '<label class="col-4 col-form-label text-left">'+displayName+'</label>';
								innerHTML += '<div class="col-8 text-left"><input type="text" id="srh'+colName+'" name="srh'+colName+'" class="form-control form-control-sm"  value="<%=_recordBean.getSrhValue()%>"></div>';
							innerHTML += '</div>';
						innerHTML += '</div>';
						break;
				}
			}
			innerHTML += '</div>';
		innerHTML += '</div>';
	innerHTML += '</div>';

	innerHTML += '<div class="row my-4 text-center text-md-left">';
		innerHTML += '<div class="col-12 col-md-4 mb-2 mb-md-0 text-md-left"></div>';
		innerHTML += '<div class="col-12 col-md-4 mb-2 mb-md-0 text-md-center">';
			innerHTML += '<button class="my-search-btn" onClick=Javascript:searchPageDataForm(\"<%=SubmitType.SEARCH%>\",\"<%=_recordBean.getController()%>\",\"\",\"\",\"&searchFilter=yes\");>Search</button>&nbsp;&nbsp;';

			innerHTML += '<button class="my-excel-btn" onClick="Javascript:searchPageDataForm(\'<%=SubmitType.PRINT%>\',\'<%=_recordBean.getController()%>\',\'xls\');">Excel</button>';
		innerHTML += '</div>';
		innerHTML += '<div class="col-12 col-md-4 mb-2 mb-md-0 text-md-right"></div>';
	innerHTML += '</div>';

	innerHTML += '<input type="hidden" id="srhReportType" name="srhReportType" value="'+reportName+'">';

	document.getElementById("reportFiltersDivID").innerHTML = innerHTML;
	if(reportName == "DA Daily Summary") {
		initSelect2Suggestor("transporterEmployees", "srhEMPLOYEE", "", false, "");
	} else if(reportName == "SMS Tx Summary") {
		initSelect2Suggestor("employees", "srhEMPLOYEE", "", false, "");
	}
	reloadDatePicker();
}

function loadTransDataList(recordID, controller) {
	updateIDInnerHTML("alert_sectionID", "");
	var appQry = "&recordID="+recordID;
	var xmlHttpRequest = setSynXMLHttpOb("../servlet/MVPGServlet");
	var str = "submitType=10&controller="+controller+"&requestType=getTransList"+appQry+getEntityParams();
	xmlHttpRequest.send(str);
	var xmlMessage = xmlHttpRequest.responseXML;
	var numOfRows = <%=_vehicleInspection.getTransArray().length%>;

	var htmlContent = '<form id="divFormName" name="divFormName" method="post" action="Javascript:#"><div class="col-12 m-0 p-0 pb-3">';
		htmlContent += '<div class="row form-row">';
			htmlContent += "<div class='col-12'><div class='card'>";
				htmlContent += "<div class='card-header table-title-header m-0 py-2'>Details</div>";
				htmlContent += "<div class='card-body m-1 p-1'>";
					htmlContent += '<table width="100%" border="0" cellpadding="0" cellspacing="0" class="table table-bordered table-striped table-hover table-sm table-block table-vertical sortable mb-0">';
						htmlContent += '<tbody class="tbody-block">';
						htmlContent += '<input type="hidden" id="recordID" name="recordID" value="'+recordID+'">';
						htmlContent += '<input type="hidden" id="numOfRows" name="numOfRows" value="'+numOfRows+'">';
						htmlContent += '<input type="hidden" id="controller" name="controller" value="'+controller+'">';
						<%for(int i=0; i<_vehicleInspection.getTransArray().length; i++) {
							String displayName = _vehicleInspection.getTransArray()[i][0];
							String splitArray[] = _vehicleInspection.getTransArray()[i][1].split("#");%>
							htmlContent += '<tr class="tr-block">';
								htmlContent += '<input type="hidden" id="partName<%=i%>" name="partName<%=i%>" value="<%=displayName%>">';
								htmlContent += '<td class="td-block table-value" data-th="" width="20%"><%=displayName%></td>';
								htmlContent += '<td class="td-block table-value" data-th="" width="25%">';
								<%for(int j=0; j<splitArray.length; j++) {%>
									htmlContent += '<div class="form-check-inline">';
										htmlContent += '<label class="form-check-label"><input type="radio" class="form-check-input" id="partValue<%=i%>" name="partValue<%=i%>" value="<%=j%>" <%if(j == 0) {%>checked<%}%>><%=splitArray[j]%></label>';
									htmlContent += '</div>';
								<%}%>
								htmlContent += '</td>';
								htmlContent += '<td class="td-block table-value" data-th="Comments" width="55%"><textarea id="partComments<%=i%>" name="partComments<%=i%>" class="form-control form-control-sm" rows="1"></textarea></td>';
							htmlContent += '</tr>';
						<%}%>
						htmlContent += '</tbody>';
					htmlContent += '</table>';
				htmlContent += "</div>";
			htmlContent += "</div></div>";
		htmlContent += '</div>';

		htmlContent += '<div class="row form-row my-3">';
			htmlContent += '<div class="row col-12">';
				htmlContent += '<div class="col-4 text-right"></div>';

				htmlContent += '<div class="col-4 text-center"><button class="my-save-btn" onClick="Javascript:updateTransDataList();">Save</button></div>';

				htmlContent += '<div class="col-4 text-right"><button class="my-close-btn" onClick="Javascript:TINY.box.hide();">Close</button></div>';
			htmlContent += '</div>';
		htmlContent += '</div>';

		htmlContent += '<div class="row form-row my-3"><div class="col-12">&nbsp;</div></div>';
	htmlContent += '</div></form>';

	TINY.box.show({
		html:htmlContent,
		fixed:false,
		maskid:'frameless',
		width:900,
		maskopacity:40,
		openjs:function() {
		if(xmlMessage.getElementsByTagName("getTransListDetails")[0] != null && xmlMessage.getElementsByTagName("getTransListDetails")[0].childNodes.length > 0) {
			var getTransListDetails = xmlMessage.getElementsByTagName("getTransListDetails")[0];
			var len = getTransListDetails.childNodes.length;
			for(var i=0; i<len; i++) {
				var transXML = getTransListDetails.getElementsByTagName("getTransListTrans")[i];
				var transID = getXMLValue(transXML.getElementsByTagName("transID")[0]);
				var partName = getXMLValue(transXML.getElementsByTagName("partName")[0]);
				var partValue = getXMLValue(transXML.getElementsByTagName("partValue")[0]);
				var partComments = getXMLValue(transXML.getElementsByTagName("partComments")[0]);
				for(var j=0; j<numOfRows; j++) {
					if(document.getElementById("partName"+j) && document.getElementById("partName"+j).value == partName) {
						setRadioButtonValue(document.divFormName["partValue"+j], partValue);
						document.getElementById("partComments"+j).value = partComments;
						break;
					}
				}
			}
		}
		}
	});
}

function updateTransDataList() {
	var recordID = document.divFormName["recordID"].value;
	var numOfRows = document.divFormName["numOfRows"].value;
	var controller = document.divFormName["controller"].value;
	var appQry = "&recordID="+recordID+"&numOfRows="+numOfRows;
	for(var j=0; j<numOfRows; j++) {
		if(document.getElementById("partName"+j)) {
			var partName = replaceSpecialChars(document.divFormName["partName"+j].value);
			var partValue = replaceSpecialChars(getRadioButtonValue(document.divFormName["partValue"+j]));
			var partComments = replaceSpecialChars(document.divFormName["partComments"+j].value);
			appQry += "&partName"+j+"="+partName+"&partValue"+j+"="+partValue+"&partComments"+j+"="+partComments;
		}
	}
	var xmlHttpRequest = setSynXMLHttpOb("../servlet/MVPGServlet");
	var str = "submitType=10&controller="+controller+"&requestType=updateTransList"+appQry+getEntityParams();
	xmlHttpRequest.send(str);
	var xmlMessage = xmlHttpRequest.responseXML;
	var mesgType = getXMLValue(xmlMessage.getElementsByTagName("mesgType")[0]);
	var mesg = getXMLValue(xmlMessage.getElementsByTagName("mesg")[0]);
	updateIDInnerHTML("alert_sectionID", "<div class='alert-box "+mesgType+"Color'>"+mesg+"</div>");
	if(mesgType == "success") { TINY.box.hide();
	} else { alert(mesg); }
}

function refreshParentWindow() {
	submitPageDataForm('<%=SubmitType.SEARCH%>','<%=_recordBean.getController()%>','','','&searchFilter=yes');
}

function updateInspectionRecords() {
	document.formmain.action = "../servlet/MVPGServlet?submitType=<%=SubmitType.SEARCH%>&controller=<%=_recordBean.getController()%>&searchFilter=yes&selectedType=<%=SubmitType.UPDATE_CONFIRM%>&srhType=updateOld";
	document.formmain.submit();
}
</script>

<%@ include file="includeHeader.jsp"%>
<%if("4".equalsIgnoreCase(request.getAttribute("loginUserRoles")+"")) {
	isNewReq = false;
	//isBrowseReq = false;
}%>
<div class='row my-2'>
	<div class='col-12 mb-2'>
		<div class='card'>
			<div class='card-header table-title-header m-0 py-2'>
				<div class="row">
					<div class="col-2"></div>
					<div class="col-8"><%=_recordBean.getDisplayName()%></div>
					<div class="col-2 text-right my-auto">
					<%if(submitType == SubmitType.SEARCH) {
						if(isNewReq && "VehicleInspection".equalsIgnoreCase(_recordBean.getController()) && "superadmin".equalsIgnoreCase(loginUser)) {%><button class="my-common-btn" onClick="Javascript:updateInspectionRecords();" title="Update">Update</button>&nbsp;<button class="my-new-btn" onClick="Javascript:submitPageDataForm('<%=SubmitType.CREATE%>','<%=_recordBean.getController()%>');" title="Create New">New</button>

						<%} else if(isNewReq) {%><button class="my-new-btn" onClick="Javascript:submitPageDataForm('<%=SubmitType.CREATE%>','<%=_recordBean.getController()%>');" title="Create New">New</button>

						<%} else if(isFileUploadReq) {%><button class="my-upload-btn" onClick="Javascript:submitPageDataForm('<%=SubmitType.UPLOAD%>','<%=_recordBean.getController()%>');" title="File Upload">Upload</button><%}
					}%>
					</div>
				</div>
			</div>

			<%if(_errorBean != null && _errorBean.getType().length() > 0) {%>
				<div class="row text-center"><section class='alert_section'><div class='alert-box <%=_errorBean.getType()%>Color'><%=_errorBean.getMesg()%></div></section></div>
				<%if("yes".equalsIgnoreCase(isPopup)) {%>
					<script>
						opener.refreshParentWindow();
						window.close();
					</script>
				<%}%>
			<%} else if(_recordBean.getErrorBean() != null && _recordBean.getErrorBean().getType().length() > 0) {%>
				<div class="row text-center"><section class='alert_section'><div class='alert-box <%=_recordBean.getErrorBean().getType()%>Color'><%=_recordBean.getErrorBean().getMesg()%></div></section></div>
			<%}%>

			<div class='card-body m-1 p-1'>
			<%if(submitType == SubmitType.SEARCH) {
				if(isSearchFilter) {%>
					<div class="row my-2 mx-1">
						<div class="rounded-top text-white pb-1 px-2 mx-1 search-filter-heading"></div>
						<div class="col-12 rounded m-0 p-2 border border-dark">
							<div class="row form-row">
								<div class="col-12 col-md-11 col-lg-11">
									<div class="form-grid">
									<%if(_recordBean.getSearchFiltersArray().length > 0) {
										GregorianCalendar calObj = new GregorianCalendar();
										int currentYear = calObj.get(Calendar.YEAR);
										for(int i=0; i<_recordBean.getSearchFiltersArray().length; i++) {
											switch(_recordBean.getSearchFiltersArray()[i]) {
												case "Year":%>
													<div class="form-group">
														<label for="srhYear"><%=_recordBean.getSearchFiltersArray()[i]%></label>
														<select id="srhYear" name="srhYear"><%for(int ij=currentYear; ij > 1999; ij--) {%><option value="<%=ij%>"><%=ij%></option><%}%></select>
													</div>
													<script>
														setSelectBoxValue(document.formmain["srhYear"], "<%=_recordBean.getSrhYear()%>");
														initSelect2SuggestorConvert("srhYear", "", false);
													</script>
													<%break;

												case "Week":%>
													<div class="form-group">
														<label for="srhWeek"><%=_recordBean.getSearchFiltersArray()[i]%></label>
														<select id="srhWeek" name="srhWeek"><option value=""></option><%for(int ij=1; ij<53; ij++) {%><option value="<%=ij%>"><%=ij%></option><%}%></select>
													</div>
													<script>
														setSelectBoxValue(document.formmain["srhWeek"], "<%=_recordBean.getSrhWeek()%>");
														initSelect2SuggestorConvert("srhWeek", "", false);
													</script>
													<%break;

												case "User Name":
												case "Card ID":
												case "Phone Number":
												case "Vehicle Number":%>
													<div class="form-group">
														<label for="srhValue"><%=_recordBean.getSearchFiltersArray()[i]%></label>
														<input type="text" id="srhValue" name="srhValue" class="form-control form-control-sm" value="<%=_recordBean.getSrhValue()%>">
													</div>
													<%break;

												case "Name":%>
													<div class="form-group">
														<label for="srhValue"><%=_recordBean.getSearchFiltersArray()[i]%></label>
														<input type="text" id="srhValue" name="srhValue" class="form-control form-control-sm" value="<%=_recordBean.getSrhValue()%>">
													</div>
													<%break;

												case "Transporter ID":%>
													<div class="form-group">
														<label for="srhTransporterID"><%=_recordBean.getSearchFiltersArray()[i]%></label>
														<input type="text" id="srhTransporterID" name="srhTransporterID" class="form-control form-control-sm" value="<%=_recordBean.getSrhTransporterID()%>">
													</div>
													<%break;

												case "Serial Number":
												case "Mobile":%>
													<div class="form-group">
														<label for="srhValue2"><%=_recordBean.getSearchFiltersArray()[i]%></label>
														<input type="text" id="srhValue2" name="srhValue2" class="form-control form-control-sm" value="<%=_recordBean.getSrhValue2()%>">
													</div>
													<%break;

												case "Card Status":
												case "Phone Status":%>
													<div class="form-group">
														<label for="srhStatus"><%=_recordBean.getSearchFiltersArray()[i]%></label>
														<select id="srhStatus" name="srhStatus" class="form-contol form-control-sm">
															<option value="0,4">All</option>
															<%_array = _mainUtil.getDataArray(_mainUtil.getRecordStatus("0,4"));for(int k=0; k<_array.length; k++) {%><option value="<%=_array[k][0]%>"><%=_array[k][1]%></option><%}%>
														</select>
													</div>
													<script>setSelectBoxValue(document.formmain["srhStatus"], "<%=_recordBean.getSrhStatus()%>");</script>
													<%break;

												case "Service Tier":%>
													<div class="form-group">
														<label for="srhValue2"><%=_recordBean.getSearchFiltersArray()[i]%></label>
														<select id="srhValue2" name="srhValue2" class="form-control form-control-sm"><option value=""></option><%_array = _mainUtil.getDataArray(_mainUtil.getServiceTier());for(int k=0; k<_array.length; k++) {%><option value="<%=_array[k][0]%>"><%=_array[k][1]%></option><%}%></select>
													</div>
													<script>
														initSelect2SuggestorConvert("srhValue2", "", true);
														setSelectBoxValue(document.formmain["srhValue2"], "<%=_recordBean.getSrhValue2()%>");
													</script>
													<%break;

												case "Status":%>
													<div class="form-group">
														<label for="srhStatus"><%=_recordBean.getSearchFiltersArray()[i]%></label>
														<select id="srhStatus" name="srhStatus" class="form-control form-control-sm">
															<%if("AdminEmployee".equalsIgnoreCase(_recordBean.getController())) {%>
																<option value="0,4,8,9">All</option>
																<%_array = _mainUtil.getDataArray(_mainUtil.getRecordStatus("0,4,8,9"));for(int k=0; k<_array.length; k++) {%><option value="<%=_array[k][0]%>"><%=_array[k][1]%></option><%}%>

															<%} else if("EmployeeTermination".equalsIgnoreCase(_recordBean.getController())
															|| "EmployeeIncident".equalsIgnoreCase(_recordBean.getController())
															|| "VehicleInspection".equalsIgnoreCase(_recordBean.getController())
															|| "EmployeeCoachingFollowup".equalsIgnoreCase(_recordBean.getController())) {%>
																<option value="0,2">All</option>
																<%_array = _mainUtil.getDataArray(_mainUtil.getRecordStatus("0,2"));for(int k=0; k<_array.length; k++) {%><option value="<%=_array[k][0]%>"><%=_array[k][1]%></option><%}%>

															<%} else if("DAStatus".equalsIgnoreCase(_recordBean.getController())) {%>
																<option value="All">All</option>
																<option value="Not Confirmed,Available">Not Confirmed, Available</option>
																<%_array = _mainUtil.getDataArray(_mainUtil.getDAStatus());for(int k=0; k<_array.length; k++) {%><option value="<%=_array[k][0]%>"><%=_array[k][1]%></option><%}%>

															<%} else if("AdminConfiguration".equalsIgnoreCase(_recordBean.getController())) {%>
																<option value="0" selected>Active</option>
																<option value="4">Inactive</option>

															<%} else if("DACheckin".equalsIgnoreCase(_recordBean.getController())) {%>
																<option value="0,2" selected>Active, Posted</option>
																<option value="0,2,3">All</option>
																<%_array = _mainUtil.getDataArray(_mainUtil.getRecordStatus("0,2,3"));for(int k=0; k<_array.length; k++) {%><option value="<%=_array[k][0]%>"><%=_array[k][1]%></option><%}%>

															<%} else if("EmployeeForms".equalsIgnoreCase(_recordBean.getController())) {%>
																<option value="0,2" selected>All</option>
																<%_array = _mainUtil.getDataArray(_mainUtil.getRecordStatus("0,2"));for(int k=0; k<_array.length; k++) {%><option value="<%=_array[k][0]%>"><%=_array[k][1]%></option><%}%>

															<%} else if("EmployeeRequest".equalsIgnoreCase(_recordBean.getController())) {%>							<option value="0,10,11" selected>All</option>
																<%_array = _mainUtil.getDataArray(_mainUtil.getRecordStatus("0,10,11"));for(int k=0; k<_array.length; k++) {%><option value="<%=_array[k][0]%>"><%=_array[k][1]%></option><%}%>
															<%}%>
														</select>
													</div>
													<script>setSelectBoxValue(document.formmain["srhStatus"], "<%=_recordBean.getSrhStatus()%>");</script>
													<%break;

												case "Opertional Status":%>
													<div class="form-group">
														<label for="srhStatus"><%=_recordBean.getSearchFiltersArray()[i]%></label>
														<select id="srhStatus" name="srhStatus" class="form-control form-control-sm">
															<option value="<%=_mainUtil.getAll(_mainUtil.getOpertionalStatus())%>">All</option>
															<%_array = _mainUtil.getDataArray(_mainUtil.getOpertionalStatus());for(int k=0; k<_array.length; k++) {%><option value="<%=_array[k][0]%>"><%=_array[k][1]%></option><%}%>
														</select>
													</div>
													<script>setSelectBoxValue(document.formmain["srhStatus"], "<%=_recordBean.getSrhStatus()%>");</script>
													<%break;

												case "Role":%>
													<div class="form-group">
														<label for="srhRole"><%=_recordBean.getSearchFiltersArray()[i]%></label>
														<select id="srhRole" name="srhRole" class="form-control form-control-sm">
															<option value=""></option>
															<option value="1">Dispatcher</option>
															<option value="2">Manager</option>
															<option value="3">Management</option>
															<option value="4">DA Associate</option>
														</select>
													</div>
													<script>setSelectBoxValue(document.formmain["srhRole"], "<%=_recordBean.getSrhRole()%>");</script>
													<%break;

												case "Card Status Date":%>
													<div class="form-group">
														<label for="srhStatusDate"><%=_recordBean.getSearchFiltersArray()[i]%></label>
														<input type="text" id="srhStatusDate" name="srhStatusDate" class="form-control form-control-sm datepicker" value="<%=_recordBean.getSrhStatusDate()%>">
													</div>
													<%break;

												case "Expiry Date":%>
													<div class="form-group">
														<label for="srhExpiryDate"><%=_recordBean.getSearchFiltersArray()[i]%></label>
														<input type="text" id="srhExpiryDate" name="srhExpiryDate" class="form-control form-control-sm datepicker" value="<%=_recordBean.getSrhExpiryDate()%>">
													</div>
													<%break;

												case "Date Range":%>
													<div class="form-group">
														<label for="Date Range"><%=_recordBean.getSearchFiltersArray()[i]%></label>
														<div class="input-group">
															<a class="input-group-text" href="Javascript:showDayFilter('left')"><i class="fa fa-angle-double-left" aria-hidden="true"></i></a>
															<input type="text" id="srhFromDate" name="srhFromDate" class="form-control form-control-sm datepicker" value="<%=_recordBean.getSrhFromDate()%>">
															<span class="input-group-text m-0 p-0"> - </span>
															<input type="text" id="srhToDate" name="srhToDate" class="form-control form-control-sm datepicker" value="<%=_recordBean.getSrhToDate()%>">
															<a class="input-group-text" href="Javascript:showDayFilter('right')"><i class="fa fa-angle-double-right" aria-hidden="true"></i></a>
														</div>
													</div>
													<%break;

												case "Category":%>
													<div class="form-group">
													<%if("AdminIncidentCategory".equalsIgnoreCase(_recordBean.getController())) {%>
														<label for="srhValue"><%=_recordBean.getSearchFiltersArray()[i]%></label>
														<input type="text" id="srhValue" name="srhValue" class="form-control form-control-sm" value="<%=_recordBean.getSrhValue()%>">
													<%} else if("AdminConfiguration".equalsIgnoreCase(_recordBean.getController())) {%>
														<label for="srhValue"><%=_recordBean.getSearchFiltersArray()[i]%></label>
														<select id="srhValue" name="srhValue" class="form-control form-control-sm">
															<option value=""></option>
															<option value="General">General</option>
															<option value="SMS">SMS</option>
															<option value="VEHICLE">Vehicle</option>
														</select>
														<script>setSelectBoxValue(document.formmain["srhValue"], "<%=_recordBean.getSrhValue()%>");</script>
													<%} else {%>
														<label for="srhCategoryID"><%=_recordBean.getSearchFiltersArray()[i]%></label>
														<select id="srhCategoryID" name="srhCategoryID" class="form-control form-control-sm"></select>
														<script>initSelect2Suggestor("incidentCategories", "srhCategoryID", "<%=_recordBean.getSrhCategoryID()%>", false, "");</script>
													<%}%>
													</div>
													<%break;

												case "Type":%>
													<div class="form-group">
														<%if("AdminIncidentType".equalsIgnoreCase(_recordBean.getController())) {%>
															<label for="srhValue"><%=_recordBean.getSearchFiltersArray()[i]%></label>
															<input type="text" id="srhValue" name="srhValue" class="form-control form-control-sm" value="<%=_recordBean.getSrhValue()%>">

														<%} else if("EmployeeRequest".equalsIgnoreCase(_recordBean.getController())) {%>
															<label for="srhType"><%=_recordBean.getSearchFiltersArray()[i]%></label>
															<select id="srhType" name="srhType" class="form-control form-control-sm"><option value="">All</option><option value="Time Off">Time Off</option><option value="Extra Days">Extra Days</option></select>
															<script>setSelectBoxValue(document.formmain["srhType"], "<%=_recordBean.getSrhType()%>");</script>

														<%} else {%>
															<label for="srhTypeID"><%=_recordBean.getSearchFiltersArray()[i]%></label>
															<select id="srhTypeID" name="srhTypeID" class="form-control form-control-sm"></select>
															<script>initSelect2Suggestor("incidentTypes", "srhTypeID", "<%=_recordBean.getSrhTypeID()%>", false, "");</script>
														<%}%>
													</div>
													<%break;

												case "Template":%>
													<div class="form-group">
														<label for="srhTypeID"><%=_recordBean.getSearchFiltersArray()[i]%></label>
														<select id="srhTypeID" name="srhTypeID"></select>
													</div>
													<script>initSelect2Suggestor("formsTemplate", "srhTypeID", "<%=_recordBean.getSrhTypeID()%>", false, "");</script>
													<%break;


												case "Coaching Owner":%>
													<div class="form-group">
														<label for="srhEmployeeID"><%=_recordBean.getSearchFiltersArray()[i]%></label>
														<select id="srhEmployeeID" name="srhEmployeeID"></select>
													</div>
													<script>
													initSelect2Suggestor("coachingOwner", "srhEmployeeID", "<%=_recordBean.getSrhEmployeeID()%>", false, "");
													</script>
													<%break;

												case "Employee":%>
													<div class="form-group">
														<label for="srhEmployeeID"><%=_recordBean.getSearchFiltersArray()[i]%></label>
														<select id="srhEmployeeID" name="srhEmployeeID"></select>
													</div>
													<script>
													initSelect2Suggestor("employees", "srhEmployeeID", "<%=_recordBean.getSrhEmployeeID()%>", false, "");
													</script>
													<%break;

												case "Vehicle":%>
													<div class="form-group">
														<label for="srhEmployeeID"><%=_recordBean.getSearchFiltersArray()[i]%></label>
														<select id="srhVehicleID" name="srhVehicleID" class="form-control form-control-sm"></select>
													</div>
													<script>initSelect2Suggestor("vehicles", "srhVehicleID", "<%=_recordBean.getSrhVehicleID()%>", false, "");</script>
													<%break;
											}
										}
									}%>
									</div>
								</div>

								<div class="col-12 col-md-1 col-lg-1 my-auto text-center">
									<div class="row">
										<div class="col-12">
										<%if("Reports".equalsIgnoreCase(_recordBean.getController())) {%>
										<button class="my-print-btn" onClick="Javascript:searchPageDataForm('<%=SubmitType.PRINT%>','<%=_recordBean.getController()%>');">Print</button>
										<%} else {%>
										<button id="searchFilterBtnID" class="my-search-btn" onClick="javascript:submitPageDataForm('<%=SubmitType.SEARCH%>','<%=_recordBean.getController()%>','','','&searchFilter=yes')">Search</button>
										<%}%>
										</div>
									</div>
								</div>
							</div>
						</div>
					</div>

				<%} if("DACheckin".equalsIgnoreCase(_recordBean.getController())) {%>
					<%if(_recordBean.getSelectedType().equalsIgnoreCase(SubmitType.UPDATE+"")) {
						isBrowseReq = false;
						employeesTxt = _recordBean.getXmlMesg().substring(_recordBean.getXmlMesg().indexOf("<employeesTxt>")+(employeesTxt.length()+2), _recordBean.getXmlMesg().indexOf("</employeesTxt>")).replaceAll("\"", "'");

						vehiclesTxt = _recordBean.getXmlMesg().substring(_recordBean.getXmlMesg().indexOf("<vehiclesTxt>")+(vehiclesTxt.length()+2), _recordBean.getXmlMesg().indexOf("</vehiclesTxt>")).replaceAll("\"", "'");

						gasCardsTxt = _recordBean.getXmlMesg().substring(_recordBean.getXmlMesg().indexOf("<gasCardsTxt>")+(gasCardsTxt.length()+2), _recordBean.getXmlMesg().indexOf("</gasCardsTxt>")).replaceAll("\"", "'"); 
						String tempData = vehiclesTxt.replaceAll("<option value=''></option>", "");
						String vehicleDataArray[] = tempData.split("</option>");
						
						List<String> assignedList = new ArrayList<String>();
						for(int i=0; i < _recordBean.getDataList().size(); i++) {
							List rowList = (ArrayList) _recordBean.getDataList().get(i);
							String vehID = rowList.get(3) == null ? "" : rowList.get(3).toString().trim();
							assignedList.add(vehID);
						}
						%>

						<script>
						var vehicleDataArray = new Array();
						var dupVehicleDataArray = new Array();
						var isPageLoadDone = false;
						function selectVehicleData(thisObj) {
							for (var i = 0; i < vehicleDataArray.length; i++) {
								var selectedVal = vehicleDataArray[i][0];
								if(document.getElementById("vehicle"+selectedVal+"DivID")) 
									document.getElementById("vehicle"+selectedVal+"DivID").className = "col-1 py-1 text-success text-left border border-dark";
							}

							var duplicateArray = new Array();
							var numOfRecords = <%=_recordBean.getDataList().size()%>;
							var isDupAlertReq = true;
							for (var i = 0; i < numOfRecords; i++) {
								var selectedVal = getSelectBoxValue(document.formmain["vehicleID"+i]);
								if($("#vehicleID"+i).hasClass("border border-danger")) {
									$("#vehicleID"+i).removeClass("border border-danger");
								}
								if(document.getElementById("vehicle"+selectedVal+"DivID")) {
									if(!duplicateArray.includes(selectedVal)) {
										document.getElementById("vehicle"+selectedVal+"DivID").className = "col-1 py-1 text-danger text-left border border-dark";
										duplicateArray.push(selectedVal);
									} else {
										if(!$("#vehicleID"+i).hasClass("border border-danger")) {
											$("#vehicleID"+i).addClass("border border-danger");
										}
										var selectedValText = getSelectBoxText(document.formmain["vehicleID"+i]);
										if(!dupVehicleDataArray.includes(selectedValText)) {
											dupVehicleDataArray.push(selectedValText);
										}
										if(isPageLoadDone) {
											if(isDupAlertReq && thisObj != null && thisObj.name == "vehicleID"+i) {
												alert("Vehicle already selected, Please check it");
												document.formmain["vehicleID"+i].value = "";
												isDupAlertReq = false;
											}
										}
									}
								}
							}
						}
						</script>
						<HR>
						<div class="row my-2 mx-1">
							<div class="col-12">
								<div class="row">
									<div class="col-12 text-center"><h5>Assigned Vehicles</h5></div>
								</div>
								<div class="row">
								<%
								for(int i=0; i<vehicleDataArray.length; i++) {
									vehicleDataArray[i]= vehicleDataArray[i].trim();
									if(vehicleDataArray[i].length() > 0) {
										String optionVal = vehicleDataArray[i].substring(15, vehicleDataArray[i].indexOf("' title='"));
										String optionText = vehicleDataArray[i].substring(vehicleDataArray[i].indexOf("'>")+2);
										if(assignedList.contains(optionVal)) {%>
											<div class="col-1 py-1 text-success text-left border border-dark" id="vehicle<%=optionVal%>DivID" title="<%=optionText%>"><%=optionText%></div>
											<script>vehicleDataArray[vehicleDataArray.length] = new Array("<%=optionVal%>","<%=optionText%>");</script>
										<%}
									}
								}%>
								</div>

								<div class="row">
									<div class="col-12 text-center pt-3"><h5>Unassigned Vehicles</h5></div>
								</div>
								<div class="row">
								<%for(int i=0; i<vehicleDataArray.length; i++) {
									vehicleDataArray[i]= vehicleDataArray[i].trim();
									if(vehicleDataArray[i].length() > 0) {
										String optionVal = vehicleDataArray[i].substring(15, vehicleDataArray[i].indexOf("' title='"));
										String optionText = vehicleDataArray[i].substring(vehicleDataArray[i].indexOf("'>")+2);
										if(!assignedList.contains(optionVal)) {%>
											<div class="col-1 py-1 text-success text-left border border-dark" id="vehicle<%=optionVal%>DivID" title="<%=optionText%>"><%=optionText%></div>
											<script>vehicleDataArray[vehicleDataArray.length] = new Array("<%=optionVal%>","<%=optionText%>");</script>
										<%}
									}
								}%>
								</div>
								<div class="row pb-2"></div>
							</div>
						</div>
					<%}
				}
				if(_recordBean.getDataCountList().size() > 0) {%>
					<div class="row my-2 mx-1 py-3 rounded border border-info">
					<%for(int i=0; i<_recordBean.getDataCountList().size(); i++) {
						List tempList = (ArrayList) _recordBean.getDataCountList().get(i);
						String label = tempList.get(0) == null ? "" : tempList.get(0).toString().trim();
						String labelCNT = tempList.get(1) == null ? "" : tempList.get(1).toString().trim();
						if(label.length() == 0 && labelCNT.length() == 0) {%>
							<div class="col-12 my-3 rounded border border-info"></div><%
							continue;
						}%>
						<div class="col-12 col-md-4"><%=label+"  : "+labelCNT%></div>
					<%}%>
					</div>
				<%} if(emojiList.size() > 0) {%>
					<div class="row my-2 mx-1 py-3 rounded border border-info">
					<%for(int i=0; i<emojiList.size(); i++) {
						List tempList1 = (ArrayList) emojiList.get(i);
						String data1 = tempList1.get(0) == null ? "" : tempList1.get(0).toString().trim();
						String data2 = tempList1.get(1) == null ? "" : tempList1.get(1).toString().trim();%>
						<div class="col-12 col-md-6"><%=data1%></div>
						<div class="col-12 col-md-6"><%=data2%></div>
					<%}%>
					</div>
				<%}%>


				<div class="row text-center"><section class='alert_section' id="alert_sectionID"></section></div>

				<!-- Top buttons section starts -->
				<div class="row my-4 text-center text-md-left">
				<%if("EmployeeSchedule".equalsIgnoreCase(_recordBean.getController()) || 
					"DACheckout".equalsIgnoreCase(_recordBean.getController()) || 
					"EmployeeTermination".equalsIgnoreCase(_recordBean.getController()) || 
					"EmployeeIncident".equalsIgnoreCase(_recordBean.getController()) || 
					"EmployeeRequest".equalsIgnoreCase(_recordBean.getController()) || 
					"DAStatus".equalsIgnoreCase(_recordBean.getController()) || 
					"VehicleInspection".equalsIgnoreCase(_recordBean.getController())) {%>
					<div class="col-12 col-md-4 mb-2 mb-md-0 text-md-left">
						<%if("EmployeeSchedule".equalsIgnoreCase(_recordBean.getController()) || 
						"EmployeeRequest".equalsIgnoreCase(_recordBean.getController()) || 
						"DAStatus".equalsIgnoreCase(_recordBean.getController()) || 
						"VehicleInspection".equalsIgnoreCase(_recordBean.getController())) {
							if(!_recordBean.getSelectedType().equalsIgnoreCase(SubmitType.UPDATE+"")) {
								if("EmployeeSchedule".equalsIgnoreCase(_recordBean.getController())) {%>
								<button class="btn btn-secondary mb-1" onClick="Javascript:searchPageDataForm('<%=SubmitType.UPDATE%>','<%=_recordBean.getController()%>', 'Repeat');" TITLE="Repeat schedule for 1 week">Repeat</button><%}%>

								<%if(_recordBean.getDataList().size() > 0) {%><button class="btn btn-secondary mb-1" onClick="Javascript:searchPageDataForm('<%=SubmitType.UPDATE%>','<%=_recordBean.getController()%>', 'Update');" TITLE="Update">Update</button><%}%>
							<%}
						}%>
					</div>
					<div class="col-12 col-md-4 mb-2 mb-md-0 text-md-center">
						<%if(_recordBean.getSelectedType().equalsIgnoreCase(SubmitType.UPDATE+"")) {
							if(_recordBean.getDataList().size() > 0) {%><button class="btn btn-success mb-1" onClick="Javascript:searchPageDataForm1('<%=SubmitType.UPDATE_CONFIRM%>','<%=_recordBean.getController()%>');">Save</button><%}

						} else {
							if(_recordBean.isDisplaySMSBtn()) {%><button id="smsBtnTopID" class="btn btn-secondary mb-1" onClick="Javascript:searchPageDataForm('<%=SubmitType.DYNAMIC%>','<%=_recordBean.getController()%>','',this);">SMS</button><%}

							if(_recordBean.isDisplayPostBtn()) {%><button id="postCheckoutBtnTopID" class="btn btn-success mb-1" onClick="Javascript:searchPageDataForm('<%=SubmitType.FINAL%>','<%=_recordBean.getController()%>','DACheckout');">DA Checkout</button>&nbsp;&nbsp;<%}

							if(_recordBean.isDisplayPostBtn()) {%><button id="postBtnTopID" class="btn btn-success mb-1" onClick="Javascript:searchPageDataForm('<%=SubmitType.FINAL%>','<%=_recordBean.getController()%>','',this);">Post</button><%}%>
						<%}%>
					</div>
					<div class="col-12 col-md-4 text-md-right">
						<%if(_recordBean.getDataList().size() > 0 && "DAStatus".equalsIgnoreCase(_recordBean.getController())) {%>
							<button id="deleteBtnTopID" class="btn btn-danger mb-1" onClick="Javascript:searchPageDataForm('<%=SubmitType.DELETE%>','<%=_recordBean.getController()%>');">Delete</button>
						<%}%>
					</div>

				<%} else if("AdminEmployee".equalsIgnoreCase(_recordBean.getController())) {%>
					<%if(_recordBean.getSelectedType().equalsIgnoreCase(SubmitType.UPDATE+"")) {%>
						<div class="col-12 col-md-4 mb-2 mb-md-0 text-md-left"></div>
						<div class="col-12 col-md-4 mb-2 mb-md-0 text-md-center">
							<button class="btn btn-success mb-1" onClick="Javascript:searchPageDataForm1('<%=SubmitType.UPDATE_CONFIRM%>','<%=_recordBean.getController()%>');">Save</button>
						</div>
						<div class="col-12 col-md-4 text-md-right"></div>
					<%} else {%>
						<div class="col-12 col-md-4 mb-2 mb-md-0 text-md-left">
							<button class="btn btn-secondary mb-1" onClick="Javascript:searchPageDataForm('<%=SubmitType.UPDATE%>','<%=_recordBean.getController()%>');" TITLE="Update">Update</button>
						</div>
						<div class="col-12 col-md-4 mb-2 mb-md-0 text-md-center">
							<%if(_recordBean.getDataList().size() > 0) {%><button class="btn btn-secondary mb-1" onClick="Javascript:searchPageDataForm('<%=SubmitType.PRINT%>','<%=_recordBean.getController()%>');">Print</button><%}%>
						</div>
						<div class="col-12 col-md-4 text-md-right"></div>
					<%}%>

				<%} else if("DACheckin".equalsIgnoreCase(_recordBean.getController())) {%>
					<%if(_recordBean.getSelectedType().equalsIgnoreCase(SubmitType.UPDATE+"")) {%>
						<div class="col-12 col-md-4 mb-2 mb-md-0 text-md-left"></div>
						<div class="col-12 col-md-4 mb-2 mb-md-0 text-md-center">
							<button class="btn btn-success mb-1" onClick="Javascript:searchPageDataForm1('<%=SubmitType.UPDATE_CONFIRM%>','<%=_recordBean.getController()%>');">Save</button>
						</div>
						<div class="col-12 col-md-4 text-md-right"></div>
					<%} else {%>
						<div class="col-12 col-md-4 mb-2 mb-md-0 text-md-left">
							<%if("DACheckin".equalsIgnoreCase(_recordBean.getController())) {%>
							<button id="swapBtnTopID" class="btn btn-secondary mb-1" onClick="Javascript:searchPageDataForm('<%=SubmitType.UPDATE%>','<%=_recordBean.getController()%>');">Swap</button>

							<!--button class="btn btn-secondary mb-1" onClick="Javascript:searchPageDataForm('<%=SubmitType.UPDATE%>','<%=_recordBean.getController()%>', 'Run');">Run</button>

							<button class="btn btn-secondary mb-1" onClick="Javascript:searchPageDataForm('<%=SubmitType.UPDATE%>','<%=_recordBean.getController()%>', 'Next Day Run');" TITLE="Next Day Run">Run <i class="fa fa-angle-double-right" aria-hidden="true"></i></button -->
							<%}%>
						</div>
						<div class="col-12 col-md-4 mb-2 mb-md-0 text-md-center">
							<%if(_recordBean.isDisplayPostBtn()) {%><button id="postBtnTopID" class="btn btn-success mb-1" onClick="Javascript:searchPageDataForm('<%=SubmitType.FINAL%>','<%=_recordBean.getController()%>','',this);">Post</button><%}%>

							<%if(_recordBean.isDisplaySMSBtn()) {%><button id="smsBtnTopID" class="btn btn-secondary mb-1" onClick="Javascript:searchPageDataForm('<%=SubmitType.DYNAMIC%>','<%=_recordBean.getController()%>','',this);">SMS</button><%}%>

							<%if(_recordBean.isDisplayPrintBtn()) {%><button class="btn btn-secondary mb-1" onClick="Javascript:searchPageDataForm('<%=SubmitType.PRINT%>','<%=_recordBean.getController()%>');">Print</button><%}%>

							<%if(_recordBean.isDisplayViewBtn()) {%><button class="btn btn-secondary mb-1" onClick="Javascript:searchPageDataForm('<%=SubmitType.PRINT%>','<%=_recordBean.getController()%>', 'view');">View</button><%}%>
						</div>
						<div class="col-12 col-md-4 text-md-right">
							<%if("DACheckin".equalsIgnoreCase(_recordBean.getController())) {%>
							<button class="btn btn-secondary mb-1" onClick="Javascript:searchPageDataForm('<%=SubmitType.UPDATE%>','<%=_recordBean.getController()%>', 'NewRun');">New Run</button>

							<button class="btn btn-secondary mb-1" onClick="Javascript:searchPageDataForm('<%=SubmitType.UPDATE%>','<%=_recordBean.getController()%>', 'NewNext Day Run');" TITLE="Next Day Run">New Run <i class="fa fa-angle-double-right" aria-hidden="true"></i></button>
							<%}%>
							<button id="deleteBtnTopID" class="btn btn-danger mb-1" onClick="Javascript:searchPageDataForm('<%=SubmitType.DELETE%>','<%=_recordBean.getController()%>');">Delete</button>
						</div>
					<%}%>
				<%}%>
				</div>
				<!-- Top buttons section ends -->

				<%if(_recordBean.getDataList().size() > 0) {
					 if("DACheckin".equalsIgnoreCase(_recordBean.getController()) && !isBrowseReq) {
						isActiveRecords = true;
						int i =  0, maxCols = 2;
						int maxRows = (_recordBean.getDataList().size()/2); 
						if((_recordBean.getDataList().size()%2) == 1) { maxRows= maxRows+1;};
						if(_recordBean.getDataList().size() < 2) {
							maxCols = 1;
							maxRows = _recordBean.getDataList().size();
						}%>
						<div class="row">
						<%for(int cols=0; cols< maxCols; cols++) {
							if(cols == 1) { maxRows = _recordBean.getDataList().size();}%>
							<div class="col-12 col-md-6">
							<table width="100%" border="0" cellpadding="0" cellspacing="0" class="table table-bordered table-striped table-hover table-sm table-block table-vertical sortable mb-0">
								<thead class="thead-block">
									<tr class="tr-block">
										<th class="th-block table-header-label text-center" width="50%">Employee</th>
										<th class="th-block table-header-label text-center" width="50%">Vehicle</th>
									</tr>
								</thead>

								<tbody class="tbody-block">
								<% String tempVehType = "";
								int vstCNT = 0;
								for (; i < maxRows; i++) {
									if(i < _recordBean.getDataList().size()) {
										List rowList = (ArrayList) _recordBean.getDataList().get(i);
										String searchID = (String) rowList.get(0);
										String clockinTime = rowList.get(1) == null ? "" : rowList.get(1).toString().trim();
										String empID = rowList.get(2) == null ? "" : rowList.get(2).toString().trim();
										String vehID = rowList.get(3) == null ? "" : rowList.get(3).toString().trim();
										String vehType = rowList.get(4) == null ? "" : rowList.get(4).toString().trim();
										if(!tempVehType.equalsIgnoreCase(vehType)) {
											if(tempVehType.length() > 0) {%>
												<script>document.getElementById("vstCNT<%=cols+"_"+tempVehType.replaceAll(" ","")%>").innerHTML = "<%=vstCNT%>";</script>
											<%vstCNT = 0; }
											tempVehType = vehType;%>
											<tr class="tr-block"><th class="th-block table-header-label text-center" data-th="Service Tier" colSpan="2"><%=vehType%> (<span id="vstCNT<%=cols+"_"+vehType.replaceAll(" ","")%>"></span>)</th></tr>
										<%} vstCNT++; %>
										<input type="hidden" id="recordID<%=i%>" name="recordID<%=i%>" value="<%=searchID%>">
										<input type="hidden" id="clockinTime<%=i%>" name="clockinTime<%=i%>" value="<%=clockinTime%>">
										<tr class="tr-block">
											<td class="td-block table-value" data-th="Employee"><select id="employeeID<%=i%>" name="employeeID<%=i%>" class="form-control form-control-sm"></select></td>
											<td class="td-block table-value" data-th="Vehicle"><select id="vehicleID<%=i%>" name="vehicleID<%=i%>" class="form-control form-control-sm border border-danger" onChange="selectVehicleData(this);"></select></td>
											<script>
												initSelect2SuggestorSetData("employeeID<%=i%>", "<%=employeesTxt%>", "<%=empID%>");
												initSelect2SuggestorSetData("vehicleID<%=i%>", "<%=vehiclesTxt%>", "<%=vehID%>", false);
											</script>
										</tr>
									<%} else {%>
										<tr class="tr-block"><td class="td-block table-value" colSpan="2"></td></tr>
									<%}
								}

								if(tempVehType.length() > 0) {%>
									<script>document.getElementById("vstCNT<%=cols+"_"+tempVehType.replaceAll(" ","")%>").innerHTML = "<%=vstCNT%>";</script>
								<%vstCNT = 0; }
								%>
								</tbody>
							</table>
							</div>
						<%}%>
						</div>

					 <%} else {
						if(_recordBean.getSelectedType().equalsIgnoreCase(SubmitType.UPDATE+"")) {
							isBrowseReq = false;
						}
						if(_recordBean.getSrhReportType().length() > 0) {%>
							<input type="hidden" id="srhReportType" name="srhReportType" value="<%=_recordBean.getSrhReportType()%>">
							<%if(_recordBean.getReportsFilterArray() != null) {
								for(int i=0; i<_recordBean.getReportsFilterArray().length; i++) {
									if("DATE_RANGE".equalsIgnoreCase(_recordBean.getReportsFilterArray()[i])) {%>
										<input type="hidden" id="srhFromDate" name="srhFromDate" value="<%=_recordBean.getSrhFromDate()%>">
										<input type="hidden" id="srhToDate" name="srhToDate" value="<%=_recordBean.getSrhToDate()%>">
									<%} else {
										String filterName = "srh"+_recordBean.getReportsFilterArray()[i];
										String filterNameVal = _recordBean.getRequestMap().get(filterName) == null ? "" : _recordBean.getRequestMap().get(filterName).toString().trim(); %>
										<input type="hidden" id="<%=filterName%>" name="<%=filterName%>" value="<%=filterNameVal%>">
									<%}
								}
							}
						}%>

						<table width="100%" border="0" cellpadding="0" cellspacing="0" class="table table-bordered table-striped table-hover table-sm table-block table-vertical sortable mb-0">
							<thead class="thead-block">
								<tr class="tr-block">
									<input type="hidden" id="prevSortColIndex" name="prevSortColIndex" value="<%=_recordBean.getColumnSortName()%>">
									<%if("DACheckin".equalsIgnoreCase(_recordBean.getController()) || 
									"DACheckout".equalsIgnoreCase(_recordBean.getController()) || 
									"EmployeeTermination".equalsIgnoreCase(_recordBean.getController()) || 
									"EmployeeIncident".equalsIgnoreCase(_recordBean.getController()) || 
									"EmployeeRequest".equalsIgnoreCase(_recordBean.getController()) || 
									"AdminEmployee".equalsIgnoreCase(_recordBean.getController()) || 
									"DAStatus".equalsIgnoreCase(_recordBean.getController()) || 
									"VehicleInspection".equalsIgnoreCase(_recordBean.getController())) {%>
										<th class="th-block table-header-label text-center" width="3%"><input type="checkbox" id="allSelRecordIDs" name="allSelRecordIDs" value="" onClick="checkOrUncheckValues(this,document.formmain.selRecordIDs);"></th>

									<%} for (int i = 0; i < _recordBean.getLabelsList().size(); i++) {
										String colLabel = (String) _recordBean.getLabelsList().get(i); %>
										<th class="th-block table-header-label text-center" width="<%=_recordBean.getWidthColumns() == null ? "" : _recordBean.getWidthColumns()[i]%>%" id="srhColHeader<%=i%>">
										<%if(_recordBean.isDisplayResultsSorting()) {%>
											<a href="Javascript:sortSearchRecords('<%=SubmitType.SEARCH%>','<%=_recordBean.getController()%>','<%=i%>','<%=_recordBean.getColumnSortOrder()%>');"><%=colLabel%></a>
										<%} else {%>
											<%=colLabel%>
										<%}%></th>

									<%} if(isBrowseReq && "VehicleInspection".equalsIgnoreCase(_recordBean.getController()) || "EmployeeForms".equalsIgnoreCase(_recordBean.getController())) {%>
										<th class="th-block table-header-label text-center" width="3%">&nbsp;</th>

									<%} if("AdminConfiguration".equalsIgnoreCase(_recordBean.getController())) {%>
										<th class="th-block table-header-label text-center" width="3%">&nbsp;</th>
									<%}%>
								</tr>
							</thead>

							<tbody class="tbody-block">
							<%for (int i = 0; i < _recordBean.getDataList().size(); i++) {
								List rowList = (ArrayList) _recordBean.getDataList().get(i);
								String searchID = (String) rowList.get(0);
								String rowColor = _recordBean.getRequestMap().get("highlightRowColor_"+i) == null ? "" : _recordBean.getRequestMap().get("highlightRowColor_"+i).toString().trim();%>
								<tr class="tr-block"><%
								if("DACheckin".equalsIgnoreCase(_recordBean.getController()) || 
									"DACheckout".equalsIgnoreCase(_recordBean.getController()) || 
									"EmployeeTermination".equalsIgnoreCase(_recordBean.getController()) || 
									"EmployeeIncident".equalsIgnoreCase(_recordBean.getController()) || 
									"EmployeeRequest".equalsIgnoreCase(_recordBean.getController()) || 
									"AdminEmployee".equalsIgnoreCase(_recordBean.getController()) || 
									"DAStatus".equalsIgnoreCase(_recordBean.getController()) || 
									"VehicleInspection".equalsIgnoreCase(_recordBean.getController())) {
									boolean isPosted = false;
									String searchRecordStatus = rowList.get(rowList.size()-1) == null ? "" : rowList.get(rowList.size()-1).toString().trim();
									if("VehicleInspection".equalsIgnoreCase(_recordBean.getController()))
										searchRecordStatus = rowList.get(rowList.size()-2) == null ? "" : rowList.get(rowList.size()-2).toString().trim();
									if("active".equalsIgnoreCase(searchRecordStatus) || "0".equalsIgnoreCase(searchRecordStatus)) { isActiveRecords = true;
									} else { isPosted = true;
									}%>

									<td class="td-block table-value text-left text-md-center" data-th="Select"><input type="checkbox" id="selRecordIDs" name="selRecordIDs" value="<%=searchID%>"></td>
									<input type="hidden" id="sel<%=searchID%>Status" name="sel<%=searchID%>Status" value="<%=searchRecordStatus%>">
									<input type="hidden" id="recordID<%=i%>" name="recordID<%=i%>" value="<%=searchID%>">

								<%} String colData = "", dataTh = "";
								String daCheckoutID = "", uploadIDs = "";
								String recordStatus1 = "";
								if(rowList.size() > 8 && rowList.get(8) != null)
									recordStatus1 = rowList.get(8).toString().trim();
								for (int j = 1; j < _recordBean.getLabelsList().size()+1; j++) {
									colData = rowList.get(j) == null ? "" : rowList.get(j).toString().trim();
									dataTh = _recordBean.getLabelsList().get(j-1).toString();
									if(isBrowseReq) {%>
										<%if((j+1) > _recordBean.getLabelsList().size() && "VehicleInspection".equalsIgnoreCase(_recordBean.getController())) {
											daCheckoutID = rowList.get(j+1) == null ? "" : rowList.get(j+1).toString().trim();
											uploadIDs = rowList.get(j+2) == null ? "" : rowList.get(j+2).toString().trim();%>
											<input type="hidden" id="daCheckoutID<%=searchID%>" name="daCheckoutID<%=searchID%>" value="<%=daCheckoutID%>">
										<%}%>

										<td class="td-block table-value" data-th="<%=dataTh%>">
											<%if("VehicleInspection".equalsIgnoreCase(_recordBean.getController())) {
												if("Active".equalsIgnoreCase(recordStatus1)) {%><a href="Javascript:submitPageDataForm('<%=SubmitType.UPDATE%>','<%=_recordBean.getController()%>','<%=searchID%>');"><%=colData%></a>
												<%} else {%><a href="Javascript:submitPageDataForm('<%=SubmitType.BROWSE%>','<%=_recordBean.getController()%>','<%=searchID%>');"><%=colData%></a>
												<%}

											} else {%><a href="Javascript:submitPageDataForm('<%=SubmitType.BROWSE%>','<%=_recordBean.getController()%>','<%=searchID%>');"><%=colData%></a>
											<%}%>
										</td>

									<%} else {
										if("EmployeeSchedule".equalsIgnoreCase(_recordBean.getController())) {
											if(j == 1) {%>
												<td class="td-block table-value" data-th="<%=dataTh%>"><%=colData%></td>
											<%} else {
												if(_recordBean.getSelectedType().equalsIgnoreCase(SubmitType.UPDATE+"")) {%>
													<td class="td-block table-value text-center" data-th="<%=dataTh%>"><input type="hidden" id="recordID<%=numOfValues%>" name="recordID<%=numOfValues%>" value="chk_<%=searchID%>_<%=dataTh%>"><input type="checkbox" id="recordIDVal<%=numOfValues%>" name="recordIDVal<%=numOfValues%>" value="1" <%if("Y".equalsIgnoreCase(colData)) {%>checked<%}%>></td>
													<% numOfValues++;
												} else {%>
													<td class="td-block table-value text-center" data-th="<%=dataTh%>"><%=colData%></td>
												<%}
											}

										} else if("AdminConfiguration".equalsIgnoreCase(_recordBean.getController())) {
											if("Value".equalsIgnoreCase(dataTh)) {
												if("0".equalsIgnoreCase(_recordBean.getSrhStatus())) {%>
													<td class="td-block table-value text-left" data-th="<%=dataTh%>"><textarea id="<%=dataTh+i%>" name="<%=dataTh+i%>" rows="1"><%=colData%></textarea></td>
												<%} else {%>
													<input type="hidden" id="<%=dataTh+i%>" name="<%=dataTh+i%>" value="<%=colData%>">
													<td class="td-block table-value text-left" data-th="<%=dataTh%>"><%=colData%></td>
												<%}

											} else if("Status".equalsIgnoreCase(dataTh)) {%>
												<td class="td-block table-value text-left" data-th="<%=dataTh%>">
													<select class="form-control form-control-sm" id="<%=dataTh+i%>" name="<%=dataTh+i%>">
													<%if("0".equalsIgnoreCase(_recordBean.getSrhStatus())) {%>
														<option value="0" selected>Active</option>
														<option value="4">Inactive</option>
													<%} else {%>
														<option value="0">Active</option>
														<option value="4" selected>Inactive</option>
													<%}%>
													</select>
												</td>

												<td class="td-block table-value text-left" data-th=""><a TITLE="Update" href="Javascript:updateConfiguration('<%=i%>','<%=searchID%>','<%=_recordBean.getController()%>');"><i class="fa fa-pencil-square-o fa-lg" aria-hidden="true"></i></a></td>
											<%} else {%>
												<input type="hidden" id="<%=dataTh+i%>" name="<%=dataTh+i%>" value="<%=colData%>">
												<td class="td-block table-value text-left" data-th="<%=dataTh%>"><%=colData%></td>
											<%}

										} else if(_recordBean.getSelectedType().equalsIgnoreCase(SubmitType.UPDATE+"") && 
											("AdminEmployee".equalsIgnoreCase(_recordBean.getController()) || 
											"EmployeeRequest".equalsIgnoreCase(_recordBean.getController()) ||
											"DAStatus".equalsIgnoreCase(_recordBean.getController()) ||
											"VehicleInspection".equalsIgnoreCase(_recordBean.getController()))) {
											if("Role".equalsIgnoreCase(dataTh)) {%>
												<td class="td-block table-value" data-th="<%=dataTh%>"><select class="form-control form-control-sm" id="employeeRole<%=i%>" name="employeeRole<%=i%>"><%_array = _mainUtil.getDataArray(_mainUtil.getRole());
												for(int k=0; k<_array.length; k++) {%><option value="<%=_array[k][0]%>" <%if(colData.equalsIgnoreCase(_array[k][1])){%>selected<%}%>><%=_array[k][1]%></option><%}%></select></td>

											<%} else if("Language".equalsIgnoreCase(dataTh)) {%>
												<td class="td-block table-value" data-th="<%=dataTh%>"><select class="form-control form-control-sm" id="preferredLanguage<%=i%>" name="preferredLanguage<%=i%>"><%String preferredLanguageOptions = _recordBean.getPreferredLanguageOptions(); if(preferredLanguageOptions.length() == 0) { preferredLanguageOptions = "English"; } String _array1[] = preferredLanguageOptions.split("#"); for(int k=0; k<_array1.length; k++) {%><option value="<%=_array1[k]%>" <%if(colData.equalsIgnoreCase(_array1[k])){%>selected<%}%>><%=_array1[k]%></option><%}%></select></td>

											<%} else if("DA Comments".equalsIgnoreCase(dataTh)) {%>
												<td class="td-block table-value" data-th="<%=dataTh%>"><textarea id="daComments<%=i%>" name="daComments<%=i%>" rows="1" class="form-control form-control-sm"><%=colData%></textarea></td>

											<%} else if("Reason".equalsIgnoreCase(dataTh) && "EmployeeRequest".equalsIgnoreCase(_recordBean.getController())) {%>
												<td class="td-block table-value" data-th="<%=dataTh%>"><textarea id="timeOffReason<%=i%>" name="timeOffReason<%=i%>" rows="1" class="form-control form-control-sm"></textarea></td>

											<%} else if("Status".equalsIgnoreCase(dataTh) && "EmployeeRequest".equalsIgnoreCase(_recordBean.getController())) {%>
												<td class="td-block table-value" data-th="<%=dataTh%>"><select id="timeOffStatus<%=i%>" name="timeOffStatus<%=i%>" class="form-control form-control-sm">
													<option value=""></option>
													<option value="<%=RecordStatus.APPROVED%>"><%=RecordStatus.RecordStatus[RecordStatus.APPROVED]%></option>
													<option value="<%=RecordStatus.REJECTED%>"><%=RecordStatus.RecordStatus[RecordStatus.REJECTED]%></option>
												</select></td>

											<%} else if("Status".equalsIgnoreCase(dataTh) && "DAStatus".equalsIgnoreCase(_recordBean.getController())) {%>
												<td class="td-block table-value" data-th="<%=dataTh%>"><select id="recordStatus<%=i%>" name="recordStatus<%=i%>" class="form-control form-control-sm"><%_array = _mainUtil.getDataArray(_mainUtil.getDAStatus());
												for(int k=0; k<_array.length; k++) {%><option value="<%=_array[k][0]%>" <%if(colData.equalsIgnoreCase(_array[k][1])){%>selected<%}%>><%=_array[k][1]%></option><%}%></select></td>

											<%} else if("Confirmed By".equalsIgnoreCase(dataTh) && "DAStatus".equalsIgnoreCase(_recordBean.getController())) {
												colData = loginUser; %>
												<td class="td-block table-value" data-th="<%=dataTh%>"><select id="confirmedBy<%=i%>" name="confirmedBy<%=i%>" class="form-control form-control-sm"><option value=""></option><%_array = _mainUtil.getDataArray(_dispatcherMap);
												for(int k=0; k<_array.length; k++) {%><option value="<%=_array[k][0]%>" <%if(colData.equalsIgnoreCase(_array[k][0])){%>selected<%}%>><%=_array[k][1]%></option><%}%></select></td>

											<%} else if("Comments".equalsIgnoreCase(dataTh) && "DAStatus".equalsIgnoreCase(_recordBean.getController())) {%>
												<td class="td-block table-value" data-th="<%=dataTh%>"><textarea id="comments<%=i%>" name="comments<%=i%>" rows="1" class="form-control form-control-sm"><%=colData%></textarea></td>

											<%} else if("Type".equalsIgnoreCase(dataTh) && "EmployeeRequest".equalsIgnoreCase(_recordBean.getController())) {%>
												<td class="td-block table-value" data-th="<%=dataTh%>"><input type="hidden" id="timeOffType<%=i%>" name="timeOffType<%=i%>" value="<%=colData%>"><%=colData%></td>

											<%} else if("Dispatcher Comments".equalsIgnoreCase(dataTh)) {%>
												<td class="td-block table-value" data-th="<%=dataTh%>"><textarea id="dispatcherComments<%=i%>" name="dispatcherComments<%=i%>" rows="1" class="form-control form-control-sm"><%=colData%></textarea></td>

											<%} else if("Parking".equalsIgnoreCase(dataTh)) {%>
												<td class="td-block table-value" data-th="<%=dataTh%>"><select id="parking<%=i%>" name="parking<%=i%>" class="form-control form-control-sm"><%_array = _mainUtil.getDataArray(_mainUtil.getParking());
												for(int k=0; k<_array.length; k++) {%><option value="<%=_array[k][0]%>" <%if(colData.equalsIgnoreCase(_array[k][1])){%>selected<%}%>><%=_array[k][1]%></option><%}%></select></td>

											<%} else if("Status".equalsIgnoreCase(dataTh) && "VehicleInspection".equalsIgnoreCase(_recordBean.getController())) {%>
												<td class="td-block table-value" data-th="<%=dataTh%>"><select id="recordStatus<%=i%>" name="recordStatus<%=i%>" class="form-control form-control-sm">
													<option value="<%=RecordStatus.ACTIVE%>"><%=RecordStatus.RecordStatus[RecordStatus.ACTIVE]%></option>
													<option value="<%=RecordStatus.POST%>"><%=RecordStatus.RecordStatus[RecordStatus.POST]%></option>
												</select></td>

												<%if((j+1) > _recordBean.getLabelsList().size()) {%><input type="hidden" id="daCheckoutID<%=i%>" name="daCheckoutID<%=i%>" value="<%=rowList.get(j+1) == null ? "" : rowList.get(j+1).toString().trim()%>"><%}%>

											<%} else {%>
												<td class="td-block table-value" data-th="<%=dataTh%>"><a href="Javascript:submitPageDataForm('<%=SubmitType.UPDATE%>','<%=_recordBean.getController()%>','<%=searchID%>');"><%=colData%></a></td>
											<%}

										} else {
											if("Status".equalsIgnoreCase(dataTh) && "DAStatus".equalsIgnoreCase(_recordBean.getController())) {%>
												<td class="td-block table-value" data-th="<%=dataTh%>"><select id="recordStatus<%=i%>" name="recordStatus<%=i%>" class="form-control form-control-sm" onChange="updateRecordStatus(this,<%=searchID%>);"><%_array = _mainUtil.getDataArray(_mainUtil.getDAStatus());
												for(int k=0; k<_array.length; k++) {%><option value="<%=_array[k][0]%>" <%if(colData.equalsIgnoreCase(_array[k][1])){%>selected<%}%>><%=_array[k][1]%></option><%}%></select></td>

											<%} else if("Confirmed By".equalsIgnoreCase(dataTh) && "DAStatus".equalsIgnoreCase(_recordBean.getController())) {
												colData = loginUser;%>
												<td class="td-block table-value" data-th="<%=dataTh%>"><select id="confirmedBy<%=i%>" name="confirmedBy<%=i%>" class="form-control form-control-sm"><option value=""></option><%_array = _mainUtil.getDataArray(_dispatcherMap);
												for(int k=0; k<_array.length; k++) {%><option value="<%=_array[k][0]%>" <%if(colData.equalsIgnoreCase(_array[k][0])){%>selected<%}%>><%=_array[k][1]%></option><%}%></select></td>

											<%} else if("Comments".equalsIgnoreCase(dataTh) && "DAStatus".equalsIgnoreCase(_recordBean.getController())) {%>
												<td class="td-block table-value" data-th="<%=dataTh%>"><textarea id="comments<%=i%>" name="comments<%=i%>" rows="1" class="form-control form-control-sm"><%=colData%></textarea></td>

											<%} else if("View".equalsIgnoreCase(dataTh)) {%>
												<td class="<%=_recordBean.getBoldColumns() != null && _recordBean.getBoldColumns()[0] == j ? "th-block table-header-label" : "td-block table-value text-center"%>" data-th="<%=dataTh%>"><a title="View" href="Javascript:viewFile(<%=colData%>)"><i class="fa fa-eye" aria-hidden="true"></i></a><a title="Delete"  href="Javascript:deleteSearchRecord(<%=colData%>)"><i class="fa fa-trash" aria-hidden="true"></i></a></td>
											<%} else {%>
												<td class="<%=_recordBean.getBoldColumns() != null && _recordBean.getBoldColumns()[0] == j ? "th-block table-header-label" : "td-block table-value "+rowColor%>" data-th="<%=dataTh%>"><%=colData%></td>
											<%}
										}
									}%>
								<%}%>

								<%if(isBrowseReq && "VehicleInspection".equalsIgnoreCase(_recordBean.getController())) {%>
									<td class="td-block table-value text-center" nowrap><%if("Active".equalsIgnoreCase(colData) && "Status".equalsIgnoreCase(dataTh)) {%>
										<a TITLE="Update" href="Javascript:loadTransDataList('<%=searchID%>','<%=_recordBean.getController()%>');"><i class="fa fa-pencil-square-o fa-lg" aria-hidden="true"></i></a>
										
										<a TITLE="Upload" href="Javascript:openUploads('<%=searchID%>','<%=_recordBean.getController()%>');"><i class="fa fa-upload fa-lg" aria-hidden="true"></i></a>
										
										<%if(uploadIDs.length() > 0) {%><a title="View" href="Javascript:viewFile('<%=uploadIDs%>')"><i class="fa fa-eye" aria-hidden="true"></i></a><%} else {%><i class="fa fa-eye text-dark" aria-hidden="true"></i><%}
									}%></td>

								<%} else if(isBrowseReq && "EmployeeForms".equalsIgnoreCase(_recordBean.getController())) {%>
									<td class="td-block table-value text-center"><%if("Posted".equalsIgnoreCase(colData) && "Status".equalsIgnoreCase(dataTh)) {%><a TITLE="View" href="Javascript:submitPageDataForm('<%=SubmitType.PRINT%>','<%=_recordBean.getController()%>','<%=searchID%>');"><i class="fa fa-eye fa-lg" aria-hidden="true"></i></a><%}%></td>
								<%}%>

								</tr>
							<%}%>
							</tbody>

							<%if(_recordBean.getFooterList().size() > 0) {%>
								<tfoot class="tfoot-block">
									<%for (int i = 0; i < _recordBean.getFooterList().size(); i++) {
									List rowList = (ArrayList) _recordBean.getFooterList().get(i);%>
									<tr class="tr-block"><%
									for (int j = 1; j < _recordBean.getLabelsList().size()+1; j++) {
										String colData = rowList.get(j) == null ? "" : rowList.get(j).toString().trim();
										String dataTh = _recordBean.getLabelsList().get(j-1).toString();%>
										<td class="th-block table-header-label text-left" data-th="<%=dataTh%>"><%=colData%></td>
									<%}%>
									</tr>
									<%}%>
								</tfoot>
							<%}%>
						</table>
					<%}%>

				<%} else if(_recordBean.getReportsList().size() > 0) {%>
					<div class="row col-12">
					<%for(int i=0; i<_recordBean.getReportsList().size(); i++) {%>
						<div class="col-12 col-md-4 mb-2 mb-md-0 text-md-left"><a href="Javascript:loadReportFilters('<%=_recordBean.getReportsList().get(i)%>');"><%=_recordBean.getReportsList().get(i)%></a></div>
					<%}%>
					</div>

					<div class="col-12 py-3 m-0 p-0" id="reportFiltersDivID">
					</div>

				<%} else {%>
					<div class="no_records text-center my-5">No records found</div>
				<%}%>
			<%}%>

			<!-- Bottom buttons section starts -->
			<div class="row my-4 text-center text-md-left">
			<%if("EmployeeSchedule".equalsIgnoreCase(_recordBean.getController()) || 
			"DACheckout".equalsIgnoreCase(_recordBean.getController()) || 
			"EmployeeTermination".equalsIgnoreCase(_recordBean.getController()) || 
			"EmployeeIncident".equalsIgnoreCase(_recordBean.getController()) || 
			"EmployeeRequest".equalsIgnoreCase(_recordBean.getController()) || 
			"DAStatus".equalsIgnoreCase(_recordBean.getController()) || 
			"VehicleInspection".equalsIgnoreCase(_recordBean.getController())) {%>
				<div class="col-12 col-md-4 mb-2 mb-md-0 text-md-left">
					<%if("EmployeeSchedule".equalsIgnoreCase(_recordBean.getController()) || 
					"EmployeeRequest".equalsIgnoreCase(_recordBean.getController()) || 
					"DAStatus".equalsIgnoreCase(_recordBean.getController()) || 
					"VehicleInspection".equalsIgnoreCase(_recordBean.getController())) {
						if(!_recordBean.getSelectedType().equalsIgnoreCase(SubmitType.UPDATE+"")) {
							if("EmployeeSchedule".equalsIgnoreCase(_recordBean.getController())) {%><button class="btn btn-secondary mb-1" onClick="Javascript:searchPageDataForm('<%=SubmitType.UPDATE%>','<%=_recordBean.getController()%>', 'Repeat');" TITLE="Repeat schedule for 1 week">Repeat</button><%}%>

							<%if(_recordBean.getDataList().size() > 0) {%><button class="btn btn-secondary mb-1" onClick="Javascript:searchPageDataForm('<%=SubmitType.UPDATE%>','<%=_recordBean.getController()%>', 'Update');" TITLE="Update">Update</button><%}%>
						<%}
					}%>
				</div>

				<div class="col-12 col-md-4 mb-2 mb-md-0 text-md-center">
					<%if(_recordBean.getSelectedType().equalsIgnoreCase(SubmitType.UPDATE+"")) {
						if("EmployeeSchedule".equalsIgnoreCase(_recordBean.getController())) {%>
							<input type="hidden" id="numOfRows" name="numOfRows" value="<%=numOfValues%>">
							<input type="hidden" id="dynamicParams" name="dynamicParams" value="recordID,recordIDVal">
						<%} else if("VehicleInspection".equalsIgnoreCase(_recordBean.getController())) {%>
							<input type="hidden" id="numOfRows" name="numOfRows" value="<%=_recordBean.getDataList().size()%>">
							<input type="hidden" id="dynamicParams" name="dynamicParams" value="recordID,daComments,dispatcherComments,parking,daCheckoutID,recordStatus">
						<%} else if("DAStatus".equalsIgnoreCase(_recordBean.getController())) {%>
							<input type="hidden" id="numOfRows" name="numOfRows" value="<%=_recordBean.getDataList().size()%>">
							<input type="hidden" id="dynamicParams" name="dynamicParams" value="recordID,recordStatus,confirmedBy,comments">
						<%} else if("EmployeeRequest".equalsIgnoreCase(_recordBean.getController())) {%>
							<input type="hidden" id="numOfRows" name="numOfRows" value="<%=_recordBean.getDataList().size()%>">
							<input type="hidden" id="dynamicParams" name="dynamicParams" value="recordID,timeOffStatus,timeOffReason,timeOffType">
						<%} if(_recordBean.getDataList().size() > 0) {%>
						<button class="btn btn-success mb-1" onClick="Javascript:searchPageDataForm1('<%=SubmitType.UPDATE_CONFIRM%>','<%=_recordBean.getController()%>');">Save</button>
						<%}%>

					<%} else {
						if(_recordBean.isDisplaySMSBtn() && _recordBean.getDataList().size() > 0) {%><button class="btn btn-secondary mb-1" onClick="Javascript:searchPageDataForm('<%=SubmitType.DYNAMIC%>','<%=_recordBean.getController()%>','',this);">SMS</button><%} else {%><script>enableOrDisableID("smsBtnTopID", "none")</script><%}

						if(isActiveRecords && _recordBean.isDisplayPostBtn() && "VehicleInspection".equalsIgnoreCase(_recordBean.getController())) {%><button class="btn btn-success mb-1" onClick="Javascript:searchPageDataForm('<%=SubmitType.FINAL%>','<%=_recordBean.getController()%>','DACheckout');">DA Checkout</button>&nbsp;&nbsp;<%} else {%><script>enableOrDisableID("postCheckoutBtnTopID", "none")</script><%}

						if(isActiveRecords && _recordBean.isDisplayPostBtn()) {%><button class="btn btn-success mb-1" onClick="Javascript:searchPageDataForm('<%=SubmitType.FINAL%>','<%=_recordBean.getController()%>','',this);">Post</button><%} else {%><script>enableOrDisableID("postBtnTopID", "none")</script><%}
					}%>
				</div>
				<div class="col-12 col-md-4 mb-2 mb-md-0 text-md-right">
					<%if(_recordBean.getDataList().size() > 0 && "DAStatus".equalsIgnoreCase(_recordBean.getController())) {%>
						<button id="deleteBtnTopID" class="btn btn-danger mb-1" onClick="Javascript:searchPageDataForm('<%=SubmitType.DELETE%>','<%=_recordBean.getController()%>');">Delete</button>
					<%}%>
				</div>

			<%} else if("AdminEmployee".equalsIgnoreCase(_recordBean.getController())) {%>
				<%if(_recordBean.getSelectedType().equalsIgnoreCase(SubmitType.UPDATE+"")) {%>
					<input type="hidden" id="numOfRows" name="numOfRows" value="<%=_recordBean.getDataList().size()%>">
					<input type="hidden" id="dynamicParams" name="dynamicParams" value="recordID,employeeRole,preferredLanguage">

					<div class="col-12 col-md-4 mb-2 mb-md-0 text-md-left"></div>
					<div class="col-12 col-md-4 mb-2 mb-md-0 text-md-center">
						<button class="btn btn-success mb-1" onClick="Javascript:searchPageDataForm1('<%=SubmitType.UPDATE_CONFIRM%>','<%=_recordBean.getController()%>');">Save</button>
					</div>
					<div class="col-12 col-md-4 mb-2 mb-md-0 text-md-right"></div>
				<%} else {%>
					<div class="col-12 col-md-4 mb-2 mb-md-0 text-md-left">
						<button class="btn btn-secondary mb-1" onClick="Javascript:searchPageDataForm('<%=SubmitType.UPDATE%>','<%=_recordBean.getController()%>');" TITLE="Update">Update</button>
					</div>
					<div class="col-12 col-md-4 mb-2 mb-md-0 text-md-center">
						<%if(_recordBean.getDataList().size() > 0) {%><button class="btn btn-secondary mb-1" onClick="Javascript:searchPageDataForm('<%=SubmitType.PRINT%>','<%=_recordBean.getController()%>');">Print</button><%}%>
					</div>
					<div class="col-12 col-md-4 mb-2 mb-md-0 text-md-right"></div>
				<%}%>

			<%} else if("DACheckin".equalsIgnoreCase(_recordBean.getController())) {%>
				<%if(_recordBean.getSelectedType().equalsIgnoreCase(SubmitType.UPDATE+"")) {%>
					<script>selectVehicleData();</script>
					<input type="hidden" id="numOfRows" name="numOfRows" value="<%=_recordBean.getDataList().size()%>">
					<input type="hidden" id="dynamicParams" name="dynamicParams" value="recordID,employeeID,vehicleID,clockinTime">

					<div class="col-12 col-md-4 mb-2 mb-md-0 text-md-left"></div>
					<div class="col-12 col-md-4 mb-2 mb-md-0 text-md-center">
						<button class="btn btn-success mb-1" onClick="Javascript:searchPageDataForm1('<%=SubmitType.UPDATE_CONFIRM%>','<%=_recordBean.getController()%>');">Save</button>
					</div>
					<div class="col-12 col-md-4 mb-2 mb-md-0 text-md-right"></div>
					<script>
					if(dupVehicleDataArray.length > 0) {
						alert("Please check below vehicles selected to multiple employees\n"+dupVehicleDataArray);
						dupVehicleDataArray = new Array();
					}
					isPageLoadDone = true;
					</script>

				<%} else {%>
					<div class="col-12 col-md-4 mb-2 mb-md-0 text-md-left">
						<%if(isActiveRecords) {%><button class="btn btn-secondary mb-1" onClick="Javascript:searchPageDataForm('<%=SubmitType.UPDATE%>','<%=_recordBean.getController()%>');">Swap</button><%} else {%><script>enableOrDisableID("swapBtnTopID", "none")</script><%}%>

						<%if("DACheckin".equalsIgnoreCase(_recordBean.getController())) {%>
						<!--button class="btn btn-secondary mb-1" onClick="Javascript:searchPageDataForm('<%=SubmitType.UPDATE%>','<%=_recordBean.getController()%>', 'Run');">Run</button>

						<button class="btn btn-secondary mb-1" onClick="Javascript:searchPageDataForm('<%=SubmitType.UPDATE%>','<%=_recordBean.getController()%>', 'Next Day Run');" TITLE="Next Day Run">Run <i class="fa fa-angle-double-right" aria-hidden="true"></i></button -->
						<%}%>
					</div>
					<div class="col-12 col-md-4 mb-2 mb-md-0 text-md-center">
						<%if(isActiveRecords && _recordBean.isDisplayPostBtn()) {%><button class="btn btn-success mb-1" onClick="Javascript:searchPageDataForm('<%=SubmitType.FINAL%>','<%=_recordBean.getController()%>','',this);">Post</button><%} else {%><script>enableOrDisableID("postBtnTopID", "none")</script><%}%>

						<%if(_recordBean.isDisplaySMSBtn() && _recordBean.getDataList().size() > 0) {%><button class="btn btn-secondary mb-1" onClick="Javascript:searchPageDataForm('<%=SubmitType.DYNAMIC%>','<%=_recordBean.getController()%>','',this);">SMS</button><%} else {%><script>enableOrDisableID("smsBtnTopID", "none")</script><%}%>

						<%if(_recordBean.isDisplayPrintBtn()) {%><button class="btn btn-secondary mb-1" onClick="Javascript:searchPageDataForm('<%=SubmitType.PRINT%>','<%=_recordBean.getController()%>');">Print</button><%}%>

						<%if(_recordBean.isDisplayViewBtn()) {%><button class="btn btn-secondary mb-1" onClick="Javascript:searchPageDataForm('<%=SubmitType.PRINT%>','<%=_recordBean.getController()%>', 'view');">View</button><%}%>
					</div>
					<div class="col-12 col-md-4 mb-2 mb-md-0 text-md-right">
						<%if("DACheckin".equalsIgnoreCase(_recordBean.getController())) {%>
						<button class="btn btn-secondary mb-1" onClick="Javascript:searchPageDataForm('<%=SubmitType.UPDATE%>','<%=_recordBean.getController()%>', 'NewRun');">New Run</button>

						<button class="btn btn-secondary mb-1" onClick="Javascript:searchPageDataForm('<%=SubmitType.UPDATE%>','<%=_recordBean.getController()%>', 'NewNext Day Run');" TITLE="Next Day Run">New Run <i class="fa fa-angle-double-right" aria-hidden="true"></i></button>
						<%}%>
						<%if(isActiveRecords) {%><button class="btn btn-danger mb-1" onClick="Javascript:searchPageDataForm('<%=SubmitType.DELETE%>','<%=_recordBean.getController()%>');">Delete</button><%} else {%><script>enableOrDisableID("deleteBtnTopID", "none")</script><%}%>
					</div>
				<%}

			}%>
			</div>
			<!-- Bottom buttons section ends -->
		</div></div>
	</div>
</div>
<%@ include file="includeFooter.jsp"%>
<script>
function autoResize(textarea) {
	textarea.style.height = "auto"; // reset
	textarea.style.height = textarea.scrollHeight + "px";
}
window.addEventListener("load", () => {
	document.querySelectorAll("textarea").forEach(t => autoResize(t));
});

function openUploads(recordID, controller) {
	var module = controller;
	var vehicleID = "", employeeID = "";
	if("VehicleInspection" == controller) {
		module = "Inspection";
		vehicleID = recordID;
	} else {
		employeeID = recordID;
	}

	var appQry = "&module="+module+"&vehicleID="+vehicleID+"&employeeID="+employeeID;	window.open("../servlet/MVPGServlet?submitType=<%=SubmitType.UPLOAD%>&controller=CommonUpload&isPopup=yes"+appQry+getPageSubmitFormValues(true), "uploadPopup", "width=900, height=900, menubar=no, status=no, scrollbars=yes, toolbar=no, location=no, directories=no");
}
</script>