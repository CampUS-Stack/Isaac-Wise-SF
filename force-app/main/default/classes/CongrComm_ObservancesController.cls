public class CongrComm_ObservancesController {
    
    Public List<Yahrzeit_Observance__c> observances {get; set;}
    Public List<YahrzeitObservanceWrapper> observanceWrappers {get; set;}
    
    Public CongrComm_ObservancesController() {
        
        User theUser = [SELECT Id, ContactID FROM User WHERE Id = :UserInfo.getUserId()];
        System.debug('theUser: ' + theUser);

        map<Id,Contact> contactMap = getContactMap();
        observances = [SELECT Id, Deceased_Name__c, Relationship__c,Contact__c, Date_of_Death__c, Next_Observance_Date__c
                       FROM Yahrzeit_Observance__c
                       WHERE Contact__c in :contactMap.keySet()
                       ORDER BY Next_Observance_Date__c ASC];
        System.debug('observances: ' + observances);

        this.observanceWrappers = createYahrzeitObservanceWrappers(contactMap,observances);
    }

    @TestVisible public list<YahrzeitObservanceWrapper> createYahrzeitObservanceWrappers(map<Id,Contact> contacts,list<Yahrzeit_Observance__c> observancesToCreate){

        map<Id,YahrzeitObservanceWrapper> observanceMap = new map<Id,YahrzeitObservanceWrapper>();
        for(Yahrzeit_Observance__c curObservance : observancesToCreate){

            if(!contacts.containsKey(curObservance.Contact__c)){
                continue;
            }

            if(!observanceMap.containsKey(curObservance.Contact__c)){
                observanceMap.put(curObservance.Contact__c,new YahrzeitObservanceWrapper());
            }

            YahrzeitObservanceWrapper yow = observanceMap.get(curObservance.Contact__c);
            yow.theContact = contacts.get(curObservance.Contact__c);
            yow.theObservances.add(curObservance);

        }
        return observanceMap.values();
    }

    @TestVisible public map<Id,Contact> getContactMap(){

        set<Id> returnSet = new set<Id>();

        String currentUserId = UserInfo.getUserId();
        returnSet.add(currentUserId);

        Contact currentUserContact = UtilitiesUsers.GetContactForCommunityUser(currentUserId);

        try{
            map<Id,Contact> contact = new map<Id,Contact>([SELECT Id,Name FROM Contact WHERE AccountId = :currentUserContact.AccountId]);
            return contact;
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return null;
        }
    }

    public class YahrzeitObservanceWrapper{

        public Contact theContact {get; set;}
        public list<Yahrzeit_Observance__c> theObservances {get; set;}

        public YahrzeitObservanceWrapper(){
            theObservances = new list<Yahrzeit_Observance__c>();
        }
    }

}