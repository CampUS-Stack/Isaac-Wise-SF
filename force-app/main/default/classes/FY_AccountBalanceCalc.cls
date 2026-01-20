/**
 * Created by Chris Home Desktop on 6/3/2018.
 */

public with sharing class FY_AccountBalanceCalc {


    @TestVisible private map<Id,Account> accountMap {get; set;}
    @TestVisible private map<Id,list<Assessment__c>> fiscalYearAssessmentsByAccountId  {get; set;}
    @TestVisible private map<Id,list<Assessment__c>> toDateAssessmentsByAccountId  {get; set;}
    @TestVisible private Date FY_EndDate {get; set;}
    @TestVisible private Date FY_StartDate {get; set;}

    @TestVisible private set<Account> accountsToUpdate {get; set;}

    /**
     * @author: Chris Gibson
     * @date: 6.22.2018
     *
     * @description: This method is the 1 param constructor
     *
     * @param accountsToPerformRollupOn - list of Account SObjects to perform Fiscal Year Calculations on.
     */
    public FY_AccountBalanceCalc(list<Account> accountsToPerformRollupOn){

        try{
//            Period thePeriod = [Select StartDate,EndDate From Period Where type = 'Quarter' and StartDate = THIS_FISCAL_QUARTER];

            Integer month = Date.today().month();
            if(month >= 6){
                this.FY_StartDate = Date.newInstance(date.today().year(),6,1);
            }
            else{
                this.FY_StartDate = Date.newInstance(date.today().year() - 1,6,1);
            }
            this.FY_EndDate = Date.today();

            system.debug(this.FY_EndDate);
            system.debug(this.FY_StartDate);
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
        }
        accountsToUpdate = new set<Account>();
        accountMap = new map<Id,Account>(accountsToPerformRollupOn);
        fiscalYearAssessmentsByAccountId = getAssessmentsInCurrentFiscalYearByAccountId(accountMap.keySet());
        toDateAssessmentsByAccountId = getAssessmentsToDateByAccountId(accountMap.keySet());

    }

    public void RunAllCalculations(){
        ResetBalances();
        RunAllFiscalYearCalculations();
        RunAllToDateCalculations();

        try{
            update new list<Account>(this.accountsToUpdate);
        }
        catch(DmlException de){
            system.debug(de.getMessage());
        }
    }

    private void ResetBalances(){
        System.debug('Resetting balances for : ' + this.accountsToUpdate);
        for(Account curAccount : this.accountMap.values()){
            curAccount.Amount_Assessed_this_FY__c = 0;
            curAccount.Current_Account_Balance__c = 0;
            addAccountToSet(curAccount);
        }
    }

    public void RunAllFiscalYearCalculations(){
        if(fiscalYearAssessmentsByAccountId == null){
            return;
        }

        for(String curKey : fiscalYearAssessmentsByAccountId.keySet()){

            list<Assessment__c> assessments = fiscalYearAssessmentsByAccountId.get(curKey);
            Account theAcc = accountMap.get(curKey);

            /// Add All calculations here
            runAssessmentAmountCalculation(theAcc,assessments);

            addAccountToSet(theAcc);
        }

    }

    public void RunAllToDateCalculations(){
        if(toDateAssessmentsByAccountId == null){
            return;
        }

        for(String curKey : toDateAssessmentsByAccountId.keySet()){

            list<Assessment__c> assessments = toDateAssessmentsByAccountId.get(curKey);
            Account theAcc = accountMap.get(curKey);

            /// Add All calculations here
            runCurrentBalanceAmountCalculation(theAcc,assessments);

            addAccountToSet(theAcc);
        }

    }

    @TestVisible private void addAccountToSet(Account accToAdd){

        Boolean accountFound = false;
        for(Account curAccount : accountsToUpdate){
            if(curAccount.Id == accToAdd.Id){
                accountFound = true;
            }
        }

        if(accountFound == false){
            accountsToUpdate.add(accToAdd);
        }
    }

    @TestVisible private void runCurrentBalanceAmountCalculation(Account theAcc, list<Assessment__c> assessments){

        if(theAcc == null || assessments == null || assessments.size() == 0){
            if(theAcc != null && (assessments == null || assessments.size() == 0)){
                theAcc.Current_Account_Balance__c = 0;
            }
            return;
        }

        Decimal currentFiscalYearAccountBalance = 0.0;

        for(Assessment__c curAssessment : assessments){

            if(curAssessment.Remaining_Balance__c != null){
                currentFiscalYearAccountBalance += curAssessment.Remaining_Balance__c;
            }
        }

        theAcc.Current_Account_Balance__c = currentFiscalYearAccountBalance;
    }

    @TestVisible private void runAssessmentAmountCalculation(Account theAcc, list<Assessment__c> assessments){

        if(theAcc == null || assessments == null || assessments.size() == 0){
            if(theAcc != null && (assessments == null || assessments.size() == 0)){
                theAcc.Amount_Assessed_this_FY__c = 0;
            }
            return;
        }

        System.debug(assessments);

        Decimal currentFiscalYearAssessmentAmount = 0.0;

        for(Assessment__c curAssessment : assessments){

            if(curAssessment.Assessed_Amount__c != null){
                currentFiscalYearAssessmentAmount += curAssessment.Assessed_Amount__c;
            }
        }

        theAcc.Amount_Assessed_this_FY__c = currentFiscalYearAssessmentAmount;
    }

    @TestVisible private map<Id,list<Assessment__c>> getAssessmentsInCurrentFiscalYearByAccountId(set<Id> accountIds){
        try{
            map<Id,list<Assessment__c>> returnMap = new map<Id,list<Assessment__c>>();
            Date startDate = this.FY_StartDate;
            Date endDate = this.FY_EndDate;
            system.debug(startDate);
            system.debug(endDate);
            String soql = 'SELECT Id,Assessed_Amount__c,Account__c,Remaining_Balance__c FROM Assessment__c WHERE Account__c in :accountIds AND (Assessment_Date__c >= :startDate AND Assessment_Date__c <= :endDate)';
            list<Assessment__c> assessments = Database.query(soql);

            system.debug(assessments.size());
            for(Assessment__c curAssessment : assessments){
                if(String.isNotBlank(curAssessment.Account__c) ){
                    if( returnMap.containsKey(curAssessment.Account__c)){
                        returnMap.get(curAssessment.Account__c).add(curAssessment);
                    }
                    else{
                        returnMap.put(curAssessment.Account__c, new list<Assessment__c>{curAssessment});
                    }
                }
            }
            return returnMap;
        }
        catch (QueryException qe){
            system.debug(qe.getMessage());
            return null;
        }
    }
    @TestVisible private map<Id,list<Assessment__c>> getAssessmentsToDateByAccountId(set<Id> accountIds){
        try{
            map<Id,list<Assessment__c>> returnMap = new map<Id,list<Assessment__c>>();
            Date endDate = date.today();
            String soql = 'SELECT Id,Assessed_Amount__c,Account__c,Remaining_Balance__c FROM Assessment__c WHERE Account__c in :accountIds AND Assessment_Date__c <= :endDate';
            list<Assessment__c> assessments = Database.query(soql);

            system.debug(assessments.size());
            for(Assessment__c curAssessment : assessments){
                if(String.isNotBlank(curAssessment.Account__c) ){
                    if( returnMap.containsKey(curAssessment.Account__c)){
                        returnMap.get(curAssessment.Account__c).add(curAssessment);
                    }
                    else{
                        returnMap.put(curAssessment.Account__c, new list<Assessment__c>{curAssessment});
                    }
                }
            }
            return returnMap;
        }
        catch (QueryException qe){
            system.debug(qe.getMessage());
            return null;
        }
    }

}