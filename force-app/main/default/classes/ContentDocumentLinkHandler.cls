/**
 * Created by Kritik Garg on 12-03-2020.
 */

public without sharing class ContentDocumentLinkHandler implements TriggerHandler.ITrigger {

    private Boolean hasExecuted { get; set; }

    public ContentDocumentLinkHandler() {
    }

    public void MainEntry(TriggerState state) {

        //system.debug('ContentDocumentLinkHandler Handler Main Entry Called.');
        system.debug('Firing object: ' + state.TriggerObject);

        if (state.IsBefore) {
            if (state.IsInsert) {
                processAfterInsert(state);
            }
            if (state.IsUpdate) {
                processAfterUpdate(state);
            }
        }
    }

    public void InProgressEntry(TriggerState state) {

        if (state.TriggerObject != 'ContentDocumentLink') {
            return;
        }
    }

    @TestVisible private void processAfterInsert(TriggerState state) {

        for (ContentDocumentLink cdl : (list<ContentDocumentLink>) state.NewList) {
            if (cdl.LinkedEntityId.getSObjectType().getDescribe().getName() == 'Ticket_Issue__c') {
                cdl.Visibility = 'AllUsers';
            }
        }

    }

    @TestVisible private void processAfterUpdate(TriggerState state) {

        for (ContentDocumentLink cdl : (list<ContentDocumentLink>) state.NewList) {
            if (cdl.LinkedEntityId.getSObjectType().getDescribe().getName() == 'Ticket_Issue__c') {
                cdl.Visibility = 'AllUsers';
            }
        }
    }

}