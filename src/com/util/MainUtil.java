package com.util;

import java.util.HashMap;
import java.util.Map;

public class MainUtil {

	public Map<String, String> getDAStatus() {

		Map<String, String> _hMap = new HashMap<String, String>();
		_hMap.put("Confirmed", "Confirmed");
		_hMap.put("Not Confirmed", "Not Confirmed");
		_hMap.put("Available", "Available");
		_hMap.put("Confirmed - No block", "Confirmed - No block");
		_hMap.put("Not Confirmed - No block", "Not Confirmed - No block");
		_hMap.put("Available - No block", "Available - No block");
		_hMap.put("Sent", "Sent");
		_hMap.put("Reply", "Reply");
		_hMap.put("Review", "Review");

		return _hMap;
	}

	public Map<String, String> getStation() {

		Map<String, String> _hMap = new HashMap<String, String>();
		_hMap.put("DNK7", "DNK7");

		return _hMap;
	}

	public Map<String, String> getParking() {

		Map<String, String> _hMap = new HashMap<String, String>();
		_hMap.put("1", "Inside");
		_hMap.put("2", "Outside");
		_hMap.put("3", "Backside");

		return _hMap;
	}

	public Map<String, String> getOpertionalStatus() {

		Map<String, String> _hMap = new HashMap<String, String>();
		_hMap.put("0", "Operational");
		_hMap.put("1", "Grounded");
		_hMap.put("2", "Delivered (Not Active)");
		_hMap.put("3", "Offboarded (With MVP)");
		_hMap.put("4", "Dealer");
		_hMap.put("5", "Need Return (With Repair Shop)");

		return _hMap;
	}

	public Map<String, String> getRole() {

		Map<String, String> _hMap = new HashMap<String, String>();
		_hMap.put("1", "Dispatcher");
		_hMap.put("2", "Manager");
		_hMap.put("3", "Management");
		_hMap.put("4", "DA Associate");

		return _hMap;
	}

	public Map<String, String> getRecordStatus(String ids) {

		Map<String, String> _hMap = new HashMap<String, String>();
		String splitArray[] = ids.split(",");
		for (int i = 0; i < splitArray.length; i++) {
			splitArray[i] = splitArray[i].trim();
			if (splitArray[i].length() > 0) {
				_hMap.put(splitArray[i], RecordStatus.RecordStatus[Integer
						.parseInt(splitArray[i])]);
			}
		}

		return _hMap;
	}

	public String getServiceTier(String serviceTier) {
		return getServiceTier(serviceTier, true);
	}

	public String getServiceTier(String serviceTier, boolean boolVal) {

		if (serviceTier.contains("Custom Delivery Van 12ft"))
			return "CUSTOM_DELIVERY_VAN_TWELVE_FT";
		else if (serviceTier.contains("CUSTOM_DELIVERY_VAN_TWELVE_FT"))
			return "CUSTOM_DELIVERY_VAN_TWELVE_FT";

		else if (serviceTier.contains("Custom Delivery Van 14ft"))
			return "CUSTOM_DELIVERY_VAN_FOURTEEN_FT";
		else if (serviceTier.contains("CUSTOM_DELIVERY_VAN_14_FT"))
			return "CUSTOM_DELIVERY_VAN_FOURTEEN_FT";

		else if (serviceTier.contains("Custom Delivery Van 16ft"))
			return "CUSTOM_DELIVERY_VAN_SIXTEEN_FT";
		else if (serviceTier.contains("CUSTOM_DELIVERY_VAN_16_FT"))
			return "CUSTOM_DELIVERY_VAN_SIXTEEN_FT";

		else if (serviceTier.contains("Small Large Van"))
			return "SMALL_LARGE_CARGO_VAN";
		else if (serviceTier.contains("SMALL_LARGE_CARGO_VAN"))
			return "SMALL_LARGE_CARGO_VAN";

		else if (serviceTier.contains("Extra Large Van"))
			return "EXTRA_LARGE_CARGO_VAN";
		else if (serviceTier.contains("EXTRA_LARGE_CARGO_VAN"))
			return "EXTRA_LARGE_CARGO_VAN";

		else if (serviceTier.contains("Large Van"))
			return "LARGE_CARGO_VAN";
		else if (serviceTier.contains("LARGE_CARGO_VAN"))
			return "LARGE_CARGO_VAN";

		else if (boolVal)
			return serviceTier;

		else
			return "";
	}

	public Map<String, String> getServiceTier() {

		Map<String, String> _hMap = new HashMap<String, String>();
		// _hMap.put("CUSTOM_DELIVERY_VAN_14_FT", "CUSTOM_DELIVERY_VAN_14_FT");
		// _hMap.put("CUSTOM_DELIVERY_VAN_16_FT", "CUSTOM_DELIVERY_VAN_16_FT");
		_hMap.put("CUSTOM_DELIVERY_VAN_TWELVE_FT",
				"CUSTOM_DELIVERY_VAN_TWELVE_FT");
		_hMap.put("CUSTOM_DELIVERY_VAN_FOURTEEN_FT",
				"CUSTOM_DELIVERY_VAN_FOURTEEN_FT");
		_hMap.put("CUSTOM_DELIVERY_VAN_SIXTEEN_FT",
				"CUSTOM_DELIVERY_VAN_SIXTEEN_FT");
		_hMap.put("EXTRA_LARGE_CARGO_VAN", "EXTRA_LARGE_CARGO_VAN");
		// _hMap.put("LARGE_CARGO_VAN", "LARGE_CARGO_VAN ");
		// _hMap.put("SMALL_CARGO_VAN", "SMALL_CARGO_VAN");
		// _hMap.put("SMALL_LARGE_CARGO_VAN", "SMALL_LARGE_CARGO_VAN");
		// _hMap.put("STANDARD_CARGO_VAN", "STANDARD_CARGO_VAN");

		return _hMap;
	}

	public String getValue(Map<String, String> _hMap, String key) {

		String value = _hMap.get(key) == null ? "" : _hMap.get(key);
		return value;
	}

	public String[][] getDataArray(Map<String, String> _hMap) {

		String[][] dataArray = _hMap.entrySet().stream()
				.sorted(Map.Entry.comparingByValue()) // Sort by value
				.map(e -> new String[] { e.getKey(), e.getValue() })
				.toArray(String[][]::new);

		return dataArray;
	}

	public String[] getDataArray(String options) {

		String[] dataArray = null;
		if (options.length() > 0)
			dataArray = options.split("#");

		return dataArray;
	}

	public String getAll(Map<String, String> _hMap) {

		String ids = "";
		String[][] dataArray = _hMap.entrySet().stream()
				.sorted(Map.Entry.comparingByValue()) // Sort by value
				.map(e -> new String[] { e.getKey(), e.getValue() })
				.toArray(String[][]::new);

		if (dataArray != null) {
			for (int i = 0; i < dataArray.length; i++) {
				String tempID = dataArray[i][0];
				if (ids.length() > 0)
					ids += ",";
				ids += tempID;
			}
		}

		return ids;
	}
}
