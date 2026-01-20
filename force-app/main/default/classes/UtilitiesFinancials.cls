/**
 * Created by Chris Home Desktop on 10/11/2017.
 */

public without sharing class UtilitiesFinancials {

    @TestVisible private static final String SOQL_SELECT = 'SELECT ';
    @TestVisible private static final String SOQL_FIELDS = 'Id';
    @TestVisible private static final String SOQL_FROM = ' FROM Payment_Adjustment__c ';
    @TestVisible private static final String SOQL_DEFAULT_QUERY_START = 'SELECT ' + SOQL_FIELDS + SOQL_FROM;


    // Build a local cache so that we don't request this multiple times
    private static Map<String,GL_Code__c> glCodeCache;

    static {
        glCodeCache = new Map<String,GL_Code__c>();
    }

    public static String getGLCodeDescription(String glCode){

        // Do we already have a result?
        if(String.isEmpty(glCode)){
            return 'NameNotFound';
        }

        if(glCodeCache != null && glCodeCache.containsKey(glCode)){
            return glCodeCache.get(glCode).Name;
        }

        try{
            list<GL_Code__c> glCodes = [SELECT Id,GL_Code__c,Name FROM GL_Code__c limit 2000];
            for (GL_Code__c curGL : glCodes) {
                glCodeCache.put(curGL.GL_Code__c,curGL);
            }
            if(glCodeCache.containsKey(glCode)){
                return glCodeCache.get(glCode).Name;
            }
            else{
                return 'NameNotFound';
            }
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return 'NameNotFound';
        }
    }


    public static list<Assessment__c> GetAssessmentsWithRemainingBalance(String accountId,String assessmentSOQLFields){

        try{
            String soql = 'SELECT '
                    + assessmentSOQLFields
                    + ' FROM Assessment__c WHERE Account__c = :accountId AND Is_Credit_Assessment__c = FALSE AND Remaining_Balance__c > 0  AND (RecordTypeId = \''
                    + UtilitiesSObject.getRecordTypeId('Assessment',Assessment__c.SObjectType)
                    + '\' OR RecordTypeId = \'' + UtilitiesSObject.getRecordTypeId('Event_Assessment',Assessment__c.SObjectType) + '\') ';
            list<Assessment__c> returnAssessments = Database.query(soql);
            return returnAssessments;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return null;
        }
    }
    public static list<Assessment__c> GetCreditAssessmentsWithRemainingBalance(String accountId,String assessmentSOQLFields){

        try{
            String soql = 'SELECT ' + assessmentSOQLFields + ' FROM Assessment__c WHERE Account__c = :accountId AND Remaining_Balance__c > 0  AND RecordTypeId = \'' + UtilitiesSObject.getRecordTypeId('Credit_Assessment',Assessment__c.SObjectType) + '\'';
            list<Assessment__c> returnAssessments = Database.query(soql);
            return returnAssessments;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return null;
        }
    }

    public static list<UtilitiesWrappers.AssessmentWrapper> GetAssessmentWrappers(String accountId,String assessmentSOQLFields,String schedPaymentSOQLFields){

        list<Assessment__c> assessments = GetAssessmentsWithRemainingBalance(accountId,assessmentSOQLFields);

        if(assessments == null){
            return null;
        }

        list<UtilitiesWrappers.AssessmentWrapper> wrappers = UtilitiesWrappers.CreateAssessmentWrappers(assessments,schedPaymentSOQLFields);

        return wrappers;
    }

    public static list<Payment_Adjustment__c> GetPaymentAdjustmentsByStatus(String status){
        try{
            String soql = SOQL_DEFAULT_QUERY_START;
            list<Payment_Adjustment__c> paymentAdjustmentAllocation = Database.query(soql);
            return paymentAdjustmentAllocation;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return null;
        }
    }



    public static Boolean UpdatePaymentBridgesWebsiteValues(list<Payment_Adjustment_Allocation__c> paymentAdjustmentAllocations){

        for(Payment_Adjustment_Allocation__c curAlloc : paymentAdjustmentAllocations){
            curAlloc.From_Website__c = true;
            curAlloc.Incomplete_Payment__c = true;
        }

        try{
            update paymentAdjustmentAllocations;
            return true;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return false;
        }
    }

    public static map<Id,list<Scheduled_Payment__c>> MapSchedulePaymentsByAssessments(set<Id> assessmentIds,String schedPaymentSOQLFields){

        try{
            map<Id,list<Scheduled_Payment__c>> returnMap = new map<Id,list<Scheduled_Payment__c>>();
            list<Scheduled_Payment__c> scheduledPayments = UtilitiesFinancials.GetScheduledPayment(schedPaymentSOQLFields,assessmentIds);

            for(Scheduled_Payment__c curSP : scheduledPayments){

                if(returnMap.containsKey(curSP.Assessment__c)){
                    returnMap.get(curSP.Assessment__c).add(curSP);
                }
                else{
                    list<Scheduled_Payment__c> spList = new list<Scheduled_Payment__c>();
                    spList.add(curSP);
                    returnMap.put(curSP.Assessment__c,spList);
                }
            }

            return returnMap;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return null;
        }
    }

    public static list<Scheduled_Payment__c> GetScheduledPayment(String soqlFields, set<Id> assessmentIds){

        try{
            String soql = 'SELECT ' + soqlFields + ' FROM Scheduled_Payment__c WHERE Assessment__c in :assessmentIds';
            list<Scheduled_Payment__c> returnSPayments = Database.query(soql);
            return returnSPayments;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return null;
        }
    }


    public static Boolean ProcessAutoPay(Payment_Adjustment__c paymentAdjustment,list<UtilitiesWrappers.AssessmentWrapper> assessments){

        if(paymentAdjustment.Amount__c == 0){
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.WARNING,'Please specify a current payment amount'));
            return false;
        }
        if(assessments == null){
            return false;
        }

        Decimal paymentAmount = paymentAdjustment.Amount__c;

        if(paymentAmount == null){
            return false;
        }

        for(UtilitiesWrappers.AssessmentWrapper curWrap : assessments){

            if(curWrap.assessment.Assessed_Amount__c == null){
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.WARNING,'Please specify an amount for the new Assessment.'));
                return false;
            }

            if(paymentAmount <= 0){
                break;
            }

            if(paymentAmount > curWrap.assessment.Remaining_Balance__c){
                curWrap.paymentAmount = String.valueOf(curWrap.assessment.Remaining_Balance__c);
                paymentAmount = paymentAmount - curWrap.assessment.Remaining_Balance__c;
            }
            else{
                curWrap.paymentAmount = String.valueOf(paymentAmount);
                paymentAmount = paymentAmount - curWrap.assessment.Remaining_Balance__c;
            }
        }


        return true;
    }


}