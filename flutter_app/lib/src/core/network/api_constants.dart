// File: lib/src/core/network/api_constants.dart
import 'package:flutter/foundation.dart';

class ApiConstants {
  ApiConstants._();

  static const String _productionUrl =
      'https://sit-app-production.up.railway.app';

  // iOS Simulator → localhost works directly.
  // macOS AirPlay Receiver occupies port 5000, so Flask runs on 5001.
  // Start backend with: PORT=5001 flask_api/venv/bin/python flask_api/run.py
  // Physical iPhone → replace with your Mac's LAN IP, e.g. http://192.168.1.X:5001
  static const String _localUrl = 'http://localhost:5001';

  static String get baseUrl =>
      kDebugMode ? _localUrl : _productionUrl;
}
