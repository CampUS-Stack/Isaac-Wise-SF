/**
 * Created by Kritik Garg on 24-03-2020.
 */

@isTest
public class MockHttpResponseGenerator  implements HttpCalloutMock {

    public HTTPResponse respond(HTTPRequest req) {

        String fileListEndPoint = 'services/apexrest/v1/TicketFiles/';
        String fileDetailsEndPoint = 'services/apexrest/v1/File/';
        String commentEndPoint = 'services/apexrest/v1/Comment/';
        String ticketEndPoint = 'services/apexrest/v1/Ticket/';

        System.debug(req.getEndpoint());

        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(200);

        if(req.getEndpoint().contains(commentEndPoint)) {
            res.setBody('{"attributes":{"type":"Comment__c","url":"/services/data/v48.0/sobjects/Comment__c/a0h1U000006v17XQAQ"},"Id":"a0h1U000006v17XQAQ"}');
        }

        if(req.getEndpoint().contains(ticketEndPoint)) {
            res.setBody('{"attributes":{"type":"Ticket_Issue__c","url":"/services/data/v48.0/sobjects/Ticket_Issue__c/a0g1U000005q6sWQAQ"},"Id":"a0g1U000005q6sWQAQ"}');
        }
        if(req.getEndpoint().contains(fileListEndPoint)) {
            res.setBody('[{"FileName":"mail","FileId":"0691U000009w574QAA","FileExt":"png","Description":null,"Body":null}]');
        }
        if(req.getEndpoint().contains(fileDetailsEndPoint)) {
            String x = EncodingUtil.base64Encode(Blob.valueOf('Test'));
            res.setBody('{"FileName":"mail","FileId":"0691U000009w574QAA","FileExt":"png","Description":null,"Body":"'+x+'"}');
        }

        return res;
    }

}