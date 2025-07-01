import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class WeatherWidget extends StatefulWidget {
  final String city;
  final String apiKey;
  final Duration refreshInterval;

  const WeatherWidget({
    super.key,
    required this.city,
    required this.apiKey,
    this.refreshInterval = const Duration(minutes: 5),
  });

  @override
  State<WeatherWidget> createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget> {
  late StreamController<Map<String, dynamic>> _weatherController;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _weatherController = StreamController<Map<String, dynamic>>();
    _fetchWeather();
    _timer = Timer.periodic(widget.refreshInterval, (_) => _fetchWeather());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _weatherController.close();
    super.dispose();
  }

  Future<void> _fetchWeather() async {
    final url = 'https://api.weatherapi.com/v1/current.json?key=${widget.apiKey}&q=${Uri.encodeComponent(widget.city)}&aqi=no';
    try {
      final response = await http.get(Uri.parse(url));
      //print('WeatherAPI.com response: ${response.statusCode} ${response.body}'); // Debug print
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _weatherController.add(data);
      } else {
        _weatherController.addError('Failed to fetch weather');
      }
    } catch (e) {
      _weatherController.addError('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: _weatherController.stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 80,
            child: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return const SizedBox(
            height: 80,
            child: Center(child: Text('Weather unavailable', style: TextStyle(color: Colors.red))),
          );
        } else if (snapshot.hasData) {
          final data = snapshot.data!;
          final temp = data['current']?['temp_c']?.toStringAsFixed(1) ?? '--';
          final condition = data['current']?['condition']?['text'] ?? '--';
          final city = data['location']?['name'] ?? widget.city;
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wb_sunny, color: Colors.orange, size: 32),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$city', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('$temp°C, $condition', style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                ],
              ),
            ),
          );
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }
} 