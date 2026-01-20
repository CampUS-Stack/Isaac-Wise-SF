/**
 * Created by Kritik Garg on 09-01-2020.
 */

public without sharing class UDTicketCallout {

    @future(callout=true)
    public static void syncNewTickets(List<Id> listOfTicketId) {

        UD_Ticket__mdt udTicket = UDUtility.getClientId();

        List<Ticket_Issue__c> listOfTicket = new List<Ticket_Issue__c>();
        listOfTicket = [
                SELECT id, Name, UD_Ticket_Id__c, Status__c, Description__c, Priority__c, Title__c, CreatedBy.Email,
                        Additional_Email_to_Notify_1__c, Additional_Email_to_Notify_2__c, Additional_Email_to_Notify_3__c
                FROM Ticket_Issue__c
                WHERE id IN :listOfTicketId
        ];

        //UDTokenWrapper tokenWrapper = UDTicketCallout.generateTokens();
        String endpoint = udTicket.Base_End_Point__c + 'services/apexrest/v1/Ticket/';

        for (Ticket_Issue__c ti : listOfTicket) {
            TicketWrapper tw = new TicketWrapper(ti, UserInfo.getOrganizationId());

            Http http = new Http();
            HttpRequest req = new HttpRequest();
            req.setMethod('POST');
            req.setEndpoint(endpoint);
            req.setHeader('ClientId', udTicket.Client_Id__c);
            req.setHeader('SecretKey', udTicket.Secret_Key__c);
            //req.setHeader('Authorization', 'Bearer ' + tokenWrapper.access_token);
            req.setHeader('Content-Type', 'application/json');
            req.setBody(JSON.serialize(tw));
            System.debug(JSON.serialize(tw));

            try {
                system.debug(req.getBody());
                HttpResponse resp = http.send(req);
                System.debug(resp.getBody());
                TicketResponseWrapper result = (TicketResponseWrapper) JSON.deserialize(resp.getBody(), TicketResponseWrapper.class);
                System.debug(result);

                ti.UD_Ticket_Id__c = result.Id;

            } catch (CalloutException ce) {
                System.debug(ce.getMessage());
                String returnMsg = 'FAIL ' + ce.getMessage();
                return ;
            } catch (QueryException qe) {
                System.debug(qe.getMessage());
                String returnMsg = 'FAIL ' + qe.getMessage();
                return ;
            } catch (Exception e) {
                system.debug(e.getMessage());
            }
        }

        update listOfTicket;

    }


    @future(callout=true)
    public static void syncOldTickets(List<Id> listOfTicketId) {

        UD_Ticket__mdt udTicket = UDUtility.getClientId();

        List<Ticket_Issue__c> listOfTicket = new List<Ticket_Issue__c>();
        listOfTicket = [
                SELECT id, Name, Status__c, UD_Ticket_Id__c, Title__c, Description__c, Priority__c, CreatedBy.Email,
                        Additional_Email_to_Notify_1__c, Additional_Email_to_Notify_2__c, Additional_Email_to_Notify_3__c
                FROM Ticket_Issue__c
                WHERE id IN :listOfTicketId
        ];

        //UDTokenWrapper tokenWrapper = UDTicketCallout.generateTokens();
        String endpoint = udTicket.Base_End_Point__c + 'services/apexrest/v1/Ticket/';

        for (Ticket_Issue__c ti : listOfTicket) {
            TicketWrapper tw = new TicketWrapper(ti, UserInfo.getOrganizationId());

            Http http = new Http();
            HttpRequest req = new HttpRequest();
            req.setMethod('PUT');
            req.setEndpoint(endpoint + ti.UD_Ticket_Id__c);
            //req.setHeader('Authorization', 'Bearer ' + tokenWrapper.access_token);
            req.setHeader('ClientId', udTicket.Client_Id__c);
            req.setHeader('SecretKey', udTicket.Secret_Key__c);
            req.setHeader('Content-Type', 'application/json');
            req.setBody(JSON.serialize(tw));
            System.debug(JSON.serialize(tw));

            try {
                system.debug(req.getBody());
                HttpResponse resp = http.send(req);
                System.debug(resp.getBody());
                TicketResponseWrapper result = (TicketResponseWrapper) JSON.deserialize(resp.getBody(), TicketResponseWrapper.class);
                System.debug(result);

                //ti.UD_Ticket_Id__c = result.Id;

            } catch (CalloutException ce) {
                System.debug(ce.getMessage());
                String returnMsg = 'FAIL ' + ce.getMessage();
                return ;
            } catch (QueryException qe) {
                System.debug(qe.getMessage());
                String returnMsg = 'FAIL ' + qe.getMessage();
                return ;
            } catch (Exception e) {
                system.debug(e.getMessage());
            }
        }

        //update listOfTicket;

    }

/*
    public static UDTokenWrapper generateTokens() {

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

        for (String s : listOfStrings) {

            if (s.contains('<img ')) {
                String img = s.substringBetween('<img ', '></');
                System.debug(img);
                String imgsrc = img.substringBetween('src="', '"');
                System.debug(imgsrc);

                imgsrc = imgsrc.replace('amp;', '');
                PageReference page = new PageReference(imgsrc);

                String strBase64 = '';
                if (!Test.isRunningTest()) {
                    Blob imgblob = page.getContent();
                    strBase64 = EncodingUtil.base64Encode(imgblob);
                }
                if (Test.isRunningTest()) {
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


    public class TicketWrapper {

        public String OrgId { get; set; }
        public String TicketSFID { get; set; }
        public String Status { get; set; }
        public String Description { get; set; }
        public String Priority { get; set; }
        public String TicketTitle { get; set; }
        public String TicketNumber { get; set; }
        public String ClientTicketSFId { get; set; }
        public String SubmitterEmail { get; set; }

        public String AdditionalEmail1 { get; set; }
        public String AdditionalEmail2 { get; set; }
        public String AdditionalEmail3 { get; set; }

        public TicketWrapper(Ticket_Issue__c ticketIssue, String oId) {
            OrgId = oId;
            TicketSFID = ticketIssue.UD_Ticket_Id__c;
            Status = ticketIssue.Status__c;
            Description = UDTicketCallout.convertImage(ticketIssue.Description__c);
            Priority = ticketIssue.Priority__c;
            TicketTitle = ticketIssue.Title__c;
            TicketNumber = ticketIssue.Name;
            ClientTicketSFId = ticketIssue.Id;
            SubmitterEmail = ticketIssue.CreatedBy.Email;
            AdditionalEmail1 = ticketIssue.Additional_Email_to_Notify_1__c;
            AdditionalEmail2 = ticketIssue.Additional_Email_to_Notify_2__c;
            AdditionalEmail3 = ticketIssue.Additional_Email_to_Notify_3__c;
        }
    }

    public class TicketResponseWrapper {
        public Attribute attributes { get; set; }
        public String Id { get; set; }
    }


    public class Attribute {
        public String type;
        public String url;
    }


}