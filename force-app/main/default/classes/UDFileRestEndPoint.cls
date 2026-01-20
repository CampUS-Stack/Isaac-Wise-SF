/**
 * Created by Kritik Garg on 12-03-2020.
 */

@RestResource(urlMapping='/v1/File/*')
global without sharing class UDFileRestEndPoint {


    @HttpGet
    global static void doGet() {

        RestRequest req = RestContext.request;
        String fileId = req.requestURI.substring(req.requestURI.lastIndexOf('/') + 1);
        Map<String, String> reqHeaders = req.headers;
        RestResponse res = RestContext.response;

        System.debug(fileId);

        String validationResponse = UDUtility.validateClientSecret(reqHeaders.get('ClientId'), reqHeaders.get('SecretKey'));
        if (validationResponse != UDUtility.VALIDATION_SUCCESS) {
            res.responseBody = Blob.valueOf(JSON.serialize(new UDUtility.ErrorWrapper(validationResponse)));
            res.statusCode = 401;
            return ;
        }

        try {
            List<ContentVersion> contentVersions = [SELECT VersionData, Title,FileExtension, Description, FileType FROM ContentVersion WHERE ContentDocumentId = :fileId AND IsLatest = true];

            System.debug(contentVersions);

            List<UDTicketFileWrapper> fileWrappers = new List<UDTicketFileWrapper>();
            for (ContentVersion cv : contentVersions) {
                fileWrappers.add(new UDTicketFileWrapper(cv.Title, cv.Id, cv.FileExtension, EncodingUtil.base64Encode(cv.VersionData), cv.Description ));
            }

            res.responseBody = Blob.valueOf(JSON.serialize(fileWrappers.get(0)));
            res.statusCode = 200;

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


}