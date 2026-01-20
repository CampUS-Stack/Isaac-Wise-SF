/**
 * Created by Kritik Garg on 18-02-2019.
 */

@isTest
public class CongrComm_FairShareControllerTest {

    @testSetup
    static void dataSetUp() {

        List<Account> accountList = TestObjectFactory.CreateAccounts('TestAccount', 2);
        accountList.get(0).Membership_Start_Date__c =  Date.today().addDays(-1);
        accountList.get(0).Membership_End_Date__c =  Date.today().addDays(1);
        accountList.get(1).Membership_Start_Date__c =  Date.today().addDays(-1);
        accountList.get(1).Membership_End_Date__c =  Date.today().addDays(1);
        accountList.get(1).Directory_Opt_out__c = false;
        insert accountList;

        insert new Important_Accounts__c(Name='Wise Temple Guest Account',Account_ID__c = accountList[0].Id);


        List<Contact> houseHoldContact = TestObjectFactory.CreateContacts('TestContact',3);
        houseHoldContact.get(0).AccountId = accountList.get(0).Id;
        houseHoldContact.get(0).Email = 'test123@noemail.com';
        houseHoldContact.get(1).AccountId = accountList.get(1).Id;
        houseHoldContact.get(2).AccountId = accountList.get(0).Id;

        insert houseHoldContact;



        //Profile p = [Select id from Profile where name = 'Wise Temple Community User'];
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
    private static void testMethod1() {
        User u = [Select id, ContactId From User where lastname = 'Testing' limit 1];

        System.runAs(u) {
            CongrComm_FairShareController fsc = new CongrComm_FairShareController();
            fsc.fairShare.Membership_Contribution__c = 100;
            fsc.fairShare.PST__c = 150;

            fsc.saveFairShare();


        }
    }

//    @isTest
//    private static void testMethod2() {
//        User u = [Select id, ContactId From User where lastname = 'Testing' limit 1];
//
//        System.runAs(u) {
//            CongrComm_FairShareController fsc = new CongrComm_FairShareController();
//            fsc.fairShare.Membership_Contribution__c = 100;
//            fsc.fairShare.PST__c = 150;
//
//            fsc.saveFairShare();
//
//
//        }
//    }

}