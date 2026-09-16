package com.tools;

import java.io.File;

import com.beans.ApplicationConfig;

/**
 * Vehicle / app upload root:
 *   UAT:    F:\JavProject\serverUpload
 *   Laptop: C:\JavProject\serverUpload
 *
 * Vehicle docs live under:
 *   {root}\{VehicleNumber}\RegistrationForms\
 *   {root}\{VehicleNumber}\ROs\
 *   {root}\{VehicleNumber}\oil change\
 *   {root}\{VehicleNumber}\Other docs\
 *
 * Optional override: web.xml init-param serverUploadPath.
 */
public final class ServerUploadPaths {

	public static final String UAT_ROOT = "F:\\JavProject\\serverUpload";
	public static final String LAPTOP_ROOT = "C:\\JavProject\\serverUpload";

	public static final String FOLDER_REGISTRATION = "RegistrationForms";
	public static final String FOLDER_RO = "ROs";
	public static final String FOLDER_OIL = "oil change";
	public static final String FOLDER_OTHER = "Other docs";
	public static final String FOLDER_INSURANCE = "Insurance";

	private static volatile String cachedRoot = null;

	private ServerUploadPaths() {
	}

	public static synchronized void clearCache() {
		cachedRoot = null;
	}

	/** Absolute root — F: (UAT) then C: (laptop). */
	public static String getRoot() {
		if (cachedRoot != null && cachedRoot.length() > 0
				&& canUseDirectory(new File(cachedRoot)))
			return cachedRoot;

		String configured = "";
		try {
			configured = ApplicationConfig.getServerUploadPath();
			if (configured == null) configured = "";
			configured = configured.trim();
		} catch (Throwable t) {
			configured = "";
		}

		String[] candidates;
		if (configured.length() > 0) {
			candidates = new String[] { configured, UAT_ROOT, LAPTOP_ROOT };
		} else {
			candidates = new String[] { UAT_ROOT, LAPTOP_ROOT };
		}

		for (int i = 0; i < candidates.length; i++) {
			String c = candidates[i];
			if (c == null || c.trim().length() == 0) continue;
			File root = new File(c.trim());
			try {
				File parent = root.getParentFile();
				if (parent != null && !parent.exists()) {
					/* create C:\JavProject if needed; skip missing drive letters */
					String abs = parent.getAbsolutePath();
					if (abs.length() <= 3) /* e.g. F:\ */
						continue;
					parent.mkdirs();
				}
				if (parent != null && !parent.exists())
					continue;
				if (!root.exists())
					root.mkdirs();
				if (canUseDirectory(root) && canWriteProbe(root)) {
					cachedRoot = root.getAbsolutePath();
					System.out.println("ServerUploadPaths root=" + cachedRoot);
					return cachedRoot;
				}
			} catch (Exception ignore) {
			}
		}

		/* Last resort: webapp docs/serverUpload */
		File fallback = new File(docsRoot(), "serverUpload");
		try { fallback.mkdirs(); } catch (Exception ignore) { }
		cachedRoot = fallback.getAbsolutePath();
		System.out.println("ServerUploadPaths FALLBACK root=" + cachedRoot);
		return cachedRoot;
	}

	/** Folder-safe vehicle number (e.g. MVPG-08, CDV-MVPG-22). */
	public static String safeVehicleFolder(String vehicleNumber) {
		String t = vehicleNumber == null ? "" : vehicleNumber.trim();
		t = t.replaceAll("[\\\\/:*?\"<>|]+", "_").replaceAll("\\s+", "_");
		while (t.startsWith(".")) t = t.substring(1);
		if (t.length() == 0) t = "Unknown";
		return t;
	}

	/**
	 * Absolute dir:
	 * {root}\{VehicleNumber}\{RegistrationForms|ROs|oil change|Other docs}
	 */
	public static String getVehicleDocDir(String vehicleNumber, String folderName) {
		String folder = folderName == null || folderName.trim().length() == 0
				? FOLDER_OTHER : folderName.trim();
		File t = new File(getRoot(), safeVehicleFolder(vehicleNumber)
				+ File.separator + folder);
		try { t.mkdirs(); } catch (Exception ignore) { }
		return t.getAbsolutePath();
	}

	/** Mirror under webapp docs for browser View links. */
	public static String getDocsMirrorDir(String vehicleNumber, String folderName) {
		String folder = folderName == null || folderName.trim().length() == 0
				? FOLDER_OTHER : folderName.trim();
		File t = new File(docsRoot(), "serverUpload" + File.separator
				+ safeVehicleFolder(vehicleNumber) + File.separator + folder);
		try { t.mkdirs(); } catch (Exception ignore) { }
		return t.getAbsolutePath();
	}

	/** Relative web path stored in DB (View uses ../ + this). */
	public static String relativeDocsPath(String vehicleNumber, String folderName,
			String fileName) {
		String folder = folderName == null || folderName.trim().length() == 0
				? FOLDER_OTHER : folderName.trim();
		return "docs/serverUpload/" + safeVehicleFolder(vehicleNumber) + "/"
				+ folder + "/" + fileName;
	}

	public static boolean isJavProjectServerUpload() {
		String r = getRoot().replace('/', '\\').toLowerCase();
		return r.indexOf("\\javproject\\serverupload") >= 0;
	}

	/** @deprecated use {@link #isJavProjectServerUpload()} */
	public static boolean isUatServerUpload() {
		return isJavProjectServerUpload();
	}

	public static String docsRoot() {
		try {
			String docs = ApplicationConfig.getDocsPath();
			if (docs != null && docs.trim().length() > 0)
				return docs.trim();
		} catch (Throwable ignore) {
		}
		try {
			String app = ApplicationConfig.getApplicationPath();
			if (app != null && app.trim().length() > 0)
				return app.trim() + File.separator + "docs";
		} catch (Throwable ignore) {
		}
		String catalina = System.getProperty("catalina.base");
		if (catalina != null && catalina.trim().length() > 0)
			return catalina.trim() + File.separator + "webapps"
					+ File.separator + "MVPx" + File.separator + "docs";
		return "C:" + File.separator + "Program Files" + File.separator
				+ "Apache Software Foundation" + File.separator + "Tomcat 9.0"
				+ File.separator + "webapps" + File.separator + "MVPx"
				+ File.separator + "docs";
	}

	private static boolean canUseDirectory(File root) {
		try {
			return root != null && root.exists() && root.isDirectory();
		} catch (Exception e) {
			return false;
		}
	}

	private static boolean canWriteProbe(File root) {
		File probe = null;
		try {
			probe = File.createTempFile("mvpx_upload_", ".tmp", root);
			return probe.isFile();
		} catch (Exception e) {
			return false;
		} finally {
			if (probe != null)
				try { probe.delete(); } catch (Exception ignore) { }
		}
	}

	public static String getTemp() {
		File t = new File(getRoot(), "localUpload");
		try { t.mkdirs(); } catch (Exception ignore) { }
		return t.getAbsolutePath();
	}

	public static String getDAApplications() {
		File t = new File(getRoot(), "DAApplications");
		try { t.mkdirs(); } catch (Exception ignore) { }
		return t.getAbsolutePath();
	}

	/** @deprecated prefer {@link #getVehicleDocDir(String, String)} */
	public static String getRegistrationForms() {
		File t = new File(getRoot(), FOLDER_REGISTRATION);
		try { t.mkdirs(); } catch (Exception ignore) { }
		return t.getAbsolutePath();
	}

	public static String getModuleUpload(String uploadFrom, String loginUser) {
		String from = uploadFrom == null ? "Common" : uploadFrom.trim();
		String user = loginUser == null ? "system" : loginUser.trim();
		File t = new File(getRoot(), from + File.separator + user);
		try { t.mkdirs(); } catch (Exception ignore) { }
		return t.getAbsolutePath();
	}

	/** {root}\Insurance\ — fleet Auto Insurance PDFs */
	public static String getInsuranceDir() {
		File t = new File(getRoot(), FOLDER_INSURANCE);
		try { t.mkdirs(); } catch (Exception ignore) { }
		return t.getAbsolutePath();
	}

	public static String getInsuranceDocsMirrorDir() {
		File t = new File(docsRoot(), "serverUpload" + File.separator
				+ FOLDER_INSURANCE);
		try { t.mkdirs(); } catch (Exception ignore) { }
		return t.getAbsolutePath();
	}

	public static String insuranceSaveBase(int year) {
		return "AutoInsurance_" + year;
	}

	public static String relativeInsurancePath(String fileName) {
		String fn = fileName == null ? "" : fileName.trim();
		return "docs/serverUpload/" + FOLDER_INSURANCE + "/" + fn;
	}

	/** Current-year Auto Insurance file on disk (primary, then docs mirror). */
	public static File findInsuranceFile(int year) {
		String y = String.valueOf(year);
		String[] prefixes = new String[] {
				"autoinsurance_" + y, "insurance_" + y };
		File[] dirs = new File[] {
				new File(getInsuranceDir()),
				new File(getInsuranceDocsMirrorDir()) };
		for (int d = 0; d < dirs.length; d++) {
			File dir = dirs[d];
			File[] list = dir.listFiles();
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
}
