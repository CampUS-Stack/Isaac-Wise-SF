@IsTest
private class NMI_PaymentResponseControllerTest {
    @IsTest
    static void testBehavior() {

        PageReference pr = Page.NMI_PaymentResponse;
        pr.getParameters().put('token-id','Testtoken');
        Test.setCurrentPage(pr);

        Test.setMock(HttpCalloutMock.class, new NMIMockHttpResponse());

        Test.startTest();

        NMI_PaymentResponseController nmiPaymentResponseController = new NMI_PaymentResponseController();

        Test.stopTest();
    }
}