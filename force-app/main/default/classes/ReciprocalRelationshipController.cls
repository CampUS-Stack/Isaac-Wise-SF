/**
 * Created by Chris Home Desktop on 5/30/2017.
 */

public with sharing class ReciprocalRelationshipController {

    public static void CreateReciprocalRelationship(Relationship_Affiliation__c relationship){

        Relationship_Type__c relationshipType = getRelationshipType(relationship.Relationship_Type__c);

        Relationship_Affiliation__c newRelationship = new Relationship_Affiliation__c();
        newRelationship.Contact__c = relationship.Related_Contact__c;
        newRelationship.Related_Contact__c = relationship.Contact__c;
        newRelationship.Relationship_Type__c = relationshipType.Other_Relationship__c;

        insert newRelationship;

        relationship.Reciprocal_Relationship__c = newRelationship.Id;

        UpdateRelationshipWithReciprocalRelationship(newRelationship.Id);
    }

    @Future
    public static void UpdateRelationshipWithReciprocalRelationship(String relationshipId){

        try{
            Relationship_Affiliation__c relationship = getRelationship(relationshipId);

            Relationship_Affiliation__c reciprocalRelationship = [SELECT Id FROM Relationship_Affiliation__c WHERE Reciprocal_Relationship__c = :relationshipId];

            relationship.Reciprocal_Relationship__c = reciprocalRelationship.Id;

            update relationship;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
        }


    }

    @TestVisible private static Relationship_Affiliation__c getRelationship(Id relationshipId){

        try{
            Relationship_Affiliation__c rel = [SELECT Id,Reciprocal_Relationship__c FROM Relationship_Affiliation__c WHERE Id = :relationshipId];
            return rel;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return null;
        }
    }

    @TestVisible private static Relationship_Type__c getRelationshipType(Id relationshipTypeId){

        try{
            Relationship_Type__c relType = [SELECT Id,Other_Relationship__r.Name,Other_Relationship__c FROM Relationship_Type__c WHERE Id = :relationshipTypeId];
            return relType;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return null;
        }
    }
}