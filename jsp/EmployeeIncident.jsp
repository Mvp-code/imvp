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
<jsp:useBean id="_recordBean" class="com.beans.EmployeeIncident" scope="request" />
<%
/* ═══════════════ LIST VIEW (redesigned — MVPx list standard) ═══════════════ */
if (submitType == SubmitType.SEARCH) {
    List dataList = _searchBean.getDataList() == null ? new ArrayList() : _searchBean.getDataList();
    int cntTotal = dataList.size(), cntPosted = 0;
    List<String> empNames  = new ArrayList<String>();
    List<String> typeNames = new ArrayList<String>();
    List<String> stNames   = new ArrayList<String>();
    /* [0]=id 1=emp 2=date 3=time 4=reported 5=type 6=location 7=emt 8=status 9=pill */
    List<String[]> rows = new ArrayList<String[]>();
    for (int i = 0; i < dataList.size(); i++) {
        List r = (List) dataList.get(i);
        String[] c = new String[10];
        for (int j = 0; j < 9 && j < r.size(); j++)
            c[j] = r.get(j) == null ? "" : r.get(j).toString().trim();
        for (int j = 0; j < 10; j++) if (c[j] == null) c[j] = "";
        String status = c[8];
        String pill = "slate";
        if ("Active".equalsIgnoreCase(status)) pill = "amber";
        else if (status.toLowerCase().startsWith("post")) { pill = "blue"; cntPosted++; }
        c[9] = pill;
        if (c[1].length() > 0 && !empNames.contains(c[1])) empNames.add(c[1]);
        if (c[5].length() > 0 && !typeNames.contains(c[5])) typeNames.add(c[5]);
        if (status.length() > 0 && !stNames.contains(status)) stNames.add(status);
        rows.add(c);
    }
    Collections.sort(empNames); Collections.sort(typeNames); Collections.sort(stNames);
%>
<%@ include file="includeHeader.jsp"%>
<link rel="stylesheet" href="../jsp/assets/css/mvpx-list.css?v=20260916d">
<script src="../jsp/assets/js/mvpx-list.js?v=20260911b"></script>

<div class="da-wrap">

  <div class="da-headrow">
    <div>
      <h2>OSHA Incidents</h2>
      <div class="statchips">
        <span class="statchip"><span class="dot" style="background:var(--da-blue)"></span><b><%=cntTotal%></b> incidents</span>
        <span class="statchip"><span class="dot" style="background:#64748B"></span><b><%=cntPosted%></b> posted</span>
      </div>
    </div>
    <div style="display:flex;gap:7px;align-items:center;flex-wrap:wrap">
      <button class="btn2" onclick="mvpxPrint('xls')" title="Export to Excel"><i class="fas fa-file-excel"></i> Excel</button>
      <button class="btn2" onclick="mvpxPrint('')" title="Download PDF"><i class="fas fa-file-pdf"></i> PDF</button>
      <%if(_searchBean.isDisplayPostBtn()){%>
      <button class="btn2 success" onclick="mvpxBulk(<%=SubmitType.FINAL%>,'post')"><i class="fas fa-check"></i> Post</button>
      <%}%>
      <button class="btn2 primary" onclick="submitPageDataForm('<%=SubmitType.CREATE%>','<%=_searchBean.getController()%>');">&#xFF0B; New</button>
    </div>
  </div>

  <div class="da-toolbar">
    <div class="daterange-fld">
      <span style="color:var(--da-faint)">&#128197;</span>
      <input type="date" id="filterFrom" onchange="mvpxDateSearch()">
      <span class="dash">&ndash;</span>
      <input type="date" id="filterTo" onchange="mvpxDateSearch()">
    </div>
    <div class="da-quick">
      <button onclick="mvpxQuickDate('week')">This week</button>
      <button onclick="mvpxQuickDate('month')">This month</button>
    </div>
    <select class="da-flt" id="filterEmp" onchange="mvpxApplyFilters()" style="min-width:170px">
      <option value="">All employees</option>
      <%for(String v : empNames){%><option value="<%=v.toLowerCase()%>"><%=v%></option><%}%>
    </select>
    <select class="da-flt" id="filterType" onchange="mvpxApplyFilters()">
      <option value="">All types</option>
      <%for(String v : typeNames){%><option value="<%=v.toLowerCase()%>"><%=v%></option><%}%>
    </select>
    <select class="da-flt" id="filterStatus" onchange="mvpxApplyFilters()">
      <option value="">All statuses</option>
      <%for(String v : stNames){%><option value="<%=v.toLowerCase()%>"><%=v%></option><%}%>
    </select>
  </div>

  <div class="da-chips" id="activeChips"></div>
  <div class="da-typesum" id="typeSum"></div>

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
          <th style="width:32px"><input type="checkbox" id="selectAll" onchange="mvpxToggleSelectAll(this)"></th>
          <th>Employee</th>
          <th>Date</th>
          <th>Time</th>
          <th>Reported</th>
          <th>Type</th>
          <th>Location</th>
          <th>EMT #</th>
          <th>Status</th>
        </tr>
      </thead>
      <tbody id="ciRows">
        <%if(rows.isEmpty()){%>
        <tr><td colspan="9" class="da-empty">No incidents for this date range.</td></tr>
        <%}%>
        <%for(String[] r : rows){%>
        <tr data-id="<%=r[0]%>"
            data-emp="<%=r[1].toLowerCase()%>"
            data-type="<%=r[5].toLowerCase()%>"
            data-st="<%=r[8].toLowerCase()%>">
          <td><input type="checkbox" class="rowCheck" value="<%=r[0]%>"></td>
          <td class="nm"><a href="javascript:void(0)" style="color:inherit" onclick="submitPageDataForm('<%=SubmitType.BROWSE%>','<%=_searchBean.getController()%>','<%=r[0]%>')"><%=r[1]%></a></td>
          <td><%=r[2]%></td>
          <td><%=r[3]%></td>
          <td class="meta"><%=r[4].length()>0?r[4]:"&mdash;"%></td>
          <td><%=r[5]%></td>
          <td class="meta"><%=r[6].length()>0?r[6]:"&mdash;"%></td>
          <td class="meta"><%=r[7].length()>0?r[7]:"&mdash;"%></td>
          <td><span class="pill <%=r[9]%>"><span class="d"></span><%=r[8]%></span></td>
        </tr>
        <%}%>
      </tbody>
    </table>
    <div class="tablefoot">
      <span id="showCount">Showing <%=rows.size()%> of <%=cntTotal%></span>
      <button class="btn2 sm" onclick="submitPageDataForm('<%=SubmitType.SEARCH%>','<%=_searchBean.getController()%>')">&#8635; Refresh</button>
    </div>
  </div>
</div>

<div class="da-toast" id="daToast"></div>

<script>
mvpxListInit({
  ctrl: '<%=_searchBean.getController()%>',
  from: '<%=_searchBean.getSrhFromDate()%>',
  to:   '<%=_searchBean.getSrhToDate()%>',
  summary: { key:'type', label:'By type', filterId:'filterType' },
  filters: [
    { id:'filterEmp',    key:'emp',  label:'Employee', mode:'includes' },
    { id:'filterType',   key:'type', label:'Type',     mode:'exact' },
    { id:'filterStatus', key:'st',   label:'Status',   mode:'exact' }
  ]
});
</script>

<%
/* ═══════════════ RECORD FORM VIEWS (unchanged legacy) ═══════════════ */
} else {
%>

<script>
function validatePageData(submitType, isValid) {

	if(submitType == <%=SubmitType.CREATE_CONFIRM%>) {
		if(isValid) {
			var mandatoryFieldsArray = new Array();
			var numOfRows = parseInt(document.formmain["numOfRows"].value);
			for(var i=0; i<numOfRows; i++) {
				if(i == 0) {
					mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["employeeID"+i], "Employee");
					mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["dateOfIncident"+i], "Date");
					mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["timeOfIncident"+i], "Time");
					mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["reportedTimeOfIncident"+i], "Reported");
					mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["incidentType"+i], "Type");
					mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["incidentLocation"+i], "Location");
					//mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["emtNumber"+i], "EMT Num");
				} else {
					if(document.formmain["employeeID"+i].value.length > 0) {
					mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["employeeID"+i], "Employee");
						mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["dateOfIncident"+i], "Date");
						mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["timeOfIncident"+i], "Time");
						mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["reportedTimeOfIncident"+i], "Reported");
						mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["incidentType"+i], "Type");
						mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["incidentLocation"+i], "Location");
						//mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["emtNumber"+i], "EMT Num");
					}
				}
			}
			isValid = validateMandatoryFieldsInForm(mandatoryFieldsArray, isValid);
		}

	} else if(submitType == <%=SubmitType.UPDATE_CONFIRM%>) {
		if(isValid) {
			var mandatoryFieldsArray = new Array();
			mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["employeeID"], "Employee");
			mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["dateOfIncident"], "Date");
			mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["timeOfIncident"], "Time");
			mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["reportedTimeOfIncident"], "Reported");
			mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["incidentType"], "Type");
			mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["incidentLocation"], "Location");
			//mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["emtNumber"], "EMT Num");
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
			<input type="hidden" id="employeeIncidentID" name="employeeIncidentID" value="<%=_recordBean.getEmployeeIncidentID()%>">
			<%if(submitType == SubmitType.CREATE) {%>
				<input type="hidden" id="dynamicParams" name="dynamicParams" value="dateOfIncident,timeOfIncident,reportedTimeOfIncident,employeeID,incidentType,incidentLocation,incidentDescription,emtNumber">
				<div class="row">
					<div class="col-12">
						<div class='card'>
							<div class='card-body m-1 p-1'>
								<table width="100%" border="0" cellpadding="0" cellspacing="0" class="table table-bordered table-striped table-hover table-sm table-block table-vertical sortable mb-0">
									<input type="hidden" id="numOfRows" name="numOfRows" value="10">
									<thead class="thead-block">
										<tr class="tr-block">
											<th class="th-block table-header-label text-center required" width="20%">Employee</th>
											<th class="th-block table-header-label text-center required" width="8%">Date</th>
											<th class="th-block table-header-label text-center required" width="8%">Time</th>
											<th class="th-block table-header-label text-center required" width="8%">Reported</th>
											<th class="th-block table-header-label text-center required" width="10%">Type</th>
											<th class="th-block table-header-label text-center required" width="15%">Location</th>
											<th class="th-block table-header-label text-center" width="23%">Desc</th>
											<th class="th-block table-header-label text-center" width="8%">EMT Num</th>
										</tr>
									</thead>
									<tbody class="tbody-block">
										<%for(int i=0; i<10; i++) {%>
										<tr class="tr-block">
											<td class="td-block table-value" data-th="Employee"><select id="employeeID<%=i%>" name="employeeID<%=i%>" class="form-control form-control-sm"></select></td>
											<td class="td-block table-value" data-th="Date"><input type="text" id="dateOfIncident<%=i%>" name="dateOfIncident<%=i%>" class="form-control form-control-sm datepicker" value=""></td>
											<td class="td-block table-value" data-th="Time">
												<div class="row col-12 m-0 p-0">
													<input type="hidden" id="timeOfIncident<%=i%>" name="timeOfIncident<%=i%>" class="form-control form-control-sm" value="">
													<div class="col-7 m-0 p-0"><input type="text" id="timeOfIncident<%=i%>Txt" name="timeOfIncident<%=i%>Txt" class="form-control form-control-sm" value="" placeholder="Time" onChange="fixTime('timeOfIncident<%=i%>');"></div>
													<div class="col-5 m-0 p-0"><select id="timeOfIncident<%=i%>Sel" name="timeOfIncident<%=i%>Sel" class="form-control form-control-sm" onChange="fixTime('timeOfIncident<%=i%>');"><option value="AM">AM</option><option value="PM">PM</option></select>
												</div>
											</td>
											<td class="td-block table-value" data-th="Reported">
												<div class="row col-12 m-0 p-0">
													<input type="hidden" id="reportedTimeOfIncident<%=i%>" name="reportedTimeOfIncident<%=i%>" class="form-control form-control-sm" value="">
													<div class="col-7 m-0 p-0"><input type="text" id="reportedTimeOfIncident<%=i%>Txt" name="reportedTimeOfIncident<%=i%>Txt" class="form-control form-control-sm" value="" placeholder="Reported Time" onChange="fixTime('reportedTimeOfIncident<%=i%>');"></div>
													<div class="col-5 m-0 p-0"><select id="reportedTimeOfIncident<%=i%>Sel" name="reportedTimeOfIncident<%=i%>Sel" class="form-control form-control-sm" onChange="fixTime('reportedTimeOfIncident<%=i%>');"><option value="AM">AM</option><option value="PM">PM</option></select>
												</div>
											</td>
											<td class="td-block table-value" data-th="Type"><select id="incidentType<%=i%>" name="incidentType<%=i%>" class="form-control form-control-sm">
												<option value=""></option>
											</select></td>
											<td class="td-block table-value" data-th="Location"><select id="incidentLocation<%=i%>" name="incidentLocation<%=i%>" class="form-control form-control-sm">
												<option value=""></option>
											</select></td>
											<td class="td-block table-value" data-th="Desc"><textarea id="incidentDescription<%=i%>" name="incidentDescription<%=i%>" class="form-control form-control-sm" rows="1"></textarea></td>
											<td class="td-block table-value" data-th="EMT Num"><input type="text" id="emtNumber<%=i%>" name="emtNumber<%=i%>" class="form-control form-control-sm" value=""></td>
										</tr>
										<script>
											initSelect2Suggestor("employees", "employeeID<%=i%>", "", false, "");
											initSelect2SuggestorConvert("incidentType<%=i%>", "", true);
											initSelect2SuggestorConvert("incidentLocation<%=i%>", "", true);
										</script>
										<%}%>
									</tbody>
								</table>
							</div>
						</div>
					</div>
				</div>

			<%} else if(submitType == SubmitType.UPDATE) {
				String timeVal = "", timeSel = "";
				String reportedVal = "", reportedSel = "";
				if(_recordBean.getTimeOfIncident().length() > 0) {
					String splitArray[] = _recordBean.getTimeOfIncident().split(" ");
					if(splitArray.length == 2) {
						timeVal = splitArray[0].trim();
						timeSel = splitArray[1].trim();
					}
				}
				if(_recordBean.getReportedTimeOfIncident().length() > 0) {
					String splitArray[] = _recordBean.getReportedTimeOfIncident().split(" ");
					if(splitArray.length == 2) {
						reportedVal = splitArray[0].trim();
						reportedSel = splitArray[1].trim();
					}
				}%>
				<div class="row">
					<div class="col-12 col-md-5">
						<div class="row form-row form-group form-group-sm">
							<label class="col-12 col-md-3 col-form-label required text-left">Employee</label>
							<div class="col-12 col-md-9 text-left"><select id="employeeID" name="employeeID" class="form-control form-control-sm">
								<option value=""></option>
							</select></div>
						</div>
						<div class="row form-row form-group form-group-sm">
							<label class="col-12 col-md-3 col-form-label required text-left">Date</label>
							<div class="col-12 col-md-9 text-left"><input type="text" id="dateOfIncident" name="dateOfIncident" class="form-control form-control-sm datepicker" value="<%=_recordBean.getDateOfIncident()%>"></div>
						</div>
						<div class="row form-row form-group form-group-sm">
							<label class="col-12 col-md-3 col-form-label required text-left">Time</label>
							<div class="col-12 col-md-9 text-left">
								<div class="row col-12 m-0 p-0">
									<input type="hidden" id="timeOfIncident" name="timeOfIncident" class="form-control form-control-sm" value="<%=_recordBean.getTimeOfIncident()%>">
									<div class="col-7 m-0 p-0"><input type="text" id="timeOfIncidentTxt" name="timeOfIncidentTxt" class="form-control form-control-sm" value="<%=timeVal%>" placeholder="Time" onChange="fixTime('timeOfIncident');"></div>
									<div class="col-5 m-0 p-0"><select id="timeOfIncidentSel" name="timeOfIncidentSel" class="form-control form-control-sm"  onChange="fixTime('timeOfIncident');"><option value="AM" <%if("AM".equalsIgnoreCase(timeSel)) {%>selected<%}%>>AM</option><option value="PM" <%if("PM".equalsIgnoreCase(timeSel)) {%>selected<%}%>>PM</option></select></div>
								</div>
							</div>
						</div>
						<div class="row form-row form-group form-group-sm">
							<label class="col-12 col-md-3 col-form-label required text-left">Reported</label>
							<div class="col-12 col-md-9 text-left">
								<div class="row col-12 m-0 p-0">
									<input type="hidden" id="reportedTimeOfIncident" name="reportedTimeOfIncident" class="form-control form-control-sm" value="<%=_recordBean.getReportedTimeOfIncident()%>">
									<div class="col-7 m-0 p-0"><input type="text" id="reportedTimeOfIncidentTxt" name="reportedTimeOfIncidentTxt" class="form-control form-control-sm" value="<%=reportedVal%>" placeholder="Reported Time" onChange="fixTime('reportedTimeOfIncident');"></div>
									<div class="col-5 m-0 p-0"><select id="reportedTimeOfIncidentSel" name="reportedTimeOfIncidentSel" class="form-control form-control-sm"  onChange="fixTime('reportedTimeOfIncident');"><option value="AM" <%if("AM".equalsIgnoreCase(reportedSel)) {%>selected<%}%>>AM</option><option value="PM" <%if("PM".equalsIgnoreCase(reportedSel)) {%>selected<%}%>>PM</option></select></div>
								</div>
							</div>
						</div>
					</div>

					<div class="col-12 col-md-2"></div>

					<div class="col-12 col-md-5">
						<div class="row form-row form-group form-group-sm">
							<label class="col-12 col-md-3 col-form-label required text-left">EMT Num</label>
							<div class="col-12 col-md-9 text-left"><input type="text" id="emtNumber" name="emtNumber" class="form-control form-control-sm" value="<%=_recordBean.getEmtNumber()%>"></div>
						</div>
						<div class="row form-row form-group form-group-sm">
							<label class="col-12 col-md-3 col-form-label required text-left">Type</label>
							<div class="col-12 col-md-9 text-left"><select id="incidentType" name="incidentType" class="form-control form-control-sm">
								<option value=""></option>
							</select></div>
						</div>
						<div class="row form-row form-group form-group-sm">
							<label class="col-12 col-md-3 col-form-label required text-left">Location</label>
							<div class="col-12 col-md-9 text-left"><select id="incidentLocation" name="incidentLocation" class="form-control form-control-sm">
								<option value=""></option>
							</select></div>
						</div>
						<div class="row form-row form-group form-group-sm">
							<label class="col-12 col-md-3 col-form-label text-left">Desc</label>
							<div class="col-12 col-md-9 text-left"><textarea id="incidentDescription" name="incidentDescription" class="form-control form-control-sm"><%=_recordBean.getIncidentDescription()%></textarea></div>
						</div>
					</div>
				</div>

				<script>
					initSelect2Suggestor("employees", "employeeID", "<%=_recordBean.getEmployeeID()%>", false, "");
					initSelect2SuggestorConvert("incidentType", "", true);
					setSelect2Option("incidentType", "<%=_recordBean.getIncidentType()%>");
					initSelect2SuggestorConvert("incidentLocation", "", true);
					setSelect2Option("incidentLocation", "<%=_recordBean.getIncidentLocation()%>");
				</script>


			<%} else if(submitType == SubmitType.BROWSE) {%>
				<div class="row">
					<div class="col-12 col-md-5">
						<div class="row">
							<label class="col-5 col-md-3 col-form-label text-left">Employee</label>
							<div class="col-7 col-md-9 form-control-plaintext text-left"><%=_recordBean.getEmployeeName()%></div>
						</div>
						<div class="row">
							<label class="col-5 col-md-3 col-form-label text-left">Date</label>
							<div class="col-7 col-md-9 form-control-plaintext text-left"><%=_recordBean.getDateOfIncident()%></div>
						</div>
						<div class="row">
							<label class="col-5 col-md-3 col-form-label text-left">Time</label>
							<div class="col-7 col-md-9 form-control-plaintext text-left"><%=_recordBean.getTimeOfIncident()%></div>
						</div>
						<div class="row">
							<label class="col-5 col-md-3 col-form-label text-left">Reported</label>
							<div class="col-7 col-md-9 form-control-plaintext text-left"><%=_recordBean.getReportedTimeOfIncident()%></div>
						</div>
					</div>

					<div class="col-12 col-md-2"></div>

					<div class="col-12 col-md-5">
						<div class="row">
							<label class="col-5 col-md-3 col-form-label text-left">EMT Num</label>
							<div class="col-7 col-md-9 form-control-plaintext text-left"><%=_recordBean.getEmtNumber()%></div>
						</div>
						<div class="row">
							<label class="col-5 col-md-3 col-form-label text-left">Type</label>
							<div class="col-7 col-md-9 form-control-plaintext text-left"><%=_recordBean.getIncidentType()%></div>
						</div>
						<div class="row">
							<label class="col-5 col-md-3 col-form-label text-left">Location</label>
							<div class="col-7 col-md-9 form-control-plaintext text-left"><%=_recordBean.getIncidentLocation()%></div>
						</div>
						<div class="row">
							<label class="col-5 col-md-3 col-form-label text-left">Desc</label>
							<div class="col-7 col-md-9 form-control-plaintext text-left"><%=_recordBean.getIncidentDescription()%></div>
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
						<button class="btn btn-success text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.CREATE_CONFIRM%>','<%=_recordBean.getController()%>','<%=_recordBean.getEmployeeIncidentID()%>');">Save</button>
						<button class="btn btn-success text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.CREATE_CONFIRM%>','<%=_recordBean.getController()%>','<%=_recordBean.getEmployeeIncidentID()%>','2');">Save & Post</button></div>
					<%} else {%>
						<button class="btn btn-success text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.UPDATE_CONFIRM%>','<%=_recordBean.getController()%>','<%=_recordBean.getEmployeeIncidentID()%>');">Save</button>
						<button class="btn btn-success text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.UPDATE_CONFIRM%>','<%=_recordBean.getController()%>','<%=_recordBean.getEmployeeIncidentID()%>','2');">Save & Post</button></div>
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
					<button class="btn btn-primary text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.UPDATE%>','<%=_recordBean.getController()%>','<%=_recordBean.getEmployeeIncidentID()%>');">Edit</button>
				<%}%>
				</div>
				<div class="col-4 text-right">
				<%if("0".equalsIgnoreCase(_recordBean.getStatus())) {%>
					<button class="btn btn-danger text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.DELETE%>','<%=_recordBean.getController()%>','<%=_recordBean.getEmployeeIncidentID()%>');">Delete</button>
				<%}%>
				</div>
			</div>
		<%}%>
	</div>
</div>
<%@ include file="includeFooter.jsp"%>
<%}%>