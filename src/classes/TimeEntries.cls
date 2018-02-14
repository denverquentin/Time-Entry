public with sharing class TimeEntries extends SObjectDomain {
	// didn't end up needing any trigger code - sweet!
	public TimeEntries(List<Time_Entry__c> sObjectList) {
		super(sObjectList);
	}

/*
	public override void onBeforeInsert() {
	}


	public override void onAfterInsert() {
	}


	public override void onBeforeUpdate(Map<Id,SObject> oldSObjectMap) {
	}
*/

	public class Constructor implements SObjectDomain.IConstructable {
		public SObjectDomain construct(List<SObject> sObjectList) {
			return new TimeEntries(sObjectList);
		}
	}
}