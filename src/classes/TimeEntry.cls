/**
 * Class to store all the Time Entry values that be entered or displayed in the Lightning component.
 * Using this class instead of the Time_Entry__c object because lightning makes you use the namespace
 * when referencing fields. That won't work for development outside of the packaging org.
 */
global class TimeEntry {
	@AuraEnabled
	global String id {get;set;}
	@AuraEnabled
	global String clientAndProjectName {get;set;}
	@AuraEnabled
	global String projectId {get;set;}
	@AuraEnabled
	global String projectTaskName {get;set;}
	@AuraEnabled
	global Date entryDate {get;set;}
	@AuraEnabled
	global String projectUserAssignmentId {get;set;}
	@AuraEnabled
	global String projectTaskAssignmentId {get;set;}
	@AuraEnabled
	global String notes {get;set;}
	@AuraEnabled
	global Decimal hours {get;set;}
	@AuraEnabled
	global Decimal billableAmount {get;set;}
	@AuraEnabled
	global Boolean isRunning {get;set;}
	@AuraEnabled
	global Boolean isClosed {get;set;}
	@AuraEnabled
	global Boolean isLocked {get;set;}
	@AuraEnabled
	global Datetime timerStartedAt {get;set;}
}