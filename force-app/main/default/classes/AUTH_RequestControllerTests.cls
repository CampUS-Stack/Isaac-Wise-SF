/**
 * Created by Chris Home Desktop on 7/7/2018.
 */
@IsTest
public with sharing class AUTH_RequestControllerTests {

    @TestSetup public static void SetupTest (){

        TestObjectFactory.FinancialTestScenario financialTestScenario = TestObjectFactory.GetFinancialTestScenario();

        insert financialTestScenario.accounts;
        insert financialTestScenario.contacts;
        insert financialTestScenario.designations;

        for(Assessment__c curAssess: financialTestScenario.assessments){
            curAssess.Account__c = financialTestScenario.accounts[0].Id;
            curAssess.Designation__c = financialTestScenario.designations[0].Id;
        }

        insert financialTestScenario.assessments;

        Scheduled_Payment__c schedP = new Scheduled_Payment__c();
        schedP.Assessment__c = financialTestScenario.assessments[0].Id;
        schedP.Expected_Amount__c = financialTestScenario.assessments[0].Assessed_Amount__c;
        insert schedP;

        Payment_Adjustment__c payment = new Payment_Adjustment__c();
        payment.Household__c = financialTestScenario.accounts[0].Id;
        payment.Status__c = 'Un-Transferred';
        payment.Amount__c = 2;
        insert payment;

        Payment_Adjustment_Allocation__c alloc = new Payment_Adjustment_Allocation__c();
        alloc.Payment_Adjustment__c = payment.Id;
        alloc.Amount__c = 2;
        insert alloc;
    }

    @TestVisible private static void ProcessTestCoverage(){

        Payment_Adjustment__c thePayment = [SELECT Id FROM Payment_Adjustment__c limit 1];
        Contact theContact = [SELECT Id FROM Contact limit 1];

        AUTH_RequestController requestCtrl = new AUTH_RequestController();

        requestCtrl.SubmitForMemberPaymentURL(2.00,theContact.Id,thePayment.Id);
        requestCtrl.GetURLTokenForMember(2.00,theContact.Id,thePayment.Id);
    }
}