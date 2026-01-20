/**
 * Created by Kritik Garg on 30-05-2020.
 */

public without sharing class CongrComm_NMIPaymentProcessorCtrl {

    public Boolean hasErrors { get; set; }
    public String errorString { get; set; }

    public String firstName { get; set; }
    public String lastName { get; set; }
    public String emailAddress { get; set; }
    public String phoneNumber { get; set; }

    public String billingStreet { get; set; }
    public String billingCity { get; set; }
    public String billingState { get; set; }
    public String billingZip { get; set; }
    public String billingCountry { get; set; }

    //Credit Card
    public String creditCard { get; set; }
    public String expirationDate { get; set; }
    public String cvc { get; set; }

    //ACH
    public String accountName { get; set; }
    public String accountNumber { get; set; }
    public String routingNumber { get; set; }

    public String selectedPaymentMethod { get; set; }  //ACH or CC
    public Payment_Vault__c vaultToEdit { get; set; }
    public Boolean isEditingVault { get; set; }
    public String paymentNumber { get; set; }
    public Boolean isGuest { get; set; }


    //<!--                            6LeFyUQhAAAAAG7-W1qTSj1E7Q5PDLzXn6V-9c7- -->
    public String CaptchaSiteKey {
        get {
            return UtilitiesUsers.GetIsSandboxEnvironment() ? '6LeFyUQhAAAAAG7-W1qTSj1E7Q5PDLzXn6V-9c7-' : '6LerrEQhAAAAABvXj3fdU6FCP6kHhfWFwUkQ_RJ3';
        }
    }

    public String paId { get; set; }
    public Decimal paymentAdjustmentAmount { get; set; }
    public Decimal onlineFee {get; set;}

    public String secureURLtoPostFromStep1 { get; set; }

    private Contact curContact { get; set; }

    public Boolean shouldDisplayPaymentOptions { get; set; }
    private Boolean shouldRedirect = true;
    private Boolean isSavingAndMakingPayment = false;
    private NMI_RequestController.X3StepResponse paymentResponse { get; set; }
    private static Id creditCardFeeDesignationId {
        get {
            return [
                    SELECT Id
                    FROM Designation__c
                    WHERE Designation_Description__c = 'Credit Card Fees'
            ].Id;
        }
        set;
    }

    public List<SelectOption> getPaymentOptions() {

        List<selectOption> options = new List<selectOption>();

        options.add(new selectOption('CC', 'Credit Card'));
        options.add(new selectOption('ACH', 'ACH'));

        return options;
    }

    public PageReference validatePaymentParam() {
        String paymentId = this.getPaymentAdjustmentId();
        if (paymentId != null && String.isNotBlank(paymentId)) {
            List<Payment_Adjustment__c> payment = [SELECT Id, Total_Attempts__c FROM Payment_Adjustment__c WHERE Id = :paymentId];
            if (payment.size() > 0 && (payment[0].Total_Attempts__c == null || payment[0].Total_Attempts__c < 5)) {
                return null;
            }
        }


        PageReference pr = new PageReference('/CongrComm_Error');
        pr.setRedirect(true);
        return pr;
    }


    public CongrComm_NMIPaymentProcessorCtrl() {
        this.onlineFee = 0;
        paId = getPaymentAdjustmentId();
        if (ApexPages.currentPage().getParameters().containsKey('method')) {
            this.shouldDisplayPaymentOptions = false;
            this.selectedPaymentMethod = ApexPages.currentPage().getParameters().get('method');
            System.debug('SELECTED PAYMENT METHOD: ' +this.selectedPaymentMethod);
        } else {
            this.selectedPaymentMethod = 'CC';
            this.shouldDisplayPaymentOptions = true;
        }
        if (ApexPages.currentPage().getParameters().containsKey('isGuest')) {
            this.isGuest = Boolean.valueOf(ApexPages.currentPage().getParameters().get('isGuest'));
        }
        if (this.isGuest == null) {
            this.isGuest = Auth.CommunitiesUtil.isGuestUser();
        }
        getPaymentAdjustmentAmount();

        //Default values
        creditCard = '';
        expirationDate = '';
        cvc = '';

        accountName = '';
        accountNumber = '';
        routingNumber = '';

//        generateSecureURL();
        fillUserInfo();
        getSelectedVaultToEdit();
    }

    public void getPaymentAdjustmentAmount() {
        if (this.paid == null || String.isBlank(this.paId)) return;
        Payment_Adjustment__c curAdjustment = [
                SELECT Id, Amount__c, Amount_Disbursed__c, Online_Fee__c, Undisbursed_Amount__c
                FROM Payment_Adjustment__c
                WHERE Id = :this.paId
        ];
        this.onlineFee = curAdjustment.Online_Fee__c != null && curAdjustment.Online_Fee__c != curAdjustment.Amount__c ? curAdjustment.Online_Fee__c : curAdjustment.Undisbursed_Amount__c;
        if (selectedPaymentMethod == 'CC') {
            this.paymentAdjustmentAmount = curAdjustment.Amount__c;
        } else if (selectedPaymentMethod == 'ACH') {
            this.paymentAdjustmentAmount = curAdjustment.Amount__c;
        }
    }

    public void getSelectedVaultToEdit() {
        if (!ApexPages.currentPage().getParameters().containsKey('vaultid')) {
            isEditingVault = false;
            return;
        }

        String vaultToEditId = ApexPages.currentPage().getParameters().get('vaultid');
        this.vaultToEdit = NMI_Utilities.GetPaymentVault(vaultToEditId);
        isEditingVault = true;
    }

    @RemoteAction
    public static void setCaptchaCheckbox(String paymentId) {
        if (paymentId == null) return;
        System.debug('CHECKING CAPTCHA');
        Payment_Adjustment__c newAdjustment = new Payment_Adjustment__c();
        newAdjustment.Id = paymentId;
        newAdjustment.Is_Captcha_Checked__c = true;
        update newAdjustment;
    }

    public void generateSecureURL() {
        NMI_TransactionalWrapper.Billing billing = buildBillingWrapper();
        secureURLtoPostFromStep1 = NMI_PaymentProcessingCtrl.GetNMIPaymentProcessingCtrl.getFormURLFromFirstStep(paId, Double.valueOf(this.paymentAdjustmentAmount), false, billing);
        System.debug(secureURLtoPostFromStep1);
    }

    private NMI_TransactionalWrapper.Billing buildBillingWrapper() {
        NMI_TransactionalWrapper.Billing billing = new NMI_TransactionalWrapper.Billing();
        if (String.isNotEmpty(billingStreet))
            billing.Address1 = billingStreet;
        if (String.isNotEmpty(billingState))
            billing.State = billingState;
        if (String.isNotEmpty(billingCity))
            billing.City = billingCity;
        if (String.isNotEmpty(billingZip))
            billing.Postal = billingZip;
        if (String.isNotEmpty(billingCountry))
            billing.Country = billingCountry;
        if (String.isNotEmpty(firstName))
            billing.FirstName = firstName;
        if (String.isNotEmpty(lastName))
            billing.LastName = lastName;
        if (String.isNotEmpty(emailAddress))
            billing.Email = emailAddress;
        return billing;
    }


    public void fillUserInfo() {

        Id uid = UserInfo.getUserId();
        System.debug('FILLING USER INFO: ' + uid);

        String isUserInfoAutoFill = apexpages.currentpage().getparameters().get('autofill');
        String communityConId = apexpages.currentpage().getparameters().get('cId');

        System.debug('isUserInfoAutoFill: ' + isUserInfoAutoFill);
        System.debug('communityConId: ' + communityConId);

        // for guest user contactId isUserInfoAutoFill == 'true' && communityConId != null
        if (isUserInfoAutoFill == 'true' && communityConId != null) {

            this.curContact = [
                    SELECT Id, FirstName, LastName, Email, Phone, AccountId, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry
                    FROM Contact
                    WHERE Id = :communityConId
            ];
            System.debug('curContact');
            System.debug(curContact);

            firstName = curContact.FirstName;
            lastName = curContact.LastName;
            emailAddress = curContact.Email;
            billingStreet = curContact.MailingStreet;
            billingCity = curContact.MailingCity;
            billingState = curContact.MailingState;
            billingZip = curContact.MailingPostalCode;
            billingCountry = curContact.MailingCountry;
        }

        if (uid != null) {
            User u = [SELECT id, ContactId FROM User WHERE id = :uid];
            System.debug('GOT USER: ' + u);
            if (u.ContactId != null) {
                System.debug('GOT USER ContactId: ' + u.ContactId);
                this.curContact = [
                        SELECT id, FirstName, LastName, Email, Phone, AccountId, Account.BillingStreet, Account.BillingCity,
                                Account.BillingState, Account.BillingPostalCode, Account.BillingCountry
                        FROM Contact
                        WHERE id = :u.ContactId
                ];
                firstName = curContact.FirstName;
                lastName = curContact.LastName;
                emailAddress = curContact.Email;
                billingStreet = curContact.Account.BillingStreet;
                billingCity = curContact.Account.BillingCity;
                billingState = curContact.Account.BillingState;
                billingZip = curContact.Account.BillingPostalCode;
                billingCountry = curContact.Account.BillingCountry;
            }

        }

    }

    private Boolean validateCaptchaChecked() {
        try {
            Payment_Adjustment__c curPa = [SELECT Id, Is_Captcha_Checked__c FROM Payment_Adjustment__c WHERE Id = :paId];
            return curPa.Is_Captcha_Checked__c;
        } catch (Exception e) {
            return false;
        }
    }

    private Boolean validateTotalPaymentAttemptsLessThan5() {
        try {
            Payment_Adjustment__c curPa = [SELECT Id, Total_Attempts__c FROM Payment_Adjustment__c WHERE Id = :paId];
            return curPa.Total_Attempts__c == null || curPa.Total_Attempts__c < 5;
        } catch (Exception e) {
            return false;
        }
    }


    private Boolean isExpiryDateValid() {
        if (String.isBlank(expirationDate)) {
            return false;
        }

        List<String> parts = expirationDate.split('/');
        if (parts.size() != 2) {
            return false;
        }

        String monthStr = parts[0].trim();
        String yearStr = parts[1].trim();

        if (!monthStr.isNumeric() || !yearStr.isNumeric()) {
            return false;
        }


        Integer expirationMonth = Integer.valueOf(monthStr);
        Integer expirationYear = Integer.valueOf(yearStr);

        // Validate month is between 1 and 12
        if (expirationMonth < 1 || expirationMonth > 12) {
            return false;
        }

        if (expirationYear < 100) {
            expirationYear += 2000; // Assume 20xx for two-digit years
        }

        Date today = Date.today();
        Integer currentMonth = today.month();
        Integer currentYear = today.year();

        if (expirationYear < currentYear || (expirationYear == currentYear && expirationMonth < currentMonth)) {
            return false;
        }

        return true;
    }



    public PageReference makePayment() {
        if (paId == null) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'FAIL - A Payment has not been associated to this page'));
            hasErrors = true;
            return null;
        }

        if (!validateCaptchaChecked()) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'FAIL - You have not checked the Captcha. Please refresh the page and try again.'));
            hasErrors = true;
            return null;
        }

        if (!validateTotalPaymentAttemptsLessThan5()) {
            ApexPages.addMessage(new ApexPages.message(
                    ApexPages.severity.ERROR,
                    'FAIL - You have made too many unsuccessful payment attempts. You can no longer proceed and must navigate back to the previous pages and try again.'));
            hasErrors = true;
            return null;
        }

        // Add expiry date validation for credit card payments
        if (selectedPaymentMethod == 'CC' && !isExpiryDateValid()) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'FAIL - The credit card expiration date is invalid or has already passed. Please enter a valid future date.'));
            hasErrors = true;
            return null;
        }

        NMI_RequestController.X3StepResponse requestResponse = makePaymentTransaction(paId);

        if (requestResponse.Result == '100') {
            if (isSavingAndMakingPayment) {
                paymentResponse = requestResponse;
            } else {
                UpdatePaymentObject(paId, requestResponse);
            }

            hasErrors = false;
            PageReference pr = Page.CongrComm_Reciept;
            pr.setRedirect(true);
            pr.getParameters().put('pId', paId);
            return pr;
        } else {
            hasErrors = true;
            generateSecureURL();
            updatePaymentAttempts();
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'FAIL - ' + requestResponse.Result + ' - ' + requestResponse.ResultText));
        }
        return null;
    }

    @TestVisible
    private void updatePaymentAttempts() {
        try {
            Payment_Adjustment__c curPa = [SELECT Id, Total_Attempts__c FROM Payment_Adjustment__c WHERE Id = :paId];
            curPa.Total_Attempts__c = curPa.Total_Attempts__c != null ? curPa.Total_Attempts__c + 1 : 1;
            update curPa;
        } catch (DmlException de) {
            UtilitiesErrors.PrintErrorDetails(de);
        } catch (UnexpectedException ue) {
            UtilitiesErrors.PrintErrorDetails(ue);
        } catch (SObjectException se) {
            UtilitiesErrors.PrintErrorDetails(se);
        } catch (QueryException qe) {
            UtilitiesErrors.PrintErrorDetails(qe);
        }
    }


    public NMI_RequestController.X3StepResponse makePaymentTransaction(String paymentAdjustmentId) {
        generateSecureURL();
        String body = getBody();

        System.debug('Payment Adjustment id' + paymentAdjustmentId);
        System.debug('Body: ' + body);

        return NMI_PaymentProcessingCtrl.GetNMIPaymentProcessingCtrl.createOneTimePaymentRequest(paymentAdjustmentId, body, secureURLtoPostFromStep1);
    }


    private String getBody() {
        String body = '';
        expirationDate = expirationDate.deleteWhitespace();

        if (selectedPaymentMethod == 'CC') {
            body = 'billing-cc-number=' + creditCard.deleteWhitespace() + '&billing-cc-exp=' + expirationDate.deleteWhitespace() + '&cvv=' + cvc +
                    '&billing-first-name=' + firstName + '&billing-last-name=' + lastName;
        }

        if (selectedPaymentMethod == 'ACH') {
            body = 'billing-account-name=' + accountName + '&billing-account-number=' + accountNumber +
                    '&billing-routing-number=' + routingNumber + '&billing-first-name=' + firstName + '&billing-last-name=' + lastName ;
        }
        return body;
    }


    @TestVisible private String UpdatePaymentObject(Id paymentId, NMI_RequestController.X3StepResponse response) {
        try {
       /*     String eventAssessmentRID = Schema.SObjectType.Assessment__c.getRecordTypeInfosByName().get('Event Assessment').getRecordTypeId();
            String soqlFields = 'Id,Total_Attempts__c,Authorize_net_Account_Type__c,Amount_Disbursed__c,Household__c,' +
                    'Check_Date__c,Amount__c,Batch__c,Authorize_net_Authorization_Code__c,Authorize_Net_Transaction_Number__c,' +
                    'Last_4_of_Credit_Card__c,Check_Number__c, Type__c, (Select ID, Incomplete_Payment__c FROM Scheduled_Payment_Bridges__r)';
            Payment_Adjustment__c curPayment = Database.query('SELECT ' + soqlFields + ' FROM Payment_Adjustment__c WHERE id =\'' + paymentId + '\'');*/
            Payment_Adjustment__c curPayment = [
                    SELECT Id,Total_Attempts__c,Authorize_net_Account_Type__c,Amount_Disbursed__c,Household__c,
                            Check_Date__c,Amount__c,Batch__c,Authorize_net_Authorization_Code__c,Authorize_Net_Transaction_Number__c,
                            Last_4_of_Credit_Card__c,Check_Number__c, Type__c, Undisbursed_Amount__c, Online_Fee__c, NMI_AuthorizationCode__c,
                            NMI_Transaction_ID__c, Payment_Gateway__c, Incomplete_Payment__c, Checking_Account_Number__c,
                    (SELECT Id, Incomplete_Payment__c FROM Scheduled_Payment_Bridges__r)
                    FROM Payment_Adjustment__c WHERE Id = :paymentId
            ];
            curPayment.Check_Date__c = date.today();
//            curPayment.Authorize_net_Account_Type__c = paymentObj.AccountType;
//            curPayment.Authorize_net_Authorization_Code__c = paymentObj.AuthorizationNumber;
//            curPayment.Authorize_Net_Transaction_Number__c = paymentObj.TransactionNumber;
            curPayment.Incomplete_Payment__c = false;
            curPayment.Payment_Gateway__c = 'NMI';
            curPayment.NMI_Transaction_ID__c = response.TransactionId;
            curPayment.NMI_AuthorizationCode__c = response.AuthorizationCode;
            curPayment.Amount__c = this.paymentAdjustmentAmount;
            curPayment.Total_Attempts__c = curPayment.Total_Attempts__c != null ? curPayment.Total_Attempts__c + 1 : 1;

            if (selectedPaymentMethod == 'CC') {
                curPayment.Type__c = 'Credit Card';
                curPayment.Last_4_of_Credit_Card__c = response.CreditCardNumber.right(7);
            }
            if (selectedPaymentMethod == 'ACH') {
                curPayment.Type__c = 'ACH';
                curPayment.Checking_Account_Number__c = response.CheckingAccountNumber;
            }

//            Batch__c batch = getBatch();
//
//            if (batch != null) {
//                curPayment.Batch__c = batch.Id;
//            }
//
//            if (String.isBlank(curPayment.Check_Number__c) && batch != null) {
//                curPayment.Check_Number__c = batch.Deposit_ID__c;
//            }
            System.debug('UPDATING PAYMENT OBJECT:' + curPayment);
            update curPayment;

            if (curPayment.Scheduled_Payment_Bridges__r != null) {

                for (Payment_Adjustment_Allocation__c curBridge : curPayment.Scheduled_Payment_Bridges__r) {
                    curBridge.Incomplete_Payment__c = false;
                }
                System.debug('UPDATING PAYMENT BRIDGE');
                update curPayment.Scheduled_Payment_Bridges__r;
            }

//            if (shouldFeeCreateAssessment(curPayment.Id))
            System.debug('ONLINE FEE: ' + this.onlineFee);
            System.debug('SELECTED PAYMENT METHOD: ' + selectedPaymentMethod);
            if (this.onlineFee > 0 && selectedPaymentMethod == 'CC') {
                System.debug('INSERTING FEE INVOICE');
                createFeeAssessment(this.onlineFee, curPayment.Household__c, curPayment.Id);
            }

            return curPayment.Id;
        } catch (QueryException qe) {
            system.debug(qe.getMessage());
            return null;
        } catch (DmlException de) {
            system.debug(de.getMessage());
            return null;
        }
    }


    @TestVisible
    public static Batch__c getBatch() {

        Batch__c batchRecord = new Batch__c();
        try {
            String depositId = Datetime.now().format('MM/dd/YY') + 'CCOL';
            system.debug(depositId);
            list<Batch__c> theBatches = [SELECT Id, Deposit_ID__c FROM Batch__c WHERE Transaction_Type__c = 'Posted Payment' AND Deposit_ID__c = :depositId AND Status__c = :ConstantsFinancials.UN_SUMMARIZED_STATUS];
            if (theBatches.size() > 0) {
                batchRecord = theBatches[0];
                return theBatches[0];
            } else {
                Batch__c newBatch = new Batch__c();
                newBatch.Deposit_ID__c = depositId;
                newBatch.Transaction_Type__c = 'Posted Payment';
                newBatch.Default_Payment_Method__c = 'Credit Card';
                newBatch.Batch_Date__c = date.today();
                insert newBatch;
                return newBatch;
            }
        } catch (QueryException qe) {
            system.debug(qe.getMessage());
            return null;
        } catch (DmlException de) {
            system.debug(de.getMessage());
            return null;
        }
    }

    public static void createFeeAssessment(Decimal totalPaymentAmount, Id accountId, Id paymentId) {

        try {
            Decimal feeAmount = totalPaymentAmount.setScale(2);
            Assessment__c assessment = new Assessment__c();
            assessment.Account__c = accountId;
            assessment.Assessed_Amount__c = feeAmount;
            assessment.RecordTypeId = UtilitiesSObject.getRecordTypeId('Assessment', Assessment__c.SObjectType);

//            Fee_Designation_Setting__c fds = UtilitiesCustomSetting.GetInstance().getFeeDesignationsSetting();
//            assessment.Designation__c = fds.Designation_Id__c ;
            assessment.Designation__c = creditCardFeeDesignationId;
            assessment.Assessment_Date__c = date.today();

            insert assessment;

            Scheduled_Payment__c schedPayment = [SELECT Id FROM Scheduled_Payment__c WHERE Assessment__c = :assessment.Id];

            Payment_Adjustment_Allocation__c alloc = new Payment_Adjustment_Allocation__c();
            alloc.Amount__c = feeAmount;
            alloc.Payment_Adjustment__c = paymentId;
            alloc.Scheduled_Payment__c = schedPayment.Id;
            insert alloc;

        } catch (DmlException de) {
            UtilitiesErrors.PrintErrorDetails(de);
        } catch (QueryException qe) {
            UtilitiesErrors.PrintErrorDetails(qe);
        }
    }


    @TestVisible private String getPaymentAdjustmentId() {
        if (ApexPages.CurrentPage().getParameters().containsKey('paId')) {
            return ApexPages.currentPage().getParameters().get('paId');
        }
        return '';
    }

    public PageReference makePaymentAndSaveVault() {
        System.debug('Making Payment and Saving Vault');
        isSavingAndMakingPayment = true;
        shouldRedirect = false;
        PageReference pageRef = makePayment();
        system.debug('HAS ERRORS: ' + hasErrors);
        if (!hasErrors) {
            System.debug('Saving Payment Vault');
            savePaymentVault();
            UpdatePaymentObject(paId, paymentResponse);
        }
        return pageRef;
    }

    public PageReference savePaymentVault() {
        System.debug('Saving Payment Vault');
        // Add expiry date validation for credit card payments
        if (selectedPaymentMethod == 'CC' && !isExpiryDateValid()) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'FAIL - The credit card expiration date is invalid or has already passed. Please enter a valid future date.'));
            hasErrors = true;
            return null;
        }

        try {
            String result;
            if (selectedPaymentMethod == 'ACH') {
                result = NMI_ManageVaultController.createNewACHVaultEntry(accountName, accountNumber, routingNumber, curContact.AccountId, firstName, lastName);
            } else {
                System.debug(creditCard.deleteWhitespace() + ' ' + expirationDate.deleteWhitespace() + ' ' + cvc);
                System.debug(curContact);
                result = NMI_ManageVaultController.createNewCCVaultEntry(creditCard.deleteWhitespace(), expirationDate.deleteWhitespace(), cvc, curContact.AccountId, firstName, lastName);
            }

            if (result.contains('FAIL')) {
                System.debug('RESULT: ' + result);
                hasErrors = true;
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, result));
                return null;
            }

            if (shouldRedirect) {
                return returnToVaultPage();
            } else {
                shouldRedirect = true;
                return null;
            }

        } catch (Exception e) {
            System.debug(e.getMessage() + e.getStackTraceString());
            hasErrors = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage() + e.getStackTraceString()));
            return null;
        }
    }

    public PageReference saveEditedPaymentVault() {

        if (selectedPaymentMethod == 'CC' && !isExpiryDateValid()) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'FAIL - The credit card expiration date is invalid or has already passed. Please enter a valid future date.'));
            hasErrors = true;
            return null;
        }

        try {
            String result;
            if (selectedPaymentMethod == 'ACH') {
                result = NMI_ManageVaultController.editACHVaultEntry(accountName, accountNumber, routingNumber, curContact.AccountId, firstName, lastName, vaultToEdit.Id);
            } else {
                result = NMI_ManageVaultController.editCCVaultEntry(creditCard.deleteWhitespace(), expirationDate.deleteWhitespace(), cvc, curContact.AccountId, firstName, lastName, vaultToEdit.Id);
            }

            if (result.contains('FAIL')) {
                System.debug('RESULT: ' + result);
                hasErrors = true;
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, result));
                return null;
            }

            if (shouldRedirect) {
                return returnToVaultPage();
            } else {
                shouldRedirect = true;
                return null;
            }

        } catch (Exception e) {
            System.debug(e.getMessage() + e.getStackTraceString());
            hasErrors = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage() + e.getStackTraceString()));
            return null;
        }
    }

    public PageReference cancelPaymentEdit() {
        return returnToVaultPage();
    }

    private PageReference returnToVaultPage() {
        PageReference pr = Page.CongrComm_ManagePaymentVaults;
        pr.getParameters().put('paId', paId);
        if (selectedPaymentMethod != null) {
            pr.getParameters().put('method', selectedPaymentMethod);
        }
        pr.setRedirect(true);
        return pr;
    }


}