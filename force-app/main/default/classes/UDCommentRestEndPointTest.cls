/**
 * Created by Kritik Garg on 24-03-2020.
 */

@IsTest
private class UDCommentRestEndPointTest {

    @testSetup static void testDatasetup() {
        Account acc = new Account();
        acc.Name = 'Test Account';
        insert acc;

        Ticket_Issue__c t = new Ticket_Issue__c();
        t.Status__c = 'New';
        t.Title__c = 'Test';
        t.Description__c = 'Test';
        insert t;
    }

    public testMethod static void testCommentEndPoint1() {

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        Account acc = [SELECT id FROM Account LIMIT 1];

        UD_Ticket__mdt udTicket = UDUtility.getClientId();

        req.addHeader('httpMethod', 'POST');
        req.addHeader('ClientId', udTicket.Client_Id__c);
        req.addHeader('SecretKey', udTicket.Secret_Key__c);
        req.addHeader('Content-Type', 'application/json');

        Ticket_Issue__c t = [SELECT id FROM Ticket_Issue__c LIMIT 1];

        req.requestUri = '/services/apexrest/v1/Comment/';
        String postData = '{"UserLastName":"Gibson Admin","UserFirstName":"Chris","UDCommentID":null,"TicketSFID":"'+t.id+'","CommentSFID":"a0h1U000006v0ZmQAI","Comment":"<p>Test 1</p>"}';
        req.requestBody = Blob.valueof(postData);
        RestContext.request = req;
        RestContext.response= res;

        Test.startTest();
        UDCommentRestEndPoint.doPost();

        Comment__c c = [SELECT id FROM Comment__c LIMIT 1];


        req.requestUri = '/services/apexrest/v1/Comment/'+c.Id;
        req.addHeader('httpMethod', 'PUT');
        UDCommentRestEndPoint.doPut();

        Test.stopTest();

    }

    public testMethod static void testCommentEndPoint2() {

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        Account acc = [SELECT id FROM Account LIMIT 1];

        UD_Ticket__mdt udTicket = UDUtility.getClientId();

        req.addHeader('httpMethod', 'POST');
        req.addHeader('ClientId', udTicket.Client_Id__c);
        req.addHeader('Content-Type', 'application/json');

        Ticket_Issue__c t = [SELECT id FROM Ticket_Issue__c LIMIT 1];

        req.requestUri = '/services/apexrest/v1/Comment/';
        String postData = '{"UserLastName":"Gibson Admin","UserFirstName":"Chris","UDCommentID":null,"TicketSFID":"'+t.id+'","CommentSFID":"a0h1U000006v0ZmQAI","Comment":"<p>Test 1</p>"}';
        req.requestBody = Blob.valueof(postData);
        RestContext.request = req;
        RestContext.response= res;

        Test.startTest();
        UDCommentRestEndPoint.doPost();


        req.requestUri = '/services/apexrest/v1/Comment/'+'test';
        req.addHeader('httpMethod', 'PUT');
        UDCommentRestEndPoint.doPut();

        Test.stopTest();

    }

    public testMethod static void testCommentEndPoint3() {

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        Account acc = [SELECT id FROM Account LIMIT 1];

        UD_Ticket__mdt udTicket = UDUtility.getClientId();

        req.addHeader('httpMethod', 'POST');
        req.addHeader('ClientId', udTicket.Client_Id__c);
        req.addHeader('SecretKey', udTicket.Secret_Key__c);
        req.addHeader('Content-Type', 'application/json');

        Ticket_Issue__c t = [SELECT id FROM Ticket_Issue__c LIMIT 1];

        req.requestUri = '/services/apexrest/v1/Comment/';
        String postData = '{"UserLastName":"Gibson Admin Gibson Admin Gibson Admin Gibson Admin Gibson Admin Gibson Admin Gibson Admin Gibson Admin Gibson Admin Gibson Admin Gibson Admin Gibson Admin Gibson Admin Gibson Admin Gibson Admin Gibson Admin Gibson Admin Gibson Admin Gibson Admin Gibson Admin Gibson Admin Gibson Admin Gibson Admin ","UserFirstName":"Chris","UDCommentID":null,"TicketSFID":"test","CommentSFID":"a0h1U000006v0ZmQAI","Comment":"<p>Test 1</p>"}';
        req.requestBody = Blob.valueof(postData);
        RestContext.request = req;
        RestContext.response= res;

        Test.startTest();
        try{
            UDCommentRestEndPoint.doPost();
        } catch (Exception e) {

        }

        //Comment__c c = [SELECT id FROM Comment__c LIMIT 1];


        req.requestUri = '/services/apexrest/v1/Comment/'+'Test';
        req.addHeader('httpMethod', 'PUT');

        try{
            UDCommentRestEndPoint.doPut();
        } catch (Exception e) {

        }

        Test.stopTest();

    }



}