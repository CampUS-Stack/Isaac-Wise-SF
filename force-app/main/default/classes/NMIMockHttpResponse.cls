/**
 * Created by Kritik Garg on 18-12-2020.
 */

@IsTest
public with sharing class NMIMockHttpResponse  implements HttpCalloutMock{

    public HTTPResponse respond(HTTPRequest req) {

        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(200);


        if(req.getEndpoint().contains(NMI_Utilities.BASE_URL+NMI_Utilities.REDIRECT_ENDPOINT)) {
            if(req.getBody().contains('token-id') ) {
//                res.setBody('<?xml version="1.0" encoding="UTF-8"?><response><result>1</result><result-text>SUCCESS</result-text><transaction-id>5567917800</transaction-id><result-code>100</result-code><authorization-code>123456</authorization-code><cvv-result>N</cvv-result><action-type>sale</action-type><amount>2.10</amount><amount-authorized>2.10</amount-authorized><tip-amount>0.00</tip-amount><surcharge-amount>0.00</surcharge-amount><ip-address>103.207.169.106</ip-address><industry>ecommerce</industry><processor-id>ccprocessora</processor-id><currency>USD</currency><customer-receipt>true</customer-receipt><tax-amount>0.00</tax-amount><shipping-amount>0.00</shipping-amount><billing><first-name>null</first-name><last-name>null</last-name><cc-number>411111******1111</cc-number><cc-exp>1025</cc-exp></billing></response>');
                res.setBody('<?xml version="1.0" encoding="UTF-8"?><response><result>1</result><result-text>SUCCESS</result-text><transaction-id>5567917800</transaction-id><result-code>100</result-code><authorization-code>123456</authorization-code><cvv-result>N</cvv-result><action-type>sale</action-type><amount>2.10</amount><amount-authorized>2.10</amount-authorized><tip-amount>0.00</tip-amount><surcharge-amount>0.00</surcharge-amount><ip-address>103.207.169.106</ip-address><industry>ecommerce</industry><processor-id>ccprocessora</processor-id><currency>USD</currency><customer-receipt>true</customer-receipt><tax-amount>0.00</tax-amount><shipping-amount>0.00</shipping-amount><billing><first-name>null</first-name><last-name>null</last-name><cc-number>411111******1111</cc-number><cc-exp>1025</cc-exp><account-number>1231025</account-number><routing-number>1231025</routing-number><customer-vault-id>1231025</customer-vault-id><account-name>Test</account-name><billing-id>123456</billing-id></billing></response>');
            } else {
                res.setBody('<?xml version="1.0" encoding="UTF-8"?><response><result>1</result><result-text>Step 1 completed</result-text><transaction-id>5567881955</transaction-id><result-code>100</result-code><form-url>https://secure.networkmerchants.com/api/v2/three-step/5r66585k</form-url></response>');
            }
            //'<?xml version="1.0" encoding="UTF-8"?><sale><api-key>Ppam7cfm564sAn7Y7wJ4H9hHk4Zhx6NF</api-key><redirect-url>https://member-force-test-dev-ed.lightning.force.com/apex/NMI_PaymentResponse</redirect-url><amount>2.0</amount><ip-address>103.207.169.106</ip-address><customer-receipt>true</customer-receipt><stored-credential-indicator>stored</stored-credential-indicator></sale>'
        }

        /*  if(req.getEndpoint().contains(NMI_Utilities.BASE_URL+NMI_Utilities.REDIRECT_ENDPOINT)) {
              res.setBody('<?xml version="1.0" encoding="UTF-8"?><response><result>1</result><result-text>SUCCESS</result-text><transaction-id>5567917800</transaction-id><result-code>100</result-code><authorization-code>123456</authorization-code><cvv-result>N</cvv-result><action-type>sale</action-type><amount>2.10</amount><amount-authorized>2.10</amount-authorized><tip-amount>0.00</tip-amount><surcharge-amount>0.00</surcharge-amount><ip-address>103.207.169.106</ip-address><industry>ecommerce</industry><processor-id>ccprocessora</processor-id><currency>USD</currency><customer-receipt>true</customer-receipt><tax-amount>0.00</tax-amount><shipping-amount>0.00</shipping-amount><billing><first-name>null</first-name><last-name>null</last-name><cc-number>411111******1111</cc-number><cc-exp>1025</cc-exp></billing></response>');
          }*/

        if(req.getEndpoint().contains('https://secure.networkmerchants.com/api/v2/three-step/5r66585k')) {
            res.setBody('https://member-force-test-dev-ed.lightning.force.com/apex/NMI_PaymentResponse?token-id=5r66585k');
            //res.setBody('<?xml version="1.0" encoding="UTF-8"?><complete-action><api-key>rUbm5n8z8jVm4B244N4jHHKkSvp2jr4q</api-key><token-id>5r66585k</token-id></complete-action>');
        }



        return res;

    }

}