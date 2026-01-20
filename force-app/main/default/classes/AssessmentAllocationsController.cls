/**
 * Created by Kritik Garg on 03-03-2020.
 */

public without sharing class AssessmentAllocationsController {

    @AuraEnabled
    public static List<Assessment__c> getAssessments(String assessmentId) {

        List<CreditAllocationWrapper> listOfCAWrappers = new List<AssessmentAllocationsController.CreditAllocationWrapper>();

        String soql = 'select id, RecordType.Name from Assessment__c WHERE id =:assessmentId' ;

        List<Assessment__c> listOfAssessment = Database.query(soql);

        return listOfAssessment;
    }


    @AuraEnabled
    public static List <CreditAllocationWrapper> getCreditAllocationsFromAssessment(String assessmentId) {

        List<CreditAllocationWrapper> listOfCAWrappers = new List<AssessmentAllocationsController.CreditAllocationWrapper>();

        String soql = 'Select id,Name, Amount__c, Payment_Adjustment__r.Name, CreatedDate ' +
                'From Credit_Allocation__c ' +
                'Where Assessment__c =:assessmentId ';


        List<Credit_Allocation__c> listOfAllocations = Database.query(soql);

        for(Credit_Allocation__c ca : listOfAllocations) {
            listOfCAWrappers.add(new CreditAllocationWrapper(ca));
        }

        return listOfCAWrappers;
    }


    @AuraEnabled
    public static List <PaymentAllocationWrapper> getPaymentAllocationsFromAssessment(String assessmentId) {

        List<PaymentAllocationWrapper> listOfPAWrappers = new List<AssessmentAllocationsController.PaymentAllocationWrapper>();

        String soql = 'SELECT ' +
                'id, Name, Amount__c, Tax_Deductible__c, Assessment_Date__c,  Scheduled_Payment__c, Scheduled_Payment__r.Assessment__c, CreatedDate ' +
                'FROM Payment_Adjustment_Allocation__c  ' +
                'WHERE Scheduled_Payment__r.Assessment__c =:assessmentId ';


        List<Payment_Adjustment_Allocation__c> listOfAllocations = Database.query(soql);

        for(Payment_Adjustment_Allocation__c pa : listOfAllocations) {
            listOfPAWrappers.add(new PaymentAllocationWrapper(pa));
        }

        return listOfPAWrappers;
    }

    public class CreditAllocationWrapper {

        @AuraEnabled public Credit_Allocation__c creditAllocation { get; set; }
        public CreditAllocationWrapper(Credit_Allocation__c ca) {
            this.creditAllocation = ca;
        }
    }

    public class PaymentAllocationWrapper {

        @AuraEnabled public Payment_Adjustment_Allocation__c paymentAdjustmentAllocation { get; set; }
        public PaymentAllocationWrapper(Payment_Adjustment_Allocation__c pa) {
            this.paymentAdjustmentAllocation = pa;
        }
    }

}