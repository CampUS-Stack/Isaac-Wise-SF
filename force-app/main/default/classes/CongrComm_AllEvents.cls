public class CongrComm_AllEvents {

    public list<Event__c> TheEvents {get; set;}

    Public CongrComm_AllEvents() {

        Date compareDate = Date.today().addMonths(6);
        this.TheEvents = [
                SELECT Id,Name,Event_Date_Start__c,Description__c
                FROM Event__c
                WHERE Event_Date_End__c >= :date.today()
                AND Include_in_multi_signup__c = false
                AND Display_on_portal__c = true
                ORDER BY Event_Date_Start__c
        ];
    }

}