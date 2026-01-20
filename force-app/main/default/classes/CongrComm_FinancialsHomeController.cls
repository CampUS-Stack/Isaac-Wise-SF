public without sharing class CongrComm_FinancialsHomeController {

    public static String CURRENT_FISCAL_YEAR { get; set; }
    public static final Decimal FEE_CHARGE = 2.5;
    
    Public Contact theContact { get; set; }
    Public List<AssessmentsWrapper> wrappedAssessments { get; set; }
    Public List<AssessmentsWrapper> wrappedPriorAssessments { get; set; }
    Public List<AssessmentsWrapper> wrappedFutureAssessments { get; set; }
    Public List<AssessmentsWrapper> selectedAssessments { get; set; }
    Public List<Payment_Adjustment__c> paymentList { get; set; }
//    public Boolean includeCharge {get; set;}
    
    public String selectedPaymentMethod { get; set; }
    public String totalPaymentAmount { get; set; }
    public String feeAmount { get; set; }
    
    public Decimal totalPaymentAmountDec { get; set; }
    public Decimal feeAmountDec { get; set; }
    
    public List<SelectOption> getPaymentOptions() {
        
        List<selectOption> options = new List<selectOption>();
        
        options.add(new selectOption('CC', 'Credit Card'));
        options.add(new selectOption('ACH', 'ACH'));
        
        return options;
    }
    
    public Decimal calculatedTotal {
        get {
            System.debug('SELECTED ASSESSMENTS: ' + selectedAssessments.size());
            if (selectedAssessments == null) return 0;
            Decimal totalToReturn = 0;
            for (AssessmentsWrapper curWrapper : selectedAssessments) {
                if (curWrapper.paymentAmount != null)
                    totalToReturn += curWrapper.paymentAmount;
            }
            System.debug('Total to Return: ' + totalToReturn);
            return totalToReturn;
        }
        set;
    }
    
    public Decimal CurrentTotalRemainingBalance {
        get {
            Decimal returnVal = 0;
            if (wrappedAssessments == null || wrappedAssessments.size() == 0) {
                return returnVal;
            }
            
            for (AssessmentsWrapper curAssessWrapper : wrappedAssessments) {
                if (curAssessWrapper.theAssessment.Remaining_Balance__c != null) {
                    returnVal += curAssessWrapper.theAssessment.Remaining_Balance__c;
                }
            }
            
            return returnVal;
        }
        set;
    }
    public Decimal PriorTotalRemainingBalance {
        get {
            Decimal returnVal = 0;
            if (wrappedPriorAssessments == null || wrappedPriorAssessments.size() == 0) {
                return returnVal;
            }
            
            for (AssessmentsWrapper curAssessWrapper : wrappedPriorAssessments) {
                if (curAssessWrapper.theAssessment.Remaining_Balance__c != null) {
                    returnVal += curAssessWrapper.theAssessment.Remaining_Balance__c;
                }
            }
            
            return returnVal;
        }
        set;
    }
    public Decimal FutureTotalRemainingBalance {
        get {
            Decimal returnVal = 0;
            if (wrappedFutureAssessments == null || wrappedFutureAssessments.size() == 0) {
                return returnVal;
            }
            
            for (AssessmentsWrapper curAssessWrapper : wrappedFutureAssessments) {
                if (curAssessWrapper.theAssessment.Remaining_Balance__c != null) {
                    returnVal += curAssessWrapper.theAssessment.Remaining_Balance__c;
                }
            }
            
            return returnVal;
        }
        set;
    }
    
    
    Public Boolean hasSelectedAssessments { get; set; }
    
    public Boolean HasAssessments {
        get {
            if (wrappedAssessments == null || wrappedAssessments.size() == 0) {
                return false;
            }
            return true;
        }
    }
    
    public Boolean HasPriorAssessments {
        get {
            if (wrappedPriorAssessments == null || wrappedPriorAssessments.size() == 0) {
                return false;
            }
            return true;
        }
    }
    
    public Boolean HasFutureAssessments {
        get {
            if (wrappedFutureAssessments == null || wrappedFutureAssessments.size() == 0) {
                return false;
            }
            return true;
        }
    }
    
    public Boolean HasPayments {
        get {
            if (paymentList == null || paymentList.size() == 0) {
                return false;
            } else {
                return true;
            }
        }
    }
    
    public PageReference testReRender(){
        return ApexPages.currentPage();
    }
    
    public CongrComm_FinancialsHomeController() {
        
        Integer orgFiscalMonth = [SELECT FiscalYearStartMonth FROM Organization].FiscalYearStartMonth;
        system.debug('Fiscal Year Start Month: ' + orgFiscalMonth);
        Integer fiscalYear = System.Today().year();
        
        if (System.today().month() < orgFiscalMonth) {
            fiscalYear -= 1;
        }
        
        Date fiscalYearDate = Date.newInstance(fiscalYear, orgfiscalMonth, 1);
        Date fiscalYearEndDate = Date.newInstance(fiscalYear + 1, orgfiscalMonth - 1, 30);
        Date priorFiscalYearDate = Date.newInstance(fiscalYear - 1, orgfiscalMonth, 1);
        
        Date payQueryDate = Date.today();
        payQueryDate = payQueryDate.addMonths(-18);
        System.debug('payQueryDate: ' + payQueryDate);
        
        Date billQueryDate = Date.today();
        billQueryDate = billQueryDate.addMonths(-24);
        System.debug('billQueryDate: ' + billQueryDate);
        
        /// Use User Utilities to get contact, if special SOQL fields are needed, pass those in.
        theContact = UtilitiesUsers.GetContactForCommunityUser(UserInfo.getUserId(), 'Id, AccountId, Account.Name, FirstName, LastName');
        
        // Get the Id for the Assessment record type
        /// use SObject utilities to get record type. This function keeps previously queried record type cached and pulls from those first
        /// if lots of areas are using record type queries, this will help to reduce overall soql queries.
        String assessmentRTypeId = UtilitiesSObject.getRecordTypeId('Assessment', Assessment__c.SObjectType);
        
        // Get the assessments, create list of wrappers
        this.wrappedAssessments = getCurrentAssessmentWrappers(fiscalYearDate, assessmentRTypeId, fiscalYearEndDate);
        set<Id> assessmentIds = getAssessmentIdsFromWrapperList(wrappedAssessments);
        this.wrappedPriorAssessments = getPriorAssessmentWrappers(fiscalYearDate, assessmentRTypeId, fiscalYearDate, assessmentIds);
        assessmentIds.addAll(getAssessmentIdsFromWrapperList(wrappedPriorAssessments));
        this.wrappedFutureAssessments = getFutureAssessmentWrappers(fiscalYearEndDate, assessmentRTypeId, assessmentIds);
        this.selectedPaymentMethod = 'CC';
        
        /// Get Payment List
        this.paymentList = getPayments(payQueryDate);
        CURRENT_FISCAL_YEAR = CongrComm_FairShareController.getOrgCurrentFiscalYear();
    }
    
    
    
    public PageReference submitPayment() {
        
        system.debug('Printing Payment Information');
        system.debug(this.totalPaymentAmount);
        system.debug(this.feeAmount);
        system.debug(this.selectedAssessments);
        Boolean hasErrors = runPaymentAmountEntryValidation(this.selectedAssessments);
        if (hasErrors) {
            return null;
        }
        
        //added method to calculate fee and total
        calculateFeeAndTotal(this.selectedAssessments);
        
        Payment_Adjustment__c newPayment = createPayment();
        
        for (AssessmentsWrapper curAssessWrap : this.selectedAssessments) {
            if (curAssessWrap.paymentAmount != null && curAssessWrap.paymentAmount > 0) {
                list<Scheduled_Payment__c> schedPayments = getRelatedSchedulePayments(new list<AssessmentsWrapper>{
                    curAssessWrap
                });
                FundsDisbursementController fundsDisbursementController = new FundsDisbursementController();
                fundsDisbursementController.DisburseFundsToAllocations(curAssessWrap.paymentAmount, schedPayments, newPayment, 'Payment');
            }
        }
        
        Payment_Adjustment__c newPaymentQueried = [SELECT Name, (SELECT ID,Incomplete_Payment__c,From_Website__c FROM Scheduled_Payment_Bridges__r) from Payment_Adjustment__c WHERE Id = :newPayment.Id];
        updatePaymentAllocations(newPaymentQueried.Scheduled_Payment_Bridges__r);
        
        PageReference pr = Page.CongrComm_ManagePaymentVaults;
        pr.getParameters().put('paId', newPaymentQueried.Id);
        pr.getParameters().put('method', selectedPaymentMethod);
        pr.setRedirect(true);
        return pr;
    }
    
    
    public PageReference makePayment() {
        selectedAssessments = new List<AssessmentsWrapper>();
        for (AssessmentsWrapper wa : wrappedAssessments) {
            selectedAssessments.add(wa);
        }
        for (AssessmentsWrapper wa : wrappedPriorAssessments) {
            selectedAssessments.add(wa);
        }
        /*for (AssessmentsWrapper wa : wrappedFutureAssessments) {
            selectedAssessments.add(wa);
        }*/
        
        if (selectedAssessments.size() > 0) {
            hasSelectedAssessments = true;
            selectedAssessments.sort();
        } else {
            hasSelectedAssessments = false;
        }
        PageReference pageRef = new PageReference('/apex/CongrComm_FinancialsPayment');
        pageRef.setRedirect(false);
        return pageRef;
    
    }
    
    @TestVisible private void updatePaymentAllocations(list<Payment_Adjustment_Allocation__c> allocations) {
        
        if (allocations != null) {
            for (Payment_Adjustment_Allocation__c curBridge : allocations) {
                curBridge.Incomplete_Payment__c = true;
                curBridge.From_Website__c = true;
            }
            try {
                update allocations;
            } catch (DmlException de) {
                system.debug(de.getMessage());
            }
        }
    }
    
    
    @TestVisible private Payment_Adjustment__c createPayment() {
        
        Payment_Adjustment__c newPayment = new Payment_Adjustment__c();

//        newPayment.Amount__c = Decimal.valueOf(this.totalPaymentAmount).setScale(2) + Decimal.valueOf(this.feeAmount).setScale(2);
        newPayment.Amount__c = totalPaymentAmountDec + feeAmountDec;
        
        newPayment.Online_Fee__c = feeAmountDec.setScale(2);
        newPayment.Household__c = theContact.AccountId;
        newPayment.Type__c = this.selectedPaymentMethod == 'ACH' ? 'ACH' : 'Credit Card';
        newPayment.From_Website__c = true;
        newPayment.Incomplete_Payment__c = true;
        newPayment.RecordTypeId = UtilitiesSObject.getRecordTypeId('Payment', Payment_Adjustment__c.SObjectType);
        
        try {
            insert newPayment;
            return newPayment;
        } catch (DmlException de) {
            system.debug(de.getMessage());
            return null;
        }
    }
    
    
    /**
     * Method to calculate fee and total
     *
     * @param assessmentsWrappers
     */
    private void calculateFeeAndTotal(list<AssessmentsWrapper> assessmentsWrappers) {
        
        Decimal totalFee = 0.0;
        Decimal totalPayWithoutFee = 0.0;
//        Fee_Designation_Setting__c fds = UtilitiesCustomSetting.GetInstance().getFeeDesignationsSetting();
        
        for (AssessmentsWrapper curWrapper : assessmentsWrappers) {
            Decimal curFee = 0.0;
            String designationId = UtilitiesCustomSetting.GetInstance().getDesignationWithFees(curWrapper.theAssessment.Designation__r.Name);
            if (designationId != NULL && designationId != '' && designationId == curWrapper.theAssessment.Designation__c && selectedPaymentMethod == 'CC') {
                if (FEE_CHARGE > 0) {
                    curFee = curWrapper.paymentAmount * (FEE_CHARGE / 100);
                }
            }
//            if (curWrapper.theAssessment.Designation__r.Should_Charge_Fee__c) {
//                if (curWrapper.theAssessment.Designation__r.Fee_Setting_Override__c) {
//                    if (curWrapper.theAssessment.Designation__r.Fee__c > 0) {
//                        curFee = curWrapper.paymentAmount * curWrapper.theAssessment.Designation__r.Fee__c / 100;
//                    }
//                } else {
//                    if (FEE_CHARGE > 0) {
//                        curFee = curWrapper.paymentAmount * (FEE_CHARGE / 100);
//                    }
//                }
//            }
            totalFee += curFee;
            totalPayWithoutFee += curWrapper.paymentAmount;
        }
        
        this.totalPaymentAmountDec = totalPayWithoutFee;
        this.feeAmountDec = totalFee.setScale(2);
    
    }
    
    
    @TestVisible private Boolean runPaymentAmountEntryValidation(list<AssessmentsWrapper> assessmentsWrappers) {
        
        Decimal amountBeingPaid = Decimal.valueOf(this.totalPaymentAmount);
        for (AssessmentsWrapper curWrapper : assessmentsWrappers) {
            if (curWrapper.paymentAmount < 0) {
                ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, 'You cannot enter a negative value.');
                ApexPages.addMessage(msg);
                return true;
            }
            if (curWrapper.paymentAmount > 0) {
                if (curWrapper.paymentAmount > curWrapper.theAssessment.Remaining_Balance__c) {
                    ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, 'You only owe $' + curWrapper.theAssessment.Remaining_Balance__c + ' for ' + curWrapper.theAssessment.Designation__r.Designation_Description__c + '. Please don\'t enter more than the amount owned');
                    ApexPages.addMessage(msg);
                    return true;
                }
            }
        }
        
        
        return false;
    }
    @TestVisible private list<Scheduled_Payment__c> getRelatedSchedulePayments(list<AssessmentsWrapper> assessmentsWrappers) {
        
        try {
            set<Id> assessmentIds = new set<Id>();
            for (AssessmentsWrapper curWrap : assessmentsWrappers) {
                if (String.isNotBlank(curWrap.theAssessment.Id)) {
                    assessmentIds.add(curWrap.theAssessment.Id);
                }
            }
            list<Scheduled_Payment__c> returnList = [SELECT Id,Remaining_Balance__c,Assessment__c,Assessment__r.Remaining_Balance__c FROM Scheduled_Payment__c WHERE Assessment__c IN :assessmentIds];
            return returnList;
        } catch (QueryException qe) {
            system.debug(qe.getMessage());
            return null;
        }
    }
    
    
    public PageReference paymentHistory() {
        PageReference pageRef = new PageReference('/apex/CongrComm_FinancialsPayHistory');
        return pageRef;
    }
    
    public PageReference billingHistory() {
        PageReference pageRef = new PageReference('/CongrComm_FinancialsBillHistory');
        return pageRef;
    }
    
    Public PageReference paymentCancel() {
        PageReference pageRef = new PageReference('/CongrComm_FinancialsHome');
        return pageRef;
    }
    
    
    /// ---------------------------- Private Helper Methods --------------------------------- ///
    //// TODO - This section can be done using dynamic SOQL in a much cleaner way.
    
    
    @TestVisible private list<AssessmentsWrapper> getCurrentAssessmentWrappers(Date fiscalYearDate, String assessmentRTypeId, Date currentFiscalYearEndDate) {
        
        try {
            list<AssessmentsWrapper> returnList = new list<AssessmentsWrapper>();
            list<Assessment__c> theAssessmentList = [
                SELECT Id, Designation__c, Designation__r.Name, Assessed_Amount__c, Remaining_Balance__c,Assessment_Date__c,
                    Description__c, Is_Tax_Deductible__c,Designation__r.Designation_Description__c,
                    Designation__r.Fee_Setting_Override__c, Designation__r.Fee__c, Designation__r.Should_Charge_Fee__c, (SELECT Id, Expected_Amount__c, Remaining_Balance__c, Date__c, Is_Currently_Due__c FROM Scheduled_Payments__r)
                FROM Assessment__c
                WHERE Account__c = :theContact.AccountId
                AND RecordTypeId = :assessmentRTypeId
                AND Assessment_Date__c >= :fiscalYearDate
                AND Assessment_Date__c <= :currentFiscalYearEndDate
                AND Remaining_Balance__c > 0
                ORDER BY Assessment_Date__c ASC
            ];
            
            Integer index = 0;
            System.debug('about to create current wrapped assessments');
            for (Assessment__c a : theAssessmentList) {
                returnList.add(new AssessmentsWrapper(a, index));
                index++;
            }
            return returnList;
        
        } catch (QueryException qe) {
            system.debug(qe.getMessage());
            return null;
        }
    }
    
    @TestVisible private list<AssessmentsWrapper> getPriorAssessmentWrappers(Date priorFiscalYearDate, String assessmentRTypeId, Date currentFiscalYearStartDate, set<Id> alreadyFoundAssessmentIds) {
        
        try {
            list<AssessmentsWrapper> returnList = new list<AssessmentsWrapper>();
            list<Assessment__c> theAssessmentList = [
                SELECT Id, Designation__c, Designation__r.Name, Assessed_Amount__c, Remaining_Balance__c,Assessment_Date__c,
                    Description__c, Is_Tax_Deductible__c,Designation__r.Designation_Description__c,
                    Designation__r.Fee_Setting_Override__c, Designation__r.Fee__c, Designation__r.Should_Charge_Fee__c, (SELECT Id, Expected_Amount__c, Remaining_Balance__c, Date__c, Is_Currently_Due__c FROM Scheduled_Payments__r)
                FROM Assessment__c
                WHERE Account__c = :theContact.AccountId
                AND RecordTypeId = :assessmentRTypeId
                AND Assessment_Date__c <= :priorFiscalYearDate
                AND ID NOT IN :alreadyFoundAssessmentIds
                AND Remaining_Balance__c > 0
                ORDER BY Assessment_Date__c ASC
            ];
            
            
            Integer index = 0;
            System.debug('about to create prior wrapped assessments');
            for (Assessment__c a : theAssessmentList) {
                returnList.add(new AssessmentsWrapper(a, index));
                index++;
            }
            
            return returnList;
        
        } catch (QueryException qe) {
            system.debug(qe.getMessage());
            return null;
        }
    }
    
    @TestVisible private list<AssessmentsWrapper> getFutureAssessmentWrappers(Date fiscalYearEndDate, String assessmentRTypeId, set<Id> alreadyFoundAssessmentIds) {
        
        try {
            list<AssessmentsWrapper> returnList = new list<AssessmentsWrapper>();
            list<Assessment__c> theAssessmentList = [
                SELECT Id, Designation__c, Designation__r.Name, Assessed_Amount__c, Remaining_Balance__c,Assessment_Date__c,
                    Description__c, Is_Tax_Deductible__c,Designation__r.Designation_Description__c,
                    Designation__r.Fee_Setting_Override__c, Designation__r.Fee__c, Designation__r.Should_Charge_Fee__c, (SELECT Id, Expected_Amount__c, Remaining_Balance__c, Date__c, Is_Currently_Due__c FROM Scheduled_Payments__r)
                FROM Assessment__c
                WHERE Account__c = :theContact.AccountId
                AND RecordTypeId = :assessmentRTypeId
                AND Assessment_Date__c >= :fiscalYearEndDate
                AND Assessment_Date__c < :Date.newInstance(Date.today().year() + 6, 12, 31)
                AND ID NOT IN :alreadyFoundAssessmentIds
                AND Remaining_Balance__c > 0
                ORDER BY Assessment_Date__c ASC
            ];
            
            
            Integer index = 0;
            System.debug('about to create prior wrapped assessments');
            for (Assessment__c a : theAssessmentList) {
                returnList.add(new AssessmentsWrapper(a, index));
                index++;
            }
            
            return returnList;
        
        } catch (QueryException qe) {
            system.debug(qe.getMessage());
            return null;
        }
    }
    
    @TestVisible private list<Payment_Adjustment__c> getPayments(Date payQueryDate) {
        try {
            
            list<Payment_Adjustment__c> returnList = [
                SELECT Id, Check_Date__c, Amount__c, Reason__c
                FROM Payment_Adjustment__c
                WHERE Household__c = :theContact.AccountId
                AND Check_Date__c > :payQueryDate
                ORDER BY Check_Date__c DESC
                LIMIT 5
            ];
            return returnList;
        } catch (QueryException qe) {
            system.debug(qe.getMessage());
            return null;
        }
    }
    
    @TestVisible private set<Id> getAssessmentIdsFromWrapperList(list<AssessmentsWrapper> wrappers) {
        
        set<Id> returnSet = new set<Id>();
        for (AssessmentsWrapper curWrap : wrappers) {
            if (curWrap.theAssessment != null && String.isNotBlank(curWrap.theAssessment.Id)) {
                returnSet.add(curWrap.theAssessment.Id);
            }
        }
        
        return returnSet;
    }
    
    
    //// -----------------------  Wrapper Classes -------------------------------------------- ////
    
    public class AssessmentsWrapper implements Comparable {
        
        Public Boolean isSelected { get; set; }
        Public Integer index { get; set; }
        Public Assessment__c theAssessment { get; set; }
        Public Decimal paymentAmount { get; set; }
        Public Decimal feeDecimal { get; set; }
        public List<SchedulePaymentWrapper> listOfSchedulePaymentWrappers { get; set; }
        
        public AssessmentsWrapper(Assessment__c theAssessment, Integer index) {
            this.isSelected = false;
            this.index = index;
            this.theAssessment = theAssessment;
            
            this.feeDecimal = 0.0;
            
            String designationId = UtilitiesCustomSetting.GetInstance().getDesignationWithFees(theAssessment.Designation__r.Name);
            if (designationId != NULL && designationId != '' && designationId == theAssessment.Designation__c) {
                if (FEE_CHARGE > 0) {
                    this.feeDecimal = FEE_CHARGE;
                }
            }
            
            listOfSchedulePaymentWrappers = new List<SchedulePaymentWrapper>();
            
            if (theAssessment.Scheduled_Payments__r != null && theAssessment.Scheduled_Payments__r.size() > 0) {
                for (Scheduled_Payment__c sp : theAssessment.Scheduled_Payments__r) {
                    listOfSchedulePaymentWrappers.add(new SchedulePaymentWrapper(sp));
                }
                listOfSchedulePaymentWrappers.sort();
            }
        }
        
        public Integer compareTo(Object ObjToCompare) {
            
            Date inDate = ((AssessmentsWrapper) ObjToCompare).theAssessment.Assessment_Date__c;
            
            if (theAssessment.Assessment_Date__c > inDate) {
                return 1;
            } else {
                return -1;
            }
        }
    
    }
    
    public class SchedulePaymentWrapper implements Comparable {
        
        public Scheduled_Payment__c scheduledPayment { get; set; }
        //public Integer order { get; set; }
        
        public SchedulePaymentWrapper(Scheduled_Payment__c schPayment) {
            this.scheduledPayment = schPayment;
        }
        
        public Integer compareTo(Object compareTo) {
            SchedulePaymentWrapper compareToSp = (SchedulePaymentWrapper) compareTo;
            if (scheduledPayment.Date__c == compareToSp.scheduledPayment.Date__c) return 0;
            if (scheduledPayment.Date__c > compareToSp.scheduledPayment.Date__c) return 1;
            return -1;
        }
    }
    
    Public class BillWrapper {
        
        Public String designation { get; set; }
        Public String description { get; set; }
        Public Date billDate { get; set; }
        Public Decimal assessment { get; set; }
        Public Decimal adjustment { get; set; }
        Public Decimal paid { get; set; }
        Public Assessment__c theAssessment { get; set; }
        
        Public BillWrapper(Assessment__c theAssessment) {
            this.designation = theAssessment.Designation__r.Name;
            this.description = theAssessment.Description__c;
            this.billDate = theAssessment.Assessment_Date__c;
            this.assessment = theAssessment.Assessed_Amount__c;
            this.adjustment = theAssessment.Amount_Adjusted__c;
            this.paid = theAssessment.Amount_Paid__c;
            this.theAssessment = theAssessment;
        }
    
    }
}