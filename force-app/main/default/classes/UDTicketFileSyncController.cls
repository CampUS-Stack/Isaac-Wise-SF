/**
 * Created by Kritik Garg on 15-03-2020.
 */

public with sharing class UDTicketFileSyncController {

    public UDTicketFileSyncController(ApexPages.StandardController controller) {

    }

    public PageReference executeBatch() {

        String ticketId = ApexPages.currentPage().getParameters().get('id');

        UDTicketFilesSyncBatch b1 = new UDTicketFilesSyncBatch(ticketId);
        ID batchprocessid = Database.executeBatch(b1, 1);

        System.debug(ticketId);
        System.debug(batchprocessid);

        PageReference pageRef = new PageReference('/'+ticketId);

        return pageRef;

    }

}