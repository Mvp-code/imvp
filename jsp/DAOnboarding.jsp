<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"
         import="java.sql.*,javax.sql.*,javax.naming.*,java.util.*,java.io.*,
                 javax.servlet.http.HttpServletRequest,com.util.*,com.beans.*,
                 com.tools.ServerUploadPaths,
                 org.apache.commons.fileupload.servlet.ServletFileUpload,
                 org.apache.commons.fileupload.disk.DiskFileItemFactory,
                 org.apache.commons.fileupload.FileItem,
                 org.apache.commons.io.FilenameUtils" %>
<%!
  private static final String[] STAGE_LABELS = {
    "S1 Background Check",
    "S2 Drug Test Details",
    "S3 Training Schedule/Day1 & Day2",
    "S4 ADP Onboarding Completed",
    "S5 Orientation",
    "S6 Schedule Fixed",
    "S7 Day 1 On-Road Training",
    "S8 Offer Letter Signed"
  };
  private static final String[] STAGE_KEYS = {
    "S1","S2","S3","S4","S5","S6","S7","S8"
  };
  private static final String[] VISIBLE_STAGE_KEYS = {
    "S1","S2","S3","S4","S5","S6","S7","S8"
  };
  private static final String[] STAGE_SHORT = {
    "Background Check",
    "Drug Test Details",
    "Training Schedule/Day1 & Day2",
    "ADP Onboarding",
    "Orientation",
    "Schedule Fixed",
    "Day 1 On-Road",
    "Offer Letter Signed"
  };

  private static final String[] DRUG_ORDER_BUILTIN = {
    "DRUG_TEST_SENT:Drug Test sent",
    "DRUG_TEST_COMPLETED:Drug Test Completed",
    "PENDING_DA:pending on DA to completed",
    "DA_CONFIRMED_RECEIVED:DA confirmed Drug Test Received"
  };
  private static final String[] DRUG_RESULT_BUILTIN = {
    "PENDING:Pending",
    "NEGATIVE:Negative (Pass)",
    "POSITIVE:Positive (Fail)"
  };
  private static final String[] TRAINING_SCHED_BUILTIN = {
    "PENDING:Pending",
    "SCHEDULED:Scheduled",
    "CONFIRMED:Confirmed"
  };

  private Connection getConn() throws Exception {
    Context ctx = new InitialContext();
    DataSource ds = (DataSource) ctx.lookup("java:comp/env/jdbc/MVPGDB");
    return ds.getConnection();
  }

  private int seqSeed(Connection conn, String seqName) {
    try {
      String sql = null;
      if ("STAGE_LOG_ID".equals(seqName))
        sql = "SELECT IFNULL(MAX(STAGE_LOG_ID),0) FROM da_onboarding_stage_log";
      else if ("DA_ONBOARDINGID".equals(seqName))
        sql = "SELECT IFNULL(MAX(onboarding_id),0) FROM da_onboarding";
      if (sql == null) return 0;
      Statement st = conn.createStatement();
      ResultSet rs = st.executeQuery(sql);
      int n = rs.next() ? rs.getInt(1) : 0;
      rs.close(); st.close();
      return n;
    } catch (Exception e) { return 0; }
  }

  private void ensureSeqRow(Connection conn, String seqName) throws Exception {
    PreparedStatement ps = conn.prepareStatement("SELECT val FROM seq WHERE name=?");
    ps.setString(1, seqName);
    ResultSet rs = ps.executeQuery();
    boolean exists = rs.next();
    rs.close(); ps.close();
    if (exists) return;
    PreparedStatement pi = conn.prepareStatement("INSERT INTO seq (name, val) VALUES (?, ?)");
    pi.setString(1, seqName);
    pi.setInt(2, seqSeed(conn, seqName));
    try { pi.executeUpdate(); } catch (SQLException ignore) {}
    pi.close();
  }

  private int getNextSeqID(Connection conn, String seqName) throws Exception {
    ensureSeqRow(conn, seqName);
    int seed = seqSeed(conn, seqName);
    PreparedStatement psChk = conn.prepareStatement("SELECT val FROM seq WHERE name=?");
    psChk.setString(1, seqName);
    ResultSet rsChk = psChk.executeQuery();
    int cur = rsChk.next() ? rsChk.getInt(1) : 0;
    rsChk.close(); psChk.close();
    if (cur < seed) {
      PreparedStatement puFix = conn.prepareStatement("UPDATE seq SET val=? WHERE name=?");
      puFix.setInt(1, seed);
      puFix.setString(2, seqName);
      puFix.executeUpdate();
      puFix.close();
    }
    PreparedStatement pu = conn.prepareStatement("UPDATE seq SET val=val+1 WHERE name=?");
    pu.setString(1, seqName); pu.executeUpdate(); pu.close();
    PreparedStatement ps = conn.prepareStatement("SELECT val FROM seq WHERE name=?");
    ps.setString(1, seqName);
    ResultSet rs = ps.executeQuery();
    int id = rs.next() ? rs.getInt(1) : (seed + 1); rs.close(); ps.close();
    return id;
  }

  private int nextOnboardingId(Connection conn) throws Exception {
    int seqId = getNextSeqID(conn, "DA_ONBOARDINGID");
    PreparedStatement ps = conn.prepareStatement("SELECT MAX(onboarding_id) FROM da_onboarding");
    ResultSet rs = ps.executeQuery();
    int maxId = rs.next() ? rs.getInt(1) : 0;
    rs.close(); ps.close();
    if (seqId <= maxId) {
      seqId = maxId + 1;
      PreparedStatement pu = conn.prepareStatement("UPDATE seq SET val=? WHERE name='DA_ONBOARDINGID'");
      pu.setInt(1, seqId);
      pu.executeUpdate();
      pu.close();
    }
    return seqId;
  }

  private int findOnboardingIdByApp(Connection conn, int appId) throws Exception {
    PreparedStatement ps = conn.prepareStatement(
      "SELECT onboarding_id FROM da_onboarding WHERE application_id=?");
    ps.setInt(1, appId);
    ResultSet rs = ps.executeQuery();
    int obId = rs.next() ? rs.getInt(1) : 0;
    rs.close(); ps.close();
    return obId;
  }

  private int resolveOrCreateOnboardingId(Connection conn, int appId, int entityId, String loginUser) throws Exception {
    int existing = findOnboardingIdByApp(conn, appId);
    if (existing > 0) return existing;

    int newObId = nextOnboardingId(conn);
    PreparedStatement psCreate = conn.prepareStatement(
      "INSERT INTO da_onboarding (onboarding_id, application_id, entity_id, station, current_stage, ob_status, CREATE_USER, UPDATE_USER) " +
      "VALUES (?,?,?,'DNK7','S1','PENDING',?,?)");
    psCreate.setInt(1, newObId);
    psCreate.setInt(2, appId);
    psCreate.setInt(3, entityId);
    psCreate.setString(4, loginUser);
    psCreate.setString(5, loginUser);
    try {
      psCreate.executeUpdate();
    } catch (SQLException dup) {
      if (dup.getMessage() != null && dup.getMessage().contains("Duplicate entry")) {
        existing = findOnboardingIdByApp(conn, appId);
        if (existing > 0) {
          psCreate.close();
          return existing;
        }
      }
      throw dup;
    }
    psCreate.close();
    return newObId;
  }

  private String gp(HttpServletRequest req, String name) {
    String v = req.getParameter(name);
    return v != null ? v.trim() : "";
  }

  /** Stage Entered/Exited are date-only (YYYY-MM-DD). */
  private String dateOnly(String v) {
    if (v == null) return "";
    v = v.trim().replace('T', ' ');
    if (v.length() >= 10) return v.substring(0, 10);
    return v;
  }

  /** Map UI done values to tinyint 0/1. */
  private int parseDoneFlag(String v) {
    if (v == null) return 0;
    v = v.trim().toLowerCase();
    if (v.isEmpty() || "0".equals(v) || "n".equals(v) || "no".equals(v) || "false".equals(v)) return 0;
    if ("1".equals(v) || "y".equals(v) || "yes".equals(v) || "done".equals(v) || "true".equals(v)) return 1;
    try { return Integer.parseInt(v) != 0 ? 1 : 0; } catch (Exception e) { return 1; }
  }

  private void ensureAppDocColumns(Connection conn) {
    String[] alters = {
      "ALTER TABLE da_applications ADD COLUMN dl_file_path VARCHAR(500) NULL",
      "ALTER TABLE da_applications ADD COLUMN ssn_file_path VARCHAR(500) NULL",
      "ALTER TABLE da_applications ADD COLUMN wp_front_file_path VARCHAR(500) NULL",
      "ALTER TABLE da_applications ADD COLUMN wp_back_file_path VARCHAR(500) NULL",
      "ALTER TABLE da_applications ADD COLUMN dl_drive_url VARCHAR(500) NULL",
      "ALTER TABLE da_applications ADD COLUMN ssn_drive_url VARCHAR(500) NULL",
      "ALTER TABLE da_applications ADD COLUMN wp_front_drive_url VARCHAR(500) NULL",
      "ALTER TABLE da_applications ADD COLUMN wp_back_drive_url VARCHAR(500) NULL",
      "ALTER TABLE da_applications ADD COLUMN offer_letter_signed TINYINT(1) NULL DEFAULT 0",
      "ALTER TABLE da_applications ADD COLUMN offer_letter_file_path VARCHAR(500) NULL",
      "ALTER TABLE da_applications ADD COLUMN offer_letter_drive_url VARCHAR(500) NULL"
    };
    for (String sql : alters) {
      try { Statement st = conn.createStatement(); st.executeUpdate(sql); st.close(); }
      catch (Exception ignore) {}
    }
  }

  /** Identity helper — pipeline is S1–S7 after migratePipelineStages. */
  private String canonicalStage(String stage) {
    if (stage == null) return "";
    if ("S9".equals(stage)) return "S7";
    return stage;
  }

  private String stageClass(String current, String stage) {
    if (current == null || current.isEmpty()) return "st-pending";
    String cur = canonicalStage(current);
    String stg = stage == null ? "" : stage;
    int c = -1, s = -1;
    for (int i = 0; i < VISIBLE_STAGE_KEYS.length; i++) {
      if (VISIBLE_STAGE_KEYS[i].equals(cur)) c = i;
      if (VISIBLE_STAGE_KEYS[i].equals(stg)) s = i;
    }
    if (s < 0 || c < 0) return "st-pending";
    if (s < c)  return "st-done";
    if (s == c) return "st-active";
    return "st-pending";
  }

  private String statusBadge(String status) {
    if (status == null || status.isEmpty()) return "<span class='badge badge-gray'>-</span>";
    switch (status.toUpperCase()) {
      case "NEW":             return "<span class='badge' style='background:#f0fdf4;color:#166534;border:1px solid #bbf7d0;'>New</span>";
      case "PENDING":         return "<span class='badge badge-gray'>Pending</span>";
      case "ON_TRACK":        return "<span class='badge badge-green'>On Track</span>";
      case "BEHIND":          return "<span class='badge badge-red'>Behind</span>";
      case "ON_HOLD":         return "<span class='badge badge-amber'>On Hold</span>";
      case "FAILED":          return "<span class='badge' style='background:#fef2f2;color:#991b1b;border:1px solid #fecaca;'>Failed</span>";
      case "NOT_INTERESTED":  return "<span class='badge' style='background:#fff7ed;color:#9a3412;border:1px solid #fed7aa;'>Not Interested</span>";
      case "NO_RESPONSE":     return "<span class='badge' style='background:#f8fafc;color:#475569;border:1px solid #cbd5e1;'>No Response</span>";
      case "COMPLETE":        return "<span class='badge badge-blue'>Complete</span>";
      default: {
        String label = status;
        if (label.toUpperCase().startsWith("X_")) label = label.substring(2);
        return "<span class='badge badge-gray'>" + esc(label.replace('_',' ')) + "</span>";
      }
    }
  }

  private boolean isManualPipelineStatus(String status) {
    if (status == null || status.isEmpty()) return false;
    String u = status.toUpperCase();
    return "ON_HOLD".equals(u) || "COMPLETE".equals(u)
        || "FAILED".equals(u) || "NOT_INTERESTED".equals(u) || "NO_RESPONSE".equals(u)
        || u.startsWith("X_");
  }

  /** Checkr result that means we cannot hire this DA. */
  private boolean isFailedBackground(String checkr) {
    if (checkr == null) return false;
    String u = checkr.trim().toUpperCase();
    return "FAIL".equals(u) || "FAILED".equals(u)
        || "ADVERSE".equals(u) || "ADVERSE_ACTION".equals(u);
  }

  private boolean isFailedOffPipeline(String obStatus, String checkr) {
    if (isFailedBackground(checkr)) return true;
    return obStatus != null && "FAILED".equalsIgnoreCase(obStatus.trim());
  }

  private void markFailedBackgroundOffPipeline(Connection conn) {
    try {
      Statement st = conn.createStatement();
      st.executeUpdate(
        "UPDATE da_onboarding SET ob_status='FAILED' " +
        "WHERE IFNULL(ob_status,'') NOT IN ('FAILED','COMPLETE') " +
        "AND UPPER(IFNULL(checkr_status,'')) IN ('FAIL','FAILED','ADVERSE','ADVERSE_ACTION')");
      st.close();
    } catch (Exception ignore) {}
  }

  private String statusCodeFromLabel(String label) {
    String code = label.trim().toUpperCase().replaceAll("[^A-Z0-9]+", "_");
    while (code.startsWith("_")) code = code.substring(1);
    while (code.endsWith("_")) code = code.substring(0, code.length() - 1);
    if (code.length() == 0) code = "CUSTOM";
    if (!code.startsWith("X_")) code = "X_" + code;
    return code;
  }

  private List<String[]> parseExtraStatuses(String raw) {
    List<String[]> out = new ArrayList<String[]>();
    if (raw == null || raw.trim().isEmpty()) return out;
    String[] parts = raw.split("\\|");
    for (int i = 0; i < parts.length; i++) {
      String p = parts[i].trim();
      if (p.length() == 0) continue;
      int colon = p.indexOf(':');
      if (colon > 0) {
        out.add(new String[] { p.substring(0, colon).trim(), p.substring(colon + 1).trim() });
      } else {
        out.add(new String[] { statusCodeFromLabel(p), p });
      }
    }
    return out;
  }

  private List<String[]> buildStatusList(String[] builtins, String extraRaw) {
    List<String[]> out = new ArrayList<String[]>();
    Set<String> seen = new HashSet<String>();
    for (int i = 0; i < builtins.length; i++) {
      String[] p = builtins[i].split(":", 2);
      if (p.length < 2) continue;
      out.add(new String[] { p[0], p[1] });
      seen.add(p[0].toUpperCase());
    }
    List<String[]> extras = parseExtraStatuses(extraRaw);
    for (String[] e : extras) {
      if (e[0] == null || e[0].isEmpty()) continue;
      if (seen.contains(e[0].toUpperCase())) continue;
      out.add(e);
      seen.add(e[0].toUpperCase());
    }
    return out;
  }

  private void ensureDrugDocColumn(Connection conn) {
    try {
      Statement st = conn.createStatement();
      st.executeUpdate("ALTER TABLE da_onboarding ADD COLUMN drug_test_doc_path VARCHAR(500) NULL");
      st.close();
    } catch (Exception ignore) {}
  }

  private void ensureStageNoteColumns(Connection conn) {
    String[] alters = {
      "ALTER TABLE da_onboarding ADD COLUMN s6_notes TEXT NULL",
      "ALTER TABLE da_onboarding ADD COLUMN s7_notes TEXT NULL",
      "ALTER TABLE da_onboarding MODIFY COLUMN s5_result VARCHAR(500) NULL",
      "ALTER TABLE da_onboarding MODIFY COLUMN s3_result VARCHAR(500) NULL",
      "ALTER TABLE da_onboarding MODIFY COLUMN s2_status VARCHAR(100) NULL",
      "ALTER TABLE da_onboarding MODIFY COLUMN s4_status VARCHAR(100) NULL",
      "ALTER TABLE da_onboarding MODIFY COLUMN s8_adp_status VARCHAR(100) NULL",
      "ALTER TABLE da_onboarding MODIFY COLUMN s9_status VARCHAR(100) NULL",
      "ALTER TABLE da_onboarding ADD COLUMN offer_letter_signed TINYINT(1) NULL DEFAULT 0",
      "ALTER TABLE da_onboarding ADD COLUMN offer_letter_doc_path VARCHAR(500) NULL",
      "ALTER TABLE da_onboarding ADD COLUMN offer_letter_entered_at DATETIME NULL",
      "ALTER TABLE da_onboarding ADD COLUMN offer_letter_exited_at DATETIME NULL",
      "ALTER TABLE da_applications ADD COLUMN offer_letter_signed TINYINT(1) NULL DEFAULT 0",
      "ALTER TABLE da_applications ADD COLUMN offer_letter_file_path VARCHAR(500) NULL",
      "ALTER TABLE da_applications ADD COLUMN offer_letter_drive_url VARCHAR(500) NULL"
    };
    for (String sql : alters) {
      try { Statement st = conn.createStatement(); st.executeUpdate(sql); st.close(); }
      catch (Exception ignore) {}
    }
    /* One-shot: reopen rows marked COMPLETE before S8 offer letter existed */
    try {
      PreparedStatement psChk = conn.prepareStatement(
        "SELECT 1 FROM mvpg_config WHERE config_key='ONBOARDING_REOPEN_PREMATURE_COMPLETE_V1' AND is_active='Y' LIMIT 1");
      ResultSet rsChk = psChk.executeQuery();
      boolean done = rsChk.next();
      rsChk.close(); psChk.close();
      if (!done) {
        Statement st = conn.createStatement();
        st.executeUpdate(
          "UPDATE da_onboarding SET ob_status='ON_TRACK', " +
          "current_stage=CASE WHEN s9_day1_date IS NOT NULL THEN 'S7' " +
          "WHEN s4_scheduled_date IS NOT NULL OR s5_day1_date IS NOT NULL THEN 'S3' " +
          "WHEN IFNULL(current_stage,'') IN ('','S8') THEN 'S7' ELSE current_stage END, " +
          "completed_date=NULL " +
          "WHERE ob_status='COMPLETE' AND IFNULL(offer_letter_signed,0)=0");
        st.close();
        try {
          PreparedStatement psI = conn.prepareStatement(
            "INSERT INTO mvpg_config (config_id, entity_id, config_group, config_key, config_label, " +
            "config_value, config_desc, is_active, CREATE_USER) " +
            "SELECT IFNULL(MAX(config_id),0)+1, 1, 'ONBOARDING', 'ONBOARDING_REOPEN_PREMATURE_COMPLETE_V1', " +
            "'Reopen premature COMPLETE', 'Y', 'Rows COMPLETE without offer letter reopened once', 'Y', 'SYSTEM' " +
            "FROM mvpg_config");
          psI.executeUpdate(); psI.close();
        } catch (Exception ignoreIns) {}
      }
    } catch (Exception ignore) {}
  }

  /**
   * One-shot renumber: old S6→S4, S7→S5, S8→S6, S9→S7.
   * Guarded by mvpg_config ONBOARDING_STAGE_RENUMBER_V2 so it never re-runs
   * after new S6/S7 meanings (Schedule / Day 1) are in use.
   */
  private int migratePipelineStages(Connection conn) {
    try {
      PreparedStatement psChk = conn.prepareStatement(
        "SELECT 1 FROM mvpg_config WHERE config_key='ONBOARDING_STAGE_RENUMBER_V2' AND is_active='Y' LIMIT 1");
      ResultSet rsChk = psChk.executeQuery();
      boolean already = rsChk.next();
      rsChk.close(); psChk.close();
      if (already) return 0;

      Statement st = conn.createStatement();
      int n = st.executeUpdate(
        "UPDATE da_onboarding SET current_stage = CASE current_stage " +
        "WHEN 'S9' THEN 'S7' WHEN 'S8' THEN 'S6' WHEN 'S7' THEN 'S5' WHEN 'S6' THEN 'S4' " +
        "ELSE current_stage END WHERE current_stage IN ('S6','S7','S8','S9')");
      try {
        st.executeUpdate(
          "UPDATE da_onboarding_stage_log SET STAGE_CODE = CASE STAGE_CODE " +
          "WHEN 'S9' THEN 'S7' WHEN 'S8' THEN 'S6' WHEN 'S7' THEN 'S5' WHEN 'S6' THEN 'S4' " +
          "ELSE STAGE_CODE END WHERE STAGE_CODE IN ('S6','S7','S8','S9')");
      } catch (Exception ignoreLog) {}
      st.close();

      PreparedStatement psI = conn.prepareStatement(
        "INSERT INTO mvpg_config (config_id, entity_id, config_group, config_key, config_label, config_value, config_desc, is_active, CREATE_USER) "
        + "VALUES (?,1,'ONBOARDING','ONBOARDING_STAGE_RENUMBER_V2','Stage Renumber V2','Y',"
        + "'S6-S9 remapped to S4-S7','Y','SYSTEM')");
      int cfgId = 1;
      try {
        Statement stMax = conn.createStatement();
        ResultSet rsMax = stMax.executeQuery("SELECT IFNULL(MAX(config_id),0)+1 FROM mvpg_config");
        if (rsMax.next()) cfgId = rsMax.getInt(1);
        rsMax.close(); stMax.close();
      } catch (Exception ignoreMax) {}
      psI.setInt(1, cfgId);
      try { psI.executeUpdate(); } catch (Exception ignoreIns) {}
      psI.close();
      return n;
    } catch (Exception ignore) {
      return 0;
    }
  }

  private String folderPart(String s) {
    String t = s == null ? "" : s.trim().replaceAll("[\\\\/:*?\"<>|]+", " ").replaceAll("\\s+", "_");
    t = t.replaceAll("[^A-Za-z0-9_\\-]+", "");
    while (t.startsWith("_")) t = t.substring(1);
    while (t.endsWith("_")) t = t.substring(0, t.length() - 1);
    return t;
  }

  private String appUploadFolderName(int appId, String firstName, String lastName) {
    String fn = folderPart(firstName);
    String ln = folderPart(lastName);
    StringBuilder sb = new StringBuilder();
    sb.append(appId);
    if (fn.length() > 0) sb.append("_").append(fn);
    if (ln.length() > 0) sb.append("_").append(ln);
    return sb.toString();
  }

  private String saveNamedAppDoc(FileItem item, int appId, String firstName, String lastName, String suffix) throws Exception {
    if (item == null || item.getName() == null || item.getName().trim().isEmpty()) return null;
    String orig = FilenameUtils.getName(item.getName());
    String ext = "";
    int dot = orig.lastIndexOf('.');
    if (dot >= 0) ext = orig.substring(dot).toLowerCase();
    if (!(".pdf".equals(ext) || ".png".equals(ext) || ".jpg".equals(ext) || ".jpeg".equals(ext) || ".webp".equals(ext))) {
      throw new Exception(suffix + " must be PDF or image");
    }
    if (item.getSize() > 50L * 1024L * 1024L) {
      throw new Exception(suffix + " exceeds 50 MB");
    }
    String folderName = appUploadFolderName(appId, firstName, lastName);
    File destDir = new File(ServerUploadPaths.getDAApplications(), folderName);
    if (!destDir.isDirectory()) destDir.mkdirs();
    File f = new File(destDir, folderName + "_" + suffix + ext);
    item.write(f);
    return f.getAbsolutePath();
  }

  private String saveDrugTestDoc(FileItem item, int appId, String firstName, String lastName) throws Exception {
    return saveNamedAppDoc(item, appId, firstName, lastName, "drug_test_result");
  }

  private String gpMap(Map<String,String> form, HttpServletRequest req, String name) {
    if (form != null && form.containsKey(name)) {
      String v = form.get(name);
      return v == null ? "" : v.trim();
    }
    return gp(req, name);
  }

  private String esc(String s) {
    if (s == null) return "";
    return s.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("'","&#39;");
  }
%>
<%
  /* ── Session vars from MVPGServlet (graceful fallback for direct access) ── */
  String obLoginUser   = (request.getAttribute("loginUser")            != null) ? request.getAttribute("loginUser").toString()            : (String) session.getAttribute("loginUser");
  String obLoginRoles  = (request.getAttribute("loginUserRoles")       != null) ? request.getAttribute("loginUserRoles").toString()       : (String) session.getAttribute("loginUserRoles");
  String obEntityID    = (request.getAttribute("entityID")             != null) ? request.getAttribute("entityID").toString()             : (session.getAttribute("entityID") != null ? session.getAttribute("entityID").toString() : "1");
  String obDispName    = (request.getAttribute("loginUserDisplayName") != null) ? request.getAttribute("loginUserDisplayName").toString() : (session.getAttribute("loginUserDisplayName") != null ? session.getAttribute("loginUserDisplayName").toString() : "");
  String obLoginUserID = (request.getAttribute("loginUserID")          != null) ? request.getAttribute("loginUserID").toString()          : (session.getAttribute("loginUserID") != null ? session.getAttribute("loginUserID").toString() : "");

  if (obLoginUser  == null) obLoginUser  = "";
  if (obLoginRoles == null) obLoginRoles = "";
  if (obDispName   == null) obDispName   = "User";

  /* ── Require login — redirect if no session ── */
  if (obLoginUser.isEmpty()) {
    response.sendRedirect(request.getContextPath() + "/servlet/MVPGServlet?submitType=11&controller=Login");
    return;
  }

  /* ── Load mvpg_config for this entity ── */
  int cfgEid = 1;
  try { cfgEid = Integer.parseInt(obEntityID.isEmpty() ? "1" : obEntityID); } catch (Exception ex) {}
  java.util.Map<String,String> cfg = new java.util.HashMap<String,String>();
  Connection cfgConn = null;
  try {
    cfgConn = getConn();
    PreparedStatement psCfg = cfgConn.prepareStatement(
      "SELECT config_key, config_value FROM mvpg_config WHERE entity_id=? AND is_active='Y'");
    psCfg.setInt(1, cfgEid);
    ResultSet rsCfg = psCfg.executeQuery();
    while (rsCfg.next()) cfg.put(rsCfg.getString(1), rsCfg.getString(2));
    rsCfg.close(); psCfg.close();
  } catch (Exception ex) { /* table may not exist yet — use defaults */ }
  finally { if (cfgConn != null) try { cfgConn.close(); } catch (Exception e) {} }
  int behindDays  = 7;
  try { behindDays = Integer.parseInt(cfg.getOrDefault("ONBOARDING_BEHIND_DAYS","7")); } catch (Exception ex) {}
  String cfgJobTitle   = cfg.getOrDefault("JOB_TITLE",   "Amazon Delivery Driver");
  String cfgLeadSource = cfg.getOrDefault("LEAD_SOURCE",  "Lead Form");
  String cfgStation    = cfg.getOrDefault("STATION_CODE", "DNK7");
  List<String[]> extraStatuses = parseExtraStatuses(cfg.getOrDefault("ONBOARDING_EXTRA_STATUSES", ""));
  List<String[]> drugOrderStatuses = buildStatusList(DRUG_ORDER_BUILTIN,
      cfg.getOrDefault("ONBOARDING_DRUG_ORDER_STATUSES", ""));
  List<String[]> drugResultStatuses = buildStatusList(DRUG_RESULT_BUILTIN,
      cfg.getOrDefault("ONBOARDING_DRUG_RESULT_STATUSES", ""));
  List<String[]> trainingSchedStatuses = buildStatusList(TRAINING_SCHED_BUILTIN,
      cfg.getOrDefault("ONBOARDING_TRAINING_SCHEDULE_STATUSES", ""));
  List<String[]> pipelineStatuses = new ArrayList<String[]>();
  pipelineStatuses.add(new String[]{"PENDING","Pending"});
  pipelineStatuses.add(new String[]{"ON_TRACK","On Track"});
  pipelineStatuses.add(new String[]{"BEHIND","Behind"});
  pipelineStatuses.add(new String[]{"ON_HOLD","On Hold"});
  pipelineStatuses.add(new String[]{"FAILED","Failed"});
  pipelineStatuses.add(new String[]{"NOT_INTERESTED","Not Interested"});
  pipelineStatuses.add(new String[]{"NO_RESPONSE","No Response"});
  for (String[] xs : extraStatuses) pipelineStatuses.add(xs);
  pipelineStatuses.add(new String[]{"COMPLETE","Complete"});

  /* ── POST: add custom pipeline status ── */
  if ("POST".equalsIgnoreCase(request.getMethod()) && "addPipelineStatus".equals(request.getParameter("action"))) {
    response.setContentType("application/json; charset=UTF-8");
    java.io.PrintWriter pw = response.getWriter();
    String label = request.getParameter("label") == null ? "" : request.getParameter("label").trim();
    if (label.length() == 0) {
      pw.print("{\"ok\":false,\"mesg\":\"Status name is required\"}");
      return;
    }
    String code = statusCodeFromLabel(label);
    /* avoid colliding with built-ins */
    String[] builtins = {"PENDING","ON_TRACK","BEHIND","ON_HOLD","FAILED","NOT_INTERESTED","NO_RESPONSE","COMPLETE","NEW"};
    for (int bi = 0; bi < builtins.length; bi++) {
      if (builtins[bi].equals(code) || builtins[bi].equals(label.toUpperCase().replace(' ','_'))) {
        pw.print("{\"ok\":false,\"mesg\":\"That status already exists\"}");
        return;
      }
    }
    Connection ac = null;
    try {
      ac = getConn();
      String cur = "";
      PreparedStatement psG = ac.prepareStatement(
        "SELECT config_value FROM mvpg_config WHERE entity_id=? AND config_key='ONBOARDING_EXTRA_STATUSES' AND is_active='Y' LIMIT 1");
      psG.setInt(1, cfgEid);
      ResultSet rsG = psG.executeQuery();
      if (rsG.next() && rsG.getString(1) != null) cur = rsG.getString(1).trim();
      rsG.close(); psG.close();
      List<String[]> existing = parseExtraStatuses(cur);
      for (String[] e : existing) {
        if (e[0].equalsIgnoreCase(code) || e[1].equalsIgnoreCase(label)) {
          pw.print("{\"ok\":false,\"mesg\":\"That status already exists\"}");
          return;
        }
      }
      String entry = code + ":" + label;
      String next = cur.length() == 0 ? entry : (cur + "|" + entry);
      PreparedStatement psU = ac.prepareStatement(
        "UPDATE mvpg_config SET config_value=?, UPDATE_USER=? WHERE entity_id=? AND config_key='ONBOARDING_EXTRA_STATUSES'");
      psU.setString(1, next); psU.setString(2, obLoginUser); psU.setInt(3, cfgEid);
      int n = psU.executeUpdate(); psU.close();
      if (n == 0) {
        PreparedStatement psI = ac.prepareStatement(
          "INSERT INTO mvpg_config (entity_id, config_group, config_key, config_label, config_value, config_desc, is_active, CREATE_USER) "
          + "VALUES (?,'ONBOARDING','ONBOARDING_EXTRA_STATUSES','Extra Pipeline Statuses',?, 'Custom pipeline statuses for DA Onboarding','Y',?)");
        psI.setInt(1, cfgEid); psI.setString(2, next); psI.setString(3, obLoginUser);
        psI.executeUpdate(); psI.close();
      }
      pw.print("{\"ok\":true,\"code\":\"" + code.replace("\"","") + "\",\"label\":\"" + label.replace("\\","\\\\").replace("\"","\\\"") + "\"}");
    } catch (Exception ex) {
      pw.print("{\"ok\":false,\"mesg\":\"" + (ex.getMessage()==null?"Save failed":ex.getMessage().replace("\"","'")) + "\"}");
    } finally {
      if (ac != null) try { ac.close(); } catch (Exception e) {}
    }
    return;
  }

  /* ── POST: add custom drug/training status ── */
  if ("POST".equalsIgnoreCase(request.getMethod()) && "addDrugStatus".equals(request.getParameter("action"))) {
    response.setContentType("application/json; charset=UTF-8");
    java.io.PrintWriter pw = response.getWriter();
    String kind = request.getParameter("kind") == null ? "" : request.getParameter("kind").trim();
    String label = request.getParameter("label") == null ? "" : request.getParameter("label").trim();
    String cfgKey = "order".equalsIgnoreCase(kind) ? "ONBOARDING_DRUG_ORDER_STATUSES"
        : ("result".equalsIgnoreCase(kind) ? "ONBOARDING_DRUG_RESULT_STATUSES"
        : ("training".equalsIgnoreCase(kind) ? "ONBOARDING_TRAINING_SCHEDULE_STATUSES" : ""));
    if (cfgKey.length() == 0 || label.length() == 0) {
      pw.print("{\"ok\":false,\"mesg\":\"Status name is required\"}");
      return;
    }
    String code = statusCodeFromLabel(label);
    Connection ac = null;
    try {
      ac = getConn();
      String cur = "";
      PreparedStatement psG = ac.prepareStatement(
        "SELECT config_value FROM mvpg_config WHERE entity_id=? AND config_key=? AND is_active='Y' LIMIT 1");
      psG.setInt(1, cfgEid); psG.setString(2, cfgKey);
      ResultSet rsG = psG.executeQuery();
      if (rsG.next() && rsG.getString(1) != null) cur = rsG.getString(1).trim();
      rsG.close(); psG.close();
      List<String[]> existing = parseExtraStatuses(cur);
      for (String[] e : existing) {
        if (e[0].equalsIgnoreCase(code) || e[1].equalsIgnoreCase(label)) {
          pw.print("{\"ok\":false,\"mesg\":\"That status already exists\"}");
          return;
        }
      }
      String entry = code + ":" + label;
      String next = cur.length() == 0 ? entry : (cur + "|" + entry);
      PreparedStatement psU = ac.prepareStatement(
        "UPDATE mvpg_config SET config_value=?, UPDATE_USER=? WHERE entity_id=? AND config_key=?");
      psU.setString(1, next); psU.setString(2, obLoginUser); psU.setInt(3, cfgEid); psU.setString(4, cfgKey);
      int n = psU.executeUpdate(); psU.close();
      if (n == 0) {
        String cfgLabel = "order".equalsIgnoreCase(kind) ? "Drug Order Statuses"
            : ("result".equalsIgnoreCase(kind) ? "Drug Result Statuses" : "Training Schedule Statuses");
        PreparedStatement psI = ac.prepareStatement(
          "INSERT INTO mvpg_config (entity_id, config_group, config_key, config_label, config_value, config_desc, is_active, CREATE_USER) "
          + "VALUES (?,'ONBOARDING',?,?,?, 'Custom onboarding statuses','Y',?)");
        psI.setInt(1, cfgEid); psI.setString(2, cfgKey); psI.setString(3, cfgLabel);
        psI.setString(4, next); psI.setString(5, obLoginUser);
        psI.executeUpdate(); psI.close();
      }
      pw.print("{\"ok\":true,\"code\":\"" + code.replace("\"","") + "\",\"label\":\"" + label.replace("\\","\\\\").replace("\"","\\\"") + "\"}");
    } catch (Exception ex) {
      pw.print("{\"ok\":false,\"mesg\":\"" + (ex.getMessage()==null?"Save failed":ex.getMessage().replace("\"","'")) + "\"}");
    } finally {
      if (ac != null) try { ac.close(); } catch (Exception e) {}
    }
    return;
  }

  /* ── GET handler: stage log JSON (for history tab in detail panel) ── */
  if ("GET".equalsIgnoreCase(request.getMethod()) && "stagelog".equals(request.getParameter("action"))) {
    String obIdLog = request.getParameter("ob_id");
    Connection cLog = null;
    try {
      cLog = getConn();
      PreparedStatement psLog = cLog.prepareStatement(
        "SELECT STAGE_CODE, STAGE_NAME, STAGE_STATUS, ENTERED_AT, EXITED_AT, " +
        "       DURATION_DAYS, MOVED_BY, NOTES " +
        "FROM da_onboarding_stage_log WHERE ONBOARDING_ID=? ORDER BY ENTERED_AT ASC");
      psLog.setInt(1, Integer.parseInt(obIdLog == null ? "0" : obIdLog));
      ResultSet rsLog = psLog.executeQuery();
      response.setContentType("application/json; charset=UTF-8");
      java.io.PrintWriter pw = response.getWriter();
      pw.print("[");
      boolean first = true;
      while (rsLog.next()) {
        if (!first) pw.print(",");
        first = false;
        pw.print("{");
        pw.print("\"stage\":\"" + (rsLog.getString("STAGE_CODE")==null?"":rsLog.getString("STAGE_CODE").replace("\"","\\\"")) + "\",");
        pw.print("\"name\":\""  + (rsLog.getString("STAGE_NAME")==null?"":rsLog.getString("STAGE_NAME").replace("\"","\\\"")) + "\",");
        pw.print("\"status\":\"" + (rsLog.getString("STAGE_STATUS")==null?"":rsLog.getString("STAGE_STATUS").replace("\"","\\\"")) + "\",");
        pw.print("\"entered\":\"" + (rsLog.getString("ENTERED_AT")==null?"":rsLog.getString("ENTERED_AT")) + "\",");
        pw.print("\"exited\":\""  + (rsLog.getString("EXITED_AT") ==null?"":rsLog.getString("EXITED_AT"))  + "\",");
        pw.print("\"days\":\""    + (rsLog.getString("DURATION_DAYS")==null?"":rsLog.getString("DURATION_DAYS")) + "\",");
        pw.print("\"by\":\""      + (rsLog.getString("MOVED_BY")==null?"":rsLog.getString("MOVED_BY").replace("\"","\\\"")) + "\",");
        pw.print("\"notes\":\""   + (rsLog.getString("NOTES")==null?"":rsLog.getString("NOTES").replace("\"","\\\"").replace("\n"," ")) + "\"");
        pw.print("}");
      }
      pw.print("]");
      pw.flush(); rsLog.close(); psLog.close();
    } catch (Exception ex) {
      response.getWriter().print("[]");
    } finally { if (cLog != null) try { cLog.close(); } catch (Exception e) {} }
    return;
  }

  /* ── GET handler: Excel export ── */
  if ("GET".equalsIgnoreCase(request.getMethod()) && "export".equals(request.getParameter("action"))) {
    int eidEx = 1;
    try { eidEx = Integer.parseInt(obEntityID.isEmpty() ? "1" : obEntityID); } catch (Exception ex) {}
    String exFilter = request.getParameter("exfilter") != null ? request.getParameter("exfilter") : "ALL";
    String exFrom   = request.getParameter("exfrom")   != null ? request.getParameter("exfrom")   : "";
    String exTo     = request.getParameter("exto")     != null ? request.getParameter("exto")     : "";
    Connection cEx = null;
    try {
      cEx = getConn();
      StringBuilder sqlEx = new StringBuilder(
        "SELECT a.first_name, a.last_name, a.email, a.phone, a.avail_type, a.applied_ts, " +
        "       COALESCE(o.current_stage,'S1') as current_stage, " +
        "       COALESCE(o.ob_status,'NEW') as ob_status, " +
        "       o.hold_reason, o.notes, " +
        "       o.s1_date, o.checkr_status, o.checkr_candidate_id, " +
        "       o.s2_status, o.labcorp_order_id, o.drug_test_location, " +
        "       o.drug_test_result, o.s3_result, " +
        "       o.s4_status, o.s4_scheduled_date, " +
        "       o.s5_result, o.s5_day1_date, o.s5_day2_date, " +
        "       o.s6_done, o.s7_done, o.s8_adp_status, " +
        "       o.s9_status, o.s9_day1_date, " +
        "       IFNULL(o.offer_letter_signed,0) AS offer_letter_signed, " +
        "       IFNULL(o.offer_letter_doc_path,'') AS offer_letter_doc_path, " +
        "       o.completed_date " +
        "FROM da_applications a " +
        "LEFT JOIN da_onboarding o ON o.application_id = a.application_id " +
        "WHERE a.entity_id = ? ");
      java.util.List<Object> exParams = new java.util.ArrayList<Object>();
      exParams.add(eidEx);
      if ("PIPELINE".equals(exFilter)) {
        sqlEx.append("AND (o.ob_status IS NULL OR o.ob_status NOT IN ('COMPLETE','FAILED')) ");
        sqlEx.append("AND (o.checkr_status IS NULL OR UPPER(o.checkr_status) NOT IN ('FAIL','FAILED','ADVERSE','ADVERSE_ACTION')) ");
      }
      else if ("HIRED".equals(exFilter)) { sqlEx.append("AND o.ob_status = 'COMPLETE' "); }
      if (!exFrom.isEmpty()) { sqlEx.append("AND DATE(a.applied_ts) >= ? "); exParams.add(exFrom); }
      if (!exTo.isEmpty())   { sqlEx.append("AND DATE(a.applied_ts) <= ? "); exParams.add(exTo); }
      sqlEx.append("ORDER BY a.application_id DESC");
      PreparedStatement psEx = cEx.prepareStatement(sqlEx.toString());
      for (int ei=0; ei<exParams.size(); ei++) {
        Object ep = exParams.get(ei);
        if (ep instanceof Integer) psEx.setInt(ei+1,(Integer)ep);
        else psEx.setString(ei+1, ep.toString());
      }
      ResultSet rsEx = psEx.executeQuery();
      response.setContentType("text/csv; charset=UTF-8");
      response.setHeader("Content-Disposition", "attachment; filename=\"DA_Onboarding_Export.csv\"");
      java.io.PrintWriter pw = response.getWriter();
      /* UTF-8 BOM so Excel auto-detects encoding and opens without import wizard */
      pw.print("﻿");
      String[] hdrs = {"First Name","Last Name","Email","Phone","Availability","Applied Date",
        "Pipeline Stage","Status","Hold Reason","Notes",
        "BG Check Date","Checkr Status","Checkr ID",
        "Drug Test Status","LabCorp Order","Test Location","Drug Result","Drug Notes",
        "Training Status","Training Scheduled Date",
        "Training Notes","Training Day 1 Date","Training Day 2 Date",
        "ADP Done","Orientation Done","Schedule Status",
        "Day 1 Training Status","Day 1 Date","Offer Letter Signed","Offer Letter Path","Completed Date"};
      /* CSV helper: wrap value in quotes, escape internal quotes */
      java.util.function.Function<String,String> csvQ = v -> {
        if (v == null) v = "";
        return "\"" + v.replace("\"", "\"\"") + "\"";
      };
      StringBuilder hdrLine = new StringBuilder();
      for (int hi=0; hi<hdrs.length; hi++) { if (hi>0) hdrLine.append(","); hdrLine.append(csvQ.apply(hdrs[hi])); }
      pw.println(hdrLine.toString());
      String[] SR_STAGES = {
        "S1 Background Check","S2 Drug Test Details","S3 Training Schedule/Day1 & Day2",
        "S4 ADP Onboarding","S5 Orientation","S6 Schedule Fixed","S7 Day 1 On-Road",
        "S8 Offer Letter Signed"
      };
      String[] STAGE_MAP_KEYS = {"S1","S2","S3","S4","S5","S6","S7","S8"};
      while (rsEx.next()) {
        String stg = rsEx.getString("current_stage");
        if ("S9".equals(stg)) stg = "S7";
        String srStage = "New";
        for (int si=0; si<STAGE_MAP_KEYS.length; si++) { if (STAGE_MAP_KEYS[si].equals(stg)) { srStage = SR_STAGES[si]; break; } }
        String[] vals = {
          rsEx.getString("first_name"), rsEx.getString("last_name"), rsEx.getString("email"), rsEx.getString("phone"),
          rsEx.getString("avail_type"), rsEx.getString("applied_ts") != null ? rsEx.getString("applied_ts").substring(0,10) : "",
          srStage, rsEx.getString("ob_status"), rsEx.getString("hold_reason"), rsEx.getString("notes"),
          rsEx.getString("s1_date"), rsEx.getString("checkr_status"), rsEx.getString("checkr_candidate_id"),
          rsEx.getString("s2_status"), rsEx.getString("labcorp_order_id"), rsEx.getString("drug_test_location"),
          rsEx.getString("drug_test_result"), rsEx.getString("s3_result"),
          rsEx.getString("s4_status"), rsEx.getString("s4_scheduled_date"),
          rsEx.getString("s5_result"), rsEx.getString("s5_day1_date"), rsEx.getString("s5_day2_date"),
          rsEx.getString("s6_done"), rsEx.getString("s7_done"), rsEx.getString("s8_adp_status"),
          rsEx.getString("s9_status"), rsEx.getString("s9_day1_date"),
          rsEx.getString("offer_letter_signed"), rsEx.getString("offer_letter_doc_path"),
          rsEx.getString("completed_date")
        };
        StringBuilder row = new StringBuilder();
        for (int vi=0; vi<vals.length; vi++) { if (vi>0) row.append(","); row.append(csvQ.apply(vals[vi])); }
        pw.println(row.toString());
      }
      pw.flush();
      rsEx.close(); psEx.close();
    } catch (Exception ex) {
      response.getWriter().println("Export error: " + ex.getMessage());
    } finally {
      if (cEx != null) try { cEx.close(); } catch (Exception e) {}
    }
    return;
  }

  /* ── POST handler: edit applicant basic info ── */
  String saveErr = null;
  if ("POST".equalsIgnoreCase(request.getMethod()) && "updateApplicant".equals(request.getParameter("action"))) {
    String appIdStr = gp(request, "application_id");
    Connection wa = null;
    try {
      int aId = Integer.parseInt(appIdStr);
      wa = getConn();
      PreparedStatement psA = wa.prepareStatement(
        "UPDATE da_applications SET first_name=?, last_name=?, email=?, phone=?, avail_type=?, app_status=?, UPDATE_USER=? WHERE application_id=?");
      psA.setString(1, gp(request, "first_name"));
      psA.setString(2, gp(request, "last_name"));
      psA.setString(3, gp(request, "email"));
      psA.setString(4, gp(request, "phone"));
      psA.setString(5, gp(request, "avail_type"));
      psA.setString(6, gp(request, "app_status").isEmpty() ? "PENDING" : gp(request, "app_status"));
      psA.setString(7, obLoginUser);
      psA.setInt(8, aId);
      psA.executeUpdate(); psA.close();
    } catch (Exception ex) {
      saveErr = "Applicant update failed: " + ex.getMessage();
    } finally {
      if (wa != null) try { wa.close(); } catch (Exception e) {}
    }
    if (saveErr == null) {
      response.sendRedirect("DAOnboarding.jsp?saved=1");
      return;
    }
  }

  /* ── POST handler: save stage edit (supports multipart for drug-test doc) ── */
  Map<String,String> updateForm = null;
  FileItem drugTestFileItem = null;
  FileItem offerLetterFileItem = null;
  String updateAction = request.getParameter("action");
  if ("POST".equalsIgnoreCase(request.getMethod()) && ServletFileUpload.isMultipartContent(request)) {
    try {
      updateForm = new HashMap<String,String>();
      File tmpDir = new File(ServerUploadPaths.getTemp());
      if (!tmpDir.isDirectory()) tmpDir.mkdirs();
      DiskFileItemFactory factory = new DiskFileItemFactory();
      factory.setSizeThreshold(1024 * 1024);
      factory.setRepository(tmpDir);
      ServletFileUpload upload = new ServletFileUpload(factory);
      upload.setFileSizeMax(50L * 1024L * 1024L);
      upload.setSizeMax(100L * 1024L * 1024L);
      List<?> items = upload.parseRequest(request);
      for (Object obj : items) {
        FileItem it = (FileItem) obj;
        if (it.isFormField()) {
          updateForm.put(it.getFieldName(), it.getString("UTF-8"));
        } else if ("drug_test_doc".equals(it.getFieldName())
            && it.getName() != null && it.getName().trim().length() > 0) {
          drugTestFileItem = it;
        } else if ("offer_letter_doc".equals(it.getFieldName())
            && it.getName() != null && it.getName().trim().length() > 0) {
          offerLetterFileItem = it;
        }
      }
      if (updateForm.get("action") != null) updateAction = updateForm.get("action").trim();
    } catch (Exception mex) {
      saveErr = "Upload parse failed: " + mex.getMessage();
      updateAction = "";
    }
  }

  if ("POST".equalsIgnoreCase(request.getMethod()) && "update".equals(updateAction)) {
    String obIdStr = gpMap(updateForm, request, "onboarding_id");
    String appIdStr2 = gpMap(updateForm, request, "app_id_for_create");
    Connection wc  = null;
    try {
      int obId = 0;
      int appId2num = Integer.parseInt(appIdStr2.isEmpty() ? "0" : appIdStr2);
      int eid2 = 1;
      try { eid2 = Integer.parseInt(obEntityID.isEmpty() ? "1" : obEntityID); } catch (Exception ex2) { eid2 = 1; }

      wc = getConn();
      ensureDrugDocColumn(wc);
      ensureStageNoteColumns(wc);
      migratePipelineStages(wc);
      if (obIdStr.isEmpty() || "0".equals(obIdStr)) {
        obId = resolveOrCreateOnboardingId(wc, appId2num, eid2, obLoginUser);
      } else {
        obId = Integer.parseInt(obIdStr);
        PreparedStatement psChk = wc.prepareStatement("SELECT 1 FROM da_onboarding WHERE onboarding_id=?");
        psChk.setInt(1, obId);
        ResultSet rsChk = psChk.executeQuery();
        boolean exists = rsChk.next();
        rsChk.close(); psChk.close();
        if (!exists && appId2num > 0) {
          obId = resolveOrCreateOnboardingId(wc, appId2num, eid2, obLoginUser);
        }
      }

      /* Fetch old state before updating */
      String oldStage = ""; String oldStatus = "";
      int appId2 = appId2num; long stageAgeDays = 0;
      PreparedStatement psSel = wc.prepareStatement(
        "SELECT current_stage, ob_status, application_id, entity_id, " +
        "       DATEDIFF(NOW(), COALESCE(stage_entered_at, NOW())) as stage_days " +
        "FROM da_onboarding WHERE onboarding_id=?");
      psSel.setInt(1, obId);
      ResultSet rs0 = psSel.executeQuery();
      if (rs0.next()) {
        oldStage  = rs0.getString(1) == null ? "" : rs0.getString(1);
        oldStatus = rs0.getString(2) == null ? "" : rs0.getString(2);
        appId2    = rs0.getInt(3);
        eid2      = rs0.getInt(4);
        stageAgeDays = rs0.getLong(5);
      }
      rs0.close(); psSel.close();

      String newStage = gpMap(updateForm, request, "current_stage");
      if (newStage.isEmpty()) newStage = oldStage;
      /* Retired Day-1 code S9 → S7 (do not remap new S8 Offer Letter) */
      if ("S9".equals(newStage)) newStage = "S7";

      String s2Entered = dateOnly(gpMap(updateForm, request, "s2_entered_at"));
      String s2Exited  = dateOnly(gpMap(updateForm, request, "s2_exited_at"));
      /* Legacy S3 timestamp columns stay in sync with S2 drug-test dates */
      String s3Entered = dateOnly(gpMap(updateForm, request, "s3_entered_at"));
      String s3Exited  = dateOnly(gpMap(updateForm, request, "s3_exited_at"));
      if (s3Entered.isEmpty() && !s2Entered.isEmpty()) s3Entered = s2Entered;
      if (s3Exited.isEmpty() && !s2Exited.isEmpty()) s3Exited = s2Exited;

      String s4Entered = dateOnly(gpMap(updateForm, request, "s4_entered_at"));
      String s4Exited  = dateOnly(gpMap(updateForm, request, "s4_exited_at"));
      /* Keep legacy S5 timestamps in sync with combined training stage dates */
      String s5Entered = dateOnly(gpMap(updateForm, request, "s5_entered_at"));
      String s5Exited  = dateOnly(gpMap(updateForm, request, "s5_exited_at"));
      if (s5Entered.isEmpty() && !s4Entered.isEmpty()) s5Entered = s4Entered;
      if (s5Exited.isEmpty() && !s4Exited.isEmpty()) s5Exited = s4Exited;

      String fn = "", ln = "";
      PreparedStatement psNm = wc.prepareStatement(
        "SELECT first_name, last_name FROM da_applications WHERE application_id=?");
      psNm.setInt(1, appId2);
      ResultSet rsNm = psNm.executeQuery();
      if (rsNm.next()) {
        fn = rsNm.getString(1) == null ? "" : rsNm.getString(1);
        ln = rsNm.getString(2) == null ? "" : rsNm.getString(2);
      }
      rsNm.close(); psNm.close();

      String drugDocPath = "";
      if (drugTestFileItem != null) {
        drugDocPath = saveDrugTestDoc(drugTestFileItem, appId2, fn, ln);
      }
      String offerDocPath = "";
      if (offerLetterFileItem != null) {
        offerDocPath = saveNamedAppDoc(offerLetterFileItem, appId2, fn, ln, "offer_letter");
      }
      int offerSigned = parseDoneFlag(gpMap(updateForm, request, "offer_letter_signed"));
      String checkrStatus = gpMap(updateForm, request, "checkr_status");
      String offerIn = dateOnly(gpMap(updateForm, request, "offer_letter_entered_at"));
      String offerOut = dateOnly(gpMap(updateForm, request, "offer_letter_exited_at"));
      String s4Status = gpMap(updateForm, request, "s4_status");
      if ("__ADD_NEW__".equals(s4Status)) s4Status = "";
      String s2Status = gpMap(updateForm, request, "s2_status");
      if ("__ADD_NEW__".equals(s2Status)) s2Status = "";
      String drugResult = gpMap(updateForm, request, "drug_test_result");
      if ("__ADD_NEW__".equals(drugResult)) drugResult = "";
      String s4Sched = dateOnly(gpMap(updateForm, request, "s4_scheduled_date"));
      String s5Day1 = dateOnly(gpMap(updateForm, request, "s5_day1_date"));
      String s5Day2 = dateOnly(gpMap(updateForm, request, "s5_day2_date"));
      String s9Day1 = dateOnly(gpMap(updateForm, request, "s9_day1_date"));
      String completedDate = dateOnly(gpMap(updateForm, request, "completed_date"));

      /* Offer letter signed = pipeline complete (S8). Day 1 alone must not complete. */
      if (offerSigned == 1) {
        newStage = "S8";
        if (completedDate.isEmpty()) {
          java.text.SimpleDateFormat ymdDone = new java.text.SimpleDateFormat("yyyy-MM-dd");
          completedDate = ymdDone.format(new java.util.Date());
        }
        if (offerOut.isEmpty()) offerOut = completedDate;
      }

      /* Build UPDATE — NULLIF converts empty string to NULL for date/optional fields */
      String upSql =
        "UPDATE da_onboarding SET " +
        "current_stage=?, ob_status=?, notes=?, hold_reason=NULLIF(?,\"\"), completed_date=NULLIF(?,\"\"), " +
        "s1_date=NULLIF(?,\"\"), checkr_candidate_id=NULLIF(?,\"\"), checkr_status=NULLIF(?,\"\"), " +
        "s2_status=NULLIF(?,\"\"), labcorp_order_id=NULLIF(?,\"\"), drug_test_location=NULLIF(?,\"\"), " +
        "s3_result=NULLIF(?,\"\"), drug_test_result=NULLIF(?,\"\"), " +
        "s4_status=NULLIF(?,\"\"), s4_scheduled_date=NULLIF(?,\"\"), " +
        "s5_result=NULLIF(?,\"\"), s5_day1_date=NULLIF(?,\"\"), s5_day2_date=NULLIF(?,\"\"), " +
        "s6_done=?, s6_notes=NULLIF(?,\"\"), " +
        "s7_done=?, s7_notes=NULLIF(?,\"\"), " +
        "s8_adp_status=NULLIF(?,\"\"), " +
        "s9_status=NULLIF(?,\"\"), s9_day1_date=NULLIF(?,\"\"), " +
        "offer_letter_signed=?, offer_letter_entered_at=NULLIF(?,\"\"), offer_letter_exited_at=NULLIF(?,\"\"), " +
        "s1_entered_at=NULLIF(?,\"\"), s1_exited_at=NULLIF(?,\"\"), " +
        "s2_entered_at=NULLIF(?,\"\"), s2_exited_at=NULLIF(?,\"\"), " +
        "s3_entered_at=NULLIF(?,\"\"), s3_exited_at=NULLIF(?,\"\"), " +
        "s4_entered_at=NULLIF(?,\"\"), s4_exited_at=NULLIF(?,\"\"), " +
        "s5_entered_at=NULLIF(?,\"\"), s5_exited_at=NULLIF(?,\"\"), " +
        "s6_entered_at=NULLIF(?,\"\"), s6_exited_at=NULLIF(?,\"\"), " +
        "s7_entered_at=NULLIF(?,\"\"), s7_exited_at=NULLIF(?,\"\"), " +
        "s8_entered_at=NULLIF(?,\"\"), s8_exited_at=NULLIF(?,\"\"), " +
        "s9_entered_at=NULLIF(?,\"\"), s9_exited_at=NULLIF(?,\"\"), " +
        (drugDocPath.length() > 0 ? "drug_test_doc_path=?, " : "") +
        (offerDocPath.length() > 0 ? "offer_letter_doc_path=?, " : "") +
        "UPDATE_USER=? " +
        "WHERE onboarding_id=?";

      PreparedStatement psUp = wc.prepareStatement(upSql);
      int p = 1;
      psUp.setString(p++, newStage);
      /* Auto-compute status — keep manual terminal / outcome statuses */
      String manualStatus = gpMap(updateForm, request, "ob_status");
      if ("__ADD_NEW__".equals(manualStatus)) manualStatus = oldStatus;
      String autoStatus;
      if (isFailedBackground(checkrStatus)) {
        /* Failed background = cannot hire; drop off active pipeline */
        autoStatus = "FAILED";
      } else if (offerSigned == 1) {
        autoStatus = "COMPLETE";
      } else if (isManualPipelineStatus(manualStatus) && !"COMPLETE".equalsIgnoreCase(manualStatus)) {
        autoStatus = manualStatus.toUpperCase();
      } else if ("COMPLETE".equalsIgnoreCase(manualStatus) && offerSigned != 1) {
        /* COMPLETE only allowed after offer letter signed */
        autoStatus = "ON_TRACK";
      } else {
        /* Has stage data? Determine ON_TRACK vs BEHIND vs PENDING */
        boolean hasStageData =
          !gpMap(updateForm, request,"s1_date").isEmpty()           || !s2Status.isEmpty()  ||
          !gpMap(updateForm, request,"s3_result").isEmpty()          || !drugResult.isEmpty() ||
          !s4Status.isEmpty()  ||
          !s4Sched.isEmpty()  || !gpMap(updateForm, request,"s5_result").isEmpty()  ||
          !s5Day1.isEmpty()        || !"0".equals(String.valueOf(parseDoneFlag(gpMap(updateForm, request,"s6_done")))) ||
          !gpMap(updateForm, request,"s6_notes").isEmpty()            || !"0".equals(String.valueOf(parseDoneFlag(gpMap(updateForm, request,"s7_done")))) ||
          !gpMap(updateForm, request,"s7_notes").isEmpty()            || !gpMap(updateForm, request,"s8_adp_status").isEmpty() ||
          !s9Day1.isEmpty() || offerSigned == 1 ||
          !gpMap(updateForm, request,"s1_entered_at").isEmpty()       || !gpMap(updateForm, request,"s2_entered_at").isEmpty() ||
          !gpMap(updateForm, request,"s4_entered_at").isEmpty();
        if (!hasStageData) {
          autoStatus = "PENDING";
        } else if (stageAgeDays > behindDays) {
          autoStatus = "BEHIND";
        } else {
          autoStatus = "ON_TRACK";
        }
      }
      psUp.setString(p++, autoStatus);
      psUp.setString(p++, gpMap(updateForm, request, "notes"));
      psUp.setString(p++, gpMap(updateForm, request, "hold_reason"));
      psUp.setString(p++, completedDate);
      psUp.setString(p++, dateOnly(gpMap(updateForm, request, "s1_date")));
      psUp.setString(p++, gpMap(updateForm, request, "checkr_candidate_id"));
      psUp.setString(p++, checkrStatus);
      psUp.setString(p++, s2Status);
      psUp.setString(p++, gpMap(updateForm, request, "labcorp_order_id"));
      psUp.setString(p++, gpMap(updateForm, request, "drug_test_location"));
      psUp.setString(p++, gpMap(updateForm, request, "s3_result"));
      psUp.setString(p++, drugResult);
      psUp.setString(p++, s4Status);
      psUp.setString(p++, s4Sched);
      psUp.setString(p++, gpMap(updateForm, request, "s5_result"));
      psUp.setString(p++, s5Day1);
      psUp.setString(p++, s5Day2);
      psUp.setInt(p++, parseDoneFlag(gpMap(updateForm, request, "s6_done")));
      psUp.setString(p++, gpMap(updateForm, request, "s6_notes"));
      psUp.setInt(p++, parseDoneFlag(gpMap(updateForm, request, "s7_done")));
      psUp.setString(p++, gpMap(updateForm, request, "s7_notes"));
      psUp.setString(p++, gpMap(updateForm, request, "s8_adp_status"));
      psUp.setString(p++, gpMap(updateForm, request, "s9_status"));
      psUp.setString(p++, s9Day1);
      psUp.setInt(p++, offerSigned);
      psUp.setString(p++, offerIn);
      psUp.setString(p++, offerOut);
      /* Stage Entered/Exited: date-only YYYY-MM-DD */
      psUp.setString(p++, dateOnly(gpMap(updateForm, request, "s1_entered_at")));
      psUp.setString(p++, dateOnly(gpMap(updateForm, request, "s1_exited_at")));
      psUp.setString(p++, s2Entered);
      psUp.setString(p++, s2Exited);
      psUp.setString(p++, s3Entered);
      psUp.setString(p++, s3Exited);
      psUp.setString(p++, s4Entered);
      psUp.setString(p++, s4Exited);
      psUp.setString(p++, s5Entered);
      psUp.setString(p++, s5Exited);
      for (int si = 6; si <= 9; si++) {
        psUp.setString(p++, dateOnly(gpMap(updateForm, request, "s"+si+"_entered_at")));
        psUp.setString(p++, dateOnly(gpMap(updateForm, request, "s"+si+"_exited_at")));
      }
      if (drugDocPath.length() > 0) psUp.setString(p++, drugDocPath);
      if (offerDocPath.length() > 0) psUp.setString(p++, offerDocPath);
      psUp.setString(p++, obLoginUser);
      psUp.setInt(p++, obId);
      psUp.executeUpdate(); psUp.close();

      /* Mirror offer letter onto da_applications for employee History / form docs */
      if (appId2 > 0) {
        try {
        PreparedStatement psApp = wc.prepareStatement(
          "UPDATE da_applications SET offer_letter_signed=?, " +
          (offerDocPath.length() > 0 ? "offer_letter_file_path=?, " : "") +
          "UPDATE_USER=? WHERE application_id=?");
        int ap = 1;
        psApp.setInt(ap++, offerSigned);
        if (offerDocPath.length() > 0) psApp.setString(ap++, offerDocPath);
        psApp.setString(ap++, obLoginUser);
        psApp.setInt(ap++, appId2);
        psApp.executeUpdate(); psApp.close();
        } catch (Exception appEx) {
          System.out.println("onboarding offer mirror: " + appEx.getMessage());
        }
      }

      /* Stage transition: close old log entry, open new one */
      if (!oldStage.isEmpty() && !oldStage.equals(newStage)) {
        try {
        PreparedStatement psClose = wc.prepareStatement(
          "UPDATE da_onboarding_stage_log SET EXITED_AT=NOW(), STAGE_STATUS='COMPLETE', UPDATE_USER=? " +
          "WHERE ONBOARDING_ID=? AND STAGE_CODE=? AND EXITED_AT IS NULL ORDER BY ENTERED_AT DESC LIMIT 1");
        psClose.setString(1, obLoginUser); psClose.setInt(2, obId); psClose.setString(3, oldStage);
        psClose.executeUpdate(); psClose.close();

        String newStageName = newStage;
        for (int si = 0; si < STAGE_KEYS.length; si++) {
          if (STAGE_KEYS[si].equals(newStage)) { newStageName = STAGE_LABELS[si]; break; }
        }
        int newLogId = getNextSeqID(wc, "STAGE_LOG_ID");
        String openSql =
          "INSERT INTO da_onboarding_stage_log " +
          "(STAGE_LOG_ID,ONBOARDING_ID,APPLICATION_ID,ENTITY_ID,STATION,STAGE_CODE,STAGE_NAME,STAGE_STATUS,ENTERED_AT,MOVED_BY,CREATE_USER) " +
          "VALUES (?,?,?,?,'DNK7',?,?,'IN_PROGRESS',NOW(),?,?)";
        PreparedStatement psOpen = wc.prepareStatement(openSql);
        psOpen.setInt(1, newLogId); psOpen.setInt(2, obId); psOpen.setInt(3, appId2);
        psOpen.setInt(4, eid2); psOpen.setString(5, newStage); psOpen.setString(6, newStageName);
        psOpen.setString(7, obLoginUser); psOpen.setString(8, obLoginUser);
        try {
          psOpen.executeUpdate();
        } catch (SQLException dupLog) {
          psOpen.close();
          newLogId = seqSeed(wc, "STAGE_LOG_ID") + 1;
          PreparedStatement puFix = wc.prepareStatement("UPDATE seq SET val=? WHERE name='STAGE_LOG_ID'");
          puFix.setInt(1, newLogId); puFix.executeUpdate(); puFix.close();
          psOpen = wc.prepareStatement(openSql);
          psOpen.setInt(1, newLogId); psOpen.setInt(2, obId); psOpen.setInt(3, appId2);
          psOpen.setInt(4, eid2); psOpen.setString(5, newStage); psOpen.setString(6, newStageName);
          psOpen.setString(7, obLoginUser); psOpen.setString(8, obLoginUser);
          psOpen.executeUpdate();
        }
        psOpen.close();

        /* Set stage_entered_at on the main record */
        PreparedStatement psEnt = wc.prepareStatement(
          "UPDATE da_onboarding SET stage_entered_at=NOW() WHERE onboarding_id=?");
        psEnt.setInt(1, obId); psEnt.executeUpdate(); psEnt.close();
        } catch (Exception logEx) {
          System.out.println("onboarding stage log: " + logEx.getMessage());
        }
      }

      /* No auto-complete on Day 1 — COMPLETE only when offer letter signed (handled above). */

    } catch (Exception ex) {
      saveErr = "Save failed: " + ex.getMessage();
    } finally {
      if (wc != null) try { wc.close(); } catch (Exception e) {}
    }
    if (saveErr == null) {
      response.sendRedirect("DAOnboarding.jsp?saved=1");
      return;
    }
  }

  /* ── Login gate — redirect if no session ── */
  if (obLoginUser.isEmpty()) {
    response.sendRedirect("home.jsp?requireLogin=1");
    return;
  }

  /* ── Flash messages ── */
  String saveMsg = saveErr != null ? saveErr : ("1".equals(request.getParameter("saved")) ? "Changes saved successfully." : null);
  boolean saveMsgOk = saveErr == null && saveMsg != null;

  /* ── Filters ── */
  String filterStatus = request.getParameter("filterStatus") != null ? request.getParameter("filterStatus") : "ALL";
  String filterStage  = request.getParameter("filterStage")  != null ? request.getParameter("filterStage")  : "ALL";
  String search       = request.getParameter("search")       != null ? request.getParameter("search").trim() : "";

  /* ── Data fetch ── */
  List<Map<String,String>> rows = new ArrayList<Map<String,String>>();
  String dbError = null;
  int total = 0, totalHired = 0;
  int cntNew = 0, cntBgDone = 0, cntDrugSent = 0, cntDrugDone = 0;
  int cntTrainSched = 0, cntTrainDone = 0, cntAdpPend = 0, cntAdpDone = 0, cntOrient = 0, cntDay1Pend = 0;

  Connection conn = null;
  try {
    conn = getConn();
    ensureAppDocColumns(conn);
    ensureDrugDocColumn(conn);
    ensureStageNoteColumns(conn);
    migratePipelineStages(conn);
    markFailedBackgroundOffPipeline(conn);
    StringBuilder sql = new StringBuilder(
      "SELECT a.application_id, a.first_name, a.last_name, a.email, a.phone, " +
      "       a.app_status, a.avail_type, a.applied_ts, " +
      "       a.dl_file_path, a.ssn_file_path, a.wp_front_file_path, a.wp_back_file_path, " +
      "       a.dl_drive_url, a.ssn_drive_url, a.wp_front_drive_url, a.wp_back_drive_url, " +
      "       IFNULL(a.offer_letter_file_path,'') AS app_offer_letter_file_path, " +
      "       IFNULL(a.offer_letter_drive_url,'') AS app_offer_letter_drive_url, " +
      "       IFNULL(a.offer_letter_signed,0) AS app_offer_letter_signed, " +
      "       o.onboarding_id, o.current_stage, " +
      "       CASE WHEN o.ob_status IS NOT NULL THEN o.ob_status " +
      "            WHEN o.onboarding_id IS NULL THEN 'NEW' " +
      "            WHEN IFNULL(o.offer_letter_signed,0)=1 THEN 'COMPLETE' " +
      "            WHEN (o.s1_date IS NOT NULL OR o.s1_entered_at IS NOT NULL OR o.s2_status IS NOT NULL) " +
      "                 AND DATEDIFF(NOW(),COALESCE(o.stage_entered_at,o.s1_entered_at,a.applied_ts)) > " + behindDays + " THEN 'BEHIND' " +
      "            WHEN (o.s1_date IS NOT NULL OR o.s1_entered_at IS NOT NULL OR o.s2_status IS NOT NULL OR o.s4_scheduled_date IS NOT NULL OR o.s9_day1_date IS NOT NULL) THEN 'ON_TRACK' " +
      "            ELSE 'PENDING' END AS ob_status, " +
      "       o.s1_date, o.s2_status, o.s3_result, o.s4_status, o.s4_scheduled_date, " +
      "       o.s5_result, o.s5_day1_date, o.s5_day2_date, o.s6_done, o.s6_notes, o.s7_done, o.s7_notes, o.s8_adp_status, " +
      "       o.s9_status, o.s9_day1_date, o.completed_date, o.notes, o.hold_reason, " +
      "       o.checkr_candidate_id, o.checkr_status, " +
      "       o.labcorp_order_id, o.drug_test_result, o.drug_test_location, " +
      "       IFNULL(o.drug_test_doc_path,'') AS drug_test_doc_path, " +
      "       IFNULL(o.offer_letter_doc_path,'') AS offer_letter_doc_path, " +
      "       IFNULL(o.offer_letter_signed,0) AS offer_letter_signed, " +
      "       o.offer_letter_entered_at, o.offer_letter_exited_at, " +
      "       o.s1_entered_at, o.s1_exited_at, " +
      "       o.s2_entered_at, o.s2_exited_at, " +
      "       o.s3_entered_at, o.s3_exited_at, " +
      "       o.s4_entered_at, o.s4_exited_at, " +
      "       o.s5_entered_at, o.s5_exited_at, " +
      "       o.s6_entered_at, o.s6_exited_at, " +
      "       o.s7_entered_at, o.s7_exited_at, " +
      "       o.s8_entered_at, o.s8_exited_at, " +
      "       o.s9_entered_at, o.s9_exited_at, " +
      "       o.stage_entered_at, o.stage_days " +
      "FROM da_applications a " +
      "LEFT JOIN da_onboarding o ON o.application_id = a.application_id " +
      "WHERE a.entity_id = ? "
    );
    List<Object> params = new ArrayList<Object>();
    int eid = 1;
    try { eid = Integer.parseInt(obEntityID.isEmpty() ? "1" : obEntityID); } catch (Exception ex) { eid = 1; }
    params.add(eid);

    /* Exclude completed hires and failed background from active pipeline by default */
    if (!filterStatus.equals("ALL")) {
      if ("NEW".equals(filterStatus)) {
        sql.append("AND (o.onboarding_id IS NULL OR o.ob_status = 'NEW' OR (o.ob_status IS NULL AND (o.current_stage IS NULL OR o.current_stage = ''))) ");
      } else if ("FAILED".equals(filterStatus)) {
        sql.append("AND (o.ob_status = 'FAILED' OR UPPER(IFNULL(o.checkr_status,'')) IN ('FAIL','FAILED','ADVERSE','ADVERSE_ACTION')) ");
      } else {
        sql.append("AND o.ob_status = ? ");
        params.add(filterStatus);
      }
    }
    else {
      sql.append("AND (o.ob_status IS NULL OR o.ob_status NOT IN ('COMPLETE','FAILED')) ");
      sql.append("AND (o.checkr_status IS NULL OR UPPER(o.checkr_status) NOT IN ('FAIL','FAILED','ADVERSE','ADVERSE_ACTION')) ");
    }
    if (!filterStage.equals("ALL"))  {
      if ("S3".equals(filterStage)) {
        sql.append("AND o.current_stage='S3' ");
      } else {
        sql.append("AND o.current_stage = ? "); params.add(filterStage);
      }
    }
    if (!search.isEmpty()) {
      sql.append("AND (a.first_name LIKE ? OR a.last_name LIKE ? OR a.email LIKE ?) ");
      params.add("%" + search + "%"); params.add("%" + search + "%"); params.add("%" + search + "%");
    }
    sql.append("ORDER BY a.application_id DESC");

    PreparedStatement ps = conn.prepareStatement(sql.toString());
    for (int i = 0; i < params.size(); i++) {
      Object param = params.get(i);
      if (param instanceof Integer) ps.setInt(i + 1, (Integer) param);
      else ps.setString(i + 1, param.toString());
    }
    ResultSet rs = ps.executeQuery();
    ResultSetMetaData meta = rs.getMetaData();
    while (rs.next()) {
      Map<String,String> row = new LinkedHashMap<String,String>();
      for (int i = 1; i <= meta.getColumnCount(); i++) {
        String v = rs.getString(i);
        row.put(meta.getColumnName(i).toLowerCase(), v == null ? "" : v);
      }
      rows.add(row);
      total++;
      /* Stage funnel KPIs (mutually exclusive by current stage) */
      String obId = row.get("onboarding_id");
      String stage = row.get("current_stage");
      String st = row.get("ob_status");
      if (st == null) st = "";
      if (stage == null) stage = "";
      if (isFailedOffPipeline(st, row.get("checkr_status"))) {
        continue;
      }
      boolean isNew = (obId == null || obId.isEmpty())
          || "NEW".equalsIgnoreCase(st)
          || stage.isEmpty();
      if (isNew) {
        cntNew++;
      } else if ("S1".equalsIgnoreCase(stage)) {
        cntBgDone++;
      } else if ("S2".equalsIgnoreCase(stage)) {
        cntDrugSent++;
      } else if ("S3".equalsIgnoreCase(stage)) {
        cntTrainSched++;
      } else if ("S4".equalsIgnoreCase(stage)) {
        String s6 = row.get("s6_done");
        if (s6 == null || s6.isEmpty() || "0".equals(s6)) cntAdpPend++;
        else cntAdpDone++;
      } else if ("S5".equalsIgnoreCase(stage)) {
        cntOrient++;
      } else if ("S6".equalsIgnoreCase(stage)) {
        String s8 = row.get("s8_adp_status");
        if (s8 != null && "FIXED".equalsIgnoreCase(s8)) cntAdpDone++;
        else cntAdpPend++;
      } else if ("S7".equalsIgnoreCase(stage)) {
        String day1 = row.get("s9_day1_date");
        if (day1 == null || day1.isEmpty()) cntDay1Pend++;
      }
    }
    rs.close(); ps.close();

    PreparedStatement psHc = conn.prepareStatement(
      "SELECT COUNT(*) FROM da_onboarding WHERE entity_id=? AND ob_status='COMPLETE'");
    psHc.setInt(1, eid);
    ResultSet rsHc = psHc.executeQuery();
    if (rsHc.next()) totalHired = rsHc.getInt(1);
    rsHc.close(); psHc.close();

  } catch (Exception ex) {
    dbError = ex.getMessage();
  } finally {
    if (conn != null) try { conn.close(); } catch (Exception e) {}
  }

  /* ── Shell setup for shared MVPx menu ── */
%>
<jsp:useBean id="_recordBean" class="com.beans.SearchBean" scope="request" />
<jsp:useBean id="_errorBean" class="com.beans.ErrorBean" scope="request" />
<%
int submitType = SubmitType.SEARCH;
_recordBean.setController("DAOnboarding");
_recordBean.setDisplayName("DA Onboarding Pipeline");
request.setAttribute("loginUser", obLoginUser);
request.setAttribute("loginUserRoles", obLoginRoles);
request.setAttribute("entityID", obEntityID);
request.setAttribute("loginUserDisplayName", obDispName);
request.setAttribute("loginUserID", obLoginUserID);
request.setAttribute("shellNoForm", "yes");
request.setAttribute("hideTopbarSearch", "yes");
%>
<!DOCTYPE html>
<html lang="en">
<%@ include file="includeHeader.jsp"%>
<script>
function validatePageData(submitType, isValid) { return isValid; }
</script>
<style>
/* DA Onboarding Pipeline — full-width, readable fonts */
.ob-shell   { display:flex; flex-direction:column; height:calc(100vh - 96px); overflow:hidden; }
.ob-hdr     { display:flex; align-items:center; justify-content:space-between; gap:12px; margin-bottom:10px; flex-shrink:0; }
.ob-hdr-left h1 { font-size:22px; font-weight:900; color:#0f172a; margin:0; line-height:1.2; }
.ob-hdr-left p  { font-size:13px; color:#64748b; margin:3px 0 0; }
.ob-hdr-right   { display:flex; gap:6px; flex-shrink:0; flex-wrap:wrap; }

/* KPI strip */
.ob-kpi-strip { display:flex; gap:6px; margin-bottom:10px; flex-shrink:0; flex-wrap:wrap; }
.ob-kpi-pill  { background:#fff; border:1px solid #e2e8f0; border-radius:8px;
                 padding:8px 12px; flex:1 1 110px; display:flex; align-items:center; gap:8px; min-width:110px;
                 text-decoration:none; color:inherit; transition:border-color .15s, box-shadow .15s; }
a.ob-kpi-pill:hover { border-color:#94a3b8; box-shadow:0 1px 4px rgba(15,23,42,.08); }
.ob-kpi-bar   { width:3px; height:28px; border-radius:2px; flex-shrink:0; }
.ob-kpi-val   { font-size:20px; font-weight:900; color:#0f172a; line-height:1; }
.ob-kpi-lbl   { font-size:11px; color:#64748b; margin-top:2px; line-height:1.2; font-weight:600; }

/* Full-width body (reports moved to Onboarding Dashboard) */
.ob-body  { display:flex; flex:1; overflow:hidden; min-height:0; }
.ob-left  { flex:1; display:flex; flex-direction:column; overflow:hidden; min-width:0; gap:8px; }
.ob-tbl-wrap { flex:1; overflow:auto; border:1px solid #e2e8f0; border-radius:12px; background:#fff; min-height:0;
               scrollbar-width:thin; scrollbar-color:#94A3B8 #E2E8F0; }
.ob-tbl-wrap::-webkit-scrollbar { width:12px; height:12px; }
.ob-tbl-wrap::-webkit-scrollbar-track { background:#E2E8F0; border-radius:6px; }
.ob-tbl-wrap::-webkit-scrollbar-thumb { background:#94A3B8; border-radius:6px; }
.ob-tbl-wrap::-webkit-scrollbar-thumb:hover { background:#64748B; }

/* Filter bar */
.filter-bar { display:flex; gap:10px; align-items:center; flex-wrap:wrap; margin-bottom:20px; }
.filter-bar select, .filter-bar input {
  padding:9px 12px; border:1px solid #d1d5db; border-radius:7px;
  font-size:14px; font-family:inherit; color:#1e293b; background:#fff; }
.filter-bar input { width:240px; }
.btn-filter { padding:9px 18px; background:#2563eb; color:#fff; border:none;
               border-radius:7px; font-size:14px; font-weight:600; cursor:pointer; }
.btn-clear  { font-size:14px; color:#64748b; text-decoration:none; }

/* Stage dots — stretch across the Stage Progress column */
.stage-track { display:flex; align-items:center; width:100%; min-width:240px; gap:0; }
.st-dot { width:26px; height:26px; border-radius:50%; font-size:11px; font-weight:700;
           display:flex; align-items:center; justify-content:center; flex-shrink:0; z-index:1; }
.st-done    { background:#16a34a; color:#fff; }
.st-active  { background:#2563eb; color:#fff; box-shadow:0 0 0 3px #eff6ff; }
.st-pending { background:#e2e8f0; color:#94a3b8; }
.st-line    { flex:1 1 auto; height:3px; background:#e2e8f0; min-width:8px; }
.st-line.done { background:#16a34a; }

/* Badges */
.badge       { display:inline-block; border-radius:6px; padding:3px 9px;
               font-size:13px; font-weight:700; white-space:nowrap; font-family:inherit; }
.badge-green { background:var(--status-ok-bg); color:var(--status-ok-fg); }
.badge-red   { background:var(--status-escalation-bg); color:var(--status-escalation-fg); }
.badge-amber { background:var(--status-warn-bg); color:var(--status-warn-fg); }
.badge-blue  { background:var(--status-info-bg); color:var(--status-info-fg); }
.badge-gray  { background:var(--status-neutral-bg); color:var(--status-neutral-fg); }

/* Table — fixed layout so Stage Progress owns the empty space (not Applicant) */
.ob-table { width:100%; border-collapse:collapse; background:#fff;
             border:1px solid var(--border,#e2e8f0); border-radius:0; overflow:hidden;
             font-family:var(--font,'Inter','IBM Plex Sans',-apple-system,'Segoe UI',Roboto,Arial,sans-serif);
             font-size:14px; color:var(--text,#16202e); table-layout:fixed; }
.ob-table th { background:var(--bg,#f1f5f9); padding:7px 8px; text-align:left;
               font-size:12px; font-weight:700; color:var(--text-muted,#475569); text-transform:uppercase;
               letter-spacing:.03em; border-bottom:1px solid var(--border,#e2e8f0); white-space:normal;
               line-height:1.2; vertical-align:bottom; }
.ob-table th.srt { cursor:pointer; user-select:none; }
.ob-table th.srt:hover { background:#EEF3FB; color:var(--theme-accent-dark,#1d4ed8); }
.ob-table th .ar { color:var(--theme-accent,#2563eb); font-size:10px; font-weight:800; margin-left:2px; }
.ob-table td { padding:8px 8px; border-bottom:1px solid var(--da-line-soft,#EEF1F6); vertical-align:middle; }
.ob-table tr:last-child td { border-bottom:none; }
.ob-table tr:hover td { background:#fafbfc; }
/* Column widths: compact meta cols; Stage Progress gets the real estate */
.ob-table .ob-col-num { width:3.5%; }
.ob-table .ob-applicant { width:16%; vertical-align:top; }
.ob-table .ob-col-applied { width:8%; }
.ob-table .ob-col-avail { width:9%; }
.ob-table .ob-col-status { width:8%; }
.ob-table .ob-col-current { width:7%; }
.ob-table .ob-stage { width:32%; }
.ob-table .ob-col-day1 { width:7%; }
.ob-table .ob-col-actions { width:9.5%; }
.ob-table .ob-tight { white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
.ob-table .meta { font-size:13px; color:var(--text-muted,#475569); }
.da-name { font-weight:700; color:var(--text,#16202e); font-size:14px; line-height:1.25;
            white-space:normal; overflow-wrap:anywhere; max-width:100%; }
.da-email { font-size:13px; color:var(--text-light,#64748b); margin-top:2px; line-height:1.3;
             white-space:nowrap; overflow:hidden; text-overflow:ellipsis; display:block; max-width:100%; }
.da-sub  { font-size:13px; color:var(--text-light,#64748b); margin-top:1px; line-height:1.3; white-space:nowrap; }
.ob-act { display:flex; flex-direction:column; align-items:stretch; gap:4px; min-width:0; }
.btn-view { padding:5px 10px; background:#f1f5f9; border:none; border-radius:6px;
             font-size:12.5px; cursor:pointer; font-weight:600; color:#374151; width:100%;
             font-family:inherit; }
.btn-view:hover { background:#e2e8f0; }
.btn-edit { padding:5px 10px; background:#2563eb; color:#fff; border:none; border-radius:6px;
             font-size:12.5px; cursor:pointer; font-weight:600; width:100%;
             font-family:inherit; }
.btn-edit:hover { background:#1d4ed8; }

/* Detail & Edit shared overlay */
.dp-overlay { display:none; position:fixed; inset:0; background:rgba(0,0,0,.3); z-index:299; }
.dp-overlay.open { display:block; }

/* Detail panel (view) */
.detail-panel { position:fixed; top:0; right:-520px; width:480px; height:100vh;
                 background:#fff; box-shadow:-4px 0 32px rgba(0,0,0,.14);
                 z-index:300; transition:right .25s ease; overflow-y:auto; padding:28px 28px 40px; }
.detail-panel.open { right:0; }

/* Edit panel — larger form text */
.edit-panel { position:fixed; top:0; right:-620px; width:580px; height:100vh;
               background:#fff; box-shadow:-4px 0 32px rgba(0,0,0,.18);
               z-index:301; transition:right .25s ease; overflow-y:auto; display:flex; flex-direction:column; }
.edit-panel.open { right:0; }
.ep-header { padding:20px 24px 16px; border-bottom:1px solid #e2e8f0; flex-shrink:0; background:#f8fafc; }
.ep-title  { font-size:18px; font-weight:900; color:#0f172a; }
.ep-sub    { font-size:13px; color:#64748b; margin-top:2px; }
.ep-body   { flex:1; overflow-y:auto; padding:0 0 80px; }
.ep-footer { position:sticky; bottom:0; background:#fff; border-top:1px solid #e2e8f0;
              padding:14px 24px; display:flex; gap:10px; }
.ep-close  { position:absolute; top:14px; right:14px; background:#e2e8f0; border:none;
              border-radius:50%; width:30px; height:30px; font-size:13px; cursor:pointer;
              color:#64748b; font-weight:700; line-height:30px; text-align:center; }
.ep-close:hover { background:#cbd5e1; }

/* Accordion */
.acc-item { border-bottom:1px solid #e2e8f0; }
.acc-header { display:flex; align-items:center; padding:14px 24px; cursor:pointer;
               user-select:none; gap:10px; background:#fff; }
.acc-header:hover { background:#f8fafc; }
.acc-num { width:28px; height:28px; border-radius:50%; font-size:12px; font-weight:800;
            display:flex; align-items:center; justify-content:center; flex-shrink:0; }
.acc-num.done    { background:#16a34a; color:#fff; }
.acc-num.active  { background:#2563eb; color:#fff; }
.acc-num.pending { background:#e2e8f0; color:#94a3b8; }
.acc-title { font-size:14px; font-weight:700; color:#0f172a; flex:1; }
.acc-chevron { font-size:11px; color:#94a3b8; transition:transform .2s; }
.acc-chevron.open { transform:rotate(180deg); }
.acc-body { display:none; padding:0 24px 16px; }
.acc-body.open { display:block; }
.acc-section-label { font-size:11px; font-weight:700; color:#64748b; text-transform:uppercase;
                      letter-spacing:.5px; margin:14px 0 8px; }

/* Edit form fields */
.ef-grid { display:grid; grid-template-columns:1fr 1fr; gap:12px; }
.ef-grid.full { grid-template-columns:1fr; }
.ef-field { display:flex; flex-direction:column; gap:4px; }
.ef-field label { font-size:12px; font-weight:700; color:#475569; text-transform:uppercase; letter-spacing:.3px; }
.ef-field input, .ef-field select, .ef-field textarea {
  padding:9px 11px; border:1px solid #d1d5db; border-radius:6px;
  font-size:14px; font-family:inherit; color:#1e293b; background:#fff; }
.ef-field textarea { resize:vertical; min-height:70px; }
.ef-field input:focus, .ef-field select:focus, .ef-field textarea:focus {
  outline:2px solid #2563eb; border-color:#2563eb; }

/* Overall section */
.ep-overall { padding:16px 24px 0; }

/* Flash banner */
.flash-ok  { background:var(--status-ok-bg); border:1px solid var(--status-ok-border);
              padding:11px 18px; font-size:14px; color:var(--status-ok-fg); margin-bottom:20px; font-weight:600; }
.flash-err { background:var(--status-escalation-bg); border:1px solid var(--status-escalation-border);
              padding:11px 18px; font-size:14px; color:var(--status-escalation-fg); margin-bottom:20px; font-weight:600; }

/* Shared panel utils */
.dp-close { position:absolute; top:16px; right:16px; background:#f1f5f9; border:none;
             border-radius:50%; width:32px; height:32px; font-size:14px; cursor:pointer; color:#64748b; font-weight:700; }
.dp-close:hover { background:#e2e8f0; }
.dp-name { font-size:22px; font-weight:900; color:#0f172a; margin-bottom:4px; }
.dp-sub  { font-size:14px; color:#64748b; margin-bottom:20px; }
.dp-section { font-size:12px; font-weight:700; color:#64748b; text-transform:uppercase;
               letter-spacing:.6px; margin:20px 0 10px; border-bottom:1px solid #f1f5f9; padding-bottom:6px; }
.dp-field { margin-bottom:10px; }
.dp-field label { font-size:12px; font-weight:700; color:#64748b; text-transform:uppercase; display:block; margin-bottom:2px; }
.dp-field span  { font-size:14px; color:#1e293b; }
.dp-stage-row { display:flex; align-items:flex-start; gap:12px; padding:8px 0; border-bottom:1px solid #f8fafc; }
.dp-stage-num { width:28px; height:28px; border-radius:50%; display:flex; align-items:center;
                justify-content:center; font-size:12px; font-weight:800; flex-shrink:0; margin-top:1px; }
.dp-stage-body h4 { font-size:14px; font-weight:700; color:#0f172a; }
.dp-stage-body p  { font-size:12px; color:#94a3b8; margin-top:2px; }

/* Error box */
.db-error { background:var(--status-escalation-bg); border:1px solid var(--status-escalation-border); border-radius:8px;
             padding:14px 18px; font-size:14px; color:var(--status-escalation-fg); margin-bottom:20px; }
</style>

<!-- ── Dashboard Shell ──────────────────────────────── -->
<div class="ob-shell">

  <!-- Header -->
  <div class="ob-hdr">
    <div class="ob-hdr-left">
      <h1>DA Onboarding Pipeline</h1>
      <p>DNK7 &middot; <%=total%> active &middot; <%=totalHired%> hired all time</p>
    </div>
    <div class="ob-hdr-right">
      <a href="DAOnboardingDashboard.jsp"
         style="display:inline-flex;align-items:center;gap:5px;padding:7px 13px;
                background:#fff;color:#0f172a;border:1px solid #e2e8f0;border-radius:7px;font-size:12px;font-weight:700;text-decoration:none;">
        Dashboard
      </a>
      <a href="https://employers.indeed.com/jobs?status=open%2Cpaused&claimed=false&createdOnIndeed=true&tab=0&sortDirection=DESC&sortField=datePostedOnIndeed" target="_blank" rel="noopener"
         style="display:inline-flex;align-items:center;gap:5px;padding:6px 12px;
                background:#2164f3;color:#fff;border-radius:7px;font-size:12px;font-weight:700;text-decoration:none;">
        &#128203; Indeed
      </a>
      <a href="https://identity.checkr.com/login" target="_blank" rel="noopener"
         style="display:inline-flex;align-items:center;gap:5px;padding:6px 12px;
                background:#0f172a;color:#fff;border-radius:7px;font-size:12px;font-weight:700;text-decoration:none;">
        &#128269; Checkr
      </a>
      <a href="https://www.labcorpsolutions.com/ots/login.jsp" target="_blank" rel="noopener"
         style="display:inline-flex;align-items:center;gap:5px;padding:6px 12px;
                background:#0f172a;color:#fff;border-radius:7px;font-size:12px;font-weight:700;text-decoration:none;">
        &#128138; LabCorp
      </a>
      <a href="https://www.smartrecruiters.com/account/sign-in" target="_blank" rel="noopener"
         style="display:inline-flex;align-items:center;gap:5px;padding:6px 12px;
                background:#0f172a;color:#fff;border-radius:7px;font-size:12px;font-weight:700;text-decoration:none;">
        &#127775; SmartRecruiters
      </a>
      <button onclick="openExport()"
         style="display:inline-flex;align-items:center;gap:5px;padding:6px 12px;
                background:#16a34a;color:#fff;border:none;border-radius:7px;font-size:12px;font-weight:700;cursor:pointer;">
        &#11015; Export
      </button>
      <button onclick="openShare()"
         style="display:inline-flex;align-items:center;gap:5px;padding:6px 12px;
                background:#7c3aed;color:#fff;border:none;border-radius:7px;font-size:12px;font-weight:700;cursor:pointer;">
        &#128279; Share Form
      </button>
      <a href="DAApplicationForm.jsp" target="_blank" rel="noopener"
         style="display:inline-flex;align-items:center;gap:5px;padding:6px 12px;
                background:#2563eb;color:#fff;border-radius:7px;font-size:12px;font-weight:700;text-decoration:none;">
        + New Application
      </a>
    </div>
  </div>

  <% if (dbError != null) { %>
  <div class="db-error" style="margin-bottom:8px;"><strong>DB error:</strong> <%=esc(dbError)%></div>
  <% } %>
  <% if (saveMsg != null) { %>
  <div class="<%=saveMsgOk ? "flash-ok" : "flash-err"%>" style="margin-bottom:8px;"><%=esc(saveMsg)%></div>
  <% } %>

  <!-- KPI strip: stage funnel -->
  <div class="ob-kpi-strip">
    <a class="ob-kpi-pill" href="DAOnboarding.jsp?filterStatus=NEW" title="New / Interviewed">
      <div class="ob-kpi-bar" style="background:#64748b;"></div>
      <div><div class="ob-kpi-val"><%=cntNew%></div><div class="ob-kpi-lbl">New (Interviewed)</div></div>
    </a>
    <a class="ob-kpi-pill" href="DAOnboarding.jsp?filterStage=S1" title="S1 Background">
      <div class="ob-kpi-bar" style="background:#0f766e;"></div>
      <div><div class="ob-kpi-val" style="color:#0f766e;"><%=cntBgDone%></div><div class="ob-kpi-lbl">Background (Done)</div></div>
    </a>
    <a class="ob-kpi-pill" href="DAOnboarding.jsp?filterStage=S2" title="S2 Drug Test Details">
      <div class="ob-kpi-bar" style="background:#2563eb;"></div>
      <div><div class="ob-kpi-val" style="color:#2563eb;"><%=cntDrugSent%></div><div class="ob-kpi-lbl">Drug Test Details</div></div>
    </a>
    <a class="ob-kpi-pill" href="DAOnboarding.jsp?filterStage=S3" title="S3 Training Schedule/Day1 &amp; Day2">
      <div class="ob-kpi-bar" style="background:#ca8a04;"></div>
      <div><div class="ob-kpi-val" style="color:#a16207;"><%=cntTrainSched%></div><div class="ob-kpi-lbl">Training Schedule/Day1 &amp; Day2</div></div>
    </a>
    <a class="ob-kpi-pill" href="DAOnboarding.jsp?filterStage=S4" title="ADP Pending (S4/S6)">
      <div class="ob-kpi-bar" style="background:#7c3aed;"></div>
      <div><div class="ob-kpi-val" style="color:#7c3aed;"><%=cntAdpPend%></div><div class="ob-kpi-lbl">ADP Pending</div></div>
    </a>
    <div class="ob-kpi-pill" title="ADP Done (S4 done / S6 Fixed)">
      <div class="ob-kpi-bar" style="background:#16a34a;"></div>
      <div><div class="ob-kpi-val" style="color:#16a34a;"><%=cntAdpDone%></div><div class="ob-kpi-lbl">ADP Done</div></div>
    </div>
    <a class="ob-kpi-pill" href="DAOnboarding.jsp?filterStage=S5" title="S5 Orientation">
      <div class="ob-kpi-bar" style="background:#0891b2;"></div>
      <div><div class="ob-kpi-val" style="color:#0e7490;"><%=cntOrient%></div><div class="ob-kpi-lbl">Orientation</div></div>
    </a>
    <a class="ob-kpi-pill" href="DAOnboarding.jsp?filterStage=S7" title="S7 Day 1 Training Pending">
      <div class="ob-kpi-bar" style="background:#dc2626;"></div>
      <div><div class="ob-kpi-val" style="color:#dc2626;"><%=cntDay1Pend%></div><div class="ob-kpi-lbl">Day 1 Training Pending</div></div>
    </a>
  </div>

  <!-- Body: Left=pipeline, Right=stats -->
  <div class="ob-body">

    <!-- LEFT: filter + scrollable table -->
    <div class="ob-left">
      <form method="get" action="DAOnboarding.jsp" class="filter-bar" style="margin-bottom:0;flex-shrink:0;">
        <input type="text" name="search" value="<%=esc(search)%>" placeholder="Search name or email...">
        <select name="filterStatus">
          <option value="ALL"<%="ALL".equals(filterStatus)?" selected":""%>>All Statuses</option>
          <% for (String[] st : pipelineStatuses) {
               if ("COMPLETE".equals(st[0])) continue; /* complete / failed stay off default list */ %>
          <option value="<%=st[0]%>" <%=st[0].equals(filterStatus)?" selected":""%>><%=esc(st[1])%></option>
          <% } %>
          <option value="COMPLETE" <%="COMPLETE".equals(filterStatus) ?" selected":""%>>Complete</option>
        </select>
        <select name="filterStage">
          <option value="ALL"<%="ALL".equals(filterStage)?" selected":""%>>All Stages</option>
          <% for (int ski = 0; ski < STAGE_KEYS.length; ski++) { %>
          <option value="<%=STAGE_KEYS[ski]%>"<%=STAGE_KEYS[ski].equals(filterStage)?" selected":""%>><%=esc(STAGE_LABELS[ski])%></option>
          <% } %>
        </select>
        <button type="submit" class="btn-filter">Filter</button>
        <a href="DAOnboarding.jsp" class="btn-clear">Clear</a>
      </form>

      <div class="ob-tbl-wrap">
      <table class="ob-table" id="obPipelineTable" style="border:none;border-radius:0;">
    <thead>
      <tr>
        <th class="srt ob-tight ob-col-num" onclick="obSort(this)">#<span class="ar"></span></th>
        <th class="srt ob-applicant" onclick="obSort(this)">Applicant<span class="ar"></span></th>
        <th class="srt ob-tight ob-col-applied" onclick="obSort(this)">Applied<span class="ar"></span></th>
        <th class="srt ob-tight ob-col-avail" onclick="obSort(this)">Availability<span class="ar"></span></th>
        <th class="srt ob-tight ob-col-status" onclick="obSort(this)">Status<span class="ar"></span></th>
        <th class="srt ob-tight ob-col-current" onclick="obSort(this)">Current<span class="ar"></span></th>
        <th class="srt ob-stage" onclick="obSort(this)">Stage Progress<br><span style="font-weight:600;text-transform:none;letter-spacing:0;color:#94a3b8;">S1 to S8</span><span class="ar"></span></th>
        <th class="ob-tight ob-col-actions">Actions</th>
      </tr>
    </thead>
    <tbody>
    <% if (rows.isEmpty()) { %>
      <tr><td colspan="8" style="text-align:center;padding:48px;color:#94a3b8;font-size:14px;">
        No applicants found<% if (!search.isEmpty() || !"ALL".equals(filterStatus) || !"ALL".equals(filterStage)) { %> matching current filters<% } %>.
      </td></tr>
    <% } %>
    <% for (Map<String,String> r : rows) {
        String curStage = r.get("current_stage");
        if (curStage == null || curStage.isEmpty()) curStage = "S1";
        String appId = r.get("application_id");
        String obId  = r.get("onboarding_id");
        String appliedSort = r.get("applied_ts");
        if (appliedSort != null && appliedSort.length() >= 10) appliedSort = appliedSort.substring(0, 10);
        else appliedSort = "";
        String applicantSort = ((r.get("last_name") == null ? "" : r.get("last_name")) + " " + (r.get("first_name") == null ? "" : r.get("first_name"))).trim().toLowerCase();
        String availSort = r.get("avail_type") == null ? "" : r.get("avail_type");
        String statusSort = r.get("ob_status") == null ? "" : r.get("ob_status");
        int stageOrd = 0;
        String displayStage = canonicalStage(curStage);
        for (int si = 0; si < VISIBLE_STAGE_KEYS.length; si++) {
          if (VISIBLE_STAGE_KEYS[si].equalsIgnoreCase(displayStage)) { stageOrd = si + 1; break; }
        }
    %>
      <tr data-id="<%=esc(appId)%>">
        <td class="ob-tight meta ob-col-num" data-sort="<%=esc(appId)%>"><%=esc(appId)%></td>
        <td class="ob-applicant" data-sort="<%=esc(applicantSort)%>">
          <div class="da-name"><%=esc(r.get("first_name"))%> <%=esc(r.get("last_name"))%></div>
          <div class="da-email" title="<%=esc(r.get("email"))%>"><%=esc(r.get("email"))%></div>
          <% if (!r.get("phone").isEmpty()) { %><div class="da-sub"><%=esc(r.get("phone"))%></div><% } %>
        </td>
        <td class="ob-tight meta ob-col-applied" data-sort="<%=esc(appliedSort)%>">
          <%=appliedSort.isEmpty() ? "-" : esc(appliedSort)%>
        </td>
        <td class="ob-tight meta ob-col-avail" data-sort="<%=esc(availSort)%>">
          <%=esc(availSort.replace("_"," "))%>
        </td>
        <td class="ob-tight ob-col-status" data-sort="<%=esc(statusSort)%>"><%=statusBadge(r.get("ob_status"))%></td>
        <td class="ob-tight ob-col-current" data-sort="<%=stageOrd%>"><span class="badge badge-blue"><%=esc(displayStage)%></span></td>
        <td class="ob-stage" data-sort="<%=stageOrd%>">
          <div class="stage-track">
          <% for (int i = 0; i < VISIBLE_STAGE_KEYS.length; i++) {
               String vKey = VISIBLE_STAGE_KEYS[i];
               String cls = stageClass(curStage, vKey);
               int labelNum = Integer.parseInt(vKey.substring(1));
               String vLabel = STAGE_LABELS[0];
               for (int li = 0; li < STAGE_KEYS.length; li++) {
                 if (STAGE_KEYS[li].equals(vKey)) { vLabel = STAGE_LABELS[li]; break; }
               } %>
            <div class="st-dot <%=cls%>" title="<%=esc(vLabel)%>"><%=labelNum%></div>
            <% if (i < VISIBLE_STAGE_KEYS.length - 1) { %><div class="st-line<%=cls.equals("st-done")?" done":""%>"></div><% } %>
          <% } %>
          </div>
          <div style="font-size:11px;color:#94a3b8;margin-top:3px;">
          <% for (int i=0;i<STAGE_KEYS.length;i++) {
               if (STAGE_KEYS[i].equals(displayStage) || STAGE_KEYS[i].equals(curStage)) {
                 out.print(STAGE_SHORT[i]); break;
               }
             } %>
          </div>
        </td>
        <td class="ob-tight ob-col-actions">
          <div class="ob-act">
            <button type="button" class="btn-view" onclick="openDetail('<%=esc(appId)%>')">View</button>
            <button type="button" class="btn-edit" onclick="openEdit('<%=esc(appId)%>')">Edit</button>
          </div>
        </td>
      </tr>
      <script>
      (function(){
        window._ob = window._ob || {};
        window._ob['<%=esc(appId)%>'] = {
          name:      '<%=esc(r.get("first_name"))%> <%=esc(r.get("last_name"))%>',
          first_name:'<%=esc(r.get("first_name"))%>',
          last_name: '<%=esc(r.get("last_name"))%>',
          email:     '<%=esc(r.get("email"))%>',
          phone:     '<%=esc(r.get("phone"))%>',
          avail_type:'<%=esc(r.get("avail_type"))%>',
          avail:     '<%=esc(r.get("avail_type").replace("_"," "))%>',
          app_status:'<%=esc(r.get("app_status"))%>',
          status:  '<%=esc(r.get("ob_status"))%>',
          stage:   '<%=esc(curStage)%>',
          ob_id:   '<%=esc(obId.isEmpty() ? "0" : obId)%>',
          vals:    ['<%=esc(r.get("s1_date"))%>','<%=esc(r.get("s2_status"))%>',
                   '<%=esc(r.get("s3_result"))%>','<%=esc(r.get("s4_status"))%>',
                   '<%=esc(r.get("s5_result"))%>','<%=esc(r.get("s6_done"))%>',
                   '<%=esc(r.get("s7_done"))%>','<%=esc(r.get("s8_adp_status"))%>',
                   '<%=esc(r.get("s9_status"))%>'],
          day1:    '<%=esc(r.get("s9_day1_date"))%>',
          done:    '<%=esc(r.get("completed_date"))%>',
          notes:   '<%=esc(r.get("notes")).replace("\\","\\\\").replace("'","\\'")%>',
          checkr_cid:   '<%=esc(r.get("checkr_candidate_id"))%>',
          checkr_status:'<%=esc(r.get("checkr_status"))%>',
          labcorp_id:   '<%=esc(r.get("labcorp_order_id"))%>',
          drug_result:  '<%=esc(r.get("drug_test_result"))%>',
          drug_loc:     '<%=esc(r.get("drug_test_location"))%>',
          drug_doc:     '<%=esc(r.get("drug_test_doc_path"))%>',
          s4_sched:     '<%=esc(r.get("s4_scheduled_date"))%>',
          s5_day1:      '<%=esc(r.get("s5_day1_date"))%>',
          s5_day2:      '<%=esc(r.get("s5_day2_date"))%>',
          hold_reason:  '<%=esc(r.get("hold_reason")).replace("\\","\\\\").replace("'","\\'")%>',
          s1_in:'<%=esc(r.get("s1_entered_at"))%>', s1_out:'<%=esc(r.get("s1_exited_at"))%>',
          s2_in:'<%=esc(r.get("s2_entered_at"))%>', s2_out:'<%=esc(r.get("s2_exited_at"))%>',
          s3_in:'<%=esc(r.get("s3_entered_at"))%>', s3_out:'<%=esc(r.get("s3_exited_at"))%>',
          s4_in:'<%=esc(r.get("s4_entered_at"))%>', s4_out:'<%=esc(r.get("s4_exited_at"))%>',
          s5_in:'<%=esc(r.get("s5_entered_at"))%>', s5_out:'<%=esc(r.get("s5_exited_at"))%>',
          s6_in:'<%=esc(r.get("s6_entered_at"))%>', s6_out:'<%=esc(r.get("s6_exited_at"))%>',
          s7_in:'<%=esc(r.get("s7_entered_at"))%>', s7_out:'<%=esc(r.get("s7_exited_at"))%>',
          s8_in:'<%=esc(r.get("s8_entered_at"))%>', s8_out:'<%=esc(r.get("s8_exited_at"))%>',
          s9_in:'<%=esc(r.get("s9_entered_at"))%>', s9_out:'<%=esc(r.get("s9_exited_at"))%>',
          s2_status:'<%=esc(r.get("s2_status"))%>',
          s4_status:'<%=esc(r.get("s4_status"))%>',
          s6_notes:'<%=esc(r.get("s6_notes") == null ? "" : r.get("s6_notes")).replace("\\","\\\\").replace("'","\\'")%>',
          s7_notes:'<%=esc(r.get("s7_notes") == null ? "" : r.get("s7_notes")).replace("\\","\\\\").replace("'","\\'")%>',
          doc_dl:       '<%=esc(r.get("dl_file_path"))%>',
          doc_ssn:      '<%=esc(r.get("ssn_file_path"))%>',
          doc_wp_front: '<%=esc(r.get("wp_front_file_path"))%>',
          doc_wp_back:  '<%=esc(r.get("wp_back_file_path"))%>',
          drive_dl:       '<%=esc(r.get("dl_drive_url"))%>',
          drive_ssn:      '<%=esc(r.get("ssn_drive_url"))%>',
          drive_wp_front: '<%=esc(r.get("wp_front_drive_url"))%>',
          drive_wp_back:  '<%=esc(r.get("wp_back_drive_url"))%>',
          offer_signed: '<%=esc(r.get("offer_letter_signed") != null && !r.get("offer_letter_signed").isEmpty() ? r.get("offer_letter_signed") : r.get("app_offer_letter_signed"))%>',
          offer_doc:    '<%=esc((r.get("offer_letter_doc_path") != null && !r.get("offer_letter_doc_path").isEmpty()) ? r.get("offer_letter_doc_path") : r.get("app_offer_letter_file_path"))%>',
          drive_offer:  '<%=esc(r.get("app_offer_letter_drive_url"))%>',
          offer_in:     '<%=esc(r.get("offer_letter_entered_at"))%>',
          offer_out:    '<%=esc(r.get("offer_letter_exited_at"))%>'
        };
      })();
      </script>
    <% } %>
    </tbody>
      </table>
      </div><!-- /ob-tbl-wrap -->
    </div><!-- /ob-left -->
  </div><!-- /ob-body -->
</div><!-- /ob-shell -->

<!-- Overlay (shared for both panels) -->
<div class="dp-overlay" id="dpOverlay" onclick="closeAll()"></div>

<!-- View detail panel -->
<div class="detail-panel" id="detailPanel">
  <button class="dp-close" onclick="closeAll()">X</button>
  <div class="dp-name" id="dp-name"></div>
  <div class="dp-sub"  id="dp-sub"></div>
  <div class="dp-section">Contact</div>
  <div class="dp-field"><label>Email</label><span id="dp-email"></span></div>
  <div class="dp-field"><label>Phone</label><span id="dp-phone"></span></div>
  <div class="dp-field"><label>Availability</label><span id="dp-avail"></span></div>
  <div class="dp-field"><label>Overall Status</label><span id="dp-status"></span></div>
  <div class="dp-field" id="dp-hold-row" style="display:none;"><label>Hold Reason</label><span id="dp-hold-reason" style="color:#b45309;font-size:12px;"></span></div>
  <div class="dp-field"><label>Day 1 Date</label><span id="dp-day1"></span></div>
  <div class="dp-field"><label>Completed Date</label><span id="dp-done"></span></div>
  <div class="dp-section">Documents</div>
  <div id="dp-docs" style="display:grid;grid-template-columns:1fr 1fr;gap:8px;margin-bottom:12px;"></div>
  <!-- Tabs -->
  <div style="display:flex;border-bottom:2px solid #e2e8f0;margin:16px 0 0;">
    <button class="dp-tab active" onclick="dpTab(this,'dp-tab-progress')" style="flex:1;padding:8px;font-size:12px;font-weight:700;border:none;background:none;color:#2563eb;border-bottom:2px solid #2563eb;cursor:pointer;">Stage Progress</button>
    <button class="dp-tab" onclick="dpTab(this,'dp-tab-history')"  style="flex:1;padding:8px;font-size:12px;font-weight:700;border:none;background:none;color:#94a3b8;cursor:pointer;">History</button>
  </div>
  <div id="dp-tab-progress">
    <div class="dp-section" style="margin-top:12px;">Stage Progress</div>
    <div id="dp-stages"></div>
    <div class="dp-section">Notes</div>
    <div id="dp-notes" style="font-size:13px;color:#64748b;line-height:1.7;white-space:pre-wrap;"></div>
  </div>
  <div id="dp-tab-history" style="display:none;">
    <div id="dp-history-body" style="padding:4px 0;">
      <div style="padding:24px;text-align:center;color:#94a3b8;font-size:12px;">Loading history&hellip;</div>
    </div>
  </div>
</div>

<!-- Edit panel -->
<div class="edit-panel" id="editPanel">
  <div class="ep-header">
    <button class="ep-close" onclick="closeAll()">X</button>
    <div class="ep-title" id="ep-name">Edit Onboarding</div>
    <div class="ep-sub" id="ep-sub"></div>
  </div>
  <div class="ep-body">
    <!-- Applicant Info edit form (separate POST) -->
    <form id="appEditForm" method="POST" action="DAOnboarding.jsp">
      <input type="hidden" name="action" value="updateApplicant">
      <input type="hidden" name="application_id" id="ep-app-id">
      <div class="acc-item" style="border-top:1px solid #e2e8f0;">
        <div class="acc-header" onclick="toggleAcc(this)" style="background:#fafafa;">
          <div class="acc-num" style="background:#64748b;color:#fff;width:26px;height:26px;border-radius:50%;font-size:11px;display:flex;align-items:center;justify-content:center;">&#9998;</div>
          <div class="acc-title" style="color:#374151;">Applicant Info</div>
          <span class="acc-chevron">&#9660;</span>
        </div>
        <div class="acc-body">
          <div class="ef-grid">
            <div class="ef-field">
              <label>First Name</label>
              <input type="text" name="first_name" id="ep-first-name">
            </div>
            <div class="ef-field">
              <label>Last Name</label>
              <input type="text" name="last_name" id="ep-last-name">
            </div>
          </div>
          <div class="ef-grid">
            <div class="ef-field">
              <label>Email</label>
              <input type="email" name="email" id="ep-app-email">
            </div>
            <div class="ef-field">
              <label>Phone</label>
              <input type="text" name="phone" id="ep-app-phone">
            </div>
          </div>
          <div class="ef-grid">
            <div class="ef-field">
              <label>Availability Type</label>
              <select name="avail_type" id="ep-avail-type">
                <option value="FULLTIME">Full Time</option>
                <option value="PARTTIME_WEEKEND">Part Time - Weekend</option>
                <option value="PARTTIME_MIXED">Part Time - Mixed</option>
              </select>
            </div>
            <div class="ef-field">
              <label>App Status</label>
              <select name="app_status" id="ep-app-status-sel">
                <option value="PENDING">Pending</option>
                <option value="ACTIVE">Active</option>
                <option value="ON_HOLD">On Hold</option>
                <option value="REJECTED">Rejected</option>
                <option value="WITHDRAWN">Withdrawn</option>
              </select>
            </div>
          </div>
          <div style="margin-top:10px;">
            <button type="submit" form="appEditForm"
                    style="padding:8px 20px;background:#0f172a;color:#fff;border:none;border-radius:7px;font-size:13px;font-weight:700;cursor:pointer;">
              Save Applicant Info
            </button>
          </div>
        </div>
      </div>
    </form>

    <form id="editForm" method="POST" action="DAOnboarding.jsp" enctype="multipart/form-data">
      <input type="hidden" name="action" value="update">
      <input type="hidden" name="onboarding_id" id="ep-ob-id">
      <input type="hidden" name="app_id_for_create" id="ep-app-id-create">

      <!-- Overall status -->
      <div class="ep-overall">
        <div style="background:#eff6ff;border:1px solid #bfdbfe;border-radius:8px;padding:10px 14px;margin-bottom:14px;font-size:12px;color:#1d4ed8;">
          <strong>To move this DA to a new stage:</strong> enter the date in that stage's "Entered" field below &mdash; the stage will advance automatically. Then click Save Changes.
        </div>
        <div class="acc-section-label">Overall</div>
        <div class="ef-grid">
          <div class="ef-field">
            <label>&#9650; Current Stage (auto-updates)</label>
            <select name="current_stage" id="ep-stage" style="border:2px solid #2563eb;font-weight:700;">
              <option value="S1">S1 - Background Check</option>
              <option value="S2">S2 - Drug Test Details</option>
              <option value="S3">S3 - Training Schedule/Day1 &amp; Day2</option>
              <option value="S4">S4 - ADP Onboarding</option>
              <option value="S5">S5 - Orientation</option>
              <option value="S6">S6 - Schedule Fixed</option>
              <option value="S7">S7 - Day 1 On-Road</option>
              <option value="S8">S8 - Offer Letter Signed</option>
            </select>
          </div>
          <div class="ef-field">
            <label>Pipeline Status</label>
            <div style="display:flex;gap:6px;align-items:center;">
              <select name="ob_status" id="ep-ob-status" style="flex:1;">
                <% for (String[] st : pipelineStatuses) { %>
                <option value="<%=st[0]%>"><%=esc(st[1])%></option>
                <% } %>
                <option value="__ADD_NEW__">+ Add new status…</option>
              </select>
            </div>
          </div>
          <div class="ef-field">
            <label>Completed Date</label>
            <input type="date" name="completed_date" id="ep-completed-date">
          </div>
        </div>
        <div class="ef-grid full" id="hold-reason-row" style="margin-top:10px;display:none;">
          <div class="ef-field">
            <label>&#9888; Reason for Hold</label>
            <input type="text" name="hold_reason" id="ep-hold-reason" placeholder="Why is this DA on hold?">
          </div>
        </div>
        <div class="ef-grid full" style="margin-top:10px;">
          <div class="ef-field">
            <label>Notes</label>
            <textarea name="notes" id="ep-notes"></textarea>
          </div>
        </div>
      </div>

      <!-- Stage accordions -->
      <div id="ep-stages-acc" style="margin-top:16px;">

        <!-- S1 - Background Check -->
        <div class="acc-item">
          <div class="acc-header" onclick="toggleAcc(this)">
            <div class="acc-num pending" id="acc-num-0">1</div>
            <div class="acc-title">S1 &mdash; Background Check</div>
            <span class="acc-chevron">&#9660;</span>
          </div>
          <div class="acc-body">
            <div class="acc-section-label">Stage dates</div>
            <div class="ef-grid">
              <div class="ef-field">
                <label>Stage Data Entered</label>
                <input type="date" name="s1_entered_at" id="ep-s1-in">
              </div>
              <div class="ef-field">
                <label>Stage Date Completed</label>
                <input type="date" name="s1_exited_at" id="ep-s1-out">
              </div>
            </div>
            <div class="ef-grid">
              <div class="ef-field">
                <label>Checkr Initiated Date</label>
                <input type="date" name="s1_date" id="ep-s1-date">
              </div>
              <div class="ef-field">
                <label>Checkr Status</label>
                <select name="checkr_status" id="ep-checkr-status">
                  <option value="">-- select --</option>
                  <option value="PENDING">Pending</option>
                  <option value="CLEAR">Clear</option>
                  <option value="FAIL">Failed</option>
                  <option value="CONSIDER">Consider</option>
                  <option value="SUSPENDED">Suspended</option>
                </select>
              </div>
            </div>
            <div class="ef-grid full">
              <div class="ef-field">
                <label>Checkr Candidate ID</label>
                <input type="text" name="checkr_candidate_id" id="ep-checkr-cid" placeholder="e.g. abc123">
              </div>
            </div>
          </div>
        </div>

        <!-- S2 - Drug Test Details (combined former S2 + S3) -->
        <div class="acc-item">
          <div class="acc-header" onclick="toggleAcc(this)">
            <div class="acc-num pending" id="acc-num-1">2</div>
            <div class="acc-title">S2 &mdash; Drug Test Details</div>
            <span class="acc-chevron">&#9660;</span>
          </div>
          <div class="acc-body">
            <div class="acc-section-label">Stage dates</div>
            <div class="ef-grid">
              <div class="ef-field">
                <label>Stage Data Entered</label>
                <input type="date" name="s2_entered_at" id="ep-s2-in">
              </div>
              <div class="ef-field">
                <label>Stage Date Completed</label>
                <input type="date" name="s2_exited_at" id="ep-s2-out">
              </div>
            </div>
            <div class="ef-grid">
              <div class="ef-field">
                <label>Order Sent Status</label>
                <select name="s2_status" id="ep-s2-status">
                  <option value="">-- select --</option>
                  <% for (String[] ds : drugOrderStatuses) { %>
                  <option value="<%=esc(ds[0])%>"><%=esc(ds[1])%></option>
                  <% } %>
                  <option value="__ADD_NEW__">+ Add additional status…</option>
                </select>
              </div>
              <div class="ef-field">
                <label>LabCorp Order ID</label>
                <input type="text" name="labcorp_order_id" id="ep-labcorp-id" placeholder="LabCorp donor/order ID">
              </div>
            </div>
            <div class="ef-grid full">
              <div class="ef-field">
                <label>Test Location</label>
                <input type="text" name="drug_test_location" id="ep-drug-loc" placeholder="e.g. 123 Main St, City">
              </div>
            </div>
            <div class="ef-grid">
              <div class="ef-field">
                <label>Drug Test Results</label>
                <select name="drug_test_result" id="ep-drug-result">
                  <option value="">-- select --</option>
                  <% for (String[] ds : drugResultStatuses) { %>
                  <option value="<%=esc(ds[0])%>"><%=esc(ds[1])%></option>
                  <% } %>
                  <option value="__ADD_NEW__">+ Add additional status…</option>
                </select>
              </div>
              <div class="ef-field">
                <label>Notes / Results Details</label>
                <input type="text" name="s3_result" id="ep-s3-result" placeholder="notes / result details">
              </div>
            </div>
            <div class="ef-grid full">
              <div class="ef-field">
                <label>Upload test result document</label>
                <input type="file" name="drug_test_doc" id="ep-drug-doc" accept=".pdf,application/pdf,image/*">
                <div id="ep-drug-doc-cur" style="font-size:12px;color:#64748b;margin-top:4px;"></div>
              </div>
            </div>
            <input type="hidden" name="s3_entered_at" id="ep-s3-in">
            <input type="hidden" name="s3_exited_at" id="ep-s3-out">
          </div>
        </div>

        <!-- S3 - Training Schedule/Day1 & Day2 (combined former S4 + S5) -->
        <div class="acc-item">
          <div class="acc-header" onclick="toggleAcc(this)">
            <div class="acc-num pending" id="acc-num-2">3</div>
            <div class="acc-title">S3 &mdash; Training Schedule/Day1 &amp; Day2</div>
            <span class="acc-chevron">&#9660;</span>
          </div>
          <div class="acc-body">
            <div class="acc-section-label">Stage Dates</div>
            <div class="ef-grid">
              <div class="ef-field">
                <label>Entered</label>
                <input type="date" name="s4_entered_at" id="ep-s4-in">
              </div>
              <div class="ef-field">
                <label>Exited</label>
                <input type="date" name="s4_exited_at" id="ep-s4-out">
              </div>
            </div>
            <div class="ef-grid">
              <div class="ef-field">
                <label>Training Schedule Status</label>
                <select name="s4_status" id="ep-s4-status">
                  <option value="">-- select --</option>
                  <% for (String[] ts : trainingSchedStatuses) { %>
                  <option value="<%=esc(ts[0])%>"><%=esc(ts[1])%></option>
                  <% } %>
                  <option value="__ADD_NEW__">+ Add new status…</option>
                </select>
              </div>
              <div class="ef-field">
                <label>Training Schedule Date</label>
                <input type="date" name="s4_scheduled_date" id="ep-s4-sched">
              </div>
            </div>
            <div class="ef-grid">
              <div class="ef-field">
                <label>Training Day 1 Date</label>
                <input type="date" name="s5_day1_date" id="ep-s5-day1">
              </div>
              <div class="ef-field">
                <label>Training Day 2 Date</label>
                <input type="date" name="s5_day2_date" id="ep-s5-day2">
              </div>
            </div>
            <div class="ef-grid full">
              <div class="ef-field">
                <label>Training Results / Notes</label>
                <input type="text" name="s5_result" id="ep-s5-result" placeholder="results / notes">
              </div>
            </div>
            <input type="hidden" name="s5_entered_at" id="ep-s5-in">
            <input type="hidden" name="s5_exited_at" id="ep-s5-out">
          </div>
        </div>

        <!-- S4 - ADP Onboarding (DB fields still s6_*) -->
        <div class="acc-item">
          <div class="acc-header" onclick="toggleAcc(this)">
            <div class="acc-num pending" id="acc-num-3">4</div>
            <div class="acc-title">S4 &mdash; ADP Onboarding Completed</div>
            <span class="acc-chevron">&#9660;</span>
          </div>
          <div class="acc-body">
            <div class="ef-grid">
              <div class="ef-field">
                <label>ADP Done</label>
                <select name="s6_done" id="ep-s6-done">
                  <option value="0">No</option>
                  <option value="1">Yes</option>
                </select>
              </div>
              <div class="ef-field">
                <label>Notes</label>
                <input type="text" name="s6_notes" id="ep-s6-notes" placeholder="ADP notes">
              </div>
            </div>
            <div class="acc-section-label">Stage Dates</div>
            <div class="ef-grid">
              <div class="ef-field">
                <label>Entered</label>
                <input type="date" name="s6_entered_at" id="ep-s6-in">
              </div>
              <div class="ef-field">
                <label>Exited</label>
                <input type="date" name="s6_exited_at" id="ep-s6-out">
              </div>
            </div>
          </div>
        </div>

        <!-- S5 - Orientation (DB fields still s7_*) -->
        <div class="acc-item">
          <div class="acc-header" onclick="toggleAcc(this)">
            <div class="acc-num pending" id="acc-num-4">5</div>
            <div class="acc-title">S5 &mdash; Orientation</div>
            <span class="acc-chevron">&#9660;</span>
          </div>
          <div class="acc-body">
            <div class="ef-grid">
              <div class="ef-field">
                <label>Orientation Done</label>
                <select name="s7_done" id="ep-s7-done">
                  <option value="0">No</option>
                  <option value="1">Yes</option>
                </select>
              </div>
              <div class="ef-field">
                <label>Notes</label>
                <input type="text" name="s7_notes" id="ep-s7-notes" placeholder="Orientation notes">
              </div>
            </div>
            <div class="acc-section-label">Stage Dates</div>
            <div class="ef-grid">
              <div class="ef-field">
                <label>Entered</label>
                <input type="date" name="s7_entered_at" id="ep-s7-in">
              </div>
              <div class="ef-field">
                <label>Exited</label>
                <input type="date" name="s7_exited_at" id="ep-s7-out">
              </div>
            </div>
          </div>
        </div>

        <!-- S6 - Schedule Fixed (DB fields still s8_*) -->
        <div class="acc-item">
          <div class="acc-header" onclick="toggleAcc(this)">
            <div class="acc-num pending" id="acc-num-5">6</div>
            <div class="acc-title">S6 &mdash; Schedule Fixed</div>
            <span class="acc-chevron">&#9660;</span>
          </div>
          <div class="acc-body">
            <div class="ef-grid full">
              <div class="ef-field">
                <label>ADP Schedule Status</label>
                <select name="s8_adp_status" id="ep-s8-adp">
                  <option value="">-- select --</option>
                  <option value="PENDING">Pending</option>
                  <option value="IN_PROGRESS">In Progress</option>
                  <option value="FIXED">Fixed</option>
                </select>
              </div>
            </div>
            <div class="acc-section-label">Stage Dates</div>
            <div class="ef-grid">
              <div class="ef-field">
                <label>Entered</label>
                <input type="date" name="s8_entered_at" id="ep-s8-in">
              </div>
              <div class="ef-field">
                <label>Exited</label>
                <input type="date" name="s8_exited_at" id="ep-s8-out">
              </div>
            </div>
          </div>
        </div>

        <!-- S7 - Day 1 On-Road Training (DB fields still s9_*) -->
        <div class="acc-item">
          <div class="acc-header" onclick="toggleAcc(this)">
            <div class="acc-num pending" id="acc-num-6">7</div>
            <div class="acc-title">S7 &mdash; Day 1 On-Road Training</div>
            <span class="acc-chevron">&#9660;</span>
          </div>
          <div class="acc-body">
            <div class="ef-grid">
              <div class="ef-field">
                <label>Day 1 Date</label>
                <input type="date" name="s9_day1_date" id="ep-s9-day1">
              </div>
              <div class="ef-field">
                <label>Training Status</label>
                <select name="s9_status" id="ep-s9-status">
                  <option value="">-- select --</option>
                  <option value="PENDING">Pending</option>
                  <option value="SCHEDULED">Scheduled</option>
                  <option value="COMPLETE">Complete</option>
                  <option value="NO_SHOW">No Show</option>
                </select>
              </div>
            </div>
            <div class="acc-section-label">Stage Dates</div>
            <div class="ef-grid">
              <div class="ef-field">
                <label>Entered</label>
                <input type="date" name="s9_entered_at" id="ep-s9-in">
              </div>
              <div class="ef-field">
                <label>Exited</label>
                <input type="date" name="s9_exited_at" id="ep-s9-out">
              </div>
            </div>
          </div>
        </div>

        <!-- S8 - Offer Letter Signed -->
        <div class="acc-item">
          <div class="acc-header" onclick="toggleAcc(this)">
            <div class="acc-num pending" id="acc-num-7">8</div>
            <div class="acc-title">S8 &mdash; Offer Letter Signed</div>
            <span class="acc-chevron">&#9660;</span>
          </div>
          <div class="acc-body">
            <div class="acc-section-label">Stage dates</div>
            <div class="ef-grid">
              <div class="ef-field">
                <label>Stage Data Entered</label>
                <input type="date" name="offer_letter_entered_at" id="ep-offer-in">
              </div>
              <div class="ef-field">
                <label>Stage Date Completed</label>
                <input type="date" name="offer_letter_exited_at" id="ep-offer-out">
              </div>
            </div>
            <div class="ef-grid">
              <div class="ef-field">
                <label>Offer Letter Signed</label>
                <select name="offer_letter_signed" id="ep-offer-signed">
                  <option value="0">No</option>
                  <option value="1">Yes</option>
                </select>
              </div>
              <div class="ef-field">
                <label>Upload Offer Letter</label>
                <input type="file" name="offer_letter_doc" id="ep-offer-doc" accept=".pdf,application/pdf,image/*">
                <div id="ep-offer-doc-cur" style="font-size:11px;color:#64748b;margin-top:6px;"></div>
              </div>
            </div>
          </div>
        </div>

      </div><!-- end stage accordions -->
    </form>
  </div><!-- ep-body -->
  <div class="ep-footer">
    <button type="submit" form="editForm"
            style="flex:1;padding:10px;background:#2563eb;color:#fff;border:none;border-radius:8px;font-size:14px;font-weight:700;cursor:pointer;">
      Save Changes
    </button>
    <button type="button" onclick="closeAll()"
            style="padding:10px 20px;background:#f1f5f9;color:#374151;border:none;border-radius:8px;font-size:14px;font-weight:600;cursor:pointer;">
      Cancel
    </button>
  </div>
</div>

<script>
var SL = [
  "S1 Background Check","S2 Drug Test Details","S3 Training Schedule/Day1 & Day2",
  "S4 ADP Onboarding Completed","S5 Orientation","S6 Schedule Fixed",
  "S7 Day 1 On-Road Training","S8 Offer Letter Signed"
];
var SS = [
  "Background Check","Drug Test Details","Training Schedule/Day1 & Day2",
  "ADP Onboarding","Orientation","Schedule Fixed","Day 1 On-Road","Offer Letter Signed"
];
var SK = ["S1","S2","S3","S4","S5","S6","S7","S8"];
/* Visible edit accordions — DB field nums still 1,2,4/5,6,7,8,9; S8 uses offer_letter_* */
var ACC_SK = ["S1","S2","S3","S4","S5","S6","S7","S8"];
var ACC_FIELD = {S1:1, S2:2, S3:4, S4:6, S5:7, S6:8, S7:9, S8:0};

function pipelineFromField(n) {
  if (n <= 2) return 'S' + n;
  if (n === 3 || n === 4 || n === 5) return 'S3';
  if (n === 6) return 'S4';
  if (n === 7) return 'S5';
  if (n === 8) return 'S6';
  if (n === 9) return 'S7';
  return 'S1';
}

function accIdxForStage(stage) {
  if (stage === 'S9') stage = 'S7';
  var i = ACC_SK.indexOf(stage);
  return i < 0 ? 0 : i;
}

function colorAccNums(stage) {
  var cur = accIdxForStage(stage);
  for (var i = 0; i < ACC_SK.length; i++) {
    var numEl = document.getElementById('acc-num-' + i);
    if (!numEl) continue;
    numEl.className = 'acc-num ' + (i < cur ? 'done' : i === cur ? 'active' : 'pending');
  }
}

function openAccForStage(stage) {
  var cur = accIdxForStage(stage);
  var items = document.querySelectorAll('#ep-stages-acc > .acc-item');
  for (var j = 0; j < items.length; j++) {
    var body = items[j].querySelector('.acc-body');
    var chev = items[j].querySelector('.acc-chevron');
    if (!body) continue;
    if (j === cur) {
      body.classList.add('open');
      if (chev) chev.classList.add('open');
    } else {
      body.classList.remove('open');
      if (chev) chev.classList.remove('open');
    }
  }
}

function ensureSelectOption(selId, code, label) {
  var el = document.getElementById(selId);
  if (!el || !code) return;
  for (var i = 0; i < el.options.length; i++) {
    if (el.options[i].value === code) return;
  }
  var opt = document.createElement('option');
  opt.value = code;
  opt.textContent = label || code;
  var addOpt = el.querySelector('option[value="__ADD_NEW__"]');
  if (addOpt) el.insertBefore(opt, addOpt); else el.appendChild(opt);
}

function wireDrugStatusAdd(selId, kind) {
  var el = document.getElementById(selId);
  if (!el || el.getAttribute('data-wired') === '1') return;
  el.setAttribute('data-wired', '1');
  el.addEventListener('change', function() {
    if (this.value !== '__ADD_NEW__') {
      this.setAttribute('data-prev', this.value);
      return;
    }
    var prev = this.getAttribute('data-prev') || '';
    var label = prompt('New status name:', '');
    if (!label || !label.trim()) { this.value = prev; return; }
    var body = new URLSearchParams();
    body.append('action', 'addDrugStatus');
    body.append('kind', kind);
    body.append('label', label.trim());
    var self = this;
    fetch('DAOnboarding.jsp', {
      method: 'POST',
      headers: {'Content-Type':'application/x-www-form-urlencoded'},
      body: body.toString(),
      credentials: 'same-origin'
    }).then(function(r){ return r.json(); }).then(function(d){
      if (!d || !d.ok) {
        alert((d && d.mesg) ? d.mesg : 'Could not add status');
        self.value = prev;
        return;
      }
      ensureSelectOption(selId, d.code, d.label);
      self.value = d.code;
      self.setAttribute('data-prev', d.code);
    }).catch(function(){ self.value = prev; alert('Could not add status'); });
  });
}

/* ── Detail panel tab switcher ── */
function dpTab(btn, tabId) {
  document.querySelectorAll('.dp-tab').forEach(function(b) {
    b.style.color = '#94a3b8'; b.style.borderBottom = 'none'; b.classList.remove('active');
  });
  btn.style.color = '#2563eb'; btn.style.borderBottom = '2px solid #2563eb'; btn.classList.add('active');
  ['dp-tab-progress','dp-tab-history'].forEach(function(id) {
    document.getElementById(id).style.display = id === tabId ? '' : 'none';
  });
}

/* ── Pipeline table sort ── */
function obSort(th) {
  var table = th.closest('table'); if (!table) return;
  var head = th.parentNode;
  var idx = Array.prototype.indexOf.call(head.children, th);
  var asc = th.getAttribute('data-dir') !== 'asc';
  head.querySelectorAll('th').forEach(function(o) {
    if (o !== th) {
      o.removeAttribute('data-dir');
      var a = o.querySelector('.ar');
      if (a) a.textContent = '';
    }
  });
  th.setAttribute('data-dir', asc ? 'asc' : 'desc');
  var ar = th.querySelector('.ar');
  if (ar) ar.textContent = asc ? '▲' : '▼';
  var tb = table.tBodies[0]; if (!tb) return;
  var rows = Array.prototype.slice.call(tb.querySelectorAll('tr[data-id]'));
  rows.sort(function(a, b) {
    var ta = a.children[idx], tbCell = b.children[idx];
    var x = (ta && ta.getAttribute('data-sort')) || (ta ? (ta.textContent || '') : '');
    var y = (tbCell && tbCell.getAttribute('data-sort')) || (tbCell ? (tbCell.textContent || '') : '');
    x = String(x).replace(/\s+/g, ' ').trim();
    y = String(y).replace(/\s+/g, ' ').trim();
    var nx = parseFloat(x.replace(/[^0-9.\-]/g, ''));
    var ny = parseFloat(y.replace(/[^0-9.\-]/g, ''));
    var num = x !== '' && y !== '' && !isNaN(nx) && !isNaN(ny)
      && /^[-0-9.]+$/.test(x.replace(/\s/g, '')) && /^[-0-9.]+$/.test(y.replace(/\s/g, ''));
    var cmp = num ? (nx - ny) : x.toLowerCase().localeCompare(y.toLowerCase());
    if (cmp === 0) return 0;
    return asc ? cmp : -cmp;
  });
  rows.forEach(function(r) { tb.appendChild(r); });
}

/* ── View panel ── */
function openDetail(id) {
  var d = (window._ob || {})[id];
  if (!d) return;
  document.getElementById('dp-name').textContent  = d.name;
  document.getElementById('dp-sub').innerHTML     = 'Application #' + id + (d.ob_id && d.ob_id!=='0' ? ' &bull; Onboarding #' + d.ob_id : '');
  document.getElementById('dp-email').innerHTML = d.email
    ? '<a href="mailto:' + d.email + '" style="color:#2563eb;text-decoration:none;">' + d.email + '</a>'
    : '-';
  document.getElementById('dp-phone').innerHTML = d.phone
    ? '<a href="tel:' + d.phone + '" style="color:#2563eb;text-decoration:none;">' + d.phone + '</a>'
    : '-';
  document.getElementById('dp-avail').textContent = d.avail  || '-';
  document.getElementById('dp-status').innerHTML  = d.status
    ? '<span style="font-weight:700;">' + d.status.replace('_',' ') + '</span>' : '-';
  var holdRow = document.getElementById('dp-hold-row');
  if (d.status === 'ON_HOLD' && d.hold_reason) {
    document.getElementById('dp-hold-reason').textContent = d.hold_reason;
    holdRow.style.display = '';
  } else { holdRow.style.display = 'none'; }
  document.getElementById('dp-day1').textContent  = d.day1   || 'TBD';
  document.getElementById('dp-done').textContent  = d.done   || 'Not yet';
  document.getElementById('dp-notes').textContent = d.notes  || 'No notes.';

  var docDefs = [
    {key:'dl',       label:"Driver's License"},
    {key:'ssn',      label:'SSN Card'},
    {key:'wp_front', label:'Work Permit (Front)'},
    {key:'wp_back',  label:'Work Permit (Back)'},
    {key:'drug_test', label:'Drug Test Result', pathField:'drug_doc'},
    {key:'offer_letter', label:'Offer Letter', pathField:'offer_doc', driveField:'drive_offer'}
  ];
  var docsHtml = '';
  for (var di = 0; di < docDefs.length; di++) {
    var dk = docDefs[di];
    var local = dk.pathField ? (d[dk.pathField] || '') : (d['doc_' + dk.key] || '');
    var drive = dk.driveField ? (d[dk.driveField] || '') : (dk.pathField ? '' : (d['drive_' + dk.key] || ''));
    var hasDoc = !!(local || drive);
    var viewUrl = hasDoc
      ? 'DADocView.jsp?appId=' + encodeURIComponent(id) + '&doc=' + encodeURIComponent(dk.key)
      : '';
    docsHtml += '<div style="border:1px solid #e2e8f0;border-radius:8px;padding:10px;background:#f8fafc;">' +
      '<div style="font-size:10px;font-weight:700;color:#94a3b8;text-transform:uppercase;margin-bottom:4px;">' + dk.label + '</div>';
    if (hasDoc) {
      docsHtml += '<a href="' + viewUrl + '" target="_blank" rel="noopener" style="font-size:12px;font-weight:700;color:#2563eb;text-decoration:none;">View</a>';
      if (drive) {
        docsHtml += ' &nbsp;<a href="' + drive + '" target="_blank" rel="noopener" style="font-size:11px;color:#64748b;text-decoration:none;">Drive</a>';
      }
    } else {
      docsHtml += '<span style="font-size:12px;color:#cbd5e1;">Not uploaded</span>';
    }
    docsHtml += '</div>';
  }
  document.getElementById('dp-docs').innerHTML = docsHtml;

  var stageKey = d.stage;
  if (stageKey === 'S9') stageKey = 'S7';
  var curIdx = ACC_SK.indexOf(stageKey);
  var html = '';
  for (var i = 0; i < ACC_SK.length; i++) {
    var sk = ACC_SK[i];
    var fieldN = ACC_FIELD[sk];
    var valIdx = fieldN - 1;
    var val = (fieldN > 0 && d.vals && d.vals[valIdx] != null) ? d.vals[valIdx] : '';
    if (sk === 'S3') {
      var parts = [];
      if (d.s4_status) parts.push(d.s4_status);
      if (d.s4_sched) parts.push('Sched ' + d.s4_sched);
      if (d.s5_day1) parts.push('Day1 ' + d.s5_day1);
      if (d.s5_day2) parts.push('Day2 ' + d.s5_day2);
      if (d.vals && d.vals[4]) parts.push(d.vals[4]);
      val = parts.join(' · ');
    }
    if (sk === 'S8') {
      val = (d.offer_signed === '1' || d.offer_signed === 1) ? 'Signed' : 'Not signed';
      if (d.offer_doc) val += ' · Doc on file';
    }
    var isDone   = i < curIdx;
    var isActive = i === curIdx;
    var bg   = isDone ? '#16a34a' : isActive ? '#2563eb' : '#e2e8f0';
    var fg   = (isDone || isActive) ? '#fff' : '#94a3b8';
    var icon = isDone ? '&#10003;' : (i + 1);
    var entered = '';
    var exited = '';
    if (sk === 'S8') {
      entered = toDateLocal(d.offer_in || '');
      exited  = toDateLocal(d.offer_out || '');
    } else {
      entered = toDateLocal(d['s' + fieldN + '_in'] || '');
      exited  = toDateLocal(d['s' + fieldN + '_out'] || '');
    }
    if (sk === 'S3' && !entered) entered = toDateLocal(d.s5_in || '');
    if (sk === 'S3' && !exited) exited = toDateLocal(d.s5_out || '');
    var dateLine = '';
    if (entered) dateLine += 'In: ' + entered;
    if (exited)  dateLine += (dateLine ? ' &rarr; Out: ' : 'Out: ') + exited;
    html += '<div class="dp-stage-row">' +
      '<div class="dp-stage-num" style="background:' + bg + ';color:' + fg + '">' + icon + '</div>' +
      '<div class="dp-stage-body"><h4>' + SS[i] + '</h4>' +
      '<p>' + (val || (isDone ? 'Complete' : isActive ? 'In Progress' : 'Pending')) + '</p>' +
      (dateLine ? '<p style="color:#64748b;font-size:10px;margin-top:2px;">' + dateLine + '</p>' : '') +
      '</div></div>';
  }
  document.getElementById('dp-stages').innerHTML = html;

  /* Reset to progress tab */
  document.getElementById('dp-tab-progress').style.display = '';
  document.getElementById('dp-tab-history').style.display  = 'none';
  document.querySelectorAll('.dp-tab').forEach(function(b,i) {
    b.style.color = i===0 ? '#2563eb' : '#94a3b8';
    b.style.borderBottom = i===0 ? '2px solid #2563eb' : 'none';
  });

  /* Pre-load history if we have an ob_id */
  if (d.ob_id && d.ob_id !== '0') {
    document.getElementById('dp-history-body').innerHTML =
      '<div style="padding:24px;text-align:center;color:#94a3b8;font-size:12px;">Loading history&hellip;</div>';
    fetch('DAOnboarding.jsp?action=stagelog&ob_id=' + d.ob_id)
      .then(function(r) { return r.json(); })
      .then(function(logs) {
        if (!logs.length) {
          document.getElementById('dp-history-body').innerHTML =
            '<div style="padding:24px;text-align:center;color:#94a3b8;font-size:12px;">No stage transitions recorded yet.</div>';
          return;
        }
        var h = '<table style="width:100%;border-collapse:collapse;font-size:11px;">' +
          '<thead><tr style="background:#f8fafc;">' +
          '<th style="padding:6px 10px;text-align:left;color:#64748b;font-weight:700;text-transform:uppercase;letter-spacing:.3px;">Stage</th>' +
          '<th style="padding:6px 10px;text-align:left;color:#64748b;font-weight:700;text-transform:uppercase;letter-spacing:.3px;">Entered</th>' +
          '<th style="padding:6px 10px;text-align:left;color:#64748b;font-weight:700;text-transform:uppercase;letter-spacing:.3px;">Exited</th>' +
          '<th style="padding:6px 10px;text-align:right;color:#64748b;font-weight:700;text-transform:uppercase;letter-spacing:.3px;">Days</th>' +
          '<th style="padding:6px 10px;text-align:left;color:#64748b;font-weight:700;text-transform:uppercase;letter-spacing:.3px;">By</th>' +
          '</tr></thead><tbody>';
        logs.forEach(function(l) {
          var statusColor = l.status==='COMPLETE' ? '#16a34a' : '#2563eb';
          h += '<tr style="border-bottom:1px solid #f1f5f9;">' +
            '<td style="padding:7px 10px;"><span style="font-weight:700;color:' + statusColor + ';">' + (l.stage||'') + '</span>' +
            '<div style="color:#94a3b8;font-size:10px;">' + (l.name||'') + '</div></td>' +
            '<td style="padding:7px 10px;color:#374151;">' + ((l.entered||'').substring(0,16)||'-') + '</td>' +
            '<td style="padding:7px 10px;color:#374151;">' + ((l.exited||'').substring(0,16)||'Active') + '</td>' +
            '<td style="padding:7px 10px;text-align:right;color:#7c3aed;font-weight:700;">' + (l.days ? parseFloat(l.days).toFixed(1) : '-') + '</td>' +
            '<td style="padding:7px 10px;color:#94a3b8;">' + (l.by||'-') + '</td>' +
            '</tr>';
        });
        h += '</tbody></table>';
        document.getElementById('dp-history-body').innerHTML = h;
      })
      .catch(function() {
        document.getElementById('dp-history-body').innerHTML =
          '<div style="padding:24px;text-align:center;color:#dc2626;font-size:12px;">Could not load history.</div>';
      });
  } else {
    document.getElementById('dp-history-body').innerHTML =
      '<div style="padding:24px;text-align:center;color:#94a3b8;font-size:12px;">No onboarding record yet &mdash; open Edit to start tracking.</div>';
  }

  document.getElementById('detailPanel').classList.add('open');
  document.getElementById('dpOverlay').classList.add('open');
}

/* ── Edit panel ── */
function toDateLocal(dt) {
  if (!dt) return '';
  /* MySQL datetime/date -> date input "YYYY-MM-DD" (no time) */
  return String(dt).replace('T', ' ').substring(0, 10);
}

function setVal(id, val) {
  var el = document.getElementById(id);
  if (!el) return;
  if (el.tagName === 'SELECT') {
    for (var i = 0; i < el.options.length; i++) {
      if (el.options[i].value === val) { el.selectedIndex = i; break; }
    }
  } else {
    el.value = val || '';
  }
}

function ensureStatusOption(status) {
  if (!status) return;
  var el = document.getElementById('ep-ob-status');
  if (!el) return;
  for (var i = 0; i < el.options.length; i++) {
    if (el.options[i].value === status) return;
  }
  var opt = document.createElement('option');
  opt.value = status;
  opt.textContent = status.replace(/^X_/, '').replace(/_/g, ' ');
  var addOpt = el.querySelector('option[value="__ADD_NEW__"]');
  if (addOpt) el.insertBefore(opt, addOpt);
  else el.appendChild(opt);
}

function openEdit(id) {
  var d = (window._ob || {})[id];
  if (!d) return;
  document.getElementById('ep-name').textContent = d.name;
  document.getElementById('ep-sub').textContent  = 'Application #' + id + ' &bull; Onboarding #' + d.ob_id;
  document.getElementById('ep-ob-id').value        = d.ob_id || '0';
  document.getElementById('ep-app-id').value       = id;
  document.getElementById('ep-app-id-create').value = id;

  /* Applicant info fields */
  document.getElementById('ep-first-name').value = d.first_name || '';
  document.getElementById('ep-last-name').value  = d.last_name  || '';
  document.getElementById('ep-app-email').value  = d.email      || '';
  document.getElementById('ep-app-phone').value  = d.phone      || '';
  setVal('ep-avail-type',      d.avail_type  || 'FULLTIME');
  setVal('ep-app-status-sel',  d.app_status  || 'PENDING');

  var stg = d.stage;
  if (stg === 'S9') stg = 'S7';
  setVal('ep-stage', stg);
  ensureStatusOption(d.status);
  setVal('ep-ob-status',      d.status);
  var obSel = document.getElementById('ep-ob-status');
  if (obSel) obSel.setAttribute('data-prev', d.status || 'PENDING');
  document.getElementById('ep-completed-date').value = (d.done || '').substring(0, 10);
  document.getElementById('ep-notes').value = d.notes || '';
  document.getElementById('ep-hold-reason').value = d.hold_reason || '';
  document.getElementById('hold-reason-row').style.display = (d.status === 'ON_HOLD') ? '' : 'none';

  /* S1 */
  document.getElementById('ep-s1-date').value    = (d.vals[0] || '').substring(0, 10);
  setVal('ep-checkr-status',  d.checkr_status);
  document.getElementById('ep-checkr-cid').value = d.checkr_cid || '';
  document.getElementById('ep-s1-in').value  = toDateLocal(d.s1_in);
  document.getElementById('ep-s1-out').value = toDateLocal(d.s1_out);

  /* S2 Drug Test Details (includes former S3 fields) */
  ensureSelectOption('ep-s2-status', d.s2_status, d.s2_status);
  setVal('ep-s2-status',   d.s2_status);
  var s2sel = document.getElementById('ep-s2-status');
  if (s2sel) s2sel.setAttribute('data-prev', d.s2_status || '');
  document.getElementById('ep-labcorp-id').value = d.labcorp_id || '';
  document.getElementById('ep-drug-loc').value   = d.drug_loc || '';
  document.getElementById('ep-s2-in').value  = toDateLocal(d.s2_in);
  document.getElementById('ep-s2-out').value = toDateLocal(d.s2_out || d.s3_out);
  ensureSelectOption('ep-drug-result', d.drug_result, d.drug_result);
  setVal('ep-drug-result', d.drug_result);
  var drsel = document.getElementById('ep-drug-result');
  if (drsel) drsel.setAttribute('data-prev', d.drug_result || '');
  document.getElementById('ep-s3-result').value  = d.vals[2] || '';
  document.getElementById('ep-s3-in').value  = toDateLocal(d.s3_in || d.s2_in);
  document.getElementById('ep-s3-out').value = toDateLocal(d.s3_out || d.s2_out);
  var docCur = document.getElementById('ep-drug-doc-cur');
  var docInp = document.getElementById('ep-drug-doc');
  if (docInp) docInp.value = '';
  if (docCur) {
    if (d.drug_doc) {
      var nm = d.drug_doc.replace(/\\/g,'/').split('/').pop();
      var viewDrug = 'DADocView.jsp?appId=' + encodeURIComponent(id) + '&doc=drug_test';
      docCur.innerHTML = 'On file: <a href="' + viewDrug + '" target="_blank" rel="noopener" style="color:#2563eb;font-weight:700;">' + nm + '</a>';
    } else {
      docCur.textContent = 'No test result document uploaded yet';
    }
  }
  wireDrugStatusAdd('ep-s2-status', 'order');
  wireDrugStatusAdd('ep-drug-result', 'result');

  /* S3 Training Schedule/Day1 & Day2 (former S4 + S5) */
  ensureSelectOption('ep-s4-status', d.s4_status, d.s4_status);
  setVal('ep-s4-status',   d.s4_status);
  var s4sel = document.getElementById('ep-s4-status');
  if (s4sel) s4sel.setAttribute('data-prev', d.s4_status || '');
  document.getElementById('ep-s4-sched').value = (d.s4_sched || '').substring(0, 10);
  document.getElementById('ep-s4-in').value  = toDateLocal(d.s4_in || d.s5_in);
  document.getElementById('ep-s4-out').value = toDateLocal(d.s4_out || d.s5_out);
  document.getElementById('ep-s5-day1').value   = (d.s5_day1 || '').substring(0, 10);
  document.getElementById('ep-s5-day2').value   = (d.s5_day2 || '').substring(0, 10);
  document.getElementById('ep-s5-result').value = d.vals[4] || '';
  document.getElementById('ep-s5-in').value  = toDateLocal(d.s5_in || d.s4_in);
  document.getElementById('ep-s5-out').value = toDateLocal(d.s5_out || d.s4_out);
  wireDrugStatusAdd('ep-s4-status', 'training');

  /* S4 ADP (DB s6_*) */
  setVal('ep-s6-done', (d.vals[5] === '1' || d.vals[5] === 1) ? '1' : '0');
  document.getElementById('ep-s6-notes').value = d.s6_notes || '';
  document.getElementById('ep-s6-in').value  = toDateLocal(d.s6_in);
  document.getElementById('ep-s6-out').value = toDateLocal(d.s6_out);

  /* S5 Orientation (DB s7_*) */
  setVal('ep-s7-done', (d.vals[6] === '1' || d.vals[6] === 1) ? '1' : '0');
  document.getElementById('ep-s7-notes').value = d.s7_notes || '';
  document.getElementById('ep-s7-in').value  = toDateLocal(d.s7_in);
  document.getElementById('ep-s7-out').value = toDateLocal(d.s7_out);

  /* S8 */
  setVal('ep-s8-adp', d.vals[7]);
  document.getElementById('ep-s8-in').value  = toDateLocal(d.s8_in);
  document.getElementById('ep-s8-out').value = toDateLocal(d.s8_out);

  /* S7 Day 1 (DB s9_*) */
  document.getElementById('ep-s9-day1').value = (d.day1 || '').substring(0, 10);
  setVal('ep-s9-status', d.vals[8]);
  document.getElementById('ep-s9-in').value  = toDateLocal(d.s9_in);
  document.getElementById('ep-s9-out').value = toDateLocal(d.s9_out);

  /* S8 Offer Letter */
  setVal('ep-offer-signed', (d.offer_signed === '1' || d.offer_signed === 1) ? '1' : '0');
  document.getElementById('ep-offer-in').value  = toDateLocal(d.offer_in);
  document.getElementById('ep-offer-out').value = toDateLocal(d.offer_out);
  var offerCur = document.getElementById('ep-offer-doc-cur');
  var offerInp = document.getElementById('ep-offer-doc');
  if (offerInp) offerInp.value = '';
  if (offerCur) {
    if (d.offer_doc) {
      var onm = d.offer_doc.replace(/\\/g,'/').split('/').pop();
      var viewOffer = 'DADocView.jsp?appId=' + encodeURIComponent(id) + '&doc=offer_letter';
      offerCur.innerHTML = 'On file: <a href="' + viewOffer + '" target="_blank" rel="noopener" style="color:#2563eb;font-weight:700;">' + onm + '</a>';
    } else {
      offerCur.textContent = 'No offer letter uploaded yet';
    }
  }

  colorAccNums(d.stage);
  openAccForStage(d.stage);

  document.getElementById('editPanel').classList.add('open');
  document.getElementById('dpOverlay').classList.add('open');
}

function toggleAcc(header) {
  var body = header.nextElementSibling;
  var chev = header.querySelector('.acc-chevron');
  body.classList.toggle('open');
  chev.classList.toggle('open');
}

/* Stay on S7 when Day 1 date is set; COMPLETE only after S8 Offer Letter Signed */
function markS7Complete(day1Val) {
  setVal('ep-stage', 'S7');
  colorAccNums('S7');
  var ob = document.getElementById('ep-ob-status');
  if (ob && (ob.value === 'COMPLETE' || ob.value === 'NEW' || !ob.value)) {
    setVal('ep-ob-status', 'ON_TRACK');
  }
}

function wireS7Complete() {
  var s9day1 = document.getElementById('ep-s9-day1');
  if (s9day1) {
    s9day1.onchange = function() { if (this.value) markS7Complete(this.value); };
  }
  var s9in = document.getElementById('ep-s9-in');
  if (s9in) {
    s9in.onchange = function() {
      if (this.value) {
        setVal('ep-stage', 'S7');
        var numEl = document.getElementById('acc-num-6');
        if (numEl) numEl.className = 'acc-num active';
      }
    };
  }
  var s4sched = document.getElementById('ep-s4-sched');
  if (s4sched) {
    s4sched.addEventListener('change', function() {
      if (!this.value) return;
      var stageSelect = document.getElementById('ep-stage');
      var curIdx = ACC_SK.indexOf(stageSelect.value);
      var nextIdx = ACC_SK.indexOf('S3');
      if (nextIdx > curIdx) {
        stageSelect.value = 'S3';
        colorAccNums('S3');
      }
    });
  }
  var offerSigned = document.getElementById('ep-offer-signed');
  if (offerSigned) {
    offerSigned.onchange = function() {
      if (this.value === '1') {
        setVal('ep-stage', 'S8');
        setVal('ep-ob-status', 'COMPLETE');
        colorAccNums('S8');
        var cd = document.getElementById('ep-completed-date');
        var outEl = document.getElementById('ep-offer-out');
        if (cd && !cd.value) {
          var today = new Date();
          cd.value = today.getFullYear() + '-' + ('0'+(today.getMonth()+1)).slice(-2) + '-' + ('0'+today.getDate()).slice(-2);
        }
        if (outEl && !outEl.value && cd && cd.value) outEl.value = cd.value;
      } else if (this.value === '0') {
        var ob = document.getElementById('ep-ob-status');
        if (ob && ob.value === 'COMPLETE') setVal('ep-ob-status', 'ON_TRACK');
      }
    };
  }
  var offerIn = document.getElementById('ep-offer-in');
  if (offerIn) {
    offerIn.addEventListener('change', function() {
      if (!this.value) return;
      var stageSelect = document.getElementById('ep-stage');
      var curIdx = ACC_SK.indexOf(stageSelect.value);
      var nextIdx = ACC_SK.indexOf('S8');
      if (nextIdx > curIdx) {
        stageSelect.value = 'S8';
        colorAccNums('S8');
      }
    });
  }
}

/* Auto-advance Current Stage when dispatcher enters a date for a higher stage */
function wireStageAutoAdvance() {
  for (var si = 1; si <= 9; si++) {
    (function(stageIdx) {
      var inEl = document.getElementById('ep-s' + stageIdx + '-in');
      if (!inEl) return;
      inEl.addEventListener('change', function() {
        if (!this.value) return;
        if (stageIdx === 3) return; /* hidden legacy drug timestamp */
        var next = pipelineFromField(stageIdx);
        var stageSelect = document.getElementById('ep-stage');
        var curIdx = ACC_SK.indexOf(stageSelect.value);
        var nextIdx = ACC_SK.indexOf(next);
        if (nextIdx > curIdx) {
          stageSelect.value = next;
          colorAccNums(next);
        }
      });
    })(si);
  }
}

function closeAll() {
  document.getElementById('detailPanel').classList.remove('open');
  document.getElementById('editPanel').classList.remove('open');
  document.getElementById('dpOverlay').classList.remove('open');
}

document.addEventListener('keydown', function(e) { if (e.key === 'Escape') closeAll(); });
document.addEventListener('DOMContentLoaded', function() {
  wireStageAutoAdvance(); wireS7Complete();
  /* Show/hide hold reason when status changes; support Add new status */
  var obStatus = document.getElementById('ep-ob-status');
  if (obStatus) {
    obStatus.addEventListener('change', function() {
      if (this.value === '__ADD_NEW__') {
        var prev = this.getAttribute('data-prev') || 'PENDING';
        var label = prompt('New pipeline status name:', '');
        if (!label || !label.trim()) { this.value = prev; return; }
        var body = new URLSearchParams();
        body.append('action', 'addPipelineStatus');
        body.append('label', label.trim());
        fetch('DAOnboarding.jsp', {
          method: 'POST',
          headers: {'Content-Type':'application/x-www-form-urlencoded'},
          body: body.toString(),
          credentials: 'same-origin'
        }).then(function(r){ return r.json(); }).then(function(d){
          if (!d || !d.ok) {
            alert((d && d.mesg) ? d.mesg : 'Could not add status');
            obStatus.value = prev;
            return;
          }
          var opt = document.createElement('option');
          opt.value = d.code;
          opt.textContent = d.label;
          var addOpt = obStatus.querySelector('option[value="__ADD_NEW__"]');
          if (addOpt) obStatus.insertBefore(opt, addOpt);
          else obStatus.appendChild(opt);
          obStatus.value = d.code;
          obStatus.setAttribute('data-prev', d.code);
          document.getElementById('hold-reason-row').style.display = 'none';
        }).catch(function(){
          alert('Could not add status');
          obStatus.value = prev;
        });
        return;
      }
      this.setAttribute('data-prev', this.value);
      document.getElementById('hold-reason-row').style.display = (this.value === 'ON_HOLD') ? '' : 'none';
    });
  }
});

/* ── Export modal ── */
function openExport() { document.getElementById('exportModal').style.display = 'flex'; }
function closeExport() { document.getElementById('exportModal').style.display = 'none'; }
function doExport() {
  var f = document.getElementById('ex-filter').value;
  var from = document.getElementById('ex-from').value;
  var to   = document.getElementById('ex-to').value;
  var url = 'DAOnboarding.jsp?action=export&exfilter=' + encodeURIComponent(f);
  if (from) url += '&exfrom=' + encodeURIComponent(from);
  if (to)   url += '&exto='   + encodeURIComponent(to);
  window.location.href = url;
  closeExport();
}

/* ── Share modal ── */
function openShare() {
  document.getElementById('shareModal').style.display = 'flex';
  /* Build QR using a simple canvas approach via qrcode lib */
  var url = document.getElementById('shareUrl').value;
  if (window.QRCode && !document.getElementById('qr-canvas').innerHTML) {
    new QRCode(document.getElementById('qr-canvas'), {
      text: url, width: 160, height: 160,
      colorDark:'#0f172a', colorLight:'#ffffff',
      correctLevel: QRCode.CorrectLevel.M
    });
  }
}
function closeShare() { document.getElementById('shareModal').style.display = 'none'; }
function copyShareLink() {
  var url = document.getElementById('shareUrl').value;
  navigator.clipboard.writeText(url).then(function() {
    var btn = document.getElementById('copyBtn');
    btn.textContent = '&#10003; Copied!';
    btn.style.background = '#16a34a';
    setTimeout(function() { btn.innerHTML = '&#128203; Copy Link'; btn.style.background = '#2563eb'; }, 2000);
  });
}
</script>

<!-- Export Modal -->
<div id="exportModal" style="display:none;position:fixed;inset:0;background:rgba(0,0,0,.45);z-index:400;align-items:center;justify-content:center;">
  <div style="background:#fff;border-radius:16px;padding:28px;width:340px;box-shadow:0 20px 60px rgba(0,0,0,.2);position:relative;">
    <button onclick="closeExport()" style="position:absolute;top:14px;right:14px;background:#f1f5f9;border:none;border-radius:50%;width:30px;height:30px;font-size:13px;cursor:pointer;color:#64748b;font-weight:700;">X</button>
    <h2 style="font-size:16px;font-weight:900;color:#0f172a;margin:0 0 4px;">Export to CSV</h2>
    <p style="font-size:12px;color:#64748b;margin:0 0 18px;">Download all onboarding data as a CSV file — opens directly in Excel with no warnings.</p>
    <div style="margin-bottom:14px;">
      <label style="font-size:11px;font-weight:700;color:#374151;display:block;margin-bottom:5px;">Include</label>
      <select id="ex-filter" style="width:100%;padding:8px 10px;border:1px solid #d1d5db;border-radius:7px;font-size:13px;">
        <option value="ALL">All Applicants</option>
        <option value="PIPELINE">Pipeline Only (not hired)</option>
        <option value="HIRED">Hired Only (complete)</option>
      </select>
    </div>
    <div style="display:flex;gap:10px;margin-bottom:18px;">
      <div style="flex:1;">
        <label style="font-size:11px;font-weight:700;color:#374151;display:block;margin-bottom:5px;">Applied From</label>
        <input type="date" id="ex-from" style="width:100%;box-sizing:border-box;padding:7px 9px;border:1px solid #d1d5db;border-radius:7px;font-size:12px;">
      </div>
      <div style="flex:1;">
        <label style="font-size:11px;font-weight:700;color:#374151;display:block;margin-bottom:5px;">Applied To</label>
        <input type="date" id="ex-to" style="width:100%;box-sizing:border-box;padding:7px 9px;border:1px solid #d1d5db;border-radius:7px;font-size:12px;">
      </div>
    </div>
    <button onclick="doExport()" style="width:100%;padding:10px;background:#16a34a;color:#fff;border:none;border-radius:8px;font-size:13px;font-weight:700;cursor:pointer;">
      &#11015; Download CSV (opens in Excel)
    </button>
  </div>
</div>

<!-- Share Modal -->
<div id="shareModal" style="display:none;position:fixed;inset:0;background:rgba(0,0,0,.45);z-index:400;align-items:center;justify-content:center;">
  <div style="background:#fff;border-radius:16px;padding:32px;width:360px;box-shadow:0 20px 60px rgba(0,0,0,.2);position:relative;">
    <button onclick="closeShare()" style="position:absolute;top:14px;right:14px;background:#f1f5f9;border:none;border-radius:50%;width:30px;height:30px;font-size:13px;cursor:pointer;color:#64748b;font-weight:700;">X</button>
    <h2 style="font-size:16px;font-weight:900;color:#0f172a;margin:0 0 4px;">Share Application Form</h2>
    <p style="font-size:12px;color:#64748b;margin:0 0 20px;">Send this link to candidates or print the QR code for in-person recruiting.</p>
    <div style="text-align:center;margin-bottom:20px;">
      <div id="qr-canvas" style="display:inline-block;padding:10px;border:1px solid #e2e8f0;border-radius:10px;background:#fff;"></div>
    </div>
    <input id="shareUrl" type="text" readonly
           value="<%=request.getScheme()%>://<%=request.getServerName()%>:<%=request.getServerPort()%><%=request.getContextPath()%>/jsp/DAApplicationForm.jsp"
           style="width:100%;box-sizing:border-box;padding:8px 10px;border:1px solid #d1d5db;border-radius:7px;font-size:11px;color:#374151;background:#f8fafc;margin-bottom:12px;"
           onclick="this.select()">
    <div style="display:flex;gap:8px;">
      <button id="copyBtn" onclick="copyShareLink()"
              style="flex:1;padding:9px;background:#2563eb;color:#fff;border:none;border-radius:7px;font-size:12px;font-weight:700;cursor:pointer;">
        &#128203; Copy Link
      </button>
      <a href="<%=request.getScheme()%>://<%=request.getServerName()%>:<%=request.getServerPort()%><%=request.getContextPath()%>/jsp/DAApplicationForm.jsp"
         target="_blank" rel="noopener"
         style="flex:1;padding:9px;background:#0f172a;color:#fff;border-radius:7px;font-size:12px;font-weight:700;cursor:pointer;text-decoration:none;text-align:center;">
        &#128279; Open Form
      </a>
    </div>
  </div>
</div>

<!-- QR Code library (lightweight, no external data sent) -->
<script src="https://cdnjs.cloudflare.com/ajax/libs/qrcodejs/1.0.0/qrcode.min.js"></script>
<%@ include file="includeFooter.jsp"%>
