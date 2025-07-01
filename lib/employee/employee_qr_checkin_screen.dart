import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_scanner/mobile_scanner.dart' as mobile_scanner;
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class EmployeeQRCheckinScreen extends StatefulWidget {
  final String userEmail;
  const EmployeeQRCheckinScreen({super.key, required this.userEmail});

  @override
  State<EmployeeQRCheckinScreen> createState() => _EmployeeQRCheckinScreenState();
}

class _EmployeeQRCheckinScreenState extends State<EmployeeQRCheckinScreen> {
  final _firestore = FirebaseFirestore.instance;
  bool _isProcessing = false;
  String? _resultMessage;
  Color _resultColor = Colors.black;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _onDetect(mobile_scanner.BarcodeCapture capture) async {
    if (_isProcessing) return;
    setState(() {
      _isProcessing = true;
      _resultMessage = 'Processing QR code...';
      _resultColor = Colors.blue;
    });

    try {
      final barcode = capture.barcodes.first;
      final qrDataStr = barcode.rawValue;
      if (qrDataStr == null) {
        _showError('Invalid QR code.');
        return;
      }

      // Parse QR data
      Map<String, dynamic> qrData;
      try {
        qrData = json.decode(qrDataStr);
      } catch (e) {
        _showError('Invalid QR code format.');
        return;
      }

      // Validate QR data
      if (!qrData.containsKey('officeId') || 
          !qrData.containsKey('type') || 
          !qrData.containsKey('date') ||
          !qrData.containsKey('securityKey')) {
        _showError('Invalid QR code format: missing required fields.');
        return;
      }

      final officeId = qrData['officeId'];
      final qrType = qrData['type'];
      final qrDate = qrData['date'];
      final securityKey = qrData['securityKey'];

      // Verify QR code authenticity from database
      final qrDocId = '${officeId}_$qrType';
      final qrDoc = await _firestore.collection('qrCodes').doc(qrDocId).get();
      
      if (!qrDoc.exists) {
        _showError('Invalid QR code: not found in system.');
        return;
      }

      final storedQRData = qrDoc.data()!;
      if (storedQRData['securityKey'] != securityKey) {
        _showError('Invalid QR code: security key mismatch.');
        return;
      }

      if (!storedQRData['active']) {
        _showError('This QR code has been deactivated.');
        return;
      }

      // Validate date
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      if (qrDate != todayStr) {
        _showError('This QR code has expired. Please use today\'s code.');
        return;
      }

      // Get current location
      final position = await _getCurrentPosition();
      if (position == null) {
        _showError('Unable to get your location. Please enable location services and try again.');
        return;
      }

      // Fetch office location
      final officeDoc = await _firestore.collection('codes').doc(officeId).get();
      if (!officeDoc.exists) {
        _showError('Invalid office location.');
        return;
      }

      final office = officeDoc.data()!;
      final officeLat = double.tryParse(office['value1'] ?? '') ?? 0.0;
      final officeLng = double.tryParse(office['value2'] ?? '') ?? 0.0;
      final officeRadius = office['Radius'] is int ? office['Radius'] : int.tryParse(office['Radius'].toString()) ?? 0;

      // Check distance
      final distance = Geolocator.distanceBetween(
        position.latitude, position.longitude, officeLat, officeLng);
      if (distance > officeRadius) {
        _showError('You are not within the office premises.');
        return;
      }

      // Check attendance status
      final attendanceRef = _firestore.collection('attendance').doc(widget.userEmail);
      final attendanceDoc = await attendanceRef.get();
      Map<String, dynamic> attendanceData = attendanceDoc.exists ? attendanceDoc.data()! : {};
      Map<String, dynamic> dayData = attendanceData[todayStr] ?? {};

      // Validate check-in/out status
      if (qrType == 'checkin') {
        if (dayData['checkIn'] != null) {
          _showError('You have already checked in today.');
          return;
        }
        dayData['checkIn'] = Timestamp.now();
        dayData['status'] = 'present';
        dayData['checkInLocation'] = GeoPoint(position.latitude, position.longitude);
      } else if (qrType == 'checkout') {
        if (dayData['checkOut'] != null) {
          _showError('You have already checked out today.');
          return;
        }
        if (dayData['checkIn'] == null) {
          _showError('You must check in before checking out.');
          return;
        }
        dayData['checkOut'] = Timestamp.now();
        dayData['checkOutLocation'] = GeoPoint(position.latitude, position.longitude);
        
        // Calculate working hours
        final checkInTime = (dayData['checkIn'] as Timestamp).toDate();
        final checkOutTime = DateTime.now();
        final workingHours = checkOutTime.difference(checkInTime).inMinutes / 60.0;
        dayData['workingHours'] = double.parse(workingHours.toStringAsFixed(2));
      }

      // Update attendance record
      attendanceData[todayStr] = dayData;
      await attendanceRef.set(attendanceData, SetOptions(merge: true));

      if (!mounted) return;  // Add early return if widget is disposed

      setState(() {
        _resultMessage = 'Successfully ${qrType == 'checkin' ? 'checked in' : 'checked out'}!';
        _resultColor = Colors.green;
        _isProcessing = false;
      });

      // Auto-close after successful check-in/out
      if (!mounted) return;  // Add another check before scheduling the delayed operation
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;  // Final check before popping
        Navigator.pop(context);
      });

    } catch (e) {
      if (!mounted) return;  // Add check before showing error
      _showError('An error occurred: $e');
    }
  }

  void _showError(String message) {
    setState(() {
      _resultMessage = message;
      _resultColor = Colors.red;
      _isProcessing = false;
    });
  }

  Future<Position?> _getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      return null;
    }
  }

  Widget _buildStatusMessage() {
    if (_resultMessage == null && !_isProcessing) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: _isProcessing ? Colors.blue.withValues(alpha: 0.1) : _resultColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_isProcessing)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          Flexible(
            child: Text(
              _isProcessing ? 'Processing QR code...' : _resultMessage!,
              style: TextStyle(
                color: _isProcessing ? Colors.blue : _resultColor,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
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
        title: const Text('QR Check-In/Out'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                mobile_scanner.MobileScanner(
                  onDetect: _onDetect,
                ),
                // Simple scanning overlay
                Center(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).primaryColor,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildStatusMessage(),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).cardColor,
            child: const Text(
              'Point your camera at the QR code',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
} 