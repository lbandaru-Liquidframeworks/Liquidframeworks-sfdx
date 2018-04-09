trigger TriggerPriceBookItemServiceType on Price_Book_Item_Service_Type__c (before insert, before update, before delete) {
	FXLicenseController.EnforceCPQLicense();
}