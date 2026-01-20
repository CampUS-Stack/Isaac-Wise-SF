/**
 * Created by Chris Home Office on 12/6/2018.
 */

public with sharing class UtilitiesEvents {

    public static final String CONTACT_SOQL_FIELDS = 'Id,Name,FirstName,LastName FROM Contact';
    public static Integer ADDITIONAL_SEARCH_COUNT = 10;


    public static list<CongrComm_EventUtilities.registrantWrapper>  getAdditionalRegistrantResults(String firstName, String lastName,Event__c theEvent){
        list<CongrComm_EventUtilities.registrantWrapper> returnList = new list<CongrComm_EventUtilities.registrantWrapper>();
        if(String.isBlank(FirstName) && String.isBlank(LastName) ){
            return null;
        }

        try{
            String FirstNameToCompare = '\'%' + FirstName + '%\'';
            String LastNameToCompare = '\'%' + LastName + '%\'';
            String soql = 'SELECT ' + CONTACT_SOQL_FIELDS + '  WHERE Account.Directory_Opt_out__c = false AND Account.Is_Current_Member__c = true ';
            String firstNameSoqlCondition = getContactSOQLFirstNameCondition(firstName);
            if(String.isNotBlank(firstNameSoqlCondition)){
                soql += ' AND ' + firstNameSoqlCondition;
            }
            String lastNameSoqlCondition = getContactSOQLLastNameCondition(lastName);
            if(String.isNotBlank(lastNameSoqlCondition)){
                soql += ' AND ' + lastNameSoqlCondition;
            }

            soql += ' limit ' + ADDITIONAL_SEARCH_COUNT;
            list<Contact> contacts = Database.query(soql);
            for(Contact curCon : contacts){
                CongrComm_EventUtilities.registrantWrapper wrap = CongrComm_EventUtilities.createRegistrantWrapper(curCon,theEvent);
                returnList.add(wrap);
            }

            return returnList;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return null;
        }
    }


    @TestVisible private static String getContactSOQLFirstNameCondition(String firstName){

        if(String.isNotBlank(FirstName)){
            return ' FirstName like \'%' + FirstName + '%\'';
        }
        else{
            return '';
        }
    }

    @TestVisible private static String getContactSOQLLastNameCondition(String lastName){

        if(String.isNotBlank(LastName)){
            return ' LastName like \'%' + LastName + '%\'';
        }
        else{
            return '';
        }
    }
}