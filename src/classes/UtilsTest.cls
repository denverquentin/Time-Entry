/**
 * Tests for Utils methods.
 */
@IsTest
private class UtilsTest {

	@IsTest
	static void test_removeNull() {
		System.assertEquals('', Utils.removeNull(null));
		System.assertEquals('hi', Utils.removeNull('hi'));
	}


	@IsTest
	static void test_convertStringSetForQuery() {
		System.assertEquals('', Utils.convertStringSetForQuery(null));
		System.assertEquals('', Utils.convertStringSetForQuery(new Set<String>()));
//		System.assertEquals('(\'' +  Constants.REC_TYPE_ID_METRIC_ACCOUNT + '\')', Utils.convertStringSetForQuery(new Set<String> {Constants.REC_TYPE_ID_METRIC_ACCOUNT}));
//		System.assertEquals('(\'' +  Constants.REC_TYPE_ID_METRIC_MID + '\',\'' + Constants.REC_TYPE_ID_METRIC_ACCOUNT + '\')', Utils.convertStringSetForQuery(new Set<String> {Constants.REC_TYPE_ID_METRIC_MID, Constants.REC_TYPE_ID_METRIC_ACCOUNT}));
	}


	@IsTest
	static void test_convertDateSetForQuery() {
		System.assertEquals('', Utils.convertDateSetForQuery(null));
		System.assertEquals('', Utils.convertDateSetForQuery(new Set<Date>()));
		System.assertEquals('(1975-06-09)', Utils.convertDateSetForQuery(new Set<Date> {Date.newInstance(1975, 6, 9)}));
		System.assertEquals('(2011-07-31,2013-10-29)', Utils.convertDateSetForQuery(new Set<Date> {Date.newInstance(2011, 7, 31), Date.newInstance(2013, 10, 29)}));
	}


	@IsTest
	static void test_convertDateForDynamicQuery() {
		System.assertEquals('1975-06-09', Utils.convertDateForDynamicQuery(Date.newInstance(1975, 6, 9)));
		System.assertEquals('1999-12-31', Utils.convertDateForDynamicQuery(Date.newInstance(1999, 12, 31)));
		System.assertEquals('1980-01-19', Utils.convertDateForDynamicQuery(Date.newInstance(1980, 1, 19)));
		System.assertEquals('1982-10-09', Utils.convertDateForDynamicQuery(Date.newInstance(1982, 10, 9)));
	}


	@IsTest
	static void test_loggingAndPageMessages() {
		Utils.confirmMsg('confirm');
		Utils.infoMsg('info');
		Utils.warnMsg('warn');
		Utils.errorMsg('error');
		Utils.errorMsg(new TimeEntryException('custom exception'));
		Utils.log('log');
		Utils.logError(new TimeEntryException('another exception'));
		Utils.log(new Account());
	}
}