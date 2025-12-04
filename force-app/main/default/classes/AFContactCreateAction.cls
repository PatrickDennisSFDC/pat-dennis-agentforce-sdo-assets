/**
 * AF Contact Create Action
 * Invocable action for creating Contact records (single or bulk)
 * Designed for Agentforce AI agents
 */
public with sharing class AFContactCreateAction {
    
    /**
     * Request input for create operation
     */
    public class Request {
        @InvocableVariable(
            label='Field Data JSON'
            description='JSON string containing Contact field data. For single record: {"LastName":"Smith","Email":"john@example.com"}. For bulk (multiple records): [{"LastName":"Smith"},{"LastName":"Jones"}]. Required fields: LastName. Optional fields: FirstName, Email, Phone, AccountId. The agent should pass all field data as a JSON string.'
            required=true
        )
        public String fieldDataJson;
        
        @InvocableVariable(
            label='Account Name'
            description='Account name to resolve to AccountId for the Contact. If provided, the system will search for an Account with this name and link the Contact to it. Example: "Acme Corp".'
            required=false
        )
        public String accountName;
        
        @InvocableVariable(
            label='Confirm'
            description='Optional: Set to false to preview only without creating. Default (true): Creates the record immediately. When user says "create contact", omit this field or set to true to create immediately. Only set to false if user explicitly asks to preview first.'
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
            description='The Contact record that was created (for single create operation). Use the record.Id field from this record for follow-up operations like updateContact or deleteContact. This is null for bulk operations.'
        )
        public Contact record;
        
        @InvocableVariable(
            label='Records'
            description='List of Contact records created (for bulk create operation). Use record.Id from each record for subsequent operations. For single create, this will contain one record.'
        )
        public List<Contact> records;
        
        @InvocableVariable(
            label='Record ID'
            description='The Salesforce ID of the created record (18-character format like "003xx000003DGbYAAW"). Use this ID for updateContact, deleteContact, or readContact operations. This is the primary identifier for follow-up operations in the conversation.'
        )
        public Id recordId;
        
        @InvocableVariable(
            label='Message'
            description='Human-readable message describing the operation result. Use this exact message to inform the user. Examples: "Contact created successfully with ID 003xx000003DGbYAAW", "Successfully created 3 Contact records".'
        )
        public String message;
        
        @InvocableVariable(
            label='Error Message'
            description='If success is false, this contains a user-friendly error message to relay directly to the user. Example: "To create a Contact, the LastName field is required." Do not use technical error details.'
        )
        public String errorMessage;
        
        @InvocableVariable(
            label='Object Type'
            description='The Salesforce object type, always "Contact" for Contact create operations. Useful for agent context and logging.'
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
            description='List of commonly-used field API names that could be populated to enrich this Contact. Examples: FirstName, Email, Phone, Title. The agent should ask the user about these fields and add them to fieldDataJson before calling again with confirm=true.'
        )
        public List<String> suggestedFields;
        
        @InvocableVariable(
            label='Preview Data'
            description='A JSON string representation of what would be created. Use this to show the user a preview before committing.'
        )
        public String previewData;
        
        @InvocableVariable(
            label='Available Fields JSON'
            description='JSON string containing metadata for all available fields that can be set on Contact records. Includes API name, label, type, required status, picklist values, help text, and more.'
        )
        public String availableFieldsJson;
        
        @InvocableVariable(
            label='Ambiguous Relationship'
            description='True if a related Account lookup found multiple matches (2+). When true, DO NOT tell the user the Contact was created. Instead, you MUST present the candidates from relationshipCandidatesJson to the user and ask which Account they meant. Say something like: "I found multiple accounts with that name. Which one did you mean?" Then list the candidates with distinguishing details.'
        )
        public Boolean ambiguousRelationship;
        
        @InvocableVariable(
            label='Ambiguous Relationship Type'
            description='The type of relationship that has multiple matches, typically "Account" for Contact creation. Use this to know what kind of candidates are provided in relationshipCandidatesJson.'
        )
        public String ambiguousRelationshipType;
        
        @InvocableVariable(
            label='Relationship Candidates JSON'
            description='JSON array of candidate Account records when ambiguousRelationship is true. Each candidate includes disambiguating details: Name, BillingCity, BillingState, Phone, Industry. Present these options to the user in a clear, numbered list with the distinguishing details, then ask them to clarify which one they meant. Example: "I found 3 accounts named Acme: 1) Acme Corp (San Francisco, CA, Technology), 2) Acme Inc (New York, NY, Manufacturing), 3) Acme LLC (Austin, TX, Retail). Which one?"'
        )
        public String relationshipCandidatesJson;
    }
    
    /**
     * Create Contact(s) - supports both single and bulk creation
     */
    @InvocableMethod(
        label='Create Contact'
        description='Creates a new Contact record immediately. Required field: LastName. Pass JSON object: {"LastName":"Smith","Email":"john@example.com"}. Default behavior creates the record right away. Optional: Set confirm=false only if user explicitly asks to preview first. Supports accountName parameter to link Contact to Account. Supports bulk creation with JSON array.'
        category='CRM Actions'
    )
    public static List<Response> createContact(List<Request> requests) {
        List<Response> responses = new List<Response>();
        
        for (Request req : requests) {
            Response res = new Response();
            res.objectType = 'Contact';
            res.success = false;
            res.records = new List<Contact>();
            
            try {
                if (String.isBlank(req.fieldDataJson)) {
                    res.success = false;
                    res.errorMessage = 'Field Data JSON is required. Provide Contact data as JSON string, e.g., {"LastName":"Smith","Email":"john@example.com"}.';
                    responses.add(res);
                    continue;
                }
                
                // Parse JSON to detect if single or bulk
                Object parsed = JSON.deserializeUntyped(req.fieldDataJson);
                Boolean isBulk = parsed instanceof List<Object>;
                
                // Build request for AFUniversalCrmRecordAction
                AFUniversalCrmRecordAction.Request actionReq = new AFUniversalCrmRecordAction.Request();
                actionReq.objectApiName = 'Contact';
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
                        res.record = (Contact) actionRes.record;
                        // ALWAYS extract ID directly from the record object
                        res.recordId = res.record.Id;
                        res.records = new List<Contact>{ res.record };
                        System.debug(LoggingLevel.INFO, 'AFContactCreateAction: Set recordId from record object: ' + res.recordId);
                    } else if (actionRes.records != null && !actionRes.records.isEmpty()) {
                        res.records = new List<Contact>();
                        for (SObject so : actionRes.records) {
                            res.records.add((Contact) so);
                        }
                        if (!res.records.isEmpty()) {
                            res.record = res.records[0];
                            // ALWAYS extract ID directly from first record
                            res.recordId = res.records[0].Id;
                            System.debug(LoggingLevel.INFO, 'AFContactCreateAction: Set recordId from records array: ' + res.recordId);
                        }
                    } else if (actionRes.recordId != null) {
                        // Fallback: use recordId from response if record object not available
                        res.recordId = actionRes.recordId;
                        System.debug(LoggingLevel.INFO, 'AFContactCreateAction: Set recordId from actionRes.recordId: ' + res.recordId);
                    } else {
                        System.debug(LoggingLevel.WARN, 'AFContactCreateAction: No recordId found in response! record=' + actionRes.record + ', records=' + actionRes.records + ', recordId=' + actionRes.recordId);
                    }
                } else {
                    res.success = false;
                    res.errorMessage = actionRes.message != null ? actionRes.message : 'Failed to create Contact.';
                }
                
            } catch (Exception e) {
                res.success = false;
                res.errorMessage = 'Error creating Contact: ' + e.getMessage();
                System.debug(LoggingLevel.ERROR, 'AFContactCreateAction: Exception - ' + e.getMessage());
            }
            
            responses.add(res);
        }
        
        return responses;
    }
}

