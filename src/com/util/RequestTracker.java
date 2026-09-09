package com.util;

import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

public class RequestTracker {

	private static final Set<String> REQUEST_IDS = ConcurrentHashMap
			.newKeySet();

	public static boolean isDuplicate(String requestId) {
		return !REQUEST_IDS.add(requestId); // false if already exists

	}
}