/**
 * Created by Kritik Garg on 03-03-2020.
 */

({
    // Fetch the Allocations from the Apex controller
    getAllocation: function (component, isCreditAssessment) {

        var action;
        if(isCreditAssessment) {
            action = component.get('c.getCreditAllocationsFromAssessment');
        } else {
            action = component.get('c.getPaymentAllocationsFromAssessment');
        }
        action.setParams({
            assessmentId: component.get("v.recordId")
        });

        // Set up the callback
        var self = this;
        action.setCallback(this, function (actionResult) {
            component.set('v.allocations', actionResult.getReturnValue());
            console.log(actionResult.getReturnValue());
        });
        $A.enqueueAction(action);
    },

    getAssessment: function (component) {
        var action = component.get('c.getAssessments');
        action.setParams({
            assessmentId: component.get("v.recordId")
        });

        // Set up the callback
        var self = this;
        action.setCallback(this, function (actionResult) {
            console.log(actionResult.getReturnValue());
            var assessments = actionResult.getReturnValue();
            if(assessments.length > 0) {
                var assessment = assessments[0];
                console.log(assessment);
                console.log(assessment.RecordType.Name);
                component.set('v.assessment', assessment);

                if(assessment.RecordType.Name == 'Credit Assessment') {
                    self.getAllocation(component,true);
                } else {
                    self.getAllocation(component,false);
                }

            }

        });
        $A.enqueueAction(action);
    },

});