/**
 * Created by Chris Home Desktop on 4/9/2018.
 */

public with sharing class CongrComm_ContactDetailsCtrl {

    public static final set<String> GRADE_LEVEL_EXCLUSIONS = new set<String>{'Class of 2003','Class of 2004','Class of 2005','Class of 2006','Class of 2007','Class of 2008','Class of 2009',
            'Class of 2010','Class of 2011','Class of 2012','Class of 2013'};

    public Contact ContactToEdit {get; set;}
    public list<UtilitiesWrappers.ContactWrapper> HouseholdContacts {get; set;}
    Public List<College_University__c> contactColleges {get; set;}

    public String CollegeUniversityIdToDelete {get; set;}

    Public Boolean hasErrors {
        get{
            return ApexPages.hasMessages();
        }
    }
    
  //  public Date contactDOB {get; set;}

    public list<SelectOption> GradeLevels {
        get{
            list<SelectOption> returnOptions = new list<SelectOption>();
            Schema.DescribeFieldResult fieldResult = Contact.Grade_Level__c.getDescribe();
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            returnOptions.add(new SelectOption('','-- NONE --'));
            for( Schema.PicklistEntry f : ple)
            {
                if(!GRADE_LEVEL_EXCLUSIONS.contains(f.getLabel())){
                    returnOptions.add(new SelectOption(f.getLabel(), f.getValue()));
                }
            }

            return returnOptions;
        }
    }
    public CongrComm_ContactDetailsCtrl(){
        initializeVariables();
    }

    public PageReference AddNewCollege(){

        if(SaveContact() == null){
            return null;
        }

        PageReference pr = Page.CongrComm_CollegeUniEdit;
        pr.setRedirect(true);
        pr.getParameters().put('cId',ContactToEdit.Id);
        pr.getParameters().put('type','new');
        return pr;
    }

    /**
     * @author: Chris Gibson
     * @date: 05.27.2018
     * @description : This method saves the contact record and runs any necessary page validation
     *
     * @return a PageReference object, taking the user to the success page or reload of current page
     */
    public PageReference SaveContact(){

        Boolean isValidationErrors = runPageValidation();
        if(isValidationErrors == true){
            return null;
        }

        try{
            update ContactToEdit;

            PageReference pr = Page.CongrComm_UpdateGPS;
            pr.getParameters().put('cId',ContactToEdit.Id);
            pr.getParameters().put('retURL','/CongrComm_ContactDetails');
            pr.setRedirect(true);
            return pr;
        }
        catch(DmlException de){
            system.debug(de.getMessage());
            return null;
        }
    }

    public PageReference EditCollegeUniversity(){

        if(SaveContact() == null){
            return null;
        }

        PageReference pr = Page.CongrComm_CollegeUniEdit;
        pr.setRedirect(true);
        pr.getParameters().put('cId',CollegeUniversityIdToDelete);
        pr.getParameters().put('type','edit');
        return pr;
    }

    public PageReference RemoveCollegeUniversity(){
        try{
            for(College_University__c curUniv : contactColleges){
                if(curUniv.Id == CollegeUniversityIdToDelete){
                    delete curUniv;
                    return null;
                }
            }
        }
        catch(DmlException de){
            system.debug(de.getMessage());
        }

        return null;
    }

    /// Run all page validation. return true if error condition met and add page messages.
    @TestVisible private Boolean runPageValidation(){

        if (ContactToEdit.Employer_Zip_Code__c!= null && ContactToEdit.Employer_Zip_Code__c != '' ) {
            if (!(ContactToEdit.Employer_Zip_Code__c.length() == 10 || ContactToEdit.Employer_Zip_Code__c.length() == 5) && ContactToEdit.Employer_Zip_Code__c.length() > 0) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Employer Zip Code must be exactly 5 or 10 digits.'));
                return true;
            }
        }

        if (ContactToEdit.OtherPostalCode != null && ContactToEdit.OtherPostalCode != '' ) {
            if (!(ContactToEdit.OtherPostalCode.length() == 10 || ContactToEdit.OtherPostalCode.length() == 5) && ContactToEdit.OtherPostalCode.length() > 0) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Other Zip Code must be exactly 5 or 10 digits.'));
                return true;
            }
        }

        if (ContactToEdit.Mobile_Phone__c != null && ContactToEdit.Mobile_Phone__c != '' ) {
            String contactMobilePhone = ContactToEdit.Mobile_Phone__c.replaceAll(' ','').replaceAll('\\(','').replaceAll('\\)','').replaceAll('-','');
            if (contactMobilePhone.length() != 10 && contactMobilePhone.length() > 0) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Cell Phone must be exactly 10 digits.'));
                return true;
            }
        }
        if (ContactToEdit.Work_Phone__c != null && ContactToEdit.Work_Phone__c != '' ) {
            String contactWorkPhone = ContactToEdit.Work_Phone__c.replaceAll(' ','').replaceAll('\\(','').replaceAll('\\)','').replaceAll('-','');
            if (contactWorkPhone.length() != 10 && contactWorkPhone.length() > 0) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Work Phone must be exactly 10 digits.'));
                return true;
            }
        }

        return false;
    }

    @TestVisible private void initializeVariables(){
        String contactId = getContactIdFromParam();
        if(!String.isEmpty(contactId)){
            ContactToEdit = getContactToEdit(contactId);
            this.contactColleges = getCollegesUniverisites(ContactToEdit.Id);
            /*
            if(ContactToEdit.Date_of_Birth__c != null) {
                this.contactDOB = myDate = date.newinstance(ContactToEdit.Date_of_Birth__c.year(), ContactToEdit.Date_of_Birth__c.month(), ContactToEdit.Date_of_Birth__c.day()); 
            } */
        }
    }

    @TestVisible private String getContactIdFromParam(){
        if(ApexPages.currentPage().getParameters().containsKey('cId')){
            return ApexPages.currentPage().getParameters().get('cId');
        }
        else{
            return '';
        }
    }

    @TestVisible private list<College_University__c> getCollegesUniverisites(String contactId){

        try {
            return [
                        SELECT Id, College_University__c, Grade_Level__c, Major__c,End_Date__c, Start_Date__c
                        FROM College_University__c
                        WHERE Contact__c = :contactId
                    ];
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return null;
        }
    }

    @TestVisible private Contact getContactToEdit(String contactId){
        try{
            Contact c = [SELECT Id,RecordType.DeveloperName,FirstName,LastName,Hebrew_Name__c,Employer__c,Employer_Zip_Code__c,Email,Mobile_Phone__c,Gender__c,Birthdate,
                                Publicize_Birthdate_Bulletin__c,Publicize_Birthdate_Rabbi__c,Confirmation_Year__c,Confirmed_at_Wise__c,Consecrated_at_Wise__c,
                                Consecrated_Year__c,Grew_up_Here__c,Religious_Affiliation__c,Bar_Bat_Mitzvah_at_Wise__c,Bar_Bat_Mitzvah_Date__c,
                                Kulanu_Graduation_Year__c,Graduated_from_Wise_Kulanu__c,Title,Work_Phone__c,Work_Email__c,Occupation__c,Specialization__c,
                                Religious_School_Student__c,Grade_Level__c,Forms_Received__c,School_Name__c,New_Student__c,Special_Student_Information__c,No_Midweek__c,
                                Anything_affecting_attendance__c,Do_not_use_my_child_s_photo__c,English_Reading_Level__c,May_we_publish_in_school_directory__c,
                                Has_IEP_in_Secular_school__c,Allergies__c,Medications__c,Learning_Disability__c,
                                Attention_Deficit_Disorder__c,Give_Consent__c,Emotional_Health_Concern__c,Explain_all_that_were_checked__c,Nickname__c,Date_of_Birth__c,
                                Emergency_Contact_1__c,Emergency_Contact_2__c,Emergency_Contact_3__c,Emergency_Contact_1_Phone__c,Emergency_Contact_1_Relationship__c,
                                Emergency_Contact_2_Phone__c,Emergency_Contact_2_Relationship__c,Emergency_Contact_3_Phone__c,Emergency_Contact_3_Relationship__c,
                                MailingStreet,MailingCity,MailingState,MailingPostalCode,MailingCountry,OtherStreet,OtherCity,OtherState,OtherPostalCode,OtherCountry,
                                Other_Parent_Email1__c,Other_Parent_Name1__c,Other_Parent_Phone1__c,Bar_Bat_Mitzvah_Year__c,
                                Doctor_s_Name__c, Doctor_s_Phone__c,Dentist__c, Dentist_s_Phone__c,age__c
                         FROM Contact c WHERE Id = :contactId];
            return c;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return null;
        }
    }
}