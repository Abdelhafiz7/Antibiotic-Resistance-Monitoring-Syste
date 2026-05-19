// lib/models/sensor_data.dart
// Immutable value object representing one parsed BLE reading from Arduino.

class SensorData {
  final double temperature;  // Celsius from DHT11
  final int ldrValue;        // LDR raw ADC value (0-1023)
  final String statusRaw;    // "NORMAL" | "RISK" as sent by Arduino
  final DateTime timestamp;

  const SensorData({
    required this.temperature,
    required this.ldrValue,
    required this.statusRaw,
    required this.timestamp,
  });

  /// Returns true when environmental risk conditions are met:
  /// temperature > 30°C  OR  LDR value < 500
  bool get isRisk =>
      temperature > 30.0 || ldrValue < 500 || statusRaw == 'RISK';

  /// Human-readable status label
  String get statusLabel => isRisk ? 'RISK DETECTED' : 'SAFE';

  /// Parse a raw BLE string in format "Temperature,LDR,Status"
  /// e.g. "24.5,620,NORMAL"  or  "35.2,200,RISK"
  /// Returns null on malformed input.
  static SensorData? tryParse(String raw) {
    try {
      final parts = raw.trim().split(',');
      if (parts.length < 3) return null;
      final temp = double.parse(parts[0].trim());
      final ldr  = int.parse(parts[1].trim());
      final stat = parts[2].trim().toUpperCase();
      return SensorData(
        temperature: temp,
        ldrValue:    ldr,
        statusRaw:   stat,
        timestamp:   DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Handy copy-with helper for mock/testing
  SensorData copyWith({
    double? temperature,
    int? ldrValue,
    String? statusRaw,
    DateTime? timestamp,
  }) => SensorData(
    temperature: temperature ?? this.temperature,
    ldrValue:    ldrValue    ?? this.ldrValue,
    statusRaw:   statusRaw   ?? this.statusRaw,
    timestamp:   timestamp   ?? this.timestamp,
  );

  @override
  String toString() =>
      'SensorData(temp: $temperature, ldr: $ldrValue, status: $statusRaw)';
}
