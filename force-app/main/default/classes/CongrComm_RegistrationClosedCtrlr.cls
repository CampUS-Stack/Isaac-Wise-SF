/**
 * Created by zacha on 11/17/2021.
 */

public without sharing class CongrComm_RegistrationClosedCtrlr {
    public Event__c theEvent {get; set;}
    public String eventId {get; set; }
    
    public CongrComm_RegistrationClosedCtrlr(){
        String theEventId = ApexPages.currentPage().getParameters().get('id');
        this.eventId = theEventId;
        
        theEvent = [
            SELECT Id, Owner.Name, Owner.Email, Name
            FROM Event__c
            WHERE Id = :theEventId
            LIMIT 1
        ];
    }
}