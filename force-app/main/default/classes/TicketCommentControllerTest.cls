/**
 * Created by Kritik Garg on 24-03-2020.
 */

@IsTest
private class TicketCommentControllerTest {
    @testSetup static void testDatasetup() {

        Account acc = new Account();
        acc.Name = 'Test Account';
        insert acc;

        Ticket_Issue__c t = new Ticket_Issue__c();
        t.Status__c = 'New';
        t.Title__c = 'Test';
        t.Description__c = 'Test';
        insert t;

        Comment__c com = new Comment__c();
        com.Comment__c = 'Test Comment';
        com.Ticket__c = t.Id;
        com.User_First_Name__c = 'Test';
        com.User_Last_Name__c = 'Test';
        insert com;

    }

    public testMethod static void testCommentEndPoint1() {

        Comment__c c = [SELECT id FROM Comment__c LIMIT 1] ;
        Ticket_Issue__c t = [SELECT id FROM Ticket_Issue__c LIMIT 1];
        TicketCommentController.getCommentsByIssueId(t.Id);
        TicketCommentController.postComment(t.Id, 'Test');

    }

}