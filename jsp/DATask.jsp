<!DOCTYPE html>
<%@ page import="java.util.*, com.util.*, com.beans.*"%>
<%!
private String escT(String s) {
	if (s == null) return "";
	return s.replace("&", "&amp;").replace("<", "&lt;")
			.replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&#39;");
}
%>
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
<jsp:useBean id="_recordBean" class="com.beans.DATask" scope="request" />
<%
/* ═══════════════ LIST VIEW ═══════════════ */
if (submitType == SubmitType.SEARCH) {
    List dataList = _searchBean.getDataList() == null ? new ArrayList() : _searchBean.getDataList();
    boolean isLead = _searchBean.getTransMap() != null
            && "yes".equals(_searchBean.getTransMap().get("isLead"));
    int cntOpen = 0, cntPend = 0, cntDone = 0, cntRisk = 0, cntDue = 0;
    List<String> daNames = new ArrayList<String>();
    List<String> asNames = new ArrayList<String>();
    /* row: 0=id 1=due 2=da 3=title 4=topic 5=priority 6=assigned 7=statusText
            8=pill 9=flag 10=flagLabel 11=rawStatus */
    List<String[]> rows = new ArrayList<String[]>();
    for (int i = 0; i < dataList.size(); i++) {
        List r = (List) dataList.get(i);
        String[] c = new String[13];
        for (int j = 0; j < 13 && j < r.size(); j++)
            c[j] = r.get(j) == null ? "" : r.get(j).toString().trim();
        for (int j = 0; j < 13; j++) if (c[j] == null) c[j] = "";
        if ("Open".equals(c[7])) cntOpen++;
        else if ("Pending".equals(c[7])) cntPend++;
        else if ("Completed".equals(c[7])) cntDone++;
        if ("atrisk".equals(c[10])) cntRisk++;
        else if ("due".equals(c[10])) cntDue++;
        if (c[2].length() > 0 && !daNames.contains(c[2])) daNames.add(c[2]);
        if (c[6].length() > 0 && !asNames.contains(c[6])) asNames.add(c[6]);
        rows.add(c);
    }
    Collections.sort(daNames); Collections.sort(asNames);
%>
<%@ include file="includeHeader.jsp"%>
<link rel="stylesheet" href="../jsp/assets/css/mvpx-list.css?v=20260916c">
<script src="../jsp/assets/js/mvpx-list.js?v=20260911b"></script>
<style>
.tk-flag{display:inline-flex;align-items:center;gap:5px;border-radius:999px;padding:2px 9px;font-size:10.5px;font-weight:700;margin-left:6px}
.tk-flag.atrisk{background:var(--da-red-50);color:var(--da-red)}
.tk-flag.due{background:var(--da-amber-50);color:var(--da-amber)}
.tk-act{border:1px solid var(--da-line);background:#fff;border-radius:7px;padding:4px 10px;font-size:11.5px;
  font-weight:600;color:var(--da-ink);cursor:pointer;white-space:nowrap}
.tk-act:hover{background:var(--da-ink);color:#fff;border-color:var(--da-ink)}
.tk-pr{font-family:var(--font-mono);font-size:10.5px;letter-spacing:.06em;padding:2px 8px;border-radius:999px;border:1px solid var(--da-line);background:#F8F7F2;color:var(--da-muted)}
.tk-pr.High{border-color:var(--da-ink);color:var(--da-ink);font-weight:700}
</style>

<div class="da-wrap">

  <div class="da-headrow">
    <div>
      <h2>DA Tasks</h2>
      <div class="statchips">
        <span class="statchip"><span class="dot" style="background:var(--da-amber)"></span><b id="cOpen"><%=cntOpen%></b> open</span>
        <span class="statchip"><span class="dot" style="background:var(--da-blue)"></span><b id="cPend"><%=cntPend%></b> pending</span>
        <span class="statchip"><span class="dot" style="background:var(--da-green)"></span><b id="cDone"><%=cntDone%></b> completed</span>
        <span class="statchip"><span class="dot" style="background:var(--da-red)"></span><b id="cRisk"><%=cntRisk%></b> at risk</span>
        <span class="statchip"><span class="dot" style="background:var(--da-amber)"></span><b id="cDue"><%=cntDue%></b> need attention</span>
      </div>
    </div>
    <div style="display:flex;gap:7px;align-items:center;flex-wrap:wrap">
      <%if(!isLead){%><span class="statchip">Showing <b>your</b> tasks</span><%}%>
      <button class="btn2" onclick="mvpxPrint('xls')" title="Export to Excel"><i class="fas fa-file-excel"></i> Excel</button>
      <button class="btn2" onclick="mvpxPrint('')" title="Download PDF"><i class="fas fa-file-pdf"></i> PDF</button>
      <button class="btn2 primary" onclick="submitPageDataForm('<%=SubmitType.CREATE%>','<%=_searchBean.getController()%>');">&#xFF0B; New Task</button>
    </div>
  </div>

  <div class="da-toolbar">
    <select class="da-flt" id="filterStatus" onchange="mvpxApplyFilters()">
      <option value="">All statuses</option>
      <option value="open">Open</option>
      <option value="pending">Pending</option>
      <option value="completed">Completed</option>
    </select>
    <select class="da-flt" id="filterFlag" onchange="mvpxApplyFilters()">
      <option value="">All urgency</option>
      <option value="atrisk">At Risk (overdue)</option>
      <option value="due">Needs Attention (&le; 1 day)</option>
    </select>
    <select class="da-flt" id="filterPr" onchange="mvpxApplyFilters()">
      <option value="">All priorities</option>
      <option value="high">High</option>
      <option value="medium">Medium</option>
      <option value="low">Low</option>
    </select>
    <select class="da-flt" id="filterDa" onchange="mvpxApplyFilters()" style="min-width:160px">
      <option value="">All DAs</option>
      <%for(String v : daNames){%><option value="<%=escT(v.toLowerCase())%>"><%=escT(v)%></option><%}%>
    </select>
    <%if(isLead){%>
    <select class="da-flt" id="filterAs" onchange="mvpxApplyFilters()">
      <option value="">All dispatchers</option>
      <%for(String v : asNames){%><option value="<%=escT(v.toLowerCase())%>"><%=escT(v)%></option><%}%>
    </select>
    <%}%>
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
          <th>Due</th>
          <th>DA</th>
          <th>Task</th>
          <th>Topic</th>
          <th>Priority</th>
          <th>Assigned</th>
          <th>Status</th>
          <th></th>
        </tr>
      </thead>
      <tbody id="ciRows">
        <%if(rows.isEmpty()){%>
        <tr><td colspan="8" class="da-empty">No tasks yet &mdash; create the first one.</td></tr>
        <%}%>
        <%for(String[] r : rows){%>
        <tr data-id="<%=r[0]%>"
            data-st="<%=r[7].toLowerCase()%>"
            data-flag="<%=r[10]%>"
            data-pr="<%=r[5].toLowerCase()%>"
            data-da="<%=escT(r[2].toLowerCase())%>"
            data-as="<%=escT(r[6].toLowerCase())%>">
          <td class="nm"><a href="javascript:void(0)" style="color:inherit" onclick="submitPageDataForm('<%=SubmitType.BROWSE%>','<%=_searchBean.getController()%>','<%=r[0]%>')"><%=r[1]%></a></td>
          <td><%=r[2].length()>0?escT(r[2]):"&mdash;"%></td>
          <td><%=escT(r[3])%></td>
          <td class="meta"><%=r[4].length()>0?escT(r[4]):"&mdash;"%></td>
          <td><%if(r[5].length()>0){%><span class="tk-pr <%=escT(r[5])%>"><%=escT(r[5].toUpperCase())%></span><%}else{%><span class="meta">&mdash;</span><%}%></td>
          <td class="meta"><%=escT(r[6])%></td>
          <td>
            <span class="pill <%=r[9]%>"><span class="d"></span><span class="ptxt"><%=r[7]%></span></span>
            <%if(r[10].length()>0){%><span class="tk-flag <%=r[10]%>"><%=r[11]%></span><%}%>
          </td>
          <td style="white-space:nowrap;text-align:right">
            <%if("0".equals(r[12])){%>
            <button class="tk-act" onclick="tkState('<%=r[0]%>','1',this)">Start</button>
            <button class="tk-act" onclick="tkState('<%=r[0]%>','2',this)">Done</button>
            <%} else if("1".equals(r[12])){%>
            <button class="tk-act" onclick="tkState('<%=r[0]%>','2',this)">Done</button>
            <%} else {%>
            <button class="tk-act" onclick="tkState('<%=r[0]%>','0',this)">Reopen</button>
            <%}%>
          </td>
        </tr>
        <%}%>
      </tbody>
    </table>
    <div class="tablefoot">
      <span id="showCount">Showing <%=rows.size()%> of <%=rows.size()%></span>
      <button class="btn2 sm" onclick="submitPageDataForm('<%=SubmitType.SEARCH%>','<%=_searchBean.getController()%>')">&#8635; Refresh</button>
    </div>
  </div>
</div>

<div class="da-toast" id="daToast"></div>

<script>
mvpxListInit({
  ctrl: '<%=_searchBean.getController()%>',
  from: '', to: '',
  summary: { key:'pr', label:'By priority', filterId:'filterPr' },
  filters: [
    { id:'filterStatus', key:'st',   label:'Status',     mode:'exact' },
    { id:'filterFlag',   key:'flag', label:'Urgency',    mode:'exact' },
    { id:'filterPr',     key:'pr',   label:'Priority',   mode:'exact' },
    { id:'filterDa',     key:'da',   label:'DA',         mode:'includes' }
    <%if(isLead){%>, { id:'filterAs', key:'as', label:'Dispatcher', mode:'exact' }<%}%>
  ]
});

/* one-click Start / Done / Reopen; the row updates in place */
function tkState(id, to, btn) {
  btn.disabled = true;
  var body = new URLSearchParams();
  body.append('submitType', '<%=SubmitType.DYNAMIC%>');
  body.append('controller', '<%=_searchBean.getController()%>');
  body.append('requestType', 'taskState');
  body.append('recordID', id);
  body.append('to', to);
  ['entityID','loginUser','loginUserID','loginUserRoles','loginUserDisplayName'].forEach(function(k){
    var el = document.getElementById(k); if (el) body.append(k, el.value);
  });
  fetch('MVPGServlet', { method:'POST', headers:{'Content-Type':'application/x-www-form-urlencoded'}, body: body.toString() })
    .then(function(r){ return r.text(); })
    .then(function(resp){
      if (resp.indexOf('<status>true') >= 0) {
        var m = /<mesg>([^<]*)<\/mesg>/.exec(resp);
        mvpxToast(m && m[1] ? m[1] : 'Updated', true);
        submitPageDataForm('<%=SubmitType.SEARCH%>', '<%=_searchBean.getController()%>');
      } else {
        var m2 = /<mesg>([^<]*)<\/mesg>/.exec(resp);
        mvpxToast(m2 && m2[1] ? m2[1] : 'Update failed', false);
        btn.disabled = false;
      }
    })
    .catch(function(){ mvpxToast('Update failed', false); btn.disabled = false; });
}
</script>

<%
/* ═══════════════ RECORD FORM VIEWS ═══════════════ */
} else {
%>

<script>
function validatePageData(submitType, isValid) {
	if (submitType == <%=SubmitType.CREATE_CONFIRM%> || submitType == <%=SubmitType.UPDATE_CONFIRM%>) {
		if (isValid) {
			var mandatoryFieldsArray = new Array();
			mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["taskTitle"], "Task");
			mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["employeeID"], "DA");
			mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["dueDate"], "Due Date");
			mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["assignedTo"], "Assigned To");
			isValid = validateMandatoryFieldsInForm(mandatoryFieldsArray, isValid);
		}
	} else if (submitType == <%=SubmitType.DELETE%>) {
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

			<input type="hidden" id="taskID" name="taskID" value="<%=_recordBean.getTaskID()%>">
			<div class='card-body m-1 p-1'>
			<%if(submitType == SubmitType.CREATE || submitType == SubmitType.UPDATE) {%>
				<div class="row">
					<div class="col-12 col-md-5">
						<div class="row form-row form-group form-group-sm">
							<label class="col-12 col-md-3 col-form-label required text-left">DA</label>
							<div class="col-12 col-md-9 text-left"><select id="employeeID" name="employeeID" class="form-control form-control-sm"></select></div>
						</div>
						<div class="row form-row form-group form-group-sm">
							<label class="col-12 col-md-3 col-form-label required text-left">Task</label>
							<div class="col-12 col-md-9 text-left"><input type="text" id="taskTitle" name="taskTitle" maxlength="200" class="form-control form-control-sm" value="<%=escT(_recordBean.getTaskTitle())%>"></div>
						</div>
						<div class="row form-row form-group form-group-sm">
							<label class="col-12 col-md-3 col-form-label text-left">Details</label>
							<div class="col-12 col-md-9 text-left"><input type="text" id="taskDesc" name="taskDesc" maxlength="2000" class="form-control form-control-sm" value="<%=escT(_recordBean.getTaskDesc())%>"></div>
						</div>
						<div class="row form-row form-group form-group-sm">
							<label class="col-12 col-md-3 col-form-label text-left">Topic</label>
							<div class="col-12 col-md-9 text-left">
								<select id="topic" name="topic" class="form-control form-control-sm">
									<option value=""></option>
									<%String[] _topics = {"Safety","Quality","Attendance","Coaching","Customer Feedback","Vehicle","Other"};
									for(String t : _topics){%>
									<option value="<%=t%>" <%=t.equals(_recordBean.getTopic())?"selected":""%>><%=t%></option>
									<%}%>
								</select>
							</div>
						</div>
					</div>

					<div class="col-12 col-md-2"></div>

					<div class="col-12 col-md-5">
						<div class="row form-row form-group form-group-sm">
							<label class="col-12 col-md-3 col-form-label required text-left">Due Date</label>
							<div class="col-12 col-md-9 text-left"><input type="text" id="dueDate" name="dueDate" class="form-control form-control-sm datepicker" value="<%=_recordBean.getDueDate()%>"></div>
						</div>
						<div class="row form-row form-group form-group-sm">
							<label class="col-12 col-md-3 col-form-label text-left">Priority</label>
							<div class="col-12 col-md-9 text-left">
								<select id="priority" name="priority" class="form-control form-control-sm">
									<%String[] _prs = {"Low","Medium","High"};
									for(String pv : _prs){%>
									<option value="<%=pv%>" <%=pv.equals(_recordBean.getPriority())?"selected":""%>><%=pv%></option>
									<%}%>
								</select>
							</div>
						</div>
						<div class="row form-row form-group form-group-sm">
							<label class="col-12 col-md-3 col-form-label required text-left">Assigned To</label>
							<div class="col-12 col-md-9 text-left"><select id="assignedTo" name="assignedTo" class="form-control form-control-sm"></select></div>
						</div>
						<%if(submitType == SubmitType.UPDATE) {%>
						<div class="row form-row form-group form-group-sm">
							<label class="col-12 col-md-3 col-form-label text-left">Status</label>
							<div class="col-12 col-md-9 text-left">
								<select id="taskStatus" name="taskStatus" class="form-control form-control-sm">
									<option value="0" <%="0".equals(_recordBean.getTaskStatus())?"selected":""%>>Open</option>
									<option value="1" <%="1".equals(_recordBean.getTaskStatus())?"selected":""%>>Pending</option>
									<option value="2" <%="2".equals(_recordBean.getTaskStatus())?"selected":""%>>Completed</option>
								</select>
							</div>
						</div>
						<%} else {%>
						<input type="hidden" id="taskStatus" name="taskStatus" value="0">
						<%}%>
					</div>
				</div>

				<script>
					initSelect2Suggestor("employees", "employeeID", "<%=_recordBean.getEmployeeID()%>", false, "");
					initSelect2Suggestor("dispatchers", "assignedTo", "<%=_recordBean.getAssignedTo()%>", false, "");
					/* the default assignee (current user) may not be in the
					   role-based dispatcher list — keep them selectable */
					<%if(_recordBean.getAssignedTo().length() > 0){%>
					setSelect2Option("assignedTo", "<%=escT(_recordBean.getAssignedTo())%>");
					<%}%>
				</script>

			<%} else if(submitType == SubmitType.BROWSE) {%>
				<div class="row">
					<div class="col-12 col-md-5">
						<div class="row">
							<label class="col-5 col-md-3 col-form-label text-left">DA</label>
							<div class="col-7 col-md-9 form-control-plaintext text-left"><%=escT(_recordBean.getEmployeeName())%></div>
						</div>
						<div class="row">
							<label class="col-5 col-md-3 col-form-label text-left">Task</label>
							<div class="col-7 col-md-9 form-control-plaintext text-left"><%=escT(_recordBean.getTaskTitle())%></div>
						</div>
						<div class="row">
							<label class="col-5 col-md-3 col-form-label text-left">Details</label>
							<div class="col-7 col-md-9 form-control-plaintext text-left"><%=escT(_recordBean.getTaskDesc())%></div>
						</div>
						<div class="row">
							<label class="col-5 col-md-3 col-form-label text-left">Topic</label>
							<div class="col-7 col-md-9 form-control-plaintext text-left"><%=escT(_recordBean.getTopic())%></div>
						</div>
					</div>

					<div class="col-12 col-md-2"></div>

					<div class="col-12 col-md-5">
						<div class="row">
							<label class="col-5 col-md-3 col-form-label text-left">Due Date</label>
							<div class="col-7 col-md-9 form-control-plaintext text-left"><%=_recordBean.getDueDate()%></div>
						</div>
						<div class="row">
							<label class="col-5 col-md-3 col-form-label text-left">Priority</label>
							<div class="col-7 col-md-9 form-control-plaintext text-left"><%=escT(_recordBean.getPriority())%></div>
						</div>
						<div class="row">
							<label class="col-5 col-md-3 col-form-label text-left">Assigned To</label>
							<div class="col-7 col-md-9 form-control-plaintext text-left"><%=escT(_recordBean.getAssignedTo())%></div>
						</div>
						<div class="row">
							<label class="col-5 col-md-3 col-form-label text-left">Status</label>
							<div class="col-7 col-md-9 form-control-plaintext text-left">
								<%="1".equals(_recordBean.getTaskStatus()) ? "Pending" : ("2".equals(_recordBean.getTaskStatus()) ? "Completed" : "Open")%>
							</div>
						</div>
					</div>
				</div>
			<%}%>
			</div>
		</div>

		<%if(submitType == SubmitType.CREATE || submitType == SubmitType.UPDATE) {%>
			<div class="row mt-4">
				<div class="col-4 text-left">
					<button class="btn btn-secondary text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.SEARCH%>','<%=_recordBean.getController()%>','');">Back to tasks</button>
				</div>
				<div class="col-4 text-center">
					<%if(submitType == SubmitType.CREATE) {%>
						<button class="btn btn-success text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.CREATE_CONFIRM%>','<%=_recordBean.getController()%>','<%=_recordBean.getTaskID()%>');">Save</button>
					<%} else {%>
						<button class="btn btn-success text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.UPDATE_CONFIRM%>','<%=_recordBean.getController()%>','<%=_recordBean.getTaskID()%>');">Save</button>
					<%}%>
				</div>
				<div class="col-4 text-right"></div>
			</div>

		<%} else if(submitType == SubmitType.BROWSE) {%>
			<div class="row mt-4">
				<div class="col-4 text-left">
					<button class="btn btn-secondary text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.SEARCH%>','<%=_recordBean.getController()%>','');">Back to tasks</button>
				</div>
				<div class="col-4 text-center">
					<button class="btn btn-primary text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.UPDATE%>','<%=_recordBean.getController()%>','<%=_recordBean.getTaskID()%>');">Edit</button>
				</div>
				<div class="col-4 text-right">
					<button class="btn btn-danger text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.DELETE%>','<%=_recordBean.getController()%>','<%=_recordBean.getTaskID()%>');">Delete</button>
				</div>
			</div>
		<%}%>
	</div>
</div>
<%@ include file="includeFooter.jsp"%>
<%}%>
