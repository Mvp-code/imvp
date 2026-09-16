<!DOCTYPE html>
<%@ page import="java.util.*, com.util.*, com.beans.*"%>
<jsp:useBean id="_errorBean" class="com.beans.ErrorBean" scope="request"/>
<jsp:useBean id="_mainUtil"  class="com.util.MainUtil"   scope="request"/>
<%
int submitType = request.getAttribute("submitType") == null
        ? SubmitType.SEARCH
        : Integer.parseInt(request.getAttribute("submitType").toString().trim());

/* Cast _recordBean to the correct type based on submitType */
SearchBean _searchBean = new SearchBean();
DAStatus   _recordBean = new DAStatus();
if (submitType == SubmitType.SEARCH) {
    Object _raw = request.getAttribute("_recordBean");
    if (_raw instanceof SearchBean) _searchBean = (SearchBean) _raw;
} else {
    Object _raw = request.getAttribute("_recordBean");
    if (_raw instanceof DAStatus) _recordBean = (DAStatus) _raw;
}

/* ---- SEARCH / LIST VIEW ---- */
if (submitType == SubmitType.SEARCH) {
    List dataList   = _searchBean.getDataList();
    Map  transMap   = _searchBean.getTransMap() == null ? new HashMap() : _searchBean.getTransMap();
    String autoSMS  = transMap.get("autoSMS") == null ? "N" : transMap.get("autoSMS").toString();
    boolean hasSMS  = _searchBean.isDisplaySMSBtn();

    /* ---- derive per-row display data & aggregate stats in one pass ---- */
    int cntTotal = dataList.size();
    int cntConfirmed = 0, cntAwaiting = 0, cntNotContacted = 0, cntAvailable = 0;

    /* unique wave-times and employee names for filter dropdowns */
    List<String> waveTimes = new ArrayList<String>();
    List<String> empNames  = new ArrayList<String>();

    /* per-row derived data stored as parallel List<String[]> */
    /* [0]=confID [1]=schedDate [2]=schedTime [3]=cleanName [4]=mobile
       [5]=smsDate [6]=smsBadge [7]=replyDate [8]=replyBadge
       [9]=comments [10]=confirmedBy [11]=rawStatus [12]=pillClass [13]=pillLabel
       [14]=actionHtml [15]=dataStatus (for JS filter) */
    List<String[]> rows = new ArrayList<String[]>();

    for (int i = 0; i < dataList.size(); i++) {
        List row = (List) dataList.get(i);
        String confID       = row.get(0) == null ? "" : row.get(0).toString().trim();
        String schedDT      = row.get(1) == null ? "" : row.get(1).toString().trim();
        String empRaw       = row.get(2) == null ? "" : row.get(2).toString().trim();
        String smsStatus    = row.get(3) == null ? "" : row.get(3).toString().trim();
        String replyRaw     = row.get(4) == null ? "" : row.get(4).toString().trim();
        String comments     = row.get(5) == null ? "" : row.get(5).toString().trim();
        String confirmedBy  = row.get(6) == null ? "" : row.get(6).toString().trim();
        String confirmation = row.get(7) == null ? "" : row.get(7).toString().trim();

        /* split schedule date/time */
        String schedDate = "", schedTime = "";
        if (schedDT.length() > 10) {
            schedDate = schedDT.substring(0, 10);
            schedTime = schedDT.substring(10).trim();
        } else {
            schedDate = schedDT;
        }

        /* strip HTML from emp raw and split name / mobile */
        String empClean = empRaw.replaceAll("<[^>]+>", "").trim();
        String cleanName = empClean, mobile = "";
        int dashIdx = empClean.lastIndexOf(" - ");
        if (dashIdx > 0) {
            cleanName = empClean.substring(0, dashIdx).trim();
            mobile    = empClean.substring(dashIdx + 3).trim();
        }

        /* wave-time dropdown */
        if (schedTime.length() > 0 && !waveTimes.contains(schedTime))
            waveTimes.add(schedTime);

        /* DA name dropdown */
        if (cleanName.length() > 0 && !empNames.contains(cleanName))
            empNames.add(cleanName);

        /* SMS column */
        String smsDate = "", smsBadge = "";
        if (smsStatus.length() > 0) {
            int dashPos = smsStatus.lastIndexOf(" - ");
            smsDate  = dashPos > 0 ? smsStatus.substring(0, dashPos).trim() : smsStatus;
            String smsSt = dashPos > 0 ? smsStatus.substring(dashPos + 3).trim() : "";
            smsBadge = "<span class='pill slate'><span class='d'></span>" + smsSt + "</span>";
        }

        /* Response column */
        String replyDate = "", replyBadge = "";
        if (replyRaw.length() > 0) {
            String replyClean = replyRaw.replaceAll("<[^>]+>", "").trim();
            int brPos = replyClean.indexOf("  ");
            replyDate  = brPos > 0 ? replyClean.substring(0, brPos).trim() : "";
            String replyMsg = brPos > 0 ? replyClean.substring(brPos).trim() : replyClean;
            String badgeCls = replyMsg.toLowerCase().contains("confirm") ? "green" : "slate";
            replyBadge = "<span class='pill " + badgeCls + "'><span class='d'></span>" + replyMsg + "</span>";
        }

        /* status pill + action + JS filter key */
        String pillClass = "slate", pillLabel = confirmation, dataStatus = "other";
        String actionHtml = "";
        boolean smsSent = smsStatus.length() > 0;

        if ("Confirmed".equalsIgnoreCase(confirmation)) {
            pillClass = "green"; pillLabel = "Confirmed"; dataStatus = "confirmed";
            cntConfirmed++;
        } else if ("Sent".equalsIgnoreCase(confirmation)
                || ("Not Confirmed".equalsIgnoreCase(confirmation) && smsSent)) {
            pillClass = "amber"; pillLabel = "Awaiting"; dataStatus = "awaiting";
            if (hasSMS)
                actionHtml = "<div class='subpill'><button class='btn sm' onclick='confirmDA(this,\"" + confID + "\")'>Confirm</button></div>";
            cntAwaiting++;
        } else if ("Not Confirmed".equalsIgnoreCase(confirmation)) {
            pillClass = "red"; pillLabel = "Not contacted"; dataStatus = "notcontacted";
            if (hasSMS)
                actionHtml = "<div class='subpill'><button class='btn sm' onclick='sendSMSRow(this,\"" + confID + "\")'>Send SMS</button></div>";
            cntNotContacted++;
        } else if ("Available".equalsIgnoreCase(confirmation)) {
            pillClass = "blue"; pillLabel = "Available"; dataStatus = "available";
            if (hasSMS)
                actionHtml = "<div class='subpill'><button class='btn sm' onclick='sendSMSRow(this,\"" + confID + "\")'>Send SMS</button></div>";
            cntAvailable++;
        } else if (confirmation.startsWith("-")) {
            pillClass = "slate"; pillLabel = "No block"; dataStatus = "noblock";
        }

        rows.add(new String[]{
            confID, schedDate, schedTime, cleanName, mobile,
            smsDate, smsBadge, replyDate, replyBadge,
            comments, confirmedBy, confirmation,
            pillClass, pillLabel, actionHtml, dataStatus
        });
    }
%>
<%@ include file="includeHeader.jsp"%>
<script src="../jsp/assets/js/mvpx-list.js?v=20260911b"></script>
<style>
:root{--da-blue:var(--theme-accent,#2563EB);--da-blue-dark:var(--theme-accent-dark,#1D4ED8);--da-blue-50:var(--status-info-bg,#EFF4FF);--da-blue-100:#DBE6FF;
--da-ink:#0B1220;--da-text:#1F2937;--da-muted:#475569;--da-faint:#64748B;
--da-line:#E4E8F0;--da-line-soft:#EEF1F6;--da-canvas:#F5F7FA;
--da-green:var(--status-ok-fg,#15803D);--da-green-50:var(--status-ok-bg,#E7F6EE);
--da-red:var(--status-action-fg,#C62828);--da-red-50:var(--status-action-bg,#FCEBEB);
--da-amber:var(--status-warn-fg,#B45309);--da-amber-50:var(--status-warn-bg,#FBF1E2);
--da-shadow:0 1px 2px rgba(16,24,40,.05),0 1px 3px rgba(16,24,40,.06);}
.da-wrap{padding:4px 0 60px}
.da-crumb{font-size:13px;color:var(--da-muted);margin-bottom:10px}
.da-crumb .tag{background:var(--da-blue-50);color:var(--da-blue-dark);font-weight:700;font-size:12px;padding:2px 8px;border-radius:6px}
.da-headrow{display:flex;justify-content:space-between;align-items:flex-start;gap:12px;margin-bottom:12px;flex-wrap:wrap}
.da-headrow h2{margin:0 0 6px;font-size:28px;font-weight:700;color:#111827}
.statchips{display:flex;gap:7px;flex-wrap:wrap}
.statchip{font-size:13px;font-weight:700;color:#374151;background:#F3F4F6;border:1px solid var(--da-line);border-radius:999px;padding:4px 12px;display:inline-flex;gap:6px;align-items:center}
.statchip b{color:#111827;font-weight:700}
.statchip .dot{width:7px;height:7px;border-radius:50%;flex-shrink:0}.da-toolbar{display:flex;align-items:center;gap:8px;flex-wrap:wrap;background:#fff;border:1px solid var(--da-line);border-radius:11px;padding:9px 11px;box-shadow:var(--da-shadow);margin-bottom:6px}
.daterange-fld{display:inline-flex;align-items:center;gap:5px;border:1px solid var(--da-line);border-radius:8px;padding:4px 9px;background:#fff}
.daterange-fld input[type=date]{border:none;font-size:13px;padding:3px 2px;font-family:inherit;color:var(--da-text);background:transparent}
.daterange-fld input[type=date]:focus{outline:none}
.daterange-fld .dash{color:var(--da-faint);font-size:13px}
.da-quick{display:inline-flex;gap:4px}
.da-quick button{border:1px solid var(--da-line);background:#fff;color:var(--da-muted);border-radius:7px;padding:6px 10px;font-size:12px;font-weight:600;cursor:pointer;transition:background .15s}
.da-quick button.on{background:var(--da-blue-50);border-color:var(--da-blue-100);color:var(--da-blue-dark)}
.da-flt{border:1px solid var(--da-line);border-radius:8px;padding:8px 10px;font-size:13.5px;background:#fff;cursor:pointer}
.da-flt:focus{outline:none;border-color:var(--da-blue);box-shadow:0 0 0 3px var(--da-blue-50)}
.da-chips{display:flex;gap:7px;flex-wrap:wrap;margin:8px 0 0;min-height:0}
.da-chip{background:var(--da-blue-50);border:1px solid var(--da-blue-100);color:var(--da-blue-dark);border-radius:999px;padding:4px 8px 4px 11px;font-size:13px;font-weight:700;display:inline-flex;align-items:center;gap:6px}
.da-chip .x{cursor:pointer;border:none;background:transparent;color:var(--da-blue-dark);font-size:13px;line-height:1;padding:0 2px}
.tablewrap{background:#fff;border:1px solid var(--da-line);border-radius:11px;overflow:hidden;box-shadow:var(--da-shadow);margin-top:12px}
.tablewrap table{width:100%;border-collapse:collapse}
.tablewrap thead th{text-align:left;font-size:13px;color:#111827;font-weight:700;padding:11px 13px;background:#FAFCFF;border-bottom:1px solid var(--da-line)}
.tablewrap thead th.srt{cursor:pointer;user-select:none}
.tablewrap thead th.srt:hover{background:#EEF3FB}
.tablewrap thead th .ar{color:var(--da-blue);font-size:11px;font-weight:800;margin-left:3px}
.tablewrap tbody td{padding:11px 13px;border-bottom:1px solid var(--da-line-soft);font-size:14.5px;font-weight:400;color:#111827;vertical-align:middle}
.tablewrap tbody tr:last-child td{border-bottom:none}
.tablewrap tbody tr:hover{background:#FAFBFE}
.nm{font-weight:700;color:#111827}.meta{font-size:13px;color:#6B7280}
.pill{display:inline-flex;align-items:center;gap:5px;padding:3px 9px;border-radius:999px;font-size:12px;font-weight:700}
.pill .d{width:6px;height:6px;border-radius:50%;flex-shrink:0}
.pill.green{background:var(--status-ok-bg);color:var(--status-ok-fg)}.pill.green .d{background:var(--status-ok-fg)}
.pill.amber{background:var(--status-warn-bg);color:var(--status-warn-fg)}.pill.amber .d{background:var(--status-warn-fg)}
.pill.red{background:var(--status-action-bg);color:var(--status-action-fg)}.pill.red .d{background:var(--status-action-fg)}
.pill.escalation{background:var(--status-escalation-bg);color:var(--status-escalation-fg)}.pill.escalation .d{background:var(--status-escalation-fg)}
.pill.blue{background:var(--status-info-bg);color:var(--status-info-fg)}.pill.blue .d{background:var(--status-info-fg)}
.pill.blue{background:var(--da-blue-50);color:var(--da-blue-dark)}.pill.blue .d{background:var(--da-blue)}
.pill.slate{background:#F1F5F9;color:#475569}.pill.slate .d{background:#64748B}
.subpill{margin-top:4px}
.statusSel{border:1px solid var(--da-line);border-radius:7px;padding:5px 8px;font-size:12.5px;font-family:inherit;background:#fff;font-weight:600;min-width:150px;cursor:pointer}
.statusSel:focus{outline:none;border-color:var(--da-blue);box-shadow:0 0 0 3px var(--da-blue-50)}
.statusSel.st-green{color:var(--status-ok-fg);border-color:var(--status-ok-border)}
.statusSel.st-red{color:var(--status-action-fg);border-color:var(--status-action-border)}
.statusSel.st-amber{color:var(--status-warn-fg);border-color:var(--status-warn-border)}
.statusSel.st-blue{color:var(--status-info-fg);border-color:var(--status-info-border)}
.statusSel.st-escalation{color:var(--status-escalation-fg);border-color:var(--status-escalation-border)}
.cmt{border:1px solid var(--da-line);border-radius:7px;padding:5px 8px;font-size:12.5px;width:140px;font-family:inherit;background:#fff}
.cmt:focus{outline:none;border-color:var(--da-blue);box-shadow:0 0 0 3px var(--da-blue-50)}
.tablefoot{display:flex;justify-content:space-between;align-items:center;padding:9px 13px;border-top:1px solid var(--da-line-soft);font-size:13px;color:var(--da-muted);gap:8px;flex-wrap:wrap}
.btn{border:1px solid var(--da-line);background:#fff;color:#111827;padding:7px 13px;border-radius:8px;font-size:13.5px;font-weight:600;cursor:pointer;display:inline-flex;align-items:center;gap:6px;white-space:nowrap;transition:background .15s}
.btn:hover{background:var(--da-line-soft)}
.btn.primary{background:var(--da-blue);border-color:var(--da-blue);color:#fff}.btn.primary:hover{background:var(--da-blue-dark)}
.btn.success{background:var(--da-green);border-color:var(--da-green);color:#fff}.btn.success:hover{background:#166534}
.btn.sm{padding:5px 9px;font-size:12px}
.btn.danger{background:#DC2626;border-color:#DC2626;color:#fff}
.toggle-wrap{display:inline-flex;align-items:center;gap:7px;font-size:12.5px;font-weight:600;color:var(--da-muted)}
.toggle-track{width:36px;height:20px;border-radius:999px;background:#D1D5DB;cursor:pointer;position:relative;transition:background .2s;border:none;padding:0;flex-shrink:0}
.toggle-track.on{background:var(--da-green)}
.toggle-track::after{content:'';position:absolute;top:2px;left:2px;width:16px;height:16px;border-radius:50%;background:#fff;transition:transform .2s;box-shadow:0 1px 2px rgba(0,0,0,.2)}
.toggle-track.on::after{transform:translateX(16px)}
.da-toast{position:fixed;bottom:24px;right:24px;background:#0B1220;color:#fff;padding:10px 16px;border-radius:10px;font-size:13px;font-weight:600;z-index:9999;opacity:0;transform:translateY(8px);transition:opacity .25s,transform .25s;pointer-events:none}
.da-toast.show{opacity:1;transform:translateY(0)}
.da-empty{text-align:center;color:var(--da-faint);padding:32px;font-size:14px}

/* Salesforce-style type preview — this page only.
   Inter (primary) · DM Sans · Open Sans · Work Sans. Headers, inputs, table, chips, buttons. */
body,
h1, h2, h3, h4,
.da-headrow h2,
.sb-brand-name, .sb-label, .tb-page,
.da-wrap, .statchip, .statchip b, .da-crumb, .da-chip, .pill, .nm, .meta,
.tablewrap thead th, .tablewrap tbody td, .tablefoot,
.da-flt, .cmt, .statusSel, .daterange-fld input, .da-quick button,
.btn, input, select, textarea, button,
.mvpx-search input,
.select2-container .select2-selection--single,
.select2-selection__rendered {
  font-family: 'Inter', 'DM Sans', 'Open Sans', 'Work Sans', 'Segoe UI', sans-serif;
}
.da-headrow h2 {
  font-size: 24px;
  font-weight: 700;
  letter-spacing: -.015em;
  color: #181818;
}
.tablewrap thead th {
  font-size: 12px;
  font-weight: 600;
  letter-spacing: .01em;
  text-transform: none;
}
input, select, textarea, .da-flt, .cmt, .statusSel {
  font-size: 13px;
  font-weight: 400;
}
</style>

<div class="da-wrap">
  <%-- heading row --%>
  <div class="da-headrow">
    <div>
      <h2>DA Confirmation</h2>
      <div class="statchips">
        <span class="statchip"><span class="dot" style="background:var(--da-blue)"></span><b id="cnt-total"><%=cntTotal%></b> scheduled</span>
        <span class="statchip"><span class="dot" style="background:var(--da-green)"></span><b id="cnt-confirmed"><%=cntConfirmed%></b> confirmed</span>
        <span class="statchip"><span class="dot" style="background:var(--da-amber)"></span><b id="cnt-awaiting"><%=cntAwaiting%></b> awaiting</span>
        <span class="statchip"><span class="dot" style="background:var(--da-red)"></span><b id="cnt-notcontacted"><%=cntNotContacted%></b> not contacted</span>
      </div>
    </div>
    <div style="display:flex;gap:8px;align-items:center;flex-wrap:wrap">
      <%if(hasSMS){%>
      <div class="toggle-wrap">
        <button id="autoSMSToggle"
                class="toggle-track<%="Y".equals(autoSMS)?" on":""%>"
                title="Auto-send SMS on schedule upload"
                onclick="toggleAutoSMS(this)"></button>
        <span id="autoSMSLabel">Auto SMS: <%="Y".equals(autoSMS)?"ON":"OFF"%></span>
      </div>
      <%}%>
      <button class="btn" onclick="daPrint('xls')" title="Export to Excel"><i class="fas fa-file-excel"></i> Excel</button>
      <button class="btn" onclick="daPrint('')" title="Download PDF"><i class="fas fa-file-pdf"></i> PDF</button>
      <button class="btn primary" onclick="submitPageDataForm('<%=SubmitType.CREATE%>','<%=_searchBean.getController()%>');">&#xFF0B; New</button>
    </div>
  </div>

  <%-- filter toolbar --%>
  <div class="da-toolbar">
    <div class="daterange-fld">
      <span style="color:var(--da-faint)">&#128197;</span>
      <input type="date" id="filterFrom" data-mdy="<%=_searchBean.getSrhFromDate()%>" onchange="dateSearch()">
      <span class="dash">&ndash;</span>
      <input type="date" id="filterTo" data-mdy="<%=_searchBean.getSrhToDate()%>" onchange="dateSearch()">
    </div>
    <div class="da-quick">
      <button id="btnToday" class="on" onclick="quickDate(this,'today')">Today</button>
      <button id="btnTomorrow" onclick="quickDate(this,'tomorrow')">Tomorrow</button>
    </div>
    <select class="da-flt" id="filterEmp" onchange="applyFilters()" style="min-width:180px">
      <option value="">All DAs</option>
      <%for(String en : empNames){%>
      <option value="<%=en.toLowerCase()%>"><%=en%></option>
      <%}%>
    </select>
    <select class="da-flt" id="filterStatus" onchange="applyFilters()">
      <option value="">All statuses</option>
      <option value="notcontacted">Not contacted</option>
      <option value="awaiting">Awaiting</option>
      <option value="confirmed">Confirmed</option>
      <option value="available">Available</option>
    </select>
    <select class="da-flt" id="filterWave" onchange="applyFilters()">
      <option value="">All wave times</option>
      <%for(String wt : waveTimes){%>
      <option value="<%=wt.toLowerCase()%>"><%=wt%></option>
      <%}%>
    </select>
  </div>

  <%-- active filter chips --%>
  <div class="da-chips" id="activeChips"></div>
  <div class="da-typesum" id="typeSum"></div>

  <%-- error banner --%>
  <%if(_errorBean != null && _errorBean.getType().length() > 0){%>
  <div class="row text-center mt-2">
    <section class="alert_section">
      <div class="alert-box <%=_errorBean.getType()%>Color"><%=_errorBean.getMesg()%></div>
    </section>
  </div>
  <%}%>

  <%-- main table --%>
  <div class="tablewrap">
    <table>
      <thead>
        <tr>
          <th style="width:32px"><input type="checkbox" id="selectAll" onchange="toggleSelectAll(this)"></th>
          <th class="srt" onclick="mvpxSort(this)">Schedule Date<span class="ar"></span></th>
          <th class="srt" onclick="mvpxSort(this)">Employee<span class="ar"></span></th>
          <th class="srt" onclick="mvpxSort(this)">SMS<span class="ar"></span></th>
          <th class="srt" onclick="mvpxSort(this)">Response<span class="ar"></span></th>
          <th class="srt" onclick="mvpxSort(this)">Comments<span class="ar"></span></th>
          <th class="srt" onclick="mvpxSort(this)">Confirmed By<span class="ar"></span></th>
          <th class="srt" onclick="mvpxSort(this)">Status<span class="ar"></span></th>
        </tr>
      </thead>
      <tbody id="daRows">
        <%if(rows.isEmpty()){%>
        <tr><td colspan="8" class="da-empty">No confirmation records for this date range.</td></tr>
        <%}%>
        <%for(String[] r : rows){
          String confID      = r[0];
          String schedDate   = r[1];
          String schedTime   = r[2];
          String cleanName   = r[3];
          String mobile      = r[4];
          String smsDate     = r[5];
          String smsBadge    = r[6];
          String replyDate   = r[7];
          String replyBadge  = r[8];
          String cmts        = r[9];
          String confBy      = r[10];
          String rawStatus   = r[11];
          String pillClass   = r[12];
          String pillLabel   = r[13];
          String actionHtml  = r[14];
          String dataStatus  = r[15];
          String searchKey   = (cleanName + " " + mobile).toLowerCase();
        %>
        <tr data-id="<%=confID%>"
            data-st="<%=dataStatus%>"
            data-name="<%=searchKey%>"
            data-wave="<%=schedTime.toLowerCase()%>"
            data-status-raw="<%=rawStatus%>">
          <td><input type="checkbox" class="rowCheck" value="<%=confID%>"></td>
          <td>
            <%=schedDate%>
            <div class="meta"><%=schedTime%></div>
          </td>
          <td class="nm">
            <%=cleanName%>
            <%if(mobile.length()>0){%><div class="meta"><%=mobile%></div><%}%>
          </td>
          <td class="meta">
            <%=smsDate.length()>0?smsDate:"&mdash;"%>
            <%if(smsBadge.length()>0){%><div class="subpill"><%=smsBadge%></div><%}%>
          </td>
          <td class="meta">
            <%=replyDate.length()>0?replyDate:"&mdash;"%>
            <%if(replyBadge.length()>0){%><div class="subpill"><%=replyBadge%></div><%}%>
          </td>
          <td>
            <input class="cmt" value="<%=cmts.replace("\"","&quot;").replace("<","&lt;")%>"
                   placeholder="Add note&hellip;"
                   data-id="<%=confID%>"
                   data-orig="<%=cmts.replace("\"","&quot;")%>"
                   onblur="saveComment(this)">
          </td>
          <td class="meta"><%=confBy.length()>0?confBy:"&mdash;"%></td>
          <td>
            <%
              String[] _stOpts = {"Not Confirmed","Confirmed","Confirmed with block","Confirmed without block","Available with no block","Available with block","Review"};
              boolean _stMatched = false;
              for (String _o : _stOpts) { if (_o.equalsIgnoreCase(rawStatus)) { _stMatched = true; break; } }
            %>
            <select class="statusSel st-<%=pillClass%>" onchange="changeStatus(this,'<%=confID%>')" title="Change status">
              <% if (!_stMatched && rawStatus != null && rawStatus.trim().length() > 0) { %>
              <option value="<%=rawStatus%>" selected><%=rawStatus%></option>
              <% } %>
              <% for (String _o : _stOpts) { %>
              <option value="<%=_o%>"<%=_o.equalsIgnoreCase(rawStatus)?" selected":""%>><%=_o%></option>
              <% } %>
            </select>
            <%=actionHtml%>
          </td>
        </tr>
        <%}%>
      </tbody>
    </table>
    <div class="tablefoot">
      <span id="showCount">Showing <%=rows.size()%> of <%=cntTotal%></span>
      <div style="display:flex;gap:8px;align-items:center;flex-wrap:wrap">
        <%if(hasSMS){%>
        <button class="btn success sm" id="bulkSMSBtn" onclick="sendBulkSMS(this)">
          &#9993; Send confirmation SMS
        </button>
        <%}%>
        <button class="btn sm" onclick="submitPageDataForm('<%=SubmitType.SEARCH%>','<%=_searchBean.getController()%>')">&#8635; Refresh</button>
      </div>
    </div>
  </div>
</div>

<div class="da-toast" id="daToast"></div>

<script>
/* ---- helpers ---- */
var _ctrl  = '<%=_searchBean.getController()%>';
var _stDyn = <%=SubmitType.DYNAMIC%>;

function toast(msg, ok) {
  var t = document.getElementById('daToast');
  t.textContent = msg;
  t.style.background = ok === false ? (typeof mvpxCssVar==='function'?mvpxCssVar('--status-danger-solid-hover','#B91C1C'):'#B91C1C') : '#0B1220';
  t.classList.add('show');
  setTimeout(function(){ t.classList.remove('show'); }, 3000);
}

function ajaxPost(params, cb) {
  /* URL-encoded (not multipart) so the servlet parses params; include login/session
     fields or the request is rejected with the login page. */
  var body = new URLSearchParams();
  body.append('submitType', _stDyn);
  body.append('controller', _ctrl);
  ['entityID','loginUser','loginUserID','loginUserRoles','loginUserDisplayName'].forEach(function(k){
    var el = document.getElementById(k); if (el) body.append(k, el.value);
  });
  for (var k in params) body.append(k, params[k]);
  fetch('MVPGServlet', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: body.toString()
  })
    .then(function(r){ return r.text(); })
    .then(function(txt){ cb(txt); })
    .catch(function(){ cb(''); });
}

/* ---- filter state ---- */
/* grouped count summary (shared engine reads window.MVPXL.summary) */
window.MVPXL = { summary: { key:'st', label:'By status', filterId:'filterStatus' } };
var _st = { emp:'', status:'', wave:'' };

function applyFilters() {
  _st.emp    = (document.getElementById('filterEmp').value || '').toLowerCase();
  _st.status = (document.getElementById('filterStatus').value || '').toLowerCase();
  _st.wave   = (document.getElementById('filterWave').value || '').toLowerCase();

  var rows = document.querySelectorAll('#daRows tr[data-id]');
  var shown = 0;
  rows.forEach(function(r) {
    var nm  = r.dataset.name  || '';
    var st  = r.dataset.st    || '';
    var wv  = r.dataset.wave  || '';
    var vis = (!_st.emp    || nm.includes(_st.emp))
           && (!_st.status || st === _st.status)
           && (!_st.wave   || wv === _st.wave);
    r.classList.toggle('mvpx-flt-out', !vis);
    if (vis) shown++;
  });
  if (window.mvpxPagerReset) mvpxPagerReset(); /* pager owns #showCount = "Rows X–Y of Z" */

  renderChips();
  mvpxGroupSummary();
  updateStatCounts();
}

function updateStatCounts() {
  var rows = document.querySelectorAll('#daRows tr[data-id]');
  var totVis=0, conf=0, awt=0, nc=0;
  rows.forEach(function(r){
    if (r.classList.contains('mvpx-flt-out')) return;
    totVis++;
    var st = r.dataset.st;
    if (st==='confirmed')    conf++;
    else if (st==='awaiting') awt++;
    else if (st==='notcontacted') nc++;
  });
  document.getElementById('cnt-total').textContent      = totVis;
  document.getElementById('cnt-confirmed').textContent  = conf;
  document.getElementById('cnt-awaiting').textContent   = awt;
  document.getElementById('cnt-notcontacted').textContent = nc;
}

var statusLabels = {
  notcontacted:'Not contacted', awaiting:'Awaiting',
  confirmed:'Confirmed', available:'Available'
};

function renderChips() {
  var c = document.getElementById('activeChips');
  c.innerHTML = '';
  if (_st.emp) {
    var sel = document.getElementById('filterEmp');
    var lbl = sel.options[sel.selectedIndex] ? sel.options[sel.selectedIndex].text : _st.emp;
    c.innerHTML += chip('DA', lbl, 'emp');
  }
  if (_st.status) c.innerHTML += chip('Status', statusLabels[_st.status]||_st.status, 'status');
  if (_st.wave)   c.innerHTML += chip('Wave', _st.wave.toUpperCase(), 'wave');
}

function chip(key, val, field) {
  return '<span class="da-chip">' + key + ': <b>' + val + '</b>'
       + '<button class="x" onclick="clearFilter(\'' + field + '\')">&times;</button></span>';
}

function clearFilter(field) {
  if (field==='emp')    { document.getElementById('filterEmp').value=''; }
  if (field==='status') { document.getElementById('filterStatus').value=''; }
  if (field==='wave')   { document.getElementById('filterWave').value=''; }
  applyFilters();
}

/* ---- click-to-sort headers ---- */
function _cellText(tr, idx){
  var td = tr.children[idx];
  return td ? (td.textContent || '').replace(/\s+/g,' ').trim() : '';
}
function mvpxSort(th){
  var head = th.parentNode;
  var idx  = Array.prototype.indexOf.call(head.children, th);
  var asc  = th.getAttribute('data-dir') !== 'asc';
  head.querySelectorAll('th').forEach(function(o){
    if (o !== th){ o.removeAttribute('data-dir'); var a=o.querySelector('.ar'); if(a) a.textContent=''; }
  });
  th.setAttribute('data-dir', asc ? 'asc' : 'desc');
  var ar = th.querySelector('.ar'); if (ar) ar.textContent = asc ? '▲' : '▼';
  var tb   = document.getElementById('daRows');
  var rows = Array.prototype.slice.call(tb.querySelectorAll('tr[data-id]'));
  rows.sort(function(a, b){
    var x = _cellText(a, idx), y = _cellText(b, idx);
    var nx = parseFloat(x.replace(/[^0-9.\-]/g,'')), ny = parseFloat(y.replace(/[^0-9.\-]/g,''));
    var num = /\d/.test(x) && /\d/.test(y) && !isNaN(nx) && !isNaN(ny)
              && x.replace(/[0-9.\-\s:\/]/g,'') === '' && y.replace(/[0-9.\-\s:\/]/g,'') === '';
    var cmp = num ? (nx - ny) : x.toLowerCase().localeCompare(y.toLowerCase());
    if (cmp === 0) return 0;
    return asc ? cmp : -cmp;
  });
  rows.forEach(function(r){ tb.appendChild(r); });
  if (window.mvpxPagerReset) mvpxPagerReset();
  else if (window.mvpxPagerRender) mvpxPagerRender(true);
}

/* ---- date helpers (server expects MM/dd/yyyy) ---- */
function _pad(n){ return (n < 10 ? '0' : '') + n; }
function toMDY(iso){ if(!iso) return ''; var p = iso.split('-'); return p.length===3 ? (p[1]+'/'+p[2]+'/'+p[0]) : ''; }
function mdyToISO(mdy){ if(!mdy) return ''; var p = mdy.split('/'); return p.length===3 ? (p[2]+'-'+_pad(parseInt(p[0],10))+'-'+_pad(parseInt(p[1],10))) : ''; }
function goSearch(fromMDY, toMDY_){
  /* Submit via the app form so the login/session params are carried
     (a bare URL nav drops them and the servlet returns Access Denied). */
  var extra = '&srhFromDate=' + encodeURIComponent(fromMDY)
            + '&srhToDate='   + encodeURIComponent(toMDY_)
            + '&srhStatus=All&searchFilter=yes';
  submitPageDataForm('<%=SubmitType.SEARCH%>', _ctrl, '', '', extra);
}
/* Excel / PDF export of the current date range (this page doesn't use mvpxListInit,
   so mvpxPrint's MVPXL config is empty — build the print URL from our own inputs) */
function daPrint(pt){
  window.open('../servlet/MVPGServlet?submitType=<%=SubmitType.PRINT%>&controller=' + _ctrl
    + '&printType=' + pt + '&searchFilter=yes&requestType=search'
    + '&srhFromDate=' + encodeURIComponent(toMDY(document.getElementById('filterFrom').value))
    + '&srhToDate='   + encodeURIComponent(toMDY(document.getElementById('filterTo').value))
    + '&srhStatus=All' + getPageSubmitFormValues(true));
}
/* date range inputs -> reload server search with MM/dd/yyyy */
function dateSearch(){
  goSearch(toMDY(document.getElementById('filterFrom').value),
           toMDY(document.getElementById('filterTo').value));
}
/* ---- quick date buttons ---- */
function quickDate(el, which){
  var d = new Date();
  if (which === 'tomorrow') d.setDate(d.getDate() + 1);
  var mdy = _pad(d.getMonth()+1) + '/' + _pad(d.getDate()) + '/' + d.getFullYear();
  goSearch(mdy, mdy);
}
/* on load, show the current server date range in the yyyy-mm-dd inputs */
(function(){
  var f = document.getElementById('filterFrom'), t = document.getElementById('filterTo');
  if (f) f.value = mdyToISO((f.dataset.mdy||'').trim());
  if (t) t.value = mdyToISO((t.dataset.mdy||'').trim());
})();

/* ---- select all (covers every filter-matching row; pager is viewport-only) ---- */
function toggleSelectAll(cb) {
  document.querySelectorAll('.rowCheck').forEach(function(c){
    var tr = c.closest('tr');
    if (!tr || !tr.classList.contains('mvpx-flt-out')) c.checked = cb.checked;
  });
}

/* ---- per-row Send SMS ---- */
function sendSMSRow(btn, confID) {
  btn.disabled = true; btn.textContent = 'Sending…';
  ajaxPost({ requestType:'sendSMS', selRecordIDs: confID }, function(resp) {
    var ok = resp.indexOf('<status>true') >= 0 || resp.indexOf('success') >= 0;
    if (ok) {
      toast('SMS sent!', true);
      btn.closest('tr').dataset.st = 'awaiting';
      var td = btn.closest('td');
      td.innerHTML = '<span class="pill amber"><span class="d"></span>Awaiting</span>'
                   + '<div class="subpill"><button class="btn sm" onclick="confirmDA(this,\'' + confID + '\')">Confirm</button></div>';
    } else {
      toast('SMS failed — check Twilio config', false);
      btn.disabled = false; btn.textContent = 'Send SMS';
    }
  });
}

/* ---- per-row Confirm ---- */
function confirmDA(btn, confID) {
  btn.disabled = true; btn.textContent = 'Saving…';
  ajaxPost({ requestType:'updateStatus', recordID: confID, recordStatus:'Confirmed' }, function(resp) {
    var ok = resp.indexOf('true') >= 0;
    if (ok) {
      toast('Confirmed ✓', true);
      var tr = btn.closest('tr');
      tr.dataset.st = 'confirmed';
      var td = btn.closest('td');
      td.innerHTML = '<span class="pill green"><span class="d"></span>Confirmed</span>';
      updateStatCounts();
    } else {
      toast('Save failed', false);
      btn.disabled = false; btn.textContent = 'Confirm';
    }
  });
}

/* ---- inline status change (dropdown) ---- */
function changeStatus(sel, confID) {
  var val = sel.value;
  var by = (document.getElementById('loginUserDisplayName') || {}).value || '';
  sel.disabled = true;
  ajaxPost({ requestType:'updateStatus', recordID: confID, recordStatus: val, confirmedBy: by }, function(resp) {
    sel.disabled = false;
    if (resp.indexOf('true') >= 0) {
      toast('Status updated', true);
      var tr = sel.closest('tr');
      tr.dataset.statusRaw = val;
      var v = val.toLowerCase(), st = 'other';
      if (v.indexOf('not confirmed') >= 0)      st = 'notcontacted';
      else if (v.indexOf('confirmed') >= 0)     st = 'confirmed';
      else if (v.indexOf('available') >= 0)     st = 'available';
      else if (v.indexOf('review') >= 0)        st = 'review';
      tr.dataset.st = st;
      updateStatCounts();
    } else {
      toast('Save failed', false);
    }
  });
}

/* ---- inline comment save ---- */
function saveComment(input) {
  var newVal = input.value.trim();
  if (newVal === input.dataset.orig) return;
  var confID    = input.dataset.id;
  var rawStatus = input.closest('tr').dataset.statusRaw || '';
  ajaxPost({ requestType:'updateStatus', recordID: confID,
             recordStatus: rawStatus, comments: newVal }, function(resp) {
    if (resp.indexOf('true') >= 0) {
      input.dataset.orig = newVal;
      toast('Note saved', true);
    } else {
      toast('Save failed', false);
    }
  });
}

/* ---- bulk SMS ---- */
function sendBulkSMS(btn) {
  var checked = Array.from(document.querySelectorAll('.rowCheck:checked')).map(function(c){ return c.value; });
  if (checked.length === 0) {
    /* send to all visible not-contacted / available rows */
    checked = Array.from(document.querySelectorAll('#daRows tr[data-id]')).filter(function(r){
      return !r.classList.contains('mvpx-flt-out') && (r.dataset.st==='notcontacted'||r.dataset.st==='available');
    }).map(function(r){ return r.dataset.id; });
  }
  if (checked.length === 0) { toast('No eligible rows selected', false); return; }
  btn.disabled = true; btn.textContent = 'Sending…';
  ajaxPost({ requestType:'sendSMS', selRecordIDs: checked.join(',') }, function(resp) {
    btn.disabled = false; btn.innerHTML = '&#9993; Send confirmation SMS';
    var ok = resp.indexOf('success') >= 0 || resp.indexOf('true') >= 0;
    toast(ok ? 'SMS sent to ' + checked.length + ' driver(s)!' : 'Some messages failed — check Twilio config', ok);
    if (ok) setTimeout(function(){ window.location.reload(); }, 2000);
  });
}

/* ---- auto SMS toggle ---- */
function toggleAutoSMS(btn) {
  ajaxPost({ requestType:'toggleAutoSMS' }, function(resp) {
    var parser = new DOMParser();
    var doc = parser.parseFromString('<r>' + resp + '</r>', 'text/xml');
    var val = doc.querySelector('autoSMS') ? doc.querySelector('autoSMS').textContent : '';
    var isOn = val.toUpperCase() === 'Y';
    btn.classList.toggle('on', isOn);
    document.getElementById('autoSMSLabel').textContent = 'Auto SMS: ' + (isOn ? 'ON' : 'OFF');
    toast('Auto SMS ' + (isOn ? 'enabled' : 'disabled'), true);
  });
}

/* REV C: viewport lock + auto-fit pager (shared engine) */
mvpxFitStart();
mvpxGroupSummary(); /* initial "By status" breakdown */
</script>

<%
} else {
    /* ---- CREATE / UPDATE / BROWSE single-record view ---- */
    String[] daStatusArray = null;
%>
<script>
function validatePageData(submitType, isValid) {
  if (submitType == <%=SubmitType.CREATE_CONFIRM%>) {
    if (isValid) {
      var mf = [];
      mf.push([document.formmain["scheduleDate"], "Schedule Date"]);
      mf.push([document.formmain["station"],       "Station"]);
      mf.push([document.formmain["recordStatus"],  "Status"]);
      var n = parseInt(document.formmain["numOfRows"].value);
      for (var i = 0; i < n; i++) {
        if (i === 0) mf.push([document.formmain["employeeID"+i], "Employee"]);
      }
      isValid = validateMandatoryFieldsInForm(mf, isValid);
    }
  } else if (submitType == <%=SubmitType.DELETE%>) {
    isValid = deleteRecord();
  }
  return isValid;
}
</script>
<%@ include file="includeHeader.jsp"%>
<style>
/* Salesforce-style type preview — DA Confirmation form view */
body, h1, h2, h3, h4, .card-header, .col-form-label, .form-control, .btn,
input, select, textarea, button, .mvpx-body {
  font-family: 'Inter', 'DM Sans', 'Open Sans', 'Work Sans', 'Segoe UI', sans-serif;
}
.card-header.table-title-header {
  font-size: 18px;
  font-weight: 700;
  letter-spacing: -.015em;
}
.form-control, select.form-control, textarea.form-control {
  font-size: 13px;
  font-weight: 400;
}
</style>
<div class='row my-2'>
  <div class='col-12 mb-2'>
    <div class='card'>
      <div class='card-header table-title-header m-0 py-2'>
        <div class="row">
          <div class="col-2"></div>
          <div class="col-8"><%=_recordBean.getDisplayName()%></div>
          <div class="col-2 text-right my-auto">
            <%if(submitType == SubmitType.BROWSE){%>
            <button class="btn btn-primary btn-sm"
                    onClick="Javascript:submitPageDataForm('<%=SubmitType.CREATE%>','<%=_recordBean.getController()%>');">New</button>
            <%}%>
          </div>
        </div>
      </div>

      <%if(_errorBean != null && _errorBean.getType().length() > 0){%>
      <div class="row text-center">
        <section class='alert_section'>
          <div class='alert-box <%=_errorBean.getType()%>Color'><%=_errorBean.getMesg()%></div>
        </section>
      </div>
      <%}%>

      <input type="hidden" id="recordID" name="recordID" value="<%=_recordBean.getRecordID()%>">
      <div class='card-body m-1 p-1'>
        <%if(submitType == SubmitType.CREATE){%>
        <div class="row">
          <div class="col-12 col-md-5">
            <div class="row form-row form-group form-group-sm">
              <label class="col-12 col-md-3 col-form-label required text-left">Schedule Date</label>
              <div class="col-12 col-md-9 text-left">
                <div class="row">
                  <input type="hidden" id="scheduleTime" name="scheduleTime" value="<%=_recordBean.getScheduleTime()%>">
                  <div class="col-6"><input type="text" id="scheduleDate" name="scheduleDate" class="form-control form-control-sm datepicker" value="<%=_recordBean.getScheduleDate()%>" placeholder="Date"></div>
                  <div class="col-3"><input type="text" id="scheduleTimeTxt" name="scheduleTimeTxt" class="form-control form-control-sm" value="" placeholder="Time" onChange="fixTime('scheduleTime');"></div>
                  <div class="col-3"><select id="scheduleTimeSel" name="scheduleTimeSel" class="form-control form-control-sm" onChange="fixTime('scheduleTime');"><option value="AM">AM</option><option value="PM">PM</option></select></div>
                </div>
              </div>
            </div>
            <div class="row form-row form-group form-group-sm">
              <label class="col-12 col-md-3 col-form-label required text-left">Status</label>
              <div class="col-12 col-md-9 text-left">
                <select id="recordStatus" name="recordStatus" class="form-control form-control-sm">
                  <option value=""></option>
                  <%String[][] _arr = _mainUtil.getDataArray(_mainUtil.getDAStatus());
                    for(int k=0;k<_arr.length;k++){%>
                  <option value="<%=_arr[k][0]%>" <%if(_recordBean.getRecordStatus().equalsIgnoreCase(_arr[k][0])||_arr.length==1){%>selected<%}%>><%=_arr[k][1]%></option>
                  <%}%>
                </select>
              </div>
            </div>
          </div>
          <div class="col-12 col-md-2"></div>
          <div class="col-12 col-md-5">
            <div class="row">
              <label class="col-5 col-md-3 required col-form-label text-left">Station</label>
              <div class="col-7 col-md-9 text-left">
                <select id="station" name="station" class="form-control form-control-sm">
                  <option value=""></option>
                  <%_arr = _mainUtil.getDataArray(_mainUtil.getStation());
                    for(int k=0;k<_arr.length;k++){%>
                  <option value="<%=_arr[k][0]%>" <%if(_recordBean.getStation().equalsIgnoreCase(_arr[k][0])||_arr.length==1){%>selected<%}%>><%=_arr[k][1]%></option>
                  <%}%>
                </select>
              </div>
            </div>
          </div>
        </div>

        <div class="row">
          <div class="col-12 col-md-2"></div>
          <div class="col-12 col-md-8">
            <table width="100%" class="table table-bordered table-striped table-hover table-sm table-block table-vertical sortable mb-0">
              <input type="hidden" id="numOfRows" name="numOfRows" value="10">
              <input type="hidden" id="dynamicParams" name="dynamicParams" value="employeeID,comments">
              <thead class="thead-block">
                <tr class="tr-block">
                  <th class="th-block table-header-label text-center required" width="40%">Employee</th>
                  <th class="th-block table-header-label text-center" width="60%">Comments</th>
                </tr>
              </thead>
              <tbody class="tbody-block">
                <%for(int i=0;i<10;i++){
                  String empID = (i==0)?_recordBean.getEmployeeID():"";%>
                <tr class="tr-block">
                  <td class="td-block table-value" data-th="Employee">
                    <select id="employeeID<%=i%>" name="employeeID<%=i%>" class="form-control form-control-sm"></select>
                  </td>
                  <td class="td-block table-value" data-th="Comments">
                    <textarea id="comments<%=i%>" name="comments<%=i%>" class="form-control form-control-sm" rows="1"></textarea>
                  </td>
                </tr>
                <script>initSelect2Suggestor("employees","employeeID<%=i%>","<%=empID%>",false,"");</script>
                <%}%>
              </tbody>
            </table>
          </div>
          <div class="col-12 col-md-2"></div>
        </div>
        <%}%>
      </div>
    </div>

    <%if(submitType == SubmitType.CREATE || submitType == SubmitType.UPDATE){%>
    <div class="row mt-4">
      <div class="col-4 text-left">
        <button class="btn btn-secondary"
                onClick="Javascript:submitPageDataForm('<%=SubmitType.SEARCH%>','<%=_recordBean.getController()%>','');">Back</button>
      </div>
      <div class="col-4 text-center">
        <%if(submitType == SubmitType.CREATE){%>
        <button class="btn btn-success"
                onClick="Javascript:submitPageDataForm('<%=SubmitType.CREATE_CONFIRM%>','<%=_recordBean.getController()%>','<%=_recordBean.getRecordID()%>');">Save</button>
        &nbsp;
        <button class="btn btn-success"
                onClick="Javascript:submitPageDataForm('<%=SubmitType.CREATE_CONFIRM%>','<%=_recordBean.getController()%>','<%=_recordBean.getRecordID()%>','2');">Save &amp; SMS</button>
        <%}else{%>
        <button class="btn btn-success"
                onClick="Javascript:submitPageDataForm('<%=SubmitType.UPDATE_CONFIRM%>','<%=_recordBean.getController()%>','<%=_recordBean.getRecordID()%>');">Save</button>
        <%}%>
      </div>
      <div class="col-4 text-right"></div>
    </div>
    <%}else if(submitType == SubmitType.BROWSE){%>
    <div class="row mt-4">
      <div class="col-4 text-left">
        <button class="btn btn-secondary"
                onClick="Javascript:submitPageDataForm('<%=SubmitType.SEARCH%>','<%=_recordBean.getController()%>','');">Back</button>
      </div>
      <div class="col-4 text-center">
        <%if("0".equalsIgnoreCase(_recordBean.getStatus())){%>
        <button class="btn btn-primary"
                onClick="Javascript:submitPageDataForm('<%=SubmitType.UPDATE%>','<%=_recordBean.getController()%>','<%=_recordBean.getRecordID()%>');">Edit</button>
        <%}%>
      </div>
      <div class="col-4 text-right">
        <%if("0".equalsIgnoreCase(_recordBean.getStatus())){%>
        <button class="btn btn-danger"
                onClick="Javascript:submitPageDataForm('<%=SubmitType.DELETE%>','<%=_recordBean.getController()%>','<%=_recordBean.getRecordID()%>');">Delete</button>
        <%}%>
      </div>
    </div>
    <%}%>
  </div>
</div>
<%@ include file="includeFooter.jsp"%>
<%}%>
