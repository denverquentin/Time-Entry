/**
 * Contains common methods that are used throughout the codebase.
 */
global with sharing class Utils {
	/**
	 * If the User.Is_Admin__c = true, the User can approve any Timesheet.
	 */
	global static Boolean canUserApproveTimesheets(Id userId) {
		User u = [select Is_Admin__c from User where Id = :userId];

		return u.Is_Admin__c;
	}


	global static String removeNull(String val) {
		if (val == null) {
			return '';
		} else {
			return val;
		}
	}


	global static String convertStringSetForQuery(Set<String> vals) {
		String returnVal = '';
		if (vals != null && vals.size() > 0) {
			returnVal = '(';
			for (String val : vals) {
				if (String.isNotBlank(val)) {
					returnVal += '\'' + val + '\',';
				} else {
					returnVal += '\'\',';
				}
			}
			returnVal = returnVal.removeEnd(',');
			returnVal += ')';
		}
		return returnVal;
	}


	// can't use method above - Date's don't have quotes around them in dynamic queries
	global static String convertDateSetForQuery(Set<Date> vals) {
		String returnVal = '';
		if (vals != null && vals.size() > 0) {
			returnVal = '(';
			for (Date val : vals) {
				returnVal += convertDateForDynamicQuery(val) + ',';
			}
			returnVal = returnVal.removeEnd(',');
			returnVal += ')';
		}
		return returnVal;
	}


	global static String convertDateForDynamicQuery(Date val) {
		if (val != null) {
			String month = String.valueOf(val.month());
			if (month.length () == 1) {
				month = '0' + month;
			}
			String day = String.valueOf(val.day());
			if (day.length () == 1) {
				day = '0' + day;
			}
			return val.year() + '-' + month + '-' + day;
		}
		return null;
	}


	// Generate a random base 32 key that's 12 characters long - also removes some confusing characters - https://www.crockford.com/wrmg/base32.html
	public static String generateRandomKey() {
		String key = EncodingUtil.base64Encode(Crypto.generateAesKey(128));
		//Utils.log('key = ' + key);
		// to ensure a better distribution of numbers & letters we're replacing some letters we don't want to use with numbers
		key = key.replaceAll('U', '0');
		key = key.replaceAll('u', '1');
		key = key.replaceAll('I', '2');
		key = key.replaceAll('i', '3');
		key = key.replaceAll('l', '4');
		key = key.replaceAll('L', '5');
		key = key.replaceAll('O', '6');
		key = key.replaceAll('o', '7');
		key = key.replaceAll('\\+', '8');
		key = key.replaceAll('/', '9');
		key = key.replaceAll('=', '');
		return key.toUpperCase().subString(0, 12); // only use 12 characters
	}


	global static void confirmMsg(String message) {
		ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.CONFIRM, message));
	}

	global static void infoMsg(String message) {
		ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, message));
	}

	global static void warnMsg(String message) {
		ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, message));
	}

	global static void errorMsg(String message) {
		ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, message));
	}

	global static void errorMsg(Exception e) {
		ApexPages.addMessages(e);
		logError(e);// also log it to save line in controller
	}

	global static void errorMsgLightning(Exception e) {
		logError(e);// also log it to save line in controller
		AuraHandledException ahe = new AuraHandledException(e.getMessage());
		ahe.setMessage(e.getMessage());
		throw ahe;
	}

	global static void log(String msg) {
		System.debug(LoggingLevel.INFO, msg);
	}

	global static void log(SObject obj) {
		System.debug(LoggingLevel.INFO, obj);
	}

	global static void logError(Exception e) {
		System.debug(LoggingLevel.ERROR, e.getMessage());
		System.debug(LoggingLevel.ERROR, e.getStackTraceString());
	}
}