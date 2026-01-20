/**
 * Created by Chris Home Desktop on 12/2/2017.
 */

public with sharing class BatchInvoiceAssessmentController {

    public Boolean ShowAssessmentEntry {get; set;}
    public Boolean ShowAccountSearchPage {get; set;}

    public Boolean MembersOnly {get; set;}

    public Class__c DummClass {get; set;}

    public Boolean ShouldRemoveRecordsAssessedThisYear {get; set;}

    public Assessment__c MasterAssessment {get; set;}
    public list<Account> TheAccounts {get; set;}
    public list<UtilitiesWrappers.AccountWrapper> TheAccountWrappers {get; set;}
    public list<Account> AccountsToExcludeForAll {get; set;}
    public list<UtilitiesWrappers.AccountWrapper> AccountWrappersToExcludeForAll {get; set;}
    public list<UtilitiesWrappers.AccountWrapper> FoundAccountWrappers {get; set;}

    public Contact DummyContact {get; set;}
    public String HouseholdName {get; set;}
    public String SelectedAccountId {get; set;}
    public String SelectedAccountIdToRemove {get; set;}

    public PaginationController AllPaginationCtrl {get; set;}
    public PaginationController SearchByPaginationCtrl {get; set;}

    public Integer NumOfPeopleToAssess {get; set;}
    public Integer NumberOfPeopleToAssess {
        get{
            if(TheAccounts == null){
                return 0;
            }
            else{
                return TheAccounts.size();
            }
        }
    }

    public list<Account> AllPaginationAccounts {
        get{
            list<Account> returnList = new list<Account>();
            for(Object currentAccount : this.AllPaginationCtrl.getObjectRecords()){
                returnList.add((Account)currentAccount);
            }

            return returnList;
        }
    }


    public list<UtilitiesWrappers.AccountWrapper> SearchByPaginationAccounts {
        get{
            list<UtilitiesWrappers.AccountWrapper> returnList = new list<UtilitiesWrappers.AccountWrapper>();
            for(Object currentAccount : this.SearchByPaginationCtrl.getObjectRecords()){
                returnList.add((UtilitiesWrappers.AccountWrapper)currentAccount);
            }

            return returnList;
        }
    }

    public String ChosenSearchType {get; set;}
    public List<SelectOption> SearchOptions{
        get{
            list<SelectOption> returnList = new list<SelectOption>();
            returnList.add(new SelectOption('Household','Household'));
            returnList.add(new SelectOption('All','All'));
            return returnList;
        }
    }

    public set<Id> HouseholdsToExcludeForAll {
        get{
            if(AccountsToExcludeForAll == null){
                return new set<Id>();
            }
            else{
                set<Id> returnSet = new set<Id>();
                for(Account curAcc : AccountsToExcludeForAll){
                    returnSet.add(curAcc.Id);
                }
                return returnSet;
            }
        }
    }

    public BatchInvoiceAssessmentController(){

        ShowAssessmentEntry = true;
        ShowAccountSearchPage = false;
        MasterAssessment = new Assessment__c();
        TheAccounts = new list<Account>();
        TheAccountWrappers = new list<UtilitiesWrappers.AccountWrapper>();
        FoundAccountWrappers = new list<UtilitiesWrappers.AccountWrapper>();
        AccountsToExcludeForAll = new list<Account>();
        AccountWrappersToExcludeForAll = new list<UtilitiesWrappers.AccountWrapper>();
        SelectedAccountId = '';
        SelectedAccountIdToRemove = '';
        DummyContact = new Contact();
        HouseholdName = '';
        ChosenSearchType = 'Household';
        this.AllPaginationCtrl = new PaginationController(new list<Account>());
        this.SearchByPaginationCtrl = new PaginationController(new list<UtilitiesWrappers.AccountWrapper>());
        this.DummClass = new Class__c();
        this.MembersOnly = true;
        this.ShouldRemoveRecordsAssessedThisYear = true;

        RunAccountQuery();
    }

    public PageReference RunAccountQuery(){

        ////     TODO: Cleanup this process to more cleanly query for the different page block tables
        ////      currently process is done by VF Page and not cleanly indicated in controller. Can cause for confusion/side effects down the road.

        if(ChosenSearchType == 'All'){
            this.TheAccounts = SearchAccounts();
            this.AllPaginationCtrl.objects = this.TheAccounts;
            this.AllPaginationCtrl.setTotalPages();
            this.NumOfPeopleToAssess = GetAccountCount();
            this.TheAccountWrappers = UtilitiesWrappers.CreateAccountWrappers(this.AllPaginationCtrl.getObjectRecords());
        }
        else{
            return SearchForAccounts();
        }
        return null;
    }

    public PageReference AddBackToAll(){

        if(String.isEmpty(SelectedAccountIdToRemove) || !HouseholdsToExcludeForAll.contains(SelectedAccountIdToRemove)){
            return null;
        }

        Integer indexOfAccToRemove = 0;
        for(Account acc : AccountsToExcludeForAll){
            if(acc.Id == SelectedAccountIdToRemove){
                break;
            }
            indexOfAccToRemove++;
        }

        AccountsToExcludeForAll.remove(indexOfAccToRemove);
        NumOfPeopleToAssess ++;
        RunAccountQuery();

        return null;
    }

    public PageReference RemoveFromAll(){

        for(UtilitiesWrappers.AccountWrapper curAcc : this.TheAccountWrappers){
            if(curAcc.IsSelected){
                AccountsToExcludeForAll.add(curAcc.TheAccount);
                NumOfPeopleToAssess --;
            }
            else{
                this.TheAccounts.add(curAcc.TheAccount);
            }
        }

        RunAccountQuery();
        return null;
    }

    public PageReference Clear(){

        MasterAssessment = new Assessment__c();
        DummyContact = new Contact();
        HouseholdName = '';
        return null;
    }

    public PageReference GoToAccountSearch(){

        ShowAccountSearchPage = true;
        ShowAssessmentEntry = false;
        return null;
    }

    public PageReference CreateAssessmentsAndContinue(){
        CreateAssessments();

        DummClass.Parent_Class__c = null;
        HouseholdName = '';
        FoundAccountWrappers = new list<UtilitiesWrappers.AccountWrapper>();

        return null;
    }

    public PageReference CreateAssessments(){

        list<Assessment__c> assessmentsToInsert = new list<Assessment__c>();
        if(ChosenSearchType == 'All'){
            assessmentsToInsert = createAssessments(TheAccounts);
        }
        else if(ChosenSearchType == 'Household'){
            assessmentsToInsert = createAssessments(FoundAccountWrappers);
        }

        try{
            insert assessmentsToInsert;
        }
        catch(DmlException de){
            system.debug(de.getMessage());
        }

        PageReference pr = new PageReference('/home/home.jsp');
        pr.setRedirect(true);
        return pr;

    }
    public PageReference GoToAssessmentCreation(){

        ShowAccountSearchPage = false;
        ShowAssessmentEntry = true;
        return null;
    }


    //// Method used for Household Searching functionality.
    public PageReference SearchForAccounts(){

        if(String.isEmpty(HouseholdName) && String.isEmpty(this.DummClass.Parent_Class__c)){
            /// Apex Page Message
            return null;
        }

        this.FoundAccountWrappers = createWrappers(GetAccounts(HouseholdName,DummClass.Parent_Class__c));
        this.SearchByPaginationCtrl = new PaginationController(this.FoundAccountWrappers);
        this.SearchByPaginationCtrl.setTotalPages();
        this.DummyContact = new Contact();

        return null;
    }



    /////---------------------------- PRIVATE HELPER METHODS ----------------------------------------- \\\\




    @TestVisible private list<Account> SearchAccounts(){

        try{
            list<Account> accs = [SELECT Id,Name,Current_Mailing_Address__c  FROM Account WHERE Is_Current_Member__c = :this.MembersOnly AND ID NOT IN :HouseholdsToExcludeForAll ORDER BY Name];
            return accs;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return null;
        }

    }

    @TestVisible private Account GetAccount(String accountId){

        try{
            Account acc = Database.query('SELECT Id,Name,Current_Mailing_Address__c  FROM Account WHERE ID = \'' + accountId + '\'');
            return acc;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return null;
        }

    }

    @TestVisible private list<Account> GetAccounts(String accountName,String classId){

        try{
            set<String> accountIdsFromClasses = getAccountIdsFromClasses(classId);
            set<String> accountIdsFromassessments = getAlreadyAssessedAccountIds();
            String soql = 'SELECT Id,Name,Current_Mailing_Address__c  FROM Account WHERE Name LIKE \'%' + accountName + '%\'';
            if(accountIdsFromClasses != null){
                soql += ' AND Id in :accountIdsFromClasses';
            }
            if(accountIdsFromassessments != null){
                soql += ' AND Id NOT IN :accountIdsFromassessments';
            }
            soql += ' ORDER BY Name ';

            list<Account> accs = Database.query(soql);
            return accs;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return null;
        }

    }
    @TestVisible private set<String> getAccountIdsFromClasses(String classId){

        if(String.isEmpty(classId)){
            return null;
        }

        try{
            list<Contact> contacts = new list<Contact>();
            contacts = [SELECT AccountId FROM Contact c WHERE Id IN (SELECT Student__c FROM Student_Class_Enrollment__c WHERE Class__c = :classId)];
            if(contacts != null){
                set<String> accountIds = getAccountIdsFromContacts(contacts);
                return accountIds;
            }else{
                return null;
            }
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return null;
        }


    }
    @TestVisible private set<String> getAlreadyAssessedAccountIds(){

        if(!ShouldRemoveRecordsAssessedThisYear || String.isEmpty(this.MasterAssessment.Designation__c)){
            return null;
        }
        try{
            Integer year = Date.today().year();
            list<Assessment__c> assessments = [SELECT Account__c FROM Assessment__c WHERE CALENDAR_YEAR(Assessment_Date__c) = :year AND Designation__c = :this.MasterAssessment.Designation__c];
            set<String> accountIds = getAccountIdsFromAssessments(assessments);
            return accountIds;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return null;
        }

    }

    @TestVisible private Integer GetAccountCount(){

        try{
            list<AggregateResult> accs = [SELECT Count(Id) num FROM Account WHERE Is_Current_Member__c = :this.MembersOnly AND ID NOT IN :HouseholdsToExcludeForAll];
            if(accs != null || accs.size() > 0){
                return Integer.valueOf(accs[0].get('num'));
            }
            return 0;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return -1;
        }

    }

    @TestVisible private list<Assessment__c> createAssessments(list<Account> accountsToCreateFor){

        list<Assessment__c> returnList = new list<Assessment__c>();
        for(Account curAcc : accountsToCreateFor){
            returnList.add(createAssessmentFromMaster(curAcc));
        }
        return returnList;
    }

    @TestVisible private list<Assessment__c> createAssessments(list<UtilitiesWrappers.AccountWrapper> accountWrappersToCreateFor){

        list<Assessment__c> returnList = new list<Assessment__c>();
        for(UtilitiesWrappers.AccountWrapper curAccWrap : accountWrappersToCreateFor){
            if(curAccWrap.IsSelected){
                returnList.add(createAssessmentFromMaster(curAccWrap.TheAccount));
            }
        }
        return returnList;
    }
    @TestVisible private Assessment__c createAssessmentFromMaster(Account acc){

        Assessment__c assessment = new Assessment__c();
        assessment.Designation__c = this.MasterAssessment.Designation__c;
        assessment.Assessment_Date__c = this.MasterAssessment.Assessment_Date__c;
        assessment.Assessed_Amount__c = this.MasterAssessment.Assessed_Amount__c;
        assessment.Description__c = this.MasterAssessment.Description__c;
        assessment.Account__c = acc.Id;
        return assessment;
    }

    @TestVisible private set<String> getAccountIdsFromContacts(list<Contact> contacts){
        set<String> returnSet = new set<String>();
        for(Contact c : contacts){
            if(!String.isEmpty(c.AccountId)){
                returnSet.add(c.AccountId);
            }
        }
        return returnSet;
    }

    @TestVisible private set<String> getAccountIdsFromAssessments(list<Assessment__c> assessments){
        set<String> returnSet = new set<String>();
        for(Assessment__c curAssessment : assessments){
            if(!String.isEmpty(curAssessment.Account__c)){
                returnSet.add(curAssessment.Account__c);
            }
        }
        return returnSet;
    }

    @TestVisible private list<UtilitiesWrappers.AccountWrapper> createWrappers(list<Account> accounts){
        list<UtilitiesWrappers.AccountWrapper> returnList = new list<UtilitiesWrappers.AccountWrapper>();
        for(Account curAccount: accounts){
            UtilitiesWrappers.AccountWrapper curWrap = new UtilitiesWrappers.AccountWrapper();
            curWrap.TheAccount = curAccount;
            returnList.add(curWrap);
        }
        return returnList;
    }
}