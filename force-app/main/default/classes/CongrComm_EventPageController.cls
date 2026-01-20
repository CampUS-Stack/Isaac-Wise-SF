public without sharing class CongrComm_EventPageController {

    public static final String CONTACT_SOQL_FIELDS = 'Id, Name, FirstName, LastName FROM Contact';

    public static final String QUESTION_FIELD_PREFIX = 'Question_';
    public static final String ANSWER_FIELD_PREFIX = 'Answer_';

    public Boolean DisplayAdditionalFinalize {get; set;}
    public Boolean MemberSearchRan {get; set;}
    public Integer ADDITIONAL_SEARCH_COUNT {get; set;}

    Public Event__c theEvent {get; set;}
    public Contact CurrentLoggedInContact {get; set;}
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
    public String selectedPaymentMethod {get; set;}

    //// Guest Page Specific variables
    public CongrComm_EventUtilities.registrantWrapper GuestPageWrapper {get; set;}
    public list<CongrComm_EventUtilities.registrantWrapper> GuestPageRegistrants {get; set;}
    //// End Guest Page Specific variables

    //// Member Page Specific variables
    public list<CongrComm_EventUtilities.registrantWrapper> HouseholdFamilyMembers {get; set;}
    public list<CongrComm_EventUtilities.registrantWrapper> SelectedFamilyMembers {get; set;}

    public list<CongrComm_EventUtilities.registrantWrapper> TheAdditionalRegistrants {get; set;}
    public list<CongrComm_EventUtilities.registrantWrapper> SelectedAdditionalRegistrants {get; set;}

    public list<CongrComm_EventUtilities.registrantWrapper> GuestRegistrants {get; set;}
    public list<CongrComm_EventUtilities.registrantWrapper> SelectedGuestRegistrants {get; set;}
    //// End Member Page Specific variables

    //To Check duplicate
    public Map<Id,Contact> mapOfContact {get;set;}

    @TestVisible private Assessment__c assessment {get; set;}

    //Added by Kritik : Task CORS-T77
    public List<QuestionWrapper> listOfQuestionWrapper {get;set;}

    public Integer NumberOfAllRegistrants{
        get{
            Integer returnCount = 0;

            if(SelectedFamilyMembers != null){
                returnCount += SelectedFamilyMembers.size();
            }
            if(SelectedAdditionalRegistrants != null){
                returnCount += SelectedAdditionalRegistrants.size();
            }
            if(SelectedGuestRegistrants != null){
                returnCount += SelectedGuestRegistrants.size();
            }
            return returnCount;
        }
    }

    public list<SelectOption> NumberOfFamilyMembers{
        get{
            list<SelectOption> returnList = new list<SelectOption>();
            returnList.add(new SelectOption('-- NONE --',''));

            if(HouseholdFamilyMembers == null){
                return returnList;
            }

            for(CongrComm_EventUtilities.registrantWrapper curWrap : HouseholdFamilyMembers){
                SelectOption so = new SelectOption(curWrap.TheContact.Id,curWrap.TheContact.Name);
                returnList.add(so);
            }
            return returnList;
        }
    }

    public Integer NumberOfMemberRegistrants{
        get{
            return getListSize(TheAdditionalRegistrants);
        }
    }

    public Integer NumberOfSelectedFamily{
        get{
            return getListSize(SelectedFamilyMembers);
        }
    }

    public Integer NumberOfSelectedAdditionalRegistrants{
        get{
            return getListSize(SelectedAdditionalRegistrants);
        }
    }

    public Integer NumberOfGuestRegistrants{
        get{
            return getListSize(GuestRegistrants);
        }
    }

    public Integer NumberOfSelectedGuestRegistrants{
        get{
            return getListSize(SelectedGuestRegistrants);
        }
    }
    public Integer NumberOfGuestPageRegistrants{
        get{
            return getListSize(GuestPageRegistrants);
        }
    }

    public Decimal TotalRegistrantPrice  {
        get{

            Double returnValue = 0.00;

            if(!theEvent.Paid_Event__c){
                return returnValue;
            }

            if(SelectedGuestRegistrants != null && SelectedGuestRegistrants.size() != 0){
                for(CongrComm_EventUtilities.registrantWrapper curWrap : SelectedGuestRegistrants){
                    if(curWrap.Price != null && curWrap.Price != 0.00){
                        returnValue += curWrap.Price;
                    }
                }
            }

            //Added by Kritik - To include Additional Registrants
            if(SelectedAdditionalRegistrants != null && SelectedAdditionalRegistrants.size() != 0){
                for(CongrComm_EventUtilities.registrantWrapper curWrap : SelectedAdditionalRegistrants){
                    if(curWrap.Price != null && curWrap.Price != 0.00){
                        returnValue += curWrap.Price;
                    }
                }
            }

            return returnValue;
        }
    }

    public Decimal TotalHouseholdPrice  {
        get{

            Double returnValue = 0.00;

            if(!theEvent.Paid_Event__c){
                return returnValue;
            }

            if(SelectedFamilyMembers != null && SelectedFamilyMembers.size() != 0){
                for(CongrComm_EventUtilities.registrantWrapper curWrap : SelectedFamilyMembers){
                    if(curWrap.Price != null || curWrap.Price != 0.00){
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

            returnValue = TotalRegistrantPrice + TotalHouseholdPrice;
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
            if(TotalRegistrantPrice == null){
                return returnValue;
            }

            if(!theEvent.Paid_Event__c){
                return returnValue;
            }

            returnValue = (TotalRegistrantPrice * .025).setScale(2);

            return returnValue;
        }
    }

    public list<SelectOption> PricingOptions{
        get{
            list<SelectOption> returnList = new list<SelectOption>();
            returnList.add(new SelectOption('','Not Attending'));

            if(this.theEvent == null){
                return returnList;
            }

            if(String.isNotBlank(theEvent.Individual_Pricing_1_Name__c)){
                SelectOption so = new SelectOption('Pricing 1',theEvent.Individual_Pricing_1_Name__c + ' - $' + theEvent.Individual_Pricing_1__c);
                returnList.add(so);
            }
            if(String.isNotBlank(theEvent.Individual_Pricing_2_Name__c)){
                SelectOption so = new SelectOption('Pricing 2',theEvent.Individual_Pricing_2_Name__c + ' - $' + theEvent.Individual_Pricing_2__c);
                returnList.add(so);
            }
            if(String.isNotBlank(theEvent.Individual_Pricing_3_Name__c)){
                SelectOption so = new SelectOption('Pricing 3',theEvent.Individual_Pricing_3_Name__c + ' - $' + theEvent.Individual_Pricing_3__c);
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
    
    public List<SelectOption> getPaymentOptions() {
        
        List<selectOption> options = new List<selectOption>();
        
        options.add(new selectOption('', '-- None --'));
        options.add(new selectOption('CC', 'Credit Card'));
        options.add(new selectOption('ACH', 'ACH'));
//        options.add(new selectOption('Bill My Account', 'Bill My Account (Pay Later)'));
        
        return options;
    }

    /// --------------------------------------- Private Helper Methods ----------------------------------- \\\\\

    /**
     * @author Chris Gibson
     * @date 10.20.2018
     *
     * @description 0 param consturctor for "CongrComm_EventPage' VF page
     */
    Public CongrComm_EventPageController(){

//        initializeVariables();
//        String eventId = ApexPages.currentPage().getParameters().get('id');
//
//        // Updated by Kritik
//        //theEvent = CongrComm_EventUtilities.GetEventwithQuestions(eventId);
//        theEvent = CongrComm_EventUtilities.GetPortalEventwithQuestions(eventId);
//
//        this.CurrentLoggedInContact = UtilitiesUsers.GetContactForCommunityUser(UserInfo.getUserId());
//        this.EventPrice = theEvent.Event_Price__c;
//        this.HouseholdFamilyMembers = CongrComm_EventUtilities.GetRelatedContacts(CurrentLoggedInContact.AccountId,theEvent);
//
//        createQuestionWrappers();
//
//        disableRegBtn = true;
//        MemberSearchRan = false;


        //Commented By Kritik - Add an entry into the table for the currently logged in contact : No longer needed

        //Added by Kritik - Task : CORS-T98 -- Add an entry into the table for the currently logged in contact
        /*
        CongrComm_EventUtilities.registrantWrapper currentLoggedInConWrapper = CongrComm_EventUtilities.createRegistrantWrapper(CurrentLoggedInContact,theEvent);
        for(CongrComm_EventUtilities.registrantWrapper curFamMember : HouseholdFamilyMembers){
            if(curFamMember.TheContact.Id == CurrentLoggedInContact.Id){
                curFamMember.SelectedTicketType = 'Pricing 1';
                curFamMember.TicketType = theEvent.Individual_Pricing_1_Name__c;
                SelectedFamilyMembers.add(curFamMember);
            }
        } 
        */
    }
    
    Public PageReference onLoad(){
        initializeVariables();
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
    
        this.CurrentLoggedInContact = UtilitiesUsers.GetContactForCommunityUser(UserInfo.getUserId());
        this.EventPrice = theEvent.Event_Price__c;
        this.HouseholdFamilyMembers = CongrComm_EventUtilities.GetRelatedContacts(CurrentLoggedInContact.AccountId,theEvent);
        
        createQuestionWrappers();
    
        disableRegBtn = true;
        MemberSearchRan = false;
        return null;
    }

    Public PageReference save(){

        System.debug('save function init');
        if(ValidatePage()){
            hasErrors = true;
            system.debug('Validation Failed');
            return null;
        }
        hasErrors = false;

        if(insertAllRecords()) {
            Payment_Adjustment__c eventPayment = createEventPayment(this.assessment);
            Payment_Adjustment__c reQueriedPayment = [SELEcT Id,Name, (SELECT Id FROM Scheduled_Payment_Bridges__r) FROM Payment_Adjustment__c WHERE Id = :eventPayment.Id];
            UtilitiesFinancials.UpdatePaymentBridgesWebsiteValues(reQueriedPayment.Scheduled_Payment_Bridges__r);
            PageReference pr = Page.CongrComm_ManagePaymentVaults;
            pr.getParameters().put('paId', reQueriedPayment.Id);
            pr.getParameters().put('method', this.selectedPaymentMethod);
            pr.setRedirect(true);
            return pr;
        } else {
            hasErrors = true;
            System.debug('Unable to insert participants');
            return null;
        }

    }
    Public PageReference saveNonPaidEvent(){

        System.debug('save function init');
        if(ValidatePage()){
            hasErrors = true;
            system.debug('Validation Failed');
            return null;
        }
        hasErrors = false;


        if(insertAllRecordsForFreeEvent()) {
            PageReference pr = Page.CongrComm_ThanksFreeEvent;
            pr.getParameters().put('pId', theEvent.Id);
            pr.setRedirect(true);
            return pr;
        } else {
            hasErrors = true;
            system.debug('Unable to insert participant');
            return null;
        }




    }

    public PageReference RemoveSelectedParticipant(){

        //System.debug('Test KRK :: ' + RegistrantNameToRemove);
        list<CongrComm_EventUtilities.registrantWrapper> familyToReAdd = new list<CongrComm_EventUtilities.registrantWrapper>();
        list<CongrComm_EventUtilities.registrantWrapper> guestsToReAdd = new list<CongrComm_EventUtilities.registrantWrapper>();
        list<CongrComm_EventUtilities.registrantWrapper> additionalsToReAdd = new list<CongrComm_EventUtilities.registrantWrapper>();
        System.debug('SelectedGuestRegistrants : ' + SelectedGuestRegistrants.size());
        for(CongrComm_EventUtilities.registrantWrapper curWrap : SelectedGuestRegistrants){
            System.debug('loop: ' +curWrap.TheContact + '::: ' + RegistrantNameToRemove);
            if((curWrap.TheContact.FirstName + ' ' +curWrap.TheContact.LastName) != RegistrantNameToRemove ){
                guestsToReAdd.add(curWrap);
            } 
        }
        for(CongrComm_EventUtilities.registrantWrapper curWrap : SelectedAdditionalRegistrants){
            if(curWrap.TheContact.Name != RegistrantNameToRemove){
                additionalsToReAdd.add(curWrap);
            }
        }
        for(CongrComm_EventUtilities.registrantWrapper curWrap : SelectedFamilyMembers){
            if(curWrap.TheContact.Name != RegistrantNameToRemove){
                familyToReAdd.add(curWrap);
            }
        }
        SelectedAdditionalRegistrants.clear();
        SelectedGuestRegistrants.clear();
        SelectedFamilyMembers.clear();

        for(CongrComm_EventUtilities.registrantWrapper  curWrap : guestsToReAdd){
            //SelectedAdditionalRegistrants.add(curWrap);
            SelectedGuestRegistrants.add(curWrap);
        }
        for(CongrComm_EventUtilities.registrantWrapper  curWrap : additionalsToReAdd){
            //SelectedGuestRegistrants.add(curWrap);
            SelectedAdditionalRegistrants.add(curWrap);
        }
        for(CongrComm_EventUtilities.registrantWrapper  curWrap : familyToReAdd){
            SelectedFamilyMembers.add(curWrap);
        }

        return null;
    }

    public PageReference SearchForRegistrants() {
        ADDITIONAL_SEARCH_COUNT = 10;
        MemberSearchRan = true;
        DisplayAdditionalFinalize = false;
        System.debug('SearchForRegistrants');
        TheAdditionalRegistrants = getAdditionalRegistrantResults();
        return null;
    }

    public PageReference SelectFamilyMembers(){
        this.SelectedFamilyMembers.clear();
        for(CongrComm_EventUtilities.registrantWrapper curWrap : HouseholdFamilyMembers){
            if(String.isNotBlank(curWrap.SelectedTicketType)){
//                curWrap.Pricing1 = 0.00;
//                curWrap.Pricing2 = 0.00;
//                curWrap.PRicing3 = 0.00;
                this.SelectedFamilyMembers.add(curWrap);
            }
        }

        return null;
    }

    public PageReference AddGuestRegistrant(){

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
            if(String.isNotBlank(curWrap.Email)){
                existingContact = checkForExistingContact(this.GuestEmail);
            }

            if(existingContact != null){
                system.debug('Found Contact');
                curWrap.TheContact = existingContact;
                this.SelectedGuestRegistrants.add(curWrap);
            }
            else {
                system.debug('Creating new contact');
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

    public PageReference AddSelectedAdditionalRegistrants() {

        //Added by Kritik
        DisplayAdditionalFinalize = false;
        FirstName = '';
        LastName = '';

        /*
        this.SelectedAdditionalRegistrants.clear();
        for(CongrComm_EventUtilities.registrantWrapper curWrap : TheAdditionalRegistrants){
            if(String.isNotBlank(curWrap.SelectedTicketType)){
//                curWrap.Pricing1 = 0.00;
//                curWrap.Pricing2 = 0.00;
//                curWrap.PRicing3 = 0.00;
                this.SelectedAdditionalRegistrants.add(curWrap);
            }
        }
        */

        return null;
    }

    Public PageReference cancel(){
        PageReference pageRef = new PageReference('/apex/CongrComm_MyEvents');
        pageRef.setRedirect(false);
        return pageRef;        

    }

    public PageReference LoadMoreAdditionalRegistrantSearchResults(){
        ADDITIONAL_SEARCH_COUNT = ADDITIONAL_SEARCH_COUNT + 5;
        system.debug(ADDITIONAL_SEARCH_COUNT);
        TheAdditionalRegistrants = getAdditionalRegistrantResults();
        return null;
    }

    public PageReference GoToFinalizeAdditionalRegistrant(){
//        SelectedAdditionalRegistrants.clear();
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

        this.SelectedFamilyMembers = new list<CongrComm_EventUtilities.registrantWrapper>();
        this.HouseholdFamilyMembers = new list<CongrComm_EventUtilities.registrantWrapper>();
        this.TheAdditionalRegistrants = new list<CongrComm_EventUtilities.registrantWrapper>();
        this.SelectedAdditionalRegistrants = new list<CongrComm_EventUtilities.registrantWrapper>();
        this.listOfQuestionWrapper = new List<QuestionWrapper>();
        this.GuestRegistrants = new list<CongrComm_EventUtilities.registrantWrapper>();
        this.SelectedGuestRegistrants = new list<CongrComm_EventUtilities.registrantWrapper>();

        mapOfContact = new Map<Id,Contact>();

        this.GuestPageWrapper = new CongrComm_EventUtilities.registrantWrapper();
        this.GuestPageWrapper.Pricing1 = this.theEvent.Individual_Pricing_1__c;
        this.GuestPageWrapper.Pricing2 =+ this.theEvent.Individual_Pricing_2__c;
        this.GuestPageWrapper.Pricing3 = this.theEvent.Individual_Pricing_3__c;
        this.GuestPageWrapper.Pricing1Name = this.theEvent.Individual_Pricing_1_Name__c;
        this.GuestPageWrapper.Pricing2Name = this.theEvent.Individual_Pricing_2_Name__c;
        this.GuestPageWrapper.Pricing3Name = this.theEvent.Individual_Pricing_3_Name__c;
    }

    @TestVisible private void createQuestionWrappers(){

        for(Question__c q : theEvent.Questions__r) {
            QuestionWrapper qw = new QuestionWrapper(q);
            listOfQuestionWrapper.add(qw);
            System.debug('q='+ qw);
        }
    }

    @TestVisible private Boolean validatePage(){

        if(SelectedFamilyMembers.size() == 0 && SelectedAdditionalRegistrants.size() == 0 && SelectedGuestRegistrants.size() == 0){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'You must add at least 1 registrant to make a payment.'));
            return true;
        }
    
        if((selectedPaymentMethod == null || String.isBlank(selectedPaymentMethod)) && theEvent.Paid_Event__c){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please select a payment method'));
            return true;
        }
        
        return false;
    }

    @TestVisible private Assessment__c createAssessment(){

        Assessment__c returnAssessment = new Assessment__c();
        returnAssessment.Account__c = this.CurrentLoggedInContact.AccountId;
        returnAssessment.Contact__c = this.CurrentLoggedInContact.Id;
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

    @TestVisible private Boolean setSelectedAdditionalRegistrants(){
        Boolean ticketSelected = false;
        //System.debug('Size : TheAdditionalRegistrants 1' + SelectedAdditionalRegistrants.size());
        for(CongrComm_EventUtilities.registrantWrapper curWrap : TheAdditionalRegistrants){
            //if(String.isNotBlank(curWrap.SelectedTicketType) && !SelectedAdditionalRegistrants.contains(curWrap)) {
            if(String.isNotBlank(curWrap.SelectedTicketType) && !mapOfContact.containsKey(curWrap.TheContact.Id)) {
                SelectedAdditionalRegistrants.add(curWrap);
                mapOfContact.put(curWrap.TheContact.Id,curWrap.TheContact);
                ticketSelected = true;
            }
        }

        return ticketSelected;

        // System.debug('Size : TheAdditionalRegistrants 2' + SelectedAdditionalRegistrants.size());

    }

    @TestVisible private list<Event_Participant__c> createEventParticipants(list<CongrComm_EventUtilities.registrantWrapper> wrappers,Boolean shouldChargeForEvent){

        list<Event_Participant__c> returnList = new list<Event_Participant__c>();
        for(CongrComm_EventUtilities.registrantWrapper curRegWrap : wrappers){
            if(curRegWrap.TheContact == null){
                continue;
            }
            Event_Participant__c participant = new Event_Participant__c();
            participant.Contact__c = curRegWrap.TheContact.Id;
            participant.Event__c = theEvent.Id;
            participant.Comments__c = Comments;

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

    @TestVisible private Boolean insertAllRecords() {

        list<Event_Participant__c> participantsToCreate = new list<Event_Participant__c>();

        processGuestParticipants();

        list<Event_Participant__c> householdParticipantsToCreate = createEventParticipants(SelectedFamilyMembers,true);
        list<Event_Participant__c> additionalParticipantsToCreate = createEventParticipants(SelectedAdditionalRegistrants,true);
        list<Event_Participant__c> guestParticipantsToCreate = createEventParticipants(SelectedGuestRegistrants,true);

        participantsToCreate.addAll(householdParticipantsToCreate);
        participantsToCreate.addAll(additionalParticipantsToCreate);
        participantsToCreate.addAll(guestParticipantsToCreate);

        system.debug('Particiapnts to Create:');
        system.debug(participantsToCreate);
        this.assessment = createAssessment();
        system.debug('Assessment to Insert:');
        system.debug(assessment);

        try{
            if(this.assessment != null){
                insert assessment;
            }
            if(participantsToCreate != null){
                insert participantsToCreate;
            }
            list<Participant_Assessment_Bridge__c> bridges = createParticipantAssessmentBridges(this.assessment.Id,participantsToCreate);
            if(bridges != null && bridges.size() > 0){
                insert bridges;
            }
            return true;

        } catch (DmlException de) {
            system.debug(de.getMessage());
            system.debug(de.getLineNumber());
            UtilitiesErrors.SendErrorEmailASYNC('Unable to add participant \n Event : ' + theEvent.Id + '\n User ID: '+  CurrentLoggedInContact.id+ '\n ' +de.getLineNumber() + ' : ' + de.getMessage());
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'There was a problem adding the new Event Participant.  Please check your submission and try again.  If the problem persists, contact your system administrator.'));
            return false;
        } catch (Exception e) {
            system.debug(e.getMessage());
            system.debug(e.getLineNumber());
            UtilitiesErrors.SendErrorEmailASYNC('Unable to add participant \n Event : ' + theEvent.Id + '\n User ID: '+  CurrentLoggedInContact.id+ '\n ' +e.getLineNumber() + ' : ' + e.getMessage());
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'There was a problem adding the new Event Participant.  Please check your submission and try again.  If the problem persists, contact your system administrator.'));
            return false;
        }
    }

    @TestVisible private Boolean insertAllRecordsForFreeEvent() {

        list<Event_Participant__c> participantsToCreate = new list<Event_Participant__c>();

        processGuestParticipants();

        list<Event_Participant__c> householdParticipantsToCreate = createEventParticipants(SelectedFamilyMembers,false);
        list<Event_Participant__c> additionalParticipantsToCreate = createEventParticipants(SelectedAdditionalRegistrants,false);
        list<Event_Participant__c> guestParticipantsToCreate = createEventParticipants(SelectedGuestRegistrants,false);

        participantsToCreate.addAll(householdParticipantsToCreate);
        participantsToCreate.addAll(additionalParticipantsToCreate);
        participantsToCreate.addAll(guestParticipantsToCreate);

        system.debug('Particiapnts to Create:');
        system.debug(participantsToCreate);

        try {
            if (participantsToCreate != null && participantsToCreate.size() > 0) {
                insert participantsToCreate;
                return true;
            }
            else{
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'No Participant selected'));
                return false;
            }
        } catch (DmlException de) {
            system.debug(de.getMessage());
            system.debug(de.getLineNumber());
            UtilitiesErrors.SendErrorEmailASYNC('Unable to add participant \n Event : ' + theEvent.Id + '\n User ID: '+  CurrentLoggedInContact.id+ '\n ' +de.getLineNumber() + ' : ' + de.getMessage());
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'There was a problem adding the new Event Participant.  Please check your submission and try again.  If the problem persists, contact your system administrator.'));
            return false;
        } catch (Exception e) {
            system.debug(e.getMessage());
            system.debug(e.getLineNumber());
            UtilitiesErrors.SendErrorEmailASYNC('Unable to add participant \n Event : ' + theEvent.Id + '\n User ID: '+  CurrentLoggedInContact.id+ '\n ' +e.getLineNumber() + ' : ' + e.getMessage());
            return false;
        }
    }

    @TestVisible private Payment_Adjustment__c createEventPayment(Assessment__c assessment){

        Payment_Adjustment__c newPayment = new Payment_Adjustment__c();
        newPayment.Household__c = this.CurrentLoggedInContact.AccountId;
        newPayment.Amount__c = this.TotalPrice;
//        newPayment.Online_Fee__c = this.TotalAdditionalRegistrantFees;
        newPayment.Type__c = 'Credit Card';
        newPayment.From_Website__c = true;
        newPayment.Incomplete_Payment__c = true;
        newPayment.Payment_Receipt_Name__c = this.theEvent.Name;
        newPayment.Receipt_Text__c = this.theEvent.Receipt_Text__c;
        newPayment.Receipt_Link__c = this.theEvent.Web_Registration_Form__c;
        try{
            insert newPayment;
        }
        catch(DmlException de){
            system.debug(de.getMessage());
            return null;
        }

        system.debug('Assessment Account ID: ' + assessment.Account__c);
        list<Scheduled_Payment__c> scheduledPayments = getRelatedSchedulePayments(assessment);
        FundsDisbursementController fundsDisbursementController = new FundsDisbursementController();
        fundsDisbursementController.DisburseFundsToAllocations(assessment.Assessed_Amount__c.setScale(2),scheduledPayments,newPayment,'Payment');

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
            Contact returnContact = [SELECT Id FROM Contact WHERE Email = :email];
            return returnContact;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return null;
        }
    }

    @TestVisible private void processGuestParticipants(){

        list<Contact> contactsToInsert = new list<contact>();
        System.debug('processGuestParticipants' + SelectedGuestRegistrants.size() );
        for(CongrComm_EventUtilities.registrantWrapper curWrap : SelectedGuestRegistrants){
            if(curWrap.TheContact != null){
                contactsToInsert.add(curWrap.TheContact);
            }
        }

        try{
            insert contactsToInsert;
        }
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