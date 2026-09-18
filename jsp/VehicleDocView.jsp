<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"
         import="java.sql.*,javax.sql.*,javax.naming.*,java.io.*,java.util.Calendar,javax.servlet.http.HttpServletResponse,com.tools.ServerUploadPaths" %>
<%!
  private String mimeFor(String fileName) {
    String lower = fileName == null ? "" : fileName.toLowerCase();
    if (lower.endsWith(".jpg") || lower.endsWith(".jpeg") || lower.endsWith(".jfif")) return "image/jpeg";
    if (lower.endsWith(".png"))  return "image/png";
    if (lower.endsWith(".gif"))  return "image/gif";
    if (lower.endsWith(".webp")) return "image/webp";
    if (lower.endsWith(".heic") || lower.endsWith(".heif")) return "image/heic";
    if (lower.endsWith(".pdf"))  return "application/pdf";
    return "application/octet-stream";
  }
  private String nvl(String s) { return s == null ? "" : s.trim(); }
%>
<%
  String loginUser = "";
  if (request.getAttribute("loginUser") != null)
    loginUser = request.getAttribute("loginUser").toString().trim();
  else if (session.getAttribute("loginUser") != null)
    loginUser = session.getAttribute("loginUser").toString().trim();
  if (loginUser.isEmpty()) {
    response.sendError(HttpServletResponse.SC_FORBIDDEN, "Login required");
    return;
  }

  String entityID = "";
  if (request.getAttribute("entityID") != null)
    entityID = request.getAttribute("entityID").toString().trim();
  else if (session.getAttribute("entityID") != null)
    entityID = session.getAttribute("entityID").toString().trim();
  if (entityID.length() == 0) entityID = "1";

  String kind = nvl(request.getParameter("kind")).toLowerCase();
  String id = nvl(request.getParameter("id"));
  String reqPath = nvl(request.getParameter("path"));
  File file = null;

  if ("ins".equals(kind)) {
    file = ServerUploadPaths.findInsuranceFile(Calendar.getInstance().get(Calendar.YEAR));
  } else if ("file".equals(kind) && reqPath.length() > 0) {
    String p = reqPath.replace('\\', '/');
    if (p.indexOf("..") >= 0) {
      response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Bad path");
      return;
    }
    file = ServerUploadPaths.resolveStoredFile(p);
  } else if (("reg".equals(kind) || "ro".equals(kind) || "oil".equals(kind)) && id.matches("\\d+")) {
    Connection conn = null;
    try {
      Context ctx = new InitialContext();
      DataSource ds = (DataSource) ctx.lookup("java:comp/env/jdbc/MVPGDB");
      conn = ds.getConnection();
      String stored = "";
      PreparedStatement ps = conn.prepareStatement(
        "SELECT IFNULL(REGISTRATION_PDF,''), IFNULL(RO_PDF,''), IFNULL(OIL_PDF,'') "
        + "FROM VEHICLE WHERE VEHICLEID=? AND ENTITYID=? AND STATUS<>1");
      ps.setLong(1, Long.parseLong(id));
      ps.setLong(2, Long.parseLong(entityID));
      ResultSet rs = ps.executeQuery();
      if (rs.next()) {
        if ("reg".equals(kind)) stored = nvl(rs.getString(1));
        else if ("ro".equals(kind)) stored = nvl(rs.getString(2));
        else stored = nvl(rs.getString(3));
      }
      rs.close(); ps.close();
      if ("oil".equals(kind) && stored.length() == 0) {
        PreparedStatement ps2 = conn.prepareStatement(
          "SELECT L.OIL_PDF FROM vehicle_maintenance_log L "
          + "WHERE L.VEHICLEID=? AND IFNULL(L.OIL_PDF,'')<>'' "
          + "ORDER BY L.MAINT_LOGID DESC LIMIT 1");
        ps2.setLong(1, Long.parseLong(id));
        ResultSet rs2 = ps2.executeQuery();
        if (rs2.next()) stored = nvl(rs2.getString(1));
        rs2.close(); ps2.close();
      }
      if (stored.length() > 0) file = ServerUploadPaths.resolveStoredFile(stored);
    } catch (Exception ex) {
      response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Could not load document");
      return;
    } finally {
      if (conn != null) try { conn.close(); } catch (Exception e) {}
    }
  } else {
    response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Missing document");
    return;
  }

  if (file == null || !ServerUploadPaths.isAllowedFile(file)) {
    response.sendError(HttpServletResponse.SC_NOT_FOUND, "Document not found");
    return;
  }

  String mime = mimeFor(file.getName());
  response.reset();
  response.setContentType(mime);
  response.setHeader("Content-Disposition", "inline; filename=\"" + file.getName().replace("\"", "") + "\"");
  response.setContentLength((int) file.length());

  FileInputStream in = null;
  OutputStream os = null;
  try {
    in = new FileInputStream(file);
    os = response.getOutputStream();
    byte[] buf = new byte[8192];
    int n;
    while ((n = in.read(buf)) > 0) os.write(buf, 0, n);
    os.flush();
  } finally {
    if (in != null) try { in.close(); } catch (Exception e) {}
  }
%>
