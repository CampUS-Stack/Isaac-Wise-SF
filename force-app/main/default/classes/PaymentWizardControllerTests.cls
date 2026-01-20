/**
 * Created by Chris Home Desktop on 11/12/2017.
 */
@IsTest
public with sharing class PaymentWizardControllerTests {

    @testSetup
    static void setupData(){

        TestObjectFactory.FinancialTestScenario financialTestScenario = TestObjectFactory.GetFinancialTestScenario();

        insert financialTestScenario.accounts;
        insert financialTestScenario.contacts;
        insert financialTestScenario.designations;

        for(Assessment__c curAssess: financialTestScenario.assessments){
            curAssess.Account__c = financialTestScenario.accounts[0].Id;
        }

        insert financialTestScenario.assessments;

        Batch__c curBatch = new Batch__c();
        insert curBatch;
        update curBatch;

        Payment_Adjustment__c payment = new Payment_Adjustment__c();
        payment.Household__c = financialTestScenario.accounts[0].Id;
        insert payment;
    }


    @IsTest public static void ProcessTestCoverage(){

        list<Account> accounts = [SELECT Id FROM Account];
        list<Contact> contacts = [SELEcT Id FROM Contact];
        list<Designation__c> designations = [SELECT Id FROM Designation__c];
        list<Assessment__c> assessments = [SELECT Id FROM Assessment__c];
        Batch__c theBatch = [SELECT Id FROM Batch__c LIMIT 1];
        Payment_Adjustment__c payAdj = [SELECT Id FROM Payment_Adjustment__c LIMIT 1];

        ApexPages.StandardController stdController = new ApexPages.StandardController(theBatch);

        PaymentWizardController pwController = new PaymentWizardController(stdController);

        pwController.SearchAssessments();

        pwController.SaveAndContinue();
        pwController.SaveAndExit();
        pwController.SaveAndSummarize();

        Object obj = pwController.stdController;
        obj = pwController.DummyContact;
        obj = pwController.CurrentYearAccountBalance;
        obj =  pwController.batch;
        obj = pwController.batchId;

        pwController.AddNewAssessment();
        pwController.ProcessAutoPay();
        pwController.GoBackToBatch();
        pwController.GoToSummarizePayments();

//        pwController.ProcessPaymentSubmission();
//        pwController.GoBackToBatch();
//        pwController.GoToSummarizePayments();
//        pwController.ProcessAutoPay();
//        pwController.AddNewAssessment();
//
//
//        pwController.getAssessments(accounts[0].Id);
//        pwController.getBatch(theBatch.Id);

    }
}