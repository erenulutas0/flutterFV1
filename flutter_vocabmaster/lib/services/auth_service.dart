import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../config/backend_config.dart';

/// Kullanıcı oturum ve profil yönetimi servisi
class AuthService {
  static const String _tokenKey = 'session_token';
  static const String _userDataKey = 'user_data';

  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Cache
  Map<String, dynamic>? _cachedUser;
  String? _cachedToken;

  /// Oturum token'ını al
  Future<String?> getToken() async {
    if (_cachedToken != null) return _cachedToken;
    
    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString(_tokenKey);
    return _cachedToken;
  }

  /// Kullanıcı verilerini al
  Future<Map<String, dynamic>?> getUser() async {
    if (_cachedUser != null) return _cachedUser;

    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(_userDataKey);
    if (userData != null) {
      _cachedUser = jsonDecode(userData);
      return _cachedUser;
    }
    return null;
  }

  /// Kullanıcı giriş yapmış mı?
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Oturumu kaydet
  Future<void> saveSession(String token, Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userDataKey, jsonEncode(user));
    _cachedToken = token;
    _cachedUser = user;
  }

  /// Kullanıcı bilgilerini güncelle
  Future<void> updateUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userDataKey, jsonEncode(user));
    _cachedUser = user;
  }

  /// Çıkış yap
  Future<void> logout() async {
    final token = await getToken();
    
    // Backend'e logout isteği gönder
    if (token != null) {
      try {
        await http.post(
          Uri.parse('${BackendConfig.baseUrl}/api/auth/logout'),
          headers: {'Authorization': 'Bearer $token'},
        );
      } catch (e) {
        // Sessizce geç
      }
    }

    // Yerel verileri temizle
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userDataKey);
    _cachedToken = null;
    _cachedUser = null;
  }

  /// Profil bilgilerini backend'den yenile
  Future<Map<String, dynamic>?> refreshProfile() async {
    final token = await getToken();
    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse('${BackendConfig.baseUrl}/api/auth/me'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          await updateUser(data['user']);
          return data['user'];
        }
      }
    } catch (e) {
      // Sessizce geç
    }
    return null;
  }

  /// Profil güncelle
  Future<bool> updateProfile(Map<String, dynamic> updates) async {
    final token = await getToken();
    if (token == null) return false;

    try {
      final response = await http.put(
        Uri.parse('${BackendConfig.baseUrl}/api/auth/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(updates),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          await updateUser(data['user']);
          return true;
        }
      }
    } catch (e) {
      // Sessizce geç
    }
    return false;
  }

  /// Kullanıcı ID'sini al
  Future<int?> getUserId() async {
    final user = await getUser();
    return user?['id'];
  }

  /// Kullanıcı tag'ını al
  Future<String?> getUserTag() async {
    final user = await getUser();
    return user?['userTag'];
  }

  /// Tam görünen ismi al (DisplayName#12345)
  Future<String?> getFullDisplayTag() async {
    final user = await getUser();
    return user?['fullDisplayTag'];
  }

  /// Display name'i al
  Future<String?> getDisplayName() async {
    final user = await getUser();
    return user?['displayName'];
  }

  /// UserTag ile kullanıcı ara
  Future<Map<String, dynamic>?> searchUserByTag(String userTag) async {
    final token = await getToken();
    if (token == null) return null;

    // # işareti yoksa ekle
    if (!userTag.startsWith('#')) {
      userTag = '#$userTag';
    }

    try {
      final response = await http.get(
        Uri.parse('${BackendConfig.baseUrl}/api/auth/user/${Uri.encodeComponent(userTag)}'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['user'];
        }
      }
    } catch (e) {
      // Sessizce geç
    }
    return null;
  }
}
