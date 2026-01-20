/**
 * Created by zacha on 5/28/2021.
 */

public without sharing class YahrzeitObservanceHandler {

    @Future
    public static void ObservanceMemberUpdate(List<Id> contactIds){
        List<Yahrzeit_Observance__c> observances = [
                SELECT Id, Is_Member_1__c, Is_Member__c
                FROM Yahrzeit_Observance__c
                WHERE Contact__c IN :contactIds
        ];

        for(Yahrzeit_Observance__c curObservance : observances){
            if(curObservance.Is_Member__c){
                curObservance.Is_Member_1__c = '1';
            } else {
                curObservance.Is_Member_1__c = 'false';
            }
        }
        update observances;
    }

    public static void ObservanceMemberUpdateForBatch(List<Id> contactIds){
        List<Yahrzeit_Observance__c> observances = [
                SELECT Id, Is_Member_1__c, Is_Member__c
                FROM Yahrzeit_Observance__c
                WHERE Contact__c IN :contactIds
        ];

        for(Yahrzeit_Observance__c curObservance : observances){
            if(curObservance.Is_Member__c){
                curObservance.Is_Member_1__c = '1';
            } else {
                curObservance.Is_Member_1__c = 'false';
            }
        }
        update observances;
    }




}