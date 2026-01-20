/**
 * Created by Chris Home Desktop on 5/21/2017.
 */

trigger Yahrzeit on Yahrzeit__c (before insert, before update, after insert) {

    TriggerHandler.TriggerHandlerEntry(new TriggerState(trigger.isBefore, trigger.isAfter, trigger.isUpdate,
            trigger.isDelete, trigger.isInsert, trigger.isExecuting, trigger.new, trigger.newMap, trigger.old, trigger.oldMap));
}