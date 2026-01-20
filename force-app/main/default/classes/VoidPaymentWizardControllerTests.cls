/**
 * Created by cgibs on 3/15/2018.
 */
@IsTest
public with sharing class VoidPaymentWizardControllerTests {

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

        VoidPaymentWizardController voidController = new VoidPaymentWizardController(stdController);

        voidController.SearchPayments();
        voidController.DisplayPaymentSearch = true;
        voidController.createPaymentAdjustmentWrapper();
        

    }
}