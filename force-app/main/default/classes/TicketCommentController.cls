/**
 * Created by Kritik Garg on 16-02-2020.
 */

public with sharing class TicketCommentController {

    @AuraEnabled
    public static List <CommentWrapper> getCommentsByIssueId(String ticketId) {
        System.debug(ticketId);

        List<CommentWrapper> listOfCommentWrappers = new List<CommentWrapper>();

        List<Comment__c> listOfComment = [SELECT id, Comment__c, LastModifiedDate, User_First_Name__c, User_Last_Name__c, CreatedBy.Name, CreatedBy.UserType FROM Comment__c WHERE Ticket__c = :ticketId ORDER BY LastModifiedDate];
        System.debug(listOfComment);

        for (Comment__c c : listOfComment) {
            listOfCommentWrappers.add(new CommentWrapper(c));
        }

        return listOfCommentWrappers;
    }


    @AuraEnabled
    public static CommentWrapper postComment(String ticketId, String commentString) {

        Comment__c comm = new Comment__c();
        comm.Comment__c = commentString;
        comm.Ticket__c = ticketId;

        try{
            insert comm;
        } catch (Exception e) {
            throw new CustomException(e.getMessage());
        }

        System.debug(ticketId);
        return new CommentWrapper(comm);
    }


    public class CommentWrapper {
        @AuraEnabled public Comment__c comment { get; set; }
        @AuraEnabled public String UserName { get; set; }


        public CommentWrapper(Comment__c c) {
            this.comment = c;
            UserName = '';
            if(c.CreatedBy.UserType == 'Guest' || Test.isRunningTest()) {
                if (c.User_First_Name__c != null && c.User_Last_Name__c != '') {
                    UserName += c.User_First_Name__c + ' ';
                }
                if (c.User_Last_Name__c != null && c.User_Last_Name__c != '') {
                    UserName += c.User_Last_Name__c;
                }
                if (UserName.length() == 0) {
                    UserName = 'Unknown';
                }
            } else {
                UserName = c.CreatedBy.Name;
            }

        }
    }

    public class CustomException extends Exception {
    }
}