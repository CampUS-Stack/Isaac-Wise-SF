/**
 * Created by Kritik Garg on 16-02-2019.
 */

public with sharing class CongrComm_FairShareController {

    //public static String CURRENT_FISCAL_YEAR = '2024-2025';
    //public static String PRIOR_FISCAL_YEAR = '2023-2024';
    public static String CURRENT_FISCAL_YEAR { get; set; }
    public static String PRIOR_FISCAL_YEAR { get; set; }
    @TestVisible private Contact communityUserContact { get; set; }
    public Fair_Share__c fairShare { get; set; }

    public CongrComm_FairShareController() {

        CURRENT_FISCAL_YEAR = getOrgCurrentFiscalYear();
        PRIOR_FISCAL_YEAR = getOrgPriorFiscalYear(CURRENT_FISCAL_YEAR);

        System.debug('CURRENT_FISCAL_YEAR : ' + CURRENT_FISCAL_YEAR);
        System.debug('PRIOR_FISCAL_YEAR : ' + PRIOR_FISCAL_YEAR);

        this.communityUserContact = UtilitiesUsers.GetContactForCommunityUser(UserInfo.getUserId());
        fairShare = this.getFairShareRecord(UserInfo.getUserId(),CURRENT_FISCAL_YEAR);
    }

    public static String getOrgCurrentFiscalYear(){
        List<Org_Fiscal_Year__mdt> orgFiscalYearList = [SELECT Label, Current_Fiscal_Year__c FROM Org_Fiscal_Year__mdt WHERE Label = 'Default' LIMIT 1];
        if(orgFiscalYearList.size() > 0){
            Org_Fiscal_Year__mdt orgFiscalYear = orgFiscalYearList[0];
            if(orgFiscalYear.Current_Fiscal_Year__c == null){
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Current Fiscal Year not found from the custom metadata type \'Org Fiscal Years\'.');
                ApexPages.addMessage(myMsg);
                return null;
            }
            return orgFiscalYear.Current_Fiscal_Year__c;
        }else{
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'The record labeled as \'Default\' was not found in the custom metadata type \'Org Fiscal Years\'.');
            ApexPages.addMessage(myMsg);
            return null;
        }
    }

    public static String getOrgPriorFiscalYear(String currentFiscalYear){
        if(currentFiscalYear == null){
            return null;
        }
        List<String> fiscalYearStings = currentFiscalYear.split('-');
        Integer currentYear = Integer.valueOf(fiscalYearStings.get(0));
        Integer priorYear = currentYear - 1;
        String priorFiscalYear = priorYear + '-' + currentYear;
        return priorFiscalYear;
    }

    @TestVisible private Fair_Share__c getFairShareRecord(String portalUserId, String fiscalYear) {
        try {
            Account portalUserAccount = [SELECT Id From Account WHERE Id IN (SELECT AccountId FROM User WHERE Id = :portalUserId)];
            Fair_Share__c fairShare = [
                    SELECT Id, Account__c, PST__c, Membership_Contribution__c, Fiscal_Year__c,
                            Last_Year_Fair_Share__c,Last_Year_Contribution_Total__c,Last_Year_PST_Amount__c,
                            Last_Year_Membership_Amount__c,Member_Comments__c
                    FROM Fair_Share__c
                    WHERE Fiscal_Year__c = :fiscalYear AND Account__c = :portalUserAccount.Id
            ];
            return fairShare;
        } catch (QueryException qe) {
            System.debug(qe.getMessage());
            Fair_Share__c fsToReturn = new Fair_Share__c();
            fsToReturn.Account__c = this.communityUserContact.AccountId;
            fsToReturn.PST__c = 150;
            fsToReturn.Fiscal_Year__c = fiscalYear;
            return fsToReturn;
        }
    }

    public PageReference saveFairShare() {
//        if(this.fairShare.Membership_Contribution__c == null || this.fairShare.Membership_Contribution__c ==0) {
//            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Membership Contribution is required');
//            ApexPages.addMessage(myMsg);
//            return null;
//        }
        try {
            upsert fairShare;
        } catch (Exception e) {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage());
            ApexPages.addMessage(myMsg);
            return null;
        }
        PageReference pr = Page.CongrComm_FairShareThanks;
        return pr;
    }

}