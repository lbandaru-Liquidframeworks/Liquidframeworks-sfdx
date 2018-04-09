public class CreditMemoItemHandler_Add
{
  static String pricebookItemKeyPrefix = Price_Book_Item__c.sObjectType.getDescribe().keyPrefix;
  static String invoiceItemKeyPrefix = Invoice_Item__c.sObjectType.getDescribe().keyPrefix;

  public static String CreateCreditMemoItems(String processStr) {
      JSONParser parser = JSON.createParser(processStr);
      Type resultType = Type.forName('CreditMemoItemHandler_Add.CreateCreditMemoItemsRequest');
      CreditMemoItemHandler_Add.CreateCreditMemoItemsRequest readValueAsResults = (CreditMemoItemHandler_Add.CreateCreditMemoItemsRequest)parser.readValueAs(resultType);

      List<Credit_Memo_Item__c> result = CreateCreditMemoItems(readValueAsResults);

      return JSON.serializePretty(result, false);
  }

  public static List<Credit_Memo_Item__c> CreateCreditMemoItems(CreateCreditMemoItemsRequest request)
  {
      Id cmId = request.cmId;
      List<Id> sourceIds = request.sourceIds;
      Decimal nextSeqNumber = request.nextSeqNumber;
      String parentCreditMemoItemId = request.parentCreditMemoItemId;

      if(sourceIds.isEmpty()) return null;
      Schema.DescribeSObjectResult CreditMemoItem = Credit_Memo_Item__c.sObjectType.getDescribe();
      if(!CreditMemoItem.isAccessible() || !CreditMemoItem.isCreateable()) {
          return null;
      }

      List<Credit_Memo__c> creditMemos = [SELECT Id, Price_Book__c FROM Credit_Memo__c WHERE Id=:cmId AND Price_Book__c!=NULL LIMIT 1];
      Price_Book__c pricebook = null;
      if (creditMemos.size() > 0) {
        pricebook = [SELECT Id, AddTktItemsByPBSeqNum__c FROM Price_Book__c WHERE Id=:creditMemos[0].Price_Book__c ];
      }

      String itemId = sourceIds.get(0);
      List<Credit_Memo_Item__c> newItems = null;
      List<Credit_Memo_Item__c> rootItems = null;

      try
      {
        if(itemId.startsWith(pricebookItemKeyPrefix)) {
            List<Price_Book_Item__c> parentPBItems = [SELECT Id FROM Price_Book_Item__c WHERE Id IN :sourceIds AND Parent_Price_Book_Item__c = null ];
            Map<Id, Price_Book_Item__c> parentPBItemsMap = new Map<Id, Price_Book_Item__c>(parentPBItems);

            List<Price_Book_Item__c> sourcePBItems = [SELECT Id FROM Price_Book_Item__c WHERE Id IN :sourceIds];
            Map<Id, Price_Book_Item__c> sourcePBItemsMap = new Map<Id, Price_Book_Item__c>(sourcePBItems);
            List<Id> sourcePBItemIds = new List<Id>();
            for(Id sourceId :  sourceIds) {
              if(sourcePBItemsMap.containsKey(sourceId)) {
                sourcePBItemIds.add(sourceId);
              }
            }

            rootItems =  CreateCreditMemoItemWithPBItem(cmId, sourcePBItemIds, null, parentCreditMemoItemId);
            insert rootItems;

            Map<Id, Credit_Memo_Item__c> cmItemToParentPBItemMap = new Map<Id, Credit_Memo_Item__c>();
            for(Credit_Memo_Item__c cmi : [SELECT Id, Price_Book_Item__c, Parent_Credit_Memo_Item__c FROM Credit_Memo_Item__c WHERE Id IN :rootItems AND Price_Book_Item__r.Parent_Price_Book_Item__c = null]) {
              if (!cmItemToParentPBItemMap.containsKey(cmi.Price_Book_Item__c)) {
                cmItemToParentPBItemMap.put(cmi.Price_Book_Item__c, cmi);
              }
            }

            List<Credit_Memo_Item__c> cmItemsToUpdate = new List<Credit_Memo_Item__c>();
            for(Credit_Memo_Item__c cmi : [SELECT Id, Parent_Credit_Memo_Item__c, Price_Book_Item__r.Parent_Price_Book_Item__c FROM Credit_Memo_Item__c WHERE Id IN :rootItems AND Price_Book_Item__r.Parent_Price_Book_Item__c != null]) {
              if (parentPBItemsMap.containsKey(cmi.Price_Book_Item__r.Parent_Price_Book_Item__c)) {
                if (cmItemToParentPBItemMap.containsKey(cmi.Price_Book_Item__r.Parent_Price_Book_Item__c)) {
                  Credit_Memo_Item__c parentcmi = cmItemToParentPBItemMap.get(cmi.Price_Book_Item__r.Parent_Price_Book_Item__c);
                  cmi.Parent_Credit_Memo_Item__c = parentcmi.Id;

                  cmItemsToUpdate.add(cmi);
                }
              }
            }

            update cmItemsToUpdate;
        } else if(itemId.startsWith(invoiceItemKeyPrefix)) {
            List<Invoice_Item__c> parentInvItems = [SELECT Id FROM Invoice_Item__c WHERE Id IN :sourceIds AND Parent_Invoice_Item__c = null ];
            Map<Id, Invoice_Item__c> parentInvItemsMap = new Map<Id, Invoice_Item__c>(parentInvItems);

            List<Invoice_Item__c> sourceInvItems = [SELECT Id FROM Invoice_Item__c WHERE Id IN :sourceIds];
            Map<Id, Invoice_Item__c> sourceInvItemsMap = new Map<Id, Invoice_Item__c>(sourceInvItems);
            List<Id> sourceInvItemIds = new List<Id>();
            for(Id sourceId :  sourceIds) {
              if(sourceInvItemsMap.containsKey(sourceId)) {
                sourceInvItemIds.add(sourceId);
              }
            }

            rootItems =  CreateCreditMemoItemWithInvItem(cmId, sourceInvItemIds, null, parentCreditMemoItemId);
            insert rootItems;

            Map<Id, Credit_Memo_Item__c> cmItemToParentInvItemMap = new Map<Id, Credit_Memo_Item__c>();
            for(Credit_Memo_Item__c cmi : [SELECT Id, Invoice_Item__c, Parent_Credit_Memo_Item__c FROM Credit_Memo_Item__c WHERE Id IN :rootItems AND Invoice_Item__r.Parent_Invoice_Item__c = null]) {
              if (!cmItemToParentInvItemMap.containsKey(cmi.Invoice_Item__c)) {
                cmItemToParentInvItemMap.put(cmi.Invoice_Item__c, cmi);
              }
            }

            List<Credit_Memo_Item__c> cmItemsToUpdate = new List<Credit_Memo_Item__c>();
            for(Credit_Memo_Item__c cmi : [SELECT Id, Parent_Credit_Memo_Item__c, Invoice_Item__r.Parent_Invoice_Item__c FROM Credit_Memo_Item__c WHERE Id IN :rootItems AND Invoice_Item__r.Parent_Invoice_Item__c != null]) {
              if (parentInvItemsMap.containsKey(cmi.Invoice_Item__r.Parent_Invoice_Item__c)) {
                if (cmItemToParentInvItemMap.containsKey(cmi.Invoice_Item__r.Parent_Invoice_Item__c)) {
                  Credit_Memo_Item__c parentcmi = cmItemToParentInvItemMap.get(cmi.Invoice_Item__r.Parent_Invoice_Item__c);
                  cmi.Parent_Credit_Memo_Item__c = parentcmi.Id;

                  cmItemsToUpdate.add(cmi);
                }
              }
            }

            update cmItemsToUpdate;

        }

        if(rootItems == null || rootItems.isEmpty()) return null;

        if (pricebook==null || !pricebook.AddTktItemsByPBSeqNum__c) {
          ApplySequenceNumber(rootItems, nextSeqNumber);
          update rootItems;
        }

        Map<Id, Credit_Memo_Item__c> newItemsMap = new Map<Id, Credit_Memo_Item__c>(rootItems);
        Set<Id> cmItemIds = newItemsMap.keySet();

        List<String> fields = new List<String>(Schema.sObjectType.Credit_Memo_Item__c.fields.getMap().keySet());
        String fieldsStr = String.join(fields, ',');

        String ns = StringUtility.FXNamespace();
        String cmiSoql = String.format('SELECT {0} FROM {1} WHERE Id IN :cmItemIds', new String[]{fieldsStr, ns+'Credit_Memo_Item__c'});
        List<Credit_Memo_Item__c> cmItems = (List<Credit_Memo_Item__c>)Database.query(cmiSoql);

        return cmItems;
      }
      catch (Exception ex)
      {
          throw ex;
      }
      finally
      {
          //RuleEngineCore.RuleEngineInProgress = flagValue;
      }
  }

  static List<Credit_Memo_Item__c> CreateCreditMemoItemWithPBItem(Id cmId, List<Id> sourceItemIds, List<Credit_Memo_Item__c> parentCMItems, String parentCreditMemoItemId)
  {
      List<Credit_Memo_Item__c> newItems = new List<Credit_Memo_Item__c>();
      //for setting up CreditMemoItem parent/child relationship with PBItem parent/child info
      Map<Id, Credit_Memo_Item__c> pbItemToCMItemLookup = new Map<Id, Credit_Memo_Item__c>();
      if(parentCMItems != null) {
        for(Credit_Memo_Item__c parentCMItem: parentCMItems) {
          pbItemToCMItemLookup.put(parentCMItem.Price_Book_Item__c, parentCMItem);
        }
      }

      String ns = UtilityGetNamespace.CurrentNamespace();

      Map<String, Id> rtLookup = GetCreditMemoItemRecordTypeLookup();

      Set<String> pbItemFields = Price_Book_Item__c.sObjectType.getDescribe().fields.getMap().keySet();
      Set<String> pbItemQueryFields = new Set<String>();
      pbItemQueryFields.addAll(pbItemFields);
      pbItemQueryFields.add('RecordType.DeveloperName');
      pbItemQueryFields.add('RecordType.Name');

      String soql = String.format('SELECT {1} FROM {0}Price_Book_Item__c WHERE IsDeleted=false AND (Id IN :sourceItemIds OR {0}Parent_Price_Book_Item__c IN :sourceItemIds) ORDER BY {0}Parent_Price_Book_Item__c NULLS FIRST',
          new String[]{ns, String.join(new List<String>(pbItemQueryFields), ',')});

      List<Price_Book_Item__c> sources = (List<Price_Book_Item__c>)Database.query(soql);
      Map<Id, Price_Book_Item__c> sourcesLookup = new Map<Id, Price_Book_Item__c>(sources);

      Map<String, String> cmItemToPBItemFieldMapping =  GetCreditMemoItemToPBItemFieldMapping(ns.toLowercase(), pbItemFields);

      SobjectType cmItemType = Credit_Memo_Item__c.SobjectType;

      for(Id sourceItemId: sourceItemIds)
      {
          Price_Book_Item__c obj = sourcesLookup.get(sourceItemId);
          Id cmiRecordType = rtLookup.containsKey(obj.RecordType.DeveloperName)? rtLookup.get(obj.RecordType.DeveloperName) : null;
          Credit_Memo_Item__c cmi = (Credit_Memo_Item__c)cmItemType.newSObject(cmiRecordType, true);
          for(String f: cmItemToPBItemFieldMapping.keySet())
          {
              cmi.put(f, obj.get(cmItemToPBItemFieldMapping.get(f)));
          }
          cmi.Credit_Memo__c = cmId;
          cmi.Price_Book_Item__c = obj.Id;
          cmi.Sequence_Number__c = obj.Sequence_Number__c;

          //field name exceptions
          if(String.IsEmpty(obj.Description_Override__c)) {
            if(!String.IsEmpty(obj.Catalog_Description__c)) {
              cmi.Description__c = obj.Catalog_Description__c;
            }
          } else {
            cmi.Description__c = obj.Description_Override__c;
          }
          if(!String.IsEmpty(obj.Catalog_Item_Code__c)) {
            cmi.Item_Code__c = obj.Catalog_Item_Code__c;
          }
          cmi.Qty__c = obj.Default_Quantity__c;

          if (!String.IsEmpty(parentCreditMemoItemId)) {
            cmi.Parent_Credit_Memo_Item__c = parentCreditMemoItemId;
          } else if (pbItemToCMItemLookup.containsKey(obj.Parent_Price_Book_Item__c)) {
            cmi.Parent_Credit_Memo_Item__c = pbItemToCMItemLookup.get(obj.Parent_Price_Book_Item__c).Id;
          }
          newItems.add(cmi);
      }
      return newItems;
  }

  static Map<String, String> GetCreditMemoItemToPBItemFieldMapping(String nsLowercase, Set<String> pbItemFields)
  {
      Map<String, String> cmiToPBIFieldMapping = new Map<String, String>();
      Boolean isInDev = String.isBlank(nsLowercase);

      for(Schema.SObjectField f: Schema.sObjectType.Credit_Memo_Item__c.fields.getMap().values())
      {
          Schema.DescribeFieldResult fd = f.getDescribe();

          if (!fd.isCustom() || !fd.isAccessible() || !fd.isCreateable() || fd.isCalculated() || fd.isAutoNumber())
          {
              continue;
          }
          String cmiFieldName = fd.getName().toLowercase();
          if(pbItemFields.contains(cmiFieldName))
          {
              cmiToPBIFieldMapping.put(cmiFieldName, cmiFieldName);
          }
          else if(!isInDev)
          {
              String pbiField = '';
              if(cmiFieldName.startsWith(nsLowercase))
              {
                  pbiField = cmiFieldName.replace(nsLowercase, '');
              }
              else
              {
                  pbiField = nsLowercase + cmiFieldName;
              }
              if(pbItemFields.contains(pbiField))
              {
                  cmiToPBIFieldMapping.put(cmiFieldName, pbiField);
              }
          }
      }
      return cmiToPBIFieldMapping;
  }

  static List<Credit_Memo_Item__c> CreateCreditMemoItemWithInvItem(Id cmId, List<Id> sourceItemIds, List<Credit_Memo_Item__c> parentCMItems, String parentCreditMemoItemId)
  {
      List<Credit_Memo_Item__c> newItems = new List<Credit_Memo_Item__c>();
      //for setting up CreditMemoItem parent/child relationship with InvItem parent/child info
      Map<Id, Credit_Memo_Item__c> invItemToCMItemLookup = new Map<Id, Credit_Memo_Item__c>();
      if(parentCMItems != null) {
        for(Credit_Memo_Item__c parentCMItem: parentCMItems) {
          invItemToCMItemLookup.put(parentCMItem.Invoice_Item__c, parentCMItem);
        }
      }

      String ns = UtilityGetNamespace.CurrentNamespace();

      Map<String, Id> rtLookup = GetCreditMemoItemRecordTypeLookup();

      Set<String> invItemFields = Invoice_Item__c.sObjectType.getDescribe().fields.getMap().keySet();
      Set<String> invItemQueryFields = new Set<String>();
      invItemQueryFields.addAll(invItemFields);

      String soql = String.format('SELECT {1} FROM {0}Invoice_Item__c WHERE IsDeleted=false AND (Id IN :sourceItemIds OR {0}Parent_Invoice_Item__c IN :sourceItemIds) ORDER BY {0}Parent_Invoice_Item__c NULLS FIRST',
          new String[]{ns, String.join(new List<String>(invItemQueryFields), ',')});

      List<Invoice_Item__c> sources = (List<Invoice_Item__c>)Database.query(soql);
      Map<Id, Invoice_Item__c> sourcesLookup = new Map<Id, Invoice_Item__c>(sources);

      Map<String, String> cmItemToInvItemFieldMapping =  GetCreditMemoItemToInvItemFieldMapping(ns.toLowercase(), invItemFields);

      SobjectType cmItemType = Credit_Memo_Item__c.SobjectType;

      for(Id sourceItemId: sourceItemIds)
      {
          Invoice_Item__c obj = sourcesLookup.get(sourceItemId);
          Credit_Memo_Item__c cmi = (Credit_Memo_Item__c)cmItemType.newSObject();
          for(String f: cmItemToInvItemFieldMapping.keySet())
          {
              cmi.put(f, obj.get(cmItemToInvItemFieldMapping.get(f)));
          }
          cmi.Credit_Memo__c = cmId;
          cmi.Invoice_Item__c = obj.Id;
          cmi.Sequence_Number__c = obj.Sequence_Number__c;

System.debug('objparent'+obj.Parent_Invoice_Item__c);
System.debug('objparent'+invItemToCMItemLookup.containsKey(obj.Parent_Invoice_Item__c));
          if (!String.IsEmpty(parentCreditMemoItemId)) {
            cmi.Parent_Credit_Memo_Item__c = parentCreditMemoItemId;
          } else if (invItemToCMItemLookup.containsKey(obj.Parent_Invoice_Item__c)) {
            cmi.Parent_Credit_Memo_Item__c = invItemToCMItemLookup.get(obj.Parent_Invoice_Item__c).Id;
          }
System.debug('objparent'+cmi.Parent_Credit_Memo_Item__c);
          newItems.add(cmi);
      }
      return newItems;
  }

  static Map<String, String> GetCreditMemoItemToInvItemFieldMapping(String nsLowercase, Set<String> invItemFields)
  {
      Map<String, String> cmiToInvItemFieldMapping = new Map<String, String>();
      Boolean isInDev = String.isBlank(nsLowercase);

      for(Schema.SObjectField f: Schema.sObjectType.Credit_Memo_Item__c.fields.getMap().values())
      {
          Schema.DescribeFieldResult fd = f.getDescribe();

          if (!fd.isCustom() || !fd.isAccessible() || !fd.isCreateable() || fd.isCalculated() || fd.isAutoNumber())
          {
              continue;
          }
          String cmiFieldName = fd.getName().toLowercase();
          if(invItemFields.contains(cmiFieldName))
          {
              cmiToInvItemFieldMapping.put(cmiFieldName, cmiFieldName);
          }
          else if(!isInDev)
          {
              String invItemField = '';
              if(cmiFieldName.startsWith(nsLowercase))
              {
                  invItemField = cmiFieldName.replace(nsLowercase, '');
              }
              else
              {
                  invItemField = nsLowercase + cmiFieldName;
              }
              if(invItemFields.contains(invItemField))
              {
                  cmiToInvItemFieldMapping.put(cmiFieldName, invItemField);
              }
          }
      }
      return cmiToInvItemFieldMapping;
  }

  public static void ApplySequenceNumber(List<Credit_Memo_Item__c> parentItems, Decimal nextSeqNumber)
  {
      if(nextSeqNumber == null || nextSeqNumber<0) return;

      for(Credit_Memo_Item__c parentItem : parentItems)
      {
          parentItem.Sequence_Number__c = nextSeqNumber;
          nextSeqNumber++;
      }
  }

  public static Map<String, Id> GetCreditMemoItemRecordTypeLookup()
  {
      String ns = StringUtility.FXNamespace();
      String cmItemFullName = ns + 'Credit_Memo_Item__c';
      Map<String, Id> rtLookup = new Map<String, Id>();
      for(RecordType rt : [SELECT Id, Name, DeveloperName FROM RecordType WHERE IsActive=true AND SobjectType = :cmItemFullName])
      {
          rtLookup.put(rt.Name, rt.Id);
          rtLookup.put(rt.DeveloperName, rt.Id);
      }
      return rtLookup;
  }

  public class CreateCreditMemoItemsRequest {
    public Id cmId;
    public List<Id> sourceIds;
    public Decimal nextSeqNumber;
    public String parentCreditMemoItemId;
  }
}
