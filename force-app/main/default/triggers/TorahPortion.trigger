/**
 * Created by Chris Home Desktop on 5/29/2017.
 */

trigger TorahPortion on Torah_Portion__c (before insert, before update) {

    TriggerHandler.TriggerHandlerEntry(new TriggerState(trigger.isBefore, trigger.isAfter, trigger.isUpdate,
            trigger.isDelete, trigger.isInsert, trigger.isExecuting, trigger.new, trigger.newMap, trigger.old, trigger.oldMap));

}