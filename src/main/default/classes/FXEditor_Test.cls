@isTest
private class FXEditor_Test
{
    static testMethod void RunThrough() 
    {
        Test.startTest();
         Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);   
        List<Price_Book_Item__c> pliItems = CreatePriceBookItems(5, job.Price_Book__c, 'Labor');

        RecordType officeRecordType = [SELECT Id, Name, DeveloperName FROM RecordType where IsActive=true AND  SobjectType = 'Account' and DeveloperName != 'office' LIMIT 1];
        Account acct = new Account(name='Account123', RecordTypeId = officeRecordType.Id);
        insert acct;

        Contact p1 = new Contact(FirstName='Jane', LastName='Doe', Account = acct);
        insert p1;


        Crew_Planning__c cp = new Crew_Planning__c(Job__c = job.Id, Role_on_Job__c = pliItems.get(0).Id, Crew_Member__c = p1.Id);
        insert cp;

        PageReference page = new PageReference('CrewPlanningEditor');
        page.getParameters().put('id', cp.Id);
        Test.setCurrentPage(page);        
      
        FXEditorController ctrl = new FXEditorController(new ApexPages.StandardController(cp));  
        List<LayoutField> fields = ctrl.LayoutFields;
        List<LayoutSection> sects = ctrl.LayoutSections;
          
        Test.stopTest();

    }
    static testMethod void newCrewPlaningTest() 
    {

        Test.startTest();
        Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);       
        PageReference page = new PageReference('CrewPlanningEditor');
        page.getParameters().put('retURL', '/' + job.Id);
        page.getParameters().put('entityType', String.valueOf(Crew_Planning__c.class));
        Test.setCurrentPage(page);        
      
        FXEditorController ext = new FXEditorController(new ApexPages.StandardController(new Crew_Planning__c()));   
     
        PageReference p2 = ext.doCancel();   
        Test.stopTest();
    }  

    static testMethod void editCrewPlaningTest() 
    {

        Test.startTest();
        Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);   
        List<Price_Book_Item__c> pliItems = CreatePriceBookItems(5, job.Price_Book__c, 'Labor');

        RecordType officeRecordType = [SELECT Id, Name, DeveloperName FROM RecordType where IsActive=true AND  SobjectType = 'Account' and DeveloperName != 'office' LIMIT 1];
        Account acct = new Account(name='Account123', RecordTypeId = officeRecordType.Id);
        insert acct;

        Contact p1 = new Contact(FirstName='Jane', LastName='Doe', Account = acct);
        insert p1;


        Crew_Planning__c cp = new Crew_Planning__c(Job__c = job.Id, Role_on_Job__c = pliItems.get(0).Id, Crew_Member__c = p1.Id);
        insert cp;

        PageReference page = new PageReference('CrewPlanningEditor');
        page.getParameters().put('id', cp.Id);
        Test.setCurrentPage(page);        
      
        FXEditorController ext = new FXEditorController(new ApexPages.StandardController(cp));   
     
        PageReference p2 = ext.save();   
        Test.stopTest();
    }  

    static testMethod void saveAndNewTest() 
    {

        Test.startTest();
        Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);   
        List<Price_Book_Item__c> pliItems = CreatePriceBookItems(5, job.Price_Book__c, 'Labor');

        RecordType officeRecordType = [SELECT Id, Name, DeveloperName FROM RecordType where IsActive=true AND  SobjectType = 'Account' and DeveloperName != 'office' LIMIT 1];
        Account acct = new Account(name='Account123', RecordTypeId = officeRecordType.Id);
        insert acct;

        Contact p1 = new Contact(FirstName='Jane', LastName='Doe', Account = acct);
        insert p1;


        Crew_Planning__c cp = new Crew_Planning__c(Job__c = job.Id, Role_on_Job__c = pliItems.get(0).Id, Crew_Member__c = p1.Id);
        insert cp;

        PageReference page = new PageReference('CrewPlanningEditor');
        page.getParameters().put('id', cp.Id);
        Test.setCurrentPage(page);        
      
        FXEditorController ext = new FXEditorController(new ApexPages.StandardController(cp));      
        PageReference p2 = ext.saveAndNew();   
        Test.stopTest();
    }  

    static testMethod void SeachRoleOnJob()
    {
        Test.startTest();
        Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);   
        List<Price_Book_Item__c> pliItems = CreatePriceBookItems(5, job.Price_Book__c, 'Labor');
        String ns = StringUtility.FXNamespace();

        String searchAttrs = '{"[ns]Role_on_Job__c" : {';
        searchAttrs += '"QueryFilter" : "IsDeleted=false",';
        searchAttrs += '"QueryFields" : "Id,Name,[ns]Catalog_Item_Code__c,[ns]Catalog_Description__c",';
        searchAttrs += '"KeywordSearchFields" : "[ns]Catalog_Description__c,[ns]Catalog_Item_Code__c",';
        searchAttrs += '"OrderBy" : "[ns]Catalog_Item_Code__c"}}';
        searchAttrs = searchAttrs.replace('[ns]', ns);


        PageReference page = new PageReference('FXEditorSearcher');
        page.getParameters().put('originatorId', job.Id);
        page.getParameters().put('subjectType', ns + 'Crew_Planning__c');
        page.getParameters().put('lknm', ns + 'Role_on_Job__c');
        page.getParameters().put('searchAttrs', searchAttrs);


        Test.setCurrentPage(page);      

        FXEditorSearchController ctrl = new FXEditorSearchController();
        ctrl.search();
        Test.stopTest();
    }

    static testMethod void LayoutDescribe_Test()
    {
        String str = '{"editLayoutSections" : [ {"columns" : 2,"heading" : "Information","layoutRows" : [ {"layoutItems" : [ {"editableForNew" : false,';
        str += '"editableForUpdate" : false, "label" : "Audit Log ID", ';
        str += '    "layoutComponents" : [ {';
        str += '  "details" : { "autoNumber" : true,"createable" : false, "custom" : false, "idLookup" : true, "inlineHelpText" : null,"label" : "Audit Log ID",';
        str += '    "name" : "Name",';
        str += '    "nameField" : true,';
        str += '    "namePointing" : false,';
        str += '    "nillable" : false,';
        str += '    "permissionable" : false,    ';        
        str += '    "updateable" : false';
        str += '  },';
        str += '  "displayLines" : 1,';
        str += '  "tabOrder" : 4,';
        str += '  "type" : "Field",';
        str += '  "value" : "Name"';
        str += '} ],';
        str += '"placeholder" : false,';
        str += '"required" : false';
        str += '}, {';
        str += '"editableForNew" : false,';
        str += '"editableForUpdate" : false,';
        str += '"label" : "Owner",';
        str += '"layoutComponents" : [ {';
        str += '  "details" : {';
        str += '  "autoNumber" : false,"byteLength" : 18,"createable" : true,"custom" : false, "defaultValue" : null,';
        str += '    "defaultValueFormula" : null, "idLookup" : false, "inlineHelpText" : null, "label" : "Owner ID","length" : 18,           ';
        str += '    "name" : "OwnerId",  "nameField" : false, "namePointing" : true,  "updateable" : true },';
        str += '  "displayLines" : 1,';
        str += '  "tabOrder" : 6,';
        str += '  "type" : "Field",';
        str += '  "value" : "OwnerId"';
        str += '} ],';
        str += '"placeholder" : false,';
        str += '"required" : false';
        str += '} ],';
        str += '"numItems" : 2';
        str += '}, {';
        str += '"layoutItems" : [ {';
        str += '"editableForNew" : true,';
        str += '"editableForUpdate" : true,';
        str += '"label" : "Event Date",';
        str += '"layoutComponents" : [ {';
        str += '  "details" : {';
        str += '    "autoNumber" : false,';
        str += '    "byteLength" : 0,';
        str += '    "calculated" : false,';
        str += '    "calculatedFormula" : null,';
        str += '    "cascadeDelete" : false,';
        str += '    "caseSensitive" : false,';
        str += '    "controllerName" : null,';
        str += '    "createable" : true,';
        str += '    "custom" : true,';
        str += '    "defaultValue" : null,';
        str += '    "defaultValueFormula" : "NOW()",';
        str += '    "defaultedOnCreate" : true,';
        str += '    "dependentPicklist" : false,';
        str += '    "deprecatedAndHidden" : false,';
        str += '    "digits" : 0,';
        str += '    "displayLocationInDecimal" : false,  ';          
        str += '    "idLookup" : false,';
        str += '    "inlineHelpText" : "Date and time",';
        str += '    "label" : "Event Date",';
        str += '    "length" : 0,';
       
        str += '    "name" : "LF50__Event_Date__c",';
        str += '    "nameField" : false,';
        str += '    "namePointing" : false,';
        str += '    "nillable" : false,';
        str += '    "updateable" : true,';
        str += '    "writeRequiresMasterRead" : false';
        str += '  },';
        str += '  "displayLines" : 1,';
        str += '  "tabOrder" : 5,';
        str += '  "type" : "Field",';
        str += '  "value" : "LF50__Event_Date__c"';
        str += '} ],';
        str += '"placeholder" : false,';
        str += '"required" : true';
        str += '}, {';
        str += '"editableForNew" : false,';
        str += '"editableForUpdate" : false,';
        str += '"label" : "",';
        str += '"layoutComponents" : [ ],';
        str += '"placeholder" : true,';
        str += '"required" : false';
        str += '} ],';
        str += '"numItems" : 2';
        str += '} ],';
        str += '"rows" : 2,';
        str += '"tabOrder" : "TopToBottom",';
        str += '"useCollapsibleSection" : false,';
        str += '"useHeading" : true';
        str += '} ]';
        str += '}';
        String ns = StringUtility.FXNamespace().replace('__', '.');

        LayoutDescribe.RecordTypeLayout rs = (LayoutDescribe.RecordTypeLayout)JSON.deserialize(str, Type.forName(ns + 'LayoutDescribe.RecordTypeLayout'));
        System.debug(rs.editLayoutSections.size());
        System.debug(rs.getFieldInfo().size());


    }

   
    static List<Price_Book_Item__c> CreatePriceBookItems(Integer itemsCount, Id priceBookId, string itemType)
    {
        List<Catalog_Item__c> catalogItems = new List<Catalog_Item__c>();
        for(Integer i=0; i<itemsCount; i++)
        {
            catalogItems.add(new Catalog_Item__c(Name= 'CI' + i , Description__c = 'Test Catalog Item' + i, UOM__c='Gal', Sequence_Number__c=i,  Ticket_Item_Record_Type__c = itemType));
        }
        insert catalogItems;

        List<Price_Book_Item__c> pliItems = new List<Price_Book_Item__c>();
        for(Integer i=0; i<itemsCount; i++)
        {
            pliItems.add(new Price_Book_Item__c(Price_Book__c = priceBookId, Price__c=i+3, Sequence_Number__c =i, Discount_Percent__c=0.123, Default_Quantity__c=1096, Included_Quantity__c=0, Catalog_Item__c=catalogItems.get(i).Id));
        }
        insert pliItems;
        return pliItems;
    }
}