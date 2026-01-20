/**
 * Created by Chris Home Desktop on 10/19/2017.
 */

public with sharing class PaymentWizardController {

    public static String ACCOUNT_SOQL_FIELDS = 'Id,Name,Current_Account_Balance__c';
    public static String ASSESSMENT_SOQL_FIELDS = 'Id,Name,Assessed_Amount__c,Amount_Paid__c,Amount_Adjusted__c,Designation__r.Name,Assessment_Date__c,Remaining_Balance__c,Description__c,Is_Credit_Assessment__c';
    public static String BATCH_SOQL_FIELDS = 'Id,Name,Default_Payment_Method__c,Deposit_ID__c,Batch_Date__c,Transaction_Type__c,Sum_of_Transaction__c';
    public static String SCHEDULED_PAYMENT_SOQL_FIELDS = 'Id,Name,Assessment__c,Remaining_Balance__c,Total_Payment_Amount__c,Expected_Amount__c,Assessment__r.Remaining_Balance__c,Assessment__r.Is_Credit_Assessment__c ';

    public static String PAYMENT_URL_PARAM = 'Payment';
    public static String WRITE_OFF_URL_PARAM = 'Write_Off';
    public static String ADJUSTMENT_URL_PARAM = 'Adjustment';
    public static String VOID_URL_PARAM = 'Void';
    public static String CREDIT_URL_PARAM = 'Credit';

    public Boolean DisplayCreditSearch {get; set;}
    public Boolean CheckValidationOverride {get; set;}

    public Account Household {get; set;}
    public Payment_Adjustment__c ThePA {get; set;}
    public String PaymentType {get; set;}

    public Contact DummyContact {get; set;}
    public Contact PaidByDummyContact {get; set;}

    public Integer toCount { get; set; }
    public String toDelete { get; set; }
    public list<Assessment__c> Assessments {get; set;}
    public list<UtilitiesWrappers.AssessmentWrapper> AssessmentWrappers {get; set;}
    public list<UtilitiesWrappers.CreditPaymentWrapper > CreditWrappers {get; set;}

    public UtilitiesWrappers.CreditPaymentWrapper  CurrentCreditWrapper{get; set;}

    public Integer CurrentCreditWrapperNumber{
        get{
            if(this.CreditWrappers == null || currentCreditWrapper == null){
                return 0;
            }

            Integer counter = 1;
            for(UtilitiesWrappers.CreditPaymentWrapper  credWrap : this.CreditWrappers){

                if(credWrap.assessment.Id == currentCreditWrapper.assessment.Id){
                    return counter;
                }

                counter++;
            }

            return 0;
        }
    }

    public Integer TotalCreditWrappers{
        get{
            if(this.CreditWrappers == null){
                return 0;
            }

            Integer counter = 0;
            for(UtilitiesWrappers.CreditPaymentWrapper curCreditWrapper : this.CreditWrappers){
                if(curCreditWrapper.isSelected){
                    counter ++;
                }
            }
            return counter;
        }
    }

    public String batchId {get; set;}
    public Batch__c batch {get; set;}
    @TestVisible ApexPages.StandardController stdController {get; set;}

    public String SuccessMessage {get; set;}

    public Decimal creditBalanceToApply{
        get{
            if(CreditWrappers == null){
                return 0.00;
            }

            Decimal returnAmt = 0.00;
            for(UtilitiesWrappers.CreditPaymentWrapper curWrap : CreditWrappers){
                if(curWrap.isSelected && curWrap.assessment != null && curWrap.assessment.Remaining_Balance__c != null)
                    returnAmt += curWrap.assessment.Remaining_Balance__c;
            }

            return returnAmt;
        }
    }

    public Decimal CurrentYearAccountBalance {get; set;}

    public PaymentWizardController(ApexPages.StandardController stdControllerToSet){

        toCount = 0;

        this.Assessments = new list<Assessment__c>();
        this.CreditWrappers = new list<UtilitiesWrappers.CreditPaymentWrapper>();
        this.DummyContact = new Contact();
        this.PaidByDummyContact = new Contact();
        this.DisplayCreditSearch = true;
        this.CheckValidationOverride = false;

        this.stdController = stdControllerToSet;
        this.batchId = stdControllerToSet.getId();
        this.batch = getBatch(this.batchId);
        this.PaymentType = this.batch.Transaction_Type__c;
        this.ThePA = createPaymentAdjustment(this.PaymentType);
        this.ThePA.Type__c = this.batch.Default_Payment_Method__c;
    }


    /**
    *  @author Chris Gibson
    *  @date 11.02.2017
    *
    *  @description This method creates the Payment object and then allocates the money
    */
    public PageReference SearchCreditAssessments(){

        try{
            String soql = 'SELECT ' + ASSESSMENT_SOQL_FIELDS + ' FROM Assessment__c WHERE Account__c = \'' + this.DummyContact.AccountId + '\' AND Remaining_Balance__c < 0  AND RecordTypeId = \'' + UtilitiesSObject.getRecordTypeId('Credit_Assessment',Assessment__c.SObjectType) + '\'';
            system.debug(soql);
            list<Assessment__c> theAssessments = Database.query(soql);
            this.CreditWrappers = UtilitiesWrappers.CreateCreditPaymentWrapper(theAssessments,SCHEDULED_PAYMENT_SOQL_FIELDS);
            return null;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return null;
        }
    }

    /** 
    *  @author Chris Gibson
    *  @date 11.02.2017
    *
    *  @description This method creates the Payment object and then allocates the money
    */
    public PageReference SearchAssessments(){

        try{
            String soql = 'SELECT ' + ASSESSMENT_SOQL_FIELDS + ' FROM Assessment__c WHERE Account__c = \'' + this.DummyContact.AccountId + '\' AND (RecordTypeId = \'' + UtilitiesSObject.getRecordTypeId('Assessment',Assessment__c.SObjectType) + '\' OR RecordTypeId = \'' + UtilitiesSObject.getRecordTypeId('Event_Assessment',Assessment__c.SObjectType) + '\')';
            system.debug(soql);
            if(this.batch.Transaction_Type__c == 'Adjustment'){
//                soql += ' AND Remaining_Balance__c >= 0 ';
            }
            else{
                soql += ' AND Remaining_Balance__c > 0 ';
            }
            if(this.batch.Transaction_Type__c == 'Posted Payment') {
                soql += 'ORDER BY   Assessment_Date__c ASC,CreatedDate DESC ,Assessed_Amount__c ASC NULLS LAST';
            }
            else{
                soql += 'ORDER BY  CreatedDate DESC,  Assessment_Date__c,Assessed_Amount__c DESC NULLS LAST';
            }

            this.Assessments = Database.query(soql);
            this.AssessmentWrappers = UtilitiesWrappers.CreateAssessmentWrappers(this.Assessments,SCHEDULED_PAYMENT_SOQL_FIELDS);
            setCurrentYearAccountBalance();
            return null;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return null;
        }
    }

    /**
    *  @author Chris Gibson
    *  @date 11.02.2017
    *
    *  @description This method is used to save the current session and clear out fields for the next household
    */
    public PageReference SaveAndContinue(){

        Boolean submissionResult;
        if(this.batch.Transaction_Type__c == 'Credit'){
            CurrentCreditWrapper.hasBeenProcessed = true;
            this.CurrentCreditWrapper.paymentAdjustment.Date_of_Action__c = batch.Batch_Date__c;
            submissionResult = ProcessPaymentSubmission(CurrentCreditWrapper.paymentAdjustment);
        }
        else{
            submissionResult = ProcessPaymentSubmission(this.ThePA);
        }

        if(!submissionResult){
            return null;
        }
        else{
            if(this.batch.Transaction_Type__c == 'Credit'){
                this.CurrentCreditWrapper = getNextCreditWrapper();
                if(this.CurrentCreditWrapper != null){
                    this.CurrentCreditWrapper.paymentAdjustment.Amount__c = this.CurrentCreditWrapper.assessment.Remaining_Balance__c;
                    this.CurrentCreditWrapper.paymentAdjustment.Source_Credit_Assessment__c = this.CurrentCreditWrapper.assessment.Id;
                    SearchAssessments();
                }
                else if(this.CurrentCreditWrapper == null){

                    PageReference pr = Page.CreditWizard;
                    pr.getParameters().put('id',this.batchId);
                    pr.setRedirect(true);
                    return pr;
                }
            }

            if(this.batch.Transaction_Type__c != 'Credit' || CurrentCreditWrapper == null){
                this.DummyContact = new Contact();
                this.PaidByDummyContact = new Contact();
                this.Assessments = new list<Assessment__c>();
                this.AssessmentWrappers = new list<UtilitiesWrappers.AssessmentWrapper>();

            }
        }

        this.thePA = new Payment_Adjustment__c();
        this.ThePa.Type__c = this.batch.Default_Payment_Method__c;
        this.CheckValidationOverride = false;
        this.SuccessMessage = '';
        return null;
    }

    /**
    *  @author Chris Gibson
    *  @date 11.02.2017
    *
    *  @description This method saves the current data entered and then navigated the user to the batch record
    */
    public PageReference SaveAndExit(){

        Boolean submissionResult;
        if(this.batch.Transaction_Type__c == 'Credit'){
            CurrentCreditWrapper.hasBeenProcessed = true;
            submissionResult = ProcessPaymentSubmission(CurrentCreditWrapper.paymentAdjustment);
        }
        else{
            submissionResult = ProcessPaymentSubmission(this.ThePA);
        }

        if(!submissionResult){
            this.SuccessMessage = 'false';
            return null;
        }
        else{
            if(this.batch.Transaction_Type__c == 'Credit'){
                this.CurrentCreditWrapper = getNextCreditWrapper();
                this.CurrentCreditWrapper.paymentAdjustment.Amount__c = this.CurrentCreditWrapper.assessment.Remaining_Balance__c;
                this.CurrentCreditWrapper.paymentAdjustment.Source_Credit_Assessment__c = this.CurrentCreditWrapper.assessment.Id;
            }
        }

        if(this.batch.Transaction_Type__c == 'Credit' && this.CurrentCreditWrapperNumber != this.CreditWrappers.size()){
            this.SuccessMessage = 'false - need to allocate credit payments';
            SearchAssessments();
            return null;
        }
        else{
            this.SuccessMessage = 'true - exit';
            this.CheckValidationOverride = false;
            return null;
        }
    }

    /**
    *  @author Chris Gibson
    *  @date 11.02.2017
    *
    *  @description This method saves the current data entered and then navigates the user to the summarize payment page.
    */
    public PageReference SaveAndAdjust(){

        Boolean submissionResult;
        if(this.batch.Transaction_Type__c == 'Credit'){
            CurrentCreditWrapper.hasBeenProcessed = true;
            submissionResult = ProcessPaymentSubmission(CurrentCreditWrapper.paymentAdjustment);
        }
        else{
            submissionResult = ProcessPaymentSubmission(this.ThePA);
        }

        if(!submissionResult){
            this.SuccessMessage = 'false';
            return null;
        }
        else{
            if(this.batch.Transaction_Type__c == 'Credit'){
                this.CurrentCreditWrapper = getNextCreditWrapper();
                this.CurrentCreditWrapper.paymentAdjustment.Amount__c = this.CurrentCreditWrapper.assessment.Remaining_Balance__c;
                this.CurrentCreditWrapper.paymentAdjustment.Source_Credit_Assessment__c = this.CurrentCreditWrapper.assessment.Id;
            }
        }

        this.CheckValidationOverride = false;
        this.SuccessMessage = 'true - adjustment';
        Batch__c adjBatch = new Batch__c();
        adjBatch.Batch_Date__c = this.batch.Batch_Date__c;
        adjBatch.Deposit_ID__c = this.batch.Deposit_ID__c + 'ADJ';
        adjBatch.Transaction_Type__c = 'Adjustment';
        adjBatch.Status__c = 'Un-Summarized';
        insert adjBatch;

        PageReference pr = Page.PaymentWizard;
        pr.setRedirect(true);
        pr.getParameters().put('id',adjBatch.Id);
        return pr;
    }

    /**
    *  @author Chris Gibson
    *  @date 11.02.2017
    *
    *  @description This method saves the current data entered and then navigates the user to the summarize payment page.
    */
    public PageReference SaveAndSummarize(){

        Boolean submissionResult;
        if(this.batch.Transaction_Type__c == 'Credit'){
            CurrentCreditWrapper.hasBeenProcessed = true;
            submissionResult = ProcessPaymentSubmission(CurrentCreditWrapper.paymentAdjustment);
        }
        else{
            submissionResult = ProcessPaymentSubmission(this.ThePA);
        }

        if(!submissionResult){
            this.SuccessMessage = 'false';
            return null;
        }
        else{
            if(this.batch.Transaction_Type__c == 'Credit'){
                this.CurrentCreditWrapper = getNextCreditWrapper();
                this.CurrentCreditWrapper.paymentAdjustment.Amount__c = this.CurrentCreditWrapper.assessment.Remaining_Balance__c;
                this.CurrentCreditWrapper.paymentAdjustment.Source_Credit_Assessment__c = this.CurrentCreditWrapper.assessment.Id;
            }
        }

        if(this.batch.Transaction_Type__c == 'Credit' && this.CurrentCreditWrapperNumber != this.CreditWrappers.size()){
            this.SuccessMessage = 'false - need to allocate credit payments';
            SearchAssessments();
        }
        else{
            this.CheckValidationOverride = false;
            this.SuccessMessage = 'true - summarize';
        }

        return null;
    }

    /**
    *  @author Chris Gibson
    *  @date 11.02.2017
    *
    *  @description This method creates the Payment object and then allocates the funds to the various scheduled payments/assessments
    */
    public Boolean ProcessPaymentSubmission(Payment_Adjustment__c paymentAdjustment){

        Decimal paymentTotal = getPaymentTotal();
        this.batch.Sum_of_Transaction__c = 0;

        system.debug('Payment Total: ' + paymentTotal);

        Boolean passedValidation = runEntryFieldValidation(paymentTotal,paymentAdjustment);
        if(!passedValidation){
            return false;
        }

        list<UtilitiesWrappers.AssessmentWrapper> newWrappers = getWrappers(this.AssessmentWrappers,true);
        list<UtilitiesWrappers.AssessmentWrapper> existingWrappers = getWrappers(this.AssessmentWrappers,false);
        set<Id> existingWrapperAssessmentIds = getWrapperAssessmentIds(this.AssessmentWrappers);

        try{

            insertPaymentAdjustmentForSubmission(paymentAdjustment,paymentTotal);
            disburseFundsAcrossAllocation(paymentAdjustment,existingWrapperAssessmentIds,existingWrappers);
            disburseFundsAcrossAllocationForNewAssessments(paymentAdjustment,newWrappers);

            this.batch.Sum_of_Transaction__c += paymentTotal;
            update this.batch;
        }
        catch(DmlException de){
            UtilitiesErrors.PrintErrorDetails(de);
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.WARNING,'An unexpected error has occured. Your administrator has been notified.'));
            system.debug(de.getMessage());
            return false;
        }

        return true;
    }

    /**
    *  @author Chris Gibson
    *  @date 11.02.2017
    *
    *  @description This method directs a user to the summarize payments page
    */
    public PageReference GoBackToBatch(){
        PageReference pr = new PageReference('/' + this.batchId);
        pr.SetRedirect(true);
        return pr;
    }

    /**
    *  @author Chris Gibson
    *  @date 11.02.2017
    *
    *  @description This method directs a user to the summarize payments page
    */
    public PageReference GoToSummarizePayments(){
        // ToDo: Uncomment this method.
//        PageReference pr = Page.SummarizePayments;
//        pr.SetRedirect(true);
//        return pr;
        return null;
    }

    public PageReference ProcessAutoPay(){


        if(this.batch.Transaction_Type__c == 'Credit'){
            UtilitiesFinancials.ProcessAutoPay(this.CurrentCreditWrapper.paymentAdjustment,this.AssessmentWrappers);
        }
        else{
            UtilitiesFinancials.ProcessAutoPay(this.ThePA,this.AssessmentWrappers);
        }
        return null;
    }

    public void AddNewAssessment(){

        if(String.isEmpty(this.DummyContact.AccountId)){
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.WARNING,'You must select a Household before adding an assessment.'));
            return;
        }

        toCount++;

        UtilitiesWrappers.AssessmentWrapper wrapper = new UtilitiesWrappers.AssessmentWrapper();
        wrapper.assessment = new Assessment__c();
        wrapper.isNew = true;
        wrapper.uniqueIdentifier = toCount;
        this.Assessments.add(wrapper.assessment);
        this.AssessmentWrappers.add(wrapper);
    }

    /**
     * Added By Kritik : To remove Assessment from row 
     *
     * @return
     */
    public PageReference deleteAssessment() {

        System.debug(toDelete);

        for (Integer x = 0; x < AssessmentWrappers.size(); x++) {
            if (AssessmentWrappers.get(x).uniqueIdentifier == Integer.valueOf(toDelete)) {
                AssessmentWrappers.remove(x);
            }
        }


        return null;
    }

    public PageReference DisplayBatchProcessForCredit(){

        this.CurrentCreditWrapper = getNextCreditWrapper();

        if(this.CurrentCreditWrapper == null){
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.WARNING,'You must select a credit to apply.'));
            return null;
        }


        this.batch.Transaction_Type__c = 'Credit';
        this.CurrentCreditWrapper.paymentAdjustment.Amount__c = this.CurrentCreditWrapper.assessment.Remaining_Balance__c;
        this.CurrentCreditWrapper.paymentAdjustment.Source_Credit_Assessment__c = this.CurrentCreditWrapper.assessment.Id;
        this.CurrentCreditWrapper.paymentAdjustment.Date_of_Action__c = batch.Batch_Date__c;
        this.DisplayCreditSearch = false;
        SearchAssessments();
        return null;
    }


    public PageReference OverrideCheckValidation(){
        CheckValidationOverride = true;
        SuccessMessage = '';
        return null;
    }

    @TestVisible private void insertPaymentAdjustmentForSubmission(Payment_Adjustment__c paymentAdjustment, Decimal paymentTotal){

        paymentAdjustment.Amount__c = paymentTotal;
        paymentAdjustment.Household__c = this.DummyContact.AccountId;
        paymentAdjustment.Batch__c = this.batch.Id;
        paymentAdjustment.Paid_by_Household__c = this.PaidByDummyContact.AccountId;
        if(this.batch.Transaction_Type__c == 'Posted Payment'){
            paymentAdjustment.RecordTypeId = UtilitiesSObject.getRecordTypeId('Payment',Payment_Adjustment__c.SOBjectType);
        }
        else{
            paymentAdjustment.RecordTypeId = UtilitiesSObject.getRecordTypeId(this.batch.Transaction_Type__c,Payment_Adjustment__c.SOBjectType);
        }
        insert paymentAdjustment;

        if(this.batch.Transaction_Type__c == 'Credit'){

            Credit_Allocation__c cAlloc = new Credit_Allocation__c();
            cAlloc.Amount__c = paymentAdjustment.Amount__c;
            cAlloc.Assessment__c = paymentAdjustment.Source_Credit_Assessment__c;
            cAlloc.Payment_Adjustment__c = paymentAdjustment.Id;
            insert cAlloc;
        }
    }

    @TestVisible private UtilitiesWrappers.CreditPaymentWrapper  getNextCreditWrapper(){

        for(UtilitiesWrappers.CreditPaymentWrapper curWrap : this.CreditWrappers){
            if(!curWrap.hasBeenProcessed && curWrap.isSelected)
                return curWrap;
        }

        return null;
    }

    @TestVisible private void insertPaymentAdjustmentForCreditSubmission(){

        list<Payment_Adjustment__c> newPayments = new list<Payment_Adjustment__c>();
        for(UtilitiesWrappers.CreditPaymentWrapper curWrapper : this.CreditWrappers){
            Payment_Adjustment__c payAdj = new Payment_Adjustment__c();
            payAdj.Amount__c = curWrapper.assessment.Assessed_Amount__c;
//            payAdj.Payment_Date__c =
        }

//        this.ThePA.Amount__c = paymentTotal;
        this.ThePA.Household__c = this.DummyContact.AccountId;
        this.ThePA.Batch__c = this.batch.Id;
        this.ThePA.Paid_by_Household__c = this.PaidByDummyContact.AccountId;
        if(this.batch.Transaction_Type__c == 'Posted Payment'){
            this.ThePA.RecordTypeId = UtilitiesSObject.getRecordTypeId('Payment',Payment_Adjustment__c.SOBjectType);
        }
        else{
            this.ThePA.RecordTypeId = UtilitiesSObject.getRecordTypeId(this.batch.Transaction_Type__c,Payment_Adjustment__c.SOBjectType);
        }
        insert this.ThePA;


    }

    @TestVisible private Boolean runEntryFieldValidation(Decimal paymentTotal,Payment_Adjustment__c payAdj){

        if(paymentTotal <= 0 && (this.batch.Transaction_Type__c != 'Adjustment')){
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.WARNING,'The payment amount entered must be greater than 0.'));
            return false;
        }
        system.debug(paymentTotal);
        system.debug(payAdj.Amount__c);
        if( (this.batch.Transaction_Type__c != 'Credit' && paymentTotal != payAdj.Amount__c) || (this.batch.Transaction_Type__c == 'Credit' && paymentTotal != (payAdj.Amount__c * -1))){
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.WARNING,'Please make sure the remaining balance is $0.00.'));
            return false;
        }
        if(String.isEmpty(payAdj.Type__c) && this.batch.Transaction_Type__c == 'Payment'){
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.WARNING,'Please specify a type before continuing.'));
            return false;
        }
        Boolean hasErrors = runLineItemValidation(payAdj);
        hasErrors = runCheckNumberValidation();
        if(hasErrors){
            return false;
        }

        return true;
    }

    @TestVisible private Boolean runCheckNumberValidation(){

        if(String.isEmpty(this.ThePA.Check_Number__c) || this.CheckValidationOverride){
            return false;
        }

        try{
            list<Payment_Adjustment__c> payAdj = [SELECT Id FROM Payment_Adjustment__c WHERE Check_Number__c = :this.ThePA.Check_Number__c AND Household__c = :this.DummyContact.AccountId];
            if(payAdj.size() > 0){
                SuccessMessage = 'CheckNumberError';
                return true;
            }
            else{
                return false;
            }
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return false;
        }
    }

    @TestVisible private Boolean runLineItemValidation(Payment_Adjustment__c payAdj){

        Boolean returnBool = false;
        Decimal paymentAmount = 0.00;
        for(UtilitiesWrappers.AssessmentWrapper curWrapper : AssessmentWrappers){

            if(String.isEmpty(curWrapper.paymentAmount)){
                continue;
            }

            if(Decimal.valueOf(curWrapper.paymentAmount) > curWrapper.assessment.Remaining_Balance__c && this.batch.Transaction_Type__c != 'Adjustment'){
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.WARNING,'Please check ' + curWrapper.assessment.Designation__r.Name +'. The payment amount cannot exceed the remaining balance.'));
                returnBool = true;
            }
            paymentAmount += Decimal.valueOf(curWrapper.paymentAmount);
        }

        if(paymentAmount > payAdj.Amount__c){
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.WARNING,'You are attempting to pay more than the Current Check Amount.'));
//            clearWrapperPaymentAmounts(AssessmentWrappers);
            returnBool = true;
        }
        if(payAdj.Check_Date__c == null){
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.WARNING,'You must specify a check date.'));
//            clearWrapperPaymentAmounts(AssessmentWrappers);
            returnBool = true;
        }

        return returnBool;
    }

    @TestVisible private void clearWrapperPaymentAmounts(list<UtilitiesWrappers.AssessmentWrapper> assessmentWrappers){
        for(UtilitiesWrappers.AssessmentWrapper curWrap: assessmentWrappers){
            curWrap.paymentAmount = '0';
        }
    }

    @TestVisible private list<UtilitiesWrappers.AssessmentWrapper> getWrappers(list<UtilitiesWrappers.AssessmentWrapper> assessmentWrappers, Boolean isNew){

        list<UtilitiesWrappers.AssessmentWrapper> returnList = new list<UtilitiesWrappers.AssessmentWrapper>();
        for(UtilitiesWrappers.AssessmentWrapper curWrapper : assessmentWrappers){

            if(curWrapper.isNew == isNew){
                returnList.add(curWrapper);
            }
        }
        return returnList;
    }

    @TestVisible private void setCurrentYearAccountBalance(){
        try{
            Account acc = [SELECT Id,Current_Account_Balance__c FROM Account WHERE Id = :this.DummyContact.AccountId];
            this.CurrentYearAccountBalance = acc.Current_Account_Balance__c;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            this.CurrentYearAccountBalance = 0.00;
        }
    }

    @TestVisible private set<Id> getWrapperAssessmentIds(list<UtilitiesWrappers.AssessmentWrapper> assessmentWrappers){

        set<Id> returnSet = new set<Id>();
        for(UtilitiesWrappers.AssessmentWrapper curWrapper : assessmentWrappers){
            if(!String.isEmpty(curWrapper.assessment.Id)){
                returnSet.add(curWrapper.assessment.Id);
            }
        }
        return returnSet;
    }

    @TestVisible private Decimal getPaymentTotal(set<Id> assessmentIds,list<MapResponse> deserializedMap){
        Decimal paymentTotal = 0;
        for(MapResponse curResponse : deserializedMap){
            assessmentIds.add(curResponse.assessmentId);
            paymentTotal += curResponse.paymentAmount;
        }
        return paymentTotal;
    }

    @TestVisible private Decimal getPaymentTotal(){

        if(this.AssessmentWrappers == null){
            return 0.0;
        }

        Decimal returnNumber = 0;
        for(UtilitiesWrappers.AssessmentWrapper curWrapper : this.AssessmentWrappers){
            system.debug(curWrapper.paymentAmount);
            if(String.isEmpty(curWrapper.paymentAmount)){
                continue;
            }
            if(curWrapper.paymentAmount.contains('$') || curWrapper.paymentAmount.contains(' ') || curWrapper.paymentAmount.contains(',')){
                curWrapper.paymentAmount = curWrapper.paymentAmount.replace('$','');
                curWrapper.paymentAmount = curWrapper.paymentAmount.replaceAll(' ','');
                curWrapper.paymentAmount = curWrapper.paymentAmount.replaceAll(',','');
            }
            if(Decimal.valueOf(curWrapper.paymentAmount) > 0 || batch.Transaction_Type__c == 'Adjustment'){
                returnNumber += Decimal.valueOf(curWrapper.paymentAmount);
            }
        }
        return returnNumber;
    }

    @TestVisible private void disburseFundsAcrossAllocation(Payment_Adjustment__c payAdj, set<Id> assessmentIds,list<UtilitiesWrappers.AssessmentWrapper> assessmentsToDisburse){
        System.debug('ASSESSMENT IDS: ' + assessmentIds.sizE());
        map<Id,list<Scheduled_Payment__c>> scheduledPaymentsByAssessmentId = UtilitiesFinancials.MapSchedulePaymentsByAssessments(assessmentIds,SCHEDULED_PAYMENT_SOQL_FIELDS);
        system.debug(scheduledPaymentsByAssessmentId);
        for(Id curInvoiceId : scheduledPaymentsByAssessmentId.keySet()){
            System.debug('Scheduled Payment Assessment Id: ' + curInvoiceId + ' ' + scheduledPaymentsByAssessmentId.get(curInvoiceId));
        }

//        if(this.batch.Transaction_Type__c == 'Credit'){
//            doDispersalForCreditPayment();
//        }
//        else{
        for(UtilitiesWrappers.AssessmentWrapper curWrapper : assessmentsToDisburse){

            system.debug('Current Assessment: ' + curWrapper.assessment.Designation__r.Name);
            system.debug('Current Assessment Payment Amount: ' + curWrapper.paymentAmount);
            if(String.isEmpty(curWrapper.paymentAmount)){
                continue;
            }

            list<Scheduled_Payment__c> scheduledPaymentsForAssessment = scheduledPaymentsByAssessmentId.get(curWrapper.assessment.Id);
            System.debug('CUR WRAPPER ASSESSMENT ID: ' + curWrapper.assessment.Id);
            system.debug(scheduledPaymentsForAssessment);
            FundsDisbursementController disbursementController = new FundsDisbursementController();
            if(this.batch.Transaction_Type__c == 'Posted Payment'){
                disbursementController.DisburseFundsToAllocations(Decimal.valueOf(curWrapper.paymentAmount),scheduledPaymentsForAssessment,payAdj,'Payment');
            }
            else if(this.batch.Transaction_Type__c == 'Adjustment'){
                disbursementController.DisburseAdjustmentsToAllocations(Decimal.valueOf(curWrapper.paymentAmount),scheduledPaymentsForAssessment,payAdj,'Adjustment');
            }
            else{
                disbursementController.DisburseFundsToAllocations(Decimal.valueOf(curWrapper.paymentAmount),scheduledPaymentsForAssessment,payAdj,this.batch.Transaction_Type__c);
            }
//            }
        }
    }

    @TestVisible private void doDispersalForCreditPayment(){

        list<Payment_Adjustment__c> insertPaymentList = new list<Payment_Adjustment__c>();
        Decimal totalPaid = 0.00;
//
//        for(LineItemWrapper curAssessWrapper : assessmentsToDisburse){
//
//            for(CreditWrapper curCredWrap : this.CreditWrappers){
//
//                if(curAssessWrapper.paymentAmount < curCredWrap.assessment.Remaining_Balance__c){
//                    FundsDisbursementController disbursementController = new FundsDisbursementController();
//                    list<Scheduled_Payment__c> scheduledPaymentsForAssessment = scheduledPaymentsByAssessmentId.get(curWrapper.assessment.Id);
//                    Payment_Adjustment__c payAdj = createPaymentAdjustment(Decimal.valueOf(curAssessWrapper.paymentAmount),curCredWrap.);
//                    insertPaymentList.add(payAdj);
//                    totalPaid += curAssessWrapper.paymentAmount;
//                    disbursementController.DisburseFundsToAllocations(Decimal.valueOf(payAdj.Amount__c),scheduledPaymentsForAssessment,payAdj,'Payment');
//
//                }
//                else if(curAssessWrapper.paymentAmount == curCredWrap.assessment.Remaining_Balance__c){
//
//                }
//                else{
//                    paymentAmountRemaining
//                }
//            }
//        }
//

//        for(CreditWrapper curCredWrap : this.CreditWrappers){
//
//            if(paymentAmountRemaining <= 0){
//                break;
//            }
//
//            for(LineItemWrapper curAssessWrapper : assessmentsToDisburse){
//                FundsDisbursementController disbursementController = new FundsDisbursementController();
//                list<Scheduled_Payment__c> scheduledPaymentsForAssessment = scheduledPaymentsByAssessmentId.get(curWrapper.assessment.Id);
//                if(curCredWrap.assessment.Remaining_Balance__c >= paymentAmountRemaining){
//                    insertPaymentList.add(payAdj);
//                    disbursementController.DisburseFundsToAllocations(Decimal.valueOf(payAdj.Amount__c),scheduledPaymentsForAssessment,payAdj,'Payment');
//                    break;
//                }
//                else if(curCredWrap.assessment.Remaining_Balance__c < curAssessWrapper.paymentAmount){
//
//                }
//            }
//        }

    }

    @TestVisible private Payment_Adjustment__c createPaymentAdjustment(Decimal paymentAmountToApply, Id sourceCreditAssessment){

        Payment_Adjustment__c payAdj = new Payment_Adjustment__c();
        payAdj.Amount__c = paymentAmountToApply;
        payAdj.Type__c = 'Credit';
        payAdj.Date_of_Action__c = this.batch.Batch_Date__c;
        payAdj.Household__c = this.ThePA.Household__c;
        payAdj.Paid_by_Household__c = this.ThePA.Paid_by_Household__c;
        payAdj.Source_Credit_Assessment__c = sourceCreditAssessment;

        return payAdj;
    }

    @TestVisible private void disburseFundsAcrossCreditAllocation(set<Id> assessmentIds,list<UtilitiesWrappers.AssessmentWrapper> assessmentsToDisburse){

        map<Id,list<Scheduled_Payment__c>> scheduledPaymentsByAssessmentId = UtilitiesFinancials.MapSchedulePaymentsByAssessments(assessmentIds,SCHEDULED_PAYMENT_SOQL_FIELDS);

        system.debug(scheduledPaymentsByAssessmentId);

        for(UtilitiesWrappers.AssessmentWrapper curWrapper : assessmentsToDisburse){

            if(String.isEmpty(curWrapper.paymentAmount)){
                continue;
            }

            list<Scheduled_Payment__c> scheduledPaymentsForAssessment = scheduledPaymentsByAssessmentId.get(curWrapper.assessment.Id);
            FundsDisbursementController disbursementController = new FundsDisbursementController();
            if(this.batch.Transaction_Type__c == 'Posted Payment'){
                disbursementController.DisburseFundsToAllocations(Decimal.valueOf(curWrapper.paymentAmount),scheduledPaymentsForAssessment,this.ThePA,'Payment');
            }
            else{
                disbursementController.DisburseFundsToAllocations(Decimal.valueOf(curWrapper.paymentAmount),scheduledPaymentsForAssessment,this.ThePA,this.batch.Transaction_Type__c);
            }
        }
    }

    @TestVisible private void disburseFundsAcrossAllocationForNewAssessments(Payment_Adjustment__c payAdj, list<UtilitiesWrappers.AssessmentWrapper> assessmentsToDisburse){

        system.debug('Running disbursement for new assessments.');

        if(assessmentsToDisburse == null || assessmentsToDisburse.size() == 0){
            return;
        }

        system.debug('Number of Assessments being created:');
        system.debug(assessmentsToDisburse.size());

        list<Assessment__c> assessmentsToInsert = new list<Assessment__c>();

        for(UtilitiesWrappers.AssessmentWrapper curWrapper : assessmentsToDisburse){

            curWrapper.assessment.Account__c = this.DummyContact.AccountId;
            if(curWrapper.paymentAmount.contains('$')){
                curWrapper.paymentAmount = curWrapper.paymentAmount.replaceAll('$','');
            }
            curWrapper.assessment.Assessed_Amount__c = Decimal.valueOf(curWrapper.paymentAmount);
            curWrapper.assessment.Assessment_Date__c = this.batch.Batch_Date__c;
            system.debug(curWrapper.assessment.Designation__c);
            assessmentsToInsert.add(curWrapper.assessment);
        }

        insert assessmentsToInsert;
        map<Id,Assessment__c> assessMap = new map<Id,Assessment__c>(assessmentsToInsert);

        disburseFundsAcrossAllocation(payAdj,assessMap.keySet(),assessmentsToDisburse);
    }

    @TestVisible private Payment_Adjustment__c createPaymentAdjustment(Decimal paymentTotal){

        Payment_Adjustment__c thePayment = new Payment_Adjustment__c();
        thePayment.Amount__c = paymentTotal;
        thePayment.Household__c = this.DummyContact.AccountId;
        thePayment.Paid_by_Household__c = this.PaidByDummyContact.AccountId;
        thePayment.RecordTypeId = UtilitiesSObject.getRecordTypeId(this.PaymentType,Payment_Adjustment__c.SOBjectType);
        insert thePayment;
        return thePayment;
    }
//
//    @TestVisible private map<Id,list<Scheduled_Payment__c>> mapSchedulePaymentsByAssessments(set<Id> assessmentIds){
//
//        try{
//            map<Id,list<Scheduled_Payment__c>> returnMap = new map<Id,list<Scheduled_Payment__c>>();
//            list<Scheduled_Payment__c> scheduledPayments = [SELECT Id,Assessment__c,Remaining_Balance__c,Total_Payment_Amount__c,Expected_Amount__c,Assessment__r.Remaining_Balance__c,Assessment__r.Is_Credit_Assessment__c FROM Scheduled_Payment__c sp WHERE sp.Assessment__c in :assessmentIds];
//
//            for(Scheduled_Payment__c curSP : scheduledPayments){
//
//                if(returnMap.containsKey(curSP.Assessment__c)){
//                    returnMap.get(curSP.Assessment__c);
//                }
//                else{
//                    list<Scheduled_Payment__c> spList = new list<Scheduled_Payment__c>();
//                    spList.add(curSP);
//                    returnMap.put(curSP.Assessment__c,spList);
//                }
//            }
//
//            return returnMap;
//        }
//        catch(QueryException qe){
//            system.debug(qe.getMessage());
//            return null;
//        }
//    }

//    @TestVisible private list<UtilitiesWrappers.AssessmentWrapper> createLineItemWrappers(){
//
//        map<Id,Assessment__c> assessmentMap = new map<Id,Assessment__c>(this.Assessments);
//        list<Scheduled_Payment__c> scheduledPayments = UtilitiesFinancials.GetScheduledPayment(SCHEDULED_PAYMENT_SOQL_FIELDS,assessmentMap.keySet());
//
//        list<UtilitiesWrappers.AssessmentWrapper> returnList = new list<UtilitiesWrappers.AssessmentWrapper>();
//        for(Assessment__c curAssessment : this.Assessments){
//
//            UtilitiesWrappers.AssessmentWrapper wrapper = new UtilitiesWrappers.AssessmentWrapper();
//            wrapper.assessment = curAssessment;
//            wrapper.isNew = false;
//            list<Scheduled_Payment__c> sPayments = new list<Scheduled_Payment__c>();
//            for(Scheduled_Payment__c curSPayment : scheduledPayments){
//                if(curSPayment.Assessment__c == curAssessment.Id){
//                    sPayments.add(curSPayment);
//                }
//            }
//            wrapper.scheduledPayments = sPayments;
//            returnList.add(wrapper);
//        }
//
//        return returnList;
//    }
////
//    @TestVisible private list<UtilitiesWrappers.CreditPaymentWrapper> createCreditWrappers(list<Assessment__c> assessments){
//
//        map<Id,Assessment__c> assessmentMap = new map<Id,Assessment__c>(assessments);
//        list<Scheduled_Payment__c> scheduledPayments = UtilitiesFinancials.GetScheduledPayment(SCHEDULED_PAYMENT_SOQL_FIELDS,assessmentMap.keySet());
//
//        list<UtilitiesWrappers.CreditPaymentWrapper> returnList = new list<UtilitiesWrappers.CreditPaymentWrapper>();
//        for(Assessment__c curAssessment : assessments){
//
//            UtilitiesWrappers.CreditPaymentWrapper wrapper = new UtilitiesWrappers.CreditPaymentWrapper();
//            wrapper.assessment = curAssessment;
//            list<Scheduled_Payment__c> sPayments = new list<Scheduled_Payment__c>();
//            for(Scheduled_Payment__c curSPayment : scheduledPayments){
//                if(curSPayment.Assessment__c == curAssessment.Id){
//                    sPayments.add(curSPayment);
//                }
//            }
//            wrapper.scheduledPayments = sPayments;
//            returnList.add(wrapper);
//        }
//
//        return returnList;
//    }

    @TestVisible private Payment_Adjustment__c createPaymentAdjustment(String paymentType){

        Payment_Adjustment__c pa = new Payment_Adjustment__c();
        pa.Household__c = this.DummyContact.AccountId;
        pa.Paid_by_Household__c = this.PaidByDummyContact.AccountId;

        if(paymentType == PAYMENT_URL_PARAM){
            pa.RecordTypeId = UtilitiesSObject.getRecordTypeId(PAYMENT_URL_PARAM,Payment_Adjustment__c.SObjectType);
        }
        else if(paymentType == WRITE_OFF_URL_PARAM){
            pa.RecordTypeId = UtilitiesSObject.getRecordTypeId(WRITE_OFF_URL_PARAM,Payment_Adjustment__c.SObjectType);
        }
        else if(paymentType == ADJUSTMENT_URL_PARAM){
            pa.RecordTypeId = UtilitiesSObject.getRecordTypeId(ADJUSTMENT_URL_PARAM,Payment_Adjustment__c.SObjectType);
        }
        else if(paymentType == VOID_URL_PARAM){
            pa.RecordTypeId = UtilitiesSObject.getRecordTypeId(VOID_URL_PARAM,Payment_Adjustment__c.SObjectType);
        }
        else if(paymentType == CREDIT_URL_PARAM){
            pa.RecordTypeId = UtilitiesSObject.getRecordTypeId(CREDIT_URL_PARAM,Payment_Adjustment__c.SObjectType);
        }

        return pa;
    }

    @TestVisible private String getAccountId(){
        if(ApexPages.CurrentPage().getParameters().containsKey('Id')){
            return ApexPages.currentPage().getParameters().get('Id');
        }
        return '';
    }


    @TestVisible private String getPagePaymentType(){
        if(ApexPages.CurrentPage().getParameters().containsKey('type')){
            return ApexPages.currentPage().getParameters().get('type');
        }
        return '';
    }

    @TestVisible private Account getAccount(String accountId){
        try{
            String soql = 'SELECT ' + ACCOUNT_SOQL_FIELDS + ' FROM Account WHERE Id = :accountId';
            Account returnAcc = Database.query(soql);
            return returnAcc;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return null;
        }
    }

    @TestVisible private Batch__c getBatch(String batchId){
        try{
            String soql = 'SELECT ' + BATCH_SOQL_FIELDS + ' FROM Batch__c WHERE Id = :batchId';
            Batch__c returnBatch = Database.query(soql);
            return returnBatch;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return null;
        }
    }


    @TestVisible private list<Assessment__c> getAssessments(String accountId){

        try{
            String soql = 'SELECT ' + ASSESSMENT_SOQL_FIELDS + ' FROM Assessment__c WHERE Account__c = :accountId AND Remaining_Balance__c > 0';
            list<Assessment__c> returnAssessments = Database.query(soql);
            return returnAssessments;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return null;
        }
    }

    public class MapResponse{

        public String assessmentId;
        public Decimal paymentAmount;
    }

}