/**
 * Created by cgibs_000 on 5/21/2017.
 */
public with sharing class TriggerHandler {


    public static ITrigger activeFunction = null;
    public static map<Id,SObject> sObjectsToUpdate = new map<Id,SObject>();

    public static void TriggerHandlerEntry(TriggerState state){
//        System.debug(state);
        if(state.TriggerObject == 'Contact'){
            processContactHandler(state);
        }
        if(state.TriggerObject == 'Yahrzeit__c'){
            processYahrzeitHandler(state);
        }
        if(state.TriggerObject == 'Account'){
            processAccountHandler(state);
        }
        if(state.TriggerObject == 'Torah_Portion__c'){
            processTorahHandler(state);
        }
        if(state.TriggerObject == 'Relationship_Affiliation__c'){
            processRelationshipHandler(state);
        }
        if(state.TriggerObject == 'Batch__c'){
            processBatchHandler(state);
        }
        if(state.TriggerObject == 'Payment_Adjustment__c'){
            processPaymentHandler(state);
        }
        if(state.TriggerObject == 'Assessment__c'){
            processAssessmentHandler(state);
        }

        if(state.TriggerObject == 'Ticket_Issue__c'){
            processTicketIssueHandler(state);
        }
        if(state.TriggerObject == 'Comment__c'){
            processCommentHandler(state);
        }
        if(state.TriggerObject == 'ContentDocumentLink'){
            processContentDocumentLinkHandler(state);
        }
        if(state.TriggerObject == 'Payment_Vault__c'){
            processPaymentVaults(state);
        }

        if(sObjectsToUpdate.values().size() > 0){
            update sObjectsToUpdate.values();
        }
    }

    @TestVisible private static void processAssessmentHandler(TriggerState state){

        if(activeFunction != null){
            activeFunction.InProgressEntry(state);
        }
        else{

            activeFunction = new AssessmentHandler();
            activeFunction.MainEntry(state);
        }
    }

    @TestVisible private static void processContactHandler(TriggerState state){

        if(activeFunction != null){
            activeFunction.InProgressEntry(state);
        }
        else{

            activeFunction = new ContactHandler();
            activeFunction.MainEntry(state);
        }
    }

    @TestVisible private static void processYahrzeitHandler(TriggerState state){

        if(activeFunction != null){
            activeFunction.InProgressEntry(state);
        }
        else{

            activeFunction = new YahrzeitHandler();
            activeFunction.MainEntry(state);
        }
    }


    @TestVisible private static void processAccountHandler(TriggerState state){
        if(activeFunction != null){
            activeFunction.InProgressEntry(state);
        } else {
            activeFunction = new AccountHandler();
            activeFunction.MainEntry(state);
        }
    }

    @TestVisible private static void processTorahHandler(TriggerState state){

        if(activeFunction != null){
            activeFunction.InProgressEntry(state);
        }
        else{

            activeFunction = new TorahHandler();
            activeFunction.MainEntry(state);
        }
    }

    @TestVisible private static void processBatchHandler(TriggerState state){

        if(activeFunction != null){
            activeFunction.InProgressEntry(state);
        }
        else{

            activeFunction = new BatchTriggerHandler();
            activeFunction.MainEntry(state);
        }
    }

    @TestVisible private static void processRelationshipHandler(TriggerState state){

        if(activeFunction != null){
            activeFunction.InProgressEntry(state);
        }
        else{

            activeFunction = new RelationshipHandler();
            activeFunction.MainEntry(state);
        }
    }

    @TestVisible private static void processPaymentHandler(TriggerState state){

        if(activeFunction != null){
            activeFunction.InProgressEntry(state);
        }
        else{

            activeFunction = new PaymentAdjustmentHandler();
            activeFunction.MainEntry(state);
        }
    }

    @TestVisible private static void processTicketIssueHandler(TriggerState state){

        if(activeFunction != null){
            activeFunction.InProgressEntry(state);
        }
        else{
            activeFunction = new TicketHandler();
            activeFunction.MainEntry(state);
        }
    }

    @TestVisible private static void processCommentHandler(TriggerState state){

        if(activeFunction != null){
            activeFunction.InProgressEntry(state);
        }
        else{
            activeFunction = new CommentHandler();
            activeFunction.MainEntry(state);
        }
    }

    @TestVisible private static void processContentDocumentLinkHandler(TriggerState state){

        if(activeFunction != null){
            activeFunction.InProgressEntry(state);
        }
        else{
            activeFunction = new ContentDocumentLinkHandler();
            activeFunction.MainEntry(state);
        }
    }
    
    @TestVisible private static void processPaymentVaults(TriggerState state){
        if(activeFunction != null){
            activeFunction.InProgressEntry(state);
        }
        else{
            activeFunction = new PaymentVaultHandler();
            activeFunction.MainEntry(state);
        }
    }


    public interface ITrigger{

        void MainEntry(TriggerState state);

        void InProgressEntry(TriggerState state);
    }
}