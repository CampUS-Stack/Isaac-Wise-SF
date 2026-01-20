/**
 * Created by zacha on 5/28/2021.
 */

trigger Account on Account (after insert, after update) {
    TriggerHandler.TriggerHandlerEntry(new TriggerState(trigger.isBefore, trigger.isAfter, trigger.isUpdate,
            trigger.isDelete, trigger.isInsert, trigger.isExecuting, trigger.new, trigger.newMap, trigger.old, trigger.oldMap));

}