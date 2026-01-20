public with sharing class CongrComm_HouseholdInfoCtrl {

    @TestVisible private Contact communityUserContact {get; set;}

    public Contact communityUserContactDetails {get; set;}
    public Account communityUserAccountDetails {get; set;}

    Public Boolean hasErrors {
        get{
            return ApexPages.hasMessages();
        }
    }

    public CongrComm_HouseholdInfoCtrl() {
        this.communityUserContact = UtilitiesUsers.GetContactForCommunityUser(UserInfo.getUserId());
        communityUserContactDetails = [
                SELECT Id,AccountID
                FROM Contact
                WHERE id = :communityUserContact.id];


        communityUserAccountDetails = [
                SELECT Id,Name,Phone,ShippingStreet,ShippingCity,ShippingState,ShippingPostalCode,ShippingCountry,BillingStreet,
                        BillingCity,BillingState,BillingPostalCode,BillingCountry,Seasonal_Street__c,Seasonal_City__c,Seasonal_State__c,
                        Seasonal_Zip__c,Seasonal_Phone__c,Seasonal_Address_Start_Month__c,Seasonal_Address_End_Month__c,Wedding_Date__c
                FROM Account
                WHERE id = :communityUserContactDetails.AccountID];
    }

    public PageReference SaveContact(){

        Boolean isValidationError = CheckForPageValidationError();
        if(isValidationError){
            return null;
        }

        try{
            update communityUserAccountDetails;

            PageReference pr = Page.CongrComm_MyFamilyInformation;
            pr.setRedirect(true);
            return pr;
        }
        catch(DmlException de){
            system.debug(de.getMessage());
            return null;
        }
    }

    @TestVisible private Boolean CheckForPageValidationError(){

        if (communityUserAccountDetails.ShippingPostalCode != null && communityUserAccountDetails.ShippingPostalCode != '' ) {
            if (!(communityUserAccountDetails.ShippingPostalCode.length() == 10 || communityUserAccountDetails.ShippingPostalCode.length() == 5) && communityUserAccountDetails.ShippingPostalCode.length() > 0) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Mailing Zip Code must be exactly 5 or 10 digits.'));
                return true;
            }
        }

        if (communityUserAccountDetails.BillingPostalCode != null && communityUserAccountDetails.BillingPostalCode != '' ) {
            if (!(communityUserAccountDetails.BillingPostalCode.length() == 5 || communityUserAccountDetails.BillingPostalCode.length() == 10) && communityUserAccountDetails.BillingPostalCode.length() > 0) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Billing Zip Code must be exactly 5 or 10 digits.'));
                return true;
            }
        }

        if (communityUserAccountDetails.Phone != null && communityUserAccountDetails.Phone != '' ) {
            String accountPhone = communityUserAccountDetails.Phone.replaceAll(' ','').replaceAll('\\(','').replaceAll('\\)','').replaceAll('-','');
            if (accountPhone.length() != 10 && accountPhone.length() > 0) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Home Phone must be exactly 10 digits'));
                return true;
            }
        }

        boolean seasonAddrValidation = runSeasonalAddressValidation();
        if(seasonAddrValidation){
            return true;
        }


        return false;
    }

    @TestVisible private boolean runSeasonalAddressValidation(){

        if (String.isNotBlank(communityUserAccountDetails.Seasonal_Street__c) && String.isBlank(communityUserAccountDetails.Seasonal_City__c)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Please enter the City for your seasonal address.'));
            return true;
        }
        if (String.isNotBlank(communityUserAccountDetails.Seasonal_City__c) && String.isBlank(communityUserAccountDetails.Seasonal_State__c)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Please enter the State of you seasonal address.'));
            return true;
        }
        if (String.isNotBlank(communityUserAccountDetails.Seasonal_State__c) && String.isBlank(communityUserAccountDetails.Seasonal_Address_Start_Month__c)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'You must specify a Seasonal Address Start Month.'));
            return true;
        }
        if (String.isNotBlank(communityUserAccountDetails.Seasonal_Address_Start_Month__c) && String.isBlank(communityUserAccountDetails.Seasonal_Address_End_Month__c)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'You must specify a Seasonal Address End Month.'));
            return true;
        }


        return false;
    }
}