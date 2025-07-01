import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String email;
  final String name;
  final String password;
  final String role;
  final String status;
  final String gender;
  final int phone;
  final String address;
  final String designation;
  final DateTime dob;
  final DateTime joiningDate;
  final String createdBy;
  final DateTime createdOn;
  final String updatedBy;
  final DateTime updatedOn;

  UserModel({
    required this.email,
    required this.name,
    required this.password,
    required this.role,
    required this.status,
    required this.gender,
    required this.phone,
    required this.address,
    required this.designation,
    required this.dob,
    required this.joiningDate,
    required this.createdBy,
    required this.createdOn,
    required this.updatedBy,
    required this.updatedOn,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      email: map['email'] as String? ?? '',
      name: map['name'] as String? ?? '',
      password: map['password'] as String? ?? '',
      role: (map['role'] as String?)?.toLowerCase() ?? 'employee',
      status: map['status'] as String? ?? 'active',
      gender: map['gender'] as String? ?? '',
      phone: map['phone'] as int? ?? 0,
      address: map['address'] as String? ?? '',
      designation: map['designation'] as String? ?? '',
      dob: (map['dob'] as Timestamp?)?.toDate() ?? DateTime.now(),
      joiningDate: (map['joiningDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: map['createdBy'] as String? ?? '',
      createdOn: (map['createdOn'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedBy: map['updatedBy'] as String? ?? '',
      updatedOn: (map['updatedOn'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'password': password,
      'role': role.toLowerCase(),
      'status': status,
      'gender': gender,
      'phone': phone,
      'address': address,
      'designation': designation,
      'dob': Timestamp.fromDate(dob),
      'joiningDate': Timestamp.fromDate(joiningDate),
      'createdBy': createdBy,
      'createdOn': Timestamp.fromDate(createdOn),
      'updatedBy': updatedBy,
      'updatedOn': Timestamp.fromDate(updatedOn),
    };
  }

  // Helper method to check if user is admin
  bool get isAdmin => role.toLowerCase() == 'admin';
} 