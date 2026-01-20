public class CongrComm_CollegeUniEditController {
    
    Public Id cId {get; set;}
    Public College_University__c theCollege {get; set;}
    Public Contact theContact {get; set;}
    Public Boolean hasErrors {
        get{
            return ApexPages.hasMessages();
        }
    }
    
    // If param type == 'edit', cId is the College's Id, straight up edit.
    // If param type == 'new', cId is the Contact's Id, create new.
    Public CongrComm_CollegeUniEditController() {

        cId = ApexPages.currentPage().getParameters().get('cId');
        if(ApexPages.currentPage().getParameters().get('type') == 'edit'){
            
            theCollege = [SELECT Id, College_University__c, End_Date__c, Grade_Level__c, Major__c,
                                 Notes__c, School_City__c, School_State__c, School_Street__c,
                                 School_Zip__c, Start_Date__c, Contact__c,Other_College_University__c
                         FROM College_University__c
                         WHERE Id = :cId];
            theContact = [SELECT Id, FirstName, LastName
                          FROM Contact
                          WHERE Id = :theCollege.Contact__c];
        } else if(ApexPages.currentPage().getParameters().get('type') == 'new') {
            theCollege = new College_University__c(Contact__c = cId);
            theContact = [SELECT Id, FirstName, LastName
                          FROM Contact
                          WHERE Id = :cId];
        }
    }
    
    // Upsert takes care of both edit or new cases.
    Public PageReference save() {

        Boolean isValidationError = CheckForPageValidationError();
        if(isValidationError){
            return null;
        }

        try {
            
            upsert theCollege;
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Update successful!'));
            if(ApexPages.currentPage().getParameters().get('type') == 'edit'){
                PageReference pageRef = new PageReference('/CongrComm_ContactDetails');
                pageRef.getParameters().put('cId', theContact.Id);
                //pageRef.getParameters().put('cId', cId);
                //pageRef.getParameters().put('type', 'edit');
                //pageRef.getParameters().put('status', 'success');
                return pageRef;
            } else if(ApexPages.currentPage().getParameters().get('type') == 'new') {
                PageReference pageRef = new PageReference('/CongrComm_ContactDetails');
                pageRef.getParameters().put('cId', theContact.Id);
                return pageRef;
            }
            
        } catch (Exception ex) {
            
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'There was a problem saving your information.  Please check your info and try again.'));
            
        }
        
        return null;
        
    }

    @TestVisible private Boolean CheckForPageValidationError(){

        if (theCollege.School_Zip__c != null && theCollege.School_Zip__c != '' ) {
            if (!(theCollege.School_Zip__c.length() == 10 || theCollege.School_Zip__c.length() == 5) && theCollege.School_Zip__c.length() > 0) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'School Zip Code must be exactly 5 or 10 digits.'));
                return true;
            }
        }

        return false;
    }
    
    Public PageReference cancel() {
        
        PageReference pageRef = new PageReference('/CongrComm_ContactDetails');
        if(ApexPages.currentPage().getParameters().get('type') == 'edit'){
            pageRef.getParameters().put('cId', theCollege.Contact__c);
        } else if(ApexPages.currentPage().getParameters().get('type') == 'new'){
            pageRef.getParameters().put('cId', theContact.Id);
        }
        return pageRef;
        
    }

}