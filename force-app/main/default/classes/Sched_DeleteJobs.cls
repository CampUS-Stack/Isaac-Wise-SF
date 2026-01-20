/**
 * Created by Chris Home Desktop on 8/13/2018.
 */
global class Sched_DeleteJobs implements Schedulable{

//    String sch = '0 0 2 * * ?'; // This is just like a regular cron job
//    System.schedule('Deletion Jobs', sch, new Sched_DeleteJobs());

    global void execute(SchedulableContext ctx) {

        B_DeleteAssessments deleteAssessBatchJob = new B_DeleteAssessments();
        Id assessmentBatchID = Database.executeBatch(deleteAssessBatchJob,200);

        B_DeletePayments deletePaymentBatchJob = new B_DeletePayments();
        Id paymentBatchId = Database.executeBatch(deletePaymentBatchJob,200);
    }
}