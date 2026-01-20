/**
 * Created by Chris Home Desktop on 5/29/2017.
 */

public with sharing class TorahHandler implements TriggerHandler.ITrigger{

    private Boolean hasExecuted {get; set;}

    public TorahHandler() {}

    public void MainEntry(TriggerState state){

        system.debug('Torah Handler Main Entry Called.');
        system.debug('Firing object: ' + state.TriggerObject);

        if(state.IsInsert){
            if(state.IsBefore){
                processBeforeInsert(state);
            }
        }
        if(state.IsUpdate){
            if(state.IsBefore){
                processBeforeUpdate(state);
            }
        }

    }

    public void InProgressEntry(TriggerState state){

        if(state.TriggerObject != 'Torah_Portion__c'){
            return;
        }
    }

    @TestVisible private void processBeforeInsert(TriggerState state){

        processTorahPortionNames((list<Torah_Portion__c>)state.NewList);
    }
    @TestVisible private void processBeforeUpdate(TriggerState state){

        processTorahPortionNames((list<Torah_Portion__c>)state.NewList);
    }

    @TestVisible private void processTorahPortionNames(list<Torah_Portion__c> torahPortions){

        for(Torah_Portion__c curTorah : torahPortions){

            curTorah.Name = Datetime.newInstance(curTorah.Date__c,Time.newInstance(0,0,0,0)).format('M/d/YYYY');
        }
    }


}