/**
 * Created by Chris Home Office on 6/25/2019.
 */

public with sharing class ExportUtilities {


    private static final String OPERATING_GL_ACCOUNT_CODE = '11101-00';
    private static final String OPERATING_ACCOUNT_NAME = 'Operating Acct - PNC';


    public class ExportWrapper {
        public string ActionDate { get; set; }
        public string ReferenceNumber { get; set; }
        public string NumberOfDistributions { get; set; }
        public string GLAccount { get; set; }
        public string Description { get; set; }
        public string Amount { get; set; }
        public string RecurNumber { get; set; }
        public string RecurFrequency { get; set; }
    }
}