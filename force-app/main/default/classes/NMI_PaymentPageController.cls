/**
 * Created by Chris Gibson on 1/18/2020.
 */

public with sharing class NMI_PaymentPageController {

    public static final String REDIRECT_URL = 'https://member-force-test-dev-ed.lightning.force.com/apex/NMI_PaymentResponse';

    public String CurrentStep {get; set;}
    public String PaymentAmount {get; set;}
    public String FormPOSTURL {get; set;}

    public NMI_PaymentPageController(){
        NMI_TransactionalWrapper transactionalWrap = new NMI_TransactionalWrapper('sale');
        transactionalWrap.ApiKey = NMI_Utilities.API_KEY;
        transactionalWrap.RedirectUrl = NMI_Utilities.BASE_URL + NMI_Utilities.REDIRECT_ENDPOINT;
        transactionalWrap.Amount = 2.00;
        transactionalWrap.IPAddress = [SELECT Id, SourceIp FROM AuthSession WHERE UsersId = :UserInfo.getUserId() ORDER BY CreatedDate DESC LIMIT 1].SourceIp;
        NMI_ConnectionController nmiConn = new NMI_ConnectionController();
        this.FormPOSTURL = nmiConn.GetRedirectUrl(transactionalWrap);
        CurrentStep = 'Step 2';
    }


    @AuraEnabled
    public static String GetNMIRedirectUrl(Double paymentAmount){

        NMI_TransactionalWrapper transactionalWrap = new NMI_TransactionalWrapper('sale');
        transactionalWrap.ApiKey = NMI_Utilities.API_KEY;
        transactionalWrap.RedirectUrl = REDIRECT_URL;
        transactionalWrap.Amount = 2.00;
        transactionalWrap.IPAddress = [SELECT Id, SourceIp FROM AuthSession WHERE UsersId = :UserInfo.getUserId() ORDER BY CreatedDate DESC LIMIT 1].SourceIp;
        system.debug(transactionalWrap.GetXMLString());
        NMI_ConnectionController nmiConn = new NMI_ConnectionController();
        String redirectUrl = nmiConn.GetRedirectUrl(transactionalWrap);
        system.debug(redirectUrl);
        return redirectUrl;
    }

}