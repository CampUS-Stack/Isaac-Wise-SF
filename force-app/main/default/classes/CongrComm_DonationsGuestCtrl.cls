/**
 * Created by Kritik Garg on 06-03-2019.
 */

public without sharing class CongrComm_DonationsGuestCtrl {


    public List<SelectOption> fundOptions {get;set;}
    public List<SelectOption> PSTHPFfundOptions {get;set;}
    public String selectedFund{get;set;}
    public String honoreeName{get;set;}
    public String listing{get;set;}
    public String sendAcknowledgementTo{get;set;}
    public Decimal amount {get; set;}
    public Assessment__c assessment {get; set;}

    public ContactWrapper con {get;set;}
    @TestVisible private Contact savedContact {get;set;}

   // @TestVisible private Contact communityUserContact {get; set;}

    public list<SelectOption> DonationTypes {
        get{
            list<SelectOption> returnList = new list<SelectOption>();
            Schema.DescribeFieldResult fieldResult = Assessment__c.Donation_Type__c.getDescribe();
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            for( Schema.PicklistEntry pickListVal : ple){
                returnList.add(new SelectOption(pickListVal.getLabel(),pickListVal.getValue()));
            }
            return returnList;
        }
        set;
    }

    public String selectedDonationType {get; set;}
    public String PSTHPFselectedDonationType {get; set;}

    Public Boolean pageErrors {
        get{
            return ApexPages.hasMessages();
        }
    }

    public CongrComm_DonationsGuestCtrl() {

        fundOptions = new List<SelectOption>();
        assessment = new Assessment__c();

        //this.communityUserContact = UtilitiesUsers.GetContactForCommunityUser(UserInfo.getUserId());

        fundOptions = generateFundOptions();
        PSTHPFfundOptions = generatePSTHPFFundOptions();

        con = new ContactWrapper();
        savedContact = new Contact();
    }

    public PageReference makeDonationAction() {

        if(this.con.lName == null ||this.con.lName == '' || this.con.Email == null || this.con.Email == '') {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Last Name and Email are required');
            ApexPages.addMessage(myMsg);
            return null;
        }
        createOrFindContact();
        if(this.savedContact.Id == null || this.savedContact.AccountId == null) {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Invalid Contact Details');
            ApexPages.addMessage(myMsg);
            return null;
        }

        Assessment__c ase = new Assessment__c();
        if(this.Amount == null || this.Amount ==0) {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Amount should be greater than 0');
            ApexPages.addMessage(myMsg);
            return null;
        }

        if(this.selectedFund == null || this.selectedFund =='') {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Select Fund');
            ApexPages.addMessage(myMsg);
            return null;
        }
        ase.Assessed_Amount__c = this.Amount;
        ase.RecordTypeId = UtilitiesSObject.getRecordTypeId('Assessment',Assessment__c.SObjectType);
        ase.Account__c = savedContact.AccountId;
        ase.Contact__c = savedContact.Id;
        ase.Designation__c = this.selectedFund;
        ase.Assessment_Date__c = Date.today();
        ase.Honoree_Memorial_Name__c = honoreeName;
        ase.Listing__c = listing;
        ase.Send_Acknowledgement_To__c = sendAcknowledgementTo;
        ase.Donation_Type__c = selectedDonationType;
        ase.From_Website__c = true;

        try {
            insert ase;
        } catch (Exception e ) {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,e.getMessage());
            ApexPages.addMessage(myMsg);
            return null;
        }

        Payment_Adjustment__c payAdj = createPaymentAdjustment(ase);
        Payment_Adjustment__c reQueriedPayment = [SELEcT Id,Name, (SELECT From_Website__c,Incomplete_Payment__c FROM Scheduled_Payment_Bridges__r) FROM Payment_Adjustment__c WHERE Id = :payAdj.Id];

        for(Payment_Adjustment_Allocation__c curAlloc : reQueriedPayment.Scheduled_Payment_Bridges__r){
            curAlloc.From_Website__c = true;
            curAlloc.Incomplete_Payment__c = true;
        }

        try{
            update reQueriedPayment.Scheduled_Payment_Bridges__r;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return null;
        }

        PageReference pr = Page.CongrComm_NMIPaymentProcessor;
        pr.getParameters().put('paId', reQueriedPayment.Id);
        pr.setRedirect(true);
        return pr;
    }

    @testvisible private Payment_Adjustment__c createPaymentAdjustment(Assessment__c assessment){

        Payment_Adjustment__c newPayment = new Payment_Adjustment__c();
        newPayment.Household__c = this.savedContact.AccountId;
        newPayment.Contact__c = this.savedContact.Id;
        newPayment.Amount__c = this.Amount;
        newPayment.Type__c = 'Credit Card';
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

    public PageReference cancel() {
        PageReference pr = Page.CongrComm_FinancialsHome ;
        return pr;
    }



    private List<SelectOption> generateFundOptions() {
        List<SelectOption> listToReturn = new List<SelectOption>();
        List<SelectOptionWrapper> SelectOptionList = new List<SelectOptionWrapper>();

        List<Designation__c> listOfDesignation = [Select Id, Name, Display_Fund_Values_on_Portal__c  from Designation__c where Display_Fund_on_Portal__c = true];

        listToReturn.add(new SelectOption('','--None--'));


        for(Designation__c dn : listOfDesignation) {

            List<String> values = new List<String>();

            if(dn.Display_Fund_Values_on_Portal__c != null && dn.Display_Fund_Values_on_Portal__c != '') {
                values = dn.Display_Fund_Values_on_Portal__c.split(';');
            }

            if(values.size() > 0 ) {
                for( String t : values) {
                    SelectOptionList.add(new SelectOptionWrapper(dn.Id,t));
                }
            } else {
                SelectOptionList.add(new SelectOptionWrapper(dn.Id,dn.Name));
            }

        }
        SelectOptionList.sort();

        for(SelectOptionWrapper sow : SelectOptionList) {
            listToReturn.add(sow.generateSelectOption());
        }
        return listToReturn;

    }

    private List<SelectOption> generatePSTHPFFundOptions() {
        List<SelectOption> listToReturn = new List<SelectOption>();
        List<SelectOptionWrapper> SelectOptionList = new List<SelectOptionWrapper>();

        List<Designation__c> listOfDesignation = [Select Id, Name, Display_Fund_Values_on_Portal__c  from Designation__c where Display_Fund_on_Portal__c = true AND Id = 'a021G00000oBl9A'];

        if(listOfDesignation.size() > 0){
            PSTHPFselectedDonationType = listOfDesignation[0].Id;
        }

        for(Designation__c dn : listOfDesignation) {

            List<String> values = new List<String>();

            if(dn.Display_Fund_Values_on_Portal__c != null && dn.Display_Fund_Values_on_Portal__c != '') {
                values = dn.Display_Fund_Values_on_Portal__c.split(';');
            }

            if(values.size() > 0 ) {
                for( String t : values) {
                    SelectOptionList.add(new SelectOptionWrapper(dn.Id,t));
                }
            } else {
                SelectOptionList.add(new SelectOptionWrapper(dn.Id,dn.Name));
            }

        }
        SelectOptionList.sort();

        for(SelectOptionWrapper sow : SelectOptionList) {
            listToReturn.add(sow.generateSelectOption());
        }
        return listToReturn;

    }

    @TestVisible private void createOrFindContact() {
        Contact contactToReturn;
        if(String.isNotBlank(con.email)){
            contactToReturn = checkForExistingContact(con.email);
        }

        if(contactToReturn != null) {
            system.debug('Found Contact');

            if (
                    (con.street != null && con.street != '') ||
                            (con.city != null && con.city != '') ||
                            (con.state != null && con.state != '') ||
                            (con.zip != null && con.zip != '')
                    ) {
                contactToReturn.MailingStreet = con.street;
                contactToReturn.MailingCity = con.city;
                contactToReturn.MailingState = con.state;
                contactToReturn.MailingPostalCode = con.zip;
            }
            try {
                update contactToReturn;
            } catch (Exception e) {
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,e.getMessage());
                ApexPages.addMessage(myMsg);
            }


        } else {
            contactToReturn = new Contact();
            contactToReturn.FirstName = con.fName;
            contactToReturn.LastName = con.lName;
            contactToReturn.Email = con.email;
            contactToReturn.MailingStreet = con.street;
            contactToReturn.MailingCity = con.city;
            contactToReturn.MailingState = con.state;
            contactToReturn.MailingPostalCode = con.zip;

            contactToReturn.AccountId = UtilitiesCustomSetting.GetInstance().getImportantAccountSetting('Wise Temple Guest Account');

            try {
                insert contactToReturn;
            } catch (Exception e) {
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,e.getMessage());
                ApexPages.addMessage(myMsg);
            }
        }
        // MailingPostalCode, MailingStreet, MailingCountry, MailingState,
        savedContact = contactToReturn;
    }

    @TestVisible private Contact checkForExistingContact(String email){
        try{
            Contact returnContact = [SELECT Id, AccountId, FirstName, LastName, Name, Email FROM Contact WHERE Email = :email];
            return returnContact;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return null;
        }
    }

    public class SelectOptionWrapper implements Comparable {
        public String value {get; set;}
        public String label {get; set;}

        public SelectOptionWrapper(String invalue, String inlabel) {
            label = inlabel;
            value = invalue;
        }

        public SelectOption generateSelectOption() {
            return new SelectOption(value,label);
        }

        public Integer compareTo(Object compareTo) {
            SelectOptionWrapper compareToSO = (SelectOptionWrapper)compareTo;
            if (label == compareToSO.label) return 0;
            if (label > compareToSO.label) return 1;
            return -1;
        }



    }

    public class ContactWrapper{
        public String fName {get;set;}
        public String lName {get;set;}
        public String email {get;set;}
        public String street {get;set;}
        public String city {get;set;}
        public String state {get;set;}
        public String zip {get;set;}
    }

}