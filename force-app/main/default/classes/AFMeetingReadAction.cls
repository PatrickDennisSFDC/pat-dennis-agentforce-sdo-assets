/**
 * AF Meeting Read Action
 * Invocable action for reading Meeting__c records by ID
 * Designed for Agentforce AI agents
 */
public with sharing class AFMeetingReadAction {
    
    public class Request {
        @InvocableVariable(
            label='Record ID'
            description='The Salesforce record ID of the Meeting__c to read. Format: 18-character ID. Use the record ID from a previous findMeetings or createMeeting operation.'
            required=true
        )
        public Id recordId;
    }
    
    public class Response {
        @InvocableVariable(label='Success')
        public Boolean success;
        
        @InvocableVariable(label='Record')
        public Meeting__c record;
        
        @InvocableVariable(label='Record ID')
        public Id recordId;
        
        @InvocableVariable(label='Message')
        public String message;
        
        @InvocableVariable(label='Error Message')
        public String errorMessage;
        
        @InvocableVariable(label='Object Type')
        public String objectType;
        
        @InvocableVariable(label='Related Account Name')
        public String relatedAccountName;
        
        @InvocableVariable(label='Related Contact Name')
        public String relatedContactName;
    }
    
    @InvocableMethod(
        label='Read Meeting'
        description='Retrieves a Meeting__c record by its Salesforce ID. Returns complete Meeting record with related Account and Contact names for context.'
        category='CRM Actions'
    )
    public static List<Response> readMeeting(List<Request> requests) {
        List<Response> responses = new List<Response>();
        
        for (Request req : requests) {
            Response res = new Response();
            res.objectType = 'Meeting__c';
            res.success = false;
            
            try {
                if (req.recordId == null) {
                    res.errorMessage = 'Record ID is required.';
                    responses.add(res);
                    continue;
                }
                
                AFUniversalCrmRecordAction.Request actionReq = new AFUniversalCrmRecordAction.Request();
                actionReq.objectApiName = 'Meeting__c';
                actionReq.operation = 'read';
                actionReq.recordId = req.recordId;
                
                AFUniversalCrmRecordAction.Response actionRes = AFUniversalCrmRecordAction.processRequest(actionReq);
                
                if (actionRes.success && actionRes.record != null) {
                    res.success = true;
                    res.record = (Meeting__c) actionRes.record;
                    res.recordId = actionRes.recordId;
                    res.message = actionRes.message != null ? actionRes.message : 'Meeting retrieved successfully.';
                    res.relatedAccountName = actionRes.relatedAccountName;
                    res.relatedContactName = actionRes.relatedContactName;
                } else {
                    res.success = false;
                    res.errorMessage = actionRes.message != null ? actionRes.message : 'Meeting not found.';
                }
                
            } catch (Exception e) {
                res.success = false;
                res.errorMessage = 'Error retrieving Meeting: ' + e.getMessage();
                System.debug(LoggingLevel.ERROR, 'AFMeetingReadAction: Exception - ' + e.getMessage());
            }
            
            responses.add(res);
        }
        
        return responses;
    }
}


