/**
 * Created by Chris Home Desktop on 2/13/2018.
 */
@IsTest
public with sharing class BatchInvoiceControllerTests {

    @TestSetup public static void RunTestSetup(){

        list<Account> accounts = TestObjectFactory.CreateAccounts('Test',1);
        insert accounts;

        list<Designation__c> designations = TestObjectFactory.CreateDesignations('test',1);
        designations[0].Is_Credit_Account__c = true;
        insert designations;

        list<Assessment__c> assessments = TestObjectFactory.CreateAssessments(1,2.0);
        assessments[0].Account__c = accounts[0].Id;
        assessments[0].Designation__c = designations[0].Id;
        insert assessments;
    }

    @IsTest public static void RunStandardControllerTests(){

        list<Account> accounts = [SELECT ID FROM Account];

        ApexPages.StandardController stdController = new ApexPages.StandardController(accounts[0]);
        BatchInvoiceController bicsc = new BatchInvoiceController(stdController);

        bicsc.CreateNewAssessment();
        bicsc.ClearFields();
        bicsc.runValidation();
        bicsc.getAssessments(accounts[0].Id);
        bicsc.runSearch(accounts[0].Id);
    }

    @IsTest public static void RunTests(){

        list<Account> accounts = [SELECT ID FROM Account];

        BatchInvoiceController bic = new BatchInvoiceController();
        bic.CreateNewAssessment();
        bic.ClearFields();
        bic.runValidation();
        bic.getAssessments(accounts[0].Id);
        bic.runSearch(accounts[0].Id);

    }
}