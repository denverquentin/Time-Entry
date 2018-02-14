/**
 * Tests for BatchScheduler Class.
 */
@IsTest
private class BatchSchedulerTest {

	@IsTest
	static void test_BatchScheduler_scheduleWeeklyTimesheetGeneration() {
		Test.startTest();

		Id jobId = BatchScheduler.scheduleWeeklyTimesheetGeneration();
		System.assert(jobId != null);

		Test.StopTest();
	}
}