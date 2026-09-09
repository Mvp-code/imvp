<!DOCTYPE html>
<%@ page import="java.util.*, com.util.*"%>
<jsp:useBean id="_errorBean" class="com.beans.ErrorBean" scope="request" />
<jsp:useBean id="_recordBean" class="com.beans.CommonUpload" scope="request" />
<%
int submitType = request.getAttribute("submitType") == null ? SubmitType.CREATE : Integer.parseInt(request.getAttribute("submitType").toString().trim());
boolean displaySaveBtn = true;
%>

<script>
function validatePageData(submitType, isValid) {

	if(submitType == <%=SubmitType.CREATE_CONFIRM%>) {
		if(isValid) {
			var mandatoryFieldsArray = new Array();			
			mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["module"], "Type");
			if(document.formmain["module"].value == "Inspection") {
				mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["vehicleID"], "Vehicle");
			} else if(document.formmain["module"].value == "Employee") {
				mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["employeeID"], "Employee");
			}

			if(document.formmain["selTimeoffIDs"]) {
				var selTimeoffIDs = getCheckboxValue(document.formmain["selTimeoffIDs"]);
				document.formmain["delTimeOffIDs"].value = selTimeoffIDs;
			}

			var selectedCNT = 0;
			var dynamicParams = document.formmain["dynamicParams"].value;
			if(dynamicParams.length > 0) {
				var splitArray = dynamicParams.split(",");
				for(var i=0; i<splitArray.length; i++) {
					if(document.formmain[splitArray[i]].value.length > 0) {
						selectedCNT++;
					}
				}

				if(document.formmain["timeOffStartDate"] && document.formmain["timeOffEndDate"]) {
					var timeOffStartDate = document.formmain["timeOffStartDate"].value;
					var timeOffEndDate = document.formmain["timeOffEndDate"].value;
					var timeOffReason = document.formmain["timeOffReason"].value;
					if(timeOffStartDate.length > 0 || timeOffEndDate.length > 0 || timeOffReason.length > 0) {
						mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["timeOffStartDate"], "Timeoff Start Date");
						mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["timeOffEndDate"], "Timeoff End Date");
						mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["timeOffReason"], "Timeoff Reason");
					}
				}

			} else {
				var numOfRows = parseInt(document.formmain["numOfRows"].value);
				for(var i=0; i<numOfRows; i++) {
					if(i == 0) {
						mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["uploadFileName"+i], "File Upload");
					}
					if(document.formmain["uploadFileName"+i].value.length > 0) {
						selectedCNT++;
					}
				}
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
					<div class="col-2 text-right my-auto"><%if(submitType == SubmitType.BROWSE) {%><button class="btn btn-primary btn-sm" onClick="Javascript:submitPageDataForm('<%=SubmitType.UPLOAD%>','<%=_recordBean.getController()%>');" title="Create New">New</button><%}%></div>
				</div>
			</div>

			<%if(_errorBean != null && _errorBean.getType().length() > 0) {%>
				<div class="row text-center"><section class='alert_section'><div class='alert-box <%=_errorBean.getType()%>Color'><%=_errorBean.getMesg()%></div></section></div>
				<%if("yes".equalsIgnoreCase(isPopup)) {%>
					<script>
						opener.refreshParentWindow();
						window.close();
					</script>
				<%}%>
			<%}%>

			<div class='card-body m-1 p-1'>
			<input type="hidden" id="<%=_recordBean.PRIMARY_KEY_ID%>" name="<%=_recordBean.PRIMARY_KEY_ID%>" value="<%=_recordBean.getRecordID()%>">
			<%if(submitType == SubmitType.CREATE || submitType == SubmitType.UPDATE) {%>

			<%} else if(submitType == SubmitType.UPLOAD) {%>
				<script>
				function selectModule(thisObj) {
					enableOrDisableID("vehicleDivID", "none");
					enableOrDisableID("employeeDivID", "none");
					if(thisObj.value == "Employee") {
						enableOrDisableID("employeeDivID", "");
						enableOrDisableID("vehicleInspectionNoteDivID", "none");
					} else {
						enableOrDisableID("vehicleDivID", "");
						enableOrDisableID("vehicleInspectionNoteDivID", "");
					}
				}
				</script>

				<%if("Inspection".equalsIgnoreCase(_recordBean.getModule())) {%>
					<style>
					  h1 {font-size:20px; margin-bottom:5px;}
					  h2 {font-size:16px; margin:15px 0 8px; color:#0056b3;}
					  .info {margin-bottom:15px; line-height:1.5;}
					  .radio-group {display:flex; gap:20px; margin:10px 0;}
					  .photos-section {display:grid; grid-template-columns:repeat(auto-fit,minmax(150px,1fr)); gap:12px;}
					  .photo-card {border:1px dashed #ccc; padding:10px; text-align:center; border-radius:8px; background:#fafafa;}
					  .photo-card input {display:none;}
					  .photo-card label {cursor:pointer; display:block;}
					  .photo-card img {max-width:100%; display:none; margin-top:8px; border-radius:5px;}
					</style>

					<input type="hidden" id="module" name="module" value="<%=_recordBean.getModule()%>">
					<input type="hidden" id="vehicleID" name="vehicleID" value="<%=_recordBean.getVehicleID()%>">
					<input type="hidden" id="employeeID" name="employeeID" value="<%=_recordBean.getEmployeeID()%>">

					<div class="row">
						<div class="col-12">
							<h2>Driver Information / <span lang="es">Información del Conductor</span></h2>
						</div>
						<div class="col-12">
							<div class="info">
								<strong>Wave Time / <span lang="es">Hora de la tanda</span>: </strong> <%=_recordBean.getWaveTime()%><br>
								<strong>Driver Name / <span lang="es">Nombre del Conductor</span> : </strong> <%=_recordBean.getEmployeeName()%><br>
								<strong>Assigned Vehicle / <span lang="es">Vehículo Asignado</span> : </strong> <%=_recordBean.getVehicleNumber()%>
							</div>
						</div>
						<%if(_recordBean.getVehicleNumber().length() > 0) {%>
							<div class="col-12">
								<h2>Parking Location / <span lang="es">Ubicación del estacionamiento</span></h2>
							</div>
							<div class="col-12">
								<div class="radio-group">
									<label><input type="radio" name="parking" value="1"> Inside / <span lang="es">Dentro</span></label>
									<label><input type="radio" name="parking" value="2"> Outside / <span lang="es">Fuera</span></label>
									<label><input type="radio" name="parking" value="3"> Backside / <span lang="es">Parte trasera</span></label>
								  </div>
							</div>

							<input type="hidden" id="dynamicParams" name="dynamicParams" value="">
							<input type="hidden" id="numOfRows" name="numOfRows" value="0">
							<input type="hidden" id="vehicleNumber" name="vehicleNumber" value="<%=_recordBean.getVehicleNumber()%>">
							<input type="hidden" id="daCheckinID" name="daCheckinID" value="<%=_recordBean.getDaCheckinID()%>">

							<%if(_recordBean.getUploadsList().size() > 0) {
								if(!"yes".equalsIgnoreCase(isPopup)) {%>
								<div class="col-12 col-md-2"></div>
								<div class="col-12 col-md-8 py-3">
								<%} else {%>
								<div class="col-12 py-3">
								<%}%>
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
														<th class="th-block table-header-label text-center" width="15%">Name</th>
														<th class="th-block table-header-label text-center" width="15%">Type</th>
														<th class="th-block table-header-label text-center" width="30%">Comments</th>
														<th class="th-block table-header-label text-center" width="30%">Audit</th>
														<th class="th-block table-header-label text-center" width="10%"></th>
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
														<td class="td-block table-value" data-th="Type"><%=type.replaceAll("-", " ")%></td>
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
								<%if(!"yes".equalsIgnoreCase(isPopup)) {%>
									<div class="col-12 col-md-2"></div>
								<%}%>
							<%}%>

							<div class="col-12">
								<h2>Start of Shift / <span lang="es">Inicio del Turno</span></h2>
							</div>
							<% String photoArray[][] = new String[][] {
								{"Front", "Frente"}, 
								{"Rear", "Trasera"}, 
								{"Passenger side", "Lado Pasajero"}, 
								{"Driver side", "Lado Conductor"}
							};
							String dynamicParams = "";%>
							<div class="col-12">
								<div class="photos-section">
								<%for(int i=0; i<photoArray.length; i++) {
									String english = photoArray[i][0];
									String spanish = photoArray[i][1];
									String paramName = "Start-"+english.replaceAll(" ", "-");
									if(dynamicParams.length() > 0)
										dynamicParams += ",";
									dynamicParams += paramName;%>
									<div class="photo-card" id="<%=paramName%>_divID">
										<label for="<%=paramName%>"><i class="fa fa-camera" aria-hidden="true"></i> <%=english%> / <span lang="es"><%=spanish%></span><span id="<%=paramName%>_divStatusID"></span></label>
										<input id="<%=paramName%>" name="<%=paramName%>" type="file" accept="image/*" capture="environment">
										<img id="preview-<%=paramName%>" alt="preview">
									</div>
									<div class="col-12 col-md-3" id="<%=paramName%>_divIDPreview" style="display:none">
										<label for="<%=paramName%>"><i class="fa fa-camera" aria-hidden="true"></i> <%=english%> / <span lang="es"><%=spanish%></span></label>
										<img id="preview-<%=paramName%>" alt="preview" src="..">
									</div>
								<%}%>
								</div>
							</div>

							<div class="col-12">
								<h2>End of Shift / <span lang="es">Fin del Turno</span></h2>
							</div>
							<div class="col-12">
								<div class="photos-section">
								<%for(int i=0; i<photoArray.length; i++) {
									String english = photoArray[i][0];
									String spanish = photoArray[i][1];
									String paramName = "End-"+english.replaceAll(" ", "-");
									if(dynamicParams.length() > 0)
										dynamicParams += ",";
									dynamicParams += paramName;%>
									<div class="photo-card" id="<%=paramName%>_divID">
										<label for="<%=paramName%>"><i class="fa fa-camera" aria-hidden="true"></i> <%=english%> / <span lang="es"><%=spanish%></span><span id="<%=paramName%>_divStatusID"></span></label>
										<input id="<%=paramName%>" name="<%=paramName%>" type="file" accept="image/*" capture="environment">
										<img id="preview-<%=paramName%>" alt="preview">
									</div>
								<%}%>
								</div>
							</div>

							<div class="col-12">
								<h2>Driver Comments / <span lang="es">Comentarios del Conductor</span></h2>
							</div>
							<div class="col-12">
								<textarea id="daComments" name="daComments" rows="2" placeholder="Please add any relevant comments here. / Por favor, añada comentarios relevantes aquí" maxlength="1000"><%=_recordBean.getDaComments()%></textarea>
							</div>
							<%if("4".equalsIgnoreCase(loginUserRoles)) {
							List timeOffList = new ArrayList();
							List extraDaysList = new ArrayList();
							if(_recordBean.getTransMap().get("timeOffList") != null)
								timeOffList = (List) _recordBean.getTransMap().get("timeOffList");
							if(_recordBean.getTransMap().get("extraDaysList") != null)
								extraDaysList = (List) _recordBean.getTransMap().get("extraDaysList");
							%>
							<div class="col-12">
								<h2>Driver Time Off / <span lang="es">Tiempo libre del conductor</span></h2>
							</div>
							<input type="hidden" id="delTimeOffIDs" name="delTimeOffIDs" value="">
							<%if(timeOffList.size() > 0) {%>
								<div class="col-12 pb-3">
									<table width="100%" border="0" cellpadding="0" cellspacing="0" class="table table-bordered table-striped table-hover table-sm table-block table-vertical sortable mb-0">
										<thead class="thead-block">
											<tr class="tr-block">
												<th class="th-block table-header-label text-center" width="10%">Start Date</th>
												<th class="th-block table-header-label text-center" width="10%">End Date</th>
												<th class="th-block table-header-label text-center" width="30%">Reason</th>
												<th class="th-block table-header-label text-center" width="7%">Status</th>
												<th class="th-block table-header-label text-center" width="20%">Reviewed</th>
												<th class="th-block table-header-label text-center" width="20%">Comments</th>
												<th class="th-block table-header-label text-center" width="3%" title="Delete">Del</th>
											</tr>
										</thead>
										<tbody class="tbody-block">
										<%for(int i=0; i<timeOffList.size(); i++) {
											List tempList = (ArrayList) timeOffList.get(i);
											String id = tempList.get(0) == null ? "" : tempList.get(0).toString().trim();
											String startDate = tempList.get(1) == null ? "" : tempList.get(1).toString().trim();
											String endDate = tempList.get(2) == null ? "" : tempList.get(2).toString().trim();
											String reason = tempList.get(3) == null ? "" : tempList.get(3).toString().trim();
											String status = tempList.get(4) == null ? "" : tempList.get(4).toString().trim();
											String reviewer = tempList.get(5) == null ? "" : tempList.get(5).toString().trim();
											String reviewedOn = tempList.get(6) == null ? "" : tempList.get(6).toString().trim();
											String reviewedComments = tempList.get(7) == null ? "" : tempList.get(7).toString().trim();
											String auditInfo = "";
											if(reviewer.length() > 0)
												auditInfo = reviewer+" on "+reviewedOn;
											%>
											<tr class="tr-block">
												<td class="td-block table-value" data-th="Start Date"><%=startDate%></td>
												<td class="td-block table-value" data-th="End Date"><%=endDate%></td>
												<td class="td-block table-value" data-th="Reason"><%=reason%></td>
												<td class="td-block table-value" data-th="Status"><%=status%></td>
												<td class="td-block table-value" data-th="Reviewed"><%=auditInfo%></td>
												<td class="td-block table-value" data-th="Comments"><%=reviewedComments%></td>
												<td class="td-block table-value text-center" data-th="Delete"><%if("Active".equalsIgnoreCase(status)) {%><input type="checkbox" id="selTimeoffIDs" name="selTimeoffIDs" value="<%=id%>"><%}%></td>
											</tr>
										<%}%>
										</tbody>
									</table>
								</div>
							<%}%>

							<div class="row col-12">
								<div class="col-12 col-md-2"><input type="text" id="timeOffStartDate" name="timeOffStartDate" class="form-control form-control-sm futuredatepicker" value="<%=_recordBean.getTimeOffStartDate()%>" placeholder="Start Date"></div>

								<div class="col-12 col-md-2"><input type="text" id="timeOffEndDate" name="timeOffEndDate" class="form-control form-control-sm futuredatepicker" value="<%=_recordBean.getTimeOffEndDate()%>" placeholder="End Date"></div>

								<div class="col-12 col-md-8"><textarea id="timeOffReason" name="timeOffReason" rows="2" placeholder="Please add any relevant reason here. / Por favor, añada aquí cualquier motivo relevante." maxlength="1000"><%=_recordBean.getTimeOffReason()%></textarea></div>
							</div>

							<div class="col-12">
								<h2>Driver Available Dates for Next Week (Overtime)<span lang="es"></span></h2>
							</div>
							<div class="row col-12 pb-3">
								<%String dynamicParamsMap = "delTimeOffIDs,extraDayCNT";
								for(int i=0; i<5; i++) {
									String extraDayID = "", extraDayVal = "";
									if(i < extraDaysList.size()) {
										List tempList = (ArrayList) extraDaysList.get(i);
										extraDayID = tempList.get(0) == null ? "" : tempList.get(0).toString().trim();
										extraDayVal = tempList.get(1) == null ? "" : tempList.get(1).toString().trim();
									}
									dynamicParamsMap += ",extraDayID"+i+",extraDayVal"+i; %>
									<input type="hidden" id="extraDayID<%=i%>" name="extraDayID<%=i%>" value="<%=extraDayID%>">
									<div class="col-12 col-md-2"><input type="text" id="extraDayVal<%=i%>" name="extraDayVal<%=i%>" class="form-control form-control-sm futuredatepicker" value="<%=extraDayVal%>" placeholder=""></div>
								<%}%>
								<input type="hidden" id="dynamicParamsMap" name="dynamicParamsMap" value="<%=dynamicParamsMap%>">
								<input type="hidden" id="extraDayCNT" name="extraDayCNT" value="5">
							</div>
							<%}%>

							<script>
							document.formmain["dynamicParams"].value = "<%=dynamicParams%>";
							</script>

						<%} else { displaySaveBtn = false;%>
							<div class="col-12 text-center">
								<h1 class="text-danger">No Checkin for today</h1>
							</div>
						<%}%>
					</div>  
					<script>
					// Preview uploaded photos
					setRadioButtonValue(document.formmain["parking"], "<%=_recordBean.getParking()%>");
					document.querySelectorAll("input[type=file]").forEach(input=>{
						input.addEventListener("change", e=>{
							const file = e.target.files[0];
							if(file) {
								// Get the file name
								const fileName = file.name;
								const docType = e.target.id;

								const preview = document.querySelector("#preview-"+docType);
								preview.src = URL.createObjectURL(file);
								preview.style.display="block";
								submitPageDataForm('3','<%=_recordBean.getController()%>','<%=_recordBean.getRecordID()%>');
								/*-
								const reader = new FileReader();
								reader.onload = () => {
									const base64 = reader.result.replace(/^data:image\/(png|jpg|jpeg);base64,/, "");
									var appQry = "&base64="+encodeURIComponent(base64)+"&docType="+encodeURIComponent(docType)+"&fileName="+encodeURIComponent(fileName);
									var dynamicParams = "";
									var fieldsArray = new Array("loginUser", "loginUserID", "loginUserRoles", "entityID", "recordID", "module", "vehicleID", "employeeID", "daCheckinID", "vehicleNumber");
									for(var i=0; i<fieldsArray.length; i++) {
										if(document.formmain[fieldsArray[i]] && document.formmain[fieldsArray[i]].value.length > 0) {
											var paramName = document.formmain[fieldsArray[i]].name;
											var paramValue = encodeURIComponent(document.formmain[fieldsArray[i]].value);
											console.log("paramName :: "+paramName+" :: "+paramValue);

											appQry += "&"+paramName+"="+paramValue;
											dynamicParams += paramName+",";
										}
									}
									var xmlHttpRequest = setSynXMLHttpOb("../servlet/MVPGServlet");
									var str = "submitType=10&controller=<%=_recordBean.getController()%>&requestType=autoSaveImage"+appQry;
									xmlHttpRequest.send(str);
									var xmlMessage = xmlHttpRequest.responseXML;
									var status = getXMLValue(xmlMessage.getElementsByTagName("status")[0]);
									var recordID = getXMLValue(xmlMessage.getElementsByTagName("recordID")[0]);
									console.log("status :: "+status+" :: "+recordID);
									var statusMesg = '<i class="fa fa-times text-danger" aria-hidden="true" title="Problem in saving photo, Please try again"></i>';
									if(status == "true") {
										document.formmain["recordID"].value = recordID;
										statusMesg = '<i class="fa fa-check text-success" aria-hidden="true" title="Photo saved successful"></i>';
										document.formmain["dynamicParams"].value = "";
									} else {
										alert("Problem in auto save image");
										document.formmain["dynamicParams"].value += docType+",";
									}
									if(document.getElementById(docType+"_divStatusID"))
										document.getElementById(docType+"_divStatusID").innerHTML = "&nbsp;"+statusMesg;
								};
								reader.readAsDataURL(file);
								*/
							}
						});
					});
					</script>
				<%} else {%>
					<div class="row">
						<div class="col-12 col-md-4">
							<div class="row form-row form-group form-group-sm">
								<label class="col-12 col-md-3 col-form-label required text-left">Type</label>
								<div class="col-12 col-md-9 text-left"><select id="module" name="module" class="form-control form-control-sm" onChange="selectModule(this);">
									<option value="Employee">Employee</option>
									<option value="Inspection" selected>Vehicle Inspection</option>
								</select></div>
							</div>
						</div>

						<div class="col-12 col-md-4" id="vehicleDivID">
							<div class="row form-row form-group form-group-sm">
								<label class="col-12 col-md-3 col-form-label required text-left">Vehicle</label>
								<div class="col-12 col-md-9 text-left"><select id="vehicleID" name="vehicleID" class="form-control form-control-sm">
									<option value=""></option>
								<%for(int i=0; i<_recordBean.getVehiclesList().size(); i++) {
									List tempList = (ArrayList) _recordBean.getVehiclesList().get(i);
									String id = tempList.get(0) == null ? "" : tempList.get(0).toString().trim();
									String value = tempList.get(1) == null ? "" : tempList.get(1).toString().trim();%>
									<option value="<%=id%>"><%=value%></option>
								<%}%>
								</select></div>
							</div>
						</div>

						<div class="col-12 col-md-3" id="employeeDivID" style="display:none">
							<div class="row form-row form-group form-group-sm">
								<label class="col-12 col-md-3 col-form-label required text-left">Employee</label>
								<div class="col-12 col-md-9 text-left"><select id="employeeID" name="employeeID" class="form-control form-control-sm"></select></div>
							</div>
						</div>
					</div>

					<script>
						initSelect2Suggestor("employees", "employeeID", "", false, "");
						initSelect2SuggestorConvert("vehicleID");
					</script>

					<input type="hidden" id="dynamicParams" name="dynamicParams" value="uploadFileName,docType,comments">
					<input type="hidden" id="numOfRows" name="numOfRows" value="10">
					<div class="row">
						<div class="col-12" id="vehicleInspectionNoteDivID">
							<label class="col-12 m-0 p-0 text-left text-info"><B>Note: Capture images for all 4 sides for Vehicle Inspection</B></label>
						</div>
						<div class="col-12">
							<table width="100%" border="0" cellpadding="0" cellspacing="0" class="table table-bordered table-striped table-hover table-sm table-block table-vertical sortable mb-0">
								<thead class="thead-block">
									<tr class="tr-block">
										<th class="th-block table-header-label text-center" width="20%">Type</th>
										<th class="th-block table-header-label text-center required" width="40%">File Upload</th>
										<th class="th-block table-header-label text-center" width="40%">Comments</th>
									</tr>
								</thead>
								<tbody class="tbody-block">
									<%for(int i=0; i<10; i++) {%>
									<tr class="tr-block">
										<td class="td-block table-value" data-th="Type"><input type="text" id="docType<%=i%>" name="docType<%=i%>" class="form-control form-control-sm"></td>
										<td class="td-block table-value" data-th="File Upload"><input type="file" id="uploadFileName<%=i%>" name="uploadFileName<%=i%>" accept="image/*" capture="environment"></td>
										<td class="td-block table-value" data-th="Comments"><textarea id="comments<%=i%>" name="comments<%=i%>" class="form-control form-control-sm" rows="1"></textarea></td>
									</tr>
									<%}%>
								</tbody>
							</table>
						</div>
					</div>
				<%}%>

			<%} else if(submitType == SubmitType.BROWSE) {%>
				<div class="row">
					<div class="col-5">
					</div>

					<div class="col-2"></div>

					<div class="col-5">
					</div>
				</div>
			<%}%>
			</div>
		</div>

		<div class="row my-4 text-center text-md-left" id="btnSectionDivID">
		<%if(submitType == SubmitType.UPLOAD) {%>
			<div class="col-12 col-md-4 mb-2 mb-md-0 text-md-left">
				<%if(!"yes".equalsIgnoreCase(isPopup) && !"4".equalsIgnoreCase(loginUserRoles)) {%>
				<button class="btn btn-secondary mb-1" onClick="Javascript:submitPageDataForm('<%=SubmitType.SEARCH%>','<%=_recordBean.getController()%>','');">Back to search</button><%}%>
			</div>
			<div class="col-12 col-md-4 mb-2 mb-md-0 text-md-center">
				<button id="saveBtn" class="btn btn-success mb-1" onClick="Javascript:submitPageDataForm('<%=SubmitType.CREATE_CONFIRM%>','<%=_recordBean.getController()%>','<%=_recordBean.getRecordID()%>');">Save</button>
			<div class="col-12 col-md-4 mb-2 mb-md-0 text-md-right"></div>

		<%} else if(submitType == SubmitType.CREATE || submitType == SubmitType.UPDATE) {%>
			<div class="col-12 col-md-4 mb-2 mb-md-0 text-md-left">
				<%if(!"yes".equalsIgnoreCase(isPopup)) {%>
				<button class="btn btn-secondary mb-1" onClick="Javascript:submitPageDataForm('<%=SubmitType.SEARCH%>','<%=_recordBean.getController()%>','');">Back to search</button><%}%>
			</div>
			<div class="col-12 col-md-4 mb-2 mb-md-0 text-md-center">
				<%if(submitType == SubmitType.CREATE) {%>
					<button class="btn btn-success mb-1" onClick="Javascript:submitPageDataForm('<%=SubmitType.CREATE_CONFIRM%>','<%=_recordBean.getController()%>','<%=_recordBean.getRecordID()%>');">Save</button>
				<%} else {%>
					<button class="btn btn-success mb-1" onClick="Javascript:submitPageDataForm('<%=SubmitType.UPDATE_CONFIRM%>','<%=_recordBean.getController()%>','<%=_recordBean.getRecordID()%>');">Save</button>
				<%}%>
			<div class="col-12 col-md-4 mb-2 mb-md-0 text-md-right"></div>

		<%} else if(submitType == SubmitType.BROWSE) {%>
			<div class="col-12 col-md-4 mb-2 mb-md-0 text-md-left">
				<button class="btn btn-secondary mb-1" onClick="Javascript:submitPageDataForm('<%=SubmitType.SEARCH%>','<%=_recordBean.getController()%>','');">Back to search</button>
			</div>
			<div class="col-12 col-md-4 mb-2 mb-md-0 text-md-center">
			<%if("0".equalsIgnoreCase(_recordBean.getStatus())) {%>
				<button class="btn btn-primary mb-1" onClick="Javascript:submitPageDataForm('<%=SubmitType.UPDATE%>','<%=_recordBean.getController()%>','<%=_recordBean.getRecordID()%>');">Edit</button>
			<%}%>
			</div>
			<div class="col-12 col-md-4 mb-2 mb-md-0 text-md-right">
			<%if("0".equalsIgnoreCase(_recordBean.getStatus())) {%>
				<button class="btn btn-danger mb-1" onClick="Javascript:submitPageDataForm('<%=SubmitType.DELETE%>','<%=_recordBean.getController()%>','<%=_recordBean.getRecordID()%>');">Delete</button>
			<%}%>
			</div>
		<%}%>
		</div>
	</div>
</div>
<%@ include file="includeFooter.jsp"%>
<script>
	<%if(!displaySaveBtn) {%> enableOrDisableID("btnSectionDivID", "none"); <%}%>
</script>