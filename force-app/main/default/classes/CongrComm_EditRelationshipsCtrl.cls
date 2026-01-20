public without sharing class CongrComm_EditRelationshipsCtrl {

    public String ContactId {get; set;}
    public Contact CurrentContact {get; set;}

    public String RelationshipIdToDelete {get; set;}

    public list<RelationshipWrapper> RelationshipWrappers {get; set;}

    public CongrComm_EditRelationshipsCtrl(){

        this.contactId = getContactIdFromParam();
        this.CurrentContact = getContact(this.contactId);
        this.RelationshipWrappers = getRelationships(this.CurrentContact.Id);
    }

    public PageReference DeleteRelationship(){

        system.debug('Delete Relationship Called. ' + this.RelationshipIdToDelete);

        if(String.isBlank(RelationshipIdToDelete)){
            return null;
        }

        list<Relationship_Affiliation__c> relsToDelete = new list<Relationship_Affiliation__c>();
        for(RelationshipWrapper curRel : this.RelationshipWrappers){
            if(curRel.Relationship.Id == this.RelationshipIdToDelete){
                relsToDelete.add(curRel.Relationship);
                break;
            }
        }

        try{

            Relationship_Affiliation__c otherRel = [SELECT Id FROM Relationship_Affiliation__c WHERE Reciprocal_Relationship__c = :this.RelationshipIdToDelete];
            relsToDelete.add(otherRel);
            if(relsToDelete != null && relsToDelete.size() > 0){
                delete relsToDelete;
            }

            this.RelationshipWrappers = getRelationships(this.CurrentContact.Id);
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
        }
        catch(DmlException de){
            system.debug(de.getMessage());
        }
        return null;
    }

    @TestVisible private String getContactIdFromParam(){

        if(ApexPages.currentPage().getParameters().containsKey('cId')){
            return ApexPages.currentPage().getParameters().get('cId');
        }
        else{
            return '';
        }
    }

    @TestVisible private Contact getContact(Id contactId){
        try{
            Contact returnContact = [SELECT Id,Name FROM Contact WHERE Id = :contactId];
            return returnContact;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return null;
        }
    }

    @TestVisible private list<RelationshipWrapper> getRelationships(Id contactId){
        try{
            list<Relationship_Affiliation__c> relationships = [SELECT Id,Name,Related_Contact__r.Name,Relationship_Type__r.Name FROM Relationship_Affiliation__c WHERE Contact__c = :contactId AND Related_Contact__r.Is_Current_Member__c = true];
            list<RelationshipWrapper> returnList = createRelationshipWrappers(relationships);
            return returnList;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return null;
        }
    }

    @TestVisible private list<RelationshipWrapper> createRelationshipWrappers(list<Relationship_Affiliation__c> relationships){

        list<RelationshipWrapper> relationshipWrappers = new list<RelationshipWrapper>();
        for(Relationship_Affiliation__c curRelationship : relationships){
            RelationshipWrapper curWrap = new RelationshipWrapper();
            curWrap.Relationship = curRelationship;
            curWrap.RelationshipName = curRelationship.Relationship_Type__r.Name.substring(0,curRelationship.Relationship_Type__r.Name.indexOf('-'));
            relationshipWrappers.add(curWrap);
        }
        return relationshipWrappers;
    }

    public class RelationshipWrapper{

        public Relationship_Affiliation__c Relationship {get; set;}
        public String RelationshipName {get; set;}

        public RelationshipWrapper(){}
    }

}