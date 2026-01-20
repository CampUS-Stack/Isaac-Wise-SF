/**
 * Created by Kritik Garg on 12-02-2020.
 */


@RestResource(urlMapping='/v1/Comment/*')
global without sharing class UDCommentRestEndPoint {

    @HttpPut
    global static void doPut() {
        RestRequest req = RestContext.request;
        Blob body = req.requestBody;
        String commentId = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);

        String requestString = body.toString();
        System.debug(requestString);
        Map<String,String> reqHeaders = req.headers;
        RestResponse res = RestContext.response;

        String validationResponse = UDUtility.validateClientSecret(reqHeaders.get('ClientId'),reqHeaders.get('SecretKey'));
        if(validationResponse != UDUtility.VALIDATION_SUCCESS) {
            res.responseBody = Blob.valueOf(JSON.serialize(new UDUtility.ErrorWrapper(validationResponse)));
            res.statusCode = 401;
            return ;
        }

        try{
            CommentWrapper cw = (CommentWrapper)JSON.deserialize(requestString,CommentWrapper.class);
            cw.CommentSFID = commentId;
            System.debug(cw.getComment());
            //System.debug(ow.getOpportunity());
            //res.responseBody = Blob.valueOf('Hey I am working');
            Comment__c commentToUpdate = cw.getComment();
            update commentToUpdate;
            Comment__c c = [SELECT id FROM Comment__c WHERE id =:commentToUpdate.Id];
            res.responseBody = Blob.valueOf(JSON.serialize(c));
            res.statusCode = 201;
        } catch (QueryException qe) {
            System.debug(qe.getMessage());
            res.responseBody = Blob.valueOf(JSON.serialize(qe));
            res.statusCode = 400;
            return ;
        } catch (DmlException de) {
            System.debug(de.getMessage());
            res.responseBody = Blob.valueOf(JSON.serialize(de));
            res.statusCode = 400;
            return ;
        } catch (Exception e) {
            res.responseBody = Blob.valueOf(JSON.serialize(e));
            res.statusCode = 400;
            return ;
        }

    }


    @HttpPost
    global static void doPost() {

        RestRequest req = RestContext.request;
        Blob body = req.requestBody;
        String requestString = body.toString();
        System.debug(requestString);
        Map<String,String> reqHeaders = req.headers;
        RestResponse res = RestContext.response;

        String validationResponse = UDUtility.validateClientSecret(reqHeaders.get('ClientId'),reqHeaders.get('SecretKey'));
        if(validationResponse != UDUtility.VALIDATION_SUCCESS) {
            res.responseBody = Blob.valueOf(JSON.serialize(new UDUtility.ErrorWrapper(validationResponse)));
            res.statusCode = 401;
            return ;
        }

        try{
            CommentWrapper cw = (CommentWrapper)JSON.deserialize(requestString,CommentWrapper.class);
            cw.CommentSFID = null;
            System.debug(cw.getComment());
            //System.debug(ow.getOpportunity());
            //res.responseBody = Blob.valueOf('Hey I am working');
            Comment__c commentToInsert = cw.getComment();
            insert commentToInsert;

            Comment__c t = [SELECT id FROM Comment__c WHERE id =:commentToInsert.Id];

            res.responseBody = Blob.valueOf(JSON.serialize(t));
            res.statusCode = 201;
        } catch (QueryException qe) {
            System.debug(qe.getMessage());
            res.responseBody = Blob.valueOf(JSON.serialize(qe));
            res.statusCode = 400;
            return ;
        } catch (DmlException de) {
            System.debug(de.getMessage());
            res.responseBody = Blob.valueOf(JSON.serialize(de));
            res.statusCode = 400;
            return ;
        } catch (Exception e) {
            res.responseBody = Blob.valueOf(JSON.serialize(e));
            res.statusCode = 400;
            return ;
        }
    }



    public class CommentWrapper {

        public String TicketSFID {get;set;}
        public String CommentSFID {get;set;}
        public String UDCommentID {get;set;}
        public String Comment {get;set;}
        public String UserFirstName {get;set;}
        public String UserLastName {get;set;}

        public Comment__c getComment() {
            Comment__c com;
            if(CommentSFID != null) {
                com = new Comment__c(id = CommentSFID);
            } else {
                com = new Comment__c();
            }

            com.Ticket__c = TicketSFID;
            com.Comment__c = Comment;
            com.UD_Comment_Id__c = UDCommentID;
            com.User_First_Name__c = UserFirstName;
            com.User_Last_Name__c = UserLastName;
            return com ;
        }

    }

}