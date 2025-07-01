import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class LeaveManagementScreen extends StatefulWidget {
  final String userEmail;
  final bool isAdmin;

  const LeaveManagementScreen({
    super.key,
    required this.userEmail,
    required this.isAdmin,
  });

  @override
  State<LeaveManagementScreen> createState() => _LeaveManagementScreenState();
}

class _LeaveManagementScreenState extends State<LeaveManagementScreen> {
  final _firestore = FirebaseFirestore.instance;

  Future<void> _updateLeaveStatus(String leaveId, String status) async {
    // Show dialog to get reason for approval/rejection (optional)
    final String? reason = await _showReasonDialog(status);
    
    if (reason == null) return; // User cancelled

    try {
      final now = DateTime.now();
      final updateData = {
        'status': status,
        'updatedBy': widget.userEmail,
        'updatedOn': Timestamp.fromDate(now),
      };
      
      // Only add adminReason if a reason was provided
      if (reason.isNotEmpty) {
        updateData['adminReason'] = reason;
      }

      await _firestore.collection('leave').doc(leaveId).update(updateData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Leave request $status')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating leave status: $e')),
        );
      }
    }
  }

  Future<String?> _showReasonDialog(String status) async {
    final TextEditingController reasonController = TextEditingController();
    
    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${status.toUpperCase()} Leave Request'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Please provide a reason for ${status.toLowerCase()} this leave request (optional):',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 1,
                maxLength: 100,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(reasonController.text.trim());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: status == 'approved' ? Colors.green : Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(status.toUpperCase()),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave Management'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: widget.isAdmin
            ? _firestore.collection('leave').orderBy('appliedOn', descending: true).snapshots()
            : _firestore
                .collection('leave')
                .where('email', isEqualTo: widget.userEmail)
                .orderBy('appliedOn', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final leaves = snapshot.data!.docs;

          if (leaves.isEmpty) {
            return const Center(child: Text('No leave requests found'));
          }

          return ListView.builder(
            itemCount: leaves.length,
            itemBuilder: (context, index) {
              final leave = leaves[index].data() as Map<String, dynamic>;
              final leaveId = leaves[index].id;
              final email = leave['email'] as String;
              final status = leave['status'] as String;
              final leaveType = leave['leaveType'] as String;
              final startDate = (leave['startDate'] as Timestamp).toDate();
              final endDate = (leave['endDate'] as Timestamp).toDate();
              final reason = leave['reason'] as String;
              final appliedOn = (leave['appliedOn'] as Timestamp).toDate();

              return Card(
                margin: const EdgeInsets.all(8),
                child: ExpansionTile(
                  title: Text(email),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$leaveType (${DateFormat('dd-MM-yyyy').format(startDate)} - ${DateFormat('dd-MM-yyyy').format(endDate)})'),
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
                          if (leaveType == 'Comp Off' && leave['workingDate'] != null)
                            Text(
                              'Date of Working: ${DateFormat('dd-MM-yyyy').format((leave['workingDate'] as Timestamp).toDate())}',
                              style: const TextStyle(
                                fontStyle: FontStyle.italic,
                                fontSize: 12,
                              ),
                            ),
                          const SizedBox(height: 8),
                          if (leave['adminReason'] != null && (status == 'approved' || status == 'rejected'))
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12.0),
                              margin: const EdgeInsets.only(bottom: 8.0),
                              decoration: BoxDecoration(
                                color: status == 'approved' 
                                    ? Colors.green.withValues(alpha: 0.1)
                                    : Colors.red.withValues(alpha: 0.1),
                                border: Border.all(
                                  color: status == 'approved' ? Colors.green : Colors.red,
                                ),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        status == 'approved' ? Icons.check_circle : Icons.cancel,
                                        color: status == 'approved' ? Colors.green : Colors.red,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8.0),
                                      Text(
                                        'Admin ${status.toUpperCase()} Reason:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: status == 'approved' ? Colors.green[700] : Colors.red[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4.0),
                                  Text(
                                    leave['adminReason'],
                                    style: TextStyle(
                                      color: status == 'approved' ? Colors.green[700] : Colors.red[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Text(
                            'Applied on: ${DateFormat('dd-MM-yyyy HH:mm').format(appliedOn)}',
                            style: const TextStyle(
                              fontStyle: FontStyle.italic,
                              fontSize: 12,
                            ),
                          ),
                          if (leave['updatedBy'] != null &&
                              leave['updatedOn'] != null)
                            Text(
                              'Last updated by ${leave['updatedBy']} on ${DateFormat('dd-MM-yyyy HH:mm').format((leave['updatedOn'] as Timestamp).toDate())}',
                              style: const TextStyle(
                                fontStyle: FontStyle.italic,
                                fontSize: 12,
                              ),
                            ),
                          if (widget.isAdmin && status == 'pending')
                            Padding(
                              padding: const EdgeInsets.only(top: 16.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () => _updateLeaveStatus(leaveId, 'rejected'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.red,
                                    ),
                                    child: const Text('Reject'),
                                  ),
                                  const SizedBox(width: 16),
                                  ElevatedButton(
                                    onPressed: () => _updateLeaveStatus(leaveId, 'approved'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Approve'),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
} 