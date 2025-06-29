/*
Firebase Firestore Database Schema

1. Users Collection (Document ID: user's email)
{
  "userId": 1,                    // number
  "email": "advaithpr1020@gmail.com",  // string
  "name": "Advaith P R",         // string
  "password": "123456",          // string
  "role": "admin",              // string ("admin" or "employee")
  "status": "active",           // string
  "gender": "male",             // string
  "phone": 9446413911,          // number
  "address": "Trivandrum",      // string
  "designation": "HR Manager",   // string
  "dob": timestamp,             // timestamp
  "joiningDate": timestamp,      // timestamp
  "createdBy": "admin",         // string
  "createdOn": timestamp,       // timestamp
  "updatedBy": "admin",         // string
  "updatedOn": timestamp        // timestamp
}

2. Leave Table (Document ID: email)
{
  "email": String,
  "leaveType": String,
  "startDate": timestamp,
  "endDate": timestamp,
  "reason": String,
  "status": String,
  "appliedOn": timestamp,
  "createdBy": String,
  "createdOn": timestamp,
  "updatedBy": String,
  "updatedOn": timestamp,
}

3. Leave Calendar Collection (Document ID: Auto-generated)
{
  "holidayDate": timestamp,
  "holidayName": "New Year's Day",
  "createdBy": "admin",         
  "createdOn": timestamp,       
  "updatedBy": "admin",         
  "updatedOn": timestamp
  "active": true
}

4. Attendance Collection (Document ID: email)
{
  "email": "user@example.com",
  "date": timestamp,
  "checkIn": timestamp,
  "checkOut": timestamp,
  "status": "present", // or "absent", "half-day"
  "markedBy": "admin"
}

5. Codes Collection (for system configurations and constants)
{
  "codeType": String,           // "leaveType" or "designation"
  "codeValue": String,          // The actual value (e.g., "Sick Leave", "Software Engineer")
  "longDescription": String,    // Detailed description
  "shortDescription": String,   // Brief description or abbreviation
  "value1": String,            // Additional configuration value
  "value2": String,            // Reserved for future use
  "flex1": String,             // Reserved for future use
  "active": boolean,           // Whether the code is active
  "createdBy": String,         // Who created the code
  "createdOn": timestamp,      // When code was created
  "updatedBy": String,         // Who last updated the code
  "updatedOn": timestamp       // When code was last updated
}

6. Policies Collection (Document ID: Auto-generated)
{
  "title": String,              // Policy title
  "description": String,        // Policy description/content
  "createdOn": timestamp,       // When policy was created
  "createdBy": String,          // Who created the policy
  "updatedOn": timestamp,       // When policy was last updated
  "updatedBy": String           // Who last updated the policy
}

7. Office Locations Collection (Document ID: Auto-generated)
{
  "name": String,               // Office name
  "address": String,            // Office address
  "latitude": number,           // Latitude coordinate
  "longitude": number,          // Longitude coordinate
  "radius": number,             // Radius in meters for location verification
  "createdOn": timestamp,       // When location was created
  "createdBy": String,          // Who created the location
  "updatedOn": timestamp,       // When location was last updated
  "updatedBy": String,          // Who last updated the location
  "isActive": boolean           // Whether location is active
}

8. QR Codes Collection (Document ID: <officeId>_<type>)
{
  "type": String,               // "checkin" or "checkout"
  "officeId": String,           // Reference to office location (codes doc id)
  "officeName": String,         // Office location name
  "date": String,               // Date for which QR code is valid (yyyy-MM-dd)
  "generatedBy": String,        // Who generated the QR code
  "generatedOn": timestamp,     // When QR code was generated
  "active": boolean             // Whether QR code is active
}

Sample Data Queries:

// Add a user (using email as document ID)
await FirebaseFirestore.instance
    .collection('users')
    .doc('advaithpr1020@gmail.com')
    .set({
  'userId': 1,
  'email': 'advaithpr1020@gmail.com',
  'name': 'Advaith P R',
  'password': '123456',
  'role': 'admin',
  'status': 'active',
  'gender': 'male',
  'phone': 9446413911,
  'address': 'Trivandrum',
  'designation': 'HR Manager',
  'dob': Timestamp.fromDate(DateTime(2003, 5, 2)),
  'joiningDate': Timestamp.fromDate(DateTime(2024, 6, 5)),
  'createdBy': 'admin',
  'createdOn': Timestamp.fromDate(DateTime(2025, 6, 4)),
  'updatedBy': 'admin',
  'updatedOn': Timestamp.fromDate(DateTime(2025, 6, 5))
});

// Add a leave type (using LeaveType as document ID)
await FirebaseFirestore.instance
    .collection('leaveTypes')
    .doc('SickLeave')
    .set({
  'leaveType': 'Sick Leave',
  'description': 'For medical reasons',
  'maxDaysAllowed': 10,
  'active': true
});

// Add a holiday to calendar (using holidayDate as document ID)
final holidayDate = DateTime(2024, 1, 1).toIso8601String();
await FirebaseFirestore.instance
    .collection('leaveCalendar')
    .doc(holidayDate)
    .set({
  'holidayDate': FieldValue.serverTimestamp(),
  'description': 'New Year\'s Day',
  'type': 'public_holiday',
  'active': true
});

// Add attendance record (using email as document ID)
await FirebaseFirestore.instance
    .collection('attendance')
    .doc('user@example.com')
    .set({
  'email': 'user@example.com',
  'date': FieldValue.serverTimestamp(),
  'checkIn': FieldValue.serverTimestamp(),
  'checkOut': null,
  'status': 'present',
  'workingHours': 0
});

// Add system code
await FirebaseFirestore.instance
    .collection('codes')
    .doc('config1')
    .set({
  'codeType': 'leaveType',
  'codeValue': 'Sick Leave',
  'longDescription': 'For medical reasons and health-related absences',
  'shortDescription': 'SL',
  'value1': '10',
  'value2': null,
  'flex1': null,
  'active': true,
  'createdBy': 'admin@company.com',
  'createdOn': FieldValue.serverTimestamp(),
  'updatedBy': 'admin@company.com',
  'updatedOn': FieldValue.serverTimestamp()
});

// Add designation code
await FirebaseFirestore.instance
    .collection('codes')
    .add({
  'codeType': 'designation',
  'codeValue': 'Software Engineer',
  'longDescription': 'Software development and programming role',
  'shortDescription': 'SE',
  'value1': 'Technical',
  'value2': null,
  'flex1': null,
  'active': true,
  'createdBy': 'admin@company.com',
  'createdOn': FieldValue.serverTimestamp(),
  'updatedBy': 'admin@company.com',
  'updatedOn': FieldValue.serverTimestamp()
});

// Add a policy (using auto-generated document ID)
await FirebaseFirestore.instance
    .collection('policies')
    .add({
  'title': 'Attendance Policy',
  'description': 'All employees must check in by 9:00 AM and check out by 6:00 PM. Late arrivals must be approved by the manager.',
  'createdOn': FieldValue.serverTimestamp(),
  'createdBy': 'admin@company.com',
  'updatedOn': FieldValue.serverTimestamp(),
  'updatedBy': 'admin@company.com'
});

// Add an office location (using auto-generated document ID)
await FirebaseFirestore.instance
    .collection('officeLocations')
    .add({
  'name': 'Main Office',
  'address': '123 Business Street, City, State 12345',
  'latitude': 12.9716,
  'longitude': 77.5946,
  'radius': 100.0, // 100 meters
  'createdOn': FieldValue.serverTimestamp(),
  'createdBy': 'admin@company.com',
  'updatedOn': FieldValue.serverTimestamp(),
  'updatedBy': 'admin@company.com',
  'isActive': true
});

// Add a QR code for check-in (using officeId and type as document ID)
await FirebaseFirestore.instance
    .collection('qrCodes')
    .doc('officeId_checkin')
    .set({
  'type': 'checkin',
  'officeId': 'officeId',
  'officeName': 'Main Office',
  'date': '2024-06-10',
  'generatedBy': 'admin@company.com',
  'generatedOn': FieldValue.serverTimestamp(),
  'active': true
});
*/ 