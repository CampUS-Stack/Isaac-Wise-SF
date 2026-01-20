/**
* Created by Chris Home Desktop on 5/29/2017.
*/

public with sharing class ContactHandler implements TriggerHandler.ITrigger{
    
    private Boolean hasExecuted {get; set;}
    
    public ContactHandler() {}
    
    public void MainEntry(TriggerState state){
        
        system.debug('Contact Handler Main Entry Called.');
        system.debug('Firing object: ' + state.TriggerObject );
        if(State.IsBefore){
            if(state.IsUpdate){
                processBeforeUpdate(state);
            }
            if(state.IsInsert){
                processBeforeInsert(state);
            }
            if(state.IsDelete){
                processAfterDelete(state);
            }
        }
        
        if(State.isAfter){
            if(state.IsUpdate){
                processAfterUpdate(state);
            }
            if(state.IsInsert){
                processAfterInsert(state);
            }
            if(state.IsDelete){
                processAfterDelete(state);
            }
        }
        
    }
    
    public void InProgressEntry(TriggerState state){
        
        if(state.TriggerObject == 'Yahrzeit__c'){
            YahrzeitHandler handler = new YahrzeitHandler();
            handler.InProgressEntry(state);
        }
        
        if(state.TriggerObject != 'Contact'){
            return;
        }
        
        system.debug('Contact Handler In progress Called.');
        system.debug('Firing object: ' + state.TriggerObject );
        if(State.isAfter){
            if(state.IsUpdate){
                processAfterUpdate(state);
            }
            if(state.IsInsert){
                processAfterInsert(state);
            }
        }
        
    }
    
    @TestVisible private void processBeforeUpdate(TriggerState state){
        
        handleContactFieldUpdates((list<Contact>)state.NewList,(map<Id,Contact>)state.OldMap);
        handleYahrzeitActions((list<Contact>)state.NewList,(map<Id,Contact>)state.OldMap);
        
    }
    
    @TestVisible private void processBeforeInsert(TriggerState state){
        
        handleContactFieldUpdates((list<Contact>)state.NewList,(map<Id,Contact>)state.OldMap);
        handleYahrzeitActions((list<Contact>)state.NewList,(map<Id,Contact>)state.OldMap);
        
    }
    
    @TestVisible private void processAfterUpdate(TriggerState state){

        handleEmailChanged((list<Contact>)state.NewList,(map<Id,Contact>)state.OldMap);
        handleAccountFieldUpdate((list<Contact>)state.NewList,(map<Id,Contact>)state.OldMap);
        YahrzeitObservanceHandler.ObservanceMemberUpdate(new List<Id>(state.newMap.keySet()));
    }
    
    @TestVisible private void processAfterDelete(TriggerState state){
        
        handleAccountFieldUpdate((list<Contact>)state.NewList,(map<Id,Contact>)state.OldMap);
        
    }
    

    @TestVisible private void processAfterInsert(TriggerState state){
        
        handleAccountFieldUpdate((list<Contact>)state.NewList,(map<Id,Contact>)state.OldMap);
        YahrzeitObservanceHandler.ObservanceMemberUpdate(new List<Id>(state.newMap.keySet()));
    }

    private void handleEmailChanged(List<Contact> newContacts, Map<Id, Contact> oldContacts){
        Set<Id> contactsWithChangedEmail = new Set<Id>();
        for(Contact curContact : newContacts){
            Contact oldContact = oldContacts.get(curContact.Id);
            if(oldContact.Email != curContact.Email){
                contactsWithChangedEmail.add(curContact.Id);
            }
        }

        if(!contactsWithChangedEmail.isEmpty()){
            ContactVaultUpdateTriggerHandler.InitiateVaultUpdate(contactsWithChangedEmail);
        }
    }
    
    
    @TestVisible private void handleYahrzeitActions(list<Contact> newContacts,map<Id,Contact> oldContacts){
        
        list<Contact> contactsToCreateYahrzeitsFor = new list<Contact>();
        for(Contact curContact : newContacts){
            
            if(oldContacts == null && curContact.Date_of_Death__c != null){
                contactsToCreateYahrzeitsFor.add(curContact);
            }
            else if( oldContacts != null && curContact.Date_of_Death__c != oldContacts.get(curContact.Id).Date_of_Death__c && curContact.Date_of_Death__c != null){
                contactsToCreateYahrzeitsFor.add(curContact);
            }
        }
        
        list<Yahrzeit__c> yahrzeits = YahrzeitCreationController.RunBeforeYahrzeitCreationProcesses(contactsToCreateYahrzeitsFor);
        YahrzeitCreationController.RunAfterYahrzeitCreationProcesses(contactsToCreateYahrzeitsFor);
    }
    
    @TestVisible private void handleContactFieldUpdates(list<Contact> newContacts,map<Id,Contact> oldContacts){
        
        handleBarmitsvahFieldUpdates(newContacts,oldContacts);
    }
    
    @TestVisible private void handleBarmitsvahFieldUpdates(list<Contact> newContacts,map<Id,Contact> oldContacts){
        
        list<Contact> contactsForBarmitsvahUpdate = new list<Contact>();
        for(Contact curContact : newContacts){
            
            if(oldContacts == null && curContact.Bar_Bat_Mitzvah_Date__c != null){
                contactsForBarmitsvahUpdate.add(curContact);
            }
            else if(oldContacts != null && curContact.Bar_Bat_Mitzvah_Date__c != oldContacts.get(curContact.Id).Bar_Bat_Mitzvah_Date__c && curContact.Bar_Bat_Mitzvah_Date__c != null){
                contactsForBarmitsvahUpdate.add(curContact);
            }
        }
        
        system.debug('Number of contacts for torah barmitsvah field update: ' + contactsForBarmitsvahUpdate.size());
        ContactFieldUpdateUtility.UpdateTorahFieldForBarmitsvah(contactsForBarmitsvahUpdate);
    }
    
    
    @TestVisible private void handleAccountFieldUpdate(list<Contact> newContacts,map<Id,Contact> oldContacts) {
        list<Id> accountForAgeFieldUpdate = new list<Id>();
        
        //Insert update
        if( newContacts != null) {
            for(Contact curContact : newContacts){
                
                if(oldContacts == null && curContact.AccountId != null) {
                    accountForAgeFieldUpdate.add(curContact.AccountId);
                }
                
                else if(oldContacts != null && curContact.AccountId != oldContacts.get(curContact.Id).AccountId) {
                    //Update Old Account
                    if(curContact.AccountId != null) {
                        accountForAgeFieldUpdate.add(curContact.AccountId);
                    }
                    
                    //Update New Account
                    if(oldContacts.get(curContact.Id).AccountId != null) {
                        accountForAgeFieldUpdate.add(oldContacts.get(curContact.Id).AccountId);
                    }
                    
                }
                
                else if(oldContacts != null && 
                        curContact.Date_of_Birth__c != oldContacts.get(curContact.Id).Date_of_Birth__c ) {
                            accountForAgeFieldUpdate.add(curContact.AccountId);
                        }
                
            }
        } 
        //delete 
        else if (newContacts == null && oldContacts != null) {
            for(Contact curContact : oldContacts.values() ){                
                accountForAgeFieldUpdate.add(curContact.AccountId);
            }
        }
        
        
        AccountFieldUpdateUtility.UpdateAgeFieldOnAccounts(accountForAgeFieldUpdate);
        
    }
    
    
}