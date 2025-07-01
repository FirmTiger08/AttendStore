import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class EmployeeMasterScreen extends StatefulWidget {
  final bool isAdmin;
  final String userEmail;
  
  const EmployeeMasterScreen({
    super.key,
    this.isAdmin = false,
    required this.userEmail,
  });

  @override
  State<EmployeeMasterScreen> createState() => _EmployeeMasterScreenState();
}

class _EmployeeMasterScreenState extends State<EmployeeMasterScreen> {
  final _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _employees = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    try {
      final QuerySnapshot snapshot = await _firestore.collection('users').get();
      setState(() {
        _employees = snapshot.docs.map((doc) {
          return {
            'email': doc.id,
            ...doc.data() as Map<String, dynamic>,
          };
        }).toList();
        
        if (!widget.isAdmin) {
          // Filter to show only the logged-in user's data
          _employees = _employees.where(
            (emp) => emp['email'] == widget.userEmail
          ).toList();
        }
        
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading employees: $e')),
        );
      }
    }
  }

  Future<void> _addEmployee(Map<String, dynamic> employeeData) async {
    try {
      final email = employeeData['email'] as String;
      
      // Add timestamps
      final now = Timestamp.now();
      employeeData['createdOn'] = now;
      employeeData['updatedOn'] = now;
      employeeData['createdBy'] = widget.userEmail;
      employeeData['updatedBy'] = widget.userEmail;
      
      // Ensure password exists
      if (!employeeData.containsKey('password')) {
        employeeData['password'] = '123456'; // Default password
      }
      
      await _firestore.collection('users').doc(email).set(employeeData);
      _loadEmployees();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding employee: $e')),
        );
      }
    }
  }

  Future<void> _editEmployee(Map<String, dynamic> employeeData) async {
    try {
      final email = employeeData['email'] as String;
      
      // Update timestamp
      employeeData['updatedOn'] = Timestamp.now();
      employeeData['updatedBy'] = widget.userEmail;
      
      await _firestore.collection('users').doc(email).update(employeeData);
      _loadEmployees();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating employee: $e')),
        );
      }
    }
  }

  Future<void> _deleteEmployee(String email) async {
    try {
      await _firestore.collection('users').doc(email).delete();
      _loadEmployees();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting employee: $e')),
        );
      }
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      if (timestamp is Timestamp) {
        return DateFormat('dd-MM-yyyy').format(timestamp.toDate());
      }
      return 'Invalid Date';
    } catch (e) {
      return 'Invalid Date';
    }
  }

  Future<void> _showAddEmployeeDialog() async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();
    final designationController = TextEditingController();
    DateTime? selectedDob;
    DateTime? selectedJoiningDate;
    String selectedGender = 'male';
    String selectedRole = 'employee';
    String selectedStatus = 'active';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Employee'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name *'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter name';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email *'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: 'Password *'),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter password';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone *'),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter phone number';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: addressController,
                  decoration: const InputDecoration(labelText: 'Address *'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter address';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: designationController,
                  decoration: const InputDecoration(labelText: 'Designation *'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter designation';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Gender: '),
                    DropdownButton<String>(
                      value: selectedGender,
                      items: ['male', 'female', 'other'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value.toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          selectedGender = newValue;
                          (context as Element).markNeedsBuild();
                        }
                      },
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Text('Role: '),
                    DropdownButton<String>(
                      value: selectedRole,
                      items: ['admin', 'employee'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value.toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          selectedRole = newValue;
                          (context as Element).markNeedsBuild();
                        }
                      },
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Text('Status: '),
                    DropdownButton<String>(
                      value: selectedStatus,
                      items: ['active', 'inactive'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value.toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          selectedStatus = newValue;
                          (context as Element).markNeedsBuild();
                        }
                      },
                    ),
                  ],
                ),
                ListTile(
                  title: Text('Date of Birth: ${selectedDob != null ? DateFormat('dd-MM-yyyy').format(selectedDob!) : "Not set"}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDob ?? DateTime.now(),
                      firstDate: DateTime(1950),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      selectedDob = date;
                      (context as Element).markNeedsBuild();
                    }
                  },
                ),
                ListTile(
                  title: Text('Joining Date: ${selectedJoiningDate != null ? DateFormat('dd-MM-yyyy').format(selectedJoiningDate!) : "Not set"}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedJoiningDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      selectedJoiningDate = date;
                      (context as Element).markNeedsBuild();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate() && selectedDob != null && selectedJoiningDate != null) {
                Navigator.of(context).pop(true);
              } else if (selectedDob == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select date of birth')),
                );
              } else if (selectedJoiningDate == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select joining date')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result == true) {
      final newEmployee = {
        'name': nameController.text,
        'email': emailController.text,
        'password': passwordController.text,
        'phone': int.parse(phoneController.text),
        'address': addressController.text,
        'designation': designationController.text,
        'gender': selectedGender,
        'role': selectedRole,
        'status': selectedStatus,
        'dob': Timestamp.fromDate(selectedDob!),
        'joiningDate': Timestamp.fromDate(selectedJoiningDate!),
      };

      await _addEmployee(newEmployee);
    }

    // Clean up
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    addressController.dispose();
    designationController.dispose();
  }

  Future<void> _showEditEmployeeDialog(Map<String, dynamic> employee) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: employee['name']);
    final phoneController = TextEditingController(text: employee['phone'].toString());
    final addressController = TextEditingController(text: employee['address']);
    final designationController = TextEditingController(text: employee['designation']);
    String selectedGender = employee['gender'] ?? 'male';
    String selectedStatus = employee['status'] ?? 'active';
    String selectedRole = employee['role'] ?? 'employee';
    
    final isEmployeeAdmin = employee['role']?.toLowerCase() == 'admin';
    final isOwnProfile = widget.userEmail == employee['email'];
    final canEditRole = widget.isAdmin && !isEmployeeAdmin;
    
    // Convert string dates or timestamps to DateTime
    DateTime? selectedDob;
    if (employee['dob'] is Timestamp) {
      selectedDob = (employee['dob'] as Timestamp).toDate();
    } else if (employee['dob'] is String) {
      try {
        selectedDob = DateTime.parse(employee['dob']);
      } catch (e) {
        selectedDob = null;
      }
    }

    DateTime? selectedJoiningDate;
    if (employee['joiningDate'] is Timestamp) {
      selectedJoiningDate = (employee['joiningDate'] as Timestamp).toDate();
    } else if (employee['joiningDate'] is String) {
      try {
        selectedJoiningDate = DateTime.parse(employee['joiningDate']);
      } catch (e) {
        selectedJoiningDate = null;
      }
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.isAdmin ? 'Edit Employee' : 'Edit Profile'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name *'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter name';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone *'),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter phone number';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: addressController,
                  decoration: const InputDecoration(labelText: 'Address *'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter address';
                    }
                    return null;
                  },
                ),
                if (widget.isAdmin && (!isEmployeeAdmin || isOwnProfile))
                  TextFormField(
                    controller: designationController,
                    decoration: const InputDecoration(labelText: 'Designation *'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter designation';
                      }
                      return null;
                    },
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text('Designation: ${employee['designation']}'),
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Gender: '),
                    DropdownButton<String>(
                      value: selectedGender,
                      items: ['male', 'female', 'other'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value.toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          selectedGender = newValue;
                          (context as Element).markNeedsBuild();
                        }
                      },
                    ),
                  ],
                ),
                if (widget.isAdmin && (!isEmployeeAdmin || isOwnProfile)) ...[
                  Row(
                    children: [
                      const Text('Status: '),
                      DropdownButton<String>(
                        value: selectedStatus,
                        items: ['active', 'inactive'].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value.toUpperCase()),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            selectedStatus = newValue;
                            (context as Element).markNeedsBuild();
                          }
                        },
                      ),
                    ],
                  ),
                  if (canEditRole)
                    Row(
                      children: [
                        const Text('Role: '),
                        DropdownButton<String>(
                          value: selectedRole,
                          items: ['admin', 'employee'].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value.toUpperCase()),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              selectedRole = newValue;
                              (context as Element).markNeedsBuild();
                            }
                          },
                        ),
                      ],
                    ),
                ] else
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Status: ${employee['status']?.toUpperCase()}'),
                        Text('Role: ${employee['role']?.toUpperCase()}'),
                      ],
                    ),
                  ),
                ListTile(
                  title: Text('Date of Birth: ${selectedDob != null ? DateFormat('dd-MM-yyyy').format(selectedDob!) : "Not set"}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDob ?? DateTime.now(),
                      firstDate: DateTime(1950),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      selectedDob = date;
                      (context as Element).markNeedsBuild();
                    }
                  },
                ),
                if (widget.isAdmin && (!isEmployeeAdmin || isOwnProfile))
                  ListTile(
                    title: Text('Joining Date: ${selectedJoiningDate != null ? DateFormat('dd-MM-yyyy').format(selectedJoiningDate!) : "Not set"}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedJoiningDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) {
                        selectedJoiningDate = date;
                        (context as Element).markNeedsBuild();
                      }
                    },
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text('Joining Date: ${_formatDate(employee['joiningDate'])}'),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate() && selectedDob != null) {
                if (widget.isAdmin && (!isEmployeeAdmin || isOwnProfile) && selectedJoiningDate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select joining date')),
                  );
                  return;
                }
                Navigator.of(context).pop(true);
              } else if (selectedDob == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select date of birth')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true) {
      final updatedEmployee = {
        ...employee,
        'name': nameController.text,
        'phone': int.parse(phoneController.text),
        'address': addressController.text,
        'gender': selectedGender,
        'dob': Timestamp.fromDate(selectedDob!),
      };

      // Only include admin-editable fields if the user is an admin and can edit this user
      if (widget.isAdmin && (!isEmployeeAdmin || isOwnProfile)) {
        updatedEmployee.addAll({
          'designation': designationController.text,
          'status': selectedStatus,
          'joiningDate': Timestamp.fromDate(selectedJoiningDate!),
        });
        
        // Only include role if it can be edited
        if (canEditRole) {
          updatedEmployee['role'] = selectedRole;
        }
      }

      await _editEmployee(updatedEmployee);
    }

    // Clean up
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    designationController.dispose();
  }

  Future<void> _showDeleteConfirmation(String email) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this employee?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _deleteEmployee(email);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Master',style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        actions: [
          if (widget.isAdmin)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _showAddEmployeeDialog,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _employees.length,
              itemBuilder: (context, index) {
                final employee = _employees[index];
                final isEmployeeAdmin = employee['role']?.toLowerCase() == 'admin';
                final isOwnProfile = widget.userEmail == employee['email'];
                
                return ExpansionTile(
                  leading: const Icon(Icons.person),
                  title: Text(employee['name'] ?? ''),
                  subtitle: Text(employee['email'] ?? ''),
                  trailing: widget.isAdmin
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(employee['role']?.toUpperCase() ?? ''),
                            if (isOwnProfile)
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _showEditEmployeeDialog(employee),
                              ),
                            if (!isEmployeeAdmin && !isOwnProfile)
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _showEditEmployeeDialog(employee),
                              ),
                            if (!isEmployeeAdmin && !isOwnProfile)
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _showDeleteConfirmation(employee['email']),
                              ),
                          ],
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(employee['role']?.toUpperCase() ?? ''),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showEditEmployeeDialog(employee),
                            ),
                          ],
                        ),
                  children: [
                    ListTile(
                      title: const Text('Details'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Designation: ${employee['designation'] ?? 'N/A'}'),
                          Text('Phone: ${employee['phone'] ?? 'N/A'}'),
                          Text('Address: ${employee['address'] ?? 'N/A'}'),
                          Text('Gender: ${employee['gender'] ?? 'N/A'}'),
                          Text('Status: ${employee['status'] ?? 'N/A'}'),
                          Text('DOB: ${_formatDate(employee['dob'])}'),
                          Text('Joining Date: ${_formatDate(employee['joiningDate'])}'),
                          if (widget.isAdmin) ...[
                            Text('Created By: ${employee['createdBy'] ?? 'N/A'}'),
                            Text('Created On: ${_formatDate(employee['createdOn'])}'),
                            Text('Updated By: ${employee['updatedBy'] ?? 'N/A'}'),
                            Text('Updated On: ${_formatDate(employee['updatedOn'])}'),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
} 