trigger ServiceAppointmentTrigger on Service_Appointment__c (after update) {
    if (Trigger.isAfter && Trigger.isUpdate) {
        // Delegate logic to the handler
        ServiceAppointmentTriggerHandler.handleCompletedAppointment(Trigger.new, Trigger.oldMap);
    }
}