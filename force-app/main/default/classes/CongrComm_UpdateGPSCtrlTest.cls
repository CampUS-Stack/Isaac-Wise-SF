/**
 * Created by zacha on 4/27/2021.
 */

@IsTest
private class CongrComm_UpdateGPSCtrlTest {
    Static TestMethod void GPSCtrl_Test(){
        Contact con = new Contact();
        con.lastname ='Test1';
        con.Contact_Type__c='Child';
        con.Date_of_Birth__c = system.today()-2100;
        con.Grade_Level__c = 'PK';
        insert con;
        Other_Volunteerism__c vol = new Other_Volunteerism__c();
        vol.Start_Date__c = system.today();
        vol.End_Date__c = system.today()+50;
        vol.Contact__c = con.id;
        insert vol;
        ApexPages.currentPage().getParameters().put('cId',con.id);

        CongrComm_UpdateGPSCtrl ctrl= new CongrComm_UpdateGPSCtrl();
        ctrl.communityUserContact  =  con;
        ctrl.ContactToEdit = con;
        ctrl.EditOrg();
        ctrl.AddNewOrg();
        ctrl.SaveContact();

    }
}