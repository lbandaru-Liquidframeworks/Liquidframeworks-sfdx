@isTest
private class UtilityUserInfoTests
{
   static testMethod void runTest() 
   { 
       string namespace = UtilityUserInfo.CurrentUserInfo();

       string userInfo = UtilityUserInfo.CurrentUserInfoEscaped();
       
   }
}