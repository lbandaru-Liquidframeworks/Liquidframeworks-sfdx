@isTest
private class InventoryManager_Test
{
	static Double w1QtyOnHand = 50000;
	static Double w2QtyOnHand = 40000;

	static Ticket_Item__c SetupTicketItem()
	{
        FX_Settings__c fs = FX_Settings__c.getOrgDefaults();
        fs.SetupOwnerId = UserInfo.getOrganizationId();
        fs.EnableInventoryTracking__c = true;
        insert fs;

		Warehouse__c w1 = new Warehouse__c(Name='w1');
		Warehouse__c w2 = new Warehouse__c(Name='w2');

		insert w1;
		insert w2;


		String guid = StringUtility.newGuid();
		Catalog_Item__c ci = new Catalog_Item__c(Name='InventoryUnitTestCatalogItem', Description__c='Test', Sequence_Number__c=99.1, Ticket_Item_Record_Type__c='Equipment', Track_Inventory__c=true);

		insert ci;

		Warehouse_Item__c wi1 = new Warehouse_Item__c(Warehouse__c = w1.Id, Catalog_Item__c = ci.Id, Quantity_On_Hand__c = w1QtyOnHand);
		Warehouse_Item__c wi2 = new Warehouse_Item__c(Warehouse__c = w2.Id, Catalog_Item__c = ci.Id, Quantity_On_Hand__c = w2QtyOnHand);

		insert wi1;
		insert wi2;

		Job__c job = AlpineTestHelper.CreateJobs(1, false).get(0);
		job.Warehouse__c = w1.Id;
		insert job;

		Price_Book_Item__c pbi = new Price_Book_Item__c(Price_Book__c = job.Price_Book__c, Catalog_Item__c = ci.Id, Default_Quantity__c=5, Sequence_Number__c=0, Discount_Percent__c=0);
		insert pbi;

		Ticket__c tkt = AlpineTestHelper.CreateTickets(job, 1, true).get(0);

		Ticket_Item__c ti = new Ticket_Item__c(Ticket__c = tkt.Id, Price_Book_Item__c = pbi.Id);
		insert ti;
		return ti;
	}


	static testmethod void InsertTicketItem_Test()
    {
    	Test.StartTest();
    	Ticket_Item__c ti = SetupTicketItem();
    	Test.StopTest();

    	String warehouseQtyFieldName = InventoryManager.GetTicketItemInventoryQtyFieldName();

    	String tktItemSoql = 'SELECT Id, [ns]Warehouse__c, [ns]Catalog_Item__c, ' + warehouseQtyFieldName + ' FROM [ns]Ticket_Item__c WHERE Id=\'' + ti.Id + '\'';

    	String ns = UtilityGetNamespace.CurrentNamespace();

		tktItemSoql = tktItemSoql.replace('[ns]', ns);

		List<sObject> objs = Database.query(tktItemSoql);

		System.assertEquals(1, objs.size());

    	String wiSoql = 'SELECT [ns]Warehouse__c, [ns]Catalog_Item__c, [ns]Quantity_On_Hand__c FROM [ns]Warehouse_Item__c WHERE [ns]Warehouse__r.Name=\'W1\'';

    	List<Warehouse_Item__c> wiItems = [SELECT Warehouse__c, Catalog_Item__c, Quantity_On_Hand__c FROM Warehouse_Item__c WHERE Warehouse__r.Name='W1'];
    	System.assertEquals(1, wiItems.size());

    	Double qty = (Double)objs.get(0).get(warehouseQtyFieldName);

    	System.assertEquals(wiItems.get(0).Quantity_On_Hand__c, w1QtyOnHand - qty);

    }

    static testmethod void InsertSamePriceBookItem_Test()
    {
        Test.StartTest();
        Ticket_Item__c ti = SetupTicketItem();

        Ticket_Item__c ti2 = new Ticket_Item__c(Ticket__c = ti.Ticket__c, Price_Book_Item__c = ti.Price_Book_Item__c);
        insert ti2;

        Test.StopTest();

        String warehouseQtyFieldName = InventoryManager.GetTicketItemInventoryQtyFieldName();

        String tktItemSoql = 'SELECT Id, [ns]Warehouse__c, [ns]Catalog_Item__c, ' + warehouseQtyFieldName + ' FROM [ns]Ticket_Item__c WHERE [ns]Ticket__c=\'' + ti.Ticket__c + '\'';

        String ns = UtilityGetNamespace.CurrentNamespace();

        tktItemSoql = tktItemSoql.replace('[ns]', ns);

        List<Ticket_Item__c> tktItems  = (List<Ticket_Item__c>)Database.query(tktItemSoql);

        
        Double totalQty = 0;
        for(Ticket_Item__c tktItem : tktItems)
        {
            totalQty += (double)tktItem.get(warehouseQtyFieldName);
        }

        String wiSoql = 'SELECT [ns]Warehouse__c, [ns]Catalog_Item__c, [ns]Quantity_On_Hand__c FROM [ns]Warehouse_Item__c WHERE [ns]Warehouse__r.Name=\'W1\'';

        List<Warehouse_Item__c> wiItems = [SELECT Warehouse__c, Catalog_Item__c, Quantity_On_Hand__c FROM Warehouse_Item__c WHERE Warehouse__r.Name='W1'];
        System.assertEquals(1, wiItems.size());

        System.assertEquals(wiItems.get(0).Quantity_On_Hand__c, w1QtyOnHand - totalQty);

    }

    static testmethod void UpdateSamePriceBookItem_Test()
    {
        Ticket_Item__c ti = SetupTicketItem();

        List<Ticket_Item__c> items = new List<Ticket_Item__c>();
        for(Integer i =0; i<300; i++)
        {
            items.add(new Ticket_Item__c(Ticket__c = ti.Ticket__c, Price_Book_Item__c = ti.Price_Book_Item__c));
        }
        insert items;
        String ns = UtilityGetNamespace.CurrentNamespace();
        String warehouseQtyFieldName = InventoryManager.GetTicketItemInventoryQtyFieldName();
        String tktItemSoql = (warehouseQtyFieldName == ns + 'Input_Qty__c')? 'SELECT Id, [ns]Warehouse__c, [ns]Catalog_Item__c, ' + warehouseQtyFieldName + ' FROM [ns]Ticket_Item__c WHERE [ns]Ticket__c=\'' + ti.Ticket__c + '\''
        : 'SELECT Id, [ns]Input_Qty__c, [ns]Warehouse__c, [ns]Catalog_Item__c, ' + warehouseQtyFieldName + ' FROM [ns]Ticket_Item__c WHERE [ns]Ticket__c=\'' + ti.Ticket__c + '\'';
      
        tktItemSoql = tktItemSoql.replace('[ns]', ns);

        Test.StartTest();
        List<Ticket_Item__c> dbItems  = (List<Ticket_Item__c>)Database.query(tktItemSoql);
        for(Ticket_Item__c item : dbItems)
        {
            Double qty = item.Input_Qty__c;
            item.Input_Qty__c =  qty * 2;
        }
        update dbItems;

        Test.StopTest();  

        List<Ticket_Item__c> tktItems  = (List<Ticket_Item__c>)Database.query(tktItemSoql);

        Double totalQty = 0;
        for(Ticket_Item__c tktItem : tktItems)
        {
            totalQty += (double)tktItem.get(warehouseQtyFieldName);
        }

        String wiSoql = 'SELECT [ns]Warehouse__c, [ns]Catalog_Item__c, [ns]Quantity_On_Hand__c FROM [ns]Warehouse_Item__c WHERE [ns]Warehouse__r.Name=\'W1\'';

        List<Warehouse_Item__c> wiItems = [SELECT Warehouse__c, Catalog_Item__c, Quantity_On_Hand__c FROM Warehouse_Item__c WHERE Warehouse__r.Name='W1'];
        System.assertEquals(1, wiItems.size());

        System.assertEquals(wiItems.get(0).Quantity_On_Hand__c, w1QtyOnHand - totalQty);

    }


    static testmethod void UpdateTicketItemQty_Test()
    {
    	Test.StartTest();
    	Ticket_Item__c ti = SetupTicketItem();    	
    	String ns = UtilityGetNamespace.CurrentNamespace();
    	String warehouseQtyFieldName = InventoryManager.GetTicketItemInventoryQtyFieldName();

    	String tktItemSoql = 'SELECT Id, [ns]Warehouse__c, [ns]Catalog_Item__c, ' + warehouseQtyFieldName + ' FROM [ns]Ticket_Item__c WHERE Id=\'' + ti.Id + '\'';	

		tktItemSoql = tktItemSoql.replace('[ns]', ns);

		List<sObject> objs = Database.query(tktItemSoql);

		System.assertEquals(1, objs.size());
		Ticket_Item__c dbTktItem = (Ticket_Item__c)objs.get(0);
		Double newQty = 1;
		dbTktItem.Input_Qty__c = newQty;

		update dbTktItem;

    	Test.StopTest();

    

    	objs = Database.query(tktItemSoql);
		System.assertEquals(1, objs.size());


    	String wiSoql = 'SELECT [ns]Warehouse__c, [ns]Catalog_Item__c, [ns]Quantity_On_Hand__c FROM [ns]Warehouse_Item__c WHERE [ns]Warehouse__r.Name=\'W1\'';

    	List<Warehouse_Item__c> wiItems = [SELECT Warehouse__c, Catalog_Item__c, Quantity_On_Hand__c FROM Warehouse_Item__c WHERE Warehouse__r.Name='W1'];
    	System.assertEquals(1, wiItems.size());

    	Double qty = (Double)objs.get(0).get(warehouseQtyFieldName);

    	System.assertEquals(newQty, qty);

    	System.assertEquals(wiItems.get(0).Quantity_On_Hand__c, w1QtyOnHand - qty);

    }

    static testmethod void UpdateTicketItem_WarehouseAndQty_Test()
    {
    	Test.StartTest();
    	Ticket_Item__c ti = SetupTicketItem();    	
    	String ns = UtilityGetNamespace.CurrentNamespace();
    	String warehouseQtyFieldName = InventoryManager.GetTicketItemInventoryQtyFieldName();

    	String tktItemSoql = 'SELECT Id, [ns]Warehouse__c, [ns]Catalog_Item__c, ' + warehouseQtyFieldName + ' FROM [ns]Ticket_Item__c WHERE Id=\'' + ti.Id + '\'';	

		tktItemSoql = tktItemSoql.replace('[ns]', ns);

		List<sObject> objs = Database.query(tktItemSoql);

		System.assertEquals(1, objs.size());
		Ticket_Item__c dbTktItem = (Ticket_Item__c)objs.get(0);
		Double newQty = 1;
		dbTktItem.Input_Qty__c = newQty;

		Warehouse__c w2 = [SELECT Id FROM Warehouse__c WHERE Name='W2' LIMIT 1];

		dbTktItem.Warehouse__c = w2.Id;
		update dbTktItem;

    	Test.StopTest();

    

    	objs = Database.query(tktItemSoql);
		System.assertEquals(1, objs.size());

    	List<Warehouse_Item__c> wiItems = [SELECT Warehouse__r.Name, Warehouse__c, Catalog_Item__c, Quantity_On_Hand__c FROM Warehouse_Item__c WHERE Warehouse__r.Name='W1' OR Warehouse__r.Name='W2'];
    	System.assertEquals(2, wiItems.size());

    	if(wiItems.get(0).Warehouse__r.Name == 'W1')
    	{
    		System.assertEquals(w1QtyOnHand, wiItems.get(0).Quantity_On_Hand__c);
    		System.assertEquals(w2QtyOnHand - newQty, wiItems.get(1).Quantity_On_Hand__c);
    	}
    	else
    	{
    		System.assertEquals(w1QtyOnHand, wiItems.get(1).Quantity_On_Hand__c);
    		System.assertEquals(w2QtyOnHand - newQty, wiItems.get(0).Quantity_On_Hand__c);

    	}   

    }


    static testmethod void DeleteTicketItem_Test()
    {
    	Test.StartTest();
    	Ticket_Item__c ti = SetupTicketItem(); 
    	delete ti;
    	Test.StopTest();    

    	List<Warehouse_Item__c> wiItems = [SELECT Warehouse__c, Catalog_Item__c, Quantity_On_Hand__c FROM Warehouse_Item__c WHERE Warehouse__r.Name='W1'];
    	System.assertEquals(1, wiItems.size());
    	System.assertEquals(w1QtyOnHand, wiItems.get(0).Quantity_On_Hand__c);
    }

    static testmethod void DeleteJob_Test()
    {
    	Test.StartTest();
    	Ticket_Item__c ti = SetupTicketItem();  
    	Ticket_Item__c dbTktItem = [SElECT Id, Ticket__c, Ticket__r.Id, Ticket__r.Job__c,  Ticket__r.Job__r.Id FROM Ticket_Item__c WHERE Id=:ti.Id];
    	delete dbTktItem.Ticket__r.Job__r;

    	Test.StopTest();    

    	List<Warehouse_Item__c> wiItems = [SELECT Warehouse__c, Catalog_Item__c, Quantity_On_Hand__c FROM Warehouse_Item__c WHERE Warehouse__r.Name='W1'];
    	System.assertEquals(1, wiItems.size());
    	System.assertEquals(w1QtyOnHand, wiItems.get(0).Quantity_On_Hand__c);
    }

    static testmethod void DeleteTicket_Test()
    {
    	Test.StartTest();
    	Ticket_Item__c ti = SetupTicketItem();  

    	Ticket_Item__c dbTktItem = [SElECT Id, Ticket__c, Ticket__r.Id, Ticket__r.Job__c,  Ticket__r.Job__r.Id FROM Ticket_Item__c WHERE Id=:ti.Id];

    
    	delete dbTktItem.Ticket__r;

    	Test.StopTest();    

    	List<Warehouse_Item__c> wiItems = [SELECT Warehouse__c, Catalog_Item__c, Quantity_On_Hand__c FROM Warehouse_Item__c WHERE Warehouse__r.Name='W1'];
    	System.assertEquals(1, wiItems.size());
    	System.assertEquals(w1QtyOnHand, wiItems.get(0).Quantity_On_Hand__c);
    }

}