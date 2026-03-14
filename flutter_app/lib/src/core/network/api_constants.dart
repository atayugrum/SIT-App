// File: lib/src/core/network/api_constants.dart
import 'package:flutter/foundation.dart';

class ApiConstants {
  ApiConstants._();

  static const String _productionUrl =
      'https://sit-app-production.up.railway.app';

  // iOS Simulator → localhost works directly.
  // Physical iPhone → replace with your Mac's LAN IP, e.g. http://192.168.1.X:5000
  static const String _localUrl = 'http://localhost:5000';

  static String get baseUrl =>
      kDebugMode ? _localUrl : _productionUrl;
}
