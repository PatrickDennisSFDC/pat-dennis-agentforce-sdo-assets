/**
 * AF Contact Controller
 * Agentforce-specific controller for Contact CRUD operations
 * Uses @AuraEnabled methods for native Agentforce integration
 * 
 * All methods reuse the existing UniversalCrmRecordAction business logic
 */
public with sharing class AFContactController {
    
    /**
     * List contacts with optional search and filters
     * @param search Search term to find in contact fields (FirstName, LastName, Email, etc.)
     * @param email Filter by Email field
     * @param accountId Filter by Account ID
     * @param recordLimit Maximum number of records to return (default: 5, max: 20)
     * @return List of Contact records
     */
    @AuraEnabled
    public static List<Contact> listContacts(
        String search,
        String email,
        String accountId,
        Integer recordLimit
    ) {
        try {
            UniversalCrmRecordAction.Request req = new UniversalCrmRecordAction.Request();
            req.objectApiName = 'Contact';
            req.operation = 'find';
            req.searchTerm = search;
            req.searchLimit = normalizeLimit(recordLimit);
            
            // Build filters from parameters
            List<UniversalCrmRecordAction.Filter> filters = new List<UniversalCrmRecordAction.Filter>();
            if (String.isNotBlank(email)) {
                filters.add(createFilter('Email', email));
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
                throw new AuraHandledException(res.message != null ? res.message : 'Failed to retrieve contacts');
            }
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException('Error listing contacts: ' + e.getMessage());
        }
    }
    
    /**
     * Get contact by ID
     * @param contactId Salesforce Contact ID (15 or 18 character)
     * @return Contact record
     */
    @AuraEnabled
    public static Contact getContactById(String contactId) {
        try {
            if (String.isBlank(contactId)) {
                throw new AuraHandledException('Contact ID is required');
            }
            
            UniversalCrmRecordAction.Request req = new UniversalCrmRecordAction.Request();
            req.objectApiName = 'Contact';
            req.operation = 'read';
            req.recordId = contactId;
            
            UniversalCrmRecordAction.Response res = UniversalCrmRecordAction.processRequest(req);
            
            if (res.success && res.record != null) {
                return (Contact) res.record;
            } else {
                throw new AuraHandledException(res.message != null ? res.message : 'Contact not found');
            }
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving contact: ' + e.getMessage());
        }
    }
    
    /**
     * Create contact(s)
     * @param contactData JSON string of contact data. Can be single object {"LastName":"Smith","Email":"john@example.com"} or array for bulk.
     *                    Supports 'accountName' field to resolve Account by name.
     * @return Created Contact record(s) - single Contact or List<Contact>
     */
    @AuraEnabled
    public static Object createContact(String contactData) {
        try {
            if (String.isBlank(contactData)) {
                throw new AuraHandledException('Contact data is required');
            }
            
            Object parsed = JSON.deserializeUntyped(contactData);
            UniversalCrmRecordAction.Request req = new UniversalCrmRecordAction.Request();
            req.objectApiName = 'Contact';
            
            if (parsed instanceof List<Object>) {
                req.operation = 'bulkCreate';
                req.bulkRecordsJson = contactData;
            } else {
                req.operation = 'create';
                Map<String, Object> data = (Map<String, Object>) parsed;
                
                // Extract accountName if present (special handling)
                if (data.containsKey('accountName')) {
                    req.accountName = String.valueOf(data.get('accountName'));
                    data.remove('accountName');
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
            throw new AuraHandledException(res.message != null ? res.message : 'Failed to create contact');
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException('Error creating contact: ' + e.getMessage());
        }
    }
    
    /**
     * Update contact
     * @param contactId Salesforce Contact ID (15 or 18 character)
     * @param contactData JSON string of fields to update. Example: {"Email":"newemail@example.com","Phone":"555-1234"}
     *                    Supports 'accountName' field to resolve Account by name.
     * @return Updated Contact record
     */
    @AuraEnabled
    public static Contact updateContact(String contactId, String contactData) {
        try {
            if (String.isBlank(contactId)) {
                throw new AuraHandledException('Contact ID is required');
            }
            
            UniversalCrmRecordAction.Request req = new UniversalCrmRecordAction.Request();
            req.objectApiName = 'Contact';
            req.operation = 'update';
            req.recordId = contactId;
            
            if (String.isNotBlank(contactData)) {
                Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(contactData);
                
                // Extract accountName if present (special handling)
                if (data.containsKey('accountName')) {
                    req.accountName = String.valueOf(data.get('accountName'));
                    data.remove('accountName');
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
            // If no contactData provided, handleUpdate will return current record
            
            UniversalCrmRecordAction.Response res = UniversalCrmRecordAction.processRequest(req);
            
            if (res.success && res.record != null) {
                return (Contact) res.record;
            } else {
                throw new AuraHandledException(res.message != null ? res.message : 'Failed to update contact');
            }
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException('Error updating contact: ' + e.getMessage());
        }
    }
    
    /**
     * Delete contact
     * @param contactId Salesforce Contact ID (15 or 18 character)
     * @return Success message
     */
    @AuraEnabled
    public static String deleteContact(String contactId) {
        try {
            if (String.isBlank(contactId)) {
                throw new AuraHandledException('Contact ID is required');
            }
            
            UniversalCrmRecordAction.Request req = new UniversalCrmRecordAction.Request();
            req.objectApiName = 'Contact';
            req.operation = 'delete';
            req.recordId = contactId;
            
            UniversalCrmRecordAction.Response res = UniversalCrmRecordAction.processRequest(req);
            
            if (res.success) {
                return 'Contact deleted successfully';
            } else {
                throw new AuraHandledException(res.message != null ? res.message : 'Failed to delete contact');
            }
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException('Error deleting contact: ' + e.getMessage());
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

