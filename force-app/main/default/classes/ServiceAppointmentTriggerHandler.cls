public with sharing class ServiceAppointmentTriggerHandler {
	public static void handleCompletedAppointment(List<Service_Appointment__c> newList, Map<Id, Service_Appointment__c> oldMap) {
        
        Set<Id> assetIdsToUpdate = new Set<Id>();
        
        for (Service_Appointment__c newAppointment : newList) {
            Service_Appointment__c oldAppointment = oldMap.get(newAppointment.Id);
            
            // Check if status changed TO 'Completed' and the Asset field is populated
            if (newAppointment.Status__c == 'Completed' && 
                oldAppointment.Status__c != 'Completed' && 
                newAppointment.Asset__c != null) 
            {
                assetIdsToUpdate.add(newAppointment.Asset__c);
            }
        }
        
        if (!assetIdsToUpdate.isEmpty()) {
            List<Customer_Asset__c> assetsToUpdate = new List<Customer_Asset__c>();
            
            // Query for the assets to ensure we only update the fields needed
            for (Customer_Asset__c asset : [SELECT Id FROM Customer_Asset__c WHERE Id IN :assetIdsToUpdate /*WITH SECURITY_ENFORCED*/]) {
                // Update the Last_Service_Date__c to today's date
                asset.Last_Service_Date__c = Date.today();
                assetsToUpdate.add(asset);
            }
            
            if (!assetsToUpdate.isEmpty()) {
                Database.update(assetsToUpdate);
            }
        }
    }
}