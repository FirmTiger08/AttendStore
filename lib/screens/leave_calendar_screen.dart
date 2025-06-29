import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../services/pdf_generator_service.dart';

class LeaveCalendarScreen extends StatefulWidget {
  final bool isAdmin;
  
  const LeaveCalendarScreen({
    super.key,
    this.isAdmin = false,
  });

  @override
  State<LeaveCalendarScreen> createState() => _LeaveCalendarScreenState();
}

class _LeaveCalendarScreenState extends State<LeaveCalendarScreen> {
  final _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _holidays = [];
  bool _isLoading = true;
  DateTime _selectedMonth = DateTime.now();
  final _formKey = GlobalKey<FormState>();
  final _holidayNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadHolidays();
  }

  @override
  void dispose() {
    _holidayNameController.dispose();
    super.dispose();
  }

  Future<void> _loadHolidays() async {
    setState(() => _isLoading = true);

    try {
      final snapshot = await _firestore
          .collection('leave_calendar')
          .where('active', isEqualTo: true)
          .get();

      final holidays = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'date': (data['holidayDate'] as Timestamp).toDate(),
          'name': data['holidayName'],
        };
      }).toList();

      setState(() {
        _holidays = holidays;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading holidays: $e'); // Debug log
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading holidays: $e')),
        );
      }
    }
  }

  Future<void> _addHoliday(DateTime date) async {
    _holidayNameController.clear();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Holiday'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Date: ${DateFormat('dd-MM-yyyy').format(date)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _holidayNameController,
                decoration: const InputDecoration(labelText: 'Holiday Name'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter holiday name';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result == true && _formKey.currentState!.validate()) {
      try {
        print('Adding holiday to database...'); // Debug log
        await _firestore.collection('leave_calendar').add({
          'holidayDate': Timestamp.fromDate(date),
          'holidayName': _holidayNameController.text.trim(),
          'createdBy': 'admin',
          'createdOn': Timestamp.now(),
          'updatedBy': 'admin',
          'updatedOn': Timestamp.now(),
          'active': true,
        });

        print('Holiday added successfully'); // Debug log
        _loadHolidays();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Holiday added successfully')),
          );
        }
      } catch (e) {
        print('Error adding holiday: $e'); // Debug log
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error adding holiday: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteHoliday(String docId) async {
    try {
      await _firestore.collection('leave_calendar').doc(docId).update({
        'active': false,
        'updatedBy': 'admin',
        'updatedOn': Timestamp.now(),
      });

      _loadHolidays();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Holiday deleted successfully')),
        );
      }
    } catch (e) {
      print('Error deleting holiday: $e'); // Debug log
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting holiday: $e')),
        );
      }
    }
  }

  Future<void> _selectMonth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth.isBefore(DateTime(2025)) ? _selectedMonth : DateTime(2024),
      firstDate: DateTime(2020),
      lastDate: DateTime(2025, 12),
    );

    if (picked != null) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month);
      });
    }
  }

  Future<void> _editHoliday(Map<String, dynamic> holiday) async {
    _holidayNameController.text = holiday['name'];
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Holiday'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Date: ${DateFormat('dd-MM-yyyy').format(holiday['date'])}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _holidayNameController,
                decoration: const InputDecoration(labelText: 'Holiday Name'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter holiday name';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true && _formKey.currentState!.validate()) {
      try {
        print('Updating holiday...'); // Debug log
        await _firestore.collection('leave_calendar').doc(holiday['id']).update({
          'holidayName': _holidayNameController.text.trim(),
          'updatedBy': 'admin',
          'updatedOn': Timestamp.now(),
        });

        print('Holiday updated successfully'); // Debug log
        _loadHolidays();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Holiday updated successfully')),
          );
        }
      } catch (e) {
        print('Error updating holiday: $e'); // Debug log
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating holiday: $e')),
          );
        }
      }
    }
  }

  Future<void> _showHolidayExportDialog() async {
    DateTime? startDate;
    DateTime? endDate;
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Export Holidays as PDF'),
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
                        _exportHolidaysAsPdf(startDate!, endDate!);
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

  Future<void> _exportHolidaysAsPdf(DateTime start, DateTime end) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Dialog(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Fetching holidays..."),
            ],
          ),
        ),
      ),
    );
    try {
      final holidays = await _fetchHolidaysInRange(start, end);
      if (!mounted) return;
      Navigator.pop(context);
      if (holidays.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No holidays found in the selected range.')),
        );
        return;
      }
      final title = 'Holiday List (${DateFormat('d MMM, yyyy').format(start)} - ${DateFormat('d MMM, yyyy').format(end)})';
      final headers = ['Date', 'Holiday Name'];
      holidays.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
      final data = holidays.map<List<String>>((h) => [
        DateFormat('dd-MM-yyyy').format(h['date']),
        h['name'] ?? '',
      ]).toList();
      final pdfData = await PdfGeneratorService.generateAttendancePdf(title, headers, data);
      await Printing.layoutPdf(onLayout: (format) => pdfData, name: 'holiday-list.pdf');
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting holidays: $e')),
      );
    }
  }

  Future<List<Map<String, dynamic>>> _fetchHolidaysInRange(DateTime start, DateTime end) async {
    final snapshot = await _firestore
        .collection('leave_calendar')
        .where('active', isEqualTo: true)
        .get();
    return snapshot.docs
        .map((doc) {
          final data = doc.data();
          final date = (data['holidayDate'] as Timestamp).toDate();
          return {
            'date': date,
            'name': data['holidayName'],
          };
        })
        .where((h) => !h['date'].isBefore(start) && !h['date'].isAfter(end))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    // Get the days in the selected month
    final daysInMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
    final firstDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final firstWeekday = firstDayOfMonth.weekday % 7; // 0 for Sunday

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave Calendar',style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: _selectMonth,
            tooltip: 'Select Month',
          ),
          if (widget.isAdmin)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              onPressed: _showHolidayExportDialog,
              tooltip: 'Export Holidays as PDF',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Month selector
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () {
                          setState(() {
                            _selectedMonth = DateTime(
                              _selectedMonth.year,
                              _selectedMonth.month - 1,
                            );
                          });
                        },
                      ),
                      Text(
                        DateFormat('MMMM yyyy').format(_selectedMonth),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () {
                          setState(() {
                            _selectedMonth = DateTime(
                              _selectedMonth.year,
                              _selectedMonth.month + 1,
                            );
                          });
                        },
                      ),
                    ],
                  ),
                ),

                // Calendar grid
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      // Weekday headers
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Text('Sun'),
                          Text('Mon'),
                          Text('Tue'),
                          Text('Wed'),
                          Text('Thu'),
                          Text('Fri'),
                          Text('Sat'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Calendar days
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          childAspectRatio: 1.5,
                        ),
                        itemCount: 42, // 6 weeks
                        itemBuilder: (context, index) {
                          final dayOffset = index - firstWeekday;
                          final day = dayOffset + 1;
                          
                          if (dayOffset < 0 || day > daysInMonth) {
                            return const SizedBox.shrink();
                          }

                          final date = DateTime(_selectedMonth.year, _selectedMonth.month, day);
                          final hasHoliday = _holidays.any((h) => 
                            DateFormat('yyyy-MM-dd').format(h['date']) == 
                            DateFormat('yyyy-MM-dd').format(date)
                          );

                          return InkWell(
                            onTap: widget.isAdmin ? () => _addHoliday(date) : null,
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                color: hasHoliday ? Colors.red[100] : null,
                              ),
                              child: Center(
                                child: Text(
                                  day.toString(),
                                  style: TextStyle(
                                    color: hasHoliday ? Colors.red : null,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Holidays list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _holidays.length,
                    itemBuilder: (context, index) {
                      final holiday = _holidays[index];
                      return ListTile(
                        title: Text(holiday['name']),
                        subtitle: Text(
                          DateFormat('dd-MM-yyyy').format(holiday['date']),
                        ),
                        trailing: widget.isAdmin
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () => _editHoliday(holiday),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () => _deleteHoliday(holiday['id']),
                                  ),
                                ],
                              )
                            : null,
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
} 