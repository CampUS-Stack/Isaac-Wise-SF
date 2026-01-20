/**
 * Created by cgibs on 8/15/2017.
 */
@IsTest
public with sharing class ClassRoster_EditControllerTests {


    @IsTest private static void ProcessTestCoverage(){

        list<Contact> students = TestObjectFactory.CreateContacts('test',1);
        insert students;

        Class__c parentClass = new Class__c();
        parentClass.Name = 'Parent Class Test';
        insert parentClass;

        Class__c theClass = new Class__c();
        theClass.Name = 'Test';
        theClass.Parent_Class__c = parentClass.Id;
        insert theClass;

        ApexPages.StandardController stdController = new ApexPages.StandardController(theClass);
        ClassRoster_EditController editCtrl = new ClassRoster_EditController(stdController);

        editCtrl.AddSelectedStudent();
        editCtrl.StudentIdToAdd = students[0].Id;
        editCtrl.AddStudent();
        editCtrl.StudentIdToRemove = students[0].Id;
        editCtrl.RemoveStudent();
        editCtrl.changeSortColumn();
        editCtrl.getEnrolledStudents();
        editCtrl.ShowAddStudentSection();
        editCtrl.ClearAddSutdentForm();
        editCtrl.SelectAllStudents();
        editCtrl.createSiblingClassSOQL();
        editCtrl.createStudentEnrollment(students[0].Id,theClass.Id);

        list<Contact> grade1Student = editCtrl.getStudents('1');
    }
}