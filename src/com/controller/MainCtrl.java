package com.controller;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.util.List;

import javax.activation.MimetypesFileTypeMap;
import javax.servlet.ServletOutputStream;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.commons.beanutils.ConvertUtils;
import org.apache.commons.beanutils.PropertyUtils;

import com.beans.ErrorBean;
import com.beans.MainBean;
import com.beans.SearchBean;
import com.dataobjects.MVPGDAO;
import com.dataobjects.MainDAO;
import com.util.SubmitType;

public class MainCtrl {

	public final String ATT_SEARCH_BEAN = "_recordBean";
	public final String ATT_RECORD_BEAN = "_recordBean";
	public final String ATT_ERROR_BEAN = "_errorBean";

	public Object createClassObj(String packageName, String className)
			throws Exception {

		if (packageName.contains(".controller"))
			className += "Ctrl";
		else if (packageName.contains(".dataobjects"))
			className += "DAO";

		String dynClassName = packageName + "." + className;
		System.out.println("createClassObj :: " + dynClassName);

		try {
			return Class.forName(dynClassName).newInstance();
		} catch (Exception ex) {
			if (dynClassName.endsWith("Ctrl"))
				return new MainCtrl();
			else if (dynClassName.endsWith("DAO"))
				return new MainDAO();
		}

		return null;
	}

	public Object getRequestVal(HttpServletRequest req, String paramName) {

		String requestVal = req.getParameter(paramName) == null ? ""
				: req.getParameter(paramName).trim();
		try {
			if (requestVal.length() > 0) {
				if (!"signatureValue".equalsIgnoreCase(paramName))
					requestVal = java.net.URLDecoder.decode(requestVal,
							"UTF-8");
				requestVal = requestVal.replaceAll("'", "''");

			} else if (requestVal.length() == 0) {
				requestVal = req.getAttribute(paramName) == null ? ""
						: req.getAttribute(paramName).toString().trim();
			}
		} catch (Exception ex) {
			ex.printStackTrace();
		}

		return requestVal;
	}

	public SearchBean setValuesToSearchBean(HttpServletRequest req,
			SearchBean searchBean) throws Exception {

		String pagingParams = "";
		String searchFilter = getRequestVal(req, "searchFilter").toString();
		if ("yes".equalsIgnoreCase(searchFilter)) {
			List<String> beanAttributes = searchBean.getBeanAttributes();
			for (int i = 0; i < beanAttributes.size(); i++) {
				String beanElementName = beanAttributes.get(i);
				Object beanElementValue = getRequestVal(req, beanElementName);
				Class<?> classType = PropertyUtils.getPropertyType(searchBean,
						beanElementName);
				beanElementValue = ConvertUtils.convert(beanElementValue,
						classType);
				PropertyUtils.setProperty(searchBean, beanElementName,
						beanElementValue);

				if (beanElementValue.toString().length() > 0)
					pagingParams += "&" + beanElementName + "="
							+ beanElementValue.toString();
			}
		}

		searchBean.setPagingParams(pagingParams);
		return searchBean;
	}

	public MainBean setValuesToBean(HttpServletRequest req, MainBean bean)
			throws Exception {

		List<String> beanAttributes = bean.getBeanAttributes();
		for (int i = 0; i < beanAttributes.size(); i++) {
			String beanElementName = beanAttributes.get(i);
			Object beanElementValue = getRequestVal(req, beanElementName);
			Class<?> classType = PropertyUtils.getPropertyType(bean,
					beanElementName);
			beanElementValue = ConvertUtils.convert(beanElementValue,
					classType);
			if (beanElementValue.toString().length() > 0)
				System.out.println("setValuesToBean :: " + beanElementName
						+ " :: " + beanElementValue);
			PropertyUtils.setProperty(bean, beanElementName, beanElementValue);
		}

		return bean;
	}

	public ControllerParameters searchRecords(ControllerParameters params)
			throws Exception {

		System.out.println("searchRecords :: " + params.getController());
		SearchBean searchBean = (SearchBean) setValuesToSearchBean(
				params.getRequest(), new SearchBean());

		MVPGDAO _DAO = (MVPGDAO) createClassObj("com.dataobjects",
				params.getController());

		searchBean = _DAO.searchRecords(searchBean, params.getRecordID(),
				params.getLoginUser(), params.getLoginUserRoles(),
				params.getLoginUserID(), params.getEntityID());

		params.getRequest().setAttribute(ATT_SEARCH_BEAN, searchBean);
		params.setSubmitType(SubmitType.SEARCH);
		params.setForwardTo("/jsp/" + params.getController() + ".jsp");
		return params;
	}

	public ControllerParameters createRecord(ControllerParameters params)
			throws Exception {

		System.out.println("createRecord :: " + params.getController());
		MVPGDAO _DAO = (MVPGDAO) createClassObj("com.dataobjects",
				params.getController());

		params.setSubmitType(SubmitType.CREATE);
		params.setForwardTo("/jsp/" + params.getController() + ".jsp");
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

		String recordID = getRequestVal(params.getRequest(), "recordID")
				.toString();

		MainBean _bean = (MainBean) _DAO.fetchRecord(recordID,
				params.getLoginUser(), params.getLoginUserRoles(),
				params.getLoginUserID(), params.getEntityID(), submitType);

		params.setSubmitType(submitType);
		params.getRequest().setAttribute(ATT_RECORD_BEAN, _bean);
		params.setForwardTo("/jsp/" + params.getController() + ".jsp");
		return params;
	}

	public ControllerParameters createRecordConfirm(ControllerParameters params)
			throws Exception {

		System.out.println("createRecordConfirm :: " + params.getController());
		MainBean _bean = (MainBean) createClassObj("com.beans",
				params.getController());
		_bean = (MainBean) setValuesToBean(params.getRequest(), _bean);

		MVPGDAO _DAO = (MVPGDAO) createClassObj("com.dataobjects",
				params.getController());

		Object returnObj[] = _DAO.createRecord(_bean, params.getLoginUser(),
				params.getLoginUserRoles(), params.getLoginUserID(),
				params.getEntityID());
		String recordID = returnObj[0].toString().trim();
		ErrorBean _errorBean = (ErrorBean) returnObj[1];
		params.getRequest().setAttribute(ATT_ERROR_BEAN, _errorBean);
		if (ErrorBean.enumTypes.success.toString()
				.equalsIgnoreCase(_errorBean.getType())) {
			params.getRequest().setAttribute("recordID", recordID);
			return fetchRecord(params);
		} else {
			params.setSubmitType(SubmitType.CREATE);
			params.getRequest().setAttribute(ATT_RECORD_BEAN, _bean);
			params.setForwardTo("/jsp/" + params.getController() + ".jsp");
			return params;
		}
	}

	public ControllerParameters updateRecord(ControllerParameters params)
			throws Exception {

		params = fetchRecord(params, SubmitType.UPDATE);
		return params;
	}

	public ControllerParameters updateRecordConfirm(ControllerParameters params)
			throws Exception {

		return params;
	}

	public ControllerParameters dynamic(ControllerParameters params)
			throws Exception {

		return params;
	}

	public ControllerParameters deleteRecord(ControllerParameters params)
			throws Exception {

		return params;
	}

	public ControllerParameters finalRecord(ControllerParameters params)
			throws Exception {

		return params;
	}

	public ControllerParameters printRecord(ControllerParameters params)
			throws Exception {

		return params;
	}

	public boolean openFile(String fileName, String fileNameWithPath,
			HttpServletResponse res, boolean isDownload) {
		System.out.println("openFile :: " + isDownload + " :: " + fileName
				+ " :: " + fileNameWithPath);
		boolean result = false;
		FileInputStream fileInputStream = null;
		ServletOutputStream servletOutputStream = null;
		try {
			int count = 0;
			servletOutputStream = res.getOutputStream();
			fileInputStream = new FileInputStream(fileNameWithPath);
			String mimeType = new MimetypesFileTypeMap()
					.getContentType(fileName);

			if (fileName.toLowerCase().endsWith(".pdf"))
				res.setContentType("application/pdf");

			else if (fileName.toLowerCase().endsWith(".gif"))
				res.setContentType("image/gif");

			else if (fileName.toLowerCase().endsWith(".png"))
				res.setContentType("image/png");

			else if (fileName.toLowerCase().endsWith(".jpeg")
					|| fileName.toLowerCase().endsWith(".jpg"))
				res.setContentType("image/jpeg");

			else if (fileName.toLowerCase().endsWith(".tif")
					|| fileName.toLowerCase().endsWith(".tiff"))
				res.setContentType("image/tiff");

			else
				res.setContentType(mimeType);

			if (isDownload) {
				res.setHeader("Content-Disposition",
						"attachment;filename=" + fileName);
			} else {
				res.setHeader("Content-Disposition", "inline;");
			}

			while ((count = fileInputStream.read()) != -1) {
				servletOutputStream.write(count);
			}
			fileInputStream.close();
			servletOutputStream.flush();
			servletOutputStream.close();
			result = true;
		} catch (NullPointerException e) {
			e.printStackTrace();
		} catch (FileNotFoundException e) {
			e.printStackTrace();
		} catch (IOException e) {
			e.printStackTrace();
		} finally {
			try {
				if (servletOutputStream != null)
					servletOutputStream.close();
				if (fileInputStream != null)
					fileInputStream.close();
			} catch (Exception e) {
				e.printStackTrace();
			}
		}

		try {
			res.flushBuffer();
			File deleFile = new File(fileNameWithPath);
			if (deleFile.exists())
				deleFile.delete();
		} catch (Exception ex) {
			ex.printStackTrace();
		}

		return result;
	}
}
