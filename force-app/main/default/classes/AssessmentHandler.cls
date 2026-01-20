/**
 * Created by Chris Home Desktop on 4/27/2018.
 */

public without sharing class AssessmentHandler implements TriggerHandler.ITrigger{

    private Boolean hasExecuted {get; set;}

    public AssessmentHandler() {}

    public void MainEntry(TriggerState state){

        system.debug('Assessment Handler Main Entry Called.');
        system.debug('Firing object: ' + state.TriggerObject);
        if(State.IsBefore) {
            if (state.IsDelete) {
                stopTransferredAssessmentDeletion(state);
            }
        }
        if(state.IsAfter){
            if(state.IsUpdate){
                performAfterUpdateActions(state);
            }
            if(state.IsInsert){
                performAfterInsertActions(state);
            }
            if (state.IsDelete) {
                performAfterDeleteActions(state);
            }
        }
        hasExecuted = true;
    }

    public void InProgressEntry(TriggerState state){
        system.debug('Assessment Handler In progress Called.');
        system.debug('Firing object: ' + state.TriggerObject);

        //// Handle other triggers fired by Assessment object in here.

        //// Return if not assessment object firing
        if(state.TriggerObject != 'Assessment__c'){
            system.debug('Another object fired this assessment trigger');
            return;
        }

        if(State.IsBefore) {
            if (state.IsDelete) {
                performBeforeDeleteActions(state);
            }
        }
        if(state.IsAfter){
            if(state.IsUpdate){
                performAfterUpdateActions(state);
            }
            if(state.IsInsert){
                performAfterInsertActions(state);
            }
            if (state.IsDelete) {
                performAfterDeleteActions(state);
            }
        }
        hasExecuted = true;
    }

    @TestVisible private void stopTransferredAssessmentDeletion(TriggerState state){

        list<Assessment__c> assessments = (list<Assessment__c>)state.OldList;
        for(Assessment__c curAssessment : assessments){

            if(curAssessment.Status__c == 'Transferred'){
                curAssessment.addError('You cannot delete a transferred assessment. Please use adjustments to change the balance of the assessment.');
            }
        }
    }

    @TestVisible private void performAfterUpdateActions(TriggerState state){
        if( hasExecuted == null || !hasExecuted ){
            runFiscalYearCalculations((list<Assessment__c>)state.NewList);
            runEventAssessmentProcessor((list<Assessment__c>)state.NewList);
        }
    }

    @TestVisible private void performAfterInsertActions(TriggerState state){
        if( hasExecuted == null || !hasExecuted ){
            runFiscalYearCalculations((list<Assessment__c>)state.NewList);
        }
    }

    @TestVisible private void performBeforeDeleteActions(TriggerState state){
        stopTransferredAssessmentDeletion(state);
    }

    @TestVisible private void performAfterDeleteActions(TriggerState state){
        if( hasExecuted == null || !hasExecuted ){
            runFiscalYearCalculations((list<Assessment__c>)state.OldList);
        }
    }


    @TestVisible private void runFiscalYearCalculations(list<Assessment__c> assessments){

        list<Account> accountsToUpdate = new list<Account>();
        set<Id> accIds = new set<Id>();
        for(Assessment__c curAssessment : assessments){
            if(String.isNotBlank(curAssessment.Account__c))
                accIds.add(curAssessment.Account__c);
        }
        try{
            accountsToUpdate = [SELECT Id,Current_Account_Balance__c,Amount_Assessed_this_FY__c FROM Account WHERE Id IN :accIds];
            FY_AccountBalanceCalc fyCalculator = new FY_AccountBalanceCalc(accountsToUpdate);
            fyCalculator.RunAllCalculations();
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
        }
    }

    //Added by Kritik on 27 Feb 2019 : task CORS-T91
    // to make Assessment  participant records "Paid in Full" checkbox to true.
    @TestVisible private void runEventAssessmentProcessor(list<Assessment__c> assessments) {

        List<Assessment__c> listOfEventAssessment = new List<Assessment__c>();
        String eventAssessmentRID = Schema.SObjectType.Assessment__c.getRecordTypeInfosByName().get('Event Assessment').getRecordTypeId();

        for(Assessment__c curAssessment : assessments){
            if(curAssessment.RecordTypeId == eventAssessmentRID) {
                listOfEventAssessment.add(curAssessment);
            }
        }

        if(listOfEventAssessment.size() == 0){
            return;
        }

        list<Event_Participant__c> participantsToUpdate = getUpdatedParticipants(listOfEventAssessment);
        if(participantsToUpdate.size()>0) {
            update participantsToUpdate;
        }
    }

    @TestVisible private list<Event_Participant__c> getUpdatedParticipants(list<Assessment__c> assessments){

        list<Event_Participant__c> returnList = new list<Event_Participant__c>();
        map<String,list<Payment_Adjustment_Allocation__c>> paymentAllocsByAssessmentId = getPaymentAllocsByAssessmentId(assessments);

        List<Participant_Assessment_Bridge__c> listOfAssessmentBridges = [
                SELECT Id, Assessment__c, Assessment__r.Remaining_Balance__c, Participant__c, Participant__r.Paid_in_Full__c
                FROM Participant_Assessment_Bridge__c
                WHERE Assessment__c IN :assessments
        ];
        for(Participant_Assessment_Bridge__c curAssessmentBridge : listOfAssessmentBridges){
            System.debug('CUR ASSESSMENT BRIDGE: ' + curAssessmentBridge.Id);
            Boolean hasError = false;
            if(String.isBlank(curAssessmentBridge.Participant__c)){
                continue;
            }

            if(paymentAllocsByAssessmentId.containsKey(curAssessmentBridge.Assessment__c)){
                for(Payment_Adjustment_Allocation__c curAlloc : paymentAllocsByAssessmentId.get(curAssessmentBridge.Assessment__c)){
                    if(curAlloc.Incomplete_Payment__c || curAlloc.Payment_Adjustment__r.Incomplete_Payment__c){
                        hasError = true;
                        break;
                    }
                }
            }

            System.debug('HAS ERROR: ' + hasError);

            if(hasError){
                System.debug('PARTICIPANT: ' + curAssessmentBridge.Participant__c);
                System.debug('PAID IN FULL: ' + curAssessmentBridge.Participant__r.Paid_in_Full__c);
                curAssessmentBridge.Participant__r.Paid_in_Full__c = false;
                returnList.add(curAssessmentBridge.Participant__r);
            }
            else if(curAssessmentBridge.Assessment__r.Remaining_Balance__c == 0){
                curAssessmentBridge.Participant__r.Paid_in_Full__c = true;
                returnList.add(curAssessmentBridge.Participant__r);
            }

        }

        return returnList;
    }

    @TestVisible private map<String,list<Payment_Adjustment_Allocation__c>> getPaymentAllocsByAssessmentId(list<Assessment__c> listOfEventAssessment){
        try{
            map<String,list<Payment_Adjustment_Allocation__c>> returnMap = new map<String,list<Payment_Adjustment_Allocation__c>>();
            map<Id,Assessment__c> assessmentMap = new map<ID,Assessment__c>(listOfEventAssessment);
            system.debug(assessmentMap);
            list<Payment_Adjustment_Allocation__c> payAdjAlloc = [SELECT Id,Payment_Adjustment__r.Incomplete_Payment__c,Incomplete_Payment__c,Assessment__c FROM Payment_Adjustment_Allocation__c WHERE Assessment__c IN :assessmentMap.keySet()];

            for(Payment_Adjustment_Allocation__c curPayAdjAlloc : payAdjAlloc){
                if(returnMap.containsKey(curPayAdjAlloc.Assessment__c)){
                    returnMap.get(curPayAdjAlloc.Assessment__c).add(curPayAdjAlloc);
                }
                else {
                    returnMap.put(curPayAdjAlloc.Assessment__c,new list<Payment_Adjustment_Allocation__c>{curPayAdjAlloc});
                }
            }

            return returnMap;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return null;
        }
    }

    /**
     * Description: This method has to check both Payment Adjustment Allocation and Payment Adjustment because
     *                  Adjustment Allocations are initially created as Complete Payments and then update to incomplete.
     *
     */
    @TestVisible private Boolean hasIncompletePayment(list<Assessment__c> listOfEventAssessment){
        try{
            map<Id,Boolean> hasErrorByAssessmentId = new map<Id,Boolean>();
            map<Id,Assessment__c> assessmentMap = new map<ID,Assessment__c>(listOfEventAssessment);
            system.debug(assessmentMap);
            list<Payment_Adjustment_Allocation__c> payAdjAlloc = [SELECT Id,Payment_Adjustment__r.Incomplete_Payment__c,Incomplete_Payment__c FROM Payment_Adjustment_Allocation__c WHERE Assessment__c IN :assessmentMap.keySet()];

            for(Payment_Adjustment_Allocation__c curPayAdjAlloc : payAdjAlloc){
                if(curPayAdjAlloc.Payment_Adjustment__r.Incomplete_Payment__c){
                    system.debug('Payment is incomplete. Returning');
                    return true;
                }
                else if(curPayAdjAlloc.Incomplete_Payment__c){
                    system.debug('Payment Adjustment Allocation is incomplete. Returning');
                    return true;
                }
            }

            return false;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return false;
        }
    }



//    @TestVisible private void runProgramBalanceCalculations(list<Assessment__c> assessments){
//
//        String eventAsessRTId = UtilitiesSObject.getRecordTypeId('Event_Assessment',Assessment__c.SObjectType);
//        map<Id,Assessment__c> assessmentMap = new map<Id,Assessment__c>(assessments);
//        set<Id> accountIds = new set<Id>();
//
////        for(Assessment__c curAssessment : assessments){
////            if(curAssessment.RecordTypeId == eventAsessRTId){
////                assessmentsByParticipantId.put(curAssessment.Program__c,curAssessment);
////            }
////        }
//        try{
//            list<Event_Participant__c> participants = [SELECT Id,Participant_Assessment_Bridge__r FROM Event_Participant__c WHERE Id in (SELECT Id FROM Participant_Assessment_Bridge__c WHERE Assessment__c IN :assessmentMap.keySet())];
//            rollUpAssessmentBalancesToParticipants(participants,assessmentsByParticipantId);
//        }
//        catch(QueryException qe){
//            system.debug(qe.getMessage());
//        }
//    }
//
//    @TestVisible private void rollUpAssessmentBalancesToParticipants(list<Event_Participant__c> participants, list<Assessment__c> assessments){
//
//        for(Event_Participant__c curParticipant : participants){
//            for(Assessment curAssessment : assessments){
//                if(curParticipant.Assessment__c == curAssessment.Id){
//                    curParticipant.
//                }
//            }
//        }
//        try{
//            update participants;
//        }
//        catch(DmlException de){
//            system.debug(de.getMessage());
//        }
//    }



}