/**
 * Created by Chris Home Desktop on 12/15/2017.
 */

public with sharing class EditBatchPaymentController {

    public list<Payment_Adjustment__c> Payments {get; set;}
    /// Allocation functionality variables
    public list<PaymentAllocationWrapper> PaymentAllocations {get; set;}
    public list<Assessment__c> AssessmentsForNewAllocation {get; set;}

    public Boolean ShowPaymentTransfer {get; set;}
    public Boolean ShowPaymentReallocation {get; set;}
    public Boolean ShowPaymentReallocationNewAllocation {get; set;}

    public String SelectedPaymentId {get; set;}
    public Payment_Adjustment__c SelectedPayment {get; set;}
    public String SelectedAssessmentIdForNewAllocation {get; set;}

    public String batchID {Get; set;}

    public EditBatchPaymentController(){
        this.batchID = getBatchIdFromParam();
        this.Payments = getPayments(batchId);
        this.PaymentAllocations = new list<PaymentAllocationWrapper>();
        ShowPaymentReallocation = false;
        ShowPaymentTransfer = false;
        ShowPaymentReallocationNewAllocation = false;
    }

    public PageReference Save(){

        if(!runValidation()){
            return null;
        }

        try{
            list<Payment_Adjustment_Allocation__c> allocs = getListOfAccountFromWrappers(PaymentAllocations);
            upsert allocs Id;
        }
        catch (DmlException de){
            system.debug(de.getMessage());
            UtilitiesErrors.CreateErrorLog(de.getMessage(),de.getStackTraceString(),de.getLineNumber(),UserInfo.getUserId());
        }

        PageReference pr = new PageReference('/' + this.batchID);
        pr.setRedirect(true);
        return pr;

    }

    @TestVisible private Boolean runValidation(){

        if(SelectedPayment == null){
            return false;
        }

        Decimal totalPaymentAmount = 0.00;
        for(PaymentAllocationWrapper curWrap : this.PaymentAllocations){
            if(curWrap.allocation.Amount__c > 0){
                totalPaymentAmount += curWrap.allocation.Amount__c;
            }
        }

        if(totalPaymentAmount != SelectedPayment.Amount__c){
            /// todo page messages here
            return false;
        }

        return true;

    }

    public PageReference ShowPaymentTransferBlock(){
        selectPayment();
        this.PaymentAllocations = getAllocationWrappers(SelectedPaymentId);
        ShowPaymentTransfer = true;
        return null;
    }
    public PageReference BackFromPaymentTransfer(){
        ShowPaymentTransfer = false;
        return null;
    }

    public PageReference ShowPaymentReAllocationBlock(){
        selectPayment();
        this.PaymentAllocations = getAllocationWrappers(SelectedPaymentId);
        ShowPaymentReallocation = true;
        return null;
    }
    public PageReference BackFromPaymentReAllocation(){
        ShowPaymentReallocation = false;
        return null;
    }

    public PageReference ShowPaymentReAllocationNewAllocationBlock(){
        if(SelectedPayment == null){
            return null;
        }
        selectPayment();
        this.AssessmentsForNewAllocation = getAssessments(SelectedPayment.Household__c);
        ShowPaymentReallocationNewAllocation = true;
        return null;
    }

    public PageReference SelectNewAllocationAssessment(){

        Scheduled_Payment__c schedPayment = getScheduledPayment(SelectedAssessmentIdForNewAllocation);

        Payment_Adjustment_Allocation__c alloc = new Payment_Adjustment_Allocation__c();
        alloc.Scheduled_Payment__c = schedPayment.Id;
        alloc.Payment_Adjustment__c = SelectedPayment.Id;
        alloc.RecordTypeId = UtilitiesSObject.getRecordTypeId(SelectedPayment.RecordType.DeveloperName,Payment_Adjustment_Allocation__c.SObjectType);
        alloc.Type__c = SelectedPayment.Type__c;
        alloc.Batch__c = SelectedPayment.Batch__c;

        PaymentAllocationWrapper wrapper = new PaymentAllocationWrapper(alloc);
        wrapper.DesignationName = schedPayment.Assessment__r.Designation__r.Name;

        this.PaymentAllocations.add(wrapper);

        this.ShowPaymentReallocationNewAllocation = false;
        this.AssessmentsForNewAllocation = new list<Assessment__c>();

        return null;

    }

    @TestVisible private void selectPayment(){
        for(Payment_Adjustment__c curPay : this.Payments){
            if(curPay.Id == this.SelectedPaymentId){
                this.SelectedPayment = curPay;
                break;
            }
        }
    }

    @TestVisible private list<Payment_Adjustment__c> getPayments(String batchID){


        try{
            list<Payment_Adjustment__c> returnList = [SELECT Id,Name,Household__c,Amount__c,Date_of_Action__c,RecordType.DeveloperName,Type__c,Batch__c  FROM Payment_Adjustment__c WHERE Batch__c = :batchID];
            return returnList;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return null;
        }
    }

    @TestVisible private list<PaymentAllocationWrapper> getAllocationWrappers(String paymentId){
        list<PaymentAllocationWrapper> returnList = new list<PaymentAllocationWrapper>();
        list<Payment_Adjustment_Allocation__c> allocationsToWrap = getAllocations(paymentId);
        for(Payment_Adjustment_Allocation__c curAlloc : allocationsToWrap){
            PaymentAllocationWrapper wrap = new PaymentAllocationWrapper(curAlloc);
            returnList.add(wrap);
        }
        return returnList;
    }

    @TestVisible private list<Payment_Adjustment_Allocation__c> getListOfAccountFromWrappers(list<PaymentAllocationWrapper> allocationWrappers){
        list<Payment_Adjustment_Allocation__c> allocs = new list<Payment_Adjustment_Allocation__c>();

        for(PaymentAllocationWrapper curWrap : allocationWrappers){
            allocs.add(curWrap.allocation);
        }
        return allocs;
    }

    @TestVisible private list<Payment_Adjustment_Allocation__c> getAllocations(String paymentId){
        try{
            list<Payment_Adjustment_Allocation__c> allocations = [SELECT Id,Scheduled_Payment__r.Assessment__r.Designation__r.Name,Amount__c  FROM Payment_Adjustment_Allocation__c WHERE Payment_Adjustment__c = :paymentId];
            return allocations;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return null;
        }
    }

    @TestVisible private list<Assessment__c> getAssessments(String accountId){
        try{
            list<Assessment__c> assessments = [SELECT Id,Designation__r.Name,Assessment_Date__c,Assessed_Amount__c,Remaining_Balance__c  FROM Assessment__c WHERE Account__c = :accountId AND Remaining_Balance__c > 0];
            return assessments;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return null;
        }
    }

    @TestVisible private Scheduled_Payment__c getScheduledPayment(String assessmentId){
        try{
            Scheduled_Payment__c schedPayment = [SELECT Id,Assessment__r.Designation__r.Name FROM Scheduled_Payment__c WHERE Assessment__c = :assessmentId];
            return schedPayment;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return null;
        }
    }


    @TestVisible public String getBatchIdFromParam(){
        if(ApexPages.currentPage().getParameters().containsKey('id')){
            return ApexPages.currentPage().getParameters().get('id');
        }
        else{
            return '';
        }
    }

    public class PaymentAllocationWrapper{

        public Payment_Adjustment_Allocation__c allocation {get; set;}
        public Assessment__c DummyAssessment {get; set;}
        public String DesignationName {get; set;}

        public PaymentAllocationWrapper(Payment_Adjustment_Allocation__c allocationToSet){
            allocation = allocationToSet;
            if(allocation == null || allocation.Scheduled_Payment__c == null || allocation.Scheduled_Payment__r.Assessment__c == null || allocation.Scheduled_Payment__r.Assessment__r.Designation__c == null){
                return;
            }
            DummyAssessment = new Assessment__c();
            DummyAssessment.Designation__c = allocation.Scheduled_Payment__r.Assessment__r.Designation__c;
            DesignationName = allocation.Scheduled_Payment__r.Assessment__r.Designation__r.Name;
        }
    }



}