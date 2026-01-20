/**
 * Created by Chris Home Desktop on 5/30/2017.
 */

public with sharing class RelationshipHandler implements TriggerHandler.ITrigger{

    private Boolean hasExecuted {get; set;}

    public RelationshipHandler() {}

    public void MainEntry(TriggerState state){

        system.debug('Relationship Handler Main Entry Called.');
        system.debug('Firing object: ' + state.TriggerObject);
        if(State.IsBefore){
            if(state.IsInsert){
                processBeforeInsert(state);
            }
        }
    }

    public void InProgressEntry(TriggerState state){

        if(state.TriggerObject != 'Relationship_Affiliation__c'){
            return;
        }

    }

    @TestVisible private void processBeforeInsert(TriggerState state){
        if(state.NewList.size() == 1){
            ReciprocalRelationshipController.CreateReciprocalRelationship((Relationship_Affiliation__c)state.NewList[0]);
        }
    }

}