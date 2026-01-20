/**
 * Created by Kritik Garg on 13-03-2020.
 */

global class UDTicketFileWrapper {

    public String FileName {get;set;}
    public String FileId {get;set;}
    public String Body {get;set;}
    public String FileExt {get;set;}
    public String Description {get;set;}

    public UDTicketFileWrapper(String name, String id, String fileExtension, String descriptionString){
        FileName = name;
        FileId = id;
        FileExt = fileExtension;
        Description = descriptionString;
        Body = null;
    }

    public UDTicketFileWrapper(String name, String id, String fileExtension, String bodyData, String descriptionString){
        FileName = name;
        FileId = id;
        FileExt = fileExtension;
        Description = descriptionString;
        Body = bodyData;
    }

}