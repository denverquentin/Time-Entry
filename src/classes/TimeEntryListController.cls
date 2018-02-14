/**
 * Controller Class for the Time Entry List lightning component.
 */
global with sharing class TimeEntryListController {

	/**
	 * Data Class that's returned to the Time Entry lightning component.
	 */
	global class TimeEntryListData {
		@AuraEnabled
		global List<TimeEntry> timeEntries {get;set;}
		@AuraEnabled
		global String userName {get;set;}
		@AuraEnabled
		global Decimal totalBillableAmount {get;set;}
		@AuraEnabled
		global Decimal totalHoursForWeek {get;set;}
		@AuraEnabled
		global Boolean canAddTimeEntry {get;set;}
		@AuraEnabled
		global Boolean canSubmitTimeSheet {get;set;}
		@AuraEnabled
		global Boolean canApproveTimeSheet {get;set;}
		@AuraEnabled
		global String sobjectType {get;set;}
	}


	@AuraEnabled
	global static TimeEntryListData getTimeEntryData(String recordId) {
		TimeEntryListData teld = new TimeEntryListData();
		teld.canSubmitTimeSheet = false;
		teld.canApproveTimeSheet = false;
		teld.canAddTimeEntry = false;
		teld.userName = UserInfo.getName();

		teld.timeEntries = new List<TimeEntry>();
		try {
			Weekly_Time_Sheet__c wts;
			Schema.SObjectType sobjectType = Id.valueOf(recordId).getSObjectType();
			Utils.log('sobjectType = ' + sobjectType);

			if (sobjectType == Schema.Weekly_Time_Sheet__c.SObjectType) {
				teld.sobjectType = 'Weekly_Time_Sheet__c';
				List<Weekly_Time_Sheet__c> timesheets = WeeklyTimeSheetsService.getWeeklyTimesheetsByIds(new Set<String> {recordId});
				if (timesheets.size() != 1) {
					throw new TimeEntryException('Unable to find the Weekly Time Sheet for Id = ' + recordId);
				}
				wts = timesheets[0];
				teld.totalBillableAmount = wts.Total_Billable_Amount__c;
				teld.totalHoursForWeek = wts.Total_Hours_for_Week__c;

				if (wts.OwnerId == UserInfo.getUserId() &&
					(String.isBlank(wts.Status__c) || wts.Status__c == Constants.STATUS_IN_PROGRESS)) {
					teld.canSubmitTimeSheet = true;
					teld.canAddTimeEntry = true;
				}

				// show approve button if the timesheet is submitted and if the current user can approve timesheets
				if (wts.Status__c == Constants.STATUS_SUBMITTED && Utils.canUserApproveTimesheets(UserInfo.getUserId())) {
					teld.canApproveTimeSheet = true;
				}

			} else if (sobjectType == Schema.Project__c.SObjectType) {
				teld.sobjectType = 'Project__c';

				wts = WeeklyTimeSheetsService.getWeeklyTimeSheetForCurrentUser(Date.today());

				// can only add entries from the Project - can't submit or approve
				if (String.isBlank(wts.Status__c) || wts.Status__c == Constants.STATUS_IN_PROGRESS) {
					teld.canAddTimeEntry = true;
				}
			}

			// get the time entries for the weekly time sheet id
			List<Time_Entry__c> timeEntries = TimeEntriesService.getTimeEntriesForWeeklyTimeSheetId(wts.Id);

			for (Time_Entry__c te : timeEntries) {
				TimeEntry teObj = new TimeEntry();
				teObj.id = te.Id;
				teObj.clientAndProjectName = te.Client__c + ' - ' + te.Project__c;
				teObj.projectId = te.Project_Id__c;
				teObj.projectTaskName = te.Project_Task__c;
				teObj.entryDate = te.Spent_Date__c;
				teObj.notes = te.Notes__c;
				teObj.hours = te.Hours__c;
				teObj.billableAmount = te.Billable_Amount__c;
				teObj.isRunning = te.Is_Running__c;
				teObj.isLocked = te.Is_Locked__c;
				teObj.isClosed = te.Is_Closed__c;
				teObj.timerStartedAt = te.Timer_Started_At__c;
				teld.timeEntries.add(teObj);
			}
		} catch (Exception e) {
			Utils.errorMsgLightning(e);
		}
		return teld;
	}


	@AuraEnabled
	global static TimeEntryListData toggleTimerForTimeEntry(String recordId, String timeEntryId) {
		try {
			List<Time_Entry__c> timeEntries = TimeEntriesService.getTimeEntriesByIds(new Set<String> {timeEntryId});
			if (timeEntries.size() == 0) {
				throw new TimeEntryException('Unable to find the Time Entry - maybe it was deleted.');
			}
			Time_Entry__c te = timeEntries[0];

			// todo: refactor this code - dupe of code in TimeEntryController
			if (te.Is_Running__c && te.Timer_Started_At__c != null) { // stop timer and update Hours

				if (te.Hours__c == null) {
					te.Hours__c = 0;
				}
				Utils.log('current hours val = ' + te.Hours__c);
				Utils.log('current timerStartedAt val = ' + te.Timer_Started_At__c);
				Utils.log('timerStartedAt.getTime() = ' + te.Timer_Started_At__c.getTime());

				Double millisecondsBetween = Datetime.now().getTime() - te.Timer_Started_At__c.getTime();
				Utils.log('millisecondsBetween = ' + millisecondsBetween);

				Double newHours = millisecondsBetween / 1000 / 3600;
				Utils.log('newHours = ' + newHours);

				te.Hours__c = te.Hours__c + newHours;
				te.Is_Running__c = false;
				te.Timer_Started_At__c = null;
			} else { // start timer
				te.Is_Running__c = true;
				te.Timer_Started_At__c = Datetime.now();
			}
			upsert te;
		} catch (Exception e) {
			Utils.errorMsgLightning(e);
		}
		return getTimeEntryData(recordId);
	}


	@AuraEnabled
	global static TimeEntryListData submitWeeklyTimesheet(String recordId) {
		// making this transactional so it will rollback if anything fails
		Savepoint sp = Database.setSavepoint();
		try {
			List<Weekly_Time_Sheet__c> timesheets = WeeklyTimeSheetsService.getWeeklyTimesheetsByIds(new Set<String> {recordId});
			if (timesheets.size() != 1) {
				throw new TimeEntryException('Unable to find the Weekly Time Sheet for Id = ' + recordId);
			}

			List<Time_Entry__c> timeEntries = TimeEntriesService.getTimeEntriesForWeeklyTimeSheetId(recordId);

			// validate and lock time entries
			if (timeEntries.size() > 0) {
				for (Time_Entry__c te : timeEntries) {
					if (te.Is_Running__c) {
						throw new TimeEntryException('There is a Timer running on a Time Entry. You must stop all Timers before you can submit the Weekly Timesheet.');
					}
					te.Is_Locked__c = true;
					te.Locked_Reason__c = 'Pending Manager Approval';
				}
				update timeEntries;
			}

			// all good - update the status
			Weekly_Time_Sheet__c wts = timesheets[0];
			wts.Status__c = Constants.STATUS_SUBMITTED;
			update wts;
		} catch (Exception e) {
			Database.rollback(sp);
			Utils.errorMsgLightning(e);
		}
		return getTimeEntryData(recordId);
	}


	@AuraEnabled
	global static TimeEntryListData approveWeeklyTimesheet(String recordId) {
		// making this transactional so it will rollback if anything fails
		Savepoint sp = Database.setSavepoint();
		try {
			List<Weekly_Time_Sheet__c> timesheets = WeeklyTimeSheetsService.getWeeklyTimesheetsByIds(new Set<String> {recordId});
			if (timesheets.size() != 1) {
				throw new TimeEntryException('Unable to find the Weekly Time Sheet for Id = ' + recordId);
			}

			List<Time_Entry__c> timeEntries = TimeEntriesService.getTimeEntriesForWeeklyTimeSheetId(recordId);

			// validate and lock time entries
			if (timeEntries.size() > 0) {
				for (Time_Entry__c te : timeEntries) {
					te.Is_Locked__c = true;
					te.Is_Closed__c = true;
					te.Locked_Reason__c = 'Manager Approval';
				}
				update timeEntries;
			}

			// all good - update the status
			Weekly_Time_Sheet__c wts = timesheets[0];
			wts.Status__c = Constants.STATUS_APPROVED;
			update wts;
		} catch (Exception e) {
			Database.rollback(sp);
			Utils.errorMsgLightning(e);
		}
		return getTimeEntryData(recordId);
	}
}