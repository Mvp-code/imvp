<!DOCTYPE html>
<%@ page import="java.util.*, com.util.*"%>
<jsp:useBean id="_errorBean" class="com.beans.ErrorBean" scope="request" />
<jsp:useBean id="_recordBean" class="com.beans.VehicleInspection" scope="request" />
<jsp:useBean id="_mainUtil" class="com.util.MainUtil" scope="request" />
<%
int submitType = request.getAttribute("submitType") == null ? SubmitType.CREATE : Integer.parseInt(request.getAttribute("submitType").toString().trim());
String _array[][] = null ;
%>

<script>
function validatePageData(submitType, isValid) {

	if(submitType == <%=SubmitType.CREATE_CONFIRM%> || submitType == <%=SubmitType.UPDATE_CONFIRM%>) {
		if(isValid) {
			var mandatoryFieldsArray = new Array();
			mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["inspectionDate"], "Date");
			mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["vehicleID"], "Vehicle");
			<%for(int i=0; i<_recordBean.getTransArray().length; i++) {
				String displayName = _recordBean.getTransArray()[i][0];%>
				mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["transValue<%=i%>"], "<%=displayName%>");
			<%}%>
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
					<div class="col-2 text-right my-auto"></div>
				</div>
			</div>

			<%if(_errorBean != null && _errorBean.getType().length() > 0) {%>
				<div class="row text-center"><section class='alert_section'><div class='alert-box <%=_errorBean.getType()%>Color'><%=_errorBean.getMesg()%></div></section></div>
			<%}%>

			<div class='card-body m-1 p-1'>
			<input type="hidden" id="vehicleInspectionID" name="vehicleInspectionID" value="<%=_recordBean.getVehicleInspectionID()%>">
			<%if(submitType == SubmitType.CREATE || submitType == SubmitType.UPDATE) {%>
				<div class="row">
					<div class="col-12 col-md-5">
						<div class="row form-row form-group form-group-sm">
							<label class="col-12 col-md-3 col-form-label required text-left">Date</label>
							<div class="col-12 col-md-9 text-left"><input type="text" id="inspectionDate" name="inspectionDate" class="form-control form-control-sm datepicker" value="<%=_recordBean.getInspectionDate()%>"></div>
						</div>
						<div class="row form-row form-group form-group-sm">
							<label class="col-12 col-md-3 col-form-label required text-left">Vehicle</label>
							<div class="col-12 col-md-9 text-left"><select id="vehicleID" name="vehicleID" class="form-control form-control-sm">
							<option value=""></option>
							<%for(int i=0; i<_recordBean.getDaCheckoutList().size(); i++) {
							List tempList = (ArrayList) _recordBean.getDaCheckoutList().get(i);
							%><option value="<%=tempList.get(0).toString()%>" <%if(_recordBean.getVehicleID().equalsIgnoreCase(tempList.get(0).toString())) {%>selected<%}%>><%=tempList.get(1).toString()%></option><%}%>
							</select></div>
						</div>
						<div class="row form-row form-group form-group-sm">
							<label class="col-12 col-md-3 col-form-label text-left">DA Remarks</label>
							<div class="col-12 col-md-9 text-left"><textarea id="daComments" name="daComments" class="form-control form-control-sm"><%=_recordBean.getDaComments()%></textarea></div>
						</div>
					</div>

					<div class="col-12 col-md-2"></div>

					<div class="col-12 col-md-5">
						<%if(submitType == SubmitType.UPDATE) {%>
						<div class="row form-row form-group form-group-sm">
							<label class="col-12 col-md-3 col-form-label text-left">Parking</label>
							<div class="col-12 col-md-9 text-left"><select id="parking" name="parking" class="form-control form-control-sm"><option value=""></option><%_array = _mainUtil.getDataArray(_mainUtil.getParking());for(int k=0; k<_array.length; k++) {%><option value="<%=_array[k][0]%>"><%=_array[k][1]%></option><%}%></select></div>

							<script>setSelectBoxValue(document.formmain["parking"], "<%=_recordBean.getParking()%>");</script>
						</div>
						<%}%>

						<div class="row form-row form-group form-group-sm">
							<label class="col-12 col-md-3 col-form-label text-left">Dispatcher Remarks</label>
							<div class="col-12 col-md-9 text-left"><textarea id="dispatcherComments" name="dispatcherComments" class="form-control form-control-sm"><%=_recordBean.getDispatcherComments()%></textarea></div>
						</div>
						<div class="row form-row form-group form-group-sm">
							<label class="col-12 col-md-3 col-form-label text-left">Ground By Dispatcher</label>
							<div class="col-12 col-md-9 text-left"><textarea id="groundByDispatcher" name="groundByDispatcher" class="form-control form-control-sm"><%=_recordBean.getGroundByDispatcher()%></textarea></div>
						</div>
					</div>

					<div class="col-12 col-md-2"></div>
					<div class="col-12 col-md-8">
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
									<input type="hidden" id="numOfRows" name="numOfRows" value="<%=_recordBean.getTransArray().length%>">
									<input type="hidden" id="dynamicParams" name="dynamicParams" value="transName,transValue,transComments">
									<%for(int i=0; i<_recordBean.getTransArray().length; i++) {
										String displayName = _recordBean.getTransArray()[i][0];
										String splitArray[] = _recordBean.getTransArray()[i][1].split("#");
										String transName = "", transValue = "", transComments = "";
										if(i < _recordBean.getTransList().size()) {
											List tempList = (ArrayList) _recordBean.getTransList().get(i);
											transName = tempList.get(1) == null ? "" : tempList.get(1).toString().trim();
											if(displayName.equalsIgnoreCase(transName)) {
												transValue = tempList.get(2) == null ? "" : tempList.get(2).toString().trim();
												transComments = tempList.get(3) == null ? "" : tempList.get(3).toString().trim();
											}
										} else {
											transValue = "0";
										}
										%>
										<tr class="tr-block">
											<input type="hidden" id="transName<%=i%>" name="transName<%=i%>" value="<%=displayName%>">
											<td class="td-block table-value" data-th="Name" width="25%"><%=_recordBean.getTransArray()[i][0]%></td>
											<td class="td-block table-value" data-th="Option" width="15%">
											<%for(int j=0; j<splitArray.length; j++) {%>
												<div class="form-check-inline">
													<label class="form-check-label"><input type="radio" class="form-check-input" id="transValue<%=i%>" name="transValue<%=i%>" value="<%=j%>"><%=splitArray[j]%></label>
												</div>
											<%}%>
											</td>
											<td class="td-block table-value" data-th="Comments" width="60%"><textarea id="transComments<%=i%>" name="transComments<%=i%>" class="form-control form-control-sm" rows="1"><%=transComments%></textarea></td>
										</tr>
										<script>
											setRadioButtonValue(document.formmain["transValue<%=i%>"], "<%=transValue%>");
										</script>
									<%}%>
									</tbody>
								</table>
							</div>
						</div>
					</div>
					<div class="col-12 col-md-2"></div>
				</div>


			<%} else if(submitType == SubmitType.BROWSE) {%>
				<div class="row">
					<div class="col-12 col-md-5">
						<div class="row">
							<label class="col-5 col-md-3 col-form-label text-left">Date</label>
							<div class="col-7 col-md-9 form-control-plaintext text-left"><%=_recordBean.getInspectionDate()%></div>
						</div>
						<div class="row">
							<label class="col-5 col-md-3 col-form-label text-left">Vehicle</label>
							<div class="col-7 col-md-9 form-control-plaintext text-left"><%=_recordBean.getVehicleName()%></div>
						</div>
						<div class="row">
							<label class="col-5 col-md-3 col-form-label text-left">Employee</label>
							<div class="col-7 col-md-9 form-control-plaintext text-left"><%=_recordBean.getEmployeeName()%></div>
						</div>
						<div class="row">
							<label class="col-5 col-md-3 col-form-label text-left">DA Remarks</label>
							<div class="col-7 col-md-9 form-control-plaintext text-left"><%=_recordBean.getDaComments()%></div>
						</div>
					</div>

					<div class="col-12 col-md-2"></div>

					<div class="col-12 col-md-5">
						<div class="row">
							<label class="col-5 col-md-3 col-form-label text-left">Parking</label>
							<div class="col-7 col-md-9 form-control-plaintext text-left"><%=_mainUtil.getParking().get(_recordBean.getParking())  == null ? "" : _mainUtil.getParking().get(_recordBean.getParking())%></div>
						</div>
						<div class="row">
							<label class="col-5 col-md-3 col-form-label text-left">Dispatch Remarks</label>
							<div class="col-7 col-md-9 form-control-plaintext text-left"><%=_recordBean.getDispatcherComments()%></div>
						</div>
						<div class="row">
							<label class="col-5 col-md-3 col-form-label text-left">Ground by Dispatcher</label>
							<div class="col-7 col-md-9 form-control-plaintext text-left"><%=_recordBean.getGroundByDispatcher()%></div>
						</div>
					</div>

					<div class="col-12 col-md-2"></div>
					<div class="col-12 col-md-8">
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
									<%for(int i=0; i<_recordBean.getTransArray().length; i++) {
										String displayName = _recordBean.getTransArray()[i][0];
										String splitArray[] = _recordBean.getTransArray()[i][1].split("#");
										String transName = "", transValue = "", transComments = "";
										if(i < _recordBean.getTransList().size()) {
											List tempList = (ArrayList) _recordBean.getTransList().get(i);
											transName = tempList.get(1) == null ? "" : tempList.get(1).toString().trim();
											if(displayName.equalsIgnoreCase(transName)) {
												transValue = tempList.get(2) == null ? "" : tempList.get(2).toString().trim();
												transComments = tempList.get(3) == null ? "" : tempList.get(3).toString().trim();
												for(int k=0; k<splitArray.length; k++) {
													if(transValue.equalsIgnoreCase(k+"")) {
														transValue = splitArray[k];
														break;
													}
												}
											}
										}%>
										<tr class="tr-block">
											<td class="td-block table-value" data-th="Name" width="25%"><%=transName%></td>
											<td class="td-block table-value" data-th="Option" width="15%"><%=transValue%></td>
											<td class="td-block table-value" data-th="Comments" width="60%"><%=transComments%></td>
										</tr>
									<%}%>
									</tbody>
								</table>
							</div>
						</div>
					</div>
					<div class="col-12 col-md-2"></div>

					<%if(_recordBean.getUploadsList().size() > 0) {%>
					<div class="col-12 col-md-2"></div>
					<div class="col-12 col-md-8 py-3">
						<div class='card'>
							<div class='card-header table-title-header m-0 py-2'>
								<div class="row">
									<div class="col-12 col-md-2"></div>
									<div class="col-12 col-md-8">Uploads</div>
									<div class="col-12 col-md-2 text-right my-auto"></div>
								</div>
							</div>

							<div class='card-body m-1 p-1'>
								<table width="100%" border="0" cellpadding="0" cellspacing="0" class="table table-bordered table-striped table-hover table-sm table-block table-vertical sortable mb-0">
									<thead class="thead-block">
										<tr class="tr-block">
											<th class="th-block table-header-label text-center required" width="15%">Name</th>
											<th class="th-block table-header-label text-center required" width="15%">Type</th>
											<th class="th-block table-header-label text-center required" width="30%">Comments</th>
											<th class="th-block table-header-label text-center required" width="30%">Audit</th>
											<th class="th-block table-header-label text-center required" width="10%"></th>
										</tr>
									</thead>
									<tbody class="tbody-block">
									<%for(int i=0; i<_recordBean.getUploadsList().size(); i++) {
										List tempList = (ArrayList) _recordBean.getUploadsList().get(i);
										String id = tempList.get(0) == null ? "" : tempList.get(0).toString().trim();
										String blobName = tempList.get(1) == null ? "" : tempList.get(1).toString().trim();
										String type = tempList.get(2) == null ? "" : tempList.get(2).toString().trim();
										String comments = tempList.get(3) == null ? "" : tempList.get(3).toString().trim();
										String createUser = tempList.get(4) == null ? "" : tempList.get(4).toString().trim();
										String createDate = tempList.get(5) == null ? "" : tempList.get(5).toString().trim();%>
										<tr class="tr-block">
											<td class="td-block table-value" data-th="Name"><%=blobName%></td>
											<td class="td-block table-value" data-th="Type"><%=type%></td>
											<td class="td-block table-value" data-th="Comments"><%=comments%></td>
											<td class="td-block table-value" data-th="Audit"><%=createUser+" on "+createDate%></td>
											<td class="td-block table-value" data-th="">
												<a title="View" href="Javascript:viewUploadRecord('<%=id%>')"><i class="fa fa-eye" aria-hidden="true"></i></a>
												<%if("0".equalsIgnoreCase(_recordBean.getStatus())) {%>
												<a title="Delete"  href="Javascript:deleteUploadRecord('<%=id%>')"><i class="fa fa-trash" aria-hidden="true"></i></a>
												<%}%>
											</td>
										</tr>
									<%}%>
									</tbody>
								</table>
							</div>
						</div>
					</div>
					<div class="col-12 col-md-2"></div>
					<%}%>
				</div>
			<%}%>
			</div>
		</div>

		<%if(submitType == SubmitType.CREATE || submitType == SubmitType.UPDATE) {%>
			<div class="row mt-4">
				<div class="col-4 text-left">
					<%if(!"4".equalsIgnoreCase(loginUserRoles)) {%><button class="btn btn-secondary text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.SEARCH%>','<%=_recordBean.getController()%>','');">Back to search</button><%}%>
				</div>
				<div class="col-4 text-center">
					<%if(submitType == SubmitType.CREATE) {%>
						<button class="btn btn-success text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.CREATE_CONFIRM%>','<%=_recordBean.getController()%>','<%=_recordBean.getVehicleInspectionID()%>');">Save</button>
						<%if(!"4".equalsIgnoreCase(loginUserRoles)) {%>
						<button class="btn btn-success text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.CREATE_CONFIRM%>','<%=_recordBean.getController()%>','<%=_recordBean.getVehicleInspectionID()%>','2');">Save & Post</button></div><%}%>
					<%} else {%>
						<button class="btn btn-success text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.UPDATE_CONFIRM%>','<%=_recordBean.getController()%>','<%=_recordBean.getVehicleInspectionID()%>');">Save</button>
						<%if(!"4".equalsIgnoreCase(loginUserRoles)) {%>
						<button class="btn btn-success text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.UPDATE_CONFIRM%>','<%=_recordBean.getController()%>','<%=_recordBean.getVehicleInspectionID()%>','2');">Save & Post</button></div><%}%>
					<%}%>
				<div class="col-4 text-right"></div>
			</div>

		<%} else if(submitType == SubmitType.BROWSE) {%>
			<div class="row mt-4">
				<div class="col-4 text-left">
					<%if(!"4".equalsIgnoreCase(loginUserRoles)) {%>
					<button class="btn btn-secondary text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.SEARCH%>','<%=_recordBean.getController()%>','');">Back to search</button><%}%>
				</div>
				<div class="col-4 text-center">
				<%if("0".equalsIgnoreCase(_recordBean.getStatus())) {%>
					<button class="btn btn-primary text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.UPDATE%>','<%=_recordBean.getController()%>','<%=_recordBean.getVehicleInspectionID()%>');">Edit</button>
				<%}%>
				</div>
				<div class="col-4 text-right">
				<%if("0".equalsIgnoreCase(_recordBean.getStatus()) && !"4".equalsIgnoreCase(loginUserRoles)) {%>
					<button class="btn btn-danger text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.DELETE%>','<%=_recordBean.getController()%>','<%=_recordBean.getVehicleInspectionID()%>');">Delete</button>
				<%}%>
				</div>
			</div>
		<%}%>
	</div>
</div>
<%@ include file="includeFooter.jsp"%>