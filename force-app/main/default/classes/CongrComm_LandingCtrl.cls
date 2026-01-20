/**
 * Created by Chris Home Desktop on 4/16/2018.
 */

public with sharing class CongrComm_LandingCtrl {

    public CongrComm_LandingCtrl(){}

    public PageReference forwardToHomePage(){

        if(UserInfo.getUserType() == 'Guest'){
            PageReference pr = Page.CongrComm_Login;
            pr.setRedirect(true);
            return pr;
        }
        else{
            PageReference pr = Page.CongrComm_Home;
            pr.setRedirect(true);
            return pr;
        }
    }
}