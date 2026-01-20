/**
 * Created by Chris Home Desktop on 10/23/2017.
 */

public with sharing class UtilitiesSObject {

    // Build a local cache so that we don't request this multiple times
    private static Map<Schema.SObjectType,Map<String,Id>> rtypesCache;

    static {
        rtypesCache = new Map<Schema.SObjectType,Map<String,Id>>();
    }



    public static Id getRecordTypeId(String recordTypeDevName, Schema.SObjectType objectType){
        Map<String, Id> developerNameToTypeId = GetRecordTypeIdsByDeveloperName(objectType);

        system.debug('Record Type Developer Name: ' + recordTypeDevName);
        system.debug('Developer Name To Type Id: ' + developerNameToTypeId.keySet());
        system.debug('record type Id: ' + developerNameToTypeId.get(recordTypeDevName));

        return developerNameToTypeId.get(recordTypeDevName);
    }

    // Returns a map of active, user-available RecordType IDs for a given SObjectType,
    // keyed by each RecordType's unique, unchanging DeveloperName
    public static Map<String, Id> GetRecordTypeIdsByDeveloperName(Schema.SObjectType token) {

        // Do we already have a result?
        Map<String, Id> mapRecordTypes = rtypesCache.get(token);

        // If not, build a map of RecordTypeIds keyed by DeveloperName
        if (mapRecordTypes == null) {
            mapRecordTypes = new Map<String, Id>();
            rtypesCache.put(token,mapRecordTypes);
        } else {
            // If we do, return our cached result immediately!
            return mapRecordTypes;
        }

        // Get the Describe Result
        Schema.DescribeSObjectResult obj = token.getDescribe();

        // Obtain ALL Active Record Types for the given SObjectType token
        // (We will filter out the Record Types that are unavailable
        // to the Running User using Schema information)
        String soql =
                'SELECT Id, Name, DeveloperName '
                        + 'FROM RecordType '
                        + 'WHERE SObjectType = \'' + String.escapeSingleQuotes(obj.getName()) + '\' '
                        + 'AND IsActive = TRUE';
        List<SObject> results;
        try {
            results = Database.query(soql);
        } catch (Exception ex) {
            results = new List<SObject>();
        }

        // Obtain the RecordTypeInfos for this SObjectType token
        Map<Id,Schema.RecordTypeInfo> recordTypeInfos = obj.getRecordTypeInfosByID();

        // Loop through all of the Record Types we found,
        //      and weed out those that are unavailable to the Running User
        for (SObject rt : results) {
            if (recordTypeInfos.get(rt.Id).isAvailable()) {
                // This RecordType IS available to the running user,
                //      so add it to our map of RecordTypeIds by DeveloperName
                mapRecordTypes.put(String.valueOf(rt.get('DeveloperName')),rt.Id);
            }
        }

        return mapRecordTypes;
    }

    public static set<String> getSetOfFieldValues(List<sObject> objects, String fieldName){
        Set<String> fieldValues = new Set<String>();

        for(sObject currentObject: objects){
            Object fieldValueObject = currentObject.get(fieldName);

            if(fieldValueObject != null){
                String fieldValue = (String)fieldValueObject;
                fieldValues.add(fieldValue);
            }
        }

        return fieldValues;
    }

    public static map<String,list<SObject>> GetMapOfSObjectListForFieldValues(List<sObject> objects, String fieldName){

        map<String,list<SObject>> returnMap = new map<String,list<SObject>>();

        for(sObject currentObject: objects){
            Object fieldValueObject = currentObject.get(fieldName);
            if(fieldValueObject == null){
                continue;
            }
            String fieldValueText = String.valueOf(fieldValueObject);
            if(returnMap.containsKey(fieldValueText)){
                returnMap.get(fieldValueText).add(currentObject);
            }
            else{
                returnMap.put(fieldValueText,new list<Sobject>{currentObject});
            }
        }

        return returnMap;
    }

    public static map<String,SObject> GetMapOfSObjectForFieldValues(List<sObject> objects, String fieldName){

        map<String,SObject> returnMap = new map<String,SObject>();

        for(sObject currentObject: objects){
            Object fieldValueObject = currentObject.get(fieldName);
            if(fieldValueObject == null){
                continue;
            }
            String fieldValueText = String.valueOf(fieldValueObject);
            if(!returnMap.containsKey(fieldValueText)){
                returnMap.put(fieldValueText,currentObject);
            }
        }

        return returnMap;
    }

    public static Double GetTotalOfAllFieldValues(list<SObject> objects,String fieldName){
        Double returnValue = 0;

        for(sObject currentObject: objects){
            Object fieldValueObject = currentObject.get(fieldName);

            if(fieldValueObject != null){
                Double fieldValue = Double.valueOf(fieldValueObject);
                returnValue += fieldValue;
            }
        }
        return returnValue;
    }

    public static List<String> GetPicklistFieldValues(Schema.SObjectType objectType, String fieldName){
        Schema.DescribeSObjectResult result = objectType.getDescribe();
        Map<String, Schema.SObjectField> fields = result.fields.getMap();
        Schema.DescribeFieldResult fieldResult = fields.get(fieldName).getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        List<String> picklistValues = new List<String>();
        for(Schema.PicklistEntry picklistVal : ple){
            picklistValues.add(picklistVal.getLabel());
        }
        return picklistValues;
    }

}