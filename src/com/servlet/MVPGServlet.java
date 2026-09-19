package com.servlet;

import java.io.IOException;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.ServletOutputStream;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import com.beans.ApplicationConfig;
import com.beans.ErrorBean;
import com.controller.ControllerParameters;
import com.controller.MVPGCtrl;
import com.dataobjects.LoginDAO;
import com.dataobjects.MVPGDAO;
import com.util.RequestTracker;
import com.util.SubmitType;

public class MVPGServlet extends HttpServlet {

	private static final long serialVersionUID = -4128287776599965906L;

	@Override
	public void init(ServletConfig config) throws ServletException {
		super.init(config);
		ApplicationConfig.update(config);
	}

	@Override
	public void doGet(HttpServletRequest req, HttpServletResponse res)
			throws ServletException, IOException {
		doPost(req, res);
	}

	@Override
	public void doPost(HttpServletRequest req, HttpServletResponse res)
			throws ServletException, IOException {
		processRequest(req, res);
	}

	private void processRequest(HttpServletRequest request,
			HttpServletResponse response) throws ServletException, IOException {

		request.setCharacterEncoding("UTF-8");
		HttpSession session = request.getSession(true);
		String loginUser = request.getParameter("loginUser") == null ? ""
				: request.getParameter("loginUser").trim();
		String loginUserDisplayName = request
				.getParameter("loginUserDisplayName") == null ? ""
						: request.getParameter("loginUserDisplayName").trim();
		String loginUserID = request.getParameter("loginUserID") == null ? ""
				: request.getParameter("loginUserID").trim();
		String loginUserRoles = request.getParameter("loginUserRoles") == null
				? ""
				: request.getParameter("loginUserRoles").trim();
		int submitType = Integer
				.parseInt(request.getParameter("submitType") == null
						? (SubmitType.CREATE + "")
						: request.getParameter("submitType").trim());
		String controller = request.getParameter("controller") == null ? ""
				: request.getParameter("controller").trim();
		String entityID = request.getParameter("entityID") == null ? ""
				: request.getParameter("entityID").trim();
		String X_REQUEST_ID = request.getParameter("X_REQUEST_ID") == null ? ""
				: request.getParameter("X_REQUEST_ID").trim();

		/* Sidebar GET links omit hidden form fields. Keep the logged-in session. */
		if (SubmitType.LOGIN != submitType) {
			if (loginUser.length() == 0)
				loginUser = sessAttr(session, "loginUser");
			if (loginUserID.length() == 0)
				loginUserID = sessAttr(session, "loginUserID");
			if (loginUserRoles.length() == 0)
				loginUserRoles = sessAttr(session, "loginUserRoles");
			if (loginUserDisplayName.length() == 0)
				loginUserDisplayName = sessAttr(session, "loginUserDisplayName");
			if (entityID.length() == 0)
				entityID = sessAttr(session, "entityID");
		}

		if (SubmitType.LOGIN == submitType) {
			if (entityID.length() == 0)
				entityID = "1";
			if (loginUser.length() == 0)
				loginUser = "testUser";

		}

		System.out.println("");
		System.out.println(this.getServletName() + " :: processRequest :: "
				+ submitType + " :: " + controller + " :: " + loginUser + " :: "
				+ loginUserID + " :: " + loginUserRoles + " :: " + entityID
				+ " :: " + X_REQUEST_ID + " :: " + request.getQueryString());

		try {
			if (X_REQUEST_ID.length() > 0) {
				boolean isDuplicate = RequestTracker.isDuplicate(X_REQUEST_ID);
				System.out.println("X_REQUEST_ID :: " + X_REQUEST_ID + " :: "
						+ isDuplicate);
				if (isDuplicate) {
					response.sendError(HttpServletResponse.SC_CONFLICT,
							"Duplicate request");
					return;
				}
			}

			ControllerParameters params = new ControllerParameters();
			params.setEntityID(entityID);
			params.setLoginUserID(loginUserID);
			params.setLoginUser(loginUser);
			params.setLoginUserRoles(loginUserRoles);
			params.setLoginUserDisplayName(loginUserDisplayName);
			params.setController(controller);
			params.setRequest(request);
			params.setResponse(response);

			MVPGCtrl controllerObj = (MVPGCtrl) new MVPGCtrl()
					.createClassObj("com.controller", controller);

			if (loginUser.length() == 0 && SubmitType.LOGIN != submitType) {
				ErrorBean errorType = new LoginDAO().getErrorType(false,
						SubmitType.LOGIN, "Access Denied");
				params.setSubmitType(SubmitType.LOGIN);
				params.getRequest().setAttribute(controllerObj.ATT_ERROR_BEAN,
						errorType);
				params.setForwardTo("/jsp/login.jsp");
				submitType = 0;
			} else {
				new MVPGDAO().createAuditInfo(controller, submitType,
						request.getRemoteAddr(), request.getQueryString(),
						loginUser, entityID);
			}

			switch (submitType) {
			case SubmitType.LOGIN:
				params = controllerObj.login(params);
				break;

			case SubmitType.LOGOUT:
				params = controllerObj.logout(params);
				break;

			case SubmitType.SEARCH:
				params = controllerObj.searchRecords(params);
				break;

			case SubmitType.BROWSE:
				params = controllerObj.fetchRecord(params);
				break;

			case SubmitType.UPLOAD:
				params = controllerObj.uploadRecord(params);
				break;

			case SubmitType.CREATE:
				params = controllerObj.createRecord(params);
				break;

			case SubmitType.CREATE_CONFIRM:
				params = controllerObj.createRecordConfirm(params);
				break;

			case SubmitType.UPDATE:
				params = controllerObj.updateRecord(params);
				break;

			case SubmitType.UPDATE_CONFIRM:
				params = controllerObj.updateRecordConfirm(params);
				break;

			case SubmitType.FINAL:
				params = controllerObj.finalRecord(params);
				break;

			case SubmitType.WITH_HOLD:
				params = controllerObj.withHoldRecord(params);
				break;

			case SubmitType.CHANGE:
				params = controllerObj.changeRecord(params);
				break;

			case SubmitType.DELETE:
				params = controllerObj.deleteRecord(params);
				break;

			case SubmitType.DYNAMIC:
				params = controllerObj.dynamic(params);
				String responseMessage = params.getResponseMessage();
				response.setHeader("Cache-Control", "no-cache");
				if ("json".equalsIgnoreCase(params.getResponseType())) {
					response.setContentType("application/json");
					response.getWriter().println(responseMessage);
				} else {
					response.setContentType("text/xml");
					response.getWriter().write(responseMessage);
				}
				return;

			case SubmitType.PRINT:
				params = controllerObj.printRecord(params);
				ServletOutputStream out = response.getOutputStream();
				if (params.getBaos() != null) {
					response.setContentType("application/pdf");
					response.setContentLength(params.getBaos().size());
					params.getBaos().writeTo(out);
					out.flush();
					out.close();
				} else if (params.getReportFileNameWithPath().length() > 0) {
					String fileName = params.getReportFileNameWithPath()
							.substring(params.getReportFileNameWithPath()
									.lastIndexOf("/") + 1);
					boolean isDownload = true;
					if ("CommonUpload".equalsIgnoreCase(controller))
						isDownload = false;
					controllerObj.openFile(fileName,
							params.getReportFileNameWithPath(), response,
							isDownload);
				} else {
					response.setContentType("text/html");
					out.println("<html>");
					out.println("<body>");
					out.println("<center><h3>No data found</h3></center>");
					out.println("</body>");
					out.println("</html>");
				}
				return;
			}

			request = params.getRequest();
			response = params.getResponse();
			if (SubmitType.LOGOUT == submitType) {
				try {
					session.invalidate();
				} catch (Exception ignore) {
				}
			} else {
				request.setAttribute("entityID", params.getEntityID());
				request.setAttribute("loginUser", params.getLoginUser());
				request.setAttribute("loginUserID", params.getLoginUserID());
				request.setAttribute("loginUserRoles",
						params.getLoginUserRoles());
				request.setAttribute("loginUserDisplayName",
						params.getLoginUserDisplayName());
				String persistUser = params.getLoginUser() == null ? ""
						: params.getLoginUser().trim();
				String forwardTo = params.getForwardTo() == null ? ""
						: params.getForwardTo();
				if (persistUser.length() > 0
						&& forwardTo.toLowerCase().indexOf("login.jsp") < 0) {
					session.setAttribute("entityID", params.getEntityID());
					session.setAttribute("loginUser", persistUser);
					session.setAttribute("loginUserID",
							params.getLoginUserID());
					session.setAttribute("loginUserRoles",
							params.getLoginUserRoles());
					session.setAttribute("loginUserDisplayName",
							params.getLoginUserDisplayName());
				}
			}
			request.setAttribute("submitType", params.getSubmitType());

			System.out.println(this.getServletName() + " :: params :: "
					+ submitType + " :: " + params.isDispatcherRequired()
					+ " :: " + params.getForwardTo() + " :: "
					+ params.getSubmitType());
			if (params.isDispatcherRequired()) {
				String forwardTo = params.getForwardTo();
				javax.servlet.RequestDispatcher dispatcher = getServletContext()
						.getRequestDispatcher(forwardTo);
				if (dispatcher != null) {
					try {
						dispatcher.forward(request, response);
					} catch (Exception ex) {
						ex.printStackTrace();
					}
				}
			}

		} catch (Exception ex) {
			ex.printStackTrace();
		}
	}

	private static String sessAttr(HttpSession session, String key) {
		if (session == null || key == null)
			return "";
		Object v = session.getAttribute(key);
		return v == null ? "" : v.toString().trim();
	}
}
