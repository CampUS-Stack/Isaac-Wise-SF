public with sharing class CongrComm_MyPersonalInfoCtrl {

    @TestVisible private Contact communityUserContact {get; set;}
    public Contact communityUserContactDetails {get; set;}

    public CongrComm_MyPersonalInfoCtrl() {
        this.communityUserContact = UtilitiesUsers.GetContactForCommunityUser(UserInfo.getUserId());
        communityUserContactDetails = [SELECT Id,Name,FirstName,LastName,Hebrew_Name__c,Nickname__c,Email,Mobile_Phone__c,Gender__c,Date_of_Birth__c,
                                        Publicize_Birthdate_Bulletin__c,Publicize_Birthdate_Rabbi__c,Employer__c,Employer_Zip_Code__c,Title,Work_Email__c,
                                        Work_Phone__c,Occupation__c,Specialization__c,Grew_up_Here__c,Religious_Affiliation__c,Consecrated_at_Wise__c,
                                        Consecrated_Year__c,Bar_Bat_Mitzvah_at_Wise__c,Bar_Bat_Mitzvah_Date__c,Confirmed_at_Wise__c,Confirmation_Year__c,
                                        Graduated_from_Wise_Kulanu__c,Kulanu_Graduation_Year__c

                                        FROM Contact
                                        WHERE id =:communityUserContact.id];

    }





}