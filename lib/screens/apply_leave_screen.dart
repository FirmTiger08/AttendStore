import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ApplyLeaveScreen extends StatefulWidget {
  final String userEmail;
  final bool isAdmin;

  const ApplyLeaveScreen({
    super.key,
    required this.userEmail,
    this.isAdmin = false,
  });

  @override
  State<ApplyLeaveScreen> createState() => _ApplyLeaveScreenState();
}

class _ApplyLeaveScreenState extends State<ApplyLeaveScreen> {
  final _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  List<Map<String, dynamic>> _leaveHistory = [];
  List<Map<String, dynamic>> _leaveTypes = [];
  Map<String, dynamic>? _selectedLeaveType;

  @override
  void initState() {
    super.initState();
    _loadLeaveTypes();
    _loadLeaveHistory();
  }

  Future<void> _loadLeaveTypes() async {
    try {
      final snapshot = await _firestore
          .collection('codes')
          .where('codeType', isEqualTo: 'leaveType')
          .where('active', isEqualTo: true)
          .get();

      final types = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'leaveType': data['codeValue'] ?? '',
          'longDescription': data['longDescription'] ?? '',
          'shortDescription': data['shortDescription'] ?? '',
          'value1': data['value1'] ?? '',
        };
      }).toList();
      
      setState(() {
        _leaveTypes = types;
        if (types.isNotEmpty && _selectedLeaveType == null) {
          _selectedLeaveType = types.first;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading leave types: $e')),
        );
      }
    }
  }

  Future<void> _loadLeaveHistory() async {
    setState(() => _isLoading = true);

    try {
      final snapshot = await _firestore
          .collection('leave')
          .where('email', isEqualTo: widget.userEmail)
          .get();

      final leaves = snapshot.docs.map((doc) => doc.data()).toList()
        ..sort((a, b) => (b['appliedOn'] as Timestamp)
            .compareTo(a['appliedOn'] as Timestamp));

      setState(() {
        _leaveHistory = leaves;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading leave history: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showApplyLeaveDialog() async {
    if (_leaveTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No leave types available')),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    final reasonController = TextEditingController();
    DateTime? startDate;
    DateTime? endDate;
    DateTime? workingDate;
    Map<String, dynamic> selectedLeaveType = _leaveTypes.first;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Apply for Leave'),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.7,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<Map<String, dynamic>>(
                        value: selectedLeaveType,
                        isExpanded: true,
                        menuMaxHeight: 300,
                        decoration: const InputDecoration(
                          labelText: 'Leave Type',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: _leaveTypes.map((type) {
                          return DropdownMenuItem<Map<String, dynamic>>(
                            value: type,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: type['leaveType'],
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                        TextSpan(
                                          text: '\n${type['longDescription']}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (Map<String, dynamic>? newValue) {
                          if (newValue != null) {
                            setState(() {
                              selectedLeaveType = newValue;
                              // Reset working date when leave type changes
                              if (newValue['leaveType'] != 'Comp Off') {
                                workingDate = null;
                              }
                            });
                          }
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select leave type';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Start Date',
                                border: OutlineInputBorder(),
                              ),
                              readOnly: true,
                              controller: TextEditingController(
                                text: startDate != null
                                    ? DateFormat('dd-MM-yyyy').format(startDate!)
                                    : '',
                              ),
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                );
                                if (date != null) {
                                  setState(() {
                                    startDate = date;
                                    if (endDate != null && endDate!.isBefore(date)) {
                                      endDate = date;
                                    }
                                  });
                                }
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please select start date';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'End Date',
                                border: OutlineInputBorder(),
                              ),
                              readOnly: true,
                              controller: TextEditingController(
                                text: endDate != null
                                    ? DateFormat('dd-MM-yyyy').format(endDate!)
                                    : '',
                              ),
                              onTap: () async {
                                if (startDate == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please select start date first'),
                                    ),
                                  );
                                  return;
                                }
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: endDate ?? startDate!,
                                  firstDate: startDate!,
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                );
                                if (date != null) {
                                  setState(() => endDate = date);
                                }
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please select end date';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      if (selectedLeaveType['leaveType'] == 'Comp Off') ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Date of Working',
                            border: OutlineInputBorder(),
                          ),
                          readOnly: true,
                          controller: TextEditingController(
                            text: workingDate != null
                                ? DateFormat('dd-MM-yyyy').format(workingDate!)
                                : '',
                          ),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now().subtract(const Duration(days: 365)),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setState(() => workingDate = date);
                            }
                          },
                          validator: (value) {
                            if (selectedLeaveType['leaveType'] == 'Comp Off' && 
                                (value == null || value.isEmpty)) {
                              return 'Please select date of working';
                            }
                            return null;
                          },
                        ),
                      ],
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: reasonController,
                        decoration: const InputDecoration(
                          labelText: 'Reason',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        maxLines: 2,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter reason';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                try {
                  final now = DateTime.now();
                  final timestamp = now.millisecondsSinceEpoch;
                  final docId = '${widget.userEmail}_$timestamp';
                  
                  final leaveData = {
                    'email': widget.userEmail,
                    'leaveType': selectedLeaveType['leaveType'],
                    'startDate': Timestamp.fromDate(startDate!),
                    'endDate': Timestamp.fromDate(endDate!),
                    'reason': reasonController.text.trim(),
                    'status': 'pending',
                    'appliedOn': Timestamp.fromDate(now),
                    'createdBy': widget.userEmail,
                    'createdOn': Timestamp.fromDate(now),
                    'updatedBy': widget.userEmail,
                    'updatedOn': Timestamp.fromDate(now),
                  };

                  if (selectedLeaveType['leaveType'] == 'Comp Off' && workingDate != null) {
                    leaveData['workingDate'] = Timestamp.fromDate(workingDate!);
                  }

                  await _firestore.collection('leave').doc(docId).set(leaveData);

                  if (!mounted) return;
                  Navigator.pop(context);
                  _loadLeaveHistory();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Leave request submitted successfully')),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error submitting leave request: $e')),
                  );
                }
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Leaves'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _leaveHistory.isEmpty
              ? const Center(child: Text('No leave history found'))
              : ListView.builder(
                  itemCount: _leaveHistory.length,
                  itemBuilder: (context, index) {
                    final leave = _leaveHistory[index];
                    final startDate = (leave['startDate'] as Timestamp).toDate();
                    final endDate = (leave['endDate'] as Timestamp).toDate();
                    final status = leave['status'] as String;
                    final leaveType = leave['leaveType'] as String;
                    final reason = leave['reason'] as String;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ExpansionTile(
                        title: Text('$leaveType'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${DateFormat('dd-MM-yyyy').format(startDate)} to ${DateFormat('dd-MM-yyyy').format(endDate)}',
                            ),
                            Text(
                              'Status: ${status.toUpperCase()}',
                              style: TextStyle(
                                color: status == 'approved'
                                    ? Colors.green
                                    : status == 'rejected'
                                        ? Colors.red
                                        : Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Reason: $reason'),
                                const SizedBox(height: 8),
                                Text(
                                  'Applied on: ${DateFormat('dd-MM-yyyy').format((leave['appliedOn'] as Timestamp).toDate())}',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showApplyLeaveDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
} 