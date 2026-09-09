<!DOCTYPE html>
<%@ page import="java.util.*, com.util.*"%>
<jsp:useBean id="_errorBean" class="com.beans.ErrorBean" scope="request" />
<jsp:useBean id="_recordBean" class="com.beans.AdminGasCard" scope="request" />
<%
int submitType = request.getAttribute("submitType") == null ? SubmitType.CREATE : Integer.parseInt(request.getAttribute("submitType").toString().trim());
%>

<script>
function validatePageData(submitType, isValid) {

	if(submitType == <%=SubmitType.CREATE_CONFIRM%> || submitType == <%=SubmitType.UPDATE_CONFIRM%>) {
		if(isValid) {
			var mandatoryFieldsArray = new Array();
			mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["cardIdentifier"], "Card ID");
			if(document.formmain["cardStatus"] && document.formmain["cardStatus"].value == "4") {
				mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["cardStatusReason"], "Reason");
			}
			mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["cardStatusDate"], "Card Status Date");
			mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["cardExpiry"], "Card Expiry");
			mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["location"], "Location");
			isValid = validateMandatoryFieldsInForm(mandatoryFieldsArray, isValid);
		}

	} else if(submitType == <%=SubmitType.DELETE%>) {
		isValid = deleteRecord();
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
					<div class="col-8"><%=_recordBean.getDisplayName()%></div>
					<div class="col-2 text-right my-auto"><%if(submitType == SubmitType.BROWSE) {%><button class="btn btn-primary btn-sm" onClick="Javascript:submitPageDataForm('<%=SubmitType.CREATE%>','<%=_recordBean.getController()%>');" title="Create New">New</button><%}%></div>
				</div>
			</div>

			<%if(_errorBean != null && _errorBean.getType().length() > 0) {%>
				<div class="row text-center"><section class='alert_section'><div class='alert-box <%=_errorBean.getType()%>Color'><%=_errorBean.getMesg()%></div></section></div>
			<%}%>

			<div class='card-body m-1 p-1'>
			<%if(submitType == SubmitType.CREATE || submitType == SubmitType.UPDATE) {%>
				<script>
				function checkStatus(thisObj, divID) {
					enableOrDisableID(divID, "none");
					if(thisObj.value == "4") {
						enableOrDisableID(divID, "");
					} else {
						document.formmain["cardStatusReason"].value = "";
					}
				}
				</script>
				<input type="hidden" id="gasCardID" name="gasCardID" value="<%=_recordBean.getGasCardID()%>">
				<div class="row">
					<div class="col-5">
						<div class="row form-row form-group form-group-sm">
							<label class="col-3 col-form-label required text-left">Card ID</label>
							<div class="col-9 text-left"><input type="text" id="cardIdentifier" name="cardIdentifier" class="form-control form-control-sm" value="<%=_recordBean.getCardIdentifier()%>"></div>
						</div>
						<div class="row">
							<label class="col-3 col-form-label text-left">Card Status</label>
							<div class="col-9 text-left">
								<div class="form-check-inline">
									<label class="form-check-label"><input type="radio" class="form-check-input" name="cardStatus" value="0" checked onChange="Javascript:checkStatus(this,'cardStatusReasonDivID');">Active</label>
								</div>
								<div class="form-check-inline">
									<label class="form-check-label"><input type="radio" class="form-check-input" name="cardStatus" value="4" onChange="Javascript:checkStatus(this,'cardStatusReasonDivID');">Inactive</label>
								</div>
							</div>
						</div>
						<div class="row form-row form-group form-group-sm" id="cardStatusReasonDivID" <%if(!"4".equalsIgnoreCase(_recordBean.getCardStatus())) {%>style="display:none"<%}%>>
							<label class="col-3 col-form-label required text-left">Reason</label>
							<div class="col-9 text-left"><textarea id="cardStatusReason" name="cardStatusReason" class="form-control form-control-sm"><%=_recordBean.getCardStatusReason()%></textarea></div>
						</div>
						<div class="row form-row form-group form-group-sm">
							<label class="col-3 col-form-label required text-left">Card Status Date</label>
							<div class="col-9 text-left"><input type="text" id="cardStatusDate" name="cardStatusDate" class="form-control form-control-sm datepicker" value="<%=_recordBean.getCardStatusDate()%>"></div>
						</div>
						<div class="row form-row form-group form-group-sm">
							<label class="col-3 col-form-label required text-left">Card Expiry</label>
							<div class="col-9 text-left"><input type="text" id="cardExpiry" name="cardExpiry" class="form-control form-control-sm datepicker" value="<%=_recordBean.getCardExpiry()%>"></div>
						</div>
					</div>

					<div class="col-2"></div>

					<div class="col-5">
						<div class="row">
							<label class="col-3 col-form-label text-left">Lock Status</label>
							<div class="col-9 text-left">
								<div class="form-check-inline">
									<label class="form-check-label"><input type="radio" class="form-check-input" name="lockStatus" value="5" checked>Locked</label>
								</div>
								<div class="form-check-inline">
									<label class="form-check-label"><input type="radio" class="form-check-input" name="lockStatus" value="6">Unlocked</label>
								</div>
							</div>
						</div>
						<div class="row">
							<label class="col-3 col-form-label text-left">Available</label>
							<div class="col-9 text-left">
								<div class="form-check-inline">
									<label class="form-check-label"><input type="radio" class="form-check-input" name="available" value="1">Yes</label>
								</div>
								<div class="form-check-inline">
									<label class="form-check-label"><input type="radio" class="form-check-input" name="available" value="0" checked>No</label>
								</div>
							</div>
						</div>
						<div class="row form-row form-group form-group-sm">
							<label class="col-3 col-form-label required text-left">Location</label>
							<div class="col-9 text-left"><input type="text" id="location" name="location" class="form-control form-control-sm" value="<%=_recordBean.getLocation()%>"></div>
						</div>
					</div>
				</div>
				<script>
					setRadioButtonValue(document.formmain["cardStatus"], "<%=_recordBean.getCardStatus()%>");
					setRadioButtonValue(document.formmain["lockStatus"], "<%=_recordBean.getLockStatus()%>");
					setRadioButtonValue(document.formmain["available"], "<%=_recordBean.getAvailable()%>");
				</script>

			<%} else if(submitType == SubmitType.BROWSE) {%>
				<input type="hidden" id="gasCardID" name="gasCardID" value="<%=_recordBean.getGasCardID()%>">
				<div class="row">
					<div class="col-5">
						<div class="row">
							<label class="col-3 col-form-label text-left">Card ID</label>
							<div class="col-9 form-control-plaintext text-left"><%=_recordBean.getCardIdentifier()%></div>
						</div>
						<div class="row">
							<label class="col-3 col-form-label text-left">Card Status</label>
							<div class="col-9 form-control-plaintext text-left"><%=RecordStatus.RecordStatus[Integer.parseInt(_recordBean.getCardStatus())]%></div>
						</div>
						<%if(_recordBean.getCardStatusReason().length() > 0) {%>
						<div class="row">
							<label class="col-3 col-form-label text-left">Reason</label>
							<div class="col-9 form-control-plaintext text-left"><%=_recordBean.getCardStatusReason()%></div>
						</div>
						<%}%>
						<div class="row">
							<label class="col-3 col-form-label text-left">Card Status Date</label>
							<div class="col-9 form-control-plaintext text-left"><%=_recordBean.getCardStatusDate()%></div>
						</div>
						<div class="row">
							<label class="col-3 col-form-label text-left">Card Expiry</label>
							<div class="col-9 form-control-plaintext text-left"><%=_recordBean.getCardExpiry()%></div>
						</div>
					</div>

					<div class="col-2"></div>

					<div class="col-5">
						<div class="row">
							<label class="col-3 col-form-label text-left">Lock Status</label>
							<div class="col-9 form-control-plaintext text-left"><%=RecordStatus.RecordStatus[Integer.parseInt(_recordBean.getLockStatus())]%></div>
						</div>
						<div class="row">
							<label class="col-3 col-form-label text-left">Available</label>
							<div class="col-9 form-control-plaintext text-left"><%="1".equalsIgnoreCase(_recordBean.getAvailable()) ? "Yes" : "No"%></div>
						</div>
						<div class="row">
							<label class="col-3 col-form-label text-left">Location</label>
							<div class="col-9 form-control-plaintext text-left"><%=_recordBean.getLocation()%></div>
						</div>
					</div>
				</div>
			<%}%>
			</div>
		</div>

		<%if(submitType == SubmitType.CREATE || submitType == SubmitType.UPDATE) {%>
			<div class="row mt-4">
				<div class="col-4 text-left">
					<button class="btn btn-secondary text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.SEARCH%>','<%=_recordBean.getController()%>','');">Back to search</button>
				</div>
				<div class="col-4 text-center">
					<%if(submitType == SubmitType.CREATE) {%>
						<button class="btn btn-success text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.CREATE_CONFIRM%>','<%=_recordBean.getController()%>','<%=_recordBean.getGasCardID()%>');">Save</button>
						<!--button class="btn btn-success text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.CREATE_CONFIRM%>','<%=_recordBean.getController()%>','<%=_recordBean.getGasCardID()%>','2');">Save & Post</button --></div>
					<%} else {%>
						<button class="btn btn-success text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.UPDATE_CONFIRM%>','<%=_recordBean.getController()%>','<%=_recordBean.getGasCardID()%>');">Save</button>
						<!--button class="btn btn-success text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.UPDATE_CONFIRM%>','<%=_recordBean.getController()%>','<%=_recordBean.getGasCardID()%>','2');">Save & Post</button --></div>
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
					<button class="btn btn-primary text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.UPDATE%>','<%=_recordBean.getController()%>','<%=_recordBean.getGasCardID()%>');">Edit</button>
				<%}%>
				</div>
				<div class="col-4 text-right">
				<%if("0".equalsIgnoreCase(_recordBean.getStatus())) {%>
					<button class="btn btn-danger text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.DELETE%>','<%=_recordBean.getController()%>','<%=_recordBean.getGasCardID()%>');">Delete</button>
				<%}%>
				</div>
			</div>
		<%}%>
	</div>
</div>
<%@ include file="includeFooter.jsp"%>