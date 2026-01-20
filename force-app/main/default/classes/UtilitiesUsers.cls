/**
 * Created by Chris Home Desktop on 4/7/2018.
 */

public with sharing class UtilitiesUsers {

    public static final String CONTACT_DEFAULT_QUERY_FIELDS = 'Id,Name,FirstName,LastName,AccountId,Nickname__c, Email, ' +
            'Account.Family_Id__c ';

    /**
     * @Author: Chris Gibson
     * @Date: 4.7.2018
     *
     * @description This method will return the contact record for a user ID. This method is intented to be used with Portal and Community users.
     *
     * @param userId - an ID representing the user record to search on behalf of.
     * @param contactQueryFields - a string that should hold comma separated fields to include in the query.
     *
     * @return a Contact SObject representing the contact found for the given user id. Null is returned if no contacts are found.
     */
    public static Contact GetContactForCommunityUser(Id userId,String contactQueryFields) {
        try{
            User u = [SELECT id, ContactID From User Where Id =:userId];
            String contactSOQL = 'SELECT ' + contactQueryFields + ' FROM Contact WHERE Id = \'' + u.ContactId + '\'';
            Contact returnContact = Database.query(contactSOQL);
            return returnContact;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return null;
        }

    }

    /**
     * @Author: Chris Gibson
     * @Date: 4.7.2018
     *
     * @description This method will return the contact record for a user ID. This method is intented to be used with Portal and Community users.
     *
     * @param userId - an ID representing the user record to search on behalf of.
     *
     * @return a Contact SObject representing the contact found for the given user id. Null is returned if no contacts are found.
     */
    public static Contact GetContactForCommunityUser(Id userId) {

        return GetContactForCommunityUser(userId,CONTACT_DEFAULT_QUERY_FIELDS);
    }

    public static Boolean GetIsSandboxEnvironment(){
        Organization org = [SELECT IsSandbox from Organization WHERE Id = :UserInfo.getOrganizationId()];
        return org.IsSandbox;
    }
}