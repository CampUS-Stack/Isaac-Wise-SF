/**
 * Created by Kritik Garg on 24-03-2020.
 */

@IsTest
private class UDFilesRestEndPointTest {

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
        insert cv;
    }

    public testMethod static void testTicketEndPoint1() {

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        Account acc = [SELECT id FROM Account LIMIT 1];

        UD_Ticket__mdt udTicket = UDUtility.getClientId();

        req.addHeader('httpMethod', 'POST');
        req.addHeader('ClientId', udTicket.Client_Id__c);
        req.addHeader('SecretKey', udTicket.Secret_Key__c);
        req.addHeader('Content-Type', 'application/json');

        Ticket_Issue__c t = [SELECT id FROM Ticket_Issue__c LIMIT 1];

        req.requestUri = '/services/apexrest/v1/TicketFiles/'+t.Id;
        RestContext.request = req;
        RestContext.response= res;

        Test.startTest();
        UDFilesRestEndPoint.doGet();

        req.requestUri = '/services/apexrest/v1/TicketFiles/'+t.Id;
        UDFilesRestEndPoint.doGet();

        Test.stopTest();
    }

    public testMethod static void testTicketEndPoint2() {

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        Account acc = [SELECT id FROM Account LIMIT 1];

        UD_Ticket__mdt udTicket = UDUtility.getClientId();

        req.addHeader('httpMethod', 'GET');
        req.addHeader('ClientId', udTicket.Client_Id__c);
        Ticket_Issue__c t = [SELECT id FROM Ticket_Issue__c LIMIT 1];


        req.requestUri = '/services/apexrest/v1/TicketFiles/'+t.Id;
        RestContext.request = req;
        RestContext.response= res;

        Test.startTest();
        UDFilesRestEndPoint.doGet();

        Test.stopTest();
    }

}