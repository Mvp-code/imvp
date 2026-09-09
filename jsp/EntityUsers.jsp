<!DOCTYPE html>
<%@ page import="java.util.*, com.util.*"%>
<jsp:useBean id="_errorBean" class="com.beans.ErrorBean" scope="request" />
<jsp:useBean id="_recordBean" class="com.beans.EntityUsers" scope="request" />
<%
int submitType = request.getAttribute("submitType") == null ? SubmitType.CREATE : Integer.parseInt(request.getAttribute("submitType").toString().trim());
%>

<script>
function validatePageData(submitType, isValid) {

	if(submitType == <%=SubmitType.CREATE_CONFIRM%> || submitType == <%=SubmitType.UPDATE_CONFIRM%> || submitType == <%=SubmitType.CHANGE%>) {
		if(isValid) {
			var mandatoryFieldsArray = new Array();
			if(submitType == <%=SubmitType.CREATE_CONFIRM%> || submitType == <%=SubmitType.UPDATE_CONFIRM%>) {
				mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["employeeID"], "Employee");
				mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["userName"], "User Name");
			}
			mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["password"], "Password");
			mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["confirmPwd"], "Confirm Password");
			isValid = validateMandatoryFieldsInForm(mandatoryFieldsArray, isValid);
			if(isValid) {
				var userName = Trim(document.formmain["userName"].value);
				if(userName.length < 6) {
					isValid = false;
					alert("User Name must be minimum 6 characters length");
				}
			}

			if(isValid) {
				var pwd1 = Trim(document.formmain["password"].value);
				var pwd2 = Trim(document.formmain["confirmPwd"].value);
				if(pwd1.length < 6) {
					isValid = false;
					alert("Password must be minimum 6 characters length");
					document.formmain["password"].value = "";
					document.formmain["confirmPwd"].value = "";
					document.formmain["password"].focus();

				} else if(!(pwd1.substr(0, 1).match(/[a-z]|[A-Z]/))) {
					isValid = false;
					alert("Password must start with a letter");
					document.formmain["password"].value = "";
					document.formmain["confirmPwd"].value = "";
					document.formmain["password"].focus();

				} else {
					var containsNumbers = true, containsChars = true, containsSpecialChars = true;
					var specialCharsRegExp = /[~_+=`!@#$%^&*(),.?":{}|<>;'\-\\[\]/]/g;
					if(!(pwd1.match(/\d/)))
						containsNumbers = false;
					if(!(pwd1.match(/[a-z]|[A-Z]/)))
						containsChars = false;
					if(!(pwd1.match(specialCharsRegExp)))
						containsSpecialChars = false;
					if(!(containsNumbers && containsChars && containsSpecialChars)) {
						isValid = false;
						alert("Password must contain at least one character, one number, one special character");
						document.formmain["password"].value = "";
						document.formmain["confirmPwd"].value = "";
						document.formmain["password"].focus();
					}
				}

				if(isValid && pwd1 != pwd2) {
					isValid = false;
					alert("Password and Confirm Password should be same");
					document.formmain["password"].value = "";
					document.formmain["confirmPwd"].value = "";
					document.formmain["password"].focus();
				}
			}

			if(!isValid) {
				if(document.formmain.pageSubmitLock != null)
					document.formmain.pageSubmitLock.value = "unlocked";
			}
		}

	} else if(submitType == <%=SubmitType.DELETE%>) {
		isValid = deleteRecord();
	}

	return isValid;
}
function enabledPwd(thisId) {
	if(document.getElementById(thisId)) {
		if(document.getElementById(thisId).type == "password") {
			document.getElementById(thisId).type = "text";
			document.getElementById(thisId+"SpanID").innerHTML = '<i class="fa fa-eye-slash" aria-hidden="true"></i>';
		} else {
			document.getElementById(thisId).type = "password";
			document.getElementById(thisId+"SpanID").innerHTML = '<i class="fa fa-eye" aria-hidden="true"></i>';
		}
	}
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

				<input type="hidden" id="recordID" name="recordID" value="<%=_recordBean.getRecordID()%>">
				<div class="row">
					<div class="col-3">
					</div>

					<div class="col-6">
						<div class="row form-row form-group form-group-sm">
							<%if(submitType == SubmitType.CREATE) {%>
								<label class="col-3 col-form-label required text-left">Employee</label>
								<div class="col-9 text-left"><select id="employeeID" name="employeeID" class="form-control form-control-sm"></select></div>
								<script>initSelect2Suggestor("employeeNotAsUsers", "employeeID", "<%=_recordBean.getEmployeeID()%>", false, "");</script>
							<%} else {%>
								<input type="hidden" id="employeeID" name="employeeID" value="<%=_recordBean.getEmployeeID()%>">
								<label class="col-3 col-form-label text-left">Employee</label>
								<div class="col-9 form-control-plaintext text-left"><%=_recordBean.getEmployeeName()%></div>
							<%}%>
						</div>
						<div class="row form-row form-group form-group-sm">
							<label class="col-3 col-form-label required text-left">User Name</label>
							<div class="col-9 text-left"><input type="text" id="userName" name="userName" class="form-control form-control-sm" value=""></div>
						</div>
						<div class="row form-row form-group form-group-sm">
							<label class="col-3 col-form-label required text-left">Password</label>
							<div class="col-9 text-left">
								<div class="input-group">
									<input type="password" id="password" name="password" class="form-control form-control-sm" value="">
									<div class="input-group-append"><a href="Javascript:enabledPwd('password');"><span class="input-group-text" id="passwordSpanID"><i class="fa fa-eye" aria-hidden="true"></i></span></a></div>
								</div>
							</div>
						</div>
						<div class="row form-row form-group form-group-sm">
							<label class="col-3 col-form-label required text-left">Confirm Password</label>
							<div class="col-9 text-left">
								<div class="input-group">
								<input type="password" id="confirmPwd" name="confirmPwd" class="form-control form-control-sm" value="">
									<div class="input-group-append"><a href="Javascript:enabledPwd('confirmPwd');"><span class="input-group-text" id="confirmPwdSpanID"><i class="fa fa-eye" aria-hidden="true"></i></span></a></div>
								</div>
							</div>
						</div>
					</div>

					<div class="col-3">
					</div>
				</div>

				<script>
					<%if(submitType == SubmitType.UPDATE) {%>
						document.formmain["userName"].value = "<%=_recordBean.getUserName()%>";
						document.formmain["password"].value = "<%=_recordBean.getPassword()%>";
						document.formmain["confirmPwd"].value = "<%=_recordBean.getPassword()%>";
					<%}%>

				</script>

			<%} else if(submitType == SubmitType.CHANGE) {%>
				<div class="row">
					<div class="col-3">
					</div>

					<div class="col-6">
						<div class="row">
							<label class="col-3 col-form-label text-left">Employee</label>
							<div class="col-9 form-control-plaintext text-left"><%=_recordBean.getEmployeeName()%></div>
							<input type="hidden" id="employeeID" name="employeeID" value="<%=_recordBean.getEmployeeID()%>">
							<input type="hidden" id="userName" name="userName" value="<%=_recordBean.getUserName()%>">
						</div>
						<div class="row form-row form-group form-group-sm">
							<label class="col-3 col-form-label required text-left">User Name</label>
							<div class="col-9 text-left"><%=_recordBean.getUserName()%></div>
						</div>
						<div class="row form-row form-group form-group-sm">
							<label class="col-3 col-form-label required text-left">Password</label>
							<div class="col-9 text-left">
								<div class="input-group">
									<input type="password" id="password" name="password" class="form-control form-control-sm" value="">
									<div class="input-group-append"><a href="Javascript:enabledPwd('password');"><span class="input-group-text" id="passwordSpanID"><i class="fa fa-eye" aria-hidden="true"></i></span></a></div>
								</div>
							</div>
						</div>
						<div class="row form-row form-group form-group-sm">
							<label class="col-3 col-form-label required text-left">Confirm Password</label>
							<div class="col-9 text-left">
								<div class="input-group">
								<input type="password" id="confirmPwd" name="confirmPwd" class="form-control form-control-sm" value="">
									<div class="input-group-append"><a href="Javascript:enabledPwd('confirmPwd');"><span class="input-group-text" id="confirmPwdSpanID"><i class="fa fa-eye" aria-hidden="true"></i></span></a></div>
								</div>
							</div>
						</div>
					</div>

					<div class="col-3">
					</div>
				</div>

			<%} else if(submitType == SubmitType.BROWSE) {%>
				<div class="row">
					<div class="col-3">
					</div>

					<div class="col-6">
						<div class="row">
							<label class="col-3 col-form-label text-left">Employee</label>
							<div class="col-9 form-control-plaintext text-left"><%=_recordBean.getEmployeeName()%></div>
						</div>
						<div class="row">
							<label class="col-3 col-form-label text-left">User Name</label>
							<div class="col-9 form-control-plaintext text-left"><%=_recordBean.getUserName()%></div>
						</div>
						<div class="row">
							<label class="col-3 col-form-label text-left">Password</label>
							<div class="col-9 form-control-plaintext text-left">xxxxxx</div>
						</div>
					</div>

					<div class="col-3">
					</div>
				</div>
			<%}%>
			</div>
		</div>

		<%if(submitType == SubmitType.CREATE || submitType == SubmitType.UPDATE || submitType == SubmitType.CHANGE) {%>
			<div class="row mt-4">
				<div class="col-4 text-left">
					<%if(submitType != SubmitType.CHANGE) {%>
					<button class="btn btn-secondary text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.SEARCH%>','<%=_recordBean.getController()%>','');">Back to search</button>
					<%}%>
				</div>
				<div class="col-4 text-center">
					<%if(submitType == SubmitType.CREATE) {%>
						<button class="btn btn-success text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.CREATE_CONFIRM%>','<%=_recordBean.getController()%>','<%=_recordBean.getRecordID()%>');">Save</button>
						<!--button class="btn btn-success text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.CREATE_CONFIRM%>','<%=_recordBean.getController()%>','<%=_recordBean.getRecordID()%>','2');">Save & Post</button --></div>

					<%} else if(submitType == SubmitType.CHANGE) {%>
						<button class="btn btn-success text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.CHANGE%>','<%=_recordBean.getController()%>','<%=_recordBean.getRecordID()%>','','&requestType=change');">Save</button>

					<%} else {%>
						<button class="btn btn-success text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.UPDATE_CONFIRM%>','<%=_recordBean.getController()%>','<%=_recordBean.getRecordID()%>');">Save</button>
						<!--button class="btn btn-success text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.UPDATE_CONFIRM%>','<%=_recordBean.getController()%>','<%=_recordBean.getRecordID()%>','2');">Save & Post</button --></div>
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