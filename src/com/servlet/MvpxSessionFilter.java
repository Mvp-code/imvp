package com.servlet;

import java.io.IOException;

import javax.servlet.Filter;
import javax.servlet.FilterChain;
import javax.servlet.FilterConfig;
import javax.servlet.ServletException;
import javax.servlet.ServletRequest;
import javax.servlet.ServletResponse;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

/**
 * Blocks unauthenticated raw JSP GETs from rendering the app shell.
 * Servlet forwards (REQUEST dispatcher only) skip this filter, so
 * MVPGServlet-authenticated pages keep working via request attributes.
 * Public: login, DA apply form, marketing home.
 */
public class MvpxSessionFilter implements Filter {

	public void init(FilterConfig filterConfig) throws ServletException {
	}

	public void destroy() {
	}

	public void doFilter(ServletRequest req, ServletResponse res,
			FilterChain chain) throws IOException, ServletException {

		HttpServletRequest request = (HttpServletRequest) req;
		HttpServletResponse response = (HttpServletResponse) res;
		String uri = request.getRequestURI() == null ? ""
				: request.getRequestURI();

		if (isPublicJsp(uri)) {
			chain.doFilter(req, res);
			return;
		}

		if (!isJsp(uri)) {
			chain.doFilter(req, res);
			return;
		}

		HttpSession session = request.getSession(false);
		String user = "";
		if (session != null && session.getAttribute("loginUser") != null) {
			user = session.getAttribute("loginUser").toString().trim();
		}
		if (user.length() == 0) {
			response.sendRedirect(request.getContextPath() + "/jsp/login.jsp");
			return;
		}

		chain.doFilter(req, res);
	}

	private static boolean isJsp(String uri) {
		String u = strip(uri);
		return u.endsWith(".jsp");
	}

	private static boolean isPublicJsp(String uri) {
		String u = strip(uri);
		return u.endsWith("/login.jsp")
				|| u.endsWith("/daapplicationform.jsp")
				|| u.endsWith("/home.jsp");
	}

	private static String strip(String uri) {
		if (uri == null) {
			return "";
		}
		String u = uri.replace('\\', '/').toLowerCase();
		int sc = u.indexOf(';');
		if (sc >= 0) {
			u = u.substring(0, sc);
		}
		int q = u.indexOf('?');
		if (q >= 0) {
			u = u.substring(0, q);
		}
		return u;
	}
}
