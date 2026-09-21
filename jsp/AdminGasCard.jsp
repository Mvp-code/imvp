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
<jsp:useBean id="_recordBean" class="com.beans.AdminGasCard" scope="request" />
<%
if (submitType == SubmitType.SEARCH) {
    List dataList = _searchBean.getDataList() == null ? new ArrayList() : _searchBean.getDataList();
    int cntTotal = dataList.size(), cntActive = 0, cntInactive = 0;
    int cntLocked = 0, cntUnlocked = 0, cntAvail = 0, cntNotAvail = 0, cntExpired = 0;
    java.text.SimpleDateFormat gcMdy = new java.text.SimpleDateFormat("MM/dd/yyyy");
    gcMdy.setLenient(false);
    java.util.Date gcToday = new java.util.Date();
    try { gcToday = gcMdy.parse(gcMdy.format(new java.util.Date())); } catch (Exception ignore) {}
    List<String[]> rows = new ArrayList<String[]>();
    Map<String, Integer> idCounts = new LinkedHashMap<String, Integer>();
    for (int i = 0; i < dataList.size(); i++) {
        List r = (List) dataList.get(i);
        String[] c = new String[8];
        for (int j = 0; j < 8; j++) {
            c[j] = (j < r.size() && r.get(j) != null) ? r.get(j).toString().trim() : "";
        }
        String stLc = c[2].toLowerCase();
        if (stLc.startsWith("active")) cntActive++;
        else cntInactive++;
        String lockLc = c[5].toLowerCase();
        if (lockLc.startsWith("lock")) cntLocked++;
        else cntUnlocked++;
        if ("yes".equalsIgnoreCase(c[7])) cntAvail++;
        else cntNotAvail++;
        if (c[4].length() > 0) {
            try {
                if (gcMdy.parse(c[4]).before(gcToday)) cntExpired++;
            } catch (Exception ignore) {}
        }
        if (c[1].length() > 0)
            idCounts.put(c[1], idCounts.get(c[1]) == null ? 1 : idCounts.get(c[1]) + 1);
        rows.add(c);
    }
    int cntDup = 0;
    for (Integer n : idCounts.values()) if (n != null && n.intValue() > 1) cntDup += n.intValue();
%>
<%@ include file="includeHeader.jsp"%>
<link rel="stylesheet" href="../jsp/assets/css/mvpx-list.css?v=20260921c">
<script src="../jsp/assets/js/mvpx-list.js?v=20260921c"></script>
<style>
.da-wrap{padding:2px 0 48px}
.da-wrap .da-headrow{margin-bottom:10px;align-items:center}
.da-wrap .da-headrow h2{
  margin:0;font-size:22px;font-weight:800;letter-spacing:-.02em;
  color:var(--text,#16202e);font-family:var(--font-disp,'Inter','DM Sans','Open Sans','Work Sans','Segoe UI',sans-serif);
}
.da-wrap .statchip{
  border-radius:6px;font-size:12px;padding:4px 10px;
  background:var(--status-action-bg);border-color:var(--status-action-border);
  color:var(--status-action-fg);
}
.da-wrap .statchip .dot{background:var(--status-action-fg)!important}
.da-wrap .statchip b{color:var(--status-action-fg)}
.gc-chip{cursor:pointer;user-select:none}
.gc-chip:hover{border-color:var(--text,#16202e)}
.vh-cards{display:grid;grid-template-columns:repeat(4,1fr);gap:10px;margin:0 0 12px}
.vh-card{
  background:var(--surface,#fff);border:1px solid var(--border,#e2e8f0);
  border-radius:8px;padding:12px 14px 10px;min-width:0;
  border-left:3px solid var(--border-strong,#cbd5e1);box-shadow:none;
}
.vh-cards .vh-card:nth-child(1){border-left-color:var(--status-ok-fg)}
.vh-cards .vh-card:nth-child(2){border-left-color:var(--status-neutral-fg,#475569)}
.vh-cards .vh-card:nth-child(3){border-left-color:var(--status-warn-fg)}
.vh-cards .vh-card:nth-child(4){border-left-color:var(--theme-accent,#2563eb)}
.vh-card h4{
  margin:0 0 8px;font-size:12px;font-weight:800;letter-spacing:.04em;
  text-transform:uppercase;color:var(--text-muted,#475569);
  display:flex;align-items:center;gap:6px;
  font-family:var(--font,'Inter','DM Sans','Open Sans','Work Sans','Segoe UI',sans-serif);
}
.vh-card h4 .n{
  margin-left:auto;font-family:var(--font-mono,ui-monospace,monospace);
  font-size:20px;font-weight:800;color:var(--text,#16202e);letter-spacing:-.02em;
}
.vh-card .dot{width:8px;height:8px;border-radius:50%;display:inline-block;margin-right:2px}
.vh-line{
  display:inline-flex;align-items:center;gap:4px;font-size:12.5px;line-height:1.5;
  cursor:pointer;border-radius:4px;padding:2px 5px;margin:0 0 1px;max-width:100%;
  color:var(--text,#16202e);
}
.vh-line:hover{background:var(--bg,#f1f5f9)}
.vh-line b{font-family:var(--font-mono,ui-monospace,monospace);font-weight:700;color:var(--text-muted,#475569)}
@media (max-width:1100px){.vh-cards{grid-template-columns:1fr 1fr}}
@media (max-width:700px){.vh-cards{grid-template-columns:1fr}}
.da-wrap .da-toolbar{border-radius:8px;padding:8px 10px;margin-bottom:8px;border-color:var(--border,#e2e8f0);background:var(--surface,#fff);box-shadow:none}
.da-wrap .da-flt{font-size:13px;padding:7px 10px;border-radius:6px;border-color:var(--border-strong,#cbd5e1);max-width:200px}
.da-wrap .btn2{border-radius:6px}
.da-wrap .btn2.primary{background:var(--theme-accent,#2563eb);border-color:var(--theme-accent,#2563eb)}
.da-wrap .tablewrap{overflow:hidden !important;border-radius:8px;margin-top:8px;border-color:var(--border,#e2e8f0);box-shadow:none}
.da-wrap .vh-tbl-x{overflow-x:auto !important;scrollbar-width:thin}
.da-wrap .tablewrap thead th{
  font-size:11px !important;font-weight:700;letter-spacing:.03em;text-transform:uppercase;
  padding:8px 10px !important;white-space:normal !important;line-height:1.25;
  color:var(--text-muted,#475569)!important;background:var(--bg,#f1f5f9)!important;
  border-bottom:1px solid var(--border,#e2e8f0)!important;
}
.da-wrap .tablewrap thead th.srt{cursor:pointer;user-select:none}
.da-wrap .tablewrap tbody td{
  font-size:13.5px !important;padding:9px 12px !important;white-space:nowrap;
  color:var(--text,#16202e);
}
.da-wrap .tablewrap tbody tr:hover{filter:brightness(.98);cursor:pointer}
.da-wrap .tablewrap .meta{font-size:12.5px !important;color:var(--text-muted,#475569)!important}
.da-wrap .tablewrap .nm{font-size:13.5px !important;font-weight:700}
.da-empty{text-align:center;color:var(--text-light,#64748b);padding:28px 12px !important}
.da-wrap #ciRows tr.gc-expired td{background:color-mix(in srgb, var(--status-warn-bg,#FEF3C7) 55%, transparent)}
.da-wrap #ciRows tr.gc-dup td{background:color-mix(in srgb, var(--status-action-bg,#FEE2E2) 40%, transparent)}
</style>

<div class="da-wrap">
  <div class="da-headrow">
    <div><h2>Gas Cards</h2></div>
    <div style="display:flex;gap:7px;align-items:center;flex-wrap:wrap">
      <%if(cntExpired>0){%><span class="statchip gc-chip" onclick="gcChip('filterExp','expired')"><span class="dot"></span><b><%=cntExpired%></b> expired</span><%}%>
      <%if(cntDup>0){%><span class="statchip gc-chip" onclick="gcChip('filterDup','dup')"><span class="dot"></span><b><%=cntDup%></b> duplicate IDs</span><%}%>
      <button type="button" class="btn2 sm" id="vhSumBtn" onclick="gcSummary()">Hide summary</button>
      <button type="button" class="btn2" onclick="mvpxPrint('xls')" title="Download filtered cards to Excel"><i class="fas fa-file-excel"></i> Excel</button>
      <button type="button" class="btn2" onclick="mvpxPrint('')" title="Download PDF"><i class="fas fa-file-pdf"></i> PDF</button>
      <button type="button" class="btn2 primary" onclick="submitPageDataForm('<%=SubmitType.CREATE%>','<%=_searchBean.getController()%>');">&#xFF0B; New</button>
    </div>
  </div>

  <div class="vh-cards">
    <div class="vh-card">
      <h4 class="gc-chip" onclick="gcChip('filterSt','active')"><span class="dot"></span> Active <span class="n"><%=cntActive%></span></h4>
      <div class="vh-line" onclick="gcChip('filterSt','inactive')"><span>Inactive</span><b>(<%=cntInactive%>)</b></div>
    </div>
    <div class="vh-card">
      <h4 class="gc-chip" onclick="gcChip('filterLock','locked')"><span class="dot"></span> Locked <span class="n"><%=cntLocked%></span></h4>
      <div class="vh-line" onclick="gcChip('filterLock','unlocked')"><span>Unlocked</span><b>(<%=cntUnlocked%>)</b></div>
    </div>
    <div class="vh-card">
      <h4 class="gc-chip" onclick="gcChip('filterAvail','yes')"><span class="dot"></span> Available <span class="n"><%=cntAvail%></span></h4>
      <div class="vh-line" onclick="gcChip('filterAvail','no')"><span>Not available</span><b>(<%=cntNotAvail%>)</b></div>
    </div>
    <div class="vh-card">
      <h4 class="gc-chip" onclick="gcChip('filterExp','expired')"><span class="dot"></span> Expired <span class="n"><%=cntExpired%></span></h4>
      <div class="vh-line" onclick="gcChip('filterDup','dup')"><span>Duplicate Card IDs</span><b>(<%=cntDup%>)</b></div>
    </div>
  </div>

  <div class="da-toolbar">
    <select class="da-flt" id="filterId" onchange="mvpxApplyFilters()" style="max-width:200px">
      <option value="">All card IDs</option>
      <%
        List<String> gcIds = new ArrayList<String>();
        for (String[] pr : rows) if (pr[1].length() > 0 && !gcIds.contains(pr[1])) gcIds.add(pr[1]);
        Collections.sort(gcIds);
        for (String gid : gcIds) {
      %>
      <option value="<%=gid.toLowerCase().replace("&","&amp;").replace("\"","&quot;")%>"><%=gid.replace("&","&amp;").replace("<","&lt;")%></option>
      <%}%>
    </select>
    <select class="da-flt" id="filterSt" onchange="mvpxApplyFilters()">
      <option value="">All card status</option>
      <option value="active">Active</option>
      <option value="inactive">Inactive</option>
    </select>
    <select class="da-flt" id="filterLock" onchange="mvpxApplyFilters()">
      <option value="">All lock status</option>
      <option value="locked">Locked</option>
      <option value="unlocked">Unlocked</option>
    </select>
    <select class="da-flt" id="filterAvail" onchange="mvpxApplyFilters()">
      <option value="">All availability</option>
      <option value="yes">Yes</option>
      <option value="no">No</option>
    </select>
    <select class="da-flt" id="filterExp" onchange="mvpxApplyFilters()" style="display:none">
      <option value=""></option>
      <option value="expired">expired</option>
    </select>
    <select class="da-flt" id="filterDup" onchange="mvpxApplyFilters()" style="display:none">
      <option value=""></option>
      <option value="dup">dup</option>
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
    <div class="vh-tbl-x">
    <table>
      <thead>
        <tr>
          <th class="srt" onclick="mvpxSort(this)">Card ID<span class="ar"></span></th>
          <th class="srt" onclick="mvpxSort(this)">Status<span class="ar"></span></th>
          <th class="srt" onclick="mvpxSort(this)">Status Date<span class="ar"></span></th>
          <th class="srt" onclick="mvpxSort(this)">Expiry<span class="ar"></span></th>
          <th class="srt" onclick="mvpxSort(this)">Lock<span class="ar"></span></th>
          <th class="srt" onclick="mvpxSort(this)">Location<span class="ar"></span></th>
          <th class="srt" onclick="mvpxSort(this)">Available<span class="ar"></span></th>
        </tr>
      </thead>
      <tbody id="ciRows">
        <%if(rows.isEmpty()){%>
        <tr><td colspan="7" class="da-empty">No gas cards found.</td></tr>
        <%}%>
        <%for(String[] r : rows){
            String stLc = r[2].toLowerCase();
            String lockLc = r[5].toLowerCase();
            String availLc = r[7].toLowerCase();
            String stPill = stLc.startsWith("active") ? "green" : "slate";
            String lockPill = lockLc.startsWith("lock") ? "amber" : "green";
            String avPill = "yes".equals(availLc) ? "green" : "slate";
            boolean expired = false;
            if (r[4].length() > 0) {
              try { expired = gcMdy.parse(r[4]).before(gcToday); } catch (Exception ignore) {}
            }
            boolean dup = r[1].length() > 0 && idCounts.get(r[1]) != null && idCounts.get(r[1]).intValue() > 1;
            String rowCls = (dup ? "gc-dup " : "") + (expired ? "gc-expired" : "");
            String idHtml = r[1].replace("&","&amp;").replace("<","&lt;");
        %>
        <tr class="<%=rowCls.trim()%>" data-id="<%=r[0]%>"
            data-card="<%=r[1].toLowerCase().replace("&","&amp;").replace("\"","&quot;")%>"
            data-st="<%=stLc.replace("&","&amp;").replace("\"","&quot;")%>"
            data-lock="<%=lockLc.replace("&","&amp;").replace("\"","&quot;")%>"
            data-avail="<%=availLc.replace("&","&amp;").replace("\"","&quot;")%>"
            data-exp="<%=expired?"expired":""%>"
            data-dup="<%=dup?"dup":""%>"
            onclick="if(event.target.closest('a,button'))return;submitPageDataForm('<%=SubmitType.UPDATE%>','<%=_searchBean.getController()%>','<%=r[0]%>')">
          <td class="nm"><a href="javascript:void(0)" style="color:inherit" onclick="submitPageDataForm('<%=SubmitType.UPDATE%>','<%=_searchBean.getController()%>','<%=r[0]%>');return false;"><%=idHtml.length()>0?idHtml:"&mdash;"%></a></td>
          <td><span class="pill <%=stPill%>"><span class="d"></span><%=r[2].length()>0?r[2].replace("&","&amp;").replace("<","&lt;"):"&mdash;"%></span></td>
          <td class="meta"><%=r[3].length()>0?r[3].replace("&","&amp;"):"&mdash;"%></td>
          <td class="meta"><%if(expired){%><span class="pill amber"><span class="d"></span><%=r[4].replace("&","&amp;")%></span><%}else{%><%=r[4].length()>0?r[4].replace("&","&amp;"):"&mdash;"%><%}%></td>
          <td><span class="pill <%=lockPill%>"><span class="d"></span><%=r[5].length()>0?r[5].replace("&","&amp;").replace("<","&lt;"):"&mdash;"%></span></td>
          <td class="meta"><%=r[6].length()>0?r[6].replace("&","&amp;").replace("<","&lt;"):"&mdash;"%></td>
          <td><span class="pill <%=avPill%>"><span class="d"></span><%=r[7].length()>0?r[7].replace("&","&amp;").replace("<","&lt;"):"&mdash;"%></span></td>
        </tr>
        <%}%>
      </tbody>
    </table>
    </div>
    <div class="tablefoot">
      <span id="showCount">Showing <%=rows.size()%> of <%=cntTotal%></span>
      <button type="button" class="btn2 sm" onclick="submitPageDataForm('<%=SubmitType.SEARCH%>','<%=_searchBean.getController()%>')">&#8635; Refresh</button>
    </div>
  </div>
</div>
<div class="da-toast" id="daToast"></div>
<script>
mvpxListInit({
  ctrl: '<%=_searchBean.getController()%>',
  from: '<%=_searchBean.getSrhFromDate()%>',
  to:   '<%=_searchBean.getSrhToDate()%>',
  filters: [
    { id:'filterId',    key:'card',  label:'Card ID',     mode:'exact' },
    { id:'filterSt',    key:'st',    label:'Status',      mode:'exact' },
    { id:'filterLock',  key:'lock',  label:'Lock',        mode:'exact' },
    { id:'filterAvail', key:'avail', label:'Available',   mode:'exact' },
    { id:'filterExp',   key:'exp',   label:'Expiry',      mode:'exact' },
    { id:'filterDup',   key:'dup',   label:'Duplicates',  mode:'exact' }
  ]
});
function gcChip(selId, val) {
  var s = document.getElementById(selId);
  if (!s) return;
  s.value = (s.value === val ? '' : val);
  mvpxApplyFilters();
}
function gcSummary() {
  var cards = document.querySelector('.vh-cards'), btn = document.getElementById('vhSumBtn');
  if (!cards || !btn) return;
  var hide = cards.style.display !== 'none';
  cards.style.display = hide ? 'none' : '';
  btn.textContent = hide ? 'Show summary' : 'Hide summary';
}
</script>
<%@ include file="includeFooter.jsp"%>
<%
} else {
%>

<script>
function validatePageData(submitType, isValid) {

	if(submitType == <%=SubmitType.CREATE_CONFIRM%> || submitType == <%=SubmitType.UPDATE_CONFIRM%>) {
		if(isValid) {
			var mandatoryFieldsArray = new Array();
			mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["cardIdentifier"], "Card ID");
			if(document.formmain["cardStatus"] && document.formmain["cardStatus"].value == "4") {
				mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["cardStatusReason"], "Reason");
			}
			mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["cardStatusDate"], "Card Status Date");
			mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["cardExpiry"], "Card Expiry");
			mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["location"], "Location");
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
			<%if(submitType == SubmitType.CREATE || submitType == SubmitType.UPDATE) {%>
				<script>
				function checkStatus(thisObj, divID) {
					enableOrDisableID(divID, "none");
					if(thisObj.value == "4") {
						enableOrDisableID(divID, "");
					} else {
						document.formmain["cardStatusReason"].value = "";
					}
				}
				</script>
				<input type="hidden" id="gasCardID" name="gasCardID" value="<%=_recordBean.getGasCardID()%>">
				<div class="row">
					<div class="col-5">
						<div class="row form-row form-group form-group-sm">
							<label class="col-3 col-form-label required text-left">Card ID</label>
							<div class="col-9 text-left"><input type="text" id="cardIdentifier" name="cardIdentifier" class="form-control form-control-sm" value="<%=_recordBean.getCardIdentifier()%>"></div>
						</div>
						<div class="row">
							<label class="col-3 col-form-label text-left">Card Status</label>
							<div class="col-9 text-left">
								<div class="form-check-inline">
									<label class="form-check-label"><input type="radio" class="form-check-input" name="cardStatus" value="0" checked onChange="Javascript:checkStatus(this,'cardStatusReasonDivID');">Active</label>
								</div>
								<div class="form-check-inline">
									<label class="form-check-label"><input type="radio" class="form-check-input" name="cardStatus" value="4" onChange="Javascript:checkStatus(this,'cardStatusReasonDivID');">Inactive</label>
								</div>
							</div>
						</div>
						<div class="row form-row form-group form-group-sm" id="cardStatusReasonDivID" <%if(!"4".equalsIgnoreCase(_recordBean.getCardStatus())) {%>style="display:none"<%}%>>
							<label class="col-3 col-form-label required text-left">Reason</label>
							<div class="col-9 text-left"><textarea id="cardStatusReason" name="cardStatusReason" class="form-control form-control-sm"><%=_recordBean.getCardStatusReason()%></textarea></div>
						</div>
						<div class="row form-row form-group form-group-sm">
							<label class="col-3 col-form-label required text-left">Card Status Date</label>
							<div class="col-9 text-left"><input type="text" id="cardStatusDate" name="cardStatusDate" class="form-control form-control-sm datepicker" value="<%=_recordBean.getCardStatusDate()%>"></div>
						</div>
						<div class="row form-row form-group form-group-sm">
							<label class="col-3 col-form-label required text-left">Card Expiry</label>
							<div class="col-9 text-left"><input type="text" id="cardExpiry" name="cardExpiry" class="form-control form-control-sm datepicker" value="<%=_recordBean.getCardExpiry()%>"></div>
						</div>
					</div>

					<div class="col-2"></div>

					<div class="col-5">
						<div class="row">
							<label class="col-3 col-form-label text-left">Lock Status</label>
							<div class="col-9 text-left">
								<div class="form-check-inline">
									<label class="form-check-label"><input type="radio" class="form-check-input" name="lockStatus" value="5" checked>Locked</label>
								</div>
								<div class="form-check-inline">
									<label class="form-check-label"><input type="radio" class="form-check-input" name="lockStatus" value="6">Unlocked</label>
								</div>
							</div>
						</div>
						<div class="row">
							<label class="col-3 col-form-label text-left">Available</label>
							<div class="col-9 text-left">
								<div class="form-check-inline">
									<label class="form-check-label"><input type="radio" class="form-check-input" name="available" value="1">Yes</label>
								</div>
								<div class="form-check-inline">
									<label class="form-check-label"><input type="radio" class="form-check-input" name="available" value="0" checked>No</label>
								</div>
							</div>
						</div>
						<div class="row form-row form-group form-group-sm">
							<label class="col-3 col-form-label required text-left">Location</label>
							<div class="col-9 text-left"><input type="text" id="location" name="location" class="form-control form-control-sm" value="<%=_recordBean.getLocation()%>"></div>
						</div>
					</div>
				</div>
				<script>
					setRadioButtonValue(document.formmain["cardStatus"], "<%=_recordBean.getCardStatus()%>");
					setRadioButtonValue(document.formmain["lockStatus"], "<%=_recordBean.getLockStatus()%>");
					setRadioButtonValue(document.formmain["available"], "<%=_recordBean.getAvailable()%>");
				</script>

			<%} else if(submitType == SubmitType.BROWSE) {%>
				<input type="hidden" id="gasCardID" name="gasCardID" value="<%=_recordBean.getGasCardID()%>">
				<div class="row">
					<div class="col-5">
						<div class="row">
							<label class="col-3 col-form-label text-left">Card ID</label>
							<div class="col-9 form-control-plaintext text-left"><%=_recordBean.getCardIdentifier()%></div>
						</div>
						<div class="row">
							<label class="col-3 col-form-label text-left">Card Status</label>
							<div class="col-9 form-control-plaintext text-left"><%=RecordStatus.RecordStatus[Integer.parseInt(_recordBean.getCardStatus())]%></div>
						</div>
						<%if(_recordBean.getCardStatusReason().length() > 0) {%>
						<div class="row">
							<label class="col-3 col-form-label text-left">Reason</label>
							<div class="col-9 form-control-plaintext text-left"><%=_recordBean.getCardStatusReason()%></div>
						</div>
						<%}%>
						<div class="row">
							<label class="col-3 col-form-label text-left">Card Status Date</label>
							<div class="col-9 form-control-plaintext text-left"><%=_recordBean.getCardStatusDate()%></div>
						</div>
						<div class="row">
							<label class="col-3 col-form-label text-left">Card Expiry</label>
							<div class="col-9 form-control-plaintext text-left"><%=_recordBean.getCardExpiry()%></div>
						</div>
					</div>

					<div class="col-2"></div>

					<div class="col-5">
						<div class="row">
							<label class="col-3 col-form-label text-left">Lock Status</label>
							<div class="col-9 form-control-plaintext text-left"><%=RecordStatus.RecordStatus[Integer.parseInt(_recordBean.getLockStatus())]%></div>
						</div>
						<div class="row">
							<label class="col-3 col-form-label text-left">Available</label>
							<div class="col-9 form-control-plaintext text-left"><%="1".equalsIgnoreCase(_recordBean.getAvailable()) ? "Yes" : "No"%></div>
						</div>
						<div class="row">
							<label class="col-3 col-form-label text-left">Location</label>
							<div class="col-9 form-control-plaintext text-left"><%=_recordBean.getLocation()%></div>
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
						<button class="btn btn-success text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.CREATE_CONFIRM%>','<%=_recordBean.getController()%>','<%=_recordBean.getGasCardID()%>');">Save</button>
						<!--button class="btn btn-success text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.CREATE_CONFIRM%>','<%=_recordBean.getController()%>','<%=_recordBean.getGasCardID()%>','2');">Save & Post</button --></div>
					<%} else {%>
						<button class="btn btn-success text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.UPDATE_CONFIRM%>','<%=_recordBean.getController()%>','<%=_recordBean.getGasCardID()%>');">Save</button>
						<!--button class="btn btn-success text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.UPDATE_CONFIRM%>','<%=_recordBean.getController()%>','<%=_recordBean.getGasCardID()%>','2');">Save & Post</button --></div>
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
					<button class="btn btn-primary text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.UPDATE%>','<%=_recordBean.getController()%>','<%=_recordBean.getGasCardID()%>');">Edit</button>
				<%}%>
				</div>
				<div class="col-4 text-right">
				<%if("0".equalsIgnoreCase(_recordBean.getStatus())) {%>
					<button class="btn btn-danger text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.DELETE%>','<%=_recordBean.getController()%>','<%=_recordBean.getGasCardID()%>');">Delete</button>
				<%}%>
				</div>
			</div>
		<%}%>
	</div>
</div>
<%@ include file="includeFooter.jsp"%>
<%
}
%>