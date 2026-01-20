///
/// @Author: Chris Gibson
/// @Date: 12.4.2014
///
/// @Purpose: This class is used to create objects in one centralized locations. If required fields change or are modified one place
///				in code can be modified to refelct those values
///
public without sharing class TestObjectFactory {

    private static User communityUser;
    private static UserRole userRole;

    ///
    /// @Author: Chris Gibson
    /// @Date: 12.04.2014
    ///
    /// @Purpose: this method creates a trigger state class with the specificed trigger object name
    ///
    /// @Params: objectName - String object representing the name for the TriggerObject value of the trigger state
    ///
    /// @Returns: A TriggerState object with isInsert and isBefore set to true
    ///
    public static TriggerState CreateTriggerState(String objectName){

        TriggerState ts = new TriggerState(objectName,true,false,true,false,false,false,
                new list<SObject>(),new map<Id,SObject>(),new list<SObject>(),new map<Id,SObject>());

        return ts;
    }

    ///
    /// @Author: Chris Gibson
    /// @Date: 12.04.2014
    ///
    /// @Purpose: this method creates a trigger state class with the specificed trigger object name and isAfter value
    ///
    /// @Params: objectName - String object representing the name for the TriggerObject value of the trigger state
    ///			 isAfter - a boolean object representing the isAfter attribute of the trigger state
    ///
    /// @Returns: A TriggerState object with isInsert set to true and an objectName specified within param as well
    ///					as the isAfter attribute being reflected by the parameter
    ///
    public static TriggerState CreateTriggerState(String objectName,Boolean isAfter){

        if(!isAfter){
            return TestObjectFactory.CreateTriggerState(objectName);
        }

        TriggerState ts = new TriggerState(objectName,false,isAfter,true,false,false,false,
                new list<SObject>(),new map<Id,SObject>(),new list<SObject>(),new map<Id,SObject>());

        return ts;

    }

    public static list<SObject> CreateObjectsWithName(Schema.SObjectType sobjectType,Integer numberToCreate){

        list<SObject> returnList = new list<SObject>();
        for(Integer i = 0; i < numberToCreate; i++){
            SObject curSObject = sobjectType.newSObject();
            returnList.add(curSObject);
        }
        return returnList;
    }

    public static list<SObject> CreateAccounts(String nameToUse, Integer numberToCreate){

        list<SObject> returnList = CreateObjectsWithName(Account.SObjectType,numberToCreate);
        for(Integer i = 0; i < numberToCreate; i++){
            returnList[i].put('Name',nameToUse + ' ' + i);
        }
        return returnList;
    }

    public static list<SObject> CreateContacts(String nameToUse, Integer numberToCreate){

        list<SObject> returnList = CreateObjectsWithName(Contact.SObjectType,numberToCreate);
        for(Integer i = 0; i < numberToCreate; i++){
            returnList[i].put('LastName',nameToUse + ' ' + i);
        }
        return returnList;
    }

    public static list<SObject> CreateDesignations(String nameToUse, Integer numberToCreate){

        list<SObject> returnList = CreateObjectsWithName(Designation__c.SObjectType,numberToCreate);
        for(Integer i = 0; i < numberToCreate; i++){
            returnList[i].put('Name',nameToUse + ' ' + i);
        }
        return returnList;
    }


    public static list<SObject> CreateAssessments(Integer numberToCreate, Decimal amountToAssess){

        list<SObject> returnList = CreateObjectsWithName(Assessment__c.SObjectType,numberToCreate);
        for(Integer i = 0; i < numberToCreate; i++){
            returnList[i].put('Assessed_Amount__c',amountToAssess);
        }
        return returnList;
    }

    public static list<SObject> CreateBatches(Integer numberToCreate){

        list<SObject> returnList = CreateObjectsWithName(Batch__c.SObjectType,numberToCreate);
        for(Integer i = 0; i < numberToCreate; i++){
            returnList[i].put('Status__c','Un-Summarized');
        }
        return returnList;
    }

    public static list<Fair_Share__c> CreateFairShare(Integer numberToCreate){

        list<SObject> returnList = CreateObjectsWithName(Fair_Share__c.SObjectType,numberToCreate);
        for(Integer i = 0; i < numberToCreate; i++){
            returnList[i].put('Fiscal_Year__c','2023-2024');
        }
        return returnList;
    }

    public static list<SObject> CreateRelationshipAffiliations(Integer numberToCreate){

        list<SObject> returnList = CreateObjectsWithName(Relationship_Affiliation__c.SObjectType,numberToCreate);
//        for(Integer i = 0; i < numberToCreate; i++){
//            returnList[i].put('Status__c','Un-Summarized');
//        }
        return returnList;
    }

    public static list<SObject> CreateRelationshipTypes(String nameToUse, Integer numberToCreate){

        list<SObject> returnList = CreateObjectsWithName(Relationship_Type__c.SObjectType,numberToCreate);
        for(Integer i = 0; i < numberToCreate; i++){
            returnList[i].put('Name',nameToUse + ' ' + i);
        }
        return returnList;
    }

    public static list<SObject> CreateYahrzeits(Integer numberToCreate){

        list<SObject> returnList = CreateObjectsWithName(Yahrzeit__c.SObjectType,numberToCreate);
        return returnList;
    }

    public static list<SObject> CreatePaymentVaults(String nameToUse, Integer numberToCreate){

        list<SObject> returnList = CreateObjectsWithName(Payment_Vault__c.SObjectType,numberToCreate);
        return returnList;
    }

    public static User CreateCommunityTestUser(Boolean createNew){

        if(communityUser != null && !createNew){
            return communityUser;
        }



        if(userRole != null){
            userRole = new UserRole(DeveloperName = 'TestRole', Name = 'My Role');
            insert userRole;
        }

        Account ac = (Account)CreateAccounts('test',1)[0];
        ac.OwnerId = UserInfo.getUserId();
        insert ac;

        Contact con = (Contact)CreateContacts('test',1)[0];
        con.AccountId = ac.Id;
        insert con;

        String randomNum = String.valueOf(System.now());
        String theUserName = 'test' + randomNum + '@test.com';
        User user = new User(alias = 'test123', email='test123@noemail.com',
                emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
                localesidkey='en_US', profileid = [SELECT Id FROM Profile WHERE Name = 'Wise Community Member'].Id,
                country='United States',IsActive =true,ContactId = con.Id,
                timezonesidkey='America/Los_Angeles', username= theUserName );

        insert user;
        communityUser = user;
        return user;

    }

    public static list<SObject> CreatePaymentAdjustments(Integer numberToCreate){

        list<SObject> returnList = CreateObjectsWithName(Payment_Adjustment__c.SObjectType,numberToCreate);
        return returnList;
    }


    public static FinancialTestScenario GetFinancialTestScenario(){
        FinancialTestScenario returnScenario = new FinancialTestScenario();
        return returnScenario;
    }

    public class FinancialTestScenario{

        public list<Account> accounts {get; set;}
        public list<Contact> contacts {get; set;}
        public list<Designation__c> designations {get; set;}
        public list<Assessment__c> assessments {get; set;}
        public list<Scheduled_Payment__c> scheduledPayments {get; set;}

        public FinancialTestScenario(){

            this.accounts = TestObjectFactory.CreateAccounts('Test',2);
            this.contacts = TestObjectFactory.CreateContacts('Test',2);
            this.designations = TestObjectFactory.CreateDesignations('test',2);
            this.assessments = TestObjectFactory.CreateAssessments(2,200.00);

        }
    }

}