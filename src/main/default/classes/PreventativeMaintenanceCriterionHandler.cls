public class PreventativeMaintenanceCriterionHandler
{
    public static void UpdateNextRunForRecurringPMC(List<Preventative_Maintenance_Criterion__c> pmcItems)
    {
        Datetime now = Datetime.now();
        for(Preventative_Maintenance_Criterion__c c : pmcItems)
        {
            if(c.Effective_Date__c!=null && c.Effective_Date__c > now || c.Expiration_Date__c !=null && c.Expiration_Date__c< now) continue;
            if(c.Evaluation_Timestamp__c == null) continue;
            if(c.Calender_Interval__c== null || c.Calender_UOM__c == null) continue;
            
            Integer interval= (Integer)c.Calender_Interval__c;
            
            if(c.Calender_UOM__c == 'Year')
            {
                c.Next_Run__c = c.Evaluation_Timestamp__c.addYears(interval);
            }
            else if(c.Calender_UOM__c == 'Month')
            {
                c.Next_Run__c = c.Evaluation_Timestamp__c.addMonths(interval);
            }
            else if(c.Calender_UOM__c == 'Day')
            {
                c.Next_Run__c = c.Evaluation_Timestamp__c.addDays(interval);
            }
            else if(c.Calender_UOM__c == 'Hour')
            {
                c.Next_Run__c = c.Evaluation_Timestamp__c.addHours(interval);
            }
            else if(c.Calender_UOM__c == 'Minute')
            {
                c.Next_Run__c = c.Evaluation_Timestamp__c.addMinutes(interval);
            }   
            
        }
    }
}