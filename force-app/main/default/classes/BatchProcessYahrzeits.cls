/**
 * Created by Kritik Garg on 30-07-2019.
 */

global class BatchProcessYahrzeits implements
                Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts {

    global Database.QueryLocator start(Database.BatchableContext bc) {

        Date todayDate = Date.today();

        String query = 'select Id, Eng_Death_Date__c,Hebrew_Date_of_Death__c, Hebrew_Year__c, Hebrew_Day__c, Hebrew_Month__c, Hebrew_Date_Events__c, Hebrew_Date_of_Death_In_Hebrew__c , Next_Observance_Date__c from Yahrzeit__c WHERE  Next_Observance_Date__c < :todayDate';
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext bc, List<Yahrzeit__c> listOfYahrzeit) {

        Integer i = 0;

        //update listOfYahrzeit;

        for(Yahrzeit__c yh : listOfYahrzeit) {
            i++;
            System.debug(i +' : ' + yh.id + ' : ' + yh.Next_Observance_Date__c);
            ConvertDatesToHebrew(yh);
        }

        update listOfYahrzeit;

    }


    public static void ConvertDatesToHebrew(Yahrzeit__c yahr){

        HebrewDateCalculationController dateConversionCtrl = new HebrewDateCalculationController();
        try{
            // Yahrzeit__c yahr = [SELECT Id, Eng_Death_Date__c,Next_Observance_Date__c,Hebrew_Date_of_Death__c, Hebrew_Year__c, Hebrew_Day__c, Hebrew_Month__c, Hebrew_Date_Events__c, Hebrew_Date_of_Death_In_Hebrew__c FROM Yahrzeit__c WHERE Id = :yahrzeitId];

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

        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
        }
        catch(DmlException de){
            system.debug(de.getMessage());
        }
    }

    global void finish(Database.BatchableContext bc) {

    }
}