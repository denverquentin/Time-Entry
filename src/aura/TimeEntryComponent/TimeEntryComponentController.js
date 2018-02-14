({
	doInit : function(component, event, helper) {
		console.log("in doInit");
		// reset everything
		component.set("v.timeEntry", null);
		component.set("v.messageTitle", null);
		component.set("v.messageSeverity", null);
		component.set("v.messages", null);
		console.log("recordId = " + component.get("v.recordId"));
		var action = component.get("c.getTimeEntryData");
		action.setParams({ recordId : component.get("v.recordId") });
		action.setCallback(this, function(response) {
			if (response.getState() === "SUCCESS") {
				component.set("v.timeEntry", response.getReturnValue().timeEntry);
				console.log("v.timeEntry = " + JSON.stringify(component.get("v.timeEntry")));
				component.set("v.allTaskOptions", response.getReturnValue().activeProjectTaskAssignments);

				var projects = [];
				for (var z = 0; z < response.getReturnValue().activeProjectUserAssignments.length; z++) {
					var d = response.getReturnValue().activeProjectUserAssignments[z];
					projects.push({value: d.value, label: d.label});
				}

				component.set("v.projectOptions", projects);
				//console.log("v.projectOptions = " + JSON.stringify(component.get("v.projectOptions")));

				if (component.get("v.timeEntry").projectUserAssignmentId != null) {
					// build a task specific list for the selected project
					var tasks = [];
					for (var z = 0; z < component.get("v.allTaskOptions").length; z++) {
						var d = component.get("v.allTaskOptions")[z];
						if (d.projectUserAssignment == component.get("v.timeEntry").projectUserAssignmentId) {
							tasks.push({value: d.value, label: d.label});
						}
					}
					component.set("v.taskOptions", tasks);
				}
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


	handleProjectOptionSelected : function(component, event, helper) {
		console.log("in handleProjectOptionSelected");
		// Get the string of the "value" attribute on the selected option
		var selectedProjectUserAssignmentId = event.getParam("value");

		// build a task specific list for the selected project
		var tasks = [];
		for (var z = 0; z < component.get("v.allTaskOptions").length; z++) {
			var d = component.get("v.allTaskOptions")[z];
			if (d.projectUserAssignment == selectedProjectUserAssignmentId) {
				tasks.push({value: d.value, label: d.label});
			}
		}
		component.set("v.taskOptions", tasks);
	},


	saveTimeEntry : function(component, event, helper) {
		console.log("in save");
		// reset message
		component.set("v.messageTitle", null);
		component.set("v.messageSeverity", null);
		component.set("v.messages", null);

		var action = component.get("c.upsertTimeEntry");
		// stringifying the object is a hack to get around this bug - https://success.salesforce.com/issues_view?id=a1p3A000000EAbLQAW
		action.setParams({ timeEntryString : JSON.stringify(component.get("v.timeEntry")) });
		action.setCallback(this, function(response) {
			if (response.getState() === "SUCCESS") {
				var teId = response.getReturnValue().id;
				console.log("teId = " + teId);

				var resultsToast = $A.get("e.force:showToast");
				resultsToast.setParams({
					"title": response.getReturnValue().title,
					"message": response.getReturnValue().message
				});
				resultsToast.fire();

				var tab = $A.get("e.force:navigateToObjectHome");
				tab.setParams({"scope": "qfts__Weekly_Time_Sheet__c"}); // using namespace is bad but only way it works

				if (component.get("v.recordId") != null) {
					if (component.get("v.recordId") != component.get("v.timeEntry").id) {
						// navigate to record we started from
						var navEvt = $A.get("e.force:navigateToSObject");
						navEvt.setParams({"recordId": component.get("v.recordId")});
						navEvt.fire();
					} else {
						tab.fire();
					}
				} else {
					tab.fire();
				}

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


	cancel : function(component, event, helper) {
		console.log("cancel");
		// first would be all we need it the component opened as an action window - not sure why it doesn't
		//$A.get("e.force:closeQuickAction").fire();

		var tab = $A.get("e.force:navigateToObjectHome");
		tab.setParams({"scope": "qfts__Weekly_Time_Sheet__c"}); // using namespace is bad but only way it works

		if (component.get("v.recordId") != null) {
			if (component.get("v.recordId") != component.get("v.timeEntry").id) {
				// navigate to record we started from
				var navEvt = $A.get("e.force:navigateToSObject");
				navEvt.setParams({"recordId": component.get("v.recordId")});
				navEvt.fire();
			} else {
				tab.fire();
			}
		} else {
			tab.fire();
		}
	}
})