/**
 * Tests for TimeEntryException Class.
 */
@IsTest
private class TimeEntryExceptionTest {

	@IsTest
	static void test_TimeEntry() {
		try {
			TimeEntryException e = new TimeEntryException('testing');
			e.x = 0;
			throw e;
		} catch (TimeEntryException e) {
			System.assert(e.getMessage() == 'testing');
		}
	}
}