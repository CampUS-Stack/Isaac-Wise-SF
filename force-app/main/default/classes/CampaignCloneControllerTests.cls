/**
 * Created by Chris Home Desktop on 8/14/2017.
 */

@IsTest
private class CampaignCloneControllerTests {
    static testMethod void testBehavior() {

        Campaign theCampaign = new Campaign();
        theCampaign.Name = 'test';
        insert theCampaign;

        CampaignCloneController ctrl = new CampaignCloneController();
        ctrl.Save();
        ctrl.Cancel();

        String testVar = ctrl.PreviousCampaignId;
        theCampaign = ctrl.PreviousCampaign;
        theCampaign = ctrl.NewCampaign;

    }
}