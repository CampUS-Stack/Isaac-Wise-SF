/**
 * Created by Chris Home Desktop on 10/10/2017.
 */

public with sharing class PaymentPagesController {

    private static final String PAYMENT_SOQL_FIELDS = 'Id,Name,Amount__c,Household__r.Name,Status__c,RecordType.Name,Type__c,Batch__r.Deposit_ID__c, Batch_Date__c ';
    private static final String ASSESSMENT_SOQL_FIELDS = 'Id,Name,Assessed_Amount__c,Account__r.Name,Status__c,Assessment_Date__c,Designation__r.Name ';

    public list<PaymentAndAdjustmentWrapper> unSummarizedPaymentAdjustments {get; set;}
    public list<PaymentAndAdjustmentWrapper> summarizedPaymentAdjustments {get; set;}
    public list<UtilitiesWrappers.AssessmentWrapper> unSummarizedAssessments {get; set;}
    public list<UtilitiesWrappers.AssessmentWrapper> summarizedAssessments {get; set;}

    public String SelectedDepositId {get; set;}

    //Filter input for Assessments
    public String FilledDesignation {get; set;}
    public String FilledStartDate {get; set;}
    public String FilledEndDate {get; set;}

    public Payment_Adjustment__c DummyPA {get; set;}

    /// Sorting Variables
    public String paymentSelectedField {get; set;}
    public String paymentSelectedSortOrder {get; set;}
    public String assessmentSelectedField {get; set;}
    public String assessmentSelectedSortOrder {get; set;}

    public Decimal UnSummarizedAssessmentTotal {
        get{
            if(unSummarizedAssessments == null || unSummarizedAssessments.size() == 0){
                return 0;
            }

            Decimal returnDec = 0;

            for(UtilitiesWrappers.AssessmentWrapper curAssess : unSummarizedAssessments){
                if(curAssess != null && curAssess.Assessment != null && curAssess.Assessment.Assessed_Amount__c != null && curAssess.Assessment.Assessed_Amount__c > 0 && curAssess.isSelected){
                    returnDec += curAssess.Assessment.Assessed_Amount__c;
                }
            }
            return returnDec;
        }
    }
    public Decimal UnSummarizedTotal {
        get{
            if(unSummarizedPaymentAdjustments == null || unSummarizedPaymentAdjustments.size() == 0){
                return 0;
            }

            Decimal returnDec = 0;

            for(PaymentAndAdjustmentWrapper curPA : unSummarizedPaymentAdjustments){
                if(curPA != null && curPA.PaymentAdjustment != null && curPA.PaymentAdjustment.Amount__c != null && curPA.isSelected){
                    returnDec += curPA.PaymentAdjustment.Amount__c;
                }
            }
            return returnDec;
        }
    }
    public Decimal SummarizedAssessmentTotal {
        get{
            if(summarizedAssessments == null || summarizedAssessments.size() == 0){
                return 0;
            }

            Decimal returnDec = 0;

            for(UtilitiesWrappers.AssessmentWrapper curAssess : summarizedAssessments){
                if(curAssess != null && curAssess.Assessment != null && curAssess.Assessment.Assessed_Amount__c != null && curAssess.Assessment.Assessed_Amount__c > 0 && curAssess.isSelected){
                    returnDec += curAssess.Assessment.Assessed_Amount__c;
                }
            }
            return returnDec;
        }
    }
    public Decimal SummarizedTotal {
        get{
            if(summarizedPaymentAdjustments == null || summarizedPaymentAdjustments.size() == 0){
                return 0;
            }

            Decimal returnDec = 0;

            for(PaymentAndAdjustmentWrapper curPA : summarizedPaymentAdjustments){
                if(curPA != null && curPA.PaymentAdjustment != null && curPA.PaymentAdjustment.Amount__c != null && curPA.PaymentAdjustment.Amount__c > 0 && curPA.isSelected){
                    returnDec += curPA.PaymentAdjustment.Amount__c;
                }
            }
            return returnDec;
        }
    }


    public PaymentPagesController(){

        FilledDesignation = '';
        if(String.isBlank(FilledStartDate)) FilledStartDate = '';
        if (String.isBlank(FilledEndDate)) FilledEndDate = '';

        this.SelectedDepositId = '';
        this.DummyPA = new Payment_Adjustment__c();

        this.paymentSelectedSortOrder = 'ASC';
        this.paymentSelectedField = 'Household__r.Name';
        this.assessmentSelectedField = 'Assessment_Date__c';
        this.assessmentSelectedSortOrder = 'ASC';

        UpdatePageLists();
    }

    /**
     *  @Author: Chris Gibson
     *  @Date: 10.10.2017
     *
     *  @Purpose: This method handles selection of all payments. If all payments are selected
     *                  they are all un selected.
     */
    public PageReference SelectAllUnSummarizedPayments(){

        if(this.unSummarizedPaymentAdjustments == null || this.unSummarizedPaymentAdjustments.size() == 0){
            return null;
        }

        performListSelectAll(this.unSummarizedPaymentAdjustments);

        return null;
    }
    /**
     *  @Author: Chris Gibson
     *  @Date: 10.10.2017
     *
     *  @Purpose: This method handles selection of all payments. If all payments are selected
     *                  they are all un selected.
     */
    public PageReference SelectAllUnSummarizedAssessments(){

        if(this.unSummarizedAssessments == null || this.unSummarizedAssessments.size() == 0){
            return null;
        }

        performListSelectAll(this.unSummarizedAssessments);

        return null;
    }

    /**
     *  @Author: Chris Gibson
     *  @Date: 10.10.2017
     *
     *  @Purpose: This method handles selection of all payments. If all payments are selected
     *                  they are all un selected.
     */
    public PageReference SelectAllSummarizedPayments(){

        if(this.summarizedPaymentAdjustments == null || this.summarizedPaymentAdjustments.size() == 0){
            return null;
        }

        performListSelectAll(this.summarizedPaymentAdjustments);

        return null;
    }

    public void UpdatePageLists(){

        this.unSummarizedPaymentAdjustments = createPaymentAndAdjustmentWrappers(getPaymentsAndAdjustments(ConstantsFinancials.UN_SUMMARIZED_STATUS));
        this.summarizedPaymentAdjustments = createPaymentAndAdjustmentWrappers(getPaymentsAndAdjustments(ConstantsFinancials.SUMMARIZED_STATUS));
        this.unSummarizedAssessments = createAssessmentWrappers(getAssessments(ConstantsFinancials.UN_SUMMARIZED_STATUS));
        this.summarizedAssessments = createAssessmentWrappers(getAssessments(ConstantsFinancials.SUMMARIZED_STATUS));

    }

    public list<SelectOption> GetDepositIds(){

        try{
            list<SelectOption> returnList = new list<SelectOption>();
            returnList.add(new SelectOption('','--NONE--'));
            list<Batch__c> batches = [SELECT Id,Deposit_Id__c FROM Batch__c WHERE Status__c = 'Un-Summarized'];

            for(Batch__c curBatch : batches){
                if(!String.isEmpty(curBatch.Deposit_Id__c)){
                    returnList.add(new SelectOption(curBatch.Deposit_Id__c,curBatch.Deposit_Id__c));
                }
            }
            return returnList;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return new list<SelectOption>();
        }
    }

    /**
     *  @Author: Chris Gibson
     *  @Date: 07.02.2017
     *
     *  @Purpose: This method changes the sort order based on what the page currently has and also provides an opportunity for the
     *              selected field variable to be set.
     *
     *  @PostCondition:
     */
    public void changePaymentSortColumn(){

        if(this.paymentSelectedSortOrder == null){
            this.paymentSelectedSortOrder = 'ASC';
        }
        else if(this.paymentSelectedSortOrder == 'ASC'){
            this.paymentSelectedSortOrder = 'DESC';
        }
        else{
            this.paymentSelectedSortOrder = 'ASC';
        }

        UpdatePageLists();
    }

    /**
     *  @Author: Chris Gibson
     *  @Date: 07.02.2017
     *
     *  @Purpose: This method changes the sort order based on what the page currently has and also provides an opportunity for the
     *              selected field variable to be set.
     *
     *  @PostCondition:
     */
    public void changeAssessmentSortColumn(){

        if(this.assessmentSelectedSortOrder == null){
            this.assessmentSelectedSortOrder = 'ASC';
        }
        else if(this.assessmentSelectedSortOrder == 'ASC'){
            this.assessmentSelectedSortOrder = 'DESC';
        }
        else{
            this.assessmentSelectedSortOrder = 'ASC';
        }

        UpdatePageLists();
    }

    @TestVisible private void performListSelectAll(list<UtilitiesWrappers.AssessmentWrapper> wrapppers){

        Boolean allSelected = true;
        for(UtilitiesWrappers.AssessmentWrapper curWrap : wrapppers){
            if(!curWrap.isSelected){
                curWrap.isSelected = true;
                allSelected = false;
            }
        }

        if(allSelected){
            for(UtilitiesWrappers.AssessmentWrapper curWrap : wrapppers){
                curWrap.isSelected = false;
            }
        }

    }

    @TestVisible private void performListSelectAll(list<PaymentAndAdjustmentWrapper> wrapppers){

        Boolean allSelected = true;
        for(PaymentAndAdjustmentWrapper curWrap : wrapppers){
            if(!curWrap.isSelected){
                curWrap.isSelected = true;
                allSelected = false;
            }
        }

        if(allSelected){
            for(PaymentAndAdjustmentWrapper curWrap : wrapppers){
                curWrap.isSelected = false;
            }
        }

    }

    public PageReference SummarizeAssessments(){

        list<Assessment__c> updateSet = new list<Assessment__c>();
        for(UtilitiesWrappers.AssessmentWrapper curAssess : this.unSummarizedAssessments){
            if(curAssess.isSelected){
                curAssess.Assessment.Status__c = ConstantsFinancials.UN_TRANSFERED_STATUS;
                updateSet.add(curAssess.Assessment);
            }
        }

        update updateSet;
        updatePageLists();

        return null;
    }

    public PageReference SummarizePayments(){

        list<Payment_Adjustment__c> updateSet = new list<Payment_Adjustment__c>();
        set<Id> batchIds = new set<Id>();
        for(PaymentAndAdjustmentWrapper curWrap : this.unSummarizedPaymentAdjustments){
            if(curWrap.isSelected){
                curWrap.PaymentAdjustment.Status__c = ConstantsFinancials.UN_TRANSFERED_STATUS;
                updateSet.add(curWrap.PaymentAdjustment);
                batchIds.add(curWrap.PaymentAdjustment.Batch__c);
            }
        }

        try{
            update updateSet;
            list<Batch__c> batches = [SELECT Id FROM Batch__c WHERE Id = :batchIds];
            update batches;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
        }
        catch(DmlException de){
            system.debug(de.getMessage());
        }

        updatePageLists();
        return null;
    }

    public PageReference PreparePaymentsForExport(){

        list<Payment_Adjustment__c> updateSet = new list<Payment_Adjustment__c>();
        for(PaymentAndAdjustmentWrapper curWrap : this.summarizedPaymentAdjustments){
            if(curWrap.isSelected){
                curWrap.PaymentAdjustment.Status__c = ConstantsFinancials.UN_TRANSFERED_STATUS;
                updateSet.add(curWrap.PaymentAdjustment);
            }
        }

        update updateSet;
        updatePageLists();

        return null;
    }

    @TestVisible private list<Payment_Adjustment__c> getPaymentsAndAdjustments(String status){

        String soql = 'SELECT ' + PAYMENT_SOQL_FIELDS + '  FROM Payment_Adjustment__c WHERE Status__c = \'' + status  + '\' ';

        if(!String.isEmpty(this.SelectedDepositId)){
            soql += ' AND Batch__r.Deposit_ID__c = \'' + this.SelectedDepositId + '\'';
        }
        if(!String.isEmpty(this.DummyPA.Batch__c)){
            soql += ' AND Batch__c = \'' + this.DummyPA.Batch__c + '\'';
        }

        Date startDate = stringToDate(FilledStartDate);
        Date endDate = stringToDate(FilledEndDate);

        if(startDate != null){
            soql += ' AND Batch_Date__c >= :startDate';
        }
        if(endDate != null){
            soql += ' AND Batch_Date__c <= :endDate';
        }

        soql += ' AND Amount__c != 0';
        soql += ' AND Incomplete_Payment__c = false ';

        soql += ' ORDER BY Batch_Date__c DESC NULLS LAST, ' + this.paymentSelectedField + ' ' + this.paymentSelectedSortOrder + ' NULLS LAST';

        soql += ' limit 500';

        try{
            system.debug(soql);
            list<Payment_Adjustment__c> returnList = Database.query(soql);
            return returnList;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return null;
        }
    }

    @TestVisible private list<Assessment__c> getAssessments(String status) {

        Date startDate = stringToDate(FilledStartDate);
        Date endDate = stringToDate(FilledEndDate);

        String soql = 'SELECT ' + ASSESSMENT_SOQL_FIELDS + '  FROM Assessment__c WHERE Status__c = \'' + status  + '\' ';

        if(!String.isEmpty(this.FilledDesignation)){
            soql += ' AND Designation__r.Name LIKE ' + '\'%' + FilledDesignation + '%\' ';
        }

        if(startDate != null) {
            soql += ' AND Assessment_Date__c >= :startDate ';
        }
        if(endDate != null) {
            soql += ' AND Assessment_Date__c <= : endDate';
        }

        soql += ' AND Assessed_Amount__c != 0 ';

        soql += ' ORDER BY ' + this.assessmentSelectedField + ' ' + this.assessmentSelectedSortOrder + ' NULLS LAST';

        soql += ' limit 500';

        try{
            system.debug(soql);
            list<Assessment__c> returnList = Database.query(soql);
            return returnList;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return null;
        }
    }

    @TestVisible private list<PaymentAndAdjustmentWrapper> createPaymentAndAdjustmentWrappers(list<Payment_Adjustment__c> paymentAdjustmentsToConvert){

        if(paymentAdjustmentsToConvert == null || paymentAdjustmentsToConvert.size() == 0){
            return new list<PaymentAndAdjustmentWrapper>();
        }
        list<PaymentAndAdjustmentWrapper> returnList = new list<PaymentAndAdjustmentWrapper>();
        for(Payment_Adjustment__c curPA : paymentAdjustmentsToConvert){
            returnList.add(new PaymentAndAdjustmentWrapper(curPA));
        }
        return returnList;
    }
    @TestVisible private list<UtilitiesWrappers.AssessmentWrapper> createAssessmentWrappers(list<Assessment__c> assessmentsToConvert){

        if(assessmentsToConvert == null || assessmentsToConvert.size() == 0){
            return new list<UtilitiesWrappers.AssessmentWrapper>();
        }

        list<UtilitiesWrappers.AssessmentWrapper> returnList = new list<UtilitiesWrappers.AssessmentWrapper>();
        for(Assessment__c curA : assessmentsToConvert){
            UtilitiesWrappers.AssessmentWrapper wrap = new UtilitiesWrappers.AssessmentWrapper();
            wrap.assessment = curA;
            returnList.add(wrap);
        }
        return returnList;
    }

    @TestVisible public PageReference applyFilter() {
        //System.debug('Applying Filter');
        //System.debug('St Date= ' + FilledStartDate);
        //System.debug(stringToDate(FilledStartDate));
        //System.debug('End Date= ' + FilledEndDate);
        UpdatePageLists();
        return null;
    }

    @TestVisible private Date stringToDate(String stringDate) {
        Date returnDate;
        if(!String.isEmpty(stringDate)) {
            try{
                returnDate =  date.parse(stringDate);
            } catch(Exception e) {
                System.debug(e);
            }
        }
        return returnDate;
    }


    /**
     *  @Author: Chris Gibson
     *  @Date: 10.10.2017
     *
     *  @Purpose: Wrapper class to capture selection logic for PaymentAdjustment object in SummarizePayment page and accompanying controller
     */
    public class PaymentAndAdjustmentWrapper{

        public Boolean isSelected {get; set;}
        public Payment_Adjustment__c PaymentAdjustment {get; set;}
        public PaymentAndAdjustmentWrapper(Payment_Adjustment__c paymentAdjustmentToSet){
            this.PaymentAdjustment = paymentAdjustmentToSet;
            this.isSelected = false;
        }
    }

    /**
     *  @Author: Chris Gibson
     *  @Date: 10.10.2017
     *
     *  @Purpose: Wrapper class to capture selection logic for PaymentAdjustment object in SummarizePayment page and accompanying controller
     */
    public class AssessmentWrapper{

        public Boolean isSelected {get; set;}
        public Assessment__c Assessment {get; set;}
        public AssessmentWrapper(Assessment__c assessmentToSet){
            this.Assessment = assessmentToSet;
            this.isSelected = false;
        }
    }
}