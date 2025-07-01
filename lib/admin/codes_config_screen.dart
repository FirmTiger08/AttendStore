import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CodesConfigScreen extends StatefulWidget {
  final String userEmail;

  const CodesConfigScreen({
    super.key,
    required this.userEmail,
  });

  @override
  State<CodesConfigScreen> createState() => _CodesConfigScreenState();
}

class _CodesConfigScreenState extends State<CodesConfigScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  String _selectedCodeType = 'leaveType';
  final _codeValueController = TextEditingController();
  final _longDescController = TextEditingController();
  final _shortDescController = TextEditingController();
  final _value1Controller = TextEditingController();
  bool _isActive = true;

  // Available code types
  final List<Map<String, String>> _codeTypes = [
    {'value': 'leaveType', 'label': 'Leave Type'},
    {'value': 'designation', 'label': 'Designation'},
    {'value': 'officeLocation', 'label': 'Office Location'},
  ];

  // Controllers for office location fields
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _radiusController = TextEditingController();

  @override
  void dispose() {
    _codeValueController.dispose();
    _longDescController.dispose();
    _shortDescController.dispose();
    _value1Controller.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  void _resetForm() {
    _codeValueController.clear();
    _longDescController.clear();
    _shortDescController.clear();
    _value1Controller.clear();
    _latitudeController.clear();
    _longitudeController.clear();
    _radiusController.clear();
    _isActive = true;
  }

  String _getCodeTypeLabel(String value) {
    return _codeTypes.firstWhere((type) => type['value'] == value)['label'] ?? value;
  }

  Future<void> _addCode() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final now = DateTime.now();
      Map<String, dynamic> data = {
        'codeType': _selectedCodeType,
        'active': _isActive,
        'createdBy': widget.userEmail,
        'createdOn': now,
        'updatedBy': widget.userEmail,
        'updatedOn': now,
        'flex1': null,
      };
      if (_selectedCodeType == 'officeLocation') {
        data.addAll({
          'codeValue': _codeValueController.text.trim(), // Office name
          'longDescription': _longDescController.text.trim(), // Address
          'shortDescription': _shortDescController.text.trim(), // Short address
          'value1': _latitudeController.text.trim(), // Latitude
          'value2': _longitudeController.text.trim(), // Longitude
          'Radius': int.tryParse(_radiusController.text.trim()) ?? 0, // Radius
        });
      } else {
        data.addAll({
          'codeValue': _codeValueController.text.trim(),
          'longDescription': _longDescController.text.trim(),
          'shortDescription': _shortDescController.text.trim(),
          'value1': _value1Controller.text.trim(),
          'value2': null,
        });
      }
      await _firestore.collection('codes').add(data);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_getCodeTypeLabel(_selectedCodeType)} added successfully')),
      );
      _resetForm();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding ${_getCodeTypeLabel(_selectedCodeType)}: $e')),
      );
    }
  }

  void _showEditDialog(String docId, Map<String, dynamic> data) {
    final formKey = GlobalKey<FormState>();
    final codeType = data['codeType'] as String? ?? '';
    final codeValueController = TextEditingController(text: data['codeValue'] ?? '');
    final longDescController = TextEditingController(text: data['longDescription'] ?? '');
    final shortDescController = TextEditingController(text: data['shortDescription'] ?? '');
    final value1Controller = TextEditingController(text: data['value1'] ?? '');
    final value2Controller = TextEditingController(text: data['value2'] ?? '');
    final radiusController = TextEditingController(text: data['Radius']?.toString() ?? '');
    bool isActive = data['active'] ?? true;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Configuration'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (codeType == 'officeLocation') ...[
                  TextFormField(
                    controller: codeValueController,
                    decoration: const InputDecoration(labelText: 'Office Name'),
                    validator: (value) => value == null || value.trim().isEmpty ? 'Enter office name' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: longDescController,
                    decoration: const InputDecoration(labelText: 'Office Address'),
                    validator: (value) => value == null || value.trim().isEmpty ? 'Enter office address' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: shortDescController,
                    decoration: const InputDecoration(labelText: 'Short Address'),
                    validator: (value) => value == null || value.trim().isEmpty ? 'Enter short address' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: value1Controller,
                    decoration: const InputDecoration(labelText: 'Latitude'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Enter latitude';
                      final lat = double.tryParse(value);
                      if (lat == null || lat < -90 || lat > 90) return 'Latitude must be between -90 and 90';
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: value2Controller,
                    decoration: const InputDecoration(labelText: 'Longitude'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Enter longitude';
                      final lng = double.tryParse(value);
                      if (lng == null || lng < -180 || lng > 180) return 'Longitude must be between -180 and 180';
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: radiusController,
                    decoration: const InputDecoration(labelText: 'Radius (meters)'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Enter radius';
                      final radius = int.tryParse(value);
                      if (radius == null || radius <= 0) return 'Radius must be positive';
                      return null;
                    },
                  ),
                ] else ...[
                  TextFormField(
                    controller: codeValueController,
                    decoration: InputDecoration(labelText: codeType == 'leaveType' ? 'Leave Type' : 'Designation'),
                    validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: longDescController,
                    decoration: const InputDecoration(labelText: 'Long Description'),
                    validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: shortDescController,
                    decoration: const InputDecoration(labelText: 'Short Description'),
                    validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: value1Controller,
                    decoration: const InputDecoration(labelText: 'Additional Value'),
                    validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Active: '),
                    Switch(
                      value: isActive,
                      onChanged: (val) {
                        isActive = val;
                        (context as Element).markNeedsBuild();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final updateData = <String, dynamic>{
                'codeValue': codeValueController.text.trim(),
                'longDescription': longDescController.text.trim(),
                'shortDescription': shortDescController.text.trim(),
                'active': isActive,
        'updatedBy': widget.userEmail,
                'updatedOn': DateTime.now(),
              };
              if (codeType == 'officeLocation') {
                updateData['value1'] = value1Controller.text.trim();
                updateData['value2'] = value2Controller.text.trim();
                updateData['Radius'] = int.tryParse(radiusController.text.trim()) ?? 0;
              } else {
                updateData['value1'] = value1Controller.text.trim();
              }
              await _firestore.collection('codes').doc(docId).update(updateData);
              if (context.mounted) Navigator.of(context).pop();
              if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Configuration updated successfully')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Configuration'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Add new code form
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Add New Configuration',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _selectedCodeType,
                              decoration: const InputDecoration(
                                labelText: 'Code Type',
                                border: OutlineInputBorder(),
                              ),
                              items: _codeTypes.map((type) {
                                return DropdownMenuItem(
                                  value: type['value'],
                                  child: Text(type['label']!),
                                );
                              }).toList(),
                              onChanged: (String? value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedCodeType = value;
                                  });
                                }
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please select a code type';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            if (_selectedCodeType == 'officeLocation') ...[
                              TextFormField(
                                controller: _codeValueController,
                                decoration: const InputDecoration(
                                  labelText: 'Office Name',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter office name';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _longDescController,
                                decoration: const InputDecoration(
                                  labelText: 'Office Address',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter office address';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _shortDescController,
                                decoration: const InputDecoration(
                                  labelText: 'Short Address',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter short address';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _latitudeController,
                                decoration: const InputDecoration(
                                  labelText: 'Latitude',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter latitude';
                                  }
                                  final lat = double.tryParse(value);
                                  if (lat == null || lat < -90 || lat > 90) {
                                    return 'Latitude must be between -90 and 90';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _longitudeController,
                                decoration: const InputDecoration(
                                  labelText: 'Longitude',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter longitude';
                                  }
                                  final lng = double.tryParse(value);
                                  if (lng == null || lng < -180 || lng > 180) {
                                    return 'Longitude must be between -180 and 180';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _radiusController,
                                decoration: const InputDecoration(
                                  labelText: 'Radius (meters)',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter radius';
                                  }
                                  final radius = int.tryParse(value);
                                  if (radius == null || radius <= 0) {
                                    return 'Radius must be a positive integer';
                                  }
                                  return null;
                                },
                              ),
                            ] else ...[
                              TextFormField(
                                controller: _codeValueController,
                                decoration: InputDecoration(
                                  labelText: _selectedCodeType == 'leaveType' ? 'Leave Type' : 'Designation',
                                  border: const OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter ${_selectedCodeType == 'leaveType' ? 'leave type' : 'designation'}';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _longDescController,
                                decoration: const InputDecoration(
                                  labelText: 'Long Description',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _shortDescController,
                                decoration: const InputDecoration(
                                  labelText: 'Short Description',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _value1Controller,
                                decoration: const InputDecoration(
                                  labelText: 'Additional Value',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                              ),
                            ],
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                const Text('Active: '),
                                Switch(
                                  value: _isActive,
                                  onChanged: (bool value) {
                                    setState(() {
                                      _isActive = value;
                                    });
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _addCode,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: Text('Add ${_getCodeTypeLabel(_selectedCodeType)}'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Existing Configurations',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  StreamBuilder<QuerySnapshot>(
                    stream: _firestore.collection('codes').orderBy('codeType').orderBy('codeValue').snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final codeDocs = snapshot.data!.docs;
                      if (codeDocs.isEmpty) {
                        return const Center(child: Text('No configurations found'));
                      }
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: codeDocs.length,
                        itemBuilder: (context, index) {
                          final doc = codeDocs[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final codeType = data['codeType'] as String? ?? 'unknown';
                          final codeValue = data['codeValue'] as String? ?? '';
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      codeValue,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: codeType == 'leaveType'
                                          ? Colors.blue
                                          : codeType == 'designation'
                                              ? Colors.green
                                              : Colors.orange,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _getCodeTypeLabel(codeType),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['longDescription'] ?? '',
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Info: ${data['shortDescription'] ?? ''}',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (data['Radius'] != null && data['Radius'].toString().isNotEmpty)
                                    Text(
                                      'Radius: ${data['Radius']}',
                                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _showEditDialog(doc.id, data),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 