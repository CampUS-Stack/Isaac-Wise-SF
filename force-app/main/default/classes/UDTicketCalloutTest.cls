/**
 * Created by Kritik Garg on 24-03-2020.
 */

@IsTest
private class UDTicketCalloutTest {

    @testSetup static void testDatasetup() {

        Account acc = new Account();
        acc.Name = 'Test Account';
        insert acc;


        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Ticket_Issue__c t = new Ticket_Issue__c();
        t.Status__c = 'New';
        t.Title__c = 'Test';
        t.Description__c = 'Test Comment <img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+P+/HgAFhAJ/wlseKgAAAABJRU5ErkJggg==">';
        insert t;

    }

    public testMethod static void testTicketEndPoint1() {

        Ticket_Issue__c t = [SELECT id FROM Ticket_Issue__c LIMIT 1];

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        List<Id> listOfIds = new List<Id>();
        listOfIds.add(t.Id);
        Test.startTest();
        UDTicketCallout.syncNewTickets(listOfIds);
        UDTicketCallout.syncOldTickets(listOfIds);
        Test.stopTest();

    }

    public testMethod static void testTicketEndPoint2() {

        Ticket_Issue__c t = [SELECT id FROM Ticket_Issue__c LIMIT 1];
        update t;
        List<Id> listOfIds = new List<Id>();
        listOfIds.add(t.Id);

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Test.startTest();
        UDTicketCallout.syncNewTickets(listOfIds);
        UDTicketCallout.syncOldTickets(listOfIds);
        Test.stopTest();
    }
}