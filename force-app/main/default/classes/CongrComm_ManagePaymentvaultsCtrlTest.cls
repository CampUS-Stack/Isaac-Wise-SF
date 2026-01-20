/**
 * Created by zacha on 4/27/2021.
 */

@IsTest
private class CongrComm_ManagePaymentvaultsCtrlTest {
    @TestSetup
    static void setupTestObjects() {
        User user = new User(alias = 'test128', email='test123@noem22323232ail.com',
            emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
            localesidkey='en_US', profileid = [SELECT Id FROM Profile WHERE Name ='System Administrator'].Id,
            country='United States',IsActive =true,
            timezonesidkey='America/Los_Angeles', username= 'test1233333@test.comemailofnoemail' );
        insert user;
        
        Account account = (Account)TestObjectFactory.CreateAccounts('TestAccount', 1)[0];
        insert account;

        Contact con = (Contact)TestObjectFactory.CreateContacts('test',1)[0];
        con.AccountId = account.Id;
        con.ownerId = UserInfo.getuserId();
        insert con;

        System.runAs(user){
            List<Payment_Vault__c> vaults = (List<Payment_Vault__c>) TestObjectFactory.CreatePaymentVaults('TestVault', 3);
            Id achRecordTypeId = UtilitiesSObject.getRecordTypeId('ACH', Payment_Vault__c.SObjectType);
            Id ccRecordTypeId = UtilitiesSObject.getRecordTypeId('Credit_Card', Payment_Vault__c.SObjectType);
            for(Payment_Vault__c vault : vaults){
                vault.Organization_Household__c = account.Id;
                vault.Credit_Card_Number__c = '1234123412341234';
                vault.RecordTypeId = ccRecordTypeId;
                vault.Expiration_Date__c = '0225';
            }
            vaults[0].RecordTypeId = achRecordTypeId;
            insert vaults;
        }
    }

    @IsTest
    static void TestGetPaymentVaultEntries(){

        Contact con = [SELECT Id, AccountId FROM Contact LIMIT 1];
        Payment_Vault__c paymentVault = [SELECT Id FROM Payment_Vault__c WHERE RecordType.Name = 'ACH' LIMIT 1];

        Payment_Adjustment__c thePayment = new Payment_Adjustment__c();
        thePayment.Check_Date__c = Date.today();
        thePayment.Household__c = con.AccountId;
        thePayment.Amount__c = 50;
        thePayment.Reason__c = 'asd';
        thePayment.RecordTypeId = UtilitiesSObject.getRecordTypeId('Payment', Payment_Adjustment__c.SObjectType);
        insert thePayment;

        PageReference pr = Page.CongrComm_ManagePaymentVaults;
        pr.getParameters().put('paId',thePayment.Id);
        pr.getParameters().put('vaultid',paymentVault.Id);
        pr.getParameters().put('index','0');
        pr.getParameters().put('method', 'ACH');
        Test.setCurrentPage(pr);

        Test.setMock(HttpCalloutMock.class, new NMIMockHttpResponse());

        Test.startTest();

        User user = new User(alias = 'test123', email='test123@noemail.com',
                emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
                localesidkey='en_US', profileid = [SELECT Id FROM Profile WHERE Name ='Wise Community Member'].Id,
                country='United States',IsActive =true,ContactId = con.Id,
                timezonesidkey='America/Los_Angeles', username= 'test1233333@test.com' );
        system.RunAs(user) {

            CongrComm_ManagePaymentVaultsController commManagePaymentVaultsController = new CongrComm_ManagePaymentVaultsController();
            commManagePaymentVaultsController.onLoadFunction();
            commManagePaymentVaultsController.navigateToPaymentPage();

            commManagePaymentVaultsController.selectVault();
            commManagePaymentVaultsController.navigateToPaymentPage();

            commManagePaymentVaultsController.cancel();
            commManagePaymentVaultsController.rowIndex = 0;
            commManagePaymentVaultsController.editSelectedVault();
            commManagePaymentVaultsController.deleteSelectedVault();
            //commManagePaymentVaultsController.makePaymentWithSelectedVault();
        }

        Test.stopTest();

    }


    @IsTest
    static void TestGetPaymentVaultEntries2(){

        Contact con = [SELECT Id, AccountId FROM Contact LIMIT 1];
        Payment_Vault__c paymentVault = [SELECT Id FROM Payment_Vault__c WHERE RecordType.Name = 'Credit Card' LIMIT 1];

        Payment_Adjustment__c thePayment = new Payment_Adjustment__c();
        thePayment.Check_Date__c = Date.today();
        thePayment.Household__c = con.AccountId;
        thePayment.Amount__c = 50;
        thePayment.Reason__c = 'asd';
        insert thePayment;

        PageReference pr = Page.CongrComm_ManagePaymentVaults;
        pr.getParameters().put('paId',thePayment.Id);
        pr.getParameters().put('vaultid',paymentVault.Id);
        pr.getParameters().put('index','0');
        Test.setCurrentPage(pr);

        Test.setMock(HttpCalloutMock.class, new NMIMockHttpResponse());


        User user = new User(alias = 'test123', email='test123@noemail.com',
                emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
                localesidkey='en_US', profileid = [SELECT Id FROM Profile WHERE Name ='Wise Community Member'].Id,
                country='United States',IsActive =true,ContactId = con.Id,
                timezonesidkey='America/Los_Angeles', username= 'test1233333@test.com' );
        system.RunAs(user) {

            CongrComm_ManagePaymentVaultsController commManagePaymentVaultsController = new CongrComm_ManagePaymentVaultsController();
            commManagePaymentVaultsController.onLoadFunction();
            commManagePaymentVaultsController.navigateToPaymentPage();

            commManagePaymentVaultsController.selectVault();
            commManagePaymentVaultsController.navigateToPaymentPage();
            Test.startTest();

            commManagePaymentVaultsController.makePaymentWithSelectedVault();

            Test.stopTest();
        }
    }

    @IsTest
    static void TestGetBatch(){
        CongrComm_ManagePaymentVaultsController.getBatch();
    }
}