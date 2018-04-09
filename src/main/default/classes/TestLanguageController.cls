@isTest
private class TestLanguageController {

    static testMethod void positiveLanguageControllerTest() {

       ApexPages.StandardController stdCtlr;

       //Instantiate and construct the controller class.  
       LanguageController controller = new LanguageController(stdCtlr);

       System.assertEquals(controller.userLanguage, UserInfo.getLanguage());        
       System.assertEquals(controller.userLocale, UserInfo.getLocale());        
       System.assertEquals(controller.userCurrency, UserInfo.getDefaultCurrency());        
   
    }
}