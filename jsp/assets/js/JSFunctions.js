jQuery(document).ready(function() {
	let formmainObj = document.getElementById("formmain");
	formmainObj.onkeypress = function (key) {
		let btn = 0 || key.keyCode || key.charCode;
		if (btn == 13) {
			key.preventDefault();
            // ? Identify if Enter was pressed inside a TEXTAREA
            if (document.activeElement.tagName.toLowerCase() === "textarea") {
                console.log("Enter inside textarea � ignored.");
                return;
            }

			// ?? Search button click if exists
			if(document.getElementById("searchFilterBtnID")) {
				document.getElementById("searchFilterBtnID").click();
			} else {
				console.log("Enter Key is Pressed!");
			}
		}
	}
});

function setXMLHttpOb(url) {
	var dynamicReq = newXMLHttpRequest();
	dynamicReq.open("POST", url, true);
	dynamicReq.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
	return dynamicReq;
}

function setSynXMLHttpOb(url) {
	var dynamicReq = newXMLHttpRequest();
	dynamicReq.open("POST", url, false);
	dynamicReq.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
	return dynamicReq;
}

function newXMLHttpRequest() {

	var dynamicReq = false;
	if (window.XMLHttpRequest) {
		dynamicReq = new XMLHttpRequest();
	} else if (window.ActiveXObject) {
		try {
			dynamicReq = new ActiveXObject("Msxml2.XMLHTTP");
		} catch (e1) {
			alert("Failed to create required ActiveXObject");
			try {
				dynamicReq = new ActiveXObject("Microsoft.XMLHTTP");
			} catch (e2) {
				alert("Unable to create an XMLHttpRequest with ActiveX");
			}
		}
	}

	return dynamicReq;
}

function checkDots(getTime) {
	for(var i=0; i<getTime.length; i++) {
		var str1 = getTime.substr(i,(i+1));
		if(str1==".") {
			break;
			return false;
		} else {
			return true;
		}
	}
}

function fixTime(timeName) {
	fixTimeConcat(document.formmain[timeName+"Txt"], document.formmain[timeName+"Sel"], document.formmain[timeName]);
}

function fixTimeConcat(txtObj, selObj, hidObj) {
	var getTime = Trim(txtObj.value);
	if(getTime.length > 0) {
		var boname  = hidObj.name;
		var boname1 = txtObj.name;

		var temptime,tempminute;
		var setbool = false;
		var setBool = false;
		var setLastBool = false;

		var timePat1 = /^(\d{2}):(\d{2})/;
		var timePat2 = /^(\d{1}):(\d{1})/;
		var timePat3 = /^(\d{1}):(\d{2})/;
		var timePat4 = /^(\d{2}):(\d{1})/; 
		var timePat5 = /^(\d{3})/; 
		var timePat6 = /^(\d{4})/; 

		var matchArray1 = getTime.match(timePat1);
		var matchArray2 = getTime.match(timePat2);
		var matchArray3 = getTime.match(timePat3);
		var matchArray4 = getTime.match(timePat4);
		var matchArray5 = getTime.match(timePat5);
		var matchArray6 = getTime.match(timePat6);

		var matchArray = new Array();
		if (matchArray1 != null) {
			matchArray = matchArray1;
		} else if(matchArray3 != null) {
			matchArray = matchArray3;
		} else if(matchArray2 != null) {
			matchArray = matchArray2;
		} else if(matchArray4 != null) {
			matchArray = matchArray4;
		} else if(matchArray6 != null) {
			matchArray = matchArray6;
			setLastBool = true;
		} else if(matchArray5 != null) {
			matchArray = matchArray5;
			setBool = true;
		} else {
			var timestr = getTime.toString();
			if(!(isNaN(timestr)) && ((timestr.length==1) || (timestr.length==2)) && checkDots(timestr)) {
				temptime   = timestr;
				tempminute = "0";
				setbool = true;
			} else {
				alert("Time is not in a valid format. Format is HH:MM");
				if(hidObj != null)
					hidObj.value = "";

				if(textObj != null) {
					textObj.value = "";
					textObj.focus();
				}
				return false;
			}
		}

		if(setbool) {
			hour   = temptime;
			minute = tempminute;
		} else {
			if(setBool) {
				var coreValue=matchArray[1];
				hour=coreValue.substring(0,1);
				minute=coreValue.substring(1,coreValue.length);
			} else if(setLastBool) {
				var coreValue=matchArray[1];
				hour=coreValue.substring(0,2);
				minute=coreValue.substring(2,coreValue.length);
			} else {
				hour = matchArray[1];
				minute = matchArray[2];
			}
		}

		if (hour <=0  || hour > 12) {
			alert("Hour must be between 1 and 12.");
			if(txtObj != null) {
				txtObj.value = "";
				txtObj.focus();
			}
			return false;
		} else if(minute<0 || minute > 59) {
			alert ("Minute must be between 0 and 59.");
			if(txtObj != null) {
				txtObj.value = "";
				txtObj.focus();
			}
			return false;
		} else {
			if(hour.length == 1) {
				hour = "0"+hour.toString()
			}
			if(minute.length == 1) {
				minute = "0"+minute.toString()
			}
			var timeval = hour+":"+minute;
			var timewithampm = timeval+" "+selObj.value;
			if(hidObj != null)
				hidObj.value = timewithampm;

			if(txtObj != null)
				txtObj.value = timeval;
		}
	}
}

function getXMLValue(xmlResp) {
	var data = "";
	if(xmlResp != null && xmlResp.firstChild != null && xmlResp.firstChild.nodeValue != null) {
		// Firefox 4k XML node limit. Firefox provides the textContent attribute.
		// But some IE versions doesn't support the textContent attribute
		if(typeof(xmlResp.textContent) != "undefined") {
			data = xmlResp.textContent;
		} else {
			data = xmlResp.firstChild.nodeValue;
		}
	}
	return data;
}

function initSelect2SuggestorConvert(selectID, placeHolderName, isCombo, maximumInputLength) {

	if(document.getElementById(selectID)) {
		maximumInputLength = maximumInputLength == undefined ? 100 : maximumInputLength;
		isCombo = isCombo == undefined ? false : isCombo;
		jQuery("#"+selectID).select2({
			tags: isCombo,
			allowClear: true,
			maximumInputLength: maximumInputLength,
			placeholder: placeHolderName
		});
	}
}

function initSelect2Suggestor(suggestorType, selectID, selectValue, isCombo, appQryString) {

	if(document.getElementById(selectID)) {
		selectValue = selectValue == undefined ? "" : selectValue;
		isCombo = isCombo == undefined ? false : isCombo;
		appQryString = appQryString == undefined ? "" : appQryString;
		console.log("initSelect2Suggestor :: " +suggestorType+" :: "+selectID+" :: "+selectValue+" :: "+isCombo+" :: "+appQryString);
		jQuery("#"+selectID).select2({
			tags: isCombo,
			allowClear: true,
			placeholder: "Select"

		}).on("select2:select", function (e) {

		}).on("select2:clear", function (e) {
			selectValue = "";

		}).on("select2:open", function (e) {
			initSelect2SuggestorLoad(suggestorType, selectID, selectValue, isCombo, appQryString);
		});

		if(selectValue.length > 0) {
			initSelect2SuggestorLoad(suggestorType, selectID, selectValue, isCombo, appQryString);
		}
	}
}

function initSelect2SuggestorLoad(suggestorType, selectID, selectValue, isCombo, appQryString) {
	console.log("initSelect2SuggestorLoad :: " +suggestorType+" :: "+selectID+" :: "+selectValue+" :: "+isCombo+" :: "+appQryString);
	var xmlHttpRequest = setSynXMLHttpOb("../servlet/MVPGServlet");
	var str = "submitType=10&controller=Incident&requestType=suggestor&suggestorType="+suggestorType+"&suggestorValue="+selectValue+appQryString+getEntityParams();
	xmlHttpRequest.send(str);
	var suggestorTxt = xmlHttpRequest.responseText;
	initSelect2SuggestorSetData(selectID, suggestorTxt);
}

function initSelect2SuggestorSetData(selectID, suggestorTxt, selectVal, enableEvent) {

	if(document.getElementById(selectID)) {
		selectVal = selectVal == undefined ? "" : selectVal;
		enableEvent = enableEvent == undefined ? true : enableEvent;
		jQuery("#"+selectID).html(suggestorTxt);
		jQuery("#"+selectID).trigger("change");
		if(selectVal.length > 0) {
			jQuery("#"+selectID).val(selectVal);
			if(enableEvent)
				jQuery("#"+selectID).trigger("change");
		}
	}
}

function setSelect2Option(selectID, selectValue) {

	if(document.getElementById(selectID)) {
		if(document.getElementById(selectID).type == "select-one") {
			// Set the value, creating a new option if necessary
			if (jQuery("#"+selectID).find("option[value='" + selectValue + "']").length) {
				jQuery("#"+selectID).val(selectValue).trigger('change');
			} else { 
				// Create a DOM Option and pre-select by default
				var newOption = new Option(selectValue, selectValue, true, true);
				// Append it to the select
				jQuery("#"+selectID).append(newOption).trigger('change');
			}
		}
	}
}

var futuredate = new Date();
	futuredate.setDate(futuredate.getDate()+1);
jQuery(function() {
	if(jQuery(".datepicker") != null && jQuery(".datepicker").length) {
		jQuery(".datepicker").datepicker({
			autoclose: true,			
			todayHighlight: true,
			format: "mm/dd/yyyy"
		});
	}

	if(jQuery(".futuredatepicker") != null && jQuery(".futuredatepicker").length) {
		jQuery(".futuredatepicker").datepicker({
			autoclose: true,			
			todayHighlight: true,
			format: "mm/dd/yyyy"
		}).datepicker('setStartDate', futuredate);
	}
});

function reloadDatePicker() {
	jQuery(function() {
		if(jQuery(".datepicker") != null && jQuery(".datepicker").length) {
			jQuery(".datepicker").datepicker({
				autoclose: true,			
				todayHighlight: true,
				format: "mm/dd/yyyy"
			});
		}

		if(jQuery(".futuredatepicker") != null && jQuery(".futuredatepicker").length) {
			jQuery(".futuredatepicker").datepicker({
				autoclose: true,			
				todayHighlight: true,
				format: "mm/dd/yyyy"
			}).datepicker('setStartDate', futuredate);
		}
	});
}

function checkPageLock() {
	if (!((document.forms["formmain"] && document.forms["formmain"].pageSubmitLock.value != ""))) {
		document.formmain.pageSubmitLock.value = "locked";
		return true;
	} else {
		alert ("Please wait... we are still processing your last request...");
		return false;
	}
}

function pageUnlock() {
	if (!((document.forms["formmain"] && document.forms["formmain"].pageSubmitLock)))
		document.formmain.pageSubmitLock.value = "unlocked";
}

function generateRequestId() {
    if (crypto && crypto.randomUUID) {
        return crypto.randomUUID();
    }

    // fallback
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, c => {
        const r = Math.random() * 16 | 0;
        const v = c === 'x' ? r : (r & 0x3 | 0x8);
        return v.toString(16);
    });
}

function validateMandatoryFieldsInForm(formObjArray, isValid) {
	if(formObjArray != null && isValid) {
		var msgToappend = "";
		var focusFirstEleObj = null;
		for (var i in formObjArray) {
			elementObj = formObjArray[i][0];
			if(elementObj == null)
				continue;

			var displayName = formObjArray[i][1];
			var tempVal = elementObj.value;
			if(tempVal.length == 0) {
				if(focusFirstEleObj == null)
					focusFirstEleObj = elementObj
				msgToappend = msgToappend+"\n"+displayName;
			}
		}

		if(msgToappend.length > 0) {
			isValid = false;
			msgToappend = msgToappend+"\n";
			alert("These fields are mandatory\n------------------------------------"+msgToappend);
			if(document.formmain.pageSubmitLock != null)
				document.formmain.pageSubmitLock.value = "unlocked";
			if(focusFirstEleObj != null)
				focusFirstEleObj.focus();
		}
	}

	return isValid;
}

function getEntityParams() {
	
	var appendParam = "";
	appendParam += getFormObjNameValue(document.formmain["entityID"], ",");
	appendParam += getFormObjNameValue(document.formmain["loginUser"], ",");
	appendParam += getFormObjNameValue(document.formmain["loginUserID"], ",");
	appendParam += getFormObjNameValue(document.formmain["loginUserRoles"], ",");
	return appendParam;
}

function getFormObjNameValue(thisObj, dataSeperator) {
	var tempVal = "";
	if(thisObj != null) {
		switch(thisObj.type) {
		case "select-one":
			tempVal = getSelectBoxValue(thisObj);
			break;

		case "select-multiple":
			tempVal = getMultiselectBoxValue(thisObj, dataSeperator);
			break;

		case "undefined":
		case "checkbox":
			tempVal = getCheckboxValue(thisObj, dataSeperator);
			break;

		case "radio":
			tempVal = getRadioButtonValue(thisObj, dataSeperator);
			break;

		default:
			thisObj.value = Trim(thisObj.value);
			tempVal = thisObj.value;
			break;
		}
		tempVal = "&"+thisObj.name+"="+tempVal;
	}
	return tempVal;
}

function getPageSubmitFormValues(hideHiddenInputs) {
	hideHiddenInputs = hideHiddenInputs == undefined ? false : hideHiddenInputs;
	var appendParam = "";
	for(i=0; i<document.formmain.elements.length; i++) {
		var formElementObj = document.formmain.elements[i];
		if(formElementObj != null && formElementObj.value.length > 0
				&& formElementObj.name && String(formElementObj.name).length > 0) {
			if(formElementObj.type == "hidden") {
				if(formElementObj.name == "entityID" || formElementObj.name == "loginUser" || formElementObj.name == "loginUserID" || formElementObj.name == "loginUserRoles") {
					appendParam += "&"+formElementObj.name+"="+formElementObj.value;

				} else if(hideHiddenInputs) {
					continue;
				}
			}

			switch(formElementObj.name) {
				case "mode":
				case "boSubmitLock":
					break;

				default:
					if(formElementObj.type.toLowerCase() == "file") {
						appendParam += getUploadFileObjValue(formElementObj);
					} else {
						var formVal = getFormObjValue(formElementObj, ",");
						if(formVal.length > 0)
							appendParam += "&"+formElementObj.name+"="+formVal;
					}
					break;
			}
		}
	}
	return appendParam;
}

function getFormObjValue(thisObj, dataSeperator) {
	var tempVal = "";
	if(thisObj != null) {
		switch(thisObj.type) {
		case "select-one":
			tempVal = getSelectBoxValue(thisObj);
			break;

		case "select-multiple":
			tempVal = getMultiselectBoxValue(thisObj, dataSeperator);
			break;

		case "undefined":
		case "checkbox":
			tempVal = getCheckboxValue(thisObj, dataSeperator);
			break;

		case "radio":
			tempVal = getRadioButtonValue(thisObj, dataSeperator);
			break;

		default:
			thisObj.value = Trim(thisObj.value);
			tempVal = thisObj.value;
			break;
		}
	}
	return tempVal;
}

function getUploadFileObjValue(formElementObj, fileObjName) {
	fileObjName = fileObjName == undefined ? "" : fileObjName;
	if(fileObjName.length == 0)
		fileObjName = formElementObj.name;
	if(formElementObj != null && formElementObj.type.toLowerCase() == "file" && formElementObj.files.length > 0)
		return "&"+fileObjName+"="+document.getElementById(formElementObj.id).files[0].name;
	return "";
}

function submitEmptyForm() {
	var status = 'This status is to avoid HTML spec Bugs';
}

var appQryDivPopup = "";
function submitPageDataForm(submitType, controller, recordID, status, appQry) {
	var isValid = true;
	recordID = recordID == undefined ? "" : recordID;
	status = status == undefined ? "" : status;
	appQry = appQry == undefined ? "" : appQry;
	isValid = (typeof validatePageData === 'function') ? validatePageData(submitType, isValid) : isValid;
	if(isValid) {
		if(recordID.length > 0)
			appQry += "&recordID="+recordID;
		if(status.length > 0)
			appQry += "&status="+status;
		/* File pages (Vehicles) used to dump every control into the next URL,
		   including nameless filters as &=operational which UAT/IIS returns blank. */
		if (submitType != "1" && document.querySelector('input[type="file"]'))
			appQry += getPageSubmitFormValues();
		if(submitType == "9") {
			window.open("../servlet/MVPGServlet?submitType="+submitType+"&controller="+controller+appQry+getPageSubmitFormValues(true));
		} else {
			/* Plain page navigation (SEARCH with no explicit searchFilter): drop this
			   page's srh* filter fields so date ranges don't leak into the next
			   module's query (e.g. DA Checkin's date hiding every Vehicle) */
			if (submitType == "1" && appQry.indexOf("searchFilter=yes") < 0 && document.formmain) {
				var srhEls = document.formmain.querySelectorAll('[name^="srh"]');
				for (var si = 0; si < srhEls.length; si++) srhEls[si].disabled = true;
			}
			document.formmain.action = "../servlet/MVPGServlet?submitType="+submitType+"&controller="+controller+appQry+appQryDivPopup;
			document.formmain.submit();
		}
	}
}

function sortSearchRecords(submitType, controller, index, sortOrder) {

	var isValid = true;
	isValid = (typeof validatePageData === 'function') ? validatePageData(submitType, isValid) : isValid;
	var prevSortColIndex = document.formmain["prevSortColIndex"].value;
	sortOrder = sortOrder == undefined ? "" : sortOrder;
	index = (parseInt(index)+2);

	if(prevSortColIndex.length == 0)
		sortOrder = "ASC";
	else if(prevSortColIndex == (index+"")) {
		if(sortOrder == "ASC")
			sortOrder = "DESC";
		else
			sortOrder = "ASC";
	} else
		sortOrder = "ASC";

	var appQry = "&searchFilter=yes&columnSortName="+index+"&columnSortOrder="+sortOrder;
	if(isValid) {
		if (document.querySelector('input[type="file"]'))
			appQry += getPageSubmitFormValues();
		document.formmain.action = "../servlet/MVPGServlet?submitType="+submitType+"&controller="+controller+appQry;
		document.formmain.submit();
	}
}

function deleteRows(tableName) {
	if(document.getElementById(tableName) != null) {
		var htmlElementObj = document.getElementById(tableName);
		if(htmlElementObj.nodeName != null) {
			if(htmlElementObj.nodeName == "TABLE") {
				while (htmlElementObj.rows.length > 0) 
					htmlElementObj.deleteRow(htmlElementObj.rows.length-1);
			} else {
				htmlElementObj.innerHTML = "";
			}
		} else {
			htmlElementObj.innerHTML = "";
		}
	}
}

function deleteTableRowsFrom(tableName, rowsLen) {
	if(document.getElementById(tableName) != null) {
		var htmlElementObj = document.getElementById(tableName);
		if(htmlElementObj.nodeName != null && htmlElementObj.nodeName == "TABLE") {
			while (htmlElementObj.rows.length > rowsLen)
				htmlElementObj.deleteRow(htmlElementObj.rows.length-1);
		}
	}
}

function deleteRecord() {
	var isValid = true;
	if(!window.confirm("Are you sure, you want to DELETE ?")) {
		isValid = false;
		if(document.formmain.pageSubmitLock != null) {
			document.formmain.pageSubmitLock.value = "unlocked";
		}
	}
	return isValid;
}

function unpostRecord() {
	var isValid = true;
	if(!window.confirm("Are you sure, you want to Unpost ?")) {
		isValid = false;
		if(document.formmain.pageSubmitLock != null) {
			document.formmain.pageSubmitLock.value = "unlocked";
		}
	}
	return isValid;
}

function Trim(input) {
	var lre = /^\s*/;
	var rre = /\s*$/;
	input = input.replace(lre, "");
	input = input.replace(rre, "");
	return input;
}

function getRadioButtonValue(radioObj) {
	var tempVal = "";
	if(radioObj != null) {
		var len = radioObj.length;
		if(len == undefined) {
			if(radioObj.checked)
				tempVal = radioObj.value;
		} else {
			for(var i=0; i<len; i++) {
				if(radioObj[i].checked) {
					tempVal = radioObj[i].value;
					break;
				}
			}
		}
	}
	return tempVal;
}

function setRadioButtonValue(radioObj, value) {
	if(radioObj != null && value != null) {
		var len = radioObj.length;
		if(len == undefined) {
			if(radioObj.value == Trim(value)) {
				radioObj.checked = true;
			}
		} else {
			for(var i=0; i<len; i++) {
				if(radioObj[i].value == Trim(value)) {
					radioObj[i].checked = true;
					break;
				}
			}
		}
	}
}

function getCheckboxValue(obj, seperator) {
	var tempVal = "";
	if(obj != null) {
		var len = obj.length;
		if(len == undefined) {
			if(obj.checked) {
				tempVal = obj.value;
			}
		} else {
			if(seperator == undefined) {
				seperator = ",";
			}
			for(var i=0; i<len; i++) {
				if(obj[i].checked) {
					if(tempVal == "") {
						tempVal = obj[i].value;
					} else {
						tempVal += seperator + obj[i].value;
					}
				}
			}
		}
	}
	return tempVal;
}

function setCheckboxValue(obj, value, seperator) {
	if(obj != null && value != null) {
		var len = obj.length;
		if(len == undefined) {
			if(Trim(obj.value) == Trim(value)) {
				obj.checked = true;
			}
		} else {
			var seperator = seperator == undefined ? "," : seperator;
			var splitArr = value.split(seperator);
			for(var i=0; i<len; i++) {
				for(var j=0; j<splitArr.length; j++) {
					if(Trim(obj[i].value.toLowerCase()) == Trim(splitArr[j].toLowerCase())) {
						obj[i].checked = true;
						break;
					}
				}
			}
		}
	}
}

function getSelectBoxText(obj) {
	var tempVal = "";
	if(obj != null) {
		for(var i=0; i<obj.length; i++) {
			if(obj.options != null)
			if(obj.options[i].selected == true) {
				tempVal = obj.options[i].text;
				break;
			}
		}
	}
	return tempVal;
}

function getSelectBoxValue(obj) {
	var tempVal = "";
	if(obj != null) {
		for(var i=0; i<obj.length; i++) {
			if(obj.options != null)
			if(obj.options[i].selected == true) {
				tempVal = obj.options[i].value;
				break;
			}
		}
	}
	return tempVal;
}

function setSelectBoxText(obj, selectedOption) {
	if(obj != null && selectedOption != null) {
		var isValSelected = false;
		for(var i=0; i<obj.length; i++) {
			if(obj.options[i].text == selectedOption) {
				obj.options[i].selected = true;
				break;
			}
		}
	}
}

function setSelectBoxValue(obj, selectedOption) {
	if(obj != null && selectedOption != null) {
		var isValSelected = false;
		for(var i=0; i<obj.length; i++) {
			if(obj.options[i].value == selectedOption) {
				obj.options[i].selected = true;
				isValSelected = true;
				break;
			}
		}

		if(!isValSelected && selectedOption.length > 0) {
			addOptionToSelectboxAsSelected(obj, selectedOption);
		}
	}
}

function getMultiselectBoxValue(obj, seperator) {
	var tempVal = "";
	if(obj != null && !obj.disabled) {
		if(seperator == undefined)
			seperator = ",";
		for(var i=0; i<obj.length; i++) {
			if(obj.options[i].selected == true) {
				if(tempVal == "") {
					tempVal = obj.options[i].value;
				} else {
					tempVal += seperator + obj.options[i].value;
				}
			}
		}
	}
	return tempVal;
}

function addOptionToSelectboxAsSelected(selectObj, value) {
	var objLen = (selectObj.length + 1);
	selectObj.length = objLen;
	selectObj.options[objLen-1].value = value;
	selectObj.options[objLen-1].text = value;
	selectObj.options[objLen-1].setAttribute("title", value);
	selectObj.options[objLen-1].selected = true;
}

function enableOrDisableID(id, displayStyle) {
	if(document.getElementById(id))
		document.getElementById(id).style.display = displayStyle;
}

function updateIDInnerHTML(id, data) {
	if(document.getElementById(id))
		document.getElementById(id).innerHTML = data;
}

function updateIDValue(id, data) {
	if(document.getElementById(id))
		document.getElementById(id).value = data;
}

function replaceSpecialChars(inputVal) {
	var actualVal = inputVal;
	inputVal = escape(inputVal.replace(/\?/g, "'").replace(/\?/g, "-"));
	inputVal = inputVal.replace(/\+/g, "%2b");

	inputVal = inputVal.replace(/%27/g, "?"); // ?
	//inputVal = inputVal.replace(/%5C/g, "\\"); // ?

	inputVal = inputVal.replace(/%u2013/g, "-"); // en dash
	inputVal = inputVal.replace(/%u2014/g, "-"); // em dash

	inputVal = inputVal.replace(/%u2018/g, "'"); // Left single quote
	inputVal = inputVal.replace(/%u2019/g, "'"); // Right single quote

	inputVal = inputVal.replace(/%u201C/g, '"'); // Left double quote
	inputVal = inputVal.replace(/%u201D/g, '"'); // Right double quote
	inputVal = inputVal.replace(/%u2265/g,">=");
	inputVal = inputVal.replace(/%u2264/g,"<=");
	if(inputVal.length > 0)
		console.log("replaceSpecialChars :: "+inputVal);
	return inputVal;
}

function checkOrUncheckValues(obj1, obj2) {
	if(obj1 != null) {
		if(obj1.checked) {
			checkAllValues(obj2);
		} else {
			unCheckAllValues(obj2);
		}
	}
}

function checkAllValues(obj) {
	if(obj != null) {
		var len = obj.length;
		if(len == undefined) {
			if(!obj.disabled)
				obj.checked = true;
		} else {
			for(var i=0; i<len; i++) {
				if(!obj[i].disabled)
					obj[i].checked = true;
			}
		}
	}
}

function unCheckAllValues(obj) {
	if(obj != null) {
		var len = obj.length;
		if(len == undefined) {
			if(!obj.disabled)
				obj.checked = false;
		} else {
			for(var i=0; i<len; i++) {
				if(!obj[i].disabled)
					obj[i].checked = false;
			}
		}
	}
}

function IsNumeric(strString) {
	var strValidChars = "0123456789";
	var strChar;
	var blnResult = true;
	if (strString.length == 0)
		return false;
	for (i = 0; i < strString.length && blnResult == true; i++) {
		strChar = strString.charAt(i);
		if (strValidChars.indexOf(strChar) == -1) {
			blnResult = false;
			break;
		}
	}
	return blnResult;
}

function validateNumericValues(obj) {
	var returnVal = true;
	obj.value = Trim(obj.value);
	if ((obj.value).length > 0 && !IsNumeric(obj.value)) {
		alert("Only numbers are allowed");
		obj.value = "";
		obj.focus();
		returnVal = false;
	}
	return returnVal;
}

function validateEmailAdd(thisObj) {
	thisObj.value = Trim(thisObj.value);
	var emailStr = thisObj.value;
	if(emailStr.length > 0) {
		var emailPat = /^(.+)@(.+)$/
		var specialChars = "\\(\\)<>@,;:\\\\\\\"\\.\\[\\]"
		var validChars = "\[^\\s" + specialChars + "\]"
		var quotedUser = "(\"[^\"]*\")"
		var ipDomainPat = /^\[(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})\]$/
		var atom = validChars + '+';
		var word = "(" + atom + "|" + quotedUser + ")";
		var userPat = new RegExp("^" + word + "(\\." + word + ")*$");
		var domainPat = new RegExp("^" + atom + "(\\." + atom +")*$");

		var matchArray=emailStr.match(emailPat)
		if (matchArray == null) {
			alert("Email address seems incorrect (check @ and .'s)");
			thisObj.value = "";
			thisObj.focus();
			return false;
		}

		var user = matchArray[1];
		var domain = matchArray[2];
		if (user.match(userPat) == null) {
			alert("The username doesn't seem to be valid.");
			thisObj.value = "";
			thisObj.focus();
			return false;
		}

		var IPArray = domain.match(ipDomainPat);
		if (IPArray != null) {
			for (var i=1; i<=4; i++) {
				if (IPArray[i] > 255) {
					alert("Destination IP address is invalid!");
					thisObj.value = "";
					thisObj.focus();
					return false;
				}
		    }
		    return true;
		}

		var domainArray = domain.match(domainPat);
		if (domainArray == null) {
			alert("The domain name doesn't seem to be valid.");
			thisObj.value = "";
			thisObj.focus();
			return false;
		}

		var atomPat = new RegExp(atom,"g");
		var domArr = domain.match(atomPat);
		var len = domArr.length;
		if (domArr[domArr.length-1].length < 2 || domArr[domArr.length-1].length > 4) {
			alert("The address must end in a three-letter domain, or two letter country.");
			thisObj.value = "";
			thisObj.focus();
			return false;
		}

		if (len < 2) {
			var errStr = "This address is missing a hostname!";
			alert(errStr);
			thisObj.value = "";
			thisObj.focus();
			return false;
		}
		return true;
	}
	return true;
}