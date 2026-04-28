# AttendStore

A full-featured **Attendance Management System** built with Flutter and Firebase. AttendStore supports two distinct user roles — **Admin** and **Employee** — and provides QR code-based check-in/check-out with geolocation verification, leave management, PDF report export, company policy publishing, and more.

---

## Table of Contents

1. [Features](#features)
2. [Tech Stack](#tech-stack)
3. [Project Structure](#project-structure)
4. [Screens & Navigation](#screens--navigation)
5. [Firestore Database Schema](#firestore-database-schema)
6. [Getting Started](#getting-started)
7. [Firebase Setup](#firebase-setup)
8. [Dependencies](#dependencies)
9. [Contributing](#contributing)

---

## Features

### Admin
| Feature | Description |
|---|---|
| **Employee Master** | View, add, edit, and deactivate employee records |
| **Attendance** | View and manage attendance records for all employees; export to PDF |
| **QR Code Generator** | Generate daily check-in / check-out QR codes tied to an office location |
| **Leave Management** | Review, approve, or reject employee leave requests |
| **Leave Calendar** | View and manage public holidays and company leave calendar |
| **Company Policies** | Create and publish company policy documents visible to all staff |
| **Codes Config** | Manage configurable codes such as leave types, designations, and office locations |

### Employee
| Feature | Description |
|---|---|
| **Dashboard** | Personalised welcome with live weather widget and leave calendar |
| **QR Check-In / Check-Out** | Scan admin-generated QR codes to mark attendance; validates date, security key, and GPS location |
| **Attendance History** | View personal attendance records by date |
| **Leave Request** | Submit leave applications with type, date range, and reason |
| **Company Policies** | Read-only view of policies published by admin |

### General
- **Role-based routing** — users are redirected to the correct dashboard on login
- **Persistent login** — session is stored via `SharedPreferences`; no re-login required on app restart
- **Forgot password** — dedicated password reset flow
- **Light / Dark / System theme** — user preference saved and migrated automatically
- **Responsive UI** — adaptive grid layouts for phone, tablet, and web

---

## Tech Stack

| Layer | Technology |
|---|---|
| UI Framework | [Flutter](https://flutter.dev) (Dart) |
| Backend / Database | [Firebase Firestore](https://firebase.google.com/products/firestore) |
| Authentication | [Firebase Auth](https://firebase.google.com/products/auth) |
| State Management | `InheritedWidget` / `provider` |
| QR Codes | `qr_flutter` (generate) · `mobile_scanner` (scan) |
| Geolocation | `geolocator` |
| PDF Export | `pdf` + `printing` |
| Weather | [WeatherAPI](https://www.weatherapi.com) via `http` |
| Local Storage | `shared_preferences` |
| Date / Locale | `intl` |

---

## Project Structure

```
lib/
├── main.dart                  # App entry point, theme handling, auth check
├── firebase_options.dart      # Auto-generated Firebase config
│
├── admin/
│   ├── admin_dashboard.dart           # Admin home with feature grid
│   ├── codes_config_screen.dart       # Manage leave types, designations, office locations
│   ├── employee_master_screen.dart    # CRUD for employee records
│   └── qr_code_generator_screen.dart  # Generate daily QR codes
│
├── employee/
│   ├── apply_leave_screen.dart         # Submit leave request
│   ├── employee_dashboard.dart         # Employee home
│   └── employee_qr_checkin_screen.dart # Scan QR → verify → record attendance
│
└── common/
    ├── attendance_screen.dart          # Attendance list (shared, role-aware)
    ├── forgot_password_screen.dart
    ├── leave_calendar_screen.dart      # Holiday calendar (admin can edit)
    ├── leave_management_screen.dart    # Leave approvals (admin)
    ├── login_screen.dart
    ├── policies_screen.dart            # Policy CRUD / viewer
    ├── profile_screen.dart
    │
    ├── models/
    │   ├── database_schema.dart        # Firestore schema documentation & sample queries
    │   ├── policy_model.dart
    │   └── user_model.dart
    │
    ├── services/
    │   ├── auth_service.dart           # Firebase Auth + Firestore user management
    │   └── pdf_generator_service.dart  # PDF generation for attendance export
    │
    ├── theme/
    │   └── app_theme.dart             # Light & dark MaterialTheme definitions
    │
    └── widgets/
        ├── app_drawer.dart             # Side navigation drawer
        ├── leave_calendar_widget.dart  # Embedded calendar widget
        └── weather_widget.dart         # Live weather card
```

---

## Screens & Navigation

```
Login Screen
└── Auth Check
    ├── Admin Dashboard
    │   ├── Employee Master
    │   ├── Attendance (all employees) → PDF export
    │   ├── QR Code Generator
    │   ├── Leave Management (approve / reject)
    │   ├── Leave Calendar (add/edit holidays)
    │   ├── Company Policies (create/edit)
    │   └── Codes Config (leave types, designations, office locations)
    │
    └── Employee Dashboard
        ├── Attendance (personal history) → QR check-in / check-out
        ├── Leave Request (apply)
        └── Company Policies (read-only)

    Both roles share:
        ├── Profile Screen
        ├── App Drawer (navigation + logout)
        └── Theme toggle (light / dark / system)
```

---

## Firestore Database Schema

AttendStore uses **eight Firestore collections**. Document IDs and field types are described below.

### 1. `users` — Document ID: user email
```json
{
  "userId":      1,
  "email":       "string",
  "name":        "string",
  "password":    "string",
  "role":        "admin | employee",
  "status":      "active | inactive",
  "gender":      "string",
  "phone":       9999999999,
  "address":     "string",
  "designation": "string",
  "dob":         "timestamp",
  "joiningDate": "timestamp",
  "createdBy":   "string",
  "createdOn":   "timestamp",
  "updatedBy":   "string",
  "updatedOn":   "timestamp"
}
```

### 2. `attendance` — Document ID: user email
Each attendance document holds a **map** keyed by date string (`"yyyy-MM-dd"`):
```json
{
  "2025-06-10": {
    "checkIn":           "timestamp",
    "checkOut":          "timestamp",
    "checkInLocation":   "GeoPoint",
    "checkOutLocation":  "GeoPoint",
    "status":            "present | absent | half-day",
    "workingHours":      8.5
  }
}
```

### 3. `leaveCalendar` — Document ID: auto-generated
```json
{
  "holidayDate": "timestamp",
  "holidayName": "string",
  "active":      true,
  "createdBy":   "string",
  "createdOn":   "timestamp",
  "updatedBy":   "string",
  "updatedOn":   "timestamp"
}
```

### 4. `leave` — Document ID: email (one active request per user)
```json
{
  "email":       "string",
  "leaveType":   "string",
  "startDate":   "timestamp",
  "endDate":     "timestamp",
  "reason":      "string",
  "status":      "pending | approved | rejected",
  "appliedOn":   "timestamp",
  "createdBy":   "string",
  "createdOn":   "timestamp",
  "updatedBy":   "string",
  "updatedOn":   "timestamp"
}
```

### 5. `codes` — Document ID: auto-generated
Stores configurable reference data: leave types, designations, and office locations.
```json
{
  "codeType":         "leaveType | designation | officeLocation",
  "codeValue":        "string",
  "longDescription":  "string",
  "shortDescription": "string",
  "value1":           "string",
  "value2":           "string",
  "flex1":            "string",
  "active":           true,
  "createdBy":        "string",
  "createdOn":        "timestamp",
  "updatedBy":        "string",
  "updatedOn":        "timestamp"
}
```
> For `officeLocation` codes, `value1` holds latitude and `value2` holds longitude. A `Radius` field (in metres) defines the geofence used during QR check-in.

### 6. `qrCodes` — Document ID: `<officeId>_<type>`
```json
{
  "type":        "checkin | checkout",
  "officeId":    "string",
  "officeName":  "string",
  "date":        "yyyy-MM-dd",
  "securityKey": "string",
  "generatedBy": "string",
  "generatedOn": "timestamp",
  "active":      true
}
```

### 7. `policies` — Document ID: auto-generated
```json
{
  "title":       "string",
  "description": "string",
  "createdOn":   "timestamp",
  "createdBy":   "string",
  "updatedOn":   "timestamp",
  "updatedBy":   "string"
}
```

### 8. `officeLocations` — Document ID: auto-generated *(legacy / alternative)*
```json
{
  "name":      "string",
  "address":   "string",
  "latitude":  12.9716,
  "longitude": 77.5946,
  "radius":    100,
  "isActive":  true,
  "createdOn": "timestamp",
  "createdBy": "string",
  "updatedOn": "timestamp",
  "updatedBy": "string"
}
```

---

## Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) ≥ 3.7.2
- Dart SDK ≥ 3.7.2
- A [Firebase project](https://console.firebase.google.com) with Firestore and Authentication enabled
- (For QR scanning) A physical Android / iOS device or a device emulator with camera support

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/FirmTiger08/AttendStore.git
cd AttendStore

# 2. Install Flutter dependencies
flutter pub get

# 3. Configure Firebase (see Firebase Setup below)

# 4. Run the app
flutter run
```

---

## Firebase Setup

1. Create a project at [console.firebase.google.com](https://console.firebase.google.com).
2. Enable **Cloud Firestore** and **Authentication** (Email/Password provider).
3. Install the [Firebase CLI](https://firebase.google.com/docs/cli) and the FlutterFire CLI:
   ```bash
   npm install -g firebase-tools
   dart pub global activate flutterfire_cli
   ```
4. Log in and configure the Flutter app:
   ```bash
   firebase login
   flutterfire configure
   ```
   This regenerates `lib/firebase_options.dart` with your project credentials.
5. Deploy the provided Firestore security rules:
   ```bash
   firebase deploy --only firestore:rules
   ```
6. **Seed the first admin user** directly in the Firestore console — create a document in the `users` collection with the document ID set to the admin's email address and the following fields:
   ```json
   {
     "email":      "admin@example.com",
     "name":       "Your Name",
     "password":   "your-password",
     "role":       "admin",
     "status":     "active"
   }
   ```
   > ⚠️ Passwords are stored as plain text in this demo project. For production use, replace this with proper hashed authentication.

---

## Dependencies

| Package | Version | Purpose |
|---|---|---|
| `firebase_core` | ^2.31.0 | Firebase initialisation |
| `firebase_auth` | ^4.17.6 | User authentication |
| `cloud_firestore` | ^4.15.7 | NoSQL database |
| `http` | ^1.4.0 | Weather API calls |
| `intl` | ^0.19.0 | Date formatting & localisation |
| `shared_preferences` | ^2.5.3 | Persistent local storage |
| `provider` | ^6.1.1 | State management helper |
| `toggle_switch` | ^2.3.0 | Theme toggle UI |
| `pdf` | ^3.11.3 | PDF document generation |
| `printing` | ^5.13.1 | PDF preview & printing |
| `path_provider` | ^2.1.5 | File system paths |
| `qr_flutter` | ^4.1.0 | QR code display |
| `mobile_scanner` | ^3.5.0 | Camera-based QR code scanning |
| `geolocator` | ^11.0.0 | GPS location for geofencing |
| `cupertino_icons` | ^1.0.8 | iOS-style icons |

---

## Contributing

1. Fork the repository and create a feature branch.
2. Make your changes and ensure the app builds without errors (`flutter build apk` or `flutter build web`).
3. Open a pull request describing the change.

---

*Built with Flutter 💙*

