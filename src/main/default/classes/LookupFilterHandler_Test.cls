@isTest
private class LookupFilterHandler_Test
{
    static void SetupData()
    {
        String contents = 'window.FX_Mobile_Filters = {' + 
               '"Account": {       ' +
               '"Job__c.CustomerAccount__c": {' +
               '    "predicate": "Account.RecordType.DeveloperName != \'Office\' && (ISNULL($Source.Price_Book__c) || ISNULL($Source.Price_Book__r.Account__c) || $Source.Price_Book__r.Account__c==Account.Id)",' +
               '    "sortFormula": {' +
               '        "formula": "Account.Name",' +
               '        "limit": "10",' +
               '        "sort": "asc"' +
               '    }' +
               '}}}';
        
        StaticResourceHandler.UpsertFile('FX_Mobile_Filters', contents); 
        CustomObjectInfo__c objInfo = new CustomObjectInfo__c();
        objInfo.DeveloperName__c = 'Job__c';
        objInfo.EntityDefinitionId__c = '01I36000001VBPgEAO';
        insert objInfo;

        CustomFieldInfo__c fInfo = new CustomFieldInfo__c(CustomObjectInfo__c = objInfo.Id, 
            FullName__c = 'Job__c.TestField__c',
            DeveloperName__c ='TestField__c',
            FieldDefinitionId__c ='00N3600000E0xm1EAB');
        insert fInfo;


    }

    static testmethod void RunTest()
    {
        SetupData();
        Test.startTest();
        
        List<StaticResource> items = [SELECT Id, Body FROM StaticResource WHERE Name='FX_Mobile_Filters'];
        LookupFilterHandler.Run();
        Test.stopTest();
    }

    static testmethod void BatchTest()
    {
        SetupData();
        Test.startTest();
        Database.executeBatch(new LookupFilterHandler());
        Test.stopTest();
    }

    static testmethod void BatchTest2()
    {
        SetupData();
        Test.startTest();
        Database.executeBatch(new LookupFilterHandler(UserInfo.getSessionID()));
        Test.stopTest();
    }


    static testmethod void BatchTest3()
    {
        SetupData();
        Test.startTest();
        List<LookupFilterHandler.LookupFilterRecord> filters = new List<LookupFilterHandler.LookupFilterRecord>();

        Database.executeBatch(new LookupFilterHandler(UserInfo.getSessionID(), filters,
             LookupFilterHandler.GetLookupFieldDefinitionIds()));
        Test.stopTest();
    }


    static testmethod void BatchTest4()
    {
        SetupData();
        Test.startTest();

        Database.executeBatch(new LookupFilterHandler(UserInfo.getSessionID(), 
             LookupFilterHandler.GetLookupFieldDefinitionIds()));
        Test.stopTest();
    }


    static testmethod void SchedulerTest()
    {
        SetupData();
        Test.startTest();
        String ns = StringUtility.FXNamespace().replace('__', '.');
        FXScheduleDispatcher.ScheduleJobNow( ns+ 'LookupFilterHandler');
        Test.stopTest();
    }


    static testmethod void FXWorkerLauncherTest()
    {
        SetupData();
        Test.startTest();
        String ns = StringUtility.FXNamespace().replace('__', '.');
        FXWorkerLauncher.DoWork(ns + 'LookupFilterHandler', null);
        Test.stopTest();
    }
    
    static testmethod void CodeCoverage()
    {
        SetupData();
        Test.startTest();
        LookupFilterHandler.RefreshLookupFilters();
        LookupFilterHandler h = new LookupFilterHandler();
        h.DoWork(null);
        Test.stopTest();
    }


    static testmethod void PredidateTest()
    {
        String rawStr = '{'
  + '"size" : 1,'
  + '"totalSize" : 1,'
  + '"done" : true,'
  + '"queryLocator" : null,'
  + '"entityTypeName" : "CustomField",'
  + '"records" : [ {'
  + '  "attributes" : {'
  + '    "type" : "CustomField",'
  + '    "url" : "/services/data/v31.0/tooling/sobjects/CustomField/00N4A00000FcsKTUAZ"'
  + '  },'
  + '  "Id" : "00N4A00000FcsKTUAZ",'
  + '  "TableEnumOrId" : "01IG0000002ELX4MAO",'
  + '  "DeveloperName" : "FilterTest",'
  + '  "FullName" : "FX5__Crew_Planning__c.FilterTest__c",'
  + '  "Metadata" : {'
  + '    "caseSensitive" : null,'
  + '    "customDataType" : null,'
  + '    "defaultValue" : null,'
  + '    "deleteConstraint" : "SetNull",'
  + '    "deprecated" : null,'
  + '    "description" : null,'
  + '    "displayFormat" : null,'
  + '    "displayLocationInDecimal" : null,'
  + '    "encrypted" : null,'
  + '    "escapeMarkup" : null,'
  + '    "externalDeveloperName" : null,'
  + '    "externalId" : false,'
  + '    "formula" : null,'
  + '    "formulaTreatBlanksAs" : null,'
  + '    "inlineHelpText" : null,'
  + '    "isFilteringDisabled" : null,'
  + '    "isNameField" : null,'
  + '    "isSortingDisabled" : null,'
  + '    "label" : "Price Book Item",'
  + '    "length" : null,'
  + '    "lookupFilter" : {'
  + '      "booleanFilter" : "(1 AND 2 AND 3 AND 4) OR 5",'
  + '      "filterItems" : [ {'
  + '        "field" : "FX5__Price_Book_Item__c.FX5__Price__c",'
  + '        "operation" : "greaterThan",'
  + '        "value" : "1956",'
  + '        "valueField" : null'
  + '      }, {'
  + '        "field" : "FX5__Price_Book_Item__c.Max_Temp__c",'
  + '        "operation" : "greaterOrEqual",'
  + '        "value" : "25.3",'
  + '        "valueField" : null'
  + '      }, {'
  + '        "field" : "FX5__Price_Book_Item__c.FX5__Catalog_Description__c",'
  + '        "operation" : "notContain",'
  + '        "value" : "Equipment",'
  + '        "valueField" : null'
  + '      }, {'
  + '        "field" : "FX5__Price_Book_Item__c.FX5__Catalog_Cost__c",'
  + '        "operation" : "notEqual",'
  + '        "value" : "0",'
  + '        "valueField" : null'
  + '      }, {'
  + '        "field" : "FX5__Price_Book_Item__c.FX5__Catalog_UOM__c",'
  + '        "operation" : "notEqual",'
  + '        "value" : "EA",'
  + '        "valueField" : null'
  + '      } ],'
  + '      "active" : true,'
  + '      "description" : null,'
  + '      "errorMessage" : null,'
  + '      "infoMessage" : null,'
  + '      "isOptional" : false'
  + '    },'
  + '    "maskChar" : null,'
  + '    "maskType" : null,'
  + '    "picklist" : null,'
  + '    "populateExistingRows" : null,'
  + '    "precision" : null,'
  + '    "readOnlyProxy" : null,'
  + '    "referenceTargetField" : null,'
  + '    "referenceTo" : "FX5__Price_Book_Item__c",'
  + '    "relationshipLabel" : "Crew Planning (Price Book Item)",'
  + '    "relationshipName" : "Crew_Planning",'
  + '    "relationshipOrder" : null,'
  + '    "reparentableMasterDetail" : null,'
  + '    "required" : false,'
  + '    "restrictedAdminField" : null,'
  + '    "scale" : null,'
  + '    "startingNumber" : null,'
  + '    "stripMarkup" : null,'
  + '    "summarizedField" : null,'
  + '    "summaryFilterItems" : null,'
  + '    "summaryForeignKey" : null,'
  + '    "summaryOperation" : null,'
  + '    "trackFeedHistory" : null,'
  + '    "trackHistory" : false,'
  + '    "trackTrending" : false,'
  + '    "type" : "Lookup",'
  + '    "unique" : null,'
  + '    "urls" : null,'
  + '    "visibleLines" : null,'
  + '    "writeRequiresMasterRead" : null'
  + '  }'
  + '} ]'
  + '}';
        Test.startTest();
        
        LookupFilterHandler.LookupFilterRawResponse result = (LookupFilterHandler.LookupFilterRawResponse)JSON.deserialize(rawStr, 
                        LookupFilterHandler.LookupFilterRawResponse.class);

        System.assert(result.HasActiveFilter(), 'should have active filter');

        LookupFilterHandler.LookupFilterRecord filter =  result.LookupFilter;
        String predicate = filter.predicate;
        System.debug(predicate);

        Test.stopTest();
    }
}