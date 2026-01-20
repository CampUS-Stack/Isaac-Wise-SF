/**
 * Created by Chris Gibson on 1/20/2020.
 */

public with sharing class NMI_PaymentResponseController {



    public NMI_PaymentResponseController(){

        if(ApexPages.currentPage().getParameters().containsKey('token-id')){
            String tokenId = ApexPages.currentPage().getParameters().get('token-id');

            NMI_ConfirmationWrapper confirmWrapper = new NMI_ConfirmationWrapper();
            confirmWrapper.ApiKey = 'rUbm5n8z8jVm4B244N4jHHKkSvp2jr4q';
            confirmWrapper.TokenId = tokenId;

            NMI_ConnectionController nmiConn = new NMI_ConnectionController();
            nmiConn.SendConfirmationRequest(confirmWrapper);
        }
    }

}