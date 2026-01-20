/**
 * Created by Chris Home Desktop on 7/8/2018.
 */

public without sharing class CongrComm_RecieptCtrl {

    public Payment_Adjustment__c thePayment { get; set; }

    public CongrComm_RecieptCtrl() {

        String paymentId = getPaymentIdFromParam();
        this.thePayment = getPaymentAdjustment(paymentId);
    }

    @TestVisible private String getPaymentIdFromParam() {
        if (ApexPages.currentPage().getParameters().containsKey('pId')) {
            return ApexPages.currentPage().getParameters().get('pId');
        }

        return '';
    }

    @TestVisible private Payment_Adjustment__c getPaymentAdjustment(String paymentId) {
        try {
            System.debug('Payment Id: ' + paymentId);
            Payment_Adjustment__c payAdj = [
                    SELECT Id, Check_Date__c, Amount__c, Name, Last_4_of_Credit_Card__c, Authorize_net_Account_Type__c, Receipt_Link__c, Receipt_Text__c,
                    (SELECT Id,Amount__c,Scheduled_Payment__r.Assessment__r.Designation__r.Designation_Description__c FROM Scheduled_Payment_Bridges__r)
                    FROM Payment_Adjustment__c
                    WHERE Id = :paymentId
            ];
            return payAdj;
        } catch (QueryException qe) {
            system.debug(qe.getMessage());
            return null;
        }
    }

}