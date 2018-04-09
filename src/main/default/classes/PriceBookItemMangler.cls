public class PriceBookItemMangler
{
    public static void OnBeforeInsert(List<Price_Book_Item__c> items)
    {
        Initialize(items);
    }   

    public static void Initialize(List<Price_Book_Item__c> items)
    {
        SetupPriceBookItems(items);
    }

    public static void SetupPriceBookItems(List<Price_Book_Item__c> itemsToProcess)
    {
        Boolean hasCurrencyIso = false;
        for(String f: Schema.sObjectType.Price_Book_Item__c.fields.getMap().keySet())
        {
            if (f.toLowerCase() == 'currencyisocode') {
                hasCurrencyIso = true;
                break;
            }
        }
        
        if (!hasCurrencyIso) {
            return;
        }

        Set<Id> pbIds = new Set<Id>();
        for(Price_Book_Item__c pbi : itemsToProcess)
        {
            pbIds.add(pbi.Price_Book__c);
        }

        String ns = UtilityGetNamespace.CurrentNamespace();

        String soql = 'SELECT CurrencyIsoCode FROM ' + ns + 'Price_Book__c WHERE Id IN :pbIds';
        
        List<Price_Book__c> pbObjs = new List<Price_Book__c>();
        for(sObject o : Database.query(soql))
        {
            pbObjs.add((Price_Book__c)o);
        }
        
        Map<Id, Price_Book__c> plMap = new Map<Id, Price_Book__c>(pbObjs);
        
        for(Price_Book_Item__c pbi : itemsToProcess)
        {     
            Price_Book__c pb = plMap.get(pbi.Price_Book__c);  
            
            pbi.put('CurrencyIsoCode', pb.get('CurrencyIsoCode'));
        }      
        
    }   

    public static void OnBeforeDelete(List<Price_Book_Item__c> itemsToProcess) {
        Database.delete([SELECT Id FROM Price_Book_Item__c WHERE Parent_Price_Book_Item__c IN :itemsToProcess AND Id NOT IN :itemsToProcess]);
    }
}