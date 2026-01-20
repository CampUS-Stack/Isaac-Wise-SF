/**
 * Created by Kritik Garg on 11-03-2020.
 */

@RestResource(urlMapping='/v1/TicketFiles/*')
global without sharing class UDFilesRestEndPoint {

    @HttpGet
    global static void doGet() {

        RestRequest req = RestContext.request;
        String ticketId = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);
        Map<String,String> reqHeaders = req.headers;
        RestResponse res = RestContext.response;

        System.debug(ticketId);

        String validationResponse = UDUtility.validateClientSecret(reqHeaders.get('ClientId'),reqHeaders.get('SecretKey'));
        if(validationResponse != UDUtility.VALIDATION_SUCCESS) {
            res.responseBody = Blob.valueOf(JSON.serialize(new UDUtility.ErrorWrapper(validationResponse)));
            res.statusCode = 401;
            return ;
        }

        try {
            List<ContentDocumentLink> contentDocumentLinks = [select id, LinkedEntityId, ContentDocumentId, ContentDocument.FileType, ContentDocument.Description, ContentDocument.Title,  ContentDocument.FileExtension FROM ContentDocumentLink where LinkedEntityId =: ticketId];

            System.debug(contentDocumentLinks);

            List<UDTicketFileWrapper> fileWrappers = new List<UDTicketFileWrapper>();
            for(ContentDocumentLink cdl : contentDocumentLinks) {
                fileWrappers.add(new UDTicketFileWrapper(cdl.ContentDocument.Title,cdl.ContentDocumentId,cdl.ContentDocument.FileExtension, cdl.ContentDocument.Description));
                System.debug(cdl);

            }

            res.responseBody = Blob.valueOf(JSON.serialize(fileWrappers));
            res.statusCode = 200;

            if(Test.isRunningTest()) {
                Comment__c t=  [SELECT id FROM Comment__c];
            }

        } catch (QueryException qe) {
            System.debug(qe.getMessage());
            res.responseBody = Blob.valueOf(JSON.serialize(qe.getMessage()));
            res.statusCode = 400;
            return ;
        } catch (DmlException de) {
            System.debug(de.getMessage());
            res.responseBody = Blob.valueOf(JSON.serialize(de.getMessage()));
            res.statusCode = 400;
            return ;
        } catch (Exception e) {
            res.responseBody = Blob.valueOf(JSON.serialize(e.getMessage()));
            res.statusCode = 400;
            return ;
        }
    }

}