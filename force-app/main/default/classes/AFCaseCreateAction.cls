/**
 * AF Case Create Action
 * Invocable action for creating Case records (single or bulk)
 * Designed for Agentforce AI agents
 */
public with sharing class AFCaseCreateAction {
    
    /**
     * Request input for create operation
     */
    public class Request {
        @InvocableVariable(
            label='Field Data JSON'
            description='JSON string containing Case field data. For single record: {"Subject":"Support Request","Status":"New"}. For bulk (multiple records): [{"Subject":"Request 1"},{"Subject":"Request 2"}]. Required fields: Subject. Optional fields: Status, Priority, Description, Origin. The agent should pass all field data as a JSON string.'
            required=true
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
            description='Optional: Set to false to preview only without creating. Default (true): Creates the record immediately. When user says "create case", omit this field or set to true to create immediately. Only set to false if user explicitly asks to preview first.'
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
            description='The Case record that was created (for single create operation). Use the record.Id field from this record for follow-up operations like updateCase or deleteCase. This is null for bulk operations.'
        )
        public Case record;
        
        @InvocableVariable(
            label='Records'
            description='List of Case records created (for bulk create operation). Use record.Id from each record for subsequent operations. For single create, this will contain one record.'
        )
        public List<Case> records;
        
        @InvocableVariable(
            label='Record ID'
            description='The Salesforce ID of the created record (18-character format like "500xx000003DGbYAAW"). Use this ID for updateCase, deleteCase, or readCase operations. This is the primary identifier for follow-up operations in the conversation.'
        )
        public Id recordId;
        
        @InvocableVariable(
            label='Message'
            description='Human-readable message describing the operation result. Use this exact message to inform the user. Examples: "Case created successfully with ID 500xx000003DGbYAAW", "Successfully created 3 Case records".'
        )
        public String message;
        
        @InvocableVariable(
            label='Error Message'
            description='If success is false, this contains a user-friendly error message to relay directly to the user. Example: "To create a Case, the Subject field is required." Do not use technical error details.'
        )
        public String errorMessage;
        
        @InvocableVariable(
            label='Object Type'
            description='The Salesforce object type, always "Case" for Case create operations. Useful for agent context and logging.'
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
            description='List of commonly-used field API names that could be populated to enrich this Case. Examples: Status, Priority, Type, Origin. The agent should ask the user about these fields and add them to fieldDataJson before calling again with confirm=true.'
        )
        public List<String> suggestedFields;
        
        @InvocableVariable(
            label='Preview Data'
            description='A JSON string representation of what would be created. Use this to show the user a preview before committing.'
        )
        public String previewData;
        
        @InvocableVariable(
            label='Available Fields JSON'
            description='JSON string containing metadata for all available fields that can be set on Case records. Includes API name, label, type, required status, picklist values, help text, and more.'
        )
        public String availableFieldsJson;
        
        @InvocableVariable(
            label='Ambiguous Relationship'
            description='True if a related record lookup (Account or Contact) found multiple matches (2+). When true, DO NOT tell the user the Case was created. Instead, you MUST present the candidates from relationshipCandidatesJson to the user and ask which one they meant. Say something like: "I found multiple matches for [Account/Contact name]. Which one did you mean?" Then list the candidates with distinguishing details.'
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
     * Create Case(s) - supports both single and bulk creation
     */
    @InvocableMethod(
        label='Create Case'
        description='Creates a new Case record immediately. Required field: Subject. Pass JSON object: {"Subject":"Support Request","Priority":"High"}. Default behavior creates the record right away. Optional: Set confirm=false only if user explicitly asks to preview first. Supports accountName and contactNameOrEmail parameters to link Case to Account and Contact. Supports bulk creation with JSON array.'
        category='CRM Actions'
    )
    public static List<Response> createCase(List<Request> requests) {
        List<Response> responses = new List<Response>();
        
        for (Request req : requests) {
            Response res = new Response();
            res.objectType = 'Case';
            res.success = false;
            res.records = new List<Case>();
            
            try {
                if (String.isBlank(req.fieldDataJson)) {
                    res.success = false;
                    res.errorMessage = 'Field Data JSON is required. Provide Case data as JSON string, e.g., {"Subject":"Support Request"}.';
                    responses.add(res);
                    continue;
                }
                
                // Parse JSON to detect if single or bulk
                Object parsed = JSON.deserializeUntyped(req.fieldDataJson);
                Boolean isBulk = parsed instanceof List<Object>;
                
                // Build request for AFUniversalCrmRecordAction
                AFUniversalCrmRecordAction.Request actionReq = new AFUniversalCrmRecordAction.Request();
                actionReq.objectApiName = 'Case';
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
                    res.ambiguousRelationship = actionRes.ambiguousRelationship != null ? actionRes.ambiguousRelationship : false;
                    res.ambiguousRelationshipType = actionRes.ambiguousRelationshipType;
                    res.relationshipCandidatesJson = actionRes.relationshipCandidatesJson;
                    
                    if (actionRes.record != null) {
                        res.record = (Case) actionRes.record;
                        // ALWAYS extract ID directly from the record object
                        res.recordId = res.record.Id;
                        res.records = new List<Case>{ res.record };
                        System.debug(LoggingLevel.INFO, 'AFCaseCreateAction: Set recordId from record object: ' + res.recordId);
                    } else if (actionRes.records != null && !actionRes.records.isEmpty()) {
                        res.records = new List<Case>();
                        for (SObject so : actionRes.records) {
                            res.records.add((Case) so);
                        }
                        if (!res.records.isEmpty()) {
                            res.record = res.records[0];
                            // ALWAYS extract ID directly from first record
                            res.recordId = res.records[0].Id;
                            System.debug(LoggingLevel.INFO, 'AFCaseCreateAction: Set recordId from records array: ' + res.recordId);
                        }
                    } else if (actionRes.recordId != null) {
                        // Fallback: use recordId from response if record object not available
                        res.recordId = actionRes.recordId;
                        System.debug(LoggingLevel.INFO, 'AFCaseCreateAction: Set recordId from actionRes.recordId: ' + res.recordId);
                    } else {
                        System.debug(LoggingLevel.WARN, 'AFCaseCreateAction: No recordId found in response! record=' + actionRes.record + ', records=' + actionRes.records + ', recordId=' + actionRes.recordId);
                    }
                } else {
                    res.success = false;
                    res.errorMessage = actionRes.message != null ? actionRes.message : 'Failed to create Case.';
                }
                
            } catch (Exception e) {
                res.success = false;
                res.errorMessage = 'Error creating Case: ' + e.getMessage();
                System.debug(LoggingLevel.ERROR, 'AFCaseCreateAction: Exception - ' + e.getMessage());
            }
            
            responses.add(res);
        }
        
        return responses;
    }
}

