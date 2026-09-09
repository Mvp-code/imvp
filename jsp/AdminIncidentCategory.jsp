<!DOCTYPE html>
<%@ page import="java.util.*, com.util.*"%>
<jsp:useBean id="_errorBean" class="com.beans.ErrorBean" scope="request" />
<jsp:useBean id="_recordBean" class="com.beans.AdminIncidentCategory" scope="request" />
<%
int submitType = request.getAttribute("submitType") == null ? SubmitType.CREATE : Integer.parseInt(request.getAttribute("submitType").toString().trim());
%>

<script>
function validatePageData(submitType, isValid) {

	if(submitType == <%=SubmitType.CREATE_CONFIRM%>) {
		if(isValid) {
			var mandatoryFieldsArray = new Array();
			var numOfRows = parseInt(document.formmain["numOfRows"].value);
			for(var i=0; i<numOfRows; i++) {
				if(i == 0) {
					mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["categoryName"+i], "Category");
				}
			}
			isValid = validateMandatoryFieldsInForm(mandatoryFieldsArray, isValid);
		}

	} else if(submitType == <%=SubmitType.UPDATE_CONFIRM%>) {
		if(isValid) {
			var mandatoryFieldsArray = new Array();
			mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["categoryName"], "Category");
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
			<input type="hidden" id="incidentCategoryID" name="incidentCategoryID" value="<%=_recordBean.getIncidentCategoryID()%>">
			<%if(submitType == SubmitType.CREATE) {%>
				<input type="hidden" id="dynamicParams" name="dynamicParams" value="categoryName">
				<div class="row">
					<div class="col-12 col-md-1"></div>
					<div class="col-12 col-md-10">
						<div class='card'>
							<div class='card-body m-1 p-1'>
								<table width="100%" border="0" cellpadding="0" cellspacing="0" class="table table-bordered table-striped table-hover table-sm table-block table-vertical sortable mb-0">
									<input type="hidden" id="numOfRows" name="numOfRows" value="10">
									<thead class="thead-block">
										<tr class="tr-block">
											<th class="th-block table-header-label text-center required" width="100%">Category</th>
										</tr>
									</thead>
									<tbody class="tbody-block">
										<%for(int i=0; i<10; i++) {%>
										<tr class="tr-block">
											<td class="td-block table-value" data-th="Category"><textarea id="categoryName<%=i%>" name="categoryName<%=i%>" class="form-control form-control-sm" rows="1"></textarea></td>
										</tr>
										<%}%>
									</tbody>
								</table>
							</div>
						</div>
					</div>
					<div class="col-12 col-md-1"></div>
				</div>

			<%} else if(submitType == SubmitType.UPDATE) {%>
				<div class="row">
					<div class="col-12">
						<div class="row form-row form-group form-group-sm">
							<label class="col-12 col-md-3 col-form-label text-left">Category</label>
							<div class="col-12 col-md-9 text-left"><textarea id="categoryName" name="categoryName" class="form-control form-control-sm"><%=_recordBean.getCategoryName()%></textarea></div>
						</div>
					</div>
				</div>

			<%} else if(submitType == SubmitType.BROWSE) {%>
				<div class="row">
					<div class="col-12 col-md-5">
						<div class="row">
							<label class="col-5 col-md-3 col-form-label text-left">Category</label>
							<div class="col-7 col-md-9 form-control-plaintext text-left"><%=_recordBean.getCategoryName()%></div>
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
						<button class="btn btn-success text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.CREATE_CONFIRM%>','<%=_recordBean.getController()%>','<%=_recordBean.getIncidentCategoryID()%>');">Save</button>
					<%} else {%>
						<button class="btn btn-success text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.UPDATE_CONFIRM%>','<%=_recordBean.getController()%>','<%=_recordBean.getIncidentCategoryID()%>');">Save</button>
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
					<button class="btn btn-primary text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.UPDATE%>','<%=_recordBean.getController()%>','<%=_recordBean.getIncidentCategoryID()%>');">Edit</button>
				<%}%>
				</div>
				<div class="col-4 text-right">
				<%if("0".equalsIgnoreCase(_recordBean.getStatus())) {%>
					<button class="btn btn-danger text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.DELETE%>','<%=_recordBean.getController()%>','<%=_recordBean.getIncidentCategoryID()%>');">Delete</button>
				<%}%>
				</div>
			</div>
		<%}%>
	</div>
</div>
<%@ include file="includeFooter.jsp"%>