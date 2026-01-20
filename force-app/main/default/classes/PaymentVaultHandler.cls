/**
 * Created by zacha on 10/5/2021.
 */

public with sharing class PaymentVaultHandler implements TriggerHandler.ITrigger{
    
    public void MainEntry(TriggerState state) {
        if(state.IsBefore){
            if(state.IsDelete){
                handleBeforeDelete(state);
            }
        }
    }
    
    public void InProgressEntry(TriggerState state) {
    
    }
    
    private void handleBeforeDelete(TriggerState state){
        for(Payment_Vault__c curVault : (List<Payment_Vault__c>) state.OldList){
            if(curVault.NMI_Customer_Vault_Number__c != null && String.isNotBlank(curVault.NMI_Customer_Vault_Number__c)){
                deleteVaultInNMI(curVault.NMI_Customer_Vault_Number__c);
            }
        }
    }
    
    @Future(Callout = TRUE)
    private static void deleteVaultInNMI(String vaultNumber){
        NMI_RequestController.GetNMIRequestController.SendDeleteVaultRequest(vaultNumber);
    }
    
}