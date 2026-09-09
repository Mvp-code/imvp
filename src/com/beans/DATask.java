package com.beans;

import java.util.ArrayList;
import java.util.List;

public class DATask extends MainBean {

	private String taskID = "";
	private String employeeID = "";
	private String employeeName = "";
	private String taskTitle = "";
	private String taskDesc = "";
	private String topic = "";
	private String priority = "";
	private String assignedTo = "";
	private String dueDate = "";
	private String taskStatus = "";

	public DATask() {
		setDisplayName("DA Task");
		setController("DATask");
	}

	@Override
	public List<String> getBeanAttributes() {

		List<String> beanAttributes = new ArrayList<String>();
		beanAttributes.add("taskID");
		beanAttributes.add("entityID");
		beanAttributes.add("employeeID");
		beanAttributes.add("taskTitle");
		beanAttributes.add("taskDesc");
		beanAttributes.add("topic");
		beanAttributes.add("priority");
		beanAttributes.add("assignedTo");
		beanAttributes.add("dueDate");
		beanAttributes.add("taskStatus");

		beanAttributes.add("createUser");
		beanAttributes.add("createDate");
		beanAttributes.add("updateUser");
		beanAttributes.add("updateDate");
		beanAttributes.add("status");
		beanAttributes.add("numOfRows");
		return beanAttributes;
	}

	public String getTaskID() { return taskID; }
	public void setTaskID(String taskID) { this.taskID = taskID; }

	public String getEmployeeID() { return employeeID; }
	public void setEmployeeID(String employeeID) { this.employeeID = employeeID; }

	public String getEmployeeName() { return employeeName; }
	public void setEmployeeName(String employeeName) { this.employeeName = employeeName; }

	public String getTaskTitle() { return taskTitle; }
	public void setTaskTitle(String taskTitle) { this.taskTitle = taskTitle; }

	public String getTaskDesc() { return taskDesc; }
	public void setTaskDesc(String taskDesc) { this.taskDesc = taskDesc; }

	public String getTopic() { return topic; }
	public void setTopic(String topic) { this.topic = topic; }

	public String getPriority() { return priority; }
	public void setPriority(String priority) { this.priority = priority; }

	public String getAssignedTo() { return assignedTo; }
	public void setAssignedTo(String assignedTo) { this.assignedTo = assignedTo; }

	public String getDueDate() { return dueDate; }
	public void setDueDate(String dueDate) { this.dueDate = dueDate; }

	public String getTaskStatus() { return taskStatus; }
	public void setTaskStatus(String taskStatus) { this.taskStatus = taskStatus; }
}
