public without sharing class AccountFieldUpdateUtility {
    
    public static String CONTACT_TYPE_CHILD = 'Child';
    public static String CONTACT_TYPE_CONTACT_1 = 'Contact 1';
    public static String CONTACT_TYPE_CONTACT_2 = 'Contact 2';
    public static String CONTACT_TYPE_ADULT = 'Additional Adult';
    
    public static void UpdateAgeFieldOnAccounts(list<Id> accountIds) {
        
        if(accountIds == null || accountIds.size() <= 0 ) 
            return ;
        
        List<Account> accountsToProcss = new List<Account>();
        accountsToProcss = [SELECT id, (Select id, Name, Age__c, Contact_Type__c From Contacts) FROM Account Where id in :accountIds];
        
        //System.debug('@@@k@@ ' + accountsToProcss);

        for(Account curAccount : accountsToProcss) {
            
            
            Double oldestChildAge = 0 ;
            Id oldestChild = null;
            Double oldestMemberAge = 0 ;
            Id oldestMember = null;
            Double youngestChildAge  ;
            Id youngestChild = null;
            
            for(Contact currContact : curAccount.Contacts) {
                
                if(currContact.Contact_Type__c == CONTACT_TYPE_CHILD ) {
                    System.debug('youngestChildAge = ' + youngestChildAge +' '+' '+oldestChildAge+' '+ currContact.Age__c  );
                    if(currContact.Age__c >= oldestChildAge) {
                        oldestChildAge = currContact.Age__c ;
                        oldestChild = currContact.Id;
                    }
                    
                    if(youngestChildAge == NULL || currContact.Age__c <= youngestChildAge) {
                        youngestChildAge = currContact.Age__c ;
                        System.debug('youngestChildAge = ' + youngestChildAge +' '+ currContact.Age__c  );
                        youngestChild = currContact.Id;
                    }
                    
                }
                
                else if((currContact.Contact_Type__c == CONTACT_TYPE_CONTACT_1 ||
                         currContact.Contact_Type__c == CONTACT_TYPE_CONTACT_2 ||
                         currContact.Contact_Type__c == CONTACT_TYPE_ADULT
                        )&& currContact.Age__c > oldestMemberAge) {
                            oldestMemberAge = currContact.Age__c ;
                            oldestMember = currContact.Id;
                        }
                
            }
            
            if(oldestMember != null)
                curAccount.Oldest_Member__c = oldestMember;
            
            if(oldestChild != null)
                curAccount.Oldest_Child__c = oldestChild; 
            
            if(youngestChild != null)
                curAccount.Youngest_Child__c = youngestChild;
        }
        update accountsToProcss;
    }
    
    
    
}