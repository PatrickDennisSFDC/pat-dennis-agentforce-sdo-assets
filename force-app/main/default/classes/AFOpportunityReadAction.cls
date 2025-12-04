/**
 * AF Opportunity Read Action
 * Invocable action for reading Opportunity records by ID
 * Designed for Agentforce AI agents
 */
public with sharing class AFOpportunityReadAction {
    
    /**
     * Request input for read operation
     */
    public class Request {
        @InvocableVariable(
            label='Record ID'
            description='The Salesforce record ID (15 or 18 character) of the Opportunity to read. Required for read operation. Format: 18-character ID like "006xx000003DGbYAAW" or 15-character like "006xx000003DGbY". Use the record ID from a previous findOpportunities or createOpportunity operation.'
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
            description='The Opportunity record that was retrieved. Use the record.Id field from this record for follow-up operations like updateOpportunity or deleteOpportunity.'
        )
        public Opportunity record;
        
        @InvocableVariable(
            label='Record ID'
            description='The Salesforce ID of the record (18-character format like "006xx000003DGbYAAW"). Use this ID for updateOpportunity, deleteOpportunity, or subsequent readOpportunity operations.'
        )
        public Id recordId;
        
        @InvocableVariable(
            label='Message'
            description='Human-readable message describing the operation result. Use this exact message to inform the user. Example: "Opportunity retrieved successfully".'
        )
        public String message;
        
        @InvocableVariable(
            label='Error Message'
            description='If success is false, this contains a user-friendly error message to relay directly to the user. Example: "Opportunity not found with ID 006xx000003DGbYAAW".'
        )
        public String errorMessage;
        
        @InvocableVariable(
            label='Object Type'
            description='The Salesforce object type, always "Opportunity" for Opportunity read operations. Useful for agent context and logging.'
        )
        public String objectType;
    }
    
    /**
     * Read Opportunity by ID
     */
    @InvocableMethod(
        label='Read Opportunity'
        description='Retrieves an Opportunity record by its Salesforce ID. Returns the complete Opportunity record with all accessible fields. Use this to get current Opportunity data before updating or to display Opportunity details to the user.'
        category='CRM Actions'
    )
    public static List<Response> readOpportunity(List<Request> requests) {
        List<Response> responses = new List<Response>();
        
        for (Request req : requests) {
            Response res = new Response();
            res.objectType = 'Opportunity';
            res.success = false;
            
            try {
                if (req.recordId == null) {
                    res.success = false;
                    res.errorMessage = 'Record ID is required. Provide the 18-character Salesforce Opportunity ID.';
                    responses.add(res);
                    continue;
                }
                
                // Build request for AFUniversalCrmRecordAction
                AFUniversalCrmRecordAction.Request actionReq = new AFUniversalCrmRecordAction.Request();
                actionReq.objectApiName = 'Opportunity';
                actionReq.operation = 'read';
                actionReq.recordId = req.recordId;
                
                // Call shared business logic
                AFUniversalCrmRecordAction.Response actionRes = AFUniversalCrmRecordAction.processRequest(actionReq);
                
                // Convert response
                if (actionRes.success && actionRes.record != null) {
                    res.success = true;
                    res.record = (Opportunity) actionRes.record;
                    res.recordId = actionRes.recordId;
                    res.message = actionRes.message != null ? actionRes.message : 'Opportunity retrieved successfully.';
                } else {
                    res.success = false;
                    res.errorMessage = actionRes.message != null ? actionRes.message : 'Opportunity not found.';
                }
                
            } catch (Exception e) {
                res.success = false;
                res.errorMessage = 'Error retrieving Opportunity: ' + e.getMessage();
                System.debug(LoggingLevel.ERROR, 'AFOpportunityReadAction: Exception - ' + e.getMessage());
            }
            
            responses.add(res);
        }
        
        return responses;
    }
}

