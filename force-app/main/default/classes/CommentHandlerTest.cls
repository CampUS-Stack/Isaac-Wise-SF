/**
 * Created by Kritik Garg on 24-03-2020.
 */

@IsTest
private class CommentHandlerTest {
    @testSetup
    static void testDataSetup() {

     /*   UD_Ticket__mdt udTicket = new UD_Ticket__mdt();
        udTicket.MasterLabel ='UD3';
        udTicket.Client_Id__c = 'testClientId';
        udTicket.Secret_Key__c = 'testSecretKey';
        udTicket.Base_End_Point__c = 'https://moketest/';
        insert udTicket;*/

        Account acc = new Account();
        acc.Name = 'Test Account';
        insert acc;

        Ticket_Issue__c t = new Ticket_Issue__c();
        t.Status__c = 'New';
        t.Title__c = 'Test';
        t.Description__c = 'Test';
        insert t;
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
        Comment__c com = new Comment__c();
        com.Comment__c = 'Test Comment <img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+P+/HgAFhAJ/wlseKgAAAABJRU5ErkJggg==">';
        com.Ticket__c = t.Id;
        insert com;

        com.Comment__c = 'Test';
        update com;
        Test.stopTest();

    }

    public testMethod static void testCommentCallout() {

        Comment__c c = [SELECT id FROM Comment__c LIMIT 1];

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();

        c.Comment__c = 'Test';
        update c;
        Test.stopTest();

    }

    public testMethod static void testCommentCallout2() {

        Ticket_Issue__c t = [SELECT id FROM Ticket_Issue__c LIMIT 1];

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();

        Comment__c com = new Comment__c();
        com.Comment__c = 'Test Comment 2 <img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+P+/HgAFhAJ/wlseKgAAAABJRU5ErkJggg==">';
        com.Ticket__c = t.Id;
        insert com;

        Test.stopTest();

    }

}