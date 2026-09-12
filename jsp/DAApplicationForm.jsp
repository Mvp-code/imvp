<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"
         import="java.sql.*,javax.sql.*,javax.naming.*,java.net.*,java.io.*,java.util.*,
                 org.apache.commons.fileupload.servlet.ServletFileUpload,
                 org.apache.commons.fileupload.disk.DiskFileItemFactory,
                 org.apache.commons.fileupload.FileItem,
                 org.apache.commons.io.FilenameUtils" %>
<%!
  private static final String DOC_UPLOAD_BASE = "F:/JavProject/serverUpload/DAApplications";
  private static final long   DOC_MAX_BYTES   = 10L * 1024L * 1024L;
  private static final Set<String> DOC_EXTS = new HashSet<String>(
      Arrays.asList(".jpg", ".jpeg", ".png", ".webp", ".pdf"));

  private Connection getConn() throws Exception {
    Context ctx = new InitialContext();
    DataSource ds = (DataSource) ctx.lookup("java:comp/env/jdbc/MVPGDB");
    return ds.getConnection();
  }

  private String esc(String s) {
    if (s == null) return "";
    return s.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("'","&#39;");
  }

  private String safe(String s) { return s == null ? "" : s.trim(); }

  /** Folder-safe segment: letters/digits only, spaces -> underscore */
  private String folderPart(String s) {
    String t = safe(s).replaceAll("[\\\\/:*?\"<>|]+", " ").replaceAll("\\s+", "_");
    t = t.replaceAll("[^A-Za-z0-9_\\-]+", "");
    while (t.startsWith("_")) t = t.substring(1);
    while (t.endsWith("_")) t = t.substring(0, t.length() - 1);
    return t;
  }

  private String appUploadFolderName(long appId, String firstName, String lastName) {
    String fn = folderPart(firstName);
    String ln = folderPart(lastName);
    StringBuilder sb = new StringBuilder();
    sb.append(appId);
    if (fn.length() > 0) sb.append("_").append(fn);
    if (ln.length() > 0) sb.append("_").append(ln);
    return sb.toString();
  }

  private boolean sendTwilioSMS(String toPhone, String body) {
    try {
      /* credentials from Admin Configuration — never hardcode SID/token in source */
      com.dataobjects.AdminConfigurationDAO cfg = new com.dataobjects.AdminConfigurationDAO();
      java.util.Properties prop = new java.util.Properties();
      String sid = cfg.getPropertyValue(
          com.beans.AdminConfiguration.enumSMS.TwilioAccountSID.toString(), prop);
      String token = cfg.getPropertyValue(
          com.beans.AdminConfiguration.enumSMS.TwilioAuthToken.toString(), prop);
      String from = cfg.getPropertyValue(
          com.beans.AdminConfiguration.enumSMS.TwilioPrimaryNum.toString(), prop);
      if (sid == null) sid = "";
      if (token == null) token = "";
      if (from == null || from.length() == 0) from = "+17249996874";
      if (sid.length() == 0 || token.length() == 0) return false;

      String phone = toPhone.replaceAll("[^+0-9]","");
      if (!phone.startsWith("+")) phone = "+1" + phone;

      String authStr = sid + ":" + token;
      String encoded = Base64.getEncoder().encodeToString(authStr.getBytes("UTF-8"));

      String params = "To="   + URLEncoder.encode(phone, "UTF-8")
                    + "&From=" + URLEncoder.encode(from,  "UTF-8")
                    + "&Body=" + URLEncoder.encode(body,  "UTF-8");

      URL url = new URL("https://api.twilio.com/2010-04-01/Accounts/" + sid + "/Messages.json");
      HttpURLConnection conn = (HttpURLConnection) url.openConnection();
      conn.setRequestMethod("POST");
      conn.setRequestProperty("Authorization", "Basic " + encoded);
      conn.setRequestProperty("Content-Type", "application/x-www-form-urlencoded");
      conn.setDoOutput(true);
      conn.getOutputStream().write(params.getBytes("UTF-8"));
      int rc = conn.getResponseCode();
      return rc == 200 || rc == 201;
    } catch (Exception ex) {
      System.out.println("DAApplicationForm.sendTwilioSMS error: " + ex.getMessage());
      return false;
    }
  }

  private long insertApplication(String firstName, String lastName, String email,
      String phone, String availType,
      boolean sun, boolean mon, boolean tue, boolean wed,
      boolean thu, boolean fri, boolean sat,
      boolean hasDL, boolean hasSSN, boolean hasWorkAuth,
      boolean hasAmazonExp, boolean hasAmazonAcct,
      String entityID) throws Exception {

    Connection conn = null;
    try {
      conn = getConn();
      String sql =
        "INSERT INTO da_applications " +
        "(first_name,last_name,email,phone,avail_type," +
        " avail_sun,avail_mon,avail_tue,avail_wed,avail_thu,avail_fri,avail_sat," +
        " has_dl,has_ssn,has_work_auth,has_amazon_exp,has_amazon_acct," +
        " app_status,entity_id,station,CREATE_USER,UPDATE_USER) " +
        "VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,'PENDING',?,'DNK7','APPLICANT','APPLICANT')";

      PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS);
      ps.setString(1,  firstName);
      ps.setString(2,  lastName);
      ps.setString(3,  email);
      ps.setString(4,  phone);
      ps.setString(5,  availType);
      ps.setBoolean(6,  sun);
      ps.setBoolean(7,  mon);
      ps.setBoolean(8,  tue);
      ps.setBoolean(9,  wed);
      ps.setBoolean(10, thu);
      ps.setBoolean(11, fri);
      ps.setBoolean(12, sat);
      ps.setBoolean(13, hasDL);
      ps.setBoolean(14, hasSSN);
      ps.setBoolean(15, hasWorkAuth);
      ps.setBoolean(16, hasAmazonExp);
      ps.setBoolean(17, hasAmazonAcct);
      ps.setInt(18, Integer.parseInt(entityID.isEmpty() ? "1" : entityID));
      ps.executeUpdate();

      ResultSet keys = ps.getGeneratedKeys();
      long newId = keys.next() ? keys.getLong(1) : -1;
      keys.close(); ps.close();
      return newId;
    } finally {
      if (conn != null) try { conn.close(); } catch (Exception e) {}
    }
  }

  private void ensureDocColumns(Connection conn) {
    String[] alters = {
      "ALTER TABLE da_applications ADD COLUMN dl_file_path VARCHAR(500) NULL",
      "ALTER TABLE da_applications ADD COLUMN ssn_file_path VARCHAR(500) NULL",
      "ALTER TABLE da_applications ADD COLUMN wp_front_file_path VARCHAR(500) NULL",
      "ALTER TABLE da_applications ADD COLUMN wp_back_file_path VARCHAR(500) NULL",
      "ALTER TABLE da_applications ADD COLUMN dl_drive_url VARCHAR(500) NULL",
      "ALTER TABLE da_applications ADD COLUMN ssn_drive_url VARCHAR(500) NULL",
      "ALTER TABLE da_applications ADD COLUMN wp_front_drive_url VARCHAR(500) NULL",
      "ALTER TABLE da_applications ADD COLUMN wp_back_drive_url VARCHAR(500) NULL"
    };
    for (String sql : alters) {
      try {
        Statement st = conn.createStatement();
        st.executeUpdate(sql);
        st.close();
      } catch (Exception ignore) { /* column already exists */ }
    }
  }

  private void updateDocPaths(long appId, String dl, String ssn, String wpFront, String wpBack,
      String dlDrive, String ssnDrive, String wpFrontDrive, String wpBackDrive) throws Exception {
    Connection conn = null;
    try {
      conn = getConn();
      ensureDocColumns(conn);
      PreparedStatement ps = conn.prepareStatement(
        "UPDATE da_applications SET dl_file_path=?, ssn_file_path=?, wp_front_file_path=?, wp_back_file_path=?, " +
        "dl_drive_url=?, ssn_drive_url=?, wp_front_drive_url=?, wp_back_drive_url=? WHERE application_id=?");
      ps.setString(1, dl);
      ps.setString(2, ssn);
      ps.setString(3, wpFront);
      ps.setString(4, wpBack);
      ps.setString(5, dlDrive);
      ps.setString(6, ssnDrive);
      ps.setString(7, wpFrontDrive);
      ps.setString(8, wpBackDrive);
      ps.setLong(9, appId);
      ps.executeUpdate();
      ps.close();
    } finally {
      if (conn != null) try { conn.close(); } catch (Exception e) {}
    }
  }

  private String uploadToDriveIfConfigured(File localFile, String driveName) {
    try {
      Class<?> cls = Class.forName("com.tools.GoogleDriveUploader");
      java.lang.reflect.Method m = cls.getMethod("upload", File.class, String.class, String.class);
      Object url = m.invoke(null, localFile, driveName, null);
      return url == null ? null : url.toString();
    } catch (Throwable ex) {
      return null;
    }
  }

  private boolean isDriveUploadEnabled() {
    try {
      Class<?> cls = Class.forName("com.tools.GoogleDriveUploader");
      java.lang.reflect.Method m = cls.getMethod("isConfigured");
      Object v = m.invoke(null);
      return v instanceof Boolean && ((Boolean) v).booleanValue();
    } catch (Throwable ex) {
      return false;
    }
  }

  private Map<String, String> parseMultipartFields(HttpServletRequest req,
      Map<String, FileItem> files) throws Exception {
    Map<String, String> fields = new HashMap<String, String>();
    if (!ServletFileUpload.isMultipartContent(req)) return fields;

    File tmpDir = new File("F:/JavProject/localUpload");
    if (!tmpDir.isDirectory()) tmpDir.mkdirs();

    DiskFileItemFactory factory = new DiskFileItemFactory();
    factory.setSizeThreshold(1024 * 1024);
    factory.setRepository(tmpDir);

    ServletFileUpload upload = new ServletFileUpload(factory);
    upload.setFileSizeMax(DOC_MAX_BYTES);
    upload.setSizeMax(DOC_MAX_BYTES * 5);

    List<?> items = upload.parseRequest(req);
    for (Object obj : items) {
      FileItem item = (FileItem) obj;
      if (item.isFormField()) {
        fields.put(item.getFieldName(), item.getString("UTF-8"));
      } else if (item.getName() != null && item.getName().trim().length() > 0) {
        files.put(item.getFieldName(), item);
      }
    }
    return fields;
  }

  private String saveDocFile(FileItem item, File destDir, String baseName) throws Exception {
    String orig = FilenameUtils.getName(item.getName());
    String ext = "";
    int dot = orig.lastIndexOf('.');
    if (dot >= 0) ext = orig.substring(dot).toLowerCase();
    if (!DOC_EXTS.contains(ext)) {
      throw new Exception("Invalid file type for " + baseName + ". Use JPG, PNG, WEBP, or PDF.");
    }
    if (item.getSize() > DOC_MAX_BYTES) {
      throw new Exception(baseName + " exceeds 10 MB limit.");
    }
    File f = new File(destDir, baseName + ext);
    item.write(f);
    return f.getAbsolutePath();
  }

  private String gp(Map<String, String> fields, String key) {
    return safe(fields.get(key));
  }

  private String fieldVal(Map<String, String> fields, HttpServletRequest req, String name) {
    String v = gp(fields, name);
    if (v.isEmpty()) v = safe(req.getParameter(name));
    return v;
  }

  private boolean fieldChecked(Map<String, String> fields, HttpServletRequest req, String name) {
    return "on".equals(fieldVal(fields, req, name));
  }
%>
<%
  Map<String, String> formFields = new HashMap<String, String>();
  Map<String, FileItem> pendingFiles = new HashMap<String, FileItem>();
  String action = safe(request.getParameter("action"));

  if ("POST".equalsIgnoreCase(request.getMethod()) && ServletFileUpload.isMultipartContent(request)) {
    formFields = parseMultipartFields(request, pendingFiles);
    if (!gp(formFields, "action").isEmpty()) action = gp(formFields, "action");
  }

  String submitMsg = "";
  String submitErr = "";
  long   newAppId  = -1;

  /* ── sendSms action: dispatcher confirmed — now send both SMS messages ── */
  String smsFirstName = safe(request.getParameter("smsFirstName"));
  String smsLastName  = safe(request.getParameter("smsLastName"));
  String smsPhone     = safe(request.getParameter("smsPhone"));
  String smsAvail     = safe(request.getParameter("smsAvail"));
  String smsSent      = "";

  if ("sendSms".equals(action)) {
    String appIdStr = safe(request.getParameter("appId"));
    try {
      long aid = Long.parseLong(appIdStr);
      newAppId = aid;
      String smsBody = "Hi " + smsFirstName + ", your application to MVP Logistics (DNK7) has been received! "
          + "We will contact you within 1-2 business days. Ref #" + newAppId
          + ". Questions? Call 732-800-1594.";
      sendTwilioSMS(smsPhone, smsBody);
      String dispatchSMS = "NEW APPLICANT: " + smsFirstName + " " + smsLastName
          + " | " + smsPhone + " | " + smsAvail.replace("_"," ")
          + " | App #" + newAppId + " - Review in MVPx pipeline.";
      sendTwilioSMS("+19082960064", dispatchSMS);
      submitMsg = "success";
      smsSent   = "yes";
    } catch (Exception ex) {
      submitMsg = "success";
      smsSent   = "error:" + ex.getMessage();
    }
  }

  if ("submit".equals(action)) {
    String firstName   = gp(formFields, "firstName").isEmpty()   ? safe(request.getParameter("firstName"))   : gp(formFields, "firstName");
    String lastName    = gp(formFields, "lastName").isEmpty()    ? safe(request.getParameter("lastName"))    : gp(formFields, "lastName");
    String email       = gp(formFields, "email").isEmpty()       ? safe(request.getParameter("email"))       : gp(formFields, "email");
    String phone       = gp(formFields, "phone").isEmpty()       ? safe(request.getParameter("phone"))       : gp(formFields, "phone");
    String availType   = gp(formFields, "availType").isEmpty()   ? safe(request.getParameter("availType"))   : gp(formFields, "availType");

    boolean sun  = "on".equals(!gp(formFields, "avail_sun").isEmpty()  ? gp(formFields, "avail_sun")  : request.getParameter("avail_sun"));
    boolean mon  = "on".equals(!gp(formFields, "avail_mon").isEmpty()  ? gp(formFields, "avail_mon")  : request.getParameter("avail_mon"));
    boolean tue  = "on".equals(!gp(formFields, "avail_tue").isEmpty()  ? gp(formFields, "avail_tue")  : request.getParameter("avail_tue"));
    boolean wed  = "on".equals(!gp(formFields, "avail_wed").isEmpty()  ? gp(formFields, "avail_wed")  : request.getParameter("avail_wed"));
    boolean thu  = "on".equals(!gp(formFields, "avail_thu").isEmpty()  ? gp(formFields, "avail_thu")  : request.getParameter("avail_thu"));
    boolean fri  = "on".equals(!gp(formFields, "avail_fri").isEmpty()  ? gp(formFields, "avail_fri")  : request.getParameter("avail_fri"));
    boolean sat  = "on".equals(!gp(formFields, "avail_sat").isEmpty()  ? gp(formFields, "avail_sat")  : request.getParameter("avail_sat"));
    boolean hasDL       = "on".equals(!gp(formFields, "has_dl").isEmpty()        ? gp(formFields, "has_dl")        : request.getParameter("has_dl"));
    boolean hasSSN      = "on".equals(!gp(formFields, "has_ssn").isEmpty()       ? gp(formFields, "has_ssn")       : request.getParameter("has_ssn"));
    boolean hasWorkAuth = "on".equals(!gp(formFields, "has_work_auth").isEmpty()  ? gp(formFields, "has_work_auth")  : request.getParameter("has_work_auth"));
    boolean hasAmazonExp  = "on".equals(!gp(formFields, "has_amazon_exp").isEmpty()  ? gp(formFields, "has_amazon_exp")  : request.getParameter("has_amazon_exp"));
    boolean hasAmazonAcct = "on".equals(!gp(formFields, "has_amazon_acct").isEmpty() ? gp(formFields, "has_amazon_acct") : request.getParameter("has_amazon_acct"));

    if (firstName.isEmpty() || lastName.isEmpty() || email.isEmpty() || phone.isEmpty() || availType.isEmpty()) {
      submitErr = "Please fill in all required fields (Name, Email, Phone, Availability).";
    } else if (!pendingFiles.containsKey("doc_dl") || !pendingFiles.containsKey("doc_ssn")
            || !pendingFiles.containsKey("doc_wp_front") || !pendingFiles.containsKey("doc_wp_back")) {
      submitErr = "Please upload all 4 required documents: Driver's License, SSN, Work Permit (front), and Work Permit (back).";
    } else {
      try {
        newAppId = insertApplication(firstName, lastName, email, phone, availType,
            sun, mon, tue, wed, thu, fri, sat,
            hasDL, hasSSN, hasWorkAuth, hasAmazonExp, hasAmazonAcct, "1");

        if (newAppId > 0) {
          File destDir = new File(DOC_UPLOAD_BASE, appUploadFolderName(newAppId, firstName, lastName));
          if (!destDir.isDirectory()) destDir.mkdirs();

          String dlPath      = saveDocFile(pendingFiles.get("doc_dl"),        destDir, "drivers_license");
          String ssnPath     = saveDocFile(pendingFiles.get("doc_ssn"),       destDir, "ssn");
          String wpFrontPath = saveDocFile(pendingFiles.get("doc_wp_front"), destDir, "work_permit_front");
          String wpBackPath  = saveDocFile(pendingFiles.get("doc_wp_back"),  destDir, "work_permit_back");

          String prefix = appUploadFolderName(newAppId, firstName, lastName);
          String dlDrive      = uploadToDriveIfConfigured(new File(dlPath),      prefix + "_drivers_license");
          String ssnDrive     = uploadToDriveIfConfigured(new File(ssnPath),     prefix + "_ssn");
          String wpFrontDrive = uploadToDriveIfConfigured(new File(wpFrontPath), prefix + "_work_permit_front");
          String wpBackDrive  = uploadToDriveIfConfigured(new File(wpBackPath),  prefix + "_work_permit_back");
          updateDocPaths(newAppId, dlPath, ssnPath, wpFrontPath, wpBackPath,
              dlDrive, ssnDrive, wpFrontDrive, wpBackDrive);

          smsFirstName = firstName;
          smsLastName  = lastName;
          smsPhone     = phone;
          smsAvail     = availType;
          submitMsg = "confirm_sms";
        } else {
          submitErr = "Submission failed. Please try again or call 732-800-1594.";
        }
      } catch (Exception ex) {
        if (ex.getMessage() != null && ex.getMessage().contains("Duplicate entry")) {
          submitErr = "An application with this email already exists. Call 732-800-1594 if you need help.";
        } else {
          submitErr = "An error occurred: " + ex.getMessage();
        }
      }
    }
  }
%><!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8"/>
<meta name="viewport" content="width=device-width,initial-scale=1.0"/>
<title>MVPx &mdash; Apply to Drive with MVP Logistics</title>
<style>
:root {
  --blue:      #2563eb;
  --blue-dark: #1d4ed8;
  --navy:      #0f172a;
  --slate:     #64748b;
  --border:    #e2e8f0;
  --bg:        #f8fafc;
  --green:     #16a34a;
  --red:       #dc2626;
  --font:      'Segoe UI', Arial, sans-serif;
}
*, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
body { font-family: var(--font); background: var(--bg); color: #1e293b; font-size: 15px; line-height: 1.6; }
a { text-decoration: none; color: inherit; }

/* Topbar */
.topbar {
  background: var(--navy); height: 56px; padding: 0 5%;
  display: flex; align-items: center; justify-content: space-between;
  position: sticky; top: 0; z-index: 50;
}
.topbar-logo { display: flex; align-items: center; gap: 10px; }
.topbar-logo img { height: 36px; width: auto; }
.topbar-logo-tag { font-size: 10px; font-weight: 700; color: #94a3b8; letter-spacing: .8px; text-transform: uppercase; }
.topbar-right { display: flex; gap: 10px; }
.btn-top { padding: 7px 16px; border-radius: 7px; font-size: 13px; font-weight: 600; cursor: pointer; }
.btn-top-ghost { border: 1px solid rgba(255,255,255,.2); color: #fff; background: none; }
.btn-top-ghost:hover { background: rgba(255,255,255,.08); }
.btn-top-primary { background: var(--blue); color: #fff; border: none; }
.btn-top-primary:hover { background: var(--blue-dark); }

/* Hero strip */
.hero-strip {
  background: linear-gradient(135deg, var(--navy) 0%, #1e3a5f 100%);
  padding: 40px 5% 36px; text-align: center;
}
.hero-strip h1 { font-size: 26px; font-weight: 900; color: #fff; margin-bottom: 8px; }
.hero-strip p  { font-size: 14px; color: #94a3b8; max-width: 480px; margin: 0 auto; }

/* Form wrapper */
.form-wrap {
  max-width: 680px; margin: 36px auto 60px; padding: 0 16px;
}

/* Section card */
.form-section {
  background: #fff; border: 1px solid var(--border); border-radius: 14px;
  padding: 28px 28px 24px; margin-bottom: 20px;
}
.form-section-title {
  font-size: 13px; font-weight: 800; color: var(--slate); text-transform: uppercase;
  letter-spacing: .8px; margin-bottom: 18px; display: flex; align-items: center; gap: 8px;
}
.form-section-title::after {
  content: ''; flex: 1; height: 1px; background: var(--border);
}
.step-num {
  width: 22px; height: 22px; border-radius: 50%; background: var(--blue);
  color: #fff; font-size: 11px; font-weight: 800;
  display: flex; align-items: center; justify-content: center; flex-shrink: 0;
}

/* Fields */
.f-row  { display: grid; grid-template-columns: 1fr 1fr; gap: 14px; }
.f-row.single { grid-template-columns: 1fr; }
.f-group { display: flex; flex-direction: column; gap: 4px; }
.f-group label { font-size: 13px; font-weight: 700; color: #374151; }
.f-group label .req { color: var(--red); }
.f-group input, .f-group select {
  padding: 11px 12px; border: 1px solid #d1d5db; border-radius: 8px;
  font-size: 15px; font-family: var(--font); color: var(--navy);
  background: #fff; transition: border-color .15s;
}
.f-group input:focus, .f-group select:focus {
  outline: none; border-color: var(--blue); box-shadow: 0 0 0 3px rgba(37,99,235,.1);
}

/* Day checkboxes */
.day-grid {
  display: flex; gap: 8px; flex-wrap: wrap; margin-top: 10px;
}
.day-box { position: relative; }
.day-box input[type=checkbox] { position: absolute; opacity: 0; width: 0; height: 0; }
.day-box label {
  display: flex; align-items: center; justify-content: center;
  width: 44px; height: 44px; border-radius: 10px;
  border: 1.5px solid var(--border); background: var(--bg);
  font-size: 11px; font-weight: 700; color: var(--slate);
  cursor: pointer; transition: all .15s; user-select: none;
}
.day-box input:checked + label {
  background: var(--blue); border-color: var(--blue); color: #fff;
}
.day-box label:hover { border-color: var(--blue); color: var(--blue); }

/* Toggle checkboxes */
.toggle-list { display: flex; flex-direction: column; gap: 10px; }
.toggle-item { display: flex; align-items: center; gap: 12px; cursor: pointer; padding: 10px 12px; border: 1px solid var(--border); border-radius: 8px; transition: border-color .15s; }
.toggle-item:hover { border-color: var(--blue); }
.toggle-item input[type=checkbox] { width: 18px; height: 18px; accent-color: var(--blue); flex-shrink: 0; cursor: pointer; }
.toggle-item .ti-label { font-size: 13px; font-weight: 600; color: #1e293b; }
.toggle-item .ti-sub   { font-size: 11px; color: var(--slate); }

/* Submit */
.btn-submit {
  width: 100%; padding: 14px; background: var(--blue); color: #fff;
  border: none; border-radius: 10px; font-size: 16px; font-weight: 700;
  cursor: pointer; font-family: var(--font); transition: background .15s; margin-top: 8px;
}
.btn-submit:hover { background: var(--blue-dark); }

/* Alerts */
.alert-err {
  background: var(--status-escalation-bg); border: 1px solid var(--status-escalation-border); border-radius: 10px;
  padding: 14px 18px; color: var(--status-escalation-fg); font-size: 13px; margin-bottom: 20px;
}
.alert-note {
  background: var(--status-info-bg); border: 1px solid var(--status-info-border); border-radius: 10px;
  padding: 12px 16px; color: var(--status-info-fg); font-size: 12px; margin-bottom: 20px;
}

/* Success screen */
.success-screen {
  text-align: center; padding: 60px 24px;
  background: #fff; border: 1px solid var(--border); border-radius: 16px;
}
.success-icon {
  width: 72px; height: 72px; border-radius: 50%; background: #dcfce7;
  display: flex; align-items: center; justify-content: center;
  font-size: 32px; margin: 0 auto 20px; font-weight: 900; color: var(--green);
}
.success-screen h2 { font-size: 22px; font-weight: 900; color: var(--navy); margin-bottom: 10px; }
.success-screen p  { font-size: 14px; color: var(--slate); max-width: 400px; margin: 0 auto 24px; line-height: 1.7; }
.success-ref { font-size: 20px; font-weight: 900; color: var(--blue); letter-spacing: 1px; }
.btn-home { display: inline-block; padding: 12px 28px; background: var(--navy); color: #fff; border-radius: 8px; font-size: 14px; font-weight: 700; margin-top: 10px; }

/* Required note */
.req-note { font-size: 11px; color: var(--slate); margin-bottom: 20px; }

/* Document uploads */
.doc-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 14px; }
.doc-upload {
  border: 1.5px dashed #cbd5e1; border-radius: 10px; padding: 14px;
  background: #f8fafc; text-align: center; cursor: pointer; transition: border-color .15s, background .15s;
}
.doc-upload:hover, .doc-upload.has-file { border-color: var(--blue); background: #eff6ff; }
.doc-upload input[type=file] { display: none; }
.doc-upload .du-label { font-size: 12px; font-weight: 700; color: #1e293b; margin-bottom: 4px; }
.doc-upload .du-hint  { font-size: 10px; color: var(--slate); margin-bottom: 8px; }
.doc-upload .du-name  { font-size: 11px; color: var(--blue); font-weight: 600; word-break: break-all; min-height: 16px; }
.doc-preview { margin-top: 8px; max-width: 100%; max-height: 80px; border-radius: 6px; display: none; }

@media (max-width: 600px) {
  .doc-grid { grid-template-columns: 1fr; }
  .f-row { grid-template-columns: 1fr; }
  .form-section { padding: 20px 18px; }
  .hero-strip h1 { font-size: 22px; }
}
</style>
</head>
<body>

<!-- Topbar -->
<div class="topbar">
  <a href="home.jsp" class="topbar-logo">
    <img src="../images/logo/logo_1.jpeg" alt="MVP Logistics">
    <span class="topbar-logo-tag">DSP Platform</span>
  </a>
  <div class="topbar-right">
    <a href="home.jsp" class="btn-top btn-top-ghost">Home</a>
    <a href="../servlet/MVPGServlet?submitType=11&controller=Login" class="btn-top btn-top-primary">Dispatcher Login</a>
  </div>
</div>

<!-- Hero -->
<div class="hero-strip">
  <h1>Drive with MVP Logistics &mdash; DNK7</h1>
  <p>Join our Amazon delivery team. Fill out the form below and we will reach out within 1-2 business days.</p>
</div>

<!-- Form -->
<div class="form-wrap">

<% if ("confirm_sms".equals(submitMsg)) { %>
  <!-- STEP 2: Application saved — confirm before sending SMS -->
  <div class="success-screen">
    <div class="success-icon">&#10003;</div>
    <h2>Application Saved!</h2>
    <p>Ref #<%=newAppId%> has been recorded for <strong><%=esc(smsFirstName)%> <%=esc(smsLastName)%></strong>.</p>
    <p style="font-size:13px;color:#64748b;margin-bottom:8px;">All 4 documents (Driver&rsquo;s License, SSN, Work Permit front &amp; back) have been uploaded.</p>
    <div style="background:#fef3c7;border:1px solid #fde68a;border-radius:10px;padding:16px 20px;margin:20px 0;text-align:left;">
      <p style="font-size:13px;font-weight:700;color:#92400e;margin-bottom:8px;">&#9888; Send SMS Notifications?</p>
      <p style="font-size:13px;color:#78350f;margin-bottom:12px;">
        This will send 2 SMS messages (applicant + dispatcher). Each message has a cost. Confirm only when ready.
      </p>
      <p style="font-size:12px;color:#92400e;">
        <strong>To:</strong> <%=esc(smsPhone)%> &amp; dispatcher (+19082960064)
      </p>
    </div>
    <form method="post" action="DAApplicationForm.jsp" style="display:flex;gap:10px;justify-content:center;flex-wrap:wrap;">
      <input type="hidden" name="action"       value="sendSms">
      <input type="hidden" name="appId"        value="<%=newAppId%>">
      <input type="hidden" name="smsFirstName" value="<%=esc(smsFirstName)%>">
      <input type="hidden" name="smsLastName"  value="<%=esc(smsLastName)%>">
      <input type="hidden" name="smsPhone"     value="<%=esc(smsPhone)%>">
      <input type="hidden" name="smsAvail"     value="<%=esc(smsAvail)%>">
      <button type="submit"
              style="padding:11px 28px;background:#16a34a;color:#fff;border:none;border-radius:8px;font-size:14px;font-weight:700;cursor:pointer;">
        &#128241; Yes, Send SMS
      </button>
      <a href="home.jsp"
         style="padding:11px 28px;background:#f1f5f9;color:#374151;border-radius:8px;font-size:14px;font-weight:600;text-decoration:none;display:inline-flex;align-items:center;">
        Skip &mdash; No SMS
      </a>
    </form>
  </div>

<% } else if ("success".equals(submitMsg)) { %>
  <!-- SUCCESS after SMS sent (or skipped) -->
  <div class="success-screen">
    <div class="success-icon">&#10003;</div>
    <h2>Application Submitted!</h2>
    <% if ("yes".equals(smsSent)) { %>
    <p>Thank you for applying to drive with MVP Logistics. We have received your application and will contact you within 1-2 business days. A confirmation SMS has been sent to your phone.</p>
    <% } else { %>
    <p>Thank you for applying to drive with MVP Logistics. We have received your application and will contact you within 1-2 business days.</p>
    <% } %>
    <div class="success-ref">Ref #<%=newAppId%></div>
    <p style="font-size:12px;color:#94a3b8;margin-top:8px;">Save this number for reference.</p>
    <a href="home.jsp" class="btn-home">Back to Home</a>
  </div>

<% } else { %>

  <% if (!submitErr.isEmpty()) { %>
  <div class="alert-err"><%=esc(submitErr)%></div>
  <% } %>

  <div class="alert-note">
    After submitting, you will receive an SMS confirmation to the phone number you provide. Questions? Call <strong>732-800-1594</strong>.
  </div>
  <p class="req-note"><span style="color:#dc2626;">*</span> Required fields</p>

  <form method="post" action="DAApplicationForm.jsp" enctype="multipart/form-data" onsubmit="return validateForm()">
    <input type="hidden" name="action" value="submit">

    <!-- Section 1: Personal Info -->
    <div class="form-section">
      <div class="form-section-title"><div class="step-num">1</div> Personal Information</div>
      <div class="f-row" style="margin-bottom:14px;">
        <div class="f-group">
          <label>First Name <span class="req">*</span></label>
          <input type="text" name="firstName" value="<%=esc(fieldVal(formFields, request, "firstName"))%>" placeholder="John" maxlength="100">
        </div>
        <div class="f-group">
          <label>Last Name <span class="req">*</span></label>
          <input type="text" name="lastName" value="<%=esc(fieldVal(formFields, request, "lastName"))%>" placeholder="Smith" maxlength="100">
        </div>
      </div>
      <div class="f-row" style="margin-bottom:14px;">
        <div class="f-group">
          <label>Email Address <span class="req">*</span></label>
          <input type="email" name="email" value="<%=esc(fieldVal(formFields, request, "email"))%>" placeholder="you@email.com" maxlength="200">
        </div>
        <div class="f-group">
          <label>Phone Number <span class="req">*</span></label>
          <input type="tel" name="phone" value="<%=esc(fieldVal(formFields, request, "phone"))%>" placeholder="(908) 000-0000" maxlength="30">
        </div>
      </div>
    </div>

    <!-- Section 2: Availability -->
    <div class="form-section">
      <div class="form-section-title"><div class="step-num">2</div> Availability</div>
      <div class="f-group" style="margin-bottom:18px;">
        <label>Availability Type <span class="req">*</span></label>
        <select name="availType" id="availType">
          <option value="">Select...</option>
          <option value="FULLTIME"<%="FULLTIME".equals(fieldVal(formFields, request, "availType"))?" selected":""%>>Full Time (upto 4 days)</option>
          <option value="PARTTIME_WEEKEND"<%="PARTTIME_WEEKEND".equals(fieldVal(formFields, request, "availType"))?" selected":""%>>Part Time &mdash; Weekends</option>
          <option value="PARTTIME_MIXED"<%="PARTTIME_MIXED".equals(fieldVal(formFields, request, "availType"))?" selected":""%>>Part Time &mdash; Mixed Days</option>
        </select>
      </div>
      <label style="font-size:11px;font-weight:700;color:#374151;">Days Available</label>
      <div class="day-grid">
        <div class="day-box"><input type="checkbox" name="avail_sun" id="d_sun"<%=fieldChecked(formFields, request, "avail_sun")?" checked":""%>><label for="d_sun">SUN</label></div>
        <div class="day-box"><input type="checkbox" name="avail_mon" id="d_mon"<%=fieldChecked(formFields, request, "avail_mon")?" checked":""%>><label for="d_mon">MON</label></div>
        <div class="day-box"><input type="checkbox" name="avail_tue" id="d_tue"<%=fieldChecked(formFields, request, "avail_tue")?" checked":""%>><label for="d_tue">TUE</label></div>
        <div class="day-box"><input type="checkbox" name="avail_wed" id="d_wed"<%=fieldChecked(formFields, request, "avail_wed")?" checked":""%>><label for="d_wed">WED</label></div>
        <div class="day-box"><input type="checkbox" name="avail_thu" id="d_thu"<%=fieldChecked(formFields, request, "avail_thu")?" checked":""%>><label for="d_thu">THU</label></div>
        <div class="day-box"><input type="checkbox" name="avail_fri" id="d_fri"<%=fieldChecked(formFields, request, "avail_fri")?" checked":""%>><label for="d_fri">FRI</label></div>
        <div class="day-box"><input type="checkbox" name="avail_sat" id="d_sat"<%=fieldChecked(formFields, request, "avail_sat")?" checked":""%>><label for="d_sat">SAT</label></div>
      </div>
    </div>

    <!-- Section 3: Documents & Eligibility -->
    <div class="form-section">
      <div class="form-section-title"><div class="step-num">3</div> Documents &amp; Eligibility</div>
      <div class="toggle-list">
        <label class="toggle-item">
          <input type="checkbox" name="has_dl"<%=fieldChecked(formFields, request, "has_dl")?" checked":""%>>
          <div><div class="ti-label">Valid Driver&rsquo;s License</div><div class="ti-sub">US driver&rsquo;s license, not expired</div></div>
        </label>
        <label class="toggle-item">
          <input type="checkbox" name="has_ssn"<%=fieldChecked(formFields, request, "has_ssn")?" checked":""%>>
          <div><div class="ti-label">Social Security Number</div><div class="ti-sub">Required for background and drug test</div></div>
        </label>
        <label class="toggle-item">
          <input type="checkbox" name="has_work_auth"<%=fieldChecked(formFields, request, "has_work_auth")?" checked":""%>>
          <div><div class="ti-label">Authorized to Work in the US</div><div class="ti-sub">Citizen, permanent resident, or valid work visa</div></div>
        </label>
        <label class="toggle-item">
          <input type="checkbox" name="has_amazon_exp"<%=fieldChecked(formFields, request, "has_amazon_exp")?" checked":""%>>
          <div><div class="ti-label">Previous Amazon Delivery Experience</div><div class="ti-sub">Worked as a DA for any DSP before (optional)</div></div>
        </label>
        <label class="toggle-item">
          <input type="checkbox" name="has_amazon_acct"<%=fieldChecked(formFields, request, "has_amazon_acct")?" checked":""%>>
          <div><div class="ti-label">Active Amazon Flex / DA Account</div><div class="ti-sub">Already have an Amazon delivery account</div></div>
        </label>
      </div>
    </div>

    <!-- Section 4: Document Upload -->
    <div class="form-section">
      <div class="form-section-title"><div class="step-num">4</div> Upload Documents</div>
      <p style="font-size:12px;color:var(--slate);margin-bottom:14px;">
        Upload clear photos of each document (JPG, PNG, WEBP, or PDF, max 10 MB each).
        Files are saved with your application<% if (isDriveUploadEnabled()) { %> and copied to Google Drive<% } %>.
      </p>
      <div class="doc-grid">
        <label class="doc-upload" id="box_dl">
          <input type="file" name="doc_dl" id="doc_dl" accept="image/jpeg,image/png,image/webp,application/pdf" onchange="previewDoc(this,'box_dl','prev_dl')">
          <div class="du-label">Driver&rsquo;s License <span class="req">*</span></div>
          <div class="du-hint">Front of license</div>
          <div class="du-name" id="name_dl">Tap to choose file</div>
          <img class="doc-preview" id="prev_dl" alt="">
        </label>
        <label class="doc-upload" id="box_ssn">
          <input type="file" name="doc_ssn" id="doc_ssn" accept="image/jpeg,image/png,image/webp,application/pdf" onchange="previewDoc(this,'box_ssn','prev_ssn')">
          <div class="du-label">Social Security Card <span class="req">*</span></div>
          <div class="du-hint">Full card, all corners visible</div>
          <div class="du-name" id="name_ssn">Tap to choose file</div>
          <img class="doc-preview" id="prev_ssn" alt="">
        </label>
        <label class="doc-upload" id="box_wp_front">
          <input type="file" name="doc_wp_front" id="doc_wp_front" accept="image/jpeg,image/png,image/webp,application/pdf" onchange="previewDoc(this,'box_wp_front','prev_wp_front')">
          <div class="du-label">Work Permit &mdash; Front <span class="req">*</span></div>
          <div class="du-hint">Front side of work authorization</div>
          <div class="du-name" id="name_wp_front">Tap to choose file</div>
          <img class="doc-preview" id="prev_wp_front" alt="">
        </label>
        <label class="doc-upload" id="box_wp_back">
          <input type="file" name="doc_wp_back" id="doc_wp_back" accept="image/jpeg,image/png,image/webp,application/pdf" onchange="previewDoc(this,'box_wp_back','prev_wp_back')">
          <div class="du-label">Work Permit &mdash; Back <span class="req">*</span></div>
          <div class="du-hint">Back side of work authorization</div>
          <div class="du-name" id="name_wp_back">Tap to choose file</div>
          <img class="doc-preview" id="prev_wp_back" alt="">
        </label>
      </div>
    </div>

    <button type="submit" class="btn-submit">Submit Application</button>
    <p style="font-size:11px;color:#94a3b8;text-align:center;margin-top:12px;">
      By submitting you agree to be contacted by MVP Logistics LLC regarding this application.
    </p>
  </form>
<% } %>

</div><!-- /form-wrap -->

<script>
function previewDoc(input, boxId, previewId) {
  var box = document.getElementById(boxId);
  var nameEl = box.querySelector('.du-name');
  var preview = document.getElementById(previewId);
  if (!input.files || !input.files[0]) {
    box.classList.remove('has-file');
    nameEl.textContent = 'Tap to choose file';
    preview.style.display = 'none';
    preview.src = '';
    return;
  }
  var f = input.files[0];
  box.classList.add('has-file');
  nameEl.textContent = f.name;
  if (f.type.indexOf('image/') === 0) {
    var reader = new FileReader();
    reader.onload = function(e) {
      preview.src = e.target.result;
      preview.style.display = 'inline-block';
    };
    reader.readAsDataURL(f);
  } else {
    preview.style.display = 'none';
    preview.src = '';
  }
}

function validateForm() {
  var fn = document.querySelector('[name=firstName]').value.trim();
  var ln = document.querySelector('[name=lastName]').value.trim();
  var em = document.querySelector('[name=email]').value.trim();
  var ph = document.querySelector('[name=phone]').value.trim();
  var av = document.querySelector('[name=availType]').value;
  if (!fn || !ln || !em || !ph || !av) {
    alert('Please fill in all required fields: First Name, Last Name, Email, Phone, and Availability Type.');
    return false;
  }
  var emailOk = /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(em);
  if (!emailOk) { alert('Please enter a valid email address.'); return false; }
  var docs = ['doc_dl','doc_ssn','doc_wp_front','doc_wp_back'];
  for (var i = 0; i < docs.length; i++) {
    var el = document.getElementById(docs[i]);
    if (!el || !el.files || !el.files[0]) {
      alert('Please upload all 4 required documents: Driver\'s License, SSN, Work Permit (front), and Work Permit (back).');
      return false;
    }
    if (el.files[0].size > 10 * 1024 * 1024) {
      alert('Each document must be 10 MB or smaller.');
      return false;
    }
  }
  return true;
}
</script>
</body>
</html>
