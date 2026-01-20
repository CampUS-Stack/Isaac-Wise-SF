/**
 * Created by Chris Home Desktop on 10/14/2018.
 */

public without sharing class CongrComm_MultiEventCtrl {

    //// TODO: Refactor this to custom setting to be controllable by administrators.
    private static final map<String,String> EVENT_TYPE_NAME_MAP = new map<String,String>{'Eitz' => 'Eitz Chayim Class','WiseUp' => 'WiseUp Project'};

    public Boolean ShowEventSelection {get; set;}
    public Boolean ShowParticipantRegistration {get; set;}

    public Event__c EventChosenForGuestEntry {get; set;}
    public String EventIdChosenForGuestEntry {get; set;}
    public String GuestTicketChoice {get; set;}
    public String GuestNameEntered {get; set;}
    public Boolean DisplayAdditionalFinalize {get; set;}


    public EventWrapper WrapperForGuest {get; set;}

    public list<EventWrapper> EventsForRegistration {get; set;}
    public list<EventWrapper> SelectedEventsForRegistration {
        get{

            list<EventWrapper> returnList = new list<EventWrapper>();
            if(EventsForRegistration == null){
                return returnList;
            }

            for(EventWrapper curWrap : EventsForRegistration){
                if(curWrap.IsSelected){
                    returnList.add(curWrap);
                }
            }

            return returnList;
        }
    }

    public String EventType {get; set;}

    public Integer NumberOfEventsForRegistration {
        get{
            if(EventsForRegistration == null){
                return 0;
            }
            else{
                return EventsForRegistration.size();
            }
        }
    }
    public Integer NumberOfSelectedEventsForRegistration {
        get{
            if(SelectedEventsForRegistration == null){
                return 0;
            }
            else{
                return SelectedEventsForRegistration.size();
            }
        }
    }

    //Added By Kritik 
    public Integer numberOfSelectedFamilyRegistration {
        get{
            if(SelectedEventsForRegistration == null){
                return 0;
            }
            else{

                Integer members = 0;

                for(EventWrapper ew : SelectedEventsForRegistration) {
                    members += ew.AttendingRegistrants.size();
                }

                return members;
            }
        }
    }

    public list<SelectOption> SelectedEventPricingOptions{
        get{
            list<SelectOption> returnList = new list<SelectOption>();
            if(EventChosenForGuestEntry == null){
                return returnList;
            }

            if(String.isNotBlank(EventChosenForGuestEntry.Individual_Pricing_1_Name__c)){
                returnList.add(new SelectOption('Pricing 1',EventChosenForGuestEntry.Individual_Pricing_1_Name__c + ' - $' + EventChosenForGuestEntry.Individual_Pricing_1__c));
            }
            if(String.isNotBlank(EventChosenForGuestEntry.Individual_Pricing_2_Name__c)){
                returnList.add(new SelectOption('Pricing 1',EventChosenForGuestEntry.Individual_Pricing_2_Name__c + ' - $' + EventChosenForGuestEntry.Individual_Pricing_2__c));
            }
            if(String.isNotBlank(EventChosenForGuestEntry.Individual_Pricing_3_Name__c)) {
                returnList.add(new SelectOption('Pricing 1', EventChosenForGuestEntry.Individual_Pricing_3_Name__c + ' - $' + EventChosenForGuestEntry.Individual_Pricing_3__c));
            }

            return returnList;
        }
    }

    public CongrComm_MultiEventCtrl() {

        this.EventIdChosenForGuestEntry = 'empty';
        this.ShowEventSelection = false;
        this.DisplayAdditionalFinalize = false;
        this.ShowParticipantRegistration = false;
        String eventTypeFromParam = getEventTypeParam();

        if(String.isBlank(eventTypeFromParam)){
            return;
        }
        if(!EVENT_TYPE_NAME_MAP.containsKey(eventTypeFromParam)){
            return;
        }

        this.EventType = EVENT_TYPE_NAME_MAP.get(eventTypeFromParam);
        system.debug(this.EventType);
        list<Event__c> events = CongrComm_EventUtilities.GetFutureEventsForMultipleRegistration(this.EventType);
        this.EventsForRegistration = createEventWrappers(events);
    }

    public void ChooseEventForGuestEdit(){

        for(EventWrapper curEventWrap : this.SelectedEventsForRegistration){
            if(curEventWrap.TheEvent.Id == EventIdChosenForGuestEntry){
                EventChosenForGuestEntry = curEventWrap.TheEvent;
                break;
            }
        }
    }

    public void BackToEventSelection(){

        this.ShowParticipantRegistration = false;
        this.ShowEventSelection = false;
    }

    public void BackToAddParticipants(){

        this.ShowParticipantRegistration = true;
        this.ShowEventSelection = false;
    }

    public void AddParticipants(){

        Contact currentContact = UtilitiesUsers.GetContactForCommunityUser(UserInfo.getUserId());
        for(EventWrapper curWrap : this.SelectedEventsForRegistration){
            curWrap.FamilyRegistrants = CongrComm_EventUtilities.GetRelatedContacts(currentContact.AccountId,curWrap.TheEvent);
        }
        this.ShowParticipantRegistration = true;
    }

    public void SelectEvents(){

        System.debug('SelectEvents---');
        this.ShowParticipantRegistration = false;
        this.ShowEventSelection = true;

        list<Event_Participant__c> participantsToInsert = new list<Event_Participant__c>();
        for(EventWrapper curEWrap : SelectedEventsForRegistration){

            for(CongrComm_EventUtilities.registrantWrapper curReg : curEWrap.AttendingRegistrants){

                Event_Participant__c participant = new Event_Participant__c();
                participant.Contact__c = curReg.TheContact.Id;
                participant.Event__c = curEWrap.TheEvent.Id;
                participantsToInsert.add(participant);
                System.debug('curReg:: '+curReg.TheContact +'::' + curReg);

                System.debug('participant:: '+participant +'::' + participant.Contact__c);
            }
        }

        try{
            insert participantsToInsert;
        }
        catch(DmlException de){
            system.debug(de.getMessage());
        }
    }

    public void SelectEventsGuest(){

        if(SelectedEventsForRegistration == null && SelectedEventsForRegistration.size() == 0){
            return;
        }

        Boolean registrantFound = false;
        for(EventWrapper curWrap : SelectedEventsForRegistration){
            if(curWrap.AttendingRegistrants != null && curWrap.AttendingRegistrants.size() > 0){
                registrantFound = true;
            }
        }

        if(!registrantFound){
            return;
        }

        Map<String,Contact> mapOfContactToInsert = new Map<String,Contact>();
        System.debug('SelectEvents---');
        this.ShowParticipantRegistration = false;
        this.ShowEventSelection = true;

        list<Event_Participant__c> participantsToInsert = new list<Event_Participant__c>();

        for(EventWrapper curEWrap : SelectedEventsForRegistration){

            for(CongrComm_EventUtilities.registrantWrapper curReg : curEWrap.AttendingRegistrants) {
                if(curReg.TheContact.Id == null ) {
                    curReg.TheContact.AccountId = UtilitiesCustomSetting.GetInstance().getImportantAccountSetting('Wise Temple Guest Account');
                    mapOfContactToInsert.put(curReg.TheContact.FirstName+curReg.TheContact.LastName+curReg.TheContact.Email, curReg.TheContact);
                    //System.debug('curReg.TheContact::'+curReg.TheContact);
                }
            }
        }
        System.debug('mapOfContactToInsert:: '+mapOfContactToInsert);
        insert mapOfContactToInsert.values() ;

        for(EventWrapper curEWrap : SelectedEventsForRegistration){

            for(CongrComm_EventUtilities.registrantWrapper curReg : curEWrap.AttendingRegistrants) {

                Event_Participant__c participant = new Event_Participant__c();
                if(curReg.TheContact.Id == null ) {
                    // System.debug('mapOfContactToInsert.get(curReg.TheContact.Email) ::' + mapOfContactToInsert.get(curReg.TheContact.Email));
                    participant.Contact__c = mapOfContactToInsert.get(curReg.TheContact.FirstName+curReg.TheContact.LastName+curReg.TheContact.Email).Id;
                } else {
                    participant.Contact__c = curReg.TheContact.Id;
                }
                participant.Event__c = curEWrap.TheEvent.Id;
                participantsToInsert.add(participant);
                System.debug('curReg:: '+curReg.TheContact +'::' + curReg);

                System.debug('participant:: '+participant +'::' + participant.Contact__c);
            }
        }

        try{
            System.debug('participantsToInsert' + participantsToInsert);
            insert participantsToInsert;
        }
        catch(DmlException de){
            system.debug(de.getMessage());
        }
    }

    @TestVisible private String getEventTypeParam(){

        if(ApexPages.currentPage().getParameters().containsKey('etype')){
            return ApexPages.currentPage().getParameters().get('etype');
        }
        else{
            return '';
        }
    }

    @TestVisible private list<EventWrapper> createEventWrappers(list<Event__c> events){

        list<EventWrapper> returnList = new list<EventWrapper>();
        for(Event__c curEvent : events){
            if(!curEvent.Display_on_portal__c) continue;
            EventWrapper wrap = new EventWrapper();
            wrap.TheEvent = curEvent;
            returnList.add(wrap);
        }
        return returnList;
    }


    public class EventWrapper{

        public Integer ADDITIONAL_SEARCH_COUNT {get; set;}
        public Boolean DisplayAdditionalFinalize {get; set;}

        public Event__c TheEvent {get; set;}
        public Boolean IsSelected {get; set;}
        public String SelectedPricingOption {get; set;}
        public String RegistrantNameToRemove {get; set;}

        public String FirstName {get; set;}
        public String LastName {get; set;}

        public String GuestFirstName {get; set;}
        public String GuestLastName {get; set;}
        public String GuestEmail {get; set;}
        public String GuestTicketType {get; set;}
            
        //To Check duplicate
        public Map<Id,Contact> mapOfContact {get;set;}

        public list<CongrComm_EventUtilities.registrantWrapper> Registrants {get; set;}
        public list<CongrComm_EventUtilities.registrantWrapper> FamilyRegistrants {get; set;}
        public list<CongrComm_EventUtilities.registrantWrapper> SelectedAttendingRegistrants {get; set;}
        public list<CongrComm_EventUtilities.registrantWrapper> AttendingGuestRegistrants {get; set;}
        public list<CongrComm_EventUtilities.registrantWrapper> AttendingFamilyRegistrants {get; set;}
        public list<CongrComm_EventUtilities.registrantWrapper> AttendingMemberRegistrants {get; set;}

        public list<CongrComm_EventUtilities.registrantWrapper> AttendingRegistrants{
            get {
                list<CongrComm_EventUtilities.registrantWrapper> returnList = new list<CongrComm_EventUtilities.registrantWrapper>();
                for (CongrComm_EventUtilities.registrantWrapper curWrap : AttendingGuestRegistrants) {
                    if (String.isNotBlank(curWrap.SelectedTicketType) && curWrap.SelectedTicketType != 'Not Attending') {
                        returnList.add(curWrap);
                    }
                }
                for (CongrComm_EventUtilities.registrantWrapper curWrap : AttendingFamilyRegistrants) {
                    if (String.isNotBlank(curWrap.SelectedTicketType) && curWrap.SelectedTicketType != 'Not Attending') {
                        returnList.add(curWrap);
                    }
                }
                for (CongrComm_EventUtilities.registrantWrapper curWrap : AttendingMemberRegistrants) {
                    if (String.isNotBlank(curWrap.SelectedTicketType) && curWrap.SelectedTicketType != 'Not Attending') {
                        returnList.add(curWrap);
                    }
                }

                return returnList;
            }
        }

        public Integer NumberOfAttendingRegistrants{

            get{
                if(AttendingRegistrants == null || AttendingRegistrants.size() == 0) {
                    return 0;
                }

                return AttendingRegistrants.size();

            }
        }
        public Integer NumberOfAttendingGuestRegistrants{

            get{
                if(AttendingGuestRegistrants == null || AttendingGuestRegistrants.size() == 0) {
                    return 0;
                }

                return AttendingGuestRegistrants.size();

            }
        }
        public Integer NumberOfSelectedAttendingRegistrants{

            get{
                if(SelectedAttendingRegistrants == null || SelectedAttendingRegistrants.size() == 0) {
                    return 0;
                }

                return SelectedAttendingRegistrants.size();

            }
        }

        public Integer NumberOfRegistrants{

            get{
                if(Registrants == null || Registrants.size() == 0) {
                    return 0;
                }

                return Registrants.size();

            }
        }

        public list<SelectOption> PricingOptions {
            get{
                list<SelectOption> returnList = new list<SelectOption>();
                returnList.add(new SelectOption('','Not Attending'));

                if(TheEvent == null){
                    return returnList;
                }

                if(String.isNotBlank(TheEvent.Individual_Pricing_1_Name__c)){
                    returnList.add(new SelectOption('Pricing 1',TheEvent.Individual_Pricing_1_Name__c));
                }
                if(String.isNotBlank(TheEvent.Individual_Pricing_2_Name__c)){
                    returnList.add(new SelectOption('Pricing 2',theEvent.Individual_Pricing_2_Name__c));
                }
                if(String.isNotBlank(TheEvent.Individual_Pricing_3_Name__c)){+
                        returnList.add(new SelectOption('Pricing 3',TheEvent.Individual_Pricing_3_Name__c));
                }

                return returnList;
            }
        }

        public EventWrapper(){

            mapOfContact = new Map<Id,Contact>();

            this.Registrants = new list<CongrComm_EventUtilities.registrantWrapper>();
            this.FamilyRegistrants = new list<CongrComm_EventUtilities.registrantWrapper>();
            this.SelectedAttendingRegistrants = new list<CongrComm_EventUtilities.registrantWrapper>();
            this.AttendingGuestRegistrants = new list<CongrComm_EventUtilities.registrantWrapper>();
            this.AttendingFamilyRegistrants = new list<CongrComm_EventUtilities.registrantWrapper>();
            this.AttendingMemberRegistrants = new list<CongrComm_EventUtilities.registrantWrapper>();

            this.DisplayAdditionalFinalize = false;
            IsSelected = false;

            SelectedPricingOption= '';
        }

        public PageReference AddSelectedMemberRegistrants() {
            DisplayAdditionalFinalize = false;
            SelectedAttendingRegistrants.clear();
            AddSelectedToList(Registrants,AttendingMemberRegistrants);
            system.debug(this.AttendingMemberRegistrants);
            FirstName = '';
            LastName = '';
            return null;
        }

        public PageReference AddSelectedFamilyRegistrants(){

            AttendingFamilyRegistrants.clear();
            AddSelectedToList(FamilyRegistrants,AttendingFamilyRegistrants);
            this.AttendingMemberRegistrants = new list<CongrComm_EventUtilities.registrantWrapper>();
            return null;
        }

        public PageReference AddGuestRegistrant(){

            if(this.SelectedPricingOption == null || this.SelectedPricingOption == '') {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error,'Select ticket type'));
                return null;
            }

            Contact existingContact;
            CongrComm_EventUtilities.registrantWrapper wrap = new CongrComm_EventUtilities.registrantWrapper();
            wrap.FirstName = this.GuestFirstName;
            wrap.LastName = this.GuestLastName;
            wrap.Email = this.GuestEmail;

            if(String.isNotBlank(wrap.Email)){
                existingContact = checkForExistingContact(wrap.Email);
            }

            if(existingContact != null) {
                system.debug('Found Contact');
                wrap.TheContact = existingContact;
            } else {
                wrap.TheContact = new Contact();
                wrap.TheContact.FirstName = this.GuestFirstName;
                wrap.TheContact.LastName = this.GuestLastName;
                wrap.TheContact.Email = this.GuestEmail;
            }

            wrap.SelectedTicketType = this.SelectedPricingOption;
            wrap.Pricing1 = this.theEvent.Individual_Pricing_1__c;
            wrap.Pricing2 = this.theEvent.Individual_Pricing_2__c;
            wrap.Pricing3 = this.theEvent.Individual_Pricing_3__c;
            wrap.Pricing1Name = this.theEvent.Individual_Pricing_1_Name__c;
            wrap.Pricing2Name = this.theEvent.Individual_Pricing_2_Name__c;
            wrap.Pricing3Name = this.theEvent.Individual_Pricing_3_Name__c;
            System.debug('Working on contact');
            this.AttendingGuestRegistrants.add(wrap);

            this.GuestTicketType = '';
            this.GuestEmail = '';
            this.GuestLastName = '';
            this.GuestFirstName = '';
            System.debug('returning on contact');

            return null;
        }

        @TestVisible private Contact checkForExistingContact(String email){
            try{
                Contact returnContact = [SELECT Id, FirstName, LastName, Name, Email FROM Contact WHERE Email = :email];
                return returnContact;
            }
            catch(QueryException qe){
                system.debug(qe.getMessage());
                return null;
            }
        }

        public PageReference LoadMoreAdditionalRegistrantSearchResults(){

            ADDITIONAL_SEARCH_COUNT = ADDITIONAL_SEARCH_COUNT + 5;
            UtilitiesEvents.ADDITIONAL_SEARCH_COUNT = ADDITIONAL_SEARCH_COUNT;
            Registrants =  UtilitiesEvents.getAdditionalRegistrantResults(firstName,lastName,TheEvent);

            return null;
        }

        public PageReference GoToFinalizeAdditionalRegistrant(){

            //SelectedAttendingRegistrants.clear(); 
            DisplayAdditionalFinalize = true;
            if(setSelectedAdditionalRegistrants() == false) {
                DisplayAdditionalFinalize = false;
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error,'Select ticket type'));         
            } 
            return null;
        }

        public PageReference GoBackToAdditionalRegistrantSearch(){
            DisplayAdditionalFinalize = false;
            return null;
        }

        public PageReference RunMemberSearch(){

            Registrants.clear();
            ADDITIONAL_SEARCH_COUNT = 10;
            Registrants = UtilitiesEvents.getAdditionalRegistrantResults(firstName,lastName,TheEvent);

            return null;
        }

        public PageReference RemoveSelectedParticipant(){

            System.debug('Test KRK :: ' + RegistrantNameToRemove);
            list<CongrComm_EventUtilities.registrantWrapper> familyToReAdd = new list<CongrComm_EventUtilities.registrantWrapper>();
            list<CongrComm_EventUtilities.registrantWrapper> guestsToReAdd = new list<CongrComm_EventUtilities.registrantWrapper>();
            list<CongrComm_EventUtilities.registrantWrapper> additionalsToReAdd = new list<CongrComm_EventUtilities.registrantWrapper>();
            for(CongrComm_EventUtilities.registrantWrapper curWrap : AttendingMemberRegistrants){
                System.debug('loop: ' +curWrap.TheContact + '::: ' + RegistrantNameToRemove);
                if((curWrap.TheContact.FirstName + ' ' +curWrap.TheContact.LastName) != RegistrantNameToRemove ){
                    guestsToReAdd.add(curWrap);
                }
            }
            for(CongrComm_EventUtilities.registrantWrapper curWrap : AttendingGuestRegistrants){
                System.debug('loop2: ' +curWrap.TheContact + '::: ' + RegistrantNameToRemove);
                //if(curWrap.TheContact.Name != RegistrantNameToRemove){
                if((curWrap.TheContact.FirstName + ' ' +curWrap.TheContact.LastName) != RegistrantNameToRemove ){
                    additionalsToReAdd.add(curWrap);
                }
            }
            for(CongrComm_EventUtilities.registrantWrapper curWrap : AttendingFamilyRegistrants){
                //if(curWrap.TheContact.Name != RegistrantNameToRemove){
                if((curWrap.TheContact.FirstName + ' ' +curWrap.TheContact.LastName) != RegistrantNameToRemove ){
                    familyToReAdd.add(curWrap);
                }
            }
            AttendingMemberRegistrants.clear();
            AttendingGuestRegistrants.clear();
            AttendingFamilyRegistrants.clear();

            for(CongrComm_EventUtilities.registrantWrapper  curWrap : guestsToReAdd){
                AttendingGuestRegistrants.add(curWrap);
            }
            for(CongrComm_EventUtilities.registrantWrapper  curWrap : additionalsToReAdd){
                AttendingMemberRegistrants.add(curWrap);
            }
            for(CongrComm_EventUtilities.registrantWrapper  curWrap : familyToReAdd){
                AttendingFamilyRegistrants.add(curWrap);
            }

            return null;
        }

/*         @TestVisible private void setSelectedAdditionalRegistrants(){

            for(CongrComm_EventUtilities.registrantWrapper curWrap : Registrants){

                if(String.isNotBlank(curWrap.SelectedTicketType))
                    SelectedAttendingRegistrants.add(curWrap);
            }

        }
 */
        @TestVisible private Boolean setSelectedAdditionalRegistrants(){
            Boolean ticketSelected = false;
            for(CongrComm_EventUtilities.registrantWrapper curWrap : Registrants){
                if(String.isNotBlank(curWrap.SelectedTicketType) && !mapOfContact.containsKey(curWrap.TheContact.Id)) {
                    SelectedAttendingRegistrants.add(curWrap);
                    mapOfContact.put(curWrap.TheContact.Id,curWrap.TheContact);
                    ticketSelected = true;
                }
            }

            return ticketSelected;
        }

        public PageReference AddSelectedToList(list<CongrComm_EventUtilities.registrantWrapper> listToCheck, list<CongrComm_EventUtilities.registrantWrapper> listToAdd){

            system.debug(listToAdd);
            for(CongrComm_EventUtilities.registrantWrapper curWrap : listToCheck){

                system.debug(curWrap.TheContact.Id + ' Is Selected ' + curWrap.SelectedTicketType);
                if(String.isNotBlank(curWrap.SelectedTicketType)) {
                    listToAdd.add(curWrap);
                }
            }

            return null;
        }
    }
}