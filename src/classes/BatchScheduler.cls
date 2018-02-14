/**
 * BatchScheduler implements the Schedulable interface and is used to schedule batch jobs.
 * Centralizing all Schedulable jobs in this class to limit the number of Schedulable
 * classes and unit tests.
 */
global class BatchScheduler implements Schedulable {

	global static final Integer WEEKLY_TIMESHEET_GENERATION = 10;

	global Integer classToSchedule { get; set; }

	global void execute(SchedulableContext sc) {
		if (classToSchedule == WEEKLY_TIMESHEET_GENERATION) {
			BatchGenerateWeeklyTimesheet batch = new BatchGenerateWeeklyTimesheet();
			Database.executeBatch(batch);
		}
	}


	/**
	 * scheduleWeeklyTimesheetGeneration method schedules the BatchGenerateWeeklyTimesheet
	 * class to run weekly on Sundays at 8:00pm.
	 * The job is scheduled as "Weekly Timesheet Generation".
	 * <p>
	 * You can schedule the job programatically by executing the following Apex code in the Developer Console:
	 * BatchScheduler.scheduleWeeklyTimesheetGeneration();
 	 * @return   Id of the Job
 	*/
	global static Id scheduleWeeklyTimesheetGeneration() {
		BatchScheduler bs = new BatchScheduler();
		bs.classToSchedule = WEEKLY_TIMESHEET_GENERATION;
		// schedule to run weekly on Sundays at 8:00pm
		return System.schedule('Weekly Timesheet Generation', '0 0 20 ? * SUN', bs);
	}
}