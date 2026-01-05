import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UnsplashService {
  // Demo API anahtarı
  // Not: Prodüksiyon ortamında bu anahtarın .env dosyasında saklanması önerilir.
  static const String _accessKey = 'maB_-ir2V-XCWN12A7eOdmM4JaCWlD2NPeWJarxPz0g';
  
  /// Kelime ile ilgili resim URL'sini getirir.
  /// Önce önbelleğe bakar, yoksa API'den çeker ve önbelleğe kaydeder.
  static Future<String?> getImageUrl(String query) async {
    final prefs = await SharedPreferences.getInstance();
    // Cache key'i kelimeye özel olsun
    final cacheKey = 'unsplash_image_${query.toLowerCase()}';
    
    // 1. Önbellek kontrolü
    final cachedUrl = prefs.getString(cacheKey);
    if (cachedUrl != null && cachedUrl.isNotEmpty) {
      // print('Image loaded from cache for: $query');
      return cachedUrl;
    }
    
    // 2. API isteği
    try {
      final uri = Uri.https('api.unsplash.com', '/search/photos', {
        'query': query.trim(), // Boşlukları temizle
        'per_page': '1',
        'client_id': _accessKey, 
        'orientation': 'portrait', // Mobil için dikey fotoğraflar
        'order_by': 'relevant', // En alakalı sonuçlar
        'content_filter': 'high', // Güvenli içerik
      });

      print('DEBUG: Requesting Unsplash: $uri'); // Not: Loglarda key görünecektir, production için dikkat.
      
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'] != null && (data['results'] as List).isNotEmpty) {
          // 'regular' veya 'small' boyutunu alalım
          final imageUrl = data['results'][0]['urls']['regular'];
          
          if (imageUrl != null) {
            // 3. Önbelleğe kaydet
            await prefs.setString(cacheKey, imageUrl);
            return imageUrl;
          }
        }
      } else {
        print('Unsplash API Error: ${response.statusCode}');
        print('Response Body: ${response.body}');
        print('Used Access Key (masked): ${_accessKey.substring(0, 10)}...${_accessKey.substring(_accessKey.length - 5)}');
      }
    } catch (e) {
      print('Error fetching image from Unsplash: $e');
    }
    
    return null;
  }
}
