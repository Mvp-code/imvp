<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"
         import="java.sql.*,javax.naming.*,javax.sql.*,java.util.*" %>
<%!
  private Connection getConn() throws Exception {
    Context ctx = new InitialContext();
    DataSource ds = (DataSource) ctx.lookup("java:comp/env/jdbc/MVPGDB");
    return ds.getConnection();
  }
  private String gp(javax.servlet.http.HttpServletRequest r, String k) {
    String v = r.getParameter(k); return (v == null) ? "" : v.trim();
  }
  private String esc(String s) {
    if (s == null) return "";
    return s.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("'","&#39;");
  }
%>
<%
  String loginUser = (request.getAttribute("loginUser") != null) ? request.getAttribute("loginUser").toString()
                   : (session.getAttribute("loginUser") != null ? session.getAttribute("loginUser").toString() : "");
  String entityID  = (request.getAttribute("entityID") != null) ? request.getAttribute("entityID").toString()
                   : (session.getAttribute("entityID") != null ? session.getAttribute("entityID").toString() : "1");
  if (loginUser == null || loginUser.isEmpty()) {
    response.sendRedirect("../servlet/MVPGServlet?submitType=11&controller=Login");
    return;
  }
  int eid = 1;
  try { eid = Integer.parseInt(entityID); } catch (Exception ex) {}

  String saveMsg = null; boolean saveOk = false;

  /* ── POST: update a config value ── */
  if ("POST".equalsIgnoreCase(request.getMethod())) {
    String configId = gp(request, "config_id");
    String newVal   = gp(request, "config_value");
    String newLabel = gp(request, "config_label");
    String newDesc  = gp(request, "config_desc");
    Connection wc = null;
    try {
      wc = getConn();
      PreparedStatement ps = wc.prepareStatement(
        "UPDATE mvpg_config SET config_value=?, config_label=?, config_desc=?, UPDATE_USER=? " +
        "WHERE config_id=? AND entity_id=?");
      ps.setString(1, newVal); ps.setString(2, newLabel); ps.setString(3, newDesc);
      ps.setString(4, loginUser); ps.setInt(5, Integer.parseInt(configId)); ps.setInt(6, eid);
      ps.executeUpdate(); ps.close();
      saveMsg = "Configuration saved successfully."; saveOk = true;
    } catch (Exception ex) {
      saveMsg = "Save failed: " + ex.getMessage();
    } finally { if (wc != null) try { wc.close(); } catch (Exception e) {} }
  }

  /* ── Load all configs ── */
  List<Map<String,String>> configs = new ArrayList<Map<String,String>>();
  List<String> groups = new ArrayList<String>();
  Connection conn = null;
  try {
    conn = getConn();
    PreparedStatement ps = conn.prepareStatement(
      "SELECT config_id, config_group, config_key, config_label, config_value, config_desc, is_active, UPDATE_USER, UPDATE_DATE " +
      "FROM mvpg_config WHERE entity_id=? ORDER BY config_group, config_id");
    ps.setInt(1, eid);
    ResultSet rs = ps.executeQuery();
    while (rs.next()) {
      Map<String,String> row = new LinkedHashMap<String,String>();
      row.put("id",       rs.getString("config_id"));
      row.put("group",    rs.getString("config_group"));
      row.put("key",      rs.getString("config_key"));
      row.put("label",    rs.getString("config_label") == null ? "" : rs.getString("config_label"));
      row.put("value",    rs.getString("config_value") == null ? "" : rs.getString("config_value"));
      row.put("desc",     rs.getString("config_desc")  == null ? "" : rs.getString("config_desc"));
      row.put("active",   rs.getString("is_active")    == null ? "Y" : rs.getString("is_active"));
      row.put("updated_by", rs.getString("UPDATE_USER") == null ? "" : rs.getString("UPDATE_USER"));
      row.put("updated_at", rs.getString("UPDATE_DATE") == null ? "" : rs.getString("UPDATE_DATE"));
      configs.add(row);
      if (!groups.contains(rs.getString("config_group"))) groups.add(rs.getString("config_group"));
    }
    rs.close(); ps.close();
  } catch (Exception ex) {
    saveMsg = "DB error: " + ex.getMessage(); saveOk = false;
  } finally { if (conn != null) try { conn.close(); } catch (Exception e) {} }
%><!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8"/>
<meta name="viewport" content="width=device-width,initial-scale=1.0"/>
<title>MVPx &mdash; Configuration</title>
<link rel="stylesheet" href="../jsp/assets/css/mvpx.css">
<style>
body { font-family: -apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif; background:#f8fafc; margin:0; }
.cfg-shell { max-width:900px; margin:0 auto; padding:32px 24px; }
.cfg-hdr { display:flex; justify-content:space-between; align-items:center; margin-bottom:24px; flex-wrap:wrap; gap:12px; }
.cfg-hdr h1 { font-size:20px; font-weight:900; color:#0f172a; margin:0; }
.cfg-hdr p  { font-size:12px; color:#94a3b8; margin:3px 0 0; }
.cfg-group  { margin-bottom:28px; }
.cfg-group-title { font-size:10px; font-weight:800; color:#64748b; text-transform:uppercase; letter-spacing:.6px;
                    padding:8px 0 6px; border-bottom:2px solid #e2e8f0; margin-bottom:0; }
.cfg-table  { width:100%; border-collapse:collapse; background:#fff; border:1px solid #e2e8f0; border-radius:12px; overflow:hidden; font-size:13px; }
.cfg-table th { background:#f8fafc; padding:9px 14px; text-align:left; font-size:10px; font-weight:700;
                 color:#64748b; text-transform:uppercase; letter-spacing:.4px; border-bottom:1px solid #e2e8f0; }
.cfg-table td { padding:10px 14px; border-bottom:1px solid #f1f5f9; vertical-align:middle; }
.cfg-table tr:last-child td { border-bottom:none; }
.cfg-table tr:hover td { background:#fafbfc; }
.cfg-key   { font-family:monospace; font-size:11px; color:#7c3aed; background:#ede9fe; padding:2px 6px; border-radius:4px; }
.cfg-val   { width:200px; padding:6px 9px; border:1px solid #d1d5db; border-radius:6px; font-size:13px; font-family:inherit; color:#1e293b; }
.cfg-val:focus { outline:2px solid #2563eb; border-color:#2563eb; }
.cfg-desc  { font-size:11px; color:#94a3b8; margin-top:3px; }
.cfg-meta  { font-size:10px; color:#cbd5e1; }
.btn-save  { padding:5px 14px; background:#2563eb; color:#fff; border:none; border-radius:6px; font-size:12px; font-weight:700; cursor:pointer; }
.btn-save:hover { background:#1d4ed8; }
.flash-ok  { background:#dcfce7; border:1px solid #86efac; border-radius:8px; padding:11px 18px; font-size:13px; color:#15803d; margin-bottom:20px; font-weight:600; }
.flash-err { background:#fee2e2; border:1px solid #fca5a5; border-radius:8px; padding:11px 18px; font-size:13px; color:#b91c1c; margin-bottom:20px; font-weight:600; }
</style>
</head>
<body>
<div class="cfg-shell">
  <div class="cfg-hdr">
    <div>
      <h1>&#9881; System Configuration</h1>
      <p>Manage MVPx tunables for DNK7 &mdash; changes take effect immediately on next page load</p>
    </div>
    <a href="DAOnboarding.jsp" style="padding:7px 14px;background:#0f172a;color:#fff;border-radius:7px;font-size:12px;font-weight:700;text-decoration:none;">
      &#8592; Back to Pipeline
    </a>
  </div>

  <% if (saveMsg != null) { %>
  <div class="<%=saveOk?"flash-ok":"flash-err"%>"><%=esc(saveMsg)%></div>
  <% } %>

  <% for (String grp : groups) { %>
  <div class="cfg-group">
    <div class="cfg-group-title"><%=esc(grp)%></div>
    <table class="cfg-table">
      <thead>
        <tr>
          <th style="width:180px;">Setting</th>
          <th style="width:120px;">Key</th>
          <th>Value</th>
          <th>Description</th>
          <th style="width:80px;">Last Updated</th>
          <th style="width:70px;"></th>
        </tr>
      </thead>
      <tbody>
      <% for (Map<String,String> c : configs) {
           if (!grp.equals(c.get("group"))) continue;
      %>
        <tr>
          <form method="POST" action="MVPGConfig.jsp">
            <input type="hidden" name="config_id" value="<%=esc(c.get("id"))%>">
            <td>
              <input type="text" name="config_label" class="cfg-val" style="width:160px;" value="<%=esc(c.get("label"))%>">
            </td>
            <td><span class="cfg-key"><%=esc(c.get("key"))%></span></td>
            <td>
              <input type="text" name="config_value" class="cfg-val" value="<%=esc(c.get("value"))%>">
            </td>
            <td>
              <input type="text" name="config_desc" class="cfg-val" style="width:100%;box-sizing:border-box;" value="<%=esc(c.get("desc"))%>">
            </td>
            <td class="cfg-meta">
              <% String upAt = c.get("updated_at"); if (upAt.length() >= 10) upAt = upAt.substring(5,10); %>
              <%=esc(upAt)%><br><%=esc(c.get("updated_by"))%>
            </td>
            <td>
              <button type="submit" class="btn-save">Save</button>
            </td>
          </form>
        </tr>
      <% } %>
      </tbody>
    </table>
  </div>
  <% } %>

  <% if (configs.isEmpty()) { %>
  <div style="background:#fff;border:1px solid #e2e8f0;border-radius:12px;padding:48px;text-align:center;color:#94a3b8;font-size:14px;">
    No configuration entries found. Check that the <code>mvpg_config</code> table exists and has rows for entity_id=<%=eid%>.
  </div>
  <% } %>
</div>
</body>
</html>
