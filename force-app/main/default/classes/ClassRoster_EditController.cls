/**
 * Created by Chris Home Desktop on 6/14/2017.
 */

public with sharing class ClassRoster_EditController {

    public Boolean displayAddStudent {get; set;}
    public Boolean displayRosterCopy {get; set;}
    public Boolean AddSiblingClassCriteria {get; set;}

    public list<UtilitiesWrappers.StudentWrapper> students {get; set;}
    public list<UtilitiesWrappers.StudentWrapper> enrolledStudents {get; set;}
    public String StudentName {get; set; }
    public Class__c theClass {get; set;}

    public String StudentIdToAdd {get; set;}
    public String StudentIdToRemove {get; set;}

    public Class__c dummyClass {get; set;}
    public Integer Age {get; set;}

    /// Sorting Variables
    public String selectedField {get; set;}
    public String selectedSortOrder {get; set;}

    public ClassRoster_EditController(ApexPages.StandardController stdController){

        this.theClass = getClass(stdController.getId());
//        this.enrolledStudents = UtilitiesWrappers.createStudentWrappers(getEnrolledStudents());
//        this.students = UtilitiesWrappers.createStudentWrappers(UtilitiesReligiousSchool.GetStudents(getIdsOfEnrolledStudents(),this.dummyClass.Name,this.dummyClass.Start_Date__c,this.dummyClass.Grade_Level__c,this.dummyClass.Parent_Class__c));
        this.displayAddStudent = false;
        this.dummyClass = new Class__c();
        this.selectedSortOrder = 'ASC';
        this.selectedField = 'LastName';
        this.Age = 0;
        this.AddSiblingClassCriteria = false;

        SearchForStudents();
    }

    public void ShowAddStudentSection(){

        if(displayAddStudent == false){
            displayAddStudent = true;
        }
    }

    public PageReference AddSelectedStudent(){

        list<Student_Class_Enrollment__c> enrollmentsToInsert = new list<Student_Class_Enrollment__c>();
        for(UtilitiesWrappers.StudentWrapper curWrap : this.students){

            if(curWrap.isSelected == true){
                Student_Class_Enrollment__c sce = new Student_Class_Enrollment__c();
                sce.Student__c = curWrap.student.Id;
                sce.Class__c = this.theClass.Id;
                sce.Enrolled_Date__c = Date.today();
                enrollmentsToInsert.add(sce);
            }
        }

        insert enrollmentsToInsert;

        this.enrolledStudents = UtilitiesWrappers.createStudentWrappers(getEnrolledStudents());
        system.debug(enrolledStudents);
        UtilitiesReligiousSchool.ClassFilter theClassFilter = new UtilitiesReligiousSchool.ClassFilter();
        theClassFilter.Name = this.dummyClass.Name;
        theClassFilter.Age = this.Age;
        theClassFilter.GradeLevel = this.dummyClass.Grade_Level__c;
        theClassFilter.ClassId = this.dummyClass.Parent_Class__c;
        theClassFilter.EnrolledStudentIds = getIdsOfEnrolledStudents();
        this.students = UtilitiesWrappers.createStudentWrappers(UtilitiesReligiousSchool.GetStudents(theClassFilter));

        return null;
    }

    public PageReference AddStudent(){

        if(String.isEmpty(this.StudentIdToAdd)){
            return null;
        }

        createStudentEnrollment(this.StudentIdToAdd,this.theClass.Id);

        if(!String.isEmpty(this.theClass.Parent_Class__c)){

            createStudentEnrollment(this.StudentIdToAdd,this.theClass.Parent_Class__c);

            if(!String.isEmpty(this.theClass.Parent_Class__r.Parent_Class__c)){

                createStudentEnrollment(this.StudentIdToAdd,this.theClass.Parent_Class__c);
            }
        }

        this.enrolledStudents = UtilitiesWrappers.createStudentWrappers(getEnrolledStudents());
        system.debug(enrolledStudents);
//        this.students = UtilitiesWrappers.createStudentWrappers(getStudents(theClass.Grade_Level__c));
        UtilitiesReligiousSchool.ClassFilter theClassFilter = new UtilitiesReligiousSchool.ClassFilter();
        theClassFilter.Name = this.dummyClass.Name;
        theClassFilter.Age = this.Age;
        theClassFilter.GradeLevel = this.dummyClass.Grade_Level__c;
        theClassFilter.ClassId = this.dummyClass.Parent_Class__c;
        theClassFilter.EnrolledStudentIds = getIdsOfEnrolledStudents();
        this.students = UtilitiesWrappers.createStudentWrappers(UtilitiesReligiousSchool.GetStudents(theClassFilter));

        return null;

    }

    public PageReference RemoveStudent(){

        system.debug(this.StudentIdToRemove);

        if(String.isEmpty(this.StudentIdToRemove)){
            return null;
        }

        try{
            Student_Class_Enrollment__c enrollment = UtilitiesReligiousSchool.GetStudentClassEnrollement(this.StudentIdToRemove,this.theClass.Id);
            delete enrollment;
        }
        catch(DmlException de){
            system.debug(de.getMessage());
        }

        this.enrolledStudents = UtilitiesWrappers.createStudentWrappers(getEnrolledStudents());
        system.debug(enrolledStudents);
        this.students = UtilitiesWrappers.createStudentWrappers(getStudents(theClass.Grade_Level__c));

        return null;
    }

    /**
     *  @Author: Chris Gibson
     *  @Date: 07.14.2017
     *
     *  @Description: This method searches for students, populating both enrolled and students to a add area.
     */

    public PageReference SearchForStudents(){

        this.enrolledStudents = UtilitiesWrappers.createStudentWrappers(getEnrolledStudents());
        system.debug(enrolledStudents);
        UtilitiesReligiousSchool.ClassFilter theClassFilter = new UtilitiesReligiousSchool.ClassFilter();
        theClassFilter.Name = this.dummyClass.Name;
        theClassFilter.Age = this.Age;
        theClassFilter.GradeLevel = this.dummyClass.Grade_Level__c;
        theClassFilter.ClassId = this.dummyClass.Parent_Class__c;
        theClassFilter.EnrolledStudentIds = getIdsOfEnrolledStudents();
        String theQuery = UtilitiesReligiousSchool.GetStudentsSOQLString(theClassFilter);
        if(AddSiblingClassCriteria)
            theQuery += ' AND Id IN ' + UtilitiesReligiousSchool.getSetStringForSOQL(getIdsOfStudentsInSiblingClasses());
        theQuery += ' ORDER BY ' + this.selectedField + ' ' + this.selectedSortOrder;
        theQuery += ' limit 500';
        system.debug(theQuery);
        list<Contact> students = UtilitiesReligiousSchool.GetStudents(getIdsOfEnrolledStudents(),theQuery);
//        list<Contact> students = UtilitiesReligiousSchool.getStudents(getIdsOfEnrolledStudents(),this.dummyClass.Name,this.dummyClass.Start_Date__c,this.dummyClass.Grade_Level__c,this.dummyClass.Parent_Class__c);
        this.students = UtilitiesWrappers.createStudentWrappers(students);

        return null;
    }


    /**
     *  @Author: Chris Gibson
     *  @Date: 07.02.2017
     *
     *  @Purpose: This method changes the sort order based on what the page currently has and also provides an opportunity for the
     *              selected field variable to be set.
     *
     *  @PostCondition:
     */
    public void changeSortColumn(){

        if(this.selectedSortOrder == null){
            this.selectedSortOrder = 'ASC';
        }
        else if(this.selectedSortOrder == 'ASC'){
            this.selectedSortOrder = 'DESC';
        }
        else{
            this.selectedSortOrder = 'ASC';
        }

        SearchForStudents();
    }

    /**
     *  @Author: Chris Gibson
     *  @Date: 07.14.2017
     *
     *  @Description: This method clears all the fields for the Add Student filter search area.
     */
    public PageReference ClearAddSutdentForm(){

        this.dummyClass.Parent_Class__c = null;
        this.dummyClass.Name = null;
        this.dummyClass.Start_Date__c = null;
        this.dummyClass.Grade_Level__c = '';
        this.Age = 0;

        SearchForStudents();

        return null;

    }

    public PageReference SelectAllStudents(){

        for(UtilitiesWrappers.StudentWrapper curStudentt : this.students){

            curStudentt.isSelected = true;
        }

        return null;
    }

    @TestVisible private void createSiblingClassSOQL(){

//        String returnSOQL = '';
//
//
//        String parentClassId = this.theClass.Parent_Class__c;
//        try{
//            list<Class__c> siblingClasses = [SELECT Id FROM Class__c WHERE Parent_Class__c = :parentClassId ];
//        }
//        catch(QueryException qe){
//            system.debug(qe.getMessage());
//            return null;
//        }

//        return null;
    }

    @TestVisible private void createStudentEnrollment(String contactId,String classId){

        Student_Class_Enrollment__c enrollment = new Student_Class_Enrollment__c();
        enrollment.Student__c = contactId;
        enrollment.Class__c = classId;
        enrollment.Enrolled_Date__c = Date.today();

        insert enrollment;
    }

    @TestVisible private list<Contact> getStudents(String gradeLevel){
        set<String> existingStudents = getIdsOfEnrolledStudents();
        system.debug(existingStudents);
        try{
            list<Contact> returnContact = [SELECT Id,Name,LastName,FirstName,Is_Current_Member__c,Nickname__c,MailingStreet,MailingCity FROM Contact WHERE Grade_Level__c = :gradeLevel AND Religious_School_Student__c = true AND ID NOT IN :existingStudents];
            return returnContact;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return null;
        }
    }

    @TestVisible private list<Contact> getEnrolledStudents(){

        try{
            list<Contact> returnContact = [SELECT Id,Name,LastName,FirstName,Is_Current_Member__c,Nickname__c,MailingStreet,MailingCity FROM Contact WHERE Id in (SELECT Student__c FROM Student_Class_Enrollment__c WHERE Class__c = :this.theClass.Id)];
            return returnContact;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return null;
        }
    }

    @TestVisible private set<String> getIdsOfEnrolledStudents(){

        if(this.enrolledStudents == null ){
            return new set<String>();
        }

        set<String> returnSet = new set<String>();
        for(UtilitiesWrappers.StudentWrapper curWrapper : this.enrolledStudents){
            returnSet.add(curWrapper.student.Id);
        }
        return returnSet;
    }

    @TestVisible private set<String> getIdsOfClasses(list<Class__c> classes){

        set<String> returnSet = new set<String>();
        for(Class__c curClass : classes){
            returnSet.add(curClass.Id);
        }
        return returnSet;
    }

    @TestVisible private set<String> getIdsOfContacts(list<Contact> contacts){

        set<String> returnSet = new set<String>();
        for(Contact curContact : contacts){
            returnSet.add(curContact.Id);
        }
        return returnSet;
    }

    @TestVisible private Class__c getClass(String classId){
        try{
            Class__c returnClass = [SELECT Id,Parent_Class__c,Parent_Class__r.Parent_Class__c,Grade_Level__c,Name FROM Class__c WHERE Id = :classId];
            return returnClass;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return null;
        }
    }

    @TestVisible private set<String> getIdsOfStudentsInSiblingClasses(){

        try{
            list<Class__c> siblingClasses = [SELECT Id,Parent_Class__c,Parent_Class__r.Parent_Class__c FROM Class__c WHERE Parent_Class__c = :this.theClass.Parent_Class__c AND Id != :this.theClass.Id];
            set<String> classIds = getIdsOfClasses(siblingClasses);
            List<Contact> contacts = [SELECT Id FROM Contact WHERE ID IN (SELECT Student__c FROM Student_Class_Enrollment__c WHERE Class__c IN :classIds)];
            return getIdsOfContacts(contacts);
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return null;
        }
    }

}