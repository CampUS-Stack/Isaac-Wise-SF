/**
 * Created by zacha on 9/15/2020.
 */

public inherited sharing class NMI_ManageVaultController {

//    @AuraEnabled public static String createOneTimePaymentRequestByVault(String paymentVaultId, Double paymentAmount) {
//
//        return createOneTimePaymentRequestByVault(paymentVaultId, paymentAmount,'');
//    }
//
//
//    @AuraEnabled public static String createOneTimePaymentRequestByVault(String paymentVaultId, Double paymentAmount, String transactionPaymentId) {
//
//        system.debug('Sending One Time Payment Request/Transaction');
//        Payment_Vault__c vaultEntry = NMI_Utilities.GetPaymentVault(paymentVaultId);
//
//        NMI_TransactionalWrapper transactionalWrapper = NMI_Utilities.CreateOneTimePaymentWrapper('sale', paymentAmount, 'recurring', vaultEntry);
//
//        NMI_RequestController.X3StepResponse requestResponse = NMI_RequestController.GetNMIRequestController.SendOneTimePaymentRequest(transactionalWrapper,'');
//
//        if(requestResponse.Result == '100'){
////            updateDonation(theDonation.Id,vaultEntry.Id);
//            if(String.isNotEmpty(transactionPaymentId)){
//                Transaction_Payment__c transactionPayment = NMI_Utilities.GetTransactionPayment(transactionPaymentId);
//                updatePaymentWithAllocations(transactionPayment,theDonation, requestResponse, vaultEntry.RecordType.Name);
//            }
//            else{
//                createPaymentWithAllocations(theDonation, requestResponse, vaultEntry.RecordType.Name);
//            }
//            NMI_PaymentReconcileCtrl.ReconcileTransactionWithProcessorASYNC(requestResponse.TransactionId);
//            return requestResponse.TransactionId;
//        }
//        else{
//            createFailurePayment(theDonation, requestResponse, 'sale');
//            return 'FAIL - ' + requestResponse.Result + ' - ' + requestResponse.ResultText;
//        }
//    }

    public static String createNewACHVaultEntry(String accountName, String accountNumber, String routingNumber, String accountId, String firstName, String lastName){

        NMI_RequestController.X3StepResponse response = NMI_RequestController.GetNMIRequestController.SendCustomerACHVaultRequest(accountName,accountNumber,routingNumber, accountId, firstName,lastName,'add-customer','');
        System.debug(response);
        if(response.Result == '100'){
            return createOrUpdateCustomerVaultData(response,accountId,'ACH');
        } else {
            return 'FAIL - ' + response.Result + ' - ' + response.ResultText;
        }
    }

    public static String createNewCCVaultEntry(String ccNumber, String ccExpiration, String cvc, Id accountId, String firstName, String lastName){
        NMI_RequestController.X3StepResponse response = NMI_RequestController.GetNMIRequestController.SendCustomerCCVaultRequest(ccNumber,ccExpiration,cvc, accountID,firstName,lastName,'add-customer','');
        if(response.Result == '100') {
            return createOrUpdateCustomerVaultData(response,accountID,'Credit_Card');
        } else {
            return 'FAIL - ' + response.Result + ' - ' + response.ResultText;
        }
    }
    
    public static String editACHVaultEntry(String accountName, String accountNumber, String routingNumber, String accountId, String firstName, String lastName, String vaultId){
        
        NMI_RequestController.X3StepResponse response = NMI_RequestController.GetNMIRequestController.SendCustomerACHVaultRequest(accountName,accountNumber,routingNumber, accountId, firstName,lastName,'update-customer',vaultId);
        System.debug(response);
        if(response.Result == '100'){
            return createOrUpdateCustomerVaultData(response,accountId,'ACH');
        } else {
            return 'FAIL - ' + response.Result + ' - ' + response.ResultText;
        }
    }
    
    public static String editCCVaultEntry(String ccNumber, String ccExpiration, String cvc, Id accountId, String firstName, String lastName, String vaultId){
        NMI_RequestController.X3StepResponse response = NMI_RequestController.GetNMIRequestController.SendCustomerCCVaultRequest(ccNumber,ccExpiration,cvc, accountID,firstName,lastName,'update-customer',vaultId);
        if(response.Result == '100') {
            return createOrUpdateCustomerVaultData(response,accountID,'Credit_Card');
        } else {
            return 'FAIL - ' + response.Result + ' - ' + response.ResultText;
        }
    }


    


    private static String createOrUpdateCustomerVaultData(NMI_RequestController.X3StepResponse response, String accountId, String pvRecordTypeDevName) {

        Payment_Vault__c pv = new Payment_Vault__c();

        if(String.isNotEmpty(response.CheckingAccountNumber))
            pv.Account_Number__c = response.CheckingAccountNumber;
        if(String.isNotEmpty(response.RoutingNumber))
            pv.Routing_Number__c = response.RoutingNumber;
        if(String.isNotEmpty(response.AccountName))
            pv.Account_Name__c = response.AccountName;

        if(String.isNotEmpty(response.CreditCardNumber))
            pv.Credit_Card_Number__c = response.CreditCardNumber;
        if(String.isNotEmpty(response.CreditCardExpiration))
            pv.Expiration_Date__c = response.CreditCardExpiration;

        pv.Organization_Household__c = accountId;
        pv.NMI_Customer_Vault_Number__c = response.CustomerVaultId;
        pv.RecordTypeId = UtilitiesSObject.getRecordTypeId(pvRecordTypeDevName,Payment_Vault__c.SObjectType);
        pv.NMI_Billing_ID__c = response.BillingId;
//        pv.Type__c = pvRecordTypeDevName == 'ACH' ? 'ACH' : 'Credit Card';
        System.debug('Record Type Dev Name: ' + pvRecordTypeDevName);
        System.debug('RECORD TYPE ID: ' + UtilitiesSObject.getRecordTypeId(pvRecordTypeDevName,Payment_Vault__c.SObjectType));

        upsert pv NMI_Customer_Vault_Number__c;

//        donation.Payment_Vault__c = pv.Id;
//        update donation;

        return pv.Id;

    }

}