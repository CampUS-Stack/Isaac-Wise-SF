/**
 * Created by Chris Home Desktop on 8/14/2017.
 */


public with sharing class UtilitiesWrappers {

    public class ContactWrapper {

        public Contact theContact {get; set;}
        public String FirstName {get; set;}
        public String LastName {get; set;}
        public String Email {get; set;}
        public String Street {get; set;}
        public String City {get; set;}
        public String State {get; set;}
        public String Zip {get; set;}
        public Event_Participant__c participant {get; set;}
        public Boolean isSelected {get; set;}

        public ContactWrapper(){}
    }

    public static list<ContactWrapper> createContactWrappers(list<Contact> contactsToCreateFrom){
        if(contactsToCreateFrom == null){
            return null;
        }

        list<ContactWrapper> returnList = new list<ContactWrapper>();
        for(Contact c : contactsToCreateFrom){
            ContactWrapper wrapper = new ContactWrapper();
            wrapper.theContact = c;
            wrapper.isSelected = false;
            returnList.add(wrapper);
        }

        return returnList;
    }

    public static list<ContactWrapper> createContactWrappers(list<Contact> contactsToCreateFrom,map<Id,Event_Participant__c> participantsByContactId){
        if(contactsToCreateFrom == null){
            return null;
        }
        system.debug(participantsByContactId);

        list<ContactWrapper> returnList = new list<ContactWrapper>();
        for(Contact c : contactsToCreateFrom){
            ContactWrapper wrapper = new ContactWrapper();
            wrapper.theContact = c;
            wrapper.isSelected = false;
            if(participantsByContactId.containsKey(c.Id)){
                wrapper.participant = participantsByContactId.get(c.Id);
            }
            returnList.add(wrapper);
        }

        return returnList;
    }

    public class StudentWrapper{

        public Contact student {get; set;}
        public Boolean isSelected {get; set;}

        public StudentWrapper(){}
    }

    public static list<StudentWrapper> createStudentWrappers(list<Contact> contactsToCreateFrom){
        if(contactsToCreateFrom == null){
            return null;
        }

        list<StudentWrapper> returnList = new list<StudentWrapper>();
        for(Contact c : contactsToCreateFrom){
            StudentWrapper wrapper = new StudentWrapper();
            wrapper.student = c;
            returnList.add(wrapper);
        }

        return returnList;
    }

    public class RS_ClassWrapper{

        public Class__c TheClass {get; set;}
        public Boolean IsSelected {get; set;}

        public RS_ClassWrapper(){}
    }

    public static list<RS_ClassWrapper> CreateClassWrappers(list<Class__c> classesToCreateFor){
        if(classesToCreateFor == null){
            return null;
        }

        list<RS_ClassWrapper> returnList = new list<RS_ClassWrapper>();
        for(Class__c c : classesToCreateFor){
            RS_ClassWrapper wrapper = new RS_ClassWrapper();
            wrapper.TheClass = c;
            returnList.add(wrapper);
        }

        return returnList;
    }

    public class RS_EventParticipantWrapper{

        public Event_Participant__c EventParticipant{get; set;}
        public Boolean IsSelected {get; set;}

        public RS_EventParticipantWrapper(){}

    }

    public static list<RS_EventParticipantWrapper> CreateClassWrappers(list<Event_Participant__c> eventParticipantsToCreateWrapper){
        if(eventParticipantsToCreateWrapper == null){
            return null;
        }

        list<RS_EventParticipantWrapper> returnList = new list<RS_EventParticipantWrapper>();
        for(Event_Participant__c ep : eventParticipantsToCreateWrapper){
            RS_EventParticipantWrapper wrapper = new RS_EventParticipantWrapper();
            wrapper.EventParticipant = ep;
            returnList.add(wrapper);
        }

        return returnList;
    }

    public class AssessmentWrapper {

        public Boolean isNew {get; set;}
        public Assessment__c assessment {get; set;}
        public list<Scheduled_Payment__c> scheduledPayments {get; set;}
        public String paymentAmount {get; set;}
        public Boolean isSelected {get; set;}
        public Boolean hasPrevBalance {get; set;}
        public Decimal prevBalance {get; set;}

        //Added by Kritik :
        public Integer uniqueIdentifier {get;set;}

        public AssessmentWrapper(){
            isSelected = false;
            isNew = false;
            hasPrevBalance = false;
        }
    }

    public static list<UtilitiesWrappers.AssessmentWrapper> CreateAssessmentWrappers(list<Assessment__c> assessments, String schedPaymentSOQLFields){

        map<Id,Assessment__c> assessmentMap = new map<Id,Assessment__c>(assessments);
        list<Scheduled_Payment__c> scheduledPayments = UtilitiesFinancials.GetScheduledPayment(schedPaymentSOQLFields,assessmentMap.keySet());

        list<AssessmentWrapper> returnList = new list<AssessmentWrapper>();
        for(Assessment__c curAssessment : assessments){

            UtilitiesWrappers.AssessmentWrapper wrapper = new AssessmentWrapper();
            wrapper.assessment = curAssessment;
            wrapper.isNew = false;
            list<Scheduled_Payment__c> sPayments = new list<Scheduled_Payment__c>();
            for(Scheduled_Payment__c curSPayment : scheduledPayments){
                if(curSPayment.Assessment__c == curAssessment.Id){
                    sPayments.add(curSPayment);
                }
            }
            wrapper.scheduledPayments = sPayments;
            returnList.add(wrapper);
        }

        return returnList;
    }


    public class CreditPaymentWrapper {

        public Assessment__c assessment {get; set;}
        public list<Scheduled_Payment__c> scheduledPayments {get; set;}
        public Boolean isSelected {get; set;}
        public Boolean hasBeenProcessed {get; set;}
        public Payment_Adjustment__c paymentAdjustment {get; set;}

        public CreditPaymentWrapper (){
            isSelected = false;
            hasBeenProcessed = false;
            paymentAdjustment = new Payment_Adjustment__c();
            paymentAdjustment.Type__c = 'Credit';
        }
    }

    public static list<UtilitiesWrappers.CreditPaymentWrapper > CreateCreditPaymentWrapper(list<Assessment__c> assessments, String schedPaymentSOQLFields){

        map<Id,Assessment__c> assessmentMap = new map<Id,Assessment__c>(assessments);
        list<Scheduled_Payment__c> scheduledPayments = UtilitiesFinancials.GetScheduledPayment(schedPaymentSOQLFields,assessmentMap.keySet());

        list<CreditPaymentWrapper > returnList = new list<CreditPaymentWrapper >();
        for(Assessment__c curAssessment : assessments){

            CreditPaymentWrapper  wrapper = new CreditPaymentWrapper ();
            wrapper.assessment = curAssessment;
            list<Scheduled_Payment__c> sPayments = new list<Scheduled_Payment__c>();
            for(Scheduled_Payment__c curSPayment : scheduledPayments){
                if(curSPayment.Assessment__c == curAssessment.Id){
                    sPayments.add(curSPayment);
                }
            }
            wrapper.scheduledPayments = sPayments;
            returnList.add(wrapper);
        }

        return returnList;
    }

    public class AccountWrapper{

        public Boolean IsSelected {get; set;}
        public Account TheAccount {get; set;}

        public AccountWrapper(){
            IsSelected = false;
        }
    }

    public static list<UtilitiesWrappers.AccountWrapper> CreateAccountWrappers(list<Object> accountsToConvert){

        list<UtilitiesWrappers.AccountWrapper> wrappers = new list<UtilitiesWrappers.AccountWrapper>();
        for(Object curObject : accountsToConvert){
            Account acc = (Account)curObject;
            UtilitiesWrappers.AccountWrapper wrapper = new UtilitiesWrappers.AccountWrapper();
            wrapper.TheAccount = acc;
            wrappers.add(wrapper);
        }
        return wrappers;
    }


    public class DonationWrapper{
        public String Fund {get; set;}
        public String FundName {get; set;}
        public Decimal Amount {get; set; }
        public String HonoreeMemorialName {get; set;}
        public String Listing {get; set;}
        public String AcknowledgementText {get; set;}
        public String DonationType {get; set;}

        public DonationWrapper(){

        }
    }
}