/**
 * Created by Chris Home Desktop on 2/26/2017.
 */

public without sharing class FundsDisbursementController {

    public FundsDisbursementController() {
    }

    /**
    *
    *  @author Chris Gibson
    *  @date 11.02.2017
    *
    *  @description This method spreads the payment amount across all the open transaction objects.
    *
    */
    public String DisburseFundsToAllocations(Decimal paymentAmount, list<Scheduled_Payment__c> scheduledPayments, Payment_Adjustment__c thePaymentAdjustment, String paymentType) {

        if (paymentAmount == null) {
            throw new CustomExceptions.InvalidParameterException('Payment amount must be not be null');
        }

        if (scheduledPayments == null || scheduledPayments.size() == 0) {
            throw new CustomExceptions.InvalidParameterException('The list of Transactions cannot be null or empty');
        }

        list<Scheduled_Payment__c> scheduledPaymentsToApplyPayments = new list<Scheduled_Payment__c>();
        list<Scheduled_Payment__c> scheduledPaymentForCreditBalance = new list<Scheduled_Payment__c>();

        for (Scheduled_Payment__c curSP : scheduledPayments) {
            system.debug('Cur Transaction Remaining Balance: ' + curSP.Remaining_Balance__c);
            if (curSP.Remaining_Balance__c > 0) {
                scheduledPaymentsToApplyPayments.add(curSP);
            }
        }

        spreadPaymentAcrossScheduledPayments(paymentAmount, scheduledPaymentsToApplyPayments, thePaymentAdjustment, paymentType);

        return '';
    }

    /**
    *
    *  @author Chris Gibson
    *  @date 04.05.2018
    *
    *  @description This method spreads the adjustment amount across all the open transaction objects.
    *
    *  NOTE***** 4.6.2018 This adjustment model will need to be revisited when there are more than 1 scheduled payment to an assessment. If existing logic
    *                       stays in place it will only adjust the first scheduled payment it finds. Need to discuss how this would spread out.
    *
    */
    public String DisburseAdjustmentsToAllocations(Decimal paymentAmount, list<Scheduled_Payment__c> scheduledPayments, Payment_Adjustment__c thePaymentAdjustment, String paymentType) {

        system.debug('Running Disbursement for Adjustments');

        if (paymentAmount == null) {
            throw new CustomExceptions.InvalidParameterException('Payment amount must be not be null');
        }

        if (scheduledPayments == null || scheduledPayments.size() == 0) {
            throw new CustomExceptions.InvalidParameterException('The list of Transactions cannot be null or empty');
        }

        list<Scheduled_Payment__c> scheduledPaymentsToApplyPayments = new list<Scheduled_Payment__c>();
        list<Scheduled_Payment__c> scheduledPaymentForCreditBalance = new list<Scheduled_Payment__c>();

        for (Scheduled_Payment__c curSP : scheduledPayments) {

            system.debug('Cur Transaction Remaining Balance: ' + curSP.Remaining_Balance__c);
            scheduledPaymentsToApplyPayments.add(curSP);
        }

        spreadAdjustmentAcrossScheduledPayments(paymentAmount, scheduledPaymentsToApplyPayments, thePaymentAdjustment, paymentType);

        return '';
    }

    /**
    *
    *  @author Chris Gibson
    *  @date 11.02.2017
    *
    *  @description This method spreads the payment amount across all the open transaction objects.
    *
    */
    public String DisburseFundsToCreditAllocations(Decimal paymentAmount, list<Scheduled_Payment__c> scheduledPayments) {

//        if(paymentAmount == null){
//            throw new CustomExceptions.InvalidParameterException('Payment amount must be not be null');
//        }
//
//        if(scheduledPayments == null || scheduledPayments.size() == 0){
//            throw new CustomExceptions.InvalidParameterException('The list of Transactions cannot be null or empty');
//        }
//
//        list<Scheduled_Payment__c> scheduledPaymentsToApplyPayments = new list<Scheduled_Payment__c>();
//        list<Scheduled_Payment__c> scheduledPaymentForCreditBalance = new list<Scheduled_Payment__c>();
//
//        for(Scheduled_Payment__c curSP : scheduledPayments){
//            system.debug('Cur Transaction Remaining Balance: ' + curSP.Remaining_Balance__c);
//            if(curSP.Remaining_Balance__c > 0 ||curSP.Assessment__r.Is_Credit_Assessment__c){
//                scheduledPaymentsToApplyPayments.add(curSP);
//            }
//        }

//        spreadPaymentAcrossScheduledPayments(paymentAmount,scheduledPaymentsToApplyPayments,thePaymentAdjustment,paymentType);

        return '';
    }
    @TestVisible private void spreadPaymentAcrossScheduledPayments(Decimal paymentAmount, list<Scheduled_Payment__c> scheduledPayments, Payment_Adjustment__c thePayment, String paymentType) {

        system.debug('Spread Payment Across Scheduled Payment Code Running.');
        Integer numberOfSPs = scheduledPayments.size();
        list<Payment_Adjustment_Allocation__c> paymentAllocations = new list<Payment_Adjustment_Allocation__c>();
        map<Id, Decimal> paymentAmountsByAssessmentId = new map<Id, Decimal>();
        map<Id, Decimal> currentRemainingBalanceByAssessmentId = new map<Id, Decimal>();

        system.debug(scheduledPayments.size());
        for (Scheduled_Payment__c curSP : scheduledPayments) {

            Decimal remainingPayment = paymentAmount - curSP.Remaining_Balance__c;
            system.debug('Remaining Payment: ' + remainingPayment);
            Decimal amountToSendToPayment = 0.0;
            if (remainingPayment < 0) {
//            if(remainingPayment < 0 && !curSP.Assessment__r.Is_Credit_Assessment__c){
                amountToSendToPayment = paymentAmount;
            }
//            else if(curSP.Assessment__r.Is_Credit_Assessment__c){
//
//                system.debug('Found Credit Assessment.');
//                system.debug('Payment Amount . ' + paymentAmount);
//                system.debug('Expected Amount . ' + curSP.Expected_Amount__c);
//                remainingPayment = paymentAmount - curSP.Expected_Amount__c;
//                system.debug('Remaining Payment: ' + paymentAmount);
//
//                if(remainingPayment < 0){
//                    amountToSendToPayment = remainingPayment;
//                }
//                else{
//                    amountToSendToPayment = curSP.Expected_Amount__c;
//                }
//                system.debug('Sending ' + amountToSendToPayment + ' to payment.');
//            }
            else {
                amountToSendToPayment = curSP.Remaining_Balance__c;
            }

            system.debug('PAyment Amount: ' + amountToSendToPayment);
            system.debug('Amount to send to Payment: ' + amountToSendToPayment);

            paymentAmount = paymentAmount - amountToSendToPayment;
            system.debug('New Remaining Payment Balance: ' + paymentAmount);
            if (amountToSendToPayment == 0) {
                continue;
            }
            system.debug('PAyment Amount: ' + paymentAmount);
            Payment_Adjustment_Allocation__c paa = createPaymentAdjustmentAllocation(amountToSendToPayment, curSP, thePayment.Id, paymentType);
            paa.Type__c = thePayment.Type__c;
            system.debug('Payment Adjustment Allocation: ' + paa);
            paymentAllocations.add(paa);

            if (!String.isEmpty(curSP.Assessment__c)) {
//                if(curSP.Assessment__r.Is_Credit_Assessment__c){
//
//                }
                if (!paymentAmountsByAssessmentId.containsKey(curSP.Assessment__c)) {
                    paymentAmountsByAssessmentId.put(curSP.Assessment__c, amountToSendToPayment);
                } else {
                    paymentAmountsByAssessmentId.put(curSP.Assessment__c, amountToSendToPayment + paymentAmountsByAssessmentId.get(curSP.Assessment__c));
                }

                if (curSP.Assessment__r.Remaining_Balance__c != null) {
                    if (!currentRemainingBalanceByAssessmentId.containsKey(curSP.Assessment__c)) {
                        currentRemainingBalanceByAssessmentId.put(curSP.Assessment__c, curSP.Assessment__r.Remaining_Balance__c);
                    }
                }
            }
        }

        insert paymentAllocations;
        system.debug('Payment Amount by Assessment ID: ' + paymentAmountsByAssessmentId);
    }

    @TestVisible private void spreadAdjustmentAcrossScheduledPayments(Decimal adjustmentAmount, list<Scheduled_Payment__c> scheduledPayments, Payment_Adjustment__c thePayment, String paymentType) {

        system.debug('Spread Adjustment Across Scheduled Payment Code Running. Adj Amt: ' + adjustmentAmount);
        Integer numberOfSPs = scheduledPayments.size();
        list<Payment_Adjustment_Allocation__c> paymentAllocations = new list<Payment_Adjustment_Allocation__c>();
        map<Id, Decimal> paymentAmountsByAssessmentId = new map<Id, Decimal>();
        map<Id, Decimal> currentRemainingBalanceByAssessmentId = new map<Id, Decimal>();

        system.debug(scheduledPayments.size());
        for (Scheduled_Payment__c curSP : scheduledPayments) {

            system.debug('Remaining Adjustment Amount: ' + adjustmentAmount);
            Payment_Adjustment_Allocation__c paa = createPaymentAdjustmentAllocation(adjustmentAmount, curSP, thePayment.Id, paymentType);
            paa.Type__c = thePayment.Type__c;
            system.debug('Payment Adjustment Allocation: ' + paa);
            paymentAllocations.add(paa);

            if (!String.isEmpty(curSP.Assessment__c)) {
                if (!paymentAmountsByAssessmentId.containsKey(curSP.Assessment__c)) {
                    paymentAmountsByAssessmentId.put(curSP.Assessment__c, adjustmentAmount);
                } else {
                    paymentAmountsByAssessmentId.put(curSP.Assessment__c, adjustmentAmount + paymentAmountsByAssessmentId.get(curSP.Assessment__c));
                }

                if (curSP.Assessment__r.Remaining_Balance__c != null) {
                    if (!currentRemainingBalanceByAssessmentId.containsKey(curSP.Assessment__c)) {
                        currentRemainingBalanceByAssessmentId.put(curSP.Assessment__c, curSP.Assessment__r.Remaining_Balance__c);
                    }
                }
            }
        }

        insert paymentAllocations;
        system.debug('Payment Amount by Assessment ID: ' + paymentAmountsByAssessmentId);
    }


    @TestVisible private Payment_Adjustment_Allocation__c createPaymentAdjustmentAllocation(Decimal paymentAmount, Scheduled_Payment__c theScheduledPayment, Id paymentId, String paymentType) {

        Payment_Adjustment_Allocation__c paa = new Payment_Adjustment_Allocation__c();
        paa.Scheduled_Payment__c = theScheduledPayment.Id;
        system.debug('Printing Payment ID: ' + paymentId);
        paa.Payment_Adjustment__c = paymentId;
        paa.Amount__c = paymentAmount;
        if (paymentType == 'Credit' || paymentType == 'Posted Payment') {
            paa.RecordTypeId = UtilitiesSObject.getRecordTypeId('Payment', Payment_Adjustment_Allocation__c.SObjectType);
        } else {
            paa.RecordTypeId = UtilitiesSObject.getRecordTypeId(paymentType, Payment_Adjustment_Allocation__c.SObjectType);
        }
        return paa;
    }

}