import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  final String userEmail;

  const ProfileScreen({
    super.key,
    required this.userEmail,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  bool _isEditing = false;

  // Controllers for editable fields
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  String _selectedGender = 'male';
  DateTime? _selectedDob;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final doc = await _firestore.collection('users').doc(widget.userEmail).get();
      setState(() {
        _userData = doc.data();
        _isLoading = false;
        
        // Initialize controllers with current data
        _nameController.text = _userData?['name'] ?? '';
        _phoneController.text = _userData?['phone']?.toString() ?? '';
        _addressController.text = _userData?['address'] ?? '';
        _selectedGender = _userData?['gender'] ?? 'male';
        
        if (_userData?['dob'] is Timestamp) {
          _selectedDob = (_userData!['dob'] as Timestamp).toDate();
        }
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate() || _selectedDob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    try {
      final updatedData = {
        'name': _nameController.text,
        'phone': int.parse(_phoneController.text),
        'address': _addressController.text,
        'gender': _selectedGender,
        'dob': Timestamp.fromDate(_selectedDob!),
        'updatedOn': Timestamp.now(),
        'updatedBy': widget.userEmail,
      };
      
      await _firestore.collection('users').doc(widget.userEmail).update(updatedData);
      await _loadUserData();
      
      setState(() => _isEditing = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
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

  Widget _buildField({
    required String label,
    required String value,
    bool isEditable = false,
    Widget? editWidget,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          Expanded(
            child: _isEditing && isEditable
                ? editWidget ?? const SizedBox()
                : Text(
                    value,
                    style: const TextStyle(fontSize: 16),
                  ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userData == null
              ? const Center(child: Text('Error loading profile'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Card(
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Personal Information',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Divider(),
                                _buildField(
                                  label: 'Name',
                                  value: _userData!['name'] ?? 'N/A',
                                  isEditable: true,
                                  editWidget: TextFormField(
                                    controller: _nameController,
                                    decoration: const InputDecoration(
                                      hintText: 'Enter name',
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter name';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                _buildField(
                                  label: 'Email',
                                  value: widget.userEmail,
                                ),
                                _buildField(
                                  label: 'Phone',
                                  value: _userData!['phone']?.toString() ?? 'N/A',
                                  isEditable: true,
                                  editWidget: TextFormField(
                                    controller: _phoneController,
                                    decoration: const InputDecoration(
                                      hintText: 'Enter phone number',
                                      border: OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.phone,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter phone number';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                _buildField(
                                  label: 'Address',
                                  value: _userData!['address'] ?? 'N/A',
                                  isEditable: true,
                                  editWidget: TextFormField(
                                    controller: _addressController,
                                    decoration: const InputDecoration(
                                      hintText: 'Enter address',
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter address';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                _buildField(
                                  label: 'Gender',
                                  value: _userData!['gender']?.toUpperCase() ?? 'N/A',
                                  isEditable: true,
                                  editWidget: DropdownButtonFormField<String>(
                                    value: _selectedGender,
                                    items: ['male', 'female', 'other'].map((String value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(value.toUpperCase()),
                                      );
                                    }).toList(),
                                    onChanged: (String? newValue) {
                                      if (newValue != null) {
                                        setState(() => _selectedGender = newValue);
                                      }
                                    },
                                    decoration: const InputDecoration(
                                      hintText: 'Select gender',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                _buildField(
                                  label: 'Date of Birth',
                                  value: _formatDate(_userData!['dob']),
                                  isEditable: true,
                                  editWidget: InkWell(
                                    onTap: () async {
                                      final date = await showDatePicker(
                                        context: context,
                                        initialDate: _selectedDob ?? DateTime.now(),
                                        firstDate: DateTime(1950),
                                        lastDate: DateTime.now(),
                                      );
                                      if (date != null) {
                                        setState(() => _selectedDob = date);
                                      }
                                    },
                                    child: InputDecorator(
                                      decoration: const InputDecoration(
                                        hintText: 'Select date of birth',
                                        border: OutlineInputBorder(),
                                      ),
                                      child: Text(
                                        _selectedDob != null
                                            ? DateFormat('dd-MM-yyyy').format(_selectedDob!)
                                            : 'Select date of birth',
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Card(
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Employment Information',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Divider(),
                                _buildField(
                                  label: 'Role',
                                  value: _userData!['role']?.toUpperCase() ?? 'N/A',
                                ),
                                _buildField(
                                  label: 'Status',
                                  value: _userData!['status']?.toUpperCase() ?? 'N/A',
                                ),
                                _buildField(
                                  label: 'Designation',
                                  value: _userData!['designation'] ?? 'N/A',
                                ),
                                _buildField(
                                  label: 'Joining Date',
                                  value: _formatDate(_userData!['joiningDate']),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (!_isEditing)
                          Center(
                            child: ElevatedButton.icon(
                              onPressed: () => setState(() => _isEditing = true),
                              icon: const Icon(Icons.edit),
                              label: const Text('Edit Profile'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          )
                        else
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _isEditing = false;
                                    // Reset controllers to original values
                                    _nameController.text = _userData!['name'] ?? '';
                                    _phoneController.text = _userData!['phone']?.toString() ?? '';
                                    _addressController.text = _userData!['address'] ?? '';
                                    _selectedGender = _userData!['gender'] ?? 'male';
                                    if (_userData!['dob'] is Timestamp) {
                                      _selectedDob = (_userData!['dob'] as Timestamp).toDate();
                                    }
                                  });
                                },
                                icon: const Icon(Icons.cancel),
                                label: const Text('Cancel'),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton.icon(
                                onPressed: _updateProfile,
                                icon: const Icon(Icons.save),
                                label: const Text('Save Changes'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
    );
  }
}