public class CongrComm_VolunteerEditController {
    
    Public Id cId {get; set;}
    Public Other_Volunteerism__c theVolunteerism {get; set;}
    Public Contact theContact {get; set;}
    Public Boolean isSuccess {get; set;}
    
    // If param type == 'edit', cId is the College's Id, straight up edit.
    // If param type == 'new', cId is the Contact's Id, create new.
    Public CongrComm_VolunteerEditController() {
        if(ApexPages.currentPage().getParameters().get('status') == 'success'){
            isSuccess = true;
        } else {
            isSuccess = false;
        }
        cId = ApexPages.currentPage().getParameters().get('cId');
         try {
        if(ApexPages.currentPage().getParameters().get('type') == 'edit'){
            
            theVolunteerism = [SELECT Id, Role__c, Organization__c, Start_Date__c, End_Date__c,
                                      Notes__c, Contact__c, Year_Ended__c, Year_Started__c
                         	   FROM Other_Volunteerism__c
                         	   WHERE Id = :cId];
            if(theVolunteerism != null && theVolunteerism.Contact__c != null)  {            	   
            theContact = [SELECT Id, FirstName, LastName
                          FROM Contact
                          WHERE Id = :theVolunteerism.Contact__c];
            }
        } else if(ApexPages.currentPage().getParameters().get('type') == 'new') {
            theVolunteerism = new Other_Volunteerism__c(Contact__c = cId);
           
	            theContact = [SELECT Id, FirstName, LastName
	                          FROM Contact
	                          WHERE Id = :cId];
            
         }
        } 
        catch (Exception e) {
            	
         }
    }
    
    // Upsert takes care of both edit or new cases.
    Public PageReference save() {
        
        try {
            
            upsert theVolunteerism;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Update successful!'));
            if(ApexPages.currentPage().getParameters().get('type') == 'edit'){
                PageReference pageRef = new PageReference('/CongrComm_UpdateGPS');
                pageRef.getParameters().put('cId', theVolunteerism.Contact__c);
                pageRef.getParameters().put('type', 'edit');
                pageRef.getParameters().put('status', 'success');
                return pageRef;
            } else if(ApexPages.currentPage().getParameters().get('type') == 'new') {
                PageReference pageRef = new PageReference('/CongrComm_UpdateGPS');
                pageRef.getParameters().put('cId', theContact.Id);
                pageRef.getParameters().put('retURL', 'CongrComm_MyFamilyInformation');
                return pageRef;
            }
            
        } catch (Exception ex) {
            
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'There was a problem saving your information.  Please check your info and try again.'));
            
        }

        PageReference pr = Page.CongrComm_UpdateGPS;
        pr.setRedirect(true);
        pr.getParameters().put('cId',cId);
        return pr;
        
    }



    // Upsert takes care of both edit or new cases.
    Public PageReference saveAndAddAnother() {

        PageReference prResult = save();
        if(prResult == null){
            return null;
        }

        PageReference pr = Page.CongrComm_VolunteerEdit;
        pr.setRedirect(true);
        if(ApexPages.currentPage().getParameters().get('type') == 'edit'){
            pr.getParameters().put('cId', theVolunteerism.Contact__c);
        } else if(ApexPages.currentPage().getParameters().get('type') == 'new'){
            pr.getParameters().put('cId', theContact.Id);
        }
        pr.getParameters().put('type', 'new');
        return pr;

    }
    
    Public PageReference cancel() {
        
        PageReference pageRef = new PageReference('/CongrComm_UpdateGPS');
        if(ApexPages.currentPage().getParameters().get('type') == 'edit'){
            pageRef.getParameters().put('cId', theVolunteerism.Contact__c);
        } else if(ApexPages.currentPage().getParameters().get('type') == 'new'){
            pageRef.getParameters().put('cId', theContact.Id);
        }
        pageRef.getParameters().put('retURL', 'CongrComm_MyFamilyInformation');
        return pageRef;
        
    }

}