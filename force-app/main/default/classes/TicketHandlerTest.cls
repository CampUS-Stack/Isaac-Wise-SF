/**
 * Created by Kritik Garg on 24-03-2020.
 */

@IsTest
private class TicketHandlerTest {

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

        Test.startTest();
        Ticket_Issue__c t = [SELECT id FROM Ticket_Issue__c LIMIT 1];
        t.Title__c = 'Test 1';
        t.UD_Ticket_Id__c = 'test';
        update t;

        Test.stopTest();

    }
 
}