@isTest
private class FXTriggerHandler_Test
{
    static testmethod void InsertTest()
    {
        AlpineTestHelper.CreateEquipment(true);
    }
    
    static testmethod void UpdateTest()
    {
        Equipment__c equip = AlpineTestHelper.CreateEquipment(true);
        equip.Serial_Number__c = StringUtility.newGuid();
        update equip ;
    }
    
    static testmethod void DeleteTest()
    {
        Equipment__c equip = AlpineTestHelper.CreateEquipment(true);
        delete equip;
    }    
}