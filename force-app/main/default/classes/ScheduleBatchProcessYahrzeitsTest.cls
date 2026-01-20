/**
 * Created by Kritik Garg on 31-07-2019.
 */

@isTest
public with sharing class ScheduleBatchProcessYahrzeitsTest {

    @TestSetup
    public static void setUpTestData() {

        Contact c = new Contact();
        c.FirstName = 'test';
        c.LastName = 'test';
        insert c;

        List<Yahrzeit__c> listOfYahrzeits = new List<Yahrzeit__c>();

        for (Integer x = 0; x < 10; x++) {


            Yahrzeit__c yahr = new Yahrzeit__c();
            yahr.Observe_on_Hebrew_Date__c = true;
            yahr.Next_Gregorian_Hebrew_Date_of_Death__c = date.today().addDays(-2-x);
            yahr.Eng_Death_Date__c = date.today().addDays(-2-x);
            yahr.Deceased__c = c.Id;
            listOfYahrzeits.add(yahr);


        }

        insert listOfYahrzeits;
    }


    public static testMethod void testMethod1() {

        Test.setMock(HttpCalloutMock.class, new HebrewDateCalculationControllerTest());
        Test.startTest();
        ScheduleBatchProcessYahrzeits.scheduleMe();
        Test.stopTest();
    }

}