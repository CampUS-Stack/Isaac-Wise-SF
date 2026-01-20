/**
 * Created by Chris Home Office on 5/28/2019.
 */

public class HebrewDateCalculationResponse{
    public Integer gy;
    public Integer gm;
    public Integer gd;
    public Integer hy;
    public String hm;
    public Integer hd;
    public String hebrew;
    public String[] events;

    public static HebrewDateCalculationResponse parse(String json){
        return (HebrewDateCalculationResponse) System.JSON.deserialize(json, HebrewDateCalculationResponse.class);
    }


}