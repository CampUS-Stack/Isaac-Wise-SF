public class CongrComm_FinancialsBillHistCtrl {

    Public Contact theContact {get; set;}
    Public Boolean hasBills {get; set;}
    Public List<BillWrapper> billList {get; set;}
    
    Public CongrComm_FinancialsBillHistCtrl() {
        
        Date queryDate = Date.today();
        queryDate = queryDate.addMonths(-24);
        System.debug('queryDate: ' + queryDate);
        
        try {
            User currentUser = [SELECT Id, ContactId
                                FROM User
                                //WHERE Id = '00529000001lCTy'];
                                WHERE Id = :UserInfo.getUserId()];
            theContact = [SELECT Id, AccountId, Account.Name, FirstName, LastName
                          FROM Contact
                          WHERE Id = :currentUser.ContactId];
            Id assessmentTypeId = [SELECT Id, Name 
                                   FROM   RecordType 
                                   WHERE  sObjectType = 'Assessment__c' 
                                   AND 	  Name = 'Assessment'
                                   LIMIT  1].Id;
            List<Assessment__c> assessmentList = [SELECT Id, Designation__r.Name, Description__c, Assessment_Date__c, Is_Tax_Deductible__c,
                                                  		 Assessed_Amount__c, Amount_Adjusted__c, Amount_Paid__c,Designation__r.Designation_Description__c
                           						  FROM   Assessment__c
                           						  WHERE  Account__c = :theContact.AccountId 
                                                  AND    RecordTypeId = :assessmentTypeId
                                                  AND    Assessment_Date__c > :queryDate 
                                                  AND 	 Remaining_Balance__c <= 0 ORDER BY Assessment_Date__c DESC];
            System.debug('assessmentList: ' + assessmentList);
            
            if(assessmentList.size() > 0){
                hasBills = true;
                billList = new List<BillWrapper>();
                for(Assessment__c a : assessmentList){
                    billList.add(new BillWrapper(a));
                }
            } else {
                hasBills = false;
            }
        } catch (Exception ex) {
            System.debug('The following exception has occurred: ' + ex.getMessage());
        }
        
    }
    
    Public PageReference cancel() {
        PageReference pageRef = new PageReference('/CongrComm_FinancialsHome');
        return pageRef;
    }
    
    Public class BillWrapper {
        
        Public String designation {get; set;}
        Public String description {get; set;}
        Public Date billDate {get; set;}
        Public Decimal assessment {get; set;}
        Public Decimal adjustment {get; set;}
        Public Decimal paid {get; set;}
        Public Assessment__c theAssessment {get; set;}
        
        Public BillWrapper(Assessment__c theAssessment) {
            this.designation = theAssessment.Designation__r.Name;
            this.description = theAssessment.Description__c;
            this.billDate = theAssessment.Assessment_Date__c;
            this.assessment = theAssessment.Assessed_Amount__c;
            this.adjustment = theAssessment.Amount_Adjusted__c;
            this.paid = theAssessment.Amount_Paid__c;
            this.theAssessment = theAssessment;
        }
        
    }
    
}