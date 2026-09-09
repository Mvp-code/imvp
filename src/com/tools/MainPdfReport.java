package com.tools;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.StringReader;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.Map;

import com.beans.ApplicationConfig;
import com.beans.EmployeeForms;
import com.beans.SearchBean;
import com.controller.ControllerParameters;
import com.itextpdf.text.Chunk;
import com.itextpdf.text.Document;
import com.itextpdf.text.Element;
import com.itextpdf.text.Font;
import com.itextpdf.text.FontFactory;
import com.itextpdf.text.Image;
import com.itextpdf.text.PageSize;
import com.itextpdf.text.Paragraph;
import com.itextpdf.text.Phrase;
import com.itextpdf.text.Rectangle;
import com.itextpdf.text.html.simpleparser.HTMLWorker;
import com.itextpdf.text.html.simpleparser.StyleSheet;
import com.itextpdf.text.pdf.ColumnText;
import com.itextpdf.text.pdf.PdfPCell;
import com.itextpdf.text.pdf.PdfPRow;
import com.itextpdf.text.pdf.PdfPTable;
import com.itextpdf.text.pdf.PdfPageEventHelper;
import com.itextpdf.text.pdf.PdfTemplate;
import com.itextpdf.text.pdf.PdfWriter;

public class MainPdfReport extends MainReport {

	private ByteArrayOutputStream baos = new ByteArrayOutputStream();

	public ByteArrayOutputStream getBaos() {
		return baos;
	}

	public void setBaos(ByteArrayOutputStream baos) {
		this.baos = baos;
	}

	int reportHederFontSize = 14;
	int fontSize = 11;

	public class PdfPageEvent extends PdfPageEventHelper {

		PdfTemplate headerTemp;
		PdfTemplate footerTemp;
		PdfTemplate footerPageTemp;

		private String entityID = "";
		private String reportName = "";

		public PdfPageEvent(String reportName, String entityID) {
			this.reportName = reportName;
			this.entityID = entityID;
		}

		public void onOpenDocument(PdfWriter writer, Document document) {
			footerPageTemp = writer.getDirectContent().createTemplate(0, 0);
		}

		@Override
		public void onEndPage(PdfWriter writer, Document document) {
			addHeader(writer, document);
			addFooter(writer, document);
		}

		private void addHeader(PdfWriter writer, Document document) {
			try {
				PdfPTable headerTable = new PdfPTable(1);
				headerTable
						.setTotalWidth(document.getPageSize().getWidth() - 40);
				headerTable.setLockedWidth(true);
				headerTable.getDefaultCell()
						.setHorizontalAlignment(PdfPCell.ALIGN_CENTER);

				String logoPath = ApplicationConfig.getApplicationPath()
						+ "/images/logo/logo_" + entityID + ".jpeg";
				File logoObj = new File(logoPath);
				if (logoObj.exists()) {
					float imageHeight = 80f;
					headerTable.getDefaultCell().setFixedHeight(imageHeight);

					Image img = Image.getInstance(logoObj.getPath());
					PdfPCell pdfPCell = new PdfPCell(img, true);
					pdfPCell.setHorizontalAlignment(PdfPCell.ALIGN_CENTER);
					pdfPCell.setFixedHeight(imageHeight);
					pdfPCell.setBorder(Rectangle.NO_BORDER);
					headerTable.addCell(pdfPCell);

					Chunk chunk = new Chunk("", FontFactory.getFont(
							FontFactory.TIMES_ROMAN, fontSize, Font.BOLD));
					Paragraph para = new Paragraph(chunk);
					para.setAlignment(Element.ALIGN_CENTER);
					pdfPCell = new PdfPCell(para);
					pdfPCell.setHorizontalAlignment(PdfPCell.ALIGN_CENTER);
					pdfPCell.setBorder(Rectangle.TOP);
					headerTable.addCell(pdfPCell);

					headerTable.writeSelectedRows(0, -1, 22,
							document.top() + imageHeight,
							writer.getDirectContent());

				} else {
					Chunk chunk = new Chunk("MVPG", FontFactory
							.getFont(FontFactory.TIMES_ROMAN, 30, Font.BOLD));
					Paragraph para = new Paragraph(chunk);
					para.setAlignment(Element.ALIGN_CENTER);
					PdfPCell pdfPCell = new PdfPCell(para);
					pdfPCell.setHorizontalAlignment(PdfPCell.ALIGN_CENTER);
					pdfPCell.setVerticalAlignment(PdfPCell.ALIGN_CENTER);
					pdfPCell.setBorder(Rectangle.BOTTOM);
					headerTable.addCell(pdfPCell);

					headerTable.writeSelectedRows(0, -1, 22,
							document.top() + 40, writer.getDirectContent());
				}

			} catch (Exception ex) {
				ex.printStackTrace();
			}
		}

		private void addFooter(PdfWriter writer, Document document) {
			try {
				PdfPTable footerTable = new PdfPTable(3);
				footerTable
						.setTotalWidth(document.getPageSize().getWidth() - 30);
				footerTable.setLockedWidth(true);
				footerTable.getDefaultCell()
						.setHorizontalAlignment(PdfPCell.ALIGN_CENTER);
				PdfPCell pdfPCell = new PdfPCell(new Phrase(new Date() + ""));
				pdfPCell.setHorizontalAlignment(PdfPCell.ALIGN_LEFT);
				pdfPCell.setBorder(Rectangle.TOP);
				footerTable.addCell(pdfPCell);

				pdfPCell = new PdfPCell(new Phrase(reportName));
				pdfPCell.setHorizontalAlignment(PdfPCell.ALIGN_CENTER);
				pdfPCell.setBorder(Rectangle.TOP);
				footerTable.addCell(pdfPCell);

				pdfPCell = new PdfPCell(new Phrase(
						String.format("Page: " + writer.getPageNumber())));
				pdfPCell.setHorizontalAlignment(PdfPCell.ALIGN_RIGHT);
				pdfPCell.setBorder(Rectangle.TOP);
				footerTable.addCell(pdfPCell);

				footerTable.writeSelectedRows(0, -1, 10,
						document.getPageSize().getBottom() + 26,
						writer.getDirectContent());
			} catch (Exception ex) {
				ex.printStackTrace();
			}
		}

		public void onCloseDocument(PdfWriter writer, Document document) {
			ColumnText.showTextAligned(footerPageTemp, Element.ALIGN_CENTER,
					new Phrase(String.valueOf(writer.getPageNumber() - 1)), 2,
					2, 0);
		}
	}

	public Document getDocument(String displayName, boolean isPortrait,
			String entityID) throws Exception {

		Document document = null;
		if (isPortrait)
			document = new Document(PageSize.LETTER, 10, 10, 10, 10);
		else
			document = new Document(PageSize.LETTER.rotate(), 10, 10, 10, 10);

		document.setMargins(22, 22, 80, 25);

		PdfWriter pdfWriter = PdfWriter.getInstance(document, baos);
		pdfWriter.setPageEvent(new PdfPageEvent(displayName, entityID));
		pdfWriter.setViewerPreferences(PdfWriter.HideMenubar);

		document.open();
		return document;
	}

	public ByteArrayOutputStream generateReport(ControllerParameters params,
			SearchBean searchBean, String printType, boolean isPortrait)
			throws Exception {

		Document document = getDocument(searchBean.getDisplayName(), isPortrait,
				params.getEntityID());

		if ("DACheckin".equalsIgnoreCase(params.getController())) {
			if (searchBean.getSrhFromDate()
					.equalsIgnoreCase(searchBean.getSrhToDate())) {

				if ("view".equalsIgnoreCase(printType)) {
					List dataColumnList = new ArrayList();
					List dataList = new ArrayList();
					String tempKey = "";
					for (int i = 0; i < searchBean.getDataList().size(); i++) {
						List tempList = (ArrayList) searchBean.getDataList()
								.get(i);
						String key = tempList.get(1) == null ? ""
								: tempList.get(1).toString().trim();
						String employee = tempList.get(2) == null ? ""
								: tempList.get(2).toString().trim();
						String vehicle = tempList.get(3) == null ? ""
								: tempList.get(3).toString().trim();
						String serviceTier = tempList.get(4) == null ? ""
								: tempList.get(4).toString().trim();
						String parking = tempList.get(5) == null ? ""
								: tempList.get(5).toString().trim();
						String routeCode = tempList.get(6) == null ? ""
								: tempList.get(6).toString().trim();
						String staging = tempList.size() > 7
								? (tempList.get(7) == null ? ""
										: tempList.get(7).toString().trim())
								: "";
						if (!key.equalsIgnoreCase(tempKey)) {
							if (tempKey.length() > 0)
								dataList.add(dataColumnList);

							tempKey = key;
							dataColumnList = new ArrayList();
							List<String> tempRow = new ArrayList<String>();
							tempRow.add(key);
							tempRow.add("");
							tempRow.add("");
							tempRow.add("");
							tempRow.add("");
							dataColumnList.add(tempRow);

						}

						List<String> tempRow = new ArrayList<String>();
						tempRow.add(employee);
						tempRow.add(vehicle);
						tempRow.add(routeCode);
						tempRow.add(staging);
						tempRow.add(parking);
						dataColumnList.add(tempRow);
					}
					dataList.add(dataColumnList);

					List<String> labelsList = new ArrayList<String>();
					labelsList.add("Employee");
					labelsList.add("Vehicle");
					labelsList.add("Route");
					labelsList.add("Staging");
					labelsList.add("Parking");

					int colWidths[] = new int[] { 34, 27, 12, 13, 14 };

					for (int i = 0; i < dataList.size();) {
						List tempRow1 = (List) dataList.get(i);
						List tempRow2 = new ArrayList();
						i++;

						if (i < dataList.size())
							tempRow2 = (List) dataList.get(i);
						i++;

						String waveTime1 = "", waveTime2 = "";
						PdfPTable pdfpTable1 = new PdfPTable(colWidths.length);
						PdfPTable pdfpTable2 = new PdfPTable(colWidths.length);
						if (tempRow1.size() > 0) {
							List tempList = (ArrayList) tempRow1.get(0);
							waveTime1 = tempList.get(0) == null ? ""
									: tempList.get(0).toString().trim();
							tempRow1.remove(0);

							pdfpTable1 = getSearchReportData(labelsList,
									tempRow1, 0, colWidths, new int[] { 0 },
									false);
						}

						if (tempRow2.size() > 0) {
							List tempList = (ArrayList) tempRow2.get(0);
							waveTime2 = tempList.get(0) == null ? ""
									: tempList.get(0).toString().trim();
							tempRow2.remove(0);

							pdfpTable2 = getSearchReportData(labelsList,
									tempRow2, 0, colWidths, new int[] { 0 },
									false);
						}

						int wave1CNT = tempRow1.size();
						int wave2CNT = tempRow2.size();
						if (waveTime1.length() > 0)
							waveTime1 = "Wave1 - " + waveTime1 + " (" + wave1CNT
									+ ")";

						if (waveTime2.length() > 0)
							waveTime2 = "Wave2 - " + waveTime2 + " (" + wave2CNT
									+ ")";

						PdfPTable pdfpTable = new PdfPTable(2);
						pdfpTable.setWidthPercentage(100);
						pdfpTable.setWidths(new int[] { 50, 50 });

						pdfpTable.addCell(getTableData(waveTime1, Font.BOLD,
								PdfPCell.ALIGN_CENTER));
						pdfpTable.addCell(getTableData(waveTime2, Font.BOLD,
								PdfPCell.ALIGN_CENTER));

						pdfpTable = buildSectionData(pdfpTable1, pdfpTable, "");
						pdfpTable = buildSectionData(pdfpTable2, pdfpTable, "");

						document.add(pdfpTable);
						document.newPage();
					}

				} else {
					// Group by Wave Time - Each wave starts with New Page
					List dataList = new ArrayList();
					String tempKey = "";
					for (int i = 0; i < searchBean.getDataList().size(); i++) {
						List tempList = (ArrayList) searchBean.getDataList()
								.get(i);
						String key = tempList.get(1) == null ? ""
								: tempList.get(1).toString().trim();
						if (!key.equalsIgnoreCase(tempKey)) {
							if (tempKey.length() > 0) {
								document.add(getSearchReportData(
										searchBean.getLabelsList(), dataList, 1,
										searchBean.getWidthColumns(),
										new int[] { 2 }, false));
								document.add(getLineTable());
								document.add(getNameValue("Total",
										dataList.size() + ""));
								document.newPage();
							}

							tempKey = key;
							dataList = new ArrayList();
						}
						dataList.add(tempList);
					}

					if (dataList.size() > 0) {
						document.add(getSearchReportData(
								searchBean.getLabelsList(), dataList, 1,
								searchBean.getWidthColumns(), new int[] { 2 },
								false));
						document.add(getLineTable());
						document.add(
								getNameValue("Total", dataList.size() + ""));
					}
				}
			} else {
				document.add(getSearchReportData(searchBean.getLabelsList(),
						searchBean.getDataList(), 1,
						searchBean.getWidthColumns()));
			}
		} else {
			document.add(getSearchReportData(searchBean.getLabelsList(),
					searchBean.getDataList(), 1, searchBean.getWidthColumns()));
		}

		document.close();

		return baos;
	}

	public ByteArrayOutputStream generateTemplate(ControllerParameters params,
			EmployeeForms bean, Map<String, String> _requestMap)
			throws Exception {

		Document document = getDocument("Forms", true, params.getEntityID());

		document.add(getEmptyRowTable());
		document.add(getTableData(bean.getFormName(), Font.BOLD,
				PdfPCell.ALIGN_CENTER));
		document.add(getEmptyRowTable());

		int fontSizeValue = 9;
		float NO_BORDER = 0f;

		Font fontObj = new Font();
		fontObj.setSize(fontSizeValue);
		fontObj.setFamily(FontFactory.TIMES_ROMAN);

		Chunk bulletChunk = new Chunk("\u2022", fontObj);
		bulletChunk.setFont(fontObj);

		String formContents = bean.getFormContents();
		String signFileNameWithPath = bean.getSignFileNameWithPath();

		StyleSheet styleSheet = new StyleSheet();
		java.io.Reader reportReader = new StringReader(formContents);
		List<Element> parseToList = HTMLWorker.parseToList(reportReader,
				styleSheet);
		float[] tableWidths = new float[] { 100 };
		PdfPTable dataPdfPTable = new PdfPTable(tableWidths.length);
		dataPdfPTable.setWidthPercentage(100);
		dataPdfPTable.setWidths(tableWidths);

		for (int k = 0; k < parseToList.size(); k++) {
			Element element = parseToList.get(k);
			if (parseToList.get(k) instanceof PdfPTable) {
				PdfPTable tHtmlTable = (PdfPTable) parseToList.get(k);
				List<PdfPRow> pdfpRowsList = tHtmlTable.getRows();
				for (int i = 0; i < pdfpRowsList.size(); i++) {
					PdfPRow pdfpRow = pdfpRowsList.get(i);
					PdfPCell pdfpCellArray[] = pdfpRow.getCells();
					PdfPTable dynPdfPTable = new PdfPTable(
							pdfpCellArray.length);
					if (pdfpCellArray.length == 2)
						dynPdfPTable.setWidths(new float[] { 25f, 75f });
					dynPdfPTable.setWidthPercentage(100);
					for (int j = 0; j < pdfpCellArray.length; j++) {
						PdfPCell pdfPCell = pdfpCellArray[j];
						if (pdfPCell != null) {
							if (pdfPCell.getBorderWidth() == 0.0)
								pdfPCell.setBorderWidth(NO_BORDER);
							dynPdfPTable.addCell(pdfPCell);
						}
					}
					if (dynPdfPTable.size() > 0) {
						PdfPCell pdfPCell = new PdfPCell(dynPdfPTable);
						pdfPCell.setBorderWidth(NO_BORDER);
						dataPdfPTable.addCell(pdfPCell);
					}
				}

			} else {
				Paragraph paragraph = new Paragraph();
				List<Chunk> chunksList = element.getChunks();
				for (int ij = 0; ij < chunksList.size(); ij++) {
					Chunk chunk = chunksList.get(ij);

					if (chunksList.size() == 10) {
						if (bean.getFormContents().contains("<ol>")) {
							Chunk numberChunk = null;
							String unicode = "";
							switch (ij) {
							case 0:
								unicode = "\u0031. ";
								break;
							case 2:
								unicode = "\u0032. ";
								break;
							case 4:
								unicode = "\u0033. ";
								break;
							case 6:
								unicode = "\u0034. ";
								break;
							case 8:
								unicode = "\u0035. ";
								break;
							}
							if (unicode.length() > 0) {
								numberChunk = new Chunk(unicode, fontObj);
								paragraph.add(numberChunk);
							}
						} else if (bean.getFormContents().contains("<ul>")) {
							paragraph.add(bulletChunk);
						}
					}

					if (chunk.getContent().contains("##signature.employee##")) {
						String data = chunk.getContent()
								.replace("##signature.employee##", "");
						paragraph.add(data);

						if (bean.getSignFileNameWithPath().length() > 0) {
							Image image = Image.getInstance(
									bean.getSignFileNameWithPath());
							image.scaleToFit(100f, 200f);
							chunk = new Chunk(image, 0, 0, true);
							paragraph.add(chunk);
						}

					} else {
						paragraph.add(new Phrase(chunk));
					}
				}

				if (paragraph != null) {
					PdfPCell pdfPCell = new PdfPCell(paragraph);
					pdfPCell.setBorderWidth(NO_BORDER);
					pdfPCell.setPadding(5);
					dataPdfPTable.addCell(pdfPCell);
				}
			}
		}

		document.add(dataPdfPTable);

		if (bean.getComments().length() > 0) {
			document.add(getNameValue("Comments", bean.getComments()));
			document.add(getEmptyRowTable());
		}

		document.close();

		return baos;
	}

	public ByteArrayOutputStream generateDashboardReport(
			ControllerParameters params, Map<String, String> _requestMap,
			Object[] dataObjArray) throws Exception {

		Document document = getDocument("Dashboard", false,
				params.getEntityID());
		String dashboardOverviewID = dataObjArray[0].toString();
		String followupTargetDate = dataObjArray[1].toString();
		List section1List = (ArrayList) dataObjArray[2];
		List safetyList = (ArrayList) dataObjArray[3];
		List qualityList = (ArrayList) dataObjArray[4];
		List accidentList = (ArrayList) dataObjArray[5];
		List incidentList = (ArrayList) dataObjArray[6];
		List dvicList = (ArrayList) dataObjArray[7];

		int colWidths[] = new int[] { 6, 6, 20, 10, 10, 10, 7, 7, 24 };
		PdfPTable sectionLabelList = new PdfPTable(colWidths.length);
		sectionLabelList.setWidthPercentage(100);
		sectionLabelList.setWidths(colWidths);

		PdfPTable sectionDataList = new PdfPTable(colWidths.length);
		sectionDataList.setWidthPercentage(100);
		sectionDataList.setWidths(colWidths);
		for (int i = 0; i < section1List.size(); i++) {
			List tempList = (ArrayList) section1List.get(i);
			String label = getListData(tempList, 0);
			String value = getListData(tempList, 1);
			sectionLabelList.addCell(
					getTableData(label, Font.BOLD, PdfPCell.ALIGN_LEFT));
			sectionDataList.addCell(
					getTableData(value, Font.NORMAL, PdfPCell.ALIGN_LEFT));
		}
		document.add(getEmptyRowTable());
		document.add(sectionLabelList);
		document.add(sectionDataList);
		document.add(getEmptyRowTable());

		colWidths = new int[] { 75, 25 };
		PdfPTable qualityTable = new PdfPTable(colWidths.length);
		qualityTable.setWidthPercentage(100);
		qualityTable.setWidths(colWidths);
		for (int i = 0; i < qualityList.size(); i++) {
			List tempList = (ArrayList) qualityList.get(i);
			String label = getListData(tempList, 0);
			String value = getListData(tempList, 1);
			qualityTable = getNameValue(label, value, qualityTable);
		}

		PdfPTable safetyTable = new PdfPTable(colWidths.length);
		safetyTable.setWidthPercentage(100);
		safetyTable.setWidths(colWidths);
		for (int i = 0; i < safetyList.size(); i++) {
			List tempList = (ArrayList) safetyList.get(i);
			String label = getListData(tempList, 0);
			String value = getListData(tempList, 1);
			safetyTable = getNameValue(label, value, safetyTable);
		}

		colWidths = new int[] { 20, 80 };
		PdfPTable incidentTable = new PdfPTable(colWidths.length);
		incidentTable.setWidthPercentage(100);
		incidentTable.setWidths(colWidths);
		for (int i = 0; i < incidentList.size(); i++) {
			List tempList = (ArrayList) incidentList.get(i);
			String id = getListData(tempList, 0);
			String date = getListData(tempList, 1);
			String type = getListData(tempList, 2);
			String desc = getListData(tempList, 3);
			if (i > 0)
				incidentTable = getEmptyRow(2, incidentTable);
			incidentTable = getNameValue("Date", date, incidentTable);
			incidentTable = getNameValue("Type", type, incidentTable);
			incidentTable = getNameValue("Desc", desc, incidentTable);
		}

		colWidths = new int[] { 20, 80 };
		PdfPTable accidentsTable = new PdfPTable(colWidths.length);
		accidentsTable.setWidthPercentage(100);
		accidentsTable.setWidths(colWidths);
		for (int i = 0; i < accidentList.size(); i++) {
			List tempList = (ArrayList) accidentList.get(i);
			String id = getListData(tempList, 0);
			String date = getListData(tempList, 1);
			String type = getListData(tempList, 2);
			String desc = getListData(tempList, 3);
			if (i > 0)
				accidentsTable = getEmptyRow(2, accidentsTable);
			accidentsTable = getNameValue("Date", date, accidentsTable);
			accidentsTable = getNameValue("Type", type, accidentsTable);
			accidentsTable = getNameValue("Desc", desc, accidentsTable);
		}

		colWidths = new int[] { 33, 34, 33 };
		PdfPTable section2Table = new PdfPTable(colWidths.length);
		section2Table.setWidthPercentage(100);
		section2Table.setWidths(colWidths);
		section2Table.addCell(getTableData("Safety Metrics", Font.BOLD,
				PdfPCell.ALIGN_CENTER));
		section2Table.addCell(getTableData("Quality Metrics", Font.BOLD,
				PdfPCell.ALIGN_CENTER));
		section2Table.addCell(
				getTableData("Incidents", Font.BOLD, PdfPCell.ALIGN_CENTER));
		section2Table = buildSectionData(safetyTable, section2Table,
				"Fantastic");
		section2Table = buildSectionData(qualityTable, section2Table,
				"Fantastic");
		section2Table = buildSectionData(incidentTable, section2Table,
				"Fantastic");
		document.add(section2Table);
		document.add(getEmptyRowTable());

		List<String> dvicHeaderList = new ArrayList<String>();
		if (dvicList.size() > 0) {
			List tempList = (ArrayList) dvicList.get(0);
			dvicHeaderList = tempList;
			dvicList.remove(0);
		}
		PdfPTable dvicTable = getSearchReportData(dvicHeaderList, dvicList, 0,
				new int[] { 16, 12, 12, 12, 12, 12, 12, 12 });

		colWidths = new int[] { 33, 67 };
		PdfPTable section3Table = new PdfPTable(colWidths.length);
		section3Table.setWidthPercentage(100);
		section3Table.setWidths(colWidths);
		section3Table.addCell(
				getTableData("Accidents", Font.BOLD, PdfPCell.ALIGN_CENTER));
		section3Table.addCell(
				getTableData("DVIC/ EOC", Font.BOLD, PdfPCell.ALIGN_CENTER));
		section3Table = buildSectionData(accidentsTable, section3Table,
				"Fantastic");
		section3Table = buildSectionData(dvicTable, section3Table, "Fantastic");
		document.add(section3Table);
		document.add(getEmptyRowTable());

		String coachingNotes = _requestMap.get("coachingNotes") == null ? ""
				: _requestMap.get("coachingNotes").toString().trim();
		if (coachingNotes.length() > 0) {
			document.add(getNameValue("Coaching Notes", coachingNotes));
			document.add(getEmptyRowTable());
		}

		String coachingResults = _requestMap.get("coachingResults") == null ? ""
				: _requestMap.get("coachingResults").toString().trim();
		if (coachingNotes.length() > 0) {
			document.add(getNameValue("Coaching Results", coachingResults));
			document.add(getEmptyRowTable());
		}

		document.close();

		return baos;
	}

	public PdfPTable buildSectionData(PdfPTable dataTable, PdfPTable retTable,
			String defaultValue) {

		if (dataTable.size() > 0)
			retTable.addCell(dataTable);
		else
			retTable.addCell(getTableData(defaultValue, Font.NORMAL,
					PdfPCell.ALIGN_CENTER));
		return retTable;
	}

	public String getListData(List tempList, int index) {

		String colData = tempList.get(index) == null ? ""
				: tempList.get(index).toString().trim();
		return colData;
	}

	public PdfPTable getEmptyRow(int colspan, PdfPTable pTable) {

		PdfPCell pdfPCell = new PdfPCell(new Phrase("\n"));
		pdfPCell.setColspan(colspan);
		pdfPCell.setHorizontalAlignment(PdfPCell.ALIGN_LEFT);
		pdfPCell.setBorderWidth(Rectangle.NO_BORDER);
		pTable.addCell(pdfPCell);
		return pTable;
	}

	public PdfPTable getEmptyRowTable() {

		PdfPTable pTable = new PdfPTable(1);
		pTable.setWidthPercentage(100);
		PdfPCell pdfPCell = new PdfPCell(new Phrase("\n"));
		pdfPCell.setHorizontalAlignment(PdfPCell.ALIGN_LEFT);
		pdfPCell.setBorderWidth(Rectangle.NO_BORDER);
		pTable.addCell(pdfPCell);
		return pTable;
	}

	public PdfPTable getLineTable() {

		PdfPTable pTable = new PdfPTable(1);
		pTable.setWidthPercentage(100);
		PdfPCell pdfPCell = new PdfPCell(new Phrase(""));
		pdfPCell.setHorizontalAlignment(PdfPCell.ALIGN_LEFT);
		pdfPCell.disableBorderSide(Rectangle.LEFT);
		pdfPCell.disableBorderSide(Rectangle.RIGHT);
		pdfPCell.disableBorderSide(Rectangle.TOP);
		pdfPCell.enableBorderSide(Rectangle.BOTTOM);
		pdfPCell.setBorderWidthBottom(1f);
		pTable.addCell(pdfPCell);
		return pTable;
	}

	public PdfPTable getTableData(String value, int fontStyle, int fontAlign) {

		PdfPTable pTable = new PdfPTable(1);
		pTable.setWidthPercentage(100);
		Chunk chunk = new Chunk(value, FontFactory
				.getFont(FontFactory.TIMES_ROMAN, fontSize, fontStyle));
		PdfPCell pdfPCell = new PdfPCell(new Phrase(chunk));
		pdfPCell.setHorizontalAlignment(fontAlign);
		pdfPCell.setBorderWidth(Rectangle.NO_BORDER);
		pTable.addCell(pdfPCell);
		return pTable;
	}

	public PdfPTable getNameValue(String label, String value) {

		PdfPTable pTable = new PdfPTable(1);
		pTable.setWidthPercentage(100);
		PdfPCell pdfPCell = new PdfPCell(new Phrase(label + ": " + value));
		pdfPCell.setHorizontalAlignment(PdfPCell.ALIGN_LEFT);
		pdfPCell.setBorderWidth(Rectangle.NO_BORDER);
		pTable.addCell(pdfPCell);
		return pTable;
	}

	public PdfPTable getNameValue(String label, String value, PdfPTable pTable)
			throws Exception {

		PdfPCell pdfPCell = new PdfPCell(new Phrase(label));
		pdfPCell.setHorizontalAlignment(PdfPCell.ALIGN_LEFT);
		pdfPCell.setBorderWidth(Rectangle.NO_BORDER);
		pTable.addCell(pdfPCell);

		pdfPCell = new PdfPCell(new Phrase(": " + value));
		pdfPCell.setHorizontalAlignment(PdfPCell.ALIGN_LEFT);
		pdfPCell.setBorderWidth(Rectangle.NO_BORDER);
		pTable.addCell(pdfPCell);
		return pTable;
	}

	public PdfPTable getSearchReportData(List<String> headerList, List dataList,
			int startIndex, int colWidths[]) throws Exception {
		return getSearchReportData(headerList, dataList, startIndex, colWidths,
				null, false);
	}

	public PdfPTable getSearchReportData(List<String> headerList, List dataList,
			int startIndex, int colWidths[], int colsBold[],
			boolean displayBorder) throws Exception {

		PdfPTable pdfpTable = new PdfPTable(colWidths.length);
		pdfpTable.setWidthPercentage(100);
		pdfpTable.setWidths(colWidths);

		if (dataList.size() > 0) {
			int numOfCols = startIndex + headerList.size();
			for (int i = 0; i < headerList.size(); i++) {
				String colLabel = headerList.get(i) == null ? ""
						: headerList.get(i).toString().trim();
				Chunk chunk = new Chunk(colLabel, FontFactory
						.getFont(FontFactory.TIMES_ROMAN, fontSize, Font.BOLD));
				chunk.setUnderline(1.0f, -1.0f);
				PdfPCell cell = new PdfPCell(new Phrase(chunk));
				if (!displayBorder)
					cell.setBorderWidth(Rectangle.NO_BORDER);
				cell.setHorizontalAlignment(PdfPCell.ALIGN_LEFT);
				pdfpTable.addCell(cell);
			}
			pdfpTable.setHeaderRows(1);

			for (int i = 0; i < dataList.size(); i++) {
				List tempList = (ArrayList) dataList.get(i);
				for (int j = startIndex; j < numOfCols; j++) {
					String colData = tempList.get(j) == null ? ""
							: ExcelFile.stripHtml(tempList.get(j).toString());
					boolean isBold = false;
					if (colsBold != null) {
						for (int k = 0; k < colsBold.length; k++) {
							if (colsBold[k] == j) {
								isBold = true;
								break;
							}
						}
					}

					Chunk chunk = new Chunk(colData,
							FontFactory.getFont(FontFactory.TIMES_ROMAN,
									fontSize,
									(isBold ? Font.BOLD : Font.NORMAL)));

					PdfPCell cell = new PdfPCell(new Phrase(chunk));
					if (!displayBorder)
						cell.setBorderWidth(Rectangle.NO_BORDER);
					cell.setHorizontalAlignment(PdfPCell.ALIGN_LEFT);
					pdfpTable.addCell(cell);
				}
			}
		}

		return pdfpTable;
	}
}
