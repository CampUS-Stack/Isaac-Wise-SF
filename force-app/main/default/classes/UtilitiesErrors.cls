/**
 * Created by cgibs on 12/26/2017.
 */

public with sharing class UtilitiesErrors {

    public static void CreateErrorLog(String errorMessage,String stackTrace,Integer lineNumber,String userId){
//        Error_Log__c errorLog = new Error_Log__c();
//        errorLog.Error_Message__c  = errorMessage;
//        errorLog.Line_Number__c = String.valueOf(lineNumber);
//        errorLog.User_Error_Occurred_For__c = userId;
//        errorLog.Stack_Trace__c = stackTrace;
//        insert errorLog;
    }
    
    public static void PrintErrorDetails(Exception e){
        System.debug(e.getMessage());
        System.debug('====================');
        System.debug(e.getCause());
        System.debug('====================');
        System.debug(e.getLineNumber());
        System.debug('====================');
        System.debug(e.getTypeName());
        System.debug('====================');
        System.debug(e.getStackTraceString());
    }

    @Future
    public static void SendErrorEmailASYNC(String messageBody){

        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.toAddresses = new String[] { 'support@undefined-design.com'};
        message.optOutPolicy = 'FILTER';
        message.subject = 'Error Message from Isaac Wise Production';
        message.plainTextBody = messageBody;
        message.htmlBody = messageBody;
        Messaging.SingleEmailMessage[] messages =   new List<Messaging.SingleEmailMessage> {message};
        Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);

        if (results[0].success)
        {
            System.debug('The email was sent successfully.');
        } else
        {
            System.debug('The email failed to send: ' + results[0].errors[0].message);
        }
    }

}