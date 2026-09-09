package com.beans;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;

public class ApplicationConfig {

	private static String applicationPath = "";
	private static String docsPath = "";
	private static String imagesPath = "";
	private static String logsPath = "";
	private static String externalDocsPath = "";

	public static String getApplicationPath() {
		return applicationPath;
	}

	public static String getExternalDocsPath() {
		return externalDocsPath;
	}

	public static String getDocsPath() {
		return docsPath;
	}

	public static String getImagesPath() {
		return imagesPath;
	}

	public static String getLogsPath() {
		return logsPath;
	}

	public static void update(ServletConfig config) throws ServletException {
		applicationPath = config.getInitParameter("applicationPath") == null
				? ""
				: config.getInitParameter("applicationPath");

		docsPath = config.getInitParameter("docsPath") == null ? ""
				: config.getInitParameter("docsPath");

		imagesPath = config.getInitParameter("imagesPath") == null ? ""
				: config.getInitParameter("imagesPath");

		logsPath = config.getInitParameter("logsPath") == null ? ""
				: config.getInitParameter("logsPath");

		externalDocsPath = config.getInitParameter("externalDocsPath") == null
				? ""
				: config.getInitParameter("externalDocsPath");

	}
}
