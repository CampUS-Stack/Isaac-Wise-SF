@isTest
public class CongrComm_EventGuestControllerTest {         
    
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
        
        
        
        User u = [Select id, ContactId From User where lastname = 'Testing' limit 1];
        
        
        
        PageReference pageRef = new PageReference('/CongrComm_MultiEvent');
        Test.setCurrentPage(pageRef);
        
        System.runAs(u) {
            
            list<Designation__c> designations = TestObjectFactory.CreateDesignations('test',1);
            designations[0].Is_Credit_Account__c = true;
            insert designations;
            
            Event__c theEvent = new Event__c();
            theEvent.Name = 'test';
            theEvent.Event_Price__c = 200 ; 
            theEvent.Event_Type__c = 'WiseUP Project';
            theEvent.Display_on_portal__c = true;
            theEvent.Include_in_multi_signup__c = true;
            theEvent.Event_Date_Start__c = Date.today().addDays(10);
            theEvent.Designation__c = designations[0].Id;
            theEvent.Individual_Pricing_1_Name__c = 'P1';
            theEvent.Individual_Pricing_2_Name__c = 'P2';
            theEvent.Individual_Pricing_3_Name__c = 'P3';
            insert theEvent;  
            
            Event_Participant__c ep = new Event_Participant__c();
            ep.Contact__c = u.ContactId;
            ep.Event__c = theEvent.Id;
            insert ep; 
            
            Contact c = [Select id from Contact limit 1 ];
            
            Question__c q1 = new Question__c();
            q1.Allow_Multiple_Choice__c = true;
            q1.RecordTypeId = Schema.SObjectType.Question__c.getRecordTypeInfosByDeveloperName().get('Picklist').getRecordTypeId();
            q1.Question__c = 'Test';
            q1.Picklist_Answers__c = 'A;B;'; 
            q1.Event__c = theEvent.Id;
            
            insert q1;
            
            ApexPages.currentPage().getParameters().put('id', theEvent.Id);
            CongrComm_EventGuestController eg = new CongrComm_EventGuestController();
            eg.onLoad();
            
            System.debug(eg.PricingOptions);
            
            eg.GuestPageWrapper.FirstName = 'TestFN';
            eg.GuestPageWrapper.LastName = 'TestFN';
            eg.GuestPageWrapper.Email = 'TestFN@test.com';
            eg.GuestPageWrapper.SelectedTicketType = 'Pricing 1';
            eg.GuestPageWrapper.price = 10.0;
            eg.GuestPageWrapper.Pricing1 = 21;
            
            eg.GuestFirstName = 'TesGuest';
            eg.GuestLastName = 'TestGuestLN';
            eg.GuestEmail = 'test@testguest.com';
            eg.GuestTicketType = 'Pricing 3';
            
            eg.AddGuestRegistrant();
            eg.RegisterGuestRegistrants();
            System.debug(eg.TotalRegistrantPrice );
            System.debug('TotalAdditionalRegistrantFees' + eg.TotalAdditionalRegistrantFees + eg.TotalRegistrantPrice );
            System.debug('NumberOfAllRegistrants' + eg.NumberOfAllRegistrants + eg.NumberOfGuestRegistrants );
            System.debug('GuestTotalPrice' + eg.GuestTotalPrice + eg.TicketOptions );
            System.debug('NumberOfSelectedGuestRegistrants' + eg.NumberOfSelectedGuestRegistrants + eg.NumberOfGuestRegistrants );
            
            eg.FirstName = 'test';
            eg.LastName = 'test';
            eg.getAdditionalRegistrantResults();
            
            
            eg.save();
            eg.cancel();
            eg.GoBackToAdditionalRegistrantSearch();
            eg.RemoveSelectedParticipant();
            eg.saveNonPaidEvent();
        }
        
    }
}