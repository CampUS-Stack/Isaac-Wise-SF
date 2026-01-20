/**
 * Created by Chris Home Desktop on 5/21/2017.
 */

public with sharing class YahrzeitHandler implements TriggerHandler.ITrigger{

    private Boolean hasExecuted {get; set;}

    public YahrzeitHandler() {}

    public void MainEntry(TriggerState state){

        system.debug('Yahrzeit Handler Main Entry Called.');
        system.debug('Firing object: ' + state.TriggerObject);
        if(state.IsAfter){
            if(state.IsInsert){
                processAfterInsert(state);
            }
            else if(state.IsUpdate){
                processAfterUpdate(state);
            }
        }
        else if(State.IsBefore){
            if(state.IsInsert){
                processBeforeInsert(state);
            }
            else if(state.IsUpdate){
                processBeforeUpdate(state);
            }
        }
    }

    public void InProgressEntry(TriggerState state){

        if(state.TriggerObject != 'Yahrzeit__c'){
            return;
        }

        system.debug('Yahrzeit Handler In progress Called.');
        system.debug('Firing object: ' + state.TriggerObject);
        if(state.IsAfter){
            if(state.IsInsert){
                processAfterInsert(state);
            }
            else if(state.IsUpdate){
                processAfterUpdate(state);
            }
        }
        else if(State.IsBefore){
            if(state.IsInsert){
                processBeforeInsert(state);
            }
            else if(state.IsUpdate){
                processBeforeUpdate(state);
            }
        }
    }

    @TestVisible private void processAfterInsert(TriggerState state){
//        ObservanceCreationController.createYahrzeitObservances(state.NewList);

        if(state.NewList.size() == 1 && !System.isFuture()){
            ConvertDatesToHebrew(String.valueOf(state.NewList[0].get('id')));
        }
    }

    @TestVisible private void processAfterUpdate(TriggerState state){

//        if(state.NewList.size() == 1 && !System.isFuture()){
//            ConvertDatesToHebrew(String.valueOf(state.NewList[0].get('id')));
//        }
    }

    @TestVisible private void processBeforeInsert(TriggerState state){


    }

    @TestVisible private void processBeforeUpdate(TriggerState state){

        if(state.NewList.size() == 1 && !System.isFuture() && !system.isBatch()){
            ConvertDatesToHebrew(String.valueOf(state.NewList[0].get('id')));
        }

    }


    @Future(callout=true) public static void ConvertDatesToHebrew(String yahrzeitId){

        HebrewDateCalculationController dateConversionCtrl = new HebrewDateCalculationController();
        try{
            Yahrzeit__c yahr = [SELECT Id, Eng_Death_Date__c,Next_Observance_Date__c,Hebrew_Date_of_Death__c, Hebrew_Year__c, Hebrew_Day__c, Hebrew_Month__c, Hebrew_Date_Events__c, Hebrew_Date_of_Death_In_Hebrew__c FROM Yahrzeit__c WHERE Id = :yahrzeitId];

            HebrewDateCalculationResponse gToHResponse = dateConversionCtrl.RunEngToHebrewDateConversion(yahr.Eng_Death_Date__c);

            if(gToHResponse == null){
                return;
            }

            Integer numOfYearsFromDeathDateToNow = date.today().year() - yahr.Eng_Death_Date__c.year();

            yahr.Hebrew_Year__c = String.valueOf(gToHResponse.hy + numOfYearsFromDeathDateToNow);
            yahr.Hebrew_Month__c = gToHResponse.hm;
            yahr.Hebrew_Day__c = String.valueOf(gToHResponse.hd);
            yahr.Hebrew_Date_Events__c = String.valueOf(gToHResponse.events);
            yahr.Hebrew_Date_of_Death_In_Hebrew__c = gToHResponse.hebrew;

            yahr.Hebrew_Date_of_Death__c = yahr.Hebrew_Day__c + ' - ' + yahr.Hebrew_Month__c + ' - ' + yahr.Hebrew_Date_of_Death_In_Hebrew__c;

            system.debug('Hebrew Day Being Passed: ' + gToHResponse.hd);
            HebrewDateCalculationResponse hToGResponse = dateConversionCtrl.RunHebrewToEngDateConversion(yahr.Hebrew_Year__c,yahr.Hebrew_Month__c,yahr.Hebrew_Day__c);
            system.debug('Printing H to G Response ' + hToGResponse);
            Date nextObservanceDate = Date.newInstance(hToGResponse.gy,hToGResponse.gm,hToGResponse.gd);

            if(nextObservanceDate > Date.today()){
                yahr.Next_Gregorian_Hebrew_Date_of_Death__c = nextObservanceDate;
            }
            else{
                system.debug('Hebrew Day Being Passed: ' + yahr.Hebrew_Day__c);
                HebrewDateCalculationResponse hToGResponse2 = dateConversionCtrl.RunHebrewToEngDateConversion(String.valueOf(Integer.valueOf(yahr.Hebrew_Year__c) + 1),yahr.Hebrew_Month__c,yahr.Hebrew_Day__c);
                system.debug('Printing H to G Response ' + hToGResponse2);
                nextObservanceDate = Date.newInstance(hToGResponse2.gy,hToGResponse2.gm,hToGResponse2.gd);
                yahr.Next_Gregorian_Hebrew_Date_of_Death__c = nextObservanceDate;
            }

            update yahr;

        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
        }
        catch(DmlException de){
            system.debug(de.getMessage());
        }
    }
}