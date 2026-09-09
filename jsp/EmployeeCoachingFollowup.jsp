<!DOCTYPE html>
<%@ page import="java.util.*, com.util.*"%>
<jsp:useBean id="_errorBean" class="com.beans.ErrorBean" scope="request" />
<jsp:useBean id="_recordBean" class="com.beans.EmployeeCoachingFollowup" scope="request" />
<%
int submitType = request.getAttribute("submitType") == null ? SubmitType.CREATE : Integer.parseInt(request.getAttribute("submitType").toString().trim());
%>

<script>
function validatePageData(submitType, isValid) {

	if(submitType == <%=SubmitType.CREATE_CONFIRM%>) {

	} else if(submitType == <%=SubmitType.UPDATE_CONFIRM%>) {
		if(isValid) {
			var mandatoryFieldsArray = new Array();
			mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["employeeID"], "Employee");
			mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["dateOfTermination"], "Date");
			mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["terminationType"], "Type");
			mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["terminationReason"], "Reason");
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
			<input type="hidden" id="employeeCoachingFollowupID" name="employeeCoachingFollowupID" value="<%=_recordBean.getEmployeeCoachingFollowupID()%>">
			<%if(submitType == SubmitType.CREATE) {%>

			<%} else if(submitType == SubmitType.UPDATE) {%>
				<input type="hidden" id="numOfRows" name="numOfRows" value="<%=_recordBean.getTransList().size()%>">
				<input type="hidden" id="dynamicParams" name="dynamicParams" value="followupTransID,followupStatus,followupComments">

				<div class="row">
					<div class="col-12 col-md-3"></div>
					<div class="col-12 col-md-6">
						<div class='card'>
							<div class='card-body m-1 p-1'>
								<table width="100%" border="0" cellpadding="0" cellspacing="0" class="table table-bordered table-striped table-hover table-sm table-block table-vertical sortable mb-0">
									<thead class="thead-block">
										<tr class="tr-block">
											<th class="th-block table-header-label text-center" width="80%">Employee</th>
											<th class="th-block table-header-label text-center" width="10%">Year</th>
											<th class="th-block table-header-label text-center" width="10%">Week</th>
										</tr>
									</thead>
									<tbody class="tbody-block">
										<tr class="tr-block">
											<td class="td-block table-value" data-th="Employee"><%=_recordBean.getDeliveryAssociate()%></td>
											<td class="td-block table-value" data-th="Year"><%=_recordBean.getDeliveryYear()%></td>
											<td class="td-block table-value" data-th="Week"><%=_recordBean.getDeliveryWeek()%></td>
										</tr>
									</tbody>
								</table>
							</div>
						</div>
					</div>
					<div class="col-12 col-md-3"></div>
				</div>

				<div class="row my-3">
					<div class="col-12 col-md-1"></div>
					<div class="col-12 col-md-10">
						<div class='card'>
							<div class='card-body m-1 p-1'>
								<table width="100%" border="0" cellpadding="0" cellspacing="0" class="table table-bordered table-striped table-hover table-sm table-block table-vertical sortable mb-0">
									<thead class="thead-block">
										<tr class="tr-block">
											<th class="th-block table-header-label text-center" width="10%">Category</th>
											<th class="th-block table-header-label text-center" width="10%">Metric</th>
											<th class="th-block table-header-label text-center" width="15%">Coaching Owner</th>
											<th class="th-block table-header-label text-center" width="10%">Target Date</th>
											<th class="th-block table-header-label text-center" width="15%">Coaching Status</th>
											<th class="th-block table-header-label text-center" width="40%">Description</th>
										</tr>
									</thead>
									<tbody class="tbody-block">
										<%for(int i=0; i<_recordBean.getTransList().size(); i++) {
										List tempList = (ArrayList) _recordBean.getTransList().get(i);%>
										<input type="hidden" id="followupTransID<%=i%>" name="followupTransID<%=i%>" value="<%=tempList.get(0) == null ? "" : tempList.get(0).toString().trim()%>">
										<tr class="tr-block">
											<td class="td-block table-value" data-th="Category"><%=tempList.get(1) == null ? "" : tempList.get(1).toString().trim()%></td>
											<td class="td-block table-value" data-th="Metric"><%=tempList.get(2) == null ? "" : tempList.get(2).toString().trim()%></td>
											<td class="td-block table-value" data-th="Coaching Owner"><%=tempList.get(3) == null ? "" : tempList.get(3).toString().trim()%></td>
											<td class="td-block table-value" data-th="Target Date"><%=tempList.get(4) == null ? "" : tempList.get(4).toString().trim()%></td>
											<td class="td-block table-value" data-th="Coaching Status"><select id="followupStatus<%=i%>" name="followupStatus<%=i%>" class="form-control form-control-sm"><option value="Not started" selected>Not started</option><option value="Inprogress">Inprogress</option><option value="Monitoring">Monitoring</option><option value="No improvement">No improvement</option><option value="Can Improve">Can Improve</option><option value="Improving">Improving</option><option value="Closed">Closed</option></select></td>
											<td class="td-block table-value" data-th="Description"><textarea id="followupComments<%=i%>" name="followupComments<%=i%>" class="form-control form-control-sm" rows="1" maxLength="2000"><%=tempList.get(6) == null ? "" : tempList.get(6).toString().trim()%></textarea></td>
										</tr>

										<script>
											setSelectBoxValue(document.formmain["followupStatus<%=i%>"], "<%=tempList.get(5) == null ? "" : tempList.get(5).toString().trim()%>");
										</script>
										<%}%>
									</tbody>
								</table>
							</div>
						</div>
					</div>
					<div class="col-12 col-md-1"></div>
				</div>

			<%} else if(submitType == SubmitType.BROWSE) {%>
				<script>
				function showHistory(transID) {
					var xmlHttpRequest = setSynXMLHttpOb("../servlet/MVPGServlet");
					var str = "submitType=10&controller=<%=_recordBean.getController()%>&requestType=showTransHx&transID="+transID+getEntityParams();
					xmlHttpRequest.send(str);
					var xmlMessage = xmlHttpRequest.responseXML;

					var htmlContent = '<div class="col-12 m-0 p-0 pb-3">';
						htmlContent += '<div class="row form-row">';
							htmlContent += "<div class='col-12'><div class='card'>";
								htmlContent += "<div class='card-header table-title-header m-0 py-2'>History</div>";
								htmlContent += "<div class='card-body m-1 p-1'>";
									htmlContent += '<table width="100%" border="0" cellpadding="0" cellspacing="0" class="table table-bordered table-striped table-hover table-sm table-block table-vertical sortable mb-0">';
										htmlContent += '<thead class="thead-block">';
											htmlContent += '<tr class="tr-block">';
												htmlContent += '<th class="th-block table-header-label text-center" width="20%">Coaching Status</th>';
												htmlContent += '<th class="th-block table-header-label text-center" width="40%">Description</th>';
												htmlContent += '<th class="th-block table-header-label text-center" width="40%">Audit</th>';
											htmlContent += '</tr>';
										htmlContent += '</thead>';
										htmlContent += '<tbody class="tbody-block">';
										if(xmlMessage.getElementsByTagName("showTransHxDetails")[0] != null) {
											var showTransHx = xmlMessage.getElementsByTagName("showTransHxDetails")[0];
											var len = showTransHx.childNodes.length;
											for(var i=0; i<len; i++) {
												var transXML = showTransHx.getElementsByTagName("showTransHxTrans")[i];
												var coachingStatus = getXMLValue(transXML.getElementsByTagName("coachingStatus")[0]);
												var comments = getXMLValue(transXML.getElementsByTagName("comments")[0]);
												var createUser = getXMLValue(transXML.getElementsByTagName("createUser")[0]);
												var createDate = getXMLValue(transXML.getElementsByTagName("createDate")[0]);
												htmlContent += '<tr class="tr-block">';
													htmlContent += '<td class="td-block table-value" data-th="Coaching Status">'+coachingStatus+'</td>';
													htmlContent += '<td class="td-block table-value" data-th="Description">'+comments+'</td>';
													htmlContent += '<td class="td-block table-value" data-th="Audit">'+createUser+" on "+createDate+'</td>';
												htmlContent += '</tr>';
											}
										}
										htmlContent += '</tbody>';
									htmlContent += '</table>';
								htmlContent += "</div>";
							htmlContent += "</div></div>";
						htmlContent += '</div>';

						htmlContent += '<div class="row form-row my-3">';
							htmlContent += '<div class="row col-12">';
								htmlContent += '<div class="col-4 text-left"></div>';
								htmlContent += '<div class="col-4 text-center"></div>';
								htmlContent += '<div class="col-4 text-right"><button class="btn btn-danger btn-sm text-center" onClick=Javascript:TINY.box.hide();>Close&nbsp;<i class="fa fa-times" aria-hidden="true"></i></button></div>';
							htmlContent += '</div>';
						htmlContent += '</div>';
					htmlContent += '</div>';

					TINY.box.show({
						html:htmlContent,
						fixed:false,
						maskid:'frameless',
						width:800,
						maskopacity:40,
						openjs:function() {
						}
					});
				}
				</script>

				<div class="row">
					<div class="col-12 col-md-3"></div>
					<div class="col-12 col-md-6">
						<div class='card'>
							<div class='card-body m-1 p-1'>
								<table width="100%" border="0" cellpadding="0" cellspacing="0" class="table table-bordered table-striped table-hover table-sm table-block table-vertical sortable mb-0">
									<thead class="thead-block">
										<tr class="tr-block">
											<th class="th-block table-header-label text-center" width="80%">Employee</th>
											<th class="th-block table-header-label text-center" width="10%">Year</th>
											<th class="th-block table-header-label text-center" width="10%">Week</th>
										</tr>
									</thead>
									<tbody class="tbody-block">
										<tr class="tr-block">
											<td class="td-block table-value" data-th="Employee"><%=_recordBean.getDeliveryAssociate()%></td>
											<td class="td-block table-value" data-th="Year"><%=_recordBean.getDeliveryYear()%></td>
											<td class="td-block table-value" data-th="Week"><%=_recordBean.getDeliveryWeek()%></td>
										</tr>
									</tbody>
								</table>
							</div>
						</div>
					</div>
					<div class="col-12 col-md-3"></div>
				</div>

				<div class="row my-3">
					<div class="col-12 col-md-1"></div>
					<div class="col-12 col-md-10">
						<div class='card'>
							<div class='card-body m-1 p-1'>
								<table width="100%" border="0" cellpadding="0" cellspacing="0" class="table table-bordered table-striped table-hover table-sm table-block table-vertical sortable mb-0">
									<thead class="thead-block">
										<tr class="tr-block">
											<th class="th-block table-header-label text-center" width="10%">Category</th>
											<th class="th-block table-header-label text-center" width="10%">Metric</th>
											<th class="th-block table-header-label text-center" width="15%">Coaching Owner</th>
											<th class="th-block table-header-label text-center" width="10%">Target Date</th>
											<th class="th-block table-header-label text-center" width="15%">Coaching Status</th>
											<th class="th-block table-header-label text-center" width="37%">Description</th>
											<th class="th-block table-header-label text-center" width="3%"></th>
										</tr>
									</thead>
									<tbody class="tbody-block">
										<%for(int i=0; i<_recordBean.getTransList().size(); i++) {
										List tempList = (ArrayList) _recordBean.getTransList().get(i);
										String transID = tempList.get(0) == null ? "" : tempList.get(0).toString().trim();
										int statusCNT = Integer.parseInt(tempList.get(10) == null ? "0" : tempList.get(10).toString().trim());%>
										<tr class="tr-block">
											<td class="td-block table-value" data-th="Category"><%=tempList.get(1) == null ? "" : tempList.get(1).toString().trim()%></td>
											<td class="td-block table-value" data-th="Metric"><%=tempList.get(2) == null ? "" : tempList.get(2).toString().trim()%></td>
											<td class="td-block table-value" data-th="Coaching Owner"><%=tempList.get(3) == null ? "" : tempList.get(3).toString().trim()%></td>
											<td class="td-block table-value" data-th="Target Date"><%=tempList.get(4) == null ? "" : tempList.get(4).toString().trim()%></td>
											<td class="td-block table-value" data-th="Coaching Status"><%=tempList.get(5) == null ? "" : tempList.get(5).toString().trim()%></td>
											<td class="td-block table-value" data-th="Description"><%=tempList.get(6) == null ? "" : tempList.get(6).toString().trim()%></td>
											<td class="td-block table-value text-center" data-th="Info"><%if(statusCNT > 0) {%><a href="Javascript:showHistory(<%=transID%>)" TITLE="Audit History"><i class="fa fa-history" aria-hidden="true"></i></a><%}%></td>
										</tr>
										<%}%>
									</tbody>
								</table>
							</div>
						</div>
					</div>
					<div class="col-12 col-md-1"></div>
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
						<button class="btn btn-success text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.CREATE_CONFIRM%>','<%=_recordBean.getController()%>','<%=_recordBean.getEmployeeCoachingFollowupID()%>');">Save</button>
						<!--button class="btn btn-success text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.CREATE_CONFIRM%>','<%=_recordBean.getController()%>','<%=_recordBean.getEmployeeCoachingFollowupID()%>','2');">Save & Post</button-->
					<%} else {%>
						<button class="btn btn-success text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.UPDATE_CONFIRM%>','<%=_recordBean.getController()%>','<%=_recordBean.getEmployeeCoachingFollowupID()%>');">Save</button>
						<!--button class="btn btn-success text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.UPDATE_CONFIRM%>','<%=_recordBean.getController()%>','<%=_recordBean.getEmployeeCoachingFollowupID()%>','2');">Save & Post</button-->
					<%}%>
				</div>
				<div class="col-4 text-right"></div>
			</div>

		<%} else if(submitType == SubmitType.BROWSE) {%>
			<div class="row mt-4">
				<div class="col-4 text-left">
					<button class="btn btn-secondary text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.SEARCH%>','<%=_recordBean.getController()%>','');">Back to search</button>
				</div>
				<div class="col-4 text-center">
				<%if("0".equalsIgnoreCase(_recordBean.getStatus())) {%>
					<button class="btn btn-primary text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.UPDATE%>','<%=_recordBean.getController()%>','<%=_recordBean.getEmployeeCoachingFollowupID()%>');">Edit</button>
					<button class="btn btn-success text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.FINAL%>','<%=_recordBean.getController()%>','<%=_recordBean.getEmployeeCoachingFollowupID()%>');">Post</button>
				<%}%>
				</div>
				<div class="col-4 text-right">
				<%if("0".equalsIgnoreCase(_recordBean.getStatus())) {%>
					<button class="btn btn-danger text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.DELETE%>','<%=_recordBean.getController()%>','<%=_recordBean.getEmployeeCoachingFollowupID()%>');">Delete</button>
				<%}%>
				</div>
			</div>
		<%}%>
	</div>
</div>
<%@ include file="includeFooter.jsp"%>