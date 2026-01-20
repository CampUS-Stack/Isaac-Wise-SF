/**
 * Created by Chris Home Desktop on 10/11/2017.
 */

public with sharing class ExportController {


    private static final String PAYMENT_ALLOCATION_SOQL_FIELDS = 'ID,Amount__c,Payment_Adjustment__r.Check_Date__c,' +
            'Scheduled_Payment__r.Designation__r.Income_GL_Account__c,' +
            'Scheduled_Payment__r.Designation__r.A_R_GL_Account__c,Batch__r.Deposit_ID__c,' +
            'Payment_Adjustment__r.Batch__r.Batch_Date__c,Payment_Adjustment__r.Batch__r.Deposit_ID__c,' +
            'Scheduled_Payment__r.Designation__r.Name,Scheduled_Payment__r.Assessment__r.Designation__c,Payment_Adjustment__r.Cash_Override_Account__c,' +
            'Payment_Adjustment__r.Source_Credit_Assessment__c,Payment_Adjustment__r.Source_Credit_Assessment__r.Designation__r.Name,Payment_Adjustment__r.Source_Credit_Assessment__r.Designation__r.AR_GL_Account__r.GL_Code__c,' +
            'Payment_Adjustment__r.Source_Credit_Assessment__r.Designation__c,Payment_Adjustment__r.Source_Credit_Assessment__r.Designation__r.AR_GL_Account__c';
    private static final String ASSESSMENT_SOQL_FIELDS = 'ID,Assessed_Amount__c,Assessment_Date__c,' +
            'Designation__r.Income_GL_Account_Number__c,Designation__r.AR_GL_Account_Number__c,' +
            'Designation__r.Name';

    private static final String OPERATING_GL_ACCOUNT_CODE = '11101-00';
    private static final String OPERATING_ACCOUNT_NAME = 'Operating Acct - PNC';

    public String SelectedDepositId {get; set;}
    public string header { get; set; }
    public string AssessmentHeader { get; set; }

    public map<String,ExportWrapper> WrappersByDesignationId{get; set;}
    public List<ExportWrapper> lstwrapper { get; set; }
    public List<ExportWrapper> AssessmentWrappers { get; set; }

    public class ExportWrapper {
        public string ActionDate { get; set; }
        public string ReferenceNumber { get; set; }
        public string NumberOfDistributions { get; set; }
        public string GLAccount { get; set; }
        public string Description { get; set; }
        public string Amount { get; set; }
        public string RecurNumber { get; set; }
        public string RecurFrequency { get; set; }
    }

    public class PaymentWrapper{
        public Payment_Adjustment__c Payment {get; set;}
        public Boolean IsSelected {get; set;}
        public PaymentWrapper(){
            IsSelected = false;
        }
    }

    public Decimal TotalPaymentAmountSelected{
        get{
            if(PaymentWrappers == null){
                return 0.00;
            }

            Decimal returnDecimal = 0.00;
            for(PaymentWrapper curWrap : PaymentWrappers){
                if(curWrap.Payment != null && curWrap.Payment.Amount__c != null && curWrap.IsSelected)
                    returnDecimal += curWrap.Payment.Amount__c;
            }
            return returnDecimal;
        }
    }

    public Integer NumberOfUnTransferredPayments{
        get{
            if(PaymentWrappers == null){
                return 0;
            }
            else{
                return PaymentWrappers.size();
            }
        }
    }

    public list<PaymentWrapper> PaymentWrappers {get; set;}

    public string Filetype { get; set; }
    public boolean isExcel { get; set; }
    public boolean isCsv { get; set; }

    public ExportController() {
        Filetype = '.csv';
        lstwrapper = new List<ExportWrapper>();
        AssessmentWrappers = new List<ExportWrapper>();
        SelectedDepositId = '';
        this.WrappersByDesignationId = new map<String,ExportWrapper>();

        header = 'Action Date,Reference,Number of Distributions,G/L Account,Description,Amount,Recur Number,Recur Frequency\r\n';
        AssessmentHeader = 'Action Date,Reference,Number of Distributions,G/L Account,Description,Amount,Recur Number,Recur Frequency\r\n';
        SearchForPayments();
    }

    public PageReference SearchForPayments(){
        this.PaymentWrappers = getPaymentWrappersToDisplay();
        return null;
    }

    public list<PaymentWrapper> getPaymentWrappersToDisplay(){
        try{
            list<PaymentWrapper> returnList = new list<PaymentWrapper>();
            String soql = 'SELECT Id,Name,Household__r.Name,Deposit_ID__c,Status__c,Amount__c FROM Payment_Adjustment__c WHERE Status__c = \'' + ConstantsFinancials.UN_TRANSFERED_STATUS +'\' AND Amount__c != 0';

            if(String.isNotBlank(SelectedDepositId)){
                soql += ' AND Batch__r.Deposit_ID__c = \'' + SelectedDepositId + '\' ';
            }
            soql += 'ORDER BY Deposit_ID__c';
            list<Payment_Adjustment__c> paymentsToDisplay = Database.query(soql);
            for(Payment_Adjustment__c curPayment : paymentsToDisplay){
                PaymentWrapper wrap = new PaymentWrapper();
                wrap.Payment = curPayment;
                returnList.add(wrap);
            }
            return returnList;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return null;
        }
    }

    public list<SelectOption> GetDepositIds(){

        try{
            list<SelectOption> returnList = new list<SelectOption>();
            returnList.add(new SelectOption('','--NONE--'));
            list<Payment_Adjustment__c> payments = [SELECT Id,Batch__r.Deposit_ID__c FROM Payment_Adjustment__c WHERE Status__c = 'Un-Transferred'];

            set<String> depositIds = new set<String>();
            for(Payment_Adjustment__c curPA : payments){
                if(String.isNotBlank(curPA.Batch__r.Deposit_ID__c)){
                    if(!depositIds.contains(curPA.Batch__r.Deposit_ID__c)){
                        depositIds.add(curPA.Batch__r.Deposit_ID__c);
                        returnList.add(new SelectOption(curPA.Batch__r.Deposit_ID__c,curPA.Batch__r.Deposit_ID__c));
                    }
                }
            }
            return returnList;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return new list<SelectOption>();
        }
    }

    public PageReference exportPaymentsToExcel(){

        try{

            set<Id> paymentIds = getSelectedPaymentIds();

            list<ExportWrapper> paymentExportWrappers = getExportWrapperForPaymentIds('Payment',paymentIds);
            list<ExportWrapper> adjustmentExportWrappers = getExportWrapperForPaymentIds('Adjustment',paymentIds);
            list<ExportWrapper> voidExportWrappers = getExportWrapperForPaymentIds('Void',paymentIds);
            list<ExportWrapper> creditExportWrappers = getExportWrapperForPaymentIds('Credit',paymentIds);

            lstwrapper.addAll(paymentExportWrappers);
            lstwrapper.addAll(adjustmentExportWrappers);
            lstwrapper.addAll(voidExportWrappers);
            lstwrapper.addAll(creditExportWrappers);

        }
        catch(CustomExceptions.GLAccountNameException glane){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,'There is a GL Number that does not have a name. Please contact an administrator and check the GL Account Custom Setting.'));
            return null;
        }


        return null;

    }

    public PageReference GoToExportPaymentPage(){

        PageReference pr = Page.ExportPayments;
        return pr;
    }

    public PageReference SelectAllPayments(){

        if(PaymentWrappers == null){
            return null;
        }

        for(PaymentWrapper curWrap : PaymentWrappers){
            curWrap.IsSelected = true;
        }

        return null;
    }

    @TestVisible private set<Id> getSelectedPaymentIds(){

        set<Id> paymentIds = new set<Id>();
        for(PaymentWrapper curPayWrap : this.PaymentWrappers){
            if(curPayWrap.IsSelected)
                paymentIds.add(curPayWrap.Payment.Id);
        }
        return paymentIds;
    }

    @TestVisible private list<ExportWrapper> getUnTransferredExportWrapper(String exportWrapperType){

        list<ExportWrapper> returnList = new list<ExportWrapper>();
        UtilitiesCustomSetting settingCntrl = UtilitiesCustomSetting.GetInstance();

        String rTypeId = UtilitiesSObject.getRecordTypeId(exportWrapperType,Payment_Adjustment__c.SObjectType);
        String soql = 'SELECT ' + PAYMENT_ALLOCATION_SOQL_FIELDS + ' FROM Payment_Adjustment_Allocation__c WHERE Payment_Status__c = \'' + ConstantsFinancials.UN_TRANSFERED_STATUS + '\' AND Payment_Adjustment__r.RecordTypeId = :rTypeId AND Payment_Adjustment__r.Batch__c != null limit 999';
        list<Payment_Adjustment_Allocation__c> paymentAdjustmentAllocations = Database.query(soql);

        set<Id> paymentAdjustmentIds = new set<Id>();
        map<String,list<Payment_Adjustment_Allocation__c>> allocationsByDepositId = new map<String,list<Payment_Adjustment_Allocation__c>>();
        map<String,list<Payment_Adjustment_Allocation__c>> allocationsByDesignation = new map<String,list<Payment_Adjustment_Allocation__c>>();
        map<String,list<Id>> designationIdsByBatchID = new map<String,list<Id>>();
        map<Id,Assessment__c> creditAssessmentsByIds = new map<Id,Assessment__c>();
        set<Id> allDesignationIds = new set<Id>();

        for(Payment_Adjustment_Allocation__c curAllocation : paymentAdjustmentAllocations){

            populateDepositIdMap(allocationsByDepositId,curAllocation);
            populateDesignationListForBatches(designationIdsByBatchID,curAllocation);
            populateDesignationMap(allocationsByDesignation,curAllocation);
            paymentAdjustmentIds.add(curAllocation.Payment_Adjustment__c);

            if(curAllocation.Payment_Adjustment__r.Batch__r.Deposit_ID__c != null && designationIdsByBatchID.containsKey(curAllocation.Payment_Adjustment__r.Batch__r.Deposit_ID__c)){
                allDesignationIds.addAll(designationIdsByBatchID.get(curAllocation.Payment_Adjustment__r.Batch__r.Deposit_ID__c));
            }

        }

        returnList = createExportWrappers(exportWrapperType,allDesignationIds,allocationsByDesignation,designationIdsByBatchID);

        updatePaymentAdjustmentsWithStatus(paymentAdjustmentIds);

        for(ExportWrapper curWrap : returnList){
            system.debug(curWrap);
        }

        return returnList;
    }


    @TestVisible private list<ExportWrapper> getExportWrapperForPaymentIds(String exportWrapperType,set<Id> paymentIds){

        list<ExportWrapper> returnList = new list<ExportWrapper>();
        UtilitiesCustomSetting settingCntrl = UtilitiesCustomSetting.GetInstance();

        String rTypeId = UtilitiesSObject.getRecordTypeId(exportWrapperType,Payment_Adjustment__c.SObjectType);
        String soql = 'SELECT ' + PAYMENT_ALLOCATION_SOQL_FIELDS + ' FROM Payment_Adjustment_Allocation__c WHERE Payment_Status__c = \'' + ConstantsFinancials.UN_TRANSFERED_STATUS + '\' AND Payment_Adjustment__c in :paymentIds AND Payment_Adjustment__r.RecordTypeId = :rTypeId AND Payment_Adjustment__r.Batch__c != null limit 999';
        list<Payment_Adjustment_Allocation__c> paymentAdjustmentAllocations = Database.query(soql);

        set<Id> paymentAdjustmentIds = new set<Id>();
        map<String,list<Payment_Adjustment_Allocation__c>> allocationsByDepositId = new map<String,list<Payment_Adjustment_Allocation__c>>();
        map<String,list<Payment_Adjustment_Allocation__c>> allocationsByDesignation = new map<String,list<Payment_Adjustment_Allocation__c>>();
        map<String,list<Id>> designationIdsByBatchID = new map<String,list<Id>>();
        set<Id> allDesignationIds = new set<Id>();
        for(Payment_Adjustment_Allocation__c curAllocation : paymentAdjustmentAllocations){

            populateDepositIdMap(allocationsByDepositId,curAllocation);
            populateDesignationListForBatches(designationIdsByBatchID,curAllocation);
            populateDesignationMap(allocationsByDesignation,curAllocation);
            paymentAdjustmentIds.add(curAllocation.Payment_Adjustment__c);
            if(curAllocation.Payment_Adjustment__r.Batch__r.Deposit_ID__c != null && designationIdsByBatchID.containsKey(curAllocation.Payment_Adjustment__r.Batch__r.Deposit_ID__c)){
                allDesignationIds.addAll(designationIdsByBatchID.get(curAllocation.Payment_Adjustment__r.Batch__r.Deposit_ID__c));
            }

        }

        returnList = createExportWrappers(exportWrapperType,allDesignationIds,allocationsByDesignation,designationIdsByBatchID);

        updatePaymentAdjustmentsWithStatus(paymentAdjustmentIds);

        for(ExportWrapper curWrap : returnList){
            system.debug(curWrap);
        }

        return returnList;
    }

    @TestVisible private list<ExportWrapper> createExportWrappers(String exportWrapperType,set<Id> allDesignationIds,map<String,list<Payment_Adjustment_Allocation__c>> allocationsByDesignation, map<String,list<Id>> designationIdsByBatchID){

        list<ExportWrapper> returnList = new list<ExportWrapper>();

        map<Id,Designation__c> designationMap = new map<Id,Designation__c>(getDesignations(allDesignationIds));
        system.debug(designationIdsByBatchID);
        for(String curKey : designationIdsByBatchID.keySet()){

            Decimal incomeAccountTotal = 0;
            Date latestDate = Date.newInstance(1970,1,1);
            set<Id> designationIds = new set<Id>(designationIdsByBatchID.get(curKey));

            system.debug(' *********   Printing Allocations for: ' + curKey);
            map<String,Decimal> paymentAmountsByGLAccount = new map<String,Decimal>();
            map<String,Decimal> paymentAmountsByGLForCredit = new map<String,Decimal>();
            map<String,Integer> distributionsByGLAccount = new map<String,Integer>();
            Integer distrbutionsForBatch = 0;
            for(Id curId : designationIds){

                list<Payment_Adjustment_Allocation__c> allocations = allocationsByDesignation.get(curKey + curId);
                if(allocations == null){
                    continue;
                }

                distrbutionsForBatch += allocations.size();

                Designation__c curDesignation = designationMap.get(curId);

                Decimal paymentAmount = 0;
                for(Payment_Adjustment_Allocation__c curAlloc : allocations){
                    system.debug(curAlloc);
                    paymentAmount += curAlloc.Amount__c;

                    if(latestDate < curAlloc.Payment_Adjustment__r.Batch__r.Batch_Date__c)
                        latestDate = curAlloc.Payment_Adjustment__r.Batch__r.Batch_Date__c;
                    if(curAlloc.Payment_Adjustment__r.Batch__r.Batch_Date__c == null)
                        latestDate = date.today();

                    if(exportWrapperType == 'Payment'){
                        if(!String.isEmpty(curAlloc.Payment_Adjustment__r.Cash_Override_Account__c)){
                            populateCashGLPaymentMap(paymentAmountsByGLAccount,curAlloc.Amount__c,curAlloc.Payment_Adjustment__r.Cash_Override_Account__c);
                            populateCashGLPaymentMap(paymentAmountsByGLAccount,curAlloc.Amount__c * -1,curDesignation.AR_GL_Account_Number__c);
                        }
                        else{
                            populateCashGLPaymentMap(paymentAmountsByGLAccount,curAlloc.Amount__c,curDesignation.Cash_Account_GL_Number__c);
                            populateCashGLPaymentMap(paymentAmountsByGLAccount,curAlloc.Amount__c * -1,curDesignation.AR_GL_Account_Number__c);
                        }
                    }
                    else if (exportWrapperType == 'Credit') {
                        /// Special scenario for credit exports. Need the same GL but multiple line items in a batch
                        /// this is in place to generate two line items that have the same amount and same GL code.
                        if(String.isNotBlank(curAlloc.Payment_Adjustment__c) && String.isNotBlank(curAlloc.Payment_Adjustment__r.Source_Credit_Assessment__c) &&
                                String.isNotBlank(curAlloc.Payment_Adjustment__r.Source_Credit_Assessment__r.Designation__c) &&
                                String.isNotBlank(curAlloc.Payment_Adjustment__r.Source_Credit_Assessment__r.Designation__r.AR_GL_Account__c) ){

                            populateCashGLPaymentMap(paymentAmountsByGLAccount,curAlloc.Amount__c,curAlloc.Payment_Adjustment__r.Source_Credit_Assessment__r.Designation__r.AR_GL_Account__r.GL_Code__c);
                            populateCashGLPaymentMap(paymentAmountsByGLAccount,curAlloc.Amount__c * -1,curDesignation.AR_GL_Account_Number__c);
//                            paymentAmountsByGLForCredit.put(curAlloc.Payment_Adjustment__r.Source_Credit_Assessment__r.Designation__r.AR_GL_Account__r.Name,curAlloc.Amount__c);
//                            paymentAmountsByGLForCredit.put(curDesignation.AR_GL_Account_Number__c,curAlloc.Amount__c);
                        }
                        //populateCashGLPaymentMap(paymentAmountsByGLAccount,curAlloc.Amount__c,curDesignation.AR_GL_Account_Number__c);
                    }
                    else if (exportWrapperType == 'Adjustment') {
                        populateCashGLPaymentMap(paymentAmountsByGLAccount,curAlloc.Amount__c * -1 ,curDesignation.Income_GL_Account_Number__c);
                        populateCashGLPaymentMap(paymentAmountsByGLAccount,curAlloc.Amount__c ,curDesignation.AR_GL_Account_Number__c);
                    }
                    else if (exportWrapperType == 'Void') {
                        if(!String.isEmpty(curAlloc.Payment_Adjustment__r.Cash_Override_Account__c)){
                            populateCashGLPaymentMap(paymentAmountsByGLAccount,curAlloc.Amount__c,curAlloc.Payment_Adjustment__r.Cash_Override_Account__c);
                            populateCashGLPaymentMap(paymentAmountsByGLAccount,curAlloc.Amount__c * -1,curDesignation.AR_GL_Account_Number__c);
                        }
                        else{
                            populateCashGLPaymentMap(paymentAmountsByGLAccount,curAlloc.Amount__c,curDesignation.Cash_Account_GL_Number__c);
                            populateCashGLPaymentMap(paymentAmountsByGLAccount,curAlloc.Amount__c * -1,curDesignation.AR_GL_Account_Number__c);
                        }
                    }
                }

                if(exportWrapperType == 'Payment'){
                    distributionsByGLAccount.put(curDesignation.Cash_Account_GL_Number__c,distrbutionsForBatch);
                    distributionsByGLAccount.put(curDesignation.AR_GL_Account_Number__c,distrbutionsForBatch);
                } else if(exportWrapperType == 'Credit'){
                    distributionsByGLAccount.put(curDesignation.AR_GL_Account_Number__c,distrbutionsForBatch);
                    distributionsByGLAccount.put(curDesignation.AR_GL_Account_Number__c,distrbutionsForBatch);
                } else if (exportWrapperType == 'Adjustment') {
                    distributionsByGLAccount.put(curDesignation.Income_GL_Account__c,distrbutionsForBatch);
                    distributionsByGLAccount.put(curDesignation.AR_GL_Account_Number__c,distrbutionsForBatch);
                } else if (exportWrapperType == 'Void') {
                    distributionsByGLAccount.put(curDesignation.Cash_Account_GL_Number__c,distrbutionsForBatch);
                    distributionsByGLAccount.put(curDesignation.AR_GL_Account_Number__c,distrbutionsForBatch);
                }
            }

            Integer batchDistribution = paymentAmountsByGLAccount.values().size();
            for(String curGL : paymentAmountsByGLAccount.keySet()) {
                Decimal payAmt = paymentAmountsByGLAccount.get(curGL);
                if (exportWrapperType == 'Payment') {
                    ExportWrapper wrap = createExportWrapper(latestDate, 'SFP' + curKey,batchDistribution, payAmt, curGL, UtilitiesFinancials.getGLCodeDescription(curGL));
                    returnList.add(wrap);
                } else if (exportWrapperType == 'Credit') {
                    ExportWrapper wrap = createExportWrapper(latestDate, 'SFP' + curKey,batchDistribution, payAmt, curGL, UtilitiesFinancials.getGLCodeDescription(curGL));
                    returnList.add(wrap);
                } else if (exportWrapperType == 'Adjustment') {
                    ExportWrapper wrap = createExportWrapper(latestDate, 'SFA' + curKey, batchDistribution, payAmt, curGL, UtilitiesFinancials.getGLCodeDescription(curGL));
                    returnList.add(wrap);
                } else if (exportWrapperType == 'Void') {
                    ExportWrapper wrap = createExportWrapper(latestDate, 'SFV' + curKey, batchDistribution, payAmt, curGL, UtilitiesFinancials.getGLCodeDescription(curGL));
                    returnList.add(wrap);
                }
            }
//
//            Integer batchDistributionForCredit = paymentAmountsByGLForCredit.values().size() * 2;
//            for(String curGL : paymentAmountsByGLForCredit.keySet()){
//
//                Decimal payAmt = paymentAmountsByGLForCredit.get(curGL);
//                ExportWrapper wrap = createExportWrapper(latestDate, 'SFP' + curKey,batchDistribution, payAmt, curGL, UtilitiesFinancials.getGLCodeDescription(curGL));
//                ExportWrapper wrap2 = createExportWrapper(latestDate, 'SFP' + curKey,batchDistribution, payAmt*-1, curGL, UtilitiesFinancials.getGLCodeDescription(curGL));
//                returnList.add(wrap);
//                returnList.add(wrap2);
//            }

        }

        return returnList;
    }

    @TestVisible private void populateCashGLPaymentMap(map<String,Decimal> paymentMap,Decimal paymentAmount,String glAccount){
        if(paymentMap.containsKey(glAccount)){
            Decimal curPayAmout = paymentMap.get(glAccount) + paymentAmount;
            paymentMap.put(glAccount,curPayAmout);
        }
        else{
            paymentMap.put(glAccount,paymentAmount);
        }
    }


    @TestVisible private void populateDesignationListForBatches(map<String,list<Id>> designationsByBatchId, Payment_Adjustment_Allocation__c curAllocation){

        if(!String.isEmpty(curAllocation.Scheduled_Payment__r.Assessment__r.Designation__c)){
            if(designationsByBatchId.containsKey(curAllocation.Payment_Adjustment__r.Batch__r.Deposit_ID__c)){
                designationsByBatchId.get(curAllocation.Payment_Adjustment__r.Batch__r.Deposit_ID__c).add(curAllocation.Scheduled_Payment__r.Assessment__r.Designation__c);
            }
            else{
                designationsByBatchId.put(curAllocation.Payment_Adjustment__r.Batch__r.Deposit_ID__c,new list<Id>{curAllocation.Scheduled_Payment__r.Assessment__r.Designation__c});
            }
        }

    }

    @TestVisible private void populateDepositIdMap(map<String,list<Payment_Adjustment_Allocation__c>> allocationsByDepositId,Payment_Adjustment_Allocation__c curAllocation){

        if(!String.isEmpty(curAllocation.Payment_Adjustment__r.Batch__r.Deposit_ID__c)){
            String keyToUse = curAllocation.Payment_Adjustment__r.Batch__r.Deposit_ID__c + curAllocation.Scheduled_Payment__r.Assessment__r.Designation__c;
            if(allocationsByDepositId.containsKey(keyToUse)){
                allocationsByDepositId.get(keyToUse).add(curAllocation);
            }
            else{
                allocationsByDepositId.put(keyToUse,new list<Payment_Adjustment_Allocation__c>{curAllocation});
            }
        }
        else{
            if(allocationsByDepositId.containsKey('None')){
                allocationsByDepositId.get('None').add(curAllocation);
            }
            else{
                allocationsByDepositId.put('None',new list<Payment_Adjustment_Allocation__c>{curAllocation});
            }
        }
    }

    @TestVisible private void populateDesignationMap(map<String,list<Payment_Adjustment_Allocation__c>> allocationsByDepositId,Payment_Adjustment_Allocation__c curAllocation){

        if(!String.isEmpty(curAllocation.Payment_Adjustment__r.Batch__r.Deposit_ID__c) && !String.isEmpty(curAllocation.Scheduled_Payment__r.Assessment__r.Designation__c)){
            if(allocationsByDepositId.containsKey(curAllocation.Payment_Adjustment__r.Batch__r.Deposit_ID__c + curAllocation.Scheduled_Payment__r.Assessment__r.Designation__c)){
                allocationsByDepositId.get(curAllocation.Payment_Adjustment__r.Batch__r.Deposit_ID__c + curAllocation.Scheduled_Payment__r.Assessment__r.Designation__c).add(curAllocation);
            }
            else{
                allocationsByDepositId.put(curAllocation.Payment_Adjustment__r.Batch__r.Deposit_ID__c + curAllocation.Scheduled_Payment__r.Assessment__r.Designation__c,new list<Payment_Adjustment_Allocation__c>{curAllocation});
            }
        }
        else{
            if(allocationsByDepositId.containsKey('None')){
                allocationsByDepositId.get('None').add(curAllocation);
            }
            else{
                allocationsByDepositId.put('None',new list<Payment_Adjustment_Allocation__c>{curAllocation});
            }
        }
    }

    public void ExportAssessmentsToExcel(){

        String soql = 'SELECT ' + ASSESSMENT_SOQL_FIELDS + ' FROM Assessment__c WHERE Status__c = \'' + ConstantsFinancials.UN_TRANSFERED_STATUS + '\' AND Is_Credit_Assessment__c = false limit 999';
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

//                if(curAssessment.Designation__r.Income_GL_Account__c == curAssessment.Designation__r.A_R_GL_Account__c){
//                    if(!String.isEmpty(curAssessment.Designation__r.Income_GL_Account__c)){
//                        if(incomeGLAssessments.containsKey(curAssessment.Designation__r.Income_GL_Account__c)){
//                            incomeGLAssessments.get(curAssessment.Designation__r.Income_GL_Account__c).add(curAssessment);
//                        }
//                        else{
//                            incomeGLAssessments.put(curAssessment.Designation__r.Income_GL_Account__c,new list<Assessment__c>{curAssessment});
//                        }
//                    }
//                    continue;
//                }

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
                ExportWrapper ew1 = createExportWrapper(curDateKey,'SFI-'+curDateKey.format(),total,totalIncomeAssessmentAmount*-1,curGLKey,UtilitiesFinancials.getGLCodeDescription(curGLKey));
                AssessmentWrappers.add(ew1);
            }
            for(String curGLKey: arGLAssessments.keySet()){
                Decimal totalARAssessmentAmount = 0.00;
                list<Assessment__c> theCurAssessments = arGLAssessments.get(curGLKey);
                for(Assessment__c curAss : theCurAssessments){
                    totalARAssessmentAmount += curAss.Assessed_Amount__c;
                }
                ExportWrapper ew2 = createExportWrapper(curDateKey,'SFI-'+curDateKey.format(),total,totalARAssessmentAmount,curGLKey,UtilitiesFinancials.getGLCodeDescription(curGLKey));
                AssessmentWrappers.add(ew2);
            }


        }

        updateAssessmentsWithStatus(assessmentIds);
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


    @TestVisible private ExportWrapper createExportWrapper(Date checkDate,String referenceNum,Integer allocSize,Decimal paymentAmount,String glAccount,String designationName){

        if(!String.isEmpty(designationName)){
//            throw new CustomExceptions.GLAccountNameException('There is a GL Account that does not have a name.');
//            return null;
        }

        ExportWrapper ew = new ExportWrapper();
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