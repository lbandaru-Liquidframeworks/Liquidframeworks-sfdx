@isTest
private class EquipmentPlanningPlaceHolder_Test
{
    @testSetup
    static void Setup()
    {
        List<Catalog_Item__c> catalogItems = new List<Catalog_Item__c>();
        for(Integer i=0; i<100; i++)
        {
            String guidStr = StringUtility.newGuid();
            catalogItems.add(new Catalog_Item__c(Name= 'CI' + guidStr   , Description__c = 'Test Catalog Item' + guidStr , UOM__c='Gal', Sequence_Number__c=i,  Ticket_Item_Record_Type__c = 'Equipment'));
        }
       
        insert catalogItems;       
        
        RecordType officeRecordType = [SELECT Id, Name, DeveloperName FROM RecordType where IsActive=true AND  SobjectType = 'Account' and DeveloperName = 'office'];

        Account office = new Account(Name= 'Office ' + StringUtility.newGuid(), RecordTypeId = officeRecordType.Id);
        insert office;  
        
        String ns = StringUtility.FXNamespace();
        Boolean hasEquipField = Equipment_Planning__c.sObjectType.getDescribe().fields.getMap().containsKey(ns + 'Equipment__c');
        
        List<Equipment__c> equip = new List<Equipment__c>();
        
        for(Integer i=0; i<100; i++)
        {    
            String uniqueStr = StringUtility.newGuid();       
            equip.add(new Equipment__c(Name= 'Equip ' + uniqueStr , Catalog_Item__c = catalogItems.get(i).Id, Unit_Number__c = uniqueStr, Office__c = office.Id));
        } 
        insert equip ;
        
        Job__c j = AlpineTestHelper.CreateJobs(1, true).get(0);
        
        List<Equipment_Planning__c> eps = new List<Equipment_Planning__c>();
        for(Integer i=0; i<100; i++)
        {
            Equipment_Planning__c ep = new Equipment_Planning__c(Planned_Start__c = Datetime.now(), Job__c = j.Id);
            if(hasEquipField)
            {
                ep.put(ns + 'Equipment__c', equip.get(i).Id);
            }
            eps.add(ep);
        } 
        
        insert eps;
    }
    static testmethod void runTest()
    {
        Test.startTest();
        String ns = StringUtility.FXNamespace();
        if(!String.isBlank(ns))
        {
            ns = ns.replace('__', '.');
        }        
         
        FXResult r = FXBatchableLauncher.Run(ns + 'EquipmentPlanningPlaceHolderBatchable');        
        Test.stopTest();
        
        System.assert(r.isSuccess, 'should succeed');
        
    }
}