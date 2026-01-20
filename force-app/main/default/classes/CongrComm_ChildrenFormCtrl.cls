/**
 * Created by Chris Home Desktop on 6/4/2018.
 */

public class CongrComm_ChildrenFormCtrl {

    /// TODO: Refactor to custom setting.
    @TestVisible private static final String REP_ID = '00537000002ShcX';

    public String ContactIdFromURL {get; set;}

    public Account TheAccount {get; set;}
    public Contact TheContact {get; set;}

    public CongrComm_ChildrenFormCtrl(){
        getURLParams();
        this.TheContact = UtilitiesUsers.GetContactForCommunityUser(UserInfo.getUserId());
        this.TheAccount = getAccount(this.TheContact.AccountId);
    }

    public PageReference Save(){
        try{
            update TheAccount;

            PageReference pr = Page.CongrComm_MyFamilyInformation;
            pr.setRedirect(true);
            return pr;
        }
        catch(DmlException de){
            system.debug(de.getMessage());
        }

        return null;
    }

    @TestVisible private void getURLParams(){

        if(ApexPages.currentPage().getParameters().containsKey('cId')){
            ContactIdFromURL = ApexPages.currentPage().getParameters().get('cId');
        }
    }

    @TestVisible public Account getAccount (Id accountId){
        try{
            Account acc = [SELEcT Id,Children_Form__c, Town_Grandchildren_Form__c, Town_AdultChildren_Form__c FROM Account WHERE Id = :accountId];
            return acc;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return null;
        }
    }


}