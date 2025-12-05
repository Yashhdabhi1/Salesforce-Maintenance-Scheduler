# Salesforce Maintenance Scheduler & Service Calendar

Automated preventive maintenance solution built on Salesforce using **Apex**, **Batch/Scheduled jobs**, **Triggers**, and a **Lightning Web Component (LWC)** calendar.

This project manages **Customer Assets**, automatically creates **Service Appointments** based on a **Maintenance Plan**, and provides a visual **maintenance calendar** for users.

---

## 🧩 Key Features

- 🔁 **Automatic Maintenance Scheduling**
  - Calculates the next service date based on `Maintenance_Plan__c.Frequency_Months__c`
  - Creates `Service_Appointment__c` records for assets that are due or overdue

- 🧮 **Centralized Scheduling Logic**
  - `MaintenanceSchedulerService` encapsulates all maintenance scheduling rules
  - Reusable by batch jobs, schedulable classes, and future UI components

- 🕒 **Batch & Scheduled Execution**
  - `MaintenanceSchedulerBatch` can be scheduled to run daily/nightly
  - Ensures all assets are evaluated regularly for upcoming maintenance

- ✅ **Trigger-Driven Updates**
  - `ServiceAppointmentTrigger` + handler update the asset’s `Last_Service_Date__c`
    when a related service appointment is completed

- 📅 **LWC Maintenance Calendar**
  - `maintenanceCalendar` LWC displays planned service appointments in a calendar-like view
  - Built for extensibility (filtering, technician view, asset-level view, etc.)

- 🧪 **Automated Testing**
  - `SchedulerAndTriggerTest` covers:
    - Date calculation logic
    - Appointment creation
    - Batch execution
    - Trigger behavior
    - Idempotency (no duplicate appointments on multiple runs)

---
## 📸 Screenshots & Visual Overview

| **LWC: Maintenance Calendar (List/Calendar View)** | ![Maintenance Calendar]<img width="1882" height="777" alt="SSM" src="https://github.com/user-attachments/assets/7597389e-57d6-4519-b6ce-03fd74bcd64f" /> |
---


## 🏗️ Tech Stack

- **Platform**: Salesforce (Lightning Experience)
- **Language**: Apex
- **Frontend**: Lightning Web Components (LWC)
- **Metadata Format**: Salesforce DX (SFDX)
- **Testing**: Apex Test Classes (and Jest-ready structure for LWC)

---

## 📁 Project Structure

```text
.
├── .husky
├── .sf
├── .sfdx
├── .vscode
├── config/
├── force-app/
│   └── main/
│       └── default/
│           ├── applications/
│           ├── aura/
│           ├── classes/
│           │   ├── MaintenanceSchedulerBatch.cls
│           │   ├── MaintenanceSchedulerBatch.cls-meta.xml
│           │   ├── MaintenanceSchedulerService.cls
│           │   ├── MaintenanceSchedulerService.cls-meta.xml
│           │   ├── SchedulerAndTriggerTest.cls
│           │   ├── SchedulerAndTriggerTest.cls-meta.xml
│           │   ├── ServiceAppointmentTriggerHandler.cls
│           │   └── ServiceAppointmentTriggerHandler.cls-meta.xml
│           ├── contentassets/
│           ├── flexipages/
│           ├── layouts/
│           ├── lwc/
│           │   └── maintenanceCalendar/
│           │       ├── __tests__/
│           │       ├── maintenanceCalendar.css
│           │       ├── maintenanceCalendar.html
│           │       ├── maintenanceCalendar.js
│           │       └── maintenanceCalendar.js-meta.xml
│           ├── lwc/jsconfig.json
│           ├── objects/
│           ├── permissionsets/
│           ├── staticresources/
│           ├── tabs/
│           └── triggers/
│               ├── ServiceAppointmentTrigger.trigger
│               └── ServiceAppointmentTrigger.trigger-meta.xml
├── manifest/
├── scripts/
├── .forceignore
├── .gitignore
├── .prettierignore
├── .prettierrc
├── eslint.config.js
├── jest.config.js
├── package.json
├── README.md
└── sfdx-project.json
