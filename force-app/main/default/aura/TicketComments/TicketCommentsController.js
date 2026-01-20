/**
 * Created by Kritik Garg on 16-02-2020.
 */

({
    doInit: function (component, event, helper) {
        helper.getCommentList(component);
    },

    validateAndPostNewComment: function(component, event, helper) {
        //console.log('generateInvoiceFromSelectedTime');
        //var newComment = component.get("v.newComment");
        // alert(JSON.stringify(selectedRecords));
        //generateInvoice
        helper.postComment(component);
    },
});