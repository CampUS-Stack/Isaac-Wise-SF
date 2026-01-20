@isTest
public class CongrComm_EventPageControllerTest {
    
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
    private static void testEventPageController() {
        
        list<Designation__c> designations = TestObjectFactory.CreateDesignations('test',1);
        designations[0].Is_Credit_Account__c = true;
        insert designations;
        
        Event__c theEvent = new Event__c();
        theEvent.Name = 'test';
        theEvent.Event_Price__c = 200 ; 
        theEvent.Display_on_portal__c = true;
        theEvent.Designation__c = designations[0].Id;
        insert theEvent;  
        
        Contact c = [Select id from Contact limit 1 ];
        
        Question__c q1 = new Question__c();
        q1.Allow_Multiple_Choice__c = true;
        q1.RecordTypeId = Schema.SObjectType.Question__c.getRecordTypeInfosByDeveloperName().get('Picklist').getRecordTypeId();
        q1.Question__c = 'Test';
        q1.Picklist_Answers__c = 'A;B;';
        q1.Event__c = theEvent.Id;
        
        insert q1;
        
        User u = [Select id From User where lastname = 'Testing' limit 1];
        
        PageReference pageRef = new PageReference('/CongrComm_EventPage');
        Test.setCurrentPage(pageRef);
        
        
        System.debug('theEvent2' + theEvent);
        
        System.runAs(u) {
            theEvent = [Select id from Event__c Limit 1 ];
            
            ApexPages.currentPage().getParameters().put('id', theEvent.Id);
            
            CongrComm_EventPageController myEventPageController = new CongrComm_EventPageController();
            myEventPageController.onLoad();
            
            myEventPageController.FirstName = 't';
            myEventPageController.LastName = 't';
            myEventPageController.SearchForRegistrants();
            myEventPageController.LoadMoreAdditionalRegistrantSearchResults();
            myEventPageController.save();
            myEventPageController.Email = 'testmailcom';
            myEventPageController.save();
            myEventPageController.Email = 'test@mail.com';
            myEventPageController.save();
            
            System.assertEquals(3, myEventPageController.NumberOfFamilyMembers.size());
            
        }
    } 
    
    @isTest
    private static void testEventPageController1() {
        
        list<Designation__c> designations = TestObjectFactory.CreateDesignations('test',1);
        designations[0].Is_Credit_Account__c = true;
        insert designations;
        
        Event__c theEvent = new Event__c();
        theEvent.Name = 'test';
        theEvent.Event_Price__c = 200 ; 
        theEvent.Display_on_portal__c = true;
        theEvent.Designation__c = designations[0].Id;
        insert theEvent;  
        
        Contact c = [Select id from Contact limit 1 offset 1];
        
        
        Question__c q1 = new Question__c();
        q1.Allow_Multiple_Choice__c = true;
        q1.RecordTypeId = Schema.SObjectType.Question__c.getRecordTypeInfosByDeveloperName().get('Picklist').getRecordTypeId();
        q1.Question__c = 'Test';
        q1.Picklist_Answers__c = 'A;B;';
        q1.Event__c = theEvent.Id;
        
        insert q1;
        
        User u = [Select id From User where lastname = 'Testing' limit 1];
        
        PageReference pageRef = new PageReference('/CongrComm_EventPage');
        Test.setCurrentPage(pageRef);
        theEvent = [Select id from Event__c Limit 1 ];
        ApexPages.currentPage().getParameters().put('id', theEvent.Id);
        
        System.runAs(u) {
            CongrComm_EventPageController myEventPageController = new CongrComm_EventPageController();
            myEventPageController.onLoad();
            myEventPageController.Email = 'test@mail.com';
            myEventPageController.RegistrantSearchName = 'Test';
            myEventPageController.SearchForRegistrants();
            
            myEventPageController.Email = 'test123@noemail.com';
            myEventPageController.GuestFirstName = 'Test';
            myEventPageController.GuestLastName = 'Test2';
            myEventPageController.GuestEmail = 'test12223@noemail.com';
            myEventPageController.GuestTicketType = 'Pricing 3';
            myEventPageController.AddGuestRegistrant();
            myEventPageController.RegisterGuestRegistrants();
            
            myEventPageController.RemoveSelectedParticipant();
            
            myEventPageController.save();
            myEventPageController.SearchForRegistrants();
            // myEventPageController.GoToFinalizeAdditionalRegistrant();
            myEventPageController.GoBackToAdditionalRegistrantSearch();
            //myEventPageController.addReg();
            //myEventPageController.removeReg();
            myEventPageController.SelectFamilyMembers();
            
            System.assertEquals(1, myEventPageController.NumberOfAllRegistrants);
            System.assertEquals(0.00, myEventPageController.GuestTotalPrice);
            
            System.debug(myEventPageController.TotalAdditionalRegistrantFees);
            System.debug(myEventPageController.PricingOptions);
            System.debug(myEventPageController.TicketOptions);
            
            System.debug(myEventPageController.NumberOfMemberRegistrants);
            System.debug(myEventPageController.NumberOfSelectedFamily);
            System.debug(myEventPageController.NumberOfSelectedAdditionalRegistrants);
            System.debug(myEventPageController.NumberOfGuestRegistrants);
            System.debug(myEventPageController.NumberOfGuestPageRegistrants);
            System.debug(myEventPageController.NumberOfSelectedGuestRegistrants);

            
            
        }
    } 
    
}