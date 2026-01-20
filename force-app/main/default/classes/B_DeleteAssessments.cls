/**
 * Created by Chris Home Desktop on 8/13/2018.
 */

global class B_DeleteAssessments implements Database.Batchable<sObject> {

    global B_DeleteAssessments(){}

    global Iterable<sObject> start(Database.BatchableContext bc) {

        list<Assessment__c> assessments = getAssessmentsToDelete();
        return assessments;
    }
    global void execute(Database.BatchableContext bc, List<SObject> records){

        try{
            delete records;
        }
        catch(DmlException de){
            system.debug(de.getMessage());
        }
    }

    global void finish(Database.BatchableContext BC) {

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

    public static list<Assessment__c> getAssessmentsToDelete(){
        try{

            list<Scheduled_Payment__c> schedPayments = [SELECT Id,Assessment__c From Scheduled_Payment__c WHERE Assessment__r.From_Website__c = true AND Id NOT IN (SELECT Scheduled_Payment__c FROM Payment_Adjustment_Allocation__c WHERE Scheduled_Payment__r.Assessment__r.From_Website__c = true AND Incomplete_Payment__c = false)];

            set<Id> assessmentIds = new set<Id>();
            for(Scheduled_Payment__c curSchedPay : schedPayments){
                if(String.isNotBlank(curSchedPay.Assessment__c)){
                    assessmentIds.add(curSchedPay.Assessment__c);
                }
            }

            list<Assessment__c> assessments = [SELECT Id FROM Assessment__c WHERE Id = :assessmentIds];
            return assessments;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return null;
        }
    }

}