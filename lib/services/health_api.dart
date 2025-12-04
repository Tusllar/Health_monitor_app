import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sensor_data.dart';
import '../models/alert_event.dart';

enum ConnectionStatus { connected, disconnected, connecting }

class HealthApiService {
  final String baseUrl;
  ConnectionStatus _status = ConnectionStatus.disconnected;
  int _retryCount = 0;
  static const int maxRetries = 3;

  HealthApiService(this.baseUrl);

  ConnectionStatus get status => _status;

  Future<SensorData?> fetchSensorData() async {
    try {
      _status = ConnectionStatus.connecting;
      
      final response = await http.get(
        Uri.parse('$baseUrl/sensor'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _status = ConnectionStatus.connected;
        _retryCount = 0;
        return SensorData.fromJson(data);
      } else {
        _status = ConnectionStatus.disconnected;
        return await _handleRetry();
      }
    } catch (e) {
      print('Error fetching sensor data: $e');
      _status = ConnectionStatus.disconnected;
      return await _handleRetry();
    }
  }

  Future<SensorData?> _handleRetry() async {
    if (_retryCount < maxRetries) {
      _retryCount++;
      await Future.delayed(Duration(seconds: _retryCount));
      return await fetchSensorData();
    }
    return null;
  }

  void resetRetry() {
    _retryCount = 0;
  }

  /// Fetch alert history from `/alerts` endpoint.
  Future<List<AlertEvent>> fetchAlerts() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/alerts'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body) as Map<String, dynamic>;
        final list = (decoded['alerts'] as List? ?? [])
            .cast<Map<String, dynamic>>();
        return list.map(AlertEvent.fromJson).toList();
      }
    } catch (e) {
      print('Error fetching alerts: $e');
    }
    return [];
  }
}