/**
 * Created by Chris Home Desktop on 2/14/2018.
 */
@IsTest
public with sharing class ModifyPaymentControllerTests {


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

        list<Account> accounts = [SELECT Id FROM Account];
        list<Contact> contacts = [SELEcT Id FROM Contact];
        list<Designation__c> designations = [SELECT Id FROM Designation__c];
        list<Assessment__c> assessments = [SELECT Id FROM Assessment__c];
        Batch__c theBatch = [SELECT Id FROM Batch__c LIMIT 1];
        Payment_Adjustment__c payAdj = [SELECT Id,Amount__c FROM Payment_Adjustment__c LIMIT 1];

        ModifyPaymentController modifyPaymentController = new ModifyPaymentController();

        modifyPaymentController.SearchForAssessments();
        modifyPaymentController.SearchForPayments();
        modifyPaymentController.ProcessAutoPay();
        modifyPaymentController.PaymentToTransfer = new ModifyPaymentController.PaymentWrapper();
        modifyPaymentController.PaymentToTransfer.Payment = payAdj;
        modifyPaymentController.PaymentToTransfer.Allocations = [SELECT Id,Amount__c FROM Payment_Adjustment_Allocation__c];
        modifyPaymentController.Save();
        modifyPaymentController.AddNewAssessment();
        modifyPaymentController.DisplayReassignmentArea();
        modifyPaymentController.GetAssessmentsFromPayment();
        modifyPaymentController.getTotalOfAllocationAmounts([SELECT Id,Amount__c FROM Payment_Adjustment_Allocation__c]);



        set<Id> wrapperIds = modifyPaymentController.wrapperIds;
        modifyPaymentController.SuccessMessage = 'pass';


    }

}