# Program Candidate Deployment Checklist

## ✅ Pre-Deployment Verification

### Files Created/Modified
- [x] **Apex Class**: `AFProgramCandidateAction.cls` - CRUD operations for Program_Candidate__c
- [x] **Apex Class Metadata**: `AFProgramCandidateAction.cls-meta.xml` (API v65.0)
- [x] **Custom Object**: `Program_Candidate__c` with 20 custom fields
- [x] **Record Type**: `Program_Candidate_Enrollment` (for Lightning Path)
- [x] **Lightning Path**: `Enrollment_Status_Path` (8 status steps)
- [x] **Page Layout**: `Program Candidate Layout` (organized sections)
- [x] **Lightning Record Page**: `Program_Candidate_Record_Page` (FlexiPage with Path, details, timeline)
- [x] **Custom Tab**: `Program_Candidate__c` tab
- [x] **Compact Layout**: `Program_Candidate_Compact_Layout` (7 key fields)
- [x] **List View**: `All Program Candidates` (default list view)
- [x] **Permission Set**: Updated `Agentforce_SDO_CustomAssetPermissions` with:
  - Class access for `AFProgramCandidateAction`
  - Object permissions for `Program_Candidate__c` (CRUD)
  - Field permissions for all 20 fields (readable/editable)
  - Tab visibility for `Program_Candidate__c`
- [x] **Universal Action**: `AFUniversalCrmRecordAction.cls` updated to support `program_candidate__c`
- [x] **Documentation**: README.md and AF_CONTROLLERS_SETUP.md updated

### Field Summary (20 Custom Fields)
1. FirstName__c (Text, 50)
2. LastName__c (Text, 50) - **No longer required**
3. Date_of_Birth__c (Date)
4. Phone__c (Phone)
5. Email__c (Email)
6. Preferred_Contact_Method__c (Picklist: Phone, Email, Text, Mail)
7. Language_Preference__c (Picklist: English (default), Spanish, French, German, Other)
8. Street__c (Text, 255)
9. City__c (Text, 40)
10. State__c (Text, 20)
11. Postal_Code__c (Text, 20)
12. Country__c (Text, 40) - **Default: "United States"**
13. Program_Name__c (Text, 255)
14. Enrollment_Status__c (Picklist: New Inquiry (default), Information Gathering, Eligibility Review, Approved, Enrollment Pending, Enrolled, Declined, On Hold) - **Track History enabled**
15. Household_Size__c (Number)
16. Annual_Income__c (Currency)
17. Insurance_Provider__c (Text, 255) - **Key segment**
18. Insurance_Policy_Number__c (Text, 50) - **Key segment**
19. Insurance_Group_Number__c (Text, 50) - **Key segment**
20. Account__c (Lookup to Account) - Optional
21. Contact__c (Lookup to Contact) - Optional

**All fields have:**
- ✅ Human-readable labels (no "__c" in labels)
- ✅ Comprehensive descriptions for AI agent guidance
- ✅ Inline help text for end users
- ✅ No required fields (all optional)

### Key Features Implemented
- ✅ **No Required Fields**: All fields are optional for flexible enrollment
- ✅ **Default Values**: 
  - Enrollment_Status__c → "New Inquiry"
  - Language_Preference__c → "English"
  - Country__c → "United States"
- ✅ **Lightning Path**: 8-step enrollment status tracking
- ✅ **Compact Layout**: 7 key fields for mobile/compact views
- ✅ **List View**: "All Program Candidates" with 8 columns
- ✅ **Account/Contact Resolution**: Name-based lookup resolution via accountName/contactNameOrEmail parameters
- ✅ **Search**: Simple search by FirstName, LastName, Email
- ✅ **Field History**: Enrollment_Status__c tracks history

## 🚀 Deployment Steps

### 1. Deploy Metadata
```bash
cd "/Users/patrick.dennis/Desktop/Developer/Agentforce/Pat Dennis Agentforce SDO Assets/pat-dennis-agentforce-sdo-assets"
sf project deploy start --source-dir force-app/main/default --target-org <your-org-alias>
```

### 2. Verify Deployment
Check for any deployment errors. Common issues:
- Missing dependencies (should be none - all self-contained)
- Permission set conflicts (should be none - additive only)

### 3. Assign Permission Set (CRITICAL!)
```bash
sf org assign permset --name Agentforce_SDO_CustomAssetPermissions --target-org <your-org-alias>
```

Or via UI:
- Setup → Users → Permission Sets
- Find "Agentforce SDO Custom Asset Permissions"
- Manage Assignments → Add users

### 4. Configure Agentforce Agent
1. Navigate to **Setup → Agentforce Agents**
2. Edit your agent
3. Go to **Actions** tab
4. Search for **"Agentforce Program Candidate Action"**
5. Select `AFProgramCandidateAction`
6. Save

### 5. Test Deployment
Test the following operations:

**Create:**
- Create a Program Candidate with minimal data (just name)
- Create with full data (all fields)
- Create with Account/Contact lookups

**Read:**
- Read by record ID
- Verify all fields are returned

**Update:**
- Update enrollment status
- Update multiple fields
- Update with Account/Contact resolution

**Find:**
- Search by name
- Search by email
- Filter by enrollment status

**Delete:**
- Delete with confirm=false (should return confirmation)
- Delete with confirm=true (should actually delete)

## 📋 Post-Deployment Verification

- [ ] Permission set assigned to test user
- [ ] Agentforce agent configured with AFProgramCandidateAction
- [ ] Custom tab visible in Salesforce UI
- [ ] Lightning Record Page displays correctly with Path component
- [ ] Compact layout works in mobile/compact views
- [ ] List view "All Program Candidates" displays correctly
- [ ] All 20 fields visible and editable
- [ ] Default values work (Enrollment Status, Language, Country)
- [ ] Lightning Path displays all 8 status steps
- [ ] Account/Contact lookup resolution works
- [ ] Search functionality works (name, email)
- [ ] Field history tracking works for Enrollment_Status__c

## 🎯 Use Case Testing

Test the phone enrollment scenario:
1. **Initial Call**: Create record with just name → Status should be "New Inquiry"
2. **Information Gathering**: Update with contact info (phone, email) → Status can move to "Information Gathering"
3. **Eligibility**: Update with eligibility data (household size, income) → Status can move to "Eligibility Review"
4. **Insurance**: Update with insurance information (key segment)
5. **Approval**: Move to "Approved" → "Enrollment Pending" → "Enrolled"

## 📝 Notes

- **No Required Fields**: All fields are optional to support incremental data capture during phone calls
- **Default Values**: Enrollment Status defaults to "New Inquiry", Language to "English", Country to "United States"
- **Account/Contact**: Optional lookups - candidates can exist without Account/Contact initially
- **Search**: Simple search by name/email only (as specified)
- **No Validation**: Address fields have no validation - just data capture
- **Insurance**: Key segment - ensure AI agent captures this information

## 🔧 Troubleshooting

**Issue**: Permission denied errors
- **Solution**: Ensure permission set is assigned

**Issue**: Action not found in Agentforce
- **Solution**: Refresh Actions tab, verify deployment succeeded

**Issue**: Lightning Path not displaying
- **Solution**: Verify record type is assigned, check FlexiPage configuration

**Issue**: Fields not populating
- **Solution**: Check field-level security in permission set, verify field API names in Apex

---

**Deployment Date**: December 2025
**Status**: ✅ Ready for Deployment
