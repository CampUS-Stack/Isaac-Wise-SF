/**
 * Created by Chris Gibson on 3/18/2020.
 */

public with sharing class NMI_CustomerVaultWrapper implements NMI_I3StepWrappers{
    public String  TransactionType {get; set;}
    public String ApiKey {get; set;}
    public String RedirectUrl {get; set;}
    public String CustomerVaultId {get; set;}

    public NMI_Utilities.Billing Billing {get; set;}
    public NMI_Utilities.Shipping Shipping {get; set;}

    /**
     * @author: Chris Gibson
     * @date: 03.18.2020
     *
     * @description This method generates the XML request for NMI's Custom Vault
     *
     * @param transactionTypeToSet - 'add-customer' or 'update-customer'
     */
    public NMI_CustomerVaultWrapper(String transactionTypeToSet) {
        TransactionType = transactionTypeToSet;
    }

    public String GetXMLString(){
        DOM.Document doc = new DOM.Document();
        dom.XmlNode saleXMLNode = doc.createRootElement(TransactionType, null, null);
        NMI_Utilities.addChildElement(saleXMLNode,'api-key',ApiKey);
        NMI_Utilities.addChildElement(saleXMLNode,'redirect-url',RedirectURL);
        NMI_Utilities.addChildElement(saleXMLNode,'customer-vault-id',CustomerVaultId);

        if(Billing != null)
            Billing.AddToXML(saleXMLNode);
        if(Shipping != null)
            Shipping.AddToXML(saleXMLNode);

        return doc.toXmlString();
    }


}