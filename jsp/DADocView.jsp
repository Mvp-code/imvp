<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"
         import="java.sql.*,javax.sql.*,javax.naming.*,java.io.*,java.nio.file.*,javax.servlet.http.HttpServletResponse" %>
<%!
  private String mimeFor(String fileName) {
    String lower = fileName == null ? "" : fileName.toLowerCase();
    if (lower.endsWith(".jpg") || lower.endsWith(".jpeg")) return "image/jpeg";
    if (lower.endsWith(".png"))  return "image/png";
    if (lower.endsWith(".webp")) return "image/webp";
    if (lower.endsWith(".pdf"))  return "application/pdf";
    return "application/octet-stream";
  }
%>
<%
  String loginUser = "";
  if (request.getAttribute("loginUser") != null) {
    loginUser = request.getAttribute("loginUser").toString().trim();
  } else if (session.getAttribute("loginUser") != null) {
    loginUser = session.getAttribute("loginUser").toString().trim();
  }
  if (loginUser.isEmpty()) {
    response.sendError(HttpServletResponse.SC_FORBIDDEN, "Login required");
    return;
  }

  String appId = request.getParameter("appId");
  String doc   = request.getParameter("doc");
  if (appId == null || doc == null) {
    response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Missing parameters");
    return;
  }

  String colLocal = null;
  String colDrive = null;
  boolean fromOnboarding = false;
  if ("dl".equals(doc)) { colLocal = "dl_file_path"; colDrive = "dl_drive_url"; }
  else if ("ssn".equals(doc)) { colLocal = "ssn_file_path"; colDrive = "ssn_drive_url"; }
  else if ("wp_front".equals(doc)) { colLocal = "wp_front_file_path"; colDrive = "wp_front_drive_url"; }
  else if ("wp_back".equals(doc)) { colLocal = "wp_back_file_path"; colDrive = "wp_back_drive_url"; }
  else if ("drug_test".equals(doc)) { fromOnboarding = true; }
  else {
    response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid document type");
    return;
  }

  String localPath = "";
  String driveUrl  = "";
  Connection conn = null;
  try {
    Context ctx = new InitialContext();
    DataSource ds = (DataSource) ctx.lookup("java:comp/env/jdbc/MVPGDB");
    conn = ds.getConnection();
    if (fromOnboarding) {
      PreparedStatement ps = conn.prepareStatement(
        "SELECT IFNULL(drug_test_doc_path,'') FROM da_onboarding WHERE application_id=? ORDER BY onboarding_id DESC LIMIT 1");
      ps.setLong(1, Long.parseLong(appId));
      ResultSet rs = ps.executeQuery();
      if (rs.next()) {
        localPath = rs.getString(1) == null ? "" : rs.getString(1).trim();
      }
      rs.close(); ps.close();
    } else {
      PreparedStatement ps = conn.prepareStatement(
        "SELECT " + colLocal + ", " + colDrive + " FROM da_applications WHERE application_id=?");
      ps.setLong(1, Long.parseLong(appId));
      ResultSet rs = ps.executeQuery();
      if (rs.next()) {
        localPath = rs.getString(1) == null ? "" : rs.getString(1).trim();
        driveUrl  = rs.getString(2) == null ? "" : rs.getString(2).trim();
      }
      rs.close(); ps.close();
    }
  } catch (Exception ex) {
    response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, ex.getMessage());
    return;
  } finally {
    if (conn != null) try { conn.close(); } catch (Exception e) {}
  }

  if (!driveUrl.isEmpty()) {
    response.sendRedirect(driveUrl);
    return;
  }
  if (localPath.isEmpty()) {
    response.sendError(HttpServletResponse.SC_NOT_FOUND, "Document not found");
    return;
  }

  File f = new File(localPath);
  if (!f.isFile()) {
    response.sendError(HttpServletResponse.SC_NOT_FOUND, "File missing on server");
    return;
  }

  String mime = mimeFor(f.getName());
  response.reset();
  response.setContentType(mime);
  response.setHeader("Content-Disposition", "inline; filename=\"" + f.getName() + "\"");
  response.setContentLength((int) f.length());

  FileInputStream in = null;
  OutputStream os = null;
  try {
    in = new FileInputStream(f);
    os = response.getOutputStream();
    byte[] buf = new byte[8192];
    int n;
    while ((n = in.read(buf)) > 0) os.write(buf, 0, n);
    os.flush();
  } finally {
    if (in != null) try { in.close(); } catch (Exception e) {}
  }
%>
