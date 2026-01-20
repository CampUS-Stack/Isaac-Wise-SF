/**
 *  @Author Chris Gibson
 *  @Date 12.2.2017
 *
 *  @description This is the 0 param constructor for the BatchInvoice pages.
 *
 */
public with sharing class BatchInvoiceController {

    public Account TheAccount {get; set;}
    public Assessment__c MasterAssessment {get; set;}
    public list<Assessment__c> TheAssessments {get; set;}

    /**
     *  @Author Chris Gibson
     *  @Date 12.2.2017
     *
     *  @description This is the 1 param constructor for the BatchInvoiceAccount page controller. This constructor is used for the BatchInvoiceAccount page and is
     *                  intended for use with the Account StandardController
     *
     *  @param stdControllerToSet = ApexPages.StandardController object representing the Account record to invoice against.
     *
     */
    public BatchInvoiceController(ApexPages.StandardController stdControllerToSet) {

        String accountID = stdControllerToSet.getId();
        this.MasterAssessment = new Assessment__c();
        runSearch(accountID);
    }

    /**
     *  @Author Chris Gibson
     *  @Date 12.2.2017
     *
     *  @description This is the 0 param constructor for the BatchInvoiceAssessment page.
     *
     */
    public BatchInvoiceController(){}

    public PageReference CreateNewAssessment(){

        if(!runValidation()){
            return null;
        }

        try{
            MasterAssessment.Account__c = this.TheAccount.Id;
            insert MasterAssessment;
            runSearch(this.TheAccount.Id);
            MasterAssessment = new Assessment__c();
            return null;
        }
        catch(DmlException de){
            system.debug(de.getMessage());
            return null;
        }
    }
    public PageReference ClearFields(){

        MasterAssessment = new Assessment__c();
        return null;
    }

    @TestVisible private Boolean runValidation(){

        Boolean returnValue = true;

        if(this.MasterAssessment.Assessed_Amount__c == null ){
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'You must enter an Assessed Amount.'));
            returnValue = false;
        }
        if(String.isEmpty(this.MasterAssessment.Designation__c)){
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'You must choose a designation to be assessed.'));
            returnValue = false;
        }
        if(this.MasterAssessment.Assessment_Date__c == null){
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'You must enter an Assessment Date.'));
            returnValue = false;
        }

        return returnValue;

    }

    @TestVisible private void runSearch(String accountId){

        this.TheAccount = getAccount(accountID);
        this.TheAssessments = getAssessments(accountID);
    }


    @TestVisible private Account getAccount(String accountId){
        try{
            Account returnAcc = [SELECT ID,Name,Assessed_Amount__c FROM Account WHERE Id = :accountId];
            return returnAcc;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return null;
        }
    }

    @TestVisible private list<Assessment__c> getAssessments(String accountId){
        try{
            list<Assessment__c> returnList = [SELECT ID,Designation__r.Name,Assessment_Date__c,Assessed_Amount__c,Description__c FROM Assessment__c WHERE Account__c = :accountId ORDER BY Assessment_Date__c DESC NULLS LAST];
            return returnList;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return null;
        }
    }


}