import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _isLoggedInKey = 'isLoggedIn';
  static const String _userEmailKey = 'userEmail';
  static const String _userRoleKey = 'userRole';

  // Initialize shared preferences
  static Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  // Set logged in state
  static Future<void> setLoggedIn(String email, String role) async {
    final prefs = await _prefs;
    await prefs.setBool(_isLoggedInKey, true);
    await prefs.setString(_userEmailKey, email);
    await prefs.setString(_userRoleKey, role);
  }

  // Clear logged in state
  static Future<void> clearLoggedIn() async {
    final prefs = await _prefs;
    await prefs.setBool(_isLoggedInKey, false);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userRoleKey);
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await _prefs;
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  // Get stored user email
  static Future<String?> getStoredEmail() async {
    final prefs = await _prefs;
    return prefs.getString(_userEmailKey);
  }

  // Get stored user role
  static Future<String?> getStoredRole() async {
    final prefs = await _prefs;
    return prefs.getString(_userRoleKey);
  }

  // Create user document in Firestore
  static Future<void> createUserDocument(User user, {String role = 'employee'}) async {
    final userDoc = _firestore.collection('users').doc(user.email);
    final docSnapshot = await userDoc.get();

    if (!docSnapshot.exists) {
      final now = Timestamp.now();
      await userDoc.set({
        'email': user.email,
        'name': user.displayName ?? user.email?.split('@')[0] ?? 'User',
        'role': role,
        'status': 'active',
        'createdOn': now,
        'updatedOn': now,
      });
    }
  }

  // Sign in with email and password
  static Future<Map<String, dynamic>?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      // Get user data from Firestore
      final userDoc = await _firestore
          .collection('users')
          .doc(email)
          .get();
      
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        
        // Check if password matches
        if (userData['password'] == password) {
          final role = (userData['role'] ?? 'employee').toString().toLowerCase();
          
          // Set logged in state
          await setLoggedIn(email, role);
          
          return userData;
        }
      }
      
      throw Exception('Invalid email or password');
    } catch (e) {
      rethrow;
    }
  }

  // Sign up with email and password
  static Future<UserCredential> signUpWithEmailAndPassword(
    String email,
    String password,
    {String role = 'employee'}
  ) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create the user document in Firestore
      await createUserDocument(userCredential.user!, role: role);

      // Set logged in state
      await setLoggedIn(email, role);

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // Sign out
  static Future<void> signOut() async {
    await _auth.signOut();
    await clearLoggedIn();
  }

  // Get current user
  static User? get currentUser => _auth.currentUser;

  // Get user role
  static Future<String> getUserRole(String email) async {
    try {
      final docSnapshot = await _firestore
          .collection('users')
          .doc(email)
          .get();

      if (docSnapshot.exists) {
        return docSnapshot.data()?['role'] ?? 'employee';
      }
      return 'employee';
    } catch (e) {
      return 'employee';
    }
  }

  // Update user profile
  static Future<void> updateUserProfile(String email, Map<String, dynamic> data) async {
    try {
      data['updatedOn'] = Timestamp.now();
      await _firestore
          .collection('users')
          .doc(email)
          .update(data);
    } catch (e) {
      rethrow;
    }
  }

  // Delete user
  static Future<void> deleteUser(String email) async {
    try {
      await _firestore
          .collection('users')
          .doc(email)
          .delete();
    } catch (e) {
      rethrow;
    }
  }
} 