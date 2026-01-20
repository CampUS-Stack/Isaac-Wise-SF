/**
 * Created by Kritik Garg on 24-03-2020.
 */

@IsTest
private class UDCommentCalloutTest {

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

    public testMethod static void testCommentCallout() {

        Ticket_Issue__c t = [SELECT id FROM Ticket_Issue__c LIMIT 1];

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
        Comment__c com = new Comment__c();
        com.Comment__c = 'Test Comment <img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+P+/HgAFhAJ/wlseKgAAAABJRU5ErkJggg==">';
        com.Ticket__c = t.Id;
        insert com;

        List<Id> listOfIds = new List<Id>();
        listOfIds.add(com.Id);

        UDCommentCallout.syncNewComment(listOfIds);
        UDCommentCallout.syncOldComment(listOfIds);
        Test.stopTest();

    }



}