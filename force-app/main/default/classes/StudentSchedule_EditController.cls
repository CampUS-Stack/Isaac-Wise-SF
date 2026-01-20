/**
 * Created by Chris Home Desktop on 7/14/2017.
 */

public with sharing class StudentSchedule_EditController {

    public Boolean displayAddClass {get; set;}

    public Contact TheStudent {get; set;}

    public list<UtilitiesWrappers.RS_ClassWrapper> EnrolledClassWrappers {get; set;}
    public list<UtilitiesWrappers.RS_ClassWrapper> ClassWrappers {get; set;}

    public String ClassName {get; set; }
    public Class__c theClass {get; set;}

    public String ClassIdToAdd {get; set;}
    public String ClassIdToRemove {get; set;}

    public Contact DummyContact {get; set;}

    /// Sorting Variables
    public String selectedField {get; set;}
    public String selectedSortOrder {get; set;}

    public StudentSchedule_EditController(ApexPages.StandardController stdController){

        this.TheStudent = (Contact)stdController.getRecord();
        this.selectedSortOrder = 'ASC';
        this.selectedField = 'Name';
        this.displayAddClass = false;

        SearchForClasses();

    }

    public PageReference SearchForClasses(){

        this.EnrolledClassWrappers = UtilitiesWrappers.CreateClassWrappers(getEnrolledClasses());
        system.debug(EnrolledClassWrappers);
        UtilitiesReligiousSchool.ClassFilter theClassFilter = new UtilitiesReligiousSchool.ClassFilter();
        system.debug('User Class Name Input: ' + this.ClassName);
        theClassFilter.Name = this.ClassName;
        theClassFilter.EnrolledClassIds = getIdsOfEnrolledClasses();
        this.ClassWrappers = UtilitiesWrappers.CreateClassWrappers(UtilitiesReligiousSchool.GetClasses(theClassFilter));

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

        SearchForClasses();
    }

    /**
     *  @Author: Chris Gibson
     *  @Date: 07.14.2017
     *
     *  @Description: This method clears all the fields for the Add Student filter search area.
     */
    public PageReference ClearAddClassForm(){

        this.ClassName = '';

        SearchForClasses();

        return null;

    }

    public void ShowAddClassSection(){

        if(displayAddClass == false){
            displayAddClass = true;
        }
    }



    public PageReference AddSelectedClass(){

        list<Student_Class_Enrollment__c> enrollmentsToInsert = new list<Student_Class_Enrollment__c>();
        for(UtilitiesWrappers.RS_ClassWrapper curWrap : this.ClassWrappers){

            if(curWrap.isSelected == true){
                Student_Class_Enrollment__c sce = new Student_Class_Enrollment__c();
                sce.Class__c = curWrap.TheClass.Id;
                sce.Student__c = this.TheStudent.Id;
                sce.Enrolled_Date__c = Date.today();
                enrollmentsToInsert.add(sce);
            }
        }

        insert enrollmentsToInsert;

        SearchForClasses();

        return null;
    }


    public PageReference RemoveClass(){

        system.debug(this.ClassIdToRemove);

        if(String.isEmpty(this.ClassIdToRemove)){
            return null;
        }

        try{
            Student_Class_Enrollment__c enrollment = UtilitiesReligiousSchool.GetStudentClassEnrollement(this.TheStudent.Id,this.ClassIdToRemove);
            delete enrollment;
        }
        catch(DmlException de){
            system.debug(de.getMessage());
        }

        SearchForClasses();

        return null;
    }

    @TestVisible private list<Class__c> getEnrolledClasses(){

        try{
            Date theDate = date.newInstance(date.today().year(),9,1);
            list<Class__c> returnClasses = [SELECT Id,Name FROM Class__c WHERE Id in (SELECT Class__c FROM Student_Class_Enrollment__c WHERE Student__c = :this.TheStudent.Id) AND Start_Date__c > :theDate AND Start_Date__c != null];
            return returnClasses;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return null;
        }
    }



    @TestVisible private set<String> getIdsOfEnrolledClasses(){

        if(this.EnrolledClassWrappers == null ){
            return new set<String>();
        }

        set<String> returnSet = new set<String>();
        for(UtilitiesWrappers.RS_ClassWrapper curWrapper : this.EnrolledClassWrappers){
            returnSet.add(curWrapper.TheClass.Id);
        }
        return returnSet;
    }

}