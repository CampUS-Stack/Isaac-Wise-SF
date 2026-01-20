/**
 * Created by Chris Home Desktop on 6/10/2018.
 */

global class B_FiscalYearCalculations implements Database.Batchable<sObject> {

    global B_FiscalYearCalculations(){}

    global Iterable<sObject> start(Database.BatchableContext bc) {

        list<Account> accounts = [SELECT Id,Amount_Assessed_this_FY__c,Current_Account_Balance__c From Account];
        return accounts;
    }
    global void execute(Database.BatchableContext bc, List<SObject> records){

        FY_AccountBalanceCalc fiscalYearCalc = new FY_AccountBalanceCalc((list<Account>)records);
        fiscalYearCalc.RunAllCalculations();
    }
    global void finish(Database.BatchableContext bc){
        // execute any post-processing operations
    }

}