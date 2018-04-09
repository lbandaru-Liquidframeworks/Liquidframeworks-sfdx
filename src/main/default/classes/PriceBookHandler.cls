public class PriceBookHandler
{
    public static void ResetGlobalPriceBooks(List<Price_Book__c> pbs)
    { 
        for(Price_Book__c pb: pbs)
        {               
            if(pb.Global_Price_Book__c ==true && pb.Is_Active__c == false) 
            {
               pb.Global_Price_Book__c = false;
            }            
        }
    }
    
    public static void EnforceCPQLicense(List<Price_Book__c> pbs)
    {
        if(Test.isRunningTest() || FXLicenseController.isCurrentUserLicensed('FXCPQ')) return;
       
        for(Price_Book__c pb : pbs)
        {
            if(String.isBlank(pb.Parent_Price_Book__c)) continue;            
            pb.addError('FXCPQ license is required to edit Price Book with Parent Price Book. The user does not have FXCPQ license. You may clear out Parent Price Book or contact the administrator.');            
        }
    }   
    
}