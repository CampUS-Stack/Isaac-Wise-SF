@isTest
public class CongrComm_FinancialsHomeControllerTest {
    
    public static testMethod void CongrComm_FinancialsHomeControllerTest() {
        // Setup test data
        // Create a unique UserName
        
        Account theAccount = new Account(Name = 'Test');
        insert theAccount;
        
        Contact theContact = new Contact(LastName = 'Tester', FirstName = 'Bob', AccountId = theAccount.Id);
        insert theContact;
        
        Designation__c theDesignation = new Designation__c(Name = 'Hello');
        insert theDesignation;
        
        Id assessmentTypeId = [SELECT Id, Name 
                                   FROM   RecordType 
                                   WHERE  sObjectType = 'Assessment__c' 
                                   AND 	  Name = 'Assessment'
                                   LIMIT  1].Id;
        
        Assessment__c theBill = new Assessment__c(RecordTypeId = assessmentTypeId, Account__c = theAccount.Id, Assessment_Date__c = Date.today(), Assessed_Amount__c = 0);
        insert theBill;
        
        String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@wisecomm.com';
        // This code runs as the system user
        
        Profile p = [Select id from Profile where name = 'Wise Community Member'];
        //Profile p = [Select id from Profile where name = 'Wise Community Member'];
        
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com',
                          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                          LocaleSidKey='en_US', ProfileId = p.Id,
                          TimeZoneSidKey='America/Los_Angeles',
                          UserName=uniqueUserName, ContactId=theContact.Id);
        
        Assessment__c theAssessment = new Assessment__c();
        theAssessment.RecordTypeId = assessmentTypeId;
        theAssessment.Account__c = theAccount.Id;
        theAssessment.Assessment_Date__c = Date.today();
        theAssessment.Assessed_Amount__c = 500;
        insert theAssessment;
        
        Assessment__c theAssessment2 = new Assessment__c();
        theAssessment2.RecordTypeId = assessmentTypeId;
        theAssessment2.Account__c = theAccount.Id;
        theAssessment2.Assessment_Date__c = Date.today().addMonths(-12);
        theAssessment2.Assessed_Amount__c = 500;
        insert theAssessment2;
        
        System.runAs(u) {
            // The following code runs as user 'u'
            System.debug('Current User: ' + UserInfo.getUserName());
            System.debug('Current Profile: ' + UserInfo.getProfileId());
            
            CongrComm_FinancialsHomeController theController = new CongrComm_FinancialsHomeController();
//            theController.homeLoad();
            theController.paymentHistory();
            theController.billingHistory();
            theController.makePayment();
            theController.paymentCancel();
        }
    }
}