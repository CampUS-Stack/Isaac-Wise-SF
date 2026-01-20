/**
 * Created by Kritik Garg on 30-07-2019.
 */

global class ScheduleBatchProcessYahrzeits  implements Schedulable {

    public static String sched = '0 00 1 ? * MON';  //Every Day at 1 AM - MON

    global static String scheduleMe() {
        ScheduleBatchProcessYahrzeits SC = new ScheduleBatchProcessYahrzeits();

        if(Test.isRunningTest()){
            return System.schedule('Batch Job for Yahrzeits tests', sched, SC);
        }
        else{
            return System.schedule('Batch Job for Yahrzeits', sched, SC);
        }
    }

    global void execute(SchedulableContext sc) {

        BatchProcessYahrzeits b1 = new BatchProcessYahrzeits();
        ID batchprocessid = Database.executeBatch(b1,75);
    }


}