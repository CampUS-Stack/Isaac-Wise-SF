/**
 * Created by Chris Home Office on 5/28/2019.
 */

public with sharing class HebrewDateCalculationController {

    public static String HEBCALC_ENDPOINT = 'https://www.hebcal.com/converter/';

    public static String HEBCALC_GREGORIAN_YEAR_PARAM_NAME = 'gy';
    public static String HEBCALC_GREGORIAN_MONTH_PARAM_NAME = 'gm';
    public static String HEBCALC_GREGORIAN_DAY_PARAM_NAME = 'gd';
    public static String HEBCALC_GREGORIAN_AFTER_SUNSET_PARAM_NAME = 'gs';

    public static String HEBCALC_HEBREW_YEAR_PARAM_NAME = 'hy';
    public static String HEBCALC_HEBREW_MONTH_PARAM_NAME = 'hm';
    public static String HEBCALC_HEBREW_DAY_PARAM_NAME = 'hd';
//    public static String HEBCALC_HEBREW_AFTER_SUNSET_PARAM_NAME = 'gs';

    public static String HEBCALC_DATE_CALCULATION_TYPE_G_TO_H = 'g2h=1';
    public static String HEBCALC_DATE_CALCULATION_TYPE_H_TO_G = 'h2g=1';

    public static String HEBCALC_RESPONSE_TYPE_PARAM_NAME = 'cfg';
    public static String HEBCALC_JSON_RESPONSE_TYPE = 'json';
    public static String HEBCALC_XML_RESPONSE_TYPE = 'xml';

    public HebrewDateCalculationController(){}

    public HebrewDateCalculationResponse RunHebrewToEngDateConversion(String hebrewYear, String hebrewMonth, String hebrewDay){

        if(String.isBlank(hebrewYear) || String.isBlank(hebrewMonth) || String.isBlank(hebrewDay)){
            return null;
        }

        String endpoint = HEBCALC_ENDPOINT + '?' + HEBCALC_RESPONSE_TYPE_PARAM_NAME + '=' + HEBCALC_JSON_RESPONSE_TYPE + '&' + HEBCALC_HEBREW_YEAR_PARAM_NAME + '=' + EncodingUtil.urlEncode(hebrewYear,'UTF-8') + '&' + HEBCALC_HEBREW_MONTH_PARAM_NAME + '=' + EncodingUtil.urlEncode(hebrewMonth,'UTF-8') + '&' + HEBCALC_HEBREW_DAY_PARAM_NAME + '=' + EncodingUtil.urlEncode(hebrewDay,'UTF-8') + '&' + HEBCALC_DATE_CALCULATION_TYPE_H_TO_G;
        return sendHTTPRequest(endpoint);
    }

    public HebrewDateCalculationResponse RunEngToHebrewDateConversion(Date dateToConvert){

        if(dateToConvert == null){
            return null;
        }

        return RunEngToHebrewDateConversion(dateToConvert.year(),dateToConvert.month(),dateToConvert.day());
    }

    public HebrewDateCalculationResponse RunEngToHebrewDateConversion(Integer year, Integer month, Integer day){

        if(year <= 0 || month <= 0 || day <= 0){
            return null;
        }

        String gregorianYear = String.valueof(year);
        String gregorianMonth = String.valueof(month);
        String gregorianDay = String.valueof(day);

        String endpoint = HEBCALC_ENDPOINT + '?' + HEBCALC_RESPONSE_TYPE_PARAM_NAME + '=' + HEBCALC_JSON_RESPONSE_TYPE + '&' + HEBCALC_GREGORIAN_YEAR_PARAM_NAME + '=' + EncodingUtil.urlEncode(gregorianYear,'UTF-8') + '&' + HEBCALC_GREGORIAN_MONTH_PARAM_NAME + '=' + EncodingUtil.urlEncode(gregorianMonth,'UTF-8') + '&' + HEBCALC_GREGORIAN_DAY_PARAM_NAME + '=' + EncodingUtil.urlEncode(gregorianDay,'UTF-8') + '&' + HEBCALC_DATE_CALCULATION_TYPE_G_TO_H;
        return sendHTTPRequest(endpoint);
    }

    @TestVisible private HebrewDateCalculationResponse sendHTTPRequest(String endpoint){

        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setEndpoint(endpoint);

        try{
            HttpResponse resp = http.send(req);
            HebrewDateCalculationResponse response = HebrewDateCalculationResponse.parse(resp.getBody());
            return response;
        }
        catch(CalloutException ce){
            system.debug(ce.getMessage());
            return null;
        }
    }
}