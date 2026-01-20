/**
 * @description Created by Chris Gibson on 3/28/2020.
 */
public without sharing class NMI_RequestController {

    //// Singleton for connection controller
    public static NMI_Requestcontroller GetNMIRequestController {
        get {
            if (theRequestController == null) {
                theRequestController = new NMI_Requestcontroller();
                return theRequestController;
            }

            return theRequestController;
        }
    }
    private static NMI_Requestcontroller theRequestController;

    /**
     * @description This is the 0 param constructor for the NMI Request Controller
     *
     * @author Chris Gibson
     *
     * @date 03.28.2020
     */
    public NMI_Requestcontroller() {
    }

    public TransactionQueryResponse GetTransactionData(String transactionId) {

        if (String.isEmpty(transactionId)) {
            return null;
        }

        Dom.XmlNode xmlResponse = NMI_ConnectionController.GetNMIConnectionController.GetTransactionData(transactionId);
        return populateTransactionQueryResponse(new TransactionQueryResponse(), xmlResponse);
    }

//    public X3StepResponse SendPaymentVaultRequest()

    //// ---------------------------- Recurring Payment Request Methods ------------------------- \\\\

//    public X3StepResponse SendRecurringPaymentRequest(String transactionType, String donationId, String paymentVaultId, String transactionId){
//
//        system.debug('Sending Recurring Payment Request/Transaction');
//        Donation__c theDonation = NMI_Utilities.GetDonation(donationId);
//        Payment_Vault__c vaultEntry = NMI_Utilities.GetPaymentVault(paymentVaultId);
//
//        NMI_RecurringWrapper recurringWrapper = NMI_Utilities.CreateRecurringWrapper(transactionType, vaultEntry, theDonation);
//        recurringWrapper.SourceTransactionId = transactionId;
//
//        return processRecurringRequest(recurringWrapper, theDonation);
//    }

//    private X3StepResponse processRecurringRequest(NMI_RecurringWrapper recurringWrapper, Donation__c theDonation) {
//
//        String redirectUrl = NMI_ConnectionController.GetNMIConnectionController.GetRedirectUrl(recurringWrapper);
//
//        String confirmationTokenURL = NMI_ConnectionController.GetNMIConnectionController.SendStep2Data('', redirectUrl);
//        String tokenId = confirmationTokenURL.split('token-id=')[1];
//
//        Dom.XmlNode xmlResult = handleConfirmationResponse(tokenId);
////        return processResult(xmlResult,'transaction-id');
//
//        X3StepResponse response = new X3StepResponse();
//        Boolean isResponseSuccessful = processResult(xmlResult);
//        if(isResponseSuccessful){
//            populate3StepResponse(response,xmlResult);
//        }
//
//        return response;
//    }


    //// ---------------------------- Customer Vault Payment Request Methods ------------------------- \\\\

    public X3StepResponse SendCustomerCCVaultRequest(String ccNumber, String ccExpiration, String cvc, String accountId, String firstName, String lastName, String transactionType, String vaultId) {
        Account theAccount = NMI_Utilities.GetAccount(accountId);
        Payment_Vault__c paymentVault = NMI_Utilities.GetPaymentVault(vaultId);
        String POSTFormURL = SendVaultRequest(theAccount, transactionType, paymentVault);

        String responseDataWithTokenId = SubmitNewPaymentDataToNMI(ccNumber, ccExpiration, cvc, firstName, lastName, POSTFormURL, 'CC');
        if (responseDataWithTokenId == 'FAIL' || !responseDataWithTokenId.contains('token-id=')) {
            return null;
        }

        String tokenId = responseDataWithTokenId.split('token-id=')[1];
        X3StepResponse response = new X3StepResponse();
        Dom.XmlNode responseDataWithCustomerVaultId = handleConfirmationResponse(tokenId);

        Boolean isResponseSuccessful = processResult(responseDataWithCustomerVaultId);
        if (isResponseSuccessful) {
            String ccNumberFromResponse = responseDataWithCustomerVaultId.getChildElement('billing', null).getChildElement('cc-number', null).getText();
            String ccExpirationFromResponse = responseDataWithCustomerVaultId.getChildElement('billing', null).getChildElement('cc-exp', null).getText();

            if (String.isNotEmpty(ccNumberFromResponse))
                response.CreditCardNumber = ccNumberFromResponse;
            if (String.isNotEmpty(ccExpirationFromResponse))
                response.CreditCardExpiration = ccExpirationFromResponse;
        }

        populate3StepResponse(response, responseDataWithCustomerVaultId);

        return response;
    }

    public X3StepResponse SendCustomerACHVaultRequest(String accountName, String accountNumber, String routingNumber, String accountId, String firstName, String lastName, String transactionType, String vaultId) {
        Account TheAccount = NMI_Utilities.GetAccount(accountId);
        Payment_Vault__c paymentVault = NMI_Utilities.GetPaymentVault(vaultId);
        String POSTFormURL = SendVaultRequest(TheAccount, transactionType, paymentVault);
        String responseDataWithTokenId = SubmitNewPaymentDataToNMI(accountName, routingNumber, accountNumber, firstName, lastName, POSTFormURL, 'ACH');
        System.debug(responseDataWithTokenId);
        if (responseDataWithTokenId == 'FAIL' || !responseDataWithTokenId.contains('token-id=')) {
            System.debug('FAIL');
            return null;
        }

        String tokenId = responseDataWithTokenId.split('token-id=')[1];
        System.debug('Token ID:' + tokenId);
        X3StepResponse response = new X3StepResponse();
        Dom.XmlNode responseDataWithCustomVaultId = handleConfirmationResponse(tokenId);
        System.debug('RESPONSE DATA WITH CUSTOM VAULT ID');

        Boolean isResponseSuccessful = processResult(responseDataWithCustomVaultId);
        if (isResponseSuccessful) {
            String accountNumberFromResponse = responseDataWithCustomVaultId.getChildElement('billing', null).getChildElement('account-number', null).getText();
            String routingNumberFromResponse = responseDataWithCustomVaultId.getChildElement('billing', null).getChildElement('routing-number', null).getText();
            String accountNameFromResponse = responseDataWithCustomVaultId.getChildElement('billing', null).getChildElement('account-name', null).getText();
            String billingId = responseDataWithCustomVaultId.getChildElement('billing', null).getChildElement('billing-id', null).getText();

            if (String.isNotEmpty(accountNameFromResponse))
                response.AccountName = accountNameFromResponse;
            if (String.isNotEmpty(routingNumberFromResponse))
                response.RoutingNumber = routingNumberFromResponse;
            if (String.isNotEmpty(accountNumberFromResponse))
                response.CheckingAccountNumber = accountNumberFromResponse;
            if (String.isNotEmpty(billingId))
                response.BillingId = billingId;
        }
        populate3StepResponse(response, responseDataWithCustomVaultId);

        return response;
    }

    public void SendDeleteVaultRequest(String vaultNumber) {
//        Payment_Vault__c paymentVault = NMI_Utilities.GetPaymentVault(vaultId);
        NMI_CustomerVaultWrapper vaultWrapper = new NMI_CustomerVaultWrapper('delete-customer');
        vaultWrapper.CustomerVaultId = vaultNumber;
        vaultWrapper.ApiKey = NMI_Utilities.API_KEY;

        try {
            String xmlString = vaultWrapper.GetXMLString();
            String endpoint = NMI_Utilities.BASE_URL + NMI_Utilities.REDIRECT_ENDPOINT;
            Http http = new Http();
            HttpRequest httpRequest = new HttpRequest();
            httpRequest.setHeader('Authorization', NMI_Utilities.API_KEY);
            httpRequest.setHeader('Content-Type', NMI_Utilities.CONTENT_TYPE);
            httpRequest.setMethod('DELETE');
            httpRequest.setEndpoint(endpoint);
            httpRequest.setBody(xmlString);

            HttpResponse response = http.send(httpRequest);
            System.debug(response.getBody());
        } catch (Exception e) {
            System.debug(e.getMessage());
        }

    }

    public void SendEmailUpdateVaultRequest(String email, String vaultNumber) {
        NMI_CustomerVaultWrapper vaultWrapper = new NMI_CustomerVaultWrapper('update-billing');
        vaultWrapper.CustomerVaultId = vaultNumber;
        vaultWrapper.ApiKey = NMI_Utilities.API_KEY;
        vaultWrapper.Billing = new NMI_Utilities.Billing();
        vaultWrapper.Billing.Email = email;

        String xmlString = vaultWrapper.GetXMLString();
        System.debug('xmlString: ' + xmlString);
        String endpoint = NMI_Utilities.BASE_URL + NMI_Utilities.REDIRECT_ENDPOINT;
        Http http = new Http();
        HttpRequest httpRequest = new HttpRequest();
        httpRequest.setHeader('Authorization', NMI_Utilities.API_KEY);
        httpRequest.setHeader('Content-Type', NMI_Utilities.CONTENT_TYPE);
        httpRequest.setMethod('POST');
        httpRequest.setEndpoint(endpoint);
        httpRequest.setBody(xmlString);

        HttpResponse response = http.send(httpRequest);
        System.debug(response.getBody());
    }

    public static String SendVaultRequest(Account acc, String transactionType, Payment_Vault__c paymentVault) {

        if (acc == null) {
            return '';
        }

        NMI_CustomerVaultWrapper vaultWrapper = NMI_Utilities.CreateVaultWrapper(acc, transactionType, paymentVault);

        if (paymentVault != null) {
            vaultWrapper.CustomerVaultId = paymentVault.NMI_Customer_Vault_Number__c;
            vaultWrapper.Billing.BillingId = paymentVault.NMI_Billing_Id__c;
        }

        NMI_ConnectionController connectionController = new NMI_ConnectionController();
        String redirectUrl = connectionController.GetRedirectUrl(vaultWrapper);
        system.debug(redirectUrl);
        return redirectUrl;
    }

//    public X3StepResponse SendCustomerVaultRequest(String accountName, String accountNumber, String routingNumber, String firstName, String lastName, String postFormURL, String transactionType, String paymentType){
//
//        String responseDataWithTokenId = SubmitNewPaymentDataToNMI(accountName, accountNumber, routingNumber, firstName, lastName, postFormURL,paymentType);
//
//        if (responseDataWithTokenId == 'FAIL' || !responseDataWithTokenId.contains('token-id=')) {
//            return null;
//        }
//
//        String tokenId = responseDataWithTokenId.split('token-id=')[1];
//        X3StepResponse response = new X3StepResponse();
//        Dom.XmlNode responseDataWithCustomVaultId = handleConfirmationResponse(tokenId);
//
//        Boolean isResponseSuccessful = processResult(responseDataWithCustomVaultId);
//        if(isResponseSuccessful){
//            populateSuccessfulResponse(responseDataWithCustomVaultId, response, paymentType);
//        }
//
//        populate3StepResponse(response,responseDataWithCustomVaultId);
//
//        return response;
//    }

    private void populateSuccessfulResponse(Dom.XmlNode responseDataWithCustomVaultId, X3StepResponse response, String paymentType) {
        if (paymentType == 'ACH') {
            String accountNumberFromResponse = responseDataWithCustomVaultId.getChildElement('billing', null).getChildElement('account-number', null).getText();
            String routingNumberFromResponse = responseDataWithCustomVaultId.getChildElement('billing', null).getChildElement('routing-number', null).getText();
            String accountNameFromResponse = responseDataWithCustomVaultId.getChildElement('billing', null).getChildElement('account-name', null).getText();
            String billingId = responseDataWithCustomVaultId.getChildElement('billing', null).getChildElement('billing-id', null).getText();

            if (String.isNotEmpty(accountNameFromResponse))
                response.AccountName = accountNameFromResponse;
            if (String.isNotEmpty(routingNumberFromResponse))
                response.RoutingNumber = routingNumberFromResponse;
            if (String.isNotEmpty(accountNumberFromResponse))
                response.CheckingAccountNumber = accountNumberFromResponse;
            if (String.isNotEmpty(billingId))
                response.BillingId = billingId;
        }
    }


    public static String SubmitNewPaymentDataToNMI(String paymentparam1, String paymentparam2, String paymentparam3, String firstName, String lastName, String endpoint, String paymentType) {

        NMI_ConnectionController connectionController = new NMI_ConnectionController();
        if (paymentType == 'CC') {
            String requestBody = getStep2Body(new NMI_Utilities.CreditCardParams(paymentparam1, paymentparam2, paymentparam3, firstName, lastName));
            system.debug(requestBody);
            String responseData = connectionController.SendStep2Data(requestBody, endpoint);
            system.debug(responseData);
            return responseData;
        } else {
            String requestBody = getStep2Body(new NMI_Utilities.ACHParams(paymentparam1, paymentparam2, paymentparam3, firstName, lastName));
            system.debug('REQUEST BODY: ' + requestBody);
            String responseData = connectionController.SendStep2Data(requestBody, endpoint);
            system.debug('RESPONSE DATA: ' + responseData);
            return responseData;
        }
    }

    private static String getStep2Body(NMI_Utilities.CreditCardParams ccParam) {

        String body = 'billing-cc-number=' + ccParam.CCNumber + '&billing-cc-exp=' + ccParam.Expiration + '&cvv=' + ccParam.CVV + '&billing-first-name=' + ccParam.firstName + '&billing-last-name=' + ccParam.lastName;
        return body;
    }

    private static String getStep2Body(NMI_Utilities.ACHParams achParam) {

        String body = 'billing-account-name=' + achParam.AccountName + '&billing-account-number=' + achParam.CheckingNumber + '&billing-routing-number=' + achParam.RoutingNumber + '&billing-first-name=' + achParam.firstName + '&billing-last-name=' + achParam.lastName ;
        return body;
    }


    //// ---------------------------- One Time Payment Request Methods ------------------------- \\\\


//    public X3StepResponse SendOneTimeRecurringPaymentRequest(String transactionType, String donationId, String paymentVaultId, String billingMethod){
//
//        system.debug('Sending One Time Payment Request/Transaction');
//        Donation__c theDonation = NMI_Utilities.GetDonation(donationId);
//        Pay vaultEntry = NMI_Utilities.GetPaymentVault(paymentVaultId);
//
//        NMI_TransactionalWrapper transactionalWrapper = NMI_Utilities.CreateOneTimePaymentWrapper(transactionType, theDonation, vaultEntry, billingMethod);
//
//        return sendTransactionalWrapper(transactionalWrapper, theDonation,'');
//    }
//
    public X3StepResponse SendOneTimePaymentRequestWithExistingVault(String transactionType, String paymentVaultId, String billingMethod, Double paymentAmount) {
        System.debug('Sending One Time Payment Request/Transaction');
        Payment_Vault__c vaultEntry = NMI_Utilities.GetPaymentVault(paymentVaultId);
        NMI_TransactionalWrapper transactionalWrapper = NMI_Utilities.CreateOneTimePaymentWrapper(transactionType, paymentAmount, billingMethod, vaultEntry);

        return sendTransactionalWrapper(transactionalWrapper, '');
    }


    /**
     * @description Method to generate secure url (Step 1)
     *
     * @param transactionalWrapper
     *
     * @return
     */
    public String getSecureURLFromFirstStep(NMI_TransactionalWrapper transactionalWrapper) {
        String redirectUrl = NMI_ConnectionController.GetNMIConnectionController.GetRedirectUrl(transactionalWrapper);
        return redirectUrl;
    }


    /**
     * @description
     * @param body
     * @param secureURL
     *
     * @return
     */
    public X3StepResponse sendOneTimePaymentRequest(String body, String secureURL) {
        String confirmationTokenURL = NMI_ConnectionController.GetNMIConnectionController.SendStep2Data(body, secureURL);

        System.debug('confirmationTokenURL = ' + confirmationTokenURL);

        String tokenId = confirmationTokenURL.split('token-id=')[1];

        Dom.XmlNode xmlResult = handleConfirmationResponse(tokenId);
        X3StepResponse response = new X3StepResponse();
        Boolean isResponseSuccessful = processResult(xmlResult);
        populate3StepResponse(response, xmlResult);

        return response;
    }


    public X3StepResponse SendOneTimePaymentRequest(NMI_TransactionalWrapper transactionalWrapper, String body) {
        return sendTransactionalWrapper(transactionalWrapper, body);
    }

    private X3StepResponse sendTransactionalWrapper(NMI_TransactionalWrapper transactionalWrapper, String body) {

        String redirectUrl = NMI_ConnectionController.GetNMIConnectionController.GetRedirectUrl(transactionalWrapper);

        String confirmationTokenURL = NMI_ConnectionController.GetNMIConnectionController.SendStep2Data(body, redirectUrl);
        System.debug('confirmationTokenURL = ' + confirmationTokenURL);

        String tokenId = confirmationTokenURL.split('token-id=')[1];

        Dom.XmlNode xmlResult = handleConfirmationResponse(tokenId);
        X3StepResponse response = new X3StepResponse();
        Boolean isResponseSuccessful = processResult(xmlResult);
        populate3StepResponse(response, xmlResult);

        return response;
    }

    ///// --------------------------- Private Helper Methods ---------------------------------- \\\\

    private X3StepResponse populate3StepResponse(X3StepResponse response, Dom.XmlNode xmlResult) {

        if (xmlResult.getChildElement('transaction-id', null) != null)
            response.TransactionId = xmlResult.getChildElement('transaction-id', null).getText();
        if (xmlResult.getChildElement('subscription-id', null) != null)
            response.SubscriptionId = xmlResult.getChildElement('subscription-id', null).getText();
        if (xmlResult.getChildElement('result-code', null) != null)
            response.Result = xmlResult.getChildElement('result-code', null).getText();
        if (xmlResult.getChildElement('result-text', null) != null)
            response.ResultText = xmlResult.getChildElement('result-text', null).getText();
        if (xmlResult.getChildElement('action-type', null) != null)
            response.ActionType = xmlResult.getChildElement('action-type', null).getText();
        if (xmlResult.getChildElement('customer-id', null) != null)
            response.CustomerId = xmlResult.getChildElement('customer-id', null).getText();
        if (xmlResult.getChildElement('avs-result', null) != null)
            response.AVSResult = xmlResult.getChildElement('avs-result', null).getText();
        if (xmlResult.getChildElement('authorization-code', null) != null)
            response.AuthorizationCode = xmlResult.getChildElement('authorization-code', null).getText();
        if (xmlResult.getChildElement('customer-vault-id', null) != null)
            response.CustomerVaultId = xmlResult.getChildElement('customer-vault-id', null).getText();
        if (xmlResult.getChildElement('billing', null) != null && xmlResult.getChildElement('billing', null).getChildElement('billing-id', null) != null)
            response.BillingId = xmlResult.getChildElement('billing', null).getChildElement('billing-id', null).getText();
        if (xmlResult.getChildElement('billing', null) != null && xmlResult.getChildElement('billing', null).getChildElement('cc-number', null) != null)
            response.CreditCardNumber = xmlResult.getChildElement('billing', null).getChildElement('cc-number', null).getText();
        if (xmlResult.getChildElement('billing', null) != null && xmlResult.getChildElement('billing', null).getChildElement('cc-exp', null) != null)
            response.CreditCardExpiration = xmlResult.getChildElement('billing', null).getChildElement('cc-exp', null).getText();
        if (xmlResult.getChildElement('billing', null) != null && xmlResult.getChildElement('billing', null).getChildElement('account-name', null) != null)
            response.AccountName = xmlResult.getChildElement('billing', null).getChildElement('account-name', null).getText();
        if (xmlResult.getChildElement('billing', null) != null && xmlResult.getChildElement('billing', null).getChildElement('account-number', null) != null)
            response.CheckingAccountNumber = xmlResult.getChildElement('billing', null).getChildElement('account-number', null).getText();


        return response;
    }
    private TransactionQueryResponse populateTransactionQueryResponse(TransactionQueryResponse response, Dom.XmlNode xmlResult) {

        if (xmlResult.getChildElement('transaction_id', null) != null)
            response.TransactionId = xmlResult.getChildElement('transaction_id', null).getText();
        if (xmlResult.getChildElement('condition', null) != null)
            response.Condition = xmlResult.getChildElement('condition', null).getText();
        if (xmlResult.getChildElement('authorization_code', null) != null)
            response.AuthorizationCode = xmlResult.getChildElement('authorization_code', null).getText();
        if (xmlResult.getChildElement('order_description', null) != null)
            response.OrderDescription = xmlResult.getChildElement('order_description', null).getText();
        if (xmlResult.getChildElement('customerid', null) != null)
            response.CustomerId = xmlResult.getChildElement('customerid', null).getText();
        if (xmlResult.getChildElement('cc_hash', null) != null)
            response.CCHash = xmlResult.getChildElement('cc_hash', null).getText();
        if (xmlResult.getChildElement('avs_response', null) != null)
            response.AVSResponse = xmlResult.getChildElement('avs_response', null).getText();
        if (xmlResult.getChildElement('processor_id', null) != null)
            response.ProcessorId = xmlResult.getChildElement('processor_id', null).getText();
        if (xmlResult.getChildElement('entry_mode', null) != null)
            response.EntryMode = xmlResult.getChildElement('entry_mode', null).getText();
        if (xmlResult.getChildElement('cc_bin', null) != null)
            response.CCbin = xmlResult.getChildElement('cc_bin', null).getText();
        if (xmlResult.getChildElement('cc_type', null) != null)
            response.CCtype = xmlResult.getChildElement('cc_type', null).getText();

        return response;
    }

    private Dom.XmlNode handleConfirmationResponse(String tokenId) {
        NMI_ConfirmationWrapper confirmWrapper = new NMI_ConfirmationWrapper();
        confirmWrapper.ApiKey = NMI_Utilities.API_KEY;
        confirmWrapper.TokenId = tokenId;
        Dom.XmlNode xmlResponse = NMI_ConnectionController.GetNMIConnectionController.GetConfirmationXmlResponse(NMI_Utilities.CreateConfirmationWrapper(tokenId));
        return xmlResponse;
    }

    private Boolean processResult(Dom.XmlNode xmlResponse) {
        if (xmlResponse.getChildElement('result-code', null) != null) {
            String resultCode = xmlResponse.getChildElement('result-code', null).getText();
            if (resultCode == '100') {
                return true;
            } else {
                return false;
            }
        }
        return false;
    }

    public class X3StepResponse {
        public String Result { get; set; }
        public String ResultText { get; set; }
        public String SubscriptionId { get; set; }
        public String TransactionId { get; set; }
        public String CustomerVaultId { get; set; }
        public String BillingId { get; set; }
        public String CreditCardNumber { get; set; }
        public String CreditCardExpiration { get; set; }
        public String CreditCardCVV { get; set; }
        public String AccountName { get; set; }
        public String CheckingAccountNumber { get; set; }
        public String RoutingNumber { get; set; }
        public String ActionType { get; set; }
        public String CustomerId { get; set; }
        public String AVSResult { get; set; }
        public String AuthorizationCode { get; set; }

        public Payment_Adjustment__c Payment { get; set; }
    }


    public class TransactionQueryResponse {

        public String TransactionId { get; set; }
        public String Condition { get; set; }
        public String AuthorizationCode { get; set; }
        public String OrderDescription { get; set; }
        public String CustomerId { get; set; }
        public String CCHash { get; set; }
        public String AVSResponse { get; set; }
        public String ProcessorId { get; set; }
        public String EntryMode { get; set; }
        public String CCbin { get; set; }
        public String CCtype { get; set; }

    }


}