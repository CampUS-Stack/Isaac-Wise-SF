/**
 * Created by Chris Gibson on 5/6/2020.
 */

public without sharing class NMI_PaymentProcessingCtrl {

    //// Singleton for connection controller
    public static NMI_PaymentProcessingCtrl GetNMIPaymentProcessingCtrl{
        get{
            if(thePaymentProcessingCtrl == null){
                thePaymentProcessingCtrl = new NMI_PaymentProcessingCtrl();
                return thePaymentProcessingCtrl;
            }

            return thePaymentProcessingCtrl;
        }
    }
    private static NMI_PaymentProcessingCtrl thePaymentProcessingCtrl;


    public NMI_PaymentProcessingCtrl(){}


    public String createOneTimePaymentRequest(Id paymentId, String body, Boolean shouldStorePaymentData) {

        system.debug('Sending One Time Payment Request/Transaction');
        system.debug('Should payment information be stored? - ' + shouldStorePaymentData);
        system.debug('Payment Adjustment ID: ' + paymentId);
        Payment_Adjustment__c paymentAdjustment = NMI_Utilities.GetPaymentAdjustment(paymentId);

        NMI_TransactionalWrapper transactionalWrapper = NMI_Utilities.CreateOneTimePaymentWrapper('sale', Double.valueOf(paymentAdjustment.Amount__c),paymentAdjustment.Type__c,null);

        System.debug(transactionalWrapper);

        if(shouldStorePaymentData){
            transactionalWrapper.AddCustomer = new NMI_TransactionalWrapper.AddCustomer();
        }

        NMI_RequestController.X3StepResponse requestResponse = NMI_RequestController.GetNMIRequestController.SendOneTimePaymentRequest(transactionalWrapper,body);

        System.debug(requestResponse.Result);

        if(requestResponse.Result == '100'){
            if(String.isNotEmpty(paymentId)){
                Payment_Adjustment__c reQueriedPaymentAdjustment = NMI_Utilities.GetPaymentAdjustment(paymentId);
                reQueriedPaymentAdjustment.Incomplete_Payment__c = false;
            }

//            NMI_PaymentReconcileCtrl.ReconcileTransactionWithProcessorASYNC(requestResponse.TransactionId);

//            if(shouldStorePaymentData != null && shouldStorePaymentData){
//                createVaultEntry(JSON.serialize(requestResponse),theDonation.Id);
//            }
            return requestResponse.TransactionId;
        }
        else{
//            if(String.isNotEmpty(transactionPaymentId)){
//                Transaction_Payment__c transactionPayment = NMI_Utilities.GetTransactionPayment(transactionPaymentId);
//                updateFailurePayment(transactionPayment, theDonation, requestResponse, 'sale');
//            }
//            else{
//                createFailurePayment(theDonation, requestResponse, 'sale');
//            }
            return 'FAIL - ' + requestResponse.Result + ' - ' + requestResponse.ResultText;
        }

    }


    /**
     * Method to get secure url to submit payment information (Used while form load)
     * @param paymentId
     * @param shouldSavePaymentInfo
     *
     * @return
     */
    public String getFormURLFromFirstStep(Id paymentId, Double paymentAmount, Boolean shouldSavePaymentInfo, NMI_TransactionalWrapper.Billing billingInfo) {
        Payment_Adjustment__c paymentAdjustment = NMI_Utilities.GetPaymentAdjustment(paymentId);
        //Double.valueOf(paymentAdjustment.Amount__c)
        NMI_TransactionalWrapper transactionalWrapper = NMI_Utilities.CreateOneTimePaymentWrapper('sale', paymentAmount, paymentAdjustment.Type__c,null);
        transactionalWrapper.Billing = billingInfo;

        System.debug(shouldSavePaymentInfo);
        if(shouldSavePaymentInfo){
            transactionalWrapper.AddCustomer = new NMI_TransactionalWrapper.AddCustomer();
        }

        String redirectUrl = NMI_RequestController.GetNMIRequestController.getSecureURLFromFirstStep(transactionalWrapper);
        System.debug('redirectUrl = '+ redirectUrl);
        return redirectUrl;
    }


    /**
     * Method to get secure url to submit payment information (Used while form load), used when using saved payment info
     * @param paymentId
     * @param vaultEntry
     *
     * @return
     */
    public String getFormURLFromFirstStep(Id paymentId, Payment_Vault__c vaultEntry) {
        Payment_Adjustment__c paymentAdjustment = NMI_Utilities.GetPaymentAdjustment(paymentId);
        NMI_TransactionalWrapper transactionalWrapper = NMI_Utilities.CreateOneTimePaymentWrapper('sale', Double.valueOf(paymentAdjustment.Amount__c), 'recurring',vaultEntry);

        String redirectUrl = NMI_RequestController.GetNMIRequestController.getSecureURLFromFirstStep(transactionalWrapper);
        return redirectUrl;
    }


    public NMI_RequestController.X3StepResponse createOneTimePaymentRequest(Id paymentId, String body, String secureURL) {


        NMI_RequestController.X3StepResponse requestResponse = NMI_RequestController.GetNMIRequestController.SendOneTimePaymentRequest(body, secureURL);
        if (requestResponse.Result == '100') {
            if (String.isNotEmpty(paymentId)) {
                Payment_Adjustment__c paymentAdjustment = NMI_Utilities.GetPaymentAdjustment(paymentId);
                paymentAdjustment.Incomplete_Payment__c = false;
            }

        }

        return requestResponse;

    }


    @future(callout=true)
    public static void createVaultEntry(String requestResponseJSON, String paymentId){

        system.debug(requestResponseJSON);

        Payment_Adjustment__c paymentAdjustment = NMI_Utilities.GetPaymentAdjustment(paymentId);
        NMI_RequestController.X3StepResponse requestResponse = (NMI_RequestController.X3StepResponse)JSON.deserialize(requestResponseJSON,NMI_RequestController.X3StepResponse.class);
        Payment_Vault__c pv = new Payment_Vault__c();

        if(String.isNotEmpty(requestResponse.AccountName)) {
            pv.Account_Name__c = requestResponse.AccountName;
        }if(String.isNotEmpty(requestResponse.CheckingAccountNumber)) {
            pv.Account_Number__c = requestResponse.CheckingAccountNumber;
        }if(String.isNotEmpty(requestResponse.RoutingNumber)) {
            pv.Routing_Number__c = requestResponse.RoutingNumber;
        }if(String.isNotEmpty(requestResponse.CreditCardNumber)) {
            pv.Credit_Card_Number__c = requestResponse.CreditCardNumber;
        }if(String.isNotEmpty(requestResponse.CreditCardExpiration)) {
            pv.Expiration_Date__c = requestResponse.CreditCardExpiration;
        }if(String.isNotEmpty(requestResponse.CustomerVaultId)) {
            pv.NMI_Customer_Vault_Number__c = requestResponse.CustomerVaultId;
        }if(String.isNotEmpty(requestResponse.BillingId)) {
            pv.NMI_Billing_ID__c = requestResponse.BillingId;
        }if(paymentAdjustment != null){
            pv.Organization_Household__c = paymentAdjustment.Account_ID__c;
        }

        if(String.isNotEmpty(pv.Credit_Card_Number__c)){
            pv.RecordTypeId = UtilitiesSObject.getRecordTypeId('Credit_Card',Payment_Vault__c.SObjectType);
        }
        else{
            pv.RecordTypeId = UtilitiesSObject.getRecordTypeId('ACH',Payment_Vault__c.SObjectType);
        }

        System.debug(pv.NMI_Customer_Vault_Number__c);
        try{
            if(String.isNotEmpty(pv.NMI_Customer_Vault_Number__c)){
                insert pv;
                paymentAdjustment.Payment_Vault__c = pv.Id;
                update paymentAdjustment;
            }
        }
        catch(DmlException de){
            system.debug(de.getMessage());
        }
    }



}