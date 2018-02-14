trigger TimeEntriesTrigger on Time_Entry__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
	// didn't end up needing any trigger code - sweet!
	SObjectDomain.triggerHandler(TimeEntries.class);
}