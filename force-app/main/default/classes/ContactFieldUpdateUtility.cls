/**
 * Created by Chris Home Desktop on 5/29/2017.
 */

public with sharing class ContactFieldUpdateUtility {

    public static void UpdateTorahFieldForBarmitsvah(list<Contact> contacts){

        list<String> torahPortionNames = new list<String>();
        map<Id,String> torahPortionsByContactId = new map<Id,String>();
        map<String,Torah_Portion__c> torahPortionsByName = new map<String,Torah_Portion__c> ();

        for(Contact curContact : contacts){
            String torahDateName = Datetime.newInstance(curContact.Bar_Bat_Mitzvah_Date__c,Time.newInstance(0,0,0,0)).format('M/d/YYYY');
            system.debug(torahDateName);
            torahPortionsByContactId.put(curContact.Id,torahDateName);
        }

        try{
            list<Torah_Portion__c> torahPortions = [SELECT Id,Name FROM Torah_Portion__c WHERE Name IN :torahPortionsByContactId.values()];

            if(torahPortions.size() <= 0){
                return;
            }

            for(Torah_Portion__c curTorahPortion : torahPortions){
                system.debug(curTorahPortion);
                torahPortionsByName.put(curTorahPortion.Name,curTorahPortion);
            }
        }
        catch(QueryException qe){
            system.debug(qe.getMessage());
            return;
        }

        for(Contact curContact : contacts){
            String torahName = torahPortionsByContactId.get(curContact.Id);
            system.debug(torahName);
            Torah_Portion__c torahPortion = torahPortionsByName.get(torahName);
            system.debug(torahPortion);
            if(torahPortion != null)
                curContact.Date_Torah_Portion__c = torahPortion.Id;
        }

    }

}