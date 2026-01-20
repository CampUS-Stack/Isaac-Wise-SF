/**
 * Created by zacha on 2/17/2021.
 */

public with sharing class NMI_ConfirmationWrapper implements NMI_I3StepWrappers{

    public String  ApiKey {get; set;}
    public String  TokenId {get; set;}

    public NMI_ConfirmationWrapper(){}

    public String GetXMLString() {
        DOM.Document doc = new DOM.Document();
        dom.XmlNode saleXMLNode = doc.createRootElement('complete-action', null, null);
        NMI_Utilities.addChildElement(saleXMLNode,'api-key',ApiKey);
        NMI_Utilities.addChildElement(saleXMLNode,'token-id',TokenId);

        return doc.toXmlString();
    }
}