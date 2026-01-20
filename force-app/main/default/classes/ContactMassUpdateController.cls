/**
 * Created by Chris Home Desktop on 8/6/2017.
 */

public with sharing class ContactMassUpdateController {

    public list<UtilitiesWrappers.ContactWrapper> ContactWrappers {get; set;}
    public String AddressToCopy {get; set;}
    public Account TheAccount {get; set;}


    public List<SelectOption> GetAddressValues() {

        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('Mailing Address','Mailing Address'));
        options.add(new SelectOption('Billing Address','Billing Address'));
        return options;

    }

    public ContactMassUpdateController(ApexPages.StandardController stdController){

        String accountId = stdController.getId();
        this.TheAccount = GetAccount(accountId);
        this.ContactWrappers = GetRelatedContactWrappers(accountId);
    }

    public PageReference UpdateAddresses(){

        list<Contact> contactsToUpdate = new list<Contact>();
        for(UtilitiesWrappers.ContactWrapper curWrap : this.ContactWrappers){

            if(curWrap.isSelected){
                UpdateIndividualAddress(curWrap);
                contactsToUpdate.add(curWrap.theContact);
            }
        }

        try{
            update contactsToUpdate;
            PageReference pr = new PageReference('/' + this.TheAccount.Id);
            pr.setRedirect(true);
            return pr;
        }
        catch(DmlException de){
            system.debug(de.getMessage());
            return null;
        }
    }

    @TestVisible private void UpdateIndividualAddress(UtilitiesWrappers.ContactWrapper conWrapper){

        if(this.AddressToCopy == 'Mailing Address'){
            conWrapper.theContact.MailingState = this.TheAccount.BillingState;
            conWrapper.theContact.MailingCity = this.TheAccount.BillingCity;
            conWrapper.theContact.MailingStreet = this.TheAccount.BillingStreet;
            conWrapper.theContact.MailingPostalCode = this.TheAccount.BillingPostalCode;
        }
        else{
            conWrapper.theContact.MailingState = this.TheAccount.ShippingState;
            conWrapper.theContact.MailingCity = this.TheAccount.ShippingCity;
            conWrapper.theContact.MailingStreet = this.TheAccount.ShippingStreet;
            conWrapper.theContact.MailingPostalCode = this.TheAccount.ShippingPostalCode;
        }
    }

    @TestVisible private list<UtilitiesWrappers.ContactWrapper> GetRelatedContactWrappers(String accountId){

        try{
            list<Contact> contacts = [SELECT Id,MailingState,MailingCity,MailingPostalCode,MailingStreet,FirstName,LastName  FROM Contact c WHERE AccountId = :accountId];
            list<UtilitiesWrappers.ContactWrapper> returnWrappers = new list<UtilitiesWrappers.ContactWrapper>();

            for(Contact curC : contacts){
                UtilitiesWrappers.ContactWrapper wrapper = new UtilitiesWrappers.ContactWrapper();
                wrapper.theContact = curC;
                returnWrappers.add(wrapper);
            }

            return returnWrappers;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return null;
        }
    }

    @TestVisible private Account GetAccount(String accountId){
        try{
            Account acc = [SELECT Id,ShippingState,ShippingCity,ShippingPostalCode,ShippingStreet,BillingCity,
                    BillingState,BillingPostalCode,BillingStreet
            FROM Account WHERE Id = :accountId];
            return acc;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return null;
        }
    }

}