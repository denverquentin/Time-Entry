({
	doInit : function(component, event, helper) {
		console.log("in doInit");
		// reset everything
		component.set("v.data", null);
		component.set("v.messageTitle", null);
		component.set("v.messageSeverity", null);
		component.set("v.messages", null);
		console.log("recordId = " + component.get("v.recordId"));
		var action = component.get("c.getTimeEntryData");
		action.setParams({ recordId : component.get("v.recordId") });
		action.setCallback(this, function(response) {
			if (response.getState() === "SUCCESS") {
				component.set("v.data", response.getReturnValue());
				//console.log("v.data = " + JSON.stringify(component.get("v.data")));

/*				code was for data tables - using tiles instead
				component.set("v.timeEntries", response.getReturnValue().timeEntries);
				if (component.get("v.timeEntries") == null) { component.set("v.timeEntries", []); }

				if (component.get("v.timeEntries").length > 0) {
					// show different columns based on the object this component is on
					if (component.get("v.data").sobjectType == 'Project__c') {

						component.set("v.timeEntryColumns", [
							{label: 'Date', fieldName: 'entryDate', type: 'text'},
							{label: 'Task', fieldName: 'projectTaskName', type: 'text'},
							{label: 'Hours', fieldName: 'hours', type: 'number'}
						]);

					} else { // Weekly_Time_Sheet__c
						component.set("v.timeEntryColumns", [
							{label: 'Date', fieldName: 'entryDate', type: 'text'},
							{label: 'Client - Project', fieldName: 'clientAndProjectName', type: 'text'},
							{label: 'Task', fieldName: 'projectTaskName', type: 'text'},
							{label: 'Hours', fieldName: 'hours', type: 'number'}
						]);
					}
				}
*/
			} else {
				component.set("v.messageTitle", "Info");
				component.set("v.messageSeverity", "info");
				var errs = [];
				for (var x = 0; x < response.getError().length; x++) {
					errs.push(response.getError()[x].message);
				}
				component.set("v.messages", errs);
			}
		});
		$A.enqueueAction(action);
	},


	newTimeEntry : function(component, event, helper) {
		console.log("in newTimeEntry");
		var evt = $A.get("e.force:navigateToComponent");
		evt.setParams({
			componentDef : "c:TimeEntryComponent",
			componentAttributes: {
				recordId : component.get("v.recordId")
			}
		});
		evt.fire();
	},


	/* not using this
	editTimeEntry : function(component, event, helper) {
		console.log("in newTimeEntry");
		var evt = $A.get("e.force:navigateToComponent");
		evt.setParams({
			componentDef : "c:TimeEntryComponent",
			componentAttributes: {
				recordId : component.get("v.recordId")
			}
		});
		evt.fire();
	},
*/

	toggleTimer : function(component, event, helper) {
		console.log("in toggleTimer");
		component.set("v.messageTitle", null);
		component.set("v.messageSeverity", null);
		component.set("v.messages", null);
		// submit button passes a value of the Time Entry Id
		var timeEntryId = event.getSource().get("v.value");
		console.log("timeEntryId = " + timeEntryId);
		console.log("recordId = " + component.get("v.recordId"));
		var action = component.get("c.toggleTimerForTimeEntry");
		action.setParams({
			recordId : component.get("v.recordId"),
			timeEntryId : timeEntryId
		});

		action.setCallback(this, function(response) {
			if (response.getState() === "SUCCESS") {
				component.set("v.data", response.getReturnValue());
				//console.log("v.data = " + JSON.stringify(component.get("v.data")));
			} else {
				component.set("v.messageTitle", "Error");
				component.set("v.messageSeverity", "error");
				var errs = [];
				for (var x = 0; x < response.getError().length; x++) {
					errs.push(response.getError()[x].message);
				}
				component.set("v.messages", errs);
			}
		});
		$A.enqueueAction(action);
	},


	submitTimeSheet : function(component, event, helper) {
		console.log("in submitTimeSheet");
		component.set("v.messageTitle", null);
		component.set("v.messageSeverity", null);
		component.set("v.messages", null);
		// submit button only shows the the weekly time sheet so the id will always be for that
		console.log("recordId = " + component.get("v.recordId"));

		var action = component.get("c.submitWeeklyTimesheet");
		action.setParams({ recordId : component.get("v.recordId") });
		action.setCallback(this, function(response) {
			if (response.getState() === "SUCCESS") {
				component.set("v.data", response.getReturnValue());
				//console.log("v.data = " + JSON.stringify(component.get("v.data")));

				var resultsToast = $A.get("e.force:showToast");
				resultsToast.setParams({
					"title": 'Success!',
					"message": 'The Weekly Timesheet was submitted for approval.'
				});
				resultsToast.fire();

			} else {
				component.set("v.messageTitle", "Error");
				component.set("v.messageSeverity", "error");
				var errs = [];
				for (var x = 0; x < response.getError().length; x++) {
					errs.push(response.getError()[x].message);
				}
				component.set("v.messages", errs);
			}
		});
		$A.enqueueAction(action);
	},


	approveTimeSheet : function(component, event, helper) {
		console.log("in approveTimeSheet");
		component.set("v.messageTitle", null);
		component.set("v.messageSeverity", null);
		component.set("v.messages", null);
		// approve button only shows the the weekly time sheet so the id will always be for that
		console.log("recordId = " + component.get("v.recordId"));

		var action = component.get("c.approveWeeklyTimesheet");
		action.setParams({ recordId : component.get("v.recordId") });
		action.setCallback(this, function(response) {
			if (response.getState() === "SUCCESS") {
				component.set("v.data", response.getReturnValue());
				//console.log("v.data = " + JSON.stringify(component.get("v.data")));

				var resultsToast = $A.get("e.force:showToast");
				resultsToast.setParams({
					"title": 'Success!',
					"message": 'The Weekly Timesheet was approved.'
				});
				resultsToast.fire();

			} else {
				component.set("v.messageTitle", "Error");
				component.set("v.messageSeverity", "error");
				var errs = [];
				for (var x = 0; x < response.getError().length; x++) {
					errs.push(response.getError()[x].message);
				}
				component.set("v.messages", errs);
			}
		});
		$A.enqueueAction(action);
	}
})