/**
 * Created by Chris Home Desktop on 2/13/2018.
 */
@IsTest
public with sharing class BatchInvoiceAssessmentControllerTests {

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


    @IsTest public static void ProcessTestCoverage(){

        list<Account> accounts = [SELEcT Id FROM Account];
        list<Assessment__c> assessments = [SELECT Id FROM Assessment__c];

        BatchInvoiceAssessmentController biac = new BatchInvoiceAssessmentController();

        biac.ChosenSearchType = 'All';
        biac.RunAccountQuery();

        biac.SelectedAccountIdToRemove = accounts[0].Id;
        biac.SelectedAccountId = accounts[0].Id;

        biac.AddBackToAll();
        biac.RemoveFromAll();


    }
}