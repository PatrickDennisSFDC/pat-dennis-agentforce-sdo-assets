/**
 * AF Case Controller
 * Agentforce-specific controller for Case CRUD operations
 * Uses @AuraEnabled methods for native Agentforce integration
 * 
 * All methods reuse the existing UniversalCrmRecordAction business logic
 */
public with sharing class AFCaseController {
    
    /**
     * List cases with optional search and filters
     * @param search Search term to find in case fields (Subject, Description, CaseNumber, etc.)
     * @param status Filter by Status field
     * @param priority Filter by Priority field
     * @param accountId Filter by Account ID
     * @param recordLimit Maximum number of records to return (default: 5, max: 20)
     * @return List of Case records
     */
    @AuraEnabled
    public static List<Case> listCases(
        String search,
        String status,
        String priority,
        String accountId,
        Integer recordLimit
    ) {
        try {
            UniversalCrmRecordAction.Request req = new UniversalCrmRecordAction.Request();
            req.objectApiName = 'Case';
            req.operation = 'find';
            req.searchTerm = search;
            req.searchLimit = normalizeLimit(recordLimit);
            
            // Build filters from parameters
            List<UniversalCrmRecordAction.Filter> filters = new List<UniversalCrmRecordAction.Filter>();
            if (String.isNotBlank(status)) {
                filters.add(createFilter('Status', status));
            }
            if (String.isNotBlank(priority)) {
                filters.add(createFilter('Priority', priority));
            }
            if (String.isNotBlank(accountId)) {
                filters.add(createFilter('AccountId', accountId));
            }
            
            if (!filters.isEmpty()) {
                req.filtersJson = JSON.serialize(filters);
            }
            
            UniversalCrmRecordAction.Response res = UniversalCrmRecordAction.processRequest(req);
            
            if (res.success && res.records != null) {
                return res.records;
            } else {
                throw new AuraHandledException(res.message != null ? res.message : 'Failed to retrieve cases');
            }
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException('Error listing cases: ' + e.getMessage());
        }
    }
    
    /**
     * Get case by ID
     * @param caseId Salesforce Case ID (15 or 18 character)
     * @return Case record
     */
    @AuraEnabled
    public static Case getCaseById(String caseId) {
        try {
            if (String.isBlank(caseId)) {
                throw new AuraHandledException('Case ID is required');
            }
            
            UniversalCrmRecordAction.Request req = new UniversalCrmRecordAction.Request();
            req.objectApiName = 'Case';
            req.operation = 'read';
            req.recordId = caseId;
            
            UniversalCrmRecordAction.Response res = UniversalCrmRecordAction.processRequest(req);
            
            if (res.success && res.record != null) {
                return (Case) res.record;
            } else {
                throw new AuraHandledException(res.message != null ? res.message : 'Case not found');
            }
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving case: ' + e.getMessage());
        }
    }
    
    /**
     * Create case(s)
     * @param caseData JSON string of case data. Can be single object {"Subject":"Support Request"} or array for bulk.
     *                 Supports 'accountName' and 'contactNameOrEmail' fields to resolve related records by name.
     * @return Created Case record(s) - single Case or List<Case>
     */
    @AuraEnabled
    public static Object createCase(String caseData) {
        try {
            if (String.isBlank(caseData)) {
                throw new AuraHandledException('Case data is required');
            }
            
            Object parsed = JSON.deserializeUntyped(caseData);
            UniversalCrmRecordAction.Request req = new UniversalCrmRecordAction.Request();
            req.objectApiName = 'Case';
            
            if (parsed instanceof List<Object>) {
                req.operation = 'bulkCreate';
                req.bulkRecordsJson = caseData;
            } else {
                req.operation = 'create';
                Map<String, Object> data = (Map<String, Object>) parsed;
                
                // Extract special fields if present
                if (data.containsKey('accountName')) {
                    req.accountName = String.valueOf(data.get('accountName'));
                    data.remove('accountName');
                }
                if (data.containsKey('contactNameOrEmail')) {
                    req.contactNameOrEmail = String.valueOf(data.get('contactNameOrEmail'));
                    data.remove('contactNameOrEmail');
                }
                
                List<Map<String, String>> fieldDataList = new List<Map<String, String>>();
                for (String key : data.keySet()) {
                    fieldDataList.add(new Map<String, String>{
                        'fieldApiName' => key,
                        'value' => String.valueOf(data.get(key))
                    });
                }
                req.fieldDataJson = JSON.serialize(fieldDataList);
            }
            
            UniversalCrmRecordAction.Response res = UniversalCrmRecordAction.processRequest(req);
            
            if (res.success) {
                if (res.record != null) {
                    return res.record;
                } else if (res.records != null && !res.records.isEmpty()) {
                    return res.records;
                } else if (res.recordId != null) {
                    return new Map<String, Object>{ 'id' => res.recordId };
                }
            }
            throw new AuraHandledException(res.message != null ? res.message : 'Failed to create case');
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException('Error creating case: ' + e.getMessage());
        }
    }
    
    /**
     * Update case
     * @param caseId Salesforce Case ID (15 or 18 character)
     * @param caseData JSON string of fields to update. Example: {"Status":"Closed","Priority":"High"}
     *                 Supports 'accountName' and 'contactNameOrEmail' fields to resolve related records by name.
     * @return Updated Case record
     */
    @AuraEnabled
    public static Case updateCase(String caseId, String caseData) {
        try {
            if (String.isBlank(caseId)) {
                throw new AuraHandledException('Case ID is required');
            }
            
            UniversalCrmRecordAction.Request req = new UniversalCrmRecordAction.Request();
            req.objectApiName = 'Case';
            req.operation = 'update';
            req.recordId = caseId;
            
            if (String.isNotBlank(caseData)) {
                Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(caseData);
                
                // Extract special fields if present
                if (data.containsKey('accountName')) {
                    req.accountName = String.valueOf(data.get('accountName'));
                    data.remove('accountName');
                }
                if (data.containsKey('contactNameOrEmail')) {
                    req.contactNameOrEmail = String.valueOf(data.get('contactNameOrEmail'));
                    data.remove('contactNameOrEmail');
                }
                
                List<Map<String, String>> fieldDataList = new List<Map<String, String>>();
                for (String key : data.keySet()) {
                    fieldDataList.add(new Map<String, String>{
                        'fieldApiName' => key,
                        'value' => String.valueOf(data.get(key))
                    });
                }
                req.fieldDataJson = JSON.serialize(fieldDataList);
            }
            // If no caseData provided, handleUpdate will return current record
            
            UniversalCrmRecordAction.Response res = UniversalCrmRecordAction.processRequest(req);
            
            if (res.success && res.record != null) {
                return (Case) res.record;
            } else {
                throw new AuraHandledException(res.message != null ? res.message : 'Failed to update case');
            }
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException('Error updating case: ' + e.getMessage());
        }
    }
    
    /**
     * Delete case
     * @param caseId Salesforce Case ID (15 or 18 character)
     * @return Success message
     */
    @AuraEnabled
    public static String deleteCase(String caseId) {
        try {
            if (String.isBlank(caseId)) {
                throw new AuraHandledException('Case ID is required');
            }
            
            UniversalCrmRecordAction.Request req = new UniversalCrmRecordAction.Request();
            req.objectApiName = 'Case';
            req.operation = 'delete';
            req.recordId = caseId;
            
            UniversalCrmRecordAction.Response res = UniversalCrmRecordAction.processRequest(req);
            
            if (res.success) {
                return 'Case deleted successfully';
            } else {
                throw new AuraHandledException(res.message != null ? res.message : 'Failed to delete case');
            }
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException('Error deleting case: ' + e.getMessage());
        }
    }
    
    /**
     * Helper method to create a filter
     */
    private static UniversalCrmRecordAction.Filter createFilter(String fieldApiName, String value) {
        UniversalCrmRecordAction.Filter filter = new UniversalCrmRecordAction.Filter();
        filter.fieldApiName = fieldApiName;
        filter.value = value;
        return filter;
    }
    
    /**
     * Normalize limit parameter (default: 5, max: 20)
     */
    private static Integer normalizeLimit(Integer recordLimit) {
        if (recordLimit == null || recordLimit < 1) {
            return 5;
        }
        return Math.min(recordLimit, 20);
    }
}

