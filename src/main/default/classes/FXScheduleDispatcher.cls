global with sharing class FXScheduleDispatcher
{    
    //Seconds Minutes Hours Day_of_month Month Day_of_week optional_year
    // String CRON_EXP = '0 0 0 3 9 ? 2022';
    
    global static FXResult ScheduleJob(String theSchedulable, String sch)
    {
        
        Boolean isSuccess = false;
        String msg = '';
        if(UserInfo.getProfileId() != FXAppSettingsHandler.getSystemAdminProfileId()) 
        {
           msg = 'Only System Admin can run FXScheduleDispatcher';
        }
        else
        {
            Type t = Type.forName(theSchedulable);        
            if(t==null)
            {
                msg  = 'You may not have access to ' + theSchedulable + '; or it is not a valid class implementing Schedulable.';
            }
            else
            {
                try
                {            
                    Schedulable mySchedulable  = (Schedulable)t.newInstance();   
                    msg = System.schedule(theSchedulable + ' - ' + System.currentTimeMillis(), sch, mySchedulable);                      
                    isSuccess = true;
                }
                catch(System.TypeException ex)
                {
                     msg = theSchedulable + ' does not implement Schedulable, thus it could not be scheduled to run.';
                     isSuccess = false;
                } 
            }
        }
        FXResult r = new FXResult();
        r.Message = msg;
        r.IsSuccess = isSuccess;
        return r;
        
    }    
    
    global static FXResult ScheduleJobNow(String theSchedulable)
    {   
      
        //Seconds Minutes Hours Day_of_month Month Day_of_week optional_year
        // String CRON_EXP = '0 0 0 3 9 ? 2022';
    
        Datetime dt =Datetime.now().addSeconds(10);
        //System.debug(dt);
        String sch = String.format('{0} {1} {2} {3} {4} ? {5}',
             new String[]
             {
                        String.valueOf(dt.second()), 
                        String.valueOf(dt.minute()), 
                        String.valueOf(dt.hour()), 
                        String.valueOf(dt.day()), 
                        String.valueOf(dt.month()), 
                        String.valueOf(dt.year())
             });
        //System.debug(sch);


        return ScheduleJob(theSchedulable, sch);
    }    
    
}