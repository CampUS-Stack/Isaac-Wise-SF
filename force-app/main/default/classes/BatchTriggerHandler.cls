/**
 * Created by Chris Home Desktop on 11/5/2017.
 */

public with sharing class BatchTriggerHandler implements TriggerHandler.ITrigger{

    private Boolean hasExecuted {get; set;}

    public BatchTriggerHandler() {}

    public void MainEntry(TriggerState state){

        system.debug('Batch Trigger Handler Main Entry Called.');
        system.debug('Firing object: ' + state.TriggerObject);

        if(state.IsUpdate){
            if(state.IsBefore){
                processBeforeUpdate(state);
            }
        }

    }

    public void InProgressEntry(TriggerState state){


        if(state.TriggerObject != 'Batch__c'){
            return;
        }

        if(state.IsUpdate){
            if(state.IsBefore){
                processBeforeUpdate(state);
            }
        }

    }

    @TestVisible private void handleTriggerFromPayment(TriggerState state){

        system.debug('Running Batch update from Payment_Adjustment__c trigger');
        if(!this.hasExecuted){
            if(state.IsAfter){
                calculateSumOfTransactions(state);
                BatchStatusUpdateController.ProcessStatusUpdates((list<Batch__c>)state.NewList);
            }
        }
        this.hasExecuted = true;
    }

    @TestVisible private void processBeforeUpdate(TriggerState state){

        calculateSumOfTransactions(state);
        BatchStatusUpdateController.ProcessStatusUpdates((list<Batch__c>)state.NewList);

    }


    @TestVisible private void calculateSumOfTransactions(TriggerState state){
        if(state.NewList.size() != 1){
            return;
        }

        try{
            list<Payment_Adjustment__c> paymentAdjustments = [SELECT Id,Amount_Disbursed__c,Amount__c FROM Payment_Adjustment__c WHERE Batch__c = :state.NewList[0].Id];
            Decimal sumOfPayments = 0.0;
            Decimal sumOfAmounts = 0.0;
            for(Payment_Adjustment__c curPA : paymentAdjustments){
                if(curPA.Amount_Disbursed__c != null){
                    sumOfPayments += curPA.Amount_Disbursed__c;
                }
                if(curPA.Amount__c != null){
                    sumOfAmounts += curPA.Amount__c;
                }
            }

            Batch__c theBatch = ((Batch__c)state.NewList[0]);
            theBatch.Sum_of_Transaction__c = sumOfPayments;
            theBatch.Sum_of_Amount__c = sumOfAmounts;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
        }
    }
}