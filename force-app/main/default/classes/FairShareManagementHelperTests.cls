/**
 * Created by cgibs on 12/19/2023.
 */

@IsTest
private class FairShareManagementHelperTests {

    @TestSetup
    static void SetupTests() {

        TestObjectFactory.FinancialTestScenario fs = TestObjectFactory.GetFinancialTestScenario();


        insert fs.accounts;
        fs.contacts[0].AccountId = fs.accounts[0].Id;
        fs.contacts[1].AccountId = fs.accounts[1].Id;
        insert fs.contacts;
        insert fs.designations;
        fs.assessments[0].Designation__c = fs.designations[0].Id;
        fs.assessments[1].Designation__c = fs.designations[1].Id;
        fs.assessments[0].Account__c = fs.accounts[0].Id;
        fs.assessments[1].Account__c = fs.accounts[0].Id;
        insert fs.assessments;
        fs.scheduledPayments = TestObjectFactory.CreateObjectsWithName(Scheduled_Payment__c.SObjectType,2);
        fs.scheduledPayments[0].Assessment__c = fs.assessments[0].Id;
        fs.scheduledPayments[1].Assessment__c = fs.assessments[1].Id;
        insert fs.scheduledPayments;

        
        List<Assessment__c> newFSAssessments = TestObjectFactory.CreateAssessments(2,300);
        List<Fair_Share__c> fairShares = TestObjectFactory.CreateFairShare(2);
        fairShares[0].Account__c = fs.accounts[0].Id;
        fairShares[0].Fiscal_Year__c = '2022-2023';
        fairShares[0].Membership_Assessment__c = fs.assessments[0].Id;
        fairShares[0].Membership_Contribution__c = 200.00;
        fairShares[0].PST_Assessment__c = fs.assessments[1].Id;
        fairShares[0].PST__c = 200.00;
        insert fairShares[0];

        fairShares[1].Account__c = fs.accounts[0].Id;
        fairShares[1].Fiscal_Year__c = '2023-2024';
        fairShares[1].Membership_Assessment__c = newFSAssessments[0].Id;
        fairShares[1].Membership_Contribution__c = 200.00;
        fairShares[1].PST_Assessment__c = newFSAssessments[1].Id;
        fairShares[1].PST__c = 200.00;
        fairShares[1].Last_Year_Fair_Share__c = fairShares[0].Id;
        insert fairShares[1];

    }

    @IsTest
    public static void testFairShareRecordsReturn(){

        FairShareManagementHelper.FairShareWrapper wrappers = FairShareManagementHelper.getFairShareInformation('2023-2024','2022-2023','Test');

    }
}