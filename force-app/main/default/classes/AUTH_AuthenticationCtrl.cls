/**
 * Created by UD Office Chris on 6/27/2018.
 */

public with sharing class AUTH_AuthenticationCtrl {

    public String MERCHANT_ID = '';
    public String TRANSACTION_ID = '';
    public String AccessToken {get; set;}

    public AUTH_AuthenticationCtrl(){

        UtilitiesCustomSetting settingCtrl = UtilitiesCustomSetting.GetInstance();
        this.MERCHANT_ID = settingCtrl.getAuthorize_NetSetting('Merchant ID');
        this.TRANSACTION_ID = settingCtrl.getAuthorize_NetSetting('Transaction ID');
    }

    public String setAccessToken(String responseBody){

        String returnString = '';
        responseBody = responseBody.substring(1,responseBody.length());
        Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);

        for(String curKey : jsonMap.keySet()){
            if(curKey == 'token'){
                returnString = String.valueOf(jsonMap.get(curKey));
            }
        }

        AccessToken = returnString;
        return returnString;
    }

}