trigger TriggerContactEnforceUserUnique on Contact (before insert, before update) {

	Set<Id> userIds = new Set<Id>();
	List<Contact> actionItems = new List<Contact>();
	Boolean isInsert = trigger.isInsert;
	
	for(Contact c : trigger.new)
	{
		if(c.User__c!=null)		
		{
			if(isInsert || c.User__c!= trigger.oldMap.get(c.Id).User__c) 
			{
				userIds.add(c.User__c);
				actionItems.add(c);
			}
		}
	}
	if(actionItems.isEmpty()) return;
	List<Contact> contacts = [SELECT Id, User__c, Name, User__r.Name FROM Contact WHERE User__c IN : userIds];
	Map<Id, Contact> userToContact= new Map<Id, Contact>();
	for(Contact c: contacts)
	{
		userToContact.put(c.User__c, c);
	}
	Set<Id> users = userToContact.keySet();
	for(Contact c : actionItems)
	{
		if(users.contains(c.User__c) && userToContact.get(c.User__c).Id!=c.Id)
		{
			Contact other = userToContact.get(c.User__c);
			c.addError('User [' + other.User__r.Name + '] is already associated with Contact [' + other.Name + ']');	
		}
	}
}