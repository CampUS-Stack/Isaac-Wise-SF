/**
 * Created by UD Office Chris on 12/17/2018.
 */

public without sharing class  CongrComm_EventGuestController {


    public static final String CONTACT_SOQL_FIELDS = 'Id, Name, FirstName, LastName, AccountId FROM Contact';

    public static final String QUESTION_FIELD_PREFIX = 'Question_';
    public static final String ANSWER_FIELD_PREFIX = 'Answer_';

    public Boolean DisplayAdditionalFinalize {get; set;}
    public Integer ADDITIONAL_SEARCH_COUNT {get; set;}

    Public Event__c theEvent {get; set;}
    public Date EventStartDate {
        get{
            if(theEvent != null && theEvent.Event_Date_Start__c != null){
                return Date.newInstance(theEvent.Event_Date_Start__c.year(),theEvent.Event_Date_Start__c.month(),theEvent.Event_Date_Start__c.day());
            }

            return Date.newInstance(2000,12,21);
        }
    }

    public Double offset{get{
        TimeZone tz = UserInfo.getTimeZone();
        return tz.getOffset(DateTime.now()) / (1000 * 3600 * 24.0);
    }}

    public String EventDescription {get; set;}
    Public Boolean hasErrors {get; set;}
    public Boolean disableRegBtn {get; set;}
    Public String FirstName {get; set;}
    Public String LastName {get; set;}
    public String Email {get; set;}
    public String Phone {get; set;}
    public String TicketType {get; set;}
    Public String Comments {get; set;}

    public String GuestFirstName {get; set;}
    public String GuestLastName {get; set;}
    public String GuestEmail {get; set;}
    public String GuestTicketType {get; set;}

    public String RegistrantNameToRemove {get; set;}

    public String RegistrantSearchName {get; set;}

    public String SelectedFamilyMemberId {get; set;}
    public String SelectedTicketType {get; set;}

    public Decimal EventPrice {get; set;}

    //// Guest Page Specific variables
    public CongrComm_EventUtilities.registrantWrapper GuestPageWrapper {get; set;}
    public list<CongrComm_EventUtilities.registrantWrapper> GuestPageRegistrants {get; set;}
    //// End Guest Page Specific variables

    public list<CongrComm_EventUtilities.registrantWrapper> GuestRegistrants {get; set;}
    public list<CongrComm_EventUtilities.registrantWrapper> SelectedGuestRegistrants {get; set;}
    //// End Member Page Specific variables

    @TestVisible private Assessment__c assessment {get; set;}

    //Added by Kritik : Task CORS-T77
    public List<QuestionWrapper> listOfQuestionWrapper {get;set;}

    public Integer NumberOfAllRegistrants{
        get{
            Integer returnCount = 0;
            if(SelectedGuestRegistrants != null){
                returnCount += SelectedGuestRegistrants.size();
            }
            return returnCount;
        }
    }


    public Integer NumberOfGuestRegistrants{
        get{
            return getListSize(GuestRegistrants);
        }
    }

    public Integer NumberOfSelectedGuestRegistrants{
        get{
            //System.debug('SelectedGuestRegistrants' + getListSize(SelectedGuestRegistrants));
            return getListSize(SelectedGuestRegistrants);
        }
    }

    public Decimal TotalRegistrantPrice  {
        get{

            Double returnValue = 0.00;

            if(!theEvent.Paid_Event__c){
                return returnValue;
            }

            if(GuestPageWrapper != null && String.isNotBlank(GuestPageWrapper.SelectedTicketType)){

                returnValue += GuestPageWrapper.Price;
                System.debug('GuestPageWrapper return value'+returnValue);
            }

            if(SelectedGuestRegistrants != null && SelectedGuestRegistrants.size() != 0){
                for(CongrComm_EventUtilities.registrantWrapper curWrap : SelectedGuestRegistrants){
                    if(curWrap.Price != null && curWrap.Price != 0.00){
                        returnValue += curWrap.Price;
                    }
                }
            }

            return returnValue;
        }
    }

    public Decimal TotalPrice  {
        get{
            Decimal returnValue = 0.00;

            if(!theEvent.Paid_Event__c){
                return returnValue;
            }

            returnValue = TotalRegistrantPrice;
            System.debug('returnValue= '+ returnValue);
            System.debug('Max_Price__c= '+ theEvent.Max_Price__c);

            if(theEvent != null && theEvent.Max_Price__c != null && theEvent.Max_Price__c != 0 && returnValue > theEvent.Max_Price__c){
                return theEvent.Max_Price__c;
            }
            else{
                return returnValue;
            }
        }
    }

    public Decimal GuestTotalPrice  {
        get{
            Decimal returnValue = 0.00;

            if(!theEvent.Paid_Event__c){
                return returnValue;
            }

            if(GuestPageRegistrants != null && GuestPageRegistrants.size() != 0){
                for(CongrComm_EventUtilities.registrantWrapper curWrap : GuestPageRegistrants){
                    if(curWrap.Price != null || curWrap.Price != 0.00){
                        returnValue += curWrap.Price;
                    }
                }
            }

            if(theEvent != null && theEvent.Max_Price__c != null && theEvent.Max_Price__c != 0 && returnValue > theEvent.Max_Price__c){
                return theEvent.Max_Price__c;
            }
            else{
                return returnValue;
            }
        }
    }

    public Decimal TotalAdditionalRegistrantFees  {
        get{
            Decimal returnValue = 0.00;

            if(!theEvent.Paid_Event__c){
                return returnValue;
            }
            if(TotalRegistrantPrice == null){
                return returnValue;
            }

            returnValue = (TotalRegistrantPrice * .025).setScale(2);

            return returnValue;
        }
    }

    public list<SelectOption> PricingOptions{
        get{
            list<SelectOption> returnList = new list<SelectOption>();
            returnList.add(new SelectOption('','Choose a Ticket'));

            if(this.theEvent == null){
                return returnList;
            }

            if(String.isNotBlank(theEvent.Individual_Pricing_1_Name__c)){
                SelectOption so = new SelectOption('Pricing 1',theEvent.Individual_Pricing_1_Name__c + ' - $' + theEvent.Individual_Guest_Pricing_1__c);
                returnList.add(so);
            }
            if(String.isNotBlank(theEvent.Individual_Pricing_2_Name__c)){
                SelectOption so = new SelectOption('Pricing 2',theEvent.Individual_Pricing_2_Name__c + ' - $' + theEvent.Individual_Guest_Pricing_2__c);
                returnList.add(so);
            }
            if(String.isNotBlank(theEvent.Individual_Pricing_3_Name__c)){
                SelectOption so = new SelectOption('Pricing 3',theEvent.Individual_Pricing_3_Name__c + ' - $' + theEvent.Individual_Guest_Pricing_3__c);
                returnList.add(so);
            }

            return returnList;
        }
    }

    public list<SelectOption> TicketOptions{
        get{
            list<SelectOption> returnList = new list<SelectOption>();
            returnList.add(new SelectOption('','Not Attending'));

            if(this.theEvent == null){
                return returnList;
            }

            if(String.isNotBlank(theEvent.Individual_Pricing_1_Name__c)){
                SelectOption so = new SelectOption('Pricing 1',theEvent.Individual_Pricing_1_Name__c);
                returnList.add(so);
            }
            if(String.isNotBlank(theEvent.Individual_Pricing_2_Name__c)){
                SelectOption so = new SelectOption('Pricing 2',theEvent.Individual_Pricing_2_Name__c);
                returnList.add(so);
            }
            if(String.isNotBlank(theEvent.Individual_Pricing_3_Name__c)){
                SelectOption so = new SelectOption('Pricing 3',theEvent.Individual_Pricing_3_Name__c);
                returnList.add(so);
            }

            return returnList;
        }
    }

    /// --------------------------------------- Private Helper Methods ----------------------------------- \\\\\

    /**
     * @author Chris Gibson
     * @date 10.20.2018
     *
     * @description 0 param consturctor for "CongrComm_EventPage' VF page
     */
    Public CongrComm_EventGuestController(){
//        String eventId = ApexPages.currentPage().getParameters().get('id');
//
//        // Updated by Kritik
//        //theEvent = CongrComm_EventUtilities.GetEventwithQuestions(eventId);
//        theEvent = CongrComm_EventUtilities.GetPortalEventwithQuestions(eventId);
////        if(theEvent.Display_on_portal__c == false){
////            PageReference pageRef = Page.CongrComm_EventRegistrationClosed;
////            pageRef.getParameters().put('id', eventId);
////            pageRef.setRedirect(true);
////            return pageRef;
////        }
//
////        this.EventPrice = theEvent.Event_Price__c;
//        initializeVariables();
//
//        createQuestionWrappers();
//
//        disableRegBtn = true;
////        return null;
//
    }
    
    Public PageReference onLoad(){
        String eventId = ApexPages.currentPage().getParameters().get('id');
    
        // Updated by Kritik
        //theEvent = CongrComm_EventUtilities.GetEventwithQuestions(eventId);
        theEvent = CongrComm_EventUtilities.GetPortalEventwithQuestions(eventId);
        if(theEvent.Display_on_portal__c == false){
            PageReference pageRef = Page.CongrComm_EventRegistrationClosed;
            pageRef.getParameters().put('id', eventId);
            pageRef.setRedirect(true);
            return pageRef;
        }

//        this.EventPrice = theEvent.Event_Price__c;
        initializeVariables();
    
        createQuestionWrappers();
    
        disableRegBtn = true;
        return null;
    }

    Public PageReference save(){

        System.debug('save function init');
        if(ValidatePage()){
            system.debug('Validation Failed');
            return null;
        }

        insertAllRecords();

        Payment_Adjustment__c eventPayment = createEventPayment(this.assessment);
        Payment_Adjustment__c reQueriedPayment = [SELEcT Id,Name, (SELECT Id FROM Scheduled_Payment_Bridges__r) FROM Payment_Adjustment__c WHERE Id = :eventPayment.Id];

        UtilitiesFinancials.UpdatePaymentBridgesWebsiteValues(reQueriedPayment.Scheduled_Payment_Bridges__r);

        
//        PageReference pr = Page.CongrComm_ManagePaymentVaults;
//        pr.getParameters().put('paId', reQueriedPayment.Id);
//        pr.setRedirect(true);

        PageReference pr = Page.CongrComm_NMIPaymentProcessor;
        pr.getParameters().put('paId', reQueriedPayment.Id);
        pr.getParameters().put('isGuest', 'true');
        pr.setRedirect(true);
        return pr;

    }



    Public PageReference saveNonPaidEvent(){

        System.debug('save function init');
        if(ValidatePage()){
            system.debug('Validation Failed');
            return null;
        }

        insertAllRecordsForFreeEvent();

        PageReference pr = Page.CongrComm_ThanksFreeEvent;
        pr.getParameters().put('pId',theEvent.Id);
        pr.setRedirect(true);
        return pr;

    }

    @TestVisible private void insertAllRecordsForFreeEvent(){


        list<Event_Participant__c> participantsToCreate = new list<Event_Participant__c>();

        Contact existingContact;
        if(String.isNotBlank(GuestPageWrapper.Email)){
            existingContact = checkForExistingContact(GuestPageWrapper.Email);
        }

        if(existingContact != null) {
            system.debug('Found Contact');
            GuestPageWrapper.TheContact = existingContact;
            //this.SelectedGuestRegistrants.add(curWrap);
        }
        else {
            system.debug('Creating new contact');
            GuestPageWrapper.TheContact.FirstName = GuestPageWrapper.FirstName;
            GuestPageWrapper.TheContact.LastName = GuestPageWrapper.LastName;
            GuestPageWrapper.TheContact.Email = GuestPageWrapper.Email;
            //GuestPageWrapper.TheContact.Phone = GuestPageWrapper.Phone;
            GuestPageWrapper.TheContact.Mobile_Phone__c = GuestPageWrapper.Phone;
            GuestPageWrapper.TheContact.AccountId = UtilitiesCustomSetting.GetInstance().getImportantAccountSetting('Wise Temple Guest Account');
            //this.SelectedGuestRegistrants.add(curWrap);
        }


        processGuestParticipants();

        list<Event_Participant__c> guestParticipantsToCreate = createEventParticipants(SelectedGuestRegistrants,true);
        guestParticipantsToCreate.addAll(createEventParticipants(new list<CongrComm_EventUtilities.registrantWrapper>{GuestPageWrapper},true));

        participantsToCreate.addAll(guestParticipantsToCreate);

        system.debug('Particiapnts to Create:');
        system.debug(participantsToCreate);

        try{
            if(participantsToCreate != null){
                system.debug('Participants to create: ' + participantsToCreate);
                insert participantsToCreate;
            }

        } catch(DmlException de){
            system.debug(de.getMessage());
            system.debug(de.getLineNumber());
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'There was a problem adding the new Event Participant.  Please check your submission and try again.  If the problem persists, contact your system administrator.'));
        }
    }

    public PageReference RemoveSelectedParticipant(){

        System.debug('Test KRK :: ' + RegistrantNameToRemove);
        list<CongrComm_EventUtilities.registrantWrapper> guestsToReAdd = new list<CongrComm_EventUtilities.registrantWrapper>();
        System.debug('SelectedGuestRegistrants : ' + SelectedGuestRegistrants.size());

        if(GuestPageWrapper.TheContact.FirstName + ' ' + GuestPageWrapper.TheContact.LastName == RegistrantNameToRemove ){
            GuestPageWrapper = new CongrComm_EventUtilities.registrantWrapper();
            GuestPageWrapper.TheContact = new Contact();
            GuestPageWrapper.Pricing1 = this.theEvent.Individual_Pricing_1__c;
            GuestPageWrapper.Pricing2 = this.theEvent.Individual_Pricing_2__c;
            GuestPageWrapper.Pricing3 = this.theEvent.Individual_Pricing_3__c;
            GuestPageWrapper.GuestPricing1 = this.theEvent.Individual_Guest_Pricing_1__c;
            GuestPageWrapper.GuestPricing2 = this.theEvent.Individual_Guest_Pricing_2__c;
            GuestPageWrapper.GuestPricing3 = this.theEvent.Individual_Guest_Pricing_3__c;
            GuestPageWrapper.Pricing1Name = this.theEvent.Individual_Pricing_1_Name__c;
            GuestPageWrapper.Pricing2Name = this.theEvent.Individual_Pricing_2_Name__c;
            GuestPageWrapper.Pricing3Name = this.theEvent.Individual_Pricing_3_Name__c;
            GuestPageWrapper.SelectedTicketType = '';
        }

        for(CongrComm_EventUtilities.registrantWrapper curWrap : SelectedGuestRegistrants){
            System.debug('loop: ' +curWrap.TheContact + '::: ' + RegistrantNameToRemove);
            if((curWrap.TheContact.FirstName + ' ' +curWrap.TheContact.LastName) != RegistrantNameToRemove ){
                guestsToReAdd.add(curWrap);
            }
        }
        SelectedGuestRegistrants.clear();

        for(CongrComm_EventUtilities.registrantWrapper  curWrap : guestsToReAdd){
            //SelectedAdditionalRegistrants.add(curWrap);
            SelectedGuestRegistrants.add(curWrap);
        }

        return null;
    }


    public PageReference AddGuestRegistrant() {

        if(this.GuestTicketType == null || this.GuestTicketType == '') {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error,'Select ticket type'));
            return null;
        }

        CongrComm_EventUtilities.registrantWrapper wrap = new CongrComm_EventUtilities.registrantWrapper();
        wrap.FirstName = this.GuestFirstName;
        wrap.LastName = this.GuestLastName;
        wrap.Email = this.GuestEmail;
        wrap.SelectedTicketType = this.GuestTicketType;
        wrap.Pricing1 = this.theEvent.Individual_Pricing_1__c;
        wrap.Pricing2 = this.theEvent.Individual_Pricing_2__c;
        wrap.Pricing3 = this.theEvent.Individual_Pricing_3__c;
        wrap.GuestPricing1 = this.theEvent.Individual_Guest_Pricing_1__c;
        wrap.GuestPricing2 = this.theEvent.Individual_Guest_Pricing_2__c;
        wrap.GuestPricing3 = this.theEvent.Individual_Guest_Pricing_3__c;
        wrap.isGuest = true;
        wrap.Pricing1Name = this.theEvent.Individual_Pricing_1_Name__c;
        wrap.Pricing2Name = this.theEvent.Individual_Pricing_2_Name__c;
        wrap.Pricing3Name = this.theEvent.Individual_Pricing_3_Name__c;
        this.GuestRegistrants.add(wrap);

        this.GuestTicketType = '';
        this.GuestEmail = '';
        this.GuestLastName = '';
        this.GuestFirstName = '';

        if(GuestRegistrants.size()>0) {
            disableRegBtn = false;
        } else {
            disableRegBtn = true;
        }

        return null;
    }

    public PageReference RegisterGuestRegistrants(){
        this.SelectedGuestRegistrants.clear();

        if(GuestRegistrants == null || GuestRegistrants.size() < 1) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error,'Add guest to register'));
            return null;
        }

        for(CongrComm_EventUtilities.registrantWrapper curWrap : this.GuestRegistrants){

            Contact existingContact;
            system.debug(curWrap.Email );
            system.debug(GuestEmail );
            if(String.isNotBlank(curWrap.Email) && curWrap.Email != GuestPageWrapper.Email){
                //Updated By Kritik
                //existingContact = checkForExistingContact(this.GuestEmail);
                existingContact = checkForExistingContact(curWrap.Email);
            }

            if(existingContact != null){
                system.debug('Found Guest Contact');
                curWrap.TheContact = existingContact;
                curWrap.TheContact.FirstName = curWrap.FirstName;
                curWrap.TheContact.LastName = curWrap.LastName;
                this.SelectedGuestRegistrants.add(curWrap);
            }
            else{
                system.debug('Creating new Guest contact');
                Contact newContact = new Contact();
                newContact.FirstName = curWrap.FirstName;
                newContact.LastName = curWrap.LastName;
                newContact.Email = curWrap.Email;
                newContact.AccountId = UtilitiesCustomSetting.GetInstance().getImportantAccountSetting('Wise Temple Guest Account');
                curWrap.TheContact = newContact;
                this.SelectedGuestRegistrants.add(curWrap);

            }
        }

        system.debug(this.SelectedGuestRegistrants);

        return null;
    }

    Public PageReference cancel(){
        return null;

    }

    public PageReference GoBackToAdditionalRegistrantSearch(){
        DisplayAdditionalFinalize = false;
        return null;
    }



    /// --------------------------------------- Private Helper Methods ----------------------------------- \\\\\

    @TestVisible private void initializeVariables(){

        this.hasErrors = false;
        this.DisplayAdditionalFinalize = false;

        this.SelectedFamilyMemberId = '';
        this.GuestEmail = '';
        this.GuestFirstName = '';
        this.GuestLastName = '';
        this.GuestTicketType = '';
        this.RegistrantNameToRemove = '';

        this.ADDITIONAL_SEARCH_COUNT = 10;

        this.listOfQuestionWrapper = new List<QuestionWrapper>();
        this.GuestRegistrants = new list<CongrComm_EventUtilities.registrantWrapper>();
        this.SelectedGuestRegistrants = new list<CongrComm_EventUtilities.registrantWrapper>();

        this.GuestPageWrapper = new CongrComm_EventUtilities.registrantWrapper();
        this.GuestPageWrapper.TheContact = new Contact();
        this.GuestPageWrapper.Pricing1 = this.theEvent.Individual_Pricing_1__c;
        this.GuestPageWrapper.Pricing2 = this.theEvent.Individual_Pricing_2__c;
        this.GuestPageWrapper.Pricing3 = this.theEvent.Individual_Pricing_3__c;
        this.GuestPageWrapper.GuestPricing1 = this.theEvent.Individual_Guest_Pricing_1__c;
        this.GuestPageWrapper.GuestPricing2 = this.theEvent.Individual_Guest_Pricing_2__c;
        this.GuestPageWrapper.GuestPricing3 = this.theEvent.Individual_Guest_Pricing_3__c;
        this.GuestPageWrapper.isGuest = true;
        this.GuestPageWrapper.Pricing1Name = this.theEvent.Individual_Pricing_1_Name__c;
        this.GuestPageWrapper.Pricing2Name = this.theEvent.Individual_Pricing_2_Name__c;
        this.GuestPageWrapper.Pricing3Name = this.theEvent.Individual_Pricing_3_Name__c;
    }

    @TestVisible private void createQuestionWrappers(){

        if(theEvent == null || theEvent.Questions__r == null || theEvent.Questions__r.size() == 0){
            return;
        }

        for(Question__c q : theEvent.Questions__r) {
            QuestionWrapper qw = new QuestionWrapper(q);
            listOfQuestionWrapper.add(qw);
            System.debug('q='+ qw);
        }
    }

    @TestVisible private Boolean validatePage() {

        if(this.GuestPageWrapper.SelectedTicketType == null || this.GuestPageWrapper.SelectedTicketType == '') {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error,'Select ticket type'));
            this.hasErrors = true;
            return true;
        }

        return false;
    }

    @TestVisible private Assessment__c createAssessment(Id accountId){

        Assessment__c returnAssessment = new Assessment__c();

        returnAssessment.Account__c = accountId;
        returnAssessment.Contact__c = this.GuestPageWrapper.TheContact.Id;
        returnAssessment.Designation__c = this.theEvent.Designation__c;
        returnAssessment.Assessed_Amount__c = this.TotalPrice;
        returnAssessment.Assessment_Date__c = Date.today();
        returnAssessment.Description__c = this.theEvent.Name;
        returnAssessment.From_Website__c = true;
        returnAssessment.Program__c = this.theEvent.Id;
        returnAssessment.RecordTypeId = UtilitiesSObject.getRecordTypeId('Event_Assessment',Assessment__c.SObjectType);
        return returnAssessment;
    }

    @TestVisible private list<CongrComm_EventUtilities.registrantWrapper>  getAdditionalRegistrantResults(){
        System.debug('getAdditionalRegistrantResults');
        System.debug('FirstName: '+ FirstName + ' LastName: ' + LastName);

        list<CongrComm_EventUtilities.registrantWrapper> returnList = new list<CongrComm_EventUtilities.registrantWrapper>();
        if(String.isBlank(FirstName) && String.isBlank(LastName) ){
            return null;
        }

        try{
            String FirstNameToCompare = '\'%' + FirstName + '%\'';
            String LastNameToCompare = '\'%' + LastName + '%\'';
            String soql = 'SELECT ' + CONTACT_SOQL_FIELDS + '  WHERE Account.Directory_Opt_out__c = false AND Account.Is_Current_Member__c = true ';
            String firstNameSoqlCondition = getContactSOQLFirstNameCondition();
            if(String.isNotBlank(firstNameSoqlCondition)){
                soql += ' AND ' + firstNameSoqlCondition;
            }
            String lastNameSoqlCondition = getContactSOQLLastNameCondition();
            if(String.isNotBlank(lastNameSoqlCondition)){
                soql += ' AND ' + lastNameSoqlCondition;
            }

            soql += ' limit ' + ADDITIONAL_SEARCH_COUNT;
            list<Contact> contacts = Database.query(soql);
            for(Contact curCon : contacts){
                CongrComm_EventUtilities.registrantWrapper wrap = CongrComm_EventUtilities.createRegistrantWrapper(curCon,theEvent);
                returnList.add(wrap);
            }

            return returnList;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return null;
        }
    }

    @TestVisible private list<Event_Participant__c> createEventParticipants(list<CongrComm_EventUtilities.registrantWrapper> wrappers,Boolean shouldChargeForEvent){

        list<Event_Participant__c> returnList = new list<Event_Participant__c>();
        for(CongrComm_EventUtilities.registrantWrapper curRegWrap : wrappers){
            Event_Participant__c participant = new Event_Participant__c();
            participant.Contact__c = curRegWrap.TheContact.Id;
            participant.Event__c = theEvent.Id;

            //Added By Kritik
            //participant.Chosen_Ticket_Type__c = curRegWrap.

            if(shouldChargeForEvent){
                if(curRegWrap.SelectedTicketType == 'Pricing 1'){
                    participant.Remaining_Balance__c = curRegWrap.Pricing1;
                    participant.Chosen_Ticket_Type__c = curRegWrap.Pricing1Name;
                    participant.Participant_Event_Fee__c = curRegWrap.Pricing1;
                }
                if(curRegWrap.SelectedTicketType == 'Pricing 2'){
                    participant.Remaining_Balance__c = curRegWrap.Pricing2;
                    participant.Chosen_Ticket_Type__c = curRegWrap.Pricing2Name;
                    participant.Participant_Event_Fee__c = curRegWrap.Pricing1;
                }
                if(curRegWrap.SelectedTicketType == 'Pricing 3'){
                    participant.Remaining_Balance__c = curRegWrap.Pricing3;
                    participant.Chosen_Ticket_Type__c = curRegWrap.Pricing3Name;
                    participant.Participant_Event_Fee__c = curRegWrap.Pricing1;
                }
            }
            else{
                participant.Remaining_Balance__c = 0.00;
            }

            participant.Comments__c = Comments;

            assignQuestionsToParticipant(participant);
            curRegWrap.EventParticipant = participant;
            returnList.add(participant);
        }
        return returnList;
    }

    @TestVisible private void assignQuestionsToParticipant(Event_Participant__c participant){

        Integer fc = 1;
        for(QuestionWrapper qw : listOfQuestionWrapper) {
            if(fc > 10){
                break;
            }
            participant.put(QUESTION_FIELD_PREFIX + fc + '__c',qw.ques.Question__c );
            participant.put(ANSWER_FIELD_PREFIX + fc + '__c',qw.ans );
            fc++;
            System.debug(qw + ' fc-->'+ fc);
        }
    }

    @TestVisible private list<Participant_Assessment_Bridge__c>  createParticipantAssessmentBridges(Id assessmentId,list<Event_Participant__c> participants){

        list<Participant_Assessment_Bridge__c> returnList = new list<Participant_Assessment_Bridge__c>();
        for(Event_Participant__c curEP : participants){
            Participant_Assessment_Bridge__c pab = new Participant_Assessment_Bridge__c();
            pab.Assessment__c = assessmentId;
            pab.Participant__c = curEP.Id;
            returnList.add(pab);
        }
        return returnList;
    }

    @TestVisible private String getContactSOQLFirstNameCondition(){

        if(String.isNotBlank(FirstName)){
            return ' (FirstName like \'%' + FirstName + '%\' OR Nickname__c  like \'%' + FirstName + '%\')' ;
        }
        else{
            return '';
        }
    }

    @TestVisible private String getContactSOQLLastNameCondition(){

        if(String.isNotBlank(LastName)){
            return ' (LastName like \'%' + LastName + '%\' OR Nickname__c like \'%' + LastName + '%\')' ;
        }
        else{
            return '';
        }
    }

    @TestVisible private void insertAllRecords(){

        list<Event_Participant__c> participantsToCreate = new list<Event_Participant__c>();

        Contact existingContact;
        if(String.isNotBlank(GuestPageWrapper.Email)){
            existingContact = checkForExistingContact(GuestPageWrapper.Email);
        }

        if(existingContact != null) {
            system.debug('Found Contact');
            GuestPageWrapper.TheContact = existingContact;
            //this.SelectedGuestRegistrants.add(curWrap);
        }
        else {
            system.debug('Creating new contact');
            GuestPageWrapper.TheContact.FirstName = GuestPageWrapper.FirstName;
            GuestPageWrapper.TheContact.LastName = GuestPageWrapper.LastName;
            GuestPageWrapper.TheContact.Email = GuestPageWrapper.Email;
            //GuestPageWrapper.TheContact.Phone = GuestPageWrapper.Phone;
            GuestPageWrapper.TheContact.Mobile_Phone__c = GuestPageWrapper.Phone;
            GuestPageWrapper.TheContact.AccountId = UtilitiesCustomSetting.GetInstance().getImportantAccountSetting('Wise Temple Guest Account');
            //this.SelectedGuestRegistrants.add(curWrap);
        }


        processGuestParticipants();

        list<Event_Participant__c> guestParticipantsToCreate = createEventParticipants(SelectedGuestRegistrants,true);
        guestParticipantsToCreate.addAll(createEventParticipants(new list<CongrComm_EventUtilities.registrantWrapper>{GuestPageWrapper},true));

        participantsToCreate.addAll(guestParticipantsToCreate);

        system.debug('Particiapnts to Create:');
        system.debug(participantsToCreate);
        this.assessment = createAssessment(GuestPageWrapper.TheContact.AccountId);
        system.debug('Assessment to Insert:');
        system.debug(assessment);

        try{
            if(this.assessment != null){
                System.debug('Assessment to Insert:');
                insert assessment;
            }
            if(participantsToCreate != null){
                system.debug('Participants to create: ' + participantsToCreate);
                insert participantsToCreate;
            }
            list<Participant_Assessment_Bridge__c> bridges = createParticipantAssessmentBridges(this.assessment.Id,participantsToCreate);
            system.debug('Bridges to be created: ' + bridges);
            if(bridges != null && bridges.size() > 0){
                insert bridges;
            }

        } catch(DmlException de){
            system.debug(de.getMessage());
            system.debug(de.getLineNumber());
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'There was a problem adding the new Event Participant.  Please check your submission and try again.  If the problem persists, contact your system administrator.'));
        }
    }

    @TestVisible private Payment_Adjustment__c createEventPayment(Assessment__c assessment){

        Payment_Adjustment__c newPayment = new Payment_Adjustment__c();
        newPayment.Household__c = assessment.Account__c;
        newPayment.Amount__c = this.TotalPrice + this.TotalAdditionalRegistrantFees;
        newPayment.Online_Fee__c = this.TotalAdditionalRegistrantFees;
        newPayment.Type__c = 'Credit Card';
        newPayment.Receipt_Text__c = this.theEvent.Receipt_Text__c;
        newPayment.Receipt_Link__c = this.theEvent.Web_Registration_Form__c;
        newPayment.Payment_Receipt_Name__c = this.theEvent.Name;
        newPayment.From_Website__c = true;
        newPayment.Incomplete_Payment__c = true;

        try{
            insert newPayment;
        }
        catch(DmlException de){
            system.debug(de.getMessage());
            return null;
        }

        list<Scheduled_Payment__c> scheduledPayments = getRelatedSchedulePayments(assessment);
        FundsDisbursementController fundsDisbursementController = new FundsDisbursementController();
        fundsDisbursementController.DisburseFundsToAllocations(this.TotalPrice,scheduledPayments,newPayment,'Payment');

        return newPayment;
    }

    @TestVisible private list<Scheduled_Payment__c> getRelatedSchedulePayments(Assessment__c assessment){

        try{
            list<Scheduled_Payment__c> returnList = [SELECT Id,Remaining_Balance__c,Assessment__c,Assessment__r.Remaining_Balance__c FROM Scheduled_Payment__c WHERE Assessment__c = :assessment.Id];
            return returnList;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return null;
        }
    }

    @TestVisible private Integer getListSize(list<Object> listToCheck){

        if(listToCheck == null || listToCheck.size() == 0){
            return 0;
        }
        else{
            return listToCheck.size();
        }
    }

    @TestVisible private Contact checkForExistingContact(String email){
        try{
            Contact returnContact = [SELECT Id,AccountId FROM Contact WHERE Email = :email LIMIT 1];
            return returnContact;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return null;
        }
    }

    @TestVisible private void processGuestParticipants() {

        try{
            list<Contact> contactsToInsert = new list<contact>();
            if(GuestPageWrapper != null && GuestPageWrapper.SelectedTicketType != null){
                //Added Condition in &&  GuestPageWrapper.TheContact.Id == null :  By Kritik
                if(GuestPageWrapper.TheContact != null && GuestPageWrapper.TheContact.Id == null) {
                    insert GuestPageWrapper.TheContact;
                }
            }
            for(CongrComm_EventUtilities.registrantWrapper curWrap : SelectedGuestRegistrants){
                //Added Condition in &&   curWrap.TheContact.Id == null :  By Kritik
                if(curWrap.TheContact != null && curWrap.TheContact.Id == null ){
                    insert curWrap.TheContact;
                }
            }
        }

//        try{
//            insert contactsToInsert;
//            return contactsToInsert;
//        }
        catch(DmlException de){
            system.debug(de.getMessage());
        }

    }



    /// --------------------------------------- Sub-Classes ----------------------------------- \\\\\

    public class QuestionWrapper {

        public Question__c ques {get;set;}
        public String ans {get;set;}
        public List<String> pickListValues {get;set;}

        public QuestionWrapper(Question__c inQues) {
            ques = new Question__c();
            ques = inQues;

            System.debug('Picklist_Answers__c='+ inQues.RecordType.Name);

            if(inQues.RecordType.Name == 'Picklist') {

                pickListValues = new List<String>();
                if(inQues.Picklist_Answers__c!= null && inQues.Picklist_Answers__c != '')
                    pickListValues = inQues.Picklist_Answers__c.split(';');
            }
        }

    }

}