/**
 * Created by zacha on 5/28/2021.
 */

public without sharing class AccountHandler implements TriggerHandler.ITrigger{
    public void MainEntry(TriggerState state) {
        if(state.IsAfter){
            if(state.IsInsert){
                processAfterInsert(state);
            }
            if(state.IsAfter){
                processAfterUpdate(state);
            }
        }
    }


    public void InProgressEntry(TriggerState state) {
    }

    private void processAfterInsert(TriggerState state){
        observanceHandlerEntry((Map<Id, Account>) state.NewMap);
    }
 
    private void processAfterUpdate(TriggerState state){
        observanceHandlerEntry((Map<Id, Account>) state.NewMap);
    }

    private void observanceHandlerEntry(Map<Id, Account> accountMap){
        Map<Id, Contact> contactMap = new Map<Id, Contact>([
                SELECT Id
                FROM Contact
                WHERE AccountId IN :accountMap.keySet()
        ]);

        if(System.isBatch() || System.isFuture() ) {
            YahrzeitObservanceHandler.ObservanceMemberUpdateForBatch(new List<Id>(contactMap.keySet()));
        } else {
            YahrzeitObservanceHandler.ObservanceMemberUpdate(new List<Id>(contactMap.keySet()));
        }

    }
}