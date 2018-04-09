@isTest
private class TicketLogTest{

    
    static testmethod void addSyncIDToTicketLog(){
        
        Ticket__c tkt = AlpineTestHelper.CreateTickets(1, true).get(0);       
        Ticket_Log__c tktLog = new Ticket_Log__c(Ticket__c = tkt.Id, Start_Time__c = System.now());
        insert tktLog;
       
        Ticket_Log__c dbTktLog=  [SELECT SyncID__c FROM Ticket_Log__c WHERE Ticket__c = :tkt.Id LIMIT 1];

        system.assert(StringUtility.isValidGuid(dbTktLog.SyncID__c));       
    }
    
    
}