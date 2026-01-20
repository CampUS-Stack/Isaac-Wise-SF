/**
 * Created by UD Office Chris on 7/27/2018.
 */

@IsTest
private class CongrComm_ObservancesControllerTests {
    static testMethod void testBehavior() {


        UserRole userRole = new UserRole(DeveloperName = 'TestRole', Name = 'My Role');
        insert userRole;

        list<Contact> contacts = TestObjectFactory.CreateContacts('Test',2);
        insert contacts;
        list<Yahrzeit__c> yahrzeits = TestObjectFactory.CreateYahrzeits(2);

        for (Yahrzeit__c y : yahrzeits) {
            y.Deceased__c = contacts.get(0).id;
        }

        insert yahrzeits;


        Account ac = (Account)TestObjectFactory.CreateAccounts('test',1)[0];
        ac.OwnerId = UserInfo.getUserId();
        insert ac;

        Contact con = (Contact)TestObjectFactory.CreateContacts('test',1)[0];
        con.AccountId = ac.Id;
        insert con;

        String randomNum = String.valueOf(System.now());
        String theUserName = 'test1233333@test.com';
        User user = new User(alias = 'test123', email='test123@noemail.com',
                emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
                localesidkey='en_US', profileid = [SELECT Id FROM Profile WHERE Name = 'Wise Community Member'].Id,
                country='United States',IsActive =true,ContactId = con.Id,
                timezonesidkey='America/Los_Angeles', username= theUserName );

        Yahrzeit_Observance__c observance = new Yahrzeit_Observance__c();
        observance.Yahrzeit__c = yahrzeits[0].Id;
        observance.Contact__c = con.Id;
        insert observance;

        System.runAs(user){


            CongrComm_ObservancesController obsCtrl = new CongrComm_ObservancesController();

        }
    }
}