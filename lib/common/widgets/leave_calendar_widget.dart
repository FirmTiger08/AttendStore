import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';

class LeaveCalendarWidget extends StatefulWidget {
  final bool isAdmin;
  final bool showControls;
  final double? height;
  
  const LeaveCalendarWidget({
    super.key,
    this.isAdmin = false,
    this.showControls = true,
    this.height,
  });

  @override
  State<LeaveCalendarWidget> createState() => _LeaveCalendarWidgetState();
}

class _LeaveCalendarWidgetState extends State<LeaveCalendarWidget> {
  final _firestore = FirebaseFirestore.instance;
  DateTime _selectedMonth = DateTime.now();
  List<Map<String, dynamic>> _holidays = [];
  List<Map<String, dynamic>> _approvedLeaves = [];
  Map<String, List<Map<String, dynamic>>> _employeeLeavesByDate = {};
  Map<String, String> _leaveTypeDescriptions = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      await _loadLeaveTypes();
      if (widget.isAdmin) {
        await _loadAllEmployeesLeaves();
      } else {
        await _loadApprovedLeaves();
      }
    } catch (e) {
      print('Error in initialization: $e');
    }
  }

  Future<void> _loadLeaveTypes() async {
    try {
      final snapshot = await _firestore
          .collection('codes')
          .where('active', isEqualTo: true)
          .get();

      final leaveTypes = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'leaveType': data['leaveType'] as String,
          'shortDescription': data['shortDescription'] as String,
        };
      }).toList();

      setState(() {
        _leaveTypeDescriptions = Map.fromEntries(
          leaveTypes.map((type) => MapEntry(
            type['leaveType'] as String,
            type['shortDescription'] as String,
          )),
        );
      });
    } catch (e) {
      print('Error loading leave types: $e');
    }
  }

  Future<void> _loadAllEmployeesLeaves() async {
    try {
      final leavesSnapshot = await _firestore
          .collection('leave')
          .where('status', isEqualTo: 'approved')
          .get();

      if (leavesSnapshot.docs.isEmpty) {
        return;
      }

      // Get all users to map emails to names
      final usersSnapshot = await _firestore.collection('users').get();
      final Map<String, String> userNames = {};
      for (var doc in usersSnapshot.docs) {
        userNames[doc.id] = doc.data()['name'] ?? 'Unknown';
      }

      // Group leaves by date
      final Map<String, List<Map<String, dynamic>>> leavesByDate = {};
      
      for (var doc in leavesSnapshot.docs) {
        final data = doc.data();
        final startDate = (data['startDate'] as Timestamp).toDate();
        final endDate = (data['endDate'] as Timestamp).toDate();
        final email = data['email'] as String;
        final leaveType = data['leaveType'] as String;
        final employeeName = userNames[email] ?? 'Unknown';

        // Add leave for each day in the range
        DateTime currentDate = startDate;
        while (!currentDate.isAfter(endDate)) {
          final dateStr = DateFormat('yyyy-MM-dd').format(currentDate);
          if (!leavesByDate.containsKey(dateStr)) {
            leavesByDate[dateStr] = [];
          }
          leavesByDate[dateStr]!.add({
            'email': email,
            'name': employeeName,
            'type': leaveType,
            'shortDescription': _leaveTypeDescriptions[leaveType] ?? leaveType,
          });
          currentDate = currentDate.add(const Duration(days: 1));
        }
      }

      if (mounted) {
        setState(() {
          _employeeLeavesByDate = leavesByDate;
        });
      }
    } catch (e) {
      print('Error loading all employees leaves: $e');
    }
  }

  Future<void> _loadApprovedLeaves() async {
    try {
      final currentUserEmail = await AuthService.getStoredEmail();

      final leavesSnapshot = await _firestore
          .collection('leave')
          .where('email', isEqualTo: currentUserEmail)
          .where('status', isEqualTo: 'approved')
          .get();
      
      if (leavesSnapshot.docs.isEmpty) {
        return;
      }

      if (mounted) {
        setState(() {
          _approvedLeaves = leavesSnapshot.docs.map((doc) {
            final data = doc.data();
            final startDate = (data['startDate'] as Timestamp).toDate();
            final endDate = (data['endDate'] as Timestamp).toDate();
            
            return {
              'startDate': startDate,
              'endDate': endDate,
              'type': data['leaveType'],
              'shortDescription': _leaveTypeDescriptions[data['leaveType']] ?? data['leaveType'],
            };
          }).toList();
        });
      }
    } catch (e) {
      print('Error loading approved leaves: $e');
    }
  }

  bool _isDateInApprovedLeave(DateTime date) {
    final isInLeave = _approvedLeaves.any((leave) {
      final startDate = leave['startDate'] as DateTime;
      final endDate = leave['endDate'] as DateTime;
      
      // Normalize dates to start of day for comparison
      final normalizedDate = DateTime(date.year, date.month, date.day);
      final normalizedStartDate = DateTime(startDate.year, startDate.month, startDate.day);
      final normalizedEndDate = DateTime(endDate.year, endDate.month, endDate.day);
      
      return normalizedDate.isAfter(normalizedStartDate.subtract(const Duration(days: 1))) && 
             normalizedDate.isBefore(normalizedEndDate.add(const Duration(days: 1)));
    });
    
    return isInLeave;
  }

  bool _hasEmployeeLeaves(DateTime date) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    return _employeeLeavesByDate.containsKey(dateStr);
  }

  void _showLeaveDetails(DateTime date) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final leaves = _employeeLeavesByDate[dateStr] ?? [];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Leave Details - ${DateFormat('dd MMM yyyy').format(date)}'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: leaves.length,
            itemBuilder: (context, index) {
              final leave = leaves[index];
              return ListTile(
                title: Text(leave['name']),
                subtitle: Text(leave['shortDescription']),
                trailing: Text(leave['email']),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get the days in the selected month
    final daysInMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
    final firstDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final firstWeekday = firstDayOfMonth.weekday % 7; // 0 for Sunday

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('leave_calendar').where('active', isEqualTo: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        // Parse holidays from snapshot
        _holidays = snapshot.data?.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            'date': (data['holidayDate'] as Timestamp).toDate(),
            'name': data['holidayName'],
          };
        }).toList() ?? [];

        return SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.showControls)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Legend
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildLegendItem(
                            Colors.red[100]!,
                            Colors.red,
                            'Weekends',
                          ),
                          const SizedBox(width: 16),
                          _buildLegendItem(
                            Colors.orange[100]!,
                            Colors.orange,
                            'Holidays',
                          ),
                          const SizedBox(width: 16),
                          _buildLegendItem(
                            widget.isAdmin ? Colors.purple[100]! : Colors.yellow[100]!,
                            widget.isAdmin ? Colors.purple[800]! : Colors.orange[800]!,
                            widget.isAdmin ? 'Employee Leaves' : 'Your Approved Leaves',
                          ),
                        ],
                      ),
                    ),
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
                    const SizedBox(height: 4),
                    // Calendar days
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        childAspectRatio: 1.5,
                        mainAxisSpacing: 0,
                        crossAxisSpacing: 0,
                      ),
                      itemCount: 42, // 6 weeks
                      itemBuilder: (context, index) {
                        final dayOffset = index - firstWeekday;
                        final day = dayOffset + 1;
                        
                        if (dayOffset < 0 || day > daysInMonth) {
                          return const SizedBox.shrink();
                        }

                        final date = DateTime(_selectedMonth.year, _selectedMonth.month, day);
                        final isWeekend = date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
                        final holiday = _holidays.firstWhere(
                          (h) => DateFormat('yyyy-MM-dd').format(h['date']) == 
                                DateFormat('yyyy-MM-dd').format(date),
                          orElse: () => {},
                        );
                        final hasHoliday = holiday.isNotEmpty;
                        final isApprovedLeave = widget.isAdmin 
                            ? _hasEmployeeLeaves(date)
                            : _isDateInApprovedLeave(date);

                        return _buildDayWidget(date, day, isWeekend, hasHoliday, isApprovedLeave, holidayName: hasHoliday ? holiday['name'] : null);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDayWidget(DateTime date, int day, bool isWeekend, bool hasHoliday, bool isApprovedLeave, {String? holidayName}) {
    Color? backgroundColor;
    Color? textColor;
    String? tooltip;
    bool isBold = false;

    if (isWeekend) {
      backgroundColor = Colors.red[100];
      textColor = Colors.red;
      tooltip = 'Weekend';
      isBold = true;
    } else if (hasHoliday) {
      backgroundColor = Colors.orange[100];
      textColor = Colors.orange;
      tooltip = holidayName ?? 'Holiday';
      isBold = true;
    } else if (isApprovedLeave) {
      backgroundColor = widget.isAdmin ? Colors.purple[100] : Colors.yellow[100];
      textColor = widget.isAdmin ? Colors.purple[800] : Colors.orange[800];
      isBold = true;
    }

    Widget dayWidget = Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        color: backgroundColor,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              day.toString(),
              style: TextStyle(
                color: textColor,
                fontWeight: isBold ? FontWeight.bold : null,
              ),
            ),
            if (isApprovedLeave && !widget.isAdmin)
              Expanded(
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _approvedLeaves
                          .firstWhere(
                            (leave) => date.isAfter(leave['startDate'].subtract(const Duration(days: 1))) && 
                                      date.isBefore(leave['endDate'].add(const Duration(days: 1))),
                            orElse: () => {'shortDescription': ''},
                          )['shortDescription'] ?? '',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 245, 0, 0),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                    ),
                  ),
                ),
              ),
            if (isApprovedLeave && widget.isAdmin)
              Builder(
                builder: (context) {
                  final dateStr = DateFormat('yyyy-MM-dd').format(date);
                  final leaves = _employeeLeavesByDate[dateStr] ?? [];
                  final names = leaves.map((l) => (l['name'] as String).substring(0, (l['name'] as String).length > 5 ? 5 : (l['name'] as String).length)).toList();
                  if (names.isEmpty) return const SizedBox.shrink();
                  final displayNames = names.join(', ');
                  
                  return Expanded(
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          displayNames,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 245, 0, 0),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );

    if (isWeekend || hasHoliday) {
      dayWidget = Material(
        color: Colors.transparent,
        child: Tooltip(
          message: tooltip,
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
          child: dayWidget,
        ),
      );
    } else if (isApprovedLeave) {
      dayWidget = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.isAdmin ? () => _showLeaveDetails(date) : null,
          child: Tooltip(
            message: widget.isAdmin 
                ? 'Click to view leave details'
                : _approvedLeaves
                    .firstWhere(
                      (leave) => date.isAfter(leave['startDate'].subtract(const Duration(days: 1))) && 
                                date.isBefore(leave['endDate'].add(const Duration(days: 1))),
                      orElse: () => {'shortDescription': 'Approved Leave'},
                    )['shortDescription'] ?? 'Approved Leave',
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
            child: dayWidget,
          ),
        ),
      );
    }

    return dayWidget;
  }

  Widget _buildLegendItem(Color backgroundColor, Color textColor, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
} 