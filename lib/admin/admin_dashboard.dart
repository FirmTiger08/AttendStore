import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'employee_master_screen.dart';
import '../common/attendance_screen.dart';
import '../common/leave_calendar_screen.dart';
import '../admin/codes_config_screen.dart';
import '../common/policies_screen.dart';
import 'qr_code_generator_screen.dart';
import '../common/widgets/app_drawer.dart';
import '../common/widgets/leave_calendar_widget.dart';

class AdminDashboard extends StatefulWidget {
  final String userEmail;
  
  const AdminDashboard({
    super.key,
    required this.userEmail,
  });

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final _firestore = FirebaseFirestore.instance;
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final doc = await _firestore.collection('users').doc(widget.userEmail).get();
      if (mounted) {
        setState(() {
          _userName = doc.data()?['name'] ?? '';
        });
      }
    } catch (e) {
      // Handle error silently
      debugPrint('Error loading user data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 1200 ? 4 : (screenWidth > 600 ? 3 : 2);
    
    // Define dashboard items as a list
    final List<_DashboardItem> dashboardItems = [
      _DashboardItem(
        title: 'Employee Master',
        icon: Icons.people,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EmployeeMasterScreen(
                isAdmin: true,
                userEmail: widget.userEmail,
              ),
            ),
          );
        },
      ),
      _DashboardItem(
        title: 'Leave Calendar',
        icon: Icons.calendar_month,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const LeaveCalendarScreen(isAdmin: true),
            ),
          );
        },
      ),
      _DashboardItem(
        title: 'Leave Management',
        icon: Icons.leak_remove,
        onTap: () {
          Navigator.pushNamed(
            context,
            '/leave-management',
          );
        },
      ),
      _DashboardItem(
        title: 'Attendance',
        icon: Icons.checklist,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AttendanceScreen(
                isAdmin: true,
                userEmail: widget.userEmail,
              ),
            ),
          );
        },
      ),
      _DashboardItem(
        title: 'Policies',
        icon: Icons.policy,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PoliciesScreen(
                isAdmin: true,
                userEmail: widget.userEmail,
              ),
            ),
          );
        },
      ),
      _DashboardItem(
        title: 'Codes Config',
        icon: Icons.settings,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CodesConfigScreen(
                userEmail: widget.userEmail,
              ),
            ),
          );
        },
      ),
      _DashboardItem(
        title: 'QR Code Generator',
        icon: Icons.qr_code,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => QRCodeGeneratorScreen(
                userEmail: widget.userEmail,
              ),
            ),
          );
        },
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
      ),
      drawer: AppDrawer(
        userEmail: widget.userEmail,
        userName: _userName,
        userRole: 'admin',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Text(
                'Leave Calendar',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            SizedBox(
              height: screenWidth > 600 ? 400 : 300,
              child: const LeaveCalendarWidget(
                isAdmin: true,
                showControls: true,
              ),
            ),
            const SizedBox(height: 4),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 8.0,
              mainAxisSpacing: 8.0,
              children: dashboardItems.map((item) => _buildDashboardItem(context, item.title, item.icon, item.onTap)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardItem(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2.0,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48.0,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 8.0),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Add a private class for dashboard items
class _DashboardItem {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  _DashboardItem({required this.title, required this.icon, required this.onTap});
}