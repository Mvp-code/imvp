<!DOCTYPE html>
<html lang="en">
<%@ page import="java.util.*, com.util.*"%>
<jsp:useBean id="_errorBean" class="com.beans.ErrorBean" scope="request" />
<head>
<meta charset="UTF-8" />
<meta name="viewport" content="width=device-width, initial-scale=1.0"/>

<script src="../jsp/bootstrap/jquery-3.3.1.js"></script>
<script src="../jsp/bootstrap/popper.js"></script>
<script src="../jsp/bootstrap/bootstrap.min.js"></script>

<script src="../jsp/JSFunctions.js"></script>

<link rel="stylesheet" type="text/css" href="../jsp/bootstrap/datepicker/datepicker.min.css">
<script src="../jsp/bootstrap/datepicker/bootstrap-datepicker.min.js"></script>

<link rel="stylesheet" type="text/css" href="../jsp/bootstrap/select2/select2.css">
<script src="../jsp/bootstrap/select2/select2.js"></script>

<link rel="stylesheet" type="text/css" href="../jsp/bootstrap/bootstrap.min.css"> 
<link rel="stylesheet" type="text/css" href="../jsp/bootstrap/all.min.css"/>
<link rel="stylesheet" type="text/css" href="../jsp/bootstrap/MVPG.css">
</head>
<body>
<div class="container-fluid">
	<div class="row">
		<div class="col-12 text-center pt-2"><img width="300px" height="150px" src="../images/logo/logo_1.jpeg"></div>
		<div class="col-12">
			<form name="formmain" method="post" action="javascript:submitEmptyForm()"><div class="container">
			<div class='row my-2'>
				<div class='col-12 mb-2'>
					<div class='card'>
						<div class='card-header table-title-header m-0 py-2'>Login</div>
						<div class='card-body'>
							<%if(_errorBean != null && _errorBean.getType().length() > 0) {%>
								<div class="row text-center"><section class='alert_section'><div class='alert-box <%=_errorBean.getType()%>Color'><%=_errorBean.getMesg()%></div></section></div>
							<%}%>
							<div class="row">
								<label class="col-3 col-form-label required text-left">Username</label>
								<div class="col-9 text-left"><input type="text" id="loginUser" name="loginUser" class="form-control form-control-sm"></select></div>
							</div>
							<div class="row py-3">
								<label class="col-3 col-form-label required text-left">Password</label>
								<div class="col-9 text-left"><input type="password" id="loginPwd" name="loginPwd" class="form-control form-control-sm"></select></div>
							</div>
						</div>
					</div>
				</div>

				<div class="row col-12 mt-4">
					<div class="col-4 text-left"></div>
					<div class="col-4 text-center">
						<button class="btn btn-success text-center" onClick="Javascript:preSubmitForm();">Submit</button>
					</div>
					<div class="col-4 text-right"></div>
				</div>
			</div>
			</div></form>
		</div>
	</div>
</div>
</body>
</html>

<script>
function preSubmitForm(submitType) {
	var isValid = true;
	var mandatoryFieldsArray = new Array();
	mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["loginUser"], "Username");
	mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["loginPwd"], "Password");
	isValid = validateMandatoryFieldsInForm(mandatoryFieldsArray, isValid);
	if(isValid) {
		document.formmain.action = "../servlet/MVPGServlet?submitType=<%=SubmitType.LOGIN%>&controller=Login";
		document.formmain.submit();
	}
}
document.formmain["loginUser"].focus();
//preSubmitForm(<%=SubmitType.SEARCH%>);
</script>