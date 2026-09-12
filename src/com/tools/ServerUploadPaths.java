package com.tools;

import java.io.File;

import com.beans.ApplicationConfig;

/**
 * Azure File Share upload root.
 * Laptop: Z:\serverUpload (mapped \\mvpgstorage.file.core.windows.net)
 * UAT:    E:\serverUpload
 * Legacy: F:\JavProject\serverUpload
 *
 * Override with web.xml init-param serverUploadPath when needed.
 */
public final class ServerUploadPaths {

	private static volatile String cachedRoot = null;

	private ServerUploadPaths() {
	}

	public static synchronized void clearCache() {
		cachedRoot = null;
	}

	/** Absolute root, e.g. Z:\serverUpload — creates folder if possible. */
	public static String getRoot() {
		if (cachedRoot != null && cachedRoot.length() > 0)
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
			candidates = new String[] { configured };
		} else {
			candidates = new String[] {
				"Z:\\serverUpload",
				"E:\\serverUpload",
				"F:\\JavProject\\serverUpload"
			};
		}

		for (int i = 0; i < candidates.length; i++) {
			String c = candidates[i];
			if (c == null || c.trim().length() == 0) continue;
			File root = new File(c.trim());
			try {
				File parent = root.getParentFile();
				/* Prefer an existing drive / share letter */
				if (parent != null && parent.exists() && !root.exists())
					root.mkdirs();
				else if (!root.exists())
					root.mkdirs();
				if (root.isDirectory() && root.exists()) {
					cachedRoot = root.getAbsolutePath();
					return cachedRoot;
				}
			} catch (Exception ignore) {
			}
		}

		/* Last resort: under Tomcat docs */
		String docs = ApplicationConfig.getDocsPath();
		if (docs == null || docs.length() == 0)
			docs = ApplicationConfig.getApplicationPath() + File.separator + "docs";
		File fallback = new File(docs, "serverUpload");
		try { fallback.mkdirs(); } catch (Exception ignore) { }
		cachedRoot = fallback.getAbsolutePath();
		return cachedRoot;
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
