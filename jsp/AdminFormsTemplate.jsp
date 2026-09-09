<!DOCTYPE html>
<%@ page import="java.util.*, com.util.*"%>
<jsp:useBean id="_errorBean" class="com.beans.ErrorBean" scope="request" />
<jsp:useBean id="_recordBean" class="com.beans.AdminFormsTemplate" scope="request" />
<%
int submitType = request.getAttribute("submitType") == null ? SubmitType.CREATE : Integer.parseInt(request.getAttribute("submitType").toString().trim());
%>

<script>
function validatePageData(submitType, isValid) {

	if(submitType == <%=SubmitType.CREATE_CONFIRM%> || submitType == <%=SubmitType.UPDATE_CONFIRM%>) {
		var textareaContents = tinymce.get("textareaContents").getContent();
		document.formmain["formContents"].value = textareaContents;
		var mandatoryFieldsArray = new Array();
		mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["formName"], "Name");
		mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["formContents"], "Template");
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

			<input type="hidden" id="adminFormsTemplateID" name="adminFormsTemplateID" value="<%=_recordBean.getRecordID()%>">
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
							<label class="col-2 col-form-label required text-left">Name</label>
							<div class="col-10 text-left"><input type="text" id="formName" name="formName" class="form-control form-control-sm" value="<%=_recordBean.getFormName()%>"></div>
						</div>
						<div class="row form-row form-group form-group-sm">
							<label class="col-2 col-form-label required text-left">Template</label>
							<div class="col-10 text-left"><textarea id="textareaContents" name="textareaContents" cols="100" spellcheck="true" rows="25" class='form-control'><%=_recordBean.getFormContents()%></textarea></div>
						</div>
					</div>

					<div class="col-2">
					</div>
				</div>

				<script>
				</script>

			<%} else if(submitType == SubmitType.BROWSE) {%>
				<div class="row">
					<div class="col-2">
					</div>

					<div class="col-8">
						<div class="row">
							<label class="col-2 col-form-label text-left">Name</label>
							<div class="col-10 form-control-plaintext text-left"><%=_recordBean.getFormName()%></div>
						</div>
						<div class="row">
							<div class="col-12 text-left"><%=_recordBean.getFormContents()%></div>
						</div>
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
					<%if(submitType != SubmitType.CHANGE) {%>
					<button class="btn btn-secondary text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.SEARCH%>','<%=_recordBean.getController()%>','');">Back to search</button>
					<%}%>
				</div>
				<div class="col-4 text-center">
					<%if(submitType == SubmitType.CREATE) {%>
						<button class="btn btn-success text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.CREATE_CONFIRM%>','<%=_recordBean.getController()%>','<%=_recordBean.getRecordID()%>');">Save</button>

					<%} else {%>
						<button class="btn btn-success text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.UPDATE_CONFIRM%>','<%=_recordBean.getController()%>','<%=_recordBean.getRecordID()%>');">Save</button>
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