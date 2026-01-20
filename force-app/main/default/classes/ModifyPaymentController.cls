/**
 * Created by Chris Home Desktop on 1/1/2018.
 */

public with sharing class ModifyPaymentController {

    public static String ASSESSMENT_SOQL_FIELDS = 'Id,Name,Assessed_Amount__c,Amount_Paid__c,Amount_Adjusted__c,Designation__r.Name,Assessment_Date__c,Remaining_Balance__c,Description__c,Is_Credit_Assessment__c';
    public static String SCHEDULED_PAYMENT_SOQL_FIELDS = 'Id,Name,Assessment__c,Remaining_Balance__c,Total_Payment_Amount__c,Expected_Amount__c,Assessment__r.Remaining_Balance__c,Assessment__r.Is_Credit_Assessment__c ';

    public Boolean ShowPaymentReAssignment { get; set; }
    public String SuccessMessage { get; set; }

    public String AccountNameInput { get; set; }
    public Contact DummyContact { get; set; }
    public Contact DummyTransferContact { get; set; }
    public Contact DummyPaidByContact { get; set; }

    @TestVisible private set<Id> assessmentIds { get; set; }

    public String TransferType { get; set; }

    public list<PaymentWrapper> PaymentWrappers { get; set; }
    public list<UtilitiesWrappers.AssessmentWrapper> AssessmentWrappers { get; set; }
    public list<UtilitiesWrappers.AssessmentWrapper> AssessmentsFromPayment { get; set; }

    public PaymentWrapper PaymentToTransfer { get; set; }

    public set<Id> wrapperIds {
        get {
            if (AssessmentWrappers == null) {
                return new set<Id>();
            }
            set<Id> returnSet = new set<Id>();
            for (UtilitiesWrappers.AssessmentWrapper curWrapper : AssessmentWrappers) {
                returnSet.add(curWrapper.Assessment.Id);
            }
            return returnSet;
        }
    }

    public ModifyPaymentController() {
        this.ShowPaymentReAssignment = false;
        this.AccountNameInput = '';
        this.DummyContact = new Contact();
        this.DummyTransferContact = new Contact();
        this.DummyPaidByContact = new Contact();
        this.assessmentIds = new set<Id>();
        this.DummyPaidByContact.Date_of_Birth__c = date.today();
    }

    public void SearchForPayments() {

        try {
            list<Payment_Adjustment__c> payments = [
                    SELECT Id,Name,Amount__c,Household__c,Deposit_ID__c,Check_Date__c,Type__c,Batch__c,
                            Paid_by_Household__c,Cash_Override_Account__c,RecordTypeId,RecordType.Name,Check_Number__c,Status__c,Date_of_Action__c,
                    (SELECT Id,Name,Amount__c,Scheduled_Payment__r.Assessment__r.Designation__r.Name,Payment_Adjustment__c FROM Scheduled_Payment_Bridges__r)
                    FROM Payment_Adjustment__c
                    WHERE Household__c = :this.DummyContact.AccountId AND (RecordType.DeveloperName = 'Payment' OR RecordType.DeveloperName = 'Credit')
                    ORDER BY Check_Date__c DESC NULLS LAST
            ];
            this.PaymentWrappers = createPaymentWrapper(payments);
        } catch (QueryException qe) {
            system.debug(qe.getMessage());
        }

    }

    public void SearchForAssessments() {

        this.AssessmentWrappers = UtilitiesFinancials.GetAssessmentWrappers(this.DummyTransferContact.AccountId, ASSESSMENT_SOQL_FIELDS, SCHEDULED_PAYMENT_SOQL_FIELDS);

        if (ApexPages.currentPage().getParameters().containsKey('type') && ApexPages.currentPage().getParameters().get('type') == 'reallocate') {
            this.AssessmentWrappers.addAll(GetAssessmentsFromPayment());
        }
    }

    public list<UtilitiesWrappers.AssessmentWrapper> GetAssessmentsFromPayment() {

        list<UtilitiesWrappers.AssessmentWrapper> returnList = new list<UtilitiesWrappers.AssessmentWrapper>();
        list<Payment_Adjustment_Allocation__c> allocations = [SELECT Id,Payment_Adjustment__c,Scheduled_Payment__c,Scheduled_Payment__r.Assessment__c,Amount__c,Batch__r.Deposit_ID__c FROM Payment_Adjustment_Allocation__c WHERE Payment_Adjustment__c = :this.PaymentToTransfer.Payment.Id];
        set<Id> schedPaymentIds = new set<Id>();
        map<Id, list<Payment_Adjustment_Allocation__c>> allocsByAssessId = new map<Id, list<Payment_Adjustment_Allocation__c>>();
        set<Id> assessmentIds = new set<Id>();
        for (Payment_Adjustment_Allocation__c curAlloc : allocations) {
            schedPaymentIds.add(curAlloc.Scheduled_Payment__c);
            assessmentIds.add(curAlloc.Scheduled_Payment__r.Assessment__c);
            if (allocsByAssessId.containsKey(curAlloc.Scheduled_Payment__r.Assessment__c)) {
                allocsByAssessId.get(curAlloc.Scheduled_Payment__r.Assessment__c).add(curAlloc);
            } else {
                list<Payment_Adjustment_Allocation__c> newList = new list<Payment_Adjustment_Allocation__c>();
                newList.add(curAlloc);
                allocsByAssessId.put(curAlloc.Scheduled_Payment__r.Assessment__c, newList);
            }
        }

        map<Id, Scheduled_Payment__c> scheduledPaymentsByAssessId = getScheduledPaymentsByAssessmentId(schedPaymentIds);

        list<Assessment__c> paidAssessments = Database.query('SELECT  ' + ASSESSMENT_SOQL_FIELDS + ' FROM Assessment__c WHERE Id IN :assessmentIds AND Id NOT In :wrapperIds');
        map<Id, Assessment__c> assessMap = new map<Id, Assessment__c>(paidAssessments);
        for (Assessment__c curAssessment : paidAssessments) {
            UtilitiesWrappers.AssessmentWrapper curWrap = new UtilitiesWrappers.AssessmentWrapper();
            list<Payment_Adjustment_Allocation__c> allocs = allocsByAssessId.get(curAssessment.Id);
            curWrap.assessment = curAssessment;
            curWrap.paymentAmount = getTotalOfAllocationAmounts(allocs);
            curWrap.hasPrevBalance = true;
            curWrap.scheduledPayments = new list<Scheduled_Payment__c>{
                    scheduledPaymentsByAssessId.get(curAssessment.Id)
            };
            curWrap.prevBalance = curWrap.assessment.Remaining_Balance__c + Decimal.valueOf(curWrap.paymentAmount);
            returnList.add(curWrap);
        }
        for (UtilitiesWrappers.AssessmentWrapper curWrap : this.AssessmentWrappers) {
            if (allocsByAssessId.containsKey(curWrap.assessment.Id)) {
                curWrap.paymentAmount = getTotalOfAllocationAmounts(allocsByAssessId.get(curWrap.assessment.Id));
                curWrap.hasPrevBalance = true;
                curWrap.prevBalance = curWrap.assessment.Remaining_Balance__c + Decimal.valueOf(curWrap.paymentAmount);
            }
        }
        this.assessmentIds = assessmentIds;

        return returnList;
    }

    @TestVisible private String getTotalOfAllocationAmounts(list<Payment_Adjustment_Allocation__c> allocstions) {
        Decimal returnAmt = 0.00;
        for (Payment_Adjustment_Allocation__c curAlloc : allocstions) {
            returnAmt += curAlloc.Amount__c;
        }

        return String.valueOf(returnAmt);
    }

    public PageReference SaveAndAdjust() {

        if (this.PaymentToTransfer == null) {
            return null;
        }

        Boolean validation = runLineItemValidation(this.PaymentToTransfer.Payment);
        if (validation) {
            return null;
        }

        Save();

        Batch__c adjBatch = new Batch__c();
        adjBatch.Batch_Date__c = Date.today();
        adjBatch.Deposit_ID__c = Datetime.now().format('MM/dd/YY') + 'ADJ';
        adjBatch.Transaction_Type__c = 'Adjustment';
        adjBatch.Status__c = 'Un-Summarized';
        insert adjBatch;

        PageReference pr = Page.PaymentWizard;
        pr.setRedirect(true);
        pr.getParameters().put('id', adjBatch.Id);
        return pr;

    }

    public PageReference Save() {

        if (this.PaymentToTransfer == null) {
            return null;
        }

        Boolean validation = runLineItemValidation(this.PaymentToTransfer.Payment);
        if (validation) {
            return null;
        }

        list<Payment_Adjustment__c> insertPayments = new list<Payment_Adjustment__c>();
        list<Payment_Adjustment_Allocation__c> insertAllocations = new list<Payment_Adjustment_Allocation__c>();

        list<UtilitiesWrappers.AssessmentWrapper> newWrappers = getWrappers(this.AssessmentWrappers, true);


        Payment_Adjustment__c newPayment = createNewPayment();
        Payment_Adjustment__c voidPayment = new Payment_Adjustment__c();

        if (this.PaymentToTransfer.Payment.Status__c == 'Transferred') {
            this.PaymentToTransfer.Payment.Type__c = 'Void';
            this.PaymentToTransfer.Payment.RecordTypeId = UtilitiesSObject.getRecordTypeId('Void', Payment_Adjustment__c.SObjectType);
            voidPayment = createVoidPayment();
            Batch__c newBatch = copyBatch(this.PaymentToTransfer.Payment.Batch__c);

            if (newBatch != null) {
                voidPayment.Batch__c = newBatch.Id;
                newPayment.Batch__c = newBatch.Id;
            }

            insertPayments.add(voidPayment);

            update this.PaymentToTransfer.Payment;
            system.debug(this.PaymentToTransfer.Payment.Scheduled_Payment_Bridges__r);
            for (Payment_Adjustment_Allocation__c curAlloc : this.PaymentToTransfer.Payment.Scheduled_Payment_Bridges__r) {
                system.debug('**Current Alloc: ' + curAlloc);
                Payment_Adjustment_Allocation__c voidAlloc = new Payment_Adjustment_Allocation__c();
                voidAlloc.Payment_Adjustment__c = this.PaymentToTransfer.Payment.Id;
                voidAlloc.Type__c = 'Void';
                voidAlloc.Amount__c = curAlloc.Amount__c * -1;
                voidAlloc.Scheduled_Payment__c = curAlloc.Scheduled_Payment__c;
                curAlloc.RecordTypeId = UtilitiesSObject.getRecordTypeId('Void', Payment_Adjustment_Allocation__c.SObjectType);
                curAlloc.Type__c = 'Void';
                voidAlloc.RecordTypeId = curAlloc.RecordTypeId;
                insertAllocations.add(voidAlloc);
            }
            update this.PaymentToTransfer.Payment.Scheduled_Payment_Bridges__r;

        } else {
            delete this.PaymentToTransfer.Payment;
        }

        insert newPayment;
        system.debug('**Household? ' + voidPayment.Household__c);
        if (voidPayment.Household__c != null) {
            insert voidPayment;
            system.debug('**New Void Payment Inserted. Assigning ID to allocations');
            for (Payment_Adjustment_Allocation__c curAlloc : insertAllocations) {
                curAlloc.Payment_Adjustment__c = voidPayment.Id;
            }
            system.debug('**Inserting New Void Allocations: ' + insertAllocations);
            insert insertAllocations;
        }
        disburseFundsAcrossAllocation(newPayment, this.AssessmentWrappers);
        disburseFundsAcrossAllocationForNewAssessments(newPayment, newWrappers);

        PageReference pr = new PageReference('/' + this.DummyTransferContact.AccountId);
        pr.setRedirect(true);
        return pr;
    }

    public void DisplayReassignmentArea() {

        if (this.DummyContact.AccountId == null) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.WARNING, 'You must select a Household.'));
            return;
        }

        if (this.PaymentWrappers == null) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.WARNING, 'You must select a payment before selecting "Use Payment"'));
            return;
        }


        for (PaymentWrapper curWrapper : this.PaymentWrappers) {
            if (curWrapper.IsSelected) {
                PaymentToTransfer = curWrapper;
                break;
            }
        }

        if (PaymentToTransfer == null) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.WARNING, 'You must select payment.'));
            return;
        }

        if (ApexPages.currentPage().getParameters().containsKey('type') && ApexPages.currentPage().getParameters().get('type') == 'reallocate') {
            this.DummyTransferContact.AccountId = this.DummyContact.AccountId;
        }

        this.ShowPaymentReAssignment = true;
        SearchForAssessments();
    }

    public void AddNewAssessment() {

        if (String.isEmpty(this.DummyContact.AccountId)) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.WARNING, 'You must select a Household before adding an assessment.'));
            return;
        }

        UtilitiesWrappers.AssessmentWrapper wrapper = new UtilitiesWrappers.AssessmentWrapper();
        wrapper.assessment = new Assessment__c();

        wrapper.isNew = true;
        this.AssessmentWrappers.add(wrapper);
    }

    public void ProcessAutoPay() {

        if (this.PaymentToTransfer == null || this.AssessmentWrappers == null) {
            return;
        }

        UtilitiesFinancials.ProcessAutoPay(this.PaymentToTransfer.Payment, this.AssessmentWrappers);

    }

    @TestVisible private Payment_Adjustment__c createNewPayment() {

        Payment_Adjustment__c newPayment = new Payment_Adjustment__c();
        newPayment.Check_Date__c = this.PaymentToTransfer.Payment.Check_Date__c;
        newPayment.Amount__c = this.PaymentToTransfer.Payment.Amount__c;
        newPayment.Type__c = this.PaymentToTransfer.Payment.Type__c;
        newPayment.Batch__c = this.PaymentToTransfer.Payment.Batch__c;
        newPayment.Household__c = this.DummyTransferContact.AccountId;
        newPayment.Paid_by_Household__c = this.DummyPaidByContact.AccountId;
        newPayment.RecordTypeId = this.PaymentToTransfer.Payment.RecordTypeId;
        newPayment.Check_Number__c = this.PaymentToTransfer.Payment.Check_Number__c;
        newPayment.Date_of_Action__c = this.PaymentToTransfer.Payment.Date_of_Action__c;
        newPayment.Cash_Override_Account__c = this.PaymentToTransfer.Payment.Cash_Override_Account__c;
        newPayment.Status__c = 'Un-Summarized';

        return newPayment;
    }

    @TestVisible private Payment_Adjustment__c createVoidPayment() {

        Payment_Adjustment__c voidPayment = new Payment_Adjustment__c();
        voidPayment.Check_Date__c = this.PaymentToTransfer.Payment.Check_Date__c;
        voidPayment.Amount__c = this.PaymentToTransfer.Payment.Amount__c * -1;
        voidPayment.Type__c = this.PaymentToTransfer.Payment.Type__c;
        voidPayment.Household__c = PaymentToTransfer.Payment.Household__c;
        voidPayment.Paid_by_Household__c = PaymentToTransfer.Payment.Paid_by_Household__c;
        voidPayment.RecordTypeId = this.PaymentToTransfer.Payment.RecordTypeId;
        voidPayment.Check_Number__c = this.PaymentToTransfer.Payment.Check_Number__c;
        voidPayment.Date_of_Action__c = this.PaymentToTransfer.Payment.Date_of_Action__c;
        voidPayment.Cash_Override_Account__c = this.PaymentToTransfer.Payment.Cash_Override_Account__c;

        return voidPayment;
    }

    @TestVisible private Batch__c copyBatch(Id batchId) {
        try {
            Batch__c theBatch = [SELECT Id,Batch_Date__c,Deposit_ID__c,Transaction_Type__c FROM Batch__c WHERE Id = :batchId];

            Batch__c newBatchRecord = new Batch__c();
            newBatchRecord.Deposit_ID__c = theBatch.Deposit_ID__c;
            newBatchRecord.Status__c = 'Un-Summarized';

//            Removal for field input 7.24 - Chris
//            newBatchRecord.Batch_Date__c = theBatch.Batch_Date__c;
            newBatchRecord.Transaction_Type__c = 'Posted Payment';
            newBatchRecord.Batch_Date__c = DummyPaidByContact.Date_of_Birth__c;

            insert newBatchRecord;

            return newBatchRecord;
        } catch (QueryException qe) {
            system.debug(qe.getMessage());
            return null;
        } catch (DmlException de) {
            system.debug(de.getMessage());
            return null;
        }
    }

    @TestVisible private void disburseFundsAcrossAllocation(Payment_Adjustment__c payAdj, list<UtilitiesWrappers.AssessmentWrapper> assessmentsToDisburse) {

        set<Id> assessmentIds = getAssessmentIds(assessmentsToDisburse);
        system.debug(assessmentIds);
        map<Id, Scheduled_Payment__c> schedPayments = getScheduledPaymentsByAssessmentId(assessmentIds);
        system.debug(schedPayments);
        FundsDisbursementController disbursementController = new FundsDisbursementController();
        for (UtilitiesWrappers.AssessmentWrapper curWrapper : assessmentsToDisburse) {

            if (String.isEmpty(curWrapper.paymentAmount)) {
                continue;
            }

            if (!schedPayments.containsKey(curWrapper.assessment.Id)) {
                continue;
            }

            Scheduled_Payment__c schedPayment = schedPayments.get(curWrapper.assessment.Id);
            list<Scheduled_Payment__c> scheduledPaymentsForAssessment = new list<Scheduled_Payment__c>();
            scheduledPaymentsForAssessment.add(schedPayment);
            if (scheduledPaymentsForAssessment != null) {
                system.debug('Current Wrapper Payment Amount:' + curWrapper.paymentAmount);
                disbursementController.DisburseFundsToAllocations(Decimal.valueOf(curWrapper.paymentAmount), scheduledPaymentsForAssessment, payAdj, 'Payment');
            }
        }
    }


    @TestVisible private void disburseFundsAcrossAllocationForNewAssessments(Payment_Adjustment__c payAdj, list<UtilitiesWrappers.AssessmentWrapper> assessmentsToDisburse) {

        system.debug('Running disbursement for new assessments.');

        if (assessmentsToDisburse == null || assessmentsToDisburse.size() == 0) {
            return;
        }

        system.debug('Number of Assessments being created:');
        system.debug(assessmentsToDisburse.size());

        list<Assessment__c> assessmentsToInsert = new list<Assessment__c>();

        for (UtilitiesWrappers.AssessmentWrapper curWrapper : assessmentsToDisburse) {

            curWrapper.assessment.Account__c = this.DummyTransferContact.AccountId;
            curWrapper.assessment.Assessed_Amount__c = Decimal.valueOf(curWrapper.paymentAmount);
//            curWrapper.assessment.Assessment_Date__c = this.PaymentToTransfer.Payment.Date_of_Action__c;
            system.debug(curWrapper.assessment.Designation__c);
            assessmentsToInsert.add(curWrapper.assessment);
        }

        insert assessmentsToInsert;
        map<Id, Assessment__c> assessMap = new map<Id, Assessment__c>(assessmentsToInsert);

        disburseFundsAcrossAllocation(payAdj, assessmentsToDisburse);
    }

    @TestVisible private map<Id, Scheduled_Payment__c> getScheduledPaymentsByAssessmentId(set<Id> schedPaymentIds) {

        try {
            list<Scheduled_Payment__c> schedPayments = Database.query('SELECT ' + SCHEDULED_PAYMENT_SOQL_FIELDS + ' FROM Scheduled_Payment__c WHERE Assessment__c in :schedPaymentIds');
            map<Id, Scheduled_Payment__c> schedledPaymentByAssessId = new map<Id, Scheduled_Payment__c>();
            for (Scheduled_Payment__c curSchedPayment : schedPayments) {
                if (!schedledPaymentByAssessId.containsKey(curSchedPayment.Assessment__c)) {
                    schedledPaymentByAssessId.put(curSchedPayment.Assessment__c, curSchedPayment);
                }
            }
            return schedledPaymentByAssessId;
        } catch (QueryException qe) {
            system.debug(qe.getMessage());
            return null;
        }
    }


    @TestVisible private list<UtilitiesWrappers.AssessmentWrapper> getWrappers(list<UtilitiesWrappers.AssessmentWrapper> assessmentWrappers, Boolean isNew) {

        list<UtilitiesWrappers.AssessmentWrapper> returnList = new list<UtilitiesWrappers.AssessmentWrapper>();
        for (UtilitiesWrappers.AssessmentWrapper curWrapper : assessmentWrappers) {

            if (curWrapper.isNew == isNew) {
                returnList.add(curWrapper);
            }

            if (this.DummyPaidByContact.Date_of_Birth__c != null) {
                curWrapper.assessment.Assessment_Date__c = this.DummyPaidByContact.Date_of_Birth__c;
            }
        }
        return returnList;
    }

    @TestVisible private Boolean runLineItemValidation(Payment_Adjustment__c payAdj) {

        Boolean returnBool = false;
        Decimal paymentAmount = 0.00;
        for (UtilitiesWrappers.AssessmentWrapper curWrapper : AssessmentWrappers) {

            if (String.isEmpty(curWrapper.paymentAmount)) {
                continue;
            }

            if (Decimal.valueOf(curWrapper.paymentAmount) > curWrapper.assessment.Remaining_Balance__c && !curWrapper.hasPrevBalance) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.WARNING, 'Please check ' + curWrapper.assessment.Designation__r.Name + '. The payment amount cannot exceed the remaining balance.'));
                returnBool = true;
            }
            paymentAmount += Decimal.valueOf(curWrapper.paymentAmount);
        }

        if (paymentAmount != this.PaymentToTransfer.Payment.Amount__c) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.WARNING, 'You must use all funds specified in the Current Payment Amount.'));
            returnBool = true;

        }

        return returnBool;
    }

    @TestVisible private set<Id> getAssessmentIds(list<UtilitiesWrappers.AssessmentWrapper> assessmentsToGetIdsFor) {
        set<Id> returnSet = new set<Id>();

        for (UtilitiesWrappers.AssessmentWrapper curWrap : assessmentsToGetIdsFor) {
            returnSet.add(curWrap.assessment.Id);
        }
        return returnSet;
    }

    @TestVisible private list<PaymentWrapper> createPaymentWrapper(list<Payment_Adjustment__c> payments) {

        list<PaymentWrapper> returnList = new list<PaymentWrapper>();
        for (Payment_Adjustment__c curPayment : payments) {
            PaymentWrapper curWrap = new PaymentWrapper();
            curWrap.Payment = curPayment;
            curWrap.Allocations = curPayment.Scheduled_Payment_Bridges__r;
            returnList.add(curWrap);
        }
        return returnList;
    }

    public class PaymentWrapper {

        public Boolean IsSelected { get; set; }
        public Payment_Adjustment__c Payment { get; set; }
        public list<Payment_Adjustment_Allocation__c> Allocations { get; set; }

        public PaymentWrapper() {
            IsSelected = false;
        }
    }


}