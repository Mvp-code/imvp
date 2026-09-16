<!DOCTYPE html>
<%@ page import="java.util.*, com.util.*, com.beans.*"%>
<jsp:useBean id="_errorBean" class="com.beans.ErrorBean" scope="request" />
<%
int submitType = request.getAttribute("submitType") == null ? SubmitType.CREATE : Integer.parseInt(request.getAttribute("submitType").toString().trim());

SearchBean _searchBean = new SearchBean();
Object _rawBeanObj = request.getAttribute("_recordBean");
if (_rawBeanObj instanceof SearchBean) {
    _searchBean = (SearchBean) _rawBeanObj;
    request.removeAttribute("_recordBean");
}
%>
<jsp:useBean id="_recordBean" class="com.beans.EmployeeSchedule" scope="request" />
<%
/* ═══════════════ LIST VIEW (redesigned — weekly matrix, read view) ═══════════════
   Editing still uses the legacy grid: the Edit Schedules button posts
   selectedType=UPDATE, which MVPGCtrl routes to searchList.jsp. */
if (submitType == SubmitType.SEARCH) {
    List dataList = _searchBean.getDataList() == null ? new ArrayList() : _searchBean.getDataList();
    List labels   = _searchBean.getLabelsList() == null ? new ArrayList() : _searchBean.getLabelsList();
    int cntEmp = dataList.size();
    int[] dayCounts = new int[7];
    /* rows: [0]=availID 1=name 2..8=day flags */
    List<String[]> rows = new ArrayList<String[]>();
    for (int i = 0; i < dataList.size(); i++) {
        List r = (List) dataList.get(i);
        String[] c = new String[9];
        for (int j = 0; j < 9 && j < r.size(); j++)
            c[j] = r.get(j) == null ? "" : r.get(j).toString().trim();
        for (int j = 0; j < 9; j++) if (c[j] == null) c[j] = "";
        for (int d = 0; d < 7; d++)
            if ("Y".equalsIgnoreCase(c[d + 2])) dayCounts[d]++;
        rows.add(c);
    }
    String weekFrom = labels.size() > 1 ? labels.get(1).toString() : _searchBean.getSrhFromDate();
    String weekTo   = labels.size() > 7 ? labels.get(7).toString() : _searchBean.getSrhToDate();
%>
<%@ include file="includeHeader.jsp"%>
<link rel="stylesheet" href="../jsp/assets/css/mvpx-list.css?v=20260916c">
<script src="../jsp/assets/js/mvpx-list.js?v=20260911b"></script>
<style>
.es-y{display:inline-flex;width:22px;height:22px;border-radius:50%;background:var(--status-ok-bg);color:var(--status-ok-fg);align-items:center;justify-content:center;font-size:11px;font-weight:800}
.es-n{color:#CBD5E1;font-size:12px}
.tablewrap td.es-c{text-align:center}
.tablewrap th.es-c{text-align:center}
</style>

<div class="da-wrap">

  <div class="da-headrow">
    <div>
      <h2>Employee Schedules</h2>
      <div class="statchips">
        <span class="statchip"><span class="dot" style="background:var(--da-blue)"></span><b><%=cntEmp%></b> employees</span>
        <span class="statchip"><span class="dot" style="background:var(--da-green)"></span><b><%=dayCounts[0]%></b> scheduled <%=weekFrom%></span>
      </div>
    </div>
    <div style="display:flex;gap:7px;align-items:center;flex-wrap:wrap">
      <button class="btn2" onclick="mvpxPrint('xls')" title="Export to Excel"><i class="fas fa-file-excel"></i> Excel</button>
      <button class="btn2" onclick="mvpxPrint('')" title="Download PDF"><i class="fas fa-file-pdf"></i> PDF</button>
      <button class="btn2 primary" onclick="esEdit()" title="Open the editable schedule grid"><i class="fas fa-pen"></i> Edit Schedules</button>
    </div>
  </div>

  <div class="da-toolbar">
    <div class="daterange-fld" title="Week starting">
      <span style="color:var(--da-faint)">&#128197;</span>
      <input type="date" id="filterFrom" onchange="esWeek(this.value)">
    </div>
    <div class="da-quick">
      <button onclick="esWeekShift(-7)">&laquo; Prev week</button>
      <button onclick="esWeekShift(0)">This week</button>
      <button onclick="esWeekShift(7)">Next week &raquo;</button>
    </div>
    <input class="da-flt" id="filterEmp" oninput="mvpxApplyFilters()" placeholder="Employee&hellip;" style="min-width:180px">
    <select class="da-flt" id="filterSched" onchange="mvpxApplyFilters()">
      <option value="">Everyone</option>
      <option value="y">Scheduled this week</option>
    </select>
  </div>

  <div class="da-chips" id="activeChips"></div>

  <%if(_errorBean != null && _errorBean.getType().length() > 0){%>
  <div class="row text-center mt-2">
    <section class="alert_section">
      <div class="alert-box <%=_errorBean.getType()%>Color"><%=_errorBean.getMesg()%></div>
    </section>
  </div>
  <%}%>

  <div class="tablewrap">
    <table>
      <thead>
        <tr>
          <th>Employee</th>
          <%for(int j = 1; j < labels.size(); j++){%>
          <th class="es-c"><%=labels.get(j)%></th>
          <%}%>
        </tr>
      </thead>
      <tbody id="ciRows">
        <%if(rows.isEmpty()){%>
        <tr><td colspan="8" class="da-empty">No schedules for this week.</td></tr>
        <%}%>
        <%for(String[] r : rows){
          boolean anyDay = false;
          for(int d = 2; d <= 8; d++) if ("Y".equalsIgnoreCase(r[d])) { anyDay = true; break; }
        %>
        <tr data-id="<%=r[0]%>"
            data-emp="<%=r[1].toLowerCase()%>"
            data-sched="<%=anyDay?"y":"n"%>">
          <td class="nm"><%=r[1]%></td>
          <%for(int d = 2; d <= 8; d++){%>
          <td class="es-c"><%if("Y".equalsIgnoreCase(r[d])){%><span class="es-y">&#10003;</span><%}else{%><span class="es-n">&mdash;</span><%}%></td>
          <%}%>
        </tr>
        <%}%>
      </tbody>
    </table>
    <div class="tablefoot">
      <span id="showCount">Showing <%=rows.size()%> of <%=cntEmp%></span>
      <span class="meta">Week: <%=weekFrom%> &ndash; <%=weekTo%></span>
    </div>
  </div>
</div>

<div class="da-toast" id="daToast"></div>

<script>
mvpxListInit({
  ctrl: '<%=_searchBean.getController()%>',
  from: '<%=weekFrom%>',
  to:   '<%=weekTo%>',
  filters: [
    { id:'filterEmp',   key:'emp',   label:'Employee',  mode:'includes' },
    { id:'filterSched', key:'sched', label:'Scheduled', mode:'exact' }
  ]
});
function esWeek(iso){
  var mdy = mvpxToMDY(iso);
  if (!mdy) return;
  submitPageDataForm('<%=SubmitType.SEARCH%>', MVPXL.ctrl, '', '',
    '&srhFromDate=' + encodeURIComponent(mdy) + '&searchFilter=yes');
}
function esWeekShift(days){
  var base = new Date();
  if (days !== 0) {
    var cur = mvpxMdyToISO(MVPXL.from);
    base = cur ? new Date(cur + 'T12:00:00') : new Date();
    base.setDate(base.getDate() + days);
  }
  var mdy = mvpxPad(base.getMonth()+1) + '/' + mvpxPad(base.getDate()) + '/' + base.getFullYear();
  submitPageDataForm('<%=SubmitType.SEARCH%>', MVPXL.ctrl, '', '',
    '&srhFromDate=' + encodeURIComponent(mdy) + '&searchFilter=yes');
}
function esEdit(){
  /* legacy editable grid (searchList.jsp) — same week */
  document.formmain.action = '../servlet/MVPGServlet?submitType=<%=SubmitType.SEARCH%>&controller=' + MVPXL.ctrl
    + '&searchFilter=yes&srhFromDate=' + encodeURIComponent(MVPXL.from)
    + '&selectedType=<%=SubmitType.UPDATE%>&selectedValues=Update';
  document.formmain.submit();
}
</script>

<%
/* ═══════════════ RECORD FORM VIEWS (unchanged legacy) ═══════════════ */
} else {
%>

<script>
function validatePageData(submitType, isValid) {

	if(submitType == <%=SubmitType.CREATE_CONFIRM%> || submitType == <%=SubmitType.UPDATE_CONFIRM%>) {
		if(isValid) {
			var scheduleDays = getCheckboxValue(document.formmain["days"]);
			document.formmain["scheduleDays"].value = scheduleDays;

			var mandatoryFieldsArray = new Array();
			mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["scheduleDate"], "Schedule Date");
			mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["employeeID"], "Employee");
			mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["scheduleDays"], "Schedule");
			isValid = validateMandatoryFieldsInForm(mandatoryFieldsArray, isValid);
		}

	} else if(submitType == <%=SubmitType.DELETE%>) {
		isValid = deleteRecord();
	}

	return isValid;
}

var vehicleID = "";
function loadEmployeeAvailability(thisObj) {
	console.log("loadEmployeeAvailability");
	if(thisObj.value.length > 0) {
		var appQry = "&employeeID="+document.formmain["employeeID"].value;
		var xmlHttpRequest = setSynXMLHttpOb("../servlet/MVPGServlet");
		var str = "submitType=10&controller=EmployeeSchedule&requestType=employeeAvailability"+appQry+getEntityParams();
		xmlHttpRequest.send(str);
		var xmlMessage = xmlHttpRequest.responseXML;
		var availabilityID = getXMLValue(xmlMessage.getElementsByTagName("availabilityID")[0]);
		var availabilityIDValues = getXMLValue(xmlMessage.getElementsByTagName("availability")[0]);
		console.log("loadEmployeeAvailability :: " +availabilityID+" :: "+availabilityIDValues);

		document.formmain["employeeAvailabilityID"].value = availabilityID;
		var availability = "Sun,Mon,Tue,Wed,Thu,Fri,Sat";
		switch(new Date().getDay()) {
			case 0:
				availability = "Mon,Tue,Wed,Thu,Fri,Sat,Sun";
				break;
			case 1:
				availability = "Tue,Wed,Thu,Fri,Sat,Sun,Mon";
				break;
			case 2:
				availability = "Wed,Thu,Fri,Sat,Sun,Mon,Tue";
				break;
			case 3:
				availability = "Thu,Fri,Sat,Sun,Mon,Tue,Wed";
				break;
			case 4:
				availability = "Fri,Sat,Sun,Mon,Tue,Wed,Thu";
				break;
			case 5:
				availability = "Sat,Sun,Mon,Tue,Wed,Thu,Fri";
				break;
			case 6:
				availability = "Sun,Mon,Tue,Wed,Thu,Fri,Sat";
				break;
		}
		var innerHTML = "";
		innerHTML += '<label class="col-6 col-form-label text-left">Schedule</label>';
		innerHTML += '<label class="col-6 col-form-label text-left">Wave</label>';
		var splitArray = availability.split(",");
		for(i=0; i<splitArray.length; i++) {
			var isDisabled = "disabled";
			var isWave = "";
			var tempArray = availabilityIDValues.split(",");
			for(j=0; j<tempArray.length; j++) {
				if(tempArray[j] == splitArray[i]) {
					isDisabled = "";
					isWave = " checked";
					break;
				}
			}

			innerHTML += '<div class="col-6 text-left"><input type="checkbox" class="form-check-input" name="days" value="'+(i+1)+'" '+isDisabled+'>'+splitArray[i]+'</label></div>';
			innerHTML += '<div class="col-6 text-left">';
				innerHTML += '<div class="form-check-inline">';
					innerHTML += '<label class="form-check-label"><input type="radio" class="form-check-input" name="wave'+i+'" value="1" '+isDisabled+isWave+'>1</label>';
				innerHTML += '</div>';
				innerHTML += '<div class="form-check-inline">';
					innerHTML += '<label class="form-check-label"><input type="radio" class="form-check-input" name="wave'+i+'" value="2" '+isDisabled+'>2</label>';
				innerHTML += '</div>';
			innerHTML += '</div>';
		}
		document.getElementById("employeeAvailabilityDivID").innerHTML = innerHTML;
	} else {
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
				<input type="hidden" id="employeeAvailabilityID" name="employeeAvailabilityID" value="">
				<input type="hidden" id="scheduleDays" name="scheduleDays" value="">
				<div class="row">
					<div class="col-12 col-lg-5">
						<div class="row form-row form-group form-group-sm">
							<label class="col-3 col-form-label required text-left">Schedule Date</label>
							<div class="col-9 text-left">
								<input type="text" id="scheduleDate" name="scheduleDate" class="form-control form-control-sm datepicker" value="<%=_recordBean.getScheduleDate()%>" placeholder="Date">
							</div>
						</div>
						<div class="row form-row form-group form-group-sm">
							<label class="col-3 col-form-label required text-left">Employee</label>
							<div class="col-9 text-left"><select id="employeeID" name="employeeID" class="form-control form-control-sm" onChange="loadEmployeeAvailability(this);"></select></div>
						</div>
						<div class="row form-row form-group form-group-sm">
							<label class="col-3 col-form-label text-left">Schedule</label>
							<div class="col-9 text-left">
								<div class="row m-0 p-0" id="employeeAvailabilityDivID">
								</div>
							</div>
						</div>
					</div>
				</div>

				<script>
					initSelect2Suggestor("employees", "employeeID", "", false, "");
				</script>

			<%} else if(submitType == SubmitType.BROWSE) {%>
				<div class="row">
					<div class="col-5">
						<div class="row">
							<label class="col-3 col-form-label text-left">Schedule Date</label>
							<div class="col-9 form-control-plaintext text-left"><%=_recordBean.getScheduleDate()%></div>
						</div>
					</div>

					<div class="col-2"></div>

					<div class="col-5">
						<div class="row">
							<label class="col-3 col-form-label text-left">Wave</label>
							<div class="col-9 form-control-plaintext text-left"></div>
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
						<button class="btn btn-success text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.CREATE_CONFIRM%>','<%=_recordBean.getController()%>','');">Save</button>
					<%} else {%>
						<button class="btn btn-success text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.UPDATE_CONFIRM%>','<%=_recordBean.getController()%>','');">Save</button>
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
					<button class="btn btn-primary text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.UPDATE%>','<%=_recordBean.getController()%>','');">Edit</button>
				<%}%>
				</div>
				<div class="col-4 text-right">
				<%if("0".equalsIgnoreCase(_recordBean.getStatus())) {%>
					<button class="btn btn-danger text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.DELETE%>','<%=_recordBean.getController()%>','');">Delete</button>
				<%}%>
				</div>
			</div>
		<%}%>
	</div>
</div>
<%@ include file="includeFooter.jsp"%>
<%}%>