<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%--
  Standalone Roadside & Fuel map — no MVPx menu.
  Copy this file plus jsp/assets/roadside/ onto the server. Do not copy includeHeader.jsp.
  Open after login: /MVPx/jsp/RoadsideMap.jsp
--%>
<%
  String rsLoginUser = session.getAttribute("loginUser") != null ? session.getAttribute("loginUser").toString() : "";
  String rsDispName  = session.getAttribute("loginUserDisplayName") != null ? session.getAttribute("loginUserDisplayName").toString() : "";
  if (rsLoginUser.length() == 0) {
    if (!response.isCommitted())
      response.sendRedirect(request.getContextPath() + "/jsp/login.jsp");
    return;
  }
  if (rsDispName.length() == 0) rsDispName = rsLoginUser;
  String ctx = request.getContextPath();
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Roadside &amp; Fuel</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700;800&display=swap">
  <style>
    html,body{height:100%;margin:0}
    body.rs-solo{font-family:Inter,system-ui,Segoe UI,sans-serif;background:#F1F5F9;color:#0F172A}
    .rs-solo-bar{height:48px;display:flex;align-items:center;justify-content:space-between;padding:0 14px;background:#0f172a;color:#fff;flex-shrink:0}
    .rs-solo-bar b{font-size:14px;letter-spacing:-.02em}
    .rs-solo-bar span{font-size:12px;opacity:.8}
    .rs-solo-bar a{color:#fff;text-decoration:none;font-size:12px;font-weight:600;border:1px solid rgba(255,255,255,.25);border-radius:7px;padding:5px 10px}
  </style>
</head>
<body class="rs-solo">
  <div class="rs-solo-bar">
    <b>Roadside &amp; Fuel</b>
    <span><%= rsDispName.replace("<","&lt;").replace(">","&gt;") %> &nbsp; <a href="<%=ctx%>/">App</a></span>
  </div>
<%@ include file="includeRoadsideMapBody.jsp"%>
</body>
</html>
