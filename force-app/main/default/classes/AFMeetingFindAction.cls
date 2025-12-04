/**
 * AF Meeting Find Action
 * Invocable action for finding/searching Meeting__c records
 * Designed for Agentforce AI agents
 */
public with sharing class AFMeetingFindAction {
    
    public class Request {
        @InvocableVariable(
            label='Search Term'
            description='Text to search for in Meeting fields (Subject__c, Description__c, Meeting_Status__c). Example: "Product Review" or "John Smith".'
        )
        public String searchTerm;
        
        @InvocableVariable(
            label='Filters JSON'
            description='JSON string of exact-match filters. Example: {"fieldApiName":"Meeting_Status__c","value":"Scheduled"}. Common filters: Meeting_Status__c, Meeting_Type__c, Meeting_Date__c, Contact__c, Account__c.'
        )
        public String filtersJson;
        
        @InvocableVariable(label='Search Limit')
        public Integer searchLimit;
    }
    
    public class Response {
        @InvocableVariable(label='Success')
        public Boolean success;
        
        @InvocableVariable(label='Record')
        public Meeting__c record;
        
        @InvocableVariable(label='Records')
        public List<Meeting__c> records;
        
        @InvocableVariable(label='Record ID')
        public Id recordId;
        
        @InvocableVariable(label='Message')
        public String message;
        
        @InvocableVariable(label='Error Message')
        public String errorMessage;
        
        @InvocableVariable(label='Object Type')
        public String objectType;
        
        @InvocableVariable(label='Ambiguous Result')
        public Boolean ambiguous;
        
        @InvocableVariable(label='Total Matches')
        public Integer totalMatches;
        
        @InvocableVariable(label='More Results Available')
        public Boolean moreResultsAvailable;
    }
    
    @InvocableMethod(
        label='Find Meetings'
        description='Searches for Meeting__c records using search term and/or filters. Returns Meeting records with related Account and Contact names. Supports filtering by Meeting_Status__c, Meeting_Date__c, Meeting_Type__c, and related objects.'
        category='CRM Actions'
    )
    public static List<Response> findMeetings(List<Request> requests) {
        List<Response> responses = new List<Response>();
        
        for (Request req : requests) {
            Response res = new Response();
            res.objectType = 'Meeting__c';
            res.success = false;
            res.records = new List<Meeting__c>();
            res.totalMatches = 0;
            res.ambiguous = false;
            res.moreResultsAvailable = false;
            
            try {
                AFUniversalCrmRecordAction.Request actionReq = new AFUniversalCrmRecordAction.Request();
                actionReq.objectApiName = 'Meeting__c';
                actionReq.operation = 'find';
                actionReq.searchTerm = req.searchTerm;
                actionReq.filtersJson = req.filtersJson;
                actionReq.searchLimit = req.searchLimit;
                
                AFUniversalCrmRecordAction.Response actionRes = AFUniversalCrmRecordAction.processRequest(actionReq);
                
                if (actionRes.success) {
                    res.success = true;
                    res.message = actionRes.message != null ? actionRes.message : 'Search completed.';
                    res.ambiguous = actionRes.ambiguous != null ? actionRes.ambiguous : false;
                    res.totalMatches = actionRes.totalMatches != null ? actionRes.totalMatches : 0;
                    
                    if (actionRes.record != null) {
                        res.record = (Meeting__c) actionRes.record;
                        res.recordId = actionRes.recordId;
                        res.records = new List<Meeting__c>{ res.record };
                    } else if (actionRes.records != null && !actionRes.records.isEmpty()) {
                        res.records = new List<Meeting__c>();
                        for (SObject so : actionRes.records) {
                            res.records.add((Meeting__c) so);
                        }
                        if (res.records.size() == 1) {
                            res.record = res.records[0];
                            res.recordId = res.records[0].Id;
                        }
                    }
                    
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
                res.errorMessage = 'Error searching Meetings: ' + e.getMessage();
                System.debug(LoggingLevel.ERROR, 'AFMeetingFindAction: Exception - ' + e.getMessage());
            }
            
            responses.add(res);
        }
        
        return responses;
    }
}


