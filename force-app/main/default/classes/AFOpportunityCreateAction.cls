/**
 * AF Opportunity Create Action
 * Invocable action for creating Opportunity records (single or bulk)
 * Designed for Agentforce AI agents
 */
public with sharing class AFOpportunityCreateAction {
    
    /**
     * Request input for create operation
     */
    public class Request {
        @InvocableVariable(
            label='Field Data JSON'
            description='JSON string containing Opportunity field data. For single record: {"Name":"New Deal","StageName":"Prospecting","CloseDate":"2024-12-31","Amount":50000}. For bulk (multiple records): [{"Name":"Deal 1"},{"Name":"Deal 2"}]. Required fields: Name, StageName, CloseDate. Optional fields: Amount, Description, Type. The agent should pass all field data as a JSON string.'
            required=true
        )
        public String fieldDataJson;
        
        @InvocableVariable(
            label='Account Name'
            description='Account name to resolve to AccountId for the Opportunity. If provided, the system will search for an Account with this name and link the Opportunity to it. Example: "Acme Corp".'
            required=false
        )
        public String accountName;
        
        @InvocableVariable(
            label='Confirm'
            description='Optional: Set to false to preview only without creating. Default (true): Creates the record immediately. When user says "create opportunity", omit this field or set to true to create immediately. Only set to false if user explicitly asks to preview first.'
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
            description='The Opportunity record that was created (for single create operation). Use the record.Id field from this record for follow-up operations like updateOpportunity or deleteOpportunity. This is null for bulk operations.'
        )
        public Opportunity record;
        
        @InvocableVariable(
            label='Records'
            description='List of Opportunity records created (for bulk create operation). Use record.Id from each record for subsequent operations. For single create, this will contain one record.'
        )
        public List<Opportunity> records;
        
        @InvocableVariable(
            label='Record ID'
            description='The Salesforce ID of the created record (18-character format like "006xx000003DGbYAAW"). Use this ID for updateOpportunity, deleteOpportunity, or readOpportunity operations. This is the primary identifier for follow-up operations in the conversation.'
        )
        public Id recordId;
        
        @InvocableVariable(
            label='Message'
            description='Human-readable message describing the operation result. Use this exact message to inform the user. Examples: "Opportunity created successfully with ID 006xx000003DGbYAAW", "Successfully created 3 Opportunity records".'
        )
        public String message;
        
        @InvocableVariable(
            label='Error Message'
            description='If success is false, this contains a user-friendly error message to relay directly to the user. Example: "To create an Opportunity, the Name field is required." Do not use technical error details.'
        )
        public String errorMessage;
        
        @InvocableVariable(
            label='Object Type'
            description='The Salesforce object type, always "Opportunity" for Opportunity create operations. Useful for agent context and logging.'
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
            description='List of commonly-used field API names that could be populated to enrich this Opportunity. Examples: Amount, Description, Type, LeadSource. The agent should ask the user about these fields and add them to fieldDataJson before calling again with confirm=true.'
        )
        public List<String> suggestedFields;
        
        @InvocableVariable(
            label='Preview Data'
            description='A JSON string representation of what would be created. Use this to show the user a preview before committing.'
        )
        public String previewData;
        
        @InvocableVariable(
            label='Available Fields JSON'
            description='JSON string containing metadata for all available fields that can be set on Opportunity records. Includes API name, label, type, required status, picklist values, help text, and more.'
        )
        public String availableFieldsJson;
        
        @InvocableVariable(
            label='Ambiguous Relationship'
            description='True if a related Account lookup found multiple matches (2+). When true, DO NOT tell the user the Opportunity was created. Instead, you MUST present the candidates from relationshipCandidatesJson to the user and ask which Account they meant. Say something like: "I found multiple accounts with that name. Which one did you mean?" Then list the candidates with distinguishing details.'
        )
        public Boolean ambiguousRelationship;
        
        @InvocableVariable(
            label='Ambiguous Relationship Type'
            description='The type of relationship that has multiple matches, typically "Account" for Opportunity creation. Use this to know what kind of candidates are provided in relationshipCandidatesJson.'
        )
        public String ambiguousRelationshipType;
        
        @InvocableVariable(
            label='Relationship Candidates JSON'
            description='JSON array of candidate Account records when ambiguousRelationship is true. Each candidate includes disambiguating details: Name, BillingCity, BillingState, Phone, Industry. Present these options to the user in a clear, numbered list with the distinguishing details, then ask them to clarify which one they meant. Example: "I found 3 accounts named Acme: 1) Acme Corp (San Francisco, CA, Technology), 2) Acme Inc (New York, NY, Manufacturing), 3) Acme LLC (Austin, TX, Retail). Which one?"'
        )
        public String relationshipCandidatesJson;
    }
    
    /**
     * Create Opportunity(s) - supports both single and bulk creation
     */
    @InvocableMethod(
        label='Create Opportunity'
        description='Creates a new Opportunity record immediately. Required fields: Name, StageName, CloseDate. Pass JSON object: {"Name":"New Deal","StageName":"Prospecting","CloseDate":"2024-12-31"}. Default behavior creates the record right away. Optional: Set confirm=false only if user explicitly asks to preview first. Supports accountName parameter to link to Account. Supports bulk creation with JSON array.'
        category='CRM Actions'
    )
    public static List<Response> createOpportunity(List<Request> requests) {
        List<Response> responses = new List<Response>();
        
        for (Request req : requests) {
            Response res = new Response();
            res.objectType = 'Opportunity';
            res.success = false;
            res.records = new List<Opportunity>();
            
            try {
                if (String.isBlank(req.fieldDataJson)) {
                    res.success = false;
                    res.errorMessage = 'Field Data JSON is required. Provide Opportunity data as JSON string, e.g., {"Name":"New Deal","StageName":"Prospecting","CloseDate":"2024-12-31"}.';
                    responses.add(res);
                    continue;
                }
                
                // Parse JSON to detect if single or bulk
                Object parsed = JSON.deserializeUntyped(req.fieldDataJson);
                Boolean isBulk = parsed instanceof List<Object>;
                
                // Build request for AFUniversalCrmRecordAction
                AFUniversalCrmRecordAction.Request actionReq = new AFUniversalCrmRecordAction.Request();
                actionReq.objectApiName = 'Opportunity';
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
                        res.record = (Opportunity) actionRes.record;
                        // ALWAYS extract ID directly from the record object
                        res.recordId = res.record.Id;
                        res.records = new List<Opportunity>{ res.record };
                        System.debug(LoggingLevel.INFO, 'AFOpportunityCreateAction: Set recordId from record object: ' + res.recordId);
                    } else if (actionRes.records != null && !actionRes.records.isEmpty()) {
                        res.records = new List<Opportunity>();
                        for (SObject so : actionRes.records) {
                            res.records.add((Opportunity) so);
                        }
                        if (!res.records.isEmpty()) {
                            res.record = res.records[0];
                            // ALWAYS extract ID directly from first record
                            res.recordId = res.records[0].Id;
                            System.debug(LoggingLevel.INFO, 'AFOpportunityCreateAction: Set recordId from records array: ' + res.recordId);
                        }
                    } else if (actionRes.recordId != null) {
                        // Fallback: use recordId from response if record object not available
                        res.recordId = actionRes.recordId;
                        System.debug(LoggingLevel.INFO, 'AFOpportunityCreateAction: Set recordId from actionRes.recordId: ' + res.recordId);
                    } else {
                        System.debug(LoggingLevel.WARN, 'AFOpportunityCreateAction: No recordId found in response! record=' + actionRes.record + ', records=' + actionRes.records + ', recordId=' + actionRes.recordId);
                    }
                } else {
                    res.success = false;
                    res.errorMessage = actionRes.message != null ? actionRes.message : 'Failed to create Opportunity.';
                }
                
            } catch (Exception e) {
                res.success = false;
                res.errorMessage = 'Error creating Opportunity: ' + e.getMessage();
                System.debug(LoggingLevel.ERROR, 'AFOpportunityCreateAction: Exception - ' + e.getMessage());
            }
            
            responses.add(res);
        }
        
        return responses;
    }
}

