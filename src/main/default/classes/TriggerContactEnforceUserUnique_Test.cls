@isTest
private class TriggerContactEnforceUserUnique_Test {
    
    static testmethod void RunTest()
    {
    	User u = [SELECT Id, Name FROM User LIMIT 1];
    	List<Contact> contacts = [SELECT Id, User__c FROM Contact WHERE User__c =:u.Id ];
    	if(contacts.size()==0)
    	{
    		Contact newContact = AlpineTestHelper.CreateUser('Doe', 'Jane', false);
    		newContact.User__c = u.Id;    	
    		insert newContact;	
    	}
    	
    	Contact newContact2 = AlpineTestHelper.CreateUser('Doe', 'Joe', false);
    	newContact2.User__c = u.Id;
    	Boolean pass = false;
    	try
    	{
	    	insert newContact2;   
    	}
    	catch(System.DmlException ex)
    	{	
    		pass = true;
    	}

	    System.assert(pass);
    }
}