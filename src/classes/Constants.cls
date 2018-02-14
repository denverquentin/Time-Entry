/**
 * Class for all Constants used by the application.
 */
global with sharing class Constants {
	global static final String PROFILE_NAME_SYSTEM_ADMINISTRATOR = 'System Administrator';

	private static final Map<String,Schema.RecordTypeInfo> accountRecordTypes = Schema.SObjectType.Account.getRecordTypeInfosByName();

	global static final Id REC_TYPE_ID_ACCOUNT_CLIENT = accountRecordTypes.get('Client').getRecordTypeId();

	global static final String STATUS_IN_PROGRESS = 'In Progress';
	global static final String STATUS_SUBMITTED = 'Submitted';
	global static final String STATUS_APPROVED = 'Approved';

	global static final String BILL_BY_PROJECT = 'Project';
	global static final String BILL_BY_TASKS = 'Tasks';
	global static final String BILL_BY_PEOPLE = 'People';
}