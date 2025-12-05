@IsTest
private class SchedulerAndTriggerTest {
    
    @TestSetup
    static void setupTestData() {
        // Create a Maintenance Plan (Frequency in months)
        Maintenance_Plan__c plan = new Maintenance_Plan__c(
            Name = 'Quarterly Checkup',
            Frequency_Months__c = 3
        );
        insert plan;

        // Create a Customer Asset linked to the plan
        Customer_Asset__c asset = new Customer_Asset__c(
            //Name = 'CS-0012',
            Installation_Date__c = Date.today().addMonths(-12),  
            Maintenance_Plan__c = plan.Id,
            Last_Service_Date__c = Date.today().addMonths(-4),  
            Next_Service_Date__c = Date.today().addMonths(-1)   
        );
        insert asset;

        Customer_Asset__c asset2 = new Customer_Asset__c(
            Installation_Date__c = Date.today().addMonths(-6),
            Maintenance_Plan__c = plan.Id
        );
        insert asset2;
    }

    @isTest
    static void testCalculateNextServiceDate_NormalCase() {
        Date lastService = Date.newInstance(2025, 1, 15);
        Date expected = lastService.addMonths(6);
        Date result = MaintenanceSchedulerService.calculateNextServiceDate(lastService, 6);
        System.assertEquals(expected, result, 'Should add 6 months correctly');
    }

    @isTest
    static void testCalculateNextServiceDate_NullHandling() {
        Date result = MaintenanceSchedulerService.calculateNextServiceDate(null, 12);
        System.assertEquals(Date.today().addYears(1), result, 'Should default to 1 year from today');
        
        result = MaintenanceSchedulerService.calculateNextServiceDate(Date.today(), null);
        System.assertEquals(Date.today().addYears(1), result);
        
        result = MaintenanceSchedulerService.calculateNextServiceDate(Date.today(), 0);
        System.assertEquals(Date.today().addYears(1), result);
    }

    @isTest
    static void testCreateDueServiceAppointments_OverdueAndDueSoon() {
        Test.startTest();
        
        MaintenanceSchedulerService.createDueServiceAppointments();
        
        Test.stopTest();

        List<Service_Appointment__c> appointments = [
            SELECT Id, Scheduled_Date__c, Status__c, Asset__r.Name 
            FROM Service_Appointment__c 
            WHERE Status__c = 'Scheduled'
        ];
        
        
        System.assertEquals(2, appointments.size(), 'Two assets should have appointments created');

        List<Customer_Asset__c> updatedAssets = [
            SELECT Id, Name, Next_Service_Date__c, Last_Service_Date__c, Installation_Date__c,
                   Maintenance_Plan__r.Frequency_Months__c
            FROM Customer_Asset__c
        ];

        for (Customer_Asset__c a : updatedAssets) {
            Date expectedNext;
            Date baseDate = a.Last_Service_Date__c != null ? a.Last_Service_Date__c : a.Installation_Date__c;
            expectedNext = baseDate.addMonths((Integer)a.Maintenance_Plan__r.Frequency_Months__c);

            System.assertEquals(expectedNext, a.Next_Service_Date__c,
                'Next_Service_Date__c should be updated for asset: ' + a.Name);
        }
    }

    @isTest
    static void testMaintenanceSchedulerBatch() {
        Test.startTest();
        
        MaintenanceSchedulerBatch batchJob = new MaintenanceSchedulerBatch();
        Id jobId = System.schedule('Test Maintenance Scheduler', '0 0 2 * * ?', batchJob);
        
        Test.stopTest();

        List<Service_Appointment__c> apps = [SELECT Id FROM Service_Appointment__c];
        System.assert(apps.size() >= 1, 'Batch should have triggered appointment creation');
    }

    @isTest
    static void testServiceAppointmentTrigger_CompletionUpdatesLastServiceDate() {
        Customer_Asset__c asset = [SELECT Id FROM Customer_Asset__c LIMIT 1];
        
        Service_Appointment__c appt = new Service_Appointment__c(
            Asset__c = asset.Id,
            Scheduled_Date__c = Date.today(),
            Status__c = 'Scheduled'
        );
        insert appt;

        Test.startTest();
        
        appt.Status__c = 'Completed';
        update appt;
        
        Test.stopTest();

        Customer_Asset__c updatedAsset = [
            SELECT Last_Service_Date__c 
            FROM Customer_Asset__c 
            WHERE Id = :asset.Id
        ];
        
        System.assertEquals(Date.today(), updatedAsset.Last_Service_Date__c,
            'Last_Service_Date__c should be updated when appointment is completed');
    }

    @isTest
    static void testGetScheduledAppointments_LWCMethod() {
        Customer_Asset__c asset = [SELECT Id FROM Customer_Asset__c LIMIT 1];
        
        Service_Appointment__c appt1 = new Service_Appointment__c(
            Asset__c = asset.Id,
            Scheduled_Date__c = Date.today().addDays(5),
            Status__c = 'Scheduled'
        );
        Service_Appointment__c appt2 = new Service_Appointment__c(
            Asset__c = asset.Id,
            Scheduled_Date__c = Date.today().addDays(10),
            Status__c = 'In Progress'
        );
        insert new List<Service_Appointment__c>{appt1, appt2};

        Test.startTest();
        
        List<Service_Appointment__c> result = MaintenanceSchedulerService.getScheduledAppointments();
        
        Test.stopTest();

        System.assertEquals(2, result.size(), 'Should return Scheduled and In Progress appointments');
        System.assertEquals('Scheduled', result[0].Status__c); // Ordered by Scheduled_Date__c ASC
    }

    @isTest
    static void testNoDuplicateAppointmentsOnMultipleRuns() {
        // Run once
        MaintenanceSchedulerService.createDueServiceAppointments();
        
        Integer initialCount = [SELECT COUNT() FROM Service_Appointment__c];

        Test.startTest();
        MaintenanceSchedulerService.createDueServiceAppointments();
        Test.stopTest();

        Integer finalCount = [SELECT COUNT() FROM Service_Appointment__c];
        
        System.assertEquals(initialCount, finalCount,
            'Should not create duplicate appointments on subsequent runs');
    }
}