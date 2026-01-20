@isTest
public class CongrComm_MultiEventGuestCtrlTest {
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
        theEvent.Event_Type__c = 'WiseUP Project';
        theEvent.Include_in_multi_signup__c = true;
        theEvent.Event_Date_Start__c = Date.today().addDays(10);
        theEvent.Event_Date_End__c = Date.today().addDays(96);
        theEvent.Designation__c = designations[0].Id;
        theEvent.Individual_Pricing_1_Name__c = 'P1';
        theEvent.Individual_Pricing_2_Name__c = 'P2';
        theEvent.Individual_Pricing_3_Name__c = 'P3';
        theEvent.Display_on_portal__c = true;
        insert theEvent;  
        
        Contact c = [Select id from Contact limit 1 ];
        
        Question__c q1 = new Question__c();
        q1.Allow_Multiple_Choice__c = true;
        q1.RecordTypeId = Schema.SObjectType.Question__c.getRecordTypeInfosByDeveloperName().get('Picklist').getRecordTypeId();
        q1.Question__c = 'Test';
        q1.Picklist_Answers__c = 'A;B;'; 
        q1.Event__c = theEvent.Id;
        
        insert q1;
        
        User u = [Select id, ContactId From User where lastname = 'Testing' limit 1];
        
        Event_Participant__c ep = new Event_Participant__c();
        ep.Contact__c = u.ContactId;
        ep.Event__c = theEvent.Id;
        insert ep;        
        
        PageReference pageRef = new PageReference('/CongrComm_MultiEvent');
        Test.setCurrentPage(pageRef);
        
        System.runAs(u) {
            // theEvent = [Select id from Event__c Limit 1 ];
            
            ApexPages.currentPage().getParameters().put('etype', 'WiseUp');
            
            CongrComm_MultiEventGuestCtrl multiEventCtrl = new CongrComm_MultiEventGuestCtrl();  
            
            CongrComm_MultiEventGuestCtrl.EventWrapper ev = new  CongrComm_MultiEventGuestCtrl.EventWrapper();
            ev.TheEvent = TheEvent;
            ev.IsSelected = true;
            
            multiEventCtrl.EventsForRegistration.get(0).IsSelected = true;
            multiEventCtrl.EventIdChosenForGuestEntry = TheEvent.Id;
            System.debug(multiEventCtrl.EventsForRegistration);
            
            multiEventCtrl.SelectEvents();
            System.debug('PricingOptions' + ev.PricingOptions);
            
            
            ev.SelectedPricingOption = 'Pricing 3';
            ev.GuestEmail = 'test123@noemail.com';
            ev.GuestLastName = 'Test LN';
            ev.AddGuestRegistrant();
            ev.RemoveSelectedParticipant();
            
            
            multiEventCtrl.EventChosenForGuestEntry = TheEvent;

            multiEventCtrl.ChooseEventForGuestEdit();
            multiEventCtrl.BackToEventSelection();
            multiEventCtrl.AddParticipants();
            ev.IsSelected = true;
            multiEventCtrl.SelectEvents();
            multiEventCtrl.SelectedEventsForRegistration.add(ev);

            multiEventCtrl.SelectEventsGuest();
            
            System.debug('SelectedEventsForRegistration' + multiEventCtrl.SelectedEventsForRegistration);
            System.debug('NumberOfEventsForRegistration' + multiEventCtrl.NumberOfEventsForRegistration);            
            System.debug('NumberOfSelectedEventsForRegistration' + multiEventCtrl.NumberOfSelectedEventsForRegistration);            
            System.debug('SelectedEventPricingOptions' + multiEventCtrl.SelectedEventPricingOptions);
            System.debug('AttendingRegistrants' + ev.AttendingRegistrants + multiEventCtrl.GuestNameEntered);
            System.debug('NumberOfAttendingGuestRegistrants' + ev.NumberOfAttendingGuestRegistrants + multiEventCtrl.GuestTicketChoice);
    
        }
    } 
    
}