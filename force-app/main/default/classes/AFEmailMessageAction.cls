/**
 * AF Email Message Action
 * Invocable action for creating email messages (EmailMessage records) with support for
 * draft/sent status, preview mode, HTML formatting, and contact resolution with ambiguity handling.
 * Designed for Agentforce AI agents to create customer-facing professional emails.
 */
public with sharing class AFEmailMessageAction {
    
    /**
     * Request input for EmailMessage creation
     */
    public class Request {
        @InvocableVariable(
            label='Contact Name or Email'
            description='The name or email address of the Contact recipient. Required. Example: "Joe Smith" or "joe@example.com". If multiple contacts match, the agent will be prompted to clarify which one.'
            required=false
        )
        public String contactNameOrEmail;
        
        @InvocableVariable(
            label='Account Name'
            description='Optional Account name to help narrow down Contact search when multiple contacts with the same name exist. Example: "Acme Corp".'
            required=false
        )
        public String accountName;
        
        @InvocableVariable(
            label='Subject'
            description='Email subject line. Required for creating the email message.'
            required=false
        )
        public String subject;
        
        @InvocableVariable(
            label='Body'
            description='Email body text (plain text). Required. This is customer-facing content - maintain a professional, courteous tone. The AI agent should ensure the email is written in second person (you, your) when addressing the recipient, not third person (their, them). If the user provides content in third person, the agent should convert it to second person. The user may also describe a desired tone (e.g., casual, formal, friendly), which the agent should incorporate into the email content. If you need formatting (bullets, numbers, bold), use the htmlBody field instead.'
            required=false
        )
        public String body;
        
        @InvocableVariable(
            label='HTML Body'
            description='Optional HTML email body for rich formatting. Use this for customer-facing emails that need professional formatting: bullet points (<ul>/<li>), numbered lists (<ol>/<li>), bold (<b> or <strong>), links (<a href>), paragraphs (<p>), etc. The AI agent should ensure the email is written in second person (you, your) when addressing the recipient, not third person (their, them). If the user provides content in third person, the agent should convert it to second person. The user may also describe a desired tone (e.g., casual, formal, friendly), which the agent should incorporate into the email content. If both body and htmlBody are provided, htmlBody takes precedence.'
            required=false
        )
        public String htmlBody;
        
        @InvocableVariable(
            label='Status'
            description='Email status: "Draft" (saves as draft, Status=5) or "Sent" (sends immediately, Status=3). Default is "Draft" if not specified. If status is "Sent", the email will actually be sent via Salesforce email delivery.'
            required=false
        )
        public String status;
        
        @InvocableVariable(
            label='Confirm'
            description='Set to false to preview the email without creating it. The agent should show the preview to the user and ask for confirmation. Set to true (or omit) to create the email message immediately. When user asks to "draft an email" or "create an email", use confirm=false first to show preview, then confirm=true to create.'
            required=false
        )
        public Boolean confirm;
    }
    
    /**
     * Response output for EmailMessage operations
     */
    public class Response {
        @InvocableVariable(
            label='Success'
            description='True if operation completed successfully, false if an error occurred.'
        )
        public Boolean success;
        
        @InvocableVariable(
            label='Record ID'
            description='The Salesforce ID of the created EmailMessage record (18-character format). Use this ID for subsequent operations.'
        )
        public Id recordId;
        
        @InvocableVariable(
            label='Message'
            description='Human-readable message describing the operation result. Use this exact message to inform the user.'
        )
        public String message;
        
        @InvocableVariable(
            label='Error Message'
            description='If success is false, this contains a user-friendly error message to relay directly to the user.'
        )
        public String errorMessage;
        
        @InvocableVariable(
            label='Preview Only'
            description='True if this is a preview response (confirm=false). The email has not been created yet.'
        )
        public Boolean previewOnly;
        
        @InvocableVariable(
            label='Preview Data'
            description='JSON string representation of what would be created. Contains Subject, Body (plain text), HtmlBody (HTML), To (contact info), Status. Use this to show the user a preview before committing.'
        )
        public String previewData;
        
        @InvocableVariable(
            label='Ambiguous Relationship'
            description='True if multiple Contacts match the provided name/email. When true, DO NOT create the email. Instead, present the candidates from relationshipCandidatesJson to the user and ask which Contact they meant.'
        )
        public Boolean ambiguousRelationship;
        
        @InvocableVariable(
            label='Relationship Candidates JSON'
            description='JSON array of candidate Contact records when ambiguousRelationship is true. Each candidate includes disambiguating details (Name, Email, Account Name, etc.). Present these options to the user in a clear, numbered list, then ask them to clarify which one they meant.'
        )
        public String relationshipCandidatesJson;
        
        @InvocableVariable(
            label='Contact ID'
            description='The Salesforce ID of the Contact record that the email was created for. Useful for follow-up operations.'
        )
        public Id contactId;
        
        @InvocableVariable(
            label='Contact Name'
            description='The name of the Contact recipient. Useful for user feedback.'
        )
        public String contactName;
        
        @InvocableVariable(
            label='Contact Email'
            description='The email address of the Contact recipient. Useful for user feedback.'
        )
        public String contactEmail;
    }
    
    /**
     * Email Message Action - Creates email messages with preview and draft/sent support
     */
    @InvocableMethod(
        label='Agentforce Email Message Action'
        description='Creates customer-facing email messages (EmailMessage records) in Salesforce. IMPORTANT: This creates customer-facing emails. The AI agent should maintain a professional, courteous, and customer-focused tone throughout the email content. The AI agent must ensure emails are written in second person perspective (you, your) when addressing the recipient, not third person. Convert third-person references like their office to your office when the recipient is clear. The user may specify desired tone (professional, casual, friendly, formal, etc.) which should be reflected in the email content. Placeholder text like [Your Name] will be automatically replaced with the actual sender name. Supports preview mode (confirm=false) to show the email before creating, and both Draft and Sent status. HTML formatting is supported. The AI agent can use HTML in the htmlBody field for formatting such as bullet points, numbered lists, bold text, links, etc. If only plain text is provided in body, it will be automatically converted to HTML format. Before creating an email, you should draft it first with confirm=false to show the user a preview. Ask the user: Would you like me to show you the email I have prepared? If they say yes, use confirm=false. If they say no but want to send it, use confirm=true with status=Sent. If they want to save as draft, use confirm=true with status=Draft. Contact resolution supports ambiguity handling - if multiple contacts match, present candidates to the user. The email sender is always the current user. The email is always related to a Contact (required). If the Contact has an Account, the email will also be related to that Account via RelatedToId.'
        category='CRM Actions'
    )
    public static List<Response> emailMessageAction(List<Request> requests) {
        List<Response> responses = new List<Response>();
        
        for (Request req : requests) {
            Response res = new Response();
            res.success = false;
            res.previewOnly = false;
            res.ambiguousRelationship = false;
            
            try {
                // Validate required fields for preview/creation
                if (String.isBlank(req.contactNameOrEmail)) {
                    res.success = false;
                    res.errorMessage = 'Contact name or email is required. Please provide the name or email address of the person you want to send the email to.';
                    res.message = res.errorMessage;
                    responses.add(res);
                    continue;
                }
                
                // Validate that we have either body or htmlBody
                if (String.isBlank(req.subject) || (String.isBlank(req.body) && String.isBlank(req.htmlBody))) {
                    // Check if this is a preview request with missing data
                    if (req.confirm == false) {
                        res.success = false;
                        res.errorMessage = 'Subject and Body (or HTML Body) are required to preview the email. Please provide both the subject and body text.';
                        res.message = res.errorMessage;
                        responses.add(res);
                        continue;
                    }
                    // For creation, both are required
                    res.success = false;
                    res.errorMessage = 'Subject and Body (or HTML Body) are required to create the email message. Please provide both the subject and body text.';
                    res.message = res.errorMessage;
                    responses.add(res);
                    continue;
                }
                
                // Resolve Contact with ambiguity handling
                Id contactId;
                try {
                    contactId = resolveContactByNameOrEmail(req.contactNameOrEmail, req.accountName);
                } catch (AmbiguousRelationshipException e) {
                    // Handle ambiguous contact
                    res.success = false;
                    res.ambiguousRelationship = true;
                    res.relationshipCandidatesJson = JSON.serialize(e.candidates);
                    res.errorMessage = 'I found multiple contacts matching "' + req.contactNameOrEmail + '". Please clarify which one you meant.';
                    res.message = res.errorMessage;
                    responses.add(res);
                    continue;
                } catch (Exception e) {
                    res.success = false;
                    res.errorMessage = 'Could not find a contact matching "' + req.contactNameOrEmail + '". ' + e.getMessage() + ' Please verify the contact name or email and try again.';
                    res.message = res.errorMessage;
                    responses.add(res);
                    continue;
                }
                
                // Get Contact details
                Contact con = [
                    SELECT Id, Name, Email, AccountId, Account.Name
                    FROM Contact
                    WHERE Id = :contactId
                    LIMIT 1
                ];
                
                res.contactId = con.Id;
                res.contactName = con.Name;
                res.contactEmail = con.Email != null ? con.Email : 'No email on file';
                
                // Get current user for sender info
                User currentUser = [
                    SELECT Id, Name, Email
                    FROM User
                    WHERE Id = :UserInfo.getUserId()
                    LIMIT 1
                ];
                
                // Determine status
                String emailStatus = '5'; // Default to Draft
                String statusLabel = 'Draft';
                if (!String.isBlank(req.status)) {
                    String statusLower = req.status.toLowerCase();
                    if (statusLower == 'sent' || statusLower == 'send' || statusLower == '3') {
                        emailStatus = '3'; // Sent
                        statusLabel = 'Sent';
                    } else if (statusLower == 'draft' || statusLower == '5') {
                        emailStatus = '5'; // Draft
                        statusLabel = 'Draft';
                    }
                }
                
                // Process body content - ensure we have both plain text and HTML
                String textBody;
                String htmlBody;
                
                if (!String.isBlank(req.htmlBody)) {
                    // HTML body provided - check if it's markdown or actual HTML
                    if (isMarkdown(req.htmlBody)) {
                        // It's markdown, convert to HTML
                        htmlBody = convertMarkdownToHtml(req.htmlBody);
                        textBody = stripHtmlTags(htmlBody);
                        // Fall back to body if stripping results in empty
                        if (String.isBlank(textBody) && !String.isBlank(req.body)) {
                            textBody = req.body;
                        }
                    } else {
                        // It's HTML, use it directly
                        htmlBody = req.htmlBody;
                        textBody = stripHtmlTags(req.htmlBody);
                        // Fall back to body if stripping results in empty
                        if (String.isBlank(textBody) && !String.isBlank(req.body)) {
                            textBody = req.body;
                        }
                    }
                } else if (!String.isBlank(req.body)) {
                    // Only body provided - check if it contains markdown
                    textBody = req.body;
                    if (isMarkdown(req.body)) {
                        // Contains markdown, convert to HTML
                        htmlBody = convertMarkdownToHtml(req.body);
                    } else {
                        // Plain text, convert to basic HTML
                        htmlBody = convertPlainTextToHtml(req.body);
                    }
                } else {
                    // Should not happen due to validation above, but handle gracefully
                    textBody = '';
                    htmlBody = '';
                }
                
                // Replace placeholders with actual sender information
                // Apply to both textBody and htmlBody
                textBody = replacePlaceholders(textBody, currentUser.Name, currentUser.Email);
                htmlBody = replacePlaceholders(htmlBody, currentUser.Name, currentUser.Email);
                
                // Preview mode (confirm=false)
                if (req.confirm == false) {
                    res.previewOnly = true;
                    res.success = true;
                    
                    // Build preview data
                    Map<String, Object> previewMap = new Map<String, Object>();
                    previewMap.put('To', con.Name + (con.Email != null ? ' <' + con.Email + '>' : ''));
                    previewMap.put('From', currentUser.Name + (currentUser.Email != null ? ' <' + currentUser.Email + '>' : ''));
                    previewMap.put('Subject', req.subject);
                    previewMap.put('Body', textBody);
                    previewMap.put('HtmlBody', htmlBody);
                    previewMap.put('Status', statusLabel);
                    previewMap.put('Contact', con.Name);
                    if (con.Account != null) {
                        previewMap.put('Account', con.Account.Name);
                    }
                    previewMap.put('HasHtmlFormatting', !String.isBlank(req.htmlBody) || (htmlBody.contains('<') && htmlBody.contains('>')));
                    
                    res.previewData = JSON.serialize(previewMap);
                    
                    String previewMessage = 'Here is the email I prepared:\n\n' +
                                          'To: ' + con.Name + (con.Email != null ? ' (' + con.Email + ')' : '') + '\n' +
                                          'Subject: ' + req.subject + '\n' +
                                          'Status: ' + statusLabel + '\n\n';
                    
                    if (!String.isBlank(req.htmlBody) || (htmlBody.contains('<') && htmlBody.contains('>'))) {
                        previewMessage += 'Body (HTML formatted):\n' + textBody + '\n\n';
                    } else {
                        previewMessage += 'Body:\n' + textBody + '\n\n';
                    }
                    
                    previewMessage += 'Would you like me to ' + (emailStatus == '3' ? 'send' : 'save') + ' this email, or would you like to make any changes?';
                    res.message = previewMessage;
                    responses.add(res);
                    continue;
                }
                
                // Savepoint for rollback on error
                Savepoint sp = Database.setSavepoint();
                
                try {
                    if (emailStatus == '3') {
                        // Send email using Messaging API - this actually sends the email
                        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                        
                        // Set recipient - use Contact email or ToAddress
                        if (con.Email != null) {
                            mail.setToAddresses(new List<String>{ con.Email });
                        } else if (!String.isBlank(req.contactNameOrEmail) && req.contactNameOrEmail.contains('@')) {
                            mail.setToAddresses(new List<String>{ req.contactNameOrEmail });
                        } else {
                            throw new ActionException('Contact does not have an email address. Cannot send email without a recipient email.');
                        }
                        
                        // Set subject and body
                        mail.setSubject(req.subject);
                        if (!String.isBlank(htmlBody)) {
                            mail.setHtmlBody(htmlBody);
                            if (!String.isBlank(textBody)) {
                                mail.setPlainTextBody(textBody);
                            }
                        } else {
                            mail.setPlainTextBody(textBody);
                        }
                        
                        // Link to Contact using setTargetObjectId (preferred for Contact)
                        mail.setTargetObjectId(con.Id);
                        
                        // Link to Account if available using setWhatId
                        if (con.AccountId != null) {
                            mail.setWhatId(con.AccountId);
                        }
                        
                        // Set sender (current user)
                        mail.setOrgWideEmailAddressId(null); // Use current user's email
                        mail.setReplyTo(currentUser.Email != null ? currentUser.Email : UserInfo.getUserEmail());
                        
                        // Save as activity so it creates EmailMessage record
                        mail.setSaveAsActivity(true);
                        
                        // Send the email
                        Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[]{ mail });
                        
                        if (results[0].isSuccess()) {
                            // Query for the EmailMessage that was just created by Messaging.sendEmail()
                            // Messaging.sendEmail() with setSaveAsActivity(true) creates a Task and EmailMessage
                            // The EmailMessage is linked via ActivityId to the Task
                            // Query by most recent Task for this Contact with matching subject
                            DateTime queryStartTime = DateTime.now().addSeconds(-10); // Give some buffer for timing
                            
                            List<Task> tasks = [
                                SELECT Id, ActivityDate, Subject, WhatId, WhoId, CreatedDate
                                FROM Task
                                WHERE WhoId = :con.Id
                                  AND Subject = :req.subject
                                  AND CreatedDate >= :queryStartTime
                                ORDER BY CreatedDate DESC
                                LIMIT 1
                            ];
                            
                            Id emailMessageId = null;
                            if (!tasks.isEmpty()) {
                                // Find EmailMessage linked to this Task via ActivityId
                                List<EmailMessage> createdEmails = [
                                    SELECT Id, Status, Subject, ActivityId, RelatedToId
                                    FROM EmailMessage
                                    WHERE ActivityId = :tasks[0].Id
                                    LIMIT 1
                                ];
                                
                                if (!createdEmails.isEmpty()) {
                                    emailMessageId = createdEmails[0].Id;
                                }
                            }
                            
                            // Fallback: If we didn't find via Task, try querying by RelatedToId and subject
                            if (emailMessageId == null && con.AccountId != null) {
                                List<EmailMessage> createdEmails = [
                                    SELECT Id, Status, Subject, RelatedToId
                                    FROM EmailMessage
                                    WHERE RelatedToId = :con.AccountId
                                      AND Subject = :req.subject
                                      AND CreatedDate >= :queryStartTime
                                    ORDER BY CreatedDate DESC
                                    LIMIT 1
                                ];
                                
                                if (!createdEmails.isEmpty()) {
                                    emailMessageId = createdEmails[0].Id;
                                }
                            }
                            
                            // Ensure EmailMessageRelation exists for Contact
                            // Messaging.sendEmail() with setTargetObjectId() should create it automatically,
                            // but we'll verify and create if needed for consistency
                            if (emailMessageId != null) {
                                List<EmailMessageRelation> existingRelations = [
                                    SELECT Id
                                    FROM EmailMessageRelation
                                    WHERE EmailMessageId = :emailMessageId
                                      AND RelationId = :con.Id
                                      AND RelationType = 'ToAddress'
                                    LIMIT 1
                                ];
                                
                                if (existingRelations.isEmpty()) {
                                    try {
                                        EmailMessageRelation emr = new EmailMessageRelation();
                                        emr.EmailMessageId = emailMessageId;
                                        emr.RelationId = con.Id;
                                        emr.RelationType = 'ToAddress';
                                        insert emr;
                                    } catch (Exception relEx) {
                                        // Relation might already exist or EmailMessage might not allow relations
                                        // Log but don't fail the operation since email was sent successfully
                                        System.debug(LoggingLevel.WARN, 'Could not create EmailMessageRelation: ' + relEx.getMessage());
                                    }
                                }
                            }
                            
                            res.success = true;
                            res.recordId = emailMessageId; // May be null if we couldn't find it, but email was sent
                            String successMessage = 'Email message sent successfully to ' + con.Name + 
                                          (con.Email != null ? ' (' + con.Email + ')' : '') + '. ' +
                                          'Subject: "' + req.subject + '". ' +
                                          'The email has been sent via Salesforce.';
                            if (emailMessageId == null) {
                                successMessage += ' Note: The EmailMessage record may not be immediately available for querying.';
                            }
                            res.message = successMessage;
                        } else {
                            // Send failed - rollback and try to save as draft
                            Database.rollback(sp);
                            String errorMsg = 'Failed to send email';
                            if (!results[0].getErrors().isEmpty()) {
                                errorMsg += ': ' + results[0].getErrors()[0].getMessage();
                            }
                            throw new ActionException(errorMsg);
                        }
                    } else {
                        // Draft status - create EmailMessage record directly
                        EmailMessage emailMsg = new EmailMessage();
                        emailMsg.Subject = req.subject;
                        emailMsg.FromName = currentUser.Name;
                        emailMsg.FromAddress = currentUser.Email != null ? currentUser.Email : UserInfo.getUserEmail();
                        emailMsg.ToAddress = con.Email != null ? con.Email : '';
                        emailMsg.TextBody = textBody;
                        emailMsg.HtmlBody = htmlBody;
                        emailMsg.MessageDate = DateTime.now();
                        emailMsg.Status = '5'; // Draft
                        
                        // Set RelatedToId - use Contact's Account if available
                        if (con.AccountId != null) {
                            emailMsg.RelatedToId = con.AccountId;
                        }
                        
                        insert emailMsg;
                        
                        // Create EmailMessageRelation to link to Contact
                        EmailMessageRelation emr = new EmailMessageRelation();
                        emr.EmailMessageId = emailMsg.Id;
                        emr.RelationId = con.Id;
                        emr.RelationType = 'ToAddress';
                        insert emr;
                        
                        res.success = true;
                        res.recordId = emailMsg.Id;
                        res.message = 'Email message saved as draft successfully to ' + con.Name + 
                                      (con.Email != null ? ' (' + con.Email + ')' : '') + '. ' +
                                      'Subject: "' + req.subject + '". ' +
                                      'You can review and send it later from your drafts.';
                    }
                    
                } catch (Exception e) {
                    // Rollback on error
                    Database.rollback(sp);
                    
                    // Try to save as draft if sending failed
                    if (emailStatus == '3') {
                        try {
                            EmailMessage emailMsg = new EmailMessage();
                            emailMsg.Subject = req.subject;
                            emailMsg.FromName = currentUser.Name;
                            emailMsg.FromAddress = currentUser.Email != null ? currentUser.Email : UserInfo.getUserEmail();
                            emailMsg.ToAddress = con.Email != null ? con.Email : '';
                            emailMsg.TextBody = textBody;
                            emailMsg.HtmlBody = htmlBody;
                            emailMsg.MessageDate = DateTime.now();
                            emailMsg.Status = '5'; // Save as draft instead
                            
                            if (con.AccountId != null) {
                                emailMsg.RelatedToId = con.AccountId;
                            }
                            
                            insert emailMsg;
                            
                            EmailMessageRelation emr = new EmailMessageRelation();
                            emr.EmailMessageId = emailMsg.Id;
                            emr.RelationId = con.Id;
                            emr.RelationType = 'ToAddress';
                            insert emr;
                            
                            res.success = true;
                            res.recordId = emailMsg.Id;
                            res.message = 'There was an issue sending the email, so I saved it as a draft instead. The email has been saved to ' + con.Name + 
                                          (con.Email != null ? ' (' + con.Email + ')' : '') + '. ' +
                                          'Subject: "' + req.subject + '". ' +
                                          'You can review and send it later from your drafts. Error: ' + e.getMessage();
                        } catch (Exception e2) {
                            res.success = false;
                            res.errorMessage = 'Failed to create email message: ' + e2.getMessage();
                            res.message = 'I encountered an error while creating the email: ' + e2.getMessage() + '. Please try again.';
                        }
                    } else {
                        res.success = false;
                        res.errorMessage = 'Failed to create email message: ' + e.getMessage();
                        res.message = 'I encountered an error while creating the email: ' + e.getMessage() + '. Please try again.';
                    }
                }
                
            } catch (Exception e) {
                res.success = false;
                res.errorMessage = 'Unexpected error: ' + e.getMessage();
                res.message = 'I encountered an unexpected error: ' + e.getMessage() + '. Please try again.';
                System.debug(LoggingLevel.ERROR, 'AFEmailMessageAction error: ' + e.getMessage());
                System.debug(LoggingLevel.ERROR, 'Stack trace: ' + e.getStackTraceString());
            }
            
            responses.add(res);
        }
        
        return responses;
    }
    
    /**
     * Convert plain text to HTML format for email client compatibility
     * Converts line breaks to HTML formatting while preserving structure
     * Also checks for markdown and converts it if detected
     */
    private static String convertPlainTextToHtml(String plainText) {
        if (String.isBlank(plainText)) {
            return '';
        }
        
        // Check if it's markdown - if so, convert markdown to HTML
        if (isMarkdown(plainText)) {
            return convertMarkdownToHtml(plainText);
        }
        
        // Check if already contains HTML tags
        if (plainText.contains('<') && plainText.contains('>')) {
            // Assume it's already HTML, return as-is
            return plainText;
        }
        
        // Escape HTML special characters first
        String html = plainText
            .replace('&', '&amp;')
            .replace('<', '&lt;')
            .replace('>', '&gt;');
        
        // Convert double line breaks to paragraphs
        String[] paragraphs = html.split('\n\n+');
        List<String> htmlParagraphs = new List<String>();
        for (String para : paragraphs) {
            String trimmed = para.trim();
            if (!String.isBlank(trimmed)) {
                // Convert single line breaks within paragraphs to <br>
                trimmed = trimmed.replace('\n', '<br>');
                htmlParagraphs.add('<p>' + trimmed + '</p>');
            }
        }
        
        if (htmlParagraphs.isEmpty()) {
            // If no paragraphs, just convert line breaks to <br>
            html = html.replace('\n', '<br>');
            return html;
        }
        
        return String.join(htmlParagraphs, '\n');
    }
    
    /**
     * Check if text contains markdown formatting syntax
     * Detects common markdown patterns like **bold**, *italic*, lists, etc.
     * Returns false if content already has proper HTML structure
     */
    private static Boolean isMarkdown(String text) {
        if (String.isBlank(text)) {
            return false;
        }
        
        // If content has HTML tags that look like valid HTML structure, it's probably HTML, not markdown
        if (text.contains('<') && text.contains('>')) {
            // Check if it has proper HTML tags (not just < and > characters)
            // Common HTML tags in email: p, br, strong, em, ul, ol, li, div, span
            Boolean hasHtmlTags = text.contains('<p') || text.contains('<br') || 
                                 text.contains('<strong') || text.contains('<em') ||
                                 text.contains('<ul') || text.contains('<ol') ||
                                 text.contains('<li') || text.contains('<div') ||
                                 text.contains('<span') || text.contains('</');
            
            // If it has proper HTML tags, it's HTML, not markdown
            if (hasHtmlTags) {
                return false;
            }
        }
        
        // Check for markdown patterns
        // Bold: **text** or __text__
        Boolean hasBold = text.contains('**') || text.contains('__');
        
        // Italic: *text* or _text_ (but not part of bold)
        Boolean hasItalic = false;
        if (text.contains('*') || text.contains('_')) {
            // Simple check: look for single * or _ that aren't part of ** or __
            // Check if there's a * that's not immediately followed or preceded by another *
            String[] lines = text.split('\\r?\\n');
            for (String line : lines) {
                // Check for single * not part of **
                if (line.contains('*')) {
                    String temp = line.replace('**', '');
                    if (temp.contains('*')) {
                        hasItalic = true;
                        break;
                    }
                }
                // Check for single _ not part of __
                if (line.contains('_')) {
                    String temp = line.replace('__', '');
                    if (temp.contains('_')) {
                        hasItalic = true;
                        break;
                    }
                }
            }
        }
        
        // Lists: lines starting with - , * , or 1.
        String[] lines = text.split('\\r?\\n');
        Boolean hasList = false;
        Boolean hasHeader = false;
        Pattern listPattern1 = Pattern.compile('^[-*]\\s+.*');
        Pattern listPattern2 = Pattern.compile('^\\d+\\.\\s+.*');
        Pattern headerPattern = Pattern.compile('^#+\\s+.*');
        
        for (String line : lines) {
            String trimmed = line.trim();
            // Check for list items
            if (listPattern1.matcher(trimmed).matches() || listPattern2.matcher(trimmed).matches()) {
                hasList = true;
                break;
            }
            // Check for headers
            if (headerPattern.matcher(trimmed).matches()) {
                hasHeader = true;
                break;
            }
        }
        
        return hasBold || hasItalic || hasList || hasHeader;
    }
    
    /**
     * Convert markdown to HTML for email formatting
     * Handles common markdown patterns: bold, italic, lists, paragraphs
     */
    private static String convertMarkdownToHtml(String markdown) {
        if (String.isBlank(markdown)) {
            return '';
        }
        
        String html = markdown;
        
        // Step 1: Convert bold: **text** or __text__ to <strong>text</strong>
        // Process ** first (most common)
        html = html.replaceAll('\\*\\*([^*\\n]+?)\\*\\*', '<strong>$1</strong>');
        // Process __ (alternative bold)
        html = html.replaceAll('__([^_\\n]+?)__', '<strong>$1</strong>');
        
        // Step 2: Convert italic: *text* or _text_ to <em>text</em>
        // Only match * that aren't part of ** (already processed)
        html = html.replaceAll('(?<!\\*)\\*([^*\\n\\*]+?)\\*(?!\\*)', '<em>$1</em>');
        // Only match _ that aren't part of __ (already processed)
        html = html.replaceAll('(?<!_)_([^_\\n_]+?)_(?!_)', '<em>$1</em>');
        
        // Step 3: Process lists line by line
        String[] lines = html.split('\\r?\\n');
        List<String> processedLines = new List<String>();
        Boolean inOrderedList = false;
        Boolean inUnorderedList = false;
        
        // Pre-compile patterns for list detection
        Pattern orderedListPattern = Pattern.compile('^\\d+\\.\\s+.*');
        Pattern unorderedListPattern = Pattern.compile('^[-*]\\s+.*');
        Pattern emptyStarPattern = Pattern.compile('^\\*\\s*$');
        
        for (Integer i = 0; i < lines.size(); i++) {
            String line = lines[i];
            String trimmedLine = line.trim();
            
            // Check for ordered list (numbered): 1. item
            if (orderedListPattern.matcher(trimmedLine).matches()) {
                if (inUnorderedList) {
                    processedLines.add('</ul>');
                    inUnorderedList = false;
                }
                if (!inOrderedList) {
                    processedLines.add('<ol>');
                    inOrderedList = true;
                }
                String listItem = trimmedLine.replaceFirst('^\\d+\\.\\s+', '').trim();
                processedLines.add('<li>' + listItem + '</li>');
            }
            // Check for unordered list: - item or * item (but not if * is for formatting)
            else if (unorderedListPattern.matcher(trimmedLine).matches() && !emptyStarPattern.matcher(trimmedLine).matches()) {
                if (inOrderedList) {
                    processedLines.add('</ol>');
                    inOrderedList = false;
                }
                if (!inUnorderedList) {
                    processedLines.add('<ul>');
                    inUnorderedList = true;
                }
                String listItem = trimmedLine.replaceFirst('^[-*]\\s+', '').trim();
                processedLines.add('<li>' + listItem + '</li>');
            }
            // Regular line
            else {
                // Close any open lists
                if (inOrderedList) {
                    processedLines.add('</ol>');
                    inOrderedList = false;
                }
                if (inUnorderedList) {
                    processedLines.add('</ul>');
                    inUnorderedList = false;
                }
                processedLines.add(line);
            }
        }
        
        // Close any lists still open at the end
        if (inOrderedList) {
            processedLines.add('</ol>');
        }
        if (inUnorderedList) {
            processedLines.add('</ul>');
        }
        
        html = String.join(processedLines, '\n');
        
        // Step 4: Convert paragraphs and line breaks
        // If we don't have list/paragraph structure, wrap in paragraphs
        if (!html.contains('<ol>') && !html.contains('<ul>') && !html.contains('<p>')) {
            // Split by double line breaks for paragraphs
            String[] paragraphs = html.split('\\n\\n+');
            List<String> htmlParagraphs = new List<String>();
            for (String para : paragraphs) {
                String trimmed = para.trim();
                if (!String.isBlank(trimmed)) {
                    // Convert single line breaks within paragraphs to <br>
                    trimmed = trimmed.replace('\n', '<br>');
                    htmlParagraphs.add('<p>' + trimmed + '</p>');
                }
            }
            if (!htmlParagraphs.isEmpty()) {
                html = String.join(htmlParagraphs, '\n');
            } else {
                // No paragraphs, just convert line breaks to <br>
                html = html.replace('\n', '<br>');
            }
        } else {
            // Has lists/HTML structure, just ensure single line breaks are <br> within non-HTML content
            lines = html.split('\\r?\\n');
            processedLines = new List<String>();
            for (String line : lines) {
                if (!line.trim().startsWith('<') && !String.isBlank(line.trim())) {
                    // Line doesn't start with HTML tag, preserve content but may need <br>
                    processedLines.add(line);
                } else {
                    processedLines.add(line);
                }
            }
            html = String.join(processedLines, '\n');
        }
        
        return html;
    }
    
    /**
     * Strip HTML tags from HTML content to create plain text fallback
     * Handles common HTML entities and formatting
     */
    private static String stripHtmlTags(String html) {
        if (String.isBlank(html)) {
            return '';
        }
        
        try {
            // Basic HTML tag stripping for plain text fallback
            String plainText = html.replaceAll('<[^>]+>', ' ')
                                   .replaceAll('&nbsp;', ' ')
                                   .replaceAll('&amp;', '&')
                                   .replaceAll('&lt;', '<')
                                   .replaceAll('&gt;', '>')
                                   .replaceAll('&quot;', '"')
                                   .replaceAll('&apos;', '\'')
                                   .replaceAll('\\s+', ' ')
                                   .trim();
            
            // Restore some line breaks from block elements
            // This is a simplified approach - for better results, consider more sophisticated parsing
            plainText = plainText.replaceAll('\\s*<p>\\s*', '\n\n')
                                 .replaceAll('\\s*</p>\\s*', '\n\n')
                                 .replaceAll('\\s*<br\\s*/?>\\s*', '\n')
                                 .replaceAll('\\s*<li>\\s*', '\n• ')
                                 .replaceAll('\\s*</li>\\s*', '\n')
                                 .replaceAll('\\n\\n+', '\n\n')
                                 .trim();
            
            return plainText;
        } catch (Exception e) {
            // If stripping fails, return the original HTML as plain text
            System.debug(LoggingLevel.WARN, 'Failed to strip HTML tags: ' + e.getMessage());
            return html.replaceAll('<[^>]+>', ' ');
        }
    }
    
    /**
     * Replace placeholder text with actual sender information
     * Handles common placeholders like [Your Name], [Sender Name], [Your Email], [Sender Email]
     * Works with both plain text and HTML content (preserves HTML tags)
     * Case-insensitive matching
     */
    private static String replacePlaceholders(String text, String senderName, String senderEmail) {
        if (String.isBlank(text)) {
            return text;
        }
        
        String result = text;
        
        // Replace name placeholders (case-insensitive)
        if (!String.isBlank(senderName)) {
            // Use pattern matching for case-insensitive replacement
            // Apex doesn't have built-in case-insensitive replace, so we'll use replaceAll with regex
            result = result.replaceAll('(?i)\\[Your Name\\]', senderName);
            result = result.replaceAll('(?i)\\[Sender Name\\]', senderName);
        }
        
        // Replace email placeholders (case-insensitive)
        if (!String.isBlank(senderEmail)) {
            result = result.replaceAll('(?i)\\[Your Email\\]', senderEmail);
            result = result.replaceAll('(?i)\\[Sender Email\\]', senderEmail);
        }
        
        return result;
    }
    
    /**
     * Resolve Contact by name or email with optional Account scope
     * Reuses logic from AFUniversalCrmRecordAction for consistency
     */
    private static Id resolveContactByNameOrEmail(String nameOrEmail, String accountName) {
        // Check if input is already a Salesforce ID (15 or 18 characters starting with 003)
        if (nameOrEmail != null && (nameOrEmail.length() == 15 || nameOrEmail.length() == 18)) {
            try {
                Id contactId = Id.valueOf(nameOrEmail);
                if (String.valueOf(contactId).startsWith('003')) {
                    List<Contact> existingContact = [
                        SELECT Id FROM Contact WHERE Id = :contactId LIMIT 1
                    ];
                    if (!existingContact.isEmpty()) {
                        return contactId;
                    }
                }
            } catch (Exception e) {
                // Not a valid ID, continue with name lookup
            }
        }
        
        String searchTerm = String.escapeSingleQuotes(nameOrEmail);
        String accountSearchTerm = !String.isBlank(accountName) ? String.escapeSingleQuotes(accountName) : null;
        
        // Try email first (more specific)
        List<Contact> contacts;
        if (!String.isBlank(accountSearchTerm)) {
            String accountLikePattern = '%' + accountSearchTerm + '%';
            contacts = [
                SELECT Id, Name, Email, Phone, Account.Name, Title, Department
                FROM Contact 
                WHERE Email = :nameOrEmail 
                  AND Account.Name LIKE :accountLikePattern
                ORDER BY LastModifiedDate DESC 
                LIMIT 2
            ];
        } else {
            contacts = [
                SELECT Id, Name, Email, Phone, Account.Name, Title, Department
                FROM Contact 
                WHERE Email = :nameOrEmail 
                ORDER BY LastModifiedDate DESC 
                LIMIT 2
            ];
        }
        
        if (!contacts.isEmpty()) {
            if (contacts.size() > 1) {
                List<Map<String, Object>> candidates = new List<Map<String, Object>>();
                for (Contact con : contacts) {
                    Map<String, Object> candidate = new Map<String, Object>();
                    candidate.put('Id', con.Id);
                    candidate.put('Name', con.Name);
                    candidate.put('Email', con.Email);
                    candidate.put('Phone', con.Phone);
                    candidate.put('AccountName', con.Account != null ? con.Account.Name : null);
                    candidate.put('Title', con.Title);
                    candidate.put('Department', con.Department);
                    candidates.add(candidate);
                }
                throw new AmbiguousRelationshipException('Contact', nameOrEmail, candidates);
            }
            return contacts[0].Id;
        }
        
        // Try name match with optional account filter
        String likePattern = '%' + searchTerm + '%';
        if (!String.isBlank(accountSearchTerm)) {
            String accountLikePattern = '%' + accountSearchTerm + '%';
            contacts = [
                SELECT Id, Name, Email, Phone, Account.Name, Title, Department
                FROM Contact 
                WHERE (Name LIKE :likePattern
                   OR FirstName LIKE :likePattern
                   OR LastName LIKE :likePattern)
                  AND Account.Name LIKE :accountLikePattern
                ORDER BY LastModifiedDate DESC 
                LIMIT 6
            ];
        } else {
            contacts = [
                SELECT Id, Name, Email, Phone, Account.Name, Title, Department
                FROM Contact 
                WHERE Name LIKE :likePattern
                   OR FirstName LIKE :likePattern
                   OR LastName LIKE :likePattern
                ORDER BY LastModifiedDate DESC 
                LIMIT 6
            ];
        }
        
        if (contacts.isEmpty()) {
            throw new AFUniversalCrmRecordAction.MissingParentException('Contact', nameOrEmail, new List<String>(), new List<String>());
        }
        
        // If multiple name matches found, throw ambiguity exception
        if (contacts.size() > 1) {
            List<Map<String, Object>> candidates = new List<Map<String, Object>>();
            for (Contact con : contacts) {
                Map<String, Object> candidate = new Map<String, Object>();
                candidate.put('Id', con.Id);
                candidate.put('Name', con.Name);
                candidate.put('Email', con.Email);
                candidate.put('Phone', con.Phone);
                candidate.put('AccountName', con.Account != null ? con.Account.Name : null);
                candidate.put('Title', con.Title);
                candidate.put('Department', con.Department);
                candidates.add(candidate);
            }
                    throw new AmbiguousRelationshipException('Contact', nameOrEmail, candidates);
        }
        
        return contacts[0].Id;
    }
    
    /**
     * Custom exception class for action-specific errors
     */
    private class ActionException extends Exception {}
}
