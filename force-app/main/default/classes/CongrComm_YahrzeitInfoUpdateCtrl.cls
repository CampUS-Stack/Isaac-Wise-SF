public class CongrComm_YahrzeitInfoUpdateCtrl {
    
    @TestVisible private Contact communityUserContact {get; set;}
    
    public Contact communityUserContactDetails {get; set;}
    public Account communityUserAccountDetails {get; set;}

    
    public CongrComm_YahrzeitInfoUpdateCtrl() {
        this.communityUserContact = UtilitiesUsers.GetContactForCommunityUser(UserInfo.getUserId());
        communityUserContactDetails = [
            SELECT Id,AccountID
            FROM Contact
            WHERE id = :communityUserContact.id];
        
        communityUserAccountDetails = [
            SELECT Id, Message_for_Assistant__c FROM Account
            WHERE id = :communityUserContactDetails.AccountID];
    }
    
    public PageReference Save(){
        try{
            update communityUserAccountDetails;
            
            PageReference pr = Page.CongrComm_Home;
            pr.setRedirect(true);
            return pr;
        }
        catch(DmlException de){
            system.debug(de.getMessage());
        }
        
        return null;
    }
    
    public PageReference Cancel(){
        
        PageReference pr = Page.CongrComm_Observances;
        pr.setRedirect(true);
        return pr;
        
    }
    
}