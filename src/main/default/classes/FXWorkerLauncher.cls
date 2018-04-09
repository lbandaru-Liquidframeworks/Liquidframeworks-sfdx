@RestResource(urlMapping='/FXWorkerLauncher/*')
global with sharing class FXWorkerLauncher
{
    @HttpPost
    global static SvcResult DoWork(String service, String jsonParams)
    {
        Map<String, String> params = (String.isBlank(jsonParams))? new Map<String, String>() 
            :(Map<String, String>)JSON.deserialize(jsonParams, Type.forName('Map<String, String>'));
        if(!String.isBlank(service))
        {
            params.put('service', service);
        }
        return Run(params);
    }

    public static SvcResult Run(String jsonParams)
    {
        return Run((Map<String, String>)JSON.deserialize(jsonParams, Type.forName('Map<String, String>'))); 
    }

    static SvcResult Run(Map<String, String> params)
    {
        String svcClassName = params.get('service');
        Type t = Type.forName(svcClassName);    
        
        SvcResult f = null;
        if(t==null)
        { 
            f =  new SvcResult(false,  null, 'You may not have access to ' + svcClassName);            
        }
        else
        {
            try
            {            
                IFXWorker w = (IFXWorker)t.newInstance();  
                f = w.DoWork(JSON.serialize(params));
            }
            catch(System.Exception ex)
            {
                f = new SvcResult( false, null, ex.getMessage() + ' | stackTrace: ' + ex.getStackTraceString());
            }   
        }
        return f;
    }
}
