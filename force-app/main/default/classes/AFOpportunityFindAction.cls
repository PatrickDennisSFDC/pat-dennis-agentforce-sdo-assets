/**
 * AF Opportunity Find Action
 * Invocable action for finding/searching Opportunity records
 * Designed for Agentforce AI agents
 */
public with sharing class AFOpportunityFindAction {
    
    /**
     * Request input for find operation
     */
    public class Request {
        @InvocableVariable(
            label='Search Term'
            description='Text to search for in Opportunity fields (Name, Description). The search will find Opportunities where any of these fields contain the search term. Example: "Deal" or "Q4".'
            required=false
        )
        public String searchTerm;
        
        @InvocableVariable(
            label='Filters JSON'
            description='JSON string of exact-match filters. Can be single object {"fieldApiName":"StageName","value":"Closed Won"} or array [{"fieldApiName":"StageName","value":"Closed Won"},{"fieldApiName":"AccountId","value":"001xx000003DGbYAAW"}]. Common filter fields: StageName, AccountId, CloseDate, Type.'
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
            description='The single Opportunity record found (when exactly one match). Use the record.Id field from this record for follow-up operations like updateOpportunity or deleteOpportunity. This is null when multiple or zero records are found.'
        )
        public Opportunity record;
        
        @InvocableVariable(
            label='Records'
            description='List of Opportunity records found. Use record.Id from each record for subsequent operations. If multiple matches, present all options to the user and ask for clarification using additional fields like StageName, CloseDate, or Account name.'
        )
        public List<Opportunity> records;
        
        @InvocableVariable(
            label='Record ID'
            description='The Salesforce ID of the record (18-character format like "006xx000003DGbYAAW"). Only populated when exactly one record is found. Use this ID for updateOpportunity, deleteOpportunity, or readOpportunity operations.'
        )
        public Id recordId;
        
        @InvocableVariable(
            label='Message'
            description='Human-readable message describing the search results. Use this exact message to inform the user. Examples: "Found exactly one matching Opportunity", "Found 3 matching Opportunity records", "No Opportunity records found matching the criteria".'
        )
        public String message;
        
        @InvocableVariable(
            label='Error Message'
            description='If success is false, this contains a user-friendly error message to relay directly to the user.'
        )
        public String errorMessage;
        
        @InvocableVariable(
            label='Object Type'
            description='The Salesforce object type, always "Opportunity" for Opportunity find operations. Useful for agent context and logging.'
        )
        public String objectType;
        
        @InvocableVariable(
            label='Ambiguous Result'
            description='True if multiple records were found in the search. When true, present all records to the user and ask for clarification using additional identifying fields like StageName, CloseDate, or Account name to narrow down the selection.'
        )
        public Boolean ambiguous;
        
        @InvocableVariable(
            label='Total Matches'
            description='Number of Opportunity records found in the search. Use this to inform the user: "Found X matching opportunities" or "No opportunities found matching your criteria".'
        )
        public Integer totalMatches;
        
        @InvocableVariable(
            label='More Results Available'
            description='True if the search returned the maximum number of results (searchLimit) but there are more matching records available. When true, suggest the user provide more specific search criteria or increase the searchLimit.'
        )
        public Boolean moreResultsAvailable;
    }
    
    /**
     * Find/Search Opportunities
     */
    @InvocableMethod(
        label='Find Opportunities'
        description='Searches for Opportunity records using a search term and/or filters. Returns matching Opportunity records. If multiple matches are found, the response indicates this and suggests additional fields to narrow down the search. Supports full-text search across Name and Description fields.'
        category='CRM Actions'
    )
    public static List<Response> findOpportunities(List<Request> requests) {
        List<Response> responses = new List<Response>();
        
        for (Request req : requests) {
            Response res = new Response();
            res.objectType = 'Opportunity';
            res.success = false;
            res.records = new List<Opportunity>();
            res.totalMatches = 0;
            res.ambiguous = false;
            res.moreResultsAvailable = false;
            
            try {
                // Build request for AFUniversalCrmRecordAction
                AFUniversalCrmRecordAction.Request actionReq = new AFUniversalCrmRecordAction.Request();
                actionReq.objectApiName = 'Opportunity';
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
                        res.record = (Opportunity) actionRes.record;
                        res.recordId = actionRes.recordId;
                        res.records = new List<Opportunity>{ res.record };
                    } else if (actionRes.records != null && !actionRes.records.isEmpty()) {
                        res.records = new List<Opportunity>();
                        for (SObject so : actionRes.records) {
                            res.records.add((Opportunity) so);
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
                res.errorMessage = 'Error searching Opportunities: ' + e.getMessage();
                System.debug(LoggingLevel.ERROR, 'AFOpportunityFindAction: Exception - ' + e.getMessage());
            }
            
            responses.add(res);
        }
        
        return responses;
    }
}

