package com.servlet;

import java.io.IOException;
import java.io.PrintWriter;
import java.util.Enumeration;
import java.util.HashMap;
import java.util.Map;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.tools.EmilyConsoleService;
import com.tools.EmilyService;

/**
 * Emily Phase 0 API - /api/emily/*
 *
 * Tool endpoints (context, rts-check, log-exception, rescue-candidates,
 * escalate, call-complete) are what the Phase 1 voice vendor will call
 * through the Cloudflare tunnel; they REQUIRE the X-EMILY-KEY header to
 * match emily_config.SHARED_KEY.
 *
 * Console endpoints (console-data, console-action, simulate) back the
 * in-app Emily Console page. They are key-exempt like the rest of the
 * LAN-only JSP pages, and they are NOT routed through the tunnel.
 *
 * Phase 0 accepts request PARAMS (form/query); Vapi-style JSON bodies get a
 * proper parser when a JSON lib lands with Phase 1.
 */
public class EmilyApiServlet extends HttpServlet {

	private static final long serialVersionUID = 20260716L;

	private final EmilyService svc = new EmilyService();
	private final EmilyConsoleService console = new EmilyConsoleService();

	@Override
	public void doGet(HttpServletRequest req, HttpServletResponse res)
			throws ServletException, IOException {
		doPost(req, res);
	}

	@Override
	public void doPost(HttpServletRequest req, HttpServletResponse res)
			throws ServletException, IOException {
		req.setCharacterEncoding("UTF-8");
		res.setContentType("application/json;charset=UTF-8");
		PrintWriter out = res.getWriter();

		String path = req.getPathInfo() == null ? "" : req.getPathInfo();
		boolean isConsole = path.equals("/console-data")
				|| path.equals("/console-action") || path.equals("/simulate");

		try {
			if (!isConsole) {
				String key = req.getHeader("X-EMILY-KEY");
				if (key == null)
					key = p(req, "emilyKey"); // simulator convenience
				String expected = svc.cfg("SHARED_KEY");
				if (expected.length() == 0 || !expected.equals(key)) {
					res.setStatus(401);
					out.print("{\"error\":\"unauthorized\"}");
					return;
				}
			}

			String user = p(req, "user");
			if (user.length() == 0)
				user = "console";

			if (path.equals("/context")) {
				out.print(svc.context(p(req, "phone")));

			} else if (path.equals("/rts-check")) {
				out.print(svc.rtsCheck(Integer.parseInt(p(req, "employeeId")),
						intOrNull(p(req, "ovAgeMin")), intOrNull(p(req, "ovStopsDone"))));

			} else if (path.equals("/log-exception")) {
				out.print(svc.logException(Integer.parseInt(p(req, "employeeId")),
						p(req, "category"), Integer.parseInt(def(p(req, "count"), "1")),
						def(p(req, "inVan"), "N"), p(req, "attempts"), p(req, "note"),
						Integer.parseInt(def(p(req, "callId"), "0")), user));

			} else if (path.equals("/rescue-candidates")) {
				out.print(svc.rescueCandidates(Integer.parseInt(p(req, "employeeId"))));

			} else if (path.equals("/escalate")) {
				out.print(svc.escalate(Integer.parseInt(def(p(req, "callId"), "0")),
						p(req, "priority"), p(req, "reason")));

			} else if (path.equals("/call-complete")) {
				int callId = Integer.parseInt(def(p(req, "callId"), "0"));
				if (callId == 0)
					callId = svc.openCall(p(req, "vapiCallId"),
							intOrNull(p(req, "employeeId")), p(req, "phone"), 0, user);
				out.print(svc.completeCall(callId, p(req, "intent"),
						p(req, "outcome"), p(req, "confidence"),
						Integer.parseInt(def(p(req, "durationSec"), "0")),
						p(req, "transcript"), p(req, "recordingUrl")));

			} else if (path.equals("/console-data")) {
				out.print(console.consoleData());

			} else if (path.equals("/console-action")) {
				Map<String, String> params = new HashMap<String, String>();
				Enumeration<String> en = req.getParameterNames();
				while (en.hasMoreElements()) {
					String nm = en.nextElement();
					params.put(nm, p(req, nm));
				}
				out.print(console.consoleAction(p(req, "action"), params, user));

			} else if (path.equals("/simulate")) {
				out.print(console.simulate(p(req, "phone"), p(req, "utterance"),
						p(req, "ovAgeMin"), p(req, "ovStopsDone"), user));

			} else {
				res.setStatus(404);
				out.print("{\"error\":\"unknown endpoint\"}");
			}
		} catch (Exception ex) {
			ex.printStackTrace();
			res.setStatus(500);
			out.print("{\"error\":" + EmilyService.js(
					ex.getClass().getSimpleName() + ": " + ex.getMessage()) + "}");
		}
	}

	private static String p(HttpServletRequest req, String name) {
		String v = req.getParameter(name);
		return v == null ? "" : v.trim();
	}

	private static String def(String v, String d) {
		return v == null || v.length() == 0 ? d : v;
	}

	private static Integer intOrNull(String v) {
		try {
			return v == null || v.length() == 0 ? null : Integer.valueOf(v.trim());
		} catch (Exception e) {
			return null;
		}
	}
}
