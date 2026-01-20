/**
 * Created by Kritik Garg on 06-03-2019.
 */

@IsTest
private class CongrComm_DonationsGuestCtrlTest {

    @testSetup
    static  void testBehavior() {

        List<Account> accountList1 = TestObjectFactory.CreateAccounts('TestAccount', 2);
        accountList1.get(0).Membership_Start_Date__c =  Date.today().addDays(-1);
        accountList1.get(0).Membership_End_Date__c =  Date.today().addDays(1);

        insert accountList1;

        insert new Important_Accounts__c(Name='Wise Temple Guest Account',Account_ID__c = accountList1[0].Id);

        list<Designation__c> designations = TestObjectFactory.CreateDesignations('test',2);
        designations[0].Display_Fund_on_Portal__c = true;
        designations[1].Display_Fund_on_Portal__c = true;
        designations[0].Display_Fund_Values_on_Portal__c = 'A;B';

        insert designations;

        List<Account> accountList = TestObjectFactory.CreateAccounts('TestAccount', 1);
        accountList.get(0).Membership_Start_Date__c =  Date.today().addDays(-1);
        accountList.get(0).Membership_End_Date__c =  Date.today().addDays(1);
        insert accountList;

        List<Contact> houseHoldContact = TestObjectFactory.CreateContacts('TestContact',1);
        houseHoldContact.get(0).AccountId = accountList.get(0).Id;
        insert houseHoldContact;

        Profile p = [Select id from Profile where name = 'Wise Community Member'];

        User user = new User(
                alias = 'test123',
                email='test123@noemail.com',
                emailencodingkey='UTF-8',
                lastname='Testing',
                languagelocalekey='en_US',
                localesidkey='en_US',
                country='United States',
                IsActive =true,
                timezonesidkey='America/Los_Angeles',
                username='tester@noemail.com');

        user.ProfileId = p.Id;
        user.ContactId = houseHoldContact.get(0).Id;
        insert user;
    }

    @isTest
    private static void testCaseOne() {
        User u = [Select id From User where lastname = 'Testing' limit 1];
        Designation__c d = [Select id from Designation__c Limit 1];

        Test.startTest();

        System.runAs(u) {
            CongrComm_DonationsGuestCtrl donationsController = new CongrComm_DonationsGuestCtrl();
            donationsController.makeDonationAction();
            donationsController.Amount = 1;
            donationsController.makeDonationAction();
            donationsController.selectedFund = d.Id;
            donationsController.con.lName = 'test';
            donationsController.con.email = 'test@test.com';
            donationsController.makeDonationAction();

            Integer s = donationsController.DonationTypes.size();

            donationsController.cancel();

            Boolean x = donationsController.pageErrors;
        }

        Test.stopTest();
    }

}