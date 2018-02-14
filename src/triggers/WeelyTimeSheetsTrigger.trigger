trigger WeelyTimeSheetsTrigger on Weekly_Time_Sheet__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
	// didn't end up needing any trigger code - sweet!
	SObjectDomain.triggerHandler(WeeklyTimeSheets.class);
}