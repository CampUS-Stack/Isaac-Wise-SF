/**
 * Created by cgibs on 7/26/2017.
 */

public with sharing class CampaignCloneController {

    public String PreviousCampaignId {get; set;}
    public Campaign PreviousCampaign {get; set;}
    public Campaign NewCampaign {get; set;}

    public CampaignCloneController() {

        this.PreviousCampaignId = getIdFRomParam();
        this.PreviousCampaign = getPreviousCampaign();

        if (this.PreviousCampaign == null) {
            return;
        }

        this.NewCampaign = CreateNewCampaign(this.PreviousCampaign);

    }


    public PageReference Save(){

        if(NewCampaign == null){
            return null;
        }

        try{
            insert NewCampaign;
        }
        catch(DmlException de){
            system.debug(de.getMessage());
            return null;
        }

        list<CampaignMember> campaignMembers = CreateNewCampaignMembers();
        insert campaignMembers;

        PageReference pr = new PageReference('/' + this.NewCampaign.Id);
        pr.setRedirect(true);
        return pr;
    }

    public PageReference Cancel(){

        if(this.PreviousCampaign == null){
            return null;
        }

        PageReference pr = new PageReference('/' + this.PreviousCampaign.Id);
        pr.setRedirect(true);
        return pr;
    }

    @TestVisible private list<CampaignMember> CreateNewCampaignMembers(){

        list<CampaignMember> campaignMembers = getCampaignMembers(this.PreviousCampaignId);
        list<CampaignMember> returnMembers = new list<CampaignMember>();

        for(CampaignMember curMember : campaignMembers){

            system.debug(curMember);

            CampaignMember newMember = new CampaignMember();
            newMember.CampaignId = this.NewCampaign.Id;
            newMember.Status = curMember.Status;
            newMember.Opted_Out__c = curMember.Opted_Out__c;
            newMember.ContactId = curMember.ContactId;

            returnMembers.add(newMember);
        }

        return returnMembers;
    }

    @TestVisible private Campaign CreateNewCampaign(Campaign oldCampaign){

        Campaign newCampaign = new Campaign();
        newCampaign.Name = oldCampaign.Name;
        newCampaign.IsActive = oldCampaign.IsActive;
        newCampaign.Fiscal_Year_Global__c = oldCampaign.Fiscal_Year_Global__c;
        newCampaign.Type = oldCampaign.Type;
        newCampaign.ParentId = oldCampaign.ParentId;
        newCampaign.Description = oldCampaign.Description;
        newCampaign.RecordTypeId = '01237000000ThBm';

        return newCampaign;

    }

    @TestVisible private list<CampaignMember> getCampaignMembers(String campaignId){
        try{
            list<CampaignMember> members = [SELECT Id,CampaignId,Status,ContactId,Opted_Out__c FROM CampaignMember WHERE CampaignId = :campaignId];
            return members;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return null;
        }
    }

    @TestVisible private Campaign getPreviousCampaign(){
        try{
            Campaign returnCampaign = [SELECT Id,Name,IsActive,Fiscal_Year_Global__c,Type,ParentId,Description,RecordTypeId FROM Campaign WHERE Id = :this.PreviousCampaignId];
            return returnCampaign;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return null;
        }
    }

    @TestVisible private String getIdFRomParam(){

        if(ApexPAges.currentPage().getParameters().containsKey('id')){
            return ApexPages.currentPage().getParameters().get('id');
        }

        return '';
    }

}