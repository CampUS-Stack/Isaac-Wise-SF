/**
 * Created by Kritik Garg on 09-01-2020.
 */

trigger Ticket on Ticket_Issue__c (after insert, after update) {

    TriggerHandler.TriggerHandlerEntry(new TriggerState(trigger.isBefore, trigger.isAfter, trigger.isUpdate,
            trigger.isDelete, trigger.isInsert, trigger.isExecuting, trigger.new, trigger.newMap, trigger.old, trigger.oldMap));

}