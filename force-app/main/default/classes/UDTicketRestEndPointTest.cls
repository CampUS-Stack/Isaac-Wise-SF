/**
 * Created by Kritik Garg on 24-03-2020.
 */

@IsTest
private class UDTicketRestEndPointTest {
    @testSetup
    static void testBehavior() {
        Account acc = new Account();
        acc.Name = 'Test Account';
        insert acc;
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

        req.requestUri = '/services/apexrest/v1/Ticket/';
        String postData = '{"TicketTitle":"Test 1","TicketSFID":"a0Y4P00000GjYquUAF","TicketNumber":"T-0000049","Status":"In Progress","Priority":"High","OrgId":"00D1U000000DAJVUA4","Description":"<p>I am testing!</p>","ClientTicketSFId":"a0g1U000005q5LQQAY"}';
        req.requestBody = Blob.valueof(postData);
        RestContext.request = req;
        RestContext.response= res;

        Test.startTest();
        UDTicketRestEndPoint.doPost();

        Ticket_Issue__c t = [SELECT id FROM Ticket_Issue__c LIMIT 1];

        req.requestUri = '/services/apexrest/v1/Ticket/'+t.Id;
        req.addHeader('httpMethod', 'PUT');
        UDTicketRestEndPoint.doPut();

        Test.stopTest();

    }

    public testMethod static void testTicketEndPoint2() {

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        Account acc = [SELECT id FROM Account LIMIT 1];

        UD_Ticket__mdt udTicket = UDUtility.getClientId();

        req.addHeader('httpMethod', 'POST');
        req.addHeader('ClientId', udTicket.Client_Id__c);
        req.addHeader('Content-Type', 'application/json');

        req.requestUri = '/services/apexrest/v1/Ticket/';
        String postData = '{"TicketTitle":"Test 1","TicketSFID":"a0Y4P00000GjYquUAF","TicketNumber":"T-0000049","Status":"In Progress","Priority":"High","OrgId":"00D1U000000DAJVUA4","Description":"<p>I am testing!</p>","ClientTicketSFId":"a0g1U000005q5LQQAY"}';
        req.requestBody = Blob.valueof(postData);
        RestContext.request = req;
        RestContext.response= res;

        Test.startTest();
        UDTicketRestEndPoint.doPost();

        //Ticket__c t = [SELECT id FROM Ticket__c LIMIT 1];

        req.requestUri = '/services/apexrest/v1/Ticket/'+'test';
        req.addHeader('httpMethod', 'PUT');
        UDTicketRestEndPoint.doPut();

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
        req.addHeader('Content-Type', 'application/json');


        req.requestUri = '/services/apexrest/v1/Ticket/';
        String postData = '{"TicketTitle":"Test 1","TicketSFID":"a0Y4P00000GjYquUAF","TicketNumber":"T-0000049","Status":"In Progress","Priority":"High1","OrgId":"00D1U000000DAJVUA4","Description":"<p>I am testing!</p>","ClientTicketSFId":"a0g1U000005q5LQQAY"}';
        req.requestBody = Blob.valueof(postData);
        RestContext.request = req;
        RestContext.response= res;

        Test.startTest();
        try{
            UDTicketRestEndPoint.doPost();
        } catch (Exception e) {

        }

        req.requestUri = '/services/apexrest/v1/Ticket/'+'test';
        req.addHeader('httpMethod', 'PUT');

        try{
            UDTicketRestEndPoint.doPut();
        } catch (Exception e) {

        }

        Test.stopTest();

    }


}