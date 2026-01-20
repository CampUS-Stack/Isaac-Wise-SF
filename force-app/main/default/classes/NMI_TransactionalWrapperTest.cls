@isTest
Private  class NMI_TransactionalWrapperTest {
    Static TestMethod void NMI_Method(){
        String str = 'transactionTypeToSet';
        NMI_TransactionalWrapper wrapper = new NMI_TransactionalWrapper(str);
        /*NMI_TransactionalWrapper.billing = 'Billing';
        wrapper.shipping = 'shipping';
        wrapper.product = 'product';
        wrapper.addSubscription = 'addSubscription';*/
        wrapper.GetXMLString();
        DOM.Document doc = new DOM.Document();
        NMI_TransactionalWrapper.Billing  bill= new NMI_TransactionalWrapper.Billing();
        dom.XmlNode saleXMLNode = doc.createRootElement(str, null, null);
        bill.FirstName ='Test';
        bill.Address1 = 'Island';
        bill.Address2 ='paris';
        bill.BillingId= '12345';
        bill.City= 'FBD';
        bill.Company='Company';
        bill.Country ='India';
        bill.Email='test@gmail.com';
        bill.LastName= 'tst';
        bill.Phone ='123467';
        bill.Postal ='1101';
        bill.State = 'state';
        bill.AddToXML(saleXMLNode);

        NMI_TransactionalWrapper.Shipping  ship= new NMI_TransactionalWrapper.Shipping();
        ship.Address1 = 'Test';
        ship.Address2 ='Test2';
        ship.City = 'city';
        ship.Company = 'Company';
        ship.Country ='country';
        ship.Email ='test@gmail.com';
        ship.Fax = '12346';
        ship.FirstName='testn';
        ship.LastName ='lstname';
        ship.Phone = '12345';
        ship.Postal='1010';
        ship.ShippingId='1235';
        ship.State ='FBD';
        ship.AddToXML(saleXMLNode);

        NMI_TransactionalWrapper.product prod = new NMI_TransactionalWrapper.product();
        prod.AlternateTaxId ='txid';
        prod.CommodityCode ='code';
        prod.Description ='description';
        prod.DiscountAmount ='140';
        prod.ProductCode ='123';
        prod.Quantity='12';
        prod.TaxAmount ='20';
        prod.TaxRate='10';
        prod.TaxType='gst';
        prod.TotalAmount='400';
        prod.UnitCost='20';
        prod.UnitOfMeasure ='kg';
        prod.AddToXML(saleXMLNode);




        wrapper.BillingMethod = 'method';
    }

}