global with sharing class MixPanelTracking
{
    global static void TrackEvent(String eventName, Integer itemCount)
    {   
        TrackEvent(eventName, itemCount, true);
    }   

    public static void TrackEvent(String eventName, Integer itemCount, Boolean asyncMode)
    {   
        if(System.isBatch() || System.isFuture()) return;
        TrackEventInternal(eventName, itemCount, Test.isRunningTest(), asyncMode);
    }  

    public static void TrackEvent(String objName, Boolean isInsert, Integer itemCount)
    {           
        String eventName = objName.removeEndIgnoreCase('__c').replace('_', '').trim() 
            + (isInsert? 'Created' : 'Edited');
        TrackEvent(eventName, itemCount, true);
    }  

    static void TrackEventInternal(String eventName, Integer itemCount, Boolean isTest, Boolean asyncMode)
    {
        FX_Settings__c fxSetting = FX_Settings__c.getOrgDefaults();
        if(String.isBlank(fxSetting.MixPanelSecurityToken__c))
        {
            fxSetting.MixPanelSecurityToken__c = 'dfe456579c77b0bd5fec94f106e0e094';            
            Database.UpsertResult result = Database.upsert(fxSetting, false);
            if(!result.isSuccess())
            {
                for(Database.Error r : result.getErrors())
                {
                    System.debug(r.getMessage());
                }
            }
        }
        if(fxSetting.MixPanelStopTracking__c || isTest) return;

        try
        {
            if(asyncMode)
            {
                SendTrackEventAsync(eventName, itemCount, fxSetting.MixPanelSecurityToken__c);
            }
            else
            {
                SendTrackEvent(eventName, itemCount, fxSetting.MixPanelSecurityToken__c);
            }
        }
        catch(System.LimitException ex)
        {
        }
    }   

    static void SendTrackEvent(String eventName, Integer itemCount, String mixpanelToken)
    {       
        UpsertMixPanelUserProfile(mixpanelToken, true);
        for(HttpRequest request : GetHttpRequests(eventName, itemCount, mixpanelToken))
        {
            (new Http()).send(request);         
        }       
    }


    @future(callout=true)
    static void SendTrackEventAsync(String eventName, Integer itemCount, String mixpanelToken)
    {       
        SendTrackEvent(eventName, itemCount, mixpanelToken);
    }

    static List<HttpRequest> GetHttpRequests(String eventName, Integer itemCount, 
        String mixpanelToken)   
    {
        List<HttpRequest> requests = new List<HttpRequest>();       
        String userName = UserInfo.getUserName();
        String email = UserInfo.getUserEmail();
        String orgName = UserInfo.getOrganizationName();
        String officeName = '';
        
        Id userId = UserInfo.getUserId();
        for (Contact c : [SELECT Office__c, Office__r.Name, User__r.Phone FROM Contact where User__c = :userId LIMIT 1]) {
            if (c.Office__r != null) {
                officeName = c.Office__r.Name;
            }
        }
        
        Integer maxBatchSize = 50;

        Integer batches = (Integer)Math.ceil(1.0 * itemCount/maxBatchSize);
        Integer batchSize = itemCount>maxBatchSize ? maxBatchSize : itemCount;

        Integer index = 0;

        Long timestamp = Datetime.now().getTime();      

        String eventEntry = GetEventDataBase64String(eventName, timestamp, mixpanelToken, userName, email, orgName, officeName);        

        for(Integer b=0; b<batches; b++)
        {
            String data = '';
            String sep='';
            for(Integer i=0; i<batchSize; i++)
            {
                index = b*batchSize+i;
                if(index == itemCount) break;
                data += sep + eventEntry;
                sep = ',';
            }
            if(batchSize>1)
            {
                data = '[' + data + ']';
            }                       
            HttpRequest req = new HttpRequest();
            req.setEndpoint('https://api.mixpanel.com/track/');
            req.setMethod('POST');
            req.setBody('data=' + EncodingUtil.base64Encode(Blob.valueOf(data)));
            requests.add(req);
        }       
        return requests;
    }

    
    static void UpsertMixPanelUserProfile(String mixpanelToken, Boolean sendRequest)
    {
        String profileInfo = '"$first_name":"' + UserInfo.getFirstName() + '",';
        profileInfo += '"$last_name":"' + UserInfo.getLastName() + '",'; 
        profileInfo += '"$email":"' + UserInfo.getUserEmail() + '"'; 

        String profile = '{';
        profile += '"$token": "' + mixpanelToken +'",';
        profile += '"$distinct_id": "' + UserInfo.getUserName() +'",';          
        profile += '"$set_once":{' + profileInfo +'}';
        profile += '}';     
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://api.mixpanel.com/engage/');
        req.setMethod('POST');
        req.setBody('data=' + EncodingUtil.base64Encode(Blob.valueOf(profile)));
        
        if(!sendRequest) return;
        (new Http()).send(req); 
    }   


    static String GetEventDataBase64String(String eventName, 
        Long timestamp, 
        String mixPanelToken, 
        String userName,
        String email,
        String orgName,
        String officeName)
    {
        String values = '"token": "' + mixPanelToken +'"';      
        values += ',"distinct_id": "' + userName +'"';
        values += ',"username": "' + userName +'"';
        values += ',"email": "' + email +'"';
        values += ',"organization": "' + orgName +'"';
        values += ',"office": "' + officeName +'"';
        if(timestamp>0)
        {
            values += ',"time":' + timestamp;
        }
        values += ',"source": "BackOffice"';
        return '{"event":"' + eventName + '","properties": {' + values + '}}';
    }   

    global static void UnitTestCodeCoverage()
    {
        UpsertMixPanelUserProfile('2dfda2ed5f89cad8424eebb79887e2a5', false);
        GetHttpRequests('UnitTestEvent', 169, '2dfda2ed5f89cad8424eebb79887e2a5');
        TrackEventInternal('UnitTestEvent', 169, true, true);
    }
}
