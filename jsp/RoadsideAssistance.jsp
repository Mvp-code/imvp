<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"
         import="java.util.*,com.util.*,com.beans.*" %>
<%
  String rsLoginUser   = request.getAttribute("loginUser") != null ? request.getAttribute("loginUser").toString() : (String) session.getAttribute("loginUser");
  String rsLoginRoles  = request.getAttribute("loginUserRoles") != null ? request.getAttribute("loginUserRoles").toString() : (String) session.getAttribute("loginUserRoles");
  String rsEntityID    = request.getAttribute("entityID") != null ? request.getAttribute("entityID").toString() : (session.getAttribute("entityID") != null ? session.getAttribute("entityID").toString() : "1");
  String rsDispName    = request.getAttribute("loginUserDisplayName") != null ? request.getAttribute("loginUserDisplayName").toString() : (session.getAttribute("loginUserDisplayName") != null ? session.getAttribute("loginUserDisplayName").toString() : "");
  String rsLoginUserID = request.getAttribute("loginUserID") != null ? request.getAttribute("loginUserID").toString() : (session.getAttribute("loginUserID") != null ? session.getAttribute("loginUserID").toString() : "");
  if (rsLoginUser == null) rsLoginUser = "";
  if (rsLoginRoles == null) rsLoginRoles = "";
  if (rsDispName == null || rsDispName.length() == 0) rsDispName = "User";
  if (rsEntityID == null || rsEntityID.length() == 0) rsEntityID = "1";
  request.setAttribute("loginUser", rsLoginUser);
  request.setAttribute("loginUserRoles", rsLoginRoles);
  request.setAttribute("entityID", rsEntityID);
  request.setAttribute("loginUserDisplayName", rsDispName);
  request.setAttribute("loginUserID", rsLoginUserID);
  request.setAttribute("shellNoForm", "yes");
  request.setAttribute("hideTopbarSearch", "yes");
%>
<jsp:useBean id="_recordBean" class="com.beans.SearchBean" scope="request" />
<%
  _recordBean.setController("RoadsideAssistance");
  _recordBean.setDisplayName("Roadside & Fuel");
  int submitType = SubmitType.SEARCH;
%>
<!DOCTYPE html>
<html lang="en">
<%@ include file="includeHeader.jsp"%>
<%@ include file="includeRoadsideMapBody.jsp"%>
<%@ include file="includeFooter.jsp"%>
