/**
 * Created by Chris Home Desktop on 5/29/2017.
 */

trigger Contact on Contact (before insert, before update,after insert, after update, after delete ) {

    TriggerHandler.TriggerHandlerEntry(new TriggerState(trigger.isBefore, trigger.isAfter, trigger.isUpdate,
            trigger.isDelete, trigger.isInsert, trigger.isExecuting, trigger.new, trigger.newMap, trigger.old, trigger.oldMap));
}