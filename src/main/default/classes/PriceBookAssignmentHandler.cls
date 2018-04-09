public class PriceBookAssignmentHandler
{
	public static void RefreshPriceBookAssignments(Set<Id> contacts)
    {
    	delete [SELECT Id FROM Price_Book_Assignment__c WHERE Contact__c IN :contacts AND Auto_Added__c = true];
    	List<Sync_Configuration__c> syncConfigs =  [SELECT Account__c, Office__c, Segment__c, Contact__c FROM Sync_Configuration__c WHERE IsDeleted=false AND Contact__c IN :contacts AND Contact__r.User__c!=null AND Contact__r.User__r.IsActive=true];
    	List<Price_Book__c> pbs = [SELECT Id, Account__c, Office__c, Segment__c FROM Price_Book__c WHERE Is_Active__c = true];

    	RefreshPriceBookAssignments(syncConfigs, pbs);
	}

	public static void RefreshPriceBookAssignments(List<Price_Book__c> pbs)
    {
    	Set<Id> pbIds = new Map<Id, Price_Book__c>(pbs).keySet();
    	delete [SELECT Id FROM Price_Book_Assignment__c WHERE Price_Book__c IN :pbIds AND Auto_Added__c = true];

    	List<Sync_Configuration__c> syncConfigs = [SELECT Account__c, Office__c, Segment__c, Contact__c FROM Sync_Configuration__c WHERE IsDeleted=false AND Contact__r.User__c!=null AND Contact__r.User__r.IsActive=true];
    	
    	RefreshPriceBookAssignments(syncConfigs, pbs);

    }

    static void RefreshPriceBookAssignments(List<Sync_Configuration__c> syncConfigs, List<Price_Book__c> pbs)
    {
    	Map<string, List<Id>> mapUsers = new Map<string, List<Id>>();
    	for(Sync_Configuration__c sc : syncConfigs)
    	{
    		string key = 'a' + sc.Account__c + 'o' +  sc.Office__c + 's' + sc.Segment__c;

            if(key.toLowerCase() == 'anullonullsnull') continue; // all null for Account__c, Office__c and Segment__c

    		if(!mapUsers.containsKey(key))
    		{
    			mapUsers.put(key, new List<Id>());
    		}
    		mapUsers.get(key).add(sc.Contact__c);
    	}

    	List<Price_Book_Assignment__c> pba = new List<Price_Book_Assignment__c>();

    	for(Price_Book__c p: pbs)
    	{
    		string key = 'a' + p.Account__c + 'o' +  p.Office__c + 's' + p.Segment__c;
    		if(!mapUsers.containsKey(key)) continue;

    		for(Id u : mapUsers.get(key))
    		{
    			pba.add(new Price_Book_Assignment__c(Contact__c = u, Price_Book__c = p.Id, Auto_Added__c = true));
    		}    		
    	}
    	if(!pba.isEmpty()) insert pba;
    }
}