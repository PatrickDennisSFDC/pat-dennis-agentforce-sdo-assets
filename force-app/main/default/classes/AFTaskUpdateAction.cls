/**
 * AF Task Update Action
 * Invocable action for updating Task records
 * Designed for Agentforce AI agents
 */
public with sharing class AFTaskUpdateAction {
    
    /**
     * Request input for update operation
     */
    public class Request {
        @InvocableVariable(
            label='Record ID'
            description='The Salesforce record ID (15 or 18 character) of the Task to update. Required for update operation. Format: 18-character ID like "00Txx000003DGbYAAW". Use the record ID from a previous findTasks, createTask, or readTask operation. The agent should maintain task IDs from the conversation context.'
            required=true
        )
        public Id recordId;
        
        @InvocableVariable(
            label='Field Data JSON'
            description='JSON string containing Task fields to update. Example: {"Status":"Completed","Priority":"High","ActivityDate":"2024-12-15"}. Only include fields that need to be changed. The agent should pass all field updates as a JSON string.'
            required=false
        )
        public String fieldDataJson;
        
        @InvocableVariable(
            label='Account Name'
            description='Account name to resolve to WhatId for the Task. If provided, the system will search for an Account with this name and link the Task to it. Example: "Acme Corp".'
            required=false
        )
        public String accountName;
        
        @InvocableVariable(
            label='Contact Name or Email'
            description='Contact name or email to resolve to WhoId for the Task. If provided, the system will search for a Contact and link the Task to it. Example: "John Smith" or "john@example.com".'
            required=false
        )
        public String contactNameOrEmail;
        
        @InvocableVariable(
            label='Confirm'
            description='Optional: Set to false to preview only without updating. Default (true): Updates the record immediately. When user says "update task", omit this field or set to true to update immediately. Only set to false if user explicitly asks to preview first.'
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
            description='The Task record that was updated. Use the record.Id field from this record for follow-up operations like deleteTask or subsequent updates.'
        )
        public Task record;
        
        @InvocableVariable(
            label='Record ID'
            description='The Salesforce ID of the updated record (18-character format like "00Txx000003DGbYAAW"). Use this ID for deleteTask or subsequent readTask/updateTask operations.'
        )
        public Id recordId;
        
        @InvocableVariable(
            label='Message'
            description='Human-readable message describing the operation result. Use this exact message to inform the user. Example: "Task updated successfully".'
        )
        public String message;
        
        @InvocableVariable(
            label='Error Message'
            description='If success is false, this contains a user-friendly error message to relay directly to the user. Example: "Task not found with ID 00Txx000003DGbYAAW".'
        )
        public String errorMessage;
        
        @InvocableVariable(
            label='Object Type'
            description='The Salesforce object type, always "Task" for Task update operations. Useful for agent context and logging.'
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
            description='JSON string containing metadata for all available fields that can be updated on Task records. Includes API name, label, type, required status, picklist values, help text, and more.'
        )
        public String availableFieldsJson;
        
        @InvocableVariable(
            label='Related Account Name'
            description='Name of the related Account (WhatId) if the task is linked to an account. Use this to provide context to the user.'
        )
        public String relatedAccountName;
        
        @InvocableVariable(
            label='Related Contact Name'
            description='Name of the related Contact (WhoId) if the task is linked to a contact. Use this to provide context to the user.'
        )
        public String relatedContactName;
        
        @InvocableVariable(
            label='Ambiguous Relationship'
            description='True if a related record lookup (Account, Contact, or Opportunity) found multiple matches (2+). When true, DO NOT tell the user the Task was updated. Instead, you MUST present the candidates from relationshipCandidatesJson to the user and ask which one they meant. Say something like: "I found multiple matches for [Account/Contact/Opportunity name]. Which one did you mean?" Then list the candidates with distinguishing details.'
        )
        public Boolean ambiguousRelationship;
        
        @InvocableVariable(
            label='Ambiguous Relationship Type'
            description='The type of relationship that has multiple matches: "Account", "Contact", or "Opportunity". Use this to know what kind of candidates are provided. For example, if this is "Account", the candidates are Account records. If this is "Contact", the candidates are Contact records.'
        )
        public String ambiguousRelationshipType;
        
        @InvocableVariable(
            label='Relationship Candidates JSON'
            description='JSON array of candidate records when ambiguousRelationship is true. Each candidate includes disambiguating details. For Accounts: Name, BillingCity, BillingState, Phone, Industry. For Contacts: Name, Email, Phone, Account.Name, Title. For Opportunities: Name, StageName, Amount, Account.Name, CloseDate. Present these options to the user in a clear, numbered list with the distinguishing details, then ask them to clarify which one they meant. Example: "I found 3 contacts named John Smith: 1) John Smith (john@acme.com, Acme Corp, VP Sales), 2) John Smith (jsmith@globex.com, Globex Inc, Director), 3) John Smith (js@initech.com, Initech, Manager). Which one?"'
        )
        public String relationshipCandidatesJson;
    }
    
    /**
     * Update Task by ID
     */
    @InvocableMethod(
        label='Update Task'
        description='Updates an existing Task record immediately. Pass the Task ID and JSON fields to update: {"Status":"Completed","Priority":"High"}. Default behavior updates the record right away. Optional: Set confirm=false only if user explicitly asks to preview first. If no fieldDataJson is provided, returns current Task data and availableFieldsJson. Supports accountName and contactNameOrEmail parameters to change WhatId or WhoId links.'
        category='CRM Actions'
    )
    public static List<Response> updateTask(List<Request> requests) {
        List<Response> responses = new List<Response>();
        
        for (Request req : requests) {
            Response res = new Response();
            res.objectType = 'Task';
            res.success = false;
            
            try {
                if (req.recordId == null) {
                    res.success = false;
                    res.errorMessage = 'Record ID is required. Provide the 18-character Salesforce Task ID.';
                    responses.add(res);
                    continue;
                }
                
                // Build request for AFUniversalCrmRecordAction
                AFUniversalCrmRecordAction.Request actionReq = new AFUniversalCrmRecordAction.Request();
                actionReq.objectApiName = 'Task';
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
                    res.message = actionRes.message != null ? actionRes.message : 'Task updated successfully.';
                    res.previewOnly = actionRes.previewOnly != null ? actionRes.previewOnly : false;
                    res.previewData = actionRes.previewData;
                    res.availableFieldsJson = actionRes.availableFieldsJson;
                    res.relatedAccountName = actionRes.relatedAccountName;
                    res.relatedContactName = actionRes.relatedContactName;
                    res.ambiguousRelationship = actionRes.ambiguousRelationship != null ? actionRes.ambiguousRelationship : false;
                    res.ambiguousRelationshipType = actionRes.ambiguousRelationshipType;
                    res.relationshipCandidatesJson = actionRes.relationshipCandidatesJson;
                    
                    if (actionRes.record != null) {
                        res.record = (Task) actionRes.record;
                        res.recordId = actionRes.recordId;
                    } else if (actionRes.recordId != null) {
                        res.recordId = actionRes.recordId;
                    }
                } else {
                    res.success = false;
                    res.errorMessage = actionRes.message != null ? actionRes.message : 'Failed to update Task.';
                }
                
            } catch (Exception e) {
                res.success = false;
                res.errorMessage = 'Error updating Task: ' + e.getMessage();
                System.debug(LoggingLevel.ERROR, 'AFTaskUpdateAction: Exception - ' + e.getMessage());
            }
            
            responses.add(res);
        }
        
        return responses;
    }
}

