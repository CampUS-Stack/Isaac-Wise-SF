/**
 * Created by Chris Home Office on 1/31/2019.
 */

public without sharing class CongrComm_ThanksFreeEventCtrl {

    public Event__c Event {get; set;}
    public CongrComm_ThanksFreeEventCtrl(){

        String programId = getUrlParam('pId');
        this.Event = getEvent(programId);
    }

    @TestVisible private Event__c getEvent(String eventId){
        try{
            Event__c returnEvent = [SELECT Id, Receipt_Text__c, Web_Registration_Form__c FROM Event__c WHERE Id = :eventId];
            return returnEvent;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return null;
        }
    }

    @TestVisible private String getUrlParam(String paramName){

        if(ApexPages.currentPage().getParameters().containsKey(paramName)){
            return ApexPages.currentPage().getParameters().get(paramName);
        }

        return '';
    }
}