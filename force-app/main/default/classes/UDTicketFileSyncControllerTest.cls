/**
 * Created by Kritik Garg on 24-03-2020.
 */

@isTest
private class UDTicketFileSyncControllerTest {

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

    public testMethod static void testCommentEndPoint1() {

        Ticket_Issue__c t = [SELECT id FROM Ticket_Issue__c LIMIT 1];

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        PageReference myVfPage = Page.UDTicketFileSync;
        Test.setCurrentPage(myVfPage);
        ApexPages.currentPage().getParameters().put('id',t.Id);

        ApexPages.StandardController sc = new ApexPages.StandardController(t);
        UDTicketFileSyncController ticketFileSyncController = new UDTicketFileSyncController(sc);
        ticketFileSyncController.executeBatch();

    }
}