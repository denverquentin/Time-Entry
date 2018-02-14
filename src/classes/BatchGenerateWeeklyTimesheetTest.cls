/**
 * Tests for BatchGenerateWeeklyTimesheet Class.
 */
@IsTest
private class BatchGenerateWeeklyTimesheetTest {

	/**
	 * Creates a test User with a Sys Admin Profile that can be used for testing.
	 * The User record will be inserted into the Database if the doInsert parameter = true;
	 * 
	 * @param  Boolean doInsert
	 * @return User
	 */
	public static User createTestAdminUser(Boolean doInsert) {
		User u = new User();
		u.FirstName = 'First' + Utils.generateRandomKey();
		u.LastName = 'Last' + Utils.generateRandomKey();
		u.Email = 'email' + Utils.generateRandomKey() + '@somewhere.co';
		u.UserName = u.Email;
		u.ProfileId = [select Id from Profile where Name = :Constants.PROFILE_NAME_SYSTEM_ADMINISTRATOR].Id;
		u.Alias = 'test';
		u.CommunityNickName = u.LastName;
		u.TimeZoneSidKey = 'America/Denver';
		u.LocaleSidKey = 'en_US';
		u.LanguageLocaleKey = 'en_US';
		u.EmailEncodingKey = 'UTF-8';
		u.IsActive = true;
		if (doInsert) {
			insert u;
		}
		return u;
	}


	@IsTest
	static void test_BatchGenerateWeeklyTimesheet() {
		// create 2 active users
		List<User> activeUsers = new List<User> {
			createTestAdminUser(false),
			createTestAdminUser(false)
		};
		insert activeUsers;		

		// create a Client Account
		Account client = new Account();
		client.Name = 'Test Client for Weekly Timesheet';
		client.RecordTypeId = Constants.REC_TYPE_ID_ACCOUNT_CLIENT;
		client.Is_Active__c = true;
		insert client;

		// start off with an inactive Project
		Project__c project = new Project__c();
		project.Name = 'Test Project for Weekly Timesheet';
		project.Is_Active__c = true;
		project.Client__c = client.Id;
		project.Bill_By__c = 'Project';
		project.Budget_By__c = 'project';
		project.Project_Hourly_Rate__c = 100.50;
		insert project;

		Project_User_Assignment__c pua1 = new Project_User_Assignment__c();
		pua1.Project__c = project.Id;
		pua1.User__c = activeUsers[0].Id;
		pua1.Is_Active__c = true;

		Project_User_Assignment__c pua2 = new Project_User_Assignment__c();
		pua2.Project__c = project.Id;
		pua2.User__c = activeUsers[1].Id;
		pua2.Is_Active__c = true;

		insert new List<Project_User_Assignment__c> {pua1, pua2};

		Test.startTest();

		BatchGenerateWeeklyTimesheet bgwt = new BatchGenerateWeeklyTimesheet(Date.today());
		Database.executeBatch(bgwt);

		Test.StopTest();

		List<Weekly_Time_Sheet__c> timesheets = [select Id from Weekly_Time_Sheet__c];
		Utils.log('timesheets.size() = ' + timesheets.size());
		System.assert(timesheets.size() == 2);
	}
}