public class CongrComm_CollegeUniController {
    
    Public Id contactId {get; set;}
    Public Contact theContact {get; set;}
    Public List<College_University__c> contactColleges {get; set;}

    public String CollegeUniversityIdToDelete {get; set;}
    
    Public CongrComm_CollegeUniController() {
        
        contactId = ApexPages.currentPage().getParameters().get('cId');
        theContact = [SELECT Id, FirstName, LastName
                      FROM Contact
                      WHERE Id = :contactId];
        
        contactColleges = [SELECT Id, College_University__c, Grade_Level__c, Major__c,End_Date__c
                           FROM College_University__c
                           WHERE Contact__c = :contactId];
        
    }

    public PageReference RemoveCollegeUniversity(){

        try{

            for(College_University__c curUniv : contactColleges){
                if(curUniv.Id == CollegeUniversityIdToDelete){
                    delete curUniv;
                    return null;
                }
            }
        }
        catch(DmlException de){
            system.debug(de.getMessage());
        }

        return null;
    }
    
}