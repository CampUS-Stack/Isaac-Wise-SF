/**
 * Created by Kritik Garg on 24-03-2020.
 */

@IsTest
private class UDFileRestEndPointTest {
    @testSetup static void testDatasetup() {

        Account acc = new Account();
        acc.Name = 'Test Account';
        insert acc;


        Ticket_Issue__c t = new Ticket_Issue__c();
        t.Status__c = 'New';
        t.Title__c = 'Test';
        t.Description__c = 'Test';
        insert t;

        ContentVersion cv = new ContentVersion();
        cv.VersionData = EncodingUtil.base64Decode('Test');
        cv.FirstPublishLocationId = t.Id;
        cv.Title = 'Test Title';
        cv.PathOnClient = 'TestTitle';
        cv.Description = 'test';
        insert cv;
    }

    public testMethod static void testTicketEndPoint1() {

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        Account acc = [SELECT id FROM Account LIMIT 1];

        UD_Ticket__mdt udTicket = UDUtility.getClientId();

        req.addHeader('httpMethod', 'GET');
        req.addHeader('ClientId', udTicket.Client_Id__c);

        Ticket_Issue__c t = [SELECT id FROM Ticket_Issue__c LIMIT 1];
        ContentVersion cv = [SELECT id FROM ContentVersion WHERE Description = 'test'];


        req.requestUri = '/services/apexrest/v1/File/'+cv.Id;
        RestContext.request = req;
        RestContext.response= res;

        Test.startTest();
        UDFileRestEndPoint.doGet();

        Test.stopTest();

    }


    public testMethod static void testCommentEndPoint2() {

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        Account acc = [SELECT id FROM Account LIMIT 1];

        UD_Ticket__mdt udTicket = UDUtility.getClientId();

        req.addHeader('httpMethod', 'GET');
        req.addHeader('ClientId', udTicket.Client_Id__c);
        req.addHeader('SecretKey', udTicket.Secret_Key__c);
        req.addHeader('Content-Type', 'application/json');

        Ticket_Issue__c t = [SELECT id FROM Ticket_Issue__c LIMIT 1];
        ContentVersion cv = [SELECT id, ContentDocumentId FROM ContentVersion WHERE Description = 'test'];


        req.requestUri = '/services/apexrest/v1/File/'+cv.ContentDocumentId;
        RestContext.request = req;
        RestContext.response= res;

        Test.startTest();
        UDFileRestEndPoint.doGet();

        req.requestUri = '/services/apexrest/v1/File/'+cv.ContentDocumentId;
        UDFileRestEndPoint.doGet();

        Test.stopTest();

    }

    public testMethod static void testTicketEndPoint3() {

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        Account acc = [SELECT id FROM Account LIMIT 1];

        UD_Ticket__mdt udTicket = UDUtility.getClientId();

        req.addHeader('httpMethod', 'POST');
        req.addHeader('ClientId', udTicket.Client_Id__c);
        req.addHeader('SecretKey', udTicket.Secret_Key__c);

        Ticket_Issue__c t = [SELECT id FROM Ticket_Issue__c LIMIT 1];
        ContentVersion cv = [SELECT id, ContentDocumentId FROM ContentVersion WHERE Description = 'test'];


        req.requestUri = '/services/apexrest/v1/File/'+cv.id;
        RestContext.request = req;
        RestContext.response= res;

        Test.startTest();
        try{
            UDFileRestEndPoint.doGet();
        } catch (Exception e) {

        }

        Test.stopTest();

    }



}