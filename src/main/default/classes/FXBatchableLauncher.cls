global with sharing class FXBatchableLauncher
{
    global static FXResult Run(String fxbatchableClassName, Map<String, Object> params)
    {
        return Run(fxbatchableClassName, params, false);
    }
    global static FXResult Run(String fxbatchableClassName, Map<String, Object> params, Boolean isDryRun)
    {
        Boolean isSuccess = false;
        String msg = '';

        Exception appException = null;

        Type t = Type.forName(fxbatchableClassName);        
        if(t==null)
        {
            msg  = 'You may not have access to ' + fxbatchableClassName + '; or it is not a valid class extending FXBatchableBase.';
        }
        else
        {
            try
            {            
                FXBatchableBase b = (FXBatchableBase)t.newInstance(); 
                b.SetParams(params);
                if(isDryRun)
                {
                    msg = 'You may use online html editor (https://html-online.com/editor/) to see the formatted msg. \r\n';
                    msg += b.DryRun();
                }
                else
                {
                    Database.executeBatch(b, 200);          
                }
                isSuccess = true;
            }
            catch(System.TypeException ex)
            {
                msg = fxbatchableClassName+ ' is not FXBatchableBase, thus it could not be run using FXBatchableLauncher';
                isSuccess = false;
                appException = ex;
            } 
        }

        FXResult r = new FXResult();
        r.Message = msg;
        r.IsSuccess = isSuccess;
        r.AppException = appException;
        return r;
    }

    global static FXResult Run(String fxbatchableClassName)
    {
        Boolean isSuccess = false;
        String msg = '';

        Exception appException = null;

        if(UserInfo.getProfileId() != FXAppSettingsHandler.getSystemAdminProfileId()) 
        {
           msg = 'Only System Admin can run FXBatchableLauncher';
        }
        else
        {
            Type t = Type.forName(fxbatchableClassName);        
            if(t==null)
            {
                msg  = 'You may not have access to ' + fxbatchableClassName + '; or it is not a valid class extending FXBatchableBase.';
            }
            else
            {
                try
                {            
                    Database.Batchable<sObject> b = (Database.Batchable<sObject>)t.newInstance(); 
                    Database.executeBatch(b, 200);          
                    isSuccess = true;
                }
                catch(System.TypeException ex)
                {
                     msg = fxbatchableClassName+ ' is not FXBatchableBase, thus it could not be run using FXBatchableLauncher';
                     isSuccess = false;
                     appException = ex;
                } 
            }
        }
        FXResult r = new FXResult();
        r.Message = msg;
        r.IsSuccess = isSuccess;
        r.AppException = appException;
        return r;
    }
}