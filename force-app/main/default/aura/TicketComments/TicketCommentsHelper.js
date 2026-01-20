/**
 * Created by Kritik Garg on 16-02-2020.
 */

({
    getCommentList: function (component) {
        var action = component.get('c.getCommentsByIssueId');
        action.setParams({
            ticketId: component.get("v.recordId")
        });

        //console.log('St Date:' + component.get("v.startDate"));

        // Set up the callback
        var self = this;
        action.setCallback(this, function (actionResult) {
            component.set('v.comments', actionResult.getReturnValue());
            console.log(actionResult.getReturnValue());
        });
        $A.enqueueAction(action);
    },

    postComment: function (component) {
        var action = component.get('c.postComment');
        action.setParams({
            ticketId: component.get("v.recordId"),
            commentString: component.get("v.newComment")
        });

        //console.log('St Date:' + component.get("v.startDate"));

        // Set up the callback
        var self = this;
        action.setCallback(this, function (response) {

            var state = response.getState();
            console.log(response.getReturnValue());
            if (state === "SUCCESS") {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": "success",
                    "message": "Comment Posted"
                });

                toastEvent.fire();
                console.log('Working');

                this.initVariable(component);
                $A.get('e.force:refreshView').fire();
            } else if (state == "ERROR") {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": "error",
                    "message": response.getError()[0].message
                });
                console.log('errorerror' + response.getError());
                console.log( response.getError());
                toastEvent.fire();
            }


        });
        $A.enqueueAction(action);
    },

    initVariable: function (component) {
        this.getCommentList(component);
        component.set("v.newComment",'');
    }

});