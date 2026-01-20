@IsTest
private class NMI_PaymentPageControllerTest {
    @IsTest
    static void testBehavior() {

        Test.setMock(HttpCalloutMock.class, new NMIMockHttpResponse());

        Test.startTest();
        NMI_PaymentPageController nmiPaymentPageController = new NMI_PaymentPageController();

        nmiPaymentPageController.PaymentAmount = '1';

        NMI_PaymentPageController.GetNMIRedirectUrl(1);


        Test.stopTest();

    }
}