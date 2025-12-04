/**
 * AF Opportunity Delete Action
 * Invocable action for deleting Opportunity records (with confirmation pattern)
 * Designed for Agentforce AI agents
 */
public with sharing class AFOpportunityDeleteAction {
    
    /**
     * Request input for delete operation
     */
    public class Request {
        @InvocableVariable(
            label='Record ID'
            description='The Salesforce record ID (15 or 18 character) of the Opportunity to delete. Required for delete operation. Format: 18-character ID like "006xx000003DGbYAAW". Use the record ID from a previous findOpportunities, createOpportunity, or readOpportunity operation.'
            required=true
        )
        public Id recordId;
        
        @InvocableVariable(
            label='Confirm'
            description='Set to true to actually perform the delete operation. If false (default), returns a confirmation message with impact information. The agent should first call with confirm=false to get confirmation details, ask the user, then call again with confirm=true if the user confirms.'
            required=false
        )
        public Boolean confirm;
    }
    
    /**
     * Response output for delete operation
     */
    public class Response {
        @InvocableVariable(
            label='Success'
            description='True if operation completed successfully, false if an error occurred. Check this before using other output variables.'
        )
        public Boolean success;
        
        @InvocableVariable(
            label='Record ID'
            description='The Salesforce ID of the deleted record (18-character format like "006xx000003DGbYAAW"). Useful for confirmation and logging.'
        )
        public Id recordId;
        
        @InvocableVariable(
            label='Message'
            description='Human-readable message describing the operation result. Use this exact message to inform the user. Examples: "Opportunity deleted successfully", "This will delete Opportunity \'New Deal\' and all related records. Call again with confirm=true to proceed."'
        )
        public String message;
        
        @InvocableVariable(
            label='Error Message'
            description='If success is false, this contains a user-friendly error message to relay directly to the user. Example: "Opportunity not found with ID 006xx000003DGbYAAW".'
        )
        public String errorMessage;
        
        @InvocableVariable(
            label='Object Type'
            description='The Salesforce object type, always "Opportunity" for Opportunity delete operations. Useful for agent context and logging.'
        )
        public String objectType;
        
        @InvocableVariable(
            label='Confirmation Required'
            description='True if this is a confirmation request (confirm=false). The agent should present the message to the user and call again with confirm=true if the user confirms the deletion.'
        )
        public Boolean confirmationRequired;
    }
    
    /**
     * Delete Opportunity by ID (with confirmation pattern)
     */
    @InvocableMethod(
        label='Delete Opportunity'
        description='Deletes an Opportunity record by its Salesforce ID. Requires confirmation: first call with confirm=false to get impact information, then call again with confirm=true to actually delete. This two-step process prevents accidental deletions.'
        category='CRM Actions'
    )
    public static List<Response> deleteOpportunity(List<Request> requests) {
        List<Response> responses = new List<Response>();
        
        for (Request req : requests) {
            Response res = new Response();
            res.objectType = 'Opportunity';
            res.success = false;
            res.confirmationRequired = false;
            
            try {
                if (req.recordId == null) {
                    res.success = false;
                    res.errorMessage = 'Record ID is required. Provide the 18-character Salesforce Opportunity ID.';
                    responses.add(res);
                    continue;
                }
                
                // Check if confirmation is required
                if (req.confirm == null || req.confirm == false) {
                    // Return confirmation message with impact info
                    res.confirmationRequired = true;
                    res.recordId = req.recordId;
                    
                    // Get opportunity info for confirmation message
                    try {
                        List<Opportunity> opportunities = [SELECT Id, Name FROM Opportunity WHERE Id = :req.recordId LIMIT 1];
                        if (!opportunities.isEmpty()) {
                            Opportunity opp = opportunities[0];
                            res.message = 'This will delete Opportunity \'' + opp.Name + '\' and all related records. Call again with confirm=true to proceed.';
                            res.success = true; // Confirmation request is successful
                        } else {
                            res.message = 'Opportunity not found with ID ' + req.recordId + '.';
                            res.errorMessage = res.message;
                        }
                    } catch (Exception e) {
                        res.message = 'This will delete the Opportunity. Call again with confirm=true to proceed.';
                        res.success = true;
                    }
                    responses.add(res);
                    continue;
                }
                
                // Perform actual delete
                // Build request for AFUniversalCrmRecordAction
                AFUniversalCrmRecordAction.Request actionReq = new AFUniversalCrmRecordAction.Request();
                actionReq.objectApiName = 'Opportunity';
                actionReq.operation = 'delete';
                actionReq.recordId = req.recordId;
                
                // Call shared business logic
                AFUniversalCrmRecordAction.Response actionRes = AFUniversalCrmRecordAction.processRequest(actionReq);
                
                // Convert response
                if (actionRes.success) {
                    res.success = true;
                    res.recordId = actionRes.recordId;
                    res.message = actionRes.message != null ? actionRes.message : 'Opportunity deleted successfully.';
                } else {
                    res.success = false;
                    res.errorMessage = actionRes.message != null ? actionRes.message : 'Failed to delete Opportunity.';
                }
                
            } catch (Exception e) {
                res.success = false;
                res.errorMessage = 'Error deleting Opportunity: ' + e.getMessage();
                System.debug(LoggingLevel.ERROR, 'AFOpportunityDeleteAction: Exception - ' + e.getMessage());
            }
            
            responses.add(res);
        }
        
        return responses;
    }
}

