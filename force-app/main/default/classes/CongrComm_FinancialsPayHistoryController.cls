public class CongrComm_FinancialsPayHistoryController {
    
    Public Contact theContact {get; set;}
    Public Boolean hasPayments {get; set;}
    Public List<Payment_Adjustment__c> paymentList {get; set;}
    Public List<PaymentWrapper> wrappedPaymentList {get; set;}
    
    Public CongrComm_FinancialsPayHistoryController() {
        
        Date queryDate = Date.today();
        queryDate = queryDate.addMonths(-18);
        System.debug('queryDate: ' + queryDate);
        
        // Get the current user's account
        try {
            User currentUser = [SELECT Id, ContactId
                                FROM   User
                                //WHERE Id = '00529000001lCTy'];
                                WHERE  Id = :UserInfo.getUserId()];
            theContact = [SELECT Id, AccountId, Account.Name, FirstName, LastName
                          FROM   Contact
                          WHERE  Id = :currentUser.ContactId];
            paymentList = [SELECT Id, Check_Date__c, Amount__c, Reason__c, Name, Last_4_of_Credit_Card__c, Authorize_net_Account_Type__c
                           FROM   Payment_Adjustment__c
                           WHERE  Household__c = :theContact.AccountId 
                           AND 	  Check_Date__c > :queryDate ORDER BY Check_Date__c DESC];
            System.debug('paymentList: ' + paymentList);
        } catch (Exception ex) {
            System.debug('The following exception has occurred: ' + ex.getMessage());
        }
        wrappedPaymentList = new List<PaymentWrapper>();
        Map<Id, PaymentWrapper> wrappedPaymentMap = new Map<Id, PaymentWrapper>();
        for(Payment_Adjustment__c p : paymentList){
            wrappedPaymentMap.put(p.Id, new PaymentWrapper(p));
        }

        List<Payment_Adjustment_Allocation__c> paymentDetailList = [SELECT Id, Assessment_Designation__c, Amount__c, Payment_Adjustment__c
        FROM Payment_Adjustment_Allocation__c
        WHERE Payment_Adjustment__c IN :wrappedPaymentMap.keySet()];

        for(Payment_Adjustment_Allocation__c pa : paymentDetailList){
            PaymentWrapper thePayment = wrappedPaymentMap.get(pa.Payment_Adjustment__c);
            thePayment.paymentDetails.add(pa);
            wrappedPaymentMap.put(pa.Payment_Adjustment__c, thePayment);
        }
        System.debug('wrappedPaymentMap: ' + wrappedPaymentMap);

        wrappedPaymentList = wrappedPaymentMap.values();

        System.debug('paymentList: ' + paymentList);
        if(paymentList.size() > 0){
            hasPayments = true;
        } else {
            hasPayments = false;
        }
        
    }
    
    Public PageReference cancel() {
        PageReference pageRef = new PageReference('/CongrComm_FinancialsHome');
        return pageRef;
    }

    Public class PaymentWrapper {

        Public Date Check_Date {get; set;}
        Public Decimal Amount {get; set;}
        Public Id theId {get; set;}
        Public Payment_Adjustment__c thePayment {get; set;}
        Public List<Payment_Adjustment_Allocation__c> paymentDetails {get; set;}

        Public PaymentWrapper(Payment_Adjustment__c thePayment) {
            this.thePayment = thePayment;
            this.Check_Date = thePayment.Check_Date__c;
            this.Amount = thePayment.Amount__c;
            this.theId = thePayment.Id;
            this.paymentDetails = new List<Payment_Adjustment_Allocation__c>();
        }

    }

}