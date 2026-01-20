/**
 * Created by Kritik Garg on 18-01-2020.
 */

public with sharing class UDCommentCallout {
    

    @future (callout=true)
    public static void syncOldComment(List<Id> listOfCommentId) {

        List<Comment__c> listOfComment = new List<Comment__c>();
        listOfComment = [SELECT id, Comment__c, UD_Comment_Id__c, Ticket__c, Ticket__r.UD_Ticket_Id__c, CreatedBy.FirstName, CreatedBy.LastName FROM Comment__c WHERE id IN :listOfCommentId];

        //UDTokenWrapper tokenWrapper = UDCommentCallout.generateTokens();
        UD_Ticket__mdt udTicket = UDUtility.getClientId();
        String endpoint = udTicket.Base_End_Point__c + 'services/apexrest/v1/Comment/';

        for(Comment__c co : listOfComment) {

            CommentWrapper cw = new CommentWrapper(co);

            Http http = new Http();
            HttpRequest req = new HttpRequest();
            req.setMethod('PUT');
            req.setEndpoint(endpoint+co.UD_Comment_Id__c);
            //req.setHeader('Authorization', 'Bearer ' + tokenWrapper.access_token);
            req.setHeader('ClientId', udTicket.Client_Id__c);
            req.setHeader('SecretKey', udTicket.Secret_Key__c);
            req.setHeader('Content-Type','application/json');
            req.setBody(JSON.serialize(cw));
            System.debug(JSON.serialize(cw));

            try {
                system.debug(req.getBody());
                HttpResponse resp = http.send(req);
                System.debug(resp.getBody());
                CommentResponseWrapper result = (CommentResponseWrapper)JSON.deserialize(resp.getBody(),CommentResponseWrapper.class);
                System.debug(result);

            } catch (CalloutException ce) {
                System.debug(ce.getMessage());
                String returnMsg = 'FAIL ' + ce.getMessage();
                return ;
            }catch (QueryException qe) {
                System.debug(qe.getMessage());
                String returnMsg = 'FAIL ' + qe.getMessage();
                return ;
            } catch (Exception e) {
                system.debug(e.getMessage());
            }
        }

    }

    @future (callout=true)
    public static void syncNewComment(List<Id> listOfCommentId) {

        List<Comment__c> listOfComment = new List<Comment__c>();
        listOfComment = [SELECT id, Comment__c, Ticket__c, Ticket__r.UD_Ticket_Id__c, CreatedBy.FirstName, CreatedBy.LastName FROM Comment__c WHERE id IN :listOfCommentId];

        UD_Ticket__mdt udTicket = UDUtility.getClientId();

        //UDTokenWrapper tokenWrapper = UDCommentCallout.generateTokens();
        String endpoint = udTicket.Base_End_Point__c + 'services/apexrest/v1/Comment/';

        for(Comment__c co : listOfComment) {

            CommentWrapper cw = new CommentWrapper(co);

            Http http = new Http();
            HttpRequest req = new HttpRequest();
            req.setMethod('POST');
            req.setEndpoint(endpoint);
            //req.setHeader('Authorization', 'Bearer ' + tokenWrapper.access_token);
            req.setHeader('ClientId', udTicket.Client_Id__c);
            req.setHeader('SecretKey', udTicket.Secret_Key__c);
            req.setHeader('Content-Type','application/json');
            req.setBody(JSON.serialize(cw));
            System.debug(JSON.serialize(cw));

            try {
                system.debug(req.getBody());
                HttpResponse resp = http.send(req);
                System.debug(resp.getBody());
                CommentResponseWrapper result = (CommentResponseWrapper)JSON.deserialize(resp.getBody(),CommentResponseWrapper.class);
                System.debug(result);

                co.UD_Comment_Id__c = result.Id;

            } catch (CalloutException ce) {
                System.debug(ce.getMessage());
                String returnMsg = 'FAIL ' + ce.getMessage();
                return ;
            }catch (QueryException qe) {
                System.debug(qe.getMessage());
                String returnMsg = 'FAIL ' + qe.getMessage();
                return ;
            } catch (Exception e) {
                system.debug(e.getMessage());
            }
        }

        update listOfComment;

    }


   /* public static UDTokenWrapper generateTokens() {

        String endpoint = BASE_ENDPOINT + 'services/oauth2/token?' + 'grant_type=password&client_id='
                + CLIENT_ID + '&client_secret=' + CLIENT_SECRET + '&username=' + USER_NAME + '&password=' + PASSWORD;

        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setEndpoint(endpoint);

        try {
            HttpResponse resp = http.send(req);
            UDTokenWrapper token = UDTokenWrapper.parse(resp.getBody());
            System.debug(resp.getBody());
            System.debug(token.access_token);

            return token;
        } catch (Exception e) {
            system.debug(e.getMessage());
            return null;
        }

    }*/


    public static String convertImage(String comment) {

        System.debug(comment);

        String commentToRet = '';

        List<String> listOfStrings = comment.split('img>');
        System.debug(listOfStrings);

        for(String s : listOfStrings) {

            if(s.contains('<img ')) {
                String img = s.substringBetween('<img ', '></');
                System.debug(img);
                String imgsrc = img.substringBetween('src="', '"');
                System.debug(imgsrc);

                imgsrc = imgsrc.replace('amp;', '');
                PageReference page = new PageReference(imgsrc);

                String strBase64 = '';
                if(!Test.isRunningTest()) {
                    Blob imgblob = page.getContent();
                    strBase64 = EncodingUtil.base64Encode(imgblob);
                }
                if(Test.isRunningTest()) {
                    strBase64 = '';
                }

                //System.debug(strBase64);

                String toReplace = 'src="data:image/png;base64,' + strBase64 + '"';

                s = s.replace(img + '></', toReplace + '></img>');
            }
            commentToRet += s;
        }

        return commentToRet;

    }



    public class CommentWrapper {

        public String TicketSFID {get;set;}
        public String CommentSFID {get;set;}
        public String UDCommentID {get;set;}
        public String Comment {get;set;}
        public String UserFirstName {get;set;}
        public String UserLastName {get;set;}


        public CommentWrapper(Comment__c com) {
            TicketSFID = com.Ticket__r.UD_Ticket_Id__c;
            CommentSFID = com.Id;
            comment = UDCommentCallout.convertImage(com.Comment__c);
            UserFirstName = com.CreatedBy.FirstName;
            UserLastName = com.CreatedBy.LastName;
        }

    }


    public class CommentResponseWrapper {
        public Attribute attributes { get; set; }
        public String Id { get; set; }
    }

    public class Attribute {
        public String type;
        public String url;
    }



}