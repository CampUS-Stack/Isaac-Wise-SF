/**
 * Created by Chris Home Desktop on 2/9/2018.
 */

public with sharing class UtilitiesCustomSetting {

    @TestVisible private static UtilitiesCustomSetting controller {get; set;}

    public static map<String,GL_Account_Names__c> glAccountSettings {get;set;}
    public static map<String,Authorize_Net_Settings__c> Authorize_NetSettings {get;set;}
    public static map<String,Designations_With_Fees__c>  DesignationsWithFees{get;set;}
    public static map<String,Important_Accounts__c> ImportantAccountSettings {get;set;}

    /**
     *	@Author: Chris Gibson
     *  @Date: 2.12.2018
     *
     *  @Description: Method returns singleton instance for any execution context
     *
     *  @Return: a CustomSettingController object representing the controller used to
     *				retreive various custom settings from the system
     */
    public static UtilitiesCustomSetting GetInstance() {

        if(controller == null){
            return controller = new UtilitiesCustomSetting();
        }
        else {
            return controller;
        }
    }


    public map<String,GL_Account_Names__c> getGLAccountSettings(){
        if(GL_Account_Names__c.getAll() == null){
            System.debug('GL_Account__c setting is null');
            return null;
        }

        map<String,GL_Account_Names__c> glAccountSettings = GL_Account_Names__c.getall();
        return glAccountSettings;
    }

    /**
     *	@Author: Chris Gibson
     *  @Date: 2.12.2018
     *
     *  @Description: This method returns the value for a specific Field Id Setting.
     *
     *  @Return: a string object representing the value of the passed in Field Id setting name.
     */
    public String getAccountGLName(String glNumber){
        if(glAccountSettings == null){
            glAccountSettings = this.getGLAccountSettings();
        }

        for(String curAccName : glAccountSettings.keySet()){
            String glNum = glAccountSettings.get(curAccName).GL_Number__c;
            if(glNum.equals(glNumber)){
                return curAccName;
            }
        }

        return '';
    }


    public map<String,Authorize_Net_Settings__c> getAuthorize_NetSettings(){
        if(Authorize_Net_Settings__c.getAll() == null){
            System.debug('Authorize_Net_Settings__c setting is null');
            return null;
        }

        map<String,Authorize_Net_Settings__c> returnAuthorize_NetSettings = Authorize_Net_Settings__c.getall();
        return returnAuthorize_NetSettings;
    }

    /**
     *	@Author: Chris Gibson
     *  @Date: 06.27.2018
     *
     *  @Description: This method returns the value for a specific Field Id Setting.
     *
     *  @Return: a string object representing the value of the passed in Field Id setting name.
     */
    public String getAuthorize_NetSetting(String settingName){
        if(Authorize_NetSettings == null){
            Authorize_NetSettings = this.getAuthorize_NetSettings();
        }

        for(String curSettingName : Authorize_NetSettings.keySet()){
            if(curSettingName.equals(settingName)){
                return Authorize_NetSettings.get(curSettingName).Value__c;
            }
        }

        return '';
    }


    public map<String,Designations_With_Fees__c> getDesignationsWithFees(){
        if(Designations_With_Fees__c.getAll() == null){
            System.debug('Authorize_Net_Settings__c setting is null');
            return null;
        }

        map<String,Designations_With_Fees__c> returnDesignationsWithFees = Designations_With_Fees__c.getall();
        return returnDesignationsWithFees;
    }

    public Fee_Designation_Setting__c getFeeDesignationsSetting() {
        if (Fee_Designation_Setting__c.getOrgDefaults() == null) {
            System.debug('Fee_Designation_Setting__c setting is null');
            return null;
        }

        Fee_Designation_Setting__c returnFeeDesignationSetting = Fee_Designation_Setting__c.getOrgDefaults();
        return returnFeeDesignationSetting;
    }

    /**
     *	@Author: Chris Gibson
     *  @Date: 08.09.2018
     *
     *  @Description: This method returns the value for a specific Field Id Setting.
     *
     *  @Return: a string object representing the value of the passed in Field Id setting name.
     */
    public String getDesignationWithFees(String settingName){
        if(DesignationsWithFees == null){
            DesignationsWithFees = this.getDesignationsWithFees();
        }

        for(String curSettingName : DesignationsWithFees.keySet()){
            if(curSettingName.equals(settingName)){
                return DesignationsWithFees.get(curSettingName).Designation_ID__c;
            }
        }

        return '';
    }

    public map<String,Important_Accounts__c> getImportantAccountSettings(){
        if(Important_Accounts__c.getAll() == null){
            System.debug('Important_Accounts__c setting is null');
            return null;
        }

        map<String,Important_Accounts__c> returnImportantAccountSettings = Important_Accounts__c.getall();
        return returnImportantAccountSettings;
    }

    /**
     *	@Author: Chris Gibson
     *  @Date: 06.27.2018
     *
     *  @Description: This method returns the value for a specific Field Id Setting.
     *
     *  @Return: a string object representing the value of the passed in Field Id setting name.
     */
    public String getImportantAccountSetting(String settingName){
        if(ImportantAccountSettings == null){
            ImportantAccountSettings = this.getImportantAccountSettings();
        }

        for(String curSettingName : ImportantAccountSettings.keySet()){
            if(curSettingName.equals(settingName)){
                return ImportantAccountSettings.get(curSettingName).Account_ID__c;
            }
        }

        return '';
    }

    public static String getDefaultPaymentGateway(){
        String defaultGateWay = 'TransNational (NMI)';
        List<Payment_Gateway_Setting__mdt> paymentGatewaySettings = [select id, Active_Gateway__c, MasterLabel FROM Payment_Gateway_Setting__mdt WHERE MasterLabel = 'Community'];
        if (paymentGatewaySettings.size() > 0) {
            return paymentGatewaySettings.get(0).Active_Gateway__c;
        }
        return defaultGateWay;
    }

    public static PageReference navigateToPaymentPageCommunity(String paymentAdjustmentId, String paymentMethod) {


        Payment_Adjustment__c newPaymentQueried = [SELECT Id, Name from Payment_Adjustment__c WHERE Id = :paymentAdjustmentId];

        String defaultGateWay = 'TransNational (NMI)';
        List<Payment_Gateway_Setting__mdt> paymentGatewaySettings = [select id, Active_Gateway__c, MasterLabel FROM Payment_Gateway_Setting__mdt WHERE MasterLabel = 'Community'];
        if (paymentGatewaySettings.size() > 0) {
            defaultGateWay = paymentGatewaySettings.get(0).Active_Gateway__c;
        }

        if (defaultGateWay == 'Authorize.net') {
            PageReference pr = Page.CongrComm_AUTHPayment;
            pr.getParameters().put('pId', newPaymentQueried.Name.substring(newPaymentQueried.Name.indexOf('-') + 1, newPaymentQueried.Name.length()));
            pr.setRedirect(true);
            return pr;
        } else if (defaultGateWay == 'TransNational (NMI)') {
            PageReference pr = Page.CongrComm_NMIPaymentProcessor;
            pr.getParameters().put('paId', newPaymentQueried.Id);
            if(paymentMethod != null)
                pr.getParameters().put('method', paymentMethod);
            pr.setRedirect(true);
            return pr;
        }
        System.debug(defaultGateWay);

        throw new CustomException('Payment gateway not configured');

    }

//    public static PageReference navigateToAuthorizeNet(String defaultGateway, Payment_Adjustment__c newPaymentQueried){
//        PageReference pr = Page.CongrComm_AUTHPayment;
//        pr.getParameters().put('pId', newPaymentQueried.Name.substring(newPaymentQueried.Name.indexOf('-') + 1, newPaymentQueried.Name.length()));
//        pr.setRedirect(true);
//        return pr;
//    }

    public class CustomException extends Exception {
    }


}