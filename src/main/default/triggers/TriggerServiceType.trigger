trigger TriggerServiceType  on Service_Type__c (before insert, before update, before delete) {

	FXLicenseController.EnforceCPQLicense();
}