/**
 * AF Account Read Action
 * Invocable action for reading Account records by ID
 * Designed for Agentforce AI agents
 */
public with sharing class AFAccountReadAction {
    
    /**
     * Request input for read operation
     */
    public class Request {
        @InvocableVariable(
            label='Record ID'
            description='The Salesforce record ID (15 or 18 character) of the Account to read. Required for read operation. Format: 18-character ID like "001xx000003DGbYAAW" or 15-character like "001xx000003DGbY". Use the record ID from a previous findAccounts or createAccount operation.'
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
            description='The Account record that was retrieved. Use the record.Id field from this record for follow-up operations like updateAccount or deleteAccount.'
        )
        public Account record;
        
        @InvocableVariable(
            label='Record ID'
            description='The Salesforce ID of the record (18-character format like "001xx000003DGbYAAW"). Use this ID for updateAccount, deleteAccount, or subsequent readAccount operations.'
        )
        public Id recordId;
        
        @InvocableVariable(
            label='Message'
            description='Human-readable message describing the operation result. Use this exact message to inform the user. Example: "Account retrieved successfully".'
        )
        public String message;
        
        @InvocableVariable(
            label='Error Message'
            description='If success is false, this contains a user-friendly error message to relay directly to the user. Example: "Account not found with ID 001xx000003DGbYAAW".'
        )
        public String errorMessage;
        
        @InvocableVariable(
            label='Object Type'
            description='The Salesforce object type, always "Account" for Account read operations. Useful for agent context and logging.'
        )
        public String objectType;
    }
    
    /**
     * Read Account by ID
     */
    @InvocableMethod(
        label='Read Account'
        description='Retrieves an Account record by its Salesforce ID. Returns the complete Account record with all accessible fields. Use this to get current Account data before updating or to display Account details to the user.'
        category='CRM Actions'
    )
    public static List<Response> readAccount(List<Request> requests) {
        List<Response> responses = new List<Response>();
        
        for (Request req : requests) {
            Response res = new Response();
            res.objectType = 'Account';
            res.success = false;
            
            try {
                if (req.recordId == null) {
                    res.success = false;
                    res.errorMessage = 'Record ID is required. Provide the 18-character Salesforce Account ID.';
                    responses.add(res);
                    continue;
                }
                
                // Build request for AFUniversalCrmRecordAction
                AFUniversalCrmRecordAction.Request actionReq = new AFUniversalCrmRecordAction.Request();
                actionReq.objectApiName = 'Account';
                actionReq.operation = 'read';
                actionReq.recordId = req.recordId;
                
                // Call shared business logic
                AFUniversalCrmRecordAction.Response actionRes = AFUniversalCrmRecordAction.processRequest(actionReq);
                
                // Convert response
                if (actionRes.success && actionRes.record != null) {
                    res.success = true;
                    res.record = (Account) actionRes.record;
                    res.recordId = actionRes.recordId;
                    res.message = actionRes.message != null ? actionRes.message : 'Account retrieved successfully.';
                } else {
                    res.success = false;
                    res.errorMessage = actionRes.message != null ? actionRes.message : 'Account not found.';
                }
                
            } catch (Exception e) {
                res.success = false;
                res.errorMessage = 'Error retrieving Account: ' + e.getMessage();
                System.debug(LoggingLevel.ERROR, 'AFAccountReadAction: Exception - ' + e.getMessage());
            }
            
            responses.add(res);
        }
        
        return responses;
    }
}

