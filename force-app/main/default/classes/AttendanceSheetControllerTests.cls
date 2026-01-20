/**
 * Created by Chris Home Desktop on 2/13/2018.
 */
@IsTest
public with sharing class AttendanceSheetControllerTests {

    @TestSetup public static void SetupTests(){

        Class__c theCls = new Class__c();
        theCls.Name = 'test';
        insert theCls;

        list<Contact> contacts = TestObjectFactory.CreateContacts('Test',1);
        insert contacts;

        Student_Class_Enrollment__c sce = new Student_Class_Enrollment__c();
        sce.Class__c = theCls.Id;
        sce.Student__c = contacts[0].Id;


    }

    @IsTest public static void ProcessTestCoverage(){

        list<Contact> cons = [SELECT Id FROM Contact];
        list<Class__c> classes = [SELECT Id FROM Class__c];

        ApexPages.StandardController stdC = new ApexPages.StandardController(classes[0]);
        AttendanceSheetController theASC = new AttendanceSheetController(stdC);

        list<Date> test = theASC.listOfDate;
        list<String> testStrings = theASC.listOfWeeks;

        Double testD = theASC.offset;

        theASC.populateWeekList();
        theASC.findNextSunday(date.today());

    }
}