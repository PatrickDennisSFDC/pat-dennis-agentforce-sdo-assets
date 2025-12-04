/**
 * AF Account Find Action
 * Invocable action for finding/searching Account records
 * Designed for Agentforce AI agents
 */
public with sharing class AFAccountFindAction {
    
    /**
     * Request input for find operation
     */
    public class Request {
        @InvocableVariable(
            label='Search Term'
            description='Text to search for in Account fields (Name, BillingCity, BillingState, BillingPostalCode, BillingStreet). The search will find Accounts where any of these fields contain the search term. Example: "Acme" or "San Francisco".'
            required=false
        )
        public String searchTerm;
        
        @InvocableVariable(
            label='Filters JSON'
            description='JSON string of exact-match filters. Can be single object {"fieldApiName":"Industry","value":"Technology"} or array [{"fieldApiName":"Industry","value":"Technology"},{"fieldApiName":"BillingCity","value":"San Francisco"}]. Common filter fields: Industry, BillingCity, BillingState, Phone.'
            required=false
        )
        public String filtersJson;
        
        @InvocableVariable(
            label='Search Limit'
            description='Maximum number of records to return (default: 5, max: 20). If more records match, the response will indicate how many total matches were found.'
            required=false
        )
        public Integer searchLimit;
    }
    
    /**
     * Response output for find operation
     */
    public class Response {
        @InvocableVariable(
            label='Success'
            description='True if operation completed successfully, false if an error occurred. Check this before using other output variables.'
        )
        public Boolean success;
        
        @InvocableVariable(
            label='Record'
            description='The single Account record found (when exactly one match). Use the record.Id field from this record for follow-up operations like updateAccount or deleteAccount. This is null when multiple or zero records are found.'
        )
        public Account record;
        
        @InvocableVariable(
            label='Records'
            description='List of Account records found. Use record.Id from each record for subsequent operations. If multiple matches, present all options to the user and ask for clarification using additional fields like Industry, City, or Phone.'
        )
        public List<Account> records;
        
        @InvocableVariable(
            label='Record ID'
            description='The Salesforce ID of the record (18-character format like "001xx000003DGbYAAW"). Only populated when exactly one record is found. Use this ID for updateAccount, deleteAccount, or readAccount operations.'
        )
        public Id recordId;
        
        @InvocableVariable(
            label='Message'
            description='Human-readable message describing the search results. Use this exact message to inform the user. Examples: "Found exactly one matching Account", "Found 3 matching Account records", "No Account records found matching the criteria".'
        )
        public String message;
        
        @InvocableVariable(
            label='Error Message'
            description='If success is false, this contains a user-friendly error message to relay directly to the user.'
        )
        public String errorMessage;
        
        @InvocableVariable(
            label='Object Type'
            description='The Salesforce object type, always "Account" for Account find operations. Useful for agent context and logging.'
        )
        public String objectType;
        
        @InvocableVariable(
            label='Ambiguous Result'
            description='True if multiple records were found in the search. When true, present all records to the user and ask for clarification using additional identifying fields like Industry, BillingCity, BillingState, or Phone to narrow down the selection.'
        )
        public Boolean ambiguous;
        
        @InvocableVariable(
            label='Total Matches'
            description='Number of Account records found in the search. Use this to inform the user: "Found X matching accounts" or "No accounts found matching your criteria".'
        )
        public Integer totalMatches;
        
        @InvocableVariable(
            label='More Results Available'
            description='True if the search returned the maximum number of results (searchLimit) but there are more matching records available. When true, suggest the user provide more specific search criteria or increase the searchLimit.'
        )
        public Boolean moreResultsAvailable;
    }
    
    /**
     * Find/Search Accounts
     */
    @InvocableMethod(
        label='Find Accounts'
        description='Searches for Account records using a search term and/or filters. Returns matching Account records. If multiple matches are found, the response indicates this and suggests additional fields to narrow down the search. Supports full-text search across Name, BillingCity, BillingState, and other key fields.'
        category='CRM Actions'
    )
    public static List<Response> findAccounts(List<Request> requests) {
        List<Response> responses = new List<Response>();
        
        for (Request req : requests) {
            Response res = new Response();
            res.objectType = 'Account';
            res.success = false;
            res.records = new List<Account>();
            res.totalMatches = 0;
            res.ambiguous = false;
            res.moreResultsAvailable = false;
            
            try {
                // Build request for AFUniversalCrmRecordAction
                AFUniversalCrmRecordAction.Request actionReq = new AFUniversalCrmRecordAction.Request();
                actionReq.objectApiName = 'Account';
                actionReq.operation = 'find';
                actionReq.searchTerm = req.searchTerm;
                actionReq.filtersJson = req.filtersJson;
                actionReq.searchLimit = req.searchLimit;
                
                // Call shared business logic
                AFUniversalCrmRecordAction.Response actionRes = AFUniversalCrmRecordAction.processRequest(actionReq);
                
                // Convert response
                if (actionRes.success) {
                    res.success = true;
                    res.message = actionRes.message != null ? actionRes.message : 'Search completed.';
                    res.ambiguous = actionRes.ambiguous != null ? actionRes.ambiguous : false;
                    res.totalMatches = actionRes.totalMatches != null ? actionRes.totalMatches : 0;
                    
                    if (actionRes.record != null) {
                        res.record = (Account) actionRes.record;
                        res.recordId = actionRes.recordId;
                        res.records = new List<Account>{ res.record };
                    } else if (actionRes.records != null && !actionRes.records.isEmpty()) {
                        res.records = new List<Account>();
                        for (SObject so : actionRes.records) {
                            res.records.add((Account) so);
                        }
                        if (res.records.size() == 1) {
                            res.record = res.records[0];
                            res.recordId = res.records[0].Id;
                        }
                    }
                    
                    // Check if more results available (if we hit the limit)
                    if (req.searchLimit != null && res.totalMatches >= req.searchLimit) {
                        res.moreResultsAvailable = true;
                    } else if (req.searchLimit == null && res.totalMatches >= 5) {
                        res.moreResultsAvailable = true;
                    }
                } else {
                    res.success = false;
                    res.errorMessage = actionRes.message != null ? actionRes.message : 'Search failed.';
                }
                
            } catch (Exception e) {
                res.success = false;
                res.errorMessage = 'Error searching Accounts: ' + e.getMessage();
                System.debug(LoggingLevel.ERROR, 'AFAccountFindAction: Exception - ' + e.getMessage());
            }
            
            responses.add(res);
        }
        
        return responses;
    }
}

