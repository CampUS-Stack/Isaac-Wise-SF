/**
 * Created by Chris Home Desktop on 2/13/2018.
 */
@IsTest
public with sharing class UtilitiesReligiousSchoolTests {

    @TestSetup public static void setupData(){

        list<Contact> students = TestObjectFactory.CreateContacts('test',2);
        insert students;

        Class__c theClass = new Class__c();
        theClass.Name = 'Test';
        insert theClass;

        Student_Class_Enrollment__c sce = new Student_Class_Enrollment__c();
        sce.Student__c = students[0].Id;
        sce.Class__c = theClass.Id;
        sce.Enrolled_Date__c = Date.today();
        insert sce;
    }

    @IsTest public static void TestWith1StudentRemoved(){

        Contact c = [SELECT Id FROM Contact WHERE Id IN (SELEcT Student__c FROM Student_Class_Enrollment__c)];
        UtilitiesReligiousSchool.RemoveFromAllClasses(c.Id);
        UtilitiesReligiousSchool.RemoveFromAllHebrewClasses(c.Id);

        list<Student_Class_Enrollment__c> sce = [SELECT Id FROM Student_Class_Enrollment__c where Student__c = :c.Id];
        system.assert(sce.size() == 0);
    }

    @IsTest public static void TestWith0StudentsRemoved(){

        Contact c = [SELECT Id FROM Contact WHERE Id NOT IN (SELEcT Student__c FROM Student_Class_Enrollment__c)];
        UtilitiesReligiousSchool.RemoveFromAllClasses(c.Id);
        UtilitiesReligiousSchool.RemoveFromAllHebrewClasses(c.Id);

        list<Student_Class_Enrollment__c> sce = [SELECT Id FROM Student_Class_Enrollment__c where Student__c = :c.Id];
        system.assert(sce.size() == 0);
    }

    @IsTest public static void ProcessTestCoverage(){

        UtilitiesReligiousSchool.ClassFilter clsFilter = new UtilitiesReligiousSchool.ClassFilter();
        clsFilter.Age = 1;
        clsFilter.Name = 'test';
        clsFilter.ClassId = '';
        clsFilter.ClassName = 'test';
        clsFilter.GradeLevel = 'test';
        clsFilter.Birthdate = 'test';
        clsFilter.StudentContactId = 'test';
        clsFilter.OrderDirection = 'test';
        clsFilter.OrderField = 'test';

        UtilitiesReligiousSchool.GetStudentsSOQLString(clsFilter);

        list<Contact> students = UtilitiesReligiousSchool.GetStudents(clsFilter);

        Student_Class_Enrollment__c sce = UtilitiesReligiousSchool.GetStudentClassEnrollement('test','test');
        sce = UtilitiesReligiousSchool.GetStudentClassEnrollementByStudent('test');
    }
}