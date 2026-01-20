public without sharing class CongrComm_DonationsController {
    
    public Final String DONATION_PAGE = 'CongrComm_Donations';
    public Final String DONATION_GUEST_PAGE = 'CongrComm_DonationsGuest';
    public Final String DONATION_PLUM_STREET_PAGE = 'CongrComm_DonationsPlumStreet';
    public Final String MEM_DONATION_PAGE = 'CongrComm_MemorialDonations';
    public Final String MEM_DONATION_DESIGNATION_NAME = 'Memorial Books'; //TODO: Use Custom Label
    public Final Decimal HARD_COPY_COST = 10.00;
    
    public List<UtilitiesWrappers.DonationWrapper> donationWrappers { get; set; }
    public List<SelectOption> fundOptions { get; set; }
    public List<SelectOption> PSTHPFfundOptions { get; set; }
    public String selectedFund { get; set; }
    public String honoreeName { get; set; }
    public String listing { get; set; }
    public String sendAcknowledgementTo { get; set; }
    public String fiscalYear { get; set; }
    public Decimal amount { get; set; }
    public Boolean includeHardCopyCost { get; set; }
    public Boolean hasDonationsEntered { get; set; }
    public Boolean displayContactInfo { get; set; }
    public Integer fundSelectedToRemove { get; set; }
    public Assessment__c assessment { get; set; }
    
    public String selectedPaymentMethod { get; set; }
    public String pageName { get; set; }
    public Integer bookIndex { get; set; }
    
    
    @TestVisible private Contact communityUserContact { get; set; }
    public UtilitiesWrappers.ContactWrapper guestContact { get; set; }
    
    public List<Memorial_Book__c> memorialBooks {
        get {
            List<Memorial_Book__c> returnValue = [
                SELECT Id, Name, Donation_Type__c, Hard_Copy__c, Honoree_Memorial_Names__c, Remembered_By__c, Fiscal_Year__c, Assessment__c, Assessment__r.Assessed_Amount__c
                From Memorial_Book__c
                WHERE Account_Family__c = :this.communityUserContact.AccountId
            ];
            return returnValue;
        }
        set;
    }
    
    public list<SelectOption> DonationTypes {
        get {
            list<SelectOption> returnList = new list<SelectOption>();
            Schema.DescribeFieldResult fieldResult = Assessment__c.Donation_Type__c.getDescribe();
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            for (Schema.PicklistEntry pickListVal : ple) {
                if (!pickListVal.getValue().equalsIgnoreCase('Memorial Book')) {
                    returnList.add(new SelectOption(pickListVal.getLabel(), pickListVal.getValue()));
                }
            }
            return returnList;
        }
        set;
    }
    
    public List<SelectOption> getPaymentOptions() {
        
        List<selectOption> options = new List<selectOption>();
        
        options.add(new selectOption('', '-- None --'));
        options.add(new selectOption('CC', 'Credit Card'));
        options.add(new selectOption('ACH', 'ACH'));
        
        return options;
    }
    
    public list<SelectOption> memorialDonationTypes {
        get {
            list<SelectOption> returnList = new list<SelectOption>();
            Schema.DescribeFieldResult fieldResult = Memorial_Book__c.Donation_Type__c.getDescribe();
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            for (Schema.PicklistEntry pickListVal : ple) {
                returnList.add(new SelectOption(pickListVal.getLabel(), pickListVal.getValue()));
            }
            return returnList;
        }
        set;
    }
    public List<SelectOption> memorialFiscalYears {
        get {
            list<SelectOption> returnList = new list<SelectOption>();
            Schema.DescribeFieldResult fieldResult = Memorial_Book__c.Fiscal_Year__c.getDescribe();
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            for (Schema.PicklistEntry pickListVal : ple) {
                returnList.add(new SelectOption(pickListVal.getLabel(), pickListVal.getValue()));
            }
            return returnList;
        }
        set;
    }
    public String memorialDonationDesignationId {
        get {
            List<Designation__c> designations = [SELECT ID FROM Designation__c WHERE Name = :MEM_DONATION_DESIGNATION_NAME];
            if (designations.size() > 0) {
                return designations.get(0).Id;
            }
            return null;
        }
        set;
    }
    public String memorialPostageDesignation {
        get {
            List<Designation__c> designations = [SELECT Id FROM Designation__c WHERE Name = 'Postage'];
            if (designations.size() > 0) {
                return designations[0].id;
            }
            return null;
        }
    }
    public Decimal TotalDonationAmount {
        get {
            Decimal returnAmount = 0;
            if (donationWrappers != null && donationWrappers.size() > 0) {
                for (UtilitiesWrappers.DonationWrapper curWrap : donationWrappers) {
                    if (curWrap.Amount != null) {
                        returnAmount += curWrap.Amount;
                    }
                }
            }
            
            return returnAmount;
        }
    }
    
    public String selectedDonationType { get; set; }
    public String PSTHPFselectedDonationType { get; set; }
    
    Public Boolean pageErrors {
        get {
            return ApexPages.hasMessages();
        }
    }
    
    public CongrComm_DonationsController() {
        
        pageName = ApexPages.currentPage().getUrl().substringAfter('apex/').split('\\?')[0];
        System.debug('Page Name: ' + pageName);
        
        fundOptions = new List<SelectOption>();
        assessment = new Assessment__c();
        
        if (UserInfo.getUserType() == 'Guest') {
            this.communityUserContact = new Contact();
        } else {
            this.communityUserContact = UtilitiesUsers.GetContactForCommunityUser(UserInfo.getUserId());
        }
        
        fundOptions = generateFundOptions();
        PSTHPFfundOptions = generatePSTHPFFundOptions();
        includeHardCopyCost = false;
        displayContactInfo = false;
        this.hasDonationsEntered = false;
        
        this.donationWrappers = new List<UtilitiesWrappers.DonationWrapper>();
        this.guestContact = new UtilitiesWrappers.ContactWrapper();
    }
    
    public PageReference addAnotherDonation() {
        
        if (this.selectedFund == null || this.selectedFund == '' || this.amount == 0) {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Make sure a Fund is selected and you have entered an amount greater than 0.');
            ApexPages.addMessage(myMsg);
            return null;
        }

        if ( this.amount < 18 ) {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Minimum donation amount = $18');
            ApexPages.addMessage(myMsg);
            return null;
        }
        
        this.hasDonationsEntered = true;
        
        UtilitiesWrappers.DonationWrapper wrapper = new UtilitiesWrappers.DonationWrapper();
        wrapper.Fund = this.selectedFund;
        wrapper.FundName = [SELECT Id,Name FROM Designation__c WHERE Id = :this.selectedFund].Name;
        wrapper.Amount = this.amount;
        wrapper.HonoreeMemorialName = this.honoreeName;
        wrapper.Listing = this.listing;
        wrapper.AcknowledgementText = this.sendAcknowledgementTo;
        wrapper.DonationType = this.selectedDonationType;
        
        this.donationWrappers.add(wrapper);
        clearDonationFields();
        return null;
    }
    
    public PageReference removeFund() {
        
        System.debug(fundSelectedToRemove);
        this.donationWrappers.remove(fundSelectedToRemove);
        if(this.donationWrappers.size() == 0) this.hasDonationsEntered = false;
        return null;
    }
    public PageReference next() {
        
        this.displayContactInfo = true;
        
        
        return null;
    }
    
    @TestVisible private void clearDonationFields() {
        this.selectedFund = '';
        this.amount = 0;
        this.honoreeName = '';
        this.listing = '';
        this.sendAcknowledgementTo = '';
        this.selectedDonationType = '';
    }
    
    public PageReference copyBook() {
        System.debug(this.bookIndex);
        Memorial_Book__c curBook = this.memorialBooks[this.bookIndex];
        selectedDonationType = curBook.Donation_Type__c;
        honoreeName = curBook.Honoree_Memorial_Names__c;
        listing = curBook.Remembered_By__c;
        
        return null;
    }
    
    public PageReference makeMemorialDonationAction() {
        
        List<Assessment__c> listOfAssessments = new List<Assessment__c>();
        
        if (this.Amount == null) {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Amount must have a value of 0 or greater');
            ApexPages.addMessage(myMsg);
            return null;
        }
        
        if (selectedPaymentMethod == null || String.isBlank(selectedPaymentMethod)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please select a payment method'));
            return null;
        }
        
        Assessment__c donationAssessment = new Assessment__c();
        donationAssessment.Assessed_Amount__c = this.Amount;
        donationAssessment.Account__c = this.communityUserContact.AccountId;
        donationAssessment.Designation__c = memorialDonationDesignationId;
        donationAssessment.Assessment_Date__c = Date.today();
        donationAssessment.Honoree_Memorial_Name__c = honoreeName;
        donationAssessment.Listing__c = listing;
        donationAssessment.Send_Acknowledgement_To__c = listing;
        donationAssessment.I_want_a_hard_copy_to_be_mailed__c = includeHardCopyCost;
        donationAssessment.Donation_Type__c = 'Memorial Book';
        
        donationAssessment.From_Website__c = true;
        donationAssessment.Contact__c = communityUserContact.Id;
        
        listOfAssessments.add(donationAssessment);
        Assessment__c shippingAssessment = new Assessment__c();
        if (includeHardCopyCost) {
            shippingAssessment.Assessed_Amount__c = HARD_COPY_COST;
            shippingAssessment.Account__c = this.communityUserContact.AccountId;
            shippingAssessment.Designation__c = memorialPostageDesignation;
            shippingAssessment.Assessment_Date__c = Date.today();
            shippingAssessment.Contact__c = communityUserContact.Id;
            listOfAssessments.add(shippingAssessment);
        }
        
        try {
            insert listOfAssessments;
            
            Memorial_Book__c memorialBook = new Memorial_Book__c();
            memorialBook.Honoree_Memorial_Names__c = honoreeName;
//            memorialBook.Donation_Type__c = selectedDonationType;
            memorialBook.Hard_Copy__c = includeHardCopyCost;
            memorialBook.Remembered_By__c = listing;
            memorialBook.Account_Family__c = this.communityUserContact.AccountId;
            memorialBook.Family_ID__c = this.communityUserContact.Account.Family_ID__c;
            memorialBook.Assessment__c = donationAssessment.Id;
            if (shippingAssessment != NULL && shippingAssessment.Id != NULL) {
                memorialBook.Hard_Copy_Assessment__c = shippingAssessment.Id;
            }

//            memorialBook.Fiscal_Year__c = fiscalYear;
            insert memorialBook;
        
        } catch (Exception e) {
            System.debug(e.getMessage());
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage());
            ApexPages.addMessage(myMsg);
            return null;
        }
        
        Payment_Adjustment__c payAdj = createPaymentAdjustment(listOfAssessments, this.Amount);
        Payment_Adjustment__c reQueriedPayment = [SELECT Id, Name, (SELECT From_Website__c,Incomplete_Payment__c FROM Scheduled_Payment_Bridges__r) FROM Payment_Adjustment__c WHERE Id = :payAdj.Id];
        
        for (Payment_Adjustment_Allocation__c curAlloc : reQueriedPayment.Scheduled_Payment_Bridges__r) {
            curAlloc.From_Website__c = true;
            curAlloc.Incomplete_Payment__c = true;
        }
        
        try {
            update reQueriedPayment.Scheduled_Payment_Bridges__r;
        } catch (QueryException qe) {
            system.debug(qe.getMessage());
            return null;
        }
        
        if (pageName.contains('Guest') || UserInfo.getUserType() == 'Guest') {
            PageReference pr = Page.CongrComm_NMIPaymentProcessor;
            pr.getParameters().put('paId', reQueriedPayment.Id);
//            pr.getParameters().put('cId', this.communityUserContact.Id);
            pr.setRedirect(true);
            return pr;
        } else {
            PageReference pr = Page.CongrComm_ManagePaymentVaults;
            pr.getParameters().put('paId', reQueriedPayment.Id);
            pr.getParameters().put('method', this.selectedPaymentMethod);
            pr.setRedirect(true);
            return pr;
        }
    }
    
    public PageReference goBackToDonationEntry() {
        this.displayContactInfo = false;
        this.hasDonationsEntered = true;
        return null;
    }
    
    public PageReference makeDonationAction() {

        if(!this.hasDonationsEntered){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Please click "Add a Donation" before clicking "Make a Payment". You need to add at least one donation to make a payment.');
            ApexPages.addMessage(myMsg);
            return null;
        }
        
        if (this.selectedPaymentMethod == null && !(pageName.contains('Guest') || UserInfo.getUserType() == 'Guest')) {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Please select a method of payment.');
            ApexPages.addMessage(myMsg);
            return null;
        }
        
        Decimal totalPaymentAmount = 0.0;
        if (UserInfo.getUserType() == 'Guest') {
            this.communityUserContact = getContactForAssessment();
        } else {
            this.communityUserContact = UtilitiesUsers.GetContactForCommunityUser(UserInfo.getUserId());
        }

        if (UserInfo.getUserType() == 'Guest' && (String.isBlank(this.guestContact.LastName) || String.isBlank(this.guestContact.Email)) ) {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Last name and email required');
            ApexPages.addMessage(myMsg);
            return null;
        }
        
        List<Assessment__c> assessments = getAssessmentsFromDonationWrapper(this.communityUserContact);
        
        for (Assessment__c curAssessment : assessments) {
            totalPaymentAmount = totalPaymentAmount + curAssessment.Assessed_Amount__c;
        }
        
        try {
            insert assessments;
            System.debug(assessments[0].id);
        } catch (Exception e) {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage());
            ApexPages.addMessage(myMsg);
            UtilitiesErrors.PrintErrorDetails(e);
            return null;
        }
        
        Payment_Adjustment__c payAdj = createPaymentAdjustment(assessments, totalPaymentAmount);
        Payment_Adjustment__c reQueriedPayment = [SELEcT Id,Name, (SELECT From_Website__c,Incomplete_Payment__c FROM Scheduled_Payment_Bridges__r) FROM Payment_Adjustment__c WHERE Id = :payAdj.Id];
        
        for (Payment_Adjustment_Allocation__c curAlloc : reQueriedPayment.Scheduled_Payment_Bridges__r) {
            curAlloc.From_Website__c = true;
            curAlloc.Incomplete_Payment__c = true;
        }
        
        try {
            update reQueriedPayment.Scheduled_Payment_Bridges__r;
        } catch (QueryException qe) {
            system.debug(qe.getMessage());
            return null;
        }
        
        System.debug('pageName');
        System.debug(pageName);
        System.debug(UserInfo.getUserType());
        if (pageName.contains('Guest') || UserInfo.getUserType() == 'Guest') {
            PageReference pr = Page.CongrComm_NMIPaymentProcessor;
            pr.getParameters().put('paId', reQueriedPayment.Id);
            pr.getParameters().put('cId', this.communityUserContact.Id);
            pr.getParameters().put('autofill','true');
            pr.setRedirect(true);
            return pr;
        } else {
            PageReference pr = Page.CongrComm_ManagePaymentVaults;
            pr.getParameters().put('paId', reQueriedPayment.Id);
            pr.getParameters().put('method', this.selectedPaymentMethod);
            pr.setRedirect(true);
            return pr;
        }
    
    }
    
    private List<Assessment__c> getAssessmentsFromDonationWrapper(Contact existingContact) {
        
        List<Assessment__c> assessments = new List<Assessment__c>();
        for (UtilitiesWrappers.DonationWrapper wrapper : this.donationWrappers) {
            if (wrapper.Amount == null || wrapper.Amount == 0) {
                continue;
            }
            Assessment__c ase = new Assessment__c();
            ase.Assessed_Amount__c = wrapper.Amount;
            ase.Account__c = this.communityUserContact.AccountId;
            ase.Designation__c = wrapper.Fund;
            ase.Assessment_Date__c = Date.today();
            ase.Honoree_Memorial_Name__c = wrapper.HonoreeMemorialName;
            ase.Listing__c = wrapper.Listing;
            ase.From_Website__c = true;
            ase.Contact__c = communityUserContact.Id;
            ase.Send_Acknowledgement_To__c = wrapper.AcknowledgementText;
            ase.Donation_Type__c = wrapper.DonationType;
            ase.Contact__c = this.communityUserContact.Id;
            ase.RecordTypeId = UtilitiesSObject.getRecordTypeId('Assessment', Assessment__c.SObjectType);
            assessments.add(ase);
        }
        
        return assessments;
    }

    @TestVisible private Id getAccountForAssessment(Contact existingUser) {
        if (existingUser != null) {
            return existingUser.AccountId;
        } else if (UserInfo.getUserType().contains('Guest')) {
            return Important_Accounts__c.GetAll().values()[0].Account_ID__c;
        } else {
            return this.communityUserContact.AccountId;
        }
    }
    @TestVisible private Contact getContactForAssessment() {
        
        Contact existingContact = findExistingContact(this.guestContact?.email);
        if (existingContact != null) {
            return existingContact;
        } else {
            Contact newContact = new Contact();
            newContact.AccountId = Important_Accounts__c.getAll().values()[0].Account_ID__c;
            newContact.FirstName = guestContact?.FirstName;
            newContact.LastName = guestContact?.LastName;
            newContact.Email = guestContact?.Email;
            newContact.MailingStreet = guestContact?.street;
            newContact.MailingCity = guestContact?.city;
            newContact.MailingState = guestContact?.state;
            newContact.MailingPostalCode = guestContact?.zip;
            insert newContact;
            return newContact;
        }
    }
    
    @TestVisible private Contact findExistingContact(String email) {
        try {
            return [SELECT Id,AccountId FROM Contact WHERE Email = :email limit 1];
        } catch (QueryException qe) {
            System.debug('Existing Contact Not Found');
            return null;
        }
    }
    
    @testvisible private Payment_Adjustment__c createPaymentAdjustment(Assessment__c assessment) {
        
        Payment_Adjustment__c newPayment = new Payment_Adjustment__c();
        
        newPayment.Household__c = this.communityUserContact.AccountId;
        newPayment.Amount__c = this.Amount ;
        newPayment.Type__c = 'Credit Card';
        newPayment.From_Website__c = true;
        newPayment.Incomplete_Payment__c = true;
        if (this.includeHardCopyCost) {
            newPayment.Amount__c = this.Amount + HARD_COPY_COST;
        }
        
        try {
            insert newPayment;
        } catch (DmlException de) {
            system.debug(de.getMessage());
            return null;
        }
        
        list<Scheduled_Payment__c> scheduledPayments = getRelatedSchedulePayments(assessment);
        FundsDisbursementController fundsDisbursementController = new FundsDisbursementController();
        fundsDisbursementController.DisburseFundsToAllocations(assessment.Assessed_Amount__c.setScale(2), scheduledPayments, newPayment, 'Payment');
        
        return newPayment;
    }
    
    @testvisible private Payment_Adjustment__c createPaymentAdjustment(List<Assessment__c> assessmentList, Decimal totalPaymentAmount) {
        
        if (assessmentList.size() == 0) {
            return null;
        }
        
        System.debug('Printing Assessment List');
        System.debug(assessmentList);
        
        Payment_Adjustment__c newPayment = new Payment_Adjustment__c();
        
        newPayment.Household__c = assessmentList[0].Account__c;
        newPayment.Amount__c = totalPaymentAmount ;
        newPayment.Type__c = 'Credit Card';
        newPayment.From_Website__c = true;
        newPayment.Incomplete_Payment__c = true;
        if (this.includeHardCopyCost) {
            newPayment.Amount__c = totalPaymentAmount + HARD_COPY_COST;
        }
        
        try {
            insert newPayment;
        } catch (DmlException de) {
            system.debug(de.getMessage());
            UtilitiesErrors.PrintErrorDetails(de);
            return null;
        }
        
        list<Scheduled_Payment__c> scheduledPayments = getRelatedSchedulePayments(assessmentList);
        FundsDisbursementController fundsDisbursementController = new FundsDisbursementController();
        fundsDisbursementController.DisburseFundsToAllocations(newPayment.Amount__c.setScale(2), scheduledPayments, newPayment, 'Payment');
        
        return newPayment;
    }
    
    @TestVisible private list<Scheduled_Payment__c> getRelatedSchedulePayments(Assessment__c assessment) {
        
        try {
            list<Scheduled_Payment__c> returnList = [SELECT Id,Remaining_Balance__c,Assessment__c,Assessment__r.Remaining_Balance__c FROM Scheduled_Payment__c WHERE Assessment__c = :assessment.Id];
            return returnList;
        } catch (QueryException qe) {
            system.debug(qe.getMessage());
            return null;
        }
    }
    
    @TestVisible private list<Scheduled_Payment__c> getRelatedSchedulePayments(List<Assessment__c> assessments) {
        List<Id> idList = new List<Id>();
        for (Assessment__c assessment : assessments) {
            idList.add(assessment.Id);
        }
        System.debug('Printing Assessment IDs');
        System.debug(idList);
        try {
            list<Scheduled_Payment__c> returnList = [SELECT Id,Remaining_Balance__c,Assessment__c,Assessment__r.Remaining_Balance__c FROM Scheduled_Payment__c WHERE Assessment__c IN :idList];
            System.debug('Scheduled Payments: ' + returnList);
            return returnList;
        } catch (QueryException qe) {
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
        
        List<Designation__c> listOfDesignation = new List<Designation__c>();
        
        //Prayer Book
        if (pageName.equalsIgnoreCase(DONATION_PAGE) || pageName.equalsIgnoreCase(DONATION_GUEST_PAGE)) {
            listOfDesignation = [Select Id, Name, Display_Fund_Values_on_Portal__c from Designation__c where Display_Fund_on_Portal__c = true AND (NOT Name like '%Memorial Books%')];
        }
        
        if (pageName.equalsIgnoreCase(MEM_DONATION_PAGE)) {
            listOfDesignation = [Select Id, Name, Display_Fund_Values_on_Portal__c from Designation__c where Display_Fund_on_Portal__c = true AND Name like '%Memorial Books%'];
        }
        
        listToReturn.add(new SelectOption('', '--None--'));
        
        
        for (Designation__c dn : listOfDesignation) {
            
            List<String> values = new List<String>();
            
            if (dn.Display_Fund_Values_on_Portal__c != null && dn.Display_Fund_Values_on_Portal__c != '') {
                values = dn.Display_Fund_Values_on_Portal__c.split(';');
            }
            
            if (values.size() > 0) {
                for (String t : values) {
                    SelectOptionList.add(new SelectOptionWrapper(dn.Id, t));
                }
            } else {
                SelectOptionList.add(new SelectOptionWrapper(dn.Id, dn.Name));
            }
        
        }
        
        if (pageName.equalsIgnoreCase(MEM_DONATION_PAGE)) {
            selectedFund = SelectOptionList.get(0).value;
        }
        
        SelectOptionList.sort();
        
        for (SelectOptionWrapper sow : SelectOptionList) {
            listToReturn.add(sow.generateSelectOption());
        }
        return listToReturn;
    
    }
    
    private List<SelectOption> generatePSTHPFFundOptions() {
        List<SelectOption> listToReturn = new List<SelectOption>();
        List<SelectOptionWrapper> SelectOptionList = new List<SelectOptionWrapper>();
        
        List<Designation__c> listOfDesignation = [Select Id, Name, Display_Fund_Values_on_Portal__c from Designation__c where Display_Fund_on_Portal__c = true AND Id = 'a021G00000oBl9A'];
        
        if (listOfDesignation.size() > 0) {
            PSTHPFselectedDonationType = listOfDesignation[0].Id;
        }
        
        for (Designation__c dn : listOfDesignation) {
            
            List<String> values = new List<String>();
            
            if (dn.Display_Fund_Values_on_Portal__c != null && dn.Display_Fund_Values_on_Portal__c != '') {
                values = dn.Display_Fund_Values_on_Portal__c.split(';');
            }
            
            if (values.size() > 0) {
                for (String t : values) {
                    SelectOptionList.add(new SelectOptionWrapper(dn.Id, t));
                }
            } else {
                SelectOptionList.add(new SelectOptionWrapper(dn.Id, dn.Name));
            }
        
        }
        SelectOptionList.sort();
        
        for (SelectOptionWrapper sow : SelectOptionList) {
            listToReturn.add(sow.generateSelectOption());
        }
        return listToReturn;
    
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