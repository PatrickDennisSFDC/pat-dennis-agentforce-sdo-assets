/**
 * AF Case Read Action
 * Invocable action for reading Case records by ID
 * Designed for Agentforce AI agents
 */
public with sharing class AFCaseReadAction {
    
    /**
     * Request input for read operation
     */
    public class Request {
        @InvocableVariable(
            label='Record ID'
            description='The Salesforce record ID (15 or 18 character) of the Case to read. Required for read operation. Format: 18-character ID like "500xx000003DGbYAAW" or 15-character like "500xx000003DGbY". Use the record ID from a previous findCases or createCase operation.'
            required=true
        )
        public Id recordId;
    }
    
    /**
     * Response output for read operation
     */
    public class Response {
        @InvocableVariable(
            label='Success'
            description='True if operation completed successfully, false if an error occurred. Check this before using other output variables.'
        )
        public Boolean success;
        
        @InvocableVariable(
            label='Record'
            description='The Case record that was retrieved. Use the record.Id field from this record for follow-up operations like updateCase or deleteCase.'
        )
        public Case record;
        
        @InvocableVariable(
            label='Record ID'
            description='The Salesforce ID of the record (18-character format like "500xx000003DGbYAAW"). Use this ID for updateCase, deleteCase, or subsequent readCase operations.'
        )
        public Id recordId;
        
        @InvocableVariable(
            label='Message'
            description='Human-readable message describing the operation result. Use this exact message to inform the user. Example: "Case retrieved successfully".'
        )
        public String message;
        
        @InvocableVariable(
            label='Error Message'
            description='If success is false, this contains a user-friendly error message to relay directly to the user. Example: "Case not found with ID 500xx000003DGbYAAW".'
        )
        public String errorMessage;
        
        @InvocableVariable(
            label='Object Type'
            description='The Salesforce object type, always "Case" for Case read operations. Useful for agent context and logging.'
        )
        public String objectType;
    }
    
    /**
     * Read Case by ID
     */
    @InvocableMethod(
        label='Read Case'
        description='Retrieves a Case record by its Salesforce ID. Returns the complete Case record with all accessible fields. Use this to get current Case data before updating or to display Case details to the user.'
        category='CRM Actions'
    )
    public static List<Response> readCase(List<Request> requests) {
        List<Response> responses = new List<Response>();
        
        for (Request req : requests) {
            Response res = new Response();
            res.objectType = 'Case';
            res.success = false;
            
            try {
                if (req.recordId == null) {
                    res.success = false;
                    res.errorMessage = 'Record ID is required. Provide the 18-character Salesforce Case ID.';
                    responses.add(res);
                    continue;
                }
                
                // Build request for AFUniversalCrmRecordAction
                AFUniversalCrmRecordAction.Request actionReq = new AFUniversalCrmRecordAction.Request();
                actionReq.objectApiName = 'Case';
                actionReq.operation = 'read';
                actionReq.recordId = req.recordId;
                
                // Call shared business logic
                AFUniversalCrmRecordAction.Response actionRes = AFUniversalCrmRecordAction.processRequest(actionReq);
                
                // Convert response
                if (actionRes.success && actionRes.record != null) {
                    res.success = true;
                    res.record = (Case) actionRes.record;
                    res.recordId = actionRes.recordId;
                    res.message = actionRes.message != null ? actionRes.message : 'Case retrieved successfully.';
                } else {
                    res.success = false;
                    res.errorMessage = actionRes.message != null ? actionRes.message : 'Case not found.';
                }
                
            } catch (Exception e) {
                res.success = false;
                res.errorMessage = 'Error retrieving Case: ' + e.getMessage();
                System.debug(LoggingLevel.ERROR, 'AFCaseReadAction: Exception - ' + e.getMessage());
            }
            
            responses.add(res);
        }
        
        return responses;
    }
}

