public class InventoryManager
{   
    public static void OnTicketItemAfterInsert(List<Ticket_Item__c> items)
    {          
        if(FX_Settings__c.getOrgDefaults().EnableInventoryTracking__c != true) return;

        String warehouseQtyFieldName = InventoryManager.GetTicketItemInventoryQtyFieldName();
        List<InventoryManager.TicketItemInventoryInfo> inventoryTrackingItems = new List<InventoryManager.TicketItemInventoryInfo>();  

        for(Ticket_Item__c ti : items)
        {
            if(ti.Warehouse__c == null || !ti.Catalog_Track_Inventory__c) continue;
            inventoryTrackingItems.add(new InventoryManager.TicketItemInventoryInfo(ti, warehouseQtyFieldName, false));
        }
        InventoryManager.UpdateWarehouseInventory(inventoryTrackingItems);
    }   

    public static void OnTicketItemAfterUpdate(List<Ticket_Item__c> items, Map<Id, Ticket_Item__c> oldMap)
    {
        if(FX_Settings__c.getOrgDefaults().EnableInventoryTracking__c != true) return;

        String warehouseQtyFieldName = InventoryManager.GetTicketItemInventoryQtyFieldName();
        List<InventoryManager.TicketItemInventoryInfo> inventoryTrackingItems = new List<InventoryManager.TicketItemInventoryInfo>();  

        for(Ticket_Item__c ti: items)
        {
            if(!ti.Catalog_Track_Inventory__c) continue;

            Ticket_Item__c old = oldMap.get(ti.Id);
            Double newQty = (Double)ti.get(warehouseQtyFieldName);
            Double oldQty = TicketItemInventoryQtyLookup.containsKey(ti.Id)? TicketItemInventoryQtyLookup.get(ti.Id) : (Double)old.get(warehouseQtyFieldName);

            if(ti.Warehouse__c == old.Warehouse__c && newQty != oldQty && ti.Warehouse__c!=null)
            {
                inventoryTrackingItems.add(new InventoryManager.TicketItemInventoryInfo(ti, newQty - oldQty));
                TicketItemInventoryQtyLookup.put(ti.Id, newQty);
            } 
            else if(ti.Warehouse__c != old.Warehouse__c)
            {
                if(old.Warehouse__c!=null)
                {
                    inventoryTrackingItems.add(new InventoryManager.TicketItemInventoryInfo(old, warehouseQtyFieldName, true));
                }
                if(ti.Warehouse__c!=null)
                {
                    inventoryTrackingItems.add(new InventoryManager.TicketItemInventoryInfo(ti, warehouseQtyFieldName, false));
                    TicketItemInventoryQtyLookup.put(ti.Id, newQty);
                }
            }                
        }
        InventoryManager.UpdateWarehouseInventory(inventoryTrackingItems);

    }

    public static void OnTicketItemAfterDelete(List<Ticket_Item__c> items)
    {
        if(FX_Settings__c.getOrgDefaults().EnableInventoryTracking__c != true) return;
        
        String warehouseQtyFieldName = InventoryManager.GetTicketItemInventoryQtyFieldName();
        List<InventoryManager.TicketItemInventoryInfo> inventoryTrackingItems = new List<InventoryManager.TicketItemInventoryInfo>();  

        for(Ticket_Item__c ti : items)
        {
            if(ti.Warehouse__c == null || !ti.Catalog_Track_Inventory__c) continue;
            inventoryTrackingItems.add(new InventoryManager.TicketItemInventoryInfo(ti, warehouseQtyFieldName, true));
        }
        InventoryManager.UpdateWarehouseInventory(inventoryTrackingItems);
    }

    static Map<Id, Double> TicketItemInventoryQtyLookup 
    {
        get
        {
            if(TicketItemInventoryQtyLocal==null)
            {
                TicketItemInventoryQtyLocal = new Map<Id, Double>();
            }
            return TicketItemInventoryQtyLocal;
        }
    }
    static Map<Id, Double> TicketItemInventoryQtyLocal;

    public static String GetTicketItemInventoryQtyFieldName()
    {
        if(String.isBlank(TicketItemInventoryQtyFieldNameLocal))
        {
            String warehouseQtyFieldName = FX_Settings__c.getOrgDefaults().TicketItemWarehouseQty__c;
            warehouseQtyFieldName = String.isBlank(warehouseQtyFieldName) ? 'qty__c' : warehouseQtyFieldName.toLowercase();
               
            Set<String> fields = Ticket_Item__c.sObjectType.getDescribe().fields.getMap().keySet();
            if(fields.contains(warehouseQtyFieldName))
            {
                TicketItemInventoryQtyFieldNameLocal = warehouseQtyFieldName;
            }
            else
            {
                TicketItemInventoryQtyFieldNameLocal = UtilityGetNamespace.CurrentNamespace() +  'Input_Qty__c';
            }
        }
        return TicketItemInventoryQtyFieldNameLocal;
    }
    static String TicketItemInventoryQtyFieldNameLocal;

	public static void RestoreInventoryUponTicketDelete(Set<Id> tktIds)
	{
        if(FX_Settings__c.getOrgDefaults().EnableInventoryTracking__c != true) return;

		String warehouseQtyFieldName = GetTicketItemInventoryQtyFieldName();

		String soql = 'SELECT Id, [ns]Warehouse__c, [ns]Catalog_Item__c, ' + warehouseQtyFieldName + ' FROM [ns]Ticket_Item__c WHERE [ns]Ticket__c IN :tktIds AND [ns]Warehouse__c!=null AND  [ns]Catalog_Track_Inventory__c=true';
		soql = soql.replace('[ns]', UtilityGetNamespace.CurrentNamespace());

        //System.debug('RestoreInventoryUponTicketDelete soql: ' + soql);

		List<TicketItemInventoryInfo> items = new List<TicketItemInventoryInfo>();
		for(sObject o : Database.query(soql))
		{
			items.add(new TicketItemInventoryInfo((Ticket_Item__c)o, warehouseQtyFieldName, true));
		}
		if(!items.isEmpty())
		{
			UpdateWarehouseInventory(items);
		}
	}

	public static void RestoreInventoryUponJobDelete(Set<Id> jobIds)
	{
        if(FX_Settings__c.getOrgDefaults().EnableInventoryTracking__c != true) return;

		List<Ticket__c> tkts = [SELECT Id FROM Ticket__c WHERE Job__c IN :jobIds];
		RestoreInventoryUponTicketDelete((new Map<Id, Ticket__c>(tkts)).keySet());
	}

	static void UpdateWarehouseInventory(List<TicketItemInventoryInfo> items)
    {       
        Map<String, Double> wiQtyLookup = new Map<String, Double>();
        for(TicketItemInventoryInfo item : items)
        {
            String key = item.WarehouseItemUniqueID;
            Double prevQty = wiQtyLookup.containsKey(key)? wiQtyLookup.get(key) : 0;  
            wiQtyLookup.put(item.WarehouseItemUniqueID, prevQty + item.Qty);
        }
        
        Set<String> ids = wiQtyLookup.keySet();
        List<Warehouse_Item__c> warehouseItems = [SELECT Quantity_On_Hand__c, Warehouse_Item_Unique__c FROM Warehouse_Item__c WHERE Warehouse_Item_Unique__c IN :ids];
        for(Warehouse_Item__c wi: warehouseItems)
        {            
            wi.Quantity_On_Hand__c = wi.Quantity_On_Hand__c - wiQtyLookup.get(wi.Warehouse_Item_Unique__c);
        }
        Database.update(warehouseItems, false);        
    }
    public class TicketItemInventoryInfo
    {
        public TicketItemInventoryInfo(Ticket_Item__c ti, String qtyField, Boolean isRestock)
        {            
            Qty = (Double)ti.get(qtyField);            
            if(isRestock)
            {
                Qty *= -1;
            }
            WarehouseItemUniqueID = ti.Warehouse__c + ti.Catalog_Item__c;

            //System.debug('TicketItemInventoryInfo('+ti.Id+', '+qtyField+', '+isRestock+'): ' + Qty + ' : ' + WarehouseItemUniqueID);

        }

        public TicketItemInventoryInfo(Ticket_Item__c ti, Double qty0)
        {
            WarehouseItemUniqueID = ti.Warehouse__c + ti.Catalog_Item__c;
            Qty = qty0;
            
            //System.debug('TicketItemInventoryInfo('+ti.Id+', '+qty0+'): ' + Qty + ' : ' + WarehouseItemUniqueID);
        }

        public Double Qty {get; private set;}
        public String WarehouseItemUniqueID {get; private set;}
    }

}