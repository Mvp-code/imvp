<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"
         import="java.util.*, com.util.*, com.beans.*" %>
<%
  /* Predict Scorecard — hosted inside the MVPx shell (sidebar + tabs), like the
     Dashboard/Reports pages. The scorecard carries its own Bootstrap + mvpg CSS,
     so it is embedded via a same-origin iframe (PredictScorecardView.jsp) to keep
     those styles from bleeding into the MVPx chrome. */
  String arLoginUser   = (request.getAttribute("loginUser") != null) ? request.getAttribute("loginUser").toString() : (String) session.getAttribute("loginUser");
  String arLoginRoles  = (request.getAttribute("loginUserRoles") != null) ? request.getAttribute("loginUserRoles").toString() : (String) session.getAttribute("loginUserRoles");
  String arEntityID    = (request.getAttribute("entityID") != null) ? request.getAttribute("entityID").toString() : (session.getAttribute("entityID") != null ? session.getAttribute("entityID").toString() : "1");
  String arDispName    = (request.getAttribute("loginUserDisplayName") != null) ? request.getAttribute("loginUserDisplayName").toString() : (session.getAttribute("loginUserDisplayName") != null ? session.getAttribute("loginUserDisplayName").toString() : "");
  String arLoginUserID = (request.getAttribute("loginUserID") != null) ? request.getAttribute("loginUserID").toString() : (session.getAttribute("loginUserID") != null ? session.getAttribute("loginUserID").toString() : "");
  if (arLoginUser == null)  arLoginUser  = "";
  if (arLoginRoles == null) arLoginRoles = "";
  if (arEntityID == null || arEntityID.length() == 0) arEntityID = "1";
  if (arDispName == null || arDispName.length() == 0) arDispName = "User";
  if (arLoginUserID == null) arLoginUserID = "";
%>
<jsp:useBean id="_recordBean" class="com.beans.SearchBean" scope="request" />
<jsp:useBean id="_errorBean"  class="com.beans.ErrorBean"  scope="request" />
<%
  int submitType = SubmitType.SEARCH;
  _recordBean.setController("PredictScorecard");
  _recordBean.setDisplayName("Predict Scorecard");
  request.setAttribute("loginUser", arLoginUser);
  request.setAttribute("loginUserRoles", arLoginRoles);
  request.setAttribute("entityID", arEntityID);
  request.setAttribute("loginUserDisplayName", arDispName);
  request.setAttribute("loginUserID", arLoginUserID);
  request.setAttribute("shellNoForm", "yes");
  request.setAttribute("hideTopbarSearch", "yes");
%>
<!DOCTYPE html>
<html lang="en">
<%@ include file="includeHeader.jsp"%>
<style>
  /* Fill the content area; the scorecard scrolls INSIDE the iframe while the
     MVPx sidebar/tabs stay fixed. Height is set by JS (the shell body is not a
     fixed-height flex container by default, so flex:1 would collapse). */
  #mvpxMainContent { padding: 0 !important; overflow: hidden !important; }
  #pscFrameWrap { margin: 0; padding: 0; }
  #pscFrame { display: block; width: 100%; border: 0; background: #f5f8ff; height: 80vh; }
</style>
<div id="pscFrameWrap">
  <iframe id="pscFrame" src="<%=request.getContextPath()%>/jsp/PredictScorecardView.jsp"
          title="Predict Scorecard"></iframe>
</div>
<script>
(function () {
  var f = document.getElementById("pscFrame");
  function sizeFrame() {
    var top = f.getBoundingClientRect().top;      /* distance from viewport top to the iframe */
    var h = window.innerHeight - top;             /* fill down to the viewport bottom */
    if (h < 240) h = 240;
    f.style.height = h + "px";
  }
  window.addEventListener("resize", sizeFrame);
  sizeFrame();
  f.addEventListener("load", sizeFrame);
  setTimeout(sizeFrame, 100);
  setTimeout(sizeFrame, 400);
  setTimeout(sizeFrame, 1000);
})();
</script>
<%@ include file="includeFooter.jsp"%>
