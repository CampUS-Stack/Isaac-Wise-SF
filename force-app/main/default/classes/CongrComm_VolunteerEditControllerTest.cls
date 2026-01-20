@isTest
public class CongrComm_VolunteerEditControllerTest {
	
    static testmethod void CongrComm_VolunteerEditControllerTestNew() {
        
        Contact theContact = new Contact(LastName = 'Bob');
        insert theContact;
        
        PageReference pageRef = new PageReference('/CongrComm_VolunteerEdit');
        Test.setCurrentPage(pageRef);
        
        ApexPages.currentPage().getParameters().put('cId', theContact.Id);
        ApexPages.currentPage().getParameters().put('type', 'new');
		
        CongrComm_VolunteerEditController controller = new CongrComm_VolunteerEditController();
        controller.cancel();
        controller.save();
        
    }
    
    static testmethod void CongrComm_VolunteerEditControllerTestEdit() {
        
        Contact theContact = new Contact(LastName = 'Bob');
        insert theContact;
        
        Other_Volunteerism__c theCollege =  new Other_Volunteerism__c(Contact__c = theContact.Id);
        insert theCollege;
        
        PageReference pageRef = new PageReference('/CongrComm_VolunteerEdit');
        Test.setCurrentPage(pageRef);
        
        ApexPages.currentPage().getParameters().put('cId', theCollege.Id);
        ApexPages.currentPage().getParameters().put('status', 'success');
        ApexPages.currentPage().getParameters().put('type', 'edit');
		
        CongrComm_VolunteerEditController controller = new CongrComm_VolunteerEditController();
        controller.cancel();
        controller.save();
        
    }
    
}