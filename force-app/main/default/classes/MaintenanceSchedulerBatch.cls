public class MaintenanceSchedulerBatch implements Schedulable {

    /**
     * @description Entry point for the scheduled job.
     * @param sc The SchedulableContext.
     */
    public void execute(SchedulableContext sc) {
        // Call the main business logic method
        MaintenanceSchedulerService.createDueServiceAppointments();
    }
}