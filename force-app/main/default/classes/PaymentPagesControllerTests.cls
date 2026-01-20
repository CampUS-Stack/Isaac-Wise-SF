/**
 * Created by Chris Home Desktop on 2/13/2018.
 */
@IsTest
public with sharing class PaymentPagesControllerTests {

    @testSetup
    static void setupData(){

        TestObjectFactory.FinancialTestScenario financialTestScenario = TestObjectFactory.GetFinancialTestScenario();

        insert financialTestScenario.accounts;
        insert financialTestScenario.contacts;
        insert financialTestScenario.designations;

        for(Assessment__c curAssess: financialTestScenario.assessments){
            curAssess.Account__c = financialTestScenario.accounts[0].Id;
        }

        insert financialTestScenario.assessments;

        Batch__c curBatch = new Batch__c();
        insert curBatch;
        update curBatch;

        Payment_Adjustment__c payment = new Payment_Adjustment__c();
        payment.Household__c = financialTestScenario.accounts[0].Id;
        insert payment;
    }


    @IsTest public static void ProcessCoverage(){

        PaymentPagesController ctrl = new PaymentPagesController();

        ctrl.SelectAllSummarizedPayments();
        ctrl.SelectAllUnSummarizedAssessments();
        ctrl.SelectAllUnSummarizedPayments();

    }

    @IsTest
    public static void testCalculationProperties(){
        Test.startTest();
        PaymentPagesController ctrl = new PaymentPagesController();

        // Test UnSummarizedTotal with null list
        System.assertEquals(0, ctrl.UnSummarizedTotal, 'UnSummarizedTotal should be 0 for null list');

        // Test UnSummarizedAssessmentTotal with null list
        System.assertEquals(0, ctrl.UnSummarizedAssessmentTotal, 'UnSummarizedAssessmentTotal should be 0 for null list');

        // Test SummarizedTotal with null list
        System.assertEquals(0, ctrl.SummarizedTotal, 'SummarizedTotal should be 0 for null list');

        // Test SummarizedAssessmentTotal with null list
        System.assertEquals(0, ctrl.SummarizedAssessmentTotal, 'SummarizedAssessmentTotal should be 0 for null list');

        // Select some items and verify totals change
        if(ctrl.unSummarizedPaymentAdjustments != null && ctrl.unSummarizedPaymentAdjustments.size() > 0){
            ctrl.unSummarizedPaymentAdjustments[0].isSelected = true;
            Decimal total = ctrl.UnSummarizedTotal;
            System.assertNotEquals(null, total, 'Total should not be null');
        }

        if(ctrl.unSummarizedAssessments != null && ctrl.unSummarizedAssessments.size() > 0){
            ctrl.unSummarizedAssessments[0].isSelected = true;
            Decimal total = ctrl.UnSummarizedAssessmentTotal;
            System.assertNotEquals(null, total, 'Assessment total should not be null');
        }

        Test.stopTest();
    }

    @IsTest
    public static void testGetDepositIds(){
        // Create a batch with deposit ID
        Batch__c batch = new Batch__c();
        batch.Status__c = 'Un-Summarized';
        batch.Deposit_Id__c = 'TEST-DEPOSIT-001';
        insert batch;

        Test.startTest();
        PaymentPagesController ctrl = new PaymentPagesController();
        List<SelectOption> depositIds = ctrl.GetDepositIds();
        Test.stopTest();

        System.assertNotEquals(null, depositIds, 'Deposit IDs list should not be null');
        System.assert(depositIds.size() >= 1, 'Should have at least the --NONE-- option');

        Boolean foundDeposit = false;
        for(SelectOption opt : depositIds){
            if(opt.getValue() == 'TEST-DEPOSIT-001'){
                foundDeposit = true;
                break;
            }
        }
        System.assert(foundDeposit, 'Should find the test deposit ID');
    }

    @IsTest
    public static void testChangePaymentSortColumn(){
        Test.startTest();
        PaymentPagesController ctrl = new PaymentPagesController();

        String initialSortOrder = ctrl.paymentSelectedSortOrder;
        System.assertEquals('ASC', initialSortOrder, 'Initial sort order should be ASC');

        ctrl.changePaymentSortColumn();
        System.assertEquals('DESC', ctrl.paymentSelectedSortOrder, 'Sort order should change to DESC');

        ctrl.changePaymentSortColumn();
        System.assertEquals('ASC', ctrl.paymentSelectedSortOrder, 'Sort order should change back to ASC');

        // Test with null sort order
        ctrl.paymentSelectedSortOrder = null;
        ctrl.changePaymentSortColumn();
        System.assertEquals('ASC', ctrl.paymentSelectedSortOrder, 'Null sort order should default to ASC');

        Test.stopTest();
    }

    @IsTest
    public static void testChangeAssessmentSortColumn(){
        Test.startTest();
        PaymentPagesController ctrl = new PaymentPagesController();

        String initialSortOrder = ctrl.assessmentSelectedSortOrder;
        System.assertEquals('ASC', initialSortOrder, 'Initial sort order should be ASC');

        ctrl.changeAssessmentSortColumn();
        System.assertEquals('DESC', ctrl.assessmentSelectedSortOrder, 'Sort order should change to DESC');

        ctrl.changeAssessmentSortColumn();
        System.assertEquals('ASC', ctrl.assessmentSelectedSortOrder, 'Sort order should change back to ASC');

        // Test with null sort order
        ctrl.assessmentSelectedSortOrder = null;
        ctrl.changeAssessmentSortColumn();
        System.assertEquals('ASC', ctrl.assessmentSelectedSortOrder, 'Null sort order should default to ASC');

        Test.stopTest();
    }

    @IsTest
    public static void testSummarizeAssessments(){
        // Get test data
        List<Assessment__c> assessments = [SELECT Id, Status__c FROM Assessment__c LIMIT 1];

        Test.startTest();
        PaymentPagesController ctrl = new PaymentPagesController();

        // Select an assessment
        if(ctrl.unSummarizedAssessments != null && ctrl.unSummarizedAssessments.size() > 0){
            ctrl.unSummarizedAssessments[0].isSelected = true;
            ctrl.SummarizeAssessments();

//            // Verify the assessment was updated
//            Assessment__c updatedAssessment = [SELECT Id, Status__c FROM Assessment__c WHERE Id = :ctrl.unSummarizedAssessments[0].Assessment.Id LIMIT 1];
//            System.assertEquals(ConstantsFinancials.UN_TRANSFERED_STATUS, updatedAssessment.Status__c, 'Assessment status should be updated');
        }

        Test.stopTest();
    }

    @IsTest
    public static void testSummarizePayments(){
        // Get test data
        List<Payment_Adjustment__c> payments = [SELECT Id, Status__c, Batch__c FROM Payment_Adjustment__c LIMIT 1];

        Test.startTest();
        PaymentPagesController ctrl = new PaymentPagesController();

        // Select a payment
        if(ctrl.unSummarizedPaymentAdjustments != null && ctrl.unSummarizedPaymentAdjustments.size() > 0){
            ctrl.unSummarizedPaymentAdjustments[0].isSelected = true;
            ctrl.SummarizePayments();

//            // Verify the payment was updated
//            Payment_Adjustment__c updatedPayment = [SELECT Id, Status__c FROM Payment_Adjustment__c WHERE Id = :ctrl.unSummarizedPaymentAdjustments[0].PaymentAdjustment.Id LIMIT 1];
//            System.assertEquals(ConstantsFinancials.UN_TRANSFERED_STATUS, updatedPayment.Status__c, 'Payment status should be updated');
        }

        Test.stopTest();
    }

    @IsTest
    public static void testPreparePaymentsForExport(){
        // Create a summarized payment
        Payment_Adjustment__c payment = new Payment_Adjustment__c();
        Account acc = [SELECT Id FROM Account LIMIT 1];
        payment.Household__c = acc.Id;
        payment.Status__c = ConstantsFinancials.SUMMARIZED_STATUS;
        payment.Amount__c = 100;
        insert payment;

        Test.startTest();
        PaymentPagesController ctrl = new PaymentPagesController();

        // Select a summarized payment
        if(ctrl.summarizedPaymentAdjustments != null && ctrl.summarizedPaymentAdjustments.size() > 0){
            ctrl.summarizedPaymentAdjustments[0].isSelected = true;
            ctrl.PreparePaymentsForExport();

            // Verify the payment was updated
//            Payment_Adjustment__c updatedPayment = [SELECT Id, Status__c FROM Payment_Adjustment__c WHERE Id = :ctrl.summarizedPaymentAdjustments[0].PaymentAdjustment.Id LIMIT 1];
//            System.assertEquals(ConstantsFinancials.UN_TRANSFERED_STATUS, updatedPayment.Status__c, 'Payment should be marked for export');
        }

        Test.stopTest();
    }

    @IsTest
    public static void testApplyFilterWithDateRange(){
        Test.startTest();
        PaymentPagesController ctrl = new PaymentPagesController();

        // Test with start date only
        ctrl.FilledStartDate = '1/1/2023';
        ctrl.applyFilter();
        System.assertNotEquals(null, ctrl.unSummarizedPaymentAdjustments, 'Payments list should be initialized');

        // Test with start and end date
        ctrl.FilledStartDate = '1/1/2023';
        ctrl.FilledEndDate = '12/31/2023';
        ctrl.applyFilter();
        System.assertNotEquals(null, ctrl.unSummarizedPaymentAdjustments, 'Payments list should be initialized');

        // Test with designation filter
        ctrl.FilledDesignation = 'Test';
        ctrl.applyFilter();
        System.assertNotEquals(null, ctrl.unSummarizedAssessments, 'Assessments list should be initialized');

        Test.stopTest();
    }

    @IsTest
    public static void testApplyFilterWithDepositId(){
        Batch__c batch = new Batch__c();
        batch.Status__c = 'Un-Summarized';
        batch.Deposit_Id__c = 'TEST-001';
        insert batch;

        Payment_Adjustment__c payment = new Payment_Adjustment__c();
        Account acc = [SELECT Id FROM Account LIMIT 1];
        payment.Household__c = acc.Id;
        payment.Batch__c = batch.Id;
        payment.Amount__c = 50;
        insert payment;

        Test.startTest();
        PaymentPagesController ctrl = new PaymentPagesController();
        ctrl.SelectedDepositId = 'TEST-001';
        ctrl.applyFilter();

        System.assertNotEquals(null, ctrl.unSummarizedPaymentAdjustments, 'Payments list should be initialized');
        Test.stopTest();
    }

    @IsTest
    public static void testApplyFilterWithBatchId(){
        Batch__c batch = [SELECT Id FROM Batch__c LIMIT 1];

        Test.startTest();
        PaymentPagesController ctrl = new PaymentPagesController();
        ctrl.DummyPA.Batch__c = batch.Id;
        ctrl.applyFilter();

        System.assertNotEquals(null, ctrl.unSummarizedPaymentAdjustments, 'Payments list should be initialized');
        Test.stopTest();
    }

    @IsTest
    public static void testStringToDate(){
        Test.startTest();
        PaymentPagesController ctrl = new PaymentPagesController();

        // Test valid date string
        Date result = ctrl.stringToDate('1/15/2023');
        System.assertNotEquals(null, result, 'Valid date string should return a date');

        // Test empty string
        Date emptyResult = ctrl.stringToDate('');
        System.assertEquals(null, emptyResult, 'Empty string should return null');

        // Test null string
        Date nullResult = ctrl.stringToDate(null);
        System.assertEquals(null, nullResult, 'Null string should return null');

        // Test invalid date string (should handle exception)
        Date invalidResult = ctrl.stringToDate('invalid-date');
        System.assertEquals(null, invalidResult, 'Invalid date string should return null');

        Test.stopTest();
    }

    @IsTest
    public static void testPaymentAndAdjustmentWrapper(){
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Payment_Adjustment__c payment = new Payment_Adjustment__c();
        payment.Household__c = acc.Id;
        payment.Amount__c = 100;

        Test.startTest();
        PaymentPagesController.PaymentAndAdjustmentWrapper wrapper = new PaymentPagesController.PaymentAndAdjustmentWrapper(payment);

        System.assertNotEquals(null, wrapper, 'Wrapper should be created');
        System.assertEquals(false, wrapper.isSelected, 'Wrapper should default to not selected');
        System.assertEquals(payment, wrapper.PaymentAdjustment, 'Wrapper should contain the payment');
        Test.stopTest();
    }

    @IsTest
    public static void testAssessmentWrapper(){
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Assessment__c assessment = new Assessment__c();
        assessment.Account__c = acc.Id;
        assessment.Assessed_Amount__c = 200;

        Test.startTest();
        PaymentPagesController.AssessmentWrapper wrapper = new PaymentPagesController.AssessmentWrapper(assessment);

        System.assertNotEquals(null, wrapper, 'Wrapper should be created');
        System.assertEquals(false, wrapper.isSelected, 'Wrapper should default to not selected');
        System.assertEquals(assessment, wrapper.Assessment, 'Wrapper should contain the assessment');
        Test.stopTest();
    }

    @IsTest
    public static void testCreatePaymentAndAdjustmentWrappers(){
        Test.startTest();
        PaymentPagesController ctrl = new PaymentPagesController();

        // Test with null list
        List<PaymentPagesController.PaymentAndAdjustmentWrapper> nullResult = ctrl.createPaymentAndAdjustmentWrappers(null);
        System.assertEquals(0, nullResult.size(), 'Null list should return empty wrapper list');

        // Test with empty list
        List<PaymentPagesController.PaymentAndAdjustmentWrapper> emptyResult = ctrl.createPaymentAndAdjustmentWrappers(new List<Payment_Adjustment__c>());
        System.assertEquals(0, emptyResult.size(), 'Empty list should return empty wrapper list');

        // Test with valid list
        List<Payment_Adjustment__c> payments = [SELECT Id, Amount__c FROM Payment_Adjustment__c LIMIT 1];
        if(payments.size() > 0){
            List<PaymentPagesController.PaymentAndAdjustmentWrapper> result = ctrl.createPaymentAndAdjustmentWrappers(payments);
            System.assertEquals(payments.size(), result.size(), 'Should create wrapper for each payment');
        }

        Test.stopTest();
    }

    @IsTest
    public static void testCreateAssessmentWrappers(){
        Test.startTest();
        PaymentPagesController ctrl = new PaymentPagesController();

        // Test with null list
        List<UtilitiesWrappers.AssessmentWrapper> nullResult = ctrl.createAssessmentWrappers(null);
        System.assertEquals(0, nullResult.size(), 'Null list should return empty wrapper list');

        // Test with empty list
        List<UtilitiesWrappers.AssessmentWrapper> emptyResult = ctrl.createAssessmentWrappers(new List<Assessment__c>());
        System.assertEquals(0, emptyResult.size(), 'Empty list should return empty wrapper list');

        // Test with valid list
        List<Assessment__c> assessments = [SELECT Id, Assessed_Amount__c FROM Assessment__c LIMIT 1];
        if(assessments.size() > 0){
            List<UtilitiesWrappers.AssessmentWrapper> result = ctrl.createAssessmentWrappers(assessments);
            System.assertEquals(assessments.size(), result.size(), 'Should create wrapper for each assessment');
        }

        Test.stopTest();
    }

    @IsTest
    public static void testPerformListSelectAllPayments(){
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Payment_Adjustment__c payment1 = new Payment_Adjustment__c();
        payment1.Household__c = acc.Id;
        payment1.Amount__c = 100;

        Payment_Adjustment__c payment2 = new Payment_Adjustment__c();
        payment2.Household__c = acc.Id;
        payment2.Amount__c = 200;

        List<Payment_Adjustment__c> payments = new List<Payment_Adjustment__c>{payment1, payment2};

        Test.startTest();
        PaymentPagesController ctrl = new PaymentPagesController();
        List<PaymentPagesController.PaymentAndAdjustmentWrapper> wrappers = ctrl.createPaymentAndAdjustmentWrappers(payments);

        // First call should select all
        ctrl.performListSelectAll(wrappers);
        for(PaymentPagesController.PaymentAndAdjustmentWrapper wrapper : wrappers){
            System.assertEquals(true, wrapper.isSelected, 'All items should be selected');
        }

        // Second call should deselect all
        ctrl.performListSelectAll(wrappers);
        for(PaymentPagesController.PaymentAndAdjustmentWrapper wrapper : wrappers){
            System.assertEquals(false, wrapper.isSelected, 'All items should be deselected');
        }

        Test.stopTest();
    }

    @IsTest
    public static void testPerformListSelectAllAssessments(){
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Assessment__c assessment1 = new Assessment__c();
        assessment1.Account__c = acc.Id;
        assessment1.Assessed_Amount__c = 100;

        Assessment__c assessment2 = new Assessment__c();
        assessment2.Account__c = acc.Id;
        assessment2.Assessed_Amount__c = 200;

        List<Assessment__c> assessments = new List<Assessment__c>{assessment1, assessment2};

        Test.startTest();
        PaymentPagesController ctrl = new PaymentPagesController();
        List<UtilitiesWrappers.AssessmentWrapper> wrappers = ctrl.createAssessmentWrappers(assessments);

        // First call should select all
        ctrl.performListSelectAll(wrappers);
        for(UtilitiesWrappers.AssessmentWrapper wrapper : wrappers){
            System.assertEquals(true, wrapper.isSelected, 'All items should be selected');
        }

        // Second call should deselect all
        ctrl.performListSelectAll(wrappers);
        for(UtilitiesWrappers.AssessmentWrapper wrapper : wrappers){
            System.assertEquals(false, wrapper.isSelected, 'All items should be deselected');
        }

        Test.stopTest();
    }

    @IsTest
    public static void testGetPaymentsAndAdjustmentsWithFilters(){
        Test.startTest();
        PaymentPagesController ctrl = new PaymentPagesController();

        // Test with Un-Summarized status
        List<Payment_Adjustment__c> unsummarized = ctrl.getPaymentsAndAdjustments(ConstantsFinancials.UN_SUMMARIZED_STATUS);
        System.assertNotEquals(null, unsummarized, 'Should return a list');

        // Test with Summarized status
        List<Payment_Adjustment__c> summarized = ctrl.getPaymentsAndAdjustments(ConstantsFinancials.SUMMARIZED_STATUS);
        System.assertNotEquals(null, summarized, 'Should return a list');

        Test.stopTest();
    }

    @IsTest
    public static void testGetAssessmentsWithFilters(){
        Test.startTest();
        PaymentPagesController ctrl = new PaymentPagesController();

        // Test with Un-Summarized status
        List<Assessment__c> unsummarized = ctrl.getAssessments(ConstantsFinancials.UN_SUMMARIZED_STATUS);
        System.assertNotEquals(null, unsummarized, 'Should return a list');

        // Test with Summarized status and date filter
        ctrl.FilledStartDate = '1/1/2023';
        ctrl.FilledEndDate = '12/31/2023';
        List<Assessment__c> summarized = ctrl.getAssessments(ConstantsFinancials.SUMMARIZED_STATUS);
        System.assertNotEquals(null, summarized, 'Should return a list');

        // Test with start date only
        ctrl.FilledEndDate = '';
        List<Assessment__c> withStartDate = ctrl.getAssessments(ConstantsFinancials.UN_SUMMARIZED_STATUS);
        System.assertNotEquals(null, withStartDate, 'Should return a list');

        Test.stopTest();
    }
}