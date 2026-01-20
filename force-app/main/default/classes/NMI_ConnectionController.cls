/**
 * @author Chris Gibson
 * @date 1/18/2020.
 *
 * @description This class is used to make callouts to the NMI Payment Gateway.
 */

public with sharing class NMI_ConnectionController {


    //// Singleton for connection controller
    public static NMI_ConnectionController GetNMIConnectionController{
        get{
            if(theConnController == null){
                theConnController = new NMI_ConnectionController();
                return theConnController;
            }

            return theConnController;
        }
    }
    private static NMI_ConnectionController theConnController;

    /**
     * @author Chris Gibson
     * @date 01.18.2020
     *
     * @description This is the 0 param constructor for the NMI Connection Controller.
     */
    public NMI_ConnectionController(){

    }

    /**
     * @author Chris Gibson
     * @date 03.29.2020
     *
     * @description This method allows submissions to be made to the Query API -
     *                  https://secure.tnbcigateway.com/merchants/resources/integration/integration_portal.php?tid=8e77f91bde036a62c7cd3949f0af8fc4#query_methodology
     *
     * @return a String representing the URL to be posted two
     */
    public Dom.XmlNode GetTransactionData(String transactionId){
        HttpResponse theResponse = SendRequest('',NMI_Utilities.QUERY_API_BASE_URL + '?' + NMI_Utilities.QUERY_API_KEY_PARAM_NAME + '=' +
                NMI_Utilities.API_KEY + '&' + NMI_Utilities.QUERY_API_TRANSACTION_ID_PARAM_NAME + '=' + transactionId,'GET');

        if(theResponse == null){
            return null;
        }

        Dom.Document xmlDoc = theResponse.getBodyDocument();
        Dom.XmlNode xmlResponse = xmlDoc.getRootElement().getChildElement('transaction',null);
        system.debug(xmlResponse);
        return xmlResponse;
    }

    /**
     * @author Chris Gibson
     * @date 01.18.2020
     *
     * @description This method is to be used in step 1 in the 3 step redirect process defined by NMI
     *              it
     *
     * @return a String representing the URL to be posted two
     */
    public String GetRedirectUrl(NMI_I3StepWrappers wrapper){
        system.debug(wrapper.GetXMLString());
        HttpResponse theResponse = SendRequest(wrapper.GetXMLString(),NMI_Utilities.BASE_URL + NMI_Utilities.REDIRECT_ENDPOINT,'POST');

        if(theResponse == null){
            return '';
        }

        Dom.Document xmlDoc = theResponse.getBodyDocument();
        Dom.XmlNode xmlResponse = xmlDoc.getRootElement();
        system.debug('theResponse = '+ theResponse.getBody());
        return xmlResponse.getChildElement('form-url',null).getText();
    }

    public String SendStep2Data(String body,String endpoint){

        HttpRequest req = new HttpRequest();
        System.debug('endpoint = ' + endpoint);
        req.setEndpoint(endpoint);
        req.setMethod('POST');
        req.setBody(body);

        try{
            Http http = new Http();
            HttpResponse response = http.send(req);
            system.debug(response.getStatusCode() + '   ' + response.getBody());
            if(response.getStatusCode() >=300 && response.getStatusCode() <= 307 && response.getStatusCode() != 306) {
                String redirectUrl = response.getHeader('Location');
                return redirectUrl;
            }
            else return response.getBody();
        }
        catch(CalloutException ce){
            system.debug(ce.getMessage());
            return 'FAIL';
        }
    }

    /**
     * @author Chris Gibson
     * @date 01.18.2020
     *
     * @description This method is to be used in step 3 in the 3 step redirect process defined by NMI
     *              it
     *
     * @return a String representing the URL to be posted to
     */
    public String SendConfirmationRequest(NMI_ConfirmationWrapper wrapper){

        Dom.XmlNode xmlResponse = GetConfirmationXmlResponse(wrapper);
        if(xmlResponse == null){
            return '';
        }
        system.debug(xmlResponse);
        return xmlResponse.getText();
    }
    /**
     * @author Chris Gibson
     * @date 01.18.2020
     *
     * @description This method is to be used in step 3 in the 3 step redirect process defined by NMI
     *              it
     *
     * @return a String representing the URL to be posted to
     */
    public String SendConfirmationRequest(NMI_ConfirmationWrapper wrapper,String fieldToCheckFor){

        Dom.XmlNode xmlResponse = GetConfirmationXmlResponse(wrapper);
        if(xmlResponse == null){
            return '';
        }
        return xmlResponse.getChildElement(fieldToCheckFor,null).getText();
    }

    public Dom.XmlNode GetConfirmationXmlResponse(NMI_ConfirmationWrapper wrapper) {

        system.debug(NMI_Utilities.BASE_URL + NMI_Utilities.REDIRECT_ENDPOINT);
        system.debug(wrapper.GetXMLString());
        HttpResponse theResponse = SendRequest(wrapper.GetXMLString(),NMI_Utilities.BASE_URL + NMI_Utilities.REDIRECT_ENDPOINT,'POST');
        if (theResponse == null) {
            return null;
        }
        system.debug(theResponse.getBody());

        Dom.Document xmlDoc = theResponse.getBodyDocument();
        Dom.XmlNode xmlResponse = xmlDoc.getRootElement();
        system.debug(xmlResponse);
        return xmlResponse;
    }

    @TestVisible private HttpResponse SendRequest(String body, String endpoint, String method) {

        Http theHttp = new Http();
        HttpRequest theRequest = createHttpRequest(endpoint,method);

        try{
            theRequest.setBody(body);
            HttpResponse theResponse;
            //if(!Test.isRunningTest()){
            theResponse = theHttp.send(theRequest);
            /*}else{
                theResponse = new HttpResponse();
                //// Test Code Dependent upon this string.
                theResponse.setBody('<response><form-url>test-form-url</form-url><subscription-id>test-subscription-id</subscription-id></response>');
            }*/
            return theResponse;
        }
        catch(CalloutException ce){
            system.debug(ce.getMessage());
            return null;
        }
    }

    @TestVisible private HttpRequest createHttpRequest(String endpoint,String method){

        HttpRequest httpRequest = new HttpRequest();
        httpRequest.setHeader('Authorization',NMI_Utilities.API_KEY);
        httpRequest.setHeader('Content-Type',NMI_Utilities.CONTENT_TYPE);
        httpRequest.setMethod(method);
        httpRequest.setEndpoint(endpoint);
        return httpRequest;
    }

}