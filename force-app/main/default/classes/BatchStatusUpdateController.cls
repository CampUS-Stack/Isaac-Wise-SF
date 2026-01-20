/**
 * Created by Chris Home Desktop on 1/28/2018.
 */

public with sharing class BatchStatusUpdateController {

    public static void ProcessStatusUpdates(list<Batch__c> batches){

        try{
            map<Id,Batch__c> batchMap = new map<Id,Batch__c>(batches);
            map<Id,list<Payment_Adjustment__c>> paymentByBatches = mapPaymentsByBatches(batchMap.keySet());

            for(Batch__c curBatch : batchMap.values()){
                if(!paymentByBatches.containsKey(curBatch.Id)){
                    continue;
                }

                if(checkForAllTransferredPayments(paymentByBatches.get(curBatch.Id))){
                    curBatch.Status__c = 'Transferred';
                }
                else if(!checkForUnSummarizedPayments(paymentByBatches.get(curBatch.Id))){
                    curBatch.Status__c = 'Summarized';
                }
            }
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
        }
    }

    @TestVisible private static Boolean checkForUnSummarizedPayments(list<Payment_Adjustment__c> payments){

        for(Payment_Adjustment__c curPayment : payments){
            system.debug(curPayment.Status__c);
            if(curPayment.Status__c == 'Un-Summarized'){
                return true;
            }
        }
        return false;
    }

    @TestVisible private static Boolean checkForAllTransferredPayments(list<Payment_Adjustment__c> payments){

        for(Payment_Adjustment__c curPayment : payments){
            system.debug(curPayment.Status__c);
            if(curPayment.Status__c != 'Transferred'){
                return false;
            }
        }
        return true;
    }

    @TestVisible private static map<Id,list<Payment_Adjustment__c>> mapPaymentsByBatches(set<Id> batchIds){

        try{
            map<Id,list<Payment_Adjustment__c>> returnMap = new map<Id,list<Payment_Adjustment__c>>();
            list<Payment_Adjustment__c> payments = [SELECT Id,Status__c,Batch__c FROM Payment_Adjustment__c WHERE Batch__c in :batchIds];

            for(Payment_Adjustment__c curPayment : payments){

                if(returnMap.containsKey(curPayment.Batch__c)){
                    returnMap.get(curPayment.Batch__c).add(curPayment);
                }
                else{
                    returnMap.put(curPayment.Batch__c,new list<Payment_Adjustment__c>{curPayment});
                }
            }

            return returnMap;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return null;
        }
    }

}