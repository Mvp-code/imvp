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
<jsp:useBean id="_recordBean" class="com.beans.AdminVehicle" scope="request" />
<%
String _array[][] = null ;

/* ═══════════════ LIST VIEW (redesigned — MVPx list standard) ═══════════════ */
if (submitType == SubmitType.SEARCH) {
    List dataList = _searchBean.getDataList() == null ? new ArrayList() : _searchBean.getDataList();
    int cntTotal = dataList.size(), cntOper = 0;
    int cntActive = 0, cntInactive = 0, cntRepair = 0;
    Map<String, Integer> tierCnt = new LinkedHashMap<String, Integer>();
    Map<String, Integer> provCnt = new LinkedHashMap<String, Integer>();
    Map<String, Integer> opCnt   = new LinkedHashMap<String, Integer>();
    Map<String, Integer> tierOpCnt = new LinkedHashMap<String, Integer>();
    Map<String, Integer> provOpCnt = new LinkedHashMap<String, Integer>();
    Map<String, Integer> tierGrCnt = new LinkedHashMap<String, Integer>();
    Map<String, Integer> provGrCnt = new LinkedHashMap<String, Integer>();
    Map<String, Integer> tierRpCnt = new LinkedHashMap<String, Integer>();
    Map<String, Integer> provRpCnt = new LinkedHashMap<String, Integer>();
    List<String> tierNames = new ArrayList<String>();
    List<String> provNames = new ArrayList<String>();
    List<String> opNames   = new ArrayList<String>();
    /* [0]=id [1]=num [2]=vin [3]=odo [4]=odoDate [5]=oilMi [6]=oilDate [7]=tier
       [8]=rentStart [9]=rentEnd [10]=daysRented [11]=provider [12]=opStatus
       [13]=sortRentS [14]=sortRentE [15]=status(hidden) [16]=repair */
    List<String[]> rows = new ArrayList<String[]>();
    for (int i = 0; i < dataList.size(); i++) {
        List r = (List) dataList.get(i);
        String[] c = new String[17];
        for (int j = 0; j < 17 && j < r.size(); j++)
            c[j] = r.get(j) == null ? "" : r.get(j).toString().trim();
        for (int j = 0; j < 17; j++) if (c[j] == null) c[j] = "";
        String op = c[12];
        String pill = "slate";
        if (op.toLowerCase().startsWith("oper")) { pill = "green"; cntOper++; }
        else if (op.toLowerCase().contains("repair") || op.toLowerCase().contains("grounded")) pill = "red";
        if (c[7].length() > 0 && !tierNames.contains(c[7])) tierNames.add(c[7]);
        String provKey = "";
        if (c[11].length() > 0) {
            for (String k : provCnt.keySet()) if (k.equalsIgnoreCase(c[11])) { provKey = k; break; }
            if (provKey.length() == 0) provKey = c[11];
            c[11] = provKey;
        }
        if (c[11].length() > 0 && !provNames.contains(c[11])) provNames.add(c[11]);
        if (op.length() > 0 && !opNames.contains(op)) opNames.add(op);
        if ("Active".equalsIgnoreCase(c[15])) cntActive++; else if (c[15].length() > 0) cntInactive++;
        c[16] = "1".equals(c[16]) ? "1" : "0";
        if ("1".equals(c[16])) cntRepair++;
        if (c[7].length() > 0) tierCnt.put(c[7], tierCnt.get(c[7]) == null ? 1 : tierCnt.get(c[7]) + 1);
        if (c[11].length() > 0) provCnt.put(c[11], provCnt.get(c[11]) == null ? 1 : provCnt.get(c[11]) + 1);
        if (op.length() > 0)   opCnt.put(op,     opCnt.get(op)     == null ? 1 : opCnt.get(op) + 1);
        boolean isOper = op.toLowerCase().startsWith("oper");
        boolean isGrnd = op.toLowerCase().contains("grounded");
        if (isOper && c[7].length() > 0) tierOpCnt.put(c[7], tierOpCnt.get(c[7]) == null ? 1 : tierOpCnt.get(c[7]) + 1);
        if (isOper && c[11].length() > 0) provOpCnt.put(c[11], provOpCnt.get(c[11]) == null ? 1 : provOpCnt.get(c[11]) + 1);
        if (isGrnd && c[7].length() > 0) tierGrCnt.put(c[7], tierGrCnt.get(c[7]) == null ? 1 : tierGrCnt.get(c[7]) + 1);
        if (isGrnd && c[11].length() > 0) provGrCnt.put(c[11], provGrCnt.get(c[11]) == null ? 1 : provGrCnt.get(c[11]) + 1);
        boolean isRep = "1".equals(c[16]);
        if (isRep && c[7].length() > 0) tierRpCnt.put(c[7], tierRpCnt.get(c[7]) == null ? 1 : tierRpCnt.get(c[7]) + 1);
        if (isRep && c[11].length() > 0) provRpCnt.put(c[11], provRpCnt.get(c[11]) == null ? 1 : provRpCnt.get(c[11]) + 1);
        rows.add(c);
    }
    Collections.sort(tierNames);
    Collections.sort(provNames); Collections.sort(opNames);
%>
<%@ include file="includeHeader.jsp"%>
<link rel="stylesheet" href="../jsp/assets/css/mvpx-list.css?v=20260911a">
<script src="../jsp/assets/js/mvpx-list.js?v=20260722d"></script>
<style>
/* out-for-repair switch: red = out (status color, allowed) */
.vh-tgl{width:40px;height:22px;border-radius:11px;border:1px solid var(--da-border,#D8D6CE);background:#E5E3DB;position:relative;cursor:pointer;padding:0;vertical-align:middle;transition:background .15s,border-color .15s}
.vh-tgl .kn{position:absolute;top:2px;left:2px;width:16px;height:16px;border-radius:50%;background:#fff;box-shadow:0 1px 2px rgba(0,0,0,.25);transition:left .15s}
.vh-tgl.on{background:var(--status-action-fg);border-color:var(--status-action-fg)}
.vh-tgl.on .kn{left:20px}
.vh-tgl:disabled{opacity:.5;cursor:wait}
.vh-chip{cursor:pointer;user-select:none}
.vh-chip:hover{border-color:var(--da-ink,#141519)}
/* summary cards: Operational / Grounded / Out for Repair */
.vh-cards{display:grid;grid-template-columns:1fr 1fr 1fr;gap:11px;margin:2px 0 10px}
.vh-card{background:var(--da-card,#fff);border:1px solid var(--da-border,#D8D6CE);border-radius:10px;padding:10px 14px 9px;min-width:0}
.vh-card h4{margin:0 0 6px;font-size:13.5px;letter-spacing:.04em;text-transform:uppercase;display:flex;align-items:center;gap:6px}
.vh-card h4 .n{margin-left:auto;font-family:var(--font-mono,monospace);font-size:18px}
.vh-card .dot{width:8px;height:8px;border-radius:50%;display:inline-block;margin-right:5px;vertical-align:baseline}
.vh-cols{display:grid;grid-template-columns:repeat(auto-fit,minmax(150px,1fr));gap:0 14px;align-items:start}
.vh-sub{font-size:11px;letter-spacing:.09em;text-transform:uppercase;color:var(--da-faint,#A6A9B1);margin:2px 0 3px}
.vh-line{display:inline-flex;align-items:center;gap:3px;font-size:13px;line-height:1.55;cursor:pointer;border-radius:5px;padding:1px 4px;margin:0 1px 1px 0;max-width:100%}
.vh-line:hover{background:var(--da-hover,#F0EEE7)}
.vh-line b{font-family:var(--font-mono,monospace);font-weight:600;white-space:nowrap}
.vh-line span{overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
@media (max-width:900px){.vh-cards{grid-template-columns:1fr}}
/* larger table text + visible bottom horizontal scrollbar (overrides revc hide) */
.da-wrap .tablewrap{
  overflow:hidden !important;
}
.da-wrap .vh-tbl-x{
  overflow-x:auto !important;overflow-y:visible !important;
  scrollbar-width:thin !important;scrollbar-color:#94A3B8 #E2E8F0;
  -ms-overflow-style:auto !important;
}
.da-wrap .vh-tbl-x::-webkit-scrollbar{display:block !important;width:12px;height:12px}
.da-wrap .vh-tbl-x::-webkit-scrollbar-track{background:#E2E8F0;border-radius:6px}
.da-wrap .vh-tbl-x::-webkit-scrollbar-thumb{background:#94A3B8;border-radius:6px}
.da-wrap .vh-tbl-x::-webkit-scrollbar-thumb:hover{background:#64748B}
.da-wrap .vh-tbl-x > table{width:max-content;min-width:100%;border-collapse:collapse}
.da-wrap .tablewrap thead th{font-size:14px !important;padding:12px 14px !important;white-space:nowrap}
.da-wrap .tablewrap tbody td{font-size:15px !important;padding:11px 14px !important;white-space:nowrap}
.da-wrap .tablewrap .meta{font-size:14px !important;color:#374151}
.da-wrap .tablewrap .nm{font-size:15px !important}
.da-wrap .tablewrap .pill{font-size:13px !important;padding:4px 10px}
.da-wrap .tablewrap .vh-act .btn2{font-size:12.5px;padding:5px 10px}
.da-wrap .da-flt{font-size:14px;padding:9px 11px}
/* same-page edit + history drawers (over the sidebar, like Returns Board) */
.vh-hx{padding:2px 7px;font-size:10.5px;margin-left:5px;vertical-align:middle}
.vh-scrim{display:none;position:fixed;inset:0;background:rgba(20,21,25,.35);z-index:390}
.vh-scrim.on{display:block}
.vh-drawer{position:fixed;top:0;right:0;width:min(440px,100vw);height:100vh;box-sizing:border-box;background:var(--da-card,#fff);border-left:1px solid var(--da-border,#D8D6CE);box-shadow:-8px 0 30px rgba(0,0,0,.14);z-index:400;padding:14px 18px;overflow:hidden;transform:translateX(calc(100% + 40px));visibility:hidden;transition:transform .22s ease,visibility .22s;display:flex;flex-direction:column}
.vh-drawer.on{transform:translateX(0);visibility:visible}
.vh-drawer .vh-scrollarea{flex:1;min-height:0;overflow-y:auto;scrollbar-width:none}
.vh-drawer .vh-scrollarea::-webkit-scrollbar{display:none}
.vh-drawer h3{margin:0 0 12px;font-size:16px;display:flex;align-items:center;gap:8px}
.vh-drawer h3 span{color:var(--da-faint,#A6A9B1);font-weight:500;font-size:13px}
.vh-x{margin-left:auto;border:0;background:transparent;font-size:15px;cursor:pointer;color:var(--da-faint,#A6A9B1)}
.vh-fgrid{display:grid;grid-template-columns:1fr 1fr;gap:9px 12px}
.vh-drawer label{display:flex;flex-direction:column;gap:3px;font-size:10.5px;letter-spacing:.06em;text-transform:uppercase;color:var(--da-faint,#6B6E76);margin-top:4px}
.vh-act{display:flex;gap:4px;align-items:center;white-space:nowrap}
.vh-act .btn2{padding:2px 8px;font-size:10.5px}
.vh-wide{width:min(720px,100vw)}
.vh-mid{width:min(560px,100vw)}
.vh-cur{font-size:11px;font-family:var(--font-mono,monospace);color:var(--da-faint,#6B6E76);text-transform:none;letter-spacing:0}
/* maintenance records in the history drawer */
.vh-rec{border:1px solid var(--da-border,#E8E6DF);border-radius:9px;padding:8px 10px;margin-bottom:7px}
.vh-rec .hd{display:flex;align-items:center;gap:7px;font-size:12.5px}
.vh-rec .hd .ic{font-size:15px}
.vh-rec .hd b{flex:1;min-width:0;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.vh-rec .meta{font-size:11px;color:var(--da-faint,#6B6E76);margin-top:3px;line-height:1.5}
.vh-rec .meta b{color:inherit;font-weight:600}
.vh-openpill{font-size:9.5px;letter-spacing:.07em;padding:2px 7px;border-radius:9px;text-transform:uppercase;white-space:nowrap}
.vh-openpill.open{background:var(--status-warn-bg);color:var(--status-warn-fg)}
.vh-openpill.done{background:var(--status-ok-bg);color:var(--status-ok-fg)}
.vh-step{font-size:10.5px;letter-spacing:.09em;text-transform:uppercase;color:var(--da-faint,#6B6E76);margin:10px 0 6px;border-bottom:1px solid var(--da-border,#E8E6DF);padding-bottom:4px}
.vh-mtypes{display:grid;grid-template-columns:repeat(auto-fill,minmax(105px,1fr));gap:7px}
.vh-mtype{border:1px solid var(--da-border,#D8D6CE);border-radius:9px;padding:9px 6px;text-align:center;cursor:pointer;background:var(--da-bg,#FAF9F5)}
.vh-mtype:hover{border-color:var(--da-ink,#141519)}
.vh-mtype.on{border:2px solid var(--da-ink,#141519);padding:8px 5px;background:#fff}
.vh-mtype .ic{font-size:20px;display:block;margin-bottom:3px}
.vh-mtype b{display:block;font-size:11px;line-height:1.25}
.vh-mtype small{color:var(--da-faint,#A6A9B1);font-size:9.5px;text-transform:uppercase;letter-spacing:.06em}
.vh-fgrid3{grid-template-columns:1fr 1fr 1fr}
.vh-drawer input,.vh-drawer select,.vh-drawer textarea{border:1px solid var(--da-border,#D8D6CE);border-radius:7px;padding:7px 9px;font-size:13.5px;font-family:inherit;background:var(--da-bg,#FAF9F5);color:inherit;width:100%;min-width:0;box-sizing:border-box}
.vh-fgrid label,.vh-fgrid3 label{min-width:0}
.vh-req{display:none}
.vh-drawer label:has(.vh-req), .vh-lbl:has(.vh-req){color:var(--status-action-fg);font-weight:700}
label .vh-req{display:inline;margin-left:1px}
.vh-lbl{display:flex;gap:2px}
.vh-drawer input:focus,.vh-drawer select:focus,.vh-drawer textarea:focus{outline:2px solid var(--da-ink,#141519);outline-offset:-1px}
.vh-drbtns{display:flex;gap:8px;align-items:center;margin-top:16px}
.vh-full{margin-left:auto;font-size:12px;color:var(--da-faint,#6B6E76)}
.vh-hxbody .it{border-bottom:1px solid var(--da-border,#E8E6DF);padding:8px 2px}
.vh-hxbody .it .top{display:flex;justify-content:space-between;font-size:11px;color:var(--da-faint,#A6A9B1);font-family:var(--font-mono,monospace)}
.vh-hxbody .it .msg{font-size:13px;margin-top:2px}
</style>

<div class="da-wrap">

  <div class="da-headrow">
    <div>
      <h2>Vehicles</h2>
    </div>
    <div style="display:flex;gap:7px;align-items:center;flex-wrap:wrap">
      <span class="statchip vh-chip" onclick="vhChip('filterRep','1')"><span class="dot" style="background:var(--da-red)"></span><b><%=cntRepair%></b> out for repair</span>
      <button class="btn2 sm" id="vhSumBtn" onclick="vhSummary()">Hide summary</button>
      <button class="btn2" onclick="mvpxPrint('xls')" title="Export to Excel"><i class="fas fa-file-excel"></i> Excel</button>
      <button class="btn2" onclick="mvpxPrint('')" title="Download PDF"><i class="fas fa-file-pdf"></i> PDF</button>
      <button class="btn2 primary" onclick="submitPageDataForm('<%=SubmitType.CREATE%>','<%=_searchBean.getController()%>');">&#xFF0B; New</button>
    </div>
  </div>

  <%int cntGrounded = 0;
    for(Map.Entry<String,Integer> e : opCnt.entrySet())
        if (e.getKey().toLowerCase().contains("grounded")) cntGrounded += e.getValue();
    String defOpVal = "";
    for (String v : opNames) {
      if (v.toLowerCase().startsWith("oper")) { defOpVal = v.toLowerCase(); break; }
    }
    if (defOpVal.length() == 0) defOpVal = "operational";
  %>
  <div class="vh-cards">
    <div class="vh-card">
      <h4 onclick="vhChip('filterOp','<%=defOpVal%>')" style="cursor:pointer"><span class="dot" style="background:var(--da-green)"></span> Operational <span class="n"><%=cntOper%></span></h4>
      <div class="vh-cols">
        <div>
          <div class="vh-sub">By Service Type</div>
          <%for(Map.Entry<String,Integer> e : tierOpCnt.entrySet()){%>
          <div class="vh-line" onclick="vhChip2('<%=defOpVal%>','filterTier','<%=e.getKey().toLowerCase()%>')"><span><%=e.getKey().replace('_',' ')%></span><b>(<%=e.getValue()%>)</b></div>
          <%}%>
        </div>
        <div>
          <div class="vh-sub">By Provider</div>
          <%for(Map.Entry<String,Integer> e : provOpCnt.entrySet()){%>
          <div class="vh-line" onclick="vhChip2('<%=defOpVal%>','filterProv','<%=e.getKey().toLowerCase()%>')"><span><%=e.getKey()%></span><b>(<%=e.getValue()%>)</b></div>
          <%}%>
        </div>
      </div>
    </div>

    <div class="vh-card">
      <h4 onclick="vhChip('filterOp','grounded')" style="cursor:pointer"><span class="dot" style="background:var(--da-red)"></span> Grounded <span class="n"><%=cntGrounded%></span></h4>
      <div class="vh-cols">
        <div>
          <div class="vh-sub">By Service Type</div>
          <%for(Map.Entry<String,Integer> e : tierGrCnt.entrySet()){%>
          <div class="vh-line" onclick="vhChip2('grounded','filterTier','<%=e.getKey().toLowerCase()%>')"><span><%=e.getKey().replace('_',' ')%></span><b>(<%=e.getValue()%>)</b></div>
          <%}%>
        </div>
        <div>
          <div class="vh-sub">By Provider</div>
          <%for(Map.Entry<String,Integer> e : provGrCnt.entrySet()){%>
          <div class="vh-line" onclick="vhChip2('grounded','filterProv','<%=e.getKey().toLowerCase()%>')"><span><%=e.getKey()%></span><b>(<%=e.getValue()%>)</b></div>
          <%}%>
        </div>
      </div>
    </div>

    <div class="vh-card">
      <h4 onclick="vhChip('filterRep','1')" style="cursor:pointer"><span class="dot" style="background:var(--da-red)"></span> Out for Repair <span class="n"><%=cntRepair%></span></h4>
      <%if(cntRepair == 0){%>
      <div class="vh-sub">No vehicles flagged</div>
      <%} else {%>
      <div class="vh-cols">
        <div>
          <div class="vh-sub">By Service Type</div>
          <%for(Map.Entry<String,Integer> e : tierRpCnt.entrySet()){%>
          <div class="vh-line" onclick="vhChip2r('filterTier','<%=e.getKey().toLowerCase()%>')"><span><%=e.getKey().replace('_',' ')%></span><b>(<%=e.getValue()%>)</b></div>
          <%}%>
        </div>
        <div>
          <div class="vh-sub">By Provider</div>
          <%for(Map.Entry<String,Integer> e : provRpCnt.entrySet()){%>
          <div class="vh-line" onclick="vhChip2r('filterProv','<%=e.getKey().toLowerCase()%>')"><span><%=e.getKey()%></span><b>(<%=e.getValue()%>)</b></div>
          <%}%>
        </div>
      </div>
      <%}%>
    </div>
  </div>

  <div class="da-toolbar">
    <div class="daterange-fld" title="Rental start range">
      <span style="color:var(--da-faint)">&#128197;</span>
      <input type="date" id="filterFrom" onchange="mvpxDateSearch()">
      <span class="dash">&ndash;</span>
      <input type="date" id="filterTo" onchange="mvpxDateSearch()">
    </div>
    <input class="da-flt" id="filterNum" oninput="mvpxApplyFilters()" placeholder="Vehicle #&hellip;" style="max-width:140px">
    <select class="da-flt" id="filterTier" onchange="mvpxApplyFilters()">
      <option value="">All service tiers</option>
      <%for(String v : tierNames){%><option value="<%=v.toLowerCase()%>"><%=v%></option><%}%>
    </select>
    <select class="da-flt" id="filterProv" onchange="mvpxApplyFilters()">
      <option value="">All providers</option>
      <%for(String v : provNames){%><option value="<%=v.toLowerCase()%>"><%=v%></option><%}%>
    </select>
    <select class="da-flt" id="filterOp" onchange="mvpxApplyFilters()">
      <option value="">All op statuses</option>
      <%
        boolean hasDefOp = false;
        for (String v : opNames) {
          boolean sel = v.toLowerCase().equals(defOpVal);
          if (sel) hasDefOp = true;
      %>
      <option value="<%=v.toLowerCase()%>"<%=sel?" selected":""%>><%=v%></option>
      <%}%>
      <%if (!hasDefOp) {%><option value="<%=defOpVal%>" selected>Operational</option><%}%>
    </select>
    <select class="da-flt" id="filterSt" onchange="mvpxApplyFilters()">
      <option value="">All status</option>
      <option value="active" selected>Active</option>
      <option value="inactive">Inactive</option>
    </select>
    <select class="da-flt" id="filterRep" onchange="mvpxApplyFilters()">
      <option value="" selected>Repair: all</option>
      <option value="1">Out for repair</option>
      <option value="0">In service</option>
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
          <th>Vehicle Number</th>
          <th>VIN Number</th>
          <th>Odometer</th>
          <th>Last Odometer Reported Date</th>
          <th>Last Oil Change Mileage</th>
          <th>Last Oil Change Date</th>
          <th>Service Tier</th>
          <th>Rental Start</th>
          <th>Rental End</th>
          <th>Number of days Rented</th>
          <th>Provider</th>
          <th>Op Status</th>
          <th>Out for Repair</th>
          <th>Actions</th>
        </tr>
      </thead>
      <tbody id="ciRows">
        <%if(rows.isEmpty()){%>
        <tr><td colspan="14" class="da-empty">No vehicles found.</td></tr>
        <%}%>
        <%for(String[] r : rows){
            String opPill = "slate";
            if (r[12].toLowerCase().startsWith("oper")) opPill = "green";
            else if (r[12].toLowerCase().contains("repair") || r[12].toLowerCase().contains("grounded")) opPill = "red";
        %>
        <tr data-id="<%=r[0]%>"
            data-num="<%=r[1].toLowerCase()%>"
            data-tier="<%=r[7].toLowerCase()%>"
            data-prov="<%=r[11].toLowerCase()%>"
            data-op="<%=r[12].toLowerCase()%>"
            data-st="<%=r[15].toLowerCase()%>"
            data-rep="<%=r[16]%>">
          <td class="nm"><a href="javascript:void(0)" style="color:inherit" onclick="vhEdit('<%=r[0]%>')" title="Edit on this page"><%=r[1]%></a></td>
          <td class="meta"><%=r[2].length()>0?r[2]:"&mdash;"%></td>
          <td class="meta"><%=r[3].length()>0?r[3]:"&mdash;"%></td>
          <td class="meta"><%=r[4].length()>0?r[4]:"&mdash;"%></td>
          <td class="meta"><%=r[5].length()>0?r[5]:"&mdash;"%></td>
          <td class="meta"><%=r[6].length()>0?r[6]:"&mdash;"%></td>
          <td><%=r[7].length()>0?r[7]:"&mdash;"%></td>
          <td class="meta"><%=r[8].length()>0?r[8]:"&mdash;"%></td>
          <td class="meta"><%=r[9].length()>0?r[9]:"&mdash;"%></td>
          <td class="meta"><%=r[10].length()>0?r[10]:"&mdash;"%></td>
          <td class="meta"><%=r[11].length()>0?r[11]:"&mdash;"%></td>
          <td><span class="pill <%=opPill%>"><span class="d"></span><%=r[12]%></span></td>
          <td><button type="button" class="vh-tgl<%="1".equals(r[16])?" on":""%>" onclick="vhRepair('<%=r[0]%>', this)" title="Toggle out-for-repair"><span class="kn"></span></button></td>
          <td><div class="vh-act">
            <button type="button" class="btn2 sm" onclick="vhEdit('<%=r[0]%>')">Edit</button>
            <button type="button" class="btn2 sm" onclick="vhHist('<%=r[0]%>','<%=r[1]%>')">History</button>
            <button type="button" class="btn2 sm" onclick="vhMaintOpen('<%=r[0]%>','<%=r[1]%>')">&#xFF0B; Maint</button>
          </div></td>
        </tr>
        <%}%>
      </tbody>
    </table>
    </div>
    <div class="tablefoot">
      <span id="showCount">Showing <%=rows.size()%> of <%=cntTotal%></span>
      <button class="btn2 sm" onclick="submitPageDataForm('<%=SubmitType.SEARCH%>','<%=_searchBean.getController()%>')">&#8635; Refresh</button>
    </div>
  </div>
</div>

<div class="da-toast" id="daToast"></div>

<!-- edit drawer: row edits stay on this page -->
<div class="vh-scrim" id="vhScrim" onclick="vhClose()"></div>
<div class="vh-drawer" id="vhDrawer">
  <h3>Edit Vehicle <span id="vhDrName"></span><button class="vh-x" onclick="vhClose()">&#10005;</button></h3>
  <input type="hidden" id="vhId">
  <div class="vh-scrollarea">
  <div class="vh-fgrid">
    <label><span class="vh-lbl">Vehicle Number<span class="vh-req">*</span></span><input id="vhNum"></label>
    <label>VIN<input id="vhVin" readonly style="opacity:.7;font-family:var(--font-mono,monospace);font-size:11.5px;letter-spacing:.02em"></label>
    <label><span class="vh-lbl">Vehicle Type<span class="vh-req">*</span></span><select id="vhType">
      <option value=""></option><option value="Rental">Rental</option><option value="Amazon-Owned">Amazon-Owned</option>
    </select></label>
    <label><span class="vh-lbl">License Plate<span class="vh-req">*</span></span><input id="vhPlate"></label>
    <label><span class="vh-lbl">Registered State<span class="vh-req">*</span></span><input id="vhState"></label>
    <label><span class="vh-lbl">Registration Expiry<span class="vh-req">*</span></span><input type="date" id="vhRegExp"></label>
    <label><span class="vh-lbl">Service Tier<span class="vh-req">*</span></span><select id="vhTier">
      <option value=""></option>
      <%_array = _mainUtil.getDataArray(_mainUtil.getServiceTier());for(int k=0; k<_array.length; k++) {%><option value="<%=_array[k][0]%>"><%=_array[k][1]%></option><%}%>
    </select></label>
    <label><span class="vh-lbl">Operational Status<span class="vh-req">*</span></span><select id="vhOp" onchange="vhOpChg()">
      <%_array = _mainUtil.getDataArray(_mainUtil.getOpertionalStatus());for(int k=0; k<_array.length; k++) {%><option value="<%=_array[k][0]%>"><%=_array[k][1]%></option><%}%>
    </select></label>
    <label>Rental Start<input type="date" id="vhRentS"></label>
    <label>Rental End<input type="date" id="vhRentE"></label>
    <label>Odometer<input type="number" id="vhOdometer" min="0" step="1" placeholder="Miles"></label>
    <label>Last Odometer Reported Date<input type="date" id="vhOdoDate"></label>
    <label>Last Oil Change Mileage<input type="number" id="vhOilMileage" min="0" step="1" placeholder="Miles"></label>
    <label>Last Oil Change Date<input type="date" id="vhOilDate"></label>
  </div>
  <label id="vhReasonWrap" style="display:none"><span class="vh-lbl">Reason (required when grounding)<span class="vh-req">*</span></span><textarea id="vhReason" rows="2"></textarea></label>
  </div>
  <div class="vh-drbtns">
    <button class="btn2" onclick="vhClose()">Cancel</button>
    <button class="btn2 primary" id="vhSaveBtn" onclick="vhSave()">Save</button>
    <a href="javascript:void(0)" class="vh-full" onclick="submitPageDataForm('<%=SubmitType.BROWSE%>','<%=_searchBean.getController()%>', document.getElementById('vhId').value)">Full page &#8599;</a>
  </div>
</div>

<!-- history drawer: grounded reasons + repair flips from VEHICLETRANS -->
<div class="vh-drawer vh-mid" id="vhHxDrawer">
  <h3>Maintenance History <span id="vhHxName"></span><button class="vh-x" onclick="vhClose()">&#10005;</button></h3>
  <div id="vhHxBody" class="vh-hxbody vh-scrollarea"></div>
</div>

<!-- maintenance drawer: type cards + structured details (vehicle_maintenance) -->
<div class="vh-drawer vh-wide" id="vhMtDrawer">
  <h3><span id="vhMtTitle">Maintenance</span> <span id="vhMtName"></span>
    <span class="vh-cur" id="vhMtCurSt"></span>
    <button class="vh-x" onclick="vhClose()">&#10005;</button></h3>
  <input type="hidden" id="vhMtId">
  <input type="hidden" id="vhMtLogId">
  <div class="vh-scrollarea">
    <div class="vh-step">Step 1 &middot; Select maintenance type</div>
    <div class="vh-mtypes" id="vhMtTypes">
      <%List _mtList = _searchBean.getTransMap() == null ? new ArrayList()
            : (List) _searchBean.getTransMap().get("maintTypes");
        if (_mtList == null) _mtList = new ArrayList();
        for (int mi = 0; mi < _mtList.size(); mi++) {
            List mt = (List) _mtList.get(mi);
            String mtId = mt.get(0) == null ? "" : mt.get(0).toString().trim();
            String mtNm = mt.get(1) == null ? "" : mt.get(1).toString().trim();
            String mtCd = mt.get(2) == null ? "" : mt.get(2).toString().trim();
            String mtCg = mt.get(3) == null ? "" : mt.get(3).toString().trim();
            String mtIc = mt.get(4) == null ? "" : mt.get(4).toString().trim();
            String _mtKey = (mtNm + " " + mtCg).toLowerCase();
            String mtFa = "fa-wrench";
            if      (_mtKey.contains("oil"))        mtFa = "fa-tint";
            else if (_mtKey.contains("tire") || _mtKey.contains("flat")) mtFa = "fa-life-ring";
            else if (_mtKey.contains("tow"))        mtFa = "fa-truck";
            else if (_mtKey.contains("jump") || _mtKey.contains("battery") || _mtKey.contains("boost")) mtFa = "fa-bolt";
            else if (_mtKey.contains("lock"))       mtFa = "fa-key";
            else if (_mtKey.contains("roadside"))   mtFa = "fa-phone";
            else if (_mtKey.contains("glass") || _mtKey.contains("windshield")) mtFa = "fa-car";
            else if (_mtKey.contains("diagnos") || _mtKey.contains("engine")) mtFa = "fa-microchip";
            else if (_mtKey.contains("a/c") || _mtKey.contains("hvac")) mtFa = "fa-snowflake";
            else if (_mtKey.contains("electric")) mtFa = "fa-plug";
            else if (_mtKey.contains("recall"))    mtFa = "fa-exclamation-triangle";
            else if (_mtKey.contains("warranty"))  mtFa = "fa-shield-alt";
            else if (_mtKey.contains("fluid"))     mtFa = "fa-flask";
            else if (_mtKey.contains("wiper") || _mtKey.contains("bulb")) mtFa = "fa-lightbulb";
            else if (_mtKey.contains("align"))     mtFa = "fa-crosshairs";
            else if (_mtKey.contains("detail") || _mtKey.contains("clean")) mtFa = "fa-magic";
            else if (_mtKey.contains("scheduled") || _mtKey.contains("preventive")) mtFa = "fa-calendar-check";
            else if (_mtKey.contains("inspect"))   mtFa = "fa-clipboard-check";
            else if (_mtKey.contains("brake"))     mtFa = "fa-compact-disc";
            else if (_mtKey.contains("body"))      mtFa = "fa-car";%>
      <div class="vh-mtype" data-id="<%=mtId%>" data-t="<%=mtNm%>" data-code="<%=mtCd%>" data-c="<%=mtCg%>" onclick="vhMtPick(this)"><span class="ic"><i class="fas <%=mtFa%>" aria-hidden="true"></i></span><b><%=mtNm%></b><small><%=mtCg%></small></div>
      <%}%>
    </div>

    <div class="vh-step"><i class="fas fa-wrench" aria-hidden="true"></i> Maintenance details</div>
    <div class="vh-fgrid">
      <label>Shop<select id="vhMtShopSel" onchange="vhMtShopChg()">
        <option value="">- Select shop -</option>
        <option value="__new">&#xFF0B; Add new shop&hellip;</option>
      </select></label>
      <label id="vhMtShopNewWrap" style="display:none">New shop name<input id="vhMtShopNew" placeholder="Shop name"></label>
    </div>
    <div class="vh-fgrid vh-fgrid3">
      <label><span class="vh-lbl">Service date<span class="vh-req">*</span></span><input type="date" id="vhMtSvcDate"></label>
      <label>Next service<input type="date" id="vhMtNextSvc"></label>
      <label>Follow-up<input type="date" id="vhMtFollowUp"></label>
      <label>Assigned<select id="vhMtAssigned"><option value=""></option></select></label>
      <label>Next oil change due<select id="vhMtOilDays" onchange="vhMtOilChg()">
        <option value=""></option><option value="30">30 days</option><option value="45">45 days</option>
        <option value="60">60 days</option><option value="90">90 days</option>
        <option value="__new">&#xFF0B; Add new&hellip;</option>
      </select><input id="vhMtOilNew" placeholder="e.g. 120 days" style="display:none;margin-top:4px"></label>
      <label>RO number<input id="vhMtRo"></label>
      <label>Vehicle status<select id="vhMtVehSt">
        <option value="">No change</option><option value="Operational">Operational</option><option value="Grounded">Grounded</option>
      </select></label>
      <label>Job status<select id="vhMtJobSt">
        <option value="Open">Open</option><option value="In Progress">In Progress</option><option value="Completed">Completed</option>
      </select></label>
      <label>Parts replaced<input id="vhMtParts" placeholder="Parts"></label>
    </div>
    <label>Description / notes<textarea id="vhMtNotes" rows="3"></textarea></label>
  </div>
  <div class="vh-drbtns">
    <button class="btn2" onclick="vhClose()">Cancel</button>
    <button class="btn2 primary" id="vhMtSaveBtn" onclick="vhMaintSave()">Save Maintenance</button>
  </div>
</div>

<script>
mvpxListInit({
  ctrl: '<%=_searchBean.getController()%>',
  from: '<%=_searchBean.getSrhFromDate()%>',
  to:   '<%=_searchBean.getSrhToDate()%>',
  filters: [
    { id:'filterNum',  key:'num',  label:'Vehicle #',   mode:'includes' },
    { id:'filterTier', key:'tier', label:'Tier',        mode:'exact' },
    { id:'filterProv', key:'prov', label:'Provider',    mode:'exact' },
    { id:'filterOp',   key:'op',   label:'Op Status',   mode:'exact' },
    { id:'filterSt',   key:'st',   label:'Status',      mode:'exact' },
    { id:'filterRep',  key:'rep',  label:'Repair',      mode:'exact' }
  ]
});
/* default filters: Operational + Active + Repair all */
(function vhApplyDefaults(){
  var op = document.getElementById('filterOp');
  var st = document.getElementById('filterSt');
  var rp = document.getElementById('filterRep');
  if (op && !op.value) {
    var want = '<%=defOpVal.replace("'", "\\'")%>';
    for (var i = 0; i < op.options.length; i++) {
      if (op.options[i].value === want || op.options[i].value.indexOf('oper') === 0) {
        op.value = op.options[i].value; break;
      }
    }
  }
  if (st && !st.value) st.value = 'active';
  if (rp) rp.value = '';
  mvpxApplyFilters();
})();

/* count lines double as one-tap filters */
function vhChip(selId, val) {
  var s = document.getElementById(selId);
  if (!s) return;
  s.value = (s.value === val ? '' : val);
  mvpxApplyFilters();
}
/* show/hide the summary cards; the auto-fit pager reclaims the space */
function vhSummary() {
  var cards = document.querySelector('.vh-cards'), btn = document.getElementById('vhSumBtn');
  var hidden = cards.style.display === 'none';
  cards.style.display = hidden ? '' : 'none';
  btn.textContent = hidden ? 'Hide summary' : 'Show summary';
  if (typeof mvpxFitStart === 'function') mvpxFitStart();
}
/* scoped card line: op status + a second filter together */
function vhChip2(opVal, selId, val) {
  var op = document.getElementById('filterOp'), s = document.getElementById(selId);
  if (!op || !s) return;
  if (op.value === opVal && s.value === val) { op.value = ''; s.value = ''; }
  else { op.value = opVal; s.value = val; }
  mvpxApplyFilters();
}
/* out-for-repair card line: repair flag + a second filter together */
function vhChip2r(selId, val) {
  var rp = document.getElementById('filterRep'), s = document.getElementById(selId);
  if (!rp || !s) return;
  if (rp.value === '1' && s.value === val) { rp.value = ''; s.value = ''; }
  else { rp.value = '1'; s.value = val; }
  mvpxApplyFilters();
}
function vhChipReset() {
  ['filterNum','filterTier','filterProv'].forEach(function(id){
    var el = document.getElementById(id); if (el) el.value = '';
  });
  var op = document.getElementById('filterOp');
  var st = document.getElementById('filterSt');
  var rp = document.getElementById('filterRep');
  if (op) {
    var want = '<%=defOpVal.replace("'", "\\'")%>';
    op.value = '';
    for (var i = 0; i < op.options.length; i++) {
      if (op.options[i].value === want || op.options[i].value.indexOf('oper') === 0) {
        op.value = op.options[i].value; break;
      }
    }
  }
  if (st) st.value = 'active';
  if (rp) rp.value = '';
  mvpxApplyFilters();
}

/* shared ajax for the drawers */
function vhAjax(params, cb) {
  var body = new URLSearchParams();
  body.append('submitType', '<%=SubmitType.DYNAMIC%>');
  body.append('controller', '<%=_searchBean.getController()%>');
  Object.keys(params).forEach(function(k){ body.append(k, params[k]); });
  ['entityID','loginUser','loginUserID','loginUserRoles','loginUserDisplayName'].forEach(function(k){
    var el = document.getElementById(k); if (el) body.append(k, el.value);
  });
  fetch('MVPGServlet', { method:'POST', headers:{'Content-Type':'application/x-www-form-urlencoded'}, body: body.toString() })
    .then(function(r){ return r.text(); })
    .then(cb)
    .catch(function(){ mvpxToast('Request failed', false); });
}
function mdyToIso(v) {
  var p = (v || '').split('/');
  return p.length === 3 ? p[2] + '-' + p[0] + '-' + p[1] : '';
}
function isoToMdy(v) {
  var p = (v || '').split('-');
  return p.length === 3 ? p[1] + '/' + p[2] + '/' + p[0] : '';
}
function vhSetSel(id, val) {
  var s = document.getElementById(id);
  if (val && !Array.prototype.some.call(s.options, function(o){ return o.value === val; })) {
    var o = document.createElement('option'); o.value = val; o.text = val; s.add(o);
  }
  s.value = val || '';
}

/* row click: edit in a drawer on this page */
function vhEdit(id) {
  vhAjax({ requestType:'vehGet', recordID:id }, function(resp){
    var d; try { d = JSON.parse(resp); } catch(e) { mvpxToast('Could not load vehicle', false); return; }
    document.getElementById('vhId').value = id;
    document.getElementById('vhDrName').textContent = d.num;
    document.getElementById('vhNum').value = d.num;
    document.getElementById('vhVin').value = d.vin;
    vhSetSel('vhType', d.type);
    document.getElementById('vhPlate').value = d.plate;
    document.getElementById('vhState').value = d.state;
    document.getElementById('vhRegExp').value = mdyToIso(d.regExp);
    vhSetSel('vhTier', d.tier);
    document.getElementById('vhOp').value = d.op;
    document.getElementById('vhRentS').value = mdyToIso(d.rentS);
    document.getElementById('vhRentE').value = mdyToIso(d.rentE);
    document.getElementById('vhOdometer').value = d.odometer || '';
    document.getElementById('vhOdoDate').value = mdyToIso(d.odoDate);
    document.getElementById('vhOilMileage').value = d.oilMileage || '';
    document.getElementById('vhOilDate').value = mdyToIso(d.oilDate);
    document.getElementById('vhReason').value = '';
    vhOpChg();
    document.getElementById('vhHxDrawer').classList.remove('on');
    document.getElementById('vhScrim').classList.add('on');
    document.getElementById('vhDrawer').classList.add('on');
  });
}
function vhOpChg() {
  document.getElementById('vhReasonWrap').style.display =
    document.getElementById('vhOp').value === '1' ? '' : 'none';
}
function vhClose() {
  document.getElementById('vhDrawer').classList.remove('on');
  document.getElementById('vhHxDrawer').classList.remove('on');
  document.getElementById('vhMtDrawer').classList.remove('on');
  document.getElementById('vhScrim').classList.remove('on');
}

/* + Maintenance: type cards + structured details */
var VH_MT = { type:'', cat:'', id:'', code:'' };
var VH_MT_FROMHX = false;
function vhMtPick(el) {
  document.querySelectorAll('.vh-mtype').forEach(function(c){ c.classList.remove('on'); });
  el.classList.add('on');
  VH_MT.type = el.dataset.t;
  VH_MT.cat = el.dataset.c;
  VH_MT.id = el.dataset.id || '';
  VH_MT.code = el.dataset.code || '';
}
function vhMtPickByIdOrCode(tid, code) {
  var hit = null;
  document.querySelectorAll('.vh-mtype').forEach(function(c){
    if ((tid && c.dataset.id === tid) || (!hit && code && c.dataset.code === code)) hit = c;
  });
  if (hit) vhMtPick(hit);
}
function vhMtShopChg() {
  document.getElementById('vhMtShopNewWrap').style.display =
    document.getElementById('vhMtShopSel').value === '__new' ? '' : 'none';
}
function vhMtShopVal() {
  var v = document.getElementById('vhMtShopSel').value;
  return v === '__new' ? document.getElementById('vhMtShopNew').value.trim() : v;
}
function vhMtOilChg() {
  document.getElementById('vhMtOilNew').style.display =
    document.getElementById('vhMtOilDays').value === '__new' ? '' : 'none';
}
function vhMtOilVal() {
  var v = document.getElementById('vhMtOilDays').value;
  return v === '__new' ? document.getElementById('vhMtOilNew').value.trim() : v;
}
function vhMtLoadShops(current) {
  vhAjax({ requestType:'vehShops' }, function(resp){
    try {
      var shops = JSON.parse(resp), sel = document.getElementById('vhMtShopSel');
      var h = '<option value="">- Select shop -</option>';
      var found = false;
      shops.forEach(function(s){
        if (s === current) found = true;
        h += '<option value="' + s + '">' + s + '</option>';
      });
      if (current && !found) { h += '<option value="' + current + '">' + current + '</option>'; found = true; }
      h += '<option value="__new">&#xFF0B; Add new shop&hellip;</option>';
      sel.innerHTML = h;
      sel.value = current || '';
      vhMtShopChg();
    } catch(e) { }
  });
}
function vhMtLoadDispatchers(current) {
  vhAjax({ requestType:'vehDispatchers' }, function(resp){
    try {
      var list = JSON.parse(resp), sel = document.getElementById('vhMtAssigned');
      var loginEl = document.getElementById('loginUser');
      var loginUser = loginEl ? loginEl.value : '';
      var dispEl = document.getElementById('loginUserDisplayName');
      var loginNm = dispEl && dispEl.value ? dispEl.value : loginUser;
      var h = '<option value=""></option>', found = false, defNm = '';
      list.forEach(function(n){
        var nm = (n && typeof n === 'object') ? (n.nm || n.id || '') : n;
        var user = (n && typeof n === 'object') ? (n.id || nm) : n;
        if (!nm) return;
        if (nm === current) found = true;
        if (user === loginUser || nm === loginNm) defNm = nm;
        h += '<option value="' + nm + '">' + nm + (user && user !== nm ? ' ('+user+')' : '') + '</option>';
      });
      if (current && !found) h += '<option value="' + current + '">' + current + '</option>';
      sel.innerHTML = h;
      sel.value = current || defNm || '';
    } catch(e) { }
  });
}
function vhMtShowCurSt(id) {
  document.getElementById('vhMtCurSt').textContent = '';
  vhAjax({ requestType:'vehGet', recordID:id }, function(resp){
    try {
      var d = JSON.parse(resp);
      var opSel = document.getElementById('vhOp');
      var opTxt = '';
      Array.prototype.forEach.call(opSel.options, function(o){ if (o.value === d.op) opTxt = o.text; });
      document.getElementById('vhMtCurSt').textContent = 'CURRENT: ' + (opTxt || d.op).toUpperCase()
        + (d.rep === '1' ? ' \u00B7 OUT FOR REPAIR' : '');
    } catch(e) { }
  });
}
function vhMaintOpen(id, name) {
  VH_MT_FROMHX = false;
  document.getElementById('vhMtTitle').textContent = 'Log Maintenance';
  document.getElementById('vhMtId').value = id;
  document.getElementById('vhMtLogId').value = '';
  document.getElementById('vhMtName').textContent = name;
  VH_MT.type = ''; VH_MT.cat = ''; VH_MT.id = ''; VH_MT.code = '';
  document.querySelectorAll('.vh-mtype').forEach(function(c){ c.classList.remove('on'); });
  var t = new Date();
  document.getElementById('vhMtSvcDate').value = t.getFullYear() + '-'
    + ('0' + (t.getMonth() + 1)).slice(-2) + '-' + ('0' + t.getDate()).slice(-2);
  ['vhMtNextSvc','vhMtFollowUp','vhMtRo','vhMtParts','vhMtNotes','vhMtShopNew'].forEach(function(k){
    document.getElementById(k).value = '';
  });
  document.getElementById('vhMtOilDays').value = '';
  document.getElementById('vhMtOilNew').value = ''; document.getElementById('vhMtOilNew').style.display = 'none';
  document.getElementById('vhMtVehSt').value = '';
  document.getElementById('vhMtJobSt').value = 'Open';
  var disp = document.getElementById('loginUserDisplayName');
  vhMtLoadShops('');
  vhMtLoadDispatchers(disp ? disp.value : '');
  vhMtShowCurSt(id);
  document.getElementById('vhDrawer').classList.remove('on');
  document.getElementById('vhHxDrawer').classList.remove('on');
  document.getElementById('vhScrim').classList.add('on');
  document.getElementById('vhMtDrawer').classList.add('on');
}
/* edit an OPEN maintenance record from the history drawer */
function vhMaintEditRow(idx) {
  var rec = window.VH_HX_RECS ? window.VH_HX_RECS[idx] : null;
  if (!rec) return;
  var vehId = document.getElementById('vhMtId').value || window.VH_HX_VEHID;
  VH_MT_FROMHX = true;
  document.getElementById('vhMtTitle').textContent = 'Update Maintenance';
  document.getElementById('vhMtId').value = window.VH_HX_VEHID;
  document.getElementById('vhMtLogId').value = rec.id;
  document.getElementById('vhMtName').textContent = window.VH_HX_VEHNAME;
  vhMtPickByIdOrCode(rec.tid, rec.code);
  document.getElementById('vhMtSvcDate').value = mdyToIso(rec.d);
  document.getElementById('vhMtNextSvc').value = mdyToIso(rec.nextSvc);
  document.getElementById('vhMtFollowUp').value = mdyToIso(rec.followUp);
  document.getElementById('vhMtRo').value = rec.ro;
  document.getElementById('vhMtParts').value = rec.parts;
  document.getElementById('vhMtNotes').value = rec.m;
  if (['30','45','60','90'].indexOf(rec.days) >= 0) {
    document.getElementById('vhMtOilDays').value = rec.days;
    document.getElementById('vhMtOilNew').value = ''; document.getElementById('vhMtOilNew').style.display = 'none';
  } else if (rec.days && rec.days.length) {
    document.getElementById('vhMtOilDays').value = '__new';
    document.getElementById('vhMtOilNew').value = rec.days; document.getElementById('vhMtOilNew').style.display = '';
  } else {
    document.getElementById('vhMtOilDays').value = '';
    document.getElementById('vhMtOilNew').value = ''; document.getElementById('vhMtOilNew').style.display = 'none';
  }
  document.getElementById('vhMtVehSt').value = '';
  document.getElementById('vhMtJobSt').value = 'Open';
  document.getElementById('vhMtShopNew').value = '';
  vhMtLoadShops(rec.shop);
  vhMtLoadDispatchers(rec.asg);
  vhMtShowCurSt(window.VH_HX_VEHID);
  document.getElementById('vhHxDrawer').classList.remove('on');
  document.getElementById('vhScrim').classList.add('on');
  document.getElementById('vhMtDrawer').classList.add('on');
}
function vhMaintSave() {
  var id = document.getElementById('vhMtId').value;
  var logId = document.getElementById('vhMtLogId').value;
  var btn = document.getElementById('vhMtSaveBtn');
  if (!VH_MT.type) { mvpxToast('Pick a maintenance type (Step 1)', false); return; }
  if (!document.getElementById('vhMtSvcDate').value) { mvpxToast('Service date is required', false); return; }
  btn.disabled = true;
  var vehSt = document.getElementById('vhMtVehSt').value;
  var params = {
    requestType: logId ? 'vehMaintUpd' : 'vehMaint', recordID:id,
    mType:  VH_MT.type,
    mCat:   VH_MT.cat,
    mTypeId: VH_MT.id,
    mCode:  VH_MT.code,
    shop:   vhMtShopVal(),
    svcDate: isoToMdy(document.getElementById('vhMtSvcDate').value),
    nextSvc: isoToMdy(document.getElementById('vhMtNextSvc').value),
    followUp: isoToMdy(document.getElementById('vhMtFollowUp').value),
    assigned: document.getElementById('vhMtAssigned').value,
    oilDays: vhMtOilVal(),
    roNum:  document.getElementById('vhMtRo').value.trim(),
    vehSt:  vehSt,
    jobSt:  document.getElementById('vhMtJobSt').value,
    parts:  document.getElementById('vhMtParts').value.trim(),
    notes:  document.getElementById('vhMtNotes').value.trim()
  };
  if (logId) params.logID = logId;
  vhAjax(params, function(resp){
    btn.disabled = false;
    var m = /<mesg>([^<]*)<\/mesg>/.exec(resp);
    if (resp.indexOf('<status>true') >= 0) {
      /* reflect a vehicle-status change on the visible row */
      if (vehSt) {
        var tr = document.querySelector('#ciRows tr[data-id="' + id + '"]');
        if (tr) {
          var pillCls = vehSt === 'Operational' ? 'green' : 'red';
          tr.querySelectorAll('td')[11].innerHTML = '<span class="pill ' + pillCls + '"><span class="d"></span>' + vehSt + '</span>';
          tr.dataset.op = vehSt.toLowerCase();
        }
      }
      vhClose();
      mvpxToast(m && m[1] ? m[1] : 'Maintenance logged', true);
      /* came from the history drawer: reopen it with fresh data */
      if (VH_MT_FROMHX) vhHist(window.VH_HX_VEHID, window.VH_HX_VEHNAME);
    } else {
      mvpxToast(m && m[1] ? m[1] : 'Save failed', false);
    }
  });
}
function vhSave() {
  var id = document.getElementById('vhId').value;
  var btn = document.getElementById('vhSaveBtn');
  btn.disabled = true;
  vhAjax({
    requestType:'vehSave', recordID:id,
    num:   document.getElementById('vhNum').value.trim(),
    type:  document.getElementById('vhType').value,
    plate: document.getElementById('vhPlate').value.trim(),
    state: document.getElementById('vhState').value.trim(),
    regExp: isoToMdy(document.getElementById('vhRegExp').value),
    tier:  document.getElementById('vhTier').value,
    op:    document.getElementById('vhOp').value,
    rentS: isoToMdy(document.getElementById('vhRentS').value),
    rentE: isoToMdy(document.getElementById('vhRentE').value),
    odometer: document.getElementById('vhOdometer').value.trim(),
    odoDate: isoToMdy(document.getElementById('vhOdoDate').value),
    oilMileage: document.getElementById('vhOilMileage').value.trim(),
    oilDate: isoToMdy(document.getElementById('vhOilDate').value),
    comments: document.getElementById('vhReason').value.trim()
  }, function(resp){
    btn.disabled = false;
    var m = /<mesg>([^<]*)<\/mesg>/.exec(resp);
    if (resp.indexOf('<status>true') >= 0) {
      vhRowRefresh(id);
      vhClose();
      mvpxToast(m && m[1] ? m[1] : 'Saved', true);
    } else {
      mvpxToast(m && m[1] ? m[1] : 'Save failed', false);
    }
  });
}
/* update the visible row without reloading (counts refresh on next load) */
function vhRowRefresh(id) {
  var tr = document.querySelector('#ciRows tr[data-id="' + id + '"]');
  if (!tr) return;
  var tds = tr.querySelectorAll('td');
  var num = document.getElementById('vhNum').value.trim();
  var tier = document.getElementById('vhTier').value;
  var opSel = document.getElementById('vhOp');
  var opTxt = opSel.options[opSel.selectedIndex] ? opSel.options[opSel.selectedIndex].text : '';
  tds[0].querySelector('a').textContent = num;
  tds[2].textContent = document.getElementById('vhOdometer').value.trim() || '\u2014';
  tds[3].textContent = isoToMdy(document.getElementById('vhOdoDate').value) || '\u2014';
  tds[4].textContent = document.getElementById('vhOilMileage').value.trim() || '\u2014';
  tds[5].textContent = isoToMdy(document.getElementById('vhOilDate').value) || '\u2014';
  tds[6].textContent = tier || '\u2014';
  tds[7].textContent = isoToMdy(document.getElementById('vhRentS').value) || '\u2014';
  tds[8].textContent = isoToMdy(document.getElementById('vhRentE').value) || '\u2014';
  var pillCls = opTxt.toLowerCase().indexOf('oper') === 0 ? 'green'
    : (opTxt.toLowerCase().indexOf('grounded') >= 0 ? 'red' : 'slate');
  tds[11].innerHTML = '<span class="pill ' + pillCls + '"><span class="d"></span>' + opTxt + '</span>';
  tr.dataset.num = num.toLowerCase();
  tr.dataset.tier = tier.toLowerCase();
  tr.dataset.op = opTxt.toLowerCase();
}

/* maintenance history: log records (open ones editable) + the notes trail */
function vhHist(id, name) {
  vhAjax({ requestType:'vehHistory', recordID:id }, function(resp){
    var d; try { d = JSON.parse(resp); } catch(e) { mvpxToast('Could not load history', false); return; }
    window.VH_HX_RECS = d.recs || [];
    window.VH_HX_VEHID = id;
    window.VH_HX_VEHNAME = name;
    document.getElementById('vhHxName').textContent = name;
    var h = '';
    h += '<div class="vh-step">Maintenance records (' + window.VH_HX_RECS.length + ')</div>';
    if (!window.VH_HX_RECS.length) h += '<div class="it"><div class="msg">No maintenance logged yet.</div></div>';
    window.VH_HX_RECS.forEach(function(r, i){
      var open = r.open === '1';
      h += '<div class="vh-rec">'
         + '<div class="hd"><span class="ic">' + (r.ic || '&#128295;') + '</span><b>' + r.ty
         + (r.cat ? ' <span class="t" style="color:var(--da-faint)">(' + r.cat + ')</span>' : '') + '</b>'
         + '<span class="vh-openpill ' + (open ? 'open' : 'done') + '">' + (open ? 'Open' : 'Completed ' + r.done) + '</span>'
         + (open ? '<button class="btn2 sm" onclick="vhMaintEditRow(' + i + ')">Update</button>' : '')
         + '</div>'
         + '<div class="meta"><b>' + r.d + '</b>'
         + (r.shop ? ' \u00B7 ' + r.shop : '')
         + (r.ro ? ' \u00B7 RO# ' + r.ro : '')
         + (r.parts ? ' \u00B7 Parts: ' + r.parts : '')
         + (r.nextSvc ? ' \u00B7 Next svc ' + r.nextSvc : '')
         + (r.followUp ? ' \u00B7 Follow-up ' + r.followUp + (r.asg ? ' (' + r.asg + ')' : '') : '')
         + (r.m ? '<br>' + r.m : '')
         + '</div></div>';
    });
    h += '<div class="vh-step" style="margin-top:14px">Notes &amp; status trail</div>';
    (d.notes || []).forEach(function(it){
      h += '<div class="it"><div class="top"><span>' + it.d + '</span><span>' + it.u + '</span></div>'
         + '<div class="msg">' + it.m + '</div></div>';
    });
    if (!(d.notes || []).length) h += '<div class="it"><div class="msg">No notes yet.</div></div>';
    document.getElementById('vhHxBody').innerHTML = h;
    document.getElementById('vhDrawer').classList.remove('on');
    document.getElementById('vhMtDrawer').classList.remove('on');
    document.getElementById('vhScrim').classList.add('on');
    document.getElementById('vhHxDrawer').classList.add('on');
  });
}
document.addEventListener('keydown', function(e){ if (e.key === 'Escape') vhClose(); });

/* out-for-repair toggle: saves via ajax, flips in place (no reload) */
function vhRepair(id, btn) {
  var to = btn.classList.contains('on') ? '0' : '1';
  btn.disabled = true;
  var body = new URLSearchParams();
  body.append('submitType', '<%=SubmitType.DYNAMIC%>');
  body.append('controller', '<%=_searchBean.getController()%>');
  body.append('requestType', 'repairToggle');
  body.append('recordID', id);
  body.append('to', to);
  ['entityID','loginUser','loginUserID','loginUserRoles','loginUserDisplayName'].forEach(function(k){
    var el = document.getElementById(k); if (el) body.append(k, el.value);
  });
  fetch('MVPGServlet', { method:'POST', headers:{'Content-Type':'application/x-www-form-urlencoded'}, body: body.toString() })
    .then(function(r){ return r.text(); })
    .then(function(resp){
      btn.disabled = false;
      var m = /<mesg>([^<]*)<\/mesg>/.exec(resp);
      if (resp.indexOf('<status>true') >= 0) {
        btn.classList.toggle('on', to === '1');
        var tr = btn.closest('tr');
        if (tr) tr.dataset.rep = to;
        mvpxToast(m && m[1] ? m[1] : 'Updated', true);
      } else {
        mvpxToast(m && m[1] ? m[1] : 'Update failed', false);
      }
    })
    .catch(function(){ btn.disabled = false; mvpxToast('Update failed', false); });
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
			var mandatoryFieldsArray = new Array();
			mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["vehicleNumber"], "Vehicle Number");
			mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["vinNumber"], "VIN Number");
			mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["vehicleType"], "Vehicle Type");
			mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["licensePlate"], "License Plate");
			mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["registeredState"], "Registered State");
			mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["registrationExpiryDate"], "Registration Expiry");
			mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["serviceTier"], "Service Tier");
			mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["opertionalStatus"], "Opertional Status");

			if(document.formmain["opertionalStatus"].value == "0") { // Opertional
				mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["rentalStart"], "Rental Start");
				mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["rentalEnd"], "Rental End");
			}
			if(document.formmain["opertionalStatus"].value == "1") {// Grounded
				mandatoryFieldsArray[mandatoryFieldsArray.length] = new Array(document.formmain["comments"], "Reason");
			}
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
			function checkVehicleType(thisObj, index) {
				index = index == undefined ? "" : index;
				if(thisObj.value == "Rental") {
					enableOrDisableID("rentalStartDivID"+index, "");
					enableOrDisableID("rentalEndDivID"+index, "");
				} else {
					enableOrDisableID("rentalStartDivID"+index, "");
					enableOrDisableID("rentalEndDivID"+index, "");
				}
			}
			</script>
				<input type="hidden" id="adminVehicleID" name="adminVehicleID" value="<%=_recordBean.getAdminVehicleID()%>">
				<div class="row">
					<div class="col-12 col-md-5">
						<div class="row form-row form-group form-group-sm">
							<label class="col-12 col-md-3 col-form-label required text-left">Vehicle Number</label>
							<div class="col-12 col-md-9 text-left"><input type="text" id="vehicleNumber" name="vehicleNumber" class="form-control form-control-sm" value="<%=_recordBean.getVehicleNumber()%>"></div>
						</div>
						<div class="row form-row form-group form-group-sm">
							<label class="col-12 col-md-3 col-form-label required text-left">VIN Number</label>
							<div class="col-12 col-md-9 text-left"><input type="text" id="vinNumber" name="vinNumber" class="form-control form-control-sm" value="<%=_recordBean.getVinNumber()%>" <%if(submitType == SubmitType.UPDATE) {%>readOnly<%}%>></div>
						</div>
						<div class="row form-row form-group form-group-sm">
							<label class="col-12 col-md-3 col-form-label required text-left">Vehicle Type</label>
							<div class="col-12 col-md-9 text-left"><select id="vehicleType" name="vehicleType" class="form-control form-control-sm" onChange="checkVehicleType(this);"><option value=""></option><option value="Rental">Rental</option><option value="Amazon-Owned">Amazon-Owned</option></select></div>
						</div>
						<div class="row form-row form-group form-group-sm" id="rentalStartDivID" style="display:none">
							<label class="col-12 col-md-3 col-form-label required text-left">Rental Start</label>
							<div class="col-12 col-md-9 text-left"><input type="text" id="rentalStart" name="rentalStart" class="form-control form-control-sm datepicker" value="<%=_recordBean.getRentalStart()%>"></div>
						</div>
						<div class="row form-row form-group form-group-sm" id="rentalEndDivID" style="display:none">
							<label class="col-12 col-md-3 col-form-label required text-left">Rental End</label>
							<div class="col-12 col-md-9 text-left"><input type="text" id="rentalEnd" name="rentalEnd" class="form-control form-control-sm datepicker" value="<%=_recordBean.getRentalEnd()%>"></div>
						</div>
					</div>

					<div class="col-12 col-md-2"></div>

					<div class="col-12 col-md-5">
						<div class="row form-row form-group form-group-sm">
							<label class="col-12 col-md-3 col-form-label required text-left">License Plate</label>
							<div class="col-12 col-md-9 text-left"><input type="text" id="licensePlate" name="licensePlate" class="form-control form-control-sm" value="<%=_recordBean.getLicensePlate()%>"></div>
						</div>
						<div class="row form-row form-group form-group-sm">
							<label class="col-12 col-md-3 col-form-label required text-left">Registered State</label>
							<div class="col-12 col-md-9 text-left"><select id="registeredState" name="registeredState" class="form-control form-control-sm"><option value=""></option></select></div>
						</div>
						<div class="row form-row form-group form-group-sm">
							<label class="col-12 col-md-3 col-form-label required text-left">Registration Expiry</label>
							<div class="col-12 col-md-9 text-left"><input type="text" id="registrationExpiryDate" name="registrationExpiryDate" class="form-control form-control-sm datepicker" value="<%=_recordBean.getRegistrationExpiryDate()%>"></div>
						</div>
						<div class="row form-row form-group form-group-sm">
							<label class="col-12 col-md-3 col-form-label required text-left">Service Tier</label>
							<div class="col-12 col-md-9 text-left"><select id="serviceTier" name="serviceTier" class="form-control form-control-sm">
								<option value=""></option>
								<%_array = _mainUtil.getDataArray(_mainUtil.getServiceTier());for(int k=0; k<_array.length; k++) {%><option value="<%=_array[k][0]%>"><%=_array[k][1]%></option><%}%>
							</select></div>
						</div>
						<%if(submitType == SubmitType.UPDATE) {%>
							<div class="row form-row form-group form-group-sm">
								<label class="col-12 col-md-3 col-form-label required text-left">Opertional Status</label>
								<div class="col-12 col-md-9 text-left"><select id="opertionalStatus" name="opertionalStatus" class="form-control form-control-sm" onChange="checkOpertionalStatus(this);"><option value=""></option>
								<%_array = _mainUtil.getDataArray(_mainUtil.getOpertionalStatus());for(int k=0; k<_array.length; k++) {%><option value="<%=_array[k][0]%>"><%=_array[k][1]%></option><%}%></select></div>
							</div>
							<div class="row form-row form-group form-group-sm" id="opertionalStatusReasonDivID" <%if(!"1".equalsIgnoreCase(_recordBean.getOpertionalStatus())) {%>style="display:none"<%}%>>
								<label class="col-12 col-md-3 col-form-label required text-left">Reason</label>
								<div class="col-12 col-md-9 text-left"><textarea id="comments" name="comments" class="form-control form-control-sm"></textarea></div>
							</div>
						<%} else {%>
							<input type="hidden" id="opertionalStatus" name="opertionalStatus" value="0">
						<%}%>
					</div>
				</div>
				<script>
				function checkOpertionalStatus(thisObj) {
					enableOrDisableID("opertionalStatusReasonDivID", "none");
					if(thisObj.value == "1") {
						enableOrDisableID("opertionalStatusReasonDivID", "");
					}
				}
				initSelect2Suggestor("usStatesList", "registeredState", "<%=_recordBean.getRegisteredState()%>", false, "");
				setSelectBoxValue(document.formmain["vehicleType"], "<%=_recordBean.getVehicleType()%>");
				initSelect2SuggestorConvert("serviceTier", "", true);
				setSelect2Option("serviceTier", "<%=_recordBean.getServiceTier()%>");
				setSelectBoxValue(document.formmain["opertionalStatus"], "<%=_recordBean.getOpertionalStatus()%>");
				checkVehicleType(document.formmain["vehicleType"]);
				</script>

			<%} else if(submitType == SubmitType.BROWSE) {
				String comments = "";
				if("1".equalsIgnoreCase(_recordBean.getOpertionalStatus()) && _recordBean.getOpertionalStatusReasonList().size() > 0) {
					List tempList = (ArrayList) _recordBean.getOpertionalStatusReasonList().get(0);
					comments = tempList.get(1) == null ? "" : tempList.get(1).toString().trim();
				}%>
				<input type="hidden" id="adminVehicleID" name="adminVehicleID" value="<%=_recordBean.getAdminVehicleID()%>">
				<div class="row">
					<div class="col-12 col-md-5">
						<div class="row">
							<label class="col-5 col-md-3 col-form-label text-left">Vehicle Number</label>
							<div class="col-7 col-md-9 form-control-plaintext text-left"><%=_recordBean.getVehicleNumber()%></div>
						</div>
						<div class="row">
							<label class="col-5 col-md-3 col-form-label text-left">VIN Number</label>
							<div class="col-7 col-md-9 form-control-plaintext text-left"><%=_recordBean.getVinNumber()%></div>
						</div>
						<div class="row">
							<label class="col-5 col-md-3 col-form-label text-left">Vehicle Type</label>
							<div class="col-7 col-md-9 form-control-plaintext text-left"><%=_recordBean.getVehicleType()%></div>
						</div>
						<div class="row">
							<label class="col-5 col-md-3 col-form-label text-left">Rental Start</label>
							<div class="col-7 col-md-9 form-control-plaintext text-left"><%=_recordBean.getRentalStart()%></div>
						</div>
						<div class="row">
							<label class="col-5 col-md-3 col-form-label text-left">Rental End</label>
							<div class="col-7 col-md-9 form-control-plaintext text-left"><%=_recordBean.getRentalEnd()%></div>
						</div>
					</div>

					<div class="col-12 col-md-2"></div>

					<div class="col-12 col-md-5">
						<div class="row">
							<label class="col-5 col-md-3 col-form-label text-left">License Plate</label>
							<div class="col-7 col-md-9 form-control-plaintext text-left"><%=_recordBean.getLicensePlate()%></div>
						</div>
						<div class="row">
							<label class="col-5 col-md-3 col-form-label text-left">Registration Expiry</label>
							<div class="col-7 col-md-9 form-control-plaintext text-left"><%=_recordBean.getRegistrationExpiryDate()%></div>
						</div>
						<div class="row">
							<label class="col-5 col-md-3 col-form-label text-left">Registered State</label>
							<div class="col-7 col-md-9 form-control-plaintext text-left"><%=_recordBean.getRegisteredState()%></div>
						</div>
						<div class="row">
							<label class="col-5 col-md-3 col-form-label text-left">Service Tire</label>
							<div class="col-7 col-md-9 form-control-plaintext text-left"><%=_recordBean.getServiceTier()%></div>
						</div>
						<div class="row">
							<label class="col-5 col-md-3 col-form-label text-left">Opertional Status</label>
							<div class="col-7 col-md-9 form-control-plaintext text-left"><%=_mainUtil.getOpertionalStatus().get(_recordBean.getOpertionalStatus()) == null ? _recordBean.getOpertionalStatus() : _mainUtil.getOpertionalStatus().get(_recordBean.getOpertionalStatus())%></div>
						</div>
					</div>
				</div>

				<%if(_recordBean.getOpertionalStatusReasonList().size() > 0) {%>
				<div class="row">
					<div class="col-12 col-md-3"></div>
					<div class="col-12 col-md-6">
						<div class='card'>
							<div class='card-header table-title-header m-0 py-2'>
								<div class="row">
									<div class="col-12 col-md-2"></div>
									<div class="col-12 col-md-8">Grounded Hx</div>
									<div class="col-12 col-md-2 text-right my-auto"></div>
								</div>
							</div>

							<div class='card-body m-1 p-1'>
								<table width="100%" border="0" cellpadding="0" cellspacing="0" class="table table-bordered table-striped table-hover table-sm table-block table-vertical sortable mb-0">
									<tbody class="tbody-block">
										<%for(int i=0; i<_recordBean.getOpertionalStatusReasonList().size(); i++) {
										List tempList = (ArrayList) _recordBean.getOpertionalStatusReasonList().get(i);%>
										<tr class="tr-block">
											<td class="td-block table-value" data-th="Date" width="15%"><%=tempList.get(3) == null ? "" : tempList.get(3).toString().trim()%></td>
											<td class="td-block table-value" data-th="User" width="15%"><%=tempList.get(2) == null ? "" : tempList.get(2).toString().trim()%></td>
											<td class="td-block table-value" data-th="Reason" width="70%"><%=tempList.get(1) == null ? "" : tempList.get(1).toString().trim()%></td>
										</tr>
										<%}%>
									</tbody>
								</table>
							</div>
						</div>
					</div>
					<div class="col-12 col-md-3"></div>
				</div>
				<%}%>
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
						<button class="btn btn-success text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.CREATE_CONFIRM%>','<%=_recordBean.getController()%>','<%=_recordBean.getAdminVehicleID()%>');">Save</button>
						<!--button class="btn btn-success text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.CREATE_CONFIRM%>','<%=_recordBean.getController()%>','<%=_recordBean.getAdminVehicleID()%>','2');">Save & Post</button --></div>
					<%} else {%>
						<button class="btn btn-success text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.UPDATE_CONFIRM%>','<%=_recordBean.getController()%>','<%=_recordBean.getAdminVehicleID()%>');">Save</button>
						<!--button class="btn btn-success text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.UPDATE_CONFIRM%>','<%=_recordBean.getController()%>','<%=_recordBean.getAdminVehicleID()%>','2');">Save & Post</button --></div>
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
					<button class="btn btn-primary text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.UPDATE%>','<%=_recordBean.getController()%>','<%=_recordBean.getAdminVehicleID()%>');">Edit</button>
				<%}%>
				</div>
				<div class="col-4 text-right">
				<%if("0".equalsIgnoreCase(_recordBean.getStatus())) {%>
					<button class="btn btn-danger text-center" onClick="Javascript:submitPageDataForm('<%=SubmitType.DELETE%>','<%=_recordBean.getController()%>','<%=_recordBean.getAdminVehicleID()%>');">Delete</button>
				<%}%>
				</div>
			</div>
		<%}%>
	</div>
</div>
<%@ include file="includeFooter.jsp"%>
<%}%>