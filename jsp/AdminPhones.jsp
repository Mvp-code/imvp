<!DOCTYPE html>
<%@ page import="java.util.*, com.util.*"%>
<jsp:useBean id="_errorBean" class="com.beans.ErrorBean" scope="request" />
<jsp:useBean id="_recordBean" class="com.beans.AdminPhones" scope="request" />
<%
int submitType = request.getAttribute("submitType") == null ? SubmitType.CREATE : Integer.parseInt(request.getAttribute("submitType").toString().trim());
%>

<script>
function validatePageData(submitType, isValid) {

	if(submitType == <%=SubmitType.CREATE_CONFIRM%> || submitType == <%=SubmitType.UPDATE_CONFIRM%>) {
		if(isValid) {
			var mandatoryFieldsArray = new Array();
			mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["phoneNumber"], "Phone Number");
			if(document.formmain["phoneStatus"] && document.formmain["phoneStatus"].value == "4") {
				mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["remarks"], "Remarks");
			}
			mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["serialNumber"], "Serial Number");
			mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["validity"], "Validity");
			if(document.formmain["auditedBy"] && document.formmain["auditedBy"].value.length > 0 || document.formmain["auditedDate"] && document.formmain["auditedDate"].value.length > 0) {
				mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["auditedBy"], "Audited By");
				mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["auditedDate"], "Audited Date");
			}
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
				</script>
				<input type="hidden" id="phoneID" name="phoneID" value="<%=_recordBean.getPhoneID()%>">
				<div class="row">
					<div class="col-5">
						<div class="row form-row form-group form-group-sm">
							<label class="col-3 col-form-label required text-left">Phone Number</label>
							<div class="col-9 text-left"><input type="text" id="phoneNumber" name="phoneNumber" class="form-control form-control-sm" value="<%=_recordBean.getPhoneNumber()%>"></div>
						</div>
						<div class="row">
							<label class="col-3 col-form-label text-left">Phone Status</label>
							<div class="col-9 text-left">
								<div class="form-check-inline">
									<label class="form-check-label"><input type="radio" class="form-check-input" name="phoneStatus" value="0" checked>Active</label>
								</div>
								<div class="form-check-inline">
									<label class="form-check-label"><input type="radio" class="form-check-input" name="phoneStatus" value="4">Inactive</label>
								</div>
							</div>
						</div>
						<div class="row form-row form-group form-group-sm">
							<label class="col-3 col-form-label required text-left">Serial Number</label>
							<div class="col-9 text-left"><input type="text" id="serialNumber" name="serialNumber" class="form-control form-control-sm" value="<%=_recordBean.getSerialNumber()%>"></div>
						</div>
					</div>

					<div class="col-2"></div>

					<div class="col-5">
						<div class="row form-row form-group form-group-sm">
							<label class="col-3 col-form-label required text-left">Validity</label>
							<div class="col-9 text-left"><input type="text" id="validity" name="validity" class="form-control form-control-sm datepicker" value="<%=_recordBean.getValidity()%>"></div>
						</div>
						<div class="row form-row form-group form-group-sm">
							<label class="col-3 col-form-label text-left">Audited</label>
							<div class="col-4 text-left"><input type="text" id="auditedBy" name="auditedBy" class="form-control form-control-sm" value="<%=_recordBean.getAuditedBy()%>" placeholder="By"></div>
							<div class="col-5 text-left"><input type="text" id="auditedDate" name="auditedDate" class="form-control form-control-sm datepicker" value="<%=_recordBean.getAuditedDate()%>" placeholder="Date"></div>
						</div>
						<div class="row form-row form-group form-group-sm">
							<label class="col-3 col-form-label text-left">Remarks</label>
							<div class="col-9 text-left"><textarea id="remarks" name="remarks" class="form-control form-control-sm"><%=_recordBean.getRemarks()%></textarea></div>
						</div>
					</div>
				</div>
				<script>
					setRadioButtonValue(document.formmain["phoneStatus"], "<%=_recordBean.getPhoneStatus()%>");
				</script>

			<%} else if(submitType == SubmitType.BROWSE) {%>
				<input type="hidden" id="phoneID" name="phoneID" value="<%=_recordBean.getPhoneID()%>">
				<div class="row">
					<div class="col-5">
						<div class="row">
							<label class="col-3 col-form-label text-left">Phone Number</label>
							<div class="col-9 form-control-plaintext text-left"><%=_recordBean.getPhoneNumber()%></div>
						</div>
						<div class="row">
							<label class="col-3 col-form-label text-left">Phone Status</label>
							<div class="col-9 form-control-plaintext text-left"><%=RecordStatus.RecordStatus[Integer.parseInt(_recordBean.getPhoneStatus())]%></div>
						</div>
						<div class="row">
							<label class="col-3 col-form-label text-left">Serial Number</label>
							<div class="col-9 form-control-plaintext text-left"><%=_recordBean.getSerialNumber()%></div>
						</div>
						<div class="row">
							<label class="col-3 col-form-label text-left">Validity</label>
							<div class="col-9 form-control-plaintext text-left"><%=_recordBean.getValidity()%></div>
						</div>
						<div class="row">
							<label class="col-3 col-form-label text-left">Audited</label>
							<div class="col-9 form-control-plaintext text-left"><%=_recordBean.getAuditedBy().length() > 0 ? (_recordBean.getAuditedBy()+" on "+_recordBean.getAuditedDate()) : ""%></div>
						</div>
						<%if(_recordBean.getRemarks().length() > 0) {%>
						<div class="row">
							<label class="col-3 col-form-label text-left">Remarks</label>
							<div class="col-9 form-control-plaintext text-left"><%=_recordBean.getRemarks()%></div>
						</div>
						<%}%>
					</div>

					<div class="col-2"></div>

					<div class="col-5">
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
						<button class="btn btn-success text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.CREATE_CONFIRM%>','<%=_recordBean.getController()%>','<%=_recordBean.getPhoneID()%>');">Save</button>
						<!--button class="btn btn-success text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.CREATE_CONFIRM%>','<%=_recordBean.getController()%>','<%=_recordBean.getPhoneID()%>','2');">Save & Post</button --></div>
					<%} else {%>
						<button class="btn btn-success text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.UPDATE_CONFIRM%>','<%=_recordBean.getController()%>','<%=_recordBean.getPhoneID()%>');">Save</button>
						<!--button class="btn btn-success text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.UPDATE_CONFIRM%>','<%=_recordBean.getController()%>','<%=_recordBean.getPhoneID()%>','2');">Save & Post</button --></div>
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
					<button class="btn btn-primary text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.UPDATE%>','<%=_recordBean.getController()%>','<%=_recordBean.getPhoneID()%>');">Edit</button>
				<%}%>
				</div>
				<div class="col-4 text-right">
				<%if("0".equalsIgnoreCase(_recordBean.getStatus())) {%>
					<button class="btn btn-danger text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.DELETE%>','<%=_recordBean.getController()%>','<%=_recordBean.getPhoneID()%>');">Delete</button>
				<%}%>
				</div>
			</div>
		<%}%>
	</div>
</div>
<%@ include file="includeFooter.jsp"%>