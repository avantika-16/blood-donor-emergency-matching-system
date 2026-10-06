# Blood Donor Emergency Matching System

A web-based application designed to help hospitals find suitable blood donors during emergency situations. The system matches donors based on blood group compatibility, eligibility, and location.

## Features

- Donor registration
- Hospital registration
- Blood request management
- Blood group compatibility matching
- Donor eligibility checking
- Location-based donor matching using Haversine distance
- Match scoring and ranking
- Donor notification system
- Hospital dashboard
- Microsoft SQL Server database integration

## Technologies Used

- Python
- Flask
- Microsoft SQL Server
- pyodbc
- HTML
- CSS
- Git & GitHub

## How It Works

1. Donors register their details and blood group.
2. Hospitals register and submit blood requirements.
3. The system checks blood group compatibility and donor eligibility.
4. Suitable donors are identified based on location and matching score.
5. Matching results are displayed to the hospital.
6. Donors can receive notifications for emergency blood requests.

## Project Structure

```text
blood-donor-emergency-matching-system/
│
├── app.py
├── database.py
├── matching.py
├── notification.py
├── schema.sql
│
├── database/
│   └── schema.sql
│
└── templates/
    ├── index.html
    ├── donor_register.html
    ├── hospital_register.html
    ├── hospital_dashboard.html
    ├── blood_request.html
    ├── matches.html
    └── donor_notifications.html

