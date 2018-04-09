@isTest
public class ItemBuilderHelper_Test
{
    static testmethod void Initialize_Test() {
    }

    static testmethod void getKeyPrefixForObject1_test() {
      Test.StartTest();

      String ns = UtilityGetNamespace.CurrentNamespace();
      String objStr = 'Job__c';
      Schema.SObjectType objType = Schema.getGlobalDescribe().get(ns+objStr);
      String keyPrefix = objType.getDescribe().keyPrefix;

      String result = ItemBuilderHelper.getKeyPrefixForObject(objType);

      Test.StopTest();

      System.assertEquals(keyPrefix, result);
    }

    static testmethod void getKeyPrefixForObject2_test() {
      Test.StartTest();

      String ns = UtilityGetNamespace.CurrentNamespace();
      String objStr = 'Job__c';
      Schema.SObjectType objType = Schema.getGlobalDescribe().get(ns+objStr);
      String keyPrefix = objType.getDescribe().keyPrefix;

      Map<String,String> result = ItemBuilderHelper.getKeyPrefixForObject(objStr);

      Test.StopTest();

      System.assertEquals(keyPrefix, result.get(objStr));
    }

    static testmethod void getKeyPrefixesForObjects_test() {
      Test.StartTest();

      String ns = UtilityGetNamespace.CurrentNamespace();
      String objStr = 'Job__c';
      Schema.SObjectType objType = Schema.getGlobalDescribe().get(ns+objStr);
      String keyPrefix = objType.getDescribe().keyPrefix;

      Map<String,String> result = ItemBuilderHelper.getKeyPrefixesForObjects();

      Test.StopTest();

      System.assertEquals(keyPrefix, result.get(objStr));
    }

    static testmethod void ProcessSearchFieldSet_test() {
    }

    static testmethod void GetFilterSoql_test() {

    }
}
