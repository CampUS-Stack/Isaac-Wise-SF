/**
 * Created by Chris Home Desktop on 11/5/2017.
 */

trigger Batch on Batch__c (before update) {

    TriggerHandler.TriggerHandlerEntry(new TriggerState(trigger.isBefore, trigger.isAfter, trigger.isUpdate,
            trigger.isDelete, trigger.isInsert, trigger.isExecuting, trigger.new, trigger.newMap, trigger.old, trigger.oldMap));

}