/**
 * AF Account Controller
 * Agentforce-specific controller for Account CRUD operations
 * Uses @AuraEnabled methods for native Agentforce integration
 * 
 * All methods reuse the existing UniversalCrmRecordAction business logic
 */
public with sharing class AFAccountController {
    
    /**
     * List accounts with optional search and filters
     * @param search Search term to find in account fields (Name, BillingCity, etc.)
     * @param industry Filter by Industry field
     * @param billingCity Filter by Billing City
     * @param billingState Filter by Billing State
     * @param phone Filter by Phone
     * @param recordLimit Maximum number of records to return (default: 5, max: 20)
     * @return List of Account records
     */
    @AuraEnabled
    public static List<Account> listAccounts(
        String search,
        String industry,
        String billingCity,
        String billingState,
        String phone,
        Integer recordLimit
    ) {
        try {
            UniversalCrmRecordAction.Request req = new UniversalCrmRecordAction.Request();
            req.objectApiName = 'Account';
            req.operation = 'find';
            req.searchTerm = search;
            req.searchLimit = normalizeLimit(recordLimit);
            
            // Build filters from parameters
            List<UniversalCrmRecordAction.Filter> filters = new List<UniversalCrmRecordAction.Filter>();
            if (String.isNotBlank(industry)) {
                filters.add(createFilter('Industry', industry));
            }
            if (String.isNotBlank(billingCity)) {
                filters.add(createFilter('BillingCity', billingCity));
            }
            if (String.isNotBlank(billingState)) {
                filters.add(createFilter('BillingState', billingState));
            }
            if (String.isNotBlank(phone)) {
                filters.add(createFilter('Phone', phone));
            }
            
            if (!filters.isEmpty()) {
                req.filtersJson = JSON.serialize(filters);
            }
            
            UniversalCrmRecordAction.Response res = UniversalCrmRecordAction.processRequest(req);
            
            if (res.success && res.records != null) {
                return res.records;
            } else {
                throw new AuraHandledException(res.message != null ? res.message : 'Failed to retrieve accounts');
            }
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException('Error listing accounts: ' + e.getMessage());
        }
    }
    
    /**
     * Get account by ID
     * @param accountId Salesforce Account ID (15 or 18 character)
     * @return Account record
     */
    @AuraEnabled
    public static Account getAccountById(String accountId) {
        try {
            if (String.isBlank(accountId)) {
                throw new AuraHandledException('Account ID is required');
            }
            
            UniversalCrmRecordAction.Request req = new UniversalCrmRecordAction.Request();
            req.objectApiName = 'Account';
            req.operation = 'read';
            req.recordId = accountId;
            
            UniversalCrmRecordAction.Response res = UniversalCrmRecordAction.processRequest(req);
            
            if (res.success && res.record != null) {
                return (Account) res.record;
            } else {
                throw new AuraHandledException(res.message != null ? res.message : 'Account not found');
            }
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving account: ' + e.getMessage());
        }
    }
    
    /**
     * Create account(s)
     * @param accountData JSON string of account data. Can be single object {"Name":"Acme"} or array [{"Name":"Acme"},{"Name":"Globex"}] for bulk
     * @return Created Account record(s) - single Account or List<Account>
     */
    @AuraEnabled
    public static Object createAccount(String accountData) {
        try {
            if (String.isBlank(accountData)) {
                throw new AuraHandledException('Account data is required');
            }
            
            Object parsed = JSON.deserializeUntyped(accountData);
            UniversalCrmRecordAction.Request req = new UniversalCrmRecordAction.Request();
            req.objectApiName = 'Account';
            
            if (parsed instanceof List<Object>) {
                req.operation = 'bulkCreate';
                req.bulkRecordsJson = accountData;
            } else {
                req.operation = 'create';
                Map<String, Object> data = (Map<String, Object>) parsed;
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
            throw new AuraHandledException(res.message != null ? res.message : 'Failed to create account');
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException('Error creating account: ' + e.getMessage());
        }
    }
    
    /**
     * Update account
     * @param accountId Salesforce Account ID (15 or 18 character)
     * @param accountData JSON string of fields to update. Example: {"Industry":"Technology","BillingCity":"San Francisco"}
     * @return Updated Account record
     */
    @AuraEnabled
    public static Account updateAccount(String accountId, String accountData) {
        try {
            if (String.isBlank(accountId)) {
                throw new AuraHandledException('Account ID is required');
            }
            
            UniversalCrmRecordAction.Request req = new UniversalCrmRecordAction.Request();
            req.objectApiName = 'Account';
            req.operation = 'update';
            req.recordId = accountId;
            
            if (String.isNotBlank(accountData)) {
                Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(accountData);
                List<Map<String, String>> fieldDataList = new List<Map<String, String>>();
                for (String key : data.keySet()) {
                    fieldDataList.add(new Map<String, String>{
                        'fieldApiName' => key,
                        'value' => String.valueOf(data.get(key))
                    });
                }
                req.fieldDataJson = JSON.serialize(fieldDataList);
            }
            // If no accountData provided, handleUpdate will return current record
            
            UniversalCrmRecordAction.Response res = UniversalCrmRecordAction.processRequest(req);
            
            if (res.success && res.record != null) {
                return (Account) res.record;
            } else {
                throw new AuraHandledException(res.message != null ? res.message : 'Failed to update account');
            }
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException('Error updating account: ' + e.getMessage());
        }
    }
    
    /**
     * Delete account
     * @param accountId Salesforce Account ID (15 or 18 character)
     * @return Success message
     */
    @AuraEnabled
    public static String deleteAccount(String accountId) {
        try {
            if (String.isBlank(accountId)) {
                throw new AuraHandledException('Account ID is required');
            }
            
            UniversalCrmRecordAction.Request req = new UniversalCrmRecordAction.Request();
            req.objectApiName = 'Account';
            req.operation = 'delete';
            req.recordId = accountId;
            
            UniversalCrmRecordAction.Response res = UniversalCrmRecordAction.processRequest(req);
            
            if (res.success) {
                return 'Account deleted successfully';
            } else {
                throw new AuraHandledException(res.message != null ? res.message : 'Failed to delete account');
            }
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException('Error deleting account: ' + e.getMessage());
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

