/*
 * Created on Sep 10, 2007
 *
 */
package com.tools;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.Base64;
import java.util.Iterator;
import java.util.List;

import javax.servlet.http.HttpServletRequest;

import org.apache.commons.fileupload.FileItem;
import org.apache.commons.fileupload.FileUploadException;
import org.apache.commons.fileupload.disk.DiskFileItemFactory;
import org.apache.commons.fileupload.servlet.ServletFileUpload;
import org.apache.commons.io.FilenameUtils;

/**
 * @author Ruban
 * 
 */
public class FileUpload {

	public boolean fetchFile(File fileObj) throws Exception {

		boolean fileCreated = false;
		FileInputStream fileinputstream = null;
		try {
			fileinputstream = new FileInputStream(fileObj);
			fileCreated = true;

		} catch (NullPointerException e) {
			fileCreated = false;
			throw e;

		} catch (FileNotFoundException e) {
			fileCreated = false;
			throw e;

		} finally {
			if (fileinputstream != null)
				fileinputstream.close();
		}

		return fileCreated;
	}

	public Object[] uploadBase64File(String base64, String fileName,
			String folderName) {

		boolean fileUploaded = true;
		String fileNameWithPath = "";
		File destinationDir = new File(folderName);
		if (!destinationDir.isDirectory())
			destinationDir.mkdirs();

		try {
			if (base64.length() > 0) {
				// Decode to bytes
				byte[] imageBytes = Base64.getDecoder().decode(base64);

				// Write bytes directly to file
				fileNameWithPath = folderName + File.separator + fileName;
				Files.write(Paths.get(fileNameWithPath), imageBytes);
			} else {
				fileUploaded = false;
			}

		} catch (Exception ex) {
			ex.printStackTrace();
			fileUploaded = false;
			fileNameWithPath = "";
		}

		System.out.println("uploadBase64File :: " + fileUploaded + " :: "
				+ fileNameWithPath);
		return new Object[] { fileUploaded, folderName };
	}

	public Object[] uploadFile(HttpServletRequest request, String loginUser,
			String uploadFrom) {

		boolean fileUploaded = true;
		String savedFileName = "";
		String realPath = ServerUploadPaths.getModuleUpload(uploadFrom,
				loginUser);

		File destinationDir = new File(realPath);
		if (!destinationDir.isDirectory())
			destinationDir.mkdirs();

		File tempDir = new File(ServerUploadPaths.getTemp());
		if (!tempDir.isDirectory())
			tempDir.mkdirs();

		DiskFileItemFactory factory = new DiskFileItemFactory();
		factory.setSizeThreshold(2 * 1024 * 1024);
		factory.setRepository(tempDir);

		ServletFileUpload upload = new ServletFileUpload(factory);
		List<?> items = null;
		try {
			items = upload.parseRequest(request);
		} catch (FileUploadException e) {
			System.err.println("Error while upload " + e.getMessage());
		}

		try {
			if (items != null) {
				Iterator<?> iterator = items.iterator();
				while (iterator.hasNext()) {
					FileItem item = (FileItem) iterator.next();
					if (!item.isFormField()) {
						String filename = item.getFieldName();
						String fileName = "";
						if (request.getParameter(filename) != null
								&& (request.getParameter(filename))
										.indexOf("\\") != -1) {
							fileName = (request.getParameter(filename))
									.substring((request.getParameter(filename))
											.lastIndexOf("\\"));
						} else {
							fileName = item.getName();
						}

						if (fileName != null && fileName.trim().length() > 0) {
							fileName = FilenameUtils.getName(fileName);

							File file = new File(destinationDir, fileName);
							item.write(file);
							savedFileName = fileName;
						}
					}
				}

			} else {
				fileUploaded = false;
			}

		} catch (Exception ex) {
			ex.printStackTrace();
			fileUploaded = false;
		}

		return new Object[] { fileUploaded, realPath, savedFileName };
	}
}
