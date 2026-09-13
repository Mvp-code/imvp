package com.tools;

import java.io.File;

import com.beans.ApplicationConfig;

/**
 * Upload root:
 *   UAT:    F:\JavProject\serverUpload (when that drive is writable)
 *   Laptop: webapp docs/ folder
 *
 * Optional override: web.xml init-param serverUploadPath.
 */
public final class ServerUploadPaths {

	public static final String UAT_ROOT = "F:\\JavProject\\serverUpload";

	private static volatile String cachedRoot = null;

	private ServerUploadPaths() {
	}

	public static synchronized void clearCache() {
		cachedRoot = null;
	}

	/** Absolute root — UAT F: drive, else docs on laptop. */
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
			candidates = new String[] { configured, UAT_ROOT };
		} else {
			candidates = new String[] { UAT_ROOT };
		}

		for (int i = 0; i < candidates.length; i++) {
			String c = candidates[i];
			if (c == null || c.trim().length() == 0) continue;
			File root = new File(c.trim());
			try {
				File parent = root.getParentFile();
				if (parent != null && !parent.exists())
					continue; /* drive letter missing (laptop has no F:) */
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

		/* Laptop / no F: — use webapp docs */
		File fallback = new File(docsRoot());
		try { fallback.mkdirs(); } catch (Exception ignore) { }
		cachedRoot = fallback.getAbsolutePath();
		System.out.println("ServerUploadPaths root (docs/laptop)=" + cachedRoot);
		return cachedRoot;
	}

	/** True when writing under F:\JavProject\serverUpload (UAT). */
	public static boolean isUatServerUpload() {
		String r = getRoot().replace('/', '\\').toLowerCase();
		return r.indexOf("\\javproject\\serverupload") >= 0;
	}

	private static String docsRoot() {
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

	public static String getRegistrationForms() {
		File t = new File(getRoot(), "RegistrationForms");
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
}
