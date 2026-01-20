/**
 * Created by Chris Home Desktop on 7/8/2018.
 */

@IsTest
private class CongrComm_EditRelationshipsCtrlTests {

    @TestSetup static void SetupTest(){

        list<Account> accounts = TestObjectFactory.CreateAccounts('test',2);
        insert accounts;

        list<Contact> contacts = TestObjectFactory.CreateContacts('Test',2);
        contacts[0].AccountId = accounts[0].Id;
        contacts[1].AccountId = accounts[1].Id;
        insert contacts;

        list<Relationship_Type__c> relTypes = TestObjectFactory.CreateRelationshipTypes('Test Rel - Rel Test ' , 2);
        insert relTypes;

        list<Relationship_Affiliation__c> relationships = TestObjectFactory.CreateRelationshipAffiliations(2);
        relationships[0].Relationship_Type__c = relTypes[0].Id;
        relationships[0].Contact__c = contacts[0].Id;
        relationships[0].Related_Contact__c = contacts[1].Id;
        relationships[1].Contact__c = contacts[1].Id;
        relationships[1].Related_Contact__c = contacts[0].Id;
        relationships[1].Relationship_Type__c = relTypes[1].Id;
        insert relationships;


    }

    static testMethod void RunEditPageTests() {

        Contact con = [SELECT Id from Contact limit 1];
        Relationship_Affiliation__c relationship_affiliation = [SELECT Id,Relationship_Type__c,Relationship_Type__r.Name FROM Relationship_Affiliation__c limit 1];

        PageReference pr = Page.CongrComm_NewRelationship;
        pr.getParameters().put('cId',con.Id);
        pr.getParameters().put('rId',relationship_affiliation.Id);
        pr.getParameters().put('type','edit');
        Test.setCurrentPage(pr);

        CongrComm_EditRelationshipsCtrl relationshipCtrl = new CongrComm_EditRelationshipsCtrl();
        relationshipCtrl.ContactId = con.Id;
        relationshipCtrl.CurrentContact = con;
        relationshipCtrl.RelationshipIdToDelete = relationship_affiliation.Id;

        relationshipCtrl.getContact(con.Id);
        relationshipCtrl.DeleteRelationship();
        list<CongrComm_EditRelationshipsCtrl.RelationshipWrapper> wrappers = relationshipCtrl.createRelationshipWrappers(new list<Relationship_Affiliation__c>{relationship_affiliation});

        relationshipCtrl.getContactIdFromParam();
        relationshipCtrl.getRelationships(con.Id);

    }
}