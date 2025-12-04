class SensorData {
  final double heartRate;
  final double spo2;
  final bool valid;
  final Map<String, double>? accel;
  final Map<String, double>? gyro;
  final int lastUpdate;

  SensorData({
    required this.heartRate,
    required this.spo2,
    required this.valid,
    this.accel,
    this.gyro,
    required this.lastUpdate,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      heartRate: (json['heart_rate'] ?? 0).toDouble(),
      spo2: (json['spo2'] ?? 0).toDouble(),
      valid: json['valid'] ?? false,
      lastUpdate: json['last_update'] ?? 0,
      accel: json['accel'] != null
          ? {
              'x': (json['accel']['x'] ?? 0.0).toDouble(),
              'y': (json['accel']['y'] ?? 0.0).toDouble(),
              'z': (json['accel']['z'] ?? 0.0).toDouble(),
            }
          : null,
      gyro: json['gyro'] != null
          ? {
              'x': (json['gyro']['x'] ?? 0.0).toDouble(),
              'y': (json['gyro']['y'] ?? 0.0).toDouble(),
              'z': (json['gyro']['z'] ?? 0.0).toDouble(),
            }
          : null,
    );
  }
}
