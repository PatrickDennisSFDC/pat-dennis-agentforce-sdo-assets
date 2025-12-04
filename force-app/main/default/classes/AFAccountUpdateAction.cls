/**
 * AF Account Update Action
 * Invocable action for updating Account records
 * Designed for Agentforce AI agents
 */
public with sharing class AFAccountUpdateAction {
    
    /**
     * Request input for update operation
     */
    public class Request {
        @InvocableVariable(
            label='Record ID'
            description='The Salesforce record ID (15 or 18 character) of the Account to update. Optional if Account Name is provided in fieldDataJson - the system will automatically resolve the record by name. Format: 18-character ID like "001xx000003DGbYAAW". For bulk updates, include Name in each record: [{"Name":"Test 10","Industry":"Tech"},{"Name":"Test 11","Industry":"Finance"}].'
            required=false
        )
        public Id recordId;
        
        @InvocableVariable(
            label='Field Data JSON'
            description='JSON string containing Account fields to update. Example: {"Industry":"Technology","BillingCity":"San Francisco","Phone":"555-1234"}. Only include fields that need to be changed. The agent should pass all field updates as a JSON string.'
            required=false
        )
        public String fieldDataJson;
        
        @InvocableVariable(
            label='Account Name'
            description='Account name to resolve to AccountId for related records (not typically used for Account updates, but available for consistency)'
            required=false
        )
        public String accountName;
        
        @InvocableVariable(
            label='Confirm'
            description='Optional: Set to false to preview only without updating. Default (true): Updates the record immediately. When user says "update account", omit this field or set to true to update immediately. Only set to false if user explicitly asks to preview first.'
            required=false
        )
        public Boolean confirm;
    }
    
    /**
     * Response output for update operation
     */
    public class Response {
        @InvocableVariable(
            label='Success'
            description='True if operation completed successfully, false if an error occurred. Check this before using other output variables.'
        )
        public Boolean success;
        
        @InvocableVariable(
            label='Record'
            description='The Account record that was updated. Use the record.Id field from this record for follow-up operations like deleteAccount or subsequent updates.'
        )
        public Account record;
        
        @InvocableVariable(
            label='Record ID'
            description='The Salesforce ID of the updated record (18-character format like "001xx000003DGbYAAW"). Use this ID for deleteAccount or subsequent readAccount/updateAccount operations.'
        )
        public Id recordId;
        
        @InvocableVariable(
            label='Message'
            description='Human-readable message describing the operation result. Use this exact message to inform the user. Example: "Account updated successfully".'
        )
        public String message;
        
        @InvocableVariable(
            label='Error Message'
            description='If success is false, this contains a user-friendly error message to relay directly to the user. Example: "Account not found with ID 001xx000003DGbYAAW".'
        )
        public String errorMessage;
        
        @InvocableVariable(
            label='Object Type'
            description='The Salesforce object type, always "Account" for Account update operations. Useful for agent context and logging.'
        )
        public String objectType;
        
        @InvocableVariable(
            label='Preview Only'
            description='True if this is a preview response (confirm=false). The record has not been updated yet. The agent should present the preview to the user, then call again with confirm=true to commit.'
        )
        public Boolean previewOnly;
        
        @InvocableVariable(
            label='Preview Data'
            description='A JSON string representation of what would be updated, showing current vs new values. Use this to show the user a preview before committing.'
        )
        public String previewData;
        
        @InvocableVariable(
            label='Available Fields JSON'
            description='JSON string containing metadata for all available fields that can be updated on Account records. Includes API name, label, type, required status, picklist values, help text, and more.'
        )
        public String availableFieldsJson;
        
        @InvocableVariable(
            label='Ambiguous Relationship'
            description='True if a parent Account lookup found multiple matches (2+). When true, DO NOT tell the user the Account was updated. Instead, you MUST present the candidates from relationshipCandidatesJson to the user and ask which Account they meant (for ParentId updates). Say something like: "I found multiple parent accounts with that name. Which one did you mean?" Then list the candidates with distinguishing details.'
        )
        public Boolean ambiguousRelationship;
        
        @InvocableVariable(
            label='Ambiguous Relationship Type'
            description='The type of relationship that has multiple matches, typically "Account" for parent Account lookups during Account updates. Use this to know what kind of candidates are provided in relationshipCandidatesJson.'
        )
        public String ambiguousRelationshipType;
        
        @InvocableVariable(
            label='Relationship Candidates JSON'
            description='JSON array of candidate Account records when ambiguousRelationship is true. Each candidate includes disambiguating details: Name, BillingCity, BillingState, Phone, Industry. Present these options to the user in a clear, numbered list with the distinguishing details, then ask them to clarify which one they meant. Example: "I found 3 accounts named Acme: 1) Acme Corp (San Francisco, CA, Technology), 2) Acme Inc (New York, NY, Manufacturing), 3) Acme LLC (Austin, TX, Retail). Which one?"'
        )
        public String relationshipCandidatesJson;
    }
    
    /**
     * Update Account by ID
     */
    @InvocableMethod(
        label='Update Account'
        description='Updates an existing Account record immediately. Pass Account ID OR include Name in fieldDataJson for automatic resolution: {"Name":"Test 10","Industry":"Technology"}. For bulk updates: [{"Name":"Test 10","Industry":"Tech"},{"Name":"Test 11","Industry":"Finance"}]. Default behavior updates immediately. Optional: Set confirm=false only if user explicitly asks to preview first.'
        category='CRM Actions'
    )
    public static List<Response> updateAccount(List<Request> requests) {
        List<Response> responses = new List<Response>();
        
        for (Request req : requests) {
            Response res = new Response();
            res.objectType = 'Account';
            res.success = false;
            
            try {
                // recordId is now optional - will be resolved by name in AFUniversalCrmRecordAction if needed
                
                // Build request for AFUniversalCrmRecordAction
                AFUniversalCrmRecordAction.Request actionReq = new AFUniversalCrmRecordAction.Request();
                actionReq.objectApiName = 'Account';
                actionReq.operation = 'update';
                actionReq.recordId = req.recordId;
                actionReq.fieldDataJson = req.fieldDataJson;
                actionReq.accountName = req.accountName;
                actionReq.confirm = req.confirm;
                
                // Call shared business logic
                AFUniversalCrmRecordAction.Response actionRes = AFUniversalCrmRecordAction.processRequest(actionReq);
                
                // Convert response
                if (actionRes.success) {
                    res.success = true;
                    res.message = actionRes.message != null ? actionRes.message : 'Account updated successfully.';
                    res.previewOnly = actionRes.previewOnly != null ? actionRes.previewOnly : false;
                    res.previewData = actionRes.previewData;
                    res.availableFieldsJson = actionRes.availableFieldsJson;
                    res.ambiguousRelationship = actionRes.ambiguousRelationship != null ? actionRes.ambiguousRelationship : false;
                    res.ambiguousRelationshipType = actionRes.ambiguousRelationshipType;
                    res.relationshipCandidatesJson = actionRes.relationshipCandidatesJson;
                    
                    if (actionRes.record != null) {
                        res.record = (Account) actionRes.record;
                        res.recordId = actionRes.recordId;
                    } else if (actionRes.recordId != null) {
                        res.recordId = actionRes.recordId;
                    }
                } else {
                    res.success = false;
                    res.errorMessage = actionRes.message != null ? actionRes.message : 'Failed to update Account.';
                }
                
            } catch (Exception e) {
                res.success = false;
                res.errorMessage = 'Error updating Account: ' + e.getMessage();
                System.debug(LoggingLevel.ERROR, 'AFAccountUpdateAction: Exception - ' + e.getMessage());
            }
            
            responses.add(res);
        }
        
        return responses;
    }
}

