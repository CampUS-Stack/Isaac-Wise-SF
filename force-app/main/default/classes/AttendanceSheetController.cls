public class AttendanceSheetController {

    private final Class__c cls;
    public List<Student_Class_Enrollment__c> students{get;set;}
    public List<Date> listOfDate {get;set;}
    public List<String> listOfWeeks {get;set;}

    public AttendanceSheetController(ApexPages.StandardController stdController) {
        listOfDate = new List<Date>();

        students = new List<Student_Class_Enrollment__c>();
        this.cls = (Class__c)stdController.getRecord();
        students = [SELECT Id, First_Name__c, Last_Name__c
        FROM Student_Class_Enrollment__c
        WHERE Class__r.Id =: this.cls.Id Order By Student__r.Account.Name];

        Date datetmp = [SELECT Start_Date__c FROM Class__c WHERE id =:this.cls.Id][0].Start_Date__c  ;
        if(datetmp != NULL) {
            Apexpages.currentPage().getHeaders().put('content-disposition', 'filename=class '+cls.Id+' Attendance '+String.valueOf(datetmp)+'.pdf');
            datetmp = findNextSunday(datetmp);
            for(Integer count=0; count<13; count++) {
                listOfDate.add(datetmp);
                datetmp = datetmp.addDays(7);
            }
        }
        //System.debug(listOfDate);
        populateWeekList();
    }

    @TestVisible public void populateWeekList(){

        this.listOfWeeks = new list<String>();

        for(Integer i = 1; i < 14 ; i ++){
            this.listOfWeeks.add('Week ' + i);
        }
    }

    public Date findNextSunday(Date current) {
        DateTime myDateTime = (DateTime)current;
        myDateTime.addHours(1);
        Integer dayOfWeek =Integer.valueOf(myDateTime.format('u'));
        //System.debug(dayOfWeek +' '+ myDateTime+ ' '+  myDateTime.format('u'));
        myDateTime = myDateTime.addDays(7-dayOfWeek);
        //System.debug(myDateTime+ ' '+  myDateTime.format('u'));
        Date myDate = date.newinstance(myDateTime.year(), myDateTime.month(), myDateTime.day());
        //System.debug(String.valueOf(myDate));
        return myDate;
    }

    public Double offset{
        get {
            TimeZone tz = UserInfo.getTimeZone();
            //Milliseconds to Day
            return tz.getOffset(DateTime.now()) / (1000 * 3600 * 24.0);
        }
    }
}