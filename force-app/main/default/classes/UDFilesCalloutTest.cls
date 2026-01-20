/**
 * Created by Kritik Garg on 24-03-2020.
 */

@IsTest
private class UDFilesCalloutTest {
    @testSetup static void testDatasetup() {
        Account acc = new Account();
        acc.Name = 'Test Account';
        insert acc;

        Ticket_Issue__c t = new Ticket_Issue__c();
        t.Status__c = 'New';
        t.Title__c = 'Test';
        t.Description__c = 'Test';
        insert t;

        Ticket_Issue__c t1 = new Ticket_Issue__c();
        t1.Status__c = 'New';
        t1.Title__c = 'Test';
        t1.Description__c = 'Test';
        insert t1;

        ContentVersion cv = new ContentVersion();
        cv.VersionData = EncodingUtil.base64Decode('Test');
        cv.FirstPublishLocationId = t.Id;
        cv.Title = 'Test Title';
        cv.PathOnClient = 'TestTitle';
        insert cv;
    }

    public testMethod static void testTicketEndPoint1() {

        List<Ticket_Issue__c> tList = [SELECT id FROM Ticket_Issue__c LIMIT 2];

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
        UDFilesCallout.getTicketFilesIds(tList.get(0).id);
        UDFilesCallout.getFileWithData(tList.get(0).id, tList.get(0).id);
        UDFilesCallout.getTicketFilesIds(tList.get(1).id);
        UDFilesCallout.getFileWithData(tList.get(1).id, tList.get(1).id);
        Test.stopTest();

    }

    public testMethod static void testTicketEndPoint2() {

        Test.startTest();
        UDFilesCallout.getTicketFilesIds(UserInfo.getUserId());
        UDFilesCallout.getFileWithData(UserInfo.getUserId(),UserInfo.getUserId());

        Test.stopTest();
 
    }

    public testMethod static void testTicketEndPoint3() {

        List<Ticket_Issue__c> tList = [SELECT id FROM Ticket_Issue__c LIMIT 2];

        Test.startTest();
        UDFilesCallout.getTicketFilesIds(tList.get(0).id);
        UDFilesCallout.getFileWithData(tList.get(0).id, tList.get(0).id);
        UDFilesCallout.getTicketFilesIds(tList.get(1).id);
        UDFilesCallout.getFileWithData(tList.get(1).id, tList.get(1).id);
        Test.stopTest();

    }

}