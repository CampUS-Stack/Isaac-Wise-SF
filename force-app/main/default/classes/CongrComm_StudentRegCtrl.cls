public with sharing class CongrComm_StudentRegCtrl {

    public static final set<String> GRADE_LEVEL_EXCLUSIONS = new set<String>{
            'Class of 2003', 'Class of 2004', 'Class of 2005', 'Class of 2006', 'Class of 2007', 'Class of 2008', 'Class of 2009',
            'Class of 2010', 'Class of 2011', 'Class of 2012', 'Class of 2013'
    };
    public List<SelectOption> classOptions { get; set; }

    public list<UtilitiesWrappers.ContactWrapper> childContacts { get; set; }
    public Boolean showMsg { get; set; }

    public Account communityUserAccountDetails { get; set; }
    public Contact SelectedContact { get; set; }
    public Contact ContactToEdit { get; set; }
    public Student_Registration_Form__c stdRegFormEdit { get; set; }
    //public Boolean showHealthSection { get; set; }


    public Boolean PageHasError { get; set; }

    @TestVisible private Contact communityUserContact { get; set; }

    public list<SelectOption> GradeLevels {
        get {
            list<SelectOption> returnOptions = new list<SelectOption>();
            Schema.DescribeFieldResult fieldResult = Contact.Grade_Level__c.getDescribe();
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            returnOptions.add(new SelectOption('', '-- NONE --'));
            for (Schema.PicklistEntry f : ple) {
                if (!GRADE_LEVEL_EXCLUSIONS.contains(f.getLabel())) {
                    returnOptions.add(new SelectOption(f.getLabel(), f.getValue()));
                }
            }

            return returnOptions;
        }
    }

    public List<SelectOption> sundayRegistrationOptions {
        get {
            List<SelectOption> returnOptions = new List<SelectOption>();
            Schema.DescribeFieldResult fieldResult = Student_Registration_Form__c.Sunday_Session_Preference__c.getDescribe();
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            for(Schema.PicklistEntry option : ple){
                returnOptions.add(new SelectOption(option.getValue(), option.getLabel()));
            }

            return returnOptions;
        }
    }


    public CongrComm_StudentRegCtrl() {

        String conId = getIdFRomParam();

        initializeVariables();
        populateChildContacts();

        classOptions = generateClassOptions();

        if (String.isNotBlank(conId)) {
            this.ContactToEdit = getContactToEdit(conId);

            communityUserAccountDetails = [
                    SELECT Id,Name,Phone,ShippingStreet,ShippingCity,ShippingState,ShippingPostalCode,ShippingCountry,BillingStreet,
                            BillingCity,BillingState,BillingPostalCode,BillingCountry,Seasonal_Street__c,Seasonal_City__c,Seasonal_State__c,
                            Seasonal_Zip__c,Seasonal_Phone__c,Seasonal_Address_Start_Month__c,Seasonal_Address_End_Month__c,Wedding_Date__c
                    FROM Account
                    WHERE id = :communityUserContact.AccountID
            ];
            stdRegFormEdit = new Student_Registration_Form__c();
            stdRegFormEdit.Student__c = conId;
        }


        if (getMsgFromParam() == 'true') {
            showMsg = true;
        }

       // isAgeUnder19();
        //showHealthSection = true;
    }

    @TestVisible private void populateChildContacts() {

        List<Contact> childCon = [SELECT Id,Name,Account.Name,Contact_Type__c,FirstName,LastName FROM Contact WHERE Account.Id = :communityUserContact.AccountId AND Contact_Type__c = 'Child'];
        childContacts = UtilitiesWrappers.createContactWrappers(childCon);
    }

    @TestVisible private void initializeVariables() {

        showMsg = false;
        PageHasError = false;
        childContacts = new List<UtilitiesWrappers.ContactWrapper>();
        classOptions = new List<SelectOption>();
        this.communityUserContact = UtilitiesUsers.GetContactForCommunityUser(UserInfo.getUserId());

    }

    public PageReference nextBtn() {

        List<Contact> selectedCon = new List<Contact>();
        for (UtilitiesWrappers.ContactWrapper cw : childContacts) {
            if (cw.isSelected) {
                selectedCon.add(cw.theContact);
            }
        }
        return null;
    }

/*    public PageReference isAgeUnder19() {

        System.debug('isAgeUnder19');
        if (ContactToEdit.Date_of_Birth__c != null
                && ContactToEdit.Date_of_Death__c == null) {

            Integer numberDays = -Date.today().daysBetween(ContactToEdit.Date_of_Birth__c);
            System.debug('numberDays:: ' + numberDays);

            Decimal age = numberDays / 365.2425;
            System.debug('age:: ' + age);

            if (age < 19) {
                showHealthSection = true;
            } else {
                showHealthSection = false;
            }
        }

        return null;
    }*/

    @TestVisible private String getMsgFromParam() {

        if (ApexPAges.currentPage().getParameters().containsKey('msg')) {
            return ApexPages.currentPage().getParameters().get('msg');
        }

        return '';
    }
    @TestVisible private String getIdFRomParam() {

        if (ApexPAges.currentPage().getParameters().containsKey('id')) {
            return ApexPages.currentPage().getParameters().get('id');
        }

        return '';
    }

    @TestVisible private Contact getContact(Id contactId) {
        try {
            Contact returnContact = [SELECT Id,Name FROM Contact WHERE Id = :contactId];
            return returnContact;
        } catch (QueryException qe) {
            system.debug(qe.getMessage());
            return null;
        }
    }

    Public PageReference SaveData() {

        if (!stdRegFormEdit.Medical_Consent__c && ContactToEdit.Age__c < 19) {
            this.PageHasError = true;
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Medical Consent is required in order to register. Please contact Courtney Anthony with questions or concerns.');
            ApexPages.addMessage(myMsg);
            return null;
        }

        if (!stdRegFormEdit.Photo_Consent__c && ContactToEdit.Age__c < 19) {
            this.PageHasError = true;
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Photo Consent is required in order to register. Please contact Courtney Anthony with questions or concerns.');
            ApexPages.addMessage(myMsg);
            return null;
        }

        this.PageHasError = false;

        try {
            update ContactToEdit;
            update communityUserAccountDetails;
            insert stdRegFormEdit;
        } catch (Exception e) {
            System.debug(e);
            system.debug(e.getLineNumber());
            return null;
        }
        PageReference pageRef = new PageReference('/CongrComm_Students?msg=true');
        pageRef.setRedirect(true);
        return pageRef;
    }

    private List<SelectOption> generateClassOptions() {
        List<SelectOption> listToReturn = new List<SelectOption>();
        List<SelectOptionWrapper> SelectOptionList = new List<SelectOptionWrapper>();

        List<Class__c> listOfClasses = [select id, Name, Available_for_Registration__c from Class__c where Available_for_Registration__c = true];

        listToReturn.add(new SelectOption('', '--None--'));

        for (Class__c c : listOfClasses) {
            SelectOptionList.add(new SelectOptionWrapper(c.Id, c.Name));
        }
        SelectOptionList.sort();

        for (SelectOptionWrapper sow : SelectOptionList) {
            listToReturn.add(sow.generateSelectOption());
        }
        return listToReturn;

    }

    @TestVisible private Contact getContactToEdit(String contactId) {
        try {

            Schema.DescribeSObjectResult Describe = Contact.sObjectType.getDescribe();
            Map<String, Schema.SObjectField> Fields = Describe.fields.getMap();

            String SOQL = 'Select RecordType.Name,';
            for (String fieldName : Fields.keySet()) {
                System.debug('fieldName: ' + fieldName);
                SOQL += fieldName + ',';
            }
            SOQL = SOQL.substring(0, SOQL.length() - 1);
            SOQL += ' FROM Contact WHERE Id = :contactId limit 1';
            Contact c = Database.query(SOQL);
            return c;
        } catch (QueryException qe) {
            system.debug(qe.getMessage());
            return null;
        }
    }

    public class SelectOptionWrapper implements Comparable {
        public String value { get; set; }
        public String label { get; set; }

        public SelectOptionWrapper(String invalue, String inlabel) {
            label = inlabel;
            value = invalue;
        }

        public SelectOption generateSelectOption() {
            return new SelectOption(value, label);
        }

        public Integer compareTo(Object compareTo) {
            SelectOptionWrapper compareToSO = (SelectOptionWrapper) compareTo;
            if (label == compareToSO.label) return 0;
            if (label > compareToSO.label) return 1;
            return -1;
        }


    }

}