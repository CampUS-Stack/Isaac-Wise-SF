/**
 * Created by Chris Home Office on 6/25/2019.
 */

public with sharing class ExportController_Payments {

    private static final String PAYMENT_ALLOCATION_SOQL_FIELDS = 'ID,Amount__c,Payment_Adjustment__r.Check_Date__c,' +
            'Scheduled_Payment__r.Designation__r.Income_GL_Account__c,' +
            'Scheduled_Payment__r.Designation__r.A_R_GL_Account__c,Batch__r.Deposit_ID__c,' +
            'Payment_Adjustment__r.Batch__r.Batch_Date__c,Payment_Adjustment__r.Batch__r.Deposit_ID__c,' +
            'Scheduled_Payment__r.Designation__r.Name,Scheduled_Payment__r.Assessment__r.Designation__c,Payment_Adjustment__r.Cash_Override_Account__c,' +
            'Payment_Adjustment__r.Source_Credit_Assessment__c,Payment_Adjustment__r.Source_Credit_Assessment__r.Designation__r.Name,Payment_Adjustment__r.Source_Credit_Assessment__r.Designation__r.AR_GL_Account__r.GL_Code__c,' +
            'Payment_Adjustment__r.Source_Credit_Assessment__r.Designation__c,Payment_Adjustment__r.Source_Credit_Assessment__r.Designation__r.AR_GL_Account__c';
}