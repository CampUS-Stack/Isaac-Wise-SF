@isTest
public class CongrComm_CollegeUniEditControllerTest {

    static testmethod void CongrComm_CollegeUniEditController_TestNew() {
        
        Contact theContact = new Contact(LastName = 'Bob');
        insert theContact;
        
        PageReference pageRef = new PageReference('/CongrComm_CollegeUniEdit');
        Test.setCurrentPage(pageRef);
        
        ApexPages.currentPage().getParameters().put('cId', theContact.Id);
        ApexPages.currentPage().getParameters().put('type', 'new');
		
        CongrComm_CollegeUniEditController controller = new CongrComm_CollegeUniEditController();
        controller.cancel();
        controller.save();
        
    }
    
    static testmethod void CongrComm_CollegeUniEditController_TestEdit() {
        
        Contact theContact = new Contact(LastName = 'Bob');
        insert theContact;
        
        College_University__c theCollege =  new College_University__c(Contact__c = theContact.Id);
        insert theCollege;
        
        PageReference pageRef = new PageReference('/CongrComm_CollegeUniEdit');
        Test.setCurrentPage(pageRef);
        
        ApexPages.currentPage().getParameters().put('cId', theCollege.Id);
        ApexPages.currentPage().getParameters().put('status', 'success');
        ApexPages.currentPage().getParameters().put('type', 'edit');
		
        CongrComm_CollegeUniEditController controller = new CongrComm_CollegeUniEditController();
        controller.cancel();
        controller.save();
        
    }
    
}