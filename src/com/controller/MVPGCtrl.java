package com.controller;

import java.io.File;
import java.util.ArrayList;
import java.util.Enumeration;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.apache.commons.beanutils.PropertyUtils;

import com.beans.Address;
import com.beans.CommonUpload;
import com.beans.Contact;
import com.beans.EmployeeForms;
import com.beans.ErrorBean;
import com.beans.MainBean;
import com.beans.SearchBean;
import com.dataobjects.EmployeeDashboardDAO;
import com.dataobjects.EmployeeFormsDAO;
import com.dataobjects.MVPGDAO;
import com.itextpdf.text.Document;
import com.itextpdf.text.Image;
import com.itextpdf.text.PageSize;
import com.tools.ExcelFile;
import com.tools.FileUpload;
import com.tools.MainPdfReport;
import com.util.SubmitType;

public class MVPGCtrl extends MainCtrl {

	public Object createClassObj(String packageName, String className)
			throws Exception {

		if (packageName.contains(".controller"))
			className += "Ctrl";
		else if (packageName.contains(".dataobjects"))
			className += "DAO";

		String dynClassName = packageName + "." + className;
		// System.out.println("createClassObj :: " + dynClassName);
		try {
			return Class.forName(dynClassName).newInstance();
		} catch (Exception ex) {
			if (dynClassName.endsWith("Ctrl"))
				return new MVPGCtrl();
			else if (dynClassName.endsWith("DAO"))
				return new MVPGDAO();
		}

		return null;
	}

	public ControllerParameters login(ControllerParameters params)
			throws Exception {

		System.out.println("login :: " + params.getController());
		MainBean _bean = (MainBean) createClassObj("com.beans",
				params.getController());
		_bean = (MainBean) setValuesToBean(params.getRequest(), _bean);

		MVPGDAO _DAO = (MVPGDAO) createClassObj("com.dataobjects",
				params.getController());

		Object returnObj[] = _DAO.login(_bean,
				params.getRequest().getRemoteAddr(),
				params.getRequest().getRequestedSessionId(),
				params.getLoginUser(), params.getLoginUserRoles(),
				params.getLoginUserID(), params.getEntityID());
		if (returnObj.length == 0) {
			ErrorBean errorType = _DAO.getErrorType(false, SubmitType.LOGIN,
					"");
			params.setSubmitType(SubmitType.LOGIN);
			params.getRequest().setAttribute(ATT_ERROR_BEAN, errorType);
			params.setForwardTo("/jsp/login.jsp");
			return params;

		} else {
			params.setEntityID(returnObj[0].toString());
			params.setLoginUserID(returnObj[1].toString());
			params.setLoginUser(returnObj[2].toString());
			params.setLoginUserRoles(returnObj[4].toString());
			if (returnObj.length > 5)
				params.setLoginUserDisplayName(returnObj[5].toString());
			if ("4".equalsIgnoreCase(params.getLoginUserRoles())) {
				params.setController("CommonUpload");
				return uploadRecord(params);
			} else {
				params.setController("DACheckin");
				return searchRecords(params);
			}

		}
	}

	public ControllerParameters logout(ControllerParameters params)
			throws Exception {

		System.out.println("logout :: " + params.getController());
		MainBean _bean = (MainBean) createClassObj("com.beans",
				params.getController());
		_bean = (MainBean) setValuesToBean(params.getRequest(), _bean);

		MVPGDAO _DAO = (MVPGDAO) createClassObj("com.dataobjects",
				params.getController());

		Object returnObj[] = _DAO.logout(_bean,
				params.getRequest().getRemoteAddr(),
				params.getRequest().getRequestedSessionId(),
				params.getLoginUser(), params.getLoginUserRoles(),
				params.getLoginUserID(), params.getEntityID());

		ErrorBean errorType = _DAO.getErrorType(true, SubmitType.LOGOUT, "");
		params.setSubmitType(SubmitType.LOGIN);
		params.getRequest().setAttribute(ATT_ERROR_BEAN, errorType);
		params.setForwardTo("/jsp/login.jsp");
		return params;
	}

	public ControllerParameters searchRecords(ControllerParameters params)
			throws Exception {

		System.out.println("searchRecords :: " + params.getController());
		SearchBean searchBean = (SearchBean) setValuesToSearchBean(
				params.getRequest(), new SearchBean());

		searchBean = (SearchBean) setTransListData(searchBean, params);

		searchBean.setRequestMap(getRequestParameterValuesMap(params));

		MVPGDAO _DAO = (MVPGDAO) createClassObj("com.dataobjects",
				params.getController());

		searchBean = _DAO.searchRecords(searchBean, params.getRecordID(),
				params.getLoginUser(), params.getLoginUserRoles(),
				params.getLoginUserID(), params.getEntityID());

		searchBean = _DAO.getSearchCounts(searchBean, params.getEntityID());

		params.getRequest().setAttribute(ATT_SEARCH_BEAN, searchBean);
		params.setSubmitType(SubmitType.SEARCH);
		if ("EmployeeDashboard".equalsIgnoreCase(params.getController())
				|| "StationDashboard".equalsIgnoreCase(params.getController())
				|| "ReturnsBoard".equalsIgnoreCase(params.getController())
				|| "WaveSheet".equalsIgnoreCase(params.getController())
				|| "DAStatus".equalsIgnoreCase(params.getController())
				|| "SmartUpload".equalsIgnoreCase(params.getController())
				|| "UploadHistory".equalsIgnoreCase(params.getController()))
			params.setForwardTo("/jsp/" + params.getController() + ".jsp");
		else if (("DACheckin".equalsIgnoreCase(params.getController())
				|| "AdminEmployee".equalsIgnoreCase(params.getController()))
				&& !(SubmitType.UPDATE + "").equals(searchBean.getSelectedType()))
			// Redesigned list pages. Their bulk-edit / vehicle-swap screens
			// (selectedType=UPDATE) still render through legacy searchList.jsp.
			params.setForwardTo("/jsp/" + params.getController() + ".jsp");
		else if ("DACheckout".equalsIgnoreCase(params.getController())
				|| "EmployeeTermination".equalsIgnoreCase(params.getController())
				|| "EmployeeIncident".equalsIgnoreCase(params.getController())
				|| "Incident".equalsIgnoreCase(params.getController())
				|| "DATask".equalsIgnoreCase(params.getController())
				|| "AdminVehicle".equalsIgnoreCase(params.getController())
				|| "AdminPhones".equalsIgnoreCase(params.getController()))
			// Redesigned list pages (no legacy sub-screens).
			params.setForwardTo("/jsp/" + params.getController() + ".jsp");
		else if ("EmployeeSchedule".equalsIgnoreCase(params.getController())
				&& searchBean.getSelectedType().length() == 0)
			// Redesigned read view; the editable grid and its save flows
			// (any selectedType) stay on legacy searchList.jsp.
			params.setForwardTo("/jsp/EmployeeSchedule.jsp");
		else
			params.setForwardTo("/jsp/searchList.jsp");

		return params;
	}

	public ControllerParameters fetchRecord(ControllerParameters params)
			throws Exception {

		return fetchRecord(params, SubmitType.BROWSE);
	}

	private ControllerParameters fetchRecord(ControllerParameters params,
			int submitType) throws Exception {

		System.out.println("fetchRecord :: " + params.getController());
		MVPGDAO _DAO = (MVPGDAO) createClassObj("com.dataobjects",
				params.getController());

		String recordID = params.getRequest().getAttribute("recordID") == null
				? ""
				: params.getRequest().getAttribute("recordID").toString()
						.trim();
		if (recordID.length() == 0)
			recordID = getRequestVal(params.getRequest(), "recordID")
					.toString();

		String requestType = getRequestVal(params.getRequest(), "requestType")
				.toString();
		if ("change".equalsIgnoreCase(requestType)
				&& "EntityUsers".equalsIgnoreCase(params.getController())) {
			recordID = "";
		}

		MainBean _bean = (MainBean) _DAO.fetchRecord(recordID,
				params.getLoginUser(), params.getLoginUserRoles(),
				params.getLoginUserID(), params.getEntityID(), submitType);

		String deleteUploadID = getRequestVal(params.getRequest(),
				"deleteUploadID").toString();
		if (deleteUploadID.length() > 0) {
			boolean result = _DAO.delteUploadRecord(deleteUploadID,
					params.getLoginUser());
			ErrorBean _errorBean = _DAO.getErrorType(result, SubmitType.DELETE,
					_bean.getDisplayName());
			params.getRequest().setAttribute(ATT_ERROR_BEAN, _errorBean);
		}

		if (submitType == SubmitType.BROWSE) {
			_bean.setUploadsList(_DAO.getUploadsList(params.getController(),
					_bean.getRecordID(), params.getEntityID()));
		}

		if ("EmployeeDashboard".equalsIgnoreCase(params.getController())) {
			SearchBean searchBean = new SearchBean();
			searchBean.setController(_bean.getController());
			searchBean.setDisplayName(_bean.getDisplayName());

			params.setSubmitType(SubmitType.SEARCH);
			params.getRequest().setAttribute(ATT_RECORD_BEAN, searchBean);
			params.setForwardTo("/jsp/" + params.getController() + ".jsp");
		} else {
			if (submitType == SubmitType.UPLOAD) {
				String isPopup = getRequestVal(params.getRequest(), "isPopup")
						.toString();
				params.getRequest().setAttribute("isPopup", isPopup);
				if ("CommonUpload"
						.equalsIgnoreCase(_bean.getClass().getSimpleName())) {
					_bean = (MainBean) setValuesToBean(params.getRequest(),
							_bean);

					CommonUpload _commonUpload = (CommonUpload) _bean;
					_commonUpload = _DAO.fetchUploadDetails(_commonUpload,
							params.getLoginUserID(), params.getLoginUserRoles(),
							params.getLoginUser(), params.getEntityID());
					_bean = _commonUpload;

				}
			}
			params.setSubmitType(submitType);
			params.getRequest().setAttribute(ATT_RECORD_BEAN, _bean);
			params.setForwardTo("/jsp/" + params.getController() + ".jsp");
		}

		return params;
	}

	public ControllerParameters createRecord(ControllerParameters params)
			throws Exception {

		System.out.println("createRecord :: " + params.getController());
		params = fetchRecord(params, SubmitType.CREATE);
		return params;
	}

	public ControllerParameters uploadRecord(ControllerParameters params)
			throws Exception {

		System.out.println("uploadRecord :: " + params.getController());
		params = fetchRecord(params, SubmitType.UPLOAD);
		return params;
	}

	public ControllerParameters createRecordConfirm(ControllerParameters params)
			throws Exception {

		System.out.println("createRecordConfirm :: " + params.getController());
		MainBean _bean = (MainBean) createClassObj("com.beans",
				params.getController());
		_bean = (MainBean) setValuesToBean(params.getRequest(), _bean);
		_bean = setTransListData(_bean, params);

		MVPGDAO _DAO = (MVPGDAO) createClassObj("com.dataobjects",
				params.getController());

		Object returnObj[] = _DAO.createRecord(_bean, params.getLoginUser(),
				params.getLoginUserRoles(), params.getLoginUserID(),
				params.getEntityID());
		String recordID = returnObj[0].toString().trim();
		ErrorBean _errorBean = (ErrorBean) returnObj[1];
		params.getRequest().setAttribute(ATT_ERROR_BEAN, _errorBean);

		if (ErrorBean.enumTypes.success.toString()
				.equalsIgnoreCase(_errorBean.getType())
				|| ErrorBean.enumTypes.notice.toString()
						.equalsIgnoreCase(_errorBean.getType())) {
			if (recordID.length() > 0) {
				params.getRequest().setAttribute("recordID", recordID);
				return fetchRecord(params);

			} else {
				String isPopup = getRequestVal(params.getRequest(), "isPopup")
						.toString();
				params.getRequest().setAttribute("isPopup", isPopup);
				if ("CommonUpload".equalsIgnoreCase(params.getController())
						&& "4".equalsIgnoreCase(params.getLoginUserRoles())) {

					CommonUpload _commonUpload = new CommonUpload();
					_commonUpload = _DAO.fetchUploadDetails(_commonUpload,
							params.getLoginUserID(), params.getLoginUserRoles(),
							params.getLoginUser(), params.getEntityID());
					_bean = _commonUpload;
					params.setSubmitType(SubmitType.UPLOAD);
					params.getRequest().setAttribute(ATT_RECORD_BEAN, _bean);
					params.setForwardTo(
							"/jsp/" + params.getController() + ".jsp");
					return params;
				} else {
					return searchRecords(params);
				}
			}

		} else {
			if ("CommonUpload"
					.equalsIgnoreCase(_bean.getClass().getSimpleName())
					|| "GenericUpload".equalsIgnoreCase(
							_bean.getClass().getSimpleName())) {
				params.setSubmitType(SubmitType.UPLOAD);

			} else {
				params.setSubmitType(SubmitType.CREATE);
			}
			params.getRequest().setAttribute(ATT_RECORD_BEAN, _bean);
			params.setForwardTo("/jsp/" + params.getController() + ".jsp");
			return params;
		}
	}

	private MainBean setTransListData(MainBean _bean,
			ControllerParameters params) throws Exception {

		List transList = new ArrayList();
		if (_bean.getNumOfRows().length() > 0) {
			int numOfRows = Integer.parseInt(_bean.getNumOfRows());
			String dynamicParams = getRequestVal(params.getRequest(),
					"dynamicParams").toString();
			System.out.println(
					"numOfRows :: " + numOfRows + " :: " + dynamicParams);
			if (dynamicParams.length() > 0) {
				String paramArray[] = dynamicParams.split(",");
				for (int i = 0; i < numOfRows; i++) {
					List<String> tempList = new ArrayList<String>();
					for (int j = 0; j < paramArray.length; j++) {
						String paramVal = getRequestVal(params.getRequest(),
								paramArray[j] + i).toString();
						if (j == 0) {
							if (paramVal.length() > 0)
								tempList.add(paramVal);
						} else {
							if (tempList.size() > 0)
								tempList.add(paramVal);
						}
					}

					if (tempList.size() > 0)
						transList.add(tempList);
				}
			}
		}

		// Common Uploads
		if (transList.size() == 0) {
			String dynamicParams = getRequestVal(params.getRequest(),
					"dynamicParams").toString();
			System.out.println("dynamicParams :: " + dynamicParams);
			if (dynamicParams.length() > 0) {
				String splitArray[] = dynamicParams.split(",");
				for (int i = 0; i < splitArray.length; i++) {
					String paramName = splitArray[i];
					if (paramName.length() > 0) {
						String paramVal = getRequestVal(params.getRequest(),
								paramName).toString();

						if (paramVal.length() > 0) {
							List<String> tempList = new ArrayList<String>();
							tempList.add(paramVal);
							tempList.add(paramName);
							transList.add(tempList);
						}
					}
				}
			}
		}
		_bean.setTransList(transList);

		Map transMap = new HashMap();
		String dynamicParamsMap = getRequestVal(params.getRequest(),
				"dynamicParamsMap").toString();
		System.out.println("dynamicParamsMap :: " + dynamicParamsMap);
		if (dynamicParamsMap.length() > 0) {
			String splitArray[] = dynamicParamsMap.split(",");
			for (int i = 0; i < splitArray.length; i++) {
				String paramName = splitArray[i];
				if (paramName.length() > 0) {
					String paramVal = getRequestVal(params.getRequest(),
							paramName).toString();
					transMap.put(paramName, paramVal);
				}
			}
		}
		_bean.setTransMap(transMap);

		if ("AdminEmployee"
				.equalsIgnoreCase(_bean.getClass().getSimpleName())) {
			PropertyUtils.setProperty(_bean, "addressBean",
					(Address) setValuesToBean(params.getRequest(),
							new Address()));

			PropertyUtils.setProperty(_bean, "contactBean",
					(Contact) setValuesToBean(params.getRequest(),
							new Contact()));
		}

		if (_bean.getUploadFileName().length() > 0) {
			Object uploadArray[] = new FileUpload().uploadFile(
					params.getRequest(), params.getLoginUser(),
					params.getController());
			boolean isUploaded = (Boolean) uploadArray[0];
			if (isUploaded) {
				String fileNameWithPath = uploadArray[1].toString() + "/"
						+ _bean.getUploadFileName();
				_bean.setUploadFileNameWithPath(fileNameWithPath);
			}
		} else if ("CommonUpload"
				.equalsIgnoreCase(_bean.getClass().getSimpleName())) {
			Object uploadArray[] = new FileUpload().uploadFile(
					params.getRequest(), params.getLoginUser(),
					params.getController());
			boolean isUploaded = (Boolean) uploadArray[0];
			if (isUploaded) {
				String fileNameWithPath = uploadArray[1].toString();
				_bean.setUploadFileNameWithPath(fileNameWithPath);
				System.out.println("fileNameWithPath :: " + fileNameWithPath);
			}
		}

		return _bean;
	}

	public ControllerParameters updateRecord(ControllerParameters params)
			throws Exception {

		System.out.println("updateRecord :: " + params.getController());
		params = fetchRecord(params, SubmitType.UPDATE);
		return params;
	}

	public ControllerParameters updateRecordConfirm(ControllerParameters params)
			throws Exception {

		System.out.println("updateRecordConfirm :: " + params.getController());
		MainBean _bean = (MainBean) createClassObj("com.beans",
				params.getController());
		_bean = (MainBean) setValuesToBean(params.getRequest(), _bean);
		_bean = setTransListData(_bean, params);

		MVPGDAO _DAO = (MVPGDAO) createClassObj("com.dataobjects",
				params.getController());

		Object returnObj[] = _DAO.updateRecord(_bean, params.getLoginUser(),
				params.getLoginUserRoles(), params.getLoginUserID(),
				params.getEntityID());
		String recordID = returnObj[0].toString().trim();
		ErrorBean _errorBean = (ErrorBean) returnObj[1];

		params.getRequest().setAttribute(ATT_ERROR_BEAN, _errorBean);
		params.getRequest().setAttribute("recordID", recordID);
		return fetchRecord(params);
	}

	public ControllerParameters deleteRecord(ControllerParameters params)
			throws Exception {

		System.out.println("deleteRecord :: " + params.getController());
		MainBean _bean = (MainBean) createClassObj("com.beans",
				params.getController());
		_bean = (MainBean) setValuesToBean(params.getRequest(), _bean);

		MVPGDAO _DAO = (MVPGDAO) createClassObj("com.dataobjects",
				params.getController());

		Object returnObj[] = _DAO.deleteRecord(_bean, params.getLoginUser(),
				params.getLoginUserRoles(), params.getLoginUserID(),
				params.getEntityID());
		ErrorBean _errorBean = (ErrorBean) returnObj[1];
		params.getRequest().setAttribute(ATT_ERROR_BEAN, _errorBean);
		return searchRecords(params);
	}

	public ControllerParameters finalRecord(ControllerParameters params)
			throws Exception {

		System.out.println("finalRecord :: " + params.getController());
		MainBean _bean = (MainBean) createClassObj("com.beans",
				params.getController());
		_bean = (MainBean) setValuesToBean(params.getRequest(), _bean);

		MVPGDAO _DAO = (MVPGDAO) createClassObj("com.dataobjects",
				params.getController());

		Object returnObj[] = _DAO.finalRecord(_bean, params.getLoginUser(),
				params.getLoginUserRoles(), params.getLoginUserID(),
				params.getEntityID());
		String recordID = returnObj[0].toString().trim();
		ErrorBean _errorBean = (ErrorBean) returnObj[1];

		params.getRequest().setAttribute(ATT_ERROR_BEAN, _errorBean);
		params.getRequest().setAttribute("recordID", recordID);
		return fetchRecord(params);
	}

	public ControllerParameters withHoldRecord(ControllerParameters params)
			throws Exception {

		System.out.println("withHoldRecord :: " + params.getController());
		MainBean _bean = (MainBean) createClassObj("com.beans",
				params.getController());
		_bean = (MainBean) setValuesToBean(params.getRequest(), _bean);

		MVPGDAO _DAO = (MVPGDAO) createClassObj("com.dataobjects",
				params.getController());

		Object returnObj[] = _DAO.withHoldRecord(_bean, params.getLoginUser(),
				params.getLoginUserRoles(), params.getLoginUserID(),
				params.getEntityID());
		ErrorBean _errorBean = (ErrorBean) returnObj[1];
		params.getRequest().setAttribute(ATT_ERROR_BEAN, _errorBean);
		return searchRecords(params);
	}

	public ControllerParameters changeRecord(ControllerParameters params)
			throws Exception {

		System.out.println("changeRecord :: " + params.getController());
		MainBean _bean = (MainBean) createClassObj("com.beans",
				params.getController());
		_bean = (MainBean) setValuesToBean(params.getRequest(), _bean);

		MVPGDAO _DAO = (MVPGDAO) createClassObj("com.dataobjects",
				params.getController());

		String requestType = getRequestVal(params.getRequest(), "requestType")
				.toString();
		if ("change".equalsIgnoreCase(requestType)) {
			Object returnObj[] = _DAO.changeRecord(_bean, params.getLoginUser(),
					params.getLoginUserRoles(), params.getLoginUserID(),
					params.getEntityID());
			ErrorBean _errorBean = (ErrorBean) returnObj[1];
			params.getRequest().setAttribute(ATT_ERROR_BEAN, _errorBean);
			return fetchRecord(params, SubmitType.CHANGE);
		} else {
			return fetchRecord(params, SubmitType.CHANGE);
		}
	}

	public ControllerParameters dynamic(ControllerParameters params)
			throws Exception {

		System.out.println("dynamic :: " + params.getController());
		String xmlMesg = "";
		MVPGDAO _DAO = (MVPGDAO) createClassObj("com.dataobjects",
				params.getController());
		String requestType = getRequestVal(params.getRequest(), "requestType")
				.toString();
		if ("suggestor".equalsIgnoreCase(requestType)) {
			String suggestorType = getRequestVal(params.getRequest(),
					"suggestorType").toString();
			String suggestorValue = getRequestVal(params.getRequest(),
					"suggestorValue").toString();
			xmlMesg = _DAO.getSuggestorTypeData(suggestorType, suggestorValue,
					params.getEntityID());

		} else if (requestType.length() > 0) {
			Map<String, String> requestMap = getRequestMap(params);
			xmlMesg = _DAO.getAjaxRequestTypeResp(requestType, requestMap,
					params.getLoginUser(), params.getLoginUserRoles(),
					params.getLoginUserID(), params.getEntityID());
		}

		System.out.println(
				"dynamic.requestType :: " + requestType + " :: " + xmlMesg);
		params.setResponseMessage(xmlMesg);
		return params;
	}

	private Map<String, String> getRequestMap(ControllerParameters params) {

		Map<String, String> requestMap = new HashMap<String, String>();
		Enumeration enumeration = params.getRequest().getParameterNames();
		while (enumeration.hasMoreElements()) {
			String fieldName = (String) enumeration.nextElement();
			if (fieldName == null || fieldName.trim().length() == 0)
				continue;
			if (params.getRequest().getParameterValues(fieldName) != null) {
				String data = "";
				String[] paraValArr = params.getRequest()
						.getParameterValues(fieldName);
				if (paraValArr != null) {
					for (int k = 0; k < paraValArr.length; k++) {
						if (paraValArr[k].trim().length() > 0) {
							if (data.length() == 0) {
								data = paraValArr[k].trim();
							} else {
								data += "@@" + paraValArr[k].trim();
							}
						}
					}
				}
				if (data.length() > 0) {
					if (requestMap.get(fieldName) != null) {
						requestMap.remove(fieldName);
					}
					requestMap.put(fieldName, data.replaceAll("'", "''"));
				}
			}
		}
		System.out.println(
				"requestMap :: " + requestMap.size() + " :: " + requestMap);
		return requestMap;
	}

	@Override
	public ControllerParameters printRecord(ControllerParameters params)
			throws Exception {

		String requestType = getRequestVal(params.getRequest(), "requestType")
				.toString();
		System.out.println("printRecords :: " + requestType + " :: "
				+ params.getController());
		if (requestType.length() > 0) {
			SearchBean searchBean = (SearchBean) setValuesToSearchBean(
					params.getRequest(), new SearchBean());

			searchBean = (SearchBean) setTransListData(searchBean, params);
			Map<String, String> _requestMap = getRequestParameterValuesMap(
					params);
			searchBean.setRequestMap(_requestMap);

			MVPGDAO _DAO = (MVPGDAO) createClassObj("com.dataobjects",
					params.getController());

			if ("EmployeeDashboard".equalsIgnoreCase(params.getController())) {
				String srhYear = getRequestVal(params.getRequest(), "srhYear")
						.toString();
				String srhWeek = getRequestVal(params.getRequest(), "srhWeek")
						.toString();
				String srhTransporterID = getRequestVal(params.getRequest(),
						"srhTransporterID").toString();
				String dashboardOverviewID = getRequestVal(params.getRequest(),
						"dashboardOverviewID").toString();

				EmployeeDashboardDAO _daoObj = (EmployeeDashboardDAO) _DAO;
				Object returnObArray[] = _daoObj.getEmployeeData(srhYear,
						srhWeek, srhTransporterID, dashboardOverviewID,
						params.getEntityID());

				params.setBaos(new MainPdfReport().generateDashboardReport(
						params, _requestMap, returnObArray));

			} else {
				Map transMap = searchBean.getTransMap();
				String printType = getRequestVal(params.getRequest(),
						"printType").toString();
				transMap.put("printType", printType);
				searchBean.setTransMap(transMap);

				searchBean = _DAO.searchRecords(searchBean,
						params.getRecordID(), params.getLoginUser(),
						params.getLoginUserRoles(), params.getLoginUserID(),
						params.getEntityID());
				System.out.println("printType :: " + printType + " :: "
						+ _DAO.getClass().getSimpleName() + " :: "
						+ searchBean.getDataList().size());

				if (searchBean.getDataList().size() > 0) {
					if ("xls".equalsIgnoreCase(printType)) {
						ExcelFile excelFile = new ExcelFile();
						String folderPath = "C:/project1/temp";
						File fileDir = new File(folderPath);

						if (!fileDir.exists())
							fileDir.mkdirs();

						String reportFileNameWithPath = excelFile
								.writeDataToXls(searchBean,
										folderPath + "/"
												+ searchBean.getDisplayName()
												+ ".xlsx");
						params.setReportFileNameWithPath(
								reportFileNameWithPath);
					} else {
						params.setBaos(new MainPdfReport().generateReport(
								params, searchBean, printType, false));
					}
				}
			}

		} else {
			Map<String, String> _requestMap = getRequestParameterValuesMap(
					params);
			MVPGDAO _DAO = (MVPGDAO) createClassObj("com.dataobjects",
					params.getController());

			if ("CommonUpload".equalsIgnoreCase(params.getController())) {
				String recordID = getRequestVal(params.getRequest(), "recordID")
						.toString();
				if (recordID.contains(",")) {
					MainPdfReport pdfReport = new MainPdfReport();
					Document document = pdfReport.getDocument("View", true,
							params.getEntityID());

					String splitArray[] = recordID.split(",");
					for (int i = 0; i < splitArray.length; i++) {
						String filePath = _DAO.fetchBlobRecord(splitArray[i],
								params.getLoginUser(), params.getEntityID());
						if (filePath.length() > 0) {
							Image img = Image.getInstance(filePath);
							img.scaleToFit(PageSize.A4.getWidth(),
									PageSize.A4.getHeight());
							document.newPage(); // new page for each image
							document.add(img);
						}
					}
					document.close();
					params.setBaos(pdfReport.getBaos());

				} else {
					String filePath = _DAO.fetchBlobRecord(recordID,
							params.getLoginUser(), params.getEntityID());
					if (filePath.length() > 0)
						params.setReportFileNameWithPath(filePath);
				}

			} else if ("EmployeeForms"
					.equalsIgnoreCase(params.getController())) {
				EmployeeFormsDAO _daoObj = (EmployeeFormsDAO) _DAO;
				String recordID = getRequestVal(params.getRequest(), "recordID")
						.toString();

				EmployeeForms bean = _daoObj.fetchRecord(recordID,
						params.getLoginUser(), params.getLoginUserRoles(),
						params.getLoginUserID(), params.getEntityID(),
						SubmitType.PRINT);

				params.setBaos(new MainPdfReport().generateTemplate(params,
						bean, _requestMap));
			}
		}

		return params;
	}

	private Map<String, String> getRequestParameterValuesMap(
			ControllerParameters params) {

		Map<String, String> requestMap = new HashMap<String, String>();
		Enumeration enumeration = params.getRequest().getParameterNames();
		while (enumeration.hasMoreElements()) {
			String fieldName = (String) enumeration.nextElement();
			if (fieldName == null || fieldName.trim().length() == 0)
				continue;
			if (!fieldName.startsWith("_qryStr")) {
				if (params.getRequest().getParameterValues(fieldName) != null) {
					String data = "";
					String[] paraValArr = params.getRequest()
							.getParameterValues(fieldName);
					if (paraValArr != null) {
						for (int k = 0; k < paraValArr.length; k++) {
							if (paraValArr[k].trim().length() > 0) {
								if (data.length() == 0) {
									data = paraValArr[k].trim();
								} else {
									data += " @@ " + paraValArr[k].trim();
								}
							}
						}
					}

					if (data.length() > 0) {
						if (requestMap.get(fieldName) != null)
							requestMap.remove(fieldName);

						requestMap.put(fieldName, data);
					}
				}
			}
		}
		System.out.println("getRequestParameterValuesMap :: "
				+ requestMap.size() + " :: " + requestMap);
		return requestMap;
	}
}
