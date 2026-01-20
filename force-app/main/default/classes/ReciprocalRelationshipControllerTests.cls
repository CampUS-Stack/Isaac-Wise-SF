/**
 * Created by Chris Home Desktop on 8/16/2017.
 */
@IsTest
public with sharing class ReciprocalRelationshipControllerTests {

    @IsTest public static void ProcessTestCoverage(){

        Contact c = new Contact();
        c.FirstName = 'test';
        c.LastName = 'test';
        insert c;

        Contact c2 = new Contact();
        c2.FirstName = 'test 2';
        c2.LastName = 'test 2';
        insert c2;

        Relationship_Type__c relType1 = new Relationship_Type__c();
        relType1.Name = 'Son - Father';
        insert relType1;

        Relationship_Type__c relType = new Relationship_Type__c();
        relType.Name = 'Father - Son';
        relType.Other_Relationship__c = relType1.Id;
        insert relType;

        relType1.Other_Relationship__c = relType.Id;
        update relType1;

        Relationship_Affiliation__c ra = new Relationship_Affiliation__c();
        ra.Contact__c = c.Id;
        ra.Relationship_Type__c = relType.Id;
        ra.Related_Contact__c = c2.Id;
        insert ra;



        ReciprocalRelationshipController.CreateReciprocalRelationship(ra);

    }
}