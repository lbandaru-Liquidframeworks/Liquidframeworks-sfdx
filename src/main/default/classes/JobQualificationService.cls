public with sharing class JobQualificationService implements IFXWorker
{
    public static SvcResult Run(String jsonParams)
    {
        Map<String, String> params = (Map<String, String>)JSON.deserialize(jsonParams, Type.forName('Map<String, String>'));
        return Run(params);
    }

    public static SvcResult Run(Map<String, String> params)
    {
        JobQualificationService s = new JobQualificationService();
        return s.DoWork(params);
    }

    public virtual SvcResult DoWork(String jsonParams)
    {
        Map<String, String> params = (Map<String, String>)JSON.deserialize(jsonParams, Type.forName('Map<String, String>'));
        return DoWork(params);             
    }

    public virtual SvcResult DoWork(Map<String, String> params)
    {
        SvcResult r = new SvcResult();      
        try
        {
            String method = params.get('method').toLowercase();
            String msg = '';
            String result = '';
            Boolean isSuccess = true;

            if(method =='getjobqualifications')
            {
                Id jobId = Id.valueOf(params.get('jobId'));
                Set<JobQualificationHandler.ResultItem> items = JobQualificationHandler.GetJobQualifications(jobId);
                result = JSON.serialize(items);
            }
            else if(method == 'getqualifiedcontacts')
            {
                Id jobId = Id.valueOf(params.get('jobId'));
                Set<Id> items = JobQualificationHandler.GetQualifiedContacts(jobId);
                result = JSON.serialize(items);

            }
            else if(method == 'getqualifiedequipment')
            {
                Id jobId = Id.valueOf(params.get('jobId'));
                Set<Id> items = JobQualificationHandler.GetQualifiedEquipment(jobId);
                result = JSON.serialize(items);
            }
            else if(method == 'getqualifieditems')
            {
                String qIds = params.get('qualificationIds');
                Set<Id> qualificationIds = new Set<Id>();
                for(String str : qIds.split(','))
                {
                    qualificationIds.add(Id.valueOf(str));
                }

                String dateStr = params.get('startDate').replace('T', ' ');
                Date startDate = dateStr.contains(':')?Datetime.valueOf(dateStr).date() : Date.valueOf(dateStr);
                dateStr = params.get('endDate').replace('T', ' ');
                Date endDate = dateStr.contains(':')?Datetime.valueOf(dateStr).date() : Date.valueOf(dateStr); 

                Set<Id> qualifiedItems = JobQualificationHandler.GetQualifiedItems(qualificationIds, startDate, endDate);
                result = JSON.serialize(qualifiedItems);
            }   
            else
            {
                msg = 'unknown method: ' +  params.get('method');
                isSuccess = false;
            }     
            r.IsSuccess= isSuccess;
            r.Result = result;
            r.Message = msg;
        }
        
       catch(Exception ex)
        {
            r.IsSuccess = false;
            r.Result = null;
            r.Message = ex.getMessage() + ' | stackTrace: ' + ex.getStackTraceString();
            System.debug(ex);
        }     
       
        return r;     
    }
    
}