/**
 * Created by Kritik Garg on 12-03-2020.
 */

trigger ContentDocumentLink on ContentDocumentLink (before insert, before update) {

    TriggerHandler.TriggerHandlerEntry(new TriggerState(trigger.isBefore, trigger.isAfter, trigger.isUpdate,
            trigger.isDelete, trigger.isInsert, trigger.isExecuting, trigger.new, trigger.newMap, trigger.old, trigger.oldMap));
    
}