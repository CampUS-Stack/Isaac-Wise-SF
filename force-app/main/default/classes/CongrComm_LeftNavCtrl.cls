/**
 * Created by Chris Home Desktop on 4/16/2018.
 */

public with sharing class CongrComm_LeftNavCtrl {

    public static String CURRENT_FISCAL_YEAR { get; set; }
    public Contact CommunityUserContact {get; set;}

    public CongrComm_LeftNavCtrl(){
//        this.HouseholdContacts = createFakeContacts();
        this.CommunityUserContact = UtilitiesUsers.GetContactForCommunityUser(UserInfo.getUserId());
        CURRENT_FISCAL_YEAR = CongrComm_FairShareController.getOrgCurrentFiscalYear();
    }
}