/**
 * Created by Kritik Garg on 02-06-2020.
 */
@isTest
public with sharing class AssessmentAllocationsControllerTest {

    @TestSetup private static void SetupTest(){

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


        list<Designation__c> designations = [SELECT Id FROM Designation__c];
        list<Assessment__c> assessments = [SELECT Id FROM Assessment__c];
        Payment_Adjustment__c payAdj = [SELECT Id FROM Payment_Adjustment__c LIMIT 1];


        Credit_Allocation__c ca = new Credit_Allocation__c();
        ca.Assessment__c = assessments.get(0).Id;
        ca.Payment_Adjustment__c = payAdj.Id;
        insert ca;

        Batch__c theBatch = [SELECT Id FROM Batch__c LIMIT 1];

        AssessmentAllocationsController.getAssessments(assessments.get(0).Id);
        AssessmentAllocationsController.getCreditAllocationsFromAssessment(assessments.get(0).Id);
        AssessmentAllocationsController.getPaymentAllocationsFromAssessment(assessments.get(0).Id);

    }

}