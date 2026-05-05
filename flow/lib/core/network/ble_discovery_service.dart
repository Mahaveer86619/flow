import 'dart:async';
import 'dart:io';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../logger/app_logger.dart';

class BleDiscoveryService {
  BleDiscoveryService._();
  static final BleDiscoveryService instance = BleDiscoveryService._();

  static const _tag = 'BleDiscoveryService';

  final _discoveredDevicesController = StreamController<List<ScanResult>>.broadcast();
  Stream<List<ScanResult>> get discoveredDevicesStream => _discoveredDevicesController.stream;

  bool _isScanning = false;
  bool get isScanning => _isScanning;

  Future<void> init() async {
    FlutterBluePlus.setLogLevel(LogLevel.none);
    AppLogger.i(_tag, 'BLE Service initialized');
  }

  Future<void> startScan() async {
    if (_isScanning) return;
    
    // Check permissions
    if (Platform.isAndroid) {
      final bluetoothScan = await Permission.bluetoothScan.request();
      final bluetoothConnect = await Permission.bluetoothConnect.request();
      final location = await Permission.location.request();
      
      if (bluetoothScan.isDenied || bluetoothConnect.isDenied || location.isDenied) {
        AppLogger.w(_tag, 'BLE permissions denied');
        return;
      }
    }

    // Check if bluetooth is on
    if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
      AppLogger.w(_tag, 'Bluetooth is off');
      return;
    }

    _isScanning = true;
    AppLogger.i(_tag, 'Starting BLE scan...');

    try {
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
      );

      FlutterBluePlus.scanResults.listen((results) {
        final flowDevices = results.where((r) => 
          r.advertisementData.advName.startsWith('Flow-')
        ).toList();

        
        _discoveredDevicesController.add(flowDevices);
      });

      await FlutterBluePlus.isScanning.where((s) => s == false).first;
      _isScanning = false;
      await FlutterBluePlus.stopScan();
      AppLogger.i(_tag, 'BLE scan timed out');
    } catch (e) {
      _isScanning = false;
      AppLogger.e(_tag, 'BLE scan failed', e);
    }
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    _isScanning = false;
  }
}
