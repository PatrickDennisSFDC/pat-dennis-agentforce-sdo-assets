/**
 * AF Case Update Action
 * Invocable action for updating Case records
 * Designed for Agentforce AI agents
 */
public with sharing class AFCaseUpdateAction {
    
    /**
     * Request input for update operation
     */
    public class Request {
        @InvocableVariable(
            label='Record ID'
            description='The Salesforce record ID (15 or 18 character) of the Case to update. Required for update operation. Format: 18-character ID like "500xx000003DGbYAAW". Use the record ID from a previous findCases, createCase, or readCase operation.'
            required=true
        )
        public Id recordId;
        
        @InvocableVariable(
            label='Field Data JSON'
            description='JSON string containing Case fields to update. Example: {"Status":"Closed","Priority":"High"}. Only include fields that need to be changed. The agent should pass all field updates as a JSON string.'
            required=false
        )
        public String fieldDataJson;
        
        @InvocableVariable(
            label='Account Name'
            description='Account name to resolve to AccountId for the Case. If provided, the system will search for an Account with this name and link the Case to it. Example: "Acme Corp".'
            required=false
        )
        public String accountName;
        
        @InvocableVariable(
            label='Contact Name or Email'
            description='Contact name or email to resolve to ContactId for the Case. If provided, the system will search for a Contact with this name or email and link the Case to it. Example: "John Smith" or "john@example.com".'
            required=false
        )
        public String contactNameOrEmail;
        
        @InvocableVariable(
            label='Confirm'
            description='Optional: Set to false to preview only without updating. Default (true): Updates the record immediately. When user says "update case", omit this field or set to true to update immediately. Only set to false if user explicitly asks to preview first.'
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
            description='The Case record that was updated. Use the record.Id field from this record for follow-up operations like deleteCase or subsequent updates.'
        )
        public Case record;
        
        @InvocableVariable(
            label='Record ID'
            description='The Salesforce ID of the updated record (18-character format like "500xx000003DGbYAAW"). Use this ID for deleteCase or subsequent readCase/updateCase operations.'
        )
        public Id recordId;
        
        @InvocableVariable(
            label='Message'
            description='Human-readable message describing the operation result. Use this exact message to inform the user. Example: "Case updated successfully".'
        )
        public String message;
        
        @InvocableVariable(
            label='Error Message'
            description='If success is false, this contains a user-friendly error message to relay directly to the user. Example: "Case not found with ID 500xx000003DGbYAAW".'
        )
        public String errorMessage;
        
        @InvocableVariable(
            label='Object Type'
            description='The Salesforce object type, always "Case" for Case update operations. Useful for agent context and logging.'
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
            description='JSON string containing metadata for all available fields that can be updated on Case records. Includes API name, label, type, required status, picklist values, help text, and more.'
        )
        public String availableFieldsJson;
        
        @InvocableVariable(
            label='Ambiguous Relationship'
            description='True if a related record lookup (Account or Contact) found multiple matches (2+). When true, DO NOT tell the user the Case was updated. Instead, you MUST present the candidates from relationshipCandidatesJson to the user and ask which one they meant. Say something like: "I found multiple matches for [Account/Contact name]. Which one did you mean?" Then list the candidates with distinguishing details.'
        )
        public Boolean ambiguousRelationship;
        
        @InvocableVariable(
            label='Ambiguous Relationship Type'
            description='The type of relationship that has multiple matches: "Account" or "Contact". Use this to know what kind of candidates are provided. For example, if this is "Account", the candidates are Account records. If this is "Contact", the candidates are Contact records.'
        )
        public String ambiguousRelationshipType;
        
        @InvocableVariable(
            label='Relationship Candidates JSON'
            description='JSON array of candidate records when ambiguousRelationship is true. Each candidate includes disambiguating details. For Accounts: Name, BillingCity, BillingState, Phone, Industry. For Contacts: Name, Email, Phone, Account.Name, Title. Present these options to the user in a clear, numbered list with the distinguishing details, then ask them to clarify which one they meant. Example: "I found 2 contacts: 1) John Smith (john@acme.com, Acme Corp, VP Sales), 2) John Smith (jsmith@globex.com, Globex Inc). Which one?"'
        )
        public String relationshipCandidatesJson;
    }
    
    /**
     * Update Case by ID
     */
    @InvocableMethod(
        label='Update Case'
        description='Updates an existing Case record immediately. Pass the Case ID and JSON fields to update: {"Status":"Closed","Priority":"High"}. Default behavior updates the record right away. Optional: Set confirm=false only if user explicitly asks to preview first. If no fieldDataJson is provided, returns current Case data and availableFieldsJson. Supports accountName and contactNameOrEmail parameters to change Account or Contact links.'
        category='CRM Actions'
    )
    public static List<Response> updateCase(List<Request> requests) {
        List<Response> responses = new List<Response>();
        
        for (Request req : requests) {
            Response res = new Response();
            res.objectType = 'Case';
            res.success = false;
            
            try {
                // recordId is required for Case - no name resolution (Subject is not unique enough)
                
                // Build request for AFUniversalCrmRecordAction
                AFUniversalCrmRecordAction.Request actionReq = new AFUniversalCrmRecordAction.Request();
                actionReq.objectApiName = 'Case';
                actionReq.operation = 'update';
                actionReq.recordId = req.recordId;
                actionReq.fieldDataJson = req.fieldDataJson;
                actionReq.accountName = req.accountName;
                actionReq.contactNameOrEmail = req.contactNameOrEmail;
                actionReq.confirm = req.confirm;
                
                // Call shared business logic
                AFUniversalCrmRecordAction.Response actionRes = AFUniversalCrmRecordAction.processRequest(actionReq);
                
                // Convert response
                if (actionRes.success) {
                    res.success = true;
                    res.message = actionRes.message != null ? actionRes.message : 'Case updated successfully.';
                    res.previewOnly = actionRes.previewOnly != null ? actionRes.previewOnly : false;
                    res.previewData = actionRes.previewData;
                    res.availableFieldsJson = actionRes.availableFieldsJson;
                    res.ambiguousRelationship = actionRes.ambiguousRelationship != null ? actionRes.ambiguousRelationship : false;
                    res.ambiguousRelationshipType = actionRes.ambiguousRelationshipType;
                    res.relationshipCandidatesJson = actionRes.relationshipCandidatesJson;
                    
                    if (actionRes.record != null) {
                        res.record = (Case) actionRes.record;
                        res.recordId = actionRes.recordId;
                    } else if (actionRes.recordId != null) {
                        res.recordId = actionRes.recordId;
                    }
                } else {
                    res.success = false;
                    res.errorMessage = actionRes.message != null ? actionRes.message : 'Failed to update Case.';
                }
                
            } catch (Exception e) {
                res.success = false;
                res.errorMessage = 'Error updating Case: ' + e.getMessage();
                System.debug(LoggingLevel.ERROR, 'AFCaseUpdateAction: Exception - ' + e.getMessage());
            }
            
            responses.add(res);
        }
        
        return responses;
    }
}

