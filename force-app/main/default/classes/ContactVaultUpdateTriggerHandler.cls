/**
 * Created by zackminott on 7/16/24.
 */

public with sharing class ContactVaultUpdateTriggerHandler implements Queueable, Database.AllowsCallouts {
    Map<Id, List<Payment_Vault__c>> paymentVaultsByContactId {get; set;}

    public static void InitiateVaultUpdate(Set<Id> contactIds){
        System.debug('IN INITIATE VAULT UPDATE: ' + contactIds);
        List<Contact> contacts = [
                SELECT Id, AccountId
                FROM Contact
                WHERE AccountId IN (SELECT Organization_Household__c FROM Payment_Vault__c)
                AND Id IN :contactIds
        ];
        if(contacts.isEmpty()) return;

        Map<Id, Contact> contactSet = new Map<Id, Contact>(contacts);
        List<Payment_Vault__c> paymentVaults = [
                SELECT Id, CreatedBy.ContactId, Organization_Household__c, NMI_Customer_Vault_Number__c, Type__c
                FROM Payment_Vault__c
                WHERE CreatedBy.ContactId IN :contactSet.keySet()
                AND CreatedBy.ContactId != NULL
        ];
        if(paymentVaults.isEmpty()) return;
        System.debug('FOUND VAULTS');
        Map<Id, List<Payment_Vault__c>> paymentVaultsByContactId = new Map<Id, List<Payment_Vault__c>>();
        for(Payment_Vault__c curVault : paymentVaults){
            String currentVaultContactId = curVault.CreatedBy.ContactId;
            if(paymentVaultsByContactId.containsKey(currentVaultContactId)){
                paymentVaultsByContactId.get(currentVaultContactId).add(curVault);
            } else {
                paymentVaultsByContactId.put(currentVaultContactId, new List<Payment_Vault__c>{curVault});
            }
        }

        System.enqueueJob(new ContactVaultUpdateTriggerHandler(paymentVaultsByContactId));
    }

    ContactVaultUpdateTriggerHandler(Map<Id, List<Payment_Vault__c>> paymentVaultsByContactId){
        this.paymentVaultsByContactId = paymentVaultsByContactId;
    }


    public void execute(QueueableContext context) {
        System.debug('EXECUTING EMAIL UPDATE');
        Map<Id, String> emailsByContactId = RetrievePaymentVaultContactsEmailsByContactId(this.paymentVaultsByContactId.keySet());
        CycleThroughPaymentVaultsAndUpdate(emailsByContactId);
    }

    private Map<Id, String> RetrievePaymentVaultContactsEmailsByContactId(Set<Id> contactIds){
        List<Contact> contacts = [
                SELECT Id, Email
                FROM Contact
                WHERE Id IN :contactIds
        ];
        Map<Id, String> emailsByContactId = new Map<Id, String>();
        for(Contact curContact : contacts){
            emailsByContactId.put(curContact.Id, curContact.Email);
        }
        return emailsByContactId;
    }

    private void CycleThroughPaymentVaultsAndUpdate(Map<Id, String> emailsByContactId){
        for(Id contactId : this.paymentVaultsByContactId.keySet()){
            List<Payment_Vault__c> contactVaults = this.paymentVaultsByContactId.get(contactId);
            String newEmail = emailsByContactId.get(contactId);
            if(String.isBlank(newEmail)) continue;

            for(Payment_Vault__c curVault : contactVaults){
                UpdateEmailOfPaymentVault(newEmail, curVault.NMI_Customer_Vault_Number__c);
            }
        }
    }

    private void UpdateEmailOfPaymentVault(String email, String paymentVaultId){
        try {
            NMI_RequestController.GetNMIRequestController.SendEmailUpdateVaultRequest(email, paymentVaultId);
        } catch(CalloutException ce){
            UtilitiesErrors.PrintErrorDetails(ce);
        } catch(NullPointerException ne){
            UtilitiesErrors.PrintErrorDetails(ne);
        } catch(Exception e){
            UtilitiesErrors.PrintErrorDetails(e);
        }
    }
}