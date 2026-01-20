/**
 * Created by UD Office Chris on 7/6/2018.
 */

public class CongrComm_AUTHRedirectCtrl {

    public String Token {get; set;}
    public String HTMLData {get; set;}
    public CongrComm_AUTHRedirectCtrl(){

        String paymentId = '';
        if(ApexPages.currentPage().getParameters().containsKey('pId')){
            paymentId = ApexPages.currentPage().getParameters().get('pId');
        }

        if(String.isBlank(paymentId)){
            return;
        }

        Payment_Adjustment__c payment = getPaymentAdjustment(paymentId);

        if(payment == null){
            return;
        }

        AUTH_RequestController requestController = new AUTH_RequestController();
        Decimal paymentAmount = (payment.Amount__c).setScale(2);
        system.debug('Payment Amount:');
        system.debug(paymentAmount);
        Contact currentUserContact = UtilitiesUsers.GetContactForCommunityUser(UserInfo.getUserId());
        if(currentUserContact != null){
            this.Token = requestController.GetURLTokenForMember(paymentAmount,currentUserContact.Id,paymentId);
        }
        else{
            this.Token = requestController.GetURLTokenForGuest(paymentAmount,paymentId);
        }
//        this.HTMLData = this.HTMLData.replaceAll('\r\n','').replaceAll('\n','').replaceAll('\r','');

    }

    @TestVisible private Payment_Adjustment__c getPaymentAdjustment(String paymentAdjString){
        try{
            Payment_Adjustment__c paymentAdjustment = Database.query('SELECT Id,Amount__c FROM Payment_Adjustment__c WHERE Name LIKE \'%' + paymentAdjString + '\'');
            return paymentAdjustment;
        }
        catch (QueryException qe){
            system.debug(qe.getMessage());
            return null;
        }
    }

}