/**
 * Created by Chris Home Desktop on 7/7/2018.
 */

@IsTest
private class FY_AccountBalanceCalcTests {


    @TestSetup static void SetupTest(){

        list<Account> accounts = TestObjectFactory.CreateAccounts('test',2);
        insert accounts;

        list<Designation__c> designations = TestObjectFactory.CreateDesignations('Test Des',2);
        insert designations;

        list<Assessment__c> assessments = TestObjectFactory.CreateAssessments(2,10);
        assessments[0].Account__c = accounts[0].Id;
        assessments[1].Account__c = accounts[1].Id;
        assessments[0].Designation__c = designations[0].Id;
        assessments[1].Designation__c = designations[1].Id;
        assessments[0].Assessment_Date__c = date.today().addMonths(-2);
        assessments[1].Assessment_Date__c = date.today().addMonths(-2);
        insert assessments;
    }

    static testMethod void testBehavior() {

        list<Account> accounts = [SELECT Id FROM Account];
        FY_AccountBalanceCalc fyCalcCtrl = new FY_AccountBalanceCalc(accounts);
        fyCalcCtrl.RunAllCalculations();

    }
}