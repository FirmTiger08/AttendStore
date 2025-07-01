import 'package:flutter/material.dart';
import 'package:toggle_switch/toggle_switch.dart';
import '../profile_screen.dart';
import '../services/auth_service.dart';
import '../../main.dart';

class AppDrawer extends StatelessWidget {
  final String userEmail;
  final String userName;
  final String userRole;

  const AppDrawer({
    super.key,
    required this.userEmail,
    required this.userName,
    required this.userRole,
  });

  Future<void> _handleLogout(BuildContext context) async {
    try {
      await AuthService.signOut();
      if (!context.mounted) return;
      Navigator.of(context).pushReplacementNamed('/login');
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging out: $e')),
      );
    }
  }

  int _getThemeIndex(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 0;
      case ThemeMode.dark:
        return 1;
      case ThemeMode.system:
        return 2;
    }
  }

  ThemeMode _getThemeMode(int index) {
    switch (index) {
      case 0:
        return ThemeMode.light;
      case 1:
        return ThemeMode.dark;
      case 2:
        return ThemeMode.system;
      default:
        return ThemeMode.light; // Default to light mode
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = ThemeChangeNotifier.of(context);
    
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(userName),
            accountEmail: Text(userEmail),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                style: const TextStyle(fontSize: 40.0),
              ),
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('My Profile'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileScreen(userEmail: userEmail),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Theme',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ToggleSwitch(
                  totalSwitches: 3,
                  minWidth: 90.0,
                  minHeight: 40.0,
                  initialLabelIndex: _getThemeIndex(themeNotifier.themeMode),
                  cornerRadius: 20.0,
                  activeFgColor: Colors.white,
                  inactiveFgColor: Colors.grey,
                  icons: const[
                    Icons.wb_sunny,
                    Icons.nights_stay,
                    Icons.settings,
                  ],
                  activeBgColors: [
                    [Theme.of(context).primaryColor],
                    const [  Color.fromARGB(255, 31, 31, 31)],
                    const [  Color.fromARGB(255, 134, 134, 134)],
                  ],
                  inactiveBgColor: Colors.grey.shade300,
                  labels: const ['Light', 'Dark', 'System'],
                  onToggle: (index) {
                    if (index != null && index >= 0 && index <= 2) {
                      final themeMode = _getThemeMode(index);
                      themeNotifier.onThemeModeChanged(themeMode);
                    }
                  },
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () => _handleLogout(context),
          ),
        ],
      ),
    );
  }
} 