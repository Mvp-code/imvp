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
<jsp:useBean id="_recordBean" class="com.beans.Incident" scope="request" />
<%
/* ═══════════════ LIST VIEW (redesigned — MVPx list standard) ═══════════════ */
if (submitType == SubmitType.SEARCH) {
    List dataList = _searchBean.getDataList() == null ? new ArrayList() : _searchBean.getDataList();
    int cntTotal = dataList.size(), cntPosted = 0;
    List<String> catNames  = new ArrayList<String>();
    List<String> typeNames = new ArrayList<String>();
    List<String> empNames  = new ArrayList<String>();
    List<String> vehNames  = new ArrayList<String>();
    /* [0]=id 1=date 2=category 3=type 4=employee 5=vehicle 6=desc 7=status 8=pill */
    List<String[]> rows = new ArrayList<String[]>();
    for (int i = 0; i < dataList.size(); i++) {
        List r = (List) dataList.get(i);
        String[] c = new String[9];
        for (int j = 0; j < 8 && j < r.size(); j++)
            c[j] = r.get(j) == null ? "" : r.get(j).toString().trim();
        for (int j = 0; j < 9; j++) if (c[j] == null) c[j] = "";
        String pill = "amber";
        if ("Posted".equalsIgnoreCase(c[7])) { pill = "blue"; cntPosted++; }
        c[8] = pill;
        if (c[2].length() > 0 && !catNames.contains(c[2]))  catNames.add(c[2]);
        if (c[3].length() > 0 && !typeNames.contains(c[3])) typeNames.add(c[3]);
        if (c[4].length() > 0 && !empNames.contains(c[4]))  empNames.add(c[4]);
        if (c[5].length() > 0 && !vehNames.contains(c[5]))  vehNames.add(c[5]);
        rows.add(c);
    }
    Collections.sort(catNames); Collections.sort(typeNames);
    Collections.sort(empNames); Collections.sort(vehNames);
%>
<%@ include file="includeHeader.jsp"%>
<link rel="stylesheet" href="../jsp/assets/css/mvpx-list.css?v=20260916d">
<script src="../jsp/assets/js/mvpx-list.js?v=20260911b"></script>

<div class="da-wrap">

  <div class="da-headrow">
    <div>
      <h2>Incidents</h2>
      <div class="statchips">
        <span class="statchip"><span class="dot" style="background:var(--da-blue)"></span><b><%=cntTotal%></b> incidents</span>
        <span class="statchip"><span class="dot" style="background:#64748B"></span><b><%=cntPosted%></b> posted</span>
      </div>
    </div>
    <div style="display:flex;gap:7px;align-items:center;flex-wrap:wrap">
      <button class="btn2" onclick="mvpxPrint('xls')" title="Export to Excel"><i class="fas fa-file-excel"></i> Excel</button>
      <button class="btn2" onclick="mvpxPrint('')" title="Download PDF"><i class="fas fa-file-pdf"></i> PDF</button>
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
    <select class="da-flt" id="filterCat" onchange="mvpxApplyFilters()">
      <option value="">All categories</option>
      <%for(String v : catNames){%><option value="<%=v.toLowerCase()%>"><%=v%></option><%}%>
    </select>
    <select class="da-flt" id="filterType" onchange="mvpxApplyFilters()">
      <option value="">All types</option>
      <%for(String v : typeNames){%><option value="<%=v.toLowerCase()%>"><%=v%></option><%}%>
    </select>
    <select class="da-flt" id="filterEmp" onchange="mvpxApplyFilters()" style="min-width:160px">
      <option value="">All employees</option>
      <%for(String v : empNames){%><option value="<%=v.toLowerCase()%>"><%=v%></option><%}%>
    </select>
    <select class="da-flt" id="filterVeh" onchange="mvpxApplyFilters()">
      <option value="">All vehicles</option>
      <%for(String v : vehNames){%><option value="<%=v.toLowerCase()%>"><%=v%></option><%}%>
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
          <th class="srt" onclick="mvpxSort(this)">Date<span class="ar"></span></th>
          <th class="srt" onclick="mvpxSort(this)">Category<span class="ar"></span></th>
          <th class="srt" onclick="mvpxSort(this)">Type<span class="ar"></span></th>
          <th class="srt" onclick="mvpxSort(this)">Employee<span class="ar"></span></th>
          <th class="srt" onclick="mvpxSort(this)">Vehicle<span class="ar"></span></th>
          <th class="srt" onclick="mvpxSort(this)">Description<span class="ar"></span></th>
          <th class="srt" onclick="mvpxSort(this)">Status<span class="ar"></span></th>
        </tr>
      </thead>
      <tbody id="ciRows">
        <%if(rows.isEmpty()){%>
        <tr><td colspan="7" class="da-empty">No incidents for this date range.</td></tr>
        <%}%>
        <%for(String[] r : rows){%>
        <tr data-id="<%=r[0]%>"
            data-cat="<%=r[2].toLowerCase()%>"
            data-type="<%=r[3].toLowerCase()%>"
            data-emp="<%=r[4].toLowerCase()%>"
            data-veh="<%=r[5].toLowerCase()%>">
          <td class="nm"><a href="javascript:void(0)" style="color:inherit" onclick="submitPageDataForm('<%=SubmitType.BROWSE%>','<%=_searchBean.getController()%>','<%=r[0]%>')"><%=r[1]%></a></td>
          <td><%=r[2]%></td>
          <td><%=r[3]%></td>
          <td><%=r[4].length()>0?r[4]:"&mdash;"%></td>
          <td class="meta"><%=r[5].length()>0?r[5]:"&mdash;"%></td>
          <td class="meta"><%=r[6].length()>0?r[6]:"&mdash;"%></td>
          <td><span class="pill <%=r[8]%>"><span class="d"></span><%=r[7]%></span></td>
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
    { id:'filterCat',  key:'cat',  label:'Category', mode:'exact' },
    { id:'filterType', key:'type', label:'Type',     mode:'exact' },
    { id:'filterEmp',  key:'emp',  label:'Employee', mode:'includes' },
    { id:'filterVeh',  key:'veh',  label:'Vehicle',  mode:'exact' }
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
			mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["incidentDate"], "Date");
			mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["incidentCategoryID"], "Category");

			var numOfRows = parseInt(document.formmain["numOfRows"].value);
			for(var i=0; i<numOfRows; i++) {
				if(i == 0) {
					mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["employeeID"+i], "Employee");
					mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["vehicleID"+i], "Vehicle");
					mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["incidentTypeID"+i], "Type");
					mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["incidentDesc"+i], "Description");
				} else {
					if(document.formmain["employeeID"+i].value.length > 0 || document.formmain["vehicleID"+i].value.length > 0 || document.formmain["incidentTypeID"+i].value.length > 0) {
						mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["employeeID"+i], "Employee");
						mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["vehicleID"+i], "Vehicle");
						mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["incidentTypeID"+i], "Type");
						mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["incidentDesc"+i], "Description");
					}
				}
			}

			isValid = validateMandatoryFieldsInForm(mandatoryFieldsArray, isValid);
		}

	} else if(submitType == <%=SubmitType.UPDATE_CONFIRM%>) {
		if(isValid) {
			var mandatoryFieldsArray = new Array();
			mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["incidentDate"], "Date");
			mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["incidentCategoryID"], "Category");
			mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["incidentTypeID"], "Type");
			mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["incidentDesc"], "Description");
			mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["employeeID"], "Employee");
			mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["vehicleID"], "Vehicle");
			isValid = validateMandatoryFieldsInForm(mandatoryFieldsArray, isValid);
		}

	} else if(submitType == <%=SubmitType.DELETE%>) {
		isValid = deleteRecord();
	}

	return isValid;
}
</script>

<%@ include file="includeHeader.jsp"%>
<link rel="stylesheet" href="../jsp/assets/css/mvpx-list.css?v=20260916d">
<style>
/* Incident form — MVPx modern (matches DA Checkin) */
.if-crumb{font-size:13px;color:var(--da-muted);margin-bottom:10px}
.if-crumb .tag{background:var(--da-blue-50);color:var(--da-blue-dark);font-weight:700;font-size:12px;padding:2px 8px;border-radius:6px}
.if-head h2{margin:0 0 12px;font-size:28px;font-weight:700;color:#111827}
.if-card{background:#fff;border:1px solid var(--da-line);border-radius:11px;box-shadow:var(--da-shadow);padding:18px 20px}
.if-grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:14px 30px}
@media(max-width:820px){.if-grid{grid-template-columns:1fr}}
.if-fld{display:flex;flex-direction:column;gap:6px}
.if-fld label{font-size:13px;font-weight:700;color:#374151}
.if-fld label .req{color:#DC2626}
.if-fld input,.if-fld textarea{border:1px solid var(--da-line);border-radius:8px;padding:9px 11px;font-size:14px;font-family:inherit;color:#111827;background:#fff;width:100%}
.if-fld input:focus,.if-fld textarea:focus{outline:none;border-color:var(--da-blue);box-shadow:0 0 0 3px var(--da-blue-50)}
.if-fld .plain{font-size:14.5px;color:#111827;padding:8px 0}
.if-sec{font-size:13px;font-weight:800;color:#111827;margin:18px 0 8px}
.if-tbl{border:1px solid var(--da-line);border-radius:10px;overflow:auto;margin-top:6px}
.if-tbl table{width:100%;border-collapse:collapse;min-width:640px}
.if-tbl th{text-align:left;font-size:13px;font-weight:700;color:#111827;background:#FAFCFF;padding:10px 12px;border-bottom:1px solid var(--da-line);white-space:nowrap}
.if-tbl th .req{color:#DC2626}
.if-tbl td{padding:7px 12px;border-bottom:1px solid var(--da-line-soft);vertical-align:middle}
.if-tbl tr:last-child td{border-bottom:none}
.if-tbl input{border:1px solid var(--da-line);border-radius:7px;padding:7px 9px;font-size:13.5px;font-family:inherit;color:#111827;background:#fff;width:100%}
.if-tbl input:focus{outline:none;border-color:var(--da-blue);box-shadow:0 0 0 3px var(--da-blue-50)}
.if-actions{display:flex;gap:8px;align-items:center;margin-top:16px}
.if-actions .spacer{flex:1}
/* select2 widgets fill the field/cell width and match the input look */
.if-fld .select2-container,.if-tbl .select2-container{width:100%!important}
.if-fld .select2-container--default .select2-selection--single,
.if-tbl .select2-container--default .select2-selection--single{height:38px;border:1px solid var(--da-line);border-radius:8px;display:flex;align-items:center}
.if-tbl .select2-container--default .select2-selection--single{height:34px;border-radius:7px}
.if-fld .select2-selection__rendered,.if-tbl .select2-selection__rendered{line-height:normal;color:#111827}
</style>

<div class="da-wrap">
  <div class="if-crumb"><span class="tag">Operation</span> / <strong><%= submitType==SubmitType.CREATE ? "New Incident" : (submitType==SubmitType.UPDATE ? "Edit Incident" : "Incident") %></strong></div>
  <div class="if-head"><h2><%= submitType==SubmitType.CREATE ? "New Incident" : (submitType==SubmitType.UPDATE ? "Edit Incident" : "View Incident") %></h2></div>

  <%if(_errorBean != null && _errorBean.getType().length() > 0) {%>
    <div class="row text-center mb-2"><section class='alert_section'><div class='alert-box <%=_errorBean.getType()%>Color'><%=_errorBean.getMesg()%></div></section></div>
  <%}%>

  <input type="hidden" id="incidentID" name="incidentID" value="<%=_recordBean.getIncidentID()%>">

  <div class="if-card">
  <%if(submitType == SubmitType.CREATE) {%>
    <div class="if-grid">
      <div class="if-fld"><label>Date <span class="req">*</span></label><input type="text" id="incidentDate" name="incidentDate" class="datepicker" value="<%=_recordBean.getIncidentDate()%>" placeholder="MM/DD/YYYY"></div>
      <div class="if-fld"><label>Category <span class="req">*</span></label><select id="incidentCategoryID" name="incidentCategoryID"></select></div>
      <div class="if-fld"><label>DSP Code</label><div class="plain">MVPG</div></div>
    </div>

    <div class="if-sec">Incident rows</div>
    <div class="if-tbl">
      <table>
        <input type="hidden" id="numOfRows" name="numOfRows" value="10">
        <input type="hidden" id="dynamicParams" name="dynamicParams" value="incidentTypeID,incidentDesc,employeeID,vehicleID">
        <thead><tr>
          <th style="width:15%">Employee <span class="req">*</span></th>
          <th style="width:15%">Vehicle <span class="req">*</span></th>
          <th style="width:20%">Type <span class="req">*</span></th>
          <th style="width:50%">Description <span class="req">*</span></th>
        </tr></thead>
        <tbody>
          <%for(int i=0; i<10; i++) {
            String employeeID = "";
            String vehicleID = "";
            if(i == 0) { employeeID = _recordBean.getEmployeeID(); vehicleID = _recordBean.getVehicleID(); }%>
          <tr>
            <td><select id="employeeID<%=i%>" name="employeeID<%=i%>"></select></td>
            <td><select id="vehicleID<%=i%>" name="vehicleID<%=i%>"></select></td>
            <td><select id="incidentTypeID<%=i%>" name="incidentTypeID<%=i%>"></select></td>
            <td><input type="text" id="incidentDesc<%=i%>" name="incidentDesc<%=i%>" value=""></td>
          </tr>
          <script>
            initSelect2Suggestor("employees", "employeeID<%=i%>", "<%=employeeID%>", false, "");
            initSelect2Suggestor("vehicles", "vehicleID<%=i%>", "<%=vehicleID%>", false, "");
            initSelect2Suggestor("incidentTypes", "incidentTypeID<%=i%>", "", false, "");
          </script>
          <%}%>
        </tbody>
      </table>
    </div>
    <script>
      initSelect2Suggestor("incidentCategories", "incidentCategoryID", "<%=_recordBean.getIncidentCategoryID()%>", false, "");
    </script>

  <%} else if(submitType == SubmitType.UPDATE) {%>
    <div class="if-grid">
      <div class="if-fld"><label>Date <span class="req">*</span></label><input type="text" id="incidentDate" name="incidentDate" class="datepicker" value="<%=_recordBean.getIncidentDate()%>"></div>
      <div class="if-fld"><label>Category <span class="req">*</span></label><select id="incidentCategoryID" name="incidentCategoryID"></select></div>
      <div class="if-fld"><label>Type <span class="req">*</span></label><select id="incidentTypeID" name="incidentTypeID"></select></div>
      <div class="if-fld"><label>Employee <span class="req">*</span></label><select id="employeeID" name="employeeID"></select></div>
      <div class="if-fld"><label>Vehicle <span class="req">*</span></label><select id="vehicleID" name="vehicleID"></select></div>
      <div class="if-fld"><label>Description <span class="req">*</span></label><input type="text" id="incidentDesc" name="incidentDesc" value="<%=_recordBean.getIncidentDesc()%>"></div>
      <div class="if-fld"><label>DSP Code</label><div class="plain">MVPG</div></div>
    </div>
    <script>
      initSelect2Suggestor("incidentCategories", "incidentCategoryID", "<%=_recordBean.getIncidentCategoryID()%>", false, "");
      initSelect2Suggestor("incidentTypes", "incidentTypeID", "<%=_recordBean.getIncidentTypeID()%>", false, "");
      initSelect2Suggestor("employees", "employeeID", "<%=_recordBean.getEmployeeID()%>", false, "");
      initSelect2Suggestor("vehicles", "vehicleID", "<%=_recordBean.getVehicleID()%>", false, "");
    </script>

  <%} else if(submitType == SubmitType.BROWSE) {%>
    <div class="if-grid">
      <div class="if-fld"><label>Date</label><div class="plain"><%=_recordBean.getIncidentDate()%></div></div>
      <div class="if-fld"><label>Category</label><div class="plain"><%=_recordBean.getIncidentCategoryName()%></div></div>
      <div class="if-fld"><label>Type</label><div class="plain"><%=_recordBean.getIncidentTypeName()%></div></div>
      <div class="if-fld"><label>Employee</label><div class="plain"><%=_recordBean.getEmployeeName()%></div></div>
      <div class="if-fld"><label>Vehicle</label><div class="plain"><%=_recordBean.getVehicleName()%></div></div>
      <div class="if-fld"><label>Description</label><div class="plain"><%=_recordBean.getIncidentDesc()%></div></div>
      <div class="if-fld"><label>DSP Code</label><div class="plain">MVPG</div></div>
    </div>
  <%}%>
  </div>

  <%if(submitType == SubmitType.CREATE || submitType == SubmitType.UPDATE) {
      int _cType = (submitType==SubmitType.CREATE) ? SubmitType.CREATE_CONFIRM : SubmitType.UPDATE_CONFIRM;%>
    <div class="if-actions">
      <button class="btn2" onClick="Javascript:submitPageDataForm('<%=SubmitType.SEARCH%>','<%=_recordBean.getController()%>','');">&larr; Back to list</button>
      <span class="spacer"></span>
      <button class="btn2 success" onClick="Javascript:submitPageDataForm('<%=_cType%>','<%=_recordBean.getController()%>','<%=_recordBean.getIncidentID()%>');"><i class="fas fa-check"></i> Save</button>
      <button class="btn2 success" onClick="Javascript:submitPageDataForm('<%=_cType%>','<%=_recordBean.getController()%>','<%=_recordBean.getIncidentID()%>','2');"><i class="fas fa-check-double"></i> Save &amp; Post</button>
    </div>
  <%} else if(submitType == SubmitType.BROWSE) {%>
    <div class="if-actions">
      <button class="btn2" onClick="Javascript:submitPageDataForm('<%=SubmitType.SEARCH%>','<%=_recordBean.getController()%>','');">&larr; Back to list</button>
      <span class="spacer"></span>
      <%if("0".equalsIgnoreCase(_recordBean.getStatus())) {%>
        <button class="btn2 primary" onClick="Javascript:submitPageDataForm('<%=SubmitType.UPDATE%>','<%=_recordBean.getController()%>','<%=_recordBean.getIncidentID()%>');"><i class="fas fa-pen"></i> Edit</button>
        <button class="btn2 danger" onClick="Javascript:submitPageDataForm('<%=SubmitType.DELETE%>','<%=_recordBean.getController()%>','<%=_recordBean.getIncidentID()%>');"><i class="fas fa-trash"></i> Delete</button>
      <%}%>
    </div>
  <%}%>
</div>
<%@ include file="includeFooter.jsp"%>
<%}%>
