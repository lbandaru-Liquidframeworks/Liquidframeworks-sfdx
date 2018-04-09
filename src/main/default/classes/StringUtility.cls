global class StringUtility {
   
    global static String newGuid() {

        String v = getHexString();               
        return (v.subString(0,8) + '-' + v.subString(8,12) + '-' + v.subString(12,16) + '-' + v.subString(16,20) + '-' + v.subString(20,32)).ToUpperCase();
    }
    
    global static Boolean isValidGuid(string guid)
    {
        return guidPattern.matcher(guid.toUpperCase()).matches();
    }
    
    static Pattern guidPattern = Pattern.compile('^[A-Z0-9]{8}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{12}$');
    
    global static void setSyncID(List<sObject> items, String syncIdFieldName)
    {
        for(sObject o : items)
        {
            if(!String.isBlank(String.valueOf(o.get(syncIdFieldName)))) continue;
            o.put(syncIdFieldName, newGuid());
        }
    }
    
    global static string getTrackingNumber(string prefix)
    {         
        String v = getHexString();           
        return prefix + v.subString(0,3) + '-' + v.subString(3,6) + '-' + v.subString(6,10) ;          
    }
    
    global enum EntityObjectType { Ticket, Job}
    
    global static Boolean isValidTrackingNumber(EntityObjectType entityType, string trackingNumber)
    {
        if(String.isBlank(trackingNumber)) return false;
        
        if(entityType == EntityObjectType.Job)
        {
            return jobPattern.matcher(trackingNumber).matches();
        }
        return tktPattern.matcher(trackingNumber).matches();     
    }
    static Pattern jobPattern = Pattern.compile('J-[A-F0-9]{3}-[A-F0-9]{3}-[A-F0-9]{4,5}');
    static Pattern tktPattern = Pattern.compile('T-[A-F0-9]{3}-[A-F0-9]{3}-[A-F0-9]{4,5}');
    
    
    private static string getHexString()
    {
        String seed = UserInfo.getUserId() +  string.valueof(System.now().getTime()) + EncodingUtil.ConvertTohex(Crypto.GenerateAESKey(128));         
        Blob bsig = Crypto.generateDigest('SHA1', Blob.valueOf(seed));
        return EncodingUtil.convertToHex(bsig).toUpperCase();         
    }
    
    global static String GetTypeName(Id objId) 
    { 
        return objId.getSobjectType().getDescribe().getName();       
    } 
    global static String FXNamespace() 
    { 
        return SObjectType.Job__c.Name.replace('Job__c', '');        
    } 

    global static String FXNamespacePrefix()
    {
        return FXNamespace().replace('__', '');
    }

    public static String GetSObjectPrefix(Id objId)
    {
        return String.isBlank(objId)? '' : String.valueOf(objId).substring(0, 3);
    }

    public static String GetJoinedString(List<Id> ids)
    {
        return GetJoinedString(ids, ',');
    }

    public static String GetJoinedString(Set<Id> ids)
    {
        return GetJoinedString(new List<Id>(ids), ',');
    }

    public static String GetJoinedString(List<Id> ids, String sep)
    {
        return GetJoinedString(ids, sep, true);
    }

    public static String GetJoinedString(Set<Id> ids, String sep)
    {
        return GetJoinedString(new List<Id>(ids), sep, true);
    }

    public static String GetJoinedString(Set<Id> ids, String sep, Boolean withSingleQuote)
    {
        return GetJoinedString(new List<Id>(ids), sep, withSingleQuote);
    }

    public static String GetJoinedString(List<Id> ids, String sep, Boolean withSingleQuote)
    {
        return withSingleQuote ? 
                    '\'' + String.join(ids, '\'' + sep + '\'') + '\''
                    : String.join(ids, sep);
    }

    public static String GetCasesafeId(string idStr)
    {
        Id idObj = idStr;
        return String.valueOf(idObj);
    }

    public static String GetCasesafeId(Id idStr)
    {
        return String.valueOf(idStr);
    }


    public static Boolean IsValidId(String str)
    {
        try{
            return !String.isBlank(str) && Id.valueOf(str)!=null;
        }
        catch(Exception ex)
        {
            return false;
        }
    }

    public static Set<String> GetSobjectFields(String str)
    {
        System.debug(str);
        //String str = 'Job__r.Ticket__r.multiTest__c=\'testStr\' AND Tracking_Number__c!=null AND Account__r.Name!=null AND RecordType.Name=\'Labor\')';
        String funcreg = '(?i)(([\\w]+__r[\\.])*([\\w]+)__c)|([\\w]+__r[\\.])+([\\w]+)|([\\w]+[\\.])+([\\w]+)';
        Pattern funcPattern = Pattern.compile(funcreg);
        Matcher fm = funcPattern.matcher(str);
        Set<String> results = new Set<String>();
        while(fm.find())
        {
            //System.debug(fm.groupCount());
            //for(Integer i=0; i<fm.groupCount(); i++)
            //System.debug('group ' + i + ' : ' + fm.group(i));
            results.add(fm.group(0));
        }
        return results;

    }

}