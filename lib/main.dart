import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/admin_dashboard.dart';
import 'screens/employee_dashboard.dart';
import 'screens/apply_leave_screen.dart';
import 'screens/leave_management_screen.dart';
import 'screens/codes_config_screen.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Ignore duplicate app error
    if (!e.toString().contains('duplicate-app')) {
      rethrow;
    }
  }
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check if we have the new integer format
    if (prefs.containsKey('theme_mode_v2')) {
      final themeModeIndex = prefs.getInt('theme_mode_v2');
      if (themeModeIndex != null && themeModeIndex >= 0 && themeModeIndex < ThemeMode.values.length) {
        setState(() {
          _themeMode = ThemeMode.values[themeModeIndex];
        });
        return;
      }
    }
    
    // Check for old boolean format and migrate
    if (prefs.containsKey('theme_mode')) {
      final oldDarkMode = prefs.getBool('theme_mode');
      if (oldDarkMode != null) {
        // Migrate from old boolean format
        final newThemeMode = oldDarkMode ? ThemeMode.dark : ThemeMode.light;
        setState(() {
          _themeMode = newThemeMode;
        });
        // Save in new format and remove old format
        await prefs.setInt('theme_mode_v2', newThemeMode.index);
        await prefs.remove('theme_mode');
        return;
      }
    }
    
    // Default to light mode
    setState(() {
      _themeMode = ThemeMode.light;
    });
    await prefs.setInt('theme_mode_v2', ThemeMode.light.index);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _themeMode = mode);
    // Ensure the mode index is valid before saving
    if (mode.index >= 0 && mode.index < ThemeMode.values.length) {
      await prefs.setInt('theme_mode_v2', mode.index);
    } else {
      // Fallback to light mode if index is invalid
      await prefs.setInt('theme_mode_v2', ThemeMode.light.index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ThemeChangeNotifier(
      themeMode: _themeMode,
      onThemeModeChanged: setThemeMode,
      child: MaterialApp(
        title: 'Attendance Management',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: _themeMode,
        home: const AuthCheckScreen(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/apply-leave': (context) => FutureBuilder<String?>(
                future: AuthService.getStoredEmail(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }
                  
                  if (!snapshot.hasData || snapshot.data == null) {
                    return const LoginScreen();
                  }

                  return ApplyLeaveScreen(
                    userEmail: snapshot.data!,
                    isAdmin: false,
                  );
                },
              ),
          '/leave-management': (context) => FutureBuilder<String?>(
                future: AuthService.getStoredEmail(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }
                  
                  if (!snapshot.hasData || snapshot.data == null) {
                    return const LoginScreen();
                  }

                  return LeaveManagementScreen(
                    userEmail: snapshot.data!,
                    isAdmin: true,
                  );
                },
              ),
          '/codes-config': (context) => FutureBuilder<String?>(
                future: AuthService.getStoredEmail(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }
                  
                  if (!snapshot.hasData || snapshot.data == null) {
                    return const LoginScreen();
                  }

                  return CodesConfigScreen(
                    userEmail: snapshot.data!,
                  );
                },
              ),
        },
      ),
    );
  }
}

class ThemeChangeNotifier extends InheritedWidget {
  final ThemeMode themeMode;
  final Future<void> Function(ThemeMode) onThemeModeChanged;

  const ThemeChangeNotifier({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
    required super.child,
  });

  static ThemeChangeNotifier of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ThemeChangeNotifier>()!;
  }

  @override
  bool updateShouldNotify(ThemeChangeNotifier oldWidget) {
    return themeMode != oldWidget.themeMode;
  }
}

class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({super.key});

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginState();
  }

  Future<void> _checkLoginState() async {
    final isLoggedIn = await AuthService.isLoggedIn();
    
    if (!mounted) return;

    if (isLoggedIn) {
      final email = await AuthService.getStoredEmail();
      final role = await AuthService.getStoredRole();
      
      if (email != null && role != null) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => role.toLowerCase() == 'admin'
                ? AdminDashboard(userEmail: email)
                : EmployeeDashboard(userEmail: email),
          ),
        );
      }
    } else {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}