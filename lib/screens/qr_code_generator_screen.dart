import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';
import 'dart:math';

class QRCodeGeneratorScreen extends StatefulWidget {
  final String userEmail;
  const QRCodeGeneratorScreen({super.key, required this.userEmail});

  @override
  State<QRCodeGeneratorScreen> createState() => _QRCodeGeneratorScreenState();
}

class _QRCodeGeneratorScreenState extends State<QRCodeGeneratorScreen> {
  final _firestore = FirebaseFirestore.instance;
  String? _selectedOfficeId;
  String _selectedType = 'checkin';
  bool _isLoading = true;
  bool _isGenerating = false;
  List<Map<String, dynamic>> _officeLocations = [];
  Map<String, dynamic>? _currentQRCode;

  // Generate a random 25-character hexadecimal security key
  String _generateSecurityKey() {
    final random = Random.secure();
    final values = List<int>.generate(25, (i) => random.nextInt(16));
    return values.map((v) => v.toRadixString(16)).join();
  }

  @override
  void initState() {
    super.initState();
    _loadOfficeLocations();
  }

  Future<void> _loadOfficeLocations() async {
    setState(() => _isLoading = true);
    final snapshot = await _firestore
        .collection('codes')
        .where('codeType', isEqualTo: 'officeLocation')
        .where('active', isEqualTo: true)
        .get();
    setState(() {
      _officeLocations = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      if (_officeLocations.isNotEmpty) {
        _selectedOfficeId = _officeLocations.first['id'];
      }
      _isLoading = false;
    });
  }

  Future<void> _generateQRCode() async {
    if (_selectedOfficeId == null) return;
    setState(() => _isGenerating = true);
    final office = _officeLocations.firstWhere((o) => o['id'] == _selectedOfficeId);
    final today = DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd').format(today);
    final securityKey = _generateSecurityKey();
    
    // Create QR data without Timestamp
    final qrData = {
      'type': _selectedType,
      'officeId': _selectedOfficeId,
      'officeName': office['codeValue'],
      'date': dateStr,
      'generatedBy': widget.userEmail,
      'securityKey': securityKey,
    };

    // Save to Firestore with Timestamp
    final qrDocId = '${_selectedOfficeId}_$_selectedType';
    await _firestore.collection('qrCodes').doc(qrDocId).set({
      ...qrData,
      'generatedOn': Timestamp.now(),
      'active': true,
    });

    setState(() {
      _currentQRCode = qrData;
      _isGenerating = false;
    });
    if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('QR code generated for ${office['codeValue']} ($_selectedType)')),
    );
  }}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Code Generator'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Office Location:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedOfficeId,
                    items: _officeLocations.map<DropdownMenuItem<String>>((office) {
                      return DropdownMenuItem<String>(
                        value: office['id'],
                        child: Text(office['codeValue'] ?? ''),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedOfficeId = val),
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  const Text('QR Code Type:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedType,
                    items: const [
                      DropdownMenuItem(value: 'checkin', child: Text('Check-In')),
                      DropdownMenuItem(value: 'checkout', child: Text('Check-Out')),
                    ],
                    onChanged: (val) => setState(() => _selectedType = val!),
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isGenerating ? null : _generateQRCode,
                      child: _isGenerating
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Generate QR Code for Today'),
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (_currentQRCode != null)
                    Center(
                      child: Column(
                        children: [
                          const Text('Today\'s QR Code:', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          QrImageView(
                            data: json.encode(_currentQRCode),
                            version: QrVersions.auto,
                            size: 200,
                          ),
                          const SizedBox(height: 16),
                          Text('Office: ${_currentQRCode!['officeName']}'),
                          Text('Type: ${_currentQRCode!['type']}'),
                          Text('Date: ${_currentQRCode!['date']}'),
                        ],
                      ),
                    ),
                ],
              ),
            ),
    );
  }
} 