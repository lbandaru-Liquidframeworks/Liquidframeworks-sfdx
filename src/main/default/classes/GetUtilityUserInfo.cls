@RestResource(urlMapping='/GetUtilityUserInfo/*')
global with sharing class GetUtilityUserInfo{
    @HttpGet
    global static String doPost() {
        string userinfo = UtilityUserInfo.CurrentUserInfo();
        return userinfo;
    }
}