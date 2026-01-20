/**
 * Created by Kritik Garg on 14-03-2020.
 */

public without sharing class UDFilesCallout {

    public static List<UDTicketFileWrapper> getTicketFilesIds(Id TicketId) {

        UD_Ticket__mdt udTicket = UDUtility.getClientId();

        List<Ticket_Issue__c> listOfTicket = new List<Ticket_Issue__c>();
        listOfTicket = [SELECT id, Name, UD_Ticket_Id__c, Status__c, Description__c, Priority__c, Title__c FROM Ticket_Issue__c WHERE id =:TicketId];

        if(listOfTicket.size()<1) {
            return null;
        }
        Ticket_Issue__c ti = listOfTicket.get(0);

        //UDTokenWrapper tokenWrapper = UDTicketCallout.generateTokens();
        String endpoint = udTicket.Base_End_Point__c + 'services/apexrest/v1/TicketFiles/';

        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setMethod('GET');
        req.setEndpoint(endpoint+ti.UD_Ticket_Id__c);
        req.setHeader('ClientId', udTicket.Client_Id__c);
        req.setHeader('SecretKey', udTicket.Secret_Key__c);
        req.setHeader('Content-Type', 'application/json');

        try {
            HttpResponse resp = http.send(req);
            System.debug(resp.getBody());
            List<UDTicketFileWrapper> result = (List<UDTicketFileWrapper>) JSON.deserialize(resp.getBody(), List<UDTicketFileWrapper>.class);
            System.debug(resp.getBody());
            return result;

        } catch (CalloutException ce) {
            System.debug(ce.getMessage());
            String returnMsg = 'FAIL ' + ce.getMessage();
            return null;
        } catch (QueryException qe) {
            System.debug(qe.getMessage());
            String returnMsg = 'FAIL ' + qe.getMessage();
            return null;
        } catch (Exception e) {
            system.debug(e.getMessage());
            return null;

        }

    }


    public static UDTicketFileWrapper getFileWithData(Id fileId, Id TicketId) {

        UD_Ticket__mdt udTicket = UDUtility.getClientId();

        List<Ticket_Issue__c> listOfTicket = new List<Ticket_Issue__c>();
        listOfTicket = [SELECT id, Name, UD_Ticket_Id__c, Status__c, Description__c, Priority__c, Title__c FROM Ticket_Issue__c WHERE id =:TicketId];

        if(listOfTicket.size()<1) {
            return null;
        }
        Ticket_Issue__c ti = listOfTicket.get(0);


        //UDTokenWrapper tokenWrapper = UDTicketCallout.generateTokens();
        String endpoint = udTicket.Base_End_Point__c + 'services/apexrest/v1/File/';

        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setMethod('GET');
        req.setEndpoint(endpoint+fileId);
        req.setHeader('ClientId', udTicket.Client_Id__c);
        req.setHeader('SecretKey', udTicket.Secret_Key__c);
        req.setHeader('Content-Type', 'application/json');

        try {
            //system.debug(req.getBody());
            HttpResponse resp = http.send(req);
            //System.debug(resp.getBody());
            UDTicketFileWrapper result = (UDTicketFileWrapper) JSON.deserialize(resp.getBody(), UDTicketFileWrapper.class);
            //System.debug(resp.getBody());
            return result;

        } catch (CalloutException ce) {
            System.debug(ce.getMessage());
            String returnMsg = 'FAIL ' + ce.getMessage();
        } catch (QueryException qe) {
            System.debug(qe.getMessage());
            String returnMsg = 'FAIL ' + qe.getMessage();
        } catch (Exception e) {
            system.debug(e.getMessage());
        }

        return null;



    }

}