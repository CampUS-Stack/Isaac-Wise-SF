/**
 *  @author: Chris Gibson
 *  @last_modified_date: 06.25.2019
 *
 *  @description: This class handles logic for exporting assessment records into GL records to be consumed by SAGE.
 */

public with sharing class ExportController_Assessments {

    private static final String ASSESSMENT_SOQL_FIELDS = 'ID,Name,Assessed_Amount__c,Assessment_Date__c,' +
            'Designation__r.Income_GL_Account_Number__c,Designation__r.AR_GL_Account_Number__c,' +
            'Designation__r.Name, Account__r.Name,Status__c';

    public string AssessmentHeader { get; set; }
    public string Filetype { get; set; }
    public boolean isExcel { get; set; }
    public boolean isCsv { get; set; }

    public List<UtilitiesExport.ExportWrapper> AssessmentExportWrappers{ get; set; }
    public list<AssessmentWrapper> AssessmentSelectionWrappers {get; set;}
    public map<String,UtilitiesExport.ExportWrapper> WrappersByDesignationId{get; set;}

    public class AssessmentWrapper{
        public Assessment__c Assessment {get; set;}
        public Boolean IsSelected {get; set;}
        public AssessmentWrapper(){
            IsSelected = false;
        }
    }

    public Decimal TotalAssessmentAmountSelected{
        get{
            if(AssessmentSelectionWrappers == null){
                return 0.00;
            }

            Decimal returnDecimal = 0.00;
            for(AssessmentWrapper curWrap : AssessmentSelectionWrappers){
                if(curWrap.Assessment != null && curWrap.Assessment.Assessed_Amount__c != null && curWrap.IsSelected)
                    returnDecimal += curWrap.Assessment.Assessed_Amount__c;
            }
            return returnDecimal;
        }
    }

    public Integer TotalNumberOfAssessmentSelected{
        get{
            if(AssessmentSelectionWrappers == null){
                return 0;
            }

            Integer returnInteger = 0;
            for(AssessmentWrapper curWrap : AssessmentSelectionWrappers){
                if(curWrap.Assessment != null && curWrap.Assessment.Assessed_Amount__c != null && curWrap.IsSelected)
                    returnInteger++;
            }
            return returnInteger;
        }
    }

    public Integer NumberOfUnTransferredAssessments{
        get{
            if(AssessmentSelectionWrappers == null){
                return 0;
            }
            else{
                return AssessmentSelectionWrappers.size();
            }
        }
    }

    public ExportController_Assessments() {
        Filetype = '.csv';
        AssessmentExportWrappers = new List<UtilitiesExport.ExportWrapper>();
        AssessmentSelectionWrappers = new List<AssessmentWrapper>();
        this.WrappersByDesignationId = new map<String,UtilitiesExport.ExportWrapper>();

        AssessmentHeader = 'Action Date,Reference,Number of Distributions,G/L Account,Description,Amount,Recur Number,Recur Frequency\r\n';
        SearchForAssessments();
    }

    public PageReference SearchForAssessments(){
        this.AssessmentSelectionWrappers = createAssessmentSelectionWrappersToDisplay();
        return null;
    }

    public PageReference GoToExportAssessmentsPage(){

        PageReference pr = Page.ExportAssessments;
        return pr;
    }

    public PageReference SelectAllAssessments(){

        if(AssessmentSelectionWrappers == null){
            return null;
        }

        for(AssessmentWrapper curWrap : AssessmentSelectionWrappers){
            curWrap.IsSelected = true;
        }

        return null;
    }

    @testVisible private list<AssessmentWrapper> createAssessmentSelectionWrappersToDisplay(){
        try{
            list<AssessmentWrapper> returnList = new list<AssessmentWrapper>();
            String soql = 'SELECT ' + ASSESSMENT_SOQL_FIELDS + ' FROM Assessment__c WHERE Status__c = \'' + ConstantsFinancials.UN_TRANSFERED_STATUS +'\' AND Assessed_Amount__c != 0 AND Assessed_Amount__c != null AND Is_Credit_Assessment__c = false ';

            soql += 'ORDER BY Designation__c LIMIT 1000 ';
            system.debug('Printing SOQL Statement:');
            system.debug(soql);
            list<Assessment__c> assessmentsToDisplay = Database.query(soql);
            for(Assessment__c curAssessment : assessmentsToDisplay){
                AssessmentWrapper wrap = new AssessmentWrapper();
                wrap.Assessment = curAssessment;
                returnList.add(wrap);
            }
            return returnList;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return null;
        }
    }

    @TestVisible private set<Id> getSelectedAssessmentIds(){

        set<Id> returnSet = new set<Id>();
        for(AssessmentWrapper curAssessWrap : this.AssessmentSelectionWrappers){
            if(curAssessWrap.IsSelected)
                returnSet.add(curAssessWrap.Assessment.Id);
        }
        return returnSet;
    }

    public void ExportAssessmentsToExcel(){

        set<Id> selectedAssessmentIds = getSelectedAssessmentIds();
        String soql = 'SELECT ' + ASSESSMENT_SOQL_FIELDS + ' FROM Assessment__c WHERE Status__c = \'' + ConstantsFinancials.UN_TRANSFERED_STATUS + '\' AND Id IN :selectedAssessmentIds AND Is_Credit_Assessment__c = false limit 999';
        list<Assessment__c> theAssessments = Database.query(soql);

        set<Id> assessmentIds = new set<Id>();
        map<Date,list<Assessment__c>> assessmentsByDate = getAssessmentsByDateMap(theAssessments);

        for(Date curDateKey : assessmentsByDate.keySet()){
            list<Assessment__c> assessments = assessmentsByDate.get(curDateKey);
            if(assessments.size() == 0){
                continue;
            }

            map<String,list<Assessment__c>> incomeGLAssessments = new map<String,list<Assessment__c>>();
            map<String,list<Assessment__c>> arGLAssessments = new map<String,list<Assessment__c>>();
            for(Assessment__c curAssessment : assessments){

                assessmentIds.add(curAssessment.Id);
                if(!String.isEmpty(curAssessment.Designation__r.Income_GL_Account_Number__c)){
                    if(incomeGLAssessments.containsKey(curAssessment.Designation__r.Income_GL_Account_Number__c)){
                        incomeGLAssessments.get(curAssessment.Designation__r.Income_GL_Account_Number__c).add(curAssessment);
                    }
                    else{
                        incomeGLAssessments.put(curAssessment.Designation__r.Income_GL_Account_Number__c,new list<Assessment__c>{curAssessment});
                    }
                }
                if(!String.isEmpty(curAssessment.Designation__r.AR_GL_Account_Number__c)){
                    if(arGLAssessments.containsKey(curAssessment.Designation__r.AR_GL_Account_Number__c)){
                        arGLAssessments.get(curAssessment.Designation__r.AR_GL_Account_Number__c).add(curAssessment);
                    }
                    else{
                        arGLAssessments.put(curAssessment.Designation__r.AR_GL_Account_Number__c,new list<Assessment__c>{curAssessment});
                    }
                }
            }

            Integer total = incomeGLAssessments.keySet().size() + arGLAssessments.keySet().size();
            for(String curGLKey: incomeGLAssessments.keySet()){
                Decimal totalIncomeAssessmentAmount = 0.00;
                list<Assessment__c> theCurAssessments = incomeGLAssessments.get(curGLKey);
                for(Assessment__c curAss : theCurAssessments){
                    totalIncomeAssessmentAmount += curAss.Assessed_Amount__c;
                }
                UtilitiesExport.ExportWrapper ew1 = createExportWrapper(curDateKey,'SFI-'+curDateKey.format(),total,totalIncomeAssessmentAmount*-1,curGLKey,UtilitiesFinancials.getGLCodeDescription(curGLKey));
                AssessmentExportWrappers.add(ew1);
            }
            for(String curGLKey: arGLAssessments.keySet()){
                Decimal totalARAssessmentAmount = 0.00;
                list<Assessment__c> theCurAssessments = arGLAssessments.get(curGLKey);
                for(Assessment__c curAss : theCurAssessments){
                    totalARAssessmentAmount += curAss.Assessed_Amount__c;
                }
                UtilitiesExport.ExportWrapper ew2 = createExportWrapper(curDateKey,'SFI-'+curDateKey.format(),total,totalARAssessmentAmount,curGLKey,UtilitiesFinancials.getGLCodeDescription(curGLKey));
                AssessmentExportWrappers.add(ew2);
            }


        }

        updateAssessmentsWithStatus(assessmentIds);

//        PageReference pr = Page.FinancialsHome;
//        pr.setRedirect(true);
//        return pr;
    }


    @TestVisible private map<Date,list<Assessment__c>> getAssessmentsByDateMap(list<Assessment__c> assessments){

        map<Date,list<Assessment__c>> returnMap = new map<Date,list<Assessment__c>>();
        for(Assessment__c curAssessment : assessments){
            if(curAssessment.Assessment_Date__c == null){
                continue;
            }

            if(returnMap.containsKey(curAssessment.Assessment_Date__c)){
                returnMap.get(curAssessment.Assessment_Date__c).add(curAssessment);
            }else{
                returnMap.put(curAssessment.Assessment_Date__c,new list<Assessment__c>{curAssessment});
            }
        }
        return returnMap;
    }

    @TestVisible private map<String,list<Assessment__c>> getAssessmentsByDesignationMap(list<Assessment__c> assessments){

        map<String,list<Assessment__c>> returnMap = new map<String,list<Assessment__c>>();
        for(Assessment__c curAssessment : assessments){
            if(curAssessment.Assessment_Date__c ==  null || String.isEmpty(curAssessment.Designation__c)){
                continue;
            }

            if(returnMap.containsKey(String.valueOf(curAssessment.Assessment_Date__c) + curAssessment.Designation__c)){
                returnMap.get(String.valueOf(curAssessment.Assessment_Date__c) + curAssessment.Designation__c).add(curAssessment);
            }else{
                returnMap.put(String.valueOf(curAssessment.Assessment_Date__c) + curAssessment.Designation__c,new list<Assessment__c>{curAssessment});
            }
        }
        return returnMap;
    }


    @TestVisible private UtilitiesExport.ExportWrapper createExportWrapper(Date checkDate,String referenceNum,Integer allocSize,Decimal paymentAmount,String glAccount,String designationName){

        if(!String.isEmpty(designationName)){
//            throw new CustomExceptions.GLAccountNameException('There is a GL Account that does not have a name.');
//            return null;
        }

        UtilitiesExport.ExportWrapper ew = new UtilitiesExport.ExportWrapper();
        ew.Amount = String.valueOf(paymentAmount);

        if(checkDate != null){
            ew.ActionDate = checkDate.format();
        }

        ew.NumberOfDistributions = String.valueOf(allocSize);
        ew.GLAccount = glAccount;
        ew.ReferenceNumber = referenceNum;
        ew.Description = designationName;
        ew.RecurFrequency = '0';
        ew.RecurNumber = '0';

        return ew;
    }

    @Future
    @TestVisible private static void updatePaymentAdjustmentsWithStatus(set<Id> paymentAdjustmentIds){

        try{
            list<Payment_Adjustment__c> paymentAdjustments = [SELECT Id,Status__c FROM Payment_Adjustment__c WHERE Id in :paymentAdjustmentIds];
            for(Payment_Adjustment__c curPA : paymentAdjustments){
                curPA.Status__c = 'Transferred';
            }

            if(paymentAdjustments.size() > 0){
                update paymentAdjustments;
            }
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
        }
        catch(DmlException de){
            system.debug(de.getMessage());
        }
    }



    @Future
    @TestVisible private static void updateAssessmentsWithStatus(set<Id> assessmentIds){

        try{
            list<Assessment__c> assessments = [SELECT Id,Status__c FROM Assessment__c WHERE Id in :assessmentIds];
            for(Assessment__c curAssess : assessments){
                curAssess.Status__c = 'Transferred';
            }

            if(assessments.size() > 0){
                update assessments;
            }
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
        }
        catch(DmlException de){
            system.debug(de.getMessage());
        }
    }

    @TestVisible private list<Payment_Adjustment_Allocation__c> getPaymentAllocations(String status){
        try{
            list<Payment_Adjustment_Allocation__c> paymentAdjustmentAllocation = [SELECT Id,Payment_Adjustment__r.Date_of_Action__c FROM Payment_Adjustment_Allocation__c WHERE Payment_Status__c = :status];
            return paymentAdjustmentAllocation;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return null;
        }
    }

    @TestVisible private set<Id> getDesignationIdsFromAggResult(list<AggregateResult> aggResults){

        set<Id> returnSet = new set<Id>();
        for(AggregateResult ar : aggResults){
            returnSet.add(String.valueOf(ar.get('des')));
        }
        return returnSet;

    }

    @TestVisible private list<Designation__c> getDesignations(set<Id> designationIds){

        try{
            list<Designation__c> returnDesignations = [SELECT ID,A_R_GL_Account__c,Name,Cash_Account__c,Income_GL_Account__c,AR_GL_Account_Number__c,Income_GL_Account_Number__c,Cash_Account_GL_Number__c FROM Designation__c WHERE Id in :designationIds];
            return returnDesignations;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return null;
        }
    }


}