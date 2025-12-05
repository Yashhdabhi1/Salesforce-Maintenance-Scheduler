import { LightningElement, wire } from 'lwc';
import getScheduledAppointments from '@salesforce/apex/MaintenanceSchedulerService.getScheduledAppointments';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class MaintenanceCalendar extends LightningElement {
    appointmentsByDate = [];
    wiredAppointmentsResult;
    isLoading = true; 
    error;

    // Map status to a color for visual grouping
    statusColors = {
        'Scheduled': 'slds-theme_alt-inverse',
        'In Progress': 'slds-theme_warning',
        'Completed': 'slds-theme_success', 
        'Canceled': 'slds-theme_error'
    };

    get hasAppointments() {
        return this.appointmentsByDate && this.appointmentsByDate.length > 0;
    }

    get showEmptyState() {
        return !this.isLoading && !this.hasAppointments;
    }

    @wire(getScheduledAppointments)
    wiredAppointments(result) {
        this.wiredAppointmentsResult = result;
        const { data, error } = result;
        this.isLoading = true; 

        if (data) {
            this.processAppointments(data);
            this.isLoading = false;
        } else if (error) {
            // Serialize error for better debugging in the console
            this.error = JSON.stringify(error, null, 2); 
            this.appointmentsByDate = [];
            this.isLoading = false;
            console.error('Error fetching appointments:', this.error);
            this.showToast('Error', 'Failed to load maintenance schedule. Check browser console for full details.', 'error');
        }
    }

    /**
     * Group appointments by scheduled date for agenda view.
     */
    processAppointments(appointments) {
        const dateGroups = new Map();

        appointments.forEach(appt => {
            // Safely retrieve cross-object fields
            const technicianName = appt.Technician__r ? appt.Technician__r.Name : 'Unassigned';
            const assetName = appt.Asset__r ? appt.Asset__r.Name : 'N/A';
            
            const scheduledDate = appt.Scheduled_Date__c;
            const formattedDate = new Date(scheduledDate).toLocaleDateString(undefined, {
                weekday: 'long',
                year: 'numeric',
                month: 'long',
                day: 'numeric'
            });

            const displayItem = {
                Id: appt.Id,
                Name: appt.Name,
                Asset_Name: assetName,
                Technician_Name: technicianName,
                Status: appt.Status__c,
                Status_Class: this.statusColors[appt.Status__c] || 'slds-theme_default',
                Link: `/lightning/r/Service_Appointment__c/${appt.Id}/view`
            };

            if (!dateGroups.has(formattedDate)) {
                dateGroups.set(formattedDate, []);
            }
            dateGroups.get(formattedDate).push(displayItem);
        });

        // Convert Map to Array for lightning:iterator
        this.appointmentsByDate = Array.from(dateGroups, ([date, appointments]) => ({
            date,
            appointments,
            // Check if date matches today's date string
            isToday: date === new Date().toLocaleDateString(undefined, { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' })
        }));
    }

    handleRefresh() {
        this.isLoading = true;
        // Refresh the wire service cache
        refreshApex(this.wiredAppointmentsResult).then(() => {
             this.isLoading = false;
             this.showToast('Success', 'Schedule refreshed.', 'success');
        }).catch(error => {
            console.error('Refresh Error:', error);
            this.showToast('Error', 'Failed to refresh schedule.', 'error');
            this.isLoading = false;
        });
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(event);
    }
}