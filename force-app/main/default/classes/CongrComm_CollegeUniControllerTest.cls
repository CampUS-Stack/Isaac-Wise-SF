@isTest
public class CongrComm_CollegeUniControllerTest {

    static testmethod void CongrComm_CollegeUniController_Test() {
        
        Contact theContact = new Contact(LastName = 'Bob');
        insert theContact;
        
        PageReference pageRef = new PageReference('/CongrComm_CollegeUni');
        Test.setCurrentPage(pageRef);
        
        ApexPages.currentPage().getParameters().put('cId', theContact.Id);
		
        CongrComm_CollegeUniController controller = new CongrComm_CollegeUniController();
        
    }
    
}