@isTest
private class ManagedPackageHelpersTest{

	static testmethod void GetCleanTypeName(){
		string typeName = ManagedPackageHelpers.CleanTypeName('job__c').toLowerCase();		
		system.assert(typeName.contains('job')); 
		string ns = UtilityGetNamespace.CurrentNamespace();
		if(ns != '') system.assert(typeName.contains(ns.toLowerCase())); 
		system.assertEquals(ManagedPackageHelpers.CleanTypeName('BogusType'), null);
		
	}
	
	static testmethod void GetCleanFieldName(){
		system.assertEquals(ManagedPackageHelpers.CleanFieldName('BogusType', 'tracking_number__c'), null);
		system.assertEquals(ManagedPackageHelpers.CleanFieldName('job__c', 'bogusField'), null);
		
		string result = ManagedPackageHelpers.CleanFieldName('job__c', 'tracking_number__c').toLowerCase();
		system.assert(result.contains('tracking_number__c')); 
		string ns = UtilityGetNamespace.CurrentNamespace();
		if(ns != '') system.assert(result.contains(ns.toLowerCase())); 
	}
	
	static testmethod void GetCleanFieldList(){
		string result = ManagedPackageHelpers.CleanFieldList('job__c', 'tracking_number__c,syncid__c').toLowerCase();
		string ns = UtilityGetNamespace.CurrentNamespace();
		if(ns==null) ns = '';
		ns = ns.toLowerCase();
		system.assertEquals(result, ns+'tracking_number__c' + ',' + ns + 'syncid__c');	
	}	
	
	static testmethod void GetCleanRelationship(){
		system.assertEquals(ManagedPackageHelpers.CleanRelationship('BogusType', 'Tickets__r'), null);
		system.assertEquals(ManagedPackageHelpers.CleanRelationship('job__c', 'bogusRelationship'), null);
		string result = ManagedPackageHelpers.CleanRelationship('job__c', 'Tickets__r').toLowerCase();
		string ns = UtilityGetNamespace.CurrentNamespace();
		if(ns==null) ns = '';
		ns = ns.toLowerCase();		
		system.assertEquals(result, ns+'tickets__r');
	}

}