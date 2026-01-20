/**
 * Created by Kritik Garg on 18-01-2020.
 */

public without sharing class CommentHandler implements TriggerHandler.ITrigger{

    private Boolean hasExecuted {get; set;}

    public CommentHandler() {}

    public void MainEntry(TriggerState state){

        system.debug('CommentHandler Handler Main Entry Called.');
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

        if(state.TriggerObject != 'Comment__c'){
            return;
        }
    }

    @TestVisible private void processAfterInsert(TriggerState state){

        List<Id> listOfIds = new List<Id>();
        List<Id> listOfTicketIds = new List<Id>();
        for(Comment__c c : (list<Comment__c>)state.NewList) {
            listOfIds.add(c.id);

            if(c.Ticket__c != null) {
                listOfTicketIds.add(c.Ticket__c);
            }
        }

        updateParentTicket(listOfTicketIds);

        if(listOfIds.size()>0 && UserInfo.getUserType() != 'Guest') {
            UDCommentCallout.syncNewComment(listOfIds);
        }
    }

    @TestVisible private void processAfterUpdate(TriggerState state) {

        Map<Id, Comment__c> oldMap = (Map<Id, Comment__c>) state.OldMap;
        List<Id> listOfIds = new List<Id>();
        List<Id> listOfTicketIds = new List<Id>();

        for (Comment__c co : (list<Comment__c>) state.NewList) {

            Comment__c oldComment = oldMap.get(co.Id);

            if(co.Comment__c != oldMap.get(co.Id).Comment__c){
                listOfIds.add(co.id);
            }

            if(co.Ticket__c != null) {
                listOfTicketIds.add(co.Ticket__c);
            }

        }

        updateParentTicket(listOfTicketIds);

        if (listOfIds.size() > 0 && UserInfo.getUserType() != 'Guest') {
            UDCommentCallout.syncOldComment(listOfIds);
        }

    }

    private void updateParentTicket(List<id> ticketIds) {
        List<Ticket_Issue__c> ticketToUpdate = new List<Ticket_Issue__c>();
        ticketToUpdate = [SELECT id FROM Ticket_Issue__c WHERE id IN :ticketIds];

        for(Ticket_Issue__c t : ticketToUpdate) {
            t.Last_Comment_Activity__c = System.now();
        }

        if(ticketToUpdate != null && ticketToUpdate.size()>0) {
            update ticketToUpdate;
        }
    }

    /*  @TestVisible private void syncTickets(list<Ticket_Issue__c> ticketList){

          for(Ticket_Issue__c t : ticketList){

              //curTorah.Name = Datetime.newInstance(curTorah.Date__c,Time.newInstance(0,0,0,0)).format('M/d/YYYY');
          }
      }*/



}