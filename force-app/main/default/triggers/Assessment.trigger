/**
 * Created by Chris Home Desktop on 4/27/2018.
 */

trigger Assessment on Assessment__c (after delete, before delete, after insert, after update) {

    TriggerHandler.TriggerHandlerEntry(new TriggerState(trigger.isBefore, trigger.isAfter, trigger.isUpdate,
            trigger.isDelete, trigger.isInsert, trigger.isExecuting, trigger.new, trigger.newMap, trigger.old, trigger.oldMap));
}