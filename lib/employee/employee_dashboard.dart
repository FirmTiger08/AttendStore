import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../common/attendance_screen.dart';
import '../common/policies_screen.dart';
import '../common/widgets/app_drawer.dart';
import '../common/widgets/leave_calendar_widget.dart';

class EmployeeDashboard extends StatefulWidget {
  final String userEmail;
  
  const EmployeeDashboard({
    super.key,
    required this.userEmail,
  });

  @override
  State<EmployeeDashboard> createState() => _EmployeeDashboardState();
}

class _EmployeeDashboardState extends State<EmployeeDashboard> {
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
      debugPrint('Error loading user data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 600 ? 3 : 2;
    
    // Define dashboard items as a list
    final List<_DashboardItem> dashboardItems = [
      _DashboardItem(
        title: 'Attendance',
        icon: Icons.history,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AttendanceScreen(
                isAdmin: false,
                userEmail: widget.userEmail,
              ),
            ),
          );
        },
      ),
      _DashboardItem(
        title: 'Leave\nRequest',
        icon: Icons.event_busy,
        onTap: () {
          Navigator.pushNamed(context, '/apply-leave');
        },
      ),
      _DashboardItem(
        title: 'Company\nPolicies',
        icon: Icons.policy,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PoliciesScreen(
                isAdmin: false,
                userEmail: widget.userEmail,
              ),
            ),
          );
        },
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Dashboard'),
      ),
      drawer: AppDrawer(
        userEmail: widget.userEmail,
        userName: _userName,
        userRole: 'employee',
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
                isAdmin: false,
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
              size: MediaQuery.of(context).size.width > 600 ? 64.0 : 48.0,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 8.0),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.width > 600 ? 18.0 : 16.0,
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