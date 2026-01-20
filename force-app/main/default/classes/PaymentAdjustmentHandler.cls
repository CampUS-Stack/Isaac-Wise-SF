/**
 * Created by Chris Home Desktop on 11/7/2017.
 */

public with sharing class PaymentAdjustmentHandler implements TriggerHandler.ITrigger{


    private Boolean hasExecuted {get; set;}

    public PaymentAdjustmentHandler() {}

    public void MainEntry(TriggerState state){

        system.debug('Payment Adjustment Trigger Handler Main Entry Called.');
        system.debug('Firing object: ' + state.TriggerObject);

        if(state.IsBefore){
            if(state.IsUpdate){
            }
            else if(state.IsDelete){
                stopTransferredPaymentDeletion(state);
            }
        }
        if(state.isAfter){
            if(state.isDelete){
                updateBatches(state);
            }
            else if(state.isUpdate){
                if(hasExecuted == null || !hasExecuted){
                    runFiscalYearCalculations((list<Payment_Adjustment__c>)state.NewList);
                    updateBatches(state);
                    hasExecuted = true;
                }
            }
            else if(state.isInsert){
                if(hasExecuted == null || !hasExecuted) {
                    runFiscalYearCalculations((list<Payment_Adjustment__c>) state.NewList);
                    hasExecuted = true;
                }
            }
        }

    }

    public void InProgressEntry(TriggerState state){

        if(state.TriggerObject == 'Batch__c'){
            BatchTriggerHandler handler = new BatchTriggerHandler();
            handler.InProgressEntry(state);
        }
        else if(state.TriggerObject == 'Assessment__c'){
            AssessmentHandler handler = new AssessmentHandler();
            handler.InProgressEntry(state);
        }

        if(state.TriggerObject != 'Payment_Adjustment__c'){
            return;
        }

        if(state.isAfter){
            if(state.isDelete){
                if(hasExecuted == null || !hasExecuted) {
                    updateBatches(state);
                    hasExecuted = true;
                }
            }
            else if(state.isUpdate){
                if(hasExecuted == null || !hasExecuted) {
                    runFiscalYearCalculations((list<Payment_Adjustment__c>) state.NewList);
                    updateBatches(state);
                    hasExecuted = true;
                }
            }
        }
    }

    @TestVisible private void stopTransferredPaymentDeletion(TriggerState state){

        list<Payment_Adjustment__c> paymentAdjustments = (list<Payment_Adjustment__c>)state.OldList;
        for(Payment_Adjustment__c curPaymentAdj : paymentAdjustments){

            if(curPaymentAdj.Status__c == 'Transferred'){
                curPaymentAdj.addError('You cannot delete a transferred payment. Please use the reallocate or void process to change the payment.');
            }
        }
    }

    @TestVisible private void updateBatches(TriggerState state){
        try{
            set<Id> batchIds = new set<Id>();

            list<Payment_Adjustment__c> oldPayments = (list<Payment_Adjustment__c>)state.OldList;
            list<Payment_Adjustment__c> newPayments = (list<Payment_Adjustment__c>)state.NewList;

            if(newPayments != null && newPayments.size() > 0){
                for(Payment_Adjustment__c curPayAdj : newPayments){
                    if(String.isNotBlank(curPayAdj.Batch__c)){
                        batchIds.add(curPayAdj.Batch__c);
                    }
                }
            }

            if(oldPayments != null && oldPayments.size() > 0){
                for(Payment_Adjustment__c curPayAdj : oldPayments){
                    if(String.isNotBlank(curPayAdj.Batch__c)){
                        batchIds.add(curPayAdj.Batch__c);
                    }
                }
            }

            list<Batch__c> batch = [SELECT Id FROM Batch__c WHERE Id IN :batchIds];
            update batch;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            UtilitiesErrors.SendErrorEmailASYNC(qe.getMessage() + ' ' + qe.getLineNumber());
        }
        catch(DmlException de){
            system.debug(de.getMessage());
            UtilitiesErrors.SendErrorEmailASYNC(de.getMessage() + ' ' + de.getLineNumber());
        }
    }


    @TestVisible private void runFiscalYearCalculations(list<Payment_Adjustment__c> payments){

        list<Account> accountsToUpdate = new list<Account>();
        set<Id> accIds = new set<Id>();
        for(Payment_Adjustment__c curPayment : payments){
            if(String.isNotBlank(curPayment.Household__c))
                accIds.add(curPayment.Household__c);
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

}