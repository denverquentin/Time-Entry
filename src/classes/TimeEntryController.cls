/**
 * Controller Class for the Time Entry lightning component.
 */
global with sharing class TimeEntryController {

	/**
	 * Data Class that's returned to the Time Entry lightning component.
	 */
	global class TimeEntryData {
		@AuraEnabled
		global TimeEntry timeEntry {get;set;}
		@AuraEnabled
		global List<Map<String,String>> activeProjectUserAssignments {get;set;}
		@AuraEnabled
		global List<Map<String,String>> activeProjectTaskAssignments {get;set;}
	}


	/**
	 * Method to that Returns a TimeEntryData object that's used by the Time Entry lightning component.
	 * @param  String recordId
	 * @return TimeEntryData
	 */
	@AuraEnabled
	global static TimeEntryData getTimeEntryData(String recordId) {
		TimeEntryData ted = new TimeEntryData();
		ted.activeProjectUserAssignments = new List<Map<String,String>>();
		ted.activeProjectTaskAssignments = new List<Map<String,String>>();
		try {
			String projectId; // will be set below if the User creates a Time Entry from a Project record
			Utils.log('recordId = ' + recordId);
			if (String.isNotBlank(recordId)) {
				// let's determine the object type - can be Time_Entry__c, Project__c or Weekly_Time_Sheet__c
				Schema.SObjectType sobjectType = Id.valueOf(recordId).getSObjectType();
				Utils.log('sobjectType = ' + sobjectType);

				if (sobjectType == Schema.Time_Entry__c.SObjectType) {
					// user wants to edit an existing Time Entry
					List<Time_Entry__c> timeEntries = TimeEntriesService.getTimeEntriesByIds(new Set<String> {recordId});

					if (timeEntries.size() != 1) {
						throw new TimeEntryException('Unable to find the Time Entry record.');
					}

					// do validations
					if (timeEntries[0].User_Id__c != UserInfo.getUserId()) {
						throw new TimeEntryException('You do not have access to edit the Time Entry for ' + timeEntries[0].User__c);
					}

					// todo: mark time entries as closed once approved
					if (timeEntries[0].Is_Closed__c) {
						throw new TimeEntryException('This Time Entry is Closed.');
					}

					// todo: mark time entries as locked once submitted for approval
					if (timeEntries[0].Is_Locked__c) {
						throw new TimeEntryException('This Time Entry is Locked.');
					}

					ted.timeEntry = new TimeEntry();
					ted.timeEntry.id = timeEntries[0].Id;
					ted.timeEntry.entryDate = timeEntries[0].Spent_Date__c;
					ted.timeEntry.clientAndProjectName = timeEntries[0].Client__c + ' - ' + timeEntries[0].Project__c;
					ted.timeEntry.projectTaskName = timeEntries[0].Project_Task__c;
					ted.timeEntry.projectUserAssignmentId = timeEntries[0].Project_User_Assignment__c;
					ted.timeEntry.projectTaskAssignmentId = timeEntries[0].Project_Task_Assignment__c;
					ted.timeEntry.notes = timeEntries[0].Notes__c;
					ted.timeEntry.hours = timeEntries[0].Hours__c;
					ted.timeEntry.isRunning = timeEntries[0].Is_Running__c;
					ted.timeEntry.timerStartedAt = timeEntries[0].Timer_Started_At__c;
					return ted;
				} else if (sobjectType == Schema.Weekly_Time_Sheet__c.SObjectType) {
					/* clicked the New button from a Weekly_Time_Sheet__c
					not going to pre-pop anything here - the save logic gets the weekly time sheet based on
					the Entry Date and validates that the timesheet can still be edited
					*/
				} else if (sobjectType == Schema.Project__c.SObjectType) {
					// clicked the New button from a Project__c
					projectId = recordId;
				} 
			}

			// the user wants to create a new Time Entry
			ted.timeEntry = new TimeEntry();
			ted.timeEntry.entryDate = Date.today();
			ted.timeEntry.isRunning = false;

			// project user assignment logic
			List<Project_User_Assignment__c> activeProjectUserAssignments = getActiveProjectUserAssignments();
			if (activeProjectUserAssignments.size() == 0) {
				throw new TimeEntryException('You have no Active Projects or Project User Assignments.');
			}

			// need this next map so we can set the ProjectUserAssignmentId on the activeProjectTaskAssignments below
			// this allow us to build the Task list dynmically based on the selected ProjectUserAssignmentId
			Map<Id,Id> projectIdAndProjectUserAssignmentIds = new Map<Id,Id>();
			for (Project_User_Assignment__c pua : activeProjectUserAssignments) {
				// logic to set the default value
				if (String.isNotBlank(projectId) && projectId == pua.Project__c) {
					ted.timeEntry.projectUserAssignmentId = pua.Id;
				}

				Map<String,String> keyVals = new Map<String,String>();
				keyVals.put('label', pua.Project__r.Client__r.Name + ' - ' + pua.Project__r.Name);
				keyVals.put('value', pua.Id);
				ted.activeProjectUserAssignments.add(keyVals);
				projectIdAndProjectUserAssignmentIds.put(pua.Project__c, pua.Id);
			}

			// project task assignment logic
			List<Project_Task_Assignment__c> activeTasksByProjectId = getActiveProjectTaskAssignments(projectIdAndProjectUserAssignmentIds.keySet());

			if (activeTasksByProjectId.size() == 0) {
				throw new TimeEntryException('You have no Active Project Task Assignments.');
			}

			for (Project_Task_Assignment__c pta : activeTasksByProjectId) {
				Map<String,String> keyVals = new Map<String,String>();
				keyVals.put('projectUserAssignment', projectIdAndProjectUserAssignmentIds.get(pta.Project__c));
				keyVals.put('label', pta.Project_Task__r.Name);
				keyVals.put('value', pta.Id);
				ted.activeProjectTaskAssignments.add(keyVals);
			}
		} catch (Exception e) {
			Utils.errorMsgLightning(e);
		}
		return ted;
	}


	/**
	 * Method to upsert a Time_Entry__c record base on data set on the Time Entry lightning component.
	 * The timer start and stop logic is in the method. Had to pass in the TimeEntry object as a JSON
	 * string do to this SF bug - https://success.salesforce.com/issues_view?id=a1p3A000000EAbLQAW
	 * 
	 * @param  String timeEntryString
	 * @return Map<String,String>
	 */
	@AuraEnabled
	global static Map<String,String> upsertTimeEntry(String timeEntryString) {
		Map<String,String> returnMap = new Map<String,String>();
		Utils.log('timeEntryString = ' + timeEntryString);
		Time_Entry__c te = new Time_Entry__c();
		try {
			TimeEntry timeEntryObj = (TimeEntry)JSON.deserializeStrict(timeEntryString, TimeEntry.class);

			if (String.isNotBlank(timeEntryObj.id)) { // update
				returnMap.put('title', 'Updated the Time Entry');
				te.Id = timeEntryObj.id;

				if (timeEntryObj.isRunning && timeEntryObj.timerStartedAt != null) { // stop it and update Hours
					te.Is_Running__c = false;
					te.Timer_Started_At__c = null;
					if (timeEntryObj.hours == null) {
						timeEntryObj.hours = 0;
					}
					Utils.log('current hours val = ' + timeEntryObj.hours);
					Utils.log('current timerStartedAt val = ' + timeEntryObj.timerStartedAt);

					Utils.log('timerStartedAt.getTime() = ' + timeEntryObj.timerStartedAt.getTime());

					Double millisecondsBetween = Datetime.now().getTime() - timeEntryObj.timerStartedAt.getTime();
					Utils.log('millisecondsBetween = ' + millisecondsBetween);

					Double newHours = millisecondsBetween / 1000 / 3600;
					Utils.log('newHours = ' + newHours);

					te.Hours__c = timeEntryObj.hours + newHours;
					Utils.log('updated hours val = ' + te.Hours__c);
					returnMap.put('message', 'The Timer was stopped.');
				} else { // start it
					returnMap.put('message', 'The Timer was started.');

					te.Is_Running__c = true;
					te.Timer_Started_At__c = Datetime.now();
				}
			} else { // only need to set these on insert
				returnMap.put('title', 'Created the Time Entry');
				returnMap.put('message', 'The Timer was started.');

				te.Spent_Date__c = timeEntryObj.entryDate;
				te.Project_User_Assignment__c = timeEntryObj.projectUserAssignmentId;
				te.Project_Task_Assignment__c = timeEntryObj.projectTaskAssignmentId;
				Weekly_Time_Sheet__c wts = WeeklyTimeSheetsService.getWeeklyTimeSheetForCurrentUser(timeEntryObj.entryDate);
				if (wts.Status__c == Constants.STATUS_SUBMITTED || wts.Status__c == Constants.STATUS_APPROVED) {
					throw new TimeEntryException('The Weekly Time Sheet has already been ' + wts.Status__c + '. You can no longer add a Time Entry to it.');
				}
				te.Weekly_Time_Sheet__c = wts.Id;

				Project_User_Assignment__c pua = getProjectUserAssignmentById(timeEntryObj.projectUserAssignmentId);
				// figure out Bill Rate & Billable based on Project settings
				if (pua.Project__r.Bill_By__c == Constants.BILL_BY_PROJECT) {
					te.Billable_Rate__c = pua.Project__r.Project_Hourly_Rate__c; // get from the Project
					te.Billable__c = pua.Project__r.Is_Billable__c;
				} else if (pua.Project__r.Bill_By__c == Constants.BILL_BY_PEOPLE) {
					te.Billable_Rate__c = pua.Hourly_Rate__c; // get from the Project User Assignment
					te.Billable__c = pua.Project__r.Is_Billable__c;
				} else if (pua.Project__r.Bill_By__c == Constants.BILL_BY_TASKS) {
					Project_Task_Assignment__c pta = getProjectTaskAssignmentById(timeEntryObj.projectTaskAssignmentId);
					te.Billable_Rate__c = pta.Hourly_Rate__c;// get from the Project Task Assignment
					te.Billable__c = pta.Billable__c;
				}
				// only choice is to start it when it's new
				te.Is_Running__c = true;
				te.Timer_Started_At__c = Datetime.now();
			}
			// always set the note
			te.Notes__c = timeEntryObj.notes;
			upsert te;

			returnMap.put('id', te.Id);
		} catch (Exception e) {
			Utils.errorMsgLightning(e);
		}
		return returnMap;
	}


	/**
	 * Get all Active Project_User_Assignment__c for Active Projects for the current user
	 * 
	 * @return List<Project_User_Assignment__c>
	 */
	private static List<Project_User_Assignment__c> getActiveProjectUserAssignments() {
		List<Project_User_Assignment__c> pua = [select Id, Project__c, Project__r.Name, Project__r.Client__r.Name
			from Project_User_Assignment__c
			where User__c = :UserInfo.getUserId() and Is_Active__c = true and Project__r.Is_Active__c = true
			order by Project__r.Client__r.Name, Project__r.Name];

		return pua;
	}


	/**
	 * Get all Active Project_Task_Assignment__c for the projectIds passed in.
	 * 
	 * @param  Set<Id> projectIds
	 * @return List<Project_Task_Assignment__c>
	 */
	private static List<Project_Task_Assignment__c> getActiveProjectTaskAssignments(Set<Id> projectIds) {
		List<Project_Task_Assignment__c> pta = [select Id, Project__c, Project_Task__c, Project_Task__r.Name
			from Project_Task_Assignment__c
			where Project__c in :projectIds and Is_Active__c = true
			order by Project_Task__r.Name]; // could also filter by Project_Task__r.Is_Active__c if needed

		return pta;
	}


	/**
	 * Get a Project_User_Assignment__c record by Id
	 * 
	 * @param  String projectUserAssignmentId
	 * @return Project_User_Assignment__c
	 */
	@TestVisible
	private static Project_User_Assignment__c getProjectUserAssignmentById(String projectUserAssignmentId) {
		return [select Project__r.Bill_By__c, Project__r.Is_Billable__c,
			Project__r.Project_Hourly_Rate__c, Hourly_Rate__c
			from Project_User_Assignment__c
			where Id = :projectUserAssignmentId];
	}


	/**
	 * Get a Project_Task_Assignment__c record by Id
	 * 
	 * @param  String projectTaskAssignmentId
	 * @return Project_Task_Assignment__c
	 */
	@TestVisible
	private static Project_Task_Assignment__c getProjectTaskAssignmentById(String projectTaskAssignmentId) {
		return [select Billable__c, Hourly_Rate__c
			from Project_Task_Assignment__c
			where Id = :projectTaskAssignmentId];
	}
}