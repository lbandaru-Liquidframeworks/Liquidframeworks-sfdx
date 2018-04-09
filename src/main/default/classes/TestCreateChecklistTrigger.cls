/**
* This class contains unit tests for validating the behavior of Apex classes
* and triggers.
*
* Unit tests are class methods that verify whether a particular piece
* of code is working properly. Unit test methods take no arguments,
* commit no data to the database, and are flagged with the testMethod
* keyword in the method definition.
*
* All test methods in an organization are executed whenever Apex code is deployed
* to a production organization to confirm correctness, ensure code
* coverage, and prevent regressions. All Apex classes are
* required to have at least 75% code coverage in order to be deployed
* to a production organization. In addition, all triggers must have some code coverage.
* 
 * The @isTest class annotation indicates this class only contains test
* methods. Classes defined with the @isTest annotation do not count against
* the organization size limit for all Apex scripts.
*
* See the Apex Language Reference for more information about Testing and Code Coverage.
*/
@isTest
private class TestCreateChecklistTrigger {

    static testMethod void myUnitTest() {
       
        Job__c j = AlpineTestHelper.CreateJobs(1, true).get(0);

        string checkListName = StringUtility.newGuid();
        Checklist__c cl = new Checklist__c(Account__c = j.CustomerAccount__c, Name= checkListName);
        insert cl;
        Checklist_Step__c cli = new Checklist_Step__c(Checklist__c = cl.Id, Sequence_Number__c = 1, Description__c = 'test1', Screen__c = 'Labor');
        Checklist_Step__c cli2 = new Checklist_Step__c(Checklist__c = cl.Id, Sequence_Number__c = 2, Description__c = 'test2', Screen__c = 'Labor');
        insert cli;
        insert cli2;
        
        Ticket__c t = AlpineTestHelper.CreateTickets(j, 1, true).get(0);

            
        //Ticket_Checklist_Step__c secondpi = pis.get(1);
        
        Ticket__c tkt = [SELECT Checklist_Name__c FROM Ticket__c WHERE Id = :t.Id LIMIT 1];
        System.assertEquals(tkt.Checklist_Name__c,  checkListName);

        List<Ticket_Checklist_Step__c> pis = [SELECT Screen__c, Sequence_Number__c, Name, Description__c, SyncID__c FROM Ticket_Checklist_Step__c WHERE Ticket__c = :t.Id ORDER BY Sequence_Number__c];    

        System.assertEquals(pis.size(), 2);
        //System.assertEquals(secondpi.Sequence_Number__c, 2);
        //System.assertEquals(secondpi.Description__c, 'test2');
        //System.assert(StringUtility.isValidGuid(secondpi.SyncID__c));
    }
}