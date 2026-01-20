/**
 * An apex page controller that exposes the site forgot password functionality
 */
public without sharing class ForgotPasswordController {
    public String username {get; set;}
	public Boolean shouldShowError {get; set;}
       
    public ForgotPasswordController() {
		shouldShowError = false;
	}
	
  	public PageReference forgotPassword() {

		this.shouldShowError = !checkForUserErrors(username);
		if(this.shouldShowError){
			return null;
		}

  		boolean success = Site.forgotPassword(username);
  		PageReference pr = Page.CongrComm_ForgotPasswordConfirm;
  		pr.setRedirect(true);
  		
  		if (success) {
  			return pr;
  		}
  		return null;
  	}

	public Boolean checkForUserErrors(String userName){

		try{
			User u = [SELECT Id FROM User WHERE Username = :userName];
			return true;
		}
		catch(QueryException qe){
			system.debug(qe.getMessage());
			return false;
		}

//		Boolean result = false;
//
//		User user = new User();
//		user.FirstName = 'any';
//		user.LastName = 'any';
//		user.Alias = 'any';
//		user.Email = 'jschaffzin@wisetemple.org';
//		user.Username = userName;
//		user.CommunityNickname = userName;
//		user.LocaleSidKey = 'en_US';
//		user.LanguageLocaleKey = 'en_US';
//		user.EmailEncodingKey = 'UTF-8';
//		user.TimeZoneSidKey = 'America/New_York';
//		user.ProfileId = [SELECT Id, Name FROM Profile WHERE Name='Standard User' limit 1].Id;
//
//		Savepoint sp = Database.setSavepoint();
//
//		try {
//			insert user;
//		}
//		catch(DmlException ex) {
//			system.debug(ex.getDmlStatusCode(0));
//			if(ex.getDmlStatusCode(0) == StatusCode.FIELD_INTEGRITY_EXCEPTION.name()){
//				result = true;
//			}
//			if(ex.getDmlStatusCode(0) == StatusCode.DUPLICATE_USERNAME.name()) {
//				result = true;
//			}
//
//		}
//		finally {
//			Database.rollback(sp);
//		}

//		return result;
	}
}