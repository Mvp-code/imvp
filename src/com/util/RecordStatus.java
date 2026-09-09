package com.util;

public interface RecordStatus {

	int ACTIVE = 0;

	int DELETE = 1;

	int POST = 2;

	int COMPLETED = 3;

	int INACTIVE = 4;

	int LOCKED = 5;

	int UNLOCKED = 6;

	int UNPOST = 7;

	int TERMINATED = 8;

	int QUIT = 9;

	int APPROVED = 10;

	int REJECTED = 11;

	String[] RecordStatus = new String[] { "Active", "Delete", "Posted",
			"Completed", "Inactive", "Locked", "Unlocked", "Unpost",
			"Terminated", "Quit", "Approved", "Rejected" };
}
