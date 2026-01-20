/**
 * Created by Chris Gibson on 1/18/2020.
 */

public without sharing class NMI_Utilities {

    public static String ACCOUNT_SOQL_FIELDS = 'Id, Name, BillingPostalCode, BillingCity, BillingState, BillingCountry, BillingStreet,' +
            'Contact_1__r.FirstName,Contact_1__r.LastName,Contact_1__r.Email';
    public static String DONATION_SOQL_FIELDS = 'Id,Payment_Vault__r.Payment_Type__c,Payment_Vault__r.Id,Payment_Vault__r.Credit_Card_Number__c,Payment_Vault__r.Credit_Card_Image__c,Organization_Household__r.BillingAddress,Fund_GAU__c,Contact__r.Name,Contact__r.Email,Total_Paid__c,Organization_Household__c,Organization_Household__r.npe01__One2OneContact__r.FirstName,Organization_Household__r.npe01__One2OneContact__r.LastName,' +
            'Organization_Household__r.npe01__One2OneContact__r.Email,Payment_Vault__r.Account_Number__c,Organization_Household__r.npe01__One2OneContact__r.MailingStreet,Organization_Household__r.npe01__One2OneContact__r.MailingState,' +
            'Organization_Household__r.npe01__One2OneContact__r.MailingCity,Organization_Household__r.npe01__One2OneContact__r.MailingPostalCode,Amount__c,Installment_Schedule__c,Installment_Amount__c,' +
            'Organization_Household__r.BillingStreet,Payment_Vault__r.RecordType.Name,Organization_Household__r.BillingCity,Organization_Household__r.BillingCountry,Organization_Household__r.BillingPostalCode,' +
            'Donation_Type__c,Date_Established__c,Contact__r.FirstName,Contact__r.LastName,Next_Donation_Date__c';
    public static String CONTACT_SOQL_FIELDS = 'id,FirstName, LastName, Name, Email, Phone, Account.BillingStreet, Account.BillingCity,Account.BillingCountry, Account.BillingState, Account.BillingPostalCode ';
    public static String PAYMENT_VAULT_SOQL_FIELDS = 'Id,Payment_Type__c,Credit_Card_Image__c,Name,NMI_Billing_ID__c,Organization_Household__c,Account_Number__c,RecordType.Name,RecordType.DeveloperName,Expiration_Date__c,Credit_Card_Number__c,NMI_Customer_Vault_Number__c';
    public static String TRANSACTION_PAYMENT_SOQL_FIELDS = 'Id,Name,Household__c,Amount__c, Type__c, Account_ID__c ';
    public static String ASSESSMENT_SOQL_FIELDS = 'Id, Designation__r.Name, Assessed_Amount__c, Remaining_Balance__c,Assessment_Date__c, ' +
            'Description__c, Is_Tax_Deductible__c,Designation__r.Designation_Description__c, Designation__r.Should_Charge_Fee__c, Account__c,  ' +
            'Designation__r.Fee_Setting_Override__c, Designation__r.Fee__c ';

    public static final String BASE_URL = 'https://secure.networkmerchants.com';
    public static final String REDIRECT_ENDPOINT = '/api/v2/three-step';

    public static final String QUERY_API_BASE_URL = 'https://secure.tnbcigateway.com/api/query.php';
    public static final String QUERY_API_KEY_PARAM_NAME = 'security_key';
    public static final String QUERY_API_TRANSACTION_ID_PARAM_NAME = 'transaction_id';

    public static final String API_KEY;
//    public static final String API_KEY = '3A9h55CtSJguDV5r62kcHd6EXS6B73kn'; //ISAAC WISE PRODUCTION API KEY
//    public static final String API_KEY = 'rUbm5n8z8jVm4B244N4jHHKkSvp2jr4q'; //SANDBOX API KEY
    public static final String CONTENT_TYPE = 'text/xml';

    public static final String REDIRECT_URL = 'https://member-force-test-dev-ed.lightning.force.com/apex/NMI_PaymentResponse';

    public static void AddChildElement(dom.XmlNode theXmlNode, String name, String value) {
        if (String.isNotEmpty(value))
            theXmlNode.addChildElement(name, null, null).addTextNode(value);
    }
    public static void addChildElement(dom.XmlNode theXmlNode, String name, Decimal value) {
        if (value != null)
            theXmlNode.addChildElement(name, null, null).addTextNode(String.valueOf(value));
    }
    public static void addChildElement(dom.XmlNode theXmlNode, String name, Date value) {
        if (value != null)
            theXmlNode.addChildElement(name, null, null).addTextNode(Datetime.newinstance(value.year(), value.month(), value.day()).format('YYYYMMdd'));
    }

    static {
        Organization org = [SELECT IsSandbox from Organization WHERE Id = :UserInfo.getOrganizationId()];
        String apiName;
        if (org.IsSandbox) {
            apiName = 'Testing';
        } else {
            apiName = 'Production';
        }
        NMI_Payment_Gateway_Credential__mdt gatewayCredential = [
                SELECT MasterLabel, API_Key__c, QualifiedApiName
                FROM NMI_Payment_Gateway_Credential__mdt
                WHERE QualifiedApiName = :apiName
        ];
        API_KEY = gatewayCredential.API_Key__c;
    }

    //// --------------------------- Wrapper Creation Utility Methods ------------------------ \\\\\
    /**
     * @author: Chris Gibson
     * @date: 03.28.2020
     *
     * @description: This method creates a wrapper class to be used with the Customer Vault 3 step process
     *
     * @param acc - the Account that the wrapper object's data should be populated from
     */
    public static NMI_CustomerVaultWrapper CreateVaultWrapper(Account acc, String transactionType, Payment_Vault__c vaultEntryToUSe) {
        NMI_CustomerVaultWrapper vaultWrapper = new NMI_CustomerVaultWrapper(transactionType);
        vaultWrapper.ApiKey = NMI_Utilities.API_KEY;
        vaultWrapper.RedirectUrl = NMI_Utilities.BASE_URL + NMI_Utilities.REDIRECT_ENDPOINT;
        vaultWrapper.Billing = new NMI_Utilities.Billing();
        if(vaultEntryToUSe != null)
            vaultWrapper.Billing.BillingId = vaultEntryToUSe.NMI_Billing_ID__c;
        if (String.isNotEmpty(acc.BillingStreet))
            vaultWrapper.Billing.Address1 = acc.BillingStreet;
        if (String.isNotEmpty(acc.BillingState))
            vaultWrapper.Billing.State = acc.BillingState;
        if (String.isNotEmpty(acc.BillingCity))
            vaultWrapper.Billing.City = acc.BillingCity;
        if (String.isNotEmpty(acc.BillingPostalCode))
            vaultWrapper.Billing.Postal = acc.BillingPostalCode;
        if (String.isNotEmpty(acc.BillingCountry))
            vaultWrapper.Billing.Country = acc.BillingCountry;
        if (String.isNotEmpty(acc.Contact_1__r.FirstName))
            vaultWrapper.Billing.FirstName = acc.Contact_1__r.FirstName;
        if (String.isNotEmpty(acc.Contact_1__r.LastName))
            vaultWrapper.Billing.LastName = acc.Contact_1__r.LastName;
        if (String.isNotEmpty(acc.Contact_1__r.Email))
            vaultWrapper.Billing.Email = acc.Contact_1__r.Email;
        return vaultWrapper;
    }

    /**
     * @author: Chris Gibson
     * @date: 03.28.2020
     *
     * @description: This method creates a wrapper class to be used with the Recurring/Subscription 3 step Process
     *
     * @param acc - the Account that the wrapper object's data should be populated from
     */
//    public static NMI_RecurringWrapper CreateRecurringWrapper(String transactionType, Payment_Vault__c vaultEntryToUSe, Donation__c theDonation) {
//
//        system.debug(vaultEntryToUSe);
//        system.debug(vaultEntryToUSe.NMI_Customer_Vault_Number__c);
//        system.debug(vaultEntryToUSe.NMI_Billing_ID__c);
//        NMI_RecurringWrapper recurringWrapper = new NMI_RecurringWrapper(transactionType);
//
//        recurringWrapper.ApiKey = NMI_Utilities.API_KEY;
//        recurringWrapper.CustomerVaultId = vaultEntryToUSe.NMI_Customer_Vault_Number__c;
//        if(vaultEntryToUSe != null){
//            recurringWrapper.Billing = new NMI_Utilities.Billing();
//            recurringWrapper.Billing.BillingId = vaultEntryToUSe.NMI_Billing_ID__c;
//        }
//        recurringWrapper.RedirectUrl = NMI_Utilities.BASE_URL + NMI_Utilities.REDIRECT_ENDPOINT;
//        recurringWrapper.Amount = theDonation.Amount__c;
//        recurringWrapper.StartDate = theDonation.Date_Established__c;
//        recurringWrapper.OrderId = theDonation.Id;
//        recurringWrapper.plan = new NMI_RecurringWrapper.Plan();
//        recurringWrapper.plan.NumOfPayments = 1;
//
//        if (theDonation.Installment_Schedule__c == 'Monthly') {
//            recurringWrapper.plan.MonthFrequency = '1';
//        } else if (theDonation.Installment_Schedule__c == 'Quarterly') {
//            recurringWrapper.plan.MonthFrequency = '4';
//        } else if (theDonation.Installment_Schedule__c == 'Yearly') {
//            recurringWrapper.plan.MonthFrequency = '12';
//        } else if (theDonation.Installment_Schedule__c == 'Weekly') {
//            recurringWrapper.plan.DayFrequency = '7';
//        }
//
//        if (theDonation.Installment_Amount__c != null)
//            recurringWrapper.plan.Amount = String.valueOf(theDonation.Installment_Amount__c);
//
//        return recurringWrapper;
//    }

    /**
     * @author: Chris Gibson
     * @date: 03.28.2020
     *
     * @description: This method creates a wrapper class to be used with the Transaction 3 step Process
     *
     * @param acc - the Account that the wrapper object's data should be populated from
     */
    public static NMI_TransactionalWrapper CreateOneTimePaymentWrapper(String transactionType, Double paymentAmount, String billingMethod, Payment_Vault__c vaultEntry) {

        NMI_TransactionalWrapper transactionalWrapper = new NMI_TransactionalWrapper(transactionType);
        transactionalWrapper.ApiKey = NMI_Utilities.API_KEY;
        transactionalWrapper.RedirectUrl = NMI_Utilities.REDIRECT_URL;
        transactionalWrapper.Amount = paymentAmount;
        // ToDo: format date correctly as YYMMDD
        // transactionalWrapper.OrderDate = theDonation.Date_Established__c;
        transactionalWrapper.BillingMethod = billingMethod;
        transactionalWrapper.CustomerReciept = 'true';
        if (UserInfo.getUserType() != 'Guest' && Test.isRunningTest() == false)
            transactionalWrapper.IPAddress = [SELECT Id, SourceIp FROM AuthSession WHERE UsersId = :UserInfo.getUserId() ORDER BY CreatedDate DESC LIMIT 1].SourceIp;
        if (vaultEntry != null) {
            transactionalWrapper.StoredCredentialIndicator = 'used';
            transactionalWrapper.CustomerVaultId = vaultEntry.NMI_Customer_Vault_Number__c;
        } else {
            transactionalWrapper.StoredCredentialIndicator = 'stored';
        }
        return transactionalWrapper;
    }
    /**
     * @author: Chris Gibson
     * @date: 03.28.2020
     *
     * @description: This method creates a wrapper class to be used with the Confirmation Step of any 3 step Process.
     *                  ie. Transaction, Recurring, or Customer Vault
     *
     * @param acc - the Account that the wrapper object's data should be populated from
     */
    public static NMI_ConfirmationWrapper CreateConfirmationWrapper(String tokenId) {

        NMI_ConfirmationWrapper confirmWrapper = new NMI_ConfirmationWrapper();
        confirmWrapper.ApiKey = NMI_Utilities.API_KEY;
        confirmWrapper.TokenId = tokenId;
        return confirmWrapper;

    }

    /**
     * @author: Chris Gibson
     * @date: 04.13.2020
     *
     * @description: This method creates a wrapper class to be used with the Confirmation Step of any 3 step Process.
     *                  ie. Transaction, Recurring, or Customer Vault
     *
     * @param acc - the Account that the wrapper object's data should be populated from
     */
//    public static void updateDonationWithSubscriptionID(String subscriptionId,Donation__c donation, String vaultId){
//        try{
//            if(String.isNotEmpty(subscriptionId)){
//                donation.NMI_Subscription_ID__c = subscriptionId;
//                if(String.isNotEmpty(vaultId)){
//                    donation.Payment_Vault__c = vaultId;
//                }
//            }
//            update donation;
//        }
//        catch(DmlException de){
//            system.debug(de.getMessage());
//        }
//    }


    //// --------------------------- NMI Payment Process Related Object Query Utilities ------------------------ \\\\\

    public static Boolean CheckIfAuthenticatedUser() {
        Boolean isAuthenticatedUser = false;
        String userType = UserInfo.getUserType();
        if (userType != 'Guest') {
            isAuthenticatedUser = true;
        }
        return isAuthenticatedUser;
    }

//    public static list<Payment_Vault__c> GetPaymentVaults(String accountID){
//        return GetPaymentVaults(PAYMENT_VAULT_SOQL_FIELDS,accountID);
//    }
//    public static list<Payment_Vault__c> GetPaymentVaults(String SOQLFields, String accountID){
//        try {
//            list<Payment_Vault__c> returnList = Database.query('SELECT ' + SOQLFields + ' FROM Payment_Vault__c WHERE Organization_Household__c = :accountId');
//            return returnList;
//        } catch (QueryException qe) {
//            system.debug(qe.getMessage());
//            return new list<Payment_Vault__c>();
//        }
//    }

    public static list<Payment_Vault__c> GetPaymentVaults(String accountID) {
        return GetPaymentVaults(PAYMENT_VAULT_SOQL_FIELDS, accountID);
    }

    public static list<Payment_Vault__c> GetPaymentVaults(String SOQLFields, String accountID) {
        try {
            list<Payment_Vault__c> returnList = Database.query('SELECT ' + SOQLFields + ' FROM Payment_Vault__c WHERE Organization_Household__c = :accountId');
            return returnList;
        } catch (QueryException qe) {
            system.debug(qe.getMessage());
            return new list<Payment_Vault__c>();
        }
    }


    public static Account GetAccount(String accountID) {
        return GetAccount(ACCOUNT_SOQL_FIELDS, accountID);
    }
    public static Account GetAccount(String SOQLFields, String accountID) {
        try {
            Account returnAccount = Database.query('SELECT ' + SOQLFields + '  FROM Account WHERE Id = :accountId');
            return returnAccount;
        } catch (QueryException qe) {
            system.debug(qe.getMessage());
            return null;
        }
    }

    public static Payment_Vault__c GetPaymentVault(String paymentVaultId){
        return GetPaymentVault(PAYMENT_VAULT_SOQL_FIELDS,paymentVaultId);
    }
    public static Payment_Vault__c GetPaymentVault(String SOQLFields, String paymentVaultId){
        try {
            Payment_Vault__c returnVault = Database.query('SELECT ' + SOQLFields + ' FROM Payment_Vault__c WHERE Id = :paymentVaultId Order By CreatedDate DESC');
            return returnVault;
        } catch (QueryException qe) {
            system.debug(qe.getMessage());
            return null;
        }
    }

//    public static Donation__c GetDonation(String accountID){
//        return GetDonation(DONATION_SOQL_FIELDS,accountID);
//    }
//    public static Donation__c GetDonation(String SOQLFields, String donationId){
//        try {
//            Donation__c returnDonation = Database.query('SELECT ' + SOQLFields + ' FROM Donation__c WHERE Id = :donationId');
//            return returnDonation;
//        } catch (QueryException qe) {
//            system.debug(qe.getMessage());
//            return null;
//        }
//    }


    public static Assessment__c GetAssessment(String assessmentID) {
        return GetAssessment(ASSESSMENT_SOQL_FIELDS, assessmentID);
    }
    public static Assessment__c GetAssessment(String SOQLFields, String assessmentID) {
        try {
            Assessment__c returnAssessment = Database.query('SELECT ' + SOQLFields + ' FROM Assessment__c WHERE Id = :assessmentID');
            return returnAssessment;
        } catch (QueryException qe) {
            system.debug(qe.getMessage());
            return null;
        }
    }

    public static Contact GetPrimaryContact(String accountID) {
        return GetPrimaryContact(CONTACT_SOQL_FIELDS, accountID);
    }
    @TestVisible private static Contact GetPrimaryContact(String SOQLFields, String accountID) {
        try {
            Contact returnCon = Database.query('SELECT ' + SOQLFields + ' FROM Donation__c FROM Contact WHERE Id IN (SELECT npe01__One2OneContact__c FROM Account WHERE Id = :accountID)');
            return returnCon;
        } catch (QueryException qe) {
            system.debug(qe.getMessage());
            return null;
        }
    }


    public static List<Contact> GetAllContacts(String accountID) {
        return GetAllContacts(CONTACT_SOQL_FIELDS, accountID);
    }
    @TestVisible private static List<Contact> GetAllContacts(String SOQLFields, String accountID) {
        try {
            List<Contact> returnConList = Database.query('SELECT ' + SOQLFields + ' FROM Contact WHERE AccountId = :accountID');
            return returnConList;
        } catch (QueryException qe) {
            system.debug(qe.getMessage());
            return null;
        }
    }

    public static Payment_Adjustment__c GetPaymentAdjustment(String transactionPaymentId) {
        return GetPaymentAdjustment(TRANSACTION_PAYMENT_SOQL_FIELDS, transactionPaymentId);
    }
    @TestVisible private static Payment_Adjustment__c GetPaymentAdjustment(String SOQLFields, Id paymentAdjustmentId) {
        try {
            Payment_Adjustment__c returnPayment = Database.query('SELECT ' + SOQLFields + ' FROM Payment_Adjustment__c WHERE Id = :paymentAdjustmentId');
            return returnPayment;
        } catch (QueryException qe) {
            system.debug(qe.getMessage());
            return null;
        }
    }


    ///// ------------------------------- Objects/Structs shared amoungst wrappers -------------------- \\\\\

    public class Billing {
        public String BillingId { get; set; }
        public String FirstName { get; set; }
        public String LastName { get; set; }
        public String Address1 { get; set; }
        public String City { get; set; }
        public String State { get; set; }
        public String Postal { get; set; }
        public String Country { get; set; }
        public String Phone { get; set; }
        public String Email { get; set; }
        public String Company { get; set; }
        public String Address2 { get; set; }
        public String Fax { get; set; }
        public String AccountType { get; set; }
        public String EntityType { get; set; }

        public void AddToXML(dom.XmlNode xmlNode) {

            dom.XmlNode billingNode = xmlNode.addChildElement('billing', null, null);
            NMI_Utilities.addChildElement(billingNode, 'billing-id', BillingId);
            NMI_Utilities.addChildElement(billingNode, 'first-name', FirstName);
            NMI_Utilities.addChildElement(billingNode, 'last-name', LastName);
            NMI_Utilities.addChildElement(billingNode, 'address1', Address1);
            NMI_Utilities.addChildElement(billingNode, 'city', City);
            NMI_Utilities.addChildElement(billingNode, 'state', State);
            NMI_Utilities.addChildElement(billingNode, 'postal', Postal);
            NMI_Utilities.addChildElement(billingNode, 'country', Country);
            NMI_Utilities.addChildElement(billingNode, 'phone', Phone);
            NMI_Utilities.addChildElement(billingNode, 'email', Email);
            NMI_Utilities.addChildElement(billingNode, 'company', Company);
            NMI_Utilities.addChildElement(billingNode, 'addresss2', Address2);
            NMI_Utilities.addChildElement(billingNode, 'fax', Fax);
            NMI_Utilities.addChildElement(billingNode, 'account-type', AccountType);
            NMI_Utilities.addChildElement(billingNode, 'entity-type', EntityType);
        }
    }

    public class Shipping {
        public String ShippingId { get; set; }
        public String FirstName { get; set; }
        public String LastName { get; set; }
        public String Address1 { get; set; }
        public String City { get; set; }
        public String State { get; set; }
        public String Postal { get; set; }
        public String Country { get; set; }
        public String Phone { get; set; }
        public String Email { get; set; }
        public String Company { get; set; }
        public String Address2 { get; set; }
        public String Fax { get; set; }
        public void AddToXML(dom.XmlNode xmlNode) {

            dom.XmlNode ShippingNode = xmlNode.addChildElement('shipping', null, null);
            NMI_Utilities.addChildElement(ShippingNode, 'billing-id', ShippingId);
            NMI_Utilities.addChildElement(ShippingNode, 'first-name', FirstName);
            NMI_Utilities.addChildElement(ShippingNode, 'last-name', LastName);
            NMI_Utilities.addChildElement(ShippingNode, 'address1', Address1);
            NMI_Utilities.addChildElement(ShippingNode, 'city', City);
            NMI_Utilities.addChildElement(ShippingNode, 'state', State);
            NMI_Utilities.addChildElement(ShippingNode, 'postal', Postal);
            NMI_Utilities.addChildElement(ShippingNode, 'country', Country);
            NMI_Utilities.addChildElement(ShippingNode, 'phone', Phone);
            NMI_Utilities.addChildElement(ShippingNode, 'email', Email);
            NMI_Utilities.addChildElement(ShippingNode, 'company', Company);
            NMI_Utilities.addChildElement(ShippingNode, 'addresss2', Address2);
            NMI_Utilities.addChildElement(ShippingNode, 'fax', Fax);
        }
    }

    public class CreditCardParams {
        public String firstName { get; set; }
        public String lastName { get; set; }
        public String CCNumber { get; set; }
        public String Expiration { get; set; }
        public String CVV { get; set; }
        public String CustomerVaultId { get; set; }

        public CreditCardParams() {
        }

        public CreditCardParams(String ccNumberToSet, String expirationToSet, String cvvToSet, String firstNameToSet, String lastNameToSet) {
            firstName = firstNameToSet;
            lastName = lastNameToSet;
            CCNumber = ccNumberToSet;
            Expiration = expirationToSet;
            CVV = cvvToSet;
        }
    }
    public class ACHParams {
        public String firstName { get; set; }
        public String lastName { get; set; }
        public String AccountName { get; set; }
        public String RoutingNumber { get; set; }
        public String CheckingNumber { get; set; }
        public String CustomerVaultId { get; set; }
        public String BillingId { get; set; }

        public ACHParams() {
        }

        public ACHParams(String accountNameToSet, String routingNumberToSet, String checkingNumberToSet, String firstNameToSet, String lastNameToSet) {
            firstName = firstNameToSet;
            lastName = lastNameToSet;
            AccountName = accountNameToSet;
            RoutingNumber = routingNumberToSet;
            CheckingNumber = checkingNumberToSet;
        }
    }

}