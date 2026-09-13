package com.tools;

import java.io.File;

import com.beans.ApplicationConfig;

/**
 * Azure File Share upload root.
 * Prefer UNC (works for Windows services that cannot see mapped letters):
 *   \\mvpgstorage.file.core.windows.net\mvpgfilestorage\serverUpload
 * Laptop mapped drive: Z:\serverUpload
 * UAT mapped drive:    E:\serverUpload
 * Legacy:              F:\JavProject\serverUpload
 *
 * Override with web.xml init-param serverUploadPath when needed.
 *
 * Note: Tomcat as LocalService cannot see interactive mapped drives (Z:).
 * Use UNC in web.xml, or run Tomcat under the Windows user that has share access.
 */
public final class ServerUploadPaths {

	public static final String AZURE_UNC_ROOT =
			"\\\\mvpgstorage.file.core.windows.net\\mvpgfilestorage\\serverUpload";

	private static volatile String cachedRoot = null;

	private ServerUploadPaths() {
	}

	public static synchronized void clearCache() {
		cachedRoot = null;
	}

	/** Absolute root — creates folder if possible. */
	public static String getRoot() {
		String current = cachedRoot;
		if (current != null && current.length() > 0
				&& !isDocsFallback(current)
				&& canUseDirectory(new File(current)))
			return current;

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
			candidates = new String[] {
				configured,
				AZURE_UNC_ROOT,
				"Z:\\serverUpload",
				"E:\\serverUpload",
				"F:\\JavProject\\serverUpload"
			};
		} else {
			candidates = new String[] {
				AZURE_UNC_ROOT,
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

		/* Last resort: under Tomcat docs — do not permanently prefer this */
		String docs = ApplicationConfig.getDocsPath();
		if (docs == null || docs.length() == 0)
			docs = ApplicationConfig.getApplicationPath() + File.separator + "docs";
		File fallback = new File(docs, "serverUpload");
		try { fallback.mkdirs(); } catch (Exception ignore) { }
		System.out.println("ServerUploadPaths FALLBACK root="
				+ fallback.getAbsolutePath()
				+ " (Tomcat cannot reach Azure share — use UNC or run Tomcat as your user)");
		cachedRoot = null; /* allow retry next call */
		return fallback.getAbsolutePath();
	}

	private static boolean isDocsFallback(String path) {
		if (path == null) return false;
		String p = path.replace('/', '\\').toLowerCase();
		return p.indexOf("\\docs\\serverupload") >= 0
				|| p.endsWith("\\docs\\serverupload");
	}

	private static boolean canUseDirectory(File root) {
		try {
			return root != null && root.exists() && root.isDirectory();
		} catch (Exception e) {
			return false;
		}
	}

	/** Confirm the JVM identity can actually create files on the share. */
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
