/**
 * Created by Chris Home Desktop on 5/29/2017.
 */

public with sharing class YahrzeitCreationController {


    public static void RunAfterYahrzeitCreationProcesses(list<Contact> contacts){

//        map<Id,Contact> contactMap = new map<Id,Contact>(contacts);
//        contactMap = new map<Id,Contact>([SELECT Id,Account.Contact_1__c,Account.Contact_2__c FROM Contact WHERE Id in :contactMap.keyset()]);
//
//        String formerHouseholdId = UtilitiesYahrzeit.GetFormerMemberHouseholdId();
//        set<Id> contact1accountIds = new set<Id>();
//        set<Id> contact2accountIds = new set<Id>();
//        list<Account> allAccounts = new list<Account>();
//        for(Contact curContact : contacts){
//
//            Contact queriedContact = contactMap.get(curContact.Id);
//            if(curContact.Id == queriedContact.Account.Contact_1__c){
//                contact1accountIds.add(curContact.AccountId);
//            }
//            else if(curContact.Id == queriedContact.Account.Contact_2__c){
//                contact2accountIds.add(curContact.AccountId);
//            }
////            curContact.AccountId = formerHouseholdId;
////            curContact.Contact_Type__c = 'Deceased';
//        }
//
//        list<Account> contact1Accounts = [SELECT Id,Contact_1__c FROM Account WHERE Id IN :contact1accountIds];
//        for(Account curAccount : contact1Accounts){
//            curAccount.Contact_1__c = null;
//            allAccounts.add(curAccount);
//        }
//        list<Account> contact2Accounts = [SELECT Id,Contact_2__c FROM Account WHERE Id IN :contact2accountIds];
//        for(Account curAccount : contact2Accounts){
//            curAccount.Contact_2__c = null;
//            allAccounts.add(curAccount);
//        }
//
//        update allAccounts;
    }


    public static list<Yahrzeit__c> RunBeforeYahrzeitCreationProcesses(list<Contact> contacts){

        list<Yahrzeit__c> yahrzeitsToInsert = createYahrzeits(contacts);
        insert yahrzeitsToInsert;

        return yahrzeitsToInsert;
    }

    @TestVisible private static list<Yahrzeit__c> createYahrzeits(list<Contact> contacts){
        list<Yahrzeit__c> yahrzeitsToInsert = new list<Yahrzeit__c>();

        for(Contact curCon : contacts) {

            Yahrzeit__c yahrzeit = new Yahrzeit__c();
            yahrzeit.Deceased__c = curCon.Id;
            yahrzeit.Eng_Death_Date__c = curCon.Date_of_Death__c;
            yahrzeit.RecordTypeId = UtilitiesSObject.getRecordTypeId('Yahrzeit',Yahrzeit__c.SObjectType);
            yahrzeitsToInsert.add(yahrzeit);
        }

        return yahrzeitsToInsert;
    }
}