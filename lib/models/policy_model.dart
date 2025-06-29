import 'package:cloud_firestore/cloud_firestore.dart';

class Policy {
  final String? id;
  final String title;
  final String description;
  final DateTime createdOn;
  final String createdBy;
  final DateTime updatedOn;
  final String updatedBy;

  Policy({
    this.id,
    required this.title,
    required this.description,
    required this.createdOn,
    required this.createdBy,
    required this.updatedOn,
    required this.updatedBy,
  });

  // Create from Firestore document
  factory Policy.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Policy(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      createdOn: (data['createdOn'] as Timestamp).toDate(),
      createdBy: data['createdBy'] ?? '',
      updatedOn: (data['updatedOn'] as Timestamp).toDate(),
      updatedBy: data['updatedBy'] ?? '',
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'createdOn': Timestamp.fromDate(createdOn),
      'createdBy': createdBy,
      'updatedOn': Timestamp.fromDate(updatedOn),
      'updatedBy': updatedBy,
    };
  }

  // Create a copy with updated fields
  Policy copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? createdOn,
    String? createdBy,
    DateTime? updatedOn,
    String? updatedBy,
  }) {
    return Policy(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdOn: createdOn ?? this.createdOn,
      createdBy: createdBy ?? this.createdBy,
      updatedOn: updatedOn ?? this.updatedOn,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }
} 