@isTest
public class CongrComm_MyFamilyInfoCtrlTest {
    
    @testSetup
    private static void setUpTestData() {
        
        List<Account> accountList = TestObjectFactory.CreateAccounts('TestAccount', 1);
        accountList.get(0).Membership_Start_Date__c =  Date.today().addDays(-1);
        accountList.get(0).Membership_End_Date__c =  Date.today().addDays(1);
        insert accountList;
        
        List<Contact> houseHoldContact = TestObjectFactory.CreateContacts('TestContact',1);
        houseHoldContact.get(0).AccountId = accountList.get(0).Id;
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
    private static void testConstructorWithoutId() {
        User u = [Select id From User where lastname = 'Testing' limit 1];
        
        System.runAs(u) {
            CongrComm_MyFamilyInfoCtrl myFamilyInfoCtrl = new CongrComm_MyFamilyInfoCtrl();  
            myFamilyInfoCtrl.createFakeContacts();
        }
    } 
    
}