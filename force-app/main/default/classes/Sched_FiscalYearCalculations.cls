/**
 * Created by Chris Home Desktop on 6/10/2018.
 */

global class Sched_FiscalYearCalculations  implements Schedulable {

//    scheduledBatchable b = new scheduledBatchable();
//    String sch = '20 30 8 10 2 ?'; // This is just like a regular cron job
//    system.schedule('Job Name', sch, b);

    global void execute(SchedulableContext ctx) {

        B_FiscalYearCalculations myBatch = new B_FiscalYearCalculations();
        Id batchId = Database.executeBatch(myBatch,200);
    }
}