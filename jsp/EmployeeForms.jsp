<!DOCTYPE html>
<%@ page import="java.util.*, com.util.*"%>
<jsp:useBean id="_errorBean" class="com.beans.ErrorBean" scope="request" />
<jsp:useBean id="_recordBean" class="com.beans.EmployeeForms" scope="request" />
<%
int submitType = request.getAttribute("submitType") == null ? SubmitType.CREATE : Integer.parseInt(request.getAttribute("submitType").toString().trim());
%>

<script>
var displaySignature = false;
function previewSignature(canvasID) {
	var canvas = document.getElementById(canvasID);
	// save canvas image as data url (png format by default)
	var dataURL = canvas.toDataURL("image/png");
	document.getElementById("saveSignature").src = dataURL;
}

function isCanvasBlank(canvas) {
	const blank = document.createElement('canvas');
	blank.width = canvas.width;
	blank.height = canvas.height;
	document.formmain["signatureValue"].value = canvas.toDataURL("image/png").replace(/^data:image\/(png|jpg);base64,/, "");
	return document.formmain["signatureValue"].value === blank.toDataURL("image/png").replace(/^data:image\/(png|jpg);base64,/, "");
}

function updateCanvas(canvas) {
	if (!canvas || canvas.width === 0 || canvas.height === 0) {
		document.formmain["signatureValue"].value = "";
        return false;
    }
	const base64 = canvas.toDataURL("image/png");
	// REMOVE PREFIX
	const cleanBase64 = base64.split(",")[1];
	// OPTIONAL SAFETY
	const finalBase64 = cleanBase64.replace(/\s+/g, "");
	document.formmain["signatureValue"].value = finalBase64;
}

function validatePageData(submitType, isValid) {

	if(submitType == <%=SubmitType.CREATE_CONFIRM%> || submitType == <%=SubmitType.UPDATE_CONFIRM%>) {
		var mandatoryFieldsArray = new Array();
		var textareaContents = tinymce.get("textareaContents").getContent();
		document.formmain["formContents"].value = textareaContents;
		document.formmain["signatureValue"].value = "";
		if(displaySignature) {
			var isSignPresent = isCanvasBlank(document.getElementById("signature-pad-canvas"));
			if(isSignPresent)
				mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["signatureValue"], "Signature");
		}

		mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["station"], "Station");
		mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["employeeID"], "Employee");
		mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["adminFormsTemplateID"], "Template");
		mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["formContents"], "Template Contents");
		isValid = validateMandatoryFieldsInForm(mandatoryFieldsArray, isValid);
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

			<input type="hidden" id="employeeFormsID" name="employeeFormsID" value="<%=_recordBean.getRecordID()%>">
			<div class='card-body m-1 p-1'>
			<%if(submitType == SubmitType.CREATE || submitType == SubmitType.UPDATE) {%>

				<script type="text/javascript" src="../jsp/richTextEditor/jscripts/tiny_mce/tiny_mce_src.js"></script>
				<script type="text/javascript">
				tinyMCE.init({
					// General options
					mode : "exact",
					elements : "textareaContents",
					theme : "advanced",
					skin : "o2k7",
					language: "en",
					plugins : "scayt, pagebreak, style, layer, table, save, advhr, advimage, advlink, emotions, iespell, insertdatetime, preview, media, searchreplace, print, contextmenu, paste, directionality, fullscreen, noneditable, visualchars, nonbreaking, xhtmlxtras, template, inlinepopups",
					// Theme options
					theme_advanced_buttons1 : "scayt, newdocument, |, bold, italic, underline, strikethrough, |, justifyleft, justifycenter, justifyright, justifyfull, |, formatselect, fontselect, fontsizeselect, |, tablecontrols, pagebreak",
					theme_advanced_buttons2 : "cut, copy, paste, pastetext, pasteword, |, search, replace, |, bullist, numlist, |, outdent, indent, blockquote, |, undo, redo, |, insertdate, inserttime, preview, |, forecolor, backcolor, |, hr, removeformat, visualaid, |, sub, sup, |, charmap, advhr, |, ltr, rtl, |, print, fullscreen, code",
					theme_advanced_buttons3 : "",
					theme_advanced_toolbar_location : "top",
					theme_advanced_toolbar_align : "left",
					theme_advanced_statusbar_location : "bottom",
					theme_advanced_resizing : false,
					// turn on/off SCAYT autostartup
					scayt_auto_startup : false,
					scayt_custom_url : "../jsp/richTextEditor/jscripts/tiny_mce/scayt.js",
					// set -1 to disable submenu
					scayt_max_suggestion : 2,
					// Replace values for the template plugin
					template_replace_values : {
						username : "MVPG",
						staffid : "mvpgEditor"
					}
				});
				</script>

				<div class="row">
					<div class="col-2">
					</div>
					<input type="hidden" id="formContents" name="formContents" value="">
					<div class="col-8">
						<div class="row form-row form-group form-group-sm">
							<label class="col-2 col-form-label required text-left">Station</label>
							<div class="col-10 text-left"><select id="station" name="station" class="form-control form-control-sm"><option value=""></option><option value="DNK7" selected>DNK7</option></select></div>
						</div>
						<%if(submitType == SubmitType.CREATE) {%>
							<div class="row form-row form-group form-group-sm">
								<label class="col-2 col-form-label required text-left">Employee</label>
								<div class="col-10 text-left"><select id="employeeID" name="employeeID" class="form-control form-control-sm" onChange="getFormTemplate();"></select></div>
							</div>
							<div class="row form-row form-group form-group-sm">
								<label class="col-2 col-form-label required text-left">Template</label>
								<div class="col-10 text-left"><select id="adminFormsTemplateID" name="adminFormsTemplateID" class="form-control form-control-sm" onChange="getFormTemplate();"></select></div>
							</div>
						<%} else {%>
							<input type="hidden" id="employeeID" name="employeeID" value="<%=_recordBean.getEmployeeID()%>">
							<input type="hidden" id="adminFormsTemplateID" name="adminFormsTemplateID" value="<%=_recordBean.getAdminFormsTemplateID()%>">
							<div class="row">
								<label class="col-2 col-form-label text-left">Employee</label>
								<div class="col-10 form-control-plaintext text-left"><%=_recordBean.getEmployeeName()%></div>
							</div>
							<div class="row">
								<label class="col-2 col-form-label text-left">Template</label>
								<div class="col-10 form-control-plaintext text-left"><%=_recordBean.getFormName()%></div>
							</div>
						<%}%>
						<div class="row form-row form-group form-group-sm">
							<div class="col-12 text-left"><textarea id="textareaContents" name="textareaContents" cols="100" spellcheck="true" rows="25" class='form-control'><%=_recordBean.getFormContents()%></textarea></div>
						</div>
						<div class="row form-row form-group form-group-sm">
							<label class="col-2 col-form-label required text-left">Comments</label>
							<div class="col-10 text-left"><textarea id="comments" name="comments" class="form-control form-control-sm"><%=_recordBean.getComments()%></textarea></div>
						</div>

						<div id="signatureDivID" class="row form-row form-group form-group-sm" style="display:none">
							<input type="hidden" id="signatureValue" name="signatureValue" value="">
							<div class="col-12 text-left">
								<p><b>Signature&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<a href="#" class="signature-pad-clear">Clear</a></b></p>
								<form class="signature-pad-form" action="#" method="POST">
									<canvas class="signature-pad-canvas" id="signature-pad-canvas" style="position: relative; margin: 0; padding: 0; border: 1px solid #c4caac;"></canvas>
								</form>
								<script type="text/javascript" src="../jsp/signaturePad.js"></script>
								<%if(_recordBean.getSignFileNameWithPath().length() > 0) {
									String filePath = _recordBean.getSignFileNameWithPath();
									filePath = filePath.substring(filePath.indexOf("docs"), filePath.length());%>
									<img id="saveSignature" src="../<%=filePath%>" style="display:none"/>
								<%}%>
							</div>
						</div>
					</div>

					<div class="col-2">
					</div>
				</div>

				<script>
					<%if(submitType == SubmitType.CREATE) {%>
						initSelect2Suggestor("employees", "employeeID", "<%=_recordBean.getEmployeeID()%>", false, "");
						initSelect2Suggestor("formsTemplate", "adminFormsTemplateID", "<%=_recordBean.getAdminFormsTemplateID()%>", false, "");
					<%} else {
						if(_recordBean.getFormContents().contains("##signature.employee##")) {%>
							displaySignature = true;
							enableOrDisableID("signatureDivID", "");

							<%if(_recordBean.getSignFileNameWithPath().length() > 0) {%>
								saveSignature.onload = () => {
								   sign_pad_ctx.drawImage(saveSignature, 0, 0);
								}
							<%}
						}
					}%>

					function getFormTemplate() {
						var employeeObj = document.formmain["employeeID"];
						var templateObj = document.formmain["adminFormsTemplateID"];
						if(templateObj.value > 0) {
							var appQry = "&adminFormsTemplateID="+templateObj.value;
							var xmlHttpRequest = setSynXMLHttpOb("../servlet/MVPGServlet");
							var str = "submitType=10&controller=<%=_recordBean.getController()%>&requestType=getFormTemplate"+appQry+getEntityParams();
							xmlHttpRequest.send(str);
							var data = xmlHttpRequest.responseText;

							var dateObj = new Date();
							var dateDay = dateObj.getDate();
							var dateMonth = dateObj.getMonth()+1;
							var dateYear = dateObj.getFullYear();
							if(dateDay < 10)
								dateDay = "0"+dateDay;
							if(dateMonth < 10)
								dateMonth = "0"+dateMonth;

							var currentDate = dateMonth+"/"+dateDay+"/"+dateYear;
							var employeeName = getSelectBoxText(employeeObj);
							var weekPrevious = "_______";
							var weekCurrent = "_______";
							data = data.replace(/##employee.name##/g, employeeName);
							data = data.replace(/##currentDate##/g, currentDate);

							enableOrDisableID("signatureDivID", "none");
							if(data.indexOf("##signature.employee##") != -1) {
								//data = data.replace(/##signature.employee##/g, "");

								displaySignature = true;
								enableOrDisableID("signatureDivID", "");
							}
							//data = data.replace(/##week.previous##/g, '<span style="text-decoration: underline;">'+weekPrevious+'</span>');
							//data = data.replace(/##week.current##/g, '<span style="text-decoration: underline;">'+weekCurrent+'</span>');
							tinyMCE.activeEditor.setContent(data);
						}
					}
				</script>

			<%} else if(submitType == SubmitType.BROWSE) {%>
				<div class="row">
					<div class="col-2">
					</div>

					<div class="col-8">
						<div class="row">
							<label class="col-2 col-form-label text-left">Station</label>
							<div class="col-10 form-control-plaintext text-left"><%=_recordBean.getStation()%></div>
						</div>
						<div class="row">
							<label class="col-2 col-form-label text-left">Employee</label>
							<div class="col-10 form-control-plaintext text-left"><%=_recordBean.getEmployeeName()%></div>
						</div>
						<div class="row">
							<label class="col-2 col-form-label text-left">Template</label>
							<div class="col-10 form-control-plaintext text-left"><%=_recordBean.getFormName()%></div>
						</div>
						<div class="row">
							<div class="col-12 text-left"><%=_recordBean.getFormContents().replaceAll("##signature.employee##", "")%></div>
						</div>
						<%if(_recordBean.getComments().length() > 0) {%>
						<div class="row">
							<label class="col-2 col-form-label text-left">Comments</label>
							<div class="col-10 form-control-plaintext text-left"><%=_recordBean.getComments()%></div>
						</div>
						<%}%>
						<%if(_recordBean.getSignFileNameWithPath().length() > 0) {%>
							<div id="signatureDivID" class="row pt-3">
								<div class="col-12 text-left">
									<p><b>Signature</b></p>
									<%String filePath = _recordBean.getSignFileNameWithPath();
									filePath = filePath.substring(filePath.indexOf("docs"), filePath.length());%>
									<img id="saveSignature" src="../<%=filePath%>"/>
								</div>
							</div>
						<%}%>
					</div>

					<div class="col-2">
					</div>
				</div>
			<%}%>
			</div>
		</div>

		<%if(submitType == SubmitType.CREATE || submitType == SubmitType.UPDATE) {%>
			<div class="row mt-4">
				<div class="col-4 text-left">
				</div>
				<div class="col-4 text-center">
					<%if(submitType == SubmitType.CREATE) {%>
						<button class="btn btn-success text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.CREATE_CONFIRM%>','<%=_recordBean.getController()%>','<%=_recordBean.getRecordID()%>');">Save</button>
						<button class="btn btn-success text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.CREATE_CONFIRM%>','<%=_recordBean.getController()%>','<%=_recordBean.getRecordID()%>','2');">Save & Post</button></div>

					<%} else {%>
						<button class="btn btn-success text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.UPDATE_CONFIRM%>','<%=_recordBean.getController()%>','<%=_recordBean.getRecordID()%>');">Save</button>
						<button class="btn btn-success text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.UPDATE_CONFIRM%>','<%=_recordBean.getController()%>','<%=_recordBean.getRecordID()%>','2');">Save & Post</button></div>
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
				<%} else if("2".equalsIgnoreCase(_recordBean.getStatus())) {%>
					<button class="btn btn-secondary text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.PRINT%>','<%=_recordBean.getController()%>','<%=_recordBean.getRecordID()%>');">Print</button>
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