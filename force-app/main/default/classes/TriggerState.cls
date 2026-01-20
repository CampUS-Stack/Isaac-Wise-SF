/**
 * Created by Chris Gibson on 5/21/2017.
 */

public with sharing class TriggerState {

    public String TriggerObject { get; set;}

    public Boolean IsBefore {get; set;}
    public Boolean IsAfter {get; set;}
    public Boolean IsDelete {get; set;}
    public Boolean IsExecuting {get; set;}
    public Boolean IsUpdate {get; set;}
    public Boolean IsInsert {get; set;}
    public list<SObject> NewList {get; set;}
    public list<SObject> OldList {get; set;}
    public map<Id,SObject> NewMap {get; set;}
    public map<Id,SObject> OldMap {get; set;}

    public TriggerState(Boolean isBefore, Boolean isAfter, Boolean isUpdate, Boolean isDelete,
            Boolean isInsert, Boolean isExecuting, list<SObject> newList, map<ID,SObject> newMap, list<SObject> oldList, map<ID,SObject> oldMap) {

        this.IsBefore = isBefore;
        this.IsAfter = isAfter;
        this.IsUpdate = isUpdate;
        this.IsDelete = isDelete;
        this.IsInsert = isInsert;
        this.IsExecuting = isExecuting;
        this.NewList = newList;
        this.OldList = oldList;
        this.NewMap = newMap;
        this.OldMap = oldMap;
        setTriggerObjectName();
    }

    public TriggerState(String triggerObject, Boolean isBefore, Boolean isAfter, Boolean isUpdate, Boolean isDelete,
            Boolean isInsert, Boolean isExecuting, list<SObject> newList, map<ID,SObject> newMap, list<SObject> oldList, map<ID,SObject> oldMap) {

        this.TriggerObject = triggerObject;
        this.IsBefore = isBefore;
        this.IsAfter = isAfter;
        this.IsUpdate = isUpdate;
        this.IsDelete = isDelete;
        this.IsInsert = isInsert;
        this.IsExecuting = isExecuting;
        this.NewList = newList;
        this.OldList = oldList;
        this.NewMap = newMap;
        this.OldMap = oldMap;
    }

    @TestVisible private void setTriggerObjectName(){

        if(IsDelete){
            this.TriggerObject = OldList.getSObjectType().getDescribe().getLocalName();

        }else{
            this.TriggerObject = NewList.getSObjectType().getDescribe().getLocalName();
        }
    }
}