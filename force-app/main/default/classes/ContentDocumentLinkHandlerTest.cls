/**
 * Created by Kritik Garg on 24-03-2020.
 */

@IsTest
private class ContentDocumentLinkHandlerTest {

    @testSetup
    static void testBehavior() {

        Account acc = new Account();
        acc.Name = 'Test Account';
        insert acc;

        Ticket_Issue__c t = new Ticket_Issue__c();
        t.Status__c = 'New';
        t.Title__c = 'Test';
        t.Description__c = 'Test';
        insert t;
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        ContentVersion cv = new ContentVersion();
        cv.VersionData = EncodingUtil.base64Decode('Test');
        cv.FirstPublishLocationId = t.Id;
        cv.Title = 'Test Title';
        cv.PathOnClient = 'TestTitle';
        cv.Description = 'test';
        insert cv;

    }

    public testMethod static void testTicketEndPoint1() {

        Ticket_Issue__c t = [SELECT id FROM Ticket_Issue__c LIMIT 1];

        Test.startTest();
        ContentVersion cv = new ContentVersion();
        cv.VersionData = EncodingUtil.base64Decode('Test');
        cv.FirstPublishLocationId = t.Id;
        cv.Title = 'Test Title';
        cv.PathOnClient = 'TestTitle';
        insert cv;

        Test.stopTest();

    }

    public testMethod static void testTicketEndPoint2() {

        Ticket_Issue__c t = [SELECT id FROM Ticket_Issue__c LIMIT 1];

        Test.startTest();
        ContentDocumentLink cdl = [SELECT id, LinkedEntityId, Visibility FROM ContentDocumentLink WHERE LinkedEntityId = :t.Id LIMIT 1];
        cdl.Visibility = 'AllUsers';
        update cdl;

        cdl.Visibility = 'AllUsers';
        update cdl;
        Test.stopTest();

    }
}