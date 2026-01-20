/**
 * Created by Chris Home Desktop on 8/14/2017.
 */
@IsTest
public with sharing class YahrzeitCreationControllerTests {

    @IsTest public static void ProcessTestCoverage(){

        Contact c = new Contact();
        c.FirstName = 'test';
        c.LastName = 'test';
        insert c;

        Yahrzeit__c yahr = new Yahrzeit__c();
//        yahr.Gregorian_Date_of_Death__c = date.today();
        yahr.Deceased__c = c.Id;
        insert yahr;

        Torah_Portion__c tp = new Torah_Portion__c();
        tp.Name = 'test';
        insert tp;
    }
}