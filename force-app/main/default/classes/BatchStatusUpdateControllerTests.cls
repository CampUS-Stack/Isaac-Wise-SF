/**
 * Created by Chris Home Desktop on 1/28/2018.
 */

@IsTest
private class BatchStatusUpdateControllerTests {
    static testMethod void TestBatchStatusShoulUpdateToClosedWhen2UnTransferred() {

        Account acc = new Account();
        acc.Name = 'Test';
        insert acc;

        list<Batch__c> batches = (list<Batch__c>) TestObjectFactory.CreateBatches(1);
        insert batches;

        list<Payment_Adjustment__c> paymentAdjustments = TestObjectFactory.CreatePaymentAdjustments(2);
        paymentAdjustments[0].Batch__c = batches[0].Id;
        paymentAdjustments[0].Household__c = acc.Id;
        paymentAdjustments[0].Status__c = 'Un-Transferred';
        paymentAdjustments[1].Batch__c = batches[0].Id;
        paymentAdjustments[1].Household__c = acc.Id;
        paymentAdjustments[1].Status__c = 'Un-Transferred';
        insert paymentAdjustments;

        BatchStatusUpdateController.ProcessStatusUpdates(batches);

        system.assert(batches[0].Status__c == 'Summarized');
    }

    static testMethod void TestBatchStatusShouldNotUpdateToClosedWhen1UnTransferredAnd1UnSummarized() {

        Account acc = new Account();
        acc.Name = 'Test';
        insert acc;

        list<Batch__c> batches = (list<Batch__c>) TestObjectFactory.CreateBatches(1);
        insert batches;

        list<Payment_Adjustment__c> paymentAdjustments = TestObjectFactory.CreatePaymentAdjustments(2);
        paymentAdjustments[0].Batch__c = batches[0].Id;
        paymentAdjustments[0].Household__c = acc.Id;
        paymentAdjustments[0].Status__c = 'Un-Transferred';
        paymentAdjustments[1].Batch__c = batches[0].Id;
        paymentAdjustments[1].Household__c = acc.Id;
        paymentAdjustments[1].Status__c = 'Un-Summarized';
        insert paymentAdjustments;

        BatchStatusUpdateController.ProcessStatusUpdates(batches);

        system.assert(batches[0].Status__c != 'Summarized');
    }

    static testMethod void TestBatchStatusShouldNotUpdateToTransferredWhen2Transferred() {

        Account acc = new Account();
        acc.Name = 'Test';
        insert acc;

        list<Batch__c> batches = (list<Batch__c>) TestObjectFactory.CreateBatches(1);
        insert batches;

        list<Payment_Adjustment__c> paymentAdjustments = TestObjectFactory.CreatePaymentAdjustments(2);
        paymentAdjustments[0].Batch__c = batches[0].Id;
        paymentAdjustments[0].Household__c = acc.Id;
        paymentAdjustments[0].Status__c = 'Transferred';
        paymentAdjustments[1].Batch__c = batches[0].Id;
        paymentAdjustments[1].Household__c = acc.Id;
        paymentAdjustments[1].Status__c = 'Transferred';
        insert paymentAdjustments;

        BatchStatusUpdateController.ProcessStatusUpdates(batches);

        system.assert(batches[0].Status__c == 'Transferred');
    }
}