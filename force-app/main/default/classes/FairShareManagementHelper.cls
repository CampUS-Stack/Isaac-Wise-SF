/**
 * Created by Chris Gibson on 2/14/2023.
 */

public without sharing class FairShareManagementHelper {

    private static String MEMBERSHIP_DESIGNATION_ID {
        get {
            String idValue = CS_Default_Metadata__mdt.getInstance('Membership_Designation_Id')?.Text_Value__c;
            return String.isNotBlank(idValue) ? idValue : 'a02Ho00002kTfmCIAS';
        }
        set;
    }

    private static String PST_DESIGNATION_ID {
        get {
            String idValue = CS_Default_Metadata__mdt.getInstance('PST_Designation_Id')?.Text_Value__c;
            return String.isNotBlank(idValue) ? idValue : 'a02Ho00002kTfmDIAS';
        }
        set;
    }


    private static Date FairShareInvoiceDate {
        get {
            Date dateValue = CS_Default_Metadata__mdt.getInstance('Fair_Share_Assessment_Date')?.Date_Value__c;
            return dateValue != null ? dateValue : Date.newInstance(2024,6,1);
        }
        set;
    }

    public class FairShareWrapper {
        @AuraEnabled public Integer NumFamiliesWithFairShare {
            get {
                if (FamiliesWithFairShare == null) {
                    return 0;
                } else {
                    return FamiliesWithFairShare.size();
                }
            }
        }
        @AuraEnabled public Integer NumFamiliesWithoutFairShare {
            get {
                if (FamiliesWithoutFairShare == null) {
                    return 0;
                } else {
                    return FamiliesWithoutFairShare.size();
                }
            }
        }
        @AuraEnabled public Integer NumFairShareWithInvoice {
            get {
                if (FairSharesWithoutInvoices == null) {
                    return 0;
                } else {
                    return FairSharesWithoutInvoices.size();
                }
            }
        }
        @AuraEnabled public Integer NumFairShareWithoutInvoice {
            get {
                if (FairSharesWithInvoices == null) {
                    return 0;
                } else {
                    return FairSharesWithInvoices.size();
                }
            }
        }
        @AuraEnabled public String currentFY { get; set; }
        @AuraEnabled public String lastFY { get; set; }
        @AuraEnabled public String membershipType { get; set; }
        @AuraEnabled public List<Account> FamiliesWithoutFairShare { get; set; }
        @AuraEnabled public List<Account> FamiliesWithFairShare { get; set; }
        @AuraEnabled public List<Fair_Share__c> FairSharesWithoutInvoices { get; set; }
        @AuraEnabled public List<Fair_Share__c> FairSharesWithInvoices { get; set; }
        public FairShareWrapper() {
            this.FamiliesWithFairShare = new List<Account>();
            this.FamiliesWithoutFairShare = new List<Account>();
            this.FairSharesWithoutInvoices = new List<Fair_Share__c>();
            this.FairSharesWithInvoices = new List<Fair_Share__c>();
        }
    }

    @AuraEnabled(Cacheable=true)
    public static String getPSTDesignationId(){
        return PST_DESIGNATION_ID;
    }

    @AuraEnabled(Cacheable=true)
    public static String getMemDesignationId(){
        return MEMBERSHIP_DESIGNATION_ID;
    }

    @AuraEnabled(Cacheable=true)
    public static FairShareWrapper getFairShareInformation(String currentFiscalYear, String previousFiscalYear, String membershipType) {
        System.debug(membershipType);
        FairShareWrapper returnWrap = new FairShareWrapper();
        returnWrap.currentFY = currentFiscalYear;
        returnWrap.lastFY = previousFiscalYear;
        returnWrap.membershipType = membershipType;
        populateAccountInfo(returnWrap);
        populateFairShareInfo(returnWrap);
        return returnWrap;
    }

    @AuraEnabled
    public static Designation__c getDesignation(String name) {
        return [SELECT Id FROM Designation__c WHERE Name = :name];
    }


    private static void populateFairShareInfo(FairShareWrapper returnWrap) {
        String SOQL = 'SELECT Id, Name, Assessment__c, Account__r.Name, Membership_Contribution__c, PST__c, Membership_Assessment__c, PST_Assessment__c FROM Fair_Share__c WHERE Fiscal_Year__c = \'' + returnWrap.currentFY + '\'';
        if (String.isNotEmpty(returnWrap.membershipType)) {
            SOQL += ' AND Account__r.Membership_Type__c = \'' + returnWrap.membershipType + '\'';
        }

        List<Fair_Share__c> fairShares = Database.query(SOQL);
        for (Fair_Share__c curFS : fairShares) {
            if (String.isBlank(curFS.Membership_Assessment__c) || String.isBlank(curFS.PST_Assessment__c)) {
                returnWrap.FairSharesWithoutInvoices.add(curFS);
            } else {
                returnWrap.FairSharesWithInvoices.add(curFS);
            }
        }
    }

    private static void populateAccountInfo(FairShareWrapper returnWrap) {
        String SOQL = 'SELECT Id, Name, (SELECT Id FROM Fair_Share__r WHERE Fiscal_Year__c = \'' + returnWrap.currentFY + '\') FROM Account WHERE Is_Current_Member__c = TRUE';
        if (String.isNotBlank(returnWrap.membershipType)) {
            SOQL += ' AND Membership_Type__c = \'' + returnWrap.membershipType + '\'';
        }

        List<Account> accounts = Database.query(SOQL);
        for (Account curAcc : accounts) {
            System.debug(curAcc.Fair_Share__r.size() == 0);
            if (curAcc.Fair_Share__r.size() == 0) {
                System.debug('Found Acc with no FS');
                returnWrap.FamiliesWithoutFairShare.add(curAcc);
            } else {
                System.debug('Found Acc with FS');
                returnWrap.FamiliesWithFairShare.add(curAcc);
            }
        }
    }


    @AuraEnabled
    public static List<Fair_Share__c> createFairSharesFromLastFY(String currentFY, String previousFY, FairShareWrapper fsWrap, Decimal membershipAmount, Decimal pstAmount) {
        Set<String> accountsWithFSAlready = UtilitiesSObject.getSetOfFieldValues(fsWrap.FamiliesWithFairShare, 'Id');
        Set<String> accountsWithoutFS = UtilitiesSObject.getSetOfFieldValues(fsWrap.FamiliesWithoutFairShare, 'Id');
        List<Account> accounts = [SELECT Id,(SELECT Id FROM Fair_Share__r WHERE Fiscal_Year__c = :previousFY) FROM Account WHERE Id IN :accountsWithoutFS];
        List<Fair_Share__c> fairSharesToInsert = new List<Fair_Share__c>();
        for (Account curAcc : accounts) {
            Fair_Share__c curFS = new Fair_Share__c();
            curFS.Account__c = curAcc.Id;
            curFS.Fiscal_Year__c = currentFY;
            if (curAcc.Fair_Share__r.size() > 0) {
                curFS.Last_Year_Fair_Share__c = curAcc.Fair_Share__r[0].Id;
            }
            curFS.Membership_Contribution__c = membershipAmount;
            curFS.PST__c = pstAmount;
            fairSharesToInsert.add(curFS);
        }

        insert fairSharesToInsert;
        return fairSharesToInsert;
    }

    @AuraEnabled
    public static List<Fair_Share__c> createZeroDollarFairShare(String currentFY, FairShareWrapper fsWrap) {

        Set<String> accountsWithFSAlready = UtilitiesSObject.getSetOfFieldValues(fsWrap.FamiliesWithFairShare, 'Id');
        List<Fair_Share__c> fairShares = [
                SELECT Id, Account__c, Member_Comments__c, Staff_Comments__c, PST__c, URJ__c, Membership_Contribution__c, Last_Year_Membership_Amount__c
                FROM Fair_Share__c
                WHERE Fiscal_Year__c = :currentFY AND Membership_Contribution__c = 0 AND Last_Year_Fair_Share__c != NULL
        ];

        for (Fair_Share__c curFS : fairShares) {
            curFS.Membership_Contribution__c = curFS.Last_Year_Membership_Amount__c;
        }

        update fairShares;
        return fairShares;
    }

    @AuraEnabled
    public static Boolean createInvoices(List<Fair_Share__c> fs,String membershipDesignationId, String pstDesignationId) {
        System.debug('Fair Shares:');
        System.debug(fs);
        List<Assessment__c> assessments = new List<Assessment__c>();
        Designation__c membershipDesignation = [SELECT Id, Designation_Description__c FROM Designation__c WHERE Id = :membershipDesignationId];
        Designation__c pstDesignation = [SELECT Id, Designation_Description__c FROM Designation__c WHERE Id = :pstDesignationId];

        for (Fair_Share__c curFS : fs) {
            assessments.add(createAssessment(curFS, membershipDesignation, curFS.Membership_Contribution__c));
            assessments.add(createAssessment(curFS, pstDesignation, curFS.PST__c));
        }

        insert assessments;

        for (Fair_Share__c curFS : fs) {
            for (Assessment__c curAss : assessments) {
                if (curAss.Account__c == curFS.Account__c) {
                    if (curAss.Designation__c == membershipDesignation.Id) {
                        curFS.Membership_Assessment__c = curAss.Id;
                    } else if (curAss.Designation__c == pstDesignation.Id) {
                        curFS.PST_Assessment__c = curAss.Id;
                    }
                }
            }
        }

        update fs;

        return true;
    }

    public static Assessment__c createAssessment(Fair_Share__c fs, Designation__c designation, Decimal amount) {
        Assessment__c assessment = new Assessment__c();
        assessment.Account__c = fs.Account__c;
        assessment.Assessed_Amount__c = amount;
        assessment.Designation__c = designation.Id;
        assessment.Assessment_Date__c = FairShareInvoiceDate;
        // removed during call with Sally and Alethia on 6.29
//        assessment.Description__c = designation.Designation_Description__c;
        assessment.RecordTypeId = UtilitiesSObject.getRecordTypeId('Assessment', Assessment__c.SObjectType);
        return assessment;
    }
}