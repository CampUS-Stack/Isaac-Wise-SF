/**
 * Created by Chris Home Desktop on 4/27/2018.
 */
@IsTEst
public with sharing class AssessmentHandlerTests {

    @IsTest public static void ProcessTestCoverage(){

        Account acc = new Account();
        acc.Name = 'test';
        insert acc;

        Assessment__c assess = new Assessment__c();
        assess.Account__c = acc.Id;
        assess.Status__c = 'Transferred';
        assess.Assessment_Date__c = date.today();
        assess.Assessed_Amount__c = 123.0;
        insert assess;

        try{
            delete assess;
        }
        catch(DmlException de){
            system.debug(de.getMessage());
        }
    }
}