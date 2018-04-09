@isTest
private class Invoicing_Test
{
    static testmethod void TrackingNumber_Test()
    {
        Test.startTest();
        Job__c j = AlpineTestHelper.CreateJobs(1, true).get(0);

        String newGuid = StringUtility.newGuid();

        string statusName = 'InvoiceStatus ' + newGuid;
        Status__c st = new Status__c(Name = statusName, SObject__c='Invoice__c', Sync__c=true, Initial_Status_Console__c =true);

        insert st;

        statusName = 'CreditMemoStatus ' + newGuid;
        Status__c stCM = new Status__c(Name = statusName, SObject__c='Credit_Memo__c', Sync__c=true, Initial_Status_Console__c =true);

        insert stCM ;


        Invoice__c inv = new Invoice__c(CustomerAccount__c = j.CustomerAccount__c , Price_Book__c = j.Price_Book__c, Status__c = st.Id );
        insert inv;


        Credit_Memo__c cm = new Credit_Memo__c(CustomerAccount__c = j.CustomerAccount__c , Price_Book__c = j.Price_Book__c, Status__c = stCM.Id );
        insert cm;

        Payment__c p = new Payment__c();
        insert p;

        Test.stopTest();

        Invoice__c  dbInv = [SELECT Id, Tracking_Number__c FROM Invoice__c WHERE Id=:inv.Id];

        System.assert(!String.isBlank(dbInv.Tracking_Number__c) && dbInv.Tracking_Number__c.startsWith('I-'), 'Invalid Inventory tracking number: ' + dbInv.Tracking_Number__c) ;


        Credit_Memo__c dbCM = [SELECT Id, Tracking_Number__c FROM Credit_Memo__c WHERE Id=:cm.Id];

        System.assert(!String.isBlank(dbCM.Tracking_Number__c) && dbCM.Tracking_Number__c.startsWith('C-'), 'Invalid Credit Memo tracking number: ' + dbCM.Tracking_Number__c) ;


        Payment__c dbPayment = [SELECT Id, Tracking_Number__c FROM Payment__c WHERE Id=:p.Id];

        System.assert(!String.isBlank(dbPayment.Tracking_Number__c) && dbPayment.Tracking_Number__c.startsWith('P-'), 'Invalid Payment__c  tracking number:' + dbPayment.Tracking_Number__c) ;
    }

}
