/**
 * Created by Kritik Garg on 05-02-2020.
 */

public with sharing class UDUtility {

    public static final String VALIDATION_SUCCESS = 'VALIDATION_SUCCESS';
    public static final String INVALID_CLIENTID = 'INVALID_CLIENT_ID';
    public static final String INVALID_SECRET = 'INVALID_SECRET_KEY';
    public static final String INVALID_REQ = 'INVALID_REQUEST';

    public static UD_Ticket__mdt getClientId() {
        List<UD_Ticket__mdt> udTickets = [select id, Client_Id__c, Secret_Key__c, Base_End_Point__c, MasterLabel FROM UD_Ticket__mdt WHERE MasterLabel = 'UD'];
        return udTickets.get(0);
    }

    public static String validateClientSecret(String clientId, String secretKey) {

        if(clientId == null  || clientId == '' || secretKey == null || secretKey =='') {
            return INVALID_REQ;
        }
        UD_Ticket__mdt udTicket = getClientId();

        if(udTicket.Client_Id__c == clientId) {

            if(udTicket.Secret_Key__c == secretKey) {
                return VALIDATION_SUCCESS;
            } else {
                return INVALID_SECRET;
            }
        }
        return INVALID_CLIENTID;
    }


    public class ErrorWrapper {
        public String Error {get;set;}

        public ErrorWrapper(String errorString) {
            Error = errorString;
        }

    }


}