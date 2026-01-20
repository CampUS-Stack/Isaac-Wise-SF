/**
 * Created by Kritik Garg on 08-02-2020.
 */

@RestResource(urlMapping='/v1/Ticket/*')
global without sharing class UDTicketRestEndPoint {


    @HttpPut
    global static void doPut() {
        RestRequest req = RestContext.request;
        Blob body = req.requestBody;
        String ticketId = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);

        String requestString = body.toString();
        System.debug(requestString);
        RestResponse res = RestContext.response;

        Map<String,String> reqHeaders = req.headers;
        String validationResponse = UDUtility.validateClientSecret(reqHeaders.get('ClientId'),reqHeaders.get('SecretKey'));
        if(validationResponse != UDUtility.VALIDATION_SUCCESS) {
            res.responseBody = Blob.valueOf(JSON.serialize(new UDUtility.ErrorWrapper(validationResponse)));
            res.statusCode = 401;
            return ;
        }

        try{
            TicketWrapper ow = (TicketWrapper)JSON.deserialize(requestString,TicketWrapper.class);
            ow.TicketSFID = ticketId;
            System.debug(ow.getTicket());
            //System.debug(ow.getOpportunity());
            //res.responseBody = Blob.valueOf('Hey I am working');
            Ticket_Issue__c ticketToInsert = ow.getTicket();
            update ticketToInsert;
            Ticket_Issue__c t = [SELECT id FROM Ticket_Issue__c WHERE id =:ticketToInsert.Id];
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


    @HttpPost
    global static void doPost() {

        RestRequest req = RestContext.request;
        Blob body = req.requestBody;

        String requestString = body.toString();
        System.debug(requestString);
        Map<String,String> reqHeaders = req.headers;
        System.debug(reqHeaders);
        RestResponse res = RestContext.response;

        String validationResponse = UDUtility.validateClientSecret(reqHeaders.get('ClientId'),reqHeaders.get('SecretKey'));
        if(validationResponse != UDUtility.VALIDATION_SUCCESS) {
            res.responseBody = Blob.valueOf(JSON.serialize(new UDUtility.ErrorWrapper(validationResponse)));
            res.statusCode = 401;
            return ;
        }

        try{
            TicketWrapper ow = (TicketWrapper)JSON.deserialize(requestString,TicketWrapper.class);
            ow.TicketSFID = null;
            System.debug(ow.getTicket());
            //System.debug(ow.getOpportunity());
            //res.responseBody = Blob.valueOf('Hey I am working');
            Ticket_Issue__c ticketToInsert = ow.getTicket();
            insert ticketToInsert;

            Ticket_Issue__c t = [SELECT id FROM Ticket_Issue__c WHERE id =:ticketToInsert.Id];
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

    public class TicketWrapper {

//        public String OrgId {get;set;}
        public String TicketSFID {get;set;}
        public String Status {get;set;}
        public String Description {get;set;}
        public String Priority {get;set;}
        public String TicketTitle { get; set; }
//        public String TicketNumber { get; set; }
        public String UDTicketSFId { get; set; }
        public String AdditionalEmail1 {get;set;}
        public String AdditionalEmail2 {get;set;}
        public String AdditionalEmail3 {get;set;}

        public Ticket_Issue__c getTicket() {
            Ticket_Issue__c ticket;
            if(TicketSFID != null) {
                ticket = new Ticket_Issue__c(id = TicketSFID);
            } else {
                ticket = new Ticket_Issue__c();
            }
            ticket.Status__c = Status;
            ticket.Description__c = Description;
            ticket.Priority__c = Priority;
            ticket.Title__c = TicketTitle;
            ticket.UD_Ticket_Id__c = UDTicketSFId;

            if(AdditionalEmail1 != null || AdditionalEmail1 != '') {
                ticket.Additional_Email_to_Notify_1__c = AdditionalEmail1;
            }
            if(AdditionalEmail2 != null || AdditionalEmail2 != '') {
                ticket.Additional_Email_to_Notify_2__c = AdditionalEmail2;
            }
            if(AdditionalEmail3 != null || AdditionalEmail3 != '') {
                ticket.Additional_Email_to_Notify_3__c = AdditionalEmail3;
            }

            return ticket ;
        }

    }

}