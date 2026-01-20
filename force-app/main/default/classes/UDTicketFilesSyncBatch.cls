/**
 * Created by Kritik Garg on 14-03-2020.
 */


global class UDTicketFilesSyncBatch implements Database.Batchable<UDTicketFileWrapper>, Database.Stateful, Database.AllowsCallouts {

    global Integer recordsProcessed = 0;
    global String ticketId { get; set; }


    public UDTicketFilesSyncBatch(String tickId) {
        ticketId = tickId;
    }

    global Iterable<UDTicketFileWrapper> start(Database.BatchableContext bc) {
        List<UDTicketFileWrapper> ticketFileWrappers = UDFilesCallout.getTicketFilesIds(ticketId);
        return ticketFileWrappers;
    }

    global void execute(Database.BatchableContext bc, List<UDTicketFileWrapper> records) {

        if (records != null && records.size() > 0) {

            for (UDTicketFileWrapper fw : records) {

                UDTicketFileWrapper fileWithData = UDFilesCallout.getFileWithData(fw.FileId, ticketId);
                findAndUpdateFile(ticketId, fileWithData);
                System.debug(fileWithData);
            }
        }
    }

    global void finish(Database.BatchableContext bc) {

    }

    private void findAndUpdateFile(Id ticketId, UDTicketFileWrapper fileData) {

        ContentVersion udContentVersion = new ContentVersion();
        if (fileData.Description != null) {
            List<ContentVersion> listOfContentVersions = [SELECT id, ContentDocumentId FROM ContentVersion WHERE Id = :fileData.Description];
            if (listOfContentVersions.size() > 0) {
                udContentVersion = listOfContentVersions.get(0);
            }
        }


        if (udContentVersion.Id == null) {

            List<ContentVersion> listOfContentVersions = [SELECT id, ContentDocumentId FROM ContentVersion WHERE Description = :fileData.FileId];
            List<ContentDocument> listToDelete = new List<ContentDocument>();
            for (ContentVersion conver : listOfContentVersions) {
                listToDelete.add(new ContentDocument(Id = conver.ContentDocumentId));
            }
            delete listToDelete;

            ContentVersion cv = new ContentVersion();
            cv.versionData = EncodingUtil.base64Decode(fileData.Body);
//cv.title = 'ContractPDF_' + Datetime.now() + '.pdf';
            cv.title = fileData.FileName ;
            cv.Description = fileData.FileId;
            cv.pathOnClient = fileData.FileName + '.' + fileData.FileExt;
            insert cv;


            cv = [SELECT ContentDocumentId FROM ContentVersion WHERE id = :cv.Id];
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = cv.ContentDocumentId;
            cdl.LinkedEntityId = ticketId;
            cdl.Visibility = 'AllUsers';
            cdl.ShareType = 'I';
            insert cdl;
        } else {

            udContentVersion.Description = fileData.FileId;
            update udContentVersion;

        }

//List<ContentDocumentLink> listOfContentDocumentLinks = [SELECT id, ];

    }

}