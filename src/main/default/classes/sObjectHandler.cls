public class sObjectHandler
{
    public static void InitTrackingNumber(String prefix, List<sObject> items)
    {
        if(!String.isBlank(prefix) && !prefix.endsWith('-'))
        {
            prefix = prefix + '-';
        }

        String fName = StringUtility.FXNamespace() + 'Tracking_Number__c';
        for(sObject o : items)
        {
            object fValue = o.get(fName);
            if(fValue==null || String.isBlank(String.valueOf(fValue)))
            {
                o.put(fName, StringUtility.getTrackingNumber(prefix));
            }
        }
    }
}