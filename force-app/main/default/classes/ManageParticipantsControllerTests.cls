/**
 * Created by Chris Home Desktop on 1/15/2018.
 */
@IsTest
public with sharing class ManageParticipantsControllerTests {


    @IsTest public static void ProcessTestCoverage(){

        Event__c theEvent = new Event__c();
        theEvent.Name = 'test';
        insert theEvent;

        ApexPages.StandardController stdCtrl = new ApexPages.StandardController(theEvent);
        ManageParticipantsController ctrl = new ManageParticipantsController(stdCtrl);

        ctrl.AddSelectedContacts();
        ctrl.changeSortColumn();
        ctrl.ClearAddParticipantForm();
        ctrl.PopulateAttendingContacts();
        ctrl.getAttendingContactId();
        ctrl.getClassSOQLFilter();
        ctrl.getContactNameSOQLFilter();
        ctrl.getContactTypeSOQLFilter();
        ctrl.getEvent(theEvent.Id);

        list<UtilitiesWrappers.ContactWrapper> wraps = ctrl.AttendingContacts;


    }
}