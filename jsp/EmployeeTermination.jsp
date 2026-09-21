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
<jsp:useBean id="_recordBean" class="com.beans.EmployeeTermination" scope="request" />
<%
/* ═══════════════ LIST VIEW (redesigned — MVPx list standard) ═══════════════ */
if (submitType == SubmitType.SEARCH) {
    List dataList = _searchBean.getDataList() == null ? new ArrayList() : _searchBean.getDataList();
    int cntTotal = dataList.size(), cntPosted = 0;
    List<String> empNames  = new ArrayList<String>();
    List<String> typeNames = new ArrayList<String>();
    List<String> stNames   = new ArrayList<String>();
    /* [0]=id 1=emp 2=date 3=type 4=reason 5=comments 6=status 7=pill */
    List<String[]> rows = new ArrayList<String[]>();
    for (int i = 0; i < dataList.size(); i++) {
        List r = (List) dataList.get(i);
        String id      = r.get(0) == null ? "" : r.get(0).toString().trim();
        String emp     = r.get(1) == null ? "" : r.get(1).toString().trim();
        String dt      = r.get(2) == null ? "" : r.get(2).toString().trim();
        String type    = r.get(3) == null ? "" : r.get(3).toString().trim();
        String reason  = r.get(4) == null ? "" : r.get(4).toString().trim();
        String cmts    = r.get(5) == null ? "" : r.get(5).toString().trim();
        String status  = r.get(6) == null ? "" : r.get(6).toString().trim();
        String pill = "slate";
        if ("Active".equalsIgnoreCase(status)) pill = "amber";
        else if (status.toLowerCase().startsWith("post")) { pill = "red"; cntPosted++; }
        if (emp.length() > 0 && !empNames.contains(emp)) empNames.add(emp);
        if (type.length() > 0 && !typeNames.contains(type)) typeNames.add(type);
        if (status.length() > 0 && !stNames.contains(status)) stNames.add(status);
        rows.add(new String[]{ id, emp, dt, type, reason, cmts, status, pill });
    }
    Collections.sort(empNames); Collections.sort(typeNames); Collections.sort(stNames);
%>
<%@ include file="includeHeader.jsp"%>
<link rel="stylesheet" href="../jsp/assets/css/mvpx-list.css?v=20260921c">
<script src="../jsp/assets/js/mvpx-list.js?v=20260921c"></script>

<div class="da-wrap">

  <div class="da-headrow">
    <div>
      <h2>Terminations</h2>
      <div class="statchips">
        <span class="statchip"><span class="dot" style="background:var(--da-blue)"></span><b><%=cntTotal%></b> records</span>
        <span class="statchip"><span class="dot" style="background:var(--da-red)"></span><b><%=cntPosted%></b> posted</span>
      </div>
    </div>
    <div style="display:flex;gap:7px;align-items:center;flex-wrap:wrap">
      <%if(_searchBean.isDisplayPostBtn()){%>
      <button class="btn2 success" onclick="mvpxBulk(<%=SubmitType.FINAL%>,'post')"><i class="fas fa-check"></i> Post</button>
      <%}%>
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
          <th>Type</th>
          <th>Reason</th>
          <th>Comments</th>
          <th>Status</th>
        </tr>
      </thead>
      <tbody id="ciRows">
        <%if(rows.isEmpty()){%>
        <tr><td colspan="7" class="da-empty">No terminations for this date range.</td></tr>
        <%}%>
        <%for(String[] r : rows){%>
        <tr data-id="<%=r[0]%>"
            data-emp="<%=r[1].toLowerCase()%>"
            data-type="<%=r[3].toLowerCase()%>"
            data-st="<%=r[6].toLowerCase()%>">
          <td><input type="checkbox" class="rowCheck" value="<%=r[0]%>"></td>
          <td class="nm"><a href="javascript:void(0)" style="color:inherit" onclick="submitPageDataForm('<%=SubmitType.BROWSE%>','<%=_searchBean.getController()%>','<%=r[0]%>')"><%=r[1]%></a></td>
          <td><%=r[2]%></td>
          <td><%=r[3]%></td>
          <td class="meta"><%=r[4].length()>0?r[4]:"&mdash;"%></td>
          <td class="meta"><%=r[5].length()>0?r[5]:"&mdash;"%></td>
          <td><span class="pill <%=r[7]%>"><span class="d"></span><%=r[6]%></span></td>
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
					mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["dateOfTermination"+i], "Date");
					mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["terminationType"+i], "Type");
					mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["terminationReason"+i], "Reason");
				} else {
					if(document.formmain["employeeID"+i].value.length > 0) {
						mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["employeeID"+i], "Employee");
						mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["dateOfTermination"+i], "Date");
						mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["terminationType"+i], "Type");
						mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["terminationReason"+i], "Reason");
					}
				}
			}
			isValid = validateMandatoryFieldsInForm(mandatoryFieldsArray, isValid);
		}

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
					<div class="col-2 text-right my-auto"><%if(submitType == SubmitType.BROWSE) {%><button class="btn btn-primary btn-sm" onClick="Javascript:submitPageDataForm('<%=SubmitType.CREATE%>','<%=_recordBean.getController()%>');" title="Create New">New</button><%}%></div>
				</div>
			</div>

			<%if(_errorBean != null && _errorBean.getType().length() > 0) {%>
				<div class="row text-center"><section class='alert_section'><div class='alert-box <%=_errorBean.getType()%>Color'><%=_errorBean.getMesg()%></div></section></div>
			<%}%>

			<div class='card-body m-1 p-1'>
			<input type="hidden" id="employeeTerminationID" name="employeeTerminationID" value="<%=_recordBean.getEmployeeTerminationID()%>">
			<%if(submitType == SubmitType.CREATE) {%>
				<input type="hidden" id="dynamicParams" name="dynamicParams" value="dateOfTermination,employeeID,terminationType,terminationReason,comments">
				<div class="row">
					<div class="col-1"></div>
					<div class="col-10">
						<div class='card'>
							<div class='card-body m-1 p-1'>
								<table width="100%" border="0" cellpadding="0" cellspacing="0" class="table table-bordered table-striped table-hover table-sm table-block table-vertical sortable mb-0">
									<input type="hidden" id="numOfRows" name="numOfRows" value="10">
									<thead class="thead-block">
										<tr class="tr-block">
											<th class="th-block table-header-label text-center required" width="20%">Employee</th>
											<th class="th-block table-header-label text-center required" width="14%">Date</th>
											<th class="th-block table-header-label text-center required" width="15%">Type</th>
											<th class="th-block table-header-label text-center required" width="15%">Reason</th>
											<th class="th-block table-header-label text-center" width="36%">Comments</th>
										</tr>
									</thead>
									<tbody class="tbody-block">
										<%for(int i=0; i<10; i++) {%>
										<tr class="tr-block">
											<td class="td-block table-value" data-th="Employee"><select id="employeeID<%=i%>" name="employeeID<%=i%>" class="form-control form-control-sm"></select></td>
											<td class="td-block table-value" data-th="Date"><input type="text" id="dateOfTermination<%=i%>" name="dateOfTermination<%=i%>" class="form-control form-control-sm datepicker" value=""></td>
											<td class="td-block table-value" data-th="Type"><select id="terminationType<%=i%>" name="terminationType<%=i%>" class="form-control form-control-sm">
												<option value=""></option>
												<option value="Terminated">Terminated</option>
												<option value="Quit">Quit</option>
											</select></td>
											<td class="td-block table-value" data-th="Reason"><select id="terminationReason<%=i%>" name="terminationReason<%=i%>" class="form-control form-control-sm">
												<option value=""></option>
												<option value="Damage">Damage</option>
												<option value="Safety">Safety</option>
												<option value="Tier-2 defect">Tier-2 defect</option>
												<option value="Callouts">Callouts</option>
												<option value="Quit">Quit</option>
											</select></td>
											<td class="td-block table-value" data-th="Comments"><textarea id="comments<%=i%>" name="comments<%=i%>" class="form-control form-control-sm" rows="1"></textarea></td>
										</tr>
										<script>
											initSelect2Suggestor("employees", "employeeID<%=i%>", "", false, "");
											initSelect2SuggestorConvert("terminationReason<%=i%>", "", true);
										</script>
										<%}%>
									</tbody>
								</table>
							</div>
						</div>
					</div>
					<div class="col-1"></div>
				</div>

			<%} else if(submitType == SubmitType.UPDATE) {%>
				<div class="row">
					<div class="col-5">
						<div class="row form-row form-group form-group-sm">
							<label class="col-3 col-form-label required text-left">Employee</label>
							<div class="col-9 text-left"><select id="employeeID" name="employeeID" class="form-control form-control-sm">
								<option value=""></option>
							</select></div>
						</div>
						<div class="row form-row form-group form-group-sm">
							<label class="col-3 col-form-label required text-left">Date</label>
							<div class="col-9 text-left"><input type="text" id="dateOfTermination" name="dateOfTermination" class="form-control form-control-sm datepicker" value="<%=_recordBean.getDateOfTermination()%>"></div>
						</div>
						<div class="row form-row form-group form-group-sm">
							<label class="col-3 col-form-label text-left">Comments</label>
							<div class="col-9 text-left"><textarea id="comments" name="comments" class="form-control form-control-sm"><%=_recordBean.getComments()%></textarea></div>
						</div>
					</div>

					<div class="col-2"></div>

					<div class="col-5">
						<div class="row form-row form-group form-group-sm">
							<label class="col-3 col-form-label text-left">Type</label>
							<div class="col-9 text-left"><select id="terminationType" name="terminationType" class="form-control form-control-sm">
								<option value=""></option>
								<option value="Terminated">Terminated</option>
								<option value="Quit">Quit</option>
							</select></div>
						</div>
						<div class="row form-row form-group form-group-sm">
							<label class="col-3 col-form-label text-left">Reason</label>
							<div class="col-9 text-left"><select id="terminationReason" name="terminationReason" class="form-control form-control-sm">
								<option value=""></option>
								<option value="Damage">Damage</option>
								<option value="Safety">Safety</option>
								<option value="Tier-2 defect">Tier-2 defect</option>
								<option value="Callouts">Callouts</option>
								<option value="Quit">Quit</option>
							</select></div>
						</div>
					</div>
				</div>

				<script>
					initSelect2Suggestor("employees", "employeeID", "<%=_recordBean.getEmployeeID()%>", false, "");
					setSelect2Option("terminationType", "<%=_recordBean.getTerminationType()%>");
					initSelect2SuggestorConvert("terminationReason", "", true);
					setSelect2Option("terminationReason", "<%=_recordBean.getTerminationReason()%>");
				</script>


			<%} else if(submitType == SubmitType.BROWSE) {%>
				<div class="row">
					<div class="col-5">
						<div class="row">
							<label class="col-3 col-form-label text-left">Employee</label>
							<div class="col-9 form-control-plaintext text-left"><%=_recordBean.getEmployeeName()%></div>
						</div>
						<div class="row">
							<label class="col-3 col-form-label text-left">Date</label>
							<div class="col-9 form-control-plaintext text-left"><%=_recordBean.getDateOfTermination()%></div>
						</div>
						<div class="row">
							<label class="col-3 col-form-label text-left">Comments</label>
							<div class="col-9 form-control-plaintext text-left"><%=_recordBean.getComments()%></div>
						</div>
					</div>

					<div class="col-2"></div>

					<div class="col-5">
						<div class="row">
							<label class="col-3 col-form-label text-left">Type</label>
							<div class="col-9 form-control-plaintext text-left"><%=_recordBean.getTerminationType()%></div>
						</div>
						<div class="row">
							<label class="col-3 col-form-label text-left">Reason</label>
							<div class="col-9 form-control-plaintext text-left"><%=_recordBean.getTerminationReason()%></div>
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
						<button class="btn btn-success text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.CREATE_CONFIRM%>','<%=_recordBean.getController()%>','<%=_recordBean.getEmployeeTerminationID()%>');">Save</button>
						<button class="btn btn-success text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.CREATE_CONFIRM%>','<%=_recordBean.getController()%>','<%=_recordBean.getEmployeeTerminationID()%>','2');">Save & Post</button></div>
					<%} else {%>
						<button class="btn btn-success text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.UPDATE_CONFIRM%>','<%=_recordBean.getController()%>','<%=_recordBean.getEmployeeTerminationID()%>');">Save</button>
						<button class="btn btn-success text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.UPDATE_CONFIRM%>','<%=_recordBean.getController()%>','<%=_recordBean.getEmployeeTerminationID()%>','2');">Save & Post</button></div>
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
					<button class="btn btn-primary text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.UPDATE%>','<%=_recordBean.getController()%>','<%=_recordBean.getEmployeeTerminationID()%>');">Edit</button>
				<%}%>
				</div>
				<div class="col-4 text-right">
				<%if("0".equalsIgnoreCase(_recordBean.getStatus())) {%>
					<button class="btn btn-danger text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.DELETE%>','<%=_recordBean.getController()%>','<%=_recordBean.getEmployeeTerminationID()%>');">Delete</button>
				<%}%>
				</div>
			</div>
		<%}%>
	</div>
</div>
<%@ include file="includeFooter.jsp"%>
<%}%>