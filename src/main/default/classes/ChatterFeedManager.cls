global class ChatterFeedManager
{    
     global static Boolean AutoFollowJob(Id userId)
     {
          return FX_Settings__c.getInstance(userId).AutoFollowJobTicket__c;
     }

     global static void ProcessJobTicketFeeds(List<Sync_Assignment__c> syncAssignmentsArgs, Boolean trueToSubscribe)
     {   
         
          Set<Id> contactIds = new Set<Id>();
          Set<Id> jobs = new Set<Id>();
          for(Sync_Assignment__c sc : syncAssignmentsArgs)
          {
               contactIds.add(sc.Contact__c);
          }
          List<Sync_Assignment__c> syncAssignments = new List<Sync_Assignment__c>();

          Set<Id> userIds = new Set<Id>();
          List<Contact> contacts = [SELECT Id, User__c FROM Contact WHERE Id IN :contactIds AND User__c!=null];

          Map<Id, Contact> contactLookup = new Map<Id, Contact> (contacts);
          Map<Id, Id> userToContact = new Map<Id, Id>();
          for(Contact c : contacts)
          {
               userIds.add(c.User__c);
               userToContact.put(c.User__c, c.Id) ;
          }
          for(Sync_Assignment__c sc : syncAssignmentsArgs)
          {
               if(!contactLookup.containsKey(sc.Contact__c) || !AutoFollowJob(contactLookup.get(sc.Contact__c).User__c)) continue;
               syncAssignments.add(sc);
               jobs.add(sc.Job__c);
          }

          if(syncAssignments.isEmpty()) return;

          List<Ticket__c> tkts = [SElECT Id, Job__c FROM Ticket__c WHERE Job__c IN :jobs AND Sync__c=true];
          Map<Id, List<Id>> jobTkts = new  Map<Id, List<Id>>();         


          Set<Id> tktIds = new Set<Id>();
         
          for(Ticket__c t : tkts)
          {
               if(!jobTkts.containsKey(t.Job__c)) jobTkts.put(t.Job__c, new List<Id>());
               jobTkts.get(t.Job__c).add(t.Id);
               tktIds.add(t.Id);
          }

          Map<string, EntitySubscription> esLookup = new Map<string, EntitySubscription>();

          for(EntitySubscription es : [select Id, parentid, subscriberid from EntitySubscription 
               where subscriberid IN :userIds AND (parentid IN :jobs  OR parentid IN :tktIds)])
          {              
               esLookup.put(String.valueOf(es.subscriberid) + es.parentid, es);
          }

        
          List<EntitySubscription> itemsOfInterest = new List<EntitySubscription>();


          for(Sync_Assignment__c sc : syncAssignments)
          {  
               Id userId = contactLookup.get(sc.Contact__c).User__c;  
               String userIdStr = String.valueOf(userId) ;     
               String esKey = userIdStr + sc.Job__c;

               if(trueToSubscribe)
               {
                    if(esLookup.containsKey(esKey)) continue;
                    itemsOfInterest.add(new EntitySubscription(parentid=sc.Job__c, subscriberId= userId));
               }
               else
               {
                    if(!esLookup.containsKey(esKey)) continue;
                    itemsOfInterest.add(esLookup.get(esKey));

               }

               if(!jobTkts.containsKey(sc.Job__c)) continue;
              
               for(Id tkt : jobTkts.get(sc.Job__c))
               {
                  
                    esKey = userIdStr + tkt;

                    if(trueToSubscribe)
                    {
                         if(esLookup.containsKey(esKey)) continue;
                         itemsOfInterest.add(new EntitySubscription(parentid=tkt, subscriberId= userId));
                    }
                    else
                    {
                         if(!esLookup.containsKey(esKey)) continue;
                         itemsOfInterest.add(esLookup.get(esKey));
                    }
               }
          }

        


          if(itemsOfInterest.isEmpty()) return;

          if(trueToSubscribe) Database.insert(itemsOfInterest, false);
          else delete itemsOfInterest;

     }

     global static void ProcessTicketFeedsOnTicketInsert(List<Ticket__c> objs)
     {         
          Set<Id> jobIds = new Set<Id>();
          Set<Id> tktIds = new Set<Id>();

          Map<Id, List<Id>> jobTkts = new  Map<Id, List<Id>>();

          List<Ticket__c> tkts = new List<Ticket__c>();

          for(Ticket__c t : objs)
          {
               if(!t.Sync__c) continue;
               tkts.add(t);
               tktIds.add(t.Id);
               jobIds.add(t.Job__c);    
               if(!jobTkts.containsKey(t.Job__c))  jobTkts.put(t.Job__c, new List<Id>());
               jobTkts.get(t.Job__c).add(t.Id);
          }


          List<Sync_Assignment__c> jobSubs = [SELECT Contact__c, Contact__r.User__c, Job__c from Sync_Assignment__c WHERE Job__c IN :jobIds AND Contact__r.User__c!=null];
          Set<Id> users = new Set<Id>();
          Set<Id> jobsInSubscription = new Set<Id>();

          Map<Id, List<Id>> jobForUsers = new Map<Id, List<Id>>();


          List<Sync_Assignment__c> jobSubscriptions = new List<Sync_Assignment__c>();

          for(Sync_Assignment__c sc : jobSubs)
          {
               if(!AutoFollowJob(sc.Contact__r.User__c)) continue;

               jobSubscriptions.add(sc);

               users.add(sc.Contact__r.User__c);
               jobsInSubscription.add(sc.Job__c);
               if(!jobForUsers.containsKey(sc.Job__c)) jobForUsers.put(sc.Job__c, new List<Id>());
               jobForUsers.get(sc.Job__c).add(sc.Contact__r.User__c);

          }

          if(jobSubscriptions.isEmpty()) return;

          List<EntitySubscription> newItems = new List<EntitySubscription>();

          for(Ticket__c t : tkts)
          {
               if(!jobForUsers.containsKey(t.Job__c)) continue;
               for(Id user : jobForUsers.get(t.Job__c))
               {
                    newItems.add(new EntitySubscription(parentid=t.Id, subscriberId= user));
               }
          }
          if(!newItems.isEmpty())
          {
               Database.insert(newItems, false);
          }

     }
    
     global static void ProcessTicketFeedsOnTicketUpdate(List<Ticket__c> tkts)
     {       
          Set<Id> jobIds = new Set<Id>();
          Set<Id> tktIds = new Set<Id>();

          for(Ticket__c t : tkts)
          {
               tktIds.add(t.Id);
               jobIds.add(t.Job__c);                         
          }          
          
          List<Sync_Assignment__c> jobSubs = [SELECT Contact__c, Contact__r.User__c, Job__c from Sync_Assignment__c WHERE Job__c IN :jobIds AND Contact__r.User__c!=null];

          if(jobSubs.isEmpty()) return;

          Set<Id> users = new Set<Id>();
          Set<Id> jobsInSubscription = new Set<Id>();

          Map<Id, List<Id>> jobForUsers = new Map<Id, List<Id>>();


          for(Sync_Assignment__c sc : jobSubs)
          {
               if(!AutoFollowJob(sc.Contact__r.User__c)) continue;
               users.add(sc.Contact__r.User__c);

               if(!jobForUsers.containsKey(sc.Job__c)) jobForUsers.put(sc.Job__c, new List<Id>());
               jobForUsers.get(sc.Job__c).add(sc.Contact__r.User__c);

          }


          List<EntitySubscription> newItems = new List<EntitySubscription>();
          List<EntitySubscription> deleteItems = new List<EntitySubscription>();       
         

          Map<string, EntitySubscription> esLookup = new Map<string, EntitySubscription>();

          for(EntitySubscription es : [select Id, parentid, subscriberid from EntitySubscription 
               where subscriberid IN :users AND (parentid IN :tktIds)])
          {              
               esLookup.put(String.valueOf(es.subscriberid) + es.parentid, es);
          }
          
          for(Ticket__c t : tkts)
          {
               if(!jobForUsers.containsKey(t.Job__c)) continue;
               for(Id user : jobForUsers.get(t.Job__c))
               {
                    String key = String.valueOf(user) + t.Id;
                    if(esLookup.containsKey(key))
                    {
                         if(!t.Sync__c) deleteItems.add(esLookup.get(key));
                    }
                    else if(t.Sync__c)
                    {
                         newItems.add(new EntitySubscription(parentid=t.Id, subscriberId= user));
                    }

               }
          }

          if(!deleteItems.isEmpty())
          {
               delete deleteItems;
          }

          if(!newItems.isEmpty())
          {
                Database.insert(newItems, false);
          }
     } 
}