/**
 * All common methods for the Weekly Time Sheet object go here.
 */
public with sharing class WeeklyTimeSheetsService {

	/**
	 * Get a List of Weekly Timesheets for a set of Ids
	 * 
	 * @param  Set<String> ids
	 * @return List<Weekly_Time_Sheet__c>
	 */
	public static List<Weekly_Time_Sheet__c> getWeeklyTimesheetsByIds(Set<String> ids) {
		List<Weekly_Time_Sheet__c> weeklyTimesheets = [select Id, Name, Status__c, Week_Starting__c, Week_Ending__c,
			Total_Billable_Amount__c, Total_Hours_for_Week__c, OwnerId
			from Weekly_Time_Sheet__c
			where Id in :ids];
		return weeklyTimesheets;
	}


	/**
	 * Get the Weekly Timesheet Id based on the current user and the Date parameter
	 * 
	 * @param  Date dt
	 * @return Weekly_Time_Sheet__c
	 */
	public static Weekly_Time_Sheet__c getWeeklyTimeSheetForCurrentUser(Date dt) {
		List<Weekly_Time_Sheet__c> weeklyTimesheets = [select Id, Name, Status__c, Week_Starting__c, Week_Ending__c,
			Total_Billable_Amount__c, Total_Hours_for_Week__c, OwnerId
			from Weekly_Time_Sheet__c
			where OwnerId = :UserInfo.getUserId() and Week_Starting__c <= :dt and Week_Ending__c >= :dt];

		// do validations
		if (weeklyTimesheets.size() == 0) {
			throw new TimeEntryException('Unable to find a Weekly Time Sheet for Date = ' + dt);
		} else if (weeklyTimesheets.size() > 1) {
			throw new TimeEntryException('More than one Weekly Time Sheet found for Date = ' + dt);
		}
		return weeklyTimesheets[0];
	}
}