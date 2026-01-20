/**
 * Created by zacha on 2/17/2021.
 */

public without sharing class CongrComm_ManagePaymentVaultsController {
    Payment_Vault__c selectedVault { get; set; }
    String paymentAdjustmentId { get; set; }
    public Integer rowIndex {get; set;}
    
    public Decimal paymentAdjustmentAmount {
        get {
            return paymentAdjustmentAmount.setScale(2);
        }
        set;
    }
    
    Map<String, Payment_Vault__c> paymentVaultMap = new Map<String, Payment_Vault__c>();
    public List<PaymentVaultWrapper> associatedPaymentVaults = new List<PaymentVaultWrapper>();
    public String selectedPaymentMethod { get; set; }
    public String paymentProcessingMethod { get; set; }
    public List<PaymentVaultWrapper> getAllVaultWrappers() {
        System.debug('GETTING VAULT WRAPPERS: ' + this.associatedPaymentVaults.size());
        return this.associatedPaymentVaults;
    }
    
    Public Boolean pageErrors {
        get {
            return ApexPages.hasMessages();
        }
    }
    
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
    
    public CongrComm_ManagePaymentVaultsController() {
    
    }
    
    public PageReference onLoadFunction() {
        getSelectedPaymentMethod();
        RetrievePaymentVaults();
        getPaymentAdjustmentId();
        getPaymentAdjustmentAmount();
        if (this.associatedPaymentVaults.isEmpty() || UtilitiesCustomSetting.getDefaultPaymentGateway() == 'Authorize.net') {
            return navigateToPaymentPage();
        }
        
        return null;
    }
    
    public void getSelectedPaymentMethod() {
        if (ApexPages.currentPage().getParameters().containsKey('method')) {
            this.paymentProcessingMethod = ApexPages.currentPage().getParameters().get('method');
            this.selectedPaymentMethod = paymentProcessingMethod == 'CC' ? 'Credit Card' : 'ACH';
        } else {
            this.selectedPaymentMethod = 'Credit Card';
        }
    }
    
    private void getPaymentAdjustmentId() {
        if (ApexPages.CurrentPage().getParameters().containsKey('paId')) {
            this.paymentAdjustmentID = ApexPages.currentPage().getParameters().get('paId');
        
        } else {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'No payment adjustment ID found'));
        }
    }
    
    private void getPaymentAdjustmentAmount() {
        Payment_Adjustment__c curAdjustment = [
            SELECT Id, Amount__c, Amount_Disbursed__c
            FROM Payment_Adjustment__c
            WHERE Id = :this.paymentAdjustmentId
        ];
        if (this.selectedPaymentMethod == 'Credit Card') {
            this.paymentAdjustmentAmount = curAdjustment.Amount__c.setScale(2);
        } else if (this.selectedPaymentMethod == 'ACH') {
            this.paymentAdjustmentAmount = curAdjustment.Amount__c - (curAdjustment.Amount__c - curAdjustment.Amount_Disbursed__c);
        }
    }
    
    private void RetrievePaymentVaults() {
        Id userId = UserInfo.getUserId();
        if (userID != null) {
            User curUser = [SELECT id, ContactId FROM User WHERE id = :userId];
            Contact curContact = getCurrentContact(curUser);
            List<Payment_Vault__c> paymentVaults = getPaymentVaultsOfAccount(curContact.AccountId);
            createVaultWrappers(paymentVaults);
        }
    }
    
    private Contact getCurrentContact(User curUser) {
        if (curUser.ContactId == null) return null;
        try {
            Contact curContact = [
                SELECT id, FirstName, LastName, Email, Phone, AccountId
                FROM Contact
                WHERE id = :curUser.ContactId
            ];
            System.debug(curContact);
            return curContact;
        } catch (Exception e) {
            System.debug(e.getMessage());
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage()));
            return null;
        }
    }
    
    private List<Payment_Vault__c> getPaymentVaultsOfAccount(String accountId) {
        if (accountId == null || String.isBlank(accountId)) return null;
        List<Payment_Vault__c> retrievedPaymentVaults = [
            SELECT Id, Name, Payment_Type__c, Type__c, Credit_Card_Number__c, Account_Number__c, RecordType.Name, Credit_Card_Image__c, NMI_Customer_Vault_Number__c, Expiration_Date__c
            FROM Payment_Vault__c
            WHERE Organization_Household__c = :accountId
            AND RecordType.Name = :selectedPaymentMethod
        ];
        System.debug('PAYMENT VAULTS SIZE: ' + retrievedPaymentVaults.size());
        System.debug(retrievedPaymentVaults);
        this.paymentVaultMap = new Map<String, Payment_Vault__c>(retrievedPaymentVaults);
        
        return retrievedPaymentVaults;
    }
    
    private void createVaultWrappers(List<Payment_Vault__c> paymentVaults) {
        List<PaymentVaultWrapper> vaultWrappers = new List<PaymentVaultWrapper>();
        for (Payment_Vault__c curVault : paymentVaults) {
            vaultWrappers.add(new PaymentVaultWrapper(curVault));
        }
        this.associatedPaymentVaults = vaultWrappers;
    }
    
    public PageReference navigateToPaymentPage() {
        if (paymentAdjustmentId != null)
            return UtilitiesCustomSetting.navigateToPaymentPageCommunity(paymentAdjustmentID, paymentProcessingMethod);
        return null;
    }
    
    public PageReference cancel() {
        PageReference pr = Page.CongrComm_FinancialsHome;
        return pr;
    }
    
    
    //region Payment Vault Callout Methods
    public PageReference makePaymentWithSelectedVault() {
        if (selectedVault == null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please select a payment method'));
            return null;
        }
        
        Payment_Adjustment__c curPayment = getPaymentAdjustment();
        Double paymentAmount = this.paymentAdjustmentAmount;
        NMI_RequestController.X3StepResponse requestResponse =
            NMI_RequestController.GetNMIRequestController.SendOneTimePaymentRequestWithExistingVault('sale', this.selectedVault.Id, 'installment', paymentAmount);
//        return requestResponse;
        if (requestResponse.Result != '100') {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'FAIL - ' + requestResponse.Result + ' - ' + requestResponse.ResultText));
            return null;
        }
        
        UpdatePaymentObject(curPayment, requestResponse);
        PageReference pr = Page.CongrComm_Reciept;
        pr.setRedirect(true);
        pr.getParameters().put('pId', this.paymentAdjustmentId);
        return pr;
    }
    
    public PageReference deleteSelectedVault() {
        String selectedVaultId = getAllVaultWrappers()[rowIndex].paymentVault.Id;
        selectedVault = paymentVaultMap.get(selectedVaultId);
        if (selectedVault == null) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Please select a payment method to delete'));
            return null;
        }
        
        try {
            delete selectedVault;
            associatedPaymentVaults.clear();
            RetrievePaymentVaults();
            System.debug(associatedPaymentVaults.size());
            if (this.associatedPaymentVaults.isEmpty() || UtilitiesCustomSetting.getDefaultPaymentGateway() == 'Authorize.net') {
                return navigateToPaymentPage();
            }
            return null;
        } catch (DmlException e) {
            System.debug(e.getMessage());
            return null;
        }
    }
    
    public PageReference editSelectedVault() {
//        selectVault();
        String selectedVaultId = getAllVaultWrappers()[rowIndex].paymentVault.Id;
        selectedVault = paymentVaultMap.get(selectedVaultId);
        if (selectedVault == null) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Please select a payment method to delete'));
            return null;
        }
        
        PageReference pr = Page.CongrComm_NMIPaymentProcessor;
        pr.getParameters().put('vaultid', selectedVault.Id);
        pr.getParameters().put('method', paymentProcessingMethod);
        pr.getParameters().put('paId', paymentAdjustmentId);
        pr.setRedirect(true);
        return pr;
    }
    
    
    //endregion
    
    private Payment_Adjustment__c getPaymentAdjustment() {
        try {
            Payment_Adjustment__c adjustmentToProcess = [
                SELECT Id,Total_Attempts__c,Authorize_net_Account_Type__c,Amount_Disbursed__c,Household__c,
                        Check_Date__c,Amount__c,Batch__c,Authorize_net_Authorization_Code__c,Authorize_Net_Transaction_Number__c,
                        Last_4_of_Credit_Card__c,Check_Number__c, Type__c, Undisbursed_Amount__c, Online_Fee__c, NMI_AuthorizationCode__c,
                        NMI_Transaction_ID__c, Payment_Gateway__c, Incomplete_Payment__c, Checking_Account_Number__c,
                (SELECT Id, Incomplete_Payment__c FROM Scheduled_Payment_Bridges__r)
                FROM Payment_Adjustment__c
                WHERE Id = :this.paymentAdjustmentId
            ];
            return adjustmentToProcess;
        } catch (QueryException e) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'ERROR processing payment: ' + e.getMessage()));
            return null;
        }
    }
    
    @TestVisible private String UpdatePaymentObject(Payment_Adjustment__c curPayment, NMI_RequestController.X3StepResponse response) {
        System.debug(response);
        try {
            curPayment.Check_Date__c = date.today();
            curPayment.Incomplete_Payment__c = false;
            curPayment.Payment_Gateway__c = 'NMI';
            curPayment.NMI_Transaction_ID__c = response.TransactionId;
            curPayment.NMI_AuthorizationCode__c = response.AuthorizationCode;
            curPayment.Amount__c = this.paymentAdjustmentAmount;
            
            if (this.selectedVault.RecordType.Name == 'Credit Card') {
                curPayment.Type__c = 'Credit Card';
                curPayment.Last_4_of_Credit_Card__c = response.CreditCardNumber.right(7);
            }
            if (this.selectedVault.RecordType.Name == 'ACH') {
                curPayment.Type__c = 'ACH';
                curPayment.Checking_Account_Number__c = response.CheckingAccountNumber;
            }
//            Batch__c batch = getBatch();
//            if (batch != null) {
//                curPayment.Batch__c = batch.Id;
//            }
//            if (String.isBlank(curPayment.Check_Number__c) && batch != null) {
//                curPayment.Check_Number__c = batch.Deposit_ID__c;
//            }
            update curPayment;
            if (curPayment.Scheduled_Payment_Bridges__r != null) {
                
                for (Payment_Adjustment_Allocation__c curBridge : curPayment.Scheduled_Payment_Bridges__r) {
                    curBridge.Incomplete_Payment__c = false;
                }
                update curPayment.Scheduled_Payment_Bridges__r;
            }
            if ((curPayment.Amount__c - curPayment.Amount_Disbursed__c) > 0 && selectedPaymentMethod == 'Credit Card')
                createFeeAssessment(curPayment.Amount__c - curPayment.Amount_Disbursed__c, curPayment.Household__c, curPayment.Id);
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
            list<Batch__c> theBatches = [SELECT Id,Deposit_ID__c FROM Batch__c WHERE Transaction_Type__c = 'Posted Payment' AND Deposit_ID__c = :depositId AND Status__c = :ConstantsFinancials.UN_SUMMARIZED_STATUS];
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
            system.debug(de.getMessage());
        } catch (QueryException qe) {
            system.debug(qe.getMessage());
        }
    }
    
    public void selectVault() {
        String selectedVaultId = System.currentPageReference().getParameters().get('vaultid');
        Integer rowIndexValue = Integer.valueOf(System.currentPageReference().getParameters().get('index'));
        System.debug('ASSOCIATED VAULTS PAYMENT SIZE: ' + this.associatedPaymentVaults.size());
        if (rowIndexValue > this.associatedPaymentVaults.size() - 1) {
            rowIndexValue -= this.associatedPaymentVaults.size();
        }
        Payment_Vault__c vault = paymentVaultMap.get(selectedVaultId);
        this.selectedVault = vault;
        for (Integer curWrapper = 0; curWrapper < associatedPaymentVaults.size(); curWrapper++) {
            if (curWrapper == rowIndexValue) {
                associatedPaymentVaults[curWrapper].isSelected = true;
            } else {
                associatedPaymentVaults[curWrapper].isSelected = false;
            }
        }
        this.selectedPaymentMethod = vault.RecordType.Name;
        getPaymentAdjustmentAmount();
    }
    
    
    class PaymentVaultWrapper {
        public Payment_Vault__c paymentVault { get; set; }
        public Boolean isSelected { get; set; }
        public Boolean isExpired { get; set; }
        public String PaymentNumber { get; set; }
        public String PaymentType { get; set; }
        
        public PaymentVaultWrapper(Payment_Vault__c paymentVault) {
            this.paymentVault = paymentVault;
            this.PaymentType = paymentVault.Payment_Type__c;
            isSelected = false;
            if (paymentVault.RecordType.Name == 'ACH') {
                this.PaymentNumber = '(ACH) ' + paymentVault.Account_Number__c;
                this.isExpired = false; // ACH doesn't expire
            } else {
                this.PaymentNumber = '(CC) ' + paymentVault.Credit_Card_Number__c;
                this.isExpired = isCardExpired(paymentVault.Expiration_Date__c);
            }
        }
 

        private Boolean isCardExpired(String expirationDate) {
            if (String.isBlank(expirationDate) || expirationDate.length() != 4) {
                return false; // Consider invalid expiration dates as not processed
            }

            Integer expirationMonth = Integer.valueOf(expirationDate.substring(0, 2));
            Integer expirationYear = Integer.valueOf('20' + expirationDate.substring(2));

            Date today = Date.today();
            Integer currentMonth = today.month();
            Integer currentYear = today.year();

            if (expirationYear < currentYear || (expirationYear == currentYear && expirationMonth < currentMonth)) {
                return true;
            }

            return false;
        }

    }
}