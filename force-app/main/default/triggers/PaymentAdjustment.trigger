/**
 * Created by Chris Home Desktop on 11/13/2017.
 */

trigger PaymentAdjustment on Payment_Adjustment__c (before insert,after update,before delete,after delete) {

    TriggerHandler.TriggerHandlerEntry(new TriggerState(trigger.isBefore, trigger.isAfter, trigger.isUpdate,
            trigger.isDelete, trigger.isInsert, trigger.isExecuting, trigger.new, trigger.newMap, trigger.old, trigger.oldMap));
}