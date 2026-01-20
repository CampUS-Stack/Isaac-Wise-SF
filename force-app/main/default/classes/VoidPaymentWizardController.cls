/**
 * Created by cgibs on 3/15/2018.
 */
public with sharing class VoidPaymentWizardController {

    public static String BATCH_SOQL_FIELDS = 'Id,Name,Default_Payment_Method__c,Deposit_ID__c,Batch_Date__c,Transaction_Type__c,Sum_of_Transaction__c';

    public String batchId {get; set;}
    public Batch__c batch {get; set;}

    public list<PaymentAdjustmentWrapper> PaymentAdjustmentWrappers {get; set;}

    public Contact DummyContact {get; set;}

    public Boolean DisplayPaymentSearch {get; set;}

    public VoidPaymentWizardController(ApexPages.StandardController stdController){

        this.batchId = stdController.getId();
        this.batch = getBatch(this.batchId);

        this.DummyContact = new Contact();
        this.DisplayPaymentSearch = true;
    }

    public PageReference SearchPayments(){

        this.PaymentAdjustmentWrappers = createPaymentAdjustmentWrapper();

        return null;
    }

    public PageReference VoidPayments(){

        list<Payment_Adjustment__c> updatePayments = new list<Payment_Adjustment__c>();
        list<Payment_Adjustment__c> insertPayments = new list<Payment_Adjustment__c>();
        map<Id,Payment_Adjustment__c> newVoidPaymentByOldPayment = new map<Id,Payment_Adjustment__c>();
        for(PaymentAdjustmentWrapper curWrap : PaymentAdjustmentWrappers){
            if(curWrap.isSelected){
                curWrap.PaymentAdjustment.Type__c = 'Void';
                curWrap.PaymentAdjustment.RecordTypeId = UtilitiesSObject.getRecordTypeId('Void',Payment_Adjustment__c.SObjectType);

                Payment_Adjustment__c voidPayment = new Payment_Adjustment__c();
                voidPayment.Status__c = 'Un-Transferred';
                voidPayment.RecordTypeId = UtilitiesSObject.getRecordTypeId('Void',Payment_Adjustment__c.SObjectType);
                voidPayment.Batch__c = this.batchId;
                voidPayment.Amount__c = curWrap.PaymentAdjustment.Amount__c * -1;
                voidPayment.Household__c = this.DummyContact.AccountId;
                voidPayment.Check_Date__c = curWrap.PaymentAdjustment.Check_Date__c;
//                voidPayment.Batch__c = curWrap.PaymentAdjustment.Batch__c;
                voidPayment.Batch__c = batchId;
                voidPayment.Deposit_ID_Override__c = curWrap.PaymentAdjustment.Batch__r.Deposit_ID__c;
                voidPayment.Paid_by_Household__c = curWrap.PaymentAdjustment.Paid_by_Household__c;
                updatePayments.add(curWrap.PaymentAdjustment);
                insertPayments.add(voidPayment);
                newVoidPaymentByOldPayment.put(curWrap.PaymentAdjustment.Id,voidPayment);
            }
        }
        map<Id,Payment_Adjustment__c> paymentMap = new map<Id,Payment_Adjustment__c>(updatePayments);
        list<Payment_Adjustment_Allocation__c> allocationsToUpdate = getPaymentAdjustmentAllocations(paymentMap.keySet());

        try{
            update updatePayments;
            insert insertPayments;
        }
        catch(DmlException de){
            system.debug(de.getMessage());
            UtilitiesErrors.SendErrorEmailASYNC(de.getMessage() + ' <br/> ' + de.getLineNumber());
        }

        list<Payment_Adjustment_Allocation__c> allocationsToInsert = new list<Payment_Adjustment_Allocation__c>();

        for(Payment_Adjustment_Allocation__c curAlloc :allocationsToUpdate){
            Payment_Adjustment_Allocation__c voidAlloc = new Payment_Adjustment_Allocation__c();
            voidAlloc.Payment_Adjustment__c = newVoidPaymentByOldPayment.get(curAlloc.Payment_Adjustment__c).Id;
            voidAlloc.Type__c = 'Void';
            voidAlloc.Amount__c = curAlloc.Amount__c * -1;
            voidAlloc.Scheduled_Payment__c = curAlloc.Scheduled_Payment__c;
            curAlloc.RecordTypeId = UtilitiesSObject.getRecordTypeId('Void',Payment_Adjustment_Allocation__c.SObjectType);
            curAlloc.Type__c = 'Void';
            voidAlloc.RecordTypeId = curAlloc.RecordTypeId;
            allocationsToInsert.add(voidAlloc);
        }

        try{
            update allocationsToUpdate;
            insert allocationsToInsert;
        }
        catch(DmlException de){
            system.debug(de.getMessage());
            UtilitiesErrors.SendErrorEmailASYNC(de.getMessage() + ' <br/> ' + de.getLineNumber());
        }

        PageReference pr = new PageReference('/' + this.DummyContact.AccountId);
        pr.setRedirect(true);
        return pr;
    }



    @TestVisible private Batch__c getBatch(String batchId){
        try{
            String soql = 'SELECT ' + BATCH_SOQL_FIELDS + ' FROM Batch__c WHERE Id = :batchId';
            Batch__c returnBatch = Database.query(soql);
            return returnBatch;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return null;
        }
    }

    @TestVisible private list<Payment_Adjustment__c> getPaymentAdjustment(){
        Date filterDate = Date.today().addYears(-1);
        try{
            list<Payment_Adjustment__c> returnList = [
                    SELECT Id,Name,Check_Date__c,Amount__c,Batch__r.Deposit_ID__c,Household__c,Paid_by_Household__c,Batch__c
                    FROM Payment_Adjustment__c
                    WHERE Household__c = :DummyContact.AccountId
                    AND RecordType.DeveloperName = 'Payment'
                    AND CreatedDate > :filterDate
                    ORDER By Check_Date__c DESC
            ];
            return returnList;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return null;
        }
    }

    @TestVisible private list<Payment_Adjustment_Allocation__c> getPaymentAdjustmentAllocations(set<Id> paymentIds){
        try{
            list<Payment_Adjustment_Allocation__c> returnList = [SELECT Id,RecordTypeId,Type__c,Payment_Adjustment__c,Scheduled_Payment__c,Amount__c FROM Payment_Adjustment_Allocation__c WHERE Payment_Adjustment__c in :paymentIds];
            return returnList;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return null;
        }
    }

    @TestVisible private list<PaymentAdjustmentWrapper> createPaymentAdjustmentWrapper(){

        list<PaymentAdjustmentWrapper> returnList = new list<PaymentAdjustmentWrapper>();
        list<Payment_Adjustment__c> paymentAdjustments = getPaymentAdjustment();

        for(Payment_Adjustment__c curPayAdj : paymentAdjustments){
            PaymentAdjustmentWrapper curWrap = new PaymentAdjustmentWrapper();
            curWrap.PaymentAdjustment = curPayAdj;
            returnList.add(curWrap);
        }

        return returnList;
    }

    public class PaymentAdjustmentWrapper{

        public Payment_Adjustment__c PaymentAdjustment {get; set;}
        public Boolean isSelected {get; set;}

        public PaymentAdjustmentWrapper(){
            this.isSelected = false;
        }
    }
}