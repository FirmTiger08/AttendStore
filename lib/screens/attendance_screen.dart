import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../services/pdf_generator_service.dart';
import 'employee_qr_checkin_screen.dart';

class AttendanceScreen extends StatefulWidget {
  final bool isAdmin;
  final String userEmail;

  const AttendanceScreen({
    super.key,
    this.isAdmin = false,
    required this.userEmail,
  });

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _attendanceRecords = [];
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();
  bool _isCheckedIn = false;
  bool _isCheckedOut = false;

  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  bool get _isPastDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected =
        DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    return selected.isBefore(today);
  }

  @override
  void initState() {
    super.initState();
    _loadAttendanceRecords();
  }

  Future<void> _loadAttendanceRecords() async {
    setState(() => _isLoading = true);

    try {
      if (widget.isAdmin) {
        await _loadAllUsersAttendance();
      } else {
        final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

        final attendanceDoc =
            await _firestore.collection('attendance').doc(widget.userEmail).get();

        if (attendanceDoc.exists) {
          final data = attendanceDoc.data() as Map<String, dynamic>;
          final records = data[dateStr] as Map<String, dynamic>?;

          if (records != null) {
            setState(() {
              _isCheckedIn = records['checkIn'] != null;
              _isCheckedOut = records['checkOut'] != null;
              _attendanceRecords = [
                {
                  'email': widget.userEmail,
                  'name': 'My Attendance', // Placeholder
                  ...records,
                }
              ];
            });
          } else {
            setState(() {
              _isCheckedIn = false;
              _isCheckedOut = false;
              _attendanceRecords = [];
            });
          }
        } else {
          setState(() {
            _isCheckedIn = false;
            _isCheckedOut = false;
            _attendanceRecords = [];
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading attendance records: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadAllUsersAttendance() async {
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final usersSnapshot = await _firestore.collection('users').get();
      final List<Map<String, dynamic>> allRecords = [];

      for (final userDoc in usersSnapshot.docs) {
        final email = userDoc.id;
        final userData = userDoc.data();
        final attendanceDoc =
            await _firestore.collection('attendance').doc(email).get();

        Map<String, dynamic> record = {
          'email': email,
          'name': userData['name'] ?? 'Unknown',
          'status': 'absent',
          'checkIn': null,
          'checkOut': null,
          'workingHours': 0,
        };

        if (attendanceDoc.exists) {
          final data = attendanceDoc.data() as Map<String, dynamic>;
          final records = data[dateStr] as Map<String, dynamic>?;
          if (records != null) {
            record.addAll(records);
          }
        }
        allRecords.add(record);
      }

      if (mounted) {
        setState(() {
          _attendanceRecords = allRecords;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading all users attendance: $e')),
        );
      }
    }
  }

  void _openQRScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmployeeQRCheckinScreen(userEmail: widget.userEmail),
      ),
    ).then((_) => _loadAttendanceRecords());
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _loadAttendanceRecords();
    }
  }

  Future<void> _updateAttendanceStatus(String email, String newStatus) async {
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      await _firestore.collection('attendance').doc(email).set({
        dateStr: {
          'status': newStatus,
          'markedBy': widget.userEmail,
          'updatedAt': FieldValue.serverTimestamp(),
        }
      }, SetOptions(merge: true));
      _loadAttendanceRecords();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Attendance status updated to $newStatus')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating attendance status: $e')),
        );
      }
    }
  }

  Future<void> _editTime(String email, String timeType) async {
    final record = _attendanceRecords.firstWhere((r) => r['email'] == email);
    final currentTime = record[timeType]?.toDate();
    
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: currentTime != null 
          ? TimeOfDay.fromDateTime(currentTime)
          : TimeOfDay.now(),
    );

    if (picked != null) {
      final newDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        picked.hour,
        picked.minute,
      );

      final checkInTime = timeType == 'checkIn' ? newDateTime : record['checkIn']?.toDate();
      final checkOutTime = timeType == 'checkOut' ? newDateTime : record['checkOut']?.toDate();

      if (checkInTime != null && checkOutTime != null && checkInTime.isAfter(checkOutTime)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Check-in time cannot be after check-out time'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      try {
        final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
        final Map<String, dynamic> updateData = {
          dateStr: {
            timeType: Timestamp.fromDate(newDateTime),
            'markedBy': widget.userEmail,
            'updatedAt': FieldValue.serverTimestamp(),
          }
        };

        if (checkInTime != null && checkOutTime != null) {
          final duration = checkOutTime.difference(checkInTime);
          final workingHours = duration.inMinutes / 60.0;
          updateData[dateStr]!['workingHours'] = workingHours;
        }

        await _firestore.collection('attendance').doc(email).set(
          updateData,
          SetOptions(merge: true),
        );

        _loadAttendanceRecords();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${timeType == 'checkIn' ? 'Check-in' : 'Check-out'} time updated')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating time: $e')),
          );
        }
      }
    }
  }

  Future<void> _showDateRangeDialogForExport() async {
    DateTime? startDate;
    DateTime? endDate;
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Select Date Range'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: startDate ?? DateTime.now(),
                            firstDate: DateTime(2024),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() => startDate = picked);
                            if (endDate != null && endDate!.isBefore(startDate!)) {
                              setState(() => endDate = null);
                            }
                          }
                        },
                        child: Text(startDate == null
                            ? 'Start Date'
                            : DateFormat('dd-MM-yyyy').format(startDate!)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: startDate == null
                            ? null
                            : () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: endDate ?? startDate!,
                                  firstDate: startDate!,
                                  lastDate: DateTime.now(),
                                );
                                if (picked != null) {
                                  setState(() => endDate = picked);
                                }
                              },
                        child: Text(endDate == null
                            ? 'End Date'
                            : DateFormat('dd-MM-yyyy').format(endDate!)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: startDate != null && endDate != null
                    ? () {
                        Navigator.pop(context);
                        _prepareReportForDateRange(startDate!, endDate!);
                      }
                    : null,
                child: const Text('Export'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _prepareReportForDateRange(DateTime startDate, DateTime endDate) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Dialog(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("Fetching records..."),
              ],
            ),
          ),
        );
      },
    );

    final String title;
    if (startDate.year == endDate.year && startDate.month == endDate.month && startDate.day == endDate.day) {
        title = 'Attendance Report for ${DateFormat('d MMMM yyyy').format(startDate)}';
    } else {
        title = 'Attendance Report (${DateFormat('d MMM, yyyy').format(startDate)} - ${DateFormat('d MMM, yyyy').format(endDate)})';
    }

    try {
      final records = await _fetchAttendanceForDateRange(startDate, endDate);
      if (!mounted) return;
      Navigator.pop(context); // Dismiss loading dialog

      if (records.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No attendance data found for the selected date range.'))
        );
        return;
      }
      _initiatePdfExport(title, records);
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching report data: $e'))
      );
    }
  }

  Future<List<Map<String, dynamic>>> _fetchAttendanceForDateRange(DateTime startDate, DateTime endDate) async {
    final List<Map<String, dynamic>> allRecords = [];
    final usersSnapshot = await _firestore.collection('users').get();
    
    for (var userDoc in usersSnapshot.docs) {
        final email = userDoc.id;
        final userData = userDoc.data();
        final attendanceDoc = await _firestore.collection('attendance').doc(email).get();

        if (attendanceDoc.exists) {
            final attendanceData = attendanceDoc.data() as Map<String, dynamic>;
            for (var day = 0; day <= endDate.difference(startDate).inDays; day++) {
                final currentDate = startDate.add(Duration(days: day));
                final dateStr = DateFormat('yyyy-MM-dd').format(currentDate);

                if (attendanceData.containsKey(dateStr)) {
                    final recordForDay = attendanceData[dateStr] as Map<String, dynamic>;
                    allRecords.add({
                        'name': userData['name'] ?? 'Unknown',
                        'email': email,
                        'date': dateStr,
                        ...recordForDay,
                    });
                }
            }
        }
    }
    return allRecords;
  }

  Future<void> _initiatePdfExport(String title, List<Map<String, dynamic>> records) async {
    if (records.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No attendance data to export.')),
      );
      return;
    }

    final List<String> headers = [
      'Date',
      'Employee',
      'Status',
      'Check-In',
      'Check-Out',
      'Working Hours'
    ];

    records.sort((a, b) {
      int dateComp = (a['date'] as String).compareTo(b['date'] as String);
      if (dateComp != 0) return dateComp;
      return (a['name'] as String).compareTo(b['name'] as String);
    });

    final List<List<String>> data = records.map((record) {
      final checkIn = record['checkIn'] as Timestamp?;
      final checkOut = record['checkOut'] as Timestamp?;
      final workingHours = (record['workingHours'] as num?)?.toDouble() ?? 0.0;
      
      return <String>[
        DateFormat('d MMM, yyyy').format(DateTime.parse(record['date'])),
        record['name'] ?? 'N/A',
        record['status']?.toString() ?? 'absent',
        checkIn != null ? DateFormat('HH:mm').format(checkIn.toDate()) : '---',
        checkOut != null ? DateFormat('HH:mm').format(checkOut.toDate()) : '---',
        workingHours.toStringAsFixed(2),
      ];
    }).toList();
    
    final pdfData =
        await PdfGeneratorService.generateAttendancePdf(title, headers, data);

    if (!mounted) return;
    await Printing.layoutPdf(
        onLayout: (format) => pdfData, name: 'attendance-report.pdf');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isAdmin ? 'Attendance Management' : 'My Attendance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _selectDate,
          ),
          if (widget.isAdmin)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              onPressed: _showDateRangeDialogForExport,
              tooltip: 'Export Report by Date Range',
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Date: ${DateFormat('dd-MM-yyyy').format(_selectedDate)}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          if (!widget.isAdmin) _buildUserControls(),
          if (_isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_attendanceRecords.isEmpty)
            const Expanded(
              child: Center(
                child: Text('No attendance records found for this date'),
              ),
            )
          else if (widget.isAdmin)
            _buildAdminAttendanceTable()
          else
            _buildUserAttendanceView(),
        ],
      ),
    );
  }

  Widget _buildUserControls() {
    return Column(
      children: [
        if (_isPastDate)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12.0),
            margin: const EdgeInsets.only(bottom: 16.0),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              border: Border.all(color: Colors.orange),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.orange),
                const SizedBox(width: 8.0),
                Expanded(
                  child: Text(
                    'Check-in and check-out are only available for today\'s date',
                    style: TextStyle(color: Colors.orange[700]),
                  ),
                ),
              ],
            ),
          ),
        if (!widget.isAdmin && _isToday)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _isCheckedOut ? null : _openQRScanner,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: Text(_isCheckedIn ? 'Check Out' : 'Check In'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 12.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildEditableTimeCell(String email, String timeType, DateTime? time) {
    if (!widget.isAdmin) {
      return Text(time != null ? DateFormat('hh:mm a').format(time) : 'N/A');
    }

    return InkWell(
      onTap: () => _editTime(email, timeType),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              time != null ? DateFormat('hh:mm a').format(time) : 'N/A',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.edit, size: 12, color: Colors.blue),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminAttendanceTable() {
    return Expanded(
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Name')),
              DataColumn(label: Text('Email')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Check In')),
              DataColumn(label: Text('Check Out')),
              DataColumn(label: Text('Working Hours')),
            ],
            rows: _attendanceRecords.map((record) {
              final checkIn = record['checkIn']?.toDate();
              final checkOut = record['checkOut']?.toDate();

              return DataRow(
                cells: [
                  DataCell(Text(record['name'] ?? 'Unknown')),
                  DataCell(Text(record['email'])),
                  DataCell(
                    DropdownButton<String>(
                      value: record['status']?.toString().toLowerCase() ?? 'absent',
                      items: ['present', 'absent', 'leave'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value.toUpperCase(),
                            style: TextStyle(
                              color: value == 'present' ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          _updateAttendanceStatus(record['email'], newValue);
                        }
                      },
                    ),
                  ),
                  DataCell(_buildEditableTimeCell(record['email'], 'checkIn', checkIn)),
                  DataCell(_buildEditableTimeCell(record['email'], 'checkOut', checkOut)),
                  DataCell(Text(
                    record['workingHours'] != null && record['workingHours'] > 0
                        ? '${record['workingHours'].toStringAsFixed(2)} hrs'
                        : 'N/A'
                  )),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildUserAttendanceView() {
    return Expanded(
      child: ListView.builder(
        itemCount: _attendanceRecords.length,
        itemBuilder: (context, index) {
          final record = _attendanceRecords[index];
          final checkIn = record['checkIn']?.toDate();
          final checkOut = record['checkOut']?.toDate();

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(record['name'] ?? record['email']),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Email: ${record['email']}'),
                  if (checkIn != null)
                    Text('Check In: ${DateFormat('hh:mm a').format(checkIn)}'),
                  if (checkOut != null)
                    Text('Check Out: ${DateFormat('hh:mm a').format(checkOut)}'),
                  if (record['workingHours'] != null)
                    Text('Working Hours: ${record['workingHours'].toStringAsFixed(2)}'),
                  Text('Status: ${record['status']?.toUpperCase() ?? 'N/A'}'),
                  Text('Marked By: ${record['markedBy'] ?? 'N/A'}'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}