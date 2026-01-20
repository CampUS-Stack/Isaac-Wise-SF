/**
 * Created by Chris Home Office on 1/31/2019.
 */

@IsTest
private class CongrComm_ThanksFreeEventCtrlTests {
    static testMethod void testBehavior() {

        Event__c theEvent = new Event__c();
        theEvent.Name = 'Test';
        insert theEvent;

        PageReference pr = Page.CongrComm_ThanksFreeEvent;
        pr.getParameters().put('pId',theEvent.Id);

        Test.setCurrentPage(pr);

        CongrComm_ThanksFreeEventCtrl ctrl = new CongrComm_ThanksFreeEventCtrl();

        ctrl.getEvent(theEvent.Id);
        ctrl.getUrlParam('pId');

    }
}