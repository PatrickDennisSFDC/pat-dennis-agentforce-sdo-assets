/**
 * AF Account Create Action
 * Invocable action for creating Account records (single or bulk)
 * Designed for Agentforce AI agents
 */
public with sharing class AFAccountCreateAction {
    
    /**
     * Request input for create operation
     */
    public class Request {
        @InvocableVariable(
            label='Field Data JSON'
            description='JSON string containing Account field data. For single record: {"Name":"Acme Corp","Industry":"Technology"}. For bulk (multiple records): [{"Name":"Acme"},{"Name":"Globex"}]. Required fields: Name. Optional fields: Industry, BillingCity, BillingState, Phone, Website, etc. The agent should pass all field data as a JSON string.'
            required=true
        )
        public String fieldDataJson;
        
        @InvocableVariable(
            label='Account Name'
            description='Account name to resolve to AccountId for related records (not typically used for Account creation, but available for consistency)'
            required=false
        )
        public String accountName;
        
        @InvocableVariable(
            label='Confirm'
            description='Optional: Set to false to preview only without creating. Default (true): Creates the record immediately. When user says "create account", omit this field or set to true to create immediately. Only set to false if user explicitly asks to preview first.'
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
            description='The Account record that was created (for single create operation). Use the record.Id field from this record for follow-up operations like updateAccount or deleteAccount. This is null for bulk operations.'
        )
        public Account record;
        
        @InvocableVariable(
            label='Records'
            description='List of Account records created (for bulk create operation). Use record.Id from each record for subsequent operations. For single create, this will contain one record.'
        )
        public List<Account> records;
        
        @InvocableVariable(
            label='Record ID'
            description='The Salesforce ID of the created record (18-character format like "001xx000003DGbYAAW"). Use this ID for updateAccount, deleteAccount, or readAccount operations. This is the primary identifier for follow-up operations in the conversation.'
        )
        public Id recordId;
        
        @InvocableVariable(
            label='Message'
            description='Human-readable message describing the operation result. Use this exact message to inform the user. Examples: "Account created successfully with ID 001xx000003DGbYAAW", "Successfully created 3 Account records".'
        )
        public String message;
        
        @InvocableVariable(
            label='Error Message'
            description='If success is false, this contains a user-friendly error message to relay directly to the user. Example: "To create an Account, the Name field is required." Do not use technical error details.'
        )
        public String errorMessage;
        
        @InvocableVariable(
            label='Object Type'
            description='The Salesforce object type, always "Account" for Account create operations. Useful for agent context and logging.'
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
            description='List of commonly-used field API names that could be populated to enrich this Account. Examples: Industry, BillingCity, Phone, Website. The agent should ask the user about these fields and add them to fieldDataJson before calling again with confirm=true.'
        )
        public List<String> suggestedFields;
        
        @InvocableVariable(
            label='Preview Data'
            description='A JSON string representation of what would be created. Use this to show the user a preview before committing. Format: {"Name":"Test 1","Industry":null,"BillingCity":null,...}'
        )
        public String previewData;
        
        @InvocableVariable(
            label='Available Fields JSON'
            description='JSON string containing metadata for all available fields that can be set on Account records. Includes API name, label, type, required status, picklist values, help text, and more. Use this to understand what fields are available and their constraints.'
        )
        public String availableFieldsJson;
        
        @InvocableVariable(
            label='Ambiguous Relationship'
            description='True if a parent Account lookup found multiple matches (2+). When true, DO NOT tell the user the Account was created. Instead, you MUST present the candidates from relationshipCandidatesJson to the user and ask which parent Account they meant (for ParentId). Say something like: "I found multiple parent accounts with that name. Which one did you mean?" Then list the candidates with distinguishing details.'
        )
        public Boolean ambiguousRelationship;
        
        @InvocableVariable(
            label='Ambiguous Relationship Type'
            description='The type of relationship that has multiple matches, typically "Account" for parent Account lookups during Account creation. Use this to know what kind of candidates are provided in relationshipCandidatesJson.'
        )
        public String ambiguousRelationshipType;
        
        @InvocableVariable(
            label='Relationship Candidates JSON'
            description='JSON array of candidate Account records when ambiguousRelationship is true. Each candidate includes disambiguating details: Name, BillingCity, BillingState, Phone, Industry. Present these options to the user in a clear, numbered list with the distinguishing details, then ask them to clarify which one they meant. Example: "I found 3 accounts named Acme: 1) Acme Corp (San Francisco, CA, Technology), 2) Acme Inc (New York, NY, Manufacturing), 3) Acme LLC (Austin, TX, Retail). Which one?"'
        )
        public String relationshipCandidatesJson;
    }
    
    /**
     * Create Account(s) - supports both single and bulk creation
     * Detects automatically if fieldDataJson is a single object or array
     */
    @InvocableMethod(
        label='Create Account'
        description='Creates a new Account record immediately. Required field: Name. Pass JSON object: {"Name":"Acme Corp","Industry":"Technology"}. Default behavior creates the record right away. Optional: Set confirm=false only if user explicitly asks to preview first. Supports bulk creation with JSON array.'
        category='CRM Actions'
    )
    public static List<Response> createAccount(List<Request> requests) {
        List<Response> responses = new List<Response>();
        
        for (Request req : requests) {
            Response res = new Response();
            res.objectType = 'Account';
            res.success = false;
            res.records = new List<Account>();
            
            try {
                if (String.isBlank(req.fieldDataJson)) {
                    res.success = false;
                    res.errorMessage = 'Field Data JSON is required. Provide Account data as JSON string, e.g., {"Name":"Acme Corp"}.';
                    responses.add(res);
                    continue;
                }
                
                // Parse JSON to detect if single or bulk
                Object parsed = JSON.deserializeUntyped(req.fieldDataJson);
                Boolean isBulk = parsed instanceof List<Object>;
                
                // Build request for AFUniversalCrmRecordAction
                AFUniversalCrmRecordAction.Request actionReq = new AFUniversalCrmRecordAction.Request();
                actionReq.objectApiName = 'Account';
                actionReq.accountName = req.accountName;
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
                    res.ambiguousRelationship = actionRes.ambiguousRelationship != null ? actionRes.ambiguousRelationship : false;
                    res.ambiguousRelationshipType = actionRes.ambiguousRelationshipType;
                    res.relationshipCandidatesJson = actionRes.relationshipCandidatesJson;
                    
                    if (actionRes.record != null) {
                        res.record = (Account) actionRes.record;
                        // ALWAYS extract ID directly from the record object
                        res.recordId = res.record.Id;
                        res.records = new List<Account>{ res.record };
                        System.debug(LoggingLevel.INFO, 'AFAccountCreateAction: Set recordId from record object: ' + res.recordId);
                    } else if (actionRes.records != null && !actionRes.records.isEmpty()) {
                        res.records = new List<Account>();
                        for (SObject so : actionRes.records) {
                            res.records.add((Account) so);
                        }
                        if (!res.records.isEmpty()) {
                            res.record = res.records[0];
                            // ALWAYS extract ID directly from first record
                            res.recordId = res.records[0].Id;
                            System.debug(LoggingLevel.INFO, 'AFAccountCreateAction: Set recordId from records array: ' + res.recordId);
                        }
                    } else if (actionRes.recordId != null) {
                        // Fallback: use recordId from response if record object not available
                        res.recordId = actionRes.recordId;
                        System.debug(LoggingLevel.INFO, 'AFAccountCreateAction: Set recordId from actionRes.recordId: ' + res.recordId);
                    } else {
                        System.debug(LoggingLevel.WARN, 'AFAccountCreateAction: No recordId found in response! record=' + actionRes.record + ', records=' + actionRes.records + ', recordId=' + actionRes.recordId);
                    }
                } else {
                    res.success = false;
                    res.errorMessage = actionRes.message != null ? actionRes.message : 'Failed to create Account.';
                }
                
            } catch (Exception e) {
                res.success = false;
                res.errorMessage = 'Error creating Account: ' + e.getMessage();
                System.debug(LoggingLevel.ERROR, 'AFAccountCreateAction: Exception - ' + e.getMessage());
            }
            
            responses.add(res);
        }
        
        return responses;
    }
}

