/**
 * Created by UD Office Chris on 6/28/2018.
 */

public class AUTH_RequestController {

    public AUTH_AuthenticationCtrl AuthController {get; set;}
    public String Token {get; set;}

    @TestVisible private Payment_Adjustment__c paymentAdjustment {get; set;}

    public PageReference CancelPage {get; set;}

    public AUTH_RequestController(){
        this.AuthController = new AUTH_AuthenticationCtrl();
        this.CancelPage = Page.CongrComm_FinancialsHome;
    }

    public String GetURLTokenForMember(Decimal amount, Id contactId, String paymentId){

        String JSONBody = GetUserPaymentSubmissionJSONRequest(amount,contactId,paymentId);
        String tokenResponseBody = sendTokenRequest(JSONBody);
        String authToken = this.AuthController.setAccessToken(tokenResponseBody);
        this.Token = authToken;

        return authToken;
    }
    public String GetURLTokenForGuest(Decimal amount, String paymentId){

        String JSONBody = GetGuestPaymentSubmissionJSONRequest(amount,paymentId);
        String tokenResponseBody = sendTokenRequest(JSONBody);
        String authToken = this.AuthController.setAccessToken(tokenResponseBody);
        this.Token = authToken;

        return authToken;
    }
    public String SubmitForMemberPaymentURL(Decimal amount, Id contactId, String paymentId){

        String JSONBody = GetUserPaymentSubmissionJSONRequest(amount,contactId,paymentId);

        system.debug('JSON Body:' + JSONBody);
        String tokenResponseBody = sendTokenRequest(JSONBody);

        system.debug('Token Response: ');
        system.debug(tokenResponseBody);

        String authToken = this.AuthController.setAccessToken(tokenResponseBody);
        this.Token = authToken;

        String paymentURLResponseBody = sendRequestForURL(authToken);

        system.debug('Payment URL Response Body:  ');
        system.debug(paymentURLResponseBody);

        return paymentURLResponseBody;
    }

    public String GetGuestPaymentSubmissionJSONRequest(Decimal amount, String firstName, String lastName){

        //// collect merchant/transaction information

        //// collect current user information

        ////
        return null;
    }

    public String GetUserPaymentSubmissionJSONRequest(Decimal amount, Id contactId,String paymentId){

        AUTH_HostedPaymentJSONStruct struct = new AUTH_HostedPaymentJSONStruct();
        struct.getHostedPaymentPageRequest = new AUTH_HostedPaymentJSONStruct.cls_getHostedPaymentPageRequest();

        struct.getHostedPaymentPageRequest.merchantAuthentication = getAuthStruct(contactId);
        struct.getHostedPaymentPageRequest.transactionRequest = getTransactionStruct(amount,contactId,paymentId);


        JSONGenerator gen = JSON.createGenerator(true);

        gen.writeStartObject();
        gen.writeFieldName('getHostedPaymentPageRequest');
        gen.writeStartObject();

        WriteAuthDataToGenerator(gen,struct.getHostedPaymentPageRequest.merchantAuthentication);
        WriteTransactionDataToGenerator(gen,struct.getHostedPaymentPageRequest.transactionRequest);
        WriteHostedPaymentSettingStringToGenerator(gen);

        gen.writeEndObject();
        gen.writeEndObject();

        String requestBody = gen.getAsString();
        return requestBody;
    }

    public String GetGuestPaymentSubmissionJSONRequest(Decimal amount,String paymentId){

        AUTH_HostedPaymentJSONStruct struct = new AUTH_HostedPaymentJSONStruct();
        struct.getHostedPaymentPageRequest = new AUTH_HostedPaymentJSONStruct.cls_getHostedPaymentPageRequest();

        struct.getHostedPaymentPageRequest.merchantAuthentication = getAuthStruct();
        struct.getHostedPaymentPageRequest.transactionRequest = getGuestTransactionStruct(amount ,paymentId);


        JSONGenerator gen = JSON.createGenerator(true);

        gen.writeStartObject();
        gen.writeFieldName('getHostedPaymentPageRequest');
        gen.writeStartObject();

        WriteAuthDataToGenerator(gen,struct.getHostedPaymentPageRequest.merchantAuthentication);
        WriteTransactionDataToGenerator(gen,struct.getHostedPaymentPageRequest.transactionRequest);
        WriteHostedPaymentSettingStringToGenerator(gen);

        gen.writeEndObject();
        gen.writeEndObject();

        String requestBody = gen.getAsString();
        return requestBody;
    }

    @TestVisible private String sendRequestForURL(String token){

        HttpRequest request = new HttpRequest();
        Http http = new Http();

        request.setEndpoint('https://accept.authorize.net/payment/payment');
        request.setMethod('POST');
        request.setHeader('Access-Control-Request-Headers','content-type,method');
        request.setBody('token=' + token);

        try{
            HttpResponse response;
            if(!Test.isRunningTest()){
                response = http.send(request);
                if(response.getStatusCode() == 200){
                    return String.valueOf(response.getBody());
                }
            }
            else{
                return AUTH_AuthenticationCtrlTests.TEST_AUTH_TOKEN_JSON_RESPONSE;
            }

            system.debug(response.getStatusCode());

            return 'FAILURE';

        }
        catch(CalloutException ce){
            system.debug(ce.getMessage());
            return ce.getMessage();
        }
    }

    @TestVisible private String sendTokenRequest(String JSONbody){
        HttpRequest request = new HttpRequest();
        Http http = new Http();

        request.setEndpoint('https://api.authorize.net/xml/v1/request.api');
        request.setMethod('POST');
        request.setHeader('Access-Control-Request-Headers','content-type,method');
        request.setHeader('content-type','application/json');
        request.setBody(JSONbody);

        try{


            if(!Test.isRunningTest()) {
                HttpResponse response = http.send(request);
                system.debug(response.getBody());
                if (response.getStatusCode() == 200) {
                    return response.getBody();
                }
            }else{
                return AUTH_AuthenticationCtrlTests.TEST_AUTH_TOKEN_JSON_RESPONSE;
            }
            return 'FAILURE';

        }
        catch(CalloutException ce){
            system.debug(ce.getMessage());
            return ce.getMessage();
        }
    }

    @TestVisible private void WriteAuthDataToGenerator(JSONGenerator gen, AUTH_HostedPaymentJSONStruct.cls_merchantAuthentication authData){

        gen.writeFieldName('merchantAuthentication');
        gen.writeStartObject();
        gen.writeStringField('name',authData.name);
        gen.writeStringField('transactionKey',authData.transactionKey);
        gen.writeEndObject();
    }

    @TestVisible private void WriteTransactionDataToGenerator(JSONGenerator gen, AUTH_HostedPaymentJSONStruct.cls_transactionRequest struct){

        gen.writeFieldName('transactionRequest');
        gen.writeStartObject();
        gen.writeStringField('transactionType',struct.transactionType);
        system.debug('Struct Amt');
        system.debug(struct.amount);
        gen.writeStringField('amount',struct.amount);
        if(struct.profile != null)
            gen.writeObjectField('profile',struct.profile);
        if(struct.order != null)
            gen.writeObjectField('order',struct.order);
        if(struct.customer != null)
            gen.writeObjectField('customer',struct.customer);
        if(struct.billTo != null)
            WriteBillToStringToGenerator(gen,struct.billTo);

//        WriteSurchargeToGenerator(gen,struct.amount);


        gen.writeEndObject();
    }
    @TestVisible private void WriteBillToStringToGenerator(JSONGenerator gen, AUTH_HostedPaymentJSONStruct.cls_billTo billTo){

        gen.writeFieldName('billTo');
        gen.writeStartObject();
        if(billTo.firstName != null)
            gen.writeStringField('firstName',billTo.firstName);
        if(billTo.lastName != null)
            gen.writeStringField('lastName',billTo.lastName);
        if(billTo.company != null)
            gen.writeStringField('company',billTo.company);
        if(billTo.address != null)
            gen.writeStringField('address',billTo.address);
        if(billTo.city != null)
            gen.writeStringField('city',billTo.city);
        if(billTo.state != null)
            gen.writeStringField('state',billTo.state);
        if(billTo.zip != null)
            gen.writeStringField('zip',billTo.zip);
        if(billTo.country != null)
            gen.writeStringField('country',billTo.country);

        gen.writeEndObject();
    }

    @TestVisible private void WriteSurchargeToGenerator(JSONGenerator gen,String amountPaid){

        gen.writeFieldName('surcharge');
        gen.writeStartObject();
        gen.writeNumberField('amount',Double.valueOf(amountPaid) * .025);
        gen.writeStringField('description','Convenience Fee');

        gen.writeEndObject();
    }
    @TestVisible private void WriteHostedPaymentSettingStringToGenerator(JSONGenerator gen){

        gen.writeFieldName('hostedPaymentSettings');
        gen.writeStartObject();
        gen.writeFieldName('setting');
        gen.writeStartArray();

        /// array item 1

        if(UserInfo.getUserType().containsIgnoreCase('Guest')){
            WriteSettingToGenerator(gen,'hostedPaymentReturnOptions',new map<String,String>{'showReceipt'=>'false','url'=>'https://wisetemple.force.com/MemberCommunity' + Page.CongrComm_GuestEventThanks.getUrl(),
            'cancelUrlText'=>'Cancel','cancelUrl'=>'https://www.wisetemple.org/'});
        }
        else{
            WriteSettingToGenerator(gen,'hostedPaymentReturnOptions',new map<String,String>{'showReceipt'=>'false','url'=>'https://wisetemple.force.com/MemberCommunity' + Page.CongrComm_Reciept.getUrl(),
            'cancelUrlText'=>'Cancel','cancelUrl'=>'https://wisetemple.force.com/MemberCommunity' + CancelPage.getUrl()});
        }


        WriteSettingToGenerator(gen,'hostedPaymentButtonOptions',new map<String,String>{'text'=>'pay'});
        WriteSettingToGenerator(gen,'hostedPaymentStyleOptions',new map<String,String>{'bgColor'=>'c24c39'});
        WriteSettingToGenerator(gen,'hostedPaymentPaymentOptions',new map<String,String>{'cardCodeRequired'=>'false','showCreditCard'=>'true','showBankAccount'=>'true'});
        WriteSettingToGenerator(gen,'hostedPaymentSecurityOptions',new map<String,String>{'captcha'=>'false'});
        WriteSettingToGenerator(gen,'hostedPaymentShippingAddressOptions',new map<String,String>{'show'=>'false','required'=>'false'});
        WriteSettingToGenerator(gen,'hostedPaymentBillingAddressOptions',new map<String,String>{'show'=>'true','required'=>'false'});
        WriteSettingToGenerator(gen,'hostedPaymentCustomerOptions',new map<String,String>{'showEmail'=>'true','requiredEmail'=>'true','addPaymentProfile'=>'true'});
        WriteSettingToGenerator(gen,'hostedPaymentOrderOptions',new map<String,String>{'show'=>'true','merchantName'=>'Isaac Wise Temple'});
        WriteSettingToGenerator(gen,'hostedPaymentIFrameCommunicatorUrl',new map<String,String>{'url'=>'https://wisetemple.force.com/MemberCommunity' + Page.CongrComm_AUTHiFrameCommunicator.getUrl()});

        gen.writeEndArray();
        gen.writeEndObject();
    }

    @TestVisible private void WriteSettingToGenerator(JSONGenerator gen, String settingName, map<String,String> settingValueMap){

        gen.writeStartObject();
        gen.writeStringField('settingName',settingName);
        String settingValue = '{';
        for(String curKey : settingValueMap.keySet()){
            String curKeyValue = settingValueMap.get(curKey);
            if(curKeyValue == 'true' || curKeyValue == 'false'){
                settingValue += '\"' + curKey + '\":' + settingValueMap.get(curKey) + ',';
            }
            else{
                settingValue += '\"' + curKey + '\":\"' + settingValueMap.get(curKey) + '\",';
            }
        }
        settingValue = settingValue.substring(0,settingValue.length() - 1);
        settingValue += '}';
        gen.writeStringField('settingValue',settingValue);
        gen.writeEndObject();
    }


    @TestVisible private AUTH_HostedPaymentJSONStruct.cls_merchantAuthentication getAuthStruct(Id contactId){

        AUTH_HostedPaymentJSONStruct.cls_merchantAuthentication authData = new AUTH_HostedPaymentJSONStruct.cls_merchantAuthentication();
        authData.name = this.AuthController.MERCHANT_ID;
        authData.transactionKey = this.AuthController.TRANSACTION_ID;
        authData.refId = contactId;
        return authData;
    }

    @TestVisible private AUTH_HostedPaymentJSONStruct.cls_merchantAuthentication getAuthStruct(){

        AUTH_HostedPaymentJSONStruct.cls_merchantAuthentication authData = new AUTH_HostedPaymentJSONStruct.cls_merchantAuthentication();
        authData.name = this.AuthController.MERCHANT_ID;
        authData.transactionKey = this.AuthController.TRANSACTION_ID;
        return authData;
    }

    @TestVisible private AUTH_HostedPaymentJSONStruct.cls_transactionRequest getTransactionStruct(Decimal amount,Id contactId,String paymentId){

        AUTH_HostedPaymentJSONStruct.cls_transactionRequest transactionData = new AUTH_HostedPaymentJSONStruct.cls_transactionRequest();
        transactionData.amount = String.valueOf(amount);
        system.debug(transactionData.Amount);
        transactionData.transactionType = AUTH_Constants.HOSTED_PAYMENT_TRANSACTION_TYPE;

        Contact theContact = retrieveContact(contactId);

        //Todo review code: Added By Kritik
        Contact loggedInUserContact = new Contact();
        loggedInUserContact = UtilitiesUsers.GetContactForCommunityUser(UserInfo.getUserId());
        /*if(loggedInUserContact!=null) {

            loggedInUserContact = [
                    SELECT id, FirstName, LastName, MailingStreet, MailingCity, MailingState, MailingPostalCode,
                            Account.BillingStreet, Account.BillingCity, Account.BillingState, Account.BillingPostalCode
                    FROM Contact
                    WHERE id = :loggedInUserContact.Id
                    LIMIT 1
            ];
        }*/

        //System.debug('loggedInUserContact '+ loggedInUserContact );

        AUTH_HostedPaymentJSONStruct.cls_customer custEmail = new AUTH_HostedPaymentJSONStruct.cls_customer();
        custEmail.email = theContact.Email;

        AUTH_HostedPaymentJSONStruct.cls_billTo billToStruct = new AUTH_HostedPaymentJSONStruct.cls_billTo();
        if(loggedInUserContact != null && theContact!=null && theContact.Id !=null ) {
            billToStruct.firstName = theContact.FirstName;
            billToStruct.lastName = theContact.LastName;
            billToStruct.address = theContact.Account.BillingStreet;
            billToStruct.city = theContact.Account.BillingCity;
            billToStruct.state = theContact.Account.BillingState;
            billToStruct.zip = theContact.Account.BillingPostalCode;
        } else {
            billToStruct.firstName = theContact.FirstName;
            billToStruct.lastName = theContact.LastName;
            billToStruct.address = theContact.MailingStreet;
            billToStruct.city = theContact.MailingCity;
            billToStruct.state = theContact.MailingState;
            billToStruct.zip = theContact.MailingPostalCode;

        }
        billToStruct.country = 'USA';

        transactionData.billTo = billToStruct;
        transactionData.customer = custEmail;

        transactionData.order = new AUTH_HostedPaymentJSONStruct.cls_order();
        transactionData.order.invoiceNumber = paymentId;
        String description = getDescriptionValue(paymentId);
        if(String.isNotBlank(description)){
            transactionData.order.description = description;
        }

        return transactionData;
    }

    @TestVisible private AUTH_HostedPaymentJSONStruct.cls_transactionRequest getGuestTransactionStruct(Decimal amount,String paymentId){

        AUTH_HostedPaymentJSONStruct.cls_transactionRequest transactionData = new AUTH_HostedPaymentJSONStruct.cls_transactionRequest();
        transactionData.amount = String.valueOf(amount);
        system.debug(transactionData.Amount);
        transactionData.transactionType = AUTH_Constants.HOSTED_PAYMENT_TRANSACTION_TYPE;

        transactionData.order = new AUTH_HostedPaymentJSONStruct.cls_order();
        transactionData.order.invoiceNumber = paymentId;
        Payment_Adjustment__c payAdj = retrievePayment(paymentId);
        if(payAdj != null)
            transactionData.order.description = payAdj.Payment_Receipt_Name__c;

        AUTH_HostedPaymentJSONStruct.cls_billTo billToStruct = new AUTH_HostedPaymentJSONStruct.cls_billTo();
        AUTH_HostedPaymentJSONStruct.cls_customer custEmail = new AUTH_HostedPaymentJSONStruct.cls_customer();

        System.debug('payAdj.Contact__r.Id ' +payAdj.Contact__r.Id );

        if(payAdj != null && payAdj.Contact__r.Id != null ) {
            billToStruct.firstName = payAdj.Contact__r.FirstName;
            billToStruct.lastName = payAdj.Contact__r.LastName;
            billToStruct.address = payAdj.Contact__r.MailingStreet;
            billToStruct.city = payAdj.Contact__r.MailingCity;
            billToStruct.state = payAdj.Contact__r.MailingState;
            billToStruct.zip = payAdj.Contact__r.MailingPostalCode;

            transactionData.billTo = billToStruct;

            custEmail.email = payAdj.Contact__r.Email;
            transactionData.customer = custEmail;

            System.debug('payAdj.Contact__r ' +payAdj.Contact__r );

        }

        return transactionData;
    }

    @TestVisible private String getDescriptionValue(String paymentId){

        String eventDescriptionString = getEventDescriptionString(paymentId);
        if(String.isNotBlank(eventDescriptionString)){
            return eventDescriptionString;
        }

        String donationDescriptionString = getDonationString(paymentId);
        if(String.isNotBlank(donationDescriptionString)){
            return donationDescriptionString;
        }

        return 'Payment Towards Account';
    }

    @TestVisible private String getEventDescriptionString(String paymentId){

        try{
//            Payment_Adjustment__c payment = [SELECT Id FROM Payment_Adjustment__c WHERE Id = :paymentId];'
            String paymentName = '%' + paymentId + '%';
            list<Scheduled_Payment__c> scheduledPayments = [SELECT Id,Assessment__c FROM Scheduled_Payment__c WHERE Id in (SELECT Scheduled_Payment__c FROM Payment_Adjustment_Allocation__c WHERE Payment_Adjustment__r.Name like :paymentName)];
            Assessment__c eventAssessment = [SELECT Id,Program__r.Name FROM Assessment__c WHERE RecordTypeId = :UtilitiesSObject.getRecordTypeId('Event_Assessment',Assessment__c.SObjectType) AND Id in :getAssessmentIds(scheduledPayments) AND Program__c != null limit 1];
            return eventAssessment.Program__r.Name;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return '';
        }
    }

    @TestVisible private String getDonationString(String paymentId){

        try{
            String paymentName = '%' + paymentId + '%';
            list<Scheduled_Payment__c> scheduledPayments = [SELECT Id,Assessment__c FROM Scheduled_Payment__c WHERE Id in (SELECT Scheduled_Payment__c FROM Payment_Adjustment_Allocation__c WHERE Payment_Adjustment__r.Name like :paymentName)];
            Assessment__c eventAssessment = [SELECT Id,Designation__r.Name FROM Assessment__c WHERE RecordTypeId = :UtilitiesSObject.getRecordTypeId('Assessment',Assessment__c.SObjectType) AND Id in :getAssessmentIds(scheduledPayments) AND Designation__r.Designation_Category__c = 'Funds' limit 1];
            return eventAssessment.Designation__r.Name;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return '';
        }
    }

    @TestVisible private set<Id> getAssessmentIds(list<Scheduled_Payment__c> scheduledPayments){
        set<Id> returnSet = new set<Id>();
        for(Scheduled_Payment__c curSched : scheduledPayments){
            if(String.isNotBlank(curSched.Assessment__c)){
                returnSet.add(curSched.Assessment__c);
            }
        }
        return returnSet;
    }

    @TestVisible private Contact retrieveContact(Id contactId){
        try{
            Contact returnContact = [SELECT Id,Email,FirstName,LastName,MailingStreet,MailingCity,MailingState,MailingPostalCode,
                    Account.BillingStreet, Account.BillingCity, Account.BillingState, Account.BillingPostalCode FROM Contact WHERE Id = :contactId];
            return returnContact;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return null;
        }
    }

    @TestVisible private Payment_Adjustment__c retrievePayment(String paymentId){
        try{
            String nameCompare = '\'%' + paymentId + '%\'';
           // Payment_Adjustment__c returnPayment = [SELECT Id,Payment_Receipt_Name__c, Contact__r.firstName, Contact__r.lastName, Contact__r.Email,  Contact__r.MailingStreet, Contact__r.MailingCity,  Contact__r.MailingState,  Contact__r.MailingPostalCode, Contact__r.Id  FROM Payment_Adjustment__c WHERE Name like :nameCompare];

            Payment_Adjustment__c returnPayment = Database.query('SELECT Id,Amount__c,Payment_Receipt_Name__c, Contact__r.firstName, Contact__r.lastName, Contact__r.Email,  Contact__r.MailingStreet, Contact__r.MailingCity,  Contact__r.MailingState,  Contact__r.MailingPostalCode, Contact__r.Id  FROM Payment_Adjustment__c WHERE Name LIKE \'%' + paymentId + '\'');

            return returnPayment;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return null;
        }
    }


}