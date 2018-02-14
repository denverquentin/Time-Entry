/**
 * BatchGenerateWeeklyTimesheet implements the Database.Batchable interface and is used to 
 * create Weekly_Time_Sheet__c records for Users for the upcoming week or for a specified
 * Week Starting value. Users get a Weekly_Time_Sheet__c record if they're User record is
 * Active, if the have a Project_User_Assignment__c record that is Active and if the Project__c
 * for the Project_User_Assignment__c record is record.
 */
global with sharing class BatchGenerateWeeklyTimesheet implements Database.Batchable<SObject> {
	private Date weekStarting;

	global BatchGenerateWeeklyTimesheet() { }


	/**
	 * Constructor for setting a week starting Date in case they're not standard
	 * or in case past or future timesheet records need to be generated.
	 * 
	 * @param  Date weekStarting
	 */
	global BatchGenerateWeeklyTimesheet(Date weekStarting) {
		this.weekStarting = weekStarting;
	}


	/**
	* Get all Active Users that are part of Active Projects by querying Project_User_Assignment__c
	*/
	global Database.QueryLocator start(Database.BatchableContext bc) {
		String query = 'select Id, User__c, User__r.Name from Project_User_Assignment__c ';
		query += 'where Is_Active__c = true and User__r.IsActive = true and Project__r.Is_Active__c = true';
		Utils.log('query = ' + query);
		return Database.getQueryLocator(query);
	}


	/**
	 * Get a set of unique Users Ids. Then create a new Weekly_Time_Sheet__c record for each
	 * with the User Id set as the OwnerId. Also set the Week_Starting__c, Week_Ending__c,
	 * and Name fields with the correct date values for the week.
	*/
	global void execute(Database.BatchableContext bc, List<SObject> scope) {
		Set<User> uniqueUsers = new Set<User>();
		for (SObject s : scope) {
			User u = (User)s.getSObject('User__r');
			uniqueUsers.add(u);
		}
		uniqueUsers.remove(null);
		Utils.log('uniqueUsers = ' + uniqueUsers);

		if (weekStarting == null) {
			weekStarting = Date.today().addDays(1); // scheduled to run on Sunday so add 1 day to start on Monday
		}
		Date weekEnding = weekStarting.addDays(6); // add 6 days to weekStarting so the week is 7 days
		Utils.log('weekStarting = ' + weekStarting);
		Utils.log('weekEnding = ' + weekEnding);

		List<Weekly_Time_Sheet__c> timesheetsToInsert = new List<Weekly_Time_Sheet__c>();
		for (User user : uniqueUsers) {
			Weekly_Time_Sheet__c wts = new Weekly_Time_Sheet__c();
			wts.OwnerId = user.Id;
			wts.Name = buildTimesheetName(weekStarting, weekEnding, user);
			wts.Week_Starting__c = weekStarting;
			wts.Week_Ending__c = weekEnding;
			timesheetsToInsert.add(wts);
		}

		Utils.log('timesheetsToInsert = ' + timesheetsToInsert);
		if (timesheetsToInsert.size() > 0) {
			insert timesheetsToInsert;
		}
	}


	global void finish(Database.BatchableContext bc) {
		// can do something when done
	}


	/**
	 * Build the Name for the Weekly Time Sheet record. Name is a combination of 
	 * Week Starting, Week Ending and the User's Full Name
	 * 
	 * @param  Date weekStarting
	 * @param  Date weekEnding
	 * @return String
	*/
	global static String buildTimesheetName(Date weekStarting, Date weekEnding, User user) {
		String name = Utils.convertDateForDynamicQuery(weekStarting);
		name += ' to ' + Utils.convertDateForDynamicQuery(weekEnding);
		name += ' for ' + user.Name;
		return name;
	}
}