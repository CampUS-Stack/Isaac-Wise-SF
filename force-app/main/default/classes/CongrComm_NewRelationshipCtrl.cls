/**
 * Created by Chris Home Desktop on 4/24/2018.
 */

public without sharing class CongrComm_NewRelationshipCtrl {

    public Contact currentContact {get; set;}
    public Boolean ContactSelected {get; set;}
    public Boolean SearchRan {get; set;}
    public String SelectedContactId {get; set;}
    public Contact SelectedContact {get; set;}
    public Relationship_Affiliation__c Relationship {get; set;}
    public String ChosenRelationshipTypeFirstName {get; set;}
    public String ChosenRelationshipTypeSecondName {get; set;}

    //// This select option lists represents all the relationship type names it can find and split to have the first portion of the "-".
    //// Example: RelationshipType Name = 'Dad - Daughter' ; This select list would have "Dad"
    public list<SelectOption> FirstNameRelationshipTypes {
        get{
            list<SelectOption> returnList = new list<SelectOption>();
            try{
                list<Relationship_Type__c> relTypes = [SELECT Name from Relationship_Type__c WHERE Other_Relationship__c != null];
                for(Relationship_Type__c curRelType : relTypes){
                    if(!curRelType.Name.contains('-')){
                        continue;
                    }

                    list<String> names = curRelType.Name.split('-');
                    SelectOption theOption = new SelectOption(names[0],names[0]);
                    returnList.add(theOption);
                }
            }
            catch(QueryException qe){
                system.debug(qe.getMessage());
            }
            return returnList;
        }
    }

    public list<SelectOption> SecondNameRelationshipTypes {
        get{
            list<SelectOption> returnList = new list<SelectOption>();
            try{

                if(String.isBlank(ChosenRelationshipTypeFirstName)){
                    return returnList;
                }
                String soql = 'SELECT Name from Relationship_Type__c WHERE Other_Relationship__c != null';
                soql += ' AND Name LIKE \'' + ChosenRelationshipTypeFirstName + '-%\'';
                list<Relationship_Type__c> relTypes = DataBase.query(soql);
                for(Relationship_Type__c curRelType : relTypes){
                    if(!curRelType.Name.contains('-')){
                        continue;
                    }

                    list<String> names = curRelType.Name.split('-');
                    SelectOption theOption = new SelectOption(names[1],names[1]);
                    returnList.add(theOption);
                }
            }
            catch(QueryException qe){
                system.debug(qe.getMessage());
            }
            return returnList;
        }
    }

    public list<UtilitiesWrappers.ContactWrapper> ContactResults {get; set;}

    public Integer NumberOfResults{
        get{
            if(ContactResults == null || ContactResults.size() == 0){
                return 0;
            }
            else{
                return ContactResults.size();
            }
        }
    }

    public String FirstName {get; set;}
    public String LastName {get; set;}

    public String PageEditType {get; set;}

    public CongrComm_NewRelationshipCtrl(){

        this.PageEditType = getPageEditType();
        this.currentContact = getContact(getContactIdFromParam());
        this.SearchRan = false;

        if(this.PageEditType == 'new'){
            RunContactSearch();
        }
        else{
            setupEditPageVariables();
        }
    }

    public PageReference RunContactSearch(){

        if(!isPageValid()){
            return null;
        }

        this.SearchRan = true;
        this.ContactResults = searchForContacts();
        ContactSelected = false;
        return null;
    }

    public PageReference SelectContact(){

        ContactSelected = true;
        for(UtilitiesWrappers.ContactWrapper curWrap : this.ContactResults){
            if(curWrap.theContact.Id == this.SelectedContactId){
                this.SelectedContact = curWrap.theContact;
            }
        }
        ContactResults = new list<UtilitiesWrappers.ContactWrapper>();
        return null;
    }

    public PageReference CreateRelationship(){
        try{
            String relTypeName = this.ChosenRelationshipTypeFirstName + '-' + this.ChosenRelationshipTypeSecondName;
            system.debug('Relationship Type Name: ' + relTypeName);
            Relationship_Type__c relType = [SELECT Id FROM Relationship_Type__c WHERE Name = :relTypeName limit 1];
            Relationship_Affiliation__c newRelationship = new Relationship_Affiliation__c();
            newRelationship.Relationship_Type__c = relType.Id;
            newRelationship.Contact__c = currentContact.Id;
            newRelationship.Related_Contact__c = SelectedContactId;
            insert newRelationship;
        }
        catch(DmlException de){
            system.debug(de.getMessage());
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
        }

        PageReference pr = Page.CongrComm_EditRelationships;
        pr.getParameters().put('cId',currentContact.Id);
        pr.setRedirect(true);
        return pr;
    }

    public PageReference UpdateRelationship(){
        try{
            String relTypeName = this.ChosenRelationshipTypeFirstName + '-' + this.ChosenRelationshipTypeSecondName;
            system.debug('Relationship Type Name: ' + relTypeName);
            Relationship_Type__c relType = [SELECT Id FROM Relationship_Type__c WHERE Name = :relTypeName limit 1];
            Relationship.Relationship_Type__c = relType.Id;
            update this.Relationship;
        }
        catch(DmlException de){
            system.debug(de.getMessage());
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
        }

        PageReference pr = Page.CongrComm_EditRelationships;
        pr.getParameters().put('cId',currentContact.Id);
        pr.setRedirect(true);
        return pr;
    }

    @TestVisible private void setupEditPageVariables(){

        Id relationshipId = getRelationshipIdFromParam();
        this.Relationship = getRelationship(relationshipId);
        this.SelectedContact = getContact(this.Relationship.Related_Contact__c);
        this.ContactSelected = true;

    }

    @TestVisible private String getContactIdFromParam(){

        if(ApexPages.currentPage().getParameters().containsKey('cId')){
            return ApexPages.currentPage().getParameters().get('cId');
        }
        else{
            return '';
        }
    }

    @TestVisible private String getPageEditType(){

        if(ApexPages.currentPage().getParameters().containsKey('type')){
            return ApexPages.currentPage().getParameters().get('type');
        }
        else{
            return 'new';
        }
    }

    @TestVisible private String getRelationshipIdFromParam(){

        if(ApexPages.currentPage().getParameters().containsKey('rId')){
            return ApexPages.currentPage().getParameters().get('rId');
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

    @TestVisible private Relationship_Affiliation__c getRelationship(Id relationshipId){
        try{
            Relationship_Affiliation__c returnRelationship = [SELECT Id,Name,Related_Contact__c FROM Relationship_Affiliation__c WHERE Id = :relationshipId];
            return returnRelationship;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return null;
        }
    }

    @TestVisible private list<UtilitiesWrappers.ContactWrapper> searchForContacts(){

        try{
            String soql = 'SELECT Id,Name,Birthdate,Account.Name FROM Contact WHERE ';

            soql += getFirstNameSOQLCondition();
            soql += getLastNameSOQLCondition();
            soql += getMemberSOQLCondition();
            soql += getCurrentContactSOQLCondition();

            soql += ' ORDER BY Account.Name';

            list<Contact> contacts = Database.query(soql);
            return UtilitiesWrappers.createContactWrappers(contacts);
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return null;
        }
    }

    @TestVisible private Boolean isPageValid(){

        if(String.isEmpty(FirstName) && String.isEmpty(LastName)){
            return false;
        }
        return true;
    }

    @TestVisible private String getCurrentContactSOQLCondition(){

        return ' Id != \'' + this.currentContact.Id + '\'';
    }

    @TestVisible private String getFirstNameSOQLCondition(){
        if(!String.isEmpty(this.FirstName)){
            return '(FirstName like \'%' + this.FirstName.trim() + '%\' OR Nickname__c like \'%' + this.FirstName.trim() + '%\') AND ';
        }
        else{
            return '';
        }
    }

    @TestVisible private String getLastNameSOQLCondition(){
        if(!String.isEmpty(this.LastName)){
            return 'LastName like \'%' + this.LastName.trim() + '%\' AND';
        }
        else{
            return '';
        }
    }

    @TestVisible private String getMemberSOQLCondition(){
        return ' Account.Is_Current_Member__c = true AND';
    }
}