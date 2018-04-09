@isTest
global class AlpineTestHelper
{
    global class TesterException extends Exception
    {
    }

    global static Boolean HasCurrencyIso() {
        return Schema.sObjectType.Price_Book_Item__c.fields.getMap().containsKey('currencyisocode');
    }

    global static Equipment__c CreateEquipment(Boolean autoSave)
    {
        String guidStr = StringUtility.newGuid();
        Catalog_Item__c ci = new Catalog_Item__c(Name= 'CI' + guidStr   , Description__c = 'Test Catalog Item' + guidStr , UOM__c='Gal', Sequence_Number__c=1,  Ticket_Item_Record_Type__c = 'Equipment');
        insert ci;

        RecordType officeRecordType = [SELECT Id, Name, DeveloperName FROM RecordType where IsActive=true AND  SobjectType = 'Account' and DeveloperName = 'office'];

        Account office = new Account(Name= 'Office ' + guidStr, RecordTypeId = officeRecordType.Id);
        insert office;

        Equipment__c e = new Equipment__c(Name= 'Equip ' + guidStr, Catalog_Item__c = ci.Id, Unit_Number__c = guidStr, Office__c = office.Id);
        if(autoSave) insert e;

        return e;
    }

    global static Account CreateOffice(string officeName)
    {
        if(string.IsBlank(officeName))
        {
            officeName = 'Office ' + StringUtility.newGuid();
        }

        RecordType officeRecordType = [SELECT Id, Name, DeveloperName FROM RecordType where IsActive=true AND  SobjectType = 'Account' and DeveloperName = 'office'];

        Account office = new Account(Name= officeName, RecordTypeId = officeRecordType.Id);

        insert office;
        return office;
    }


    global static Account CreateAccount(string acctName)
    {
        if(string.IsBlank(acctName))
        {
            acctName = 'Account ' + StringUtility.newGuid();
        }

        Account acct = new Account(Name = acctName);
        insert acct;
        return acct;
    }

    global static List<Job__c> CreateJobs(Integer jobCount, Boolean autoSave)
    {
        string newGuid = StringUtility.newGuid();

        RecordType officeRecordType = [SELECT Id, Name, DeveloperName FROM RecordType where IsActive=true AND  SobjectType = 'Account' and DeveloperName = 'office'];

        Account office = new Account(name= 'Office ' + StringUtility.newGuid(), RecordTypeId = officeRecordType.Id);

        insert office;

        Account a = new Account(Name = 'Acct ' + newGuid);
        string priceListName = 'Price List ' + newGuid;
        Price_Book__c pl = new Price_Book__c(Name = priceListName);
        insert a;
        insert pl;


        Price_Book__c priceBook = [SELECT Id FROM Price_Book__c WHERE Name =:priceListName LIMIT 1];

        RecordType statusRecordType = GetRecordType('Status__c');

        string statusName = 'JobStatus ' + newGuid;
        Status__c st = new Status__c(Name = statusName, SObject__c='Job__c', Sync__c=true, Initial_Status_Console__c =true,  RecordTypeId=statusRecordType.Id);
        insert st;

        Status__c jobStatus = st;

        RecordType jobRecordType = GetRecordType('Job__c');

        List<Job__c> newJobs = new List<Job__c>();

        for(integer i = 0; i<jobCount ; i++){
            Job__c j = new Job__c(Name='Job ' + i, Status__c = jobStatus.Id, CustomerAccount__c = a.Id, Office__c = office.Id, Price_Book__c = priceBook.Id, RecordTypeId= jobRecordType.Id);
            newJobs.add(j);
        }
        if(autoSave)  insert newJobs;
        return newJobs;
    }

    public static List<Quote__c> CreateQuotes(Integer count, Boolean autoSave)
    {
        String newGuid = StringUtility.newGuid();

        RecordType officeRecordType = [SELECT Id, Name, DeveloperName FROM RecordType where IsActive=true AND  SobjectType = 'Account' and DeveloperName = 'office'];

        RecordType statusRecordType = GetRecordType('Status__c');
        RecordType qtRecordType = GetRecordType('Quote__c');

        Account office = new Account(name= 'Office ' + StringUtility.newGuid(), RecordTypeId = officeRecordType.Id);

        insert office;

        Account a = new Account(Name = 'Acct ' + newGuid);
        String priceListName = 'Price List ' + newGuid;
        Price_Book__c pl = new Price_Book__c(Name = priceListName);
        insert a;
        insert pl;

        Price_Book__c priceBook = [SELECT Id FROM Price_Book__c WHERE Name =:priceListName LIMIT 1];

        String statusName = 'QtInitialStatus ' + newGuid;
        Status__c st = new Status__c(Name = statusName, SObject__c='Quote__c', SObject_Record_Type__c=qtRecordType.DeveloperName, Sync__c=true, Initial_Status_Console__c =true,  RecordTypeId=statusRecordType.Id);

        insert st;

        Status__c st2 = new Status__c(Name = 'QtNoSyncStatus' + newGuid, SObject__c='Quote__c', SObject_Record_Type__c=qtRecordType.DeveloperName, Sync__c=false, Initial_Status_Console__c =false,  RecordTypeId=statusRecordType.Id);
        insert st2;

        List<Quote__c> newItems = new List<Quote__c>();

        for(Integer i = 0; i<count ; i++){
            Quote__c q = new Quote__c(CustomerAccount__c = a.Id, Office__c = office.Id, Price_Book__c = priceBook.Id, RecordTypeId = qtRecordType.Id);
            newItems.add(q);
        }
        if(autoSave)  insert newItems;
        return newItems;
    }



    global static Price_Book__c CreatePriceBook(Boolean autoSave, Date effectiveDate, string currencyISOCode)
    {
        string newGuid = StringUtility.newGuid();
        Boolean hasCurrencyIso = HasCurrencyIso();

        string priceListName = 'Price List ' + newGuid;
        Price_Book__c pl = new Price_Book__c(Name = priceListName, Effective_Date__c = effectiveDate);
        if (hasCurrencyIso) {
            pl.put('CurrencyISOCode', currencyISOCode);
        }
        if(!autoSave) return pl;

        insert pl;

        string namespace = UtilityGetNamespace.CurrentNamespace();
        String soql = (hasCurrencyIso) ? 'SELECT Id, Name, CurrencyISOCode FROM ' + namespace + 'Price_Book__c WHERE Name =:priceListName LIMIT 1'
            : 'SELECT Id, Name FROM ' + namespace + 'Price_Book__c WHERE Name =:priceListName LIMIT 1' ;

        return (Price_Book__c)Database.query(soql);
    }

    global static RecordType GetRecordType(string objectType)
    {
        string namespace = UtilityGetNamespace.CurrentNamespace();

        string objType =  objectType.startsWith(namespace)? objectType: UtilityGetNamespace.CurrentNamespace()  + objectType;

        return [SELECT Id, Name, DeveloperName FROM RecordType where IsActive=true AND  SobjectType = :objType LIMIT 1];
    }

    global static Contact CreateUser(string lastName, string firstName, Boolean autoSave)
    {
        string newGuid = StringUtility.newGuid();
        string acctName = 'Account ' + newGuid;
        Account contactAccount = new Account(Name=acctName);
        insert contactAccount;

        Account acct = [SELECT Id FROM Account WHERE Name=:acctName LIMIT 1];

        string department0 = 'Department ' + newGuid;

        Contact user = new Contact(FirstName=firstName, LastName = lastName, Department=department0, AccountId=acct.Id, User__c = UserInfo.getUserId());
        if(!autoSave) return user;
        insert user;
        return [SELECT Id, Name FROM Contact WHERE Department =:department0 LIMIT 1];
    }

    public static Contact CreateContact(Boolean autoSave)
    {
        String newGuid = StringUtility.newGuid();
        String acctName = 'Account ' + newGuid;
        Account contactAccount = new Account(Name=acctName);
        insert contactAccount;

        Account acct = [SELECT Id FROM Account WHERE Name=:acctName LIMIT 1];

        string department0 = 'Department ' + newGuid;

        String lastName = 'LastName ' + newGuid.substring(0, 10);
        String firstName = 'FirstName ' + newGuid.substring(0, 10);


        Contact c = new Contact(FirstName=firstName, LastName = lastName, Department=department0, AccountId=acct.Id);
        if(!autoSave) return c;
        insert c;
        return [SELECT Id, Name FROM Contact WHERE Id =:c.Id];
    }

    global static Contact CreateContactWithStandardUser(Boolean autoSave)
    {
        User newUser = CreateStandardUser();
        insert newUser;

        String guid = StringUtility.newGuid();
        String acctName = 'Account ' + guid;

        Account contactAccount = new Account(Name=acctName);
        insert contactAccount;

        Account acct = [SELECT Id FROM Account WHERE Name=:acctName LIMIT 1];

        String department0 = 'Department ' + guid;

        Contact cp = new Contact(FirstName='FN' + guid, LastName = 'LN' + guid, Department=department0, AccountId=acct.Id,
         User__c = newUser.Id);
        if(!autoSave) return cp;

        insert cp;
        return [SELECT Id, Name, User__c FROM Contact WHERE Id=:cp.Id];
    }


    global static User CreateStandardUser()
    {
        String guid = StringUtility.newGuid();
        String userEmail = guid + '@test.com';

        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User u = new User(Alias = 'standt', Email=userEmail, EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = p.Id,
        TimeZoneSidKey='America/Los_Angeles', UserName=userEmail);
        return u;
    }

    public enum UserLicenseType {Standard, PowerCustomerSuccess, PowerPartner, CspLitePortal, CsnOnly, Guest}
    public static User CreateUser(UserLicenseType type)
    {
        String guid = StringUtility.newGuid();
        String userEmail = guid + '@test.com';
        String licenseType = String.valueOf(type);
        System.debug('licenseType=' + licenseType);

        List<Profile> profiles = [SELECT Id FROM Profile WHERE UserType=:licenseType];
        if(profiles.isEmpty())
        {
            System.debug('FAILED : CreateUser with License Type : ' + type);
            return null;
        }

        User u = new User(Alias = 'standt', Email=userEmail, EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = profiles.get(0).Id,
        TimeZoneSidKey='America/Los_Angeles', UserName=userEmail);
        return u;
    }

    global static Contact CreateContactWithTestUser(string lastName, string firstName, Boolean autoSave)
    {
        User dummyUser = [select id, TimeZoneSidKey, LocaleSidKey, Email, UserName,
                EmailEncodingKey, ProfileId, LanguageLocaleKey
                from User limit 1];

        String guid = StringUtility.newGuid();
        String email = guid + '@test.com';

        User newUser = new User(FirstName = firstName, LastName = lastName, Email = email,Username = email, ProfileId = dummyUser.ProfileId,
        Alias =guid.substring(0,5),
        CommunityNickname = guid.substring(0,5),
        TimeZoneSidKey=dummyUser.TimeZoneSidKey,
        LocaleSidKey=dummyUser.LocaleSidKey,
        EmailEncodingKey=dummyUser.EmailEncodingKey,
        LanguageLocaleKey=dummyUser.LanguageLocaleKey);

        insert newUser;


        string newGuid = StringUtility.newGuid();
        string acctName = 'Account ' + newGuid;
        Account contactAccount = new Account(Name=acctName);
        insert contactAccount;

        Account acct = [SELECT Id FROM Account WHERE Name=:acctName LIMIT 1];

        string department0 = 'Department ' + newGuid;

        Contact cp = new Contact(FirstName=firstName, LastName = lastName, Department=department0, AccountId=acct.Id, User__c = newUser.Id);
        if(!autoSave) return cp;
        insert cp;
        return [SELECT Id, Name, User__c FROM Contact WHERE Department =:department0 LIMIT 1];
    }

    global static Contact CreateContactWithNoUser(string lastName, string firstName, Boolean autoSave)
    {
        string newGuid = StringUtility.newGuid();
        string acctName = 'Account ' + newGuid;
        Account contactAccount = new Account(Name=acctName);
        insert contactAccount;

        Account acct = [SELECT Id FROM Account WHERE Name=:acctName LIMIT 1];

        string department0 = 'Department ' + newGuid;

        Contact user = new Contact(FirstName=firstName, LastName = lastName, Department=department0, AccountId=acct.Id);
        if(!autoSave) return user;
        insert user;
        return [SELECT Id, Name FROM Contact WHERE Department =:department0 LIMIT 1];
    }

    public static List<Crew_Planning__c> CreateScheduledCrew(Integer crewCount, Job__c job, Boolean autoSave) {
        List<Price_Book_Item__c> pricebookItems = CreatePriceBookItems(1, job.Price_Book__c, 'test1');

        List<Crew_Planning__c> scheduledCrew = new List<Crew_Planning__c>();
        for(Integer i=0; i<crewCount; i++)
        {
            scheduledCrew.add(new Crew_Planning__c(Job__c = job.Id, Role_on_Job__c= pricebookItems[0].Id));
        }

        if(autoSave) insert scheduledCrew;
        return scheduledCrew;
    }

    public static List<Equipment_Planning__c> CreateScheduledEquipment(Integer equipmentCount, Job__c job, Boolean autoSave) {
        List<Price_Book_Item__c> pricebookItems = CreatePriceBookItems(1, job.Price_Book__c, 'test1');

        List<Equipment_Planning__c> scheduledEquipment = new List<Equipment_Planning__c>();
        for(Integer i=0; i<equipmentCount; i++)
        {
            scheduledEquipment.add(new Equipment_Planning__c(Job__c = job.Id, Price_Book_Item__c= pricebookItems[0].Id));
        }

        if(autoSave) insert scheduledEquipment ;
        return scheduledEquipment;
    }

    global static List<Ticket__c> CreateTickets(Integer tktCount, Boolean autoSave)
    {
        Job__c job = CreateJobs(1, true).get(0);

        return CreateTickets(job, tktCount, autoSave);
    }

    global static List<Ticket__c> CreateTickets(Job__c job, Integer tktCount, Boolean autoSave)
    {
        string newGuid = StringUtility.newGuid();

        RecordType statusRecordType = GetRecordType('Status__c');
        RecordType tktRecordType = GetRecordType('Ticket__c');

        string statusName = 'TktInitialStatus ' + newGuid;
        Status__c st = new Status__c(Name = statusName, SObject__c='Ticket__c', SObject_Record_Type__c=tktRecordType.DeveloperName, Sync__c=true, Initial_Status_Console__c =true,  RecordTypeId=statusRecordType.Id);

        insert st;

        Status__c st2 = new Status__c(Name = 'TktNoSyncStatus' + newGuid, SObject__c='Ticket__c', SObject_Record_Type__c=tktRecordType.DeveloperName, Sync__c=false, Initial_Status_Console__c =false,  RecordTypeId=statusRecordType.Id);
        insert st2;

        List<Ticket__c> tkts = new List<Ticket__c>();
        for(Integer i=0; i<tktCount; i++)
        {
            tkts.add(new Ticket__c(Job__c = job.Id, RecordTypeId = tktRecordType.Id));
        }

        if(autoSave) insert tkts;
        return tkts;
    }

    global static List<Invoice__c> CreateInvoices(Integer invCount, Boolean autoSave, Id pricebook)
    {
        string newGuid = StringUtility.newGuid();
        string acctName = 'Account ' + newGuid;
        Account contactAccount = new Account(Name=acctName);
        insert contactAccount;

        Account acct = [SELECT Id FROM Account WHERE Name=:acctName LIMIT 1];

        RecordType statusRecordType = GetRecordType('Status__c');

        string statusName = 'InvInitialStatus ' + newGuid;
        Status__c st = new Status__c(Name = statusName, SObject__c='Invoice__c', Sync__c=true, Initial_Status_Console__c =true,  RecordTypeId=statusRecordType.Id);

        insert st;

        Status__c st2 = new Status__c(Name = 'InvNoSyncStatus' + newGuid, SObject__c='Invoice__c', Sync__c=false, Initial_Status_Console__c =false,  RecordTypeId=statusRecordType.Id);
        insert st2;

        List<Invoice__c> invs = new List<Invoice__c>();
        for(Integer i=0; i<invCount; i++)
        {
            Invoice__c inv = new Invoice__c(CustomerAccount__c = acct.Id, Status__c = st.Id);
            if (pricebook != null) {
              inv.Price_Book__c = pricebook;
            }
            if(String.isBlank(inv.Tracking_Number__c)){
              inv.Tracking_Number__c = StringUtility.getTrackingNumber('I-');
            }
            invs.add(inv);
        }

        if(autoSave) insert invs;
        return invs;
    }

    global static List<Quote__c> CreateQuotes(Price_Book__c pb, Integer qtCount, Boolean autoSave)
    {
        string newGuid = StringUtility.newGuid();

        RecordType statusRecordType = GetRecordType('Status__c');
        RecordType qtRecordType = GetRecordType('Quote__c');

        string statusName = 'QtInitialStatus ' + newGuid;
        Status__c st = new Status__c(Name = statusName, SObject__c='Quote__c', SObject_Record_Type__c=qtRecordType.DeveloperName, Sync__c=true, Initial_Status_Console__c =true,  RecordTypeId=statusRecordType.Id);

        insert st;

        Status__c st2 = new Status__c(Name = 'QtNoSyncStatus' + newGuid, SObject__c='Quote__c', SObject_Record_Type__c=qtRecordType.DeveloperName, Sync__c=false, Initial_Status_Console__c =false,  RecordTypeId=statusRecordType.Id);
        insert st2;

        List<Quote__c> qts = new List<Quote__c>();
        for(Integer i=0; i<qtCount; i++)
        {
            qts.add(new Quote__c(Price_Book__c = pb.Id, RecordTypeId = qtRecordType.Id));
        }

        if(autoSave) insert qts;
        return qts;
    }

    global  static List<Price_Book_Item__c> CreatePriceBookItems(Integer itemsCount, Id priceBookId, string itemType)
    {
        return CreatePriceBookItems(itemsCount, priceBookId, itemType, true);
    }

    global  static List<Price_Book_Item__c> CreatePriceBookItems(Integer itemsCount, Id priceBookId, string itemType, Boolean autoSave)
    {
        List<Catalog_Item__c> catalogItems = new List<Catalog_Item__c>();
        for(Integer i=0; i<itemsCount; i++)
        {
            catalogItems.add(new Catalog_Item__c(Name= 'CI' +  StringUtility.newGuid(), Description__c = 'Test Catalog Item' + i, UOM__c='Gal', Sequence_Number__c=i,  Ticket_Item_Record_Type__c = itemType));
        }
        insert catalogItems;
        List<Price_Book_Item__c> pliItems = new List<Price_Book_Item__c>();
        for(Integer i=0; i<itemsCount; i++)
        {
            pliItems.add(new Price_Book_Item__c(Price_Book__c = priceBookId, Price__c=i+3, Sequence_Number__c =i, Discount_Percent__c=0.123, Default_Quantity__c=1096, Included_Quantity__c=0, Catalog_Item__c=catalogItems.get(i).Id));
        }
        if(autoSave) insert pliItems;
        return pliItems;
    }

    public static Preventative_Maintenance_Schedule__c CreatePMS(Work_Order__c templateWorkOrder, Boolean autoSave)
     {
         Equipment__c e = CreateEquipment(true);

         Preventative_Maintenance_Schedule__c  pms = new Preventative_Maintenance_Schedule__c();
         if(templateWorkOrder != null)
         {
             pms.Template_Work_Order__c = templateWorkOrder.Id;
         }
         pms.Equipment__c = e.Id;
         pms.IsActive__c = true;
         if(autoSave) insert pms;
         return pms;

     }

     public static List<Work_Order__c> CreateWorkOrders(Preventative_Maintenance_Schedule__c sourcePMS, Integer itemsCount, Boolean autoSave)
     {
         List<Work_Order__c> workOrders = new List<Work_Order__c>();
         for(Integer i =0; i<itemsCount; i++)
         {
             Work_Order__c wo = new Work_Order__c(IsTemplate__c = false);
             if(sourcePMS!=null)
             {
                 wo.Source_PMS__c = sourcePMS.Id;
             }
             workOrders.add(wo);
         }
         if(autoSave) insert workOrders;
         return workOrders;
     }

}
