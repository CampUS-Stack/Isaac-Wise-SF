/**
 * Created by Chris Home Desktop on 8/16/2017.
 */

public with sharing class ProgramSignInPDFController {

    public Event__c event {Get; set;}
    public List<Event_Participant__c> participants{get;set;}
    public ProgramSignInPDFController(ApexPages.StandardController stdController) {
        this.event = (Event__c)stdController.getRecord();
        String eventId = stdController.getId();
        this.event = getEvent(eventId);
//
//        Apexpages.currentPage().getHeaders().put('content-disposition', 'filename='+event.Name+'.pdf');
//
        participants = new List<Event_Participant__c> ();
        participants = [SELECT id,
                Name,
                Contact__r.LastName,
                Contact__r.FirstName,
                Contact__r.Email,
                Family_ID__c,
                Contact__r.Account.Is_Current_Member__c,
                Membership_Status__c,
                Contact__r.Account.Name,
                Contact__r.Nickname__c
        From Event_Participant__c
        where Event__r.Id = :this.event.Id Order By Contact__r.Account.Name,Contact__r.LastName];
    }

    @TestVisible private Event__c getEvent(String eventId){
        try{
            Event__c theEvent = [SELECT Id,Name,Event_Date_Start__c FROM Event__c WHERE Id = :eventId];
            return theEvent;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return null;
        }
    }


    public Double offset{
        get {
            TimeZone tz = UserInfo.getTimeZone();
            //Milliseconds to Day
            return tz.getOffset(DateTime.now()) / (1000 * 3600 * 24.0);
//            return 0;
        }
    }
}