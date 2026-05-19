import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../models/sensor_data.dart';

enum BleState {
  idle,
  scanning,
  connecting,
  connected,
  disconnected,
  error,
}

class BleService extends ChangeNotifier {
  static const String _serviceUuid        = '0000ffe0-0000-1000-8000-00805f9b34fb';
  static const String _characteristicUuid = '0000ffe1-0000-1000-8000-00805f9b34fb';

  BleState _state = BleState.idle;
  BleState get state => _state;

  BluetoothDevice? _connectedDevice;
  BluetoothDevice? get connectedDevice => _connectedDevice;

  BluetoothCharacteristic? _txCharacteristic;

  List<ScanResult> _scanResults = [];
  List<ScanResult> get scanResults => List.unmodifiable(_scanResults);

  SensorData? _latestData;
  SensorData? get latestData => _latestData;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  String _dataBuffer = '';

  final _dataController = StreamController<SensorData>.broadcast();
  Stream<SensorData> get dataStream => _dataController.stream;

  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<BluetoothConnectionState>? _connStateSub;


  Future<void> startScan() async {
    if (_state == BleState.scanning) return;

    _scanResults = [];
    _setState(BleState.scanning);

    try {
      await FlutterBluePlus.stopScan();

      _scanSub?.cancel();
      _scanSub = FlutterBluePlus.scanResults.listen((results) {
        _scanResults = results;
        notifyListeners();
      });

      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 8));

      await FlutterBluePlus.isScanning.where((v) => !v).first;
      if (_state == BleState.scanning) _setState(BleState.idle);
    } catch (e) {
      _setError('Scan failed: $e');
    }
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    _scanSub?.cancel();
    if (_state == BleState.scanning) _setState(BleState.idle);
  }

  Future<void> connect(BluetoothDevice device) async {
    _connectedDevice = device;
    _setState(BleState.connecting);
    await stopScan();

    int attempts = 3;
    bool success = false;
    dynamic lastError;

    for (int i = 1; i <= attempts; i++) {
      try {
        await device.disconnect().catchError((_) {});
        await Future.delayed(const Duration(milliseconds: 500));

        await device.connect(
          timeout: const Duration(seconds: 12),
          autoConnect: false,
        );
        success = true;
        break; 
      } catch (e) {
        lastError = e;
        if (i < attempts) {
          await Future.delayed(const Duration(seconds: 1));
        }
      }
    }

    if (!success) {
      _setError('Connection failed after $attempts attempts: $lastError');
      await disconnect();
      return;
    }

    try {
      _connStateSub?.cancel();
      _connStateSub = device.connectionState.listen((cs) {
        if (cs == BluetoothConnectionState.disconnected) {
          _onDeviceDisconnected();
        }
      });

      _connectedDevice = device;

      final services = await device.discoverServices();
      BluetoothCharacteristic? characteristic;

      for (final service in services) {
        if (service.uuid.toString().toLowerCase() == _serviceUuid) {
          for (final c in service.characteristics) {
            if (c.uuid.toString().toLowerCase() == _characteristicUuid) {
              characteristic = c;
              break;
            }
          }
        }
        if (characteristic != null) break;
      }

      if (characteristic == null) {
        final systemServiceUuids = [
          '1800', 
          '1801', 
          '180a', 
          '180f',
        ];

        for (final service in services) {
          final svcUuid = service.uuid.toString().toLowerCase();
          if (systemServiceUuids.any((sysUuid) => svcUuid.contains(sysUuid))) {
            continue;
          }
          for (final c in service.characteristics) {
            if (c.properties.notify || c.properties.read) {
              characteristic = c;
              break;
            }
          }
          if (characteristic != null) break;
        }
      }

      if (characteristic == null) {
        throw Exception('HM-10 serial characteristic not found on this device.');
      }

      _txCharacteristic = characteristic;
      await characteristic.setNotifyValue(true);

      characteristic.onValueReceived.listen(_onDataReceived);

      _setState(BleState.connected);
    } catch (e) {
      _setError('Service discovery failed: $e');
      await disconnect();
    }
  }

  Future<void> disconnect() async {
    _dataBuffer = '';
    _connStateSub?.cancel();
    _txCharacteristic = null;

    try {
      await _connectedDevice?.disconnect();
    } catch (_) {}

    _connectedDevice = null;
    if (_state != BleState.error) {
      _setState(BleState.disconnected);
    }
  }


  void _onDeviceDisconnected() {
    if (_state == BleState.connected) {
      _connectedDevice = null;
      _txCharacteristic = null;
      _dataBuffer = '';
      _setState(BleState.disconnected);
    }
  }

  void _onDataReceived(List<int> bytes) {
    final rawString = utf8.decode(bytes, allowMalformed: true);
    debugPrint('BLE Raw Bytes Received: $bytes -> "$rawString"');
    _dataBuffer += rawString;

    while (_dataBuffer.contains('\n')) {
      final idx  = _dataBuffer.indexOf('\n');
      final line = _dataBuffer.substring(0, idx).trim();
      _dataBuffer = _dataBuffer.substring(idx + 1);

      if (line.isEmpty) continue;
      debugPrint('BLE Processing Line: "$line"');

      if (line.contains('ERROR:DHT11')) {
        _setError('Arduino Sensor Error: DHT11 failed to read.');
        continue;
      }

      final data = SensorData.tryParse(line);
      if (data != null) {
        _latestData = data;
        _dataController.add(data);
        notifyListeners();
      } else {
        debugPrint('BLE Parse failed for line: "$line"');
      }
    }
  }

  void _setState(BleState newState) {
    _state = newState;
    if (newState != BleState.error) _errorMessage = '';
    notifyListeners();
  }

  void _setError(String msg) {
    _errorMessage = msg;
    _state = BleState.error;
    notifyListeners();
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _connStateSub?.cancel();
    _dataController.close();
    super.dispose();
  }
}
