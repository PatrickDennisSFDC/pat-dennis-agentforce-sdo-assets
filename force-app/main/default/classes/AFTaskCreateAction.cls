/**
 * AF Task Create Action
 * Invocable action for creating Task records (single or bulk)
 * Designed for Agentforce AI agents
 */
public with sharing class AFTaskCreateAction {
    
    /**
     * Request input for create operation
     */
    public class Request {
        @InvocableVariable(
            label='Field Data JSON'
            description='JSON string containing Task field data. For single record: {"Subject":"Follow up with John","Priority":"High","ActivityDate":"2024-12-10"}. For bulk: [{"Subject":"Task 1"},{"Subject":"Task 2"}]. The agent should intelligently map user descriptions to Subject and Description fields. Status defaults to org default (typically "Not Started"). Optional fields: Priority, ActivityDate (due date), Description, WhoId, WhatId.'
            required=true
        )
        public String fieldDataJson;
        
        @InvocableVariable(
            label='Account Name'
            description='Account name to resolve to WhatId for the Task. If provided, the system will search for an Account with this name and link the Task to it via WhatId. Example: "Acme Corp". Use this when the task is related to an account.'
            required=false
        )
        public String accountName;
        
        @InvocableVariable(
            label='Contact Name or Email'
            description='Contact name or email to resolve to WhoId for the Task. If provided, the system will search for a Contact and link the Task to it via WhoId. Example: "John Smith" or "john@example.com". Use this when the task is related to a contact.'
            required=false
        )
        public String contactNameOrEmail;
        
        @InvocableVariable(
            label='Confirm'
            description='Optional: Set to false to preview only without creating. Default (true): Creates the record immediately. When user says "create task", omit this field or set to true to create immediately. Only set to false if user explicitly asks to preview first.'
            required=false
        )
        public Boolean confirm;
    }
    
    /**
     * Response output for create operation
     */
    public class Response {
        @InvocableVariable(
            label='Success'
            description='True if operation completed successfully, false if an error occurred. Check this before using other output variables.'
        )
        public Boolean success;
        
        @InvocableVariable(
            label='Record'
            description='The Task record that was created (for single create operation). Use the record.Id field from this record for follow-up operations like updateTask or deleteTask. This is null for bulk operations.'
        )
        public Task record;
        
        @InvocableVariable(
            label='Records'
            description='List of Task records created (for bulk create operation). Use record.Id from each record for subsequent operations. For single create, this will contain one record.'
        )
        public List<Task> records;
        
        @InvocableVariable(
            label='Record ID'
            description='The Salesforce ID of the created Task record (18-character format like "00Txx000003DGbYAAW"). Use this ID for updateTask, deleteTask, or readTask operations. This is the primary identifier for follow-up operations in the conversation.'
        )
        public Id recordId;
        
        @InvocableVariable(
            label='Message'
            description='Human-readable message describing the operation result. Use this exact message to inform the user. Examples: "Task created successfully with ID 00Txx000003DGbYAAW", "Successfully created 3 Task records".'
        )
        public String message;
        
        @InvocableVariable(
            label='Error Message'
            description='If success is false, this contains a user-friendly error message to relay directly to the user. Example: "To create a Task, at least Subject or Description should be provided." Do not use technical error details.'
        )
        public String errorMessage;
        
        @InvocableVariable(
            label='Object Type'
            description='The Salesforce object type, always "Task" for Task create operations. Useful for agent context and logging.'
        )
        public String objectType;
        
        @InvocableVariable(
            label='Preview Only'
            description='True if this is a preview response (confirm=false). The record has not been created yet. The agent should present the preview to the user, collect additional field data if enrichment is suggested, then call again with confirm=true to commit.'
        )
        public Boolean previewOnly;
        
        @InvocableVariable(
            label='Enrichment Suggested'
            description='True if the provided data is minimal and additional fields are suggested. When true, check suggestedFields for commonly-used fields that could be populated to enrich the record.'
        )
        public Boolean enrichmentSuggested;
        
        @InvocableVariable(
            label='Suggested Fields'
            description='List of commonly-used field API names that could be populated to enrich this Task. Examples: Priority, ActivityDate, Description. The agent should ask the user about these fields and add them to fieldDataJson before calling again with confirm=true.'
        )
        public List<String> suggestedFields;
        
        @InvocableVariable(
            label='Preview Data'
            description='A JSON string representation of what would be created. Use this to show the user a preview before committing.'
        )
        public String previewData;
        
        @InvocableVariable(
            label='Available Fields JSON'
            description='JSON string containing metadata for all available fields that can be set on Task records. Includes API name, label, type, required status, picklist values, help text, and more.'
        )
        public String availableFieldsJson;
        
        @InvocableVariable(
            label='Related Account Name'
            description='Name of the related Account (WhatId) if the task is linked to an account. Use this to provide context: "Task created for Account: Acme Corp".'
        )
        public String relatedAccountName;
        
        @InvocableVariable(
            label='Related Contact Name'
            description='Name of the related Contact (WhoId) if the task is linked to a contact. Use this to provide context: "Task created for Contact: John Smith".'
        )
        public String relatedContactName;
        
        @InvocableVariable(
            label='Ambiguous Relationship'
            description='True if a related record lookup (Account, Contact, or Opportunity) found multiple matches (2+). When true, DO NOT tell the user the Task was created. Instead, you MUST present the candidates from relationshipCandidatesJson to the user and ask which one they meant. Say something like: "I found multiple matches for [Account/Contact/Opportunity name]. Which one did you mean?" Then list the candidates with distinguishing details.'
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
     * Create Task(s) - supports both single and bulk creation
     * Detects automatically if fieldDataJson is a single object or array
     */
    @InvocableMethod(
        label='Create Task'
        description='Creates a new Task record immediately. The agent should intelligently map user descriptions to Subject and Description fields. Example: {"Subject":"Follow up","Priority":"High","ActivityDate":"2024-12-10"}. Status defaults to org default. Use accountName or contactNameOrEmail to link task to Account (WhatId) or Contact (WhoId). Supports bulk creation with JSON array.'
        category='CRM Actions'
    )
    public static List<Response> createTask(List<Request> requests) {
        List<Response> responses = new List<Response>();
        
        for (Request req : requests) {
            Response res = new Response();
            res.objectType = 'Task';
            res.success = false;
            res.records = new List<Task>();
            
            try {
                if (String.isBlank(req.fieldDataJson)) {
                    res.success = false;
                    res.errorMessage = 'Field Data JSON is required. Provide Task data as JSON string, e.g., {"Subject":"Follow up with customer","Priority":"High"}.';
                    responses.add(res);
                    continue;
                }
                
                // Parse JSON to detect if single or bulk
                Object parsed = JSON.deserializeUntyped(req.fieldDataJson);
                Boolean isBulk = parsed instanceof List<Object>;
                
                // Build request for AFUniversalCrmRecordAction
                AFUniversalCrmRecordAction.Request actionReq = new AFUniversalCrmRecordAction.Request();
                actionReq.objectApiName = 'Task';
                actionReq.accountName = req.accountName;
                actionReq.contactNameOrEmail = req.contactNameOrEmail;
                actionReq.confirm = req.confirm;
                
                if (isBulk) {
                    actionReq.operation = 'bulkCreate';
                    actionReq.bulkRecordsJson = req.fieldDataJson;
                } else {
                    actionReq.operation = 'create';
                    actionReq.fieldDataJson = req.fieldDataJson;
                }
                
                // Call shared business logic
                AFUniversalCrmRecordAction.Response actionRes = AFUniversalCrmRecordAction.processRequest(actionReq);
                
                // Convert response
                if (actionRes.success) {
                    res.success = true;
                    res.message = actionRes.message;
                    res.previewOnly = actionRes.previewOnly != null ? actionRes.previewOnly : false;
                    res.enrichmentSuggested = actionRes.enrichmentSuggested != null ? actionRes.enrichmentSuggested : false;
                    res.suggestedFields = actionRes.suggestedFields;
                    res.previewData = actionRes.previewData;
                    res.availableFieldsJson = actionRes.availableFieldsJson;
                    res.relatedAccountName = actionRes.relatedAccountName;
                    res.relatedContactName = actionRes.relatedContactName;
                    res.ambiguousRelationship = actionRes.ambiguousRelationship != null ? actionRes.ambiguousRelationship : false;
                    res.ambiguousRelationshipType = actionRes.ambiguousRelationshipType;
                    res.relationshipCandidatesJson = actionRes.relationshipCandidatesJson;
                    
                    if (actionRes.record != null) {
                        res.record = (Task) actionRes.record;
                        // ALWAYS extract ID directly from the record object
                        res.recordId = res.record.Id;
                        res.records = new List<Task>{ res.record };
                        System.debug(LoggingLevel.INFO, 'AFTaskCreateAction: Set recordId from record object: ' + res.recordId);
                    } else if (actionRes.records != null && !actionRes.records.isEmpty()) {
                        res.records = new List<Task>();
                        for (SObject so : actionRes.records) {
                            res.records.add((Task) so);
                        }
                        if (!res.records.isEmpty()) {
                            res.record = res.records[0];
                            // ALWAYS extract ID directly from first record
                            res.recordId = res.records[0].Id;
                            System.debug(LoggingLevel.INFO, 'AFTaskCreateAction: Set recordId from records array: ' + res.recordId);
                        }
                    } else if (actionRes.recordId != null) {
                        // Fallback: use recordId from response if record object not available
                        res.recordId = actionRes.recordId;
                        System.debug(LoggingLevel.INFO, 'AFTaskCreateAction: Set recordId from actionRes.recordId: ' + res.recordId);
                    } else {
                        System.debug(LoggingLevel.WARN, 'AFTaskCreateAction: No recordId found in response! record=' + actionRes.record + ', records=' + actionRes.records + ', recordId=' + actionRes.recordId);
                    }
                } else {
                    res.success = false;
                    res.errorMessage = actionRes.message != null ? actionRes.message : 'Failed to create Task.';
                }
                
            } catch (Exception e) {
                res.success = false;
                res.errorMessage = 'Error creating Task: ' + e.getMessage();
                System.debug(LoggingLevel.ERROR, 'AFTaskCreateAction: Exception - ' + e.getMessage());
            }
            
            responses.add(res);
        }
        
        return responses;
    }
}

