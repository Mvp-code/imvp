<!DOCTYPE html>
<%@ page import="java.util.*, com.util.*"%>
<jsp:useBean id="_errorBean" class="com.beans.ErrorBean" scope="request" />
<jsp:useBean id="_recordBean" class="com.beans.GenericUpload" scope="request" />
<%
int submitType = request.getAttribute("submitType") == null ? SubmitType.CREATE : Integer.parseInt(request.getAttribute("submitType").toString().trim());
%>

<script>
function validatePageData(submitType, isValid) {

	if(submitType == <%=SubmitType.CREATE_CONFIRM%>) {
		if(isValid) {
			var mandatoryFieldsArray = new Array();
			mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["uploadFileName"], "File to Upload");
			isValid = validateMandatoryFieldsInForm(mandatoryFieldsArray, isValid);
		}

	} else if(submitType == <%=SubmitType.DELETE%>) {
		isValid = deleteRecord();
	}

	return isValid;
}

function checkButtons(thisObj) {

	enableOrDisableID("saveBtn", "");
	enableOrDisableID("runBtn", "none");
	enableOrDisableID("nextDayRunBtn", "none");

	enableOrDisableID("runBtn1", "none");
	enableOrDisableID("nextDayRunBtn1", "none");
	if(thisObj.value == "EmployeeSchedule") {
		enableOrDisableID("saveBtn", "none");
		//enableOrDisableID("runBtn", "");
		//enableOrDisableID("nextDayRunBtn", "");

		enableOrDisableID("runBtn1", "");
		enableOrDisableID("nextDayRunBtn1", "");
	}
	if(thisObj.value == "Escalations" || thisObj.value == "DashboardOverview" || thisObj.value == "Delivered Packages" || thisObj.value == "Service Details" || thisObj.value == "Weekly Report")
		document.formmain["dataSeperator"].value = ",";
	else
		document.formmain["dataSeperator"].value = "";

}
</script>

<%@ include file="includeHeader.jsp"%>
<div class='row my-2'>
	<div class='col-12 mb-2'>
		<div class='card'>
			<div class='card-header table-title-header m-0 py-2'>
				<div class="row">
					<div class="col-2"></div>
					<div class="col-8"><%=_recordBean.getDisplayName()%></div>
					<div class="col-2 text-right my-auto"><%if(submitType == SubmitType.BROWSE) {%><button class="btn btn-primary btn-sm" onClick="Javascript:submitPageDataForm('<%=SubmitType.UPLOAD%>','<%=_recordBean.getController()%>');" title="Create New">New</button><%}%></div>
				</div>
			</div>

			<%if(_errorBean != null && _errorBean.getType().length() > 0) {%>
				<div class="row text-center"><section class='alert_section'><div class='alert-box <%=_errorBean.getType()%>Color'><%=_errorBean.getMesg()%></div></section></div>
			<%}%>

			<div class='card-body m-1 p-1'>
			<input type="hidden" id="<%=_recordBean.PRIMARY_KEY_ID%>" name="_recordBean.PRIMARY_KEY_ID" value="<%=_recordBean.getRecordID()%>">
			<%if(submitType == SubmitType.CREATE || submitType == SubmitType.UPDATE) {%>
				<div class="row">
					<div class="col-5">
						<div class="row form-row form-group form-group-sm">
							<label class="col-3 col-form-label required text-left">First Name</label>
							<div class="col-9 text-left"><input type="text" id="firstName" name="firstName" class="form-control form-control-sm" value=""></div>
						</div>
					</div>

					<div class="col-2"></div>

					<div class="col-5">
					</div>
				</div>
				<script>
				</script>

			<%} else if(submitType == SubmitType.UPLOAD) {%>
				<div class="row">
					<div class="col-12 col-md-4">
						<div class="row form-row form-group form-group-sm">
							<label class="col-3 col-form-label required text-left">Doc Type</label>
							<div class="col-9 text-left"><select id="tableName" name="tableName" class="form-control form-control-sm" onChange="checkButtons(this);">
								<option value=""></option>
								<option value="Associates Concessions">Associates Concessions</option>
								<option value="Engine Off Compliance (EOC) Overview">Engine Off Compliance (EOC) Overview</option>
								<option value="Daily Routes">Daily Routes</option>
								<option value="DashboardOverview">Dashboard Overview</option>
								<option value="Daily Itineraries">Daily Itineraries</option>
								<option value="DVIC">DVIC</option>
								<option value="DeliveryOverview">Delivery Overview</option>
								<option value="Employee">Employee</option>
								<option value="EmployeeSchedule">Employee Schedules</option>
								<option value="Escalations">Escalations</option>
								<option value="SafetyDashboard">Safety Dashboard</option>
								<option value="Station Level">Station Level</option>
								<option value="QualityOverview">Quality Overview</option>
								<option value="Vehicles">Vehicles</option>
								<option value="WST Delivered Packages">WST Delivered Packages</option>
								<option value="WST Service Details">WST Service Details</option>
								<option value="WST Weekly Report">WST Weekly Report</option>
								
							</select></div>
						</div>
					</div>

					<div class="col-12 col-md-4">
						<div class="row form-row form-group form-group-sm">
							<label class="col-3 col-form-label required text-left">File to Upload</label>
							<div class="col-9 text-left"><input type="file" id="uploadFileName" name="uploadFileName"></div>
						</div>
					</div>

					<div class="col-12 col-md-3">
						<div class="row form-row form-group form-group-sm">
							<label class="col-9 col-form-label text-left">Data seperator for csv file</label>
							<div class="col-3 text-left"><input type="text" id="dataSeperator" name="dataSeperator"></div>
						</div>
					</div>
				</div>

			<%} else if(submitType == SubmitType.BROWSE) {%>
				<div class="row">
					<div class="col-5">
						<div class="row">
							<label class="col-3 col-form-label text-left">First Name</label>
							<div class="col-9 form-control-plaintext text-left"></div>
						</div>
					</div>

					<div class="col-2"></div>

					<div class="col-5">
					</div>
				</div>
			<%}%>
			</div>
		</div>

		<%if(submitType == SubmitType.UPLOAD) {%>
			<div class="row mt-4">
				<div class="col-4 text-left">
					<button class="btn btn-secondary text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.SEARCH%>','<%=_recordBean.getController()%>','');">Back to search</button>
				</div>
				<div class="col-4 text-center">
					<button id="saveBtn" class="btn btn-success text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.CREATE_CONFIRM%>','<%=_recordBean.getController()%>','<%=_recordBean.getRecordID()%>');">Save</button>

					<button id="runBtn" style="display:none" class="btn btn-success text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.CREATE_CONFIRM%>','<%=_recordBean.getController()%>','<%=_recordBean.getRecordID()%>', '', '&selectedType=Run');">Run</button>

					<button id="nextDayRunBtn" style="display:none" class="btn btn-success text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.CREATE_CONFIRM%>','<%=_recordBean.getController()%>','<%=_recordBean.getRecordID()%>', '', '&selectedType=Next Day Run');" TITLE="Next Day Run">Run <i class="fa fa-angle-double-right" aria-hidden="true"></i></button>
				</div>
				<div class="col-4 text-right">
					<button id="runBtn1" style="display:none" class="btn btn-success text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.CREATE_CONFIRM%>','<%=_recordBean.getController()%>','<%=_recordBean.getRecordID()%>', '', '&selectedType=NewRun');">New Run</button>

					<button id="nextDayRunBtn1" style="display:none" class="btn btn-success text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.CREATE_CONFIRM%>','<%=_recordBean.getController()%>','<%=_recordBean.getRecordID()%>', '', '&selectedType=NewNext Day Run');" TITLE="Next Day Run">New Run <i class="fa fa-angle-double-right" aria-hidden="true"></i></button>
				</div>
			</div>

		<%} else if(submitType == SubmitType.CREATE || submitType == SubmitType.UPDATE) {%>
			<div class="row mt-4">
				<div class="col-4 text-left">
					<button class="btn btn-secondary text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.SEARCH%>','<%=_recordBean.getController()%>','');">Back to search</button>
				</div>
				<div class="col-4 text-center">
					<%if(submitType == SubmitType.CREATE) {%>
						<button class="btn btn-success text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.CREATE_CONFIRM%>','<%=_recordBean.getController()%>','<%=_recordBean.getRecordID()%>');">Save</button>
					<%} else {%>
						<button class="btn btn-success text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.UPDATE_CONFIRM%>','<%=_recordBean.getController()%>','<%=_recordBean.getRecordID()%>');">Save</button>
					<%}%>
				<div class="col-4 text-right"></div>
			</div>

		<%} else if(submitType == SubmitType.BROWSE) {%>
			<div class="row mt-4">
				<div class="col-4 text-left">
					<button class="btn btn-secondary text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.SEARCH%>','<%=_recordBean.getController()%>','');">Back to search</button>
				</div>
				<div class="col-4 text-center">
				<%if("0".equalsIgnoreCase(_recordBean.getStatus())) {%>
					<button class="btn btn-primary text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.UPDATE%>','<%=_recordBean.getController()%>','<%=_recordBean.getRecordID()%>');">Edit</button>
				<%}%>
				</div>
				<div class="col-4 text-right">
				<%if("0".equalsIgnoreCase(_recordBean.getStatus())) {%>
					<button class="btn btn-danger text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.DELETE%>','<%=_recordBean.getController()%>','<%=_recordBean.getRecordID()%>');">Delete</button>
				<%}%>
				</div>
			</div>
		<%}%>
	</div>
</div>
<%@ include file="includeFooter.jsp"%>