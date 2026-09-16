<!DOCTYPE html>
<%@ page import="java.util.*, com.util.*, com.beans.*"%>
<jsp:useBean id="_errorBean" class="com.beans.ErrorBean" scope="request" />
<jsp:useBean id="_mainUtil" class="com.util.MainUtil" scope="request" />
<%
int submitType = request.getAttribute("submitType") == null ? SubmitType.CREATE : Integer.parseInt(request.getAttribute("submitType").toString().trim());

SearchBean _searchBean = new SearchBean();
Object _rawBeanObj = request.getAttribute("_recordBean");
if (_rawBeanObj instanceof SearchBean) {
    _searchBean = (SearchBean) _rawBeanObj;
    request.removeAttribute("_recordBean");
}
%>
<jsp:useBean id="_recordBean" class="com.beans.DACheckout" scope="request" />
<%
String _array[][] = null ;

/* ═══════════════ LIST VIEW (redesigned — MVPx list standard) ═══════════════ */
if (submitType == SubmitType.SEARCH) {
    List dataList = _searchBean.getDataList() == null ? new ArrayList() : _searchBean.getDataList();
    int cntTotal = dataList.size(), cntPosted = 0;
    List<String> empNames = new ArrayList<String>();
    List<String> vehNames = new ArrayList<String>();
    List<String> stNames  = new ArrayList<String>();
    /* [0]=id 1=inDate 2=inTime 3=outDate 4=outTime 5=emp 6=veh 7=parking 8=status 9=pill */
    List<String[]> rows = new ArrayList<String[]>();
    for (int i = 0; i < dataList.size(); i++) {
        List r = (List) dataList.get(i);
        String id      = r.get(0) == null ? "" : r.get(0).toString().trim();
        String inDT    = r.get(1) == null ? "" : r.get(1).toString().trim();
        String outDT   = r.get(2) == null ? "" : r.get(2).toString().trim();
        String emp     = r.get(3) == null ? "" : r.get(3).toString().trim();
        String veh     = r.get(4) == null ? "" : r.get(4).toString().trim();
        String parking = r.get(5) == null ? "" : r.get(5).toString().trim();
        String status  = r.get(6) == null ? "" : r.get(6).toString().trim();
        String inD = inDT, inT = "";
        if (inDT.length() > 10) { inD = inDT.substring(0,10); inT = inDT.substring(10).trim(); }
        String outD = outDT, outT = "";
        if (outDT.length() > 10) { outD = outDT.substring(0,10); outT = outDT.substring(10).trim(); }
        String pill = "slate";
        if ("Active".equalsIgnoreCase(status)) pill = "green";
        else if (status.toLowerCase().startsWith("post")) { pill = "blue"; cntPosted++; }
        if (emp.length() > 0 && !empNames.contains(emp)) empNames.add(emp);
        if (veh.length() > 0 && !vehNames.contains(veh)) vehNames.add(veh);
        if (status.length() > 0 && !stNames.contains(status)) stNames.add(status);
        rows.add(new String[]{ id, inD, inT, outD, outT, emp, veh, parking, status, pill });
    }
    Collections.sort(empNames); Collections.sort(vehNames); Collections.sort(stNames);
%>
<%@ include file="includeHeader.jsp"%>
<link rel="stylesheet" href="../jsp/assets/css/mvpx-list.css?v=20260916e">
<script src="../jsp/assets/js/mvpx-list.js?v=20260916a"></script>

<div class="da-wrap">

  <div class="da-headrow">
    <div>
      <h2>DA Checkouts</h2>
      <div class="statchips">
        <span class="statchip"><span class="dot" style="background:var(--da-blue)"></span><b><%=cntTotal%></b> checkouts</span>
        <span class="statchip"><span class="dot" style="background:#64748B"></span><b><%=cntPosted%></b> posted</span>
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
      <button id="btnToday" onclick="mvpxQuickDate('today')">Today</button>
      <button id="btnTomorrow" onclick="mvpxQuickDate('tomorrow')">Tomorrow</button>
    </div>
    <select class="da-flt" id="filterEmp" onchange="mvpxApplyFilters()" style="min-width:170px">
      <option value="">All employees</option>
      <%for(String v : empNames){%><option value="<%=v.toLowerCase()%>"><%=v%></option><%}%>
    </select>
    <select class="da-flt" id="filterVeh" onchange="mvpxApplyFilters()">
      <option value="">All vehicles</option>
      <%for(String v : vehNames){%><option value="<%=v.toLowerCase()%>"><%=v%></option><%}%>
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
          <th>Clockin Time</th>
          <th>Clockout Time</th>
          <th>Employee</th>
          <th>Vehicle</th>
          <th>Parking</th>
          <th>Status</th>
        </tr>
      </thead>
      <tbody id="ciRows">
        <%if(rows.isEmpty()){%>
        <tr><td colspan="7" class="da-empty">No checkouts for this date range.</td></tr>
        <%}%>
        <%for(String[] r : rows){%>
        <tr data-id="<%=r[0]%>"
            data-emp="<%=r[5].toLowerCase()%>"
            data-veh="<%=r[6].toLowerCase()%>"
            data-st="<%=r[8].toLowerCase()%>">
          <td><input type="checkbox" class="rowCheck" value="<%=r[0]%>"></td>
          <td><%=r[1]%><div class="meta"><%=r[2]%></div></td>
          <td><%=r[3]%><div class="meta"><%=r[4]%></div></td>
          <td class="nm"><a href="javascript:void(0)" style="color:inherit" onclick="submitPageDataForm('<%=SubmitType.BROWSE%>','<%=_searchBean.getController()%>','<%=r[0]%>')"><%=r[5]%></a></td>
          <td><%=r[6].length()>0?r[6]:"&mdash;"%></td>
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
  summary: { key:'st', label:'By status', filterId:'filterStatus' },
  filters: [
    { id:'filterEmp',    key:'emp', label:'Employee', mode:'includes' },
    { id:'filterVeh',    key:'veh', label:'Vehicle',  mode:'exact' },
    { id:'filterStatus', key:'st',  label:'Status',   mode:'exact' }
  ]
});
</script>

<%
/* ═══════════════ RECORD FORM VIEWS (unchanged legacy) ═══════════════ */
} else {
%>

<script>
function validatePageData(submitType, isValid) {

	if(submitType == <%=SubmitType.CREATE_CONFIRM%> || submitType == <%=SubmitType.UPDATE_CONFIRM%>) {
		if(isValid) {
			var mandatoryFieldsArray = new Array();
			mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["daCheckinID"], "Employee");
			mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["clockoutDate"], "Clockout Date");
			mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["clockoutTimeTxt"], "Clockout Time");
			mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["parking"], "Parking");
			mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["packagesLeft"], "How many packages did you bring back ?");
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
			<%if(submitType == SubmitType.CREATE || submitType == SubmitType.UPDATE) {
				String clockoutTime = _recordBean.getClockoutTime();
				if("12:00 AM".equalsIgnoreCase(clockoutTime)) {
					clockoutTime = "";
				}
				String clockoutTimeSel = "";
				if(clockoutTime.length() > 0) {
					String splitArray[] = clockoutTime.split(" ");
					clockoutTime = "";
					if(splitArray.length == 2) {
						clockoutTime = splitArray[0].trim();
						clockoutTimeSel = splitArray[1].trim();
					}
				}%>
				<script>
				var clockinArray = new Array();
				<%for(int i=0; i<_recordBean.getCheckinList().size(); i++) { List tempList = (ArrayList) _recordBean.getCheckinList().get(i);%>clockinArray[clockinArray.length] = new Array("<%=tempList.get(0).toString()%>", "<%=tempList.get(2).toString()%>");<%}%>
				function loadClockIn(thisObj) {
					if(document.getElementById("clockinDataDivID"))
						document.getElementById("clockinDataDivID").innerHTML = "";

					if(thisObj.value.length > 0) {
						for(var i=0; i<clockinArray.length; i++) {
							if(clockinArray[i][0] == thisObj.value) {
								if(document.getElementById("clockinDataDivID")) {
									document.getElementById("clockinDataDivID").innerHTML = clockinArray[i][1];
									geLocaletAuditTime();
								}
							}
						}
					}
				}

				function geLocaletAuditTime() {
					var dateObj = new Date();
					var dateDay = dateObj.getDate();
					var dateMonth = dateObj.getMonth()+1;
					var dateYear = dateObj.getFullYear();

					var dateHours = dateObj.getHours();
					var dateMins = dateObj.getMinutes();
					var dateAMPM = dateHours > 12 ? "PM" : "AM";
					if(dateHours > 12)
						dateHours = dateHours-12;
					if(dateHours < 10)
						dateHours = "0"+dateHours;
					if(dateMins < 10)
						dateMins = "0"+dateMins;
					if(dateDay < 10)
						dateDay = "0"+dateDay;
					if(dateMonth < 10)
						dateMonth = "0"+dateMonth;

					var selDate = dateMonth+"/"+dateDay+"/"+dateYear;
					var selTime = dateHours+":"+dateMins+" "+dateAMPM;

					if(document.formmain["clockoutDate"])
						document.formmain["clockoutDate"].value = selDate;
					if(document.formmain["clockoutTimeTxt"])
						document.formmain["clockoutTimeTxt"].value = dateHours+":"+dateMins;
					if(document.formmain["clockoutTimeSel"])
						document.formmain["clockoutTimeSel"].value = dateAMPM;
					if(document.formmain["clockoutTime"])
						document.formmain["clockoutTime"].value = selTime;
					if(document.getElementById("clockoutDataDivID"))
						document.getElementById("clockoutDataDivID").innerHTML = selDate+" "+selTime;
				}
				</script>
				<input type="hidden" id="daCheckoutID" name="daCheckoutID" value="<%=_recordBean.getDaCheckoutID()%>">
				<div class="row">
					<div class="col-12 col-md-5">
						<div class="row form-row form-group form-group-sm">
							<label class="col-12 col-md-3 col-form-label required text-left">Employee</label>
							<div class="col-12 col-md-9 text-left"><select id="daCheckinID" name="daCheckinID" class="form-control form-control-sm" onChange="loadClockIn(this);">
							<option value=""></option>
							<%for(int i=0; i<_recordBean.getCheckinList().size(); i++) {
							List tempList = (ArrayList) _recordBean.getCheckinList().get(i);
							%><option value="<%=tempList.get(0).toString()%>" <%if(_recordBean.getDaCheckinID().equalsIgnoreCase(tempList.get(0).toString())) {%>selected<%}%>><%=tempList.get(1).toString()%></option><%}%>
							</select></div>
						</div>
						<div class="row form-row form-group form-group-sm">
							<label class="col-12 col-md-3 col-form-label text-left">Clockin Time</label>
							<div class="col-12 col-md-9 form-control-plaintext text-left" id="clockinDataDivID"><%=_recordBean.getClockinDate()+" "+_recordBean.getClockinTime()%></div>
						</div>
						
						<%if(submitType == SubmitType.UPDATE) {%>
							<div class="row form-row form-group form-group-sm">
								<label class="col-12 col-md-3 col-form-label text-left">Clockout Time</label>
								<div class="col-12 col-md-9 text-left m-0 p-0">
									<div class="row col-12 m-0 p-0">
										<input type="hidden" id="clockoutDate" name="clockoutDate" value="<%=_recordBean.getClockoutDate()%>">
										<input type="hidden" id="clockoutTime" name="clockoutTime" value="<%=_recordBean.getClockoutTime()%>">
										<div class="col-6 form-control-plaintext"><%=_recordBean.getClockoutDate()%></div>
										<div class="col-3"><input type="text" id="clockoutTimeTxt" name="clockoutTimeTxt" class="form-control form-control-sm" value="<%=clockoutTime%>" placeholder="Time" onChange="fixTime('clockoutTime');"></div>
										<div class="col-3"><select id="clockoutTimeSel" name="clockoutTimeSel" class="form-control form-control-sm"><option value="AM" <%if("AM".equalsIgnoreCase(clockoutTimeSel)) {%>selected<%}%>>AM</option><option value="PM" <%if("AM".equalsIgnoreCase(clockoutTimeSel)) {%>selected<%}%>>PM</option></select></div>
									</div>
								</div>
							</div>
							<%if(clockoutTime.length() == 0) {%><script>geLocaletAuditTime();</script><%}%>
						<%} else {%>
							<div class="row form-row form-group form-group-sm">
								<label class="col-12 col-md-3 col-form-label text-left">Clockout Time</label>
								<div class="col-12 col-md-9 form-control-plaintext text-left" id="clockoutDataDivID"><%=_recordBean.getClockoutDate()+" "+_recordBean.getClockoutTime()%></div>
								<input type="hidden" id="clockoutDate" name="clockoutDate" value="<%=_recordBean.getClockoutDate()%>">
								<input type="hidden" id="clockoutTime" name="clockoutTime" value="<%=_recordBean.getClockoutTime()%>">
								<!--div class="col-9 text-left m-0 p-0">
									<div class="row col-12 m-0 p-0">
										<input type="hidden" id="clockoutTime" name="clockoutTime" value="<%=_recordBean.getClockoutTime()%>">
										<div class="col-6"><input type="text" id="clockoutDate" name="clockoutDate" class="form-control form-control-sm datepicker" value="<%=_recordBean.getClockoutDate()%>" placeholder="Date"></div>
										<div class="col-3"><input type="text" id="clockoutTimeTxt" name="clockoutTimeTxt" class="form-control form-control-sm" value="<%=clockoutTime%>" placeholder="Time" onChange="fixTime('clockoutTime');"></div>
										<div class="col-3"><select id="clockoutTimeSel" name="clockoutTimeSel" class="form-control form-control-sm"><option value="AM" <%if("AM".equalsIgnoreCase(clockoutTimeSel)) {%>selected<%}%>>AM</option><option value="PM" <%if("AM".equalsIgnoreCase(clockoutTimeSel)) {%>selected<%}%>>PM</option></select></div>
									</div>
								</div -->
							</div>
						<%}%>
						<div class="row form-row form-group form-group-sm">
							<label class="col-12 col-md-3 col-form-label text-left">DA Remarks</label>
							<div class="col-12 col-md-9 text-left"><textarea id="daComments" name="daComments" class="form-control form-control-sm"><%=_recordBean.getDaComments()%></textarea></div>
						</div>
						<div class="row form-row form-group form-group-sm">
							<label class="col-12 col-md-3 col-form-label text-left">Dispatcher Remarks</label>
							<div class="c9ol-12 col-md-9 text-left"><textarea id="dispatchComments" name="dispatchComments" class="form-control form-control-sm"><%=_recordBean.getDispatchComments()%></textarea></div>
						</div>
					</div>

					<div class="col-12 col-md-2"></div>

					<div class="col-12 col-md-5">
						<div class="row">
							<label class="col-12 col-md-6 col-form-label required text-left">Vehicle Parked</label>
							<div class="col-12 col-md-6 text-left">
								<select id="parking" name="parking" class="form-control form-control-sm"><option value=""></option><%_array = _mainUtil.getDataArray(_mainUtil.getParking());for(int k=0; k<_array.length; k++) {%><option value="<%=_array[k][0]%>"><%=_array[k][1]%></option><%}%></select>
							</div>
						</div>
						<div class="row">
							<label class="col-12 col-md-6 col-form-label text-left">Did you keep vehicle clean ?</label>
							<div class="col-12 col-md-6 text-left">
								<div class="form-check-inline">
									<label class="form-check-label"><input type="radio" class="form-check-input" name="vehicleClean" value="1" checked>Yes</label>
								</div>
								<div class="form-check-inline">
									<label class="form-check-label"><input type="radio" class="form-check-input" name="vehicleClean" value="0">No</label>
								</div>
							</div>
						</div>
						<div class="row">
							<label class="col-12 col-md-6 col-form-label text-left">Post Inspection Completed ?</label>
							<div class="col-12 col-md-6 text-left">
								<div class="form-check-inline">
									<label class="form-check-label"><input type="radio" class="form-check-input" name="postInspection" value="1" checked>Yes</label>
								</div>
								<div class="form-check-inline">
									<label class="form-check-label"><input type="radio" class="form-check-input" name="postInspection" value="0">No</label>
								</div>
							</div>
						</div>
						<div class="row">
							<label class="col-12 col-md-6 col-form-label text-left">Check with Dispatcher for any Safety Incidents</label>
							<div class="col-12 col-md-6 text-left">
								<div class="form-check-inline">
									<label class="form-check-label"><input type="radio" class="form-check-input" name="dispatcherChecked" value="1" checked>Yes</label>
								</div>
								<div class="form-check-inline">
									<label class="form-check-label"><input type="radio" class="form-check-input" name="dispatcherChecked" value="0">No</label>
								</div>
							</div>
						</div>
						<div class="row">
							<label class="col-12 col-md-6 col-form-label text-left">Called dispatcher from last stop ?</label>
							<div class="col-12 col-md-6 text-left">
								<div class="form-check-inline">
									<label class="form-check-label"><input type="radio" class="form-check-input" name="calledFromLast" value="1" checked>Yes</label>
								</div>
								<div class="form-check-inline">
									<label class="form-check-label"><input type="radio" class="form-check-input" name="calledFromLast" value="0">No</label>
								</div>
							</div>
						</div>
						<div class="row">
							<label class="col-12 col-md-6 col-form-label required text-left">How many packages did you bring back ?</label>
							<div class="col-12 col-md-6 text-left"><input type="text" id="packagesLeft" name="packagesLeft" class="form-control form-control-sm" value="<%=_recordBean.getPackagesLeft()%>"></div>
						</div>
						<div class="row">
							<label class="col-12 col-md-6 col-form-label text-left">Returned Phone</label>
							<div class="col-12 col-md-6 text-left">
								<div class="form-check-inline">
									<label class="form-check-label"><input type="radio" class="form-check-input" name="phoneReturned" value="1" checked>Yes</label>
								</div>
								<div class="form-check-inline">
									<label class="form-check-label"><input type="radio" class="form-check-input" name="phoneReturned" value="0">No</label>
								</div>
							</div>
						</div>
						<div class="row">
							<label class="col-12 col-md-6 col-form-label text-left">Returned Gas Card</label>
							<div class="col-12 col-md-6 text-left">
								<div class="form-check-inline">
									<label class="form-check-label"><input type="radio" class="form-check-input" name="gasCard" value="1" checked>Yes</label>
								</div>
								<div class="form-check-inline">
									<label class="form-check-label"><input type="radio" class="form-check-input" name="gasCard" value="0">No</label>
								</div>
							</div>
						</div>
						<div class="row">
							<label class="col-12 col-md-6 col-form-label text-left">Returned Cables</label>
							<div class="col-12 col-md-6 text-left">
								<div class="form-check-inline">
									<label class="form-check-label"><input type="radio" class="form-check-input" name="phoneCable" value="1" checked>Yes</label>
								</div>
								<div class="form-check-inline">
									<label class="form-check-label"><input type="radio" class="form-check-input" name="phoneCable" value="0">No</label>
								</div>
							</div>
						</div>
						<div class="row">
							<label class="col-12 col-md-6 col-form-label text-left">Returned Flash Light</label>
							<div class="col-12 col-md-6 text-left">
								<div class="form-check-inline">
									<label class="form-check-label"><input type="radio" class="form-check-input" name="flashLight" value="1" checked>Yes</label>
								</div>
								<div class="form-check-inline">
									<label class="form-check-label"><input type="radio" class="form-check-input" name="flashLight" value="0">No</label>
								</div>
							</div>
						</div>
						<div class="row">
							<label class="col-12 col-md-6 col-form-label text-left">Returned Power Bank</label>
							<div class="col-12 col-md-6 text-left">
								<div class="form-check-inline">
									<label class="form-check-label"><input type="radio" class="form-check-input" name="powerBank" value="1" checked>Yes</label>
								</div>
								<div class="form-check-inline">
									<label class="form-check-label"><input type="radio" class="form-check-input" name="powerBank" value="0">No</label>
								</div>
							</div>
						</div>
					</div>
				</div>

				<script>
					setSelectBoxValue(document.formmain["parking"], "<%=_recordBean.getParking()%>");
					setRadioButtonValue(document.formmain["vehicleClean"], "<%=_recordBean.getVehicleClean()%>");
					setRadioButtonValue(document.formmain["postInspection"], "<%=_recordBean.getPostInspection()%>");
					setRadioButtonValue(document.formmain["dispatcherChecked"], "<%=_recordBean.getDispatcherChecked()%>");
					setRadioButtonValue(document.formmain["calledFromLast"], "<%=_recordBean.getCalledFromLast()%>");
					setRadioButtonValue(document.formmain["phoneReturned"], "<%=_recordBean.getPhoneReturned()%>");
					setRadioButtonValue(document.formmain["gasCard"], "<%=_recordBean.getGasCard()%>");
					setRadioButtonValue(document.formmain["phoneCable"], "<%=_recordBean.getPhoneCable()%>");
					setRadioButtonValue(document.formmain["flashLight"], "<%=_recordBean.getFlashLight()%>");
					setRadioButtonValue(document.formmain["powerBank"], "<%=_recordBean.getPowerBank()%>");
				</script>

			<%} else if(submitType == SubmitType.BROWSE) {%>
				<input type="hidden" id="daCheckoutID" name="daCheckoutID" value="<%=_recordBean.getDaCheckoutID()%>">
				<div class="row">
					<div class="col-12 col-md-5">
						<div class="row">
							<label class="col-5 col-md-3 col-form-label text-left">Employee</label>
							<div class="col-7 col-md-9 form-control-plaintext text-left"><%=_recordBean.getEmployeeName()%></div>
						</div>
						<div class="row">
							<label class="col-5 col-md-3 col-form-label text-left">Vehicle</label>
							<div class="col-7 col-md-9 form-control-plaintext text-left"><%=_recordBean.getVehicleName()%></div>
						</div>
						<div class="row">
							<label class="col-5 col-md-3 col-form-label text-left">Clockin Time</label>
							<div class="col-7 col-md-9 form-control-plaintext text-left"><%=_recordBean.getClockinDate()+" "+_recordBean.getClockinTime()%></div>
						</div>
						<div class="row">
							<label class="col-5 col-md-3 col-form-label text-left">Clockout Time</label>
							<div class="col-7 col-md-9 form-control-plaintext text-left"><%=_recordBean.getClockoutDate()+" "+_recordBean.getClockoutTime()%></div>
						</div>
						<div class="row">
							<label class="col-5 col-md-3 col-form-label text-left">DA Remarks</label>
							<div class="col-7 col-md-9 form-control-plaintext text-left"><%=_recordBean.getDaComments()%></div>
						</div>
						<div class="row">
							<label class="col-5 col-md-3 col-form-label text-left">Dispatch Remarks</label>
							<div class="col-7 col-md-9 form-control-plaintext text-left"><%=_recordBean.getDispatchComments()%></div>
						</div>
					</div>

					<div class="col-12 col-md-2"></div>

					<div class="col-12 col-md-5">
						<div class="row">
							<label class="col-8 col-md-6 col-form-label text-left">Vehicle Parked</label>
							<div class="col-4 col-md-6 form-control-plaintext text-left"><%=_mainUtil.getParking().get(_recordBean.getParking())  == null ? "" : _mainUtil.getParking().get(_recordBean.getParking())%></div>
						</div>
						<div class="row">
							<label class="col-8 col-md-6 col-form-label text-left">Did you keep vehicle clean ?</label>
							<div class="col-4 col-md-6 form-control-plaintext text-left"><%="1".equalsIgnoreCase(_recordBean.getVehicleClean()) ? "Yes" : "No"%></div>
						</div>
						<div class="row">
							<label class="col-8 col-md-6 col-form-label text-left">Post Inspection Completed ?</label>
							<div class="col-4 col-md-6 form-control-plaintext text-left"><%="1".equalsIgnoreCase(_recordBean.getPostInspection()) ? "Yes" : "No"%></div>
						</div>
						<div class="row">
							<label class="col-8 col-md-6 col-form-label text-left">Check with Dispatcher for any Safety Incidents</label>
							<div class="col-4 col-md-6 form-control-plaintext text-left"><%="1".equalsIgnoreCase(_recordBean.getDispatcherChecked()) ? "Yes" : "No"%></div>
						</div>
						<div class="row">
							<label class="col-8 col-md-6 col-form-label text-left">Called dispatcher from last stop ?</label>
							<div class="col-4 col-md-6 form-control-plaintext text-left"><%="1".equalsIgnoreCase(_recordBean.getCalledFromLast()) ? "Yes" : "No"%></div>
						</div>
						<div class="row">
							<label class="col-8 col-md-6 col-form-label text-left">How many packages did you bring back ?</label>
							<div class="col-4 col-md-6 form-control-plaintext text-left"><%=_recordBean.getPackagesLeft()%></div>
						</div>
						<div class="row">
							<label class="col-8 col-md-6 col-form-label text-left">Returned Phone</label>
							<div class="col-4 col-md-6 form-control-plaintext text-left"><%="1".equalsIgnoreCase(_recordBean.getPhoneReturned()) ? "Yes" : "No"%></div>
						</div>
						<div class="row">
							<label class="col-8 col-md-6 col-form-label text-left">Returned Gas Card</label>
							<div class="col-4 col-md-6 form-control-plaintext text-left"><%="1".equalsIgnoreCase(_recordBean.getGasCard()) ? "Yes" : "No"%></div>
						</div>
						<div class="row">
							<label class="col-8 col-md-6 col-form-label text-left">Returned Cables</label>
							<div class="col-4 col-md-6 form-control-plaintext text-left"><%="1".equalsIgnoreCase(_recordBean.getPhoneCable()) ? "Yes" : "No"%></div>
						</div>
						<div class="row">
							<label class="col-8 col-md-6 col-form-label text-left">Returned Flash Light</label>
							<div class="col-4 col-md-6 form-control-plaintext text-left"><%="1".equalsIgnoreCase(_recordBean.getFlashLight()) ? "Yes" : "No"%></div>
						</div>
						<div class="row">
							<label class="col-8 col-md-6 col-form-label text-left">Returned Power Bank</label>
							<div class="col-4 col-md-6 form-control-plaintext text-left"><%="1".equalsIgnoreCase(_recordBean.getPowerBank()) ? "Yes" : "No"%></div>
						</div>
					</div>
				</div>
			<%}%>
			</div>
		</div>

		<div class="row my-4 text-center text-md-left">
		<%if(submitType == SubmitType.CREATE || submitType == SubmitType.UPDATE) {%>
			<div class="col-12 col-md-4 mb-2 mb-md-0 text-md-left">
				<button class="btn btn-secondary mb-1" onClick="Javascript:submitPageDataForm('<%=SubmitType.SEARCH%>','<%=_recordBean.getController()%>','');">Back to search</button>
			</div>
			<div class="col-12 col-md-4 mb-2 mb-md-0 text-md-center">
				<%if(submitType == SubmitType.CREATE) {%>
					<button class="btn btn-success mb-1" onClick="Javascript:submitPageDataForm('<%=SubmitType.CREATE_CONFIRM%>','<%=_recordBean.getController()%>','<%=_recordBean.getDaCheckoutID()%>');">Save</button>
					<button class="btn btn-success mb-1" onClick="Javascript:submitPageDataForm('<%=SubmitType.CREATE_CONFIRM%>','<%=_recordBean.getController()%>','<%=_recordBean.getDaCheckoutID()%>','2');">Save & Post</button></div>
				<%} else {%>
					<button class="btn btn-success mb-1" onClick="Javascript:submitPageDataForm('<%=SubmitType.UPDATE_CONFIRM%>','<%=_recordBean.getController()%>','<%=_recordBean.getDaCheckoutID()%>');">Save</button>
					<button class="btn btn-success mb-1" onClick="Javascript:submitPageDataForm('<%=SubmitType.UPDATE_CONFIRM%>','<%=_recordBean.getController()%>','<%=_recordBean.getDaCheckoutID()%>','2');">Save & Post</button></div>
				<%}%>
			<div class="col-12 col-md-4 mb-2 mb-md-0 text-md-right"></div>

		<%} else if(submitType == SubmitType.BROWSE) {%>
			<div class="col-12 col-md-4 mb-2 mb-md-0 text-md-left">
				<button class="btn btn-secondary mb-1" onClick="Javascript:submitPageDataForm('<%=SubmitType.SEARCH%>','<%=_recordBean.getController()%>','');">Back to search</button>
			</div>
			<div class="col-12 col-md-4 mb-2 mb-md-0 text-md-center">
			<%if("0".equalsIgnoreCase(_recordBean.getStatus())) {%>
				<button class="btn btn-primary mb-1" onClick="Javascript:submitPageDataForm('<%=SubmitType.UPDATE%>','<%=_recordBean.getController()%>','<%=_recordBean.getDaCheckoutID()%>');">Edit</button>
			<%}%>
			</div>
			<div class="col-12 col-md-4 mb-2 mb-md-0 text-md-right">
			<%if("0".equalsIgnoreCase(_recordBean.getStatus())) {%>
				<button class="my-delete-btn" onClick="Javascript:submitPageDataForm('<%=SubmitType.DELETE%>','<%=_recordBean.getController()%>','<%=_recordBean.getDaCheckoutID()%>');">Delete</button>
			<%}%>
			</div>
		<%}%>
		</div>
	</div>
</div>
<%@ include file="includeFooter.jsp"%>
<%}%>