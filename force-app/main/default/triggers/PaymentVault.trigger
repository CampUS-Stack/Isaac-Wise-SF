/**
 * Created by zacha on 10/5/2021.
 */

trigger PaymentVault on Payment_Vault__c (before delete) {
    TriggerHandler.TriggerHandlerEntry(new TriggerState(trigger.isBefore, trigger.isAfter, trigger.isUpdate,
        trigger.isDelete, trigger.isInsert, trigger.isExecuting, trigger.new, trigger.newMap, trigger.old, trigger.oldMap));
}