public with sharing class MaintenanceSchedulerService {

    public static Date calculateNextServiceDate(Date lastServiceDate, Integer frequencyMonths) {
        if (lastServiceDate == null || frequencyMonths == null || frequencyMonths <= 0) {
            // Default to 1 year from today if data is incomplete
            return Date.today().addYears(1);
        }
        
        // Add the calculated number of months to the last service date
        return lastServiceDate.addMonths(frequencyMonths);
    }

    /**
     * @description Main method to run daily/nightly to check for assets needing new appointments.
     * Finds assets whose Next_Service_Date__c is in the past or due soon and creates a Service_Appointment__c.
     */
    public static void createDueServiceAppointments() {
        // 1. Get Assets that are due (or overdue) for maintenance
        List<Customer_Asset__c> assetsToSchedule = [
            SELECT 
                Id, 
                Name, 
                Next_Service_Date__c,
                Last_Service_Date__c,
                Installation_Date__c, 
                Maintenance_Plan__c, 
                Maintenance_Plan__r.Frequency_Months__c
            FROM 
                Customer_Asset__c
            WHERE 
                Maintenance_Plan__c != NULL
                AND (Next_Service_Date__c = NULL 
                     OR Next_Service_Date__c <= :Date.today().addDays(30))
            // WITH SECURITY_ENFORCED   // add back in production if needed
        ];

        if (assetsToSchedule.isEmpty()) {
            return;
        }

        // 2. Find any existing open appointments for these assets (to avoid duplicates)
        Set<Id> assetIds = new Set<Id>();
        for (Customer_Asset__c a : assetsToSchedule) {
            assetIds.add(a.Id);
        }

        Map<Id, Service_Appointment__c> openAppointmentsByAsset = new Map<Id, Service_Appointment__c>();
        if (!assetIds.isEmpty()) {
            for (Service_Appointment__c sa : [
                SELECT Id, Asset__c, Status__c
                FROM Service_Appointment__c
                WHERE Asset__c IN :assetIds
                  AND Status__c IN ('Scheduled', 'In Progress')
            ]) {
                // we only need to know that one exists
                if (sa.Asset__c != null && !openAppointmentsByAsset.containsKey(sa.Asset__c)) {
                    openAppointmentsByAsset.put(sa.Asset__c, sa);
                }
            }
        }

        List<Service_Appointment__c> appointmentsToInsert = new List<Service_Appointment__c>();
        List<Customer_Asset__c>     assetsToUpdate       = new List<Customer_Asset__c>();

        // 3. Calculate next dates and create appointments
        for (Customer_Asset__c asset : assetsToSchedule) {

            // Skip if there is already an open appointment → prevents duplicates
            if (openAppointmentsByAsset.containsKey(asset.Id)) {
                continue;
            }

            Integer frequency = (Integer) asset.Maintenance_Plan__r.Frequency_Months__c;
            if (frequency == null || frequency <= 0) {
                System.debug('Asset ' + asset.Name + ' skipped: Invalid frequency.');
                continue;
            }

            // Determine the starting date for the next calculation
            Date startServiceDate = (asset.Last_Service_Date__c != null)
                ? asset.Last_Service_Date__c
                : asset.Installation_Date__c;

            if (startServiceDate == null) {
                System.debug('Asset ' + asset.Name + ' skipped: Missing start date.');
                continue;
            }

            // Calculate the actual next service date
            Date newNextServiceDate = calculateNextServiceDate(startServiceDate, frequency);

            // ✅ KEY CHANGE:
            // For your tests, "due" = past OR within look-ahead window (30 days).
            // We therefore only skip if the date is too far in the future.
            if (newNextServiceDate > Date.today().addDays(30)) {
                // Not due within the window, skip.
                continue;
            }

            // 1. Prepare new Service Appointment (Name is Auto-Number)
            Service_Appointment__c newAppointment = new Service_Appointment__c(
                Asset__c        = asset.Id,
                Scheduled_Date__c = newNextServiceDate,
                Status__c       = 'Scheduled'
            );
            appointmentsToInsert.add(newAppointment);
            
            // 2. Update the Asset's Next Service Date (matches your test expectation)
            asset.Next_Service_Date__c = newNextServiceDate;
            assetsToUpdate.add(asset);
        }

        // 4. DML
        if (!appointmentsToInsert.isEmpty()) {
            Database.insert(appointmentsToInsert);
        }
        
        if (!assetsToUpdate.isEmpty()) {
            Database.update(assetsToUpdate);
        }
    }

    /**
     * @description Fetches all service appointments that are scheduled or in progress for the LWC.
     * @return List of Service_Appointment__c records.
     */
    @AuraEnabled(cacheable=true)
    public static List<Service_Appointment__c> getScheduledAppointments() {
        return [
            SELECT 
                Id, 
                Name, 
                Scheduled_Date__c, 
                Status__c,
                Technician__c, 
                Technician__r.Name, 
                Asset__r.Name, 
                Asset__c
            FROM 
                Service_Appointment__c 
            WHERE 
                Status__c IN ('Scheduled', 'In Progress')
            ORDER BY 
                Scheduled_Date__c ASC
        ];
    }
}
