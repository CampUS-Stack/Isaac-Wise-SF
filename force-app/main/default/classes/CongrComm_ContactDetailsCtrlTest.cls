@isTest
private class CongrComm_ContactDetailsCtrlTest {
    
    @testSetup
    private static void setUpTestData() {
        List<Account> accountList = TestObjectFactory.CreateAccounts('TestAccount', 1);
        insert accountList;
        
        List<Contact> houseHoldContact = TestObjectFactory.CreateContacts('TestContact',1);
        houseHoldContact.get(0).Employer_Zip_Code__c = '12345';
        insert houseHoldContact;        
    }
    
    //Negative Test case
    @isTest
    private static void testConstructorWithoutId() {
        CongrComm_ContactDetailsCtrl contactDetailsCtrl = new CongrComm_ContactDetailsCtrl();         
        System.assertNotEquals(null, contactDetailsCtrl.GradeLevels);
    }
    
    @isTest
    private static void testConstructorWithIdCase1() {
        Contact con = [Select id from Contact limit 1];
        
        Test.startTest();
        PageReference currentPage = Page.CongrComm_ContactDetails;
        Test.setCurrentPage(currentPage);
        
        ApexPages.currentPage().getParameters().put('cId',con.Id);
        CongrComm_ContactDetailsCtrl contactDetailsCtrl = new CongrComm_ContactDetailsCtrl();  
        String conID = con.Id;
        contactDetailsCtrl.ContactToEdit.Employer_Zip_Code__c = '12334';
        contactDetailsCtrl.SaveContact();
        
        con = [Select id,Employer_Zip_Code__c from Contact limit 1];
        System.assertEquals('12334', con.Employer_Zip_Code__c, 'No effect on Employer_Zip_Code__c for length <= 5');
        Test.stopTest();
    }
    
    @isTest
    private static void testConstructorWithIdCase2() {
        Contact con = [Select id from Contact limit 1];
        
        Test.startTest();
        PageReference currentPage = Page.CongrComm_ContactDetails;
        Test.setCurrentPage(currentPage);
        
        ApexPages.currentPage().getParameters().put('cId',con.Id);
        CongrComm_ContactDetailsCtrl contactDetailsCtrl = new CongrComm_ContactDetailsCtrl();  
        String conID = con.Id;
        contactDetailsCtrl.ContactToEdit.Employer_Zip_Code__c = '123345';
        contactDetailsCtrl.SaveContact(); 
        
        con = [Select id,Employer_Zip_Code__c from Contact limit 1];
        System.assertEquals('12345', con.Employer_Zip_Code__c, 'Employer_Zip_Code__c is null for length > 5');
        Test.stopTest();
    }
    
}