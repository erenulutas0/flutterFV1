import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class BackendConfig {
  static String get baseUrl {
    final port = dotenv.env['API_PORT'] ?? '8082';
    
    // Web için localhost
    if (kIsWeb) {
      return 'http://localhost:$port';
    }
    
    // Dotenv'de tanımlıysa onu kullan
    if (dotenv.env['BACKEND_URL'] != null && dotenv.env['BACKEND_URL']!.isNotEmpty) {
      return dotenv.env['BACKEND_URL']!;
    }
    
    // Tanımlı değilse varsayılan olarak Emülatör IP'si
    return 'http://10.0.2.2:$port';
  }
}
