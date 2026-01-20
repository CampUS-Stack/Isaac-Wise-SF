/**
 * Created by Chris Gibson on 1/19/2020.
 */

public with sharing class NMI_TransactionalWrapper implements NMI_I3StepWrappers{


    public list<String> FormFields = new list<String>{'',''};

    public String ApiKey {get; set;}
    public String RedirectUrl {get; set;}
    public Decimal Amount {get; set;}
    public String IPAddress {get; set;}
    public String Industry {get; set;}
    public String BillingMethod {get; set;}
    public String BillingNumber {get; set;}
    public String BillingTotal {get; set;}
    public String ProcessorId {get; set;}
    public String SecCode {get; set;}
    public String TheCurrency {get; set;}
    public String OrderDescription {get; set;}
    public String CustomerId {get; set;}
    public String CustomerVaultId {get; set;}
    public String MerchantRecieptEmail {get; set;}
    public String CustomerReciept {get; set;}
    public Date OrderDate {get; set;}
    public String InitiatedBy {get; set;}
    public String InitialTransactionId {get; set;}
    public String StoredCredentialIndicator {get; set;}
    public Billing Billing {get; set;}
    public Shipping Shipping {get; set;}
    public Product Product {get; set;}
    public AddSubscription AddSubscription {get; set;}
    public AddCustomer AddCustomer {get; set;}
    public String PartialPayments {get; set;}
    public String PartialPaymentId {get; set;}

    public String  TransactionType {get; set;}
    public NMI_TransactionalWrapper(String transactionTypeToSet){
        TransactionType = transactionTypeToSet;
    }
    public String GetXMLString(){

        DOM.Document doc = new DOM.Document();
        dom.XmlNode saleXMLNode = doc.createRootElement(TransactionType, null, null);
        NMI_Utilities.addChildElement(saleXMLNode,'api-key',ApiKey);
        NMI_Utilities.addChildElement(saleXMLNode,'redirect-url',RedirectURL);
        NMI_Utilities.addChildElement(saleXMLNode,'amount',Amount);
        NMI_Utilities.addChildElement(saleXMLNode,'ip-address',IPAddress);
        NMI_Utilities.addChildElement(saleXMLNode,'billing-method',BillingMethod);
        NMI_Utilities.addChildElement(saleXMLNode,'billing-number',BillingNumber);
        NMI_Utilities.addChildElement(saleXMLNode,'billing-total',BillingTotal);
        NMI_Utilities.addChildElement(saleXMLNode,'sec-code',SecCode);
        NMI_Utilities.addChildElement(saleXMLNode,'currency',TheCurrency);
        NMI_Utilities.addChildElement(saleXMLNode,'order-description',OrderDescription);
        NMI_Utilities.addChildElement(saleXMLNode,'customer-id',CustomerId);
        NMI_Utilities.addChildElement(saleXMLNode,'customer-vault-id',CustomerVaultId);
        NMI_Utilities.addChildElement(saleXMLNode,'merchant-receipt-email',MerchantRecieptEmail);
        NMI_Utilities.addChildElement(saleXMLNode,'customer-receipt',CustomerReciept);
        NMI_Utilities.addChildElement(saleXMLNode,'order-date',OrderDate);
        NMI_Utilities.addChildElement(saleXMLNode,'InitiatedBy',InitiatedBy);
        NMI_Utilities.addChildElement(saleXMLNode,'initial-transaction-id',InitialTransactionId);
        NMI_Utilities.addChildElement(saleXMLNode,'stored-credential-indicator',StoredCredentialIndicator);

        if(billing != null)
            billing.AddToXML(saleXMLNode);

        if(shipping != null)
            shipping.AddToXML(saleXMLNode);

        if(product != null)
            product.AddToXML(saleXMLNode);

        if(addSubscription != null)
            addSubscription.AddToXML(saleXMLNode);

        if(AddCustomer != null)
            AddCustomer.AddToXML(saleXMLNode);


        return doc.toXmlString();
    }


    public class Billing{
        public String BillingId {get; set;}
        public String FirstName {get; set;}
        public String LastName {get; set;}
        public String Address1 {get; set;}
        public String City {get; set;}
        public String State {get; set;}
        public String Postal {get; set;}
        public String Country {get; set;}
        public String Phone {get; set;}
        public String Email {get; set;}
        public String Company {get; set;}
        public String Address2 {get; set;}
        public String Fax {get; set;}
        public String AccountType {get; set;}
        public String EntityType {get; set;}

        public Void AddToXML(dom.XmlNode xmlNode){

            dom.XmlNode billingNode =  xmlNode.addChildElement('billing', null, null);
            NMI_Utilities.addChildElement(billingNode,'billing-id',BillingId);
            NMI_Utilities.addChildElement(billingNode,'first-name',FirstName);
            NMI_Utilities.addChildElement(billingNode,'last-name',LastName);
            NMI_Utilities.addChildElement(billingNode,'address1',Address1);
            NMI_Utilities.addChildElement(billingNode,'city',City);
            NMI_Utilities.addChildElement(billingNode,'state',State);
            NMI_Utilities.addChildElement(billingNode,'postal',Postal);
            NMI_Utilities.addChildElement(billingNode,'country',Country);
            NMI_Utilities.addChildElement(billingNode,'phone',Phone);
            NMI_Utilities.addChildElement(billingNode,'email',Email);
            NMI_Utilities.addChildElement(billingNode,'company',Company);
            NMI_Utilities.addChildElement(billingNode,'addresss2',Address2);
            NMI_Utilities.addChildElement(billingNode,'fax',Fax);
            NMI_Utilities.addChildElement(billingNode,'account-type',AccountType);
            NMI_Utilities.addChildElement(billingNode,'entity-type',EntityType);
        }
    }
    public class Shipping{
        public String ShippingId {get; set;}
        public String FirstName {get; set;}
        public String LastName {get; set;}
        public String Address1 {get; set;}
        public String City {get; set;}
        public String State {get; set;}
        public String Postal {get; set;}
        public String Country {get; set;}
        public String Phone {get; set;}
        public String Email {get; set;}
        public String Company {get; set;}
        public String Address2 {get; set;}
        public String Fax {get; set;}
        public Void AddToXML(dom.XmlNode xmlNode){

            dom.XmlNode ShippingNode = xmlNode.addChildElement('Shipping', null, null);
            NMI_Utilities.addChildElement(ShippingNode,'billing-id',ShippingId);
            NMI_Utilities.addChildElement(ShippingNode,'first-name',FirstName);
            NMI_Utilities.addChildElement(ShippingNode,'last-name',LastName);
            NMI_Utilities.addChildElement(ShippingNode,'address1',Address1);
            NMI_Utilities.addChildElement(ShippingNode,'city',City);
            NMI_Utilities.addChildElement(ShippingNode,'state',State);
            NMI_Utilities.addChildElement(ShippingNode,'postal',Postal);
            NMI_Utilities.addChildElement(ShippingNode,'country',Country);
            NMI_Utilities.addChildElement(ShippingNode,'phone',Phone);
            NMI_Utilities.addChildElement(ShippingNode,'email',Email);
            NMI_Utilities.addChildElement(ShippingNode,'company',Company);
            NMI_Utilities.addChildElement(ShippingNode,'addresss2',Address2);
            NMI_Utilities.addChildElement(ShippingNode,'fax',Fax);
        }
    }
    public class Product{
        public String ProductCode {get; set;}
        public String Description {get; set;}
        public String CommodityCode {get; set;}
        public String UnitOfMeasure {get; set;}
        public String UnitCost {get; set;}
        public String Quantity {get; set;}
        public String TotalAmount {get; set;}
        public String TaxAmount {get; set;}
        public String TaxRate {get; set;}
        public String DiscountAmount {get; set;}
        public String TaxType {get; set;}
        public String AlternateTaxId {get; set;}
        public Void AddToXML(dom.XmlNode xmlNode){


            dom.XmlNode productNode = xmlNode.addChildElement('Product', null, null);
            NMI_Utilities.addChildElement(productNode,'product-code',ProductCode);
            NMI_Utilities.addChildElement(productNode,'description',Description);
            NMI_Utilities.addChildElement(productNode,'commodity-code',CommodityCode);
            NMI_Utilities.addChildElement(productNode,'unit-of-measure',UnitOfMeasure);
            NMI_Utilities.addChildElement(productNode,'unit-cost',UnitCost);
            NMI_Utilities.addChildElement(productNode,'quantity',Quantity);
            NMI_Utilities.addChildElement(productNode,'total-amount',TotalAmount);
            NMI_Utilities.addChildElement(productNode,'tax-amount',TaxAmount);
            NMI_Utilities.addChildElement(productNode,'tax-rate',TaxRate);
            NMI_Utilities.addChildElement(productNode,'discount-amount',DiscountAmount);
            NMI_Utilities.addChildElement(productNode,'tax-type',TaxType);
        }
    }
    public class AddSubscription{
        public String StartDate {get; set;}
        public Plan Plan {get; set;}

        public Void AddToXML(dom.XmlNode xmlNode){
            dom.XmlNode AddSubNode = xmlNode.addChildElement('add-subscription', null, null);
            NMI_Utilities.addChildElement(AddSubNode,'start-date',StartDate);

            if(Plan != null){
                Plan.AddToXML(xmlNode);
            }
        }
    }

    public class Plan{
        public String PlanId {get; set;}
        public Integer Payments {get; set;}
        public Decimal Amount {Get; set;}
        public String DayFrequency {get; set;}
        public String MonthFrequency {get; set;}
        public String DayOfMonth {get; set;}
        public void AddToXML(dom.XmlNode xmlNode){
            dom.XmlNode planNode = xmlNode.addChildElement('plan', null, null);
            NMI_Utilities.addChildElement(planNode,'plan-id',PlanId);
            NMI_Utilities.addChildElement(planNode,'payments',Payments);
            NMI_Utilities.addChildElement(planNode,'day-frequency',DayFrequency);
            NMI_Utilities.addChildElement(planNode,'month-frequency',MonthFrequency);
            NMI_Utilities.addChildElement(planNode,'day-of-month',DayOfMonth);
        }
    }

    public class AddCustomer {
        public String CustomerVaultId {get; set;}
        public void AddToXML(dom.XmlNode xmlNode){
            dom.XmlNode planNode = xmlNode.addChildElement('add-customer', null, null);
            NMI_Utilities.addChildElement(planNode,'customer-vault-id',CustomerVaultId);
        }
    }

}