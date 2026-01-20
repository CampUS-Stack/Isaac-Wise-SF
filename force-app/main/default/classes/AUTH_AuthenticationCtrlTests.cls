/**
 * Created by Chris Home Desktop on 7/7/2018.
 */
@IsTest
public with sharing class AUTH_AuthenticationCtrlTests {

    public static String TEST_AUTH_TOKEN_JSON_RESPONSE = '﻿{"token":"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.34jc9EA5","messages":{"resultCode":"Ok","message":[{"code":"I00001","text":"Successful."}]}}';
    @IsTest public static void RunAuthControllerTests(){

        Authorize_Net_Settings__c setting1 = new Authorize_Net_Settings__c();
        setting1.Name = 'Merchant ID';
        setting1.Value__c = 'test1233';
        insert setting1;

        Authorize_Net_Settings__c setting2 = new Authorize_Net_Settings__c();
        setting2.Name = 'Transaction ID';
        setting2.Value__c = 'test12331';
        insert setting2;

        AUTH_AuthenticationCtrl authCtrl = new AUTH_AuthenticationCtrl();
        authCtrl.setAccessToken(TEST_AUTH_TOKEN_JSON_RESPONSE);

    }
}