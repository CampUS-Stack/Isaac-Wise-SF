@isTest
public class CongrComm_DonationsControllerTest {
    
    @testSetup
    private static void setUpTestData() {
        
        list<Designation__c> designations = TestObjectFactory.CreateDesignations('test',4);
        designations[0].Display_Fund_on_Portal__c = true;
        designations[1].Display_Fund_on_Portal__c = true;
        designations[0].Display_Fund_Values_on_Portal__c = 'A;B';

        designations[2].Display_Fund_on_Portal__c = true;
        designations[2].Name = 'Memorial Books';

        designations[3].Display_Fund_on_Portal__c = true;
        designations[3].Name = 'Memorial Donation - Shipping Charges';
        insert designations;
        
        List<Account> accountList = TestObjectFactory.CreateAccounts('TestAccount', 1);
        accountList.get(0).Membership_Start_Date__c =  Date.today().addDays(-1);
        accountList.get(0).Membership_End_Date__c =  Date.today().addDays(1);
        insert accountList;
        
        List<Contact> houseHoldContact = TestObjectFactory.CreateContacts('TestContact',1);
        houseHoldContact.get(0).AccountId = accountList.get(0).Id;
        insert houseHoldContact;

        Assessment__c assessment = new Assessment__c();
        assessment.Assessed_Amount__c = 100.00;
        assessment.Account__c = accountList.get(0).Id;
        insert assessment;

        
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
        Designation__c d = [SELECT Id,Name FROM Designation__c LIMIT 1];
        Assessment__c assessment = [SELECT Id,Assessed_Amount__c FROM Assessment__c LIMIT 1];

        Test.startTest();

        Test.setCurrentPage(Page.CongrComm_Donations);

        System.runAs(u) {

            CongrComm_DonationsController donationsController = new CongrComm_DonationsController();
            donationsController.amount = 19;
            donationsController.selectedDonationType = 'In Honor Od';
            donationsController.selectedFund = d.Id;
            donationsController.listing = 'test';
            donationsController.selectedPaymentMethod = 'CC';
            donationsController.addAnotherDonation();
            donationsController.makeDonationAction();
            donationsController.selectedFund = d.Id;
            donationsController.makeDonationAction();
            
            donationsController.cancel();

            //donationsController.createPaymentAdjustment(assessment);

            //donationsController.copyBook();
            //donationsController.removeFund();

            Boolean x = donationsController.pageErrors;
        }
        
        Test.stopTest();
    }

    @isTest
    private static void testCaseTwo() {
        User u = [Select id From User where lastname = 'Testing' limit 1];
        Designation__c d = [Select id from Designation__c Limit 1];

        Test.startTest();

        Test.setCurrentPage(Page.CongrComm_MemorialDonations);

        System.runAs(u) {
            CongrComm_DonationsController donationsController = new CongrComm_DonationsController();
            donationsController.makeMemorialDonationAction();
            donationsController.Amount = 19;
            donationsController.makeMemorialDonationAction();
            donationsController.includeHardCopyCost = true;
            donationsController.selectedFund = d.Id;
            donationsController.selectedPaymentMethod = 'CC';
            donationsController.makeMemorialDonationAction();

            donationsController.cancel();

            Boolean x = donationsController.pageErrors;

        }

        Test.stopTest();
    }
    
}