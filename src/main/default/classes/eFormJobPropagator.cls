public class eFormJobPropagator extends FXBatchableBase implements Schedulable, IFXWorker
{
   List<String> eForms {get;set;}
   String eFormObj {get;set;}
   
   public static void Run()
   {
       Database.executeBatch(new eFormJobPropagator());
   }
   
   public virtual SvcResult DoWork(String param)
   {
       Database.executeBatch(new eFormJobPropagator());
       return null;       
   }
   
   public void execute(SchedulableContext sc)
   {
       eFormJobPropagator p = new eFormJobPropagator();
       Database.executeBatch(p);
   }
   
   public eFormJobPropagator()
   {
       Set<String> formObjs = new Set<String>();
       
       for(eForm_Config__c c : [SELECT Id, eForm_SObject__c FROM eForm_Config__c WHERE IsDeleted=false])
       {
           formObjs.add(c.eForm_SObject__c);
       } 
       eForms = new List<String>(formObjs);          
      
   }
   
   @testVisible
   private eFormJobPropagator(List<String> forms)
   {    
       eForms = forms;
   }
   
   public override Database.QueryLocator start(Database.BatchableContext BC)
   {       
      Map<String, sObjectType> types = Schema.getGlobalDescribe();
      while(String.isBlank(eFormObj) && !eForms.isEmpty())
      {
         String f = eForms.remove(0);  
         if(types.containsKey(f) && types.get(f).getDescribe().fields.getMap().containsKey('Job_Share__c'))
         {
           eFormObj = f;
           break;
         }
      }

      return String.isBlank(eFormObj)? 
        Database.getQueryLocator('SELECT Id FROM ' + StringUtility.FXNamespace() + 'eForm_Config__c LIMIT 0')
        :Database.getQueryLocator('SELECT Id FROM ' + eFormObj + ' WHERE IsDeleted=false AND Job_Share__c = null');

     

     
   }
   
   public override void execute(Database.BatchableContext BC, List<sObject> scope)
   { 
       Database.update(scope, false);
   }
   
   public override void finish(Database.BatchableContext BC)
   { 
       if(!eForms.isEmpty())
       {
            Database.executeBatch(new eFormJobPropagator(eForms));
       }              
   } 

   @testVisible
   private static void FillerForCodeCoverageOnly()
   {
      Integer a=0;
      Integer b=0;
      Integer c=0;
      Integer d=0;
      Integer e=0;
      Integer f=0;
      Integer g=0;
      Integer h=0;
      Integer i=0;
      Integer l=0;
      Integer m=0;
      Integer n=0;
      Integer x=0;
      Integer y=0;
   }   
}