/**
 * Created by Chris Home Desktop on 8/9/2017.
 */

public with sharing class ManageParticipantsController {

    public Boolean displayAddContact {get; set;}

    public list<UtilitiesWrappers.ContactWrapper> TheContacts {get; set;}
    public list<UtilitiesWrappers.ContactWrapper> AttendingContacts {get; set;}

    public String ContactNameToSearch {get; set;}

    public String ContactIdToAdd {get; set;}
    public String ContactIdToRemove {get; set;}

    public Event__c TheEvent {get; set;}
    public Event__c DummyEvent {get; set;}

    /// Sorting Variables
    public String selectedField {get; set;}
    public String selectedSortOrder {get; set;}

    public ManageParticipantsController(ApexPages.StandardController stdController){

        this.DummyEvent = new Event__c();
        this.TheEvent = getEvent(stdController.getId());
        this.displayAddContact = false;
        this.ContactNameToSearch = '';
        this.selectedField = 'LastName';
        this.selectedSortOrder = 'ASC';
        this.TheContacts = new list<UtilitiesWrappers.ContactWrapper>();
        this.AttendingContacts = new list<UtilitiesWrappers.ContactWrapper>();

        RunContactSearches();
    }

    public void ShowAddParticipantSection(){

        if(displayAddContact == false){
            displayAddContact = true;
        }
    }

    public PageReference UnShowAddParticipantSection(){

        if(displayAddContact == true){
            displayAddContact = false;
        }

        return null;
    }


    /**
     *  @Author: Chris Gibson
     *  @Date: 07.02.2017
     *
     *  @Purpose: This method changes the sort order based on what the page currently has and also provides an opportunity for the
     *              selected field variable to be set.
     *
     *
     *  @PostCondition:
     */
    public void changeSortColumn(){

        if(this.selectedSortOrder == null){
            this.selectedSortOrder = 'ASC';
        }
        else if(this.selectedSortOrder == 'ASC'){
            this.selectedSortOrder = 'DESC';
        }
        else{
            this.selectedSortOrder = 'ASC';
        }

        RunContactSearches();
    }

    public PageReference RunContactSearches(){

        PopulateAttendingContacts();

        set<Id> attendingContactIds = getAttendingContactId();
        String soql = 'SELECT Id,Name,Account.Name,Contact_Type__c,FirstName,LastName FROM Contact c WHERE Id NOT IN :attendingContactIds';
        soql += getContactNameSOQLFilter();
        soql += getClassSOQLFilter();
        soql += getContactTypeSOQLFilter();
        soql += ' ORDER BY ' + this.selectedField + ' ' + this.selectedSortOrder;
        soql += ' limit 500';

        try{
            list<Contact> contacts = Database.query(soql);
            this.TheContacts = UtilitiesWrappers.createContactWrappers(contacts);
            system.debug(this.TheContacts);
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
        }

        return null;
    }

    @TestVisible private Event__c getEvent(String eventId){

        try{
            Event__c theEvent = [SELECT Id,Name,Parent_Program__c  FROM Event__c WHERE Id = :eventId];
            return theEvent;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return null;
        }
    }


    public PageReference RemoveParticipant(){

        system.debug(this.ContactIdToRemove);

        set<Id> contactIdsToRemove = new set<Id>();

        for(UtilitiesWrappers.ContactWrapper curWrap : this.AttendingContacts){
            if(curWrap.isSelected)
                contactIdsToRemove.add(curWrap.theContact.Id);
        }

        if(contactIdsToRemove.size() == 0){
            return null;
        }

        try{
            list<Event_Participant__c> eps = [SELECT Id,Name FROM Event_Participant__c WHERE Contact__c in :contactIdsToRemove AND Event__c = :this.TheEvent.Id];
            delete eps;
        }
        catch(DmlException de){
            system.debug(de.getMessage());
        }

        RunContactSearches();

        return null;
    }

    public PageReference MarkParticipantsAsAttending(){

        list<Event_Participant__c> participantsList = new list<Event_Participant__c>();
        for(UtilitiesWrappers.ContactWrapper curWrapper : this.AttendingContacts){

            if(curWrapper != null && curWrapper.isSelected){
                curWrapper.participant.Attended__c = true;
                participantsList.add(curWrapper.participant);
                curWrapper.isSelected = false;
            }
        }

        system.debug(participantsList);
        if(participantsList.size() == 0){
            return null;
        }

        try{
            update participantsList;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
        }
        catch(DmlException de){
            system.debug(de.getMessage());
        }

        return null;
    }

    @TestVisible private list<Event_Participant__c> getEventParticipants(set<Id> contactIds){
        try{
            list<Event_Participant__c> eventParticipants = [SELECT Id,Attended__c,Contact__c  FROM Event_Participant__c WHERE Contact__c in :contactIds AND Event__c = :this.TheEvent.Id];
            return eventParticipants;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return null;
        }
    }

    public PageReference AddSelectedContacts(){

        list<Event_Participant__c> eventParticipants = new list<Event_Participant__c>();

        for(UtilitiesWrappers.ContactWrapper curWrapper : this.TheContacts){

            system.debug(curWrapper);
            if(curWrapper != null && curWrapper.isSelected){
                Event_Participant__c eventParticipant = new Event_Participant__c();
                eventParticipant.Contact__c = curWrapper.theContact.Id;
                eventParticipant.Event__c = this.TheEvent.Id;
                eventParticipants.add(eventParticipant);
            }
        }

        insert eventParticipants;

        RunContactSearches();

        return null;
    }

    public PageReference ClearAddParticipantForm(){

        this.ContactNameToSearch = '';
        RunContactSearches();
        return null;
    }

    @TestVisible private String getContactNameSOQLFilter(){

        if(!String.isEmpty(this.ContactNameToSearch)){
            return ' AND Name LIKE \'%' + this.ContactNameToSearch  + '%\'';
        }

        return '';
    }

    @TestVisible private String getContactTypeSOQLFilter(){

        return ' AND Contact_Type__c !=  \'Deceased\'' ;
    }

    @TestVisible private String getClassSOQLFilter(){

        system.debug(this.DummyEvent.Parent_Program__c);
        if(!String.isEmpty(this.DummyEvent.Parent_Program__c)){
            return ' AND Id IN (SELECT Contact__c FROM Event_Participant__c WHERE Event__c = \'' + this.DummyEvent.Parent_Program__c + '\')';
        }

        return '';
    }

    @TestVisible private void PopulateAttendingContacts(){
        if(this.TheEvent == null){
            return;
        }

        String soql = 'SELECT Id,Name,Account.Name,Contact_Type__c,FirstName,LastName FROM Contact c WHERE Id IN (SELECT Contact__c FROM Event_Participant__c WHERE Event__c = \'' + this.TheEvent.Id + '\') ORDER BY LastName';

        soql += ' limit 250';
        try{
            list<Contact> contacts = Database.query(soql);
            map<Id,Contact> contactsById = new map<Id,Contact>(contacts);
            list<Event_Participant__c> participants = getEventParticipants(contactsById.keySet());
            map<Id,Event_Participant__c> participantsByContactId = new map<Id,Event_Participant__c>();
            for(Contact c :contacts){
                for(Event_Participant__c p : participants){
                    if(p.Contact__c == c.Id){
                        participantsByContactId.put(c.Id,p);
                        break;
                    }
                }
            }
            this.AttendingContacts = UtilitiesWrappers.createContactWrappers(contacts,participantsByContactId);
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
        }
    }

    @TestVisible private set<Id> getAttendingContactId(){
        if(this.AttendingContacts == null){
            return null;
        }

        set<Id> returnSet = new set<Id>();
        for(UtilitiesWrappers.ContactWrapper curWrapper : this.AttendingContacts){

            if(!String.isEmpty(curWrapper.theContact.Id))
                returnSet.add(curWrapper.theContact.Id);
        }
        return returnSet;

    }

}