<!DOCTYPE html>
<%@ page import="java.util.*, com.util.*, com.beans.AdminPhones"%>
<jsp:useBean id="_errorBean" class="com.beans.ErrorBean" scope="request" />
<jsp:useBean id="_recordBean" class="com.beans.AdminPhones" scope="request" />
<%
int submitType = request.getAttribute("submitType") == null ? SubmitType.CREATE : Integer.parseInt(request.getAttribute("submitType").toString().trim());
String _cs = _recordBean.getCurrentStatus() == null || _recordBean.getCurrentStatus().trim().length() == 0 ? "0" : _recordBean.getCurrentStatus().trim();
String _ps = _recordBean.getPhoneStatus() == null || _recordBean.getPhoneStatus().trim().length() == 0 ? "0" : _recordBean.getPhoneStatus().trim();
%>

<script>
function validatePageData(submitType, isValid) {

	if(submitType == <%=SubmitType.CREATE_CONFIRM%> || submitType == <%=SubmitType.UPDATE_CONFIRM%>) {
		if(isValid) {
			var mandatoryFieldsArray = new Array();
			mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["phoneNumber"], "Phone Number");
			if(document.formmain["phoneStatus"] && document.formmain["phoneStatus"].value == "4") {
				mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["remarks"], "Notes");
			}
			var cs = document.formmain["currentStatus"] ? document.formmain["currentStatus"].value : "0";
			if(cs == "2" || cs == "3") {
				mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["remarks"], "Notes");
			}
			mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["serialNumber"], "IMEI 1");
			mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["contractEndDate"], "Contract End Date");
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
						<div class="row">
							<label class="col-3 col-form-label text-left">Current Status</label>
							<div class="col-9 text-left">
								<div class="form-check-inline">
									<label class="form-check-label"><input type="radio" class="form-check-input" name="currentStatus" value="0" checked>In Use</label>
								</div>
								<div class="form-check-inline">
									<label class="form-check-label"><input type="radio" class="form-check-input" name="currentStatus" value="1">Not Used</label>
								</div>
								<div class="form-check-inline">
									<label class="form-check-label"><input type="radio" class="form-check-input" name="currentStatus" value="2">Damaged</label>
								</div>
								<div class="form-check-inline">
									<label class="form-check-label"><input type="radio" class="form-check-input" name="currentStatus" value="3">Lost</label>
								</div>
							</div>
						</div>
						<div class="row form-row form-group form-group-sm">
							<label class="col-3 col-form-label required text-left">IMEI 1</label>
							<div class="col-9 text-left"><input type="text" id="serialNumber" name="serialNumber" class="form-control form-control-sm" value="<%=_recordBean.getSerialNumber()%>"></div>
						</div>
						<div class="row form-row form-group form-group-sm">
							<label class="col-3 col-form-label text-left">IMEI 2</label>
							<div class="col-9 text-left"><input type="text" id="imei2" name="imei2" class="form-control form-control-sm" value="<%=_recordBean.getImei2()%>"></div>
						</div>
						<div class="row form-row form-group form-group-sm">
							<label class="col-3 col-form-label text-left">Make</label>
							<div class="col-9 text-left"><input type="text" id="deviceMake" name="deviceMake" class="form-control form-control-sm" value="<%=_recordBean.getDeviceMake()%>"></div>
						</div>
						<div class="row form-row form-group form-group-sm">
							<label class="col-3 col-form-label text-left">Model</label>
							<div class="col-9 text-left"><input type="text" id="deviceModel" name="deviceModel" class="form-control form-control-sm" value="<%=_recordBean.getDeviceModel()%>"></div>
						</div>
						<div class="row form-row form-group form-group-sm">
							<label class="col-3 col-form-label text-left">IMSI</label>
							<div class="col-9 text-left"><input type="text" id="imsi" name="imsi" class="form-control form-control-sm" value="<%=_recordBean.getImsi()%>"></div>
						</div>
						<div class="row form-row form-group form-group-sm">
							<label class="col-3 col-form-label text-left">ICCID</label>
							<div class="col-9 text-left"><input type="text" id="iccid" name="iccid" class="form-control form-control-sm" value="<%=_recordBean.getIccid()%>"></div>
						</div>
						<div class="row form-row form-group form-group-sm">
							<label class="col-3 col-form-label text-left">EID</label>
							<div class="col-9 text-left"><input type="text" id="eid" name="eid" class="form-control form-control-sm" value="<%=_recordBean.getEid()%>"></div>
						</div>
					</div>

					<div class="col-2"></div>

					<div class="col-5">
						<div class="row form-row form-group form-group-sm">
							<label class="col-3 col-form-label required text-left">Contract End Date</label>
							<div class="col-9 text-left"><input type="text" id="contractEndDate" name="contractEndDate" class="form-control form-control-sm datepicker" value="<%=_recordBean.getContractEndDate()%>"></div>
						</div>
						<div class="row form-row form-group form-group-sm">
							<label class="col-3 col-form-label text-left">Contract Start Date</label>
							<div class="col-9 text-left"><input type="text" id="contractStartDate" name="contractStartDate" class="form-control form-control-sm datepicker" value="<%=_recordBean.getContractStartDate()%>"></div>
						</div>
						<div class="row form-row form-group form-group-sm">
							<label class="col-3 col-form-label text-left">Last Audit Date</label>
							<div class="col-9 text-left"><input type="text" id="auditedDate" name="auditedDate" class="form-control form-control-sm datepicker" value="<%=_recordBean.getAuditedDate()%>"></div>
						</div>
						<div class="row form-row form-group form-group-sm">
							<label class="col-3 col-form-label text-left">Device Ordered Date</label>
							<div class="col-9 text-left"><input type="text" id="deviceOrderedDate" name="deviceOrderedDate" class="form-control form-control-sm datepicker" value="<%=_recordBean.getDeviceOrderedDate()%>"></div>
						</div>
						<div class="row form-row form-group form-group-sm">
							<label class="col-3 col-form-label text-left">Ordered IMEI</label>
							<div class="col-9 text-left"><input type="text" id="deviceOrderedImei" name="deviceOrderedImei" class="form-control form-control-sm" value="<%=_recordBean.getDeviceOrderedImei()%>"></div>
						</div>
						<div class="row form-row form-group form-group-sm">
							<label class="col-3 col-form-label text-left">In Use Date</label>
							<div class="col-9 text-left"><input type="text" id="deviceInUseDate" name="deviceInUseDate" class="form-control form-control-sm datepicker" value="<%=_recordBean.getDeviceInUseDate()%>"></div>
						</div>
						<div class="row form-row form-group form-group-sm">
							<label class="col-3 col-form-label text-left">Notes</label>
							<div class="col-9 text-left"><textarea id="remarks" name="remarks" class="form-control form-control-sm"><%=_recordBean.getRemarks()%></textarea></div>
						</div>
					</div>
				</div>
				<script>
					setRadioButtonValue(document.formmain["phoneStatus"], "<%=_ps%>");
					setRadioButtonValue(document.formmain["currentStatus"], "<%=_cs%>");
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
							<div class="col-9 form-control-plaintext text-left"><%=RecordStatus.RecordStatus[Integer.parseInt(_ps)]%></div>
						</div>
						<div class="row">
							<label class="col-3 col-form-label text-left">Current Status</label>
							<div class="col-9 form-control-plaintext text-left"><%=AdminPhones.currentStatusLabel(_cs)%></div>
						</div>
						<div class="row">
							<label class="col-3 col-form-label text-left">IMEI 1</label>
							<div class="col-9 form-control-plaintext text-left"><%=_recordBean.getSerialNumber()%></div>
						</div>
						<div class="row">
							<label class="col-3 col-form-label text-left">IMEI 2</label>
							<div class="col-9 form-control-plaintext text-left"><%=_recordBean.getImei2()%></div>
						</div>
						<div class="row">
							<label class="col-3 col-form-label text-left">Make / Model</label>
							<div class="col-9 form-control-plaintext text-left"><%=((_recordBean.getDeviceMake()+" "+_recordBean.getDeviceModel()).trim())%></div>
						</div>
						<div class="row">
							<label class="col-3 col-form-label text-left">IMSI</label>
							<div class="col-9 form-control-plaintext text-left"><%=_recordBean.getImsi()%></div>
						</div>
						<div class="row">
							<label class="col-3 col-form-label text-left">ICCID</label>
							<div class="col-9 form-control-plaintext text-left"><%=_recordBean.getIccid()%></div>
						</div>
						<div class="row">
							<label class="col-3 col-form-label text-left">EID</label>
							<div class="col-9 form-control-plaintext text-left"><%=_recordBean.getEid()%></div>
						</div>
					</div>

					<div class="col-2"></div>

					<div class="col-5">
						<div class="row">
							<label class="col-3 col-form-label text-left">Contract End Date</label>
							<div class="col-9 form-control-plaintext text-left"><%=_recordBean.getContractEndDate()%></div>
						</div>
						<div class="row">
							<label class="col-3 col-form-label text-left">Contract Start Date</label>
							<div class="col-9 form-control-plaintext text-left"><%=_recordBean.getContractStartDate()%></div>
						</div>
						<div class="row">
							<label class="col-3 col-form-label text-left">Last Audit Date</label>
							<div class="col-9 form-control-plaintext text-left"><%=_recordBean.getAuditedDate()%></div>
						</div>
						<div class="row">
							<label class="col-3 col-form-label text-left">Device Ordered Date</label>
							<div class="col-9 form-control-plaintext text-left"><%=_recordBean.getDeviceOrderedDate()%></div>
						</div>
						<div class="row">
							<label class="col-3 col-form-label text-left">Ordered IMEI</label>
							<div class="col-9 form-control-plaintext text-left"><%=_recordBean.getDeviceOrderedImei()%></div>
						</div>
						<div class="row">
							<label class="col-3 col-form-label text-left">In Use Date</label>
							<div class="col-9 form-control-plaintext text-left"><%=_recordBean.getDeviceInUseDate()%></div>
						</div>
						<%if(_recordBean.getRemarks().length() > 0) {%>
						<div class="row">
							<label class="col-3 col-form-label text-left">Notes</label>
							<div class="col-9 form-control-plaintext text-left"><%=_recordBean.getRemarks()%></div>
						</div>
						<%}%>
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
						</div>
					<%} else {%>
						<button class="btn btn-success text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.UPDATE_CONFIRM%>','<%=_recordBean.getController()%>','<%=_recordBean.getPhoneID()%>');">Save</button>
						</div>
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
