@isTest
private class UtilityGetNamespaceFromIdTest
{
   static testMethod void runTest() 
   { 
       string namespace = UtilityGetNamespace.CurrentNamespace();
	   System.assert(namespace=='' || namespace.endsWith('__'));         
   }
   
   static testMethod void runTest2() 
   { 
       string namespace = UtilityGetNamespace.CurrentNamespaceWithoutUnderscores();
	   System.assert(namespace=='' || !namespace.endsWith('__'));  
   }
   
   static testMethod void runTest3() 
   { 
		UtilityGetNamespace util = new UtilityGetNamespace();
		string np = util.getNamespace();
		System.assert(np=='' || np.endsWith('__'));
		
		string npShort = util.getNamespaceWithoutUnderscores();
		System.assert(npShort=='' || !npShort.endsWith('__'));     
   }
}