/**
 * Created by Chris Home Desktop on 7/8/2018.
 */

@IsTest
private class CongrComm_AUTHiFrameCommCtrlTests {

    public static final String TEST_JSON_TRANSACTION_RESPONSE = '{\"accountType\":\"Visa\",\"accountNumber\":\"XXXX1111\",\"transId\":\"0\",\"responseCode\":\"1\",\"authorization\":\"000000\",\"merchantName\":\"Isaac Wise Temple\",\"billTo\":{\"firstName\":\"Chris\",\"lastName\":\"Gibsonsan\",\"address\":\"1530 Commercial CT\",\"city\":\"Jonesboro\",\"state\":\"GA\",\"zip\":\"30236\",\"country\":\"USA\"},\"totalAmount\":\"22.00\",\"orderInvoiceNumber\":\"023466\"}';

    static testMethod void testBehaviorWithBatch() {

        Batch__c theBatch = new Batch__c();
        theBatch.Deposit_ID__c = '1234';
        theBatch.Transaction_Type__c = 'Posted Payment';
        theBatch.Status__c = ConstantsFinancials.UN_SUMMARIZED_STATUS;
        insert theBatch;

        CongrComm_AUTHiFrameCommCtrl.PaymentObjectParams params = new CongrComm_AUTHiFrameCommCtrl.PaymentObjectParams();
        params.AccountNumber = 'test';
        params.TransactionNumber = 'test2';
        params.AccountType = 'Visa';
        params.AuthorizationNumber = 'test';
        params.OrderInvoiceNumber = '1234';

        CongrComm_AUTHiFrameCommCtrl.UpdatePaymentObject(params);
        CongrComm_AUTHiFrameCommCtrl.TransactionUpdateFromAUTH(TEST_JSON_TRANSACTION_RESPONSE);
        CongrComm_AUTHiFrameCommCtrl.getBatchId();

    }

    static testMethod void testBehaviorWithoutBatch() {

        CongrComm_AUTHiFrameCommCtrl.PaymentObjectParams params = new CongrComm_AUTHiFrameCommCtrl.PaymentObjectParams();
        params.AccountNumber = 'test';
        params.TransactionNumber = 'test2';
        params.AccountType = 'Visa';
        params.AuthorizationNumber = 'test';
        params.OrderInvoiceNumber = '1234';

        CongrComm_AUTHiFrameCommCtrl.UpdatePaymentObject(params);
        CongrComm_AUTHiFrameCommCtrl.TransactionUpdateFromAUTH(TEST_JSON_TRANSACTION_RESPONSE);
        CongrComm_AUTHiFrameCommCtrl.getBatchId();

    }
}