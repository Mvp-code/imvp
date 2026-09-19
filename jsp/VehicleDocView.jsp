<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"
         import="java.sql.*,javax.sql.*,javax.naming.*,java.io.*,java.util.Calendar" %>
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

  private File docsDir(ServletContext app) {
    try {
      String rp = app.getRealPath("/docs");
      if (rp != null && rp.length() > 0) return new File(rp);
    } catch (Exception ignore) {}
    return new File("docs");
  }

  private File[] searchRoots(ServletContext app) {
    return new File[] {
      docsDir(app),
      new File(docsDir(app), "serverUpload"),
      new File("F:\\JavProject\\serverUpload"),
      new File("C:\\JavProject\\serverUpload")
    };
  }

  private boolean under(File file, File root) {
    if (file == null || root == null) return false;
    try {
      String c = file.getCanonicalPath();
      String r = root.getCanonicalPath();
      if (c.equalsIgnoreCase(r)) return true;
      String prefix = r.endsWith("\\") || r.endsWith("/") ? r : r + File.separator;
      return c.length() > prefix.length()
          && c.regionMatches(true, 0, prefix, 0, prefix.length());
    } catch (Exception e) {
      return false;
    }
  }

  private boolean allowed(File f, ServletContext app) {
    if (f == null || !f.isFile()) return false;
    File[] roots = searchRoots(app);
    for (int i = 0; i < roots.length; i++) {
      if (under(f, roots[i])) return true;
    }
    try {
      String web = app.getRealPath("/");
      if (web != null && under(f, new File(web))) return true;
    } catch (Exception ignore) {}
    return false;
  }

  private File resolveStored(ServletContext app, String storedPath) {
    if (storedPath == null) return null;
    String raw = storedPath.trim();
    if (raw.length() == 0) return null;
    File abs = new File(raw);
    if (abs.isAbsolute() && allowed(abs, app)) return abs;
    String p = raw.replace('\\', '/');
    while (p.startsWith("../")) p = p.substring(3);
    while (p.startsWith("./")) p = p.substring(2);
    if (p.startsWith("/")) p = p.substring(1);
    if (p.indexOf("..") >= 0) return null;
    if (p.length() == 0) return null;
    String rest = p.startsWith("docs/") ? p.substring(5) : p;
    File inDocs = new File(docsDir(app), rest.replace('/', File.separatorChar));
    if (allowed(inDocs, app)) return inDocs;
    String underSu = rest.startsWith("serverUpload/")
        ? rest.substring("serverUpload/".length()) : rest;
    File[] roots = searchRoots(app);
    for (int i = 0; i < roots.length; i++) {
      File cand = new File(roots[i], underSu.replace('/', File.separatorChar));
      if (allowed(cand, app)) return cand;
      cand = new File(roots[i], rest.replace('/', File.separatorChar));
      if (allowed(cand, app)) return cand;
    }
    try {
      String web = app.getRealPath("/");
      if (web != null) {
        File webFile = new File(web, p.replace('/', File.separatorChar));
        if (allowed(webFile, app)) return webFile;
      }
    } catch (Exception ignore) {}
    return null;
  }

  private File findInsurance(ServletContext app, int year) {
    String y = String.valueOf(year);
    String[] prefixes = new String[] { "autoinsurance_" + y, "insurance_" + y };
    File[] dirs = new File[] {
      new File(docsDir(app), "serverUpload" + File.separator + "Insurance"),
      new File("F:\\JavProject\\serverUpload\\Insurance"),
      new File("C:\\JavProject\\serverUpload\\Insurance")
    };
    for (int d = 0; d < dirs.length; d++) {
      File[] list = dirs[d].listFiles();
      if (list == null) continue;
      for (int i = 0; i < list.length; i++) {
        File f = list[i];
        if (f == null || !f.isFile()) continue;
        String n = f.getName().toLowerCase();
        for (int p = 0; p < prefixes.length; p++) {
          if (n.startsWith(prefixes[p] + ".") || n.equals(prefixes[p]))
            return f;
        }
      }
    }
    return null;
  }
%>
<%
  /* Always 200 — UAT IIS turns sendError / 403 / 404 into a blank or generic failure. */
  String loginUser = "";
  if (request.getAttribute("loginUser") != null)
    loginUser = request.getAttribute("loginUser").toString().trim();
  else if (session.getAttribute("loginUser") != null)
    loginUser = session.getAttribute("loginUser").toString().trim();
  if (loginUser.isEmpty()) {
    response.setStatus(200);
    response.setContentType("text/html; charset=UTF-8");
%>
<!DOCTYPE html><html><body style="font-family:sans-serif;padding:24px">
<p>Login required to view this document. Open Vehicles from the menu after you sign in.</p>
</body></html>
<%
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
  String fail = "";
  ServletContext app = application;

  try {
    if ("ins".equals(kind)) {
      file = findInsurance(app, Calendar.getInstance().get(Calendar.YEAR));
    } else if ("file".equals(kind) && reqPath.length() > 0) {
      if (reqPath.indexOf("..") >= 0) fail = "Bad path";
      else file = resolveStored(app, reqPath);
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
        if (stored.length() > 0) file = resolveStored(app, stored);
        else fail = "No document on file for this vehicle";
      } finally {
        if (conn != null) try { conn.close(); } catch (Exception e) {}
      }
    } else {
      fail = "Missing document";
    }
  } catch (Exception ex) {
    fail = "Could not load document";
  }

  if (fail.length() == 0 && (file == null || !allowed(file, app)))
    fail = "Document not found on the server. Upload it again, then view.";

  if (fail.length() > 0) {
    response.setStatus(200);
    response.setContentType("text/html; charset=UTF-8");
%>
<!DOCTYPE html><html><body style="font-family:sans-serif;padding:24px">
<p><%= fail %></p>
</body></html>
<%
    return;
  }

  String mime = mimeFor(file.getName());
  response.setContentType(mime);
  response.setHeader("Content-Disposition", "inline; filename=\"" + file.getName().replace("\"", "") + "\"");
  if (file.length() <= Integer.MAX_VALUE)
    response.setContentLength((int) file.length());

  FileInputStream in = null;
  try {
    in = new FileInputStream(file);
    OutputStream os = response.getOutputStream();
    byte[] buf = new byte[8192];
    int n;
    while ((n = in.read(buf)) > 0) os.write(buf, 0, n);
    os.flush();
  } finally {
    if (in != null) try { in.close(); } catch (Exception e) {}
  }
%>
