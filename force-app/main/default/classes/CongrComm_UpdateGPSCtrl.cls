public with sharing class CongrComm_UpdateGPSCtrl {

    @TestVisible private Contact communityUserContact {get; set;}
    public Contact ContactToEdit {get; set;}
    public List<Other_Volunteerism__c> otherVolunteerisms {get; set;}

    public String OrgIdToEdit {get; set;}

    public String ReturnPage {get; set;}

    public CongrComm_UpdateGPSCtrl() {
        if(ApexPages.currentPage().getParameters().containsKey('retURL')){
            ReturnPage = ApexPages.currentPage().getParameters().get('retURL');
        }
        else{
            ApexPages.currentPage().getParameters().put('retURL','/CongrComm_MyFamilyInformation');
        }

        String cId = ApexPages.currentPage().getParameters().get('cId');

        try{
            this.communityUserContact = UtilitiesUsers.GetContactForCommunityUser(UserInfo.getUserId());
            this.ContactToEdit = [SELECT Id, FirstName, Name,LastName, Skills_Interests_Other__c, Skills__c,Areas_of_Interest__c,Interests__c,Skills_Committments__c,Torah_Commitment__c
                                    FROM Contact
                                    WHERE id =:cId];

            this.otherVolunteerisms = [SELECT Id, Role__c, Organization__c, Start_Date__c, End_Date__c,From__c,To__c,Year_Started__c,Year_Ended__c
                                        FROM Other_Volunteerism__c
                                        WHERE Contact__c = :ContactToEdit.Id
                                        ORDER BY Start_Date__c DESC];
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
        }
    }

    public PageReference AddNewOrg(){

        if(SaveContact() == null){
            return null;
        }

        PageReference pr = Page.CongrComm_VolunteerEdit;
        pr.setRedirect(true);
        pr.getParameters().put('cId',ContactToEdit.Id);
        pr.getParameters().put('type','new');
        return pr;
    }

    public PageReference EditOrg(){

        if(SaveContact() == null){
            return null;
        }

        PageReference pr = Page.CongrComm_VolunteerEdit;
        pr.setRedirect(true);
        pr.getParameters().put('cId',OrgIdToEdit);
        pr.getParameters().put('type','edit');
        return pr;
    }


    public PageReference SaveContact(){
        try{
            update ContactToEdit;

            PageReference pr = Page.CongrComm_MyFamilyInformation;
            pr.setRedirect(true);
            return pr;
        }
        catch(DmlException de){
            system.debug(de.getMessage());
            return null;
        }
    }
}