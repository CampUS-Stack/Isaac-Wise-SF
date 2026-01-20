/**
 * Created by Chris Home Desktop on 6/28/2017.
 */

global with sharing class UtilitiesReligiousSchool {

    webService static String RemoveFromAllClasses(String contactId){

        try{
            list<Student_Class_Enrollment__c> enrollments  = [SELECT Id FROM Student_Class_Enrollment__c sce WHERE sce.Student__c = :contactId];

            if(enrollments.size() == 0){
                return 'NoEnrollmentsFound';
            }

            delete enrollments;
        }
        catch (QueryException qe){
            system.debug(qe.getMessage());
            return 'NoEnrollmentsFound';
        }
        catch(DmlException de){
            system.debug(de.getMessage());
            return 'DeleteError';
        }
        catch(Exception e){
            system.debug(e.getMessage());
            return 'UnknownException';
        }

        return 'SUCCESS';
    }

    webService static String RemoveFromAllHebrewClasses(String contactId){

        try{
            /// TODO: Implement filter for Hebrew enrollment only.
            Date theDate = Date.newInstance(2017,08,31);
            list<Student_Class_Enrollment__c> enrollments  = [SELECT Id FROM Student_Class_Enrollment__c sce WHERE sce.Student__c = :contactId AND Class__r.Name like '%Hebrew%' AND Class__r.Start_Date__c > :theDate];
            delete enrollments;
        }
        catch (QueryException qe){
            system.debug(qe.getMessage());
            return 'NoEnrollmentsFound';
        }
        catch(DmlException de){
            system.debug(de.getMessage());
            return 'InertError';
        }
        catch(Exception e){
            system.debug(e.getMessage());
            return 'UnknownException';
        }

        return 'SUCCESS';
    }

    /**
      * @Author: Chris Gibson
      * @Date: 07.14.2017
      *
      * @Description: This class holds class filter possibilities for use with Religious School Utility methods.
     */
    public class ClassFilter{

        public Integer Age {get; set;}
        public String Name {get; set;}
        public String ClassId {get; set;}
        public String GradeLevel {get; set;}
        public String Birthdate {get; set;}
        public set<String> EnrolledStudentIds {get; set;}
        public set<String> EnrolledClassIds {get; set;}

        public String ClassName {get; set;}
        public String StudentContactId {get; set;}

        public String OrderField {get; set;}
        public String OrderDirection {get; set;}

        public ClassFilter(){}
    }

    public static Student_Class_Enrollment__c GetStudentClassEnrollement(String studentId,String classId){

        try{
            Student_Class_Enrollment__c sce = [SELECT Id FROM Student_Class_Enrollment__c WHERE Student__c = :studentId AND Class__c = :classId];
            return sce;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return null;
        }
    }

    public static Student_Class_Enrollment__c GetStudentClassEnrollementByStudent(String studentId){

        try{
            Student_Class_Enrollment__c sce = [SELECT Id FROM Student_Class_Enrollment__c WHERE Student__c = :studentId];
            return sce;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return null;
        }
    }

    public static String GetStudentsSOQLString(ClassFilter theClassFilter){

        String soql = 'SELECT Id,Name,LastName,FirstName,Is_Current_Member__c,Nickname__c,MailingStreet,MailingCity FROM Contact WHERE ';
        String studentNameCriteria = getStudentNameSOQLCriteria(theClassFilter.Name);
        if(studentNameCriteria != ''){
            soql += studentNameCriteria + ' AND ';
        }
        String studentBirthdateCriteria = getStudentAgeSOQLCriteria(theClassFilter.Age);
        if(studentBirthdateCriteria != ''){
            soql += studentBirthdateCriteria + ' AND ';
        }
        String studentGradeLevelCriteria = getStudentGradeLevelSOQLCriteria(theClassFilter.GradeLevel);
        if(studentGradeLevelCriteria != ''){
            soql += studentGradeLevelCriteria + ' AND ';
        }
        String studentParentClassCriteria = getStudentParentClassSOQLCriteria(theClassFilter.ClassId);
        if(studentParentClassCriteria != ''){
            soql += studentParentClassCriteria + ' AND ';
        }

        if(theClassFilter != null && theClassFilter.EnrolledStudentIds != null){
            String soqlForIds = getSetStringForSOQL(theClassFilter.EnrolledStudentIds);
            if(soqlForIds != '')
                soql += 'ID NOT IN '+ soqlForIds +'AND ';
        }
        soql += 'Religious_School_Student__c = true ';

        return soql;
    }

    //convert a Set<String> into a quoted, comma separated String literal for inclusion in a dynamic SOQL Query
    public static String getSetStringForSOQL(Set<String> mapKeySet)
    {
        String newSetStr = '' ;
        for(String str : mapKeySet)
            newSetStr += '\'' + str + '\',';

        newSetStr = newSetStr.lastIndexOf(',') > 0 ? '(' + newSetStr.substring(0,newSetStr.lastIndexOf(',')) + ')' : newSetStr ;
        System.debug('quoteKeySet() :  newSetStr ============ ' + newSetStr);

        return newSetStr;

    }

    public static list<Contact> GetStudents(set<String> enrolledStudents, String query){

        try{
            list<Contact> returnContact = Database.query(query);
            return returnContact;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return null;
        }
    }

    public static list<Contact> GetStudents(ClassFilter theClassFilter){

        String soql = GetStudentsSOQLString(theClassFilter);
        try{
            list<Contact> returnContact = Database.query(soql);
            return returnContact;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return null;
        }
        return QueryForStudentContacts(soql);
    }

    public static list<Contact> QueryForStudentContacts(String soqlQuery){

        try{
            list<Contact> returnContact = Database.query(soqlQuery);
            return returnContact;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return null;
        }
    }


    @TestVisible private static String getStudentNameSOQLCriteria(String theName){

        if(!String.isEmpty(theName)){
            return ' Name LIKE \'%' + theName + '%\'';
        }
        else{
            return '';
        }
    }

    @TestVisible private static String getStudentDateSOQLCriteria(Date theDate){

        if(theDate != null){
            return ' Birthdate = :theDate';
        }
        else{
            return '';
        }
    }

    @TestVisible private static String getStudentAgeSOQLCriteria(Integer age){

        if(age != null && age != 0){
            return ' Age__c = ' + age;
        }
        else{
            return '';
        }
    }

    @TestVisible private static String getStudentGradeLevelSOQLCriteria(String gradeLevel){

        if(!String.isEmpty(gradeLevel)){
            return ' Grade_Level__c = \'' + gradeLevel + '\'';
        }
        else{
            return '';
        }
    }

    @TestVisible private static String getStudentParentClassSOQLCriteria(String parentId){

        if(!String.isEmpty(parentId)){
            return ' Id IN (SELECT Student__c FROM Student_Class_Enrollment__c WHERE Class__c = \'' + parentId + '\') ';
        }
        else{
            return '';
        }
    }


    ///// -------------------- Class Utility Methods --------------------- \\\


    public static list<Class__c> GetClasses(ClassFilter theClassFilter){

        String soql = GetClassSOQLString(theClassFilter);
        try{
            list<Class__c> returnClasses = Database.query(soql);
            return returnClasses;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return null;
        }
        return QueryForClasses(soql);
    }


    public static list<Class__c> GetClasses(set<String> enrolledClasses, String query){

        try{
            list<Class__c> returnClasses = Database.query(query);
            return returnClasses;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return null;
        }
    }



    public static list<Class__c> QueryForClasses(String soqlQuery){

        try{
            list<Class__c> returnClasses = Database.query(soqlQuery);
            return returnClasses;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return null;
        }
    }


    public static String GetClassSOQLString(ClassFilter theClassFilter){

        system.debug('Class Filter: ' + theClassFilter);

        String soql = 'SELECT Id,Name,Parent_Class__c,Parent_Class__r.Parent_Class__c FROM Class__c WHERE ';
        String studentNameCriteria = getClassNameSOQLCriteria(theClassFilter.Name);

//        String studentDateCriteria = getClassDateSOQLCriteria();
//        if(studentDateCriteria != ''){
//            if(studentNameCriteria != ''){
//                soql += studentNameCriteria + ' AND ';
//            }
//            soql += studentDateCriteria;
//        }

        system.debug(theClassFilter.EnrolledClassIds);
        if(theClassFilter.EnrolledClassIds != null){
            if(studentNameCriteria != ''){
                soql += studentNameCriteria;
            }
            String soqlForIds = getSetStringForSOQL(theClassFilter.EnrolledClassIds);
            if(soqlForIds != ''){
                soql +=  ' AND ID NOT IN ' + soqlForIds;
            }
        }
        system.debug(soql);
        return soql;
    }


    @TestVisible private static String getClassNameSOQLCriteria(String gradeLevel){

        if(!String.isEmpty(gradeLevel)){
            return ' Name LIKE \'%' + gradeLevel + '%\'';
        }
        else{
            return '';
        }
    }


    @TestVisible private static String getClassDateSOQLCriteria(){

        String returnString = ' CALENDAR_YEAR(End_Date__c) > ' + date.today().year() + ' AND ';
        returnString += ' CALENDAR_MONTH(End_Date__c) > ' + date.today().month() + '';
        return returnString;
    }

}