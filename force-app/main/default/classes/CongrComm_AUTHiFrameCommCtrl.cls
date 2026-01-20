/**
 * Created by Chris Home Desktop on 7/7/2018.
 */

global class CongrComm_AUTHiFrameCommCtrl {

    public static Batch__c foundBatchRecord { get; set; }
    public String UserType {get; set;}


    public class PaymentObjectParams {

        public String OrderInvoiceNumber { get; set; }
        public String TransactionNumber { get; set; }
        public String AuthorizationNumber { get; set; }
        public String AccountType { get; set; }
        public String AccountNumber { get; set; }

        public PaymentObjectParams() {
        }
    }

    @RemoteAction
    global static String TransactionUpdateFromAUTH(String jsonUpdateStruct) {

        PaymentObjectParams params = new PaymentObjectParams();
        system.debug(jsonUpdateStruct);
        map<String, Object> jsonMap = (map<String, Object>) JSON.deserializeUntyped(jsonUpdateStruct);
        for (String curKey : jsonMap.keySet()) {
            system.debug(curKey);
            system.debug(jsonMap.get(curKey));

            if (curKey.containsIgnoreCase('orderInvoiceNumber')) {
                params.OrderInvoiceNumber = String.valueOf(jsonMap.get(curKey));
            } else if (curKey.containsIgnoreCase('accountType')) {
                params.AccountType = String.valueOf(jsonMap.get(curKey));
            } else if (curKey.containsIgnoreCase('accountNumber')) {
                params.AccountNumber = String.valueOf(jsonMap.get(curKey));
            } else if (curKey.containsIgnoreCase('transId')) {
                params.TransactionNumber = String.valueOf(jsonMap.get(curKey));
            } else if (curKey.containsIgnoreCase('authorization')) {
                params.AuthorizationNumber = String.valueOf(jsonMap.get(curKey));
            }
        }

        return UpdatePaymentObject(params);


    }

    @TestVisible private static String UpdatePaymentObject(PaymentObjectParams paymentObj) {
        try {
            String soqlFields = 'Id,Authorize_net_Account_Type__c,Amount_Disbursed__c,Household__c,Check_Date__c,Amount__c,Batch__c,Authorize_net_Authorization_Code__c,Authorize_Net_Transaction_Number__c,Last_4_of_Credit_Card__c, (Select ID FROM Scheduled_Payment_Bridges__r)';
            Payment_Adjustment__c curPayment = Database.query('SELECT ' + soqlFields + ' FROM Payment_Adjustment__c WHERE Name LIKE \'%' + paymentObj.OrderInvoiceNumber + '\'');
            curPayment.Check_Date__c = date.today();
            curPayment.Authorize_net_Account_Type__c = paymentObj.AccountType;
            curPayment.Authorize_net_Authorization_Code__c = paymentObj.AuthorizationNumber;
            curPayment.Authorize_Net_Transaction_Number__c = paymentObj.TransactionNumber;
            curPayment.Last_4_of_Credit_Card__c = paymentObj.AccountNumber;
            curPayment.Incomplete_Payment__c = false;
//            curPayment.Batch__c = getBatchId();
//            if (String.isBlank(curPayment.Check_Number__c) && foundBatchRecord != null) {
//                curPayment.Check_Number__c = foundBatchRecord.Deposit_ID__c;
//            }
            update curPayment;


            if (shouldFeeCreateAssessment(curPayment.Id)) {
                system.debug('Inside should fee create assessment');
                createFeeAssessment(curPayment.Amount__c - curPayment.Amount_Disbursed__c, curPayment.Household__c, curPayment.Id);
            }
            else if(checkForEventFee(curPayment)){
                system.debug('Inside should fee create assessment');
                createFeeAssessment(curPayment.Amount__c - curPayment.Amount_Disbursed__c, curPayment.Household__c, curPayment.Id);
            }

            if (curPayment.Scheduled_Payment_Bridges__r != null) {

                for (Payment_Adjustment_Allocation__c curBridge : curPayment.Scheduled_Payment_Bridges__r) {
                    curBridge.Incomplete_Payment__c = false;
                }
                update curPayment.Scheduled_Payment_Bridges__r;
            }
//            updateBatch(curPayment.Batch__c);
            return curPayment.Id;
        } catch (QueryException qe) {
            system.debug(qe.getMessage());
            return 'FAILURE';
        } catch (DmlException de) {
            system.debug(de.getMessage());
            return 'FAILURE';
        }
    }

    @TestVisible private static boolean checkForEventFee(Payment_Adjustment__c payAdj) {

        system.debug('checkForEventFee Method Running.');
        try {

            //// If payment has its entire balance allocated - then we are not in fee scenario
            //// Otherwise check for an event assessment.
            if(payAdj.Amount__c == payAdj.Amount_Disbursed__c){
                return true;
            }

            map<Id, Scheduled_Payment__c> schedPayments = new map<Id, Scheduled_Payment__c> ([
                    SELECT Assessment__c
                    FROM Scheduled_Payment__c
                    WHERE Id IN (
                            SELECT Scheduled_Payment__c
                            FROM Payment_Adjustment_Allocation__c
                            WHERE Payment_Adjustment__c = :payAdj.Id
                    )
            ]);

            set<Id> assessIds = new set<Id>();
            for (Scheduled_Payment__c curSchedPayment : schedPayments.values()) {
                assessIds.add(curSchedPayment.Assessment__c);
            }
            list<Assessment__c> assessments = [
                    SELECT Id,Designation__c
                    FROM Assessment__c
                    WHERE Id IN :assessIds
            ];

            set<Id> designationIds = new set<Id>();
            for (Assessment__c curAssessment : assessments) {
                if (curAssessment.RecordTypeId == UtilitiesSObject.getRecordTypeId('Event_Assessment',Assessment__c.SObjectType)) {
                    return true;
                }
            }

            return false;

        } catch (QueryException qe) {
            system.debug(qe.getMessage());
            return false;
        }
    }

    @Future public static void updateBatch(Id batchId){
        try{
            Batch__c theBatch = [SELECT Id FROM Batch__c WHERE Id = :batchId];
            update theBatch;
        }
        catch(DmlException de){
            system.debug(de.getMessage());
        }
    }

    @TestVisible private static boolean shouldFeeCreateAssessment(String paymentId) {

        system.debug('shouldFeeCreateAssessment Method Running.');
        try {

            map<Id, Scheduled_Payment__c> schedPayments = new map<Id, Scheduled_Payment__c> ([
                    SELECT Assessment__c
                    FROM Scheduled_Payment__c
                    WHERE Id IN (
                            SELECT Scheduled_Payment__c
                            FROM Payment_Adjustment_Allocation__c
                            WHERE Payment_Adjustment__c = :paymentId
                    )
            ]);

            set<Id> assessIds = new set<Id>();
            for (Scheduled_Payment__c curSchedPayment : schedPayments.values()) {
                assessIds.add(curSchedPayment.Assessment__c);
            }
            list<Assessment__c> assessments = [
                    SELECT Id,Designation__c
                    FROM Assessment__c
                    WHERE Id IN :assessIds
            ];

            set<String> designationIds = new set<String>();
            for (Assessment__c curAssessment : assessments) {
                if (String.isNotBlank(curAssessment.Designation__c)) {
                    Id desigId = curAssessment.Designation__c;
                    designationIds.add(desigId);
                }
            }

            list<Designations_with_Fees__c> feeDesignations = UtilitiesCustomSetting.GetInstance().getDesignationsWithFees().values();

            system.debug(designationIds);
            for (Designations_with_Fees__c curDesig : feeDesignations) {
                system.debug(curDesig);
                system.debug(curDesig.Designation_ID__c);
                Id curDesignationId = curDesig.Designation_ID__c;
                system.debug(designationIds.contains(curDesignationId));
                if (designationIds.contains(curDesignationId)) {
                    return true;
                }
            }

            return false;


        } catch (QueryException qe) {
            system.debug(qe.getMessage());
            return false;
        }
    }

    @TestVisible private static void createFeeAssessment(Decimal totalPaymentAmount, Id accountId, Id paymentId) {

        try {
            if(totalPaymentAmount <= 0){
                return;
            }
            
            Decimal feeAmount = totalPaymentAmount.setScale(2);
            Assessment__c assessment = new Assessment__c();
            assessment.Account__c = accountId;
            assessment.Assessed_Amount__c = feeAmount;
            //// TODO: move ID to custom setting and pull by name
            assessment.Designation__c = 'a023700000jpMWO';
            assessment.Assessment_Date__c = date.today();
            assessment.From_Website__c = true;

            if(assessment.Assessed_Amount__c == 0){
                return;
            }

            insert assessment;

            Scheduled_Payment__c schedPayment = [SELECT Id FROM Scheduled_Payment__c WHERE Assessment__c = :assessment.Id];

            Payment_Adjustment_Allocation__c alloc = new Payment_Adjustment_Allocation__c();
            alloc.Amount__c = feeAmount;
            alloc.Payment_Adjustment__c = paymentId;
            alloc.Scheduled_Payment__c = schedPayment.Id;
            insert alloc;

        } catch (DmlException de) {
            system.debug(de.getMessage());
        } catch (QueryException qe) {
            system.debug(qe.getMessage());
        }


    }


    @TestVisible private static String getBatchId() {

        try {
            String depositId = Datetime.now().format('MM/dd/YY') + 'CCOL';
            system.debug(depositId);
            list<Batch__c> theBatches = [SELECT Id,Deposit_ID__c FROM Batch__c WHERE Transaction_Type__c = 'Posted Payment' AND Deposit_ID__c = :depositId AND Status__c = :ConstantsFinancials.UN_SUMMARIZED_STATUS];
            if (theBatches.size() > 0) {
                foundBatchRecord = theBatches[0];
                return theBatches[0].Id;
            } else {
                Batch__c newBatch = new Batch__c();
                newBatch.Deposit_ID__c = depositId;
                newBatch.Transaction_Type__c = 'Posted Payment';
                newBatch.Default_Payment_Method__c = 'Credit Card';
                newBatch.Batch_Date__c = date.today();
                insert newBatch;
                foundBatchRecord = newBatch;
                return newBatch.Id;
            }
        } catch (QueryException qe) {
            system.debug(qe.getMessage());
            return '';
        } catch (DmlException de) {
            system.debug(de.getMessage());
            return '';
        }
    }


    public CongrComm_AUTHiFrameCommCtrl() {

        system.debug(ApexPages.currentPage().getParameters());
        this.UserType = UserInfo.getUserType();


    }
}