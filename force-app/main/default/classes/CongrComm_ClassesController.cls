public class CongrComm_ClassesController {

    Public Account theFamily { get; set; }
    Public List<classWrapper> classWrapperList { get; set; }
    Public Boolean hasStudents { get; set; }

    public CongrComm_ClassesController() {
        User currentUser = [
                SELECT Id, ContactId
                FROM User
                //WHERE Id = '00529000001lCTy'];
                WHERE Id = :UserInfo.getUserId()
        ];
        Contact currentContact = [
                SELECT Id, AccountId, FirstName, LastName
                FROM Contact
                WHERE Id = :currentUser.ContactId
        ];

        theFamily = [
                SELECT Id, Name
                FROM Account
                WHERE Id = :currentContact.AccountId
        ];

        Map<Id, Contact> familyMembers = new Map<Id, Contact>([
                SELECT Id, FirstName, LastName
                FROM Contact
                WHERE AccountId = :theFamily.Id
        ]);
        Set<Id> familyMemberIds = new Set<Id>();
        for (Contact c : familyMembers.values()) {
            familyMemberIds.add(c.Id);
        }

        System.debug('familyMemberIds: ' + familyMemberIds);

        Map<Id, List<Student_Class_Enrollment__c>> familyClassMap = new Map<Id, List<Student_Class_Enrollment__c>>();
        List<Student_Class_Enrollment__c> familyClasses = [
                SELECT Id, Student__c, Class__r.Name, Class__r.Class_Description__c,
                        Class__r.Teacher__r.FirstName, Class__r.Teacher__r.LastName,
                        Class__r.Room__c
                FROM Student_Class_Enrollment__c
                WHERE Student__c IN :familyMemberIds
                AND Class__c NOT IN (SELECT Parent_Class__c FROM Class__c)
                AND Class__r.Display_Class_on_Portal__c = true
                ORDER BY Enrolled_Date__c DESC NULLS LAST
        ];


        for (Student_Class_Enrollment__c sce : familyClasses) {
            List<Student_Class_Enrollment__c> theList = familyClassMap.get(sce.Student__c);
            if (theList == null) {
                theList = new List<Student_Class_Enrollment__c>();
            }
            theList.add(sce);
            familyClassMap.put(sce.Student__c, theList);
        }

        classWrapperList = new List<classWrapper>();
        for (Id i : familyClassMap.keySet()) {
            List<Student_Class_Enrollment__c> theList = familyClassMap.get(i);
            if (theList != null) {
                Contact theStudent = familyMembers.get(i);
                classWrapperList.add(new classWrapper(theStudent, theList));
            }
        }
        if (classWrapperList.size() > 0) {
            hasStudents = true;
        } else {
            hasStudents = false;
        }

    }

    public class classWrapper {

        Public Contact theStudent { get; set; }
        Public List<Student_Class_Enrollment__c> theClasses { get; set; }

        public classWrapper(Contact theStudent, List<Student_Class_Enrollment__c> theClasses) {
            this.theStudent = theStudent;
            this.theClasses = theClasses;
        }

    }

}