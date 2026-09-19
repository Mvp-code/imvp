<!DOCTYPE html>
<%@ page import="java.util.*, com.util.*, com.beans.*"%>
<jsp:useBean id="_errorBean" class="com.beans.ErrorBean" scope="request" />
<%
// Capture raw bean BEFORE useBean may replace it (SEARCH mode sets SearchBean)
Object _rawBeanObj = request.getAttribute("_recordBean");
List _dataList = new ArrayList();
String detectedType  = "";
String uploadSummary = "";
if (_rawBeanObj instanceof SearchBean) {
    SearchBean _sb = (SearchBean) _rawBeanObj;
    if (_sb.getDataList() != null) _dataList = _sb.getDataList();
    // Remove SearchBean so useBean doesn't try to cast it to SmartUpload (ClassCastException)
    request.removeAttribute("_recordBean");
}
%>
<jsp:useBean id="_recordBean" class="com.beans.SmartUpload" scope="request" />
<%
// actualSubmitType drives display logic
int actualSubmitType = request.getAttribute("submitType") == null
    ? SubmitType.UPLOAD
    : Integer.parseInt(request.getAttribute("submitType").toString().trim());
// formmain must never be multipart — file upload uses a dynamically-created form in JS
int submitType = SubmitType.SEARCH;
detectedType  = _recordBean.getDetectedType();
uploadSummary = _recordBean.getUploadSummary();
String totalRows = "";
String insertedRows = "";
if (uploadSummary != null && uploadSummary.contains("|")) {
    String[] parts = uploadSummary.split("\\|");
    totalRows    = parts.length > 0 ? parts[0] : "";
    insertedRows = parts.length > 1 ? parts[1] : "";
}
%>

<script>
// Stores files dropped via drag-and-drop (input.files is read-only — can't assign FileList directly)
var _smartDropFiles = null;

function initDropZone() {
    var zone  = document.getElementById("dropZone");
    var input = document.getElementById("uploadFileName");
    if (!zone || !input) return;

    zone.addEventListener("dragover", function(e) {
        e.preventDefault();
        zone.classList.add("drag-over");
    });
    zone.addEventListener("dragleave", function() {
        zone.classList.remove("drag-over");
    });
    zone.addEventListener("drop", function(e) {
        e.preventDefault();
        zone.classList.remove("drag-over");
        if (e.dataTransfer.files.length > 0) {
            _smartDropFiles = e.dataTransfer.files;
            // DataTransfer constructor is supported in Chrome/Firefox — lets us assign input.files
            try {
                var dt = new DataTransfer();
                Array.from(e.dataTransfer.files).forEach(function(f) { dt.items.add(f); });
                input.files = dt.files;
            } catch(ex) {}
            showSelectedFile(e.dataTransfer.files[0].name);
        }
    });
    input.addEventListener("change", function() {
        _smartDropFiles = null; // file picker wins; clear drop state
        if (input.files.length > 0) showSelectedFile(input.files[0].name);
    });
}

function showSelectedFile(name) {
    var lbl = document.getElementById("selectedFileName");
    if (lbl) lbl.textContent = name;
    var hint = document.getElementById("dropHint");
    if (hint) hint.style.display = "none";
}

function smartUploadSubmit() {
    var input = document.getElementById("uploadFileName");
    var fileName = "";

    // Prefer file picker; fall back to drag-and-drop variable
    if (input && input.files && input.files.length > 0) {
        fileName = input.files[0].name;
    } else if (_smartDropFiles && _smartDropFiles.length > 0) {
        fileName = _smartDropFiles[0].name;
    }

    if (!fileName) {
        alert("Please select a file to upload.");
        return;
    }

    // For Employee Schedule uploads, ask which day(s) to load + run vehicle allocation.
    var override   = (document.getElementById("tableName") || {value:""}).value;
    var isSchedule = (override === "EmployeeSchedule")
                  || (override === "" && /schedule/i.test(fileName));
    if (isSchedule) {
        var modal = document.getElementById("schedRunModal");
        if (modal) { modal.style.display = "flex"; return; }
    }
    _doSmartUpload("");
}

function _doSmartUpload(selectedType) {
    var modal = document.getElementById("schedRunModal");
    if (modal) modal.style.display = "none";

    var input = document.getElementById("uploadFileName");
    var fileName = "";

    // Prefer file picker; fall back to drag-and-drop variable
    if (input && input.files && input.files.length > 0) {
        fileName = input.files[0].name;
    } else if (_smartDropFiles && _smartDropFiles.length > 0) {
        fileName = _smartDropFiles[0].name;
        try {
            var dt = new DataTransfer();
            dt.items.add(_smartDropFiles[0]);
            input.files = dt.files;
        } catch(ex) {}
    }

    if (!fileName) {
        alert("Please select a file to upload.");
        return;
    }

    var qName = fileName.replace(/[()\[\]]/g, '').replace(/\s+/g, ' ').trim();
    var url = "../servlet/MVPGServlet?submitType=<%=SubmitType.CREATE_CONFIRM%>&controller=SmartUpload"
            + "&uploadFileName=" + encodeURIComponent(qName)
            + "&tableName=" + encodeURIComponent((document.getElementById("tableName") || {value:""}).value)
            + "&dataSeperator=";
    if (selectedType) url += "&selectedType=" + encodeURIComponent(selectedType);

    // Copy session hidden fields from formmain into URL
    var skipNames = {mode:1, boSubmitLock:1, pageSubmitLock:1, tableName:1, dataSeperator:1};
    var els = document.formmain.elements;
    for (var i = 0; i < els.length; i++) {
        var el = els[i];
        if (!el.name || el.type === "file" || skipNames[el.name]) continue;
        if (el.value) url += "&" + el.name + "=" + encodeURIComponent(el.value);
    }

    // Dynamically create a temp multipart form so formmain stays non-multipart
    var form = document.createElement("form");
    form.method = "post";
    form.enctype = "multipart/form-data";
    form.action = url;
    form.style.display = "none";
    form.appendChild(input);          // move file input into temp form
    document.body.appendChild(form);
    form.submit();
}

function validatePageData(submitType, isValid) { return isValid; }

window.addEventListener("load", initDropZone);
</script>

<style>
.smart-upload-zone {
    border: 2px dashed #999;
    border-radius: 6px;
    padding: 32px 16px;
    text-align: center;
    cursor: pointer;
    background: #fafafa;
    color: #555;
    transition: border-color 0.2s, background 0.2s;
}
.smart-upload-zone.drag-over {
    border-color: #333;
    background: #f0f0f0;
}
.smart-upload-zone input[type=file] {
    position: absolute;
    width: 1px;
    height: 1px;
    opacity: 0;
    overflow: hidden;
    top: -9999px;
    left: -9999px;
}
.smart-upload-zone label {
    cursor: pointer;
    font-weight: 500;
}
.upload-result-badge {
    display: inline-block;
    padding: 4px 12px;
    border-radius: 4px;
    font-size: 0.85rem;
    font-weight: 500;
}
.badge-success { background: #e8f5e9; color: #2e7d32; border: 1px solid #a5d6a7; }
.badge-warn    { background: #fff8e1; color: #f57f17; border: 1px solid #ffe082; }
.badge-error   { background: #ffebee; color: #c62828; border: 1px solid #ef9a9a; }
</style>

<%@ include file="includeHeader.jsp"%>

<%-- DA Schedule run-day popup (Today / Next Day [default] / Holiday Run) --%>
<div id="schedRunModal" style="display:none; position:fixed; top:0; left:0; width:100%; height:100%;
     background:rgba(15,23,42,0.45); z-index:1080; align-items:center; justify-content:center;">
  <div style="background:#fff; border-radius:10px; padding:24px 26px; max-width:440px; width:92%;
       box-shadow:0 12px 40px rgba(0,0,0,0.25);">
    <h6 style="font-weight:700; margin-bottom:6px; color:#1e293b;">Load DA Schedule</h6>
    <p style="font-size:0.86rem; color:#475569; margin-bottom:18px;">
      Choose which day(s) to load the schedule and run vehicle allocation for.
    </p>
    <div style="display:flex; flex-direction:column; gap:10px;">
      <button type="button" class="btn btn-outline-primary btn-block"
              onclick="_doSmartUpload('Run');">Today</button>
      <button type="button" id="schedNextDayBtn" class="btn btn-primary btn-block"
              onclick="_doSmartUpload('Next Day Run');">Next Day &nbsp;<small>(default)</small></button>
      <button type="button" class="btn btn-outline-primary btn-block"
              onclick="_doSmartUpload('Holiday Run');">Holiday Run <small>(today + next 2 days)</small></button>
    </div>
    <div style="text-align:right; margin-top:16px;">
      <button type="button" class="btn btn-link btn-sm" style="color:#64748b;"
              onclick="document.getElementById('schedRunModal').style.display='none';">Cancel</button>
    </div>
  </div>
</div>

<div class="row my-2">
  <div class="col-12 mb-2">
    <div class="card">
      <%-- Error / success banner --%>
      <%if (_errorBean != null && _errorBean.getType().length() > 0) {%>
        <div class="row text-center">
          <section class="alert_section">
            <div class="alert-box <%=_errorBean.getType()%>Color"><%=_errorBean.getMesg()%></div>
          </section>
        </div>
      <%}%>

      <div class="card-body m-2 p-2">

        <%-- Result summary shown after upload --%>
        <%if (detectedType != null && detectedType.length() > 0 && actualSubmitType == SubmitType.BROWSE) {%>
        <div class="row mb-3">
          <div class="col-12">
            <div class="p-3" style="background:#f5f5f5; border-radius:6px; border:1px solid #ddd;">
              <h6 class="mb-2" style="font-weight:600;">Upload Result</h6>
              <div class="row">
                <div class="col-md-4">
                  <small class="text-muted">Detected Type</small><br>
                  <span class="upload-result-badge badge-success"><%=detectedType%></span>
                </div>
                <%if (totalRows.length() > 0) {%>
                <div class="col-md-4 mt-2 mt-md-0">
                  <small class="text-muted">Rows Processed</small><br>
                  <strong><%=insertedRows%></strong> of <strong><%=totalRows%></strong> loaded
                </div>
                <%}%>
              </div>
            </div>
          </div>
        </div>
        <%}%>

        <%-- Upload form (always visible) --%>
        <div class="row mb-4">
          <div class="col-12 col-md-8 offset-md-2">

            <h6 class="mb-2" style="font-weight:600;">Upload an Amazon File</h6>
            <p class="text-muted" style="font-size:0.85rem; margin-bottom:12px;">
              Drop any Amazon portal file below. The type is detected automatically from the filename.
              CSV and Excel (.xlsx) files are supported.
            </p>

            <div id="uploadFormWrapper">
              <div class="smart-upload-zone" id="dropZone"
                   onclick="document.getElementById('uploadFileName').click()">
                <div id="dropHint">
                  <i class="fa fa-cloud-upload fa-2x mb-2" style="color:#888;"></i><br>
                  <label>Drag &amp; drop file here, or click to browse</label><br>
                  <small class="text-muted">DSP_Overview_Dashboard, AssociateData, VehiclesData, Routes, Itineraries, Schedule, Safety&hellip;</small>
                </div>
                <input type="file" id="uploadFileName" name="uploadFileName"
                       accept=".csv,.xlsx,.xls,.txt">
                <div id="selectedFileName" style="margin-top:8px; font-weight:500; color:#333;"></div>
              </div>

              <div class="row mt-3">
                <div class="col-12 col-md-6">
                  <label class="col-form-label col-form-label-sm text-muted">
                    Override Type <small>(leave blank for auto-detect)</small>
                  </label>
                  <select name="tableName" id="tableName" class="form-control form-control-sm">
                    <option value="">-- Auto Detect --</option>
                    <option value="Employee">Employee (AssociateData)</option>
                    <option value="Vehicles">Vehicles (VehiclesData)</option>
                    <option value="EmployeeSchedule">Employee Schedule</option>
                    <option value="DashboardOverview">Dashboard Overview (Scorecard)</option>
                    <option value="SafetyDashboard">Safety Dashboard</option>
                    <option value="Daily Routes">Daily Routes</option>
                    <option value="Daily Itineraries">Daily Itineraries</option>
                    <option value="DVIC">DVIC Pre-Trip</option>
                    <option value="Escalations">Escalations / ORCAS</option>
                    <option value="WST Delivered Packages">WST Delivered Packages</option>
                    <option value="WST Service Details">WST Service Details</option>
                    <option value="WST Weekly Report">WST Weekly Report</option>
                    <option value="Associates Concessions">Associates Concessions</option>
                    <option value="Engine Off Compliance (EOC) Overview">EOC Overview</option>
                    <option value="DeliveryOverview">Delivery Overview</option>
                    <option value="QualityOverview">Quality Overview</option>
                    <option value="Station Level">Station Level</option>
                  </select>
                </div>
                <div class="col-12 col-md-6 d-flex align-items-end mt-2 mt-md-0">
                  <input type="hidden" name="dataSeperator" value="">
                  <button type="button" class="btn btn-primary btn-sm"
                          onclick="smartUploadSubmit();">
                    <i class="fa fa-upload mr-1"></i> Upload &amp; Load
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>

        <%-- inline filename -> type detection for the recent-uploads preview --%>
        <%!
        private String suDetectType(String f) {
          if (f == null) return "Unknown";
          String n = f.toLowerCase();
          if (n.contains("associatedata")) return "Employee";
          if (n.contains("vehiclesdata")) return "Vehicles";
          if (n.contains("schedule")) return "EmployeeSchedule";
          if (n.contains("dsp_overview") || n.contains("overview_dashboard")) return "DashboardOverview";
          if (n.contains("safety")) return "SafetyDashboard";
          if (n.contains("orcas") || n.contains("escalation")) return "Escalations";
          if (n.contains("itinerar")) return "Daily Itineraries";
          if (n.contains("route")) return "Daily Routes";
          if (n.contains("dvic")) return "DVIC";
          if (n.contains("sentiment")) return "Sentiment";
          if (n.contains("station") && n.contains("level")) return "StationLevel";
          if (n.contains("concession")) return "Associate Concessions";
          if (n.contains("eoc")) return "EOC Overview";
          if (n.contains("tenure") || n.contains("workforce")) return "Workforce";
          if (n.contains("delivery")) return "DeliveryOverview";
          if (n.contains("quality")) return "QualityOverview";
          return "Unknown";
        }
        %>

        <%-- Upload history --%>
        <%
        if (_dataList != null && _dataList.size() > 0) {
        %>
        <hr>
        <h6 class="mb-2" style="font-weight:600;">Recent Uploads</h6>
        <div class="table-responsive">
          <table class="table table-sm table-bordered" style="font-size:0.85rem;">
            <thead class="thead-light">
              <tr>
                <th>Date</th>
                <th>File Name</th>
                <th>Detected Type</th>
                <th style="text-align:right;">Total Rows</th>
                <th style="text-align:right;">Loaded Rows</th>
                <th>Result</th>
              </tr>
            </thead>
            <tbody>
            <%
            for (int i = 0; i < _dataList.size(); i++) {
                List row = (ArrayList) _dataList.get(i);
                // col 0 = GENERIC_UPLOADID (skip), 1 = Date, 2 = FILE_NAME, 3 = TOTAL_ROWS, 4 = ACTUAL_ROWS
                String uDate  = row.size() > 1 && row.get(1) != null ? row.get(1).toString() : "";
                String uFile  = row.size() > 2 && row.get(2) != null ? row.get(2).toString() : "";
                String uTotal = row.size() > 3 && row.get(3) != null ? row.get(3).toString() : "";
                String uActual= row.size() > 4 && row.get(4) != null ? row.get(4).toString() : "";
                String uType  = suDetectType(uFile);
                boolean unknown = "Unknown".equals(uType);
                int tot = 0, act = 0;
                try { tot = Integer.parseInt(uTotal.trim()); } catch (Exception e) {}
                try { act = Integer.parseInt(uActual.trim()); } catch (Exception e) {}
                String badge, bStyle;
                if (unknown)          { badge = "Unrecognized"; bStyle = "background:#fff8e1;color:#b36200;border:1px solid #ffe082;"; }
                else if (tot == 0)    { badge = "No rows";      bStyle = "background:#f1f5f9;color:#475569;border:1px solid #e2e8f0;"; }
                else if (act == 0)    { badge = "Failed";       bStyle = "background:#fdecec;color:#b91c1c;border:1px solid #f3c9c9;"; }
                else if (act < tot)   { badge = "Partial";      bStyle = "background:#fff8e1;color:#b36200;border:1px solid #ffe082;"; }
                else                  { badge = "Loaded";       bStyle = "background:#e7f6ee;color:#15803d;border:1px solid #b7e4c7;"; }
            %>
              <tr>
                <td><%=uDate%></td>
                <td style="word-break:break-all;"><%=uFile%></td>
                <td><span style="display:inline-block;padding:2px 8px;border-radius:6px;font-size:0.78rem;font-weight:600;<%=unknown ? "background:#fff8e1;color:#b36200;border:1px solid #ffe082;" : "background:#eef2f7;color:#334155;border:1px solid #e2e8f0;"%>"><%=uType%></span></td>
                <td style="text-align:right;"><%=uTotal%></td>
                <td style="text-align:right;<%=(tot > 0 && act < tot) ? "color:#b36200;font-weight:600;" : ""%>"><%=uActual%></td>
                <td><span style="display:inline-block;padding:2px 9px;border-radius:999px;font-size:0.75rem;font-weight:700;<%=bStyle%>"><%=badge%></span></td>
              </tr>
            <%}%>
            </tbody>
          </table>
        </div>
        <%}%>

      </div><%-- card-body --%>
    </div><%-- card --%>
  </div>
</div>

<%@ include file="includeFooter.jsp"%>
