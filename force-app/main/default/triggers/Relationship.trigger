/**
 * Created by Chris Home Desktop on 8/16/2017.
 */

trigger Relationship on Relationship_Affiliation__c (before insert, before update) {


    TriggerHandler.TriggerHandlerEntry(new TriggerState(trigger.isBefore, trigger.isAfter, trigger.isUpdate,
            trigger.isDelete, trigger.isInsert, trigger.isExecuting, trigger.new, trigger.newMap, trigger.old, trigger.oldMap));
}