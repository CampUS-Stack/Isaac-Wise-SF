/**
 * Created by Kritik Garg on 09-01-2020.
 */

public without sharing class UDTokenWrapper {

    public String access_token {get;set;}
    public String instance_url {get;set;}
    public String id {get;set;}
    public String token_type {get;set;}
    public String issued_at {get;set;}
    public String signature {get;set;}

    public static UDTokenWrapper parse(String json){
        return (UDTokenWrapper) System.JSON.deserialize(json, UDTokenWrapper.class);
    }
}