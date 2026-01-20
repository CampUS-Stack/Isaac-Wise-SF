/**
 * Created by Chris Home Desktop on 8/14/2017.
 */
@IsTest
public with sharing class ContactMassUpdateControllerTests {

    @IsTest private static void ProcessTestCoverage(){

        Account acc = new Account();
        acc.Name = 'test';
        insert acc;

        ApexPages.StandardController stdController = new ApexPages.StandardController(acc);
        ContactMassUpdateController updateController = new ContactMassUpdateController(stdController);

        updateController.GetAddressValues();
        updateController.UpdateAddresses();

    }
}