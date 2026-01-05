import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:device_info_plus/device_info_plus.dart';

class AppConfig {
  static String? _cachedBaseUrl;
  
  static Future<String> get baseUrl async {
    if (_cachedBaseUrl != null) return _cachedBaseUrl!;
    
    final port = dotenv.env['API_PORT'] ?? '8082';
    
    if (kIsWeb) {
      _cachedBaseUrl = 'http://${dotenv.env['LOCALHOST_IP'] ?? 'localhost'}:$port';
    } else if (Platform.isAndroid) {
      // Check if running on emulator or real device
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final isEmulator = !androidInfo.isPhysicalDevice;
      
      if (isEmulator) {
        // Emulator: use 10.0.2.2
        _cachedBaseUrl = 'http://${dotenv.env['EMULATOR_IP'] ?? '10.0.2.2'}:$port';
      } else {
        // Real device: use PC's local network IP
        _cachedBaseUrl = 'http://${dotenv.env['REAL_DEVICE_IP'] ?? '192.168.1.100'}:$port';
      }
    } else {
      _cachedBaseUrl = 'http://${dotenv.env['LOCALHOST_IP'] ?? 'localhost'}:$port';
    }
    
    return _cachedBaseUrl!;
  }

  static Future<String> get apiBaseUrl async => '${await baseUrl}/api';
}
