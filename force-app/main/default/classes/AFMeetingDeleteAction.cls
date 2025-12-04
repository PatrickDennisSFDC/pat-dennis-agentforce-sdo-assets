/**
 * AF Meeting Delete Action
 * Invocable action for deleting Meeting__c records (with confirmation)
 * Designed for Agentforce AI agents
 */
public with sharing class AFMeetingDeleteAction {
    
    public class Request {
        @InvocableVariable(label='Record ID' required=true)
        public Id recordId;
        
        @InvocableVariable(label='Confirm')
        public Boolean confirm;
    }
    
    public class Response {
        @InvocableVariable(label='Success')
        public Boolean success;
        
        @InvocableVariable(label='Record ID')
        public Id recordId;
        
        @InvocableVariable(label='Message')
        public String message;
        
        @InvocableVariable(label='Error Message')
        public String errorMessage;
        
        @InvocableVariable(label='Object Type')
        public String objectType;
        
        @InvocableVariable(label='Confirmation Required')
        public Boolean confirmationRequired;
        
        @InvocableVariable(label='Related Account Name')
        public String relatedAccountName;
        
        @InvocableVariable(label='Related Contact Name')
        public String relatedContactName;
    }
    
    @InvocableMethod(
        label='Delete Meeting'
        description='Deletes a Meeting__c record. Requires confirmation: first call with confirm=false, then with confirm=true to actually delete.'
        category='CRM Actions'
    )
    public static List<Response> deleteMeeting(List<Request> requests) {
        List<Response> responses = new List<Response>();
        
        for (Request req : requests) {
            Response res = new Response();
            res.objectType = 'Meeting__c';
            res.success = false;
            res.confirmationRequired = false;
            
            try {
                if (req.recordId == null) {
                    res.errorMessage = 'Record ID is required.';
                    responses.add(res);
                    continue;
                }
                
                if (req.confirm == null || req.confirm == false) {
                    res.confirmationRequired = true;
                    res.recordId = req.recordId;
                    
                    try {
                        Meeting__c meeting = [SELECT Id, Subject__c, Meeting_Date__c, Meeting_Status__c,
                                             Account__r.Name, Contact__r.Name
                                             FROM Meeting__c 
                                             WHERE Id = :req.recordId 
                                             LIMIT 1];
                        
                        if (meeting.Account__r != null) {
                            res.relatedAccountName = meeting.Account__r.Name;
                        }
                        if (meeting.Contact__r != null) {
                            res.relatedContactName = meeting.Contact__r.Name;
                        }
                        
                        String meetingDesc = meeting.Subject__c != null ? '"' + meeting.Subject__c + '"' : 'this meeting';
                        res.message = 'This will delete Meeting ' + meetingDesc + 
                                     ' (Date: ' + meeting.Meeting_Date__c + '). ' +
                                     'Call again with confirm=true to proceed.';
                        res.success = true;
                    } catch (QueryException qe) {
                        res.errorMessage = 'Meeting not found with ID: ' + req.recordId;
                    }
                    
                    responses.add(res);
                    continue;
                }
                
                AFUniversalCrmRecordAction.Request actionReq = new AFUniversalCrmRecordAction.Request();
                actionReq.objectApiName = 'Meeting__c';
                actionReq.operation = 'delete';
                actionReq.recordId = req.recordId;
                
                AFUniversalCrmRecordAction.Response actionRes = AFUniversalCrmRecordAction.processRequest(actionReq);
                
                if (actionRes.success) {
                    res.success = true;
                    res.recordId = actionRes.recordId;
                    res.message = actionRes.message != null ? actionRes.message : 'Meeting deleted successfully.';
                } else {
                    res.success = false;
                    res.errorMessage = actionRes.message != null ? actionRes.message : 'Failed to delete Meeting.';
                }
                
            } catch (Exception e) {
                res.success = false;
                res.errorMessage = 'Error deleting Meeting: ' + e.getMessage();
                System.debug(LoggingLevel.ERROR, 'AFMeetingDeleteAction: Exception - ' + e.getMessage());
            }
            
            responses.add(res);
        }
        
        return responses;
    }
}


