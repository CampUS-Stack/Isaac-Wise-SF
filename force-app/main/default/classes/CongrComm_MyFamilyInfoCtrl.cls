/**
 * Created by Chris Home Desktop on 4/7/2018.
 */

public without sharing class CongrComm_MyFamilyInfoCtrl {

    @TestVisible private Contact communityUserContact {get; set;}

    public list<UtilitiesWrappers.ContactWrapper> HouseholdContacts {get; set;}
    public List<UtilitiesWrappers.ContactWrapper> otherRelatedContacts { get; set; }

    public CongrComm_MyFamilyInfoCtrl(){
//        this.HouseholdContacts = createFakeContacts();
        this.communityUserContact = UtilitiesUsers.GetContactForCommunityUser(UserInfo.getUserId());
        this.HouseholdContacts = getHouseholdContactWrappers(this.communityUserContact.AccountId);

        if (communityUserContact != null) {
           // otherRelatedContacts = UtilitiesWrappers.createContactWrappers(getRelateContacts(communityUserContact.Id));
            otherRelatedContacts = UtilitiesWrappers.createContactWrappers(getRelateContactsByEmail(communityUserContact.Email));
        }
        System.debug(otherRelatedContacts );

    }

    @TestVisible private list<UtilitiesWrappers.ContactWrapper> createFakeContacts(){
        list<UtilitiesWrappers.ContactWrapper> returnList = new list<UtilitiesWrappers.ContactWrapper>();

        UtilitiesWrappers.ContactWrapper c1 = new UtilitiesWrappers.ContactWrapper();
        c1.FirstName = 'Samantha';
        c1.LastName = 'Burn';
        UtilitiesWrappers.ContactWrapper c2 = new UtilitiesWrappers.ContactWrapper();
        c2.FirstName = 'MacKenzie';
        c2.LastName = 'Burn';
        UtilitiesWrappers.ContactWrapper c3 = new UtilitiesWrappers.ContactWrapper();
        c3.FirstName = 'Kevin';
        c3.LastName = 'Burn';

        returnList.add(c1);
        returnList.add(c2);
        returnList.add(c3);

        return returnList;
    }

    @TestVisible private list<UtilitiesWrappers.ContactWrapper> getHouseholdContactWrappers(Id accountId){
        try{
            list<Contact> contacts = [SELECT Id,Name,FirstName,LastName,RecordType.DeveloperName FROM Contact WHERE AccountId = :accountId ORDER BY Contact_Type__c];
            list<UtilitiesWrappers.ContactWrapper> returnList = UtilitiesWrappers.createContactWrappers(contacts);
            return returnList;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return null;
        }
    }

    @TestVisible private List<Contact> getRelateContacts(String contactId) {

        List<Contact> contactListToReturn = new List<Contact>();

        try {
            contactListToReturn = [SELECT Id, Name, FirstName, LastName, Account.Name, Email, Phone FROM Contact WHERE Other_Parent__c = :contactId];
            return contactListToReturn;
        } catch (Exception e) {
            System.debug(e.getMessage());
        }
        return null;
    }

    @TestVisible private List<Contact> getRelateContactsByEmail(String conEmail) {

        List<Contact> contactListToReturn = new List<Contact>();

        try {
            contactListToReturn = [SELECT Id, Name, FirstName, LastName, Account.Name, Email, Phone FROM Contact WHERE Other_Parent_Email1__c = :conEmail];
            System.debug(conEmail);
            System.debug(contactListToReturn);
            return contactListToReturn;
        } catch (Exception e) {
            System.debug(e.getMessage());
        }
        return null;
    }


}