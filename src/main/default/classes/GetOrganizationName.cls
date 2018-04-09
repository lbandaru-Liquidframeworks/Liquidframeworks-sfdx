@RestResource(urlMapping='/GetOrganizationName/*')
global with sharing class GetOrganizationName{
    @HttpGet
    global static String doPost() {
        String orgName = System.Userinfo.getOrganizationName();
        return orgName;
    }
}