/**
 * Created by Chris Home Desktop on 2/13/2018.
 */
@IsTest
public with sharing class ExportController_Tests {

    @testSetup
    static void setupData(){

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

        Batch__c curBatch = new Batch__c();
        curBatch.Deposit_ID__c = 'test1234';
        insert curBatch;
        update curBatch;

        Payment_Adjustment__c payment = new Payment_Adjustment__c();
        payment.Household__c = financialTestScenario.accounts[0].Id;
        payment.Status__c = 'Un-Transferred';
        payment.Amount__c = 2;
        payment.Batch__c = curBatch.Id;
        insert payment;

        Payment_Adjustment_Allocation__c alloc = new Payment_Adjustment_Allocation__c();
        alloc.Payment_Adjustment__c = payment.Id;
        alloc.Scheduled_Payment__c = schedP.Id;
        alloc.Amount__c = 2;
        insert alloc;
    }

    @IsTest public static void ProcessTestCoverage(){

        ExportController ec = new ExportController();
        ec.exportPaymentsToExcel();
        ec.ExportAssessmentsToExcel();

        ExportController.ExportWrapper wrap = new ExportController.ExportWrapper();
        wrap.ActionDate = 'test';
        wrap.ReferenceNumber = 'test';
        wrap.NumberOfDistributions = 'test';
        wrap.GLAccount = 'test';
        wrap.Description = 'test';
        wrap.Amount = 'test';
        wrap.RecurNumber = 'test';
        wrap.RecurFrequency = 'test';

        ec.isExcel = true;
        ec.isCsv = true;
    }


}