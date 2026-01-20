/**
 * Created by Chris Home Desktop on 8/13/2018.
 */

global class B_DeletePayments implements Database.Batchable<sObject> {

    global B_DeletePayments(){}

    global Iterable<sObject> start(Database.BatchableContext bc) {

        Datetime oneHourAgoDateTime = Datetime.now().addHours(-1);
        list<Payment_Adjustment__c> paymentsToDelete = [SELECT Id FROM Payment_Adjustment__c WHERE Incomplete_Payment__c = :true AND CreatedDate < :oneHourAgoDateTime];
        return paymentsToDelete;
    }

    global void execute(Database.BatchableContext bc, List<SObject> records){

        try{
            delete records;
        }
        catch(DmlException de){
            system.debug(de.getMessage());
        }
    }
    global void finish(Database.BatchableContext bc){
        // Get the ID of the AsyncApexJob representing this batch job
        // from Database.BatchableContext.
        // Query the AsyncApexJob object to retrieve the current job's information.

        AsyncApexJob a = [Select Id, Status,ExtendedStatus,NumberOfErrors, JobItemsProcessed,
                TotalJobItems, CreatedBy.Email
        from AsyncApexJob where Id =:BC.getJobId()];

        if(a.Status == 'Failed'){
            // Send an email to the Apex job's submitter notifying of job completion.
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            String[] toAddresses = new String[] {'chris@undefined-design.com'};
            mail.setToAddresses(toAddresses);
            mail.setSubject('Delete Assessment Job: ' + a.Status);
            mail.setPlainTextBody('The batch Apex job processed ' + a.TotalJobItems +
                    ' batches with '+ a.NumberOfErrors + ' failures.');
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
    }
}