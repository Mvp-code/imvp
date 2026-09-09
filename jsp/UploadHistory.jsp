<!DOCTYPE html>
<%@ page import="java.util.*, com.util.*, com.beans.*"%>
<jsp:useBean id="_errorBean" class="com.beans.ErrorBean" scope="request" />
<%
Object _rawBean = request.getAttribute("_recordBean");
List dataList  = new ArrayList();
String summary = "";
if (_rawBean instanceof SearchBean) {
    SearchBean _sb = (SearchBean) _rawBean;
    if (_sb.getDataList() != null) dataList = _sb.getDataList();
    summary = _sb.getColumnSortName() != null ? _sb.getColumnSortName() : "";
    request.removeAttribute("_recordBean");
}
%>
<%
com.beans.MainBean _recordBean = new com.beans.MainBean();
_recordBean.setController("UploadHistory");
_recordBean.setDisplayName("Upload History");
int submitType = request.getAttribute("submitType") == null
    ? SubmitType.BROWSE
    : Integer.parseInt(request.getAttribute("submitType").toString().trim());

// Parse key:value summary map
Map<String,String> sm = new java.util.LinkedHashMap<String,String>();
if (summary != null && summary.length() > 0) {
    for (String pair : summary.split("\\|\\|")) {
        String[] kv = pair.split(":", 2);
        if (kv.length == 2) sm.put(kv[0].trim(), kv[1].trim());
    }
}

String[] days = {"Sun","Mon","Tue","Wed","Thu","Fri","Sat"};

String fromDate = "";
String toDate   = "";
%>

<script>
function validatePageData(submitType, isValid) { return isValid; }
</script>

<style>
.uh-section-title {
    font-size: 0.7rem;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 0.08em;
    color: #888;
    margin-bottom: 6px;
    margin-top: 2px;
}
.uh-card {
    border: 1px solid #e0e0e0;
    border-radius: 6px;
    padding: 12px 14px;
    background: #fff;
    height: 100%;
}
.uh-card .big-num {
    font-size: 1.55rem;
    font-weight: 700;
    color: #111;
    line-height: 1.1;
}
.uh-card .sub-label {
    font-size: 0.72rem;
    color: #777;
    margin-top: 1px;
}
.uh-card .split-row {
    display: flex;
    gap: 14px;
    align-items: flex-end;
    flex-wrap: wrap;
}
.uh-card .split-item { text-align: center; flex: 1; min-width: 50px; }
.uh-card .split-item .split-num { font-size: 1.1rem; font-weight: 700; color: #111; }
.uh-card .split-item .split-lbl { font-size: 0.68rem; color: #888; }
.dvic-day-row { display: flex; gap: 4px; margin-top: 6px; flex-wrap: wrap; }
.dvic-day-cell {
    flex: 1; min-width: 36px; text-align: center;
    border: 1px solid #e0e0e0; border-radius: 4px; padding: 3px 2px;
    background: #fafafa;
}
.dvic-day-cell .dc-day  { font-size: 0.6rem; color: #999; }
.dvic-day-cell .dc-num  { font-size: 0.9rem; font-weight: 600; color: #333; }
.sched-day-row { display: flex; gap: 4px; margin-top: 6px; flex-wrap: wrap; }
.sched-day-cell {
    flex: 1; min-width: 36px; text-align: center;
    border: 1px solid #e0e0e0; border-radius: 4px; padding: 3px 2px;
    background: #fafafa;
}
.sched-day-cell .sd-day { font-size: 0.6rem; color: #999; }
.sched-day-cell .sd-num { font-size: 0.9rem; font-weight: 600; color: #333; }
.sched-day-cell.has-data { background: #f5f5f5; border-color: #ccc; }
.type-badge {
    display: inline-block; padding: 2px 8px; border-radius: 3px;
    font-size: 0.78rem; background: #f0f0f0; color: #333; border: 1px solid #ddd;
}
.history-table th { white-space: nowrap; }
.stat-warn { color: #b36200; }
</style>

<%@ include file="includeHeader.jsp"%>

<div class="row my-2">
  <div class="col-12 mb-2">
    <div class="card">

      <div class="card-header table-title-header m-0 py-2">
        <div class="d-flex align-items-center justify-content-between flex-nowrap w-100">
          <div style="font-weight:700; white-space:nowrap;">Upload History &amp; Loaded Data</div>
          <button class="btn btn-primary btn-sm"
                  onclick="submitPageDataForm('<%=SubmitType.SEARCH%>','SmartUpload','','','');">
            <i class="fa fa-upload mr-1"></i> New Upload
          </button>
        </div>
      </div>

      <div class="card-body m-2 p-2">

        <%if (!sm.isEmpty()) {%>

        <%-- ROW 1: Employees | Vehicles | This Week Schedule --%>
        <div class="uh-section-title">People &amp; Fleet</div>
        <div class="row mb-2">

          <%-- Employees --%>
          <div class="col-6 col-md-3 mb-2">
            <div class="uh-card">
              <div class="big-num"><%=sm.getOrDefault("emp_active","—")%></div>
              <div class="sub-label">Active Employees</div>
            </div>
          </div>

          <%-- Vehicles --%>
          <div class="col-6 col-md-3 mb-2">
            <div class="uh-card">
              <div class="split-row">
                <div class="split-item">
                  <div class="split-num"><%=sm.getOrDefault("veh_operational","—")%></div>
                  <div class="split-lbl">Operational</div>
                </div>
                <div class="split-item">
                  <div class="split-num stat-warn"><%=sm.getOrDefault("veh_grounded","—")%></div>
                  <div class="split-lbl">Grounded</div>
                </div>
              </div>
              <div class="sub-label mt-1">Vehicles</div>
            </div>
          </div>

          <%-- Schedule this week --%>
          <%
            boolean anySched = false;
            for (String d : days) {
              String c = sm.getOrDefault("sched_" + d, "0");
              if (!"0".equals(c) && !"—".equals(c) && c.trim().length() > 0) { anySched = true; break; }
            }
          %>
          <div class="col-12 col-md-6 mb-2">
            <div class="uh-card">
              <div class="sub-label mb-1">This Week Schedule (Sun &ndash; Sat)</div>
              <div class="sched-day-row">
                <%for (String d : days) {
                    String cnt = sm.getOrDefault("sched_" + d, "0");
                    boolean hasData = !"0".equals(cnt) && !"—".equals(cnt);
                %>
                <div class="sched-day-cell<%=hasData ? " has-data" : ""%>">
                  <div class="sd-day"><%=d%></div>
                  <div class="sd-num"><%=hasData ? cnt : "<span style='color:#cbd5e1;'>&mdash;</span>"%></div>
                </div>
                <%}%>
              </div>
              <%if (!anySched) {%>
                <div style="font-size:0.72rem; color:#b36200; background:#fff8e1; border:1px solid #ffe082; border-radius:6px; padding:4px 8px; margin-top:6px;">No schedule loaded this week &mdash; upload a Week schedule file to populate this.</div>
              <%}%>
            </div>
          </div>
        </div>

        <%-- ROW 2: Safety | Routes --%>
        <div class="uh-section-title">Safety &amp; Routes</div>
        <div class="row mb-2">

          <%-- Safety Events --%>
          <div class="col-6 col-md-3 mb-2">
            <div class="uh-card">
              <div class="split-row">
                <div class="split-item">
                  <div class="split-num"><%=sm.getOrDefault("safety_this","—")%></div>
                  <div class="split-lbl">This Week</div>
                </div>
                <div class="split-item">
                  <div class="split-num"><%=sm.getOrDefault("safety_last","—")%></div>
                  <div class="split-lbl">Last Week</div>
                </div>
              </div>
              <div class="sub-label mt-1">Safety Events</div>
            </div>
          </div>

          <%-- DA by Date --%>
          <div class="col-12 col-md-9 mb-2">
            <div class="uh-card">
              <div class="row mb-1">
                <div class="col-6">
                  <span class="sub-label">DA by Date &mdash; This Week</span>
                  <span class="ml-2" style="font-size:0.78rem;font-weight:600;"><%=sm.getOrDefault("da_this_total","0")%> total</span>
                </div>
                <div class="col-6 text-right">
                  <span class="sub-label">Last Week &mdash; </span>
                  <span style="font-size:0.78rem;font-weight:600;"><%=sm.getOrDefault("da_last_total","0")%> total</span>
                </div>
              </div>
              <div class="dvic-day-row">
                <%for (String d : days) {
                    String thisVal = sm.getOrDefault("da_this_" + d, "0");
                    String lastVal = sm.getOrDefault("da_last_" + d, "0");
                %>
                <div class="dvic-day-cell" style="min-width:52px;">
                  <div class="dc-day"><%=d%></div>
                  <div class="dc-num"><%="0".equals(thisVal) ? "-" : thisVal%></div>
                  <div style="font-size:0.62rem;color:#aaa;margin-top:1px;"><%="0".equals(lastVal) ? "-" : lastVal%></div>
                </div>
                <%}%>
              </div>
              <div style="font-size:0.65rem;color:#aaa;margin-top:4px;">Top row = this week &nbsp;|&nbsp; Bottom row = last week</div>
            </div>
          </div>

          <%-- DVIC Summary --%>
          <div class="col-12 col-md-6 mb-2">
            <div class="uh-card">
              <div class="row">
                <div class="col-4">
                  <div class="sub-label">This Week</div>
                  <div class="big-num" style="font-size:1.3rem;"><%=sm.getOrDefault("dvic_this","—")%></div>
                  <div class="sub-label mt-1">DVIC Inspections</div>
                </div>
                <div class="col-4 text-center">
                  <div class="sub-label">&lt; 90 sec</div>
                  <div class="big-num stat-warn" style="font-size:1.3rem;"><%=sm.getOrDefault("dvic_lt90","—")%></div>
                  <div class="sub-label mt-1">Under Threshold</div>
                </div>
                <div class="col-4 text-right">
                  <div class="sub-label">Missing</div>
                  <div class="big-num stat-warn" style="font-size:1.3rem;"><%=sm.getOrDefault("dvic_missing","—")%></div>
                  <div class="sub-label mt-1">No Inspection</div>
                </div>
              </div>
              <div class="dvic-day-row mt-1">
                <%for (String d : days) {
                    String cnt = sm.getOrDefault("dvic_day_" + d, "0");
                %>
                <div class="dvic-day-cell">
                  <div class="dc-day"><%=d%></div>
                  <div class="dc-num"><%="0".equals(cnt) ? "-" : cnt%></div>
                </div>
                <%}%>
              </div>
            </div>
          </div>
        </div>

        <hr class="mt-0 mb-3">
        <%}%>

        <%-- Date filter --%>
        <div class="row mb-3">
          <div class="col-12 col-md-8">
            <div class="form-inline">
              <label class="mr-2 text-muted" style="font-size:0.85rem;">From</label>
              <input type="text" id="srhFromDate" name="srhFromDate"
                     class="form-control form-control-sm mr-2"
                     style="width:130px;" value="<%=fromDate%>"
                     placeholder="MM/DD/YYYY">
              <label class="mr-2 text-muted" style="font-size:0.85rem;">To</label>
              <input type="text" id="srhToDate" name="srhToDate"
                     class="form-control form-control-sm mr-2"
                     style="width:130px;" value="<%=toDate%>"
                     placeholder="MM/DD/YYYY">
              <button class="btn btn-secondary btn-sm"
                      onclick="submitPageDataForm('<%=SubmitType.SEARCH%>','UploadHistory','','','&searchFilter=yes');">
                Filter
              </button>
              <button class="btn btn-link btn-sm ml-1"
                      onclick="document.getElementById('srhFromDate').value='';document.getElementById('srhToDate').value='';submitPageDataForm('<%=SubmitType.SEARCH%>','UploadHistory','','','&searchFilter=yes');">
                Clear
              </button>
            </div>
          </div>
        </div>

        <%-- Upload log table --%>
        <%if (dataList == null || dataList.size() == 0) {%>
        <div class="text-center text-muted py-4">
          <i class="fa fa-inbox fa-2x mb-2"></i><br>
          No uploads found<%=fromDate.length() > 0 || toDate.length() > 0 ? " for the selected date range." : "."%>
        </div>
        <%} else {%>
        <div class="table-responsive">
          <table class="table table-sm table-bordered history-table" style="font-size:0.83rem;">
            <thead class="thead-light">
              <tr>
                <th>Upload Date</th>
                <th>File Name</th>
                <th>Detected Type</th>
                <th style="text-align:right;">Total Rows</th>
                <th style="text-align:right;">Loaded</th>
                <th>Uploaded By</th>
              </tr>
            </thead>
            <tbody>
            <%
            for (int i = 0; i < dataList.size(); i++) {
                List row = (ArrayList) dataList.get(i);
                String uDate  = row.size() > 0 && row.get(0) != null ? row.get(0).toString() : "";
                String uFile  = row.size() > 1 && row.get(1) != null ? row.get(1).toString() : "";
                String uType  = row.size() > 2 && row.get(2) != null ? row.get(2).toString() : "";
                String uTotal = row.size() > 3 && row.get(3) != null ? row.get(3).toString() : "";
                String uLoad  = row.size() > 4 && row.get(4) != null ? row.get(4).toString() : "";
                String uUser  = row.size() > 5 && row.get(5) != null ? row.get(5).toString() : "";
                boolean isUnknown = "Unknown".equals(uType);
            %>
              <tr>
                <td><%=uDate%></td>
                <td style="word-break:break-all;"><%=uFile%></td>
                <td><span class="type-badge" style="<%=isUnknown ? "background:#fff8e1;color:#b36200;border-color:#ffe082;" : ""%>"><%=uType%></span></td>
                <td style="text-align:right;"><%=uTotal%></td>
                <td style="text-align:right; <%=!isUnknown && uLoad.length() > 0 && uTotal.length() > 0 && !uLoad.equals(uTotal) ? "color:#b36200;" : ""%>"><%=uLoad%></td>
                <td><%=uUser%></td>
              </tr>
            <%}%>
            </tbody>
          </table>
        </div>
        <div class="text-muted" style="font-size:0.78rem;">
          Showing last <%=dataList.size()%> upload<%=dataList.size() == 1 ? "" : "s"%>.
        </div>
        <%}%>

      </div><%-- card-body --%>
    </div><%-- card --%>
  </div>
</div>

<%@ include file="includeFooter.jsp"%>
