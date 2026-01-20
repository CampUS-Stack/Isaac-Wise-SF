/**
 * Created by zacha on 4/27/2021.
 */

@IsTest
private class CongrComm_NMIPaymentProcessorCtrlTest {
    @TestSetup
    static void dataSetup() {

        Account account = (Account) TestObjectFactory.CreateAccounts('TestAccount', 1)[0];
        insert account;

        Contact con = (Contact) TestObjectFactory.CreateContacts('test', 1)[0];
        con.AccountId = account.Id;
        con.ownerId = UserInfo.getuserId();
        insert con;

        List<Payment_Vault__c> vaults = (List<Payment_Vault__c>) TestObjectFactory.CreatePaymentVaults('TestVault', 3);
        for (Payment_Vault__c vault : vaults) {
            vault.Organization_Household__c = account.Id;
            vault.Credit_Card_Number__c = '1234123412341234';
            vault.Expiration_Date__c = '0222';
        }
        insert vaults;
/*

        Payment_Adjustment__c thePayment = new Payment_Adjustment__c();
        thePayment.Check_Date__c = Date.today();
        thePayment.Household__c = account.Id;
        thePayment.Amount__c = 50;
        thePayment.Reason__c = 'asd';
        thePayment.RecordTypeId = UtilitiesSObject.getRecordTypeId('Payment', Payment_Adjustment__c.SObjectType);
        insert thePayment;

        Scheduled_Payment__c schedP = new Scheduled_Payment__c();
        schedP.Assessment__c = financialTestScenario.assessments[0].Id;
        schedP.Expected_Amount__c = financialTestScenario.assessments[0].Assessed_Amount__c;
        insert schedP;
*/

        TestObjectFactory.FinancialTestScenario financialTestScenario = TestObjectFactory.GetFinancialTestScenario();
        insert financialTestScenario.designations;

        list<Designation__c> designations = TestObjectFactory.CreateDesignations('Test Des',1);
        designations.get(0).Designation_Description__c = 'Credit Card Fees';
        insert designations;

        
        for(Assessment__c curAssess: financialTestScenario.assessments){
            curAssess.Account__c = account.Id;
            curAssess.Designation__c = financialTestScenario.designations[0].Id;
        }

        insert financialTestScenario.assessments;

        Scheduled_Payment__c schedP = new Scheduled_Payment__c();
        schedP.Assessment__c = financialTestScenario.assessments[0].Id;
        schedP.Expected_Amount__c = financialTestScenario.assessments[0].Assessed_Amount__c;
        insert schedP;

        Batch__c curBatch = new Batch__c();
        curBatch.Deposit_ID__c = 'test1234';
        insert curBatch;
        update curBatch;

        Payment_Adjustment__c payment = new Payment_Adjustment__c();
        payment.Household__c = account.Id;
        payment.Status__c = 'Un-Transferred';
        payment.Amount__c = 2;
        payment.Batch__c = curBatch.Id;
        payment.RecordTypeId = UtilitiesSObject.getRecordTypeId('Payment', Payment_Adjustment__c.SObjectType);
        insert payment;

        Payment_Adjustment_Allocation__c alloc = new Payment_Adjustment_Allocation__c();
        alloc.Payment_Adjustment__c = payment.Id;
        alloc.Scheduled_Payment__c = schedP.Id;
        alloc.Amount__c = 2;
        insert alloc;




    }

    @IsTest
    static void testBehavior() {

        Contact con = [SELECT Id, AccountId FROM Contact LIMIT 1];
        Payment_Vault__c paymentVault = [SELECT Id FROM Payment_Vault__c LIMIT 1];

        Payment_Adjustment__c paymentAdjustment = [SELECT Id FROM Payment_Adjustment__c LIMIT 1];

        PageReference pr = Page.CongrComm_ManagePaymentVaults;
        pr.getParameters().put('paId', paymentAdjustment.Id);
        pr.getParameters().put('vaultid', paymentVault.Id);
        pr.getParameters().put('index', '0');
        pr.getParameters().put('cId', con.Id);
        pr.getParameters().put('autofill','true');
        Test.setCurrentPage(pr);
        CongrComm_NMIPaymentProcessorCtrl.setCaptchaCheckbox(paymentAdjustment.Id);


        Test.setMock(HttpCalloutMock.class, new NMIMockHttpResponse());


        User user = new User(alias = 'test123', email = 'test123@noemail.com',
                emailencodingkey = 'UTF-8', lastname = 'Testing', languagelocalekey = 'en_US',
                localesidkey = 'en_US', profileid = [SELECT Id FROM Profile WHERE Name = 'Wise Community Member'].Id,
                country = 'United States', IsActive = true, ContactId = con.Id,
                timezonesidkey = 'America/Los_Angeles', username = 'test1233333@test.com');
        system.RunAs(user) {
            Test.startTest();
            CongrComm_NMIPaymentProcessorCtrl nmiPaymentProcessorCtrl = new CongrComm_NMIPaymentProcessorCtrl();
            nmiPaymentProcessorCtrl.creditCard = '4111111111111111';
            nmiPaymentProcessorCtrl.expirationDate = '10/25';
            nmiPaymentProcessorCtrl.cvc = '123';
            nmiPaymentProcessorCtrl.accountName = 'Suntrust Check';
            nmiPaymentProcessorCtrl.accountNumber = '123123123';
            nmiPaymentProcessorCtrl.routingNumber = '123123123';
            nmiPaymentProcessorCtrl.onlineFee = 2;
            nmiPaymentProcessorCtrl.makePayment();
            nmiPaymentProcessorCtrl.savePaymentVault();

            nmiPaymentProcessorCtrl.getPaymentOptions();

            CongrComm_NMIPaymentProcessorCtrl.getBatch();
            Test.stopTest();

        }

    }

    @IsTest
    static void testBehavior2() {

        Contact con = [SELECT Id, AccountId FROM Contact LIMIT 1];
        Payment_Vault__c paymentVault = [SELECT Id FROM Payment_Vault__c LIMIT 1];

        Payment_Adjustment__c paymentAdjustment = [SELECT Id FROM Payment_Adjustment__c LIMIT 1];

        PageReference pr = Page.CongrComm_ManagePaymentVaults;
        pr.getParameters().put('paId', paymentAdjustment.Id);
        pr.getParameters().put('vaultid', paymentVault.Id);
        pr.getParameters().put('index', '0');
        pr.getParameters().put('cId', con.Id);
        pr.getParameters().put('autofill','true');
        Test.setCurrentPage(pr);
        CongrComm_NMIPaymentProcessorCtrl.setCaptchaCheckbox(paymentAdjustment.Id);


        Test.setMock(HttpCalloutMock.class, new NMIMockHttpResponse());


        User user = new User(alias = 'test123', email = 'test123@noemail.com',
                emailencodingkey = 'UTF-8', lastname = 'Testing', languagelocalekey = 'en_US',
                localesidkey = 'en_US', profileid = [SELECT Id FROM Profile WHERE Name = 'Wise Community Member'].Id,
                country = 'United States', IsActive = true, ContactId = con.Id,
                timezonesidkey = 'America/Los_Angeles', username = 'test1233333@test.com');
        system.RunAs(user) {
            Test.startTest();
            CongrComm_NMIPaymentProcessorCtrl nmiPaymentProcessorCtrl = new CongrComm_NMIPaymentProcessorCtrl();
            nmiPaymentProcessorCtrl.creditCard = '4111111111111111';
            nmiPaymentProcessorCtrl.expirationDate = '10/25';
            nmiPaymentProcessorCtrl.cvc = '123';
            nmiPaymentProcessorCtrl.accountName = 'Suntrust Check';
            nmiPaymentProcessorCtrl.accountNumber = '123123123';
            nmiPaymentProcessorCtrl.routingNumber = '123123123';
            nmiPaymentProcessorCtrl.saveEditedPaymentVault();
            nmiPaymentProcessorCtrl.cancelPaymentEdit();
            nmiPaymentProcessorCtrl.makePaymentAndSaveVault();
            Test.stopTest();

        }

    }

    @IsTest
    static void testValidatePaymentParam() {
        CongrComm_NMIPaymentProcessorCtrl paymentProcessorCtrl = new CongrComm_NMIPaymentProcessorCtrl();
        paymentProcessorCtrl.validatePaymentParam();

        paymentProcessorCtrl.errorString = '';
        paymentProcessorCtrl.phoneNumber = '';
        paymentProcessorCtrl.paymentNumber = '';
        paymentProcessorCtrl.expirationDate = '';
        String CaptchaSiteKey = paymentProcessorCtrl.CaptchaSiteKey;
        paymentProcessorCtrl.makePaymentAndSaveVault();
        paymentProcessorCtrl.updatePaymentAttempts();
    }
}