/**
 * All common methods for the Time Entry object go here.
 */
public with sharing class TimeEntriesService {

	/**
	 * Get a List of Time Entries for a set of Ids
	 * 
	 * @param  Set<String> ids
	 * @return List<Time_Entry__c>
	 */
	public static List<Time_Entry__c> getTimeEntriesByIds(Set<String> ids) {
		List<Time_Entry__c> timeEntries = [select Id, Hours__c, Client__c, Project__c, Project_Id__c, User__c, User_Id__c,
			Project_Task__c, Is_Closed__c, Is_Locked__c, Is_Running__c, Locked_Reason__c, Spent_Date__c, Notes__c,
			Timer_Started_At__c, Billable_Amount__c
			from Time_Entry__c where Id in :ids order by Spent_Date__c, Client__c, Project__c];
		return timeEntries;
	}


	/**
	 * Get a List of Time Entries for a Weekly Time Sheet Id
	 * 
	 * @param  String id
	 * @return List<Time_Entry__c>
	 */
	public static List<Time_Entry__c> getTimeEntriesForWeeklyTimeSheetId(String id) {
		List<Time_Entry__c> timeEntries = [select Id, Hours__c, Client__c, Project__c, Project_Id__c, User__c, User_Id__c,
			Project_Task__c, Is_Closed__c, Is_Locked__c, Is_Running__c, Locked_Reason__c, Spent_Date__c, Notes__c,
			Timer_Started_At__c, Billable_Amount__c
			from Time_Entry__c where Weekly_Time_Sheet__c = :id order by Spent_Date__c, Client__c, Project__c];
		return timeEntries;
	}
}