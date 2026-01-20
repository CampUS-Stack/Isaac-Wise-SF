/**
 * Created by Chris Home Desktop on 4/30/2018.
 */

public without sharing class CongrComm_DirectoryCtrl {

    public static final String CONTACT_SOQL_FIELDS = 'Id, Name,FirstName,Account.Phone,LastName,Contact_Type__c,Email,Grade_Level__c,RecordType.DeveloperName, Birthdate, Home_Phone__c,Account.Current_Mailing_Address__c, Mobile_Phone__c, Account.Contact_1_Email_Formula__c, Account.Contact_2_Email_Formula__c, HomePhone,MailingStreet, MailingCity ,MailingState, MailingCountry, Account.Name,Account.Contact_1__r.Email, Account.Contact_2__r.Email,  Phone, School_Name__c';

    private static final List<String> listOfYearsToInclude = new List<String>{'Class of 2021','Class of 2020','Class of 2019','Class of 2018','Class of 2017','Class of 2016'};
    
    /// Variable used for input field functionality.
    public Contact DummyContact {get; set;}

    public List<Contact> contactList { get; private set; }
    //public Contact searchContact { get; set;}
    //Public task inBirthDate {get;set;}
    public String startDate {get;set;}  //BirthDate
    public String inName {get;set;}     //Name
    public String lastName {get;set;}     //Name
    public String inCity {get;set;}         //City
    public String inState {get;set;}    //State
    public String inGrade {get;set;}   //Grade
    public String inZip {get;set;}   //Zip
    public Integer inZipValidation;
    public String inSecularSchoolName {get;set;} //Secular School Name

    public List<SelectOption> gradeOptions {get; set;}
    public List<SelectOption> secularSchoolOptions {get; set;}
    
    public Contact con {get;set;}
    public String conId {get; set;}
    public boolean firstLoad {get; set;}

    public Account theAccount {get; set;}

    public Integer NumberOfResults{
        get{
            if(contactList == null){
                return 0;
            }

            return contactList.size();
        }
    }

    public CongrComm_DirectoryCtrl() {
        this.DummyContact = new Contact();
        contactList = new List<Contact>();
        gradeOptions = new List<SelectOption>();
        inGrade  = '';
        //gradeOptions.add(new SelectOption('','None'));
        gradeOptions.add(new SelectOption('',''));
        gradeOptions.add(new SelectOption('None','None'));
        gradeOptions.add(new SelectOption('All','All'));
        for(String aValue :  getPickListValues(Contact.Grade_Level__c.getDescribe())) {
            String label = aValue;            
            if(label == 'K')
                label = 'Kindergarten';
            else if(label == 'PK') 
                label = 'Pre-Kindergarten';
            else if(label.contains('Class of') && !listOfYearsToInclude.contains(label)){
                continue;
            }
            gradeOptions.add(new SelectOption(aValue,label) );
        }

        secularSchoolOptions = new List<SelectOption>();
        inSecularSchoolName  = '';
        //gradeOptions.add(new SelectOption('','None'));
        secularSchoolOptions.add(new SelectOption('',''));
        secularSchoolOptions.add(new SelectOption('None','None'));
        secularSchoolOptions.add(new SelectOption('All','All'));
        for(String aValue :  getPickListValues(Contact.School_Name__c.getDescribe())) {
            secularSchoolOptions.add(new SelectOption(aValue,aValue) );
        }

        System.debug(gradeOptions);
        firstLoad = true;

        this.theAccount = getCurrentUserAccount();
    }

    public PageReference searchContacts() {

        firstLoad = false;
        Boolean hasValidationErrors = runPageValidation();
        if(hasValidationErrors){
            return null;
        }

        searchForContacts();
        return null;
    }

    public void searchForContacts() {
        String query = 'SELECT ' + CONTACT_SOQL_FIELDS + ' FROM Contact WHERE Is_Current_Member__c = True ';


        if(inName!=null && inName!= '') {
            query += ' AND (FirstName LIKE ' + '\'%' + inName.trim() + '%\' OR Nickname__c LIKE ' + '\'%' + inName.trim() + '%\')';
        }
        if(lastName!=null && lastName!= '') {
            query += ' AND (LastName LIKE ' + '\'%' + lastName.trim() + '%\' OR Nickname__c LIKE ' + '\'%' + lastName.trim() + '%\')';
        }

        if(inZip != null)
            inZipValidation = inZip.length();

        system.debug(inzip);
        if(inZip!=null && inZip!= '' && (inZipValidation == 5 || inZipValidation == 10)) {
            query += ' AND Account.ShippingPostalCode LIKE ' + '\'%' + inZip + '%\' ';
        } else if (!(inZipValidation == 5 || inZipValidation == 10) && inZipValidation > 0){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Zip Code must be exactly 5 or 10 digits'));
            inzip = '';
            contactList = new list<Contact>();
            return;
        }

        if(!String.isEmpty(inSecularSchoolName) && inSecularSchoolName == 'All'){
            query += ' AND School_Name__c != \'\'';
        }
        else if(!String.isEmpty(inSecularSchoolName) && inSecularSchoolName == 'None'){
            query += ' AND School_Name__c = \'\'';
        }
        else if(!String.isEmpty(inSecularSchoolName)) {
            query += ' AND School_Name__c = \''   + inSecularSchoolName.trim()   + '\'';
        }

        //Grade Search handling
        if(!String.isEmpty(inGrade) && inGrade == 'All'){
            query += ' AND Grade_Level__c != \'\'';
        }
        else if(!String.isEmpty(inGrade) && inGrade == 'None'){
            query += ' AND Grade_Level__c = \'\'';
        }
        else if(!String.isEmpty(inGrade)) {
            query += ' AND Grade_Level__c = \''   + inGrade.trim()   + '\'';
        }

        query += ' AND Account.Directory_Opt_out__c = false';
        query += ' ORDER BY Account.Name ASC NULLS LAST';
        query += ' LIMIT 200';

        System.debug(query);
        try{
            contactList = Database.query(query);
        } catch (Exception e) {
            System.debug(e);
            contactList = new list<Contact>();
        }
        System.debug(contactList);
    }

    public List<String> getPickListValues(Schema.DescribeFieldResult fieldResult) {
        List<String> pickListValuesList= new List<String>();
        //Schema.DescribeFieldResult fieldResult = Contact.Grade_Level__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry pickListVal : ple){
            pickListValuesList.add(pickListVal.getLabel());
        }
        return pickListValuesList;
    }

    @TestVisible private Boolean runPageValidation(){

        if(String.isBlank(inName) && String.isBlank(inGrade) && String.isBlank(inZip) && String.isBlank(inSecularSchoolName) && String.isBlank(lastName)){
            return true;
        }

        return false;
    }

    public void updateAccount(){

        try{
            update this.theAccount;
        }
        catch(DmlException de){
            system.debug(de.getMessage());
        }
    }


    @TestVisible private Account getCurrentUserAccount(){

        Contact userContact = UtilitiesUsers.GetContactForCommunityUser(UserInfo.getUserId());
        if(userContact == null || String.isBlank(userContact.AccountId)){
            return null;
        }

        try{
            Account returnAccount = [SELECT Id,Directory_Opt_out__c FROM Account WHERE Id = :userContact.AccountId];
            return returnAccount;
        }
        catch (QueryException qe){
            system.debug(qe.getMessage());
            return null;
        }
    }

    public PageReference clearSearchAction() {
        
        inGrade = '';
        inSecularSchoolName = '';
        inName = '';
        lastName = '';
        inZip ='';
        contactList = new List<Contact>();
        return null;
        
    }
    
    //TO be used in apex: actionfunction to get contact details 
    public PageReference fetchContactDetails() {
        con = new Contact();
        String query = 'SELECT ' + CONTACT_SOQL_FIELDS + ' FROM Contact WHERE Id = \'' + conId + '\'';
        con = Database.query(query);
        return null;
    }
}