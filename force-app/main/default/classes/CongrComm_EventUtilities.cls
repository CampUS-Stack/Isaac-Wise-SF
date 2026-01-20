/**
 * Created by Chris Home Desktop on 10/14/2018.
 */

public without sharing class CongrComm_EventUtilities {

    public static final String EVENT_SOQL_FIELDS = 'Id, Paid_Event__c, Web_Registration_Form__c, Name, Question_1__c, Question_2__c, Question_3__c, Question_4__c, Question_5__c, Event_Price__c, Event_Date_Start__c,'+
            'Individual_Pricing_1__c,Individual_Pricing_1_Name__c,Individual_Pricing_2__c,Individual_Pricing_2_Name__c,Designation__c, Max_Price__c,'+
            'Individual_Pricing_3__c,Individual_Pricing_3_Name__c,Pricing_Type__c,Household_Pricing__c,Description__c,Receipt_Text__c, Display_on_portal__c,Individual_Guest_Pricing_1__c,Individual_Guest_Pricing_2__c,Individual_Guest_Pricing_3__c';

    public static final String QUESTION_SOQL_FIELDS = 'Id, Name, Event__c, Allow_Multiple_Choice__c, Question__c, Picklist_Answers__c, Order__c, Required__c, RecordType.Name ';


    public static final String EVENT_SOQL = 'SELECT ' + EVENT_SOQL_FIELDS + ' FROM Event__c';


    public static Event__c GetEvent(String eventId){
        try{
            Event__c returnEvent = Database.query(EVENT_SOQL + ' WHERE Id = :eventId limit 1');
            return returnEvent;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return null;
        }
    }

    public static Event__c GetEventwithQuestions(String eventId){
        try{
            //System.debug('SELECT '+ EVENT_SOQL_FIELDS + ', (SELECT '+QUESTION_SOQL_FIELDS +' FROM Questions__r ) FROM Event__c WHERE Id = :eventId limit 1');
            Event__c returnEvent = Database.query('SELECT '+ EVENT_SOQL_FIELDS + ', (SELECT '+QUESTION_SOQL_FIELDS +' FROM Questions__r order by Order__c NULLS LAST, Name ) FROM Event__c WHERE Id = :eventId limit 1');
            return returnEvent;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return null;
        }
    }

    //To get Event with Display_on_portal__c = true
    public static Event__c GetPortalEventwithQuestions(String eventId){
        try{
            Event__c returnEvent = Database.query('SELECT '+ EVENT_SOQL_FIELDS + ', (SELECT '+QUESTION_SOQL_FIELDS +' FROM Questions__r order by Order__c NULLS LAST, Name ) FROM Event__c WHERE Id = :eventId limit 1');
            return returnEvent;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return null;
        }
    }

    public static list<Event__c> GetEvents(String eventType){
        try{
            list<Event__c> returnEvents = Database.query(EVENT_SOQL + ' WHERE Event_Type__c = :eventType');
            return returnEvents;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return null;
        }
    }

    public static list<Event__c> GetFutureEvents(String eventType){
        try{
            Date startDate = Date.today();
            list<Event__c> returnEvents = Database.query(EVENT_SOQL + ' WHERE Event_Type__c = :eventType AND Event_Date_Start__c > :startDate');
            return returnEvents;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return null;
        }
    }

    public static list<Event__c> GetFutureEventsForMultipleRegistration(String eventType){
        try{
            Date startDate = Date.today();
            system.debug(startDate);
            list<Event__c> returnEvents = Database.query(EVENT_SOQL + ' WHERE Event_Type__c = :eventType AND Event_Date_End__c >= :startDate AND Include_in_multi_signup__c = true Order By Event_Date_Start__c ASC');
            return returnEvents;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return null;
        }
    }

    public static list<registrantWrapper> GetRelatedContacts(Id accountId,Event__c theEvent){
        try{
            list<registrantWrapper> returnList = new list<registrantWrapper>();
            list<Contact> contacts = [SELECT Id,Name,AccountId,FirstName,LastName FROM Contact WHERE AccountId = :accountId];
            for(Contact theCon : contacts){
                registrantWrapper wrap = CreateRegistrantWrapper(theCon,theEvent);
                returnList.add(wrap);
            }
            return returnList;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return null;
        }
    }


    public static registrantWrapper CreateRegistrantWrapper(Contact theContact,Event__c theEvent){

        registrantWrapper wrap = new registrantWrapper();
        wrap.TheContact = theContact;
        wrap.Pricing1 = theEvent.Individual_Pricing_1__c;
        wrap.Pricing2 = theEvent.Individual_Pricing_2__c;
        wrap.Pricing3 = theEvent.Individual_Pricing_3__c;
        wrap.Pricing1Name = theEvent.Individual_Pricing_1_Name__c;
        wrap.Pricing2Name = theEvent.Individual_Pricing_2_Name__c;
        wrap.Pricing3Name = theEvent.Individual_Pricing_3_Name__c;
        wrap.HouseholdPricing = theEvent.Household_Pricing__c;
        wrap.EventPricingType = theEvent.Pricing_Type__c;
        wrap.GuestPricing1 = theEvent.Individual_Guest_Pricing_1__c;
        wrap.GuestPricing2 = theEvent.Individual_Guest_Pricing_2__c;
        wrap.GuestPricing3 = theEvent.Individual_Guest_Pricing_3__c;
        return wrap;
    }

    Public class registrantWrapper{

        Public Contact TheContact {get; set;}
        Public String ContactId {get; set;}

        Public String FirstName {get; set;}
        Public String LastName {get; set;}
        Public String Email {get; set;}
        Public String Phone {get; set;}
        Public Integer TheOrder {get; set;}

        public String SelectedTicketType {get; set;}
        public String EventPricingType {get; set;}

        public Decimal Pricing1 {get; set;}
        public Decimal Pricing2 {get; set;}
        public Decimal Pricing3 {get; set;}
        public Decimal GuestPricing1 {get; set;}
        public Decimal GuestPricing2 {get; set;}
        public Decimal GuestPricing3 {get; set;}
        public Boolean isGuest {get; set;}
        public String Pricing1Name {get; set;}
        public String Pricing2Name {get; set;}
        public String Pricing3Name {get; set;}

        public Decimal HouseholdPricing {get; set;}

        Public String TicketType {
            get{

                if(String.isBlank(SelectedTicketType)){
                    return 'Blank';
                }
                if(SelectedTicketType.equalsIgnoreCase('Pricing 1')){
                    return Pricing1Name;
                }
                else if(SelectedTicketType == 'Pricing 2'){
                    return Pricing2Name;
                }
                else if(SelectedTicketType == 'Pricing 3'){
                    return Pricing3Name;
                }

                return 'none';
            }
            set;
        }
        Public Decimal Price {
            get{
                if(String.isBlank(SelectedTicketType)){
                    return 0.00;
                }

                if(SelectedTicketType == 'Pricing 1'){
                    System.debug('IsGuest : '+IsGuest);
                    if(IsGuest == true){
                        System.debug('GuestPricing1 : '+GuestPricing1);
                        return GuestPricing1;
                    }else {
                        System.debug('Pricing1 : '+Pricing1);
                        return Pricing1;
                    }
                }
                else if(SelectedTicketType == 'Pricing 2'){
                    if(IsGuest == true){
                        System.debug('GuestPricing2 : '+GuestPricing2);
                        return GuestPricing2;
                    }else {
                        System.debug('Pricing1 : '+Pricing2);
                        return Pricing2;
                    }
                }
                else if(SelectedTicketType == 'Pricing 3'){
                    if(IsGuest == true){
                        System.debug('GuestPricing3 : '+GuestPricing3);
                        return GuestPricing3;
                    }else {
                        System.debug('Pricing1 : '+Pricing3);
                        return Pricing3;
                    }
                }


                return 0.00;
            }
            set;
        }

        public Event_Participant__c EventParticipant {get; set;}


        public Boolean Selected {get; set;}

        Public registrantWrapper(){
            this.Selected = false;
            this.IsGuest = false;
            this.SelectedTicketType = '';
        }
    }
}