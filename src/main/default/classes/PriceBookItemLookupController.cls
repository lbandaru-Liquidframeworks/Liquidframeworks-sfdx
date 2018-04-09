public with sharing class PriceBookItemLookupController {
  
  public List<Price_Book_Item__c> results{get;set;} // search results
  public string searchString{get;set;} // search keyword

  public string priceBookId {get;set;}
 
  public PriceBookItemLookupController() 
  {    
    itemTypes = new List<SelectOption>(); 
    string defaultItemType = System.currentPageReference().getParameters().get('defaultItemType');
    if(!string.isBlank(defaultItemType))
    {
      defaultItemType = defaultItemType.toLowerCase();
    }

    Map<String, Schema.SObjectField> fieldMap= Catalog_Item__c.sObjectType.getDescribe().fields.getMap();

    for(string fieldName : fieldMap.keySet())
    {
      if(fieldName.toLowerCase().contains('ticket_item_record_type__c'))
      {
        for (PicklistEntry item : fieldMap.get(fieldName).getDescribe().getPickListValues()) 
        {  
          string entry = item.getLabel();

          itemTypes.add(new SelectOption(entry, entry));
          if(!string.isBlank(defaultItemType) && entry.toLowerCase().contains(defaultItemType))
          {
            selectedItemType = entry;
          }
        }
      }
    }   

    priceBookId = System.currentPageReference().getParameters().get('priceBookId');
    searchString = System.currentPageReference().getParameters().get('lksrch');

    if(!string.isBlank(selectedItemType) && !string.isBlank(priceBookId))
    {
       runSearch();  
    }   
  }
 
  // performs the keyword search
  public PageReference search() {
    runSearch();
    return null;
  }
 
  // prepare the query and issue the search command
  private void runSearch() {
    // TODO prepare query string for complex serarches & prevent injections
    results = performSearch(searchString);    
           
  } 
 
  // run the search and return the records found. 
  private List<Price_Book_Item__c> performSearch(string searchString) {
    return performSearch(priceBookId, selectedItemType, searchString);   
  }


   public List<Price_Book_Item__c> performSearch(string pbId, string itemType, string searchString) {

    if(string.isBlank(searchString))
    {
       return [SELECT Id, Name, Catalog_Item_Code__c, Catalog_Description__c, Breadcrumb__c FROM Price_Book_Item__c WHERE Price_Book__c =:pbId AND Ticket_Item_Record_Type__c =:itemType ORDER BY Name]; 
    }
    string keywordStr =  '%' + searchString +'%';
    return [SELECT Id, Name, Catalog_Item_Code__c, Catalog_Description__c, Breadcrumb__c FROM Price_Book_Item__c WHERE Price_Book__c =:pbId AND Ticket_Item_Record_Type__c =:itemType AND (Name LIKE :keywordStr OR Catalog_Item_Code__c LIKE :keywordStr OR Catalog_Description__c LIKE :keywordStr) ORDER BY Name]; 
  }

  
 
  // used by the visualforce page to send the link to the right dom element
  public string getFormTag() {
    return System.currentPageReference().getParameters().get('frm');
  }
 
  // used by the visualforce page to send the link to the right dom element for the text box
  public string getTextBox() {
    return System.currentPageReference().getParameters().get('txt');
  }
  
  public List<SelectOption> itemTypes {get; private set; }
  public string selectedItemType {get;set;}
}