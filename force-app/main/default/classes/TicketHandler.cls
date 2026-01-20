/**
 * Created by Kritik Garg on 09-01-2020.
 */

public without sharing class TicketHandler implements TriggerHandler.ITrigger{

    private Boolean hasExecuted {get; set;}

    public TicketHandler() {}

    public void MainEntry(TriggerState state){

        system.debug('TicketHandler Handler Main Entry Called.');
        system.debug('Firing object: ' + state.TriggerObject);

        if(state.IsAfter){
            if(state.IsInsert) {
                processAfterInsert(state);
            }
            if(state.IsUpdate) {
                processAfterUpdate(state);
            }
        }
    }

    public void InProgressEntry(TriggerState state){

        if(state.TriggerObject != 'Ticket_Issue__c'){
            return;
        }
    }

    @TestVisible private void processAfterInsert(TriggerState state){

        List<Id> listOfIds = new List<Id>();
        for(Ticket_Issue__c ti : (list<Ticket_Issue__c>)state.NewList) {
            listOfIds.add(ti.id);
        }

        if(listOfIds.size()>0 && UserInfo.getUserType() != 'Guest') {
            UDTicketCallout.syncNewTickets(listOfIds);
        }
    }

    @TestVisible private void processAfterUpdate(TriggerState state) {

        Map<Id, Ticket_Issue__c> oldMap = (Map<Id, Ticket_Issue__c>) state.OldMap;
        List<Id> listOfIds = new List<Id>();
        for (Ticket_Issue__c ti : (list<Ticket_Issue__c>) state.NewList) {

            Ticket_Issue__c oldTicket = oldMap.get(ti.Id);

            if (ti.UD_Ticket_Id__c != null && (ti.Description__c != oldTicket.Description__c ||
                    ti.Priority__c != oldTicket.Priority__c ||
                    ti.Title__c != oldTicket.Title__c ||
                    ti.Status__c != oldTicket.Status__c ||
                    ti.Additional_Email_to_Notify_1__c != oldTicket.Additional_Email_to_Notify_1__c ||
                    ti.Additional_Email_to_Notify_2__c != oldTicket.Additional_Email_to_Notify_2__c ||
                    ti.Additional_Email_to_Notify_3__c != oldTicket.Additional_Email_to_Notify_3__c
            )) {
                listOfIds.add(ti.id);
            }
        }
        System.debug(listOfIds);
        if (listOfIds.size() > 0 && UserInfo.getUserType() != 'Guest') {
            UDTicketCallout.syncOldTickets(listOfIds);
        }
    }

  /*  @TestVisible private void syncTickets(list<Ticket_Issue__c> ticketList){

        for(Ticket_Issue__c t : ticketList){

            //curTorah.Name = Datetime.newInstance(curTorah.Date__c,Time.newInstance(0,0,0,0)).format('M/d/YYYY');
        }
    }*/


}