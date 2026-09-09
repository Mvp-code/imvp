<!DOCTYPE html>
<%@ page import="java.util.*, com.util.*"%>
<jsp:useBean id="_errorBean" class="com.beans.ErrorBean" scope="request" />
<jsp:useBean id="_recordBean" class="com.beans.GenericSMS" scope="request" />
<jsp:useBean id="_mainUtil" class="com.util.MainUtil" scope="request" />
<%
int submitType = request.getAttribute("submitType") == null ? SubmitType.CREATE : Integer.parseInt(request.getAttribute("submitType").toString().trim());
String _array[][] = null ;
%>

<script>
function validatePageData(submitType, isValid) {
	if(submitType == <%=SubmitType.CREATE_CONFIRM%>) {
		if(isValid) {
			var mandatoryFieldsArray = new Array();
			mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["station"], "Station");
			mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["message"], "Message");
			var numOfRows = parseInt(document.formmain["numOfRows"].value);
			for(var i=0; i<numOfRows; i++) {
				if(i == 0) {
					mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["employeeID"+i], "Employee");
				}
			}

			isValid = validateMandatoryFieldsInForm(mandatoryFieldsArray, isValid);
		}

	} else if(submitType == <%=SubmitType.UPDATE_CONFIRM%>) {

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

			<input type="hidden" id="recordID" name="recordID" value="<%=_recordBean.getRecordID()%>">
			<div class='card-body m-1 p-1'>
			<%if(submitType == SubmitType.CREATE) {%>
				<div class="container">
					<div class="col-12">
						<div class="row">
							<label class="col-5 col-md-3 required col-form-label text-left">Station</label>
							<div class="col-7 col-md-9 text-left"><select id="station" name="station" class="form-control form-control-sm">
								<option value=""></option>
								<%_array = _mainUtil.getDataArray(_mainUtil.getStation());for(int k=0; k<_array.length; k++) {%><option value="<%=_array[k][0]%>" <%if(_recordBean.getStation().equalsIgnoreCase(_array[k][0]) || _array.length == 1) {%>selected<%}%>><%=_array[k][1]%></option><%}%>
							</select></div>
						</div>
						<div class="row">
							<label class="col-5 col-md-3 required col-form-label text-left">Message</label>
							<div class="col-7 col-md-9 text-left"><textarea id="message" name="message" class="form-control form-control-sm"></textarea></div>
						</div>
					</div>
				</div>

				<div class="container pt-3">
					<div class="col-12">
					<table width="100%" border="0" cellpadding="0" cellspacing="0" class="table table-bordered table-striped table-hover table-sm table-block table-vertical sortable mb-0">
						<input type="hidden" id="numOfRows" name="numOfRows" value="10">
						<input type="hidden" id="dynamicParams" name="dynamicParams" value="employeeID,comments">
						<thead class="thead-block">
							<tr class="tr-block">
								<th class="th-block table-header-label text-center required" width="100%">Employee</th>
							</tr>
						</thead>
						<tbody class="tbody-block">
							<%for(int i=0; i<10; i++) {%>
							<tr class="tr-block">
								<td class="td-block table-value" data-th="Employee"><select id="employeeID<%=i%>" name="employeeID<%=i%>" class="form-control form-control-sm"></select></td>
							</tr>
							<script>
								initSelect2Suggestor("employees", "employeeID<%=i%>", "", false, "");
							</script>
							<%}%>
						</tbody>
					</table>
					</div>
				</div>

			<%} else if(submitType == SubmitType.UPDATE) {%>


			<%} else if(submitType == SubmitType.BROWSE) {%>
				<div class="row">
					<div class="col-12">
						<div class="row">
							<label class="col-5 col-md-3 col-form-label text-left">Date</label>
							<div class="col-7 col-md-9 form-control-plaintext text-left"><%=_recordBean.getCreateDate()%></div>
						</div>
						<div class="row">
							<label class="col-5 col-md-3 col-form-label text-left">Station</label>
							<div class="col-7 col-md-9 form-control-plaintext text-left"><%=_recordBean.getStation()%></div>
						</div>
						<div class="row">
							<label class="col-5 col-md-3 col-form-label text-left">Message</label>
							<div class="col-7 col-md-9 form-control-plaintext text-left"><%=_recordBean.getMessage()%></div>
						</div>
					</div>

					<div class="col-12 col-md-3"></div>
					<div class="col-12 col-md-6">
						<div class='card'>
							<div class='card-header table-title-header m-0 py-2'>
								<div class="row">
									<div class="col-12 col-md-2"></div>
									<div class="col-12 col-md-8">Details</div>
									<div class="col-12 col-md-2 text-right my-auto"></div>
								</div>
							</div>

							<div class='card-body m-1 p-1'>
								<table width="100%" border="0" cellpadding="0" cellspacing="0" class="table table-bordered table-striped table-hover table-sm table-block table-vertical sortable mb-0">
									<tbody class="tbody-block">
									<%for(int i=0; i<_recordBean.getTransList().size(); i++) {
										List tempList = (ArrayList) _recordBean.getTransList().get(i);
										String empName = tempList.get(2) == null ? "" : tempList.get(2).toString().trim();
										String messageType = tempList.get(3) == null ? "" : tempList.get(3).toString().trim();
										String messageStatus = tempList.get(4) == null ? "" : tempList.get(4).toString().trim();
										%>
										<tr class="tr-block">
											<td class="td-block table-value" data-th="Name" width="80%"><%=empName%></td>
											<td class="td-block table-value" data-th="Option" width="20%"><%=messageStatus.replaceAll("queued", "Sent")%></td>
										</tr>
									<%}%>
									</tbody>
								</table>
							</div>
						</div>
					</div>
					<div class="col-12 col-md-3"></div>
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
					<%if(submitType == SubmitType.CREATE) {
						if(_recordBean.isDisplaySMSBtn()) {%>
							<button class="btn btn-success text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.CREATE_CONFIRM%>','<%=_recordBean.getController()%>','<%=_recordBean.getRecordID()%>','2');">Save & SMS</button></div>
						<%} else {%>
							<button class="btn btn-success text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.CREATE_CONFIRM%>','<%=_recordBean.getController()%>','<%=_recordBean.getRecordID()%>');">Save</button>
						<%}
					} else {%>

					<%}%>
				<div class="col-4 text-right"></div>
			</div>

		<%} else if(submitType == SubmitType.BROWSE) {%>
			<div class="row mt-4">
				<div class="col-4 text-left">
					<button class="btn btn-secondary text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.SEARCH%>','<%=_recordBean.getController()%>','');">Back to search</button>
				</div>
				<div class="col-4 text-center">
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
