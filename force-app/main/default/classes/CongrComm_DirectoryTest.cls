@isTest
public class CongrComm_DirectoryTest {
    
    @testSetup
    private static void setUpTestData() {
        List<Account> accountList = TestObjectFactory.CreateAccounts('TestAccount', 1);
        accountList.get(0).Membership_Start_Date__c =  Date.today().addDays(-1);
        accountList.get(0).Membership_End_Date__c =  Date.today().addDays(1);

        insert accountList;
        
        List<Contact> houseHoldContact = TestObjectFactory.CreateContacts('TestContact',2);
        houseHoldContact.get(0).AccountId = accountList.get(0).Id;
        
        insert houseHoldContact;        
    }
    
    @isTest
    private static void testDirectoryCtrl() {
        Contact con = [Select id from Contact limit 1];

        Test.startTest();
        CongrComm_DirectoryCtrl directoryCtrl = new CongrComm_DirectoryCtrl(); 
        directoryCtrl.conId = con.Id;
        directoryCtrl.fetchContactDetails();
        System.assertEquals(0, directoryCtrl.NumberOfResults);
        
        directoryCtrl.inCity = 'TestCity';
        directoryCtrl.inGrade = 'TestGrade';
        directoryCtrl.inName = 'TestName';
        directoryCtrl.inState = 'TestState';
        directoryCtrl.inZip = '12345';
        directoryCtrl.inSecularSchoolName = 'TestSchoolName';
        
        directoryCtrl.searchContacts();
        directoryCtrl.inZip = '1234';
        directoryCtrl.searchContacts();
        
        System.assertEquals(0, directoryCtrl.NumberOfResults);

        directoryCtrl.clearSearchAction();
        
        Test.stopTest();
    }
    
}